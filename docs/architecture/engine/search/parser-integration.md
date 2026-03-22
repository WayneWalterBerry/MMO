# Search Parser Integration

**Module:** `src/engine/search/` + `src/engine/parser/`  
**Owner:** Bart (Architect)  
**Status:** Design Phase  

## Overview

This document describes how the parser pipeline handles search/find syntax patterns and feeds them into the search engine module.

**Key Principle:** Verb handlers stay **thin** — they parse syntax and delegate to `search.search()` or `search.find()`. All logic lives in the search module.

---

## Syntax Patterns

### Basic Patterns

| Pattern | Example | Type | Target | Scope |
|---------|---------|------|--------|-------|
| `search` | "search" | sweep | nil | nil |
| `search around` | "search around" | sweep | nil | nil |
| `search the room` | "search the room" | sweep | nil | nil |
| `search for [target]` | "search for matchbox" | targeted | "matchbox" | nil |
| `find [target]` | "find matchbox" | targeted | "matchbox" | nil |
| `search [scope]` | "search nightstand" | scoped sweep | nil | "nightstand" |

### Compound Patterns

| Pattern | Example | Type | Target | Scope |
|---------|---------|------|--------|-------|
| `search [scope] for [target]` | "search the nightstand for the matchbox" | scoped targeted | "matchbox" | "nightstand" |
| `find [target] in [scope]` | "find the matchbox in the nightstand" | scoped targeted | "matchbox" | "nightstand" |
| `search [scope] for [target]` | "search nightstand for matches" | scoped targeted | "matches" | "nightstand" |

### Goal-Oriented Patterns (TBD)

| Pattern | Example | Type | Goal Type | Goal Value |
|---------|---------|------|-----------|------------|
| `find something that can [action]` | "find something that can light the candle" | goal-action | "action" | "light" |
| `find something [property]` | "find something sharp" | goal-property | "property" | "sharp" |
| `find something to [verb]` | "find something to write with" | goal-action | "action" | "write" |

---

## Parser Pipeline

### Tier 1: Preprocessor

**Location:** `src/engine/parser/preprocess.lua`

**Normalizations:**
- `"search around"` → `"search"`
- `"look for X"` → `"find X"` (semantic mapping: visual → general search)
- `"search the room"` → `"search"`
- Strip articles: `"the matchbox"` → `"matchbox"`

```lua
-- In preprocess.lua
function preprocess(input)
  local normalized = input:lower()
  
  -- Normalize search variants
  normalized = normalized:gsub("search around", "search")
  normalized = normalized:gsub("search the room", "search")
  
  -- Map "look for" to "find"
  normalized = normalized:gsub("look for ", "find ")
  
  -- Strip articles
  normalized = normalized:gsub(" the ", " ")
  normalized = normalized:gsub(" a ", " ")
  normalized = normalized:gsub(" an ", " ")
  
  return normalized
end
```

### Tier 2: Pattern Matching

**Location:** `src/engine/parser/init.lua`

Extract verb, target, and scope from normalized input:

```lua
-- In parser/init.lua
function parse_search_command(input)
  local verb, target, scope
  
  -- Pattern: "search [scope] for [target]"
  verb, scope, target = input:match("^(search) (%S+) for (.+)$")
  if verb then
    return {verb = "search", target = target, scope = scope}
  end
  
  -- Pattern: "find [target] in [scope]"
  verb, target, scope = input:match("^(find) (%S+) in (.+)$")
  if verb then
    return {verb = "find", target = target, scope = scope}
  end
  
  -- Pattern: "search for [target]"
  verb, target = input:match("^(search) for (.+)$")
  if verb then
    return {verb = "search", target = target, scope = nil}
  end
  
  -- Pattern: "find [target]"
  verb, target = input:match("^(find) (.+)$")
  if verb then
    return {verb = "find", target = target, scope = nil}
  end
  
  -- Pattern: "search [scope]"
  verb, scope = input:match("^(search) (.+)$")
  if verb then
    return {verb = "search", target = nil, scope = scope}
  end
  
  -- Pattern: "search" (bare)
  verb = input:match("^(search)$")
  if verb then
    return {verb = "search", target = nil, scope = nil}
  end
  
  return nil  -- Not a search command
end
```

### Tier 3: Goal-Oriented Parsing (TBD)

Extract goal type and value from natural language:

```lua
-- In parser/goals.lua (NEW)
function parse_goal_query(target)
  -- Pattern: "something that can [action]"
  local action = target:match("something that can (%w+)")
  if action then
    return {type = "action", value = action}
  end
  
  -- Pattern: "something that can [action] [context]"
  local action, context = target:match("something that can (%w+) (.+)")
  if action then
    return {type = "action", value = action, context = context}
  end
  
  -- Pattern: "something [property]"
  local property = target:match("something (%w+)")
  if property then
    return {type = "property", value = property}
  end
  
  -- Pattern: "something to [verb]"
  local verb = target:match("something to (%w+)")
  if verb then
    return {type = "action", value = verb}
  end
  
  return nil  -- Not a goal query
end
```

---

## Scope Resolution

**Purpose:** Convert scope string into object ID or validate it exists.

```lua
-- In verbs/init.lua or parser/init.lua
function resolve_scope(ctx, scope_str)
  if not scope_str then
    return nil  -- Full room search
  end
  
  -- Find object in current room
  local room = registry.get(ctx.current_room)
  local object = find_visible(ctx, scope_str)
  
  if not object then
    output("You don't see a " .. scope_str .. " here.")
    return false  -- Error
  end
  
  return object.id
end
```

### Scope Examples

| Input | Scope String | Resolved ID | Notes |
|-------|--------------|-------------|-------|
| "search nightstand" | "nightstand" | "nightstand" | Direct match |
| "search the small nightstand" | "nightstand" | "nightstand" | After article stripping |
| "search bed" | "bed" | "bed" | Simple match |
| "search drawer" | "drawer" | "nightstand_drawer" | Finds nested container |

---

## Target Resolution

**Purpose:** Convert target string into search parameter (literal or fuzzy).

### Exact Matching
Target matches object ID or name exactly:
```lua
-- "matchbox" → finds object with id="matchbox" or name="matchbox"
```

### Fuzzy Matching
Target matches objects that **contain** the target:
```lua
-- "matches" → finds "matchbox" which contains "match" objects
-- "match" → finds "match" inside "matchbox" inside "drawer"
```

### Fuzzy Resolution Algorithm

```lua
-- In search/traverse.lua
function matches_target(object, target, registry)
  -- Exact ID match
  if object.id == target then
    return true
  end
  
  -- Exact name match
  if object.name == target then
    return true
  end
  
  -- Substring match in name
  if object.name:find(target) then
    return true
  end
  
  -- If object is container, check contents
  if object.is_container then
    for _, child_id in ipairs(object.contains or {}) do
      local child = registry.get(child_id)
      if matches_target(child, target, registry) then
        return true
      end
    end
  end
  
  return false
end
```

**Example:**
- Target: "matches"
- Drawer contains: ["matchbox", "candle"]
- Matchbox contains: ["match", "match", "match", ...]
- Result: Drawer matches target (fuzzy match through nested contents)

---

## Context Setting

**Purpose:** Found objects become the target for follow-up commands.

### Context Variable
```lua
ctx.last_noun = object_id
```

### Follow-Up Resolution
After finding an object, bare commands resolve to it:

```lua
-- Sequence:
> find matchbox
You have found: a small matchbox.

[ctx.last_noun = "matchbox"]

> take it
[Parser resolves "it" → ctx.last_noun → "matchbox"]
You take the matchbox.

> open it
[Still resolves to "matchbox"]
You open the matchbox.
```

### Context Persistence
Context persists until:
1. New object found (replaces `last_noun`)
2. Player moves to different room (clears context)
3. Player examines different object (updates `last_noun`)

---

## Multi-Command Chaining

**Purpose:** Search results feed into subsequent commands in a chain.

### Parser Support
Multi-command separator: `,` or `and`

```lua
-- Example: "search for a match, light it and light the candle"
-- Parses into:
[
  {verb = "search", target = "match", scope = nil},
  {verb = "light", target = "it", scope = nil},  -- "it" = match
  {verb = "light", target = "candle", scope = nil},
]
```

### Context Flow
1. First command (`search for a match`) executes
   - Sets `ctx.last_noun = "match"`
2. Second command (`light it`) resolves `"it"` to `ctx.last_noun`
   - Lights the match
3. Third command (`light candle`) uses explicit target
   - Uses lit match (held) to light candle

### Example Workflow

**Input:** `"search for a match, take it, light it, light the candle"`

**Parsed:**
```lua
commands = {
  {verb = "search", target = "match"},
  {verb = "take", target = "it"},
  {verb = "light", target = "it"},
  {verb = "light", target = "candle"},
}
```

**Execution:**
```
Turn 1-3: Search for match (3 steps)
  → Found match in matchbox in drawer
  → ctx.last_noun = "match"

Turn 4: Take it
  → Resolves "it" → "match"
  → Take match from matchbox

Turn 5: Light it
  → Resolves "it" → "match"
  → Light match (now lit_match)
  → ctx.last_noun = "lit_match"

Turn 6: Light candle
  → Explicit target: "candle"
  → Use held match (fire_source) to light candle
```

**Total turns:** 6 (3 for search, 1 for each subsequent command)

---

## Verb Handler Implementation

### handlers["search"]

```lua
-- In verbs/init.lua
handlers["search"] = function(ctx, args)
  local target = args.target  -- May be nil (sweep)
  local scope = args.scope    -- May be nil (full room)
  
  -- Resolve scope if provided
  if scope then
    scope = resolve_scope(ctx, scope)
    if scope == false then
      return  -- Error already output
    end
  end
  
  -- Delegate to search module
  search.search(ctx, target, scope)
end
```

### handlers["find"]

```lua
-- In verbs/init.lua
handlers["find"] = function(ctx, args)
  local target = args.target  -- REQUIRED
  local scope = args.scope    -- Optional
  
  -- Validate target
  if not target or target == "" then
    output("Find what?")
    return
  end
  
  -- Check for goal-oriented query
  local goal = parse_goal_query(target)
  if goal then
    -- Goal-oriented search (TBD)
    search.find_goal(ctx, goal, scope)
    return
  end
  
  -- Resolve scope if provided
  if scope then
    scope = resolve_scope(ctx, scope)
    if scope == false then
      return
    end
  end
  
  -- Delegate to search module
  search.find(ctx, target, scope)
end
```

---

## Error Handling

### Missing Target (Find)
```lua
> find
Find what?
```

### Invalid Scope
```lua
> search the unicorn
You don't see a unicorn here.
```

### Meaningless Query
```lua
> find something
Find what? Be more specific.
```

### Empty Room
```lua
> search
There's nothing to search here.
```

---

## Parser Integration Points

### 1. Preprocessor
- Normalize search variants
- Strip articles
- Map "look for" → "find"

### 2. Pattern Matching
- Extract verb, target, scope
- Handle compound patterns
- Parse goal-oriented queries

### 3. Scope Resolution
- Convert scope string → object ID
- Validate object exists in room
- Handle nested containers

### 4. Target Resolution
- Exact matching
- Fuzzy matching (recursive)
- Goal matching (TBD)

### 5. Context Setting
- Set `ctx.last_noun` on discovery
- Enable pronoun resolution ("it", "them")
- Persist across commands

### 6. Multi-Command Chaining
- Parse comma-separated commands
- Pass context between commands
- Handle turn cost per command

---

## Testing Requirements

### Pattern Matching Tests
- `test_parse_search_bare` — "search"
- `test_parse_search_for_target` — "search for matchbox"
- `test_parse_find_target` — "find matchbox"
- `test_parse_search_scope_for_target` — "search nightstand for matchbox"
- `test_parse_find_target_in_scope` — "find matchbox in nightstand"
- `test_parse_search_scope` — "search nightstand"

### Scope Resolution Tests
- `test_resolve_scope_valid` — "nightstand" → "nightstand"
- `test_resolve_scope_invalid` — "unicorn" → error
- `test_resolve_scope_nested` — "drawer" → "nightstand_drawer"

### Target Resolution Tests
- `test_exact_match` — "matchbox" finds matchbox
- `test_fuzzy_match` — "matches" finds matchbox containing matches
- `test_recursive_fuzzy` — "match" finds match inside matchbox inside drawer

### Goal Parsing Tests
- `test_parse_goal_action` — "something that can light" → {type="action", value="light"}
- `test_parse_goal_property` — "something sharp" → {type="property", value="sharp"}
- `test_parse_goal_with_context` — "something that can light the candle" → includes context

### Context Setting Tests
- `test_found_sets_context` — Search sets `ctx.last_noun`
- `test_pronoun_resolution` — "it" resolves to `ctx.last_noun`
- `test_context_persists` — Context survives multiple commands
- `test_context_replaced` — New find replaces old context

### Multi-Command Tests
- `test_chain_search_take` — "search for X, take it"
- `test_chain_search_light` — "find match, light it, light candle"
- `test_chain_turn_cost` — Each command in chain costs turns correctly

---

## Integration with Existing Systems

### Verb System
- Search/find verbs registered in `handlers` table
- Thin handlers that delegate to search module
- Reuse existing verb dispatch infrastructure

### Parser System
- Extends pattern matching with search-specific patterns
- Reuses existing preprocessor
- Adds goal-oriented parsing (new)

### Context System
- Uses existing `ctx.last_noun` for pronoun resolution
- Reuses existing noun resolution logic
- Extends with fuzzy matching

### GOAP System (if goal-oriented search uses GOAP)
- Query GOAP planner to check if object can achieve goal
- Reuse existing GOAP action definitions
- No duplication of action metadata

---

## Performance Considerations

### Pattern Matching
- Sequential pattern matching is O(n) where n = number of patterns
- Keep pattern list short (~10 patterns)
- Most specific patterns first

### Scope Resolution
- O(1) for exact ID match
- O(n) for name search where n = objects in room
- Expected: n < 20 in typical room

### Target Fuzzy Matching
- O(n*m) where n = queue size, m = avg nesting depth
- Expected: n < 30, m < 5
- Total operations: < 150 per search

### Goal Parsing
- O(1) for regex matching
- No performance concerns

---

## Future Extensions

### Natural Language Questions
Support question syntax:
```
> where is the matchbox?
[Internally: "find matchbox"]
```

### Preposition Variations
Handle spatial prepositions:
```
> search under the bed
> search on top of the nightstand
> search inside the drawer
```

### Partial Result Suggestions
When goal-oriented search finds multiple matches:
```
> find something that can light
You found several things:
- A matchbox
- A candle (but it needs to be lit first)
- A lighter
Which did you mean?
```

---

## Example: Full Parser Flow

**Input:** `"search the nightstand for matches"`

**Step 1: Preprocessor**
```
"search the nightstand for matches"
→ strip "the"
→ "search nightstand for matches"
```

**Step 2: Pattern Matching**
```
Pattern: "search [scope] for [target]"
Match: verb="search", scope="nightstand", target="matches"
```

**Step 3: Scope Resolution**
```
resolve_scope(ctx, "nightstand")
→ find_visible(ctx, "nightstand")
→ object_id = "nightstand"
```

**Step 4: Delegate to Search Module**
```lua
search.search(ctx, "matches", "nightstand")
```

**Step 5: Search Module Builds Queue**
```
Scope = "nightstand"
→ Filter room proximity list to nightstand subtree
→ Queue: ["nightstand_top", "nightstand_drawer"]
```

**Step 6: Traverse**
```
Turn 1: Check nightstand_top → no match
Turn 2: Check nightstand_drawer → open it → contains matchbox → matchbox contains matches → MATCH!
```

**Step 7: Set Context**
```
ctx.last_noun = "matchbox"  -- Or "match" depending on resolution
Output: "You have found: a small matchbox."
```

**Result:**
- 2 turns elapsed
- Drawer opened (persistent)
- Context set for follow-up command
- Player can now "take it" or "open it"
