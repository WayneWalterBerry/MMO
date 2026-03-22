# Look

> Vision-only observation of the current room and visible objects.

## Synonyms
- `look` — Look around the room
- `see` (implied) — Vision-based observation

## Sensory Mode
- **Works in darkness?** ❌ No — requires light
- **Primary sense:** Vision
- **Light level:** Needs at least some light (DAYTIME_START onwards)

## Syntax
- `look` — Look around the room
- `look around` — Same as look (alias)
- `look at [object]` — Examine a specific object closely
- `look in [container]` — Look inside a container
- `look on [surface]` — Look on top of a surface
- `look under [object]` — Look underneath something

## Behavior
- **Without arguments:** Prints room description, exits, visible objects, and people
- **With object:** Prints object description if visible
- **In darkness:** "It is too dark to see anything. You could try feeling around."
- **Light level checks:** Uses `has_some_light(ctx)` — requires GAME_SECONDS since daylight started

## Design Notes
- **Sensory distinction:** `look` and `see` are **vision only** and fail in darkness. This is the core search/find/look distinction.
- **Fallback:** Use `feel` or `search` for exploration in darkness
- **From Wayne's directive:** "look and see = vision only (requires light)"
- The engine provides light level info; presentation handles sensory output

## Related Verbs
- `search` — All-sense discovery (works in darkness)
- `find` — Universal search verb (all senses)
- `feel` — Touch-based groping (works in darkness)
- `examine` — Vision-focused close inspection, but falls back to touch in darkness

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["look"]`
- **Ownership:** Smithers (UI Engineer) — text presentation, sensory output
