# Touch

> Direct tactile interaction with an object.

## Synonyms
- `touch` — Touch an object

## Sensory Mode
- **Works in darkness?** ✅ Yes — pure tactile
- **Light requirement:** None

## Syntax
- `touch [object]` — Touch something

## Behavior
- **Object interaction:** Simple tactile contact
- **Information:** May provide tactile description
- **State check:** Checks object state/condition by touch
- **Search order:** Hands first (interaction verb)

## Design Notes
- **Basic interaction:** Less specific than examine or feel
- **Tactile discovery:** Can discover objects by touching

## Related Verbs
- `feel` — Feeling (similar sense)
- `examine` — Closer inspection
- `look` — Visual inspection

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["touch"]`
