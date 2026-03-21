# Decision: Wine Bottle FSM for Puzzle 016

**Author:** Flanders (Object Systems Engineer)  
**Date:** 2026-07-22  
**Status:** Implemented  
**Affects:** `src/meta/objects/wine-bottle.lua`, `src/meta/objects/oil-flask.lua`

---

## Summary

Implemented the DRINK verb transition on `wine-bottle.lua` for Puzzle 016 (Wine Drink). The wine bottle now supports the full interaction chain: TAKE → OPEN → DRINK (or TASTE for investigation).

## Changes Made

### wine-bottle.lua
1. **Template:** Changed from `container` to `small-item` — wine bottle is a holdable/drinkable item, not a container for storing other objects. Matches `poison-bottle.lua` pattern.
2. **Categories:** Updated from `{"container", ...}` to `{"small-item", ...}` for template consistency.
3. **New transition:** `open → empty` via DRINK (aliases: quaff, sip, swig). Full message from puzzle-016 spec.
4. **New prerequisite:** `drink = { requires_state = "open" }` — must uncork before drinking.
5. **Sensory properties:** Added `on_taste` to sealed, open, and empty states. TASTE is non-consuming investigation; DRINK is consuming state change.
6. **Descriptions:** Updated OPEN message, empty state feel/description per puzzle spec.
7. **Mutate:** Added `contains = nil` to drink and pour transitions (clears bottle contents).

### oil-flask.lua
- Added `on_drink_reject` property with flavor message for when player tries to drink lamp oil. Engine needs to check this field when processing DRINK on non-drinkable objects.

## Design Decision: No Mechanical Effect

The task description mentioned a `liquid_courage` buff. The puzzle-016 design doc (by Sideshow Bob) explicitly rejects this:

> *"CBG's gap analysis asked: health benefit? courage? just flavor text? The answer is flavor text only."*

Reasons from the design doc:
1. No health/buff system exists in the engine yet
2. The purpose is teaching the DRINK verb, not a reward system
3. Consistency with Puzzle 002's binary outcomes (safe vs. death)

**I followed the design doc.** If a buff system is wanted later, it can be added as a future enhancement without changing the FSM structure.

## For Moe (World Builder)

Per-bottle flavor variations (3 different drink messages per the puzzle doc) should be applied as instance overrides in the storage cellar room definition, not in the base object. The base object provides the default message; instances override `on_drink` for variety.

## For Nelson (Tester)

Test matrix:
- DRINK sealed bottle → should fail (requires open state)
- OPEN sealed bottle → transitions to open
- DRINK open bottle → transitions to empty with message
- TASTE open bottle → sensory message, NO state change
- DRINK empty bottle → should fail (terminal state, no transition)
- DRINK oil flask → should show rejection message
- SMELL still works in all states (Puzzle 010 compatibility)

## All Tests

39/39 existing tests pass after changes. No regressions.
