# Write

> Write text on a writable surface.

## Synonyms
- `write` — Write text
- `inscribe` — Write/inscribe (synonym)

## Sensory Mode
- **Works in darkness?** ❌ No — requires light
- **Light requirement:** Yes

## Syntax
- `write [text] on [object]` — Write text on object
- `inscribe [text] on [object]` — Inscribe (synonym)

## Behavior
- **Writable check:** Object must have `writable = true` or similar
- **Text argument:** Player provides text to write
- **Surface limit:** Object may have character/space limit
- **State change:** Object's text property updated
- **Message:** "You write X on Y."

## Design Notes
- **Puzzle creation:** Players can create readable objects via write
- **Permanent text:** Written text persists (unless overwritten)
- **Light requirement:** Vision needed to write neatly

## Related Verbs
- `read` — Read written text

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["write"]`, `handlers["inscribe"]`
- **Ownership:** Bart (Architect) — state mutation
