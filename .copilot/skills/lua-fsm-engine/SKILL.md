# SKILL: Table-Driven FSM Engine in Lua

## What This Solves

Objects that have multiple states (match: unlit/lit/spent, nightstand: closed/open) need declarative state management. The FSM engine provides inline state definitions within each object file with declarative transitions.

## Pattern

### Object File Format (Inline FSM)

```lua
-- src/meta/objects/{object_id}.lua
return {
    -- Base properties (persist across all states, never in state definitions)
    id = "match",
    keywords = {"match", "stick"},
    size = 1, weight = 0.01, portable = true,

    -- Initial state properties (what the object looks like at load time)
    name = "a wooden match",
    description = "An unlit match...",
    casts_light = false,

    -- FSM metadata
    initial_state = "unlit",
    _state = "unlit",

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

-- Check if an object is FSM-managed
local def = fsm.load(obj)  -- returns obj if obj.states exists, nil otherwise

-- Query available transitions for verb handlers
local transitions = fsm.get_transitions(obj)  -- returns non-auto transitions

-- Execute a state transition (returns transition table or nil + error)
local trans, err = fsm.transition(registry, obj_id, "lit", { target = matchbox })

-- Process auto-transitions (call after each command)
local msg = fsm.tick(registry, obj_id)  -- returns message string or nil
```

### Verb Handler Integration Pattern

```lua
if obj.states then
    local transitions = fsm.get_transitions(obj)
    local target_trans
    for _, t in ipairs(transitions) do
        if t.verb == "open" then target_trans = t; break end
        -- Also check aliases
        if t.aliases then
            for _, alias in ipairs(t.aliases) do
                if alias == "open" then target_trans = t; break end
            end
        end
    end
    if target_trans then
        local trans, err = fsm.transition(registry, obj.id, target_trans.to, {})
        if trans then
            print(trans.message)
            if trans.spawns then spawn_objects(ctx, trans.spawns) end
        end
    else
        if obj._state == "open" then print("Already open.") end
    end
    return
end
-- ... fall through to old mutation system
```

## Critical Implementation Details

### 1. State property convention

- **Properties that CHANGE between states** → defined in EVERY state that uses them
- **Properties that NEVER change** → only at top level (base), NEVER in any state definition
- If a state overrides a base property, ALL related states must define it to avoid losing it during transitions

### 2. Save containment BEFORE cleanup

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

### 3. Engine-only fields

`on_tick` and `terminal` exist in the FSM definition but are NEVER applied to the object. The engine reads them from `obj.states[state_name]`, not from `obj` top-level. This keeps the object clean.

### 4. on_tick returns data, doesn't mutate state

```lua
on_tick = function(obj)
    obj.burn_remaining = obj.burn_remaining - 1  -- OK: mutate counters
    if obj.burn_remaining <= 0 then
        return { trigger = "duration_expired" }   -- engine handles transition
    end
end
```

### 5. Backward compatibility

Objects without `states` are invisible to the FSM engine. Old mutation system continues to work. Objects can have BOTH FSM states AND mutations (hybrid model).

### 6. Avoid double-ticking

If you have an existing tick system (like `tick_burnable`), add a guard:
```lua
if obj.states then return end  -- FSM handles its own tick
```

### 7. Transition spawns

FSM transitions can include a `spawns` field. The engine returns the transition table; the verb handler processes spawns:
```lua
if trans.spawns then spawn_objects(ctx, trans.spawns) end
```

## When to Use

- Object has 2+ states with different properties (descriptions, capabilities, accessibility)
- States have transitions triggered by verbs or time/duration
- Consumable objects with burn/use counters
- Container objects with accessibility gates (open/closed)
- Multi-axis states (vanity: drawer × mirror = 4 states)

## When NOT to Use

- Single-state objects (bed, pillow, knife) — no benefit
- Dynamic mutations where the new object is generated at runtime (WRITE text on paper)
- Destructive transformations (use `mutations` alongside FSM instead)
