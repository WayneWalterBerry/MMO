# Close

> Close a container, door, or other closeable object.

## Synonyms
- `close` — Close an object
- `shut` — Synonym for close

## Sensory Mode
- **Works in darkness?** ✅ Yes — can close by touch
- **Primary sense:** Touch
- **Light requirement:** Not required

## Syntax
- `close [object]` — Close something
- `shut [object]` — Close something (synonym)

## Behavior
- **Requires reachability:** Object must be findable and accessible
- **FSM transition:** Inverse of open — transitions from "open" to "closed" state
- **State change:** Closes container and updates FSM state
- **Message:** Prints transition message or generic "You close X."
- **Search order:** Hands first (interaction verb)

## Design Notes
- **Interaction verb:** Hands-first search — you typically close what's in front of you or in your hands
- **FSM-driven:** Behavior defined via object's state machine
- **Reverse of open:** Exactly opposite transition

## Related Verbs
- `open` — Open an object (inverse transition)
- `look in` — Observe contents (requires open state)

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["close"]`
- **FSM:** `src/engine/fsm.lua` handles state transitions
- **Ownership:** Bart (Architect) — state mutation
