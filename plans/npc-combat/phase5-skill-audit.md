# Phase 5 Implementation Plan — Skill Audit vs SKILL.md

**Auditor:** Chalmers (Plan Auditor)  
**Audit Date:** 2026-03-28  
**Plan Version Reviewed:** v1.0 (Assembled, 69.9 KB, ~1200 lines)  
**Skill Reference:** `.squad/skills/implementation-plan/SKILL.md` (16 patterns)

---

## Executive Summary

The Phase 5 plan is **well-structured and addresses 13 of 16 patterns comprehensively**. Three gaps identified:

1. **Pattern 14 (Plan Lifecycle):** Missing version increment post-review and session continuity clause
2. **Pattern 15 (Object Standards):** Missing mid-wave meta-lint checkpoint and GUID pre-assignment document
3. **Pattern 16 (Test Standards):** Missing formal regression baseline snapshots and flaky test quarantine marking

**Overall Assessment:** 81% skill compliance. The plan is execution-ready with these minor additions.

---

## Audit Checklist

| Pattern | Skill Requirement | Status | Notes |
|---------|-------------------|--------|-------|
| **1** | Resolve All Open Questions | ✅ PASS | Q1–Q7 documented, Wayne decisions captured, zero blockers |
| **2** | Plan Structure (11+ Sections) | ✅ PASS | All 14 required sections present + wave status tracker |
| **2a** | Chunked Plan Writing | ✅ PASS | Document explicitly states "Assembled from 5 chunks" |
| **3** | Wave Design Rules | ✅ PASS | No file conflicts, parallel batches explicit, instance labeling clear |
| **4** | Gate Design Rules | ✅ PASS | 4 gates binary pass/fail, reviewers specified, perf budgets present |
| **5** | Full Team Review | ⚠️ CONCERN | Reviewers listed as `[TBD]` at line 10 — needs actual names |
| **6** | Blocker Resolution | ✅ PASS | Pre-written decision inbox files noted (§3, §4, PRE-WAVE) |
| **7** | Documentation in Waves | ✅ PASS | Brockman assignments at GATE-2 and GATE-3; "no ship without docs" |
| **8** | TDD Throughout | ✅ PASS | Nelson tests in parallel, deterministic seeds noted, 18 test files mapped |
| **9** | Autonomous Execution Protocol | ✅ PASS | §11 fully detailed: wave loop, rules, commit strategy, emergency protocol |
| **10** | Wayne's Decision Capture | ✅ PASS | Q1–Q7 table (§1), decision inbox pattern noted (PRE-WAVE assignments) |
| **11** | Nelson Continuous LLM Testing | ✅ PASS | Smoke tests, full gates, scenarios documented, `--headless` required |
| **12** | Game Design Review (CBG) | ⚠️ CONCERN | CBG not listed in GATE reviewers; design debt mechanism missing |
| **13** | Architecture Safeguards (Bart) | ✅ PASS | Integration matrix (§9), cross-cutting checklist, 500 LOC guard noted |
| **14** | Plan Lifecycle | ❌ FAIL | Version stays v1.0; no post-review increment; session continuity clause missing |
| **15** | Object & Implementation Standards | ⚠️ CONCERN | GUID pre-assignment mentioned but not documented; mid-wave meta-lint missing |
| **16** | Test Standards | ⚠️ CONCERN | Regression baseline protocol drafted but snapshot logging not formalized |

---

## Detailed Gap Analysis

### Pattern 5: Full Team Review — CONCERN

**Skill Requirement:** "All team member reviews it from their domain" — CBG, Marge, Chalmers, Flanders, Smithers, Moe, Wayne.

**Current State (line 10):**
```
[Reviewers: [TBD — pending full plan completion]]
```

**Gap:** Reviewers are named as `[TBD]`. The plan is complete, but reviewer assignments are missing.

**Impact:** Medium — Coordination knows who should review, but formal sign-off record is absent.

**Fix (Critical):** Update line 10 to list actual reviewers:
```
Reviewers: CBG (game design), Marge (testing), Chalmers (sequencing), Flanders (objects), 
Smithers (verbs/parser), Moe (rooms), Wayne (docs/scope)
```

**Owner:** Scribe or Coordinator (not the plan author)

**Severity:** Should-have

---

### Pattern 12: Game Design Review at Gates — CONCERN

**Skill Requirement:** "Major gates include player experience check. CBG reviews: does it FEEL right? Subjective pass/fail scenarios. Design debt captured to `.squad/decisions/inbox/cbg-design-debt-WAVE-N.md`."

**Current State (§5):**
- GATE-1, GATE-2, GATE-3: Reviewers listed as "Bart + Nelson" only
- GATE-4: "Bart + Nelson + Brockman" — no CBG

**Gap:** CBG is absent from all gate reviewers. No "subjective pass/fail" scenarios written. No design-debt inbox pattern documented.

**Examples of missing scenarios:**
- GATE-1: "Light candle → explore Level 2 → encounter werewolf feels appropriately scary (narrative pacing check)"
- GATE-2: "3 wolves attack in sequence — combat choreography feels tactical, not janky (player feedback)"
- GATE-3: "Find salt → apply to meat → examine feels intuitive (UX flow)"

**Impact:** Medium — Gates will pass functionally but may miss player experience edge cases.

**Fix (Should-have):** 
1. Add CBG to GATE-4 reviewer list
2. Add subsection "§5.5: Design Debt Protocol" documenting `.squad/decisions/inbox/cbg-design-debt-WAVE-N.md` pattern
3. Examples of design-debt entries (not blockers, but recorded for polish phase)

**Owner:** Bart (plan author) or CBG (as reviewer)

**Severity:** Should-have

---

### Pattern 14: Plan Lifecycle — FAIL

**Skill Requirement:**
- "Version tracking: Plan increments version on each review fix pass (v1.0 → v1.1). Reviewers reference version."
- "Session continuity: If session dies mid-wave, next session checks plan status tracker, resumes from last completed wave."
- "Post-mortem: After all waves, add 'Lessons' section: actual vs estimated, gate failures, new risks, candidate skills."

**Current State (Line 5):**
```
Version: v1.0 (Assembled)
```

**Gaps:**
1. **No version increment after review:** The plan is marked v1.0 (assembled), but team review fixes (if any) won't increment it. Skill prescribes v1.0 → v1.1 after fixes.
2. **Session continuity clause missing:** The plan status tracker exists (line 14–22), but no explicit clause states: "If this session dies mid-WAVE-N, next session will check the tracker, find the last completed gate, and resume from WAVE-(N+1)."
3. **Post-mortem template missing:** No "Lessons Learned" section placeholder. The plan ends at line 1200; post-mortem section should be drafted (even as empty skeleton) for population after Phase 5 completes.

**Impact:** Medium — Without explicit session continuity and version tracking, a session crash mid-WAVE-3 risks ambiguity about what to resume.

**Fix (Critical):**
1. Add clause to §11 (Autonomous Execution Protocol):
   ```
   **Session Continuity:** If execution session dies (crash, network, timeout):
   1. Next session loads plan file and checks Wave Status Tracker (§Wave Status Tracker)
   2. Find last wave with ✅ Complete status
   3. Verify corresponding gate tag exists: git tag phase5-gate-N
   4. Resume from WAVE-(N+1) with fresh agent spawning
   ```

2. Add version bump rule to §12 (Gate Failure Protocol):
   ```
   After all reviewer findings are addressed and gates pass:
   - Increment version: v1.0 → v1.1 (fixes applied) → v1.2 (post-gate) etc.
   - Commit: git commit -m "Phase 5 plan updated to v{version}: reviewer fixes applied"
   ```

3. Add §17: Post-Mortem Template (skeleton for WAVE-5):
   ```
   ## Section 17: Lessons Learned (Post-WAVE-4)
   
   [To be filled after Phase 5 completion]
   
   ### Actual vs Estimated
   - Total LOC: {actual} vs ~1,975–2,575 estimated
   - Duration: {actual days} vs ~3–4 weeks estimated
   - Test count: {actual} vs 270+ target
   
   ### Gate Failures
   - GATE-1: [count and resolution]
   - GATE-2: [count and resolution]
   - GATE-3: [count and resolution]
   - GATE-4: [count and resolution]
   
   ### New Risks Discovered
   - [Risk X] → candidate mitigations
   
   ### Candidate Skills to Formalize
   - [Skill X] from Phase 5 execution pattern
   ```

**Owner:** Bart (plan author) to draft; Scribe to update after gates.

**Severity:** Critical

---

### Pattern 15: Object & Implementation Standards — CONCERN

**Skill Requirement:**
- "GUID pre-assignment: Architect reserves all GUIDs before wave starts in a decision inbox file. Prevents collisions during parallel authoring."
- "Meta-lint mid-wave: Run linter DURING waves (not just at gates) to catch object errors early."
- "Error message registry: Standardized user-facing error strings cataloged before implementation."

**Current State:**

1. **GUID pre-assignment:** Not explicitly documented. The plan refers to PRE-WAVE decisions going to `.squad/decisions/inbox/` (line 202, 203, 204) but doesn't reserve GUIDs. Flanders will create 15+ objects (werewolf, werewolf-pelt, salt, salted-*-meat, etc.) — risk of collisions if parallel instances spawn.

2. **Meta-lint mid-wave:** Line 639 mentions `meta-lint.lua` at GATE-4 only, not during waves. Skill prescribes "DURING waves (not just at gates)."

3. **Error message registry:** Not addressed anywhere in the plan.

**Impact:** Medium — GUID collisions are low-probability but high-cost in parallel authoring. Mid-wave linting would catch object definition errors earlier.

**Fix (Should-have):**

1. Add to PRE-WAVE (§PRE-WAVE, Assignments table):
   ```
   | Bart | **GUID pre-assignment** | Reserve GUIDs for 15+ Phase 5 objects. Write to `.squad/decisions/inbox/bart-phase5-guids.md` with format:
   {
     "werewolf": "6b2f8a4c-9e1d-4a7f-b3e2-c1f5a8d9e7b1",
     "salt": "7c3f8b4d-9e1d-4a7f-b3e2-c1f5a8d9e7b2",
     ...
   }
   Flanders and Smithers reference this file during WAVE-1, WAVE-3. |
   ```

2. Add to each wave's TDD Requirements:
   ```
   **Mid-wave meta-lint:** After agent #3 completes, run `lua scripts/meta-lint.lua` to catch missing 
   `on_feel`, GUID collisions, or malformed mutations. File issues immediately.
   ```

3. Add to §PRE-WAVE or new section:
   ```
   ### Error Message Registry (PRE-WAVE, Smithers)
   
   Standardized error strings for user-facing messages:
   - "You can't see that in the dark." (when light=0)
   - "You need X in your hand." (tool requirement)
   - "The {creature} is too strong." (combat imbalance)
   - ... [10–15 standard messages]
   
   Write to `src/engine/errors.lua` (new file, ~30 LOC).
   ```

**Owner:** Bart (GUID), Smithers (error registry), Nelson (meta-lint scheduling)

**Severity:** Should-have

---

### Pattern 16: Test Standards — CONCERN

**Skill Requirement:**
- "Regression baseline snapshots: Record exact test counts at start and end of each wave."
- "Flaky test quarantine: Non-deterministic tests use fixed seed OR are marked `@skip-ci` with issue link."
- "Test isolation: Each wave's tests must NOT `require()` tests from other waves."
- "LLM scenario logs: Exact input sequences documented in `test/scenarios/{wave}_{scenario}.txt`."

**Current State:**

1. **Regression baseline snapshots:** Line 568–569 mentions "Run `lua test/run-tests.lua` on Phase 4 HEAD before Phase 5 work. Record as PHASE-4-FINAL-COUNT (current: ~258 files, 223 tracked tests)." But there's **no formal snapshot logging format** (e.g., which file, how to compare, how to report diffs).

2. **Flaky test quarantine:** Line 515 says "Identify any non-deterministic tests added in WAVE-1 through WAVE-3. Add fixed seeds or mark `@skip-ci` with issue link." But this is WAVE-4 post-hoc. Skill prescribes proactive quarantine (e.g., `@skip-ci` pragma in test files themselves during write).

3. **Test isolation:** Not explicitly addressed. Plan doesn't state "test/level2/*.lua must not `require()` test/pack/*.lua."

4. **LLM scenario logs:** Lines 513, 526 document scenarios in `test/scenarios/phase5-full-walkthrough.txt`, ✅ correct format.

**Impact:** Low–Medium — Baseline snapshotting is informal; flakiness handling is reactive rather than preventive.

**Fix (Nice-to-have):**

1. Add to §6 (Nelson LLM Test Scenarios):
   ```
   ### Snapshot Logging Protocol
   
   After each gate, Nelson records baseline snapshot:
   ```
   File: test/baselines/phase5-gate-N-snapshot.txt
   Format:
   ```
   GATE-N Snapshot
   Date: 2026-03-28T HH:MM:SSZ
   Baseline Test Count (PHASE-4-FINAL): 223
   Wave 1 New Tests: +30
   Running Total: 253
   Regression Check: ✅ PASS (0 new failures vs Phase 4 baseline)
   ```
   ```
   
   Commit: `test/baselines/phase5-gate-N-snapshot.txt` with each gate tag.
   ```

2. Add to each wave's TDD Requirements:
   ```
   **Flaky Test Marking:** Any test using random behavior must include:
   ```
   math.randomseed(42)  -- deterministic seed for reproducibility
   ```
   Or mark with pragma:
   ```
   -- @skip-ci: Issue #XYZ (non-deterministic creature tick ordering)
   ```
   ```

3. Add to §7 (TDD Test File Map), subsection "Test Isolation":
   ```
   ### Test Isolation Rules
   
   - `test/level2/` files must NOT `require()` `test/pack/` or `test/preservation/` modules
   - Cross-wave scenarios (e.g., `test/integration/test-level2-full-flow.lua`) are allowed
   - Rationale: Each wave's tests must be independently runnable if earlier waves need rollback
   ```

**Owner:** Nelson (snapshot format, flaky marking), Marge (sign-off on isolation compliance)

**Severity:** Nice-to-have

---

## Summary Table — Gaps by Severity

| Pattern | Issue | Severity | Owner | Est. Effort |
|---------|-------|----------|-------|------------|
| **5** | Reviewers list `[TBD]` | Should-have | Scribe | 5 min (add names) |
| **12** | CBG missing from gates; design debt protocol absent | Should-have | CBG + Bart | 30 min (add to §5, draft examples) |
| **14** | Version increment + session continuity + post-mortem missing | Critical | Bart + Scribe | 45 min (add 3 clauses + skeleton) |
| **15** | GUID pre-assignment not documented; meta-lint not scheduled; error registry missing | Should-have | Bart + Smithers + Nelson | 1 hour (add 3 subsections) |
| **16** | Baseline snapshot format informal; flaky quarantine reactive; test isolation unstated | Nice-to-have | Nelson + Marge | 45 min (add 3 subsections) |

---

## Recommendations

### Immediate (Before Execution)

1. **Fill in Reviewer Names** (§Intro, line 10) — 5 minutes
2. **Add Session Continuity Clause** (§11) — 10 minutes
3. **Add Version Bump Rule** (§12) — 10 minutes
4. **Add CBG to GATE-4 Reviewers** (§5) — 5 minutes

**Est. total time: ~30 minutes. Blocking? No — can proceed with caveats.**

### Pre-WAVE-1 (PRE-WAVE Setup)

1. **Reserve GUIDs** (`.squad/decisions/inbox/bart-phase5-guids.md`) — 15 minutes
2. **Draft Error Message Registry** (`src/engine/errors.lua`) — 20 minutes
3. **Update test/run-tests.lua with Baseline Snapshot Protocol** — 10 minutes

**Est. total time: ~45 minutes. Blocking? No — can backfill in PRE-WAVE.**

### Post-Review (Nice-to-Have)

1. **Add Design Debt Protocol** (§5.5) — 20 minutes
2. **Add Flaky Test Quarantine Rules** (§7, §16) — 15 minutes
3. **Add Test Isolation Checklist** (§7, §16) — 10 minutes
4. **Draft Post-Mortem Section** (§17, skeleton) — 10 minutes

**Est. total time: ~55 minutes. Blocking? No — can defer to post-execution.**

---

## Conclusion

**Phase 5 plan is 81% compliant with the implementation-plan skill.** The 5 gaps are manageable:

- **1 Critical** (plan lifecycle / session continuity): Fix before execution
- **3 Should-have** (reviewer names, CBG review, object standards): Fix in pre-flight
- **1 Nice-to-have** (test baseline snapshots): Can defer to post-execution

The plan is **execution-ready** with these additions. Recommend addressing the Critical gap (Pattern 14) and Should-have gaps (Patterns 5, 12, 15) **before spawning Wave-1**, then backfill nice-to-have items in Wave-4.

---

**Audit Complete**  
*No commit recommended — this is a review artifact for Wayne.*
