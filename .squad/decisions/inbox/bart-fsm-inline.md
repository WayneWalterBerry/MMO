# Decision: FSM Definitions Live Inline in Object Files

**Date:** 2026-03-20  
**Author:** Bart (Architect), per Wayne's directive  
**Status:** Implemented  
**Affects:** All FSM-managed objects, engine/fsm, engine/verbs

## Decision

FSM state definitions are embedded directly in the object file. One file = one object = one FSM. The `src/meta/fsms/` directory has been deleted.

## Format

```lua
return {
    -- Base properties (persist across all states)
    id = "match",
    keywords = {"match", "stick"},
    size = 1, weight = 0.01, portable = true,

    -- Initial state + current state
    initial_state = "unlit",
    _state = "unlit",

    -- FSM definition (inline)
    states = {
        unlit = { name = "a wooden match", casts_light = false, ... },
        lit   = { name = "a lit match", casts_light = true, on_tick = function(obj) ... end },
        spent = { name = "a spent match", terminal = true },
    },
    transitions = {
        { from = "unlit", to = "lit", verb = "strike", requires_property = "has_striker" },
        { from = "lit", to = "spent", trigger = "auto", condition = "duration_expired" },
    },
}
```

## Detection

- `obj.states` exists → FSM-managed
- `obj.states` absent → plain object (backward compatible)
- `_fsm_id` is retired

## Hybrid Model

Objects can have BOTH `states`/`transitions` (FSM for reversible state changes) AND `mutations` (for destructive transformations). Example: curtains use FSM for open/close, mutations for tear.

## Rationale

- Eliminates file scatter (4 vanity files → 1)
- Single source of truth per object
- FSM engine unchanged in purpose, just reads from a different location
- Verb handlers check `obj.states` instead of `obj._fsm_id`
