# Decision: Combat-Loot Puzzles as Approved Puzzle Mechanic

**Date:** 2026-07-29  
**Proposer:** Sideshow Bob (Puzzle Master)  
**Requestor:** Wayne Berry  
**Status:** Approved

## Overview

**Combat-loot puzzles** are an approved design pattern for Level 1 and beyond. This means players may need to **fight creatures to obtain items required for puzzle solutions**.

## The Principle

Fighting is not purely a survival mechanic—it can be a **problem-solving mechanic**. When a player kills a creature and collects its loot, they are solving a puzzle by choosing combat as their solution path.

This pattern ties into Phase 3 development (creature inventory, death/corpse systems) and creates new **combat-puzzle hybrid gameplay**.

## Mechanics

- **Creatures carry loot:** Objects in a creature's inventory (or dropped on death)
- **Death → Loot access:** When a creature dies, its inventory becomes accessible
- **Puzzle-critical items:** Some items needed to solve puzzles are only available from creatures
- **Player agency:** Creature loot is optional unless required by a puzzle
- **Multiple solution paths:** Non-combat solutions must always exist as alternatives (where narratively sensible)

## Examples (Puzzle Seeds for Future Design)

1. **Spider Fang Antidote** — A spider in the cellar carries (or drops) a fang with venom properties. Grinding the fang creates an antidote to a poison trap. Non-combat path: slow alchemy/extraction from environment.

2. **Wolf Tooth Key** — A wolf in the courtyard wears a key on a cord around its neck. Killing the wolf drops the key. Non-combat path: find the locksmith's spare in an obscure location.

3. **Bat Wing Torch** — A bat in the deep cellar sheds a wing (or drops it on death). Bat wings + oil create a luminescent torch. Non-combat path: craft using alternative reagents (rare flowers).

## Handoffs & Dependencies

- **Flanders:** Add `inventory` field to creature definitions (carried_items). Add `drops_on_death` metadata.
- **Bart:** Ensure creature death triggers inventory drop into room `contents`. Validate containment of dropped items.
- **CBG:** Advise on creature encounter design to ensure combat loot doesn't trivialize puzzles.
- **Nelson:** Test corpse loot access, multi-item drops, player inventory limits.

## Principles Respected

- **Principle 0:** Objects are inanimate; creatures are separate entities with behavior
- **Principle 8:** Creature definitions declare loot metadata; engine executes (no hardcoded verb logic)
- **Principle 9:** Creature materials (teeth, fangs, wings) obey real-world properties

## Future Considerations

- Creature behavior may depend on loot they carry (wounded or encumbered creatures react differently)
- Loot drop rates can vary by creature species and condition
- Corpse decay may consume loot over time (Phase 3)
