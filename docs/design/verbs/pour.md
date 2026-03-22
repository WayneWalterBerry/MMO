# Pour

> Pour out a liquid from a container.

## Synonyms
- `pour` — Pour something
- `pour [liquid]` — Pour out liquid
- `spill` — Spill (similar effect)

## Sensory Mode
- **Works in darkness?** ✅ Yes
- **Light requirement:** None

## Syntax
- `pour [object]` — Pour out the liquid
- `pour [liquid] into [container]` — Pour into a specific target
- `spill [object]` — Spill (synonym)

## Behavior
- **Liquid check:** Object must be a container with liquid
- **Search order:** Hands first (interaction verb)
- **Effect:** Liquid is poured out (removed from container or destroyed)
- **Target:** May pour into another container or onto floor
- **State change:** Container emptied or liquid transferred
- **Message:** "You pour X."

## Design Notes
- **Interaction verb:** Hands-first search
- **Transfer mechanics:** Can pour from one container to another
- **Spillage:** Pouring can create spills or transfer effects

## Related Verbs
- `drink` — Consume liquid
- `eat` — Consume solid
- **[open](open.md)** — May need to open container first

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["pour"]`, `handlers["spill"]`
- **Ownership:** Bart (Architect)
