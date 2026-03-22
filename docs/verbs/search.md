# Search

> All-sense discovery verb — searches for objects using any available sense (vision, touch, hearing, smell).

## Synonyms
- `search` — Search around or for a specific object
- `search around` — Room sweep discovery
- `search for [object]` — Search for a specific thing
- Preprocessor converts "search around" → `search ""`

## Sensory Mode
- **Works in darkness?** ✅ Yes — uses any available sense
- **Senses used:** Vision (light), Touch (dark), Hearing, Smell, Taste
- **Adaptive:** Engine picks appropriate sense based on context
  - Light: "You search and spot the..."
  - Darkness: "You feel out a nightstand..."
  - Hearing: "You search and hear a faint ticking..."

## Syntax
- `search` — Search the room (room sweep, all reachable objects)
- `search around` — Same as search (normalized by preprocessor)
- `search for [object]` — Search for something specific
- `search around for [object]` — Verbose form

## Behavior
- **Without object:** Performs room sweep — describes all discoverable objects
- **With object:** Searches for specific object using all available senses
- **Discovery sequence:** 
  1. Check if object already known/visible
  2. Use vision if light available
  3. Use touch if in darkness
  4. Use hearing for sound sources (ticking, etc.)
  5. Use smell for scented objects
- **Once found:** Player knows location — can interact even without direct line of sight
- **Search order:** Room/surfaces first (acquisition verb)

## Design Notes
- **Wayne's directive (2026-03-22T04:03):** "`find` and `search` = use ALL senses (works in dark and light)"
- **Core distinction:** `search`/`find` ≠ `look`/`see`. Search uses all senses; look is vision-only.
- **Example from directive:** 
  - "search around in dark" → "you feel out a nightstand"
  - "search around in light" → "you see a nightstand"
  - "find the ticking" → uses hearing to locate source
- **Once discovered:** Object becomes knowable for subsequent commands (e.g., "open drawer" works even if initially found by touch)
- **Sensory output:** Engine determines sense used; presentation adapts output accordingly

## Related Verbs
- `find` — Universal discovery (distinction: search is targeted, find is more exploratory)
- `look` — Vision-only observation (fails in darkness)
- `feel` — Touch-based groping (darker, more intimate exploration)
- `listen` — Hearing-based discovery
- `smell` — Olfactory exploration

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["search"]`
- **Preprocessor:** `src/engine/parser/preprocess.lua` normalizes "search around" → search ""
- **Sensory engine:** `src/engine/ui/presentation.lua` determines light level and selects sense
- **Ownership:** Bart (Architect) — sensory mode selection; Smithers (UI) — sensory output presentation
