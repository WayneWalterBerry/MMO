---
updated_at: 2026-03-19T11:27:41Z
focus_area: Tier 2 parser live + FSM engine design complete. Next: implement FSM engine.
active_issues: []
---

# What We're Focused On

**Phase 2 Complete:** Tier 2 embedding-based parser is now live in the game loop. FSM object lifecycle design is complete. Ready for FSM engine implementation.

## Completed (Batch 2)

- ✅ **Bart:** Tier 2 Parser Wired
  - Trimmed embedding index: 29,582 → 4,337 phrases (gzip 34MB → 4.9MB)
  - Created Jaccard phrase-text matcher in Lua (no ONNX needed yet)
  - Wired into game loop: Tier 1 (exact dispatch) → Tier 2 (similarity) on miss
  - Threshold 0.40; fails visibly below threshold with diagnostic output
  - Files: `src/engine/parser/init.lua`, `embedding_matcher.lua`, loop integration
  - **Status:** Tested, committed
  
- ✅ **Comic Book Guy:** FSM Object Lifecycle Design
  - Designed 7 FSM objects: match (3 states), candle (4 states), 5 containers
  - 32 static objects catalogued (no FSM needed)
  - Duration tick system (event-driven: 1 tick = 1 player command)
  - Consumables: finite duration with terminal "spent" state
  - Containers: reversible open/closed, no terminal states
  - Warning thresholds tunable (match: 5 ticks, candle: 10 ticks)
  - Ticks fire before verb execution (fair resource consumption)
  - File: `docs/design/fsm-object-lifecycle.md` (25KB)
  - **Status:** Ready for implementation

## Artifacts Generated (Batch 3)

- `.squad/orchestration-log/bart-20260319-112741.md` — Bart's work summary
- `.squad/orchestration-log/cbg-20260319-112741.md` — CBG's work summary
- `.squad/log/20260319-tier2-wired-fsm-designed.md` — Session log
- `.squad/decisions.md` — Merged decisions 6 & 7 (Tier 2 Wiring, FSM Design)

## Cross-Agent Context

- **Bart → CBG:** Tier 2 parser live; can test ~400 command variations now
- **CBG → Bart:** FSM design done; next task is FSM engine implementation from this design

## Immediate Next Steps

1. **Bart's next task:** Build FSM engine from CBG's design
   - FSM data structure with transitions and auto-conditions
   - State machine dispatcher
   - Tick counter and auto-transition checks
   - Warning threshold system
   
2. **CBG's next task:** Phase 2 consumable object conversion (match → FSM)
   - Merge match.lua + match-lit.lua
   - Test duration mechanics and warning thresholds

## Pending Directives

- **Not yet shipped:** Phase 1 FSM engine (pending Bart implementation)
- **Blocked:** Paper dynamics, knife/pin as injury tools, sewing (awaiting FSM foundation)
- **Research:** Chalmers' Phase 1 LLM data generation (pending Wayne)
- **Prototype:** Frink's PWA + Wasmoon (pending Wayne greenlight)
