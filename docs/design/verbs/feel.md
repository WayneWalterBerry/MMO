# Feel

> Touch-based tactile exploration — grope around or feel specific objects by hand.

## Synonyms
- `feel` — Feel around the room or feel an object
- `grope` — Synonym for feel around
- `grope around` — Room sweep by touch
- Preprocessor converts "grope around" → feel ""

## Sensory Mode
- **Works in darkness?** ✅ Yes — pure tactile sense
- **Primary sense:** Touch/Tactile
- **Light requirement:** None — works equally well in light or dark

## Syntax
- `feel` — Feel around the room (tactile room sweep)
- `feel around` — Same as feel (normalized)
- `feel [object]` — Feel a specific object by touch
- `grope around` — Verbose form of feel around

## Behavior
- **Without object:** Tactile room sweep — player extends hands to feel nearby objects
- **With object:** Locates and describes object through touch alone
- **Information provided:** Size, shape, texture, temperature (what touch conveys)
- **Vision unavailable:** No visual details; only tactile impressions
- **Search order:** Room/surfaces first (acquisition verb)

## Design Notes
- **Sensory availability:** Feel works in complete darkness — no light requirement
- **From Wayne's directive:** "search around" in dark → "you feel out a nightstand"
- **Distinction from search:** `feel` is explicitly tactile; `search` adapts sensory mode
- **First-class status:** Feel is now promoted as a discovery verb equal to look/search/find
- **Interaction discovery:** Once an object is felt and known, player can interact with it without seeing it
- **Player touch:** Uses player's hands to feel around — requires free movement

## Related Verbs
- `search` — All-sense discovery (may use touch as one sense)
- `find` — Universal discovery (may use touch)
- `look` — Vision-only (opposite sense)
- `touch` — Direct tactile interaction (specific object)
- `listen` — Hearing-based discovery (complementary sense)
- `smell` — Olfactory discovery (complementary sense)

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["feel"]`
- **Preprocessor:** `src/engine/parser/preprocess.lua` converts "grope around" and "feel around" → feel ""
- **Sensory output:** `src/engine/ui/presentation.lua` generates tactile descriptions
- **Ownership:** Smithers (UI Engineer) — text presentation and sensory output; Bart (Architect) — verb logic
