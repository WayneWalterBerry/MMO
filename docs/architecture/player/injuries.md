# Injury System — Architecture

**Version:** 1.0  
**Author:** Bart (Architect)  
**Date:** 2026-07-22  
**Status:** Design  
**Purpose:** Technical specification for the injury FSM system, injury types, over-time effects, and healing interactions.

---

## Overview

Injuries are a **state of the player** — a nested array in the player file. Each injury type is defined as its own `.lua` file in `src/meta/injuries/`, following the same FSM pattern used by objects. Injuries have states, transitions, timers, and sensory descriptions.

The engine ticks injuries each turn, just like it ticks object FSMs. Injury behavior is encoded in metadata — the engine stays generic.

---

## File Structure

```
src/meta/injuries/
├── bleeding.lua          -- Laceration / open wound
├── poisoned.lua          -- Toxic substance ingested
├── bruise.lua            -- Blunt force trauma
├── burn.lua              -- Thermal damage
├── infection.lua         -- Wound infection (degenerative)
├── fracture.lua          -- Broken bone
└── ...                   -- Extensible per game content
```

Each file defines a complete FSM for one injury type. Injury authors (Flanders, content team) create these files using the same patterns as object `.lua` files.

---

## Injury Instance Structure

When an injury is inflicted, the engine creates an **instance** from the injury type definition:

```lua
-- Runtime injury instance (stored in player.injuries[])
{
    type = "bleeding",              -- References src/meta/injuries/bleeding.lua
    _state = "active",             -- Current FSM state
    source = "rusty-knife",        -- Object that caused this injury (for messaging)
    inflicted_at = 1200,           -- Game time (seconds) when injury was inflicted
    elapsed = 0,                   -- Seconds since inflicted (for degenerative scaling)

    -- Copied from injury definition, mutable per-instance:
    damage_per_tick = 5,           -- Current per-turn damage (0 for one-time injuries)
    severity = "moderate",         -- For display and healing matching

    -- Timer tracking (managed by FSM engine):
    _timer = {
        remaining = 7200,          -- Seconds until auto-transition
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

    -- Damage behavior per state
    damage_type = "over_time",         -- "one_time" | "over_time" | "degenerative"

    states = {
        active = {
            name = "bleeding",
            description = "Blood seeps steadily from the wound.",
            on_feel = "The wound is wet and warm.",
            on_look = "A deep gash, still bleeding freely.",

            damage_per_tick = 5,       -- Lose 5 health per turn

            -- If untreated for 2 hours (game time), worsens
            timed_events = {
                { event = "transition", delay = 7200, to_state = "worsened" },
            },
        },

        treated = {
            name = "bandaged wound",
            description = "The wound is bound. Bleeding has stopped.",
            on_feel = "Tight bandages cover the wound.",
            on_look = "A bandaged gash. No longer bleeding.",

            damage_per_tick = 0,       -- Bleeding stopped

            -- Natural healing over time
            timed_events = {
                { event = "transition", delay = 14400, to_state = "healed" },
            },
        },

        worsened = {
            name = "infected wound",
            description = "The untreated wound festers. You feel feverish.",
            on_feel = "Hot, swollen. The skin around the wound is inflamed.",
            on_look = "The wound is red and swollen, oozing.",

            damage_per_tick = 10,      -- Accelerated damage

            timed_events = {
                { event = "transition", delay = 3600, to_state = "critical" },
            },
        },

        critical = {
            name = "septic wound",
            description = "Sepsis. Your vision blurs. You can barely stand.",
            on_feel = "Burning fever. The wound is black at the edges.",

            damage_per_tick = 20,      -- Rapidly fatal

            timed_events = {
                { event = "transition", delay = 1800, to_state = "fatal" },
            },
        },

        fatal = {
            name = "fatal blood loss",
            description = "You've lost too much blood.",
            terminal = true,
            -- Engine sets health to 0 on entering a fatal state
        },

        healed = {
            name = "healed wound",
            description = "A faded scar remains.",
            terminal = true,
            -- Engine removes this injury from player.injuries[]
        },
    },

    transitions = {
        -- Verb-triggered (healing items)
        {
            from = "active", to = "treated",
            verb = "bandage",
            requires_tool = "bandage",
            message = "You press the bandage firmly against the wound. The bleeding slows, then stops.",
            mutate = { damage_per_tick = 0 },
        },
        {
            from = "worsened", to = "treated",
            verb = "treat",
            requires_tool = "medicine",
            message = "You apply the medicine. The swelling begins to subside.",
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

    -- What objects can interact with this injury
    healing_interactions = {
        bandage   = { transitions_to = "treated", from_states = { "active" } },
        medicine  = { transitions_to = "treated", from_states = { "active", "worsened" } },
        antidote  = nil,  -- Bandage doesn't cure poison; antidote doesn't cure bleeding
    },
}
```

---

## Injury Types

### Type 1: One-Time Damage

Injury causes a single health decrease at the moment of infliction. No per-turn drain. Healing restores some health.

**Examples:** bruise, cut, blunt trauma

```lua
-- src/meta/injuries/bruise.lua
return {
    id = "bruise",
    name = "Bruise",
    category = "physical",
    damage_type = "one_time",

    initial_state = "active",

    -- One-time damage applied on infliction (not per-tick)
    on_inflict = {
        damage = 10,
        message = "A nasty bruise forms.",
    },

    states = {
        active = {
            name = "bruise",
            description = "A dark, painful bruise.",
            damage_per_tick = 0,           -- No ongoing damage

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
            verb = "treat",
            requires_tool = "healing_salve",
            message = "The salve soothes the bruise. It fades quickly.",
        },
    },
}
```

### Type 2: Over-Time Damage

Injury causes health to decrease each turn while active. Constant rate until treated or fatal.

**Examples:** bleeding, mild poison, exposure

```lua
-- src/meta/injuries/poisoned.lua
return {
    id = "poisoned",
    name = "Poisoned",
    category = "toxin",
    damage_type = "over_time",

    initial_state = "active",

    on_inflict = {
        damage = 15,                       -- Initial damage on contact
        message = "Poison courses through your veins.",
    },

    states = {
        active = {
            name = "poisoned",
            description = "Your stomach churns. Poison burns in your veins.",
            on_feel = "Cold sweat. Trembling hands.",
            on_smell = "A chemical taste at the back of your throat.",

            damage_per_tick = 8,           -- Steady drain each turn

            timed_events = {
                { event = "transition", delay = 5400, to_state = "critical" },
            },
        },

        treated = {
            name = "neutralized poison",
            description = "The antidote is working. The burning fades.",
            damage_per_tick = 0,

            timed_events = {
                { event = "transition", delay = 3600, to_state = "healed" },
            },
        },

        critical = {
            name = "severe poisoning",
            description = "Convulsions. Your body is shutting down.",
            damage_per_tick = 15,

            timed_events = {
                { event = "transition", delay = 1800, to_state = "fatal" },
            },
        },

        fatal = {
            name = "lethal poisoning",
            description = "The poison has won.",
            terminal = true,
        },

        healed = {
            name = "recovered",
            description = "The poison has left your system.",
            terminal = true,
        },
    },

    transitions = {
        {
            from = "active", to = "treated",
            verb = "drink",
            requires_tool = "antidote",
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
            requires_tool = "antidote",
            message = "Just in time. The antidote fights the poison.",
            mutate = { damage_per_tick = 0 },
        },
        {
            from = "critical", to = "fatal",
            trigger = "auto",
            condition = "timer_expired",
            message = "The poison claims you.",
        },
        {
            from = "treated", to = "healed",
            trigger = "auto",
            condition = "timer_expired",
            message = "The last traces of poison leave your body.",
        },
    },

    healing_interactions = {
        antidote = { transitions_to = "treated", from_states = { "active", "critical" } },
    },
}
```

### Type 3: Degenerative Damage

Health decrease accelerates over time. Each turn, `damage_per_tick` increases. Untreated, this kills faster and faster.

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
        damage = 5,
        message = "The wound feels hot. Something is wrong.",
    },

    -- Degenerative scaling: damage increases each tick
    degenerative = {
        base_damage = 2,               -- Starting damage per tick
        increment = 1,                 -- Added to damage each tick
        max_damage = 25,               -- Cap on per-tick damage
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
            verb = "treat",
            requires_tool = "medicine",
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
            verb = "treat",
            requires_tool = "strong_medicine",
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
```

This means:
- Turn 1: 2 damage
- Turn 2: 3 damage
- Turn 3: 4 damage
- ...
- Turn 24+: capped at 25 damage

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
        type = injury_type,
        _state = injury_def.initial_state,
        source = effect.source or "unknown",
        inflicted_at = game_time(),
        elapsed = 0,
        damage_per_tick = injury_def.states[injury_def.initial_state].damage_per_tick or 0,
        severity = effect.severity or "moderate",
        _timer = nil,  -- Started by FSM engine on state entry
    }

    -- 3. Apply one-time infliction damage
    if injury_def.on_inflict and injury_def.on_inflict.damage then
        player.health = math.max(0, player.health - injury_def.on_inflict.damage)
    end

    -- 4. Start FSM timer for initial state
    if injury_def.states[instance._state].timed_events then
        fsm.start_injury_timer(instance, injury_def)
    end

    -- 5. Add to player's injury array
    player.injuries[#player.injuries + 1] = instance

    -- 6. Emit infliction message
    if injury_def.on_inflict and injury_def.on_inflict.message then
        print(injury_def.on_inflict.message)
    end
end
```

---

## Injury Ticking

Each turn, the engine iterates the player's injuries:

```lua
function injury_system.tick(injury, delta_seconds)
    local injury_def = load_injury_definition(injury.type)
    local state_def = injury_def.states[injury._state]
    local result = { damage = 0, message = nil, transition = nil }

    -- Skip terminal states
    if state_def.terminal then
        return result
    end

    -- Apply per-tick damage
    if injury.damage_per_tick and injury.damage_per_tick > 0 then
        result.damage = injury.damage_per_tick
    end

    -- Degenerative scaling
    if injury_def.damage_type == "degenerative" and injury_def.degenerative then
        local degen = injury_def.degenerative
        injury.damage_per_tick = math.min(
            degen.max_damage,
            injury.damage_per_tick + degen.increment
        )
    end

    -- Tick timer
    injury.elapsed = injury.elapsed + delta_seconds
    if injury._timer and not injury._timer.paused then
        injury._timer.remaining = injury._timer.remaining - delta_seconds
        if injury._timer.remaining <= 0 then
            -- Find auto-transition for current state
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

## Healing Interactions

Healing items interact with specific injury types. The matching is declared on BOTH sides:

### Object Side (what the healing item targets)

```lua
-- bandage.lua
on_use = {
    targets_injury = "bleeding",       -- Injury type this item treats
    transition_to = "treated",         -- Target FSM state
    stops_drain = true,
}
```

### Injury Side (what items can treat this injury)

```lua
-- bleeding.lua
healing_interactions = {
    bandage  = { transitions_to = "treated", from_states = { "active" } },
    medicine = { transitions_to = "treated", from_states = { "active", "worsened" } },
}
```

### Matching Logic

When a healing verb fires:

```lua
function injury_system.try_heal(player, healing_object, verb)
    local effect = healing_object["on_" .. verb]
    if not effect or not effect.targets_injury then return false end

    -- Find matching active injury
    local injury = find_active_injury(player, effect.targets_injury)
    if not injury then
        print("You don't have that kind of injury.")
        return false
    end

    -- Check injury accepts this healing item
    local injury_def = load_injury_definition(injury.type)
    local interaction = injury_def.healing_interactions[healing_object.id]
    if not interaction then
        print("That won't help with this injury.")
        return false
    end

    -- Check current state is valid for this interaction
    if not table_contains(interaction.from_states, injury._state) then
        print("It's too late for that to help.")
        return false
    end

    -- Apply healing transition
    injury_system.transition(injury, interaction.transitions_to)
    return true
end
```

---

## Multiple Simultaneous Injuries

A player can have multiple active injuries. The engine processes ALL of them each turn:

```lua
player.injuries = {
    { type = "bleeding",  _state = "active",  damage_per_tick = 5  },
    { type = "poisoned",  _state = "active",  damage_per_tick = 8  },
    { type = "bruise",    _state = "active",  damage_per_tick = 0  },
}
-- Total per-turn damage: 5 + 8 + 0 = 13 health lost per turn
```

Healing items target specific injury types. Using a bandage treats the bleeding but not the poison. The player needs BOTH a bandage AND an antidote.

---

## Injury Lifecycle

```
1. INFLICTION
   Object verb fires → object metadata declares injury type
   → injury_system.inflict() creates instance
   → on_inflict damage applied
   → Instance added to player.injuries[]

2. ACTIVE PHASE
   Each turn: injury ticked → damage_per_tick applied to player.health
   Timer counts down → may auto-transition to worse state
   Player can use healing items → verb triggers FSM transition

3. TREATMENT
   Healing item targets this injury type
   → FSM transitions to "treated" state
   → damage_per_tick set to 0 (bleeding stopped)
   → Timer starts for natural healing

4. RESOLUTION
   Either:
   a) Timer expires in "treated" → auto-transition to "healed" → removed from array
   b) Timer expires in worsened state → cascades to "fatal" → death check
   c) Player health hits 0 from accumulated damage → death
```

---

## Injury FSM Conventions

To maintain consistency with the object FSM system:

| Convention | Rule |
|---|---|
| **State names** | Lowercase, descriptive: `active`, `treated`, `healed`, `worsened`, `critical`, `fatal` |
| **Terminal states** | Marked with `terminal = true`. Two kinds: `healed` (remove injury) and `fatal` (trigger death) |
| **Timed events** | Same format as objects: `{ event = "transition", delay = N, to_state = "..." }` |
| **Transitions** | Same format: `{ from, to, verb/trigger, condition, message, mutate }` |
| **Sensory text** | Each state has `description`, `on_feel`, `on_look`, `on_smell` (as applicable) |
| **Damage encoding** | `damage_per_tick` in state definition. `0` means no ongoing damage. |
| **Timer units** | Seconds (game time). 360 seconds per turn, 3600 seconds per game hour. |

---

## Integration with Engine Systems

### FSM Engine Reuse

Injury FSMs use the **same FSM engine** as object FSMs. The `fsm.tick()`, `fsm.transition()`, `fsm.start_timer()`, and `fsm.tick_timers()` functions work on injury instances identically to object instances.

The only difference: injury instances live in `player.injuries[]` instead of the object registry. The engine loop iterates both.

### Engine Hook: `on_death`

When an injury reaches a `fatal` terminal state, or when accumulated injury damage drops health to 0, the `on_death` engine hook fires (see [event-handlers.md](../engine/event-handlers.md)).

### Object Authoring (Flanders)

Object authors encode damage and healing interactions in their `.lua` files. They don't need to understand the injury FSM engine — they just declare:

```lua
-- "This knife does 25 damage and inflicts bleeding"
on_stab = { damage = 25, injury = "bleeding" }

-- "This potion heals 40 HP"
on_drink = { heal = 40 }

-- "This bandage stops bleeding"
on_use = { targets_injury = "bleeding", transition_to = "treated" }
```

The engine and injury system handle the rest.

---

## Design Decisions

| ID | Decision | Rationale |
|---|---|---|
| D-INJURY001 | Injuries are FSMs in `src/meta/injuries/` | Same pattern as objects. Content authors can create new injury types without engine changes. |
| D-INJURY002 | Three damage types: one-time, over-time, degenerative | Covers all gameplay needs. Each type is a configuration of the same FSM engine. |
| D-INJURY003 | Healing items declare target injury type | Specific matching prevents "heal everything" items. Forces puzzle-like resource management. |
| D-INJURY004 | Injury FSM reuses object FSM engine | No duplicate state machine code. Same `fsm.tick()`, same timer system, same transition format. |
| D-INJURY005 | Multiple simultaneous injuries supported | Realistic. Compound injuries create urgency and resource pressure. |
| D-INJURY006 | Fatal injury state triggers death independently of health | Even if health > 0, a fatal state (e.g., sepsis) is game over. Belt and suspenders. |

---

## Related

- [health.md](health.md) — Health tracking, damage pipeline, death
- [README.md](README.md) — Player system overview
- [Object Core Principles](../objects/core-principles.md) — FSM pattern reference
- [Engine Event Handlers](../engine/event-handlers.md) — `on_death` hook
