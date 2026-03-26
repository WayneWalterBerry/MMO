---
name: "test-pass"
description: "Full quality gate — linter, tests, parser benchmark, Nelson walkthrough. Logs all issues to GitHub."
domain: "squad-operations"
confidence: "high"
source: "manual — Wayne directive 2026-03-26"
---

## Context

When Wayne says "test pass", "run test pass", "quality gate", or "full verification", the Coordinator runs this structured quality sweep. The goal is to find ALL issues and log them — NOT to fix them. This is a read-only audit that produces GitHub issues as output.

**Trigger phrases:** "test pass", "run test pass", "quality gate", "full verification", "run the gauntlet"

## Sequence

### Step -1 — Wait for All Agents to Finish

Check `list_agents` for any running background agents. If agents are still active:
- Report: `"⏳ Waiting on {N} agents to finish: {names}..."`
- Use `read_agent(wait: true, timeout: 300)` for each
- Collect and present their results normally
- If any agent is stuck after 5 minutes, stop it and note what was lost

### Step 0 — Commit and Push

Run sequentially:
```
git add -A
git status
```
If there are staged changes:
```
git commit -m "session: pre-test-pass commit

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
git push origin main
```
If nothing to commit, skip. If on a branch other than main, push to current branch.

### Step 1+ — Parallel Quality Checks (ALL AT ONCE)

**Launch ALL of these as background agents simultaneously.** They are independent — no dependencies between them.

#### Agent 1: Lisa — Run Linter
```
agent: Lisa
task: Run `python scripts/meta-lint/lint.py` and log ALL errors and warnings.
      For each ERROR, create a GitHub issue with:
        - Title: "Lint {RULE-ID}: {one-line description}"
        - Body: file path, line number (if available), rule description, severity
        - Label: "lint"
      Do NOT fix anything. Report only.
output: List of issues created + total error/warning counts
```

#### Agent 2: Nelson — Run Unit Tests
```
agent: Nelson
task: Run `lua test/run-tests.lua` and log ALL failures.
      For each FAILING test file, create a GitHub issue with:
        - Title: "Test failure: {test-file-name} ({N} failures)"
        - Body: test file path, failure count, specific failing test IDs and error messages
        - Label: "test-failure"
      Do NOT fix anything. Report only.
      Also report: total tests passed, total failed, total skipped.
output: List of issues created + test summary
```

#### Agent 3: Smithers — Run Parser Benchmark
```
agent: Smithers
task: Run `lua test/parser/test-tier2-benchmark.lua` and report results.
      If pass rate drops below 98% (144/147), create a GitHub issue:
        - Title: "Parser benchmark regression: {rate}% (was 98%)"
        - Body: failing case IDs, expected vs actual, benchmark score
        - Label: "parser"
      If at 98% or above, just report the score — no issue needed.
      Also list the 3 known failing cases for reference.
output: Benchmark score + any regression issue
```

#### Agent 4: Nelson — Full Level Walkthrough (LLM Playtest)
```
agent: Nelson (separate spawn from unit tests)
task: Run the game in headless mode and attempt to walk through ALL 7 rooms
      in Level 1. For EACH room, try:
        - Enter the room via portal
        - Look around
        - Interact with 2-3 objects
        - Test all exits from the room
      Log EVERY issue found as a GitHub issue:
        - Title: "Playtest: {brief description}"
        - Body: full command transcript, expected vs actual, room name
        - Label: "playtest"
      Do NOT fix anything. Report only.
      Use: `echo "command" | lua src/main.lua --headless`
output: List of issues created + rooms visited + paths tested
```

### After All Agents Complete

Present a summary report:

```
🧪 Test Pass Results
━━━━━━━━━━━━━━━━━━━━
🔍 Linter:     {errors} errors, {warnings} warnings → {N} issues filed
🧪 Unit Tests: {passed}/{total} passed → {N} issues filed
📊 Parser:     {score}% ({pass}/{total}) → {regression? issue filed : "no regression"}
🎮 Walkthrough: {rooms}/{total_rooms} visited → {N} issues filed

Total new issues: {sum}
```

## Patterns

- **Parallel, not sequential.** Steps 1-4 run simultaneously as background agents.
- **Log, don't fix.** The test pass is a diagnostic tool. Fixes are separate work items.
- **GitHub issues are the output.** Every finding becomes a trackable issue.
- **Labels matter.** Use `lint`, `test-failure`, `parser`, `playtest` labels for easy filtering.
- **Idempotent labeling.** Check if an issue with the same title already exists before creating duplicates.
- **Nelson gets two spawns.** Unit tests and walkthrough are different tasks — spawn Nelson twice with different names (e.g., `nelson-unit-tests` and `nelson-walkthrough`).

## Anti-Patterns

- **Don't fix issues during a test pass.** That's a separate workflow. Test pass = audit only.
- **Don't skip the walkthrough.** It catches things unit tests miss (UX, text, parser gaps).
- **Don't run sequentially.** The whole point is parallel — 4 agents at once.
- **Don't skip commit+push.** Tests should run against committed code, not dirty working tree.
- **Don't create duplicate issues.** Check existing open issues before filing.
