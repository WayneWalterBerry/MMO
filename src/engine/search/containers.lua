-- engine/search/containers.lua
-- Container interaction during search: detection, opening, locking.
-- Reuses existing container logic, thin wrapper.
--
-- Ownership: Bart (Architect)

local containers = {}

---------------------------------------------------------------------------
-- Container detection and state checks
---------------------------------------------------------------------------

--- Check if object is a container
-- @param object object instance
-- @return boolean
function containers.is_container(object)
    if not object then return false end
    if object.is_container == true or object.container == true then
        return true
    end
    -- BUG-125 (#33): Also check the categories array for "container"
    if object.categories then
        for _, cat in ipairs(object.categories) do
            if cat == "container" then return true end
        end
    end
    return false
end

--- Check if container is locked
-- @param object object instance
-- @return boolean
function containers.is_locked(object)
    if not object then return false end
    return object.is_locked == true or object.locked == true
end

--- Check if container is open
-- @param object object instance
-- @return boolean
function containers.is_open(object)
    if not object then return false end
    -- Default to open if not explicitly closed
    if object.is_open ~= nil then
        return object.is_open
    end
    if object.open ~= nil then
        return object.open
    end
    -- For containers, default to closed unless specified
    if containers.is_container(object) then
        return false
    end
    return true
end

--- Check if container can be auto-opened during search
-- @param object object instance
-- @return boolean
function containers.can_auto_open(object)
    if not containers.is_container(object) then
        return false
    end
    if containers.is_locked(object) then
        return false
    end
    if containers.is_open(object) then
        return false  -- Already open
    end
    return true
end

---------------------------------------------------------------------------
-- Container manipulation
---------------------------------------------------------------------------

--- Open a container (if unlocked)
-- @param ctx game context
-- @param object object instance
-- @return {success: boolean, narrative: string}
function containers.open(ctx, object)
    if containers.is_locked(object) then
        return {
            success = false,
            narrative = "It's locked."
        }
    end
    
    if containers.is_open(object) then
        return {
            success = false,
            narrative = "It's already open."
        }
    end
    
    -- Open it
    object.is_open = true
    object.open = true
    object.accessible = true
    
    -- Apply FSM transition if available
    local fsm_ok, fsm_mod = pcall(require, "engine.fsm")
    if fsm_ok and fsm_mod and object._state and ctx.registry then
        local trans, err = fsm_mod.transition(ctx.registry, object.id, "open", nil, "open")
        if not trans and object.states and object.states.open then
            -- Manual state transition (no matching FSM transition found)
            fsm_mod.stop_timer(object.id)
            object._state = "open"
            fsm_mod.start_timer(ctx.registry, object.id)
        end
    end
    
    return {
        success = true,
        narrative = ""  -- Narrator will generate the message
    }
end

--- Get container contents
-- @param object object instance
-- @param registry registry instance
-- @return list of object IDs
function containers.get_contents(object, registry)
    if not object then return {} end
    
    local contents = {}
    
    -- Check various content fields
    if object.contents then
        if type(object.contents) == "table" then
            for _, item_id in ipairs(object.contents) do
                contents[#contents + 1] = item_id
            end
        end
    end
    
    if object.contains then
        if type(object.contains) == "table" then
            for _, item_id in ipairs(object.contains) do
                contents[#contents + 1] = item_id
            end
        end
    end
    
    return contents
end

return containers
