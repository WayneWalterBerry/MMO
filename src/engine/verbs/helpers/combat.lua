-- engine/verbs/helpers/combat.lua
-- Self-infliction and FSM verb helpers.

local core = require("engine.verbs.helpers.core")
local search = require("engine.verbs.helpers.search")
local inventory = require("engine.verbs.helpers.inventory")

local M = {}

---------------------------------------------------------------------------
-- Self-infliction: shared logic for stab/cut/slash self
---------------------------------------------------------------------------
local BODY_AREA_WEIGHTS = {
    { area = "left arm",   weight = 3 },
    { area = "right arm",  weight = 3 },
    { area = "left hand",  weight = 2 },
    { area = "right hand", weight = 2 },
    { area = "left leg",   weight = 2 },
    { area = "right leg",  weight = 2 },
    { area = "torso",      weight = 1 },
    { area = "stomach",    weight = 1 },
}
local BODY_AREA_TOTAL_WEIGHT = 16

local BODY_AREA_DAMAGE_MODS = {
    ["left arm"]   = 1.0, ["right arm"]  = 1.0,
    ["left hand"]  = 1.0, ["right hand"] = 1.0,
    ["left leg"]   = 1.0, ["right leg"]  = 1.0,
    ["torso"]      = 1.5, ["stomach"]    = 1.5,
    ["head"]       = 2.0,
}

-- Body area aliases the parser recognizes
local BODY_AREA_ALIASES = {
    ["arm"]      = "left arm",
    ["hand"]     = "left hand",
    ["leg"]      = "left leg",
    ["left arm"] = "left arm",  ["right arm"]  = "right arm",
    ["left hand"]= "left hand", ["right hand"] = "right hand",
    ["left leg"] = "left leg",  ["right leg"]  = "right leg",
    ["torso"]    = "torso",     ["chest"]      = "torso",   ["side"] = "torso",
    ["stomach"]  = "stomach",   ["belly"]      = "stomach", ["gut"]  = "stomach",
    ["head"]     = "head",      ["forehead"]   = "head",    ["face"] = "head",
}

local function random_body_area()
    local roll = math.random(1, BODY_AREA_TOTAL_WEIGHT)
    local acc = 0
    for _, entry in ipairs(BODY_AREA_WEIGHTS) do
        acc = acc + entry.weight
        if roll <= acc then return entry.area end
    end
    return "left arm"
end

-- Parse self-infliction noun into body_area and weapon keyword
-- Returns: is_self, body_area_or_nil, weapon_kw_or_nil
local function parse_self_infliction(noun)
    if noun == nil then noun = "" end
    local target_part, tool_word = noun:match("^(.+)%s+with%s+(.+)$")
    if not target_part then target_part = noun; tool_word = nil end

    -- Strip possessive prefix ("my", "your")
    local cleaned = target_part:lower():gsub("^my%s+", ""):gsub("^your%s+", "")

    -- Check if targeting self or a body part
    if cleaned == "self" or cleaned == "myself" or cleaned == "me"
        or cleaned == "yourself" or cleaned == "you" or cleaned == "" then
        return true, nil, tool_word
    end

    -- Check if it's a recognized body area
    local area = BODY_AREA_ALIASES[cleaned]
    if area then
        return true, area, tool_word
    end

    return false, nil, tool_word
end

local function handle_self_infliction(ctx, noun, verb_name, profile_field)
    if noun == "" then
        print(verb_name:sub(1,1):upper() .. verb_name:sub(2) .. " what?")
        return true
    end

    local is_self, body_area, tool_word = parse_self_infliction(noun)
    if not is_self then return false end

    -- Find weapon
    local weapon = nil
    if tool_word then
        weapon = search.find_in_inventory(ctx, tool_word)
        if not weapon then
            print("You don't have " .. tool_word .. ".")
            return true
        end
    else
        -- Search hands for any item with the right damage profile
        local candidates = {}
        for i = 1, 2 do
            local hand = ctx.player.hands[i]
            if hand then
                local obj = inventory._hobj(hand, ctx.registry)
                if obj and obj[profile_field] then
                    candidates[#candidates + 1] = obj
                end
            end
        end
        if #candidates == 0 then
            print("You have nothing sharp to " .. verb_name .. " with.")
            return true
        elseif #candidates > 1 then
            local names = {}
            for _, c in ipairs(candidates) do names[#names + 1] = c.name or c.id end
            print(verb_name:sub(1,1):upper() .. verb_name:sub(2) .. " yourself with what? You're holding " .. table.concat(names, " and ") .. ".")
            return true
        end
        weapon = candidates[1]
    end

    -- Validate weapon has the right profile
    local profile = weapon[profile_field]
    if not profile then
        print("You can't " .. verb_name .. " yourself with " .. (weapon.name or "that") .. ".")
        return true
    end

    -- Resolve body area
    if not body_area then
        body_area = random_body_area()
    end

    -- Apply body area damage modifier
    local base_damage = profile.damage or 5
    local modifier = BODY_AREA_DAMAGE_MODS[body_area] or 1.0
    local effective_damage = math.floor(base_damage * modifier)

    -- Inflict the injury — route through effects pipeline when available (#66)
    local source = "self-inflicted (" .. (weapon.id or "weapon") .. ", " .. verb_name .. ")"
    local instance = nil

    if weapon.effects_pipeline and profile.pipeline_effects then
        -- Build contextualized effect list with body_area and damage overrides
        local fx_list = {}
        for _, fx in ipairs(profile.pipeline_effects) do
            local copy = {}
            for k, v in pairs(fx) do copy[k] = v end
            copy.damage = effective_damage
            copy.location = body_area
            copy.source = source
            -- Substitute body area in message
            if copy.message then
                copy.message = string.format(copy.message, body_area)
            end
            fx_list[#fx_list + 1] = copy
        end
        local fx_ctx = { player = ctx.player, registry = ctx.registry, source = weapon }
        -- Suppress default infliction messages — we print our own narration
        local old_print = _G.print
        local _captured = {}
        _G.print = function(...) _captured[#_captured + 1] = table.pack(...) end
        core.effects.process(fx_list, fx_ctx)
        _G.print = old_print
        -- Check if injury was created
        if ctx.player.injuries then
            for _, inj in ipairs(ctx.player.injuries) do
                if inj.source == source then
                    instance = inj
                end
            end
        end
        if fx_ctx.game_over then ctx.game_over = true end
    else
        -- Legacy direct path (weapons without pipeline_effects)
        local inj_ok, injury_mod = pcall(require, "engine.injuries")
        if not inj_ok then
            print("Something goes wrong.")
            return true
        end
        local _captured = {}
        local old_print = _G.print
        _G.print = function(...) _captured[#_captured + 1] = true end
        instance = injury_mod.inflict(ctx.player, profile.injury_type, source, body_area, effective_damage)
        _G.print = old_print
    end

    if not instance then
        print("The wound doesn't take hold.")
        return true
    end

    -- Set bloody state
    ctx.player.state = ctx.player.state or {}
    ctx.player.state.bloody = true
    ctx.player.state.bleed_ticks = 10

    -- Print the weapon's description with body area substituted
    if profile.description then
        print(string.format(profile.description, body_area))
    else
        print("You " .. verb_name .. " your " .. body_area .. " with " .. (weapon.name or "the weapon") .. ".")
    end

    return true
end

---------------------------------------------------------------------------
-- try_fsm_verb: Execute an FSM transition on an object for a given verb.
-- Returns true if a matching transition was found and executed.
-- Processes pipeline_effects (injuries, narration, mutations) through
-- the effects pipeline, including unconsciousness triggers.
-- NOTE: Does NOT mutate obj._state directly — FSM state management is
-- handled by the game loop via fsm_mod.transition in live play.
-- This function only evaluates the transition and routes its effects.
---------------------------------------------------------------------------
local function try_fsm_verb(ctx, obj, verb)
    if not obj or not obj.states or not obj.transitions then return false end

    local matched = nil
    for _, t in ipairs(obj.transitions) do
        if t.from == (obj._state or obj.initial_state) and t.trigger ~= "auto" then
            if t.verb == verb then
                matched = t
                break
            end
            if t.aliases then
                for _, a in ipairs(t.aliases) do
                    if a == verb then matched = t; break end
                end
                if matched then break end
            end
        end
    end

    if not matched then return false end

    -- Print transition message
    if matched.message and matched.message ~= "" then
        print(matched.message)
    end

    -- Process effects through the pipeline (injuries, unconsciousness, etc.)
    local fx = matched.pipeline_effects or matched.effect
    if fx and ctx.player then
        core.effects.process(fx, {
            player = ctx.player,
            source = obj,
            source_id = obj.id,
            registry = ctx.registry,
            time_offset = ctx.time_offset or 0,
        })
    end

    return true
end

M.random_body_area = random_body_area
M.parse_self_infliction = parse_self_infliction
M.handle_self_infliction = handle_self_infliction
M.try_fsm_verb = try_fsm_verb

return M
