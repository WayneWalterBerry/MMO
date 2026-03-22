# Eat

> Consume an edible object.

## Synonyms
- `eat` — Eat something
- `consume` — Consume something (synonym)
- `devour` — Eat hungrily (synonym)

## Sensory Mode
- **Works in darkness?** ✅ Yes
- **Light requirement:** None

## Syntax
- `eat [object]` — Eat something
- `eat [object] from [container]` — Eat from a specific source
- `consume [object]` — Consume (synonym)

## Behavior
- **Edible check:** Object must have `edible = true`
- **Search order:** Hands first (interaction verb — you eat what you hold)
- **Consumption:** Item is consumed (removed from inventory)
- **State change:** Item removed from hands/inventory
- **Effect application:** Any `on_eat` effects are applied (may heal, poison, etc.)
- **Message:** "You eat X."

## Design Notes
- **Interaction verb:** Hands-first search — you eat what you're holding or can reach
- **Effect mechanics:** Edible items may have healing/harm effects
- **Container extraction:** Can eat from "get food from bag" style usage

## Related Verbs
- `drink` — Consume liquids
- `taste` — Taste before eating (may reveal poison)
- `pour` — Pour liquid

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["eat"]`, `handlers["consume"]`, `handlers["devour"]`
- **Effects:** Uses `on_eat` handler system
- **Ownership:** Bart (Architect) — state management; Smithers (UI) — output
