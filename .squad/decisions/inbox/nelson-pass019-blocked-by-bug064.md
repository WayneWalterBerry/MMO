# Pass 019 Feedback — Nelson (Tester)

**Date**: 2026-03-21  
**Status**: Test Blocked by BUG-064

## Critical Blocker: BUG-064

**Severity**: CRITICAL  
**Title**: Container search doesn't reveal contents  
**Impact**: Blocks critical path at Step 3

### The Problem

Players cannot discover the matchbox inside the nightstand drawer.

**Commands Tested:**
- `search drawer` → only describes wood/handle
- `examine drawer` → only describes wood/handle
- `feel drawer` → only describes wood/handle

**Expected**: Should show "a small matchbox" (like `feel around` shows room objects)

**Actual**: Only tactile description of drawer surface

**Workaround**: Direct `get matchbox` works, but requires meta-knowledge

### Why This Matters

The critical path is:
1. `feel around` → discover nightstand ✅ (BUG-063 fixed!)
2. `open nightstand` → drawer opens ✅
3. **`search drawer` → discover matchbox** 🔴 BROKEN
4. `get matchbox`, `light match`, etc.

Without discovery at step 3, the game is unplayable for real users.

## Good News: BUG-063 is Fixed!

The GUID normalization fix works perfectly:
- `feel around` now correctly lists the nightstand
- Critical path Step 1 is solid
- The fix is complete

## What I Was Unable to Test

Due to BUG-064 blocking progression, I couldn't complete:

### Injury System (Highest Priority)
- Stabbing self with knife/dagger
- Targeted attacks (`stab my arm with knife`)
- `injuries` command
- `health` command
- Per-turn damage drain
- Auto-heal for minor cuts

### Bandage System
- `apply bandage` to wounds
- Bleeding stops / healing boost
- `remove bandage`
- Multiple wound targeting

### Poison System
- Drink poison bottle (should injure, not kill)
- Poisoned status in `injuries`
- Per-turn poison damage

### Puzzles
- Puzzle 015 (draft extinguish) — BUG-060 was fixed, wanted to retest
- Puzzle 016 (wine drink) — BUG-061 still open

### Parser & Edge Cases
- Multi-command variations
- Compound commands
- Pronoun resolution
- Natural variations (`grab`, `pick up`)
- Nonsense commands
- Empty/repeated commands

## Recommendation

**Fix BUG-064 before Pass 020.**

This is the highest priority. The game cannot be played without container search working.

Once fixed, I can complete the full injury system test (the newest, most complex feature) and verify the puzzle fixes.

## Positive Observations

**Writing Quality**: Exceptional throughout
- Match lighting: "sputters once, twice -- then catches with a sharp hiss and a curl of sulphur smoke"
- Match burnout: "The match flame reaches your fingers and dies. You drop the blackened stub."
- Drawer description: "Wood, smooth but slightly sticky from old wax."

**Match System**: Works beautifully
- Lights correctly
- Burns out over time
- Match count tracks properly (7→6)
- Atmospheric and immersive

**BUG-063 Fix**: Perfect
- Nightstand now appears in `feel around`
- GUID normalization is solid
- Critical path Step 1 complete

---

**Next Steps**: Fix BUG-064, then I'll do a full injury system test + puzzle retest in Pass 020.

— Nelson
