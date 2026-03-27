-- engine/injuries.lua
-- Injury engine: infliction, per-turn ticking, health computation, healing.
-- Health is derived: max_health - sum(injury.damage for active injuries).
--
-- Ownership: Bart (Architect)

local injuries = {}

local SECONDS_PER_TICK = 360

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

    -- Print infliction message
    if on_inflict.message then
        print(on_inflict.message)
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
                            messages[#messages + 1] = t.message
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

    -- Disease curable_in guard: reject healing if current state is outside
    -- the allowed cure window
    local def = injuries.load_definition(injury.type)
    if def and def.curable_in then
        local in_window = false
        for _, s in ipairs(def.curable_in) do
            if s == injury._state then in_window = true; break end
        end
        if not in_window then
            print("The treatment has no effect.")
            return false
        end
    end

    -- Validate via injury definition's healing_interactions
    if not def then def = injuries.load_definition(injury.type) end
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
        -- Skip hidden diseases (not yet symptomatic)
        if injury._hidden then goto continue_list end

        local def = injuries.load_definition(injury.type)
        local state_def = def and def.states and def.states[injury._state]

        local name = (state_def and state_def.name) or (def and def.name) or injury.type
        local symptom = (state_def and state_def.symptom)
                     or (state_def and state_def.description)
                     or ""

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

---------------------------------------------------------------------------
-- Injury targeting: resolve player text to an injury instance
-- @param player table
-- @param target_str string|nil  — text after "to", e.g. "left arm stab wound"
-- @param cures_list table       — e.g. {"bleeding", "minor-cut"}
-- @return injury|nil, error_msg string
---------------------------------------------------------------------------
local function table_contains(t, val)
    for _, v in ipairs(t) do
        if v == val then return true end
    end
    return false
end

function injuries.resolve_target(player, target_str, cures_list)
    if not player.injuries or #player.injuries == 0 then
        return nil, "You don't have any injuries."
    end

    -- Filter to treatable injuries
    local treatable = {}
    for _, injury in ipairs(player.injuries) do
        if table_contains(cures_list, injury.type) and not injury.treatment then
            treatable[#treatable + 1] = injury
        end
    end

    if #treatable == 0 then
        return nil, "You don't have any injuries that would help."
    end

    -- Auto-target: if only one treatable injury and no target specified
    if target_str == nil or target_str == "" then
        if #treatable == 1 then
            return treatable[1], ""
        else
            return nil, injuries.format_injury_options(treatable)
        end
    end

    local normalized = target_str:lower()

    -- Priority 1: Exact instance ID
    for _, injury in ipairs(treatable) do
        if injury.id == target_str then
            return injury, ""
        end
    end

    -- Priority 2: Display name substring
    for _, injury in ipairs(treatable) do
        local def = injuries.load_definition(injury.type)
        local state_def = def and def.states and def.states[injury._state]
        if state_def and state_def.name and
           string.find(state_def.name:lower(), normalized, 1, true) then
            return injury, ""
        end
    end

    -- Priority 3: Body location substring
    for _, injury in ipairs(treatable) do
        if injury.location and
           string.find(injury.location:lower(), normalized, 1, true) then
            return injury, ""
        end
    end

    -- Priority 4: Injury type exact match
    for _, injury in ipairs(treatable) do
        if injury.type == normalized then
            return injury, ""
        end
    end

    -- Priority 5: Ordinal index
    local ordinal_map = {first = 1, second = 2, third = 3, fourth = 4, fifth = 5}
    local ordinal_index = ordinal_map[normalized] or tonumber(normalized)
    if ordinal_index and treatable[ordinal_index] then
        return treatable[ordinal_index], ""
    end

    return nil, "You don't see that injury. " .. injuries.format_injury_options(treatable)
end

function injuries.format_injury_options(treatable)
    local lines = {"Which injury? You have:"}
    for i, injury in ipairs(treatable) do
        local def = injuries.load_definition(injury.type)
        local state_def = def and def.states and def.states[injury._state]
        local state_name = (state_def and state_def.name) or injury.type
        local location = injury.location and (" (" .. injury.location .. ")") or ""
        lines[#lines + 1] = "  " .. i .. ". " .. state_name .. location
    end
    return table.concat(lines, "\n")
end

---------------------------------------------------------------------------
-- Treatment: apply a treatment object to an injury (dual binding)
-- @param player table
-- @param treatment_obj table  — bandage instance
-- @param injury table         — target injury instance
---------------------------------------------------------------------------
function injuries.apply_treatment(player, treatment_obj, injury)
    -- 1. Bind treatment → injury
    treatment_obj.applied_to = injury.id

    -- 2. Bind injury → treatment
    injury.treatment = {
        type = treatment_obj.id,
        item_id = treatment_obj.id,
        healing_boost = treatment_obj.healing_boost or 1,
    }

    -- 3. Transition bandage FSM: clean/soiled → applied
    treatment_obj._state = "applied"

    -- 4. Transition injury FSM if applicable
    local def = injuries.load_definition(injury.type)
    if def and def.healing_interactions then
        local interaction = def.healing_interactions[treatment_obj.id]
        if interaction and interaction.from_states then
            if table_contains(interaction.from_states, injury._state) then
                injury._state = interaction.transitions_to
                injury.damage_per_tick = 0
            end
        end
    end
end

---------------------------------------------------------------------------
-- Treatment: remove a treatment object from its attached injury
-- @param player table
-- @param treatment_obj table
-- @return boolean, string|nil
---------------------------------------------------------------------------
function injuries.remove_treatment(player, treatment_obj)
    if not treatment_obj.applied_to then
        return false, "That isn't applied to anything."
    end

    -- Find the injury this treatment is attached to
    local injury = injuries.find_by_id(player, treatment_obj.applied_to)
    if not injury then
        -- Injury healed while bandage was on — just clean up bandage side
        treatment_obj.applied_to = nil
        treatment_obj._state = "soiled"
        return true
    end

    -- Clear injury → treatment reference
    injury.treatment = nil

    -- If injury is still active, resume damage
    local def = injuries.load_definition(injury.type)
    if def then
        -- Revert to active state if currently treated
        if injury._state == "treated" then
            injury._state = "active"
        end
        local state_def = def.states and def.states[injury._state]
        if state_def and state_def.damage_per_tick then
            injury.damage_per_tick = state_def.damage_per_tick
        end
    end

    -- Clear treatment → injury reference
    treatment_obj.applied_to = nil

    -- Transition bandage FSM: applied → soiled
    treatment_obj._state = "soiled"

    return true
end

---------------------------------------------------------------------------
-- Direct disease healing: check curable_in before allowing cure
-- @param player table
-- @param injury_type string
-- @return true if healed, false otherwise
---------------------------------------------------------------------------
function injuries.heal(player, injury_type)
    local injury, index = injuries.find_by_type(player, injury_type)
    if not injury then
        print("You don't have that affliction.")
        return false
    end

    local def = injuries.load_definition(injury.type)
    if def and def.curable_in then
        local in_window = false
        for _, s in ipairs(def.curable_in) do
            if s == injury._state then in_window = true; break end
        end
        if not in_window then
            print("The treatment has no effect.")
            return false
        end
    end

    -- Cure: transition to healed and remove
    injury._state = "healed"
    injury.damage_per_tick = 0
    table.remove(player.injuries, index)
    return true
end

---------------------------------------------------------------------------
-- Get merged restriction set from all active injuries
-- @param player table
-- @return table — keys are restriction names, values are true
---------------------------------------------------------------------------
function injuries.get_restrictions(player)
    local restrictions = {}
    for _, injury in ipairs(player.injuries or {}) do
        local def = injuries.load_definition(injury.type)
        local state_def = def and def.states and def.states[injury._state]
        if state_def and state_def.restricts then
            for k, v in pairs(state_def.restricts) do
                if v then restrictions[k] = true end
            end
        end
    end
    return restrictions
end

return injuries
