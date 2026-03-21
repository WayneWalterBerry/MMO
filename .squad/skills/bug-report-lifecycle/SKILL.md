---
name: "Bug Report Lifecycle"
description: "Standard workflow for triaging, diagnosing, and fixing player bug reports from the in-game 'report bug' command. Covers issue intake, root cause analysis, implementation, testing, deployment, and resolution communication."
domain: "bug-fixing, issue-triage, deployment, GitHub-integration"
confidence: "low"
source: "manual"
tools:
  - name: "github-mcp-server-issue_read"
    description: "Read issue details, body, and comments from GitHub Issues API"
    when: "Fetching the bug report from WayneWalterBerry/MMO-Issues; extracting player session transcript and reproduction steps"
  - name: "github-mcp-server-issue_read (get_comments)"
    description: "Retrieve and post comments on GitHub issues"
    when: "Adding status updates or closing comments with deployment confirmation"
---

## Context

Bug reports filed by players via the in-game `/report bug` command are automatically created as GitHub issues in the **public** repository `WayneWalterBerry/MMO-Issues`. These issues contain:
- **Room name** — where the player was when the bug occurred
- **Timestamp** — when the bug was reported
- **Session transcript** — last 50 lines of player activity/server events
- **Player description** — free-form explanation of what went wrong

The issue lifecycle spans five phases: intake, diagnosis, fix + test, deploy, and resolution.

## Patterns

### Phase 1: Read the Issue

**Pattern**: Obtain complete context before diagnosing

1. Use `github-mcp-server-issue_read` (method: `get`) to fetch the full issue from `WayneWalterBerry/MMO-Issues`
2. Extract and parse the **session transcript** (the last ~50 lines of game activity)
3. Identify the exact sequence of player actions leading up to the bug
4. Note room name, player action, and any error messages in the transcript

**Example transcript structure**:
```
[14:32:10] Player: examine book
[14:32:11] Server: "You see a dusty book about wizards."
[14:32:15] Player: take book
[14:32:16] Server: ERROR: Parser failure at token 3
[14:32:17] Player: /report bug
```

---

### Phase 2: Diagnose

**Pattern**: Route to the appropriate specialist agent based on bug type

Categorize the issue and delegate to the owning team:

| Bug Type | Specialists | Source Files |
|----------|------------|--------------|
| **Parser issue** (tokenization, grammar, syntax error) | Bart (Lead) or Smithers (Senior Engineer) | `src/engine/parser/` |
| **Object/room behavior** (missing objects, wrong state, collision) | Flanders (Object Systems) | `src/meta/objects/`, `src/meta/world/` |
| **Verb handler bug** (verb not recognized, wrong output format) | Smithers | `src/engine/verbs/init.lua` |
| **UI/display issue** (status bar, inventory, text rendering) | Smithers | `web/bootstrapper.js`, `web/game-adapter.lua` |

**Diagnosis workflow**:
1. Share the transcript with the assigned specialist
2. Specialist reads relevant source files (e.g., `src/engine/parser/preprocess.lua` for parser bugs)
3. Reproduce the bug locally or trace the code path from the transcript
4. Identify the root cause line/function

---

### Phase 3: Fix + Unit Test

**Pattern**: Implement fix with regression safety

1. **Implement the fix** in the appropriate source file(s)
   - Example: Fix tokenizer bug in `src/engine/parser/tokenize.lua`
   - Example: Update verb handler in `src/engine/verbs/init.lua`

2. **Write a unit test** that reproduces the original bug and verifies the fix
   - Parser bugs → write test in `test/parser/` (e.g., `test/parser/test-preprocess.lua`)
   - Other bugs → add test in the appropriate `test/` subdirectory

3. **Run existing tests** to verify no regressions:
   ```powershell
   lua test/parser/test-preprocess.lua
   lua test/parser/test-context.lua
   # (run all applicable test suites)
   ```

4. Ensure all tests pass before moving to deployment

---

### Phase 4: Deploy

**Pattern**: Build, copy, and push in sequence

Deployment sequence (execute in order; each step must complete successfully):

1. **Rebuild the engine**:
   ```powershell
   powershell -File web/build-engine.ps1
   ```

2. **Rebuild the meta objects**:
   ```powershell
   powershell -File web/build-meta.ps1
   ```

3. **Copy to GitHub Pages**:
   - Copy the built files to: `C:\Users\wayneb\source\repos\WayneWalterBerry.github.io\play\`
   - Verify files are in place

4. **Commit and push the Pages repo**:
   ```bash
   cd C:\Users\wayneb\source\repos\WayneWalterBerry.github.io
   git add play/
   git commit -m "Deploy bugfix: [brief description]"
   git push
   ```

5. **Commit and push the MMO source repo**:
   ```bash
   cd C:\Users\wayneb\source\repos\MMO
   git add src/ web/ test/
   git commit -m "Fix: [bug description]. Tests updated. Deployed."
   git push
   ```

---

### Phase 5: Comment and Close

**Pattern**: Player-friendly communication, no private details

1. **Post a comment** on the GitHub issue (`WayneWalterBerry/MMO-Issues`) using `github-mcp-server-issue_read` (method: `get_comments`) with language that:
   - Explains what was fixed in **player terms**: "The game now correctly parses 'take the book' commands" (not "Modified tokenizer line 42")
   - Lists which game systems were changed (broadly): "Parser", "Object behavior", "Verb system"
   - Confirms deployment: "This fix is now live on the game"
   - **NEVER include**:
     - Private file paths (`src/engine/parser/tokenize.lua`)
     - Private repository URLs (code repo)
     - Secret game URL (`waynewalterberry.github.io/play/`)

2. **Example comment**:
   ```
   Thanks for reporting this! We found and fixed the issue.
   
   **What was wrong**: The game wasn't correctly handling multi-word item names in "take" commands.
   
   **What we fixed**: Updated the verb system to parse compound objects correctly.
   
   **Status**: ✅ This fix is now live on the game. Try again and it should work!
   ```

3. **Close the issue** using `gh issue close` or the GitHub API

---

## Examples

### Example 1: Parser Bug

**Issue**: Player reports "take the book" command not working in the Library

**Diagnosis**: Bart reviews transcript, identifies tokenizer error on multi-word object names

**Fix**: Update `src/engine/parser/tokenize.lua` to handle quoted phrases; write test in `test/parser/test-tokenize.lua`

**Deploy**: Build, copy to Pages, commit both repos

**Comment**: "Fixed multi-word object parsing in the verb system. Try 'take the book' again!"

---

### Example 2: Object State Bug

**Issue**: Player reports door in the Bedroom appears locked but can't be unlocked with the key

**Diagnosis**: Flanders reviews object state in `src/meta/world/bedroom.lua`, identifies missing state transition

**Fix**: Add state handler for unlock verb; write test to verify state transitions

**Deploy**: Rebuild meta, copy to Pages, commit

**Comment**: "Fixed the door unlock behavior. The key should now work as expected!"

---

## Anti-Patterns

### ❌ Do NOT

1. **Post technical details in issue comments** — Never mention file paths or implementation details. Players don't need to know about `src/engine/parser/preprocess.lua`.

2. **Reference the secret game URL** — The game URL is not public. Never post it in a public issue comment.

3. **Mention the private code repository** — The MMO source repo is private. Don't reference it by name or link.

4. **Skip unit tests** — Always write a test that reproduces the bug and verifies the fix. No test = risk of regression.

5. **Deploy without running regression tests** — Always run existing test suites before pushing to live.

6. **Close the issue before confirming deployment** — Verify the fix is live before closing; give the player confidence by confirming in a comment first.

7. **Leave deployment halfway** — Build + copy + commit must all complete. Partial deployments leave the game in an inconsistent state.

8. **Assume you know the root cause** — Always trace the code or reproduce the bug. Assumptions lead to wrong fixes.

---

## Related Skills

- **[Web Publish](./../web-publish/SKILL.md)** — The deployment phase uses web build and publish patterns
- **[Project Conventions](./../project-conventions/SKILL.md)** — Test structure and code organization conventions
