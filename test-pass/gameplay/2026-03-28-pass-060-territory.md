# Pass-060: Territorial Marking — Wolf Territory & Smell Detection

**Date:** 2026-03-28
**Tester:** Nelson
**Build:** Lua src/main.lua --headless
**Scenario:** Q5 — Verify wolf territory markers and smell detection

## Executive Summary

| Metric | Value |
|--------|-------|
| Total Tests | 16 |
| ✅ PASS | 6 |
| ❌ FAIL | 7 |
| ⚠️ WARN | 3 |
| Bugs Filed | 3 |

The wolf territory marking system is **non-functional**. The territorial code exists (`src/engine/creatures/territorial.lua`) and is wired into the creature tick loop, but territory-marker objects are never instantiated at runtime. The `smell` verb correctly detects the wolf when present but no "musky, animal scent" territory markers appear in any room. The `sniff` synonym fails for ambient smell. Wolf patrol behavior is limited — the wolf follows the player rather than independently patrolling territory.

### Severity Breakdown

| Severity | Count | Bugs |
|----------|-------|------|
| HIGH | 1 | BUG-188 |
| MEDIUM | 1 | BUG-189 |
| LOW | 1 | BUG-190 |

## Bug List

| Bug ID | Issue | Severity | Summary |
|--------|-------|----------|---------|
| BUG-188 | #312 | HIGH | Territory markers never instantiated — territorial marking system non-functional |
| BUG-189 | #316 | MEDIUM | `sniff` (ambient, no target) returns error instead of room smell |
| BUG-190 | #323 | LOW | Wolf scent vanishes instantly when wolf leaves room — no lingering territorial scent |

## Test Methodology

- Headless pipe-based testing (`--headless` mode)
- Navigated: Bedroom → Cellar → Storage Cellar → Deep Cellar → Hallway
- Tested `smell` in all 5 rooms reached
- Tested `look`, `feel around`, `sniff`, and targeted smell variants
- Multiple room transitions to trigger wolf movement and potential territory marking
- Wolf encountered in deep-cellar and hallway across multiple sessions

## Individual Tests

### T-001: `smell` in hallway (wolf's home room)
**Command:** `smell`
**Response:** Beeswax polish, torch smoke, old wood. Lists: torches, portraits, side table, vase, doors, staircase, matchbox, iron key. **No territory marker listed.**
**Verdict:** ❌ FAIL
**Bug:** BUG-188 — Wolf's home room should contain territory markers

### T-002: `look` in hallway — territory marker should NOT appear
**Command:** `look around`
**Response:** Full room description with furniture, doors, staircase. No mention of territory marker, scent, or musk.
**Verdict:** ✅ PASS — Territory markers are correctly invisible to `look` (or absent entirely due to BUG-188)

### T-003: `feel around` in hallway — territory marker should NOT be found
**Command:** `feel around`
**Response:** Lists: torches, portraits, side table, door, steps, staircase, doors. No territory marker.
**Verdict:** ✅ PASS — Territory markers correctly not discoverable by touch (or absent due to BUG-188)

### T-004: `smell` in deep cellar (wolf present)
**Command:** `smell`
**Response:** Lists all room objects including: "a grey wolf -- Wet dog and old meat. A predator's musk, sharp and territorial." **No territory marker listed separately.**
**Verdict:** ❌ FAIL
**Bug:** BUG-188 — Wolf present and active, but no territory marker created in room

### T-005: `smell territory` in hallway
**Command:** `smell territory`
**Response:** "You can't find anything like that to smell."
**Verdict:** ❌ FAIL
**Bug:** BUG-188 — No territory marker exists to smell by keyword

### T-006: `smell musk` in hallway
**Command:** `smell musk`
**Response:** "You can't find anything like that to smell."
**Verdict:** ❌ FAIL
**Bug:** BUG-188 — Territory marker keywords ("musk") not found

### T-007: `smell scent` in hallway
**Command:** `smell scent`
**Response:** "You can't find anything like that to smell."
**Verdict:** ❌ FAIL
**Bug:** BUG-188

### T-008: `sniff` (ambient, no target) in hallway
**Command:** `sniff`
**Response:** "You can't find anything like that to smell."
**Verdict:** ❌ FAIL
**Bug:** BUG-189 — `sniff` should work as synonym for ambient `smell`

### T-009: `sniff around` in hallway
**Command:** `sniff around`
**Response:** "You can't find anything like that to smell."
**Verdict:** ❌ FAIL
**Bug:** BUG-189

### T-010: `smell wolf` after wolf departs
**Command:** `smell wolf` (immediately after "A grey wolf scurries south.")
**Response:** "You can't find anything like that to smell."
**Verdict:** ⚠️ WARN
**Bug:** BUG-190 — Wolf scent should linger for a few turns after departure

### T-011: `smell` in cellar (wolf visited)
**Command:** `smell`
**Response:** Lists barrel, trap door, iron-bound door, spider, brazier, matchbox. **No territory marker. No wolf scent.**
**Verdict:** ⚠️ WARN — Wolf was observed in this room earlier but left no scent trail

### T-012: `smell` in storage cellar
**Command:** `smell`
**Response:** Lists crates, wine rack, grain, lantern, rope, flask, spittoon, doors, match, crowbar, matchbox. **No territory marker.**
**Verdict:** ✅ PASS — Wolf not expected in storage cellar (no direct path)

### T-013: Wolf present in deep cellar (encounter check)
**Command:** Enter deep cellar
**Response:** "A wolf paces the room, sniffing the air." Wolf ambient messages appear consistently.
**Verdict:** ✅ PASS — Wolf creature is alive and active

### T-014: Wolf movement between rooms
**Command:** Multiple room transitions (hallway ↔ deep cellar)
**Response:** Wolf observed in both deep cellar and hallway. Messages: "A wolf paces the room, sniffing the air.", "A grey wolf scurries south/up/down."
**Verdict:** ✅ PASS — Wolf moves between rooms

### T-015: Wolf patrol behavior — independent territory patrol
**Command:** Observed wolf movement across multiple turns
**Response:** Wolf appears to follow the player between rooms rather than independently patrolling. Wolf always appears in the room the player is in or just entered. No observed independent patrol circuit.
**Verdict:** ⚠️ WARN — Wolf may be chase-following the player instead of patrolling territory boundaries. Difficult to verify in headless mode since wolf and player end up in same room.

### T-016: Non-alpha wolf territory avoidance
**Command:** N/A — cannot test
**Response:** Only 1 wolf exists in Level 1. Territory markers are not created (BUG-188). Cannot test whether a non-alpha wolf avoids marked territory.
**Verdict:** ❌ FAIL (blocked)
**Bug:** BUG-188 — Prerequisite system not functional

## Smell Detection Coverage

| Room | Territory Marker in `smell`? | Wolf in `smell`? |
|------|------------------------------|-------------------|
| Bedroom | ❌ No | N/A (wolf not here) |
| Cellar | ❌ No | Wolf visited but not in smell output |
| Storage Cellar | ❌ No | N/A |
| Deep Cellar | ❌ No | ✅ Yes (when present) |
| Hallway | ❌ No | Wolf ambient msg appears but not in smell |

## Wolf Behavior Observations

- **Home room:** Hallway (per creature definition), but wolf frequently found in deep cellar
- **Movement:** Wolf moves between deep-cellar and hallway, occasionally visits cellar
- **Reaction to player:** Ambient messages ("paces the room, sniffing the air", "head snaps toward you, deep growl") — wolf acknowledges player presence
- **Combat:** Not tested (out of scope for Q5)
- **Territory marking:** Not observed in any room across all test sessions

## Conclusions

1. **Territory marking system non-functional** — The code exists and is wired into the game loop, but markers are never created. This is the central failure of Q5.
2. **Smell verb works well for present objects** — When the wolf is in the room, `smell` correctly reports its scent. The sensory system itself is solid.
3. **Sniff synonym broken for ambient use** — `sniff` only works for targeted objects, not ambient room smell.
4. **Wolf creature AI partially works** — The wolf moves, has ambient messages, and responds to player presence. But it doesn't mark territory or demonstrate patrol patterns.
5. **Non-alpha avoidance untestable** — With no territory markers and only 1 wolf, this scenario cannot be verified.

---
*Nelson — QA Tester*
*Every bug you find now is a bug the player never sees.*
