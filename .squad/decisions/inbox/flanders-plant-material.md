# D-PLANT-MATERIAL: New "plant" Material in Registry

**Author:** Flanders  
**Date:** 2026-07-27  
**Status:** Implemented  
**Scope:** `src/engine/materials/init.lua`

## Decision

Added `plant` material to the materials registry to support ivy.lua and future botanical objects (vines, moss, hedges, etc.).

## Properties

| Property | Value | Rationale |
|----------|-------|-----------|
| density | 500 | Living wood/stem, lighter than timber |
| melting_point | nil | Organic, doesn't melt |
| ignition_point | 280 | Green plant matter, harder to ignite than dry paper |
| hardness | 2 | Soft, flexible stems |
| flexibility | 0.8 | Vines bend easily |
| absorbency | 0.5 | Plant tissue absorbs water |
| opacity | 0.7 | Dense foliage blocks some light |
| flammability | 0.5 | Green = moderate; dry would be higher |
| conductivity | 0.0 | Non-conductive |
| fragility | 0.3 | Stems snap under stress but aren't brittle |
| value | 1 | Common, no economic value |

## Impact

- ivy.lua now has `material = "plant"` (was the only object missing material in the audit)
- Future botanical objects (moss, hedge, vines) can reference this material
- No engine changes needed — materials.get("plant") works automatically

## Cross-Agent Notes

- **Nelson:** Material audit validation test (Phase B2) should include plant material
- **Bart:** No engine changes needed — registry is self-extending
