# Decision: Extract Player System into Dedicated Subfolder

**Author:** Brockman (Documentation)  
**Date:** 2026-03-22  
**Status:** ✅ IMPLEMENTED  
**Commit:** f1935c7

## Problem

The architecture overview (`00-architecture-overview.md`) contained scattered player-related documentation across multiple layers:
- Layer 6: Player Model (inventory, hands, worn items, skills)
- Layer 8: Light & Dark System (sensory gating specific to player perception)
- Layer 2.5.5: Multi-Room System (player location tracking, movement)

This organization made it difficult to:
1. Find all player-related information quickly
2. Add detailed player mechanics docs without bloating the overview
3. Scale player system documentation as features grow (NPCs, combat, etc.)

## Solution

Created a dedicated `docs/architecture/player/` subfolder with three focused documents:

1. **player-model.md** — Complete player entity structure
   - Hand system (2 slots, capacity constraints)
   - Wearable system (body slots, vision blocking, containers)
   - Skills system (binary state, verb gating, tool combinations)

2. **player-movement.md** — Movement mechanics
   - Movement verbs (NORTH/SOUTH/UP/DOWN/etc.)
   - Exit system (accessibility checks, locked doors, keys)
   - Location tracking (`ctx.current_room`)
   - Multi-room architecture (objects persist, ticking scope)

3. **player-sensory.md** — Sensory experience
   - Light & Dark system (light sources, darkness gating)
   - Vision blocking (wearables, puzzles)
   - Sensory verb gating (LOOK/FEEL/SMELL differences)

## Benefits

1. **Single Point of Reference:** All player docs in one place
2. **Scalable:** Easy to add NPC, combat, or multiplayer docs later
3. **Cross-References:** Overview stays clean while pointing to detailed docs
4. **Mirrors Other Subsystems:** Consistent with objects/, rooms/, engine/ organization
5. **Content Preserved:** Every line moved; nothing lost or forgotten

## Architecture Pattern

Follows the established pattern:
- **Core Architecture Overview:** High-level system map
- **Subsystem Folders:** objects/, rooms/, engine/, **player/**
- **Detailed Specs:** Linked from overview with brief summaries

## Implementation

- Extracted all player-related content from overview
- Added brief summaries in Layer 6, Layer 8, and Layer 2.5.5
- Added cross-reference section at top of each new player doc
- Updated cross-references in overview to point to player/ folder

## No Content Lost

Every section removed from overview appears in new docs:
- ✅ Player inventory structure (hands, worn, skills)
- ✅ Hand slot mechanics
- ✅ Wearable system details
- ✅ Skills system mechanics
- ✅ Light & dark sensory gating
- ✅ Vision blocking mechanics
- ✅ Movement workflow and exit handling
- ✅ Location tracking and multi-room architecture

---

**Next Steps:** Monitor player-system docs as NPC and combat subsystems evolve; create cross-links to keep the ecosystem coherent.
