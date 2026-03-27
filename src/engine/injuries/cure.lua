-- engine/injuries/cure.lua
-- Cure/healing logic: try_heal, resolve_target, apply_treatment, remove_treatment,
-- heal, get_restrictions. Split from injuries/init.lua in Phase 3 WAVE-0.
--
-- Ownership: Bart (Architect)

local cure = {}

-- Injected reference to parent injuries module (set via cure.init)
local injuries = nil

function cure.init(injuries_mod)
    injuries = injuries_mod
end

local function table_contains(t, val)
    for _, v in ipairs(t) do
        if v == val then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- Try to heal an injury with a healing object
-- Returns: true if healed, false otherwise
---------------------------------------------------------------------------
function cure.try_heal(player, healing_object, verb)
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
-- Injury targeting: resolve player text to an injury instance
-- @param player table
-- @param target_str string|nil  — text after "to", e.g. "left arm stab wound"
-- @param cures_list table       — e.g. {"bleeding", "minor-cut"}
-- @return injury|nil, error_msg string
---------------------------------------------------------------------------
function cure.resolve_target(player, target_str, cures_list)
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
            return nil, cure.format_injury_options(treatable)
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

    return nil, "You don't see that injury. " .. cure.format_injury_options(treatable)
end

function cure.format_injury_options(treatable)
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
function cure.apply_treatment(player, treatment_obj, injury)
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
function cure.remove_treatment(player, treatment_obj)
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
-- Metadata-driven cure: scan injuries for healing_interactions match
-- The injury definition declares what cures it (no disease-specific code).
-- @param player table
-- @param healing_object table — item being applied (needs .id)
-- @return boolean success, string|nil message
---------------------------------------------------------------------------
function cure.apply_healing_interaction(player, healing_object)
    if not player.injuries or #player.injuries == 0 then
        return false, "You don't have any injuries to treat."
    end

    local obj_id = healing_object and healing_object.id
    if not obj_id then return false, nil end

    for idx, injury in ipairs(player.injuries) do
        local def = injuries.load_definition(injury.type)
        if def and def.healing_interactions then
            local interaction = def.healing_interactions[obj_id]
            if interaction then
                -- Check if injury is in a curable state
                if interaction.from_states then
                    local valid = false
                    for _, s in ipairs(interaction.from_states) do
                        if s == injury._state then valid = true; break end
                    end
                    if not valid then
                        return false, interaction.reject_message
                            or "It's too late for that to help."
                    end
                end
                -- Transition to target state
                injury._state = interaction.transitions_to or "cured"
                injury.damage_per_tick = 0
                -- Remove fully cured injuries
                if injury._state == "cured" or injury._state == "healed" then
                    table.remove(player.injuries, idx)
                end
                return true, interaction.message
                    or "The treatment takes effect."
            end
        end
    end

    return false, "That doesn't seem to help with any of your injuries."
end

---------------------------------------------------------------------------
-- Direct disease healing: check curable_in before allowing cure
-- @param player table
-- @param injury_type string
-- @return true if healed, false otherwise
---------------------------------------------------------------------------
function cure.heal(player, injury_type)
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
function cure.get_restrictions(player)
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

return cure
