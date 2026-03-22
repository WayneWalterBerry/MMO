# Extinguish

> Put out a flame or fire.

## Synonyms
- `extinguish` — Put out a flame
- `snuff` — Snuff out (synonym)

## Sensory Mode
- **Works in darkness?** ✅ Yes
- **Light requirement:** No (can extinguish even after light goes out)

## Syntax
- `extinguish [object]` — Put out a flame
- `snuff [object]` — Snuff out (synonym)
- `snuff out [object]` — Snuff out explicitly

## Behavior
- **Lit check:** Object must be in "lit" state
- **Search order:** Hands first (interaction verb)
- **State change:** Transitions object from "lit" to unlit state
- **Light loss:** Room may become darker if main light source extinguished
- **Message:** "You extinguish X."

## Design Notes
- **Inverse of light:** Exactly opposite state transition
- **FSM-driven:** Uses state machine transitions
- **Darkness:** Extinguishing only light source makes room dark

## Related Verbs
- `light` — Light something (inverse)
- `burn` — Related fire verb

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["extinguish"]`, `handlers["snuff"]`
- **FSM:** Uses state machine for lit/unlit
- **Ownership:** Bart (Architect)
