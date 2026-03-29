# Sound Plan Review — Marge (Test Manager)

**Plan:** `projects/sound/sound-implementation-plan.md` + `board.md`  
**Date:** 2026-03-30  
**Verdict:** ⚠️ Concerns  

---

## Findings

### 1. ✅ Test Gate Structure Sound
Four waves with binary gates (GATE-0 through GATE-3). Each gate has pass criteria:
- GATE-0: Module loads, no-op works, web bridge connects, zero regressions
- GATE-1: Metadata complete, sounds sourced, validation tests pass
- GATE-2: FSM/verb/mutation hooks wired, integration tests pass
- GATE-3: Build pipeline works, LLM walkthroughs pass

This is good structure. Each gate is clear.

### 2. ⚠️ **BLOCKER: Nelson LLM Test Scenarios Undefined**
The plan says: "GATE-3: LLM headless walkthroughs pass (5 scenarios)" but the **specific scenarios are not listed**. What are the 5 scenarios?

Example: Does a walkthrough include:
- Lighting a candle in darkness (sound + text coordination)?
- Listening to a creature (sound event + on_listen text)?
- Room transitions (ambient start/stop)?
- Combat hit with sound?
- All of the above?

**Without this spec, Nelson cannot write reproducible tests.** This blocks WAVE-3 gate definition.

**Recommendation:** Add section "Nelson LLM Test Scenarios (GATE-3)" with explicit headless commands:
```
Scenario 1: Look → Listen (candle on table)
$ look
$ listen
$ take candle
Expected: Text appears, candle sound queues if loaded, no crash

Scenario 2: Combat sound
$ attack wolf
Expected: Hit text appears, combat sound plays/queues, no crash
... etc (3 more scenarios)
```

### 3. ⚠️ **BLOCKER: No Regression Baseline**
The plan says "zero regressions" but doesn't specify:
- What IS the baseline test count at WAVE-0 start? (Need: `lua test/run-tests.lua --count-only`)
- What baseline must GATE-3 match?
- What is the flaky-test protocol if a pre-existing test fails?

**Recommendation:** Add to plan: "Baseline snapshot: {N} tests pass at WAVE-0 start; GATE-3 must report same {N} passing."

### 4. ⚠️ **BLOCKER: Headless Mode Coverage Unclear**
The plan says "Headless mode: ctx.sound_manager is nil" but doesn't verify:
- Does the test suite run in headless mode (it should)?
- Are there explicit headless variants of Nelson's tests?
- Does `--headless` get injected into the test runner automatically?

Example missing spec: "All tests run with `lua test/run-tests.lua --headless` before each gate."

**Recommendation:** Add to all gate criteria: "All tests pass with and without `--headless` flag."

### 5. ⚠️ Concern: Mock Driver vs Web Driver Test Split
WAVE-0 includes "mock driver tests" for the sound manager. But the plan doesn't spec:
- How does Nelson mock the web bridge (JS interop)?
- Can `pcall()` safely hide all JS errors during tests?
- Is there a "mock.lua" driver that tracks calls without playing audio?

**Currently assumes:** Yes, Bart will write a mock driver. But this assumption needs explicit visibility in the plan.

**Recommendation:** Add to WAVE-0 Track 0A: "Bart provides mock driver (`test/sound/mock-driver.lua`) that records all play/stop/load calls for verification."

### 6. ⚠️ Concern: Concurrency Limits Testing
The plan specifies: "Max 4 concurrent one-shots, Max 3 concurrent ambient loops." But no test covers this:
- Does test fire 5 one-shots and verify oldest is evicted?
- Does test verify priority: room > creature > object?

**Recommendation:** Add to GATE-0 criteria: "Concurrency tests: (a) 5 one-shots loaded, oldest evicted verified; (b) 3 ambient loops prioritized (room trumps creature)."

### 7. ✅ Nelson Autonomous Walkthrough Pattern Good
Using `echo "cmd" | lua src/main.lua --headless` is solid. Deterministic seeds for randomness (if creatures spawn randomly) noted as important.

### 8. ⚠️ Concern: Cache Bust + Asset Deploy Testing
The plan mentions HTTP cache-bust (`?v=CACHE_BUST`), but no test verifies:
- Does the deployed sound URL actually resolve? (Integration test against staging server?)
- Can the browser decode fetched .opus files?

This might be a **Phase 2 concern** (manual QA on staging), not a gate blocker. But it should be explicit.

**Recommendation:** Mark as Phase 2 QA: "Manual test on staging: fetch sounds/rat-squeak.opus?v={CACHE_BUST}, verify browser plays audio."

### 9. ⚠️ Concern: Flaky Test Quarantine Plan Missing
If Nelson discovers a test is non-deterministic (sound timing, async load race), what's the protocol?
- Mark with `@skip-ci` + issue link?
- Retry with fixed seed?
- Escalate to Bart?

**Recommendation:** Add to plan: "Non-deterministic tests marked `@skip-ci` with issue link. Bart decides: fix or quarantine."

### 10. ✅ Asset Sourcing Responsibility Clear
CBG sources sounds, Nelson validates metadata. Good ownership. But validation tests aren't defined — see Finding #2.

---

## Consolidated Verdict

**The testing strategy is structurally sound but has 3 blockers and 5 concerns.**

### Blockers (Must Fix Before GATE-0)

1. **Define Nelson LLM Test Scenarios explicitly.** List 5 headless walkthroughs with expected inputs/outputs.
2. **Baseline regression snapshot needed.** Capture test count at WAVE-0 start, enforce match at GATE-3.
3. **Headless mode coverage explicit.** Add "All tests pass with `--headless`" to every gate.

### Concerns (Strongly Recommended)

4. Mock driver spec in GATE-0: Bart provides `test/sound/mock-driver.lua`.
5. Concurrency limit tests: Eviction + priority verified in GATE-0.
6. Flaky test quarantine protocol: `@skip-ci` + issue link documented.
7. Cache-bust asset testing: Phase 2 QA on staging (explicit, not assumed).
8. Async load race conditions: Fixed seeds for LLM tests.

---

**Reviewed by:** Marge (Test Manager)  
**Confidence:** Medium (3 blockers, 5 concerns = rework cycle needed)  
**Signature:** ⚠️
