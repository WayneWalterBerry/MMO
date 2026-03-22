# Break

> Break something breakable into pieces or damage it.

## Synonyms
- `break` — Break something
- `shatter` — Break into pieces (synonym)
- `smash` — Break forcefully (synonym)

## Sensory Mode
- **Works in darkness?** ✅ Yes — can break by touch
- **Light requirement:** None

## Syntax
- `break [object]` — Break something
- `shatter [object]` — Shatter into pieces
- `smash [object]` — Smash forcefully

## Behavior
- **Breakable check:** Object must have `breakable = true` or similar
- **Tool requirement:** Some breakable objects require a tool/weapon
- **Search order:** Hands first (interaction verb)
- **Mutation system:** Uses mutation system to transform object
- **State change:** Object may transition to "broken" state or be destroyed
- **Message:** Descriptive break message based on object

## Design Notes
- **Mutation-driven:** Breaking uses object mutation system
- **Tool variants:** Different tools have different break messages
- **Irreversible:** Usually can't "unbreak" something
- **Alternative weapons:** Can use any object with destructive capability

## Related Verbs
- `tear` — Tear fabric apart (similar)
- `damage` — More general damage (not implemented)
- **Combat verbs:** `stab`, `cut`, `slash` for combat breaking

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["break"]`, `handlers["shatter"]`, `handlers["smash"]`
- **Mutations:** Uses `find_mutation()` and `perform_mutation()`
- **Ownership:** Bart (Architect)
