# Pull

> Pull objects or detach composite parts.

## Synonyms
- `pull` — Pull something
- `yank` — Pull (synonym)
- `tug` — Pull (synonym)
- `extract` — Extract (synonym)

## Sensory Mode
- **Works in darkness?** ✅ Yes — can pull by touch
- **Light requirement:** None

## Syntax
- `pull [object]` — Pull something
- `pull out [drawer]` — Pull out a drawer
- `pull [part] from [container]` — Extract a part
- `yank [object]` — Pull (synonym)
- `extract [object]` — Extract (synonym)

## Behavior
- **Detachable parts:** Checks for detachable parts on composite objects
- **Verb validation:** Part must support "pull" in `detach_verbs`
- **Movable objects:** Can move spatial objects aside
- **FSM fallback:** If not a part, tries FSM transitions
- **State change:** Part detaches or object moves
- **Message:** Descriptive message based on what's being pulled

## Design Notes
- **Composite object support:** Primary verb for detaching parts (drawers, corks, etc.)
- **Spatial objects:** Also handles moving furniture/obstacles
- **Multi-purpose:** Handles both parts and objects
- **Touch-based:** Can pull by feel in darkness

## Related Verbs
- `push` — Push objects (opposite direction)
- `move` — Move objects generally
- `lift` — Lift and reveal (similar mechanic)

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["pull"]`, `handlers["yank"]`, `handlers["tug"]`, `handlers["extract"]`
- **Part system:** Uses `find_part()` and `detach_part()`
- **Ownership:** Bart (Architect) — object state
