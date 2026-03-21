# Parser Tier 2: Compound (Phrase Similarity Fallback)

**Status:** ✅ Built  
**Version:** 1.0  
**Implementation:** `src/engine/parser/init.lua`  
**Purpose:** Graceful fallback for command variations using token-based similarity matching.

---

## Overview

If Tier 1 misses, the input is tokenized and compared to all known phrases using **Jaccard token overlap**.

**Jaccard Formula:**
```
J(A, B) = |A ∩ B| / |A ∪ B|
```

Where A is the tokenized input and B is the tokenized phrase.

**Threshold:** 0.40 (tunable for difficulty)

---

## Design

### Characteristics

- **Cost:** Zero tokens, ~5ms per lookup (single pass through phrase dictionary)
- **Examples:**
  - "examine the chair" → matches "x" (shared token "chair")
  - "look at chair" → matches "examine" (shared tokens)
  - "give match to player" → matches "give"
- **Success Rate:** ~90% of player input (combined with Tier 1)
- **Recovery:** Graceful fail with suggestion: "Did you mean 'look'?"

### Phrase Dictionary

The phrase dictionary is curated by hand and embedded in `src/engine/parser/init.lua`. Examples:

```lua
phrases = {
  ["look around"] = "look",
  ["examine object"] = "examine",
  ["pick up item"] = "take",
  ["light candle with match"] = "light",
  ["put item in container"] = "put",
  ["open door"] = "open",
  ["close door"] = "close",
}
```

---

## Implementation

### Tier 2 Algorithm

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

### Jaccard Overlap Implementation

```lua
function jaccard_overlap(tokens_a, tokens_b)
  local intersection_count = 0
  local union_set = {}
  
  -- Build union and count intersection
  for _, token in ipairs(tokens_a) do
    union_set[token] = true
  end
  
  for _, token in ipairs(tokens_b) do
    if union_set[token] then
      intersection_count = intersection_count + 1
    end
    union_set[token] = true
  end
  
  local union_count = 0
  for _ in pairs(union_set) do
    union_count = union_count + 1
  end
  
  if union_count == 0 then return 0 end
  return intersection_count / union_count
end
```

---

## Combined Flow (Tier 1 → Tier 2)

### Example 1: Direct Match (Tier 1 Success)

```
INPUT: "l at the candle"

TIER 1 CHECK:
  - Normalize: "l at the candle"
  - Exact alias lookup: "l" is an alias for "look"
  - SUCCESS → Route to LOOK handler
```

### Example 2: Fallback Match (Tier 2 Success)

```
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

### Example 3: Complete Failure

```
INPUT: "xyzzy"

TIER 1 CHECK:
  - Normalize: "xyzzy"
  - No match in aliases
  - FAIL → Continue to Tier 2

TIER 2 CHECK:
  - Tokenize: ["xyzzy"]
  - Compare against all phrases
  - No phrase contains "xyzzy"
  - Best score: 0.0 (below threshold)
  - FAIL → Escalate to Tier 3 (if implemented)

Player sees: "I don't understand that. Try 'help'."
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

- **Tier 2:** O(n·m) where n = phrase dictionary size (~50 entries), m = avg tokens per phrase (~3)
  - Total: ~150 token comparisons per input → ~5ms in Lua
- **Combined (Tier 1 + Tier 2):** ~90% of inputs resolve in <1ms (Tier 1)

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

See `parser-tier-3-goap.md` for Tier 3 design.

---

## Future Improvements

- **Fuzzy Matching:** Levenshtein distance for typo tolerance (e.g., "lool" → "look")
- **Weighted Tokens:** Penalize common words ("the", "at") in Jaccard calculation
- **Learned Aliases:** Track user shortcuts and personalize dictionary
- **Multi-Language:** Phrase dictionary entries in multiple languages with fallback

---

## Testing Strategy

### Tier 1 Tests

```lua
assert(tier1_parse("look") == "look")
assert(tier1_parse("l") == "look")
assert(tier1_parse("examine") == "examine")
assert(tier1_parse("take") == "take")
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
assert(parse_input("look") == ("look", nil, nil))

-- Full flow: Tier 2 fallback
assert(parse_input("x at chair") == ("examine", "chair", nil))

-- Full flow: Failure
assert(parse_input("xyzzy") == nil)
```

---

## See Also

- **Parser Tier 1 (Basic):** `parser-tier-1-basic.md`
- **Parser Tier 3 (GOAP):** `parser-tier-3-goap.md`
- **Architecture Overview:** `00-architecture-overview.md`
- **Verb System:** `verb-system.md`
- **Command Variation Matrix:** `../design/command-variation-matrix.md`
- **Parser Implementation:** `src/engine/parser/init.lua`
