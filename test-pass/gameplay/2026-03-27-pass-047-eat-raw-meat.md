# Pass-047: Eat Raw Meat — Food Poisoning Consequence

**Date:** 2026-03-27
**Tester:** Nelson
**Build:** `lua src/main.lua --headless`
**Method:** Headless pipe-based testing (SKILL.md Pattern 1)

## Executive Summary

**Total tests:** 7 | **Pass:** 6 | **Warn:** 1 | **Fail:** 0

The food poisoning system for eating raw meat works correctly end-to-end. Eating a dead rat produces vivid taste text, stomach rebellion messages, a persistent `stomach cramps` injury visible in `status`, and an ongoing nausea effect that triggers on subsequent actions. A cooking hint is displayed. No crashes or hangs.

One warning noted: combat text has pre-existing grammar issues in weapon/body-part agreement (not related to the eat system, but observed during the test).

## Bug List

| Bug ID | Severity | Summary |
|--------|----------|---------|
| — | — | No new bugs found for the eat-raw-meat system |
| (obs) | LOW | Pre-existing combat grammar: "The fangs bites", "the claws glances off", "sinks its teeth into toward" — subject-verb disagreement and doubled prepositions in combat messages (not new, not scoped to this pass) |

## Test Session

### Command Sequence (Run 1)

```
goto cellar
attack rat
take dead rat
eat dead rat
look
feel
inventory
```

### Command Sequence (Run 2 — injury persistence)

```
goto cellar
attack rat
take dead rat
eat dead rat
status
wait
wait
wait
```

---

## Individual Tests

### T-001: `goto cellar`
**Input:** `goto cellar`
**Response:** Player materializes in The Cellar. Full room description rendered with brazier, barrel, torch bracket, stairway, locked door, and rat. Exits shown (up, north). Time displayed (2:00 AM).
**Verdict:** ✅ PASS
**Notes:** Room renders correctly. Rat is present and described.

### T-002: `attack rat`
**Input:** `attack rat`
**Response:** Multi-round combat with bare fists. Blow-by-blow narration. Combat concludes: `a brown rat is dead!`
**Verdict:** ✅ PASS
**Notes:** Combat resolves correctly. Rat dies after several rounds. Combat messages are vivid. (Grammar issues in combat text noted as observation — pre-existing, not scoped here.)

### T-003: `take dead rat`
**Input:** `take dead rat`
**Response:** `You take a dead rat.`
**Verdict:** ✅ PASS
**Notes:** Dead rat is takeable. Clean response.

### T-004: `eat dead rat` ⭐ Primary Test
**Input:** `eat dead rat`
**Response:**
```
Fur and blood. You immediately regret this decision.
You choke it down. Your stomach rebels almost immediately.
Your stomach lurches. Something you ate is fighting back.
(Hint: Cooking raw meat makes it safe to eat and more nourishing.)
```
**Verdict:** ✅ PASS
**Verification Checklist:**
- [x] **Taste text present:** "Fur and blood. You immediately regret this decision." — visceral, appropriate
- [x] **Stomach rebellion message:** "You choke it down. Your stomach rebels almost immediately." — clear consequence
- [x] **Food poisoning warning:** "Your stomach lurches. Something you ate is fighting back." — ongoing symptom
- [x] **Cooking hint:** "(Hint: Cooking raw meat makes it safe to eat and more nourishing.)" — player guidance provided
- [x] **Rat consumed:** Rat no longer in inventory or room after eating

### T-005: `look` (post-eat)
**Input:** `look`
**Response:** Full room description. Dead rat no longer listed in room contents. No anomalies.
**Verdict:** ✅ PASS
**Notes:** Rat was consumed — not dropped, not duplicated. Room state is clean.

### T-006: `feel` (food poisoning persistence)
**Input:** `feel`
**Response:**
```
You reach out in the darkness, feeling around you...
  an old barrel
  an iron torch bracket
  a narrow stone stairway
  a heavy iron-bound door
  an iron brazier
The cramps worsen. A wave of nausea doubles you over. This is going to
be rough.
```
**Verdict:** ✅ PASS
**Notes:** Food poisoning effect persists across commands. "The cramps worsen" fires as an ongoing effect after the `feel` action. This is excellent — the injury isn't just a one-shot message, it's a persistent condition that reminds the player they made a bad choice.

### T-007: `status` (injury verification — Run 2)
**Input:** `status`
**Response:**
```
You examine yourself:
  stomach cramps — Your stomach twists and cramps. Cold sweat prickles your
  forehead. Something you ate was bad.
Health: 100/100
```
**Verdict:** ✅ PASS
**Notes:** The `stomach cramps` injury is registered and visible in player status. Description is flavorful and appropriate. Health remains 100/100 — food poisoning is an injury/condition, not direct HP damage. This is good design.

### T-008: `wait` (effect decay — Run 2)
**Input:** `wait` (×3)
**Response:**
```
Time passes.
The cramps worsen. A wave of nausea doubles you over. This is going to be rough.
---END---
Time passes.
---END---
Time passes.
---END---
```
**Verdict:** ⚠️ WARN
**Notes:** The nausea effect fired once on the first `wait`, then stopped. This could mean: (a) the effect has a tick timer and only fires periodically, (b) it decays naturally, or (c) it's a one-shot delayed effect. Behavior seems intentional but worth confirming with design — does food poisoning eventually resolve on its own, or does it require treatment? Not a bug, but flagged for design clarity.

---

## Observations

### Combat Text Grammar (Pre-existing)
Observed during `attack rat` — not new to this pass but worth noting:
- `"The fangs bites at someone's torso"` → should be "bite" (plural subject)
- `"the claws glances off"` → should be "glance" (plural subject)
- `"sinks its teeth into toward someone's chest"` → doubled preposition "into toward"
- `"the keratin skitters off someone's thigh as A brown rat"` → uppercase "A" mid-sentence

These are subject-verb agreement and preposition issues in the combat narration system. Not scoped to eat-raw-meat testing but visible during the combat required to produce a dead rat.

## Summary

The eat-raw-meat → food-poisoning pipeline is **fully functional**:

1. **Taste text** — vivid and disgusting ("Fur and blood")
2. **Stomach rebellion** — immediate consequence ("Your stomach rebels")
3. **Food poisoning injury** — registered as `stomach cramps` in `status`
4. **Persistent effects** — nausea fires on subsequent actions ("The cramps worsen")
5. **Cooking hint** — player guidance to cook meat instead
6. **Inventory cleanup** — rat is consumed, not duplicated

No bugs found. The system delivers a satisfying consequence chain that teaches the player raw meat is dangerous while pointing them toward the cooking mechanic.

---

**Signed:** Nelson, Tester
**Pass result:** ✅ ALL CLEAR — food poisoning consequence verified
