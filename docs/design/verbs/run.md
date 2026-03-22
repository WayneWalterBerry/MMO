# Run

> Move quickly in a direction.

## Synonyms
- `run` — Run in a direction
- `run [direction]` — Run quickly

## Sensory Mode
- **Works in darkness?** ✅ Yes
- **Light requirement:** None

## Syntax
- `run north` — Run north
- `run [direction]` — Run in any compass direction

## Behavior
- **Speed:** Faster than walking (narrative flavor vs. `walk`)
- **Direction parsing:** Accepts cardinal and vertical directions
- **Delegation:** Typically delegates to `go` handler
- **Narrative:** May print "You run" instead of "You go"
- **No stamina mechanics:** (Currently simple, no fatigue tracking)

## Design Notes
- **Flavor verb:** Run is mechanically identical to `go`/`walk`, purely narrative
- **Faster narrative tone:** Suggests urgency or haste
- **No physical mechanics:** Currently no speed-based game effects

## Related Verbs
- `go` — Primary movement verb
- `walk` — Normal speed movement
- `head` — Head in direction
- **[direction](direction.md)** — Shorthand (n/s/e/w/u/d)

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["run"]`
- **Delegation:** Typically wraps `go` handler
- **Ownership:** Bart (Architect)
