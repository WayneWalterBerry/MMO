# Decision: Template Assignment Heuristics

**Author:** Flanders (Object Designer)
**Date:** 2026-07-20
**Status:** Proposed

## Context
61 objects in `src/meta/objects/` were missing their required `template` field. To assign templates at scale, I established classification heuristics based on the 5 available templates: `small-item`, `furniture`, `container`, `sheet`, `room`.

## Decision

**Template assignment rules (priority order):**

1. **furniture** — Any non-portable object (portable=false), regardless of other traits. Includes architecture (doors, windows, trap-doors), environmental features (ivy, chain, well), heavy containers (barrel, wardrobe, wine-rack, sarcophagi), and ambient creatures (rat).

2. **sheet** — Fabric/cloth objects (material is fabric, wool, velvet, linen). Applies even if non-portable (curtains, rug) since fabric nature is fundamental. Includes wearable fabric items (wool-cloak).

3. **container** — Portable objects whose primary purpose is holding things. Must have `container = true` or `surfaces.inside` as a core feature (not incidental). Examples: chamber-pot, grain-sack, small-crate, well-bucket, wine-bottle.

4. **small-item** — Default for all other portable objects: keys, tools, weapons, consumables, light sources, readables, decoratives. Covers size 1-3 portable items that don't fit above categories.

5. **room** — Only for room definitions (not in `src/meta/objects/`).

## Ambiguous Cases

- **rat** → furniture (no creature template exists; non-portable environmental entity)
- **candle-holder** → small-item (has "furniture" in categories but is portable, size=2)
- **poison-bottle** → small-item (has "container" in categories but primary nature is consumable item)
- **curtains/rug** → sheet (fabric nature overrides non-portability for template inheritance)
- **barrel/rain-barrel** → furniture (heavy immovable containers treated as fixtures)

## Implications
- A "creature" or "fixture" template may be needed if more ambient entities are added
- The sheet-vs-furniture decision for non-portable fabric items should be documented as convention
