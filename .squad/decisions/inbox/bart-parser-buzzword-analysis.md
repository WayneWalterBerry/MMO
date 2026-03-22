# Decision: Parser Strategy — Rejecting AI Buzzwords for Zero-Cost Prime Directive

**Decided By:** Bart (Architect)  
**Date:** 2026-03-25  
**Context:** Wayne asked if Decision Matrix Skill, Humanizer, or Orchestration are needed for Prime Directive achievement.

---

## The Question

*"Do we need Decision Matrix Skill, Humanizer, or Orchestration to achieve the Prime Directive?"*

---

## Decision

**NO — but with nuance.**

All three buzzwords describe patterns from systems that spend tokens and require complex state management. The Prime Directive constraint (ZERO tokens) changes the calculus completely.

---

## Three Rejections + One Acceptance

### 1. Decision Matrix Skill — REJECTED
**Why:** We already have this through GOAP + embedding matcher.  
**Real Problem:** Coverage gap (need more idioms/synonyms), not decision logic.  
**Action:** Expand idiom tables instead of adding framework.

### 2. Humanizer — REJECTED
**Why:** We already have this through narrator.lua + error message overhaul.  
**Real Problem:** Template rotation bug and mechanical error messages, not missing system.  
**Action:** Polish existing systems instead of wrapping them.

### 3. Orchestration Framework — REJECTED
**Why:** Game loop IS already orchestrating. Question is whether pipeline is flexible, not whether it exists.  
**Real Problem:** Monolithic preprocess.lua makes adding stages difficult.  
**Action:** Refactor to table-driven pipeline (simple design, not framework).

### ✅ Table-Driven Pipeline Pattern — ACCEPTED
**Why:** Gives flexibility without framework overhead.  
**Implementation:** Refactor `preprocess.lua` into composable stages:
```lua
local pipeline = {
    strip_politeness,
    strip_adverbs,
    transform_questions,
    expand_idioms,
    resolve_pronouns,
    disambiguate_nouns,
}

local function preprocess(input)
    local text = input
    for _, transform in ipairs(pipeline) do
        text = transform(text)
    end
    return text
end
```

---

## Reasoning

**Constraint:** Prime Directive = "feel like Copilot, cost like Zork" (ZERO tokens).

**The Buzzword Problem:** All three patterns were designed for systems that:
1. Call AI models (spending tokens per inference)
2. Need complex state management (branching, rollback)
3. Scale across services (distributed coordination)

None of these apply. Adding formal versions introduces overhead without benefit.

**What Actually Matters:**
- **Coverage** > decision logic (expand idioms)
- **Polish** > new layers (fix narrator and errors)
- **Simplicity** > frameworks (table-driven pipelines)

---

## Impact

**No New Systems:**
- ❌ No Decision Matrix module
- ❌ No Humanizer layer
- ❌ No orchestration engine

**What Changes:**
- ✅ Refactor preprocess.lua to table-driven (roadmap section 6)
- ✅ Expand idiom mappings (roadmap Tier 3)
- ✅ Polish error messages (roadmap Tier 2)
- ✅ Add discovery memory (roadmap Tier 4)
- ✅ Generalize GOAP (roadmap Tier 6)

**Expected Outcome:**
- Parser coverage: 70% → 95%
- Error message quality: C- → B+
- Player frustration: High → Low

---

## Related Documentation

- `docs/architecture/engine/parser/parser-strategy.md` — Full analysis
- `docs/architecture/engine/parser/prime-directive-roadmap.md` — Implementation plan
- `docs/architecture/engine/parser/README.md` — Parser architecture

---

## Commit

`a86f9d7` — docs: Add parser strategy document (buzzword analysis & architectural decisions)

---

*Principle: The illusion of intelligence is engineering. Zero tokens teaches simplicity.*
