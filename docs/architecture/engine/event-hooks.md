# Engine Event Hooks — Injury Pipeline Architecture

**Version:** 2.0 (Updated for Implementation)  
**Date:** 2026-07-22 (original) · Updated 2026-07-27  
**Author:** Bart (Architect)  
**Status:** Architecture Analysis + Implementation Record  
**Requested by:** Wayne "Effe" Berry

---

## 1. Executive Summary

This document analyzes how `.lua` object files hook into the engine to cause injuries, with two reference cases: **consumable → injury** (poison bottle) and **contact → injury** (bear trap). It audits the hook taxonomy, identifies architectural gaps, and documents the **Effect Processing Pipeline** — a unified system for translating object-declared effects into engine actions like injury infliction.

**Key finding:** The engine has a robust injury system (`injuries.inflict()`) and a designed-but-mostly-unimplemented hook framework (only `on_traverse` is live). The missing piece was a **standardized effect processor** that bridges the gap between object metadata and the injury engine. That bridge — `src/engine/effects.lua` — is now **shipped and live**.

**Status update:** The effect processor is implemented (232 lines). The poison bottle is the first fully migrated object. Hooks that previously used inline string checks now route through `effects.process()`.

---

## 2. State Audit

### 2.1 System Status

| System | Status | Location | Notes |
|--------|--------|----------|-------|
| **Injury Engine** | ✅ Fully implemented | `src/engine/injuries.lua` | `inflict()`, `tick()`, `compute_health()`, `try_heal()`, 6 injury types |
| **FSM Engine** | ✅ Fully implemented | `src/engine/fsm/init.lua` | States, transitions, timers, `on_tick`, `on_transition` callbacks |
| **Hook Framework** | 🟡 Designed, 1 of 12 implemented | `src/engine/traverse_effects.lua` | Only `on_traverse` + `wind_effect` is live |
| **Hook Architecture Doc** | ✅ Comprehensive | `docs/architecture/engine/event-handlers/about.md` | 12 hooks cataloged, registry pattern designed |
| **Object Effect Declarations** | ✅ Structured tables | `src/meta/objects/*.lua` | Pipeline-native objects use `effects_pipeline = true` |
| **Effect Processing** | ✅ **Implemented** | `src/engine/effects.lua` | **Unified pipeline: `effects.process()` with 5 built-in handlers** |

### 2.2 Currently Active Hooks

| Hook | Location | Implementation | Pipeline Status |
|------|----------|----------------|-----------------|
| `on_traverse` | `traverse_effects.lua` + `verbs/init.lua` | Wind effect extinguishes candles on exit traversal | Independent (future convergence) |
| `on_tick` (per-state) | `fsm/init.lua` | Legacy per-state callback, runs every game tick | N/A |
| `on_transition` (per-transition) | `fsm/init.lua` | Fires when FSM transition executes | N/A |
| `on_feel/look/smell/taste/listen` | Verb handlers | Sensory callbacks (string or function) per state | N/A |
| `on_taste_effect` | Verb handler → **`effects.process()`** | ✅ Routes structured effect through pipeline | **Migrated** |
| `on_feel_effect` | Verb handler → **`effects.process()`** | ✅ Routes structured effect through pipeline | **Migrated** |
| `effect` (on transition) | Verb handler → **`effects.process()`** | ✅ Routes structured effect through pipeline | **Migrated** |

### 2.3 How Objects Cause Injuries

> **Update:** Patterns A and B below are the **legacy patterns** that existed before the pipeline. The poison bottle has been migrated to Pattern D (pipeline-native). Legacy patterns still work via `effects.normalize()`.

#### Pattern A: Transition Effect — Legacy (still supported)

```lua
-- Legacy string tag — normalized by effects.normalize()
transitions = {
    {
        from = "open", to = "empty", verb = "drink",
        effect = "poison",  -- ← normalize() maps to inflict_injury table
    },
}
```

#### Pattern B: Sensory Effect — Legacy (still supported)

```lua
-- Legacy string tag — normalized by effects.normalize()
states = {
    default = {
        on_feel = "SHARP! The edge bites into your finger...",
        on_feel_effect = "cut",  -- ← normalize() maps to inflict_injury table
    },
}
```

#### Pattern C: Combat Effect (unchanged)

```lua
-- src/meta/objects/knife.lua — already structured, routes through pipeline
on_stab = {
    damage = 5,
    injury_type = "bleeding",
    description = "You stab the knife into your %s.",
},
```

#### Pattern D: Pipeline-Native (NEW — shipped)

Objects with `effects_pipeline = true` use structured effect tables:

```lua
-- src/meta/objects/poison-bottle.lua (shipped)
return {
    id = "poison-bottle",
    effects_pipeline = true,

    transitions = {
        {
            from = "open", to = "empty", verb = "drink",
            effect = {
                type = "inflict_injury",
                injury_type = "poisoned-nightshade",
                source = "poison-bottle",
                damage = 10,
                message = "A bitter, almost sweet taste burns down your throat. Your heart begins to race.",
            },
            pipeline_effects = {
                { type = "inflict_injury", injury_type = "poisoned-nightshade",
                  source = "poison-bottle", damage = 10,
                  message = "A bitter, almost sweet taste burns down your throat. Your heart begins to race." },
                { type = "mutate", target = "self", field = "weight", value = 0.1 },
                { type = "mutate", target = "self", field = "is_consumable", value = false },
            },
        },
    },

    states = {
        open = {
            on_taste = "BITTER! Searing fire courses down your throat...",
            on_taste_effect = {
                type = "inflict_injury",
                injury_type = "poisoned-nightshade",
                source = "poison-bottle",
                damage = 5,
                message = "The taste alone is enough. Burning sweetness sears your tongue and throat.",
                pipeline_routed = true,
            },
        },
    },
}
```

### 2.4 The Problem (Now Resolved)

The legacy patterns (A and B) shared a flaw: **the verb handler had to know how to interpret each effect type.** Every new injury-causing mechanism required editing verb handler code. This violated the project's core principle:

> "Engine stays generic; objects own their behavior."

**Resolution:** `src/engine/effects.lua` now provides `effects.process()` — a unified dispatch that routes any effect declaration (string, table, or array) to the appropriate handler. Verb handlers delegate instead of interpreting. See `effects-pipeline.md` for full implementation details.

---

## 3. Consumable → Injury Pipeline (Poison) — Shipped

### 3.1 Legacy Flow (Before Pipeline)

```
Player types "drink bottle"
  → Parser resolves: verb = "drink", target = poison-bottle
    → Drink verb handler:
      1. Finds object in hands
      2. Finds transition: { from = "open", to = "empty", verb = "drink" }
      3. Executes FSM transition (bottle._state = "empty")
      4. Applies mutations (weight, keywords)
      5. Checks: if trans.effect == "poison" then  ← HARDCODED (was)
           injuries.inflict(player, "poisoned-nightshade", ...)
         end
      6. Prints transition message
    → Post-command tick:
      injuries.tick(player)  ← poison ticks begin
```

### 3.2 Current Flow (Pipeline-Routed)

```
Player types "drink bottle"
  → Parser resolves: verb = "drink", target = poison-bottle
    → Drink verb handler:
      1. Finds object in hands
      2. Finds transition: { from = "open", to = "empty", verb = "drink" }
      3. Executes FSM transition (bottle._state = "empty")
      4. Applies mutations
      5. If trans.effect then
           effects.process(trans.effect, ctx)  ← UNIFIED PIPELINE
         end
      6. Prints transition message
    → Post-command tick:
      injuries.tick(player)
```

### 3.3 Actual Object Metadata (Shipped)

```lua
-- src/meta/objects/poison-bottle.lua (actual shipped code)
{
    from = "open", to = "empty", verb = "drink",
    aliases = {"quaff", "sip", "gulp", "consume"},
    message = "You raise the bottle to your lips. The liquid burns like liquid fire. "
           .. "Your vision swims, your knees buckle, and the world tilts sideways...",
    effect = {
        type = "inflict_injury",
        injury_type = "poisoned-nightshade",
        source = "poison-bottle",
        damage = 10,
        message = "A bitter, almost sweet taste burns down your throat. Your heart begins to race.",
    },
    pipeline_effects = {
        { type = "inflict_injury", injury_type = "poisoned-nightshade",
          source = "poison-bottle", damage = 10,
          message = "A bitter, almost sweet taste burns down your throat. Your heart begins to race." },
        { type = "mutate", target = "self", field = "weight", value = 0.1 },
        { type = "mutate", target = "self", field = "is_consumable", value = false },
    },
    mutate = {
        weight = 0.1,
        is_consumable = false,
        categories = { remove = "dangerous" },
        keywords = { add = "empty" },
    },
}
```

### 3.4 Hook Used

**No new hook needed.** The consumable pipeline runs through the existing FSM transition system. The `effect` field on transitions is a de facto hook — the pipeline processes it via `effects.process()` instead of inline verb-handler code.

The drink verb fires the FSM transition. The transition carries an `effect`. The effect processor inflicts the injury. Clean separation.

---

## 4. Contact → Injury Pipeline (Bear Trap)

### 4.1 Two Sub-Cases

Contact injuries split into two distinct architectural paths:

| Sub-Case | Trigger | Example | Hook Needed |
|----------|---------|---------|-------------|
| **Sensory contact** | Player touches/feels the object | Glass shard, hot iron, thorns | `on_feel_effect` (exists, needs standardization) |
| **Spatial contact** | Player enters area with trap | Bear trap, pit trap, gas cloud | `on_enter_room` or `on_take` (not yet implemented) |

### 4.2 Sensory Contact (Glass Shard Pattern)

**Current:** `on_feel_effect = "cut"` checked inline by feel verb handler.

**Proposed:** Standardize to structured effect on any sensory callback:

```lua
-- src/meta/objects/glass-shard.lua (proposed)
states = {
    default = {
        on_feel = "SHARP! The edge bites into your finger...",
        on_feel_effect = {
            type = "inflict_injury",
            injury_type = "minor-cut",
            source = "glass-shard",
            location = "finger",
            damage = 3,
        },
    },
}
```

After the verb handler prints the sensory text, it checks for `on_{verb}_effect` and passes it to `effects.process()`. This generalizes to any sensory verb:

| Field | Verb | Example |
|-------|------|---------|
| `on_feel_effect` | feel | Glass shard cuts finger |
| `on_taste_effect` | taste | Poison detected (weaker dose than drinking) |
| `on_smell_effect` | smell | Noxious gas causes nausea |
| `on_touch_effect` | take | Thorny vine pricks hand |

### 4.3 Spatial Contact (Bear Trap Pattern)

A bear trap on the floor has two trigger conditions:

**Case A: Player takes the trap** — fires on `take` verb

```lua
-- src/meta/objects/bear-trap.lua
return {
    id = "bear-trap",
    name = "a rusted bear trap",
    initial_state = "set",
    states = {
        set = {
            on_look = "A rusty iron contraption with serrated jaws, half-hidden in debris.",
            on_feel = "SNAP! The jaws clamp shut on your hand!",
            on_feel_effect = {
                type = "inflict_injury",
                injury_type = "bleeding",
                source = "bear-trap",
                location = "hand",
                damage = 8,
                message = "The trap's iron jaws bite deep into your hand!",
            },
        },
        sprung = {
            on_look = "A sprung bear trap, jaws open and bent.",
            on_feel = "Cold iron. The jaws are bent open — it won't bite again.",
        },
    },
    transitions = {
        {
            from = "set", to = "sprung", verb = "take",
            message = "You reach for the trap — SNAP!",
            effect = {
                type = "inflict_injury",
                injury_type = "bleeding",
                source = "bear-trap",
                location = "hand",
                damage = 8,
                message = "Iron jaws clamp shut on your fingers!",
            },
            mutate = {
                weight = function(w) return w + 0.5 end,
            },
        },
    },
}
```

This uses the **existing transition effect pattern** — no new hook needed. The `take` verb finds the transition, executes it, and the effect processor inflicts the injury. The trap transitions from `set` → `sprung` so it can't hurt the player again.

**Case B: Hidden trap — player walks into it** — requires `on_enter_room` hook

```lua
-- In room metadata (room with hidden pit trap)
on_enter_room = {
    type = "trap_effect",
    trap_id = "pit-trap",
    injury_type = "bruised",
    damage = 6,
    location = "leg",
    avoid_check = { skill = "perception", difficulty = 3 },
    hit_message = "The floor gives way! You tumble into a shallow pit.",
    avoid_message = "You notice the loose flagstones just in time and step around them.",
    one_shot = true,
}
```

This requires implementing the `on_enter_room` hook from the planned catalog (see `about.md` section 4.2). The `trap_effect` subtype handler would:

1. Check if `one_shot` and already triggered → skip
2. Check `avoid_check` against player skills → print avoid_message and skip
3. Call `injuries.inflict(player, injury_type, trap_id, location, damage)`
4. Print `hit_message`
5. Mark trap as triggered (if `one_shot`)

### 4.4 Hidden Object Considerations

For a hidden bear trap (`is_hidden = true`):

| Player Action | What Happens | Hook/System |
|---------------|-------------|-------------|
| `look` in room | Trap not listed (hidden) | Existing: hidden objects excluded from room description |
| `search` room | Trap revealed if perception check passes | Existing: search system with skill gates |
| `feel` around room | "Something metal under the debris" | Existing: sensory per-state text |
| `take trap` (after revealed) | Trap snaps: injury + FSM transition to `sprung` | Transition effect (existing pattern) |
| `go` into room (trap on floor) | Trap springs on entry | `on_enter_room` hook (proposed) |
| `traverse` exit with trap | Trap springs on traversal | `on_traverse` hook with `trap_effect` subtype |

**Key distinction:** If the trap is an **object in the room**, it uses transition effects triggered by verbs (take, feel). If the trap is a **room-level hazard**, it uses `on_enter_room` or `on_traverse` hooks declared in room metadata.

---

## 5. The Effect Processing Pipeline — Shipped

> Full implementation details in `effects-pipeline.md`. This section summarizes the integration with the hook taxonomy.

### 5.1 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     EFFECT SOURCES                          │
│                                                             │
│  FSM Transition          Sensory Callback      Engine Hook  │
│  (trans.effect)          (on_taste_effect)     (on_enter)   │
│       │                       │                    │        │
│       └───────────┬───────────┘                    │        │
│                   ▼                                ▼        │
│          ┌─────────────────┐              ┌──────────────┐  │
│          │ effects.normalize│              │ Hook Handler  │  │
│          │ (string → table)│              │ (already has  │  │
│          └────────┬────────┘              │  structured   │  │
│                   │                       │  effect data) │  │
│                   └───────────┬───────────┘              │  │
│                               ▼                          │  │
│                    ┌───────────────────┐                  │  │
│                    │ effects.process() │ ◄────────────────┘  │
│                    │ (unified dispatch)│                     │
│                    └────────┬──────────┘                     │
│                             │                                │
│              ┌──────────────┼──────────────┐                 │
│              ▼              ▼              ▼                  │
│     ┌──────────────┐ ┌───────────┐ ┌────────────┐           │
│     │inflict_injury│ │ narrate   │ │ mutate     │           │
│     │              │ │           │ │            │           │
│     │injuries.     │ │print()    │ │obj[k]=v    │           │
│     │inflict()     │ │           │ │            │           │
│     └──────────────┘ └───────────┘ └────────────┘           │
│     ┌──────────────┐ ┌────────────┐                          │
│     │ add_status   │ │remove_     │                          │
│     │              │ │status      │                          │
│     │player.state[]│ │player.     │                          │
│     │              │ │state[]=nil │                          │
│     └──────────────┘ └────────────┘                          │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 Module: `src/engine/effects.lua` (232 lines)

The shipped module provides:

| Function | Purpose |
|----------|---------|
| `effects.register(type, fn)` | Register handler for effect type |
| `effects.unregister(type)` | Remove handler (testing) |
| `effects.has_handler(type)` | Check if handler exists |
| `effects.normalize(raw)` | String/table/array → array of `{type=...}` |
| `effects.process(raw, ctx)` | Main entry: normalize → intercept → dispatch |
| `effects.add_interceptor(phase, fn)` | Before/after interceptor registration |
| `effects.clear_interceptors()` | Clear all interceptors (testing) |

### 5.3 Built-in Effect Handlers (Shipped)

```lua
-- inflict_injury: pcall-safe routing to injuries.inflict()
-- Sets ctx.game_over = true on lethal damage (no more os.exit(0))
effects.register("inflict_injury", function(effect, ctx)
    local inj_ok, injury_mod = pcall(require, "engine.injuries")
    if not inj_ok then return nil end
    local instance = injury_mod.inflict(
        ctx.player, effect.injury_type,
        effect.source or ctx.source_id or "unknown",
        effect.location, effect.damage
    )
    if effect.message then print(effect.message) end
    if instance and ctx.player then
        local health = injury_mod.compute_health(ctx.player)
        if health <= 0 then ctx.game_over = true end
    end
    return instance
end)

-- narrate: print message
effects.register("narrate", function(effect, ctx)
    if effect.message then print(effect.message) end
end)

-- add_status: player.state[status] = {active, duration, severity}
effects.register("add_status", function(effect, ctx) ... end)

-- remove_status: player.state[status] = nil
effects.register("remove_status", function(effect, ctx) ... end)

-- mutate: target resolution → obj[field] = value
effects.register("mutate", function(effect, ctx) ... end)
```

### 5.4 Integration Points (Where Effects Fire via Pipeline)

| Source | Code Location | How Effect Is Accessed | Status |
|--------|--------------|----------------------|--------|
| FSM transition effect | Verb handler after `fsm.transition()` | `trans.effect → effects.process()` | ✅ Migrated |
| Sensory verb effect | Verb handler after printing sensory text | `state.on_{verb}_effect → effects.process()` | ✅ Migrated |
| Engine hook handler | Hook handler functions | Directly calls `effects.process()` | Ready (on_traverse future) |
| Combat verb effect | `verbs/init.lua` in stab/cut/hit | `obj.on_{verb}` → direct or pipeline | Route as needed |

---

## 6. Engine Event Taxonomy for Injury-Causing Objects

### 6.1 Complete Taxonomy (Updated)

| Category | Hook/Trigger | When It Fires | Example Objects | Injury Path | Status |
|----------|-------------|---------------|-----------------|-------------|--------|
| **Consumption** | FSM transition with `effect` | Player drinks/eats, transition executes | Poison bottle, bad food, tainted water | `trans.effect → effects.process() → injuries.inflict()` | ✅ **Shipped** |
| **Sensory Contact** | `on_{verb}_effect` on state | Player touches/feels/tastes object | Glass shard, hot iron, toxic plant | `state.on_taste_effect → effects.process() → injuries.inflict()` | ✅ **Shipped** |
| **Verb Contact** | `on_{verb}` table on object | Player stabs/cuts/hits with object | Knife (self-harm), blunt weapon | `obj.on_stab → injuries.inflict()` (route through pipeline as needed) | Existing |
| **Spatial Trap** | `on_enter_room` hook | Player enters room with trap | Pit trap, gas cloud, falling rocks | `hook handler → effects.process() → injuries.inflict()` | Planned |
| **Traversal Trap** | `on_traverse` hook | Player moves through exit | Tripwire, collapsing passage | `hook handler → effects.process() → injuries.inflict()` | Planned (hook exists) |
| **Acquisition Trap** | FSM transition on `take` | Player picks up trapped object | Bear trap, cursed item | `trans.effect → effects.process() → injuries.inflict()` | ✅ **Shipped** |
| **Duration/Tick** | `injuries.tick()` | Each game turn while injury active | Poison ticking, bleeding progression | `injuries.tick() → damage accumulation → state transitions` | Existing |
| **Environmental** | `on_timer` hook (room-level) | Turn counter reaches threshold | Room on fire, flooding, freezing | `hook handler → effects.process() → injuries.inflict()` | Planned |

### 6.2 Injury-Causing Hook Summary

| Hook Name | Status | Needed For | Priority |
|-----------|--------|-----------|----------|
| FSM `trans.effect` | ✅ **Routes through `effects.process()`** | Poison bottle, bear trap on take | **DONE** |
| `on_{verb}_effect` | ✅ **Routes through `effects.process()`** | Glass shard, poison bottle taste | **DONE** |
| `on_enter_room` | ❌ Designed, not implemented | Pit trap, gas cloud, room hazards | **MEDIUM** — needed for spatial traps |
| `on_traverse` | ✅ Implemented (independent) | Tripwire, collapsing passage | Future: route through pipeline |
| `on_pickup` | ❌ Designed, not implemented | Cursed items, weight effects | **LOW** — cursed items are a future feature |
| `on_timer` | ❌ Designed, not implemented | Room-level environmental damage | **LOW** — injury tick handles per-object duration |

---

## 7. Architecture Gaps & Recommendations (Updated)

### 7.1 Gap Analysis

| Gap | Severity | Status | Resolution |
|-----|----------|--------|------------|
| **No unified effect processor** | 🔴 Was High | ✅ **RESOLVED** | `src/engine/effects.lua` shipped (232 lines, 5 handlers) |
| **Effect strings not standardized** | 🔴 Was High | ✅ **RESOLVED** | `effects.normalize()` handles legacy strings; new objects use structured tables |
| **`on_enter_room` hook missing** | 🟡 Medium | ❌ Still open | Implement `on_enter_room` in hook framework |
| **No `trap_effect` subtype** | 🟡 Medium | ❌ Still open | Add `trap_effect` handler to `on_traverse` |
| **Sensory effect fields inconsistent** | 🟡 Was Medium | ✅ **RESOLVED** | Convention established: `on_{sense}_effect` for all 5 senses |
| **Hook framework not centralized** | 🟡 Medium | ❌ Still open | Migration per `about.md` Section 7 |

### 7.2 Is the Event System Extensible Enough?

**Yes.** The effect processing pipeline is now the standard path for all object-declared effects. Adding new effect types requires only `effects.register(type, handler)` — zero changes to verb handlers, the pipeline module, or object format.

**What was completed:**

1. ✅ **Created `src/engine/effects.lua`** — the unified effect processor
2. ✅ **Refactored verb handlers** to call `effects.process()` instead of inline effect checks
3. ✅ **Migrated poison-bottle.lua** — first pipeline-native object with `effects_pipeline = true`

**What still needs to happen:**

1. **Implement `on_enter_room` hook** for spatial traps (follows `traverse_effects.lua` pattern)
2. **Add `trap_effect` subtype** to `on_traverse` for traversal traps
3. **Migrate remaining objects** to structured effect tables (at Flanders's pace; legacy format still works)

### 7.3 Should Hooks Be Per-Object or Per-Verb?

**Per-object.** This is already the established pattern and it's correct:

| Approach | How It Works | Verdict |
|----------|-------------|---------|
| **Per-object** (current) | Object says "when someone drinks me, inflict poison" via `effect` on transition | ✅ Objects own their behavior. Engine stays generic. New injury objects require zero engine changes. |
| **Per-verb** (rejected) | Verb says "when drink is used on a consumable with `dangerous` category, check for effects" | ❌ Violates core principle. Every new injury source requires verb handler edits. |

The object declares *what* happens (effect metadata). The engine decides *when* it happens (hook integration point). The effect processor decides *how* (effect handler functions). Clean separation.

---

## 8. Injury Creation API for Objects

### 8.1 Structured Effect Declaration

Objects declare injury effects using this standard format:

```lua
effect = {
    type = "inflict_injury",
    injury_type = "poisoned-nightshade",   -- matches src/meta/injuries/{type}.lua
    source = "poison-bottle",               -- what caused the injury (for narration)
    location = "hand",                      -- body location (nil = systemic)
    damage = 10,                            -- override initial_damage from definition
    message = "A bitter taste burns...",    -- narration on infliction
}
```

### 8.2 Where Objects Can Declare Effects

| Location in Object Metadata | When It Fires | Example |
|----------------------------|---------------|---------|
| `transitions[].effect` | On FSM state transition | Poison bottle drink, bear trap take |
| `states[].on_feel_effect` | On feel/touch sensory verb | Glass shard cuts finger |
| `states[].on_taste_effect` | On taste sensory verb | Poison detected on lick |
| `states[].on_smell_effect` | On smell sensory verb | Noxious gas causes nausea |
| `on_stab` / `on_cut` / `on_hit` | On combat/violence verb | Knife stab, blunt hit |

### 8.3 Injury Definition Requirements

For objects to cause injuries, the injury type must exist in `src/meta/injuries/`. Each injury definition provides:

```lua
-- src/meta/injuries/{type}.lua
return {
    id = "poisoned-nightshade",
    name = "Nightshade Poisoning",
    category = "systemic",            -- physical | systemic | environmental
    damage_type = "over_time",        -- over_time | one_time | degenerative
    initial_state = "active",

    on_inflict = {
        initial_damage = 10,          -- immediate HP reduction
        damage_per_tick = 8,          -- per-turn drain (0 for one_time)
        message = "Your heart begins to race...",
    },

    states = { ... },                 -- FSM states with sensory text, damage, restrictions
    transitions = { ... },            -- Healing/worsening transitions
    healing_interactions = { ... },   -- Which items cure which states
}
```

### 8.4 Worked Examples

#### Poison Bottle — Completed Migration (shipped code)

The poison bottle is the first object fully migrated to the effects pipeline. The actual shipped metadata:

```lua
-- src/meta/objects/poison-bottle.lua (ACTUAL shipped code)
return {
    id = "poison-bottle",
    effects_pipeline = true,         -- ← pipeline-native flag
    is_consumable = true,
    consumable_type = "liquid",
    poison_type = "nightshade",
    poison_severity = "lethal",

    transitions = {
        -- drink: lethal dose via pipeline
        {
            from = "open", to = "empty", verb = "drink",
            aliases = {"quaff", "sip", "gulp", "consume"},
            message = "You raise the bottle to your lips...",
            effect = {
                type = "inflict_injury",
                injury_type = "poisoned-nightshade",
                source = "poison-bottle",
                damage = 10,
                message = "A bitter, almost sweet taste burns down your throat. "
                       .. "Your heart begins to race.",
            },
            pipeline_effects = {
                { type = "inflict_injury", injury_type = "poisoned-nightshade",
                  source = "poison-bottle", damage = 10,
                  message = "A bitter, almost sweet taste burns down your throat. "
                         .. "Your heart begins to race." },
                { type = "mutate", target = "self", field = "weight", value = 0.1 },
                { type = "mutate", target = "self", field = "is_consumable", value = false },
            },
            mutate = {
                weight = 0.1,
                is_consumable = false,
                categories = { remove = "dangerous" },
                keywords = { add = "empty" },
            },
        },
        -- pour: safe disposal (no effect)
        {
            from = "open", to = "empty", verb = "pour",
            aliases = {"spill", "dump"},
            message = "You tip the bottle. The green liquid pours out...",
            mutate = { weight = 0.1, is_consumable = false, ... },
        },
    },

    states = {
        open = {
            on_taste = "BITTER! Searing fire courses down your throat...",
            -- Sub-lethal warning dose via pipeline
            on_taste_effect = {
                type = "inflict_injury",
                injury_type = "poisoned-nightshade",
                source = "poison-bottle",
                damage = 5,
                message = "The taste alone is enough. Burning sweetness sears your tongue and throat.",
                pipeline_routed = true,
            },
        },
    },

    prerequisites = {
        drink = { requires_state = "open", warns = { "injury", "poisoned-nightshade" } },
        pour = { requires_state = "open" },
        taste = { warns = { "injury", "poisoned-nightshade" } },
    },
}
```

**Effect routing summary:**

| Player Action | Effect Path | Damage |
|---------------|------------|--------|
| `drink bottle` | `trans.effect → effects.process() → inflict_injury(poisoned-nightshade, 10)` | 10 |
| `taste bottle` (open) | `state.on_taste_effect → effects.process() → inflict_injury(poisoned-nightshade, 5)` | 5 |
| `pour bottle` | No effect — safe disposal | 0 |

#### Bear Trap (Contact → Injury on Take)

```lua
-- Object: bear-trap.lua
transitions = {
    {
        from = "set", to = "sprung", verb = "take",
        message = "You reach for the trap — SNAP!",
        effect = {
            type = "inflict_injury",
            injury_type = "bleeding",
            source = "bear-trap",
            location = "hand",
            damage = 8,
            message = "Iron jaws clamp shut on your fingers!",
        },
    },
}
```

#### Pit Trap (Spatial → Injury on Room Entry — Future)

```lua
-- Room metadata (not yet implemented — requires on_enter_room hook)
on_enter_room = {
    type = "trap_effect",
    trap_id = "pit-trap",
    injury_type = "bruised",
    damage = 6,
    location = "leg",
    hit_message = "The floor gives way beneath you! You tumble into a shallow pit.",
    avoid_check = { skill = "perception", difficulty = 3 },
    avoid_message = "You notice the loose flagstones and step carefully around them.",
    one_shot = true,
}
```

---

## 9. Implementation Status & Migration Guide

### 9.1 Completed Work

| Task | Status | Delivered |
|------|--------|-----------|
| Create `src/engine/effects.lua` with `effects.process()` and 5 handlers | ✅ **DONE** | 232 lines, fully tested |
| Add `effects.normalize()` for backward compatibility with string effects | ✅ **DONE** | Legacy strings map to structured tables |
| Refactor verb handlers to call `effects.process()` | ✅ **DONE** | Inline checks replaced with one-line delegation |
| Migrate poison-bottle to structured `effect` tables | ✅ **DONE** | First pipeline-native object |
| Before/after interceptor infrastructure | ✅ **DONE** | Shipped (runs empty — zero overhead) |

### 9.2 Remaining Work

| Priority | Task | Effort | Enables |
|----------|------|--------|---------|
| **P2** | Implement `on_enter_room` hook + `trap_effect` subtype | Medium | Spatial traps (pit, gas) |
| **P2** | Add `trap_effect` subtype to existing `on_traverse` | Small | Traversal traps (tripwire) |
| **P3** | Migrate `traverse_effects.lua` into `src/engine/hooks/` structure | Small | Clean module organization |
| **P3** | Implement remaining hooks from catalog (`on_pickup`, `on_drop`, etc.) | Large (per hook) | Future mechanics |

### 9.3 Migration Guide: Adopting the Pipeline for Existing Objects

To migrate an existing object to the effects pipeline:

**Step 1: Add the pipeline flag**
```lua
return {
    id = "your-object",
    effects_pipeline = true,    -- ← signals pipeline-native
    -- ...
}
```

**Step 2: Replace string effects with structured tables**

Before (legacy):
```lua
effect = "poison"
```

After (pipeline-native):
```lua
effect = {
    type = "inflict_injury",
    injury_type = "poisoned-nightshade",
    source = "your-object",
    damage = 10,
    message = "Your narration here.",
}
```

**Step 3: Replace sensory string effects with structured tables**

Before (legacy):
```lua
on_taste_effect = "poison"
```

After (pipeline-native):
```lua
on_taste_effect = {
    type = "inflict_injury",
    injury_type = "poisoned-nightshade",
    source = "your-object",
    damage = 5,
    message = "A weaker dose narration here.",
    pipeline_routed = true,
}
```

**Step 4 (optional): Add `pipeline_effects` for atomic processing**

If the transition has multiple side effects (injury + mutation), add a `pipeline_effects` array:
```lua
pipeline_effects = {
    { type = "inflict_injury", injury_type = "poisoned-nightshade",
      source = "your-object", damage = 10 },
    { type = "mutate", target = "self", field = "weight", value = 0.1 },
    { type = "mutate", target = "self", field = "is_consumable", value = false },
}
```

**Step 5: Add GOAP prerequisites with `warns` hints**
```lua
prerequisites = {
    drink = { requires_state = "open", warns = { "injury", "your-injury-type" } },
}
```

**Reference implementation:** `src/meta/objects/poison-bottle.lua` — the first completed migration.

---

## 10. Relationship to Existing Architecture

This document extends:
- **`docs/architecture/engine/event-handlers/about.md`** — The hook framework design. The effect processing layer (Layer 3.6) sits between hooks and the injury system.
- **`docs/architecture/00-architecture-overview.md`** — Layer 3.5 Engine Hooks. The effect processor is Layer 3.6.
- **`docs/architecture/engine/effects-pipeline.md`** — The full implementation specification for the pipeline.

This document does NOT change:
- **FSM architecture** — States, transitions, timers, thresholds all stay the same.
- **Injury system** — `injuries.inflict()`, `tick()`, `try_heal()` APIs unchanged.
- **Verb system** — Verbs still dispatch to FSM transitions. They now delegate effect processing to `effects.process()`.
- **Object metadata format** — Backward compatible. Existing string effects still work via `effects.normalize()`.

---

## Appendix A: Cross-Reference

| Document | What It Covers |
|----------|---------------|
| `effects-pipeline.md` | **Full implementation spec** — API signatures, handler code, interceptors, migration status |
| `event-handlers/about.md` | Hook framework design (12 hooks, registry, dispatch) |
| `event-handlers/wind_effect.md` | First implemented hook subtype |
| `event-handlers/puzzle-designer-guide.md` | Content author guide to using hooks |
| `docs/injuries/README.md` | Injury type index |
| `docs/injuries/poisoned-nightshade.md` | Detailed nightshade poison design |
| `docs/injuries/bleeding.md` | Detailed bleeding wound design |
| `docs/verbs/drink.md` | Drink verb behavior spec |
| `src/engine/effects.lua` | **The pipeline implementation (232 lines, 5 handlers)** |
| `src/meta/objects/poison-bottle.lua` | **First completed pipeline migration** |
| This document | Hook taxonomy, gap analysis, pipeline integration, migration guide |
