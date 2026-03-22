# Move

> Move an object from its current location.

## Synonyms
- `move` — Move something
- `shift` — Move (synonym)
- `slide` — Move smoothly (synonym)

## Sensory Mode
- **Works in darkness?** ✅ Yes — can move by touch
- **Light requirement:** None

## Syntax
- `move [object]` — Move something
- `move [object] aside` — Move aside
- `shift [object]` — Shift (synonym)
- `slide [object]` — Slide (synonym)

## Behavior
- **Movable check:** Object must be movable
- **Spatial movement:** Uses spatial object movement system
- **Search order:** Hands first (interaction verb)
- **State change:** Object repositioned
- **Message:** "You move X."

## Design Notes
- **General movement:** More generic than push/pull
- **Spatial objects:** Works with furniture and obstacles
- **Touch navigation:** Can move obstacles by feel

## Related Verbs
- `push` — Push in specific direction
- `pull` — Pull in specific direction
- `lift` — Lift and reveal

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["move"]`, `handlers["shift"]`, `handlers["slide"]`
- **Spatial system:** Uses `move_spatial_object()` utility
- **Ownership:** Bart (Architect)
