-- engine/creatures/territorial.lua
-- Territory marking system: place markers, BFS radius detection, response dispatch.
-- Phase 4 WAVE-5. Q5 resolved: player detects markers via SMELL only.
-- territory-marker.lua object created by Flanders; this engine reads from it.
--
-- Ownership: Bart (Architecture Lead)

local M = {}

local navigation = require("engine.creatures.navigation")

---------------------------------------------------------------------------
-- Helpers: extract owner and radius from a marker (handles both formats)
-- Flanders' territory-marker.lua uses top-level owner/radius fields.
-- Test mocks may use territory.owner/territory.radius subtable.
---------------------------------------------------------------------------
local function marker_owner(marker)
    if marker.territory and marker.territory.owner then
        return marker.territory.owner
    end
    return marker.owner or marker.creator
end

local function marker_radius(marker)
    if marker.territory and marker.territory.radius then
        return marker.territory.radius
    end
    return marker.radius or 2
end

---------------------------------------------------------------------------
-- is_marker(obj) -> bool
-- Identifies territory markers by id or structural presence.
---------------------------------------------------------------------------
local function is_marker(obj)
    if obj.id == "territory-marker" then return true end
    if type(obj.id) == "string" and obj.id:find("^territory%-marker") then return true end
    if obj.territory then return true end
    return false
end
local function get_room(context, room_id)
    if context.rooms and context.rooms[room_id] then
        return context.rooms[room_id]
    end
    local reg = context.registry
    if type(reg.get_room) == "function" then return reg:get_room(room_id) end
    if type(reg.get) == "function" then
        local obj = reg:get(room_id)
        if obj then return obj end
    end
    return nil
end

local function list_objects(registry)
    if type(registry.list) == "function" then return registry:list() end
    if type(registry.all) == "function" then return registry:all() end
    if registry._objects then
        local result = {}
        for _, obj in pairs(registry._objects) do result[#result + 1] = obj end
        return result
    end
    return {}
end

---------------------------------------------------------------------------
-- mark_territory(creature, ctx) -> marker or nil
-- Places an invisible territory-marker object in the creature's room.
---------------------------------------------------------------------------
function M.mark_territory(creature, ctx)
    if not creature or not ctx or not ctx.registry then return nil end
    local loc = creature.location
    if not loc then return nil end

    -- Each marker gets a unique id so multiple markers coexist in the registry
    local uid = (creature.guid or creature.id) .. "-mark-" .. tostring(os.time()) .. "-" .. tostring(math.random(1000, 9999))
    local marker = {
        id = "territory-marker-" .. uid,
        guid = uid,
        template = "small-item",
        name = "a territorial scent mark",
        keywords = { "scent", "mark", "territory marker" },
        material = "organic",
        portable = false,
        visible = false,
        hidden = true,
        invisible = true,
        searchable = false,
        on_feel = "You feel nothing unusual.",
        on_smell = "A musky, animal scent lingers here.",
        on_look = nil,
        description = nil,
        location = loc,
        -- Top-level fields (Flanders format)
        owner = creature.guid,
        creator = creature.guid,
        radius = (creature.behavior and creature.behavior.mark_radius) or 2,
        timestamp = ctx.game_time or os.time(),
        -- Subtable format (test compatibility)
        territory = {
            owner = creature.guid,
            radius = (creature.behavior and creature.behavior.mark_radius) or 2,
            timestamp = ctx.game_time or os.time(),
        },
    }

    -- Register in registry under unique id
    local reg = ctx.registry
    if type(reg.register) == "function" then
        reg:register(marker.id, marker)
    elseif type(reg.add) == "function" then
        reg:add(marker)
    elseif reg._objects then
        reg._objects[marker.guid] = marker
    end

    -- Add to room contents using the registration id (matches reg:get key)
    local room = get_room(ctx, loc)
    if room then
        room.contents = room.contents or {}
        room.contents[#room.contents + 1] = marker.id
    end

    return marker
end

---------------------------------------------------------------------------
-- get_territory_rooms(marker, ctx) -> array of room_id
-- BFS from marker location, up to marker.territory.radius hops.
---------------------------------------------------------------------------
function M.get_territory_rooms(marker, ctx)
    if not marker or not ctx then return {} end

    local start_room = marker.location
    if not start_room then return {} end
    local radius = marker_radius(marker)

    local visited = { [start_room] = true }
    local frontier = { start_room }
    local result = { start_room }
    local depth = 0

    while #frontier > 0 and depth < radius do
        depth = depth + 1
        local next_frontier = {}
        for _, rid in ipairs(frontier) do
            local room = get_room(ctx, rid)
            if room and room.exits then
                for _, exit in pairs(room.exits) do
                    local target = navigation.get_exit_target(ctx, exit)
                    if target and not visited[target] then
                        visited[target] = true
                        next_frontier[#next_frontier + 1] = target
                        result[#result + 1] = target
                    end
                end
            end
        end
        frontier = next_frontier
    end

    return result
end

---------------------------------------------------------------------------
-- is_in_territory(creature, room_id, ctx) -> bool
-- Checks whether room_id falls within any territory marker owned by creature.
---------------------------------------------------------------------------
function M.is_in_territory(creature, room_id, ctx)
    if not creature or not room_id or not ctx or not ctx.registry then return false end

    for _, obj in ipairs(list_objects(ctx.registry)) do
        if is_marker(obj) and marker_owner(obj) == creature.guid then
            local rooms = M.get_territory_rooms(obj, ctx)
            for _, rid in ipairs(rooms) do
                if rid == room_id then return true end
            end
        end
    end
    return false
end

---------------------------------------------------------------------------
-- evaluate_marker(creature, marker, ctx) -> response string or table
-- Determines creature's response to an encountered territory marker.
-- Own marker → "patrol"; foreign + high aggression → "challenge"; foreign + low → "avoid"
---------------------------------------------------------------------------
function M.evaluate_marker(creature, marker, ctx)
    if not creature or not marker then return "ignore" end

    local owner = marker_owner(marker)
    if not owner then return "ignore" end

    -- Own marker: patrol / defend
    if owner == creature.guid then
        return "patrol"
    end

    -- Foreign marker: response based on aggression
    local behavior = creature.behavior or {}
    local aggression = behavior.aggression or 0
    -- Normalize: if > 1, treat as 0-100 scale
    local aggro_normalized = aggression > 1 and (aggression / 100) or aggression

    if aggro_normalized > 0.7 then
        return "challenge"
    else
        return "avoid"
    end
end

---------------------------------------------------------------------------
-- find_markers_in_room(registry, room_id) -> array of marker objects
-- Finds all territory-marker objects in a given room.
---------------------------------------------------------------------------
function M.find_markers_in_room(registry, room_id)
    if not registry or not room_id then return {} end
    local markers = {}
    for _, obj in ipairs(list_objects(registry)) do
        if is_marker(obj) and obj.location == room_id then
            markers[#markers + 1] = obj
        end
    end
    return markers
end

---------------------------------------------------------------------------
-- expire_markers(ctx, duration_hours)
-- Removes territory markers whose timestamp is older than duration_hours.
-- duration_hours: max age in game hours (e.g. 24 for "1 day").
-- ctx must have .registry and .game_time (current game hours).
---------------------------------------------------------------------------
function M.expire_markers(ctx, duration_hours)
    if not ctx or not ctx.registry or not duration_hours then return end
    local now = ctx.game_time or 0
    local to_remove = {}

    for _, obj in ipairs(list_objects(ctx.registry)) do
        if is_marker(obj) then
            local ts = (obj.territory and obj.territory.timestamp) or obj.timestamp
            if ts and (now - ts) >= duration_hours then
                to_remove[#to_remove + 1] = obj
            end
        end
    end

    for _, marker in ipairs(to_remove) do
        -- Remove from registry using both id and guid to handle all marker formats
        local reg = ctx.registry
        if type(reg.remove) == "function" then
            reg:remove(marker.id)
            if marker.guid and marker.guid ~= marker.id then
                if type(reg.get) == "function" and reg:get(marker.guid) then
                    reg:remove(marker.guid)
                end
            end
        elseif reg._objects then
            reg._objects[marker.id] = nil
            if marker.guid then reg._objects[marker.guid] = nil end
        end

        -- Remove from room contents (by id or guid, matching how it was added)
        if marker.location then
            local room = get_room(ctx, marker.location)
            if room and room.contents then
                for i = #room.contents, 1, -1 do
                    if room.contents[i] == marker.id or room.contents[i] == marker.guid then
                        table.remove(room.contents, i)
                    end
                end
            end
        end
    end
end

return M
