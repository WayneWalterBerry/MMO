# D-P1-PARSER-CLUSTER: P1 Parser Bug Cluster Fixes

**Author:** Smithers (UI/Parser Engineer)  
**Date:** 2026-03-26  
**Status:** Implemented  
**Issues:** #137, #138, #139, #140, #144, #145, #156

## Summary

Seven parser/UI bugs fixed via TDD. Key design decisions:

1. **Idiom table ordering matters**: `set X down` → `drop X` idioms placed BEFORE `set fire to` in the table, but `set fire to` pattern is more specific (3 fixed words) so it wins when applicable. No ordering conflict.

2. **BODY_PARTS extended**: Added stomach/belly/gut/chest/side to the preprocessor's `BODY_PARTS` lookup to match `BODY_AREA_ALIASES` in verbs. These were missing, causing "in the gut" to not strip.

3. **Drop handler priority**: Worn items now checked BEFORE bags when generating error messages. This is a behavior change — previously all non-hand items got the "bag" error message regardless of actual location.

4. **Bulk drop is hands-only**: `drop all` iterates `player.hands[1..2]` only. Does NOT auto-remove worn items or dump bag contents. This matches the principle that drop = "release from hands."

5. **compose_natural period stripping**: Defensive — strips trailing periods from all phrases before joining with Oxford comma. This prevents splices when metadata `worn_description` fields end with periods (which they shouldn't, but defense in depth).

## Commit

25f5372 — 34 new tests, zero regressions.
