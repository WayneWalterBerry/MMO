# Puzzle 001: Light the Room

**Status:** 🟢 In Game  
**Difficulty:** ⭐⭐ Level 2  
**Cruelty Rating:** Polite (soft failure with recovery path)  
**Author:** Sideshow Bob  
**Last Updated:** 2026-03-20

---

## Overview

The player wakes in complete darkness in a bedroom around 2–3 AM. They cannot see anything and must find a light source. This is the first puzzle and teaches the core tool system: finding objects, using containers, and chaining compound tool actions together to accomplish a goal.

## Room

Bedroom (starting location)

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Bedroom |
| **Objects Required** | nightstand, drawer, matchbox, match (7 instances), candle |
| **Objects Created** | match-lit (state mutation of match) |
| **Prerequisite Puzzles** | None |
| **Unlocks** | Visual exploration of bedroom; foundation for Puzzle 002+ |
| **GOAP Compatible?** | Yes (full auto-resolution available) |
| **Multiple Solutions?** | 2 (strike match OR wait for dawn) |
| **Estimated Time** | 2–5 min (first-time), < 1 min (repeat) |

---

## Required Objects

- Nightstand (furniture with drawer)
- Matchbox (container with striker surface, holds individual matches)
- Individual matches (7 inside matchbox; each is a separate object)
- Candle (target object that can be lit)

## Solution

### Primary Path: Light the Candle

1. **FEEL around** — In darkness, the player uses FEEL to explore the room blindly. This discovers the nightstand beside the bed.
2. **FEEL nightstand** — The player explores the nightstand by touch, discovering a drawer.
3. **OPEN nightstand** — The drawer opens (requiring an OPEN verb without light).
4. **FEEL inside drawer** — By touch, the player finds the matchbox.
5. **TAKE matchbox** — Player takes the matchbox into inventory.
6. **OPEN matchbox** — Player opens the matchbox, revealing 7 individual matches inside. The matchbox is a container — its contents are listed.
7. **TAKE match** — Player takes one match from the matchbox into inventory.
8. **STRIKE match ON matchbox** — This is a **compound tool action**. The match requires a striker surface (the matchbox's `has_striker` property) to ignite. The match mutates: `match` → `match-lit`. The lit match now has `provides_tool = "fire_source"` and `casts_light = true` (small radius). A tiny flame appears. The match is burning — the player has ~30 game seconds before it burns out.
9. **LIGHT candle WITH match** — The player applies the lit match (fire_source) to the candle. The candle's code mutates: `candle.lua` → `candle-lit.lua`. The candle now has `casts_light = true`, illuminating the room. The match is consumed in the process.
10. **Room illuminated** — The player can now see. All objects in the room become visible. The player learns they're in a bedroom with furniture, and can now read labels, explore visually, etc.

## Alternative Solutions

### Daytime Path: Wait for Natural Light

The player can choose to wait (in real time, approximately 3–4 minutes pass) until in-game time reaches 6 AM. When daytime arrives:

1. **OPEN curtains** — The window behind the curtains provides natural light, illuminating the room.
2. **Navigate without candle** — The room is now visible without lighting the candle. The player can explore and interact with objects normally.

**Trade-off:** This path is slower but consumes no matches. A patient player can avoid tool usage entirely for this puzzle.

### Alternative: Light Candle Without Taking It

The candle sits on TOP of the nightstand. A player could:

1. Find the matchbox and strike a match (steps 1–8 above).
2. **LIGHT candle WITH match** while the candle remains on the nightstand.
3. The room illuminates without the player taking possession of the candle.

**Trade-off:** The candle remains on the nightstand and cannot be carried elsewhere.

## What the Player Learns

1. **FEEL works in darkness** — Sensory verbs function without light. The player discovers that darkness is not a complete blocker, just a limitation.
2. **Tools are objects** — The matchbox is not an abstract inventory system; it's a physical container that must be found, opened, and has things inside.
3. **Containers have contents** — The matchbox is a container. Opening it reveals individual matches. You take a match OUT of the matchbox. Containment is a physical reality.
4. **Compound tool actions** — Striking a match requires BOTH the match AND the matchbox (its striker surface). This teaches that some actions need two specific objects working together. Neither object alone can produce fire.
5. **Consumable resources** — Matches are limited (7 available). Using a match consumes it. Lit matches burn out after ~30 seconds if not used. Resource management is important.
6. **Tool capability matching** — The lit match provides `fire_source`. The candle requires `fire_source`. Any fire source can light any candle — capability matching, not item-ID matching.
7. **Objects cast light** — When an object has `casts_light = true`, it illuminates the surrounding room. Lighting objects is a core mechanic.
8. **State mutations are visible** — When the candle lights, it changes fundamentally. It's not a flag flip — the candle becomes a different object visually and functionally.

## Failure Consequences

### Running Out of Matches
If the player wastes all 7 matches without lighting the candle:

- The matchbox is simply empty (contents = {}). No special mutation needed — an empty container is just an empty container.
- The player is left in darkness with no remaining fire source.
- **Soft failure:** The player can wait for daytime (6 AM) and use natural light. This is inconvenient but not a softlock.
- **Learning moment:** Resource management matters. Wasting tools has real costs.

### Match Burns Out
If the player strikes a match but doesn't use it within ~30 game seconds:

- The match burns down to the player's fingers and is consumed.
- The player must strike another match. This teaches urgency — lit matches are temporary.

### Fumbling in Darkness (Flavor)
Attempting actions in darkness without light might display messages like:

- "You fumble in the darkness..."
- "You can't see well enough to do that."

This reinforces that light is valuable and darkness is a real constraint.

### Trying to Light Candle Without Fire Source
If the player tries `LIGHT candle` without possessing a fire source:

- Engine returns: "You have nothing to light it with."
- The player must find a tool before proceeding.
- **Learning moment:** Tools are required, not optional.

## Status

**🟢 In Game** — Tested and working.

**Owner:** Sideshow Bob  
**Builder:** Flanders (Object Designer)  
**Tester:** Nelson  
**Last Tested:** 2026-03-15

---

## Difficulty Rating: ⭐⭐ Level 2 (Introductory)

### Rating Analysis

| Factor | Analysis | Score |
|--------|----------|-------|
| **Step count** | 9 actions (FEEL → open drawer → take matchbox → open matchbox → take match → strike match → light candle), but GOAP collapses 5–7 | 3–5 actions perceived |
| **Tool chain depth** | Single linear chain: nightstand → matchbox → match → strike → light | Depth 2 (simple) |
| **Clue obviousness** | Nightstand contextually adjacent to bed (narratively sensible); matches contextually near candle; FEEL works in darkness (taught immediately via failure feedback) | Contextual (non-explicit but reasonable) |
| **GOAP coverage** | GOAP can auto-resolve entire chain if player discovers match location first. Or player manually executes. | Partial (scaffolding + player choice) |
| **Failure reversibility** | Soft only: 7 matches available (generous for first puzzle); player can waste them and wait for dawn (3–4 min). Encourages experimentation. | Soft |
| **Lateral thinking required?** | No. Solution is linear and hinted by narrative ("you wake in darkness, you need light"). | None |
| **Player learning time** | 2–5 min (first-time); < 1 min (experienced) | Appropriate for opening |

### Justification

This is the opening puzzle. It teaches core systems (containment, compound tools, sensory verbs, GOAP scaffolding) with a linear solution path and no real failure penalty. The puzzle is designed to build confidence before introducing Level 3 complexity. Despite 9 discrete actions, the conceptual challenge is minimal. GOAP can collapse the chain, but player can also manually execute. The narrative guides the player toward the solution. This is a **tutorial-grade** Level 2, not a challenge.

### Cruelty Analysis: **Polite**

- **Running out of matches:** Soft failure. Matchbox becomes empty, but player can wait for dawn (3–4 real minutes).
- **Match burns out:** Soft failure. Player strikes another match. Teaches urgency.
- **Visual feedback:** Player always knows when light has been achieved (room description changes).
- **No hidden gotchas:** Everything works as expected. No trick conditions or cryptic feedback.

---

## Design Notes

### Puzzle Patterns Applied

This puzzle uses two core patterns:

1. **Lock-and-Key (Compound):** Darkness is the "lock." Fire source is the "key." Match requires striker surface (matchbox) to ignite—this is a compound lock (two objects required).
2. **Combination/Synthesis:** Match (object A) + matchbox striker (object B) → lit match (new state). Lit match + candle → illuminated candle.
3. **Transformation/State Mutation:** match → match-lit (state change with new properties: `casts_light`, `provides_tool`). Consumed resource (burnout timer).
4. **Discovery/Sensory:** FEEL works in darkness, guiding exploration without light.

### Why These Objects?

- **Matchbox as container with 7 matches:** The matchbox is a proper container (like the sack) holding individual match objects. Each match is a real thing you take out, hold, and strike. 7 matches provides generous margin for experimentation — this is the first puzzle and we want players to learn, not suffer. The physical reality of taking a match out of a box is more immersive than an abstract "charges" counter.
- **Compound action (STRIKE match ON matchbox):** This is the first compound tool action. The match alone can't ignite. The matchbox alone can't ignite. You need both — the match head AND the striker surface. This teaches players that some tools require a second object to activate.
- **Match-lit as temporary fire_source:** The lit match is a time-limited resource. It provides `fire_source` and `casts_light`, but burns out in ~30 game seconds. This creates urgency and teaches that some tools are temporary.
- **Nightstand drawer:** Natural place to look for matches. The closed drawer teaches the containment system. The nightstand location is logical without being obscure.
- **Candle on nightstand top:** Visible (or discoverable by FEEL) once the drawer is found. Adjacency suggests the matches might be nearby.

### Why Start in Darkness?

- **Narrative:** Waking up in darkness is more dramatic than waking to daylight.
- **Tutorial:** Darkness forces the player to learn FEEL and non-visual interaction immediately.
- **Tool teaching:** The player must find and use tools to solve a simple problem. This establishes that tools are central to gameplay.

### Time Scale

- **Real time:** 1 real hour = 1 full in-game day.
- **Daytime window:** 6 AM to 6 PM in-game.
- **Wait time to dawn:** ~3–4 real minutes from typical play start time (2–3 AM in-game).

This makes the "wait for daylight" path feel viable but slower than finding the matches.

---

## Related Systems

- **Light System:** Defined in `design-directives.md` (Light & Time System section)
- **Tool Convention:** Defined in `design-directives.md` (Tools System section)
- **Compound Tool Pattern:** Defined in `tool-objects.md` (Compound Tool Actions section)
- **Consumable Pattern:** Defined in `tool-objects.md` (Consumable Tools section)
- **Object: Matchbox:** Container with striker, defined in `src/meta/objects/matchbox.lua`
- **Object: Match:** Individual match, defined in `src/meta/objects/match.lua`
- **Object: Match-lit:** Lit match variant, defined in `src/meta/objects/match-lit.lua`
