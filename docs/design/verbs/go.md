# Go

> Move in a direction using compass directions or named exits.

## Synonyms
- `go` — Go in a direction
- `go [direction]` — Go north/south/east/west/up/down/etc.
- `go through [exit]` — Go through a named exit
- Used as dispatcher for directional movement

## Sensory Mode
- **Works in darkness?** ✅ Yes — can navigate by memory/touch
- **Light requirement:** None (though disorientation possible in complete darkness)

## Syntax
- `go north` — Move north (or: `go n`)
- `go south/east/west` — Directional movement
- `go up/down` — Vertical movement
- `go through [door/exit]` — Go through a named exit
- `go [direction]` — Any compass direction

## Behavior
- **Direction parsing:** Normalized from "north" → "n", "south" → "s", etc.
- **Room transition:** Player moves from current room to adjacent room
- **Exit checking:** Room must have exit in that direction
- **State change:** `ctx.player.location` updated to new room
- **Message:** "You go [direction]." or descriptive room entry message
- **Failure:** "You can't go that way." if no exit

## Design Notes
- **Movement dispatcher:** `go` is the primary movement verb; directional commands may delegate to `go`
- **Named exits:** Can also use exit object names (e.g., "go through door")
- **Darkness tolerance:** Player can navigate in darkness (relies on memory)

## Related Verbs
- `north/south/east/west` — Directional shortcuts (n/s/e/w)
- `up/down` — Vertical movement shortcuts (u/d)
- `walk/run/head` — Alternative movement verbs
- `climb` — Climb obstacles
- `enter` — Enter through an exit

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["go"]`
- **Movement logic:** `src/engine/traverse_effects.lua` handles room transitions
- **Ownership:** Bart (Architect) — game state mutation, room transitions
