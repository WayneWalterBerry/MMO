# Pass-001: Speed Runner Simulation (Seed 1111) — Wyatt's World

**Date:** 2025-07-18
**Tester:** Nelson (QA Engineer)
**Build:** `lua src/main.lua --headless --world wyatt-world`
**Mode:** Speed run — minimal commands, skip reading, direct to solutions

---

## Executive Summary

**Result: TOTAL FAILURE — 0/7 puzzles solvable**

- Total commands attempted: 80+
- Puzzles solved: 0 / 7
- Bugs filed: 6 (2 CRITICAL, 2 HIGH, 1 MEDIUM, 1 LOW)
- Sequence breaks found: 1 (all rooms accessible without hub puzzle)

Three independent blockers prevent ANY puzzle from being completed:
1. All rooms are dark (engine darkness at 2 AM, no light sources)
2. All rooms are empty (instances = {} in every room file, 68 objects defined but unplaced)
3. Key verbs missing ("press" not implemented, "enter"/"set" parse incorrectly)

---

## Bugs Filed

| # | Issue | Severity | Summary |
|---|-------|----------|---------|
| 1 | [#443](https://github.com/WayneWalterBerry/MMO/issues/443) | CRITICAL | All rooms dark — no lighting for E-rated kid game |
| 2 | [#442](https://github.com/WayneWalterBerry/MMO/issues/442) | CRITICAL | All room instances empty — 68 objects defined, none placed |
| 3 | [#441](https://github.com/WayneWalterBerry/MMO/issues/441) | HIGH | Hub exits not gated — all rooms accessible without solving hub |
| 4 | [#446](https://github.com/WayneWalterBerry/MMO/issues/446) | CRITICAL | "press" verb not implemented — hub puzzle unsolvable |
| 5 | [#448](https://github.com/WayneWalterBerry/MMO/issues/448) | LOW | Room re-entry shows description despite darkness |
| 6 | [#449](https://github.com/WayneWalterBerry/MMO/issues/449) | HIGH | "enter"/"set" verbs parse wrong — keypad/dial input impossible |

---

## Speed Run: Commands Per Room

| Room | Puzzle | Min Commands (spec) | Actual Commands Tested | Result |
|------|--------|--------------------|-----------------------|--------|
| Beast Studio (Hub) | Press blue button | 2 (read sign, press button) | 8 | ❌ BLOCKED — press verb missing, no objects |
| Feastables Factory | Sort chocolates | ~10 (read + take/put ×5) | 7 | ❌ BLOCKED — no objects, dark |
| Money Vault | Enter 170 | 5 (read 3 cards, enter code, take trophy) | 8 | ❌ BLOCKED — no objects, dark, enter=movement |
| Beast Burger Kitchen | Build burger | 13 (read + 6×take/put) | 8 | ❌ BLOCKED — no objects, dark |
| Last to Leave | Find 3 fakes | 9 (examine 3 + take 3 + drop 3) | 8 | ❌ BLOCKED — no objects, dark |
| Riddle Arena | Solve 3 riddles | 6 (read 3 + touch 3) | 8 | ❌ BLOCKED — no objects, dark |
| Grand Prize Vault | Unlock chest | 6 (read letter, set 3 dials, open, take) | 9 | ❌ BLOCKED — no objects, dark, set parsing broken |

---

## Can Puzzles Be Solved Without Reading?

**Cannot be tested.** No puzzle can be solved AT ALL (with or without reading) because:
- No objects are instantiated in any room
- All rooms are dark
- Key verbs (press, enter-as-input, set-dial) are missing

**Theoretical analysis** (assuming bugs were fixed):
- **Puzzle 01 (Hub):** A speed runner who knows "press blue button" could skip reading the sign. The spec suggests gating buttons until sign is read — **this is not implemented.**
- **Puzzle 03 (Money Vault):** If you know the combo is 170, you'd skip reading the 3 math cards entirely. **Design should require reading cards first** (e.g., cards unlock keypad digits).
- **Puzzle 07 (Grand Prize Vault):** If you know 13-50-7, you'd skip the letter entirely. Same concern — **the combination should not be guessable.**
- **Puzzles 02, 04, 05, 06:** Require physical object interaction that inherently involves reading labels/descriptions. These are better designed against speed-running.

---

## Sequence Break Analysis

### Can you skip rooms?
**YES.** All 6 exits from the hub are plain `{ target = "room-id" }` — no locks, no doors, no state gating. Speed run to any room: **1 command.**

### Can you go directly to Grand Prize Vault?
**YES.** `go down` from the hub reaches the final room immediately. Zero puzzles required.

### Can you skip the hub puzzle entirely?
**YES.** The hub puzzle (read sign → press blue button) has no enforcement. Nothing prevents navigation.

---

## Room-by-Room Detail

### T-001: Hub (Beast Studio) — Speed Run Attempt
```
> look
It is too dark to see. You need a light source.
> feel around
You feel around but find nothing within reach.
> press blue button
I'm not sure what you mean.
> push button
Hmm, try looking around for clues!
> read sign
It is too dark to read anything.
> search
There's nothing to search here.
```
**Verdict:** ❌ FAIL — Room is dark, empty, and press verb doesn't exist.

### T-002: Feastables Factory — Speed Run Attempt
```
> go north → The Feastables Factory (dark)
> feel → nothing within reach
> smell → Chocolate! It smells SO good!
> search → nothing to search here
> take bar → Hmm, try looking around for clues!
```
**Verdict:** ❌ FAIL — Room is dark, no objects to sort. Smell works (room-level).

### T-003: Money Vault — Speed Run Attempt
```
> go south → The Money Vault (dark)
> feel → nothing within reach
> smell → fresh paper and metal
> enter 170 → You can't go that way.
> read card → too dark to read
```
**Verdict:** ❌ FAIL — Dark, empty, "enter" = movement verb.

### T-004: Beast Burger Kitchen — Speed Run Attempt
```
> go east → The Beast Burger Kitchen (dark)
> feel → nothing within reach
> smell → Sizzling burgers! Amazing!
> take recipe → Hmm, try looking around for clues!
> take bun → Hmm, try looking around for clues!
```
**Verdict:** ❌ FAIL — Dark, empty. No recipe card, no ingredients.

### T-005: Last to Leave — Speed Run Attempt
```
> go west → The Last to Leave Room (dark)
> feel → nothing within reach
> smell → cozy house, cookies, clean laundry
> examine clock → can't find in darkness
> find box → nothing to search here
```
**Verdict:** ❌ FAIL — Dark, empty. No clock, book, lamp, or found-it box.

### T-006: Riddle Arena — Speed Run Attempt
```
> go up → The Riddle Arena (dark)
> feel → nothing within reach
> smell → clean, like a brand new stage
> read riddle → too dark to read
> touch clock → can't feel anything like that
```
**Verdict:** ❌ FAIL — Dark, empty. No riddle boards, clock, piano, or hole.

### T-007: Grand Prize Vault — Speed Run Attempt
```
> go down → The Grand Prize Vault (dark)
> feel → nothing within reach
> smell → gold glitter and party streamers
> listen → Soft victory music. This room feels special!
> read letter → too dark to read
> set dial 1 to 13 → You don't see any dial 1 to 13 to set.
> open chest → Hmm, try looking around for clues!
```
**Verdict:** ❌ FAIL — Dark, empty. "set" parses wrong. No letter, chest, or lock.

---

## Positive Findings

1. **Room-level sensory verbs work in darkness:** `smell` and `listen` return correct, kid-friendly descriptions for all 7 rooms. Good content!
2. **Navigation works correctly:** All room connections match the spec. Hub → 6 rooms, each room returns to hub.
3. **Intro narrative plays correctly:** "You walk through a giant golden door..." matches level-01.lua.
4. **Time system works:** `time` returns "It is 2:00 AM."
5. **E-rated content:** No scary words, no violence language in any room description.
6. **68 object definitions exist:** The content has been authored, just not wired into rooms.

---

## Recommendations

**Priority order for unblocking Wyatt's World:**
1. **Fix lighting** (#443) — Add `always_lit = true` or `casts_light` objects. Quick win.
2. **Populate room instances** (#442) — Wire 68 objects into 7 rooms using deep-nesting syntax. Biggest effort.
3. **Add "press" verb** (#446) — Required for hub puzzle.
4. **Gate hub exits** (#441) — Lock doors until blue button pressed.
5. **Add "enter"/"set" verb patterns** (#449) — Required for Money Vault and Grand Prize Vault.
6. **Fix auto-look darkness bypass** (#448) — Low priority consistency fix.
