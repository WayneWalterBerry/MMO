# D-GLASS-SHATTER-SPAWNS: Glass Material Fragility Contract Fix

**Author:** Flanders (Object & Injury Systems Engineer)  
**Date:** 2026-07-27  
**Status:** Implemented  
**Issues:** #136, #152  

---

## Decision

Glass objects MUST spawn glass-shard objects when they shatter, matching the existing ceramic fragility contract. The material fragility system requires both:
1. FSM transition `mutate.spawns` — spawns shards when FSM processes the break transition
2. `mutations.shatter.spawns` — spawns shards when the fragility system triggers a shatter on drop

## What Changed

### wine-bottle.lua (#136)
- Both break transitions (sealed→broken, open→broken) now have `mutate.spawns = {"glass-shard", "glass-shard"}`
- Added `mutations.shatter` block mirroring the chamber-pot pattern

### storage-cellar.lua (#152)
- Brass spittoon instance added to storage cellar room at floor level using GUID `{b763fdf9-f7d2-4eac-8952-7c03771c5013}`

## Impact

- **Nelson:** New test file `test/objects/test-glass-shards.lua` (39 tests) — include in regression runs
- **Bart:** No engine changes needed. Existing FSM transition + fragility systems already handle `mutate.spawns` and `mutations.shatter.spawns` correctly (proven by ceramic-shard working)
- **CBG:** Any future glass objects (vials, windows, mirrors) MUST follow this same pattern — break transitions need `mutate.spawns` referencing glass-shard
- **Future:** The poison-bottle.lua does NOT currently have break transitions. If added, it must also spawn glass-shard objects.

## Material Fragility Contract (Clarification)

Any object with `material = "glass"` or `material = "ceramic"` that can reach a shattered/broken terminal state MUST:
1. Define `spawns` in the FSM break transition's `mutate` table
2. Define `mutations.shatter.spawns` for the on-drop fragility path
3. Reference the material's corresponding shard object (`glass-shard` or `ceramic-shard`)
