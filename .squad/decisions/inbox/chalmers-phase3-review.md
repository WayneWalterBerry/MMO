# Phase 3 Plan Audit — Chalmers (Plan Auditor)

**Document:** `plans/npc-combat/npc-combat-implementation-phase3.md`
**Author:** Bart (Architecture Lead)
**Reviewed:** 2026-08-16
**Requested by:** Wayne "Effe" Berry

---

## VERDICT: CONDITIONAL APPROVE

Phase 3 is well-structured and the scope is defensible. Two blockers must be resolved before execution begins. Four concerns should be addressed but are not gate-blocking.

---

## Blockers (MUST fix before WAVE-0 starts)

### B1: LOC Violations — Selective Enforcement

The plan correctly identifies `combat/init.lua` (695 LOC) as needing a pre-emptive split in WAVE-0. Good. But the W0 LOC audit only "flags" three other modules that are **already** over the 500 LOC limit — and then proceeds to add code to them without mandating splits.

| File | Current LOC | Phase 3 Adds | Projected | % Over 500 |
|------|------------|-------------|-----------|-------------|
| `combat/init.lua` | 695 | Split → ~445 + ~250 | ✅ Handled | — |
| `verbs/crafting.lua` | 629 | +50 (cook verb) | ~679 | **36%** |
| `verbs/survival.lua` | 715 | +30 (eat effects) | ~745 | **49%** |
| `engine/injuries.lua` | 556 | +40 (cure mechanics) | ~596 | **19%** |
| `creatures/init.lua` | 466 | +120 (W1+W2+W5) | ~586 | **17%** |

The Risk Register (R8) acknowledges crafting.lua hits 679 LOC and says "Flag for split in WAVE-5 or Phase 4 pre-flight." But survival.lua at 715 LOC is **already worse than the file being split in W0**, and gets no split plan at all.

**Required fix:** W0 must either (a) split `survival.lua` and `crafting.lua` alongside `combat/init.lua`, or (b) document an explicit exception with Wayne's approval and a firm Phase 4 split commitment. "Flag and defer" is insufficient when three files breach the same threshold that justified an entire pre-flight wave.

### B2: File Ownership Conflict in WAVE-4

The WAVE-4 detail section (line 490) assigns **combat sound propagation** to Smithers:

> `#### Combat Sound Propagation (Smithers)`
> `**File:** src/engine/combat/init.lua (~15 LOC addition)`

But the File Ownership Summary (line 686) assigns combat/init.lua W4 changes to **Bart**:

> `| src/engine/combat/init.lua | Bart | 0, 4 | W0: extract resolution.lua; W4: sound emission |`

And the File Conflict Prevention matrix (line 711) assigns it to **Smithers**:

> `| W4 | injuries.lua | ... | init.lua (kick), combat/init.lua (sound) | test/ |`

Per `.squad/routing.md`, Bart owns `src/engine/**` (including `combat/`). Smithers owns `src/engine/verbs/init.lua` and `src/engine/parser/**`, NOT combat modules.

**Required fix:** Reassign combat sound propagation to Bart in the WAVE-4 detail section. Update the File Conflict Prevention matrix. Alternatively, if Smithers is intentional (because the feature is presentation-adjacent), document the cross-boundary ownership with justification.

---

## Concerns (SHOULD fix)

### C1: Dependency Chain Is Overconstrained

The plan serializes W0 → W1 → W2 → W3 → {W4 ∥ W5}. True minimum dependencies:

```
W0 → W1 → W2 (strict: death → inventory drops)
      ↘ W3 (needs corpse objects from W1, not inventory from W2)
      ↘ W5 (needs creature death from W1, not food from W3)
W0 → W4 (needs combat/init.lua stable after W0 split)
```

W3 (food) does not require W2 (creature inventory) — the cook dead-rat path only needs dead-rat.lua from W1. W4 (kick, stress, cure, sound) doesn't need W3 or W2 at all — cure works on existing injuries, kick aliases an existing verb. W5 (respawning) needs creature death (W1) but not food or inventory.

**Impact:** The serial chain adds ~2 waves of unnecessary waiting. After W1, three waves (W3, W4, W5) could run in parallel instead of serially. W2 could also run parallel to W3 since they touch different files.

**Recommendation:** Restructure to: W0 → W1 → {W2 ∥ W3 ∥ W4} → W5 (docs + respawn + integration). This shortens the critical path significantly. If the conservative serial approach is intentional (gate quality), state that explicitly.

### C2: "(if exists)" Weapon References in WAVE-5

WAVE-5 assigns Smithers to add combat metadata to weapons:

> | iron-poker (if exists) | blunt | 5 | Fireplace tool |
> | letter-opener (if exists) | edged | 2 | Small blade |

A plan should not contain "(if exists)" references. Either verify these objects exist now and list their file paths, or remove them from scope.

**Recommendation:** Run `glob` for `src/meta/objects/iron-poker*` and `src/meta/objects/letter-opener*` and update the table with confirmed file paths or strike the rows.

### C3: Dead-Spider Portability Inconsistency

WAVE-1 object table (line 218) says dead-spider is a `small-item` (implying portable). Q4 answer (line 820) says "Dead wolf/spider are in-place" (implying furniture-sized, not portable).

The WAVE-1 table:
> | `dead-spider.lua` | small-item | No (chitin) | No |

The Q4 recommendation:
> Dead rat/cat/bat are small → portable. Dead wolf/spider are in-place.

These contradict. A spider small enough to be `small-item` template should be portable. If Q4 meant only dead-wolf is furniture, fix the text. If dead-spider should be furniture, fix the WAVE-1 table.

### C4: Spoilage FSM Claimed in WAVE-1 but Tested Without Food System

WAVE-1 includes spoilage FSM on dead creature objects (fresh → bloated → rotten → bones) and a test file `test/food/test-corpse-spoilage.lua`. But the food effects pipeline ships in WAVE-3. The FSM ticking mechanism needs to exist in W1 for spoilage to work — is that already in the engine from Phase 2, or does it need to be built?

If the FSM engine (`src/engine/fsm/init.lua`) already handles time-based transitions, this is fine. If not, the spoilage FSM in W1 is untickable until additional engine work ships. Clarify the dependency.

---

## Positives

1. **Wave tracker** — Present and well-formed. Matches Phase 1/2 format.
2. **Dependency graph** — ASCII diagrams + summary chain. Clear. No circular deps.
3. **File ownership** — New Files table (16 files) and Modified Files table (13 files) both clean. Per-wave conflict prevention matrix is a Phase 3 innovation not present in Phase 2 — good addition.
4. **Gates** — All 6 gates have checkboxed pass/fail criteria. Testable assertions.
5. **TDD test file map** — 16 test files, ~190 estimated tests. Comprehensive.
6. **D-14 alignment** — Corpse mutation, cook mutation, cure mutation all correctly use the code-rewrite model.
7. **Scope discipline** — 11 features explicitly deferred to Phase 4 (Section 11). This is excellent. Phase 3 builds a complete gameplay arc without scope creep.
8. **Open Questions** — 6 well-formed questions (Q1–Q6) with options tables, pros/cons, and recommendations. These are decision-ready for Wayne.
9. **Risk Register** — 8 risks with likelihood/impact/mitigation. R8 (crafting LOC) shows awareness of the LOC issue even if the mitigation is weak.
10. **Lessons from Phase 2** — Section 12 shows retrospective thinking. Module-split-first pattern directly applied.
11. **Parser Integration Matrix** — Appendix B tracks embedding index updates per wave. Good cross-system awareness.
12. **Autonomous Execution Protocol** — Sections 9, Gate Failure Protocol, and Wave Checkpoint Protocol all present (correcting my initial read — they were past line 689).

---

## Section-by-Section Structure Check

| Section | Present? | Notes |
|---------|----------|-------|
| Wave Status Tracker | ✅ | Top of doc, 6 waves |
| Executive Summary | ✅ | With "What We're Building", "Why This Order", "Phase 2 Foundation", "Walk-Away Capability" |
| Quick Reference Table | ✅ | Parallel tracks + gates + deliverables |
| Dependency Graph | ✅ | ASCII + summary chain |
| Implementation Waves (Detailed) | ✅ | W0–W5, agent assignments, code samples |
| Testing Gates Summary | ✅ | Estimated counts per gate |
| TDD Test File Map | ✅ | 16 files mapped |
| File Ownership Summary | ✅ | New + Modified + Conflict Prevention matrix |
| Risk Register | ✅ | 8 risks |
| Autonomous Execution Protocol | ✅ | With Gate Failure + Wave Checkpoint protocols |
| Open Questions | ✅ | 6 questions, option tables, recommendations |
| Phase 4 Deferrals | ✅ | 11 features explicitly deferred |
| Lessons from Phase 2 | ✅ | 5 lessons applied |
| GUID Reservation Table | ✅ | Appendix A, 15 entries |
| Parser Integration Matrix | ✅ | Appendix B, per-wave keyword map |

**Plan completeness:** 15/15 sections present. Structure matches implementation-plan skill format. Improvement over Phase 2 (which lacked Open Questions + Parser Integration).

---

## Summary

| Category | Rating |
|----------|--------|
| Plan structure | ✅ Excellent — all sections present, well-organized |
| Dependency chain | ⚠️ Correct but overconstrained (C1) |
| File conflicts | ❌ Ownership conflict in W4 (B2) |
| LOC projections | ❌ 4 files will exceed 500 LOC without planned splits (B1) |
| Scope | ✅ Well-sized, good Phase 4 deferrals |
| Open questions | ✅ 6 well-formed with option tables |
| Risk awareness | ✅ Good register, weak mitigation on LOC (R8) |

**CONDITIONAL APPROVE** — Resolve B1 (LOC splits) and B2 (ownership conflict), then this plan is execution-ready.

---

*— Chalmers, Plan Auditor*
