---
name: "LLM Play Testing"
description: "Using an LLM agent to interactively play a text adventure game as a QA tester. The agent improvises natural language like a real player, discovers bugs through creative exploration, and produces structured test pass reports."
domain: "testing, qa, text-adventure, interactive-fiction, play-testing"
confidence: "medium"
source: "observed"
tools:
  - name: "powershell (async mode)"
    description: "Launch the game as an interactive process"
    when: "Starting lua src/main.lua in async mode to send commands and read responses"
  - name: "write_powershell"
    description: "Send player commands to the running game"
    when: "Typing commands like 'feel around', 'search nightstand', 'light candle'"
  - name: "read_powershell"
    description: "Read game output after sending a command"
    when: "Capturing the game's response to evaluate correctness"
  - name: "create / edit"
    description: "Write test pass report incrementally"
    when: "Streaming results to the test pass file as each test completes"
---

## Context

This skill captures the technique of using an LLM agent (Nelson) to play-test a text adventure game interactively. Unlike traditional automated testing (scripted assertions, unit tests), the LLM brings human-like creativity — improvising natural language phrases, trying things a real player would try, and recognizing when responses "feel wrong" even without explicit assertions.

This is a zero-cost alternative to human play testing that catches a different class of bugs than unit tests: parser coverage gaps, unnatural error messages, missing synonyms, interaction chain regressions, and UX friction.

### ⚠️ CRITICAL: Always Use `--headless` for Automated Testing

**The game has a TUI (split-screen terminal UI) that uses ANSI escape codes for cursor positioning, screen clearing, and scroll regions.** When an LLM agent reads game output through an interactive terminal session, the TUI rendering overwrites existing content, making it LOOK like the game hung — even though the engine responded correctly. This caused 5 false-positive hang reports (BUG-105/106/116/117/118) and a wasted engineering sprint.

**Solution:** Always launch the game with `--headless` for automated testing:

```bash
echo "look around" | lua src/main.lua --headless
```

Headless mode:
- Disables all TUI rendering (no ANSI codes, no cursor repositioning)
- Outputs plain text only (no `"> "` prompt prefix)
- Adds `---END---` delimiter after each response for easy parsing
- Preserves all game logic — only presentation changes

**NEVER test via interactive terminal mode.** Use `--headless` + piped input. See decision D-HEADLESS for full rationale.

## Patterns

### Pattern 1: Headless Pipe-Based Testing (Recommended)

Launch the game in headless mode with piped input for reliable, parseable output.

```
1. Build input: write commands to a temp file or pipe them inline
2. Run: echo "command" | lua src/main.lua --headless
3. Parse output: split on "---END---" to get individual responses
4. Evaluate: does each response make sense? Is it what a player would expect?
```

For multi-command sessions:
```bash
printf "feel around\nsearch nightstand\nquit\n" | lua src/main.lua --headless
```

**Key:** Each response is delimited by `---END---`. No ANSI codes, no prompt noise, no false positives.

### Pattern 1b: Interactive Game Session (Legacy — Not Recommended)

Launch the game in async mode, send commands, read responses. **WARNING:** This approach is prone to TUI false positives — use Pattern 1 (headless) for automated testing.

```
1. powershell mode="async" → lua src/main.lua --no-ui
2. write_powershell → send command (e.g., "feel around")
3. read_powershell → capture response
4. Evaluate: does the response make sense? Is it what a player would expect?
5. Repeat with creative variations
```

### Pattern 2: Creative Phrase Generation

The LLM's value is improvising phrases a scripted test would never try. Test categories:

| Category | Examples | What It Catches |
|----------|----------|-----------------|
| **Polite phrasing** | "please open the drawer", "could you look around?" | Politeness stripping gaps |
| **Questions** | "what's in here?", "is the door locked?" | Question transform coverage |
| **Adverbs** | "carefully examine", "quickly take" | Adverb poisoning the parser |
| **Synonyms** | "check", "inspect", "hunt for", "rummage" | Missing verb synonyms |
| **Articles** | "find the matchbox", "take a match" | Article stripping in targets |
| **Compound** | "find a match and light it", "search for matches then light the candle" | Compound command splitting |
| **Natural speech** | "I want to look around", "let me open that" | Preamble stripping |
| **Confused player** | "help", "what do I do", "where am I" | Error message quality |
| **Mischievous player** | "eat the door", "throw the room", nonsense input | Graceful failure handling |

### Pattern 3: Structured Test Pass Report

Every test pass follows the format defined in `test-pass/README.md`:

**File location:** `test-pass/gameplay/YYYY-MM-DD-pass-NNN.md`
**READ `test-pass/README.md` BEFORE writing.** Follow naming, location, and content conventions exactly.

Report structure:
```markdown
# Pass-NNN: {Title}
**Date:** YYYY-MM-DD
**Tester:** Nelson
**Build:** Lua src/main.lua

## Executive Summary
Total tests, pass/fail counts, severity breakdown.

## Bug list table
| Bug ID | Severity | Summary |

## Individual Tests
### T-001: {exact phrase typed}
**Response:** {exact game output}
**Verdict:** ✅ PASS / ❌ FAIL / 🔴 HANG / ⚠️ WARN
**Bug:** BUG-NNN (if applicable)
```

### Pattern 4: Streaming Output

**CRITICAL:** Write the test pass file incrementally. Append each test result AS IT COMPLETES. If the game hangs or the session crashes, the transcript so far is preserved.

```
1. Create file with header
2. After each test: append the test result block
3. After all tests: prepend the executive summary
```

### Pattern 5: Bug Classification

| Severity | Criteria |
|----------|----------|
| **CRITICAL** | Game hangs (requires force-quit), data loss, blocks progression |
| **HIGH** | Feature doesn't work, common player phrase fails |
| **MEDIUM** | Minor feature gap, uncommon phrase fails, cosmetic issue |
| **LOW** | Grammar, polish, extremely rare edge case |

Assign sequential bug IDs continuing from the last known bug number. Check existing test passes for the highest BUG-NNN.

### Pattern 6: Bug-to-Unit-Test Pipeline

After a play test pass, the bugs found should be converted to unit tests:
1. Each bug becomes one or more unit test cases
2. Tests encode the exact input that triggered the bug
3. Tests assert the expected correct behavior
4. Tests initially FAIL (confirming the bug exists)
5. After fixes, tests PASS (confirming the fix works)
6. Tests remain as regression guards forever

This creates a virtuous cycle: play test → find bugs → write unit tests → fix bugs → tests pass → play test again.

## Anti-Patterns

- **Don't script the session.** The whole point is improvisation. A scripted session is just a worse unit test.
- **Don't only test happy paths.** Try to break things. Type nonsense. Be a confused new player AND a mischievous veteran.
- **Don't wait until the end to write.** Stream incrementally — hangs lose everything if you buffer.
- **Don't forget the file conventions.** Read `test-pass/README.md` every time. `YYYY-MM-DD-pass-NNN.md` in the right subfolder.
- **Don't mix test types.** Gameplay tests go in `gameplay/`. Object tests go in `objects/`. Don't dump in the root.

## When to Use

- After any code changes to parser, verbs, search system, or game mechanics
- After bug fixes (regression verification)
- Before releases (critical path verification)
- When adding new objects, rooms, or interactions
- When Nelson is spawned for "play testing", "test pass", "try it out", "creative testing"

## Metrics

Track across passes:
- **Pass rate trend** — are we improving?
- **Hang frequency** — should approach zero
- **Bug severity distribution** — should shift from CRITICAL to LOW over time
- **Phrase coverage** — are we testing new categories each pass?
