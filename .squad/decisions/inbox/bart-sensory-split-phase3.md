# Decision: Split sensory verbs into modules

Date: $ts
Owner: Bart
Issue: Phase 3 refactor (sensory split)

## Decision
Split `src/engine/verbs/sensory.lua` into focused modules under `src/engine/verbs/sensory/` (look, touch, search, smell, taste, listen) with a thin wrapper preserving the existing registration API. Preserve verb aliases and handler behavior.

## Rationale
The sensory verb handler exceeded size thresholds and blocked parallel work. Modularizing it keeps behavior stable while improving navigability.

## Constraints
- Zero behavior changes
- Preserve verb registration and aliasing
- Keep output text and order intact
