# Puzzle Designer Guide — Engine Event Handlers

> **Audience:** Bob (Puzzle Designer), CBG (Design Lead), anyone designing puzzles.

## What Are Event Handlers?

Event handlers are **pre-built engine mechanics** you can wire into your room and object metadata. You don't write code — you add a block of metadata, and the engine does the rest.

Think of them as tools in your toolbox. Each one does something specific (blow out a flame, lock a door, trigger a sound) and you choose when it fires by putting it in the right place in your metadata.

## How to Use Them

1. **Browse this folder** — each `.md` file (other than this one and README) documents one handler
2. **Pick the mechanic** you need for your puzzle
3. **Add the metadata block** to your room or object file in the format shown in the handler's doc
4. **Test it** — run the game and verify the effect fires when expected

## Currently Available

| Handler | What It Does | Where It Fires | Example Puzzle |
|---------|-------------|----------------|----------------|
| [wind_effect](./wind_effect.md) | Extinguishes lit items carried by the player | Exit traversal (`on_traverse`) | Puzzle 015: stairway draft blows out candle |

## Requesting New Handlers

If your puzzle needs a mechanic that doesn't exist:

1. **Describe what you need** — what triggers it, what it affects, what the player experiences
2. **File a request** — write it up in your puzzle design doc with a section called "Required Engine Mechanics"
3. **Engineering builds it** — Bart or Smithers implements the handler and adds a doc here
4. **You wire it in** — once the doc exists, you can use it in any room or object

## Key Concepts

### Event Handlers vs FSM
- **FSM** = state transitions on individual objects (candle: unlit → lit → spent). You define these in object metadata. Data-driven.
- **Event Handlers** = engine mechanics that fire on game events (wind blows, player enters room, item picked up). Engine-built, metadata-configured.
- **They work together:** a wind_effect handler *triggers* an FSM transition (lit → extinguished). The handler is the cause; the FSM transition is the effect.

### The `on_traverse` Pattern
The first handler type fires on **exit traversal** — when the player moves through a door, stairway, or passage. Add an `on_traverse` block to any exit:

```lua
exits = {
  up = {
    target = "hallway",
    on_traverse = {
      type = "wind_effect",        -- which handler to invoke
      description = "A cold draft rushes up the stairway...",
      extinguishes = { "candle" }  -- handler-specific parameters
    }
  }
}
```

Future handler types may fire on different triggers: entering a room, picking up an item, examining something, or after N turns pass.

### Wind Resistance
Objects can declare `wind_resistant = true` to survive wind effects. Use this for puzzle design — the player must figure out which light source survives the draft.

## Tips for Good Puzzle Design with Handlers

- **Foreshadow the mechanic** — add a description hint before the player encounters it ("a faint breeze from the stairway")
- **Provide an alternative** — if wind kills the candle, make sure the lantern is findable
- **Layer mechanics** — combine handlers with FSM for multi-step puzzles
- **Test both paths** — what happens if the player doesn't have the affected item?
