# Brass Spittoon Playtest — Nelson

**Date:** 2026-03-24
**Tester:** Nelson (QA Engineer)
**Build:** Lua src/main.lua --headless
**Object Under Test:** `src/meta/objects/brass-spittoon.lua`
**Unit Tests:** 71/71 PASS (object definition fully verified)

## Executive Summary

| Metric | Count |
|--------|-------|
| Total Tests | 21 |
| ✅ PASS | 10 |
| ❌ FAIL | 9 |
| ⚠️ WARN | 2 |
| Bugs Filed | 2 |

**Verdict: BLOCKED — Object Not Placed in Game World**

The brass spittoon (`brass-spittoon.lua`) is a fully implemented object with all 5 senses, FSM states, container behavior, wearable metadata, and helmet properties. All 71 unit tests pass. However, **it has no room instance** — the object blueprint exists but was never spawned into any room's `instances` table. Every in-game interaction test fails because the spittoon simply doesn't exist in the world.

The ceramic chamber pot (comparison baseline) works perfectly: all senses, wear, mirror, hit-head, and drop-shatter confirmed functional. The engine is ready for the spittoon — it just needs to be placed.

## Bug List

| Bug ID | Severity | Summary |
|--------|----------|---------|
| BUG-147 | **HIGH** | Brass spittoon not placed in any game room — object file exists but no room instance |
| BUG-148 | **LOW** | "brass bowl" keyword may collide with "brass candle holder" when both are in same room |

---

## Scenario 1: Find the Spittoon

### T-001: "search for the spittoon"
**Command:** `search for the spittoon`
**Response:**
```
You begin searching for spittoon...
On top of the large four-poster bed, you feel: ... but no spittoon.
Inside the large four-poster bed, you feel: ... but no spittoon.
[...searches every object in room...]
You finish searching. No spittoon found.
```
**Verdict:** ❌ FAIL
**Bug:** BUG-147 — Object not placed in any room. Search system correctly recognizes keyword "spittoon" and methodically searches all surfaces/containers but finds nothing.

### T-002: "look for a brass bowl"
**Command:** `look for a brass bowl`
**Response:**
```
You begin searching for brass bowl...
[...searches everything...]
You finish searching. No brass bowl found.
```
**Verdict:** ❌ FAIL
**Bug:** BUG-147 — Keyword "brass bowl" recognized by parser. Search traversal correct. Object absent from world.

### T-003: "find the cuspidor"
**Command:** `find the cuspidor`
**Response:**
```
You begin searching for cuspidor...
[...searches everything...]
You finish searching. No cuspidor found.
```
**Verdict:** ❌ FAIL
**Bug:** BUG-147 — Formal synonym "cuspidor" works perfectly in parser. Still no object to find.

**Parser Note:** ✅ All three keywords (spittoon, brass bowl, cuspidor) are correctly recognized by the search system. The parser resolves them properly — the problem is purely that no instance exists.

---

## Scenario 2: Examine It (All 5 Senses)

### T-004: "look at the spittoon" (lit room)
**Command:** `look at the spittoon` (after lighting candle)
**Response:** `You don't notice anything called that nearby.`
**Verdict:** ❌ FAIL
**Bug:** BUG-147

### T-005: "examine the brass bowl" (lit room)
**Command:** `examine the brass bowl` (after lighting candle)
**Response:** `Cool brass, tarnished and slightly rough. The stem is ridged for grip. Hardened wax drippings cling to the base like frozen tears.`
**Verdict:** ⚠️ WARN
**Bug:** BUG-148 — "brass bowl" resolves to the **brass candle holder** (also brass, also in room). When the spittoon IS placed in the same room, keyword disambiguation will need testing.

### T-006: "smell the spittoon"
**Command:** `smell the spittoon`
**Response:** `You can't find anything like that to smell.`
**Verdict:** ❌ FAIL — Object absent. (Expected: "Stale tobacco, old saliva, and tarnished brass. A cocktail nobody ordered.")

### T-007: "feel the spittoon"
**Command:** `feel the spittoon`
**Response:** `You can't feel anything like that nearby.`
**Verdict:** ❌ FAIL — Object absent. (Expected: "Heavy, cold brass. The rolled rim is smooth...")

### T-008: "listen to the spittoon"
**Command:** `listen to the spittoon`
**Response:** `You can't hear anything like that.`
**Verdict:** ❌ FAIL — Object absent. (Expected: "A resonant *bong* when flicked...")

### T-009: "taste the spittoon"
**Command:** `taste the spittoon`
**Response:** `You can't find anything like that to taste.`
**Verdict:** ❌ FAIL — Object absent. (Expected: "tarnish tastes of pennies and regret")

**Note:** All 5 sense descriptions ARE defined in the object file and verified by unit tests 53–63. They just can't be exercised in-game.

---

## Scenario 3: Wear as Helmet

### T-010: "put the spittoon on my head"
**Command:** `put the spittoon on my head`
**Response:** `You aren't holding that.`
**Verdict:** ❌ FAIL — Can't hold what doesn't exist. Parser parsed "put X on head" correctly.

### T-011: "wear the cuspidor"
**Command:** `wear the cuspidor`
**Response:** `You aren't holding that.`
**Verdict:** ❌ FAIL — Same. "cuspidor" recognized but no target object.

---

## Scenario 4: Container Behavior

**Status:** BLOCKED — Cannot test `put match in spittoon` because the spittoon doesn't exist in the game world. Container capacity (2) verified by unit tests 26–30.

---

## Scenario 5: Durability (Brass = Fragility 0.1)

**Status:** BLOCKED — Cannot drop or hit the spittoon. Brass fragility (0.1) confirmed by unit test 48. Material dent behavior defined in FSM transitions (unit tests 39–44).

---

## Scenario 6: Compare with Ceramic Pot (Baseline)

The chamber pot IS placed in the bedroom and serves as the working baseline for all wearable-container-helmet mechanics.

### T-012: "look at the chamber pot" (lit room)
**Command:** `look at the chamber pot`
**Response:**
```
A squat ceramic chamber pot with the quiet dignity of an object that knows
exactly what it is for. It is mercifully empty, glazed in a chipped
blue-and-white pattern that suggests someone once thought aesthetics mattered
even here.

It is, thankfully, empty.
```
**Verdict:** ✅ PASS — Beautiful description. Container shows empty state.

### T-013: "smell the chamber pot"
**Command:** `smell the chamber pot`
**Response:** `You'd rather not. Even empty, the memory of its purpose lingers.`
**Verdict:** ✅ PASS — Character-appropriate refusal with flavor.

### T-014: "feel the chamber pot"
**Command:** `feel the chamber pot`
**Response:** `A ceramic bowl, smooth-glazed and cold. The rim is chipped in places.`
**Verdict:** ✅ PASS — Material-appropriate tactile description.

### T-015: "listen to the chamber pot"
**Command:** `listen to the chamber pot`
**Response:** `a ceramic chamber pot makes no sound.`
**Verdict:** ✅ PASS — Reasonable. (Minor: lowercase article in object name)

### T-016: "taste the chamber pot"
**Command:** `taste the chamber pot`
**Response:** `You give a ceramic chamber pot a cautious lick. Nothing remarkable.`
**Verdict:** ✅ PASS — Appropriately disgusting attempt acknowledged.

### T-017: "get the chamber pot" + "wear the chamber pot"
**Command:** `get the chamber pot` then `wear the chamber pot`
**Response:**
```
You take a ceramic chamber pot.
You put on a ceramic chamber pot.
This is going to smell worse than I thought.
```
**Verdict:** ✅ PASS — Pickup and equip work. Smell narration on wear.

### T-018: "look in the mirror" (wearing pot)
**Command:** `look in the mirror` (with chamber pot worn)
**Response:** `In the mirror, you see: A ceramic chamber pot sits absurdly atop your head. Your left hand grips a small matchbox. You appear healthy and alert.`
**Verdict:** ✅ PASS — Mirror reflects worn equipment. Appearance description works.

### T-019: "hit head" (wearing pot)
**Command:** `hit head` (with chamber pot worn)
**Response:**
```
You slam your fist against your helmeted head. The impact rattles you
even through the protection. Stars flash across your vision...

Your eyes flutter open. Your head throbs with a dull, persistent ache.
Stars still dance at the edges of your vision.
```
**Verdict:** ✅ PASS — Hit recognized, concussion system engaged, pot absorbs some damage but player still stunned. Engine helmet detection works.

### T-020: "drop the chamber pot" (ceramic durability)
**Command:** `drop the chamber pot`
**Response:** `The ceramic chamber pot shatters on the stone floor, sending fragments skittering across the room.`
**Verdict:** ✅ PASS — Ceramic (fragility 0.7) shatters on stone floor as expected. This is the behavior the brass spittoon (fragility 0.1) should NOT exhibit when tested.

### T-021: "put match in the chamber pot" (container)
**Command:** `put the match in the chamber pot`
**Response:** `You need to be holding that to put it somewhere.`
**Verdict:** ⚠️ WARN — Match had already burned out (became "spent match" on floor). Not a container bug — player state issue. Container capacity verified by unit tests.

---

## Summary of Findings

### What Works (Engine Ready)
- ✅ **Search system:** All keywords (spittoon, brass bowl, cuspidor) parsed correctly
- ✅ **Parser:** "wear X", "put X on head", "search for X", "examine X" all route correctly
- ✅ **Chamber pot baseline:** All wearable/container/helmet/mirror/durability mechanics confirmed functional
- ✅ **Unit tests:** 71/71 pass — object definition is complete and correct
- ✅ **Material system:** Brass (fragility 0.1) registered, ceramic (fragility 0.7) shatters on drop

### What's Missing
- ❌ **BUG-147:** The spittoon has no room instance. It needs one line added to a room file:
  ```lua
  { id = "brass-spittoon", type = "a brass spittoon", type_id = "{b763fdf9-f7d2-4eac-8952-7c03771c5013}" },
  ```
- ⚠️ **BUG-148:** When placed, "brass bowl" may collide with "brass candle holder" — needs disambiguation test

### Recommendation

**Place the spittoon in a room** (hallway or cellar would fit thematically — a saloon fixture in a manor corridor or tucked in a cellar corner). Then re-run this test pass. Every T-001 through T-011 should flip from FAIL to PASS once the instance exists. The engine is ready.

---

*Nelson — QA Engineer*
*"The blueprint is perfect. It just needs a home."*
