# Pass-039: Regression Retest — Parser Phrase Routing + New Object Verification

**Date:** 2026-03-23
**Tester:** Nelson
**Build:** Lua src/main.lua (commit 351bfa3 + Flanders object builds)
**Requested by:** Wayne "Effe" Berry

## Executive Summary

| Category | Tests | Passed | Failed |
|----------|-------|--------|--------|
| Unit tests (full suite) | 44 files | 44 | 0 |
| Phrase routing (BUG-127–131) | 45 | 45 | 0 |
| Headless E2E — health queries (#35) | 5 | 5 | 0 |
| Headless E2E — injury queries (#36) | 2 | 2 | 0 |
| Headless E2E — self-appearance (#37) | 1 | 1 | 0 |
| Headless E2E — inventory/hands (#38) | 3 | 3 | 0 |
| Headless E2E — wait & appearance (#39) | 2 | 2 | 0 |
| Object validation — poison-bottle.lua | 23 | 23 | 0 |
| Object validation — bear-trap.lua | 22 | 22 | 0 |
| Object validation — crushing-wound.lua | 24 | 24 | 0 |
| **TOTALS** | **171** | **171** | **0** |

**Result: ✅ ALL PASS — 0 bugs found. All #35–#39 fixes verified. All new objects well-formed.**

## Bug List

No new bugs found in this pass.

---

## Part 1: Parser Phrase Routing Regression (#35–#39)

### 1A. Unit Test Suite (Baseline)

All 44 test files pass (full `lua test/run-tests.lua`). No regressions introduced.

### 1B. Phrase Routing Unit Tests (`test-pass038-phrase-routing.lua`)

All 45 tests pass. Breakdown by issue:

#### #35 — Health Status Queries (BUG-127) — 12 tests ✅

| # | Phrase | Routes to | Verdict |
|---|--------|-----------|---------|
| T-001 | `status` | health | ✅ PASS |
| T-002 | `how am I` | health | ✅ PASS |
| T-003 | `how am I doing` | health | ✅ PASS |
| T-004 | `am I hurt?` | health | ✅ PASS |
| T-005 | `am I injured?` | health | ✅ PASS |
| T-006 | `what's wrong with me?` | health | ✅ PASS |
| T-007 | `what is wrong with me` | health | ✅ PASS |
| T-008 | `check my wounds` | health | ✅ PASS |
| T-009 | `check my injuries` | health | ✅ PASS |
| T-010 | `check my health` | health | ✅ PASS |
| T-011 | `am I ok?` | health | ✅ PASS |
| T-012 | `am I alright?` | health | ✅ PASS |

#### #36 — Injury Location / Severity (BUG-128) — 8 tests ✅

| # | Phrase | Routes to | Verdict |
|---|--------|-----------|---------|
| T-013 | `Where am I bleeding from?` | injuries | ✅ PASS |
| T-014 | `where am I bleeding` | injuries | ✅ PASS |
| T-015 | `How bad is it?` | injuries | ✅ PASS |
| T-016 | `why don't I feel well?` | injuries | ✅ PASS |
| T-017 | `why dont I feel well` | injuries | ✅ PASS |
| T-018 | `how bad are my injuries` | injuries | ✅ PASS |
| T-019 | `where am I` (regression) | look | ✅ PASS |
| T-020 | `where am I?` (regression) | look | ✅ PASS |

#### #37 — Self-Appearance (BUG-129) — 10 tests ✅

| # | Phrase | Routes to | Verdict |
|---|--------|-----------|---------|
| T-021 | `look at myself` | appearance | ✅ PASS |
| T-022 | `look at self` | appearance | ✅ PASS |
| T-023 | `look at me` | appearance | ✅ PASS |
| T-024 | `examine myself` | appearance | ✅ PASS |
| T-025 | `examine self` | appearance | ✅ PASS |
| T-026 | `examine me` | appearance | ✅ PASS |
| T-027 | `check myself` | appearance | ✅ PASS |
| T-028 | `check self` | appearance | ✅ PASS |
| T-029 | `look at nightstand` (regression) | examine | ✅ PASS |
| T-030 | `examine nightstand` (regression) | examine | ✅ PASS |

#### #38 — Inventory / Hands (BUG-130) — 8 tests ✅

| # | Phrase | Routes to | Verdict |
|---|--------|-----------|---------|
| T-031 | `what's in my hands?` | inventory | ✅ PASS |
| T-032 | `what is in my hands` | inventory | ✅ PASS |
| T-033 | `am I holding anything?` | inventory | ✅ PASS |
| T-034 | `am I holding something?` | inventory | ✅ PASS |
| T-035 | `look at my hands` | inventory | ✅ PASS |
| T-036 | `what am I carrying?` (regression) | inventory | ✅ PASS |
| T-037 | `what am I holding?` (regression) | inventory | ✅ PASS |
| T-038 | `what do I have?` (regression) | inventory | ✅ PASS |

#### #39 — Wait & Appearance Verbs (BUG-131) — 2 tests ✅

| # | Phrase | Routes to | Verdict |
|---|--------|-----------|---------|
| T-039 | `wait` | wait | ✅ PASS |
| T-040 | `appearance` | appearance | ✅ PASS |

#### Existing Behaviour Regressions — 5 tests ✅

| # | Phrase | Routes to | Verdict |
|---|--------|-----------|---------|
| T-041 | `health` | health | ✅ PASS |
| T-042 | `injuries` | injuries | ✅ PASS |
| T-043 | `inventory` | inventory | ✅ PASS |
| T-044 | `what's in the wardrobe` | examine | ✅ PASS |
| T-045 | `check the nightstand` | examine | ✅ PASS |

### 1C. Headless End-to-End Verification

All phrases tested through `lua src/main.lua --headless` to confirm full engine response:

| # | Input | Game Response | Verdict |
|---|-------|--------------|---------|
| T-046 | `status` | "You feel fine. No injuries to speak of." | ✅ PASS |
| T-047 | `how am I` | "You feel fine. No injuries to speak of." | ✅ PASS |
| T-048 | `am I hurt?` | "You feel fine. No injuries to speak of." | ✅ PASS |
| T-049 | `what's wrong with me?` | "You feel fine. No injuries to speak of." | ✅ PASS |
| T-050 | `check my wounds` | "You feel fine. No injuries to speak of." | ✅ PASS |
| T-051 | `where am I bleeding from?` | "You feel fine. No injuries to speak of." | ✅ PASS |
| T-052 | `how bad is it?` | "You feel fine. No injuries to speak of." | ✅ PASS |
| T-053 | `look at myself` | "Your reflection shows an unremarkable figure in plain clothes, unharmed and..." | ✅ PASS |
| T-054 | `what's in my hands?` | "Left hand: (empty) / Right hand: (empty)" | ✅ PASS |
| T-055 | `what am I carrying?` | "Left hand: (empty) / Right hand: (empty)" | ✅ PASS |
| T-056 | `inventory` | "Left hand: (empty) / Right hand: (empty)" | ✅ PASS |
| T-057 | `wait` | "Time passes." | ✅ PASS |
| T-058 | `appearance` | "Your reflection shows an unremarkable figure in plain clothes, unharmed and..." | ✅ PASS |

---

## Part 2: New Object Verification

### 2A. poison-bottle.lua — 23/23 checks ✅

| # | Check | Result |
|---|-------|--------|
| T-059 | Has GUID | ✅ PASS |
| T-060 | ID = "poison-bottle" | ✅ PASS |
| T-061 | Material = glass | ✅ PASS |
| T-062 | Has keywords (9 entries) | ✅ PASS |
| T-063 | Has categories (8 entries) | ✅ PASS |
| T-064 | initial_state = "sealed" | ✅ PASS |
| T-065 | FSM states table exists | ✅ PASS |
| T-066 | Has sealed state | ✅ PASS |
| T-067 | Has open state | ✅ PASS |
| T-068 | Has empty state | ✅ PASS |
| T-069 | Empty state is terminal | ✅ PASS |
| T-070 | Has transitions | ✅ PASS |
| T-071 | Has on_feel sensory | ✅ PASS |
| T-072 | Has on_smell sensory | ✅ PASS |
| T-073 | Has on_listen sensory | ✅ PASS |
| T-074 | is_consumable = true | ✅ PASS |
| T-075 | poison_type = "nightshade" | ✅ PASS |
| T-076 | Drink transition inflicts poisoned-nightshade injury | ✅ PASS |
| T-077 | Has composite parts table | ✅ PASS |
| T-078 | Cork part exists | ✅ PASS |
| T-079 | Label part exists | ✅ PASS |
| T-080 | Cork is detachable | ✅ PASS |
| T-081 | Label has readable_text | ✅ PASS |

**Notes:** Excellent object. Full FSM lifecycle (sealed→open→empty), consumption pipeline with injury effect, composite parts system (detachable cork + readable label), complete sensory properties across all states. The cork factory function creates independent objects on detach. Label reveals poison identity via `read` verb.

### 2B. bear-trap.lua — 22/22 checks ✅

| # | Check | Result |
|---|-------|--------|
| T-082 | Has GUID | ✅ PASS |
| T-083 | ID = "bear-trap" | ✅ PASS |
| T-084 | Material = iron | ✅ PASS |
| T-085 | Has keywords (7 entries) | ✅ PASS |
| T-086 | Has categories (5 entries) | ✅ PASS |
| T-087 | is_trap flag set | ✅ PASS |
| T-088 | is_armed flag set | ✅ PASS |
| T-089 | initial_state = "set" | ✅ PASS |
| T-090 | FSM states table exists | ✅ PASS |
| T-091 | Has "set" (armed) state | ✅ PASS |
| T-092 | Has "triggered" (snapped) state | ✅ PASS |
| T-093 | Has "disarmed" (safe) state | ✅ PASS |
| T-094 | Has transitions | ✅ PASS |
| T-095 | Has on_feel sensory | ✅ PASS |
| T-096 | Has on_smell sensory | ✅ PASS |
| T-097 | Has on_listen sensory | ✅ PASS |
| T-098 | Set state has on_feel_effect (contact injury) | ✅ PASS |
| T-099 | on_feel_effect inflicts crushing-wound | ✅ PASS |
| T-100 | Take transition from "set" has injury effect | ✅ PASS |
| T-101 | Touch transition from "set" has injury effect | ✅ PASS |
| T-102 | Disarmed state allows portable | ✅ PASS |
| T-103 | Disarmed state not dangerous | ✅ PASS |

**Notes:** Well-designed trap object. Contact injury pipeline works on both `take` and `touch` verbs when armed. Disarm requires tool + lockpicking skill (good skill-gating). Triggered state allows safe pickup. Full sensory descriptions across all states. The "observe first" teaching pattern is solid — players who `look` before grabbing are rewarded.

### 2C. crushing-wound.lua — 24/24 checks ✅

| # | Check | Result |
|---|-------|--------|
| T-104 | Has GUID | ✅ PASS |
| T-105 | ID = "crushing-wound" | ✅ PASS |
| T-106 | Name = "Crushing Wound" | ✅ PASS |
| T-107 | damage_type = "over_time" | ✅ PASS |
| T-108 | Has on_inflict block | ✅ PASS |
| T-109 | Initial damage = 15 | ✅ PASS |
| T-110 | Tick damage = 2 | ✅ PASS |
| T-111 | FSM states table exists | ✅ PASS |
| T-112 | Has "active" state | ✅ PASS |
| T-113 | Active state damage_per_tick = 2 | ✅ PASS |
| T-114 | Active state has restricts (grip/climb/fight) | ✅ PASS |
| T-115 | Has "treated" state | ✅ PASS |
| T-116 | Treated stops bleeding (dpt = 0) | ✅ PASS |
| T-117 | Has "worsened" state | ✅ PASS |
| T-118 | Worsened increases damage (dpt = 5) | ✅ PASS |
| T-119 | Has "critical" state | ✅ PASS |
| T-120 | Critical high damage (dpt = 12) | ✅ PASS |
| T-121 | Has "fatal" state | ✅ PASS |
| T-122 | Fatal is terminal | ✅ PASS |
| T-123 | Has "healed" state | ✅ PASS |
| T-124 | Healed is terminal | ✅ PASS |
| T-125 | Has transitions | ✅ PASS |
| T-126 | Has healing_interactions | ✅ PASS |
| T-127 | Bandage heals (in healing_interactions) | ✅ PASS |

**Notes:** Full injury lifecycle with degradation path (active→worsened→critical→fatal) and treatment path (active→treated→healed). Tick damage escalation is well-calibrated: 2→5→12→death. Timed auto-transitions create urgency. Both bandage and healing-poultice are supported. Restricts table properly limits player actions. Bleeding component confirmed via damage_per_tick in active state.

---

## Observations

1. **World loader warnings** — ~40 "base class not found" warnings appear during headless startup. These are pre-existing (rooms referencing objects whose templates haven't been registered yet). Not a regression — noted for tracking.

2. **All 5 parser issues (#35–#39) are confirmed fixed.** The natural phrase transforms route correctly at both the parser unit level and the full game engine level.

3. **All 3 new object files are well-formed and follow project conventions.** Each has proper FSM states, transitions, sensory properties, and effect pipelines.

---

**Sign-off:** Pass-039 complete. 171 tests, 171 passed, 0 failed, 0 bugs. ✅

— Nelson, Tester
