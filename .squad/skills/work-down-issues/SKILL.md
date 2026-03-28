---
name: "work-down-issues"
description: "Burn down ALL open GitHub issues — plan, parallelize, iterate until zero, then run test-pass"
domain: "squad-operations"
confidence: "high"
source: "manual — Wayne directive 2026-03-26"
---

## Context

When Wayne says "work down issues", "burn down issues", "clear the backlog", or "work down the board", the Coordinator runs this structured burndown loop. The goal is to close ALL open GitHub issues through parallel agent work, verified by Marge, then run the test-pass skill as a final gate.

**Trigger phrases:** "work down issues", "burn down issues", "clear the backlog", "work down the board", "close all issues"

## Sequence

### Step 1 — Review All Open Issues

Pull ALL open issues from GitHub:
```
gh issue list --state open --json number,title,labels,body --limit 100
```

Categorize every issue by:
- **Owner** — which agent handles it (use routing.md + issue labels)
- **Type** — bug, enhancement, design, test, docs, linter
- **Dependencies** — does issue X need issue Y done first?
- **Complexity** — quick fix (< 5 min agent time) vs. standard vs. complex

### Step 2 — Plan Parallel Waves

Group issues into **waves** — batches that can run in parallel without file conflicts.

**Wave planning rules:**
- Same-file issues go in the SAME wave (serialized within wave) or DIFFERENT waves
- Different-file issues go in the SAME wave (parallel)
- Max 4-5 agents per wave (platform limits)
- Each wave should take ~5-15 minutes of agent time
- Dependencies determine wave ordering: if #42 depends on #41, put #41 in an earlier wave

**Present the plan to Wayne:**
```
📋 Burndown Plan: {N} issues in {M} waves

Wave 1 (parallel):
  🏗️ Bart — #42: Fix auth timeout (engine)
  🔨 Flanders — #38: Add candle sensory (object)
  ⚛️ Smithers — #45: Parser typo fix (parser)
  🏗️ Moe — #39: Room description update (rooms)

Wave 2 (parallel, after Wave 1):
  🏗️ Bart — #43: Refactor loader (depends on #42)
  ...

Estimated waves: {M}
```

**Do NOT ask permission to start.** Present the plan and immediately begin Wave 1.

### Step 3 — Execute Waves (TDD-First)

**⚠️ TDD IS MANDATORY.** Every bug fix MUST follow the TDD cycle:
1. **Write a failing test first** that reproduces the bug
2. **Run the test** — confirm it fails (proves the bug exists)
3. **Fix the code** — make the test pass
4. **Run all tests** — confirm zero regressions

This is not optional. Agents that skip the failing test step are doing it wrong. The test is PROOF the bug existed and PROOF the fix works. Include this instruction in every agent spawn prompt:

```
TDD REQUIRED: For each bug you fix:
1. Write a test that FAILS reproducing the bug
2. Fix the code so the test PASSES
3. Run full test suite — zero regressions
The test file goes in the appropriate test/ directory.
```

For each wave:
1. **Spawn all wave agents in parallel** (background mode) — spawn MULTIPLE instances of the same agent if they are working on different files with no conflicts (e.g., two Flanders fixing two different objects, two Nelson fixing two different test files)
2. **Collect results** as agents complete — verify each agent wrote tests
3. **Log any issues that couldn't be fixed** — create follow-up issues if needed
4. **Close fixed issues** via `gh issue close {number}` with a comment referencing the commit AND the test file
5. **Commit and push after EVERY wave:**
   ```
   git add -A && git commit -m "burndown wave {N}: {brief summary of fixes}
   
   Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
   git push origin main
   ```
   This ensures each wave's work is saved before the next wave starts. If an agent crashes mid-wave, previous waves are safe.

### Step 4 — Iterate Until Clear

After each wave:
1. **Re-scan GitHub** for remaining open issues
2. If issues remain, plan the next wave
3. **Do NOT stop.** Keep cycling waves until the board is clear or all remaining issues are blocked/deferred
4. Report progress every 2-3 waves:
   ```
   🔄 Burndown: Wave {N} complete
      ✅ Closed: {X} issues
      📋 Remaining: {Y} issues
      ⏭️ Next wave: {agents + issues}
   ```

### Step 5 — Marge Verification Gate

When ALL issues are closed (or only deferred/design issues remain):
1. **Spawn Marge** to verify closures:
   - For each recently-closed issue, Marge checks:
     - Was the fix actually committed?
     - Does the fix match what the issue described?
     - Are there any obvious regressions?
   - Marge can REOPEN issues that weren't properly fixed
2. If Marge reopens issues, go back to Step 3 and fix them
3. Marge's verdict is the gate — she must approve before proceeding

### Step 6 — Run Test Pass

Once Marge approves all closures, trigger the **test-pass** skill:
- Commit & push
- Run linter, unit tests, parser benchmark, Nelson walkthrough — all in parallel
- Log any new issues found
- Present final summary

## Patterns

- **Waves, not one-at-a-time.** Always maximize parallel work per wave.
- **Multi-instance agents.** Spawn the SAME agent multiple times if they can work on different files without conflicts. E.g., two Flanders fixing two different objects, two Nelson fixing two different test files. Use unique agent names: `flanders-fix-267`, `flanders-fix-265`.
- **Commit+push after EVERY wave.** Each wave's work is saved before the next starts. Crash-resilient.
- **Route by expertise.** Bart gets engine issues, Flanders gets objects, Smithers gets parser, Moe gets rooms, Nelson gets test issues, Brockman gets docs.
- **Close as you go.** Don't wait until all waves are done — close issues as each agent finishes.
- **Marge is the gate.** No issue is truly closed until Marge verifies. She can reopen.
- **Deferred issues are OK.** Some issues (design, future features) can't be fixed now — mark them and move on. The goal is zero actionable bugs, not zero issues.
- **Test pass is mandatory.** Even if all issues are closed, the test pass catches regressions.

## Wave Planning Heuristics

| Issue Type | Typical Agent | Typical Complexity |
|-----------|---------------|-------------------|
| Engine bug | Bart | Standard |
| Object missing sensory | Flanders | Quick fix |
| Parser/embedding issue | Smithers | Standard |
| Room description/exit | Moe | Quick fix |
| Test failure | Nelson | Standard |
| Linter rule violation | Lisa/Bart | Quick fix |
| Documentation | Brockman | Quick fix |
| Puzzle design | Sideshow Bob + Flanders | Complex |
| Web/deploy | Gil | Standard |
| Design/feature request | CBG (plan only) | Complex — often deferred |

## Anti-Patterns

- **Don't skip Marge.** She catches 10-20% of "fixes" that are actually incomplete.
- **Don't run test-pass before Marge approves.** The test pass should run on verified-clean code.
- **Don't serialize when you can parallelize.** If 4 agents can work simultaneously, use 4 agents.
- **Don't re-attempt issues that failed twice.** After 2 failed attempts, escalate to Wayne.
