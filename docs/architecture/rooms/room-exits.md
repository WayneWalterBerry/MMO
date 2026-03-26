# Room Exit Architecture — Portal Objects

**Author:** Brockman (Documentation)  
**Date:** 2026-03-26  
**Status:** Current — reflects Phase 2 implementation  
**Related:** `../objects/portal-pattern.md`, `dynamic-room-descriptions.md`, `../../design/verb-system.md`

---

## 1. Overview

**As of Phase 2, all exits are portal objects.** The system moved from inline exit definitions to first-class portal objects with FSM state machines. This enables complex passage behavior (locked doors, barred gates, broken windows) through reusable portal semantics rather than special-case logic.

**Key principle:** Portals are **traversable passages** defined as `.lua` files in `src/meta/objects/` and referenced from rooms via thin `{ portal = "object-id" }` exit entries. They inherit from `portal.lua` template and declare their traversal rules via FSM `traversable` flags on each state.

---

## 2. How Exits Are Defined Now: Thin References

Room exit tables contain **thin portal references**:

```lua
-- In start-room.lua
exits = {
    north = { portal = "bedroom-hallway-door-north" },
    window = { portal = "bedroom-courtyard-window-out" },
    down = { portal = "bedroom-cellar-trapdoor-down" },
}
```

Each value is a table with a single `portal` key pointing to a registered object ID. The engine resolves this reference at runtime by looking up the object in the registry.

**Why thin references?** They keep room files readable and immutable. The portal object lives in its own `.lua` file and can be mutated independently. Room files don't need rewriting every time a portal changes state.

---

## 3. Movement Resolution Path

When a player types a direction command:

1. **Direction normalization** → `north`, `south`, `up`, `down`, etc.
2. **Exit lookup** → fetch `room.exits[direction]`
3. **Portal reference resolution** → if `exit.portal` exists, look up the portal object from the registry
4. **State check** → read portal's `_state` and check the FSM state's `traversable` flag
5. **Traversal** → if `traversable = true`, move player; otherwise print blocked message

### Code Example (from `src/engine/verbs/movement.lua`):

```lua
-- Thin reference resolution
if exit and type(exit) == "table" and exit.portal then
    portal_obj = ctx.registry:get(exit.portal)
end

-- State check for traversability
if portal_obj and portal_obj.portal then
    local state = portal_obj.states and portal_obj.states[portal_obj._state]
    if not state or not state.traversable then
        print((portal_obj.name or "The way") .. " blocks your path.")
        return
    end
    -- Proceed to traverse
    local target_id = portal_obj.portal.target
    ...
end
```

---

## 4. Portal Object Structure

Each portal is a complete object inheriting from `src/meta/templates/portal.lua`:

```lua
return {
    guid = "{unique-guid}",
    template = "portal",
    
    -- Object identity
    id = "bedroom-hallway-door-north",
    name = "a heavy oak door",
    keywords = {"door", "oak door", "heavy oak door"},
    
    -- Portal metadata (engine-executed per Principle 8)
    portal = {
        target = "hallway",                    -- destination room ID
        bidirectional_id = "{shared-guid}",   -- links to paired portal
        direction_hint = "north",              -- for movement resolution
    },
    
    -- Passage constraints
    max_carry_size = 4,      -- largest carried item that fits
    max_carry_weight = 50,   -- heaviest single item allowed
    player_max_size = 5,     -- largest player size that fits (optional)
    
    -- FSM: defines all valid states and traversability
    initial_state = "barred",
    _state = "barred",
    
    states = {
        barred = {
            traversable = false,
            description = "The door is barred from the other side.",
            on_feel = "Rough oak, cold iron. Solid — no give.",
        },
        unbarred = {
            traversable = false,
            description = "The door is unbarred but closed.",
            on_feel = "The door shifts slightly in its frame.",
        },
        open = {
            traversable = true,
            description = "The door stands open.",
            on_feel = "Cool air drifts through the doorway.",
        },
        broken = {
            traversable = true,
            description = "The door is destroyed.",
            on_feel = "Jagged splinters and bent iron.",
        },
    },
    
    transitions = {
        { from = "barred", to = "unbarred", verb = "unbar" },
        { from = "unbarred", to = "open", verb = "open", aliases = {"push"} },
        { from = "open", to = "unbarred", verb = "close" },
        { from = "barred", to = "broken", verb = "break" },
    },
    
    -- Sensory properties (required per Principle 6)
    on_feel = "Rough oak grain under your fingers, cold iron bands.",
    on_smell = "Old oak and iron.",
    on_listen = "Silence from beyond.",
    on_taste = "Dry, gritty wood grain.",
    
    -- Passage-specific effects (optional)
    on_traverse = {
        wind_effect = {
            strength = "draught",
            extinguishes = { "candle" },
            message_extinguish = "A cold draught snuffs your candle flame.",
        },
    },
    
    mutations = {},
}
```

### Key Fields

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `portal.target` | string | Destination room ID | `"hallway"` |
| `portal.bidirectional_id` | string | Shared ID for paired portal | `"{4bb381ad-...}"` |
| `portal.direction_hint` | string | Direction for movement parsing | `"north"` |
| `max_carry_size` | number | Size tier limit for carried items | `4` (Large items fit; Huge don't) |
| `max_carry_weight` | number | Weight limit in game units | `50` |
| `traversable` (state field) | boolean | Can player move through this state? | `true` or `false` |

---

## 5. Bidirectional Portal Sync

Portals can be paired bidirectionally via `bidirectional_id`. When a paired portal is created correctly:

```lua
-- bedroom-hallway-door-north.lua
portal = {
    target = "hallway",
    bidirectional_id = "{4bb381ad-2c9d-4926-8ebc-e55d8e48f4c4}",
    direction_hint = "north",
}

-- hallway.lua→bedroom-hallway-door-south.lua
portal = {
    target = "start-room",
    bidirectional_id = "{4bb381ad-2c9d-4926-8ebc-e55d8e48f4c4}",
    direction_hint = "south",
}
```

**Engine behavior (D-PORTAL-BIDIR-SYNC):**  
When an FSM transition completes on one portal, the FSM engine automatically finds its paired portal (via `bidirectional_id`) in the registry and applies the same state change. This ensures breaking a door from either side keeps both sides in sync.

**No verb handler involvement needed.** The FSM handles sync automatically. This is pure Principle 8 compliance: engine executes metadata.

---

## 6. Portal States and Traversability

Each portal declares all its valid states and explicitly marks which are traversable:

```lua
states = {
    locked = {
        traversable = false,
        blocked_message = "The door is locked.",
        description = "A heavy oak door, locked tight.",
    },
    open = {
        traversable = true,
        description = "The door stands open.",
    },
    broken = {
        traversable = true,
        description = "Only splinters remain where the door stood.",
    },
}
```

When a player attempts to traverse, the engine checks:
1. Is the portal object's `_state` in the `states` table?
2. Does that state have `traversable = true`?
3. If no to either: print blocked message and prevent movement.

This replaces the old inline `open`, `locked`, `hidden` flags with a cleaner FSM model where all behavior is explicit in state definitions.

---

## 7. Example: The Bedroom-Hallway Door

The bedroom-hallway oak door demonstrates the complete pattern:

**File:** `src/meta/objects/bedroom-hallway-door-north.lua`

Key features:
- **4-state FSM:** barred → unbarred → open → broken (or barred → broken)
- **Asymmetric description:** bedroom side sees a bar; hallway side sees iron brackets
- **Bidirectional sync:** paired with `bedroom-hallway-door-south.lua` via shared `bidirectional_id`
- **Passage effects:** wind effect when traversing (can snuff candles)
- **Sensory richness:** on_feel, on_smell, on_listen, on_knock, on_push, on_pull all defined per state

**Room reference** (in `start-room.lua`):

```lua
instances = {
    { id = "bedroom-hallway-door-north", type_id = "{25852832-6f19-48af-a118-20350ac8d243}" },
},

exits = {
    north = { portal = "bedroom-hallway-door-north" },
}
```

**Traversal scenarios:**

| Scenario | Portal State | `traversable` | Result |
|----------|--------------|---------------|--------|
| Player tries `north` | `barred` | `false` | "The way is barred." |
| Player types `unbar` | Transition fires | → `unbarred` | Paired portal also transitions; state change persists |
| Player tries `north` again | `unbarred` | `false` | "The way is closed." |
| Player types `open` or `push` | Transition fires | → `open` | Player can now `north` through |
| Player enters and types `north` | `open` | `true` | Player moves to hallway; traverse effects fire |

---

## 8. Passage Constraints and Containment

Portals enforce size/weight constraints via `max_carry_size` and `max_carry_weight`. These are checked **before** traversal (validation left to verb handler or future `engine/traversal` module).

The constraints are **static** across all portal states. A door that's `open` has the same carrying limit as when it's `closed` — the doorway geometry doesn't change, only its traversability.

### Future: Traversal Validation Module

A dedicated `src/engine/traversal/init.lua` module (not yet implemented) will validate:
1. Player size fits through portal
2. Each carried item fits size/weight constraints
3. If portal requires hands-free, player can't carry items in hands

For now, constraint checking is stub/future work.

---

## 9. Portal Mutations and FSM Transitions

Portals use FSM transitions to change state, not object mutations. This is the key architectural difference from old-style objects:

```lua
transitions = {
    {
        from = "barred",
        to = "unbarred",
        verb = "unbar",
        trigger = "exit_unbarred",
        message = "You hear scraping iron as the bar is lifted from the other side.",
    },
    {
        from = "barred",
        to = "broken",
        verb = "break",
        requires_strength = 3,
        message = "You slam into the door with everything you have. The oak cracks and splinters.",
        spawns = {"wood-splinters"},
    },
}
```

FSM transitions can:
- Change portal state
- Emit messages
- Spawn items in the room
- Trigger effects
- Sync bidirectional portals

No object mutation happens (code rewrite). The portal object persists; only its `_state` changes in memory and gets persisted to save files.

---

## 10. Portal Template Defaults

The `portal.lua` template provides sensible defaults:

```lua
return {
    guid = "d902e90d-ec66-45df-8b93-a8dd35a6aaca",
    template = "portal",
    name = "a passage",
    keywords = {},
    description = "A passage between rooms.",
    
    size = 5,
    weight = 100,
    portable = false,
    material = "wood",
    
    portal = {
        target = nil,
        bidirectional_id = nil,
        direction_hint = nil,
    },
    
    max_carry_size = nil,    -- nil = no limit
    max_carry_weight = nil,
    
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
    on_smell = nil,
    on_listen = nil,
    
    container = false,
    capacity = 0,
    contents = {},
    location = nil,
    
    categories = {"portal"},
    mutations = {},
}
```

Instances override `portal.target`, `portal.bidirectional_id`, `portal.direction_hint`, and add custom states/transitions as needed.

---

## 11. How the Old Inline Exit System Differs

**Old (inline exits in rooms):**
```lua
exits = {
    north = {
        target = "hallway",
        open = true,
        locked = false,
        type = "door",
        description = "A heavy oak door...",
        mutations = { break = { ... } },
    }
}
```

**New (portal objects referenced):**
```lua
exits = {
    north = { portal = "bedroom-hallway-door-north" },
}

-- Portal object in src/meta/objects/bedroom-hallway-door-north.lua
-- FSM states with traversable flags instead of open/locked booleans
-- Bidirectional sync built into FSM engine
```

**Advantages of the new system:**
1. **Reusable:** Portal templates can be instantiated multiple times across the world
2. **Mutable via FSM:** State changes via transitions, not object rewrites
3. **Sensory richness:** Each portal state has independent sensory descriptions
4. **Bidirectional sync:** Engine-driven, not verb-handler-driven
5. **Room files simpler:** Exit tables are declarative, not prescriptive
6. **Principle 8 compliance:** Engine executes FSM metadata; no portal-specific verb handler logic needed

---

## 12. Room Integration Pattern

A room declares its exits as portal references:

```lua
-- src/meta/rooms/start-room.lua
return {
    id = "start-room",
    name = "The Bedroom",
    description = "...", -- permanent features only
    
    instances = {
        { id = "bed", type_id = "..." },
        { id = "bedroom-hallway-door-north", type_id = "{25852832-...}" },
    },
    
    exits = {
        north = { portal = "bedroom-hallway-door-north" },
        window = { portal = "bedroom-courtyard-window-out" },
        down = { portal = "bedroom-cellar-trapdoor-down" },
    },
}
```

The room's `instances` list includes all portal objects. They're loaded when the room is loaded, ensuring the registry has them available for movement resolution.

---

## 13. Future Considerations

1. **Traversal validation module** (`src/engine/traversal/init.lua`) — currently stub; will validate player/item size/weight constraints
2. **Dynamic exit lists** — currently computed from `room.exits`; future: might auto-generate from portal instances
3. **Portal descriptions in room output** — currently inline in `room.exits`; might migrate to portal object's `room_presence` field
4. **One-way portals** — portals can exist in one room without reciprocal in target room (intentional; supports one-way passages)
5. **Boundary portals** — portals that are always impassable or permanently blocked (future design)

---

## 14. Related Files

- **Template:** `src/meta/templates/portal.lua`
- **Example portals:** `src/meta/objects/bedroom-hallway-door-north.lua`, `bedroom-hallway-door-south.lua`, `bedroom-courtyard-window-out.lua`
- **Room file example:** `src/meta/rooms/start-room.lua`
- **Engine: movement handler** → `src/engine/verbs/movement.lua` (portal resolution, traversal)
- **Engine: FSM** → `src/engine/fsm/init.lua` (state transitions, bidirectional sync)
- **Documentation:** `portal-pattern.md` (how to create portals), `dynamic-room-descriptions.md` (room composition)
