# wind_effect — Environmental Wind

## What It Does

When a player moves through an exit with this handler, a **draft or wind blows through the passage**. Any lit items in the player's inventory that appear in the handler's `extinguishes` list get blown out (transition to `extinguished` FSM state). Items with the `wind_resistant = true` property are **immune** to this effect.

## When It Fires

**On exit traversal** — specifically, **before** the player moves to the new room. This allows the handler to modify the player's inventory state before the destination room renders.

## Metadata Format

Add this structure to an exit's `on_traverse` field:

```lua
exits = {
  up = {
    target = "hallway",
    on_traverse = {
      type = "wind_effect",
      description = "A cold draft rushes up the stairway...",
      extinguishes = { "candle", "torch" }
    }
  }
}
```

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `type` | string | Yes | Must be "wind_effect" |
| `description` | string | Yes | Message printed to the player when the effect fires. Use vivid, environmental language. |
| `extinguishes` | list of strings | Yes | Keywords (object identifiers) to check against the player's inventory. Only objects with matching keywords are susceptible. |

## Object Requirements

Target objects (those listed in `extinguishes`) must have:

1. **A lit FSM state** — The handler checks if the object is currently in a "lit" state before extinguishing it. Objects without a "lit" state are skipped.
2. **Matching keyword** — The object's keyword must appear in the `extinguishes` list.
3. **Optional: `wind_resistant = true`** — If present, this object is immune to the wind effect and will not be extinguished.

### Example Object Definition

```lua
{
  id = "candle",
  name = "wax candle",
  keywords = { "candle", "wax" },
  properties = {
    wind_resistant = false  -- (optional; false is default)
  },
  fsm = {
    states = { "lit", "extinguished" },
    initial = "extinguished",
    transitions = {
      { from = "extinguished", to = "lit", on = "light" },
      { from = "lit", to = "extinguished", on = "extinguish" }
    }
  }
}
```

## Example Puzzle: Puzzle 015 — The Deep Cellar Stairway

**Premise:** The player descends a narrow stone staircase into a cellar. A cold draft flows upward through the passage.

**Setup:**
- Exit up from cellar to stairway has a `wind_effect` handler
- Player starts with a lit candle and an oil lantern with a metal cage (both lit)

**Behavior:**
```lua
on_traverse = {
  type = "wind_effect",
  description = "A sudden draft roars up from the depths below, " ..
                "chilling you to the bone. You feel a sharp *poof* " ..
                "as something snuffs out.",
  extinguishes = { "candle" }
}
```

The oil lantern survives because:
- It has `wind_resistant = true` (metal cage protects the flame)
- It is NOT in the `extinguishes` list

The candle is extinguished because:
- It matches a keyword in `extinguishes`
- It is currently in the "lit" state
- It has no `wind_resistant` protection

## Puzzle Design Tips

Use `wind_effect` when:
- **Environmental forces affect carried items.** Wind, rain, water crossings, open flames in dangerous areas.
- **Progression is gated by item survival.** Player must choose which lit item to carry, or must find a wind-resistant container.
- **Sensory hints matter.** The vivid `description` text primes the player to anticipate consequences.

### Example Scenarios

- **River crossing:** Swift water extinguishes torches; oil lanterns (with sealed cages) survive.
- **Mountain pass:** Icy wind blows out candles but wind-resistant lanterns endure.
- **Crypt entrance:** Stale air pocket extinguishes small flames but not enclosed burners.

## See Also

- [FSM (Finite State Machines)](../../objects/state-machines.md) — Object state transitions
- [Object Metadata Reference](../../objects/metadata.md) — Full object structure
- [Puzzle Design Guide](../../design/puzzles/) — Multi-step puzzle patterns

---

**For Bob:** Use this handler when environmental forces are part of your puzzle mechanic. Combine it with prerequisite chains to create puzzles where the player must find/craft wind-resistant items to proceed.
