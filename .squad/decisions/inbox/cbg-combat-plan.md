# Decision: Combat System Plan Complete

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-07-28  
**Category:** Design  
**Status:** 🟢 Active  

## Decision

The combat system design plan (`plans/combat-system-plan.md`) is the authoritative design document for all combat features. It defines:

1. **Body zone system** — 4–6 zones per creature, unified with armor slots, declared as `body_tree` in creature `.lua` metadata (D-COMBAT-1, D-COMBAT-3, D-COMBAT-4)
2. **Combat phases** — 6-phase engine-driven FSM (initiate → declare → respond → resolve → narrate → update), inspired by MTG's structured combat phases (D-COMBAT-2)
3. **Material-based damage** — weapon material × force vs. armor + tissue layers, using the existing 17+ material registry (Principle 9)
4. **Unified combatant interface** — one `resolve_exchange()` function for all combat (player-vs-NPC, NPC-vs-NPC)
5. **Disease delivery** — `on_hit` mechanism on natural weapons for rabies, venom, lycanthropy
6. **4-phase implementation roadmap** — Phase 1 (rat), Phase 2 (creature variety + disease), Phase 3 (advanced), Phase 4 (humanoid NPCs)

## Impact

- **Bart:** Build `src/engine/combat/init.lua` per the 6-phase FSM spec. Material damage resolution function follows Section 5 formulas.
- **Flanders:** Add `body_tree` and `combat` tables to rat + player definitions. Create tissue materials (skin, hide, bone, organ, tooth_enamel, keratin).
- **Smithers:** Extend attack/hit/strike verbs to target creatures. Implement combat response prompts (block/dodge/counter/flee).
- **Nelson:** Create `test/combat/` test directory. Material interaction tests, FSM state tests, creature death tests.
- **NPC Plan (D-COMBAT-5):** The NPC system plan must be updated — `body_tree` is required from Phase 1, not deferred to Phase 4.

## Wayne's Directives Implemented

- D-COMBAT-1: ✅ 4–6 body zones (Section 3)
- D-COMBAT-2: ✅ MTG phases as engine FSM (Section 4)
- D-COMBAT-3: ✅ Body zones = armor slots (Section 3.7)
- D-COMBAT-4: ✅ `body_tree` on every creature (Section 3.4)
- D-COMBAT-5: ✅ NPC plan update noted (Section 3.8)
