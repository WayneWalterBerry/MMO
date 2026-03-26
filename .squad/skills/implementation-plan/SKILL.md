---
name: "implementation-plan"
description: "How to write, review, and execute a multi-wave implementation plan with TDD, gates, docs, and autonomous execution"
domain: "planning, execution, coordination"
confidence: "high"
source: "earned — NPC+Combat Phase 1 implementation plan (2026-03-26), refined through 7-reviewer team review cycle"
---

## Context

When the team needs to implement a major feature that spans multiple agents, multiple files, and multiple phases, this skill defines how to write the plan, review it, resolve blockers, and execute it autonomously ("walk away" capable). This was earned during the NPC+Combat implementation plan — the first plan to go through full team review, blocker resolution, and wave-based autonomous execution.

Applies when:
- A feature touches 3+ agents' domains
- Implementation spans multiple files that must coordinate
- Wayne wants to "start it and walk away"
- Both design plans and implementation code are involved

## Patterns

### 1. Resolve All Open Questions BEFORE Writing the Plan

Before the architect writes the plan, the coordinator must:
- Extract ALL open questions from every source plan (NPC plan, combat plan, etc.)
- Categorize: which BLOCK implementation vs. which have clear recommendations
- Present blocking questions to Wayne ONE AT A TIME using `ask_user` with choices
- Batch-approve non-blocking questions that have recommendations
- Capture all decisions to `.squad/decisions/inbox/`
- Result: **ZERO open blockers** before the plan is written

### 2. Plan Structure (11+ Sections)

The implementation plan document (`plans/{feature}-implementation-plan.md`) must contain:

| Section | Purpose |
|---------|---------|
| Executive Summary | What we're building, in what order, why |
| Quick Reference Table | All waves + gates at a glance |
| Dependency Graph | ASCII/markdown showing what blocks what |
| Implementation Waves | Parallel batches of work (WAVE-0, WAVE-1, ...) |
| Testing Gates | Binary pass/fail checkpoints between waves |
| Feature Breakdown (per system) | Detailed per-module specs |
| Cross-System Integration Points | Where systems connect |
| Nelson LLM Test Scenarios | Specific headless walkthrough scripts |
| TDD Test File Map | Every test file listed with what it covers |
| Risk Register | What could go wrong + mitigations |
| Autonomous Execution Protocol | How coordinator runs without Wayne |
| Gate Failure Protocol | Escalation rules (1x → issue, 2x → Wayne) |
| Wave Checkpoint Protocol | After each wave: verify completion, update plan |
| Documentation Deliverables | Brockman's docs listed per gate |

### 3. Wave Design Rules

- **WAVE-0** = Pre-flight (test runner registration, directory creation, linting setup)
- Each wave is a batch of **parallel work** — all agents in a wave start simultaneously
- **Hard rule:** No two agents in the same wave touch the same file
- **Multiple instances OK:** The same team member CAN be spawned as multiple parallel instances in the same wave IF they're working on different files. E.g., two Nelson instances writing tests for different modules, or two Flanders instances building different objects. The coordinator labels them clearly (e.g., "Nelson (creature tests)" vs "Nelson (material tests)"). The only constraint is file-level: no two instances touch the same file.
- Each wave has explicit: agent assignments, exact file paths, TDD requirements, scope estimate
- **Commit/push after every gate passes**
- **Checkpoint after every wave:** verify completion, update plan documentation

### 4. Gate Design Rules

- Gates are **binary pass/fail** — no "mostly works"
- Every gate specifies: unit tests that must pass, zero regressions, LLM walkthrough scenarios
- Gate reviewers: Bart (architecture) + Marge (test sign-off) + Nelson (LLM walkthroughs)
- Performance budgets where applicable (e.g., "<50ms per creature tick")
- **Documentation completion** is a gate requirement ("no phase ships without docs")

### 5. Full Team Review BEFORE Execution

After the architect writes the plan, EVERY team member reviews it from their domain:

| Reviewer | Focus |
|----------|-------|
| CBG | Game design correctness, player experience, test scenarios |
| Marge | Test coverage, gate criteria, regression risks, autonomy protocol |
| Chalmers | Sequencing, parallelism safety, file conflicts, crash resilience |
| Flanders | Object work clarity, spec completeness, file ownership |
| Smithers | Parser/verb work, UI loop, file ownership |
| Moe | Room wiring, placement, portal integration |
| Wayne | Documentation gaps, missing deliverables |

All reviewers run **in parallel** (no file conflicts — they're reading, not writing).
Each reviewer reports: ✅ (good), ⚠️ (concern), ❌ (blocker).

### 6. Blocker Resolution

- Collect ALL findings from ALL reviewers
- Present consolidated table to Wayne: blockers vs. concerns
- Wayne says "fix all" → architect fixes them in ONE pass
- Wayne's own findings (like "docs missing") are treated as blockers too
- After fixes, the plan is review-clean — no second review round needed (unless structural changes)

### 7. Documentation in Waves

Documentation is NOT an afterthought — it's a gate requirement:
- Brockman runs **in parallel** with Nelson's LLM testing after each phase gate
- NPC docs after GATE-3, Combat docs after GATE-6
- Both `docs/architecture/` and `docs/design/` deliverables
- Rule: "No phase ships without its docs"

### 8. TDD Throughout

- Nelson writes test files in the SAME wave as implementation (parallel, different files)
- Tests are written to the spec, not to the implementation
- TDD catches become fix tasks for the implementer (not rejection — it's the TDD cycle)
- Integration tests verify cross-module behavior at gates
- LLM walkthroughs at major gates (GATE-3 for NPC, GATE-6 for Combat)
- Deterministic seeds (`math.randomseed(42)`) for reproducible LLM tests

### 9. Autonomous Execution Protocol

For "walk away" capability:
- Wave → parallel agents → collect → gate → pass? → checkpoint → next wave
- Fail? → file GitHub issue, assign fix agent, re-gate
- Escalate to Wayne after 1x gate failure (Phase 1 threshold — relax to 2x once proven)
- Commit/push after every gate
- Checkpoint plan doc after every wave (mark completed, note deviations)
- Ralph monitors the pipeline if activated

### 10. Wayne's Decision Capture Pattern

When resolving blocking questions:
- Use `ask_user` with choices (not open-ended)
- One question at a time
- Include recommendation as first choice with "(Recommended)" label
- Capture each decision immediately to `.squad/decisions/inbox/`
- Batch non-blocking questions: "approve all at recommendation?"

### 11. Nelson Continuous LLM Testing (Walk-Away Assurance)

For long-running autonomous execution without human intervention, Nelson runs LLM playthroughs **continuously**, not just at gates:
- **After every wave:** Nelson runs a quick smoke-test walkthrough (~5 commands) to verify the game still boots and basic interaction works. This catches regressions BEFORE the gate.
- **At every gate:** Nelson runs the full scenario suite (all scenarios defined for that gate). This is the formal pass/fail.
- **Between waves (if idle):** Nelson runs exploratory LLM sessions — freeform play in `--headless` mode, trying edge cases, unusual verb combinations, dark-room interactions. Findings logged as issues.
- **Frequency:** Coordinator decides when to spawn Nelson instances based on wave complexity. Simple data waves (WAVE-1, WAVE-4) get post-wave smoke only. Engine waves (WAVE-2, WAVE-5) get mid-wave checks too.
- **All runs use `--headless` mode** with deterministic seeds for reproducibility.
- **Nelson instances can run in parallel** with implementation agents (different files — tests vs engine code).

### 12. Game Design Review at Gates (CBG)

Beyond code tests, major gates include a **player experience check**:
- CBG reviews: does it FEEL right? Is the gameplay arc discoverable? Does pacing work?
- "Subjective pass/fail" scenarios: e.g., "light candle → examine room → pick up item should feel natural in <3 commands"
- Design debt captured to `.squad/decisions/inbox/cbg-design-debt-WAVE-N.md` — doesn't block gates but feeds polish phase

### 13. Architecture Safeguards (Bart)

- **Interface contracts:** Each wave documents what public APIs it exposes for the next wave. Contracts freeze once dependent wave starts.
- **Module size guard:** If any module exceeds 500 LOC mid-plan, trigger engine-code-review skill before it ships.
- **Rollback strategy:** Git tag per gate. If wave N+2 reveals wave N was wrong, revert to tag, re-plan.
- **Cross-cutting checklist:** Before each gate verify: consistent error handling, debug hooks present, performance baseline measured.

### 14. Plan Lifecycle (Chalmers)

- **Version tracking:** Plan increments version on each review fix pass (v1.0 → v1.1). Reviewers reference version.
- **Status tracker:** Top of plan doc shows wave status at a glance: `WAVE-0: ✅ | WAVE-1: 🟡 | WAVE-2: ⏳`
- **Session continuity:** If session dies mid-wave, next session checks plan status tracker, resumes from last completed wave.
- **Post-mortem:** After all waves, add "Lessons" section: actual vs estimated, gate failures, new risks, candidate skills.

### 15. Object & Implementation Standards (Flanders + Smithers)

- **Object spec checklist:** Before wave kickoff, verify every object has: GUID (Windows format, unique), template, `on_feel`, keywords, name, description.
- **GUID pre-assignment:** Architect reserves all GUIDs before wave starts in a decision inbox file. Prevents collisions during parallel authoring.
- **Meta-lint mid-wave:** Run linter DURING waves (not just at gates) to catch object errors early.
- **Parser integration matrix:** List new nouns, verb aliases, and embedding keywords per wave. Specify which wave updates `embedding-index.json`.
- **Headless requirement:** Every new feature must pass `--headless` mode. Add to gate checklist.
- **Error message registry:** Standardized user-facing error strings cataloged before implementation.

### 16. Test Standards (Marge)

- **Regression baseline snapshots:** Record exact test counts at start and end of each wave.
- **Flaky test quarantine:** Non-deterministic tests use fixed seed OR are marked `@skip-ci` with issue link.
- **Performance regression gates:** Every gate includes latency/memory budgets (e.g., creature tick <50ms).
- **Test isolation:** Each wave's tests must NOT `require()` tests from other waves.
- **LLM scenario logs:** Exact input sequences documented in `test/scenarios/{wave}_{scenario}.txt`.

## Examples

Reference implementation: `plans/npc-combat-implementation-plan.md` (72KB, 1271 lines, 7 waves, 6 gates)

Source plans consumed: `plans/npc-system-plan.md` + `plans/combat-system-plan.md`

Cross-reference analysis that preceded the plan: 13 alignment fixes identified and applied by CBG.

## Anti-Patterns

- **Don't write the plan with open questions** — resolve them ALL first
- **Don't skip team review** — every reviewer catches different things (CBG found hybrid stance gap, Marge found 4 test blockers, Wayne found docs gap, Chalmers found player file ambiguity)
- **Don't serialize the review** — all reviewers read in parallel
- **Don't treat docs as optional** — Wayne considers missing docs a blocker
- **Don't assume per-exchange combat input** — Wayne chose hybrid stance (auto-resolve + interrupt)
- **Don't put two agents on the same file in one wave** — guaranteed merge conflict
- **Don't skip WAVE-0 pre-flight** — test runner registration must happen before tests are written
- **Don't use 2x failure threshold for first-time features** — use 1x until the pattern is proven
- **Don't forget wave checkpoints** — update the plan doc after every wave completes
- **Don't leave the architect to fix their own review findings alone** — give them ALL findings in one consolidated pass
