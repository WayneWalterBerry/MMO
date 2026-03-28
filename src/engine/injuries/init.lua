-- engine/injuries.lua
-- Injury engine: infliction, per-turn ticking, health computation, healing.
-- Health is derived: max_health - sum(injury.damage for active injuries).
--
-- Ownership: Bart (Architect)

local injuries = {}

local SECONDS_PER_TICK = 360

-- Forward declaration for stress system (WAVE-3)
local _stress_def = nil
local load_stress_def  -- forward declaration; defined in stress section

---------------------------------------------------------------------------
-- Injury definition loader
---------------------------------------------------------------------------
local _cache = {}

function injuries.load_definition(injury_type)
    if _cache[injury_type] then return _cache[injury_type] end
    local ok, def = pcall(require, "meta.injuries." .. injury_type)
    if ok and def then
        _cache[injury_type] = def
        return def
    end
    return nil
end

-- Allow tests to inject definitions without filesystem access
function injuries.register_definition(injury_type, def)
    _cache[injury_type] = def
end

function injuries.clear_cache()
    _cache = {}
    _stress_def = nil
end

---------------------------------------------------------------------------
-- Health computation (derived — never stored)
---------------------------------------------------------------------------
function injuries.compute_health(player)
    local total_damage = 0
    for _, injury in ipairs(player.injuries or {}) do
        total_damage = total_damage + (injury.damage or 0)
    end
    return math.max(0, (player.max_health or 100) - total_damage)
end

---------------------------------------------------------------------------
-- Instance ID generation
---------------------------------------------------------------------------
local _next_id = 0
local function next_instance_id(injury_type)
    _next_id = _next_id + 1
    return injury_type .. "-" .. _next_id
end

-- Allow tests to reset
function injuries.reset_id_counter()
    _next_id = 0
end

---------------------------------------------------------------------------
-- Text interpolation: replace {key} placeholders with context values.
-- Used by injury templates that declare {source}, {location}, etc.
-- Falls back to definition's interpolation_defaults, then raw key name.
---------------------------------------------------------------------------
local function readable_source(source_id)
    if not source_id or source_id == "" or source_id == "unknown" then
        return nil
    end
    return source_id:gsub("%-", " ")
end

function injuries.interpolate(text, vars)
    if not text then return nil end
    if not vars then return text end
    return (text:gsub("{(%w+)}", function(key)
        return vars[key] or key
    end))
end

local function build_interp_vars(instance, def)
    local defaults = def and def.interpolation_defaults or {}
    return {
        location = instance.location or defaults.location or "body",
        source = readable_source(instance.source) or defaults.source or "something",
    }
end

---------------------------------------------------------------------------
-- Compute initial state_turns_remaining from definition state metadata.
-- Supports both `duration` (direct turn count) and `timed_events` (seconds).
---------------------------------------------------------------------------
local function compute_state_turns(state_def)
    if not state_def then return nil end
    if state_def.duration then return state_def.duration end
    if state_def.timed_events and state_def.timed_events[1] then
        local delay = state_def.timed_events[1].delay
        if delay and delay > 0 then
            return math.ceil(delay / SECONDS_PER_TICK)
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Inflict an injury on the player
-- @param player table
-- @param injury_type string
-- @param source string           — e.g. "silver-dagger"
-- @param location string|nil     — body area, e.g. "left arm"
-- @param override_damage number|nil — weapon-supplied damage overrides def
---------------------------------------------------------------------------
function injuries.inflict(player, injury_type, source, location, override_damage)
    local def = injuries.load_definition(injury_type)
    if not def then
        print("Unknown injury type: " .. tostring(injury_type))
        return nil
    end

    local on_inflict = def.on_inflict or {}
    local initial_dmg = override_damage or on_inflict.initial_damage or 0
    local instance = {
        id = next_instance_id(injury_type),
        type = injury_type,
        _state = def.initial_state or "active",
        source = source or "unknown",
        location = location,
        turns_active = 0,
        damage = initial_dmg,
        damage_per_tick = on_inflict.damage_per_tick or 0,
    }

    -- Copy degenerative config if present
    if def.degenerative then
        instance.damage_per_tick = def.degenerative.base_damage or instance.damage_per_tick
    end

    -- Disease-specific initialization
    if def.category == "disease" then
        instance.category = "disease"
        if def.hidden_until_state then
            instance._hidden = true
            instance.hidden_until_state = def.hidden_until_state
        end
        local init_state_def = def.states and def.states[instance._state]
        instance.state_turns_remaining = compute_state_turns(init_state_def)
    end

    -- Self-infliction damage ceiling: never reduce health below 1
    if source and source:find("self%-inflicted") then
        local current_health = injuries.compute_health(player)
        if current_health - instance.damage < 1 then
            instance.damage = math.max(0, current_health - 1)
        end
    end

    player.injuries = player.injuries or {}
    player.injuries[#player.injuries + 1] = instance

    -- Print infliction message (interpolate placeholders from context)
    if on_inflict.message then
        local vars = build_interp_vars(instance, def)
        print(injuries.interpolate(on_inflict.message, vars))
    end

    return instance
end

---------------------------------------------------------------------------
-- Find injury by instance ID
---------------------------------------------------------------------------
function injuries.find_by_id(player, instance_id)
    for i, injury in ipairs(player.injuries or {}) do
        if injury.id == instance_id then
            return injury, i
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Find injury by type
---------------------------------------------------------------------------
function injuries.find_by_type(player, injury_type)
    for i, injury in ipairs(player.injuries or {}) do
        if injury.type == injury_type then
            return injury, i
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Per-turn injury tick
-- Returns: messages table, death flag
---------------------------------------------------------------------------
function injuries.tick(player)
    local messages = {}
    local died = false

    if not player.injuries or #player.injuries == 0 then
        return messages, false
    end

    -- Phase 1: Tick each active injury
    for _, injury in ipairs(player.injuries) do
        local def = injuries.load_definition(injury.type)
        if not def then goto continue_tick end

        local state_def = def.states and def.states[injury._state]
        if not state_def then goto continue_tick end

        -- Skip terminal states
        if state_def.terminal then goto continue_tick end

        -- Advance turn counter
        injury.turns_active = (injury.turns_active or 0) + 1

        -- Disease progression: decrement state_turns_remaining, transition
        if injury.category == "disease" and injury.state_turns_remaining then
            injury.state_turns_remaining = injury.state_turns_remaining - 1
            if injury.state_turns_remaining <= 0 then
                local transitioned = false
                for _, t in ipairs(def.transitions or {}) do
                    if t.from == injury._state and t.trigger == "auto"
                       and (t.condition == "duration_expired"
                            or t.condition == "timer_expired") then
                        injury._state = t.to
                        injury.turns_active = 0
                        -- Apply mutations from transition
                        if t.mutate then
                            for k, v in pairs(t.mutate) do
                                injury[k] = v
                            end
                        end
                        -- Check hidden_until_state visibility
                        local show_msg = true
                        if injury._hidden then
                            if injury._state == injury.hidden_until_state then
                                injury._hidden = false
                            else
                                show_msg = false
                            end
                        end
                        if show_msg and t.message then
                            local vars = build_interp_vars(injury, def)
                            messages[#messages + 1] = injuries.interpolate(t.message, vars)
                        end
                        -- Initialize state_turns_remaining for new state
                        local new_state_def = def.states and def.states[injury._state]
                        injury.state_turns_remaining = compute_state_turns(new_state_def)
                        -- Refresh state_def for subsequent checks this tick
                        state_def = new_state_def
                        transitioned = true
                        break
                    end
                end
                if not transitioned then
                    injury.state_turns_remaining = nil
                end
            end
        end

        -- Accumulate per-turn damage (over-time injuries)
        if injury.damage_per_tick and injury.damage_per_tick > 0 then
            injury.damage = injury.damage + injury.damage_per_tick
        end

        -- Degenerative scaling: increase damage_per_tick each turn
        if def.damage_type == "degenerative" and def.degenerative then
            local degen = def.degenerative
            injury.damage_per_tick = math.min(
                degen.max_damage or 999,
                (injury.damage_per_tick or 0) + (degen.increment or 0)
            )
        end

        -- Auto-healing: some injuries heal after N turns in their current state
        if state_def.auto_heal_turns and injury.turns_active >= state_def.auto_heal_turns then
            injury._state = "healed"
            local healed_state = def.states and def.states["healed"]
            if healed_state and healed_state.description then
                messages[#messages + 1] = healed_state.description
            end
            goto continue_tick
        end

        ::continue_tick::
    end

    -- Phase 2: Remove healed/terminal injuries
    local active = {}
    for _, injury in ipairs(player.injuries) do
        local def = injuries.load_definition(injury.type)
        local state_def = def and def.states and def.states[injury._state]
        if state_def and state_def.terminal then
            -- Check for death message on fatal states
            if injury._state == "fatal" and state_def.death_message then
                messages[#messages + 1] = state_def.death_message
            end
        else
            active[#active + 1] = injury
        end
    end
    player.injuries = active

    -- Phase 3: Check death
    local health = injuries.compute_health(player)
    if health <= 0 then
        -- Self-inflicted injuries alone cannot kill (design: ceiling on self-damage)
        local has_external = false
        for _, injury in ipairs(player.injuries) do
            if not injury.source or not injury.source:find("self%-inflicted") then
                has_external = true
                break
            end
        end
        if has_external then
            died = true
        end
    end

    return messages, died
end

---------------------------------------------------------------------------
-- Try to heal an injury with a healing object
-- Delegates to cure module
---------------------------------------------------------------------------
local cure = require("engine.injuries.cure")
cure.init(injuries)

injuries.try_heal = cure.try_heal

---------------------------------------------------------------------------
-- List injuries (for the `injuries` verb)
---------------------------------------------------------------------------
function injuries.list(player)
    local has_injuries = player.injuries and #player.injuries > 0
    local has_stress = (player.stress or 0) > 0
        and injuries.get_stress_level(player) ~= nil

    if not has_injuries and not has_stress then
        print("You feel fine. No injuries to speak of.")
        return
    end

    print("You examine yourself:")
    for _, injury in ipairs(player.injuries or {}) do
        -- Skip hidden diseases (not yet symptomatic)
        if injury._hidden then goto continue_list end

        local def = injuries.load_definition(injury.type)
        local state_def = def and def.states and def.states[injury._state]

        local name = (state_def and state_def.name) or (def and def.name) or injury.type
        local symptom = (state_def and state_def.symptom)
                     or (state_def and state_def.description)
                     or ""

        -- Interpolate placeholders in symptom/description text
        local vars = build_interp_vars(injury, def)
        symptom = injuries.interpolate(symptom, vars) or symptom

        local line = "  " .. name
        if injury.location then
            line = line .. " on your " .. injury.location
        end
        if symptom ~= "" then
            line = line .. " — " .. symptom
        end
        if injury.treatment then
            line = line .. " [treated]"
        end
        print(line)

        ::continue_list::
    end

    -- Stress (WAVE-3): show current stress level description
    if has_stress then
        local def = load_stress_def()
        local level_name = injuries.get_stress_level(player)
        if def and def.levels and level_name then
            for _, lvl in ipairs(def.levels) do
                if lvl.name == level_name then
                    print("  " .. lvl.description)
                    break
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Compute total health drain per tick from all untreated injuries
---------------------------------------------------------------------------
function injuries.compute_total_drain(player)
    local total_drain = 0
    for _, injury in ipairs(player.injuries or {}) do
        total_drain = total_drain + (injury.damage_per_tick or 0)
    end
    return total_drain
end

-- Delegate cure/healing functions to cure module
injuries.resolve_target = cure.resolve_target
injuries.format_injury_options = cure.format_injury_options
injuries.apply_treatment = cure.apply_treatment
injuries.remove_treatment = cure.remove_treatment
injuries.heal = cure.heal
injuries.apply_healing_interaction = cure.apply_healing_interaction
injuries.get_restrictions = cure.get_restrictions

---------------------------------------------------------------------------
-- Stress system (WAVE-3): psychological injury via accumulated trauma
-- Stress metadata lives in meta/injuries/stress.lua (Principle 8).
-- Narration owned by Smithers (UI Engineer).
---------------------------------------------------------------------------

load_stress_def = function()
    if _stress_def then return _stress_def end
    -- Check definition cache (supports test injection via register_definition)
    if _cache["stress"] then
        _stress_def = _cache["stress"]
        return _stress_def
    end
    local ok, def = pcall(require, "meta.injuries.stress")
    if ok and def then
        _stress_def = def
        return def
    end
    return nil
end

-- Allow tests to inject the stress definition
function injuries.register_stress_definition(def)
    _stress_def = def
end

function injuries.clear_stress_definition()
    _stress_def = nil
end

---------------------------------------------------------------------------
-- Stress narration tables (Smithers — WAVE-3)
---------------------------------------------------------------------------

local STRESS_TRIGGER_NARRATION = {
    witness_creature_death = "The sight of death shakes you.",
    near_death_combat      = "A wave of terror washes over you as death looms close.",
    witness_gore           = "The gore turns your stomach.",
}

local STRESS_LEVEL_NARRATION = {
    shaken      = "Your hands begin to tremble.",
    distressed  = "Your breathing quickens. Heart pounding.",
    overwhelmed = "Panic overwhelms you.",
}

---------------------------------------------------------------------------
-- Stress: level computation helpers
---------------------------------------------------------------------------

-- Compute stress level name from numeric stress value and definition.
local function compute_stress_level(stress_value, def)
    if not def or not def.levels then return nil end
    local current_level = nil
    for _, lvl in ipairs(def.levels) do
        if stress_value >= lvl.threshold then
            current_level = lvl.name
        end
    end
    return current_level
end

-- Return a copy of the effects table for a given stress level name.
local function get_level_effects(level_name, def)
    if not level_name or not def or not def.effects then return {} end
    local fx = def.effects[level_name]
    if not fx then return {} end
    local copy = {}
    for k, v in pairs(fx) do copy[k] = v end
    return copy
end

---------------------------------------------------------------------------
-- Stress API
---------------------------------------------------------------------------

-- Add stress from a trauma trigger.
-- Looks up trigger value from stress.lua metadata, adds to player.stress.
-- Prints trigger-specific narration and level-change narration.
function injuries.add_stress(player, trigger_name)
    local def = load_stress_def()
    if not def or not def.triggers then return end
    local amount = def.triggers[trigger_name]
    if not amount then return end

    local old_level = player.stress_level

    player.stress = (player.stress or 0) + amount

    -- Trigger narration
    local trigger_msg = STRESS_TRIGGER_NARRATION[trigger_name]
    if trigger_msg then
        print(trigger_msg)
    end

    -- Recompute level and effects
    local new_level = compute_stress_level(player.stress, def)
    player.stress_level = new_level
    player.stress_effects = get_level_effects(new_level, def)

    -- Level-change narration (only when crossing a new threshold)
    if new_level and new_level ~= old_level then
        local level_msg = STRESS_LEVEL_NARRATION[new_level]
        if level_msg then
            print(level_msg)
        end
    end
end

-- Return current stress level name based on accumulated stress vs thresholds.
-- Returns nil if stress is below the lowest threshold.
function injuries.get_stress_level(player)
    local def = load_stress_def()
    if not def or not def.levels then return nil end
    local stress = player.stress or 0
    return compute_stress_level(stress, def)
end

-- Return the effects table for the player's current stress level.
-- Returns empty table if no stress or below threshold.
function injuries.get_stress_effects(player)
    local def = load_stress_def()
    if not def or not def.effects then return {} end
    local level = injuries.get_stress_level(player)
    if not level then return {} end
    return get_level_effects(level, def)
end

-- Cure stress via rest. Accepts optional ctx for safe-room checking.
-- Checks ctx.room for hostile creatures; cures if safe.
function injuries.cure_stress(player, ctx)
    if not player or (player.stress or 0) <= 0 then return false end

    -- Check safe room via ctx.room creatures (test-compatible path)
    if ctx then
        local room = ctx.room
        if room and room.creatures then
            for _, creature in ipairs(room.creatures) do
                if creature.hostile and creature.alive ~= false then
                    return false
                end
            end
        end
    end

    player.stress = 0
    player.stress_level = nil
    player.stress_effects = {}

    print("With rest and safety, the panic slowly fades.")
    return true
end

-- Check if a room qualifies as "safe" for stress cure.
-- Q2 resolved: any room without hostile creatures is safe.
function injuries.is_safe_room(room, registry)
    if not room then return false end
    local creatures_ok, creatures_mod = pcall(require, "engine.creatures")
    if not creatures_ok or not creatures_mod then return true end
    local room_id = room.id or room
    if not registry then return true end
    local room_creatures = creatures_mod.get_creatures_in_room(registry, room_id)
    for _, c in ipairs(room_creatures) do
        if c.alive ~= false and c._state ~= "dead" and c._state ~= "fled" then
            local aggression = c.behavior and c.behavior.aggression or 0
            if aggression > 0 then return false end
        end
    end
    return true
end

return injuries
