# Decision: Spatial Relationships Implementation

**Author:** Bart (Architect)
**Date:** 2026-03-26
**Status:** Implemented
**Affects:** Object definitions, verb system, room exits, puzzle design

## Summary

Implemented the spatial relationships system from Comic Book Guy's design spec (`docs/design/spatial-system.md`). Focused on the critical path: bed → rug → trap door puzzle chain.

## Key Decisions

### 1. Per-Object Properties, Not a Spatial Graph

Spatial relationships are declared as simple object properties (`movable`, `resting_on`, `covering`) rather than a separate spatial graph engine module. This keeps the system data-driven and composable without adding new engine infrastructure.

**Rationale:** The immediate need is bed→rug→trap door. A full spatial graph is over-engineering at this stage. Properties can be upgraded to a graph later if needed.

### 2. Dynamic Blocking Check

Instead of maintaining a `blocked_by` list on each object, the movement helper scans room.contents for objects with `resting_on == this_object.id`. This means no bookkeeping when relationships change.

### 3. Verb-Layer Helper, Not Engine Module

`move_spatial_object()` lives in `engine/verbs/init.lua` as a helper, not as a new engine module. This matches the existing pattern where game logic flows through verb handlers.

### 4. FSM Reveal via Engine, Not Player

The trap door's `hidden→revealed` FSM transition is triggered programmatically when the rug is moved, not by a player verb. This ensures the reveal happens as a consequence of moving the covering object.

### 5. reveals_exit Pattern

Objects can declare `reveals_exit = "direction"` to unhide a room exit when opened. The `open` handler checks this after successful FSM transitions.

## New Object Properties

| Property | Type | Description |
|----------|------|-------------|
| `movable` | boolean | Can be pushed/pulled/moved |
| `moved` | boolean | Has been moved from initial position |
| `resting_on` | string | ID of object this sits on (blocks that object's movement) |
| `covering` | table | List of object IDs this conceals |
| `push_message` | string | Custom message for push verb |
| `move_message` | string | Custom message for move/pull verb |
| `moved_room_presence` | string | Room presence after moved |
| `moved_description` | string | Description after moved |
| `moved_on_feel` | string | Feel text after moved |
| `discovery_message` | string | Message when revealed from covering |
| `reveals_exit` | string | Exit direction to unhide on open |

## New Verbs

PUSH, SHOVE, MOVE, SHIFT, SLIDE, LIFT — all route through `move_spatial_object()`.

## Team Impact

- **Content creators:** New objects can use `movable`, `covering`, `resting_on` properties for spatial puzzles
- **QA:** Test sequence: push bed → move rug → open trap door → down exit visible
- **Future:** The `covering` list pattern extends to paintings over safes, cloths over holes, etc.
