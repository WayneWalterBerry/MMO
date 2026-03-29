# Sound System — Unified Implementation Plan

**Version:** 1.0
**Date:** 2026-07-31
**Status:** Plan Complete — Ready for Review
**Owner:** Wayne "Effe" Berry
**Architect:** Bart (Architecture Lead)
**Contributors:** Comic Book Guy (Game Design), Gil (Web Pipeline), Frink (Research)

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
        ▼  GATE-0: Module loads, no-op mode works, web bridge connects
        │
WAVE-1: Object Metadata + Asset Sourcing
  ├── Flanders: sounds tables on objects + creatures
  ├── Moe: room ambient declarations
  ├── CBG: design review (priority tiers, MVP sound list)
  └── Nelson: metadata validation tests
        │
        ▼  GATE-1: Objects declare sounds, files sourced, metadata tests pass
        │
WAVE-2: Engine Event Integration
  ├── Bart: FSM hooks, verb hooks, mutation hooks, room transition hooks
  ├── Smithers: effects pipeline play_sound type
  └── Nelson: integration tests (end-to-end sound triggers)
        │
        ▼  GATE-2: Sounds fire on state changes, verbs, room transitions
        │
WAVE-3: Polish + Deploy + Docs
  ├── Gil: build-sounds.ps1, deploy.ps1 update, cache-busting
  ├── Nelson: LLM headless walkthroughs
  └── Brockman: architecture + design documentation
        │
        ▼  GATE-3: Full pipeline works, docs shipped, LLM walkthroughs pass
```

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

-- Object scanning (called by loader)
M:scan_object(obj)             -- Extract sounds table, queue files
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
driver:play(handle, opts) → id     -- Play loaded sound; opts.volume, opts.loop
driver:stop(playback_id)           -- Stop a playing sound
driver:stop_all()                  -- Stop everything
driver:set_master_volume(level)    -- 0-100
driver:unload(handle)              -- Release resources
`

**Terminal Driver:** Detects platform (Windows/macOS/Linux) via `package.config` and `os.execute`. Fire-and-forget one-shots only. No loops, no volume control. Silent no-op on unsupported platforms. Max 2 second sounds.

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
- Register `test/sound/` in test runner

**Test approach:** Mock driver injected into sound manager. Verify: init, scan_object, trigger, play/stop lifecycle, no-op mode, room enter/exit.

### GATE-0 Criteria

- [ ] `src/engine/sound/init.lua` loads without errors
- [ ] Sound manager in no-op mode (nil driver): all methods return silently
- [ ] Web bridge functions exposed on `window` (6 functions)
- [ ] Lua bridge calls JS functions via `pcall()` without error
- [ ] `--headless` mode: `ctx.sound_manager` is nil, zero overhead
- [ ] `test/sound/` tests pass (mock driver)
- [ ] Zero regressions on existing test suite

---

## WAVE-1: Object Sound Metadata + Asset Sourcing

**Goal:** Add `sounds` tables to objects and creatures. Declare room ambients. Source all 24 MVP sound files. After this wave, objects know what they sound like; files exist on disk.

### Track 1A: Object/Creature Sound Metadata (Flanders)

**Files:** EDIT 15+ object `.lua` files in `src/meta/objects/` and `src/meta/creatures/`

**Sound key convention (prefix-based dispatch):**

| Prefix | Trigger | Example |
|--------|---------|---------|
| `on_state_{state}` | FSM enters state | `on_state_lit` |
| `ambient_{state}` | Loop while in state | `ambient_lit` |
| `on_verb_{verb}` | Verb acts on object | `on_verb_break` |
| `on_mutate` | Mutation fires | `on_mutate` |

**Creature sounds (all 5 creatures):** Per-state sounds mapped to `on_listen` text. Dead state = silence (deliberate design — absence of sound IS the sound).

**Priority objects (Tier 1):** Candle, match, torch, oil lantern, mirror, bear trap, all doors (8), all creatures (5).

**Design rule:** Every object with a `sounds` table MUST already have `on_feel` and `on_listen`. Sound never exists without its text equivalent.

### Track 1B: Room Ambient Declarations (Moe)

**Files:** EDIT 7 room `.lua` files in `src/meta/world/`

**Room ambient assignments:**

| Room | Ambient File | Character |
|------|-------------|-----------|
| Bedroom | `amb-bedroom-silence.ogg` | Near-silence; settling stone |
| Hallway | `amb-hallway-torches.ogg` | Torch crackle, timber creak |
| Cellar | `amb-cellar-drip.ogg` | Irregular water drips, stone echo |
| Storage Cellar | `amb-storage-scratching.ogg` | Rat scratching, old wood creak |
| Deep Cellar | `amb-deep-cellar-silence.ogg` | Oppressive near-silence |
| Crypt | `amb-crypt-void.ogg` | Borderline inaudible; rare stone settle |
| Courtyard | `amb-courtyard-wind.ogg` | Wind, rare owl hoot, ivy rustle |

**Room sound format:**
`lua
sounds = {
    ambient = "amb-cellar-drip.ogg",
    on_enter = "footsteps-stone.ogg",
}
`

### Track 1C: Asset Sourcing (CBG design review + Wayne)

**24 MVP sound files to source:** 8 creature, 4 door/passage, 3 fire/light, 4 combat/impact, 3 ambient loops, 2 destruction/event.

**Sourcing priority:** CC0 (Zapsplat, Sonniss) → CC-BY (OpenGameArt) → CC-BY-SA (Freesound). No CC-BY-NC (BBC) for commercial flexibility.

**Compression:** `ffmpeg -i input.wav -c:a libopus -b:a 48k -ac 1 output.opus`

**Size budget:** ~230 KB total (all 24 files). Per-room lazy load: ~30-80 KB per room.

**File location:** `assets/sounds/{category}/{name}.opus` (creatures/, objects/, combat/, ambient/)

### Track 1D: Metadata Tests (Nelson)

**Files:**
- CREATE `test/sound/test-sound-metadata.lua` — Validate all objects with `sounds` tables have: valid filenames, matching `on_listen`/`on_feel`, correct key prefixes

### GATE-1 Criteria

- [ ] 15+ objects/creatures have `sounds` tables with correct key prefixes
- [ ] 7 rooms declare ambient sounds
- [ ] 24 sound files sourced, compressed to Opus, stored in `assets/sounds/`
- [ ] Metadata tests pass (key format, file existence, accessibility check)
- [ ] Zero regressions

---

## WAVE-2: Event Integration + Engine Hooks

**Goal:** Wire the sound manager into engine event points. After this wave, sounds actually play when the player interacts with the world.

### Track 2A: Engine Event Hooks (Bart)

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
- [ ] Verb on object with `sounds` → correct sound triggered
- [ ] Verb on object without `sounds` → default sound triggered
- [ ] Room entry → ambient starts; room exit → ambient stops
- [ ] Mutation → old sounds stop, new object scanned, `on_mutate` fires
- [ ] Combat hit → damage-type impact sound fires
- [ ] `--headless`: zero sound calls, zero overhead
- [ ] Integration tests pass
- [ ] Zero regressions

---

## WAVE-3: Polish + Build Pipeline + Testing

**Goal:** Production-ready deployment. Build pipeline for sound assets, deploy integration, LLM walkthroughs, documentation.

### Track 3A: Build + Deploy Pipeline (Gil)

**Files:**
- CREATE `web/build-sounds.ps1` — Validate + copy sounds to `web/dist/sounds/` (flat namespace)
- EDIT `web/deploy.ps1` — Add sound directory copy step (~5 lines)

**Build pipeline:** Validate each file <100 KB, valid Opus format. Flatten `assets/sounds/{category}/` → `web/dist/sounds/`. Deploy to `../WayneWalterBerry.github.io/play/sounds/`.

**Cache-busting:** Reuse existing `CACHE_BUST` constant in bootstrapper.js. `fetch(url + '?v=' + CACHE_BUST)`.

**Player Controls (MVP):**
- Master volume (0-100, default 80)
- Sound effects toggle (on/off)
- Ambient toggle (on/off — some players want SFX but not loops)
- Text-only mode (explicit mute)
- Volume stored in `localStorage` for persistence

### Track 3B: LLM Walkthroughs (Nelson)

**Scenarios (all `--headless` + deterministic seed):**
1. Boot game → look → verify no sound errors in output
2. Light candle → verify FSM transition text (sound would fire on web)
3. Open door → move to hallway → verify room transition sequence
4. Encounter creature → verify creature state change text
5. Full Level 1 walkthrough → zero crashes, zero sound-related errors

### Track 3C: Documentation (Brockman)

**Files:**
- CREATE `docs/architecture/engine/sound-system.md` — Engine architecture, driver interface, hook points
- CREATE `docs/design/sound-design.md` — Sound design philosophy, priority tiers, accessibility rules
- UPDATE `docs/design/object-design-patterns.md` — Add `sounds` table pattern

### GATE-3 Criteria

- [ ] `build-sounds.ps1` runs successfully
- [ ] Sounds deploy to web dist directory
- [ ] LLM headless walkthroughs pass (5 scenarios)
- [ ] Architecture docs shipped
- [ ] Design docs shipped
- [ ] Object design patterns updated with `sounds` table
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
| Terminal `os.execute()` blocks game loop | Game freezes during sound playback | Medium | Cap at 2s; fire-and-forget; terminal sound is best-effort |
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

*End of Sound System Implementation Plan*
