# Pass-043: Kill Rat & Verify Corpse Reshape

**Date:** 2026-03-27
**Tester:** Nelson
**Build:** `lua src/main.lua --headless`
**Method:** Headless pipe input (Pattern 1)

## Executive Summary

**Total tests: 8 | ✅ PASS: 6 | ⚠️ WARN: 2 | ❌ FAIL: 0 | 🔴 HANG: 0**

The rat kill → corpse reshape pipeline works end-to-end. The brown rat dies in combat, reshapes to a "dead rat" (small-item template), has sensory text for `feel` and `smell`, is portable, and appears in inventory after `take`. Two warnings noted for combat text quality (duplicate word, unclear subject).

## Bug List

| Bug ID | Severity | Summary |
|--------|----------|---------|
| — | LOW | Combat text: "sinks its teeth into into someone's shoulder" — duplicate "into" |
| — | LOW | Combat text uses "Someone" instead of "you" for the player character |

## Input Script

```
goto cellar
look
attack rat
look
feel dead rat
smell dead rat
take dead rat
inventory
```

## Individual Tests

### T-001: goto cellar
**Input:** `goto cellar`
**Response:**
```
You materialize in The Cellar.
**The Cellar** You stand at the foot of a narrow stone stairway...
There is a brown rat here. An iron brazier glows with dull coals, radiating warmth.
A rat crouches in the shadows near the wall.
```
**Verdict:** ✅ PASS
**Notes:** Player arrives in cellar. Brown rat is present and described. Room description renders correctly.

### T-002: look (pre-combat)
**Input:** `look`
**Response:**
```
**The Cellar** ...
There is a brown rat here. An iron brazier glows with dull coals, radiating warmth.
A panicked rat zigzags across the floor.
```
**Verdict:** ✅ PASS
**Notes:** Rat is alive, has ambient behavior text ("panicked rat zigzags across the floor").

### T-003: attack rat
**Input:** `attack rat`
**Response:**
```
You engage a brown rat with bare fists!
Someone punches a brown rat's shin, but the bone glances off.
A brown rat sinks its teeth into into someone's shoulder, cutting into the flesh.
...
a brown rat is dead!
```
**Verdict:** ⚠️ WARN
**Notes:** Combat resolves correctly — rat dies. However:
1. **Duplicate word:** "sinks its teeth into into someone's shoulder" (double "into")
2. **Subject unclear:** "Someone punches" should be "You punch" for the player character
3. **Material mismatch:** "the bone edge nicks" when fighting bare-fisted — "bone" refers to fists but reads oddly

Core mechanic works. Text polish needed.

### T-004: look (post-combat — corpse reshape verification)
**Input:** `look`
**Response:**
```
**The Cellar**

You stand at the foot of a narrow stone stairway in a low-ceilinged cellar...

A dead rat lies crumpled on the floor. An iron brazier glows with dull coals, radiating warmth.

Exits:
  up: up
  north: north
```
**Verdict:** ✅ PASS — **KEY VERIFICATION POINT**
**Notes:** The live "brown rat" has been replaced by "a dead rat" in the room description. Room presence text is "A dead rat lies crumpled on the floor." — confirms the object reshaped from living rat to dead rat corpse. No trace of the living rat remains.

### T-005: feel dead rat (sensory — on_feel)
**Input:** `feel dead rat`
**Response:**
```
Cooling fur over a limp body. The tail hangs like wet string.
```
**Verdict:** ✅ PASS — **KEY VERIFICATION POINT**
**Notes:** Dead rat has `on_feel` sensory text. Evocative, appropriate for a corpse. Confirms the reshaped object has tactile description (required by Principle 6 / core-principles).

### T-006: smell dead rat (sensory — on_smell)
**Input:** `smell dead rat`
**Response:**
```
Blood and musk. The sharp copper of death.
```
**Verdict:** ✅ PASS — **KEY VERIFICATION POINT**
**Notes:** Dead rat has `on_smell` sensory text. Confirms multi-sensory data survived the reshape.

### T-007: take dead rat (portability)
**Input:** `take dead rat`
**Response:**
```
You take a dead rat.
```
**Verdict:** ✅ PASS — **KEY VERIFICATION POINT**
**Notes:** Dead rat is portable (small-item template). Player can pick it up. Confirms the reshaped corpse object has `takeable` properties.

### T-008: inventory (inventory confirmation)
**Input:** `inventory`
**Response:**
```
  Left hand: a dead rat
  Right hand: (empty)
```
**Verdict:** ✅ PASS — **KEY VERIFICATION POINT**
**Notes:** Dead rat appears in player's left hand. Confirms the take succeeded and the object is properly tracked in inventory.

## Reshape Verification Summary

| Check | Expected | Actual | Status |
|-------|----------|--------|--------|
| Rat dies in combat | "a brown rat is dead!" | ✅ Confirmed | PASS |
| Corpse replaces living rat in room | "A dead rat lies crumpled on the floor." | ✅ Confirmed | PASS |
| Corpse has `on_feel` | Sensory text present | "Cooling fur over a limp body..." | PASS |
| Corpse has `on_smell` | Sensory text present | "Blood and musk..." | PASS |
| Corpse is portable (small-item) | Can be taken | "You take a dead rat." | PASS |
| Corpse appears in inventory | Shows in hand slot | "Left hand: a dead rat" | PASS |
| Living rat absent after death | No "brown rat" in room | ✅ Confirmed | PASS |

## Conclusion

The kill → corpse reshape pipeline is **fully functional**. The brown rat object mutates into a dead rat corpse with correct template (small-item), sensory properties, room presence text, and portability. The Prime Directive (D-14: code mutation IS state change) is working as designed.

Minor combat text polish recommended (duplicate "into", player subject as "Someone").

---
**Nelson — Tester**
*Every bug you find now is a bug the player never sees.*
