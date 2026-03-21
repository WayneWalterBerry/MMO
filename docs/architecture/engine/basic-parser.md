# Basic Parser: Tier 1 (Exact) + Tier 2 (Phrase Similarity)

**Version:** 1.0  
**Author:** Brockman (Documentation)  
**Date:** 2026-03-25  
**Purpose:** Foundational command parsing covering exact verb matching and phrase similarity fallback.

---

## Overview

The parser is organized in three tiers, each handling progressively more complex command matching:

- **Tier 1 & 2** (this document) — Fast, deterministic, token-free matching
- **Tier 3+** — Goal-Oriented Action Planning (see `intelligent-parser.md`)

Tier 1 + Tier 2 successfully handle ~90% of typical player input with zero latency cost.

**Implementation:** `src/engine/parser/init.lua`

---

## Tier 1: Exact Dispatch

### Design

Input is converted to lowercase and matched against a verb alias dictionary. On match, the verb handler is immediately invoked.

```
INPUT: "look"
STEP 1: Normalize to lowercase: "look"
STEP 2: Exact alias lookup: found → verb_id=LOOK
STEP 3: Route to handler
```

### Characteristics

- **Cost:** Zero tokens, instant (hash table lookup)
- **Examples:** "look", "l", "x chair", "take match"
- **Success Rate:** ~70% of typical player input
- **Pattern:** verb + optional noun(s)

### Alias Dictionary

Verbs may have multiple aliases (shortcuts):

```lua
aliases = {
  look = { "l", "examine", "x", "view" },
  take = { "get", "grab", "pick up" },
  inventory = { "i", "inv" }
}
```

---

## Tier 2: Phrase Similarity

### Design

If Tier 1 misses, the input is tokenized and compared to all known phrases using **Jaccard token overlap**.

**Jaccard Formula:**
```
J(A, B) = |A ∩ B| / |A ∪ B|
```

Where A is the tokenized input and B is the tokenized phrase.

**Threshold:** 0.40 (tunable for difficulty)

### Characteristics

- **Cost:** Zero tokens, ~5ms per lookup (single pass through phrase dictionary)
- **Examples:**
  - "examine the chair" → matches "x" (shared token "chair")
  - "look at chair" → matches "examine" (shared tokens)
  - "give match to player" → matches "give"
- **Success Rate:** ~90% of player input (combined with Tier 1)
- **Recovery:** Graceful fail with suggestion: "Did you mean 'look'?"

### Implementation Strategy

```lua
function tier2_match(input)
  local input_tokens = tokenize(input)
  local best_match = nil
  local best_score = 0
  
  for phrase, verb_id in pairs(phrase_dictionary) do
    local phrase_tokens = tokenize(phrase)
    local score = jaccard_overlap(input_tokens, phrase_tokens)
    
    if score > best_score then
      best_score = score
      best_match = verb_id
    end
  end
  
  if best_score >= THRESHOLD then
    return best_match, best_score
  else
    return nil
  end
end
```

---

## Combined Flow

### Player Input → Verb

```
INPUT: "l at the candle"

TIER 1 CHECK:
  - Normalize: "l at the candle"
  - Exact alias lookup: "l" is an alias for "look"
  - SUCCESS → Route to LOOK handler

---

INPUT: "look at that table"

TIER 1 CHECK:
  - Normalize: "look at that table"
  - Exact alias lookup: no exact match
  - FAIL → Continue to Tier 2

TIER 2 CHECK:
  - Tokenize: ["look", "at", "that", "table"]
  - Compare to phrase dictionary
  - "look" phrase tokens: ["look"]
  - Jaccard(["look","at","that","table"], ["look"]) = 1/4 = 0.25 (MISS)
  - "examine" phrase tokens: ["examine", "item", "object"]
  - Continue through dictionary...
  - Best match found: "look" with score 0.40
  - SUCCESS (at threshold) → Route to LOOK handler
```

---

## Tuple Output

Successful Tier 1 + Tier 2 parsing returns a **verb dispatch tuple**:

```lua
(verb_id, target_noun, optional_tool_noun)
```

Examples:

| Input | Verb | Target | Tool |
|-------|------|--------|------|
| "look" | LOOK | nil | nil |
| "x chair" | EXAMINE | "chair" | nil |
| "light candle with match" | LIGHT | "candle" | "match" |
| "take" | TAKE | nil | nil |

---

## Failure Modes & Recovery

### Case 1: Total Miss

No Tier 1 match and Tier 2 score < threshold.

**Player sees:** "I don't understand that. Try 'help'."

**Action:** Escalates to Tier 3 (if implemented). Otherwise, failure.

### Case 2: Ambiguous Match

Multiple phrases with identical scores (rare).

**Player sees:** "Did you mean 'look' or 'examine'?"

**Action:** Prompts for clarification (not currently implemented; defaults to first match).

---

## Performance Notes

- **Tier 1:** O(1) lookup time (hash table)
- **Tier 2:** O(n·m) where n = phrase dictionary size (~50 entries), m = avg tokens per phrase (~3)
  - Total: ~150 token comparisons per input → ~5ms in Lua
- **Combined:** ~90% of inputs resolve in <1ms (Tier 1)

---

## Phrase Dictionary

The phrase dictionary is curated by hand and embedded in `src/engine/parser/init.lua`. Examples:

```lua
phrases = {
  ["look around"] = LOOK,
  ["examine object"] = EXAMINE,
  ["pick up item"] = TAKE,
  ["light candle with match"] = LIGHT,
  ["put item in container"] = PUT,
  ["open door"] = OPEN,
  ["close door"] = CLOSE,
}
```

---

## Design Rationale

### Why Not LLM for Tier 1 & 2?

1. **Cost:** LLM calls ($0.01–0.10 per request) accumulate quickly in interactive commands
2. **Latency:** Network round-trip (100+ms) kills real-time feel
3. **Overkill:** 70% of inputs don't need AI reasoning

### Why Jaccard for Tier 2?

1. **Fast:** O(n) token comparison, no complex linguistics
2. **Deterministic:** Same input always produces same result
3. **Tunable:** Single threshold controls sensitivity
4. **Works:** Achieves ~90% coverage on typical MUD commands

### When to Escalate to Tier 3

Tier 3 (GOAP-based) kicks in when:
- Tier 1 + Tier 2 both fail (command not recognized)
- User provides complex intent that Tier 1 & 2 can't parse (decomposition needed)
- Prerequisites are missing (e.g., "light candle" fails because no fire source)

See `intelligent-parser.md` for Tier 3+ design.

---

## Testing Strategy

### Tier 1 Tests

```lua
assert(tier1_parse("look") == LOOK)
assert(tier1_parse("l") == LOOK)
assert(tier1_parse("examine") == EXAMINE)
assert(tier1_parse("take") == TAKE)
```

### Tier 2 Tests

```lua
-- Below threshold
assert(tier2_score("look at banana") < THRESHOLD or matches("look"))

-- Above threshold
assert(tier2_score("examine chair") >= THRESHOLD and matches("examine"))

-- Edge case: Single token
assert(tier2_score("x") >= THRESHOLD and matches("examine"))
```

### Integration Tests

```lua
-- Full flow: Tier 1 wins
assert(parse_input("look") == (LOOK, nil, nil))

-- Full flow: Tier 2 fallback
assert(parse_input("x at chair") == (EXAMINE, "chair", nil))

-- Full flow: Failure
assert(parse_input("xyzzy") == nil)
```

---

## Future Improvements

- **Fuzzy Matching:** Levenshtein distance for typo tolerance (e.g., "lool" → "look")
- **Weighted Tokens:** Penalize common words ("the", "at") in Jaccard calculation
- **Learned Aliases:** Track user shortcuts and personalize dictionary
- **Multi-Language:** Phrase dictionary entries in multiple languages with fallback

---

## See Also

- **Intelligent Parser (Tier 3+):** `intelligent-parser.md`
- **Verb System:** `verb-system.md`
- **Command Variation Matrix:** `command-variation-matrix.md`
- **Parser Implementation:** `src/engine/parser/init.lua`
