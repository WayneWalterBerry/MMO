# Pass-064: Silk Bandage Healing

**Date:** 2026-03-28
**Tester:** Nelson
**Build:** `lua src/main.lua --headless` (+ `--debug` for GOTO teleport)
**Scope:** Silk bandage crafting → healing → consumption lifecycle
**Method:** Headless pipe-based testing (Pattern 1 from SKILL.md)

## Executive Summary

**Total tests:** 20
**Pass:** 8 | **Fail:** 9 | **Warn:** 3
**New bugs filed:** 5 (BUG-206 through BUG-210)
**Confirmed existing bugs:** 3 (BUG-180, BUG-181, BUG-157)
**Bug fixed:** 1 (BUG-184 — craft system now finds floor ingredients)

### Critical Finding

**The silk-bandage healing flow is BLOCKED end-to-end.** The player cannot pick up silk-bundles after killing the spider (disambiguation deadlock from BUG-180), and after crafting silk-bandages, the 2 spawned bandages ALSO trigger the same disambiguation deadlock. Since `apply` requires the item in hand, bandage healing is **completely untestable through normal gameplay.**

The existing `all_same_id` bypass in `helpers.lua:515-529` does not fix the problem because spawned objects get unique instance IDs (e.g., `silk-bundle` vs `silk-bundle-loot-1`, `silk-bandage` vs `silk-bandage-2`), causing the bypass check to always fail.

## Bug Summary

| Bug ID | Severity | Summary | New? | GH Issue |
|--------|----------|---------|------|----------|
| BUG-180 | CRITICAL | Duplicate silk-bundle drops → disambiguation deadlock | No | #293 |
| BUG-181 | HIGH | Crafted items placed on floor instead of player's hands | No | Existing |
| BUG-157 | MEDIUM | "stab" verb only targets self, not creatures | No | #232 |
| BUG-206 | CRITICAL | `all_same_id` disambiguation bypass ineffective — instance ID suffix mismatch | **Yes** | #362 |
| BUG-207 | HIGH | Minor-cut injury description hardcodes "glass" and "hand" regardless of tool/body | **Yes** | #365 |
| BUG-208 | MEDIUM | Treated injury description uses wrong body part ("hand" for leg wound) | **Yes** | #364 |
| BUG-209 | MEDIUM | Combat narration uses "Someone" instead of "You" for player actions | **Yes** | #366 |
| BUG-210 | LOW | Combat grammar: "organs gives way", "teeth bites", "fangs glances off" | **Yes** | #363 |

### Fixed Bug Verified

| Bug ID | Status | Notes |
|--------|--------|-------|
| BUG-184 | ✅ FIXED | `craft silk-bandage` now finds silk-bundle on room floor — previously failed |

---

## Individual Tests

### T-001: Health command at game start (no injuries)
**Input:** `health`
**Response:** `You feel fine. No injuries to speak of.`
**Verdict:** ✅ PASS — Correct response when uninjured.

### T-002: Apply bandage with no injuries
**Input:** `apply bandage` (at game start, no injuries)
**Response:** `You don't have any injuries to treat.`
**Verdict:** ✅ PASS — Correctly blocks treatment when healthy.

### T-003: Craft silk-bandage without ingredients
**Input:** `craft silk-bandage` (no silk-bundle in inventory or room)
**Response:** `You don't have enough silk-bundle to craft silk-bandage.`
**Verdict:** ✅ PASS — Clear error message with ingredient name.

### T-004: Use silk-bandage when not in inventory
**Input:** `use silk-bandage` (game start, no bandage exists)
**Response:** `You don't notice anything called that nearby. Try 'search around' to discover what's here.`
**Verdict:** ⚠️ WARN — Response is generic "not found" rather than a healing-specific message. Functional but unhelpful.

### T-005: Self-injury with knife
**Input:** `cut self with knife` (holding knife)
**Response:** `You nick your left leg with the knife. A shallow cut — it stings.`
**Verdict:** ✅ PASS — Self-injury works. Creates injury, reduces HP by 3.

### T-006: Health after self-injury
**Input:** `health` (after 1 cut)
**Response:**
```
You examine yourself:
  minor cut on your left leg — A small cut on your hand where the glass
  caught you. It stings, but the bleeding has mostly stopped on its own.

Health: 97/100
```
**Verdict:** ❌ FAIL
**Bug:** BUG-207 — Injury description says "your **hand** where the **glass** caught you" but injury is on **left leg** from a **knife**. Template text is hardcoded regardless of body part or tool used.

### T-007: Multiple self-injuries
**Input:** `cut self with knife` × 3
**Response:** Three cuts on different body parts (left leg, right hand, left hand). All say "glass caught you."
**Verdict:** ❌ FAIL
**Bug:** BUG-207 (same — all 3 injuries use identical hardcoded description)

### T-008: Health with 3 injuries
**Input:** `health` (after 3 cuts)
**Response:** `Health: 91/100` — Three injuries at 3 damage each = 9 total.
**Verdict:** ✅ PASS — Damage math is correct (100 - 9 = 91).

### T-009: Apply poultice to single injury
**Input:** `apply poultice` (1 injury, holding poultice)
**Response:** `You break the apothecary's knot and press the poultice against the wound. The crushed herbs spread across the injury, drawing a sharp sting, then a spreading coolness.`
**Verdict:** ✅ PASS — Treatment applied successfully. Injury state changes to "treated."

### T-010: Treated injury description body part
**Input:** `health` (after poultice on left leg)
**Response:**
```
  bandaged cut on your left leg — The bandage on your hand is snug. The
  sting is fading. [treated]
```
**Verdict:** ❌ FAIL
**Bug:** BUG-208 — Says "bandage on your **hand**" but wound is on **left leg**. The treated-state description template ignores the actual body part.

### T-011: Re-apply same poultice
**Input:** `apply poultice` (already applied)
**Response:** `a herbal poultice is already applied to a wound.`
**Verdict:** ✅ PASS — Correctly prevents double-application.

### T-012: Stab spider
**Input:** `stab spider` (in cellar with spider)
**Response:** `You can only stab yourself. (Try: stab self with <weapon>)`
**Verdict:** ❌ FAIL
**Bug:** BUG-157 (existing) — Help says "stab <target> — Attack with a stabbing weapon" but only self-targeting works. Player must use `attack spider` instead.

### T-013: Attack spider — combat resolution
**Input:** `attack spider` (holding knife)
**Response:** Multi-round combat. Spider killed. Player takes injuries (bleeding, spider bite, venom).
**Verdict:** ❌ FAIL (partial — combat works but text issues)
**Bug:** BUG-209 — Combat narration: "**Someone** cuts a large brown spider's cephalothorax" and "someone's hand". Should say "You" and "your".
**Bug:** BUG-210 — Grammar: "the organs **gives** way" (should be "give"), "The **teeth bites** at someone's forearm" (should be "teeth bite"), "the **fangs glances** off" (should be "fangs glance").

### T-014: Take silk-bundle after spider death
**Input:** `take silk` / `take silk bundle` / `take web silk` / `take bundle` / `take spider silk`
**Response:** `Which do you mean: a bundle of spider silk or a bundle of spider silk?`
**Verdict:** ❌ FAIL
**Bug:** BUG-180 (existing) + BUG-206 (new) — Two identical silk-bundles dropped (byproducts + loot_table.always). The `all_same_id` bypass in helpers.lua:515-529 fails because byproduct has `id="silk-bundle"` while loot has `id="silk-bundle-loot-1"`. The instance IDs differ, so the bypass treats them as different objects and triggers the unresolvable disambiguation prompt.

### T-015: Disambiguation response formats
**Input:** `1`, `first`, `first one` (after "Which do you mean" prompt)
**Response:** `I'm not sure what you mean.` for all formats.
**Verdict:** ❌ FAIL — No input format resolves the disambiguation prompt. Player is completely stuck.

### T-016: Craft silk-bandage (silk on floor)
**Input:** `craft silk-bandage` (silk-bundle on floor, not in inventory)
**Response:** `You tear the silk into strips suitable for bandaging wounds.`
**Verdict:** ✅ PASS — Crafting successfully found ingredient on floor and consumed it. This confirms BUG-184 is FIXED.

### T-017: Pick up crafted silk-bandage
**Input:** `take silk bandage` (2 bandages on floor after crafting)
**Response:** `Which do you mean: a silk bandage or a silk bandage?`
**Verdict:** ❌ FAIL
**Bug:** BUG-206 — Same disambiguation deadlock as silk-bundles. Craft spawns 2 bandages with IDs `silk-bandage` and `silk-bandage-2`. The `all_same_id` check fails because these are different strings.

### T-018: Apply silk-bandage from floor
**Input:** `apply silk-bandage` (bandage on floor, not in hand)
**Response:** `You don't have silk-bandage.`
**Verdict:** ⚠️ WARN — Apply requires item in hand. Since bandage can't be picked up (T-017), healing is blocked. Message could hint "You need to be holding it."

### T-019: Bandage at full health (without bandage)
**Input:** `apply silk-bandage` (no bandage, no injuries)
**Response:** `You don't have any injuries to treat.`
**Verdict:** ⚠️ WARN — Checks injuries BEFORE checking inventory. Would be more helpful to check if player has the item first.

### T-020: Em dash encoding in headless mode
**Input:** (observed across all outputs)
**Response:** Em dashes (—) render as `ΓÇö` throughout all game text.
**Verdict:** ❌ FAIL — UTF-8 encoding issue. Em dash U+2014 is being output as raw bytes that display as `ΓÇö` on Windows terminals / headless pipe output.

---

## Blocked Test Scenarios

The following scenarios from the task brief could NOT be tested due to the disambiguation deadlock:

| Scenario | Blocked By |
|----------|------------|
| Verify silk-bandage heals +5 HP | Can't pick up bandage (BUG-206) |
| Verify silk-bandage stops bleeding | Can't pick up bandage (BUG-206) |
| Verify bandage is consumed (single-use) | Can't pick up bandage (BUG-206) |
| Try using bandage when at full health (holding it) | Can't pick up bandage (BUG-206) |
| Verify bandage FSM transition unused→used | Can't pick up bandage (BUG-206) |

---

## Root Cause Analysis: BUG-206

The `all_same_id` bypass was a correct concept but incorrect implementation:

**Code** (`src/engine/verbs/helpers.lua:515-529`):
```lua
local first_id = matches[1].obj.id
for _, m in ipairs(matches) do
    if m.score == top_score and m.obj.id ~= first_id then
        all_same_id = false
        break
    end
end
```

**Problem**: Compares full `.id` field which includes instance suffixes:
- Byproduct: `id = "silk-bundle"` (base ID from resolve_byproduct)
- Loot drop: `id = "silk-bundle-loot-1"` (suffixed in loot.lua:140)
- Craft spawn 1: `id = "silk-bandage"` (base ID)
- Craft spawn 2: `id = "silk-bandage-2"` (suffixed in helpers.lua:1197)

**Fix suggestion**: Compare a base ID or template field instead of the full `.id`. For example:
```lua
local function base_id(obj)
    return obj.template_id or obj.id:gsub("%-loot%-%d+$", ""):gsub("%-(%d+)$", "")
end
```

---

## Session Transcript Summary

| Session | Purpose | Key Result |
|---------|---------|------------|
| test1-9 | Startup, navigation, help | Learned game commands and candle mechanics |
| test11-13 | Navigate bedroom → cellar | Successfully reached cellar with candle + knife |
| test14-15 | Combat: stab vs attack | "stab" only self-targets; "attack" works |
| test16-18 | Spider kill + silk pickup | Disambiguation deadlock confirmed; no input resolves it |
| test19-21 | Self-injury + poultice healing | Poultice treatment works; injury descriptions wrong |
| test22-23 | Creative pickup attempts | "take all", "take web silk", "loot", "scavenge" all fail |
| test24 | Edge cases at game start | health/apply/craft guard clauses work correctly |
| test25-26 | Debug GOTO + craft + apply | Craft finds floor ingredients; bandages also deadlocked |

---

## Sign-off

The silk-bandage healing feature is **not testable through normal gameplay** due to the disambiguation deadlock (BUG-206 compounding BUG-180). The crafting recipe is correctly defined, the ingredient search works, and the bandage object has proper healing properties (`healing_boost = 5`, `cures = {"bleeding"}`, single-use FSM). But the player can never hold a silk-bandage because every spawn of 2+ identical objects triggers an unresolvable disambiguation prompt.

**Priority fix**: BUG-206 — fix the `all_same_id` check to compare base IDs, not instance-suffixed IDs. This single fix would unblock the entire silk-bandage crafting and healing flow.

**Secondary fix**: BUG-181 — place at least one crafted item into the player's hand. This would also partially work around the disambiguation issue (only 1 bandage on floor = no disambiguation).

— Nelson, the Tester
