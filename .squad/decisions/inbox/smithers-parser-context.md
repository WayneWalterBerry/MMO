# Decision: Parser Context Retention Between Commands (BUG-060)

**Author:** Smithers (UI Engineer)
**Date:** 2026-03-21
**Status:** Implemented
**Affects:** engine/loop/init.lua, engine/parser/preprocess.lua

## Context

The parser lost context between commands. After "search wardrobe", typing "open" would fail with "Open what?" because the parser didn't remember "wardrobe" as the active noun.

## Decision

The game loop now maintains `context.last_noun` — the last successfully referenced noun from a verb+noun command. On subsequent commands:

1. **Empty noun + action verb** → substitutes `context.last_noun` (e.g., "search wardrobe" then "open" → opens wardrobe)
2. **Pronoun** ("it", "that", "this", "them", "those") → resolves to `context.last_noun`
3. **Direction/room verbs** (look, feel, north, inventory, etc.) → excluded from context inheritance via explicit `no_noun_verbs` list

The noun is stored bare (prepositions stripped: "in wardrobe" → "wardrobe") so it works across different verb preposition patterns.

## Rationale

- Explicit exclusion list is safer than trying to detect which verbs need nouns
- Stored at the loop level (not parser level) because noun resolution depends on verb handler success
- Single `last_noun` rather than a stack — text adventures traditionally use single-reference context

## Implications

- Any new verb that operates on the room (no noun expected) must be added to `no_noun_verbs`
- The context resets naturally when the player references a new noun
- Compound commands ("open and search") propagate context within the same input line
