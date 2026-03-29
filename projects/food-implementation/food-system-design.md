# Food System Design Plan

**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-07-14 (revised 2026-07-28)  
**Status:** ✅ PoC COMPLETE — cheese + bread created, eat/drink verbs implemented, bait mechanic done (Phase 2 WAVE-5). Full design remains draft.  
**Scope:** Level 1 food system, creature-to-food transformation, cooking craft gates, scaling path  
**Dependencies:** NPC system, effects pipeline, FSM, mutation engine, creature inventory system

---

## Revision History

| Date | Change | Source |
|------|--------|--------|
| 2026-07-14 | Initial draft: food objects, eat/drink, bait, spoilage FSM | CBG design analysis |
| 2026-07-28 | Creature-to-food transformation, cooking-as-craft gate, edibility model, mutation chain, architecture decision (A+B hybrid), cooking verb spec, creature inventory cross-reference | Wayne directives + Bart architecture + Frink research |

---

## Table of Contents

1. [Design Philosophy](#1-design-philosophy)
2. [Architecture Decision: Mutation + Metadata Trait](#2-architecture-decision)
3. [Edibility Model](#3-edibility-model)
4. [Food as Objects](#4-food-as-objects)
5. [Creature-to-Food Transformation (D-14)](#5-creature-to-food-transformation)
6. [Cooking as Craft Gate](#6-cooking-as-craft-gate)
7. [Cooking Verb Spec](#7-cooking-verb-spec)
8. [Mutation Chain: Live Rat to Dinner](#8-mutation-chain)
9. [Food States (FSM)](#9-food-states-fsm)
10. [Sensory Integration](#10-sensory-integration)
11. [Food and Creatures (Bait)](#11-bait)
12. [Food and Health](#12-food-and-health)
13. [Creature Inventory Cross-Reference](#13-creature-inventory)
14. [First Food Items](#14-first-food-items)
15. [Verb Extensions Summary](#15-verb-extensions)
16. [Scaling Path](#16-scaling-path)
17. [Open Questions](#17-open-questions)

---

## 1. Design Philosophy

### 1.1 The Valheim Model: Empowerment, Not Punishment

Food follows the Valheim philosophy: **eating is a buff, not eating is neutral**. No hunger meter. No starvation clock. In a two-hand inventory system, forcing ration-carrying crowds out puzzle items.

**Core principle:** Food is opportunity, not obligation.

### 1.2 Sensory-First Design

Every food item is an object you SMELL, FEEL, TASTE, and LOOK at. Senses are the player's primary tool for evaluating food safety:

| Sense | Role | Risk |
|-------|------|------|
| **SMELL** | Freshness, cooking state | None |
| **FEEL** | Raw vs. cooked, temperature | None |
| **TASTE** | Flavor, poison, quality | **Dangerous** |
| **LOOK** | Color, mold, steam | Requires light |

SMELL warns you. TASTE commits you.

### 1.3 Mutation IS Cooking (D-14)

When the player cooks raw chicken over fire, the engine rewrites `raw-chicken.lua` to `cooked-chicken.lua`. The code IS the state. No state flags. Code mutation. This is the Prime Directive applied to food.

### 1.4 Dwarf Fortress Lessons, Simplified

From DF we take: food identity, cooking transforms, spoilage urgency, food attracts creatures. We leave behind: nutrition tracking, farming, meal quality ratings, brewing.

---

## 2. Architecture Decision: Mutation + Metadata Trait

**Decided:** 2026-07-28 | **By:** Bart (Architect) | **Refs:** `bart-food-architecture.md`, `cbg-food-creature-design.md`

### The Problem

Objects and creatures are different systems (Principle 0). Food comes from BOTH. A bread roll is an object. A dead rat is... what?

### Options Evaluated

| Option | Mechanism | Verdict |
|--------|-----------|---------|
| **A: D-14 Mutation** | Creature dies, mutates to food object | **SELECTED** (creature-to-object) |
| **B: Metadata Trait** | `edible = true` + `food = {...}` on any object | **SELECTED** (engine detection) |
| **C: Multiple Templates** | `template = {"small-item", "food"}` | **REJECTED** — loader rewrite, diamond problem |
| **D: Food Template** | `template = "food"` extends small-item | **REJECTED** — duplication, not composable |

### The Decision: A + B Hybrid

**"Food" is a metadata trait, not a template.** Any object can be food by declaring `edible = true` and `food = {...}`. No new templates. No loader changes.

**Creature death uses D-14 mutation.** Kill handler triggers `mutation.mutate()` to replace the creature with an inanimate object that declares `edible = true` if appropriate.

### Why Not C or D?

"Food" is not a type -- it is a property. "Edible" crosscuts all categories. Multi-template inheritance adds HIGH engine complexity to solve a modeling error. A food template creates artificial categories and cannot compose. Bart's analysis: "Option B adds TRIVIAL complexity. Option C adds HIGH. Same result."

### Principle Compliance

| Principle | Compliance |
|-----------|-----------|
| **P0** | Dead creature mutates INTO an object. Boundary stays clean. |
| **P8** | Engine reads `edible`, `food.nutrition` metadata. Zero food-specific logic. |
| **D-14** | Creature-to-object = code rewrite. Cooking = code rewrite. |
| **P9** | `material = "flesh"` on meat. Material properties govern cook/cut. |

---

## 3. Edibility Model

### Three Tiers

| Tier | `edible` | `cookable` | Examples | Experience |
|------|----------|-----------|----------|------------|
| **Always-Edible** | `true` | `false` | Bread, cheese, herbs, fruit, wine | Eat immediately. Safe. |
| **Cook-Required** | `false` | `true` | Raw meat, raw chicken, grain | `eat` rejects with hint. Must cook. |
| **Never-Edible** | `false` | `false` | Bones, stones, wood, metal | Generic rejection. |

### Eat Handler Change (2 lines)

```lua
if obj.edible then
    -- existing eat logic
elseif obj.cookable then
    print(obj.on_eat_reject or "You can't eat that raw. Try cooking it first.")
else
    print("You can't eat " .. (obj.name or "that") .. ".")
end
```

### The `food` Table Convention

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `category` | string | Yes | `meat`, `grain`, `fruit`, `herb`, `dairy`, `drink` |
| `raw` | bool | No | Needs cooking before eating |
| `cook_to` | string | If raw | Mutation target when cooked |
| `spoil_time` | number | No | Ticks until spoilage (`0` = never) |
| `nutrition` | number | No | Buff strength (0-100) |
| `effects` | table | No | Effect tables on consumption |
| `bait_value` | number | No | Creature attractiveness (0-100) |
| `bait_target` | string | No | `rodent`, `insect`, etc. |
| `risk` | string | No | `disease`, `poison`, etc. |
| `risk_chance` | number | No | Probability (0.0-1.0) |
| `on_eat_message` | string | No | Custom consumption message |

---

## 4. Food as Objects

Food items inherit from `small-item` and declare food-specific fields via `edible` + `food = {...}`. No `food` template exists -- food is a property, not a type.

### New Materials

| Material | Density | Ignition | Hardness | Notes |
|----------|---------|----------|----------|-------|
| **meat** | 1050 | 300 | 1 | Raw animal flesh |
| **bread** | 350 | 250 | 2 | Baked grain product |
| **fruit** | 900 | 350 | 1 | Phase 2 |
| **cheese** | 1100 | 350 | 3 | Phase 2 |

---

## 5. Creature-to-Food Transformation (D-14)

**Source:** Wayne directive (2026-03-27): *"The engine should allow creature instances to completely change into an object instance on death. The mutation target is declared in the creature's own metadata."*

### The Mechanism

When a creature's health reaches zero, the engine triggers a mutation declared in the creature's `.lua` file. The creature literally becomes a different object. No creature-specific engine code.

```
rat.lua (creature, alive) -> [health_zero] -> dead-rat.lua (object, edible, container)
```

### Creature Declares Its Own Death Form

```lua
-- In rat.lua
mutations = {
    die = {
        becomes = "dead-rat",
        message = "The rat shudders once and goes still.",
        transfer_contents = true,
    },
},
```

Engine reads `mutations.die`, calls `mutation.mutate()`. Pure Principle 8.

### What Happens Mechanically

1. Rat takes lethal damage, health reaches zero
2. Engine checks `rat.mutations.die` -- calls `mutation.mutate(reg, ldr, "rat", "dead-rat", templates)`
3. Mutation loads `dead-rat.lua`, resolves `template = "small-item"`
4. Preserves `location` and `container` -- dead rat stays where live rat was
5. Registry entry replaced -- old creature data (behavior, drives, reactions) gone
6. Object is now a portable small-item with `edible = true`

### The Dead Rat Object

```lua
-- src/meta/objects/dead-rat.lua
return {
    guid = "{generate-guid}",
    template = "small-item",
    id = "dead-rat",
    name = "a dead rat",
    keywords = {"dead rat", "rat", "rat corpse", "corpse", "carcass"},
    description = "A dead rat lies on its side, legs splayed. Matted brown fur darkened with blood.",

    size = 1, weight = 0.3, portable = true,
    material = "flesh",
    container = true, capacity = 1,

    edible = true,
    cookable = true,
    food = {
        category = "meat", raw = true, cook_to = "cooked-rat-meat",
        nutrition = 3, risk = "disease", risk_chance = 0.4,
        spoil_time = 40, bait_value = 85, bait_target = "rodent",
        on_eat_message = "You tear into the raw rat flesh. It's gamey and foul.",
    },

    on_feel = "Cooling fur over a limp body. Thin ribs beneath the skin.",
    on_smell = "Blood and musk. The sharp copper of fresh death.",
    on_listen = "Nothing. Absolutely nothing.",
    on_taste = "Fur and blood. Raw and metallic. Your stomach clenches.",
    room_presence = "A dead rat lies crumpled on the floor.",

    crafting = {
        cook = {
            becomes = "cooked-rat-meat",
            requires_tool = "fire_source",
            message = "You hold the rat over the flames. The fur singes away and the flesh darkens.",
            fail_message_no_tool = "You need a fire source to cook this.",
        },
    },
    mutations = {
        cook = { becomes = "cooked-rat-meat", requires_tool = "fire_source" },
    },

    initial_state = "fresh", _state = "fresh",
    states = {
        fresh = { description = "A dead rat, freshly killed.", room_presence = "A dead rat lies crumpled on the floor." },
        bloated = {
            description = "A dead rat, belly distended with gas.",
            on_smell = "Sweet, sickly decay.",
            food = { nutrition = 0, bait_value = 95,
                effects = { { type = "inflict_injury", injury_type = "food-poisoning", damage = 5 } } },
        },
        rotten = {
            description = "A rotting rat. Maggots writhe in the exposed flesh.",
            on_smell = "Overwhelming putrefaction.",
            food = { nutrition = 0, bait_value = 100,
                effects = { { type = "inflict_injury", injury_type = "food-poisoning", damage = 10 } } },
        },
        bones = { description = "A tiny rodent skeleton, picked clean.", edible = false, food = nil },
    },
    transitions = {
        { from = "fresh", to = "bloated", verb = "_tick", condition = "timer", timer = 40 },
        { from = "bloated", to = "rotten", verb = "_tick", condition = "timer", timer = 40 },
        { from = "rotten", to = "bones", verb = "_tick", condition = "timer", timer = 60 },
    },
}
```

### Why Mutation, Not FSM Dead State

The team rejected keeping the creature in a `dead` FSM state with `edible = true`:

1. **Principle 0 violation** -- a creature with `animate = false` that you eat and carry is functionally an object.
2. **No independent FSM** -- bolting spoilage onto creature FSM mixes behavioral and material states.
3. **No containment** -- dead rat needs to BE a container for stolen items.

---

## 6. Cooking as Craft Gate

**Source:** Wayne directive (2026-03-27): *"Some food can't be eaten without cooking. Cooking is a CRAFTING operation that gates edibility."*

### The Model

Some food is inedible raw. `cook` verb + `fire_source` triggers mutation to cooked version. Raw object declares `edible = false` + `cookable = true` + `food = { raw = true, cook_to = "cooked-form" }`. Eat handler rejects with hint.

### Cooking Uses Mutation, Not FSM

Cooking transforms `raw-rat-meat.lua` into `cooked-rat-meat.lua` via mutation (D-14):

1. Cooked meat is a fundamentally different object -- different name, description, sensory, nutrition.
2. D-14 Prime Directive -- the code is rewritten entirely.
3. FSM is wrong here -- FSM is for state cycling (candle: unlit/lit). Raw-to-cooked is material transformation.
4. Precedent -- existing `sew` verb already uses `recipe.becomes` mutation.

**Exception:** Post-cooking degradation uses FSM: `fresh -> cold -> spoiled`. Legitimate FSM.

### Cooking Uses the `crafting` Field Pattern

Same convention as `sew`: object declares `crafting.cook` with recipe, `requires_tool`, `becomes`, and `message`.

### Fire Source Scope

Cooking requires `fire_source` capability anywhere visible -- hands, room, or surfaces. `find_visible_tool()` already handles this. Fire sources are often environmental (fireplace, wall torch).

| Object | Provides | Status |
|--------|----------|--------|
| match (lit) | `fire_source` | Exists |
| candle (lit) | `fire_source` | Exists |
| torch (lit) | `fire_source` | Exists |
| kitchen hearth | `fire_source` (when lit) | **Needed for Level 1** |

---

## 7. Cooking Verb Spec

**Verb:** `cook` | **Aliases:** `roast`, `bake`, `grill`  
**File:** `src/engine/verbs/crafting.lua` (follows `sew` pattern)  
**Requires:** Food in hand + `fire_source` in visible scope

```lua
handlers["cook"] = function(ctx, noun)
    if noun == "" then print("Cook what?") return end

    local food = find_in_inventory(ctx, noun)
    if not food then food = find_visible(ctx, noun) end
    if not food then err_not_found(ctx) return end

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
    if not fire then fire = find_tool_in_inventory(ctx, recipe.requires_tool or "fire_source") end
    if not fire then
        print(recipe.fail_message_no_tool or "You need a fire source to cook.")
        return
    end

    local ok = perform_mutation(ctx, food, recipe)
    if not ok then print("Something goes wrong.") return end
    consume_tool_charge(ctx, fire)
    print(recipe.message or ("You cook " .. (food.name or "it") .. " over the flames."))
end

handlers["roast"] = handlers["cook"]
handlers["bake"] = handlers["cook"]
handlers["grill"] = handlers["cook"]
```

Players type `cook meat`, `bake bread`, `roast rat` -- natural language. The `sew` pattern proves the model: each craft type gets its own handler. The recipe on the object controls output.

---

## 8. Mutation Chain: Live Rat to Dinner

The full D-14 mutation chain. Three stages, three `.lua` files, three complete sensory sets.

```
rat.lua (creature, alive, animate=true)
  -> [kill] -> dead-rat.lua (object, edible raw but risky)
    -> [cook] -> cooked-rat-meat.lua (object, safe, nutritious)
```

### Stage 1: Living Rat

```lua
-- src/meta/creatures/rat.lua (excerpt)
mutations = {
    die = { becomes = "dead-rat", message = "The rat shudders once and goes still.",
            transfer_contents = true },
},
```

### Stage 2: Dead Rat

See section 5 for full `.lua`. Key: `edible = true`, `food.raw = true`, `food.cook_to = "cooked-rat-meat"`, spoilage FSM fresh -> bloated -> rotten -> bones.

### Stage 3: Cooked Rat Meat

```lua
-- src/meta/objects/cooked-rat-meat.lua
return {
    guid = "{generate-guid}",
    template = "small-item",
    id = "cooked-rat-meat",
    name = "a piece of cooked rat meat",
    keywords = {"rat meat", "cooked meat", "meat", "cooked rat meat", "food"},
    description = "A charred chunk of rat meat, browned and crispy. Not a feast, but better than raw.",

    material = "flesh", size = 1, weight = 0.15, portable = true,

    edible = true, cookable = false,
    food = {
        category = "meat", raw = false, nutrition = 15, spoil_time = 120,
        effects = {
            { type = "narrate", message = "Tough and gamey, but it fills your stomach." },
            { type = "mutate", target = "player", field = "health", value = 3, op = "add" },
        },
    },

    on_feel = "Warm and firm. Slightly crispy surface, dense and fibrous inside.",
    on_smell = "Charred meat -- smoky, savory, with an undertone of gaminess.",
    on_taste = "Tough and gamey, but edible. The char adds a bitter smokiness.",
    on_listen = "Faint crackling as it cools.",
    room_presence = "A piece of cooked meat sits here, still faintly steaming.",

    initial_state = "fresh", _state = "fresh",
    states = {
        fresh = { description = "Cooked rat meat, still warm." },
        cold = { description = "Cold cooked rat meat. Congealed grease.", food = { nutrition = 10 } },
        spoiled = { description = "Rotten meat. Grey-green mold.", edible = false },
    },
    transitions = {
        { from = "fresh", to = "cold", verb = "_tick", condition = "timer", timer = 30 },
        { from = "cold", to = "spoiled", verb = "_tick", condition = "timer", timer = 90 },
    },
}
```

### Grain-to-Flatbread Chain

```lua
-- src/meta/objects/grain-handful.lua
return {
    guid = "{generate-guid}", template = "small-item",
    id = "grain-handful", name = "a handful of barley grain",
    keywords = {"grain", "barley", "kernels"},

    edible = false, cookable = true,
    on_eat_reject = "Raw grain is too hard to chew. You'd need to bake it.",
    on_feel = "Dry, hard kernels that shift between your fingers.",
    on_smell = "Dusty, faintly nutty.",

    crafting = {
        cook = {
            becomes = "flatbread", requires_tool = "fire_source",
            message = "You spread the grain on a flat stone near the fire. It fuses into crude flatbread.",
        },
    },
    mutations = { cook = { becomes = "flatbread", requires_tool = "fire_source" } },
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

### Spoilage Lifecycle

Food uses existing FSM engine. No new engine code.

```
    FRESH --(cook)--> COOKED
      |                  |
      | spoil_time       | spoil_time (longer)
      v                  v
    SPOILED            SPOILED
```

Cooking resets and extends the spoilage timer. Historically accurate. Strategically motivating.

### Spoilage Timers

| Food | Fresh to Spoiled | Cooked to Spoiled | Notes |
|------|-----------------|-------------------|-------|
| Raw meat | 60 ticks | 120 ticks | Cooking doubles shelf life |
| Bread | 120 to stale, 240 to moldy | N/A | Does not cook further |
| Cheese | 200 to aged | N/A | Aging *improves* it |
| Fruit | 80 ticks | N/A | Spoils fast |
| Dried herbs | Never | N/A | Already preserved |

At game scale (1 real hour = 1 game day), 60 ticks ~ 2.5 real minutes.

---

## 10. Sensory Integration

### The Sensory Funnel

```
SMELL (safe)       -> "Something smells like roasted meat."
FEEL (safe)        -> "Warm, firm, oily. Cooked meat."
LOOK (needs light) -> "A charred chicken leg on a wooden plate."
TASTE (risky!)     -> "Rich, smoky." OR: "Bitter, WRONG"
```

Cautious player uses SMELL + FEEL = full identification, zero risk.

### State-Dependent Sensory

| State | SMELL | FEEL | TASTE |
|-------|-------|------|-------|
| **Fresh raw** | "Raw poultry, metallic" | "Cold, clammy" | "Raw and bloody" (nausea) |
| **Cooked** | "Smoky, savory" | "Hot, crispy" | "Rich, well-cooked" |
| **Spoiled** | "Rotting, eyes water" | "Slimy, warm" | "IMMEDIATE GAG" (poisoning) |

---

## 11. Food and Creatures (Bait)

Food objects declare `food.bait_value` (0-100). Creatures within smell range evaluate based on hunger drive.

| Food | Bait Value | Target |
|------|-----------|--------|
| Raw meat | 80 | rodent, carnivore |
| Cooked meat | 60 | rodent, carnivore |
| Cheese | 90 | rodent |
| Bread | 40 | rodent, omnivore |
| Spoiled food | 95 | rodent, insect |
| Dried herbs | 5 | none |

### Emergent Behaviors

- **Rat follows food trail** -- drop meat, rat navigates toward it
- **Baited trap** -- cheese in trap, rat investigates, trap springs
- **Distraction** -- drop food to lure rat, sneak past
- **Spoilage attracts pests** -- forgotten food becomes stronger bait
- **Feeding calms** -- drop food near hungry rat, fear drops

---

## 12. Food and Health

### Healing Scale

| Food Quality | Healing | Example |
|-------------|---------|---------|
| Raw edible | 0 | Raw fruit |
| Cooked simple | 3-5 HP | Roasted chicken, cooked rat |
| Cooked quality | 8-12 HP | Well-prepared meal (future) |
| Medicinal herb | Cure status | Mint cures nausea |
| Spoiled | -5 to -10 HP | Food poisoning |

### Food Poisoning Injury

```lua
-- src/meta/injuries/food-poisoning.lua
return {
    id = "food-poisoning",
    name = "food poisoning",
    description = "Cramps, nausea, and cold sweats.",
    severity = "moderate", duration = 20,
    effects = {
        { type = "add_status", status = "nauseated", duration = 12 },
        { type = "add_status", status = "weakened", duration = 20 },
    },
    on_feel = "Your guts twist and clench.",
    on_recovery = "The worst has passed.",
}
```

### Taste-Risk Spectrum

| Action | Risk | Reward |
|--------|------|--------|
| SMELL | None | Freshness, cooking state |
| FEEL | None | Temperature, texture |
| TASTE | Low-Med | Confirms identity; spoiled = nausea |
| EAT | Med-High | Full nutrition; spoiled = poisoning |

---

## 13. Creature Inventory Cross-Reference

**Reference:** `plans/creature-inventory-plan.md`

Dead creatures that are containers can drop loot AND can be food. These are independent metadata traits.

### The Intersection

When a creature dies and mutates to a corpse object:
- **If creature had inventory**: corpse is container with loot (`container = true`, `transfer_contents = true`)
- **If creature's flesh is edible**: corpse has `edible = true` and `food = {...}`
- These are independent. A corpse can be both, either, or neither.

### Examples

| Creature | Drops Loot? | Edible? | Corpse |
|----------|-------------|---------|--------|
| **Rat** | No | **Yes** | `dead-rat.lua`: edible, no loot |
| **Skeleton** | **Yes** (sword, armor, coins) | No (bones) | `skeleton-remains.lua`: container, not edible |
| **Thieving Rat** | **Yes** (stolen cheese) | **Yes** | `dead-rat.lua`: container AND edible |
| **Spider** | No | No (chitin) | `dead-spider.lua`: not edible |

### Design Rule

Creature declares `mutations.die.becomes` and `transfer_contents`. Corpse declares `container` and `edible` independently. No special "loot-food" engine logic -- existing systems handle both.

---

## 14. First Food Items

### Level 1 Roster (7 items)

| # | Item | Teaches | Tier |
|---|------|---------|------|
| 1 | Bread roll | Basic eating, safe food | Always-Edible |
| 2 | Raw chicken leg | Cooking requirement | Cook-Required |
| 3 | Cooked chicken leg | Cooking reward | Always-Edible (via mutation) |
| 4 | Wedge of cheese | Best rat bait, aging | Always-Edible |
| 5 | Dried mint leaves | Medicinal herb, nausea cure | Always-Edible |
| 6 | Wrinkled apple | Fruit, spoilage | Always-Edible |
| 7 | Waterskin | Drink mechanic, refillable | Always-Drinkable |

### Placement

| Item | Room | Location | Discovery |
|------|------|----------|-----------|
| Bread roll | Kitchen / Pantry | On shelf | SMELL bread |
| Raw chicken | Kitchen | Hanging from hook | SMELL raw meat |
| Cheese wedge | Cellar / Pantry | On shelf | SMELL cheese |
| Dried mint | Bedroom / Study | In drawer | FEEL papery bundle |
| Wrinkled apple | Kitchen | On table | FEEL round fruit |
| Waterskin | Bedroom | On nightstand | LISTEN sloshing |
| Cooked chicken | N/A | Created by cooking | -- |

---

## 15. Verb Extensions Summary

| Verb | Status | Aliases | Notes |
|------|--------|---------|-------|
| `eat` | **Exists** -- needs cookable check + effects | consume, devour | 2-line cookable hint + effects pipeline |
| `drink` | **Exists** -- works as-is | quaff, sip | FSM-driven |
| `cook` | **New** | roast, bake, grill | Mutation-based, fire_source |
| `pour` | **Exists** | splash, spill | For liquids |
| `fill` | **Exists** (FSM) | -- | Waterskin refill |
| `feed` | **Not needed** | -- | Emerges from drop/give + creature AI |

---

## 16. Scaling Path

### Phase 1: Proof of Concept (Current Target)

7 food items, cook verb, eat effects, spoilage FSM, edibility gating.

| Task | Effort | Owner |
|------|--------|-------|
| Create 7 food object `.lua` files | Medium | Flanders |
| Add `cook` verb handler + aliases | Small | Smithers |
| Add `cookable` check to eat handler | Small | Smithers |
| Add effects processing to eat verb | Small | Smithers |
| Create `food-poisoning` injury | Small | Flanders |
| Create meat material | Small | Flanders |
| Add kitchen hearth fire source | Medium | Moe |
| Place food items in Level 1 | Small | Moe |
| Tests: cook, eat raw/cooked, spoilage | Medium | Nelson |

### Phase 2: Creature Integration

| Task | Dependencies |
|------|-------------|
| Wire kill handler to `mutation.mutate` on `mutations.die` | Creature system |
| Create dead-rat, cooked-rat-meat objects | Phase 1 |
| Emit `food_present` stimulus on food drop | NPC stimulus |
| Creature hunger evaluates nearby food | NPC drives |
| Rat trap with bait slot | Trap design |

### Phase 3: Expanded Recipes

Multi-ingredient cooking, `butcher` verb (knife + corpse = meat + bones), brewing, preservation.

### Phase 4: World Economy

Food trade, tavern meals, cooking skill, food quality tiers.

---

## 17. Open Questions

### Original (still open)

**Q1: Can a candle cook food?** Rec: No. Only dedicated fire sources have `fire_source`.

**Q2: Does eating raw fruit cause nausea?** Rec: Category-based. Raw fruit/herbs/cheese/bread = safe. Raw meat = nausea. Spoiled anything = poisoning.

**Q3: Should hunger exist as a player stat?** Rec: Defer. Valheim model (no hunger). Revisit after playtesting.

**Q4: How many fire sources in Level 1?** Rec: 1 (kitchen fireplace). Classic adventure loop.

**Q5: Can creatures eat dropped food?** Rec: Yes, with delay. Must be hungry and unafraid.

**Q6: Cooking require both hands free?** Rec: No. Food in one hand, fire is room fixture.

### New (from tonight's directives)

**Q7: Corpse mutation instant or delayed?** Rec: Instant. Death narration already emitted by transition.

**Q8: ALL creatures drop corpses?** Rec: Size-based. Small = portable corpse. Medium+ = furniture-sized (butcher in place).

**Q9: Cook whole corpse without butchering?** Rec: V1 yes for small creatures (rats). Larger creatures require butchery (Phase 3).

**Q10: Dead rat as bait?** Rec: Yes. Rats are cannibalistic. `bait_value = 85` attracts live rats.

**Q11: Grain needs water to cook?** Rec: V1: grain + fire = flatbread. Phase 3: grain + fire + water = porridge.

**Q12: Wine as food?** Rec: Yes. Add `food = { category = "drink", nutrition = 5, effects = { tipsy } }` to wine open state.

---

## Appendix A: Engine Readiness

| Feature | Status | Usage |
|---------|--------|-------|
| `edible` + `eat` verb | Exists | Consumption |
| `drink` + FSM | Exists | Liquids |
| Sensory hooks | Exists | Identification |
| Effects pipeline | Exists | Food effects |
| FSM timers | Exists | Spoilage |
| Mutation hot-swap | Exists | Cooking + death |
| Material registry | Exists | Food materials |
| `cook` verb | **Needs creation** | Cooking |
| `food.effects` in `eat` | **Needs addition** | Eat effects |
| `cookable` check in `eat` | **Needs addition** | Raw rejection |
| `food-poisoning` injury | **Needs creation** | Spoiled food |
| Food materials | **Needs creation** | meat, bread |
| Fire source furniture | **Needs creation** | Kitchen hearth |

**Assessment: ~80% ready.** Core pipelines exist. Remaining = content + minor verb additions.

---

## Appendix B: Cross-References

| Document | Relevance |
|----------|-----------|
| `docs/design/design-directives.md` | D-14, sensory system |
| `docs/architecture/objects/core-principles.md` | Principles 0, 1, 3, 6, 8, 9 |
| `plans/npc-system-plan.md` | Rat hunger, smell, bait |
| `plans/creature-inventory-plan.md` | Loot drops, death mutation, containers |
| `docs/design/tools-system.md` | fire_source capability |
| `.squad/decisions/inbox/bart-food-architecture.md` | A+B hybrid decision |
| `.squad/decisions/inbox/bart-cooking-craft-architecture.md` | Cook verb, crafting pattern |
| `.squad/decisions/inbox/cbg-food-creature-design.md` | Competitor analysis |
| `.squad/decisions/inbox/frink-cooking-gates-research.md` | 7-game cooking survey |
| `.squad/decisions/inbox/copilot-directive-creature-self-mutation.md` | Wayne D-14 creature directive |
| `.squad/decisions/inbox/copilot-directive-cooking-craft.md` | Wayne cooking-as-craft directive |

---

## Appendix C: Squad Impact

| Member | Work |
|--------|------|
| **Flanders** | Create dead-rat, cooked-rat-meat, flatbread, food-poisoning injury, meat material |
| **Moe** | Kitchen hearth, place food items in Level 1 |
| **Smithers** | `cook`/`roast`/`bake`/`grill` handler; `cookable` check + `food.effects` in eat handler |
| **Nelson** | Tests: cook with/without fire, eat raw/cooked, spoilage FSM |
| **Sideshow Bob** | Cooking puzzles (rat bait, food trade, hunger pressure) |
| **Bart** | Wire kill handler to `mutation.mutate` on creature death (Phase 2) |
