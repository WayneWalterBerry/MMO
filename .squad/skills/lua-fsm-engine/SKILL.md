# SKILL: Table-Driven FSM Engine in Lua

## What This Solves

Objects that have multiple states (match: unlit/lit/spent, nightstand: closed/open) were managed as separate files with the mutation system hot-swapping entire objects. This caused duplication and made state transitions fragile. The FSM engine provides a single definition per object with declarative state transitions.

## Pattern

### FSM Definition Format

```lua
-- src/meta/fsms/{object_id}.lua
return {
    id = "match",
    initial_state = "unlit",

    -- Properties that don't change across states
    shared = {
        keywords = {"match", "stick"},
        size = 1, weight = 0.01, portable = true,
    },

    -- Per-state property overrides (merged onto object during transition)
    states = {
        unlit = {
            name = "a wooden match",
            description = "An unlit match...",
            casts_light = false,
        },
        lit = {
            name = "a lit match",
            description = "A burning match...",
            provides_tool = "fire_source",
            casts_light = true,
            burn_remaining = 3,
            -- Engine-only: called each tick, returns trigger or warning
            on_tick = function(obj)
                obj.burn_remaining = obj.burn_remaining - 1
                if obj.burn_remaining <= 0 then
                    return { trigger = "duration_expired" }
                elseif obj.burn_remaining == 1 then
                    return { warning = "The flame flickers low..." }
                end
            end,
        },
        spent = {
            name = "a spent match",
            casts_light = false,
            terminal = true,  -- no transitions out
        },
    },

    transitions = {
        { from = "unlit", to = "lit", verb = "strike",
          requires_property = "has_striker",  -- checked on context.target
          message = "The match ignites!" },
        { from = "lit", to = "spent", trigger = "auto",
          condition = "duration_expired",
          message = "The match dies." },
    },
}
```

### Engine API

```lua
local fsm = require("engine.fsm")

-- Query available transitions for verb handlers
local transitions = fsm.get_transitions(obj)  -- returns non-auto transitions

-- Execute a state transition (returns transition table or nil + error)
local trans, err = fsm.transition(registry, obj_id, "lit", { target = matchbox })

-- Process auto-transitions (call after each command)
local msg = fsm.tick(registry, obj_id)  -- returns message string or nil
```

### Verb Handler Integration Pattern

```lua
if obj._fsm_id then
    local transitions = fsm.get_transitions(obj)
    local target_state
    for _, t in ipairs(transitions) do
        if t.verb == "open" then target_state = t.to; break end
    end
    if target_state then
        local trans, err = fsm.transition(registry, obj.id, target_state, {})
        if trans then print(trans.message) end
    else
        if obj._state == "open" then print("Already open.") end
    end
    return
end
-- ... fall through to old mutation system
```

## Critical Implementation Details

### 1. Save containment BEFORE cleanup

`apply_state` removes old state keys, which includes `surfaces`. Save surface contents at the TOP of the function before any mutation:

```lua
local saved_surface_contents = {}
if obj.surfaces then
    for sname, zone in pairs(obj.surfaces) do
        saved_surface_contents[sname] = zone.contents or {}
    end
end
-- THEN do cleanup and apply new state
```

### 2. Engine-only fields

`on_tick` and `terminal` exist in the FSM definition but are NEVER applied to the object. The engine reads them from the definition, not from the object. This keeps the object clean.

### 3. on_tick returns data, doesn't mutate state

```lua
on_tick = function(obj)
    obj.burn_remaining = obj.burn_remaining - 1  -- OK: mutate counters
    if obj.burn_remaining <= 0 then
        return { trigger = "duration_expired" }   -- engine handles transition
    end
end
```

### 4. Backward compatibility

Objects without `_fsm_id` are invisible to the FSM engine. Old mutation system continues to work. Migration is gradual — convert objects one at a time.

### 5. Avoid double-ticking

If you have an existing tick system (like `tick_burnable` for candles), add a guard:
```lua
if obj._fsm_id then return end  -- FSM handles its own tick
```

## When to Use

- Object has 2+ states with different properties (descriptions, capabilities, accessibility)
- States have transitions triggered by verbs or time/duration
- Consumable objects with burn/use counters
- Container objects with accessibility gates (open/closed)

## When NOT to Use

- Single-state objects (bed, pillow, knife) — no benefit
- Dynamic mutations where the new object is generated at runtime (WRITE text on paper)
- Objects where the mutation creates a fundamentally different thing (breaking a mirror)
