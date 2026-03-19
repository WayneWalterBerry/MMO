# Puzzle 002: Poison Bottle

## Overview

A bottle of poison sits on the nightstand in the bedroom. In darkness, the player cannot read the skull-and-crossbones label. The puzzle teaches sensory interaction and the consequences of blindly tasting unknown substances. It's a trap puzzle: the player learns what NOT to do.

## Room

Bedroom (on nightstand)

## Required Objects

- Poison bottle (contains toxic liquid)
- Light source (candle or daylight, to read the label)
- Optional: nose (to smell the chemical scent)

## Solution

### Safe Path: Light First, Then Look

1. Complete Puzzle 001 (Light the Room) to illuminate the bedroom.
2. **LOOK at poison-bottle** — With light present, the player can now read the skull-and-crossbones label. The description reveals: "A glass bottle with a cork stopper. A skull and crossbones is painted on the label in faded red."
3. **Player learns:** This is poison. Do not drink it.

### Safe Path: Smell First

Without light, the player can safely interact with the bottle:

1. **SMELL poison-bottle** — The verb works in darkness. The response is: "You detect a sharp, acrid chemical smell. Warning bells go off in your mind. This is not something to taste."
2. **Player learns:** SMELL provides safe identification. The chemical scent is a warning.

### Safe Path: Feel First

1. **FEEL poison-bottle** — The verb works in darkness. The response is: "Glass bottle, sealed with a cork stopper. Heavy and smooth. You can't tell what's inside by touch alone."
2. **Player learns:** FEEL provides some information but not everything. Texture doesn't reveal content or danger.

## The Trap: Taste in Darkness

### If Player Types: TASTE poison-bottle

In darkness (before lighting the room):

1. **Result:** The player's fingers touch the liquid as they tip the bottle. They get a tiny taste.
2. **Message:** "You taste something vile, metallic, and wrong. Your tongue burns. The world goes dark."
3. **Consequence:** **Death.** The player dies and the game ends (or resets to a checkpoint if checkpoints are implemented).
4. **Learning moment:** TASTE is dangerous. Tasting unknown substances without light or safety checks is fatal. The player should use other senses first.

### After Lighting the Room

If the player is foolish enough to taste the poison after seeing the label:

1. The same result occurs: death.
2. **Learning moment:** Reading warnings is important. The label says poison; drinking it anyway has predictable consequences.

## Alternative Solutions

### No Alternative — This is Not a Puzzle to "Solve"

Unlike Puzzle 001 (Light the Room), this is not a puzzle with multiple solution paths. It's a **trap puzzle** designed to teach consequences. The "solution" is: don't touch it.

- If the player avoids the poison entirely: they escape unharmed.
- If the player investigates safely (SMELL, FEEL, LOOK with light): they learn what it is and avoid it.
- If the player tastes it without light: they die.

## What the Player Learns

1. **SMELL is safe investigation** — Unlike TASTE, SMELL provides information without risk in darkness.
2. **LOOK requires light** — In darkness, LOOK returns "You can't see anything." In light, LOOK reveals details like labels and warnings.
3. **TASTE is dangerous** — Without certainty about what you're tasting, TASTE can be fatal.
4. **Consequences are real** — The game world has permanent, player-ending consequences. Choices matter.
5. **Multiple senses exist** — FEEL, SMELL, LOOK, TASTE are all verbs. Each provides different information and carries different risks.
6. **Reading labels prevents mistakes** — Once the label is visible, the player has clear information. Ignoring it is willful disregard.

## Failure Consequences

### Tasting the Poison
- **Immediate:** Death. Game over (or load from checkpoint).
- **Narrative:** The player drank an unknown substance in the dark. It was poison. Natural consequences.
- **Learning moment:** The game is not forgiving of reckless actions. Safety checks matter.

### Multiple Deaths?
If the player somehow resets and attempts the poison again:
- The same result: death.
- **Design note:** This creates a harsh learning experience, but it's intentional. The game teaches through failure.

## Status

**Designed** — Detailed game design established. Implementation pending per `.squad/decisions.md`.

---

## Design Notes

### Why is This a Trap?

- **Early lesson:** Early in the game, the player learns that death can come from foolish choices, not just combat.
- **Sensory teaching:** The puzzle rewards using multiple senses (SMELL, FEEL, LOOK) before committing to dangerous actions (TASTE).
- **Consequence establishment:** The game world has stakes. Death is real. Players must be cautious.

### Why on the Nightstand?

- **Proximity to light puzzle:** The poison is near the candle and matchbox. The player encounters these objects during the first puzzle.
- **Temptation:** With a candle and matches nearby, the poison is near an easy investigation opportunity.
- **Narrative:** Perhaps the poison was poison all along, or perhaps it's a dangerous substance left behind. Either way, it's a hazard to avoid.

### Why Not Deadly Immediately?

The poison requires `TASTE` to kill. This gives the player multiple opportunities to investigate safely first:
- FEEL the bottle → discover it's a container
- SMELL the bottle → get a chemical warning
- LOOK at the bottle with light → read the label

Only the reckless choice (TASTE in darkness) is fatal. A curious but cautious player survives.

### Label Detail

The skull-and-crossbones is intentionally "faded red" — a clear universal warning that even a literacy-light player recognizes. There's no ambiguity here.

---

## Related Systems

- **Sensory Verbs:** FEEL, SMELL, LOOK, TASTE (core gameplay)
- **Light System:** Defined in `design-directives.md`
- **Poison Object:** Defined in game object files (not yet documented in tool-objects.md)
