# Spatial Relationships & Stacking System Design

**Date:** 2026-03-26  
**Designer:** Comic Book Guy (Game Design)  
**Status:** Design Complete (Ready for Implementation)  
**Approval:** Wayne Berry (Lead Designer)

---

## Executive Summary

Objects in MMO exist in three-dimensional space. They stack, nest, cover, hide, and interact with gravity. The bedroom is not a flat list of items—it is a **spatial puzzle** where moving the rug reveals the trap door underneath, where the bed sits on top of a rug, where a candle rests on a nightstand.

This document defines:
1. **Spatial Relationships** — the verbs and data model for ON/UNDER/BEHIND/COVERING
2. **Stacking Rules** — which objects can stack, weight/size constraints, capacity limits
3. **Hidden Objects** — how objects become discoverable only after spatial manipulation
4. **Movable Furniture** — push/pull/move mechanics for heavy objects
5. **Spatial Verbs** — the actions players use to manipulate space (PUSH, PULL, LOOK UNDER, LIFT, etc.)
6. **Room Layout Data Model** — how the room tracks relative positions and covering relationships
7. **Integration Points** — how this system works with containers, FSM, composite objects, and the dark/light system

---

## 1. Core Spatial Model: Five Relationships

Objects relate to other objects through five spatial relationships:

### 1.1 ON (Surface Stacking)

An object is **ON** another object when it rests on top of a designated surface. This is the most common relationship for interactive surfaces.

**Examples:**
- Candle ON nightstand (on the `top` surface)
- Pillow ON bed (on the `mattress` surface)
- Matches ON shelf (on the `surface` zone)
- Player can lie ON the bed

**Key Properties:**
- **Surface capacity:** How many objects can be on this surface? (e.g., nightstand top: 3 items max)
- **Weight support:** What's the maximum weight the surface can bear? (e.g., nightstand: 10 lbs; bed: 200 lbs)
- **Stackability flag:** `is_stackable_surface = true` (only stackable objects declare they accept things on top)
- **Visibility:** Objects ON a surface are visible if the surface is accessible (not blocked by something covering it)

**Data Model:**
```lua
-- In object definition:
surfaces = {
    top = {
        name = "top of the nightstand",
        keywords = {"top", "surface"},
        capacity = 3,           -- max 3 items
        weight_capacity = 10,   -- max 10 lbs
        contents = {},          -- what's on top currently
        accessible = true,      -- can player access this surface?
    }
}
```

**Lifecycle:**
- Player: `PUT candle ON nightstand`
- Engine: Checks if nightstand.surfaces.top is accessible → Yes
- Engine: Checks if capacity allows (3/3 full?) → Yes, adds candle
- Engine: Candle object moves to nightstand.surfaces.top.contents
- Engine: Candle's location becomes "on the nightstand" (for reference in descriptions)

### 1.2 UNDER (Beneath Objects)

An object is **UNDER** another object when it's hidden beneath or concealed by it. The relationship is **intentional concealment**, not spatial nesting.

**Examples:**
- Trap door UNDER the rug (the rug covers it)
- Key UNDER the bed (tucked underneath, on the floor)
- Note BEHIND the wardrobe (behind = under, in terms of discovery)

**Critical Difference from ON:**
- **ON:** Object sits on top, visible, accessible if surface is exposed
- **UNDER:** Object is concealed by something above it, invisible until the covering object moves

**Key Properties:**
- **Covering relationship:** Which object is doing the covering? (e.g., rug covers the trap door)
- **Visibility flag:** `visible_when_covered = false` (trap door doesn't exist until rug moves)
- **Discovery condition:** What action reveals the UNDER object? (e.g., moving the rug, lifting something)
- **Parent object reference:** The object underneath knows what's covering it

**Data Model:**
```lua
-- Trap door object:
trap_door = {
    id = "trap-door",
    name = "a trap door",
    covered_by = "rug",         -- this object is under the rug
    visible_when_covered = false, -- not visible until rug moves
    discovery_verb = "move",     -- verb that reveals it: MOVE RUG
    discovery_message = "As you pull the rug aside, your foot catches an edge. A wooden seam. A trap door!",
}

-- Rug object:
rug = {
    id = "rug",
    name = "a Persian rug",
    covering = { "trap-door" },  -- this rug covers the trap door
    -- When rug is moved, reveal covered objects
}
```

**Lifecycle - Covering:**
1. Player: `MOVE RUG`
2. Engine: Checks if rug can move (no preconditions) → Yes
3. Engine: Rug transitions to new position (off trap door)
4. Engine: Checks `covering` array on rug → finds trap-door
5. Engine: Sets trap-door.visible_when_covered = true (or reveals it directly)
6. Engine: Fires discovery_message: "As you pull the rug aside..."
7. Engine: Trap door now appears in EXAMINE description and is explorable

### 1.3 BEHIND (Occluded by Proximity)

An object is **BEHIND** another when it's obscured by an obstacle in front of it. Typically for secrets hidden by furniture placement.

**Examples:**
- Note BEHIND the wardrobe (behind a piece of furniture)
- Passage BEHIND the painting (hidden by the painting hanging over it)
- Loose brick BEHIND the curtains (curtain conceals it)

**Key Properties:**
- **Blocking object:** What's in front? (e.g., wardrobe blocks the note behind it)
- **Visibility condition:** Usually requires moving or examining the blocking object
- **Search verb:** Often requires LOOK BEHIND or MOVE OBJECT deliberately

**Data Model:**
```lua
-- Hidden note:
hidden_note = {
    id = "note-behind-wardrobe",
    name = "a yellowed note",
    hidden_behind = "wardrobe",  -- this note is behind the wardrobe
    visible_when_blocked = false, -- not visible while wardrobe is there
    discovery_verb = "examine",   -- verb that reveals it
}

-- Wardrobe:
wardrobe = {
    id = "wardrobe",
    name = "a tall wooden wardrobe",
    hiding = { "note-behind-wardrobe" }, -- this wardrobe hides items behind it
}
```

### 1.4 COVERING (Active Concealment)

An object **COVERS** another when it's intentionally placed on top to conceal. Unlike ON (where objects just rest), COVERING means the bottom object is inaccessible and invisible.

**Examples:**
- Rug COVERS trap door (the rug is the top object; trap door is underneath)
- Cloth COVERS a hole in the floorboards
- Painting COVERS a safe in the wall

**Key Properties:**
- **Bi-directional relationship:**
  - Rug perspective: `rug.covering = [trap-door]` (the rug covers these)
  - Trap door perspective: `trap_door.covered_by = "rug"` (I'm covered by the rug)
- **Concealment mechanics:** What's underneath becomes inaccessible
- **Reveal mechanic:** Moving the covering object reveals what's beneath

**Data Model:**
```lua
-- Rug (covering side):
rug = {
    id = "rug",
    covering = {
        trap_door = {
            object_id = "trap-door",
            discovery_message = "As you pull the rug aside, a wooden seam catches your foot. A trap door!",
            discovery_conditions = { "rug must be moved away" }
        }
    }
}

-- Trap door (covered side):
trap_door = {
    id = "trap-door",
    covered_by = "rug",
    visible_when_covered = false,
    discovery_trigger = "rug_moved_away",
}
```

### 1.5 INSIDE (Container Containment)

An object is **INSIDE** another when it's placed in a container (nightstand drawer, sack, etc.). This is **different from** ON, UNDER, BEHIND, COVERING—it's a containment relationship.

**Examples:**
- Matches INSIDE matchbox
- Clothes INSIDE wardrobe drawer
- Poison bottle INSIDE nightstand drawer

**Key Properties:**
- **Container vs. Surface:**
  - INSIDE = container semantics (TAKE, DROP, etc. work normally)
  - ON = surface semantics (object sits visibly on top)
- **Capacity:** Maximum items or weight the container can hold
- **Accessibility:** Can the player reach inside? (locked? drawer closed?)
- **Contents inheritance:** When a container-part detaches (e.g., drawer), contents move with it

**Note:** INSIDE is already defined in the **Composite & Detachable Object System** and **Container Surfaces** (FSM doc). This spatial system assumes INSIDE works as documented. See Integration section below.

---

## 2. Stacking Rules: What Can Go On What

Not all objects can stack on all surfaces. The stacking system enforces three constraints:

### 2.1 Stackability Declaration

Each object declares whether it provides a surface for stacking:

```lua
is_stackable_surface = true   -- I accept things on top of me
is_stackable_surface = false  -- I am solid; nothing goes on me
```

**Stackable Objects (examples):**
- Bed: `is_stackable_surface = true` (pillows, sheets, player can lie on it)
- Nightstand: `is_stackable_surface = true` (candle, bottle on top)
- Rug: `is_stackable_surface = true` (furniture sits on it; trap door beneath)
- Shelf: `is_stackable_surface = true` (books, candles on shelf)
- Table: `is_stackable_surface = true` (generic furniture surface)

**Non-Stackable Objects (examples):**
- Candle: `is_stackable_surface = false` (you can't put things on a candle)
- Match: `is_stackable_surface = false` (too small and fragile)
- Book: `is_stackable_surface = false` (books stack, but a single book doesn't declare a surface)
- Ink bottle: `is_stackable_surface = false` (you could theoretically stack on it, but it's fragile)

### 2.2 Weight & Size Constraints

Every object has two properties that affect stacking:

```lua
weight = 10,   -- in "pounds" (units don't matter; scale is relative)
size = 2,      -- in "volume" (1-10 scale; larger = takes up more surface space)
```

Surfaces have capacity limits:

```lua
surfaces = {
    top = {
        weight_capacity = 20,     -- max 20 lbs total
        size_capacity = 5,        -- max 5 volume units
        contents = {}
    }
}
```

**Stacking Validation:**
1. Can the surface accept things? (is_stackable_surface = true)
2. Would adding this object exceed weight capacity?
3. Would adding this object exceed size capacity?

**Example Scenario: Nightstand Stacking**

```
nightstand.surfaces.top:
  - weight_capacity: 10 lbs
  - size_capacity: 3 units
  - contents: [candle(1 lb, 0.5 units), bottle(2 lbs, 1 unit)]
  - remaining: 7 lbs, 1.5 units

Player attempts: PUT book ON nightstand
  - book: 3 lbs, 2 units
  - Validation: 3 lbs < 7 lbs? ✓ YES
  - Validation: 2 units < 1.5 units? ✗ NO (size exceeded)
  - Result: "The nightstand top is too cramped. Try removing something first."
```

### 2.3 Furniture Weight Categories

Heavy objects cannot be placed on light surfaces. Introduce three weight categories:

| Category | Weight Range | Examples | Movable? |
|----------|--------------|----------|----------|
| **Light** | 0.1 – 5 lbs | Candle, bottle, match, book, matches | Yes, by hand |
| **Medium** | 5 – 30 lbs | Nightstand, chair, small table | Yes, with effort (PUSH/PULL) |
| **Heavy** | 30+ lbs | Bed, large wardrobe, bookcase | Difficult; requires multiple players (future) |

**Stacking Rule:** Heavy furniture cannot rest ON light furniture.

```lua
-- Light surface (nightstand):
surfaces.top = {
    weight_capacity = 10,  -- max 10 lbs
}

-- Attempt to put heavy wardrobe on nightstand:
wardrobe: weight = 80 (HEAVY)
Validation: 80 > weight_capacity (10)? ✗ NO
Result: "The nightstand would collapse under the wardrobe's weight."
```

### 2.4 Surface Capacity Models

Different surfaces have different capacity philosophies:

**Model A: Flat Surface (Nightstand Top)**
- Small, flat surface
- Capacity: 3 items OR 10 lbs (whichever fills first)
- Example: "You place a candle on the nightstand. There's still room for 2 small items."

**Model B: Large Surface (Bed)**
- Large, resilient surface
- Capacity: 10+ items OR 200 lbs
- Example: "You lie on the bed. The mattress sags under your weight."

**Model C: Stacking Furniture (Rug)**
- Designed to support heavy objects
- Capacity: Can hold furniture (bed, wardrobe) ON it
- Example: "The bed rests on the rug. The rug bears its weight easily."

**Model D: Container Interior (Drawer)**
- Not a "surface" but a contained space
- Capacity: 4 items OR 15 lbs
- Managed via INSIDE relationship (see Integration section)

---

## 3. Hidden Objects: The Discovery Mechanic

The most important spatial mechanic: **objects don't exist to the player until revealed**. This is different from "dark room can't see"—this is "the object literally isn't discoverable."

### 3.1 Hidden Object States

An object can be in one of three discovery states:

| State | Player Can... | Example |
|-------|---------------|---------|
| **Hidden** | Nothing. Object doesn't appear in descriptions, EXAMINE, or SEARCH. | Trap door under rug |
| **Hinted** | See a description hint ("you notice a seam") without interaction | Trap door when rug is still on top but description mentions "a gap" |
| **Revealed** | Fully interact: EXAMINE, TAKE, MOVE | Trap door after rug is moved |

### 3.2 The Trap Door Example

**Setup:**
- Rug covers trap door
- Trap door is hidden (state: hidden)
- Player enters room, EXAMINE rug → sees no hint of trap door
- Player LOOK UNDER rug → hint message: "There seems to be a seam in the wood."
- Player MOVE rug → trap door becomes revealed

**Lifecycle:**

```
INITIAL STATE (room loads):
  - rug.position = "center floor"
  - rug.covering = [trap_door]
  - trap_door.covered_by = "rug"
  - trap_door.visible_when_covered = false
  - trap_door.discovery_message = "As you pull the rug aside, a wooden seam catches your foot. A trap door!"

PLAYER ACTION 1: EXAMINE rug
  - rug description is provided (doesn't mention trap door)
  - trap_door is not listed in room contents (hidden)

PLAYER ACTION 2: LOOK UNDER rug (if implemented)
  - Engine: Checks if this verb is allowed
  - Engine: Checks if rug has precondition "must_be_moved" → No
  - Engine: Provides hint message (optional): "There's a gap in the wood underneath."

PLAYER ACTION 3: MOVE rug
  - rug.position = "corner" (off the trap door)
  - Engine: Checks rug.covering array → finds trap_door
  - Engine: Sets trap_door.visible_when_covered = true
  - Engine: Fires discovery_message
  - Engine: trap_door now appears in EXAMINE description and room contents
  - trap_door is fully interactive (EXAMINE, MOVE, ENTER if a door)
```

### 3.3 Discovery Conditions

Each hidden object declares what action reveals it:

```lua
-- Trap door object:
trap_door = {
    id = "trap-door",
    name = "a trap door",
    covered_by = "rug",
    visible_when_covered = false,
    
    -- REVEAL CONDITION 1: What action reveals it?
    discovery_trigger = "covering_object_moves",
    discovery_source = "rug",  -- specifically, the rug must move
    
    -- REVEAL CONDITION 2 (alternative): Search action
    -- discovery_trigger = "player_searches",
    -- discovery_verb = "search", 
    -- discovery_message = "You poke around the floor and feel a wooden outline. A trap door!",
    
    -- DISCOVERY MESSAGE: Fired when trap door becomes visible
    discovery_message = "As you pull the rug aside, a wooden seam catches your foot. A trap door!",
}
```

### 3.4 Hidden Object Categories

**Category 1: Covered by Something Above**
- Trigger: Moving the covering object
- Examples: Trap door under rug, key under bed, loose board under blanket

**Category 2: Behind Something**
- Trigger: Moving the blocking object OR examining it
- Examples: Note behind wardrobe, passage behind painting

**Category 3: Inside Something Closed**
- Trigger: Opening the container
- Examples: Matches inside matchbox (already in Composite system)
- Note: This is managed by container FSM; not covered by spatial relationships

**Category 4: Conditional on State**
- Trigger: Object reaching a specific state (candle burning, mirror broken)
- Examples: Shadows visible when light is bright, reflection visible only in unbroken mirror
- Note: This is FSM-driven; spatial system facilitates discovery via state changes

### 3.5 Design Best Practices

**DO:**
- Hide objects that are narrative moments (trap door reveal)
- Provide tactile hints via FEEL/SMELL ("You smell age and wood dust")
- Make discovery feel like achievement ("You found a secret!")
- Use hidden objects as puzzle gates (trap door leads to escape)

**DON'T:**
- Hide objects without any hint mechanism (player feels cheated)
- Hide objects without clear reveal conditions (player feels stuck)
- Use hidden objects for trivial items (wastes puzzle potential)
- Create impossible-to-discover secrets (unless it's an Easter egg with hints elsewhere)

---

## 4. Movable Furniture: Push, Pull, Move

Players can move heavy objects around the room. This is the primary spatial manipulation mechanic.

### 4.1 Movable vs. Fixed Objects

Each object declares whether it can move:

```lua
portable = false,              -- This is furniture; can't carry it
can_be_pushed = true,         -- But it CAN be pushed/pulled
can_be_pulled = true,         -- Yes, both directions
move_difficulty = "moderate", -- Difficulty tier (easy, moderate, hard)
```

**Portable Objects:** Can be picked up and carried in inventory. Already defined in existing systems.

**Movable Furniture:** Too heavy to carry, but can be pushed/pulled within the room.

| Attribute | Value | Notes |
|-----------|-------|-------|
| portable | false | Can't carry this |
| can_be_pushed | true | Can push it |
| can_be_pulled | true | Can pull it |
| move_difficulty | "moderate" | Requires effort |
| move_cost | 2 | Costs 2 ticks of action/resource |

### 4.2 Move Verbs & Syntax

**Verb: PUSH**
```
PUSH bed         → Pushes bed away from player
PUSH bed north   → Pushes bed toward the north wall (if location defined)
PUSH bed onto rug → Pushes bed to rest on the rug
```

**Verb: PULL**
```
PULL rug         → Pulls rug toward player
PULL rug away    → Pulls rug in the "away" direction
PULL rug off trap door → Specific intent (syntax sugar)
```

**Verb: MOVE**
```
MOVE bed         → General move (engine decides direction)
MOVE bed corner  → Moves bed to a specific location in room
```

### 4.3 Movement Mechanics

When a player pushes/pulls an object:

1. **Preconditions Check:**
   - Is the object can_be_pushed/pulled = true?
   - Is the player strong enough? (optional future: strength attribute)
   - Is the path clear? (optional: other furniture blocking?)

2. **Movement Execution:**
   - Object transitions from position A to position B
   - Any objects resting ON the moved object stay with it (bed moves → sheets move with bed)
   - Any objects UNDER the moved object become exposed (rug moves → trap door revealed)

3. **Covering Relationship Update:**
   - If object was covering something, check `covering` array
   - If revealing is conditional, fire discovery message
   - Covered objects transition from hidden to revealed

4. **Side Effects:**
   - Trigger any FSM state changes (bed moved off rug → bed is now "on floor" state)
   - Update room description to reflect new positions

### 4.4 Movement Example: Pushing the Bed Off the Rug

**Initial State:**
```
Room contents:
  - rug (covers trap door)
  - bed (on top of rug)
  - wardrobe (on floor)

bed.position = "on_rug"
rug.covering = [trap_door]
trap_door.visible_when_covered = false
```

**Player Action: PUSH bed away**

```
1. Preconditions: bed.can_be_pushed = true ✓
2. Find new position: bed moves from "on_rug" to "on_floor"
3. Update bed state: bed.position = "on_floor"
4. Handle contents on bed: sheets, pillow move with bed ✓
5. Check what was under bed: rug is still there, unaffected
6. Check rug.covering: [trap_door]
   → Has bed moved away? Yes!
   → Is trap_door still covered? Check rug.position → still center
   → trap_door still hidden (must move rug to reveal)
7. Fire message: "The bed scrapes across the floor. Dust billows."
```

**Player Action: PULL rug away (after bed is moved)**

```
1. Preconditions: rug.can_be_pulled = true ✓
2. Find new position: rug moves from "center" to "corner"
3. Update rug state: rug.position = "corner"
4. Handle contents on rug: bed is no longer on rug (already moved)
5. Check rug.covering: [trap_door]
   → Is rug still covering trap_door? No! Rug moved away.
   → Trigger discovery: trap_door.visible_when_covered = true
   → Fire discovery_message: "As you pull the rug aside..."
6. trap_door is now in room contents and fully interactive
7. Fire message: "The rug bunches up in the corner. Something wooden underneath catches your eye."
```

### 4.5 Movement Difficulty & Resistance

Objects have a move_difficulty that affects success/failure:

| Difficulty | Action Cost | Player Feedback | Example |
|------------|------------|--|---------|
| **easy** | 1 tick | "The chair slides easily." | Chair |
| **moderate** | 2 ticks | "You strain to push the table." | Table, nightstand |
| **hard** | 3+ ticks | "The bed barely budges." | Bed, wardrobe |

**Future Expansion (Multiplayer):** Some objects might require 2+ players:
```lua
-- Wardrobe (very heavy):
move_difficulty = "hard"
move_min_players = 2  -- Requires 2+ players to move
```

---

## 5. Spatial Verbs: The Action Language

Players interact with spatial systems through dedicated verbs. Some exist in the engine; others are new additions needed for spatial puzzles.

### 5.1 Core Spatial Verbs

#### PUT ON / PLACE ON (Object → Surface)
```
Syntax: PUT candle ON nightstand
Checks:
  - Is nightstand.surfaces.top a valid stackable surface?
  - Does surface have capacity?
  - Does item have weight/size that fits?
Actions:
  - Item moves from inventory to surface.contents
  - Update item location reference
  - Provide feedback: "You place the candle on the nightstand."
```

#### TAKE FROM (Surface → Inventory)
```
Syntax: TAKE candle FROM nightstand
Checks:
  - Is candle on the nightstand?
  - Is the surface accessible (not covered)?
Actions:
  - Item moves from surface.contents to inventory
  - Update item location reference
Feedback: "You take the candle."
```

#### LIFT / RAISE (Temporary Exposure)
```
Syntax: LIFT mattress
Semantics: Temporarily peek under something; when you release, it returns
Checks:
  - Is object liftable?
  - What's underneath?
Actions:
  - Show contents of "under" space
  - Optionally: Player can take items while lifted
  - Player can't move the object while lifted (different from MOVE)
Feedback: "You lift the mattress. Underneath, you find a key!"

Note: LIFT is for discovery/access without full removal.
MOVE is for permanent relocation.
```

#### LOOK UNDER (Tactile Discovery)
```
Syntax: LOOK UNDER bed
  or    SEARCH UNDER bed
  or    FEEL UNDER bed  (more appropriate in darkness)
Checks:
  - Is there space under the object?
  - Are there hidden items underneath?
Actions:
  - Reveal hidden items (if conditions met)
  - Fire discovery message if applicable
Feedback: "You feel under the bed. Your hand brushes something cold. A key?"
```

#### LOOK BEHIND (Spatial Occlusion)
```
Syntax: LOOK BEHIND wardrobe
  or    EXAMINE BEHIND wardrobe
Checks:
  - Can player access the space behind?
  - Are there hidden items?
Actions:
  - Describe the space behind
  - Reveal hidden items (if applicable)
  - Optionally: Allow MOVE WARDROBE to access behind
Feedback: "You peer behind the wardrobe. A yellowed note is pinned to the wall."
```

#### PUSH / PULL (Furniture Movement)
```
Syntax: PUSH bed
  or    PUSH bed north
  or    PULL rug
Checks:
  - Object.can_be_pushed/can_be_pulled = true
  - Player has sufficient strength (optional)
Actions:
  - Object moves to new position
  - Update covering relationships
  - Trigger discovery of hidden objects
Feedback: "You push the bed. It scrapes across the floor."
```

#### MOVE (Generic Relocation)
```
Syntax: MOVE chair to corner
  or    MOVE bed away
Checks:
  - Object.can_be_pushed or can_be_pulled = true
  - Direction/destination valid
Actions:
  - Object relocates
  - All spatial relationships update
Feedback: "The chair scrapes along the floor as you move it."
```

### 5.2 Verb Dispatch & Disambiguation

When a player says "PUSH bed," the engine must:

1. **Identify the verb:** PUSH → `detach_verb` or `move_verb`
2. **Identify the target:** bed → resolve to bed object
3. **Check object properties:** bed.can_be_pushed = true?
4. **Route to handler:** spatial_verbs.push(bed, context)
5. **Execute movement:** Trigger spatial relationships, update covering, reveal hidden

**Disambiguation Rules:**
- PUSH vs. PULL vs. MOVE: Different verbs, same category (movement)
- LOOK UNDER vs. FEEL UNDER: Same action, different sensory flavor
- LIFT vs. MOVE: LIFT is temporary; MOVE is permanent

---

## 6. Room Layout Data Model: Tracking Positions

How does the room know where everything is? We need a flexible position model that tracks:
1. What's where (object positions)
2. What's on top of what (covering relationships)
3. What's under what (concealment)
4. What's accessible (visibility of hidden objects)

### 6.1 Position Anchor Model

Each object has a **position** that's either relative to other objects or absolute in the room:

```lua
-- Absolute position (anchor to room):
bed = {
    id = "bed",
    position = "center_floor",  -- "north_wall", "south_wall", "corner", etc.
    location = "bedroom",
}

-- Relative position (anchor to another object):
candle = {
    id = "candle",
    position = "on_nightstand_top",  -- on a surface
    parent_location = "nightstand.surfaces.top"
}

-- Covered/hidden position:
trap_door = {
    id = "trap-door",
    position = "floor_center",      -- where it really is
    covered_by = "rug",             -- but rug is on top
    visible = false                 -- so it's hidden
}
```

### 6.2 Spatial Relationships Table

The room maintains a **spatial relationships table** that tracks:

```lua
-- Room object:
bedroom = {
    contents = {},  -- Top-level objects in the room
    
    -- Spatial relationships (query-able):
    spatial_index = {
        on_relationships = {
            ["nightstand.top"] = {"candle", "bottle"},  -- candle and bottle on nightstand top
            ["bed"] = {"sheets", "pillow"},              -- sheets and pillow on bed
            ["rug"] = {"bed"}                            -- bed is on rug
        },
        
        under_relationships = {
            ["bed"] = {"key"},                           -- key is under bed
            ["rug"] = {"trap-door"}                      -- trap door is under rug
        },
        
        covering_relationships = {
            ["rug"] = {"trap-door"},                     -- rug covers trap door
            ["blanket"] = {}                             -- blanket doesn't cover anything
        },
        
        hidden_objects = {
            ["trap-door"] = true,                        -- trap door is currently hidden
            ["note-behind-wardrobe"] = true              -- note is currently hidden
        }
    }
}
```

### 6.3 Update Flow: When Objects Move

**Scenario: Player pushes bed off the rug**

```
1. spatial_index.on_relationships["rug"] = {"bed"}
2. Player: PUSH bed
3. Validation: bed.can_be_pushed = true ✓
4. Update position: bed.position = "corner" (new)
5. Update spatial_index:
   - REMOVE bed from on_relationships["rug"]
   - ADD bed to on_relationships["floor"] (or implicit "none")
6. Check covering: rug.covering = {"trap-door"}
   - Bed was on rug; rug was covering trap-door
   - Is trap-door still covered? rug.position still center → YES
   - No change to trap-door visibility
7. Fire message: "The bed scrapes across the floor."
```

**Scenario: Player pulls rug away**

```
1. spatial_index.on_relationships["rug"] = {} (bed already gone)
2. Player: PULL rug
3. Validation: rug.can_be_pulled = true ✓
4. Update position: rug.position = "corner" (new)
5. Update spatial_index:
   - REMOVE rug from on_relationships["floor"]
   - ADD rug to on_relationships["floor_corner"]
6. Check covering: rug.covering = {"trap-door"}
   - Rug was covering trap-door
   - Is rug still on top? rug.position = "corner" (away from trap-door)
   - REVEAL trap-door!
7. Update spatial_index:
   - REMOVE "trap-door" from hidden_objects
   - ADD trap-door to room contents
8. Fire discovery_message: "As you pull the rug aside, a wooden seam catches your foot. A trap door!"
9. trap-door is now fully interactive
```

### 6.4 Query Functions for Spatial Logic

The engine provides query functions:

```lua
-- What's on top of the nightstand?
contents = room:query_on_surface("nightstand", "top")
-- Returns: {candle, bottle}

-- What's under the bed?
hidden = room:query_under_object("bed")
-- Returns: {key}

-- Is this object visible?
visible = room:is_object_visible("trap-door")
-- Returns: false (still covered)

-- What's covering this?
covering = room:get_covering_object("trap-door")
-- Returns: rug

-- Can I take this?
can_take = room:can_access_object("candle")
-- Returns: true (on accessible surface)
```

---

## 7. Integration with Existing Systems

The spatial system doesn't exist in isolation. It must work seamlessly with containers, FSM, composite objects, and the dark/light system.

### 7.1 Integration with Containers (FSM + Composite)

**Scenario: Nightstand Drawer**

The nightstand is a composite object with a detachable drawer. The drawer is also a container.

```
Nightstand (parent):
  ├── surfaces.top (stackable surface)
  │   └── contents: [candle, bottle]
  └── parts.drawer (detachable, container)
      ├── detachable = true
      ├── container = true
      └── contents: [matches, poison-bottle]

Spatial relationships:
  - candle ON nightstand.top (surface stacking)
  - matches INSIDE nightstand drawer (container)
  - drawer is PART of nightstand (composite)
  - drawer can be DETACHED (becomes independent)
```

**Player Actions:**
1. `EXAMINE nightstand` → Describes top surface and drawer
2. `PUT candle ON nightstand` → candle.location = nightstand.surfaces.top
3. `OPEN nightstand drawer` → drawer.state = open (FSM transition)
4. `PUT match ON nightstand` → "You need to open the drawer first OR place it on top"
5. `TAKE matches FROM drawer` → Removes from drawer.contents
6. `PULL drawer` → Detaches drawer; it becomes independent in room
   - New FSM state: nightstand.state = "closed_without_drawer"
   - Drawer is now independent object in room
   - Drawer still contains matches (contents preserved)
   - Drawer is now liftable/movable as independent object

**Design Decision:** 
- Surfaces are for stacking objects ON (candle ON nightstand top)
- Containers are for placing objects IN (matches IN drawer)
- Composite objects can have both (nightstand has surface AND drawer)

### 7.2 Integration with FSM (Object Lifecycle)

**Scenario: Candle State Changes Affect Visibility**

```
candle states:
  - unlit: Default state
  - lit: Emits light, burns
  - stub: Nearly burned out, dimmer light
  - spent: Exhausted

Spatial effect:
  - When candle is lit, light_radius = 2
  - When candle is stub, light_radius = 1
  - When candle is spent, light_radius = 0 (doesn't emit light)
  - Objects ON the nightstand become more/less visible depending on candle state
```

**Future Feature: Shadows**

```
If candle is lit and positioned ON nightstand:
  - Objects nearby cast shadows
  - Player sees "shadowy outline of a key under the bed" (less detail)
  - When candle position changes or is extinguished, shadows change

Implementation:
  - Candle FSM tracks position: position = "on_nightstand_top"
  - Light system queries: "What objects are in light_radius?"
  - Spatial system queries: "What objects are under/behind lit objects?"
  - Rendering system combines: "Show object with reduced detail if shadowed"
```

### 7.3 Integration with Composite Objects (Parts)

**Scenario: Bed with Detachable Sheets**

```
Bed (parent):
  ├── surfaces.mattress (stackable)
  │   └── contents: [pillow]
  └── parts.sheets (detachable)
      ├── detachable = true
      └── size = 2, weight = 1 (light fabric)

Initial state:
  - sheets on mattress: PART relationship
  - pillow on mattress: ON relationship (surface stacking)

Player: PULL sheets
  - Sheets detach as independent object
  - Sheets fall to floor next to bed
  - Pillow stays on mattress
  - Bed transitions: state = "without_sheets"
  - Sheets can now be moved/examined independently
```

### 7.4 Integration with Dark/Light System

**Can you manipulate spatial objects in the dark?**

Yes, but with different semantics:

| Action | Dark | Light | Notes |
|--------|------|-------|-------|
| **PUSH bed** | Via FEEL (tactile) | Via LOOK (visual) | Path must be clear |
| **LIFT mattress** | Via FEEL | Via LOOK | Tactile access works |
| **LOOK UNDER** | Via FEEL (more sensitive) | Via LOOK | FEEL is actual touch; LOOK is vision |
| **TAKE from surface** | Via FEEL | Via LOOK | Surface must be accessible tactilely |
| **EXAMINE object** | Via multi-sense | Via LOOK | Dark uses FEEL/SMELL; light uses LOOK |

**Dark-specific challenge:**
- In darkness, player can push furniture but might hit obstacles (no visual feedback)
- Can pull rug but doesn't know what's being revealed until EXAMINE it
- Creates tension: "I pulled the rug. What's under it?"

**Design Philosophy:** Darkness doesn't disable spatial interactions; it changes how they feel.

### 7.5 Integration with Sensory System

Each spatial action fires sensory feedback:

```lua
-- PUSH bed:
on_feel: "The bed scrapes against the floor with a grinding sound."
on_listen: "Wood groans as the bed moves."
on_look: "The bed slowly shifts across the floorboards." (if light)

-- PULL rug:
on_feel: "The rug bunches under your hands as you pull it."
on_smell: "Dust rises from beneath the rug—age and must."
on_listen: "The rug whispers across the floor."
on_look: "Dust motes swirl in the air." (if light)

-- REVEAL trap door:
on_feel: "Your foot catches on a wooden seam. Your heart races."
on_listen: "A metallic click as hinges creak."
on_look: "A large wooden panel set into the floor. Hinges visible."
discovery_message: "You've found the trap door!"
```

---

## 8. Implementation Strategy

### 8.1 Phase 1: Core Spatial Model (MVP)

**Goal:** Get basic ON, UNDER, and MOVE working

**What to implement:**
1. Object properties: `is_stackable_surface`, `can_be_pushed`, `can_be_pulled`, `covered_by`, `covering`
2. Surface capacity: `weight_capacity`, `size_capacity`
3. Basic movement: PUSH, PULL, MOVE verbs
4. Discover hidden: When covering object moves, reveal what's under
5. Query functions: "What's on this surface?", "What's covered?", "Is visible?"

**Example objects to test:**
- Bed, rug, nightstand, candle, trap door
- Simple flow: MOVE rug → trap door revealed

**Code locations:**
- Object properties: Individual .lua files (bed.lua, rug.lua, etc.)
- Spatial index: Room object in registry
- Verbs: src/verbs/spatial.lua (new file)
- Queries: src/spatial.lua (new module)

### 8.2 Phase 2: Hidden Object Discovery

**Goal:** Implement full hidden object lifecycle

**What to implement:**
1. Object state: hidden, hinted, revealed
2. Discovery triggers: covering_object_moves, player_searches, state_change
3. Discovery messages: "You found a secret!"
4. Hint system: FEEL/SMELL/LISTEN provide clues without full reveal

**Example objects:**
- Trap door (covered by rug)
- Note (behind wardrobe)
- Key (under bed)

### 8.3 Phase 3: Advanced Spatial Verbs

**Goal:** LIFT, LOOK UNDER, LOOK BEHIND

**What to implement:**
1. LIFT verb: Temporary peek without full removal
2. LOOK UNDER / FEEL UNDER: Tactile discovery
3. LOOK BEHIND: Spatial occlusion queries
4. Furniture-specific behavior: Some objects can't be lifted

### 8.4 Phase 4: Integration with FSM & Composite

**Goal:** Spatial system works with state changes and detachable parts

**What to implement:**
1. When composite part detaches, update spatial_index
2. When FSM state changes, update surfaces/covering
3. When candle burns, update light radius in spatial queries
4. Test: Drawer detaches → contents on floor; sheets detach → pillow on mattress

---

## 9. Data Structure Examples

### 9.1 Complete Rug Object with Covering

```lua
-- File: src/meta/objects/rug.lua
return {
    id = "rug",
    name = "a Persian rug",
    description = "An ornate Persian rug, worn but beautiful. The colors are faded.",
    
    -- Sensory
    on_feel = "The rug is woven tightly, with ridges and patterns you can feel.",
    on_smell = "Dust and age. Something faintly musty underneath.",
    on_listen = "The rug muffles sound when you move on it.",
    on_look = "Persian patterns of crimson, gold, and indigo. Some threads are worn.",
    
    -- Weight & size
    weight = 15,  -- Medium furniture
    size = 4,     -- Takes up significant space
    
    -- Spatial
    portable = false,
    can_be_pushed = true,
    can_be_pulled = true,
    move_difficulty = "moderate",  -- Takes effort to move
    
    -- Stacking
    is_stackable_surface = true,
    surfaces = {
        top = {
            name = "surface of the rug",
            keywords = {"surface", "top", "rug"},
            capacity = 5,            -- Can hold furniture on it
            weight_capacity = 100,   -- Sturdy; can support bed
            contents = {}
        }
    },
    
    -- Covering
    covering = {
        trap_door = {
            object_id = "trap-door",
            hidden_message = "There seems to be a gap in the wood underneath the rug.",
            discovery_message = "As you pull the rug aside, a wooden seam catches your foot. A trap door!",
            discovery_verb = "move"
        }
    },
    
    -- Location
    location = "bedroom",
    position = "center_floor"
}
```

### 9.2 Complete Trap Door Object with Hidden State

```lua
-- File: src/meta/objects/trap-door.lua
return {
    id = "trap-door",
    name = "a trap door",
    
    -- Initially hidden
    on_look_hidden = "You notice a seam in the wood, too regular to be natural.",
    on_feel_hidden = "Your foot catches on a wooden edge. Something beneath the surface.",
    on_look_revealed = "A heavy wooden panel set into the floor, about 3 feet square. Iron hinges along one edge.",
    
    -- Weight & size
    weight = 20,
    size = 3,
    
    -- Spatial
    portable = false,
    can_be_pushed = false,
    can_be_pulled = true,  -- Can be pulled open
    is_stackable_surface = false,
    
    -- Hidden state
    covered_by = "rug",
    visible_when_covered = false,
    discovery_trigger = "covering_object_moves",
    discovery_source = "rug",
    discovery_message = "As you pull the rug aside, a wooden seam catches your foot. A trap door!",
    discovery_verb = "move",
    
    -- FSM (future)
    -- States: hidden → revealed → open → entered
    -- Initial state: hidden
    
    -- Location
    location = "bedroom",
    position = "floor_center_under_rug"
}
```

### 9.3 Nightstand with Surfaces & Detachable Drawer

```lua
-- File: src/meta/objects/nightstand.lua
-- (Combines surface stacking + composite drawer)

return {
    id = "nightstand",
    name = "a wooden nightstand",
    
    -- Sensory
    on_feel = "Smooth wood, cool and solid. There's a small drawer handle.",
    on_smell = "Old wood, with faint polish.",
    on_look = "A small wooden table, about 24 inches tall. Oak, well-made.",
    
    -- Weight & size
    weight = 12,  -- Medium furniture
    size = 2,
    
    -- Spatial
    portable = false,
    can_be_pushed = true,
    can_be_pulled = true,
    is_stackable_surface = true,
    
    -- TOP SURFACE (for stacking)
    surfaces = {
        top = {
            name = "top of the nightstand",
            keywords = {"top", "surface"},
            capacity = 3,
            weight_capacity = 10,
            contents = {}
        }
    },
    
    -- COMPOSITE: Detachable drawer
    parts = {
        drawer = {
            id = "nightstand-drawer",
            name = "a small drawer",
            detachable = true,
            container = true,
            weight = 2,
            size = 1,
            capacity = 4,
            weight_capacity = 8,
            keywords = {"drawer"},
            on_feel = "A wooden drawer, about 12 inches wide.",
            on_look = "Wooden drawer, painted blue inside.",
            
            factory = function(parent)
                return {
                    id = "nightstand-drawer",
                    name = "a small drawer",
                    location = parent.location,
                    container = true,
                    contents = {},  -- Inherits parent's drawer contents
                    weight = 2,
                    size = 1,
                    -- ... full object definition
                }
            end
        }
    },
    
    -- FSM states (simplified)
    state = "closed_with_drawer",  -- or "open_with_drawer", "closed_without_drawer"
    
    -- Location
    location = "bedroom",
    position = "east_wall"
}
```

---

## 10. Future Expansions

### 10.1 Multiplayer Cooperation

```
-- Future: Some objects require 2+ players
wardrobe = {
    move_difficulty = "very_hard",
    move_min_players = 2,
    -- Two players must both PUSH simultaneously
}
```

### 10.2 Destructible Objects

```
-- Future: Breaking changes spatial state
mirror = {
    breakable = true,
    parts_on_break = ["mirror-shard", "mirror-shard"],
    on_break_message = "The mirror shatters into pieces!",
    covering_when_broken = nil  -- No longer covers anything
}
```

### 10.3 Conditional Stacking

```
-- Future: Only certain objects can stack together
bed_with_wet_sheets = {
    material = "wet_fabric",
    incompatible_with = ["dry_fabric", "match"]  -- Can't stack wet sheets with fire
}
```

### 10.4 Dynamic Room Layouts

```
-- Future: Rooms have multiple layout variants
bedroom = {
    variants = {
        "messy",  -- Furniture scattered
        "clean",  -- Furniture organized
        "burglarized"  -- Furniture overturned
    }
}
```

---

## 11. Success Criteria

The spatial system is complete when:

1. ✅ Objects declare stackability and capacity
2. ✅ Players can PUT objects ON surfaces (respecting capacity)
3. ✅ Players can MOVE furniture (PUSH/PULL)
4. ✅ Moving an object reveals what was underneath
5. ✅ Hidden objects transition from hidden → revealed
6. ✅ Discovery messages fire appropriately
7. ✅ LIFT, LOOK UNDER, LOOK BEHIND verbs work
8. ✅ Spatial system integrates with FSM state changes
9. ✅ Spatial system integrates with composite parts
10. ✅ Spatial system works in darkness (FEEL-based)
11. ✅ Room escape puzzle is solvable: bed → rug → trap door → escape

---

## 12. Key Design Principles

1. **Spatial relationships are first-class concepts.** Not afterthoughts or edge cases.
2. **Hidden objects create achievement moments.** "I found a secret!" is a core feeling.
3. **Darkness doesn't disable space; it changes how you experience it.** FEEL, SMELL, LISTEN work as primary senses.
4. **Weight and size matter.** Heavy furniture can't float; light items don't break surfaces.
5. **Movement has consequences.** Pushing a bed changes what's visible; pulling a rug reveals secrets.
6. **Reversibility is a design choice, not a bug.** Drawers open/close; trap doors stay discovered.
7. **Composite objects stay coherent.** Detaching a drawer keeps its contents; moving a bed moves its sheets.
8. **Integration is seamless.** Spatial, FSM, containers, and sensory systems work together without friction.

---

## 13. Terminology Reference

| Term | Definition |
|------|-----------|
| **ON** | Object rests on a surface (visible if surface exposed) |
| **UNDER** | Object concealed by something above (invisible until covering moves) |
| **BEHIND** | Object obscured by a blocking obstacle (hidden by furniture) |
| **COVERING** | Object on top conceals what's below (bi-directional relationship) |
| **INSIDE** | Object in a container (already in Composite system) |
| **Stackable Surface** | Object declares it accepts things on top (is_stackable_surface = true) |
| **Hidden** | Object not discoverable until specific condition met |
| **Revealed** | Object becomes discoverable after trigger fires |
| **Portable** | Can be picked up and carried (inventory item) |
| **Movable Furniture** | Too heavy to carry; can be pushed/pulled within room |
| **Discovery Trigger** | The action/condition that makes hidden object visible |
| **Covering Relationship** | Bi-directional link between covering object and covered object |

---

End of Document
