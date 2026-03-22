# Walk

> Move at normal speed in a direction.

## Synonyms
- `walk` — Walk in a direction
- `walk [direction]` — Walk to a location
- `travel` — Synonym for walk (alias)

## Sensory Mode
- **Works in darkness?** ✅ Yes
- **Light requirement:** None

## Syntax
- `walk north` — Walk north
- `walk [direction]` — Walk in any compass direction
- `travel [direction]` — Travel (synonym for walk)

## Behavior
- **Speed:** Normal walking pace (narrative flavor vs. `run`)
- **Direction parsing:** Accepts cardinal and vertical directions
- **Delegation:** Typically delegates to `go` handler
- **Narrative:** May print different message than bare direction

## Design Notes
- **Flavor verb:** Walk is identical mechanically to `go`, but with different narrative tone
- **Alternative to shortcuts:** More verbose than bare `n/s/e/w`, same effect
- **Travel synonym:** `travel` is typically an alias for `walk`

## Related Verbs
- `go` — Primary movement verb
- `run` — Fast movement (same direction, different speed)
- `head` — Head in direction (similar to walk)
- **[direction](direction.md)** — Shorthand (n/s/e/w/u/d)

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["walk"]`
- **Delegation:** Typically wraps `go` handler
- **Ownership:** Bart (Architect)
