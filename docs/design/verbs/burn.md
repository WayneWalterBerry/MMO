# Burn

> Set something on fire or make something burn.

## Synonyms
- `burn` — Burn something

## Sensory Mode
- **Works in darkness?** ⚠️ — Can start fire but may need light to see
- **Light requirement:** No initial requirement

## Syntax
- `burn [object]` — Burn something
- `burn [object] with [source]` — Burn using a specific source

## Behavior
- **Flammable check:** Object must be flammable
- **Source requirement:** Need a fire source
- **Search order:** Hands first (interaction verb)
- **State change:** Object transitions to "burning" or destroyed
- **Effect:** May consume the object or transition to burnt state
- **Message:** "You burn X."

## Design Notes
- **Fire mechanics:** Similar to `light` but may consume object
- **Mutation system:** May trigger object mutations (burning cloth → ash)
- **Danger:** Burning can destroy valuable items
- **Alternative to light:** Some objects can only be burned, not lit

## Related Verbs
- `light` — Light something (similar but non-destructive)
- `extinguish` — Put out a fire

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["burn"]`
- **Mutations:** May use mutation system for object transformation
- **Ownership:** Bart (Architect)
