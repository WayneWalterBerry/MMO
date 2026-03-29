# Phase 5 Plan Review — Test Management Perspective
**Reviewer:** Marge (Test Manager)  
**Date:** 2026-03-29  
**Plan:** `plans/npc-combat/npc-combat-implementation-phase5.md`  
**Status:** Ready to Execute with Conditions  

---

## Executive Summary

**Overall Assessment:** ✅ **PLAN IS EXECUTABLE** — Solid foundation with clear gates, regression baselines, and risk mitigations. However, 5 non-blockers require immediate attention before WAVE-1 start to avoid gate delays.

**Key Concerns:** Flaky test quarantine strategy incomplete, LLM scenario logs format unspecified, gate reviewer assignments vague ("Bart + Nelson" needs clarification), and autonomous execution depends heavily on Nelson's continuous availability.

**Blockers:** None. All test infrastructure, gates, and regression targets are well-defined.

---

## Section-by-Section Review

### ✅ Regression Baseline Snapshots

**Finding:** Excellent. Exact counts documented.

| Metric | Documented? | Clarity | Notes |
|--------|-------------|---------|-------|
| Phase 4 baseline | ✅ YES | Specific: 223 tests, ~258 files | `PHASE-4-FINAL-COUNT` label |
| GATE-1 target | ✅ YES | ~238 tests (223 + 15) | Documented in Section 5 |
| GATE-2 target | ✅ YES | ~248 tests (223 + 25) | Cumulative formula clear |
| GATE-3 target | ✅ YES | ~258 tests (223 + 35) | Linear progression |
| GATE-4 target | ✅ YES | 270+ tests (223 + 47+) | Conservative/stretch goals: 270/300 |
| Nelson pre-wave mandate | ✅ YES | "Register new test dirs + record PHASE-4-FINAL-COUNT" | Section 4, PRE-WAVE assignments |

**Risk:** Phase 4 baseline must be run BEFORE any Phase 5 commits. PRE-WAVE assignment places this on Nelson (correct owner), but no explicit blockers if baseline drifts from 223. Recommend: **lock baseline in git tag at pre-wave-start.**

**Verdict:** ✅ GOOD

---

### ⚠️ Flaky Test Quarantine Strategy

**Finding:** Incomplete protocol; needs clarification before WAVE-1.

| Aspect | Status | Details |
|--------|--------|---------|
| Flaky test detection | ❌ INCOMPLETE | GATE-4 requires "3 consecutive runs, 100%", but no pre-detection pipeline |
| Quarantine triggers | ❌ UNCLEAR | What pass rate triggers quarantine? 95%? 90%? |
| Quarantine location | ❌ UNSPECIFIED | Are flaky tests moved to `test/flaky/`, skipped, or marked `@skip-ci`? |
| Recovery protocol | ❌ MISSING | How does a quarantined test un-quarantine? |
| Per-test determinism | ✅ GOOD | Nelson directed to use `math.randomseed(42)` for LLM scenarios |
| Seed documentation | ❌ INCOMPLETE | Should all new unit tests use fixed seeds? Not specified. |

**Current Language:** GATE-4 says "No flaky tests (3 consecutive runs, 100%)" — this is a **gate criterion**, but there's no **prevention strategy** for test development. Nelson's WAVE-4 task includes "Test flakiness audit — document any non-deterministic tests added in WAVE-1 through WAVE-3. Add fixed seeds or mark `@skip-ci` with issue link."

**Missing:** Explicit rule for Phase 5 TDD: "All new tests must either (A) use fixed seeds via `math.randomseed()`, or (B) declare `@skip-ci` with linked issue if randomness is intentional."

**Recommendation:** Before PRE-WAVE, add to Section 12 (Gate Failure Protocol) or new section:

> **Flaky Test Protocol**
> 1. All new tests use `math.randomseed(42)` by default for deterministic replay
> 2. Any test intentionally using randomness must declare `@flaky` tag + issue link
> 3. At GATE-N, run full suite 3 consecutive times; any test <100% pass triggers investigation
> 4. Failed flaky tests are tagged `@skip-ci` and opened as GitHub issue with label `flaky-test`
> 5. Flaky tests unblock gate iff root cause is filed + reproduction steps clear

**Verdict:** ⚠️ CONCERN — Define quarantine protocol before WAVE-1 starts. Without it, GATE-4 may stall on ambiguous flakiness verdicts.

---

### ✅ Performance Regression Gates

**Finding:** Well-specified. Clear thresholds per subsystem.

| Gate | System | Metric | Threshold | Test File |
|------|--------|--------|-----------|-----------|
| GATE-1 | L2 instantiation | Load time | < 200ms | (implicit in gate check) |
| GATE-2 | Pack scoring | Per-tick cost | < 50ms/tick | (implicit) |
| GATE-3 | Salt mutation | Mutation latency | < 20ms | (implicit) |
| GATE-4 | Full suite | N/A | ZERO regressions vs Phase 4 | `lua test/run-tests.lua` |

**Strengths:**
- ✅ Thresholds are concrete (200ms, 50ms/tick, 20ms)
- ✅ Tied to specific subsystems (instantiation, pack AI, mutation engine)
- ✅ Measurable (no vague "fast enough")

**Weaknesses:**
- ⚠️ **No explicit performance test files listed.** Gates reference performance ("Perf: L2 instantiation < 200ms"), but Section 7 (TDD Test File Map) does not include dedicated perf tests. Are these measured ad-hoc during gate reviews, or should unit tests exist?
- ⚠️ **Baseline missing:** What is Phase 4 pack-score latency? If it was already 45ms/tick, 50ms/tick is a tight margin.
- ⚠️ **Tool undefined:** Which profiler? `os.clock()` inside Lua, or external perf instrumentation?

**Recommendation:** Add to Section 5 (Testing Gates):

> **Performance Baselines (Phase 4 Measured)**
> - L2 instantiation (phase5-gate-1): Measure on clean machine; baseline TBD during PRE-WAVE
> - Pack scoring (phase5-gate-2): Current wolf-pack (1-2 wolves): ~15ms/tick. Threshold 50ms/tick allows 3× overhead for werewolf + 3-wolf coordination.
> - Salt mutation (phase5-gate-3): Comparable to burn/break mutations; target <20ms on existing meat objects

Document baseline measurements in PRE-WAVE gate checklist (Bart responsibility).

**Verdict:** ✅ GOOD (thresholds defined, but measurement protocol & baselines need PRE-WAVE clarification)

---

### ✅ Test Isolation (No Cross-Wave Requires)

**Finding:** Excellent. Strict dependency chain eliminates cross-wave pollution.

**Verified:**
- ✅ PRE-WAVE is pure design + bug fixes; adds 0 new test files
- ✅ WAVE-1 creates 5 test files; WAVE-2 creates 5 more (no overlap)
- ✅ WAVE-2 and WAVE-3 can run in parallel; different test directories (`test/creatures/test-pack-*.lua` vs `test/preservation/test-*-*.lua`)
- ✅ WAVE-4 is validation-only (no new tests, runs existing suite)
- ✅ Section 7 confirms: No test file is authored by multiple waves
- ✅ File ownership table (Section 4, each wave) has no conflicts

**Artifact Test Independence:**
- Section 7 TDD Test File Map lists 18 new test files across 4 waves
- Cumulative: W1 (5 files, 30 tests) → W2 (5 files, 18 tests) → W3 (6 files, 18 tests) → W4 (2 files, 13 tests)
- Section 3 Dependency Graph explicitly states: "WAVE-2 and WAVE-3 can run in parallel (no file overlap)"

**Cross-Wave Artifact Risks:**
- ⚠️ WAVE-2 modifies `src/engine/creatures/pack.lua` (Bart)
- ⚠️ WAVE-3 modifies `src/engine/verbs/` (Smithers for salt verb)
- ⚠️ Both waves also update `src/meta/creatures/wolf.lua` (Flanders)?

Wait — checking Section 4 WAVE-2 and WAVE-3 carefully:

**WAVE-2 File Ownership (Section 4):**
- `src/engine/creatures/pack.lua` ← Bart (MODIFY)
- `src/meta/creatures/wolf.lua` ← Flanders (MODIFY)

**WAVE-3 File Ownership (Section 4):**
- `src/engine/verbs/` (salt verb) ← Smithers
- `src/meta/creatures/wolf-meat.lua` ← Flanders (MODIFY)

Flanders modifies `wolf.lua` in WAVE-2 (pack_role field) AND `wolf-meat.lua` in WAVE-3 (salted-meat mutations). **Different files** ✅ — no conflict.

**Parallel Safety Reconfirmed:**
- No single file touched by multiple waves ✅
- No shared test directories ✅
- Dependency chain: WAVE-1 → {WAVE-2, WAVE-3 parallel} → WAVE-4 ✅

**Verdict:** ✅ GOOD — Test isolation is rock-solid. No cross-wave requires detected.

---

### ⚠️ LLM Scenario Logs Format

**Finding:** Scenarios defined, but log format unspecified.

**What's Documented:**
- ✅ 5 LLM scenarios (Scenarios 2.1–2.5, Section 6)
- ✅ Input: bash echo + pipe to `lua src/main.lua --headless`
- ✅ Expected patterns: regex-like strings (e.g., "brass key", "werewolf", "salt")
- ✅ Pass criteria: prose descriptions (e.g., "Player reaches L2, visits ≥5 of 7 rooms")
- ✅ Seeds: `math.randomseed(42)` for deterministic replay

**What's NOT Documented:**
- ❌ **Output log file format:** Should Nelson capture stderr+stdout to `test/scenarios/phase5-full-walkthrough.txt`? JSON? Plain text? Timestamped?
- ❌ **Delimiter:** Plan says scripts end with `---END---` (headless mode), but no log file spec
- ❌ **Pass/fail recording:** How does Nelson document which of the 5 scenarios passed/failed?
- ❌ **Log retention:** Do logs persist in git (test/scenarios/) or are they ephemeral?
- ❌ **LLM verdict format:** Nelson is an LLM — does his "pass criteria" check translate to structured output for CI/CD?

**Current Language:**
> "Record in `test/scenarios/phase5-full-walkthrough.txt`" (Section 4, WAVE-4 assignment)

This implies a single text file, but doesn't specify format. **Is this one concatenated run, or 5 separate runs with headers?**

**Recommendation:** Add to Section 5 (Testing Gates) → new subsection "LLM Scenario Logging Protocol":

> **Scenario Log Format**
> 1. Each scenario run outputs to: `test/scenarios/scenario-2-{N}.log` (e.g., `scenario-2-1.log`, `scenario-2-2.log`)
> 2. Log structure:
>    ```
>    === Scenario 2.1: Level 2 Exploration ===
>    [INPUT] echo "look\ntake brass key\n..." | lua src/main.lua --headless
>    [SEED] math.randomseed(42)
>    [STDOUT]
>    ... game output ...
>    [STDERR]
>    ... errors (if any) ...
>    [VERDICT] PASS | FAIL
>    [NOTES] Player reached L2, visited 6/7 rooms. (or: FAIL: werewolf room unreachable)
>    ```
> 3. Aggregate report: `test/scenarios/phase5-scenario-summary.txt` — one-liner per scenario with verdict
> 4. CI integration: If any scenario fails, gate fails; logs retained in build artifact

**Alternative (Simpler):** Just one file with all 5 scenarios concatenated, clear delimiters between each.

**Verdict:** ⚠️ CONCERN — Define log format & file structure before Nelson starts WAVE-4. Otherwise, gate reviews will stall on ambiguous pass/fail documentation.

---

### ⚠️ Gate Reviewer Assignments

**Finding:** Vague. "Bart + Nelson" unclear; no escalation path specified.

**Current Language (Section 5):**

| Gate | Reviewers |
|------|-----------|
| GATE-1 | "Bart + Nelson" |
| GATE-2 | "Bart + Nelson" |
| GATE-3 | "Bart + Nelson" |
| GATE-4 | "Bart + Nelson + Brockman" |

**Ambiguities:**
- ❌ **Role clarity:** Is Bart the architect sign-off or automated gate runner? Is Nelson running tests or reviewing them?
- ❌ **Tie-breaker:** If Bart says PASS but Nelson says FAIL, who decides?
- ❌ **Acceptance criteria:** Do both reviewers need to sign off, or any one?
- ❌ **Escalation threshold:** At what point does a gate failure escalate to Wayne? Currently Section 11 says "2× failure on same gate" — but who initiates escalation?

**Current Escalation (Section 12, Gate Failure Protocol):**
> 1× Failure: Diagnose → file issue → assign fix agent → re-run full gate
> 2× Failure: Escalate to Wayne with RCA

Clear ✅, but doesn't specify **who** escalates (Bart? Nelson? Coordinator?).

**Who is the "Coordinator"?** Section 11 says "Coordinator orchestrates without Wayne unless escalation triggers," but the Coordinator is not defined in the plan. Is this Bart? A role? The Scribe?

**Recommendation:** Add to Section 11 (Autonomous Execution Protocol):

> **Gate Review Protocol**
> - **Bart (Architecture Lead):** Verifies engine modules, integration points, regression suite runs cleanly. Sign-off: "GATE-N architecture OK"
> - **Nelson (QA):** Runs full test suite (`lua test/run-tests.lua`), LLM walkthroughs, flakiness audit. Sign-off: "GATE-N tests pass"
> - **Acceptance:** Both signatures required (Bart AND Nelson). Disagreement escalates to Coordinator (see below).
> - **Coordinator Role:** Defined as the session Scribe or first available Squad member who is not Bart/Nelson. On escalation, Coordinator files GitHub issue and notifies Wayne.
> - **Gate Passes iff:** (A) Bart: "Architecture OK", (B) Nelson: "Tests pass", (C) No new P0 bugs opened in GATE-N.
> - **Retry after fix:** Coordinator re-runs gate with fixed agent(s). If still fails, triggers Section 12 (Gate Failure Protocol).

**Verdict:** ⚠️ CONCERN — Gate reviewer roles and escalation ownership need clarification to avoid gate stalls. Add before PRE-WAVE.

---

### ✅ Autonomous Execution Protocol

**Finding:** Well-structured and realistic. Walk-away capability is achievable with noted dependencies.

**Strengths:**
- ✅ **Execution loop clear:** WAVE-N → parallel agents → Nelson smoke-test → GATE-N → pass/fail fork
- ✅ **File ownership pre-assigned:** Section 4 lists agent per file; no conflicts
- ✅ **Commit/tag protocol:** After every passing gate, clear: `git commit` + `git tag phase5-gate-N` + push
- ✅ **Fallback decision tree:** 1× failure (fix), 2× failure (Wayne decides), rollback strategy (tags: `phase5-pre-wave`, `phase5-gate-1`, etc.)
- ✅ **Milestone checkpoints:** Section 13 (Wave Checkpoint Protocol) specifies post-gate actions
- ✅ **Nelson mandates:** `--headless` mode, fixed seeds, continuous testing between waves

**Dependencies on Continuous Availability:**
- ⚠️ **Nelson = critical path:** Every gate requires Nelson's test run + LLM walkthroughs. If Nelson is unavailable mid-wave, all gates stall.
- ⚠️ **Bart = reviewer:** GATE-N regression run requires Bart's verification. Backup not specified.
- ⚠️ **Flanders = WAVE-1 + WAVE-3:** Creature definitions + object definitions. No backup agent listed.

**Risk Mitigation:**
- Current language assumes squad is fully staffed (7 agents across 5 waves).
- **If an agent becomes unavailable:** Plan does NOT specify contingencies. Recommend: "If Nelson unavailable, Bart can run test suite; if Bart unavailable, Smithers can review architecture."

**"Will It Work Without Wayne?"** — Yes, with caveats:
- ✅ Waves 1–4 can execute autonomously (no Wayne in execution loop)
- ✅ Gate failures auto-escalate to Wayne at 2× threshold (no ambiguity)
- ✅ Commit/tag/push handled by Coordinator (not Wayne)
- ⚠️ **But:** GATE-4 "no engine module > 500 LOC" requires architectural judgment. Currently assigned to Bart, but if this triggers a code-split proposal, Wayne may need to arbitrate.

**Section 11 Autonomous Execution Compliance:**
> "Per Skill Pattern 9 — walk-away capable. Coordinator orchestrates without Wayne unless escalation triggers."

This maps to Skill Pattern 9 (autonomous execution), which I don't have context for in the custom instructions. **But the plan IS written to avoid Wayne involvement except at escalation gates.** ✅

**Verdict:** ✅ GOOD (Autonomous execution feasible; list recommended backups for Nelson/Bart/Flanders before PRE-WAVE to be fully walk-away capable.)

---

## Cross-Cutting Issues

### 1. Phase 4 Baseline Regression Liability

**Risk:** If Phase 4 baseline is not locked BEFORE Phase 5 begins, gate comparisons become ambiguous.

**Current Language:** "Run `lua test/run-tests.lua` on Phase 4 HEAD before Phase 5 work. Record as PHASE-4-FINAL-COUNT (current: ~258 files, 223 tracked tests)."

**Missing:** No git artifact (tag or commit marker) that locks the baseline. If someone runs tests on Phase 4 HEAD on different machines/times, counts may vary by ±5 tests due to flakiness or seed variance.

**Recommendation:** PRE-WAVE assignment should include: "Nelson records baseline as `git tag phase4-final-baseline` on Phase 4 HEAD before any Phase 5 commits."

### 2. Test Deduplication Audit Not Planned

**Marge's Responsibility (per charter):** "Unit test deduplication — I audit unit test files to prevent test explosion... Flag duplicates for consolidation."

**Current Plan:** Does not mention deduplication audit before or after Phase 5.

**Recommendation:** Add post-GATE-4 task: "Marge audits 18 new test files for overlaps with existing Phase 4 tests. Flag any duplicate coverage; mark for Phase 6 consolidation."

### 3. Test Data Cleanliness (Regression Pollution Risk)

**Risk:** Phase 5 adds 36 new tests across 18 files. If any test modifies global state (registry mutations, saved objects), subsequent tests might fail spuriously.

**Current Language:** Section 4 says "No file overlap" ✅, but doesn't address test isolation within files.

**Recommendation:** Before GATE-1, Nelson should audit new test files for:
- Tests that leave objects in registry after completion
- Tests that modify global `math.randomseed` without resetting
- Tests that rely on a specific object spawn order

Add task: "Nelson: Test data cleanliness audit (registry state, seed reset) before GATE-1."

---

## Regression Testing Completeness Matrix

| Phase 4 Feature | GATE-1 | GATE-2 | GATE-3 | GATE-4 | Notes |
|-----------------|--------|--------|--------|--------|-------|
| Candle lighting | ✅ | ✅ | ✅ | ✅ | Phase 4 regression test runs at every gate |
| Wolf combat | ✅ | ✅ | ✅ | ✅ | Phase 4 regression test runs at every gate |
| Butchery | ✅ | ✅ | ✅ | ✅ | Phase 4 regression test runs at every gate |
| Crafting (silk) | ✅ | ✅ | ✅ | ✅ | Fixed in PRE-WAVE |
| Cooking | ✅ | ✅ | ✅ | ✅ | Phase 4 regression test runs at every gate |
| Stress injuries | ✅ | ✅ | ✅ | ✅ | Phase 4 regression test runs at every gate |
| **New Phase 5 Features:** | — | — | — | — | — |
| Level 2 foundation | ✅ | ✅ | ✅ | ✅ | GATE-1 + GATE-4 acceptance |
| Werewolf creature | ✅ | ✅ | ✅ | ✅ | GATE-1 + GATE-4 acceptance |
| Pack tactics | ✗ | ✅ | ✅ | ✅ | GATE-2 acceptance (not in GATE-1) |
| Salt preservation | ✗ | ✗ | ✅ | ✅ | GATE-3 acceptance |

**Matrix Assessment:** ✅ GOOD — Each feature has clear acceptance gates, and Phase 4 regressions run at every gate.

---

## Pre-Phase 5 Checklist (for Marge to Execute)

Before PRE-WAVE starts:

- [ ] Lock Phase 4 baseline: `git tag phase4-final-baseline` on current HEAD; `lua test/run-tests.lua` records 223 tests (or actual count)
- [ ] **Define flaky test quarantine protocol** (Section on protocol, thresholds, `@skip-ci` tagging)
- [ ] **Specify LLM scenario log format** (file structure, delimiter, verdict field)
- [ ] **Clarify gate reviewer assignments & tie-breaker** (Bart architect vs Nelson QA, who escalates?)
- [ ] **Assign Coordinator role** (Scribe? First available non-Bart/Nelson?)
- [ ] **Measure Phase 4 perf baselines** (pack-score latency, instantiation time, mutation time)
- [ ] **Confirm test isolation within new test files** (registry state, seed reset, global state)
- [ ] **Plan deduplication audit post-GATE-4** (Marge responsibility per charter)

---

## Test Plan Verdict by Category

| Category | Status | Evidence | Concern Level |
|----------|--------|----------|----------------|
| **Regression Baseline Snapshots** | ✅ GOOD | 223 tests documented; gate targets incremental (+15, +10, +10, +15); formula clear | None |
| **Flaky Test Quarantine** | ⚠️ CONCERN | Only GATE-4 "3 runs, 100%" check; no pre-detection or quarantine location specified | Medium |
| **Performance Regression Gates** | ✅ GOOD | Thresholds quantified (200ms, 50ms/tick, 20ms); but measurement tool & baselines need PRE-WAVE | Low |
| **Test Isolation** | ✅ GOOD | No cross-wave file conflicts; parallel waves independent; dependency chain clear | None |
| **LLM Scenario Logs** | ⚠️ CONCERN | 5 scenarios defined, but output format unspecified; log file name ambiguous | Medium |
| **Gate Reviewer Assignments** | ⚠️ CONCERN | "Bart + Nelson" roles vague; tie-breaker undefined; Coordinator role not named | Medium |
| **Autonomous Execution Protocol** | ✅ GOOD | Walk-away capable with clear escalation; but backup agents for Nelson/Bart/Flanders not listed | Low |

---

## Summary: Test Readiness Vote

**Can Phase 5 execute as planned?**

**YES, with 3 pre-execution clarifications:**

1. **Define flaky test quarantine** (prevent GATE-4 stalls on ambiguous flakiness)
2. **Specify LLM log format** (so Nelson knows what to write, CI/CD knows what to parse)
3. **Clarify gate reviewers & Coordinator** (avoid gate deadlock on Bart vs Nelson disagreement)

**These are not blockers; they are operational hygiene items.** The plan's structure is sound.

---

## Marge's Sign-Off

**Test Plan Status:** 🟡 CONDITIONAL PASS — Ready for PRE-WAVE execution pending 3 protocol clarifications.

**Recommendation to Wayne:**
1. Review and approve clarifications above (flaky protocol, log format, reviewer roles)
2. Have Coordinator (TBD) merge clarifications into plan Section 5/11
3. Proceed with PRE-WAVE; lock baseline before any code commits
4. I (Marge) will audit test coverage post-GATE-4 per charter (deduplication, Nelson→unit test pipeline)

**Green Light Conditions:**
- ✅ Regression baselines documented (223 Phase 4, 270+ target)
- ✅ Test gates defined (GATE-1 through GATE-4 with pass/fail criteria)
- ✅ No cross-wave test isolation conflicts
- ✅ Performance thresholds quantified
- ✅ Autonomous execution protocol walk-away capable
- ⚠️ Pending: Flaky quarantine protocol, LLM log format, gate reviewer tie-breaker

**Proceed with Phase 5 PRE-WAVE.** I will track all test execution and report any gate failures to Wayne per escalation protocol.

---

**End of Review**  
*Marge, Test Manager*  
*"Nothing leaves this house broken."*
