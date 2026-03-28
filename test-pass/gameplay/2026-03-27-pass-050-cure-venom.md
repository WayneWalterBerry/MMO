# Pass-050: LLM Playtest — Cure Spider Venom with Antidote-Vial
**Date:** 2026-03-27
**Tester:** Nelson (LLM Playtest)
**Build:** lua src/main.lua --headless
**Method:** Headless pipe-based testing (Pattern 1 from SKILL.md)

## Executive Summary

Targeted playtest of the spider venom → antidote cure gameplay loop. Fought the spider across **7 independent sessions**, checked for venom injury infliction, navigated to the storage cellar to locate the antidote-vial, and attempted the full cure sequence.

**Result: Complete failure of the venom/cure loop.** Two blocking bugs prevent this feature from working at all.

- **Total sessions run:** 7
- **Total individual tests:** 11
- **Bugs found:** 3
- **Pass:** 5
- **Fail:** 6

### Severity Breakdown

| Severity | Count |
|----------|-------|
| CRITICAL | 1     |
| HIGH     | 1     |
| MEDIUM   | 1     |

## Bug List

| Bug ID  | Severity | Summary |
|---------|----------|---------|
| BUG-177 | CRITICAL | Creature counter-attacks set `result.defender=nil` — no damage, injuries, or on_hit effects (venom) ever apply to the player |
| BUG-178 | HIGH     | Antidote-vial not placed in any room — decided for storage-cellar wine-rack but never implemented |
| BUG-179 | MEDIUM   | Combat narration describes damage landing ("warm blood and torn flesh") but player takes zero actual damage |

## Root Cause Analysis

### BUG-177 — The Venom Pipeline Is Completely Disconnected

**Location:** `src/engine/combat/resolution.lua`, function `R.update()`, line 340

**Evidence from debug trace (temporary `io.stderr` logging added to `R.update()`):**

```
-- Player attacks spider: defender is correctly populated
[DBG] atk=? def=deep-cellar-spider def.health=3 sev=1 wpn=punch

-- Spider attacks player: DEFENDER IS NIL
[DBG] atk=deep-cellar-spider def=nil def.health=nil sev=0 wpn=bite
```

**Mechanism:** When `resolve_exchange(creature, player, ...)` is called for the spider's counter-attack, the returned `result.defender` is `nil`. The `R.update()` function early-returns at line 340:

```lua
if not defender or not defender.health then return result end
```

This means for ALL creature→player attacks:
1. ❌ No HP damage applied to the player
2. ❌ No combat injuries inflicted (C11 path skipped)
3. ❌ No on_hit disease delivery — spider-venom NEVER triggers (Track 4C skipped)

The spider's bite weapon IS correctly selected (debug shows `wpn=bite`), and the `on_hit` property IS preserved through `normalize_weapon()`. But none of it matters because the defender is nil.

**Statistical confirmation:** Across 7 sessions with ~12 spider bite attempts at 60% venom probability, zero venom was inflicted. The probability of this by chance alone is `(0.4)^12 ≈ 0.0017%`. This is not bad luck — it's a code path that never executes.

### BUG-178 — Antidote-Vial Not Placed in World

**Decision exists** in `.squad/decisions/inbox/Moe-phase3-review.md`:
> DECISION: Antidote-vial placement → storage-cellar wine-rack.

**Object definition exists** at `src/meta/objects/antidote-vial.lua` with correct `cures = {"spider-venom"}` property.

**But** `src/meta/rooms/storage-cellar.lua` wine-rack contents only has `wine-bottle`. The antidote-vial instance was never added. Searching the storage cellar reveals: large crate, iron key, small crate, wine bottle, grain sack, oil lantern, rope, crowbar, oil flask, spittoon. No antidote.

### BUG-179 — Phantom Damage Narration

Combat text shows spider bites landing with graphic prose ("warm blood and torn flesh", "the fangs bites into flesh") but because `R.update()` skips processing, the player's health never decreases. The `health` command reports "You feel fine. No injuries to speak of." This creates a jarring disconnect where the player reads about injuries that don't exist in the game state.

## Individual Tests

### T-001: Navigate to deep-cellar
**Input:** `goto deep-cellar`
**Response:**
```
You materialize in The Deep Cellar.
**The Deep Cellar**
It is too dark to see. You need a light source. Try 'feel' to grope around
in the darkness. It is 2:00 AM.
The spider tenses, front legs raised. The web trembles.
A wolf paces the room, sniffing the air.
```
**Verdict:** ✅ PASS — Spider is present in deep-cellar as expected. Room atmosphere is excellent.

### T-002: Attack spider (×7 sessions)
**Input:** `attack spider`
**Response (representative):**
```
You can't see well — attacks will be less accurate.
You engage a large brown spider with bare fists!
A wet thud and sharp pain in someone's arm; the fangs bites into flesh.
A heavy impact on someone's torso — warm blood and torn flesh.
A heavy impact on a large brown spider's cephalothorax — warm blood and torn flesh.
The spider's abdomen splits, spilling a tangle of silk.
a large brown spider is dead!
```
**Verdict:** ❌ FAIL (BUG-177) — Spider bites narrated as landing ("fangs bites into flesh", "warm blood and torn flesh") but no venom inflicted. Player takes zero damage. Across 7 sessions with multiple spider bites, venom triggered exactly 0 times.

### T-003: Check health after spider fight
**Input:** `health`
**Response:** `You feel fine. No injuries to speak of.`
**Verdict:** ❌ FAIL (BUG-177, BUG-179) — After combat where spider landed penetrating bites, player has no injuries and full health. The narration described "warm blood and torn flesh" but game state is pristine.

### T-004: Check injuries after spider fight
**Input:** `injuries`
**Response:** `You feel fine. No injuries to speak of.`
**Verdict:** ❌ FAIL (BUG-177) — Confirms no spider-venom injury was inflicted. Expected at least combat damage injuries if not venom.

### T-005: Feel in deep-cellar after fight
**Input:** `feel`
**Response:**
```
You reach out in the darkness, feeling around you...
  a stone altar, an iron wall sconce, an iron wall sconce,
  a stone sarcophagus, an iron chain, the iron door,
  a wide stone stairway, a stone archway with an iron gate,
  a dead spider, a dead spider, a grey wolf
```
**Verdict:** ✅ PASS — Dead spider is tactile. Room objects all discoverable.

### T-006: Navigate to storage-cellar
**Input:** `goto storage-cellar`
**Response:**
```
You materialize in The Storage Cellar.
**The Storage Cellar**
It is too dark to see. You need a light source.
```
**Verdict:** ✅ PASS — Room accessible. One room south of deep-cellar (correct adjacency for antidote placement).

### T-007: Search storage-cellar for antidote
**Input:** `search around`
**Response:**
```
On top of the large wooden crate, you feel: a small wooden crate.
Inside the large wooden crate, you feel: a heavy iron key.
Inside the wooden wine rack, you feel: a dusty wine bottle.
You feel a heavy sack of grain...
You feel a brass oil lantern...
You feel a coil of rope...
You feel an iron crowbar...
You feel a small ceramic oil flask...
You check inside the brass spittoon. It's empty.
You finish searching the area. Nothing interesting.
```
**Verdict:** ❌ FAIL (BUG-178) — No antidote-vial found anywhere in storage-cellar. Wine rack contains only wine bottle.

### T-008: Take antidote
**Input:** `take antidote`
**Response:** `You don't notice anything called that nearby. Try 'search around' to discover what's here.`
**Verdict:** ❌ FAIL (BUG-178) — Antidote not in game world.

### T-009: Use antidote
**Input:** `use antidote`
**Response:** `You don't notice anything called that nearby. Try 'search around' to discover what's here.`
**Verdict:** ❌ FAIL (BUG-178) — Cannot use nonexistent item.

### T-010: Feel in storage-cellar
**Input:** `feel`
**Response:**
```
You reach out in the darkness, feeling around you...
  a large wooden crate, a wooden wine rack, a heavy sack of grain,
  a brass oil lantern, a coil of rope, an iron crowbar,
  a small ceramic oil flask, a brass spittoon,
  the iron-bound door, a second iron-bound door
```
**Verdict:** ✅ PASS — Storage cellar objects all discoverable by touch.

### T-011: Second attack attempt (spider already dead)
**Input:** `attack spider` (2nd time)
**Response:** `You don't see that here to attack.`
**Verdict:** ✅ PASS — Correct response for dead target. Could improve to say "The spider is already dead."

## Gameplay Loop Assessment

The intended spider venom → antidote cure loop:

| Step | Expected | Actual | Status |
|------|----------|--------|--------|
| 1. Fight spider | Spider bites, venom inflicted (60% per bite) | Spider bites narrated but venom never inflicted | ❌ BLOCKED |
| 2. Check venom injury | `injuries` shows "spider-venom (injected)" | "No injuries to speak of" | ❌ BLOCKED |
| 3. Navigate to storage-cellar | Player backtracks one room south | Room accessible | ✅ OK |
| 4. Find antidote in wine-rack | `search` reveals antidote-vial in wine-rack | Wine-rack contains only wine bottle | ❌ BLOCKED |
| 5. Take antidote | `take antidote` picks up vial | Item doesn't exist in world | ❌ BLOCKED |
| 6. Use antidote to cure venom | `use antidote` triggers healing_interactions | Cannot test — items missing | ❌ BLOCKED |
| 7. Verify cure | `injuries` shows no venom | Cannot test | ❌ BLOCKED |

**Conclusion:** 0% of the cure loop is functional. Two independent bugs (BUG-177 and BUG-178) each individually prevent the entire feature from working.

## Recommendations

### P0 — Must fix before any disease/cure testing:
1. **BUG-177**: Fix `resolve_exchange()` or `R.update()` so that creature→player attacks populate `result.defender` with the player object. This is a fundamental combat system bug that affects ALL creature damage and disease delivery.
2. **BUG-178**: Add `antidote-vial` to storage-cellar wine-rack contents (one-line change in `src/meta/rooms/storage-cellar.lua`).

### P1 — Fix before playtest re-run:
3. **BUG-179**: Audit combat narration to ensure text matches actual game state (don't describe "warm blood" if no damage is applied).

### Re-test plan:
After BUG-177 and BUG-178 are fixed, re-run this exact playtest to verify:
- Venom infliction at expected ~60% rate
- Antidote discoverable in wine-rack
- `use antidote` cures venom in "injected" and "spreading" states
- Cure message matches `healing_interactions` definition
- Venom progression (injected → spreading → paralysis) if untreated

## Sign-off

Playtest complete. The spider venom → antidote cure feature is **completely non-functional** due to two blocking bugs. BUG-177 (nil defender on creature attacks) is the more severe issue — it means **no creature in the game can damage the player or inflict any disease**. This is a systemic combat engine bug, not specific to the spider.

— Nelson, Tester
