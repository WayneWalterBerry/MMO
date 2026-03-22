# Player Appearance Subsystem — Architecture

**Version:** 1.0  
**Author:** Bart (Architect)  
**Date:** 2026-03-23  
**Status:** Design  
**Purpose:** Technical specification for the player appearance composition engine — transforms player state into natural language descriptions for mirrors, multiplayer `look at`, and any future system that needs to describe what a player looks like.

---

## Overview

The appearance subsystem is an **engine-level renderer** that reads `player.lua` state and produces a composed natural language description. It is NOT an object — it is a stateless function that takes a player state table as input and returns a string.

**Core invariant:** The appearance subsystem never modifies player state. It is a pure read → compose → return pipeline.

**File location:** `src/engine/player/appearance.lua`

---

## Input / Output Contract

### Input

The subsystem reads from the player state table (same structure as `player.lua` in `src/main.lua:278-290`):

```lua
player = {
    hands = { nil, nil },       -- two hand slots (object IDs or nil)
    worn = {                    -- body slot → object ID
        head = nil,             -- helmet, hat, etc.
        torso = nil,            -- armor, shirt, cloak
        feet = nil,             -- boots, shoes
        -- extensible: gloves, back, etc.
    },
    max_health = 100,
    injuries = {                -- active injury instances
        {
            id = "bleeding-1",
            type = "bleeding",
            _state = "active",          -- FSM state (active, treated, healed, etc.)
            location = "left arm",      -- body area
            severity = "moderate",
            damage = 20,
            damage_per_tick = 5,
            treatment = nil,            -- or { type = "bandage", item_id = "bandage-1" }
        },
    },
    state = {
        bloody = false,         -- global blood state
    },
}
```

### Output

A single composed string suitable for display. Example:

```
In the mirror, you see a pale figure in dented iron armor. A deep gash
runs along your left arm, partially wrapped in a bloodied bandage. Your
right hand grips a brass key. Your boots are caked with dried mud.
```

### Function Signature

```lua
--- Compose a natural language description of a player's appearance.
--- @param player table     — player state table (hands, worn, injuries, max_health)
--- @return string          — composed description (multi-sentence, natural English)
function appearance.describe(player)
```

---

## Layer Architecture

The subsystem uses an **ordered layer pipeline**. Each layer is a renderer function that examines one region of the player and returns a descriptive phrase (or `nil` if there's nothing notable to say about that region).

### Layer Execution Order

Layers execute top-to-bottom (head-to-toe), matching how a person scans a reflection:

| Order | Layer | Renderer Function | Examines |
|-------|-------|-------------------|----------|
| 1 | Head | `render_head(player)` | `worn.head`, head injuries, face injuries |
| 2 | Torso | `render_torso(player)` | `worn.torso`, chest/torso injuries, bandages |
| 3 | Arms | `render_arms(player)` | Arm injuries, arm bandages |
| 4 | Hands | `render_hands(player)` | `player.hands[1]`, `player.hands[2]`, hand injuries, gloves |
| 5 | Legs | `render_legs(player)` | Leg injuries, worn leg armor (future) |
| 6 | Feet | `render_feet(player)` | `worn.feet`, foot injuries |
| 7 | Overall | `render_overall(player)` | Health-based pallor, blood stains, general condition |

### Layer Contract

Each renderer follows the same contract:

```lua
--- @param player table     — full player state
--- @return string|nil      — descriptive phrase, or nil if nothing notable
function render_head(player)
```

**Nil semantics:** A `nil` return means "nothing notable about this region." The composer skips nil layers entirely — no placeholder text, no "you see nothing on your head." Silence is correct.

### Composition Pipeline

```lua
function appearance.describe(player)
    local layers = {
        render_head,
        render_torso,
        render_arms,
        render_hands,
        render_legs,
        render_feet,
        render_overall,
    }

    local phrases = {}
    for _, renderer in ipairs(layers) do
        local phrase = renderer(player)
        if phrase then
            phrases[#phrases + 1] = phrase
        end
    end

    if #phrases == 0 then
        return "You see an unremarkable figure staring back at you."
    end

    return table.concat(phrases, " ")
end
```

### Layer Registration (Extensibility)

The layer list is a plain Lua table. Adding a new body region (e.g., `render_back` for cloaks/backpacks) means appending a function to the table. No engine changes required.

---

## Worn Item Rendering

Each layer checks `player.worn[slot]` for its region. If an item is worn, the renderer loads the object definition from the registry to get its `name` and any appearance-relevant metadata.

### Object Metadata for Appearance

Wearable objects can declare optional appearance fields:

```lua
-- src/meta/objects/iron-helmet.lua
return {
    id = "iron-helmet",
    name = "a dented iron helmet",
    type = "wearable",
    wear_slot = "head",

    -- Optional appearance metadata (consumed by appearance subsystem)
    appearance = {
        worn_description = "a battered iron helmet sits on your head",
        damaged_description = "a cracked iron helmet, its visor bent",
    },
}
```

**Fallback:** If no `appearance` metadata exists, the renderer uses the object's `name` field: "You are wearing [name] on your [slot]."

### Rendering Logic

```lua
function render_head(player)
    local parts = {}

    -- Worn item
    local head_item = player.worn and player.worn.head
    if head_item then
        local obj = load_object(head_item)
        if obj and obj.appearance and obj.appearance.worn_description then
            parts[#parts + 1] = obj.appearance.worn_description
        elseif obj then
            parts[#parts + 1] = obj.name .. " sits on your head"
        end
    end

    -- Head injuries (see Injury Rendering Pipeline below)
    local head_injuries = get_injuries_at(player, {"head", "face", "forehead", "scalp"})
    for _, injury in ipairs(head_injuries) do
        parts[#parts + 1] = render_injury_phrase(injury)
    end

    if #parts == 0 then return nil end
    return compose_natural(parts)
end
```

---

## Held Item Rendering

The `render_hands` layer reads `player.hands[1]` and `player.hands[2]`:

```lua
function render_hands(player)
    local parts = {}
    local hand_names = { "left", "right" }

    for i, hand_slot in ipairs(player.hands) do
        if hand_slot then
            local obj = load_object(hand_slot)
            if obj then
                parts[#parts + 1] = "your " .. hand_names[i] ..
                    " hand grips " .. obj.name
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
```

---

## Injury Rendering Pipeline

Injuries are the most complex part of the appearance. The subsystem must compose natural phrases from structured injury data — not just "you have a cut" but "a deep gash on your left arm, wrapped in a bloodied bandage."

### Pipeline Stages

```
injury instance → location filter → severity map → treatment check → phrase composition
```

### Stage 1: Location Filter

Each layer calls `get_injuries_at(player, locations)` to find injuries matching its body region:

```lua
--- Find injuries at specific body locations.
--- @param player table
--- @param locations string[]   — e.g., {"left arm", "right arm", "arm"}
--- @return table[]             — matching injury instances
function get_injuries_at(player, locations)
    local matches = {}
    for _, injury in ipairs(player.injuries or {}) do
        for _, loc in ipairs(locations) do
            if injury.location and string.find(
                string.lower(injury.location),
                string.lower(loc), 1, true
            ) then
                matches[#matches + 1] = injury
                break
            end
        end
    end
    return matches
end
```

**Location matching** is substring-based: the arm layer checks for `"left arm"`, `"right arm"`, and `"arm"`, which catches `"upper left arm"` too.

### Stage 2: Severity Mapping

Injury severity maps to adjectives:

| Severity | Adjective | Example |
|----------|-----------|---------|
| `nil` / unknown | (no adjective) | "a wound on your arm" |
| `"minor"` | "a small", "a shallow" | "a shallow cut on your forearm" |
| `"moderate"` | "a deep", "a nasty" | "a deep gash along your left arm" |
| `"severe"` | "a grievous", "a terrible" | "a grievous wound in your side" |

The severity-to-adjective mapping is a lookup table, not hardcoded conditionals:

```lua
local severity_adjectives = {
    minor    = { "small", "shallow", "slight" },
    moderate = { "deep", "nasty", "ugly" },
    severe   = { "grievous", "terrible", "gaping" },
}
```

### Stage 3: Treatment Check

If `injury.treatment` exists, the phrase includes the treatment:

| Treatment State | Phrase Fragment |
|----------------|-----------------|
| No treatment | (injury only) |
| `treatment.type == "bandage"`, injury still active | "wrapped in a bloodied bandage" |
| `treatment.type == "bandage"`, injury treated | "neatly bandaged" |
| Injury `_state == "treated"` | "a healing wound" |
| Injury `_state == "healed"` (terminal) | (skipped — injury will be removed) |

### Stage 4: Phrase Composition

The composer assembles the final phrase from parts:

```lua
--- Compose a natural injury phrase from structured data.
--- @param injury table — injury instance
--- @return string
function render_injury_phrase(injury)
    local def = load_injury_definition(injury.type)
    local adj = pick_severity_adjective(injury.severity)
    local noun = def.appearance_noun or def.name or injury.type
    -- e.g., "gash", "wound", "cut", "bruise"

    local phrase = adj and (adj .. " " .. noun) or noun
    -- → "deep gash"

    if injury.location then
        phrase = phrase .. " on your " .. injury.location
        -- → "deep gash on your left arm"
    end

    if injury.treatment then
        local treatment_phrase = render_treatment(injury)
        phrase = phrase .. ", " .. treatment_phrase
        -- → "deep gash on your left arm, wrapped in a bloodied bandage"
    end

    return "a " .. phrase
end
```

### Injury Type Metadata for Appearance

Injury definitions in `src/meta/injuries/` can declare optional appearance fields:

```lua
-- src/meta/injuries/bleeding.lua (appearance-relevant fields)
return {
    id = "bleeding",
    name = "Bleeding Wound",

    -- Appearance subsystem reads these
    appearance_noun = "gash",           -- used in composed phrase
    appearance_active = "bleeding freely",
    appearance_treated = "bound with cloth",
}
```

**Fallback:** If no appearance fields exist, the renderer uses `name` and generic phrasing.

---

## Overall Health Descriptor

The `render_overall` layer maps derived health to a condition descriptor:

```lua
function render_overall(player)
    local health = compute_health(player)
    local pct = health / player.max_health

    local parts = {}

    -- Health-based pallor
    if pct <= 0.25 then
        parts[#parts + 1] = "your skin is deathly pale, eyes sunken"
    elseif pct <= 0.50 then
        parts[#parts + 1] = "you look pale and unsteady"
    elseif pct <= 0.75 then
        parts[#parts + 1] = "you look a bit worn but standing"
    end
    -- 75-100%: no comment (healthy is the default, no need to state it)

    -- Global blood state
    if player.state and player.state.bloody then
        parts[#parts + 1] = "dried blood is visible on your skin and clothes"
    end

    if #parts == 0 then return nil end
    return compose_natural(parts)
end
```

### Health Percentage → Descriptor Map

| Health % | Descriptor | Rationale |
|----------|-----------|-----------|
| 76–100% | (nothing) | Healthy is the default — silence is correct |
| 51–75% | "worn but standing" | Minor concern |
| 26–50% | "pale and unsteady" | Visible distress |
| 0–25% | "deathly pale, eyes sunken" | Near death |

---

## Integration Points

### Integration 1: Mirror Object (`on_examine` Hook)

The mirror is a special object with an `is_mirror` flag (or integrated into furniture like the vanity at `src/meta/objects/vanity.lua`). When the player examines a mirror, the engine intercepts and calls the appearance subsystem.

**Current state:** The vanity object (`src/meta/objects/vanity.lua:31-42`) has a hardcoded `on_look` that returns a static string about "your reflection staring back." This will be replaced with a dynamic appearance call.

**Target architecture:**

```lua
-- In the examine/look verb handler (src/engine/verbs/init.lua):
-- When the target object has is_mirror = true or is the vanity mirror:
if target.is_mirror or (target.mirror_surface) then
    local appearance = require("engine.player.appearance")
    local description = appearance.describe(context.player)
    print("In the mirror, you see " .. description)
    return true
end
```

**Mirror flag on objects:**

```lua
-- src/meta/objects/vanity.lua (updated)
return {
    id = "vanity",
    name = "an oak vanity",
    is_mirror = true,       -- Engine flag: triggers appearance subsystem on examine
    -- ... existing FSM states for drawer, breakable mirror, etc.
}
```

### Integration 2: `look at <player>` (Future — Multiplayer)

The same subsystem answers "what does another player look like?" by passing the target player's state:

```lua
-- Future multiplayer verb handler:
local appearance = require("engine.player.appearance")
local description = appearance.describe(target_player)
print("You see " .. target_player.name .. ". " .. description)
```

**Design for this now, implement later.** The subsystem takes ANY player state table — it doesn't assume "self." This is the key architectural decision that makes it reusable.

### Integration 3: Status/Health Command

The `health` / `status` verb can optionally call `appearance.describe()` to include visual state alongside injury listing. This is a future integration point — the appearance subsystem provides the "what you look like" complement to the injury system's "what's wrong with you."

---

## Relationship to Existing Player State

### Where State Lives (Current — `src/main.lua:278-290`)

```lua
player = {
    hands = { nil, nil },       -- held items: appearance reads this
    worn = {},                  -- worn items: appearance reads this
    injuries = {},              -- injury instances: appearance reads this
    max_health = 100,           -- for health percentage: appearance reads this
    state = {
        bloody = false,         -- blood flag: appearance reads this
    },
}
```

### What Appearance Reads (Summary)

| Player Field | Used By Layer | Purpose |
|-------------|---------------|---------|
| `worn.head` | `render_head` | Headgear description |
| `worn.torso` | `render_torso` | Armor/clothing description |
| `worn.feet` | `render_feet` | Footwear description |
| `hands[1]`, `hands[2]` | `render_hands` | Held item description |
| `injuries[]` | All body layers | Injury phrases per location |
| `injuries[].treatment` | All body layers | Treatment phrases |
| `injuries[].location` | Location filter | Route injury to correct layer |
| `injuries[].severity` | Severity map | Adjective selection |
| `injuries[]._state` | Treatment check | Active vs. treated vs. healed |
| `max_health` | `render_overall` | Health percentage calculation |
| `state.bloody` | `render_overall` | Global blood stain |

### What Appearance Does NOT Read

- `player.skills` — irrelevant to visual appearance
- `player.inventory` — bags aren't visible (unless worn on back, handled via `worn.back`)
- `player.visited_rooms` — no bearing on appearance
- `player.location` — appearance is context-independent

---

## Natural Language Composition

The `compose_natural` utility combines multiple phrases into a natural sentence, avoiding robotic lists:

```lua
--- Combine phrases into natural English.
--- @param phrases string[] — e.g., {"a dented helmet", "a gash above your eye"}
--- @return string
function compose_natural(phrases)
    if #phrases == 1 then
        return phrases[1]
    elseif #phrases == 2 then
        return phrases[1] .. " and " .. phrases[2]
    else
        -- Oxford comma for 3+
        local last = table.remove(phrases)
        return table.concat(phrases, ", ") .. ", and " .. last
    end
end
```

**Anti-pattern (robotic):**
```
You are wearing a helmet. You have a cut. Your arm is bandaged.
```

**Target (natural):**
```
A battered iron helmet sits on your head, and a deep gash runs above
your right eye. Your torso is wrapped in bloodied leather armor.
```

---

## Design Decisions

| ID | Decision | Rationale |
|---|---|---|
| D-APP001 | Appearance is an engine subsystem, not object logic | Reusable across mirrors, multiplayer, status commands. Objects just set the `is_mirror` flag. |
| D-APP002 | Layered head-to-toe rendering | Matches natural scan order. Each layer is independent and testable. |
| D-APP003 | Nil layers are skipped (silence is correct) | No "you see nothing on your feet." If there's nothing to say, say nothing. |
| D-APP004 | Subsystem takes any player state table | Future-proofs for multiplayer — same function describes self or another player. |
| D-APP005 | Injury phrases are composed, not canned | Structured pipeline (location → severity → treatment → phrase) produces varied, natural English from data. |
| D-APP006 | Object appearance metadata is optional | Objects can declare `appearance.worn_description` for richer text, but the system works with just `name`. Graceful degradation. |

---

## Related

- [README.md](README.md) — Player system overview, canonical player.lua structure
- [injuries.md](injuries.md) — Injury FSM system (appearance reads injury instances)
- [injury-targeting.md](injury-targeting.md) — Body location matching (appearance reuses location data)
- [health.md](health.md) — Derived health computation (appearance uses health percentage)
- [inventory.md](inventory.md) — Held items (appearance reads hand slots)
- [player-model.md](player-model.md) — Worn items, hand slots (appearance reads these)
