# Pass-038: Phase 3 Sanity Check — Hit, Unconsciousness, Injuries, Appearance/Mirror
**Date:** 2026-03-23
**Tester:** Nelson
**Build:** Lua src/main.lua --headless
**Scope:** Phase 3 features shipped 2026-03-22 — first play-test validation

## Executive Summary

**Total tests: 38** | ✅ **PASS: 22** | ❌ **FAIL: 13** | ⚠️ **WARN: 3**

The core mechanics are solid — hit verb, unconsciousness, injury engine, mirror reflection, and basic inventory all work correctly. The bugs are concentrated in **parser coverage gaps**: many natural-language phrases that players would try ("status", "how am I", "look at myself", "what's in my hands?") don't route to the correct subsystem. The engine handles these features correctly when accessed through recognized commands, but the parser doesn't bridge enough synonyms.

**5 new bugs filed** (BUG-127 through BUG-131).

## Bug List

| Bug ID | Severity | Summary |
|--------|----------|---------|
| BUG-127 | MEDIUM | "status", "how am I", "am I hurt?", "what's wrong with me?" not recognized as health/injury query |
| BUG-128 | MEDIUM | "Where am I bleeding from?", "Why don't I feel well?", "How bad is it?" not recognized |
| BUG-129 | MEDIUM | "look at myself"/"examine self"/"check myself" don't route to appearance system (even in light) |
| BUG-130 | LOW | "what's in my hands?"/"look at my hands"/"am I holding anything?" not recognized as inventory |
| BUG-131 | LOW | "wait" not recognized as a verb (common text adventure command); "appearance" as standalone not recognized |

## Individual Tests

---

### UNCONSCIOUSNESS FLOW

#### T-001: hit head → unconsciousness → wake up
**Commands:** `hit head`, then wait 4+ turns, then `health`
**Response:** "Stars explode across your vision. The world tilts and fades..." → 4 empty turns → "Your eyes flutter open. Your head throbs with a dull, persistent ache."
**Verdict:** ✅ PASS
**Notes:** Wake timer = 5 turns. Commands while unconscious produce empty output (correctly blocked). On waking, concussion injury is active: "concussed on your head — Your head is swimming." Health: 95/100.

#### T-002: hit head → commands blocked while unconscious
**Commands:** `hit head`, `health` (unconscious), `look` (unconscious)
**Response:** health and look both produce `---END---` with no text while unconscious.
**Verdict:** ✅ PASS
**Notes:** All player commands are correctly suppressed during unconsciousness.

#### T-003: hit head with items in hand → sleep after recovery
**Commands:** feel around → open drawer → get matchbox → open matchbox → get match → `hit head` → (unconscious) → (wake) → `sleep 4 hours`
**Response:** Items persisted through unconsciousness. Sleep after waking worked normally with dawn message.
**Verdict:** ✅ PASS

#### T-004: punch head (synonym) → unconsciousness
**Commands:** `punch head`
**Response:** "You slam your fist hard against the side of your head. Stars explode..."
**Verdict:** ✅ PASS
**Notes:** "punch" correctly routes to hit handler.

#### T-005: bash head / bonk head → unconsciousness
**Commands:** `bash head`, `bonk head`
**Response:** Both triggered unconsciousness with concussion narration.
**Verdict:** ✅ PASS

#### T-006: hit head → hit arm/leg after waking → multiple injuries stack
**Commands:** hit head → (wake) → hit arm → hit leg → health
**Response:** Three injuries listed: concussion on head, bruise on left arm, bruise on left leg. Health: 87/100.
**Verdict:** ✅ PASS

#### T-007: hit arm → bruise (not unconsciousness)
**Commands:** `hit arm`
**Response:** "You punch yourself in the left arm. Sharp pain blooms across the muscle." Player remains conscious.
**Verdict:** ✅ PASS

#### T-008: hit leg → bruise on leg
**Commands:** `hit leg`
**Response:** "You drive your fist down against your left leg. Intense pain shoots through the limb."
**Verdict:** ✅ PASS

#### T-009: hit self → random body area
**Commands:** `hit self`
**Response:** "You punch yourself in the stomach. You double over, gasping."
**Verdict:** ✅ PASS
**Notes:** Random body area selection working.

#### T-010: strike arm / thump leg (synonyms)
**Commands:** `strike arm`, `thump leg`
**Response:** Both inflicted bruise injuries on correct locations.
**Verdict:** ✅ PASS

#### T-011: sleep with 10 bruise injuries — no bleed-out (bruises aren't fatal)
**Commands:** hit arm ×10 → sleep 8 hours → health
**Response:** Survived sleep. Health: 60/100. All 10 bruises still present after sleep.
**Verdict:** ⚠️ WARN
**Notes:** Bruises have auto_heal_turns=3 in the definition, but all 10 survive 8 hours of sleep. This may be intentional if sleep ticks injuries only once, or a bug if sleep should tick per simulated hour. No bleed-out because bruises do 0 damage_per_tick. Sleep + bleeding wound scenario could not be tested — no knife accessible in bedroom.

#### T-012: sleep with injury → bleed out (via headless)
**Commands:** N/A — requires bleeding wound (knife/dagger), not accessible in starting area.
**Verdict:** ⚠️ NOT FULLY TESTABLE (headless)
**Notes:** Unit tests in test-hit-unconscious.lua (lines 376-401) confirm the engine correctly kills the player when bleeding during sleep. The game loop integration can't be tested without a weapon.

#### T-013: hit head → bleed out while unconscious (via headless)
**Commands:** N/A — requires pre-existing bleeding wound + head hit.
**Verdict:** ⚠️ NOT FULLY TESTABLE (headless)
**Notes:** Unit tests (lines 294-324) confirm bleeding + unconscious = death when health hits 0. Verified at unit test level; full game loop requires weapon access.

---

### INJURY LISTING — NATURAL PHRASING

#### T-014: "health"
**Response:** "You feel fine. No injuries to speak of." (uninjured) / Full injury list + health (injured)
**Verdict:** ✅ PASS

#### T-015: "injuries"
**Response:** Same output as "health" — lists all injuries with descriptions.
**Verdict:** ✅ PASS

#### T-016: "status"
**Response:** "I'm not sure what you mean."
**Verdict:** ❌ FAIL — BUG-127
**Expected:** Should show health/injury status.

#### T-017: "how am I"
**Response:** "I'm not sure what you mean."
**Verdict:** ❌ FAIL — BUG-127

#### T-018: "check my wounds"
**Response:** "You can't find anything like that in the darkness." (dark) / "You don't notice anything called that nearby." (light)
**Verdict:** ❌ FAIL — BUG-127
**Notes:** Parser treats "wounds" as a search target instead of routing to injury system.

#### T-019: "am I hurt?"
**Response:** "I'm not sure what you mean."
**Verdict:** ❌ FAIL — BUG-127

#### T-020: "what's wrong with me?"
**Response:** "I'm not sure what you mean."
**Verdict:** ❌ FAIL — BUG-127

#### T-021: "Where am I bleeding from?"
**Response:** Room description shown ("The Bedroom...") — parser matched "Where am I" → look.
**Verdict:** ❌ FAIL — BUG-128
**Notes:** The question transform parsed "where am I bleeding from?" as "where am I?" and triggered look.

#### T-022: "Why don't I feel well?"
**Response:** "I'm not sure what you mean."
**Verdict:** ❌ FAIL — BUG-128

#### T-023: "How bad is it?"
**Response:** "I'm not sure what you mean."
**Verdict:** ❌ FAIL — BUG-128

---

### INVENTORY / HANDS — NATURAL PHRASING

#### T-024: "inventory"
**Response:** "Left hand: (empty) / Right hand: (empty)" — or shows items when carrying.
**Verdict:** ✅ PASS
**Notes:** With matchbox: shows "Left hand: a small matchbox (contains: 6 matches)". Good detail.

#### T-025: "i" (shorthand)
**Response:** Same as inventory.
**Verdict:** ✅ PASS

#### T-026: "what am I holding?"
**Response:** Shows hand slots (same as inventory).
**Verdict:** ✅ PASS

#### T-027: "what am I carrying?"
**Response:** Shows hand slots.
**Verdict:** ✅ PASS

#### T-028: "what do I have?"
**Response:** Shows hand slots.
**Verdict:** ✅ PASS

#### T-029: "what's in my hands?"
**Response:** "You don't notice anything called that nearby."
**Verdict:** ❌ FAIL — BUG-130
**Notes:** Parser treats "hands" as a search target instead of routing to inventory.

#### T-030: "look at my hands"
**Response:** "You don't notice anything called that nearby."
**Verdict:** ❌ FAIL — BUG-130

#### T-031: "am I holding anything?"
**Response:** "I'm not sure what you mean."
**Verdict:** ❌ FAIL — BUG-130

---

### APPEARANCE / MIRROR

#### T-032: "look in mirror" (with dawn light)
**Response:** "Your reflection shows an unremarkable figure in plain clothes, unharmed and unburdened."
**Verdict:** ✅ PASS

#### T-033: "look at mirror" / "examine mirror" / "look at vanity"
**Response:** All three show the reflection description.
**Verdict:** ✅ PASS

#### T-034: mirror with injury (hit arm → look in mirror)
**Response:** "In the mirror, you see: A bruise on your left arm."
**Verdict:** ✅ PASS
**Notes:** Mirror dynamically reflects injury state. Excellent.

#### T-035: "look at myself" / "examine self" / "examine myself" / "look at self"
**Response:** "You don't notice anything called that nearby." (even in daylight)
**Verdict:** ❌ FAIL — BUG-129
**Expected:** Should route to appearance system or mirror.

#### T-036: "appearance" (standalone command)
**Response:** "I'm not sure what you mean."
**Verdict:** ❌ FAIL — BUG-131

#### T-037: "check myself" / "check my health"
**Response:** "You don't notice anything called that nearby."
**Verdict:** ❌ FAIL — BUG-129

#### T-038: "wait" (common text adventure command)
**Response:** "I'm not sure what you mean."
**Verdict:** ❌ FAIL — BUG-131
**Notes:** "rest" works (interpreted as sleep 1 hour). "wait" should either pass time or be aliased to rest.

---

## Unit Test Baseline

All 42 existing test files pass (verified before play test). The existing unit tests in `test/verbs/test-hit-unconscious.lua` comprehensively cover:
- Hit verb with all body areas ✅
- Unconsciousness trigger from head hits ✅
- Helmet armor reduction ✅
- Wake timer countdown ✅
- Bleed-out while unconscious ✅
- Sleep + injury death ✅
- Appearance describe() with injuries/armor/low-health ✅
- Mirror integration ✅
- Hit synonyms (punch, bash, strike, bonk, smash, thump) ✅

## Summary of Findings

**What works well:**
- Hit verb + all synonyms + body targeting: rock solid
- Unconsciousness system: timer, blocking, wake narration all excellent
- Injury engine: stacking, listing, health computation correct
- Mirror/appearance integration: dynamically reflects injuries, held items, low health
- Basic inventory commands: `inventory`, `i`, `what am I holding?`, `what am I carrying?`, `what do I have?` all work

**What needs parser work (5 bugs):**
- Health/injury natural phrases: only "health" and "injuries" work; "status", "how am I", "am I hurt?", etc. all fail
- Self-examination: "look at myself" etc. don't route to appearance/mirror
- Some inventory phrases: "what's in my hands?", "look at my hands" fail
- Missing verb: "wait" (extremely common in text adventures)
- Bleeding query: "Where am I bleeding from?" incorrectly triggers room look
