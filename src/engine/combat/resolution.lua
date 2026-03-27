-- engine/combat/resolution.lua
-- Damage resolution: resolve_damage(), layer penetration, severity mapping,
-- update (health/injury application), interrupt_check.
--
-- Ownership: Bart (Architect) — split from combat/init.lua in Phase 3 WAVE-0.

local materials = require("engine.materials")
local presentation_ok, presentation = pcall(require, "engine.ui.presentation")
local injuries_ok, injuries = pcall(require, "engine.injuries")
if not injuries_ok then injuries = nil end
local npc_behavior_ok, npc_behavior = pcall(require, "engine.combat.npc-behavior")
if not npc_behavior_ok then npc_behavior = nil end

local R = {}

R.SEVERITY = {
    DEFLECT = 0,
    GRAZE = 1,
    HIT = 2,
    SEVERE = 3,
    CRITICAL = 4,
}

R.SIZE_MODIFIERS = {
    tiny = 0.5,
    small = 1.0,
    medium = 2.0,
    large = 4.0,
    huge = 8.0,
}

R.STANCE_MODIFIERS = {
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

function R.is_player(obj)
    return obj and (obj.id == "player" or obj.is_player == true)
end

local function size_modifier(combat)
    local size = combat and combat.size or "medium"
    return R.SIZE_MODIFIERS[size] or 1.0
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

function R.normalize_weapon(weapon)
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
            on_hit = weapon.on_hit,
            _natural_weapon = true,
        }
    end
    return weapon
end

function R.pick_weapon(attacker)
    if attacker and attacker.combat and attacker.combat.natural_weapons then
        local list = attacker.combat.natural_weapons
        if #list > 0 then
            return R.normalize_weapon(list[math.random(#list)])
        end
    end
    return R.normalize_weapon({
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
    if not layer then return R.SEVERITY.DEFLECT end
    if layer == "organ" then return R.SEVERITY.CRITICAL end
    if layer == "bone" then return R.SEVERITY.SEVERE end
    if layer == "flesh" then return R.SEVERITY.HIT end
    return R.SEVERITY.GRAZE
end

---------------------------------------------------------------------------
-- Core damage resolution: layer penetration + severity calculation
---------------------------------------------------------------------------
function R.resolve_damage(attacker, defender, weapon, target_zone, response, opts)
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
    local stance_mod = R.STANCE_MODIFIERS[stance] or R.STANCE_MODIFIERS.balanced

    -- NPC stance: if attacker is NPC, read combat.behavior via npc-behavior
    if not R.is_player(attacker) and npc_behavior then
        local npc_stance = npc_behavior.select_stance(attacker)
        if npc_stance and R.STANCE_MODIFIERS[npc_stance] then
            stance = npc_stance
            stance_mod = R.STANCE_MODIFIERS[npc_stance]
        end
    end

    local weapon_type = weapon and weapon.combat and weapon.combat.type or "blunt"
    if weapon_type == "slash" then weapon_type = "edged" end

    local weapon_force = weapon and weapon.combat and weapon.combat.force or 1
    local weapon_material = weapon and (weapon.material or weapon.combat and weapon.combat.material) or "flesh"
    local mat = get_material(weapon_material)
    local base_force = (mat.density or 1000) * size_modifier(attacker and attacker.combat) * weapon_force * FORCE_SCALE
    local accuracy = weapon_force >= 7 and 1.0 or 0.6

    if R.is_player(attacker) then
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
    if not response_type and not R.is_player(defender) and npc_behavior then
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
            result.severity = R.SEVERITY.DEFLECT
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

    if R.is_player(defender) then
        defense_multiplier = defense_multiplier * (stance_mod.defense or 1.0)
    elseif stance ~= "balanced" then
        defense_multiplier = defense_multiplier * (stance_mod.defense or 1.0)
    end

    base_force = base_force * defense_multiplier
    if base_force <= 0 then
        result.severity = R.SEVERITY.DEFLECT
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

---------------------------------------------------------------------------
-- Severity → injury type mapping
---------------------------------------------------------------------------
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

function R.map_severity_to_injury(severity, weapon_type)
    if not severity or severity <= 0 then return nil end
    local wtype = weapon_type or "blunt"
    if wtype == "slash" then wtype = "edged" end
    local map = SEVERITY_INJURY_MAP[wtype] or SEVERITY_INJURY_MAP.blunt
    return map[severity] or "bruised"
end

---------------------------------------------------------------------------
-- Update: apply damage to defender, inflict injuries, handle death
---------------------------------------------------------------------------
function R.update(result, _opts)
    local defender = result.defender
    if not defender or not defender.health then return result end

    local damage_map = {
        [R.SEVERITY.DEFLECT] = 0,
        [R.SEVERITY.GRAZE] = 1,
        [R.SEVERITY.HIT] = 3,
        [R.SEVERITY.SEVERE] = 6,
        [R.SEVERITY.CRITICAL] = 10,
    }
    local damage = damage_map[result.severity or R.SEVERITY.DEFLECT] or 0
    defender.health = math.max(0, defender.health - damage)
    result.damage = damage
    result.target_health = defender.health

    -- C11: Inflict injury via the injury subsystem when damage lands
    if injuries and damage > 0 and defender.injuries then
        local weapon = result.weapon
        local weapon_type = weapon and weapon.combat and weapon.combat.type or "blunt"
        local injury_type = R.map_severity_to_injury(result.severity, weapon_type)
        if injury_type then
            local source = weapon and weapon.id or "unknown"
            local zone = result.zone
            pcall(injuries.inflict, defender, injury_type, source, zone, damage)
            result.injury_type = injury_type
        end
    end

    -- Track 4C: on_hit disease delivery — severity >= HIT triggers weapon's
    -- on_hit effect (e.g. venom, rabies). Fully generic: no creature-specific
    -- code (Principle 8). Symmetric for player-vs-NPC and NPC-vs-NPC.
    if injuries and (result.severity or 0) >= R.SEVERITY.HIT then
        local weapon = result.weapon
        local on_hit = weapon and weapon.on_hit
        if on_hit and on_hit.inflict and on_hit.probability then
            if math.random() <= on_hit.probability then
                local source = weapon.id or "unknown"
                local zone = result.zone
                pcall(injuries.inflict, defender, on_hit.inflict, source, zone)
                result.disease_inflicted = on_hit.inflict
            end
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

---------------------------------------------------------------------------
-- Interrupt check: detect stance-ineffective streaks
---------------------------------------------------------------------------
function R.interrupt_check(result, combat_state)
    if not combat_state then return nil end
    if result.weapon_broke then return "weapon_break" end
    if result.armor_failed then return "armor_fail" end
    if result.severity == R.SEVERITY.DEFLECT then
        combat_state.deflect_streak = (combat_state.deflect_streak or 0) + 1
    else
        combat_state.deflect_streak = 0
    end
    if (combat_state.deflect_streak or 0) >= 2 then
        return "stance_ineffective"
    end
    return nil
end

return R
