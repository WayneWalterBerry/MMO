local M = {}

local SEVERITY = {
    DEFLECT = 0,
    GRAZE = 1,
    HIT = 2,
    SEVERE = 3,
    CRITICAL = 4,
}

local function pick(list)
    return list[math.random(#list)]
end

local zone_words = {
    head = { "head", "skull", "cranium" },
    body = { "body", "torso", "flank", "side", "belly", "chest", "ribs" },
    torso = { "torso", "chest", "ribs", "gut" },
    arms = { "arm", "forearm", "shoulder" },
    hands = { "hand", "fingers", "knuckles" },
    legs = { "leg", "thigh", "shin", "knee", "haunch" },
    feet = { "foot", "ankle" },
    tail = { "tail", "tail" },
}

local tissue_words = {
    skin = "skin",
    hide = "hide",
    flesh = "flesh",
    bone = "bone",
    organ = "organ",
}

local function zone_text(zone, body_tree)
    if not zone then return "body" end
    -- #369/#337: Use creature-specific zone names when available (Principle 8)
    if body_tree and body_tree[zone] and body_tree[zone].names then
        return pick(body_tree[zone].names)
    end
    local list = zone_words[zone]
    if list then return pick(list) end
    return zone
end

local function tissue_text(tissue)
    if not tissue then return "flesh" end
    return tissue_words[tissue] or tissue:gsub("-", " ")
end

local function material_text(material_name)
    if not material_name then return "weapon" end
    -- #363: Use singular/mass-noun forms to avoid subject-verb disagreement
    if material_name == "tooth-enamel" then
        return pick({ "tooth", "tooth-enamel", "enamel", "fang" })
    end
    if material_name == "keratin" then
        return pick({ "keratin claws", "claws", "keratin" })
    end
    return material_name:gsub("-", " ")
end

local function actor_name(actor)
    -- #366: nil attacker in player-initiated combat defaults to "You"
    if not actor then return "You" end
    if actor.id == "player" or actor.is_player then return "You" end
    local name = actor.name or actor.id or "someone"
    if name:lower() == "you" then return "You" end
    return name:sub(1, 1):upper() .. name:sub(2)
end

local function possessive(name)
    if not name then return "their" end
    local lower = name:lower()
    if lower == "you" or lower == "the player" then return "your" end
    if name:sub(-1) == "s" then return name .. "'" end
    return name .. "'s"
end

local function action_verb(result)
    return result.action_verb
        or (result.weapon and result.weapon.combat and result.weapon.combat.message)
        or (result.weapon and result.weapon.message)
        or "hits"
end

local LIGHT_TEMPLATES = {
    [SEVERITY.DEFLECT] = {
        "{attacker} {verb} {target_possessive} {zone}, but the {material} glances off.",
        "The {material} skitters off {target_possessive} {zone} as {attacker} {verb}.",
        "{attacker} {verb} toward {target_possessive} {zone}; the {material} fails to bite.",
    },
    [SEVERITY.GRAZE] = {
        "{attacker} {verb} {target_possessive} {zone}, leaving a shallow mark in the {tissue}.",
        "The {material} edge nicks {target_possessive} {zone}, a thin line across the {tissue}.",
        "A quick strike across {target_possessive} {zone} scratches the {tissue}.",
    },
    [SEVERITY.HIT] = {
        "{attacker} {verb} into {target_possessive} {zone}, cutting into the {tissue}.",
        "The {material} bites at {target_possessive} {zone}, parting {tissue}.",
        "{attacker} drives the {material} into {target_possessive} {zone}, drawing blood from the {tissue}.",
    },
    [SEVERITY.SEVERE] = {
        "{attacker} hacks into {target_possessive} {zone}; the {tissue} cracks under the {material}.",
        "A brutal blow to {target_possessive} {zone} fractures the {tissue}.",
        "The {material} tears through {target_possessive} {zone}, splintering {tissue}.",
    },
    [SEVERITY.CRITICAL] = {
        "{attacker} plunges the {material} into {target_possessive} {zone}, hitting something vital.",
        "A devastating strike to {target_possessive} {zone} — the {tissue} gives way.",
        "{attacker} drives the {material} deep into {target_possessive} {zone}; a fatal wound opens.",
    },
}

local DARK_TEMPLATES = {
    [SEVERITY.DEFLECT] = {
        "You hear a sharp clack as the {material} glances off in the dark.",
        "A dull thud at {target_possessive} {zone}; the {material} doesn't bite.",
        "In the dark, a scrape and a miss — the {material} skitters away.",
    },
    [SEVERITY.GRAZE] = {
        "You feel a quick sting at {target_possessive} {zone}; a light scratch in the {tissue}.",
        "A faint rip and warmth on {target_possessive} {zone} — the {material} just grazes.",
        "In the dark you hear a soft hiss and feel a nick on {target_possessive} {zone}.",
    },
    [SEVERITY.HIT] = {
        "A wet thud and sharp pain in {target_possessive} {zone}; the {material} bites into {tissue}.",
        "You hear a crack and feel the {material} sink into {target_possessive} {zone}.",
        "A heavy impact on {target_possessive} {zone} — warm blood and torn {tissue}.",
    },
    [SEVERITY.SEVERE] = {
        "A sickening crunch from {target_possessive} {zone}; the {tissue} fractures.",
        "You hear bone snap as the {material} smashes {target_possessive} {zone}.",
        "A brutal crack and tearing sound — {target_possessive} {zone} is wrecked.",
    },
    [SEVERITY.CRITICAL] = {
        "A deep, wet squelch and a scream — the blow to {target_possessive} {zone} is fatal.",
        "In the dark, a violent crunch and sudden stillness at {target_possessive} {zone}.",
        "You hear a piercing shriek and feel the {material} drive deep; something vital gives way.",
    },
}

local function render(template, data)
    local text = template:gsub("{(.-)}", function(key)
        return data[key] or ""
    end)
    -- #290/#338: Collapse preposition overlap when verb phrase already ends
    -- with a preposition that clashes with the template's following preposition
    text = text:gsub("into into", "into")
    text = text:gsub("into toward", "toward")
    text = text:gsub("into at", "at")
    text = text:gsub("onto into", "into")
    text = text:gsub("onto toward", "toward")
    text = text:gsub("onto at", "at")
    text = text:gsub("across across", "across")
    text = text:gsub("across toward", "toward")
    return text
end

function M.generate(result, light)
    result = result or {}
    local severity = result.severity or SEVERITY.HIT
    local is_light = light ~= false
    local templates = is_light and LIGHT_TEMPLATES or DARK_TEMPLATES
    local list = templates[severity] or templates[SEVERITY.HIT]

    local defender = result.defender or {}
    local defender_name = defender.name or defender.id or "someone"

    local data = {
        attacker = actor_name(result.attacker),
        verb = action_verb(result),
        target_possessive = possessive(defender_name),
        zone = zone_text(result.zone, defender.body_tree),
        material = material_text(result.material_name or (result.weapon and result.weapon.material)),
        tissue = tissue_text(result.tissue_hit),
    }

    return render(pick(list), data)
end

M.narrate = M.generate

-- Expose SEVERITY for external use (budget logic, witness tests)
M.SEVERITY = SEVERITY

---------------------------------------------------------------------------
-- Witness narration — NPC-vs-NPC combat observed by the player
---------------------------------------------------------------------------

-- Third-person visual templates (same room + light)
local WITNESS_LIGHT_TEMPLATES = {
    [SEVERITY.DEFLECT] = {
        "{attacker} swipes at {defender}, but misses entirely.",
        "{attacker} lunges at {defender}; the blow glances harmlessly off.",
        "{defender} sidesteps as {attacker} strikes at empty air.",
    },
    [SEVERITY.GRAZE] = {
        "{attacker} scratches {defender} across the {zone}, barely drawing blood.",
        "{attacker} nicks {defender}'s {zone} with a light scratch.",
        "A quick swipe from {attacker} leaves a shallow mark on {defender}'s {zone}.",
    },
    [SEVERITY.HIT] = {
        "{attacker} strikes {defender} in the {zone}, drawing blood.",
        "{attacker} drives into {defender}'s {zone} with a solid hit.",
        "{attacker} lands a vicious blow to {defender}'s {zone}.",
    },
    [SEVERITY.SEVERE] = {
        "{attacker} savages {defender}'s {zone}; you hear bone crack.",
        "A brutal strike from {attacker} tears into {defender}'s {zone}.",
        "{attacker} smashes into {defender}'s {zone} with terrible force.",
    },
    [SEVERITY.CRITICAL] = {
        "{attacker} lunges at {defender}, claws extended — a killing blow to the {zone}.",
        "{attacker} drives deep into {defender}'s {zone}; {defender} crumples.",
        "A devastating strike from {attacker} to {defender}'s {zone} — the fight is over.",
    },
}

-- Audio-only templates (same room + dark)
local WITNESS_DARK_TEMPLATES = {
    [SEVERITY.DEFLECT] = {
        "You hear a brief scuffle nearby.",
        "Something shifts in the darkness — a scrape, then nothing.",
        "A quick shuffling sound nearby, then silence.",
    },
    [SEVERITY.GRAZE] = {
        "You hear a brief scuffle nearby.",
        "A small creature yelps softly in the darkness.",
        "You hear claws skitter across something in the dark.",
    },
    [SEVERITY.HIT] = {
        "Something yelps in pain in the darkness.",
        "You hear a wet thud and a yelp of pain in the dark.",
        "You hear a wet impact and a pained squeal nearby.",
    },
    [SEVERITY.SEVERE] = {
        "A terrible shriek pierces the darkness.",
        "You hear a sickening crunch in the dark, then whimpering.",
        "Something screams in agony nearby — bone snaps in the dark.",
    },
    [SEVERITY.CRITICAL] = {
        "A piercing shriek rips through the darkness, then silence.",
        "A violent thrashing in the dark ends with a final, wet crunch.",
        "A piercing shriek tears through the darkness, then nothing.",
    },
}

-- Adjacent room templates (distant audio, 1 line max)
local ADJACENT_TEMPLATES = {
    "You hear sounds of a struggle from the {direction}.",
    "Distant snarling and scuffling echo from the {direction}.",
    "Something fights in the {direction} — you hear muffled thuds.",
}

--- Generate third-person visual witness narration (same room + lit).
-- @param result  combat result table
-- @return string  narration text
local function witness_visual(result)
    result = result or {}
    local severity = result.severity or SEVERITY.HIT
    local list = WITNESS_LIGHT_TEMPLATES[severity] or WITNESS_LIGHT_TEMPLATES[SEVERITY.HIT]

    local attacker = result.attacker or {}
    local defender = result.defender or {}

    local data = {
        attacker = actor_name(attacker),
        defender = actor_name(defender),
        zone = zone_text(result.zone, defender.body_tree),
        material = material_text(result.material_name or (result.weapon and result.weapon.material)),
        tissue = tissue_text(result.tissue_hit),
    }

    return render(pick(list), data)
end

--- Generate audio-only witness narration (same room + dark).
-- @param result  combat result table
-- @return string  narration text
local function witness_dark(result)
    result = result or {}
    local severity = result.severity or SEVERITY.HIT
    local list = WITNESS_DARK_TEMPLATES[severity] or WITNESS_DARK_TEMPLATES[SEVERITY.HIT]
    return pick(list)
end

--- Generate distant narration for adjacent room combat.
-- @param direction  string direction label (e.g. "north", "above")
-- @return string  narration text
local function witness_adjacent(direction)
    local dir = direction or "nearby"
    local template = pick(ADJACENT_TEMPLATES)
    return render(template, { direction = dir })
end

--- Unified witness narration dispatcher.
-- Selects narration tier based on opts.light and opts.distance.
--
-- Called by tests as: describe_exchange(result, opts)
-- Called by Bart as:  describe_exchange(result, { light = bool, distance = str })
--
-- @param result  combat result table (attacker, defender, severity, zone, etc.)
-- @param opts    table  { light = bool, distance = "adjacent"|"out_of_range"|nil }
-- @return string|nil  narration text (nil for out-of-range)
function M.describe_exchange(result, opts)
    result = result or {}
    opts = opts or {}

    local distance = opts.distance
    if distance == "out_of_range" or distance == "distant" then
        return nil
    end

    if distance == "adjacent" then
        local direction = opts.direction or "nearby"
        return witness_adjacent(direction)
    end

    -- Same room: light-dependent
    if opts.light == false then
        return witness_dark(result)
    end
    return witness_visual(result)
end

-- Keep standalone helpers accessible for Bart's emit_witness pathway
M.describe_exchange_visual = witness_visual
M.describe_exchange_dark = witness_dark
M.describe_adjacent = witness_adjacent

---------------------------------------------------------------------------
-- Narration budget — caps NPC narration per combat round
---------------------------------------------------------------------------

--- Create a new budget tracker for one combat round.
-- @param cap  number  max NPC narration lines per round (default 6)
-- @return table  budget state object
function M.new_budget(cap)
    return { count = 0, cap = cap or 6, overflow_emitted = false }
end

M.create_budget = M.new_budget

-- Module-level budget for simple callers (reset_budget / get_budget)
local budget_state = M.new_budget(6)

--- Reset the module-level narration budget for a new combat round.
function M.reset_budget()
    budget_state.count = 0
    budget_state.overflow_emitted = false
end

--- Get current module-level budget state (for testing/inspection).
-- @return table  { count, cap, overflow_emitted }
function M.get_budget()
    return {
        count = budget_state.count,
        cap = budget_state.cap,
        overflow_emitted = budget_state.overflow_emitted,
    }
end

--- Check whether a narration line should be emitted under budget rules.
-- @param budget           table   budget state (count, cap, overflow_emitted)
-- @param severity         number  severity level from SEVERITY enum
-- @param is_player_combat boolean true if player's own fight (exempt)
-- @return boolean  true if the line should be emitted
local function budget_allows(budget, severity, is_player_combat)
    if is_player_combat then return true end
    if budget.count < budget.cap then return true end
    -- Over budget: only critical-tier narration (HIT+) passes
    if severity and severity >= SEVERITY.HIT then return true end
    return false
end

--- Emit a witness narration line, respecting the budget protocol.
--
-- Supports two calling conventions:
--   emit(result, budget, opts)  — budget-aware (test/engine API)
--   emit(text, severity, is_player_combat) — simple (legacy/internal)
--
-- @return string|nil  the line to show, or nil if suppressed
function M.emit(result_or_text, budget_or_severity, opts_or_player)
    -- Detect calling convention: budget-aware vs simple
    if type(result_or_text) == "table" then
        -- Budget-aware call: emit(result, budget, opts)
        local result = result_or_text
        local budget = budget_or_severity
        local opts = opts_or_player or {}

        if not budget or type(budget) ~= "table" then
            budget = budget_state
        end

        local severity = result.severity or SEVERITY.HIT
        local is_player_combat = opts.player_combat

        -- Generate text through describe_exchange
        local text = M.describe_exchange(result, opts)
        if not text then return nil end

        if not budget_allows(budget, severity, is_player_combat) then
            return nil
        end

        if not is_player_combat then
            budget.count = budget.count + 1
        end

        return text
    else
        -- Simple call: emit(text, severity, is_player_combat)
        local text = result_or_text
        local severity = budget_or_severity
        local is_player_combat = opts_or_player

        if not text then return nil end

        if not budget_allows(budget_state, severity, is_player_combat) then
            return nil
        end

        if not is_player_combat then
            budget_state.count = budget_state.count + 1
        end

        return text
    end
end

--- Returns overflow marker text if budget was exceeded this round.
-- Call after a full combat round to display the deferred indicator.
-- @param budget  table  budget state (optional, uses module-level if nil)
-- @return string|nil  "[The melee continues...]" if overflow occurred, nil otherwise
function M.overflow_text(budget)
    local b = budget or budget_state
    if b.count >= b.cap and not b.overflow_emitted then
        b.overflow_emitted = true
        return "[The melee continues...]"
    end
    return nil
end

---------------------------------------------------------------------------
-- Unified witness dispatcher — called by combat engine per exchange
---------------------------------------------------------------------------

--- Determine proximity tier between the player and a combat room.
-- @param player_room_id  string  the room the player is currently in
-- @param combat_room_id  string  the room where combat is happening
-- @param exits           table   exits table from the player's current room
-- @return string  "same", "adjacent", or "distant"
function M.proximity(player_room_id, combat_room_id, exits)
    if not player_room_id or not combat_room_id then return "distant" end
    if player_room_id == combat_room_id then return "same" end
    if exits then
        for _, exit in pairs(exits) do
            local target = type(exit) == "table" and exit.target or exit
            if target == combat_room_id then return "adjacent" end
        end
    end
    return "distant"
end

--- Find the direction label for an adjacent room exit.
-- @param exits           table   exits from the player's room
-- @param combat_room_id  string  the room where combat is happening
-- @return string  direction label (e.g. "north") or "nearby"
local function find_direction(exits, combat_room_id)
    if not exits or not combat_room_id then return "nearby" end
    for dir, exit in pairs(exits) do
        local target = type(exit) == "table" and exit.target or exit
        if target == combat_room_id then return dir end
    end
    return "nearby"
end

--- Generate witness narration for NPC combat based on proximity and light.
-- Full-context entry point for Bart's combat engine integration.
--
-- @param result           table   combat result (attacker, defender, severity, zone, etc.)
-- @param player_room_id   string  current room of the player
-- @param combat_room_id   string  room where the combat occurs
-- @param light            boolean whether the player's room is lit
-- @param exits            table   exits from the player's current room
-- @param is_player_combat boolean true if the player is a combatant
-- @return string|nil      narration text to display (nil = nothing to show)
function M.emit_witness(result, player_room_id, combat_room_id, light, exits, is_player_combat)
    result = result or {}
    local prox = M.proximity(player_room_id, combat_room_id, exits)

    if prox == "distant" then
        return nil
    end

    local severity = result.severity or SEVERITY.HIT
    local text

    if prox == "same" then
        if light then
            text = witness_visual(result)
        else
            text = witness_dark(result)
        end
    elseif prox == "adjacent" then
        local direction = find_direction(exits, combat_room_id)
        text = witness_adjacent(direction)
    end

    -- Use simple emit with module-level budget
    return M.emit(text, severity, is_player_combat)
end

--- Emit a morale break narration line (counts toward budget).
-- @param creature_name  string  name of the fleeing creature
-- @param direction      string  direction it flees toward (optional)
-- @param light          boolean whether the room is lit
-- @return string|nil    narration text or nil if suppressed
function M.emit_morale_break(creature_name, direction, light)
    local name = creature_name or "Something"
    local text
    if light then
        if direction then
            text = name .. " panics and bolts " .. direction .. "!"
        else
            text = name .. " panics and flees!"
        end
    else
        if direction then
            text = "You hear something scramble away to the " .. direction .. "."
        else
            text = "You hear something scramble away in the dark."
        end
    end
    return M.emit(text, SEVERITY.GRAZE, false)
end

---------------------------------------------------------------------------
-- Combat sound propagation narration API (WAVE-4)
---------------------------------------------------------------------------

--- Emit combat sound narration for the player based on distance from combat.
-- Same room: nil (combat narration already covers it).
-- Adjacent room: directional sound text.
-- 2+ exits away: nil (sound doesn't propagate that far).
--
-- @param room       string  room id where combat occurs
-- @param intensity  number  0-10 scale (unarmed=3, weapon=6, death=8)
-- @param witness_text string template override (unused in Phase 3; reserved)
-- @param opts       table   { player_room_id, exits, light }
-- @return string|nil  narration text for the player
function M.emit_combat_sound(room, intensity, witness_text, opts)
    opts = opts or {}
    local prox = M.proximity(opts.player_room_id, room, opts.exits)

    if prox == "same" then return nil end
    if prox == "distant" then return nil end

    -- Adjacent: directional sound narration
    local direction = find_direction(opts.exits, room)
    return "You hear violent sounds from the " .. direction .. ". Something crashes."
end

--- Narrate a creature fleeing from combat noise (visible to player only).
-- @param creature_name string  display name of the creature
-- @param light         boolean whether the player can see
-- @return string|nil   narration text, or nil if dark
function M.creature_flee_sound(creature_name, light)
    if not light then return nil end
    return (creature_name or "Something") .. " skitters away from the noise."
end

--- Narrate a predator investigating combat noise (visible to player only).
-- @param creature_name string  display name of the creature
-- @param light         boolean whether the player can see
-- @return string|nil   narration text, or nil if dark
function M.creature_investigate_sound(creature_name, light)
    if not light then return nil end
    return (creature_name or "Something") .. " perks up, drawn toward the sounds."
end

return M
