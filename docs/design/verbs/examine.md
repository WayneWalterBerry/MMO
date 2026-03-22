# Examine

> Close inspection verb — adaptive sensory mode based on light availability.

## Synonyms
- `examine` — Examine an object closely
- `inspect` — Synonym for examine
- `x` — Keyboard shortcut for examine

## Sensory Mode
- **Works in darkness?** ✅ Yes — falls back to touch
- **Primary sense (light):** Vision
- **Fallback sense (dark):** Touch
- **Adaptive:** "examine" adjusts based on available light
  - Light: "You examine the nightstand carefully. It has three drawers..."
  - Darkness: "You feel the nightstand carefully by touch. It's wooden, three drawers..."

## Syntax
- `examine [object]` — Examine an object closely
- `inspect [object]` — Synonym for examine
- `x [object]` — Keyboard shortcut (examine)
- `examine [object] in [container]` — Examine an object inside something

## Behavior
- **Visual mode (light):** Returns detailed object description, properties, states
- **Tactile mode (dark):** Returns touch-based description — size, shape, texture, temperature
- **Required light check:** Uses `has_some_light(ctx)`
- **Information depth:** Higher detail than look, but sensory presentation differs by light level
- **Object states:** Describes current FSM state if applicable

## Design Notes
- **Special hybrid verb:** Unlike pure vision verbs (`look`) or pure sensory verbs (`feel`), `examine` adapts
- **Wayne's design intent:** `examine` is the closest inspection verb — should work even in darkness by touch
- **Sensory output:** Engine presents findings through available sense:
  - "You examine the box closely. It's oak, 12 inches wide..."
  - vs. "You examine the box in the darkness. It feels like oak, roughly 12 inches wide, smooth finish..."
- **Player intent preserved:** Regardless of sensory mode, the action is the same — detailed inspection
- **Search order:** Uses standard search (hands/inventory first for interaction verbs)

## Related Verbs
- `look` — Vision-only observation (fails in darkness)
- `look at [object]` — Vision-only close look (synonym for examine in light)
- `feel` — Touch-based exploration (always tactile)
- `search` — All-sense discovery (find before examining)
- `find` — Locate using any sense (enables examination)

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["examine"]`
- **Light check:** `has_some_light(ctx)` determines sensory mode
- **Output presentation:** `src/engine/ui/presentation.lua` generates sensory-appropriate descriptions
- **Ownership:** Smithers (UI Engineer) — sensory presentation; Bart (Architect) — verb logic and state inspection
