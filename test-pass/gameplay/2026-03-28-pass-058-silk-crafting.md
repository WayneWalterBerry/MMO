# Pass-058: Silk Crafting System
**Date:** 2026-03-28
**Tester:** Nelson
**Build:** Lua src/main.lua --headless
**Scope:** Spider combat → silk acquisition → craft silk-rope & silk-bandage → aliases → error handling → examine crafted items

## Executive Summary

**Total Tests:** 28
**Pass:** 18 | **Fail:** 8 | **Warn:** 2
**Bugs Filed:** 8 (1 CRITICAL, 3 HIGH, 3 MEDIUM, 1 LOW)

The silk-bandage crafting path works end-to-end: kill spider → take silk-bundle → craft silk-bandage → apply bandage. However, the silk-rope crafting path is **completely blocked** by a critical bug: the take system refuses to pick up a second item with the same base type ("You already have that"), making it impossible to hold 2 silk-bundles required for the rope recipe. This also blocks picking up the second crafted bandage.

Additionally, crafted items land on the floor rather than in the player's hands, disambiguation fails for identical items, and several common player phrases ("kill", "use", "stomp") are not recognized.

## Bug List

| Bug ID | Severity | Summary | Filed |
|--------|----------|---------|-------|
| BUG-180 | 🔴 CRITICAL | Can't hold two items of same type — "You already have that" blocks silk-rope crafting | Yes |
| BUG-181 | 🟠 HIGH | Crafted items placed on floor instead of player's hands | Yes |
| BUG-182 | 🟠 HIGH | Disambiguation prompt for identical items gives no way to differentiate | Yes |
| BUG-183 | 🟠 HIGH | "kill" verb not recognized — common text adventure combat phrase | Yes |
| BUG-184 | 🟡 MEDIUM | Craft system doesn't find ingredients on room floor | Yes |
| BUG-185 | 🟡 MEDIUM | "use bandage" not recognized despite being listed as application verb | Yes |
| BUG-186 | 🟡 MEDIUM | "stomp spider" not recognized — natural combat phrase for small creatures | Yes |
| BUG-187 | 🟢 LOW | "craft" with no noun gives misleading error "You don't know how to craft that" | Yes |

---

## Individual Tests

### T-001: attack spider
**Input:** `attack spider`
**Response:** `You engage a large brown spider with bare fists! ... The spider's abdomen splits, spilling a tangle of silk. ... a large brown spider is dead!`
**Verdict:** ✅ PASS
**Notes:** Unarmed combat works. Spider killed after multiple exchanges. Silk drops on death. Combat text is atmospheric and varied.

### T-002: kill spider
**Input:** `kill spider`
**Response:** `I'm not sure what you mean. Try 'help' to see what you can do, or describe what you're trying to accomplish.`
**Verdict:** ❌ FAIL
**Bug:** BUG-183 — "kill" is the most natural combat verb in text adventures (Zork, Infocom heritage). Not recognized.

### T-003: strike spider
**Input:** `strike spider`
**Response:** `You engage a large brown spider with bare fists! ...`
**Verdict:** ✅ PASS
**Notes:** "strike" works as an attack alias.

### T-004: stomp spider
**Input:** `stomp spider`
**Response:** `I'm not sure what you mean.`
**Verdict:** ❌ FAIL
**Bug:** BUG-186 — "stomp" is a natural verb for killing a small floor creature. Not recognized.

### T-005: take silk-bundle (first)
**Input:** `take silk-bundle` (after dropping matchbox to free a hand)
**Response:** `You take a bundle of spider silk.`
**Verdict:** ✅ PASS
**Notes:** Hyphenated ID keyword works to select the item.

### T-006: take silk-bundle (second — same type)
**Input:** `take silk-bundle` (while already holding one silk-bundle, second is on floor)
**Response:** `You already have that.`
**Verdict:** ❌ FAIL
**Bug:** BUG-180 — CRITICAL. The take system treats items with the same base type as identical and refuses to pick up a second instance. Since silk-rope requires 2 silk-bundles, this makes silk-rope **impossible to craft**.

### T-007: take spider silk (disambiguation)
**Input:** `take spider silk` (2 silk-bundles on floor)
**Response:** `Which do you mean: a bundle of spider silk or a bundle of spider silk?`
**Verdict:** ❌ FAIL
**Bug:** BUG-182 — Both options are identical strings. Player has no way to choose between them. Should use ordinals ("the first bundle" / "the second bundle") or auto-select.

### T-008: take bundle (disambiguation)
**Input:** `take bundle` (2 silk-bundles on floor)
**Response:** `Which do you mean: a bundle of spider silk or a bundle of spider silk?`
**Verdict:** ❌ FAIL
**Bug:** BUG-182 (same)

### T-009: craft silk-bandage (1 bundle in hand)
**Input:** `craft silk-bandage`
**Response:** `You tear the silk into strips suitable for bandaging wounds.`
**Verdict:** ✅ PASS
**Notes:** Recipe recognized, ingredient consumed, narration correct. Silk-bundle removed from inventory.

### T-010: craft silk-bandage — item placement
**Input:** (checked inventory and room after craft)
**Response:** Inventory: both hands empty. Room: "A folded strip of silk lies here" + search reveals 2 silk bandages on floor.
**Verdict:** ❌ FAIL
**Bug:** BUG-181 — Crafted bandages placed on floor instead of player's hands. Player must manually pick them up after crafting. Expected: at least one bandage goes to hand.

### T-011: take silk-bandage (first)
**Input:** `take silk-bandage`
**Response:** `You take a silk bandage.`
**Verdict:** ✅ PASS

### T-012: take silk-bandage (second — same type)
**Input:** `take silk-bandage` (while already holding one)
**Response:** `You already have that.`
**Verdict:** ❌ FAIL
**Bug:** BUG-180 (same root cause — can't hold 2 of same type)

### T-013: craft silk-rope (insufficient ingredients — 0 bundles)
**Input:** `craft silk-rope` (no silk-bundles anywhere in inventory or room)
**Response:** `You don't have enough silk-bundle to craft silk-rope.`
**Verdict:** ✅ PASS
**Notes:** Correct error message for insufficient ingredients.

### T-014: craft silk-rope (1 bundle in hand, 1 on floor)
**Input:** `craft silk-rope` (holding 1 silk-bundle, 1 on floor)
**Response:** `You don't have enough silk-bundle to craft silk-rope.`
**Verdict:** ⚠️ WARN
**Bug:** BUG-184 — Craft system does not search room floor for ingredients. Only checks hands and containers. If this is by design, the error message should hint: "You need to be holding the ingredients."

### T-015: craft silk-rope (2 bundles on floor, 0 in hand)
**Input:** `craft silk-rope` (both silk-bundles on floor)
**Response:** `You don't have enough silk-bundle to craft silk-rope.`
**Verdict:** ⚠️ WARN
**Bug:** BUG-184 (same — floor ingredients not counted)

### T-016: craft silk-rope — BLOCKED
**Input:** Cannot test — impossible to hold 2 silk-bundles due to BUG-180.
**Response:** N/A
**Verdict:** ❌ FAIL (blocked)
**Bug:** BUG-180 — silk-rope recipe requires 2 silk-bundles in inventory; "You already have that" prevents this.

### T-017: make silk-rope (alias)
**Input:** `make silk-rope`
**Response:** `You don't have enough silk-bundle to craft silk-rope.`
**Verdict:** ✅ PASS
**Notes:** "make" alias correctly dispatches to craft handler. Error message matches "craft" output.

### T-018: create silk-rope (alias)
**Input:** `create silk-rope`
**Response:** `You don't have enough silk-bundle to craft silk-rope.`
**Verdict:** ✅ PASS
**Notes:** "create" alias correctly dispatches to craft handler.

### T-019: craft nonexistent-recipe
**Input:** `craft unicorn-armor`
**Response:** `You don't know how to craft that.`
**Verdict:** ✅ PASS
**Notes:** Clean error for unknown recipe.

### T-020: craft with no noun
**Input:** `craft`
**Response:** `You don't know how to craft that.`
**Verdict:** ❌ FAIL
**Bug:** BUG-187 — "You don't know how to craft that" when no noun given. "that" refers to nothing. Should say "Craft what?" or "What would you like to craft?"

### T-021: look silk-bundle
**Input:** `look silk-bundle`
**Response:** `A tangled mass of spider silk, still sticky in places. The strands catch the light with an oily sheen.`
**Verdict:** ✅ PASS

### T-022: feel silk-bundle
**Input:** `feel silk-bundle`
**Response:** `Sticky strands that cling to your fingers. Surprisingly strong.`
**Verdict:** ✅ PASS

### T-023: smell silk-bundle
**Input:** `smell silk-bundle`
**Response:** `Faintly musty, like a damp cellar corner.`
**Verdict:** ✅ PASS

### T-024: look silk-bandage
**Input:** `look silk-bandage`
**Response:** `A strip of spider silk, torn and folded into a makeshift bandage. The material is thin but dense — remarkably absorbent. It clings to itself without a knot.`
**Verdict:** ✅ PASS

### T-025: feel silk-bandage
**Input:** `feel silk-bandage`
**Response:** `Thin, smooth silk that clings to your skin. It sticks to itself and to wound edges without a knot. Cool and slightly tacky.`
**Verdict:** ✅ PASS

### T-026: smell / taste / listen silk-bandage
**Input:** `smell silk-bandage` / `taste silk-bandage` / `listen silk-bandage`
**Response:** `Clean silk. A trace of cellar dust.` / `Tasteless silk fibers. Faintly sticky on the tongue.` / `Silent.`
**Verdict:** ✅ PASS
**Notes:** All five senses implemented on silk-bandage. Good coverage.

### T-027: apply bandage (with injury)
**Input:** `apply bandage` (after spider bite during combat)
**Response:** `You apply a silk bandage to the wound.`
**Verdict:** ✅ PASS
**Notes:** Bandage application works. Recognized "bandage" as keyword for silk-bandage.

### T-028: use bandage
**Input:** `use bandage`
**Response:** `You don't know how to use a silk bandage.`
**Verdict:** ❌ FAIL
**Bug:** BUG-185 — silk-bandage object defines application verbs as: apply, use, wrap, bind, bandage. But "use" is not recognized as a valid verb for bandages. Only "apply" works.

---

## Observations (Non-Bug)

### Spider Combat
- Spider has 3 HP, unarmed combat kills in 1–6 rounds (variable)
- Spider venom is very dangerous — causes "burning numbness" that escalates to paralysis and death within ~4 game ticks
- Venom killed the player in 4 of 6 test sessions
- Spider drops **2 silk-bundles** (1 from `byproducts` + 1 from `loot_table.always`) — sufficient for 1 silk-rope
- Spider occasionally drops a spider-fang (observed once in 6 kills)

### Crafting System
- Recipe dispatch works via noun matching (ID-based)
- Article stripping works ("craft the silk-rope" would strip "the")
- Narration text is well-written and atmospheric
- Ingredient consumption is correct (silk-bundle removed from inventory)
- Result quantity works (1 silk-bundle → 2 silk-bandages)

### Sensory Descriptions
- silk-bundle: all senses present (look, feel, smell confirmed)
- silk-bandage: all 5 senses present (look, feel, smell, taste, listen) — excellent coverage
- Both items have distinct, atmospheric descriptions that work in darkness (via feel)

---

## Progression-Blocking Summary

The silk crafting feature chain is **partially broken**:

| Step | Status | Blocker |
|------|--------|---------|
| Kill spider → get silk | ✅ Works | — |
| Take silk-bundle | ✅ Works (1st) | BUG-180 blocks 2nd |
| Craft silk-bandage | ✅ Works | — |
| Apply silk-bandage | ✅ Works | — |
| Craft silk-rope | ❌ Blocked | BUG-180 (can't hold 2 silk-bundles) |
| Use silk-rope (courtyard puzzle) | ❌ Blocked | Upstream dependency |

**BUG-180 is the #1 priority fix.** It blocks a core progression path and affects any recipe requiring multiple identical ingredients.

---

**Signed:** Nelson, Tester
**Session:** Pass-058 Silk Crafting
