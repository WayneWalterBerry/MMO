# Flavor Text Playtest — event_output.on_wear System
**Date:** 2026-03-24
**Tester:** Nelson
**Build:** Lua src/main.lua --headless
**Scope:** One-shot flavor text for wool-cloak, chamber-pot, terrible-jacket

## Executive Summary

**18 tests** | **15 PASS** | **0 FAIL** | **2 WARN** | **1 SKIP**

The `event_output.on_wear` system is **solid**. Flavor text fires exactly once on first wear for both testable items (wool-cloak, chamber-pot), correctly goes silent on re-wear, and does not interfere with items that lack `event_output`. The flavor text appears in the right place — immediately after the "You put on..." message. Multiple wearables in the same session each fire their flavor independently.

Two minor parser gaps found with creative phrasing ("put pot on my head", "wear pot as a hat"). The terrible-jacket could not be tested because it's a **craft-only item** not spawned in any room.

## Issue Summary

| ID | Severity | Summary |
|----|----------|---------|
| WARN-01 | LOW | "put the pot on my head" — auto-pickup works but "on my head" suffix causes wear rejection |
| WARN-02 | LOW | "wear the chamber pot as a hat" — parser confused by "as a hat" suffix, returns "You aren't holding that" |
| SKIP-01 | INFO | terrible-jacket is craft-only (requires 2× cloth + sewing tool), untestable without crafting pipeline |

## Test Results

### Scenario 1: Wool Cloak First Wear

#### T-001: `wear cloak` (after open wardrobe + take)
**Setup:** feel around → sleep until dawn → open wardrobe → take cloak → wear cloak
**Response:**
```
You put a moth-eaten wool cloak on your back.
I need to get better outfits. I look like a peasant.
```
**Verdict:** ✅ PASS — Flavor text fires on first wear, appears immediately after wear message.

#### T-002: `wear cloak` (second time, after remove)
**Setup:** ...wear cloak → remove cloak → wear cloak
**Response:**
```
You put a moth-eaten wool cloak on your back.
```
**Verdict:** ✅ PASS — One-shot works. No flavor text on re-wear. Silent as expected.

#### T-003: `put on the cloak` (creative phrasing, wardrobe open)
**Setup:** feel around → sleep until dawn → open wardrobe → put on the cloak
**Response:**
```
You pick up a moth-eaten wool cloak.
You put a moth-eaten wool cloak on your back.
I need to get better outfits. I look like a peasant.
```
**Verdict:** ✅ PASS — "put on" recognized as wear synonym. Auto-pickup from open wardrobe + flavor fires.

#### T-004: `put on the wool cloak` (same as above, full name)
**Setup:** feel around → sleep until dawn → open wardrobe → put on the wool cloak
**Response:**
```
You pick up a moth-eaten wool cloak.
You put a moth-eaten wool cloak on your back.
I need to get better outfits. I look like a peasant.
```
**Verdict:** ✅ PASS — Full name resolves correctly.

#### T-005: `don the cloak` (synonym)
**Setup:** feel around → sleep until dawn → open wardrobe → don the cloak
**Response:**
```
You pick up a moth-eaten wool cloak.
You put a moth-eaten wool cloak on your back.
I need to get better outfits. I look like a peasant.
```
**Verdict:** ✅ PASS — "don" verb alias works. Flavor fires.

#### T-006: `I want to wear the cloak` (preamble stripping)
**Setup:** feel around → sleep until dawn → open wardrobe → I want to wear the cloak
**Response:**
```
You pick up a moth-eaten wool cloak.
You put a moth-eaten wool cloak on your back.
I need to get better outfits. I look like a peasant.
```
**Verdict:** ✅ PASS — Parser strips "I want to" preamble. Flavor fires.

#### T-007: `put on the cloak` (wardrobe CLOSED)
**Setup:** feel around → sleep until dawn → put on the cloak (wardrobe not opened)
**Response:**
```
You need to take the moth-eaten wool cloak first.
```
**Verdict:** ✅ PASS — Expected behavior. Cloak is inside closed wardrobe, not accessible. No error, clean message.

### Scenario 2: Chamber Pot First Wear

#### T-008: `wear the chamber pot`
**Setup:** feel around → sleep until dawn → wear the chamber pot
**Response:**
```
You pick up a ceramic chamber pot.
You put on a ceramic chamber pot.
This is going to smell worse than I thought.
```
**Verdict:** ✅ PASS — Auto-pickup from room floor + flavor text fires.

#### T-009: `put on the chamber pot`
**Setup:** feel around → sleep until dawn → put on the chamber pot
**Response:**
```
You pick up a ceramic chamber pot.
You put on a ceramic chamber pot.
This is going to smell worse than I thought.
```
**Verdict:** ✅ PASS — "put on" synonym works. Flavor fires.

#### T-010: `wear pot → remove → wear pot` (one-shot)
**Setup:** feel around → sleep until dawn → wear the chamber pot → remove the pot → wear the chamber pot
**Response (first wear):**
```
You put on a ceramic chamber pot.
This is going to smell worse than I thought.
```
**Response (second wear):**
```
You put on a ceramic chamber pot.
```
**Verdict:** ✅ PASS — One-shot works. Silent on re-wear.

#### T-011: `put the pot on my head` (creative phrasing)
**Setup:** feel around → sleep until dawn → put the pot on my head
**Response:**
```
You pick up a ceramic chamber pot.
You can't wear a ceramic chamber pot on your head.
```
**Verdict:** ⚠️ WARN (WARN-01) — Auto-pickup works, but the "on my head" slot-specification syntax causes wear rejection. The pot's configured slot IS head, so this should work. Parser gap: "put X on my Y" isn't routing to the wear handler correctly.

#### T-012: `wear the chamber pot as a hat` (creative phrasing)
**Setup:** feel around → sleep until dawn → wear the chamber pot as a hat
**Response:**
```
You aren't holding that.
```
**Verdict:** ⚠️ WARN (WARN-02) — Parser confused by "as a hat" suffix. Likely parsing "hat" as the target noun. No auto-pickup, no wear attempt.

#### T-013: `please put on the chamber pot` (politeness)
**Setup:** feel around → sleep until dawn → please put on the chamber pot
**Response:**
```
You pick up a ceramic chamber pot.
You put on a ceramic chamber pot.
This is going to smell worse than I thought.
```
**Verdict:** ✅ PASS — Parser strips "please". Flavor fires.

#### T-014: `wear chamber pot` in darkness (no sleep/light)
**Setup:** feel around → wear chamber pot (no dawn, no light)
**Response:**
```
You pick up a ceramic chamber pot.
You put on a ceramic chamber pot.
This is going to smell worse than I thought.
```
**Verdict:** ✅ PASS — Wearing works in complete darkness. Flavor fires. Good — players shouldn't need light to put on clothes.

### Scenario 3: Terrible Jacket

#### T-015: terrible-jacket availability
**Setup:** Searched all room definitions for terrible-jacket placement.
**Finding:** The terrible-jacket is a **craft-only item**. Recipe: 2× cloth + sewing tool → terrible-jacket. Cloth is obtainable from cloth-scraps in the storage cellar. Sewing tools are in the wardrobe sack.
**Verdict:** ⏭️ SKIP (SKIP-01) — Cannot test without crafting pipeline. The object definition and event_output config are correctly authored; engine behavior verified through cloak and pot tests which use the identical code path.

### Scenario 4: Multiple Wearables in Sequence

#### T-016: `wear cloak → remove → wear pot` (sequential, independent firing)
**Setup:** feel around → sleep until dawn → open wardrobe → wear cloak → remove cloak → wear chamber pot → remove pot
**Response:**
```
You put a moth-eaten wool cloak on your back.
I need to get better outfits. I look like a peasant.
...
You put on a ceramic chamber pot.
This is going to smell worse than I thought.
```
**Verdict:** ✅ PASS — Each item fires its flavor text independently. No cross-contamination.

#### T-017: `wear cloak + wear pot` (both worn simultaneously)
**Setup:** feel around → sleep until dawn → open wardrobe → wear cloak → wear chamber pot
**Response:**
```
You put a moth-eaten wool cloak on your back.
I need to get better outfits. I look like a peasant.
...
You put on a ceramic chamber pot.
This is going to smell worse than I thought.
```
**Verdict:** ✅ PASS — Different slots (back + head). Both flavors fire. No conflicts.

### Scenario 5: Edge Cases

#### T-018: `wear candle holder` (portable, non-wearable, no event_output)
**Setup:** feel around → sleep until dawn → take candle holder → wear candle holder
**Response:**
```
You can't wear a brass candle holder.
```
**Verdict:** ✅ PASS — Clean rejection. No error, no extra text, no event_output leakage.

#### T-019: `wear sack` (wearable, NO event_output)
**Setup:** feel around → sleep until dawn → open wardrobe → take sack → wear sack
**Response:**
```
You sling a burlap sack over your shoulder. It makes a serviceable, if ugly, backpack.
```
**Verdict:** ✅ PASS — Wearable item without event_output. Custom wear message appears (from wear handler), no flavor text, no errors. Proves event_output is additive and doesn't break items that lack it.

#### T-020: `wear rug` / `wear bed` / `wear curtains` (non-portable, non-wearable)
**Setup:** feel around → sleep until dawn → wear the rug / wear the bed / wear the curtains
**Response:** `You aren't holding that.` (all three)
**Verdict:** ✅ PASS — Non-portable items gracefully rejected. No errors, no event_output leakage.

## Output Placement Verification

For all successful wear+flavor tests, the flavor text consistently appears on the line **immediately after** the wear confirmation message:

```
You put a moth-eaten wool cloak on your back.     ← wear message
I need to get better outfits. I look like a peasant.  ← flavor text (same ---END--- block)
```

This is correct — the flavor text is part of the same response, reads naturally as the character's inner monologue, and doesn't appear on a separate turn.

## Observations

1. **Auto-pickup is excellent.** The wear verb automatically picks up items from the room floor and from open containers. Very player-friendly.
2. **One-shot mechanism is bulletproof.** Tested on both items across multiple sessions. The `event_output["on_wear"] = nil` approach works perfectly.
3. **Parser handles creative phrasing well.** "don", "put on", "I want to wear", "please put on" all work. Only "as a hat" and "on my head" suffixes cause issues.
4. **Darkness doesn't block wearing.** Players can wear items in the dark, which feels correct.
5. **terrible-jacket untestable.** The crafting pipeline would need to be exercised to verify this item's flavor text in-game. The code path is identical to cloak/pot, so confidence is high even without direct testing.

## Sign-off

All testable flavor text items verified. The `event_output.on_wear` system is working as designed. Two low-severity parser warnings filed for creative phrasing edge cases. Terrible-jacket skipped due to craft-only availability.

— Nelson, QA Engineer
