# Sound Implementation Plan

**Date:** 2026-07-31
**Status:** Draft
**Owner:** Wayne "Effe" Berry
**Research:** `resources/research/sound/sound-effects-research.md` (Frink)

---

## Section 1: Engine Architecture

**Author:** Bart (Architecture Lead)
**Scope:** Sound metadata, lazy loading, event mapping, sound manager, platform abstraction, room-scoped audio

### Design Principles

Before any implementation detail — these are inviolable:

1. **Accessibility first (Wayne's requirement).** Every sound event MUST have a text equivalent. Sound enhances; it never replaces. The game is fully playable on mute, over SSH, in CI, or by a deaf player. No gameplay information is conveyed exclusively through audio.

2. **Principle 8 compliance.** Objects declare their sounds via metadata. The engine executes them. No object-specific sound logic in engine code. If a candle crackles when lit, `candle.lua` declares it — the sound manager plays it.

3. **Graceful degradation.** Sound is a layered subsystem. If the platform can't play audio, the sound manager becomes a no-op. Zero impact on game behavior.

4. **Pre-compressed delivery (Wayne's requirement).** OGG files are stored compressed on the server. The browser downloads and decodes them natively. No runtime compression/decompression step in engine code.

---

### 1. Sound Metadata on Objects

Objects declare sounds via an optional `sounds` table. This follows the same pattern as `states`, `transitions`, and `mutations` — declarative metadata that the engine reads and acts on.

#### 1.1 The `sounds` Table

```lua
return {
    id = "candle",
    template = "small-item",
    -- ... existing fields ...

    sounds = {
        -- Event-keyed: triggered by specific engine events
        on_state_lit = "candle-ignite.ogg",          -- FSM enters "lit" state
        on_state_extinguished = "candle-snuff.ogg",  -- FSM enters "extinguished" state

        -- Ambient: loops while object is in this FSM state
        ambient_lit = "fire-crackle-loop.ogg",       -- loops while _state == "lit"

        -- Verb-keyed: triggered when verb acts on this object
        on_verb_break = "wax-snap.ogg",              -- player breaks the candle
        on_verb_take = "item-pickup-light.ogg",      -- player picks it up

        -- Mutation-keyed: triggered when object mutates
        on_mutate = "object-transform.ogg",          -- code rewrite fires
    },
}
```

#### 1.2 Key Naming Convention

Sound keys follow a strict prefix convention so the engine can dispatch without per-object logic:

| Prefix | Trigger | Example Key | When It Fires |
|--------|---------|-------------|---------------|
| `on_state_{state}` | FSM transition enters `{state}` | `on_state_lit` | `fsm.transition()` completes to "lit" |
| `ambient_{state}` | Loop while in `{state}` | `ambient_lit` | Object is in "lit" state and in earshot |
| `on_verb_{verb}` | Verb handler acts on object | `on_verb_break` | `verbs.break` resolves to this object |
| `on_mutate` | Mutation engine rewrites object | `on_mutate` | `mutation.apply()` fires |
| `on_pickup` | Object picked up | `on_pickup` | Engine hook `on_pickup` fires |
| `on_drop` | Object dropped | `on_drop` | Engine hook `on_drop` fires |

#### 1.3 Creature Sounds

Creatures use the same `sounds` table. Their richer FSM states map naturally:

```lua
return {
    id = "rat",
    -- ... existing fields ...

    sounds = {
        on_state_idle = "rat-chitter-quiet.ogg",
        on_state_flee = "rat-panic-squeak.ogg",
        on_state_dead = "rat-death-squeak.ogg",
        ambient_idle = "rat-scratch-loop.ogg",
        ambient_wander = "rat-scurry-loop.ogg",
    },
}
```

#### 1.4 Room Sounds

Rooms can declare ambient sounds that play while the player is present:

```lua
return {
    id = "cellar",
    -- ... existing fields ...

    sounds = {
        ambient = "water-drip-echo-loop.ogg",   -- always loops in this room
        on_enter = "footsteps-stone.ogg",        -- one-shot on room entry
    },
}
```

#### 1.5 Fallback / Default Sounds

The sound manager maintains a small table of fallback sounds keyed by verb. These fire when an object has no `sounds` table but the player performs a common action. Objects can override any of these by declaring their own `on_verb_{verb}` key.

```lua
-- In src/engine/sound/defaults.lua
return {
    on_verb_take = "item-pickup.ogg",
    on_verb_drop = "item-drop.ogg",
    on_verb_open = "door-creak-generic.ogg",
    on_verb_close = "door-close-generic.ogg",
    on_verb_lock = "lock-click.ogg",
    on_verb_unlock = "lock-click.ogg",
    on_verb_hit = "impact-blunt.ogg",
    on_verb_slash = "impact-slash.ogg",
    on_verb_drink = "swallow.ogg",
}
```

This table is small (~10 entries) and always loaded. It provides baseline audio coverage without requiring every object to declare sounds.

---

### 2. Lazy Loading Integration

#### 2.1 Design Constraint

Wayne's requirement: sounds load when their associated object/creature/room loads. No bulk preload. This piggybacks on the existing loader flow.

#### 2.2 Current Loading Flow (Reference)

```
Level file → list of room paths
  → For each room:
      loader.load_source(room.lua) → room table
      loader.flatten_instances(room.instances) → flat object list
      For each instance:
          loader.resolve_instance(instance, base_classes, templates) → resolved object
          registry:register(id, resolved_object)
```

#### 2.3 Sound Loading Extension

After an object registers in the registry, the sound manager scans its `sounds` table and queues audio files for async loading. No new module boundaries — the loader calls the sound manager as a post-registration hook.

```
registry:register(id, object)
  → sound_manager:scan_object(object)
      → For each value in object.sounds:
          sound_manager:queue_load(filename)
```

**Implementation in the loader:**

```lua
-- In the room-loading sequence (loader or game-adapter)
for _, obj in ipairs(resolved_objects) do
    registry:register(obj.id, obj)
    if ctx.sound_manager and obj.sounds then
        ctx.sound_manager:scan_object(obj)
    end
end

-- Room itself
if ctx.sound_manager and room.sounds then
    ctx.sound_manager:scan_object(room)
end
```

#### 2.4 Sound Manager Queue

The sound manager maintains three internal tables:

```lua
sound_manager._queue = {}       -- filenames waiting to load
sound_manager._loaded = {}      -- filename → audio_handle (platform-specific)
sound_manager._playing = {}     -- filename → { handle, loop, owner_id }
```

**`scan_object(obj)`** iterates `obj.sounds`, deduplicates against `_loaded`, and appends new filenames to `_queue`.

**`flush_queue()`** is called by the platform layer. On web: issues async `fetch()` calls that decode into `AudioBuffer` objects. On terminal: verifies file existence on disk via `io.open()` (no network). Files that fail to load are silently dropped (graceful degradation).

#### 2.5 Unloading

When the player leaves a room, objects that are no longer in earshot (not in the current room and not in the player's hands) can be unloaded:

```lua
sound_manager:unload_room(old_room_id)
-- Stops all playing sounds owned by objects in old_room_id
-- Removes their audio handles from _loaded (frees memory)
-- Exception: objects in player.hands[] are retained
```

This keeps memory bounded — at most one room's worth of audio is loaded at a time, plus hand-held items.

---

### 3. Event-to-Sound Mapping

The engine already has well-defined event points. Sound hooks attach to these existing points — no new event system needed.

#### 3.1 Hook Points

| Engine Event | Where It Fires | Sound Key Resolved | Type |
|---|---|---|---|
| **FSM transition** | `fsm.transition()` returns success | `on_state_{new_state}` | One-shot |
| **FSM state active** | Object is in state + in earshot | `ambient_{current_state}` | Loop |
| **Verb execution** | Verb handler completes on object | `on_verb_{verb_name}` | One-shot |
| **Object mutation** | `mutation.apply()` rewrites object | `on_mutate` | One-shot |
| **Room entry** | `on_enter_room` hook fires | Room's `on_enter` | One-shot |
| **Room exit** | `on_exit_room` hook fires | (stop old room ambients) | Stop |
| **Object pickup** | `on_pickup` hook fires | `on_pickup` | One-shot |
| **Object drop** | `on_drop` hook fires | `on_drop` | One-shot |
| **Combat hit** | `injuries.inflict()` processes | `on_verb_{attack_verb}` | One-shot |
| **Creature state change** | Creature FSM ticks to new state | `on_state_{new_state}` | One-shot |
| **Timer expiration** | `fsm.tick_timers()` auto-transitions | `on_state_{new_state}` | One-shot |
| **Effect processing** | `effects.process()` runs effect | `play_sound` effect type | One-shot/Loop |

#### 3.2 Integration Pattern

Each hook calls the sound manager through a single dispatch function. This keeps the integration surgical — one line per hook site.

```lua
-- Utility function (in sound manager)
function sound_manager:trigger(obj, event_key)
    if not self._enabled then return end
    local sound_file = obj.sounds and obj.sounds[event_key]
    if not sound_file then
        sound_file = self._defaults[event_key]  -- fallback
    end
    if not sound_file then return end
    self:play(sound_file, { owner = obj.id })
end
```

**FSM hook (in `fsm.transition()`):**
```lua
-- After successful transition, before returning
if ctx.sound_manager then
    ctx.sound_manager:trigger(obj, "on_state_" .. target_state)
end
```

**Verb hook (in verb dispatch, `loop/init.lua`):**
```lua
-- After verb handler returns, if it resolved an object
if ctx.sound_manager and resolved_obj then
    ctx.sound_manager:trigger(resolved_obj, "on_verb_" .. verb)
end
```

**Room entry hook (in `movement.lua`):**
```lua
-- In on_enter_room processing
if ctx.sound_manager then
    ctx.sound_manager:enter_room(new_room)
end
```

#### 3.3 Effects Pipeline Integration

Register a `play_sound` effect type so any system can trigger sound through the existing effects pipeline:

```lua
effects.register("play_sound", function(effect, ctx)
    if ctx.sound_manager then
        ctx.sound_manager:play(effect.sound_file, {
            volume = effect.volume,
            loop = effect.loop or false,
            owner = effect.owner_id,
        })
    end
end)
```

This allows object transition definitions to include sound effects inline:

```lua
-- In an object's transitions table
{
    from = "closed", to = "open", verb = "open",
    message = "The heavy lid grinds open.",
    effects = {
        { type = "play_sound", sound_file = "stone-grind.ogg", volume = 80 }
    }
}
```

---

### 4. Sound Manager Module

**Location:** `src/engine/sound/init.lua`

The sound manager is a platform-agnostic module that owns all audio state. It exposes a clean API that the engine calls. The actual audio playback is delegated to a **platform driver** injected at startup.

#### 4.1 Module Structure

```
src/engine/sound/
├── init.lua          -- Sound manager (API + state)
├── defaults.lua      -- Default verb-to-sound fallback table
└── driver.lua        -- Platform driver interface (abstract)
```

#### 4.2 Public API

```lua
local M = {}

-- Lifecycle
function M:init(driver, options)       -- Initialize with platform driver
function M:shutdown()                  -- Stop all sounds, release resources

-- Object scanning (called by loader)
function M:scan_object(obj)            -- Extract sounds table, queue files
function M:flush_queue()               -- Load all queued files (async on web)

-- Playback
function M:play(filename, opts)        -- Play sound (one-shot or loop)
    -- opts.volume: 0-100 (default 50)
    -- opts.loop: boolean (default false)
    -- opts.owner: object id (for lifecycle tracking)
function M:stop(filename)              -- Stop a specific sound
function M:stop_by_owner(owner_id)     -- Stop all sounds owned by an object

-- Room transitions
function M:enter_room(room)            -- Start room ambients + object ambients
function M:exit_room(room)             -- Stop non-portable sounds

-- Event dispatch
function M:trigger(obj, event_key)     -- Resolve sound key → play

-- Settings
function M:set_volume(level)           -- Master volume 0-100
function M:set_enabled(bool)           -- Global mute toggle
function M:is_enabled()                -- Query mute state

-- Cleanup
function M:unload_room(room_id)        -- Free audio handles for a room's objects

return M
```

#### 4.3 Internal State

```lua
M._enabled = true                  -- global toggle
M._volume = 50                     -- master volume (0-100)
M._driver = nil                    -- platform driver (injected)
M._defaults = {}                   -- loaded from defaults.lua

M._queue = {}                      -- { filename = true } — pending loads
M._loaded = {}                     -- { filename = handle } — ready to play
M._playing = {}                    -- { filename = { handle, loop, owner_id } }
M._object_sounds = {}              -- { obj_id = { event_key = filename } }
```

#### 4.4 Ambient Sound Management

Ambient sounds require special handling because they loop continuously while their condition holds:

```lua
function M:enter_room(room)
    -- 1. Start room-level ambient
    if room.sounds and room.sounds.ambient then
        self:play(room.sounds.ambient, { loop = true, owner = room.id })
    end

    -- 2. Play room entry one-shot
    if room.sounds and room.sounds.on_enter then
        self:play(room.sounds.on_enter, { owner = room.id })
    end

    -- 3. Start object ambients for current FSM states
    for _, obj_id in ipairs(room.contents or {}) do
        local obj = registry:get(obj_id)
        if obj and obj.sounds and obj._state then
            local ambient_key = "ambient_" .. obj._state
            if obj.sounds[ambient_key] then
                self:play(obj.sounds[ambient_key], { loop = true, owner = obj.id })
            end
        end
    end
end

function M:exit_room(room)
    -- Stop all sounds owned by room or room objects, EXCEPT player-held items
    self:stop_by_owner(room.id)
    for _, obj_id in ipairs(room.contents or {}) do
        if not player_is_holding(obj_id) then
            self:stop_by_owner(obj_id)
        end
    end
end
```

#### 4.5 No-Op Fallback

If no driver is injected (terminal without audio support, headless mode, CI):

```lua
function M:init(driver, options)
    if not driver then
        -- No-op mode: all methods silently succeed
        self._enabled = false
        return
    end
    self._driver = driver
    self._enabled = options and options.enabled ~= false
end
```

Every public method checks `self._enabled` first. Zero overhead when disabled.

---

### 5. Platform Abstraction

The sound manager calls a **driver** interface. Each platform provides its own driver implementation.

#### 5.1 Driver Interface

```lua
-- Abstract driver contract (documented, not a base class)
-- Each platform implements these functions:

driver:load(filename, callback)
    -- Async load a sound file
    -- callback(handle, err) — handle is opaque, platform-specific
    -- Web: fetch() + decodeAudioData() → AudioBuffer
    -- Terminal: verify file exists, return file path as handle

driver:play(handle, opts) → playback_id
    -- Play a loaded sound
    -- opts.volume: 0-100
    -- opts.loop: boolean
    -- Returns opaque playback_id for stop()

driver:stop(playback_id)
    -- Stop a playing sound

driver:stop_all()
    -- Stop everything (room transition, shutdown)

driver:set_master_volume(level)
    -- 0-100, applied to all current and future playback

driver:unload(handle)
    -- Release audio resources for this handle
```

#### 5.2 Web Driver (Fengari + Web Audio API)

**Location:** `web/sound-driver.lua` (bridges to JS via `js.global`)

```lua
local js = require("js")
local window = js.global

local D = {}
local audio_ctx = nil

function D:init()
    local AudioContext = window.AudioContext or window.webkitAudioContext
    if AudioContext then
        audio_ctx = AudioContext.new()
    end
end

function D:load(filename, callback)
    -- Use the existing JIT fetch pattern from game-adapter
    local url = "assets/audio/" .. filename
    window:_loadSound(url, function(buffer, err)
        callback(buffer, err)
    end)
end

function D:play(handle, opts)
    if not audio_ctx or not handle then return nil end
    local source = audio_ctx:createBufferSource()
    source.buffer = handle
    source.loop = opts.loop or false

    local gain = audio_ctx:createGain()
    gain.gain.value = (opts.volume or 50) / 100
    source:connect(gain)
    gain:connect(audio_ctx.destination)
    source:start(0)

    return { source = source, gain = gain }
end

function D:stop(playback_id)
    if playback_id and playback_id.source then
        playback_id.source:stop()
    end
end

return D
```

**JS helper (in `web/index.html` or `web/sound-bridge.js`):**
```javascript
window._loadSound = function(url, callback) {
    fetch(url)
        .then(r => r.arrayBuffer())
        .then(data => audioCtx.decodeAudioData(data))
        .then(buffer => callback(buffer, null))
        .catch(err => callback(null, err.message));
};
```

This follows the existing `_cachedFetch` pattern from `game-adapter.lua` — Lua calls a JS global function, JS does the async work, callback returns the result.

#### 5.3 Terminal Driver

**Location:** `src/engine/sound/terminal-driver.lua`

Terminal sound is best-effort. Most terminal sessions (SSH, CI, headless) won't support it. The driver detects platform capability at init and becomes a no-op if unsupported.

```lua
local D = {}
local platform = nil
local sound_dir = nil

function D:init(opts)
    sound_dir = opts and opts.sound_dir or "resources/audio"
    -- Detect platform
    if package.config:sub(1,1) == "\\" then
        platform = "windows"
    elseif os.execute("which afplay > /dev/null 2>&1") then
        platform = "macos"
    elseif os.execute("which aplay > /dev/null 2>&1") then
        platform = "linux"
    else
        platform = nil  -- unsupported — no-op mode
    end
end

function D:load(filename, callback)
    local path = sound_dir .. "/" .. filename
    local f = io.open(path, "r")
    if f then
        f:close()
        callback(path, nil)
    else
        callback(nil, "file not found: " .. path)
    end
end

function D:play(handle, opts)
    if not platform or not handle then return nil end
    if opts.loop then return nil end  -- terminal can't loop; skip
    -- Non-blocking where possible
    if platform == "windows" then
        os.execute('start /b powershell -c "(New-Object Media.SoundPlayer \'' .. handle .. '\').PlaySync()" >nul 2>&1')
    elseif platform == "macos" then
        os.execute("afplay " .. handle .. " &")
    elseif platform == "linux" then
        os.execute("aplay " .. handle .. " &")
    end
    return handle
end

function D:stop(playback_id)
    -- Terminal playback is fire-and-forget; no reliable stop
end

function D:stop_all() end
function D:set_master_volume(level) end
function D:unload(handle) end

return D
```

**Terminal limitations (accepted):**
- No looping ambient sounds (ambient is web-only)
- Blocking playback on some platforms (short sounds only, < 2 sec)
- No volume control
- No stop/cancel
- WAV format required (OGG needs decoder); terminal uses `.wav` copies

#### 5.4 Headless / CI Mode

When `--headless` flag is set, no driver is injected. The sound manager initializes in no-op mode. Zero overhead, zero side effects.

---

### 6. Room-Scoped Audio

#### 6.1 Core Rule

**Earshot = current room + player's hands.**

A sound is audible if its owning object is in the player's current room OR in the player's hands. Everything else is silent.

#### 6.2 Room Transition Sequence

When the player moves from Room A to Room B:

```
1. on_exit_room(Room A) fires
   → sound_manager:exit_room(Room A)
      → Stop Room A's ambient loop
      → Stop all object ambients in Room A
      → KEEP sounds for objects in player.hands[]

2. Player moves to Room B

3. on_enter_room(Room B) fires
   → sound_manager:enter_room(Room B)
      → Load any unloaded sounds for Room B objects (scan + flush)
      → Start Room B's ambient loop
      → Start object ambients for Room B contents
      → Play Room B's on_enter one-shot (if declared)
```

#### 6.3 Object Movement and Sound Lifecycle

| Event | Sound Behavior |
|-------|---------------|
| Player picks up object with ambient | Ambient continues (object in hand = in earshot) |
| Player drops object in current room | Ambient continues (still in earshot) |
| Player drops object, leaves room | Ambient stops on room exit |
| Object FSM transitions | One-shot fires if in earshot; new ambient starts if applicable |
| Object mutates (D-14 code rewrite) | Old object's sounds stop; new object scanned for sounds |
| Object destroyed / removed from registry | All sounds for that owner stop |

#### 6.4 Mutation and Sound

When mutation fires (the Prime Directive — code IS state), the old object is replaced with a new one. The sound manager must handle this:

```lua
-- In mutation.apply(), after object replacement:
if ctx.sound_manager then
    ctx.sound_manager:stop_by_owner(old_obj.id)        -- stop old sounds
    ctx.sound_manager:scan_object(new_obj)              -- scan new object
    ctx.sound_manager:trigger(new_obj, "on_mutate")     -- play mutation sound
    -- Start new ambient if applicable
    if new_obj._state and new_obj.sounds then
        local ambient_key = "ambient_" .. new_obj._state
        if new_obj.sounds[ambient_key] then
            ctx.sound_manager:play(new_obj.sounds[ambient_key], {
                loop = true, owner = new_obj.id
            })
        end
    end
end
```

#### 6.5 Multiple Simultaneous Sounds

The web driver handles mixing natively (Web Audio API mixes all active sources). The sound manager doesn't need its own mixer. However, we cap concurrent sounds to prevent audio chaos:

- **Max concurrent one-shots:** 4 (oldest evicted if exceeded)
- **Max concurrent ambient loops:** 3 (room ambient + 2 object ambients)
- **Priority:** Room ambient > creature ambient > object ambient > one-shots

These limits live in the sound manager, not the driver.

---

### 7. File Organization

```
src/engine/sound/
├── init.lua              -- Sound manager module (API + state)
├── defaults.lua          -- Default verb→sound fallback table
└── terminal-driver.lua   -- Terminal platform driver

web/
├── sound-driver.lua      -- Web/Fengari platform driver
└── sound-bridge.js       -- JS helper for Web Audio API

resources/audio/          -- Sound files (pre-compressed OGG for web, WAV for terminal)
├── creatures/            -- rat-chitter.ogg, wolf-growl.ogg, etc.
├── objects/              -- door-creak.ogg, glass-shatter.ogg, etc.
├── ambience/             -- fire-crackle-loop.ogg, water-drip-loop.ogg, etc.
└── actions/              -- item-pickup.ogg, impact-blunt.ogg, etc.
```

---

### 8. Context Object Extension

The sound manager is injected into `ctx` at startup, following the established pattern for `registry`, `ui`, and `player`:

```lua
-- In main.lua or game-adapter.lua initialization
local sound = require("src.engine.sound")
local driver = nil

if not args.headless then
    if _G.__FENGARI then
        driver = require("web.sound-driver")
    else
        driver = require("src.engine.sound.terminal-driver")
    end
end

sound:init(driver, { enabled = true, volume = 50 })
ctx.sound_manager = sound
```

This follows the same conditional-subsystem pattern as `ctx.ui` — present when available, nil when not, and every callsite guards with `if ctx.sound_manager then`.

---

### 9. Architectural Constraints

| Constraint | Rationale |
|---|---|
| No external Lua dependencies | Fengari compatibility (D-14 ecosystem) |
| Sound manager is stateless across saves | Audio state is ephemeral — rebuilt from object metadata on load |
| No sound-specific fields on `ctx.player` | Sound preferences stored separately (localStorage on web, file on terminal) |
| No modifications to object .lua schema beyond `sounds` table | Single optional field addition; backward-compatible |
| Terminal driver must not block > 2 seconds | Short one-shots only; no ambient loops |
| Web driver must not block the coroutine | All loads/plays are async via JS bridge |

---

### 10. Migration Path

Adding sound to existing objects is incremental and non-breaking:

1. **Phase 0 (this plan):** Build `src/engine/sound/` module + drivers. No object changes.
2. **Phase 1:** Add `sounds = {}` to 12-15 high-impact objects (per Frink's research MVP list). Hook FSM transitions + room entry.
3. **Phase 2:** Expand to all objects with `on_listen` fields (~63 objects, 5 creatures). Add verb-level hooks.
4. **Phase 3:** Ambient loops, spatial audio, volume ducking.

Each phase is independently shippable. The engine never requires sound — it always enhances.

---

*Next sections: Comic Book Guy (sound design / asset selection), Gil (web build pipeline / delivery)*
