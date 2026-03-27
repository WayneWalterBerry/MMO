# Phase 2 NPC+Combat Implementation Plan Review

**Reviewed By:** Chalmers (Senior Reviewer)  
**Date:** 2026-03-26T16:45:00Z  
**Plan:** `plans/npc-combat-implementation-phase2.md` (Chunks 1–5)  
**Status:** READY WITH IMPROVEMENTS

---

## Executive Summary

The Phase 2 plan is **structurally sound** and **sequencing is mostly correct**, but several **safety and scalability issues** require attention before execution:

| Category | Status | Notes |
|----------|--------|-------|
| **Wave sequencing** | ✅ | Dependencies are correct; no parallel improvements possible |
| **File conflicts** | ⚠️ | CRITICAL: `src/engine/creatures/init.lua` modified in 2 waves; collision risk |
| **Crash resilience** | ⚠️ | No gate recovery procedure for mid-wave failure |
| **Session continuity** | ✅ | Version tracking present (Chunks 1–5); status tracker included |
| **Module size** | ❌ | `creatures/init.lua` +140 LOC / `combat/init.lua` +80 LOC will exceed limits |
| **Plan lifecycle** | ⚠️ | No post-mortem template; no version control for plan itself |
| **Gate failure paths** | ⚠️ | Escalation rules vague; no rollback procedure |

---

## Detailed Findings

### 1. Wave Sequencing ✅

**Assessment:** The dependency chain is correct and **cannot be parallelized further**.

**Evidence:**
- WAVE-0 → WAVE-1: Pre-flight must complete before creature data creation (reasonable)
- WAVE-1 → WAVE-2: Data must exist before engine consumes it (correct)
- WAVE-2 → WAVE-3: Predator-prey must work before multi-combatant (logical)
- WAVE-3/WAVE-4/WAVE-5: Correct serial ordering (combat → disease delivery → food uses combat)

**Parallelization check:**
- WAVE-3 (Bart/Smithers) and WAVE-4 (Flanders/Bart) are sequential: both need `combat/init.lua` modifications. WAVE-3 ships combat; WAVE-4 extends it with `on_hit` delivery. ✅ Cannot parallelize.
- WAVE-4 and WAVE-5 can overlap: Disease system (WAVE-4) and Food PoC (WAVE-5) are independent except Rabies blocks `drink` verb (cross-cut). This is intentional for integration testing. ✅ Correct.

**Gate sequencing is binary (no soft gates).** All-or-nothing progression prevents half-complete states. ✅

---

### 2. File Conflicts ⚠️ **CRITICAL**

**Assessment:** Dangerous file collision in WAVE-2 and WAVE-5.

**Conflict found:**

| File | WAVE-2 | WAVE-5 | Risk |
|------|--------|--------|------|
| `src/engine/creatures/init.lua` | Bart modifies (attack action, predator-prey) | Bart modifies (bait mechanic, hunger drive) | **MERGE CONFLICT** |
| `src/engine/combat/init.lua` | Bart modifies (NPC-vs-NPC) | — | Separate waves ✅ |

**The problem:** Both WAVE-2 and WAVE-5 claim ownership of `creatures/init.lua`:
- **WAVE-2:** Adds `score_actions()` for attack, `execute_action("attack")` branch, creature-to-creature stimulus
- **WAVE-5:** Adds hunger drive tick, `food_stimulus` detection, creature movement toward food

**WAVE-3 and WAVE-4 don't modify `creatures/init.lua`** (Bart only modifies `combat/init.lua` and `injuries.lua`). So the file sits untouched for 4 waves, then Bart comes back in WAVE-5. **If WAVE-2 or WAVE-3 fails and needs rollback, WAVE-5 code won't apply cleanly.**

**Recommendation:**
- **Option A (Preferred):** Move food/bait logic (`create_stimulus()` + hunger tick) into a separate module `src/engine/food-drivers/init.lua`. Creatures calls `food_drivers.process_hunger(creature, context)` once per tick. Eliminates file conflict; keeps `creatures/init.lua` stable after WAVE-2.
- **Option B:** Merge WAVE-2 and WAVE-5 food/bait work into a single WAVE-2.5 between WAVE-2 and WAVE-3. Requires scope negotiation; may delay NPC-combat ship date.
- **Option C (Current):** Accept conflict; document merge procedure in `.squad/decisions/`. If WAVE-2 fails mid-execution, WAVE-5 will need manual `git rebase` or cherry-pick. **Risk: Human error during recovery.**

**Decision requested:** Wayne should choose A/B/C before WAVE-0 starts.

---

### 3. Crash Resilience ⚠️

**Assessment:** No recovery procedure if a wave fails mid-execution.

**Current protocol (implicit from text):**
- Wave starts → parallel tasks → gate tests run → all-or-nothing pass/fail
- If gate fails: "Fix before proceeding" (implied: no formal retry procedure)

**Missing pieces:**
1. **Mid-wave failure:** If Flanders creates `cat.lua`, `wolf.lua`, `spider.lua` but Moe's room modifications fail, what's the status? Is the wave "half-done"? Can Nelson run GATE-1 tests?
2. **Gate failure recovery:** If GATE-1 fails because "chitin material registry fails," who owns the fix? Flanders (creator) or Bart (architecture reviewer)? Time estimate?
3. **Rollback procedure:** If GATE-1 fails after 4 hours of work, do we `git reset --hard` to pre-wave state and re-execute? Or cherry-pick individual fixes?

**Recommendation:**
- Add section to plan: **"Crash & Recovery Protocol"** (suggest ~200 words)
  - Define "half-done" wave: which tasks are critical-path vs. optional-polish?
  - Assign recovery owner for each gate failure class (e.g., "creature data load failure" → Flanders; "test infra failure" → Nelson)
  - Document rollback procedure: `git reset` vs. targeted fixes
  - Set re-gate budget: after fix, re-run gate immediately (no re-planning)

**Example structure:**
```markdown
## Crash & Recovery Protocol

### Mid-Wave Failure
If a wave is incomplete at day-end, the next day:
1. Status check: which tasks are done? (Flanders can report cat.lua + wolf.lua done, spider/bat incomplete)
2. Continuous tests: run partial test suite on completed deliverables (tests on cat/wolf pass; spider/bat tests skip)
3. Continue from checkpoint: remaining agents pick up where they left off (no re-planning)

### Gate Failure Classifications
- **Data load failure** (creatures don't parse): Owner = Flanders (fix data); recover time ~30 min
- **Test infrastructure failure** (test/food/ dir not registered): Owner = Nelson (fix runner); recover time ~15 min
- **Engine bug** (attack action crashes): Owner = Bart (fix code); recover time ~1–2 hrs
```

---

### 4. Session Continuity ✅

**Assessment:** Version tracking and status tracking are present and functional.

**Evidence:**
- **Plan versioning:** Each chunk has a date (2026-07-30, 2026-07-28) and "Chunk N of 5" header. Clear linear order.
- **Wave status tracker (§1, ~line 22):** `| Wave | Status |` table with `⏳` placeholders. Can be updated in real time.
- **Section 2 (Gates + Testing):** Each gate documents its exact pass/fail criteria and commit message (line ~706: `git commit -m "GATE-1: Phase 2 creature definitions..."`).
- **Scenario logging (§3, ~line 1107):** Nelson logs each LLM run to `test/scenarios/gate{N}/` with deterministic seeds and PASS/FAIL markers.

**This is professional.** The plan is a living document; teams can track progress by:
1. Updating wave status tracker daily
2. Grepping for "gate{N}" in commit history
3. Reading scenario log files for regression detection

**Gaps:**
- No "planned completion date" for each wave (e.g., "WAVE-1: ~4 hours, 1 agent day + 0.5 test days")
- No carry-over / burndown dashboard linking to daily plan

**Minor recommendation:** Add time estimate and owner per wave (suggested 1–2 lines each).

---

### 5. Module Size ❌ **CRITICAL**

**Assessment:** Engine modules will exceed safe LOC limits.

**Current sizes (from Phase 1):**
- `src/engine/creatures/init.lua`: 421 LOC
- `src/engine/combat/init.lua`: 435 LOC
- `src/engine/injuries.lua`: ~350 LOC (estimated from design)

**Phase 2 additions (per plan):**
- **WAVE-2:** `creatures/init.lua` +60–80 LOC (predator-prey, attack action)
- **WAVE-3:** `combat/init.lua` +30–50 LOC (NPC response auto-select, NPC stance)
- **WAVE-5:** `creatures/init.lua` +60–80 LOC (hunger drive, food stimulus)
- **WAVE-4:** `injuries.lua` +30–40 LOC (disease FSM ticking, `hidden_until_state` check)

**Post-Phase 2 sizes:**
- `creatures/init.lua`: 421 + 140 = **561 LOC** (EXCEEDS 500 LOC threshold)
- `combat/init.lua`: 435 + 80 = **515 LOC** (EXCEEDS 500 LOC threshold)
- `injuries.lua`: 350 + 40 = **390 LOC** (OK)

**Reference:** GATE-0 checks `wc -l` against 500 LOC limit (line ~656).

**This will fail GATE-0.** The plan pre-emptively identifies the problem but doesn't propose a solution.

**Recommendation (Must choose before WAVE-0):**

**Option A: Split creatures/init.lua (Preferred)**
- Extract creature-to-creature stimulus system → `src/engine/creatures/stimulus.lua` (~80 LOC)
- Extract predator-prey detection → `src/engine/creatures/predator-prey.lua` (~60 LOC)
- Keep main file at ~420 + 40 (attack action) = 460 LOC ✅

**Option B: Split combat/init.lua**
- Extract NPC behavior selection → `src/engine/combat/npc-behavior.lua` (~50 LOC)
- Keep main file at ~435 + 30 (narration changes) = 465 LOC ✅

**Option C: Defer WAVE-5 food/bait to Phase 3**
- Removes 60–80 LOC of creature additions → final size ~480 LOC ✅
- Trade-off: delays food PoC by 1 sprint; Phase 2 ships just creature combat (thematically incomplete)

**Option D: Accept 500+ LOC as a one-time exception**
- Update GATE-0 threshold to 600 LOC
- Risk: sets precedent; next phase module might be 700 LOC

**Chalmers recommendation:** Choose **Option A** (stimulus module split) because:
1. Stimulus is a distinct subsystem with clear interface
2. Isolates creature-to-creature events from creature-tick lifecycle
3. Future Phase 3 (social creatures, cooperation) will need this module anyway
4. No impact on WAVE-2 or WAVE-5 implementation; refactor timing is flexible (before or after WAVE-2)

---

### 6. Plan Lifecycle ⚠️

**Assessment:** Plan is thorough but lacks post-mortem and meta-versioning.

**Strengths:**
- Clear 5-chunk structure with cross-references
- Every gate has acceptance criteria
- Scenario logging provides regression baseline
- Each wave has file ownership matrix

**Gaps:**
1. **No post-mortem template:** After Phase 2 completes, where do lessons go?
   - Example: "Food bait mechanism was simpler than expected; could have shipped 1 day earlier"
   - Example: "Witness narration audio-only mode has edge case in adjacent-room distance calc; needs Phase 3 fix"
   - These go to `.squad/decisions/inbox/` or project notes?

2. **No plan versioning control:** If Bart needs to update the plan mid-wave (e.g., change WAVE-3 acceptance criteria), how is this tracked?
   - Suggested: `plans/npc-combat-implementation-phase2.md` → commits its changes to git (rare but possible during planning phase)
   - Or: `.squad/decisions/inbox/{agent}-phase2-scope-change.md` for each change

3. **No "plan deprecation" marker:** After WAVE-5, is this plan read-only? Or can it be edited for archival?
   - Suggested: Add "Status" field: `ACTIVE` → `COMPLETE` → `ARCHIVED` at doc top

**Recommendation:**
- After GATE-5 (phase 2 complete), file: `.squad/decisions/inbox/bart-phase2-postmortem.md` documenting:
  - What was faster/slower than estimated?
  - What module splits worked well? (if Option A is chosen)
  - Did creature-to-creature stimulus generalize as expected?
  - Food bait complexity vs. design estimate?
- Add "Plan Status: ACTIVE (in progress)" to top of doc; change to "COMPLETE" when GATE-5 passes
- Archive decision: move `.squad/decisions/inbox/` → `.squad/decisions/archive/` once merged into `decisions.md`

---

### 7. Gate Failure Paths ⚠️

**Assessment:** Gate failure escalation is implicit but not explicit.

**Current text (line ~668):**
> Action on fail: "File issue, assign to Flanders (creature data) or Nelson (test fix), re-gate."

**Problems:**
1. **No SLA:** How quickly should the assigned agent fix and re-gate? 1 hour? 1 day?
2. **No escalation:** What if Flanders doesn't respond? Does Bart take over? Does the wave wait?
3. **No rollback decision:** Is the wave rolled back to pre-start state while fixing? Or fixed in-place and then re-tested?
4. **No cross-gate rollback:** If GATE-2 fails, do we roll back GATE-1 and WAVE-1, or just fix WAVE-2 in isolation?

**Examples of ambiguous scenarios:**
- GATE-1 passes; GATE-2 partially fails (20 of 40 tests crash). Flanders fixes creature data (not code). Do we re-run all of GATE-2 or just the failing tests?
- GATE-3 fails; multi-combatant test loops forever. Bart needs to split `combat/init.lua` (Option B from module size issue). Do we delay WAVE-4 while splitting? Or split after GATE-3 passes?

**Recommendation:** Add **"Gate Failure Escalation Matrix"** to plan:

```markdown
## Gate Failure Escalation

| Gate | Failure Category | Owner | Assigned By | SLA | Rollback? |
|------|------------------|-------|-------------|-----|-----------|
| GATE-0 | Test dir not found | Nelson | Bart | 30 min | No (pre-flight) |
| GATE-1 | Creature load fails | Flanders | Bart | 1 hour | Yes (roll back WAVE-1) |
| GATE-1 | Creature load fails | Nelson | Bart | 30 min | No (in-place fix) |
| GATE-2 | Attack action crashes | Bart | Nelson | 2 hours | Yes (roll back WAVE-2) |
| GATE-3 | Multi-combatant hangs | Bart | Marge | 3 hours | Yes (roll back WAVE-3) |
| GATE-4 | Disease FSM doesn't progress | Bart or Flanders | Nelson | 2 hours | No (in-place fix) |
| GATE-5 | LLM scenario fails non-deterministically | Nelson | Bart | 1 hour (re-seed) | Maybe (investigate first) |

---

**Decision Rules:**
- **Code bugs (Bart/Smithers):** Assign immediately; SLA 2–3 hours; roll back wave on failure
- **Data issues (Flanders/Moe):** Assign immediately; SLA 1 hour; no rollback (in-place fix acceptable)
- **Test/infra issues (Nelson):** Assign immediately; SLA 30 min–1 hour; no rollback (fix and re-run)
- **If SLA expires:** Escalate to Chalmers for judgment call (defer wave, split task, etc.)
```

---

## Summary Table

| Review Area | Status | Issue | Impact | Recommendation |
|-------------|--------|-------|--------|-----------------|
| Wave sequencing | ✅ | None | — | Proceed |
| File conflicts | ⚠️ | `creatures/init.lua` touched in WAVE-2 & WAVE-5 | Merge conflict on rollback | **Choose Option A/B/C before WAVE-0** |
| Crash resilience | ⚠️ | No recovery procedure | Recovery is ad-hoc | Add "Crash & Recovery Protocol" section |
| Session continuity | ✅ | Minor: no time estimates per wave | Velocity tracking harder | Add ~1 line per wave (optional) |
| Module size | ❌ | Creatures/Combat exceed 500 LOC | **GATE-0 will fail** | **Choose Option A/B/C/D before WAVE-0** |
| Plan lifecycle | ⚠️ | No post-mortem template; no versioning | Knowledge loss after GATE-5 | Add post-mortem template + status field |
| Gate failure paths | ⚠️ | Escalation rules vague | Bottleneck on Bart if multiple failures | Add Escalation Matrix to plan |

---

## Pre-Execution Checklist

**Before WAVE-0 starts, Wayne must confirm:**

- [ ] File conflict resolution: A, B, or C?
- [ ] Module size handling: A, B, C, or D?
- [ ] If Option A (stimulus split): should split happen before WAVE-2 or after?
- [ ] Crash recovery protocol: add to plan?
- [ ] Gate escalation matrix: add to plan?
- [ ] Post-mortem template: file location after GATE-5?

**Once confirmed, update `plans/npc-combat-implementation-phase2.md` and commit as:**
```
git commit -m "Chalmers pre-execution review: address file conflicts, module sizes, recovery paths"
```

---

## Confidence Assessment

**Overall: 7.5 / 10**

The plan is **strategically sound** and **tactically detailed**. Sequencing is correct. But **3 blockers** (file conflicts, module size, crash recovery) must be resolved before execution:

- ✅ **Strengths:** Clear wave dependencies, comprehensive gate specs, LLM scenarios well-designed, ownership matrix complete
- ⚠️ **Weaknesses:** No recovery procedure, file conflict not resolved, module size pre-flagged but unsolved, no post-mortem structure
- ❌ **Blockers:** GATE-0 will fail on LOC check; file merge conflicts possible; no defined path for mid-wave recovery

**Recommendation:** Return plan to Bart for items marked `⚠️` and `❌`. Re-submit once resolved.

---

**Chalmers**  
Senior Reviewer, MMO Project  
2026-03-26T16:45:00Z
