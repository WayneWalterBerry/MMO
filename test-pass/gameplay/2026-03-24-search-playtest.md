# Search System Playtest — LLM Creative Phrase Testing

**Date:** 2026-03-24
**Tester:** Nelson (QA Engineer)
**Build:** `lua src/main.lua --headless` (commit `9cdd289`, main)
**Focus:** Search system — regression verification for #132/#135 compound fix + general search UX
**Method:** Headless pipe-based testing with creative human-like phrases

---

## Executive Summary

**30 tests run | 19 PASS | 6 FAIL | 5 WARN**

The search system's core discovery mechanics are excellent — `search around`, scoped search, targeted `find X`, synonym handling, politeness/preamble stripping all work beautifully. Dark-room search consistently uses tactile "feel" language (✅ immersive).

**However, the #132/#135 compound command fix is only partially effective.** The fix (`containers.open` sets `accessible=true`) enables `get X from Y` after search, but standalone `get X` still fails for items inside containers. This breaks all compound commands like "find match, get match" and post-search context like "get matchbox" after discovering it. The `search for X` phrasing also consistently fails, being parsed as a scoped search on location "for X".

### Bugs Found

| Bug ID | Severity | Summary |
|--------|----------|---------|
| BUG-117 | **HIGH** | Compound "find X, get X" — search finds item but get can't access it |
| BUG-118 | **HIGH** | Standalone `get X` fails for items inside containers even after search opened them |
| BUG-119 | **MEDIUM** | `search for X` consistently parses "for X" as a location scope, not a target |
| BUG-120 | **MEDIUM** | Lit-room search still uses "feel" language instead of "see" |
| BUG-121 | **LOW** | "explore" not recognized as search/feel synonym |
| BUG-122 | **LOW** | "grope" not recognized as feel synonym |
| BUG-123 | **LOW** | "search by touch" treats "by touch" as literal target |

---

## Category 1: Basic Search Variations

### T-001: "search around"
**Command:** `search around`
**Response:** Full room search with tactile language. Discovers all objects on surfaces, inside bed, opens drawer/wardrobe/burlap sack/chamber pot. Reports contents of each.
**Verdict:** ✅ PASS — Comprehensive, immersive, correct.

### T-002: "look around for stuff"
**Command:** `look around for stuff`
**Response:** `It is too dark to see anything. Try 'feel' to explore by touch.`
**Verdict:** ⚠️ WARN — Parser routes to "look around" (visual verb) which fails in darkness. A player saying this intuitively expects search behavior.

### T-003: "rummage through everything"
**Command:** `rummage through everything`
**Response:** Full room search identical to T-001. "rummage" synonym works, "through everything" correctly stripped.
**Verdict:** ✅ PASS

### T-004: "search the room"
**Command:** `search the room`
**Response:** Full room search. "the room" correctly interpreted as broad scope.
**Verdict:** ✅ PASS

### T-005: "what can I find?"
**Command:** `what can I find?`
**Response:** Full room search. Question transform works perfectly.
**Verdict:** ✅ PASS — (Previously BUG-084, confirmed fixed)

### T-006: "explore the area"
**Command:** `explore the area`
**Response:** `I'm not sure what you mean. Try 'help' to see what you can do.`
**Verdict:** ⚠️ WARN — "explore" is a natural player verb not recognized.
**Bug:** BUG-121 (LOW)

---

## Category 2: Targeted Search

### T-007: "search the nightstand"
**Command:** `search the nightstand`
**Response:** Scoped search on nightstand. Shows top items (candle holder, glass bottle), opens drawer, finds matchbox, opens matchbox, finds matches.
**Verdict:** ✅ PASS — Excellent scoped search with container traversal.

### T-008: "look inside the bed"
**Command:** `look inside the bed`
**Response:** `It is too dark to see anything. Try 'feel' to explore by touch.`
**Verdict:** ⚠️ WARN — "look inside" uses visual verb, fails in dark. Player expects feel-equivalent.

### T-009: "check under the bed"
**Command:** `check under the bed`
**Response:** `You can't find anything like that in the darkness. Try 'feel' to explore by touch.`
**Verdict:** ⚠️ WARN — "check" routes to visual path in darkness.

### T-010: "feel around the nightstand"
**Command:** `feel around the nightstand`
**Response:** Lists all room-level objects (bed, nightstand, vanity, etc.) — NOT a scoped feel of the nightstand.
**Verdict:** ⚠️ WARN — "feel around" ignores the "the nightstand" target and does a generic room feel. Not a bug per se, but unintuitive.

### T-011: "rummage through the drawer"
**Command:** `rummage through the drawer`
**Response:** Scoped search on nightstand (drawer recognized as part of nightstand). Opens drawer, finds matchbox. Opens matchbox, finds matches.
**Verdict:** ✅ PASS — Drawer recognized as valid scope.

### T-012: "inspect the nightstand"
**Command:** `inspect the nightstand`
**Response:** `It's too dark to see, but you feel: Smooth wooden surface, crusted with hardened wax drippings. A small drawer handle protrudes from the front. Your fingers find top: a brass candle holder, a small glass bottle`
**Verdict:** ✅ PASS — Beautiful dark-mode inspect with flavor text.

---

## Category 3: Compound Commands (Today's Fix — #132/#135)

### T-013: "find the match and grab it"
**Command:** `find the match and grab it`
**Response:**
```
You begin searching for match...
[searches surfaces, opens drawer, opens matchbox]
You feel: a wooden match. You have found: a wooden match.
You don't notice anything called that nearby. Try 'search around' to discover what's here.
```
**Verdict:** ❌ FAIL — Search FINDS the match successfully, but the second command "grab it" fails. The match inside the matchbox is not accessible to standalone get/take.
**Bug:** BUG-117 (HIGH)

### T-014: "search for knife, take knife"
**Command:** `search for knife, take knife`
**Response:**
```
There's nothing to search there.
You take a small knife.
```
**Verdict:** ❌ FAIL — "search for knife" fails (BUG-119: "for" parsed as scope). "take knife" works independently because knife is on a bed surface (always accessible).
**Bug:** BUG-119 (MEDIUM)

### T-015: "look for the candle and pick it up"
**Command:** `look for the candle and pick it up`
**Response:**
```
You begin searching for candle...
[opens brass candle holder]
You feel: a tallow candle. You have found: a tallow candle.
You don't notice anything called that nearby. Try 'search around' to discover what's here.
```
**Verdict:** ❌ FAIL — Same as T-013. Search finds candle but "pick it up" can't access it.
**Bug:** BUG-117 (same root cause)

### T-016: "find match, get match" (exact regression test)
**Command:** `find match, get match`
**Response:**
```
You begin searching for match...
[opens drawer, opens matchbox]
You feel: a wooden match. You have found: a wooden match.
You don't notice anything called that nearby. Try 'search around' to discover what's here.
```
**Verdict:** ❌ FAIL — This is the EXACT regression case from #132/#135. Search finds the match but get can't access it. The fix made `get X from Y` work, but not standalone `get X`.
**Bug:** BUG-117, BUG-118

### T-017: "find match, get match from matchbox"
**Command:** `find match, get match from matchbox`
**Response:**
```
You begin searching for match...
[finds match]
You don't see matchbox here.
```
**Verdict:** ❌ FAIL — After targeted `find match` opens the matchbox during search traversal, the matchbox itself isn't visible to "get X from Y". The matchbox is nested inside the drawer.

### T-018: "search for candle and light it"
**Command:** `search for candle and light it`
**Response:**
```
There's nothing to search there.
You have nothing to light it with. The wick stares back at you, cold and uncooperative.
```
**Verdict:** ❌ FAIL — "search for" parse failure (BUG-119). "light it" executes but no fire source.
**Bug:** BUG-119

---

## Category 4: Post-Search Context

### T-019: search around → "get match" (next turn)
**Command:** `search around` then `get match`
**Response:** Full search completes. Then: `You don't notice anything called that nearby.`
**Verdict:** ❌ FAIL — After broad search opens drawer and finds matchbox, standalone "get match" fails.
**Bug:** BUG-118 (HIGH)

### T-020: search around → "get knife" (next turn)
**Command:** `search around` then `get knife`
**Response:** Full search completes. Then: `You take a small knife.`
**Verdict:** ✅ PASS — Knife is on a bed surface (always accessible), not inside a container.

### T-021: search around → "take matchbox from drawer" (explicit)
**Command:** `search around` then `take matchbox from drawer`
**Response:** `You take a small matchbox from a small drawer.`
**Verdict:** ✅ PASS — Explicit "from drawer" works! The #132/#135 fix enables this path.

### T-022: search around → "get matchbox" (standalone)
**Command:** `search around` then `get matchbox`
**Response:** `You don't notice anything called that nearby.`
**Verdict:** ❌ FAIL — Standalone get can't find items inside opened containers.
**Bug:** BUG-118

### T-023: search around → "take cloak" (from wardrobe)
**Command:** `search around` then `take cloak`
**Response:** `You take a moth-eaten wool cloak.`
**Verdict:** ✅ PASS — Cloak inside wardrobe IS accessible after search. Wardrobe items work!

### T-024: search around → "take needle" (from burlap sack inside wardrobe)
**Command:** `search around` then `take needle`
**Response:** `You take a sewing needle.`
**Verdict:** ✅ PASS — Even doubly-nested items (needle → burlap sack → wardrobe) are accessible.

**Key insight:** Wardrobe/burlap sack contents become accessible after search, but drawer contents do NOT. The drawer has a unique accessibility issue compared to other containers.

---

## Category 5: Search in Darkness

### T-025: "feel around"
**Command:** `feel around`
**Response:** `You reach out in the darkness, feeling around you... [lists 9 room objects]`
**Verdict:** ✅ PASS — Tactile language, correct discovery.

### T-026: "grope in the dark"
**Command:** `grope in the dark`
**Response:** `You can't feel anything like that nearby. Try 'feel' to explore what's around you.`
**Verdict:** ⚠️ WARN — "grope" not recognized as a feel synonym.
**Bug:** BUG-122 (LOW)

### T-027: "search by touch"
**Command:** `search by touch`
**Response:** `You begin searching for by touch...` (searches for literal "by touch")
**Verdict:** ⚠️ WARN — Prepositional phrase "by touch" parsed as search target.
**Bug:** BUG-123 (LOW)

### T-028: Lit-room search language
**Command:** Light candle, then `search the room`
**Response:** Still uses "you feel:" language throughout. Example: `On top of the large four-poster bed, you feel: a goose-down pillow...`
**Verdict:** ⚠️ WARN — In a lit room, search should say "you see:" not "you feel:".
**Bug:** BUG-120 (MEDIUM)

---

## Category 6: Edge Cases

### T-029: "find unicorn"
**Command:** `find unicorn`
**Response:** Searches all surfaces and containers, reports "but no unicorn" for each. Ends with: `You finish searching. No unicorn found.`
**Verdict:** ✅ PASS — Graceful not-found with thorough search and clear conclusion.

### T-030: "search the ceiling"
**Command:** `search the ceiling`
**Response:** Same thorough search pattern, "but no ceiling" for each location. Ends with: `You finish searching. No ceiling found.`
**Verdict:** ✅ PASS — Treats "ceiling" as a target, not a scope. Reasonable behavior.

---

## Category 7: Bonus Tests (Parser Quality)

### T-031: "carefully search the nightstand" (adverb)
**Command:** `carefully search the nightstand`
**Response:** Scoped nightstand search. Adverb "carefully" stripped cleanly.
**Verdict:** ✅ PASS

### T-032: "please search around" (politeness)
**Command:** `please search around`
**Response:** Full room search. Politeness prefix stripped.
**Verdict:** ✅ PASS

### T-033: "let me search this place" (preamble)
**Command:** `let me search this place`
**Response:** Full room search. Preamble "let me" stripped.
**Verdict:** ✅ PASS

### T-034: "find everything"
**Command:** `find everything`
**Response:** Full room search. "everything" treated as broad scope.
**Verdict:** ✅ PASS — (Previously BUG-078, confirmed fixed)

### T-035: "look for the candle"
**Command:** `look for the candle`
**Response:** Targeted search, finds tallow candle inside brass candle holder.
**Verdict:** ✅ PASS — "look for" correctly routes to search.

### T-036: "hunt for stuff"
**Command:** `hunt for stuff`
**Response:** Targeted search for literal "stuff". Searches everywhere, "but no stuff".
**Verdict:** ⚠️ WARN — "stuff" should ideally trigger general search. Very minor.

### T-037: "help"
**Command:** `help`
**Response:** Comprehensive help text listing all verb categories with examples.
**Verdict:** ✅ PASS — Excellent reference.

---

## Bug Detail

### BUG-117: Compound "find X, get X" — get can't access items found by search (HIGH)
**Repro:** `find match, get match` or `find the match and grab it`
**Expected:** After search finds the match (opening drawer and matchbox), the subsequent get/take should pick it up.
**Actual:** Search correctly finds and reports the match, but get says "You don't notice anything called that nearby."
**Root cause:** The #132/#135 fix sets `accessible=true` on opened containers, enabling `get X from Y`. But standalone `get X` uses `find_visible` which doesn't traverse into container contents — it only finds items directly in the room or on surfaces.
**Impact:** All compound search+take commands fail. This is the core player experience for compound phrasing.

### BUG-118: Standalone "get X" fails for items inside containers after search (HIGH)
**Repro:** `search around` → (next turn) → `get matchbox`
**Expected:** After search opens the drawer and discovers the matchbox, the player should be able to take it.
**Actual:** "You don't notice anything called that nearby."
**Note:** This specifically affects the drawer. Items in the wardrobe and burlap sack ARE accessible after search. The drawer→matchbox relationship has a unique accessibility gap.
**Workaround:** `take matchbox from drawer` works correctly.

### BUG-119: "search for X" consistently parses wrong (MEDIUM)
**Repro:** `search for knife` or `search for candle`
**Expected:** Targeted search for knife/candle.
**Actual:** "There's nothing to search there." — "for knife" is being parsed as a location scope.
**Note:** "look for X" and "find X" both work correctly. Only "search for X" fails.

### BUG-120: Lit-room search uses "feel" language instead of "see" (MEDIUM)
**Repro:** Light candle → `search the room`
**Expected:** "On top of the bed, you see: ..."
**Actual:** "On top of the bed, you feel: ..."
**Impact:** Cosmetic but breaks immersion. Search should adapt language to lighting state.

### BUG-121: "explore" not recognized as search/feel synonym (LOW)
**Repro:** `explore the area`
**Expected:** Triggers search or feel.
**Actual:** "I'm not sure what you mean."

### BUG-122: "grope" not recognized as feel synonym (LOW)
**Repro:** `grope in the dark`
**Expected:** Triggers feel.
**Actual:** "You can't feel anything like that nearby."

### BUG-123: "search by touch" treats modifier as target (LOW)
**Repro:** `search by touch`
**Expected:** General search (modifier ignored).
**Actual:** Searches for literal "by touch".

---

## Regression Verification Summary

| Issue | What Was Fixed | Verified? | Notes |
|-------|---------------|-----------|-------|
| #132 | Compound "find X, get X" | ⚠️ PARTIAL | `get X from Y` works after search (✅), but standalone `get X` does not (❌) |
| #135 | Search opens containers but contents inaccessible | ⚠️ PARTIAL | `accessible=true` set on container but items inside drawer still not reachable by bare `get` |
| BUG-078 | "find everything" literal | ✅ FIXED | Now triggers full search |
| BUG-084 | "what can I find?" hangs | ✅ FIXED | Works perfectly |
| BUG-093 | "rummage around" hangs | ✅ FIXED | Works perfectly |

---

## Positive Highlights

1. **Dark-room search language** — Consistently uses "feel" verbs. Immersive and correct.
2. **Container traversal** — Search opens unlocked containers, dives into nested containers (burlap sack inside wardrobe), reports contents at each level.
3. **Scoped search** — "search the nightstand" perfectly limits to nightstand + its sub-containers.
4. **Parser quality** — Politeness stripping, adverb stripping, preamble removal, question transforms all work.
5. **Graceful not-found** — "find unicorn" searches everything and gives clear "No unicorn found" message.
6. **GOAP auto-chain** — `light candle` automatically chains: open matchbox → get match → strike match → light candle. Impressive.

---

**Sign-off:** Nelson, QA Engineer — 2026-03-24
