# Player Pass 3: player.lua as Canonical State

**Issue:** #104  
**Version:** 1.0  
**Author:** Bart (Architect)  
**Status:** Implemented  

---

## Problem

Player state was split across two locations:

| State | Before | After |
|-------|--------|-------|
| `hands`, `worn`, `skills`, `location`, `injuries`, `consciousness`, `state` | `ctx.player.*` | `ctx.player.*` (unchanged) |
| `visited_rooms` | `ctx.visited_rooms` | `ctx.player.visited_rooms` |

The `visited_rooms` set lived on the context root (`ctx`), not on the player model. This violated the principle that all player state should live in a single canonical location — the player model.

---

## Solution

Moved `visited_rooms` from `ctx` to `ctx.player`:

```lua
-- BEFORE (scattered state)
local context = {
    player = { hands = {...}, location = "bedroom", ... },
    visited_rooms = { [start_room_id] = true },  -- orphaned on context
}

-- AFTER (canonical player state)
local player = {
    hands = { nil, nil },
    worn = {},
    skills = {},
    location = start_room_id,
    max_health = 100,
    injuries = {},
    consciousness = { ... },
    state = { bloody = false, poisoned = false, has_flame = 0 },
    visited_rooms = { [start_room_id] = true },  -- canonical on player
}
```

All reads/writes updated from `ctx.visited_rooms` → `ctx.player.visited_rooms`.

---

## Canonical Player State Model (Post-Pass 3)

```lua
player = {
    -- Identity & position
    location = "room-id",              -- current room ID

    -- Inventory
    hands = { nil, nil },              -- [1]=left, [2]=right hand slots
    worn = {},                         -- array of worn item IDs
    skills = {},                       -- learned skills dict { sewing = true }

    -- Health & injuries
    max_health = 100,                  -- base maximum (health is DERIVED, never stored)
    injuries = {},                     -- active injury instances

    -- Consciousness FSM
    consciousness = {
        state = "conscious",           -- conscious | unconscious | waking
        wake_timer = 0,
        cause = nil,
        unconscious_since = nil,
    },

    -- Session flags
    state = {
        bloody = false,
        poisoned = false,
        has_flame = 0,                 -- match flame ticks remaining
        hints_shown = {},              -- one-shot hint tracking (lazy-init)
    },

    -- World knowledge
    visited_rooms = { ["start-room"] = true },  -- rooms the player has entered
}
```

**Derived state (computed, never stored):**
- Current health = `max_health - sum(injuries[].damage)`
- Appearance text = computed from hands + worn + injuries + blood

---

## Files Changed

| File | Change |
|------|--------|
| `src/main.lua` | Moved `visited_rooms` init from context to player table |
| `src/engine/verbs/movement.lua` | Changed `ctx.visited_rooms` → `ctx.player.visited_rooms` (3 sites) |
| `web/game-adapter.lua` | Same migration for web build entry point |
| `test/verbs/test-engine-hooks-101.lua` | Updated 8 mock contexts |
| `test/verbs/test-movement-verbs.lua` | Updated mock context + 2 test setups |
| `test/verbs/test-spatial-verbs.lua` | Updated mock context |
| `test/parser/test-context-window.lua` | Updated mock context |
| `test/verbs/test-player-canonical-state.lua` | **NEW** — 8 tests validating canonical state |

---

## Design Rules Going Forward

1. **All player state lives on `ctx.player`** — no player-related data on `ctx` root.
2. **New player state fields** go into `ctx.player` (or a sub-table like `ctx.player.state`).
3. **`ctx.current_room`** remains on context — it's a convenience reference to the room object, not player state per se. The canonical location is `ctx.player.location` (room ID string).
4. **Derived state is never stored** — compute health from injuries, compute appearance from worn/hands/injuries.
