# D-CREATE-OBJECT-ACTION: Creature Object Creation Engine

**Author:** Bart (Architecture Lead)
**Date:** 2026-08-17
**Status:** ✅ Implemented
**Category:** Architecture
**Wave:** Phase 4 WAVE-4

## Decision

Added `create_object` action to the creature action dispatch system (`src/engine/creatures/actions.lua`). This is a **reusable, metadata-driven** pattern — any creature can create environmental objects by declaring `behavior.creates_object` in their metadata.

### Key Design Choices

1. **Cooldown uses `os.time()` (real seconds)** — not coupled to the presentation layer's game-time computation. Creature metadata specifies cooldown in real seconds. This avoids a dependency on `engine/ui/presentation.lua` from the creature subsystem.

2. **Condition function receives `(creature, context, helpers)`** — full context including helpers so conditions can query room contents, registry, etc.

3. **Object instantiation via shallow copy + `registry:register()`** — creature metadata provides `object_def` table (a template for the created object). Engine copies it, stamps a unique ID, sets `creator` field, registers in registry, and places in room via `room.contents`.

4. **NPC obstacle check in `navigation.lua`** — `room_has_npc_obstacle()` scans target room contents for `obstacle.blocks_npc_movement = true`. Integrated into `get_valid_exits()` so all NPC movement (wander, flee, bait-chase) respects obstacles. Player movement is unaffected.

### Files Modified

| File | Change |
|------|--------|
| `src/engine/creatures/actions.lua` | Added `create_object` action execution + scoring (~40 LOC) |
| `src/engine/creatures/navigation.lua` | Added `room_has_npc_obstacle()` + obstacle check in `get_valid_exits()` (~20 LOC) |

### Principle 8 Compliance

No spider-specific or creature-specific logic anywhere. The engine reads `behavior.creates_object` metadata and executes it generically. Any creature (spider, bird, ant) can use this pattern by declaring the appropriate metadata.

## Impact

- **Flanders:** Spider metadata should use `behavior.creates_object.object_def` (table of properties for the spawned object), `cooldown` (real seconds), `condition` (function), `narration` (string), `priority` (number, default 15).
- **Nelson:** Test `create_object` via mock creature with `creates_object` behavior. Test NPC obstacle blocking via `navigation.get_valid_exits()` with an obstacle object in target room.
