# Decision: NPC+Combat Implementation Plan

**Author:** Bart (Architect)  
**Date:** 2026-07-28  
**Category:** Architecture  
**Status:** 🟢 Active

## Decision

Created unified implementation plan at `plans/npc-combat-implementation-plan.md` that merges NPC Phase 1 and Combat Phase 1 into a 6-wave, 6-gate execution pipeline with explicit file ownership and TDD gates.

## Key Architectural Decisions in the Plan

1. **NPC Phase 1 ships before Combat Phase 1** — creature autonomy proven before adding combat complexity
2. **Creature tick integration point:** After fire propagation, before injury tick in `loop/init.lua`
3. **Stimulus system:** Simple event queue in `engine/creatures/init.lua`, consumed by creature tick
4. **Combat engine:** Single `resolve_exchange()` function handles all combatants generically (Principle C2, Principle 8)
5. **No file conflicts:** Explicit ownership map per wave — Smithers owns `verbs/init.lua`, Bart owns `movement.lua`/`combat.lua`/`effects.lua`/`fsm/init.lua`/`creatures/init.lua`/`combat/init.lua`/`loop/init.lua`
6. **Test runner expansion:** `test/creatures/` and `test/combat/` directories added incrementally

## Impact

- **Flanders:** Creates creature template, rat, flesh material (WAVE-1); retrofits body_tree + tissue materials (WAVE-4)
- **Bart:** Builds creature tick engine (WAVE-2), stimulus emission (WAVE-3), combat FSM (WAVE-5), combat integration (WAVE-6)
- **Smithers:** Implements catch/chase/attack verbs (WAVE-3), combat verb extensions (WAVE-6)
- **Moe:** Places rat in room (WAVE-3)
- **Nelson:** TDD test suite at every wave; LLM walkthroughs at GATE-3 and GATE-6
- **Coordinator:** Autonomous wave→gate→wave execution loop; Wayne check-in at GATE-3 and GATE-6 only
