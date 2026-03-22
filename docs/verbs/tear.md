# Tear

> Tear fabric or materials apart.

## Synonyms
- `tear` — Tear something
- `rip` — Rip (synonym)

## Sensory Mode
- **Works in darkness?** ✅ Yes — can tear by touch
- **Light requirement:** None

## Syntax
- `tear [object]` — Tear something
- `rip [object]` — Rip something

## Behavior
- **Tearable check:** Object must have `tearable = true` or similar
- **Tool requirement:** Some tearables require a tool
- **Search order:** Hands first (interaction verb)
- **Mutation system:** Uses mutation system
- **State change:** Object transitions to "torn" state or is destroyed
- **Message:** Tear/rip message based on object

## Design Notes
- **Fabric focus:** Primarily for textiles, cloth, paper
- **Mutation-driven:** Uses same mutation system as break
- **Irreversible:** Can't "unsew" torn items (unless crafted)

## Related Verbs
- `break` — Break rigid objects (similar concept)
- `sew` — Sew fabric together (can repair torn items)

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["tear"]`, `handlers["rip"]`
- **Mutations:** Uses mutation system
- **Ownership:** Bart (Architect)
