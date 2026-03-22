# Put

> Place an object in/on a container or surface with deliberate positioning.

## Synonyms
- `put` — Put something in or on something else
- `place` — Place an object (synonym)

## Sensory Mode
- **Works in darkness?** ✅ Yes — can place by touch
- **Primary sense:** Touch
- **Light requirement:** Not required

## Syntax
- `put [object] in [container]` — Put something inside a container
- `put [object] on [surface]` — Put something on top of a surface
- `put [object] under [object]` — Hide under something
- `place [object] in [container]` — Same as put (synonym)

## Behavior
- **Search order:** Hands first (interaction verb — you place what you're holding)
- **Container check:** Target must be a container or have surface
- **State requirements:** Some containers must be opened before putting items in
- **Spatial positioning:** Different from drop — intentional placement with specificity
- **Message:** "You put X in Y."

## Design Notes
- **Intentional placement:** Unlike drop (releases object), put is deliberate positioning
- **Interaction verb:** Hands-first search — you put what you're holding
- **Container interaction:** Often follows `open`
- **Surface support:** Objects must be stackable/placeable on the target

## Related Verbs
- `drop` — Release without targeting (simpler)
- `take` — Acquire from container (inverse)
- `open` — Open container before putting things in
- `place` — Synonym for put

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["put"]`
- **Ownership:** Bart (Architect) — containment logic, state management
