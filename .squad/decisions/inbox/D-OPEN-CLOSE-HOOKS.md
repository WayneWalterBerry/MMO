# D-OPEN-CLOSE-HOOKS: on_open and on_close Engine Hooks

**Author:** Bart (Architect)  
**Date:** 2026-03-28  
**Status:** Implemented  

## Decision

Added `on_open` and `on_close` hooks to the open/close verb handlers, following the exact pattern of `on_wear`/`on_remove_worn`. Both support:
1. **Callback hooks:** `obj.on_open = function(obj, ctx) ... end` — fires after successful FSM transition
2. **event_output:** `event_output = { on_open = "text", on_close = "text" }` — one-shot flavor text, consumed after first fire

## Hook Taxonomy (Updated)

| Hook | Verb | Pattern |
|------|------|---------|
| `on_wear` | wear | callback + event_output |
| `on_remove_worn` | remove | callback + event_output |
| `on_open` | open | callback + event_output |
| `on_close` | close | callback + event_output |
| `on_drop` | drop | fragility + event_output |
| `on_take` | take | event_output only |

## Usage

```lua
return {
    id = "treasure-chest",
    on_open = function(obj, ctx)
        -- Fire trap, update puzzle state, etc.
    end,
    event_output = {
        on_open = "A musty waft of stale air escapes the chest.",
        on_close = "The lid slams shut with a hollow boom.",
    },
}
```

## Constraints

- Hooks only fire on the FSM path (objects with `.states`). Mutation-based open/close does not fire hooks.
- Hooks fire AFTER the transition message prints but BEFORE the verb handler returns.
- Failed transitions (already open/closed, can't open) do NOT fire hooks.
