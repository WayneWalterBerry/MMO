# Butchery System

**Author:** Brockman (Documentation)  
**Date:** 2026-08-16  
**Version:** 1.0  
**Status:** Approved for WAVE-1 Implementation  
**Related:** `creature-death-reshape.md`, `../../design/food-system.md`, `../../.squad/decisions.md` (Decision D-CREATURE-DEATH)

---

## 1. The Problem Space

### Why Butchery Exists

Phase 3 established creature death → corpse → cooking pipeline. But large creatures (wolf) reshape to `furniture` template after death, making them non-portable. A player cannot:

- Pick up a wolf corpse and carry it
- Cook a corpse directly (too bulky)
- Extract usable resources from the creature

The wolf becomes a dead-end asset — visitable, interactive, but not processable into useful items. This breaks the resource extraction loop identified as critical for Phase 4's "crafting loop" theme.

### The Solution

**Butchery** is a verb handler that converts large (furniture-template) corpses into portable meat cuts, bones, and hides. The system uses:

1. **Metadata declaration** — `butchery_products` block on creature death_state
2. **Tool capability check** — requires "butchering" capability (e.g., knife)
3. **Configurable duration** — game-time advancement (Q1 resolved: Option B)
4. **Product instantiation** — creates room-floor objects for each product
5. **Corpse removal** — optional cleanup after butchery completes

---

## 2. Architecture Overview

### Pipeline Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ Player: "butcher wolf"                                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────┐
        │ Resolve: find wolf corpse│
        │ (dead creature, in room) │
        └──────────────┬───────────┘
                       │
                       ▼
        ┌──────────────────────────────────┐
        │ Validate: death_state exists?    │
        │ Validate: butchery_products?     │
        └──────────────┬───────────────────┘
                       │
                       ▼
        ┌──────────────────────────────────────┐
        │ Tool Check: player has tool with     │
        │ "butchering" capability?             │
        └──────────────┬──────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │ NO                           │ YES
        ▼                              ▼
    Return Error            ┌──────────────────────┐
                            │ Advance game time    │
                            │ (5 min: Option B)    │
                            │ Trigger FSM ticks    │
                            └──────────┬───────────┘
                                       │
                                       ▼
                            ┌──────────────────────┐
                            │ For each product:    │
                            │ registry:instantiate │
                            │ room:add_object      │
                            └──────────┬───────────┘
                                       │
                                       ▼
                            ┌──────────────────────┐
                            │ If removes_corpse:   │
                            │ room:remove_object   │
                            │ registry:deregister  │
                            └──────────┬───────────┘
                                       │
                                       ▼
                            ┌──────────────────────┐
                            │ Print completion     │
                            │ message              │
                            └──────────────────────┘
```

### Core Concepts

1. **Death state requirement** — Only creatures that have undergone death reshape (via `reshape_instance()`) are butcherable. The corpse must have `death_state` metadata.

2. **Capability-based tool check** — Tool selection is NOT object-ID based. The system checks: `player:find_tool_with_capability("butchering")`. This allows multiple objects (knife, butcher-knife, cleaver) to serve this role.

3. **Metadata-driven products** — Butchery outputs are completely defined by `butchery_products` block. Engine has no hard-coded knowledge of wolf-specific or creature-specific products. Principle 8: "Engine executes metadata."

4. **Time advancement (Option B)** — Butchery advances the game clock (default: 5 minutes game time). This triggers FSM ticks, candle burn, creature respawns, and spoilage checks. Creates strategic depth: player must manage time while butchering.

5. **Corpse removal optional** — `removes_corpse` flag controls whether the corpse instance is deleted after butchery. For smaller creatures, the corpse might remain visible but empty.

---

## 3. Metadata Specification

### `butchery_products` Block

Placed within a creature's `death_state` block:

```lua
death_state = {
    template = "furniture",  -- reshaped template after death
    portable = false,
    -- ... other death_state fields ...

    butchery_products = {
        -- REQUIRED: capability name for tool check
        requires_tool = "butchering",

        -- REQUIRED: game-time duration (string for display)
        -- Actual tick advancement happens via ctx.game:advance_time()
        duration = "5 minutes",

        -- REQUIRED: array of product specs
        products = {
            { id = "wolf-meat", quantity = 3 },
            { id = "wolf-bone", quantity = 2 },
            { id = "wolf-hide", quantity = 1 },
        },

        -- REQUIRED: narration messages
        narration = {
            start = "You begin carving the wolf carcass...",
            complete = "You finish butchering the wolf. Meat, bones, and hide lie at your feet.",
        },

        -- OPTIONAL: whether corpse disappears after butchery
        removes_corpse = true,  -- default: false
    },
},
```

### Field Reference

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `requires_tool` | string | Yes | Capability name (e.g., "butchering"). Tool must have this in its `capabilities` array. |
| `duration` | string | Yes | Human-readable duration for display. Actual time advance set by handler via `ctx.game:advance_time()` or similar. |
| `products` | array | Yes | Each element: `{id, quantity}`. `id` is object template ID (must resolve via `registry:get_template()`). `quantity` is integer. |
| `narration.start` | string | Yes | Printed when butchery begins. |
| `narration.complete` | string | Yes | Printed when butchery finishes. |
| `removes_corpse` | boolean | No | Default `false`. If true, corpse removed after butchery and deregistered from registry. |

---

## 4. Integration Points

### 1. Verb Handler Pipeline

**Location:** `src/engine/verbs/crafting.lua` (or extracted `butchery.lua` if LOC budget requires)

```lua
verbs.butcher = function(context, noun)
    -- 1. Resolve corpse
    local target = resolve_object(context, noun)
    if not target then
        err_not_found(context)
        return
    end

    -- 2. Validate death_state + butchery_products
    if not target.death_state or not target.death_state.butchery_products then
        context.print("There's nothing useful to carve from that.")
        return
    end

    local butch = target.death_state.butchery_products

    -- 3. Tool check
    local tool = context.player:find_tool_with_capability(butch.requires_tool)
    if not tool then
        context.print(string.format("You need a %s to butcher this.", butch.requires_tool))
        return
    end

    -- 4. Advance time
    context.print(butch.narration.start)
    context.game:advance_time(300)  -- 5 minutes in ticks

    -- 5. Instantiate products
    for _, product_spec in ipairs(butch.products) do
        for i = 1, product_spec.quantity do
            local instance = context.registry:instantiate(product_spec.id)
            context.room:add_object(instance)
        end
    end

    -- 6. Remove corpse if specified
    if butch.removes_corpse then
        context.room:remove_object(target)
        context.registry:deregister(target.guid)
    end

    context.print(butch.narration.complete)
end
```

**Verb aliases:** `butcher`, `carve`, `skin`, `fillet` (handled via parser embedding index)

### 2. Death Reshape Connection

Butchery relies on `reshape_instance()` from `src/engine/creatures/death.lua`. When a creature dies:

1. `kill_handler()` detects death
2. `reshape_instance(creature, creature.death_state)` converts creature → corpse
3. Corpse instance remains registered with original GUID
4. Corpse's `death_state` block now contains `butchery_products` metadata

Butchery reads this metadata at runtime. No file-swap occurs; the instance is transformed in-place (Principle 8, D-14 compliance).

### 3. Registry Instantiation

When butchery produces items, it uses:

```lua
local instance = context.registry:instantiate(product_spec.id)
```

This requires:
- `product_spec.id` matches a template in `src/meta/objects/` (e.g., `wolf-meat.lua`)
- Template returns valid object table with required fields: `id`, `template`, `guid`, sensory properties

### 4. Room Placement

After instantiation, products are added to the room:

```lua
context.room:add_object(instance)
```

This places the object on the floor (room's `room_presence` array). Objects are immediately visible and interact-able by the player.

### 5. Time Advancement (Option B Decision)

Butchery advances game time by a fixed duration (default: 5 minutes). This triggers:

- **FSM ticks** on all active creatures in the room
- **Candle burn** (if light source present)
- **Spoilage checks** (cooked meat → rotten meat FSM)
- **Creature respawns** (if respawn_interval timer expires)
- **Narration hooks** (optional time-triggered messages)

Implementation via `context.game:advance_time(ticks)` where 1 tick = 6 seconds game-time.

---

## 5. Example: Wolf Butchery

### Wolf Death State (in `src/meta/creatures/wolf.lua`)

```lua
death_state = {
    template = "furniture",
    portable = false,
    description = "The wolf's carcass lies motionless, blood pooling beneath it.",
    on_feel = "Warm fur and thick muscle beneath. Heavy.",

    butchery_products = {
        requires_tool = "butchering",
        duration = "5 minutes",
        products = {
            { id = "wolf-meat", quantity = 3 },
            { id = "wolf-bone", quantity = 2 },
            { id = "wolf-hide", quantity = 1 },
        },
        narration = {
            start = "You begin carving the wolf carcass with your knife. Blood and fur fly.",
            complete = "You finish butchering the wolf. Three cuts of meat, two bones, and a pelt lie at your feet.",
        },
        removes_corpse = true,
    },
},
```

### Player Interaction Sequence

```
> butcher wolf
You begin carving the wolf carcass with your knife. Blood and fur fly.
[5 minutes pass: candles burn, time ticks, spoilage advances...]
You finish butchering the wolf. Three cuts of meat, two bones, and a pelt lie at your feet.

> look
This is the Forest Clearing. Dead leaves cover the ground.
You see here: wolf meat (x3), wolf bone (x2), wolf hide.

> take wolf meat
You pick up wolf meat.

> cook wolf meat with fire
[Continues existing cooking verb: raw wolf-meat → cooked-wolf-meat mutation]
```

---

## 6. Testing Strategy

### Test Coverage (WAVE-1 deliverables)

**File:** `test/butchery/test-butcher-verb.lua`
- ✅ Resolve wolf corpse by noun
- ✅ `butcher wolf` without knife → error: "You need a knife"
- ✅ `butcher wolf` with knife → products appear
- ✅ Product instantiation verified (3 meat, 2 bone, 1 hide in room)
- ✅ Corpse removed (if `removes_corpse = true`)
- ✅ Verb aliases work: `carve wolf`, `skin wolf`
- ✅ Non-butcherable objects: `butcher rat` → error (rat is small-item, cookable, not reshaped)

**File:** `test/butchery/test-butchery-products.lua`
- ✅ Wolf products instantiate with correct properties
- ✅ Wolf-meat can be cooked (inherits cooked-rat-meat FSM pattern)
- ✅ Spider products instantiate (1 meat, 1 silk-bundle)
- ✅ Tool capability check: knife has "butchering" capability
- ✅ Time advances by 5 minutes during butchery

---

## 7. Implementation Checklist (WAVE-1)

- [ ] **Smithers:** Implement `verbs.butcher()` in `src/engine/verbs/crafting.lua`
  - Tool capability check: `player:find_tool_with_capability(requires_tool)`
  - Product instantiation: loop over `products` array
  - Time advancement: `context.game:advance_time(300)` for 5 minutes
  - Corpse removal: conditional deregister if `removes_corpse = true`

- [ ] **Flanders:** Add `butchery_products` to wolf `death_state` in `src/meta/creatures/wolf.lua`
  - 3 wolf-meat, 2 wolf-bone, 1 wolf-hide
  - Tool: "butchering"
  - Duration: "5 minutes"

- [ ] **Flanders:** Add `butchery_products` to spider `death_state` in `src/meta/creatures/spider.lua`
  - 1 spider-meat, 1 silk-bundle

- [ ] **Flanders:** Create `src/meta/objects/wolf-meat.lua` (small-item, cookable, nutrition 35)
  - FSM: `raw` → `cooked` (via cook verb)
  - Mutation target: `cooked-wolf-meat.lua`

- [ ] **Flanders:** Create `src/meta/objects/wolf-bone.lua` (small-item, improvised weapon, blunt force 3)

- [ ] **Flanders:** Create `src/meta/objects/wolf-hide.lua` (small-item, crafting material for armor)

- [ ] **Flanders:** Create `src/meta/objects/butcher-knife.lua` (tool, capabilities: `butchering`, `cutting`)

- [ ] **Smithers:** Update `src/engine/parser/embedding-index.json` with butcher verb aliases: `carve`, `skin`, `fillet`

- [ ] **Nelson:** Write `test/butchery/test-butcher-verb.lua` (~3 tests)

- [ ] **Nelson:** Write `test/butchery/test-butchery-products.lua` (~3 tests)

---

## 8. Related Systems

### Death Reshape (`creature-death-reshape.md`)
Butchery **depends on** death reshape. The corpse must exist as a registered instance with `death_state` metadata.

### Food System (`../../design/food-system.md`)
Butchery **feeds** the food system. Wolf-meat products are cookable (raw → cooked), follow spoilage FSM, provide nutrition.

### Tool Capability System (`../../design/tools-system.md`)
Butchery **relies on** tool capabilities. The knife must declare `capabilities = {"butchering", "cutting"}`.

### Time System (`../../design/time-system.md`)
Butchery **advances** game time. 5-minute duration creates strategic pressure: player must manage spoilage, candle burn, respawns.

### Registry & Instantiation (`src-structure.md`)
Butchery **uses** registry instantiation. Each product creates a new instance via `registry:instantiate(template_id)`.

---

## 9. Decision Rationale

### Why Capability-Based Tool Check?

**Not:** "Check if player has butcher-knife object"  
**Instead:** "Check if player has any tool with `butchering` capability"

**Rationale:**
- Supports tool variety without verb code changes
- Knife, cleaver, dagger all could have "butchering" capability
- Follows existing tool system (fire_source, cutting, etc.)
- Engine learns capability, not specific objects (Principle 8)

### Why Time Advancement (Option B)?

**Not:** "Instantaneous; player decides separately when to advance time"  
**Instead:** "Advance game time by 5 minutes during butchery"

**Rationale:**
- Butchery is a *time-consuming action* (Dwarf Fortress pattern)
- Creates strategic depth: must manage spoilage during butchery
- Consistent with existing `cook` verb (also advances time)
- Allows creatures to respawn while player is butchering
- Q1 decision in Phase 4 plan, approved by team

### Why Metadata Driven?

**Not:** Hard-code wolf → (3 meat, 2 bone, 1 hide)  
**Instead:** Declare products in `butchery_products` block

**Rationale:**
- Scales to 20+ creatures (Phase 4 scope)
- Enables experimentation without engine changes
- Follows Principle 8: "Engine executes metadata"
- Reduces verb handler complexity (generic, not creature-specific)

---

## 10. Known Limitations & Future Extensions

| Limitation | Status | Notes |
|-----------|--------|-------|
| Corpse must exist as furniture | By design | Small creatures (rat) are cookable directly, not butcherable. This is intentional. |
| No partial butchery | Deferred | "Butcher one cut" produces one meat. Full implementation in Phase 5+. |
| No tool wear/durability | Deferred | Phase 5+ scope: knife degrades with use. |
| No skill progression | Deferred | Phase 5+: butchery speed/yield improves with practice. |
| No creature-specific narration | Deferred | All creatures use same "carving" message. Phase 5+: custom narration per creature type. |

---

## 11. Glossary

| Term | Definition |
|------|-----------|
| **Butchery** | Act of processing a corpse into portable meat/bone/hide via knife tool |
| **Corpse** | Dead creature reshaped to furniture template via `reshape_instance()` |
| **Capability** | String identifier on a tool (e.g., "butchering", "fire_source") that a system checks for |
| **Product** | Result of butchery: individual meat, bone, hide object instantiated in room |
| **Death state** | Metadata block on creature defining post-death appearance, FSM, byproducts, butchery_products |

