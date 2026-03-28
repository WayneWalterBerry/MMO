# Smithers — Wave 1 Fix (Movement Verbs & Exit Doors)

**Status:** ✅ Complete  
**Date:** 2026-03-28T04:50Z  
**Duration:** 810 seconds  
**Model:** claude-opus-4.6  
**Mode:** background

## Manifest Assignment

- **Issue #388:** Movement verbs (north, south, etc.) failing on 21 tests
- **Issue #387:** Exit door handlers (open, close, unlock, lock) invisible to parser, 12 test failures

## Work Completed

### Issue #388 (Movement Verbs)
- Root cause: Exit doors stored in `room.exits` are plain tables, not registry objects
- `find_visible()` only searches registry → exits never found
- Fix: Added `find_exit_by_keyword()` helper to `src/engine/verbs/helpers/search.lua`
- Applied fallback pattern to all movement verbs (north, south, east, west, etc.)
- Result: 21 failures → 0

### Issue #387 (Exit Door Handlers)
- Scope: open, close, unlock, lock verbs on exit doors
- Applied exit resolution fallback pattern consistently
- Result: 12 failures → 0

## Key Artifacts

- **Commit:** 031b27d
- **Helper added:** `find_exit_by_keyword(ctx, noun)` → `(exit_table, direction_key)`
- **Pattern:** All door-interacting verbs now check exits after `find_visible()`
- **Decision created:** Exit Door Resolution Pattern (merged to decisions.md)

## Test Results

- `test/verbs/test-movement-verbs.lua`: All pass
- `test/verbs/test-door-verbs.lua`: All pass
- Overall: 21 + 12 failures resolved

## Notes

Clean implementation. No object-specific engine code added. Follows D-14 (code mutation = state).
