# Decision: Matchbox Container Rework + Compound Tool Pattern

**Author:** Comic Book Guy (Game Designer)
**Date:** 2026-03-20
**Status:** Implemented per Wayne's directive

## Decision

Reworked the matchbox from a tool-with-charges to a proper container holding individual match objects. Established the compound tool action pattern (STRIKE match ON matchbox) and consumable fire source pattern (match-lit burns out after ~30 seconds).

## Changes

1. **Matchbox is now a container** — `container = true`, `has_striker = true`, holds match-1 through match-7. No longer provides `fire_source` directly. No more `charges` counter.
2. **matchbox-empty.lua deleted** — An empty container doesn't need a separate file. This was Wayne's explicit directive.
3. **Individual match objects** — `match.lua` (inert) and `match-lit.lua` (burning, provides fire_source). The match requires STRIKE ON matchbox (compound action) to ignite.
4. **Thread created** — `thread.lua` provides `sewing_material`. Placed in sack with needle. Compound tool pair for SEW verb.

## Impact on Existing Systems

- **Engine needs `requires_property` resolution** — match.mutations.strike uses `requires_property = "has_striker"` to check the target object. This is a new resolution pattern alongside `requires_tool` (capability) and `requires` (item ID).
- **Engine needs consumable timer** — `burn_remaining` on match-lit decrements in game time. Auto-consumes when 0.
- **Engine needs container TAKE FROM** — `TAKE match FROM matchbox` removes item from container's contents array.
- **Match instancing** — contents reference match-1 through match-7 as instances of match.lua archetype. Engine resolves the mapping.

## Rationale

Wayne's directive: "The matchbox should NOT have matchbox.lua + matchbox-empty.lua. The matchbox is a CONTAINER (like the sack) with a contents array." This is more immersive (real objects vs. abstract counters) and more consistent with the code-IS-state philosophy.

## Team Impact

- **Bart (Engine):** Needs to implement `requires_property`, consumable timers, container TAKE FROM, and match instancing.
- **Brockman (Docs):** Design directives and tool-objects.md already updated.
- **All designers:** The compound tool pattern and container-with-contents pattern are now documented as standard patterns for future objects.
