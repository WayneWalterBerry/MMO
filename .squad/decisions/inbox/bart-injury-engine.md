# Decision: Injury Engine — Pass 2

**Author:** Bart (Lead Engineer)  
**Date:** 2026-07-25  
**Status:** IMPLEMENTED  
**Requested by:** Wayne Berry

---

## Decisions

### D-INJURY010: Injury engine is a standalone module
**Decision:** The injury system lives in `src/engine/injuries.lua` as a self-contained module with no hard dependencies on verbs, loop, or UI.

**Rationale:** The injury engine needs to be callable from multiple places — the game loop (ticking), verb handlers (infliction/healing), and the UI (health display). A standalone module with a clean API (`inflict`, `tick`, `compute_health`, `try_heal`, `list`) keeps coupling minimal and testing straightforward.

**Alternatives considered:** Embedding injury logic directly in the verb handlers or the loop. Rejected because it would create circular dependencies and make unit testing impossible without the full game context.

### D-INJURY011: Injury definitions loaded via require with test injection
**Decision:** Injury definitions are loaded from `src/meta/injuries/{type}.lua` via `require()`, with a `register_definition()` API for test injection.

**Rationale:** Follows the same pattern as object `.lua` files — metadata-driven, author-editable, no engine changes needed for new injury types. The test injection API (`register_definition` / `clear_cache`) enables isolated unit testing without filesystem access.

### D-INJURY012: Poison bottle wires through injury system
**Decision:** The poison bottle's drink handler now calls `injuries.inflict(player, "poisoned-nightshade", obj.id)` instead of setting `ctx.game_over = true` directly. The poisoned-nightshade injury starts at 15 damage + 8/tick, so drinking poison is survivable if the player has an antidote.

**Rationale:** This demonstrates the injury system end-to-end and creates gameplay possibility — the player has a window to find an antidote before the poison kills them. The old instant-death path is preserved as a fallback if the injury module fails to load.

**Gameplay impact:** Drinking poison is no longer instant death. The player takes 15 damage immediately, then 8 per turn. With 100 max health, they have roughly 10 turns to find and drink an antidote. This creates tension and puzzle pressure.

---

## Files Created
- `src/engine/injuries.lua` — Core injury engine
- `src/meta/injuries/poisoned-nightshade.lua` — First injury FSM definition
- `test/injuries/test-injury-engine.lua` — 49-assertion test suite

## Files Modified
- `src/main.lua` — Added `player.max_health` and `player.injuries`
- `src/engine/loop/init.lua` — Injury tick + death check in game loop
- `src/engine/verbs/init.lua` — `injuries`, `apply` verbs + poison drink wiring
- `test/run-tests.lua` — Added `test/injuries/` directory to scanner

## Test Results
175/175 pass (49 new + 126 existing unchanged)
