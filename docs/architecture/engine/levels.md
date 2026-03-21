# Level Architecture

**Author:** Bart (Architect)  
**Date:** 2026-07-21  
**Status:** Implemented (data model); enforcement passive  

---

## Overview

Levels group rooms into cohesive gameplay experiences with defined boundaries, completion criteria, and narrative arcs. The level system is a **data layer** — level definitions are pure Lua metadata that the engine, UI, and tooling can query without special-case code.

Two complementary data sources define the level system:

1. **Room-level field** — each room `.lua` file carries `level = { number, name }` inline.  
2. **Level definition file** — `src/meta/levels/level-NN.lua` holds the authoritative level metadata: room membership, completion triggers, boundaries, and restricted objects.

### Why Two Sources?

- The **room-level field** is fast to read at runtime — Smithers' status bar (and any future UI) can display the current level without loading the full level definition.  
- The **level definition file** is the source of truth for structural queries: "which rooms belong to Level 1?", "is this a boundary exit?", "has the player completed the level?"

If they ever disagree, the level definition file wins. Moe keeps room fields in sync when rooms are added or moved between levels.

---

## Room-Level Field

Every room `.lua` file includes a `level` table immediately after the `name` field:

```lua
return {
    guid = "...",
    template = "room",

    id = "start-room",
    name = "The Bedroom",
    level = { number = 1, name = "The Awakening" },
    keywords = { ... },
    ...
}
```

### Fields

| Field    | Type   | Description                          |
|----------|--------|--------------------------------------|
| `number` | number | Level number (1-based, sequential)   |
| `name`   | string | Human-readable level name            |

### Consumer: Status Bar

`engine/ui/status.lua` reads `room.level` via `status.get_level(room)`. If present, it displays `Lv 1: The Awakening — THE BEDROOM`. The hardcoded `LEVEL_MAP` fallback can be removed once all rooms carry the field.

---

## Level Definition Files

Located at `src/meta/levels/level-NN.lua`. Each file returns a Lua table:

```lua
return {
    guid = "...",
    template = "level",

    number = 1,
    name = "The Awakening",
    description = "...",

    rooms = { "start-room", "cellar", ... },
    start_room = "start-room",

    completion = {
        { type = "reach_room", room = "hallway", from = "deep-cellar", message = "..." },
        { type = "reach_room", room = "hallway", from = "courtyard",   message = "..." },
    },

    boundaries = {
        entry = { "start-room" },
        exit  = {
            { room = "hallway", exit_direction = "north", target_level = 2 },
        },
    },

    restricted_objects = {
        -- Objects that must not cross to the next level
    },
}
```

### Top-Level Fields

| Field               | Type   | Description                                      |
|---------------------|--------|--------------------------------------------------|
| `guid`              | string | Unique identifier for the level definition        |
| `template`          | string | Always `"level"`                                  |
| `number`            | number | Level number (matches room `level.number`)        |
| `name`              | string | Level name (matches room `level.name`)            |
| `description`       | string | Narrative summary for tooling / documentation     |
| `rooms`             | table  | Ordered list of room IDs belonging to this level  |
| `start_room`        | string | Room ID where the player begins this level        |
| `completion`        | table  | Array of completion criteria (OR'd)               |
| `boundaries`        | table  | Entry/exit points for level transitions           |
| `restricted_objects`| table  | Object IDs that should not cross to the next level|

### Completion Criteria

Each entry in the `completion` array describes one way the player can complete the level:

| Field     | Type   | Description                                          |
|-----------|--------|------------------------------------------------------|
| `type`    | string | Trigger type: `"reach_room"` (more types as needed)  |
| `room`    | string | Target room ID that triggers completion              |
| `from`    | string | (optional) Room the player must arrive from          |
| `message` | string | Narrative text shown on completion                   |

Multiple entries are OR'd — any single match triggers completion. The `from` field is optional; if omitted, reaching the room from any direction counts.

### Boundaries

**Entry points** — rooms where the player can enter this level (typically `start_room` plus any alternate entry from a previous level).

**Exit points** — specific room exits that lead to the next level:

| Field            | Type   | Description                              |
|------------------|--------|------------------------------------------|
| `room`           | string | Room ID containing the exit              |
| `exit_direction` | string | Direction key in the room's `exits` table|
| `target_level`   | number | Level number the exit leads to           |

### Restricted Objects

Per Wayne's directive (`docs/design/levels/level-design-considerations.md`):

> If a level designer does NOT want an object to transfer to the next level, there MUST be a task or puzzle that destroys, consumes, or removes that object before the player can enter the next level.

The `restricted_objects` list declares which object IDs should not cross. The engine does **not** auto-strip them — the level designer must ensure a diegetic removal mechanism exists. This list is for validation and testing (Nelson can verify boundary states).

---

## Current Levels

### Level 1: The Awakening

**File:** `src/meta/levels/level-01.lua`

**Rooms (7):**

| Room ID          | Name                 | Path Type       |
|------------------|----------------------|-----------------|
| `start-room`     | The Bedroom          | Critical path   |
| `cellar`         | The Cellar           | Critical path   |
| `storage-cellar` | The Storage Cellar   | Critical path   |
| `deep-cellar`    | The Deep Cellar      | Critical path   |
| `hallway`        | The Manor Hallway    | Critical path   |
| `crypt`          | The Crypt            | Optional         |
| `courtyard`      | The Inner Courtyard  | Optional (alt)   |

**Completion:** Reach the hallway from the deep cellar (primary) or from the courtyard (alternate).

**Exit to Level 2:** Hallway → NORTH (grand staircase).

---

## Engine Integration (Future)

The level data is passive for now — the engine does not enforce boundaries or check completion. Future integration points:

1. **Status bar** — Already works via `room.level` (Smithers).
2. **Completion check** — Engine loop checks `completion` criteria on room transitions; fires `on_level_complete` callback.
3. **Boundary enforcement** — On exit transitions matching `boundaries.exit`, engine checks `restricted_objects` against player inventory and warns/blocks.
4. **Level loader** — Engine loads level definitions at startup to build a level registry alongside the room registry.

These are additive — the data model supports them without schema changes.

---

## Design Principles

1. **Data over code** — Levels are metadata, not engine logic. Follows Principle 8.
2. **Room-level field is denormalized** — Intentional duplication for fast UI reads. Level file is source of truth.
3. **Completion is declarative** — Level files declare *what* triggers completion; the engine decides *when* to check.
4. **Object restrictions are advisory** — The engine won't silently strip inventory. Designers must build diegetic removal puzzles.
5. **Extensible** — New completion types (`solve_puzzle`, `collect_item`, `defeat_enemy`) can be added to the `type` field without schema changes.
