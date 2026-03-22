# Unlock

> Unlock a locked container or door.

## Synonyms
- `unlock` — Unlock something

## Sensory Mode
- **Works in darkness?** ✅ Yes — can unlock by touch
- **Light requirement:** None

## Syntax
- `unlock [object]` — Unlock a locked container/door
- `unlock [object] with [key]` — Unlock using specific key

## Behavior
- **Lock check:** Object must be locked
- **Key requirement:** Must have appropriate key (if locked)
- **Search order:** Hands first (interaction verb)
- **State change:** Object transitions from "locked" to "unlocked" state via FSM
- **Message:** "You unlock X."

## Design Notes
- **FSM-driven:** Uses state machine transitions
- **Key matching:** Keys matched by ID (must have correct key object)
- **Container access:** Unlocking allows opening
- **Puzzle mechanic:** Finding keys is common puzzle element

## Related Verbs
- `open` — Open a container (after unlocking)
- `close` — Close a container
- `lock` — Lock (not implemented yet)

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["unlock"]`
- **FSM:** Uses state machine transitions
- **Ownership:** Bart (Architect) — state mutations
