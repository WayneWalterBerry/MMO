# Dwarf Fortress Architecture Deep Dive & Comparison

**Author:** Frink (Researcher)  
**Requested by:** Wayne Berry  
**Date:** 2026-07-19  
**Status:** Research Complete  
**Related:** D-DF-ARCHITECTURE, D-MUTATE-PROPOSAL, Principle 8

---

## Executive Summary

Dwarf Fortress (DF) is the most ambitious simulation game ever built — 700,000+ lines of C++, 20+ years of continuous development, and a design philosophy that prioritizes emergence over scripting. Wayne calls it the GOAT, and the architecture backs that up.

Our engine already shares DF's core DNA: property-bag objects, data-driven definitions, and a generic engine that doesn't special-case object types. But DF goes dramatically further in three areas: **continuous numeric simulation** (temperature, wear, pressure as real numbers, not FSM states), **material-as-physics** (combat/fire/melting all derive from the same material property tables), and **hierarchical composition** (creatures built from body plans → tissue layers → material properties, all composable via templates).

This report maps every major DF system to our engine, identifies what we should adopt, what we should avoid, and what we already do better.

---

## Table of Contents

1. [DF Material/Property System](#1-df-materialproperty-system)
2. [DF Object/Entity Model](#2-df-objectentity-model)
3. [DF FSM / State Management](#3-df-fsm--state-management)
4. [Comparison: Our Engine vs DF](#4-comparison-our-engine-vs-df)
5. [Lessons We Can Adopt](#5-lessons-we-can-adopt)
6. [DF Development History & Philosophy](#6-df-development-history--philosophy)
7. [Sources](#7-sources)

---

## 1. DF Material/Property System

### 1.1 How DF Defines Materials

Every material in Dwarf Fortress is a **property bag** defined in plaintext "raw" files. Materials are categorized as:

- **Inorganic** (`inorganic_metal.txt`, `inorganic_stone.txt`) — metals, stone, gems
- **Organic** — derived from creatures (`creature_x.txt`) and plants (`plant_x.txt`)

A material definition looks like this:

```
[INORGANIC:STEEL]
  [USE_MATERIAL_TEMPLATE:METAL_TEMPLATE]
  [STATE_NAME_ADJ:ALL_SOLID:steel]
  [COLOR:0:7:1]
  [MATERIAL_VALUE:30]
  [SPEC_HEAT:500]
  [MELTING_POINT:12718]
  [BOILING_POINT:14968]
  [SOLID_DENSITY:7850]
  [IMPACT_YIELD:2520]
  [IMPACT_FRACTURE:3900]
  [IMPACT_ELASTICITY:150]
  [SHEAR_YIELD:720]
  [SHEAR_FRACTURE:1720]
  [SHEAR_ELASTICITY:56]
  [IGNITE_POINT:NONE]
```

### 1.2 Material Properties: The Full Set

DF materials carry a rich set of numeric properties that the engine uses for simulation:

| Property Category | Properties | Engine Use |
|---|---|---|
| **Mechanical** | Impact/shear yield, fracture, elasticity | Combat damage calculation |
| **Thermal** | Melting point, boiling point, ignition point, specific heat | Phase transitions, fire |
| **Physical** | Solid/liquid density, max edge | Weight, buoyancy, weapon sharpness |
| **Economic** | Material value | Trade, wealth calculation |
| **Display** | Color, state names (solid/liquid/gas adjectives) | Rendering, description generation |

**Key insight:** These are not boolean flags or FSM states. They are **continuous numeric values** that the engine uses in physics calculations. A "steel sword" doesn't know it's sharp — it inherits steel's `SHEAR_FRACTURE:1720` and `MAX_EDGE:10000`, and the combat engine calculates cutting ability from those numbers.

### 1.3 Material Template Inheritance

DF uses a template system strikingly similar to our own:

```
[MATERIAL_TEMPLATE:METAL_TEMPLATE]
  [IS_METAL]
  [ITEMS_WEAPON]
  [ITEMS_ARMOR]
  [ITEMS_AMMO]
  [ITEMS_METAL]
  ...shared metal properties...
```

Individual metals then inherit from this template and override specific values:

```
[INORGANIC:STEEL]
  [USE_MATERIAL_TEMPLATE:METAL_TEMPLATE]
  [SOLID_DENSITY:7850]       ← Override
  [SHEAR_FRACTURE:1720]      ← Override
```

**Parallel to our engine:** This is exactly how our templates work — `templates/small-item.lua` provides defaults, and specific objects override. The difference is that DF's templates are purely declarative tokens, while ours are executable Lua.

### 1.4 How The Engine Simulates Physics on Properties

This is the architectural insight Wayne identified: **DF's engine doesn't know what objects are. It only knows material properties.**

- **Combat:** When a steel sword strikes a leather breastplate, the engine calculates momentum from weapon weight × velocity, compares it against the armor's impact yield and shear fracture values. It doesn't know "sword" or "leather" — it runs math on numbers.
- **Fire:** When a tile reaches ignition temperature, every item on that tile checks `material.ignition_point`. Wood has one (~10508°U). Stone doesn't. The engine doesn't know "wood burns" — it knows "this material's ignition point was exceeded."
- **Phase transitions:** When temperature crosses `material.melting_point`, the engine transforms solid to liquid. Ice at 10001°U becomes water. Steel at 12719°U becomes molten steel. Same code path, same rule, different data.

**This is Principle 8 in its purest form.** The engine is a physics calculator operating on property bags. Object behavior is entirely data-determined.

### 1.5 The "Raw Files" System — DF's Equivalent of Our .lua Files

| Feature | DF Raw Files | Our .lua Files |
|---|---|---|
| **Format** | Custom token syntax `[TOKEN:VALUE]` | Lua table literals `{ key = value }` |
| **Execution** | Parsed at load time, no runtime code | Executed in sandbox, supports functions |
| **Templates** | `USE_MATERIAL_TEMPLATE`, `CREATURE_VARIATION` | `template = "name"` with deep_merge |
| **Extensibility** | New files parsed automatically | New files loaded by file scan |
| **Callbacks** | None — pure data, no logic | Full Lua functions (`on_look`, `on_tick`, etc.) |
| **Sandboxing** | N/A (not code) | Restricted Lua sandbox |

**Critical difference:** DF raws are purely declarative — no embedded logic. All behavior emerges from the engine's interpretation of numeric properties. Our `.lua` files embed both data AND behavior (callback functions, guard logic). This is more powerful but less "pure" — our objects can contain logic that subverts engine generality.

---

## 2. DF Object/Entity Model

### 2.1 How DF Defines Entities

DF defines five major entity categories in its raws:

1. **Creatures** — `[CREATURE:DWARF]` with body plans, castes, materials, behaviors
2. **Items** — `[ITEM_WEAPON:SWORD_SHORT]`, `[ITEM_ARMOR:MAIL_SHIRT]`
3. **Buildings** — workshops, furnaces, constructions
4. **Plants** — trees, shrubs, crops with growth stages and materials
5. **Entities** — civilizations with culture, tech, ethics

### 2.2 Creature Composition: The Deep Architecture

DF's creature system is its most impressive architectural achievement. A creature is composed hierarchically:

```
CREATURE definition
  └─ BODY template (body structure: humanoid, quadruped, etc.)
      └─ Body parts (head, torso, arms, legs, eyes, organs...)
          └─ BODY_DETAIL_PLAN (tissue layering)
              └─ Tissue layers (skin → fat → muscle → bone)
                  └─ Material templates (each tissue has material properties)
  └─ CREATURE_VARIATION (reusable modification macros)
  └─ CASTE definitions (male/female/other variations)
```

**Example:** A dwarf's arm is:
- **Part** defined in `body_default.txt` as `[BP:RLA:right lower arm:...]`
- **Layers** applied by `BODY_DETAIL_PLAN:STANDARD_MAMMAL_TISSUE_LAYERS`
  - Outer: skin (thickness: 1mm, material: SKIN_TEMPLATE)
  - Under: fat (thickness: 5mm, material: FAT_TEMPLATE)
  - Under: muscle (thickness: 20mm, material: MUSCLE_TEMPLATE)
  - Core: bone (material: BONE_TEMPLATE)

When a sword strikes this arm, the engine traces through each tissue layer, comparing the sword's material properties against each layer's material properties, calculating penetration depth, determining whether bone is reached, whether arteries are severed, etc.

**This is emergence:** The game doesn't have "arm damage code." It has material-vs-material physics and anatomical structure. The result is a wound simulation of staggering detail — all from property interactions.

### 2.3 Raws vs Runtime Instances

| Concept | DF | Our Engine |
|---|---|---|
| **Template** | Raw definition (CREATURE:DWARF) | Base object .lua file |
| **Instance** | Runtime entity with state (specific dwarf "Urist") | Registry entry with unique ID |
| **Identity** | Internal integer ID + historical figure record | String ID + GUID |
| **State** | Continuous properties (temperature, wear counter, mood value) | Discrete FSM state (`_state = "lit"`) |
| **Persistence** | Save file serializes all instance state | Not yet implemented |

### 2.4 Object State: Temperature, Damage, Wear, Decay

DF tracks extensive **continuous state** on every instance:

- **Temperature** — numeric value (°U), recalculated per tile update. Drives phase transitions.
- **Wear** — 0 to ~3.2M wear points. Each ~806,400 points increments visual wear level (x → X → XX → destroyed).
- **Contaminants** — substances stuck to items/creatures (blood, mud, venom). Tracked as material + amount. Can transfer by contact.
- **Quality** — craftsmanship level (1-5 stars + artifact). Affects value, not physical properties.
- **Damage** — per-tissue-layer injury tracking on creatures. Each layer has separate damage state.

**Contrast with our engine:** We model state as **discrete FSM states** (unlit/lit/spent) rather than continuous values. Our candle doesn't have a numeric wax_remaining — it has a timer that triggers state transitions. This is simpler and sufficient for text-based IF, but limits the emergent property interactions DF achieves.

### 2.5 Emergent Behaviors from Property Interactions

DF's most celebrated feature is that complex behaviors emerge from simple property rules:

| Emergent Behavior | Underlying Properties |
|---|---|
| Fire spreads to wood but not stone | Materials have `IGNITE_POINT` or don't |
| Iron rusts when wet | Material reaction rules + contaminant system |
| Forgotten beast melts copper armor | Beast temperature > copper's melting point |
| Dwarf freezes in blizzard | Temperature propagation + creature heat tolerance |
| Silver warhammer crushes skulls | Silver's extreme density × weapon momentum |
| Wooden furniture floats in flood | Wood density < water density |

**None of these are special-cased.** Each arises from the interaction of numeric material properties with generic physics simulation.

---

## 3. DF FSM / State Management

### 3.1 State Transitions: Continuous vs Discrete

DF does NOT use formal Finite State Machines in the way our engine does. Instead, it uses **continuous property simulation with threshold-based transitions**:

```
Our Engine (discrete):     unlit ──[light]──→ lit ──[timer]──→ spent
DF (continuous):           temperature rises → crosses melting_point → material changes phase
```

In DF, "state" is the current value of a property, and "transition" is the property crossing a threshold defined by material data. There is no named state like "melting" — there's just `current_temp > melting_point`, which triggers the phase change system.

### 3.2 Temperature as the Universal State Driver

DF uses a custom temperature scale (degrees Urist, °U):
- Range: 0 to 60,000 (unsigned 16-bit)
- Water freezes at 10,000°U, boils at 10,180°U
- Magma sits at 12,000°U
- Steel melts at 12,718°U

Temperature propagates tile-by-tile. Each update:
1. Tile temperature adjusts toward neighbors (heat diffusion)
2. Every item/material on the tile checks its thresholds
3. If `temp > melting_point` → solid becomes liquid
4. If `temp > boiling_point` → liquid becomes gas
5. If `temp > ignition_point` → material catches fire, generating more heat

**This creates cascading effects:** Fire heats tiles → adjacent materials reach ignition → fire spreads → more heat → more ignition. A single magma breach can destroy an entire wooden fortress through pure property propagation.

### 3.3 Creature AI: Needs-Based Goal System

DF's creature AI is not GOAP (Goal-Oriented Action Planning) in the textbook sense, but shares the spirit:

1. **Needs evaluation** — Each creature has needs (hunger, thirst, sleep, social, safety). Unmet needs generate urgency scores.
2. **Goal generation** — The highest-priority unmet need generates a goal ("find drink", "sleep", "flee danger").
3. **Task matching** — Goals are matched against available jobs (from the global job list) and resource availability.
4. **Pathfinding** — A* algorithm calculates route to task target.
5. **Execution + interrupts** — Creature executes task. High-priority interrupts (combat, panic) can preempt.

**Key architectural choice:** DF's AI is purely tick-driven, not event-driven. Each creature re-evaluates its state every tick. This is computationally expensive but produces natural-looking behavior as priorities shift moment to moment.

**Our GOAP comparison:** Our parser decomposes player commands into goals, and the engine resolves them against available actions. DF does the inverse — NPC goals are internally generated from needs, and resolved against available world state. Both are goal-oriented; ours is player-facing, DF's is NPC-facing.

### 3.4 Cascade Effects

DF's most DF-like behavior is cascading state changes. One event triggers others:

```
Rain falls on fortress
  → tile.wetness increases
  → iron items on tile: contaminant "water" applied
  → if water contaminant + iron material → rust reaction triggers
  → iron item wear increases
  → if wear > threshold → item quality degrades or item destroyed
```

Another classic cascade:

```
Dwarf's friend dies
  → dwarf.stress increases
  → if stress > threshold → dwarf enters "tantrum" state
  → tantrum dwarf attacks nearest creature
  → attacked creature retaliates
  → original tantrum dwarf may die
  → THEIR friends get stressed
  → cascade continues ("tantrum spiral")
```

These cascades are not scripted. They emerge from the interaction of independent systems (weather + material reactions, stress + combat + social bonds).

---

## 4. Comparison: Our Engine vs DF

### 4.1 Object Definition

| Aspect | Dwarf Fortress | Our Engine | Gap / Opportunity |
|---|---|---|---|
| **Format** | Custom token syntax `[TOKEN:VALUE]` | Lua table literals with functions | Our format is more expressive; DF is more constrainable |
| **Templates** | `MATERIAL_TEMPLATE`, `CREATURE_VARIATION`, `BODY_DETAIL_PLAN` — 3+ composition systems | Single `template` field with `deep_merge` | DF has richer composition; we could add variation macros |
| **Inheritance** | Multi-layer: template → creature → caste → instance | Two-layer: template → base → instance | Sufficient for IF; DF's depth is for anatomy/biology |
| **Embedded logic** | Zero — pure declarative data | Full Lua callbacks (`on_look`, `on_tick`, guards) | Our approach is more powerful but less "pure" |
| **Material system** | First-class citizen: 20+ numeric properties per material | `material = "wax"` — string label, no properties | **Major gap.** Our materials are names, not property bags |
| **Body/anatomy** | Full anatomical hierarchy with tissue layers | None — objects are monolithic | Not needed for IF, but composite system is related |

### 4.2 Property Mutation

| Aspect | Dwarf Fortress | Our Engine | Gap / Opportunity |
|---|---|---|---|
| **Mechanism** | Continuous numeric simulation | FSM state swap + mutate field | DF simulates; we transition. Both valid. |
| **Granularity** | Per-property continuous values (temp, wear, stress) | Per-state property overlays | Our `mutate` field closes this gap for discrete changes |
| **Material physics** | Engine calculates from material properties | Engine executes metadata declarations | DF derives behavior; we declare it |
| **Cascading** | Automatic via property thresholds | Explicit via `on_transition` callbacks | We could add property watchers for cascades |
| **Arbitrary mutation** | Limited — engine defines which properties matter | Unlimited — `mutate` can change any property | **We win here.** Our `mutate` field is more flexible |

### 4.3 State Management

| Aspect | Dwarf Fortress | Our Engine | Gap / Opportunity |
|---|---|---|---|
| **Model** | Continuous values with threshold transitions | Discrete named FSM states | Both appropriate for their domains |
| **Temperature** | Full tile-based thermal simulation | Not applicable (text game) | N/A |
| **Timers** | Global tick counter, time-stepped | Per-object timer with pause/resume | Our timer system is well-designed for IF |
| **Wear/decay** | Numeric wear counter per item | Not implemented | Could add `wear` as mutable property |
| **Phase transitions** | Automatic from temperature thresholds | Explicit FSM transitions | Could add threshold-based auto-transitions |

### 4.4 Emergent Behavior

| Aspect | Dwarf Fortress | Our Engine | Gap / Opportunity |
|---|---|---|---|
| **Fire** | Emerges from ignition_point + temperature propagation | Would require explicit FSM transitions per object | **Key gap.** Biggest difference in philosophy |
| **Water/fluid** | Cellular automata with pressure | Not applicable | N/A for text games |
| **Social cascades** | Mood/stress → tantrum → violence → more stress | Not yet implemented | NPC system could adopt needs model |
| **Material interactions** | Automatic from property matching | Object-specific callback logic | Could add material property resolution |
| **Weather effects** | Temperature/rain affect all materials generically | N/A | Text description changes per weather feasible |

### 4.5 Instance Management

| Aspect | Dwarf Fortress | Our Engine | Gap / Opportunity |
|---|---|---|---|
| **Identity** | Integer IDs + historical figure records | String IDs + GUID in registry | Both sufficient |
| **Tracking** | Hundreds of thousands of entities tracked | Room-scoped ticking + shared registry | Our approach is correct for scope |
| **History** | Full historical record per entity | None | LLM-generated universe templates fill this role differently |
| **Persistence** | Custom binary save format | Not yet implemented | Serialization planned |
| **Performance** | FPS death at scale — single-threaded | Command-based, no tick pressure | **We win.** Turn-based avoids DF's perf crisis |

### 4.6 Perception / Sensory

| Aspect | Dwarf Fortress | Our Engine | Gap / Opportunity |
|---|---|---|---|
| **Visual** | Tile-based 2D grid (ASCII/sprites) | Text descriptions, multi-state | Different modalities entirely |
| **Sensory depth** | Primarily visual; some text logs | **Five senses: look, feel, smell, taste, listen** | **We win massively.** DF barely does non-visual |
| **Darkness** | Binary light/dark per tile | Rich darkness model: sensory verbs work without light | **We win.** Our darkness gameplay is unique |
| **State-driven description** | Tile appearance changes with material state | Per-state descriptions, room_presence, sensory callbacks | Both strong; ours is more expressive per object |

### 4.7 Parser / Interaction

| Aspect | Dwarf Fortress | Our Engine | Gap / Opportunity |
|---|---|---|---|
| **Input** | Menu-based designations + keyboard shortcuts | Natural language parser (rule + embedding) | Completely different paradigms |
| **Expressiveness** | Limited to pre-defined menu options | Unlimited natural language (with fallback) | **We win.** NLP is categorically richer |
| **Accessibility** | Notorious difficulty | Parser + tap-to-suggest (mobile) | **We win.** Mobile-first design |
| **GOAP integration** | Creatures use need/goal system internally | Player commands decomposed into goals | Both goal-oriented; different directions |

---

## 5. Lessons We Can Adopt

### 5.1 What DF Patterns Could Enhance Our Architecture

#### **ADOPT: Material Property Tables** ⭐ HIGH PRIORITY

Our biggest gap. Currently `material = "wax"` is a string label with no properties. Adopting DF's approach:

```lua
-- Current (our engine):
{ material = "wax", weight = 1, ... }

-- DF-inspired upgrade:
materials = {
    wax = {
        density = 900,
        melting_point = 60,    -- Celsius (simplified)
        ignition_point = 230,
        hardness = 2,
        flexibility = 0.8,
        value = 1,
    },
    steel = {
        density = 7850,
        melting_point = 1370,
        ignition_point = nil,  -- Won't burn
        hardness = 9,
        flexibility = 0.3,
        value = 30,
        sharpness_max = 0.95,
    },
}
```

**Impact on Principle 8:** Objects wouldn't declare `casts_light = true` when lit — they'd have `temperature > ignition_point` and the engine would derive light-casting from temperature. But for a text game, this level of physics simulation is likely overkill. **The right move: material property tables for DESCRIPTION generation and GUARD resolution, not for full physics simulation.**

```lua
-- Practical adoption for our engine:
transitions = {
    melt = {
        from = "solid", to = "melted",
        guard = function(obj, ctx)
            local mat = materials[obj.material]
            return ctx.temperature > mat.melting_point
        end,
        message = function(obj)
            return "The " .. obj.material .. " " .. obj.name .. " melts into a puddle."
        end,
    }
}
```

#### **ADOPT: Template Composition / Variation Macros** ⭐ MEDIUM PRIORITY

DF's `CREATURE_VARIATION` system lets you define reusable modifications:

```
-- DF concept:
[CREATURE_VARIATION:FIRE_BREATHING]
  [CV_ADD_TAG:FIREBREATH_ATTACK]
  [CV_ADD_TAG:FIRE_IMMUNE]
```

Our equivalent could be a Lua-based variation system:

```lua
-- variations/fire_creature.lua
return function(base)
    base.categories = base.categories or {}
    table.insert(base.categories, "fire_immune")
    base.attacks = base.attacks or {}
    table.insert(base.attacks, "fire_breath")
    return base
end
```

This would support D-17 (Universe Templates) by enabling parametric world generation.

#### **ADOPT: Threshold-Based Auto-Transitions** ⭐ HIGH PRIORITY

DF's property-threshold model maps beautifully to our `mutate` + `guard` system:

```lua
-- Add to transition definitions:
transitions = {
    auto_rust = {
        trigger = "auto",
        from = "intact", to = "rusted",
        condition = function(obj)
            return obj.wetness and obj.wetness > 0.5
                and obj.material == "iron"
        end,
        mutate = { weight = function(cur) return cur * 0.95 end },
        message = "Rust blooms across the iron surface.",
    }
}
```

This brings DF-style emergence (rain → wet → rust) into our FSM framework without abandoning discrete states.

#### **CONSIDER: Wear as a Numeric Property** 🟡 MEDIUM PRIORITY

Instead of binary states (intact/broken), track numeric wear:

```lua
{
    wear = 0,           -- 0.0 = pristine, 1.0 = destroyed
    wear_rate = 0.001,  -- per-use wear increment
    wear_thresholds = {
        { at = 0.3, apply = { description = "slightly worn ..." } },
        { at = 0.7, apply = { description = "heavily worn ..." } },
        { at = 1.0, trigger = "break" },
    }
}
```

This is a hybrid of DF's continuous wear and our discrete FSM approach.

#### **CONSIDER: Contaminant/Tag System** 🟡 LOW PRIORITY

DF's contaminant system (blood, mud, venom sticking to objects) maps to our property mutation:

```lua
-- Object can accumulate contaminant tags:
contaminants = { "blood", "mud" },
-- Engine checks contaminants for verb resolution:
-- "examine sword" → "A rusty sword, smeared with dried blood."
```

### 5.2 What DF Does That We Should NOT Copy

#### **AVOID: Full Physics Simulation** 🛑

DF's temperature-per-tile, fluid dynamics, and real-time physics calculations cause the infamous "FPS death" — performance collapse as fortress complexity grows. DF's simulation is single-threaded and cannot effectively use modern multi-core CPUs. At 200+ dwarves, FPS can drop below 10.

**For a mobile-first, turn-based text game, continuous physics simulation is:**
- Unnecessary (no visual physics to render)
- Expensive (mobile CPUs are limited)
- Hostile to the medium (text describes states, not gradients)

**Keep our FSM approach.** Discrete states are the correct abstraction for text-based IF.

#### **AVOID: Unbounded Entity Tracking** 🛑

DF tracks every entity that ever existed — every historical figure, every artifact, every spatter of blood. This causes memory to grow without bound and is a major contributor to late-game performance collapse.

**Our approach (D-45: FSM Tick Scope)** — only ticking objects in the current room — is architecturally superior for our use case. We should never adopt DF's "simulate everything everywhere" model.

#### **AVOID: Single-File Codebase Sprawl** 🛑

DF grew to 700,000 lines of C++ largely maintained by one developer with minimal modularization. Our engine's separation into `engine/` (FSM, registry, containment, mutation) and `meta/` (object definitions) is already cleaner than DF's architecture.

#### **AVOID: Pure-Data Rigidity** ⚠️

DF's raw files cannot contain logic — they're pure data tokens. This means any behavior that doesn't fit the engine's built-in simulation models requires engine code changes. Our `.lua` files with embedded callbacks are more flexible. **Don't give up embedded logic for "purity."**

### 5.3 What WE Do Better Than DF

| Area | Why We're Better |
|---|---|
| **Sensory depth** | Five senses (look/feel/smell/taste/listen) vs DF's primarily visual output. Our darkness model is unique in gaming. |
| **Natural language interaction** | Free-form NLP parser vs DF's opaque menu system. Orders of magnitude more expressive. |
| **Mobile-first accessibility** | Tap-to-suggest, abbreviations, mobile-optimized. DF is notoriously inaccessible. |
| **Embedded behavior logic** | Lua callbacks in object definitions. DF requires engine changes for novel behavior. |
| **Performance model** | Turn-based, command-driven. Zero "FPS death" risk. |
| **Mutation flexibility** | `mutate` field can change ANY property. DF's mutations are engine-determined. |
| **Self-modifying objects** | `loadstring` + registry swap enables arbitrary runtime transformation. DF objects can't redefine themselves. |
| **Separation of concerns** | Engine / meta / templates cleanly separated. DF is monolithic C++. |

### 5.4 Concrete Recommendations for Principle 8 and the Mutate Field

**Principle 8 already captures the DF philosophy.** The current wording — "The Engine Executes Metadata; Objects Declare Behavior" — directly mirrors DF's "engine operates on property bags, not named types." No changes needed to the principle itself.

**For the `mutate` field (D-MUTATE-PROPOSAL):**

1. **Proceed as proposed.** The `mutate` field on transitions is the correct mechanism for DF-style property mutation within our discrete FSM framework.

2. **Add material property resolution.** When `mutate` references a material-dependent value, look it up from a materials table:
   ```lua
   mutate = {
       sharpness = { from_material = "material", property = "sharpness_max" }
   }
   ```

3. **Add threshold-triggered auto-transitions.** Extend the FSM tick to check property thresholds:
   ```lua
   auto_transitions = {
       { when = function(obj) return obj.wetness > 0.5 end,
         trigger = "rust_begins" }
   }
   ```

4. **Keep states discrete.** Don't try to replicate DF's continuous simulation. Use `mutate` to change numeric values, and `guard`/`auto_transition` conditions to check thresholds. This gives us DF-style emergence within our FSM paradigm.

---

## 6. DF Development History & Philosophy

### 6.1 Tarn Adams's Design Philosophy

Tarn Adams published his simulation principles in *Game AI Pro 2* (Chapter 41). The four key principles:

1. **Don't Overplan Your Model** — Start simple, iterate. Let emergence surprise you. Over-specification kills emergent behavior.

2. **Break Down and Understand the System** — Decompose complex systems into fundamental interacting elements. DF's biome system doesn't define biomes — it defines temperature, rainfall, and drainage, and biomes emerge from their interaction.

3. **Don't Overcomplicate** — Track only properties that meaningfully affect the simulation. Not every detail needs modeling. Drop variables that don't produce richer interaction or storytelling.

4. **Base Your Model on Real-World Analogs** — Use simplified real-world physics as the foundation. Players can then apply real-world intuition to predict game behavior, creating a sense of coherent reality.

**The meta-principle:** Build systems that interact, not behaviors that are scripted. Emergence is not a bug — it's the product.

### 6.2 Development Timeline

| Period | Milestone | Architectural Significance |
|---|---|---|
| **2002** | Development begins (spin-off from "Slaves to Armok") | Foundation: C/C++, simulation-first design |
| **2006** | First public alpha release (ASCII) | Community growth, donation model |
| **2007–2010** | Z-levels added, water simulation, emotions | 3D simulation layer, fluid cellular automata |
| **2010–2012** | Necromancers, vampires, adventure mode overhaul | Historical figure system, persistent world history |
| **2012–2020** | "Feature arcs" — structured development roadmap | Memory/pathfinding optimization cycles |
| **2022** | Steam release with graphics (Kitfox Games) | First multi-developer work, SDL/OpenGL rendering layer |
| **2023–2026** | Ongoing: magic, sieges, diplomacy, Lua scripting | Modding layer evolution, first scripting language addition |

### 6.3 Key Architectural Decisions

1. **Everything is a property bag.** No class hierarchies. Entities are bags of typed properties. This enables generic simulation.

2. **Raws are the source of truth.** All game content is defined in external data files. The engine is content-agnostic.

3. **Single-threaded simulation.** All systems run sequentially on one thread. This avoids concurrency bugs but creates the FPS ceiling. A deliberate tradeoff: correctness over performance.

4. **Simulate the world, not the game.** DF simulates physics, biology, psychology, and sociology. "Game mechanics" emerge from these simulations rather than being designed directly.

5. **History persists.** Every entity's history is tracked permanently. This creates narrative richness but unbounded memory growth.

### 6.4 The Cost of Depth

| Cost | Impact |
|---|---|
| **Performance** | "FPS death" at scale. Single-threaded, 700K lines, no parallelism. Large forts become unplayable. |
| **Complexity** | 20+ years of accumulated systems. Bug surface area is enormous. |
| **Accessibility** | Notoriously difficult to learn. Steam version helped, but the learning curve remains steep. |
| **Development speed** | Single primary developer. Features take years. The magic/myth system has been in development for 5+ years. |
| **Memory** | Unbounded entity history consumes RAM. Old worlds can exceed gigabytes. |

---

## 7. Sources

### Primary Sources

1. Adams, Tarn. "Simulation Principles from Dwarf Fortress." *Game AI Pro 2*, Chapter 41. CRC Press, 2015. http://www.gameaipro.com/GameAIPro2/GameAIPro2_Chapter41_Simulation_Principles_from_Dwarf_Fortress.pdf

2. Bay 12 Games. "Dwarf Fortress Development." Official development blog. https://www.bay12games.com/dwarves/dev.html

3. Stack Overflow Blog. "700,000 lines of code, 20 years, and one developer: How Dwarf Fortress is built." December 2021. https://stackoverflow.blog/2021/12/31/700000-lines-of-code-20-years-and-one-developer-how-dwarf-fortress-is-built/

### DF Wiki — Technical Documentation

4. "Material Science." Dwarf Fortress Wiki. https://dwarffortresswiki.org/Material_science

5. "Material." Dwarf Fortress Wiki. https://dwarffortresswiki.org/material

6. "Steel." Dwarf Fortress Wiki. https://dwarffortresswiki.org/steel

7. "Raw file." Dwarf Fortress Wiki. https://dwarffortresswiki.org/index.php/Raw_file

8. "Temperature." Dwarf Fortress Wiki. https://dwarffortresswiki.org/index.php/Temperature

9. "Fire." Dwarf Fortress Wiki. https://dwarffortresswiki.org/index.php/Fire

10. "Wear." Dwarf Fortress Wiki. https://dwarffortresswiki.org/wear

11. "Contaminant." Dwarf Fortress Wiki. https://dwarffortresswiki.org/Contaminant

12. "Flow." Dwarf Fortress Wiki. https://dwarffortresswiki.org/index.php/Flow

13. "Pressure." Dwarf Fortress Wiki. https://dwarffortresswiki.org/index.php/Pressure

14. "Anatomy." Dwarf Fortress Wiki. https://dwarffortresswiki.org/index.php/Anatomy

15. "Wound." Dwarf Fortress Wiki. https://dwarffortresswiki.org/index.php/Wound

16. "Body detail plan token." Dwarf Fortress Wiki. https://dwarffortresswiki.org/index.php/Body_detail_plan_token

17. "Tissue definition token." Dwarf Fortress Wiki. https://dwarffortresswiki.org/index.php/DF2014:Tissue_definition_token

18. "Path." Dwarf Fortress Wiki. https://dwarffortresswiki.org/index.php/Path

19. "Modding." Dwarf Fortress Wiki. https://dwarffortresswiki.org/Modding

20. "Version history." Dwarf Fortress Wiki. https://dwarffortresswiki.org/index.php/Version_history

21. "Maximizing framerate." Dwarf Fortress Wiki. https://dwarffortresswiki.org/index.php/Maximizing_framerate

22. "Legends." Dwarf Fortress Wiki. https://dwarffortresswiki.org/legends

23. "Entity token." Dwarf Fortress Wiki. https://dwarffortresswiki.org/index.php/Entity_token

### Industry & Academic Sources

24. GamesIndustry.biz. "Slow and steady wins the race: How Dwarf Fortress reinvented itself after 20 years." https://www.gamesindustry.biz/slow-and-steady-wins-the-race-how-dwarf-fortress-reinvented-itself-after-20-years

25. Game Developer (Gamasutra). "Interview: The Making Of Dwarf Fortress." https://www.gamedeveloper.com/design/interview-the-making-of-dwarf-fortress

26. Lehner, Niilo. "Systems-Based Game Design in Dwarf Fortress." Thesis. https://www.theseus.fi/bitstream/handle/10024/814557/Lehner_Niilo.pdf

27. GameDev StackExchange. "How does Dwarf Fortress keep track of so many entities without losing performance?" https://gamedev.stackexchange.com/questions/32813/how-does-dwarf-fortress-keep-track-of-so-many-entities-without-losing-performanc

28. PC Gamer. "Dwarf Fortress dwarves are 'more human than human,' creator says." https://www.pcgamer.com/games/sim/dwarf-fortress-dwarves-are-more-human-than-human-creator-says/

29. DFHack Modding Guide. https://docs.dfhack.org/en/stable/docs/guides/modding-guide.html

30. Paprika Magazine. "Interview With Tarn Adams." https://paprikamagazine.com/folds/phantasy/interview-with-tarn-adams

31. GDC Vault. "Practices in Procedural Generation" (Tarn Adams). https://www.gdcvault.com/play/1023372/Practices-in-Procedural

32. Wikipedia. "Dwarf Fortress." https://en.wikipedia.org/wiki/Dwarf_Fortress

33. Putnam3145. "DF-Raws" (reference repository). https://github.com/Putnam3145/DF-Raws

34. niezbop. "DwarfFortress-raws" (raw file collection). https://github.com/niezbop/DwarfFortress-raws

---

*This research supports D-DF-ARCHITECTURE and validates our Principle 8 direction. The key takeaway: DF proves property-bag simulation works at scale. Our engine already has the right DNA — the `mutate` field and material property tables are the natural next steps to close the remaining gaps, without falling into DF's performance and complexity traps.*
