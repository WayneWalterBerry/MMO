local resolution = require("engine.combat.resolution")
local narration = require("engine.combat.narration")
local presentation_ok, presentation = pcall(require, "engine.ui.presentation")
local creatures_ok, creatures_mod = pcall(require, "engine.creatures")
if not creatures_ok then creatures_mod = nil end
local npc_behavior_ok, npc_behavior = pcall(require, "engine.combat.npc-behavior")
if not npc_behavior_ok then npc_behavior = nil end

local M = {}

-- Re-export from resolution for backward compatibility
M.SEVERITY = resolution.SEVERITY

M.PHASE = {
    INITIATE = 1,
    DECLARE = 2,
    RESPOND = 3,
    RESOLVE = 4,
    NARRATE = 5,
    UPDATE = 6,
}

local SIZE_MODIFIERS = resolution.SIZE_MODIFIERS
local is_player = resolution.is_player
local normalize_weapon = resolution.normalize_weapon
local pick_weapon = resolution.pick_weapon

function M.initiate(attacker, defender)
    local a_speed = attacker and attacker.combat and attacker.combat.speed or 0
    local d_speed = defender and defender.combat and defender.combat.speed or 0
    if a_speed ~= d_speed then
        return a_speed > d_speed and attacker or defender,
            a_speed > d_speed and defender or attacker
    end
    local a_size = attacker and attacker.combat and attacker.combat.size or "medium"
    local d_size = defender and defender.combat and defender.combat.size or "medium"
    local a_mod = SIZE_MODIFIERS[a_size] or 1.0
    local d_mod = SIZE_MODIFIERS[d_size] or 1.0
    if a_mod ~= d_mod then
        return a_mod < d_mod and attacker or defender,
            a_mod < d_mod and defender or attacker
    end
    return attacker, defender
end

function M.declare(attacker, weapon, target_zone, opts)
    local attack_weapon = normalize_weapon(weapon) or pick_weapon(attacker)
    return {
        weapon = attack_weapon,
        target_zone = target_zone,
        stance = opts and opts.stance or "balanced",
    }
end

function M.respond(defender, response, opts)
    local r = response
    if type(r) == "table" then r = r.type end
    return {
        type = r,
        stance = opts and opts.stance or "balanced",
    }
end

function M.resolve_exchange(attacker, defender, weapon, target_zone, response, opts)
    local attack_action = M.declare(attacker, weapon, target_zone, opts)
    local defense_action = M.respond(defender, response, opts)
    local result = resolution.resolve_damage(attacker, defender, attack_action.weapon, attack_action.target_zone, defense_action.type, opts)

    result.phase_log = {
        M.PHASE.INITIATE,
        M.PHASE.DECLARE,
        M.PHASE.RESPOND,
        M.PHASE.RESOLVE,
        M.PHASE.NARRATE,
        M.PHASE.UPDATE,
    }

    result.narration = M.narrate(result, result.light ~= false)
    result.text = result.narration

    local update_result = resolution.update(result, opts)
    if update_result then
        for k, v in pairs(update_result) do result[k] = v end
    end

    return result
end

function M.resolve(attacker, defender, weapon, target_zone, response, opts)
    return resolution.resolve_damage(attacker, defender, normalize_weapon(weapon), target_zone, response, opts)
end

function M.narrate(result, light)
    if narration and narration.generate then
        return narration.generate(result, light)
    end
    if narration and narration.narrate then
        return narration.narrate(result, light)
    end
    return ""
end

-- Delegate to resolution module
M.update = resolution.update
M.interrupt_check = resolution.interrupt_check

---------------------------------------------------------------------------
-- Active fights tracking (Track 3A)
---------------------------------------------------------------------------

local active_fights = {}
local fight_counter = 0

function M.get_active_fights()
    return active_fights
end

function M.find_fight_by_room(room_id)
    for _, fight in pairs(active_fights) do
        if fight.room_id == room_id then return fight end
    end
    return nil
end

function M.find_fight_for_combatant(combatant)
    local cid = combatant.id or combatant.guid
    for _, fight in pairs(active_fights) do
        for _, c in ipairs(fight.combatants) do
            if (c.id or c.guid) == cid then return fight end
        end
    end
    return nil
end

function M.start_fight(context, combatants, room_id)
    fight_counter = fight_counter + 1
    local fight = {
        id = fight_counter,
        combatants = {},
        room_id = room_id,
        round = 0,
    }
    for _, c in ipairs(combatants) do
        fight.combatants[#fight.combatants + 1] = c
    end
    active_fights[fight.id] = fight
    if context then context.active_fights = active_fights end
    return fight
end

function M.end_fight(context, fight_id)
    active_fights[fight_id] = nil
    if context then context.active_fights = active_fights end
end

function M.join_fight(fight, combatant)
    for _, c in ipairs(fight.combatants) do
        if (c.id or c.guid) == (combatant.id or combatant.guid) then
            return fight
        end
    end
    fight.combatants[#fight.combatants + 1] = combatant
    return fight
end

function M.remove_combatant(fight, combatant)
    local cid = combatant.id or combatant.guid
    for i = #fight.combatants, 1, -1 do
        if (fight.combatants[i].id or fight.combatants[i].guid) == cid then
            table.remove(fight.combatants, i)
            break
        end
    end
    if #fight.combatants < 2 then return true end
    return false
end

-- Sort combatants: speed desc → size asc → player last among equals
function M.sort_combatants(combatants)
    local sorted = {}
    for _, c in ipairs(combatants) do sorted[#sorted + 1] = c end
    table.sort(sorted, function(a, b)
        local a_speed = a.combat and a.combat.speed or 0
        local b_speed = b.combat and b.combat.speed or 0
        if a_speed ~= b_speed then return a_speed > b_speed end
        local a_size = SIZE_MODIFIERS[a.combat and a.combat.size or "medium"] or 1.0
        local b_size = SIZE_MODIFIERS[b.combat and b.combat.size or "medium"] or 1.0
        if a_size ~= b_size then return a_size < b_size end
        -- Player goes last among equals
        local a_player = is_player(a) and 1 or 0
        local b_player = is_player(b) and 1 or 0
        return a_player < b_player
    end)
    return sorted
end

-- NPC target selection: prey list first, then aggression threshold fallback
function M.select_npc_target(attacker, combatants)
    local prey_list = attacker.behavior and attacker.behavior.prey
    local attacker_id = attacker.id or attacker.guid

    -- Priority: prey list targets
    if prey_list and #prey_list > 0 then
        for _, prey_id in ipairs(prey_list) do
            for _, c in ipairs(combatants) do
                local cid = c.id or c.guid
                if cid ~= attacker_id and c._state ~= "dead" and c.animate ~= false then
                    if c.id == prey_id then return c end
                end
            end
        end
    end

    -- Fallback: attack highest-aggression target (non-self, alive)
    local aggression = attacker.behavior and attacker.behavior.aggression or 0
    if aggression > 20 then
        local best, best_size = nil, math.huge
        for _, c in ipairs(combatants) do
            local cid = c.id or c.guid
            if cid ~= attacker_id and c._state ~= "dead" and c.animate ~= false then
                local c_size = SIZE_MODIFIERS[c.combat and c.combat.size or "medium"] or 1.0
                if c_size < best_size then
                    best, best_size = c, c_size
                end
            end
        end
        return best
    end
    return nil
end

-- Resolve one full round of multi-combatant combat
function M.resolve_round(context, fight)
    if not fight or #fight.combatants < 2 then return {} end

    fight.round = (fight.round or 0) + 1
    local ordered = M.sort_combatants(fight.combatants)
    local results = {}

    local light = true
    if context and context.player and presentation_ok and presentation
       and presentation.get_light_level then
        light = presentation.get_light_level(context) ~= "dark"
    end

    -- Pairwise: each combatant attacks once per round in turn order
    for _, attacker in ipairs(ordered) do
        if attacker._state == "dead" or attacker.animate == false then
            goto continue_attacker
        end

        local target
        if is_player(attacker) then
            -- Player attacks their declared target (from context)
            target = context and context.combat_target
            if not target or target._state == "dead" then
                target = nil
                for _, c in ipairs(fight.combatants) do
                    if not is_player(c) and c._state ~= "dead" and c.animate ~= false then
                        target = c
                        break
                    end
                end
            end
        else
            target = M.select_npc_target(attacker, fight.combatants)
        end

        if not target or target._state == "dead" then
            goto continue_attacker
        end

        local weapon = pick_weapon(attacker)
        local target_zone = nil
        if not is_player(attacker) and npc_behavior then
            target_zone = npc_behavior.select_target_zone(attacker, target)
        end
        local response = nil
        if not is_player(target) and npc_behavior then
            response = npc_behavior.select_response(target, attacker)
        end

        -- Cornered stance: attack × 1.5 applied via opts
        local stance = context and context.combat_stance or "balanced"
        local opts = { light = light, stance = stance }
        if attacker._cornered then
            opts.cornered_bonus = 1.5
        end

        local result = M.resolve_exchange(attacker, target, weapon, target_zone, response, opts)
        results[#results + 1] = result

        -- Remove dead combatants
        if result.defender_dead then
            M.remove_combatant(fight, target)
        end

        ::continue_attacker::
    end

    -- End fight if fewer than 2 alive combatants remain
    local alive_count = 0
    for _, c in ipairs(fight.combatants) do
        if c._state ~= "dead" and c.animate ~= false then
            alive_count = alive_count + 1
        end
    end
    if alive_count < 2 then
        M.end_fight(context, fight.id)
    end

    return results
end

-- Reset active fights (for testing)
function M.reset_fights()
    active_fights = {}
    fight_counter = 0
end

-- Context-aware target selection: finds same-room creatures via registry
function M.select_target(context, attacker)
    if not context or not attacker then return nil end
    local attacker_loc = attacker.location
    if not attacker_loc then return nil end
    -- Build combatants list from registry (all animate creatures in same room)
    local combatants = {}
    if creatures_mod and creatures_mod.get_creatures_in_room then
        combatants = creatures_mod.get_creatures_in_room(context.registry, attacker_loc)
    else
        -- Fallback: scan registry directly
        local all = {}
        if context.registry and type(context.registry.list) == "function" then
            all = context.registry:list()
        elseif context.registry and type(context.registry.all) == "function" then
            all = context.registry:all()
        end
        for _, obj in ipairs(all) do
            if obj.animate and obj.location == attacker_loc then
                combatants[#combatants + 1] = obj
            end
        end
    end
    return M.select_npc_target(attacker, combatants)
end

function M.run_combat(context, attacker, defender)
    local light = true
    if context and context.player and presentation_ok and presentation and presentation.get_light_level then
        light = presentation.get_light_level(context) ~= "dark"
    end

    -- C14: Signal combat mode to the game loop
    if context then context.combat_active = true end

    local stance = context and context.combat_stance or "balanced"
    local weapon = pick_weapon(attacker)

    -- NPC target zone: use combat.behavior.target_priority for zone selection
    local target_zone = nil
    if not is_player(attacker) and npc_behavior then
        target_zone = npc_behavior.select_target_zone(attacker, defender)
    end

    -- NPC defense response: auto-select from defender's combat.behavior.defense
    local response = nil
    if not is_player(defender) and npc_behavior then
        response = npc_behavior.select_response(defender, attacker)
    end

    local result = M.resolve_exchange(attacker, defender, weapon, target_zone, response, { light = light, stance = stance })

    -- WAVE-4: Emit combat sound stimulus for creature reactions
    if creatures_mod and creatures_mod.emit_stimulus then
        local room_id = defender.location
            or (context and context.current_room and context.current_room.id)
        if room_id then
            local intensity = 3  -- unarmed
            if weapon and weapon.id and weapon.id ~= "fist" then intensity = 6 end
            if result.defender_dead then intensity = 8 end
            creatures_mod.emit_stimulus(room_id, "loud_noise", {
                intensity = intensity,
                source = attacker.id or attacker.guid or "combat",
            })
        end
    end

    -- C12: Emit creature_died stimulus and capture death narration
    if result.defender_dead then
        if creatures_mod and creatures_mod.emit_stimulus then
            local room_id = defender.location
                or (context and context.current_room and context.current_room.id)
            if room_id then
                creatures_mod.emit_stimulus(room_id, "creature_died", {
                    creature_id = defender.id or defender.guid,
                    creature_name = defender.name,
                })
            end
        end
    end

    -- C14: Clear combat mode when combat resolves
    if result.defender_dead or result.fled or result.combat_over then
        if context then context.combat_active = nil end
    end

    return result
end

return M
