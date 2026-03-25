# Decision: Door/Exit Architecture Direction

**Author:** Bart (Architecture Lead)  
**Date:** 2026-07-28  
**Status:** Proposed — awaiting Wayne's decision  
**Analysis:** `plans/door-architecture-analysis.md`

## Summary

After deep analysis of the current hybrid door/exit system against all 11 Core Principles, I recommend **Option B: Doors become first-class objects** using a `passage` template and the existing object system (FSM, mutation, sensory, materials).

## Key Finding

The current exit system is a **parallel object system** — ~322 lines of exit-specific engine code across 8 files duplicating capabilities the object system already provides (FSM, mutation, keyword matching, sensory, effects). Exits satisfy **0 of 11** Core Principles. Full unification satisfies **11 of 11**.

## Proposed Approach

1. Create `passage` template for traversable objects
2. Room `exits` tables become thin direction → passage-object-ID references
3. Door state managed by standard FSM (`traversable` flag per state)
4. Door mutations use standard `becomes` code rewrite (D-14 compliant)
5. Remove `becomes_exit`, `exit_matches()`, and exit-specific verb paths
6. Incremental migration: one door at a time, backward-compatible

## Impact

- **Net -177 lines** of engine code (remove 252 exit-specific, add 75 passage support)
- Unlocks: multi-step mechanisms, composite doors, material-derived behavior, timed passages, reusable templates
- **4-6 sessions** estimated for full migration

## Decision Points for Wayne

1. Go/No-Go on unification
2. Template name: `passage` (recommended) vs `portal` vs `exit`
3. Bidirectional strategy: paired objects (recommended) vs single shared object
4. Migration start: bedroom-hallway door (recommended first candidate)

## Who Should Know

- **Flanders** — door object definitions will migrate to passage template pattern
- **Moe** — room exit tables simplify to thin references
- **Smithers** — exit-specific parser/verb code paths will be removed
- **Nelson** — ~15-20 test files need mock context updates during migration
- **Comic Book Guy** — new game design possibilities (drawbridges, mechanisms, magical wards)
