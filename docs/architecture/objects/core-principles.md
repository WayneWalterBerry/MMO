# Core Architecture Principles

**Version:** 1.0  
**Last Updated:** 2026-03-22  
**Author:** Brockman (Documentation)  
**Purpose:** The 8 foundational principles that govern how the object system works.

---

## Overview

These eight principles form the bedrock of the MMO architecture. They define how objects are created, stored, modified, perceived, and related to each other in the game world. Every design decision in the engine traces back to one or more of these principles.

## Table of Contents

0. [Objects Are Inanimate](#0-objects-are-inanimate)
0.5. [Room .lua Files Use Deep Nesting](#05-room-lua-files-use-deep-nesting)
1. [Code-Derived Mutable Objects](#1-code-derived-mutable-objects)
2. [Base Objects → Object Instances](#2-base-objects--object-instances)
3. [Objects Have FSM; Instances Know Their State](#3-objects-have-fsm-instances-know-their-state)
4. [Composite Objects Encapsulate Inner Objects](#4-composite-objects-encapsulate-inner-objects)
5. [Multiple Instances Per Base Object; Each Instance Has a Unique GUID](#5-multiple-instances-per-base-object-each-instance-has-a-unique-guid)
6. [Objects Exist in Sensory Space; State Determines Perception](#6-objects-exist-in-sensory-space-state-determines-perception)
7. [Objects Exist in Spatial Relationships](#7-objects-exist-in-spatial-relationships)
8. [The Engine Executes Metadata; Objects Declare Behavior](#8-the-engine-executes-metadata-objects-declare-behavior)

---

## 0. Objects Are Inanimate

**The object system is designed exclusively for physical, inanimate things.** Furniture, tools, weapons, containers, consumables, and other environmental objects are the domain of the object system. **Living creatures — rats, guards, NPCs, animals — are NOT objects.**

### Why This Distinction Matters

Living creatures have fundamentally different requirements than inanimate objects:

- **Behavior Trees & AI:** Creatures need sophisticated decision-making, goal-driven behavior, and reactive intelligence. Objects are passive — they respond to external actions but do not independently pursue goals.
- **Pathfinding & Movement:** Creatures navigate space, avoid obstacles, and plan routes. Objects exist at a spatial location; they don't move on their own.
- **Dialogue & Communication:** Creatures interact with players through speech, memory of past encounters, and dynamic responses. Objects provide sensory information only.
- **Persistent Agency:** Creatures maintain internal state (hunger, fear, memory, goals). Objects reflect the state of the world (broken, lit, open, consumed).

### Design Consequence

When designing a game feature, ask: **"Is this alive?"** If yes, it's a future NPC/creature system. If no, it belongs in the object system.

**Examples:**
- ✅ A rat that scurries away → **Not an object.** This requires creature AI, pathing, and behavior trees. Defer to NPC system.
- ✅ A rat trap (the device) → **Is an object.** It's a container/tool that sits in space and has states (armed, sprung, empty).
- ✅ A candle → **Is an object.** It has states (lit, unlit, spent) and responds to player actions.
- ✅ A guard → **Not an object.** This requires dialogue, patrol routes, combat AI, and memory. Defer to NPC system.

### Future: NPC System

NPCs, creatures, and living things will eventually have their own architecture:
- **State Machines for AI:** Desire-driven state machines, goal hierarchies, or behavior trees
- **Pathfinding & Spatial Reasoning:** A* pathfinding, obstacle avoidance, territory mapping
- **Dialogue System:** Conversation trees, relationship tracking, dynamic responses
- **Creature Types:** Specific AI profiles for rats, guards, merchants, enemies, etc.

This is **not yet designed or architected**. Do not attempt to model living things using the object system as a workaround.

---

## 0.5. Room .lua Files Use Deep Nesting

**Room .lua files describe the physical space through deeply nested object instances.** Objects are placed inline using relationship keys that describe how they sit in the room.

### The Nesting Pattern

Each room file is a Lua table containing top-level objects with nested children. Nesting occurs via four relationship keys:

| Key | Meaning | Relationship | Example |
|-----|---------|--------------|---------|
| `on_top` | Items sitting on a surface | Object rests on parent's surface | Candle on nightstand |
| `contents` | Items inside a container | Object is inside parent's cavity | Matches in matchbox |
| `nested` | Objects in a physical slot (not "inside") | Object occupies parent's slot without being inside | Drawer in nightstand slot |
| `underneath` | Hidden items under parent | Object hidden until parent is moved/lifted | Brass key under rug |

### The Architectural Decision: Why Deep Nesting?

**The nesting IS the room's physical description.** By reading the Lua table's structure, you can visualize the room layout. This eliminates the need for separate room maps or spatial metadata — the code itself encodes topology.

**Example Room Structure:**
```lua
return {
    -- Nightstand: solid furniture with a drawer slot
    {
        id = "nightstand",
        type_id = "{guid-nightstand}",
        location = "room",
        on_top = {
            -- Candle holder sitting on nightstand surface
            {
                id = "candle-holder",
                type_id = "{guid-holder}",
                contents = {
                    -- Candle inside the holder
                    { id = "candle", type_id = "{guid-candle}" },
                },
            },
            -- Poison bottle also on nightstand
            { id = "poison-bottle", type_id = "{guid-poison}" },
        },
        nested = {
            -- Drawer is in the nightstand's slot (not "inside" it)
            {
                id = "drawer",
                type_id = "{guid-drawer}",
                state = "closed",
                contents = {
                    -- Matchbox inside the drawer
                    {
                        id = "matchbox",
                        type_id = "{guid-matchbox}",
                        state = "closed",
                        contents = {
                            { id = "match-1", type_id = "{guid-match}" },
                            { id = "match-2", type_id = "{guid-match}" },
                            -- ... more matches
                        },
                    },
                },
            },
        },
    },

    -- Rug: can have items hidden beneath it
    {
        id = "rug",
        type_id = "{guid-rug}",
        location = "room",
        underneath = {
            -- Brass key hidden under the rug
            { id = "brass-key", type_id = "{guid-key}" },
            -- Trap door hidden under the rug, not yet visible
            { id = "trap-door", type_id = "{guid-trap}", hidden = true },
        },
    },
}
```

### Key Rules

1. **Containers require `contents` key:** Only objects with a `contents` key can hold items. "Put X inside Y" fails if Y has no `contents`.
   - Nightstand has NO `contents` (it's solid furniture)
   - Drawer HAS `contents` (it can hold things)
   - "Put pillow inside drawer" → ✅ WORKS
   - "Put pillow inside nightstand" → ❌ FAILS

2. **`nested` is for physical slots:** Use `nested` when an object occupies a discrete slot in the parent, not thrown inside.
   - Drawer is in the nightstand's slot (a specific designed cavity)
   - Matches are in the matchbox's cavity (use `contents`)

3. **Each instance has identity:** Every nested object has:
   - `id` — a unique identifier within the room instance
   - `type_id` — a GUID reference to its object template/definition
   - Instance overrides (e.g., `state = "closed"`, `hidden = true`) live on the instance

4. **`underneath` items are hidden:** Items in the `underneath` key are not visible until the parent object is moved or lifted. Setting `hidden = true` on an underneath item makes it extra hidden (e.g., a trap door under a rug that looks like floor).

### Why This Pattern Matters

- **Self-Documenting:** The nested structure IS the room layout. Developers read the `.lua` file and visualize the scene.
- **Encapsulation:** Each container fully owns its contents; parent-child relationships are explicit.
- **Solves Surface Ambiguity:** Using `on_top`, `contents`, and `nested` explicitly clarifies how objects relate — no guessing.
- **Constraint Enforcement:** The engine can verify that only objects with `contents` receive PUT-INSIDE commands.
- **Composable:** Furniture can be designed as templates and instantiated multiple times with nested variations.

### Instance vs. Template

**Template (drawer.lua):**
```lua
return {
    id = "drawer",
    name = "a wooden drawer",
    is_container = true,
    -- No contents in template; contents vary per instance
}
```

**Room Instance (.../bedroom.lua):**
```lua
{
    id = "drawer-1",
    type_id = "{guid-drawer}",  -- References drawer.lua
    state = "closed",
    contents = {  -- Room instance defines what's IN this drawer
        { id = "matchbox", type_id = "{guid-matchbox}" },
    },
}
```

The template defines the object's behavior; the room instance defines what it contains and its state.

### Design Consequence

When building a room, ask:
- **Is this object on top of something?** Use `on_top`.
- **Is this object inside a container?** Use `contents`.
- **Is this object in a physical slot (drawer, cubby, pocket)?** Use `nested`.
- **Is this object hidden under something?** Use `underneath`.

Never mix relationships. Each parent has exactly one type of child relationship to its instances.

**Source:** Wayne (2026-03-21) — Approved deep nesting as the standard for room .lua files.

---



This engine operates on a fundamental architectural principle: **all game objects are mutable Lua tables derived from immutable source code**. Understanding this principle is essential to understanding how the entire system works.

### The Pattern: Code → Live Instances → Mutations

#### Load Phase
At startup, the engine reads all `.lua` object files from disk exactly once. For each object file (e.g., `src/meta/world/candle.lua`):

1. **Store as string:** The entire source code is stored in memory as a Lua string
2. **Parse into table:** The source string is parsed (via `load()`) into a live Lua table and registered in the object registry
3. **Ready for mutation:** The object is now a live, mutable data structure in RAM

Example:
```lua
-- candle.lua on disk
{
    id = "candle",
    name = "A tapered candle",
    provides_tool = "fire_source",
    mutations = { light = { becomes = "candle-lit", message = "..." } }
}

-- At runtime (after load phase):
-- registry["candle"] = { id="candle", name="...", mutations={...}, ... }
-- This live table is now ready to be mutated
```

#### Runtime Mutation: Two Strategies

When the engine mutates an object during gameplay, it employs two strategies:

**Strategy 1: Direct Table Mutation (FSM State Swap)**  
For transitions within the same state family (e.g., `candle` → `candle-lit`), the engine modifies the live table directly:
- Looks up the target state from the `mutations` table
- Applies new properties from the target state definition into the live table
- The registry entry is updated in-place; no reload needed
- Example: Lighting a candle swaps its `provides_tool` capability and message text

**Strategy 2: Code Re-parsing (`becomes` Mutation)**  
For terminal transitions or complex state changes, the engine re-parses source code into a fresh table:
- Retrieves the stored source string for the new state (e.g., `candle-lit.lua` source)
- Calls `load()` to parse the source into a new table
- Swaps the registry entry: old table removed, new table inserted
- All references to the object now point to the fresh definition
- Example: A candle transitioning to `candle-spent` (terminal state) gets a complete object definition swap

### The Key Insight

The engine is **always operating on objects that originated as .lua code**. The .lua files are the **source of truth** for what objects ARE. At runtime:

- The engine creates **living instances** from those source definitions
- It **mutates these instances freely** — they're just Lua tables in memory
- The mutations are **code-semantics** (swapping properties, changing FSM state), not flag-setting
- Objects can transition, transform, break, burn, and be consumed — all through table mutation and definition swapping

This is **not a static data-driven system**. It's a **code-derived mutable world**: source code defines the template, the engine creates living instances, and mutations reshape those instances during gameplay.

### Ephemeral State: The Current Design

All object mutations exist **in-memory only**. Restarting the game:
- Loads fresh `.lua` files from disk
- Creates new live instances from source
- Player progress is lost (unless explicitly persisted)

**Future Perspective:** The architecture does not preclude persistence (save/load to disk or cloud). However, that remains a future concern. The current principle is: **objects are temporary instances derived from eternal source code**. When you quit, you dissolve back to the source.

### Why This Matters

1. **Flexibility:** Objects can transition through arbitrary FSM states without engine code changes
2. **Composability:** Complex behavior (multi-part objects, conditional transitions) is data, not hard-coded
3. **Debuggability:** Object state is always just a Lua table; inspect it at any point
4. **Extensibility:** New object types are .lua files + registry entries; no engine modifications needed
5. **Determinism:** Mutations are reproducible; the same source + same game history = same world state

---

## 2. Base Objects → Object Instances

The game world architecture is built on a two-tier object model: **immutable base objects** that define identity and **mutable instances** that hold runtime state.

### Base Objects (The Authored Layer)

Base objects are immutable templates that exist in the **source code**. Each base object:

- **Is an authored artifact:** Designed by game developers, stored as `.lua` files in `src/meta/objects/`
- **Has a unique GUID:** Enables future downloading from a web service and caching
- **Defines identity:** Answers the question "what is this thing?" (e.g., "this is a candle")
- **Is NOT mutable at runtime:** The `.lua` file is read once at load time and defines the permanent blueprint
- **Can inherit from other base objects:** Enables template hierarchies (e.g., `small-item` template → `candle` base object → `bedroom-candle` instance)

Example hierarchy:
```
Template (base): small-item
  ↓ (inherits from)
Base Object: candle
  ↓ (instance created at room load)
Instance: candle-1 (living table in registry)
```

### Object Instances (The Runtime Layer)

Object instances are **created at room load time** from base objects. Each instance:

- **Inherits everything from its base object:** Properties, capabilities, mutation definitions
- **IS mutable at runtime:** FSM state changes, property mutations, timer state, containment changes
- **Is a live Lua table in the registry:** A mutable data structure in memory
- **Is ephemeral:** Lives for the duration of the game session; destroyed on restart
- **Multiple instances can derive from the same base object:** The same candle base object can spawn many candle instances in a room (future work: instancing system)

Example at runtime:
```lua
-- Base object (immutable, source of truth)
base_candle = { id = "candle", name = "A tapered candle", provides_tool = "fire_source" }

-- Instance 1 (mutable, in registry)
bedroom_candle = { id = "candle", name = "A tapered candle", provides_tool = "fire_source", state = "lit" }

-- Instance 2 (mutable, in registry)
kitchen_candle = { id = "candle", name = "A tapered candle", provides_tool = "fire_source", state = "unlit" }
```

### The Principle

**The game world is composed of object instances derived from immutable base objects.** Base objects define identity (what something IS); instances hold state (what's happening to it RIGHT NOW). Base objects are authored artifacts with GUIDs for distribution; instances are ephemeral runtime entities created and destroyed as the player navigates the world.

### Why This Matters

1. **Clean separation of concerns:** Base objects are "what exists"; instances are "what is"
2. **Scalability:** Many instances can derive from few base objects (efficient memory use)
3. **Distribution:** Base objects with GUIDs can be downloaded from a web service and cached
4. **Inheritance flexibility:** Template hierarchies reduce duplication (a "small-item" template can be inherited by many base objects)
5. **Runtime mutation:** Instances can change freely without affecting the base object blueprint

---

## 3. Objects Have FSM; Instances Know Their State

Every object in the world is a **finite state machine (FSM)**. Base objects define the FSM blueprint—states, transitions, sensory descriptions per state, and timed events. Object instances track the current state. The engine is a **generic FSM executor**: it reads the FSM metadata from objects and executes state transitions without any object-specific code.

### The FSM Architecture

#### Base Objects: The FSM Blueprint

Base objects authored in `src/meta/objects/*.lua` define the complete FSM for a class of objects:

```lua
-- src/meta/objects/candle.lua (FSM blueprint)
return {
    id = "candle",
    name = "a tallow candle",
    description = "An unlit tallow candle",
    provides_tool = nil,
    casts_light = false,
    mutations = {
        light = {
            requires_tool = "fire_source",
            becomes = "candle-lit",
            message = "The candle flares to life."
        }
    }
}

-- src/meta/objects/candle-lit.lua (another FSM state)
return {
    id = "candle",
    name = "a tallow candle",
    description = "A lit tallow candle with a bright flame",
    provides_tool = "fire_source",
    casts_light = true,
    mutations = {
        extinguish = {
            becomes = "candle",
            message = "The flame gutters out."
        }
    }
}
```

Each state file defines:
- **Properties:** name, description, weight, capabilities (`provides_tool`, `casts_light`)
- **Sensory descriptions:** what the player sees (description), hears (on_listen), feels (on_feel)
- **Transitions:** the available state transitions as `mutations` (verb → next state)
- **Timed events:** ambient messages that fire on intervals (clock chimes, dripping water)

**The FSM is the authored, immutable part** — designed by game developers, stored in source code, and loaded once at startup.

#### Object Instances: The Needle on the Record

When a room loads, instances are created from base objects. Each instance has a `_state` field tracking the current FSM state:

```lua
-- At room load time:
instance_candle = {
    id = "candle",
    type_id = "992df7f3-...",
    location = "nightstand.top",
    _state = "candle",  -- <-- Which FSM state are we in?
    
    -- Runtime state (merged from current FSM state):
    name = "a tallow candle",
    description = "An unlit tallow candle",
    provides_tool = nil,
    casts_light = false,
    mutations = { light = { ... } }
}

-- After player lights the candle:
instance_candle._state = "candle-lit"
-- Properties updated from candle-lit state:
instance_candle.description = "A lit tallow candle..."
instance_candle.provides_tool = "fire_source"
instance_candle.casts_light = true
instance_candle.mutations = { extinguish = { ... } }
```

**The instance is the "needle on the record"** — the FSM defines the grooves (possible states and transitions), and the instance tracks which groove the needle is in right now.

### The Engine as Generic FSM Executor

The engine does NOT contain special-case code for individual object types. Instead:

1. **Player acts:** Types a command (e.g., "light the candle")
2. **Handler dispatches:** Verb handler routes to the object
3. **Engine reads FSM metadata:** Looks up `mutations.light` from the object's current state
4. **Engine checks prerequisites:** Confirms the player has a `fire_source` tool
5. **Engine executes transition:** Mutates the instance (swaps the `_state`, updates properties)
6. **Engine narrates:** Prints the transition message

No special-case objects. A candle with 2 states, a wall clock with 24 states, and a door with 2 states all work identically from the engine's perspective.

**Example: Generic LIGHT Handler**

```lua
verb.LIGHT = function(ctx, target, tool)
    -- 1. Resolve target object (generic, works for any lightable object)
    local obj = registry:get(target)
    
    -- 2. Check if current state has a "light" transition (generic FSM query)
    local transition = obj.mutations and obj.mutations.light
    if not transition then
        return false, target .. " can't be lit"
    end
    
    -- 3. Check prerequisites from the object's FSM metadata (generic)
    if transition.requires_tool then
        tool = inventory:find_by_capability(transition.requires_tool)
        if not tool then
            return false, "You need a " .. transition.requires_tool
        end
    end
    
    -- 4. Execute the transition (generic code rewrite)
    -- Mutate the instance: _state → next state, properties updated
    registry:mutate(target, transition.becomes)
    
    -- 5. Narrate (generic)
    print(transition.message)
    return true
end
```

### State Determines Everything

Everything about an object in a given moment is determined by its current FSM state:

- **What the player sees:** `description` (updated per state)
- **What the player feels:** `on_feel` handler (per state)
- **What the player hears:** `on_listen` handler and `timers` (per state)
- **Object capabilities:** `provides_tool`, `casts_light` (per state)
- **Available actions:** `mutations` table (per state) determines which verbs are valid
- **Ambient behavior:** `timers` array fires timed events (per state)

There are no flags like `is_lit = true` or `is_open = false`. **The entire object IS its current state.**

### Transitions: Verb-Driven and Timer-Driven

Transitions can be triggered two ways:

**Verb-driven:** Player action triggers a transition.
```lua
mutations.light = { becomes = "candle-lit", ... }
-- Player types "light candle" → handler finds mutations.light → executes
```

**Timer-driven:** Engine's timer system triggers a transition.
```lua
timers = {
    {
        name = "auto_close",
        interval = 30,
        recurring = false,
        on_fire = function(self)
            -- Auto-transition: door-open → door
            registry:mutate(self.id, "door")
            print("The door swings shut.")
        end
    }
}
```

Both use the same FSM mechanism. The engine is agnostic about whether a state change came from player action or an internal timer.

### Why This Matters

1. **Behavioral complexity without engine growth:** A candle that needs flint and steel to light, a door that locks itself after 1 minute, a clock that chimes on the hour — all work without engine changes. The complexity is **data** (FSM metadata), not code.

2. **Composability:** Objects can have arbitrary state counts. A light switch has 2 states. A staircase might have 4 (normal, flooded, collapsed, under repair). A puzzle box might have 16. The engine treats them all identically.

3. **Debuggability:** At any moment, the truth about an object is in its `_state` field and the properties merged from that state's definition. No hidden flags or state variables. Inspect the registry to see the whole truth.

4. **Determinism:** The same sequence of player actions, starting from the same world state, always produces the same results — because transitions are purely state-driven, not probabilistic.

5. **Extensibility:** New object types are new `.lua` files with FSM definitions. Zero engine changes needed.

---

## 4. Composite Objects Encapsulate Inner Objects

Complex game objects often consist of multiple components—a poison-bottle has a cork, a candle-holder has a candle, a nightstand has a drawer, a matchbox has matches. The architecture handles this through **composite objects**: a single `.lua` file that defines both the outer object and all its inner objects as nested Lua tables. Inner objects are not referenced by ID in separate files; they are defined **inline and encapsulated** in the parent object's file.

### Encapsulation Pattern: One File, Multiple Objects

A composite object is authored as a single `.lua` file containing:

1. **The outer object:** The main entity (e.g., `poison-bottle`)
2. **Inner object definitions:** Nested tables defining detachable components (e.g., the `cork`)

Example structure:

```lua
-- src/meta/objects/poison-bottle.lua (ONE file)
return {
    id = "poison-bottle",
    name = "a poison bottle",
    description = "A small glass bottle filled with iridescent liquid.",
    contains = {
        cork = {
            id = "cork",
            name = "a glass cork",
            description = "A small glass stopper.",
            type_id = "cork-guid",
            -- cork has its own base object definition, FSM states, mutations
            mutations = {
                insert = { becomes = "poison-bottle", message = "You stopper the bottle." }
            }
        }
    }
}
```

### Inner Objects Become Independent on Detachment

When an inner object is detached (e.g., the player removes the cork), the engine:

1. **Extracts the inner object** from the `contains` table
2. **Registers it as a live instance** with its own mutable state and FSM
3. **Gives it its own location** (e.g., on the floor, in inventory)
4. **It becomes a full object** — no longer "part of" the bottle, now a standalone entity

Example at runtime:

```lua
-- Before detachment:
bottle = { id = "poison-bottle", contains = { cork = { ... } } }

-- Player removes the cork:
-- Engine extracts inner object, registers it
bottle = { id = "poison-bottle", contains = {} }
cork = { id = "cork", location = "nightstand.floor", _state = "cork", ... }
```

### Why Encapsulation, Not Referential Composition

The architecture does **not** use referential composition (e.g., "this bottle references cork.lua by ID"). Instead:

- **All related objects are in one file** — authoring is streamlined. You design the bottle and its cork together.
- **No ID cross-references** — simplifies loading and prevents orphaned objects.
- **Inner objects have full definitions** — each inner object is a complete base object with its own GUID, FSM, mutations, and sensory descriptions.
- **Extraction is transparent** — when an inner object detaches, it's no different from any other object instance in the registry.

### Implemented Examples

- **`poison-bottle.lua`** → contains `cork` (removable)
- **`candle-holder.lua`** → contains `candle` (removable)
- **`nightstand.lua`** → contains `drawer` (removable, lockable)
- **`matchbox.lua`** → contains `matches` (consumable)

### Why This Matters

1. **Authoring clarity:** Complex objects are designed in one place. The bottle, its cork, and its cork's FSM all live in `poison-bottle.lua`.
2. **Composability:** Multi-part objects don't require engine changes or special cases. The registry and mutation system handle extraction naturally.
3. **Reusability:** Inner object definitions can be reused. Multiple bottles might contain the same cork definition.
4. **State encapsulation:** The inner object's mutable state (whether it's inserted, removed, broken) is tracked independently once extracted.
5. **Design ergonomics:** Developers think in terms of whole objects, not distributed ID references. Complex puzzles, containers, and multi-part tools are data, not code.

---

## 5. Multiple Instances Per Base Object; Each Instance Has a Unique GUID

The world often contains **many objects of the same type with independent state**. A matchbox holds 6 matches (all instances of the `match` base object). A bag contains 3 coins (all instances of the `coin` base object). A quiver holds 12 arrows. The architecture handles this through **instance multiplicity**: one base object definition can spawn many runtime instances, each with its own unique GUID, independent FSM state, mutation history, and timer state.

### The Problem: Multiple Identical Objects with Different States

Consider a matchbox. It contains 6 matches. Without instancing:

- **Approach A:** Create 6 separate base objects: `match-1.lua`, `match-2.lua`, ..., `match-6.lua` — duplicate definitions, not scalable.
- **Approach B:** Hard-code matchbox contents in object metadata — lacks flexibility, can't move matches independently, no true FSM state per match.

**Neither works.** The game needs a uniform, scalable system where one `match.lua` template produces many independent instances, each trackable and mutable.

### The Solution: Instance Multiplicity + GUIDs

When a room loads and contains a matchbox, the engine:

1. **Creates the matchbox instance** from `matchbox.lua` base object, assigns instance GUID (e.g., `9a3f2e1d-...`)
2. **Instantiates inner matches** from the `match.lua` base object **multiple times**, each with its own instance GUID:
   - Match #1: `instance_guid = "8f2a1b4c-..."`, `_state = "unlit"`
   - Match #2: `instance_guid = "7c9d3e2f-..."`, `_state = "unlit"`
   - Match #3: `instance_guid = "6b4e1a9d-..."`, `_state = "lit"`
   - Match #4: `instance_guid = "5a3d8c2e-..."`, `_state = "spent"`
   - Match #5: `instance_guid = "4f9b2d1e-..."`, `_state = "unlit"`
   - Match #6: `instance_guid = "3e8a7c9d-..."`, `_state = "unlit"`

Each match:
- Derives from the same `match` base object definition
- Has its own **instance GUID** (runtime identifier, not the base object GUID)
- Tracks its own **FSM state** (`_state`)
- Can have its own **timers** (a lit match has a burn timer; spent match has none)
- Can be manipulated independently (remove match #3, keep the others)

### Instance GUID vs Base Object GUID

**Base Object GUID:** The identifier for the source template.
- Example: `match` base object GUID = `550e8400-e29b-41d4-a716-446655440000`
- Stored in source code: `return { id = "match", type_id = "550e8400-...", ... }`
- Used for: Distribution, caching, version tracking
- **Not** used for runtime disambiguation

**Instance GUID:** The runtime identifier assigned when an instance is created.
- Example: Match #3 instance GUID = `6b4e1a9d-88f2-4c7a-9b1e-2a3d4e5f6g7h`
- Generated at room load time: `registry:create_instance("match", parent_id, position)`
- Used for: Querying, referencing, disambiguating multiple instances
- The engine uses instance GUIDs to answer: "Which specific match do you mean?"

### Player-Facing Disambiguation

When the player types "get match" and there are 6 matches in the matchbox, the parser must disambiguate. The system provides multiple layers:

1. **Sensory description per state:** "a lit match" vs "a spent match" — the engine can distinguish matches by their state.
2. **Ordinal reference:** "get the third match" or "get the first unlit match"
3. **Adjective-based selection:** "get the burning match" (FSM state = `lit`) vs "get the fresh match" (FSM state = `unlit`)
4. **Instance GUID as last resort:** If ambiguity persists, the engine internally uses instance GUID to track which specific object was referenced.

Example:
```
> get match
Which match do you mean?
  1. a lit match
  2. a spent match
  3. an unlit match
  ...
```

Or, with smarter parsing:
```
> get lit match
You take the lit match.
```

### Container Scalability Pattern

The instancing system enables containers of arbitrary size:

- **Matchbox:** Contains 6 match instances, all `match` base object
- **Coin purse:** Contains 15 coin instances, all `coin` base object
- **Quiver:** Contains 12 arrow instances, all `arrow` base object
- **Treasure chest:** Contains 50 item instances of mixed types (coins, gems, rings, scrolls)

Containers are defined as composite objects (Principle 4) with `contains` fields. The inner objects can be instantiated multiple times:

```lua
-- src/meta/objects/matchbox.lua
return {
    id = "matchbox",
    name = "a wooden matchbox",
    description = "A small box filled with wooden matches.",
    contains = {
        matches = {
            {
                id = "match",
                name = "a match",
                type_id = "match-guid",
                _state = "unlit"
            },
            {
                id = "match",
                name = "a match",
                type_id = "match-guid",
                _state = "unlit"
            },
            {
                id = "match",
                name = "a match",
                type_id = "match-guid",
                _state = "lit"
            },
            -- ... up to 6 matches
        }
    }
}
```

At runtime, each match gets its own instance GUID. The engine tracks the array index and instance GUID. When a match is extracted, it's removed from the `contains` array and registered as a standalone object in the registry.

### Independent State & Timers

Each instance maintains its own mutable state:

```lua
-- Match #3 (instance GUID: 6b4e1a9d-...)
match_instance_3 = {
    id = "match",
    type_id = "550e8400-...",
    instance_guid = "6b4e1a9d-...",
    location = "matchbox-9a3f2e1d-...",
    _state = "lit",
    description = "A lit match with a bright flame",
    provides_tool = "fire_source",
    casts_light = true,
    timers = {
        {
            name = "burn_out",
            interval = 120,     -- Burns for 120 ticks
            recurring = false,
            on_fire = function(self)
                registry:mutate(self.instance_guid, "match-spent")
            end
        }
    }
}

-- Match #4 (instance GUID: 5a3d8c2e-...)
match_instance_4 = {
    id = "match",
    type_id = "550e8400-...",
    instance_guid = "5a3d8c2e-...",
    location = "matchbox-9a3f2e1d-...",
    _state = "spent",
    description = "A spent match, blackened and useless",
    provides_tool = nil,
    casts_light = false,
    timers = {}     -- No timers; it's already spent
}
```

Lighting match #3 does **not** affect match #4. Timer events are instance-specific. Each instance ticks independently.

### The Generic Instancing Algorithm

When a composite object with multiple inner instances is loaded:

1. **Parse the composite object** (e.g., `matchbox.lua`)
2. **Iterate the `contains` array** (or nested table of instances)
3. **For each inner instance:**
   - Assign a unique instance GUID: `uuid.generate()`
   - Record the parent relationship: `instance.parent_id = matchbox_guid`
   - Record position/index: `instance.location = matchbox_guid` (inside container)
   - Register in the object registry under instance GUID
   - Initialize FSM state from `_state` field
   - Initialize timers from `timers` array

4. **Store parent-child relationship** in a mapping table:
   ```lua
   registry.containment[matchbox_guid] = {
       [1] = { instance_guid = "8f2a1b4c-...", object_id = "match" },
       [2] = { instance_guid = "7c9d3e2f-...", object_id = "match" },
       ...
   }
   ```

5. **On extraction** (player removes a match):
   - Remove from parent's `contains` array
   - Update instance location: `instance.location = player.location`
   - Update containment mapping: remove from parent, add to player inventory

### Why This Matters

1. **Scalability:** A matchbox can hold 1, 6, 100, or 1000 matches — all instances of the same base object. The engine scales linearly.
2. **Memory efficiency:** One `match.lua` definition serves many instances. No code duplication.
3. **State independence:** Each match's FSM state, timers, and properties are independent. Lighting one doesn't burn all.
4. **Player agency:** Players can pick individual matches, move them between containers, light some and leave others. The engine tracks every instance.
5. **Design flexibility:** Containers (bags, boxes, quivers, chests) are generic. The instancing system handles any multiplicity.
6. **Debugging clarity:** Every instance has a GUID. The engine can log: "Match instance 6b4e1a9d-... transitioned from lit → spent at tick 450."

---

## 6. Objects Exist in Sensory Space; State Determines Perception

Every object in the world is **perceivable through multiple senses**. When the player interacts with an object, the engine doesn't say "you can't perceive that" — it says "**here's what you perceive given this sense and this object's current state.**" The fundamental insight is that **FSM state drives sensory output**. The same candle in the `lit` state and `unlit` state return entirely different sensory descriptions across all channels: sight, touch, sound, and smell.

### The Multi-Sensory Model

The engine supports five primary perception verbs, each querying the object's current state:

- **LOOK / EXAMINE** — Visual description: "What does this look like?"
- **FEEL** — Tactile description: "What does this feel like when touched?"
- **SMELL** — Olfactory description: "What odor does this emit?"
- **LISTEN** — Auditory description: "What sound does this make?"
- **TASTE** — Gustatory description (for edibles/drinkables): "What flavor is this?"

Each verb maps to a sensory key in the object's FSM state metadata. The engine reads the state-specific sensory data and returns it to the player. There is no hard-coded "fire smells" logic — the candle's `lit` state **declares** its smell.

### State-Driven Sensory Descriptions

Each FSM state can override sensory descriptions. A candle provides the clearest example:

**Unlit candle (`candle-unlit` state):**
```lua
_state = "unlit",
description = "A white tapered candle, unlit.",
on_feel = "The wax is cool and hardened, smooth to the touch.",
on_smell = "A faint trace of old smoke clings to the wick.",
on_listen = nil,  -- No sound
on_taste = nil,   -- Not edible
room_presence = "An unlit candle rests on the nightstand."
```

**Lit candle (`candle-lit` state):**
```lua
_state = "lit",
description = "A candle burns brightly, flame dancing.",
on_feel = "Heat radiates from the flame. The wax near the top is warm, almost hot.",
on_smell = "Melting beeswax mixed with woodsmoke fills the air.",
on_listen = "A faint crackle comes from the burning wick.",
on_taste = nil,
room_presence = "A candle flickers on the nightstand, casting dancing shadows."
```

**Spent candle (`candle-spent` state):**
```lua
_state = "spent",
description = "A candle burned down to a stub, useless.",
on_feel = "Cold hardened wax; the wick is black and brittle.",
on_smell = "The sharp, acrid smell of burnt wax and soot.",
on_listen = nil,
on_taste = nil,
room_presence = "A burned-out candle stub sits on the nightstand."
```

When a player executes "feel candle" and the candle is `lit`, the engine reads the `lit` state's `on_feel` field and returns it. When the state transitions to `spent`, the same "feel candle" command returns a completely different tactile description.

### The Critical Insight: Stats Override Base Descriptions

As Wayne noted: **"Stats might override a sense, like a burning candle."** The sensory system respects hierarchical overrides:

1. **Base object sensory data** (fallback defaults, defined in base object)
2. **State-specific sensory data** (override if FSM state declares it)
3. **Environmental modifiers** (light level, temperature, weather affect perception)
4. **Player stat modifiers** (future: a blind player has no visual perception; a deaf player has no auditory perception)

Example: A candle in `lit` state is perceivable through **all** senses. But if the player is blind (future mechanic), the LOOK/EXAMINE verbs still work — they return *alternative* sensory fallbacks (touch, smell, sound). The engine never says "you can't look at that." It says "you're blind, but here's what you can touch/smell/hear."

### No Hardcoded Perception; No Object-Specific Code

The engine contains **no object-specific perception logic**. There is no line in the codebase that says "fire smells like smoke" or "water is wet" or "bells make sound." Instead:

- The **LOOK handler** is generic: "Read the target's `description` field for its current state. Display it."
- The **FEEL handler** is generic: "Read the target's `on_feel` field for its current state. Display it."
- The **SMELL handler** is generic: "Read the target's `on_smell` field for its current state. Display it."
- The **LISTEN handler** is generic: "Read the target's `on_listen` field for its current state. Display it."

Each object **owns** its sensory descriptions in its `.lua` metadata. The engine just reads and displays. This is the power of the data-driven architecture: new sensory behaviors require no engine changes.

### Environmental Conditions & Sensory Filters

Environmental conditions act as **sensory filters**, not object properties:

- **Darkness** blocks visual perception (LOOK returns "It is too dark to see") but does NOT block touch, smell, or sound.
- **Silence** (future mechanic) blocks auditory perception but not other senses.
- **Odorless air** (future mechanic) blocks smell but not other senses.

The light system, for example, is implemented as a **filter applied during verb handling**, not as a property of the object:

```lua
-- Generic LOOK handler
function handle_look(target_obj)
    if not is_lit(target_obj.location) then
        return "It is too dark to see anything."
    end
    return target_obj[target_obj._state .. ".description"]
end
```

The candle doesn't have a `brightness` property. The room has a **light state**. When the candle is `lit`, it affects the room's light state. When the player issues LOOK, the engine checks room lighting and decides whether to grant visual perception.

### Linking to Principle #3: State Determines Everything

This principle makes explicit what Principle #3 implies: **An object's FSM state determines not just its behavior, but also how it is perceived.**

- Principle #3 says: "State determines behavior (transitions, timers, capabilities)."
- Principle #6 says: "State also determines sensory output (description, feel, smell, listen)."

The two principles are unified under a single truth: **The world is not static. Objects transform, and perception transforms with them.**

### Why This Matters

1. **Multi-sensory engagement:** Players don't just see the world; they feel, smell, hear, and (occasionally) taste it. A text adventure becomes a **sensory experience**, not a visual-only game.
2. **Accessibility foundation:** Blind players (future) can fully experience the world through non-visual senses. The architecture supports this from the ground up.
3. **Immersion:** When players interact with objects, they receive **state-appropriate sensory feedback**. A candle doesn't "look" lit while "feeling" cold. All senses reflect the current state.
4. **Designer freedom:** Content creators don't edit engine code to add new sensory behaviors. They edit object metadata (`.lua` files). New object types are pure content, no engineering required.
5. **Composability:** Sensory descriptions can reference object properties dynamically. A lantern's `on_feel` can read its fuel level: "The lamp is warm; it feels full." State-driven descriptions enable context-aware messaging.
6. **Debugging clarity:** Every perception query is logged. The engine tracks which sense was used, which state was active, and what description was returned. Sensory bugs are easy to trace.

---

## 7. Objects Exist in Spatial Relationships

Objects don't just exist in a room — **they exist relative to other objects**. A bed sits ON a rug. A rug COVERS a trap door. A candle holder sits ON a nightstand. A key is INSIDE a drawer. These relationships are **first-class metadata**, not derived from container hierarchies or hardcoded physics engines.

### The Spatial Graph Model

The game world is not a flat list of objects. It's a **spatial graph** where each object may declare its position relative to other objects. The engine traverses this graph to determine:

- **Visibility:** Is an object perceivable? (It's invisible if covered by another object)
- **Accessibility:** Can an object be interacted with? (A drawer's contents are inaccessible until opened)
- **Movement consequences:** When you push or move an object, what's revealed or hidden?

Spatial relationships are declared in `.lua` metadata using relationship fields:

```lua
-- rug.lua
{
    id = "rug",
    name = "A Persian rug",
    resting_on = "bed",           -- This rug sits ON the bed
    surfaces = {
        top = { capacity = 5, objects = { "candle_holder" } },
    },
    -- When moved, the rug may reveal what's beneath it
    on_move = function(self, direction)
        if self.covering then
            return "You move the rug, revealing " .. self.covering .. " beneath!"
        end
    end,
    mutations = {
        move = { becomes = "rug", message = "You shift the rug." }
    }
}

-- trap_door.lua
{
    id = "trap_door",
    name = "A hidden trap door",
    covering_by = "rug",           -- This trap door is covered BY the rug
    accessible = false,            -- Can't open while covered
    on_uncover = function(self)
        self.accessible = true
        return "The trap door is now visible!"
    end
}

-- nightstand.lua
{
    id = "nightstand",
    name = "A wooden nightstand",
    surfaces = {
        top = { capacity = 3, objects = { "candle_holder" } },
        inside = { capacity = 5, accessible = false, objects = { "key" } }  -- drawer not yet opened
    }
}
```

### Spatial Relationships as Metadata, Not Code

The engine does **not hardcode** "beds go on rugs" or "rugs cover trap doors." Instead:

- Each object **declares** its spatial position in `.lua` metadata
- Relationship fields: `resting_on`, `covering`, `covered_by`, `surfaces`
- The engine reads these declarations and enforces the spatial graph
- No engine code changes needed to create new spatial scenarios

### Engine Traversal: Graph Resolution

When a player interacts with an object, the engine **resolves the spatial graph**:

1. **Visibility check:** Is the target covered? Traverse `covering` relationships. If covered, return "It's hidden under X."
2. **Accessibility check:** Is the target accessible? Check `accessible` flag and parent objects. A drawer's contents are inaccessible until `container.inside.accessible = true`.
3. **Movement resolution:** When an object is moved/pushed/lifted, traverse reverse relationships. Push the bed → check what's on it (rug) → move rug → check what's beneath it (trap door).

Example: Player "move rug"

```
1. Engine looks up "rug" → finds resting_on = "bed" (position context)
2. Checks cover status → rug is covering "trap_door"
3. Executes move → trap_door.accessible = true, trap_door becomes visible
4. Returns: "You move the rug, revealing a trap door beneath!"
```

### Surfaces as Typed Containers

Objects can have **multiple surfaces**, each with distinct properties:

```lua
nightstand = {
    surfaces = {
        top = { 
            capacity = 3, 
            weight_capacity = 10, 
            accessible = true,
            objects = {}
        },
        inside = { 
            capacity = 5, 
            weight_capacity = 15, 
            accessible = false,  -- Locked until drawer is opened
            objects = { "key", "letter" }
        }
    }
}
```

- **`top` surface:** Always accessible. Items can be placed/taken freely.
- **`inside` surface:** Locked until `accessible = true` (e.g., after "open drawer").
- Each surface has independent capacity, weight limits, and item size restrictions.

### Movement Verbs Interact with Spatial Position

Verbs like PUSH, PULL, MOVE, SHIFT, and LIFT manipulate spatial relationships:

- **PUSH BED:** Engine checks for objects `resting_on = "bed"`. If rug is there, bed can't move. Or: push succeeds, and rug slides with it. (Game design choice per object.)
- **MOVE RUG:** Engine checks `covering` list. Rug moves → trap door is uncovered → trap door becomes visible.
- **LIFT CANDLE HOLDER:** Engine checks what surface it's on. If on `top`, lifts freely. If inside a drawer (inside surface), check if drawer is open.

### Already Demonstrated: The Bedroom Puzzle

The current game demonstrates this principle in action:

1. Player enters bedroom → sees bed, sees rug on floor
2. "PUSH BED" → Bed moves, rug stays visible (design choice)
3. "MOVE RUG" → Rug is moved, trap door revealed beneath
4. "EXAMINE TRAP DOOR" → Now visible and perceivable
5. "OPEN TRAP DOOR" → Opens, revealing cellar entrance

Each step is driven by spatial relationship resolution, not hardcoded puzzle logic. The engine doesn't know about "bedroom puzzle." It knows about spatial graphs.

### Why This Matters

1. **Compositional puzzle design:** Complex environments are built by declaring spatial relationships. No engine code per puzzle.
2. **Visibility is spatial:** Objects are invisible when covered/inside/locked, not because of `visible = false` flags. Perception derives from position.
3. **Player agency:** Moving/pushing/lifting objects has **causal effects** on the world. It's not just flavor — it reshapes accessibility.
4. **Scalability:** Any object can participate in spatial graphs. A book on a shelf, a ring in a chest, a portrait on a wall — all follow the same spatial model.
5. **Debuggability:** Spatial relationships are traceable. "Why can't I see the trap door?" → "It's covered by the rug." Engine can report this clearly.

---

---

## 8. The Engine Executes Metadata; Objects Declare Behavior

The engine is a **generic state machine executor** with zero knowledge of specific object types. It does not know what a candle is, what burning means, or why a door locks. Its sole job is to read FSM metadata from object tables and execute the declared transitions, mutations, guards, and timers.

**All behavior lives in the object .lua files.** Objects declare:
- **States** with sensory properties (what the object looks like, smells like, feels like in each state)
- **Transitions** with triggers, guards, and messages (how and when state changes occur)
- **Mutations** on transitions (what properties change when a transition fires — weight, keywords, capabilities, any arbitrary property)
- **Timed events** (automatic state changes driven by elapsed time)

**The engine's contract:**
1. Load object metadata as Lua tables
2. Execute FSM transitions when triggered (apply state, apply mutations, fire callbacks)
3. Tick timers and fire auto-transitions when they expire
4. Never contain object-specific logic — no `if obj.id == "candle"` anywhere in engine code

**FSM transitions can mutate ANY property on an object instance.** Through the `mutate` field, transitions declare arbitrary property changes: direct values (`weight = 0.5`), computed values (`weight = function(cur) return cur - 0.05 end`), and list operations (`keywords = { add = "stub", remove = "tall" }`). The engine applies these generically without understanding what the properties mean.

### Why This Matters

This is the Dwarf Fortress lesson: the simulation engine operates on **property bags**, not on named object types. Dwarf Fortress doesn't have special "dwarf code" or "door code" — it has material properties, physical simulation rules, and data-driven definitions. Our engine follows the same pattern: a generic FSM executor operating on metadata-rich object tables.

This principle is the architectural complement to Principle 1 (Code-Derived Mutable Objects) and Principle 3 (Objects Have FSM). Where Principle 1 says objects are mutable tables, and Principle 3 says objects carry FSM blueprints, **Principle 8 says the engine is the generic machine that executes those blueprints without understanding them.**

### Design Consequences

1. **New object types require zero engine changes** — add a .lua file, done
2. **New property types require zero engine changes** — the `mutate` applicator is property-agnostic
3. **Object complexity is bounded by metadata expressiveness**, not by engine code
4. **Testing is data-driven** — verify transitions produce correct state, not that engine "understands" objects
5. **The engine can be reasoned about independently of any specific game content**

### Academic & Industry Lineage

- **Harel Statecharts (1987):** Hierarchical state machines with orthogonal regions — our FSM model is a flat specialization of this
- **Entity-Component-System (ECS):** Components are data bags; systems are generic processors. Our objects are entities with inline component data; the FSM engine is the system.
- **Dwarf Fortress (2006–present):** Property-bag material/object system where the simulation engine has no concept of named object types — it operates on physical properties. This is our direct architectural reference model per Wayne's directive (D-DF-ARCHITECTURE).

---

**End of Core Architecture Principles**
