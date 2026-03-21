-- engine/fsm/init.lua
-- Table-driven FSM engine for object state management.
-- Objects with inline `states` and `_state` fields are managed by this system.
-- FSM definitions live INSIDE the object file (one file = one object = one FSM).
-- Non-FSM objects are unaffected (backward compatible).

local fsm = {}

-- Material registry (lazy-loaded on first threshold check)
local _materials
local function get_materials()
    if _materials then return _materials end
    local ok, mod = pcall(require, "engine.materials")
    if ok then _materials = mod end
    return _materials
end

-- Active timed events: keyed by object ID
-- Each entry: { state, remaining, event, to_state }
fsm.active_timers = {}

-- Paused timers for objects in unloaded rooms
fsm.paused_timers = {}

-- Check if an object has inline FSM data.
-- Returns the object itself as the definition, or nil.
function fsm.load(obj)
    if type(obj) == "table" and obj.states then
        return obj
    end
    return nil
end

-- Apply transition-level mutations to an object instance.
-- Supports: direct values, functions (computed from current), and list ops (add/remove).
local function apply_mutations(obj, mutations)
    if not mutations then return end
    for k, v in pairs(mutations) do
        if type(v) == "function" then
            obj[k] = v(obj[k])
        elseif type(v) == "table" and (v.add ~= nil or v.remove ~= nil) then
            local list = obj[k]
            if type(list) ~= "table" then list = {}; obj[k] = list end
            if v.remove then
                for i = #list, 1, -1 do
                    if list[i] == v.remove then table.remove(list, i) end
                end
            end
            if v.add then
                local found = false
                for _, item in ipairs(list) do
                    if item == v.add then found = true; break end
                end
                if not found then list[#list + 1] = v.add end
            end
        else
            obj[k] = v
        end
    end
end

-- Apply state properties to an object, preserving containment and identity.
-- Removes old state-specific keys, then applies new state properties.
-- Base properties (not defined in any state) persist untouched.
local function apply_state(obj, new_state_name, old_state_name)
    local new_state = obj.states[new_state_name]
    if not new_state then return false end

    -- Save containment data BEFORE cleanup (surfaces, contents, location)
    local saved_surface_contents = {}
    if obj.surfaces then
        for sname, zone in pairs(obj.surfaces) do
            saved_surface_contents[sname] = zone.contents or {}
        end
    end
    local saved_contents = obj.contents
    local saved_location = obj.location

    -- Remove old state-specific keys (skip engine-only keys)
    if old_state_name and obj.states[old_state_name] then
        for k in pairs(obj.states[old_state_name]) do
            if k ~= "on_tick" and k ~= "terminal" then
                obj[k] = nil
            end
        end
    end

    -- Apply new state properties
    for k, v in pairs(new_state) do
        if k == "on_tick" or k == "terminal" then
            -- Engine-only: not applied to the object
        elseif k == "surfaces" then
            -- Rebuild surfaces with new structure but preserved contents
            obj.surfaces = {}
            for sname, zone in pairs(v) do
                obj.surfaces[sname] = {}
                for zk, zv in pairs(zone) do
                    if zk ~= "contents" then
                        obj.surfaces[sname][zk] = zv
                    end
                end
                obj.surfaces[sname].contents = saved_surface_contents[sname] or {}
            end
        else
            obj[k] = v
        end
    end

    -- Restore containment
    obj.location = saved_location
    if saved_contents and not obj.surfaces then
        obj.contents = saved_contents
    end
    obj._state = new_state_name
    return true
end

-- Return available (non-auto) transitions from the object's current state.
function fsm.get_transitions(obj)
    if not obj or not obj.states or not obj._state then return {} end
    local result = {}
    for _, t in ipairs(obj.transitions or {}) do
        if t.from == obj._state and t.trigger ~= "auto" then
            result[#result + 1] = t
        end
    end
    return result
end

-- Transition an object to target_state. Returns transition table on success,
-- or nil + error code on failure. Optional context table for guard checks.
-- verb_hint narrows transition search when multiple transitions share a target.
function fsm.transition(registry, obj_id, target_state, context, verb_hint)
    local obj = registry:get(obj_id)
    if not obj or not obj.states or not obj._state then
        return nil, "not_fsm"
    end

    local cur = obj.states[obj._state]
    if cur and cur.terminal then return nil, "terminal" end

    -- Find a matching transition (prefer verb_hint when given)
    local trans
    for _, t in ipairs(obj.transitions or {}) do
        if t.from == obj._state and t.to == target_state and t.trigger ~= "auto" then
            if not verb_hint or t.verb == verb_hint then
                trans = t
                break
            end
            -- Also check aliases for verb_hint
            if verb_hint and t.aliases then
                for _, a in ipairs(t.aliases) do
                    if a == verb_hint then trans = t; break end
                end
                if trans then break end
            end
        end
    end
    -- Fallback: if verb_hint didn't match, pick the first available transition
    if not trans then
        for _, t in ipairs(obj.transitions or {}) do
            if t.from == obj._state and t.to == target_state and t.trigger ~= "auto" then
                trans = t
                break
            end
        end
    end
    if not trans then return nil, "no_transition" end

    -- Guard: requires_property on context.target
    if trans.requires_property then
        local target = context and context.target
        if not target or not target[trans.requires_property] then
            return nil, "requires_property", trans
        end
    end

    -- Guard: custom function
    if trans.guard and not trans.guard(obj, context) then
        return nil, "guard_failed", trans
    end

    local old_state = obj._state
    -- Stop timer for the old state (extinguish, etc.)
    fsm.stop_timer(obj_id)
    apply_state(obj, target_state, old_state)
    apply_mutations(obj, trans.mutate)
    if trans.on_transition then trans.on_transition(obj, context) end
    -- Start timer for the new state if it has timed_events
    fsm.start_timer(registry, obj_id)
    return trans
end

-- Check property thresholds for auto-transitions.
-- Thresholds are declarative: { property = "temperature", above = 62, transition = "melting" }
-- The property is checked against env_context values.
-- Optional: above_material / below_material resolves the limit from the object's material.
-- Returns a message string if a threshold transition fires, nil otherwise.
local function check_thresholds(registry, obj, obj_id, env_context)
    if not obj.thresholds or not env_context then return nil end

    local mat = nil
    if obj.material then
        local mats = get_materials()
        if mats then mat = mats.get(obj.material) end
    end

    for _, threshold in ipairs(obj.thresholds) do
        local env_value = env_context[threshold.property]
        if env_value ~= nil then
            local crossed = false

            -- Direct numeric threshold: above / below
            if threshold.above and env_value > threshold.above then
                crossed = true
            elseif threshold.below and env_value < threshold.below then
                crossed = true
            end

            -- Material-referenced threshold: above_material / below_material
            if not crossed and mat then
                if threshold.above_material then
                    local limit = mat[threshold.above_material]
                    if limit and env_value > limit then crossed = true end
                elseif threshold.below_material then
                    local limit = mat[threshold.below_material]
                    if limit and env_value < limit then crossed = true end
                end
            end

            if crossed and threshold.transition then
                -- Find a matching transition from current state to the threshold target
                for _, t in ipairs(obj.transitions or {}) do
                    if t.from == obj._state and t.to == threshold.transition then
                        local old_state = obj._state
                        fsm.stop_timer(obj_id)
                        apply_state(obj, t.to, old_state)
                        apply_mutations(obj, t.mutate)
                        if t.on_transition then t.on_transition(obj, env_context) end
                        fsm.start_timer(registry, obj_id)
                        return t.message or threshold.message
                    end
                end
            end
        end
    end
    return nil
end

-- Process auto-transitions (burn countdown, duration expiry, threshold checks).
-- Returns a message string if a transition or warning fired, nil otherwise.
-- Optional env_context: room environmental state for threshold checking.
function fsm.tick(registry, obj_id, env_context)
    local obj = registry:get(obj_id)
    if not obj or not obj.states or not obj._state then return nil end

    -- Step 1: existing on_tick callback (legacy burn countdown, etc.)
    local state = obj.states[obj._state]
    if state and state.on_tick then
        local result = state.on_tick(obj)
        if result then
            if result.warning then return result.warning end
            if result.trigger then
                for _, t in ipairs(obj.transitions or {}) do
                    if t.from == obj._state and t.trigger == "auto"
                       and t.condition == result.trigger then
                        apply_state(obj, t.to, obj._state)
                        apply_mutations(obj, t.mutate)
                        return t.message
                    end
                end
            end
        end
    end

    -- Step 2: threshold checking (material property-based auto-transitions)
    local threshold_msg = check_thresholds(registry, obj, obj_id, env_context)
    if threshold_msg then return threshold_msg end

    return nil
end

-- Start a timed event for an object if its current state has timed_events.
-- Uses remaining_burn for candle-style partial timers, otherwise the delay from metadata.
function fsm.start_timer(registry, obj_id)
    local obj = registry:get(obj_id)
    if not obj or not obj.states or not obj._state then return end

    local state = obj.states[obj._state]
    if not state or not state.timed_events then return end

    local te = state.timed_events[1]  -- first timed event
    if not te then return end

    -- Use remaining_burn if the object tracks partial burn (candle pattern)
    local delay = te.delay
    if obj.remaining_burn and obj.remaining_burn > 0 then
        delay = obj.remaining_burn
    end

    fsm.active_timers[obj_id] = {
        state = obj._state,
        remaining = delay,
        event = te.event,
        to_state = te.to_state,
    }
end

-- Stop/remove the timer for an object (e.g., on extinguish or room unload).
function fsm.stop_timer(obj_id)
    fsm.active_timers[obj_id] = nil
end

-- Pause a timer, preserving remaining time for later resume.
function fsm.pause_timer(obj_id)
    local timer = fsm.active_timers[obj_id]
    if timer then
        fsm.paused_timers[obj_id] = timer
        fsm.active_timers[obj_id] = nil
    end
end

-- Resume a paused timer.
function fsm.resume_timer(obj_id)
    local timer = fsm.paused_timers[obj_id]
    if timer then
        fsm.active_timers[obj_id] = timer
        fsm.paused_timers[obj_id] = nil
    end
end

-- Scan all objects in a room and start timers for any with timed_events.
-- Called on room load.
function fsm.scan_room_timers(registry, room)
    if not room or not room.contents then return end
    for _, obj_id in ipairs(room.contents) do
        -- Resume paused timer if available, otherwise start fresh
        if fsm.paused_timers[obj_id] then
            fsm.resume_timer(obj_id)
        else
            fsm.start_timer(registry, obj_id)
        end
        -- Also check surface/container contents
        local obj = registry:get(obj_id)
        if obj and obj.surfaces then
            for _, zone in pairs(obj.surfaces) do
                for _, item_id in ipairs(zone.contents or {}) do
                    if fsm.paused_timers[item_id] then
                        fsm.resume_timer(item_id)
                    else
                        fsm.start_timer(registry, item_id)
                    end
                end
            end
        end
        if obj and obj.contents then
            for _, item_id in ipairs(obj.contents) do
                if fsm.paused_timers[item_id] then
                    fsm.resume_timer(item_id)
                else
                    fsm.start_timer(registry, item_id)
                end
            end
        end
    end
end

-- Pause all timers for objects in a room. Called on room unload.
function fsm.pause_room_timers(room)
    if not room or not room.contents then return end
    for _, obj_id in ipairs(room.contents) do
        fsm.pause_timer(obj_id)
    end
end

-- Tick all active timers by delta_seconds.
-- Fires auto-transitions when timers expire.
-- Returns a list of { obj_id, message } for any transitions that fired.
function fsm.tick_timers(registry, delta_seconds)
    local messages = {}
    local expired = {}
    -- Phase 1: decrement and collect expired timers
    for obj_id, timer in pairs(fsm.active_timers) do
        timer.remaining = timer.remaining - delta_seconds
        if timer.remaining <= 0 then
            expired[#expired + 1] = { id = obj_id, timer = timer }
        else
            -- Update remaining_burn on the object for save/resume fidelity
            local obj = registry:get(obj_id)
            if obj and obj.remaining_burn then
                obj.remaining_burn = timer.remaining
            end
        end
    end
    -- Phase 2: process expired timers (safe to mutate active_timers now)
    for _, entry in ipairs(expired) do
        local obj_id = entry.id
        local timer = entry.timer
        fsm.active_timers[obj_id] = nil
        local obj = registry:get(obj_id)
        if obj and obj._state == timer.state then
            -- Update remaining_burn if object tracks it
            if obj.remaining_burn then
                obj.remaining_burn = 0
            end
            -- Fire the auto-transition
            for _, t in ipairs(obj.transitions or {}) do
                if t.from == timer.state and t.trigger == "auto"
                   and t.condition == "timer_expired" then
                    apply_state(obj, t.to, timer.state)
                    apply_mutations(obj, t.mutate)
                    if t.message then
                        messages[#messages + 1] = { obj_id = obj_id, message = t.message }
                    end
                    break
                end
            end
            -- Start new timer if the new state also has timed_events (cyclic clocks)
            fsm.start_timer(registry, obj_id)
        end
    end
    return messages
end

return fsm
