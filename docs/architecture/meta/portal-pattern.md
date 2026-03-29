# Portal Object Pattern

**Author:** Brockman (Documentation)  
**Date:** 2026-03-26  
**Status:** Current — reference implementation available  
**Related:** `../rooms/room-exits.md`, `core-principles.md`, `../../design/verb-system.md`

---

## 1. What Is a Portal?

A **portal** is a first-class passage object that connects two rooms. It's defined as a `.lua` file, instantiated in a room, and referenced from that room's exit table. Portals are immutable as objects (can't be picked up, moved, or deleted), but their **state** changes via FSM transitions.

**Principle 8 compliance:** Portal objects declare their behavior (states, transitions, sensory properties). The engine executes the FSM to change state. No portal-specific logic lives in verb handlers.

---

## 2. Template Inheritance

All portals inherit from `src/meta/templates/portal.lua`:

```lua
return {
    guid = "d902e90d-ec66-45df-8b93-a8dd35a6aaca",
    id = "portal",
    name = "a passage",
    template = "portal",
    
    portal = {
        target = nil,
        bidirectional_id = nil,
        direction_hint = nil,
    },
    
    initial_state = "open",
    _state = "open",
    states = {
        open = {
            traversable = true,
            description = "An open passage.",
        },
    },
    transitions = {},
    
    on_feel = "A passage.",
    
    categories = {"portal"},
}
```

Every portal instance **must override**:
- `guid` — unique Windows GUID
- `id` — unique object ID
- `portal.target` — destination room ID
- `portal.direction_hint` — direction keyword (north, south, up, down, etc.)
- `name` — display name for this specific passage
- `description`, sensory properties, states, transitions (custom to the portal type)

**Optional overrides:**
- `portal.bidirectional_id` — if paired with another portal
- `max_carry_size`, `max_carry_weight` — passage constraints
- `material` — what the portal is made of (wood, stone, rope, etc.)
- `on_traverse` — effects that fire when traversing (wind, light, sound)

---

## 3. Core Fields Explained

### Portal Metadata: `portal` Table

```lua
portal = {
    target = "hallway",                            -- Required: destination room ID
    bidirectional_id = "{4bb381ad-2c9d-4926-...}", -- Optional: links to paired portal
    direction_hint = "north",                      -- Required: direction keyword
}
```

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `target` | string | YES | Destination room ID. The engine looks up this room in the context to determine where the player moves. |
| `bidirectional_id` | string | NO | If set and identical on another portal, the FSM engine will sync state changes between the pair. Use the same GUID on both sides of a bidirectional passage. |
| `direction_hint` | string | YES | Direction keyword for movement commands and parser matching. `"north"`, `"south"`, `"up"`, `"down"`, `"northwest"`, `"in"`, `"out"`, etc. |

### FSM State Declaration

Every portal declares which states are traversable:

```lua
states = {
    open = {
        traversable = true,
        name = "an open oak door",
        description = "The oak door stands open.",
        on_feel = "Cool air drifts through the doorway.",
    },
    closed = {
        traversable = false,
        name = "a closed oak door",
        description = "The door is shut.",
        on_feel = "Solid oak, with no give.",
        blocked_message = "The door is closed.",
    },
    locked = {
        traversable = false,
        blocked_message = "The door is locked.",
    },
}
```

**Key rule:** A state with `traversable = false` **blocks movement**. The engine checks this flag before allowing traversal. If `traversable = true`, the player can move through. If missing or `false`, the player cannot.

### Sensory Properties (Per State)

Each state can have its own sensory descriptions. The engine updates these when the state changes:

```lua
states = {
    open = {
        traversable = true,
        on_feel = "Cool air drifts through the doorway.",
        on_smell = "Dust and old stone.",
        on_listen = "The sound of wind in the corridor.",
    },
    closed = {
        traversable = false,
        on_feel = "Solid oak, unyielding.",
        on_smell = "Old oak wood.",
        on_listen = "No sound from beyond.",
    },
}
```

**Required per Principle 6:** Every portal must have `on_feel` (primary dark sense) in at least its initial state. The player might be in darkness, so tactile feedback is essential.

### FSM Transitions

Transitions define how the portal changes state and what happens when it does:

```lua
transitions = {
    {
        from = "closed",
        to = "open",
        verb = "open",
        aliases = {"push", "swing"},
        message = "You push the door open. It swings inward on groaning hinges.",
    },
    {
        from = "open",
        to = "closed",
        verb = "close",
        aliases = {"shut"},
        message = "You push the door closed. It closes with a thud.",
    },
    {
        from = "closed",
        to = "broken",
        verb = "break",
        requires_strength = 3,
        message = "You slam into the door with all your strength. It splinters!",
        spawns = {"wood-splinters"},
    },
}
```

**Transition fields:**

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `from` | string | YES | Current state (must exist in `states` table) |
| `to` | string | YES | Next state (must exist in `states` table) |
| `verb` | string | YES | Primary verb that triggers this transition (`"open"`, `"break"`, `"unbar"`) |
| `aliases` | table | NO | Alternative verbs (`{"push", "swing"}`) |
| `message` | string | NO | Message printed when transition fires |
| `requires_strength` | number | NO | Strength tier required (1–5; player must have sufficient strength capability) |
| `requires_tool` | table | NO | Tools that can trigger this transition |
| `spawns` | table | NO | Item IDs to create in the room when transition fires |
| `trigger` | string | NO | Custom event name (for other systems to detect) |

---

## 4. Passage Constraints

Optionally define size/weight limits:

```lua
max_carry_size = 4,        -- Size tier 1–6; player can't carry larger items through
max_carry_weight = 50,     -- Weight limit in game units
player_max_size = 5,       -- Player/creature size tier; creature can't fit if larger
requires_hands_free = true, -- Player must carry items in containers, not hands
```

**Currently informational** — the engine doesn't enforce these yet. Future `src/engine/traversal/init.lua` will validate before allowing traversal. For now, include them for completeness.

### Size Tier Reference

| Tier | Label | Examples |
|------|-------|----------|
| 1 | Tiny | Key, coin, ring, pin |
| 2 | Small | Book, dagger, potion, sack |
| 3 | Medium | Sword, shield, lantern, stool |
| 4 | Large | Chair, chest, barrel, lamp |
| 5 | Huge | Bed, wardrobe, desk |
| 6 | Massive | Piano, statue, cart |

A door with `max_carry_size = 4` allows carrying chairs and chests through, but not beds or wardrobes.

---

## 5. Complete Example: Simple Open Door

**File:** `src/meta/objects/hallway-kitchen-door-east.lua`

```lua
return {
    guid = "{a1b2c3d4-e5f6-47a8-b9c0-d1e2f3a4b5c6}",
    template = "portal",
    
    id = "hallway-kitchen-door-east",
    name = "a wooden door",
    keywords = {"door", "wooden door", "hallway door", "kitchen door", "way east"},
    material = "oak",
    
    portal = {
        target = "kitchen",
        bidirectional_id = "{kitchen-hallway-pair-id}",
        direction_hint = "east",
    },
    
    max_carry_size = 4,
    max_carry_weight = 50,
    player_max_size = 5,
    
    -- Simple open/close FSM
    initial_state = "open",
    _state = "open",
    
    states = {
        open = {
            traversable = true,
            name = "an open wooden door",
            description = "A wooden door stands open to the east.",
            on_feel = "Wooden frame, worn smooth from years of use.",
            on_smell = "Old wood and the faint aroma of cooking.",
            on_listen = "Distant sounds from the kitchen.",
        },
        closed = {
            traversable = false,
            name = "a closed wooden door",
            description = "A wooden door is closed.",
            on_feel = "Solid oak.",
            on_smell = "Wood.",
            on_listen = "Muffled sounds from beyond.",
            blocked_message = "The door is closed.",
        },
    },
    
    transitions = {
        {
            from = "open",
            to = "closed",
            verb = "close",
            aliases = {"shut"},
            message = "You close the door behind you.",
        },
        {
            from = "closed",
            to = "open",
            verb = "open",
            aliases = {"push"},
            message = "You open the door.",
        },
    },
}
```

---

## 6. Complex Example: Multi-State Door (Bedroom-Hallway)

**File:** `src/meta/objects/bedroom-hallway-door-north.lua`

A 4-state door with asymmetric sensory descriptions (barred on one side):

```lua
return {
    guid = "{25852832-6f19-48af-a118-20350ac8d243}",
    template = "portal",
    
    id = "bedroom-hallway-door-north",
    name = "a heavy oak door",
    keywords = {"door", "heavy door", "oak door", "heavy oak door", "barred door", "iron bands"},
    material = "oak",
    
    portal = {
        target = "hallway",
        bidirectional_id = "{4bb381ad-2c9d-4926-8ebc-e55d8e48f4c4}",
        direction_hint = "north",
    },
    
    max_carry_size = 4,
    max_carry_weight = 50,
    player_max_size = 5,
    
    -- 4-state FSM: barred → unbarred → open, or barred → broken
    initial_state = "barred",
    _state = "barred",
    
    states = {
        barred = {
            traversable = false,
            name = "a heavy oak door",
            description = "A heavy oak door with iron bands. It appears to be barred from the other side.",
            on_examine = "Thick oak planks bound by iron bands. No keyhole on this side.",
            on_feel = "Rough oak grain, cold iron bands. Solid — no give when you push.",
            on_smell = "Old oak and iron. Staleness from the corridor beyond.",
            on_listen = "The faint creak of the iron bar shifting in its brackets.",
            on_knock = "A deep, dull thud. No one answers.",
            on_push = "The door doesn't budge. The iron bar holds from the other side.",
            blocked_message = "The door is barred from the other side.",
        },
        
        unbarred = {
            traversable = false,
            name = "an unbarred oak door",
            description = "The heavy oak door stands unbarred, closed.",
            on_feel = "The door shifts slightly in its frame. No longer held.",
            on_listen = "A faint draught whistles through the gap.",
            on_push = "The door is ready to open. Push harder.",
            blocked_message = "The door is closed.",
        },
        
        open = {
            traversable = true,
            name = "an open oak door",
            description = "The heavy oak door stands open, revealing a dim corridor beyond.",
            on_feel = "The open door edge, worn smooth. Cool corridor air drifts through.",
            on_listen = "The corridor beyond: distant dripping, the settling of old stone.",
        },
        
        broken = {
            traversable = true,
            name = "a splintered doorframe",
            description = "Where the oak door once stood, only splintered wood and twisted hinges remain.",
            on_feel = "Jagged splinters and bent iron. Mind your fingers.",
            on_listen = "The corridor beyond is fully exposed.",
        },
    },
    
    transitions = {
        {
            from = "barred",
            to = "unbarred",
            verb = "unbar",
            trigger = "exit_unbarred",
            message = "You hear scraping iron as the bar is lifted from the other side.",
        },
        {
            from = "unbarred",
            to = "open",
            verb = "open",
            aliases = {"push"},
            message = "You push the door open. It swings inward on groaning hinges.",
        },
        {
            from = "open",
            to = "unbarred",
            verb = "close",
            aliases = {"shut"},
            message = "You close the door.",
        },
        {
            from = "barred",
            to = "broken",
            verb = "break",
            requires_strength = 3,
            message = "You slam into the door with all your might. The oak cracks and splinters!",
            spawns = {"wood-splinters"},
        },
    },
    
    -- Optional: effects that fire when traversing
    on_traverse = {
        wind_effect = {
            strength = "draught",
            extinguishes = { "candle" },
            message_extinguish = "As you step through, a cold draught snuffs your candle.",
            message_spared = "A cold draught funnels through the doorway.",
        },
    },
    
    mutations = {},
}
```

### Paired Portal (Hallway Side)

**File:** `src/meta/objects/bedroom-hallway-door-south.lua`

Same `bidirectional_id` ensures FSM sync:

```lua
return {
    guid = "{87f65432-1a0b-9c8d-7e6f-5a4b3c2d1e0f}",
    template = "portal",
    
    id = "bedroom-hallway-door-south",
    name = "a heavy oak door",
    keywords = {"door", "heavy door", "oak door", "barred door"},
    material = "oak",
    
    portal = {
        target = "start-room",
        bidirectional_id = "{4bb381ad-2c9d-4926-8ebc-e55d8e48f4c4}",  -- Same as north side
        direction_hint = "south",
    },
    
    max_carry_size = 4,
    max_carry_weight = 50,
    player_max_size = 5,
    
    initial_state = "barred",
    _state = "barred",
    
    -- Hallway perspective: see iron bar brackets instead of having the bar on you
    states = {
        barred = {
            traversable = false,
            description = "A heavy oak door with iron brackets. A thick bar rests in the brackets, barring passage.",
            on_feel = "Iron brackets, cold and secure. A heavy bar blocks passage.",
            on_listen = "Silence from beyond. The weight of the bar settling.",
        },
        unbarred = {
            traversable = false,
            description = "The door stands closed. The bar has been lifted from the brackets.",
            on_feel = "The door is free now.",
            on_listen = "Faint breathing sounds from beyond.",
        },
        open = {
            traversable = true,
            description = "The heavy oak door stands open.",
            on_feel = "The open door frame.",
            on_listen = "Sounds from the bedroom.",
        },
        broken = {
            traversable = true,
            description = "The doorway gapes open — the door has been destroyed.",
            on_feel = "Jagged splinters.",
        },
    },
    
    transitions = {
        -- Same transitions; FSM engine will sync state across bidirectional_id
        {
            from = "barred",
            to = "unbarred",
            verb = "unbar",
            message = "You lift the heavy iron bar from its brackets.",
        },
        {
            from = "unbarred",
            to = "open",
            verb = "open",
            message = "You pull the door open.",
        },
        {
            from = "open",
            to = "unbarred",
            verb = "close",
            message = "You close the door.",
        },
        {
            from = "barred",
            to = "broken",
            verb = "break",
            requires_strength = 3,
            message = "You slam into the door and break through!",
            spawns = {"wood-splinters"},
        },
    },
}
```

**Note:** When either portal transitions, the FSM engine finds the paired portal (same `bidirectional_id`) and applies the same state change. No manual sync needed in verb handlers.

---

## 7. Special Case: One-Way Portals

A portal that only appears from one side (e.g., drop-down from a balcony):

```lua
-- In room "balcony":
exits = {
    down = { portal = "balcony-garden-drop" }
}

-- balcony-garden-drop.lua
portal = {
    target = "garden",
    direction_hint = "down",
    bidirectional_id = nil,  -- Not paired; one-way only
}

-- In room "garden": 
-- Simply DON'T declare an "up" exit back to balcony
-- This is implicit: one-way passages have exits from only one side
```

---

## 8. Always-Blocked Portal (Boundary)

A portal that represents an impassable boundary (currently always locked/barred):

```lua
-- vault-door.lua
initial_state = "sealed",
_state = "sealed",

states = {
    sealed = {
        traversable = false,
        description = "An impenetrable vault door of solid steel.",
        blocked_message = "The vault is sealed. You cannot enter.",
    },
},

transitions = {
    -- Currently no transitions; permanently impassable
    -- Future: add a multi-key unlock puzzle here
}
```

No `portal.target` needed (engine won't try to traverse anyway). This is useful for representing locked areas that become accessible later via puzzle solutions.

---

## 9. Portal in Room Definition

Portals are instantiated in a room's `instances` list and referenced from `exits`:

```lua
-- start-room.lua
return {
    id = "start-room",
    name = "The Bedroom",
    description = "...",  -- permanent features only
    
    instances = {
        { id = "bed", type_id = "{...}" },
        { id = "nightstand", type_id = "{...}" },
        { id = "bedroom-hallway-door-north", type_id = "{25852832-6f19-48af-a118-20350ac8d243}" },
        { id = "bedroom-courtyard-window-out", type_id = "{...}" },
        { id = "bedroom-cellar-trapdoor-down", type_id = "{...}" },
    },
    
    exits = {
        north = { portal = "bedroom-hallway-door-north" },
        window = { portal = "bedroom-courtyard-window-out" },
        down = { portal = "bedroom-cellar-trapdoor-down" },
    },
}
```

**Important:**
- Portal instance must exist in `instances` for the room loader to initialize it.
- Exit reference uses the instance `id` (e.g., `"bedroom-hallway-door-north"`), not the type_id.
- The engine resolves the reference at movement time via registry lookup.

---

## 10. Required vs. Optional Fields

### Every Portal MUST Have

- `guid` — unique Windows GUID
- `template = "portal"` — inherits from portal template
- `id` — unique object ID
- `portal.target` — destination room ID (or nil for blocked portals)
- `portal.direction_hint` — direction keyword
- `name` — display name
- `description` — default description
- `on_feel` — required per Principle 6 (tactile sense)
- `states` — at least an initial state
- `initial_state` — must match a key in `states`

### Portal Should Have

- `keywords` — searchable keywords for parser
- `on_examine` — detailed inspection
- `on_smell`, `on_listen`, `on_taste` — sensory depth
- `transitions` — most portals change state
- `max_carry_size`, `max_carry_weight` — document constraints

### Portal May Have

- `portal.bidirectional_id` — if paired with another portal
- `on_traverse` — effects when passing through
- `player_max_size` — if size-restricted
- `requires_hands_free` — if climbs/requires free hands
- `material` — for detail
- `mutations` — rare (FSM transitions preferred)

---

## 11. Creating a New Portal: Checklist

**Step 1: Generate GUIDs**
- Portal GUID (Windows GUID format)
- Bidirectional ID (if paired) — same GUID on both sides

**Step 2: Choose States and Transitions**
- What are the valid states? (e.g., open, closed, locked, broken)
- Which states allow traversal? Mark with `traversable = true`
- What verbs transition between states? (open, close, break, unbar)

**Step 3: Define Sensory Properties**
- `name` — what is it called?
- `description` — what does it look like? (different per state)
- `on_feel`, `on_smell`, `on_listen`, `on_taste` (at least feel)
- `on_examine`, `on_knock`, `on_push`, `on_pull` (if interactable)

**Step 4: Document Constraints** (even if engine doesn't validate yet)
- `max_carry_size` — what items fit?
- `max_carry_weight` — how heavy?
- `player_max_size` — do only small creatures fit?

**Step 5: Create Portal Files**
- `src/meta/objects/{id}.lua` — create the portal object file
- If paired: `src/meta/objects/{id}-paired}.lua` with matching `bidirectional_id`

**Step 6: Room Integration**
- Add portal instance to room's `instances` list
- Add exit reference to room's `exits` table: `direction = { portal = "object-id" }`
- Ensure destination room exists

**Step 7: Test**
- `look` — verify portal appears in room
- `[verb]` — verify transitions work
- Traversal: verify movement works and opposite portal syncs (if bidirectional)

---

## 12. Related Documentation

- **Room Exit Architecture** — `../rooms/room-exits.md` (how portals fit into movement)
- **Core Principles** — `core-principles.md` (Principle 6: sensory depth, Principle 8: engine executes metadata)
- **FSM Lifecycle** — `../engine/fsm-object-lifecycle.md` (how FSM transitions work)
- **Verb System** — `../../design/verb-system.md` (portal verbs: open, close, break, etc.)

---

*This pattern document is the canonical reference for creating portal objects. When in doubt, refer to the example implementations in `src/meta/objects/` — they demonstrate all major patterns.*
