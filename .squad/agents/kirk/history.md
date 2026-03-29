# Kirk — History

## Core Context

**Project:** MMO — a Lua text adventure game (Zork-inspired) for mobile/web
**Owner:** Wayne "Effe" Berry
**Stack:** Pure Lua, Fengari (browser), zero external dependencies
**Team:** 17+ members (Simpsons universe)
**My role:** Project Manager — cross-project boards, priorities, timeline tracking

## Current Projects (7 boards)

| Project | Board | Owner | Status |
|---------|-------|-------|--------|
| Linter | `projects/linter/board.md` | Wiggum | ✅ COMPLETE (6/6 waves) |
| Mutation Graph | `projects/mutation-graph/board.md` | Wiggum | ✅ Phase 1 complete, Phase 2 deferred |
| Testing | `projects/testing/board.md` | Marge + Nelson | ✅ Steady state (257 tests) |
| NPC Combat | `projects/npc-combat/board.md` | Bart (arch lead) | 📋 Phase 5 plan reviewed, PRE-WAVE pending |
| Worlds | `projects/worlds/board.md` | Bart + Moe | 📋 Designed, ready to execute |
| Sound | `projects/sound/board.md` | Bart + Gil | 📋 Designed, needs team review |
| Parser Improvements | `projects/parser-improvements/board.md` | Smithers | 🟢 91.2% accuracy, D1-D4 resolved by Frink |

## Board Conventions (Wayne's rules)

- **Next Steps** section ALWAYS at the top (after header)
- Standard header: Owner, Last Updated, Overall Status
- Every board needs an owner
- Implementation plans follow the implementation-plan skill (Pattern 5: team review before execution)
- Sound board: P0 is full team review per skill Pattern 5

## Learnings

(append new learnings below this line)

### Work-Down-Issues Skill (2026-03-27)

**What it teaches:**
The work-down-issues skill is Kirk's framework for burning down ALL open GitHub issues systematically. When Wayne says "work down issues" or "burn down the backlog", it triggers a structured 6-step burndown loop:

1. **Review & Categorize** — Pull all open issues, sort by owner/type/complexity/dependencies
2. **Plan Waves** — Group issues into parallel batches that won't conflict on files; present plan to Wayne
3. **Execute Waves (TDD-first)** — Spawn agents in parallel, write failing test → fix code → run full test suite; commit+push AFTER EACH WAVE
4. **Iterate Until Clear** — Re-scan GitHub after each wave; cycle waves until board is clear
5. **Marge Verification** — QA gate checks each closure for actual fix match, can reopen issues
6. **Test Pass** — Final gate: run linter, unit tests, parser bench, Nelson walkthrough in parallel

**Key patterns:**
- **Waves, not one-at-a-time** — Maximize parallel work (4-5 agents per wave, ~5-15 min each)
- **Wave planning heuristics** — Route by expertise: Bart (engine), Flanders (objects), Smithers (parser), Moe (rooms), Nelson (tests)
- **TDD is mandatory** — Every bug fix must have a failing test FIRST, then code fix, then full test run. No test = no close.
- **Multi-instance agents** — Spawn the SAME agent multiple times if they work on different files without conflicts (e.g., two Flanders fixing two objects)
- **Commit+push after EVERY wave** — Each wave's work is saved before the next starts; crash-resilient
- **Marge is the gate** — No issue is truly closed until QA verifies the fix. She can reopen.
- **Deferred issues are OK** — Design/future features can't be fixed now; mark them, move on. Goal = zero actionable bugs.
- **Anti-patterns to avoid** — Don't skip Marge, don't run test-pass before Marge approves, don't serialize when parallel is possible

**Complement: Bug Report Lifecycle Skill**
The bug-report-lifecycle skill describes the player-centric workflow for issues filed via `/report bug` command (auto-created in public `WayneWalterBerry/MMO-Issues` repo):
- Phase 1: Read issue, extract session transcript, identify player action sequence
- Phase 2: Route to specialist (Bart/Smithers/Flanders) based on bug type
- Phase 3: Fix + unit test (mandatory regression test, TDD approach)
- Phase 4: Deploy (build engine → build meta → copy to GitHub Pages → commit both repos)
- Phase 5: Comment in player-friendly terms (NO technical details, NO file paths, NO secret URLs), close issue

**Connection to Kirk's PM role:**
**Stability = Priority Tier 0** (per Wayne's priorities). Work-down-issues is how the team systematically converts GitHub issue backlog into zero actionable bugs. Kirk's job: coordinate issue burndown, track waves, manage Marge verification gate, ensure test-pass runs before closure. This is the structured operational rhythm that keeps the game playable for players and unblocks feature work.

The wave-based approach lets Kirk see real-time progress (Wave 1: 4 issues → Wave 2: 3 issues remaining), parallelize without file conflicts, and ensure TDD rigor prevents regression. Marge is the quality gate Kirk enforces — no issue passes until verified fixed.

### Options v1.0 and GATE-1 READY (2026-08-02)

**What I did:**
Updated Options plan.md to v1.0 and board.md to GATE-1 READY status. Fixed B8 (changed all `room.hints` references to `room.goal` in Phase 5 section, updated code examples to use `goal = { verb, noun, label }` format). Fixed B10 (replaced subjective GATE-5 criteria "Nelson approves walkthrough UX" with quantitative thresholds: 12/12 LLM scenarios, 5/5 parser aliases, number selection tests, <50ms performance, zero regressions).

**Major updates:**
- Version changed from 0.2 to 1.0, status changed to "GATE-1 READY — all blockers resolved, architecture approved"
- Executive Summary updated to definitively state Approach C (goal-driven hybrid), removed provisional language
- Key Questions section: marked ALL 5 questions as RESOLVED with Wayne's decisions
- Phase 5: removed "CONDITIONAL" tag, made definitive — hybrid approach requires `goal` field
- Phase Overview table: removed "Blocked On: Architecture" from all phases
- Pending Questions: replaced entire section with "All key questions resolved"
- Version History: added v1.0 entry documenting all blocker resolutions
- Board: Overall Status changed to "GATE-1 READY", all 7 blocker items marked COMPLETE
- Board: Fixes phase marked COMPLETE, GATE-1 phase marked "Ready for Wayne's final approval"
- Board: Open Questions updated with all 12 blockers marked resolved
- Board: Blockers section updated to show all 12 resolved

**Why it matters:**
All 12 blockers from team review are now resolved. Wayne approved all architecture decisions (Approach C, Option C context window, free hints, state-based goal detection). The plan is now definitive rather than conditional — ready for Wayne's GATE-1 approval to begin implementation.
