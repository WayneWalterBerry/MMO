# Session Log: Tier 2 Wired + FSM Designed
**Date:** 2026-03-19  
**Timestamp:** 2026-03-19T11:27:41Z  

## Session Summary

Two parallel agents completed their work:

### Bart: Tier 2 Parser Wired
- Trimmed embedding index: 29,582 → 4,337 phrases (gzip 34MB → 4.9MB)
- Created Lua parser module with Jaccard phrase-text similarity matching
- Wired into game loop: Tier 1 (exact verb dispatch) → fallback to Tier 2 (similarity matching)
- Threshold set to 0.40 (below: command fails with diagnostic output)
- No ONNX in Lua; real embedding vectors deferred to browser runtime
- Files: `src/engine/parser/init.lua`, `embedding_matcher.lua`, game loop integration
- Status: Tested successfully, committed

### Comic Book Guy: FSM Object Lifecycle Designed
- Designed unified FSM for consumables (match, candle) and containers (nightstand, wardrobe, window, curtains, vanity)
- 7 FSM objects total, 32 static objects (no state needed)
- Key pattern: One logical object, multiple state files, FSM definitions for transitions
- Consumables: duration-based auto-expiry with terminal "spent" state
- Containers: reversible open/closed with no terminal states
- Tick system: event-driven (1 tick = 1 player command), ticks before verb execution
- Warning thresholds: match at 5 ticks, candle at 10 ticks (tunable)
- File: `docs/design/fsm-object-lifecycle.md`
- Status: Ready for architect implementation

## Cross-Agent Context
- Bart: Tier 2 is live; CBG can test parser on ~400 command variations
- CBG: FSM design complete; Bart's next task is FSM engine implementation
- QA: Diagnostic parser output enables systematic testing

## Directives Captured
1. Match-lit.lua + match.lua → one FSM object (duration-based state machine)
2. All object state management → FSM approach (hybrid: FSM defs + per-state files)
3. Ship lean index, play test empirically, expand if needed
4. No fallback past Tier 2 (fail visibly on miss)

## Files Involved
- Orchest logs: `.squad/orchestration-log/bart-*.md`, `.squad/orchestration-log/cbg-*.md`
- Decisions merged into `.squad/decisions.md`
- Design doc: `docs/design/fsm-object-lifecycle.md` (newly created)
- Parser wiring: `src/engine/parser/*`, `src/engine/loop/init.lua`

## Immediate Next Steps
1. Merge decision inbox into decisions.md ✓
2. Update .squad/identity/now.md with focus shift
3. Archive decisions.md if >20KB
4. Git commit .squad/ changes
