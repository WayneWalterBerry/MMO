# Read

> Read text on an object — may teach skills or provide information.

## Synonyms
- `read` — Read text

## Sensory Mode
- **Works in darkness?** ❌ No — requires light
- **Light requirement:** Yes

## Syntax
- `read [object]` — Read something
- `read [text] on [object]` — Read specific text

## Behavior
- **Visibility:** Object must be visible (requires light)
- **Text check:** Object must have readable text
- **Skill learning:** Reading may teach skills (defined on object)
- **Message:** Prints readable text or skill message
- **One-time learning:** Skills typically learned once, not repeatedly

## Design Notes
- **Skill gate:** Primary mechanism for teaching skills to players
- **Light requirement:** Vision-only verb
- **Object data:** Reading text comes from object definition
- **Puzzle mechanic:** Some puzzles require finding and reading instructions

## Related Verbs
- `examine` — Examine object (does not read)
- `look at` — Look at object (does not read)
- `write` — Write text (create readable objects)

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["read"]`
- **Skill learning:** Uses skill system
- **Ownership:** Smithers (UI) — text presentation
