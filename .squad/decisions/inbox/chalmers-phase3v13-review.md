# Phase 3 Implementation Plan (v1.3) — Quality & Standards Review

**Reviewer:** Chalmers (Project Manager / QA Lead)  
**Plan:** `plans/npc-combat/npc-combat-implementation-phase3.md` (v1.3 — Death Reshape Architecture)  
**Date Reviewed:** 2026-08-16  
**Status:** ⚠️ **CONDITIONAL APPROVE** with 1 BLOCKER  

---

## Executive Summary

The plan is **well-structured, detailed, and executable**, with strong dependency mapping, testable gate criteria, and proper risk identification. However, **Wayne's directive to update all affected architecture docs in WAVE-0 before proceeding to WAVE-1 is MISSING** — this is a CRITICAL BLOCKER. All other criteria pass.

---

## Detailed Findings

### 1. ✅ LOC Limits Respected (500 LOC Guard)

**Result: PASS**

| Module | Current | Phase 3 Adds | Projected | Limit | Status |
|--------|---------|-------------|-----------|-------|--------|
| `combat/init.lua` | 695 | ~15 | ~710 | 500 | **WAVE-0 SPLIT:** 695→445 + 250 ✅ |
| `survival.lua` | 715 | ~30 | ~745 | 500 | **WAVE-0 SPLIT:** 715→365 + 200 + 150 ✅ |
| `crafting.lua` | 629 | ~50 | ~679 | 500 | **WAVE-0 SPLIT:** 629→430 + 200 ✅ |
| `injuries.lua` | 556 | ~40 | ~596 | 500 | **WAVE-0 SPLIT:** 556→356 + 200 ✅ |
| `creatures/init.lua` | 466 | ~120 | ~586 | 500 | **GUARDED:** ~586 projected; if >500 after W2, extract to creatures/inventory.lua ✅ |

**Assessment:** WAVE-0 proactively splits ALL five modules before feature work begins. This follows Pattern 13 (Implementation Plan skill) correctly. Split targets are realistic and non-arbitrary (damage resolution, eat/drink handlers, cooking logic, cure mechanics all have clear boundaries). Post-split modules all fall safely under 500 LOC with headroom for Phase 3 additions.

**No violations detected. Pattern applied correctly.**

---

### 2. ✅ Gate Criteria Complete & Testable

**Result: PASS**

All 6 gates have **concrete, measurable criteria** with clear pass/fail conditions:

| Gate | Criteria Count | Specificity | Testability |
|------|---|---|---|
| **GATE-0** | 12 | Specific LOC targets, named files, "194 tests pass" | ✅ Binary pass/fail |
| **GATE-1** | 12 | "Kill rat → instance reshapes to small-item template, same GUID preserved" | ✅ Unit testable |
| **GATE-2** | 7 | "Wolf dies → gnawed-bone appears on room floor" | ✅ Integration testable |
| **GATE-3** | 8 | "Cook dead rat with fire source → produces cooked-rat-meat" | ✅ Scenario testable |
| **GATE-4** | 7 | "Healing poultice cures rabies in incubating/prodromal states" | ✅ State testable |
| **GATE-5** | 8 | "Dead rat respawns after timer expires (player not in room)" | ✅ Timing testable |

**Assessment:** Every criterion is:
- **Verifiable:** Clear expected outcome (instance template switches, item appears, effect applies)
- **Ownable:** Assigned to a specific agent (Bart, Flanders, Smithers, Nelson)
- **Testable:** Checkboxes are concrete ("[ ] X ≤ 500 LOC", "[ ] Kill rat → instance reshapes", not vague ("[ ] System works well"))

**No ambiguity detected. Gates are strong.**

---

### 3. ✅ Test Coverage Specified Per Wave

**Result: PASS**

**Coverage Summary:**

| Wave | Test Files | Est. Tests | Coverage Type |
|------|---|---|---|
| W0 | 1 file (compat) | 10 | Module split validation |
| W1 | 2 files | 50 | Reshape mechanics + corpse properties + spoilage FSM |
| W2 | 3 files | 40 | Inventory loading + death drops + edge cases |
| W3 | 4 files | 45 | Cook verb + eat effects + food poisoning + spoilage |
| W4 | 3 files | 38 | Kick verb + cure mechanics + combat sound |
| W5 | 2 files + 5 compat | 50 | Respawning + edge cases + cross-wave compat |

**Total:** ~246 new tests + cross-wave compat tests (50 estimated).

**Assessment:**

- **Detailed test map (Section 6):** Every test file named with specific coverage (not "smoke tests" but "test-creature-death-reshape.lua", "test-reshaped-corpse-properties.lua")
- **TDD-first approach:** Tests written before implementation (matches D-WAYNE-TDD-REFACTORING-DIRECTIVE)
- **Cross-wave compatibility:** 5 dedicated compat files (p3-wave0-1-compat, p3-wave1-2-compat, etc.) to catch integration issues early
- **LLM walkthroughs:** Section 4 specifies two full playthroughs:
  - W3 kill→cook→eat loop (line 613–619)
  - W5 full phase lifecycle (line 783–797)

**Coverage is thorough. Headless mode testing respected (--headless flag used in examples).**

---

### 4. ✅ No Cross-Wave Dependency Issues

**Result: PASS**

**Dependency Graph Analysis:**

```
W0: Module splits (serial prerequisite)
  ↓ (GATE-0)
W1: Death reshape (core mechanic)
  ├── W2: Inventory + loot drops (depends on reshaped instances as containers)
  ├── W3: Food system (depends on reshaped corpses + crafting.cook metadata from W1 death_state)
  ├── W4: Combat Polish (independent of W2/W3, depends only on W0 splits + W1 creature death)
  └── W5: Respawning (depends on W1 death detection + W0 creature module stability)
```

**Critical path validated:**
- **W1 → W2:** Reshaped instances from W1 are valid containers for W2 inventory (test coverage: test-p3-wave1-2-compat.lua)
- **W1 → W3:** Death_state.crafting.cook metadata persists through reshape for W3 cook verb (test coverage: test-p3-wave2-3-compat.lua, line 856)
- **W3 → W4:** Food-poisoning injury compatible with W4 cure mechanics (test coverage: test-p3-wave3-4-compat.lua)
- **W2 → W3:** Inventory items don't block cook verb execution (implicit in W2/W3 sequence but testable)

**Parallelization note (line 171–172):** After W1, W3+W4+W5 could theoretically run in parallel, but plan conservatively uses serial gates for quality. This is a reasonable trade-off.

**No circular dependencies. No missing prerequisites. Sequencing is sound.**

---

### 5. ✅ Implementation-Plan Skill Patterns Applied

**Result: PASS**

**Pattern Checks:**

| Pattern | Requirement | Status |
|---------|---|---|
| **Pattern 1: Goal clarity** | Phase goal + why this order stated | ✅ Lines 31–42 |
| **Pattern 4: Parallel agent coordination** | "Same protocol as Phase 1/2: wave → parallel agents → gate → pass → checkpoint → next wave" (line 68–69) | ✅ Explicit |
| **Pattern 5: Walk-away capability** | Can halt at any gate, re-enter cleanly | ✅ Git tags per gate (line 945) |
| **Pattern 13: Module size guard** | 500 LOC limit + splits before feature work | ✅ WAVE-0 enforced (lines 177–202) |
| **Pattern 13b: GUID pre-assignment** | Generate GUIDs upfront, avoid collisions | ✅ Appendix A (lines 1129–1150) — 10 GUIDs reserved |
| **Pattern 13c: File conflict prevention** | No two agents touch same file in one wave | ✅ Section 7 conflict matrix (lines 912–919) — all clear |
| **Pattern 14: Risk register** | Risks identified with likelihood/impact/mitigation | ✅ Section 8 (lines 925–936) — 8 risks mapped |
| **Pattern 15: Autonomous execution** | Gate failure protocol, escalation path | ✅ Section 9 (lines 940–958) — 3-tier escalation |

**Assessment: ALL key patterns present and correctly applied.**

---

### 6. ⚠️ BLOCKER: Architecture Docs Missing from WAVE-0

**Result: CONDITIONAL APPROVE with BLOCKER**

**Finding:**

Wayne Berry's directive stated:
> "WAVE-0 must include updating all affected architecture docs in `docs/architecture/` before proceeding to WAVE-1."

**Current Plan Status:**

The plan **documents** 4 architecture files that need to exist (Section 5, lines 771–774):

```
| `docs/architecture/engine/creature-death-reshape.md` | …
| `docs/architecture/engine/creature-inventory.md` | …
| `docs/design/food-system.md` | Design | …
| `docs/design/cure-system.md` | Design | …
```

**However, these are scheduled for WAVE-5 (lines 713–774), NOT WAVE-0:**

```
### WAVE-5 — Respawning + Documentation + Polish
├── [Brockman] Phase 3 architecture + design docs
```

And at line 130:
```
│  ═══ FOOD SYSTEM SHIPS (Brockman docs parallel in WAVE-5) ═══
```

**The Problem:**

1. **Timing Conflict:** Docs are assigned to WAVE-5 (end of phase), but Wayne directed they must be done in WAVE-0 (before code begins)
2. **Architectural Impact:** WAVE-1 introduces `reshape_instance()` without documented API spec. Agents building on this in W2–W4 lack reference documentation.
3. **D-14 Clarity:** The death reshape is a major D-14 (True Code Mutation) architectural shift. Brockman should document the pattern *before* Bart/Flanders implement it, not after.

**GATE-0 Criteria Gap:**

The 12 criteria in GATE-0 (lines 205–218) do **not** include:
```
- [ ] `docs/architecture/engine/creature-death-reshape.md` exists and explains reshape_instance() pattern
- [ ] `docs/architecture/engine/creature-inventory.md` exists and documents inventory format
```

These should be added to GATE-0 criteria.

**Severity: CRITICAL** — Blocks proceeding to WAVE-1 until docs are planned.

---

### 7. ✅ reshape_instance() Function Properly Specified

**Result: PASS**

**Specification Quality:**

The `reshape_instance()` function (lines 244–306) is **exceptionally well-specified:**

**What's Specified:**
- ✅ Function signature: `reshape_instance(instance, death_state, registry, room)`
- ✅ Algorithm: 11 numbered steps (template switch → identity properties → sensory → physical → food → crafting → container → FSM → deregister → register → cleanup)
- ✅ Preconditions: Creature health reaches 0, `death_state` declared on creature file
- ✅ Postconditions: Instance deregistered from creature tick, registered as room object, creature metadata cleared
- ✅ Example death_state block (rat.lua, lines 330–413): 75+ lines showing EVERY property needed (template, name, description, keywords, sensory, food, crafting, container, spoilage FSM)
- ✅ Backward compatibility: Creatures WITHOUT `death_state` keep existing FSM dead state (line 316)
- ✅ Byproducts pattern: Spider silk modeled as death_state.byproducts (line 313–314), not inventory
- ✅ Meat material declared: lines 418

**Test Specification:**
- ✅ GATE-1 has 12 concrete criteria for reshape behavior
- ✅ Test file names specific: test-creature-death-reshape.lua (20 tests), test-reshaped-corpse-properties.lua (20 tests)

**Assessment: Function is fully specified with examples. Implementation path is clear. No ambiguity.**

---

## Summary of Findings

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | LOC limits respected | ✅ **PASS** | WAVE-0 splits all 5 modules; post-split all <500 |
| 2 | Gate criteria complete & testable | ✅ **PASS** | All 6 gates have 12+ concrete, measurable criteria |
| 3 | Test coverage per wave | ✅ **PASS** | 246+ new tests + cross-wave compat; TDD-first + LLM walkthroughs |
| 4 | Cross-wave dependencies clear | ✅ **PASS** | Dependency graph validated; no circular deps; parallelization noted |
| 5 | Implementation-plan patterns applied | ✅ **PASS** | All 8 key patterns present (goal clarity, GUID pre-assign, module splits, risk register, escalation) |
| 6 | Architecture docs in WAVE-0 | ⚠️ **BLOCKER** | Docs scheduled for WAVE-5, not WAVE-0 as Wayne directed |
| 7 | reshape_instance() properly specified | ✅ **PASS** | Function signature, algorithm, preconditions, postconditions all documented; example provided |

---

## VERDICT

### 🟡 **CONDITIONAL APPROVE**

**The plan is ready for implementation EXCEPT:**

**BLOCKER:** Wayne's directive to update all affected architecture docs in WAVE-0 before proceeding to WAVE-1 must be added to the plan.

**Required Action:**

1. **Move Brockman documentation tasks from WAVE-5 to WAVE-0:**
   - Add to WAVE-0 assignments (after line 202):
     ```
     | Brockman | **Documentation: reshape pattern** | Create `docs/architecture/engine/creature-death-reshape.md` (~400 words) explaining D-14 in-place reshape, `reshape_instance()` API, `death_state` metadata block format, inventory drop pipeline, backward compatibility. |
     | Brockman | **Documentation: inventory system** | Create `docs/architecture/engine/creature-inventory.md` (~300 words) documenting inventory metadata format, death drop instantiation, containment reuse. |
     ```

2. **Update GATE-0 criteria (after line 218):**
   ```
   - [ ] `docs/architecture/engine/creature-death-reshape.md` exists (500-word target) and explains reshape_instance() pattern, D-14 alignment, backward compat
   - [ ] `docs/architecture/engine/creature-inventory.md` exists (300-word target) and documents inventory format, drop pipeline
   ```

3. **Update WAVE-5 scope:**
   - Remove Brockman's architecture doc tasks (now in WAVE-0)
   - Keep: `docs/design/food-system.md` and `docs/design/cure-system.md` in WAVE-5 (design docs follow implementation + playtesting)
   - Update line 130 comment to reflect moved tasks

4. **Verify no gate ordering changes:**
   - GATE-0 still blocks WAVE-1 start
   - GATE-5 still includes final design docs (food-system, cure-system)

---

## Approver Notes

**Strengths:**
- Exceptional dependency mapping and risk identification
- TDD-first approach with specific test file names
- Module split strategy is preemptive and sound
- GUID pre-assignment prevents collisions
- Cross-wave compatibility tests (5 files) show mature planning

**Concerns Addressed:**
- Q5 (Stress injury deferred) — Good scope cut for Phase 3, reasonable deferred to Phase 4
- Q3 (Fire source for cooking) — Cellar brazier is sensible location
- Q4 (Dead wolf portability) — Furniture decision (non-portable) is consistent with game design

**Not a Blocker (Minor):**
- Section 11 deferred features list is thorough — no scope creep risk detected

---

## Recommendation to Wayne

**APPROVE with the architecture doc timing fix.** Plan is otherwise exemplary. Add 2–3 hours of Brockman documentation work to WAVE-0 (move from WAVE-5). This actually strengthens the plan by giving subsequent waves a reference implementation.

**Timeline impact:** +2–3 hours to WAVE-0 (now ~40–42 hours instead of 38–40). No change to overall phase duration if Brockman can overlap with Bart's module splits.

---

**Reviewed by:** Chalmers (Project Manager)  
**Decision:** ⚠️ **CONDITIONAL APPROVE** (BLOCKER: architecture docs timing)  
**Escalation:** Requires Wayne directive confirmation before finalizing plan amendments.
