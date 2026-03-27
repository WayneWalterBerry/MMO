local materials = require("engine.materials")
local narration = require("engine.combat.narration")
local presentation_ok, presentation = pcall(require, "engine.ui.presentation")
local injuries_ok, injuries = pcall(require, "engine.injuries")
if not injuries_ok then injuries = nil end
local creatures_ok, creatures_mod = pcall(require, "engine.creatures")
if not creatures_ok then creatures_mod = nil end
local npc_behavior_ok, npc_behavior = pcall(require, "engine.combat.npc-behavior")
if not npc_behavior_ok then npc_behavior = nil end

local M = {}

M.SEVERITY = {
    DEFLECT = 0,
    GRAZE = 1,
    HIT = 2,
    SEVERE = 3,
    CRITICAL = 4,
}

M.PHASE = {
    INITIATE = 1,
    DECLARE = 2,
    RESPOND = 3,
    RESOLVE = 4,
    NARRATE = 5,
    UPDATE = 6,
}

local SIZE_MODIFIERS = {
    tiny = 0.5,
    small = 1.0,
    medium = 2.0,
    large = 4.0,
    huge = 8.0,
}

local STANCE_MODIFIERS = {
    aggressive = { attack = 1.3, defense = 1.3 },
    defensive = { attack = 0.7, defense = 0.7 },
    balanced = { attack = 1.0, defense = 1.0 },
}

local FORCE_SCALE = 0.1
-- Tissue-layer penetration resistance. Tuned so unarmed blunt (force=2, bone)
-- can penetrate soft tissue (hide/flesh) at GRAZE level while bone/organ stay
-- protected.  See #275 — old value of 1000 made fists deal zero damage.
local THICKNESS = 200

local function ensure_material_defaults()
    if not materials or not materials.registry then return end
    for _, mat in pairs(materials.registry) do
        if mat.max_edge == nil then
            if type(mat.hardness) == "number" then
                mat.max_edge = math.max(1, math.floor(mat.hardness))
            else
                mat.max_edge = 1
            end
        end
    end
end

ensure_material_defaults()

local function is_player(obj)
    return obj and (obj.id == "player" or obj.is_player == true)
end

local function size_modifier(combat)
    local size = combat and combat.size or "medium"
    return SIZE_MODIFIERS[size] or 1.0
end

local function get_material(name)
    if materials and materials.get then
        local mat = materials.get(name)
        if mat then
            if mat.max_edge == nil then
                mat.max_edge = type(mat.hardness) == "number" and math.max(1, math.floor(mat.hardness)) or 1
            end
            return mat
        end
    end
    return { density = 1000, hardness = 1, flexibility = 0.5, max_edge = 1 }
end

local function normalize_weapon(weapon)
    if not weapon then return nil end
    if weapon.combat then return weapon end
    if weapon.type then
        return {
            id = weapon.id,
            name = weapon.name or weapon.id,
            material = weapon.material,
            combat = {
                type = weapon.type,
                force = weapon.force or 1,
                message = weapon.message or "hits",
                two_handed = weapon.two_handed or false,
            },
            _natural_weapon = true,
        }
    end
    return weapon
end

local function pick_weapon(attacker)
    if attacker and attacker.combat and attacker.combat.natural_weapons then
        local list = attacker.combat.natural_weapons
        if #list > 0 then
            return normalize_weapon(list[math.random(#list)])
        end
    end
    return normalize_weapon({
        id = "fist",
        name = "bare fist",
        material = "bone",
        combat = { type = "blunt", force = 2, message = "punches", two_handed = false },
    })
end

local function zone_weights(body_tree, exclude)
    local zones = {}
    local total = 0
    for zone, info in pairs(body_tree or {}) do
        if zone ~= exclude then
            local weight = (info and info.size) or 1
            zones[#zones + 1] = { id = zone, weight = weight }
            total = total + weight
        end
    end
    return zones, total
end

local function weighted_zone(body_tree, exclude)
    local zones, total = zone_weights(body_tree, exclude)
    if #zones == 0 then return nil end
    local roll = math.random() * total
    local acc = 0
    for _, entry in ipairs(zones) do
        acc = acc + entry.weight
        if roll <= acc then return entry.id end
    end
    return zones[#zones].id
end

local function select_zone(body_tree, target_zone, allow_target, accuracy)
    if not body_tree or next(body_tree) == nil then return target_zone or "body" end
    local target_accuracy = accuracy or 0.6
    if target_zone and allow_target and body_tree[target_zone] then
        math.random()
        if math.random() <= target_accuracy then
            return target_zone
        end
        return weighted_zone(body_tree, target_zone) or target_zone
    end
    return weighted_zone(body_tree, nil) or target_zone
end

local function map_severity(layer)
    if not layer then return M.SEVERITY.DEFLECT end
    if layer == "organ" then return M.SEVERITY.CRITICAL end
    if layer == "bone" then return M.SEVERITY.SEVERE end
    if layer == "flesh" then return M.SEVERITY.HIT end
    return M.SEVERITY.GRAZE
end

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

local function resolve_damage(attacker, defender, weapon, target_zone, response, opts)
    local result = {
        attacker = attacker,
        defender = defender,
        weapon = weapon,
    }

    local light = true
    if opts and opts.light ~= nil then
        light = opts.light
    elseif opts and presentation_ok and presentation and presentation.get_light_level then
        light = presentation.get_light_level(opts) ~= "dark"
    end

    local stance = opts and opts.stance or "balanced"
    local stance_mod = STANCE_MODIFIERS[stance] or STANCE_MODIFIERS.balanced

    -- NPC stance: if attacker is NPC, read combat.behavior via npc-behavior
    if not is_player(attacker) and npc_behavior then
        local npc_stance = npc_behavior.select_stance(attacker)
        if npc_stance and STANCE_MODIFIERS[npc_stance] then
            stance = npc_stance
            stance_mod = STANCE_MODIFIERS[npc_stance]
        end
    end

    local weapon_type = weapon and weapon.combat and weapon.combat.type or "blunt"
    if weapon_type == "slash" then weapon_type = "edged" end

    local weapon_force = weapon and weapon.combat and weapon.combat.force or 1
    local weapon_material = weapon and (weapon.material or weapon.combat and weapon.combat.material) or "flesh"
    local mat = get_material(weapon_material)
    local base_force = (mat.density or 1000) * size_modifier(attacker and attacker.combat) * weapon_force * FORCE_SCALE
    local accuracy = weapon_force >= 7 and 1.0 or 0.6

    if is_player(attacker) then
        base_force = base_force * (stance_mod.attack or 1.0)
    elseif stance ~= "balanced" then
        base_force = base_force * (stance_mod.attack or 1.0)
    end

    -- Cornered bonus: attack × 1.5 when creature has no escape
    if opts and opts.cornered_bonus then
        base_force = base_force * opts.cornered_bonus
    end

    local defense_multiplier = 1.0
    local response_type = response
    if type(response_type) == "table" then response_type = response_type.type end

    -- NPC response auto-select: if no response provided, read defender's behavior
    if not response_type and not is_player(defender) and npc_behavior then
        response_type = npc_behavior.select_response(defender, attacker)
    end
    if response_type == "block" then
        defense_multiplier = 0.3
    elseif response_type == "flee" then
        defense_multiplier = 0.5
        result.fled = true
        result.combat_over = true
    elseif response_type == "dodge" then
        if math.random() <= 0.4 then
            result.severity = M.SEVERITY.DEFLECT
            result.zone = select_zone(defender and defender.body_tree, target_zone, light, accuracy)
            result.tissue_hit = defender and defender.body_tree
                and defender.body_tree[result.zone]
                and defender.body_tree[result.zone].tissue
                and defender.body_tree[result.zone].tissue[1]
            result.material_name = weapon_material
            result.action_verb = weapon and weapon.combat and weapon.combat.message or "hits"
            result.dodged = true
            result.light = light
            return result
        end
    elseif response_type == "counter" then
        result.counter = true
    end

    if is_player(defender) then
        defense_multiplier = defense_multiplier * (stance_mod.defense or 1.0)
    elseif stance ~= "balanced" then
        defense_multiplier = defense_multiplier * (stance_mod.defense or 1.0)
    end

    base_force = base_force * defense_multiplier
    if base_force <= 0 then
        result.severity = M.SEVERITY.DEFLECT
        result.zone = select_zone(defender and defender.body_tree, target_zone, light, accuracy)
        result.tissue_hit = defender and defender.body_tree
            and defender.body_tree[result.zone]
            and defender.body_tree[result.zone].tissue
            and defender.body_tree[result.zone].tissue[1]
        result.material_name = weapon_material
        result.action_verb = weapon and weapon.combat and weapon.combat.message or "hits"
        result.light = light
        return result
    end

    local zone = select_zone(defender and defender.body_tree, target_zone, light, accuracy)
    local zone_info = defender and defender.body_tree and defender.body_tree[zone] or nil
    local layers = zone_info and zone_info.tissue or { "flesh" }

    local deepest = nil
    if weapon_type == "edged" or weapon_type == "pierce" then
        local edge_force = base_force * (mat.max_edge or 1)
        for _, layer in ipairs(layers) do
            local layer_mat = get_material(layer)
            edge_force = edge_force - ((layer_mat.hardness or 1) * THICKNESS)
            if edge_force > 0 then
                deepest = layer
            else
                break
            end
        end
    else
        local remaining = base_force
        for _, layer in ipairs(layers) do
            local layer_mat = get_material(layer)
            local transfer = remaining * (1.0 - (layer_mat.flexibility or 0))
            local layer_damage = transfer - ((layer_mat.hardness or 1) * THICKNESS * 0.5)
            if layer_damage > 0 then
                deepest = layer
            end
            remaining = transfer * 0.8
            if remaining <= 0 then break end
        end
    end

    result.zone = zone
    result.tissue_hit = deepest or layers[1]
    result.severity = map_severity(deepest)
    result.material_name = weapon_material
    result.action_verb = weapon and weapon.combat and weapon.combat.message or "hits"
    result.light = light
    return result
end

function M.resolve_exchange(attacker, defender, weapon, target_zone, response, opts)
    local attack_action = M.declare(attacker, weapon, target_zone, opts)
    local defense_action = M.respond(defender, response, opts)
    local result = resolve_damage(attacker, defender, attack_action.weapon, attack_action.target_zone, defense_action.type, opts)

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

    local update_result = M.update(result, opts)
    if update_result then
        for k, v in pairs(update_result) do result[k] = v end
    end

    return result
end

function M.resolve(attacker, defender, weapon, target_zone, response, opts)
    return resolve_damage(attacker, defender, normalize_weapon(weapon), target_zone, response, opts)
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

-- C11: Map combat severity to injury type for the injury subsystem
local SEVERITY_INJURY_MAP = {
    edged = {
        [1] = "minor-cut",       -- GRAZE
        [2] = "bleeding",        -- HIT
        [3] = "bleeding",        -- SEVERE
        [4] = "bleeding",        -- CRITICAL
    },
    pierce = {
        [1] = "minor-cut",
        [2] = "bleeding",
        [3] = "bleeding",
        [4] = "bleeding",
    },
    blunt = {
        [1] = "bruised",
        [2] = "bruised",
        [3] = "crushing-wound",
        [4] = "crushing-wound",
    },
}

local function map_severity_to_injury(severity, weapon_type)
    if not severity or severity <= 0 then return nil end
    local wtype = weapon_type or "blunt"
    if wtype == "slash" then wtype = "edged" end
    local map = SEVERITY_INJURY_MAP[wtype] or SEVERITY_INJURY_MAP.blunt
    return map[severity] or "bruised"
end

function M.update(result, _opts)
    local defender = result.defender
    if not defender or not defender.health then return result end

    local damage_map = {
        [M.SEVERITY.DEFLECT] = 0,
        [M.SEVERITY.GRAZE] = 1,
        [M.SEVERITY.HIT] = 3,
        [M.SEVERITY.SEVERE] = 6,
        [M.SEVERITY.CRITICAL] = 10,
    }
    local damage = damage_map[result.severity or M.SEVERITY.DEFLECT] or 0
    defender.health = math.max(0, defender.health - damage)
    result.damage = damage
    result.target_health = defender.health

    -- C11: Inflict injury via the injury subsystem when damage lands
    if injuries and damage > 0 and defender.injuries then
        local weapon = result.weapon
        local weapon_type = weapon and weapon.combat and weapon.combat.type or "blunt"
        local injury_type = map_severity_to_injury(result.severity, weapon_type)
        if injury_type then
            local source = weapon and weapon.id or "unknown"
            local zone = result.zone
            pcall(injuries.inflict, defender, injury_type, source, zone, damage)
            result.injury_type = injury_type
        end
    end

    -- C12: Creature death mutation
    if defender.health <= 0 then
        defender._state = "dead"
        defender.animate = false
        defender.portable = true
        defender.alive = false
        result.defender_dead = true

        -- Pull death description from creature's dead state definition
        local dead_state = defender.states and defender.states.dead
        if dead_state then
            if dead_state.room_presence then
                defender.room_presence = dead_state.room_presence
            end
            result.death_narration = dead_state.description
                or (defender.name and (defender.name .. " is dead."))
                or "The creature is dead."
        else
            result.death_narration = (defender.name and (defender.name .. " is dead."))
                or "The creature is dead."
        end
    end

    return result
end

function M.interrupt_check(result, combat_state)
    if not combat_state then return nil end
    if result.weapon_broke then return "weapon_break" end
    if result.armor_failed then return "armor_fail" end
    if result.severity == M.SEVERITY.DEFLECT then
        combat_state.deflect_streak = (combat_state.deflect_streak or 0) + 1
    else
        combat_state.deflect_streak = 0
    end
    if (combat_state.deflect_streak or 0) >= 2 then
        return "stance_ineffective"
    end
    return nil
end

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
