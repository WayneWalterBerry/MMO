# Search Module Design

**Module Path:** `src/engine/search/`  
**Ownership:** Bart (Architect)  
**Status:** Design Phase  

## Overview

The search module implements progressive room traversal as a **separate, standalone engine component** following the same pattern as `src/engine/injuries.lua` and `src/engine/traverse_effects.lua`.

**Design Principle:** Verb handlers in `verbs/init.lua` stay **thin** — they parse syntax and delegate to the search module. The search module owns ALL traverse state and logic.

## Module Structure

```
src/engine/search/
├── init.lua          ← Public API and state coordination
├── traverse.lua      ← Walk algorithm and proximity ordering
├── containers.lua    ← Container interaction during search
├── narrator.lua      ← Narrative generation system
└── goals.lua         ← Goal-oriented matching (TBD)
```

---

## init.lua — Public API & State Coordination

### Purpose
Provides the public interface for the search system and coordinates between sub-modules.

### Public API

```lua
-- Start a search operation
search.search(ctx, target, scope)
  -- target: string or nil (nil = undirected sweep)
  -- scope: object ID or nil (nil = full room)
  -- Returns: nil (operates through game loop)

-- Start a find operation (alias for search with target)
search.find(ctx, target, scope)
  -- target: string (required)
  -- scope: object ID or nil
  -- Returns: nil

-- Check if a search is currently active
search.is_searching()
  -- Returns: boolean

-- Abort current search (called by any new command)
search.abort(ctx)
  -- Returns: nil

-- Process one search step (called by game loop)
search.tick(ctx)
  -- Returns: boolean (true if search continues, false if complete)

-- Check if an object has been searched before
search.has_been_searched(room_id, object_id)
  -- Returns: boolean

-- Mark an object as searched
search.mark_searched(room_id, object_id)
  -- Returns: nil
```

### State Owned

```lua
_state = {
  active = false,           -- Is a search currently running?
  target = nil,             -- What are we searching for? (nil = sweep)
  scope = nil,              -- Where are we searching? (nil = full room)
  queue = {},               -- Proximity-ordered list of objects to visit
  current_index = 1,        -- Where we are in the queue
  current_step = 0,         -- Turn counter for this search
  found_items = {},         -- Objects discovered so far
  room_id = nil,            -- Which room is being searched
  is_goal_search = false,   -- Is this a goal-oriented search?
  goal_type = nil,          -- Goal property or action (if goal search)
}
```

### Dependencies
- `traverse.lua` — Builds queue, processes steps
- `containers.lua` — Handles container interactions
- `narrator.lua` — Generates output prose
- `goals.lua` — Matches goal-oriented queries

### Events Fired
- None (operates through context and output system)

### Integration with Game Loop

```lua
-- In loop/init.lua
function loop.tick(ctx)
  -- ... existing code ...
  
  -- If search is active, process one step
  if search.is_searching() then
    local continue = search.tick(ctx)
    if not continue then
      -- Search completed or interrupted
      return
    end
  end
  
  -- ... rest of loop ...
end
```

---

## traverse.lua — Walk Algorithm

### Purpose
Implements the proximity-ordered traversal algorithm and step machine.

### Public API

```lua
-- Build a search queue from room proximity list
traverse.build_queue(room, scope, target)
  -- room: room object
  -- scope: object ID or nil
  -- target: search target or nil
  -- Returns: ordered list of objects to visit

-- Process one step of traversal
traverse.step(ctx, queue, index, target)
  -- ctx: game context
  -- queue: list of objects
  -- index: current position
  -- target: what we're looking for
  -- Returns: {
  --   found: boolean,
  --   item: object or nil,
  --   continue: boolean,
  --   narrative: string
  -- }

-- Get proximity-ordered list for a room
traverse.get_proximity_list(room)
  -- room: room object
  -- Returns: ordered list of object IDs

-- Expand an object into searchable surfaces
traverse.expand_object(object, registry)
  -- object: object to expand
  -- registry: object registry
  -- Returns: list of {surface_id, is_container, depth}
```

### State Owned
None (stateless utility functions)

### Dependencies
- `containers.lua` — Checks container properties
- Room metadata (`proximity_list`)
- Registry (for object lookup)

### Algorithm

**Step 1: Build Queue**
1. Get room's `proximity_list` from metadata
2. If `scope` provided, filter to just that object + contents
3. For each object in proximity order:
   - Add surfaces first (top, shelves, undersides)
   - Then add nested containers (drawer, compartments)
   - Recurse depth-first into containers
4. Return ordered queue

**Step 2: Process Step**
1. Get current object from queue
2. Check if it's a container:
   - If locked → skip with narrative note
   - If unlocked and closed → open it (via containers.lua)
3. Check if target found (if targeted search)
4. Generate narrative (via narrator.lua)
5. Return result

**Step 3: Surface Ordering**
Surfaces are always searched before nested containers:
- Nightstand top → Nightstand drawer
- Dresser top → Dresser drawer 1 → Dresser drawer 2
- Bookshelf shelves → Bookshelf compartment

---

## containers.lua — Container Interaction

### Purpose
Handles container detection, opening, locking, and state changes during search.

### Public API

```lua
-- Check if object is a container
containers.is_container(object)
  -- Returns: boolean

-- Check if container is locked
containers.is_locked(object)
  -- Returns: boolean

-- Check if container is open
containers.is_open(object)
  -- Returns: boolean

-- Open a container (if unlocked)
containers.open(ctx, object)
  -- Returns: {success: boolean, narrative: string}

-- Check if container can be auto-opened during search
containers.can_auto_open(object)
  -- Returns: boolean (unlocked and not already open)

-- Get container contents
containers.get_contents(object, registry)
  -- Returns: list of object IDs
```

### State Owned
None (queries and modifies object state directly)

### Dependencies
- Container system (`engine/containers/` if it exists, or object properties)
- FSM engine (for state transitions when opening)

### Reuse Strategy
This module **reuses existing container logic** — it doesn't duplicate container behavior. It's a thin wrapper around existing container systems.

```lua
-- Example: delegates to existing system
function containers.open(ctx, object)
  if object.is_locked then
    return {
      success = false,
      narrative = "It's locked."
    }
  end
  
  -- Reuse existing container open logic
  object.is_open = true
  fsm.apply_state(object, "open", registry)
  
  return {
    success = true,
    narrative = "You open it."
  }
end
```

---

## narrator.lua — Narrative Generation

### Purpose
Generates sensory-appropriate prose for search actions based on light level, object type, and discovery type.

### Public API

```lua
-- Generate narrative for a search step
narrator.step_narrative(ctx, object, found_target, sense)
  -- ctx: game context
  -- object: current object being searched
  -- found_target: was the target found? (boolean)
  -- sense: primary sense being used (vision/touch/hearing)
  -- Returns: string (prose output)

-- Generate narrative for container open
narrator.container_open(ctx, container, is_locked)
  -- Returns: string

-- Generate narrative for search completion
narrator.completion(ctx, found_items, target)
  -- found_items: list of discovered objects
  -- target: what was being searched for
  -- Returns: string

-- Generate narrative for search interruption
narrator.interruption(ctx, steps_taken)
  -- Returns: string

-- Determine primary sense for current conditions
narrator.get_primary_sense(ctx, room)
  -- Returns: "vision" | "touch" | "hearing" | "smell"
```

### State Owned
None (stateless narrative generator)

### Dependencies
- Room light level (`room.light_level` or similar)
- Player sense capabilities (if implemented)

### Narrative Templates

**Step Narrative (Nothing Found)**
- Vision: "Your eyes scan the {object} — nothing notable."
- Touch: "You feel the {object} — nothing there."
- Hearing: "You listen near the {object} — silence."

**Step Narrative (Target Found)**
- Vision: "You turn toward the {object} and spot: {target}."
- Touch: "Your fingers find: {target}."
- Hearing: "You hear a faint {sound} — you locate: {target}."

**Container Open (Unlocked)**
- "The {object} has a drawer..."
- "You notice it's slightly ajar. You pull it open."
- "Inside, your fingers find: {contents}."

**Container Open (Locked)**
- "You spot a locked {object}. You can't open it without a key."

**Completion (Found)**
- "You have found: {object name}."

**Completion (Exhausted)**
- "You finish searching. No {target} found."

**Interruption**
- "[Search interrupted]"

### Sensory Selection Algorithm

```lua
function narrator.get_primary_sense(ctx, room)
  if room.light_level and room.light_level > 0 then
    return "vision"
  elseif ctx.can_hear_objects then  -- if implemented
    return "hearing"
  else
    return "touch"
  end
end
```

---

## goals.lua — Goal-Oriented Matching (TBD)

### Purpose
Matches objects against goal-oriented search queries ("find something that can light").

**Status:** TBD — Unit tests will determine GOAP vs property matching approach.

### Public API

```lua
-- Check if object matches goal
goals.matches_goal(object, goal_type, goal_value, registry)
  -- object: object to check
  -- goal_type: "action" | "property"
  -- goal_value: e.g., "light" | "sharp"
  -- registry: for GOAP resolution if needed
  -- Returns: boolean

-- Parse goal-oriented query
goals.parse_goal(query)
  -- query: e.g., "something that can light the candle"
  -- Returns: {type: "action", value: "light", context: "candle"}
  --       or {type: "property", value: "sharp"}
```

### State Owned
None (stateless matcher)

### Dependencies
- GOAP planner (if GOAP approach chosen)
- Object property system (if property approach chosen)

### Two Implementation Approaches

#### Option A: Property Matching (Simpler, Faster)
```lua
function goals.matches_goal(object, goal_type, goal_value)
  if goal_type == "property" then
    return object["is_" .. goal_value] == true
  end
  return false
end

-- Example object:
knife = {
  id = "knife",
  name = "kitchen knife",
  is_sharp = true,
  is_cutting_tool = true,
  fire_source = false,
}
```

#### Option B: GOAP-Driven (More Flexible, Heavier)
```lua
function goals.matches_goal(object, goal_type, goal_value, registry)
  if goal_type == "action" then
    -- Use GOAP to check if object can achieve action
    local plan = goap.plan(ctx, {[goal_value] = true}, object)
    return plan ~= nil
  end
  return false
end

-- Example: "find something that can light"
-- → GOAP checks if object has "light" action or prerequisite chain
```

### Testing Strategy
Wayne wants **unit tests to decide** the best approach:

```lua
-- Property-based test
test("find something sharp finds knife", function()
  knife.is_sharp = true
  assert(goals.matches_goal(knife, "property", "sharp") == true)
end)

-- GOAP-based test
test("find something that can cut finds scissors", function()
  scissors.actions = {"cut"}
  assert(goals.matches_goal(scissors, "action", "cut", registry) == true)
end)

-- Performance comparison
test("benchmark goal matching performance", function()
  -- Measure both approaches
  -- Compare response time
  -- Evaluate player experience
end)
```

---

## Verb Handler Integration

Verb handlers in `verbs/init.lua` stay **thin** — just parse and delegate:

```lua
-- In verbs/init.lua
handlers["search"] = function(ctx, args)
  local target = args.target  -- from parser
  local scope = args.scope    -- from parser
  
  -- Delegate to search module
  search.search(ctx, target, scope)
end

handlers["find"] = function(ctx, args)
  local target = args.target  -- required
  local scope = args.scope    -- optional
  
  -- Delegate to search module
  search.find(ctx, target, scope)
end
```

All logic lives in the search module, not in verb handlers.

---

## Testing Requirements

### Unit Tests

**traverse.lua:**
- `test_build_queue_full_room` — Proximity order respected
- `test_build_queue_scoped` — Scope filtering works
- `test_expand_object_surfaces_first` — Surfaces before containers
- `test_expand_object_recursive` — Nested containers expanded

**containers.lua:**
- `test_auto_open_unlocked` — Unlocked containers open
- `test_skip_locked` — Locked containers skipped
- `test_container_stays_open` — State persists after search

**narrator.lua:**
- `test_vision_narrative` — Light prose generated
- `test_touch_narrative` — Dark prose generated
- `test_completion_found` — Found message correct
- `test_completion_exhausted` — Not found message correct

**goals.lua:**
- `test_property_matching` — Property-based goals work
- `test_goap_matching` — GOAP-based goals work (if implemented)
- `test_goal_parsing` — Query parsing correct

### Integration Tests

**Full search workflows:**
- `test_search_find_take` — Search → find → take sequence
- `test_search_interruption` — Command interrupts search cleanly
- `test_nested_container_search` — Drawer inside nightstand works
- `test_turn_cost` — Each step advances turn counter
- `test_injury_ticking` — Injuries worsen during search
- `test_search_memory` — Repeated searches skip visited objects

---

## Performance Considerations

### Queue Building
- Proximity lists are **pre-computed** in room metadata
- No dynamic distance calculation at runtime
- Queue building is O(n) where n = objects in room

### Container Expansion
- Recursive depth-first traversal
- Maximum depth should be limited (e.g., 5 levels)
- Prevents infinite loops from circular containment

### Narrative Generation
- Templates are pre-defined strings
- No LLM calls at runtime
- Fast string interpolation only

---

## Future Extensions

### Search Memory System
Track what's been searched to skip on re-search:

```lua
-- In data-model.md's search_memory structure
search.mark_searched(room_id, object_id)
search.has_been_searched(room_id, object_id)
```

### Learning System
Player gets faster at searching known locations:

```lua
-- Reduce turn cost based on familiarity
if player.search_count[object_id] > 5 then
  turn_cost = 0.5  -- Half speed for familiar objects
end
```

### NPC Awareness
NPCs notice opened containers:

```lua
-- After container opened
events.fire("container_opened", {
  object = container,
  opener = player,
  room = room
})
```
