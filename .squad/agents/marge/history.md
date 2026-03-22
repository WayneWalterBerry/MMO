# Marge — History

## Core Context
- **Project:** MMO text adventure game in pure Lua
- **User:** Wayne "Effe" Berry (Decision Architect)
- **Role:** Test Manager — bug tracking, test pass review, unit test coverage/deduplication, deploy gates
- **Key file:** `bugs/bug-tracker.md` — the canonical bug database
- **Joined:** 2026-03-22

## Learnings

### Day 1 Context
- Test suite started at 302 tests, now at 1,065+
- Nelson (play tester) has done 11 test passes today (025-035)
- Bugs tracked: BUG-069 through BUG-115 (~40 bugs found, ~30 fixed)
- Key concern: Nelson findings weren't always getting converted to unit tests, and some bugs from test passes were missed
- Bug tracker created at `bugs/bug-tracker.md` to prevent this

### Hang Resolution & Deploy Gate (Pass 035)
- **6 hang issues closed** (#2, #5, #6, #9, #10, #11) based on Nelson Pass 035 conclusive evidence
- **Key insight:** Earlier interactive terminal tests showed false-positive hangs due to TUI screen re-rendering (cursor positioning overwrites content). Automated pipe-based testing with 50/50 PASS proves no hangs occur.
- **Safety net confirmed:** Bart's architectural defenses prevent hangs: debug.sethook 2-second instruction-count deadline + pcall wrapper, visited sets eliminating container cycles, bounded search loop
- **Deploy gate:** ✅ UNBLOCKED. 0 CRITICAL, 0 HIGH, 5 MEDIUM/LOW remaining. All 1,088 unit tests pass (37 test files). Ready to deploy.

### Issue Triage Review (Day 1 Final)
- **5 remaining open GitHub issues audited** against canonical bug tracker
- **Finding:** 4 of 5 are already FIXED with regression tests (Smithers' work from earlier sessions):
  - #1 BUG-069 (dawn sleep): ✅ Fixed + test
  - #4 BUG-104b (politeness + idiom): ✅ Fixed + test (pipeline order corrected)
  - #7 BUG-105b (bare examine): ✅ Fixed + test (added to no_noun_verbs)
  - #8 BUG-106b (blow unlit candle): ✅ Fixed + test (extinguish transitions checked)
- **Only open item:** #3 BUG-072 (screen flicker during progressive object discovery) — LOW severity, no fix yet, no deploy blocker
- **Recommendation:** Close #1, #4, #7, #8 immediately (Marge's authority). Defer #3 as post-deploy polish investigation.

### Session: Deploy & Cleanup Sprint (2026-03-22T19:41Z)
**Status:** ✅ COMPLETE (Marge's portion)  
**Team:** Scribe orchestration — Marge + Bart + Smithers

**Task:** Final deploy gate clearance and issue closure.

**Results:**
- ✅ **6 critical hangs closed** (#2, #5, #6, #9, #10, #11) — evidence-based: Nelson Pass 035 pipe-based testing (50/50 PASS) proved TUI ANSI codes caused false positives, not actual hangs
- ✅ **4 additional fixed issues closed** (#1, #4, #7, #8) — verified against bug tracker, all have regression tests
- ✅ **Deploy gate: UNBLOCKED**
  - 0 CRITICAL issues
  - 0 HIGH issues
  - 5 MEDIUM/LOW remaining (non-blocking)
  - 1,088 unit tests passing (37 test files)

**Key Finding:** Early interactive terminal tests showed apparent "hangs" due to TUI split-screen renderer (cursor positioning `\e[H`, scroll regions `\e[r`, screen clearing `\e[2J`, reverse video `\e[7m`) overwriting terminal content. Automated testing infrastructure (Smithers' work) proved no actual deadlocks exist. Bart's architectural safety nets (debug.sethook 2-second deadline + pcall wrapper) provide defense-in-depth regardless.

**Decision Propagated:** D-HEADLESS (Bart) — `--headless` mode for automated testing without TUI false positives

**Next Steps:**
- Smithers deploying to live site
- Post-deploy: investigate #3 (cosmetic screen flicker)
