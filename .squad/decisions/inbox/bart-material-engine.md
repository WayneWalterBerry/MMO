# D-MAT001: Material Registry and Threshold-Based Auto-Transitions

**Author:** Bart (Architect)  
**Date:** 2026-07-19  
**Status:** Implemented  
**Requested by:** Wayne Berry  
**Research by:** Frink (Researcher)

---

## Decision

The engine now supports **material properties** as a first-class data layer and **threshold-based auto-transitions** in the FSM tick loop. This is an extension of Principle 8 — the engine gains new execution machinery without gaining semantic knowledge of materials.

## What Was Implemented

### 1. Material Registry (`src/engine/materials/init.lua`)
- Lua table mapping 13 material names to numeric property tables
- Materials: wax, wood, fabric, wool, iron, steel, brass, glass, paper, leather, ceramic, tallow, cotton
- Properties: density, melting_point, ignition_point, hardness, flexibility, absorbency, opacity, flammability, conductivity, fragility, value (+ rust_susceptibility for iron/steel)
- API: `materials.get(name)` → property table, `materials.get_property(name, prop)` → value
- Adding new materials requires zero engine changes

### 2. Threshold Checking in FSM Tick (`src/engine/fsm/init.lua`)
- New `check_thresholds()` runs as Step 2 in `fsm.tick()`, after existing `on_tick` callbacks
- Objects declare thresholds: `{ property = "temperature", above = 62, transition = "melting" }`
- Supports `above` / `below` (direct numeric) and `above_material` / `below_material` (resolved from material registry)
- When crossed, finds matching transition from current state → target state, fires it with full apply_state + apply_mutations + on_transition pipeline
- Material registry is lazy-loaded via pcall (no hard dependency)

### 3. Environment Context in Game Loop (`src/engine/loop/init.lua`)
- Loop builds `env_context` from room properties: temperature, wetness, moisture, light_level
- Passed to `fsm.tick(registry, obj_id, env_context)` each command cycle
- Rooms can declare `temperature`, `wetness`, etc. as numeric properties

## Backward Compatibility
- Objects without `thresholds` field: zero behavior change (nil check short-circuits)
- Objects without `material` field: thresholds still work with direct numeric limits
- `fsm.tick()` third parameter is optional — existing callers unaffected
- Existing timed_events, on_tick callbacks, and manual transitions all work unchanged

## Usage Example
```lua
-- Object declares material and thresholds:
material = "wax",
thresholds = {
    { property = "temperature", above = 62, transition = "melting" },
    { property = "temperature", above_material = "ignition_point", transition = "burning" },
},
transitions = {
    { from = "solid", to = "melting", trigger = "auto", message = "The wax softens and droops." },
    { from = "solid", to = "burning", trigger = "auto", message = "The wax catches fire!" },
},

-- Room declares environment:
temperature = 80,  -- hot room near fire
```

## Rationale
- Follows Frink's architecture recommendation: material properties fit WITHIN Principle 8
- Same pattern as timed_events: new metadata the engine executes generically
- Per-tick checking is correct for turn-based IF (no continuous simulation needed)
- Performance: O(n × t) where n = room objects, t = avg thresholds per object (~5-15 checks per tick)
