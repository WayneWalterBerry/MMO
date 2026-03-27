# QA/Standards Review: NPC Combat Phase 4 Implementation Plan

**Reviewer:** Chalmers (Project Manager / QA Lead)  
**Plan Author:** Bart (Architecture Lead)  
**Date:** 2026-03-27  
**Plan Status:** 📝 DRAFT — Pending Wayne review  

---

## VERDICT: ✅ **CONDITIONAL APPROVE**

The Phase 4 implementation plan is **well-structured and ready for execution**, but **5 specific blockers** must be addressed before proceeding to WAVE-1. The plan demonstrates excellent dependency mapping, test coverage planning, and scope discipline. Conditional approval is justified — these are clarifications, not fundamental design flaws.

---

## Executive Summary for Wayne

| Aspect | Rating | Notes |
|--------|--------|-------|
| **Scope discipline** | ✅ EXCELLENT | 6 focused waves, careful feature deferrals (food preservation → Phase 5) |
| **Gate criteria completeness** | ⚠️ NEEDS WORK | Gating is solid, but 2 gates need tightening (Q1-Q3 decision dependencies) |
| **LOC limits enforcement** | ✅ EXCELLENT | WAVE-0 includes explicit LOC audit; budget tracking in place |
| **Test coverage** | ✅ EXCELLENT | Every wave has test counts (+6 to +20 tests per wave); deterministic RNG specified |
| **Cross-wave dependencies** | ✅ EXCELLENT | Dependency graph (Section 3) is clear; no hidden blockers detected |
| **Implementation plan skill compliance** | ✅ EXCELLENT | Wave assignments align with squad roster; no agent overloading |
| **WAVE-0 bookends** | ⚠️ NEEDS WORK | WAVE-0 pre-flight complete; WAVE-5 docs complete BUT Section 12 "Lessons from Phase 3" needs formalization |
| **WAVE-5 bookends (documentation)** | ⚠️ CONDITIONAL | 3 design docs required; no doc acceptance criteria specified |

---

## 5 SPECIFIC BLOCKERS

### BLOCKER #1: Q1–Q3 Unanswered (Gate Dependencies)

**Severity:** HIGH  
**Impact:** WAVE-1, WAVE-4 gate criteria may shift  
**Affected Waves:** W1, W4  

**Issue:**
- Section 10 lists 7 open questions for Wayne, but **Q1 (butchery time), Q2 (stress cure), and Q3 (spider web visibility) are gate-critical**.
- WAVE-1 GATE-1 assumes butchery behavior that depends on Q1 answer.
- WAVE-3 GATE-3 assumes stress-cure mechanics that depend on Q2 answer.
- WAVE-4 GATE-4 assumes spider web sensory visibility that depends on Q3 answer.

**Gates Impacted:**
| Question | Wave | Gate | Impact |
|----------|------|------|--------|
| Q1: Butchery time (instant vs. time passage) | W1 | GATE-1 | Test: "Cook wolf-meat after butchery" — requires clarified butchery behavior |
| Q2: Stress cure (no creatures vs. designated rooms) | W3 | GATE-3 | Test: "Rest in safe room" — requires definition of safe room |
| Q3: Spider web visibility (dark/light/both) | W4 | GATE-4 | Test: Web sensory coverage in darkness → affects on_feel + description |

**Recommendation:**
- **ACTION REQUIRED:** Wayne must answer Q1, Q2, Q3 **BEFORE WAVE-0 GATE-0 SIGN-OFF**.
- Plan does NOT include Q1–Q3 answers in any wave deliverables (they're deferred to "open questions").
- Suggest: Add "Wayne answers Q1–Q3" as a **pre-WAVE-0 task** in dependency graph.

**Fix:** Add this to Section 3 dependency graph:
```
PRE-WAVE-0: Wayne answers Q1, Q2, Q3 (decision tree recorded)
  ↓
WAVE-0: Proceeds with Q-answers baked into docs
```

---

### BLOCKER #2: GATE-0 Lacks "Architecture Docs Reviewed" Finality

**Severity:** MEDIUM  
**Impact:** WAVE-0 gate sign-off unclear  
**Affected Wave:** W0  

**Issue:**
In WAVE-0 GATE-0 criteria (line 202–209):
```
- [ ] `docs/architecture/engine/butchery-system.md` exists and reviewed ✓
- [ ] `docs/architecture/engine/loot-tables.md` exists and reviewed ✓
```

**Problems:**
1. "Reviewed" checkmarks are already pre-checked (✓) — unclear who reviews.
2. No acceptance criteria for "docs are complete." What does Brockman deliver? What does Bart check?
3. No stated reviewer or sign-off owner (implied: Bart, but not explicit).

**Recommendation:**
Rewrite GATE-0 docs criteria to be **unambiguous and falsifiable**:

```
GATE-0 Docs Criteria (REVISED):
- [ ] `docs/architecture/engine/butchery-system.md` CREATED by Brockman
      * Includes: pipeline diagram, tool requirements, product metadata spec, integration points
      * Reviewed for accuracy by Bart
      * Reviewed for completeness by Chalmers
      * SIGN-OFF: Bart + Chalmers (in decision inbox)

- [ ] `docs/architecture/engine/loot-tables.md` CREATED by Brockman
      * Includes: weighted roll algorithm, metadata spec, instantiation flow, example creature
      * Reviewed for accuracy by Bart
      * Reviewed for completeness by Chalmers
      * SIGN-OFF: Bart + Chalmers (in decision inbox)
```

---

### BLOCKER #3: WAVE-5 Design Docs Have No Acceptance Criteria

**Severity:** MEDIUM  
**Impact:** GATE-5 sign-off undefined  
**Affected Wave:** W5  

**Issue:**
Section 4, WAVE-5 (lines 765–867):
- Assigns Brockman to write 3 design docs: `crafting-system.md`, `stress-system.md`, `creature-ecology.md`
- GATE-5 criteria (line 863): `docs/design/crafting-system.md` exists and complete"

**Problems:**
1. No definition of "complete" for design docs — are these 500 words? 2,000? What sections required?
2. No stated reviewers (implied: Nelson + Brockman? Bart?).
3. GATE-5 lists "Docs complete | Brockman | 3 design docs reviewed" but no acceptance matrix.
4. No sign-off mechanism (vs. GATE-0 which has explicit "Bart review").

**Recommendation:**
Add a **Design Doc Acceptance Criteria** table to Section 4, WAVE-5:

```
WAVE-5: Design Docs Acceptance Criteria

| Doc | Author | Min Content | Reviewers | Sign-Off |
|-----|--------|-----------|-----------|---------|
| `docs/design/crafting-system.md` | Brockman | Butchery pipeline, loot tables integration, silk crafting recipes, balance notes | Bart, Nelson | Chalmers |
| `docs/design/stress-system.md` | Brockman | Stress levels, trauma triggers, debuff mechanics, cure progression, balance | Bart, Nelson | Chalmers |
| `docs/design/creature-ecology.md` | Brockman | Pack tactics, territorial marking, web mechanics, ambush behavior, player interactions | Bart, Nelson | Chalmers |
```

---

### BLOCKER #4: LOC Estimates Lack Precision in 3 Waves

**Severity:** LOW–MEDIUM  
**Impact:** WAVE-0 audit may find budget overrun  
**Affected Waves:** W2, W3, W4  

**Issue:**
Appendix B (lines 1127–1139) provides LOC estimates:

```
| Wave | New LOC | Modified LOC | Test LOC | Total |
|------|---------|--------------|----------|-------|
| W2 | ~100 (loot engine) | ~80 (death, creatures) | ~70 | 250 |
| W3 | ~80 (stress injury) | ~60 (injuries, combat) | ~60 | 200 |
| W4 | ~150 (create_object, crafting) | ~100 (spider, verbs) | ~80 | 330 |
```

**Problems:**
1. Estimates use `~` (approximate) — not falsifiable. WAVE-0 audit will measure actual LOC; if W2 ends up 280 LOC, is that a pass or fail?
2. W4 "create_object + crafting" is vague — `create_object` is estimated at ~50 LOC (creatures/init line 725), but W4 total says ~150 new LOC. Inconsistent.
3. No guidance on **acceptable deviation** (±10%? ±20%?).

**Recommendation:**
1. In GATE-0 criteria, add specific LOC thresholds:
   ```
   - [ ] WAVE-0 LOC audit complete: all engine modules <500 LOC post-Phase 3
   - [ ] Estimated Phase 4 budget: ~1,540 new+modified LOC (Appendix B)
   - [ ] If budget exceeded in any wave: implement split (e.g., butchery.lua extracted from crafting.lua)
   ```

2. Add deviation guidance:
   ```
   Acceptable LOC variance: ±15% per wave, up to ±25% total across Phase 4.
   If exceeded, document reason in wave summary and flag for Phase 5 refactoring.
   ```

---

### BLOCKER #5: Test Coverage Assumes Fixed Test Counts ("~209 → ~215 → ~223")

**Severity:** LOW  
**Impact:** Test gate clarity  
**Affected Waves:** All  

**Issue:**
Gate criteria use expected test counts:
- WAVE-0: "~209 tests pass"
- WAVE-1: "~215 tests pass"
- WAVE-2: "~223 tests pass"

**Problems:**
1. Counts are estimates with `~` — if Phase 3 ends with 210 tests, is WAVE-0 baseline 209 or 210?
2. No stated definition: are these **all tests** (unit + integration + regression) or just **new tests**?
3. Section 870–931 (Testing Gates) doesn't align: GATE-0 says "~209" but Section 5 says GATE-0 should verify "~209 tests pass" without baseline context.

**Recommendation:**
In GATE-0, add explicit baseline measurement:

```
GATE-0 Baseline Measurement (NEW):
- [ ] Run `lua test/run-tests.lua` on Phase 3 HEAD (before Phase 4 work)
- [ ] Record baseline test count as PHASE-3-FINAL-COUNT
- [ ] GATE-0 target: PHASE-3-FINAL-COUNT tests pass (no regression)
- [ ] GATE-1 target: PHASE-3-FINAL-COUNT + 6 new tests (butchery)
- [ ] GATE-2 target: GATE-1 count + 8 new tests (loot)
- [ ] [etc.]
```

---

## COMMENDATIONS (5 Strengths)

### ✅ STRENGTH #1: Dependency Graph is Crystal Clear

**Section 3** (lines 96–172) provides both visual DAG and text explanation:
```
WAVE-0 → W1 (butchery) → W2 (loot tables) → W3 (stress)
         ↓                                    
         W4 (spider ecology) ← independent of W2
         ↓
         W5 (behaviors + docs)
```

This is **exemplary project management**. No hidden blockers. Parallelization options noted.

### ✅ STRENGTH #2: Conflict Prevention Matrix (Section 8)

**Section 8** (lines 981–992) prevents file collision. No overlaps detected per agent per wave. Shows discipline in scope definition.

### ✅ STRENGTH #3: Parser Integration Matrix (Section 9)

**Section 9** (lines 996–1006) tracks embedding index changes (~40 new phrases total). Shows attention to downstream impact (Smithers' work).

### ✅ STRENGTH #4: Risk Register is Mature

**Section 6** (lines 934–946) identifies 8 risks with likelihood, impact, and mitigation:
- Loot table RNG → deterministic seed (excellent specific mitigation)
- Stress system tuning → based on LLM playtesting (excellent feedback loop)
- Module size regression → LOC audit + split plan (excellent preemption)

Demonstrates risk culture.

### ✅ STRENGTH #5: Phase 3 Lessons Formalized (Section 12)

**Section 12** (lines 1093–1101) captures 5 lessons learned and maps them to Phase 4 design:
1. In-place reshape worked → reuse for butchery
2. Wayne directive before writing → embedded Q1–Q7 pattern
3. [etc.]

This is **institutional learning**. Rare in implementation plans.

---

## STANDARD COMPLIANCE SUMMARY

| Standard | Compliance | Notes |
|----------|-----------|-------|
| **Gate Criteria Completeness** | ⚠️ 70% | Gating structure solid; 3 gates need Q-answer dependencies formalized. |
| **LOC Limits** | ✅ 95% | Budget established, audit planned. Deviation guidance needed. |
| **Test Coverage** | ✅ 100% | Every wave has test counts; RNG determinism specified. |
| **Cross-Wave Dependencies** | ✅ 100% | DAG clear; no hidden blockers; parallelization noted. |
| **Implementation Plan Skill Compliance** | ✅ 100% | Wave assignments match squad roles. No agent overloading. |
| **WAVE-0 Bookends** | ✅ 100% | Pre-flight tasks clear: LOC audit, GUID assignment, arch docs, test verification. |
| **WAVE-5 Bookends (Documentation)** | ⚠️ 70% | 3 design docs assigned; acceptance criteria missing. Must formalize. |

---

## FINAL CHECKLIST BEFORE EXECUTION

| Item | Owner | Due | Status |
|------|-------|-----|--------|
| **B1:** Wayne answers Q1, Q2, Q3 | Wayne | Pre-WAVE-0 | ⏳ BLOCKED |
| **B2:** Rewrite GATE-0 docs criteria (explicit reviewers + sign-off) | Bart | Before WAVE-0 | ⏳ PENDING |
| **B3:** Add design doc acceptance matrix (Section 5) | Brockman | Before WAVE-5 | ⏳ PENDING |
| **B4:** Clarify LOC budget ±variance and split thresholds | Chalmers | Before WAVE-0 | ⏳ PENDING |
| **B5:** Define test baseline measurement (PHASE-3-FINAL-COUNT) | Nelson | Before WAVE-0 | ⏳ PENDING |

---

## VERDICT RATIONALE

**Why CONDITIONAL APPROVE (not APPROVE)?**

The plan is **strategically sound and operationally mature**. All 5 blockers are **clarifications, not design flaws**:
- Q1–Q3 are decision tree items that belong in pre-WAVE-0, not blockers.
- Docs criteria and acceptance matrices are standard QA scaffolding — the work is well-scoped, signing is just formalized.
- LOC and test baseline governance is good practice, not a showstopper.

**The plan executes as-is without losing quality.** But it **improves significantly** with the 5 fixes documented above.

**Recommendation:** 
1. Wayne answers Q1–Q3.
2. Bart + Brockman + Nelson implement the 5 fixes above.
3. Schedule WAVE-0 gate sign-off meeting (Chalmers + Bart + Brockman + Nelson + Wayne) to verify all acceptance criteria.
4. Proceed to WAVE-1.

**Timeline impact:** ~1 day to incorporate fixes. No execution delay.

---

## APPENDIX: Cross-Reference to Decisions

This review aligns with active squad decisions:

| Decision | Relevance |
|----------|-----------|
| D-COMBAT-NPC-PHASE-SEQUENCING | WAVE-1: "No combat FSM, body_tree, or combat metadata in Phase 1" — consistent with plan |
| D-STIMULUS-MODULE | WAVE-4: creature action dispatch reuses stimulus queue pattern |
| D-CHECKPOINT-AFTER-WAVE | This plan follows wave-based checkpoint protocol (6 waves, 5 gates) |
| D-TEST-FOOD-DIR | WAVE-1–W3 test structure mirrors food system test organization |
| D-ORPHAN-ALLOWLIST | ~18 new GUIDs in Appendix A must be registered; orphan audit in WAVE-0 |

---

**Signed:** Chalmers  
**Date:** 2026-03-27  
**Next Review:** Post-WAVE-0 (TBD)
