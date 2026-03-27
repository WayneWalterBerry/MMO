# Decision: Food Object Material Proxy

**Author:** Flanders
**Date:** 2026-07-30
**Track:** WAVE-5 Track 5A

## Decision

Both food objects (`cheese.lua`, `bread.lua`) use `material = "wax"` as a proxy since no `food`, `organic`, or `cheese`/`bread` materials exist in the material registry (`src/meta/materials/`).

## Rationale

- Cheese has a waxy rind and oily texture — `wax` is the closest physical match among the 30 existing materials.
- Bread has no good existing match; `wax` was chosen for consistency between the two food objects.
- The plan spec (line 657/660) calls for `material = "cheese"` / `material = "bread"` but those don't exist.

## Impact

- **Bart:** If food materials need distinct physical properties (hardness, density, fragility) for the containment or damage systems, dedicated `food` or `organic` material definitions should be created in `src/meta/materials/`.
- **Nelson:** Tests should not assert material-specific properties on food objects until real food materials are defined.
- **Smithers:** The `eat` verb (Track 5B) should check `food.edible`, not material type, to determine edibility.

## Status

Provisional — revisit when food system expands beyond PoC.
