# Find

> Universal discovery verb — locate objects using all available senses.

## Synonyms
- `find` — Find a specific object
- `find [object]` — Search for and locate something
- Preprocessor converts "find X" patterns to find verb

## Sensory Mode
- **Works in darkness?** ✅ Yes — uses any available sense
- **Senses used:** Vision (light), Touch (dark), Hearing, Smell, Taste
- **Adaptive:** Engine picks appropriate sense based on context
  - Light: "You look around and find the..."
  - Darkness: "You feel around and discover a..."
  - Hearing: "You listen and locate a faint..."

## Syntax
- `find [object]` — Find something specific
- `find the [object]` — Find with article
- `find [sound]` — Find something by hearing (e.g., "find the ticking")

## Behavior
- **Requires object:** Cannot use bare `find` without a target
- **Discovery sequence:** 
  1. Check visible objects first (if light available)
  2. Check tactile discovery (if in darkness)
  3. Check auditory cues (if appropriate)
  4. Check olfactory cues (if appropriate)
- **Once found:** Player knows location and can interact
- **Sensory awareness:** Output describes which sense was used
- **Search order:** Room/surfaces first (acquisition verb)

## Design Notes
- **Wayne's directive (2026-03-22T04:03):** "`find` and `search` = use ALL senses"
- **Distinction from `search`:** `find` is typically directed at a specific object ("find X"), while `search` can be undirected ("search around"). Both use all senses.
- **Example from directive:** 
  - "find the ticking" → uses hearing to locate the source
  - "find the nightstand" → uses vision in light, touch in dark
- **Parser optimization:** `find` requires a noun argument; errors if none provided
- **Integration:** Once discovered via `find`, object is "known" for future interactions

## Related Verbs
- `search` — All-sense discovery, can be undirected ("search around") or directed ("search for X")
- `look` — Vision-only observation
- `listen` — Hearing-based discovery (narrower than find)
- `smell` — Olfactory discovery (narrower than find)
- `feel` — Touch-based discovery (narrower than find)

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["find"]`
- **Preprocessor:** `src/engine/parser/preprocess.lua` converts question patterns to find verb
- **Sensory engine:** `src/engine/ui/presentation.lua` determines light level and selects sense
- **Ownership:** Bart (Architect) — verb logic and sensory selection; Smithers (UI) — output presentation
