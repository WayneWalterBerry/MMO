-- engine/creatures/init.lua
-- Creature behavior engine: drives, reactions, utility-scored actions, movement.
-- Evaluates metadata on animate objects generically (Principle 8).
--
-- Ownership: Bart (Architecture Lead)

local M = {}

local stimulus = require("engine.creatures.stimulus")
local predator_prey = require("engine.creatures.predator-prey")

---------------------------------------------------------------------------
-- Registry abstraction: works with both real registry (:list) and test mocks (:all)
---------------------------------------------------------------------------

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

local function get_location(registry, creature)
    if creature.location then return creature.location end
    if type(registry.get_location) == "function" then
        return registry:get_location(creature.guid)
    end
    return nil
end

local function set_location(registry, creature, room_id)
    creature.location = room_id
    if type(registry.set_location) == "function" then
        registry:set_location(creature.guid, room_id)
    end
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
    for _, obj in ipairs(list_objects(reg)) do
        if obj.id == room_id and (obj.template == "room" or obj.exits) then
            return obj
        end
    end
    return nil
end

local function get_player_room_id(context)
    local cr = context.current_room
    if type(cr) == "table" then return cr.id end
    if type(cr) == "string" then return cr end
    return nil
end

---------------------------------------------------------------------------
-- emit_stimulus / clear_stimuli — delegated to stimulus module
---------------------------------------------------------------------------
function M.emit_stimulus(room_id, stimulus_type, data)
    stimulus.emit(room_id, stimulus_type, data)
end

function M.clear_stimuli()
    stimulus.clear()
end

---------------------------------------------------------------------------
-- get_creatures_in_room(registry, room_id) -> creature[]
-- Returns all animate creatures located in the given room.
---------------------------------------------------------------------------
function M.get_creatures_in_room(registry, room_id)
    local result = {}
    for _, obj in ipairs(list_objects(registry)) do
        if obj.animate then
            local loc = get_location(registry, obj)
            if loc == room_id then
                result[#result + 1] = obj
            end
        end
    end
    return result
end

---------------------------------------------------------------------------
-- Drive system
---------------------------------------------------------------------------

-- update_drives(creature)
-- Advances each drive by its decay_rate, clamped to [min, max].
local function update_drives(creature)
    if type(creature.drives) ~= "table" then return end
    for _, drive in pairs(creature.drives) do
        if type(drive) == "table" and type(drive.value) == "number" then
            local rate = drive.decay_rate or 0
            drive.value = drive.value + rate
            local max_val = drive.max or 100
            local min_val = drive.min or 0
            if drive.value > max_val then drive.value = max_val end
            if drive.value < min_val then drive.value = min_val end
        end
    end
end

---------------------------------------------------------------------------
-- Reaction system
---------------------------------------------------------------------------

-- get_exit_target(context, exit) -> target_room_id or nil
-- Resolves exit target from either simple format or portal-based format.
local function get_exit_target(context, exit)
    if type(exit) ~= "table" then return nil end
    -- Simple exit: { target = "room-id", open = true }
    if exit.target then return exit.target end
    -- Portal-based exit: { portal = "portal-id" }
    if exit.portal and context.registry then
        local reg = context.registry
        if type(reg.get) == "function" then
            local portal = reg:get(exit.portal)
            if portal and portal.portal then return portal.portal.target end
        end
    end
    return nil
end

-- get_room_distance(context, from_id, to_id) -> number
-- BFS distance between two rooms. Returns 999 if unreachable.
local function get_room_distance(context, from_id, to_id)
    if from_id == to_id then return 0 end
    local visited = { [from_id] = true }
    local frontier = { from_id }
    local depth = 0
    while #frontier > 0 and depth < 10 do
        depth = depth + 1
        local next_frontier = {}
        for _, rid in ipairs(frontier) do
            local room = get_room(context, rid)
            if room and room.exits then
                for _, exit in pairs(room.exits) do
                    local target_id = get_exit_target(context, exit)
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

-- is_exit_passable(context, exit, creature) -> bool, target_room_id
-- Checks whether a creature can pass through an exit.
local function is_exit_passable(context, exit, creature)
    if type(exit) ~= "table" then return false, nil end

    -- Simple exit format: { target = "room-id", open = bool }
    if exit.target then
        if exit.open == false then
            if not (creature.movement and creature.movement.can_open_doors) then
                return false, nil
            end
        end
        return true, exit.target
    end

    -- Portal-based exit: { portal = "portal-id" }
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

-- get_valid_exits(context, room_id, creature) -> array of { direction, target }
-- Returns exits a creature can traverse from the given room.
local function get_valid_exits(context, room_id, creature)
    local room = get_room(context, room_id)
    if not room or not room.exits then return {} end

    local valid = {}
    for dir, exit in pairs(room.exits) do
        local passable, target = is_exit_passable(context, exit, creature)
        if passable and target then
            valid[#valid + 1] = { direction = dir, target = target }
        end
    end
    return valid
end

-- Stimulus helpers table — passed to stimulus.process() so it can resolve
-- room distances without duplicating the navigation code.
local stimulus_helpers = {
    get_location = get_location,
    get_room_distance = get_room_distance,
}

-- process_stimuli(context, creature) -> messages[]
-- Delegated to stimulus module.
local function process_stimuli(context, creature)
    return stimulus.process(context, creature, stimulus_helpers)
end

---------------------------------------------------------------------------
-- Behavior selection (utility scoring)
---------------------------------------------------------------------------

-- score_actions(creature, context) -> sorted array of { action, score }
local function score_actions(creature, context)
    local behavior = creature.behavior or {}
    local drives = creature.drives or {}
    local scores = {}

    scores[#scores + 1] = { action = "idle", score = 10 }

    -- C14: Suppress wander during active combat
    local wander_score = 0
    if not (context and context.combat_active) then
        if drives.curiosity then
            wander_score = wander_score + (drives.curiosity.value or 0) * 0.3
        end
        wander_score = wander_score + (behavior.wander_chance or 0) * 0.2
    end
    scores[#scores + 1] = { action = "wander", score = wander_score }

    local fear_val = drives.fear and drives.fear.value or 0
    local flee_threshold = behavior.flee_threshold or 50
    if fear_val >= flee_threshold then
        scores[#scores + 1] = { action = "flee", score = fear_val * 1.5 }
    end

    local vocal_score = 0
    if fear_val > 10 and fear_val < flee_threshold then
        vocal_score = fear_val * 0.3
    end
    if drives.curiosity then
        vocal_score = vocal_score + (drives.curiosity.value or 0) * 0.1
    end
    scores[#scores + 1] = { action = "vocalize", score = vocal_score }

    -- Attack: no-op until WAVE-5 (D-COMBAT-NPC-PHASE-SEQUENCING)

    for _, entry in ipairs(scores) do
        entry.score = entry.score + math.random() * 2
    end

    table.sort(scores, function(a, b) return a.score > b.score end)
    return scores
end

---------------------------------------------------------------------------
-- Action execution
---------------------------------------------------------------------------

-- move_creature(context, creature, target_room_id)
-- Moves a creature between rooms, updating location and room.contents.
local function move_creature(context, creature, target_room_id)
    local old_loc = get_location(context.registry, creature)

    -- Update room.contents arrays (real game uses these)
    local old_room = get_room(context, old_loc)
    if old_room and old_room.contents then
        for i = #old_room.contents, 1, -1 do
            if old_room.contents[i] == creature.id then
                table.remove(old_room.contents, i)
                break
            end
        end
    end
    local new_room = get_room(context, target_room_id)
    if new_room then
        new_room.contents = new_room.contents or {}
        new_room.contents[#new_room.contents + 1] = creature.id
    end

    -- Update location (both obj.location and mock registry tracker)
    set_location(context.registry, creature, target_room_id)
end

-- execute_action(context, creature, action) -> messages[]
local function execute_action(context, creature, action)
    local messages = {}
    local player_room = get_player_room_id(context)
    local creature_loc = get_location(context.registry, creature)

    if action == "idle" then
        if creature._state and creature._state ~= "alive-idle"
           and creature._state ~= "dead" then
            creature._state = "alive-idle"
        end

    elseif action == "wander" then
        local exits = get_valid_exits(context, creature_loc, creature)
        if #exits > 0 then
            local choice = exits[math.random(#exits)]
            local old_loc = creature_loc

            if creature._state and creature._state ~= "dead" then
                creature._state = "alive-wander"
            end

            move_creature(context, creature, choice.target)

            if old_loc == player_room then
                local name = creature.name or "a creature"
                messages[#messages + 1] = name:sub(1,1):upper() .. name:sub(2) ..
                    " scurries " .. choice.direction .. "."
            elseif choice.target == player_room then
                local name = creature.name or "a creature"
                local st = creature.states and creature.states[creature._state]
                local arrival = st and st.room_presence
                messages[#messages + 1] = arrival or
                    (name:sub(1,1):upper() .. name:sub(2) .. " arrives.")
            end
            creature._last_exit = choice.direction
        else
            if creature._state and creature._state ~= "dead" then
                creature._state = "alive-idle"
            end
        end

    elseif action == "flee" then
        local exits = get_valid_exits(context, creature_loc, creature)
        if #exits > 0 then
            local choice = exits[math.random(#exits)]
            local old_loc = creature_loc

            if creature._state and creature._state ~= "dead" then
                creature._state = "alive-flee"
            end

            move_creature(context, creature, choice.target)

            if old_loc == player_room then
                local name = creature.name or "a creature"
                messages[#messages + 1] = name:sub(1,1):upper() .. name:sub(2) ..
                    " bolts " .. choice.direction .. "!"
            elseif choice.target == player_room then
                local name = creature.name or "a creature"
                messages[#messages + 1] = name:sub(1,1):upper() .. name:sub(2) ..
                    " darts into the room, eyes wide with fear!"
            end
            creature._last_exit = choice.direction
        else
            if creature._state and creature._state ~= "dead" then
                creature._state = "alive-flee"
            end
        end

    elseif action == "vocalize" then
        if creature_loc == player_room then
            local st = creature.states and creature.states[creature._state]
            local sound = st and st.on_listen
            if sound then
                messages[#messages + 1] = sound
            end
        end

    -- attack is a no-op until WAVE-5 (D-COMBAT-NPC-PHASE-SEQUENCING)
    end

    return messages
end

---------------------------------------------------------------------------
-- creature_tick(context, creature) -> messages[]
-- Evaluates one creature's behavior: drives → reactions → action selection.
---------------------------------------------------------------------------
function M.creature_tick(context, creature)
    local messages = {}

    if not creature.animate or creature._state == "dead" then
        return messages
    end

    -- 1. Update drives
    update_drives(creature)

    -- 2. Process stimuli
    local reaction_msgs = process_stimuli(context, creature)
    for _, msg in ipairs(reaction_msgs) do
        messages[#messages + 1] = msg
    end

    -- 3. Score and select best action
    local actions = score_actions(creature, context)
    local best = actions[1]
    if best then
        local action_msgs = execute_action(context, creature, best.action)
        for _, msg in ipairs(action_msgs) do
            messages[#messages + 1] = msg
        end
    end

    return messages
end

---------------------------------------------------------------------------
-- tick(context) -> messages[]
-- Master tick: iterates all animate objects, runs creature_tick for each,
-- then drains the stimulus queue.
---------------------------------------------------------------------------
function M.tick(context)
    local messages = {}
    if not context or not context.registry then return messages end

    local creatures = {}
    for _, obj in ipairs(list_objects(context.registry)) do
        if obj.animate then
            creatures[#creatures + 1] = obj
        end
    end

    for _, creature in ipairs(creatures) do
        local ok, result = pcall(M.creature_tick, context, creature)
        if ok and type(result) == "table" then
            for _, msg in ipairs(result) do
                messages[#messages + 1] = msg
            end
        end
    end

    M.clear_stimuli()
    return messages
end

return M
