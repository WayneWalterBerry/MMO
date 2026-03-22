# D-HEADLESS: Headless Testing Mode

**Author:** Bart (Architect)  
**Date:** 2026-03-25  
**Status:** Implemented

## Problem

Nelson's LLM play testing (Passes 034-035) reported 5 "hangs" (BUG-105/106/116/117/118) that turned out to be **false positives**. The root cause: the TUI split-screen renderer (`engine/ui/init.lua`) uses ANSI escape codes — cursor positioning (`\e[H`), scroll regions (`\e[r`), screen clearing (`\e[2J`), reverse video (`\e[7m`) — which overwrite existing terminal content. When Nelson's agent read the game output through an interactive terminal session, the cursor repositioning made responses appear blank or missing, simulating a hang.

Pass-035 proved this definitively: 50/50 PASS with zero hangs when tested via pipe-based automation with precise timing.

The false positives caused wasted engineering time: we investigated, added a 2-second global safety net (`debug.sethook` timeout in `loop/init.lua`), and ran a full hang elimination sprint — much of which was chasing ghosts.

## Solution: `--headless` Flag

Added `--headless` command-line flag to `src/main.lua` that activates a clean automated testing mode:

1. **Disables TUI** — no ANSI escape codes, no cursor positioning, no scroll regions, no screen clearing
2. **Suppresses prompt** — no `"> "` prefix that pollutes pipe output
3. **Clean delimiters** — every response ends with `---END---` on its own line, making it trivial to parse command boundaries
4. **Minimal banner** — skips the ASCII art header and tutorial hints; keeps only the room intro text
5. **Preserves all game logic** — only the presentation layer changes

## Usage

```bash
# Single command
echo "look around" | lua src/main.lua --headless

# Multi-command session
printf "feel around\nsearch nightstand\nquit\n" | lua src/main.lua --headless

# With room override for targeted testing
echo "look" | lua src/main.lua --headless --room cellar
```

## Output Format

```
You wake with a start. The darkness is absolute.
You can feel rough linen beneath your fingers.
---END---
<response to first command>
---END---
<response to second command>
---END---
```

Parsing is trivial: split on `---END---\n` to get individual responses.

## Relationship to `--no-ui`

`--no-ui` was an existing flag that disabled the TUI but still showed `"> "` prompts, the full welcome banner, and helper text. `--headless` implies `--no-ui` but goes further — designed specifically for pipe-based automated testing where every byte of output matters.

## Impact

- Nelson MUST use `--headless` for all automated/LLM play testing going forward
- Eliminates the entire class of TUI false-positive hang reports
- No changes needed to game logic, parser, or verb handlers
- Existing `--no-ui` behavior preserved for human terminal use without TUI

## Files Changed

- `src/main.lua` — flag parsing, context propagation, banner gating
- `src/engine/loop/init.lua` — prompt suppression, response delimiters, helper text gating
