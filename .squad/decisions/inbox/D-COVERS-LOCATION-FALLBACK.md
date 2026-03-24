# D-COVERS-LOCATION-FALLBACK

**Author:** Flanders (Object & Injury Systems)
**Date:** 2026-07-27
**Status:** Implemented
**Issues:** #155, #134

## Decision

`covers_location()` in `armor.lua` now falls back to `wear.slot` or `wear_slot` when no explicit `covers` array exists on a worn item. This is the correct behavior because ALL real wearable objects use `wear.slot` (not `covers`).

## Impact

- **Nelson:** Existing armor interceptor tests use `covers = { "head" }` on mock items — these still work (backward compatible). New tests in `test-ceramic-degradation.lua` use `wear.slot` like real objects.
- **Bart:** The armor interceptor now actually intercepts damage for all worn items, not just test mocks. `degrade_covering_armor()` is exported for verb-level degradation calls.
- **Smithers:** The tear verb now moves spawned items to player's hands. Any future verb that calls `perform_mutation` with spawns should consider whether results belong in hands or room.
- **CBG:** The terrible-jacket tear mutation (3 cloth spawns) will now also go to hands — verify this is desired behavior at next audit.

## Regression Risk

- Low. `covers` array still takes priority; fallback only fires when `covers` is absent.
- 3 pre-existing search test failures were resolved as a side effect.
