# Prime Directive Roadmap: Parser Evolution to Natural Language Excellence

**Status:** 🎯 Active Roadmap  
**Version:** 1.0  
**Author:** Bart (Architect)  
**Date:** 2025-03-25  
**Purpose:** North Star for achieving A-grade Prime Directive alignment (95%+)

---

## Executive Summary

**Current State:** C+ / 65% Prime Directive alignment  
**Target State:** A / 95% alignment  
**Philosophy:** The game should feel like talking to an AI — but cost nothing to run.

This roadmap charts our path from "better than classic IF" to "feels like Copilot." The foundation is solid: GOAP prerequisite resolution, natural language preprocessing, and compound command chaining are genuine innovations. But gaps remain — mechanical error messages, missing politeness handling, question-form failures, and limited context memory create friction that breaks the conversational illusion.

This document defines what "feels like Copilot" means concretely, prioritizes improvements by impact/effort ratio, and establishes metrics to track progress.

**Reference:** See [Prime Directive Architecture Review](../../../../.squad/decisions/inbox/bart-prime-directive-review.md) for detailed gap analysis.

---

## 1. Current State (C+ / 65%)

### Strengths: What Feels Like Copilot ✨

**GOAP Prerequisite Resolution** — Our strongest Prime Directive feature. When a player types `light the candle`, the system:
1. Detects missing fire source
2. Plans backwards: find match → open containers → take match → strike → light
3. Executes 5-step chain automatically
4. Narrates each step naturally

No classic IF engine does this. This is zero-cost inference at human conversation level.

**Natural Language Preprocessing** — Handles conversational preambles gracefully:
- `I want to take the match` → `take match` ✅
- `I need to light the candle` → `light candle` ✅
- `I'd like to open the drawer` → `open drawer` ✅

**Compound Commands** — Chains work naturally:
- `take match, strike it, light candle` → 3 sequential actions ✅
- `examine matchbox then open it` → with pronoun resolution ✅

**Pronoun Resolution** — Context chaining between commands:
- `examine matchbox` → `open it` resolves to matchbox ✅
- `look at candle` → `light that` resolves to candle ✅

**Sensory Fallback** — In darkness, helpful guidance:
- `"It is too dark to see... (Try 'feel' to grope around.)"` ✅

### Gaps: What Feels Like Zork 💥

**Catastrophic Failures** (inputs that should work but don't):

| Player Types | What Happens | Impact |
|---|---|---|
| `please open the drawer` | "please" becomes verb → no handler | ❌ HIGH |
| `can I look under the bed?` | "can" becomes verb → no handler | ❌ HIGH |
| `carefully examine the nightstand` | "carefully" becomes verb → fails | ❌ HIGH |
| `look at the bed more closely` | noun = "bed more closely" → fails keyword match | ❌ HIGH |
| `what's this?` | No natural language pattern → fails | ❌ MEDIUM |
| `is the door locked?` | "is" becomes verb → no handler | ❌ MEDIUM |
| `set fire to the candle` | No idiom mapping → fails | ❌ MEDIUM |
| `examine everything` | "everything" not supported → fails | ❌ MEDIUM |

**The Politeness Problem** — Players trained on conversational AI will type politely. None of these work:
- `please look around`
- `could you open the drawer?`
- `can I take the match?`
- `let me examine the bed`
- `maybe I should look in the drawer`

**The Adverb Problem** — Natural English uses adverbs constantly. Our preprocessor strips articles but never strips adverbs:
- `carefully examine the nightstand` → "carefully" poisoned as verb
- `look more closely at the bed` → "more closely" poisons noun
- `quickly take the match` → "quickly" becomes verb

**Mechanical Error Messages** — Most failures produce Zork-style punishment:
- `"You don't see that here."` — No help, no suggestion (Grade: D)
- `"You can't light that."` — Doesn't explain fire source needed (Grade: D)
- `"I don't understand that."` — Worst possible response (Grade: F)

**Search Narrator Never Rotates** — Progressive search is brilliant architecture, but narrator always picks `templates[1]`. Every search step sounds identical: `"Your eyes scan the X — nothing notable."` Mechanical repetition breaks immersion.

**GOAP Coverage Narrow** — Planner only handles `fire_source` capability. The generalized planner from architecture docs (unlock with key, wear armor after finding, cut with sharp tool) isn't implemented. This limits "magic moments" to candle-lighting.

**Context Window Missing** — No discovery memory. Examining the matchbox doesn't teach GOAP where matches are. "Light the candle" can't infer tool location from recent discovery. This gap prevents Copilot-style inference.

---

## 2. Target State (A / 95%)

### Definition: What "Feels Like Copilot" Means

**Test Case 1: Any Reasonable English Works**
- Player types natural phrasing → game responds meaningfully
- Politeness is invisible (stripped, not punished)
- Questions map to commands: `"can I open the drawer?"` → `open drawer`
- Adverbs are ignored: `"carefully examine X"` → `examine X`
- Multiple phrasings reach same action: `"set fire to X" = "light X" = "ignite X"`

**Test Case 2: Error Messages Guide, Never Punish**
- Every failure includes helpful suggestion
- Context-aware: if player tried object name, suggest what they CAN do with it
- Replace `"I don't understand"` with verb suggestions and example commands
- Replace `"You don't see that here"` with close matches or sensory fallback
- Replace `"You can't light that"` with prerequisite hints

**Test Case 3: No Magic Words**
- `"go to bed" = "sleep on bed" = "lie in bed" = "rest"`
- `"what's this?" = "examine this" = "look at this" = "what is that?"`
- `"is X locked?" = "examine X"` (sensible inference)
- `"set fire to X" = "light X" = "ignite X" = "kindle X"`

**Test Case 4: Questions Work as Commands**
- `"what's in the drawer?"` → `examine drawer` or `search drawer`
- `"where is the key?"` → `find key`
- `"can I take the match?"` → `take match`
- `"do I have a torch?"` → `inventory`

**Test Case 5: Discovery Feeds Context**
- After `examine matchbox`, GOAP knows matches are there
- `"light the candle"` auto-resolves match location from recent discovery
- `"use it"` resolves to most recently discovered relevant object
- `"go back"` resolves to previous room

---

## 3. Improvement Tiers (Ordered by Impact/Effort)

### Tier 0: Stripping Layer (Immediate, 2-3 hours)

**Impact:** HIGH | **Effort:** LOW | **Risk:** ZERO  
**File:** `src/engine/parser/preprocess.lua`

Add comprehensive stripping patterns to `natural_language()` function. This is purely additive — zero risk to existing behavior.

**Politeness Words:**
```lua
"please %s+(.+)" → recurse
"kindly %s+(.+)" → recurse
"could you %s+(.+)" → recurse
"can you %s+(.+)" → recurse
"would you %s+(.+)" → recurse
"will you %s+(.+)" → recurse
```

**Question Forms (Commands in Disguise):**
```lua
"can I %s+(.+)" → recurse (strip question marker)
"may I %s+(.+)" → recurse
"should I %s+(.+)" → recurse
"is it possible to %s+(.+)" → recurse
```

**Preambles (Thinking Aloud):**
```lua
"let me %s+(.+)" → recurse
"I think I'll %s+(.+)" → recurse
"maybe %s+(.+)" → recurse
"perhaps %s+(.+)" → recurse
"I wonder if I can %s+(.+)" → recurse
```

**Hedging (Uncertainty Language):**
```lua
"try to %s+(.+)" → recurse
"try %s+(.+)" → recurse
"attempt to %s+(.+)" → recurse
```

**Trailing Adverbs (Strip from Noun):**
```lua
-- Function: strip_adverbs(noun_phrase)
-- Strips: carefully, quickly, gently, slowly, quietly, closely, thoroughly
-- Example: "bed more closely" → "bed"
```

**Test Cases:**
- `please open the drawer` → `open drawer` ✅
- `can I take the match?` → `take match` ✅
- `let me examine the bed` → `examine bed` ✅
- `try to light the candle` → `light candle` ✅
- `look at the bed carefully` → `look at bed` ✅

**Metrics:**
- Parser failure rate should drop by 15-20% immediately
- 10+ phrases from "20 Phrases That Should Work" list will pass

---

### Tier 1: Question Transform (Short-term, 1-2 hours)

**Impact:** MEDIUM | **Effort:** LOW | **Risk:** LOW  
**File:** `src/engine/parser/preprocess.lua`

Map question forms to command verbs. Add patterns AFTER politeness stripping but BEFORE verb lookup.

**Information Questions → Examination:**
```lua
"what'?s in the (.+)" → "examine", target
"what'?s inside the (.+)" → "look in", target
"is there anything in (.+)" → "search", target
"what does the (.+) say" → "read", target
"what'?s this" → "examine", last_noun
"what is that" → "examine", last_noun
```

**Possibility Questions → Commands:**
```lua
"is the (.+) locked" → "examine", target
"is the (.+) open" → "examine", target
"can the (.+) be opened" → "examine", target
```

**Location Questions → Search:**
```lua
"where is the (.+)" → "find", target
"where did I put the (.+)" → "find", target
"any (.+) around here" → "search for", target
```

**Possession Questions → Inventory:**
```lua
"do I have (.+)" → "inventory", ""
"am I carrying (.+)" → "inventory", ""
"what am I holding" → "inventory", ""
```

**Test Cases:**
- `what's in the drawer?` → `examine drawer` ✅
- `is the door locked?` → `examine door` ✅
- `where is the key?` → `find key` ✅
- `do I have a match?` → `inventory` ✅

---

### Tier 2: Error Message Overhaul (Short-term, 2-3 hours)

**Impact:** HIGH | **Effort:** MEDIUM | **Risk:** LOW  
**File:** `src/engine/verbs/init.lua` (throughout handlers)

Replace every mechanical error with contextual guidance. Every failure becomes a teaching moment.

**Priority Replacements:**

**"I don't understand that."** → Most harmful message in the game
```lua
-- BEFORE:
"I don't understand that."

-- AFTER:
"Hmm, I'm not sure what you mean by '" .. input .. "'. Try phrasing it as a verb + object, like 'open drawer' or 'take match'. Type 'help' for a full command list."

-- With fuzzy matching:
"I don't recognize '" .. verb .. "'. Did you mean '" .. closest_verb .. "'? Type 'help' for all commands."
```

**"You don't see that here."** → Second most frustrating
```lua
-- BEFORE:
"You don't see that here."

-- AFTER (with close match):
"You don't see '" .. noun .. "' nearby. Did you mean '" .. closest_match .. "'? Type 'look' to see what's around you."

-- AFTER (in darkness):
"You can't see in the dark. Try 'feel " .. noun .. "' to explore by touch."

-- AFTER (no close match):
"You don't see anything called '" .. noun .. "' nearby. Try 'look' to see what's in the room."
```

**"You can't light that."** → Missing prerequisite hint
```lua
-- BEFORE:
"You can't light that."

-- AFTER (not flammable):
"The " .. obj.name .. " doesn't seem flammable."

-- AFTER (missing tool):
"You'll need a fire source to light the " .. obj.name .. ". Maybe a match or torch?"
```

**"You can't carry that."** → Why not?
```lua
-- BEFORE:
"You can't carry that."

-- AFTER (too heavy):
"The " .. obj.name .. " is too heavy to lift. Maybe there's a way to move it instead?"

-- AFTER (fixed):
"The " .. obj.name .. " is fixed in place. You can't take it."

-- AFTER (immovable):
"The " .. obj.name .. " won't budge. Perhaps you could interact with it some other way?"
```

**Hands Full:**
```lua
-- BEFORE: "Your hands are full. Drop something first."
-- This one is actually GOOD — keep it!
```

**Test Pattern:** Every error message must:
1. Acknowledge what the player tried
2. Explain why it didn't work (when reasonable)
3. Suggest an alternative action OR point to help

---

### Tier 3: Idiom Library (Medium-term, 1-2 hours)

**Impact:** MEDIUM | **Effort:** LOW | **Risk:** ZERO  
**File:** `src/engine/parser/preprocess.lua` → new `idiom_mappings` table

Build extensible phrase-to-canonical-form mappings. Expandable without code changes.

**Fire/Light Idioms:**
```lua
"set fire to (.+)" → "light", target
"set (.+) on fire" → "light", target
"ignite (.+)" → "light", target
"kindle (.+)" → "light", target
"burn (.+)" → "light", target
```

**Tool Use Idioms:**
```lua
"put (.+) to (.+)" → "use", tool .. " on " .. target
"put (.+) on (.+)" → "use", tool .. " on " .. target (context-dependent)
"use (.+) with (.+)" → "use", tool .. " on " .. target
"apply (.+) to (.+)" → "use", tool .. " on " .. target
```

**Movement Idioms:**
```lua
"go to sleep" → "sleep", ""
"lie down" → "sleep", ""
"have a rest" → "sleep", ""
"take a nap" → "sleep", ""
```

**Search Idioms:**
```lua
"rummage through (.+)" → "search", target
"rifle through (.+)" → "search", target
"dig through (.+)" → "search", target
"look everywhere" → "search", "room"
```

**Examination Idioms:**
```lua
"take a closer look at (.+)" → "examine", target
"take a look at (.+)" → "examine", target
"inspect (.+)" → "examine", target
"study (.+)" → "examine", target
"check out (.+)" → "examine", target
```

**Meta Idioms:**
```lua
"check my pockets" → "inventory", ""
"what am I carrying" → "inventory", ""
"give me a hint" → "help", ""
```

---

### Tier 4: Context Window (Medium-term, 4-6 hours)

**Impact:** HIGH | **Effort:** MEDIUM | **Risk:** MEDIUM  
**Files:** `src/engine/parser/context.lua` (extend), GOAP planner

Implement discovery memory and confidence scoring. This closes the gap between "parser understands words" and "parser understands intent."

**Core Concept:** Objects the player has examined/discovered become part of context. GOAP queries this context when planning tool resolution.

**Data Structure:**
```lua
context.discovered_objects = {
    ["matchbox-nightstand"] = {
        object_id = "matchbox-nightstand",
        discovered_at = tick_count,
        location = "nightstand-top",
        contains = { "match" },  -- learned from examination
        confidence = 1.0,  -- decays over time
    }
}
```

**Discovery Tracking:**
- `examine matchbox` → records in `discovered_objects` with contents
- `search drawer` → records all found objects
- `open X` → records interior contents

**GOAP Integration:**
- When `plan_for_tool("fire_source")` runs, check `discovered_objects` for containers with matches
- Use confidence scoring: recent discoveries > older ones
- Prefer examined/opened containers over unsearched ones

**Pronoun Enhancement:**
- `"use it"` resolves to most recently discovered relevant object (not just last_object)
- `"open that"` prefers objects the player has examined over arbitrary room objects

**Confidence Decay:**
```lua
confidence = 1.0 / (1 + (current_tick - discovered_at) / decay_rate)
-- Objects 50 ticks ago have lower confidence than objects 1 tick ago
```

**Test Cases:**
- `examine matchbox` → `light candle` auto-uses matchbox ✅
- `search drawer` → `take needle` uses discovered needle ✅
- `look at painting` → `take it` resolves to painting ✅

**Note:** This is Tier 4 from parser architecture docs. Implementation deferred until Tier 0-3 complete.

---

### Tier 5: Fuzzy Noun Resolution (Longer-term, 6-8 hours)

**Impact:** MEDIUM | **Effort:** HIGH | **Risk:** MEDIUM  
**Files:** New `src/engine/parser/fuzzy_resolver.lua`

When exact noun match fails, fall back to property-based matching.

**Property Queries:**
- `"the wooden thing"` → matches objects with `material="wood"`
- `"that metal object"` → matches objects with `material="iron"` or `material="steel"`
- `"something sharp"` → matches objects with `sharp=true` capability
- `"the heavy furniture"` → matches objects with `weight > threshold` AND `type_id="furniture"`

**Descriptor Matching:**
- `"that table"` → matches `furniture` with "table" in name/description
- `"the round object"` → matches objects with "round" or "circular" in description
- `"the glass container"` → matches `container` with `material="glass"`

**Implementation:**
1. Extract adjectives from player input (wooden, metal, heavy, sharp, round, glass)
2. Query visible objects for matching properties
3. If multiple matches, prompt player: `"Did you mean the wooden chest or the wooden chair?"`
4. If one match, proceed with confidence

**Risk:** High false-positive rate. Needs extensive testing before enabling by default.

---

### Tier 6: Generalized GOAP (Medium-term, 4-6 hours)

**Impact:** HIGH | **Effort:** MEDIUM | **Risk:** MEDIUM  
**File:** `src/engine/parser/goal_planner.lua`

Extend GOAP beyond `fire_source` to handle arbitrary tool prerequisites.

**Current State:** GOAP only plans for `fire_source` capability (matches). The planner structure is sound, but hard-coded to one use case.

**Target State:** Generalized `plan_for_tool(capability)` that works for:
- `sharp` → finds knife, broken glass, shard
- `needle` → finds sewing needle in drawer
- `key` → searches containers, checks inventory, suggests LOOK UNDER
- `light_source` → finds candle, torch, match
- `container` → finds chest, drawer, sack

**Key Changes:**
1. Replace `try_plan_match()` with `try_plan_capability(capability_name)`
2. Extract match-specific logic into data-driven rules
3. Add capability → search hints mapping: `{ sharp = "Try searching the kitchen for a knife" }`

**Unlock Chain Example:**
```lua
-- Player: "open chest"
-- GOAP detects: chest.locked = true, requires capability="key"
-- GOAP plans:
--   1. Search for key (check inventory, search room, look under objects)
--   2. Take key
--   3. Unlock chest with key
--   4. Open chest
```

**Test Cases:**
- `light candle` → auto-finds and uses match ✅ (already works)
- `unlock door` → auto-finds key in drawer, unlocks ✅ (new)
- `sew sheet` → auto-finds needle in vanity, sews ✅ (new)
- `cut sheet` → auto-finds sharp object, cuts ✅ (new)

---

## 4. Unit Test Strategy

**Prime Directive:** Before implementing ANY tier, write tests first. The test suite IS the specification.

### Test-Driven Development Pattern

**Step 1:** Write failing tests for new behavior  
**Step 2:** Implement feature  
**Step 3:** Verify tests pass  
**Step 4:** Add regression tests for existing behavior

### Test Files (Proposed Structure)

```
test/parser/
├── test-stripping.lua          (Tier 0: politeness, adverbs, preambles)
├── test-question-transform.lua (Tier 1: questions → commands)
├── test-idioms.lua             (Tier 3: phrase mappings)
├── test-context.lua            (Tier 4: discovery memory)
├── test-fuzzy-resolution.lua   (Tier 5: property matching)
└── test-regression.lua         (ALL phrases that work today must keep working)
```

### Regression Test Set (Critical)

Every phrase that works today MUST keep working after improvements. Build test suite from current passing cases:

**Current Passing Phrases (Sample):**
```lua
assert_parses("look", "LOOK", nil)
assert_parses("take match", "TAKE", "match")
assert_parses("I want to open the drawer", "OPEN", "drawer")
assert_parses("examine matchbox then open it", compound + pronoun resolution)
assert_parses("go to bed", "SLEEP", nil)
assert_parses("what time is it?", "TIME", nil)
-- ... 50+ more
```

**Test Harness:**
```lua
function test_parser_input(input, expected_verb, expected_noun)
    local verb, noun = parser.parse(input)
    assert(verb == expected_verb, "Expected verb: " .. expected_verb)
    if expected_noun then
        assert(noun == expected_noun, "Expected noun: " .. expected_noun)
    end
end
```

### Test Coverage Targets

- **Tier 0:** 30+ stripping test cases (politeness, questions, adverbs)
- **Tier 1:** 20+ question transform test cases
- **Tier 2:** No unit tests (error messages are UX, test via playthrough)
- **Tier 3:** 40+ idiom test cases
- **Tier 4:** 15+ context/discovery test cases
- **Tier 5:** 25+ fuzzy resolution test cases
- **Regression:** 100+ passing cases that must NEVER break

---

## 5. Metrics: Measuring Prime Directive Progress

### Quantitative Metrics

**1. Parser Coverage Rate**
- **Definition:** % of "reasonable English phrases" that parse successfully
- **Baseline (Current):** ~70% (estimated from review)
- **Target (A-grade):** 95%+
- **Measurement:** Test suite of 200+ natural phrasing variations

**2. Nelson's Creative Phrasing Pass Rate**
- **Definition:** % of creative phrases from Nelson's playtests that work
- **Baseline (Current):** ~60% (from BUG-067/068 reports)
- **Target (A-grade):** 90%+
- **Measurement:** Dedicate one playtest to "try to break the parser"

**3. Failure Message Quality Score**
- **Definition:** Manual grade of error messages (A/B/C/D/F scale)
- **Baseline (Current):** C- average (from review)
- **Target (A-grade):** B+ average
- **Measurement:** Review all error messages, score helpfulness

**4. Bart's 30+ Failing Examples Coverage**
- **Definition:** % of phrases from review's "20+ Phrases That Should Work" that now pass
- **Baseline (Current):** 3/30 = 10%
- **Target (After Tier 0-3):** 24/30 = 80%
- **Measurement:** Automated test suite

**5. "I Don't Understand" Frequency**
- **Definition:** Number of parse failures per 100 player commands in typical playthrough
- **Baseline (Current):** ~12-15 (estimated)
- **Target (A-grade):** <5
- **Measurement:** Log parse failures during integration tests

### Qualitative Metrics

**6. Player Frustration Events**
- **Definition:** Number of times player tries 3+ phrasings of same intent before succeeding
- **Baseline (Current):** Unknown (need playtest logging)
- **Target (A-grade):** <2 per playthrough
- **Measurement:** Playtest with command logging

**7. Copilot Feel Test**
- **Definition:** Blind playtest — "Does this feel like talking to an AI?"
- **Baseline (Current):** "Feels like an advanced IF parser" (anecdotal)
- **Target (A-grade):** "Feels conversational" (5/5 playtesters)
- **Measurement:** Survey after blind playtest

**8. Magic Moment Frequency**
- **Definition:** Number of times GOAP auto-resolves multi-step prerequisites per playthrough
- **Baseline (Current):** 1-2 (candle-lighting only)
- **Target (After Tier 6):** 5-8 (keys, needles, sharp tools, light sources)
- **Measurement:** Log GOAP plan executions

---

## 6. Architectural Dependencies

### Before Implementing This Roadmap

**None.** All tiers are additive or refinement. No breaking changes to core engine.

### Parallel Work Streams

**Search Memory Implementation** — Tier 4 depends on search system tracking discovered objects. Coordinate with search module owner (Smithers).

**Verb Handler Refactor** — Error message overhaul (Tier 2) is easier after verb file split. Consider refactoring `src/engine/verbs/init.lua` into per-category files first.

### Integration Points

- **GOAP Planner** (Tier 4, Tier 6): Must extend `goal_planner.lua` without breaking existing fire_source logic
- **Context System** (Tier 4): Extends `src/engine/parser/context.lua`
- **Preprocessing** (Tier 0, 1, 3): All changes in `src/engine/parser/preprocess.lua`
- **Error Messages** (Tier 2): Touches every verb handler in `src/engine/verbs/init.lua`

---

## 7. Risk Assessment

| Tier | Risk Level | Mitigation |
|---|---|---|
| Tier 0 (Stripping) | **LOW** | Purely additive; stripped input recurses through pipeline |
| Tier 1 (Questions) | **LOW** | Pattern matching before verb lookup; doesn't affect existing paths |
| Tier 2 (Errors) | **LOW** | UX-only changes; no parser logic affected |
| Tier 3 (Idioms) | **LOW** | Same as Tier 0; additive mappings |
| Tier 4 (Context) | **MEDIUM** | Adds state tracking; requires careful integration with GOAP |
| Tier 5 (Fuzzy) | **MEDIUM** | High false-positive risk; needs extensive testing |
| Tier 6 (GOAP Gen) | **MEDIUM** | Refactors core GOAP logic; risk of breaking fire_source chain |

**Recommended Order:** Implement Tier 0 → 1 → 3 → 2 (quick wins, low risk) before tackling Tier 4/6 (higher impact, higher risk).

---

## 8. Success Criteria

**Tier 0-3 Complete When:**
- ✅ 80% of "20+ Phrases That Should Work" now pass
- ✅ "I don't understand" frequency drops below 8/100 commands
- ✅ Nelson's creative phrasing pass rate exceeds 75%
- ✅ All regression tests pass (100+ existing phrases still work)

**Full Roadmap Complete (A-grade) When:**
- ✅ 95%+ parser coverage on 200-phrase natural language test suite
- ✅ Error messages average B+ helpfulness score
- ✅ "I don't understand" frequency below 5/100 commands
- ✅ 5+ GOAP magic moments per playthrough (not just candle-lighting)
- ✅ Blind playtest: 5/5 testers say "feels conversational"

---

## 9. Iteration Plan

**Sprint 1 (This Week):**
- Tier 0: Stripping Layer (2-3 hours)
- Tier 1: Question Transform (1-2 hours)
- Write regression test suite (2 hours)
- Measure baseline metrics
- **Deliverable:** 15-20% fewer parse failures

**Sprint 2 (Next Week):**
- Tier 3: Idiom Library (1-2 hours)
- Tier 2: Error Message Overhaul (3-4 hours)
- Nelson playtest pass
- **Deliverable:** Error messages feel helpful, not punishing

**Sprint 3 (Week 3):**
- Tier 4 MVP: Discovery tracking (4-6 hours)
- GOAP integration with context
- Integration testing
- **Deliverable:** "Light candle" uses recently examined matchbox

**Sprint 4 (Week 4):**
- Tier 6: Generalized GOAP (4-6 hours)
- Add needle, key, sharp tool planning
- End-to-end playtest
- **Deliverable:** 5+ magic moments per playthrough

**Sprint 5 (Future):**
- Tier 5: Fuzzy Resolution (6-8 hours)
- High-risk, high-reward feature
- Extensive testing before prod
- **Deliverable:** "the wooden thing" works reliably

---

## 10. Long-Term Vision

### Beyond A-Grade (Future Enhancements)

**Contextual Disambiguation** — When player types ambiguous noun, offer choices based on recent context:
```
> take the box
"Which box — the matchbox on the nightstand or the wooden chest by the door?"
```

**Spatial Inference** — Understand relative locations:
```
> "what's near the bed?"
"The nightstand is beside the bed. The rug is underneath it."
```

**Temporal Context** — Commands reference game time:
```
> "when does the clock strike midnight?"
"The wall clock shows 11:45. Midnight is in 15 minutes."
```

**Action Chaining** — Auto-collapse related commands:
```
> "go to the bed and lie down"
Auto-expands to: go to bed → sleep
```

**Learning Mode** — After parse failures, suggest command format:
```
> "I'm trying to get some sleep here"
"Try: 'sleep' or 'go to bed'"
[Remember for next similar phrasing]
```

### The Endgame: Turing Test for IF

**The ultimate test:** A player unfamiliar with text adventures should feel like they're talking to a person (or AI agent), not fighting a parser.

**How we get there:** Engineering, not LLMs. Every tier in this roadmap is zero-cost, local Lua parsing. The illusion of intelligence comes from:
- Robust preprocessing (Tier 0-3)
- Goal-oriented inference (Tier 6)
- Context retention (Tier 4)
- Helpful guidance (Tier 2)
- Sensory fallbacks (existing)
- Progressive search (existing)

This is the Prime Directive made manifest.

---

## Related Documentation

- **[Prime Directive Review](../../../../.squad/decisions/inbox/bart-prime-directive-review.md)** — Detailed gap analysis (this document's source)
- **[Prime Directive Definition](../../../design/00-design-requirements.md)** — REQ-PRIME: The game should feel like talking to an AI
- **[Parser Tier 1: Basic](../parser-tier-1-basic.md)** — Exact verb dispatch (current implementation)
- **[Parser Tier 2: Compound](../parser-tier-2-compound.md)** — Embedding matcher (architectural issues identified)
- **[Parser Tier 3: GOAP](../parser-tier-3-goap.md)** — Goal planner (partially implemented)
- **[Parser Tier 4: Context](../parser-tier-4-context.md)** — Context window (design only, not implemented)
- **[Parser Tier 5: SLM](../parser-tier-5-slm.md)** — Future vision (local embedding model)

---

## Maintenance

**Review Cadence:** Quarterly  
**Metrics Review:** After each sprint  
**Playtest Frequency:** Weekly (during active development)

**Ownership:**
- **Roadmap Maintenance:** Bart (Architect)
- **Implementation:** Bart (Tier 0-1, 3, 6), Smithers (Tier 4 search integration), TBD (Tier 2, 5)
- **Testing:** Nelson (playtesting), Bart (unit tests)

---

*"The illusion of intelligence is engineering. The feeling of intelligence is attention to detail."*  
— Bart, Architect
