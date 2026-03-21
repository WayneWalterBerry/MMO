### Verb-Dependent Object Search Order in find_visible

**Date:** 2026-07-23  
**Author:** Smithers (Senior Engineer)  
**Requested by:** Wayne Berry (copilot-directive-2026-03-21T19-35Z)  
**Status:** Implemented  

---

#### What Changed

`find_visible` in `src/engine/verbs/init.lua` now uses verb-dependent search order instead of a fixed order.

**Before:** All verbs searched Room → Surfaces → Containers → Parts → Hands → Bags → Worn.

**After:**
- **Interaction verbs** (open, close, light, drink, pour, eat, extinguish, wear, remove, pry, shut): **Hands → Bags → Worn → Room → Surfaces → Parts**
- **Acquisition verbs** (take, examine, look, search, feel, smell, listen, and everything else): **Room → Surfaces → Parts → Hands → Bags → Worn** (identical to old fixed order)

#### Why

When a player holds a candle and there's one on the table:
- "light candle" should target the HELD candle (you're acting on it)
- "take candle" should target the TABLE candle (you're reaching for it)

The verb category determines the player's likely intent. Interaction verbs act on controlled objects (hands first). Acquisition verbs reach for world objects (room first).

#### How It Works

1. `ctx.current_verb` is set at all three dispatch points (game loop, Tier 2 parser fallback, Tier 3 GOAP execution) before calling the verb handler.
2. `find_visible` checks `ctx.current_verb` against the `interaction_verbs` lookup table.
3. Six sub-search functions (`_fv_room`, `_fv_surfaces`, `_fv_parts`, `_fv_hands`, `_fv_bags`, `_fv_worn`) are composed in the appropriate order.

#### Files Changed

| File | Change |
|------|--------|
| `src/engine/verbs/init.lua` | Added `interaction_verbs` table, refactored `find_visible` into composable sub-functions |
| `src/engine/loop/init.lua` | Set `context.current_verb = verb` before handler dispatch |
| `src/engine/parser/init.lua` | Set `context.current_verb = verb` before Tier 2 dispatch |
| `src/engine/parser/goal_planner.lua` | Set `ctx.current_verb = step.verb` before GOAP step dispatch |
| `test/inventory/test-search-order.lua` | **NEW** — 12 tests for verb-dependent resolution |

#### Test Results

- **114 original tests:** All pass (acquisition order = old fixed order, zero regression)
- **12 new tests:** All pass (interaction/acquisition/disambiguation/fallback)
- **Total: 126 tests, 0 failures**

#### Design Notes

- Verbs like `light`, `drink`, `eat`, `extinguish` call `find_in_inventory` BEFORE `find_visible`. They already get hands-first behavior. The verb-dependent `find_visible` serves as their fallback (for room-only items).
- `use` is in the interaction_verbs table but has no handler yet. When added, it will automatically get hands-first search.
- Adding new interaction verbs only requires adding them to the `interaction_verbs` table — no other changes needed.

#### For Other Engineers

- **Bart:** If you add new verbs that act on held objects, add them to `interaction_verbs` in verbs/init.lua.
- **Nelson:** The test file `test/inventory/test-search-order.lua` covers the new behavior. Add disambiguation test cases as new verbs are implemented.
- **Flanders:** Your instance-aware hands changes are compatible — just need to use `_hobj()` in the `_fv_hands` and `_fv_bags` sub-functions when merging.
