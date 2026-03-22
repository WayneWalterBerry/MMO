# BUG-069: Confusing "sleep until dawn" error after dawn

**Reporter:** Nelson  
**Date:** 2026-03-22  
**Pass:** 022  
**Severity:** MINOR (usability)  
**Type:** Error message clarity  
**Status:** NEW

---

## Summary

When player tries `sleep until dawn` after dawn has already passed, the error message is technically correct but contextually confusing.

---

## Steps to Reproduce

1. Start game
2. `sleep until dawn` (works, brings to 6:00 AM)
3. `sleep 6 hours` (brings to ~8:30 AM)
4. `sleep until dawn` (error)

---

## Input

```
> sleep until dawn
```

**Context:** Current time is 8:38 AM (already past dawn at 6:00 AM)

---

## Expected Behavior

One of these messages:
```
It's already past dawn.
```

Or:
```
Dawn has already passed. Current time is 8:38 AM.
```

Or:
```
You can't sleep until dawn — it's already 8:38 AM.
```

---

## Actual Behavior

```
You can't sleep that long. Try 12 hours or less.
```

---

## Analysis

**Why it's confusing:**
- The message talks about "12 hours" when the player is thinking about "dawn"
- Player doesn't see the connection between "until dawn" and "that long"
- Message doesn't explain *why* sleeping until dawn is too long (because it's already past dawn)

**Why it's technically correct:**
- Sleeping from 8:38 AM until next dawn (~6:00 AM) would be ~21 hours
- That exceeds the 12-hour sleep limit
- The error is accurate, just not helpful

**Root cause:**
The sleep verb probably calculates the duration first, then checks against the 12-hour limit, without special-casing "until dawn" when current time > dawn time.

---

## Suggested Fix

Add special case in sleep verb (likely `src/verbs/sleep.lua`):

```lua
if target_time_name == "dawn" and game.state.time > dawn_time then
  return "It's already past dawn. Current time is " .. format_time(game.state.time) .. "."
end
```

**Alternative:** Check if calculated duration > 12 hours AND target is "dawn", show dawn-specific message.

---

## Impact

**Gameplay:** None — doesn't break anything  
**UX:** LOW — Only confuses players who test edge cases  
**Frequency:** Rare — most players won't try sleeping until dawn after dawn  

---

## Priority

**P2 (Polish)** — Nice to fix, but not urgent. Engine is stable and issue fixes are working.

---

## Related Issues

None.

---

## Test Verification

Once fixed, verify:
1. `sleep until dawn` before dawn → works ✅
2. `sleep until dawn` after dawn → clear message ✅
3. `sleep until dawn` at exactly dawn (6:00 AM) → works or clear message ✅
