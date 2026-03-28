# Food–Creature Transformation: Unified Design Plan

**Author:** Comic Book Guy (Creative Director / Design Department Lead)  
**Date:** 2026-08-15  
**Status:** 🟢 Design Proposal — Awaiting Wayne Approval  
**Supersedes:** `plans/food-system-design.md` (food design), `plans/creature-inventory-plan.md` (loot design)  
**Incorporates:** Wayne's 3 directives, Bart's 2 architecture decisions, Frink's 2 research docs, CBG's creature→food design

---

> "I have read eight documents totaling 200+ KB, synthesized three Wayne directives, two Bart architecture decisions, two Frink research surveys, and my own prior creature→food analysis into a single unified design. Worst. Cross-referencing exercise. Ever."

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Wayne's Directives (Authoritative)](#2-waynes-directives)
3. [The Mutation Chain](#3-the-mutation-chain)
4. [Edibility Model](#4-edibility-model)
5. [Cooking System](#5-cooking-system)
6. [Creature Inventory & Loot Drops](#6-creature-inventory--loot-drops)
7. [Loot + Food Interaction](#7-loot--food-interaction)
8. [Full Example: The Rat](#8-full-example-the-rat)
9. [Full Example: The Skeleton](#9-full-example-the-skeleton)
10. [Sensory Escalation for Food](#10-sensory-escalation-for-food)
11. [Open Questions for Wayne](#11-open-questions-for-wayne)
12. [Scaling Path](#12-scaling-path)
13. [Agent Assignments](#13-agent-assignments)

---

## 1. Executive Summary

Wayne's freestyle session produced three interconnected directives that unify food, creatures, cooking, and loot into a single mutation-driven pipeline. This plan documents the **design** (not implementation) of that pipeline.

### The Core Insight

There are no separate "food system" and "loot system" and "cooking system." There is **one system: D-14 mutation chains**, with metadata traits that tell the engine what each link in the chain can do.

```
ALIVE CREATURE ──[kill]──▶ DEAD CREATURE/CORPSE ──[cook]──▶ COOKED FOOD
     (animate)                (small-item, edible)            (small-item, edible, safe)
                                     │
                                     ├── has inventory? ──▶ items drop to room
                                     └── has food metadata? ──▶ can be eaten
```

### Four Principles Governing Everything

| # | Principle | Application |
|---|-----------|-------------|
| **D-14** | Code Mutation IS State Change | `rat.lua` → `dead-rat.lua` → `cooked-rat-meat.lua`. Each is a complete code rewrite. |
| **P-8** | Engine Executes Metadata | Objects declare `mutations.die`, `crafting.cook`, `edible`, `food = {...}`. Engine reads and acts. Zero object-specific engine code. |
| **P-0** | Objects Are Inanimate | A dead creature IS an object. The creature→object boundary crossing happens via mutation. Clean categorical split. |
| **P-9** | Material Consistency | Rat flesh is flesh. Steel sword is steel. Material properties determine what happens when you cut, burn, or cook something. |

### What This Plan Decides

| Decision | Choice | Rationale |
|----------|--------|-----------|
| How creatures become food | D-14 mutation (`mutations.die`) | Creature .lua declares its own death transformation (Wayne directive) |
| How food is modeled | Metadata trait (`edible = true`, `food = {...}`) on any object | Not a template. Pure Principle 8. (Bart's A+B hybrid) |
| How cooking works | `cook` verb + `fire_source` tool + mutation | Cooking gates edibility. `raw-meat.lua` → `cooked-meat.lua` (Wayne directive) |
| How creature inventory works | Reuse existing containment system (`container = true`) | Creatures carry items via same mechanics as chests/bags (Wayne directive) |
| How loot drops | On death, inventory instantiates to room floor | Items become independent room objects (creature-inventory-plan Phase 1) |

---

## 2. Wayne's Directives (Authoritative)

These three directives from Wayne's session are **binding design decisions**, not proposals.

### Directive W-FOOD-1: Dead Creatures Become Food via D-14 Mutation

> "The engine should allow creature instances to completely change into an object instance on death. The creature .lua file would know how to rewrite itself into an object."

**Implementation:** Every creature that can become food declares `mutations.die = { becomes = "dead-X" }`. The engine triggers this mutation when health reaches zero. The mutation target is a `small-item` with `edible = true`.

### Directive W-FOOD-2: Cooking Gates Edibility

> "Some food can't be eaten without cooking. Raw flesh requires cooking to make the state change from raw flesh to edible meat. Cooking is a CRAFTING operation that gates edibility."

**Implementation:** Raw food has `edible = false` + `cookable = true` + `crafting.cook = { becomes = "cooked-X", requires_tool = "fire_source" }`. The `cook` verb reads this recipe and performs the mutation. Cooked food has `edible = true`.

### Directive W-FOOD-3: Creatures Have Inventory, Drop Loot on Death

> "Creatures should have inventory. Killing a creature causes them to drop their inventory as loot."

**Implementation:** Creatures declare `inventory = { hands = {...}, worn = {...}, carried = {...} }`. On death, the engine instantiates all inventory items as independent room-floor objects. The containment system already supports this.

---

## 3. The Mutation Chain

The mutation chain is the central concept unifying food, death, and cooking. Each step is a complete D-14 code rewrite — the `.lua` file transforms into an entirely different `.lua` file.

### 3.1 Chain Anatomy

```
┌────────────────┐    mutations.die     ┌────────────────┐    crafting.cook     ┌────────────────┐
│  LIVE CREATURE  │────────────────────▶│   DEAD CORPSE   │────────────────────▶│  COOKED FOOD    │
│                 │                      │                 │                      │                 │
│  animate = true │                      │  template =     │                      │  template =     │
│  template =     │                      │    "small-item" │                      │    "small-item"  │
│    "creature"   │                      │  edible = true  │                      │  edible = true   │
│  behavior = {}  │                      │  food.raw = true│                      │  food.raw = false│
│  drives = {}    │                      │  portable = true│                      │  nutrition = 15  │
│  health = 10    │                      │  container=true │                      │  healing = true  │
└────────────────┘                      └────────────────┘                      └────────────────┘
        │                                       │                                       │
    creature/                               objects/                                objects/
     rat.lua                              dead-rat.lua                        cooked-rat-meat.lua
```

### 3.2 What Each Link Provides

| Link | Template | Key Traits | File Location |
|------|----------|------------|---------------|
| **Live creature** | `creature` | `animate=true`, behavior, drives, health, combat, body_tree | `src/meta/creatures/` |
| **Dead corpse** | `small-item` | `edible=true`, `food={raw=true}`, `container=true`, spoilage FSM, sensory | `src/meta/objects/` |
| **Cooked food** | `small-item` | `edible=true`, `food={raw=false}`, nutrition, healing, new sensory | `src/meta/objects/` |

### 3.3 What the Mutation Preserves

Per Bart's architecture analysis, `mutation.mutate()` preserves:
- **Location** — dead rat appears where the live rat was
- **Container contents** — if the rat was carrying stolen cheese, the corpse holds it
- **Registry ID slot** — the object ID stays the same; the GUID updates
- **Surface placement** — if the rat was on a shelf, corpse is on the shelf

What mutation **destroys**:
- All creature fields (`behavior`, `drives`, `reactions`, `movement`, `awareness`, `health`)
- The old GUID (new object gets its own)
- The `animate` flag (not present on small-item template)

This is correct. A dead rat has no behavior, no drives, no health. The code transformation reflects reality.

### 3.4 Branching Chains

Not all chains are linear. Some creatures branch:

```
Live rat ──[die]──▶ Dead rat ──[cook]──▶ Cooked rat meat
                         │
                         └──[butcher]──▶ Raw rat meat ──[cook]──▶ Cooked rat meat
                                              │
                                              └──▶ Rat bones (byproduct)
```

```
Live skeleton ──[die]──▶ Skeleton remains (NOT edible)
                               │
                               └──▶ [search/loot] ──▶ sword, coins, armor (inventory drops)
```

**Rule:** Every branch is a D-14 mutation. The creature declares the first step (`mutations.die`). Each subsequent object declares its own next step (`mutations.butcher`, `crafting.cook`). The chain is **distributed across object files**, not centralized in the engine.

---

## 4. Edibility Model

### 4.1 Food as Metadata Trait

**"Food" is not a template. It's a metadata trait.** This is Bart's Option A+B hybrid, confirmed by Wayne.

Any object — small-item, container, furniture, even a wax candle — can be food by declaring `edible = true` and a `food = {...}` table. The `eat` verb checks this metadata. The engine doesn't know about "food" as a concept — it knows about `edible` and `food.nutrition`.

```lua
-- ANY object can be food. These are all valid:
{ template = "small-item", id = "bread-roll",     edible = true, food = { nutrition = 15 } }
{ template = "small-item", id = "dead-rat",        edible = true, food = { nutrition = 5, raw = true } }
{ template = "small-item", id = "cooked-rat-meat", edible = true, food = { nutrition = 15, raw = false } }
{ template = "small-item", id = "candle-stub",     edible = true, food = { nutrition = 0, on_eat_message = "Why." } }
{ template = "small-item", id = "skeleton-remains", edible = false }  -- bones aren't food
```

### 4.2 The `food` Table Convention

Every object with `edible = true` SHOULD declare a `food = {}` table. The engine reads these fields:

| Field | Type | Required? | Description |
|-------|------|-----------|-------------|
| `nutrition` | number | Yes | Healing/buff strength (0–100 scale) |
| `raw` | bool | No | `true` if uncooked. Default `false`. |
| `risk` | string | No | Risk type on consumption: `"disease"`, `"poison"`, `"nausea"` |
| `risk_chance` | number | No | Probability of risk triggering (0.0–1.0) |
| `on_eat_message` | string | No | Narration when eaten |
| `effects` | table | No | Array of effect tables applied on consumption |
| `category` | string | No | `"meat"`, `"grain"`, `"fruit"`, `"herb"`, `"dairy"`, `"drink"` |
| `spoil_time` | number | No | Ticks until spoilage (0 or nil = never spoils) |
| `bait_value` | number | No | Attractiveness to creatures (0–100) |
| `bait_target` | string | No | Creature category attracted: `"rodent"`, `"insect"`, `"omnivore"` |

### 4.3 The Edibility Spectrum

Wayne's directive creates three edibility states. These aren't FSM states — they're metadata declarations:

| State | `edible` | `cookable` | Eating Outcome | Example |
|-------|----------|------------|----------------|---------|
| **Inedible** | `false` | `false` | "You can't eat that." | Sword, stone, skeleton remains |
| **Requires cooking** | `false` | `true` | "You can't eat this raw. Try cooking it first." | Raw rat meat, grain handful |
| **Edible (risky)** | `true` | — | Nausea, disease risk, low nutrition | Dead rat corpse (whole), raw fish |
| **Edible (safe)** | `true` | — | Good nutrition, possible healing | Cooked meat, bread, cheese, fruit |

The key Wayne directive: **cooking gates edibility**. Some food literally cannot be eaten until cooked. Others CAN be eaten raw but are risky. The metadata on each object controls which pattern applies.

### 4.4 Edibility Gating in the Eat Handler

The existing `eat` handler checks `obj.edible`. Bart's architecture adds a `cookable` check:

```lua
if obj.edible then
    -- existing eat logic (process food.effects, nutrition, remove object)
elseif obj.cookable then
    -- Object needs cooking first
    print(obj.on_eat_reject or "You can't eat that raw. Try cooking it first.")
else
    print("You can't eat " .. (obj.name or "that") .. ".")
end
```

This is a **2-line addition** to the existing eat handler. The `on_eat_reject` field lets each object provide a custom rejection message. If absent, a generic hint guides the player.

---

## 5. Cooking System

### 5.1 The `cook` Verb

Cooking is a **dedicated verb**, not a sub-command of `craft`. Per Bart's architecture:

- `cook`, `roast`, `bake`, `grill` are all aliases to the same handler
- The handler reads `obj.crafting.cook` (the recipe)
- The recipe declares `requires_tool = "fire_source"` and `becomes = "cooked-X"`
- The handler searches room scope for a `fire_source` capability
- On success: mutation rewrites the object. On failure: helpful error message.

### 5.2 Cooking as Mutation (D-14)

Cooking is the cleanest application of the Prime Directive. Raw food is destroyed and replaced by cooked food:

```
raw-rat-meat.lua                    cooked-rat-meat.lua
────────────────                    ────────────────────
name = "raw rat meat"          →    name = "cooked rat meat"
edible = false                 →    edible = true
food.raw = true                →    food.raw = false
food.nutrition = 0             →    food.nutrition = 15
on_smell = "raw blood, musk"   →    on_smell = "charred, smoky, savory"
on_taste = "you'd need to be   →    on_taste = "tough, gamey, edible"
  truly desperate..."
```

Every field is different. This is not a state change — it's a **material transformation**. The cooked meat is a fundamentally different object. D-14 is the right mechanism.

### 5.3 Recipe Metadata on Objects

Objects declare their cooking recipe in a `crafting.cook` table:

```lua
crafting = {
    cook = {
        becomes = "cooked-rat-meat",
        requires_tool = "fire_source",
        message = "You hold the meat over the flames. It sizzles and darkens.",
        fail_message_no_tool = "You need a fire source to cook this.",
    },
},
```

This follows the exact pattern of the existing `sew` verb in `crafting.lua`. The engine is recipe-agnostic — it reads the metadata and performs the mutation.

### 5.4 Fire Source Scope

Per Bart's Decision 5: **Cooking requires `fire_source` capability. The tool can be anywhere visible — hands, room, or surfaces.**

The player doesn't need to hold fire. They hold the food near the fire:
- Player holds raw meat + lit candle in hand → cook works (if candle provides `fire_source`)
- Player holds raw meat, lit torch on wall → cook works
- Player holds raw meat, fireplace is in room → cook works
- No fire anywhere → "You need a fire source to cook this."

### 5.5 Existing Fire Sources

| Object | Provides `fire_source`? | Notes |
|--------|------------------------|-------|
| Match (lit) | Yes | Consumable, short duration |
| Candle (lit) | Debatable (open question) | Small flame, see Q1 |
| Oil lantern (lit) | Yes | Sustained fire |
| Torch (lit) | Yes | Room-scope, not held |
| Kitchen hearth | Yes (when lit) | **Needed for Level 1** — implied by existing room descriptions |

### 5.6 Cooking Failure

For Phase 1: cooking is binary. Either you have a `fire_source` and the mutation succeeds, or you don't and it fails. No partial cooking, no burning. Keep it simple.

Future phases can add:
- **Burned food** (Valheim mechanic): leave on fire too long → mutation to `charred-X` (inedible but useful for smelting)
- **Partial cooking**: fire goes out mid-cook → remains raw

---

## 6. Creature Inventory & Loot Drops

### 6.1 Inventory Model

Per Wayne's directive and the creature-inventory-plan, creatures carry items via the **same containment system** players use:

```lua
-- In skeleton-warrior.lua
inventory = {
    hands = { "steel-sword-01", "shield-01" },
    worn = {
        head = "iron-helmet-01",
        torso = "iron-plate-armor-01",
    },
    carried = { "coins-20", "key-01" },
},
```

Three layers:
| Layer | Max | Combat Effect? | Example |
|-------|-----|----------------|---------|
| **Hands** | 2 items | Yes (wielded weapons) | Sword, shield |
| **Worn** | 1 per slot (9 slots) | Yes (armor reduces damage) | Helmet, breastplate |
| **Carried** | Capacity-limited | No | Coins, keys, potions |

### 6.2 Death Drop Mechanism

When a creature enters the `dead` state:

1. Engine checks `mutations.die` on the creature
2. If defined: `mutation.mutate()` replaces creature with corpse/remains object
3. **All inventory items instantiate to the room floor** as independent objects
4. The dead creature object (corpse) appears at the creature's last location
5. Inventory items are now lootable — `take sword`, `take coins`, etc.

**Phase 1 uses scatter-to-floor** (items appear directly on room floor, not inside corpse). This is simpler and matches how most roguelikes handle it.

### 6.3 Self-Declared Mutation (Wayne's Directive)

The creature's `.lua` file declares its own death transformation. No creature-specific engine code:

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

The engine logic is generic:
```
health reaches 0 → check mutations.die → if exists: mutate → if transfer_contents: move inventory
```

This is **Principle 8 in action**. The engine doesn't know about rats, skeletons, or wolves. It knows about `mutations.die.becomes`.

### 6.4 Creatures Without Inventory

A creature with empty or missing `inventory = {}` drops nothing. A bare rat with no items dies and becomes a corpse — no loot, just a dead animal. This is valid and common for simple creatures.

### 6.5 Creatures Without Death Mutation

If a creature has no `mutations.die`, the engine falls back to FSM transition to `dead` state. The creature remains a creature (just dead, `animate = false`). This is the existing behavior — mutation is opt-in, not mandatory.

---

## 7. Loot + Food Interaction

This is where the systems combine. A dead creature can be **both** a container (holding loot) **and** food (with edible metadata). Or it can be one but not the other.

### 7.1 The Two Archetypes

| Archetype | Container? | Edible? | Example |
|-----------|-----------|---------|---------|
| **Food creature** | Maybe (if carrying stolen items) | Yes | Dead rat, dead chicken |
| **Loot creature** | Yes (armor, weapons, coins) | No | Dead skeleton, dead golem |
| **Food + loot** | Yes | Yes | Dead wolf (meat + carried items) |

### 7.2 How This Works Mechanically

**Food creature (rat):**
```lua
-- dead-rat.lua
template = "small-item",
edible = true,
container = true,   -- holds anything the rat was carrying
capacity = 1,
food = { nutrition = 5, raw = true, risk = "disease", risk_chance = 0.4 },
```

The player can:
- `eat dead rat` → consumes for low nutrition + nausea risk
- `search dead rat` → finds stolen cheese (if rat had inventory)
- `cook dead rat` → mutation to `cooked-rat-meat.lua`

**Loot creature (skeleton):**
```lua
-- skeleton-remains.lua
template = "small-item",
edible = false,       -- bones aren't food
container = true,     -- holds skeleton's former equipment
capacity = 5,
```

The player can:
- `search skeleton` → finds sword, coins, armor
- `eat skeleton` → "You can't eat that."
- No cooking, no food metadata

**Food + loot creature (wolf, future):**
```lua
-- dead-wolf.lua
template = "small-item",   -- or "furniture" if too large to carry
edible = true,
container = true,
food = { nutrition = 8, raw = true, cookable = true },
-- Wolf was carrying a stolen saddlebag with coins
```

### 7.3 Loot Drop Timing vs. Corpse Container

**Phase 1 design:** Items scatter to the room floor on death. The corpse is a separate object that MAY also be a container (for any items not yet instantiated). In practice, Phase 1 scatters everything.

**Future possibility:** Items drop INTO the corpse container. Player must `search corpse` or `open corpse` to access loot. This enables:
- Grave-robbing as a conscious action
- Corpse desecration mechanics
- "Did I miss something?" discovery

---

## 8. Full Example: The Rat

The complete lifecycle of a rat, from alive to dinner.

### 8.1 Stage 1: Live Rat

```lua
-- src/meta/creatures/rat.lua
return {
    guid = "{071e73f6-...}",
    template = "creature",
    id = "rat",
    name = "a brown rat",
    animate = true,
    health = 10,
    behavior = { type = "skittish", ... },
    drives = { hunger = { value = 50, ... } },

    mutations = {
        die = {
            becomes = "dead-rat",
            message = "The rat shudders once and goes still.",
            transfer_contents = true,
        },
    },

    on_feel = "Coarse, greasy fur over a taut, wiry body...",
    on_smell = "Musk and damp fur. Rodent.",
}
```

The creature is animate, has behavior and drives, and declares its own death transformation.

### 8.2 Stage 2: Player Kills Rat

```
> hit rat with candlestick
You swing the brass candlestick. The rat squeals and crumples.

A dead rat lies on the floor.
```

**Engine flow:**
1. Damage handler reduces rat health to 0
2. Engine checks `rat.mutations.die` → found: `{ becomes = "dead-rat" }`
3. `mutation.mutate(reg, ldr, "rat", "dead-rat", templates)` executes
4. `dead-rat.lua` loaded, template `small-item` resolved
5. Location preserved — dead rat at rat's last position
6. Registry entry at "rat" replaced with dead-rat table
7. Creature tick skips (no `animate` field on new object)

### 8.3 Stage 3: Dead Rat (Object, Edible, Raw)

```lua
-- src/meta/objects/dead-rat.lua
return {
    guid = "{new-guid}",
    template = "small-item",
    id = "dead-rat",
    name = "a dead rat",
    keywords = {"dead rat", "rat", "rat corpse", "corpse", "carcass"},
    description = "A limp brown rat, matted fur dark with blood. Beady eyes stare at nothing.",

    size = 1,
    weight = 0.3,
    portable = true,
    material = "flesh",
    container = true,
    capacity = 1,

    edible = true,
    food = {
        category = "meat",
        nutrition = 5,
        raw = true,
        risk = "disease",
        risk_chance = 0.4,
        bait_value = 85,
        bait_target = "rodent",
        on_eat_message = "Fur and blood. Stringy, warm, profoundly wrong.",
        effects = {
            { type = "add_status", status = "nauseated", duration = 10 },
        },
    },

    cookable = true,
    on_eat_reject = "You could eat this raw, but it would be foul. Maybe cook it first.",

    crafting = {
        cook = {
            becomes = "cooked-rat-meat",
            requires_tool = "fire_source",
            message = "You hold the rat carcass over the flames. Fat sizzles. The fur singes away. The smell shifts from death to something almost edible.",
            fail_message_no_tool = "You need a fire source to cook this.",
        },
    },

    on_feel = "Cooling fur over a limp body. Thin ribs beneath the skin. The tail hangs like wet string.",
    on_smell = "Blood and musk. The sharp copper of fresh death.",
    on_listen = "Nothing. Absolutely nothing.",
    on_taste = "Fur and blood. Raw, metallic. Your stomach clenches.",

    -- Spoilage FSM
    initial_state = "fresh",
    _state = "fresh",
    states = {
        fresh = {
            description = "A dead rat, freshly killed. Blood glistens on its fur.",
            room_presence = "A dead rat lies crumpled on the floor.",
        },
        bloated = {
            description = "A dead rat, belly distended with gas. The fur has dulled.",
            room_presence = "A bloated rat carcass lies here. The smell worsens.",
            on_smell = "Sweet, sickly decay. Your nose wrinkles involuntarily.",
            food = { nutrition = 0, risk_chance = 0.8, effects = {
                { type = "inflict_injury", injury_type = "food-poisoning", damage = 5 },
            }},
        },
        rotten = {
            description = "A rotting rat. Maggots writhe in exposed flesh.",
            room_presence = "A rotting rat carcass festers here. Flies swarm.",
            on_smell = "Overwhelming putrefaction. Eyes water from five feet away.",
            edible = false,
            food = nil,
        },
    },
    transitions = {
        { from = "fresh", to = "bloated", verb = "_tick", condition = "timer", timer = 40 },
        { from = "bloated", to = "rotten", verb = "_tick", condition = "timer", timer = 40 },
    },
}
```

**Player options at this stage:**
- `eat dead rat` → edible but risky (nausea, disease chance, low nutrition)
- `cook dead rat` → mutation to cooked-rat-meat.lua (requires fire_source)
- `smell rat` / `feel rat` → sensory information about freshness
- `search rat` → find any items the rat was carrying
- Do nothing → spoilage FSM ticks: fresh → bloated → rotten

### 8.4 Stage 4: Player Cooks the Dead Rat

```
> cook dead rat
You hold the rat carcass over the flames. Fat sizzles. The fur singes 
away. The smell shifts from death to something almost edible.
```

**Engine flow:**
1. `cook` verb resolves "dead rat" → dead-rat object in inventory
2. Reads `crafting.cook` → `{ becomes = "cooked-rat-meat", requires_tool = "fire_source" }`
3. Searches room scope for `fire_source` capability → finds kitchen hearth (lit)
4. `mutation.mutate(reg, ldr, "dead-rat", "cooked-rat-meat", templates)` executes
5. Object replaced in registry. Location preserved.

### 8.5 Stage 5: Cooked Rat Meat (Safe Food)

```lua
-- src/meta/objects/cooked-rat-meat.lua
return {
    guid = "{new-guid}",
    template = "small-item",
    id = "cooked-rat-meat",
    name = "a piece of cooked rat meat",
    keywords = {"rat meat", "cooked meat", "meat", "cooked rat meat", "food"},
    description = "A charred chunk of rat meat, browned and crispy. Not a feast, but it smells better than it did raw.",

    size = 1,
    weight = 0.15,
    portable = true,
    material = "flesh",

    edible = true,
    cookable = false,
    food = {
        category = "meat",
        nutrition = 15,
        raw = false,
        on_eat_message = "Tough and gamey, but warm and filling. You've eaten worse. Probably.",
        effects = {
            { type = "mutate", target = "player", field = "health", value = 3, op = "add" },
        },
    },

    on_feel = "Warm and firm. Slightly crispy surface, dense and fibrous inside.",
    on_smell = "Charred meat — smoky, savory, with an undertone of gaminess.",
    on_taste = "Gamey. Fibrous. The char adds a bitter smokiness. Edible.",
    on_listen = "Faint crackling as it cools.",

    -- Post-cooking spoilage FSM
    initial_state = "fresh",
    _state = "fresh",
    states = {
        fresh = { description = "Cooked rat meat, still warm.", room_presence = "A piece of cooked meat sits here, faintly steaming." },
        cold = { description = "Cold cooked rat meat. Congealed grease coats the surface.", food = { nutrition = 10 } },
        spoiled = { description = "Grey-green mold covers the surface.", edible = false, food = nil },
    },
    transitions = {
        { from = "fresh", to = "cold", verb = "_tick", condition = "timer", timer = 60 },
        { from = "cold", to = "spoiled", verb = "_tick", condition = "timer", timer = 120 },
    },
}
```

### 8.6 Stage 6: Player Eats Cooked Rat Meat

```
> eat rat meat
You chew the tough, gamey meat. Not good, exactly, but warm and filling.
Your body accepts it gratefully.

[Nutrition: +15]
[Healing: +3 HP]
```

Object consumed. Removed from registry. Player healed.

### 8.7 Complete Rat Chain Summary

```
rat.lua (creature) ──[kill]──▶ dead-rat.lua (small-item, edible, raw)
                                    │
                                    ├──[eat raw]──▶ consumed (+5 nutrition, nausea risk)
                                    ├──[cook + fire_source]──▶ cooked-rat-meat.lua
                                    │                              └──[eat]──▶ consumed (+15, +3 HP)
                                    └──[wait]──▶ bloated ──▶ rotten (inedible)
```

---

## 9. Full Example: The Skeleton

A creature with inventory but NO food value. Demonstrates loot without food.

### 9.1 Live Skeleton

```lua
-- src/meta/creatures/skeleton-warrior.lua
return {
    guid = "{skeleton-guid}",
    template = "creature",
    id = "skeleton-warrior",
    name = "a skeleton warrior",
    animate = true,
    health = 30,

    inventory = {
        hands = { "steel-sword-01", "shield-01" },
        worn = {
            head = "iron-helmet-01",
            torso = "iron-plate-armor-01",
        },
        carried = { "coins-20", "key-01" },
    },

    mutations = {
        die = {
            becomes = "skeleton-remains",
            message = "The skeleton collapses in a clatter of bones and rusted iron.",
            transfer_contents = false,   -- items scatter to floor, not into remains
        },
    },

    on_feel = "Dry bone beneath cold iron. The joints click loosely.",
    on_smell = "Dust, old iron, and the faint sweetness of ancient decay.",
}
```

### 9.2 Player Kills Skeleton

```
> attack skeleton with sword
The skeleton collapses in a clatter of bones and rusted iron.

You see: a pile of bones, a steel sword, a shield, an iron helmet, 
iron plate armor, 20 coins, and a small key.
```

**Engine flow:**
1. Skeleton health reaches 0
2. `mutations.die` triggers → `mutation.mutate()` → skeleton-remains.lua
3. `transfer_contents = false` → inventory items instantiate directly to room floor
4. Six new room-floor objects: sword, shield, helmet, armor, coins, key
5. Skeleton-remains object appears at creature's location

### 9.3 Skeleton Remains (NOT Edible)

```lua
-- src/meta/objects/skeleton-remains.lua
return {
    guid = "{remains-guid}",
    template = "small-item",
    id = "skeleton-remains",
    name = "a pile of bones",
    keywords = {"skeleton", "bones", "remains", "pile of bones"},
    description = "A heap of yellowed bones, some still connected by sinew. The skull grins emptily.",

    size = 2,
    weight = 2.0,
    portable = false,   -- too awkward to carry
    material = "bone",

    edible = false,      -- bones are NOT food
    -- No food table. No crafting.cook. No cookable flag.

    on_feel = "Dry, smooth bone. Lighter than expected. Some pieces shift and click.",
    on_smell = "Dust and old calcium. Nothing organic left.",
    on_listen = "A faint clicking as bones settle.",
}
```

The player can:
- `search skeleton` → already visible (items scattered to floor)
- `take sword` / `take helmet` / `take coins` → normal pickup
- `eat skeleton` → "You can't eat that."
- No food system interaction at all

---

## 10. Sensory Escalation for Food

This is our competitive advantage. No other game in Frink's research has a graduated sensory risk escalation for food. We do.

### 10.1 The Escalation Ladder

```
SMELL (safe)  →  FEEL (safe)  →  LOOK (needs light)  →  TASTE (risky!)  →  EAT (committed)
```

Each step gives more information and carries more risk. A cautious player smells before tasting, tastes before eating. An impatient player eats first and suffers the consequences.

### 10.2 Applied to Food States

| Sense | Fresh Corpse | Bloated Corpse | Rotten Corpse | Cooked Meat |
|-------|-------------|----------------|---------------|-------------|
| **SMELL** | "Blood, musk" | "Sweet, sickly decay" ⚠️ | "Overwhelming rot" 🚫 | "Charred, savory" ✅ |
| **FEEL** | "Warm, limp" | "Puffy, taut, gas" | "Squishy, falling apart" | "Warm, crispy" |
| **TASTE** | "Raw, metallic" (nausea risk) | "Bitter bile" (nausea guaranteed) | "Immediate gag" (poisoning) | "Gamey, smoky" (safe) |
| **EAT** | +5, nausea | +0, food poisoning | -5 HP, severe | +15, +3 HP heal |

**Design principle:** SMELL is the player's food safety tool. It always works, always free, always informative. If something smells wrong, don't eat it. This teaches the sensory system organically.

### 10.3 Object-Category Food Escalation

Non-creature food (bread, cheese, grain) follows the same ladder with lower stakes:

| Sense | Fresh Bread | Stale Bread | Moldy Bread |
|-------|------------|-------------|-------------|
| **SMELL** | "Warm, yeasty" | "Faint wheat" | "Musty, sour" |
| **TASTE** | "Chewy, wholesome" | "Dry, chalky" | "GAG" |
| **EAT** | +15 nutrition | +5 nutrition | Nausea |

The risk gradient maps to biological reality — Principle 9 (material consistency) in action.

---

## 11. Open Questions for Wayne

### Q1: Can a candle cook food?

A lit candle has `casts_light = true`. Some existing objects mark it as `fire_source`. But realistically a candle is a terrible cooking fire.

**Options:**
- A) Candle IS a fire_source → cooking with a candle works (simplicity, consistency)
- B) Candle is NOT a fire_source for cooking → only dedicated fire objects (hearth, torch, brazier) work (puzzle value: finding real fire matters)

**CBG recommends B.** A candle that cooks meat trivializes the fire-finding puzzle. Limit `fire_source` for cooking to objects that realistically provide sufficient heat.

### Q2: Corpse cooking — can you cook a whole corpse?

Per CBG's food-creature analysis, dead-rat has `cookable = true`. But should you be able to cook the WHOLE corpse, or must you butcher first?

**Options:**
- A) Cook whole corpse → simpler, fewer steps, dead-rat cooks directly to cooked-rat-meat
- B) Must butcher first → knife → butcher corpse → raw-meat → cook → cooked-meat (deeper puzzle chain)
- C) Both paths exist → cook whole (lower nutrition) or butcher+cook (higher nutrition)

**CBG recommends A for Phase 1, C for Phase 2.** Keep the PoC chain short: kill → cook → eat. Add butchery as a "skilled path" bonus in Phase 2.

### Q3: Does eating raw food that's edible (like a dead rat corpse) require a confirmation?

Eating a raw rat is disgusting. Should the engine ask "Are you sure?" or just commit?

**Options:**
- A) No confirmation — player typed it, player eats it, player suffers (NetHack school)
- B) Warning then confirmation — "The rat is raw and bloody. Eat it anyway?" (gentle)

**CBG recommends A.** The narration IS the warning. "Fur and blood. Profoundly wrong." teaches through consequence, not dialogue boxes. This is text IF, not a UI.

### Q4: Scatter vs. corpse-container for loot?

Phase 1 scatters items to the floor. But CBG's analysis shows MUDs use corpse-as-container for better gameplay (search, discovery, grave-robbing).

**Options:**
- A) Scatter to floor forever (simple)
- B) Items fall into corpse container → `search corpse` to access (richer gameplay)
- C) Start with A, migrate to B in Phase 2

**CBG recommends C.** Scatter is simpler for PoC. Corpse-container adds depth later.

### Q5: Should spoiled food be permanently inedible, or just very dangerous?

Current design: rotten corpse sets `edible = false`. Dead end.

**Options:**
- A) Rotten = inedible (clean, simple, clear signal)
- B) Rotten = edible with severe consequences (NetHack school: you CAN eat anything if you're desperate enough)

**CBG recommends B.** The NetHack approach is more interesting. A desperate player should be able to eat rotten meat and suffer food poisoning. The sensory system already warns them. Closing the option removes player agency.

### Q6: Transfer-contents flag — should the corpse hold the creature's items, or scatter them?

Wayne's directive says creatures drop loot. But the mechanism differs:

**Options:**
- A) `transfer_contents = true` → items go INSIDE the corpse container → player searches to find
- B) `transfer_contents = false` → items scatter to floor → immediately visible
- C) Per-creature choice — rat: transfer (tiny items hidden in corpse). Skeleton: scatter (armor clatters to floor).

**CBG recommends C.** Let each creature's `.lua` file decide. A rat hiding stolen cheese makes sense (search the body). A skeleton's armor clattering to the floor makes sense (immediate discovery). The flag is already in the mutation metadata — use it.

### Q7: Phase 1 creature roster — which creatures get food chains?

For PoC, how many creature types need the full kill→corpse→cook chain?

**CBG recommends: rat only for Phase 1.** One creature with the full mutation chain proves the system. Add wolf, spider, chicken in Phase 2. Keep the PoC laser-focused.

### Q8: Nutrition as buff vs. healing?

The food-system-plan says "food is a buff, not survival." The creature-inventory-plan implies healing. Which is it?

**CBG recommends: both.** Nutrition is a buff (Valheim model — no hunger stat, eating is strategic). But cooked food also heals HP (small amount). Eating is opportunity, not obligation. The player never starves but benefits from eating. Align with D-FOOD-SYSTEMS-RESEARCH conclusion.

---

## 12. Scaling Path

### Phase 1: Proof of Concept (Rat + Cheese)

**Goal:** One creature (rat) with the full mutation chain. One existing food object (cheese-wedge) for comparison. `cook` verb functional.

| Deliverable | Owner | Effort |
|-------------|-------|--------|
| `mutations.die` on rat.lua | Flanders | 2 lines |
| `dead-rat.lua` (object, edible, spoilage FSM) | Flanders | ~60 lines |
| `cooked-rat-meat.lua` (object, edible, safe) | Flanders | ~40 lines |
| `cook` verb handler + aliases | Smithers | ~40 lines in crafting.lua |
| `cookable` check in `eat` handler | Smithers | 2 lines in survival.lua |
| Kill handler → mutation trigger | Bart | ~15 lines in damage path |
| Kitchen hearth object (fire_source) | Flanders + Moe | 1 object + room wiring |
| Tests: cook, eat raw, eat cooked, spoilage | Nelson | ~6 test cases |

**Estimated effort:** 1–2 sessions. Zero engine module rewrites. All work is metadata + verb handlers.

**Acceptance criteria:**
1. Kill rat → dead-rat object appears at rat's location
2. `eat dead rat` → nausea + low nutrition
3. `cook dead rat` (with fire) → cooked-rat-meat appears
4. `cook dead rat` (no fire) → "You need a fire source"
5. `eat cooked rat meat` → good nutrition + healing
6. Dead rat spoils over time: fresh → bloated → rotten
7. Rotten rat eating → food poisoning

### Phase 2: Full Food + Cooking

**Goal:** Complete Level 1 food roster (7 items from food-system-plan), butchery verb, expanded creature chains.

| Deliverable | Owner |
|-------------|-------|
| 7 food objects (.lua files) from food-system-plan §8 | Flanders |
| `butcher` verb handler (tool-gated) | Smithers |
| `raw-rat-meat.lua`, `rat-bones.lua` (butchery outputs) | Flanders |
| Food-poisoning injury type | Flanders |
| 2 new materials (meat, bread) | Flanders |
| Creature inventory metadata on skeleton-warrior | Flanders |
| Inventory → room instantiation on death | Bart |
| Food effects processing in eat handler | Smithers |
| Expanded test suite (~20 tests) | Nelson |

**Dependencies:** Phase 1 complete. Kitchen room exists.

### Phase 3: Recipes, Multi-Ingredient Cooking, Loot Tables

**Goal:** Multi-ingredient recipes (meat + grain = stew). Loot table randomization. Preservation mechanics.

| Feature | Description |
|---------|-------------|
| **Recipes** | Combine 2+ ingredients at fire → specific dish. `crafting.cook.ingredients = { "meat", "grain" }` |
| **Loot tables** | Weighted probability per creature type. Random bonus drops. |
| **Preservation** | Drying rack + meat + time → jerky (never spoils). Smoking for long shelf life. |
| **Butchery byproducts** | Bones → crafting material. Skin → leather (future). Fat → candle fuel (future). |

**Dependencies:** Phase 2 complete. NPC system Phase 1 for bait mechanic.

### Phase 4: World Economy + Advanced Food

**Goal:** NPC food trade. Tavern meals. Cooking skill. Food quality tiers.

This phase is distant and deliberately vague. It depends on NPC system maturity, world expansion beyond Level 1, and player economy design.

---

## 13. Agent Assignments

| Agent | Department | Responsibility |
|-------|-----------|---------------|
| **CBG** (this doc) | Design | Design plan, open questions, scaling path |
| **Bart** | Engineering | Kill handler → mutation trigger, inventory instantiation on death |
| **Smithers** | Engineering | `cook` verb handler, `cookable` check in eat, `butcher` verb (Phase 2) |
| **Flanders** | Design | All `.lua` object files (dead-rat, cooked-rat-meat, food items, skeleton-remains) |
| **Moe** | Design | Kitchen room with hearth, food placement in Level 1 rooms |
| **Nelson** | QA | Test suite: mutation chains, cooking, eating, spoilage, loot drops |
| **Sideshow Bob** | Design | Cooking puzzles (bait the rat, feed the prisoner, poison the soup) |
| **Brockman** | Documentation | Document food metadata convention, cooking verb usage |

---

## Cross-References

| Document | Relevance |
|----------|-----------|
| `plans/food-system-design.md` | Prior food design (superseded by this plan for scope; details still valid) |
| `plans/creature-inventory-plan.md` | Prior loot design (superseded by this plan for scope; details still valid) |
| `plans/combat-system-plan.md` | Combat → death → mutation trigger |
| `.squad/decisions/inbox/bart-food-architecture.md` | Bart's A+B hybrid recommendation |
| `.squad/decisions/inbox/bart-cooking-craft-architecture.md` | Bart's cook verb architecture |
| `.squad/decisions/inbox/cbg-food-creature-design.md` | CBG's creature→food analysis |
| `.squad/decisions/inbox/frink-cooking-gates-research.md` | 7-game cooking research |
| `.squad/decisions/inbox/frink-creature-loot-research.md` | 6-game loot research |
| `docs/architecture/objects/core-principles.md` | Principles 0, 1, 8, 9, D-14 |
| `src/engine/mutation/init.lua` | Mutation API |
| `src/engine/verbs/crafting.lua` | Existing craft pattern (sew) |
| `src/engine/verbs/survival.lua` | Existing eat/drink handlers |

---

*Filed by Comic Book Guy, Creative Director, after reading 200+ KB of cross-referenced design documents. Worst. Synthesis exercise. Ever. Best. Unified plan. Always.*
