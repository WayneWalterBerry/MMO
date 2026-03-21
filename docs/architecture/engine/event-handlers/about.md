# Engine Event Hooks

**Version:** 1.0  
**Date:** 2026-07-22  
**Author:** Bart (Lead Engineer)  
**Status:** Design — not yet implemented (except `on_traverse`)  
**Audience:** Engine developers, content authors (for metadata format)

---

## 1. What Are Engine Hooks?

Engine Hooks are **engine-built handler functions** that fire in response to game events — a player entering a room, picking up an object, combining items, or passing through an exit. They are the engine's extension points for gameplay behavior that goes beyond simple state machines.

### Why "Engine Hooks" and not…

| Candidate | Why Not |
|-----------|---------|
| **"Verb Handlers"** | Wayne's initial suggestion. Good intuition — many hooks fire in response to verbs (pick up → `on_pickup`). But not all hooks are verb-triggered: `on_timer`, `on_first_visit`, and `on_enter_room` fire from engine events, not player commands. "Verb Handler" would mislead authors into thinking every hook maps to a verb. |
| **"Event Handlers"** | Technically accurate but too generic. Every callback in the engine could be called an "event handler." This name would collide with FSM's `on_transition`, `timed_events`, and threshold callbacks, which are a different system. |
| **"Engine Hooks"** ✅ | Clear origin: these live in the **engine**, not in metadata. Clear mechanism: they **hook into** the game loop at defined points. Distinguishes cleanly from FSM (data-driven) and from verb dispatch (player-facing). The `on_` prefix convention reinforces the hook metaphor. |

---

## 2. How Engine Hooks Differ from FSM

This is the most important distinction in the architecture. Both systems respond to game events, but they work at different levels:

| | **Engine Hooks** | **FSM** |
|---|---|---|
| **Who creates them** | Engine developers (Lua code in `src/engine/`) | Content authors (metadata in `.lua` object files) |
| **Where they live** | Engine modules (`src/engine/hooks/`) | Object metadata (`states`, `transitions`, `timed_events`) |
| **What they do** | React to game-wide events (movement, inventory changes, time passing) | Manage per-object state transitions (lit→extinguished, locked→unlocked) |
| **How they're defined** | `register(hook_type, handler_fn)` in engine code | Declarative tables in object `.lua` files |
| **Data flow** | Metadata declares WHAT hook to invoke + parameters; engine dispatches | Object owns its full state machine definition |
| **Can trigger FSM?** | ✅ Yes — hooks frequently cause FSM transitions | FSM does not invoke hooks |

### Example: How They Interact

The wind draft puzzle demonstrates both systems working together:

```
Player types "go up"
  → Engine: handle_movement() fires
    → Engine Hook: on_traverse dispatches to wind_effect handler
      → wind_effect checks inventory for lit candle
        → FSM: transitions candle from "lit" → "extinguished"
          → Object metadata: extinguished state applies (casts_light = false)
```

The hook (`on_traverse`) is engine code. The state transition (`lit → extinguished`) is FSM. The hook *triggers* the FSM transition — they collaborate but don't overlap.

---

## 3. Architecture

### 3.1 Module Structure

```
src/engine/hooks/
  init.lua          -- Hook registry + dispatch (the only file that exists today as traverse_effects.lua)
  on_traverse.lua   -- Exit-effect handlers (EXISTING, to be moved here)
  on_enter_room.lua -- Room arrival handlers (FUTURE)
  on_pickup.lua     -- Inventory acquisition handlers (FUTURE)
  ...
```

### 3.2 Registry Pattern

Every hook type uses the same registration pattern established by `traverse_effects.lua`:

```lua
-- src/engine/hooks/init.lua

local hooks = {}
local registry = {}  -- { hook_type = { subtype = handler_fn } }

--- Register a handler for a specific hook type and subtype.
-- @param hook_type string  e.g. "on_traverse", "on_pickup"
-- @param subtype   string  e.g. "wind_effect", "curse_effect"
-- @param handler   function(effect_data, ctx) -> nil
function hooks.register(hook_type, subtype, handler)
    registry[hook_type] = registry[hook_type] or {}
    registry[hook_type][subtype] = handler
end

--- Dispatch a hook. Called by the engine at the appropriate moment.
-- @param hook_type string     Which hook is firing
-- @param effect    table      The metadata-declared effect (type + parameters)
-- @param ctx       table      Engine context (player, registry, current_room, etc.)
-- @return boolean  true if a handler ran, false if no matching handler
function hooks.dispatch(hook_type, effect, ctx)
    if not effect or not effect.type then return false end
    local type_registry = registry[hook_type]
    if not type_registry then return false end
    local handler = type_registry[effect.type]
    if not handler then return false end
    handler(effect, ctx)
    return true
end

--- Dispatch all hooks in a list (for fields that accept multiple effects).
-- @param hook_type string
-- @param effects   table|nil  Single effect table or array of effect tables
-- @param ctx       table
function hooks.dispatch_all(hook_type, effects, ctx)
    if not effects then return end
    if effects.type then
        hooks.dispatch(hook_type, effects, ctx)
        return
    end
    for _, effect in ipairs(effects) do
        hooks.dispatch(hook_type, effect, ctx)
    end
end

return hooks
```

### 3.3 Metadata Declaration

Content authors declare hooks in their metadata files using a consistent pattern:

```lua
-- In a room file (exit hook)
exits = {
    down = {
        target = "deep-cellar",
        on_traverse = {
            type = "wind_effect",
            strength = "gust",
            extinguishes = { "candle" },
            message_extinguish = "A chill updraft snuffs your candle!",
        },
    },
}

-- In a room file (room-level hook)
on_enter_room = {
    type = "ambiance",
    message = "Water drips steadily from the ceiling.",
    sound = "drip_drip",
}

-- In an object file (object-level hook)
on_pickup = {
    type = "curse_effect",
    curse = "weight",
    message = "The ring feels heavier than it should...",
}
```

### 3.4 Integration Points

Each hook type has exactly ONE integration point in the engine — the place where `hooks.dispatch()` is called:

| Hook Type | Integration Point | When It Fires |
|-----------|------------------|---------------|
| `on_traverse` | `handle_movement()` in `verbs/init.lua` | After exit validation, BEFORE player moves |
| `on_enter_room` | `handle_movement()` in `verbs/init.lua` | AFTER player arrives in new room |
| `on_leave_room` | `handle_movement()` in `verbs/init.lua` | BEFORE player leaves current room |
| `on_pickup` | `take` verb handler | AFTER item added to inventory |
| `on_drop` | `drop` verb handler | AFTER item removed from inventory |
| `on_examine` | `look` / `examine` verb handler | AFTER description displayed |
| `on_combine` | `use X with Y` verb handler | AFTER combination validated |
| `on_use` | `use` verb handler | WHEN player uses an item on a target |
| `on_timer` | `fsm.tick_all()` in game loop | WHEN turn counter hits threshold |
| `on_first_visit` | `handle_movement()` in `verbs/init.lua` | AFTER arrival, only if room not in `visited_rooms` |
| `on_death` | Death handler (future) | WHEN player health reaches zero |
| `on_npc_react` | NPC system (future) | WHEN NPC observes a player action |

---

## 4. Hook Catalog

### 4.1 `on_traverse` — Exit Effects ✅ IMPLEMENTED

**Fires:** When player moves through an exit.  
**Timing:** BEFORE player location changes (origin room context available).  
**Declared on:** Exit metadata in room files.  
**Existing implementation:** `src/engine/traverse_effects.lua`

**Built-in subtypes:**
- `wind_effect` — Extinguishes unprotected light sources. Respects `wind_resistant` property on objects.

**Future subtypes to consider:**
- `water_effect` — Damages non-waterproof items, extinguishes fire sources, soaks player
- `narrow_passage` — Blocks oversized items, forces dropping large inventory
- `heat_effect` — Damages flammable items, burns player if unprotected
- `tripwire` — Triggers trap if player doesn't have disarm skill

**Example metadata:**
```lua
on_traverse = {
    type = "wind_effect",
    strength = "gust",
    extinguishes = { "candle" },
    spares = { wind_resistant = true },
    message_extinguish = "A chill updraft snuffs your candle!",
    message_spared = "Your lantern holds steady in the draft.",
}
```

---

### 4.2 `on_enter_room` — Room Arrival Effects

**Fires:** When player arrives in a room.  
**Timing:** AFTER player location changes, AFTER `on_enter` description prints.  
**Declared on:** Room metadata.

**Subtypes to consider:**
- `ambiance` — Print atmospheric text, play sound cue
- `trap` — Falling rocks, pit trap, gas release (check player skills/items for avoidance)
- `npc_greeting` — NPC reacts to player entering their space
- `environmental_damage` — Room is on fire, flooded, freezing (tick-based damage)
- `discovery` — Reveal a hidden object or passage on entry

**Example metadata:**
```lua
on_enter_room = {
    type = "trap",
    trap_type = "falling_rocks",
    damage = 2,
    avoid_skill = "agility",
    avoid_message = "You dodge the falling stones!",
    hit_message = "Rocks crash down on you from above!",
}
```

**Note:** This is distinct from the existing `on_enter` callback on rooms. `on_enter` is a simple description function (`return string`). `on_enter_room` is a dispatched engine hook that can have side effects (damage, state changes, spawns).

---

### 4.3 `on_leave_room` — Room Departure Effects

**Fires:** When player leaves a room.  
**Timing:** BEFORE player location changes (current room context available).  
**Declared on:** Room metadata.

**Subtypes to consider:**
- `lock_behind` — Door locks after player passes through
- `collapse` — Passage collapses, making return impossible (one-way effect)
- `npc_farewell` — NPC reacts to player leaving
- `alarm` — Triggers alert in connected rooms (guard system)

**Example metadata:**
```lua
on_leave_room = {
    type = "lock_behind",
    exit = "north",
    message = "The heavy door slams shut behind you. You hear the bolt slide home.",
    locked_description = "A heavy iron door, locked from the other side.",
}
```

---

### 4.4 `on_pickup` — Item Acquisition Effects

**Fires:** When player takes an object.  
**Timing:** AFTER item is added to inventory (item is in player's possession).  
**Declared on:** Object metadata.

**Subtypes to consider:**
- `curse_effect` — Cursed item affects player stats, can't be dropped
- `weight_burden` — Item is deceptively heavy, slows player
- `npc_react` — NPC objects to player taking their property
- `discovery` — Picking up the item reveals something underneath
- `trigger_fsm` — Taking the item triggers a state change elsewhere (remove item from altar → door opens)

**Example metadata:**
```lua
on_pickup = {
    type = "curse_effect",
    curse = "cannot_drop",
    stat_penalty = { strength = -1 },
    message = "The ring slides onto your finger and won't come off.",
    remove_condition = "bless_spell",
}
```

---

### 4.5 `on_drop` — Item Drop Effects

**Fires:** When player drops an object.  
**Timing:** AFTER item is removed from inventory.  
**Declared on:** Object metadata.

**Subtypes to consider:**
- `fragile_break` — Item shatters when dropped (triggers FSM → broken state)
- `spill` — Liquid container empties, affects room/nearby objects
- `npc_react` — NPC picks up dropped item, comments on it
- `placement_trigger` — Dropping item on specific surface triggers puzzle (place gem on pedestal)

**Example metadata:**
```lua
on_drop = {
    type = "fragile_break",
    break_state = "shattered",
    spawns = { "glass_shards" },
    message = "The vial shatters on the stone floor! Liquid seeps between the cracks.",
}
```

---

### 4.6 `on_examine` — Examination Discovery Effects

**Fires:** When player examines an object closely.  
**Timing:** AFTER the object's description is displayed.  
**Declared on:** Object metadata.

**Subtypes to consider:**
- `reveal_hidden` — Examination reveals a hidden object or detail (secret compartment)
- `knowledge_gain` — Player learns something (add to journal, unlock skill)
- `trigger_fsm` — Examination changes the object's state (disturbing the dust reveals an inscription)
- `one_time` — Effect only fires once (tracked via `examined` flag)

**Example metadata:**
```lua
on_examine = {
    type = "reveal_hidden",
    reveals = "secret_compartment",
    requires_skill = "perception",
    message = "You notice a thin seam in the wood. There's a hidden compartment here!",
    fail_message = "An ordinary wooden box, well-made but unremarkable.",
}
```

---

### 4.7 `on_combine` — Item Combination Effects

**Fires:** When player uses one item with another.  
**Timing:** AFTER combination is validated (both items exist, are accessible).  
**Declared on:** Either item's metadata (or a recipe registry).

**Subtypes to consider:**
- `craft` — Two items combine into a new item (key + string = key_on_string)
- `chemical_reaction` — Mixing produces an effect (acid + lock = dissolved_lock)
- `repair` — One item repairs another (thread + torn_cloth = mended_cloth)
- `fail_spectacularly` — Wrong combination causes damage or destroys items

**Example metadata:**
```lua
on_combine = {
    type = "craft",
    partner = "string",
    produces = "key_on_string",
    consumes_self = false,
    consumes_partner = true,
    requires_skill = "knots",
    message = "You tie the string securely around the key.",
}
```

---

### 4.8 `on_use` — Item Use Effects

**Fires:** When player uses an item on a target (object, exit, or NPC).  
**Timing:** AFTER the use action is validated.  
**Declared on:** Object metadata (the item being used).

**Subtypes to consider:**
- `key_unlock` — Use key on locked door/container
- `tool_apply` — Use tool on object (crowbar on crate, oil on hinge)
- `consumable` — Use potion/food on self (health, buff, vision)
- `weapon` — Use weapon on target (combat future)

**Example metadata:**
```lua
on_use = {
    type = "tool_apply",
    target_keyword = "hinge",
    effect = "lubricate",
    message = "You oil the rusty hinges. The door swings freely now.",
    target_mutation = { squeaky = false },
}
```

---

### 4.9 `on_timer` — Turn-Based Timed Effects

**Fires:** When a specified number of turns have elapsed.  
**Timing:** During `tick_all()` in the game loop, after FSM timers are processed.  
**Declared on:** Room metadata or object metadata.

**Note:** This is different from FSM `timed_events` which trigger state transitions on a single object. `on_timer` is for room-wide or game-wide effects that aren't tied to one object's state machine.

**Subtypes to consider:**
- `rising_water` — Room floods over N turns (escape puzzle)
- `torch_countdown` — Room-mounted torch burns down, room goes dark
- `npc_patrol` — NPC arrives/leaves room on schedule
- `environmental_shift` — Temperature changes, weather shifts

**Example metadata:**
```lua
on_timer = {
    type = "rising_water",
    start_turn = 0,
    interval = 5,
    stages = {
        { turn = 5,  message = "Water begins seeping under the door." },
        { turn = 10, message = "The water is ankle-deep now." },
        { turn = 15, message = "Water rises to your waist. You need to get out!" },
        { turn = 20, message = "The water closes over your head.", effect = "drown" },
    },
}
```

---

### 4.10 `on_first_visit` — One-Time Room Events

**Fires:** When player enters a room for the first time.  
**Timing:** AFTER `on_enter_room`, only if room is not in `ctx.visited_rooms`.  
**Declared on:** Room metadata.

**Note:** The engine already tracks `ctx.visited_rooms` and gives a full `look` on first visit vs. short description on revisit. This hook extends that with side effects.

**Subtypes to consider:**
- `cutscene` — Extended narrative text on first entry
- `spawn` — Objects appear only on first visit (NPC flees, item materializes)
- `set_flag` — Set a game flag that other systems can check
- `trigger_elsewhere` — First visit to room A causes a change in room B

**Example metadata:**
```lua
on_first_visit = {
    type = "cutscene",
    narrative = {
        "The door creaks open to reveal a vast underground chamber.",
        "Stalactites hang from the ceiling like stone teeth.",
        "In the center, a stone pedestal holds a glowing orb.",
    },
    delay_between_lines = 1,
}
```

---

### 4.11 `on_npc_react` — NPC Reaction Effects (Future)

**Fires:** When an NPC observes a player action in the same room.  
**Timing:** AFTER the triggering action completes.  
**Declared on:** NPC metadata.

**Subtypes to consider:**
- `dialogue` — NPC comments on player's action
- `mood_shift` — NPC disposition changes (friendly → hostile)
- `block_action` — NPC intervenes to prevent an action
- `assist` — NPC helps with player's action

---

### 4.12 `on_death` — Player Death Effects (Future)

**Fires:** When player health/state reaches a terminal condition.  
**Timing:** BEFORE game-over sequence.  
**Declared on:** Room or object that caused the death.

**Subtypes to consider:**
- `narrative_death` — Custom death text per cause
- `respawn` — Player respawns at checkpoint with penalties
- `ghost_mode` — Player continues as ghost (multiverse tie-in)

---

## 5. Implementing a New Hook Type

This section is a step-by-step guide for any engineer adding a new hook type.

### Step 1: Create the handler module

```lua
-- src/engine/hooks/on_pickup.lua
local hooks = require("engine.hooks")

-- Handler for curse_effect subtype
local function curse_handler(effect, ctx)
    local item = ctx.target  -- the picked-up item
    if effect.curse == "cannot_drop" then
        item.droppable = false
    end
    if effect.stat_penalty then
        for stat, penalty in pairs(effect.stat_penalty) do
            ctx.player[stat] = (ctx.player[stat] or 0) + penalty
        end
    end
    if effect.message then
        print(effect.message)
    end
end

-- Register subtype(s)
hooks.register("on_pickup", "curse_effect", curse_handler)
```

### Step 2: Add the dispatch call at the integration point

```lua
-- In the relevant verb handler (e.g., take verb in verbs/init.lua)
local hooks = require("engine.hooks")

-- ... after item is added to inventory ...
if item.on_pickup then
    hooks.dispatch("on_pickup", normalize_effect(item.on_pickup), ctx)
end
```

### Step 3: Add metadata to an object

```lua
-- src/meta/objects/cursed-ring.lua
return {
    id = "cursed-ring",
    name = "a tarnished silver ring",
    on_pickup = {
        type = "curse_effect",
        curse = "cannot_drop",
        message = "The ring slides onto your finger and won't come off.",
    },
}
```

### Step 4: Write tests

```lua
-- test/hooks/test-on-pickup.lua
-- Test: curse_effect sets droppable = false
-- Test: curse_effect applies stat penalty
-- Test: item without on_pickup is unaffected
-- Test: unknown subtype is silently ignored (no crash)
-- Test: nil/missing fields are handled gracefully
```

### Step 5: Document the subtype

Add the subtype to this document's catalog (Section 4) with metadata format and behavior description.

---

## 6. Design Rules

1. **Hooks are engine code.** They live in `src/engine/hooks/`. Content authors never write hook handler code — they declare hook metadata in their `.lua` files.

2. **One integration point per hook type.** Each hook fires from exactly one place in the engine. This keeps the dispatch predictable and debuggable.

3. **Hooks don't block.** They execute synchronously but should not loop or wait. Print messages, mutate state, trigger FSM — then return.

4. **Hooks can trigger FSM, but FSM doesn't trigger hooks.** This prevents circular dispatch. If an FSM transition needs to cause a game event, it should set a flag that the game loop checks.

5. **Unknown subtypes are silently ignored.** If metadata declares `type = "future_thing"` and no handler is registered, `dispatch()` returns false. No crash. This allows forward-compatible metadata.

6. **Normalize input formats.** Following the `on_traverse` lesson (BUG-060), always accept both flat `{ type = "X", ... }` and nested `{ X = { ... } }` formats via a `normalize_effect()` utility.

7. **Objects own their properties; hooks declare the condition.** A wind hook checks `obj.wind_resistant` — it doesn't carry a list of resistant objects. A trap hook checks `player.agility` — it doesn't list who can dodge.

8. **Timing is documented and fixed.** BEFORE-move vs. AFTER-move matters for narrative order. Each hook type documents its timing, and that timing doesn't change.

---

## 7. Migration Plan

The existing `traverse_effects.lua` is the prototype for this system. When we implement the full hook architecture:

1. **Rename** `src/engine/traverse_effects.lua` → `src/engine/hooks/on_traverse.lua`
2. **Create** `src/engine/hooks/init.lua` with the generic registry (Section 3.2)
3. **Update** `verbs/init.lua` to use `hooks.dispatch("on_traverse", ...)` instead of `traverse_effects.process(...)`
4. **Existing tests continue to pass** — the API surface for `on_traverse` doesn't change, just its home.
5. **Add new hook types** one at a time as gameplay requires them.

---

## 8. Relationship to Other Systems

```
┌─────────────────────────────────────────────────┐
│                   Game Loop                      │
│  read command → parse → verb dispatch → tick     │
│                                                  │
│  ┌──────────────┐    ┌──────────────────────┐   │
│  │ Engine Hooks  │───▶│  FSM (per-object)    │   │
│  │              │    │                      │   │
│  │ on_traverse  │    │ states/transitions   │   │
│  │ on_enter_room│    │ timed_events         │   │
│  │ on_pickup    │    │ thresholds           │   │
│  │ on_drop      │    │ on_transition (cb)   │   │
│  │ on_examine   │    │                      │   │
│  │ on_combine   │    │                      │   │
│  │ ...          │    │                      │   │
│  └──────┬───────┘    └──────────────────────┘   │
│         │                                        │
│         ▼                                        │
│  ┌──────────────┐    ┌──────────────────────┐   │
│  │   Registry    │    │  Verb System          │   │
│  │ (object store)│    │ (31 verbs, dispatch)  │   │
│  └──────────────┘    └──────────────────────┘   │
└─────────────────────────────────────────────────┘

Hooks → can trigger FSM transitions (one-way dependency)
Hooks → can mutate objects via registry
Hooks → can print messages to player
Verbs → fire hooks at defined integration points
FSM   → does NOT fire hooks (no circular dispatch)
```

---

## Appendix A: Quick Reference

| Hook | Declared On | Fires | Timing |
|------|-------------|-------|--------|
| `on_traverse` | Exit | Player moves through exit | Before move |
| `on_enter_room` | Room | Player arrives in room | After move, after description |
| `on_leave_room` | Room | Player departs room | Before move |
| `on_pickup` | Object | Player takes item | After inventory add |
| `on_drop` | Object | Player drops item | After inventory remove |
| `on_examine` | Object | Player examines item | After description |
| `on_combine` | Object | Player combines items | After validation |
| `on_use` | Object | Player uses item on target | After validation |
| `on_timer` | Room/Object | Turn count reached | During tick |
| `on_first_visit` | Room | First entry to room | After on_enter_room |
| `on_npc_react` | NPC | NPC observes action | After action |
| `on_death` | Room/Object | Player dies | Before game-over |
