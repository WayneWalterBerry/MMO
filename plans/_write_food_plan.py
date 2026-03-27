#!/usr/bin/env python3
"""Writes the updated food-system-plan.md"""
import os

content = []
content.append("""# Food System Design Plan

**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-07-14 (revised 2026-07-28)  
**Status:** Draft — revised with creature-food, cooking-craft, and edibility directives  
**Scope:** Level 1 food system, creature-to-food transformation, cooking craft gates, scaling path  
**Dependencies:** NPC system (rat hunger drives), effects pipeline, FSM, mutation engine, creature inventory system

---

## Revision History

| Date | Change | Source |
|------|--------|--------|
| 2026-07-14 | Initial draft: food objects, eat/drink, bait, spoilage FSM | CBG design analysis |
| 2026-07-28 | Added creature-to-food transformation, cooking-as-craft gate, edibility model, mutation chain, architecture decision (A+B hybrid), cooking verb spec, creature inventory cross-reference | Wayne directives + Bart architecture + Frink research |

---

## Table of Contents

1. [Design Philosophy](#1-design-philosophy)
2. [Architecture Decision: Mutation + Metadata Trait](#2-architecture-decision-mutation--metadata-trait)
3. [Edibility Model](#3-edibility-model)
4. [Food as Objects](#4-food-as-objects)
5. [Creature-to-Food Transformation (D-14)](#5-creature-to-food-transformation-d-14)
6. [Cooking as Craft Gate](#6-cooking-as-craft-gate)
7. [Cooking Verb Spec](#7-cooking-verb-spec)
8. [Mutation Chain: Live Rat to Dinner](#8-mutation-chain-live-rat-to-dinner)
9. [Food States (FSM)](#9-food-states-fsm)
10. [Sensory Integration](#10-sensory-integration)
11. [Food and Creatures (Bait)](#11-food-and-creatures-bait)
12. [Food and Health](#12-food-and-health)
13. [Creature Inventory Cross-Reference](#13-creature-inventory-cross-reference)
14. [First Food Items](#14-first-food-items)
15. [Verb Extensions Summary](#15-verb-extensions-summary)
16. [Scaling Path](#16-scaling-path)
17. [Open Questions](#17-open-questions)

---

## 1. Design Philosophy

### 1.1 The Valheim Model: Empowerment, Not Punishment

Food follows the Valheim philosophy: **eating is a buff, not eating is neutral**. The player never starves. There is no hunger meter ticking toward death. Food is a strategic resource — eating the right thing at the right time gives you an edge.

This is a deliberate rejection of the NetHack starvation clock. In a text adventure where inventory is limited to two hands, forcing players to carry rations would crowd out puzzle-critical items. Food should make players *want* to eat, not *have* to.

**Core principle:** Food is opportunity, not obligation.

### 1.2 Sensory-First Design

Food integrates directly with the existing sensory system (D-SENSORY). Every food item is, first and foremost, an object you can SMELL, FEEL, TASTE, and LOOK at. The senses are the player's primary tool for evaluating food safety:

| Sense | Role in Food System | Risk |
|-------|---------------------|------|
| **SMELL** | Safe identification — reveals freshness, cooking state, ingredients | None |
| **FEEL** | Texture identification — raw vs. cooked, spoiled vs. fresh, temperature | None |
| **TASTE** | Chemical identification — flavor, poison, quality | **Dangerous** |
| **LOOK** | Visual identification — color, mold, steam, char | Requires light |

The philosophy mirrors the poison bottle: SMELL warns you. TASTE commits you.

### 1.3 Mutation IS Cooking (D-14 Alignment)

When the player cooks a raw chicken leg over a fire, the engine does not set `chicken.cooked = true`. It rewrites `raw-chicken.lua` to `cooked-chicken.lua`. The code IS the state. The cooked chicken is a fundamentally different object with different sensory descriptions, different effects, different material properties.

This is the Prime Directive (D-14) applied to food. No state flags. Code mutation.

### 1.4 Dwarf Fortress Lessons, Simplified

From DF we take: food has identity (not generic rations), cooking transforms ingredients, spoilage creates urgency, food attracts creatures. From DF we leave behind: complex nutrition tracking, farming, meal quality ratings, brewing pipelines.

---

## 2. Architecture Decision: Mutation + Metadata Trait

**Decision Date:** 2026-07-28  
**Decided By:** Bart (Architect) with Wayne approval  
**References:** `bart-food-architecture.md`, `cbg-food-creature-design.md`

### The Problem

Objects and creatures are different systems (Principle 0). But food comes from BOTH. A bread roll is an object that is food. A dead rat is... what? When a creature crosses the alive-to-dead boundary, what architectural mechanism governs the transition to food?

### Options Evaluated

| Option | Mechanism | Verdict |
|--------|-----------|---------|
| **A: D-14 Mutation** | Creature dies, mutates to food object | **SELECTED** (for creature-to-object crossing) |
| **B: Metadata Trait** | `edible = true` + `food = {...}` on any object | **SELECTED** (for engine food detection) |
| **C: Multiple Templates** | `template = {"small-item", "food"}` array | **REJECTED** — loader rewrite, ordering ambiguity, diamond problem |
| **D: Food Template** | `template = "food"` extends small-item | **REJECTED** — duplication drift, not composable |

### The Decision: A + B Hybrid

**"Food" is a metadata trait, not a template.** Any object can be food by declaring `edible = true` and `food = {...}`. The `eat` verb checks this metadata. No new templates. No loader changes. No registry changes.

**Creature death uses D-14 mutation to cross the type boundary.** When a creature dies, the kill handler triggers `mutation.mutate()` to replace the creature with an inanimate object. The new object declares whatever traits it needs — including `edible = true` if the creature's meat is edible.

### Why Not Multiple Templates (Option C)?

Multiple templates solve the "IS-A food AND IS-A small-item" problem. But `food` is not a type — it is a property. A candle is not a "food-type" thing; it is a small-item that happens to be edible (if you are desperate enough). In real life, "edible" is not a category of object — it is a property that crosscuts all categories. A shoe is leather (edible in extremis). A candle is wax (edible). Grain is grain (edible). That is a trait, not a type.

Multi-template inheritance adds engine complexity (loader rewrite, merge-order ambiguity, validation rewrite) to solve a modeling error. Bart's analysis: "Option C adds HIGH complexity. Option B adds TRIVIAL complexity. Both achieve the same result."

### Why Not Food Template (Option D)?

A food template gives you default values for nutrition, spoilage, etc. But it creates an artificial category. What template does a candle stub you can eat in desperation use? `small-item`? `food`? It cannot be both without multi-template. If we get 20+ food items and need defaults, we revisit. Not before.

### Principle Compliance

| Principle | Compliance |
|-----------|-----------|
| **P0: Inanimate** | Dead creature mutates INTO an object. Boundary stays clean. |
| **P1: Code-derived** | Code defines new form. `.lua` file IS the definition. |
| **P8: Engine executes metadata** | `edible`, `food.nutrition`, `food.risk` — engine reads metadata, zero food-specific logic. |
| **D-14: Code IS state** | Creature-to-object is a code rewrite. Cooking is a code rewrite. |
| **P9: Material consistency** | `material = "flesh"` on meat objects. Material properties determine cook/cut behavior. |

---

## 3. Edibility Model

### Three Tiers of Edibility

Every potential food item in the game falls into one of three tiers. This is not engine logic — it is a convention enforced by object metadata.

| Tier | `edible` | `food.raw` | `cookable` | Examples | Player Experience |
|------|----------|-----------|-----------|----------|------------------|
| **Always-Edible** | `true` | `false` | `false` | Bread, cheese, dried herbs, fruit, wine | Eat immediately. Safe. Beneficial. |
| **Cook-Required** | `false` | `true` | `true` | Raw rat meat, raw chicken, grain | Cannot eat raw. `eat` verb rejects with hint. Must cook first. |
| **Never-Edible** | `false` | `false` | `false` | Bones, stones, wood, metal | Cannot eat. Generic rejection message. |

### Edibility Gating in the Eat Handler

The existing `eat` handler checks `obj.edible`. For cook-required food, we add a hint:

```lua
if obj.edible then
    -- existing eat logic (process food.effects, consume object)
elseif obj.cookable then
    -- Needs cooking first — give the player a hint
    print(obj.on_eat_reject or "You can't eat that raw. Try cooking it first.")
else
    print("You can't eat " .. (obj.name or "that") .. ".")
end
```

This is a 2-line addition to the existing eat handler. The `on_eat_reject` field lets each object provide a custom rejection message.

### The `food` Table Convention

Every food object declares a `food = {}` table in its metadata:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `category` | string | Yes | One of: `meat`, `grain`, `fruit`, `herb`, `dairy`, `drink` |
| `raw` | bool | No | If true, this food needs cooking before eating |
| `cook_to` | string | If raw | Object ID to mutate into when cooked |
| `spoil_time` | number | No | Ticks until spoilage. `0` or `nil` = never spoils |
| `nutrition` | number | No | Buff strength when eaten (0-100 scale) |
| `effects` | table | No | Array of effect tables applied on consumption |
| `bait_value` | number | No | How attractive to creatures (0-100) |
| `bait_target` | string | No | Creature category attracted (`rodent`, `insect`, etc.) |
| `risk` | string | No | Risk type when eating (`disease`, `poison`, etc.) |
| `risk_chance` | number | No | Probability of risk (0.0-1.0) |
| `on_eat_message` | string | No | Custom message when eaten |
""")

content.append("""---

## 4. Food as Objects

### 4.1 Template Pattern

Food items inherit from `small-item` and declare food-specific fields via the `edible` + `food = {...}` metadata trait pattern. No `food` template exists — food is a property, not a type.

```lua
return {
    guid = "{windows-guid}",
    template = "small-item",
    id = "raw-chicken",
    name = "a raw chicken leg",
    keywords = {"chicken", "chicken leg", "raw chicken", "meat"},
    description = "A plump, pale chicken leg with goosebumped skin.",

    size = 1,
    weight = 0.3,
    portable = true,
    material = "meat",

    -- EDIBILITY (Tier 2: Cook-Required)
    edible = false,
    cookable = true,
    on_eat_reject = "You can't eat this raw. You'd need to cook it first.",
    food = {
        category = "meat",
        raw = true,
        cook_to = "cooked-chicken",
        spoil_time = 60,
        nutrition = 0,
    },

    -- SENSORY (on_feel mandatory for darkness)
    on_feel = "Cold, clammy skin with tiny bumps. Slippery with moisture.",
    on_smell = "Raw poultry — faintly metallic, slightly sweet.",
    on_listen = "Silent.",
    on_taste = "Raw and bloody. Your stomach lurches.",

    -- COOKING (crafting recipe pattern from sew verb)
    crafting = {
        cook = {
            becomes = "cooked-chicken",
            requires_tool = "fire_source",
            message = "Fat sizzles and pops as the chicken cooks.",
            fail_message_no_tool = "You need a fire source to cook this.",
        },
    },
    mutations = {
        cook = {
            becomes = "cooked-chicken",
            requires_tool = "fire_source",
            message = "Fat sizzles and pops as the chicken cooks. The skin crisps and browns.",
        },
    },
}
```

### 4.2 New Materials

| Material | Density | Ignition | Hardness | Flexibility | Notes |
|----------|---------|----------|----------|-------------|-------|
| **meat** | 1050 | 300 | 1 | 0.6 | Raw animal flesh |
| **bread** | 350 | 250 | 2 | 0.3 | Baked grain product |
| **fruit** | 900 | 350 | 1 | 0.5 | Plant fruit (Phase 2) |
| **cheese** | 1100 | 350 | 3 | 0.4 | Dairy solid (Phase 2) |

---

## 5. Creature-to-Food Transformation (D-14)

**Source:** Wayne directive (2026-03-27): *"The engine should allow creature instances to completely change into an object instance on death. The creature .lua file would know how to rewrite itself into an object — the mutation target is declared in the creature's own metadata."*

### The Mechanism

When a creature's health reaches zero, the engine triggers a mutation declared in the creature's own `.lua` file. The creature literally becomes a different object. The engine executes this generically — no creature-specific code.

```
rat.lua (creature, alive)
  -> [health_zero] ->
      rat.lua dead state (brief moment for death narration)
        -> [mutation] ->
            dead-rat.lua (object, small-item, edible, container)
```

### Creature Declares Its Own Death Form

```lua
-- In rat.lua (creature definition)
mutations = {
    die = {
        becomes = "dead-rat",
        message = "The rat shudders once and goes still.",
        transfer_contents = true,  -- stolen items go into corpse
    },
},
```

The engine reads `mutations.die`, calls `mutation.mutate()`, and the creature is replaced. No rat-specific engine code. Pure Principle 8.

### What Happens Mechanically

1. Rat takes lethal damage, health reaches zero
2. Engine checks `rat.mutations.die` — it exists
3. `mutation.mutate(reg, ldr, "rat", "dead-rat", templates)` called
4. Mutation loads `dead-rat.lua`, resolves `template = "small-item"`
5. Preserves `location` and `container` — dead rat stays where live rat was
6. Registry entry at key "rat" is replaced — now points to dead-rat table
7. Old creature data (behavior, drives, reactions, movement) is gone
8. Object is now a portable small-item with `edible = true`
""")

content.append("""### The Dead Rat Object

```lua
-- src/meta/objects/dead-rat.lua
return {
    guid = "{generate-guid}",
    template = "small-item",
    id = "dead-rat",
    name = "a dead rat",
    keywords = {"dead rat", "rat", "rat corpse", "corpse", "carcass"},
    description = "A dead rat lies on its side, legs splayed. Its matted brown "
        .. "fur is darkened with blood. Beady black eyes stare at nothing.",

    size = 1,
    weight = 0.3,
    portable = true,
    material = "flesh",
    container = true,
    capacity = 1,

    -- Edible raw (risky) OR cookable into cooked-rat-meat
    edible = true,
    cookable = true,
    food = {
        category = "meat",
        raw = true,
        cook_to = "cooked-rat-meat",
        nutrition = 3,
        risk = "disease",
        risk_chance = 0.4,
        spoil_time = 40,
        bait_value = 85,
        bait_target = "rodent",
        on_eat_message = "You tear into the raw rat flesh. It's gamey and foul.",
    },

    on_feel = "Cooling fur over a limp body. The ribcage is thin — you can "
           .. "feel the tiny bones beneath the skin.",
    on_smell = "Blood and musk. The sharp copper of fresh death.",
    on_listen = "Nothing. Absolutely nothing.",
    on_taste = "Fur and blood. Raw and metallic. Your stomach clenches.",
    room_presence = "A dead rat lies crumpled on the floor.",

    crafting = {
        cook = {
            becomes = "cooked-rat-meat",
            requires_tool = "fire_source",
            message = "You hold the rat over the flames. The fur singes away "
                   .. "and the flesh darkens.",
            fail_message_no_tool = "You need a fire source to cook this.",
        },
    },
    mutations = {
        cook = {
            becomes = "cooked-rat-meat",
            requires_tool = "fire_source",
            message = "You cook the dead rat over the flames.",
        },
    },

    -- Spoilage FSM
    initial_state = "fresh",
    _state = "fresh",
    states = {
        fresh = {
            description = "A dead rat, freshly killed.",
            room_presence = "A dead rat lies crumpled on the floor.",
        },
        bloated = {
            description = "A dead rat, belly distended with gas.",
            room_presence = "A bloated rat carcass lies here.",
            on_smell = "Sweet, sickly decay.",
            food = { nutrition = 0, bait_value = 95,
                effects = {
                    { type = "inflict_injury", injury_type = "food-poisoning", damage = 5 },
                    { type = "add_status", status = "nauseated", duration = 15 },
                },
            },
        },
        rotten = {
            description = "A rotting rat. Maggots writhe in the exposed flesh.",
            room_presence = "A rotting rat carcass festers here.",
            on_smell = "Overwhelming putrefaction.",
            food = { nutrition = 0, bait_value = 100,
                effects = {
                    { type = "inflict_injury", injury_type = "food-poisoning", damage = 10 },
                },
            },
        },
        bones = {
            description = "A tiny rodent skeleton, picked clean.",
            edible = false,
            food = nil,
        },
    },
    transitions = {
        { from = "fresh", to = "bloated", verb = "_tick", condition = "timer",
          timer = 40, message = "The dead rat has begun to bloat." },
        { from = "bloated", to = "rotten", verb = "_tick", condition = "timer",
          timer = 40, message = "The rat carcass is rotting." },
        { from = "rotten", to = "bones", verb = "_tick", condition = "timer",
          timer = 60, message = "The rat has decayed to bare bones." },
    },
}
```

### Why Mutation, Not FSM Dead State

The team rejected keeping the creature in a `dead` FSM state with `edible = true`:

1. **Principle 0 violation** — A creature with `animate = false` that you can eat and carry is functionally an object. Architecture should reflect reality.
2. **No independent FSM** — Bolting spoilage onto a creature FSM mixes behavioral and material states.
3. **No containment** — Dead rat needs to BE a container for stolen items. Mutation to a container-capable object handles this.

---

## 6. Cooking as Craft Gate

**Source:** Wayne directive (2026-03-27): *"Some food can't be eaten without cooking. Raw flesh requires cooking (craft) to become edible meat. Cooking is a CRAFTING operation that gates edibility."*

### The Model

Some food is inedible raw. The `cook` verb + a `fire_source` tool triggers a mutation to the cooked version. The raw object declares `edible = false` + `cookable = true` + `food.raw = true` + `food.cook_to = "cooked-form"`. The eat handler rejects raw food with a hint.

### Cooking Uses Mutation, Not FSM

Cooking transforms `raw-rat-meat.lua` into `cooked-rat-meat.lua` via mutation (D-14):

1. **Cooked meat is a fundamentally different object** — different name, description, sensory properties, nutrition, material behavior, keywords.
2. **D-14 Prime Directive** — the code is rewritten. The cooked-meat `.lua` file has completely different content.
3. **FSM is wrong here** — FSM is for objects cycling through states while remaining the same object (candle: unlit-to-lit). Raw-to-cooked is a material transformation.
4. **Precedent** — the existing `sew` verb in `crafting.lua` already does this via `recipe.becomes`.

**Exception:** Post-cooking degradation uses FSM: `fresh -> cooling -> cold -> spoiled`. Same object degrading = legitimate FSM.

### Cooking Uses the `crafting` Field Pattern

Same convention as `sew`: the object declares `crafting.cook` with the recipe.

### Fire Source Scope

Cooking requires `fire_source` capability anywhere visible — hands, room, or surfaces. The existing `find_visible_tool(ctx, capability)` already handles this. Fire sources are often environmental (fireplace, wall torch), so room-scope search is correct.

| Object | Provides | Status |
|--------|----------|--------|
| match (lit) | `fire_source` | Exists |
| candle (lit) | `fire_source` | Exists |
| oil-lantern (lit) | `fire_source` | Exists |
| torch (lit) | `fire_source` | Exists |
| kitchen hearth | `fire_source` (when lit) | **Needed for Level 1** |

---

## 7. Cooking Verb Spec

### Verb: `cook`

**Aliases:** `roast`, `bake`, `grill`  
**File:** `src/engine/verbs/crafting.lua` (follows the `sew` pattern)  
**Requires:** Food in hand + `fire_source` in visible scope

```lua
handlers["cook"] = function(ctx, noun)
    if noun == "" then
        print("Cook what? (Try: cook <food>)")
        return
    end

    local food = find_in_inventory(ctx, noun)
    if not food then
        food = find_visible(ctx, noun)
    end
    if not food then
        err_not_found(ctx)
        return
    end

    if not food.crafting or not food.crafting.cook then
        if not food.cookable then
            print("You can't cook " .. (food.name or "that") .. ".")
        else
            print("You're not sure how to cook " .. (food.name or "that") .. ".")
        end
        return
    end

    local recipe = food.crafting.cook

    local fire = find_visible_tool(ctx, recipe.requires_tool or "fire_source")
    if not fire then
        fire = find_tool_in_inventory(ctx, recipe.requires_tool or "fire_source")
    end
    if not fire then
        print(recipe.fail_message_no_tool or "You need a fire source to cook.")
        return
    end

    local ok = perform_mutation(ctx, food, recipe)
    if not ok then
        print("Something goes wrong — the food burns to ash.")
        return
    end

    consume_tool_charge(ctx, fire)
    print(recipe.message or ("You cook " .. (food.name or "it") .. " over the flames."))
end

handlers["roast"] = handlers["cook"]
handlers["bake"] = handlers["cook"]
handlers["grill"] = handlers["cook"]
```

### Why a Dedicated Verb

Players type `cook meat`, `bake bread`, `roast rat` — natural language verbs. The `sew` pattern proves the model: each craft type gets its own handler. The recipe on the object controls output, not the verb name.
""")

content.append("""---

## 8. Mutation Chain: Live Rat to Dinner

This is the full D-14 mutation chain. Four stages, four distinct `.lua` files, four complete sensory sets.

```
rat.lua (creature, alive, animate=true)
  -> [kill: health reaches 0]
    -> dead-rat.lua (object, small-item, edible raw but risky)
      -> [cook: fire_source required]
        -> cooked-rat-meat.lua (object, small-item, safe, nutritious)
```

### Stage 1: Living Rat (creature)

```lua
-- src/meta/creatures/rat.lua (relevant excerpt)
return {
    guid = "{071e73f6-...}",
    template = "creature",
    id = "rat",
    name = "a brown rat",
    animate = true,
    -- ... behavior, drives, reactions ...

    mutations = {
        die = {
            becomes = "dead-rat",
            message = "The rat shudders once and goes still.",
            transfer_contents = true,
        },
    },
}
```

### Stage 2: Dead Rat (edible object, risky)

See full definition in section 5. Key: `edible = true`, `food.raw = true`, `food.cook_to = "cooked-rat-meat"`, spoilage FSM fresh-to-bones.

### Stage 3: Cooked Rat Meat (safe food)

```lua
-- src/meta/objects/cooked-rat-meat.lua
return {
    guid = "{generate-guid}",
    template = "small-item",
    id = "cooked-rat-meat",
    name = "a piece of cooked rat meat",
    keywords = {"rat meat", "cooked meat", "meat", "cooked rat meat", "food"},
    description = "A charred chunk of rat meat, browned and crispy at the edges. "
        .. "Not exactly a feast, but it smells better than it did raw.",

    material = "flesh",
    size = 1,
    weight = 0.15,
    portable = true,

    edible = true,
    cookable = false,
    food = {
        category = "meat",
        raw = false,
        nutrition = 15,
        spoil_time = 120,
        effects = {
            { type = "narrate", message = "Tough and gamey, but it fills your stomach." },
            { type = "mutate", target = "player", field = "health", value = 3, op = "add" },
        },
    },

    on_feel = "Warm and firm. Slightly crispy surface, dense and fibrous inside.",
    on_smell = "Charred meat — smoky, savory, with an undertone of gaminess.",
    on_taste = "Tough and gamey, but edible. The char adds a bitter smokiness.",
    on_listen = "Faint crackling as it cools.",
    room_presence = "A piece of cooked meat sits here, still faintly steaming.",

    initial_state = "fresh",
    _state = "fresh",
    states = {
        fresh = {
            description = "A piece of cooked rat meat, still warm.",
        },
        cold = {
            description = "Cold cooked rat meat. Congealed grease coats the surface.",
            on_smell = "Cold grease and old meat.",
            food = { nutrition = 10 },
        },
        spoiled = {
            description = "Rotten meat. Grey-green mold covers the surface.",
            on_smell = "Foul. Rotting meat and mold.",
            edible = false,
        },
    },
    transitions = {
        { from = "fresh", to = "cold", verb = "_tick", condition = "timer", timer = 30 },
        { from = "cold", to = "spoiled", verb = "_tick", condition = "timer", timer = 90 },
    },
}
```

### Grain-to-Flatbread Chain (Baking Example)

```lua
-- src/meta/objects/grain-handful.lua
return {
    guid = "{generate-guid}",
    template = "small-item",
    id = "grain-handful",
    name = "a handful of barley grain",
    keywords = {"grain", "barley", "kernels"},
    description = "A handful of dry barley kernels.",

    edible = false,
    cookable = true,
    on_eat_reject = "Raw grain is too hard to chew. You'd need to grind and bake it.",

    on_feel = "Dry, hard little kernels that shift between your fingers.",
    on_smell = "Dusty, faintly nutty.",

    crafting = {
        cook = {
            becomes = "flatbread",
            requires_tool = "fire_source",
            message = "You spread the grain on a flat stone near the fire. "
                   .. "The kernels soften and fuse into a crude flatbread.",
            fail_message_no_tool = "You need a fire source to bake this.",
        },
    },
    mutations = {
        cook = {
            becomes = "flatbread",
            requires_tool = "fire_source",
            message = "You bake the grain into a rough flatbread.",
        },
    },
}
```

### Player Experience Arc

```
> kill rat
You swing the brass candlestick. The rat squeals and crumples.
A dead rat lies crumpled on the floor.

> smell rat
Blood and musk. The sharp copper of fresh death.

> cook rat
You hold the rat over the flames. The fur singes away and the 
flesh darkens. The smell shifts from death to dinner.

> eat rat meat
Tough and gamey, but it fills your stomach.
[Nutrition: +15] [Healing: +3 HP]
```

---

## 9. Food States (FSM)

### 9.1 The Spoilage Lifecycle

Food objects use the existing FSM engine for state progression. No new engine code.

```
    +----------+    cook     +----------+
    |   FRESH  |----------->|  COOKED  |
    |  (raw)   |            |          |
    +----+-----+            +----+-----+
         |                       |
         | spoil_time            | spoil_time (longer)
         v                       v
    +----------+            +----------+
    | SPOILED  |            | SPOILED  |
    |  (raw)   |            | (cooked) |
    +----------+            +----------+
```

Cooking resets and extends the spoilage timer. Historically accurate. Strategically motivating.

### 9.2 Spoilage Timers

| Food | Fresh to Spoiled | Cooked to Spoiled | Notes |
|------|-----------------|-------------------|-------|
| Raw meat | 60 ticks | 120 ticks (cooked) | Cooking doubles shelf life |
| Bread | 120 to stale, 240 to moldy | N/A | Does not cook further |
| Cheese | 200 to aged | N/A | Aging *improves* it |
| Fruit | 80 ticks | N/A | Spoils relatively fast |
| Dried herbs | Never | N/A | Already preserved |

---

## 10. Sensory Integration

### 10.1 The Sensory Funnel for Food

```
SMELL (safe)       -> "Something smells like roasted meat nearby."
FEEL (safe)        -> "Warm, firm, oily surface. A cooked piece of meat."
LOOK (needs light) -> "A charred chicken leg on a wooden plate."
TASTE (risky!)     -> "Rich, smoky." OR: "Bitter, WRONG — *cough*"
```

A cautious player can identify any food item without risk using SMELL + FEEL.

### 10.2 State-Dependent Sensory Text

| State | SMELL | FEEL | TASTE |
|-------|-------|------|-------|
| **Fresh (raw)** | "Raw poultry — faintly metallic" | "Cold, clammy, bumpy skin" | "Raw and bloody" (nausea) |
| **Cooked** | "Roasted meat — smoky, savory" | "Hot, crispy, firm flesh" | "Rich, well-cooked" |
| **Spoiled** | "Rotting meat — eyes water" | "Slimy, warm, skin slides" | "IMMEDIATE GAG" (poisoning) |
""")

content.append("""---

## 11. Food and Creatures (Bait)

### 11.1 The Bait Mechanic

Food objects declare `food.bait_value` (0-100). Creatures within smell range evaluate food based on hunger drive.

| Food | Bait Value | Target | Notes |
|------|-----------|--------|-------|
| Raw meat | 80 | rodent, carnivore | Strong smell |
| Cooked meat | 60 | rodent, carnivore | Less pungent |
| Cheese | 90 | rodent | Classic bait |
| Bread | 40 | rodent, omnivore | Mild |
| Spoiled food | 95 | rodent, insect | Strongest bait |
| Dried herbs | 5 | none | Almost no value |

### 11.2 Emergent Bait Behaviors

These emerge from the drive system, not scripts:
- **Rat follows food trail** — Drop meat, rat navigates toward it
- **Baited trap** — Put cheese in trap, rat investigates, trap springs
- **Distraction** — Drop food in hallway to lure rat, sneak past
- **Spoiled food attracts pests** — Dropped food spoils, becomes stronger bait
- **Feeding calms creature** — Drop food near hungry rat, rat eats, fear drops

---

## 12. Food and Health

### 12.1 Healing Through Food

| Food Quality | Healing | Duration | Example |
|-------------|---------|----------|---------|
| Raw edible | 0 | — | Raw fruit (safe but no benefit) |
| Cooked simple | 3-5 HP | Instant | Roasted chicken, cooked rat |
| Cooked quality | 8-12 HP | Instant | Well-prepared meal (future) |
| Medicinal herb | 0 HP + cure | Removes status | Mint tea cures nausea |
| Spoiled | -5 to -10 HP | Over time | Food poisoning |

### 12.2 Food Poisoning

New injury type: `food-poisoning` in `src/meta/injuries/`

```lua
return {
    id = "food-poisoning",
    name = "food poisoning",
    description = "Cramps, nausea, and cold sweats from eating tainted food.",
    severity = "moderate",
    duration = 20,
    effects = {
        { type = "add_status", status = "nauseated", duration = 12 },
        { type = "add_status", status = "weakened", duration = 20 },
    },
    on_feel = "Your guts twist and clench.",
    on_recovery = "The worst has passed. Your stomach still feels fragile.",
}
```

### 12.3 Taste-Risk Spectrum

| Action | Risk | Reward |
|--------|------|--------|
| SMELL food | None | Identifies freshness, cooking state |
| FEEL food | None | Identifies temperature, texture |
| TASTE food | Low-Medium | Confirms identity; spoiled food causes nausea |
| EAT food | Medium-High | Full nutrition/healing; spoiled = food poisoning |

---

## 13. Creature Inventory Cross-Reference

**Reference:** `plans/creature-inventory-plan.md`

Dead creatures that are containers can drop loot AND can be food. These are independent traits on the corpse object.

### The Intersection

When a creature dies and mutates to a corpse object:
- **If the creature had inventory**, the corpse is a container holding loot (`container = true`, `transfer_contents = true`)
- **If the creature's flesh is edible**, the corpse has `edible = true` and `food = {...}`
- These are independent metadata traits. A corpse can be both, either, or neither.

### Examples

| Creature | Drops Loot? | Is Edible? | Corpse Object |
|----------|-------------|-----------|---------------|
| **Rat** | No (rats carry nothing) | **Yes** | `dead-rat.lua`: edible, no loot |
| **Skeleton** | **Yes** — sword, armor, coins | No — bones are not food | `skeleton-remains.lua`: container with loot, not edible |
| **Thieving Rat** | **Yes** — stolen cheese | **Yes** | `dead-rat.lua`: container with loot AND edible |
| **Spider** | No | No — chitin is not meat | `dead-spider.lua`: not edible |

### Design Rule

The creature declares `mutations.die.becomes` and `mutations.die.transfer_contents`. The corpse object declares `container` and `edible` independently. No special "loot-food" engine logic needed — existing containment system handles loot, existing eat verb handles food.

---

## 14. First Food Items

### Level 1 Food Roster (7 items)

| # | Item | Teaches | Edibility Tier |
|---|------|---------|---------------|
| 1 | Bread roll | Basic eating, safe food | Always-Edible |
| 2 | Raw chicken leg | Cooking requirement, raw danger | Cook-Required |
| 3 | Cooked chicken leg | Reward for cooking | Always-Edible (via mutation) |
| 4 | Wedge of cheese | Best rat bait, aging mechanic | Always-Edible |
| 5 | Dried mint leaves | Medicinal herb, nausea cure | Always-Edible |
| 6 | Wrinkled apple | Fruit category, spoilage | Always-Edible |
| 7 | Waterskin | Drink mechanic, refillable | Always-Drinkable |

### Placement in Level 1

| Item | Room | Location | Discovery |
|------|------|----------|-----------|
| Bread roll | Kitchen / Pantry | On shelf | SMELL bread from hallway |
| Raw chicken | Kitchen | Hanging from hook | SMELL raw meat |
| Cheese wedge | Cellar / Pantry | On shelf | SMELL sharp cheese |
| Dried mint | Bedroom / Study | In drawer | FEEL papery bundle |
| Wrinkled apple | Kitchen | On table | FEEL round fruit |
| Waterskin | Bedroom | On nightstand | LISTEN sloshing |
| Cooked chicken | N/A | Created by cooking | — |

---

## 15. Verb Extensions Summary

| Verb | Status | Aliases | Notes |
|------|--------|---------|-------|
| `eat` | **Exists** — needs cookable check + effects | consume, devour | Add cookable rejection, food.effects pipeline |
| `drink` | **Exists** — works as-is | quaff, sip | FSM-driven |
| `cook` | **New** | roast, bake, grill | Mutation-based, requires fire_source |
| `pour` | **Exists** | splash, spill | For liquids |
| `fill` | **Exists** (FSM transition) | — | Waterskin refill |
| `feed` | **Not needed** | — | Emerges from drop/give + creature AI |

---

## 16. Scaling Path

### Phase 1: Proof of Concept (Current Target)

7 food items, cook verb, eat effects, spoilage FSM, edibility gating.

| Task | Effort | Owner |
|------|--------|-------|
| Create 7 food object `.lua` files | Medium | Flanders |
| Add `cook` verb handler + aliases | Small | Smithers |
| Add `cookable` check to eat handler (2 lines) | Small | Smithers |
| Add effects processing to eat verb | Small | Smithers |
| Create `food-poisoning` injury type | Small | Flanders |
| Create meat material | Small | Flanders |
| Add fire source furniture (kitchen hearth) | Medium | Moe |
| Place food items in Level 1 rooms | Small | Moe |
| Tests: cook, eat raw, eat cooked, spoilage | Medium | Nelson |

### Phase 2: Creature Integration

| Task | Dependencies |
|------|-------------|
| Wire kill handler to call `mutation.mutate` on `mutations.die` | Creature system |
| Create dead-rat, cooked-rat-meat objects | Phase 1 food objects |
| Emit `food_present` stimulus on food drop | NPC stimulus system |
| Creature hunger drive evaluates nearby food | NPC drive system |
| Rat trap with bait slot | Trap object design |

### Phase 3: Expanded Recipes

Multi-ingredient cooking, `butcher` verb (knife + corpse = meat + bones), brewing, preservation.

### Phase 4: World Economy

Food trade, tavern meals, cooking skill, food quality tiers.
""")

content.append("""---

## 17. Open Questions

### From Original Plan (still open)

**Q1: Can a candle cook food?**  
Recommendation: No. Candles cast light but do not cook. Only dedicated fire sources have `fire_source` capability.

**Q2: Does eating raw fruit cause nausea?**  
Recommendation: Category-based. Raw fruit, herbs, cheese, bread = safe. Raw meat = nausea. Spoiled anything = food poisoning.

**Q3: Should hunger exist as a player stat?**  
Recommendation: Defer. Start with Valheim model (no hunger stat). Revisit after playtesting.

**Q4: How many fire sources in Level 1?**  
Recommendation: 1 fire source (kitchen fireplace). Player brings food to fire. Classic adventure loop.

**Q5: Can creatures eat food the player has dropped?**  
Recommendation: Yes, with delay. Creature must be hungry enough and unafraid.

**Q6: Should cooking require both hands free?**  
Recommendation: Cooking at fire-source furniture requires only food in one hand. The fire is a room fixture.

### New Questions (from tonight's directives)

**Q7: Should corpse mutation happen instantly on death, or after a delay?**  
Recommendation: Instant. The `dead` state exists for the death narration. Corpse object takes over from there.

**Q8: Should ALL creatures drop corpses, or only small ones?**  
Recommendation: Size-based. Tiny/small creatures = portable corpse. Medium+ = non-portable corpse (furniture-sized).

**Q9: Can you cook a whole corpse without butchering?**  
Recommendation: For V1, yes — small creatures like rats can be cooked whole. Larger creatures require butchery first (Phase 3).

**Q10: Dead rat as bait for other rats?**  
Recommendation: Yes. Rats are cannibalistic scavengers. Dead rat `bait_value = 85` attracts live rats.

**Q11: Grain cooking — does it need water?**  
Recommendation: V1: grain + fire = flatbread (simple). Phase 3: grain + fire + water = porridge (multi-ingredient).

**Q12: Wine as food?**  
Recommendation: Yes. Add `food = { category = "drink", nutrition = 5, effects = { add_status("tipsy", 15) } }` to wine's open state.

---

## Appendix A: Engine Readiness Assessment

| Engine Feature | Status | Food Usage |
|---------------|--------|-----------|
| `edible` flag + `eat` verb | Exists | Consumption pipeline |
| `drink` verb + FSM transitions | Exists | Liquid consumption |
| Sensory hooks (`on_taste`, `on_smell`) | Exists | Food identification |
| `on_taste_effect` | Exists | Taste-risk mechanic |
| Effects pipeline | Exists | Food effects |
| FSM timer-driven transitions | Exists | Spoilage lifecycle |
| Mutation hot-swap | Exists | Cooking + death transformation |
| Material registry | Exists | Food materials |
| Creature drives (hunger, fear) | Designed | Bait mechanic |
| `cook` verb | **Needs creation** | Cooking action |
| `food.effects` processing in `eat` | **Needs addition** | Eat-time effects |
| `cookable` check in `eat` | **Needs addition** | Raw food rejection hint |
| `food-poisoning` injury type | **Needs creation** | Spoiled food consequence |
| Food materials (meat, bread) | **Needs creation** | Material properties |
| Fire source furniture | **Needs creation** | Cooking location |

**Assessment: Engine is approximately 80% ready.** Core pipelines exist. Remaining work is content and minor verb additions.

---

## Appendix B: Cross-References

| Document | Relevance |
|----------|-----------|
| `docs/design/design-directives.md` | D-14 (mutation), sensory system, consumables |
| `docs/architecture/objects/core-principles.md` | Principles 0, 1, 3, 6, 8, 9 |
| `plans/npc-system-plan.md` | Rat hunger drive, smell awareness, bait |
| `plans/creature-inventory-plan.md` | Loot drops, creature death mutation, container corpses |
| `docs/design/tools-system.md` | fire_source capability, compound tools |
| `.squad/decisions/inbox/bart-food-architecture.md` | Option A+B hybrid decision |
| `.squad/decisions/inbox/bart-cooking-craft-architecture.md` | Cook verb spec, crafting recipe pattern |
| `.squad/decisions/inbox/cbg-food-creature-design.md` | Competitor analysis, sensory escalation |
| `.squad/decisions/inbox/frink-cooking-gates-research.md` | 7-game survey of cooking mechanics |
| `.squad/decisions/inbox/copilot-directive-creature-self-mutation.md` | Wayne's D-14 creature mutation directive |
| `.squad/decisions/inbox/copilot-directive-cooking-craft.md` | Wayne's cooking-as-craft directive |

---

## Appendix C: Impact by Squad Member

| Member | Role | Work Required |
|--------|------|---------------|
| **Flanders** | Object definitions | Create dead-rat, cooked-rat-meat, flatbread, food-poisoning injury, meat material |
| **Moe** | Room definitions | Wire kitchen hearth, place food items in Level 1 rooms |
| **Smithers** | Parser/verbs | Add `cook`/`roast`/`bake`/`grill` handler; add `cookable` check + `food.effects` to eat handler |
| **Nelson** | QA | Tests: cook with fire, cook without fire, eat raw, eat cooked, spoilage FSM |
| **Sideshow Bob** | Puzzles | Design cooking puzzles (rat bait, food trade, hunger pressure) |
| **Bart** | Architecture | Wire kill handler to call `mutation.mutate` on creature death (Phase 2) |
""")

output_path = r"C:\Users\wayneb\source\repos\MMO\plans\food-system-plan.md"
full_content = "\n".join(content)
with open(output_path, "w", encoding="utf-8") as f:
    f.write(full_content)

size_kb = len(full_content.encode("utf-8")) / 1024
print(f"Written {size_kb:.1f} KB to {output_path}")
