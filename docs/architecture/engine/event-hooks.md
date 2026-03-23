# Engine Event Hooks — Injury Pipeline Architecture

**Version:** 1.0
**Date:** 2026-07-22
**Author:** Bart (Architect)
**Status:** Architecture Analysis + Design Proposal
**Requested by:** Wayne "Effe" Berry

---

## 1. Executive Summary

This document analyzes how `.lua` object files hook into the engine to cause injuries, with two reference cases: **consumable → injury** (poison bottle) and **contact → injury** (bear trap). It audits what exists today, identifies architectural gaps, and proposes the **Effect Processing Pipeline** — a unified system for translating object-declared effects into engine actions like injury infliction.

**Key finding:** The engine has a robust injury system (`injuries.inflict()`) and a designed-but-mostly-unimplemented hook framework (only `on_traverse` is live). The missing piece is a **standardized effect processor** that bridges the gap between object metadata and the injury engine. Today, this bridge is ad-hoc — scattered across verb handlers as inline string checks.

---

## 2. Current State Audit

### 2.1 What Exists Today

| System | Status | Location | Notes |
|--------|--------|----------|-------|
| **Injury Engine** | ✅ Fully implemented | `src/engine/injuries.lua` | `inflict()`, `tick()`, `compute_health()`, `try_heal()`, 6 injury types |
| **FSM Engine** | ✅ Fully implemented | `src/engine/fsm/init.lua` | States, transitions, timers, `on_tick`, `on_transition` callbacks |
| **Hook Framework** | 🟡 Designed, 1 of 12 implemented | `src/engine/traverse_effects.lua` | Only `on_traverse` + `wind_effect` is live |
| **Hook Architecture Doc** | ✅ Comprehensive | `docs/architecture/engine/event-handlers/about.md` | 12 hooks cataloged, registry pattern designed |
| **Object Effect Declarations** | 🟡 Ad-hoc patterns | `src/meta/objects/*.lua` | `effect = "poison"`, `on_feel_effect = "cut"`, `on_taste_effect = "poison"` |
| **Effect Processing** | ❌ Missing | (scattered in verb handlers) | No unified pipeline; verb handlers interpret effect strings inline |

### 2.2 Currently Active Hooks

| Hook | Location | Implementation |
|------|----------|---------------|
| `on_traverse` | `traverse_effects.lua` + `verbs/init.lua` | Wind effect extinguishes candles on exit traversal |
| `on_tick` (per-state) | `fsm/init.lua` | Legacy per-state callback, runs every game tick |
| `on_transition` (per-transition) | `fsm/init.lua` | Fires when FSM transition executes |
| `on_feel/look/smell/taste/listen` | Verb handlers | Sensory callbacks (string or function) per state |
| `on_taste_effect` | Verb handler (taste) | Inline check in taste verb: triggers poison |
| `on_feel_effect` | Verb handler (feel) | Inline check in feel verb: triggers cut |
| `effect` (on transition) | Verb handler (drink, etc.) | Inline check after FSM transition: triggers injury |

### 2.3 How Objects Currently Cause Injuries

There are **three patterns** in today's codebase, all ad-hoc:

#### Pattern A: Transition Effect (Poison Bottle — Drink)

```lua
-- src/meta/objects/poison-bottle.lua
transitions = {
    {
        from = "open", to = "empty", verb = "drink",
        message = "You raise the bottle to your lips...",
        effect = "poison",  -- ← String tag, interpreted by verb handler
    },
}
```

The `drink` verb handler checks for `trans.effect == "poison"` after executing the FSM transition, then calls `injuries.inflict(player, "poisoned-nightshade", "poison-bottle", nil, 10)`. The mapping from `"poison"` → `"poisoned-nightshade"` is **hardcoded in the verb handler**.

#### Pattern B: Sensory Effect (Glass Shard — Feel)

```lua
-- src/meta/objects/glass-shard.lua
states = {
    default = {
        on_feel = "SHARP! The edge bites into your finger...",
        on_feel_effect = "cut",  -- ← String tag, checked by feel verb
    },
}
```

The `feel` verb handler checks for `state.on_feel_effect == "cut"` after printing the sensory text, then calls `injuries.inflict(player, "minor-cut", obj.id, "finger", 3)`. Again, the mapping and parameters are **inline in the verb handler**.

#### Pattern C: Combat Effect (Knife — Stab/Cut)

```lua
-- src/meta/objects/knife.lua
on_stab = {
    damage = 5,
    injury_type = "bleeding",
    description = "You stab the knife into your %s.",
},
on_cut = {
    damage = 3,
    injury_type = "minor-cut",
},
```

The `stab`/`cut` verb handlers read the structured `on_stab`/`on_cut` tables directly and call `injuries.inflict()` with the specified parameters. This is the **most structured** of the three patterns — the object carries its own injury metadata.

### 2.4 The Problem

All three patterns work, but they share a flaw: **the verb handler must know how to interpret each effect type.** Every new injury-causing mechanism requires editing verb handler code. This violates the project's core principle:

> "Engine stays generic; objects own their behavior."

---

## 3. Consumable → Injury Pipeline (Poison)

### 3.1 Current Flow

```
Player types "drink bottle"
  → Parser resolves: verb = "drink", target = poison-bottle
    → Drink verb handler:
      1. Finds object in hands
      2. Finds transition: { from = "open", to = "empty", verb = "drink" }
      3. Executes FSM transition (bottle._state = "empty")
      4. Applies mutations (weight, keywords)
      5. Checks: if trans.effect == "poison" then  ← HARDCODED
           injuries.inflict(player, "poisoned-nightshade", ...)
         end
      6. Prints transition message
    → Post-command tick:
      injuries.tick(player)  ← poison ticks begin
```

### 3.2 Proposed Flow

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

### 3.3 What the Object Metadata Should Look Like

```lua
-- src/meta/objects/poison-bottle.lua (proposed)
transitions = {
    {
        from = "open", to = "empty", verb = "drink",
        aliases = {"quaff", "sip", "gulp"},
        message = "You raise the bottle to your lips...",
        effect = {
            type = "inflict_injury",
            injury_type = "poisoned-nightshade",
            source = "poison-bottle",
            damage = 10,
            message = "A bitter, almost sweet taste burns down your throat. "
                   .. "Your heart begins to race.",
        },
        mutate = {
            weight = 0.1,
            categories = { remove = "dangerous" },
        },
    },
}
```

**Backward compatibility:** The engine should accept both legacy `effect = "poison"` (string) and new `effect = { type = "inflict_injury", ... }` (table) formats. A `normalize_effect()` function converts strings to tables using a mapping:

```lua
local legacy_map = {
    poison = { type = "inflict_injury", injury_type = "poisoned-nightshade" },
    cut    = { type = "inflict_injury", injury_type = "minor-cut" },
    burn   = { type = "inflict_injury", injury_type = "burn" },
    bruise = { type = "inflict_injury", injury_type = "bruised" },
}
```

### 3.4 Hook Used

**No new hook needed.** The consumable pipeline runs through the existing FSM transition system. The `effect` field on transitions is already a de facto hook — it just needs a standardized processor instead of inline verb-handler code.

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

## 5. The Effect Processing Pipeline

### 5.1 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     EFFECT SOURCES                          │
│                                                             │
│  FSM Transition          Sensory Callback      Engine Hook  │
│  (trans.effect)          (on_feel_effect)      (on_enter)   │
│       │                       │                    │        │
│       └───────────┬───────────┘                    │        │
│                   ▼                                ▼        │
│          ┌─────────────────┐              ┌──────────────┐  │
│          │ normalize_effect│              │ Hook Handler  │  │
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
│     │inflict_injury│ │ fsm_trans │ │ spawn_obj  │           │
│     │              │ │           │ │            │           │
│     │injuries.     │ │fsm.       │ │registry.   │           │
│     │inflict()     │ │transition()│ │register() │           │
│     └──────────────┘ └───────────┘ └────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 Module Design

```lua
-- src/engine/effects.lua (proposed)

local effects = {}
local handlers = {}

function effects.register(effect_type, handler_fn)
    handlers[effect_type] = handler_fn
end

function effects.process(effect, ctx)
    if not effect then return false end
    if type(effect) == "string" then
        effect = effects.normalize(effect)
    end
    if not effect or not effect.type then return false end
    local handler = handlers[effect.type]
    if not handler then return false end
    handler(effect, ctx)
    return true
end

function effects.normalize(effect_string)
    local legacy_map = {
        poison = { type = "inflict_injury", injury_type = "poisoned-nightshade" },
        cut    = { type = "inflict_injury", injury_type = "minor-cut" },
        burn   = { type = "inflict_injury", injury_type = "burn" },
        bruise = { type = "inflict_injury", injury_type = "bruised" },
    }
    return legacy_map[effect_string]
end

return effects
```

### 5.3 Built-in Effect Handlers

```lua
-- inflict_injury: the primary effect type for injury-causing objects
effects.register("inflict_injury", function(effect, ctx)
    local injury_mod = require("engine.injuries")
    local instance = injury_mod.inflict(
        ctx.player,
        effect.injury_type,
        effect.source or "unknown",
        effect.location,
        effect.damage
    )
    if effect.message then
        print(effect.message)
    end
    return instance
end)

-- fsm_transition: trigger a state change on another object
effects.register("fsm_transition", function(effect, ctx)
    local fsm_mod = require("engine.fsm")
    fsm_mod.transition(ctx.registry, effect.target_id, effect.to_state, ctx, effect.verb_hint)
end)

-- spawn_object: materialize a new object in room or inventory
effects.register("spawn_object", function(effect, ctx)
    local loader = require("engine.loader")
    -- load and register the spawned object
end)
```

### 5.4 Integration Points (Where Effects Fire)

| Source | Code Location | How Effect Is Accessed |
|--------|--------------|----------------------|
| FSM transition effect | `fsm/init.lua` after `apply_state()` | `trans.effect` |
| Sensory verb effect | `verbs/init.lua` in sensory handlers | `state.on_{verb}_effect` |
| Engine hook handler | Hook handler functions | Directly calls `effects.process()` |
| Combat verb effect | `verbs/init.lua` in stab/cut/hit | `obj.on_{verb}` (already structured) |

---

## 6. Engine Event Taxonomy for Injury-Causing Objects

### 6.1 Complete Taxonomy

| Category | Hook/Trigger | When It Fires | Example Objects | Injury Path |
|----------|-------------|---------------|-----------------|-------------|
| **Consumption** | FSM transition with `effect` | Player drinks/eats, transition executes | Poison bottle, bad food, tainted water | `trans.effect → effects.process() → injuries.inflict()` |
| **Sensory Contact** | `on_{verb}_effect` on state | Player touches/feels/tastes object | Glass shard, hot iron, toxic plant | `state.on_feel_effect → effects.process() → injuries.inflict()` |
| **Verb Contact** | `on_{verb}` table on object | Player stabs/cuts/hits with object | Knife (self-harm), blunt weapon | `obj.on_stab → injuries.inflict()` (already structured) |
| **Spatial Trap** | `on_enter_room` hook | Player enters room with trap | Pit trap, gas cloud, falling rocks | `hook handler → effects.process() → injuries.inflict()` |
| **Traversal Trap** | `on_traverse` hook | Player moves through exit | Tripwire, collapsing passage | `hook handler → effects.process() → injuries.inflict()` |
| **Acquisition Trap** | FSM transition on `take` | Player picks up trapped object | Bear trap, cursed item | `trans.effect → effects.process() → injuries.inflict()` |
| **Duration/Tick** | `injuries.tick()` | Each game turn while injury active | Poison ticking, bleeding progression | `injuries.tick() → damage accumulation → state transitions` |
| **Environmental** | `on_timer` hook (room-level) | Turn counter reaches threshold | Room on fire, flooding, freezing | `hook handler → effects.process() → injuries.inflict()` |

### 6.2 Injury-Causing Hook Summary

| Hook Name | Implemented? | Needed For | Priority |
|-----------|-------------|-----------|----------|
| FSM `trans.effect` | 🟡 Exists as string, needs `effects.process()` | Poison bottle, bear trap on take | **HIGH** — enables all consumable injuries |
| `on_{verb}_effect` | 🟡 Exists as string, needs `effects.process()` | Glass shard, hot iron | **HIGH** — enables all sensory contact injuries |
| `on_enter_room` | ❌ Designed, not implemented | Pit trap, gas cloud, room hazards | **MEDIUM** — needed for spatial traps |
| `on_traverse` | ✅ Implemented | Tripwire, collapsing passage | Already works; add `trap_effect` subtype |
| `on_pickup` | ❌ Designed, not implemented | Cursed items, weight effects | **LOW** — cursed items are a future feature |
| `on_timer` | ❌ Designed, not implemented | Room-level environmental damage | **LOW** — injury tick handles per-object duration |

---

## 7. Architecture Gaps & Recommendations

### 7.1 Gap Analysis

| Gap | Severity | Description | Fix |
|-----|----------|-------------|-----|
| **No unified effect processor** | 🔴 High | Verb handlers interpret effect strings inline. Every new effect type requires editing verb code. | Create `src/engine/effects.lua` with `effects.process()` |
| **Effect strings not standardized** | 🔴 High | `effect = "poison"` is a string. Mapping to injury type is hardcoded in verb handler. | Standardize to `effect = { type = "inflict_injury", injury_type = "...", ... }` |
| **`on_enter_room` hook missing** | 🟡 Medium | No way for rooms to inflict injuries on entry (spatial traps). | Implement `on_enter_room` in hook framework |
| **No `trap_effect` subtype** | 🟡 Medium | `on_traverse` exists but has no trap subtype. | Add `trap_effect` handler to `on_traverse` |
| **Sensory effect fields inconsistent** | 🟡 Medium | `on_feel_effect` exists on glass-shard, `on_taste_effect` on poison-bottle. No convention for other senses. | Document standard: `on_{sense}_effect` for all 5 senses |
| **Hook framework not centralized** | 🟡 Medium | `traverse_effects.lua` is standalone, not in planned `src/engine/hooks/` structure. | Migration per `about.md` Section 7 |

### 7.2 Is the Current Event System Extensible Enough?

**Yes, architecturally.** The designed hook framework in `about.md` is solid — registry pattern, dispatch, metadata declaration. The problem isn't the design, it's that only 1 of 12 hooks is implemented.

**What needs to happen:**

1. **Create `src/engine/effects.lua`** — the unified effect processor (Section 5.2). This is the highest-value change. It eliminates inline verb-handler effect interpretation.

2. **Refactor verb handlers** to call `effects.process()` instead of inline effect checks. Surgical: find every `if trans.effect` and `if state.on_{x}_effect` check, replace with `effects.process()`.

3. **Implement `on_enter_room` hook** for spatial traps. This follows the existing `traverse_effects.lua` pattern exactly.

4. **Add `trap_effect` subtype** to `on_traverse` for traversal traps.

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

### 8.4 Full Worked Examples

#### Poison Bottle (Consumable → Injury)

```lua
-- Object: poison-bottle.lua
-- Injury path: drink → transition effect → inflict_injury → poisoned-nightshade

transitions = {
    {
        from = "open", to = "empty", verb = "drink",
        aliases = {"quaff", "sip", "gulp"},
        message = "You raise the bottle to your lips and drink deeply.",
        effect = {
            type = "inflict_injury",
            injury_type = "poisoned-nightshade",
            source = "poison-bottle",
            damage = 10,
            message = "A bitter, almost sweet taste burns down your throat. "
                   .. "Your pupils dilate. Your heart begins to race.",
        },
        mutate = {
            weight = 0.1,
            categories = { remove = "dangerous" },
        },
    },
}
```

#### Bear Trap (Contact → Injury on Take)

```lua
-- Object: bear-trap.lua
-- Injury path: take → transition effect → inflict_injury → bleeding

transitions = {
    {
        from = "set", to = "sprung", verb = "take",
        message = "You reach for the trap —",
        effect = {
            type = "inflict_injury",
            injury_type = "bleeding",
            source = "bear-trap",
            location = "hand",
            damage = 8,
            message = "SNAP! The iron jaws clamp shut on your fingers!",
        },
    },
}
```

#### Pit Trap (Spatial → Injury on Room Entry)

```lua
-- Room metadata (not an object — room-level hook)
-- Injury path: on_enter_room → trap_effect handler → inflict_injury → bruised

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

## 9. Implementation Priority

| Priority | Task | Effort | Enables |
|----------|------|--------|---------|
| **P0** | Create `src/engine/effects.lua` with `effects.process()` and `inflict_injury` handler | Small (< 100 lines) | All structured injury effects |
| **P0** | Add `normalize_effect()` for backward compatibility with string effects | Tiny (< 20 lines) | Zero-breakage migration |
| **P1** | Refactor verb handlers to call `effects.process()` instead of inline checks | Medium (surgical edits across verbs/init.lua) | Unified pipeline |
| **P1** | Update poison-bottle + glass-shard to use structured `effect` tables | Small | Reference implementations |
| **P2** | Implement `on_enter_room` hook + `trap_effect` subtype | Medium | Spatial traps (pit, gas) |
| **P2** | Add `trap_effect` subtype to existing `on_traverse` | Small | Traversal traps (tripwire) |
| **P3** | Migrate `traverse_effects.lua` into `src/engine/hooks/` structure | Small | Clean module organization |
| **P3** | Implement remaining hooks from catalog (`on_pickup`, `on_drop`, etc.) | Large (per hook) | Future mechanics |

---

## 10. Relationship to Existing Architecture

This document extends:
- **`docs/architecture/engine/event-handlers/about.md`** — The hook framework design. This document adds the **effect processing layer** that sits between hooks and the injury system.
- **`docs/architecture/00-architecture-overview.md`** — Layer 3.5 Engine Hooks. The effect processor becomes Layer 3.6.

This document does NOT change:
- **FSM architecture** — States, transitions, timers, thresholds all stay the same.
- **Injury system** — `injuries.inflict()`, `tick()`, `try_heal()` APIs unchanged.
- **Verb system** — Verbs still dispatch to FSM transitions. They just delegate effect processing.
- **Object metadata format** — Backward compatible. Existing string effects still work via `normalize_effect()`.

---

## Appendix A: Cross-Reference

| Document | What It Covers |
|----------|---------------|
| `event-handlers/about.md` | Hook framework design (12 hooks, registry, dispatch) |
| `event-handlers/wind_effect.md` | First implemented hook subtype |
| `event-handlers/puzzle-designer-guide.md` | Content author guide to using hooks |
| `docs/injuries/README.md` | Injury type index |
| `docs/injuries/poisoned-nightshade.md` | Detailed nightshade poison design |
| `docs/injuries/bleeding.md` | Detailed bleeding wound design |
| `docs/verbs/drink.md` | Drink verb behavior spec |
| This document | How objects cause injuries via hooks + effects pipeline |
