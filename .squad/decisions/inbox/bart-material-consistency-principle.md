# Decision: Material Consistency as Core Architecture Principle 9

**Date:** 2026-03-27  
**Author:** Bart (Architect)  
**Requested by:** Wayne "Effe" Berry  
**Status:** ✅ IMPLEMENTED

---

## Overview

Material Consistency has been added as **Core Architecture Principle 9** in `docs/architecture/objects/core-principles.md`.

The principle establishes that **every object MUST derive its physical behavior from a material in the material registry** (`src/engine/materials/init.lua`), never from hard-coded properties.

---

## The Principle

### Core Rule
Objects declare a `material` property that references a material definition in the registry. The engine resolves all physical properties (fragility, flammability, hardness, weight-class, etc.) from that material at runtime.

### Example
```lua
-- candle.lua
{
    id = "candle",
    material = "wax",  -- All physical behavior derived from wax material
    name = "a white candle",
}

-- materials.registry.wax contains:
-- density, fragility, flammability, hardness, flexibility, etc.
```

### The Exception (Critical)
**Object instances CAN override material properties when needed**, but this is the exception, not the rule.

```lua
-- Instance in room: specific candle is reinforced
{
    id = "candle-special",
    type_id = "{guid-candle}",
    material = "wax",
    fragility_override = 0.1,  -- Exception: this candle is hardened
}
```

Override-driven tuning keeps the material system clean: defaults from the registry, exceptions documented explicitly on instances.

---

## Material Registry Structure

The material registry (`src/engine/materials/init.lua`) defines:

| Property | Purpose | Range/Units |
|----------|---------|------------|
| `density` | Mass per volume | kg/m³ → affects weight |
| `hardness` | Deformation resistance | 1–10 (Mohs scale) |
| `fragility` | Break likelihood | 0.0–1.0 |
| `flammability` | Burn propensity | 0.0–1.0 |
| `flexibility` | Bend without breaking | 0.0–1.0 |
| `absorbency` | Liquid absorption | 0.0–1.0 |
| `opacity` | Light transmission | 0.0–1.0 |
| `conductivity` | Heat/electricity transfer | 0.0–1.0 |
| `melting_point` | Temp threshold | °C or nil |
| `ignition_point` | Burning threshold | °C or nil |
| `value` | Economic multiplier | 1–100 |

---

## Design Consequences

### 1. Consistency Across the World
Two wax candles (unless instance-overridden) have identical physical properties everywhere. No secret balancing in code.

### 2. Content-Driven Physics
Adding or adjusting materials requires zero engine changes. A designer edits the registry; all objects using that material inherit the new properties.

### 3. Scalability
New object types automatically inherit physical behavior from their material. Creating 50 wooden objects doesn't require 50 property definitions.

### 4. Debuggability
Physical behavior is traceable: "Why does this burn?" → Look up material → Check flammability. Clear causality.

### 5. Reusability
Multiple object types share the same material (e.g., "wood" applies to chairs, doors, arrows, bows). Define once, use everywhere.

---

## Alignment with Architecture

### Dwarf Fortress Paradigm (D-DF-ARCHITECTURE)
This principle directly implements Wayne's directive: the simulation engine operates on **physical properties**, not object type names. Dwarf Fortress doesn't have "door code" — it has material properties and physical simulation. We follow the same model.

### Complements Principle 8 (Engine Executes Metadata)
- **Principle 8:** Engine is generic FSM executor; objects declare behavior via metadata
- **Principle 9:** Physical behavior specifically comes from the material registry; no hard-coded per-object physics

### Complements Principle 1 (Code-Derived Mutable Objects)
Material properties are immutable defaults (source of truth). Instances can mutate (override), but the principle enforces that mutations are exceptions.

---

## Implementation Status

✅ **Added to Core Architecture Principles (v1.1)**
- Updated TOC (lines 16–26)
- Updated metadata (version, author, purpose)
- Added comprehensive Principle 9 documentation (lines 1110–1248)
- Documented material registry structure
- Documented object → material binding pattern
- Documented runtime resolution algorithm
- **Clearly documented the exception rule** (instance overrides)
- Added implementation examples
- Added design consequences

✅ **Committed:** a809a24 — "Add Material Consistency as Core Architecture Principle 9"

✅ **Appended to Bart's history.md**
- Added learning entry under "## Learnings"
- Documents alignment with Dwarf Fortress paradigm

---

## Future Work

1. **Validation:** Add load-time checks to ensure all objects have valid `material` references
2. **Composite materials:** Multi-part objects can declare different materials per part (e.g., wooden hilt + iron blade)
3. **Material inheritance:** Derived materials (e.g., "hardened-wood" inherits from "wood" with overrides)
4. **Runtime material swaps:** Allow in-game transformations (wood → charcoal) via material property changes
5. **Physics simulation:** Integrate material properties into damage calculation, weight-based carry limits, burning mechanics

---

## Files Changed

- **`docs/architecture/objects/core-principles.md`** — Added Principle 9 (v1.0 → v1.1)
- **`.squad/agents/bart/history.md`** — Added learning entry
- **Commit:** a809a24

---

## Approval

✅ **Requested by:** Wayne "Effe" Berry  
✅ **Implemented by:** Bart (Architect)  
✅ **Status:** Ready for team review
