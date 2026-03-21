# Nelson: Inventory Test Suite — Surprising Behaviors

**Date:** 2026-03-21
**Author:** Nelson (QA Tester)
**Related:** `test/inventory/test-inventory.lua` (60 tests)

## Observations from Test Writing

### 1. Self-Containment Guard Uses Object Identity, Not ID
The containment module's BUG-036b guard does `if item == container_obj then` — a Lua table identity check. Two different table references with the same `.id` field would bypass this. In practice this is fine because objects come from the registry (single source of truth), but during refactoring if objects are ever cloned or reconstructed, this guard would silently fail.

**Risk:** LOW (registry guarantees single reference today)
**Recommendation:** Consider adding `or item.id == container_obj.id` as a belt-and-suspenders check.

### 2. `put` Requires Items in Hands Only
The `put X in Y` handler only looks at `player.hands[1..2]` for the item to place. Items inside held bags or worn containers cannot be directly `put` elsewhere — the player must first `take item from bag`, then `put item in target`. This is a two-step dance that may surprise players.

**Risk:** MEDIUM (UX friction)
**Recommendation:** Either keep as-is (realistic) or add auto-extraction from bags during `put`.

### 3. `drop` Has Smart Bag Detection
When you try to `drop` an item that's in a bag (not directly in hand), the system gives a helpful "get that out of the bag first" message rather than silently failing. This is good UX — worth preserving during refactoring.

### 4. `find_visible` Search Order Matters
The search order is: room contents → surface contents → inner container contents → parts → hands → bags → worn. This means room items shadow identically-named surface items. The verb handlers rely on this ordering (e.g., preferring non-spent items from bags over terminal items on the floor).

**Risk:** LOW (intentional design)
**Recommendation:** Preserve this search priority during refactoring.

### 5. Surface Accessibility is the Gate for Container Access
Both `take from` and `put in` check `zone.accessible ~= false` on surfaces. Closed drawers (accessible=false) correctly block access. This is the containment layer's primary security mechanism.

## Test Coverage Summary

| Category | Tests | Status |
|----------|-------|--------|
| Basic take (room → hand) | 9 | ✅ |
| Two-handed objects | 2 | ✅ |
| Basic drop (hand → room) | 5 | ✅ |
| Take from container | 5 | ✅ |
| Take from surface container | 2 | ✅ |
| Put in container | 6 | ✅ |
| Put containment validation | 3 | ✅ |
| Inventory listing | 5 | ✅ |
| Containment module direct | 10 | ✅ |
| Round-trip operations | 2 | ✅ |
| Registry basics | 6 | ✅ |
| find_visible/discovery | 3 | ✅ |
| Edge cases (articles, syntax) | 2 | ✅ |
| **Total** | **60** | **All pass** |
