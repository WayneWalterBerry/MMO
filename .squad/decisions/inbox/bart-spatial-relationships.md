# D-SPATIAL-ARCH: Spatial Relationships — Engine Architecture

**Author:** Bart (Architect)  
**Date:** 2026-03-27  
**Status:** Active  
**Related:** D-SPATIAL-HIDE (Comic Book Guy), Wayne play-test feedback (2026-03-27)  
**Deliverable:** `docs/architecture/objects/spatial-relationships.md`

---

## Decision

The engine architecture for spatial concealment relationships follows three rules:

1. **Covering objects own the relationship.** The `covering` array on the covering object (e.g., rug) declares what it hides. The hidden object declares `hidden = true` and provides an FSM with `hidden → revealed` transition. The room does not track relationships — objects are self-describing.

2. **traverse.lua must filter hidden objects.** `expand_object()` must check `obj.hidden` and skip hidden objects entirely. `matches_target()` must also return `false` for hidden objects. This is a bug fix — the search engine currently walks past the `hidden` flag without checking it.

3. **The `behind` relationship uses the same pattern.** Future `hiding_behind` field on blocker objects (wardrobe, curtains) follows identical mechanics to `covering`. The engine treats both as concealment; only the reveal verb differs.

---

## What Already Works

- `rug.lua`: `covering = {"trap-door"}`, `movable = true`, `moved = false`, `surfaces.underneath`
- `trap-door.lua`: `hidden = true`, FSM `hidden → revealed → open`, `discovery_message`
- Move verb handler (`verbs/init.lua:1168-1206`): dumps underneath items, reveals covered objects via FSM transition
- Room description (`look`): filters `obj.hidden` objects
- Sensory verbs (`smell`, `listen`): filter `obj.hidden` objects
- Keyword resolution: filters `obj.hidden` objects

## What Needs Fixing

- **`traverse.lua`**: No hidden-object check in `expand_object()` or `matches_target()` — search can find hidden objects
- **`rug.lua`**: `surfaces.underneath` lacks `accessible = false` — search can discover items under the unmoved rug
- **Move handler**: Should set `underneath.accessible = true` when covering object is moved

## Design Rationale

Object-level metadata (not room-level relationship tables) because:
- Follows Principle 8: objects declare behavior, engine executes
- Composable: rug carries its `covering` list if moved to another room
- No second source of truth — one place to author, one place to debug
