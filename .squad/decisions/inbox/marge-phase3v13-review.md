# Marge — Phase 3 v1.3 Implementation Plan Review

**Reviewer:** Marge (Test Manager)  
**Plan:** `plans/npc-combat/npc-combat-implementation-phase3.md` (v1.3)  
**Date:** 2026-03-27  
**Scope:** Death reshape architecture, creature lifecycle, food system, combat polish, respawning  

---

## Executive Summary

**VERDICT: CONDITIONAL APPROVE**

The Phase 3 v1.3 plan is well-structured, dependency-sound, and follows the implementation-plan skill format correctly. The major architecture shift (in-place death reshape replacing separate dead-creature files) is a stronger D-14 pattern and is backward-compatible. All QA gates are properly specified. However, **WAVE-0 is missing the mandatory architecture documentation requirement** that Wayne directed. This must be added as a blocker before wave execution begins.

---

## Review Findings

### ✅ 1. Wave Ordering Given Reshape Architecture

**Status:** APPROVED

The 6-wave serial dependency chain is correct for the new reshape architecture:

- **WAVE-0:** Module splits before adding 120+ LOC across Phase 3
- **WAVE-1:** Death reshape happens first (foundation for everything downstream)
- **WAVE-2:** Inventory metadata + death drops (depends on W1 reshaped instances being valid containers)
- **WAVE-3:** Cook→eat loop (depends on W1 corpse instances having `crafting.cook` metadata)
- **WAVE-4:** Cure + combat polish (independent of food/inventory, depends on W0 split stability)
- **WAVE-5:** Respawning + docs (integration/polish, depends on all prior waves)

The async potential (W3+W4 parallel after W2) is noted but conservative serial approach is justified. Parallelization note is helpful for schedule flexibility.

**Key strength:** D-14 principle is stronger in v1.3 than v1.2 — the creature code literally contains both living and dead states. No separate dead-creature files = fewer files to mutate, same GUID through reshape = cleaner identity tracking.

---

### ✅ 2. Agent Assignments — Clear & Non-Overlapping

**Status:** APPROVED

Section 7 (File Ownership Summary) demonstrates zero file conflicts:

| Wave | Bart | Flanders | Smithers | Nelson |
|------|------|----------|----------|--------|
| W0 | Module splits (all engine) | — | — | Test runner |
| W1 | reshape_instance() | death_state blocks | embedding index | Creature death tests |
| W2 | Inventory processing | Creature updates + new objects | embedding index | Inventory tests |
| W3 | — | Food objects + injury | Cook verb + effects + synonyms | Food tests + LLM walkthrough |
| W4 | Cure + sound (engine/injuries + combat/init) | Cure metadata + injury updates + antidote | Kick alias | Combat tests |
| W5 | Respawn engine | Respawn metadata | Weapon metadata + embedding | Respawn tests + LLM walkthrough |

**Ownership matrix is explicit.** Wave 4 clarification (Bart owns combat sound from `src/engine/**` per routing.md, Smithers owns kick alias) is clear. Embedding index updates properly track through all waves as a parallel Smithers responsibility.

---

### ✅ 3. Cross-Wave Compatibility Tests Specified

**Status:** APPROVED

Section 6 defines **5 explicit compatibility tests** between consecutive wave pairs:

1. `test-p3-wave0-1-compat.lua` — Module splits preserve creature death, eat handler flow
2. `test-p3-wave1-2-compat.lua` — Reshaped corpse instances are valid containers for inventory
3. `test-p3-wave2-3-compat.lua` — Reshaped instances carry `crafting.cook` metadata for W3 cook verb
4. `test-p3-wave3-4-compat.lua` — Food-poisoning injury compatible with W4 cure pipeline
5. `test-p3-wave4-5-compat.lua` — Cured creatures work with W5 respawn system

This pattern (wave N + wave N+1 compatibility explicit) was established in Phase 2 and is re-applied correctly. Each test validates the **seam** between waves — not just individual wave completion, but also the pipeline continuity.

---

### ✅ 4. Scope Containment — No Creep

**Status:** APPROVED

Section 11 explicitly defers 12 Phase 4 features:

- Loot tables (complexity justified for Phase 4 with 20+ creatures)
- Butcher verb (only needed for medium+ corpses)
- Pack tactics / Wrestling / Environmental combat
- Weapon/armor degradation
- Humanoid NPCs
- Spider web creation
- Lycanthropy
- Multi-ingredient cooking
- Food preservation
- Creature-to-creature looting
- **Stress injury** (Q5 decision: explicitly removed from Phase 3 scope)

Stress removal from Phase 3 (Q5 decision) is the clearest scope protection. Rather than shipping a half-baked stress system, Phase 3 focuses on **death + food + cure + respawn + combat polish (kick + sound propagation)**. This is tight and defensible.

**Risk register** (Section 8) documents 8 risks with mitigation. No unmitigated show-stoppers.

---

### ⚠️ 5. Open Questions Resolution Status

**Status:** MOSTLY RESOLVED — 1 MINOR TBD

| Q# | Question | Resolution | Status |
|----|----------|-----------|--------|
| Q1 | Corpse as container vs. scatter? | Option B: Corpse is searchable container | ✅ RESOLVED |
| Q2 | Respawn: timer vs. event-based? | Custom: Per-creature metadata (timers) | ✅ RESOLVED |
| Q3 | Fire source for cooking in Level 1? | Option B: Cellar brazier (new object) | ✅ RESOLVED |
| Q4 | Dead wolf portable or furniture? | Option B: Furniture (not portable) | ✅ RESOLVED |
| Q5 | Stress injury complexity? | Option C: DEFERRED to Phase 4 | ✅ RESOLVED |
| Q6 | Loot tables? | Option A: Fixed inventory only (Phase 4 for RNG) | ✅ RESOLVED |

**Minor TBD remaining:** Antidote object placement (line 679): `Placed in Level 1 (location TBD by Moe — study shelf or cellar cabinet)`. This is non-blocking — Moe's room layout decision can follow GATE-1 completion. Not a blocker for wave execution.

All 6 open questions have Wayne's explicit decisions documented. No ambiguity.

---

### ✅ 6. Implementation-Plan Skill Format

**Status:** APPROVED WITH DISTINCTION

This plan follows the skill format correctly:

- ✅ Executive summary (Section 1: context + build scope)
- ✅ Quick reference table (Section 2)
- ✅ Dependency graph with ASCII art (Section 3)
- ✅ Detailed wave breakdown (Section 4: assignments, gate criteria, tests)
- ✅ Testing gates summary (Section 5)
- ✅ TDD test file map (Section 6)
- ✅ File ownership matrix (Section 7)
- ✅ Risk register (Section 8)
- ✅ Autonomous execution protocol (Section 9)
- ✅ Open questions with resolutions (Section 10)
- ✅ Deliberate deferrals (Section 11)
- ✅ Lessons learned (Section 12)
- ✅ GUID reservation table (Appendix A)
- ✅ Parser integration matrix (Appendix B)

**Craft quality:** High. The plan is readable, modular, and internally cross-referenced. Wave 1 `reshape_instance()` pseudocode (lines 241-306) is implementation-ready. Creature file examples (rat.lua death_state block, lines 334-413) are concrete and detailed.

---

## 🚨 BLOCKER FOUND: Architecture Docs Not in WAVE-0

**SEVERITY:** BLOCKING  
**REQUIREMENT:** Wayne directive (2026-03-27): "WAVE-0 must include updating all affected architecture docs in `docs/architecture/` **before proceeding to WAVE-1**"

**Current plan status:**

- **WAVE-5 includes 4 doc files** (Section 4, WAVE-5 breakdown, lines 767-774):
  - `docs/architecture/engine/creature-death-reshape.md`
  - `docs/architecture/engine/creature-inventory.md`
  - `docs/design/food-system.md`
  - `docs/design/cure-system.md`

- **WAVE-0 is NOT documented as including architecture doc updates**
  - WAVE-0 tasks (lines 193-203): module splits, GUID pre-assignment, test verification
  - GATE-0 criteria (lines 205-218): no mention of architecture doc review/updates

**The directive says:** Architecture docs must be reviewed/updated BEFORE WAVE-1 ("before proceeding to WAVE-1").  
**The plan says:** Docs are delivered in WAVE-5 (after respawning).

This is a sequencing mismatch. Wayne's intent (based on the directive) appears to be:
1. WAVE-0 audits existing architecture docs
2. Updates them to reflect the new reshape design before code implementation
3. THEN WAVE-1 proceeds with implementation against documented architecture

Currently, WAVE-0 is pure code refactoring. The docs are deferred to integration time (WAVE-5).

---

## Recommendations

### Must Implement (BLOCKING)

**Add to WAVE-0 assignments:**

1. **[Brockman] Architecture doc review + draft updates** (~2-3 hours)
   - Review existing docs in `docs/architecture/engine/` and `docs/architecture/objects/`
   - Identify sections affected by v1.3 reshape architecture:
     - D-14 (Prime Directive) — note stronger pattern in v1.3
     - Object lifecycle — creature death now reshapes in-place, not file-swap
     - Mutation system — `reshape_instance()` distinction from `mutation.mutate()`
   - Draft updates to clarify reshape vs. file-swap mutation
   - Flag for Bart review if architecture changes needed

2. **[Bart] Architecture review** (reviewer role, 30 min)
   - Review Brockman's draft doc updates
   - Ensure they're accurate pre-implementation
   - Sign off that WAVE-1 code will match documented architecture

3. **Add to GATE-0 criteria:**
   - [ ] Brockman: `docs/architecture/engine/creature-death-reshape.md` drafted or existing docs updated to explain in-place reshape vs. file swap
   - [ ] Bart reviewed architecture doc draft for accuracy
   - [ ] No implementation gaps between doc and planned code

**Rationale:** Documenting before implementing ensures code matches architecture. This is especially critical for D-14 — the "creature code literally transforms" pattern needs to be documented clearly to prevent confusion with existing file-swap mutations. WAVE-1 should implement against a documented specification, not discover it exists during code review.

### Should Implement (Quality Enhancement)

1. **Cellar brazier placement decision** — Assign to Moe with a decision deadline before WAVE-3 (cooking verb needs a fire source). Not blocking WAVE-0/1/2, but needed before cook verb testing.

2. **Test coverage projection confidence** — Total estimate is ~437 tests by GATE-5 (up from 194 current). This is a 126% increase. Recommend Nelson flag any test file that doesn't materialize as planned so gate criteria can adapt.

---

## Gate Readiness Assessment

| Gate | Readiness | Notes |
|------|-----------|-------|
| **GATE-0** | ⏳ PENDING | Blocked until architecture docs added to WAVE-0 scope. Once added, GATE-0 is ready (splits + docs + tests). |
| **GATE-1** | ✅ READY | reshape_instance() function and death_state blocks are clearly specified. Creature death tests cover all 5 creatures + byproducts. |
| **GATE-2** | ✅ READY | Inventory + drop mechanics clearly defined. Meta-lint rules specified (INV-01 through INV-04). |
| **GATE-3** | ✅ READY | Cook verb, eat effects, spoilage FSM all detailed. LLM walkthrough specified. |
| **GATE-4** | ✅ READY | Kick alias, cure mechanics, combat sound propagation, weapon metadata all specified. |
| **GATE-5** | ✅ READY | Respawn engine, respawn metadata per creature, weapon integration all specified. Final LLM walkthrough specified. |

---

## Detailed Compliance Checklist

### Focus Area 1: Wave Ordering ✅
- [x] Strict dependency chain (W0 → W1 → W2 → W3 → W4 → W5)
- [x] Dependencies documented in ASCII graph
- [x] Parallelization constraints noted
- [x] Reshape architecture justifies this order

### Focus Area 2: Agent Assignments ✅
- [x] No two agents assigned same file in same wave
- [x] Ownership matrix explicit (Table Section 7)
- [x] Cross-wave coordination (embedding index tracked through all waves)
- [x] Nelson role clear (testing + LLM walkthroughs)

### Focus Area 3: Cross-Wave Compatibility ✅
- [x] 5 compatibility tests between wave pairs (Section 6)
- [x] Each test validates seam between waves
- [x] Follows Phase 2 pattern established
- [x] Explicit in TDD test file map

### Focus Area 4: Scope Containment ✅
- [x] 12 Phase 4 deferrals documented (Section 11)
- [x] Stress injury explicitly removed (Q5 decision)
- [x] Loot tables deferred (justified for 20+ creatures in Phase 4)
- [x] Risk register with mitigation

### Focus Area 5: Open Questions ✅
- [x] All 6 questions have Wayne's explicit decisions
- [x] Decisions documented with rationale
- [x] Q5 (stress) removal from scope is crystal clear
- [x] Only minor TBD remaining (Moe's antidote placement, non-blocking)

### Focus Area 6: Implementation-Plan Format ✅
- [x] Executive summary
- [x] Quick reference
- [x] Dependency graph
- [x] Detailed waves with assignments + criteria
- [x] Testing gates + test map
- [x] File ownership
- [x] Risk register
- [x] Execution protocol
- [x] Appendices (GUIDs, parser integration)

### 🚨 BLOCKER: Architecture Docs ❌
- [ ] WAVE-0 includes architecture doc review/updates (MISSING)
- [ ] GATE-0 criteria mention docs (MISSING)
- [ ] Architecture docs drafted before WAVE-1 implementation (MISSING)

---

## Final Verdict

**CONDITIONAL APPROVE — GATE-0 BLOCKED ON ARCHITECTURE DOCS**

The plan is excellent and ready to execute **after** WAVE-0 is expanded to include architecture documentation review and draft updates. The blocker is addressable in 2-3 hours of Brockman's time + 30 minutes of Bart review.

**If blocker is resolved:** APPROVE for full execution.  
**If blocker is deferred:** REJECT (violates Wayne's directive).

---

## Recommended Next Steps

1. **For Bart:** Add architecture doc tasks to WAVE-0 assignments
2. **For Brockman:** Draft/review impacted docs (creature death reshape, D-14 implications)
3. **For Nelson:** Prepare test infrastructure for ~240 new tests across 25 test files
4. **For Moe:** Get cellar-brazier location locked in before WAVE-3 cook verb work
5. **Escalate to Wayne:** Confirm architecture doc placement in WAVE-0 before WAVE-0 kicks off

---

**Signed:** Marge  
**Role:** Test Manager  
**Date:** 2026-03-27  
**Status:** Awaiting architecture docs blocker resolution
