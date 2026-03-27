# Marge Phase 4 Review — Project Management & Scope Concerns

**Author:** Marge (Test Manager)  
**Date:** 2026-08-16  
**Re:** `plans/npc-combat/npc-combat-implementation-phase4.md` (Bart, author)  
**Status:** 🔴 **CONDITIONAL APPROVE** (5 blockers, all resolvable)

---

## Executive Summary

Phase 4 plan is **well-structured and realistic**, with clear wave sequencing and no critical oversights. However, I identified **5 project management concerns** that must be resolved before WAVE-0 kickoff:

1. **Architecture docs bookends missing** (Wayne directive D-14 compliance)
2. **Wave-5 scope creep risk** (3 major features + 3 design docs)
3. **Stress system open question Q2 vague** (impacts testing strategy)
4. **Cross-wave dependency underestimated** (W2→W3 not just W1→W2)
5. **No regression gate between waves** (gate criteria silent on Phase 3 regressions)

---

## Detailed Findings

### 1. ❌ BLOCKER: Architecture Docs Bookends (Wayne Directive)

**Severity:** CRITICAL  
**Category:** Compliance (D-14 precedent)

From Marge history: D-BROCKMAN001 (Design vs Architecture Documentation Separation) and Wayne directives consistently demand:
- Architecture docs **complete in WAVE-0** before any code
- Design docs **complete in WAVE-5** after implementation

**Current Plan Status:**
- ✅ WAVE-0: Brockman creates `butchery-system.md` and `loot-tables.md` (architecture)
- ✅ WAVE-5: Brockman creates `crafting-system.md`, `stress-system.md`, `creature-ecology.md` (design)

**Issue:** Plan is **correct** but missing explicit enforcement.

**Fix Required:** Add to GATE-0 criteria:
```
- [ ] Architecture docs complete: butchery-system.md + loot-tables.md reviewed for technical accuracy
- [ ] Design docs DEFERRED to WAVE-5 (verify none created before then)
```

Add to GATE-5 criteria:
```
- [ ] Design docs complete: crafting-system.md + stress-system.md + creature-ecology.md exist
- [ ] No architecture docs modified after WAVE-0 (unless bug fix)
```

**Recommendation:** CONDITIONAL — add these lines to Section 5 (Testing Gates) and re-submit.

---

### 2. ⚠️ BLOCKER: WAVE-5 Scope Creep Risk

**Severity:** HIGH  
**Category:** Risk management

**Current WAVE-5 Load:**
- **Code:** Pack tactics engine + Territorial marking system + Ambush behavior
- **Objects:** 1 invisible marker + weapon metadata on N weapons
- **Tests:** 2 test files (~16 tests)
- **Docs:** 3 design docs (~150-200 total lines)
- **QA:** Final LLM walkthrough

**Problem:** Section 9 (Conflict Prevention Matrix) shows **zero overlap**, but that assumes no blockers. If:
- Pack tactics testing finds behavioral bugs → Bart debugging
- Weapon metadata reveal missing data fields → Smithers must retrofit
- Design docs need accuracy review → Brockman alone

...then Bart + Smithers + Brockman are **all blocked simultaneously** on a single wave.

**Recommendation:** Add to risk register (Section 6):
```
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **WAVE-5 convergence bottleneck** | Medium | High | Pre-write weapon metadata schema (S3) + prototype pack tactics (W0) + docs outline (W0) |
```

**Fix Required:** Either:
- Move pack tactics → W4 (parallel with spider webs)
- Split weapon metadata as separate preparatory task in W4
- Reduce WAVE-5 to 1-2 core behaviors, defer ambush to Phase 5

I recommend: **Weapon metadata as W4 parallel track** (Smithers, ~2 hours). Reduces W5 to Bart (pack + territorial) + Nelson (tests + LLM) + Brockman (docs).

---

### 3. ❌ BLOCKER: Stress System Q2 — Safe Room Definition Vague

**Severity:** MEDIUM-HIGH  
**Category:** Test strategy impact

**Current Q2 (Section 10):**
```
Recommendation: Option A (no creatures). Simple, consistent with current ecosystem.
```

**Problem:** This is **Bart's recommendation**, not a decision. Open questions should have **explicit acceptance by Wayne**, not agent recommendations. For testing, Nelson needs clarity **before** writing tests.

**Why It Matters:**
- **Option A (no creatures):** Nelson tests "empty room" → cure works
- **Option B (no hostile creatures):** Nelson tests "room with passive creature" → different fixture setup
- **Option C (designated safe rooms):** Nelson tests specific metadata → different object definitions

**Impact:** If Nelson writes tests for Option A, then Wayne selects Option C, **all stress tests fail/need rewrite**.

**Fix Required:** Change Q2 language:
```
Q2: Stress Cure — Safe Room Definition

REQUIRED DECISION FROM WAYNE (blocks Nelson test writing):
- A: No creatures
- B: No hostile creatures  
- C: Designated safe rooms (metadata required)

Recommendation: Option A (simplest, no new metadata).
```

**Recommendation:** CONDITIONAL — Wayne must answer Q1-Q7 explicitly in decisions inbox before WAVE-0 kickoff.

---

### 4. ⚠️ BLOCKER: Cross-Wave Dependency Underestimated

**Severity:** MEDIUM  
**Category:** Risk register incomplete

**Current Dependency Graph (Section 3):**
```
WAVE-1 ──→ WAVE-2 ──→ WAVE-3 ──→ (W4, W5 parallel)
```

**Problem:** This is **code dependency correct**, but **test dependency incomplete**.

**Test Dependencies Not Documented:**
- W2 (loot tables) must be tested with **varied creature drops** (GATE-2 criterion: "10 kills match probability")
- W3 (stress) must test **stress from loot variety** (e.g., "witness different loot drops trigger stress?"
- W4 (webs) depends on spider creature behavior being stable (needs W2 + W3 stable first)

**Example Problem Scenario:**
- W1 ships: butchery works ✅
- W2 ships: loot tables roll correctly ✅
- W3 starts: "test stress infliction from witnessing death"
- W3 discovers: loot table RNG makes stress tests flaky (W2 wasn't mature enough)
- Result: W3 blocked on W2 re-stabilization

**Fix Required:** Add to Section 3:
```
### Test Stability Chain

W1 → W2 (code ready)
W2 → W3 (10+ test iterations for RNG stability) ← critical path
W3 → W4 (behavior stable before spider placement)
W4 → W5 (all subsystems green before pack tactics testing)
```

Also update GATE-2 criteria to include:
```
- [ ] Deterministic seed loot tests verified (math.randomseed(42) consistency)
- [ ] No flaky test reruns (100% pass rate on 3 runs)
```

**Recommendation:** CONDITIONAL — update Section 3 dependency graph + add flakiness gate criteria.

---

### 5. ⚠️ BLOCKER: No Regression Gate Between Waves

**Severity:** MEDIUM  
**Category:** Quality gate gaps

**Current Plan (Section 5 — Testing Gates):**
- GATE-0 through GATE-5 each verify new functionality
- **Missing:** No gate verifies Phase 3 still works

**Problem:** If W1 implementation accidentally breaks existing wolf combat:
- W1 GATE-1 passes (butchery works)
- W2 ships: loot tables work
- W3 ships: stress infliction works
- W4 testing discovers: "wait, wolf combat broken since W1"
- Result: 3 waves of work built on broken foundation

**Example Real Risk:** Wolf creatures live in Cellar. WAVE-0 GUID assignment adds new injury types. Injury manifest can change spawn behavior. No test catches it until W5.

**Fix Required:** Add to GATE-0 criteria:
```
- [ ] Regression test suite: `lua test/run-tests.lua --phase-3` (verify Phase 3 completion tests still pass)
```

Update each wave's gate to include:
```
- [ ] No regressions in Phase 3 tests (0 new failures vs baseline from GATE-0)
```

**Recommendation:** CONDITIONAL — add regression baseline to GATE-0, then check against all subsequent gates.

---

## Strengths of the Plan

1. ✅ **Wave sequencing is sound** — dependency chain makes sense (butchery → loot tables → stress → ecology)
2. ✅ **Agent assignments are non-overlapping** — Conflict Prevention Matrix (Section 8) shows zero file collisions
3. ✅ **Open questions are actionable** — Q1-Q7 are genuine design decisions, not vague speculation
4. ✅ **Gate criteria are testable** — GATE-0 through GATE-5 criteria are specific and measurable
5. ✅ **Risk register is realistic** — 8 identified risks with mitigation (RNG flakiness, stress tuning, module bloat, etc.)

---

## Scope Creep Warning

**What's NOT in Phase 4 (deferred to Phase 5):**
- Food preservation (salting, smoking, drying)
- Wrestling/grapple
- Environmental combat (push, slam)
- Weapon/armor degradation
- Humanoid NPCs
- Multi-ingredient cooking
- A* pathfinding

**Verdict:** **Good deferment**. Phase 4 stays focused on the crafting loop (kill → process → craft → use). Phase 5 can then expand with preservation and combat depth.

---

## Recommendation: CONDITIONAL APPROVE

**Release to WAVE-0 only if:**

1. ✅ Wayne answers Q1-Q7 explicitly in `.squad/decisions/inbox/wayne-phase4-questions.md`
2. ✅ Add regression gate baseline to GATE-0 (Phase 3 tests as control)
3. ✅ Update Section 3 dependency graph with test stability chain
4. ✅ Update Section 6 Risk Register: add WAVE-5 convergence bottleneck + mitigation
5. ✅ Add explicit Wayne decision requirement to Q2 (safe room definition)

**After fixes:** Plan is **APPROVED FOR EXECUTION**. Wave sequencing is sound, scope is realistic, and agent assignments avoid conflicts.

---

## Quality Gate Checklist for Marge

Before each wave kicks off, I will verify:

- [ ] **WAVE-0 Kickoff:** Wayne's Q1-Q7 answers in decisions inbox + regression baseline documented
- [ ] **WAVE-1 Kickoff:** Butcher verb aliases added to embedding index before Smithers codes
- [ ] **WAVE-2 Kickoff:** Deterministic seed policy enforced (math.randomseed(42) in all loot tests)
- [ ] **WAVE-3 Kickoff:** Stress test fixture matches Q2 decision (safe room definition locked)
- [ ] **WAVE-4 Kickoff:** Weapon metadata schema reviewed by Smithers before Flanders codes spider
- [ ] **WAVE-5 Kickoff:** Pack tactics prototype verified by Bart (no surprise blockers)
- [ ] **GATE-5 Sign-Off:** All Phase 3 regression tests green + Phase 4 completion criteria met

---

## Impact Summary

| Stakeholder | Impact | Action |
|-------------|--------|--------|
| **Wayne** | Decisions needed on Q1-Q7 | Answer in decision inbox before WAVE-0 |
| **Bart** | W5 convergence risk | Consider moving weapon metadata to W4 |
| **Flanders** | No direct impact | Proceed with object definitions as planned |
| **Smithers** | W5 weapon metadata prep | Pre-write schema, review with Bart in W4 |
| **Moe** | No impact (W4 only) | Cellar placement unchanged |
| **Nelson** | Test infrastructure | Add regression baseline script, deterministic seed policy |
| **Brockman** | Docs bookends strict | Architecture docs WAVE-0, design docs WAVE-5 only |

---

## Next Steps

1. **Marge sends this to Wayne** for Q1-Q7 answers
2. **Bart updates plan** with fixes #2-5 above
3. **Marge re-reviews** updated plan → FULL APPROVE
4. **Scribe merges** Phase 4 plan and Wayne decision as canonical
5. **WAVE-0 kicks off** with clear dependencies and regression baseline

---

*Report by Marge — Test Manager*  
*Sent: 2026-08-16*  
*Next checkpoint: Post-Wayne decision review*
