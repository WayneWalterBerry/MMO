# Player System — Architecture Overview

**Version:** 2.0  
**Author:** Bart (Architect)  
**Date:** 2026-07-22  
**Revised:** 2026-07-22 — Derived health, first-class inventory, injury-specific healing (Wayne directive 2026-03-21T19:17Z)  
**Status:** Design  
**Purpose:** High-level map of all player subsystems and how they interconnect.

---

## Overview

The player is a first-class entity in the game state, tracked as a Lua table (`player.lua`) that the engine keeps up to date each turn. The player system encompasses everything the player IS and everything that happens TO the player.

**Core invariant:** `player.lua` is the single source of truth for all mutable player state. The engine reads and mutates ONLY this file. There is no separate inventory system, no separate health tracker, no external state. Everything lives here.

---

## Subsystems

| Subsystem | Doc | Status |
|---|---|---|
| **Player Model** | [player-model.md](player-model.md) | ✅ Implemented |
| **Movement** | [player-movement.md](player-movement.md) | ✅ Implemented |
| **Sensory** | [player-sensory.md](player-sensory.md) | ✅ Implemented |
| **Health** | [health.md](health.md) | 🔷 Designed |
| **Injuries** | [injuries.md](injuries.md) | 🔷 Designed |
| **Inventory** | [inventory.md](inventory.md) | 🔷 Designed |

---

## Player Entity Structure

The canonical `player.lua` structure, combining all subsystems:

```lua
player = {
    -- Identity & Location
    current_room = "bedroom",

    -- Maximum health (base value; can be modified by effects)
    max_health = 100,
    -- NO health field. Health is DERIVED: max_health - sum(injury.damage)
    -- See health.md for the computation formula.

    -- Active Injuries — the player's health state
    injuries = {
        { id = "poisoned-nightshade", type = "poisoned-nightshade", turns_active = 3 },
        { id = "bleeding-arm-1", type = "bleeding", severity = 1, turns_active = 4 },
    },

    -- Inventory — first-class nested array of carried objects
    -- Nested because containers hold items (bag contains bandage contains nothing)
    inventory = {
        "brass-key",
        "oil-lantern",
        { id = "leather-bag", contents = { "bandage", "antidote-nightshade" } },
    },

    -- Visited rooms (for tracking exploration state)
    visited_rooms = { "bedroom", "cellar", "storage-cellar" },

    -- Active Effects (buffs, debuffs, environmental modifiers)
    effects = {},

    -- Worn items
    worn = {
        head = nil,
        torso = nil,
        feet = nil,
    },

    -- Skills
    skills = {
        lockpicking = false,
        sewing = false,
    },
}
```

### What's NOT in player.lua

- **`health`** — There is no stored health field. Health is computed on read: `max_health - sum(injury.damage)`. See [health.md](health.md).
- **External state** — No separate inventory database, no separate injury tracker. Everything is here.

---

## System Interactions

### Health ↔ Injuries (Derived Relationship)

Health is NOT stored — it is an emergent property of injuries. The player's current health is computed each time it's needed:

```
current_health = max_health - sum(injury.damage for each active injury)
```

- **One-time injuries** carry a fixed `damage` value that reduces derived health.
- **Over-time injuries** accumulate `damage` each turn while active.
- **Degenerative injuries** increase their accumulated damage faster each turn.

There is no `player.health` to mutate. Healing an injury removes its damage contribution, which raises derived health automatically.

See [health.md](health.md) for the computation formula and engine integration.

### Inventory ↔ Engine

Inventory is a first-class nested array in `player.lua`. The engine mutates this array directly on pickup/drop:

- **Pickup:** Engine appends object ID (or container table) to `player.inventory`.
- **Drop:** Engine removes the entry from `player.inventory` and places the object in the room.
- **Container access:** Engine traverses nested `contents` arrays to find items inside bags.
- **`inventory` verb:** Reads directly from `player.inventory` — no external lookup.

See [inventory.md](inventory.md) for the full specification.

### Healing ↔ Injury-Specific Matching

Healing objects cure SPECIFIC injury types. The match is exact:

- `antidote-nightshade` cures `poisoned-nightshade`, NOT `poisoned-spider-venom`.
- `bandage` stops `bleeding`, NOT `poisoned`.
- The relationship is encoded on the healing object (`cures` field) and validated against the injury's `type`.

See [injuries.md](injuries.md) § Injury-Specific Healing.

### Injuries ↔ FSM

Each injury type has its own FSM, following the same pattern as object FSMs (states, transitions, timed_events). Injury FSMs live in `src/meta/injuries/` as individual `.lua` files.

See [injuries.md](injuries.md) for the full FSM specification.

### Engine Loop ↔ Player

The engine loop ticks object FSMs each turn. The health system adds a **player tick phase** after the object tick phase:

1. Parse command → dispatch verb
2. Tick object FSMs (existing)
3. **Tick player injuries** — iterate `player.injuries`, accumulate per-turn damage, advance FSM timers
4. **Compute derived health** — `max_health - sum(all injury damage)`
5. **Check death condition** — derived health ≤ 0 triggers death
6. Render output (including health in status bar, computed on read)

---

## Design Philosophy

1. **Health is derived, not stored.** There is no `health` field. Health is the difference between `max_health` and the sum of all injury damage. Healing doesn't "add health" — it removes injury damage.
2. **Inventory is first-class.** Carried objects live in `player.lua` as a nested array. The engine mutates this array directly. No external inventory system.
3. **Object resolution is verb-dependent.** When the player targets an object by name (e.g., "take candle" or "light candle"), the search order depends on the verb. Interaction verbs (use, light, drink) prioritize the player's hands; acquisition verbs (take, examine) prioritize the room. See [inventory.md](inventory.md) § Object Resolution Order.
4. **player.lua is the single source of truth.** The engine reads and mutates ONLY this file. Injuries, inventory, effects, visited rooms — all here.
5. **Objects own damage values.** The engine applies what objects declare. No hardcoded damage tables.
6. **Injuries are FSMs.** Same pattern as objects — states, transitions, timers. No special-case injury logic.
7. **Healing is injury-specific.** Each healing object cures a specific injury type. Antidote-A doesn't cure poison-B. The engine matches by exact type.
8. **Engine stays generic.** The engine ticks injuries, computes derived health, mutates inventory. Behavior is in metadata.

---

## Related Architecture

- [Object Core Principles](../objects/core-principles.md) — FSM patterns that injuries follow
- [Engine Event Handlers](../engine/event-handlers.md) — Hook system for `on_death`, `on_use`
- [Engine Loop](../engine/) — Turn processing and tick phases
