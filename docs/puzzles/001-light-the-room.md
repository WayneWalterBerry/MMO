# Puzzle 001: Light the Room

## Overview

The player wakes in complete darkness in a bedroom around 2–3 AM. They cannot see anything and must find a light source. This is the first puzzle and teaches the core tool system: finding objects, using containers, and chaining tools together to accomplish a goal.

## Room

Bedroom (starting location)

## Required Objects

- Nightstand (furniture with drawer)
- Matchbox (container with matches inside)
- Individual matches (consumable tool, provides `fire_source`)
- Candle (target object that can be lit)
- Matchbox striker surface (built into matchbox)

## Solution

### Primary Path: Light the Candle

1. **FEEL around** — In darkness, the player uses FEEL to explore the room blindly. This discovers the nightstand beside the bed.
2. **FEEL nightstand** — The player explores the nightstand by touch, discovering a drawer.
3. **OPEN nightstand** — The drawer opens (requiring an OPEN verb without light).
4. **FEEL inside drawer** — By touch, the player finds the matchbox.
5. **TAKE matchbox** — Player takes the matchbox into inventory.
6. **OPEN matchbox** — Player opens the matchbox, revealing individual matches inside (matchbox has 3 matches).
7. **TAKE match** — Player takes one match from the matchbox.
8. **STRIKE match ON matchbox** — This is a compound tool action. The player uses the match against the matchbox striker surface. The engine consumes one match charge from the matchbox (it now has 2 matches left) and creates a lit-match object. The match cannot exist in inventory as a separate object — it's consumed and replaced with a visual representation of "a lit match" in the player's hand.
9. **LIGHT candle WITH match** — The player applies the lit match to the candle. The candle's code mutates: `candle.lua` → `candle-lit.lua`. The candle now has `casts_light = true`, illuminating the room.
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
2. **Tools are objects** — The matchbox is not an abstract inventory system; it's a physical object that must be found, picked up, and opened.
3. **Containers have contents** — The matchbox is a container. Opening it reveals contents inside. Containment is a physical reality in the game world.
4. **Tools enable verbs** — Without a match (fire_source capability), the player cannot light the candle. The verb is blocked until the tool exists.
5. **Compound tools exist** — Striking a match requires both the match and the matchbox striker. This teaches that some actions need two specific objects.
6. **Consumable resources** — Matches are limited (3 available). Using a match consumes it. Resource management is important.
7. **Objects cast light** — When an object has `casts_light = true`, it illuminates the surrounding room. Lighting objects is a core mechanic.
8. **State mutations are visible** — When the candle lights, it changes fundamentally. It's not a flag flip — the candle becomes a different object visually and functionally.

## Failure Consequences

### Running Out of Matches
If the player wastes all 3 matches without lighting the candle:

- The matchbox mutates to `matchbox-empty.lua` (an empty, useless container).
- The player is left in darkness with no remaining fire source.
- **Soft failure:** The player can wait for daytime (6 AM) and use natural light. This is inconvenient but not a softlock.
- **Learning moment:** Resource management matters. Wasting tools has real costs.

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

**Designed** — Detailed game design and mechanics established. Implementation in progress per `.squad/decisions.md` and `design-directives.md`.

---

## Design Notes

### Why These Objects?

- **Matchbox with 3 matches:** Enough for multiple attempts plus margin for error. Three is the classic puzzle number. More than one allows for retries; not so many that matches feel infinite.
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
- **Consumable Tools:** Defined in `design-directives.md` (Consumable Tools subsection)
- **Object: Matchbox:** Full spec in `tool-objects.md`
