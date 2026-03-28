# Pass-061: Full Crafting Loop — Phase 4 Critical Path

**Date:** 2026-03-28
**Tester:** Nelson
**Build:** `lua src/main.lua --headless`
**Method:** Headless pipe-based testing (Pattern 1 from SKILL.md)
**Scope:** Phase 4 critical path end-to-end: bedroom → cellar → hallway → kill wolf → butcher → cook → eat → kill spider → craft bandage → apply → heal

---

## Executive Summary

| Metric | Value |
|--------|-------|
| **Total Tests** | 24 |
| **✅ PASS** | 12 |
| **❌ FAIL** | 10 |
| **⚠️ WARN** | 2 |
| **Critical Bugs** | 3 |
| **High Bugs** | 3 |
| **Medium Bugs** | 3 |
| **Low Bugs** | 2 |

**VERDICT: ❌ PHASE 4 CRITICAL PATH IS BLOCKED.**

The full crafting loop cannot be completed end-to-end. Three critical blockers prevent progression:
1. The **butcher-knife is not placed in any room** — wolf butchery is impossible
2. **Wolf combat is consistently lethal** — player dies from accumulated injuries every fight
3. **Crafted silk-bandages are not placed in inventory** — crafting output goes to floor, player can't use before dying

The kill→butcher→cook→eat loop is **completely broken**. The kill→silk→craft→bandage→heal loop is **partially broken** (crafting works but output inventory placement fails, and venom kills player before bandage can be applied).

---

## Bug Summary

| Issue | Severity | Summary | Blocks |
|-------|----------|---------|--------|
| [#351](https://github.com/WayneWalterBerry/MMO/issues/351) | CRITICAL | Butcher-knife not placed in any Level 1 room | Wolf→meat→cook→eat |
| [#352](https://github.com/WayneWalterBerry/MMO/issues/352) | CRITICAL | Wolf combat consistently lethal — player dies every fight | Wolf→butcher→cook→eat |
| [#353](https://github.com/WayneWalterBerry/MMO/issues/353) | CRITICAL | Crafted silk-bandages not placed in player inventory | Craft→apply→heal |
| [#354](https://github.com/WayneWalterBerry/MMO/issues/354) | HIGH | "kill" verb not recognized by parser | Common player phrase |
| [#355](https://github.com/WayneWalterBerry/MMO/issues/355) | HIGH | Kitchen inaccessible — east door latched from inside, no keyhole | Alternate butcher-knife path |
| [#356](https://github.com/WayneWalterBerry/MMO/issues/356) | HIGH | Spider drops 2 identical silk-bundles — disambiguation failure | Take silk after spider kill |
| [#357](https://github.com/WayneWalterBerry/MMO/issues/357) | MEDIUM | Butcher error says "You need a knife" — player HAS a knife | Misleading feedback |
| [#358](https://github.com/WayneWalterBerry/MMO/issues/358) | MEDIUM | "stab" verb only targets self, not creatures | Combat verb gap |
| [#359](https://github.com/WayneWalterBerry/MMO/issues/359) | MEDIUM | Combat text grammar errors — "the organs gives way", "someone" | Polish |
| [#360](https://github.com/WayneWalterBerry/MMO/issues/360) | LOW | Venom damage accumulates faster than player can craft+apply bandage | Balance tuning |
| [#361](https://github.com/WayneWalterBerry/MMO/issues/361) | LOW | "light candle" auto-sequence consumes extra match (grabs spent match first) | Minor waste |

---

## Individual Tests

### T-001: Feel around (bedroom start)
**Input:** `feel around`
**Response:** Lists 11 objects including bed, nightstand, wardrobe, rug, trap door, windows, curtains, chamber pot, oak door.
**Verdict:** ✅ PASS — Comprehensive tactile room scan in darkness.

---

### T-002: Search nightstand → get candle + matchbox
**Input:** `search nightstand` → `take candle` → `take matchbox`
**Response:** Finds brass candle holder, glass bottle, poultice, matchbox (with 7 matches). Takes candle and matchbox successfully.
**Verdict:** ✅ PASS — Search, discovery, and take all work correctly.

---

### T-003: Strike match → light candle
**Input:** `strike match` → `light candle`
**Response:** Match strikes with vivid narration. "light candle" auto-sequence: drops candle, looks for match, grabs spent match first, drops it, grabs working match, strikes it, lights candle. Candle lit successfully.
**Verdict:** ⚠️ WARN — Candle lights but auto-sequence grabs spent match before working match, wasting a search step. The "prepare" auto-sequence is clever but slightly wasteful.

---

### T-004: Move bed → lift rug → find brass key
**Input:** `move bed` → `lift rug`
**Response:** "You move a large four-poster bed aside." → "You grab the edge of the threadbare rug and pull it aside... Something clatters to the floor -- a small brass key!"
**Verdict:** ✅ PASS — Two-step puzzle (move bed, lift rug) works perfectly with satisfying narration.

---

### T-005: Take brass key (hands full)
**Input:** `take brass key` (with candle + matchbox in hands)
**Response:** "Your hands are full. Drop something first."
**Verdict:** ✅ PASS — Two-hand inventory constraint correctly enforced.

---

### T-006: Navigate bedroom → cellar (trap door)
**Input:** `open trap door` → `go down`
**Response:** Trap door opens with atmospheric narration, player descends to cellar. Room description shows brazier, barrel, spider, web, exits.
**Verdict:** ✅ PASS — Room transition works. Cellar description is excellent.

---

### T-007: Unlock cellar door with brass key
**Input:** `unlock door`
**Response:** "The brass key slides into the padlock with a precise click. You turn it — the mechanism resists, then yields with a grinding clank. The padlock falls open."
**Verdict:** ✅ PASS — Auto-finds brass key in hand, unlocks padlock. Great narration.

---

### T-008: Open crate in storage cellar (auto-crowbar)
**Input:** `open crate`
**Response:** Auto-drops item, looks for crowbar, pries open crate. "Inside: a heavy sack nestled in straw packing." Searching crate finds "a heavy iron key."
**Verdict:** ✅ PASS — Auto-tool selection for crate opening is impressive. Iron key correctly placed.

---

### T-009: Navigate cellar → storage cellar → deep cellar → hallway
**Input:** Series of unlocks, opens, and directional moves
**Response:** Full navigation path works: cellar → storage cellar → deep cellar → hallway. Each room has distinct atmospheric description.
**Verdict:** ✅ PASS — Complete cellar navigation works end-to-end.

---

### T-010: "kill wolf" verb
**Input:** `kill wolf` (wolf present in room — confirmed by "A wolf paces the room" message)
**Response:** "I'm not sure what you mean. Try 'help' to see what you can do, or describe what you're trying to accomplish."
**Verdict:** ❌ FAIL
**Bug:** "kill" is not registered as a verb alias for "attack". Only `attack` and `fight` are wired. This is the most natural player phrase for combat.

---

### T-011: "kill rat" verb (creature confirmed present)
**Input:** `kill rat` (rat in cellar, confirmed by room description)
**Response:** "I'm not sure what you mean."
**Verdict:** ❌ FAIL
**Bug:** Same as T-010. "kill" is universally unrecognized. Verified in `src/engine/verbs/init.lua` line 470-502: only `handlers["attack"]` and `handlers["fight"]` are registered.

---

### T-012: Attack wolf with knife
**Input:** `attack wolf` (small knife in hand)
**Response:** Full combat plays out with 8-12 exchanges. Wolf dies ("a grey wolf is dead!"). Player takes massive damage: cranium bone cracks, torso vital hits, shoulder bone cracks, arm bone cracks. Player dies immediately after: "Your injuries have overwhelmed you. YOU HAVE DIED."
**Verdict:** ❌ FAIL
**Bug:** Wolf combat is consistently lethal. Tested 3 times — player died every time. The wolf deals too many vital/bone-crack hits during the encounter. Player cannot survive to butcher/loot.

---

### T-013: Combat text quality
**Input:** (observed during T-012 combat)
**Response examples:**
- "A devastating strike to a grey wolf's belly — the organs gives way." (should be "give way")
- "the claws glances off" (should be "glance off")
- "the keratin claws fails to bite" (should be "fail to bite")
- "Someone cuts toward a grey wolf's skull" (should be "You cut" — "Someone" is impersonal)
**Verdict:** ⚠️ WARN
**Bug:** Subject-verb agreement errors throughout combat text. "Someone" used instead of "You" for player actions.

---

### T-014: Butcher wolf with knife
**Input:** `butcher wolf` (small knife in hand, dead wolf carcass present)
**Response:** "You need a knife to butcher this."
**Verdict:** ❌ FAIL
**Bug:** Player IS holding a knife. The error message is misleading. The system requires `butchering` tool capability (only on butcher-knife), but the message implies any knife would work. Should say "You need a butchering knife" or "Your knife isn't suited for butchering."

---

### T-015: Butcher-knife placement
**Input:** (code inspection — `grep butcher-knife src/meta/rooms/`)
**Response:** No matches. The butcher-knife object exists (`src/meta/objects/butcher-knife.lua`) but is NOT referenced in any room definition.
**Verdict:** ❌ FAIL
**Bug:** CRITICAL BLOCKER. The butcher-knife is defined but not placed anywhere in Level 1. Without it, the entire wolf→meat→cook→eat pipeline is impossible.

---

### T-016: Kitchen access (east door in hallway)
**Input:** `open east door` → `go east`
**Response:** "A lighter oak door is locked. It won't budge." → "This door is firmly locked. The latch is on the inside — simple iron, but effective. There's no keyhole to pick."
**Verdict:** ❌ FAIL
**Bug:** Kitchen is inaccessible. Even if butcher-knife were placed in kitchen, player couldn't reach it. No key, no keyhole, latched from inside.

---

### T-017: Attack spider with knife
**Input:** `attack spider` (small knife, cellar)
**Response:** Combat succeeds. Spider dies: "The spider's abdomen splits, spilling a tangle of silk. a large brown spider is dead!" Room now shows "a bundle of spider silk."
**Verdict:** ✅ PASS — Spider combat works. Silk drops correctly on death.

---

### T-018: Take silk bundle (disambiguation)
**Input:** `take silk bundle`
**Response:** "Which do you mean: a bundle of spider silk or a bundle of spider silk?"
**Verdict:** ❌ FAIL
**Bug:** Spider drops 2 silk-bundles with identical names. The disambiguation system asks player to choose between two indistinguishable options. Player cannot differentiate them.

---

### T-019: Craft silk-bandage
**Input:** `craft silk-bandage` (silk-bundle in hand or nearby)
**Response:** "You tear the silk into strips suitable for bandaging wounds."
**Verdict:** ✅ PASS (partial) — Crafting recipe executes and narration plays. However, see T-020 for output bug.

---

### T-020: Crafted silk-bandages in inventory
**Input:** `inventory` (immediately after crafting)
**Response:** "Left hand: (empty), Right hand: (empty)" — No bandages in hands.
**Verdict:** ❌ FAIL
**Bug:** Crafting consumes the silk-bundle but the resulting silk-bandages are not placed in the player's hands. They appear to go to the floor (or vanish). Player's hands are empty after crafting even though they were empty before.

---

### T-021: Apply silk bandage
**Input:** `apply silk bandage`
**Response:** "You don't have silk bandage."
**Verdict:** ❌ FAIL
**Bug:** Follows from T-020 — bandages aren't in inventory. Player cannot apply what they don't have. Even if they picked them up from floor, the venom/bleeding kills them first (see T-022).

---

### T-022: Spider venom survival window
**Input:** (observed across multiple spider combat runs)
**Response:** After spider combat, player has ~57-73 HP with active bleeding and spreading venom. Venom message: "The numbness creeps past your knee. Your legs feel like they belong to someone else." Player dies within 2-3 commands from accumulated damage.
**Verdict:** ❌ FAIL
**Bug:** The damage accumulation from spider venom + bleeding kills the player before they can complete the craft→take→apply sequence (3+ commands needed). The survival window is too narrow.

---

### T-023: "stab wolf" verb
**Input:** `stab wolf`
**Response:** "You can only stab yourself. (Try: stab self with <weapon>)"
**Verdict:** ❌ FAIL
**Bug:** "stab" should work on creatures (it's a natural combat verb), but it's only mapped to self-infliction.

---

### T-024: Poultice healing (no injuries)
**Input:** `use poultice` (no active injuries)
**Response:** "You break the apothecary's knot and press the poultice against the wound. The crushed herbs spread across the injury, drawing a sharp sting, then a spreading coolness." → Health: "You feel fine. No injuries to speak of."
**Verdict:** ✅ PASS — Poultice applies and heals. (Note: it consumed the poultice even without injuries, which is mildly wasteful but not a bug per se.)

---

## Phase 4 Critical Path Status

| Step | Action | Status | Blocker |
|------|--------|--------|---------|
| 1 | Start in bedroom, get brass key | ✅ Works | — |
| 2 | Navigate to cellar, unlock doors | ✅ Works | — |
| 3 | Navigate cellar → hallway | ✅ Works | — |
| 4 | Kill wolf | ⚠️ Partial | Player dies every time (balance) |
| 5 | Butcher wolf with knife | ❌ BLOCKED | Butcher-knife not in any room |
| 6 | Get wolf-meat + wolf-bone + wolf-hide | ❌ BLOCKED | Cannot butcher |
| 7 | Cook wolf-meat (fire source) | ❌ BLOCKED | No wolf-meat available |
| 8 | Eat cooked-wolf-meat → verify healing | ❌ BLOCKED | No cooked meat |
| 9 | Kill spider | ✅ Works | — |
| 10 | Get silk-bundle | ⚠️ Partial | Disambiguation bug with 2 identical drops |
| 11 | Craft silk-bandage | ⚠️ Partial | Crafting runs but output not in inventory |
| 12 | Use bandage → verify healing | ❌ BLOCKED | Bandage not in hands, venom kills first |

**Steps completed:** 5 of 12 (42%)
**Steps blocked:** 5 of 12 (42%)
**Steps partial:** 2 of 12 (17%)

---

## Recommendations (Priority Order)

1. **Place butcher-knife in a Level 1 room** — Kitchen (if accessible) or storage-cellar shelf are logical locations
2. **Register "kill" as verb alias for "attack"** — Single line fix: `handlers["kill"] = handlers["attack"]`
3. **Fix crafting output placement** — Crafted items should go to player's empty hand slots, overflow to floor
4. **Reduce wolf damage or increase player HP** — Wolf fight is 100% lethal with starter knife
5. **Fix silk-bundle disambiguation** — Either drop 1 bundle, or give them distinguishing names ("a large bundle of spider silk", "a small bundle of spider silk")
6. **Widen spider venom survival window** — Reduce venom tick rate or add a grace period post-combat
7. **Fix butcher error message** — "You need a butchering knife" not "You need a knife"
8. **Add "kill" alias** — Quick parser fix
9. **Fix combat grammar** — "the organs give way" not "gives way"

---

## Sign-off

Phase 4 critical path playtest complete. The crafting loop is **not viable** in its current state. Navigation and room exploration are solid. Combat triggers work (via "attack") but balance and missing items block progression.

— **Nelson**, Tester
2026-03-28
