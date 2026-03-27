# Phase 3 Plan Review — Test Coverage + Quality Gates

**Reviewer:** Marge (Test Manager)
**Date:** 2026-08-16
**Plan Reviewed:** `plans/npc-combat/npc-combat-implementation-phase3.md` v1.0
**Requested By:** Wayne "Effe" Berry

---

## Verdict: ⚠️ CONDITIONAL APPROVE

Phase 3 is approved **conditionally** — the plan is solid overall, but has 2 blockers and 4 concerns that must be addressed before implementation begins.

---

## Blockers (Must Fix Before WAVE-0)

### BLOCKER-1: Missing Cross-Wave Compatibility Tests

Phase 2 established a clear cross-wave compat test pattern:
- `test/creatures/test-wave1-2-compat.lua` (creature data → engine expectations)
- `test/combat/test-wave2-3-compat.lua` (combat → NPC-vs-NPC)
- `test/injuries/test-wave3-4-compat.lua` (combat resolution → disease delivery)

**Phase 3 specifies ZERO cross-wave compat tests.** This violates the precedent and creates blind spots between every wave boundary.

**Required additions to the TDD Test File Map (Section 6):**

| Test File | After Gate | Validates |
|-----------|-----------|-----------|
| `test/creatures/test-p3-wave0-1-compat.lua` | GATE-0 | Split combat module still resolves damage correctly in creature death path |
| `test/creatures/test-p3-wave1-2-compat.lua` | GATE-1 | Corpse objects from W1 are valid containers for W2 inventory drops |
| `test/food/test-p3-wave2-3-compat.lua` | GATE-2 | Dead creature objects carry `crafting.cook` metadata needed by W3 cook verb |
| `test/injuries/test-p3-wave3-4-compat.lua` | GATE-3 | Food-poisoning injury compatible with W4 cure mechanics pipeline |
| `test/creatures/test-p3-wave4-5-compat.lua` | GATE-4 | Cured/stressed creatures can be targets for W5 respawn tracking |

**Impact:** +5 test files, ~50 tests. Revise Section 5 estimates accordingly (from ~190 to ~240).

### BLOCKER-2: Meta-Lint Infrastructure Does Not Exist

WAVE-2 specifies meta-lint rules INV-01 through INV-04 (creature inventory validation). Nelson is assigned to implement them. However:

- **No meta-lint test framework exists** in the codebase today (zero matches for meta-lint/meta-check in test files).
- The plan assumes meta-lint rules can simply be "added" — but the infrastructure to run and test them needs to be built first.
- D-MUTATION-GRAPH-LINTER is still 🟡 In Progress, suggesting the broader linting pipeline is incomplete.

**Required fix:** WAVE-2 must include a **meta-lint bootstrap** task (Bart or Nelson) before INV-01–INV-04 can be authored. Add ~5 LOC estimate + 1 test file for the framework itself, or explicitly declare the dependency on D-MUTATION-GRAPH-LINTER completion.

---

## Concerns (Should Fix, Not Blocking)

### CONCERN-1: GATE-0 Listed as "No Formal Gate"

The dependency graph (Section 3) states: `── (no formal gate — split verified, tests pass) ──` for WAVE-0.

This is inconsistent with Section 4, which DOES define GATE-0 criteria (combat/init.lua ≤ 500 LOC, resolution.lua exists, all 194 tests pass, etc.). The Section 3 comment undermines the rigor.

**Fix:** Remove the "no formal gate" parenthetical from Section 3. GATE-0 is real and critical — a bad combat split would cascade to every subsequent wave.

### CONCERN-2: `survival.lua` (715 LOC) Not Scheduled for Split

The plan correctly flags `crafting.lua` (629 LOC) and `survival.lua` (715 LOC) as over the 500 LOC limit. WAVE-3 then **adds ~30 LOC to survival.lua** (eat handler extensions), pushing it to ~745 LOC.

The LOC audit is in WAVE-0 but no split is scheduled. If survival.lua breaks during WAVE-3 modifications, the blast radius is large (eat, drink, sleep, rest — all survival verbs).

**Recommendation:** Either (a) split survival.lua in WAVE-0 alongside the combat split, or (b) add a GATE-3 criterion: `survival.lua ≤ 800 LOC` as a hard cap, with a mandatory Phase 4 split if exceeded.

### CONCERN-3: Spoilage + Respawn Timer Tests May Be Slow

The test runner (`test/run-tests.lua`) has:
- **No timeout mechanism** per test file
- **No parallel execution** (sequential subprocess spawning)

Phase 3 adds timer-dependent tests:
- Spoilage FSM: fresh → bloated → rotten → bones (tick-driven)
- Respawn timer: 60–200 ticks per creature
- "wait ×60" in the LLM walkthrough

If these tests simulate real tick counts rather than using mock/fast-forward injection, the suite could slow significantly. With ~211 test files post-Phase 3, any per-file slowdown compounds.

**Recommendation:** Add to GATE-5 criteria: "Full test suite completes in under 120 seconds" (or whatever the current baseline is). Nelson should use tick injection, not real waits.

### CONCERN-4: Gate Criteria Need Numeric Precision on Two Items

| Gate | Vague Criterion | Suggested Precision |
|------|-----------------|---------------------|
| GATE-1 | "Dead rat spoilage FSM ticks correctly" | "Dead rat transitions fresh→bloated at tick 50, bloated→rotten at tick 100, rotten→bones at tick 150 (or per food-system-plan.md §5 values)" |
| GATE-4 | "Combat sounds attract/repel creatures in adjacent rooms" | "Combat in Room A emits loud_noise stimulus; creature in adjacent Room B with `timid` behavior flees; creature with `aggressive` behavior approaches" |

Precise gates enable automated verification. Vague gates require human judgment calls that slow the pipeline.

---

## Positive Findings

1. **TDD coverage is comprehensive.** 16 test files covering every new feature, every wave. Every engine change has a corresponding test assignment. This is clean.
2. **Gate-per-wave discipline maintained.** Every gate includes "All existing tests pass (zero regressions)" — consistent with D-WAYNE-REGRESSION-TESTS and D-CHECKPOINT-AFTER-WAVE.
3. **D-14 mutation used correctly.** Creature death → corpse mutation follows the Prime Directive. No state flags, no shortcuts.
4. **Principle 8 compliance.** Cook recipe on the food object, cure eligibility on the injury, respawn metadata on the creature — all metadata-driven, no object-specific engine code.
5. **Backward compatibility preserved.** Creatures without `mutations.die` keep existing behavior. Good defensive design.
6. **Nelson LLM walkthroughs specified.** WAVE-3 and WAVE-5 both include `--headless` walkthrough commands — compliant with D-HEADLESS.
7. **Parallel track assignments are clean.** No agent is double-booked within a wave. Dependencies are well-mapped.

---

## Regression Risk Assessment

| Wave | Risk Level | Rationale |
|------|-----------|-----------|
| WAVE-0 | 🔴 HIGH | Extracting ~250 LOC from a 695 LOC combat module. Any import/reference error breaks ALL combat tests. Mitigated by running full suite at GATE-0. |
| WAVE-1 | 🟡 MEDIUM | Modifying creature death path in `creatures/init.lua`. Could break existing creature tick, creature combat, or creature FSM tests (13 existing creature test files). |
| WAVE-2 | 🟢 LOW | Mostly additive — new inventory metadata, new objects. Only risk is double-processing in creature tick. |
| WAVE-3 | 🟡 MEDIUM | Modifying `survival.lua` (715 LOC, already over limit) and `crafting.lua` (629 LOC). Existing eat/drink tests could break if handler signature changes. |
| WAVE-4 | 🟡 MEDIUM | Modifying `injuries.lua` (cure mechanics). Existing injury tests (9 injury types, multiple test files) could regress. |
| WAVE-5 | 🟢 LOW | Mostly additive — new respawn module, metadata on creatures. Low blast radius. |

**Highest risk:** WAVE-0 and WAVE-3. These should receive the most careful post-gate review.

---

## Performance Assessment

- **Current baseline:** 191 test files, sequential execution, no timeouts.
- **Post-Phase 3 estimate:** ~211 test files (+20), ~240 new tests across those files.
- **Runtime concern:** LOW if timer tests use tick injection. MEDIUM if they simulate real ticks.
- **Recommendation:** Establish a baseline runtime measurement at GATE-0 and track it at every gate. If runtime growth exceeds 20%, investigate before proceeding.

---

## Summary

| Category | Status |
|----------|--------|
| Test coverage | ✅ Comprehensive (with BLOCKER-1 fix) |
| Gate criteria | ✅ Mostly measurable (with CONCERN-4 fix) |
| Cross-wave compat | ❌ Missing — BLOCKER-1 |
| Meta-lint prereq | ❌ Missing infrastructure — BLOCKER-2 |
| Regression risk | ⚠️ WAVE-0 and WAVE-3 highest risk (acknowledged, mitigated by gates) |
| Performance | ⚠️ Monitor, not blocking |

**Conditional approval clears when:**
1. Cross-wave compat tests added to Sections 5 + 6 (BLOCKER-1)
2. Meta-lint bootstrap task added to WAVE-2 or dependency on D-MUTATION-GRAPH-LINTER made explicit (BLOCKER-2)

---

*— Marge, Test Manager*
*"No wave ships without green tests."*
