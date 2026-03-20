# Nelson Pass-007 Bug Summary
**Date:** 2026-03-20  
**Build:** 634a96e  
**Pass:** test-pass/2026-03-20-pass-007.md

## New Bugs (2)

### BUG-031 (MINOR): Compound "and" commands show confusing mixed output with GOAP
- **Repro:** Fresh start → `get match from matchbox and light candle`
- **Expected:** Graceful failure or GOAP chains everything
- **Actual:** First half fails ("You don't see matchbox here"), then GOAP succeeds for second half. Player sees error + success.
- **Impact:** Confusing UX, not game-breaking

### BUG-032 (MINOR): "burn candle" doesn't trigger GOAP backward-chaining
- **Repro:** Fresh start → `burn candle`
- **Expected:** GOAP chains to get flame, same as `light candle`
- **Actual:** "You have no flame to burn anything with." — verb recognized but no GOAP. `light` and `ignite` DO trigger GOAP.
- **Fix:** Register "burn" as GOAP goal synonym for "light"

## Verified Fixed (4)
- BUG-015: Wardrobe internal IDs → now shows display names ✅
- BUG-028: "key" doesn't resolve to "brass key" → `get key` works ✅
- BUG-029: Iron door not examinable → `look at door` works ✅
- BUG-030: No unlock verb → 3 phrasings work, error states clean ✅

## Assessment
**Strongest build yet.** GOAP is transformative. Zero regressions. Only 2 minor bugs found.
