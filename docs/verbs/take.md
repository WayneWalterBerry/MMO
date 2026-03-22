# Take

> Acquire an object and pick it up into inventory (hands or bags).

## Synonyms
- `take` — Pick something up
- `get` — Get something (same handler)
- `grab` — Grab something (same handler)
- `pick up` — Pick up an object (normalized by preprocessor)
- `pick` — Pick something up (with fallback to lockpicking)

## Sensory Mode
- **Works in darkness?** ✅ Yes — can take by touch alone
- **Primary sense:** Touch (tactile acquisition)
- **Vision requirement:** Not strictly required; blind acquisition works

## Syntax
- `take [object]` — Pick up an object
- `get [object]` — Same as take
- `grab [object]` — Same as take
- `pick [object]` — Same as take (or `pick lock` for lockpicking)
- `get [object] from [container]` — Extract from a container

## Behavior
- **Basic acquisition:** Moves object from location to player's hand/inventory
- **Hand requirements:**
  - One-handed items: Require one free hand
  - Two-handed items: Require both hands free
  - Full hands: "Your hands are full. Drop something first."
- **Search order:** Room/surfaces first (acquisition verb — reaches for world objects)
- **Weight/portability:** Object must be portable (not fixed, not too heavy)
- **Container extraction:** "get X from Y" works for bags and containers
- **Instance tracking:** Each instance of an object gets unique instance_id

## Design Notes
- **Acquisition priority:** Searches room/surfaces FIRST, then falls back to hands/bags
- **Opposite of interaction verbs:** `use`, `drink`, `light` search hands-first (player likely holds the tool)
- **Two-handed carry:** Items can require both hands (e.g., heavy weapons, furniture)
- **Portability check:** Object must have `portable = true` or similar flag
- **Inventory constraints:** Limited by hand slots (2) and bag capacity

## Related Verbs
- `drop` — Release an object (inverse)
- `put` — Place an object in/on (more deliberate placement)
- `inventory` — Check what you're carrying
- `wear` — Put on equipment (alternative to hands)

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["take"]`
- **Aliases:** `get`, `grab`, `pick` all delegate to take handler
- **Container extraction:** "get X from Y" parsed and handled specially
- **Hand management:** `first_empty_hand(ctx)`, `count_hands_used(ctx)`
- **Search functions:** `find_in_inventory()`, `find_visible()` with acquisition-first order
- **Ownership:** Bart (Architect) — game state mutations, inventory management, hand slots
