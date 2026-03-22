# Lift

> Lift an object to pick it up or reveal what's underneath.

## Synonyms
- `lift` — Lift something

## Sensory Mode
- **Works in darkness?** ✅ Yes — can lift by touch
- **Light requirement:** None

## Syntax
- `lift [object]` — Lift an object
- `lift up [object]` — Lift explicitly

## Behavior
- **Visibility:** Object must be findable
- **Movable objects:** If object is movable (furniture, etc.), move it aside
- **Portable objects:** If portable, pick up (like take)
- **Weight check:** If heavy, refuse ("too heavy to lift")
- **Message:** Appropriate message based on action taken

## Design Notes
- **Multi-purpose:** Handles both furniture movement and item pickup
- **Reveal mechanic:** Lifting furniture can reveal what's underneath
- **Touch-based:** Can lift by feel in darkness
- **Weight consideration:** Very heavy objects won't lift

## Related Verbs
- `take` — Pick up (if portable)
- `push`/`pull` — Move objects (if movable)

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["lift"]`
- **Spatial system:** Uses `move_spatial_object()` for furniture
- **Ownership:** Bart (Architect)
