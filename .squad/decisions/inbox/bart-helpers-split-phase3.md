## Decision: Split verbs/helpers.lua into modules

**Date:** 2026-08-21  
**Owner:** Bart (Architect)  
**Status:** Proposed  

### Context
Phase 3 refactor requires splitting `src/engine/verbs/helpers.lua` with zero behavior changes. The file was 1,600+ LOC and a shared dependency for all verb handlers, so modularization reduces cognitive load and future merge risk.

### Decision
Split helpers into focused modules under `src/engine/verbs/helpers/`:
- `core.lua` (shared dependencies, time/light helpers, `hobj`)
- `inventory.lua` (hands, part detach/reattach, remove-from-location, inventory weight)
- `search.lua` (keyword matching, find_visible, find_in_inventory + search subroutines)
- `tools.lua` (tool capability lookup + charge handling)
- `mutation.lua` (container access, mutations, spatial movement)
- `combat.lua` (self-infliction + `try_fsm_verb`)
- `portal.lua` (portal lookup + bidirectional sync)

`src/engine/verbs/helpers.lua` now re-exports the same API surface. Guarded `butchery`'s `carve` alias so combat keeps ownership when registered earlier.

### Consequences
- No behavior change; all existing call sites continue via re-export layer.
- Test suite re-run; only pre-existing failures remain.
- Future Phase 3 refactors can target the smaller helper modules independently.
