# Orchestration Log: bart-bugfix-pass007
**Timestamp:** 2026-03-20T22:00Z  
**Agent:** Bart (Architect)  
**Status:** ✅ COMPLETE

## Deliverables
- **BUG-031 Fixed:** Compound "and" + GOAP clean output
  - Location: `src/engine/loop/init.lua` — new block detects if last sub-command has GOAP plan, skips earlier prerequisites
  - Logic: If GOAP can handle entire chain end-to-end, redundant early sub-commands are omitted
  - Impact: Player typing "get match from matchbox and light candle" now routes to GOAP for clean, coherent output

- **BUG-032 Fixed:** "burn" as GOAP synonym for "light"
  - Location: `src/engine/parser/goal_planner.lua` — new `VERB_SYNONYMS` table maps "burn" → "light"
  - Location: `src/engine/verbs/init.lua` — burn handler checks for "light" FSM transition before standalone logic
  - Location: `src/engine/loop/init.lua` — added "burn" to prepositional "with" stripping
  - Impact: Player can now `burn candle` and trigger GOAP backward-chaining like `light candle`

## Files Modified
1. `src/engine/parser/goal_planner.lua` — VERB_SYNONYMS + canonical verb lookup
2. `src/engine/verbs/init.lua` — burn handler logic
3. `src/engine/loop/init.lua` — compound command detection + "burn" stripping

## Design Notes
- VERB_SYNONYMS is a simple 1:1 map (not many-to-many) for clarity and extensibility
- Pattern replicable for future synonym pairs without engine changes
- No regression: existing "and" compound commands (non-GOAP) still split and process normally
- Edge case: "burn" verb now correctly identifies FSM-based lightable objects (candles) vs standalone burn targets

## Testing
- Verified in pass-007: `light candle` ✅, `burn candle` ✅, compound resolution ✅
- Zero regressions on existing verbs
