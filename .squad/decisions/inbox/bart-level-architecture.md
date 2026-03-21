# Decision: Level Data Architecture

**Author:** Bart (Architect)  
**Date:** 2026-07-21  
**Status:** Implemented  
**Requested by:** Wayne "Effe" Berry

---

## D-LEVEL001: Two-Layer Level Data Model

**Decision:** Levels are defined by two complementary data sources:

1. **Room-level field** (`level = { number = N, name = "..." }`) on every room `.lua` file — fast runtime access for UI (status bar).
2. **Level definition file** (`src/meta/levels/level-NN.lua`) — authoritative source of truth for room membership, completion criteria, boundaries, and object restrictions.

**Rationale:**
- Room field is denormalized for O(1) status bar reads (Smithers' use case).
- Level file holds structural data that doesn't belong on individual rooms (completion triggers, boundary definitions, restricted object lists).
- If they disagree, the level file wins. Moe keeps them in sync.

**Follows:** Principle 8 (engine executes metadata; objects declare behavior). Level definitions are pure data — no engine special-case code.

---

## D-LEVEL002: Declarative Completion & Advisory Restrictions

**Decision:**
- **Completion criteria** are declarative conditions in the level file. Multiple entries are OR'd — any match triggers completion. Current type: `reach_room` (with optional `from` constraint). Extensible to `solve_puzzle`, `collect_item`, etc.
- **Restricted objects** are advisory. The engine does NOT auto-strip inventory at level boundaries. Level designers must build diegetic removal mechanisms (per Wayne's directive in `docs/design/levels/level-design-considerations.md`).

**Rationale:**
- Declarative completion keeps the engine generic — it checks conditions, doesn't hard-code narrative logic.
- Advisory restrictions respect Principle 8 and the design rule that object removal must be natural (not arbitrary inventory stripping).
- Nelson can validate boundary states by cross-referencing `restricted_objects` against player inventory in tests.

---

## D-LEVEL003: Courtyard is Level 1

**Decision:** The courtyard room belongs to Level 1 ("The Awakening"), not Level 2.

**Rationale:** CBG's Level 1 master plan (`docs/levels/01/level-01-intro.md`) explicitly lists the courtyard as Room 6 of 7 in Level 1. It's an alternate path accessible via the bedroom window. Smithers' interim `LEVEL_MAP` had it as Level 2 — that was a best-guess without authoritative data. The `LEVEL_MAP` fallback is now obsolete since all rooms carry `room.level`.

---

## Impact on Team

- **Smithers:** `room.level` field is now live on all rooms. `status.get_level(room)` already prefers it over `LEVEL_MAP`. The fallback table can be removed at his discretion.
- **Moe:** When adding new rooms, include `level = { number = N, name = "..." }` after the `name` field. When a new level is created, add the room to the corresponding level definition file.
- **Nelson:** Can validate level completeness by loading `level-01.lua` and checking all listed rooms have matching `level` fields. Can test boundary transitions and restricted object enforcement.
- **CBG:** Level definition schema supports his design needs — completion criteria, room lists, boundary points.
