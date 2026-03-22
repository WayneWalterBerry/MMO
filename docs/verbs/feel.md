# Feel

> Touch-based tactile exploration — grope around or feel specific objects by hand.

## Synonyms
- `feel` — Feel around the room or feel an object
- `grope` — Synonym for feel around
- `grope around` — Room sweep by touch
- `touch` — Direct tactile interaction with an object
- Preprocessor converts "grope around" → feel ""

## Sensory Mode
- **Works in darkness?** ✅ Yes — pure tactile sense
- **Primary sense:** Touch/Tactile
- **Light requirement:** None — works equally well in light or dark

## Syntax

### Feeling Around
- `feel` — Feel around the room (tactile room sweep)
- `feel around` — Same as feel (normalized)
- `grope around` — Verbose form of feel around

### Feeling Specific Objects
- `feel [object]` — Feel a specific object by touch
- `touch [object]` — Touch something (direct tactile interaction)

## Behavior

### Feeling Around (Room Sweep)
- **Without object:** Tactile room sweep — player extends hands to feel nearby objects
- **Information provided:** Size, shape, texture, temperature (what touch conveys)
- **Vision unavailable:** No visual details; only tactile impressions
- **Search order:** Room/surfaces first (acquisition verb)

### Feeling Specific Objects
- **With object:** Locates and describes object through touch alone
- **Object interaction:** Simple tactile contact (for touch verb)
- **Information:** May provide tactile description
- **State check:** Checks object state/condition by touch

### Touch-Specific Behavior
- **Search order:** Hands first (interaction verb)
- **Tactile discovery:** Can discover objects by touching
- **Message:** Tactile description of the object

## Design Notes
- **Sensory availability:** Feel works in complete darkness — no light requirement
- **From Wayne's directive:** "search around" in dark → "you feel out a nightstand"
- **Distinction from search:** `feel` is explicitly tactile; `search` adapts sensory mode
- **First-class status:** Feel is now promoted as a discovery verb equal to look/search/find
- **Interaction discovery:** Once an object is felt and known, player can interact with it without seeing it
- **Player touch:** Uses player's hands to feel around — requires free movement
- **Basic interaction:** Touch is less specific than examine or feel; basic tactile discovery

## Related Verbs
- `search` — All-sense discovery (may use touch as one sense)
- `find` — Universal discovery (may use touch)
- `look` — Vision-only (opposite sense)
- `listen` — Hearing-based discovery (complementary sense)
- `smell` — Olfactory discovery (complementary sense)
- `examine` — Closer inspection

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["feel"]`, `handlers["touch"]`
- **Preprocessor:** `src/engine/parser/preprocess.lua` converts "grope around" and "feel around" → feel ""
- **Sensory output:** `src/engine/ui/presentation.lua` generates tactile descriptions
- **Ownership:** Smithers (UI Engineer) — text presentation and sensory output; Bart (Architect) — verb logic
