# Decision: Unconsciousness Trigger Object Conventions

**Author:** Flanders  
**Date:** 2026-07-28  
**Issue:** #162  
**Status:** ACTIVE  

## Context

Built 4 unconsciousness trigger objects per CBG's design doc. Several conventions and gaps emerged that affect Bart (engine), Smithers (parser), and future object authors.

## Decisions

### D-UNCONSC-OBJ-FIELDS: Standard fields for unconsciousness-causing objects

Every object that causes unconsciousness MUST declare:
- `causes_unconsciousness = true`
- `injury_type = "concussion"` (all KO sources use concussion injury)
- `unconscious_severity` — one of: `"minor"`, `"moderate"`, `"severe"`, `"critical"`
- `unconscious_duration = { min = N, max = N }` — turn range for KO

Additionally, the transition's `pipeline_effects` must include an `inflict_injury` entry with `causes_unconsciousness = true` and `unconscious_duration` for the effects pipeline to process.

### D-UNCONSC-MATERIALS: Use registered materials only

Objects must use materials from the material registry (`src/engine/materials/init.lua`). Mappings:
- Real-world "granite" → use `stone`
- Real-world "timber" → use `wood`
- `oak` and `iron` exist in registry as-is

### D-UNCONSC-ENGINE-GAP: Effects pipeline needs consciousness interceptor

**For Bart:** The `causes_unconsciousness` field on `inflict_injury` effects is currently ignored. The effects pipeline dispatches the injury but never sets `player.consciousness.state = "unconscious"`. An after-effect interceptor is needed.

### D-UNCONSC-VERB-GAP: Missing verb handlers for trigger objects

**For Smithers:** The following verb handlers do not exist and are needed for self-infliction:
- `breathe` — routes to gas vent trigger
- `trigger` — routes to trap trigger
- `step` — routes to pressure plate activation

## Affected Team Members

- **Bart** — Must add consciousness interceptor to effects pipeline
- **Smithers** — Must add breathe/trigger/step verb handlers
- **Nelson** — 7 TDD tests awaiting engine/verb support
- **Future object authors** — Follow D-UNCONSC-OBJ-FIELDS convention
