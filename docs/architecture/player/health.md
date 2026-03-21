# Player Health System — Architecture

**Version:** 1.0  
**Author:** Bart (Architect)  
**Date:** 2026-07-22  
**Status:** Design  
**Purpose:** Technical specification for health tracking, damage application, healing, and death.

---

## Overview

Health is a numeric, mutable property of the player. It declines from injury and recovers from healing. The engine tracks health in `player.lua` and updates it each turn.

---

## Health Properties

```lua
player = {
    health = 100,         -- Current health (0–max_health)
    max_health = 100,     -- Maximum health (can be modified by effects)
    injuries = {},        -- Active injury instances (see injuries.md)
    effects = {},         -- Future: buffs, debuffs, environmental modifiers
}
```

### Rules

| Property | Type | Range | Default |
|---|---|---|---|
| `health` | number | `0` to `max_health` | `100` |
| `max_health` | number | `1+` | `100` |

- Health is clamped: never below `0`, never above `max_health`.
- Health is an integer. All damage and healing values are integers.
- `max_health` can be temporarily reduced by effects (e.g., disease caps your max at 60).

---

## Damage Sources

### Principle: Damage is Encoded on the Object, Not the Engine

This is a foundational design decision. The engine does not contain damage tables. Every damage value originates from an object's `.lua` metadata. Object authors (Flanders) control how much damage their objects deal.

The engine's role is to **read the damage declaration and apply it**. Nothing more.

### Source 1: Verb-Triggered Object Damage

When a verb fires against an object that declares damage, the engine applies it.

**Object metadata pattern:**

```lua
-- src/meta/objects/poison-bottle.lua
return {
    id = "poison-bottle",
    name = "a bottle of dark liquid",

    on_drink = {
        damage = 100,                    -- Flat health reduction
        message = "The poison burns through you. Everything goes dark.",
    },
}
```

```lua
-- src/meta/objects/rusty-knife.lua
return {
    id = "rusty-knife",
    name = "a rusty knife",

    on_stab_self = {
        damage = 25,                     -- Flat health reduction
        injury = "laceration",           -- Also inflicts an injury (see injuries.md)
        message = "You drive the blade into your arm. Blood wells up.",
    },
}
```

**Engine processing:**

```lua
-- Pseudocode: verb handler reads object metadata
local effect = object["on_" .. verb]
if effect and effect.damage then
    player.health = math.max(0, player.health - effect.damage)
end
if effect and effect.injury then
    injury_system.inflict(player, effect.injury, effect)
end
```

### Source 2: Injury Over-Time Damage

Some injuries cause health to decrease each turn while active. This is NOT encoded on the triggering object — it's encoded on the injury definition in `src/meta/injuries/`.

See [injuries.md](injuries.md) § Over-Time Damage.

### Source 3: Actions Against the Player (Future)

In future phases, external actors can damage the player:

- **NPC attacks:** NPC metadata encodes attack damage
- **Traps:** Trap object metadata encodes trigger damage
- **Environmental damage:** Room properties (fire, cold, toxic gas) cause per-turn damage

These follow the same principle: **damage is encoded in the source entity's metadata**, not the engine.

---

## Damage Application Pipeline

Every source of damage flows through a single pipeline:

```
1. Source declares damage   (object.on_verb.damage = N)
2. Engine reads declaration  (verb handler extracts damage value)
3. Modifiers applied         (future: armor reduces damage)
4. Health reduced            (player.health -= final_damage)
5. Clamp to zero             (player.health = max(0, player.health))
6. Injury inflicted          (if source declares an injury type)
7. Death check               (if health <= 0, trigger death)
```

### Step 3: Damage Modifiers (Future)

Placeholder for armor, resistances, buffs. Not in Phase 1. When implemented:

```lua
-- Future: armor reduction
local armor = get_worn_armor(player)
local reduction = armor and armor.damage_reduction or 0
local final_damage = math.max(1, declared_damage - reduction)
```

### Step 7: Death Check

After ANY health reduction, the engine checks:

```lua
if player.health <= 0 then
    trigger_death(player, damage_source)
end
```

---

## Death

### Trigger

`player.health <= 0` after any damage application (verb, injury tick, or environmental).

### Behavior

Death is handled by the `on_death` engine hook (see [event-handlers.md](../engine/event-handlers.md)):

1. All active injuries become irrelevant (player is dead).
2. The engine emits a death message (contextual to the cause).
3. Game over or respawn — determined by game mode configuration.

### Death Messages

Death messages are contextual. The damage source provides the message:

```lua
-- Object-caused death
on_drink = {
    damage = 100,
    death_message = "The poison claims your life.",
}

-- Injury-caused death (bleeding out)
-- Defined in injury FSM terminal state
states = {
    fatal = {
        message = "You bleed out. The world fades.",
        terminal = true,
    },
}
```

If no specific death message is provided, the engine uses a generic fallback: `"You have died."`

---

## Healing

### Principle: Healing is Object-Driven

Just like damage, healing is encoded on objects. A healing potion's `.lua` file declares how much it heals. The engine reads and applies.

### Healing Types

#### Type 1: Flat Health Restore

Object restores a fixed amount of health.

```lua
-- src/meta/objects/healing-potion.lua
return {
    id = "healing-potion",
    name = "a glowing red potion",

    on_drink = {
        heal = 40,                       -- Restore 40 health
        message = "Warmth floods through you. You feel stronger.",
        consumable = true,               -- Potion is consumed on use
    },
}
```

**Engine processing:**

```lua
if effect.heal then
    player.health = math.min(player.max_health, player.health + effect.heal)
end
```

#### Type 2: Stop Over-Time Drain

Object stops an active injury from draining health each turn, without restoring health.

```lua
-- src/meta/objects/bandage.lua
return {
    id = "bandage",
    name = "a clean linen bandage",

    on_use = {
        stops_drain = true,              -- Stops per-turn damage
        targets_injury = "bleeding",     -- Only works on bleeding-type injuries
        transition_to = "treated",       -- Transitions injury FSM to "treated" state
        message = "You bind the wound tightly. The bleeding slows, then stops.",
        consumable = true,
    },
}
```

**Engine processing:**

```lua
if effect.stops_drain and effect.targets_injury then
    local injury = find_active_injury(player, effect.targets_injury)
    if injury then
        injury_system.transition(injury, effect.transition_to or "treated")
    end
end
```

#### Type 3: Cure Specific Injury

Object fully heals a specific injury type, transitioning its FSM to `healed` and restoring associated health.

```lua
-- src/meta/objects/antidote.lua
return {
    id = "antidote",
    name = "a vial of clear antidote",

    on_drink = {
        cures = "poisoned",             -- Cures poisoned injury type
        heal = 20,                       -- Also restores some health
        message = "The antidote works. The burning subsides.",
        consumable = true,
    },
}
```

**Engine processing:**

```lua
if effect.cures then
    local injury = find_active_injury(player, effect.cures)
    if injury then
        injury_system.transition(injury, "healed")
        remove_injury(player, injury)
    end
end
if effect.heal then
    player.health = math.min(player.max_health, player.health + effect.heal)
end
```

---

## Healing Pipeline

```
1. Object declares healing     (object.on_verb.heal = N, .cures = "type")
2. Engine reads declaration     (verb handler extracts healing data)
3. Health restored              (player.health += heal, clamped to max)
4. Injury cured/transitioned   (if .cures or .targets_injury specified)
5. Injury removed from array   (if cured to "healed" terminal state)
6. Object consumed              (if consumable = true)
```

---

## Per-Turn Health Update

The engine loop gains a new phase after object FSM ticking:

```lua
-- In engine loop, after object tick phase:

-- Phase: Player Health Tick
local injury_messages = {}
for i, injury in ipairs(player.injuries) do
    local result = injury_system.tick(injury, SECONDS_PER_TICK)
    if result.damage then
        player.health = math.max(0, player.health - result.damage)
    end
    if result.message then
        injury_messages[#injury_messages + 1] = result.message
    end
    if result.transition then
        injury_system.transition(injury, result.transition)
    end
end

-- Remove healed injuries
player.injuries = filter_active(player.injuries)

-- Death check
if player.health <= 0 then
    trigger_death(player, last_damage_source)
end

-- Display injury messages
for _, msg in ipairs(injury_messages) do
    print(msg)
end
```

---

## Player File Structure (Complete)

```lua
-- src/meta/player/player.lua (engine-managed)
return {
    health = 100,
    max_health = 100,

    hands = { left = nil, right = nil },
    worn = { head = nil, torso = nil, feet = nil },
    skills = { lockpicking = false, sewing = false },

    injuries = {
        -- Active injury instances (populated at runtime)
        -- Example:
        -- {
        --     type = "bleeding",           -- References src/meta/injuries/bleeding.lua
        --     _state = "active",           -- Current FSM state
        --     source = "rusty-knife",      -- What caused this injury
        --     inflicted_at = 1200,         -- Game time when inflicted
        --     damage_per_tick = 5,         -- Current per-turn damage
        -- },
    },

    effects = {
        -- Future: buffs, debuffs, environmental modifiers
    },
}
```

---

## Integration Points

### Verb Handlers

Verb handlers check for `on_<verb>` metadata on the target object. If damage or healing is declared, they call into the health system:

```lua
-- In verb handler (e.g., drink):
local effect = target_object.on_drink
if effect then
    if effect.damage then
        health_system.apply_damage(player, effect.damage, target_object)
    end
    if effect.heal then
        health_system.apply_heal(player, effect.heal)
    end
    if effect.injury then
        injury_system.inflict(player, effect.injury, effect)
    end
    if effect.cures then
        injury_system.cure(player, effect.cures)
    end
end
```

### Status Bar

The terminal UI status bar displays current health:

```
Health: 75/100 | Room: Kitchen | Injuries: bleeding (active)
```

### Cloud Persistence

Player health, injuries, and effects are persisted to cloud storage each turn, alongside hands, worn items, and skills. The `player.lua` file is the canonical representation.

---

## Design Decisions

| ID | Decision | Rationale |
|---|---|---|
| D-HEALTH001 | Damage encoded on objects, not engine | Object authors control gameplay. Engine stays generic. |
| D-HEALTH002 | Single damage pipeline for all sources | Consistent behavior. One place for armor/modifier logic. |
| D-HEALTH003 | Health is integer, clamped 0–max | Simple, deterministic. No floating-point edge cases. |
| D-HEALTH004 | Death at health ≤ 0 | Clean threshold. No negative health states. |
| D-HEALTH005 | Healing items declare targets | Bandage targets "bleeding", antidote targets "poisoned". Generic engine, specific objects. |

---

## Related

- [injuries.md](injuries.md) — Injury FSM system, over-time damage, degenerative injuries
- [README.md](README.md) — Player system overview
- [player-model.md](player-model.md) — Existing player entity structure
- [Engine Event Handlers](../engine/event-handlers.md) — `on_death` hook
- [Object Core Principles](../objects/core-principles.md) — "Engine executes metadata; objects declare behavior"
