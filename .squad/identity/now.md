---
updated_at: 2026-03-19T16:28:39Z
focus_area: Planning + research complete — ready for engineering phase
active_issues: []
---

# What We're Focused On

V1 REPL is playable and tested. Foundation work (engine, verbs, tools, skills system) delivered. New planning phase complete:
- ✅ Feel verb bug fixed, container/surface enumeration working
- ✅ All batch 1 pending items addressed (blockers fixed, objects designed, skills system designed, docs swept)
- ✅ Parser plan delivered (Tier 2 embedding-based, 6 phases, 10 working days)
- ✅ PWA+Wasmoon research complete (5–7hr prototype, high confidence)

**Next decisions needed from Wayne:**
1. Chalmers' open questions: accuracy threshold, Tier 3 optional SLM, training volume
2. Greenlight Frink's PWA prototype (5–7hr)

## Artifacts Generated (Batch 2)

- `plan/llm-slm-parser-plan.md` — Tier 2 embedding parser implementation (445 lines, 17.6KB)
- `.squad/agents/frink/research-pwa-wasmoon.md` — PWA + Wasmoon feasibility study (28.5KB)
- `docs/design/player-skills.md` — Skills system architecture (24.3KB)

## Decisions Filed

- **D-42:** Tier 2 Embedding Parser (references D-19, D-17)
- **D-43:** PWA + Wasmoon Prototype Feasibility

## Still Pending (engineering phase)

- Chalmers: Phase 1 LLM data generation (pending Wayne approval)
- Frink: PWA prototype (5–7hr, pending greenlight)
- Bart: Wire WRITE, CUT, SEW, PICK LOCK verbs (blocked until Chalmers Phase 1 begins)
- Comic Book Guy: New object designs (paper, pen, knife, pin, needle) awaiting integration
- Brockman: Ongoing newspaper/docs as engineering progresses

## Recent Directives Not Yet Implemented

- Paper mutates with written words (dynamic mutation)
- Knife/pin as injury tools → blood for writing
- Sewing: cloth → clothing with needle
- Puzzles are first-class design goal
