# Injury System — Architecture

**Version:** 2.0  
**Author:** Bart (Architect)  
**Date:** 2026-07-22  
**Revised:** 2026-07-22 — Injury-specific healing, derived health integration (Wayne directive 2026-03-21T19:17Z)  
**Status:** Design  
**Purpose:** Technical specification for the injury FSM system, injury types, over-time effects, injury-specific healing, and derived health integration.

---

## Overview

Injuries are a **state of the player** — a nested array in `player.lua`. Each injury type is defined as its own `.lua` file in `src/meta/injuries/`, following the same FSM pattern used by objects. Injuries have states, transitions, timers, and sensory descriptions.

The engine ticks injuries each turn, just like it ticks object FSMs. Injury behavior is encoded in metadata — the engine stays generic.

**Key change (v2):** Health is derived from injuries. Each injury instance carries a `damage` field — the running total of damage it has caused. Health = `max_health - sum(injury.damage)`. Healing an injury removes its damage contribution. See [health.md](health.md).

---

## File Structure

```
src/meta/injuries/
├── bleeding.lua                  -- Laceration / open wound
├── poisoned-nightshade.lua       -- Nightshade poison (specific)
├── poisoned-spider-venom.lua     -- Spider venom (specific)
├── bruise.lua                    -- Blunt force trauma
├── burn.lua                      -- Thermal damage
├── infection.lua                 -- Wound infection (degenerative)
├── fracture.lua                  -- Broken bone
└── ...                           -- Extensible per game content
```

Each file defines a complete FSM for one injury type. Injury authors (Flanders, content team) create these files using the same patterns as object `.lua` files.

**Note on naming:** Injury types are **specific**, not generic. There is no `poisoned.lua` — there is `poisoned-nightshade.lua` and `poisoned-spider-venom.lua`. This specificity is what makes injury-specific healing work.

---

## Injury Instance Structure

When an injury is inflicted, the engine creates an **instance** from the injury type definition:

```lua
-- Runtime injury instance (stored in player.injuries[])
{
    id = "poisoned-nightshade-1",   -- Unique instance ID
    type = "poisoned-nightshade",   -- References src/meta/injuries/poisoned-nightshade.lua
    _state = "active",              -- Current FSM state
    source = "nightshade-berry",    -- Object that caused this injury (for messaging)
    inflicted_at = 1200,            -- Game time (seconds) when injury was inflicted
    turns_active = 3,               -- Turns since infliction

    -- Damage tracking (for derived health)
    damage = 39,                    -- Total damage this injury has caused (initial + accumulated)
    damage_per_tick = 8,            -- Current per-turn damage accumulation (0 for one-time injuries)

    -- Severity (for display and FSM behavior)
    severity = "moderate",

    -- Timer tracking (managed by FSM engine):
    _timer = {
        remaining = 7200,           -- Seconds until auto-transition
        paused = false,
    },
}
```

---

## Injury FSM Pattern

Every injury `.lua` file declares an FSM. The pattern mirrors object FSMs exactly.

### Common State Flow

```
inflicted → active → treated → healed
                  ↘ (untreated, timer expires)
                    worsened → critical → fatal
```

### Full Example: `bleeding.lua`

```lua
-- src/meta/injuries/bleeding.lua
return {
    id = "bleeding",
    name = "Bleeding Wound",
    category = "physical",
    description = "An open wound that bleeds continuously.",

    initial_state = "active",

    damage_type = "over_time",         -- "one_time" | "over_time" | "degenerative"

    on_inflict = {
        initial_damage = 5,            -- Starting .damage value on the instance
        damage_per_tick = 5,           -- Per-turn damage accumulation
        message = "Blood wells from the wound.",
    },

    states = {
        active = {
            name = "bleeding",
            description = "Blood seeps steadily from the wound.",
            on_feel = "The wound is wet and warm.",
            on_look = "A deep gash, still bleeding freely.",

            damage_per_tick = 5,       -- Accumulates 5 to injury.damage per turn

            timed_events = {
                { event = "transition", delay = 7200, to_state = "worsened" },
            },
        },

        treated = {
            name = "bandaged wound",
            description = "The wound is bound. Bleeding has stopped.",
            on_feel = "Tight bandages cover the wound.",
            on_look = "A bandaged gash. No longer bleeding.",

            damage_per_tick = 0,       -- No further damage accumulation

            timed_events = {
                { event = "transition", delay = 14400, to_state = "healed" },
            },
        },

        worsened = {
            name = "infected wound",
            description = "The untreated wound festers. You feel feverish.",
            on_feel = "Hot, swollen. The skin around the wound is inflamed.",
            on_look = "The wound is red and swollen, oozing.",

            damage_per_tick = 10,      -- Accelerated damage accumulation

            timed_events = {
                { event = "transition", delay = 3600, to_state = "critical" },
            },
        },

        critical = {
            name = "septic wound",
            description = "Sepsis. Your vision blurs. You can barely stand.",
            on_feel = "Burning fever. The wound is black at the edges.",

            damage_per_tick = 20,      -- Rapidly fatal accumulation

            timed_events = {
                { event = "transition", delay = 1800, to_state = "fatal" },
            },
        },

        fatal = {
            name = "fatal blood loss",
            description = "You've lost too much blood.",
            terminal = true,
            -- Engine checks derived health; if <= 0, triggers death
        },

        healed = {
            name = "healed wound",
            description = "A faded scar remains.",
            terminal = true,
            -- Engine removes this injury from player.injuries[]
            -- Its .damage contribution disappears; derived health rises
        },
    },

    transitions = {
        -- Verb-triggered (healing items)
        {
            from = "active", to = "treated",
            verb = "use",
            requires_item_cures = "bleeding",   -- Healing item must have cures = "bleeding"
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

        -- Auto-transitions (timer-driven)
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
}
```

---

## Injury-Specific Healing

### The Core Rule

Healing objects cure **specific** injury types. The match is by exact `type` string. This is the foundational healing mechanic:

| Healing Object | `cures` Field | Heals | Does NOT Heal |
|---|---|---|---|
| `antidote-nightshade` | `"poisoned-nightshade"` | Nightshade poisoning | Spider venom, bleeding, bruise |
| `antidote-spider-venom` | `"poisoned-spider-venom"` | Spider venom poisoning | Nightshade, bleeding, bruise |
| `bandage` | `"bleeding"` | Bleeding wounds | Any poison, bruise, fracture |
| `healing-salve` | `"bruise"` | Bruises | Bleeding, poison, fracture |

### Dual-Side Encoding

The healing relationship is encoded on **both** the healing object and the injury definition:

#### Healing Object Side

```lua
-- src/meta/objects/antidote-nightshade.lua
return {
    id = "antidote-nightshade",
    name = "a vial of nightshade antidote",

    on_drink = {
        cures = "poisoned-nightshade",   -- EXACT injury type
        transition_to = "treated",       -- FSM target state (or nil for full removal)
        message = "The antidote takes effect. The burning subsides.",
        consumable = true,
    },
}
```

#### Injury Definition Side

```lua
-- src/meta/injuries/poisoned-nightshade.lua
return {
    id = "poisoned-nightshade",
    -- ... states, transitions ...

    -- What healing objects can treat this injury
    healing_interactions = {
        ["antidote-nightshade"] = {
            transitions_to = "treated",
            from_states = { "active", "critical" },
        },
        -- antidote-spider-venom is NOT listed here — it won't work
    },
}
```

### Matching Logic

When a healing verb fires, the engine does an exact-match lookup:

```lua
function injury_system.try_heal(player, healing_object, verb)
    local effect = healing_object["on_" .. verb]
    if not effect or not effect.cures then return false end

    -- Step 1: Find injury with matching type (exact match)
    local injury, index = find_injury_by_type(player, effect.cures)
    if not injury then
        print("You don't have that kind of injury.")
        return false
    end

    -- Step 2: Validate the injury definition accepts this healing object
    local injury_def = load_injury_definition(injury.type)
    local interaction = injury_def.healing_interactions[healing_object.id]
    if not interaction then
        print("That won't help with this injury.")
        return false
    end

    -- Step 3: Check current FSM state is valid for this interaction
    if not table_contains(interaction.from_states, injury._state) then
        print("It's too late for that to help.")
        return false
    end

    -- Step 4: Apply healing
    if effect.transition_to or interaction.transitions_to then
        -- Partial healing: transition FSM, stop damage accumulation
        local target_state = effect.transition_to or interaction.transitions_to
        injury_system.transition(injury, target_state)
        injury.damage_per_tick = 0
    else
        -- Full cure: remove injury entirely
        table.remove(player.injuries, index)
        -- Derived health rises immediately
    end

    return true
end
```

### Why Dual-Side?

Both sides declare the relationship for **validation**:

1. **Object side** (`cures = "poisoned-nightshade"`) — tells the engine which injury to look for in the player's array.
2. **Injury side** (`healing_interactions`) — validates that this specific healing object is authorized and declares which FSM states it can work from.

This prevents edge cases: even if someone crafts a custom object with `cures = "poisoned-nightshade"`, the injury definition must also list that object in `healing_interactions`.

---

## Injury Types

### Type 1: One-Time Damage

Injury causes a single health decrease at the moment of infliction. The `damage` field is set once and does not grow. Healing removes the injury and its fixed damage.

**Examples:** bruise, cut, blunt trauma

```lua
-- src/meta/injuries/bruise.lua
return {
    id = "bruise",
    name = "Bruise",
    category = "physical",
    damage_type = "one_time",

    initial_state = "active",

    on_inflict = {
        initial_damage = 10,           -- Set injury.damage = 10 on creation
        message = "A nasty bruise forms.",
    },

    states = {
        active = {
            name = "bruise",
            description = "A dark, painful bruise.",
            damage_per_tick = 0,           -- No ongoing accumulation

            timed_events = {
                { event = "transition", delay = 14400, to_state = "healed" },
            },
        },

        healed = {
            name = "faded bruise",
            description = "The bruise has faded.",
            terminal = true,
        },
    },

    transitions = {
        {
            from = "active", to = "healed",
            trigger = "auto",
            condition = "timer_expired",
            message = "The bruise fades.",
        },
        {
            from = "active", to = "healed",
            verb = "use",
            requires_item_cures = "bruise",
            message = "The salve soothes the bruise. It fades quickly.",
        },
    },

    healing_interactions = {
        ["healing-salve"] = { transitions_to = "healed", from_states = { "active" } },
    },
}
```

### Type 2: Over-Time Damage

Injury accumulates damage each turn (`damage_per_tick` added to `injury.damage`). Derived health drops each turn.

**Examples:** bleeding, mild poison, exposure

```lua
-- src/meta/injuries/poisoned-nightshade.lua
return {
    id = "poisoned-nightshade",
    name = "Nightshade Poisoning",
    category = "toxin",
    damage_type = "over_time",

    initial_state = "active",

    on_inflict = {
        initial_damage = 15,               -- Starting .damage on the instance
        message = "Nightshade poison courses through your veins.",
    },

    states = {
        active = {
            name = "poisoned (nightshade)",
            description = "Your stomach churns. Nightshade burns in your veins.",
            on_feel = "Cold sweat. Trembling hands.",
            on_smell = "A bitter taste at the back of your throat.",

            damage_per_tick = 8,           -- Accumulates 8 per turn

            timed_events = {
                { event = "transition", delay = 5400, to_state = "critical" },
            },
        },

        treated = {
            name = "neutralized nightshade",
            description = "The antidote is working. The burning fades.",
            damage_per_tick = 0,           -- Stops accumulating

            timed_events = {
                { event = "transition", delay = 3600, to_state = "healed" },
            },
        },

        critical = {
            name = "severe nightshade poisoning",
            description = "Convulsions. Your body is shutting down.",
            damage_per_tick = 15,

            timed_events = {
                { event = "transition", delay = 1800, to_state = "fatal" },
            },
        },

        fatal = {
            name = "lethal nightshade poisoning",
            description = "The nightshade has won.",
            terminal = true,
        },

        healed = {
            name = "recovered from nightshade",
            description = "The poison has left your system.",
            terminal = true,
        },
    },

    transitions = {
        {
            from = "active", to = "treated",
            verb = "drink",
            requires_item_cures = "poisoned-nightshade",
            message = "The antidote takes effect. The burning subsides.",
            mutate = { damage_per_tick = 0 },
        },
        {
            from = "active", to = "critical",
            trigger = "auto",
            condition = "timer_expired",
            message = "The poison intensifies. Your body convulses.",
            mutate = { damage_per_tick = 15 },
        },
        {
            from = "critical", to = "treated",
            verb = "drink",
            requires_item_cures = "poisoned-nightshade",
            message = "Just in time. The antidote fights the nightshade.",
            mutate = { damage_per_tick = 0 },
        },
        {
            from = "critical", to = "fatal",
            trigger = "auto",
            condition = "timer_expired",
            message = "The nightshade claims you.",
        },
        {
            from = "treated", to = "healed",
            trigger = "auto",
            condition = "timer_expired",
            message = "The last traces of nightshade leave your body.",
        },
    },

    healing_interactions = {
        ["antidote-nightshade"] = {
            transitions_to = "treated",
            from_states = { "active", "critical" },
        },
        -- antidote-spider-venom does NOT appear here. Wrong antidote, no effect.
    },
}
```

### Type 3: Degenerative Damage

Damage accumulation accelerates over time. Each turn, `damage_per_tick` increases. Untreated, this kills faster and faster.

**Examples:** untreated infection, spreading disease, venom

```lua
-- src/meta/injuries/infection.lua
return {
    id = "infection",
    name = "Infection",
    category = "disease",
    damage_type = "degenerative",

    initial_state = "active",

    on_inflict = {
        initial_damage = 5,
        message = "The wound feels hot. Something is wrong.",
    },

    degenerative = {
        base_damage = 2,               -- Starting damage per tick
        increment = 1,                 -- Added to damage_per_tick each turn
        max_damage = 25,               -- Cap on per-tick accumulation rate
    },

    states = {
        active = {
            name = "infected wound",
            description = "The wound festers. Red lines spread from it.",
            on_feel = "Hot to the touch. Throbbing pain.",

            damage_per_tick = 2,       -- Starts low, scales via degenerative rules

            timed_events = {
                { event = "transition", delay = 10800, to_state = "severe" },
            },
        },

        severe = {
            name = "severe infection",
            description = "Fever. Chills. The infection is spreading fast.",

            damage_per_tick = 10,      -- Jumps on state change

            timed_events = {
                { event = "transition", delay = 3600, to_state = "fatal" },
            },
        },

        treated = {
            name = "treated infection",
            description = "Medicine fights the infection. Fever is breaking.",
            damage_per_tick = 0,

            timed_events = {
                { event = "transition", delay = 7200, to_state = "healed" },
            },
        },

        fatal = {
            name = "sepsis",
            description = "Organ failure. The infection has won.",
            terminal = true,
        },

        healed = {
            name = "cleared infection",
            description = "The infection is gone.",
            terminal = true,
        },
    },

    transitions = {
        {
            from = "active", to = "treated",
            verb = "use",
            requires_item_cures = "infection",
            message = "The medicine takes effect. The fever begins to break.",
            mutate = { damage_per_tick = 0 },
        },
        {
            from = "active", to = "severe",
            trigger = "auto",
            condition = "timer_expired",
            message = "The infection worsens dramatically.",
            mutate = { damage_per_tick = 10 },
        },
        {
            from = "severe", to = "treated",
            verb = "use",
            requires_item_cures = "infection",
            message = "Powerful medicine fights the severe infection.",
            mutate = { damage_per_tick = 0 },
        },
        {
            from = "severe", to = "fatal",
            trigger = "auto",
            condition = "timer_expired",
            message = "Sepsis. Your body gives out.",
        },
        {
            from = "treated", to = "healed",
            trigger = "auto",
            condition = "timer_expired",
            message = "The infection has cleared completely.",
        },
    },

    healing_interactions = {
        medicine        = { transitions_to = "treated", from_states = { "active" } },
        strong_medicine = { transitions_to = "treated", from_states = { "active", "severe" } },
    },
}
```

---

## Degenerative Damage: Engine Processing

For `damage_type = "degenerative"` injuries, the engine increases `damage_per_tick` each turn:

```lua
-- In injury_system.tick():
if injury_def.damage_type == "degenerative" and injury._state == "active" then
    local degen = injury_def.degenerative
    injury.damage_per_tick = math.min(
        degen.max_damage,
        injury.damage_per_tick + degen.increment
    )
end
-- Then: injury.damage = injury.damage + injury.damage_per_tick
```

This means (for infection with base=2, increment=1, max=25):
- Turn 1: +2 damage (total .damage grows by 2)
- Turn 2: +3 damage
- Turn 3: +4 damage
- ...
- Turn 24+: capped at +25 per turn

The scaling is **per-tick linear** with a cap. Content authors set the `base_damage`, `increment`, and `max_damage` in the injury `.lua` file. The engine just applies the formula.

---

## Injury Infliction

When an object's verb handler declares an injury, the engine creates an instance:

```lua
function injury_system.inflict(player, injury_type, effect)
    -- 1. Load injury definition from src/meta/injuries/<type>.lua
    local injury_def = load_injury_definition(injury_type)

    -- 2. Create instance from definition
    local instance = {
        id = injury_type .. "-" .. generate_id(),  -- Unique instance ID
        type = injury_type,
        _state = injury_def.initial_state,
        source = effect.source or "unknown",
        inflicted_at = game_time(),
        turns_active = 0,

        -- Damage tracking for derived health
        damage = injury_def.on_inflict.initial_damage or 0,
        damage_per_tick = injury_def.states[injury_def.initial_state].damage_per_tick or 0,

        severity = effect.severity or "moderate",
        _timer = nil,  -- Started by FSM engine on state entry
    }

    -- 3. Start FSM timer for initial state
    if injury_def.states[instance._state].timed_events then
        fsm.start_injury_timer(instance, injury_def)
    end

    -- 4. Add to player's injury array
    player.injuries[#player.injuries + 1] = instance

    -- 5. Emit infliction message
    if injury_def.on_inflict and injury_def.on_inflict.message then
        print(injury_def.on_inflict.message)
    end

    -- Derived health decreases automatically (new injury adds to sum of damage)
end
```

**Note (v2 change):** There is no `player.health -= damage` line. The injury's `damage` field is set, and `compute_health()` accounts for it automatically.

---

## Injury Ticking

Each turn, the engine iterates the player's injuries and accumulates damage:

```lua
function injury_system.tick(injury, delta_seconds)
    local injury_def = load_injury_definition(injury.type)
    local state_def = injury_def.states[injury._state]
    local result = { message = nil, transition = nil }

    -- Skip terminal states
    if state_def.terminal then
        return result
    end

    -- Accumulate per-tick damage on the injury instance
    if injury.damage_per_tick and injury.damage_per_tick > 0 then
        injury.damage = injury.damage + injury.damage_per_tick
    end

    -- Degenerative scaling (increase accumulation rate)
    if injury_def.damage_type == "degenerative" and injury_def.degenerative then
        local degen = injury_def.degenerative
        injury.damage_per_tick = math.min(
            degen.max_damage,
            injury.damage_per_tick + degen.increment
        )
    end

    -- Track turns
    injury.turns_active = (injury.turns_active or 0) + 1

    -- Tick timer
    if injury._timer and not injury._timer.paused then
        injury._timer.remaining = injury._timer.remaining - delta_seconds
        if injury._timer.remaining <= 0 then
            local auto_trans = find_auto_transition(injury_def, injury._state)
            if auto_trans then
                result.transition = auto_trans.to
                result.message = auto_trans.message
            end
        end
    end

    return result
end
```

---

## Multiple Simultaneous Injuries

A player can have multiple active injuries. The engine processes ALL of them each turn. Derived health is the sum:

```lua
player.injuries = {
    { type = "bleeding",            _state = "active", damage = 20, damage_per_tick = 5  },
    { type = "poisoned-nightshade", _state = "active", damage = 39, damage_per_tick = 8  },
    { type = "bruise",              _state = "active", damage = 10, damage_per_tick = 0  },
}
-- sum(damage) = 20 + 39 + 10 = 69
-- Derived health = 100 - 69 = 31
-- Next turn: damage grows by 5 + 8 + 0 = 13 → health = 100 - 82 = 18
```

Healing items target specific injury types. Using a bandage treats the bleeding but not the poison. Using `antidote-nightshade` treats the nightshade but not the bleeding. The player needs BOTH a bandage AND the correct antidote.

---

## Injury Lifecycle (Revised for Derived Health)

```
1. INFLICTION
   Object verb fires → object metadata declares injury type
   → injury_system.inflict() creates instance with initial .damage
   → Instance added to player.injuries[]
   → Derived health drops immediately (sum of damage increased)

2. ACTIVE PHASE
   Each turn: injury ticked → .damage_per_tick added to injury.damage
   Derived health decreases (sum of damage grows)
   Timer counts down → may auto-transition to worse state
   Player can inspect injuries via `injuries` or `check health` verb

3. TREATMENT
   Player uses correct healing item (exact type match via `cures` field)
   → Engine validates match (object.cures == injury.type AND injury_def.healing_interactions)
   → FSM transitions to "treated" state
   → .damage_per_tick set to 0 (damage stops accumulating)
   → Existing .damage remains until injury reaches healed state

4. RESOLUTION
   Either:
   a) Timer expires in "treated" → auto-transition to "healed" → removed from array
      → Injury's .damage removed from sum → derived health rises
   b) Timer expires in worsened state → cascades to "fatal" → death check
   c) Derived health hits 0 from accumulated damage → death
```

---

## Player Injury Verb

Players can inspect their injuries via a verb (`injuries` or `check health`):

```lua
-- Verb handler for "injuries" / "check health"
function verb_injuries(player)
    if #player.injuries == 0 then
        print("You feel fine. No injuries.")
        return
    end

    local health = compute_health(player)
    print(string.format("Health: %d/%d", health, player.max_health))

    for _, injury in ipairs(player.injuries) do
        local injury_def = load_injury_definition(injury.type)
        local state_def = injury_def.states[injury._state]
        print(string.format("  - %s (%s) — damage: %d",
            state_def.name, injury._state, injury.damage))
    end
end
```

---

## Injury FSM Conventions

To maintain consistency with the object FSM system:

| Convention | Rule |
|---|---|
| **State names** | Lowercase, descriptive: `active`, `treated`, `healed`, `worsened`, `critical`, `fatal` |
| **Terminal states** | Marked with `terminal = true`. Two kinds: `healed` (remove injury, remove damage) and `fatal` (trigger death) |
| **Timed events** | Same format as objects: `{ event = "transition", delay = N, to_state = "..." }` |
| **Transitions** | Same format: `{ from, to, verb/trigger, condition, message, mutate }` |
| **Sensory text** | Each state has `description`, `on_feel`, `on_look`, `on_smell` (as applicable) |
| **Damage encoding** | `damage_per_tick` in state definition. `0` means no ongoing accumulation. |
| **Damage tracking** | Each instance carries `.damage` — the running total of damage caused. |
| **Timer units** | Seconds (game time). 360 seconds per turn, 3600 seconds per game hour. |
| **Healing specificity** | Healing items match by exact injury `type`. No generic healing. |

---

## Integration with Engine Systems

### FSM Engine Reuse

Injury FSMs use the **same FSM engine** as object FSMs. The `fsm.tick()`, `fsm.transition()`, `fsm.start_timer()`, and `fsm.tick_timers()` functions work on injury instances identically to object instances.

The only difference: injury instances live in `player.injuries[]` instead of the object registry. The engine loop iterates both.

### Derived Health Integration

After ticking all injuries, the engine computes derived health:

```lua
local current_health = compute_health(player)
if current_health <= 0 then
    trigger_death(player, last_damage_source)
end
```

### Engine Hook: `on_death`

When an injury reaches a `fatal` terminal state, or when accumulated injury damage makes derived health ≤ 0, the `on_death` engine hook fires (see [event-handlers.md](../engine/event-handlers.md)).

### Object Authoring (Flanders)

Object authors encode damage and healing interactions in their `.lua` files. They declare:

```lua
-- "This knife inflicts a bleeding injury starting at 25 damage"
on_stab = { injury = "bleeding", initial_damage = 25 }

-- "This antidote cures nightshade poisoning specifically"
on_drink = { cures = "poisoned-nightshade", consumable = true }

-- "This bandage stops bleeding specifically"
on_use = { cures = "bleeding", transition_to = "treated", consumable = true }
```

The engine and injury system handle matching, validation, and FSM transitions.

---

## Design Decisions

| ID | Decision | Rationale |
|---|---|---|
| D-INJURY001 | Injuries are FSMs in `src/meta/injuries/` | Same pattern as objects. Content authors can create new injury types without engine changes. |
| D-INJURY002 | Three damage types: one-time, over-time, degenerative | Covers all gameplay needs. Each type is a configuration of the same FSM engine. |
| D-INJURY003 | Healing items match by EXACT injury type | Antidote-nightshade cures poisoned-nightshade, not poisoned-spider-venom. Forces specific remedies. Supports puzzle design. |
| D-INJURY004 | Injury FSM reuses object FSM engine | No duplicate state machine code. Same `fsm.tick()`, same timer system, same transition format. |
| D-INJURY005 | Multiple simultaneous injuries supported | Realistic. Compound injuries create urgency and resource pressure. |
| D-INJURY006 | Fatal injury state triggers death independently of health | Even if derived health > 0, a fatal state (e.g., sepsis) is game over. Belt and suspenders. |
| D-INJURY007 | Each injury carries `.damage` field | Running total of damage caused. Used for derived health computation. Removed when injury is healed. |
| D-INJURY008 | Dual-side healing validation | Object declares `cures`, injury declares `healing_interactions`. Both must agree. Prevents spoofing. |
| D-INJURY009 | Injury types are specific, not generic | `poisoned-nightshade` not `poisoned`. Specificity enables injury-specific healing matching. |

---

## Related

- [health.md](health.md) — Derived health computation, death
- [inventory.md](inventory.md) — First-class inventory (healing objects are carried items)
- [README.md](README.md) — Player system overview
- [Object Core Principles](../objects/core-principles.md) — FSM pattern reference
- [Engine Event Handlers](../engine/event-handlers.md) — `on_death` hook
