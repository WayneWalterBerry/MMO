# Player Health System — Architecture

**Version:** 2.0  
**Author:** Bart (Architect)  
**Date:** 2026-07-22  
**Revised:** 2026-07-22 — Health is derived, not stored (Wayne directive 2026-03-21T19:17Z)  
**Status:** Design  
**Purpose:** Technical specification for derived health computation, damage accumulation, healing, and death.

---

## Overview

Health is a **derived value**, not a stored field. There is no `health` property in `player.lua`. Instead, health is computed on every read:

```
current_health = max_health - sum(injury.damage for each active injury)
```

Health is an **emergent property of injuries**. The player's "health number" reflects the aggregate damage of all active injuries. When an injury is healed (removed), its damage contribution disappears and derived health rises automatically.

---

## Health Computation

### The Formula

```lua
function compute_health(player)
    local total_damage = 0
    for _, injury in ipairs(player.injuries) do
        total_damage = total_damage + (injury.damage or 0)
    end
    return math.max(0, player.max_health - total_damage)
end
```

### Properties

| Property | Type | Stored? | Notes |
|---|---|---|---|
| `max_health` | number | ✅ Yes, in player.lua | Base maximum health. Default `100`. Can be modified by effects. |
| `health` | number | ❌ **NOT stored** | Computed: `max_health - sum(injury.damage)`. Never persisted. |
| `injuries` | array | ✅ Yes, in player.lua | Each injury carries a `damage` field — its contribution to health reduction. |

### Rules

- Derived health is clamped: never below `0`, never above `max_health`.
- All damage values are integers. `max_health` is an integer.
- `max_health` can be temporarily reduced by effects (e.g., disease caps max at 60). Derived health recomputes accordingly.
- Health is computed **on read** — any system that needs the health value calls `compute_health(player)`.

### Player.lua Structure (Health-Related Fields)

```lua
-- src/meta/player/player.lua (engine-managed)
return {
    max_health = 100,
    -- NO health field. Health is derived.

    injuries = {
        -- Each injury carries a .damage field: its health cost
        -- {
        --     id = "poisoned-nightshade",
        --     type = "poisoned-nightshade",
        --     damage = 15,            -- This injury's contribution to health reduction
        --     turns_active = 3,
        -- },
        -- {
        --     id = "bleeding-arm-1",
        --     type = "bleeding",
        --     severity = 1,
        --     damage = 20,            -- Accumulated over 4 turns at 5/turn
        --     turns_active = 4,
        -- },
    },

    effects = {},
}
```

---

## How Damage Works Under Derived Health

Under the old model, damage mutated `player.health`. Under the new model, **damage is recorded on the injury itself**. The injury's `damage` field grows over time (for over-time injuries) or is set once (for one-time injuries). Health is never directly mutated.

### Source 1: Verb-Triggered Object Damage (Inflicts an Injury)

When a verb fires against an object that declares damage, the engine creates an injury with an initial `damage` value:

```lua
-- src/meta/objects/rusty-knife.lua
return {
    id = "rusty-knife",
    name = "a rusty knife",

    on_stab_self = {
        injury = "bleeding",           -- Inflicts a bleeding injury
        initial_damage = 25,           -- Injury starts with 25 damage
        message = "You drive the blade into your arm. Blood wells up.",
    },
}
```

**Engine processing:**

```lua
-- Verb handler reads object metadata
local effect = object["on_" .. verb]
if effect and effect.injury then
    injury_system.inflict(player, effect.injury, {
        initial_damage = effect.initial_damage or 0,
        source = object.id,
    })
end
-- No player.health mutation. The new injury's .damage field reduces derived health.
```

### Source 2: Injury Over-Time Damage Accumulation

Over-time injuries increase their `damage` field each turn:

```lua
-- In injury_system.tick():
if injury.damage_per_tick and injury.damage_per_tick > 0 then
    injury.damage = injury.damage + injury.damage_per_tick
end
-- Derived health decreases automatically because sum(injury.damage) grew.
```

### Source 3: One-Time Damage (Flat)

Some objects deal flat damage without a persistent injury (e.g., a lethal poison):

```lua
-- src/meta/objects/poison-bottle.lua
return {
    id = "poison-bottle",
    name = "a bottle of dark liquid",

    on_drink = {
        injury = "lethal-poison",
        initial_damage = 100,          -- Injury starts at 100 damage (lethal if max_health = 100)
        message = "The poison burns through you. Everything goes dark.",
    },
}
```

Even "instant death" works through the injury system. The poison creates an injury with `damage = 100`, which makes `compute_health()` return `0`.

---

## Per-Turn Health Tick

The engine loop computes health each turn after ticking injuries:

```lua
-- In engine loop, after object tick phase:

-- Phase 1: Tick all injuries (advance FSM timers, accumulate damage)
for i, injury in ipairs(player.injuries) do
    local injury_def = load_injury_definition(injury.type)
    local state_def = injury_def.states[injury._state]

    -- Skip terminal states
    if not state_def.terminal then
        -- Accumulate per-turn damage on the injury
        if injury.damage_per_tick and injury.damage_per_tick > 0 then
            injury.damage = injury.damage + injury.damage_per_tick
        end

        -- Degenerative scaling (increase rate)
        if injury_def.damage_type == "degenerative" and injury_def.degenerative then
            local degen = injury_def.degenerative
            injury.damage_per_tick = math.min(
                degen.max_damage,
                injury.damage_per_tick + degen.increment
            )
        end

        -- Tick FSM timer, check for auto-transitions
        injury.turns_active = (injury.turns_active or 0) + 1
        -- ... timer/transition logic same as before ...
    end
end

-- Phase 2: Remove healed injuries
player.injuries = filter_active(player.injuries)

-- Phase 3: Compute derived health and check death
local current_health = compute_health(player)
if current_health <= 0 then
    trigger_death(player, last_damage_source)
end

-- Phase 4: Display injury messages
for _, msg in ipairs(injury_messages) do
    print(msg)
end
```

---

## Death

### Trigger

`compute_health(player) <= 0` after any injury tick or injury infliction.

Equivalently: `sum(injury.damage) >= max_health`.

### Behavior

Death is handled by the `on_death` engine hook (see [event-handlers.md](../engine/event-handlers.md)):

1. All active injuries become irrelevant (player is dead).
2. The engine emits a death message (contextual to the cause).
3. Game over or respawn — determined by game mode configuration.

### Death Messages

Death messages are contextual. The injury or damage source provides the message:

```lua
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

### Principle: Healing Removes Injury Damage (Not "Adds Health")

Under derived health, there is no "add 40 HP" operation. Healing works by:

1. **Curing an injury** — removes the injury from `player.injuries[]`, which removes its `damage` contribution. Derived health rises.
2. **Treating an injury** — transitions the injury FSM to `treated` state, setting `damage_per_tick = 0` so damage stops accumulating. Existing damage remains until the injury reaches `healed` (terminal) state and is removed.

### Healing is Injury-Specific

Healing objects cure **specific** injury types. The match is by exact injury `type`:

- `antidote-nightshade` cures `poisoned-nightshade` — NOT `poisoned-spider-venom`.
- `bandage` treats `bleeding` — NOT `poisoned-nightshade`.
- `antidote-spider-venom` cures `poisoned-spider-venom` — NOT `poisoned-nightshade`.

There is no generic "heal 40 HP" item. All healing flows through the injury system.

### Object Metadata Pattern

```lua
-- src/meta/objects/antidote-nightshade.lua
return {
    id = "antidote-nightshade",
    name = "a vial of nightshade antidote",

    on_drink = {
        cures = "poisoned-nightshade",   -- Exact injury type this cures
        message = "The antidote works. The burning subsides.",
        consumable = true,
    },
}
```

```lua
-- src/meta/objects/bandage.lua
return {
    id = "bandage",
    name = "a clean linen bandage",

    on_use = {
        cures = "bleeding",              -- Exact injury type this treats
        transition_to = "treated",       -- Transitions FSM (doesn't fully remove yet)
        message = "You bind the wound tightly. The bleeding slows, then stops.",
        consumable = true,
    },
}
```

### Engine Processing: Healing

```lua
function injury_system.try_heal(player, healing_object, verb)
    local effect = healing_object["on_" .. verb]
    if not effect or not effect.cures then return false end

    -- Find matching active injury by exact type
    local injury, index = find_injury_by_type(player, effect.cures)
    if not injury then
        print("You don't have that kind of injury.")
        return false
    end

    if effect.transition_to then
        -- Partial healing: transition FSM state (e.g., "active" → "treated")
        injury_system.transition(injury, effect.transition_to)
        injury.damage_per_tick = 0  -- Stop further damage accumulation
    else
        -- Full cure: remove injury entirely
        table.remove(player.injuries, index)
        -- Derived health increases immediately (injury's .damage is gone)
    end

    return true
end
```

---

## Healing Pipeline (Revised)

```
1. Object declares healing          (object.on_verb.cures = "injury-type")
2. Engine reads declaration          (verb handler extracts cures target)
3. Engine finds matching injury      (exact match on injury.type)
4. Injury transitioned or removed    (FSM transition or full removal)
5. Derived health recomputes         (sum of remaining injury.damage)
6. Object consumed                   (if consumable = true)
```

Note: There is no "restore N health" step. Health rises because injury damage was removed.

---

## Status Bar

The terminal UI status bar computes health on read:

```
Health: 75/100 | Room: Kitchen | Injuries: bleeding (active), poisoned-nightshade (active)
```

```lua
-- Status bar rendering:
local health = compute_health(player)
local status = string.format("Health: %d/%d", health, player.max_health)
```

---

## Cloud Persistence

Player injuries, inventory, effects, and `max_health` are persisted to cloud storage each turn. Health is NOT persisted — it is recomputed on load from the injury array.

---

## Design Decisions

| ID | Decision | Rationale |
|---|---|---|
| D-HEALTH001 | Health is derived, not stored | Health is an emergent property of injuries. No stale state, no sync bugs, no "health says 50 but injuries say 80 damage." Single source of truth. |
| D-HEALTH002 | No generic "heal N HP" | All healing flows through injuries. Forces specific remedies (antidote for poison, bandage for bleeding). Supports puzzle design. |
| D-HEALTH003 | Health computed on read | Any system that needs health calls `compute_health()`. No cache, no staleness. |
| D-HEALTH004 | Damage recorded on injury instances | Each injury carries its own `.damage` — the running total of damage it has caused. Engine only mutates injury data. |
| D-HEALTH005 | Death at derived health ≤ 0 | `sum(injury.damage) >= max_health`. Clean threshold. |
| D-HEALTH006 | Damage encoded on objects, not engine | Object authors control gameplay. Engine stays generic. (Preserved from v1.) |

---

## Related

- [injuries.md](injuries.md) — Injury FSM system, injury-specific healing, over-time damage
- [inventory.md](inventory.md) — First-class inventory system
- [README.md](README.md) — Player system overview
- [player-model.md](player-model.md) — Existing player entity structure
- [Engine Event Handlers](../engine/event-handlers.md) — `on_death` hook
- [Object Core Principles](../objects/core-principles.md) — "Engine executes metadata; objects declare behavior"
