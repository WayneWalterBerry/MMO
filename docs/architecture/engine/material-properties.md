# Material Properties Engine Architecture

**Version:** 1.0  
**Date:** 2026-07-19  
**Author:** Frink (Researcher)  
**Audience:** Architecture team, engine developers  
**Status:** Research Complete — Ready for Architecture Review  

---

## Executive Summary

Our engine's biggest gap relative to Dwarf Fortress is that **materials are labels, not property bags**. When we write `material = "wax"`, the engine stores a string — it doesn't know that wax melts at 60°C, burns at 230°C, is soft, or floats on water. Dwarf Fortress assigns 20+ numeric properties to every material, and the simulation engine derives all behavior from those numbers without ever knowing what "wax" or "steel" means.

This document specifies how to add **numeric material properties** and **threshold-based auto-transitions** to our engine, and analyzes whether this fits within Principle 8 or requires new architectural capabilities.

**Key finding:** Material properties can be implemented WITHIN the existing Principle 8 framework. No new engine principles are needed — but the engine does need a **material registry** (a new data layer) and an extension to the **FSM tick loop** (threshold checking alongside timer expiry).

---

## 1. How Dwarf Fortress Implements Material Properties

### 1.1 The RAW File Format

DF defines materials in plaintext "raw" files using a custom token syntax. Every material is a property bag of 20+ numeric values:

```
[INORGANIC:STEEL]
  [USE_MATERIAL_TEMPLATE:METAL_TEMPLATE]
  [STATE_NAME_ADJ:ALL_SOLID:steel]
  [COLOR:0:7:1]
  [MATERIAL_VALUE:30]
  [SPEC_HEAT:500]
  [MELTING_POINT:12718]           -- degrees Urist (~1370°C)
  [BOILING_POINT:14968]
  [SOLID_DENSITY:7850]            -- kg/m³
  [IMPACT_YIELD:2520]
  [IMPACT_FRACTURE:3900]
  [IMPACT_ELASTICITY:150]
  [SHEAR_YIELD:720]
  [SHEAR_FRACTURE:1720]
  [SHEAR_ELASTICITY:56]
  [IGNITE_POINT:NONE]
```

**Property categories in DF:**

| Category | Properties | Engine Use |
|----------|-----------|------------|
| **Mechanical** | Impact/shear yield, fracture, elasticity | Combat damage calculation |
| **Thermal** | Melting point, boiling point, ignition point, specific heat | Phase transitions, fire propagation |
| **Physical** | Solid/liquid density, max edge | Weight, buoyancy, weapon sharpness |
| **Economic** | Material value | Trade, wealth |
| **Display** | Color, state name adjectives (solid/liquid/gas) | Rendering, description |

**Critical insight:** These are **continuous numeric values**, not boolean flags. A steel sword doesn't "know" it's sharp — it inherits steel's `SHEAR_FRACTURE:1720` and `MAX_EDGE:10000`, and the combat engine calculates cutting ability from those numbers.

> **Source:** Dwarf Fortress Wiki, "Material definition token" — https://dwarffortresswiki.org/index.php/Material_definition_token

### 1.2 Template Inheritance

DF uses material templates as inheritance bases:

```
[MATERIAL_TEMPLATE:METAL_TEMPLATE]
  [IS_METAL]
  [ITEMS_WEAPON]
  [ITEMS_ARMOR]
  [SPEC_HEAT:500]
  ... shared metal defaults ...
```

Individual metals inherit and override:

```
[INORGANIC:STEEL]
  [USE_MATERIAL_TEMPLATE:METAL_TEMPLATE]
  [SOLID_DENSITY:7850]       -- Override
  [SHEAR_FRACTURE:1720]      -- Override
```

**Our equivalent:** We already have `template = "furniture"` inheritance. Material property tables would use the same pattern — a base template with per-material overrides.

> **Source:** DF Wiki, "Raw file" — https://dwarffortresswiki.org/index.php/Raw_file

### 1.3 How the Engine Uses Material Properties

The DF engine has **zero knowledge of object types**. It operates purely on numeric properties:

- **Combat:** When a steel sword strikes leather armor, the engine calculates momentum from weapon weight × velocity, compares against armor's `IMPACT_YIELD` and `SHEAR_FRACTURE`. It doesn't know "sword" or "leather."
- **Fire:** When a tile reaches a temperature, every item checks `material.IGNITE_POINT`. Wood ignites. Stone doesn't. Same code path.
- **Phase transitions:** When temperature crosses `material.MELTING_POINT`, solid becomes liquid. Ice→water. Steel→molten steel. Same rule, different data.

This is Principle 8 in its purest form: the engine is a physics calculator operating on property bags.

---

## 2. How Threshold-Based Auto-Transitions Work

### 2.1 The DF Model: Continuous Simulation

DF uses continuous property simulation with threshold-based transitions:

```
DF (continuous):    temperature rises → crosses melting_point → material changes phase
Our Engine (discrete): unlit ──[LIGHT]──→ lit ──[timer]──→ spent
```

In DF, "state" is the current value of a property. "Transition" is a property crossing a threshold defined by material data. There's no named state "melting" — just `current_temp > melting_point`, which triggers the phase change system.

**Temperature propagation each tick:**
1. Tile temperature adjusts toward neighbors (heat diffusion)
2. Every item/material on the tile checks its thresholds
3. If `temp > melting_point` → solid becomes liquid
4. If `temp > boiling_point` → liquid becomes gas
5. If `temp > ignition_point` → material catches fire, generating more heat

This creates **cascading effects:** Fire heats tiles → adjacent materials reach ignition → fire spreads → more heat → more ignition. A single magma breach can destroy an entire wooden fortress.

### 2.2 Comparison: BotW Chemistry Engine

Nintendo's Breath of the Wild implements a simpler but equally effective version. Three rules:

1. Elements (fire, water, electricity, wind) can change the state of materials
2. Elements can affect each other's state
3. Materials do not change each other's state directly

Objects have properties: metal conducts electricity, wood burns, ice melts. When lightning strikes, a metal weapon near enemies conducts electricity. A wooden arrow lit by a torch becomes a fire arrow. Simple property rules, enormous emergent space.

> **Source:** GamesBeat, "BotW makes chemistry just as important as physics" — https://gamesbeat.com/the-legend-of-zelda-breath-of-the-wild-makes-chemistry-just-as-important-as-physics/

### 2.3 Comparison: Noita's Pixel Materials

Noita simulates every pixel with material properties (density, flammability, conductivity, solidity). Cellular automata rules drive interactions: oil floats on water (density), fire spreads to flammable neighbors, lava melts ice. All emergent from simple per-material numeric properties.

> **Source:** 80.lv, "Noita: a Game Based on Falling Sand Simulation" — https://80.lv/articles/noita-a-game-based-on-falling-sand-simulation  
> **Source:** GDC Vault, "Exploring the Tech and Design of Noita" — https://braindump.jethro.dev/posts/gdc_vault_exploring_the_tech_and_design_of_noita/

### 2.4 Comparison: Caves of Qud

Caves of Qud uses material properties for object interactions — acid corrodes metals, fire burns organics, liquids have weight/temperature/flash point. Materials interact through property-matching rules. Every liquid pool, gas cloud, and object surface participates in the same interaction system.

> **Source:** GameDeveloper, "Tapping into procedural generation in Caves of Qud" — https://www.gamedeveloper.com/design/tapping-into-the-potential-of-procedural-generation-in-caves-of-qud

### 2.5 Our Model: Discrete FSM + Property Thresholds (Hybrid)

We don't need DF's continuous physics simulation — we're a text game, not a tile simulator. But we can adopt the **threshold-check pattern** within our discrete FSM:

```
Our hybrid:  object has numeric properties → FSM tick checks thresholds → triggers transitions
```

**The key difference from DF:** We check thresholds at FSM tick time (once per player command), not continuously. This is correct for a text-based IF game where time advances discretely.

---

## 3. Engine Changes Required

### 3.1 New Data Layer: Material Registry

A new Lua module that maps material names to property tables:

```lua
-- src/engine/materials/init.lua
local materials = {
    wax = {
        density = 900,           -- kg/m³
        melting_point = 60,      -- °C (simplified from DF's Urist scale)
        ignition_point = 230,    -- °C
        hardness = 2,            -- 1-10 Mohs-inspired scale
        flexibility = 0.8,       -- 0.0 = rigid, 1.0 = fully flexible
        absorbency = 0.0,        -- 0.0 = waterproof, 1.0 = sponge
        opacity = 0.6,           -- 0.0 = transparent, 1.0 = opaque
        value = 1,               -- economic value multiplier
        flammability = 0.7,      -- 0.0 = fireproof, 1.0 = flash-combustible
        conductivity = 0.0,      -- 0.0 = insulator, 1.0 = conductor
    },
    iron = {
        density = 7870,
        melting_point = 1538,
        ignition_point = nil,    -- won't burn
        hardness = 8,
        flexibility = 0.3,
        absorbency = 0.0,
        opacity = 1.0,
        value = 5,
        flammability = 0.0,
        conductivity = 0.8,
        rust_susceptibility = 0.9,
    },
    fabric = {
        density = 300,
        melting_point = nil,     -- chars, doesn't melt
        ignition_point = 250,
        hardness = 1,
        flexibility = 1.0,
        absorbency = 0.8,
        opacity = 0.3,
        value = 2,
        flammability = 0.6,
        conductivity = 0.0,
    },
    wood = {
        density = 600,
        melting_point = nil,
        ignition_point = 300,
        hardness = 4,
        flexibility = 0.2,
        absorbency = 0.3,
        opacity = 1.0,
        value = 3,
        flammability = 0.5,
        conductivity = 0.0,
    },
    glass = {
        density = 2500,
        melting_point = 1400,
        ignition_point = nil,
        hardness = 6,
        flexibility = 0.0,
        absorbency = 0.0,
        opacity = 0.1,
        value = 4,
        flammability = 0.0,
        conductivity = 0.0,
        fragility = 0.9,        -- 0.0 = unbreakable, 1.0 = shatters easily
    },
    brass = {
        density = 8500,
        melting_point = 930,
        ignition_point = nil,
        hardness = 6,
        flexibility = 0.1,
        absorbency = 0.0,
        opacity = 1.0,
        value = 8,
        flammability = 0.0,
        conductivity = 0.6,
    },
}
```

**Design decision:** Use real-world-inspired units where possible (°C for temperature, Mohs-inspired 1-10 for hardness, 0.0-1.0 normalized for ratios). This keeps the data understandable to designers without requiring custom unit conversions.

### 3.2 Extension to FSM Tick: Threshold Checking

The current FSM tick loop does two things:
1. Decrement timers
2. Fire auto-transitions when timers expire

We add a third step: **check property thresholds.**

```lua
-- Pseudocode for extended FSM tick
function fsm.tick(obj, context)
    -- Step 1: Existing timer logic
    if obj._timer then
        obj._timer = obj._timer - 1
        if obj._timer <= 0 then
            fire_auto_transition(obj)
        end
    end

    -- Step 2: NEW — threshold checks
    if obj.thresholds then
        local mat = materials[obj.material]
        for _, threshold in ipairs(obj.thresholds) do
            if threshold.condition(obj, mat, context) then
                fire_threshold_transition(obj, threshold)
            end
        end
    end
end
```

**Threshold definition on objects:**

```lua
-- In a candle object definition:
thresholds = {
    {
        id = "melt",
        condition = function(obj, mat, ctx)
            return ctx.ambient_temperature and mat.melting_point
                and ctx.ambient_temperature > mat.melting_point
        end,
        transition = "melted",
        message = function(obj)
            return "The " .. obj.name .. " softens and melts into a waxy puddle."
        end,
        mutate = {
            weight = function(cur) return cur * 0.5 end,
            keywords = { remove = "solid", add = "puddle" },
        },
    },
    {
        id = "ignite",
        condition = function(obj, mat, ctx)
            return ctx.ambient_temperature and mat.ignition_point
                and ctx.ambient_temperature > mat.ignition_point
        end,
        transition = "burning",
        message = "The wax catches fire!",
    },
}
```

### 3.3 Context Object: Environmental State

Threshold conditions need access to environmental state. We introduce a **context object** passed through the tick:

```lua
local context = {
    ambient_temperature = room.temperature or 20,  -- °C, default room temp
    wetness = room.wetness or 0.0,                  -- 0.0 = dry, 1.0 = submerged
    light_level = room.light_level or 0,            -- 0 = darkness
    -- Extensible: add new environmental properties without engine changes
}
```

This context is assembled per-room at tick time and passed to all threshold conditions. The engine doesn't understand what "temperature" or "wetness" means — it just passes data.

### 3.4 Material Property Resolution in Guards

FSM transition guards can reference material properties:

```lua
transitions = {
    melt = {
        trigger = "auto",
        from = "solid", to = "melted",
        guard = function(obj, ctx)
            local mat = materials[obj.material]
            return mat and mat.melting_point
                and ctx.ambient_temperature > mat.melting_point
        end,
    },
    rust = {
        trigger = "auto",
        from = "intact", to = "rusted",
        guard = function(obj, ctx)
            local mat = materials[obj.material]
            return mat and mat.rust_susceptibility
                and ctx.wetness > 0.5
                and mat.rust_susceptibility > 0.5
        end,
        mutate = {
            description = "The iron surface is blotched with orange rust.",
            weight = function(cur) return cur * 0.95 end,
        },
    },
}
```

---

## 4. Relationship to Principle 8

### 4.1 Assessment: Extension, Not Replacement

**Principle 8 states:** "The Engine Executes Metadata; Objects Declare Behavior."

Material properties are a **natural extension** of Principle 8, not a new principle. Here's why:

| P8 Contract | Material Properties | Status |
|-------------|-------------------|--------|
| Load object metadata as Lua tables | Material registry is a Lua table loaded at startup | ✅ Fits |
| Execute FSM transitions when triggered | Threshold checks trigger FSM transitions | ✅ Fits |
| Tick timers and fire auto-transitions | Threshold checks run alongside timers in tick | ✅ Fits |
| Never contain object-specific logic | Engine checks `obj.material` generically, like any property | ✅ Fits |

**The engine still doesn't know what "wax" means.** It knows that `obj.material` maps to a table of numbers, and that `obj.thresholds` contains condition functions that reference those numbers. The threshold conditions are metadata declared by objects — the engine executes them generically.

### 4.2 What Changes

Principle 8's scope expands from:
- Objects declare **behavior** (FSM states, transitions, mutations)

To:
- Objects declare **behavior** (FSM states, transitions, mutations) AND **physical identity** (material properties)
- The engine resolves material properties from a shared registry
- Transition guards and threshold conditions can reference material properties

### 4.3 Suggested P8 Addendum

> **Principle 8 Addendum — Material Properties:**  
> Objects may declare a `material` property that references a shared material registry. The material registry maps material names to tables of numeric physical properties (density, melting point, hardness, etc.). The engine resolves material properties at runtime but assigns no semantic meaning to them. Threshold conditions on objects reference material properties to determine when auto-transitions fire. The material registry is metadata — adding new materials or properties requires zero engine changes.

---

## 5. Relationship to the `mutate` Field

### 5.1 Complementary, Not Competing

The `mutate` field and material properties serve different roles:

| Concern | `mutate` Field | Material Properties |
|---------|---------------|-------------------|
| **What it does** | Changes properties on transition | Provides numeric identity for condition-checking |
| **When it fires** | When a transition activates | Continuously available for guard evaluation |
| **Direction** | Outward (transition → property change) | Inward (property values → guard evaluation) |
| **Scope** | Per-instance (each object can mutate differently) | Per-material (shared across all objects of same material) |

**They work together:**

```lua
-- The mutate field changes an object's properties
-- Material properties determine WHEN that mutation triggers

transitions = {
    rust = {
        trigger = "auto",
        guard = function(obj, ctx)
            local mat = materials[obj.material]  -- Material properties
            return ctx.wetness > 0.5 and mat.rust_susceptibility > 0.5
        end,
        mutate = {                                -- Mutate field
            description = "Rust blooms across the iron surface.",
            weight = function(cur) return cur * 0.95 end,
            keywords = { add = "rusted" },
        },
    },
}
```

### 5.2 Material-Derived Mutations

A special `mutate` pattern for properties derived from material data:

```lua
mutate = {
    -- Direct value from material table
    max_sharpness = { from_material = true, property = "sharpness_max" },
    -- Computed from material + current value
    weight = function(obj)
        local mat = materials[obj.material]
        return obj.size * mat.density / 1000
    end,
}
```

This keeps the `mutate` field as the universal property-change mechanism while allowing material properties to inform what values are set.

---

## 6. Performance Implications

### 6.1 Threshold Checking: Per-Tick Cost

**Current tick cost:** O(n) where n = objects in current room with active timers.

**Added cost:** O(n × t) where t = average threshold count per object.

**Expected values:**
- Objects per room: 5-20
- Thresholds per object: 0-3 (most objects have zero)
- Effective threshold checks per tick: ~5-15

**Verdict: Negligible.** At 15 Lua function calls per tick, this adds microseconds to a command-response cycle measured in milliseconds.

### 6.2 Event-Driven vs. Per-Tick Checking

**Option A: Check every tick** (recommended for our engine)
- Simple implementation
- Guaranteed to catch threshold crossings within one player command
- Cost is trivial for our room-scoped tick model (D-45)

**Option B: Event-driven** (what DF does)
- Only check when relevant environmental property changes
- More complex: need event bus, subscription management
- Better for DF's continuous simulation with thousands of entities
- **Overkill for our turn-based model**

**Recommendation:** Per-tick checking. Our room-scoped tick (5-20 objects) makes event-driven optimization unnecessary. If we ever scale to hundreds of active objects per room (unlikely for text IF), revisit.

### 6.3 Material Registry Lookup

Material resolution is a single hash-table lookup: `materials[obj.material]`. Cost: O(1), ~nanoseconds. Not a concern.

### 6.4 DF's Cautionary Tale: "FPS Death"

DF's single-threaded, every-entity-every-tick model causes performance collapse at scale. At 200+ dwarves with full material simulation, FPS drops below 10.

**We are immune.** Our architecture ensures this:
- **Turn-based:** No continuous simulation pressure
- **Room-scoped ticking (D-45):** Only current-room objects tick
- **Discrete states:** No tile-by-tile heat diffusion
- **Mobile-first:** Performance constraints force simplicity

> **Source:** DF community performance analysis, widely documented on r/dwarffortress and Bay 12 forums

---

## 7. Implementation Roadmap

### Phase 1: Material Registry (LOW risk)
1. Create `src/engine/materials/init.lua` with initial material table
2. Load material registry at engine startup
3. Expose `materials.get(name)` → property table
4. No existing behavior changes

### Phase 2: Threshold Checking in FSM Tick (MEDIUM risk)
1. Extend `fsm.tick()` to check `obj.thresholds` after timer logic
2. Add `context` parameter to tick (room environmental state)
3. Fire threshold transitions through existing `fsm.apply_state()` path
4. Existing timer-only objects unaffected (no `thresholds` field = no checks)

### Phase 3: Object Adoption (LOW risk, iterative)
1. Add `material = "wax"` to candle (already conceptual)
2. Add threshold for melting near fire sources
3. Add `material = "iron"` to brass-key, rust threshold
4. Expand material table as designers add new objects

### Phase 4: Material-Aware Description Generation (MEDIUM risk)
1. Sensory callbacks can reference material properties for richer descriptions
2. `on_feel` can report hardness, flexibility, temperature
3. `on_smell` can report flammability indicators
4. Description generation remains in object metadata, not engine logic

---

## 8. Architectural Diagram

```
┌──────────────────────────────────────────────────────────┐
│                    OBJECT DEFINITION (.lua)                │
│                                                            │
│  material = "wax"                                          │
│  fsm.states = { solid, melted, burning, spent }            │
│  fsm.thresholds = [                                        │
│    { condition: temp > mat.melting_point → "melted" }      │
│    { condition: temp > mat.ignition_point → "burning" }    │
│  ]                                                         │
│  fsm.transitions = [ ... mutate fields ... ]               │
│                                                            │
└────────────────────────┬─────────────────────────────────┘
                         │ references
                         ▼
┌──────────────────────────────────────────────────────────┐
│                  MATERIAL REGISTRY                         │
│                                                            │
│  wax:  { density:900, melting_point:60, ignite:230, ... }  │
│  iron: { density:7870, melting_point:1538, rust:0.9, ... } │
│  ...                                                       │
│                                                            │
└────────────────────────┬─────────────────────────────────┘
                         │ looked up by
                         ▼
┌──────────────────────────────────────────────────────────┐
│                    FSM ENGINE (tick loop)                   │
│                                                            │
│  1. Decrement timers → fire auto-transitions               │
│  2. Check thresholds → resolve material properties         │
│     → evaluate conditions → fire threshold transitions     │
│  3. Apply mutate fields → update object instance           │
│  4. Fire callbacks → generate messages                     │
│                                                            │
│  ⚠ Engine has ZERO knowledge of what materials mean         │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

---

## 9. Key Design Question: Resolved

> **Can material properties be implemented WITHIN the existing Principle 8 framework (all in .lua metadata), or does the engine need new capabilities?**

**Answer: Both.**

Material properties fit within Principle 8's philosophy — all behavior is metadata, the engine is a generic executor. However, the engine needs two **mechanical extensions**:

1. **Material Registry** — a new data layer the engine loads and exposes (similar to how it loads object definitions)
2. **Threshold checking in tick** — a new step in the FSM tick loop that evaluates condition functions against material property values

These are extensions to the engine's **execution machinery**, not violations of its **design philosophy**. The engine still doesn't understand what wax is — it just has a richer toolkit for executing object-declared metadata.

**Analogy:** Adding threshold checks to the tick loop is like adding timer support was. Timers didn't violate P8 — they gave objects a new kind of metadata the engine could execute. Thresholds are the same pattern.

---

## 10. Sources & References

1. **Dwarf Fortress Wiki — Material definition token.** https://dwarffortresswiki.org/index.php/Material_definition_token
2. **Dwarf Fortress Wiki — Raw file format.** https://dwarffortresswiki.org/index.php/Raw_file
3. **DF Raw Archives (GitHub).** https://github.com/zwei2stein/df-raw-archives
4. **Nolla Games — "Exploring the Tech and Design of Noita" (GDC 2020).** https://braindump.jethro.dev/posts/gdc_vault_exploring_the_tech_and_design_of_noita/
5. **80.lv — "Noita: a Game Based on Falling Sand Simulation."** https://80.lv/articles/noita-a-game-based-on-falling-sand-simulation
6. **Noita Wiki — Materials.** https://noita.fandom.com/wiki/Materials
7. **GamesBeat — "BotW makes chemistry just as important as physics."** https://gamesbeat.com/the-legend-of-zelda-breath-of-the-wild-makes-chemistry-just-as-important-as-physics/
8. **The Artifice — "Systemic Games: A Design Philosophy."** https://the-artifice.com/systemic-games-philosophy/
9. **GameDeveloper — "Procedural generation in Caves of Qud."** https://www.gamedeveloper.com/design/tapping-into-the-potential-of-procedural-generation-in-caves-of-qud
10. **EB-DEVS — Formal Framework for Emergent Behavior (Journal of Computational Science, 2021).** https://www.sciencedirect.com/science/article/pii/S1877750321000752
11. **Simulating Mechanics to Study Emergence in Games (AIIDE).** https://ojs.aaai.org/index.php/AIIDE/article/download/12477/12336
12. **Springer — "The Chemical Engine Algorithm and Realization Based on UE4."** https://link.springer.com/chapter/10.1007/978-3-031-50072-5_14
13. **Internal — DF Architecture Comparison Report.** `resources/research/competitors/dwarf-fortress/architecture-comparison.md`
14. **Internal — Core Architecture Principles, Principle 8.** `docs/architecture/objects/core-principles.md`
15. **Internal — FSM Object Lifecycle.** `docs/design/fsm-object-lifecycle.md`

---

*End of Architecture Document*
