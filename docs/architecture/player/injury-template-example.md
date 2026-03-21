# Injury Template Reference — Canonical `.lua` Format

**Author:** Flanders (Object & Injury Systems Engineer)  
**Date:** 2026-07-22  
**Status:** Reference  
**Purpose:** Canonical format for injury `.lua` template files in `src/meta/injuries/`. This is the authoritative example for anyone creating new injury types.

---

## Overview

Injury templates follow the same pattern as object templates:

- **One `.lua` file per injury type** in `src/meta/injuries/`
- **Each file returns a single Lua table** with a Windows GUID, FSM states, transitions, timers, and healing interactions
- **The engine executes metadata; injuries declare behavior** (Principle 8, same as objects)
- **Injuries are JIT-loaded** on demand, just like objects — not bulk-loaded at startup

The engine has zero knowledge of specific injury types. No `if injury.type == "bleeding"` anywhere.

---

## Canonical Example: `bleeding.lua`

```lua
-- src/meta/injuries/bleeding.lua
-- Injury template: Bleeding Wound
-- Pattern: Over-time damage with degenerative worsening if untreated
-- FSM: active → treated → healed  (happy path)
--      active → worsened → critical → fatal  (untreated path)

return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{b8a48066-7efc-4b41-a7c9-5eb6343416e0}",  -- Windows GUID, unique to this injury TYPE
    id = "bleeding",                                     -- String ID (matches filename, used in cures/refs)
    name = "Bleeding Wound",                             -- Human-readable display name
    category = "physical",                               -- physical | toxin | disease | environmental
    description = "An open wound that bleeds continuously.",

    -- ═══════════════════════════════════════════════════════════
    -- DAMAGE MODEL
    -- ═══════════════════════════════════════════════════════════
    damage_type = "over_time",          -- "one_time" | "over_time" | "degenerative"
                                        --   one_time:      damage set once at infliction, never grows
                                        --   over_time:     damage_per_tick accumulates each turn
                                        --   degenerative:  damage_per_tick increases each turn (see degenerative table)

    initial_state = "active",           -- FSM state on infliction

    on_inflict = {
        initial_damage = 5,             -- Sets instance.damage on creation
        damage_per_tick = 5,            -- Sets instance.damage_per_tick on creation
        message = "Blood wells from the wound.",
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM STATES
    -- Each state defines: sensory text, damage rate, timed auto-transitions
    -- Same fields as object states (name, description, on_feel, on_look, etc.)
    -- ═══════════════════════════════════════════════════════════
    states = {
        -- ── ACTIVE: Injury is untreated, accumulating damage ──
        active = {
            name = "bleeding",
            description = "Blood seeps steadily from the wound.",
            on_feel = "The wound is wet and warm.",
            on_look = "A deep gash, still bleeding freely.",
            on_smell = "The metallic tang of blood.",

            damage_per_tick = 5,        -- +5 to instance.damage each turn

            -- Capability restrictions (engine checks these)
            restricts = {
                climb = true,           -- Cannot climb while actively bleeding
            },

            timed_events = {
                { event = "transition", delay = 7200, to_state = "worsened" },
                -- 7200 seconds = 20 turns. Untreated bleeding worsens.
            },
        },

        -- ── TREATED: Healing item applied, damage stopped ──
        treated = {
            name = "bandaged wound",
            description = "The wound is bound. Bleeding has stopped.",
            on_feel = "Tight bandages cover the wound.",
            on_look = "A bandaged gash. No longer bleeding.",

            damage_per_tick = 0,        -- No further damage accumulation

            timed_events = {
                { event = "transition", delay = 14400, to_state = "healed" },
                -- 14400 seconds = 40 turns = 4 game hours to fully heal
            },
        },

        -- ── WORSENED: Untreated too long, infection sets in ──
        worsened = {
            name = "infected wound",
            description = "The untreated wound festers. You feel feverish.",
            on_feel = "Hot, swollen. The skin around the wound is inflamed.",
            on_look = "The wound is red and swollen, oozing.",

            damage_per_tick = 10,       -- Accelerated damage accumulation

            restricts = {
                climb = true,
                run = true,             -- Fever prevents running
            },

            timed_events = {
                { event = "transition", delay = 3600, to_state = "critical" },
            },
        },

        -- ── CRITICAL: Life-threatening, last chance for treatment ──
        critical = {
            name = "septic wound",
            description = "Sepsis. Your vision blurs. You can barely stand.",
            on_feel = "Burning fever. The wound is black at the edges.",

            damage_per_tick = 20,       -- Rapidly fatal accumulation

            restricts = {
                climb = true,
                run = true,
                fight = true,           -- Too weak
            },

            timed_events = {
                { event = "transition", delay = 1800, to_state = "fatal" },
            },
        },

        -- ── FATAL: Terminal state — triggers death check ──
        fatal = {
            name = "fatal blood loss",
            description = "You've lost too much blood.",
            terminal = true,
            -- Engine checks derived health; if <= 0, triggers on_death
            -- Fatal terminal state ALSO triggers death independently (D-INJURY006)
        },

        -- ── HEALED: Terminal state — injury removed from player ──
        healed = {
            name = "healed wound",
            description = "A faded scar remains.",
            terminal = true,
            -- Engine removes this injury from player.injuries[]
            -- Its .damage contribution disappears; derived health rises
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM TRANSITIONS
    -- Same format as object transitions: from, to, verb/trigger, condition, message, mutate
    -- ═══════════════════════════════════════════════════════════
    transitions = {
        -- ── Verb-triggered: Player uses a healing item ──
        {
            from = "active", to = "treated",
            verb = "use",
            requires_item_cures = "bleeding",       -- Healing item must declare cures = "bleeding"
            message = "You press the bandage firmly against the wound. The bleeding slows, then stops.",
            mutate = { damage_per_tick = 0 },
        },
        {
            from = "worsened", to = "treated",
            verb = "use",
            requires_item_cures = "bleeding",
            message = "You apply the bandage. The swelling begins to subside.",
            mutate = { damage_per_tick = 0 },
        },

        -- ── Auto-transitions: Timer-driven worsening ──
        {
            from = "active", to = "worsened",
            trigger = "auto",
            condition = "timer_expired",
            message = "The wound is getting worse. You feel feverish.",
            mutate = { damage_per_tick = 10 },
        },
        {
            from = "worsened", to = "critical",
            trigger = "auto",
            condition = "timer_expired",
            message = "Infection spreads. Your vision swims.",
            mutate = { damage_per_tick = 20 },
        },
        {
            from = "critical", to = "fatal",
            trigger = "auto",
            condition = "timer_expired",
            message = "You collapse. The world goes dark.",
        },
        {
            from = "treated", to = "healed",
            trigger = "auto",
            condition = "timer_expired",
            message = "The wound has fully healed. Only a scar remains.",
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- HEALING INTERACTIONS (Injury-side declaration)
    -- Maps healing object IDs → what states they work from and where they send the FSM
    -- BOTH sides must agree: object declares cures="bleeding", injury lists the object here
    -- ═══════════════════════════════════════════════════════════
    healing_interactions = {
        ["bandage"] = {
            transitions_to = "treated",
            from_states = { "active", "worsened" },
        },
        ["healing-poultice"] = {
            transitions_to = "treated",
            from_states = { "active", "worsened", "critical" },
            -- Poultice is stronger — works even in critical state
        },
        -- Items NOT listed here have NO effect on this injury.
        -- antidote-nightshade is NOT here. Wrong treatment, no match.
    },
}
```

---

## Template vs. Instance

The `.lua` file on disk is the **template** (immutable definition). When an injury is inflicted, the engine creates an **instance** (mutable runtime copy). The instance carries per-occurrence state that the template does not.

### What the Template Defines (on disk)
```
guid, id, name, category, description
damage_type, initial_state, on_inflict
states{}, transitions{}, healing_interactions{}
```

### What the Instance Adds (at runtime)
```lua
-- Runtime injury instance (lives in player.injuries[])
{
    -- From template (copied)
    type = "bleeding",                  -- References the template's id

    -- Instance-specific (added by engine at infliction)
    id = "bleeding-a7f3",              -- Unique instance ID (type + short hash)
    _state = "active",                 -- Current FSM state (starts at initial_state)
    source = "rusty-knife",            -- Object that caused this injury
    inflicted_at = 4320,               -- Game time (seconds) when inflicted
    turns_active = 7,                  -- Turns since infliction (incremented each tick)

    -- Damage tracking (initialized from on_inflict, modified by ticking)
    damage = 40,                       -- Running total damage caused (for derived health)
    damage_per_tick = 5,               -- Current per-turn accumulation (from state def)

    -- Severity (for display, set by inflicting object or engine)
    severity = "moderate",             -- informational, used in messaging

    -- Timer (managed by FSM engine, same as object timers)
    _timer = {
        remaining = 3600,              -- Seconds until next auto-transition
        paused = false,
    },
}
```

**Key distinction:** The template's `states{}`, `transitions{}`, and `healing_interactions{}` are NOT copied into the instance. The engine looks them up from the template definition when needed (same as objects — instance has `_state`, engine reads state definition from the base class).

---

## How Healing Objects Reference Injury Types

Healing objects declare which injury types they cure in their `.lua` files. The match is by **exact `id` string**.

### Object Side (in `src/meta/objects/`)

```lua
-- src/meta/objects/bandage.lua
return {
    guid = "{...}",
    id = "bandage",
    name = "a linen bandage",
    -- ...

    on_use = {
        cures = "bleeding",             -- EXACT match to injury template id
        transition_to = "treated",      -- Target FSM state on the injury
        consumable = true,              -- Bandage is consumed on use
        message = "You wrap the bandage tightly around the wound.",
    },
}

-- src/meta/objects/antidote-nightshade.lua
return {
    guid = "{...}",
    id = "antidote-nightshade",
    name = "a vial of nightshade antidote",
    -- ...

    on_drink = {
        cures = "poisoned-nightshade",  -- EXACT match — only cures nightshade
        transition_to = "treated",
        consumable = true,
        message = "The antidote takes effect. The burning subsides.",
    },
}
```

### Multi-Cure Objects

Some healing objects can treat multiple injury types. They declare a table of cures:

```lua
-- src/meta/objects/healing-poultice.lua
return {
    guid = "{...}",
    id = "healing-poultice",
    name = "a herbal poultice",
    -- ...

    on_use = {
        cures = { "bleeding", "bruise", "minor-cut" },   -- Treats multiple types
        transition_to = "treated",
        consumable = true,
        message = "The poultice draws warmth into the wound.",
    },
}
```

### Dual-Side Validation

Both sides must agree for healing to work:

1. **Object side:** `cures = "bleeding"` → tells engine which injury type to look for
2. **Injury side:** `healing_interactions["bandage"]` → validates the object is authorized

If the object declares `cures = "bleeding"` but `bleeding.lua` doesn't list that object in `healing_interactions`, the healing is **rejected**. This prevents spoofing and enforces intentional design.

---

## JIT Loading & Build Pipeline

### Where Files Live

```
src/meta/
├── objects/                    -- Object templates (candle.lua, match.lua, etc.)
├── injuries/                   -- Injury templates (bleeding.lua, infection.lua, etc.)
│   ├── bleeding.lua
│   ├── poisoned-nightshade.lua
│   ├── poisoned-spider-venom.lua
│   ├── bruise.lua
│   ├── burn.lua
│   ├── infection.lua
│   ├── fracture.lua
│   └── ...
├── templates/                  -- Base templates (small-item.lua, container.lua, etc.)
└── world/                      -- Room definitions
```

Injuries sit **alongside objects** in `src/meta/`, following the same organizational pattern. They are peers, not children of the object system.

### How the Engine Loads Injury Templates

Injury templates are **JIT-loaded** (loaded on first reference), not bulk-loaded at startup:

```lua
-- Simplified loader logic
local injury_cache = {}

function load_injury_definition(injury_type)
    if injury_cache[injury_type] then
        return injury_cache[injury_type]
    end

    -- JIT: load from file system (or web CDN in production)
    local source = read_file("src/meta/injuries/" .. injury_type .. ".lua")
    local def = loader.load_source(source)  -- Same sandboxed loader as objects

    -- Validate required fields
    assert(def.guid, "Injury missing GUID: " .. injury_type)
    assert(def.id == injury_type, "Injury id mismatch: " .. injury_type)
    assert(def.states and def.transitions, "Injury missing FSM: " .. injury_type)

    injury_cache[injury_type] = def
    return def
end
```

**In production (web delivery):**
- Injury `.lua` files are bundled alongside object `.lua` files in the web build
- The JIT loader fetches from CDN on first reference (same HTTP cache strategy as objects)
- Once loaded, the definition is cached for the session
- The player never downloads injury types they haven't encountered

### Sandbox

Injury `.lua` files execute in the same sandbox as objects:
- **Allowed:** `math`, `string`, `table`, `pairs`, `ipairs`, `tostring`, `tonumber`, `type`, `select`, `unpack`
- **Blocked:** `os`, `io`, `debug`, `require`, `dofile`, `loadfile`
- **Functions in state tables:** Allowed (e.g., `on_look = function(self) ... end`) but no side effects

---

## Required Fields Reference

| Field | Type | Required | Description |
|---|---|---|---|
| `guid` | string | **Yes** | Windows GUID in `{...}` format. Unique per injury type. |
| `id` | string | **Yes** | String identifier. Must match filename (e.g., `bleeding` → `bleeding.lua`). |
| `name` | string | **Yes** | Human-readable display name. |
| `category` | string | **Yes** | One of: `physical`, `toxin`, `disease`, `environmental`. |
| `description` | string | **Yes** | One-line summary of the injury. |
| `damage_type` | string | **Yes** | One of: `one_time`, `over_time`, `degenerative`. |
| `initial_state` | string | **Yes** | FSM state on infliction (usually `"active"`). |
| `on_inflict` | table | **Yes** | `{ initial_damage, damage_per_tick, message }` — applied at infliction. |
| `states` | table | **Yes** | FSM state definitions. Must include at least `healed` (terminal). |
| `transitions` | table | **Yes** | FSM transitions (verb-triggered and auto). |
| `healing_interactions` | table | **Yes** | Map of healing object IDs → `{ transitions_to, from_states }`. |

### Optional Fields

| Field | Type | Description |
|---|---|---|
| `degenerative` | table | Only for `damage_type = "degenerative"`. `{ base_damage, increment, max_damage }`. |
| `states[X].restricts` | table | Capability restrictions while in this state. |
| `states[X].on_feel` | string | Sensory: what the player feels. |
| `states[X].on_look` | string | Sensory: what the player sees. |
| `states[X].on_smell` | string | Sensory: what the player smells. |
| `states[X].on_listen` | string | Sensory: what the player hears. |

---

## Quick-Start: Creating a New Injury Type

1. **Design doc first** — Create `docs/design/injuries/<name>.md` following the design template
2. **Generate GUID** — Use `[guid]::NewGuid()` in PowerShell (wrap in `{...}`)
3. **Create `.lua` file** — `src/meta/injuries/<name>.lua` following this canonical format
4. **Define FSM** — States, transitions, timers. Draw the state diagram first.
5. **Define healing** — Which objects cure this? Add to `healing_interactions`. Update those objects' `cures` fields too.
6. **Cross-validate** — Every object in `healing_interactions` must also declare `cures = "<this-injury-id>"` in its own `.lua` file.

---

## Related

- [injuries.md](injuries.md) — Full injury system architecture (FSM engine, ticking, derived health)
- [health.md](health.md) — Derived health computation
- [../../design/injuries/README.md](../../design/injuries/README.md) — Design workflow and template for injury concepts
- [../objects/core-principles.md](../objects/core-principles.md) — Object FSM pattern (injuries mirror this exactly)
