# Bart — Bugfix Pass-008 Decisions

**Author:** Bart (Architect)
**Date:** 2026-03-21
**Scope:** BUG-033, BUG-034, candle-holder placement

---

## D-BUG033: GOAP drops spent matches before acquiring new fire source

**Status:** Implemented
**Affects:** engine/parser/goal_planner.lua

When the GOAP planner builds a fire_source plan, it now checks player hands for spent matches and prepends `drop match` steps before attempting to take a new match. Spent matches are terminal consumables (D-OBJ003, D-OBJ006) — they have no further utility and should never block the planner.

---

## D-BUG034: "put out" and "blow out" are compound verb phrases mapped to extinguish

**Status:** Implemented
**Affects:** engine/loop/init.lua (preprocess_natural_language)

Added `"put out X"` and `"blow out X"` → `"extinguish", X` mappings in NLP preprocessing, positioned BEFORE the compound "and" splitter and BEFORE the existing `"put on"` → wear mapping. This prevents the parser from splitting "put out candle" into verb=PUT noun="out candle".

---

## D-OBJ007: Surface item contents searched before surface items in resolution

**Status:** Implemented
**Affects:** engine/verbs/init.lua (find_visible), engine/parser/goal_planner.lua (resolve_target), engine/verbs/init.lua (get_light_level)

When resolving keywords against surface items, the engine now searches inside a surface item's `contents` array BEFORE matching the surface item itself. This ensures "candle" resolves to the candle object inside a candle-holder, not to the candle-holder (which matches "candle" via name substring). The same nested search was added to `get_light_level` so a lit candle inside a holder on a surface still illuminates the room. Pattern: contents-before-container resolution for composites.

---

## D-OBJ008: Candle holder placed in bedroom on nightstand, candle nested inside

**Status:** Implemented
**Affects:** meta/world/start-room.lua

The candle-holder instance is placed at `nightstand.top`. The candle instance location changed from `nightstand.top` to `candle-holder`, making it a contained child of the composite. This matches the candle-holder's `with_candle` state design (D-OBJ005). The candle and holder are independently examinable and the candle remains the target for light/extinguish verbs.
