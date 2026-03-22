# Puzzle Feedback — Pass 021
**Date:** 2026-03-21  
**Tester:** Nelson  
**From:** Test Pass 021

---

## Testing Status

**Note:** Due to game stability issues (BUG-067: rapid command hang, BUG-068: inventory hang), I was unable to complete puzzle testing as planned. This feedback is based on limited testing before encountering blockers.

---

## Puzzle 015: Candle Draft Extinguish
**Status:** NOT TESTED  
**Reason:** Could not obtain sustained light source (candle) due to inability to navigate beyond bedroom. Match burns out too quickly to test draft mechanics.

**Required for Testing:**
- Need to obtain candle
- Need to light candle
- Need to reach drafty area

**Deferred to next playtest** once stability issues are resolved.

---

## Puzzle 016: Wine Drinking
**Status:** NOT TESTED  
**Reason:** Could not navigate to wine location due to locked door (north) and stability issues preventing exploration.

**Deferred to next playtest** once:
1. BUG-067 (rapid commands) is fixed
2. BUG-068 (inventory) is fixed
3. Navigation is possible

---

## Critical Path Puzzle: Matchbox Discovery
**Status:** ✅ VERIFIED WORKING (BUG-065 FIX)

**The Victory:**
The original blocker (BUG-065) is now FIXED. Players can discover the matchbox via:
```
> feel drawer
Wood, smooth but slightly sticky from old wax. There's a small handle on the front.
Your fingers find inside:
  a small matchbox
```

**Player Experience:** This is now intuitive and discoverable. A new player would:
1. `feel around` → find nightstand
2. `open nightstand` → drawer opens
3. `feel drawer` → discovers matchbox (THE FIX!)
4. `get matchbox` → take it
5. `open matchbox`, `get match`, `light match` → light!

**Excellent progression.** The core darkness-to-light puzzle now works perfectly.

---

## Recommendations

1. **Fix stability bugs first** (BUG-067, BUG-068) before puzzle testing can continue
2. **Re-test Puzzle 015 and 016** in Pass 022 once game is stable
3. **Consider adding hint** if player tries `look` in darkness without a light → suggest `feel around`

---

## Player Journey Observation

**What Works:**
- Darkness is atmospheric and creates tension
- `feel around` is a great discovery mechanic
- Match lighting has beautiful prose ("sputters once, twice -- then catches")
- Match burning out creates urgency

**What's Missing from This Test:**
- Couldn't experience sustained light (candle)
- Couldn't explore multiple rooms
- Couldn't test puzzle interactions

**Overall:** The critical path puzzle (find matchbox in darkness) is now SOLVED with BUG-065 fix. This is a major win. Remaining puzzles await stable build.
