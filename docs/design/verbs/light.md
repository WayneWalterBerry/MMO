# Light

> Light a fire or candle — requires a fire source (lighter, match, flint).

## Synonyms
- `light` — Light something
- `ignite` — Light something (synonym)
- `relight` — Relight an extinguished flame

## Sensory Mode
- **Works in darkness?** ⚠️ Risky — can light source but may need light to see
- **Light requirement:** No initial requirement, but useful to see result

## Syntax
- `light [object]` — Light something (torch, candle, etc.)
- `light [object] with [source]` — Light using a specific source
- `strike match` — Strike a match (special phrase)
- `ignite [object]` — Ignite (synonym)

## Behavior
- **Flammable check:** Object must be flammable (`flammable = true` or similar)
- **Source requirement:** Need a fire source (lighter, match, flint, etc.)
- **Search order:** Hands first (interaction verb — you light what you hold)
- **State change:** Object transitions to "lit" state via FSM
- **Light emission:** Lit object may illuminate room
- **Message:** "You light X."

## Design Notes
- **Tool requirement:** Must have appropriate fire source
- **FSM state:** Lighting transitions object state machine to "lit"
- **Illumination:** Lit objects may change visibility/light level in room
- **Self-lighting:** Match/lighter may need to be lit first

## Related Verbs
- `extinguish` — Put out a flame (inverse)
- `burn` — Set something on fire (related)
- `strike` — Strike a match (special case)

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["light"]`, `handlers["ignite"]`, `handlers["relight"]`
- **FSM:** Uses state machine for lit/unlit transitions
- **Ownership:** Bart (Architect) — state mutations; Smithers (UI) — light effects
