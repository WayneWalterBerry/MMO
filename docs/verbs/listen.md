# Listen

> Hearing-based sensory verb — listen to ambient sounds or specific sound sources.

## Synonyms
- `listen` — Listen to ambient sounds
- `listen to [object]` — Listen to a specific sound source
- `hear` — Implied sensory mode

## Sensory Mode
- **Works in darkness?** ✅ Yes — hearing works without vision
- **Primary sense:** Hearing/Auditory
- **Light requirement:** None

## Syntax
- `listen` — Listen to ambient sounds in the room
- `listen to [object]` — Listen closely to a specific sound source
- `hear [object]` — Hear something (question pattern)

## Behavior
- **Without object:** Listens to ambient room sounds
- **With object:** Focuses on specific sound source (ticking, breathing, etc.)
- **Silent objects:** Describe silence or lack of sound
- **Information:** Returns what can be heard about the object
- **Search order:** Room/surfaces first (discovery verb)

## Design Notes
- **Discovery capability:** Hearing can discover objects without vision (e.g., "find the ticking")
- **All-sense discovery:** Hear is one sense available to `search` and `find` verbs
- **No light requirement:** Pure sensory access to auditory information
- **Ambient vs. focused:** Can listen broadly or target specific sources

## Related Verbs
- `search` — May use hearing as one sense
- `find` — May use hearing to locate
- `smell` — Complementary sensory verb
- `taste` — Complementary sensory verb
- `feel` — Complementary sensory verb

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["listen"]`
- **Ownership:** Smithers (UI Engineer) — auditory descriptions and sensory output
