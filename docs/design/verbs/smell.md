# Smell

> Olfactory sensory verb — smell ambient odors or specific objects.

## Synonyms
- `smell` — Smell the air or a specific object
- `sniff` — Smell (synonym)

## Sensory Mode
- **Works in darkness?** ✅ Yes — olfaction works without light
- **Primary sense:** Smell/Olfactory
- **Light requirement:** None

## Syntax
- `smell` — Smell the air in the room
- `smell [object]` — Smell a specific object
- `sniff [object]` — Sniff something (synonym)

## Behavior
- **Without object:** Detects ambient odors in the room
- **With object:** Describes the smell of a specific object
- **Olfactory clues:** May reveal hidden information via scent
- **Search order:** Room/surfaces first (discovery verb)

## Design Notes
- **Discovery sense:** Smell can help locate objects ("find the rose garden")
- **All-sense discovery:** Available as one sense in `search` and `find` verbs
- **No light required:** Works in complete darkness
- **Atmospheric:** Smell is often used for flavor/mood alongside other senses

## Related Verbs
- `search` — May use smell as one sense
- `find` — May use smell to locate
- `listen` — Complementary sensory verb
- `taste` — Complementary sensory verb
- `feel` — Complementary sensory verb

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["smell"]` and `handlers["sniff"]`
- **Ownership:** Smithers (UI Engineer) — olfactory descriptions
