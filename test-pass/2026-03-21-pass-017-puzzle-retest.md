# Pass 017: Puzzle Retest (BUG-060, BUG-061, BUG-062)

**Date:** 2026-03-21  
**Tester:** Nelson (QA Agent)  
**Build:** Latest (post BUG-060/061/062 fixes)  
**Method:** `lua src/main.lua --no-ui` (piped commands, plain stdout mode)  
**Purpose:** Retest the 11 tests that FAILED in Pass 016 after three bug fixes

---

## Summary

| Category | Tests | Passed | Failed | Blocked | Notes |
|----------|-------|--------|--------|---------|-------|
| Puzzle 015: Draft Extinguish | 4 | 3 | 0 | 1 | ✅ BUG-060 FIXED — wind effect fires correctly |
| Puzzle 016: Wine Drink | 6 | 0 | 6 | 0 | 🔴 BUG-061 NOT FIXED — wine bottle still inaccessible |
| Oil Flask Drink Rejection | 1 | 1 | 0 | 0 | ✅ BUG-062 FIXED — custom rejection text works |
| **TOTAL** | **11** | **4** | **6** | **1** | **36% pass, 55% fail, 9% blocked** |

**Previous Pass 016:** 0/11 of these tests passed  
**This Pass 017:** 4/11 passed, 6/11 still failing, 1 blocked  

---

## Bug Fix Verification

| Bug | Description | Status | Verdict |
|-----|-------------|--------|---------|
| BUG-060 | `on_traverse` schema mismatch | ✅ FIXED | `normalize_effect` correctly handles nested `{wind_effect: {...}}` format |
| BUG-061 | Wine rack contents ID mismatch | ❌ NOT FIXED | Wine bottle instance uses `location = "wine-rack"` but engine needs `location = "wine-rack.inside"` |
| BUG-062 | Drink handler ignores `on_drink_reject` | ✅ FIXED | Oil flask prints custom gagging text instead of generic refusal |

---

## 1. Puzzle 015: Draft Extinguish — 3 PASS / 0 FAIL / 1 BLOCKED

### Test 1.1: Go UP from deep cellar with lit candle → wind extinguishes candle
```
> go up
Halfway up the stairway, a gust of warm air rushes down from above. Your
candle flame gutters, flickers wildly — and goes out. Darkness swallows the
stairwell.
```
**Result:** Wind effect fires on traversal. Candle is extinguished. Player arrives in hallway. **PASS** ✅

### Test 1.2: Wind description prints
**Result:** Full atmospheric description prints: "Halfway up the stairway, a gust of warm air rushes down from above. Your candle flame gutters, flickers wildly — and goes out. Darkness swallows the stairwell." Excellent writing. **PASS** ✅

### Test 1.3: Candle is now unlit/extinguished
```
> inventory
  Left hand: a half-burned candle
  Right hand: a heavy iron key

> examine candle
A tallow candle, recently extinguished. The wick is black and still warm,
trailing a thin wisp of smoke. Wax has pooled and hardened in rough drips down
the sides. It could be relit.
```
**Result:** Candle FSM transitioned from `lit` → `extinguished`. Inventory shows "half-burned candle" (not "lit"). Examine confirms extinguished state with "It could be relit." **PASS** ✅

### Test 1.4: Oil lantern should NOT be extinguished (wind resistant)
**Result:** **BLOCKED** 🚫

Cannot fuel the oil lantern. Tested:
- `fill lantern` → "I don't understand that."
- `pour oil flask into lantern` → "You don't see that here."
- `pour oil flask` (while holding both) → "You can't pour a small ceramic oil flask."
- `fuel lantern with oil flask` → "I don't understand that."
- `use oil flask on lantern` → "an iron oil lantern is not a container"

The oil lantern FSM expects verb `pour` with tool requirement `lamp-oil` (provided by oil flask), but the parser can't resolve the two-object interaction. Cannot reach `fueled` state → cannot reach `lit` state → cannot test wind resistance.

**Note:** Code review shows the lantern does NOT have `wind_resistant = true` property. The wind effect's `extinguishes` list only targets `{ "candle" }`, so a lit lantern would likely be spared by type-mismatch regardless. But this cannot be verified in gameplay.

---

## 2. Puzzle 016: Wine Drink — 0 PASS / 6 FAIL

### Root Cause: BUG-061 NOT FIXED

The wine bottle instance in `storage-cellar.lua` (line 28) uses:
```lua
{ id = "wine-bottle", location = "wine-rack" }
```

But the engine's container placement code (`main.lua` lines 240-260) requires the explicit surface suffix:
```lua
{ id = "wine-bottle", location = "wine-rack.inside" }
```

Without `.inside`, the wine bottle gets placed into a root-level `contents` array on the wine-rack object, NOT into `wine-rack.surfaces.inside.contents`. The engine's `look inside`, `take from`, and item visibility code only checks `surfaces.inside.contents` — so the wine bottle is invisible and unreachable.

**Evidence:** Compare with iron-key which correctly uses `location = "large-crate.inside"` and IS accessible after prying.

### Test 2.1: Take wine bottle from wine rack
```
> take wine bottle
You don't see that here.

> get wine bottle from wine rack
There is no wine bottle in a wooden wine rack.
```
**Result:** Wine bottle not found. Not in room, not in wine rack. **FAIL** ❌

### Test 2.2: Open wine bottle (sealed → open)
**Result:** Cannot test — depends on 2.1. **FAIL** ❌

### Test 2.3: Taste wine (investigation text)
**Result:** Cannot test — depends on 2.1. **FAIL** ❌

### Test 2.4: Drink wine (open → empty, flavor text)
**Result:** Cannot test — depends on 2.1. **FAIL** ❌

### Test 2.5: Drink wine again (should say empty)
**Result:** Cannot test — depends on 2.1. **FAIL** ❌

### Test 2.6: Wine rack interaction (see bottles, take them)
```
> look at wine rack
A tall wooden wine rack against the west wall, built of dark-stained timber.
Circular slots hold bottles in rows -- most empty, a few still occupied.
Cobwebs bridge the gaps between bottles like silk hammocks. The wood is warped with damp.

> look inside wine rack
There is nothing inside a wooden wine rack.
```
**Result:** Rack description mentions "a few still occupied" but `look inside` shows nothing. Contradiction between narrative and gameplay state. **FAIL** ❌

---

## 3. Oil Flask Drink Rejection — 1 PASS / 0 FAIL

### Test 3.1: `drink oil flask` — custom rejection text
```
> get oil flask
You take a small ceramic oil flask.

> drink oil flask
You gag on the thick, acrid oil. That's lamp fuel, not drink. You spit it out,
grimacing.
```
**Result:** Custom `on_drink_reject` text prints correctly. No generic "You can't drink that" message. Flavor text is vivid and appropriate. **PASS** ✅

---

## Remaining Open Issues

### BUG-061 — Still Open (HIGH)
**Fix Required:** In `src/meta/world/storage-cellar.lua` line 28, change:
```lua
{ id = "wine-bottle", location = "wine-rack" },
```
to:
```lua
{ id = "wine-bottle", location = "wine-rack.inside" },
```
This one-line change aligns with the pattern used by `iron-key` (`large-crate.inside`), `cloth-scraps` (`small-crate.inside`), and `candle-stubs` (`small-crate.inside`).

### NEW: Oil Lantern Fueling (Observation)
The oil lantern's `pour`/`fill`/`fuel` transition requires a `lamp-oil` tool, but the parser cannot resolve "pour oil flask into lantern" or similar phrasings. This blocks the entire lantern usage chain (fuel → light → carry). Not a new bug — likely falls under existing parser limitation (similar to BUG-039 "use X on Y" not understood). Flagging as observation for Puzzle 015 test 1.4.

---

## Conclusions

1. **BUG-060 FIX VERIFIED** ✅ — `normalize_effect()` correctly handles both `{type: "wind_effect"}` and `{wind_effect: {...}}` formats. Wind effect fires on deep-cellar → hallway traversal. Candle FSM transitions cleanly. Atmospheric writing is excellent.

2. **BUG-061 FIX INCOMPLETE** ❌ — The wine bottle type_id was fixed (IDs now match: `wine-bottle` everywhere), but the instance `location` field was not updated to use the `.inside` surface suffix. The engine requires explicit `location = "wine-rack.inside"` to place items into container surfaces. This is a one-line fix.

3. **BUG-062 FIX VERIFIED** ✅ — The drink handler's fallback correctly checks `on_drink_reject` before printing generic text. Oil flask produces vivid custom rejection.

**Net result:** 4 of 11 previously-failing tests now pass. 6 remain blocked by BUG-061 (one-line data fix needed). 1 blocked by parser limitation (oil lantern fueling).
