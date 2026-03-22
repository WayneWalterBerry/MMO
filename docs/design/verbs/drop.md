# Drop

> Release an object from your inventory back into the current room.

## Synonyms
- `drop` — Drop something you're holding
- `drop it` — Drop the current item
- `dump` — Drop (informal synonym)

## Sensory Mode
- **Works in darkness?** ✅ Yes — tactile release
- **Primary sense:** Touch
- **No light requirement**

## Syntax
- `drop [object]` — Drop an item from your hands
- `drop [object] here` — Drop at current location (explicit)

## Behavior
- **Search order:** Hands first (interaction verb — you're dropping what you hold)
- **Removal:** Takes object from hand slots or inventory
- **Placement:** Object lands in current room
- **State update:** Object location changed from "player" to current room
- **Release confirmation:** "You drop X."

## Design Notes
- **Inverse of take:** Reverse of acquisition — releases object back to world
- **Search order:** Hands/bags first (you can only drop what you're carrying)
- **Interaction verb:** Uses hands-first search (opposite of acquisition verbs)
- **No weight/force mechanics:** Simple immediate release (no physics)

## Related Verbs
- `take` — Pick up (inverse)
- `put` — Place deliberate (alternative to drop)
- `inventory` — Check what you're carrying

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["drop"]`
- **Ownership:** Bart (Architect) — state mutation (hands → room)
