# Apply

> Apply a healing item to an injury.

## Synonyms
- `apply` — Apply a healing item

## Sensory Mode
- **Works in darkness?** ✅ Yes — can apply bandage by touch
- **Light requirement:** None

## Syntax
- `apply [item]` — Apply healing item to active injury
- `apply [item] to [injury]` — Apply to specific injury

## Behavior
- **Injury requirement:** Player must have active injuries
- **Item search:** Searches hands first (interaction verb)
- **Dual binding:** Bandage items dual-bind to both player and injury
- **Injury resolution:** If multiple injuries, targets most severe or specified
- **State change:** Injury marked as treated, bandage marked as applied
- **Message:** Transition message from bandage (or generic)

## Design Notes
- **Dual binding system:** Bandages bind to both player.injuries and object.applied_to
- **Multiple injuries:** Handles cases with multiple wounds
- **Interaction verb:** Hands-first search
- **Healing alternatives:** Can also use on_drink or on_use effects for potion healing
- **FSM integration:** Bandage transitions from "unapplied" to "applied" state

## Related Verbs
- `health` — Check injuries
- `eat`/`drink` — Consume healing items (alternative healing)

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["apply"]`
- **Injury module:** Uses `engine.injuries` module
- **Ownership:** Bart (Architect) — injury state management
