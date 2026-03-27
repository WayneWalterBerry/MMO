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
local combat_ok, combat = pcall(require, "engine.combat")
if not combat_ok then combat = nil end

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

    -- Attack: score when prey is present in the same room
    if predator_prey.has_prey_in_room(creature, context, M.get_creatures_in_room, get_location) then
        local aggression = behavior.aggression or 0
        local hunger_val = drives.hunger and drives.hunger.value or 0
        local attack_score = aggression * 0.5 + hunger_val * 0.5
        -- Territorial boost: creature in home territory gets aggression bonus
        if behavior.territorial then
            local territory = behavior.territory or behavior.home_territory
            local loc = get_location(context.registry, creature)
            if territory and loc == territory then
                attack_score = attack_score + aggression * 0.3
            end
        end
        scores[#scores + 1] = { action = "attack", score = attack_score }
    end

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
-- Track 5C: food-as-bait behavior (R-5 boundary: no cooking/recipes/spoilage)
local function find_bait(ctx, room_id, cid)
    local r = {}
    for _, o in ipairs(list_objects(ctx.registry)) do
        if o.food and o.food.bait_targets and get_location(ctx.registry, o) == room_id then
            for _, t in ipairs(o.food.bait_targets) do if t == cid then r[#r+1]=o; break end end
        end
    end
    table.sort(r, function(a,b) return (a.food.bait_value or 0) > (b.food.bait_value or 0) end)
    return r
end
local function try_bait(ctx, creature)
    local h = creature.drives and creature.drives.hunger
    if not h or (h.value or 0) < (h.satisfy_threshold or 80) then return nil end
    if ctx.combat_active or (combat and combat.find_fight_for_combatant and combat.find_fight_for_combatant(creature)) then return nil end
    local loc = get_location(ctx.registry, creature); if not loc then return nil end
    local cn = creature.name or "a creature"
    local pr, CN, msgs = get_player_room_id(ctx), cn:sub(1,1):upper()..cn:sub(2), {}
    local food = find_bait(ctx, loc, creature.id)
    if #food > 0 then
        ctx.registry:remove(food[1].id); h.value = h.min or 0
        if loc == pr then local m = CN.." scurries toward "..(food[1].name or "the food").." and devours it."; msgs[1] = m; print(m) end
        return msgs end
    local best, bv = nil, -1
    for _, ex in ipairs(get_valid_exits(ctx, loc, creature)) do
        local a = find_bait(ctx, ex.target, creature.id)
        if #a > 0 and (a[1].food.bait_value or 0) > bv then best, bv = ex.target, a[1].food.bait_value or 0 end end
    if not best then return nil end; move_creature(ctx, creature, best)
    if loc == pr then msgs[1] = CN.." scurries away, drawn by a scent." end
    if best == pr then msgs[1] = CN.." arrives, sniffing hungrily." end
    return msgs
end
-- Morale helpers: built after all navigation/movement functions are defined
local morale_helpers = {
    get_location = get_location,
    get_valid_exits = get_valid_exits,
    get_player_room_id = get_player_room_id,
    move_creature = move_creature,
}

local function check_morale(context, creature, combat_result)
    return morale.check(context, creature, combat_result, morale_helpers)
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

    elseif action == "attack" then
        local target = predator_prey.select_prey_target(
            context, creature, M.get_creatures_in_room, get_location)
        if target and combat then
            if creature._state and creature._state ~= "dead" then
                creature._state = "alive-hunt"
            end
            local result = combat.run_combat(context, creature, target)
            local room_id = creature_loc or player_room
            -- Emit creature_attacked stimulus via M.emit_stimulus for testability
            if room_id then
                M.emit_stimulus(room_id, "creature_attacked", {
                    attacker_id = creature.id or creature.guid,
                    defender_id = target.id or target.guid,
                    attacker_name = creature.name,
                    defender_name = target.name,
                })
            end
            -- Creature death: reshape if death_state present, then emit stimulus
            if result and result.defender_dead and room_id then
                local dead_name = target.name
                local death_room = get_room(context, room_id)
                M.handle_creature_death(target, context, death_room)
                M.emit_stimulus(room_id, "creature_died", {
                    creature_id = target.id or target.guid,
                    creature_name = dead_name,
                    killer_id = creature.id or creature.guid,
                    killer_name = creature.name,
                })
            end
            -- Narrate if player is in the same room
            if creature_loc == player_room then
                local atk_name = creature.name or "a creature"
                local def_name = target.name or "a creature"
                if result and result.text and result.text ~= "" then
                    messages[#messages + 1] = result.text
                else
                    messages[#messages + 1] = atk_name:sub(1,1):upper() ..
                        atk_name:sub(2) .. " attacks " .. def_name .. "!"
                end
                if result and result.death_narration then
                    messages[#messages + 1] = result.death_narration
                end
            end

            -- Track 3B: Morale check on the DEFENDER after combat resolves
            if result and not result.defender_dead then
                local morale_result = M.attempt_flee(context, target)
                if target._morale_message then
                    messages[#messages + 1] = target._morale_message
                    target._morale_message = nil
                end
                -- If defender fled, remove from any active fight
                if morale_result == "flee" and combat.find_fight_for_combatant then
                    local fight = combat.find_fight_for_combatant(target)
                    if fight then combat.remove_combatant(fight, target) end
                end
            end

            -- Track 3B: Morale check on the ATTACKER too
            M.attempt_flee(context, creature)
            if creature._morale_message then
                messages[#messages + 1] = creature._morale_message
                creature._morale_message = nil
            end
        end
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
    local bait = try_bait(context, creature)
    if bait then for _, m in ipairs(bait) do messages[#messages+1] = m end; return messages end

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

---------------------------------------------------------------------------
-- Public API: expose internal functions for testing and cross-module use
---------------------------------------------------------------------------
function M.has_prey_in_room(c, ctx) return predator_prey.has_prey_in_room(c, ctx, M.get_creatures_in_room, get_location) end
function M.select_prey_target(ctx, c) return predator_prey.select_prey_target(ctx, c, M.get_creatures_in_room, get_location) end

M.score_actions = score_actions
M.execute_action = execute_action

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

function M.attempt_flee(context, creature)
    return morale.check(context, creature, nil, morale_helpers)
end

---------------------------------------------------------------------------
-- Death reshape API (delegated to engine/creatures/death.lua)
---------------------------------------------------------------------------
M.reshape_instance = death.reshape_instance
M.handle_creature_death = death.handle_creature_death

---------------------------------------------------------------------------
-- Inventory API (delegated to engine/creatures/inventory.lua)
---------------------------------------------------------------------------
M.validate_inventory = creature_inventory.validate
M.drop_inventory_on_death = creature_inventory.drop_on_death
M.inventory_presence_hint = creature_inventory.presence_hint

return M
