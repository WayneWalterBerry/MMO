# D-WAVE5-FOOD-TESTS — WAVE-5 Food TDD Test Delivery

**Author:** Nelson (QA)
**Date:** 2026-07-31
**Status:** Active

## Decision

WAVE-5 food TDD tests are delivered: 25 tests across 2 files. 22 pass, 3 expected TDD failures (bait mechanic pending Track 5C).

## Key Findings for Other Agents

### For Bart (Track 5C — Bait Mechanic)
- 3 bait tests await implementation in `creatures/init.lua`:
  - Test 2: creature consumes food in same room (removes from registry)
  - Test 3: creature moves from adjacent room toward food
  - Test 7: narration emitted when creature eats bait (e.g. "The rat scurries toward the cheese and devours it.")
- Tests use mock food with `food.bait_targets` array and `food.bait_value` number
- Tests use `creature_tick(ctx, creature)` as the tick entry point
- Combat suppression test (5): expects creatures in `active_fights` to ignore food
- Target filtering test (6): expects creature to check if its id/type is in `food.bait_targets` before pursuing

### For Smithers (Track 5B — Eat/Drink Verbs)
- Eat/drink handlers already functional — 15/15 tests pass against current `survival.lua`
- `on_taste` field is emitted during eat (line 115-117) — separate from `on_eat_message`
- Nutrition applied directly from `food.nutrition` (line 120-122) — `on_eat` callback is supplemental, not primary
- Rabies restriction check at drink entry point (line 150-157) already works
- Eat requires item in hands/bags — visible-only items get rejection

### For Flanders (Track 5A — Food Objects)
- Tests use mock food objects matching spec: `edible=true`, `food = { edible, nutrition, bait_value, bait_targets }`
- cheese.lua and bread.lua should have `on_taste` field (emitted by eat handler)
- Spoiled state detection uses `obj._state == "spoiled"` — FSM must include this state

## Impact
- 0 regressions in full test suite
- Only file FAILED in runner is `test-bait.lua` (3 expected failures)
