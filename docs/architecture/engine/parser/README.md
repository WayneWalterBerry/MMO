# Parser Architecture

**Purpose:** Natural language parsing pipeline for conversational text adventure interface  
**Philosophy:** Feel like talking to an AI — but cost nothing to run (Prime Directive)

---

## Overview

The parser transforms player input (natural English) into game commands through a multi-tier pipeline. Each tier adds robustness and intelligence while maintaining zero runtime costs.

**Current State:** 5 tiers documented (3 implemented, 2 designed)  
**Prime Directive Alignment:** C+ / 65% (see roadmap for improvement path)

---

## Pipeline Tiers

### Tier 1: Basic (Exact Verb Dispatch)
**Status:** ✅ Implemented  
**Doc:** [parser-tier-1-basic.md](../parser-tier-1-basic.md)  
**Coverage:** ~70% of typical player input

Fast hash-based verb alias lookup. Handles simple commands:
- `look` → LOOK verb
- `x chair` → EXAMINE "chair"
- `take match` → TAKE "match"

### Tier 2: Compound (Embedding Matcher)
**Status:** ✅ Implemented (architectural issues identified)  
**Doc:** [parser-tier-2-compound.md](../parser-tier-2-compound.md)  
**Coverage:** ~15% of atypical input

Jaccard similarity matching against 4,337 pre-built phrases. Falls back when Tier 1 fails. Currently has noun leakage issues (returns phrase dictionary noun instead of player's noun).

### Tier 3: GOAP (Goal-Oriented Action Planning)
**Status:** ⏳ Partially Implemented  
**Doc:** [parser-tier-3-goap.md](../parser-tier-3-goap.md)  
**Coverage:** Prerequisite chains for specific capabilities

Backward-chains prerequisites when player lacks required tools:
- `light candle` → auto-finds match, opens containers, strikes match, lights candle
- Currently only handles `fire_source` capability (not generalized)

### Tier 4: Context Window
**Status:** 📋 Designed (not implemented)  
**Doc:** [parser-tier-4-context.md](../parser-tier-4-context.md)  
**Planned Coverage:** Discovery memory + confidence scoring

Would track examined objects and use discovery context to inform GOAP planning. Example: after `examine matchbox`, `light candle` would know matches are in the matchbox.

### Tier 5: SLM (Small Language Model)
**Status:** 🔮 Future Vision  
**Doc:** [parser-tier-5-slm.md](../parser-tier-5-slm.md)  
**Planned Coverage:** Semantic understanding with local embeddings

Long-term: use small language model for semantic similarity (still client-side, no API calls). Handles intent matching beyond pattern recognition.

---

## Prime Directive Roadmap

**See:** [prime-directive-roadmap.md](prime-directive-roadmap.md)

Our North Star document for evolving the parser from "better than classic IF" (C+ / 65%) to "feels like Copilot" (A / 95%).

**Key Improvements Planned:**
- **Tier 0:** Politeness/adverb stripping (immediate, high impact)
- **Tier 1:** Question-to-command transformation
- **Tier 2:** Error message overhaul (guide, never punish)
- **Tier 3:** Idiom library expansion
- **Tier 4:** Context window implementation
- **Tier 5:** Fuzzy noun resolution (property-based matching)
- **Tier 6:** Generalized GOAP (beyond fire_source)

**Current Gaps:**
- Politeness words (`please`, `can I`, `let me`) fail
- Adverbs (`carefully examine`, `look closely`) poison parsing
- Error messages are mechanical (Zork-style, not Copilot-style)
- GOAP only handles candle-lighting (not keys, needles, sharp tools)
- No discovery memory (examining matchbox doesn't teach GOAP)

**Target State Test Cases:**
1. Any reasonable English → meaningful response
2. Error messages guide, never punish
3. No "magic words" — multiple phrasings reach same action
4. Questions work as commands
5. Discovery feeds context (Copilot-style inference)

---

## Implementation Files

```
src/engine/parser/
├── init.lua              (Main entry point, Tier 1 dispatch)
├── preprocess.lua        (Natural language transformations)
├── embedding_matcher.lua (Tier 2: Jaccard similarity)
├── goal_planner.lua      (Tier 3: GOAP backward chaining)
└── context.lua           (Pronoun resolution, last_object tracking)
```

---

## Test Strategy

**Before implementing any tier:** Write tests first. The test suite is the specification.

**Regression Critical:** Every phrase that works today MUST keep working after improvements.

**Test Structure:**
```
test/parser/
├── test-stripping.lua          (Politeness, adverbs)
├── test-question-transform.lua (Questions → commands)
├── test-idioms.lua             (Phrase mappings)
├── test-context.lua            (Discovery memory)
├── test-regression.lua         (100+ passing cases)
```

---

## Metrics

**Parser Coverage Rate:** ~70% → Target: 95%  
**Nelson's Creative Phrasing Pass Rate:** ~60% → Target: 90%  
**Error Message Quality:** C- → Target: B+  
**"I Don't Understand" Frequency:** 12-15/100 → Target: <5/100

---

## Related Documentation

- **[Prime Directive Roadmap](prime-directive-roadmap.md)** — North Star for A-grade alignment
- **[Prime Directive Review](../../../../.squad/decisions/inbox/bart-prime-directive-review.md)** — Gap analysis
- **[Design Requirements](../../../design/00-design-requirements.md)** — REQ-PRIME: Feel like talking to AI
- **[Search Integration](../search/parser-integration.md)** — How search uses parser context

---

*"The illusion of intelligence is engineering. The feeling of intelligence is attention to detail."*
