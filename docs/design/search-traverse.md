# Search Traverse System Design

## Overview

Search and find verbs have been redesigned from instant discovery to **progressive room traversals**. The engine walks through a room step-by-step, narrating discoveries, with time cost and interruptibility.

**Core philosophy:** Discovery is not instant; it's a time commitment with narrative pacing that makes exploration feel real.

---

## Proximity Ordering System

### Definition
Proximity ordering is a **fixed, per-room ordered list** of furniture objects, arranged from closest to farthest from the player's current position.

### Room Metadata
Each room includes a `proximity_list` in its metadata:

```lua
bedroom = {
  name = "Master Bedroom",
  description = "...",
  proximity_list = {
    "bed",           -- Player is likely on this
    "nightstand",    -- Adjacent to bed
    "vanity",        -- Across from bed
    "wardrobe",      -- Corner
    "dresser",       -- Wall
    "bookshelf",     -- Far wall
  }
}
```

### Traversal Order
During search/find, the engine iterates through `proximity_list` in order:
1. Start at index 1 (closest)
2. Examine each object
3. Auto-open unlocked containers (stay open)
4. Skip locked containers (with narrative note)
5. Continue until found or list exhausted

### Game Design Implications
- **Proximity feels real:** Player searches closest objects first, expanding outward
- **Fixed per room:** Allows designers to shape discovery narrative through ordering
- **Predictable:** Players learn room layouts through repeated searches
- **Optimization:** Reduces AI computation; order is metadata, not calculated

---

## Turn Cost Model

### Per-Step Cost
**Each step (each furniture object examined) costs one game turn.**

Turn effects during search:
- Injuries tick (e.g., bleeding, poison)
- Clock advances (game time moves forward)
- NPC actions process
- Weather changes occur

### Example: 3-step search
```
> search for knife
You begin searching...

[Turn 1] You feel the dresser — nothing.
[Turn 2] You move to the nightstand — you pull open the drawer...
[Turn 3] Inside, your fingers find: a kitchen knife.

You have found: a kitchen knife.
```

After these commands, 3 turns have elapsed. Any injuries worsen by 3 ticks.

### Design Intent
- **Incentive to search strategically:** Don't search if you're bleeding out
- **Time pressure:** Finding something important may cost you dearly
- **Realistic:** Thorough exploration takes time
- **Interruptibility gateway:** Player can escape a long search by interrupting

---

## Container Auto-Open Mechanics

### Unlocked Containers
**Behavior:** Auto-open silently during traversal; remain open after search.

Example:
```
You reach out to a small nightstand. It has a drawer...
You pull the drawer open.
Inside, your fingers find: a small matchbox and a candle.
```

- Drawer is now **permanently open**
- Player did not pay extra turn cost to open it
- Subsequent `look` shows it as open
- Contents visible without further action

### Locked Containers
**Behavior:** Skip with narrative note; container remains locked.

Example:
```
You spot a locked chest in the corner.
You examine it, but it's locked tight.
```

- Chest remains **locked**
- Player must use `unlock` verb separately
- Does NOT consume a turn during search
- Narrative acknowledges it but doesn't break flow

### Persistent State
- Containers opened during search **stay open**
- Reflects reality: player physically opened them
- Reduces "magical closing" immersion breaks
- Players must manage opened containers (security, narrative implications)

---

## Interruption Handling

### Trigger
Any new player command interrupts the current search traversal.

### Clean Termination
1. Search loop breaks immediately
2. Turn cost applied **only for steps completed**
3. Engine resumes normal command processing
4. No lingering state

### Example
```
> search for torch
You begin searching...

[Turn 1] You feel the bed — nothing there.

> look
[Search interrupted]

You are in a dark bedroom. You can feel:
- A large bed
- A nightstand
```

- Only 1 turn was spent (Step 1 completed)
- Injuries ticked by 1
- New `look` command processes normally
- Search loop fully cleaned up

### Design Rationale
- **Agency:** Player can escape if search takes too long
- **Tactical depth:** Player must choose when to search, when to interrupt
- **Narrative flexibility:** Interruption allows dynamic scene changes

---

## Container State Persistence

### Why Containers Stay Open

1. **Realism:** If you physically open a drawer, it stays open
2. **Narrative continuity:** No magical closing between commands
3. **World consistency:** Objects reflect player's past actions
4. **Exploration reward:** Player sees fruits of their search effort

### Implications

- Player can see what's in opened containers without re-searching
- Opened containers become part of room state (persistent)
- Security considerations: opened containers can be found by NPCs
- Players must manage opened containers for story/stealth reasons

### Implementation
```lua
-- After search opens a container
container.is_open = true
room:persist_object_state(container)  -- Save to room state

-- Subsequent look/examine shows it open
container:describe()  -- "The drawer is open. Inside: ..."
```

---

## Discovery, Not Acquisition

### Core Principle
Finding an object **does NOT pick it up**. It announces it and sets context.

### Workflow

```
[Find succeeds]
You have found: a small matchbox.

[Object becomes context]
> pick up
You pick up the matchbox.  -- Works without repeating "matchbox"

[Or explicit take]
> take it
You take the matchbox.  -- Works with pronoun
```

### Context System
When an object is found, its identifier is stored in the command context:
- `bare_noun_context` = "matchbox"
- Allows follow-up commands to reference it without re-stating name
- Persists until new object found or player moves

### Design Benefit
- **Pacing:** Find announces discovery; take is separate action
- **Agency:** Player chooses to acquire or leave
- **Narrative clarity:** "You have found X" is distinct from "You acquire X"
- **Realism:** Finding ≠ obtaining

---

## Goal-Oriented Search (TBD)

### Syntax
```
find something that can [action]
find something that can light [target]
find something sharp
find something to write with
```

### What It Does
Engine searches for an object that can fulfill the goal (action or property).

### Two Possible Implementations

#### Option A: GOAP-Driven
- Engine uses GOAP (Goal-Oriented Action Planning)
- Determines if found object can achieve goal through available actions
- Most flexible but computationally heavier
- Example: "find something to cut" → engine checks if object has cutting actions

#### Option B: Property Matching
- Objects have simple properties: `fire_source`, `sharp`, `writing_tool`, `container`, etc.
- Engine searches for objects matching the required property
- Fastest but less flexible
- Example: "find something sharp" → searches for `is_sharp = true`

### Current Status: TBD
Wayne wants unit tests to determine the best approach:
1. Start with property matching (simpler, faster)
2. Write unit tests exploring GOAP approach
3. Measure performance and complexity
4. Decide based on test results

### Suggested Unit Tests
```lua
-- Property-based test
test("find something sharp finds knife", function()
  knife.is_sharp = true
  assert(find_goal_match("sharp") == knife)
end)

-- GOAP-based test
test("find something that can cut finds cutting tool", function()
  scissors.actions = {"cut"}
  assert(find_goal_match_goap("cut") == scissors)
end)

-- Hybrid test
test("find something that can light finds fire source", function()
  -- Test both approaches
  -- Measure response time
  -- Evaluate player experience
end)
```

---

## Narrative Generation Pattern

### Sensory-Aware Narration

Narration adapts to light level and available senses:

#### In Daylight (Light Available)
```
You search the room...

Your eyes scan across a large bed — nothing useful.

You turn toward the nightstand and notice: a small lamp.
```

#### In Darkness (No Light)
```
You search the room...

You feel the edge of a large bed — nothing there.

Your hand brushes a nightstand. It has a drawer...
You pull it open.
Inside, your fingers find: a small matchbox.
```

#### Sound-Based Discovery
```
You listen carefully...

You hear the faint tick of a clock. Moving closer, you locate: a wall-mounted clock.
```

### Narrative Templates

**Proximity step (nothing found):**
- Light: "Your eyes scan the {object} — nothing notable."
- Dark: "You feel the {object} — nothing there."
- Sound: "You listen near the {object} — silence."

**Container discovery (unlocked):**
- "The {object} has a drawer..."
- "You notice it's slightly ajar. You pull it open."
- "Inside, your fingers find: {contents}."

**Container discovery (locked):**
- "You spot a locked {object}. You can't open it without a key."

**Target found:**
- "You have found: {object name}."

### Engine Responsibilities
- **Traverse system:** Walks through proximity list, applies turn cost
- **Container logic:** Checks locked/unlocked state, opens automatically
- **Narrative engine:** Generates prose based on sense used and discovery type
- **Context system:** Sets found object as context for follow-up commands

---

## Interruption Flow Chart

```
[Search Start]
        |
        v
[Initialize: turn_cost = 0, current_step = 0]
        |
        v
[Loop: Next furniture in proximity_list]
        |
    +---+---+
    |       |
[Found?]  [More items?]
    |       |
   YES      NO
    |       |
    +---+---+
        |
        v
[Apply turn cost, tick injuries, advance clock]
    |
    +--- [Player inputs new command] ---> [Interrupt search]
    |                                        |
    |                                        v
    +---- [Search completes] -----------> [Return to prompt]
```

---

## Room Metadata Example

```lua
rooms.bedroom = {
  id = "bedroom",
  name = "Master Bedroom",
  description = "A spacious bedroom with morning light filtering through curtains.",
  
  -- Proximity ordering for search/find traversal
  proximity_list = {
    "bed",           -- Player starts here
    "nightstand",    -- Right of bed
    "vanity",        -- Opposite wall
    "wardrobe",      -- Corner
    "dresser",       -- Another wall
    "bookshelf",     -- Far corner
  },
  
  furniture = {
    bed = { /* ... */ },
    nightstand = { is_container = true, is_locked = false /* ... */ },
    vanity = { /* ... */ },
    -- ...
  }
}
```

---

## System Ownership

- **Brockman:** Documentation, design narrative, test specification
- **Bart:** Traverse system architecture, proximity ordering logic, interruption handling
- **Smithers:** Narrative generation, sensory-aware prose templates
- **[TBD Goal-Matcher]:** Goal-oriented search implementation (GOAP or property matching)

---

## Testing Strategy

### Unit Tests Required
1. Proximity ordering respected in traversal
2. Turn cost applied per step
3. Container auto-open (unlocked) and skip (locked)
4. Interruption cleans up state
5. Context set correctly on discovery
6. Goal-oriented search (both approaches for comparison)
7. Sensory narration adapts to light level

### Integration Tests Required
1. Search + take workflow
2. Find + interruption workflow
3. Multiple searches with persistent container state
4. Goal-oriented search with various object types
5. Time pressure scenario (injuries ticking during search)

---

## Future Considerations

- **Partial matches:** "Find something that can make light" (multiple objects qualify)
- **Filtering by location:** "Search the dresser" (search only one container)
- **Time optimization:** Player learns to search efficiently (faster searches for known objects)
- **NPC awareness:** NPCs notice opened containers; can affect story state

