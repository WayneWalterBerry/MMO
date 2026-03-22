# Search Data Model

**Module:** `src/engine/search/`  
**Owner:** Bart (Architect)  
**Status:** Design Phase  

## Overview

This document defines all data structures used by the search/find engine, including search queue format, search memory, active search state, and room metadata requirements.

---

## Active Search State

**Location:** Module-local variable in `src/engine/search/init.lua`  
**Persistence:** Volatile (not saved to disk)  
**Scope:** Single active search at a time (global to search module)

```lua
_state = {
  -- Core flags
  active = false,              -- Is a search currently running?
  
  -- Search parameters
  target = nil,                -- What we're looking for (string or nil)
                               -- nil = undirected sweep
                               -- "matchbox" = targeted search
  
  scope = nil,                 -- Where we're searching (object ID or nil)
                               -- nil = full room
                               -- "nightstand" = scoped to that object
  
  -- Queue and position
  queue = {},                  -- Ordered list of search queue entries
                               -- (see SearchQueueEntry below)
  
  current_index = 1,           -- Current position in queue (1-indexed)
  
  current_step = 0,            -- Number of steps taken this search
                               -- (used for turn cost on interruption)
  
  -- Results
  found_items = {},            -- List of discovered object IDs
                               -- (accumulated during sweep)
  
  -- Location
  room_id = nil,               -- Which room is being searched
                               -- (validates we don't cross rooms)
  
  -- Goal-oriented search (TBD)
  is_goal_search = false,      -- Is this a goal-oriented search?
  goal_type = nil,             -- "action" | "property"
  goal_value = nil,            -- e.g., "light", "sharp", "cut"
  goal_context = nil,          -- Additional context (e.g., "the candle")
}
```

### Field Details

**active** (boolean)
- `true` when search is in SEARCHING or STEP state
- `false` when IDLE, FOUND, EXHAUSTED, INTERRUPTED
- Used by `is_searching()` to determine if search is running

**target** (string | nil)
- `nil` for undirected sweep: "search" or "search the room"
- String for targeted search: "search for matchbox"
- Matched against object IDs, names, and aliases

**scope** (string | nil)
- `nil` for full room search
- Object ID for scoped search: "search nightstand"
- Queue builder filters to just this object and its contents

**queue** (list of SearchQueueEntry)
- Built during INITIALIZING state
- Ordered by proximity (closest to farthest)
- Each entry represents one searchable location (surface or container)

**current_index** (integer)
- 1-indexed position in queue
- Incremented after each STEP
- When `current_index > #queue`, search is exhausted

**current_step** (integer)
- Count of completed steps (turn counter)
- Used to calculate turn cost on interruption
- Reset to 0 when search starts

**found_items** (list of strings)
- Accumulates discovered object IDs during sweep
- Used for summary output on EXHAUSTED state
- Empty for targeted search (stops on first match)

**room_id** (string)
- Set during INITIALIZING from `ctx.current_room`
- Validates we don't accidentally cross rooms
- Search never leaves the starting room

**is_goal_search** (boolean)
- `true` for "find something that can light"
- `false` for literal searches
- Triggers goal matcher instead of name matching

**goal_type** (string | nil)
- `"action"` for "find something that can [verb]"
- `"property"` for "find something [adjective]"
- Determines which goal matching strategy to use

**goal_value** (string | nil)
- The action or property being sought
- e.g., "light", "cut", "sharp", "flammable"

**goal_context** (string | nil)
- Additional context from query
- e.g., "find something that can light the candle" → goal_context = "candle"
- May be used by GOAP planner (if implemented)

---

## SearchQueueEntry

**Format:** Each entry in the search queue

```lua
{
  object_id = string,          -- Object identifier (e.g., "nightstand_top")
  
  type = string,               -- "surface" | "container" | "object"
                               -- Determines search behavior
  
  depth = integer,             -- Nesting depth (0 = room level, 1 = inside furniture, 2 = drawer in furniture, etc.)
                               -- Max depth should be limited (5?)
  
  parent_id = string | nil,    -- Parent object ID (nil for room-level objects)
                               -- Used for narrative context
  
  is_container = boolean,      -- Does this entry have contents to search?
  
  is_locked = boolean,         -- Is it locked? (containers only)
                               -- If true, skip with narrative note
  
  is_open = boolean,           -- Is it already open? (containers only)
                               -- If false, auto-open during search
  
  surface_name = string | nil, -- For surfaces: "top", "shelf", "underside"
                               -- Used in narrative generation
}
```

### Example Queue

For a bedroom with bed, nightstand (with drawer), and vanity:

```lua
queue = {
  -- Room-level objects (depth 0)
  {
    object_id = "bed",
    type = "object",
    depth = 0,
    parent_id = nil,
    is_container = false,
    is_locked = false,
    is_open = false,
    surface_name = nil,
  },
  
  -- Nightstand surfaces come first (depth 0)
  {
    object_id = "nightstand_top",
    type = "surface",
    depth = 0,
    parent_id = "nightstand",
    is_container = false,
    is_locked = false,
    is_open = false,
    surface_name = "top",
  },
  
  -- Then nightstand containers (depth 1)
  {
    object_id = "nightstand_drawer",
    type = "container",
    depth = 1,
    parent_id = "nightstand",
    is_container = true,
    is_locked = false,
    is_open = false,
    surface_name = "drawer",
  },
  
  -- Vanity (depth 0)
  {
    object_id = "vanity",
    type = "object",
    depth = 0,
    parent_id = nil,
    is_container = false,
    is_locked = false,
    is_open = false,
    surface_name = nil,
  },
}
```

---

## Room Proximity Metadata

**Location:** Room definition in `src/meta/rooms/`  
**Persistence:** Static (defined in room files)  
**Purpose:** Defines search order for objects (closest to farthest)

```lua
-- Example: bedroom.lua
return {
  id = "bedroom",
  name = "Master Bedroom",
  description = "A spacious bedroom with morning light filtering through curtains.",
  
  -- REQUIRED for search/find functionality
  proximity_list = {
    "bed",           -- Player is likely on this (closest)
    "nightstand",    -- Right beside bed
    "vanity",        -- Across from bed
    "wardrobe",      -- Corner of room
    "dresser",       -- Against wall
    "bookshelf",     -- Far corner (farthest)
  },
  
  -- Furniture objects
  furniture = {
    bed = { /* ... */ },
    nightstand = {
      -- Nightstand HAS surfaces and containers
      surfaces = {"top", "shelf"},
      containers = {"drawer"},
      -- Container properties
      drawer = {
        is_container = true,
        is_locked = false,
        is_open = false,
        contains = {"matchbox", "candle"},
      },
    },
    vanity = { /* ... */ },
    wardrobe = { /* ... */ },
    dresser = { /* ... */ },
    bookshelf = { /* ... */ },
  },
  
  -- Other room properties...
}
```

### Proximity List Format

**Type:** Ordered list of object IDs (strings)

**Rules:**
1. **Designer-defined** — Order is a design decision, not calculated
2. **Closest to farthest** — Start with objects player is near/on
3. **All searchable objects** — Must include all furniture with contents
4. **Room-relative** — Order may differ by room even for same furniture type
5. **Fixed** — Does not change during gameplay

**Design Intent:**
- Allows designers to shape discovery narrative
- Predictable for players (learn room layouts)
- Optimizes performance (no runtime distance calculation)

---

## Object Searchable Metadata

**Location:** Object definitions in `src/meta/objects/`  
**Purpose:** Defines how objects are searched (surfaces, containers, parts)

```lua
-- Example: nightstand.lua
return {
  id = "nightstand",
  name = "small nightstand",
  
  -- Surfaces (searched first, in order)
  surfaces = {
    "top",        -- Searched first
    "shelf",      -- Then shelf
  },
  
  -- Nested containers (searched after surfaces, in order)
  containers = {
    "drawer",     -- Then drawer
  },
  
  -- Drawer properties
  drawer = {
    id = "nightstand_drawer",
    name = "nightstand drawer",
    is_container = true,
    is_locked = false,
    is_open = false,
    
    -- Drawer contents (visible when opened)
    contains = {"matchbox", "candle"},
  },
  
  -- ... other properties ...
}
```

### Surface Types

Common surface types (narrative-friendly):
- `"top"` — Top surface of object
- `"shelf"` | `"shelves"` — Horizontal storage planes
- `"underside"` — Bottom of object (e.g., under table)
- `"ledge"` — Narrow horizontal surface

### Container Properties

Required for containers:
- `is_container` — Boolean flag
- `is_locked` — Can search auto-open?
- `is_open` — Current state
- `contains` — List of object IDs (or empty list)

---

## Search Memory

**Location:** Stored on room object  
**Persistence:** Saved to disk with room state  
**Purpose:** Track what's been searched to optimize re-searches

```lua
-- On room object
room.search_memory = {
  -- Map of object_id -> boolean (has been searched)
  bed = true,
  nightstand_top = true,
  nightstand_drawer = true,
  vanity = false,  -- Not yet searched
  
  -- Timestamp of last full room search (optional)
  last_full_search = 1678900000,
  
  -- Search count per object (for learning system, optional)
  search_counts = {
    bed = 3,
    nightstand_drawer = 5,
  },
}
```

### API

```lua
-- Check if object has been searched
search.has_been_searched(room_id, object_id)
  -- Returns: boolean

-- Mark object as searched
search.mark_searched(room_id, object_id)
  -- Modifies room.search_memory[object_id] = true

-- Clear search memory for room (optional)
search.clear_memory(room_id)
  -- Resets room.search_memory = {}
```

### Design Intent

**Optimization:**
- Skip already-searched objects on re-search
- "You've already searched the bed" message

**Player learning:**
- Track search counts per object
- Could reduce turn cost for familiar locations (future feature)

**Realism:**
- Player doesn't re-search same location every time
- "I already looked there" behavior

---

## Goal-Oriented Query Structure

**Format:** Parsed from natural language query

```lua
-- Example: "find something that can light the candle"
{
  type = "action",             -- "action" | "property"
  value = "light",             -- Action verb or property name
  context = "candle",          -- Optional target context
  original_query = "find something that can light the candle",
}

-- Example: "find something sharp"
{
  type = "property",
  value = "sharp",
  context = nil,
  original_query = "find something sharp",
}
```

### Parsing Rules

**Action-based:**
- Pattern: "something that can [verb]"
- Extract: verb → goal_value

**Property-based:**
- Pattern: "something [adjective]"
- Extract: adjective → goal_value

**With context:**
- Pattern: "something that can [verb] [noun]"
- Extract: verb → goal_value, noun → context

---

## Object Property Schema (for Goal Matching)

**Option A: Property-Based Matching**

Objects define boolean properties:

```lua
-- Example: knife.lua
{
  id = "knife",
  name = "kitchen knife",
  
  -- Properties for goal matching
  is_sharp = true,
  is_cutting_tool = true,
  is_weapon = true,
  fire_source = false,
  is_writing_tool = false,
}

-- Example: matchbox.lua
{
  id = "matchbox",
  name = "small matchbox",
  
  fire_source = true,
  is_container = true,
  is_sharp = false,
  can_light = true,
}
```

**Option B: GOAP-Based Matching**

Objects define available actions (existing system):

```lua
-- Example: matchbox.lua
{
  id = "matchbox",
  name = "small matchbox",
  
  actions = {"open", "close", "light"},  -- Existing GOAP actions
}
```

Goal matcher uses GOAP planner to determine if object can achieve goal.

---

## Container State Persistence

**Important:** Containers opened during search **stay open**.

### Before Search
```lua
nightstand.drawer = {
  is_open = false,
  contains = {"matchbox", "candle"},
}
```

### After Search (drawer opened)
```lua
nightstand.drawer = {
  is_open = true,  -- ← CHANGED
  contains = {"matchbox", "candle"},
}
```

### Persistence
Container state is saved with room:
```lua
-- When saving room state
save_room(room)
  -- Includes all furniture states
  -- includes container is_open flags
```

On reload, drawers remain open if they were opened during search.

---

## Performance Considerations

### Queue Size
- Typical room: 5-10 furniture pieces
- Each piece: 1-3 surfaces + 0-2 containers
- Expected queue size: 15-30 entries
- Max depth: 5 levels (to prevent infinite recursion)

### Memory Usage
- Active search state: ~1 KB
- Search memory per room: ~500 bytes (50 objects × 10 bytes per entry)
- Proximity metadata per room: ~200 bytes (20 objects × 10 bytes per ID)

### Disk Persistence
Only search memory is persisted:
- Stored in room state file
- Updated on search completion
- Small enough to save frequently

---

## Example: Full Data Flow

### Initial State
```lua
-- Player is in bedroom
ctx.current_room = "bedroom"

-- Search state is idle
_state.active = false

-- Room has proximity list
rooms["bedroom"].proximity_list = {"bed", "nightstand", "vanity"}

-- Room has no search memory yet
rooms["bedroom"].search_memory = {}
```

### Command: "search for matchbox"
```lua
-- Verb handler calls search module
search.find(ctx, "matchbox", nil)

-- INITIALIZING state
_state = {
  active = true,
  target = "matchbox",
  scope = nil,
  queue = {
    {object_id = "bed", type = "object", depth = 0, ...},
    {object_id = "nightstand_top", type = "surface", depth = 0, ...},
    {object_id = "nightstand_drawer", type = "container", depth = 1, ...},
    {object_id = "vanity", type = "object", depth = 0, ...},
  },
  current_index = 1,
  current_step = 0,
  room_id = "bedroom",
  found_items = {},
  is_goal_search = false,
}

-- Transition to SEARCHING
```

### Turn 1: First Step
```lua
-- Game loop calls search.tick()

-- STEP state
-- Examine queue[1] = bed
-- No matchbox found
-- Mark as searched

rooms["bedroom"].search_memory["bed"] = true

-- Increment
_state.current_index = 2
_state.current_step = 1

-- Output: "You feel the edge of a bed. Nothing there."

-- Back to SEARCHING
```

### Turn 3: Found
```lua
-- STEP state
-- Examine queue[3] = nightstand_drawer
-- is_container = true, is_locked = false, is_open = false
-- Call containers.open()
-- Check contents: ["matchbox", "candle"]
-- Match found!

-- Update container state
nightstand.drawer.is_open = true

-- Update search memory
rooms["bedroom"].search_memory["nightstand_drawer"] = true

-- Set context
ctx.last_noun = "matchbox"

-- Output:
-- "It has a drawer... you pull it open."
-- "Inside, your fingers find: a small matchbox."
-- "You have found: a small matchbox."

-- Transition to FOUND → IDLE
_state.active = false
_reset_state()
```

### Final Persistent State
```lua
-- Room state (saved to disk)
rooms["bedroom"].search_memory = {
  bed = true,
  nightstand_top = true,
  nightstand_drawer = true,
}

-- Container state (saved to disk)
nightstand.drawer.is_open = true

-- Context (volatile, not saved)
ctx.last_noun = "matchbox"
```

---

## Testing Requirements

### Data Structure Tests
- `test_queue_entry_format` — Valid queue entries created
- `test_proximity_list_required` — Error if room missing proximity_list
- `test_search_memory_persistence` — Memory saved with room state
- `test_container_state_persistence` — Opened containers stay open

### Data Validation Tests
- `test_invalid_scope` — Error on non-existent scope
- `test_max_depth_limit` — Queue stops at depth 5
- `test_circular_containment` — No infinite loops

### Performance Tests
- `test_large_room_queue_size` — 50+ objects handled efficiently
- `test_deep_nesting` — 5 levels of containers
- `test_search_memory_overhead` — Memory usage reasonable
