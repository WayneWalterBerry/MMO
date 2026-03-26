# D-PLAN-REVIEW-FIXES: NPC+Combat Plan Review — All 16 Issues Fixed

**Author:** Bart (Architect)  
**Date:** 2026-07-28  
**Status:** 🟢 Active  
**Category:** Process  
**Requested By:** Wayne Berry

## Decision

Applied all 8 blockers and 8 concerns from team review to `plans/npc-combat-implementation-plan.md`. Every issue Wayne flagged is now resolved in the plan.

## Changes Applied

### Blockers

| ID | Issue | Fix |
|----|-------|-----|
| B1 | Hybrid stance combat not in plan | Added WAVE-5.5 section: stance model (aggressive/defensive/balanced), auto-resolve loop, interrupt on weapon break/armor fail/stance ineffective 2+ rounds. Smithers implements in WAVE-6. |
| B2 | Zero documentation deliverables | Added Brockman as parallel worker: 4 NPC docs in WAVE-3, 5 combat docs in WAVE-6. "No phase ships without its docs" gate rule. |
| B3 | Player model file path ambiguous | Verified: player table lives in `src/main.lua` lines ~305-324. Updated WAVE-4 to specify exact file path. |
| B4 | Test dirs not in test runner | Added WAVE-0 pre-flight task: Bart registers test/creatures/ and test/combat/ in run-tests.lua before any test files exist. |
| B5 | Creature tick perf budget missing | Added to GATE-2: tick <50ms with 5 creatures. Nelson adds perf assertion. |
| B6 | Material registry test unclear | Added explicit Nelson instruction: call `engine.materials.get('flesh')`, fail with clear message if nil (not a load error). |
| B7 | Distant-room stimulus edge case | Added test case #13 to WAVE-2: creature 3+ rooms away receives NO stimulus. Validates perception_range boundary. |
| B8 | NPC plan has zero docs | Covered by B2 — added creature-template.md and npc-system.md to Brockman's WAVE-3 deliverables. |

### Concerns

| ID | Issue | Fix |
|----|-------|-----|
| C1 | Gate failure protocol missing | Added Section 12: file issue → assign fix agent (not original author if lockout) → re-gate failed items only → escalate to Wayne on 1x failure. |
| C2 | Commit/push points missing | Added `git add -A && git commit && git push` after every gate pass. |
| C3 | Combat sub-loop input unclear | Added to WAVE-6 Smithers: combat runs inside main loop, same io.read() pattern, headless auto-selects balanced. |
| C4 | verbs/combat.lua ownership | Clarified: Bart owns combat/init.lua + combat/narration.lua. Smithers owns all verb handlers in verbs/init.lua. verbs/combat.lua is Bart's stimulus emission file. |
| C5 | Rat spawn location | Added to WAVE-3 Moe: top-level instance in cellar (not on/in/under furniture). |
| C6 | LLM scenario determinism | Added to Section 8: seed math.randomseed(42) via --headless. Retry with seeds 43, 44 before declaring failure. |
| C7 | Narration variety assertion | Added to WAVE-5 Nelson: 3 exchanges with fixed seed, assert ≥3 unique templates varying by severity + material + zone. |
| C8 | Escalation threshold | Updated to 1x failure → escalate (Phase 1 policy). Can relax to 2x once proven. |

### Additional Changes

- **combat/narration.lua split:** Changed from optional to REQUIRED. init.lua = FSM + damage, narration.lua = text generation.
- **Nelson as gate signer:** Added to GATE-3 and GATE-6 reviewer lists.

## Impact

- **All agents:** Plan is now the single source of truth for NPC+Combat implementation. Re-read before starting work.
- **Brockman:** New assignment — 9 documentation files across WAVE-3 and WAVE-6.
- **Smithers:** Defensive response prompts replaced with hybrid stance model. Re-read WAVE-6 instructions.
- **Nelson:** New test cases added (WAVE-2 perception boundary, WAVE-5 narration variety, GATE-2 perf budget).
- **Bart:** WAVE-0 pre-flight task added. combat/narration.lua is now required separate file.
- **Coordinator:** Gate failure protocol in Section 12. 1x escalation threshold for Phase 1.
