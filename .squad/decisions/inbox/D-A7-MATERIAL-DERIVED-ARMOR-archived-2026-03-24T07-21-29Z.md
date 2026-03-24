# D-A7-MATERIAL-DERIVED-ARMOR

**Date:** 2026-07-27
**Author:** Flanders
**Status:** Implemented
**Scope:** chamber-pot.lua, armor system

## Decision

Chamber pot armor is now **material-derived** — no hardcoded `provides_armor` or `reduces_unconsciousness`. The engine armor interceptor reads `material = "ceramic"` and calculates protection from the material registry properties (hardness, density, fragility). The wear table provides `coverage = 0.8` and `fit = "makeshift"` as modifiers.

`is_helmet = true` is retained as a **semantic tag** — it tells the engine "this is helmet-shaped" but is NOT the source of protection values.

## Rationale

Dwarf Fortress property-bag architecture (D-DF-ARCHITECTURE): objects declare what they ARE, the engine figures out what that MEANS. Hardcoded armor values on individual objects create maintenance debt and bypass the material system.

## Impact

- **Bart (engine):** Armor interceptor must handle ceramic material for head-slot items. Coverage + fit modifiers should be consumed.
- **Nelson (tests):** Existing chamber-pot helmet tests may need updating if they assert `provides_armor = 1` or `reduces_unconsciousness = 1` on the object directly. Those fields no longer exist.
- **CBG:** brass-spittoon still has hardcoded `provides_armor = 2` — candidate for same migration if this pattern proves stable.

## Files Changed

- `src/meta/objects/chamber-pot.lua` — removed hardcoded armor, added FSM degradation, added event_output
- `docs/objects/chamber-pot.md` — updated design doc
