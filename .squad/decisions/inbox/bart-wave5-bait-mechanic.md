# Decision: Bait Mechanic Architecture (Track 5C)

**Author:** Bart (Architecture Lead)
**Date:** 2026-03-28
**Commit:** `edabb12`
**Scope:** WAVE-5 Track 5C — food-as-bait behavior

## Decision

Bait behavior is implemented as a **preemptive check** in `creature_tick()`, evaluated after stimulus processing but before utility-scored action selection. When a creature is hungry and food with matching `bait_targets` exists in the same or adjacent room, bait behavior takes priority over normal wander/idle/attack actions (returns early, skipping `score_actions`).

## Key Design Choices

1. **Bait preempts action scoring:** Rather than adding a "seek_food" action to `score_actions`, bait is checked before scoring. This prevents hunger-vs-wander competition and ensures reliable bait luring (no randomness).

2. **Combat suppresses hunger:** Both `ctx.combat_active` flag and `combat.find_fight_for_combatant()` are checked. An in-combat creature ignores food entirely.

3. **Same-room consumption is immediate:** When food is in the creature's current room, it's consumed in a single tick (no multi-tick approach). This matches the spec and keeps the mechanic simple.

4. **Adjacent-room movement is per-tick:** The creature moves one room toward food per tick, then consumes on the next tick when co-located.

5. **bait_value priority:** When multiple food items target the same creature, highest `bait_value` is consumed/approached first.

## Affects

- **Nelson (tests):** Bait narration is both returned from `creature_tick()` as messages AND printed to stdout. Tests capturing `print` output will see narration.
- **Smithers (verbs):** No interaction — eat/drink verbs are independent of creature bait consumption.
- **Flanders (objects):** Food objects must have `food = { bait_targets = {...}, bait_value = N }` for bait to work. No object file changes needed from engine side.

## Navigation Enhancement

String portal IDs in room exits are now resolved automatically by `is_exit_passable()` and `get_exit_target()`. Previously only table-format exits (`{ portal = "guid" }`) were supported; now bare string GUIDs work too. This unblocks any room definitions using string portal references.

## R-5 Boundary

No cooking, recipes, or spoilage-driven creature behavior. Bait is purely `bait_targets` matching + `bait_value` priority.
