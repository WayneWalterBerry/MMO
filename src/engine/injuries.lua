-- engine/injuries.lua
-- Injury engine: infliction, per-turn ticking, health computation, healing.
-- Health is derived: max_health - sum(injury.damage for active injuries).
--
-- Ownership: Bart (Architect)

local injuries = {}

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
-- Inflict an injury on the player
---------------------------------------------------------------------------
function injuries.inflict(player, injury_type, source)
    local def = injuries.load_definition(injury_type)
    if not def then
        print("Unknown injury type: " .. tostring(injury_type))
        return nil
    end

    local on_inflict = def.on_inflict or {}
    local instance = {
        id = next_instance_id(injury_type),
        type = injury_type,
        _state = def.initial_state or "active",
        source = source or "unknown",
        turns_active = 0,
        damage = on_inflict.initial_damage or 0,
        damage_per_tick = on_inflict.damage_per_tick or 0,
    }

    -- Copy degenerative config if present
    if def.degenerative then
        instance.damage_per_tick = def.degenerative.base_damage or instance.damage_per_tick
    end

    player.injuries = player.injuries or {}
    player.injuries[#player.injuries + 1] = instance

    -- Print infliction message
    if on_inflict.message then
        print(on_inflict.message)
    end

    return instance
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
        died = true
    end

    return messages, died
end

---------------------------------------------------------------------------
-- Try to heal an injury with a healing object
-- Returns: true if healed, false otherwise
---------------------------------------------------------------------------
function injuries.try_heal(player, healing_object, verb)
    local effect = healing_object["on_" .. verb]
    if not effect or not effect.cures then return false end

    -- Find matching active injury by exact type
    local injury, index = injuries.find_by_type(player, effect.cures)
    if not injury then
        print("You don't have that kind of injury.")
        return false
    end

    -- Validate via injury definition's healing_interactions
    local def = injuries.load_definition(injury.type)
    if def and def.healing_interactions then
        local interaction = def.healing_interactions[healing_object.id]
        if interaction and interaction.from_states then
            local valid = false
            for _, s in ipairs(interaction.from_states) do
                if s == injury._state then valid = true; break end
            end
            if not valid then
                print("It's too late for that to help.")
                return false
            end
        end
    end

    -- Apply healing
    if effect.transition_to then
        -- Partial healing: transition FSM, stop damage
        injury._state = effect.transition_to
        injury.damage_per_tick = 0
        injury.turns_active = 0  -- Reset for auto-heal timer in new state
    else
        -- Full cure: remove injury entirely
        table.remove(player.injuries, index)
    end

    -- Print healing message
    if effect.message then
        print(effect.message)
    end

    return true
end

---------------------------------------------------------------------------
-- List injuries (for the `injuries` verb)
---------------------------------------------------------------------------
function injuries.list(player)
    if not player.injuries or #player.injuries == 0 then
        print("You feel fine. No injuries to speak of.")
        return
    end

    print("You examine yourself:")
    for _, injury in ipairs(player.injuries) do
        local def = injuries.load_definition(injury.type)
        local state_def = def and def.states and def.states[injury._state]

        local name = (state_def and state_def.name) or (def and def.name) or injury.type
        local symptom = (state_def and state_def.symptom)
                     or (state_def and state_def.description)
                     or ""

        local line = "  " .. name
        if symptom ~= "" then
            line = line .. " — " .. symptom
        end
        print(line)
    end
end

return injuries
