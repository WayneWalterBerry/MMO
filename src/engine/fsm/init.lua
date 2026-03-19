-- engine/fsm/init.lua
-- Table-driven FSM engine for object state management.
-- Objects with _fsm_id and _state fields are managed by this system.
-- Non-FSM objects are unaffected (backward compatible).

local fsm = {}
local _cache = {}

-- Load an FSM definition by id (e.g., "match" loads meta.fsms.match)
function fsm.load(fsm_id)
    if _cache[fsm_id] then return _cache[fsm_id] end
    local ok, def = pcall(require, "meta.fsms." .. fsm_id)
    if ok and def then
        _cache[fsm_id] = def
        return def
    end
    return nil
end

-- Apply state properties to an object, preserving containment and identity.
-- Removes old state-specific keys, applies shared, then applies new state.
local function apply_state(obj, def, new_state_name, old_state_name)
    local new_state = def.states[new_state_name]
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

    -- Remove old state-specific keys (skip engine-only and shared keys)
    if old_state_name and def.states[old_state_name] then
        for k in pairs(def.states[old_state_name]) do
            if k ~= "on_tick" and k ~= "terminal"
               and (not def.shared or def.shared[k] == nil) then
                obj[k] = nil
            end
        end
    end

    -- Apply shared properties
    for k, v in pairs(def.shared or {}) do
        obj[k] = v
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
    if not obj or not obj._fsm_id or not obj._state then return {} end
    local def = fsm.load(obj._fsm_id)
    if not def then return {} end
    local result = {}
    for _, t in ipairs(def.transitions or {}) do
        if t.from == obj._state and t.trigger ~= "auto" then
            result[#result + 1] = t
        end
    end
    return result
end

-- Transition an object to target_state. Returns transition table on success,
-- or nil + error code on failure. Optional context table for guard checks.
function fsm.transition(registry, obj_id, target_state, context)
    local obj = registry:get(obj_id)
    if not obj or not obj._fsm_id or not obj._state then
        return nil, "not_fsm"
    end
    local def = fsm.load(obj._fsm_id)
    if not def then return nil, "no_definition" end

    local cur = def.states[obj._state]
    if cur and cur.terminal then return nil, "terminal" end

    -- Find a matching transition
    local trans
    for _, t in ipairs(def.transitions or {}) do
        if t.from == obj._state and t.to == target_state and t.trigger ~= "auto" then
            trans = t
            break
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
    apply_state(obj, def, target_state, old_state)
    if trans.on_transition then trans.on_transition(obj, context) end
    return trans
end

-- Process auto-transitions (burn countdown, duration expiry).
-- Returns a message string if a transition or warning fired, nil otherwise.
function fsm.tick(registry, obj_id)
    local obj = registry:get(obj_id)
    if not obj or not obj._fsm_id or not obj._state then return nil end
    local def = fsm.load(obj._fsm_id)
    if not def then return nil end

    local state = def.states[obj._state]
    if not state or not state.on_tick then return nil end

    local result = state.on_tick(obj)
    if not result then return nil end

    -- Warning (non-transition message)
    if result.warning then return result.warning end

    -- Auto-transition trigger
    if result.trigger then
        for _, t in ipairs(def.transitions or {}) do
            if t.from == obj._state and t.trigger == "auto"
               and t.condition == result.trigger then
                apply_state(obj, def, t.to, obj._state)
                return t.message
            end
        end
    end
    return nil
end

return fsm
