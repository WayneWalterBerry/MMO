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
local function expand_object(object_id, registry, depth, include_nested_containers, visited)
    depth = depth or 0
    include_nested_containers = include_nested_containers or false
    visited = visited or {}

    -- Cycle detection: skip objects already expanded in this traversal.
    -- Containment is a tree by design, but a visited set protects against
    -- data bugs (e.g., circular contents references) without magic constants.
    if visited[object_id] then
        return {}
    end
    visited[object_id] = true

    -- Secondary safety belt: max depth 3 matches the data model
    -- (room → furniture → container → item = 3 levels)
    if depth > 3 then
        return {}
    end
    
    local obj = registry:get(object_id)
    if not obj then
        return {}
    end

    -- Spatial visibility: hidden objects are invisible to search (#26)
    if obj.hidden then
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
                local child_entries = expand_object(child_id, registry, depth + 1, include_nested_containers, visited)
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
-- @param part_surface string or nil (#41: restrict to this surface when searching a part)
-- @return ordered list of queue entries
function traverse.build_queue(room, scope, target, registry, part_surface)
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
        -- BUG-082: If scope not found in proximity list, check parts of room objects
        -- This handles sub-components (e.g., "drawer" is a part of nightstand)
        if #search_list == 0 and registry then
            for _, obj_id in ipairs(proximity_list) do
                local obj = registry:get(obj_id)
                if obj and obj.parts then
                    for part_key, part in pairs(obj.parts) do
                        if part.id == scope or part_key == scope then
                            -- Use the parent object but with nested containers enabled
                            search_list[#search_list + 1] = obj_id
                            include_nested_containers = true
                            -- #41: Use the part's surface mapping if not already set
                            if not part_surface and part.surface then
                                part_surface = part.surface
                            end
                            break
                        end
                    end
                    if #search_list > 0 then break end
                end
            end
        end
    end
    
    -- Expand each object into searchable entries
    for _, obj_id in ipairs(search_list) do
        local entries = expand_object(obj_id, registry, 0, include_nested_containers)
        for _, entry in ipairs(entries) do
            -- #41: When part_surface is set, only include that specific surface
            -- and skip the parent object entry and other surfaces
            if part_surface then
                if entry.type == "surface" and entry.surface_name == part_surface then
                    entry.direct_part_search = true
                    queue[#queue + 1] = entry
                end
                -- Skip object entries and non-matching surfaces
            else
                queue[#queue + 1] = entry
            end
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
local function matches_target(object, target, registry, depth, visited)
    depth = depth or 0
    visited = visited or {}
    
    if not object or not target then
        return false
    end

    -- Spatial visibility: hidden objects never match (#26)
    if object.hidden then
        return false
    end

    -- Cycle detection: skip objects already checked in this match walk.
    -- Prevents infinite recursion from circular containment references.
    local oid = object.id
    if oid and visited[oid] then
        return false
    end
    if oid then
        visited[oid] = true
    end

    -- Secondary safety belt: depth limit matches containment model depth
    if depth > 3 then
        return false
    end
    
    target = target:lower()
    -- BUG-081: Strip articles from target before matching
    target = target:gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
    
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
            if child and matches_target(child, target, registry, depth + 1, visited) then
                return true
            end
        end
    end
    
    return false
end

--- Peek inside a matched container for a more specific match (#22)
-- When search finds a container whose name matches the target (e.g., "matchbox"
-- matches "match"), peek inside to see if contents match more directly.
-- Read-only: never mutates state (D-PEEK).
-- @param obj container object that matched the target
-- @param target string search target
-- @param registry registry instance
-- @return child object if a deeper match is found, nil otherwise
local function find_deeper_match(obj, target, registry)
    if not containers.is_container(obj) then return nil end
    local contents = containers.get_contents(obj, registry)
    for _, child_id in ipairs(contents) do
        local child = registry:get(child_id)
        if child and matches_target(child, target, registry, 0) then
            return child
        end
    end
    return nil
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
    
    -- BUG-075: Handle surface entries (e.g., nightstand's "inside" surface = drawer)
    if entry.type == "surface" and entry.parent_id and entry.surface_name then
        local parent = registry:get(entry.parent_id)
        if not parent then
            result.narrative = ""
            return result
        end
        
        -- Get current state's surfaces template (for accessibility check)
        -- But use parent's actual surfaces for contents (where items are)
        local surface_template = parent.surfaces and parent.surfaces[entry.surface_name]
        if parent._state and parent.states and parent.states[parent._state] then
            local state_obj = parent.states[parent._state]
            if state_obj.surfaces and state_obj.surfaces[entry.surface_name] then
                surface_template = state_obj.surfaces[entry.surface_name]
            end
        end
        
        -- Check if surface exists
        if not surface_template then
            result.narrative = ""
            return result
        end
        
        -- If surface is not accessible, peek without changing state (#24)
        if surface_template.accessible == false then
            -- #41: Direct part search (e.g., "search drawer") on closed surface
            -- should tell the player to open it first instead of peeking
            if entry.direct_part_search then
                result.narrative = narrator.part_closed(ctx, entry.surface_name, parent)
                return result
            end

            -- Check if parent is locked (via FSM state or container flag)
            local is_locked = containers.is_locked(parent)
            if is_locked then
                result.narrative = narrator.container_locked(ctx, parent)
                return result
            end

            -- Only peek inside container surfaces (drawers, wardrobes, etc.)
            -- Non-container inaccessible surfaces (e.g., rug's "underneath")
            -- are truly hidden and can't be searched until made accessible (#26)
            if not containers.is_container(parent) then
                result.narrative = ""
                return result
            end
            
            -- Peek at contents without opening (#24: read-only search)
            local actual_surface = parent.surfaces and parent.surfaces[entry.surface_name]
            local contents = actual_surface and actual_surface.contents or {}
            
            -- Undirected search: enumerate contents
            if not target and not is_goal_search then
                if #contents > 0 then
                    local items = {}
                    for _, child_id in ipairs(contents) do
                        local child = registry:get(child_id)
                        if child then
                            items[#items + 1] = child.name or child.id
                        end
                    end
                    result.narrative = narrator.container_contents_no_target(ctx, parent, items, nil)
                else
                    result.narrative = narrator.container_contents_no_target(ctx, parent, {}, nil)
                end
                return result
            end
            
            -- Targeted search: check contents for match, report what's there if not found (#27)
            for _, child_id in ipairs(contents) do
                local child = registry:get(child_id)
                if child then
                    if target and not is_goal_search then
                        if matches_target(child, target, registry, 0) then
                            -- #22: If matched child is a container, peek inside for a more specific match
                            local deeper = find_deeper_match(child, target, registry)
                            if deeper then
                                result.found = true
                                result.item = deeper
                                result.narrative = narrator.container_peek(ctx, parent) .. "\n" .. narrator.container_peek(ctx, child) .. "\n" .. narrator.found_target(ctx, deeper, child)
                            else
                                result.found = true
                                result.item = child
                                result.narrative = narrator.container_peek(ctx, parent) .. "\n" .. narrator.found_target(ctx, child, parent)
                            end
                            return result
                        end
                    elseif is_goal_search and goal_type and goal_value then
                        if goals.matches_goal(child, goal_type, goal_value, registry) then
                            result.found = true
                            result.item = child
                            result.narrative = narrator.container_peek(ctx, parent) .. "\n" .. narrator.found_target(ctx, child, parent)
                            return result
                        end
                    end
                end
            end
            
            -- Target not found inside — report what IS there (#27)
            if target then
                local items = {}
                for _, child_id in ipairs(contents) do
                    local child = registry:get(child_id)
                    if child then
                        items[#items + 1] = child.name or child.id
                    end
                end
                result.narrative = narrator.container_contents_no_target(ctx, parent, items, target)
            end
            return result
        end
        
        -- Now surface is accessible - check its contents
        -- ALWAYS use parent.surfaces for contents (not state template)
        local actual_surface = parent.surfaces and parent.surfaces[entry.surface_name]
        local contents = actual_surface and actual_surface.contents or {}

        -- BUG-079: Undirected scoped search should enumerate surface contents
        if not target and not is_goal_search and #contents > 0 then
            local items = {}
            for _, child_id in ipairs(contents) do
                local child = registry:get(child_id)
                if child then
                    items[#items + 1] = child.name or child.id
                end
            end
            if #items > 0 then
                -- #41: Use part-specific narration for direct drawer searches
                if entry.direct_part_search then
                    result.narrative = narrator.part_contents(ctx, entry.surface_name, parent, items)
                else
                    -- Bug #47: sensory-aware narration for surface contents
                    local sense = "vision"
                    if ctx.current_room and ctx.current_room.light_level
                        and ctx.current_room.light_level <= 0 then
                        sense = "touch"
                    end
                    local find_word = sense == "touch" and "Inside you feel: " or "Inside you find: "
                    result.narrative = (result.narrative ~= "" and result.narrative .. "\n" or "")
                        .. find_word .. table.concat(items, ", ") .. "."
                end
            else
                if entry.direct_part_search then
                    result.narrative = narrator.part_empty(ctx, entry.surface_name, parent)
                end
            end
            return result
        end
        
        -- #41: Direct part search with no contents
        if not target and not is_goal_search and #contents == 0 and entry.direct_part_search then
            result.narrative = narrator.part_empty(ctx, entry.surface_name, parent)
            return result
        end

        for _, child_id in ipairs(contents) do
            local child = registry:get(child_id)
            if child then
                -- Check if child matches target
                if target and not is_goal_search then
                    if matches_target(child, target, registry, 0) then
                        result.found = true
                        result.item = child
                        result.narrative = result.narrative .. "\n" .. narrator.found_target(ctx, child, parent)
                        return result
                    end
                elseif is_goal_search and goal_type and goal_value then
                    if goals.matches_goal(child, goal_type, goal_value, registry) then
                        result.found = true
                        result.item = child
                        result.narrative = result.narrative .. "\n" .. narrator.found_target(ctx, child, parent)
                        return result
                    end
                end
            end
        end
        
        -- BUG-126 (#34): Target not found in accessible surface — report what IS there (#27)
        if target and #contents > 0 then
            local items = {}
            for _, child_id in ipairs(contents) do
                local child = registry:get(child_id)
                if child then
                    items[#items + 1] = child.name or child.id
                end
            end
            if #items > 0 then
                result.narrative = narrator.container_contents_no_target(ctx, parent, items, target)
            end
        end

        -- Surface checked, no match found
        return result
    end
    
    -- Get the object (for non-surface entries)
    local obj = registry:get(entry.object_id)
    if not obj then
        result.narrative = ""
        return result
    end
    
    -- #40: Objects with surfaces have their contents searched via surface entries
    -- in the queue. Skip the object entry to avoid contradictory narration
    -- (e.g., "nothing there" followed by surface entry reporting contents).
    -- For targeted searches, still check if the object itself matches the target.
    if obj.surfaces then
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
        -- No match or undirected — suppress narration; surfaces follow in queue
        result.narrative = ""
        return result
    end

    -- If it's a container and it's closed, peek without opening (#24)
    if entry.is_container and not entry.is_open then
        if entry.is_locked then
            -- Locked - skip with note
            result.narrative = narrator.container_locked(ctx, obj)
            return result
        else
            -- Peek at contents without changing state (#24: read-only search)
            local contents = containers.get_contents(obj, registry)

            -- BUG-079: Undirected scoped search should enumerate container contents
            if not target and not is_goal_search then
                if #contents > 0 then
                    local items = {}
                    for _, child_id in ipairs(contents) do
                        local child = registry:get(child_id)
                        if child then
                            items[#items + 1] = child.name or child.id
                        end
                    end
                    result.narrative = narrator.container_contents_no_target(ctx, obj, items, nil)
                else
                    result.narrative = narrator.container_contents_no_target(ctx, obj, {}, nil)
                end
                return result
            end

            -- Targeted search: check contents, report what's there if not found (#27)
            for _, child_id in ipairs(contents) do
                local child = registry:get(child_id)
                if child then
                    if target and not is_goal_search then
                        if matches_target(child, target, registry, 0) then
                            -- #22: If matched child is a container, peek inside for a more specific match
                            local deeper = find_deeper_match(child, target, registry)
                            if deeper then
                                result.found = true
                                result.item = deeper
                                result.narrative = narrator.container_peek(ctx, obj) .. "\n" .. narrator.container_peek(ctx, child) .. "\n" .. narrator.found_target(ctx, deeper, child)
                            else
                                result.found = true
                                result.item = child
                                result.narrative = narrator.container_peek(ctx, obj) .. "\n" .. narrator.found_target(ctx, child, obj)
                            end
                            return result
                        end
                    elseif is_goal_search and goal_type and goal_value then
                        if goals.matches_goal(child, goal_type, goal_value, registry) then
                            result.found = true
                            result.item = child
                            result.narrative = narrator.container_peek(ctx, obj) .. "\n" .. narrator.found_target(ctx, child, obj)
                            return result
                        end
                    end
                end
            end

            -- Target not found inside — check if the container itself matches (#22)
            if target and not is_goal_search then
                if matches_target(obj, target, registry, 0) then
                    result.found = true
                    result.item = obj
                    result.narrative = narrator.container_peek(ctx, obj) .. "\n" .. narrator.found_target(ctx, obj, nil)
                    return result
                end
            end

            -- Target not found inside or on container — report what IS there (#27)
            if target then
                local items = {}
                for _, child_id in ipairs(contents) do
                    local child = registry:get(child_id)
                    if child then
                        items[#items + 1] = child.name or child.id
                    end
                end
                result.narrative = narrator.container_contents_no_target(ctx, obj, items, target)
            end
            return result
        end
    end
    
    -- #34: Handle open container objects — check contents, report what's inside
    if entry.is_container and entry.is_open then
        local contents = containers.get_contents(obj, registry)
        
        -- Undirected search: enumerate contents
        if not target and not is_goal_search then
            if #contents > 0 then
                local items = {}
                for _, child_id in ipairs(contents) do
                    local child = registry:get(child_id)
                    if child then
                        items[#items + 1] = child.name or child.id
                    end
                end
                result.narrative = narrator.container_contents_no_target(ctx, obj, items, nil)
            else
                result.narrative = narrator.step_narrative(ctx, obj, false)
            end
            return result
        end
        
        -- Targeted search: check contents for match
        for _, child_id in ipairs(contents) do
            local child = registry:get(child_id)
            if child then
                if target and not is_goal_search then
                    if matches_target(child, target, registry, 0) then
                        local deeper = find_deeper_match(child, target, registry)
                        if deeper then
                            result.found = true
                            result.item = deeper
                            result.narrative = narrator.container_peek(ctx, child) .. "\n" .. narrator.found_target(ctx, deeper, child)
                        else
                            result.found = true
                            result.item = child
                            result.narrative = narrator.found_target(ctx, child, obj)
                        end
                        return result
                    end
                elseif is_goal_search and goal_type and goal_value then
                    if goals.matches_goal(child, goal_type, goal_value, registry) then
                        result.found = true
                        result.item = child
                        result.narrative = narrator.found_target(ctx, child, obj)
                        return result
                    end
                end
            end
        end
        
        -- Target not found in contents — check if the container itself matches (#22)
        if target and not is_goal_search then
            if matches_target(obj, target, registry, 0) then
                result.found = true
                result.item = obj
                result.narrative = narrator.found_target(ctx, obj, nil)
                return result
            end
        end

        -- Target not found inside or on container — report what IS there (#34)
        if target and #contents > 0 then
            local items = {}
            for _, child_id in ipairs(contents) do
                local child = registry:get(child_id)
                if child then
                    items[#items + 1] = child.name or child.id
                end
            end
            result.narrative = narrator.container_contents_no_target(ctx, obj, items, target)
        else
            result.narrative = narrator.step_narrative(ctx, obj, false)
        end
        return result
    end
    
    -- Check if this object matches the target
    if target and not is_goal_search then
        if matches_target(obj, target, registry, 0) then
            -- #22: If matched object is a container, peek inside for a more specific match
            local deeper = find_deeper_match(obj, target, registry)
            if deeper then
                result.found = true
                result.item = deeper
                result.narrative = narrator.container_peek(ctx, obj) .. "\n" .. narrator.found_target(ctx, deeper, obj)
            else
                result.found = true
                result.item = obj
                result.narrative = narrator.found_target(ctx, obj, nil)
            end
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
