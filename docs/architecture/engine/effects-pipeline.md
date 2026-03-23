# Unified Effect Processing Pipeline — Architecture

**Version:** 2.0 (Implementation Record)  
**Date:** 2026-07-26 (proposed) · Updated 2026-07-27 (shipped)  
**Author:** Bart (Architect) — design · Smithers (UI Engineer) — implementation  
**Status:** ✅ IMPLEMENTED — `src/engine/effects.lua`  
**Decision:** D-EFFECTS-PIPELINE  
**Requested by:** Wayne "Effe" Berry  
**Prerequisite reading:** `event-hooks.md` (hook taxonomy + gap analysis)

---

## 1. Problem Statement (Historical)

> This section records the pre-pipeline state. The problems described here are now resolved.

### 1.1 Pre-Pipeline State

Before the pipeline shipped, when an object caused something to happen — an injury, a status effect, a narration — the **verb handler** contained inline code that interpreted the object's metadata and called the appropriate subsystem. Three distinct patterns existed:

| Pattern | Example | Where the logic lived |
|---------|---------|----------------------|
| **String tag on transition** | `effect = "poison"` on drink transition | Drink verb handler checked `trans.effect == "poison"`, called `injuries.inflict()` with hardcoded parameters |
| **String tag on state** | `on_taste_effect = "poison"` on open state | Taste verb handler checked `obj.on_taste_effect == "poison"`, ran inline death sequence with `os.exit(0)` |
| **Structured table on state** | `on_feel_effect = { type = "inflict_injury", ... }` | Not consumed — verb handlers didn't read structured effect tables |

### 1.2 The Core Violation

Every new injury-causing object required editing engine verb handler code. This violated Principle 8:

> *"All behavior declared in metadata, zero engine knowledge needed."*

The engine **knew** that `"poison"` meant nightshade. The engine **knew** that tasting poison should print specific death text and call `os.exit(0)`. The engine decided the injury type, the damage, the narration — all information that should live in the object.

### 1.3 What It Cost

- **New poison types** (viper venom, mild food poisoning) required verb handler edits for each trigger verb
- **Inconsistent behavior** — drinking poison went through the injury system; tasting poison bypassed it entirely and called `os.exit(0)` directly
- **Duplicated logic** — each sensory verb re-implemented its own effect dispatch
- **Content authors** (Flanders, CBG) could not add injury-causing objects without engine changes

### 1.4 Resolution

The pipeline is now implemented in `src/engine/effects.lua` (232 lines). Objects declare structured effect tables; the engine routes them. The `os.exit(0)` bug is fixed — all injury paths go through `injuries.inflict()`. Content authors can add new injury-causing objects with zero engine changes.

---

## 2. Architecture: Effect Processing Pipeline (As Implemented)

### 2.1 Design Principle

Objects declare **what** happens (structured effect tables). The engine decides **when** it happens (hook integration points). The effect processor decides **how** it happens (dispatch to subsystems). Clean three-way separation.

```
OBJECT says: "When someone drinks me, inflict poisoned-nightshade at damage 10"
ENGINE says: "A drink transition just fired, and it has an effect table"
PIPELINE says: "This is an inflict_injury effect — routing to injuries.inflict()"
```

No component knows the other's business. No hardcoded mappings. No verb handler edits for new objects.

### 2.2 Effect Declaration Formats

The pipeline accepts three declaration formats, normalized internally by `effects.normalize()`:

| Format | Example | When to use |
|--------|---------|-------------|
| **Legacy string** | `effect = "poison"` | Backward compat only. Mapped via `legacy_map`. |
| **Single table** | `effect = { type = "inflict_injury", ... }` | One effect fires. |
| **Array of tables** | `effect = { { type = "inflict_injury", ... }, { type = "narrate", ... } }` | Multiple effects fire in order. |

**Real example from poison-bottle.lua (shipped):**

```lua
-- Single structured effect on a transition (poison-bottle.lua, drink transition)
effect = {
    type = "inflict_injury",
    injury_type = "poisoned-nightshade",
    source = "poison-bottle",
    damage = 10,
    message = "A bitter, almost sweet taste burns down your throat. Your heart begins to race.",
},

-- Single structured effect on a state callback (poison-bottle.lua, open.on_taste_effect)
on_taste_effect = {
    type = "inflict_injury",
    injury_type = "poisoned-nightshade",
    source = "poison-bottle",
    damage = 5,
    message = "The taste alone is enough. Burning sweetness sears your tongue and throat.",
    pipeline_routed = true,
},

-- Array of effects for atomic processing (poison-bottle.lua, drink pipeline_effects)
pipeline_effects = {
    { type = "inflict_injury", injury_type = "poisoned-nightshade",
      source = "poison-bottle", damage = 10,
      message = "A bitter, almost sweet taste burns down your throat. Your heart begins to race." },
    { type = "mutate", target = "self", field = "weight", value = 0.1 },
    { type = "mutate", target = "self", field = "is_consumable", value = false },
},
```

### 2.3 Shipped Effect Types

Five built-in handlers are registered at module load time. Each maps to an existing subsystem:

| Effect Type | What It Does | Subsystem Called | Parameters | Status |
|-------------|-------------|-----------------|------------|--------|
| `inflict_injury` | Applies an injury to the player | `injuries.inflict()` via `pcall` | `injury_type`, `source`, `location`, `damage`, `message` | ✅ Shipped |
| `narrate` | Prints a message to the player | `print()` | `message` | ✅ Shipped |
| `mutate` | Changes a field on an object | Direct field assignment | `target` (`"self"` or object ID), `field`, `value` | ✅ Shipped |
| `add_status` | Adds a status condition to the player | `player.state[]` table | `status`, `duration`, `severity`, `message` | ✅ Shipped |
| `remove_status` | Removes a status condition from the player | `player.state[]` table | `status`, `message` | ✅ Shipped |

**Not yet implemented** (registered when subsystems arrive):

| Effect Type | Subsystem | Use Case |
|-------------|-----------|----------|
| `trigger_event` | event dispatch | Fire named event into game loop |
| `fsm_transition` | `fsm.transition()` | Force state change on another object |
| `spawn_object` | loader + registry | Materialize a new object |
| `destroy_object` | registry | Remove an object from the world |

### 2.4 Effect Processor Module — Actual Implementation

The shipped module (`src/engine/effects.lua`, 232 lines) is reproduced below. This is the **actual code**, not a proposal.

#### Public API

| Function | Signature | Description |
|----------|-----------|-------------|
| `effects.register(effect_type, handler_fn)` | `(string, function(effect, ctx) → any)` | Register a handler for an effect type |
| `effects.unregister(effect_type)` | `(string)` | Remove a handler (primarily for testing) |
| `effects.has_handler(effect_type)` | `(string) → boolean` | Check if a handler is registered |
| `effects.normalize(raw)` | `(string\|table) → table[]\|nil` | Normalize any declaration to an array of `{type=...}` tables |
| `effects.process(raw, ctx)` | `(string\|table, table) → boolean` | Main entry point — normalize, intercept, dispatch |
| `effects.add_interceptor(phase, fn)` | `("before"\|"after", function(effect, ctx))` | Register before/after interceptor |
| `effects.clear_interceptors()` | `()` | Clear all interceptors (testing) |

#### Handler Registry

```lua
local effects = {}
local handlers = {}

function effects.register(effect_type, handler_fn)
    handlers[effect_type] = handler_fn
end

function effects.unregister(effect_type)
    handlers[effect_type] = nil
end

function effects.has_handler(effect_type)
    return handlers[effect_type] ~= nil
end
```

#### Interceptor Infrastructure

```lua
local interceptors = { before = {}, after = {} }

function effects.add_interceptor(phase, fn)
    interceptors[phase] = interceptors[phase] or {}
    interceptors[phase][#interceptors[phase] + 1] = fn
end

function effects.clear_interceptors()
    interceptors = { before = {}, after = {} }
end

-- Returns true if cancelled (before phase only).
function effects._run_interceptors(phase, effect, ctx)
    for _, fn in ipairs(interceptors[phase] or {}) do
        local result = fn(effect, ctx)
        if phase == "before" and result == "cancel" then
            return true -- cancelled
        end
    end
    return false
end
```

#### Legacy Normalization

```lua
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
        if raw.type then return { raw } end   -- single effect → wrap in array
        if raw[1] then return raw end          -- already an array of effects
    end
    return nil
end
```

Note: `normalize()` returns a **copy** of legacy map entries to prevent mutation of templates across calls.

#### Main Processing Entry Point

```lua
function effects.process(raw, ctx)
    local effect_list = effects.normalize(raw)
    if not effect_list then return false end

    ctx = ctx or {}
    local any = false

    for _, effect in ipairs(effect_list) do
        -- Phase 1: before_effect interceptors can cancel or modify
        local cancelled = effects._run_interceptors("before", effect, ctx)
        if not cancelled then
            -- Phase 2: dispatch to registered handler
            local handler = handlers[effect.type]
            if handler then
                handler(effect, ctx)
                any = true
            end
            -- Phase 3: after_effect interceptors (cleanup, narration, achievements)
            effects._run_interceptors("after", effect, ctx)
        end
    end

    return any
end
```

### 2.5 Built-in Handler Implementations

All five built-in handlers are registered at the bottom of `effects.lua` at module load time.

#### `inflict_injury` — Routes to `injuries.inflict()` (safe `pcall`)

```lua
effects.register("inflict_injury", function(effect, ctx)
    local inj_ok, injury_mod = pcall(require, "engine.injuries")
    if not inj_ok then return nil end

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

    -- Check for instant death after injury infliction
    if instance and ctx.player then
        local health = injury_mod.compute_health(ctx.player)
        if health <= 0 then
            ctx.game_over = true
        end
    end

    return instance
end)
```

Key detail: Uses `pcall(require, "engine.injuries")` for safe require — the module gracefully degrades if the injury system isn't loaded. Sets `ctx.game_over = true` on lethal damage (no more `os.exit(0)` inline).

#### `narrate` — Prints message text

```lua
effects.register("narrate", function(effect, ctx)
    if effect.message then
        print(effect.message)
    end
end)
```

#### `add_status` — Adds status condition to player state

```lua
effects.register("add_status", function(effect, ctx)
    if not effect.status or not ctx.player then return end
    ctx.player.state = ctx.player.state or {}
    ctx.player.state[effect.status] = {
        active = true,
        duration = effect.duration,
        severity = effect.severity,
    }
    if effect.message then
        print(effect.message)
    end
end)
```

#### `remove_status` — Removes status condition

```lua
effects.register("remove_status", function(effect, ctx)
    if not effect.status or not ctx.player then return end
    ctx.player.state = ctx.player.state or {}
    ctx.player.state[effect.status] = nil
    if effect.message then
        print(effect.message)
    end
end)
```

#### `mutate` — Changes a field on an object

```lua
effects.register("mutate", function(effect, ctx)
    if not effect.field then return end
    local target_obj
    if effect.target == "self" and ctx.source then
        target_obj = ctx.source
    elseif effect.target and ctx.registry then
        target_obj = ctx.registry:get(effect.target)
    elseif ctx.source then
        target_obj = ctx.source
    end
    if target_obj then
        target_obj[effect.field] = effect.value
    end
end)
```

Target resolution order: `"self"` → `ctx.source`, named ID → `ctx.registry:get()`, fallback → `ctx.source`.

### 2.6 Processing Flow

The complete path from player input to subsystem action (as implemented):

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
     │           → single table? wraps in array: { {type=...} }
     │           → string "poison"? maps via legacy_map
     │           → array? returns as-is
     │           │
     │           ▼
     │         For each effect in normalized list:
     │           │
     │           ├── Phase 1: Run before_effect interceptors
     │           │     → any returns "cancel"? skip this effect
     │           │     → can modify effect table in-place (e.g. armor reduces damage)
     │           │
     │           ├── Phase 2: Dispatch to handler by effect.type
     │           │     ├── "inflict_injury" → pcall(require "engine.injuries") → injuries.inflict()
     │           │     │                      → prints effect.message → checks game_over
     │           │     ├── "narrate"        → print(effect.message)
     │           │     ├── "add_status"     → player.state[status] = {active, duration, severity}
     │           │     ├── "remove_status"  → player.state[status] = nil
     │           │     └── "mutate"         → resolve target → obj[field] = value
     │           │
     │           └── Phase 3: Run after_effect interceptors
     │                 → cannot cancel (effect already happened)
     │                 → use cases: achievement triggers, NPC reactions, narration
     │
     └── NO → continue (no effects)
  │
  ▼
  6. Prints transition message
  │
  ▼
Post-command: injuries.tick(player) runs on game loop tick
```

### 2.7 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        EFFECT SOURCES                               │
│                                                                     │
│  FSM Transition         Sensory Callback        Engine Hook         │
│  (trans.effect)         (on_taste_effect)       (on_enter_room)     │
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
│         │                  │  Copies legacy map entries (no mutate) │
│         └────────┬─────────┘                                        │
│                  │                                                  │
│         ┌────────▼─────────┐                                        │
│         │ before_effect    │  Interceptors: cancel, modify          │
│         │ interceptors     │  (e.g. armor reduces damage)           │
│         └────────┬─────────┘                                        │
│                  │                                                  │
│    ┌─────────────┼──────────────┬───────────────┬──────────────┐    │
│    ▼             ▼              ▼               ▼              ▼    │
│ ┌────────┐ ┌─────────┐ ┌───────────┐ ┌───────────┐ ┌────────────┐ │
│ │inflict │ │ narrate  │ │add_status │ │remove_    │ │  mutate    │ │
│ │_injury │ │          │ │           │ │status     │ │            │ │
│ │        │ │ print()  │ │player.    │ │player.    │ │ obj[k]=v   │ │
│ │pcall   │ │          │ │state[]    │ │state[]=nil│ │ via target │ │
│ │injuries│ │          │ │           │ │           │ │ resolution │ │
│ │.inflict│ │          │ │           │ │           │ │            │ │
│ └────────┘ └─────────┘ └───────────┘ └───────────┘ └────────────┘ │
│    │                                                                │
│    ▼                                                                │
│ ┌────────────────┐                                                  │
│ │ after_effect    │  Interceptors: cleanup, achievement triggers     │
│ │ interceptors    │  (e.g. "first injury" achievement)              │
│ └────────────────┘                                                  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. Integration Points (As Implemented)

### 3.1 Verb Handlers → Effect Processor

Verb handlers that previously checked for effect strings now delegate to `effects.process()`:

**Before (was — inline dispatch):**
```lua
-- In drink verb handler
if trans.effect == "poison" then
    local inj_ok, injury_mod = pcall(require, "engine.injuries")
    if inj_ok then
        injury_mod.inflict(ctx.player, "poisoned-nightshade", obj.id)
        -- ... hardcoded death check, hardcoded narration
    end
end
```

**After (shipped — one-line delegation):**
```lua
-- In drink verb handler
if trans.effect then
    effects.process(trans.effect, ctx)
end
```

The object's effect table carries the injury type, damage, source, and message. The pipeline routes it. The verb handler doesn't know or care what happens.

### 3.2 Sensory Verbs → Effect Processor

Each sensory verb (feel, taste, smell, listen, look) follows the same post-pattern:

**Before (was — per-verb inline checks):**
```lua
-- In taste verb handler
if obj.on_taste_effect then
    if obj.on_taste_effect == "poison" then
        print("Fire courses through your veins...")
        print("*** YOU HAVE DIED ***")
        os.exit(0)  -- bypassed injury system entirely!
    end
end
```

**After (shipped — unified):**
```lua
-- In taste verb handler
local state = fsm_mod.get_state_def(obj)
if state and state.on_taste_effect then
    effects.process(state.on_taste_effect, ctx)
end
```

**Real example — poison-bottle.lua open state (shipped):**

```lua
-- The on_taste_effect on the open state is a structured table with pipeline_routed flag
on_taste_effect = {
    type = "inflict_injury",
    injury_type = "poisoned-nightshade",
    source = "poison-bottle",
    damage = 5,
    message = "The taste alone is enough. Burning sweetness sears your tongue and throat.",
    pipeline_routed = true,
},
```

The `pipeline_routed = true` flag signals that this effect was authored for pipeline routing (not a legacy string). It's informational — the pipeline processes both flagged and unflagged effects identically.

This applies to all five sensory verbs:

| Hook Field | Verb(s) | Shipped Example |
|------------|---------|-----------------|
| `on_taste_effect` | taste, lick | Poison bottle open state (poisoned-nightshade, damage=5) |
| `on_feel_effect` | feel, touch | Bear trap set state (bleeding), glass shard (minor-cut) |
| `on_smell_effect` | smell, sniff | (convention ready, no objects yet) |
| `on_listen_effect` | listen, hear | (convention ready, no objects yet) |
| `on_look_effect` | look, examine | (convention ready, no objects yet) |

### 3.3 Injury System Integration

The `inflict_injury` handler calls the existing `injuries.inflict()` API with no changes to that system. The shipped implementation uses `pcall` for safe require:

```lua
effects.register("inflict_injury", function(effect, ctx)
    local inj_ok, injury_mod = pcall(require, "engine.injuries")
    if not inj_ok then return nil end

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

    if instance and ctx.player then
        local health = injury_mod.compute_health(ctx.player)
        if health <= 0 then
            ctx.game_over = true
        end
    end

    return instance
end)
```

Differences from the original proposal:
- **`pcall` safety**: require is wrapped in `pcall` — if the injury module isn't available, the handler returns nil instead of crashing
- **`ctx.game_over` flag**: Instead of `os.exit(0)`, lethal damage sets a flag on the context table for the game loop to handle cleanly
- **Source fallback chain**: `effect.source or ctx.source_id or "unknown"` — three-level fallback

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

### 3.5 Object Opt-in: The `effects_pipeline` Flag

Objects that use structured effect tables set a top-level flag to indicate pipeline routing:

```lua
-- poison-bottle.lua (shipped)
return {
    id = "poison-bottle",
    effects_pipeline = true,   -- ← all effects on this object are structured tables
    -- ...
}
```

The `effects_pipeline = true` flag signals to the engine that:
1. All `effect` fields on transitions are structured tables (not legacy strings)
2. All `on_{sense}_effect` fields on states are structured tables
3. The object is pipeline-native — no legacy normalization needed

This is a **convention flag**, not enforced by the pipeline module itself. The pipeline processes any format regardless. The flag helps the engine and content authors distinguish migrated objects from legacy ones.

### 3.6 The `pipeline_effects` Array and `pipeline_routed` Flag

Two metadata patterns emerged during the poison bottle migration:

#### `pipeline_effects` — Full effect chain for atomic processing

Transitions can declare a `pipeline_effects` array alongside the single `effect` field. This provides the complete atomic effect chain:

```lua
-- poison-bottle.lua drink transition (shipped)
{
    from = "open", to = "empty", verb = "drink",
    -- Single effect (backward compat — engine can use this alone)
    effect = {
        type = "inflict_injury",
        injury_type = "poisoned-nightshade",
        source = "poison-bottle",
        damage = 10,
        message = "A bitter, almost sweet taste burns down your throat. Your heart begins to race.",
    },
    -- Full pipeline chain for atomic processing (D-EFFECTS-PIPELINE)
    -- Engine falls back to effect + mutate if pipeline_effects not consumed.
    pipeline_effects = {
        { type = "inflict_injury", injury_type = "poisoned-nightshade",
          source = "poison-bottle", damage = 10,
          message = "A bitter, almost sweet taste burns down your throat. Your heart begins to race." },
        { type = "mutate", target = "self", field = "weight", value = 0.1 },
        { type = "mutate", target = "self", field = "is_consumable", value = false },
    },
    -- FSM-level mutations (applied by fsm.transition → apply_mutations)
    mutate = { ... },
}
```

The `pipeline_effects` array includes **all** side effects as pipeline-routed types, including mutations that FSM-level `mutate` also handles. This gives the engine a choice:
- **Pipeline-aware engine**: Process `pipeline_effects` atomically via `effects.process()`
- **Fallback engine**: Process `effect` + `mutate` separately (traditional path)

#### `pipeline_routed` — Marks an individual effect as pipeline-authored

```lua
-- poison-bottle.lua open state on_taste_effect (shipped)
on_taste_effect = {
    type = "inflict_injury",
    injury_type = "poisoned-nightshade",
    source = "poison-bottle",
    damage = 5,
    message = "The taste alone is enough. Burning sweetness sears your tongue and throat.",
    pipeline_routed = true,   -- ← informational: authored for pipeline routing
},
```

The `pipeline_routed = true` flag is informational. The pipeline ignores it during processing — it exists for tooling, debugging, and content author clarity.

### 3.7 FSM State Transition Connection

Effects fire **after** the FSM transition has been applied. This is deliberate and confirmed in the shipped implementation:

1. Transition executes → object state changes (e.g., bottle: open → empty)
2. Mutations apply → object properties update (weight, keywords, categories)
3. Effects fire → subsystems activate (injury inflicted, narration printed)

This ordering guarantees that the object is in its **post-transition state** when effects fire. An `after_effect` interceptor that inspects the object sees the new state, not the old one.

**Exception:** `before_effect` interceptors fire before the effect handler runs, but still after the FSM transition. This is correct — the interceptor can cancel the effect (e.g., immunity), but it cannot undo the state transition. The bottle is empty regardless of whether the poison takes hold (the player drank the liquid; whether the poison works is a separate question).

### 3.8 GOAP Planning Integration

The GOAP planner (`goal_planner.lua`) reads `prerequisites` tables on objects. Effect declarations don't change GOAP planning — the planner doesn't need to understand effects, only state requirements.

Objects that cause effects declare GOAP-visible consequences in their prerequisites to enable avoidance planning. **Real example from poison-bottle.lua (shipped):**

```lua
-- poison-bottle.lua prerequisites (shipped)
prerequisites = {
    drink = { requires_state = "open", warns = { "injury", "poisoned-nightshade" } },
    pour = { requires_state = "open" },
    open = { requires_state = "sealed", requires_free_hands = true },
    uncork = { requires_state = "sealed", requires_free_hands = true },
    taste = { warns = { "injury", "poisoned-nightshade" } },
},
```

The `warns` field is advisory — the planner can use it for future "avoid danger" goals.

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

### 5.2 Future Effect Types

| Effect Type | Subsystem | Use Case | Priority |
|-------------|-----------|----------|----------|
| `heal_injury` | injury system | Antidote application, bandage | High (pairs with inflict) |
| `add_buff` | buff/debuff system | Strength potion, speed boost | Medium |
| `remove_buff` | buff/debuff system | Debuff cure, buff expiration | Medium |
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

For effects on other players (future MMO feature), the ctx table carries the target. The current `mutate` handler already demonstrates target resolution via `ctx.registry`. The `inflict_injury` handler always targets `ctx.player` today — future combat extends this with `effect.target` resolution.

---

## 6. Migration Status

### 6.1 Backward Compatibility (Shipped)

The `effects.normalize()` function guarantees zero-breakage migration. All three formats work:

```lua
-- Legacy format (still works)
effect = "poison"
-- normalize() → { { type = "inflict_injury", injury_type = "poisoned-nightshade",
--                    source = "unknown", damage = 10 } }

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

The legacy map covers all currently used string tags: `"poison"`, `"cut"`, `"burn"`, `"bruise"`, `"nausea"`. Unrecognized strings return `nil` (silently ignored).

### 6.2 Migration Phases (Status)

**Phase 1: Create the pipeline** — ✅ COMPLETE
- `src/engine/effects.lua` shipped with `process()`, `normalize()`, `register()`, `unregister()`, `has_handler()`
- Five built-in handlers registered: `inflict_injury`, `narrate`, `add_status`, `remove_status`, `mutate`
- Before/after interceptor infrastructure shipped (empty — zero overhead)

**Phase 2: Refactor verb handlers** — ✅ COMPLETE
- Inline effect checks replaced with `effects.process()` calls
- The `os.exit(0)` bug in the taste handler is eliminated

**Phase 3: Object migration** — ✅ FIRST MIGRATION COMPLETE (poison-bottle)
- `poison-bottle.lua` fully migrated: `effects_pipeline = true`, structured effect tables, `pipeline_effects` array
- Objects using legacy string effects continue working via `normalize()`
- Remaining objects migrate at Flanders's pace

**Phase 4: Register future handlers** — ONGOING
- `add_status` and `remove_status` shipped ahead of schedule
- `mutate` shipped ahead of schedule
- `heal_injury` needed when antidote objects are built

### 6.3 Verb Handler Refactoring (Completed)

| Handler | Previous Pattern | Status |
|---------|-----------------|--------|
| `drink` | `trans.effect == "poison"` → hardcoded `injuries.inflict()` | ✅ Migrated to `effects.process()` |
| `taste` | `on_taste_effect == "poison"` → inline death + `os.exit(0)` | ✅ Migrated — **`os.exit(0)` bug fixed** |
| `feel` | `on_feel_effect == "cut"` → inline `injuries.inflict()` | ✅ Migrated to `effects.process()` |
| `stab`/`cut`/`hit` | `obj.on_stab` table → direct `injuries.inflict()` | Route through pipeline as needed |

### 6.4 What Did NOT Change

- **FSM architecture** — states, transitions, timers, thresholds: untouched
- **Injury system API** — `injuries.inflict()`, `tick()`, `compute_health()`, `try_heal()`: untouched
- **Verb dispatch** — parser → verb handler flow: untouched
- **Object metadata format** — backward compatible, existing objects work as-is
- **GOAP planner** — reads prerequisites, not effects: untouched
- **Traverse effects** — `traverse_effects.lua` continues to work independently (future: may route through pipeline)

---

## 7. Relationship to Existing Architecture

### 7.1 Layer Position

The effect processor sits at **Layer 3.6** in the architecture stack:

```
Layer 5:  Meta-code (object .lua files)        — declares effects
Layer 4:  Verb system (verbs/init.lua)          — triggers effects
Layer 3.6: Effect processor (effects.lua)       — routes effects    ← SHIPPED
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

## 8. Implementation Summary

| Component | Owner | Lines | Status |
|-----------|-------|-------|--------|
| `src/engine/effects.lua` — core module | Smithers (impl), Bart (design) | 232 | ✅ Shipped |
| `inflict_injury` handler | Smithers | ~25 | ✅ Shipped (with pcall safety, game_over flag) |
| `narrate` handler | Smithers | ~5 | ✅ Shipped |
| `add_status` handler | Smithers | ~12 | ✅ Shipped |
| `remove_status` handler | Smithers | ~8 | ✅ Shipped |
| `mutate` handler | Smithers | ~15 | ✅ Shipped (with target resolution) |
| Before/after interceptor infrastructure | Smithers | ~20 | ✅ Shipped (empty — zero overhead) |
| `unregister()` + `has_handler()` + `clear_interceptors()` | Smithers | ~10 | ✅ Shipped (testing support) |
| Poison bottle migration | Flanders | — | ✅ Shipped (first pipeline-native object) |

**Actual shipped: 232 lines in `effects.lua`. Five handlers. Three-format normalization. Full interceptor infrastructure.**

---

## Appendix A: Complete Effect Declaration Reference (Shipped)

```lua
-- inflict_injury: Apply injury to player via injuries.inflict()
-- Handler uses pcall for safe require. Sets ctx.game_over on lethal damage.
{ type = "inflict_injury",
  injury_type = "poisoned-nightshade",  -- REQUIRED: matches meta/injuries/{type}.lua
  source = "poison-bottle",              -- fallback chain: effect.source → ctx.source_id → "unknown"
  location = "hand",                     -- body location (nil = systemic)
  damage = 10,                           -- override initial_damage from definition
  message = "The pain is blinding.",     -- printed after infliction
}

-- narrate: Print a message to the player
{ type = "narrate",
  message = "The liquid burns your throat...",  -- REQUIRED
}

-- mutate: Change a field on an object
-- Target resolution: "self" → ctx.source, named ID → ctx.registry:get(), fallback → ctx.source
{ type = "mutate",
  target = "self",      -- "self" = source object, or an object ID
  field = "is_consumable",
  value = false,
}

-- add_status: Add a status condition to the player's state table
{ type = "add_status",
  status = "nauseated",    -- REQUIRED: status identifier
  duration = 12,           -- turns (-1 = permanent until cured)
  severity = "mild",       -- "mild" | "moderate" | "severe"
  message = "Your stomach churns.",
}

-- remove_status: Remove a status condition from the player's state table
{ type = "remove_status",
  status = "nauseated",    -- REQUIRED
  message = "The nausea finally passes.",
}
```

**Not yet implemented** (register when subsystems arrive):

```lua
-- fsm_transition: Force state change on another object (FUTURE)
{ type = "fsm_transition",
  target_id = "candle",      -- REQUIRED: object to transition
  to_state = "extinguished", -- REQUIRED: target state
  verb_hint = "extinguish",  -- for FSM transition matching
}

-- trigger_event: Fire a named event into the game loop (FUTURE)
{ type = "trigger_event",
  event = "alarm_triggered",   -- REQUIRED: event name
  args = { room = "cellar" },  -- event-specific payload
}

-- spawn_object: Create a new object (FUTURE)
{ type = "spawn_object",
  template = "smoke-cloud",    -- REQUIRED: object template ID
  location = "current_room",   -- "current_room" | "inventory" | room ID
  overrides = { duration = 5 },
}

-- destroy_object: Remove an object from the world (FUTURE)
{ type = "destroy_object",
  target_id = "glass-vial",   -- REQUIRED: object to remove
  message = "The vial shatters into dust.",
}
```

## Appendix B: Poison Bottle — Complete Migration Example

The poison bottle (`src/meta/objects/poison-bottle.lua`) is the first object fully migrated to the effects pipeline. This section documents the actual shipped metadata patterns.

### Object-Level Flag

```lua
return {
    id = "poison-bottle",
    effects_pipeline = true,    -- signals pipeline-native object
    is_consumable = true,
    consumable_type = "liquid",
    poison_type = "nightshade",
    poison_severity = "lethal",
    -- ...
}
```

### Transition Effect (drink → lethal dose)

```lua
{
    from = "open", to = "empty", verb = "drink",
    aliases = {"quaff", "sip", "gulp", "consume"},
    message = "You raise the bottle to your lips. The liquid burns like liquid fire...",
    -- Single structured effect (effects.process normalizes to array)
    effect = {
        type = "inflict_injury",
        injury_type = "poisoned-nightshade",
        source = "poison-bottle",
        damage = 10,
        message = "A bitter, almost sweet taste burns down your throat. Your heart begins to race.",
    },
    -- Full pipeline chain for atomic processing
    pipeline_effects = {
        { type = "inflict_injury", injury_type = "poisoned-nightshade",
          source = "poison-bottle", damage = 10,
          message = "A bitter, almost sweet taste burns down your throat. Your heart begins to race." },
        { type = "mutate", target = "self", field = "weight", value = 0.1 },
        { type = "mutate", target = "self", field = "is_consumable", value = false },
    },
    -- FSM-level mutations (applied by fsm.transition → apply_mutations)
    mutate = {
        weight = 0.1,
        is_consumable = false,
        categories = { remove = "dangerous" },
        keywords = { add = "empty" },
    },
}
```

### State Effect (taste → sub-lethal warning dose)

```lua
-- On the "open" state
on_taste = "BITTER! Searing fire courses down your throat. Your vision blurs...",
on_taste_effect = {
    type = "inflict_injury",
    injury_type = "poisoned-nightshade",
    source = "poison-bottle",
    damage = 5,
    message = "The taste alone is enough. Burning sweetness sears your tongue and throat.",
    pipeline_routed = true,
},
```

### Safe Path (pour → no effect)

```lua
{
    from = "open", to = "empty", verb = "pour",
    aliases = {"spill", "dump"},
    message = "You tip the bottle. The green liquid pours out, hissing where it touches the stone floor...",
    -- No effect field — safe disposal path
    mutate = {
        weight = 0.1,
        is_consumable = false,
        categories = { remove = "dangerous" },
        keywords = { add = "empty" },
    },
}
```

### Effect Routing Summary

| Player Action | Effect Path | Damage | Survivable? |
|---------------|------------|--------|-------------|
| `drink bottle` | `trans.effect → effects.process() → inflict_injury(poisoned-nightshade, 10)` | 10 | Depends on health |
| `taste bottle` (open) | `state.on_taste_effect → effects.process() → inflict_injury(poisoned-nightshade, 5)` | 5 | Yes (warning dose) |
| `pour bottle` | No effect — safe disposal | 0 | Always |

## Appendix C: Cross-Reference

| Document | What It Covers |
|----------|---------------|
| `event-hooks.md` | Hook taxonomy, gap analysis, pipeline integration with hooks |
| `event-handlers/about.md` | Hook framework design (12 hooks, registry, dispatch) |
| `event-handlers/wind_effect.md` | First implemented hook subtype (traverse effects) |
| `event-handlers/puzzle-designer-guide.md` | Content author guide to using hooks |
| `docs/design/objects/poison-bottle.md` | Poison bottle design (consumption → injury) |
| `docs/design/objects/bear-trap.md` | Bear trap design (contact → injury) |
| `src/meta/objects/poison-bottle.lua` | **Poison bottle implementation — first pipeline-native object** |
| `src/meta/objects/bear-trap.lua` | Bear trap implementation (structured effects) |
| `src/engine/effects.lua` | **The pipeline implementation (232 lines)** |
| `src/engine/injuries.lua` | Injury system API |
| `src/engine/traverse_effects.lua` | Existing traverse effect processor |
| This document | Unified Effect Processing Pipeline architecture + implementation record |
