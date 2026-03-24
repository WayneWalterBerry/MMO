# Decision Log: March 25 Daily Plan Update

**Date:** 2026-03-25  
**Owner:** Chalmers (Project Manager)  
**Status:** PENDING WAYNE APPROVAL

---

## Executive Summary

March 24 shipped 12 major features + 63 closed issues. Six carry-over items now have formal tracking (GitHub issues #158–163). March 25 plan restructured with:
- **P0 (must-ship today):** Engine code review + meta-compiler research/design
- **P1 (today if time permits):** Deploy, docs updates, newspaper hold clarification
- **P2 (after P0):** Design work + backlog triage
- **Dependencies:** Explicit blocking graph showing research → design → build → validate sequence

---

## Four Open Questions for Wayne (Resolve Now)

### 1. P0-A Sequencing: Refactor Before or After Meta-Compiler?

**Context:** `verbs/init.lua` is 5,817 lines (31+ verb handlers in one file). Should we split it before or after meta-compiler ships?

**Option A: Refactor First**
- Pros: Cleaner code architecture, easier for meta-check semantic analysis, LLM context smaller
- Cons: +3 hours work today, delays meta-compiler ship
- Sequence: (1) Bart reviews, (2) Nelson tests, (3) refactor, (4) THEN meta-compiler

**Option B: Meta-Compiler First**
- Pros: Ship meta-check today as planned, validate current sprawling code, use compiler as safety net for future refactoring
- Cons: Harder to refactor later (bigger code surface), larger LLM context now
- Sequence: (1) Meta-check ships, (2) refactor later with compiler as CI gate

**Recommendation:** **Option B** (meta-compiler first) — Ships key tool today, refactoring becomes Phase 2 work with better safety guarantees. But this is Wayne's call.

---

### 2. P0-B Tool Details: Language, Naming, Location

**Context:** Meta-check will validate .lua object/room/level files at CI time (before runtime).

**Decisions Needed:**
- **Language:** Confirmed Python + Lark? Or different? (Python is in scripts/, Lark has proven Lua parsing)
- **Naming:** `meta-check` confirmed? Location: `scripts/meta-check/` or `src/meta-check/` or `bin/meta-check`?
- **CI Integration:** Should this become a hard gate (tests fail if meta-check fails)?
- **Config:** Rules live in code, or separate `meta-check-rules.json`?

**Recommendation:** Python + Lark in `scripts/meta-check/check.py`, CI-gated after validation by Lisa. But confirm.

---

### 3. Deploy Timing: Before or After Refactoring Work?

**Context:** March 24 work (armor, event_output, 25+ bug fixes) is on main but not on live site (#158).

**Option A: Deploy Now**
- Pros: Live site gets March 24 features immediately, players test, faster feedback loop
- Cons: If P0-A refactoring breaks something, deploy rollback is messy
- Sequence: (1) Deploy, (2) refactor with canary testing, (3) deploy Phase 2

**Option B: Deploy After P0s**
- Pros: No deploy churn, P0-A refactoring validates cleanly, deploy once with both P0s
- Cons: Players wait longer, live site stale for 1–2 days
- Sequence: (1) Refactor, (2) meta-check ships, (3) deploy both

**Recommendation:** **Option A** (deploy now) — Keeps live site moving, players get immediate value, P0-A refactoring is code-only (no runtime impact if done correctly). But test first.

---

### 4. #159 (Evening Newspaper): Confirm Hold Until P0s Complete

**Context:** Evening newspaper (edition 2) was flagged #159 but hasn't shipped. Wayne's directive D-NO-NEWSPAPER-PENDING says hold until P0s done.

**Question:** Is this still the intent? Should newspaper be P1 or stay deferred until P0s ship?

**Current Status:** Held per D-NO-NEWSPAPER-PENDING. No action today.

---

## Dependencies Documented

See "Dependencies Graph" in plan for explicit blocking relationships:

**Critical Path (Serial):**
1. P0-A: Code review (1–2 hr) → Bart recommends splits
2. P0-B Research (30 min) → Answers 5 questions
3. P0-B Design Docs (1 hr) → Brockman + Bart create `docs/meta-check/`
4. P0-B Build (2–3 hr) → Implement meta-check CLI
5. P0-B Validation (30 min) → Lisa tests on existing objects
6. **Then:** P1 work (deploy, docs, newspaper)

**Parallel Work (Can start now):**
- Bart begins P0-A code review immediately (doesn't wait for meta-check)
- Nelson prepares test coverage audit for functions Bart will recommend splitting
- Frink starts P0-B research (bug catalog, Lark prototype) in parallel with Bart's review

---

## Carry-Over Summary

### What Shipped (March 24)
- 12 major features (armor, equipment hooks, event_output, etc.)
- 14+ bug fixes (parser cluster, ceramic pot, brass bowl, on_drop tests, etc.)
- 63 GitHub issues closed
- 1,088 tests passing
- Code on main branch, ready to deploy

### What Didn't Ship (6 Items Now Tracked)
| Issue | Title | Owner | Status |
|-------|-------|-------|--------|
| #158 | Deploy March 24 work | Gil | Blocked: manual approval gate |
| #159 | Evening newspaper | Flanders | Held per D-NO-NEWSPAPER-PENDING |
| #160 | Docs: event-hooks.md | Brockman | Blocked: P0-B validation first |
| #161 | Docs: effects-pipeline.md | Brockman | Blocked: P0-B validation first |
| #162 | Design: Injury-causing objects | Comic Book Guy | Blocked: puzzle dependency, Wayne clarification needed |
| #163 | Test: Material audit CI | Nelson | Blocked: P0-B meta-compiler rules |

---

## Process Rules Embedded in Plan

All Wayne's TDD-First directives now documented in plan section "Process Rules (Wayne's TDD-First Directives)":
- Plan first (>2 hr work gets written down)
- Test coverage before refactoring (no regressions)
- Commit between phases (clear git history)
- Deploy gate: all tests pass (1,088+ tests, no flakes)
- Refactoring sequence is non-negotiable (D-REFACTOR)

---

## Next Actions

1. **Wayne approves/clarifies 4 open questions** (sequencing, tool details, deploy timing, newspaper)
2. **Bart starts P0-A code review immediately** (can work in parallel)
3. **Frink starts P0-B research** (bug catalog, Lark prototype)
4. **Nelson prepares test audit** (for functions Bart will recommend splitting)
5. **Brockman blocks** on P0-B design doc approval (can't write docs until Lisa finalizes rules)
6. **Chalmers monitors blockers** and escalates any delays to Wayne

---

## Confidence Level

**HIGH (85%)** — Plan is comprehensive, process rules clear, carry-over fully catalogued, research questions specific, and dependencies explicit. Main uncertainty is whether to refactor before or after meta-compiler; rest is execution.
