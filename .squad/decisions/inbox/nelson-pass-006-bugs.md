# Nelson — Pass 006 Bug Report
**Date:** 2026-03-20  
**Pass:** Test Pass 006 — Multi-Room Movement

---

## Previous Bugs Fixed

### BUG-026: Movement verbs completely unimplemented — ✅ FIXED
All movement verb forms now work: `down`, `d`, `go down`, `descend`, `climb down`, `enter trap door`, `up`, `u`, `go up`, `ascend`, `climb up`. This was the #1 critical blocker from pass-005.

---

## New Bugs

### BUG-029: Iron door in cellar not examinable
- **Severity:** Minor
- **Input:** `look at door` / `look at iron door` (in cellar)
- **Expected:** Description of the heavy iron-bound door shown in exits
- **Actual:** "You don't see that here."
- **Notes:** The exit list shows "a heavy iron-bound door (locked)" but neither "door" nor "iron door" resolves to an examinable object. Player can walk into it (`go north` → "locked") but can't examine it.

### BUG-030: No unlock/use-key verb for locked doors
- **Severity:** Major — **Blocks game progression past the cellar**
- **Input:** `unlock door` → "I don't understand that." / `use key on door` → "I don't understand that." / `open door` → "You can't open that."
- **Expected:** Some interaction with the lock using the brass key found under the rug
- **Actual:** No unlock verb recognized. Key is a dead-end item.
- **Notes:** The brass key + locked iron door is clearly a designed puzzle. But the parser has no unlock verb. This is the next critical-path blocker after BUG-026 was fixed. **Player cannot reach Room 3.**
