# Sound System — Unified Implementation Plan

**Version:** 1.1
**Date:** 2026-07-31
**Status:** Plan Complete — v1.1 (all team review findings addressed)
**Owner:** Wayne "Effe" Berry
**Architect:** Bart (Architecture Lead)
**Contributors:** Comic Book Guy (Game Design), Gil (Web Pipeline), Frink (Research)

> **v1.1 Changelog:** Consolidated findings from 7-agent team review (Bart, CBG, Marge, Chalmers, Flanders, Smithers, Moe). Resolved 10 blockers and 11 concerns. Key additions: sound key resolution chain, scan_object lifecycle, driver fade params, regression baseline, LLM test scenarios, GUID pre-assignment protocol, field naming spec, verb integration pattern, nil-safe trigger, rollback plan, gate failure escalation.

---

## Wave Status Tracker

```
WAVE-0: ⏳ Pending  |  WAVE-1: ⏳ Pending  |  WAVE-2: ⏳ Pending  |  WAVE-3: ⏳ Pending
```

---

## Executive Summary

**What:** Add an optional sound effects system to the MMO text adventure engine — ambient loops, creature vocalizations, object interaction sounds, and combat impacts.

**Why:** Sound transforms the experience from "reading a story" to "being in a place." The game starts at 2 AM in total darkness — hearing a rat skitter or a door creak while navigating by feel creates genuine tension. Frink's research confirms Web Audio API integration is straightforward via the existing Fengari JS bridge.

**How:** A 4-wave implementation building a platform-agnostic sound manager (Lua) with injected drivers (Web Audio via Fengari, terminal best-effort). Objects declare sounds via metadata (`sounds` table — Principle 8 compliant). ~24 OGG Opus files at ~230 KB total. Sound enhances but never replaces text — the game is fully playable on mute.

**Three Iron Laws (Wayne's directives):**
1. **Accessibility first.** Every sound event has a text equivalent. Zero gameplay information conveyed exclusively through audio.
2. **Lazy loading.** Sounds load when their object/creature/room loads. No bulk preload.
3. **Pre-compressed.** OGG Opus files stored compressed on server; browser `decodeAudioData()` handles decompression natively.

---

## Quick Reference Table

| Wave | Name | Tracks | Agent Assignments | Gate | Key Deliverables |
|------|------|--------|-------------------|------|------------------|
| **WAVE-0** | Sound Manager + Platform Abstraction | 3 parallel | Bart (engine), Gil (web bridge), Nelson (tests) | GATE-0 | `src/engine/sound/init.lua`, `web/bootstrapper.js` audio, `web/game-adapter.lua` bridge |
| **WAVE-1** | Object Sound Metadata + Room Ambients | 4 parallel | Flanders (objects), Moe (rooms), CBG (design review), Nelson (tests) | GATE-1 | `sounds` tables on 15+ objects/creatures, room ambient declarations, 24 sound files sourced |
| **WAVE-2** | Event Integration + Engine Hooks | 3 parallel | Bart (engine hooks), Smithers (narration sounds), Nelson (integration tests) | GATE-2 | FSM/verb/mutation hooks wired, effects pipeline `play_sound` type, combat sound dispatch |
| **WAVE-3** | Polish + Build Pipeline + Testing | 3 parallel | Gil (build-sounds.ps1, deploy), Nelson (LLM walkthroughs), Brockman (docs) | GATE-3 | Build pipeline, deploy integration, architecture + design docs |

---

## Dependency Graph

```
WAVE-0: Sound Manager Module
  ├── Bart: src/engine/sound/init.lua + defaults.lua + terminal-driver.lua
  ├── Gil: bootstrapper.js audio subsystem + game-adapter.lua sound bridge
  └── Nelson: test/sound/ test scaffolding
        │
        ▼  GATE-0: Module loads, no-op mode works, web bridge connects, API frozen
        │
        ├──────────────────────────────────────────────────┐
        │                                                  │
WAVE-1: Object Metadata + Asset Sourcing          WAVE-2 Track 2A: Engine Hooks (Bart)
  ├── Flanders: sounds tables on objects              (can start after GATE-0 — hooks are
  ├── Moe: room ambient declarations                   structural, don't need sound files)
  ├── CBG: design review (parallel, non-blocking)
  └── Nelson: metadata validation tests
        │                                                  │
        ▼  GATE-1: Objects declare sounds, files sourced   │
        │                                                  │
        ├──────────────────────────────────────────────────┘
        │
WAVE-2: Tracks 2B + 2C (need GATE-1 objects)
  ├── Smithers: effects pipeline play_sound type
  └── Nelson: integration tests (end-to-end sound triggers)
        │
        ▼  GATE-2: Sounds fire on state changes, verbs, room transitions
        │
WAVE-3: Polish + Deploy + Docs
  ├── Gil: build-sounds.ps1, deploy.ps1 update, cache-busting
  ├── Nelson: LLM headless walkthroughs (5 scenarios)
  └── Brockman: architecture + design documentation
        │
        ▼  GATE-3: Full pipeline works, docs shipped, LLM walkthroughs pass
```

**v1.1 (C4 fix):** WAVE-2 Track 2A (Bart: engine hooks) can start after GATE-0 — hooks are structural and don't need actual sound files. WAVE-2 Tracks 2B + 2C wait for GATE-1 because they need objects with `sounds` tables.

---

## WAVE-0: Sound Manager + Platform Abstraction

**Goal:** Build the core sound infrastructure — a platform-agnostic Lua module and two platform drivers (web + terminal). After this wave, the sound manager loads, runs in no-op mode during tests, and connects to Web Audio on the browser.

### Track 0A: Engine Sound Module (Bart)

**Files:**
- CREATE `src/engine/sound/init.lua` — Sound manager: API + state (~150 LOC)
- CREATE `src/engine/sound/defaults.lua` — Default verb-to-sound fallback table (~15 entries)
- CREATE `src/engine/sound/terminal-driver.lua` — Terminal driver (best-effort, no-op fallback)

**Sound Manager Public API:**

`lua
-- Lifecycle
M:init(driver, options)        -- Initialize with platform driver (nil = no-op)
M:shutdown()                   -- Stop all sounds, release resources

-- Object scanning (called by loader after template resolution + registry registration)
M:scan_object(obj)             -- Extract sounds table, queue files
-- LIFECYCLE: scan_object is called AFTER loader.resolve_template() and
-- registry:register() complete, as a post-registration hook. The loader
-- calls ctx.sound_manager:scan_object(obj) if sound_manager is non-nil.
-- Insertion point: loader/init.lua, after register() returns. (Resolves C7)
M:flush_queue()                -- Load all queued files (async on web)

-- Playback
M:play(filename, opts)         -- Play sound (one-shot or loop)
M:stop(filename)               -- Stop a specific sound
M:stop_by_owner(owner_id)      -- Stop all sounds owned by an object

-- Room transitions
M:enter_room(room)             -- Start room ambients + object ambients
M:exit_room(room)              -- Stop non-portable sounds
M:unload_room(room_id)         -- Free audio handles for a room's objects

-- Event dispatch
M:trigger(obj, event_key)      -- Resolve sound key → play (with fallback to defaults)
-- RESOLUTION CHAIN (resolves C6):
--   1. obj.sounds[event_key] → object-specific sound (always wins)
--   2. defaults[event_key] → generic fallback (e.g., "generic-break.opus")
--   3. nil → silent (no sound for this event)
-- State-qualified ambient: check ambient_{current_state} first, then ambient.
-- Object-specific ALWAYS overrides defaults. Defaults are last resort.

-- Settings
M:set_volume(level)            -- Master volume 0-100
M:set_enabled(bool)            -- Global mute toggle
`

**Internal State:**
- `_queue`: filenames pending load
- `_loaded`: filename → audio handle (platform-specific)
- `_playing`: filename → { handle, loop, owner_id }
- `_object_sounds`: obj_id → { event_key → filename }

**Concurrency Limits:**
- Max 4 concurrent one-shots (oldest evicted)
- Max 3 concurrent ambient loops (room > creature > object priority)

**Driver Interface Contract:**
`
driver:load(filename, callback)     -- Async load; callback(handle, err)
driver:play(handle, opts) → id     -- Play loaded sound; opts.volume, opts.loop,
                                   --   opts.fade_in_ms, opts.fade_out_ms (v1.1: C3)
                                   --   Terminal driver ignores fade params.
                                   --   Web driver implements via GainNode.linearRampToValueAtTime().
driver:stop(playback_id)           -- Stop a playing sound
driver:stop_all()                  -- Stop everything
driver:set_master_volume(level)    -- 0-100
driver:unload(handle)              -- Release resources
`

**Terminal Driver:** Detects platform (Windows/macOS/Linux) via `package.config` and uses `io.popen()` with immediate `:close()` for non-blocking fire-and-forget (v1.1: C1 fix — `os.execute()` is synchronous and blocks the game loop). Falls back to silent no-op if `io.popen()` is unavailable. Fire-and-forget one-shots only. No loops, no volume control. Max 2 second sounds. Terminal sound is classified as **"known best-effort, dev-only, not production."**

**Context Integration:** Sound manager injected as `ctx.sound_manager` at startup (same pattern as `ctx.ui`, `ctx.registry`). Nil in `--headless` mode.

### Track 0B: Web Audio Bridge (Gil)

**Files:**
- EDIT `web/bootstrapper.js` — Add audio subsystem (~80 lines): AudioContext, GainNode, 6 bridge functions
- EDIT `web/game-adapter.lua` — Add sound bridge module (~40 lines): Lua wrappers exposing `_G._web_sound`
- CREATE `web/sound-driver.lua` — Web platform driver (bridges to JS via `js.global`)

**JS Bridge Functions (on `window`):**
- `_soundLoad(id, url)` — Async fetch + `decodeAudioData()` → `_audioBuffers[id]`
- `_soundPlay(id, opts)` — Create `AudioBufferSourceNode`, connect to `GainNode` chain
- `_soundStop(id)` — Stop active source
- `_soundUnload(id)` — Release buffer
- `_soundIsLoaded(id)` — Query buffer cache
- `_soundSetMasterVolume(vol)` — Set master `GainNode.gain.value`
- `_soundSetMuted(muted)` — Global mute toggle

**Autoplay Policy:** First keypress in input box calls `_ensureAudioContext()` → `AudioContext.resume()`. No "click to enable" banner needed — the game requires typing to play.

**Format:** OGG Opus at 48 kbps mono. ~6 KB/sec. Browser `decodeAudioData()` handles decompression natively. Fallback to OGG Vorbis only if needed (Phase 2 concern — not MVP).

**All bridge calls wrapped in `pcall()`** — sound failure never crashes the game.

### Track 0C: Test Scaffolding (Nelson)

**Files:**
- CREATE `test/sound/test-sound-manager.lua` — Unit tests for sound manager API
- CREATE `test/sound/test-sound-defaults.lua` — Verify default verb-sound mappings
- CREATE `test/sound/mock-driver.lua` — Mock driver that records all play/stop/load calls for verification (v1.1: Marge #5)
- Register `test/sound/` in test runner

**Test approach:** Mock driver injected into sound manager. Verify: init, scan_object, trigger, play/stop lifecycle, no-op mode, room enter/exit.

**Mock driver spec (v1.1: Marge #5):** `test/sound/mock-driver.lua` records all calls into `driver._calls` table: `{ {method="play", args={...}}, ... }`. Nelson tests assert against this log. No actual audio playback.

**Concurrency limit tests (v1.1: Marge #6):**
- Test: Fire 5 one-shots → verify oldest (1st) is evicted, 4 remain playing
- Test: Start 4 ambient loops → verify lowest priority evicted (room > creature > object)
- Test: Priority override — room ambient always trumps creature ambient

### GATE-0 Criteria

- [ ] `src/engine/sound/init.lua` loads without errors
- [ ] Sound manager in no-op mode (nil driver): all methods return silently
- [ ] Web bridge functions exposed on `window` (6 functions)
- [ ] Lua bridge calls JS functions via `pcall()` without error
- [ ] `--headless` mode: `ctx.sound_manager` is nil, zero overhead
- [ ] `test/sound/` tests pass (mock driver) — includes concurrency eviction tests
- [ ] All tests pass with AND without `--headless` flag (v1.1: Marge #4)
- [ ] Zero regressions on existing test suite
- [ ] **Regression baseline captured:** Record exact passing test count at WAVE-0 start (v1.1: Marge #3)

**GATE-0 Interface Contract Freeze (v1.1: Chalmers #4):**
After GATE-0, the following API is **frozen** — WAVE-1 agents can depend on it:
- `M:init(driver, options)` — exists, works with nil driver (no-op)
- `M:scan_object(obj)` — exists, safe to call on any object (no-op if no `sounds` table)
- `M:trigger(obj, event_key)` — exists, resolves via chain, silent on miss
- `M:play(filename, opts)` — exists, works with mock/web/terminal/nil driver
- `M:enter_room(room)` / `M:exit_room(room)` — exist, safe to call

**GATE-0 Checkpoint Protocol (v1.1: Chalmers #6):**
After GATE-0: Coordinator (Wayne or delegate) verifies all 3 tracks complete, updates `board.md` status to `WAVE-0: ✅`, commits. Bart's sound manager API is finalized and frozen.

---

## WAVE-1: Object Sound Metadata + Asset Sourcing

**Goal:** Add `sounds` tables to objects and creatures. Declare room ambients. Source all 24 MVP sound files. After this wave, objects know what they sound like; files exist on disk.

### Track 1A: Object/Creature Sound Metadata (Flanders)

**Files:** EDIT 15+ object `.lua` files in `src/meta/objects/` and `src/meta/creatures/`

**GUID Pre-Assignment Protocol (v1.1: Flanders #3):**
Before WAVE-1 starts, Bart writes `.squad/decisions/inbox/bart-sound-guids.md` with pre-assigned GUIDs for all objects Flanders/Moe will modify. This prevents GUID collisions during parallel authoring per Pattern 15.

**Sound Field Naming Convention (v1.1: Flanders #4 + Moe #3):**
Sound fields use a dedicated namespace separate from sensory `on_*` fields:

| Field | Type | Example |
|-------|------|---------|
| `ambient_loop` | Continuous loop while object/room active | `ambient_loop = "rat-idle.opus"` |
| `on_state_{state}` | Fired on FSM transition to state | `on_state_lit = "candle-ignite.opus"` |
| `on_verb_{verb}` | Fired when verb acts on object | `on_verb_break = "glass-shatter.opus"` |
| `on_mutate` | Fired when mutation applies | `on_mutate = "mirror-crack.opus"` |
| `on_traverse` | Fired on room exit traversal (doors/passages) | `on_traverse = "door-creak.opus"` |

Sensory fields (`on_feel`, `on_listen`, `on_smell`, `on_taste`) remain text strings. Sound fields are filenames referencing `.opus` assets. No overlap, no ambiguity.

**Sound key convention (prefix-based dispatch):**

| Prefix | Trigger | Example |
|--------|---------|---------|
| `on_state_{state}` | FSM enters state | `on_state_lit` |
| `ambient_{state}` | Loop while in state | `ambient_lit` |
| `on_verb_{verb}` | Verb acts on object | `on_verb_break` |
| `on_mutate` | Mutation fires | `on_mutate` |
| `on_traverse` | Exit traversal (doors) | `on_traverse` |

**Creature sounds (all 5 creatures):** Per-state sounds mapped to `on_listen` text. Dead state = silence (deliberate design — absence of sound IS the sound).

**Creature Death State (v1.1: Flanders #5 + CBG #3):**
When a creature dies:
1. FSM transitions to `dead` state
2. `ambient_loop` stops — `sound_manager:stop_by_owner(creature_id)` is called
3. `on_listen` text updates to explicit silence: `"The [creature] is motionless. No breath, no sound."` (CBG education recommendation)
4. `on_feel` remains describing the dead body (e.g., `"Cold, stiff fur."`)
5. Creature object is NOT deleted — it stays in the room as a dead body
6. No `on_state_dead` sound fires — silence IS the death sound (D-SOUND-8)

This must be clarified before WAVE-2 integration so `stop_by_owner()` behavior is correct.

**Priority objects (Tier 1):** Candle, match, torch, oil lantern, mirror, bear trap, all doors (8), all creatures (5).

**Design rule:** Every object with a `sounds` table MUST already have `on_feel` and `on_listen`. Sound never exists without its text equivalent.

### Track 1B: Room Ambient Declarations (Moe)

**Files:** EDIT 7 room `.lua` files in `src/meta/world/`

**Room ambient assignments (v1.1: standardized to .opus — C5):**

| Room | Ambient File | Character |
|------|-------------|-----------|
| Bedroom | `amb-bedroom-silence.opus` | Near-silence; settling stone |
| Hallway | `amb-hallway-torches.opus` | Torch crackle, timber creak |
| Cellar | `amb-cellar-drip.opus` | Irregular water drips, stone echo |
| Storage Cellar | `amb-storage-scratching.opus` | Rat scratching, old wood creak |
| Deep Cellar | `amb-deep-cellar-silence.opus` | Oppressive near-silence |
| Crypt | `amb-crypt-void.opus` | Borderline inaudible; rare stone settle |
| Courtyard | `amb-courtyard-wind.opus` | Wind, rare owl hoot, ivy rustle |

**Room sound format:**
`lua
sounds = {
    ambient_loop = "amb-cellar-drip.opus",
    on_enter = "footsteps-stone.opus",
}
`

**Room Exit Transition Sounds (v1.1: Moe #4):**
Room traversal fires the **door/passage object's** sound, NOT the room's exit definition. Door objects declare `sounds = { on_traverse = "door-creak.opus" }`. Moe does NOT add sound fields to room exit definitions — sound ownership belongs to the door/passage object (Flanders' domain). The movement handler calls `sound_manager:trigger(exit_obj, "on_traverse")` when the player passes through.

**Time-of-Day Ambient Variation (v1.1: CBG #5):**
**Deferred to Phase 2.** MVP uses fixed ambient (permanent 2 AM deep-night atmosphere for all rooms). No `ambient_loop_night` / `ambient_loop_day` fields needed in WAVE-1. Simpler gate criteria, less integration risk.

### Track 1C: Asset Sourcing (CBG design review + Wayne)

**CBG Parallelism (v1.1: Chalmers #3):** CBG's design review runs in PARALLEL with Flanders/Moe — it is non-blocking to GATE-1. If CBG surfaces design issues, they are captured to `.squad/decisions/inbox/` for the next wave. CBG does NOT block Flanders/Moe from completing their tracks.

**24 MVP sound files to source:** 8 creature, 4 door/passage, 3 fire/light, 4 combat/impact, 3 ambient loops, 2 destruction/event.

**Sourcing priority:** CC0 (Zapsplat, Sonniss) → CC-BY (OpenGameArt) → CC-BY-SA (Freesound). No CC-BY-NC (BBC) for commercial flexibility.

**Compression:** `ffmpeg -i input.wav -c:a libopus -b:a 48k -ac 1 output.opus`

**Size budget:** ~230 KB total (all 24 files). Per-room lazy load: ~30-80 KB per room.

**File location:** `assets/sounds/{category}/{name}.opus` (creatures/, objects/, combat/, ambient/)

**Standardized format (v1.1: C5):** ALL sound files use `.opus` extension (OGG Opus container). No `.ogg` extensions — `.opus` is the actual codec identifier. CBG's sound audit tables should reference `.opus` throughout.

### Track 1D: Metadata Tests (Nelson)

**Files:**
- CREATE `test/sound/test-sound-metadata.lua` — Validate all objects with `sounds` tables have: valid filenames, matching `on_listen`/`on_feel`, correct key prefixes
- CREATE `test/sound/test-room-ambients.lua` — Validate every room has valid `ambient_loop` or explicitly `nil` (v1.1: Moe #10)

**Room ambient validation (v1.1: Moe #10):** Test checks all 7 rooms: (a) room has `sounds.ambient_loop` referencing a real `.opus` file in `assets/sounds/`, OR (b) room explicitly has no ambient. No silent failures.

### GATE-1 Criteria

- [ ] 15+ objects/creatures have `sounds` tables with correct key prefixes
- [ ] 7 rooms declare ambient sounds (using `ambient_loop` field name)
- [ ] 24 sound files sourced, compressed to `.opus`, stored in `assets/sounds/`
- [ ] Metadata tests pass (key format, file existence, accessibility check)
- [ ] Room ambient validation tests pass (v1.1: Moe #10)
- [ ] All tests pass with AND without `--headless` flag (v1.1: Marge #4)
- [ ] Zero regressions (baseline count from GATE-0 must match)

---

## WAVE-2: Event Integration + Engine Hooks

**Goal:** Wire the sound manager into engine event points. After this wave, sounds actually play when the player interacts with the world.

### Track 2A: Engine Event Hooks (Bart)

**Canonical Integration Path (v1.1: C2 + Smithers #3):**
The **effects pipeline is the primary path** for sound dispatch. Objects declare sounds as metadata; hooks emit effects (not direct `trigger()` calls). The `M:trigger()` method is an **internal helper** called by the effect handler, not by verb handlers directly.

Flow: `verb handler → effects.process(obj, "play_sound", key)` → effect handler calls `sound_manager:trigger(obj, key)` internally.

This eliminates the dual-path problem: no risk of double-firing. Verb handlers do NOT call `trigger()` directly.

**Nil-Safe Trigger Pattern (v1.1: Smithers #7):**
Sound manager provides a safe entry point for all callers:
```lua
function M:trigger_safe(obj, event_key)
    if not self then return end  -- nil in headless mode
    self:trigger(obj, event_key)
end
```
Verb handlers use `context.sound_manager:trigger_safe(obj, "break")` — always safe, nil-safe. Alternatively, callers check `if context.sound_manager then ... end`.

**Narration + Sound Timing (v1.1: Smithers #4):**
Text emits first (unconditional). Sound fires concurrently (async, non-blocking). No delays in text output for sound sync. Sound lag is acceptable — the browser handles timing. No `if sound then ... else print()` branching.

**LISTEN Verb Behavior (v1.1: Smithers #5):**
When a player types LISTEN on a creature that has an ambient loop running:
- Text: `on_listen` prints (always)
- Sound: LISTEN verb triggers a **fresh one-shot** (`on_verb_listen`) even if creature ambient loop is active. Concurrent one-shots are allowed (max 4 total). The ambient loop is NOT stopped.

**Verb-to-Event Key Mapping (v1.1: Flanders #10):**
Verb handlers fire sound events using the pattern `on_verb_{verb_name}`. The verb name matches the verb handler key exactly. Examples: `on_verb_break`, `on_verb_listen`, `on_verb_light`, `on_verb_attack`. Smithers integrates one generic pattern into `verbs/init.lua` — not 31 hardcoded calls.

**Combat Sound Sequence (v1.1: Smithers #10 + CBG #8):**
A single combat action emits: all combat text first (attack description, damage, opponent response), then all combat sounds fire-and-forget (hit + opponent vocalization). No interleaving. Combat budget: 3 simultaneous max (ambient ducked 50%, creature vocalization, impact sound).

When a creature dies mid-combat: `sound_manager:stop_by_owner(creature_id)` is called. The creature's ambient loop stops cleanly. No ghost sounds. This is tested in WAVE-2 integration (CBG #8).

**Mutation Sound Handling (v1.1: Flanders #8):**
On mutation (e.g., candle → candle-broken):
1. `sound_manager:stop_by_owner(old_obj_id)` — stop all sounds from old object
2. `on_mutate` sound fires (from old object's sounds table)
3. `sound_manager:scan_object(new_obj)` — scan the mutated replacement
4. Mutated objects do NOT inherit parent sounds. `candle-broken.lua` declares its own `sounds` table (or has none — which means silence). This is intentional.

**Room Enter/Exit Hook Integration (v1.1: Moe #6):**
The game loop (movement handler) calls these explicitly:
1. `sound_manager:exit_room(old_room)` — stops room ambient + non-held object ambients. Called BEFORE room transition text.
2. `sound_manager:enter_room(new_room)` — starts room ambient + scans/starts object ambients for current FSM states. Called AFTER room text renders.
3. Crossfade (web only): `exit_room` fades out (1.5s via `fade_out_ms`), `enter_room` fades in (1.5s via `fade_in_ms`). Terminal driver ignores fade params.

**Files:**
- EDIT `src/engine/fsm/init.lua` — Add sound trigger after successful transition (~3 lines)
- EDIT `src/engine/loop/init.lua` — Add sound trigger after verb dispatch (~3 lines)
- EDIT `src/engine/mutation/init.lua` — Add sound trigger on object mutation (~6 lines)
- EDIT movement handler — Add `enter_room`/`exit_room` sound calls (~4 lines)
- EDIT `src/engine/effects.lua` — Register `play_sound` effect type (~8 lines)
- EDIT loader — Add `scan_object` call after registry registration (~4 lines)

**12 hook points, each ≤3 lines:**

| Hook | Location | Sound Key |
|------|----------|-----------|
| FSM transition | `fsm.transition()` | `on_state_{new_state}` |
| FSM ambient | `enter_room` | `ambient_{current_state}` |
| Verb execution | Verb dispatch | `on_verb_{verb}` (object override → default fallback) |
| Object mutation | `mutation.apply()` | `on_mutate` + stop old + scan new |
| Room entry | Movement handler | Room `on_enter` + start ambients |
| Room exit | Movement handler | Stop room + non-held object sounds |
| Object pickup | `on_pickup` hook | `on_pickup` |
| Object drop | `on_drop` hook | `on_drop` |
| Combat hit | `injuries.inflict()` | `on_verb_{attack_verb}` |
| Creature state change | Creature FSM tick | `on_state_{new_state}` |
| Timer expiration | `fsm.tick_timers()` | `on_state_{new_state}` |
| Effect processing | `effects.process()` | `play_sound` effect type |

**Ambient management on room transitions:**
- `exit_room`: Stop room ambient + object ambients (keep hand-held items)
- `enter_room`: Start room ambient + scan/start object ambients for current FSM states
- Crossfade: 1.5s fade out → 1.5s fade in (web driver only)

**Combat sound budget: 3 simultaneous max.** Slot 1: ambient (ducked 50%). Slot 2: creature vocalization. Slot 3: impact sound. Each combat phase gets at most ONE event sound.

### Track 2B: Narration Sound Integration (Smithers)

**Files:**
- EDIT `src/engine/verbs/init.lua` — Ensure verb handlers that resolve objects pass through sound trigger

**Scope:** Verify that existing verb text output + sound trigger coexist cleanly. Text is unconditional; sound is fire-and-forget. No `if sound then ... else print()` branching.

### Track 2C: Integration Tests (Nelson)

**Files:**
- CREATE `test/sound/test-sound-integration.lua` — End-to-end: FSM transition triggers sound, verb triggers sound, room entry triggers ambient
- CREATE `test/sound/test-sound-combat.lua` — Combat sound dispatch: damage type → impact sound

**All tests use `--headless` mode with mock driver.**

### GATE-2 Criteria

- [ ] FSM transition → sound plays (mock driver records call)
- [ ] Verb on object with `sounds` → correct sound triggered via effects pipeline
- [ ] Verb on object without `sounds` → default sound triggered
- [ ] Room entry → ambient starts; room exit → ambient stops (crossfade on web)
- [ ] Mutation → old sounds stop, `on_mutate` fires, new object scanned
- [ ] Combat hit → damage-type impact sound fires (3 simultaneous max)
- [ ] Creature death → `stop_by_owner()` called, no ghost sounds (v1.1: CBG #8)
- [ ] `--headless`: zero sound calls, zero overhead
- [ ] All tests pass with AND without `--headless` flag (v1.1: Marge #4)
- [ ] Integration tests pass
- [ ] Zero regressions (baseline count from GATE-0 must match)

---

## WAVE-3: Polish + Build Pipeline + Testing

**Goal:** Production-ready deployment. Build pipeline for sound assets, deploy integration, LLM walkthroughs, documentation.

### Track 3A: Build + Deploy Pipeline (Gil)

**Files:**
- CREATE `web/build-sounds.ps1` — Validate + copy sounds to `web/dist/sounds/` (flat namespace)
- EDIT `web/deploy.ps1` — Add sound directory copy step (~5 lines)

**Build pipeline:** Validate each file <100 KB, valid Opus format. Flatten `assets/sounds/{category}/` → `web/dist/sounds/`. Deploy to `../WayneWalterBerry.github.io/play/sounds/`.

**Cache-busting:** Reuse existing `CACHE_BUST` constant in bootstrapper.js. `fetch(url + '?v=' + CACHE_BUST)`.

**Cache-bust testing (v1.1: Marge #8):** Deferred to Phase 2 QA. Manual test on staging: fetch `sounds/rat-squeak.opus?v={CACHE_BUST}`, verify browser plays audio. Not a gate blocker.

**WAVE-3 Rollback Plan (v1.1: Chalmers #5):**
If the web build pipeline fails or deploy is partially broken:
1. **Revert code:** `git revert HEAD~N` to undo sound-related commits
2. **Redeploy:** Run `web/deploy.ps1` without sound directory — site works without sounds (text-canonical design ensures this)
3. **Verify:** Confirm game loads, no JS errors from missing sounds (`pcall()` protects all bridge calls)
4. Sound failure never breaks the game — this is a design invariant, not just a hope

**Player Controls (MVP):**
- Master volume (0-100, default 80)
- Sound effects toggle (on/off)
- Ambient toggle (on/off — some players want SFX but not loops)
- Text-only mode (explicit mute)
- Volume stored in `localStorage` for persistence

### Track 3B: LLM Walkthroughs (Nelson)

**Nelson LLM Test Scenarios (v1.1: Marge #2):**
All scenarios use `--headless` + deterministic seed. Each scenario is a scripted command sequence with expected text output and expected sound events (verified via mock driver call log).

**Scenario 1: Room Look + Listen (ambient verification)**
```
$ echo "look\nlisten" | lua src/main.lua --headless
Expected text: Room description appears. On_listen text prints.
Expected sound: Room ambient queued (or no-op in headless). No crash.
```

**Scenario 2: Light Candle (FSM transition + sound)**
```
$ echo "take matchbox\ntake match\nstrike match\nlight candle" | lua src/main.lua --headless
Expected text: Match lights, candle ignites. FSM transition text appears.
Expected sound: on_state_lit sound would fire on web. No crash in headless.
```

**Scenario 3: Open Door + Room Transition (ambient crossfade)**
```
$ echo "open door\nnorth" | lua src/main.lua --headless
Expected text: Door opens, player moves to hallway. New room description.
Expected sound: on_traverse sound fires, old ambient stops, new ambient starts. No crash.
```

**Scenario 4: Combat Encounter (creature + impact sounds)**
```
$ echo "attack rat" | lua src/main.lua --headless
Expected text: Combat text appears (hit/miss, damage). Creature response.
Expected sound: Impact sound + creature vocalization would fire. No crash.
```

**Scenario 5: Full Level 1 Walkthrough (regression sweep)**
```
$ echo "{full-level-1-command-sequence}" | lua src/main.lua --headless
Expected: Zero crashes, zero sound-related errors, zero regressions.
All text output matches non-sound baseline. Game completes.
```

### Track 3C: Documentation (Brockman)

**Files:**
- CREATE `docs/architecture/engine/sound-system.md` — Engine architecture, driver interface, hook points
- CREATE `docs/design/sound-design.md` — Sound design philosophy, priority tiers, accessibility rules
- UPDATE `docs/design/object-design-patterns.md` — Add `sounds` table pattern

### GATE-3 Criteria

- [ ] `build-sounds.ps1` runs successfully — all files validated
- [ ] Sounds deploy to web dist directory
- [ ] `build-sounds.ps1` validation: every `.opus` file < 100 KB, valid format
- [ ] Staging deploy tested (v1.1: Chalmers #5)
- [ ] Rollback tested: game works after removing sound directory (v1.1: Chalmers #5)
- [ ] LLM headless walkthroughs pass (5 scenarios — see Track 3B for specs)
- [ ] Architecture docs shipped
- [ ] Design docs shipped
- [ ] Object design patterns updated with `sounds` table
- [ ] All tests pass with AND without `--headless` flag (v1.1: Marge #4)
- [ ] Regression baseline matches: GATE-3 test count ≥ GATE-0 baseline (v1.1: Marge #3)
- [ ] Zero regressions on full test suite

---

## File Ownership Summary

| Owner | Files | Wave |
|-------|-------|------|
| **Bart** | `src/engine/sound/init.lua`, `src/engine/sound/defaults.lua`, `src/engine/sound/terminal-driver.lua` | 0 |
| **Bart** | Edits to `fsm/init.lua`, `loop/init.lua`, `mutation/init.lua`, `effects.lua`, loader, movement | 2 |
| **Gil** | `web/sound-driver.lua`, edits to `bootstrapper.js`, `game-adapter.lua` | 0 |
| **Gil** | `web/build-sounds.ps1`, edit to `deploy.ps1` | 3 |
| **Flanders** | 15+ object/creature `.lua` files (`sounds` table additions) | 1 |
| **Moe** | 7 room `.lua` files (`sounds` table additions) | 1 |
| **CBG** | Design review + asset sourcing guidance | 1 |
| **Smithers** | `src/engine/verbs/init.lua` verification | 2 |
| **Nelson** | `test/sound/` (4 test files across waves 0-2) | 0, 1, 2, 3 |
| **Brockman** | `docs/architecture/engine/sound-system.md`, `docs/design/sound-design.md` | 3 |

---

## Risk Register

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Browser autoplay policy blocks AudioContext | Sounds don't play on first room load | Low | First keypress unlocks; game requires typing |
| Sound files too large for mobile | Slow room transitions | Low | 48 kbps Opus; ~230 KB total; lazy load per room |
| Terminal `io.popen()` best-effort | Sound may not play on all terminals | Medium | io.popen() with immediate close; dev-only; silent no-op fallback (v1.1: C1) |
| CC-BY sounds require attribution tracking | Legal compliance | Low | Prioritize CC0 sources; attribution in `assets/sounds/README.md` |
| Fengari JS bridge edge cases | `pcall()` swallows real errors | Low | Debug mode logs all bridge errors; production silences them |
| Sound manager exceeds 500 LOC | Architecture review triggered | Low | Core API is ~150 LOC; driver interface is thin |

---

## Architectural Constraints

| Constraint | Rationale |
|---|---|
| No external Lua dependencies | Fengari compatibility |
| Sound manager is stateless across saves | Audio state is ephemeral — rebuilt from object metadata on load |
| No sound-specific fields on `ctx.player` | Sound preferences stored separately (`localStorage` on web) |
| Only one new field on objects (`sounds` table) | Backward-compatible; optional |
| Terminal driver must not block > 2 seconds | Short one-shots only; no ambient loops |
| Web driver must not block the Lua coroutine | All loads/plays async via JS bridge |
| `--headless` mode: `ctx.sound_manager` is nil | Zero overhead in CI/testing |

---

## Design Decisions (Consolidated)

| ID | Decision | Choice | Source |
|----|----------|--------|--------|
| D-SOUND-1 | Sound metadata format | `sounds` table with prefix-keyed entries (`on_state_`, `ambient_`, `on_verb_`, `on_mutate`) | Bart |
| D-SOUND-2 | Loading strategy | Lazy load piggybacking on existing loader → registry flow | Bart (Wayne directive) |
| D-SOUND-3 | Platform drivers | Injected driver pattern; web (Fengari + Web Audio) + terminal (`os.execute` best-effort) | Bart |
| D-SOUND-4 | Earshot scope | Current room + player's hands | Bart |
| D-SOUND-5 | Accessibility | Text always present + canonical; sound is additive fire-and-forget | CBG (Wayne directive) |
| D-SOUND-6 | Compression format | OGG Opus at 48 kbps mono; browser decodes natively | Gil |
| D-SOUND-7 | Effects integration | `play_sound` effect type registered in effects pipeline | Bart |
| D-SOUND-8 | Dead creature sound | Silence — no death sounds; absence of sound IS the design | CBG |
| D-SOUND-9 | Combat sound budget | 3 simultaneous max (ambient ducked + creature + impact) | CBG |
| D-SOUND-10 | Door sound sharing | 2-3 base creak sounds; material variation expressed in text | CBG |
| D-SOUND-11 | Damage type sounds | 4 impact sounds by type (pierce/slash/blunt/crush), not weapon | CBG |
| D-SOUND-12 | Player controls | Master volume + 3 toggles (SFX, ambient, creature) | CBG |
| D-SOUND-13 | Time-of-day ambient | Deferred to Phase 2; MVP uses 2 AM (deep night) for all rooms | CBG |
| D-SOUND-14 | Ambient crossfade | 1.5s fade out → 1.5s fade in on room transitions (web only) | CBG |
| D-SOUND-15 | Event ducking | Ambient ducks 30% during event sounds | CBG |
| D-SOUND-16 | MVP scope | 24 sounds covering Tier 1 categories | CBG |
| D-SOUND-17 | Sound licensing | Prioritize CC0 + CC-BY; no CC-BY-NC | Frink |
| D-SOUND-18 | Build pipeline | Separate `build-sounds.ps1`; flat deploy namespace | Gil |

---

## Gate Failure Escalation Protocol (v1.1: Chalmers #10)

1. **Failure detected:** Nelson files a GitHub issue, tags the responsible agent.
2. **Fix cycle:** Assignee fixes and requests re-gate within the same session.
3. **Re-gate failure:** If re-gate still fails, escalate to Wayne within 30 minutes.
4. **Flaky test protocol (v1.1: Marge #9):** Non-deterministic tests (sound timing, async load race conditions) are marked `@skip-ci` with linked issue. Bart decides: fix immediately or quarantine with tracking issue. Nelson uses fixed seeds for all LLM test scenarios.

---

## Phase 2 Deferred Scope (v1.1: Chalmers #8 + CBG #5)

The following features are explicitly **deferred to Phase 2** and are NOT in scope for WAVE-0 through WAVE-3:

1. **Vorbis fallback** — Legacy Safari support (OGG container with Vorbis codec)
2. **Time-of-day ambient variation** — `ambient_loop_night` / `ambient_loop_day` per room
3. **LRU cache** — Sound buffer eviction when count exceeds ~50
4. **Advanced mixer UI** — Per-category volume controls beyond MVP toggles
5. **TTS ducking** — Screen reader audio coordination
6. **New verb sounds** — Spell incantation or new verb-specific sounds (Smithers #9)
7. **Cache-bust staging validation** — Manual QA on deployed staging server (Marge #8)

This list prevents scope creep mid-wave. Any team member who encounters a Phase 2 item during implementation should capture it to `.squad/decisions/inbox/` and continue.

---

*End of Sound System Implementation Plan — v1.1*
