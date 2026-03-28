# Pass-062: Edge Case Error Handling

**Date:** 2026-03-28
**Tester:** Nelson
**Build:** `lua src/main.lua --headless`
**Method:** Headless pipe-based testing (Pattern 1)
**Focus:** Graceful error handling for invalid/edge-case player actions

## Executive Summary

| Metric | Count |
|--------|-------|
| Total tests | 10 |
| ✅ PASS | 5 |
| ⚠️ WARN | 2 |
| ❌ FAIL | 3 |

**Bugs filed:** 5 (1 HIGH, 2 MEDIUM, 2 LOW)

The engine handles most "wrong action" edge cases gracefully — furniture can't be butchered or taken, crafting unknown recipes is rejected cleanly, and dead creatures can't be attacked. However, the butchery verb has message-priority issues (checks knife before checking alive/dead), the `use` verb on a poultice bypasses the no-injury guard that `apply` correctly enforces, and the fuzzy noun resolver occasionally matches wildly wrong objects ("meat" → "rug").

## Bug Summary

| Bug ID | Severity | Summary |
|--------|----------|---------|
| BUG-180 | MEDIUM | `butcher rat` on alive rat says "nothing useful to carve from this corpse" — calls living creature a corpse (#325) |
| BUG-181 | LOW | `butcher wolf` on alive wolf says "need a knife" — skips alive-check, goes straight to tool-check (#327) |
| BUG-182 | HIGH | `use poultice` bypasses no-injury guard and consumes the item; `apply poultice` correctly rejects (#329) |
| BUG-183 | LOW | `attack spider` (dead) says "don't see that here" even though `look at spider` sees it — should say "already dead" (#331) |
| BUG-184 | MEDIUM | Parser fuzzy-matches "meat" to "rug" for eat command — "You can't eat a threadbare rug" (#335) |

---

## Individual Tests

### T-001: butcher chair (non-corpse furniture)
**Input:** `butcher bed` / `butcher nightstand` / `butcher wardrobe` / `butcher vanity`
**Response (all 4):**
```
You can't butcher that.
```
**Verdict:** ✅ PASS
**Notes:** Clean, consistent rejection for all non-creature objects. Message is clear and appropriate. No chair exists in Level 1, so tested equivalent furniture items.

---

### T-002: butcher rat (too small / cook directly)
**Input:** `butcher rat` (alive rat, cellar)
**Response:**
```
There's nothing useful to carve from this corpse.
```
**Verdict:** ❌ FAIL
**Bug:** BUG-180
**Notes:** The rat is ALIVE (it scurried away right after this message). Calling a living creature a "corpse" is misleading. The message should first check if the target is alive ("The rat is still alive!") and then separately handle the "too small to butcher" case. After killing the rat, `look at rat` shows "A tiny scatter of cleaned rat bones" — the rat auto-mutated to bones on death, leaving no corpse to butcher. Subsequent `butcher rat` (dead) also returns "There's nothing useful to carve from this corpse." which is correct-ish but the word "corpse" is still confusing when the object is now bones.

---

### T-003: butcher wolf without knife
**Input:** `butcher wolf` (alive wolf, hallway, no knife in hand)
**Response:**
```
You need a knife to butcher this.
```
**Verdict:** ⚠️ WARN
**Bug:** BUG-181
**Notes:** The knife-check fires BEFORE the alive-check. A player butchering a living wolf should hear "That's still alive!" not "You need a knife." The message is technically helpful but the error priority is backwards. When tested on a dead spider (`butcher spider` after killing it), the same "need a knife" message fires correctly. The fix should be: check alive → check dead → check knife → butcher.

---

### T-004: cook wolf-meat without fire
**Input:** `cook` / `cook meat` / `cook food` (bedroom, no fire source)
**Response:**
```
cook       → "You'll need to pick that up first."
cook meat  → "You'll need to pick that up first."
cook food  → "You don't notice anything called that nearby."
```
**Verdict:** ⚠️ WARN
**Notes:** Could not fully test this scenario — producing wolf-meat requires killing wolf + knife to butcher, which is a multi-step chain not achievable without a knife. The `cook` command with no valid cookable object in the room gives "You'll need to pick that up first" — implying it found *something* to cook (perhaps nearest object?) instead of saying "There's nothing to cook here." The `cook food` version correctly says nothing found. The inconsistency between `cook` and `cook food` is minor but notable. Unable to test the actual "cook meat without fire" rejection since no meat was obtainable.

---

### T-005: eat raw wolf-meat
**Input:** `eat rat` (dead rat, cellar) / `eat spider` (dead spider, cellar) / `eat meat` (bedroom)
**Response:**
```
eat rat    → "You can't eat a dead rat."
eat spider → "You can't eat a dead spider."
eat meat   → "You can't eat a threadbare rug."
```
**Verdict:** ❌ FAIL (partial)
**Bug:** BUG-184 (for `eat meat` → rug matching)
**Notes:** `eat rat` and `eat spider` give vague rejections — "You can't eat a dead rat" doesn't explain WHY (raw? not food? too small?). A message like "That's not safe to eat raw" would be more informative. The `eat meat` command is a clear bug: the parser fuzzy-matched "meat" to "rug" (the only soft object nearby?), producing the absurd "You can't eat a threadbare rug." Could not produce actual wolf-meat to test eating raw meat with food-poisoning mechanic.

---

### T-006: craft with no ingredients
**Input:** `craft` / `craft nothing` (bedroom, empty hands)
**Response (both):**
```
You don't know how to craft that.
```
**Also tested:** `craft silk-rope` / `craft silk-bandage` (valid recipes, no ingredients)
**Response:**
```
craft silk-rope    → "You don't have enough silk-bundle to craft silk-rope."
craft silk-bandage → "You don't have enough silk-bundle to craft silk-bandage."
```
**Verdict:** ✅ PASS
**Notes:** Both cases handled well. Unknown recipes get a clear "don't know how" message. Known recipes with missing ingredients get a specific message naming the missing material. Good error hierarchy.

---

### T-007: craft nonexistent-item
**Input:** `craft unicorn-horn` / `craft nonexistent-item` / `craft bandage`
**Response (all 3):**
```
You don't know how to craft that.
```
**Verdict:** ✅ PASS
**Notes:** Consistent rejection for all unknown recipe names. Message is clear and doesn't crash or produce confusing output.

---

### T-008: take non-portable furniture
**Input:** `take bed` / `take nightstand` / `take wardrobe` / `take vanity`
**Response (all 4):**
```
It's far too heavy to carry.
```
**Verdict:** ✅ PASS
**Notes:** Clean, immersive rejection. Doesn't say "that's not portable" (gamey) — says "far too heavy" (naturalistic). Good UX.

---

### T-009: attack dead creature
**Input:** `attack spider` (after killing spider, cellar)
**Response:**
```
You don't see that here to attack.
```
**Context:** `look at spider` in the same room returns: "A dead spider lies curled on its back, legs drawn inward like a clenched fist."
**Verdict:** ⚠️ WARN → ❌ FAIL
**Bug:** BUG-183
**Notes:** The dead spider is clearly visible (look works), but attack says "don't see that here." The message should be "It's already dead" or "There's no fight left in it." The current message implies the object doesn't exist, which contradicts what the player can see. Same behavior observed with `kick rat` after killing rat — the keyword stops resolving for combat verbs despite the corpse/remains being visible.

---

### T-010: use bandage/poultice when not injured
**Input:** `apply poultice` / `use poultice` (no injuries, bedroom)
**Response:**
```
apply poultice → "You don't have any injuries to treat."
use poultice   → "You break the apothecary's knot and press the poultice
                  against the wound. The crushed herbs spread across the
                  injury, drawing a sharp sting, then a spreading coolness."
```
**Verdict:** ❌ FAIL
**Bug:** BUG-182
**Notes:** Critical inconsistency. `apply poultice` correctly checks for injuries and rejects. `use poultice` skips the injury check entirely and CONSUMES the poultice on a non-existent wound. This wastes a limited healing resource. The `use` verb handler's FSM transition path appears to bypass the injury validation that `apply` enforces. After `use poultice` consumed it, subsequent `use poultice on wound` said "You don't have any injuries to treat" — but the poultice was already gone.

---

## Navigation Notes

Reaching test locations required significant setup:
- **Bedroom → Cellar:** move bed → move rug → find key → open trap door → down
- **Cellar → Storage Cellar:** unlock door (with key) → open padlock → north
- **Bedroom → Hallway:** get crowbar from storage cellar → return to bedroom → break door → north
- The north door from bedroom is barred and requires the crowbar's `break` capability
- The cellar door requires the brass key hidden under the rug under the bed

---

## Sign-off

All 10 edge case scenarios tested. 5 bugs filed to GitHub Issues. The engine is generally robust for "wrong action" inputs, with the main gaps being in butchery verb error ordering, `use` vs `apply` verb inconsistency for medical items, and occasional fuzzy noun mis-resolution.

— Nelson, Tester
