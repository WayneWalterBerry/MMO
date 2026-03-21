# Frink — DF Architecture Recommendations

**Author:** Frink (Researcher)  
**Date:** 2026-07-19  
**Research:** `resources/research/competitors/dwarf-fortress/architecture-comparison.md`  
**Status:** RECOMMENDATION

---

## Recommendations from Dwarf Fortress Architecture Analysis

### R1: Material Property Tables ⭐ HIGH PRIORITY

**What:** Create a `materials.lua` registry mapping material names to numeric property bags (density, melting_point, ignition_point, hardness, flexibility, value, sharpness_max).

**Why:** Our current `material = "wax"` is a string label with no properties. DF's entire emergence comes from numeric material properties that the engine resolves generically. Material property tables enable guard functions, description generation, and mutation logic to reference material data without special-casing.

**Impact:** Supports Principle 8, D-MUTATE-PROPOSAL, future emergence patterns.

---

### R2: Threshold-Based Auto-Transitions ⭐ HIGH PRIORITY

**What:** Extend FSM transitions to support `condition` functions that check numeric property thresholds (not just timers). When a mutable property crosses a threshold, an auto-transition fires.

**Why:** This is how DF achieves emergence within a rules-based system. Rain → wet → rust on iron objects becomes: wetness property increases → threshold condition triggers "rust" auto-transition. Bridges DF-style cascading into our existing FSM framework.

**Impact:** Enables emergent behavior chains without continuous physics simulation.

---

### R3: Variation/Composition Macros 🟡 MEDIUM PRIORITY

**What:** Add a variation system (Lua functions that modify base definitions) to complement our template system. DF's `CREATURE_VARIATION` lets you define reusable modifications applied to any base.

**Why:** Supports D-17 (Universe Templates) and procedural generation. A "fire_resistant" variation could be applied to any object to add heat-related guards and properties.

**Impact:** More expressive world generation, reduced boilerplate in object definitions.

---

### R4: Numeric Wear/Decay Property 🟡 MEDIUM PRIORITY

**What:** Add optional `wear` as a numeric property (0.0–1.0) that increments on use, with configurable thresholds that trigger description changes or FSM transitions.

**Why:** DF tracks wear as a continuous value with visual thresholds. This is a natural fit for our `mutate` field — transitions increment wear, thresholds drive state changes.

**Impact:** Richer object lifecycle without requiring separate FSM states for each wear level.

---

### Anti-Recommendations (What NOT to Adopt)

- **Full physics simulation** — DF's temperature-per-tile model causes FPS death. Our FSM is correct for text IF.
- **Unbounded entity history** — DF tracks everything forever. Our room-scoped ticking is architecturally superior.
- **Pure-data objects** — DF raws have no embedded logic. Our Lua callbacks are more powerful. Don't sacrifice flexibility for philosophical purity.
