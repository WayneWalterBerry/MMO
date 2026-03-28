# Smithers-A — Wave 2 Bugfix (Search Discovery, Container Openability, Pillow Pin)

**Status:** ✅ Complete  
**Date:** 2026-03-28T14:30Z  
**Duration:** 1483 seconds (~24.7 minutes)  
**Model:** claude-opus-4.6  
**Mode:** background

## Manifest Assignment

- **Issue #385:** Search discovery verb broken; container objects not discoverable via search
- **Issue #384:** Search verb fails to open containers for inspection
- **Issue #377:** Pillow pin (small object) not findable within pillow

## Work Completed

### Issue #385 (Search Discovery)
- Root cause: `search` verb did not recursively traverse nested containers in room
- Fix: Enhanced `find_visible()` to search `room_presence` properties recursively; added depth controls
- Result: 4 test assertions fixed

### Issue #384 (Search Opens Containers)
- Scope: search verb must open closed containers to reveal contents
- Fix: Added container openability check; opens non-locked containers during search
- Result: 4 test assertions fixed

### Issue #377 (Pillow Pin Discovery)
- Scope: Small objects nested within containers (e.g., pin inside pillow)
- Fix: Applied deep traversal pattern; `peek_open()` helper added for non-destructive container access
- Result: 1 test assertion fixed

## Key Artifacts

- **Commit:** 031b27d (Wave 2 — Smithers-A)
- **Helper added:** `peek_open()` → non-destructive container inspection
- **Pattern:** Recursive container traversal with depth limits
- **Total test assertions fixed:** 9

## Test Results

- `test/verbs/test-search.lua`: All pass
- `test/search/test-container-discovery.lua`: All pass
- `test/inventory/test-nested-objects.lua`: All pass

## Notes

Established deep nesting traversal pattern for future search enhancements. Maintains D-14 (code mutation = state).
