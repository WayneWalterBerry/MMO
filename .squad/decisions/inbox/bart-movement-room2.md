# Decision: Movement Verbs + Room 2 + Multi-Room Engine

**Author:** Bart (Architect)  
**Date:** 2026-07-18  
**Status:** IMPLEMENTED  
**Commit:** db0deed

## Context

Nelson's pass-005 confirmed that exits display correctly but every movement command returns "I don't understand that." Movement was the single most critical missing feature — players were trapped in the bedroom.

## Decisions Made

### D-42: Movement Handler Architecture
**Decision:** Single `handle_movement(ctx, direction)` function handles all movement. Direction aliases, keyword search, accessibility checks, and room transition all flow through this one function.  
**Rationale:** Centralizes all movement logic. Every movement verb (north, go, enter, descend, climb) delegates to the same handler. Easy to add new movement verbs later.

### D-43: Multi-Room Loading at Startup
**Decision:** All room files in `src/meta/world/` are loaded at startup into a shared `context.rooms` table. All object instances across all rooms share a single registry.  
**Rationale:** Simplest correct approach for V1. Objects in the registry persist regardless of which room the player is in. Room state (contents lists) persists naturally. Lazy-loading would add complexity with no benefit at this scale.  
**Trade-off:** Memory usage grows with room count, but irrelevant for V1.

### D-44: Per-Room Contents, Shared Registry
**Decision:** Each room has its own `room.contents` array. Objects live in the shared registry. Moving objects between rooms means updating the contents arrays.  
**Rationale:** The registry is the single source of truth for object state. Contents arrays just track which objects are "in" which room. This naturally supports dropping items in one room and finding them later.

### D-45: FSM Tick Scope
**Decision:** FSM ticks only run on objects in the current room + player hands. Objects in other rooms don't tick while the player is away.  
**Rationale:** Correct for V1 — candles in other rooms shouldn't burn down while the player isn't there. If we later need world simulation, we can add a global tick pass.

### D-46: Cellar as Room 2
**Decision:** The cellar is the first expansion room, accessed via the trap door stairs. It's naturally dark (no windows), has a locked iron door to the north (future expansion hook), and contains minimal atmospheric objects (barrel, torch bracket).  
**Rationale:** The trap door puzzle was already built. The cellar is the natural destination. The locked north door provides a future expansion point without requiring immediate content.

### D-47: Exit Display Name Convention
**Decision:** FSM state labels should NOT appear in object display names. State is conveyed through descriptions and room_presence fields.  
**Rationale:** BUG-027 showed that "a trap door (open)" leaks implementation into player-facing text. The fix strips the suffix. Going forward, FSM state names should always be clean display names.

## Files Changed
- `src/main.lua` — Multi-room loading replaces single-room loading
- `src/engine/verbs/init.lua` — 130+ lines of movement verb handlers
- `src/engine/loop/init.lua` — NLP preprocessing for stair phrases
- `src/meta/objects/trap-door.lua` — BUG-027 fix
- `src/meta/world/cellar.lua` — New room
- `src/meta/objects/barrel.lua` — New cellar object
- `src/meta/objects/torch-bracket.lua` — New cellar object

## Open Items
- Hallway room (north from bedroom) not yet implemented — shows "cannot yet reach"
- Cellar north door locked with no key — future expansion
- Room-specific ambient sounds not implemented
- No unlock/lock verb handler yet (needed for future locked doors)
