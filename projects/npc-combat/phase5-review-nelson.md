# Phase 5 Plan Review — Nelson (QA/Tester)

**Date:** 2026-03-28  
**Reviewer:** Nelson (Tester)  
**Plan Reviewed:** `plans/npc-combat/npc-combat-implementation-phase5.md` (v1.0, Assembled)  
**Review Scope:** Test completeness, LLM scenario coverage, gate criteria specificity, regression baseline accuracy, deterministic seeds, headless mode requirements, performance budgets, edge cases

---

## Executive Summary

Phase 5 plan is **well-structured for QA execution** with strong regression baselines, clear gate criteria, and deterministic walkthrough scenarios. However, **7 concerns** identified across test coverage gaps, gate criteria specificity, performance budgets, and LLM scenario assumptions. No blockers; all addressable via clarification or minor test additions.

---

## Detailed Findings

### ✅ STRENGTHS

#### 1. **Strong Regression Baseline Protocol** (§5)

✅ **Good:** Explicit Phase 4 baseline (`PHASE-4-FINAL-COUNT = 223`) documented as starting point. Incremental gate targets (+15, +10, +10, +15 = 50 net tests) are realistic.

**Citation:** Plan §5, lines 567–569: "record as PHASE-4-FINAL-COUNT (current: ~258 files, 223 tracked tests)."

**Why this matters:** Prevents silent regressions. Nelson will run baseline before PRE-WAVE starts.

---

#### 2. **Deterministic Seed Discipline** (WAVE-2, WAVE-3)

✅ **Good:** Pack tests specify `math.randomseed(42)` (line 386) and preservation tests specify `ctx.game_time = fixed` (line 462). This is critical for reproducible creature behavior and spoilage timing.

**Citation:** Plan §4, WAVE-2 (line 386), WAVE-3 (line 462).

**Why this matters:** Without fixed seeds, pack role assignments and spoilage comparisons will be flaky in CI.

---

#### 3. **Headless Mode Wired Throughout** (§6 Scenarios 2.1–2.5)

✅ **Good:** All 5 LLM scenarios explicitly use `--headless` flag and include expected patterns (regex hints like "catacombs", "werewolf", "dead").

**Citation:** Plan §6, Scenarios 2.1–2.5, all include `echo "..." | lua src/main.lua --headless`.

**Why this matters:** Prevents TUI hangs in automation. Matches Nelson's historical best practice (charter: always use `--headless` in automated tests).

---

#### 4. **Clear Gate Criteria — Binary Pass/Fail** (§5)

✅ **Good:** All 4 gates (GATE-1 through GATE-4) define checkboxes, specific test file names, and perf targets.

**Examples:**
- GATE-1 (line 579–587): ✅ 7 L2 rooms instantiate, exits route bidirectional, brass key unlocks, werewolf loads, creatures spawn, zero regressions, 238+ tests pass.
- GATE-2 (line 595–603): ✅ Stagger attacks tested, alpha by HP verified, omega retreat proven, pack narration reviewed, 248+ tests.
- GATE-3 (line 609–621): ✅ Salt verb resolves, mutation fires, spoilage is 3× slower, fails without salt, distinct sensory, 258+ tests.
- GATE-4 (line 629–649): ✅ Full LLM walkthrough, 3 docs signed off, 270+ tests, flakiness audit clean, linter passes, embedding index updated.

**Why this matters:** No ambiguous "make sure it feels right." Each gate is executable.

---

#### 5. **Integration Matrix Identifies Cross-System Dependencies** (§9)

✅ **Good:** Table explicitly maps 16 integration points: Level 2 → creature placement, werewolf → loot, pack tactics → combat FSM, salt → mutation, etc. Risk mitigations documented (e.g., "parallel object+verb creation in WAVE-3").

**Citation:** Plan §9, lines 1008–1026.

**Why this matters:** Catches hidden dependencies. Nelson knows to test across subsystems, not in silos.

---

### ⚠️ CONCERNS

#### **CONCERN #1: Gate Criteria Are Descriptive, Not Always Binary**

⚠️ **Issue:** Some gate checklist items are subjective or require manual review:

- **GATE-1 (line 584):** "Room presence text correct — Manual review" ← No pass/fail test specified
- **GATE-2 (line 602):** "Coordinated attack narration correct — Manual review" ← Who reviews? What's the acceptance threshold?
- **GATE-4 (line 636):** "No flaky tests (3 consecutive runs, 100%)" ← Operational detail, not a testable gate. Does Nelson run 3 times in a single gate check?

**Impact:** Medium. If Bart or Wayne aren't available for manual sign-off, gate can stall.

**Recommendation:** 
- Clarify manual review SLA (e.g., "Bart reviews room presence before merging WAVE-1")
- Add specific narration acceptance criteria (e.g., "Alpha narration includes 'lunges first' or 'alpha'")
- Define flakiness audit protocol: separate from GATE-4 pass/fail? (e.g., "Run suite 3× consecutively; if any failure, file issue but don't block gate")

---

#### **CONCERN #2: Test File Map Is Incomplete — No Coverage for Specific Scenarios**

⚠️ **Issue:** Section 7 (TDD Test File Map, lines 831–868) lists 18 test files with ~79 tests total (W1–W4). However:

1. **Scenario 2.4 (Pack Tactics) has no dedicated unit test.** Plan says "observe alpha/omega behavior" in walkthrough (§6, lines 756–783) but:
   - No test file for "omega retreat at <25% HP" specifically
   - `test-pack-omega.lua` (line 844) shows 3 tests but doesn't match scenario inputs (scenario uses `wait` ticks, test may not)
   - How does Nelson verify omega retreats at exactly <25% vs <30%? (Plan says <30% in WAVE-2 code, §4 line 335 says `health < 30%`, but gate criteria line 599 says `< 25%` — inconsistent)

2. **Salt verb integration isn't unit-tested for two-hand requirement.** Plan says "Fails without salt in hand" (line 619) but:
   - `test-salt-verb.lua` line 847: only lists 4 tests
   - Does this include "salt without holding salt" failure case? "salt without holding meat"? "salt with meat but salt in ground"?
   - No explicit two-hand inventory validation test

3. **Level 2 creature **respawn** not tested.** Plan mentions respawn (§8.1.2, lines 936–937: "Respawn: 400 ticks, max_population=1 (werewolf)") but no test file listed.

**Impact:** Medium-High. If tests don't match scenarios, LLM walkthrough could pass but gate criteria might fail, or vice versa.

**Recommendation:**
- Add explicit test cases:
  - `test/pack/test-omega-retreat-threshold.lua`: omega retreats at exactly 30% HP, NOT 25%
  - `test/preservation/test-salt-two-hand-requirement.lua`: salt verb requires both salt AND meat in hands (not on ground)
  - `test/creatures/test-creature-respawn.lua`: werewolf respawns after 400 ticks with max_population=1
- Clarify omega retreat threshold: is it 25% or 30%? (Code vs gate mismatch)

---

#### **CONCERN #3: Performance Budgets Underspecified**

⚠️ **Issue:** Section 5 gates mention perf targets but lack verification method:

- **GATE-1 (line 587):** "L2 instantiation < 200ms" — How measured? `time lua src/main.lua`? Startup overhead excluded? Sample size?
- **GATE-2 (line 605):** "Pack scoring < 50ms/tick" — Which creature tick? 5 wolves all scoring simultaneously? Worst-case or average?
- **GATE-3 (line 623):** "Salt mutation < 20ms" — Single mutation or full chain (raw → salted → cooked → salted)? With IO overhead?

**Impact:** Low-Medium. Prevents false positives in performance regression. Without clarity, Nelson might waste time troubleshooting.

**Recommendation:**
- Define measurement protocol in a new section (e.g., "Performance Testing Methodology"):
  - Startup overhead excluded (measure just room instantiation, not boot)
  - 10-iteration warm-up, then 100-iteration average
  - Worst-case scenario (e.g., 5 wolves in same room for pack scoring)
- Or mark as "TBD post-implementation" and measure baseline in WAVE-1, then gate on 20% regression threshold

---

#### **CONCERN #4: LLM Scenario 2.4 (Pack Tactics) Doesn't Verify Alpha Selection or Stagger**

⚠️ **Issue:** Scenario 2.4 (§6, lines 756–783) is designed to observe pack behavior via narration, but:

1. **Alpha selection not verified.** Scenario doesn't attack the pack or observe attack order. Just "wait 5 times" and "feel" — no visible proof that alpha attacked first vs all 3 simultaneously.

2. **Stagger attacks need combat.** To verify "alpha first, beta delayed 1 turn," you MUST trigger combat and track turn-by-turn attack output. The scenario skips this.

3. **Omega retreat needs HP damage.** To test omega retreat at <30% HP, you need wolves wounded. The scenario has no combat.

**Current scenario outputs:**
```bash
echo "look
take knife
go north
go north
go north
unlock door with brass key
open door
go north
go west
look
wait
wait
wait
wait
wait
look
feel" | lua src/main.lua --headless
```

**Problem:** This just moves to wolf-den and looks around. No combat, so no attack order, no retreat behavior observed.

**Impact:** Medium-High. LLM walkthrough Scenario 2.4 will PASS even if pack role assignment is completely broken (because it doesn't test pack behavior). Nelson will think GATE-2 is green when it might fail.

**Recommendation:**
- Rewrite Scenario 2.4 to include combat:
  ```bash
  echo "take knife
  # navigate to wolf-den
  look              # verify 3+ wolves present
  attack wolf       # round 1 - alpha attacks
  look              # check who attacked
  attack wolf       # round 2 - beta attacks
  attack wolf       # round 3 - omega retreats?
  look              # verify omega gone or present
  ..." | lua src/main.lua --headless
  ```
- Add expected pattern matching: "alpha", "lunges first", "staggers", "flees" or similar
- Cross-reference with unit test `test-pack-stagger.lua` to ensure walkthrough and unit tests match

---

#### **CONCERN #5: Regression Baseline May Be Stale — No PRE-WAVE Baseline Run**

⚠️ **Issue:** Plan assigns Nelson to "run baseline" in PRE-WAVE (line 205), but:

1. **When exactly?** Before or after bug fixes? If AFTER, then bug fixes could introduce regressions that aren't caught.
2. **Baseline count discrepancy.** Plan says "Phase 4 baseline: 223 tracked tests" (line 99) but Nelson's history notes "baseline snapshot: 206 files, 462 violations" for linter tests (history.md, line 41). Are these the same baseline or different?
3. **No explicit "freeze point."** If Smithers fixes bugs in PRE-WAVE and introduces a new regression, when do we detect it?

**Impact:** Low-Medium. Regressions could slip through if baseline isn't locked.

**Recommendation:**
- Clarify: baseline run AFTER all bug fixes in PRE-WAVE complete
- Name the freeze point: `PHASE-4-FINAL-GATE` (locked after all PRE-WAVE tasks done, before WAVE-1)
- Document baseline command: `lua test/run-tests.lua > phase4-baseline.txt 2>&1` with timestamp
- Gate-1 compare: `lua test/run-tests.lua | diff - phase4-baseline.txt` (zero diff for regression, plus new test count)

---

#### **CONCERN #6: TDD Test Count Target Is Loose — "~79 Tests" Over 4 Waves**

⚠️ **Issue:** Section 7 summary (line 866) targets "~79 tests" across 18 files over Waves 1–4:

- W1: ~30 tests (but 5 test files listed lines 837–841)
- W2: ~18 tests (5 files listed lines 842–846)
- W3: ~18 tests (6 files listed lines 847–852)
- W4: ~13 tests (2 files listed lines 853–854)

**Problem:**
1. Average of ~4–6 tests/file is LOW for integration-level test files. Compare to Phase 4 history (223 tests across 255 files = 0.87 tests/file, but that includes 74 empty test files). Phase 5 should have 3–5 tests per file minimum if they're integration tests.
2. No explicit count per test file. "~30 tests" in W1 spread over 5 files = 6 tests each. That's thin for room loading + brass-key transition + werewolf + creature placement.
3. Gate target creep: GATE-1 says "238+ tests" (line 585) but math doesn't add up: 223 (baseline) + 30 (W1) = 253, not 238. ✅ Math is correct actually (223 + 15 minimum per gate spec §5 line 569), but the test file map doesn't deliver 50 tests total.

**Impact:** Low-Medium. Tests might be underscoped, catching fewer edge cases.

**Recommendation:**
- Expand test file map with explicit test counts per file (e.g., `test-room-loading.lua: 10 tests` instead of "7 tests" for 7 rooms)
- Target minimum 5 tests per file for system-critical files (rooms, creatures, verbs)
- If targeting 270+ tests at GATE-4, ensure test file map sums to 270, not 223 + loose "79 somewhere"

---

#### **CONCERN #7: Edge Cases — Salted Meat Spoilage Timeout During L2 Exploration**

⚠️ **Issue:** WAVE-3 adds salted-meat with 3× slower spoilage, but:

1. **Timeout calculation not specified in tests.** Scenario 2.5 (§6, line 791–823) expects the player to carry salted-wolf-meat through werewolf combat, then back to Level 1, then rest. How long is this journey in game ticks? If salted meat spoils in <15 min (900 ticks), it might spoil during the walkthrough.

2. **No test for "salted meat consumed while salted."** What if player cooks salted-raw meat? Does it stay salted-cooked (with 3× multiplier)? Test `test-salt-cook-chain.lua` says "preserves multiplier" (line 462) but doesn't test the inverse: raw → salted → cooked vs raw → cooked → ? (is salted property lost on cook?).

3. **FSM state grammar undefined.** Plan says salted-meat has FSM `fresh → stale → spoiled` (line 989) but fresh-meat in Phase 4 might have different states. Do they conflict? Does `salted-wolf-meat.lua` redefine states entirely, or inherit+extend?

**Impact:** Medium. Salted meat might not work as intended if FSM interactions aren't tested.

**Recommendation:**
- Add test: `test/preservation/test-salted-meat-inventory-timer.lua` — carry salted meat for N ticks, verify it's still edible at spoilage threshold
- Add test: `test/preservation/test-salted-cook-preserves-multiplier.lua` — raw → salted → cooked → verify 3× multiplier applies to cooked state
- Document salted-meat FSM states explicitly: `fresh-salted → stale-salted → spoiled-salted` (distinct from `fresh → rotten` for unsalted)

---

### ❌ BLOCKERS

**None identified.** All concerns are addressable via test additions or clarifications.

---

## Gate Criteria Audit

### Gate Criteria Specificity — Binary Pass/Fail Assessment

| Gate | Pass/Fail Clarity | Issue | Risk |
|------|------|-------|------|
| **GATE-1** | ⚠️ Mixed | "Room presence text — Manual review" (no acceptance criteria) | Med |
| **GATE-2** | ⚠️ Mixed | Pack narration manual review; omega threshold inconsistent (25% vs 30%) | Med |
| **GATE-3** | ✅ Clear | Salt verb, mutation, spoilage all testable. Exception: two-hand requirement needs explicit test | Med |
| **GATE-4** | ⚠️ Mixed | "3 consecutive runs, 100%" is procedural, not criteria. Manual doc sign-off required. | Low |

**Summary:** 50% of gates have ambiguous manual review steps. Recommend adding acceptance rubric or delegating manual review to named agent with SLA.

---

## Test Determinism & Reproducibility

✅ **Strong** — Pack tests use `math.randomseed(42)`, preservation tests use fixed time. Headless mode throughout. **One gap:**

- **LLM scenarios don't specify seed.** Scenario 2.1–2.5 don't set `math.randomseed(42)`. If creature behavior is random (e.g., werewolf patrol route), scenario could be non-deterministic. **Recommend:** Add seed to echo command or document that scenario assumes default seed (0) or deterministic behavior.

---

## Regression Baseline

✅ **Protocol solid** — PHASE-4-FINAL-COUNT baseline established. Incremental gate targets reasonable. **One caveat:**

- No explicit "freeze commit" or rollback point named before bug fixes run. Recommend PRE-WAVE defines `phase5-pre-wave` tag BEFORE bug fixes, so rollback is clean.

---

## Edge Cases Not Covered

| Edge Case | Test File | Status |
|-----------|-----------|--------|
| Omega retreat at exactly 30% HP (not 25%) | test-pack-omega.lua | ⚠️ Threshold mismatch |
| Salt verb without salt in hand | test-salt-verb.lua | ⚠️ Unclear if tested |
| Salt verb without meat in hand | test-salt-verb.lua | ⚠️ Unclear if tested |
| Salted meat spoils during L2 exploration | (none) | ❌ **Not covered** |
| Salted-cooked meat retains 3× multiplier | test-salt-cook-chain.lua | ⚠️ Unclear implementation |
| Werewolf respawn after 400 ticks | (none) | ❌ **Not covered** |
| Level 1 rooms still accessible after L2 load | (regression test) | ⚠️ Assumed, not explicit |
| Embedding index stale for new L2 nouns | (gate-4 linter check) | ✅ Covered |

---

## Recommendations (Priority Order)

### P0 — Before WAVE-1 Starts

1. **Clarify omega retreat threshold:** Is it 25% or 30%? Update both WAVE-2 code spec (line 335) and GATE-2 criteria (line 599) to match.

2. **Rewrite Scenario 2.4** to include combat and attack verification. Current walkthrough won't test pack behavior.

3. **Define manual review SLA:** Who signs off on room presence, narration, and docs? When? Create `.squad/decisions/inbox/nelson-gate-manual-review-sla.md`.

### P1 — Before PRE-WAVE Tasks Assigned

4. **Expand test file map:** Specify test count per file (not aggregate "~30"). Target 5+ tests for system-critical files.

5. **Add missing test files:**
   - `test/preservation/test-salted-meat-inventory-timer.lua` (carry salted meat for N ticks)
   - `test/creatures/test-creature-respawn.lua` (werewolf respawn at 400 ticks)
   - `test/preservation/test-salt-two-hand-requirement.lua` (both salt and meat required in hands)

6. **Document performance measurement protocol:** Define how L2 instantiation, pack scoring, and salt mutation times are measured (startup overhead, iterations, worst-case).

### P2 — Before WAVE-3 Tasks Assigned

7. **Lock PHASE-4-FINAL-COUNT baseline:** Run after all PRE-WAVE bug fixes complete. Tag as `phase5-freeze-point` for rollback.

8. **Define spoilage FSM state grammar:** Document how salted-meat states (`fresh-salted`, `stale-salted`) relate to unsalted (`fresh`, `rotten`). Update object definitions and tests.

---

## Sign-Off Checklist

- [ ] Omega retreat threshold reconciled (25% vs 30%)
- [ ] Scenario 2.4 includes combat and attack verification
- [ ] Missing test files added (respawn, two-hand, timer)
- [ ] Manual review SLA documented
- [ ] Performance measurement protocol defined
- [ ] Baseline freeze-point committed before PRE-WAVE bug fixes

**Once these are addressed, GATE-1 can proceed with confidence.**

---

## Summary Table

| Finding | Category | Severity | Recommendation |
|---------|----------|----------|-----------------|
| Room presence & narration manual review unclarified | Gate criteria | ⚠️ Med | Define SLA, add acceptance rubric |
| Omega retreat threshold mismatch (25% vs 30%) | Edge case | ⚠️ Med | Reconcile code + gate specs |
| Scenario 2.4 doesn't test pack behavior (no combat) | LLM coverage | ⚠️ Med-High | Rewrite with combat steps |
| Salt verb two-hand requirement test count unclear | Test coverage | ⚠️ Med | Add explicit test file |
| Performance budgets underspecified | Perf gating | ⚠️ Low-Med | Define measurement protocol |
| TDD test count target is loose (~79 over 4 waves) | Test planning | ⚠️ Low | Expand map with per-file counts |
| Salted meat spoilage timeout not tested | Edge case | ⚠️ Med | Add inventory timer test |
| Baseline freeze point not explicit | Regression | ⚠️ Low | Tag `phase5-freeze-point` before bug fixes |

---

## Conclusion

**Phase 5 plan is sound, well-structured, and executable.** Testing gates are mostly binary, regression protocol is solid, and determinism is wired throughout. The 7 concerns are **clarifications and minor test additions**, not structural blockers. Recommend addressing P0 recommendations before WAVE-1 spawning, then proceed with confidence.

**Estimated effort to address all recommendations:** ~8–12 hours (test writing + documentation + threshold reconciliation).

---

**Reviewed by:** Nelson (Tester/QA)  
**Date:** 2026-03-28  
**Status:** 🟡 **Ready to Execute — Pending P0 Clarifications**
