# Strike

> Strike a match or strike something against a surface.

## Synonyms
- `strike` — Strike a match
- `strike match on [surface]` — Strike match on a surface

## Sensory Mode
- **Works in darkness?** ⚠️ — Can strike match to create light
- **Light requirement:** No initial requirement

## Syntax
- `strike match` — Strike a match (requires match in inventory)
- `strike match on [object]` — Strike match on specific surface

## Behavior
- **Match requirement:** Must have a match in inventory
- **Surface check:** Match may require specific striking surface (rough surface, box, etc.)
- **Search order:** Hands first (interaction verb)
- **State change:** Match transitions to "lit" or is consumed
- **Light source:** Struck match becomes a light source
- **Message:** "You strike a match."

## Design Notes
- **Fire source:** Matches are a primary fire-starting tool
- **Surface-specific:** Some matches require rough surface to strike
- **Consumption:** Matches are typically consumable (burn out)
- **Alternative:** Can use flint/steel or lighter instead

## Related Verbs
- `light` — Light other objects (using match as source)
- `burn` — Burn something with match flame

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["strike"]`
- **Ownership:** Bart (Architect) — state; Smithers (UI) — fire description
