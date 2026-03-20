# Architecture Overview

**Version:** 1.2  
**Last Updated:** 2026-03-22
**Author:** Brockman (Documentation)  
**Purpose:** High-level map of how all systems fit together. Detailed specs are in linked docs.

---

## Core Principle: Code-Derived Mutable Objects

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

## Core Principle: Base Objects → Object Instances

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

## Core Principle: Objects Have FSM; Instances Know Their State

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

## Core Principle: Composite Objects Encapsulate Inner Objects

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

## Core Principle: Multiple Instances Per Base Object; Each Instance Has a Unique GUID

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

## Core Principle: Objects Exist in Sensory Space; State Determines Perception

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

## Core Principle: Objects Exist in Spatial Relationships

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

## The System Stack

### Layer 1: Engine Core

**Runtime:** Lua (5.4)  
**Entry Point:** `src/main.lua`

The engine is a **self-modifying Lua interpreter**. All game state is represented as Lua code/data. When the player acts, the engine rewrites the object definitions to reflect new state.

**Core Files:**
- `src/engine/loop/init.lua` — Main game loop (read command → parse → verb dispatch → tick → render)
- `src/engine/parser/init.lua` — Tier 1 (exact) + Tier 2 (phrase similarity) parser
- `src/engine/verbs/init.lua` — Verb handlers (31 verbs, pluggable)
- `src/engine/registry/init.lua` — Object registry (load, store, query)
- `src/engine/loader/init.lua` — Object template resolution + inheritance
- `src/engine/containment/init.lua` — Containment validation (5-layer checks)
- `src/engine/mutation/init.lua` — Code rewrite engine (object state transitions)

---

### Layer 2: Parser System

**Design:** Three-tier command parsing.

#### Tier 1: Exact Dispatch
- Input → verb alias lookup → handler
- **Cost:** Zero tokens, instant
- **Examples:** "look", "l", "x chair"
- **Success Rate:** ~70% of typical player input

#### Tier 2: Phrase Similarity
- If Tier 1 misses, compute Jaccard token overlap between input and phrase dictionary
- Threshold: 0.40 (tunable)
- **Cost:** Zero tokens, ~5ms per lookup
- **Examples:** "examine the chair" → matches "x", "look at chair" → matches "examine"
- **Success Rate:** ~90% of player input

#### Tier 3: NOT YET IMPLEMENTED
- If Tier 2 misses, **Goal-Oriented Action Planning (GOAP) backward-chaining parser** engages
- Detects missing prerequisites: "Light candle" fails → planner checks candle's prerequisite table
- Builds action chain: [open matchbox, get match, strike match, light candle]
- Executes chain step-by-step through Tier 1
- Stops on first failure
- **Cost:** ~125 object scans per plan, sub-millisecond in Lua
- **Design:** Prerequisite chains object-owned (not centralized). Each transition can declare prerequisites.
- **Performance:** Estimated 3 days of implementation (half day planning, half day content tagging, 1 day tests)

**Key Insight:** Tier 3 is a recovery mechanism, not mind-reading. It asks: "The player wanted X. X failed because Y is missing. Can I satisfy Y?" It does NOT ask: "What might they want to do next?"

**Example:**
```lua
-- User types: "light the candle"
-- Tier 1 routes to LIGHT handler
-- Handler finds: no fire_source in inventory
-- Tier 3 engages:
--   Check candle's prerequisites: needs fire_source
--   Search for fire_source providers: match-1 (state: unlit)
--   Plan needed: get match, strike match
--   Check match's prerequisites: needs holding match (in inventory)
--   Subplan: open matchbox, get match
--   Execute: [open matchbox → get match → strike match → light candle]
--   Player sees: rapid narration of all steps
-- Result: candle is lit (player achieved their goal in one command)
```

---

### Layer 2.5: Terminal UI (Split-Screen Display)

**Design:** Classic IF split-screen: output window (scrollable, top), status bar (top line), input line (bottom).

**Components:**
- **Output Window:** Renders all game output (action results, sensory descriptions). Scrollback buffer holds 500 lines. User can scroll up/down with `/up`, `/down`, `/bottom` commands.
- **Status Bar:** Single-line display at screen top. Left-justified (player name, location) / right-justified (light state, health, etc.). Updates per turn.
- **Input Line:** Bottom line where player types commands. Cursor visible. Separate from output — no game output mixes with user input.
- **ANSI Escape Codes:** Pure Lua implementation, no C libraries. Windows-compatible. Uses scroll regions to isolate status bar.

**Implementation:**
- `src/engine/ui/init.lua` — Terminal UI module
- `display.ui` hook intercepts all `print()` calls
- `--no-ui` flag for fallback to simple REPL (test mode, piped input)

**See Also:** Detailed design in (future: `docs/design/terminal-ui.md`)

---

### Layer 2.75: Timed Events & Ambient Output

**Design:** Objects declare embedded timers that emit ambient events to the output window.

**Types:**
- **One-shot timers:** Fire once after N time units (time bomb, timed door unlock)
- **Recurring timers:** Fire repeatedly every N time units (clock chime, dripping water, creaking floorboards)

**Example (Wall Clock in Bedroom):**
```lua
timers = {
  {
    name = "hourly_chime",
    interval = 3600,  -- 1 in-game hour in seconds
    recurring = true,
    message = function(self, now)
      local hour = math.floor((now % 86400) / 3600)
      local chime_count = (hour == 0) and 12 or (hour % 12)
      return ("The clock chimed %d time%s."):format(chime_count, chime_count == 1 and "" or "s")
    end
  }
}
```

**Output:** Emitted regardless of player action. Creates sense of world simulation.

---

### Layer 3: Verb Dispatch

**Count:** 31 verbs across 4 categories

#### Navigation & Perception (7)
LOOK, EXAMINE, FEEL, SMELL, TASTE, LISTEN, READ

#### Inventory (6)
TAKE, DROP, INVENTORY, WEAR, PUT, OPEN, CLOSE

#### Object Interaction (8)
LIGHT, STRIKE, EXTINGUISH, BREAK, TEAR, WRITE, CUT, SEW, PRICK

#### Movement (6+)
NORTH, SOUTH, EAST, WEST, UP, DOWN, GO, ENTER, EXIT, DESCEND, CLIMB (all route through unified `handle_movement`)

#### Meta (2)
HELP, QUIT

**Architecture: Generic Handlers + Object-Owned FSM**

Verb handlers in `src/engine/verbs/init.lua` are generic infrastructure — they dispatch commands but contain NO object-specific logic. 

Example: The OPEN handler doesn't have special cases for "wooden doors," "drawers," "cursed gates," or "time-locked safes." Instead, each object declares its own transitions and prerequisites in its FSM metadata:

```lua
-- In src/meta/world/bedroom-door.lua
mutations = {
    open = {
        requires_tool = "key",       -- Only object knows it needs a key
        requires_skill = nil,
        becomes = "bedroom-door-open",
        message = "The door swings inward.",
        timed_revert = 30            -- Door auto-closes after 30 ticks
    }
}
```

When the OPEN handler runs:
1. Engine finds the target object (bedroom-door)
2. Looks up the object's transition rules (mutations.open)
3. Checks prerequisites from the **object's FSM**, not engine code
4. Executes the mutation (replaces object definition)
5. Returns the object's message

**Result:** The engine is truly generic. Objects own their state machines. This enables:
- Cursed interactions (object FSM returns nonsense messages)
- Room-specific verb behavior (via object-specific mutations)
- Dynamic verb adaptation (object mutations change based on universe state)
- No engine changes needed for new object types

**Movement Handler Unification:**
- All movement verbs route through `handle_movement(ctx, direction)`
- Handles: direction alias resolution, keyword search, exit accessibility checks (locked doors)
- Room transition: updates `ctx.current_room`, loads room contents, resets view

**Verb Handler Pattern:**
```lua
verb.LIGHT = function(ctx, target, tool)
    -- 1. Resolve target object
    -- 2. Check for requires_tool capability
    -- 3. Check for success conditions (light source present, object lightable)
    -- 4. Execute mutation (swap object definition)
    -- 5. Print message
    -- 6. Return success/fail
end
```

**Tool Resolution:** Verbs can request capabilities (`requires_tool`). Engine searches player inventory for matching `provides_tool`. First match wins.

---

### Layer 2.5.5: Multi-Room System

**Design:** World is multi-room. All rooms load at startup. Objects persist across room boundaries.

**Architecture:**
- **Room Registry:** `context.rooms = { bedroom = {...}, cellar = {...}, ... }`
- **Object Registry:** Single shared registry across all rooms
- **Room Contents:** Each room has `room.contents` array (which objects are in this room)
- **Player Location:** `ctx.current_room` tracks current room ID

**Loading:**
- Startup: Load all `.lua` files from `src/meta/world/`
- Each room returns: `{ id, name, description, contents, ...}`
- Rooms instantiated into `context.rooms` table

**Movement:**
- Player types: "go north"
- `handle_movement` looks up north exit in current room
- Checks accessibility (locked door? key in inventory?)
- Transitions player to new room: `ctx.current_room = "cellar"`
- Resets view: shows room description, contents

**Object Persistence:**
- Drop item in bedroom → item stays in registry with `location = "bedroom"`
- Move to cellar → return to bedroom → item still there
- Objects tick only in current room + player hands (prevents resource burn in other rooms)

---

### Layer 4: Object System

**Architecture:** Single Lua file per logical object (including all states/parts).

#### Object Definition Structure
```lua
{
    id = "candle",
    name = "A tapered candle",
    size = 1,
    weight = 0.1,
    template = "small-item",           -- Inherit defaults from template
    provides_tool = "fire_source",      -- Optional: what capability does this provide?
    casts_light = true,                 -- Optional: does this emit light?
    on_look = function(self) return "..." end,
    on_feel = "Smooth wax.",
    on_smell = "Pleasant vanilla scent.",
    mutations = {
        extinguish = {
            becomes = "candle",         -- Return to unlit state
            message = "The flame goes out.",
        }
    }
}
```

#### Object States via Mutations
- **Match:** unlit → lit (30 ticks) → spent
- **Candle:** unlit → lit (100 ticks) → stub (20 ticks) → spent
- **Nightstand:** closed → open (reversible, container access gate)
- **Paper:** blank → paper-with-writing (one-way, text embedded in definition)

**Code Rewrite Model:** When a mutation triggers, the entire object definition is replaced. Old definition removed from registry, new one inserted. No separate state flags.

#### Composite Objects
- **Single file:** nightstand.lua contains nightstand + drawer definitions
- **Detachable parts:** drawer has factory function; can detach to become independent
- **FSM state names:** `closed_with_drawer`, `closed_without_drawer` (reflect component presence)
- **Part reversibility:** Design choice per part (drawer reversible, cork irreversible)

#### Object Templates
**Single-level inheritance** (no deep chains):
- `sheet.lua` — fabric/cloth family
- `furniture.lua` — heavy immovable objects
- `container.lua` — bags, boxes, chests
- `small-item.lua` — tiny portable items

Instance properties override template properties. Loader uses deep merge.

---

### Layer 5: Containment System

**5-Layer Validation Chain:**

1. **Layer 1:** Is target a container? (has `container` field)
2. **Layer 2:** Does item fit physically? (size tier ≤ max_item_size)
3. **Layer 3:** Is there room left? (total_weight ≤ weight_capacity)
4. **Layer 4:** Category accept/reject? (is item in allowed categories?)
5. **Layer 5:** Weight limit? (item weight + contents < capacity)

**Multi-Surface Support:**
```lua
container = {
    surfaces = {
        top = { capacity = 3, weight_capacity = 20, max_item_size = 3 },
        inside = { capacity = 5, weight_capacity = 15, max_item_size = 2, accessible = false }
    }
}
```

**Key Properties:**
- `weight` (number) — object's own weight
- `weight_capacity` (number) — how much stuff can it hold?
- `size` (1-6) — how large is this object physically?
- `max_item_size` (1-6) — what's the biggest item that fits through opening?
- `categories` (table) — what types does this belong to? (e.g., "book", "clothing", "tool")

---

### Layer 6: Player Model

**Inventory Structure:**
```lua
player = {
    hands = { left = nil, right = nil },     -- What's held in hands?
    worn = {                                  -- What's worn?
        head = nil,
        torso = nil,
        feet = nil,
        -- ... other body slots
    },
    skills = {
        lockpicking = false,
        sewing = false,
        -- ... learned skills
    }
}
```

**Hand Slots:**
- Player has 2 hands total
- Objects declare `hands_required` (0, 1, or 2)
- Heavy/large items tie up both hands
- Worn items don't consume hand slots

**Wearable System:**
- Each worn item occupies one body slot
- Wearables can be containers (backpack on back)
- Some wearables block vision (sack on head)
- Slot conflicts prevent simultaneous wear

**Skills:**
- Binary (have it or don't)
- Gates certain verbs (SEW requires sewing skill)
- Unlocks tool combinations (pin → lock pick WITH skill)
- Discovered through gameplay (find manual, practice, NPC teaching, puzzle solve)

---

### Layer 7: World State & Time

**Game Clock:**
- Real-time OS time × 24 = game seconds
- Always accurate, even between commands
- 24-hour cycle: 6 AM (dawn) to 6 PM (dusk) to 2 AM (night)
- Used for light/dark calculations

**Game State:**
- Collection of all object definitions (mutable Lua code)
- Player state (inventory, worn, skills, location)
- Exit state (locks, open/closed doors)
- Room visibility (light/dark, what's visible)

**Persistence (Cloud):**
- Mutated state persists to cloud storage
- Enables cross-device play
- Supports analytics on universe evolution

---

### Layer 8: Light & Dark System

**Light Sources:**
- Objects with `casts_light = true` emit light (lit candle, torch)
- Room-level check: if any object in room casts light, room is bright
- Daylight: outside areas + time 6 AM to 6 PM + `allows_daylight = true`

**Sensory in Darkness:**
- LOOK requires light (fails with "You see nothing in the darkness")
- FEEL / SMELL / TASTE / LISTEN work in darkness (no light needed)
- EXAMINE has light requirement (only in bright rooms)

**Vision Blocking:**
- Wearables with `blocks_vision = true` (sack, blindfold) disable LOOK
- Even in bright room, blindness overrides light
- Becomes a puzzle element (can't see, but can FEEL/SMELL)

---

### Layer 9: Consumables & Temporal Effects

**Event-Driven Ticks:**
- 1 tick = 1 player command
- Ticks happen BEFORE verb execution (fair resource consumption)
- Each object tracks remaining ticks in current state

**Match Lifecycle:**
1. Unlit (any number of ticks)
2. Strike on matchbox → mutates to `match-lit`
3. Lit (30 ticks, warning at 5 ticks)
4. Auto-transition to `match-spent` (terminal)
5. Spent (can't be relit)

**Candle Lifecycle:**
1. Unlit (any number of ticks)
2. Light with fire source → mutates to `candle-lit`
3. Lit (100 ticks, warning at 10 ticks)
4. Auto-transition to `candle-stub` (medium burn)
5. Stub (20 ticks, warning at 5 ticks — urgent)
6. Auto-transition to `candle-spent` (terminal)
7. Spent (no light, can't be relit)

**Terminal States:**
- Once spent, object cannot transition back to any active state
- "Spent" means destroyed/unusable for puzzle purposes
- Prevents infinite resource loops

---

### Layer 10: Game Loop

**Each Turn:**

```
1. [Tick] Auto-advance object timers (consumables burn, state transitions)
2. [Input] Read command from player
3. [Parse] Tier 1 exact lookup → Tier 2 phrase similarity
4. [Dispatch] Route to appropriate verb handler
5. [Execute] Verb mutates objects, checks conditions
6. [Render] Print output (success/fail message + sensory feedback)
7. [Check] If ctx.game_over, break loop and prompt "Play again?"
8. [Repeat]
```

**Context Object (passed to all verbs):**
```lua
ctx = {
    player = { ... },           -- Current player state
    registry = { ... },         -- All object definitions
    current_room = "bedroom",   -- Player location
    game_over = false,          -- Exit flag
}
```

---

## Data Flow: Command → Verb → Object → FSM → Response

```
Player Types "light candle"
    ↓
Parser (Tier 1): "light" exact match? No.
    ↓
Parser (Tier 2): Phrase similarity to "light"? Yes (score 0.85)
    ↓
Verb Handler: verb.LIGHT(ctx, "candle", nil)
    ↓
Engine: Find candle in registry
    ↓
Check: Mutations.light requires_tool = "fire_source"
    ↓
Search: Player inventory for provides_tool = "fire_source"
    ↓
Result: No fire_source found
    ↓
[NEW: Tier 3 Goal Decomposition Engages]
    ↓
Planner: Query candle's prerequisites
    ↓
Found: prerequisites = [{ need = "fire_source", sources = [{ object = "match", state = "lit" }] }]
    ↓
Backward Chaining: Plan to light a match
    ↓
Check match's prerequisites: needs holding match, has_striker surface
    ↓
Plan: [open matchbox → get match → strike match → light candle]
    ↓
Execute Each Step via Tier 1:
  1. OPEN matchbox → success
  2. GET match → success
  3. STRIKE match → success (match-lit obtained)
  4. LIGHT candle (now fire_source available) → success
    ↓
Output: "You slide the matchbox tray open. You take a match and strike it against 
the strip — it catches with a hiss. The wick catches the flame and curls to life, 
casting a warm amber glow."
    ↓
Game State: candle-lit, match-lit, matchbox-open
    ↓
Continue game loop
```

**Without Tier 3 (old flow):**
```
Player Types "light candle"
  → Tier 1 + Tier 2 route to LIGHT handler
  → Handler finds no fire_source
  → Failure: "You have nothing to light it with."
  → Player must manually: open matchbox → take match → strike match → light candle (4 more commands)
```

---

## Integration Points

### Verb + Object
- Verbs declare requirements: `requires_tool`, `requires_skill`
- Objects declare capabilities: `provides_tool`, `provides_skill`
- Engine matches requirements to capabilities

### Parser + Verb
- Parser returns (verb_id, target_noun, optional_tool_noun)
- Verb handler dispatches based on verb_id
- Target and tool resolved from player location and inventory

### FSM + Mutation
- FSM state names match file naming: `candle`, `candle-lit`, `candle-spent`
- Mutation triggers code swap (old definition → new definition)
- Auto-transitions happen before verb execution

### Container + Inventory
- Player inventory is a container (special: no gravity, tied to player body)
- Worn items are tracked separately (don't consume hand slots)
- Hand slots limited (0/1/2 hands required per object)

### Light + Rendering
- Room renders based on light state (bright/dark)
- Sensory descriptions gated by light/dark
- Wearables can override light state (vision blocking)

### Skills + Verbs
- Verbs gate on `required_skill`
- Player learns skills through gameplay
- Skills unlock tool combinations and new mutations

---

## Design Principles

1. **Code IS State** — No separate flag system. Object definitions are mutable and definitive.
2. **Capability Matching** — Tools provide capabilities; verbs require them. Extensible beyond specific items.
3. **5-Layer Containment** — Systematic validation prevents "put desk in elephant" nonsense.
4. **Event-Driven Time** — Fair resource consumption; ticks before verbs; matches burn urgently.
5. **Sensory Over Visual** — Darkness forces FEEL/SMELL/LISTEN; creates puzzle depth.
6. **Single-File Composites** — All parts of an object live in one file; FSM names reflect states.
7. **Tier 1 + 2 Parser** — Fast exact lookup (70%), graceful phrase similarity (20%), visible fail (10%).
8. **Cloud Persistence** — Universe state lives in cloud; players resume cross-device.
9. **Player-Per-Universe** — Each player has their own world; opt-in multi-player.
10. **LLM at Build Time** — Content generated once at build time; procedurally varied per player; no per-interaction tokens.

---

## Cross-References

- **Parser Details:** `verb-system.md`, `command-variation-matrix.md`
- **Goal-Oriented Parser:** `intelligent-parser.md` (existing), `docs/design/goal-decomposition.md` (planned)
- **Object Details:** `fsm-object-lifecycle.md`, `composite-objects.md`
- **Container Details:** `containment-constraints.md`
- **Wearable Details:** `wearable-system.md`
- **Verb Reference:** `verb-system.md`
- **Tool Patterns:** `tool-objects.md`
- **Skills Design:** `player-skills.md`
- **Room Design:** `dynamic-room-descriptions.md`, `room-exits.md`, `spatial-system.md`
- **Terminal UI:** `docs/design/terminal-ui.md` (planned)
- **Timed Events:** `docs/design/timed-events.md` (planned)
- **Architecture Decisions:** `architecture-decisions.md`, `.squad/decisions.md`

---

## Future Expansion Points

- **Procedural Variation:** Seeded universe templates for replay differentiation
- **Multiverse Merging:** Double-opt-in player universe merges (post-MVP)
- **NPC AI:** Static → Reactive → Proactive (Phase 2+)
- **Combat System:** Turn-based verb system (Phase 2+)
- **Magic System:** High-level verbs triggering LLM effects (Phase 3+)
- **More Verbs:** Start with 31; extensible for custom puzzles
- **ONNX Runtime:** Real vector embeddings in browser (Phase 2)
- **App Store:** Capacitor wrapping for iOS/Android (Phase 3+)

