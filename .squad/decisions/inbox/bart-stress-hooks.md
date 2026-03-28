# D-STRESS-HOOKS: Stress Trauma Hook Architecture

**Author:** Bart (Architect)
**Date:** 2026-03-28
**Category:** Architecture
**Status:** ✅ Implemented

## Decision

Stress trauma hooks follow the same pattern as the C11/C12 injury and stimulus hooks — minimal integration points that delegate to a central API (`injuries.add_stress`). No stress-specific logic lives in the caller.

## Key Design Points

1. **Three trauma hooks, three files:** `witness_creature_death` (death.lua), `near_death_combat` (combat/init.lua), `witness_gore` (butchery.lua). Each is a single call to `injuries.add_stress(player, trigger_name)`.

2. **Stress debuffs as multipliers:**
   - `attack_penalty` → 15% force reduction per point (floor 0.3×) in `resolution.resolve_damage`
   - `movement_penalty` → probability of movement failure in `verbs/movement.lua` + reduced flee speed in `verbs/init.lua`
   - `flee_bias` → auto-selects flee in headless mode; narrative hint in interactive mode

3. **`is_safe_room(room, registry)`** checks for alive creatures with `behavior.aggression > 0`. Separate from `cure_stress` for flexibility.

4. **Graceful degradation:** All hooks pcall-guard the `engine.injuries` require. If stress.lua metadata doesn't exist, all hooks are no-ops.

## Affects

- **Nelson:** Tests should verify stress accumulation across triggers and debuff application. See GATE-3 criteria in plan.
- **Smithers:** Narration tables are in injuries/init.lua — review/own the text.
- **Flanders:** stress.lua already matches expected schema. No changes needed.
