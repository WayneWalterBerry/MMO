# Climb

> Climb stairs, ladders, or other obstacles.

## Synonyms
- `climb` — Climb something
- `climb up` — Climb upward
- `climb down` — Climb downward

## Sensory Mode
- **Works in darkness?** ⚠️ Risky — can climb by touch but dangerous
- **Light requirement:** Not strictly required, but recommended

## Syntax
- `climb up` — Climb upstairs
- `climb down` — Climb downstairs
- `climb [object]` — Climb a specific obstacle
- `climb up [object]` — Climb up something
- `climb down [object]` — Climb down something

## Behavior
- **Obstacle checking:** Object must be climbable (`climbable = true`)
- **Direction support:** "up"/"down" directions for stairs and ladders
- **Destination:** Moves player to above/below room
- **State update:** `ctx.player.location` changed via traverse_effects
- **Failure:** "You can't climb that." if not climbable

## Design Notes
- **Specialized movement:** Different from simple `go up/down` — implies effort and climbing mechanics
- **Obstacle type:** Can climb stairs, ladders, ropes, cliffs, etc.
- **Touch navigation:** Could navigate by touch in darkness (dangerous)

## Related Verbs
- `ascend` — Climb up (synonym)
- `descend` — Climb down (synonym)
- `go up/down` — Simple vertical movement
- **[direction](direction.md)** — Basic up/down

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["climb"]`
- **Movement:** Uses traverse_effects for room transitions
- **Ownership:** Bart (Architect)
