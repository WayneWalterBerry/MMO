# Pass-044: Kill Wolf — Corpse Reshape & Gnawed-Bone Drop

**Date:** 2026-03-27
**Tester:** Nelson
**Build:** `lua src/main.lua --headless`
**Method:** Headless pipe-based testing (Pattern 1 from SKILL.md)
**Scope:** Wolf death → furniture corpse transformation → gnawed-bone inventory drop to floor

## Executive Summary

**Total tests: 8 | ✅ PASS: 4 | ❌ FAIL: 3 | ⚠️ WARN: 1**

Wolf combat and corpse reshape work correctly. The dead wolf appears as non-portable furniture in the room description. However, the **gnawed-bone is never dropped to the floor** when the wolf dies — the primary loot mechanic is broken. Additionally, **two dead wolf objects** appear in the room after death (duplicate entity bug), and disambiguation shows identical options when "bone" keyword collides with dead wolf objects.

## Bug List

| Bug ID | Severity | Summary |
|--------|----------|---------|
| BUG-165 | **HIGH** | Gnawed-bone not dropped to floor on wolf death — `inventory.drop_on_death()` not transferring carried items |
| BUG-166 | **MEDIUM** | Duplicate dead wolf entities after death — `search around` scans two separate "a dead wolf" objects |
| BUG-167 | **LOW** | Disambiguation shows identical options: "Which do you mean: a dead wolf or a dead wolf?" |

## Test Commands

Two test runs were executed. Run 2 used 20 `attack wolf` commands to guarantee a kill (wolf requires ~7 engagement cycles with bare fists due to 20-round stalemate cap).

**Run 2 input (definitive):**
```
goto hallway
attack wolf ×20
look
search around
take gnawed bone
take bone
feel dead wolf
search dead wolf
inventory
```

## Individual Tests

### T-001: Wolf can be killed with bare fists
**Input:** `attack wolf` (repeated across multiple engagement cycles)
**Response:** After ~7 engagement cycles (each capped at 20 combat rounds), the wolf finally died:
```
a grey wolf is dead!
```
**Verdict:** ✅ PASS
**Notes:** Combat frequently ends in stalemate ("The combat reaches a stalemate. Both combatants back off, wary.") and wolf flees. Player must re-engage. This is probably intentional — killing a wolf bare-handed should be extremely hard.

### T-002: Dead wolf appears in room description as furniture
**Input:** `look` (after wolf death)
**Response:**
```
A dead wolf sprawls across the floor, blood pooling beneath it.
```
**Verdict:** ✅ PASS — Corpse correctly appears as room furniture with appropriate room_presence text.

### T-003: Dead wolf is not portable (can't carry)
**Input:** `take dead wolf`
**Response:**
```
You can't carry a dead wolf.
```
**Verdict:** ✅ PASS — Correctly rejects pickup. Furniture template, not portable.

### T-004: Dead wolf has tactile description (feel)
**Input:** `feel dead wolf`
**Response:**
```
Coarse fur, already cooling. The massive jaw hangs slack. The body is heavy, immovable.
```
**Verdict:** ✅ PASS — Excellent sensory description. Confirms on_feel is present.

### T-005: Gnawed-bone drops to floor on wolf death
**Input:** `search around` (after wolf death)
**Response:**
```
Your eyes scan a dead wolf — nothing notable.
Your eyes scan a dead wolf — nothing notable.
...
You finish searching the area. Nothing interesting.
```
**Verdict:** ❌ FAIL
**Bug:** BUG-165 — The gnawed-bone (GUID `{b8db1d83-9c05-401c-ae7b-67c31b98d6fc}`) is defined in the wolf's `inventory.carried` but never appears on the room floor after death. The `drop_on_death()` mechanism either isn't being called or isn't transferring carried items to the room. No bone found anywhere via search.

### T-006: Gnawed-bone is takeable
**Input:** `take gnawed bone`
**Response:**
```
You don't notice anything called that nearby. Try 'search around' to discover what's here.
```
**Verdict:** ❌ FAIL
**Bug:** BUG-165 (same root cause) — Bone doesn't exist in the room because it was never dropped.

### T-007: Duplicate dead wolf entities
**Input:** `search around` (after wolf death)
**Response:** Two separate "a dead wolf" entries scanned:
```
Your eyes scan a dead wolf — nothing notable.
Your eyes scan a dead wolf — nothing notable.
```
**Verdict:** ❌ FAIL
**Bug:** BUG-166 — Two dead wolf objects exist in the room after death. The original wolf entity and the reshaped corpse may both be present, or `reshape_instance()` is creating a duplicate rather than replacing in-place.

### T-008: "take bone" disambiguation collision
**Input:** `take bone` (Run 1 only)
**Response:**
```
Which do you mean: a dead wolf or a dead wolf?
```
**Verdict:** ⚠️ WARN
**Bug:** BUG-167 — The keyword "bone" on dead wolf objects triggers disambiguation with two identical display names. Player cannot distinguish between them. This is a downstream symptom of BUG-166 (duplicate entities) and possibly the dead wolf having "bone" in its keyword list.

## Analysis

### What works
- Combat system produces a kill eventually (wolf health reaches 0)
- Death state reshape transforms wolf into furniture with correct description, on_feel, and non-portable flag
- Room description correctly integrates the corpse as a room_presence element

### What's broken
1. **Primary failure:** The gnawed-bone loot drop is completely non-functional. The wolf's `inventory.carried` contains the bone GUID, but `handle_creature_death()` → `inventory.drop_on_death()` is not transferring it to the room floor. This blocks the intended gameplay loop where killing the wolf rewards the player with a bone item.

2. **Secondary failure:** Two dead wolf entities exist post-death. This suggests `reshape_instance()` creates a new object but doesn't remove/replace the original, OR the death handler creates the corpse without cleaning up the original creature entry in the registry.

### Recommended investigation
- Trace `handle_creature_death()` in `src/engine/creatures/death.lua` — is `inventory.drop_on_death()` being called?
- Check if `reshape_instance()` in `src/engine/mutation/init.lua` replaces the registry entry or creates a new one alongside it
- Verify the gnawed-bone GUID resolves correctly when loaded

---

**Signed:** Nelson, Tester
**Pass complete:** 2026-03-27
