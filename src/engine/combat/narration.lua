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
    organ = "organs",
}

local function zone_text(zone)
    if not zone then return "body" end
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
    if material_name == "tooth-enamel" then
        return pick({ "teeth", "tooth-enamel", "enamel", "fangs" })
    end
    if material_name == "keratin" then
        return pick({ "keratin claws", "claws", "keratin" })
    end
    return material_name:gsub("-", " ")
end

local function actor_name(actor)
    if not actor then return "Someone" end
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
    return (template:gsub("{(.-)}", function(key)
        return data[key] or ""
    end))
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
        zone = zone_text(result.zone),
        material = material_text(result.material_name or (result.weapon and result.weapon.material)),
        tissue = tissue_text(result.tissue_hit),
    }

    return render(pick(list), data)
end

M.narrate = M.generate

return M
