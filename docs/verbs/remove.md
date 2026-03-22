# Remove

> Take off a worn item (clothing, armor, accessories).

## Synonyms
- `remove` — Remove a worn item
- `doff` — Remove formally (synonym)
- `take off` — Take off a worn item

## Sensory Mode
- **Works in darkness?** ✅ Yes — can undress by touch
- **Primary sense:** Touch
- **Light requirement:** Not required

## Syntax
- `remove [object]` — Remove a worn item
- `doff [object]` — Remove formally
- `take off [object]` — Remove informally

## Behavior
- **Worn check:** Object must be currently worn
- **Search order:** Worn inventory first (interaction verb)
- **Hand slot requirement:** Can only remove if you have a free hand
- **State change:** Item moves from "worn" to hand slot or bag
- **Message:** "You remove X."
- **Full hands:** "Your hands are full. Drop something first."

## Design Notes
- **Interaction verb:** Worn-first search — you remove what you're wearing
- **Hand requirement:** Unlike wearing, removing requires free hand space
- **Inverse of wear:** Exact opposite state transition
- **Equipment burden:** Removing armor/weight items may free up capacity

## Related Verbs
- `wear` — Put on an item (inverse)
- `inventory` — Check worn items
- `drop` — Drop the removed item

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["remove"]` and `handlers["doff"]`
- **Worn inventory:** Searches `ctx.player.worn` structure
- **Ownership:** Bart (Architect) — inventory state management
