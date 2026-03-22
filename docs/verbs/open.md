# Open

> Open a container, door, or other openable object.

## Synonyms
- `open` — Open a container or door

## Sensory Mode
- **Works in darkness?** ✅ Yes — can open by touch
- **Primary sense:** Touch
- **Light requirement:** Not strictly required (depends on object state)

## Syntax
- `open [object]` — Open something
- `open [container] with [key]` — Open using a specific key

## Behavior
- **Requires visibility:** Object must be reachable/findable
- **FSM transition:** Uses object's state machine if defined (states, transitions)
- **Locked check:** Some containers are locked and require unlocking first
- **State change:** Transitions container from "closed" to "open" state
- **Message:** Prints transition message or generic response
- **Search order:** Hands first (interaction verb — you interact with things you hold or see)

## Design Notes
- **Interaction verb:** Hands-first search order — likely to be holding or near the container
- **FSM-driven:** Container behavior defined via state machine (open.on_open, close.on_close)
- **Lock mechanics:** Some containers locked; see `unlock` verb
- **Door vs. Container:** Same verb handles both game objects and exits

## Related Verbs
- `close` — Close an object (inverse FSM transition)
- `unlock` — Unlock a locked container
- `put` — Place something in an opened container
- `look in` — Observe contents after opening

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["open"]`
- **FSM:** `src/engine/fsm.lua` handles state transitions
- **Ownership:** Bart (Architect) — FSM state mutations, containment logic
