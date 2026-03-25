# Decision: Fuzzy fallback for hand/worn item searches

**Author:** Smithers (UI Engineer)
**Date:** 2026-07-17
**Bug:** #181

## Context

The `drop` verb handler searched hands using `matches_keyword()` (exact-only), bypassing the Tier 5 fuzzy resolver. This meant typos like "drop spitton" failed even though the spittoon was in hand. The `get` verb worked because it uses `find_visible()` which has fuzzy built in.

## Decision

1. **Verb handlers that search hands/worn/bags directly must add fuzzy fallback** when exact match fails. Use `fuzzy.parse_noun_phrase()` + `fuzzy.score_object()` as the fallback pattern.

2. **The `look X` bare-noun dark path now delegates to examine** instead of returning a generic "too dark" error. This gives the player tactile feedback on what they tried to look at, which is better UX and consistent with how `look at X` already works in darkness.

3. **The examine dark-path output now includes the object name** ("It's too dark to see a brass spittoon, but you feel: ...") so that fuzzy-matched items are identifiable to the player.

## Affected Files

- `src/engine/verbs/acquisition.lua` — drop handler fuzzy fallback for hands + worn items
- `src/engine/verbs/sensory.lua` — examine dark-path name inclusion, look→examine dark delegation

## Impact

- **Nelson:** 24/24 tests pass in `test/verbs/test-fuzzy-drop.lua`
- **Bart:** No engine-level changes needed — fuzzy module API used as-is
- **All verb authors:** If you write a new handler that searches hands directly (bypassing `find_visible`), add the fuzzy fallback pattern
