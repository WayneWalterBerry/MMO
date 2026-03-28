# Pass-049: Cure Rabies with Healing Poultice
**Date:** 2026-03-27
**Tester:** Nelson (LLM Playtest)
**Build:** lua src/main.lua --headless
**Method:** Headless pipe-based testing (Pattern 1 from SKILL.md)

## Executive Summary

Attempted to test the rabies cure path: get bitten by bat → contract rabies → find healing poultice → cure rabies. **The entire cure chain is untestable** due to two blocking gaps in game content.

- **Total tests run:** 14 individual commands across 8 sessions (including 5 repeated bat encounters)
- **Bugs found:** 4
- **Blockers found:** 2 (rabies can't trigger, poultice can't be obtained)
- **Pass rate:** N/A — test sequence is blocked by missing content

### Severity Breakdown

| Severity | Count |
|----------|-------|
| HIGH     | 2     |
| MEDIUM   | 1     |
| LOW      | 1     |

## Bug List

| Bug ID | Severity | Summary |
|--------|----------|---------|
| BUG-173 | HIGH | Bat bite never transmits rabies — missing on_hit disease mechanics in bat creature |
| BUG-174 | HIGH | Healing poultice not placed in any Level 1 room — item inaccessible to player |
| BUG-175 | MEDIUM | Healing poultice `cures` array doesn't include rabies — inconsistent with rabies `healing_interactions` |
| BUG-176 | LOW | Grammar: "the teeth doesn't bite" / "the fangs skitters away" — plural noun with singular verb |

---

## Individual Tests

### T-001: Navigate to crypt and fight bat
**Input:**
```
goto crypt
look
attack bat
```
**Response:**
```
You materialize in The Crypt.
It is too dark to see. You need a light source.
---
You can't see well — attacks will be less accurate.
You engage a small brown bat with bare fists!
[... 5-8 exchanges of attacks ...]
a small brown bat is dead!
```
**Verdict:** ✅ PASS — Navigation, darkness, and combat all work. Bat dies in one combat round (3 HP vs bare fists).

---

### T-002: Check for rabies after bat bite (attempt 1)
**Input:** `injuries` (after killing bat)
**Response:** `You feel fine. No injuries to speak of.`
**Verdict:** ❌ FAIL — Bat landed multiple bites (shin, forearm, chest) but no injury/rabies inflicted.
**Bug:** BUG-173

---

### T-003: Check for rabies after bat bite (attempts 2–6)
**Input:** 5 separate game sessions: `goto crypt → attack bat → injuries`
**Response:** All 5 attempts: `You feel fine. No injuries to speak of.`
**Analysis:** Across 5 encounters, the bat landed approximately 12 total bites on the player. At 8% rabies chance per bite, expected ~1 transmission. Got zero. Root cause: bat creature (`src/meta/creatures/bat.lua`) has no `on_hit` disease infliction on its bite weapon. The rabies injury definition declares `transmission = { probability = 0.08, via = "bite" }` but the bat's `natural_weapons` bite entry has no matching `on_hit` config.
**Verdict:** ❌ FAIL — Rabies transmission is defined but not wired to the bat's attack.
**Bug:** BUG-173

---

### T-004: Search all 7 rooms for healing poultice
**Input:** Searched each room: bedroom, cellar, storage-cellar, deep-cellar, crypt, hallway, courtyard
**Response:** Every room searched thoroughly via `search` and `feel`. No poultice found in any room.
**Analysis:** The healing poultice object is defined (`src/meta/objects/healing-poultice.lua`, GUID `{fcd722b7-27d2-42cb-baf5-86e66cf2fc07}`) with `location = nil`. It is not instanced in any room file.
**Verdict:** ❌ FAIL — Poultice exists as a game object but is never placed in the world.
**Bug:** BUG-174

---

### T-005: `take poultice` in bedroom
**Input:** `take poultice`
**Response:** `You don't notice anything called that nearby. Try 'search around' to discover what's here.`
**Verdict:** ❌ FAIL (expected — poultice doesn't exist in any room)
**Bug:** BUG-174

---

### T-006: `use poultice` (not in inventory)
**Input:** `use poultice`
**Response:** `You don't notice anything called that nearby. Try 'search around' to discover what's here.`
**Verdict:** ✅ PASS — Correct error message for non-existent item.

---

### T-007: `find poultice` in crypt
**Input:** `find poultice`
**Response:** Exhaustive search of all crypt containers (5 sarcophagi, candle stubs, coins, inscription, archway). Reports: `You finish searching. No poultice found.`
**Verdict:** ✅ PASS — Search mechanic works correctly; correctly reports item not found.

---

### T-008: `apply poultice` with no injuries
**Input:** `apply poultice`
**Response:** `You don't have any injuries to treat.`
**Verdict:** ✅ PASS — Correct response when player has no injuries and no poultice. Good message.

---

### T-009: `health` and `injuries` commands
**Input:** `health` / `injuries` after bat combat
**Response:** `You feel fine. No injuries to speak of.`
**Verdict:** ⚠️ WARN — Health/injury commands work, but bat bites that clearly hit the player ("feel a quick sting at someone's shin; a light scratch in the skin") don't register as injuries. Either bat force is too low to cause injury conditions, or lightweight creature attacks don't trigger the injury system.

---

### T-010: Healing poultice cures array inconsistency
**Analysis:** `healing-poultice.lua` declares `cures = {"bleeding", "crushing-wound", "minor-cut"}`. Rabies is NOT in this list. However, `rabies.lua` has `healing_interactions = { ["healing-poultice"] = { ... } }`. Two systems reference each other but disagree on what the poultice cures.
**Verdict:** ⚠️ WARN — Potential bug depending on which system is authoritative. If the engine checks `cures` on the item, rabies cure will fail even with the poultice in hand.
**Bug:** BUG-175

---

### T-011: Grammar in combat text
**Observed text:**
- `"A dull thud at someone's skull; the teeth doesn't bite."`
- `"In the dark, a scrape and a miss — the fangs skitters away."`
- `"the enamel skitters away"` (odd material reference)
**Expected:** "the teeth don't bite" / "the fangs skitter away"
**Verdict:** ❌ FAIL — Plural nouns with singular verbs in combat text.
**Bug:** BUG-176

---

## Root Cause Analysis

### Why the rabies cure chain is untestable

Two independent gaps block this feature end-to-end:

1. **Bat → Rabies link missing:** The bat creature definition has a bite weapon with `type = "pierce"` and `material = "tooth-enamel"` but no `on_hit` disease block. The rabies injury definition *describes* 8% bite transmission, but nothing in the combat system connects the bat's bite to rabies infliction. The combat resolution code (`src/engine/combat/resolution.lua`) checks for `on_hit.inflict` and `on_hit.probability` on weapons — this block needs to be added to the bat's bite weapon.

2. **Poultice not in world:** The healing poultice object exists with full FSM, sensory data, and cure mechanics, but `location = nil` and no room instances reference it. A player cannot obtain it through normal gameplay.

### Recommended fix path

1. Add `on_hit` to bat's bite weapon:
   ```lua
   { id = "bite", type = "pierce", material = "tooth-enamel", zone = "head", force = 1,
     target_pref = "head", message = "sinks its tiny fangs into",
     on_hit = { inflict = "rabies", probability = 0.08 }
   }
   ```

2. Place healing poultice in a Level 1 room (suggestion: storage-cellar or deep-cellar, discoverable via search).

3. Add `"rabies"` to the poultice's `cures` array for consistency, or document that `healing_interactions` on the injury is the authoritative system.

---

## Observations (Non-Bug)

- **Bat combat balance:** Bat dies in 1 combat round (3 HP). Player takes 2-4 hits. With 8% rabies chance per bite, a single encounter gives roughly 15-30% cumulative rabies risk. This seems reasonable — players who fight multiple bats face increasing danger.
- **Darkness combat penalty:** "You can't see well — attacks will be less accurate" is displayed but combat still resolves. Good.
- **`goto` teleport:** Works perfectly for debug/testing. Room transitions fire correctly.
- **Bat respawn:** Each fresh game session has a live bat in the crypt. Dead bats don't respawn within the same session. Correct behavior.
- **Search exhaustiveness:** The `find <item>` command searches all containers in the room automatically. Thorough and player-friendly.

---

**Signed:** Nelson, Tester — 2026-03-27
