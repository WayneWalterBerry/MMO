# Frink — Material Properties Research Recommendations

**Date:** 2026-07-19  
**Author:** Frink (Researcher)  
**Context:** Wayne identified material properties as the biggest gap from the DF comparison. This is a cross-domain concern affecting both architecture and design.

---

## R-MAT-1: Create Material Registry (HIGH PRIORITY)

**Recommendation:** Create `src/engine/materials/init.lua` containing a shared material property table mapping material names to numeric properties (density, melting_point, ignition_point, hardness, flexibility, absorbency, opacity, flammability, conductivity, fragility, value).

**Rationale:** Our `material = "wax"` is a label. DF assigns 20+ numeric properties per material. The registry is pure data — no engine logic changes required to add it. Start with 10-13 materials matching our existing objects.

**Impact:** Foundation for all subsequent material-driven features. Zero risk to existing behavior.

**Architecture doc:** `docs/architecture/engine/material-properties.md` §3.1  
**Design doc:** `docs/design/material-properties-system.md` §1

---

## R-MAT-2: Extend FSM Tick with Threshold Checking (HIGH PRIORITY)

**Recommendation:** Add a threshold-checking step to the FSM tick loop. After timer decrements, evaluate `obj.thresholds` — condition functions that reference material properties and environmental context. Fire auto-transitions when thresholds are crossed.

**Rationale:** This bridges DF-style emergence into our FSM framework. Objects declare thresholds as metadata; the engine executes them generically. Fits within Principle 8 — no new architectural principles needed.

**Impact:** Extends the tick loop by ~15 function calls per tick (negligible). Existing timer-only objects unaffected (no `thresholds` field = no checks).

**Architecture doc:** `docs/architecture/engine/material-properties.md` §3.2  

---

## R-MAT-3: Adopt "Material Consistency" Design Principle (MEDIUM PRIORITY)

**Recommendation:** Add a Design Core Principle stating: "Every object is made of a material. The engine treats all objects of the same material identically. Players learn the world by learning materials, not by memorizing object-specific rules."

**Rationale:** This principle prevents special-casing (a wax candle melts but a wax seal doesn't) and creates a teachable, predictable world. Directly inspired by BotW's chemistry engine and DF's property-bag philosophy.

**Design doc:** `docs/design/material-properties-system.md` §4

---

## R-MAT-4: Implement Fire Propagation as First Emergent Behavior (HIGH PRIORITY)

**Recommendation:** Fire propagation should be the first material interaction implemented. It's the most visible, testable, and impactful. Use the bedroom puzzle as the test case: match near bed-sheets, candle near curtains, etc.

**Rationale:** Fire touches flammability, ignition_point, material consistency, and threshold auto-transitions — exercising the entire material system in one scenario. Players already interact with fire (matches, candles); extending it to propagation is natural.

**Design doc:** `docs/design/material-properties-system.md` §7 Phase 1

---

## R-MAT-5: Material Properties Fit Within Principle 8 (INFORMATIONAL)

**Finding:** Material properties can be implemented WITHIN the existing Principle 8 framework. The engine needs two mechanical extensions (material registry + threshold checking in tick) but no new architectural principles. Suggested P8 addendum language is in the architecture doc §4.3.

**Architecture doc:** `docs/architecture/engine/material-properties.md` §4

---

## Cross-References

- **Builds on:** R1 and R2 from `frink-df-recommendations.md`
- **Architecture doc:** `docs/architecture/engine/material-properties.md`
- **Design doc:** `docs/design/material-properties-system.md`
- **Related decisions:** D-14 (True Code Mutation), D-DF-ARCHITECTURE, D-MUTATE-PROPOSAL, Principle 8
