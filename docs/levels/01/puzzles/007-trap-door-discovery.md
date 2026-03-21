# Puzzle 007: Trap Door Discovery

**Status:** 🟢 In Game (Implicit / Core to 005)  
**Difficulty:** ⭐⭐⭐ Level 3 (Intermediate / Spatial Reasoning)  
**Zarfian Cruelty:** Polite (solvable through exploration, no instant failures)  
**Classification:** 🟢 In Game  
**Pattern Type:** Spatial Discovery + Object Layering  
**Author:** Sideshow Bob  
**Last Updated:** 2026-03-21

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Bedroom (hidden beneath rug, exit to cellar) |
| **Objects Required** | Rug (movable), Bed (on rug), Trap door (beneath rug), Brass key (beneath trap door) |
| **Objects Created** | None (objects already layered in room) |
| **Prerequisite Puzzles** | 001 (Light the Room — need light to see trap door clearly) |
| **Unlocks** | Exit to Cellar (progression) |
| **GOAP Compatible?** | Yes (partial: GOAP can auto-resolve if player states "move rug" or "find exit") |
| **Multiple Solutions?** | 1 (must move rug to discover trap door; no bypasses) |
| **Estimated Time** | 3–10 min (depends on exploration thoroughness) |

---

## Overview

The trap door is the exit from the bedroom—the gateway to the cellar and the next stage of the game. However, it's hidden beneath the rug that covers the bedroom floor. The player must realize that objects can be layered spatially (rug covers floor, bed sits on rug, trap door is under rug) and that moving/manipulating one object reveals what's underneath. This is the first major spatial discovery puzzle and teaches that physical arrangement of objects is meaningful and explorable.

---

## Solution Path

### Primary Solution: Move Rug to Reveal Trap Door

1. **Light the room (Puzzle 001 completion)** — The player should have lit the candle by this point, illuminating the bedroom fully.
2. **LOOK around** — With light, the player can see the bed is sitting on a large rug. Visual description includes: "A heavy rug covers most of the floor, worn and dusty."
3. **Explore spatially** — Player realizes: bed is ON rug; objects sit ON objects. Maybe something is UNDER the rug?
4. **PUSH bed** or **MOVE bed** — The player pushes the bed off the rug to clear the rug area. Message: "You shove the heavy bed across the stones. It scrapes loudly, revealing dusty floor beneath."
5. **PULL rug** or **MOVE rug** — The player pulls/rolls the rug to the side. As the rug moves: **Trap door is revealed.** Message: "You roll the dusty rug aside. Beneath it, a carved stone slab becomes visible—a trap door. Its iron hinges creak in the still air. Beside it, gleaming in your candlelight, lies a brass key."
6. **Discovery of brass key** — The brass key is now visible on/near the trap door. Description now includes both in the room view.
7. **TAKE brass-key** — Player takes the key into inventory.
8. **LOOK at trap-door** — Player examines the trap door. Description: "A trap door made of ancient stone, sealed shut. An iron lock mechanism suggests it requires a key to open."
9. **OPEN trap-door WITH brass-key** — Wait for later. Player can attempt this, but should realize they need to descend to the cellar.
10. **DESCEND** or **DOWN** — Player climbs through the trap door into the cellar below. Puzzle 005 complete; Puzzle 006 begins.

### Alternative Solutions

**None.** The trap door must be revealed by moving the rug. No alternate detection methods (like LISTEN for hollow sounds) are implemented. The spatial manipulation is the solution.

**Design note:** Future versions might allow a perceptive player to LISTEN and hear a hollow echo beneath the rug, providing a hint without requiring movement first. This would be a nice QoL addition but is not required for this version.

---

## What the Player Learns

1. **Objects are layered spatially** — Objects sit ON other objects. Furniture arrangement has meaning. Beds don't float; they sit on rugs.
2. **Layering hides content** — Things can be UNDER other things. What's under the rug? You must move it to find out.
3. **Moving objects has consequences** — When you move the bed, you expose the rug. When you move the rug, you expose the trap door. This is an emergent discovery chain.
4. **Spatial reasoning is puzzle-solving** — This is the first puzzle that requires thinking about physics and arrangement, not just tool chains.
5. **Room exits can be hidden** — The main progression exit (trap door leading to cellar) is not obvious. The player must explore and discover it.
6. **Light enables discovery** — Without lighting the room (Puzzle 001), the trap door is still there, but the player cannot see it well. FEEL would work in darkness, but visual inspection is easier.

---

## Failure Modes

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| Never move the bed or rug | Trap door remains hidden indefinitely | Continue exploring; player may eventually think to move furniture |
| Move furniture but don't LOOK carefully | May miss the trap door visually | FEEL around the floor; or try common exit keywords like "down" (if trap door is nearby) |
| Move rug but don't take brass key | Key remains on floor | LOOK again; TAKE brass-key manually |
| Attempt to OPEN trap-door without light | Can still open it (door unlocks with key), but descending into darkness is scary | Bring a light source (candle, match) before descending |

---

## Failure Reversibility

**Soft failure.** Moving the bed/rug is always reversible—the player can move them back, rearrange again, etc. There's no penalty for exploring. The trap door, once discovered, is always accessible. No locked-out state.

---

## Prerequisite Chain

**Objects:**
- Bed (movable furniture)
- Rug (movable, covers trap door)
- Trap door (exit, beneath rug)
- Brass key (on trap door)

**Verbs:**
- PUSH, MOVE, PULL (to move furniture)
- LOOK (to see trap door when revealed)
- FEEL (to find trap door in darkness if not lit)
- TAKE (to grab brass key)
- OPEN (to unlock and open trap door)

**Mechanics:**
- Spatial layering (objects ON objects, objects UNDER objects)
- Furniture mobility (beds/rugs can be moved)
- Object visibility (hidden until rug is moved)
- Inventory persistence (brass key stays with player)

**Puzzles:**
- Puzzle 001 (Light the Room): Helps with discovering the trap door visually

---

## Design Rationale

**Why this difficulty?**
Level 3 intermediate puzzle. It's more complex than a straightforward lock-and-key (Level 2), but less laterally tricky than Level 4. The player must:
1. Realize that objects are spatially arranged and movable
2. Hypothesize that something might be hidden under the rug
3. Systematically move furniture to uncover it

This tests spatial reasoning—a core skill for dungeon exploration games.

**Why this location?**
The bedroom is the starting room. Hiding the exit teaches the player early on: "This world rewards exploration and experimentation. You must interact with furniture, move things around, discover what's underneath." It's a foundational lesson for all subsequent dungeons.

**Why this object arrangement?**
- Bed ON rug (natural, makes sense narratively)
- Rug covers floor (natural)
- Trap door UNDER rug (clever hiding spot)
- Brass key NEAR trap door (logical reward placement)

The chain is intuitive once discovered but not obvious at first glance. Players who are used to "always explore every object" will naturally move furniture; players who treat rooms as static may need a hint.

---

## GOAP Analysis

**Is this puzzle GOAP-compatible?**
Partially. GOAP can help if the player expresses intent clearly:
- Player types: "escape the room" or "find the exit"
- GOAP might plan: move bed → move rug → explore → find trap door

However, GOAP doesn't usually "guess" that furniture should be moved without explicit instruction. This is a puzzle where manual exploration and player initiative matter more than automated planning. A better UX might provide a hint like "You notice the rug seems movable" if the player has been in the room for a while without discovering the trap door.

---

## Notes & Edge Cases

- **Rug immobility before moving bed:** In the current room data, the bed sits ON the rug. A player cannot move the rug while something is on it (to maintain physics integrity). They must move the bed first.
- **Visual feedback:** When the rug is moved, the room description should update to show the trap door clearly. Subsequent LOOK should always mention the trap door and brass key.
- **Reversibility of moves:** After the player moves the bed and rug, moving them back should not "hide" the trap door again. Once discovered, it's discovered.
- **Sensory in darkness:** A clever player in darkness could FEEL around the floor and detect the trap door's iron hinges by touch. This is a nice QoL feature—sensory diversity.
- **Torch bracket in cellar:** After the player descends into the cellar, they might return to the bedroom. The trap door should remain open and accessible, allowing backtracking if needed.

---

## Status

🟢 In Game (Implicit) — Trap door puzzle is baked into Puzzle 005 (Bedroom Escape) but is distinct enough to document separately as a spatial discovery puzzle.

**Owner:** Sideshow Bob  
**Builder:** Flanders (room spatial layout)  
**Tester:** Nelson  
**Last Tested:** 2026-03-21

---

## Related Systems

- **Puzzle 005:** Bedroom Escape (meta-puzzle that includes this spatial puzzle)
- **Spatial System:** Defined in `spatial-system.md` (object layering, ON/UNDER relationships)
- **Object Mobility:** Furniture can be moved; not all objects are static
- **Room Persistence:** Trap door state persists even after descending to cellar
