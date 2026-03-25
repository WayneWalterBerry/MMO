# Decision: Unconsciousness Trigger Object Design

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-07-26  
**Status:** Design Complete  
**Issue:** #162  

---

## Decision: D-UNCON-TRIGGERS

### Summary

Four unconsciousness trigger objects designed for game-wide deployment. All use the existing `concussion` injury type — no new injury definitions created.

### Trigger Objects

| Object | ID | Severity | Duration | One-shot? | Self-infliction? |
|--------|----|----------|----------|-----------|------------------|
| Falling Rock Trap | `falling-rock-trap` | Severe | 10–15 turns | Yes (permanent) | Yes — `pull wire`, `trigger trap` |
| Ceiling Collapse | `unstable-ceiling` | Severe | 12–18 turns | Yes (permanent, room mutates) | Yes — `push beam`, `shout` |
| Poison Gas Vent | `poison-gas-vent` | Minor | 3–5 turns | **No — resets** | Yes — `breathe gas`, `inhale fumes` |
| Enemy Blow (Club Trap) | `falling-club-trap` | Moderate | 6–10 turns | Yes (permanent) | Yes — `step on plate`, `trigger trap` |

### Key Decisions

1. **Unified injury type:** All triggers inflict `concussion`. No new injury types.
2. **Ceiling collapse is dual-injury:** Inflicts `concussion` + `crushing-wound` simultaneously. Most dangerous trigger (25 HP initial + 2/turn bleed during KO).
3. **Gas vent resets:** Only resettable trigger. Creates room-escape puzzle dynamic.
4. **Enemy blow = mechanical trap in V1:** Principle 0 (no NPCs). Spring-loaded club simulates combat strike. Real NPC strikes will use same `concussion` injury in Phase 2+.
5. **Smell vs breathe distinction:** `smell gas` = warning (sensory), `breathe gas` = self-infliction trigger. Smithers must route these differently.
6. **Meta-commands bypass consciousness gate:** `save` and `quit` must work during unconsciousness. Only player-action commands are rejected.
7. **Self-inflicted KO + external injuries = death possible:** Self-infliction ceiling protects against self-inflicted damage killing, but external injuries (e.g., a bleeding wound from a prior stab) continue ticking during self-inflicted unconsciousness and CAN kill.

### Who Should Know

- **Flanders:** Build 4 object `.lua` files per spec in `docs/design/injuries/unconsciousness-triggers.md`
- **Bart:** Verify injury stacking during unconsciousness handles dual-injury ceiling collapse and self-infliction ceiling edge cases
- **Nelson:** Write failing tests first (D-TESTFIRST) — 13+ test cases specified in the design doc §6
- **Smithers:** Route self-infliction commands per trigger, implement rejection message pools with source-specific narration, gate meta-commands
- **Sideshow Bob:** Gas vent is a natural room-escape puzzle; rock trap rewards observation in darkness (feel wire → cut it); ceiling collapse teaches stealth; self-KO is a puzzle mechanic

### Design Doc

`docs/design/injuries/unconsciousness-triggers.md`
