# Direction

> Shorthand directional commands for cardinal and vertical movement.

## Synonyms (Cardinal Directions)
- `north` / `n` — Move north
- `south` / `s` — Move south
- `east` / `e` — Move east
- `west` / `w` — Move west

## Synonyms (Vertical Directions)
- `up` / `u` — Move up (stairs, levels)
- `down` / `d` — Move down (stairs, levels)

## Sensory Mode
- **Works in darkness?** ✅ Yes
- **Light requirement:** None

## Syntax
- `north` — Move north (equivalent to `go north`)
- `n` — Shorthand for north
- `south`, `s` — Move south
- `east`, `e` — Move east
- `west`, `w` — Move west
- `up`, `u` — Move up
- `down`, `d` — Move down

## Behavior
- **Direct dispatch:** Each direction is a handler that delegates to `go`
- **Room transition:** Moves player to adjacent room if exit exists
- **Failure:** "You can't go that way." if no exit in direction
- **State update:** `ctx.player.location` changed

## Design Notes
- **Keyboard efficiency:** Single-letter shortcuts (n/s/e/w/u/d) for fast navigation
- **Aliases:** All are aliases/wrappers around `go` handler
- **No arguments:** Pure directional shorthand; can't combine with other verbs

## Related Verbs
- `go` — Primary movement verb (e.g., `go north`)
- `walk/run/head` — Alternative movement verbs (slower, narrative flavor)
- `climb` — Climb obstacles
- `enter` — Enter through a named exit

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["north"]`, `handlers["s"]`, etc.
- **All handlers:** Delegate to `handlers["go"]` with direction argument
- **Ownership:** Bart (Architect) — game state mutation
