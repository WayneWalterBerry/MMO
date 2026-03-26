# Combat Narration

**File:** `src/engine/combat/narration.lua`  
**Author:** Bart (Architecture)  
**Date:** 2026-07-XX  
**Version:** 1.0 (GATE-6)

---

## Overview

Combat narration converts a numerical damage result into dramatic, varied prose. The system uses:
- **Severity-scaled templates** (DEFLECT through CRITICAL each have distinct vocabulary)
- **Material-aware descriptions** (steel sounds different than claws)
- **Zone-aware language** (head vs. torso vs. limbs get different verbs)
- **Darkness variants** (light mode uses visuals; dark mode uses sound/touch)

All narration is **procedurally generated** from template libraries, ensuring variety across repeated combats.

---

## Template Architecture

### Template Structure

```lua
local LIGHT_TEMPLATES = {
    [SEVERITY.DEFLECT] = {
        "{attacker} {verb} {target_possessive} {zone}, but the {material} glances off.",
        "The {material} skitters off {target_possessive} {zone} as {attacker} {verb}.",
        "{attacker} {verb} toward {target_possessive} {zone}; the {material} fails to bite.",
    },
    -- ... more severity levels
}

local DARK_TEMPLATES = {
    [SEVERITY.DEFLECT] = {
        "You hear a sharp clack as the {material} glances off in the dark.",
        "A dull thud at {target_possessive} {zone}; the {material} doesn't bite.",
        "In the dark, a scrape and a miss — the {material} skitters away.",
    },
    -- ... more severity levels
}
```

### Placeholder Tags

| Placeholder | Source | Example |
|-------------|--------|---------|
| `{attacker}` | `actor_name(result.attacker)` | "You", "The rat" |
| `{verb}` | `action_verb(result)` | "slashes", "punches", "bites" |
| `{target_possessive}` | `possessive(defender_name)` | "your", "the rat's" |
| `{zone}` | `zone_text(result.zone)` | "head", "torso", "arm" |
| `{material}` | `material_text(result.material_name)` | "steel blade", "claws", "teeth" |
| `{tissue}` | `tissue_text(result.tissue_hit)` | "flesh", "bone", "organs" |

---

## Severity Levels & Vocabulary

### DEFLECT (Severity 0)

**Meaning:** Weapon failed to penetrate outer layer  
**Vocabulary:** glances, skitters, fails to bite, clacks

**Light templates:**
```
"{attacker} {verb} {target_possessive} {zone}, but the {material} glances off."
"The {material} skitters off {target_possessive} {zone} as {attacker} {verb}."
"{attacker} {verb} toward {target_possessive} {zone}; the {material} fails to bite."
```

**Dark templates:**
```
"You hear a sharp clack as the {material} glances off in the dark."
"A dull thud at {target_possessive} {zone}; the {material} doesn't bite."
"In the dark, a scrape and a miss — the {material} skitters away."
```

### GRAZE (Severity 1)

**Meaning:** Shallow cut into outer layer  
**Vocabulary:** nicks, scratches, thin line, shallow mark

**Light templates:**
```
"{attacker} {verb} {target_possessive} {zone}, leaving a shallow mark in the {tissue}."
"The {material} edge nicks {target_possessive} {zone}, a thin line across the {tissue}."
"A quick strike across {target_possessive} {zone} scratches the {tissue}."
```

**Dark templates:**
```
"You feel a quick sting at {target_possessive} {zone}; a light scratch in the {tissue}."
"A faint rip and warmth on {target_possessive} {zone} — the {material} just grazes."
"In the dark you hear a soft hiss and feel a nick on {target_possessive} {zone}."
```

### HIT (Severity 2)

**Meaning:** Moderate penetration into flesh  
**Vocabulary:** bites, drives, sinks, draws blood

**Light templates:**
```
"{attacker} {verb} into {target_possessive} {zone}, cutting into the {tissue}."
"The {material} bites at {target_possessive} {zone}, parting {tissue}."
"{attacker} drives the {material} into {target_possessive} {zone}, drawing blood from the {tissue}."
```

**Dark templates:**
```
"A wet thud and sharp pain in {target_possessive} {zone}; the {material} bites into {tissue}."
"You hear a crack and feel the {material} sink into {target_possessive} {zone}."
"A heavy impact on {target_possessive} {zone} — warm blood and torn {tissue}."
```

### SEVERE (Severity 3)

**Meaning:** Deep penetration, fracture, or massive trauma  
**Vocabulary:** hacks, brutal, shatters, cracks, splintering

**Light templates:**
```
"{attacker} hacks into {target_possessive} {zone}; the {tissue} cracks under the {material}."
"A brutal blow to {target_possessive} {zone} fractures the {tissue}."
"The {material} tears through {target_possessive} {zone}, splintering {tissue}."
```

**Dark templates:**
```
"A sickening crunch from {target_possessive} {zone}; the {tissue} fractures."
"You hear bone snap as the {material} smashes {target_possessive} {zone}."
"A brutal crack and tearing sound — {target_possessive} {zone} is wrecked."
```

### CRITICAL (Severity 4)

**Meaning:** Vital organ damage, potentially fatal  
**Vocabulary:** plunges, devastating, severs, eviscerates, vital

**Light templates:**
```
"{attacker} plunges the {material} into {target_possessive} {zone}, hitting something vital."
"A devastating strike to {target_possessive} {zone} — the {tissue} gives way."
"{attacker} drives the {material} deep into {target_possessive} {zone}; a fatal wound opens."
```

**Dark templates:**
```
"A deep, wet squelch and a scream — the blow to {target_possessive} {zone} is fatal."
"In the dark, a violent crunch and sudden stillness at {target_possessive} {zone}."
"You hear a piercing shriek and feel the {material} drive deep; something vital gives way."
```

---

## Dynamic Text Replacement

### actor_name(actor) → string

Formats actor name for use in narration:

```lua
local function actor_name(actor)
    if not actor then return "Someone" end
    local name = actor.name or actor.id or "someone"
    if name:lower() == "you" then return "You" end
    return name:sub(1, 1):upper() .. name:sub(2)
end
```

**Examples:**
- Player: "You"
- Rat: "The rat"
- Generic: "Someone"

### possessive(name) → string

Converts name to possessive form:

```lua
local function possessive(name)
    if not name then return "their" end
    local lower = name:lower()
    if lower == "you" or lower == "the player" then return "your" end
    if name:sub(-1) == "s" then return name .. "'" end
    return name .. "'s"
end
```

**Examples:**
- "You" → "your"
- "The rat" → "the rat's"
- "Cornelius" → "Cornelius's"

### zone_text(zone) → string

Maps body zone ID to narrative word:

```lua
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

local function zone_text(zone)
    if not zone then return "body" end
    local list = zone_words[zone]
    if list then return pick(list) end  -- Random from list
    return zone
end
```

**Examples:**
- "head" → "head" / "skull" / "cranium" (random)
- "legs" → "leg" / "thigh" / "shin" / "knee" / "haunch" (random)

### tissue_text(tissue) → string

Maps tissue layer name to narrative word:

```lua
local tissue_words = {
    skin = "skin",
    hide = "hide",
    flesh = "flesh",
    bone = "bone",
    organ = "organs",
}

local function tissue_text(tissue)
    if not tissue then return "flesh" end
    return tissue_words[tissue] or tissue:gsub("-", " ")
end
```

**Examples:**
- "flesh" → "flesh"
- "bone" → "bone"
- "organ" → "organs"

### material_text(material_name) → string

Maps weapon material to narrative word, with special handling for natural weapons:

```lua
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
```

**Examples:**
- "steel" → "steel"
- "tooth-enamel" → "teeth" / "teeth" / "enamel" / "fangs" (random)
- "keratin" → "keratin claws" / "claws" / "keratin" (random)

### action_verb(result) → string

Extracts verb from weapon or result:

```lua
local function action_verb(result)
    return result.action_verb
        or (result.weapon and result.weapon.combat and result.weapon.combat.message)
        or (result.weapon and result.weapon.message)
        or "hits"
end
```

**Examples:**
- Dagger: "slashes"
- Punch: "punches"
- Rat bite: "sinks its teeth into"

---

## Generation Algorithm

**Function:** `M.generate(result, light) -> narration_string`

```lua
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
```

**Steps:**
1. Determine severity (0–4)
2. Choose template library (LIGHT or DARK)
3. Get template list for severity
4. Build replacement dictionary
5. Pick random template from list
6. Render by replacing placeholders
7. Return narration string

---

## Rendering

**Function:** `render(template, data) -> string`

```lua
local function render(template, data)
    return (template:gsub("{(.-)}", function(key)
        return data[key] or ""
    end))
end
```

Uses Lua string `gsub()` to replace `{key}` placeholders with values from the `data` table.

**Example:**
```lua
local template = "{attacker} {verb} {target_possessive} {zone}, but the {material} glances off."
local data = {
    attacker = "You",
    verb = "swing",
    target_possessive = "the rat's",
    zone = "head",
    material = "steel blade"
}

render(template, data)
-- Output: "You swing the rat's head, but the steel blade glances off."
```

---

## Darkness Handling

### Light Level Detection

```lua
local light = true
if opts and opts.light ~= nil then
    light = opts.light
elseif opts and presentation_ok and presentation and presentation.get_light_level then
    light = presentation.get_light_level(opts) ~= "dark"
end
```

### Dark Mode Characteristics

In darkness, narration emphasizes:
- **Sound:** "You hear a sharp clack..."
- **Tactile sensation:** "A wet thud and sharp pain..."
- **Absence of visual detail:** No color, no specific zone visibility

**Dark templates avoid:**
- References to what things "look like"
- Specific color descriptions
- Visual precision

**Light templates emphasize:**
- Visual precision: "the steel blade glances off"
- Color/appearance: specific material names
- Zone clarity: exact body part

---

## Variety Guarantees

### Design Intent

Narration should **never repeat the exact same string** across multiple combats. Each generation picks a random template, ensuring variety even in identical situations.

### Variance Sources

1. **Template list:** Each severity has 3 templates (pick random)
2. **Zone words:** Most zones have 3–5 synonyms
3. **Material words:** Natural weapons have multiple names
4. **Random seed:** Unsynchronized in continuous gameplay

### Test Requirement (GATE-5, C7)

"Run 3 combat exchanges with fixed seed (`math.randomseed(42)`). Assert ≥3 unique narration templates across exchanges."

This ensures that even with deterministic seeding, the system produces different strings for different severity levels and combinations.

---

## Complete Example

**Setup:**
```lua
local result = {
    attacker = { name = "You", id = "player", is_player = true },
    defender = { name = "The rat", id = "rat" },
    weapon = { combat = { message = "slash", type = "edged" }, material = "steel" },
    zone = "head",
    tissue_hit = "flesh",
    severity = 2,  -- HIT
    action_verb = "slash",
}

M.generate(result, true)  -- Light mode
```

**Execution:**
1. Pick LIGHT_TEMPLATES[2] (HIT severity)
2. Get list: 3 templates
3. Pick random: `"{attacker} {verb} into {target_possessive} {zone}, cutting into the {tissue}."`
4. Build data:
   - attacker = "You"
   - verb = "slash"
   - target_possessive = "the rat's"
   - zone = "head" (or "skull" / "cranium")
   - material = "steel"
   - tissue = "flesh"
5. Render: `"You slash into the rat's head, cutting into the flesh."`

---

## Template Library

### Full LIGHT_TEMPLATES

| Severity | Templates | Count |
|----------|-----------|-------|
| DEFLECT | "glances off", "skitters off", "fails to bite" | 3 |
| GRAZE | "shallow mark", "nicks", "scratches" | 3 |
| HIT | "bites", "drives", "draws blood" | 3 |
| SEVERE | "hacks", "fractures", "tears through" | 3 |
| CRITICAL | "plunges", "devastating", "fatal wound" | 3 |

### Full DARK_TEMPLATES

| Severity | Templates | Count |
|----------|-----------|-------|
| DEFLECT | "sharp clack", "dull thud", "scrape and miss" | 3 |
| GRAZE | "quick sting", "faint rip", "soft hiss" | 3 |
| HIT | "wet thud", "crack and sink", "heavy impact" | 3 |
| SEVERE | "sickening crunch", "bone snap", "brutal crack" | 3 |
| CRITICAL | "wet squelch", "violent crunch", "piercing shriek" | 3 |

---

## See Also

- **Combat FSM:** `docs/architecture/combat/combat-fsm.md` — NARRATE phase (Phase 5)
- **Damage Resolution:** `docs/architecture/combat/damage-resolution.md` — Severity calculation
- **Body Zone System:** `docs/architecture/combat/body-zone-system.md` — Zone and tissue definitions
- **Combat System (Design):** `docs/design/combat-system.md` — Player experience of narration
