# Parser Strategy: Why We Don't Need AI Orchestration Buzzwords

**Author:** Bart (Architect)  
**Date:** 2026-03-25  
**Context:** Analysis of strategic architectural choices in pursuit of the Prime Directive ("feel like Copilot, cost like Zork")

---

## The Question

Wayne asked: *"Do we need Decision Matrix Skill, Humanizer, or Orchestration to achieve the Prime Directive?"*

**Answer:** No. But the reasoning behind this decision — and one architectural pattern worth keeping — matters.

---

## The Three Buzzwords Examined

### 1. Decision Matrix Skill

**What it really is:**  
Structured decision-making using weighted scoring matrices to pick the "best" interpretation from multiple parser candidates. Each candidate (verb interpretation) gets scored across dimensions like confidence, frequency, context fit, etc.

**Why it sounds tempting:**  
The parser sometimes finds multiple valid interpretations. A scoring system could pick intelligently instead of just picking the first match.

**Why we don't need it:**  
We already have this concept embedded in our pipeline — it's just called **GOAP + parser disambiguation**. 

- Tier 2 (Embedding Matcher) returns scored candidates and picks by Jaccard similarity
- Tier 3 (GOAP) evaluates candidates against prerequisites
- The pipeline naturally filters by confidence

Adding a formal "Decision Matrix Module" would be **infrastructure for infrastructure's sake**. The real gap isn't decision logic — it's coverage. We need better **synonyms and idiom mappings** (width), not better decision frameworks.

**Example gap (real problem):**  
Player types: `"burn the candle"`  
Current system: BURN not recognized as synonym for LIGHT  
Matrix Skill would solve: Scores BURN=0.8 vs LIGHT=0.9 (if both were recognized)  
Real solution: Add BURN → LIGHT idiom mapping

**Verdict:** Skip the module. Expand the idiom table instead.

---

### 2. Humanizer

**What it really is:**  
A layer that makes AI-generated responses sound natural/conversational instead of mechanical. Applies tone transformations, adds filler words, varies sentence structure, etc.

**Why it sounds tempting:**  
Our narrator sometimes sounds robotic. A "humanization layer" could soften responses, making them feel less like classic IF and more like talking to an AI assistant.

**Why we don't need it:**  
We already have this — it's called **`narrator.lua` + error message overhaul (Tier 2 of the roadmap)**.

- `narrator.lua` already handles sensory text variation
- The error message rewrite (Tier 2, Prime Directive roadmap) IS humanization — it replaces mechanical "I don't understand" with helpful "Did you mean X?"
- The "progressive search" narrator already rotates templates (poorly, but structurally sound)

A "Humanizer Layer" would just be a wrapper around what `narrator.lua` should already do better. The real work is:
1. **Expand narrator templates** (sensory variations)
2. **Rewrite verb error messages** (guidance instead of punishment)
3. **Fix narrator template rotation** (don't pick `templates[1]` every time)

None of this needs a separate system. It's just doing the existing work well.

**Example gap (real problem):**  
Player types: `"look"`  
Current system: Returns `"Your eyes scan the room — nothing notable."`  (always)  
Humanizer would solve: Cycles through templates: "Your gaze sweeps across...", "You look around...", "Nothing catches your attention..."  
Real solution: Fix the narrator template rotation bug in search_verbose

**Verdict:** Skip the module. Polish `narrator.lua` and error messages instead.

---

### 3. Orchestration

**What it really is:**  
A framework for coordinating multiple components/stages in a pipeline. Orchestration systems (popular in cloud AI) manage state, error handling, branching logic, and stage sequencing.

**Why it sounds tempting:**  
The parser IS a pipeline: Raw Input → Preprocess → Verb Handler → Search → GOAP → Narrator. Maybe we need formal orchestration to make it flexible, testable, and extensible.

**Why we don't need the framework, but the pattern matters:**  
We already have orchestration — it's called **the game loop**. The question isn't whether the pipeline exists; it's whether it's **flexible enough**.

**What we ARE doing (from roadmap section 6):**  
Refactor `preprocess.lua` from one monolithic function into a **table-driven pipeline**. This is the ONE orchestration pattern worth borrowing:

```lua
local pipeline = {
    strip_politeness,     -- Tier 0
    strip_adverbs,        -- Tier 0
    transform_questions,  -- Tier 1
    expand_idioms,        -- Tier 3
    resolve_pronouns,     -- Existing
    disambiguate_nouns,   -- Tier 5
}

-- Each stage receives input, returns transformed output
local function preprocess(input)
    local text = input
    for _, transform in ipairs(pipeline) do
        text = transform(text)
    end
    return text
end
```

**Why this works (and why a formal framework doesn't):**

| Aspect | What Frameworks Offer | What We Actually Need |
|---|---|---|
| Complexity | State machines, branching, rollback | 6 sequential transforms, each 10-50 lines |
| Extensibility | Configuration files, plugins | Add function to table, done |
| Testability | Mock stages, dependency injection | Test each function in isolation |
| Tokens Cost | Zero | ZERO — this is the whole point |

Adding a formal orchestration framework would introduce infrastructure overhead that doesn't serve the player experience. The table-driven approach is simpler, cheaper, and just as extensible.

**Example: Adding a new stage** (idiom expansion at Tier 3)  
With framework: Wire up configs, register handlers, define contracts, add middleware  
With table: `table.insert(pipeline, expand_idioms)` ✅

**Verdict:** Don't use a framework. Use good pipeline design instead.

---

## The Common Rejection Reason

All three buzzwords describe patterns from systems that:
1. Call AI models (spending tokens per inference)
2. Need complex state management (branching, rollback)
3. Scale across many services (distributed coordination)

**The Prime Directive constraint is ZERO tokens.** We're not building an AI system — we're building an **interpreter** that LOOKS like AI through engineering and attention to detail.

Adding formal versions of these patterns would introduce architectural complexity that doesn't serve that goal. Instead:

- **Coverage matters more than framework.** More synonyms beats a smarter scorer.
- **Existing systems matter more than new layers.** Better narrator beats a humanizer wrapper.
- **Simplicity beats sophistication.** A table-driven pipeline beats an orchestration engine.

---

## What IS Going to Happen

The ONE concept worth implementing is the **extensible interpretation pipeline** (from roadmap section 6).

### Current State
```lua
-- preprocess.lua is one monolithic function
local function preprocess(input)
    local text = strip_articles(input)
    text = strip_politeness(text)
    text = strip_adverbs(text)
    -- 50 more lines of tangled if/else
    return text
end
```

**Problems:**
- Hard to test individual stages
- Hard to reorder or disable stages
- Hard to add new transforms without breaking existing ones

### Target State (Roadmap Section 6)

```lua
-- Explicit, composable pipeline
local pipeline = {
    strip_politeness,       -- Tier 0: "please", "can I", "let me"
    strip_adverbs,          -- Tier 0: "carefully", "quickly"
    transform_questions,    -- Tier 1: "what's in X?" → "examine X"
    expand_idioms,          -- Tier 3: "set fire to X" → "light X"
    resolve_pronouns,       -- Existing: "it", "that" → context
    disambiguate_nouns,     -- Tier 5: "wooden thing" → property match
}

local function preprocess(input)
    local text = input
    for _, transform in ipairs(pipeline) do
        text = transform(text)
    end
    return text
end
```

### Full Interpretation Flow

```
Raw Input
    ↓
[pipeline stages] ← Each stage: 10-50 lines, easy to test
    ↓
Clean Command
    ↓
Verb Handler ← Dispatch to LOOK/TAKE/LIGHT/etc
    ↓
Execute ← Game state mutation
    ↓
Narrate ← narrator.lua with templates
```

### Each Stage is Self-Contained

**Example: `strip_politeness`** (Tier 0)
```lua
local function strip_politeness(text)
    text = text:gsub("^please%s+", "")           -- "please open drawer"
    text = text:gsub("^can%s+i%s+", "")          -- "can I look around?"
    text = text:gsub("^could%s+you%s+", "")      -- "could you examine this?"
    text = text:gsub("^let%s+me%s+", "")         -- "let me take the match"
    text = text:gsub("^maybe%s+i%s+should%s+", "")  -- "maybe I should look"
    return text
end
```

**Example: `transform_questions`** (Tier 1)
```lua
local function transform_questions(text)
    -- "what's in the drawer?" → "examine drawer"
    if text:match("what'?s%s+in%s+the%s+(.+)%?") then
        return "examine " .. text:match("what'?s%s+in%s+the%s+(.+)%?")
    end
    -- "where is the key?" → "find key"
    if text:match("where%s+is%s+the%s+(.+)%?") then
        return "find " .. text:match("where%s+is%s+the%s+(.+)%?")
    end
    return text
end
```

---

## Key Insight: The Prime Directive Gap Is Coverage, Not Architecture

The parser pipeline architecture is sound. What's needed:

| Gap | Solution | Buzzword Trap |
|---|---|---|
| Missing synonyms/idioms | Expand idiom table (width) | Decision Matrix Skill |
| Mechanical error messages | Rewrite verb handlers (tone) | Humanizer |
| Stiff narrator templates | Fix template rotation bug | Humanizer |
| Limited GOAP | Generalize planner (breadth) | Orchestration |
| Noun ambiguity | Property-based matching (fuzzy) | Decision Matrix Skill |

**None of these require new architectural patterns. They require making the existing pipeline smarter at each stage.**

---

## Implementation Strategy

### Phase 1: Pipeline Refactor (Prerequisites)
1. Refactor `preprocess.lua` into table-driven pipeline
2. Write tests for each stage in isolation
3. **Status:** Foundational work before all Tier improvements

### Phase 2: Low-Risk Wins (Tiers 0-3)
1. **Tier 0:** Strip politeness + adverbs (1-2 hours)
2. **Tier 1:** Transform questions → commands (1-2 hours)  
3. **Tier 3:** Expand idiom mappings (1-2 hours)
4. **Tier 2:** Error message overhaul (2-3 hours)
5. **Result:** 80%+ parser coverage on natural phrasing

### Phase 3: High-Impact Features (Tiers 4, 6)
1. **Tier 4:** Context window (discovery memory)
2. **Tier 6:** Generalized GOAP (arbitrary tool prerequisites)
3. **Result:** Multiple GOAP "magic moments" per playthrough

### Phase 4: Polish (Tier 5)
1. **Tier 5:** Fuzzy noun resolution (highest risk, highest reward)
2. **Result:** A-grade Prime Directive alignment (95%+)

---

## Rejection Summary

| Buzzword | What We Did Instead | Why It Works |
|---|---|---|
| **Decision Matrix Skill** | Expanded idiom mappings + Tier 2/5 | Direct solution, no framework overhead |
| **Humanizer** | Polish narrator.lua + error messages | Existing systems, just need attention |
| **Orchestration Framework** | Table-driven pipeline | Simplicity, testability, zero overhead |

**The pattern we kept:** Composable pipeline stages. This is orchestration in the *good* sense (clean interfaces, easy to test) without the *bad* sense (infrastructure overhead).

---

## Conclusion

The Prime Directive gap is real. The solution is not more frameworks — it's **engineering discipline**:

- More coverage at each stage (synonyms, idioms, patterns)
- Better error messages (guidance, not punishment)
- Simpler architecture (table-driven, not orchestrated)
- Relentless testing (regression suites, playtest feedback)

This is the illusion of intelligence through attention to detail. No buzzwords required.

---

**See Also:**
- [Prime Directive Roadmap](prime-directive-roadmap.md) — Detailed tiers and implementation plan
- [README.md](README.md) — Parser architecture overview
- [Design Requirements](../../../design/00-design-requirements.md) — REQ-PRIME background
