# Orchestration: Bart — GOAP Tier 3 Completion
**Date:** 2026-03-20T21:15Z
**Agent:** Bart (Architect)
**Status:** ✅ LANDED

## Spawn Summary
Bart was tasked with building the Goal-Oriented Action Planning (GOAP) Tier 3 backward-chaining parser — a prerequisite resolver that auto-executes preparatory steps when the player's intent requires tools they don't have.

## Implementation Delivered
- **Module:** `src/engine/parser/goal_planner.lua` (~220 lines) — Backward-chaining resolver, MAX_DEPTH=5 cycle prevention
- **Integration:** `src/engine/loop/init.lua` — Pre-check planner between Tier 1 verb dispatch and Tier 2 fallback
- **Verbs:** UNLOCK handler for exits (doors); exit examine/feel support
- **Metadata:** Objects with `requires_tool` transitions now support automatic planning
- **Bug fixes:** BUG-029 (iron door examinable), BUG-030 (UNLOCK verb implemented)

## Key Design Decisions
1. **Pre-check vs post-failure:** Planner runs BEFORE verb handler to avoid retrofitting return codes to 40+ handlers
2. **In-place container manipulation:** Containers opened without pickup, preserving hand capacity during plan execution
3. **Nested containment search:** 3-level deep (hands → room → containers → surfaces), handles matchbox→match chains
4. **Narrated execution:** "You'll need to prepare first..." then step-by-step output, no confirmation prompt
5. **Stop-on-failure:** If any step fails, plan aborts; world state consistent via real verb execution

## Risks Addressed
- Infinite loops: Cycle detection via visited-set, MAX_DEPTH=5 limit
- Wrong inferences: Only fires on explicit `requires_tool` metadata
- Hand capacity: In-place container ops eliminate mid-plan failures
- Narrative coherence: Narrated (not silent) execution

## Files Changed
- `src/engine/parser/goal_planner.lua` — created
- `src/engine/loop/init.lua` — planner integration, prepositional parsing, context tracking
- `src/engine/verbs/init.lua` — UNLOCK handler, exit examine/feel, help text
- `src/meta/objects/candle.lua` — prerequisites table added
- `src/meta/world/cellar.lua` — iron door: key_id, state descriptions, open mutation, on_feel

## Test Coverage
- Candle-match-matchbox chain: full backward resolution ✅
- Nested containment: matchbox in drawer on nightstand ✅
- UNLOCK + iron door: brass key unlocks cellar north door ✅

## Unblocked
- Player can now unlock doors with keys
- Multi-room progression beyond cellar blocked door now possible
- Goal-oriented commands ("light the candle") work with automatic planning

## Next Steps
- Extend `requires_property` prerequisites (not just `requires_tool`)
- Add implicit rules (auto-infer "holding" prerequisite)
- Tag additional objects with prerequisites (lantern, fireplace, crafting tools)
- Test GOAP with pass-007
