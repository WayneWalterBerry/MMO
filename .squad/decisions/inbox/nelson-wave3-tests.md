# D-WAVE3-TESTS — WAVE-3 TDD Test Delivery

**Author:** Nelson (QA)
**Date:** 2026-07-31
**Status:** Active

## Decision

WAVE-3 TDD tests are delivered as red-phase tests. 41 tests across 2 files validate the spec before implementation is complete.

## Key Findings for Other Agents

### For Bart (Tracks 3A, 3B)
- `combat.initiate()` works for 2-combatant turn order. Multi-combatant (`get_turn_order`) not yet exposed.
- `active_fights` table must be created/tracked/cleaned on `context` — tests expect `{ combatants, room_id, round }` structure.
- `attempt_flee(ctx, creature)` must move creature to adjacent room via portal exits. Tests mock portal-based exits.
- Cornered fallback: when `attempt_flee` finds no valid exits, must set `creature._cornered = true` or `creature._stance = "cornered"`.
- Cornered bonus: `get_effective_attack(creature)` must multiply force by 1.5 when cornered.
- `select_target(ctx, creature)` must check prey list first, then fall back to aggression threshold for non-prey targets.

### For Smithers (Track 3C)
- `narration.describe_exchange(result, opts)` must accept `opts.distance` ("same", "adjacent", "out_of_range") and `opts.witness` (boolean).
- Adjacent narration: 1 line max, distant/muffled language.
- Out-of-range: must return nil or empty string.
- Budget system: `narration.new_budget(cap)` → budget state; `narration.emit(result, budget, opts)` → string or nil.
- Budget protocol: suppress non-critical (sev ≤ 1) after cap; always emit critical (sev ≥ 3); player combat exempt (`opts.player_combat = true`).
- Morale break narration (`opts.morale_break = true`) counts toward budget.

## Impact
- Tests validate against spec, not implementation — expected to fail until Bart/Smithers complete their tracks.
- 0 regressions in existing test suite.
