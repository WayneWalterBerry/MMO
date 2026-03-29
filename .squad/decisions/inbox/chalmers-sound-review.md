# Sound Plan Review — Chalmers (Plan Auditor)

**Plan:** `projects/sound/sound-implementation-plan.md` + `board.md`  
**Date:** 2026-03-30  
**Verdict:** ⚠️ Concerns  

---

## Findings

### 1. ✅ Wave Dependency Graph Clean
WAVE-0 → GATE-0 → WAVE-1 → GATE-1 → WAVE-2 → GATE-2 → WAVE-3 → GATE-3. Linear, no cycles. Each wave has clear gate before next starts. This is correct.

### 2. ✅ File Ownership Non-Overlapping
- WAVE-0: Bart (`src/engine/sound/`), Gil (`web/`), Nelson (`test/`)
- WAVE-1: Flanders (`src/meta/objects/`), Moe (`src/meta/world/`), CBG (async design), Nelson (`test/`)
- WAVE-2: Bart (`src/engine/`), Smithers (`src/engine/verbs/`), Nelson (`test/`)
- WAVE-3: Gil (`web/`), Nelson (`test/`), Brockman (`docs/`)

No two agents touch the same file in the same wave. Safe for parallel execution. ✅

### 3. ⚠️ **BLOCKER: Wave-1 Parallelism Assumes CBG Async**
The plan lists CBG (design review) as a parallel track in WAVE-1. But:
- When does CBG's review happen? Concurrently with Flanders/Moe?
- What if CBG finds design issues? Does it block Flanders/Moe?
- Is CBG writing to `projects/sound/` (shared by board.md updates)? File conflict risk?

**Current risk:** If CBG's review surfaces issues, the wave halts waiting for rework. But the plan assumes all tracks finish simultaneously.

**Recommendation:** Clarify WAVE-1 sequencing:
- Option A: CBG review runs BEFORE Flanders/Moe start (sequential within WAVE-1).
- Option B: CBG runs in parallel; if issues found, capture to `.squad/decisions/inbox/`, don't block gate.
- Current plan assumes Option B but doesn't say so explicitly.

### 4. ⚠️ **BLOCKER: Gate-0 → Gate-1 Handoff Undefined**
After GATE-0 (sound manager loads), what state is the system in?
- Does `ctx.sound_manager` exist but have no sounds loaded?
- Can Flanders call `sound_manager.scan_object()` on a newly-defined object?
- Does the bridge (`window:_soundLoad()`) work without any sounds deployed to web?

The plan doesn't specify the **interface contract** between WAVE-0 and WAVE-1.

**Recommendation:** Add to GATE-0 criteria: "Sound manager API frozen. WAVE-1 can assume: M:init(), M:scan_object(), M:play() exist and work (with no-op fallback if bridge unavailable)."

### 5. ⚠️ **BLOCKER: WAVE-2 → WAVE-3 Crash Resilience**
After WAVE-2, sound events are firing (verb hooks, FSM transitions). WAVE-3 adds the build pipeline and deploy.

Risk: If the web build pipeline fails (bad .ps1 script, missing .opus files), can WAVE-3 rollback cleanly? Or are deployed sounds partially live?

**Recommendation:** Add to plan: "WAVE-3 gate includes: (a) build-sounds.ps1 passes validation, (b) staging deploy tested, (c) rollback plan documented (git revert + redeploy)."

### 6. ⚠️ Concern: WAVE-0 Checkpoint Missing
After GATE-0, the plan should checkpoint:
- All 3 WAVE-0 tracks completed ✅
- No regressions ✅
- Bart's sound manager API finalized and frozen
- Plan updated with status

Currently the plan doesn't specify who validates the checkpoint.

**Recommendation:** Add: "After GATE-0: Coordinator (Wayne or delegate) verifies all tracks done, updates `board.md` status to `WAVE-0: ✅`, commits."

### 7. ✅ Estimated Hours Reasonable
8–10 hrs (WAVE-0), 6–8 hrs (WAVE-1), 6–8 hrs (WAVE-2), 4–5 hrs (WAVE-3). Total 24–31 hrs over multiple agents is plausible for a feature of this scope.

### 8. ⚠️ Concern: Phase 2 Scope Creep Risk
The plan mentions Phase 2 items (Vorbis fallback, time-of-day variation, LRU cache, advanced mixer). But where are these captured? If not in `.squad/decisions/`, team members might assume Phase 1 includes them.

**Recommendation:** Create `.squad/decisions/inbox/bart-sound-phase2-deferral.md` explicitly listing deferred features. Prevents scope creep mid-WAVE.

### 9. ✅ Risk Register Adequate
Browser autoplay policy, file size, legacy browser support, concurrent sound limits, memory pressure — all identified with mitigations. No surprises.

### 10. ⚠️ Concern: Autonomous Execution Protocol Incomplete
The plan says "Gate failure → file GitHub issue, assign fix agent, re-gate." But:
- Who files the issue? (Nelson? Coordinator?)
- Who assigns the fix? (Bart? Coordinator?)
- How long before re-gate? (Same session? Next session?)
- Escalation to Wayne after how many failures? (Plan says "1x" but no failure threshold defined)

**Recommendation:** Add section: "Gate Failure Escalation: (1) Failure → Nelson files issue, tags assignee. (2) Assignee fixes, requests re-gate. (3) If re-gate still fails, escalate to Wayne within 30 min."

---

## Consolidated Verdict

**The plan is sequentially sound but has 3 blockers and 3 concerns around wave handoffs, crash resilience, and autonomous execution.**

### Blockers (Must Fix)

1. **WAVE-1 CBG parallelism:** Clarify whether CBG's design review runs in parallel (non-blocking to gate) or blocks Flanders/Moe.
2. **GATE-0 → GATE-1 interface contract:** Specify what API is frozen after GATE-0 that WAVE-1 depends on.
3. **WAVE-3 deploy rollback plan:** Document crash resilience and revert procedure before WAVE-3 starts.

### Concerns (Strongly Recommended)

4. Checkpoint protocol: Who validates GATE-0 completion + updates board.md?
5. Phase 2 deferred scope: Explicit `.squad/decisions/` file listing Phase 2 items.
6. Gate failure escalation: Define protocol (issue → assignee → Wayne threshold).

---

**Reviewed by:** Chalmers (Plan Auditor)  
**Confidence:** Medium (3 blockers around coordination, not execution)  
**Signature:** ⚠️
