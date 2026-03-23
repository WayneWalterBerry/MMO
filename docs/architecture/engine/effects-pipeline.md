# Unified Effect Processing Pipeline — Architecture

**Version:** 1.0  
**Date:** 2026-07-26  
**Author:** Bart (Architect)  
**Status:** Architecture Specification  
**Decision:** D-EFFECTS-PIPELINE  
**Requested by:** Wayne "Effe" Berry  
**Prerequisite reading:** `event-hooks.md` (hook taxonomy + gap analysis)

---

## 1. Problem Statement

### 1.1 Current State

Today, when an object causes something to happen — an injury, a status effect, a narration — the **verb handler** contains inline code that interprets the object's metadata and calls the appropriate subsystem. Three distinct patterns exist:

| Pattern | Example | Where the logic lives |
|---------|---------|----------------------|
| **String tag on transition** | `effect = "poison"` on drink transition | Drink verb handler checks `trans.effect == "poison"`, calls `injuries.inflict()` with hardcoded parameters |
| **String tag on state** | `on_taste_effect = "poison"` on open state | Taste verb handler checks `obj.on_taste_effect == "poison"`, runs inline death sequence with `os.exit(0)` |
| **Structured table on state** | `on_feel_effect = { type = "inflict_injury", ... }` | Not yet consumed — verb handlers don't read structured effect tables |

The inline handling is brittle. The drink verb hardcodes `"poisoned-nightshade"` as the injury type for any `"poison"` string. The taste verb runs an entirely separate death sequence that bypasses the injury system entirely. Both patterns share a fundamental flaw.

### 1.2 The Core Violation

Every new injury-causing object requires editing engine verb handler code. This violates Principle 8:

> *"All behavior declared in metadata, zero engine knowledge needed."*

Today, the engine **knows** that `"poison"` means nightshade. The engine **knows** that tasting poison should print specific death text and call `os.exit(0)`. The engine decides the injury type, the damage, the narration — all information that should live in the object.

### 1.3 What This Costs

- **New poison types** (viper venom, mild food poisoning) require verb handler edits for each trigger verb
- **New effect categories** (buffs, debuffs, healing, environmental) have no standard path
- **Inconsistent behavior** — drinking poison goes through the injury system; tasting poison bypasses it entirely and calls `os.exit(0)` directly
- **Duplicated logic** — each sensory verb re-implements its own effect dispatch (`on_taste_effect`, `on_feel_effect`, etc.)
- **Content authors** (Flanders, CBG) cannot add injury-causing objects without engine changes

### 1.4 What Already Works

The good news: Flanders has already built two objects (`poison-bottle.lua`, `bear-trap.lua`) using the **structured effect table format** proposed in `event-hooks.md`. The objects are ready. The engine just can't read them yet.

```lua
-- Already in poison-bottle.lua (Flanders)
effect = {
    type = "inflict_injury",
    injury_type = "poisoned-nightshade",
    source = "poison-bottle",
    damage = 10,
    message = "A bitter, almost sweet taste burns down your throat...",
}
```

The pipeline we need is a ~100-line module that bridges these declarations to the existing subsystems.

---

## 2. Proposed Architecture: Effect Processing Pipeline

### 2.1 Design Principle

Objects declare **what** happens (structured effect tables). The engine decides **when** it happens (hook integration points). The effect processor decides **how** it happens (dispatch to subsystems). Clean three-way separation.

```
OBJECT says: "When someone drinks me, inflict poisoned-nightshade at damage 10"
ENGINE says: "A drink transition just fired, and it has an effect table"
PIPELINE says: "This is an inflict_injury effect — routing to injuries.inflict()"
```

No component knows the other's business. No hardcoded mappings. No verb handler edits for new objects.

### 2.2 Effect Declaration Format

Objects declare effects as structured Lua tables attached to hook points in their metadata. Every effect has a `type` field that identifies the processor, plus type-specific parameters:

```lua
-- Consumption effect (on FSM transition)
transitions = {
    {
        from = "open", to = "empty", verb = "drink",
        message = "You raise the bottle to your lips...",
        effect = {
            { type = "inflict_injury", injury_type = "poisoned-nightshade",
              source = "poison-bottle", damage = 10 },
            { type = "narrate",
              message = "A bitter, almost sweet taste burns down your throat." },
            { type = "mutate", target = "self", field = "is_consumable",
              value = false },
        },
    },
}

-- Contact effect (on sensory verb)
states = {
    set = {
        on_feel = "SNAP! The jaws clamp shut on your hand!",
        on_feel_effect = {
            { type = "inflict_injury", injury_type = "crushing-wound",
              source = "bear-trap", location = "hand", damage = 15 },
            { type = "narrate",
              message = "The trap's iron jaws crush your hand. Pain whites out your vision." },
        },
    },
}

-- Proximity effect (on room entry — future)
on_enter_room = {
    { type = "inflict_injury", injury_type = "bruised", source = "pit-trap",
      location = "leg", damage = 6 },
    { type = "narrate", message = "The floor gives way! You tumble into a shallow pit." },
}
```

**Single effect shorthand:** When only one effect fires, a bare table (without the array wrapper) is accepted:

```lua
effect = { type = "inflict_injury", injury_type = "minor-cut", damage = 3 }
```

The processor normalizes both forms internally.

### 2.3 Effect Types

The pipeline ships with these built-in effect types. Each maps to an existing subsystem:

| Effect Type | What It Does | Subsystem Called | Parameters |
|-------------|-------------|-----------------|------------|
| `inflict_injury` | Applies an injury to the player | `injuries.inflict()` | `injury_type`, `source`, `location`, `damage` |
| `narrate` | Prints a message to the player | `print()` / narrator | `message`, `style` (optional) |
| `mutate` | Changes a field on an object | mutation system | `target`, `field`, `value` |
| `add_status` | Adds a status condition to the player | player state | `status`, `duration`, `severity` |
| `remove_status` | Removes a status condition | player state | `status` |
| `trigger_event` | Fires a named event into the game loop | event dispatch | `event`, `args` |
| `fsm_transition` | Forces a state change on another object | `fsm.transition()` | `target_id`, `to_state`, `verb_hint` |
| `spawn_object` | Creates a new object in the world | loader + registry | `template`, `location`, `overrides` |
| `destroy_object` | Removes an object from the world | registry | `target_id` |
| `play_sound` | Emits a sound description (future: audio) | narrator | `sound`, `intensity` |

**Day-one implementation:** `inflict_injury` and `narrate`. These cover all current use cases (poison bottle, bear trap, glass shard). Other types are registered as the subsystems that back them come online.

### 2.4 Effect Processor Module (`effects.lua`)

```lua
-- src/engine/effects.lua
-- Unified effect processor. Objects declare effects; this module routes them.
--
-- Ownership: Bart (Architect)
-- Decision: D-EFFECTS-PIPELINE

local effects = {}
local handlers = {}

--- Register a handler for an effect type.
-- @param effect_type  string           The type value (e.g. "inflict_injury")
-- @param handler_fn   function(effect, ctx) -> boolean
function effects.register(effect_type, handler_fn)
    handlers[effect_type] = handler_fn
end

--- Normalize legacy string effects to structured tables.
local legacy_map = {
    poison = { type = "inflict_injury", injury_type = "poisoned-nightshade",
               source = "unknown", damage = 10 },
    cut    = { type = "inflict_injury", injury_type = "minor-cut",
               source = "unknown", damage = 3 },
    burn   = { type = "inflict_injury", injury_type = "burn",
               source = "unknown", damage = 5 },
    bruise = { type = "inflict_injury", injury_type = "bruised",
               source = "unknown", damage = 4 },
    nausea = { type = "add_status", status = "nauseated", duration = 12 },
}

function effects.normalize(raw)
    if type(raw) == "string" then
        local mapped = legacy_map[raw]
        if mapped then
            local copy = {}
            for k, v in pairs(mapped) do copy[k] = v end
            return { copy }
        end
        return nil
    end
    if type(raw) == "table" then
        if raw.type then return { raw } end      -- single effect
        if raw[1] then return raw end              -- array of effects
    end
    return nil
end

--- Process an effect declaration.
-- Accepts: string ("poison"), single table ({type=...}), or array of tables.
-- @param raw    string|table   The effect declaration from object metadata
-- @param ctx    table          Game context (player, registry, source object, etc.)
-- @return boolean              true if at least one effect was processed
function effects.process(raw, ctx)
    local effect_list = effects.normalize(raw)
    if not effect_list then return false end

    local any = false
    for _, effect in ipairs(effect_list) do
        -- before_effect hook: interceptors can cancel or modify
        local cancelled = effects._run_interceptors("before", effect, ctx)
        if not cancelled then
            local handler = handlers[effect.type]
            if handler then
                handler(effect, ctx)
                any = true
            end
            -- after_effect hook: post-processing
            effects._run_interceptors("after", effect, ctx)
        end
    end
    return any
end

--- Interceptor registry for before/after hooks.
local interceptors = { before = {}, after = {} }

function effects.add_interceptor(phase, fn)
    interceptors[phase] = interceptors[phase] or {}
    interceptors[phase][#interceptors[phase] + 1] = fn
end

function effects._run_interceptors(phase, effect, ctx)
    for _, fn in ipairs(interceptors[phase] or {}) do
        local result = fn(effect, ctx)
        if phase == "before" and result == "cancel" then
            return true  -- cancelled
        end
    end
    return false
end

return effects
```

### 2.5 Processing Flow

The complete path from player input to subsystem action:

```
Player types "drink bottle"
  │
  ▼
Parser → verb = "drink", target = "poison-bottle"
  │
  ▼
Drink verb handler:
  1. Resolves object in player's hands
  2. Finds FSM transition: { from="open", to="empty", verb="drink" }
  3. Executes FSM transition (state changes to "empty")
  4. Applies mutation table (weight, keywords, categories)
  5. Checks: does transition have an .effect field?
     │
     ├── YES → effects.process(trans.effect, ctx)
     │           │
     │           ▼
     │         effects.normalize(trans.effect)
     │           │
     │           ▼
     │         For each effect in list:
     │           │
     │           ├── Run before_effect interceptors
     │           │     (armor check? resistance? can modify/cancel)
     │           │
     │           ├── Dispatch to handler by effect.type
     │           │     ├── "inflict_injury" → injuries.inflict(player, ...)
     │           │     ├── "narrate"        → print(effect.message)
     │           │     ├── "add_status"     → player.statuses[status] = {...}
     │           │     └── "mutate"         → obj[field] = value
     │           │
     │           └── Run after_effect interceptors
     │                 (narration hooks, achievement checks)
     │
     └── NO → continue (no effects)
  │
  ▼
  6. Prints transition message
  │
  ▼
Post-command: injuries.tick(player) runs on game loop tick
```

### 2.6 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        EFFECT SOURCES                               │
│                                                                     │
│  FSM Transition         Sensory Callback        Engine Hook         │
│  (trans.effect)         (on_feel_effect)        (on_enter_room)     │
│       │                       │                      │              │
│       └───────────┬───────────┴──────────────────────┘              │
│                   ▼                                                 │
│         ┌──────────────────┐                                        │
│         │ effects.process()│                                        │
│         └────────┬─────────┘                                        │
│                  │                                                  │
│         ┌────────▼─────────┐                                        │
│         │ effects.normalize│  Accepts: string | table | array       │
│         │ (legacy compat)  │  Returns: array of {type=...} tables   │
│         └────────┬─────────┘                                        │
│                  │                                                  │
│         ┌────────▼─────────┐                                        │
│         │ before_effect    │  Interceptors: cancel, modify          │
│         │ interceptors     │  (e.g. armor reduces damage)           │
│         └────────┬─────────┘                                        │
│                  │                                                  │
│    ┌─────────────┼─────────────┬──────────────┬──────────────┐      │
│    ▼             ▼             ▼              ▼              ▼      │
│ ┌────────┐ ┌─────────┐ ┌──────────┐ ┌───────────┐ ┌──────────┐    │
│ │inflict │ │ narrate  │ │ mutate   │ │add_status │ │ trigger  │    │
│ │_injury │ │          │ │          │ │           │ │ _event   │    │
│ │        │ │ print()  │ │ obj[k]=v │ │player.    │ │ event    │    │
│ │injuries│ │ narrator │ │ mutation │ │statuses[] │ │ dispatch │    │
│ │.inflict│ │          │ │          │ │           │ │          │    │
│ └────────┘ └─────────┘ └──────────┘ └───────────┘ └──────────┘    │
│    │                                                                │
│    ▼                                                                │
│ ┌────────────────┐                                                  │
│ │ after_effect    │  Interceptors: cleanup, achievement triggers     │
│ │ interceptors    │  (e.g. "first injury" achievement)              │
│ └────────────────┘                                                  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. Integration Points

### 3.1 Verb Handlers → Effect Processor

Every verb handler that currently checks for effect strings gets a surgical refactoring. The pattern is identical each time:

**Before (current — inline dispatch):**
```lua
-- In drink verb handler (line ~4840)
if trans.effect == "poison" then
    local inj_ok, injury_mod = pcall(require, "engine.injuries")
    if inj_ok then
        injury_mod.inflict(ctx.player, "poisoned-nightshade", obj.id)
        -- ... hardcoded death check, hardcoded narration
    end
end
```

**After (unified — one-line delegation):**
```lua
-- In drink verb handler
if trans.effect then
    effects.process(trans.effect, ctx)
end
```

That's it. The object's effect table carries the injury type, damage, source, and message. The pipeline routes it. The verb handler doesn't know or care what happens.

### 3.2 Sensory Verbs → Effect Processor

Each sensory verb (feel, taste, smell, listen, look) follows the same post-pattern:

**Before (current — per-verb inline checks):**
```lua
-- In taste verb handler (line ~2146)
if obj.on_taste_effect then
    if obj.on_taste_effect == "poison" then
        print("Fire courses through your veins...")
        print("*** YOU HAVE DIED ***")
        os.exit(0)  -- bypasses injury system entirely!
    elseif obj.on_taste_effect == "nausea" then
        print("Your stomach lurches...")
        ctx.player.state.nauseated = true
    end
end
```

**After (unified):**
```lua
-- In taste verb handler
local state = fsm_mod.get_state_def(obj)
if state and state.on_taste_effect then
    effects.process(state.on_taste_effect, ctx)
end
```

This applies to all five sensory verbs. The convention is `on_{sense}_effect` on the current FSM state:

| Hook Field | Verb(s) | Example Object |
|------------|---------|----------------|
| `on_feel_effect` | feel, touch | Bear trap (crushing-wound), glass shard (minor-cut) |
| `on_taste_effect` | taste, lick | Poison bottle in open state (poisoned-nightshade) |
| `on_smell_effect` | smell, sniff | Noxious gas cloud (nausea status) |
| `on_listen_effect` | listen, hear | Banshee wail (fear status — future) |
| `on_look_effect` | look, examine | Medusa gaze (petrification — future) |

### 3.3 Injury System Integration

The `inflict_injury` handler calls the existing `injuries.inflict()` API with no changes:

```lua
effects.register("inflict_injury", function(effect, ctx)
    local injury_mod = require("engine.injuries")
    local instance = injury_mod.inflict(
        ctx.player,
        effect.injury_type,
        effect.source or ctx.source_id or "unknown",
        effect.location,
        effect.damage
    )
    if effect.message then
        print(effect.message)
    end
    -- Check for instant death
    if instance then
        local health = injury_mod.compute_health(ctx.player)
        if health <= 0 and ctx then
            ctx.game_over = true
        end
    end
    return instance
end)
```

The injury system's existing API (`inflict()`, `tick()`, `compute_health()`, `try_heal()`) is unchanged. The pipeline is an adapter, not a replacement.

### 3.4 Narration Integration

Effects can include narration at three points:

1. **Transition message** — printed by the verb handler as usual (before effects fire)
2. **Effect message** — printed by the effect handler (during effect processing)
3. **After-effect narration** — printed by `after_effect` interceptors (after all effects resolve)

Example sequence for drinking poison:

```
> drink bottle
You raise the bottle to your lips...              ← transition message (verb handler)
A bitter, almost sweet taste burns down your       ← effect.message (inflict_injury handler)
  throat. Your heart begins to race.
Your vision blurs. The room tilts sideways.        ← after_effect interceptor (optional)
```

For the day-one implementation, the transition message and effect message cover all cases. The `after_effect` narrative hook exists for future atmospheric text (e.g., room reactions to the player's injury).

### 3.5 FSM State Transition Connection

Effects fire **after** the FSM transition has been applied. This is deliberate:

1. Transition executes → object state changes (e.g., bottle: open → empty)
2. Mutations apply → object properties update (weight, keywords, categories)
3. Effects fire → subsystems activate (injury inflicted, narration printed)

This ordering guarantees that the object is in its **post-transition state** when effects fire. An `after_effect` interceptor that inspects the object sees the new state, not the old one.

**Exception:** `before_effect` interceptors fire before the effect handler runs, but still after the FSM transition. This is correct — the interceptor can cancel the effect (e.g., immunity), but it cannot undo the state transition. The bottle is empty regardless of whether the poison takes hold (the player drank the liquid; whether the poison works is a separate question).

### 3.6 GOAP Planning Integration

The GOAP planner (`goal_planner.lua`) already reads `prerequisites` tables on objects. Effect declarations don't change GOAP planning — the planner doesn't need to understand effects, only state requirements.

However, objects that cause effects SHOULD declare GOAP-visible consequences in their prerequisites to enable avoidance planning:

```lua
prerequisites = {
    drink = {
        requires_state = "open",
        -- GOAP hint: planner knows this action has consequences
        warns = { "injury", "poisoned-nightshade" },
    },
}
```

The `warns` field is advisory — the planner can use it for future "avoid danger" goals, but it's not required for day-one.

---

## 4. Before/After Hook Pattern

### 4.1 Design Origin

Classic interactive fiction (Inform, TADS) uses a three-phase pattern for actions: **before** (can prevent), **during** (the action), **after** (consequences). This is proven architecture for effect modification without violating encapsulation.

### 4.2 Three-Phase Effect Processing

```
Phase 1: BEFORE_EFFECT
  │  Interceptors run in registration order
  │  Any interceptor can return "cancel" to abort the effect
  │  Interceptors can modify the effect table in-place
  │  Use cases: armor damage reduction, poison immunity, resistance checks
  │
  ▼
Phase 2: EFFECT
  │  The registered handler for effect.type executes
  │  Handler calls the target subsystem (injuries, narration, etc.)
  │  This is the "actual thing happening"
  │
  ▼
Phase 3: AFTER_EFFECT
  │  Interceptors run in registration order
  │  Cannot cancel (effect already happened)
  │  Use cases: achievement triggers, NPC reactions, log entries, narration
```

### 4.3 Interceptor Examples

**Armor reduces injury damage (before_effect):**

```lua
effects.add_interceptor("before", function(effect, ctx)
    if effect.type ~= "inflict_injury" then return end
    local armor = ctx.player and ctx.player.worn_armor
    if armor and armor.damage_reduction then
        effect.damage = math.max(1, effect.damage - armor.damage_reduction)
        print("Your " .. armor.name .. " absorbs some of the blow.")
    end
end)
```

**Poison immunity cancels effect (before_effect):**

```lua
effects.add_interceptor("before", function(effect, ctx)
    if effect.type ~= "inflict_injury" then return end
    if not effect.injury_type then return end
    local player = ctx.player
    if player.immunities and player.immunities[effect.injury_type] then
        print("You feel the poison trying to take hold, but your body resists.")
        return "cancel"
    end
end)
```

**Achievement trigger (after_effect):**

```lua
effects.add_interceptor("after", function(effect, ctx)
    if effect.type == "inflict_injury" and effect.injury_type == "poisoned-nightshade" then
        ctx.player.achievements = ctx.player.achievements or {}
        ctx.player.achievements["tasted_death"] = true
    end
end)
```

### 4.4 Interceptor Ordering

Interceptors run in registration order (first registered, first called). The engine registers built-in interceptors at startup. Objects and systems register their own interceptors via the effects module's public API.

For day-one, no interceptors are registered. The before/after infrastructure exists but runs empty — zero overhead when unused.

---

## 5. Extensibility

### 5.1 Adding New Effect Types

New effect types require **zero changes** to the pipeline module. A system registers its handler at startup:

```lua
-- In src/engine/buffs.lua (hypothetical future module)
local effects = require("engine.effects")

effects.register("add_buff", function(effect, ctx)
    ctx.player.buffs = ctx.player.buffs or {}
    ctx.player.buffs[#ctx.player.buffs + 1] = {
        id = effect.buff_type,
        duration = effect.duration or 10,
        magnitude = effect.magnitude or 1,
    }
    if effect.message then print(effect.message) end
end)
```

That's it. Any object can now declare `{ type = "add_buff", buff_type = "strength", duration = 5 }` and the pipeline routes it. No verb handler changes. No pipeline changes.

### 5.2 Planned Future Effect Types

| Effect Type | Subsystem | Use Case | Priority |
|-------------|-----------|----------|----------|
| `add_buff` | buff/debuff system | Strength potion, speed boost | Medium |
| `remove_buff` | buff/debuff system | Debuff cure, buff expiration | Medium |
| `heal_injury` | injury system | Antidote application, bandage | High (pairs with inflict) |
| `environmental_damage` | room hazard system | Fire, flooding, cold | Low |
| `teleport` | room/movement system | Teleportation scroll, trap door | Low |
| `modify_skill` | skill system | Temporary skill boost/penalty | Medium |
| `create_light` | lighting system | Magic illumination | Low |

### 5.3 Multi-Effect Sequences

Objects can declare arrays of effects that execute in order:

```lua
effect = {
    { type = "narrate", message = "The liquid burns like fire..." },
    { type = "inflict_injury", injury_type = "poisoned-nightshade", damage = 10 },
    { type = "add_status", status = "hallucinating", duration = 5 },
    { type = "mutate", target = "self", field = "is_consumable", value = false },
}
```

Each effect in the array runs its own before/after interceptor cycle. If a `before_effect` interceptor cancels one effect, the remaining effects still process. This is intentional — armor might block the injury but not the hallucination.

### 5.4 Multiplayer Considerations

For effects on other players (future MMO feature), the ctx table carries the target:

```lua
-- Effect targeting another player (future)
effect = {
    type = "inflict_injury",
    injury_type = "bleeding",
    target = "other_player",  -- resolved by ctx at runtime
    source = "silver-dagger",
    damage = 5,
}
```

The `inflict_injury` handler checks `effect.target`:
- `nil` or `"self"` → `ctx.player` (current behavior)
- `"other_player"` → `ctx.target_player` (set by combat system)
- A specific player ID → resolved from player registry

This is a future extension. Day-one always targets `ctx.player`.

---

## 6. Migration Path

### 6.1 Backward Compatibility

The `effects.normalize()` function guarantees zero-breakage migration. String effects still work:

```lua
-- Legacy format (still works)
effect = "poison"
-- normalize() → { { type = "inflict_injury", injury_type = "poisoned-nightshade", ... } }

-- New format (preferred)
effect = { type = "inflict_injury", injury_type = "poisoned-nightshade", damage = 10 }
-- normalize() → { { type = "inflict_injury", ... } }

-- Array format (multiple effects)
effect = {
    { type = "inflict_injury", ... },
    { type = "narrate", ... },
}
-- normalize() → returns as-is
```

The legacy map covers all currently used string tags: `"poison"`, `"cut"`, `"burn"`, `"bruise"`, `"nausea"`. Any string not in the map is silently ignored (logged in debug mode).

### 6.2 Migration Phases

**Phase 1: Create the pipeline (engine change)**
- Create `src/engine/effects.lua` with `process()`, `normalize()`, `register()`
- Register `inflict_injury` and `narrate` handlers
- Wire before/after interceptor infrastructure (empty day-one)
- No object changes needed. No verb handler changes yet.

**Phase 2: Refactor verb handlers (engine change)**
- Replace inline effect checks with `effects.process()` calls
- Surgical edits — each replacement is 1-3 lines replacing 10-20 lines
- Specific locations:
  - **Drink handler** (line ~4840): Replace `if trans.effect == "poison"` block with `effects.process(trans.effect, ctx)`
  - **Taste handler** (line ~2146): Replace `if obj.on_taste_effect == "poison"` block with `effects.process(state.on_taste_effect, ctx)`
  - **Feel handler**: Replace `if obj.on_feel_effect == "cut"` block with `effects.process(state.on_feel_effect, ctx)`
  - Add generic post-sensory hook: `if state.on_{verb}_effect then effects.process(...) end`

**Phase 3: Object migration (object changes — Flanders owns)**
- Objects already using structured effects (poison-bottle, bear-trap): already done
- Objects using string effects: migrate at Flanders's pace
- Legacy strings continue to work via `normalize()`

**Phase 4: Register future handlers (as subsystems arrive)**
- `add_status` when status system exists
- `heal_injury` when antidote objects are built
- `add_buff` when buff/debuff system is designed

### 6.3 Verb Handlers Requiring Refactoring

| Handler | File Location | Current Pattern | Effort |
|---------|--------------|-----------------|--------|
| `drink` | `verbs/init.lua` ~line 4840 | `trans.effect == "poison"` → hardcoded `injuries.inflict()` | Small: 1 line replaces ~20 |
| `taste` | `verbs/init.lua` ~line 2146 | `on_taste_effect == "poison"` → inline death + `os.exit(0)` | Small: 1 line replaces ~15, **fixes `os.exit(0)` bug** |
| `feel` | `verbs/init.lua` | `on_feel_effect == "cut"` → inline `injuries.inflict()` | Small: 1 line replaces ~5 |
| `stab`/`cut`/`hit` | `verbs/init.lua` | `obj.on_stab` table → direct `injuries.inflict()` | Medium: already structured, route through pipeline |

**Bonus fix:** The taste handler currently calls `os.exit(0)` on poison, bypassing the injury system entirely. Migrating to the pipeline fixes this — the `inflict_injury` handler goes through `injuries.inflict()` properly, enabling healing, antidotes, and survival mechanics.

### 6.4 What Does NOT Change

- **FSM architecture** — states, transitions, timers, thresholds: untouched
- **Injury system API** — `injuries.inflict()`, `tick()`, `compute_health()`, `try_heal()`: untouched
- **Verb dispatch** — parser → verb handler flow: untouched
- **Object metadata format** — backward compatible, existing objects work as-is
- **GOAP planner** — reads prerequisites, not effects: untouched
- **Traverse effects** — `traverse_effects.lua` continues to work independently (future: may route through pipeline)

---

## 7. Relationship to Existing Architecture

### 7.1 Layer Position

The effect processor sits at **Layer 3.6** in the architecture stack, between the hook framework (Layer 3.5) and the verb system (Layer 4):

```
Layer 5:  Meta-code (object .lua files)        — declares effects
Layer 4:  Verb system (verbs/init.lua)          — triggers effects
Layer 3.6: Effect processor (effects.lua)       — routes effects    ← NEW
Layer 3.5: Hook framework (traverse_effects)    — fires on events
Layer 3:  FSM engine (fsm/init.lua)             — manages state
Layer 2:  Injury system (injuries.lua)          — receives effects
Layer 1:  Registry + Loader                     — stores objects
```

### 7.2 Document Relationships

| Document | Relationship |
|----------|-------------|
| `event-hooks.md` | **Prerequisite.** Identified the gap, proposed the solution, defined the taxonomy. This document is the implementation spec. |
| `event-handlers/about.md` | **Sibling.** Defines the 12-hook framework. The effect processor connects to hooks as an output pathway. |
| `docs/design/objects/poison-bottle.md` | **Consumer.** CBG's design drives the consumption pipeline requirements. |
| `docs/design/objects/bear-trap.md` | **Consumer.** CBG's design drives the contact pipeline requirements. |
| `00-architecture-overview.md` | **Parent.** This document adds Layer 3.6 to the architecture stack. |

### 7.3 Traverse Effects: Convergence Path

`traverse_effects.lua` is an independent effect processor for exit-traversal effects (wind extinguishes candles). It has its own registry pattern: `traverse_effects.register(type, handler)`.

Long-term, traverse effects can route through the unified pipeline:

```lua
-- Future: traverse_effects.lua delegates to effects.lua
traverse_effects.register("trap_effect", function(effect, ctx)
    effects.process(effect, ctx)
end)
```

This is not a day-one change. The two systems coexist cleanly.

---

## 8. Implementation Sizing

| Task | Owner | Effort | Priority | Enables |
|------|-------|--------|----------|---------|
| Create `src/engine/effects.lua` | Bart | ~80 lines | **P0** | Everything |
| Register `inflict_injury` handler | Bart | ~15 lines | **P0** | All injury-causing objects |
| Register `narrate` handler | Bart | ~5 lines | **P0** | Effect-attached narration |
| Refactor drink verb handler | Bart | ~3 lines (replaces ~20) | **P1** | Poison bottle via pipeline |
| Refactor taste verb handler | Bart | ~3 lines (replaces ~15) | **P1** | Taste effects via pipeline + fixes `os.exit` bug |
| Refactor feel verb handler | Bart | ~3 lines (replaces ~5) | **P1** | Contact effects via pipeline |
| Generic `on_{sense}_effect` hook | Bart | ~10 lines | **P1** | All sensory effects generalized |
| Wire before/after interceptors | Bart | Already in P0 module | **P2** | Armor, resistance, immunity |
| Register `add_status` handler | Bart | ~10 lines | **P2** | Nausea, hallucination, fear |
| Migrate `traverse_effects` | Bart | ~20 lines | **P3** | Unified pipeline for all effects |

**Total day-one (P0 + P1): ~120 lines of new code, ~60 lines of deletions.**

---

## Appendix A: Complete Effect Declaration Reference

```lua
-- inflict_injury: Apply injury to player via injuries.inflict()
{ type = "inflict_injury",
  injury_type = "poisoned-nightshade",  -- REQUIRED: matches meta/injuries/{type}.lua
  source = "poison-bottle",              -- object that caused it (for narration)
  location = "hand",                     -- body location (nil = systemic)
  damage = 10,                           -- override initial_damage from definition
  message = "The pain is blinding.",     -- printed after infliction
}

-- narrate: Print a message to the player
{ type = "narrate",
  message = "The liquid burns your throat...",  -- REQUIRED
  style = "danger",                              -- future: narrator formatting
}

-- mutate: Change a field on an object
{ type = "mutate",
  target = "self",      -- "self" = source object, or an object ID
  field = "is_consumable",
  value = false,
}

-- add_status: Add a temporary status condition to the player
{ type = "add_status",
  status = "nauseated",    -- REQUIRED: status identifier
  duration = 12,           -- turns (-1 = permanent until cured)
  severity = "mild",       -- "mild" | "moderate" | "severe"
  message = "Your stomach churns.",
}

-- remove_status: Remove a status condition
{ type = "remove_status",
  status = "nauseated",    -- REQUIRED
  message = "The nausea finally passes.",
}

-- fsm_transition: Force state change on another object
{ type = "fsm_transition",
  target_id = "candle",      -- REQUIRED: object to transition
  to_state = "extinguished", -- REQUIRED: target state
  verb_hint = "extinguish",  -- for FSM transition matching
}

-- trigger_event: Fire a named event into the game loop
{ type = "trigger_event",
  event = "alarm_triggered",   -- REQUIRED: event name
  args = { room = "cellar" },  -- event-specific payload
}

-- spawn_object: Create a new object
{ type = "spawn_object",
  template = "smoke-cloud",    -- REQUIRED: object template ID
  location = "current_room",   -- "current_room" | "inventory" | room ID
  overrides = { duration = 5 },
}

-- destroy_object: Remove an object from the world
{ type = "destroy_object",
  target_id = "glass-vial",   -- REQUIRED: object to remove
  message = "The vial shatters into dust.",
}
```

## Appendix B: Cross-Reference

| Document | What It Covers |
|----------|---------------|
| `event-hooks.md` | Hook taxonomy, gap analysis, effect pipeline proposal |
| `event-handlers/about.md` | Hook framework design (12 hooks, registry, dispatch) |
| `event-handlers/wind_effect.md` | First implemented hook subtype (traverse effects) |
| `event-handlers/puzzle-designer-guide.md` | Content author guide to using hooks |
| `docs/design/objects/poison-bottle.md` | Poison bottle design (consumption → injury) |
| `docs/design/objects/bear-trap.md` | Bear trap design (contact → injury) |
| `src/meta/objects/poison-bottle.lua` | Poison bottle implementation (structured effects) |
| `src/meta/objects/bear-trap.lua` | Bear trap implementation (structured effects) |
| `src/engine/injuries.lua` | Injury system API |
| `src/engine/traverse_effects.lua` | Existing traverse effect processor |
| This document | Unified Effect Processing Pipeline architecture |
