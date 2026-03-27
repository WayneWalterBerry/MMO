# Decision: Eat Handler Backward Compatibility for Food System

**Author:** Smithers (Parser/UI Engineer)
**Date:** 2026-07-30
**Context:** WAVE-5 Track 5B — Eat/Drink Verb Extensions

## Decision

The eat handler uses a **dual-path edibility check**: WAVE-5 `food.edible` (nested food table) AND legacy `obj.edible` (top-level boolean). Objects with the new `food` table must be held in hands; legacy `edible` objects can be eaten from the room (grandfathered).

## Rationale

The WAVE-5 spec requires "object must be in player's hands to eat." However, existing on_eat hook tests (#102, test-engine-hooks-102.lua) place edible objects in room contents without putting them in hands. Enforcing the hand requirement for ALL edible objects would break these tests.

The compromise: new food-system objects (`food = { edible = true }`) enforce the holding requirement. Legacy objects (`edible = true` at top level, no `food` table) maintain the old behavior (searchable in room via `find_visible`).

## Affects

- **Nelson:** New food tests should use `food = { edible = true }` pattern and place food in player hands. Legacy `edible = true` pattern still works but doesn't enforce holding.
- **Flanders:** Food objects (cheese, bread) should use `food = { edible = true, nutrition = N }` table pattern.
- **Bart:** The `food.nutrition` value is applied to `player.nutrition` (accumulator). Player model may need a nutrition field initialized.

## Drink Restriction

The drink handler checks `injuries.get_restrictions(player).drink` before object resolution. Rabies furious state blocks all drinking with a thematic hydrophobia message. This is an early-exit check — no object needed.
