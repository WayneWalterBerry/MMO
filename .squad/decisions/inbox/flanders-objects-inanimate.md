# Decision: Objects Are Inanimate

**Decided By:** Wayne "Effe" Berry  
**Engineered By:** Flanders, Object & Injury Systems Engineer  
**Date:** 2026-03-24  
**Status:** IMPLEMENTED  

---

## Decision Statement

**Objects in the MMO engine system are INANIMATE.** Living creatures, animals, NPCs, and autonomous agents are NOT objects and must not be modeled using the object system. They are a separate, future feature requiring their own architecture.

## Rationale

The object system is optimized for **passive, state-driven entities**: furniture, tools, containers, weapons, consumables. These objects respond to player actions and world events but do not independently pursue goals or make decisions.

Living creatures have fundamentally different requirements:
- **Autonomous behavior** — independent decision-making, goal pursuit, planning
- **Spatial reasoning** — pathfinding, obstacle avoidance, territory management
- **Communication** — dialogue, relationship memory, dynamic responses
- **Agency** — creatures act on the world; objects are acted upon

Attempting to model creatures as objects leads to:
1. **Architectural bloat** — adding behavior trees, dialogue, and AI to objects complicates the system
2. **Design confusion** — a "rat object" looks and feels like furniture, but requires creature mechanics
3. **Implementation waste** — special-casing creatures within the object system duplicates work before the NPC system exists

## Implementation

### Removed
- **File:** `src/meta/objects/rat.lua` — Deleted (atmospheric creature incorrectly modeled as object)
- **Room Reference:** `src/meta/world/storage-cellar.lua` — Removed rat instance from room
- **Web Dist:** `web/dist/meta/rooms/storage-cellar.lua` — Removed rat instance from room
- **Web Dist:** `web/dist/meta/objects/8bf03d96-19dd-491d-b17f-f071ed9d028f.lua` — Deleted (compiled rat object)

### Added Documentation
- **File:** `docs/architecture/objects/core-principles.md` — Added new Principle 0: "Objects Are Inanimate"
  - Explains the distinction between objects and creatures
  - Provides design guidance with examples
  - References the future NPC system

## Design Guidance for Future Features

**When designing a feature:**
- **Is it alive or autonomous?** → Defer to NPC/creature system (future)
- **Is it passive and state-driven?** → Belongs in object system (now)

**Examples:**
- ✅ **Rat object** → NOT an object; requires creature AI
- ✅ **Rat trap** → IS an object; container/tool with states
- ✅ **Guard with patrol route** → NOT an object; requires dialogue and pathfinding
- ✅ **Guard helmet (loot)** → IS an object; equipment

## Future: NPC System Specification

When the NPC system is designed, it will handle:
- Behavior trees or state machines with goals
- Pathfinding and spatial reasoning
- Dialogue systems and memory
- Creature-specific profiles (rats, guards, merchants, etc.)
- Combat, social, and environmental AI

**Do not attempt to work around this decision by special-casing creatures as objects.**

---

## Sign-Off

**Flanders (Object & Injury Systems):** ✅ Implemented
- Removed rat object
- Updated core-principles documentation
- Removed room references
- No broken references remain

**Status:** CLOSED (All action items completed)
