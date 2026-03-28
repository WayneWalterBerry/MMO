# Pass-048: Kill → Cook → Eat Gameplay Loop (Phase 3 Critical Path)
**Date:** 2026-03-27
**Tester:** Nelson (LLM Playtest)
**Build:** lua src/main.lua --headless
**Method:** Headless pipe-based testing (Pattern 1 from SKILL.md)

## Executive Summary

Playtested the **full kill→cook→eat gameplay loop** in the Cellar — the Phase 3 critical path. All 9 critical-path steps **PASS**. The loop is mechanically complete and playable end-to-end. Six edge-case tests also pass. Found **8 bugs** in combat text generation (grammar, pronouns, truncation) and health feedback. No blockers.

- **Total tests:** 18
- **Critical path:** 9/9 ✅ PASS
- **Edge cases:** 6/6 ✅ PASS
- **Warnings:** 2 (health tracking unclear)
- **Combat text bugs:** 4 (LOW–MEDIUM)
- **Other bugs:** 2 (LOW)

### Severity Breakdown

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 4 |
| LOW | 4 |

## Bug List

| Bug ID | Severity | Summary |
|--------|----------|---------|
| BUG-165 | MEDIUM | Combat text uses "someone" instead of "you" for the player |
| BUG-166 | MEDIUM | Capitalized "A" mid-sentence in combat deflection text |
| BUG-167 | MEDIUM | Truncated combat sentences — ends with "sinks its teeth into." (no object) |
| BUG-168 | LOW | Subject-verb disagreement: "the claws fails", "the claws glances", "the teeth fails" |
| BUG-169 | LOW | Unicode encoding artifact "ΓÇö" instead of em-dash in eating hint |
| BUG-170 | LOW | Death announcement "a brown rat is dead!" starts with lowercase "a" |
| BUG-171 | MEDIUM | No explicit health restoration feedback when eating cooked meat |
| BUG-172 | LOW | Combat hits that "draw blood" don't register as injuries on `health` check |

## Critical Path Verification

### Step-by-Step Loop

| Step | Input | Expected | Actual | Result |
|------|-------|----------|--------|--------|
| 1. Enter cellar | `goto cellar` | Arrive in cellar | "You materialize in The Cellar." | ✅ |
| 2. Rat present | `look` | Rat visible | "A panicked rat zigzags across the floor." | ✅ |
| 3. Kill rat | `attack rat` | Rat dies | "a brown rat is dead!" | ✅ |
| 4. Corpse appears | `look` | Dead rat on floor | "A dead rat lies crumpled on the floor." | ✅ |
| 5. Take corpse | `take dead rat` | Corpse in hand | "You take a dead rat." | ✅ |
| 6. Cook with brazier | `cook rat` | Meat produced | "The fur singes away and the flesh darkens." | ✅ |
| 7. Cooked in inventory | `inventory` | Cooked meat shown | "Left hand: a piece of cooked rat meat" | ✅ |
| 8. Eat cooked meat | `eat cooked rat` | Meat consumed | "Gamey and tough, with a smoky char." | ✅ |
| 9. Meat gone | `inventory` | Hands empty | "Left hand: (empty) / Right hand: (empty)" | ✅ |

**CRITICAL PATH VERDICT: ✅ ALL 9 STEPS PASS**

## Individual Tests

### T-001: goto cellar
**Input:** `goto cellar`
**Response:** "You materialize in The Cellar." Full room description with rat, brazier, barrel, exits.
**Verdict:** ✅ PASS — Teleport works. Room fully described with all expected objects.

### T-002: look (rat present)
**Input:** `look`
**Response:** Full room description. "There is a brown rat here." and "A panicked rat zigzags across the floor."
**Verdict:** ✅ PASS — Rat is present and has ambient behavior text.

### T-003: attack rat
**Input:** `attack rat`
**Response:** Multi-round combat. Player uses bare fists. Rat fights back with teeth/claws. After several rounds: "a brown rat is dead!"
**Verdict:** ✅ PASS — Combat resolves. Rat dies. But see BUG-165 through BUG-168 for combat text quality issues.

**Combat text excerpt (showing bugs):**
```
Someone punches a brown rat's shin, leaving a shallow mark in the hide.
A brown rat drives the tooth-enamel into someone's skull, drawing blood from the flesh.
The tooth-enamel skitters off someone's torso as A brown rat sinks its teeth into.
```
- "Someone" should be "You" (BUG-165)
- Capital "A" mid-sentence (BUG-166)
- Sentence truncated after "into." (BUG-167)

### T-004: look (corpse visible)
**Input:** `look`
**Response:** "A dead rat lies crumpled on the floor."
**Verdict:** ✅ PASS — Live rat replaced by dead rat in room description. Clean state transition.

### T-005: take dead rat
**Input:** `take dead rat`
**Response:** "You take a dead rat."
**Verdict:** ✅ PASS — Corpse is takeable.

### T-006: cook rat
**Input:** `cook rat`
**Response:** "You hold the rat over the flames. The fur singes away and the flesh darkens. (Hint: Cooking raw meat makes it safe to eat and more nourishing.)"
**Verdict:** ✅ PASS — Cooking works. Brazier proximity auto-detected. Dead rat transforms to cooked meat. Hint system provides guidance.

### T-007: inventory (cooked meat present)
**Input:** `inventory`
**Response:** "Left hand: a piece of cooked rat meat / Right hand: (empty)"
**Verdict:** ✅ PASS — Dead rat correctly mutated into cooked rat meat.

### T-008: eat cooked rat
**Input:** `eat cooked rat`
**Response:** "You eat a piece of cooked rat meat. Gamey and tough, with a smoky char. The flavor is strong -- wild, not farmed. Edible, if you don't think about it. The rat meat is gamey but filling. (Hint: Careful what you eat ΓÇö not everything is safe to consume.)"
**Verdict:** ✅ PASS — Eating works. Excellent flavor text. Note: "ΓÇö" encoding artifact (BUG-169).

### T-009: inventory (meat consumed)
**Input:** `inventory`
**Response:** "Left hand: (empty) / Right hand: (empty)"
**Verdict:** ✅ PASS — Meat removed from inventory after eating.

### T-010: health before combat
**Input:** `health` (before attacking rat)
**Response:** "You feel fine. No injuries to speak of."
**Verdict:** ✅ PASS — Baseline health confirmed.

### T-011: health after combat
**Input:** `health` (after killing rat, taking multiple "drawing blood" hits)
**Response:** "You feel fine. No injuries to speak of."
**Verdict:** ⚠️ WARN (BUG-172) — Rat attacks described as "drawing blood from the flesh" multiple times, but no injuries registered. Either combat damage isn't applying to player, or the injury threshold is too high for rat attacks. Confusing for player who reads "drawing blood" then sees "no injuries."

### T-012: health after eating
**Input:** `health` (after eating cooked rat meat)
**Response:** "You feel fine. No injuries to speak of."
**Verdict:** ⚠️ WARN (BUG-171) — Cannot verify health restoration because player had no injuries/damage. No explicit "+HP" or "You feel better" feedback. The eat action provides no mechanical feedback, only flavor text.

### T-013: eat raw (uncooked) rat
**Input:** `eat dead rat` (without cooking)
**Response:** "Fur and blood. You immediately regret this decision. You choke it down. Your stomach rebels almost immediately. Your stomach lurches. Something you ate is fighting back. (Hint: Cooking raw meat makes it safe to eat and more nourishing.)"
**Verdict:** ✅ PASS — Eating raw meat produces sickness. Cooking is mechanically meaningful (not just flavor). Good design — creates real incentive to cook.

### T-014: cook live rat
**Input:** `cook rat` (rat still alive, not in hand)
**Response:** "You'll need to pick that up first."
**Verdict:** ✅ PASS — Can't cook what you're not holding. Correct validation.

### T-015: take live rat
**Input:** `take rat` (rat alive)
**Response:** "You can't carry a brown rat."
**Verdict:** ✅ PASS — Living creatures can't be picked up. Correct design.

### T-016: look at dead rat
**Input:** `look at dead rat`
**Response:** "A dead rat lies on its side, legs splayed stiffly. Its fur is matted with blood and its beady eyes stare at nothing."
**Verdict:** ✅ PASS — Excellent corpse description. Atmospheric and detailed.

### T-017: feel dead rat
**Input:** `feel dead rat`
**Response:** "Cooling fur over a limp body. The tail hangs like wet string."
**Verdict:** ✅ PASS — Tactile description works. Great prose.

### T-018: smell dead rat
**Input:** `smell dead rat`
**Response:** "Blood and musk. The sharp copper of death."
**Verdict:** ✅ PASS — Olfactory description works. Evocative.

## Bug Details

### BUG-165: Combat text uses "someone" instead of "you" (MEDIUM)
**Reproduction:** Attack any creature. Observe combat log.
**Observed:** "A brown rat drives the enamel into someone's ribs, drawing blood from the flesh." / "Someone punches a brown rat's shin"
**Expected:** "A brown rat drives the enamel into your ribs" / "You punch a brown rat's shin"
**Impact:** Breaks immersion. Player reads as third-person spectator rather than participant.

### BUG-166: Capitalized "A" mid-sentence in combat (MEDIUM)
**Reproduction:** Attack any creature. Watch for deflection text.
**Observed:** "The keratin skitters off someone's thigh as A brown rat rakes its claws across."
**Expected:** "...as a brown rat rakes its claws across."
**Impact:** Grammatically incorrect. Appears consistently in deflection-format combat lines.

### BUG-167: Truncated combat sentences (MEDIUM)
**Reproduction:** Attack any creature. Watch for "sinks its teeth into" lines.
**Observed:** "The teeth skitters off someone's gut as A brown rat sinks its teeth into."
**Expected:** "The teeth skitter off someone's gut as a brown rat sinks its teeth into your flesh." (or similar completion)
**Impact:** Sentence ends with dangling preposition. Missing object. Appears in deflection-type messages.

### BUG-168: Subject-verb disagreement in combat (LOW)
**Reproduction:** Attack any creature.
**Observed:** "the claws fails to bite" / "the keratin claws glances off" / "the teeth fails to bite"
**Expected:** "the claws fail to bite" / "the keratin claws glance off" / "the teeth fail to bite"
**Impact:** Plural subjects with singular verbs. Repeated across all combat encounters.

### BUG-169: Unicode encoding artifact in hint (LOW)
**Reproduction:** `eat cooked rat` — observe hint text.
**Observed:** "(Hint: Careful what you eat ΓÇö not everything is safe to consume.)"
**Expected:** "(Hint: Careful what you eat — not everything is safe to consume.)"
**Impact:** Em-dash rendered as "ΓÇö". Likely UTF-8 BOM or encoding mismatch in headless output.

### BUG-170: Death announcement lowercase (LOW)
**Reproduction:** Kill any creature.
**Observed:** "a brown rat is dead!"
**Expected:** "A brown rat is dead!" (sentence-initial capitalization)
**Impact:** Minor grammar — sentence starts with lowercase letter.

### BUG-171: No health restoration feedback from eating (MEDIUM)
**Reproduction:** Take damage, then eat cooked meat, then check health.
**Observed:** Eating produces only flavor text. No "You feel better", no HP indicator, no mechanical feedback.
**Expected:** Some indication that eating restored health/satiety (e.g., "The meal restores your strength." or a health delta).
**Impact:** Player can't tell if eating cooked vs raw actually matters mechanically beyond sickness avoidance.

### BUG-172: Combat "drawing blood" hits don't register injuries (LOW)
**Reproduction:** Fight rat barehanded. Take hits described as "drawing blood from the flesh." Check `health`.
**Observed:** Multiple hits that "draw blood" and "part flesh" → `health` shows "No injuries to speak of."
**Expected:** At least minor injuries after taking blood-drawing hits, OR softer combat text for grazing blows.
**Impact:** Dissonance between combat narration and health state. May be by design (rat damage below injury threshold), but confusing to player.

## Sign-off

**Phase 3 Critical Path: ✅ VERIFIED COMPLETE.** The kill→cook→eat loop works end-to-end. All 9 steps execute correctly. The gameplay loop is mechanically sound — rat spawns, combat resolves, corpse appears, cooking transforms the item, eating consumes it. Edge cases (raw eating, live cooking, live taking) all handled correctly.

The 8 bugs found are all in combat text generation (pronouns, grammar, truncation) and health feedback — none block gameplay. Combat text quality should be addressed before beta playtesting (BUG-165–168 affect every combat encounter).

— Nelson, Tester
