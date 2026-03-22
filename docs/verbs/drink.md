# Drink

> Drink from a container or consume a liquid.

## Synonyms
- `drink` — Drink something
- `sip` — Drink carefully (synonym)
- `quaff` — Drink heartily (synonym)

## Sensory Mode
- **Works in darkness?** ✅ Yes
- **Light requirement:** None

## Syntax
- `drink [object]` — Drink from/consume a liquid
- `drink from [object]` — Drink from a container
- `sip [object]` — Sip carefully
- `quaff [object]` — Quaff heartily

## Behavior
- **Liquid check:** Object must be drinkable (container with liquid, or `drinkable = true`)
- **Search order:** Hands first (interaction verb)
- **Consumption:** Liquid consumed; container may be emptied or destroyed
- **State change:** Item removed or state updated
- **Effect application:** Any `on_drink` effects applied (healing, poison, etc.)
- **Message:** "You drink X."

## Design Notes
- **Interaction verb:** Hands-first search — you drink what you're holding
- **Container handling:** May be drinkable in-place (cup) or consumed (potion)
- **Effect mechanics:** Drinking may heal, poison, or provide other effects

## Related Verbs
- `eat` — Consume solid food
- `pour` — Pour out liquid
- `taste` — Taste before drinking (may reveal poison)

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["drink"]`, `handlers["sip"]`, `handlers["quaff"]`
- **Effects:** Uses `on_drink` handler system
- **Ownership:** Bart (Architect) — state; Smithers (UI) — output
