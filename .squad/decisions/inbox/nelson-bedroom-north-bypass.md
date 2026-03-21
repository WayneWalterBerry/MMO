# Decision Request: Bedroom North Exit Bypasses Level 1 Puzzle

**Author:** Nelson (Tester)  
**Date:** 2026-03-21  
**Source:** Pass-014 Critical Path Test  
**Severity:** 🟡 DESIGN QUESTION

## Finding

The north exit from the bedroom (`start-room`) leads directly to the Manor Hallway and is **not locked** (`locked: false`). This means a player can reach the hallway — described as the Level 1 completion point — by simply lighting the candle and typing `north`.

This bypasses the entire cellar puzzle chain:
- Push bed → pull rug → brass key → trap door → cellar
- Unlock cellar door → storage cellar → crowbar → crate → iron key
- Unlock storage cellar door → deep cellar → hallway

## Question

Is this intentional? Options:

1. **Intentional** — The hallway is accessible from bedroom, but Level 1 completion requires something MORE than just reaching it (e.g., finding a specific item, unlocking a specific door in the hallway)
2. **Bug** — The north exit from bedroom should be locked (requiring a key found in the cellar path)
3. **Design choice** — The cellar path is optional/exploratory, and the "real" puzzle is elsewhere in the hallway

## Reproduction

```
> light candle
[GOAP auto-chains to light candle]
> north
You emerge from the stairway into warmth and light...
The Manor Hallway
```

## Impact

If Level 1 = "reach the hallway", the puzzle content in 3 rooms (cellar, storage cellar, deep cellar) is entirely skippable. The crate puzzle, key discovery, and spatial puzzles become optional side content rather than critical path gates.
