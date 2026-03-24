# D-PREP-STRIP: Decorative Preposition Stripping in Parser Pipeline

**Author:** Smithers (UI/Parser Engineer)
**Date:** 2026-03-25
**Status:** Implemented
**Issue:** #154 (also fixes #147, #148)

## Decision

Added `strip_decorative_prepositions` as pipeline stage 4 (after `strip_noun_modifiers`, before `expand_idioms`). This stage distinguishes between **decorative** prepositions (location/manner — stripped) and **functional** prepositions (compound targets — preserved).

### Stripped (decorative):
- "as a/an WORD" — manner descriptor ("wear pot as a hat")
- "in the mirror/reflection" — reflective surface
- "on the floor/ground" — drop location
- "on/from (my) BODYPART" — body-part placement/source

### Preserved (functional):
- "put X in Y" — compound container target (skipped entirely for put/place/set verbs)
- "put X on Y" — compound surface target (unless Y is a body part)

### Additional: put-to-wear routing
`transform_compound_actions` now routes "put X on (my) BODYPART" → "wear X" directly in preprocessing, replacing the runtime routing in the put verb handler.

### Body Parts Table
Shared `BODY_PARTS` lookup at module scope: head, face, neck, arm(s), leg(s), hand(s), foot/feet, shoulder(s), waist, torso. Excludes "chest" and "back" (ambiguous with furniture/navigation).

## Rationale

Stage position 4 is critical: must run BEFORE `transform_look_patterns` so "look at myself in the mirror" → "look at myself" → appearance. Must run BEFORE `transform_compound_actions` so "drop knife on the floor" → "drop knife" (prevents false "drop X on Y" → "put X on Y" routing).
