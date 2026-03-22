-- engine/search/traverse.lua
-- Walk algorithm: proximity ordering, step-by-step traversal.
--
-- Ownership: Bart (Architect)

local traverse = {}

local containers = require("engine.search.containers")
local narrator = require("engine.search.narrator")
local goals = require("engine.search.goals")

---------------------------------------------------------------------------
-- Build search queue from room proximity list
---------------------------------------------------------------------------

--- Get proximity-ordered list for a room
-- @param room room object
-- @return ordered list of object IDs
function traverse.get_proximity_list(room)
    if room.proximity_list then
        return room.proximity_list
    end
    
    -- Fallback: use room contents in definition order
    if room.contents then
        return room.contents
    end
    
    return {}
end

--- Expand an object into searchable surfaces and containers
-- @param object_id string
-- @param registry registry instance
-- @param depth number (current nesting depth)
-- @param include_nested_containers boolean (true when scope search)
-- @return list of queue entries
local function expand_object(object_id, registry, depth, include_nested_containers)
    depth = depth or 0
    include_nested_containers = include_nested_containers or false
    
    -- Prevent infinite recursion
    if depth > 5 then
        return {}
    end
    
    local obj = registry:get(object_id)
    if not obj then
        return {}
    end
    
    local entries = {}
    
    -- Add the object itself as a searchable entry
    entries[#entries + 1] = {
        object_id = object_id,
        type = "object",
        depth = depth,
        parent_id = nil,
        is_container = containers.is_container(obj),
        is_locked = containers.is_locked(obj),
        is_open = containers.is_open(obj),
        surface_name = nil,
    }
    
    -- Expand surfaces first (if object has surfaces)
    if obj.surfaces then
        for surface_name, surface_data in pairs(obj.surfaces) do
            -- Skip if surface_data is just a list (treat as contents)
            if type(surface_data) == "table" and surface_data.contents then
                entries[#entries + 1] = {
                    object_id = object_id .. "_" .. surface_name,
                    type = "surface",
                    depth = depth,
                    parent_id = object_id,
                    is_container = false,
                    is_locked = false,
                    is_open = true,
                    surface_name = surface_name,
                }
            end
        end
    end
    
    -- BUG-075: Then expand nested containers (recursive) when doing a scoped search
    if include_nested_containers and containers.is_container(obj) then
        -- Get the sub-containers (e.g., drawers inside nightstand)
        local contents = containers.get_contents(obj, registry)
        for _, child_id in ipairs(contents) do
            local child = registry:get(child_id)
            if child and containers.is_container(child) then
                -- Recursively expand nested containers
                local child_entries = expand_object(child_id, registry, depth + 1, include_nested_containers)
                for _, child_entry in ipairs(child_entries) do
                    entries[#entries + 1] = child_entry
                end
            end
        end
    end
    
    return entries
end

--- Build a search queue from room proximity list
-- @param room room object
-- @param scope object ID or nil
-- @param target search target or nil
-- @param registry registry instance
-- @return ordered list of queue entries
function traverse.build_queue(room, scope, target, registry)
    local queue = {}
    
    -- Get proximity-ordered object list
    local proximity_list = traverse.get_proximity_list(room)
    
    -- If scope provided, filter to just that object
    local search_list = proximity_list
    local include_nested_containers = false
    if scope then
        search_list = {}
        for _, obj_id in ipairs(proximity_list) do
            if obj_id == scope then
                search_list[#search_list + 1] = obj_id
                -- BUG-075: When searching a specific object, include nested containers
                include_nested_containers = true
                break
            end
        end
    end
    
    -- Expand each object into searchable entries
    for _, obj_id in ipairs(search_list) do
        local entries = expand_object(obj_id, registry, 0, include_nested_containers)
        for _, entry in ipairs(entries) do
            queue[#queue + 1] = entry
        end
    end
    
    return queue
end

---------------------------------------------------------------------------
-- Process one step of traversal
---------------------------------------------------------------------------

--- Check if object matches target (fuzzy matching)
-- @param object object instance
-- @param target string
-- @param registry registry instance
-- @param depth number (recursion depth tracking)
-- @return boolean
local function matches_target(object, target, registry, depth)
    depth = depth or 0
    
    -- BUG-076, BUG-077: Prevent infinite recursion with depth limit
    if depth > 3 then
        return false
    end
    
    if not object or not target then
        return false
    end
    
    target = target:lower()
    
    -- Exact ID match
    if object.id and object.id:lower() == target then
        return true
    end
    
    -- Exact name match
    if object.name and object.name:lower() == target then
        return true
    end
    
    -- Substring match in name
    if object.name and object.name:lower():find(target, 1, true) then
        return true
    end
    
    -- Keyword match
    if object.keywords then
        for _, kw in ipairs(object.keywords) do
            if kw:lower() == target or kw:lower():find(target, 1, true) then
                return true
            end
        end
    end
    
    -- If object is container, check contents recursively (fuzzy)
    if containers.is_container(object) and containers.is_open(object) then
        local contents = containers.get_contents(object, registry)
        for _, child_id in ipairs(contents) do
            local child = registry:get(child_id)
            if child and matches_target(child, target, registry, depth + 1) then
                return true
            end
        end
    end
    
    return false
end

--- Process one step of traversal
-- @param ctx game context
-- @param entry queue entry
-- @param target what we're looking for
-- @param is_goal_search boolean
-- @param goal_type string
-- @param goal_value string
-- @return result table {found: boolean, item: object or nil, continue: boolean, narrative: string}
function traverse.step(ctx, entry, target, is_goal_search, goal_type, goal_value)
    local registry = ctx.registry
    local room = ctx.current_room
    
    local result = {
        found = false,
        item = nil,
        continue = true,
        narrative = "",
    }
    
    -- Get the object
    local obj = registry:get(entry.object_id)
    if not obj then
        result.narrative = ""
        return result
    end
    
    -- If it's a container and it's closed, try to open it
    if entry.is_container and not entry.is_open then
        if entry.is_locked then
            -- Locked - skip with note
            result.narrative = narrator.container_locked(ctx, obj)
            return result
        else
            -- Unlocked - auto-open
            local open_result = containers.open(ctx, obj)
            if open_result.success then
                result.narrative = narrator.container_open(ctx, obj)
                -- After opening, check contents
                local contents = containers.get_contents(obj, registry)
                for _, child_id in ipairs(contents) do
                    local child = registry:get(child_id)
                    if child then
                        -- Check if child matches target
                        if target and not is_goal_search then
                            if matches_target(child, target, registry, 0) then
                                result.found = true
                                result.item = child
                                result.narrative = result.narrative .. "\n" .. narrator.found_target(ctx, child, obj)
                                return result
                            end
                        elseif is_goal_search and goal_type and goal_value then
                            if goals.matches_goal(child, goal_type, goal_value, registry) then
                                result.found = true
                                result.item = child
                                result.narrative = result.narrative .. "\n" .. narrator.found_target(ctx, child, obj)
                                return result
                            end
                        end
                    end
                end
                -- If we get here, container was opened but target not found inside
                return result
            else
                result.narrative = open_result.narrative or ""
                return result
            end
        end
    end
    
    -- Check if this object matches the target
    if target and not is_goal_search then
        if matches_target(obj, target, registry, 0) then
            result.found = true
            result.item = obj
            result.narrative = narrator.found_target(ctx, obj, nil)
            return result
        end
    elseif is_goal_search and goal_type and goal_value then
        if goals.matches_goal(obj, goal_type, goal_value, registry) then
            result.found = true
            result.item = obj
            result.narrative = narrator.found_target(ctx, obj, nil)
            return result
        end
    end
    
    -- Not found - generate step narrative
    result.narrative = narrator.step_narrative(ctx, obj, false)
    return result
end

return traverse
