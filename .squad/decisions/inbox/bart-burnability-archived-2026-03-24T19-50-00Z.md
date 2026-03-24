# Decision: Burnability Derived from Material Flammability

**Author:** Bart (Architect)
**Date:** 2025-07-18
**Issue:** #120

## Decision

The `burn` verb handler now derives burnability from `materials.get(obj.material).flammability` instead of per-object `flammable` flags or `categories` arrays. This follows the same pattern established for armor (material-derived, not hardcoded).

## Threshold

- **Burnable:** `flammability >= 0.3`
- **Not burnable:** `flammability < 0.3` or no material

## Resolution Order

1. **FSM transition** — if the object has a `burn` verb transition, use it (e.g., rope: intact → burning)
2. **Mutation** — if the object has a `burn` mutation, apply it (e.g., letter → letter-ash)
3. **Generic destruction** — remove the object from the world entirely

## Who This Affects

- **Flanders** — New objects with `material` fields automatically get correct burn behavior. No need to add `flammable` flags or categories. Objects that need custom burn behavior should use FSM transitions or mutations.
- **Moe** — Room objects with flammable materials can now be burned. Consider whether rooms need fire-spread mechanics later.
- **Comic Book Guy** — Puzzles can leverage material-derived burnability. Burning a rope to drop something, burning a scroll, etc.

## Backward Compatibility

The old `obj.flammable` and `categories = {"flammable"}` paths are removed. Only `paper.lua` used the `flammable` category — it has `material = "paper"` (flammability 0.8) so it burns correctly under the new system.
