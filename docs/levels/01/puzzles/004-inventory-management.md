# Puzzle 004: Inventory Management

**Status:** 🟡 Wanted  
**Difficulty:** ⭐ Level 1 (Trivial / System Teaching)  
**Zarfian Cruelty:** Polite (soft constraint, learnable via failure)  
**Classification:** 🟡 Wanted  
**Pattern Type:** System Constraint + Resource Management  
**Author:** Sideshow Bob  
**Last Updated:** 2026-03-21

---

## Overview

The player has two hands. Certain actions (like striking a match) require both hands to be free. If the player is carrying too much, they cannot perform compound tool actions. This puzzle teaches that inventory is physical and strategic, not a magical bag. Early in the game, a sack or bag found in the bedroom becomes crucial: it frees up hand slots by providing a container to carry multiple items without juggling them.

## Room

Bedroom (and extends to anywhere the player carries items)

## Required Objects

- Matchbox and matches (require both hands free to strike)
- Sack or small bag (solves the hand-shortage problem)
- Optional: backpack (upgrades from sack, provides even more capacity without taking hand slots)

## Solution

### The Problem: Not Enough Hands

**Scenario:** Player has found a matchbox but is carrying a rock, a book, and a stick. They're holding items in both hands. They attempt `STRIKE match ON matchbox`:

- Engine checks: Player has two hands. Each hand is occupied (rock in left, book in right).
- Result: "Your hands are full. You need both hands free to strike a match."
- Player realizes: Inventory has limits.

### The Solution: Find a Sack

1. **Find sack or bag in bedroom** — A sack (or similar container) is located somewhere in the bedroom (e.g., under the bed, in the wardrobe, or hanging on a hook). This is the first bag the player can find.
2. **PUT items IN sack** — Player uses the PUT verb to place items (rock, book, stick) into the sack. The sack is now holding 3 items. Player's hands are now free.
3. **TAKE sack** — Player takes the sack in one hand (or carries it by a handle). Sacks/bags take up one hand slot but hold multiple items inside.
4. **Now hands are free** — Player now has one free hand and is "carrying sack" with the other. With one free hand, they still can't strike a match (which needs both hands). They drop the sack.
5. **DROP sack** — Player sets the sack down on the ground. Now both hands are free.
6. **STRIKE match ON matchbox** — Success. Both hands are free. Player can now light the candle.
7. **TAKE sack again** — After striking the match, player picks up the sack again to carry other items.

**Learning:** Inventory management is strategic. Sacks let you carry more, but compound actions require hands-free status.

### Upgrade Path: Backpack

A backpack (a more advanced bag) might be found or crafted later:

1. **Find or craft backpack** — Backpacks are wearable and don't take a hand slot.
2. **WEAR backpack** — Player puts on the backpack. It's now worn on their back and provides inventory space without using hand slots.
3. **Both hands remain free** — With a backpack worn, the player can carry a matchbox in one hand, strike a match, and still have capacity for items. Hands are not consumed by the backpack.
4. **Gameplay improvement** — Backpack is an upgrade that makes inventory management less tedious.

## Alternative Solutions

### No Alternatives — This Is a Constraint, Not a Puzzle

Unlike Puzzle 001 (Light the Room), this isn't a puzzle with multiple solution paths. It's a **system constraint** that teaches game rules:

- **Without managing inventory:** Player's hands are full. They can't perform compound actions. They're stuck.
- **With sack:** Player can carry more items but still must manage hands for compound actions.
- **With backpack:** Player has freedom to perform actions while carrying many items.

There's no "bypass" or alternate solution. The player must learn hand management or suffer limitations.

## What the Player Learns

1. **Inventory is physical** — Not a magical bag with infinite space. Items take up space. Hands can hold a limited number of items.
2. **Two hands are precious** — Compound actions (striking a match) require both hands free. If hands are occupied, the action fails.
3. **Containers solve inventory problems** — A sack lets you carry multiple items in one "slot" (one hand). This is the first solution to hand management.
4. **Strategic inventory management** — Before attempting a compound action, the player might need to drop items or put them in a container.
5. **Upgrades improve quality of life** — A backpack is worn and doesn't consume hand slots. It's an upgrade that removes tedium.
6. **Wearables are different from held items** — Backpack is worn (not held). Gloves, boots, armor, etc. would also be worn. This teaches a system layer: held vs. worn.

## Failure Consequences

### Attempting Compound Action With Hands Full
- Engine returns: "Your hands are full. You need [both hands / one free hand / X free hands] to do that."
- Player must drop items or move them to a container.
- **Learning moment:** Plan your inventory before committing to actions.

### Running Out of Container Space
If the sack is full (capacity = 4 items, for example) and the player tries to add a 5th:

- Engine returns: "The sack is full."
- Player must remove an item or find a larger container.
- **Learning moment:** Even containers have limits.

### Dropping Important Items
If the player drops a key item (e.g., the matchbox) to free hands and then moves to another room:

- The item remains on the ground in the previous room.
- Player must return to retrieve it.
- **Learning moment:** Dropping items has consequences. Track what you've left behind.

## Status

**Designed** — Detailed game design established. Awaiting implementation.

---

## Design Notes

### Why This Matters

Inventory management in text-based games is often abstracted away (unlimited magical bags). This game makes it physical:
- Real objects take up space.
- Real hands have limited capacity.
- Real strategic choices emerge.

This creates emergent gameplay: should I carry the heavy rock for defense or drop it to move faster? Should I fill my sack with scrolls or save space for food?

### Two Hands Mechanics

Per design-directives.md:
- "Striking a match needs both hands free" (from Puzzle 004 design section).
- Other compound actions might also require free hands: opening a lock with a crowbar, crafting with tools, etc.

### Sack vs. Backpack

**Sack:**
- Portable container (can be picked up or left behind)
- Takes up one hand slot
- First bag the player finds
- Capacity: ~4 items

**Backpack:**
- Wearable (worn like clothes)
- Does not take up a hand slot
- Upgrade found or crafted later
- Capacity: ~6 items
- More comfortable for long journeys

Both solve different problems. Sack is immediate relief. Backpack is long-term comfort.

### Future Expansions

- **Weight management:** Some items weigh more than others. A backpack full of stones is heavier to carry.
- **Encumbrance:** Very heavy items slow the player down.
- **Skill upgrades:** Learning a carrying skill might increase capacity without new bags.
- **Magic bags:** Much later, magical bags might provide unlimited space (but at a cost).

---

## Related Systems

- **Inventory System:** Core gameplay mechanic (defined in game engine)
- **Container Objects:** Sacks, bags, backpacks (not yet documented in tool-objects.md)
- **Wearable System:** Backpacks, armor, clothes (not yet documented)
- **Compound Tools:** Requires two hands free (defined in tool-objects.md and design-directives.md)
