# Player System — Architecture Overview

**Version:** 1.0  
**Author:** Bart (Architect)  
**Date:** 2026-07-22  
**Status:** Design  
**Purpose:** High-level map of all player subsystems and how they interconnect.

---

## Overview

The player is a first-class entity in the game state, tracked as a Lua table (`player.lua`) that the engine keeps up to date each turn. The player system encompasses everything the player IS and everything that happens TO the player.

---

## Subsystems

| Subsystem | Doc | Status |
|---|---|---|
| **Player Model** | [player-model.md](player-model.md) | ✅ Implemented |
| **Movement** | [player-movement.md](player-movement.md) | ✅ Implemented |
| **Sensory** | [player-sensory.md](player-sensory.md) | ✅ Implemented |
| **Health** | [health.md](health.md) | 🔷 Designed |
| **Injuries** | [injuries.md](injuries.md) | 🔷 Designed |

---

## Player Entity Structure

The canonical `player.lua` structure, combining all subsystems:

```lua
player = {
    -- Identity & Location
    current_room = "bedroom",

    -- Inventory (existing)
    hands = { left = nil, right = nil },
    worn = {
        head = nil,
        torso = nil,
        feet = nil,
    },

    -- Skills (existing)
    skills = {
        lockpicking = false,
        sewing = false,
    },

    -- Health System (new)
    health = 100,
    max_health = 100,

    -- Active Injuries (new)
    injuries = {},

    -- Active Effects (new — for future use: buffs, debuffs, environmental)
    effects = {},
}
```

---

## System Interactions

### Health ↔ Injuries

Injuries are the primary mechanism that reduces health. The engine loop iterates the player's `injuries` array each turn and applies damage according to each injury's type and FSM state.

- **One-time injuries** subtract health once on creation, then sit in the array until healed.
- **Over-time injuries** subtract health every turn while in an `active` state.
- **Degenerative injuries** increase their damage output each turn.

See [health.md](health.md) for the damage application pipeline.

### Objects ↔ Health

Objects encode damage and healing in their metadata. The engine does NOT hardcode damage values — object authors control what happens when a verb fires.

- A poison bottle's `.lua` says `on_drink = { damage = 100 }` (lethal).
- A knife's `.lua` says `on_stab = { damage = 25, injury = "laceration" }`.
- A healing potion says `on_drink = { heal = 40 }`.
- A bandage says `on_use = { cures = "bleeding", stops_drain = true }`.

See [health.md](health.md) § Damage Encoding and § Healing.

### Injuries ↔ FSM

Each injury type has its own FSM, following the same pattern as object FSMs (states, transitions, timed_events). Injury FSMs live in `src/meta/injuries/` as individual `.lua` files.

See [injuries.md](injuries.md) for the full FSM specification.

### Engine Loop ↔ Player

The engine loop already ticks object FSMs each turn. The health system adds a **player health tick phase** after the object tick phase:

1. Parse command → dispatch verb
2. Tick object FSMs (existing)
3. **Tick player injuries** (new — iterate `player.injuries`, apply per-turn damage)
4. **Check death condition** (new — `health <= 0` triggers death)
5. Render output

---

## Design Philosophy

1. **Objects own damage values.** The engine applies what objects declare. No hardcoded damage tables.
2. **Injuries are FSMs.** Same pattern as objects — states, transitions, timers. No special-case injury logic.
3. **Engine stays generic.** The engine ticks injuries and applies health changes. Injury behavior is in metadata.
4. **Healing is object-driven.** Healing items declare what they cure and how much they restore. The engine matches healing to injuries.
5. **Player file is the source of truth.** `player.lua` contains health, injuries, and effects. Cloud-persisted each turn.

---

## Related Architecture

- [Object Core Principles](../objects/core-principles.md) — FSM patterns that injuries follow
- [Engine Event Handlers](../engine/event-handlers.md) — Hook system for `on_death`, `on_use`
- [Engine Loop](../engine/) — Turn processing and tick phases
