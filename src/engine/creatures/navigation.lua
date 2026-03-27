-- engine/creatures/navigation.lua
-- Creature navigation helpers: exit resolution, room distance, movement.
-- Extracted from creatures/init.lua for WAVE-3 (Phase 2).
--
-- Ownership: Bart (Architecture Lead)

local M = {}

---------------------------------------------------------------------------
-- get_exit_target(context, exit) -> target_room_id or nil
---------------------------------------------------------------------------
function M.get_exit_target(context, exit)
    if type(exit) == "string" then exit = { portal = exit } end
    if type(exit) ~= "table" then return nil end
    if exit.target then return exit.target end
    if exit.portal and context.registry then
        local reg = context.registry
        if type(reg.get) == "function" then
            local portal = reg:get(exit.portal)
            if portal and portal.portal then return portal.portal.target end
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- get_room_distance(context, from_id, to_id, get_room_fn) -> number
-- BFS distance between two rooms. Returns 999 if unreachable.
---------------------------------------------------------------------------
function M.get_room_distance(context, from_id, to_id, get_room_fn)
    if from_id == to_id then return 0 end
    local visited = { [from_id] = true }
    local frontier = { from_id }
    local depth = 0
    while #frontier > 0 and depth < 10 do
        depth = depth + 1
        local next_frontier = {}
        for _, rid in ipairs(frontier) do
            local room = get_room_fn(context, rid)
            if room and room.exits then
                for _, exit in pairs(room.exits) do
                    local target_id = M.get_exit_target(context, exit)
                    if target_id and not visited[target_id] then
                        if target_id == to_id then return depth end
                        visited[target_id] = true
                        next_frontier[#next_frontier + 1] = target_id
                    end
                end
            end
        end
        frontier = next_frontier
    end
    return 999
end

---------------------------------------------------------------------------
-- is_exit_passable(context, exit, creature) -> bool, target_room_id
---------------------------------------------------------------------------
function M.is_exit_passable(context, exit, creature)
    if type(exit) == "string" then exit = { portal = exit } end
    if type(exit) ~= "table" then return false, nil end

    if exit.target then
        if exit.open == false then
            if not (creature.movement and creature.movement.can_open_doors) then
                return false, nil
            end
        end
        return true, exit.target
    end

    if exit.portal and context.registry and type(context.registry.get) == "function" then
        local portal = context.registry:get(exit.portal)
        if not portal then return false, nil end
        local state = portal.states and portal.states[portal._state]
        if not state or not state.traversable then
            if not (creature.movement and creature.movement.can_open_doors) then
                return false, nil
            end
        end
        local target = portal.portal and portal.portal.target
        if not target then return false, nil end
        return true, target
    end

    return false, nil
end

---------------------------------------------------------------------------
-- get_valid_exits(context, room_id, creature, get_room_fn) -> exits[]
---------------------------------------------------------------------------
function M.get_valid_exits(context, room_id, creature, get_room_fn)
    local room = get_room_fn(context, room_id)
    if not room or not room.exits then return {} end

    local valid = {}
    for dir, exit in pairs(room.exits) do
        local passable, target = M.is_exit_passable(context, exit, creature)
        if passable and target then
            valid[#valid + 1] = { direction = dir, target = target }
        end
    end
    return valid
end

return M
