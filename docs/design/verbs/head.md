# Head

> Head in a direction (move with purpose).

## Synonyms
- `head` — Head in a direction
- `head [direction]` — Move in direction

## Sensory Mode
- **Works in darkness?** ✅ Yes
- **Light requirement:** None

## Syntax
- `head north` — Head north
- `head [direction]` — Head in any compass direction

## Behavior
- **Movement:** Similar to `go`/`walk`/`run`, different narrative tone
- **Direction parsing:** Accepts cardinal and vertical directions
- **Purpose:** Implies intentional, directed movement
- **Delegation:** Typically wraps `go` handler

## Design Notes
- **Narrative flavor:** "You head north" suggests purposeful movement
- **Alternative verbs:** One of several movement narrative options

## Related Verbs
- `go` — Primary movement verb
- `walk` — Normal speed
- `run` — Fast speed
- **[direction](direction.md)** — Shorthand

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["head"]`
- **Ownership:** Bart (Architect)
