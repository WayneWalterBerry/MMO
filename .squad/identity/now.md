---
updated_at: 2026-03-22T00:00:00Z
focus_area: Play test fixes shipped. Tier 2 parser live + FSM engine implementation next. CYOA research in progress.
active_issues: []
---

# What We're Focused On

**Phase 2 Status:** Tier 2 embedding-based parser is live and robust (typo correction added). Play test bugs fixed. FSM object lifecycle design complete and validated. FSM engine implementation starting.

## Completed (Play Test Batch)

- ✅ **Bart:** Play Test Bug Fixes (4 bugs resolved)
  - Added "drawer" keyword to nightstand surface zone
  - Implemented NLP preprocessing for "what's inside" → look
  - Created matchbox-open.lua; added accessible gating to containers
  - Levenshtein typo correction in Tier 2 preprocessing
  - All fixes verified during playtesting
  - **Commit:** a6dc7b0
  
- ✅ **Comic Book Guy:** FSM Object Lifecycle Design (previous batch, now logged)
  - Designed 7 FSM objects (match, candle, 5 containers)
  - 32 static objects catalogued
  - Duration tick system (event-driven, per-command)
  - File-per-state pattern validated by matchbox fixes
  - Ready for FSM engine implementation
  - **File:** `docs/design/fsm-object-lifecycle.md` (25KB)

## In Progress

- ⏳ **Frink:** CYOA Book Series Research
  - Researching branching narrative patterns
  - Analyzing CYOA mechanics for story module design
  - Awaiting Wayne scope/timeline directive
  - Expected completion: Next session

## Artifacts Generated (Batch 4)

- `.squad/orchestration-log/2026-03-22T000000Z-bart-playtest-fixes.md` — Playtest fixes summary
- `.squad/orchestration-log/2026-03-22T000001Z-cbg-fsm-design-logged.md` — FSM design logging
- `.squad/orchestration-log/2026-03-22T000002Z-frink-cyoa-research.md` — Research status
- `.squad/log/2026-03-22T000000Z-playtest-fixes.md` — Session log
- `.squad/decisions.md` — Merged playtest fixes decision (#13)

## Cross-Agent Context

- **Bart → CBG:** Playtest fixes complete; matchbox-open.lua pattern validates file-per-state approach
- **CBG → Bart:** FSM design ready; Tier 2 supports ~400 command variations for testing
- **CBG → Frink:** FSM engine next priority; Frink research continues in parallel

## Immediate Next Steps

1. **Bart's next task:** Build FSM engine from CBG's design
   - FSM data structure with transitions and auto-conditions
   - State machine dispatcher
   - Tick counter and auto-transition checks
   - Warning threshold system
   
2. **CBG's next task:** Phase 2 consumable object conversion (match → FSM)
   - Merge match.lua + match-lit.lua
   - Implement via new FSM engine
   - Test duration mechanics and warning thresholds

3. **Frink's next task:** Complete CYOA research (pending Wayne)
   - Finalize research findings
   - Propose story module architecture

## Pending Directives

- **Wayne:** Greenlight Frink's CYOA research scope/timeline
- **Not yet shipped:** FSM engine (Bart starting implementation)
- **Blocked:** Paper dynamics, knife/pin as injury tools, sewing (awaiting FSM foundation)
- **Research:** Completed design phases; implementation underway

