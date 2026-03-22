# Decision: Appearance Subsystem + Consciousness Architecture

**Author:** Bart (Architect)  
**Date:** 2026-03-23  
**Status:** Designed (pending implementation)

## Appearance Subsystem (D-APP001 through D-APP006)

- **D-APP001:** Appearance is an engine subsystem at `src/engine/player/appearance.lua`, not object logic. Objects set `is_mirror` flag; engine calls `appearance.describe(player)`.
- **D-APP002:** Layered head-to-toe rendering (head, torso, arms, hands, legs, feet, overall). Each layer is an independent function returning a phrase or nil.
- **D-APP003:** Nil layers are silently skipped — no "you see nothing" filler.
- **D-APP004:** `appearance.describe()` takes any player state table — works for self (mirror) or another player (future multiplayer).
- **D-APP005:** Injury phrases are composed via a 4-stage pipeline: location → severity → treatment → natural phrase.
- **D-APP006:** Object appearance metadata (`appearance.worn_description`) is optional with graceful fallback to `name`.

## Consciousness State Machine (D-CONSC001 through D-CONSC008)

- **D-CONSC001:** Consciousness is a player-level field (`player.consciousness`) — not engine-level.
- **D-CONSC002:** Binary conscious/unconscious only — no dazed/intermediate state (Wayne directive).
- **D-CONSC003:** Game loop uses simple `if/else` on `player.consciousness.state`, not a formal FSM module.
- **D-CONSC004:** Injury system (`injury_mod.tick`) is unchanged — consciousness calls it, no coupling.
- **D-CONSC005:** Sleep and unconsciousness share the same "inactive ticking" model — both tick injuries per turn.
- **D-CONSC006:** Death check runs before wake timer check — can't wake up from death.
- **D-CONSC007:** Missing `consciousness` field = conscious (backward compatible with old saves).
- **D-CONSC008:** Wake timer is turn-based, not time-based.

## Implementation Gap Found

The current sleep verb (`verbs/init.lua:4827+`) does NOT call `injury_mod.tick()` during its tick loop. This means sleeping with active bleeding is currently safe — which contradicts the design intent. The consciousness doc specifies the fix.

## Affects

- **Smithers:** Will implement both subsystems using these specs.
- **Flanders:** Mirror objects need `is_mirror` flag. Injury defs can add `appearance_noun` field.
- **Nelson:** Testing matrix for both subsystems is in the daily plan.
