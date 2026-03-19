# Puzzles

This directory documents all known puzzles in the MMO. Each puzzle teaches core mechanics, introduces game systems, or creates challenge scenarios through interaction with objects and tools.

## Format Convention

Each puzzle is documented with this structure:

```markdown
# Puzzle NNN: {Name}

## Overview
Brief description of what the player encounters and must solve.

## Room
Where this puzzle takes place in the game world.

## Required Objects
List of all objects needed to solve the puzzle (or key objects involved).

## Solution
Step-by-step walkthrough of the primary solution path.

## Alternative Solutions
Other ways to solve the puzzle (if any).

## What the Player Learns
Game mechanics and systems this puzzle teaches.

## Failure Consequences
What happens if the player fails or does something wrong.

## Status
Implementation status: Implemented / Designed / Concept
```

## Puzzle Index

### 001 — Light the Room
The first puzzle the player encounters when waking in total darkness.

**Core Mechanic:** Tool chains and light systems.  
**Status:** Designed  
**See:** [001-light-the-room.md](001-light-the-room.md)

---

### 002 — Poison Bottle
Identifying a dangerous object in darkness using multiple senses.

**Core Mechanic:** Sensory input and consequences.  
**Status:** Designed  
**See:** [002-poison-bottle.md](002-poison-bottle.md)

---

### 003 — Write in Blood
Using self-injury as a resource to accomplish a task.

**Core Mechanic:** Tool chains with dark consequences.  
**Status:** Designed  
**See:** [003-write-in-blood.md](003-write-in-blood.md)

---

### 004 — Inventory Management
Understanding the physical constraints of having two hands.

**Core Mechanic:** Inventory as a physical, strategic system.  
**Status:** Designed  
**See:** [004-inventory-management.md](004-inventory-management.md)

---

## Design Philosophy

All puzzles in this game follow these core principles:

1. **Tools enable verbs** — Without the right tool (matchbox, pen, knife), certain actions are impossible.
2. **Code is state** — When a puzzle changes the world (candle lights, paper gains writing, object breaks), the object's definition is rewritten. This is not a flag flip — it's a true state mutation.
3. **Multiple paths to victory** — Most puzzles have alternative solutions. Exploration and creativity are rewarded.
4. **Consequences matter** — Failure states exist. Wasting resources has real costs. Wrong actions have real penalties.
5. **Teach through discovery** — Puzzles teach mechanics by requiring players to use them. The light puzzle teaches tools, darkness, and discovery.

---

## See Also

- **Design Directives:** `docs/design/design-directives.md`
- **Tool Objects:** `docs/design/tool-objects.md`
- **Game Design Foundations:** `docs/design/game-design-foundations.md`
- **Architecture Decisions:** `.squad/decisions.md`
