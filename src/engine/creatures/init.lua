-- engine/creatures/init.lua
-- Creature behavior engine: drives, reactions, utility-scored actions, movement.
-- Evaluates metadata on animate objects generically (Principle 8).
--
-- Ownership: Bart (Architecture Lead)

local M = {}

local stimulus = require("engine.creatures.stimulus")
local predator_prey = require("engine.creatures.predator-prey")
local morale = require("engine.creatures.morale")
local navigation = require("engine.creatures.navigation")
local death = require("engine.creatures.death")
local creature_inventory = require("engine.creatures.inventory")
local respawn = require("engine.creatures.respawn")
local combat_ok, combat = pcall(require, "engine.combat")
if not combat_ok then combat = nil end
local creature_actions = require("engine.creatures.actions")
local pack_tactics = require("engine.creatures.pack-tactics")
local territorial = require("engine.creatures.territorial")

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
-- Stimulus / creatures API
---------------------------------------------------------------------------
function M.emit_stimulus(room_id, stimulus_type, data)
    stimulus.emit(room_id, stimulus_type, data)
end

function M.clear_stimuli() stimulus.clear() end

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

-- Drive system: update_drives(creature)
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

-- Navigation helpers delegated to navigation module
local function get_room_distance(context, from_id, to_id)
    return navigation.get_room_distance(context, from_id, to_id, get_room)
end

local function get_valid_exits(context, room_id, creature)
    return navigation.get_valid_exits(context, room_id, creature, get_room)
end

local stimulus_helpers = {
    get_location = get_location,
    get_room_distance = get_room_distance,
}

local function process_stimuli(context, creature)
    return stimulus.process(context, creature, stimulus_helpers)
end

---------------------------------------------------------------------------
-- Death reshape API (delegated to engine/creatures/death.lua)
-- Placed early so action_helpers can reference M.handle_creature_death.
---------------------------------------------------------------------------
M.reshape_instance = death.reshape_instance
M.handle_creature_death = death.handle_creature_death

---------------------------------------------------------------------------
-- Action helpers table (dependencies for creatures/actions.lua)
---------------------------------------------------------------------------
local action_helpers = {
    get_location = get_location,
    set_location = set_location,
    get_room = get_room,
    get_player_room_id = get_player_room_id,
    list_objects = list_objects,
    get_valid_exits = get_valid_exits,
    -- Wrappers resolve M.* at call time so test monkey-patching works
    get_creatures_in_room = function(reg, room_id)
        return M.get_creatures_in_room(reg, room_id)
    end,
    emit_stimulus = function(room_id, st, data)
        return M.emit_stimulus(room_id, st, data)
    end,
    handle_creature_death = function(target, ctx, room)
        return M.handle_creature_death(target, ctx, room)
    end,
}

-- Morale helpers: move_creature delegates to extracted actions module
local morale_helpers = {
    get_location = get_location,
    get_valid_exits = get_valid_exits,
    get_player_room_id = get_player_room_id,
    move_creature = function(ctx, creature, target)
        creature_actions.move_creature(ctx, creature, target, action_helpers)
    end,
}

local function check_morale(context, creature, combat_result)
    return morale.check(context, creature, combat_result, morale_helpers)
end

function M.attempt_flee(context, creature)
    return morale.check(context, creature, nil, morale_helpers)
end

-- attempt_flee added after definition so action_helpers captures it
action_helpers.attempt_flee = function(ctx, creature)
    return M.attempt_flee(ctx, creature)
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

    -- 0. Territorial evaluation: reduce fear, boost effective aggression
    local behavior = creature.behavior or {}
    local creature_loc = get_location(context.registry, creature)
    if behavior.territorial then
        local territory = behavior.territory or behavior.home_territory
        if territory and creature_loc == territory then
            if creature.drives and creature.drives.fear then
                local fear = creature.drives.fear
                fear.value = math.max(fear.min or 0, (fear.value or 0) - 10)
            end
        end
    end

    -- 0a. Territory marking: place marker when creature enters a new room
    if behavior.territorial and behavior.marks_territory ~= false then
        if creature_loc and creature_loc ~= creature._last_marked_room then
            local existing = territorial.find_markers_in_room(context.registry, creature_loc)
            local already_marked = false
            for _, m in ipairs(existing) do
                local m_owner = (m.territory and m.territory.owner) or m.owner or m.creator
                if m_owner == creature.guid then
                    already_marked = true; break
                end
            end
            if not already_marked then
                territorial.mark_territory(creature, context)
                creature._last_marked_room = creature_loc
            end
        end
    end

    -- 0b. Territorial marker response: evaluate foreign markers in room
    if behavior.territorial and creature_loc then
        local markers = territorial.find_markers_in_room(context.registry, creature_loc)
        for _, marker in ipairs(markers) do
            local m_owner = (marker.territory and marker.territory.owner) or marker.owner or marker.creator
            if m_owner and m_owner ~= creature.guid then
                local response = territorial.evaluate_marker(creature, marker, context)
                if response == "avoid" then
                    -- Flee from foreign territory
                    local exits = get_valid_exits(context, creature_loc, creature)
                    if #exits > 0 then
                        local choice = exits[math.random(#exits)]
                        creature_actions.move_creature(context, creature, choice.target, action_helpers)
                        creature._last_exit = choice.direction
                    end
                    return messages
                elseif response == "challenge" then
                    creature._state = "alive-aggressive"
                end
                break
            end
        end
    end

    -- 0c. Pack tactics: defensive retreat when health < 20%
    if pack_tactics.should_retreat(creature, context) then
        local exits = get_valid_exits(context, creature_loc, creature)
        if #exits > 0 then
            local choice = exits[math.random(#exits)]
            creature_actions.move_creature(context, creature, choice.target, action_helpers)
            creature._state = "alive-flee"
            local player_room = get_player_room_id(context)
            if creature_loc == player_room then
                local cn = creature.name or "a creature"
                messages[#messages + 1] = cn:sub(1,1):upper() .. cn:sub(2) .. " limps away, seeking cover."
            end
            return messages
        end
    end

    -- 1. Update drives
    update_drives(creature)

    -- 2. Process stimuli
    local reaction_msgs = process_stimuli(context, creature)
    for _, msg in ipairs(reaction_msgs) do
        messages[#messages + 1] = msg
    end
    local bait = creature_actions.try_bait(context, creature, action_helpers)
    if bait then for _, m in ipairs(bait) do messages[#messages+1] = m end; return messages end

    -- 2a. Ambush check: creature with behavior.ambush stays hidden until trigger
    if behavior.ambush and not creature._ambush_sprung then
        local ambush = behavior.ambush
        local should_spring = false
        if type(ambush.condition) == "function" then
            should_spring = ambush.condition(creature, context)
        elseif ambush.trigger_on_proximity then
            local player_room = get_player_room_id(context)
            should_spring = creature_loc == player_room
        end
        if not should_spring then
            return messages
        end
        creature._ambush_sprung = true
        local player_room = get_player_room_id(context)
        if creature_loc == player_room and ambush.narration then
            messages[#messages + 1] = ambush.narration
        end
    end

    -- 2b. Web ambush (spider-specific via metadata — Principle 8)
    if behavior.web_ambush and not creature._ambush_sprung then
        local web_ambush = behavior.web_ambush
        local should_spring = false
        if type(web_ambush.condition) == "function" then
            should_spring = web_ambush.condition(creature, context)
        end
        if should_spring then
            creature._ambush_sprung = true
        else
            return messages
        end
    end

    -- 3. Score and select best action (with pack stagger)
    local scored = creature_actions.score_actions(creature, context, action_helpers)
    local best = scored[1]
    if best then
        -- Pack stagger: if attacking and pack present, only alpha attacks this turn
        if best.action == "attack" and creature_loc then
            local pack = pack_tactics.get_pack_in_room(context.registry, creature_loc, creature)
            if #pack > 1 then
                local alpha = pack_tactics.select_alpha(pack, context)
                if alpha and alpha.guid ~= creature.guid then
                    -- Non-alpha: skip attack this turn (stagger delay)
                    if not creature._pack_waited then
                        creature._pack_waited = true
                        best = { action = "idle", score = 0 }
                    else
                        creature._pack_waited = nil
                    end
                end
            end
        end

        local action_msgs = creature_actions.execute_action(context, creature, best.action, action_helpers)
        for _, msg in ipairs(action_msgs) do
            messages[#messages + 1] = msg
        end
    end

    return messages
end

---------------------------------------------------------------------------
-- tick(context) -> messages[]
-- Master tick: iterates all animate objects, runs creature_tick for each,
-- advances respawn timers, then drains the stimulus queue.
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

    -- Advance respawn timers (spawns new creatures when ready)
    respawn.tick(context, list_objects, get_room, get_player_room_id(context))

    M.clear_stimuli()
    return messages
end

---------------------------------------------------------------------------
-- Public API: expose internal functions for testing and cross-module use
---------------------------------------------------------------------------
function M.has_prey_in_room(c, ctx) return predator_prey.has_prey_in_room(c, ctx, M.get_creatures_in_room, get_location) end
function M.select_prey_target(ctx, c) return predator_prey.select_prey_target(ctx, c, M.get_creatures_in_room, get_location) end

-- Delegate to actions module, preserving original public signatures
function M.score_actions(creature, context)
    return creature_actions.score_actions(creature, context, action_helpers)
end
function M.execute_action(context, creature, action)
    return creature_actions.execute_action(context, creature, action, action_helpers)
end

-- check_morale(creature) -> true if health/max_health < flee_threshold
function M.check_morale(creature)
    if not creature then return nil end
    local health = creature.health
    local max_health = creature.max_health
    if not health or not max_health or max_health <= 0 then return nil end
    local threshold = creature.combat and creature.combat.behavior
        and creature.combat.behavior.flee_threshold
    if not threshold then
        local raw = creature.behavior and creature.behavior.flee_threshold
        if raw and raw > 1 then threshold = raw / 100 else threshold = raw end
    end
    if not threshold then return nil end
    return (health / max_health) < threshold
end

---------------------------------------------------------------------------
-- Respawn API (delegated to engine/creatures/respawn.lua)
---------------------------------------------------------------------------
M.register_for_respawn = respawn.register
M.respawn_pending = respawn.count_pending
M.respawn_clear = respawn.clear

---------------------------------------------------------------------------
-- Inventory API (delegated to engine/creatures/inventory.lua)
---------------------------------------------------------------------------
M.validate_inventory = creature_inventory.validate
M.drop_inventory_on_death = creature_inventory.drop_on_death
M.inventory_presence_hint = creature_inventory.presence_hint

---------------------------------------------------------------------------
-- Pack Tactics API (delegated to engine/creatures/pack-tactics.lua)
---------------------------------------------------------------------------
M.pack_tactics = pack_tactics

---------------------------------------------------------------------------
-- Territorial API (delegated to engine/creatures/territorial.lua)
---------------------------------------------------------------------------
M.territorial = territorial

return M
