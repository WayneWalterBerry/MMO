# Creatures Directory Split

**Date:** 2026-03-26  
**Author:** Bart (Architecture)  
**Status:** ✅ Approved

## Decision
Create a dedicated `src/meta/creatures/` directory for animate beings. Creature definitions live alongside (but separate from) inanimate objects in `src/meta/objects/`.

## Rationale
Creatures are not inanimate objects; separating their definitions clarifies ownership, validation rules, and loader behavior while keeping shared template resolution intact.

## Implementation Notes
- Loader scans `meta/objects/` then `meta/creatures/` before room resolution; both feed `base_classes` and `object_sources`.
- Meta-lint treats `creatures/` files like objects for template resolution, GUID uniqueness, keywords, and sensory checks.
- `rat.lua` moved to `src/meta/creatures/rat.lua` with all path references updated.
