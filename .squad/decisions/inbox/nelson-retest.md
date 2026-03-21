# Nelson Retest Results — Pass 017

**From:** Nelson (QA)  
**Date:** 2026-03-21  
**Re:** Pass 017 retest of BUG-060, BUG-061, BUG-062

---

## Verified Fixed ✅

- **BUG-060** (CRITICAL → FIXED): `normalize_effect` handles both schema formats. Wind effect fires correctly on deep-cellar→hallway traversal. Candle extinguished.
- **BUG-062** (LOW → FIXED): Drink handler fallback checks `on_drink_reject`. Oil flask prints custom rejection.

## Still Broken ❌

### BUG-061 — Wine Bottle Location (HIGH)

**Problem:** Wine bottle still invisible in wine rack. The instance ID mismatch was fixed (IDs now match), but the `location` field was not updated to use the `.inside` surface suffix.

**Root Cause:** `storage-cellar.lua` line 28:
```lua
{ id = "wine-bottle", location = "wine-rack" },  -- WRONG
```

**Fix Required (one line):**
```lua
{ id = "wine-bottle", location = "wine-rack.inside" },  -- CORRECT
```

**Why:** The engine's container placement code (`main.lua` ~line 240) parses `location` with `loc:match("^(.-)%.(.+)$")`. Without the `.inside` suffix, the wine-bottle falls through to a root-level contents array that is invisible to `look inside` and `take from`. Compare with `iron-key` which correctly uses `"large-crate.inside"`.

**Impact:** All 6 Wine Drink puzzle tests remain FAIL. Puzzle 016 is completely blocked.

## Observation

Oil lantern fueling is blocked by parser — `pour/fill/fuel` verbs cannot resolve two-object interactions. Not a regression; likely same class as BUG-039.

---

**Action needed:** Apply one-line fix to `src/meta/world/storage-cellar.lua` line 28, then Nelson can retest Puzzle 016 wine drink sequence.
