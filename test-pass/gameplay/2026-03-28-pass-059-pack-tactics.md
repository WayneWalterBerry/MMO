# Pass-059: Pack Tactics Combat Playtest

**Date:** 2026-03-28
**Tester:** Nelson
**Build:** Lua src/main.lua --headless
**Scope:** Pack tactics system — stagger attacks, alpha behavior, retreat, flee, lone wolf

## Executive Summary

**Total Tests:** 11
**Pass:** 2 | **Fail:** 6 | **Warn:** 2 | **Blocked:** 1
**Bugs Filed:** 6

Pack tactics are **untestable in the current game world**. Only 1 wolf exists (hallway, `max_population = 1`). The pack tactics code (`src/engine/creatures/pack-tactics.lua`) implements alpha selection, stagger, retreat, and doorway positioning, but none of these features can trigger at runtime because a pack requires 2+ wolves of the same species in the same room.

Additionally, the single wolf exhibits severe behavioral issues: it never initiates combat against the player (player not in prey list), always wanders away from the player's room, and never retreats at low health during player-initiated combat due to a `max_health` lookup bug.

## Bug List

| Bug ID | Severity | Summary | Issue |
|--------|----------|---------|-------|
| BUG-200 | **CRITICAL** | Pack tactics untestable — only 1 wolf in game, `max_population = 1` | Filed |
| BUG-201 | **HIGH** | Wolf never retreats in player combat — `creature.combat.max_health` is nil, flee ratio always 1.0 | Filed |
| BUG-202 | **HIGH** | Wolf never attacks player — player not in `behavior.prey` list | Filed |
| BUG-203 | **MEDIUM** | Combat narration uses "Someone" instead of "You" for player actions | Filed |
| BUG-204 | **MEDIUM** | Grammar errors in combat narration — subject-verb disagreement | Filed |
| BUG-205 | **LOW** | No standalone "flee" or "run" verb outside combat context | Filed |

## Individual Tests

---

### T-001: Find room with multiple wolves
**Input:** Navigate to hallway (wolf's home room) and all connected rooms
**Response:** Only 1 wolf instance found in entire game. Wolf wanders between hallway and deep cellar. No second wolf anywhere.
**Verdict:** ❌ FAIL
**Bug:** BUG-200
**Details:** `wolf.lua` has `respawn.max_population = 1`. `hallway.lua` contains exactly 1 wolf instance (`hallway-wolf`). No other room definition contains wolf instances. Pack tactics require 2+ wolves of the same `id` in the same room — this condition can never be met.

---

### T-002: Observe staggered attacks (2+ wolves)
**Input:** N/A — requires 2+ wolves
**Response:** N/A
**Verdict:** 🔒 BLOCKED (by BUG-200)
**Details:** Cannot test stagger behavior without multiple wolves. Code review confirms `pack-tactics.plan_attack()` implements correct stagger (alpha attacks turn 0, beta waits via `_pack_waited` flag), but this path is never executed at runtime.

---

### T-003: Alpha wolf selection (highest health attacks first)
**Input:** N/A — requires 2+ wolves
**Response:** N/A
**Verdict:** 🔒 BLOCKED (by BUG-200)
**Details:** Code review confirms `select_alpha()` correctly selects highest-health wolf with max_health tiebreaker. Unit tests in `test/creatures/test-pack-tactics.lua` pass. But runtime verification is impossible with 1 wolf.

---

### T-004: Wolf retreat at <20% health
**Input:** `attack wolf` (with crowbar, in hallway after waiting for wolf to arrive)
**Response:** Full combat to the death. Wolf fought through all health levels without retreating. Both combatants died.
**Verdict:** ❌ FAIL
**Bug:** BUG-201
**Details:** In `src/engine/verbs/init.lua` line 447:
```lua
local max_hp = creature.combat.max_health or creature.health or 10
```
Wolf has `max_health = 40` at top level but NO `combat.max_health` field. The lookup chain falls through to `creature.health` (current health), making `hp_pct = current/current = 1.0` always. The 20% threshold never triggers. Should use `creature.max_health or creature.combat.max_health or creature.health or 10`.

---

### T-005: Wolf attacks player (unprovoked)
**Input:** Enter hallway, wait 3 turns with wolf present
**Response:** Wolf wanders in and out of room. Never attacks player. Only reaction is `"The wolf's head snaps toward you. A deep growl fills the passage."` then wolf moves away next tick.
**Verdict:** ❌ FAIL
**Bug:** BUG-202
**Details:** Wolf's `behavior.prey = {"rat", "cat", "bat"}` — player is not in prey list. Action scoring only scores "attack" if `prey_in_room` is true. Wolf has `aggression = 70` and `territorial` behavior, but the attack action is never considered against the player. The wolf should treat the player as a threat/intruder in territorial mode.

---

### T-006: Lone wolf attacks normally (no pack stagger)
**Input:** `attack wolf` (after wait, wolf present in hallway)
**Response:** Combat engaged immediately. Wolf fought continuously with no idle turns.
**Verdict:** ✅ PASS
**Details:** With only 1 wolf, `get_pack_in_room()` returns a pack of size 1. The stagger code correctly skips for single wolves (`if #pack == 1 then return`). Wolf attacked every exchange round without delay. This confirms single-wolf combat works correctly (no false stagger).

---

### T-007: Player-initiated combat with wolf
**Input:** `attack wolf`
**Response:** `"You engage a grey wolf with a brass candle holder!"` followed by full combat exchange to the death.
**Verdict:** ✅ PASS (combat engages)
**Details:** Combat successfully initiated. The auto-resolved combat in headless mode ran 15+ exchange rounds. Wolf counter-attacked each round. Both combatants accumulated injuries and died. Combat loop functioned correctly.

---

### T-008: Combat narration — player identity
**Input:** `attack wolf` (observed narration output)
**Response:** All player attacks narrated as "Someone cracks...", "Someone drives the brass into..." — never "You".
**Verdict:** ❌ FAIL
**Bug:** BUG-203
**Details:** `narration.lua` line 60 checks `actor.id == "player" or actor.is_player` to return "You". The player object apparently lacks both markers when passed through `combat_mod.resolve_exchange()`. The fix attempt (#289) in narration.lua isn't working. Every player action reads as "Someone" — completely breaks immersion.

---

### T-009: Combat narration grammar
**Input:** `attack wolf` (observed narration output)
**Response:** Multiple grammar errors:
- `"the claws fails to bite"` → should be "the claws fail to bite"
- `"the organs gives way"` → should be "the organs give way"
- `"the brass glances off"` → acceptable (brass singular)
- `"the claws glances off"` → should be "the claws glance off"
**Verdict:** ❌ FAIL
**Bug:** BUG-204
**Details:** The narration template system doesn't handle plural nouns correctly for verb conjugation. "claws" and "organs" are plural but get singular verb forms. Appears to be a pattern: all natural weapon names treated as singular for verb agreement.

---

### T-010: Player flee from wolf
**Input:** `flee`, `run` (while wolf present after waiting)
**Response:**
- `flee` → `"a heavy oak door is barred."` (parsed as movement south)
- `run` → `"Go where?"` (not recognized as flee)
**Verdict:** ⚠️ WARN
**Bug:** BUG-205
**Details:** The "flee" verb only exists within the combat stance selection system (attack → stance prompt → flee option). Outside of combat, "flee" is parsed as a directional movement or fails entirely. There's no standalone verb for running away from a threatening creature. Players who type "flee" or "run" when a wolf is present get confusing responses.

---

### T-011: Wolf wander behavior — avoids player
**Input:** Enter any room containing the wolf; observe across multiple sessions.
**Response:** Every time the player enters a room with the wolf, the wolf moves to an adjacent room during the same creature tick. Pattern observed across 5+ room transitions:
- Deep cellar: wolf present → player enters → `"A grey wolf scurries up."`
- Hallway: wolf present → player enters → `"A grey wolf scurries down."`
**Verdict:** ⚠️ WARN
**Details:** Wolf has aggression 70 and territorial behavior, yet it consistently moves away from the player. The `player_enters` reaction fires (growl message appears), but the creature action system then selects "wander" as the best action, causing the wolf to leave. This creates a frustrating game experience — the wolf feels like it's playing keep-away. Players cannot observe, interact with, or fight the wolf without getting lucky with timing (e.g., waiting until the wolf wanders back).

---

## Code Review Notes (Pack Tactics Module)

The pack tactics code in `src/engine/creatures/pack-tactics.lua` was reviewed directly since runtime testing was blocked:

| Function | Status | Notes |
|----------|--------|-------|
| `select_alpha(pack, ctx)` | ✅ Logic correct | Highest health, max_health tiebreaker |
| `plan_attack(pack, ctx)` | ✅ Logic correct | Alpha delay=0, others stagger by 1 |
| `should_retreat(creature, ctx)` | ✅ Logic correct | hp/max_hp < 0.20 check |
| `get_pack_in_room(registry, room_id, creature)` | ✅ Logic correct | Same id, animate, not dead, same room |
| `prefers_doorway(creature, ctx, get_room_fn)` | ⚠️ Trivial | Returns true if room has any exits (always true) |

Integration in `creatures/init.lua` lines 315-334 correctly gates stagger behind `#pack > 1` and skips for lone wolves. The `_pack_waited` alternation mechanism looks correct but has never executed at runtime.

Unit tests in `test/creatures/test-pack-tactics.lua` (4 tests) all pass — they verify alpha selection, stagger delays, single-wolf bypass, and retreat threshold using mock objects.

## Recommendations

1. **Add a second wolf instance** to hallway or an adjacent room to enable pack tactics testing at runtime. Even for playtesting, `max_population` should be ≥2 for the hallway wolf.
2. **Fix the flee threshold bug** — line 447 of `verbs/init.lua` should use `creature.max_health` not `creature.combat.max_health`.
3. **Add "player" to wolf threat list** — wolves with `territorial` behavior should consider the player a valid attack target, not just prey species.
4. **Fix "Someone" narration** — verify player object has `id = "player"` or `is_player = true` when passed to combat resolution.
5. **Add standalone flee verb** — players should be able to type "flee" or "run" outside the combat stance system.
6. **Investigate wolf keep-away behavior** — the wolf's action scoring causes it to always wander away from the player, making encounters feel broken.

---

**Signed:** Nelson, Tester — 2026-03-28
