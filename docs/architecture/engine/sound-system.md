# Sound System Architecture

**Version:** 1.1  
**Status:** Production-ready (WAVE-3)  
**Owner:** Bart (Architecture Lead)  
**Documentation:** Brockman

---

## Overview

The sound system provides optional audio support for the MMO text adventure engine. It is **completely optional** — the game is fully playable without sound, and all sound events have text equivalents. Sound enriches atmosphere but never conveys critical information.

**Key principles:**
- **Text-canonical:** Every sound has a text fallback. Sound is decorative, not required.
- **Lazy-loaded:** Sounds load when objects load; no bulk preload.
- **Platform-agnostic:** Core Lua module with pluggable platform drivers (Web Audio, terminal, null).
- **Headless-safe:** In `--headless` mode, `ctx.sound_manager` is nil; all code branches work without sound.

---

## Module Structure

### Core Module: `src/engine/sound/init.lua`

The **sound manager** is a stateless orchestrator that:
1. Extracts sound metadata from objects
2. Manages playback queues and concurrency
3. Dispatches events to a platform driver
4. Implements resolution chain for sound fallback

**Size:** ~150 LOC. **Dependencies:** None (zero external libraries).

### Defaults Table: `src/engine/sound/defaults.lua`

Generic fallback sounds for common verbs. When an object has no specific sound for an event, the sound manager checks this table.

**Current defaults:**

| Event | Filename |
|-------|----------|
| `on_verb_break` | `generic-break.opus` |
| `on_verb_open` | `generic-creak.opus` |
| `on_verb_close` | `generic-close.opus` |
| `on_verb_light` | `generic-ignite.opus` |
| `on_verb_hit` | `generic-blunt-hit.opus` |
| (11 more verb defaults) | |

### Platform Drivers

#### Web Audio Driver: `web/sound-driver.lua`

Bridges Lua to Web Audio API via Fengari JS bridge. Implements concurrent playback, master volume, and crossfade timing for room transitions.

**JS functions exposed on `window`:**
- `_soundLoad(filename, callback)` — Async fetch + decodeAudioData()
- `_soundPlay(filename, opts)` — Create AudioBufferSourceNode, connect to GainNode chain
- `_soundStop(play_id)` — Stop active source
- `_soundUnload(filename)` — Release buffer
- `_soundSetMasterVolume(level)` — Set master GainNode gain
- `_soundSetMuted(muted)` — Global mute toggle

**Format support:** OGG Opus at 48 kbps mono. Browser `decodeAudioData()` handles decompression natively.

**Concurrency:** Max 4 one-shots, max 3 ambient loops. Oldest sounds are evicted when capacity is reached.

#### Terminal Driver: `src/engine/sound/terminal-driver.lua`

Best-effort audio on macOS/Linux/Windows. Uses platform-specific commands (`afplay`, `aplay`, `paplay`, or `PowerShell`). Fire-and-forget one-shots only. No loops, no volume control.

**Characteristics:**
- Non-blocking: `io.popen()` with immediate `:close()`
- Dev-only: Not production-grade; fallback silent on any error
- Max 2 seconds per sound
- Classified as "known best-effort"

#### Null Driver (Default)

When no driver is provided, all sound methods return silently. Used in `--headless` mode and test scenarios.

---

## Public API (21 Methods)

### Lifecycle

```lua
function M:new()
    -- Create a new sound manager instance
    -- @return SoundManager
```

```lua
function M:init(driver, options)
    -- Initialize with a platform driver
    -- @param driver  Driver table (nil = no-op mode)
    -- @param options Optional config: { volume, enabled }
    -- In --headless, driver is nil; all methods are silent no-ops
```

```lua
function M:shutdown()
    -- Stop all sounds, release resources
    -- Called on game exit or scene transition
```

### Object Scanning

```lua
function M:scan_object(obj)
    -- Extract sounds table from an object and queue files for loading
    -- Called by loader AFTER obj is registered to the registry
    -- Safe to call on any object; no-op if obj has no sounds table
    -- @param obj  Object with optional sounds table
```

```lua
function M:flush_queue()
    -- Trigger async loading of all queued sound files
    -- On web: files load in background
    -- In headless: queue is cleared, no-op
    -- Should be called after all initial objects are scanned
```

### Playback Control

```lua
function M:play(filename, opts)
    -- Play a sound file
    -- @param filename  Sound filename (e.g., "door-creak.opus")
    -- @param opts      Optional table: { loop=bool, owner_id=string, fade_in_ms, fade_out_ms }
    -- @return play_id (integer), or nil if sound disabled/failed
    -- If opts.loop=true, sound is queued as an ambient (max 3 concurrent)
    -- If opts.loop=false (default), sound is a one-shot (max 4 concurrent)
    -- When at capacity, oldest sound of same type is evicted
```

```lua
function M:stop(play_id)
    -- Stop a specific playing sound by play_id
    -- @param play_id  Integer returned from play()
    -- Removes from tracking lists; calls driver.stop()
```

```lua
function M:stop_by_owner(owner_id)
    -- Stop all sounds owned by a specific object
    -- Used to clean up creature ambients when creature dies
    -- @param owner_id  GUID or id of owner object
```

### Room Transitions

```lua
function M:enter_room(room)
    -- Start room ambients when entering
    -- Called by movement handler AFTER new room text renders
    -- Plays room.sounds.ambient with { loop=true, owner_id=room.id }
    -- @param room  Room object with optional sounds.ambient_loop
```

```lua
function M:exit_room(room)
    -- Stop non-portable sounds when leaving a room
    -- Calls stop_by_owner(room_id) to clean up all room-owned sounds
    -- @param room  Room being exited
    -- Web driver will crossfade out (1.5s fade_out_ms)
```

```lua
function M:unload_room(room_id)
    -- Free audio handles for a room's objects
    -- Called when room is unloaded from memory (rarely used)
    -- Stops sounds, then calls driver.unload() for cached buffers
```

### Event Dispatch

```lua
function M:trigger(obj, event_key)
    -- Resolve and play a sound for an object event
    -- Implements THREE-TIER RESOLUTION CHAIN:
    --   1. obj.sounds[event_key]       → object-specific sound (always wins)
    --   2. defaults[event_key]          → generic fallback
    --   3. nil                          → silent (no sound)
    --
    -- State-qualified ambient: checks ambient_{current_state} before ambient
    --
    -- @param obj        Object declaring sounds
    -- @param event_key  Sound key (e.g., "on_verb_break", "on_state_lit")
    -- @return play_id, or nil if no sound or sound disabled
    --
    -- Automatically detects ambient vs one-shot:
    --   Keys starting with "ambient" → loop=true
    --   All others → loop=false (one-shot)
```

### Settings

```lua
function M:set_volume(level)
    -- Set master volume (0.0–1.0, clamped)
    -- @param level  Float between 0 and 1
    -- Propagates to driver.set_master_volume()
```

```lua
function M:get_volume()
    -- Return current master volume (0.0–1.0)
    -- @return number
```

```lua
function M:set_enabled(enabled)
    -- Enable or disable all sound globally
    -- @param enabled  Boolean; if false, stops all playing sounds
    -- Used for settings menu toggle
```

```lua
function M:is_enabled()
    -- Return true if sound is globally enabled
    -- @return boolean
```

```lua
function M:mute()
    -- Mute sound (preserves volume setting)
    -- Used for in-game "mute" command
```

```lua
function M:unmute()
    -- Unmute sound
    -- Restores volume to pre-mute level
```

```lua
function M:is_muted()
    -- Return true if currently muted
    -- @return boolean
```

### Driver Management

```lua
function M:set_driver(driver)
    -- Hot-swap the platform driver
    -- @param driver  New driver table, or nil to disable
    -- Allows switching between web/terminal/null at runtime
```

```lua
function M:get_driver()
    -- Return the current driver (or nil)
    -- @return driver table, or nil
```

---

## Driver Interface Contract

All drivers (web, terminal, null) implement this interface:

```lua
driver:load(filename, callback)
    -- Async load a sound file from disk/network
    -- @param filename   Sound filename
    -- @param callback   Function(handle, err) called when done
    --                   handle = platform-specific audio data
    --                   err = string error message, or nil on success
    -- Fire-and-forget; must not block game loop
```

```lua
driver:play(filename, opts)
    -- Play a loaded sound
    -- @param filename  Sound filename
    -- @param opts      Table: { volume (0-1), loop (bool),
    --                           fade_in_ms, fade_out_ms }
    -- @return play_id  Platform-specific playback ID
    -- Terminal driver ignores fade params
    -- Must return a non-nil play_id to mark sound as active
```

```lua
driver:stop(play_id)
    -- Stop a specific playing sound
    -- @param play_id  ID returned from play()
```

```lua
driver:stop_all()
    -- Stop all currently playing sounds
```

```lua
driver:set_master_volume(level)
    -- Set master volume (0.0–1.0)
    -- @param level  Float, clamped to [0, 1]
    -- Terminal driver is a no-op
```

```lua
driver:unload(handle)
    -- Release audio resources
    -- @param handle  Returned from load()
    -- Terminal driver is a no-op
```

---

## Sound File Metadata: The `sounds` Table

Objects and rooms declare sounds via a `sounds` table. This table maps **event keys** to **filenames**.

### Field Naming Convention

| Field | Trigger | Example |
|-------|---------|---------|
| `ambient_loop` | Continuous while object/room active | `"rat-idle.opus"` |
| `ambient_{state}` | Loop while in specific FSM state | `ambient_lit = "candle-flame.opus"` |
| `on_state_{state}` | Fires on FSM transition to state | `on_state_lit = "candle-ignite.opus"` |
| `on_verb_{verb}` | Fires when verb acts on object | `on_verb_break = "glass-shatter.opus"` |
| `on_mutate` | Fires when mutation applies | `"mirror-crack.opus"` |
| `on_traverse` | Fires on door/passage traversal | `"door-creak.opus"` |

### Example: Lit Candle

```lua
return {
    id = "candle",
    -- ... other fields ...
    sounds = {
        on_state_lit = "candle-ignite.opus",      -- Fires when candle state → lit
        on_verb_blow = "candle-blow.opus",        -- Fires when player blows on it
        ambient_lit = "candle-flame.opus",        -- Loops while in lit state
    },
}
```

### Resolution Chain

When an event fires, the sound manager uses this chain to find the sound:

1. **Object-specific** (`obj.sounds[event_key]`) — Always wins if present
2. **State-qualified ambient** (`obj.sounds["ambient_" .. obj._state]`) — Checked before plain ambient
3. **Generic ambient** (`obj.sounds.ambient_loop`) — If no state variant
4. **Defaults fallback** (`defaults[event_key]`) — If object has no sound
5. **Silent** — If no sound found; this is valid and expected

---

## Hook Points (12 Integration Sites)

The engine calls the sound manager at these points:

| Hook | Location | Event Key | Purpose |
|------|----------|-----------|---------|
| **FSM transition** | `src/engine/fsm/init.lua` | `on_state_{new_state}` | Play state-change sound |
| **FSM ambient** | `enter_room()` | `ambient_{state}` | Loop while in state |
| **Verb execution** | Verb handler → effects pipeline | `on_verb_{verb}` | Play interaction sound |
| **Object mutation** | `src/engine/mutation/init.lua` | `on_mutate` | Play destruction/change sound |
| **Room entry** | Movement handler | Room ambient + object scans | Start room sound + load object ambients |
| **Room exit** | Movement handler | `stop_by_owner(room_id)` | Stop room and non-portable sounds |
| **Combat hit** | `src/engine/injuries.lua` | `on_verb_{attack}` | Play impact sound |
| **Creature state change** | Creature FSM | `on_state_{dead}` | Silence (no sound = death) |
| **Pickup** | Inventory handler | `on_verb_take` | Play pickup sound |
| **Drop** | Inventory handler | `on_verb_drop` | Play drop sound |
| **Door traversal** | Movement handler | `on_traverse` | Play door-open/footsteps |
| **Effects pipeline** | `src/engine/effects.lua` | `play_sound` effect | Generic sound dispatch |

---

## Concurrency & Limits

### One-Shots vs. Loops

**One-shot:** Non-looping sound. Max 4 concurrent. Oldest is evicted when capacity reached.
- Impact sounds, creature vocalizations, verb interactions
- Deactivate via `driver.stop()` or auto-expire

**Ambient loop:** Looping sound. Max 3 concurrent. Lowest priority evicted when capacity reached.
- Room atmospheres, object idle loops
- Manual stop via `stop_by_owner()` or `exit_room()`

### Priority

Within the 3-ambient limit:
1. **Room ambient** (highest priority — never evicted unless room changes)
2. **Creature ambient** (mid priority — creature presence in room)
3. **Object ambient** (lowest priority — item in inventory or on shelf)

When a new ambient arrives and 3 are active, the lowest-priority one is stopped.

### Eviction Policy

- **One-shots:** FIFO (oldest evicted first)
- **Ambients:** Priority-based (lowest priority evicted)

Example: If room ambient + creature loop + object loop are active, adding a new ambient will evict the object loop.

---

## Nil-Safe Pattern (Headless Mode)

In `--headless` mode, `ctx.sound_manager` is `nil`. Code must check before calling:

```lua
if context.sound_manager then
    context.sound_manager:trigger(obj, "break")
end
```

Or use a defensive call:

```lua
local sm = context.sound_manager
if sm then sm:trigger(obj, "break") end
```

All code paths work identically with or without sound. Sound is purely additive.

---

## Integration Example: Candle Lighting

When a player lights a candle (state transition `unlit` → `lit`):

1. **FSM fires transition** → calls `sound_manager:trigger(candle, "on_state_lit")`
2. **Resolution chain:**
   - Check `candle.sounds.on_state_lit` → found: `"candle-ignite.opus"`
   - Return `"candle-ignite.opus"`
3. **Play sound:** `sound_manager:play("candle-ignite.opus", { owner_id=candle.id })`
4. **Text output:** "The wick catches the flame..." (unconditional, happens first)
5. **Sound plays:** Concurrently in background (async on web, fire-and-forget on terminal)

Text is always printed. Sound fires if driver available and enabled. No synchronization needed.

---

## File Format & Assets

**Format:** OGG Opus at 48 kbps, mono (not stereo)  
**Extension:** `.opus` (OGG Opus container)  
**Directory:** `assets/sounds/{category}/{name}.opus`  
**Size:** ~6 KB/sec; MVP ~230 KB total (all 24 files)  
**License:** CC0 or CC-BY (no CC-BY-NC for commercial flexibility)

### Categories

- `creatures/` — Creature vocalizations
- `objects/` — Object interaction sounds
- `combat/` — Impact and hit sounds
- `ambient/` — Room atmospheres
- `ui/` — UI confirmations (phase 2)

---

## Design Rules

1. **Every sound needs a text fallback.** If `on_listen` describes silence, the sound object must have `on_listen` explicitly.

2. **Creature death = silence.** When a creature dies, its `ambient_loop` is stopped, and `on_listen` updates to explicit silence. No `on_state_dead` sound fires. Absence of sound IS the death notification.

3. **Object-specific sounds ALWAYS override defaults.** If an object declares a `sounds` table, those filenames are used. Defaults never supersede.

4. **Mutation doesn't inherit.** When an object mutates (e.g., candle → candle-broken), the new object is scanned fresh. It gets its own `sounds` table, or silence if it has none.

5. **Sound is fire-and-forget.** No waiting for audio to finish. Text outputs immediately; sound plays asynchronously.

6. **Accessibility first.** Every sound event has a text equivalent. Sound enhances atmosphere but never conveys required information.

---

## Testing

Sound is tested at two levels:

### Unit Tests

`test/sound/test-sound-manager.lua` — Mock driver verifies:
- Sound manager loads and initializes
- `scan_object()` extracts sounds tables
- `trigger()` resolution chain works correctly
- Concurrency limits enforce eviction
- No-op mode (nil driver) is silent

### Integration Tests

`test/sound/test-sound-integration.lua` — End-to-end verification:
- FSM transition fires correct sound
- Verb on object triggers sound
- Room entry starts ambient; room exit stops it
- Mutation stops old, fires `on_mutate`, scans new
- Combat hits fire impact sounds
- Creature death stops sounds (no ghosts)

All tests run with `--headless` flag and mock driver. Sound never blocks the game loop.

---

## Performance Characteristics

- **Memory:** Minimal. Object `sounds` tables are small (<10 KB even with 50+ objects). Loaded audio buffers are cached per-room (~50-80 KB).
- **CPU:** Negligible. Trigger dispatch is O(1) hash lookup. Loading is async on web, fire-and-forget on terminal.
- **Network (web):** Lazy-loaded per room. ~30-80 KB downloaded when entering a room with sounds.
- **Headless overhead:** Zero. Sound manager is `nil`; no allocation, no calls.

---

## Rollback & Recovery

If sound system fails:

1. **Code revert:** `git revert HEAD~N` to undo sound commits
2. **Redeploy:** Run `web/deploy.ps1` without sound directory
3. **Game continues:** All bridge calls are `pcall()`-wrapped; missing sounds cause silent fails, never crashes
4. **Verify:** Load game, confirm no JS errors, no sound-related logs

Sound system is designed to be completely removable without breaking the game. Text-canonical design ensures this invariant.

---

## Debugging

### Headless Mode

```bash
lua src/main.lua --headless
```

All sound calls are no-op. Output is text-only. Useful for regression testing.

### Sound-Specific Logs

Debug mode (TODO: implement in Phase 2) will log:
- `SOUND_LOAD: {filename} → {handle}`
- `SOUND_PLAY: {play_id} {filename}`
- `SOUND_STOP: {play_id}`
- `SOUND_EVICT: {old_id} (capacity reached)`

### Browser Console

Web Audio API errors appear in DevTools console. Examples:
- `Uncaught DOMException: AudioContext state is "suspended"` — First keypress unlocks
- `404: sounds/rat-squeak.opus` — File missing; fallback to silence

---

## Future Directions (Phase 2+)

- **Time-of-day ambients:** Different room sounds at day vs. night
- **Spatial audio:** Sound panning based on object location
- **UI sounds:** Button clicks, error beeps
- **Music tracks:** Background themes (separate from SFX)
- **Volume presets:** Sound vs. ambient independently controllable
- **Speech synthesis:** Text-to-speech for narration (accessibility)

---

**Last Updated:** WAVE-3 (v1.1)  
**Next Review:** Phase 2 (Phase 2+)
