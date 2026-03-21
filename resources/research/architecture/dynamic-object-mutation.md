# Dynamic Object Mutation: Computer Science Foundations

**Author:** Frink (Researcher)  
**Requested by:** Wayne Berry  
**Date:** 2026-07-16  
**Status:** Research Complete

---

## Executive Summary

Wayne's core insight — "the engine only changes what you program it to change" — identifies a fundamental architectural limitation that the game industry has been wrestling with for decades. The current MMO engine already has the *skeleton* of a solution: FSM transitions that atomically swap state properties on objects. But the engine limits mutation to what verb handlers explicitly trigger, and only to properties explicitly listed in state definitions.

This document surveys six areas of computer science and game engine design to build a theoretical foundation for making **ALL** object properties mutable through FSM transitions — controlled by `.lua` authors, not engine programmers.

**The key finding:** The combination of Harel statecharts (extended state machines with data context), Lua metatables (proxy-based property observation), and ECS-inspired composable property bags gives us a proven, well-studied foundation for universal property mutation. We don't need to invent new theory — we need to *compose* existing patterns correctly.

---

## 1. Entity-Component-System (ECS) Architecture

### How Modern Engines Handle Dynamic Property Mutation

The Entity-Component-System pattern, now dominant in Unity DOTS, Unreal's Mass Entity system, and Bevy (Rust), fundamentally reframes what a "game object" is:

| Concept | Traditional OOP | ECS |
|---------|----------------|-----|
| Identity | Class instance | Integer ID (entity) |
| Properties | Member variables on a class | Components attached to entity |
| Behavior | Methods on the class | Systems that query for component sets |
| Mutation | Call methods that modify internal state | Add/remove/modify components |

**The critical insight for our project:** In ECS, an entity's *archetype* (which components it has) can change at runtime. Removing a `Renderer` component makes an object invisible. Adding a `Burning` component makes it on fire. The entity's capabilities are determined by its current component set, not by a static class definition.

### Components as Composable Property Bags

Unity DOTS stores components as pure data structs in contiguous memory chunks, organized by archetype. When you add or remove a component, the entity's data physically moves between memory chunks. This means:

- **What an object IS** = which components it has (its archetype)
- **What's happening to it** = the values within those components
- **What it can do** = which systems match its component signature

This is strikingly similar to our Lua table approach. A Lua table IS a property bag. Our FSM states already swap properties on/off the object table. The difference: ECS does this for *every possible property*, while our FSM only swaps properties explicitly listed in state definitions.

### Relevance to Our FSM + Lua Table Approach

Our current `apply_state()` function in `src/engine/fsm/init.lua` already does a primitive form of ECS-style archetype mutation:

```lua
-- Current: remove old state props, apply new ones
for k, v in pairs(new_state) do
    obj[k] = v  -- State properties overwrite object properties
end
```

**What ECS teaches us:** We should think of FSM states not as "named modes" but as **component sets**. Each state declares which properties (components) the object has in that state. The transition IS the archetype change.

### Sources
- Unity ECS Concepts: https://docs.unity3d.com/Packages/com.unity.entities@0.1/manual/ecs_core.html
- Unity DOTS Architecture: https://deepwiki.com/Unity-Technologies/EntityComponentSystemSamples/2-dots-architecture
- "Entity Component System Complete Tutorial" (2025): https://generalistprogrammer.com/tutorials/entity-component-system-complete-ecs-architecture-tutorial
- "ECS in Game Development: A Deep Dive": https://www.numberanalytics.com/blog/ecs-in-game-development-deep-dive

---

## 2. Reactive/Observable Property Systems

### The Observer Pattern Applied to Game Object Properties

The Observer pattern decouples "what changed" from "who cares." In game engines, this enables property changes to cascade without the object knowing about its dependents:

```
Player picks up wet cloth
  → cloth.wetness = 0.8
    → Observer: weight system recalculates (water adds mass)
    → Observer: description system updates ("a damp cloth")
    → Observer: room humidity increases slightly
    → Observer: if near fire, evaporation timer starts
```

Robert Nystrom's *Game Programming Patterns* describes this as essential for decoupled game systems. The key principle: **the object doesn't know who's listening; it just announces changes.**

### Cascading Property Changes

This is where Wayne's vision gets powerful. Consider a burning candle:

```
candle.state → "lit"
  → candle.casts_light = true        (FSM state property)
  → candle.weight decreases over time (wax consumption)
  → room.light_level increases        (environment reacts)
  → nearby_cloth.fire_risk increases   (proximity effect)
  → candle.description changes         ("the candle burns low...")
```

In a reactive system, each of these is a **derived property** — computed from other properties, not hardcoded by a programmer. The `.lua` author declares the relationships; the engine propagates changes.

### Event-Driven vs. Tick-Driven Mutation

| Approach | When Changes Happen | Best For |
|----------|-------------------|----------|
| Event-driven | On property change (observer fires) | Instant reactions (light on/off, doors) |
| Tick-driven | Every game tick (system processes) | Gradual changes (rust, rot, burning) |
| Hybrid | Events trigger, ticks propagate | Most real-world behavior |

Our engine already uses both: FSM transitions are event-driven (verb triggers state change), while `timed_events` and `on_tick` are tick-driven. The gap is that **only FSM-listed properties participate in either system.**

### Lessons from UI Frameworks (React, Vue, Signals)

Modern UI reactivity offers directly applicable patterns:

**Vue's Proxy-based Reactivity:**
Vue 3 wraps objects in JavaScript `Proxy` objects. Any property read is *tracked* (dependency registered), any property write *triggers* updates to all dependents. This is exactly the pattern we need:

```lua
-- Conceptual Lua equivalent using metatables
local proxy = setmetatable({}, {
    __newindex = function(self, key, value)
        local old = rawget(actual_data, key)
        rawset(actual_data, key, value)
        notify_observers(key, value, old)  -- cascade!
    end,
    __index = function(self, key)
        track_dependency(key)  -- register who's reading
        return rawget(actual_data, key)
    end
})
```

**Signal-based Reactivity (Preact Signals, SolidJS):**
Signals wrap individual values with automatic dependency tracking. When `signal.value` changes, only the specific computations depending on it re-execute. This is more granular than component-level re-rendering and maps directly to per-property game object mutation.

**The key insight:** Vue/React solved the "how do I make arbitrary property changes propagate correctly" problem for UI. We face the exact same problem for game objects. Their solutions (Proxy/metatable interception + dependency graphs) are directly portable to Lua via metatables.

### Sources
- Nystrom, "Observer" in *Game Programming Patterns*: https://www.gameprogrammingpatterns.com/observer.html
- Unity Learn, Observer Pattern: https://learn.unity.com/tutorial/65de086fedbc2a06ac2aca58
- Vue Reactivity System: https://deepwiki.com/vuejs/core/3-reactivity-system
- Preact Signals: https://preactjs.com/guide/v10/signals/
- ReactiveX Observable: https://reactivex.io/documentation/observable.html
- Lua Proxy Tables with Metatables: https://www.tutorialspoint.com/lua/lua_proxy_tables_with_metatables.htm
- Programming in Lua, `__index` and `__newindex`: https://www.lua.org/pil/13.4.1.html

---

## 3. Data-Driven Game Objects (Academic & Industry Research)

### The Foundational Paper: Scott Bilas, GDC 2002

Scott Bilas's GDC talk "A Data-Driven Game Object System" (2002) is the ur-text for this entire field. His core argument:

> **Game objects should be defined by data, not by code.** The programmer builds the system that interprets data. The designer fills in the data. New object types require zero code changes.

Bilas advocated for objects as bags of components described in data files — precisely what our `.lua` object definitions already are. The critical extension Bilas didn't fully explore: **what if the data can also describe how objects CHANGE, not just what they ARE?**

### The Prototype Pattern in Game Design

Nystrom's *Game Programming Patterns* describes the Prototype pattern as directly applicable to game object creation:

- Objects are created by **cloning prototypes** rather than instantiating classes
- Properties can be **overridden per-instance** without changing the prototype
- JavaScript (and Lua) natively support this via prototype chains (JS) and metatables (Lua)

**Our engine already uses this pattern.** Each object in `src/meta/objects/` is a prototype. When instantiated into a universe, it's cloned. FSM states override prototype properties. This is textbook Prototype pattern — we just haven't exploited its full power for mutation.

### Relevant Academic Work

**"Simulation Principles from Dwarf Fortress"** (Tarn Adams, Game AI Pro 2):
Dwarf Fortress models every material with physical properties (density, melting point, fracture strength, corrosion rate). Objects don't have hardcoded "rust" behavior — instead, the *material properties system* applies degradation rules to any object based on its material's corrosion coefficient and environmental moisture. This is universal property mutation driven by data, not code.

**AXIOM: Expanding Object-Centric Models** (arXiv:2505.24784, 2025):
Proposes modeling games as compositions of objects with independent dynamic behaviors and interaction rules. Objects are assembled from modular properties, and behaviors emerge from property interactions — not from scripted sequences.

**Dyn-O: Structured World Models with Object-Centric Representations** (NeurIPS 2025):
Separates object features into "dynamic-agnostic" (what the object fundamentally is) and "dynamic-aware" (what's currently happening to it). This maps directly to our base properties vs. FSM state properties.

**"Deep Learning Applications in Games: A Survey from a Data Perspective"** (Applied Intelligence, Springer, 2023):
Surveys how compositional, data-centric approaches enable procedural content generation and emergent gameplay — exactly the self-modifying universe Wayne envisions.

### The Type Object Pattern (Nystrom)

Nystrom's Type Object pattern separates *type data* from *instance data*:

```
Type: "iron_sword"
  - base_damage: 12
  - material: "iron"
  - corrosion_rate: 0.01

Instance: player's_iron_sword
  - type → "iron_sword"  (inherits base properties)
  - rust_level: 0.3       (instance-specific mutation)
  - name: "a rusty iron sword"  (derived from rust_level)
```

**Key insight for our project:** The type defines what CAN change. The instance tracks what HAS changed. FSM states are the *mechanism* of change. Together, they make every property implicitly mutable without the engine knowing in advance which properties matter.

### Sources
- Bilas, "A Data-Driven Game Object System," GDC 2002
- Nystrom, "Prototype" in *Game Programming Patterns*: https://gameprogrammingpatterns.com/prototype.html
- Nystrom, "Type Object" in *Game Programming Patterns*: https://gameprogrammingpatterns.com/type-object.html
- Nystrom, "Component" in *Game Programming Patterns*: https://gameprogrammingpatterns.com/component.html
- Adams, "Simulation Principles from Dwarf Fortress," *Game AI Pro 2*: http://www.gameaipro.com/GameAIPro2/GameAIPro2_Chapter41_Simulation_Principles_from_Dwarf_Fortress.pdf
- Dwarf Fortress Material Science: https://dwarffortresswiki.org/Material_science
- AXIOM (arXiv, 2025): https://arxiv.org/abs/2505.24784
- Dyn-O (NeurIPS, 2025): https://www.cs.utexas.edu/~pstone/Papers/bib2html-links/dyno_neurips2025.pdf
- Deep Learning in Games Survey (Springer, 2023): https://link.springer.com/article/10.1007/s10489-023-05094-2

---

## 4. FSM as Universal Property Mutator

### Can FSM Transitions Carry Arbitrary Property Mutations?

**Yes — and the theory for this has existed since 1987.**

The standard FSM model (`State × Input → State`) is purely about state identity. But real systems need state machines that also carry and modify *data*. Three established formalisms address this:

### Extended State Machines (FSM + Data Context)

An extended state machine augments the FSM with a **context** — a set of variables that transitions can read and write:

```
State Machine = (States, Events, Transitions, Context)

Transition = {
    from: State,
    to: State,
    event: Event,
    guard: Context → Boolean,
    actions: Context → Context'   ← THIS IS THE KEY
}
```

The `actions` on a transition can modify **any** variable in the context. This is exactly what we need: FSM transitions that carry arbitrary property mutations, not just state identity changes.

**XState** (the modern JavaScript statechart library) implements this directly:

```javascript
// XState: transitions carry context mutations
const candleMachine = createMachine({
    context: { weight: 1.0, burn_remaining: 7200, light_level: 0 },
    states: {
        lit: {
            on: {
                TICK: {
                    actions: assign({
                        weight: (ctx) => ctx.weight - 0.001,
                        burn_remaining: (ctx) => ctx.burn_remaining - 1,
                        light_level: (ctx) => Math.min(1.0, ctx.burn_remaining / 3600)
                    })
                }
            }
        }
    }
});
```

Every tick, the transition modifies weight, burn time, AND light level — all from data, not from engine code.

### Harel Statecharts

David Harel's 1987 paper "Statecharts: A Visual Formalism for Complex Systems" (Science of Computer Programming, Vol. 8) introduced statecharts to solve the "state explosion" problem in complex reactive systems. Key extensions over classical FSMs:

| Feature | Classical FSM | Harel Statechart |
|---------|--------------|-----------------|
| State hierarchy | Flat | Nested (composite states) |
| Concurrency | No | Yes (orthogonal regions) |
| Transition actions | Output only | Can modify external state |
| Guard conditions | No | Yes (boolean on context) |
| History | No | Yes (remember substates) |

**Harel's transition notation:** `event [condition] / action`

The `/action` part is where property mutation happens. In Harel's formalism, an action can:
- Modify variables in the extended state
- Send events to other state machines
- Trigger external side effects

**This maps directly to our architecture:**
```lua
-- Our current transition definition
{ from = "unlit", to = "lit", verb = "light", message = "..." }

-- Extended with Harel-style actions:
{ from = "unlit", to = "lit", verb = "light",
  actions = {
      casts_light = true,
      light_radius = 2,
      weight = function(obj) return obj.weight * 0.99 end,
      provides_tool = "fire_source",
  },
  message = "..." }
```

### UML State Machine Actions

The UML formalization of Harel's work defines three action categories:

1. **Entry actions** — execute when entering a state (our `apply_state` property application)
2. **Exit actions** — execute when leaving a state (our old-state property removal)
3. **Transition actions** — execute during the transition itself (our `on_transition` callback)

Our engine already implements all three, but only for properties explicitly listed in state definitions. **The theoretical framework supports making these actions operate on ANY property.**

### Sources
- Harel, D. (1987). "Statecharts: A Visual Formalism for Complex Systems." *Science of Computer Programming*, 8(3), 231-274.
- UML State Machine (Wikipedia): https://en.wikipedia.org/wiki/UML_state_machine
- UML State Machine Diagrams Reference: https://www.uml-diagrams.org/state-machine-diagrams-reference.html
- XState Documentation: https://stately.ai/docs/xstate
- XState Context and State: https://deepwiki.com/statelyai/xstate/2.3-context-and-state
- Boost.Statechart Library: https://www.boost.org/doc/libs/release/libs/statechart/doc/index.html
- Qt State Machine Overview: https://doc.qt.io/qt-6/qtstatemachine-overview.html
- Itemis State Machine Basics: https://www.itemis.com/en/products/itemis-create/documentation/user-guide/sclang_state_machine_basics

---

## 5. The Mutation Gap Problem

### Wayne's Insight: "The Engine Only Changes What You Program It To Change"

This is the central problem, and it has a name in software architecture: the **impedance mismatch** between the authoring model (what the content creator wants to express) and the execution model (what the engine can process).

Currently in our engine:

```
Content author writes:    "When the sword gets bloody, it should be heavier"
Engine requires:          A programmer to add weight-mutation logic to the ATTACK verb handler
```

The author can declare any property they want in a state definition, but the engine only *responds to* properties it knows about (`casts_light`, `provides_tool`, `surfaces`, etc.). Unknown properties get silently applied to the object table but have no effect unless some system reads them.

### How Other Systems Make ALL Properties Implicitly Mutable

**Dwarf Fortress approach: Material Property Tables**
Every material defines dozens of properties. Systems iterate over objects and apply rules based on property values — not based on property names hardcoded in the engine. If a material has `CORROSION_RATE: 0.01`, the corrosion system applies it. The engine doesn't need to know what specific materials exist.

**ECS approach: Systems query for components**
Systems don't care which entity has which components — they query for component combinations. A `BurningSystem` processes any entity with `Flammable + Temperature` components. Adding those components to a chair, a person, or a letter all make them burnable without code changes.

**React/Vue approach: Generic reactivity**
The reactivity system doesn't know what properties exist. It intercepts ALL reads and writes via Proxy/metatable and tracks dependencies generically. Any property change triggers any dependent computation.

### Declarative vs. Imperative Mutation

| | Declarative Mutation | Imperative Mutation |
|---|---------------------|---------------------|
| **Who** | Content author | Engine programmer |
| **Where** | Data files (.lua objects) | Engine code (verb handlers) |
| **What** | "This property has this value in this state" | `if condition then obj.property = value end` |
| **Flexibility** | New properties need no engine changes | New properties require new engine code |
| **Risk** | Author might set nonsensical values | Programmer gatekeeps all changes |

**The gap in our engine:** We're 80% declarative (states declare properties) but 20% imperative (verb handlers decide which properties the engine actually reads and reacts to). Closing this gap means making the engine *generically reactive* to any property, not just known ones.

### Can We Make the .lua Author the Mutator, Not the Engine Programmer?

**Yes.** The theoretical path is:

1. **Object properties live in a proxy table** (Lua metatables with `__newindex`)
2. **Any property write triggers the observer system** (like Vue's Proxy)
3. **Engine systems register interest in property patterns**, not specific properties
   - Light system: "notify me when anything with `casts_light` changes"
   - Weight system: "notify me when `weight` changes on anything in a container"
   - Description system: "notify me when ANY visible property changes"
4. **FSM state definitions become the single source of truth** for what an object's properties are in each state
5. **The .lua author adds ANY property to ANY state** — if an engine system cares about it, the system reacts; if not, the property is still there for description/narration purposes

```lua
-- Author adds to candle.lua — zero engine changes needed:
states = {
    lit = {
        name = "a lit tallow candle",
        casts_light = true,        -- light system reacts
        smoke_output = 0.3,        -- ventilation system could react
        warmth_radius = 1,         -- comfort system could react  
        wax_drip_rate = 0.01,      -- narration system could mention
        fire_hazard = true,        -- safety system could react
        mood_modifier = "cozy",    -- atmosphere system could react
    }
}
```

The engine doesn't need to know about `smoke_output` in advance. A future `VentilationSystem` can register for it. Meanwhile, the property exists on the object and could be referenced in descriptions, examined by other objects' guard conditions, or queried by LLM-generated narrative.

### The Lua Metatable Solution

Lua's metatable system provides the exact mechanism needed:

```lua
-- Conceptual: wrap every game object in an observable proxy
function make_observable(obj)
    local data = {}
    for k, v in pairs(obj) do data[k] = v end
    
    return setmetatable({}, {
        __newindex = function(_, key, value)
            local old = data[key]
            data[key] = value
            if old ~= value then
                event_bus:emit("property_changed", {
                    object = obj.id,
                    property = key,
                    old_value = old,
                    new_value = value,
                })
            end
        end,
        __index = function(_, key)
            return data[key]
        end
    })
end
```

This is a well-established pattern in Lua game scripting (used in Roblox, Love2D mods, and other Lua game engines). The critical point: `__newindex` fires for ANY property write, not just known ones.

### Sources
- Lua `__index` and `__newindex` metamethods: https://www.lua.org/pil/13.4.1.html
- Lua Proxy Tables: https://www.tutorialspoint.com/lua/lua_proxy_tables_with_metatables.htm
- lua-users wiki, Metatable Events: https://lua-users.org/wiki/MetatableEvents
- Dwarf Fortress Material System: https://dwarffortresswiki.org/material
- Bilas, "A Data-Driven Game Object System," GDC 2002

---

## 6. Real-World Object Behaviors This Could Enable

The power of universal property mutation is best demonstrated through examples that are **impossible** in our current hardcoded-verb-handler model but **trivial** in a declarative mutation system.

### Objects That Degrade Over Time

**Iron Sword — Rust Progression:**
```lua
-- Author writes this, zero engine code needed
states = {
    pristine = {
        name = "an iron sword",
        description = "A well-forged iron blade, gleaming in the light.",
        damage_bonus = 3,
        corrosion_rate = 0.001,
        timed_events = {{ event = "transition", delay = 86400, to_state = "worn" }},
    },
    worn = {
        name = "a worn iron sword",
        description = "The blade shows nicks and the first spots of rust.",
        damage_bonus = 2,
        corrosion_rate = 0.003,
        timed_events = {{ event = "transition", delay = 43200, to_state = "rusty" }},
    },
    rusty = {
        name = "a rusty iron sword",
        description = "More rust than iron now. It might break if you swing too hard.",
        damage_bonus = 0,
        break_chance = 0.15,
        on_look = function(obj, ctx)
            return "Flakes of rust fall away at your touch."
        end,
    },
}
```

**Dwarf Fortress validates this approach.** In DF, iron objects have `[RUST]` as a material property. The corrosion system checks moisture exposure against corrosion resistance — no special "rust this specific object" code exists. Any iron object rusts. Any gold object doesn't. The material data drives it.

### Objects That React to Environment

**Cloth — Environmental Response:**
```lua
states = {
    dry = {
        name = "a cotton cloth",
        weight = 0.5,
        absorbent = true,
        flammable = true,
        transitions = {
            { to = "wet", trigger = "auto", guard = function(obj, ctx)
                return ctx.room and ctx.room.moisture > 0.5
            end },
        },
    },
    wet = {
        name = "a damp cotton cloth",
        weight = 0.8,  -- water adds mass
        absorbent = false,
        flammable = false,  -- wet cloth won't burn
        wringing_yield = "water",
        description = "The cloth is heavy with moisture.",
        transitions = {
            { to = "dry", trigger = "auto", guard = function(obj, ctx)
                return ctx.room and ctx.room.moisture < 0.2
            end },
        },
    },
    frozen = {
        name = "a stiff, frozen cloth",
        weight = 0.9,
        rigid = true,  -- can't be folded
        flammable = false,
        description = "The cloth is frozen solid, stiff as a board.",
    },
}
```

Notice how the author changes `weight`, `flammable`, `absorbent`, and even adds new properties (`wringing_yield`, `rigid`) per state — all without any engine changes. A future "wringing" verb just checks for `wringing_yield`. A future crafting system just checks `rigid`.

### Objects That Learn from Player Behavior

**Lock — Adaptive Difficulty:**
```lua
-- The lock remembers failed attempts via FSM context
states = {
    locked = {
        name = "a brass padlock",
        pick_difficulty = 5,
        on_tick = function(obj, ctx)
            if (obj.failed_picks or 0) >= 3 then
                return "jammed"  -- auto-transition
            end
        end,
    },
    jammed = {
        name = "a jammed brass padlock",
        description = "The lock mechanism is jammed. Repeated failed attempts have bent something inside.",
        pick_difficulty = 99,
        requires_tool_to_fix = "locksmith_kit",
    },
    unlocked = {
        name = "an open brass padlock",
        blocks_passage = false,
    },
},
transitions = {
    { from = "locked", to = "locked", verb = "pick",
      guard = function(obj, ctx)
          return ctx.player.skill < obj.pick_difficulty  -- fail
      end,
      on_transition = function(obj, ctx)
          obj.failed_picks = (obj.failed_picks or 0) + 1
      end,
      message = "The pick slips. You feel something give slightly inside the mechanism.",
    },
},
```

The lock's behavior emerges from property accumulation across transitions — the `failed_picks` counter exists nowhere in engine code. The `.lua` author invented it.

### Objects Whose Names Change Based on State

Our engine already supports this via FSM state properties (the candle changes from "a tallow candle" to "a lit tallow candle"). But universal mutation takes it further:

**A Story-Reactive Object:**
```lua
states = {
    unknown = {
        name = "a dusty old book",
        description = "The cover is too faded to read.",
    },
    identified = {
        name = "Aldric's Journal",
        description = "A leather-bound journal. The name 'Aldric' is embossed on the cover.",
        readable = true,
        value = 50,
    },
    decoded = {
        name = "Aldric's Decoded Journal",
        description = "The cipher has been broken. The journal reveals secrets of the old fortress.",
        readable = true,
        reveals_secret = "fortress_passage",
        value = 500,
        quest_item = "fortress_mystery",
    },
}
```

Each state doesn't just change the name — it changes what the object *is capable of* in the game world. The `reveals_secret` property could be read by a room system. The `quest_item` property could be read by a journal/quest tracker. None of these systems need to know this specific object exists.

### The Emergent Behavior Payoff

When ALL properties are mutable, behaviors **compose** without programmer intervention:

1. Player lights candle → `casts_light = true`, `fire_hazard = true`
2. Player places candle on wooden shelf → shelf is now near fire source
3. Shelf checks: `if nearby_fire and self.flammable then transition("smoldering")`
4. Smoldering shelf → `smoke_output = 0.5`, triggers ventilation check
5. If no ventilation → room fills with smoke → `visibility = 0.2`
6. Player can't see → sensory verbs still work (D-37: FEEL, SMELL work in darkness)
7. Player SMELLs → "Smoke. Something wooden is burning."

**None of this requires a programmer.** Each object's `.lua` file declares its own reactive properties. The engine's generic systems (light, fire, ventilation, visibility) query for property patterns. Emergence happens because independent property declarations interact through shared systems.

### Sources
- Adams, T. "Simulation Principles from Dwarf Fortress," *Game AI Pro 2*: http://www.gameaipro.com/GameAIPro2/GameAIPro2_Chapter41_Simulation_Principles_from_Dwarf_Fortress.pdf
- Dwarf Fortress Material Properties: https://dwarffortresswiki.org/Material_science
- "Prototype Pattern in Game Design": https://www.momentslog.com/development/design-pattern/prototype-pattern-in-game-design-creating-game-objects

---

## 7. Synthesis: Architectural Path Forward

### What We Already Have

| Capability | Status | Location |
|-----------|--------|----------|
| FSM state definitions with property bags | ✅ Implemented | `src/meta/objects/*.lua` |
| Atomic state property application | ✅ Implemented | `src/engine/fsm/init.lua:apply_state()` |
| Timer-based auto-transitions | ✅ Implemented | `src/engine/fsm/init.lua:tick()` |
| Guard conditions on transitions | ✅ Implemented | `src/engine/fsm/init.lua:transition()` |
| `on_transition` callbacks | ✅ Implemented | `src/engine/fsm/init.lua:131` |
| Lua tables as property bags | ✅ Native | Lua language feature |

### What We Need (Informed by This Research)

| Capability | Theory Source | Implementation Path |
|-----------|--------------|-------------------|
| Observable properties via metatable proxy | Vue reactivity, Lua `__newindex` | Wrap objects in proxy tables |
| Generic system registration for property patterns | ECS archetype queries | Event bus + property pattern matching |
| Transition actions that modify context (extended state) | Harel statecharts, XState `assign` | Add `actions` field to transition definitions |
| Computed/derived properties | Vue `computed`, Signals | Metatabled getters that recalculate on dependency change |
| Author-defined properties without engine awareness | Bilas data-driven objects, DF materials | Engine reads properties generically, not by name |

### The Three-Layer Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Layer 3: Content (.lua object definitions)             │
│  • Authors declare states with ANY properties           │
│  • Authors define transitions with actions              │
│  • Authors write guard conditions                       │
│  • NO engine awareness required for new properties      │
├─────────────────────────────────────────────────────────┤
│  Layer 2: Reactive Property System (engine middleware)   │
│  • Metatable proxy intercepts all property writes       │
│  • Event bus broadcasts property changes                │
│  • Dependency tracking for computed properties          │
│  • Generic — doesn't know property names in advance     │
├─────────────────────────────────────────────────────────┤
│  Layer 1: Engine Systems (query for property patterns)  │
│  • Light system: queries casts_light, light_radius      │
│  • Weight system: queries weight, container contents    │
│  • Description system: queries name, description        │
│  • Each system registers property interests generically │
└─────────────────────────────────────────────────────────┘
```

**The critical principle:** Layer 3 (content) can add properties that no Layer 1 system currently reads. Those properties still exist on the object. A future system can start reading them with zero changes to Layer 3. This is how Dwarf Fortress can add new material interactions without changing any material definitions — and how our engine should work.

### Theoretical Confidence

Every component of this architecture has been independently validated:

- **Metatable proxy observation:** Standard Lua pattern, used in Roblox (millions of games), Love2D
- **Event-driven property cascading:** Standard Observer pattern, proven in every major game engine
- **Extended state machines:** Formally specified since Harel 1987, implemented in XState, Boost.Statechart, Qt
- **Data-driven object composition:** Industry standard since Bilas 2002, powers Unity, Unreal, Bevy
- **Author-as-mutator:** Proven by Dwarf Fortress (modders define materials), Minecraft datapacks, Roblox scripting

**We are not inventing new computer science. We are composing proven patterns into a specific architecture for text-adventure object mutation.** The theoretical risk is near zero. The implementation risk is in getting the reactive system performant within our sandbox constraints (D-14, D-16).

---

## References (Consolidated)

### Seminal Works
1. Harel, D. (1987). "Statecharts: A Visual Formalism for Complex Systems." *Science of Computer Programming*, 8(3), 231-274.
2. Bilas, S. (2002). "A Data-Driven Game Object System." GDC 2002.
3. Nystrom, R. (2014). *Game Programming Patterns*. Genever Benning.
4. Adams, T. "Simulation Principles from Dwarf Fortress." *Game AI Pro 2*. http://www.gameaipro.com/GameAIPro2/GameAIPro2_Chapter41_Simulation_Principles_from_Dwarf_Fortress.pdf

### Game Engine Architecture
5. Unity ECS Concepts: https://docs.unity3d.com/Packages/com.unity.entities@0.1/manual/ecs_core.html
6. Unity DOTS Architecture: https://deepwiki.com/Unity-Technologies/EntityComponentSystemSamples/2-dots-architecture
7. ECS Complete Tutorial (2025): https://generalistprogrammer.com/tutorials/entity-component-system-complete-ecs-architecture-tutorial

### Design Patterns
8. Nystrom, "Observer": https://www.gameprogrammingpatterns.com/observer.html
9. Nystrom, "Prototype": https://gameprogrammingpatterns.com/prototype.html
10. Nystrom, "Type Object": https://gameprogrammingpatterns.com/type-object.html
11. Nystrom, "Component": https://gameprogrammingpatterns.com/component.html

### State Machines
12. UML State Machine (Wikipedia): https://en.wikipedia.org/wiki/UML_state_machine
13. UML State Machine Diagrams: https://www.uml-diagrams.org/state-machine-diagrams-reference.html
14. XState Documentation: https://stately.ai/docs/xstate
15. XState Context and State: https://deepwiki.com/statelyai/xstate/2.3-context-and-state
16. Boost.Statechart: https://www.boost.org/doc/libs/release/libs/statechart/doc/index.html

### Reactivity Systems
17. Vue Reactivity System: https://deepwiki.com/vuejs/core/3-reactivity-system
18. Preact Signals: https://preactjs.com/guide/v10/signals/
19. ReactiveX: https://reactivex.io/documentation/observable.html

### Lua Implementation
20. Programming in Lua, Metatables: https://www.lua.org/pil/13.4.1.html
21. Lua Proxy Tables: https://www.tutorialspoint.com/lua/lua_proxy_tables_with_metatables.htm
22. lua-users wiki, Metatable Events: https://lua-users.org/wiki/MetatableEvents

### Academic Papers (2023-2025)
23. AXIOM: Object-Centric Models (arXiv, 2025): https://arxiv.org/abs/2505.24784
24. Dyn-O: Structured World Models (NeurIPS, 2025): https://www.cs.utexas.edu/~pstone/Papers/bib2html-links/dyno_neurips2025.pdf
25. Deep Learning in Games Survey (Springer, 2023): https://link.springer.com/article/10.1007/s10489-023-05094-2
26. Object-Centric Agents in Open World Games (IEEE, 2023): https://ieeexplore.ieee.org/document/10125026

### Game-Specific
27. Dwarf Fortress Material Science: https://dwarffortresswiki.org/Material_science
28. Dwarf Fortress Materials: https://dwarffortresswiki.org/material
29. Systems-Based Design in DF (thesis): https://www.theseus.fi/bitstream/handle/10024/814557/Lehner_Niilo.pdf?sequence=3
