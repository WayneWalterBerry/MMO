# Enter

> Enter through an exit or into a location.

## Synonyms
- `enter` — Enter through something
- `enter [exit]` — Enter through a named exit
- `go through [exit]` — Alternative form

## Sensory Mode
- **Works in darkness?** ✅ Yes
- **Light requirement:** None

## Syntax
- `enter [exit]` — Enter through a door or exit
- `enter [location]` — Enter into a location
- `go through [exit]` — Alternative syntax

## Behavior
- **Exit lookup:** Resolves exit by name
- **Room transition:** Moves player through exit to destination room
- **State update:** `ctx.player.location` changed
- **Description:** May print entry message from exit definition
- **Failure:** "You can't enter that." if exit not found

## Design Notes
- **Named exits:** Provides alternative to "go north" — can "enter door" instead
- **Flavor:** More immersive than bare directions
- **Door/portal focus:** Typically used for named exits rather than cardinal directions

## Related Verbs
- `go` — Primary movement verb
- **[direction](direction.md)** — Cardinal directions (n/s/e/w)

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["enter"]`
- **Ownership:** Bart (Architect)
