-- engine/player/appearance.lua
-- Player appearance subsystem: reads player state and composes a natural
-- language description for mirrors, "look at self", and future multiplayer.
-- Pure read → compose → return pipeline. Never modifies player state.
--
-- Ownership: Smithers (UI Engineer)

local appearance = {}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

--- Combine phrases into natural English with Oxford comma.
--- Deduplicates identical phrases (Issue #31: duplicate bruise text).
local function compose_natural(phrases)
    -- Deduplicate identical phrases
    local seen = {}
    local unique = {}
    for _, p in ipairs(phrases) do
        if not seen[p] then
            seen[p] = true
            unique[#unique + 1] = p
        end
    end
    phrases = unique

    if #phrases == 0 then return nil end
    if #phrases == 1 then return phrases[1] end
    if #phrases == 2 then return phrases[1] .. " and " .. phrases[2] end
    local last = table.remove(phrases)
    return table.concat(phrases, ", ") .. ", and " .. last
end

--- Get injuries at specific body locations.
local function get_injuries_at(player, locations)
    local matches = {}
    for _, injury in ipairs(player.injuries or {}) do
        if injury.location then
            local loc_lower = injury.location:lower()
            for _, pattern in ipairs(locations) do
                if loc_lower:find(pattern:lower(), 1, true) then
                    matches[#matches + 1] = injury
                    break
                end
            end
        end
    end
    return matches
end

--- Severity → adjective mapping.
local severity_adjectives = {
    minor    = { "small", "slight" },
    moderate = { "deep", "nasty" },
    severe   = { "grievous", "terrible" },
}

local function pick_severity_adjective(severity)
    local options = severity_adjectives[severity]
    if not options then return nil end
    return options[math.random(#options)]
end

--- Compose a natural injury phrase from structured data.
local function render_injury_phrase(injury)
    local adj = pick_severity_adjective(injury.severity)

    -- Determine injury noun based on type
    local noun_map = {
        bleeding = "gash",
        bruised  = "bruise",
        concussion = "bruise",
        burn     = "burn",
    }
    local noun = noun_map[injury.type] or "wound"

    local phrase = adj and (adj .. " " .. noun) or noun

    if injury.location then
        phrase = phrase .. " on your " .. injury.location
    end

    -- Treatment check
    if injury._state == "treated" or injury.treatment then
        phrase = phrase .. ", wrapped in a bandage"
    end

    return "a " .. phrase
end

--- Resolve object from ID or table.
local function resolve_obj(item, registry)
    if type(item) == "table" then return item end
    if type(item) == "string" and registry then
        local get = registry.get
        if get then return registry:get(item) end
    end
    return nil
end

---------------------------------------------------------------------------
-- Layer renderers
---------------------------------------------------------------------------

local function render_head(player, registry)
    local parts = {}

    -- Worn headgear
    if player.worn then
        for _, worn_id in ipairs(player.worn) do
            local obj = resolve_obj(worn_id, registry)
            if obj and (obj.wear_slot == "head" or obj.is_helmet) then
                if obj.appearance and obj.appearance.worn_description then
                    parts[#parts + 1] = obj.appearance.worn_description
                else
                    parts[#parts + 1] = (obj.name or "a helmet") .. " sits on your head"
                end
            end
        end
    end

    -- Head injuries
    local head_injuries = get_injuries_at(player, {"head", "face", "forehead", "scalp"})
    for _, injury in ipairs(head_injuries) do
        parts[#parts + 1] = render_injury_phrase(injury)
    end

    if #parts == 0 then return nil end
    return compose_natural(parts)
end

local function render_torso(player, registry)
    local parts = {}

    -- Worn torso armor/clothing
    if player.worn then
        for _, worn_id in ipairs(player.worn) do
            local obj = resolve_obj(worn_id, registry)
            if obj and obj.wear_slot == "torso" then
                if obj.appearance and obj.appearance.worn_description then
                    parts[#parts + 1] = obj.appearance.worn_description
                else
                    parts[#parts + 1] = "you are wearing " .. (obj.name or "something") .. " on your torso"
                end
            end
        end
    end

    -- Torso injuries
    local torso_injuries = get_injuries_at(player, {"torso", "chest", "ribs", "stomach", "side"})
    for _, injury in ipairs(torso_injuries) do
        parts[#parts + 1] = render_injury_phrase(injury)
    end

    if #parts == 0 then return nil end
    return compose_natural(parts)
end

local function render_arms(player, registry)
    local parts = {}

    -- Arm injuries
    local arm_injuries = get_injuries_at(player, {"left arm", "right arm", "arm"})
    for _, injury in ipairs(arm_injuries) do
        parts[#parts + 1] = render_injury_phrase(injury)
    end

    if #parts == 0 then return nil end
    return compose_natural(parts)
end

local function render_hands(player, registry)
    local parts = {}
    local hand_names = { "left", "right" }

    -- Held items
    for i, hand_slot in ipairs(player.hands or {}) do
        if hand_slot then
            local obj = resolve_obj(hand_slot, registry)
            if obj then
                parts[#parts + 1] = "your " .. hand_names[i] .. " hand grips " .. (obj.name or "something")
            else
                parts[#parts + 1] = "your " .. hand_names[i] .. " hand grips something"
            end
        end
    end

    -- Hand injuries
    local hand_injuries = get_injuries_at(player, {"hand", "fingers", "wrist"})
    for _, injury in ipairs(hand_injuries) do
        parts[#parts + 1] = render_injury_phrase(injury)
    end

    if #parts == 0 then return nil end
    return compose_natural(parts)
end

local function render_legs(player, registry)
    local parts = {}

    -- Leg injuries
    local leg_injuries = get_injuries_at(player, {"left leg", "right leg", "leg"})
    for _, injury in ipairs(leg_injuries) do
        parts[#parts + 1] = render_injury_phrase(injury)
    end

    if #parts == 0 then return nil end
    return compose_natural(parts)
end

local function render_feet(player, registry)
    local parts = {}

    -- Worn footwear
    if player.worn then
        for _, worn_id in ipairs(player.worn) do
            local obj = resolve_obj(worn_id, registry)
            if obj and obj.wear_slot == "feet" then
                if obj.appearance and obj.appearance.worn_description then
                    parts[#parts + 1] = obj.appearance.worn_description
                else
                    parts[#parts + 1] = (obj.name or "boots") .. " cover your feet"
                end
            end
        end
    end

    if #parts == 0 then return nil end
    return compose_natural(parts)
end

local function render_overall(player)
    local parts = {}

    -- Health-based pallor
    local inj_ok, injury_mod = pcall(require, "engine.injuries")
    local health = player.max_health or 100
    if inj_ok and injury_mod then
        health = injury_mod.compute_health(player)
    end
    local pct = health / (player.max_health or 100)

    if pct <= 0.25 then
        parts[#parts + 1] = "your skin is deathly pale, eyes sunken"
    elseif pct <= 0.50 then
        parts[#parts + 1] = "you look pale and unsteady"
    elseif pct <= 0.75 then
        parts[#parts + 1] = "you look a bit worn but standing"
    else
        parts[#parts + 1] = "you appear healthy and alert"
    end

    -- Global blood state
    if player.state and player.state.bloody then
        parts[#parts + 1] = "dried blood is visible on your skin and clothes"
    end

    if #parts == 0 then return nil end
    return compose_natural(parts)
end

---------------------------------------------------------------------------
-- Main API
---------------------------------------------------------------------------

--- Compose a natural language description of a player's appearance.
--- @param player table — player state table (hands, worn, injuries, max_health)
--- @param registry table|nil — object registry for resolving IDs
--- @return string — composed description (multi-sentence, natural English)
function appearance.describe(player, registry)
    -- Guard: unconscious player can't see their reflection
    if player.consciousness
       and (player.consciousness.state == "unconscious"
         or player.consciousness.state == "waking") then
        return "You can't examine yourself — you're unconscious."
    end

    local layers = {
        render_head,
        render_torso,
        render_arms,
        render_hands,
        render_legs,
        render_feet,
    }

    local phrases = {}
    for _, renderer in ipairs(layers) do
        local phrase = renderer(player, registry)
        if phrase then
            phrases[#phrases + 1] = phrase
        end
    end

    -- Overall health (separate — it's a summary, not a body part)
    local overall = render_overall(player)
    if overall then
        phrases[#phrases + 1] = overall
    end

    if #phrases == 0 then
        return "Your reflection shows an unremarkable figure in plain clothes, unharmed and unburdened."
    end

    -- Capitalize first letter of composed description
    local desc = table.concat(phrases, ". ")
    -- Issue #30: Capitalize first letter after every ". " separator
    desc = desc:gsub("%.%s+(%l)", function(c) return ". " .. c:upper() end)
    desc = desc:sub(1, 1):upper() .. desc:sub(2)
    if not desc:match("[%.!?]$") then desc = desc .. "." end

    return "In the mirror, you see: " .. desc
end

---------------------------------------------------------------------------
-- Test exports
---------------------------------------------------------------------------
appearance._render_head = render_head
appearance._render_torso = render_torso
appearance._render_arms = render_arms
appearance._render_hands = render_hands
appearance._render_legs = render_legs
appearance._render_feet = render_feet
appearance._render_overall = render_overall
appearance._get_injuries_at = get_injuries_at
appearance._render_injury_phrase = render_injury_phrase
appearance._compose_natural = compose_natural

return appearance
