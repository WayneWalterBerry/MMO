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
    if behavior.territorial then
        local territory = behavior.territory or behavior.home_territory
        local creature_loc = get_location(context.registry, creature)
        if territory and creature_loc == territory then
            if creature.drives and creature.drives.fear then
                local fear = creature.drives.fear
                fear.value = math.max(fear.min or 0, (fear.value or 0) - 10)
            end
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

    -- 3. Score and select best action
    local scored = creature_actions.score_actions(creature, context, action_helpers)
    local best = scored[1]
    if best then
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

return M
