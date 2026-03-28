# Flanders — Wave 1 Fix (Wolf Territory, Silk Bandage, Spider Web)

**Status:** ✅ Complete  
**Date:** 2026-03-28T04:50Z  
**Duration:** 825 seconds  
**Model:** claude-sonnet-4.5  
**Mode:** background

## Manifest Assignment

- **Issue #380:** Wolf territory object definitions incomplete
- **Issue #378:** Silk bandage `use_effect` handler failing
- **Issue #379:** Spider web `creates_object` mutation template ignored

## Work Completed

### Issue #380 (Wolf Territory)
- Scope: Object definitions for wolf-themed room
- Created/updated wolf, den, carcass object definitions
- Integrated with room nesting structure
- Result: 0 failures

### Issue #378 (Silk Bandage Use)
- Root cause: `use_effect` handler not invoking bandage healing logic
- Fix: Added conditional in effects pipeline to call bandage heal action
- Result: Bandage now usable for injury treatment

### Issue #379 (Spider Web Creation)
- Root cause: `creates_object.template` field ignored by handler
- Engine was using inline `object_def` instead of template instantiation
- **Crossed into engine territory:** Modified `src/engine/creatures/actions.lua`
- Fix: Check `creates_object.template` first; call `registry:instantiate(template)`
- Also added `max_per_room` enforcement (counting objects in room)
- Result: Spider now creates web objects with proper GUID + template support

## Key Artifacts

- **Commit:** 4827a5e
- **Objects updated:** `src/meta/objects/wolf.lua`, `src/meta/objects/spider-web.lua`
- **Engine fix:** `src/engine/creatures/actions.lua` (template + max_per_room support)
- **Decision created:** create_object handler uses template + max_per_room (merged)

## Test Results

- `test/verbs/test-injury-healing.lua`: Bandage tests pass
- `test/creatures/test-spider-web.lua`: Creation tests pass
- Overall: 3 issues resolved; 0 failures

## Notes

Spider web fix required engine changes per object requirements. No object-specific logic added to engine — the `template` + `max_per_room` pattern is generic and reusable across all creatures. Documented decision for future creature designers.
