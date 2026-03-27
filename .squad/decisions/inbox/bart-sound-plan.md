# D-SOUND-ARCHITECTURE: Sound System Engine Architecture

**Author:** Bart (Architecture Lead)
**Date:** 2026-07-31
**Status:** 🟢 Active
**Category:** Architecture
**Plan:** `plans/sound-implementation-plan.md` (Section 1)
**Research:** `resources/research/sound/sound-effects-research.md` (Frink)

## Decision

The sound system is a layered, optional engine subsystem that follows Principle 8 (objects declare, engine executes). Key architectural decisions:

### D-SOUND-1: Object Sound Metadata

Objects declare sounds via an optional `sounds` table keyed by event prefix (`on_state_`, `ambient_`, `on_verb_`, `on_mutate`, `on_pickup`, `on_drop`). The engine resolves keys at dispatch time — no object-specific sound logic in engine code.

### D-SOUND-2: Lazy Loading via Loader Piggyback

Sound files load when their owning object loads. `sound_manager:scan_object(obj)` is called after `registry:register()`. No bulk preload, no sound manifest file. Memory bounded to one room's audio + hand-held items.

### D-SOUND-3: Platform Driver Interface

The sound manager delegates playback to an injected driver. Two drivers ship: `web/sound-driver.lua` (Web Audio API via Fengari JS bridge) and `src/engine/sound/terminal-driver.lua` (os.execute best-effort). No driver = no-op mode. Headless/CI always no-op.

### D-SOUND-4: Room-Scoped Audio

Earshot = current room + player's hands. Room transitions stop old ambients, start new ones. Objects in player's hands retain their sounds across rooms. Mutation stops old object sounds, scans new object.

### D-SOUND-5: Sound Is Enhancement Only

Every sound event has a text equivalent. Game is fully playable on mute. No gameplay information conveyed exclusively through audio. This is Wayne's explicit accessibility requirement.

### D-SOUND-6: Pre-Compressed Delivery

OGG files stored compressed on server, decoded by browser natively. Terminal uses WAV (no decoder needed). No runtime compression in engine code.

### D-SOUND-7: Effects Pipeline Integration

A `play_sound` effect type is registered in `effects.lua`, allowing FSM transitions and any other system to trigger sounds through the existing effect dispatch pipeline.

## Affected Team Members

| Member | Impact |
|--------|--------|
| **Gil** | Must implement `web/sound-driver.lua` and `web/sound-bridge.js`. Add `_loadSound` JS global. |
| **Flanders** | Will add `sounds = {}` tables to object .lua files (Phase 1: 12-15 objects). |
| **Moe** | Will add `sounds = {}` to room .lua files for ambient and on_enter sounds. |
| **Comic Book Guy** | Owns sound design: which sounds for which objects, asset sourcing, naming conventions. |
| **Nelson** | Will need tests for sound manager module (unit) and integration (room transitions). |
| **Smithers** | May need to add sound-related UI (mute toggle, volume indicator). |

## Files Created/Modified

- `plans/sound-implementation-plan.md` — New: implementation plan (Section 1: Engine Architecture)
- `src/engine/sound/init.lua` — Future: sound manager module
- `src/engine/sound/defaults.lua` — Future: verb-to-sound fallback table
- `src/engine/sound/terminal-driver.lua` — Future: terminal platform driver
- `web/sound-driver.lua` — Future: web platform driver
- `web/sound-bridge.js` — Future: JS Web Audio API helper
