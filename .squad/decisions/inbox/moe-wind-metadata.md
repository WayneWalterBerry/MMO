# Decision: on_traverse Wind Effect Metadata for Puzzle 015

**Author:** Moe (Room/Level Builder)
**Date:** 2026-07-22
**Status:** Proposed
**Affects:** deep-cellar.lua, hallway.lua, engine (on_traverse handler — Bart)

## Context

Puzzle 015 (Draft Extinguish) requires a wind effect that triggers when the player traverses the stairway between the deep cellar and the hallway. The stairway acts as a natural chimney — 9°C below, 18°C above — creating intermittent gusts strong enough to extinguish an unprotected candle but not a wind-resistant lantern.

## Decision

Added `on_traverse.wind_effect` metadata to both ends of the `deep-cellar-hallway-stairway` passage:

- **deep-cellar.lua `up` exit:** Warm downdraft from above extinguishes candle.
- **hallway.lua `down` exit:** Chill updraft from below extinguishes candle.
- **deep-cellar.lua description:** Added foreshadowing line about the draught from the stairway.

## Metadata Format

```lua
on_traverse = {
    wind_effect = {
        strength = "gust",
        extinguishes = { "candle" },
        spares = { wind_resistant = true },
        message_extinguish = "...",
        message_spared = "...",
        message_no_light = nil,
    },
}
```

This follows the format specified in `docs/levels/01/puzzles/puzzle-015-draft-extinguish.md`.

## Notes for Bart

This is the first `on_traverse` environmental effect in the codebase. The engine needs a handler that:
1. Fires when a player moves through an exit with `on_traverse`
2. Checks carried objects against the effect's filters (`extinguishes` list, `spares` property)
3. Triggers the appropriate FSM transition (e.g., candle `lit → extinguished`)
4. Displays the correct message based on outcome

The pattern should be generic — future uses include water crossings, narrow passages, and hot rooms.

## Topology Note

The task referenced "storage cellar" but the actual stairway connects **deep-cellar ↔ hallway** (passage_id: `deep-cellar-hallway-stairway`). The storage cellar connects to the deep cellar via an iron door (north/south), not a stairway.
