# QA Review: Phase 2 NPC+Combat Implementation Plan

**Reviewer:** Marge (QA Lead)  
**Date:** 2026-03-26  
**Plan:** `plans/npc-combat-implementation-phase2.md` (Chunks 1–3)  
**Requested by:** Wayne Berry  

---

## Executive Summary

**Overall Status:** ⚠️ **CONDITIONALLY APPROVED WITH CRITICAL GAPS**

The Phase 2 plan demonstrates strong architectural thinking, comprehensive gate criteria, and excellent wave dependencies. However, **critical issues in test isolation, autonomy protocol, and LLM coverage require resolution before WAVE-0 launch**.

| Category | Status | Notes |
|----------|--------|-------|
| Test Coverage | ⚠️ | 15 TDD files specified; gaps in cross-wave regression testing |
| Gate Criteria | ⚠️ | Binary gates defined; but GATE-0 lacks enforcement mechanism |
| Regression Risks | ⚠️ | Combat + creatures interaction untested pre-Phase 2 |
| LLM Scenarios | ✅ | 11 scenarios solid; coverage complete |
| Performance Budgets | ❌ | Unrealistic for 10 creatures; no baseline data |
| Test Isolation | ❌ | WAVE-3/4/5 cross-dependencies create test brittleness |
| Autonomy Protocol | ❌ | Plan assumes Wayne's presence for decision-making |

---

## 1. Test Coverage — TDD Files & Regression Risk

### ✅ Strengths

- **15 new test files** specified across 5 waves
- **Explicit assertions** per test file (creatures, combat, disease, food)
- **Clear ownership:** Nelson owns all test files; no ambiguity
- **Wave-scoped test creation:** Tests created AFTER implementation starts (good practice)

### ⚠️ Gaps

#### Gap 1.1: WAVE-0 has no explicit test file

**Issue:** Pre-flight checklist mentions "test dirs registered" and "no regressions," but:
- No `test/run-tests.lua` modification spec (line 199 says "MODIFY" but no detail)
- No explicit test that verifies the new dirs exist and are discovered
- `test/food/` is registered, but `test/scenarios/` is not mentioned in chunk 2a

**Risk:** GATE-0 passes mechanically, but test runner may not discover `test/scenarios/gate{N}/` subdirs.

**Recommendation:** Create `test/wave0/test-preflight.lua`:
```lua
-- Validates: test/run-tests.lua discovers new directories without error
-- Verifies: test/creatures/, test/combat/, test/food/, test/scenarios/ exist
-- Ensures: baseline test count at WAVE-0 start (for regression delta tracking)
```

#### Gap 1.2: No cross-wave integration test until GATE-5

**Issue:** 
- WAVE-1 creates creature data (isolated)
- WAVE-2 tests creature behavior (isolated from WAVE-1 data)
- WAVE-3 tests NPC combat (depends on creatures from WAVE-2)
- WAVE-4 tests disease (depends on combat from WAVE-3)
- WAVE-5 tests food (depends on creatures + disease from earlier waves)

**But:** No test file validates creature data + behavior together until WAVE-2 completes.

**Risk:** Creature specs (WAVE-1) may be incompatible with behavior engine (WAVE-2) even if both gate individually. Discovered only at GATE-2, causing re-work.

**Recommendation:** Add `test/creatures/test-wave1-2-integration.lua` to WAVE-2:
```lua
-- Validates that cat.lua metadata aligns with attack scoring logic
-- Tests: has_prey_in_room(cat) with real cat.lua data + rat.lua
-- Tests: select_prey_target(context, cat) against loaded creatures
```

#### Gap 1.3: Phase 1 creature/combat tests not re-run at GATE-1/2/3

**Issue:** Plan says "zero regressions," but Phase 1 tests are 14 existing files. At GATE-1, we add 5 new creature files. Does GATE-1 re-run the Phase 1 creature tests?

- Line 684: `test/run-tests.lua — zero regressions in ALL existing tests (Phase 1 creature/combat tests still pass)` ✓
- But this is implicit in GATE-1. Not explicit in GATE-1 pass criteria above that line.

**Risk:** Phase 1 tests could silently regress if not run.

**Recommendation:** Make it explicit in GATE-1:
```
- lua test/run-tests.lua | grep -c "PASS" → (baseline + ~80 new tests)
- Verify: Phase 1 creature/combat tests still all pass
```

#### Gap 1.4: No test for engine file size guard (GATE-0)

**Issue:** Line 656: "No engine file exceeds 500 LOC (checked via `wc -l`)" is mentioned but:
- No test file implements this
- Manual check (`wc -l src/engine/**/*.lua`) is not automated
- GATE-0 says "LOC guard: wc -l src/engine/**/*.lua | Every file < 500 lines"
- But who runs this? Bart? Marge? How is it logged?

**Risk:** GATE-0 lint check gets skipped; Bart's engine files balloon post-Phase-2.

**Recommendation:** Create automated check in `test/wave0/test-loc-guard.lua`:
```lua
-- Reads src/engine files; asserts each < 500 lines
-- Logs LOC summary at test end
```

---

## 2. Gate Criteria — Binary Pass/Fail & Enforcement

### ✅ Strengths

- **5 gates defined** with explicit pass/fail criteria
- **GATE-0 through GATE-5** form a linear dependency chain
- **Reviewer assignments** clear (Bart, Nelson, Marge, CBG)
- **Action on fail** specified for each gate (file issue, assign, re-gate)

### ⚠️ Critical Gap

#### Gap 2.1: GATE-0 has no enforcement mechanism

**Issue:** 
- GATE-0 is described as "5-minute setup" (line 670)
- **But it has test-runner discovery + LOC guard + regression checks.**
- Then immediately says: "On pass: No separate commit — WAVE-0 is a 5-minute setup folded into WAVE-1 commit." (line 670)

**This is contradictory.** If GATE-0 fails (e.g., LOC check fails), do we commit anyway?

**Risk:** Quality gate becomes advisory, not enforced. Bart could skip GATE-0 review if it's "folded into WAVE-1."

**Recommendation:** Clarify GATE-0 pass/fail action:
```
ON GATE-0 PASS: Bart commits with tag "gate-0-preflight" before WAVE-1 starts
ON GATE-0 FAIL: Re-gate GATE-0; no WAVE-1 commits until GATE-0 passes
```

#### Gap 2.2: GATE-4 has no performance budget measurement script

**Issue:** Line 802: "Performance budget: Disease tick (all active injuries) resolves in <10ms for 5 concurrent diseases."

**But:** No test file measures this. `test/injuries/test-disease-*` files don't mention `os.clock()` measurement.

**Risk:** Performance budget is aspirational, not verified. Disease system could ship 100ms/tick; gate would pass anyway.

**Recommendation:** Add performance assertion to `test/injuries/test-disease-delivery.lua`:
```lua
local start = os.clock()
for i = 1, 100 do
    injuries.tick(context)  -- all 5 disease instances
end
local elapsed = os.clock() - start
assert(elapsed / 100 < 0.010, "Disease tick avg > 10ms")
```

#### Gap 2.3: GATE-3 multi-combatant test doesn't specify seed

**Issue:** Line 747: "Multi-combatant: 3 creatures in same room... no infinite loops (max 20 rounds safety)"

**But:** No seed mentioned. Determinism rule (line 866) says seeds must be fixed for reproducible tests. If multi-combatant test randomizes creature targets, it might fail one run, pass the next.

**Risk:** Flaky test; GATE-3 becomes probabilistic.

**Recommendation:** Specify seed in GATE-3 spec:
```
test-multi-combatant.lua: seed 42, verify turn order + termination (no loops) 
```

---

## 3. Regression Risks — Cross-Wave Breakage

### ⚠️ Critical Gaps

#### Gap 3.1: Combat + Creatures interaction untested before WAVE-2

**Issue:** 
- Phase 1 shipped creature engine (421 LOC) + combat FSM (435 LOC)
- But Phase 1 combat tests *only* test **player-vs-rat**, not **creature-vs-creature**
- WAVE-2 is when we wire attack → Combat FSM
- **WAVE-1 modifies the creature FSM specs (adds combat metadata), but WAVE-2 modifies engine to USE it.**

**If WAVE-1 specs are incompatible with WAVE-2 engine, we discover this at GATE-2 (very late).**

**Risk:** GATE-1 passes (creatures load). GATE-2 fails (engine can't interpret creatures). Requires WAVE-1 re-work.

**Recommendation:** Add integration smoke test to WAVE-2:
```lua
-- test/creatures/test-wave2-engine-compat.lua
-- Load real cat.lua + rat.lua; call creature.attack_action()
-- Verify creature.execute_action("attack", target) doesn't error
```
This can run BEFORE WAVE-2 implementation, as a spec check.

#### Gap 3.2: Disease-Combat integration untested until GATE-4

**Issue:** 
- WAVE-3 ships NPC-vs-NPC combat
- WAVE-4 ships disease delivery via `on_hit`
- **But what if WAVE-3 combat tests don't cover `on_hit` field?**
- Weapon object created in WAVE-1 might not have `on_hit` structure that WAVE-4 expects

**Risk:** GATE-3 combat tests pass. GATE-4 disease delivery fails because weapons don't have `on_hit` field.

**Recommendation:** Add `on_hit` field validation to WAVE-1 creature tests:
```lua
-- test/creatures/test-wave1-weapon-structure.lua
-- For each creature.combat.natural_weapons entry:
-- Assert: weapon has "on_hit" field (table or nil) → compatible with WAVE-4 delivery
```

#### Gap 3.3: Food + Disease interaction untested until GATE-5

**Issue:** 
- WAVE-4 rabies blocks `drink` via `restricts.drink`
- WAVE-5 adds `drink` verb
- **But WAVE-5 test doesn't verify that rabies-blocked drink works pre-food.**

**Risk:** GATE-5 scenario "rabies blocks drink" fails because drink verb wasn't tested in GATE-4.

**Recommendation:** Add cross-wave test to GATE-4:
```lua
-- test/injuries/test-disease-verbs-integration.lua (GATE-4)
-- Verifies: restricts.drink flag exists + is checked by (hypothetical) drink verb
-- Doesn't test drink verb logic (that's GATE-5), just compatibility
```

---

## 4. LLM Scenarios — Coverage & Sufficiency

### ✅ Excellent Coverage

**11 LLM scenarios specified (GATE-2 through GATE-5):**
- GATE-2: P2-A (cat/rat), P2-B (wolf), P2-C (spider web) = 3 scenarios
- GATE-3: P2-D (witness lit), P2-D2 (witness dark), P2-E (multi-combatant) = 3 scenarios
- GATE-4: P2-F (rabies), P2-F2 (venom) = 2 scenarios
- GATE-5: P2-G (bait), P2-H (eat/drink), P2-I (rabies blocks drink), P2-J (full end-to-end) = 4 scenarios

**Total: 12 scenarios** (P2-A through P2-J + full walkthrough)

### ✅ Determinism & Seeding

- Seed 42 specified for most tests (good for reproducibility)
- Fallback to seeds 43, 44 if probabilistic tests fail (excellent)
- Headless mode enforced (prevents TUI false positives) ✓

### ⚠️ Minor Gaps

#### Gap 4.1: No scenario for creature fleeing successfully

**Issue:** GATE-3 tests morale/flee (line 760), but no LLM scenario verifies it.

**Risk:** Flee logic could be broken; gate still passes (unit test passes, but end-to-end behavior is wrong).

**Recommendation:** Add P2-E2: "Creature Flees Successfully"
```bash
# Wolf at low health vs player → wolf should flee, not fight to death
echo "go hallway\nattack wolf\nwait\nattack wolf\nlook" | lua src/main.lua --headless
# Expected: wolf health low → wolf flees → player sees "wolf scurries away"
```

#### Gap 4.2: No scenario for multi-combatant with player intervention

**Issue:** GATE-3 spec mentions (line 761) "Player joins active fight during cat-vs-rat combat," but no LLM scenario covers this.

**Risk:** Player intervention logic could be broken; gate still passes (unit tests pass, but end-to-end is broken).

**Recommendation:** Add P2-E3: "Player Joins Active NPC Combat"
```bash
# Cat and rat fighting. Player enters mid-fight and attacks one.
echo "go cellar\nwait\nwait\nattack rat\nlook" | lua src/main.lua --headless
# Expected: player joins combat; turn order updates; 3-way fight ensues
```

---

## 5. Performance Budgets — Realistic or Aspirational?

### ❌ Critical Issue

**Performance budgets specified but no baseline data:**

| System | Budget | Baseline | Risk |
|--------|--------|----------|------|
| Creature tick (10 creatures) | <50ms | **UNKNOWN** | ❌ |
| Combat resolution (3 creatures) | <100ms | **UNKNOWN** | ❌ |
| Disease tick (5 diseases) | <10ms | **UNKNOWN** | ❌ |

#### Gap 5.1: No Phase 1 performance baseline

**Issue:** 
- Phase 1 shipped creature engine. Does it meet the <50ms budget?
- Phase 1 shipped combat FSM. Does it meet the <100ms budget?
- **We don't know.** No baseline measurements recorded.

**Risk:** 
- WAVE-2 adds creature generalization (predator-prey scanning). Could push creatures from 40ms → 60ms (fail budget).
- We won't discover this until GATE-2 performance test runs.
- Then we have to optimize mid-phase (risky).

**Recommendation (GATE-0):**
1. Run Phase 1 creature tests 10× with `os.clock()` measurement
2. Record baseline (e.g., "Phase 1 creature tick: 30ms avg")
3. Set GATE-2 target: "Phase 2 creature tick: 35ms avg (±5ms margin)"

#### Gap 5.2: Combat budget ignores player participation

**Issue:** Budget says "combat resolution <100ms for a 3-creature fight" but doesn't specify if player is attacker, defender, or observer.

- Player attacker vs 2 NPCs: complex (player AI + 2 NPC targets)
- Player defender vs 2 NPCs: moderately complex
- Player observer (witness narration only): simple

**Risk:** Test runs "3 creature fight (NPC vs NPC)" and passes <100ms. But player joins → fight takes 200ms → user perceives lag.

**Recommendation:** Specify budget per scenario:
- NPC-vs-NPC (3 creatures): <100ms
- Player-vs-NPC-vs-NPC: <150ms
- Witness narration (no player involvement): <20ms

#### Gap 5.3: No memory profiling for creature registry

**Issue:** WAVE-2 adds creature stimuli emission. Each stimulus is buffered in a queue. After 100 ticks:
- 10 creatures × ~5 stimuli/creature/tick = 50 stimuli/tick
- 100 ticks × 50 = 5,000 stimuli buffered (if not flushed)

**Risk:** Memory leak. Stimuli queue grows unbounded → OOM after 1000 ticks.

**Recommendation:** Add `test/creatures/test-creature-perf.lua` (already specified in GATE-2):
```lua
local mem_start = collectgarbage("count")
creatures.tick(context) -- 100 times
collectgarbage()
local mem_end = collectgarbage("count")
assert(mem_end < mem_start * 1.1, "Memory leak: >10% increase")
```

---

## 6. Test Isolation — Wave Dependencies & Brittleness

### ❌ Critical Issues

#### Issue 6.1: WAVE-3 tests depend on WAVE-2 implementation

**Current structure:**
- WAVE-2: Implement creature attack + predator-prey
- GATE-2: Test creature behavior (isolated)
- **WAVE-3: Implement NPC combat + witness narration**
- GATE-3: Test NPC combat (depends on creature attack from WAVE-2!)

**Problem:** GATE-3 test `test-npc-combat.lua` calls:
```lua
creatures.execute_action("attack", target)  -- WAVE-2 implementation
```

If GATE-2 passes but WAVE-2 implementation is incomplete (e.g., attack doesn't set `combat.phase`), then GATE-3 test will fail. **Test isolation broken.**

**Risk:** GATE-3 failure → blame on WAVE-3 (NPC combat), but root cause is WAVE-2 incomplete.

**Recommendation:** Extract creature attack logic into a sub-test that GATE-2 MUST pass:
```lua
-- test/creatures/test-wave2-attack-readiness.lua (run at GATE-2)
-- Validates: creatures.execute_action("attack") completes without error
-- Validates: attack sets all fields that WAVE-3 NPC combat expects
```

#### Issue 6.2: WAVE-4 disease tests depend on WAVE-3 combat

**Current structure:**
- WAVE-3: Implement NPC combat
- GATE-3: Test NPC combat (isolated)
- **WAVE-4: Implement on_hit disease delivery**
- GATE-4: Test disease (depends on combat from WAVE-3!)

**Problem:** GATE-4 test `test-disease-delivery.lua` calls:
```lua
combat.run_combat(ctx, spider, player, venom_bite)  -- WAVE-3 implementation
```

If GATE-3 passes but combat.run_combat doesn't properly call `resolve_exchange()` for NPC-as-attacker, then GATE-4 test will fail or create false positives.

**Risk:** GATE-4 failure → blame on disease, but root cause is combat incomplete.

**Recommendation:** Extract combat+disease integration into GATE-3:
```lua
-- test/combat/test-combat-disease-compat.lua (run at GATE-3)
-- Validates: combat.run_combat() accepts creature as attacker
-- Validates: resolve_exchange() checks for on_hit field (even if not used yet)
```

#### Issue 6.3: WAVE-5 food tests depend on WAVE-1 + WAVE-2 + WAVE-4

**Current structure:**
- WAVE-1: Creature data (cheese.lua, bread.lua)
- WAVE-2: Creature behavior (bait stimulus)
- WAVE-4: Disease (rabies blocks drink)
- **WAVE-5: Implement eat/drink verbs + food bait**
- GATE-5: Test food (depends on creatures + behavior + disease!)

**Problem:** GATE-5 scenario P2-J (full end-to-end) depends on:
1. Creature data (cheese exists) — from WAVE-1
2. Bait behavior (rat approaches food) — from WAVE-2
3. Disease (rabies blocks drink) — from WAVE-4

If ANY of those waves are incomplete, GATE-5 full scenario fails. But which wave broke it?

**Risk:** GATE-5 failure → blame on food, but root cause could be creature data or behavior or disease.

**Recommendation:** Add sequential sub-gates:
- GATE-5a: Food objects load + validate (WAVE-1 data ready)
- GATE-5b: Bait stimulus fires (WAVE-2 behavior ready)
- GATE-5c: Rabies blocks drink (WAVE-4 disease ready)
- GATE-5 (full): End-to-end integration

---

## 7. Autonomy Protocol — Can This Run Without Wayne?

### ❌ Critical Gaps

#### Gap 7.1: Who decides if a gate fails?

**Issue:** Each gate specifies "Reviewer" (e.g., "Bart architecture, Marge test sign-off"). But:
- What if Bart is unavailable?
- What if gate outcome is ambiguous (e.g., "performance is 48ms, budget is 50ms")?
- Who has final authority to declare GATE-2 failed?

**Current plan says:** "Action on fail: File issue, assign to [team], re-gate." But doesn't specify escalation path if team disagrees.

**Risk:** Phase 2 stalls waiting for Wayne's decision on a borderline gate outcome.

**Recommendation:** Document decision authority:
```
GATE-0 authority: Bart (architecture) — final say on "no regressions"
GATE-1 authority: Bart (architecture) — final say on creature validity
GATE-2 authority: Bart (architecture) + Marge (performance check)
GATE-3 authority: Bart (architecture) + Nelson (LLM walkthrough)
GATE-4 authority: Bart (architecture) + Marge (regression analysis)
GATE-5 authority: Bart (architecture) + Nelson (full LLM) + CBG (player experience)

Decision rule: Unanimous "PASS" = gate passes. Any "FAIL" = re-work required.
              Ambiguous = escalate to Wayne (decision architect).
```

#### Gap 7.2: No protocol for parallel wave blockers

**Issue:** Plan says waves run in parallel (e.g., WAVE-2 tracks 3-4 agents). But:
- WAVE-2: Bart (engine), Nelson (tests), Smithers (none), CBG (none)
- If Bart's creatures/init.lua changes break Nelson's tests, who decides?

**Plan doesn't specify:** Can Nelson block GATE-2 on Bart's incomplete code? Or does Bart have final say?

**Risk:** Conflict during WAVE-2 execution. Nelson writes tests, Bart's code fails tests, they argue about who fixes it.

**Recommendation:** Add to each wave:
```
Conflict resolution (WAVE-X):
- If Nelson's test fails on Bart's code: Bart has 4 hours to fix. 
  If unfixed, Nelson escalates to Wayne.
- If Bart's code is blocked on Nelson's test: Nelson has 2 hours to debug.
  If unresolved, Nelson escalates to Wayne.
```

#### Gap 7.3: No emergency abort protocol

**Issue:** What if a wave discovers a fundamental architectural flaw mid-implementation?

**Example:** WAVE-2 creature predator-prey detection scans all creatures every tick. At GATE-2 performance test, it's 200ms (4× budget). Re-architecting could push back launch by 2 weeks.

**Current plan:** No abort/pivot protocol. Implies we must push through.

**Risk:** Phase 2 ships with known performance problems, or stalls for 2 weeks.

**Recommendation:** Add decision point:
```
WAVE-X: If performance budget cannot be met by cycle N, 
        Wayne decides: (A) Ship with known issue, (B) De-scope feature, (C) Re-architect
```

#### Gap 7.4: Portal TDD burndown (#199-208) is parallel, but not gated

**Issue:** Line 200: "Nelson: Parallel: Portal TDD burndown (#199–#208), lint fixes (#249, #250)"

**But:** No mention of how portal TDD impacts GATE-0. Does it need to pass before WAVE-1 starts? Or is it independent?

**Risk:** Portal TDD stalls. WAVE-0 gets blocked waiting for Nelson to finish portals + WAVE-0 preflight tests.

**Recommendation:** Clarify:
```
Portal TDD (#199-208) and GATE-0 preflight are independent. 
Portal TDD does NOT block WAVE-0 or GATE-0. 
Nelson can work on portals in parallel with GATE-0; they don't interact.
```

---

## 8. Summary Findings by Category

### Test Coverage

| Item | Status | Impact |
|------|--------|--------|
| 15 TDD files specified | ✅ | Good |
| WAVE-0 test automation | ⚠️ | Lint checks not automated |
| Cross-wave integration tests | ❌ | CRITICAL: No WAVE-1/2 compat test |
| Phase 1 regression re-runs | ✅ | Implicit in gates; needs explicit log |
| Performance measurement | ❌ | CRITICAL: No baseline data |
| Disease/combat integration | ⚠️ | Untested until GATE-4 |
| Food/disease interaction | ⚠️ | Untested until GATE-5 |

**Recommendation:** Add 5 new test files:
- `test/wave0/test-preflight.lua`
- `test/creatures/test-wave1-2-integration.lua`
- `test/creatures/test-wave1-weapon-structure.lua`
- `test/injuries/test-disease-verbs-integration.lua`
- `test/creatures/test-phase1-baseline.lua` (performance benchmark)

### Gate Criteria

| Item | Status | Impact |
|------|--------|--------|
| Gates defined (5) | ✅ | Good |
| Pass/fail explicit | ✅ | Good |
| Enforcement mechanism | ❌ | CRITICAL: GATE-0 can be skipped |
| Performance verification | ❌ | CRITICAL: No measurement script |
| Seed determinism | ⚠️ | Multi-combatant test seed unspecified |

**Recommendation:** 
- Add commit/tag enforcement to GATE-0/1
- Add `os.clock()` measurements to performance budgets
- Specify seed for all probabilistic tests

### Regression Risks

| Item | Status | Impact |
|------|--------|--------|
| Phase 1 creature tests rerun | ✅ | Specified at GATE-1 |
| Combat + creatures compat | ❌ | CRITICAL: No pre-WAVE-2 test |
| Disease + combat compat | ❌ | CRITICAL: No pre-WAVE-4 test |
| Food + disease compat | ⚠️ | Covered at GATE-5 |

**Recommendation:** Add 3 new compatibility tests (run at end of prior wave, before next wave starts).

### LLM Scenarios

| Item | Status | Impact |
|------|--------|--------|
| Count (11 scenarios) | ✅ | Excellent |
| Coverage (GATE-2–5) | ✅ | Comprehensive |
| Seeding (42/43/44) | ✅ | Good |
| Creature flee scenario | ⚠️ | Missing (morale/flee LLM test) |
| Player intervention scenario | ⚠️ | Missing (player joins NPC fight) |

**Recommendation:** Add 2 new LLM scenarios for GATE-3.

### Performance Budgets

| Item | Status | Impact |
|------|--------|--------|
| Creature tick <50ms | ❌ | No baseline; likely unrealistic |
| Combat <100ms | ❌ | No baseline; no player-involved variant |
| Disease <10ms | ⚠️ | Achievable; measurement script needed |

**Recommendation:** 
- Measure Phase 1 baselines at GATE-0
- Adjust GATE-2 budget based on Phase 1 + predator-prey overhead
- Add player-involved combat budget variant

### Test Isolation

| Item | Status | Impact |
|------|--------|--------|
| Wave 1 → 2 dependencies | ❌ | CRITICAL: No compatibility check |
| Wave 2 → 3 dependencies | ❌ | CRITICAL: No compatibility check |
| Wave 3 → 4 dependencies | ❌ | CRITICAL: No compatibility check |
| Wave 4 → 5 dependencies | ⚠️ | Covered at GATE-5 |

**Recommendation:** Add 3 new "readiness" tests (run at end of prior gate, verify next gate can depend on it).

### Autonomy Protocol

| Item | Status | Impact |
|------|--------|--------|
| Decision authority | ❌ | CRITICAL: Ambiguous who decides gate outcome |
| Parallel conflict resolution | ❌ | CRITICAL: No protocol for inter-team disputes |
| Emergency abort | ❌ | CRITICAL: No pivot protocol if architecture breaks |
| Portal TDD independence | ⚠️ | Unspecified if portal TDD blocks GATE-0 |

**Recommendation:**
- Document decision authority per gate
- Add conflict escalation protocol (Bart vs Nelson → Wayne decides)
- Add feature de-scope option if budget broken
- Clarify portal TDD independence

---

## 9. Marge's Recommendations (Priority Order)

### BLOCKING (Must fix before WAVE-0 launch)

1. **Add GATE-0 automation + enforcement**
   - Create `test/wave0/test-preflight.lua` (LOC guard, dir discovery, baseline regression)
   - Add git commit/tag requirement: `git commit -m "GATE-0: preflight passed" && git tag gate-0`
   - Abort WAVE-1 if GATE-0 tag missing

2. **Add cross-wave compatibility checks**
   - Create `test/creatures/test-wave1-2-integration.lua` (run after WAVE-1, before WAVE-2)
   - Create `test/combat/test-wave2-3-compat.lua` (run after WAVE-2, before WAVE-3)
   - Create `test/injuries/test-wave3-4-compat.lua` (run after GATE-3, before WAVE-4)
   - These are SAFETY CHECKS, not full tests. Can be 5-10 LOC each.

3. **Add performance baseline measurement**
   - Create `test/creatures/test-phase1-baseline.lua` (measure Phase 1 creature/combat perf)
   - Run at GATE-0
   - Use result to set realistic GATE-2 budget

4. **Add decision authority protocol**
   - Document who decides GATE pass/fail for each gate
   - Specify escalation path (unanimous PASS, any FAIL → escalate)
   - Decision authority document to `.squad/decisions/inbox/marge-gate-authority.md`

### HIGH PRIORITY (Should fix before WAVE-1 starts)

5. **Add multi-combatant seed specification**
   - Specify `math.randomseed(42)` for GATE-3 `test-multi-combatant.lua`

6. **Add performance measurement scripts**
   - `test/injuries/test-disease-delivery.lua`: Add `os.clock()` measurement
   - Document as GATE-4 pass requirement

7. **Add LLM creature flee scenario**
   - P2-E2: Creature flees successfully (GATE-3)

8. **Add LLM player intervention scenario**
   - P2-E3: Player joins active NPC combat (GATE-3)

### MEDIUM PRIORITY (Should fix before GATE-5)

9. **Add weapon on_hit structure validation (WAVE-1)**
   - Verify creature weapons have `on_hit` field structure compatible with WAVE-4

10. **Add disease verb compatibility test (GATE-4)**
    - Verify `restricts.drink` flag works even though drink verb not yet implemented

### INFORMATIONAL

- Clarify portal TDD independence in plan (reassure that portal #199-208 doesn't block GATE-0)
- Document conflict resolution for parallel WAVE-2 (Bart vs Nelson)
- Document feature de-scope option if performance budget broken mid-phase

---

## 10. Final Gate Approval

### GATE-0 (Pre-Flight)

**Status:** ⚠️ **CONDITIONAL** — Cannot pass until:
- [ ] `test/wave0/test-preflight.lua` created (automation + baseline)
- [ ] GATE-0 enforcement protocol documented (commit/tag requirement)
- [ ] Phase 1 performance baseline measured
- [ ] Decision authority protocol documented

**Estimated fix time:** 2-3 hours (Marge + Bart collaboration)

### GATES 1-5

**Status:** ⚠️ **CONDITIONAL** — Cannot pass until:
- [ ] 3 cross-wave compatibility tests added (WAVE-1/2, WAVE-2/3, WAVE-3/4)
- [ ] Performance measurement scripts added to GATE-2 and GATE-4
- [ ] 2 new LLM scenarios added to GATE-3
- [ ] Weapon structure + disease verb tests added

**Estimated fix time:** 4-5 hours (Nelson + Bart collaboration)

---

## 11. Recommendation Summary

| Finding | Severity | Recommendation |
|---------|----------|-----------------|
| GATE-0 not automated | CRITICAL | Add `test/wave0/test-preflight.lua` + enforcement |
| Cross-wave isolation poor | CRITICAL | Add 3 compatibility check files |
| Performance budgets unvalidated | CRITICAL | Measure Phase 1 baseline at GATE-0 |
| No autonomy protocol | CRITICAL | Document decision authority + escalation |
| LLM creature flee scenario missing | HIGH | Add P2-E2 |
| Multi-combatant seed unspecified | HIGH | Specify seed 42 in GATE-3 |
| Performance measurement absent | HIGH | Add `os.clock()` to GATE-2/4 tests |

---

## Attachments

**Companion documents to prepare:**
- `.squad/decisions/inbox/marge-gate-authority.md` (decision authority protocol)
- `.squad/decisions/inbox/marge-wave-conflict-protocol.md` (parallel work dispute resolution)
- `.squad/decisions/inbox/marge-performance-baseline.md` (Phase 1 perf measurements, GATE-2 adjusted budget)

---

**Signed:** Marge (QA Lead)  
**Date:** 2026-03-26T14:30:00Z  
**Status:** SUBMITTED FOR REVIEW

Next step: Wayne decides whether to proceed with GATE-0 as-is (risk acceptance) or address critical gaps first (recommended).
