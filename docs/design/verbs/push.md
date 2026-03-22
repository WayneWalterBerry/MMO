# Push

> Push an object aside or move it out of the way.

## Synonyms
- `push` — Push something
- `shove` — Push forcefully (synonym)

## Sensory Mode
- **Works in darkness?** ✅ Yes — can push by touch
- **Light requirement:** None

## Syntax
- `push [object]` — Push an object
- `push [object] aside` — Push aside explicitly
- `shove [object]` — Shove (synonym)

## Behavior
- **Movable check:** Object must be movable (`movable = true`)
- **Spatial movement:** Uses spatial object movement system
- **Search order:** Hands first (interaction verb)
- **State change:** Object location updated on spatial grid
- **Message:** "You push X." or spatial description

## Design Notes
- **Spatial objects:** Handles furniture and other movable obstacles
- **Touch-based:** Can move objects by feel in darkness
- **Directional:** May need "aside/away/over" suffix stripping

## Related Verbs
- `pull` — Pull objects (opposite direction)
- `move` — Move objects (more general)
- `lift` — Lift and reveal

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["push"]`, `handlers["shove"]`
- **Spatial system:** Uses `move_spatial_object()` utility
- **Ownership:** Bart (Architect)
