# Decision: P0-C Acceptance Criteria V2 Complete

**Author:** Lisa (Object Testing Specialist)
**Date:** 2026-03-24
**Status:** Ready for Implementation
**Affects:** Smithers (must implement), Flanders (injury/material authors), Moe (level authors)

## What

Authored `docs/meta-check/acceptance-criteria-v2.md` — ~160 new validation rules covering 4 meta types that V1 skipped:

| Meta Type | Rules | Files Covered |
|-----------|-------|---------------|
| Templates (definitions) | 27 | 5 files in `src/meta/templates/` |
| Injuries | 67 | 7 files in `src/meta/injuries/` |
| Materials | 24 | 23 files in `src/meta/materials/` |
| Levels (extended) | 31 | 1+ files in `src/meta/levels/` |
| Cross-references | 11 | References between all meta types |

Combined V1 + V2 = **~304 total rules**. Every `.lua` file under `src/meta/` is now covered.

## Impact

- **Smithers:** This is your spec for meta-check v2 implementation. Prioritize 🔴 ERROR rules first. Material validation is straightforward (11 required fields per file). Injury validation is the most complex (FSM + timed events + healing interactions).
- **Flanders:** New injury files must pass INJ-01 through INJ-69. Key requirement: `id` must match filename exactly, `healing_interactions` must be present (even if `{}`).
- **Moe:** New level files must pass LV-11 through LV-41. Completion criteria, boundaries, and intro structure are now validated.
- **Materials migration note:** `src/engine/materials/init.lua` dynamically loads from `src/meta/materials/`. Material validation rules (MD-01 through MD-24) apply to the meta files, not the engine.
