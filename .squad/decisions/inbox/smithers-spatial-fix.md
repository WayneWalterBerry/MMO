# Decision: Read-Only Search Peek for Containers

**Date:** 2026-03-27
**Author:** Smithers (UI Engineer)
**Status:** Implemented
**Commit:** 70fc91f
**Issues:** #24, #26, #27

## Context

The search system had three related bugs in how it interacted with spatial relationships:
1. Hidden objects (trap door under rug) were discoverable by search (#26)
2. Search auto-opened containers (drawers, wardrobes) as a side effect (#24)
3. Search didn't report container contents when the target wasn't found (#27)

## Decision

### Hidden Object Filtering
Added `obj.hidden` checks to both `expand_object()` and `matches_target()` in traverse.lua. Hidden objects are ghosts — completely invisible to the search engine until explicitly revealed by the move verb handler.

### Read-Only Peek (Not Open)
Search now "peeks" inside closed containers without changing their state. The old code called `containers.open()` and FSM `transition()` during search, which mutated object state. The new code reads `contents` directly without triggering any state transitions.

**Key distinction:** Container surfaces (nightstand drawer) can be peeked into during search. Non-container inaccessible surfaces (rug's underneath) are truly hidden and cannot be peeked — they require the covering object to be physically moved first.

### Content Reporting
Added narrator functions to report what IS inside a container when the target isn't found. This gives players useful information about the game world during search.

## Alternatives Considered

1. **Save/restore state:** Open the container, search, then close it again. Rejected — fragile, could fail if FSM transitions have side effects (sounds, messages), and violates the principle that search is observation, not action.

2. **Separate "search-open" FSM event:** Add a special "peek" transition to container FSMs. Rejected — overengineered, every container would need a peek transition, and the simpler approach (just read contents) works fine.

## Consequences

- Search is now purely observational — it never mutates game state
- Players must explicitly `open` containers if they want to change their state
- The `accessible` flag on surfaces now has two semantics: container-accessible (peekable) vs. physically-blocked (not peekable)
