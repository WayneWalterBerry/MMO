# Decision: Fire Propagation Architecture

**Author:** Bart (Architecture Lead)
**Date:** 2025-07-18
**Issue:** #121

## Decision

Fire propagation is implemented as a standalone tick-based module (`src/engine/fire_propagation/init.lua`) that runs once per game tick in the post-command phase of the game loop.

## Key Choices

### Proximity Model (3 tiers)
- **SAME_SURFACE (0.8):** Items on the same furniture surface (e.g., two items on a nightstand's top). Highest spread chance — they're effectively touching.
- **SAME_PARENT (0.5):** Items on different surfaces of the same furniture (e.g., something on top vs. underneath). Medium spread — heat rises/radiates.
- **SAME_ROOM (0.2):** Items loose in the room or on different furniture. Low spread — radiant heat only.

### Spread Formula
`chance = proximity_factor × target_flammability × source_intensity`

All values derived from the material system. No per-object fire configuration needed.

### Rate Limiting
MAX_IGNITIONS_PER_TICK = 2. Fire cascades over multiple turns. Players always have at least one turn to react before the next wave of ignitions.

### Generic Destruction Countdown
Non-FSM objects get `_burn_ticks_remaining = 1` when ignited by propagation. They burn for one tick (giving the player a chance to extinguish) before being destroyed. FSM objects use their declared burn transitions.

### "Burning" vs "Lit"
Lit candles do NOT propagate fire. Only objects in a "burning" FSM state, with `state.is_burning = true`, or with the explicit `is_burning` flag spread fire. This prevents candles from being fire hazards.

## Affected Team Members

- **Flanders:** Object authors can add `{ from = "intact", to = "burning", verb = "burn" }` transitions for custom burn behavior. Generic destruction works automatically for simple objects.
- **Moe:** Room designers should be aware that placing many flammable objects on the same surface creates fire propagation chains.
- **Nelson:** 23 new tests with deterministic RNG. Use `ctx.fire_rng` to control roll outcomes.
- **Sideshow Bob:** Fire propagation opens new puzzle design space — chain reactions, timed escape scenarios, using fire as a tool.
