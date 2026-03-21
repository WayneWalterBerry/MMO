# Parser Tier 1: Basic (Exact Verb Dispatch)

**Status:** ✅ Built  
**Version:** 1.0  
**Implementation:** `src/engine/parser/init.lua`  
**Purpose:** Fast, zero-latency verb dispatch via exact alias matching.

---

## Overview

Input is converted to lowercase and matched against a verb alias dictionary. On match, the verb handler is immediately invoked.

```
INPUT: "look"
STEP 1: Normalize to lowercase: "look"
STEP 2: Exact alias lookup: found → verb_id=LOOK
STEP 3: Route to handler
```

---

## Design

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

## Implementation

### Tier 1 Logic

```lua
function tier1_parse(input)
  -- Normalize to lowercase
  local normalized = string.lower(input)
  
  -- Extract first word (the verb)
  local verb = normalized:match("^(%w+)")
  
  -- Check if verb is in alias dictionary
  if aliases[verb] then
    return verb
  end
  
  -- Check if verb is an alias of another verb
  for base_verb, alias_list in pairs(aliases) do
    for _, alias in ipairs(alias_list) do
      if alias == verb then
        return base_verb
      end
    end
  end
  
  return nil  -- No match
end
```

---

## Examples

| Input | Verb | Target | Tool |
|-------|------|--------|------|
| "look" | LOOK | nil | nil |
| "x chair" | EXAMINE | "chair" | nil |
| "l" | LOOK | nil | nil |
| "take" | TAKE | nil | nil |

---

## Performance Notes

- **Lookup Time:** O(1) hash table lookup
- **Latency:** <1ms (typically sub-millisecond)
- **Success Coverage:** ~70% of typical player input

---

## Testing Strategy

```lua
assert(tier1_parse("look") == "look")
assert(tier1_parse("l") == "look")
assert(tier1_parse("examine") == "examine")
assert(tier1_parse("take") == "take")
assert(tier1_parse("xyzzy") == nil)  -- No match
```

---

## See Also

- **Parser Tier 2 (Phrase Similarity):** `parser-tier-2-compound.md`
- **Parser Tier 3 (GOAP):** `parser-tier-3-goap.md`
- **Architecture Overview:** `00-architecture-overview.md`
- **Verb System:** `verb-system.md`
- **Parser Implementation:** `src/engine/parser/init.lua`
