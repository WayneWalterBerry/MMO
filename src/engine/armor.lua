-- engine/armor.lua
-- Armor before-effect interceptor. Reduces inflict_injury damage based on
-- worn items' materials, coverage, fit, and degradation state.
--
-- Ownership: Smithers (UI/Parser Engineer) — implementation
--            Bart (Architect) — design (D-ARMOR-SYSTEM)
--
-- Registration: armor.register(effects)  installs the before-interceptor.
-- The interceptor only touches effects with type == "inflict_injury".

local materials = require("engine.materials")

local armor = {}

---------------------------------------------------------------------------
-- Constants (from architecture doc §3.1)
---------------------------------------------------------------------------
local HARDNESS_WEIGHT   = 1.0
local FLEXIBILITY_WEIGHT = 1.0
local DENSITY_WEIGHT    = 0.5
local DENSITY_CAP       = 3000  -- kg/m³ — beyond this, density stops scaling

-- Fit multipliers (architecture doc §3.2)
local FIT_MULTIPLIER = {
    makeshift  = 0.5,
    fitted     = 1.0,
    masterwork = 1.2,
}

-- Degradation state → protection multiplier (architecture doc §5.2)
local STATE_MULTIPLIER = {
    intact    = 1.0,
    cracked   = 0.7,
    shattered = 0.0,
}

-- Degradation transitions
local DEGRADE_NEXT = {
    intact  = "cracked",
    cracked = "shattered",
}

-- Impact type → degradation multiplier (architecture doc §5.1)
local IMPACT_TYPE_FACTOR = {
    piercing = 0.5,
    slashing = 1.0,
    blunt    = 1.5,
}
local DEFAULT_IMPACT_FACTOR = 1.0

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

--- Calculate base protection from a material property table.
local function base_protection(mat)
    local hardness    = mat.hardness or 0
    local flexibility = mat.flexibility or 0
    local density     = mat.density or 0
    local density_factor = math.min(1.0, density / DENSITY_CAP)
    return hardness * HARDNESS_WEIGHT
         + flexibility * FLEXIBILITY_WEIGHT
         + density_factor * DENSITY_WEIGHT
end

--- Get the effective protection for a single worn item.
-- Returns 0 if the item has no valid material or is shattered.
local function item_protection(item)
    -- State check
    local state = item._state or "intact"
    local state_mult = STATE_MULTIPLIER[state]
    if not state_mult or state_mult == 0 then return 0 end

    -- Material lookup
    local mat = materials.get(item.material)
    if not mat then return 0 end

    -- Base from material
    local prot = base_protection(mat)

    -- Coverage (default 1.0)
    local coverage = item.coverage or 1.0
    prot = prot * coverage

    -- Fit multiplier (default "fitted" = 1.0)
    local fit = item.fit or "fitted"
    local fit_mult = FIT_MULTIPLIER[fit] or 1.0
    prot = prot * fit_mult

    -- Degradation state multiplier
    prot = prot * state_mult

    return prot
end

--- Check whether a worn item covers a given injury location.
-- Checks explicit `covers` array first, then falls back to
-- `wear.slot` or `wear_slot` for items that declare a single slot.
local function covers_location(item, location)
    -- Explicit covers array (highest priority)
    if item.covers then
        for _, loc in ipairs(item.covers) do
            if loc == location then return true end
        end
        return false
    end
    -- Fall back to wear.slot or wear_slot (single-slot items)
    local slot = (item.wear and item.wear.slot) or item.wear_slot
    if slot and slot == location then return true end
    return false
end

--- Build narration for armor absorbing damage.
local function narrate_absorption(item, reduction)
    if reduction <= 0 then return end
    local name = item.name or item.id or "your armor"
    if reduction >= 5 then
        print("Your " .. name .. " absorbs much of the blow.")
    else
        print("Your " .. name .. " absorbs some of the blow.")
    end
end

--- Remove an item from the player's worn list (by identity or id).
local function remove_from_worn(player, item)
    if not player or not player.worn then return end
    for i = #player.worn, 1, -1 do
        local worn = player.worn[i]
        if worn == item or (type(worn) == "table" and worn.id == item.id)
           or worn == item.id then
            table.remove(player.worn, i)
            return true
        end
    end
    return false
end

--- Check if an item's current state allows it to be worn.
-- Checks both the armor STATE_MULTIPLIER table (shattered = 0 → non-wearable)
-- and the item's FSM state definition (wearable = false → non-wearable).
-- Items without FSM states or degradation are assumed wearable.
function armor.is_wearable_state(item)
    if not item then return false end
    local state = item._state

    -- Check armor degradation: shattered = non-wearable
    if state and STATE_MULTIPLIER[state] == 0 then
        return false
    end

    -- Check FSM state definition for explicit wearable = false
    if state and item.states and item.states[state] then
        local state_def = item.states[state]
        if state_def.wearable == false then
            return false
        end
    end

    return true
end

--- Check if a worn item should be auto-unequipped due to non-wearable state.
-- Removes the item from player.worn if its state is non-wearable.
-- @return boolean removed, string|nil message
function armor.auto_unequip_check(player, item)
    if not player or not item then return false end
    if armor.is_wearable_state(item) then return false end

    local removed = remove_from_worn(player, item)
    if removed then
        local name = item.name or item.id or "your equipment"
        print("Your " .. name .. " falls away!")
        return true, "Your " .. name .. " falls away!"
    end
    return false
end

--- Check degradation and apply state transition.
-- @param player  table|nil  Player state for auto-unequip (optional for backward compat)
local function check_degradation(item, original_damage, impact_type, player)
    local state = item._state or "intact"
    local next_state = DEGRADE_NEXT[state]
    if not next_state then return end  -- already shattered or unknown

    local mat = materials.get(item.material)
    if not mat then return end

    local fragility = mat.fragility or 0
    if fragility <= 0 then return end  -- material never breaks

    local impact_factor = IMPACT_TYPE_FACTOR[impact_type] or DEFAULT_IMPACT_FACTOR
    local break_chance = fragility * (original_damage / 20) * impact_factor

    if math.random() < break_chance then
        item._state = next_state
        local name = item.name or item.id or "your armor"
        if next_state == "cracked" then
            print("Your " .. name .. " develops a hairline crack.")
        elseif next_state == "shattered" then
            print("Your " .. name .. " shatters and falls away!")
            if player then
                remove_from_worn(player, item)
            end
        end
    end
end

--- Degrade worn armor covering a given location (called by hit verb).
-- @param player       table   Player state (must have .worn)
-- @param location     string  Body location that was hit
-- @param damage       number  Original damage of the hit
-- @param impact_type  string  "blunt", "slashing", "piercing", or nil
function armor.degrade_covering_armor(player, location, damage, impact_type)
    local worn = player.worn
    if not worn or #worn == 0 then return end
    for _, item in ipairs(worn) do
        if type(item) == "table" and covers_location(item, location) then
            check_degradation(item, damage, impact_type, player)
        end
    end
end

---------------------------------------------------------------------------
-- Registration
---------------------------------------------------------------------------

--- Install the armor before-interceptor on the effects pipeline.
-- @param effects_module  The effects module (engine.effects)
function armor.register(effects_module)
    effects_module.add_interceptor("before", function(effect, ctx)
        -- Only intercept injury effects
        if effect.type ~= "inflict_injury" then return end
        if not effect.location then return end
        if not ctx or not ctx.player then return end

        local worn = ctx.player.worn
        if not worn or #worn == 0 then return end

        -- Gather worn items covering this injury location
        local covering = {}
        for _, item in ipairs(worn) do
            if covers_location(item, effect.location) then
                covering[#covering + 1] = item
            end
        end
        if #covering == 0 then return end

        -- Sum protection from all covering layers
        local total_protection = 0
        for _, item in ipairs(covering) do
            total_protection = total_protection + item_protection(item)
        end

        local original_damage = effect.damage
        local protection_int = math.floor(total_protection)

        -- Reduce damage (minimum 1 — armor never fully negates)
        if protection_int > 0 then
            effect.damage = math.max(1, effect.damage - protection_int)
        end

        -- Narrate
        local reduction = original_damage - effect.damage
        for _, item in ipairs(covering) do
            if item_protection(item) > 0 then
                narrate_absorption(item, reduction)
                break  -- one narration line is enough
            end
        end

        -- Degradation check per item
        local impact_type = effect.damage_type or nil
        for _, item in ipairs(covering) do
            check_degradation(item, original_damage, impact_type, ctx.player)
        end
    end)
end

return armor
