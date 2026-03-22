# Pull

> Pull objects or detach composite parts. Also includes pushing and lifting mechanics.

## Synonyms
- `pull` — Pull something
- `yank` — Pull (synonym)
- `tug` — Pull (synonym)
- `extract` — Extract (synonym)
- `push` — Push an object aside or move it out of the way
- `shove` — Push forcefully (synonym)
- `lift` — Lift an object to pick it up or reveal what's underneath

## Sensory Mode
- **Works in darkness?** ✅ Yes — can pull/push/lift by touch
- **Light requirement:** None

## Syntax

### Pulling
- `pull [object]` — Pull something
- `pull out [drawer]` — Pull out a drawer
- `pull [part] from [container]` — Extract a part
- `yank [object]` — Pull (synonym)
- `extract [object]` — Extract (synonym)

### Pushing
- `push [object]` — Push an object
- `push [object] aside` — Push aside explicitly
- `shove [object]` — Shove (synonym)

### Lifting
- `lift [object]` — Lift an object
- `lift up [object]` — Lift explicitly

## Behavior

### Pulling
- **Detachable parts:** Checks for detachable parts on composite objects
- **Verb validation:** Part must support "pull" in `detach_verbs`
- **Movable objects:** Can move spatial objects aside
- **FSM fallback:** If not a part, tries FSM transitions
- **State change:** Part detaches or object moves
- **Message:** Descriptive message based on what's being pulled

### Pushing
- **Movable check:** Object must be movable (`movable = true`)
- **Spatial movement:** Uses spatial object movement system
- **Search order:** Hands first (interaction verb)
- **State change:** Object location updated on spatial grid
- **Message:** "You push X." or spatial description

### Lifting
- **Visibility:** Object must be findable
- **Movable objects:** If object is movable (furniture, etc.), move it aside
- **Portable objects:** If portable, pick up (like take)
- **Weight check:** If heavy, refuse ("too heavy to lift")
- **Message:** Appropriate message based on action taken
- **Reveal mechanic:** Lifting furniture can reveal what's underneath

## Design Notes
- **Composite object support:** Primary verb for detaching parts (drawers, corks, etc.)
- **Spatial objects:** Also handles moving furniture/obstacles
- **Multi-purpose:** Handles both parts and objects for all three verbs
- **Touch-based:** Can pull/push/lift by feel in darkness
- **Weight consideration:** Very heavy objects won't lift

### Push Specifics
- **Spatial objects:** Handles furniture and other movable obstacles
- **Touch-based:** Can move objects by feel in darkness
- **Directional:** May need "aside/away/over" suffix stripping

### Lift Specifics
- **Multi-purpose:** Handles both furniture movement and item pickup
- **Reveal mechanic:** Lifting furniture can reveal what's underneath
- **Touch-based:** Can lift by feel in darkness

## Related Verbs
- `move` — Move objects (more general)
- `take` — Pick up (if portable)
- `drop` — Release an object

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["pull"]`, `handlers["yank"]`, `handlers["tug"]`, `handlers["extract"]`, `handlers["push"]`, `handlers["shove"]`, `handlers["lift"]`
- **Part system:** Uses `find_part()` and `detach_part()` for pull
- **Spatial system:** Uses `move_spatial_object()` utility for push and lift
- **Ownership:** Bart (Architect) — object state
