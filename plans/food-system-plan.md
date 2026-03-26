# Food System Design Plan

**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-07-14  
**Status:** Draft — pending Wayne review  
**Scope:** Level 1 food system, scaling path to full implementation  
**Dependencies:** NPC system (rat hunger drives), effects pipeline, FSM, mutation engine

---

## Table of Contents

1. [Design Philosophy](#1-design-philosophy)
2. [Food as Objects](#2-food-as-objects)
3. [Food States (FSM)](#3-food-states-fsm)
4. [Sensory Integration](#4-sensory-integration)
5. [Cooking System](#5-cooking-system)
6. [Food & Creatures](#6-food--creatures)
7. [Food & Health](#7-food--health)
8. [First Food Items](#8-first-food-items)
9. [Verb Extensions](#9-verb-extensions)
10. [Scaling Path](#10-scaling-path)
11. [Open Questions](#11-open-questions)

---

## 1. Design Philosophy

### 1.1 The Valheim Model: Empowerment, Not Punishment

Food in this game follows the Valheim philosophy: **eating is a buff, not eating is neutral**. The player never starves. There is no hunger meter ticking toward death. Food is a strategic resource — eating the right thing at the right time gives you an edge.

This is a deliberate rejection of the NetHack starvation clock. In a text adventure where inventory is limited to two hands, forcing players to carry rations would crowd out puzzle-critical items. Food should make players *want* to eat, not *have* to.

**Core principle:** Food is opportunity, not obligation.

### 1.2 Sensory-First Design

Food integrates directly with the existing sensory system (D-SENSORY). Every food item is, first and foremost, an object you can SMELL, FEEL, TASTE, and LOOK at. The senses aren't decorative — they're the player's primary tool for evaluating food safety:

| Sense | Role in Food System | Risk |
|-------|---------------------|------|
| **SMELL** | Safe identification — reveals freshness, cooking state, ingredients | None |
| **FEEL** | Texture identification — raw vs. cooked, spoiled vs. fresh, temperature | None |
| **TASTE** | Chemical identification — flavor, poison, quality | **Dangerous** |
| **LOOK** | Visual identification — color, mold, steam, char | Requires light |

The philosophy mirrors the poison bottle: SMELL warns you. TASTE commits you. This creates meaningful choice without requiring a food encyclopedia.

### 1.3 Mutation IS Cooking (D-14 Alignment)

When the player cooks a raw chicken leg over a fire, the engine doesn't set `chicken.cooked = true`. It rewrites `raw-chicken.lua` → `cooked-chicken.lua`. The code IS the state. The cooked chicken is a fundamentally different object with different sensory descriptions, different effects, different material properties.

This is the Prime Directive (D-14) applied to food. No state flags. Code mutation.

### 1.4 Dwarf Fortress Lessons, Simplified

From DF we take:
- **Food has identity** — not generic "rations" but specific items with flavor
- **Cooking transforms ingredients** — raw → cooked is a meaningful act
- **Spoilage creates urgency** — food decays, rewarding preparation and timing
- **Food attracts creatures** — the rat smells your cheese and comes investigating

From DF we deliberately leave behind:
- Complex nutrition tracking (too granular for text adventure)
- Farming and agriculture (out of scope for dungeon crawl)
- Meal quality ratings (unnecessary UI burden)
- Brewing pipelines (maybe later, not V1)

---

## 2. Food as Objects

### 2.1 Template: `consumable`

Food items use the existing object system (Principle 1, 2, 8). No special engine code — food declares its behavior via metadata, and the engine executes it.

A new template isn't strictly required. Food items inherit from `small-item` (most food is portable and hand-sized) and declare food-specific fields. However, for clarity and future extensibility, a `consumable` category marker is recommended.

**Required fields for all food objects:**

```lua
return {
    guid = "{windows-guid}",
    template = "small-item",
    id = "raw-chicken",
    name = "a raw chicken leg",
    keywords = {"chicken", "chicken leg", "raw chicken", "meat", "poultry"},
    description = "A plump, pale chicken leg with goosebumped skin. Pink juice weeps from where it was severed.",

    -- PHYSICAL
    size = 1,
    weight = 0.3,
    portable = true,
    material = "meat",                   -- new material (see §2.2)

    -- FOOD PROPERTIES (Principle 8: metadata, not engine code)
    edible = true,                       -- flags this for `eat` verb
    food = {
        category = "meat",               -- meat | grain | fruit | herb | dairy | drink
        cookable = true,                 -- can be cooked with fire_source
        cooked_form = "cooked-chicken",  -- mutation target when cooked
        spoil_time = 60,                 -- ticks until fresh → spoiled (0 = never spoils)
        nutrition = 0,                   -- raw meat gives no benefit (must cook)
        effects = {},                    -- effects applied on eat (empty = none)
    },

    -- SENSORY (MANDATORY: on_feel for darkness)
    on_feel = "Cold, clammy skin with tiny bumps. Slippery with moisture. A raw joint of meat.",
    on_smell = "Raw poultry — faintly metallic, slightly sweet. Not rotten, but not appetizing.",
    on_listen = "Silent.",
    on_taste = "Raw and bloody. Your stomach lurches.",
    on_taste_effect = {
        type = "add_status",
        status = "nauseated",
        duration = 8,
        message = "A wave of nausea rolls through you."
    },

    -- FSM (spoilage lifecycle)
    initial_state = "fresh",
    _state = "fresh",
    states = { ... },       -- see §3
    transitions = { ... },  -- see §3
}
```

### 2.2 New Materials

The material system (`src/engine/materials/`) needs food-specific materials. These integrate with the existing material registry — each is a new `.lua` file in `src/meta/materials/`.

| Material | Density | Ignition | Hardness | Flexibility | Flammability | Notes |
|----------|---------|----------|----------|-------------|-------------|-------|
| **meat** | 1050 | 300 | 1 | 0.6 | 0.15 | Raw animal flesh |
| **bread** | 350 | 250 | 2 | 0.3 | 0.4 | Baked grain product |
| **fruit** | 900 | 350 | 1 | 0.5 | 0.1 | Plant fruit |
| **cheese** | 1100 | 350 | 3 | 0.4 | 0.1 | Dairy solid |
| **dried-herb** | 200 | 200 | 1 | 0.2 | 0.7 | Dried plant matter |

These are not all needed for V1. Start with `meat` and `bread`; add others as food items require them.

### 2.3 The `food` Table Convention

Every food object declares a `food = {}` table in its metadata. This is the single source of truth for the engine's food-related logic. The engine reads this table — it never contains object-specific code (Principle 8).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `category` | string | Yes | One of: `meat`, `grain`, `fruit`, `herb`, `dairy`, `drink` |
| `cookable` | bool | No | Can this be cooked? Default `false` |
| `cooked_form` | string | If cookable | Object ID to mutate into when cooked |
| `spoil_time` | number | No | Ticks until spoilage. `0` or `nil` = never spoils |
| `nutrition` | number | No | Buff strength when eaten (0–100 scale) |
| `effects` | table | No | Array of effect tables applied on consumption |
| `bait_value` | number | No | How attractive to creatures (0–100). See §6 |
| `bait_target` | string | No | Creature category attracted (`rodent`, `insect`, etc.) |

---

## 3. Food States (FSM)

### 3.1 The Spoilage Lifecycle

Food objects use the existing FSM engine (`src/engine/fsm/init.lua`) for state progression. No new engine code needed — food declares its states and transitions, and the FSM tick drives them forward.

```
    ┌──────────┐    cook     ┌──────────┐
    │   FRESH  │────────────▶│  COOKED  │
    │ (raw)    │             │          │
    └────┬─────┘             └────┬─────┘
         │                        │
         │ spoil_time              │ spoil_time (longer)
         ▼                        ▼
    ┌──────────┐             ┌──────────┐
    │ SPOILED  │             │ SPOILED  │
    │ (raw)    │             │ (cooked) │
    └──────────┘             └──────────┘
```

**Key insight:** Cooking resets and extends the spoilage timer. This is historically accurate (cooking as preservation) and creates a strategic reason to cook food early.

### 3.2 State Definitions

Every cookable food item declares these states:

```lua
states = {
    fresh = {
        description = "A plump, pale chicken leg. It looks fresh.",
        on_smell = "Raw poultry — faintly metallic, slightly sweet.",
        on_feel = "Cold, clammy skin with tiny bumps.",
        room_presence = "A raw chicken leg sits here, glistening.",
    },
    spoiled = {
        description = "A chicken leg gone grey-green at the edges. Flies orbit it lazily.",
        on_smell = "The unmistakable reek of rotting meat. Your eyes water.",
        on_feel = "Slimy. The skin slides under your fingers. Warm to the touch.",
        on_taste = "You gag before it reaches your tongue. The smell alone is punishment.",
        room_presence = "A spoiled chicken leg festers here. Flies buzz around it.",
        on_taste_effect = {
            type = "inflict_injury",
            injury_type = "food-poisoning",
            damage = 8,
            message = "Your stomach rebels violently."
        },
    },
},
transitions = {
    { from = "fresh", to = "spoiled", verb = "_tick", condition = "timer",
      timer = 60, message = "The chicken leg has begun to turn." },
},
```

**Non-cookable items** (bread, cheese, dried herbs) may have simpler lifecycles:
- Bread: `fresh` → `stale` → `moldy` (stale is still edible but less nutritious)
- Cheese: `fresh` → `aged` (aged is *better*, not worse — a nice inversion)
- Dried herbs: no spoilage (already preserved)

### 3.3 Spoilage Timers

Spoilage uses the existing FSM timer mechanism (`fsm.start_timer`, `fsm.stop_timer`). The `timer` field on a transition tells the FSM engine how many ticks until the transition fires automatically.

| Food | Fresh → Spoiled | Cooked → Spoiled | Notes |
|------|-----------------|-------------------|-------|
| Raw meat | 60 ticks | 120 ticks (cooked) | Cooking doubles shelf life |
| Bread | 120 ticks → stale, 240 → moldy | N/A | Bread doesn't cook further |
| Cheese | 200 ticks → aged | N/A | Aging improves it |
| Fruit | 80 ticks | N/A | Fruit spoils relatively fast |
| Dried herbs | Never | N/A | Already preserved |

At the game's time scale (1 real hour = 1 game day), 60 ticks ≈ ~2.5 real minutes of holding the item. This creates gentle urgency without panic.

### 3.4 Spoilage as Mutation

When food transitions to `spoiled`, the FSM applies state changes inline (new description, new sensory text, new effects). For dramatic transformations — bread becoming moldy, fruit becoming rotten — full mutation can replace the object entirely:

```lua
mutations = {
    spoil = {
        becomes = "moldy-bread",
        message = "The bread has gone fuzzy with grey-green mold.",
    },
},
```

This follows D-14: the moldy bread is a different object with different code. The code IS the state.

---

## 4. Sensory Integration

### 4.1 Food Identification Through Senses

Food is discovered the same way everything else is: by using your senses. This is especially critical at 2 AM when the game starts and the player has no light.

**The Sensory Funnel for Food:**

```
SMELL (safe)     →  "Something smells like roasted meat nearby."
  ↓
FEEL (safe)      →  "Warm, firm, oily surface. A cooked piece of meat."
  ↓
LOOK (needs light) → "A charred chicken leg on a wooden plate."
  ↓
TASTE (risky!)   →  "Rich, smoky, well-seasoned. Delicious."
                     OR: "Bitter, acrid, WRONG — *cough*"
```

**Design rule:** A cautious player can fully identify any food item without risk by using SMELL + FEEL. TASTE provides confirmation and flavor text but carries risk (food poisoning from spoiled food, poison from tampered food).

### 4.2 State-Dependent Sensory Text

Every food state has unique sensory descriptions. This is where the writing does the heavy lifting:

| State | SMELL | FEEL | TASTE |
|-------|-------|------|-------|
| **Fresh (raw)** | "Raw poultry — faintly metallic" | "Cold, clammy, bumpy skin" | "Raw and bloody" (nausea risk) |
| **Cooked** | "Roasted meat — smoky, savory" | "Hot, crispy skin, firm flesh" | "Rich, well-cooked, satisfying" |
| **Spoiled** | "Rotting meat — eyes water" | "Slimy, warm, skin slides" | "IMMEDIATE GAG" (food poisoning) |

The sensory system IS the food identification system. No separate "identify food" mechanic needed.

### 4.3 Dark Room Food Discovery

At 2 AM, the player navigates by non-visual senses. Food works the same way:

1. Player enters pantry: *"You smell something. Meat, maybe. And something sweet — fruit?"*
2. `SMELL` → *"Definitely meat, hanging somewhere to your left. And below it, the sugary scent of dried fruit."*
3. `FEEL shelf` → *"Your hand finds a wooden shelf. On it: something round and firm (fruit?), something wrapped in cloth (bread?), and something cold and slick (raw meat)."*
4. `TAKE bread` → *"You take the cloth-wrapped bundle. It feels like a small loaf."*

The room's `on_smell` field can hint at food presence. Individual food items provide their own sensory detail.

### 4.4 Smell Radius and Creature Interaction

Food with strong smells (`bait_value > 0`) emits a stimulus that creatures can detect within their `awareness.smell_range`. The rat's smell range is 3 rooms — drop a piece of raw meat and the rat can smell it from three rooms away.

This creates the bait mechanic organically through existing creature awareness (§6).

---

## 5. Cooking System

### 5.1 The Cooking Verb

Cooking requires a `fire_source` tool and a raw food item. The engine checks for the tool capability the same way it checks for `fire_source` when lighting a candle.

**Player interaction:**

```
> cook chicken
You hold the chicken leg over the flames. Fat sizzles and pops.
The raw meat browns and crisps. The smell is incredible.

> cook chicken with fire
(same result — parser resolves "fire" to fire_source)
```

**Engine flow:**

1. Player types `cook chicken`
2. Parser resolves `chicken` → `raw-chicken` object in inventory
3. `cook` verb handler checks: `obj.food and obj.food.cookable`
4. Verb handler searches inventory/room for `fire_source` capability
5. If fire_source found: mutation engine rewrites `raw-chicken` → `cooked-chicken`
6. If no fire_source: *"You need a fire to cook with."*

### 5.2 Cooking as Mutation

Cooking is the cleanest application of D-14. The raw food object is destroyed and replaced by a cooked food object:

```
raw-chicken.lua                    cooked-chicken.lua
─────────────                      ──────────────────
id = "raw-chicken"           →     id = "cooked-chicken"
name = "a raw chicken leg"   →     name = "a roasted chicken leg"
material = "meat"            →     material = "meat"
on_smell = "raw poultry..."  →     on_smell = "roasted meat, smoky..."
food.nutrition = 0           →     food.nutrition = 40
food.spoil_time = 60         →     food.spoil_time = 120
edible = true                →     edible = true
food.effects = {}            →     food.effects = { heal(5) }
```

The cooked version is a completely new object definition. Different name, different description, different sensory text, different nutrition, longer spoilage, healing effect. The code IS the state.

### 5.3 Fire Sources

Existing fire sources already in the game:

| Source | Capability | Duration | Notes |
|--------|-----------|----------|-------|
| **match-lit** | `fire_source` | ~3 ticks | Too brief for cooking realistically, but functional |
| **candle-lit** | `casts_light` | Long | Not a cooking fire — see open question §11 |

For Level 1, cooking requires access to a proper fire source. Candidates:
- **Fireplace** in a kitchen or common room (furniture, `fire_source` when lit)
- **Brazier** in cellar (furniture, `fire_source` when lit)
- **Campfire** if outdoor area exists

A fire source for cooking should be a furniture-class object with `fire_source = true` in its lit state. The player lights it (with match/candle), then cooks food over it.

### 5.4 Cooking Failures

Not all cooking attempts succeed. Cooking with inadequate heat or for too long could produce:

- **Charred food:** Overcooked mutation → `charred-chicken.lua` (edible but low nutrition, bad taste)
- **Partially cooked:** If fire goes out mid-cook → remains raw (no mutation)

For V1, keep it simple: cooking is binary success. The `cook` verb either transforms the food or fails (no fire source). Charring and partial cooking are scaling-path features.

---

## 6. Food & Creatures

### 6.1 The Bait Mechanic

The rat specification (NPC System Plan §6) defines:
- `drives.hunger.value` — current hunger (0–100)
- `drives.hunger.satisfy_threshold = 80` — seeks food when hunger > 80
- `drives.hunger.decay_rate = 2` — gets hungrier by 2 per tick
- `awareness.smell_range = 3` — can smell food 3 rooms away

Food objects declare `food.bait_value` (0–100) indicating how attractive they are to creatures. When a food item is placed in a room, the engine can emit a `food_present` stimulus. Creatures within smell range evaluate whether to investigate based on their hunger drive.

### 6.2 Bait Value by Food Type

| Food | Bait Value | Target | Notes |
|------|-----------|--------|-------|
| Raw meat | 80 | rodent, carnivore | Strong smell, irresistible to rats |
| Cooked meat | 60 | rodent, carnivore | Still attractive but less pungent |
| Cheese | 90 | rodent | The classic mouse trap bait |
| Bread | 40 | rodent, omnivore | Mild attraction |
| Fresh fruit | 30 | omnivore, insect | Sweet but not overwhelming |
| Spoiled food | 95 | rodent, insect | Rotting food is the strongest bait |
| Dried herbs | 5 | none | Almost no bait value |

### 6.3 Emergent Bait Behaviors

These emerge from the drive system, not from scripts:

1. **Rat follows food trail** — Player drops raw meat in room A. Rat in room C smells it (smell_range = 3). Rat's hunger > satisfy_threshold → rat navigates toward food.
2. **Baited trap** — Player puts cheese in rat trap. Rat investigates. Trap springs. (Requires trap object with bait slot.)
3. **Distraction** — Player drops food in hallway to lure rat out of room, then sneaks past.
4. **Spoiled food attracts pests** — Dropped food eventually spoils, becoming a stronger attractant. Player who litters creates pest problems.
5. **Feeding calms creature** — If player drops food near a hungry rat, rat eats the food, hunger drops, and rat becomes less skittish (lower fear → less likely to flee).

### 6.4 The `feed` Interaction

```
> give chicken to rat
> feed rat
> drop cheese (near rat)
```

Feeding is not a new verb — it emerges from existing verbs:
- `drop` food near a creature → creature's hunger drive evaluates the food
- `give` food to creature → same evaluation, more intentional
- Creature AI decides whether to eat, flee, or ignore based on drives

The NPC tick evaluates: *"Is there food in my room? Is my hunger > satisfy_threshold? Is my fear low enough to approach?"*

---

## 7. Food & Health

### 7.1 Healing Through Food

Eating cooked food provides a healing buff. This uses the existing effects pipeline (`src/engine/effects.lua`) — no new engine code.

```lua
-- In cooked-chicken.lua
food = {
    effects = {
        { type = "narrate", message = "Warmth spreads through your belly. You feel restored." },
        { type = "mutate", target = "self", field = "health",
          value = function(h) return math.min(h + 5, 100) end },
    },
},
```

**Healing scale:**

| Food Quality | Healing | Duration | Example |
|-------------|---------|----------|---------|
| Raw edible | 0 | — | Raw fruit (safe but no benefit) |
| Cooked simple | 3–5 HP | Instant | Roasted chicken, toasted bread |
| Cooked quality | 8–12 HP | Instant | Well-prepared meal (future) |
| Medicinal herb | 0 HP + cure | Removes status | Mint tea cures nausea |
| Spoiled | -5 to -10 HP | Over time | Food poisoning |

### 7.2 Food Poisoning

Eating spoiled food triggers the injury system via `on_taste_effect` or `food.effects`:

```lua
-- In spoiled-chicken.lua (the spoiled state or mutated object)
food = {
    effects = {
        { type = "inflict_injury", injury_type = "food-poisoning", damage = 8 },
        { type = "add_status", status = "nauseated", duration = 12 },
        { type = "narrate", message = "Your stomach heaves. That was a terrible mistake." },
    },
},
```

**New injury type needed:** `food-poisoning` in `src/meta/injuries/`

```lua
-- src/meta/injuries/food-poisoning.lua
return {
    guid = "{generate-guid}",
    id = "food-poisoning",
    name = "food poisoning",
    description = "Cramps, nausea, and cold sweats from eating tainted food.",
    severity = "moderate",
    duration = 20,       -- ticks until recovery
    effects = {
        { type = "add_status", status = "nauseated", duration = 12 },
        { type = "add_status", status = "weakened", duration = 20 },
    },
    on_feel = "Your guts twist and clench.",
    on_recovery = "The worst has passed. Your stomach still feels fragile.",
}
```

### 7.3 Medicinal Herbs

Certain food items act as medicine rather than nutrition:

- **Mint leaves:** Cure nausea (`remove_status: nauseated`)
- **Willow bark:** Reduce pain (future pain system)
- **Honey:** Slow-heal over time (future HoT effect)

For V1, mint leaves are the first medicinal herb — they directly counter food poisoning's nausea effect, teaching players that the food system has cures as well as dangers.

### 7.4 Taste-Risk Spectrum

The existing sensory design philosophy applies perfectly:

| Action | Risk | Reward |
|--------|------|--------|
| SMELL food | None | Identifies freshness, cooking state |
| FEEL food | None | Identifies temperature, texture |
| TASTE food | Low-Medium | Confirms identity, flavor; spoiled food causes nausea |
| EAT food | Medium-High | Full nutrition/healing; spoiled food causes food poisoning |

**The escalation ladder:** SMELL → FEEL → TASTE → EAT. Each step gives more information but carries more risk. A cautious player smells before tasting, tastes before eating. An impatient player eats first and asks questions later. Both are valid playstyles with natural consequences.

---

## 8. First Food Items

### 8.1 Level 1 Food Roster

These 7 items provide a complete food system tutorial within Level 1's existing 7-room layout. Each teaches a different food mechanic.

#### Item 1: Bread Roll

**Teaches:** Basic eating, safe food, simplest case.

```lua
return {
    guid = "{generate-guid}",
    template = "small-item",
    id = "bread-roll",
    name = "a crusty bread roll",
    keywords = {"bread", "roll", "bread roll", "food", "loaf"},
    description = "A small, round bread roll with a golden-brown crust dusted with flour. It looks freshly baked.",

    size = 1,
    weight = 0.15,
    portable = true,
    material = "bread",

    edible = true,
    food = {
        category = "grain",
        cookable = false,
        spoil_time = 120,
        nutrition = 15,
        effects = {
            { type = "narrate", message = "The bread is dense and satisfying. A simple comfort." },
        },
    },

    on_feel = "A firm, round shape with a rough crust. Slightly warm. Breadcrumbs flake off under your fingers.",
    on_smell = "Fresh bread — yeasty, warm, with a hint of toasted flour. Comforting.",
    on_listen = "The crust crackles faintly when you squeeze it.",
    on_taste = "Chewy crust, soft interior. Plain but wholesome. Your stomach welcomes it.",

    initial_state = "fresh",
    _state = "fresh",
    states = {
        fresh = {
            description = "A crusty bread roll, golden-brown and dusted with flour.",
            room_presence = "A bread roll sits here, dusted with flour.",
        },
        stale = {
            description = "A bread roll gone hard and pale. The crust has lost its crackle.",
            room_presence = "A stale bread roll sits here, forgotten.",
            on_smell = "Faint wheat. The fresh-bread smell is gone.",
            on_feel = "Hard as a rock. You could hammer nails with this.",
            on_taste = "Dry, chalky, tasteless. Edible, but joyless.",
            food = { nutrition = 5 },
        },
        moldy = {
            description = "A bread roll furred with grey-green mold. Tiny white filaments web the crust.",
            room_presence = "A moldy bread roll sits here. Flies circle it.",
            on_smell = "Musty, sour. The unmistakable smell of mold.",
            on_feel = "Fuzzy patches on a hard surface. Damp in places.",
            on_taste = "You barely get it near your mouth before gagging.",
            on_taste_effect = { type = "add_status", status = "nauseated", duration = 6 },
            food = { nutrition = 0, bait_value = 70, bait_target = "rodent" },
        },
    },
    transitions = {
        { from = "fresh", to = "stale", verb = "_tick", condition = "timer",
          timer = 120, message = "The bread roll has gone stale." },
        { from = "stale", to = "moldy", verb = "_tick", condition = "timer",
          timer = 120, message = "Mold has crept across the bread roll." },
    },
}
```

#### Item 2: Raw Chicken Leg

**Teaches:** Cooking requirement, raw-food danger, mutation.

```lua
return {
    guid = "{generate-guid}",
    template = "small-item",
    id = "raw-chicken",
    name = "a raw chicken leg",
    keywords = {"chicken", "chicken leg", "raw chicken", "meat", "poultry", "drumstick"},
    description = "A plump, pale chicken leg with goosebumped skin. Pink juice weeps from where it was severed.",

    size = 1,
    weight = 0.3,
    portable = true,
    material = "meat",

    edible = true,
    food = {
        category = "meat",
        cookable = true,
        cooked_form = "cooked-chicken",
        spoil_time = 60,
        nutrition = 0,
        bait_value = 80,
        bait_target = "rodent",
        effects = {
            { type = "add_status", status = "nauseated", duration = 10 },
            { type = "narrate", message = "Raw chicken. Your body rejects it almost immediately." },
        },
    },

    on_feel = "Cold, clammy skin with tiny bumps. Slippery with moisture. A raw joint of meat.",
    on_smell = "Raw poultry — faintly metallic, slightly sweet. Not rotten, but not appetizing.",
    on_listen = "Silent.",
    on_taste = "Raw and bloody. Slippery, cool, profoundly wrong. Your stomach clenches.",
    on_taste_effect = { type = "add_status", status = "nauseated", duration = 4 },

    initial_state = "fresh",
    _state = "fresh",
    states = {
        fresh = {
            description = "A plump, pale chicken leg. It looks fresh.",
            room_presence = "A raw chicken leg sits here, glistening with moisture.",
        },
        spoiled = {
            description = "A chicken leg gone grey-green. The smell is aggressive.",
            room_presence = "A spoiled chicken leg festers here. Flies orbit it.",
            on_smell = "The unmistakable reek of rotting meat. Your eyes water.",
            on_feel = "Slimy. The skin slides under your fingers. Unpleasantly warm.",
            food = { nutrition = 0, bait_value = 95, bait_target = "rodent" },
        },
    },
    transitions = {
        { from = "fresh", to = "spoiled", verb = "_tick", condition = "timer",
          timer = 60, message = "The chicken leg has begun to turn. The smell thickens." },
    },

    mutations = {
        cook = { becomes = "cooked-chicken", message = "Fat sizzles and pops as the chicken cooks. The skin crisps and browns." },
    },
}
```

#### Item 3: Cooked Chicken Leg (mutation target)

**Teaches:** Reward for cooking — healing, good flavor, longer shelf life.

```lua
return {
    guid = "{generate-guid}",
    template = "small-item",
    id = "cooked-chicken",
    name = "a roasted chicken leg",
    keywords = {"chicken", "chicken leg", "roasted chicken", "cooked chicken", "meat", "drumstick"},
    description = "A beautifully roasted chicken leg, skin crackling and brown. Steam rises from the juicy flesh beneath.",

    size = 1,
    weight = 0.25,
    portable = true,
    material = "meat",

    edible = true,
    food = {
        category = "meat",
        cookable = false,
        spoil_time = 120,
        nutrition = 40,
        bait_value = 60,
        bait_target = "rodent",
        effects = {
            { type = "narrate", message = "Rich, smoky, deeply satisfying. Warmth spreads through you." },
            { type = "mutate", target = "player", field = "health",
              value = 5, op = "add" },
        },
    },

    on_feel = "Hot, crispy skin over firm flesh. Greasy to the touch. A cooked drumstick.",
    on_smell = "Roasted meat — smoky, savory, with rendered fat. Your mouth waters.",
    on_listen = "The skin crackles faintly. Juices pop beneath the surface.",
    on_taste = "Rich, smoky, well-seasoned by fire. The meat pulls clean from the bone.",

    initial_state = "fresh",
    _state = "fresh",
    states = {
        fresh = {
            description = "A roasted chicken leg, still steaming. The skin is perfectly crisp.",
            room_presence = "A roasted chicken leg sits here, steaming gently.",
        },
        cold = {
            description = "A cold roasted chicken leg. The fat has congealed on the surface.",
            room_presence = "A cold chicken leg sits here, grease congealed.",
            on_feel = "Cool, slightly tacky with congealed fat. Still firm.",
            on_smell = "Cold roasted meat. Less aromatic but still recognizable.",
            food = { nutrition = 30 },
        },
        spoiled = {
            description = "A chicken leg gone grey and slick. The smell is vile.",
            room_presence = "A spoiled chicken leg sits here, grey and forgotten.",
            on_smell = "Rancid fat and decay. Don't.",
            on_feel = "Slick, soft, yielding. The bone shifts loosely inside.",
            food = { nutrition = 0, bait_value = 90 },
        },
    },
    transitions = {
        { from = "fresh", to = "cold", verb = "_tick", condition = "timer",
          timer = 30, message = "The chicken leg has cooled." },
        { from = "cold", to = "spoiled", verb = "_tick", condition = "timer",
          timer = 90, message = "The chicken leg has gone bad." },
    },
}
```

#### Item 4: Wedge of Cheese

**Teaches:** Non-cookable food, best rat bait, aging mechanic (food that improves).

```lua
return {
    guid = "{generate-guid}",
    template = "small-item",
    id = "cheese-wedge",
    name = "a wedge of hard cheese",
    keywords = {"cheese", "cheese wedge", "wedge", "cheddar", "food"},
    description = "A firm wedge of pale yellow cheese, rind darkened with age. Tiny crystalline specks glint in the paste.",

    size = 1,
    weight = 0.2,
    portable = true,
    material = "cheese",

    edible = true,
    food = {
        category = "dairy",
        cookable = false,
        spoil_time = 200,
        nutrition = 25,
        bait_value = 90,
        bait_target = "rodent",
        effects = {
            { type = "narrate", message = "Sharp, salty, crumbly. Remarkably satisfying." },
        },
    },

    on_feel = "A firm wedge with a waxy rind. Dense and cool. Slightly crumbly at the edges.",
    on_smell = "Sharp, tangy, unmistakably cheese. A rich, earthy pungency.",
    on_listen = "Silent.",
    on_taste = "Sharp, salty, with a crystalline crunch. Complex and deeply savory.",

    initial_state = "fresh",
    _state = "fresh",
    states = {
        fresh = {
            description = "A wedge of hard cheese, pale yellow with a dark rind.",
            room_presence = "A wedge of cheese sits here, smelling sharp.",
        },
        aged = {
            description = "The cheese has darkened and hardened. The crystalline specks are more pronounced.",
            room_presence = "A well-aged wedge of cheese sits here. The smell is powerful.",
            on_smell = "Intensely pungent. The sharpness has deepened into something almost meaty.",
            food = { nutrition = 35, bait_value = 95 },
        },
    },
    transitions = {
        { from = "fresh", to = "aged", verb = "_tick", condition = "timer",
          timer = 200, message = "The cheese has aged. If anything, it smells better." },
    },
}
```

#### Item 5: Dried Mint Leaves

**Teaches:** Medicinal herb, nausea cure, non-spoiling, safe identification via smell.

```lua
return {
    guid = "{generate-guid}",
    template = "small-item",
    id = "dried-mint",
    name = "a bundle of dried mint leaves",
    keywords = {"mint", "dried mint", "mint leaves", "herb", "herbs", "medicine"},
    description = "A small bundle of dried mint leaves, tied with twine. The leaves are curled and brittle but intensely fragrant.",

    size = 1,
    weight = 0.05,
    portable = true,
    material = "dried-herb",

    edible = true,
    food = {
        category = "herb",
        cookable = false,
        spoil_time = 0,     -- dried herbs don't spoil
        nutrition = 0,
        effects = {
            { type = "remove_status", status = "nauseated" },
            { type = "narrate", message = "Cool, sharp mint floods your mouth. Your stomach calms immediately." },
        },
    },

    on_feel = "Dry, papery leaves that crumble between your fingers. A small bundle tied with rough twine.",
    on_smell = "Bright, clean, unmistakably mint. Cool and penetrating even through the nose.",
    on_listen = "The dried leaves rustle and crackle faintly.",
    on_taste = "Intensely minty. A cooling wave rushes through your mouth and down your throat.",
}
```

#### Item 6: Wrinkled Apple

**Teaches:** Fruit category, moderate spoilage, safe to eat raw, darkness identification via smell.

```lua
return {
    guid = "{generate-guid}",
    template = "small-item",
    id = "wrinkled-apple",
    name = "a wrinkled apple",
    keywords = {"apple", "fruit", "wrinkled apple", "food"},
    description = "A small, red apple with wrinkled skin. Past its prime, but the flesh beneath still looks firm.",

    size = 1,
    weight = 0.15,
    portable = true,
    material = "fruit",

    edible = true,
    food = {
        category = "fruit",
        cookable = false,
        spoil_time = 80,
        nutrition = 10,
        bait_value = 30,
        bait_target = "omnivore",
        effects = {
            { type = "narrate", message = "Tart and slightly mealy, but refreshing. Better than nothing." },
        },
    },

    on_feel = "Round, slightly soft. The skin is loose and wrinkled. Cool to the touch.",
    on_smell = "Sweet, faintly alcoholic — the fermentation of overripe fruit. Still edible.",
    on_listen = "Silent.",
    on_taste = "Tart, mealy, with an edge of fermentation. Not great, but not bad.",

    initial_state = "fresh",
    _state = "fresh",
    states = {
        fresh = {
            description = "A wrinkled red apple, past its prime but edible.",
            room_presence = "A wrinkled apple sits here, slightly soft.",
        },
        rotten = {
            description = "A brown, mushy apple crawling with tiny fruit flies. Juice pools beneath it.",
            room_presence = "A rotten apple sits here, surrounded by tiny flies.",
            on_smell = "Vinegar and decay. Sickeningly sweet.",
            on_feel = "Soft, yielding, wet. Your thumb pushes through the skin. Something squirms inside.",
            on_taste_effect = { type = "add_status", status = "nauseated", duration = 6 },
            food = { nutrition = 0, bait_value = 70, bait_target = "insect" },
        },
    },
    transitions = {
        { from = "fresh", to = "rotten", verb = "_tick", condition = "timer",
          timer = 80, message = "The apple has gone soft and brown. Tiny flies orbit it." },
    },
}
```

#### Item 7: Waterskin

**Teaches:** Drink mechanic, container-based liquid, refillable.

```lua
return {
    guid = "{generate-guid}",
    template = "small-item",
    id = "waterskin",
    name = "a leather waterskin",
    keywords = {"waterskin", "water", "skin", "flask", "canteen", "drink"},
    description = "A worn leather waterskin, slightly damp with condensation. It sloshes when moved.",

    size = 1,
    weight = 0.5,
    portable = true,
    material = "leather",

    edible = false,
    drinkable = true,

    on_feel = "Soft, supple leather. Damp with condensation. It yields when squeezed — liquid inside.",
    on_smell = "Leather and faintly mineral water. Clean.",
    on_listen = "A gentle sloshing. There's liquid inside.",
    on_taste = "Cool, clean water with a faint leather tang. Refreshing.",

    initial_state = "full",
    _state = "full",
    states = {
        full = {
            description = "A leather waterskin, plump with water. It sloshes heavily.",
            room_presence = "A leather waterskin sits here, damp with condensation.",
            on_listen = "A heavy slosh. Nearly full.",
        },
        half = {
            description = "A leather waterskin, half-full. It sloshes loosely.",
            room_presence = "A half-empty waterskin sits here.",
            on_listen = "A loose slosh. About half full.",
            on_feel = "The leather sags. Less weight than before.",
        },
        empty = {
            description = "A flat, empty waterskin. The leather is wrinkled and dry.",
            room_presence = "An empty waterskin lies here, flat and wrinkled.",
            on_listen = "Nothing. It's empty.",
            on_feel = "Flat, dry leather. No weight. Empty.",
            on_taste = "You squeeze out a few drops. Barely anything.",
            drinkable = false,
        },
    },
    transitions = {
        { from = "full", to = "half", verb = "drink",
          message = "You drink deeply. Cool water slides down your throat.",
          effect = {
              { type = "narrate", message = "Refreshing. You feel better." },
              { type = "mutate", target = "player", field = "health", value = 2, op = "add" },
          },
        },
        { from = "half", to = "empty", verb = "drink",
          message = "You drain the last of the water. The skin goes flat.",
          effect = {
              { type = "narrate", message = "The last swallow. You'll need to find more." },
              { type = "mutate", target = "player", field = "health", value = 2, op = "add" },
          },
        },
        { from = "empty", to = "full", verb = "fill",
          requires_property = "water_source",
          message = "You hold the waterskin under the flow. It swells with cold water.",
        },
    },
}
```

### 8.2 Placement in Level 1

| Item | Room | Location | Discovery |
|------|------|----------|-----------|
| Bread roll | Kitchen / Pantry | On shelf | SMELL bread from hallway |
| Raw chicken | Kitchen | Hanging from hook (on_top of rack) | SMELL raw meat |
| Cheese wedge | Cellar / Pantry | On shelf | SMELL sharp cheese |
| Dried mint | Bedroom / Study | In drawer or pouch | FEEL papery bundle |
| Wrinkled apple | Kitchen | On table | FEEL round fruit |
| Waterskin | Bedroom | On nightstand or hook | LISTEN sloshing |
| Cooked chicken | N/A | Created by cooking raw chicken | — |

---

## 9. Verb Extensions

### 9.1 New Verb: `cook`

**File:** `src/engine/verbs/init.lua` (or `survival.lua` verb module)

```lua
handlers["cook"] = function(ctx, noun)
    local obj = find_in_inventory(ctx, noun)
    if not obj then
        if find_visible(ctx, noun) then
            print("You'll need to pick that up first.")
        else
            err_not_found(ctx)
        end
        return
    end

    if not (obj.food and obj.food.cookable) then
        print("You can't cook " .. (obj.name or "that") .. ".")
        return
    end

    -- Search for fire_source in room (furniture) or inventory
    local fire = find_capability(ctx, "fire_source")
    if not fire then
        print("You need a fire to cook with.")
        return
    end

    local target_id = obj.food.cooked_form
    if not target_id then
        print("You're not sure how to cook " .. (obj.name or "that") .. ".")
        return
    end

    -- Mutation: raw → cooked (D-14)
    local new_obj, err = mutation.mutate(ctx.registry, ctx.loader, obj.id, target_id, ctx.templates)
    if new_obj then
        local msg = (obj.mutations and obj.mutations.cook and obj.mutations.cook.message)
            or ("You cook the " .. (obj.name or "food") .. " over the fire.")
        print(msg)
    else
        print("Something goes wrong. The food doesn't cook properly.")
    end
end

handlers["roast"] = handlers["cook"]
handlers["grill"] = handlers["cook"]
handlers["fry"] = handlers["cook"]
```

### 9.2 Existing Verb: `eat` — Required Changes

The existing `eat` verb in `survival.lua` already handles `edible` objects. Changes needed:

1. **Process `food.effects`** — The existing handler removes the object but doesn't process the `food.effects` array. Add effects processing after consumption.
2. **Check spoilage state** — If the object's current FSM state has food overrides (e.g., `states.spoiled.food.effects`), use those instead of the base `food.effects`.
3. **Print nutrition feedback** — Brief message about how filling the food was.

```lua
-- After removing the object from registry:
if obj.food and obj.food.effects then
    for _, effect in ipairs(obj.food.effects) do
        effects.process(effect, {
            player = ctx.player,
            registry = ctx.registry,
            source = obj,
            source_id = obj.id,
        })
    end
end
```

### 9.3 Existing Verb: `drink` — No Changes Needed

The existing `drink` verb already handles FSM transitions with effects. The waterskin's `full → half → empty` transitions work within the existing system. No modifications required.

### 9.4 Verb Summary

| Verb | Status | Aliases | Notes |
|------|--------|---------|-------|
| `eat` | **Exists** — needs effects processing | consume, devour | Add `food.effects` pipeline |
| `drink` | **Exists** — works as-is | quaff, sip, swig | FSM-driven, effects-capable |
| `cook` | **New** | roast, grill, fry | Mutation-based, requires fire_source |
| `pour` | **Exists** — works as-is | splash, spill, dump | For liquids |
| `fill` | **Exists** (via FSM transition) | — | Waterskin refill via requires_property |
| `feed` | **Not needed** | — | Emerges from drop/give + creature AI |

---

## 10. Scaling Path

### Phase 1: Proof of Concept (Current Target)

**Goal:** 7 food items, cook verb, eat effects, spoilage FSM. Prove the system works within existing engine.

| Task | Effort | Dependencies |
|------|--------|-------------|
| Create 7 food object `.lua` files | Medium | None |
| Add `cook` verb handler | Small | Fire source object |
| Add effects processing to `eat` verb | Small | None |
| Create `food-poisoning` injury type | Small | None |
| Create 2 new materials (meat, bread) | Small | None |
| Add fire source furniture (fireplace or brazier) | Medium | Room placement |
| Place food items in Level 1 rooms | Small | Room definitions |

**Estimated effort:** 2–3 sessions.

### Phase 2: Creature Integration

**Goal:** Food attracts creatures. Bait mechanic works.

| Task | Effort | Dependencies |
|------|--------|-------------|
| Emit `food_present` stimulus when food placed/dropped | Medium | NPC stimulus system |
| Creature hunger drive evaluates nearby food | Medium | NPC drive system |
| Creature `eat` action removes food from room | Small | NPC action system |
| Rat trap with bait slot | Medium | Trap object design |

**Depends on:** NPC system implementation (Phase 1 of NPC plan).

### Phase 3: Expanded Recipes

**Goal:** Multi-ingredient cooking, prepared meals, brewing.

| Feature | Description |
|---------|-------------|
| **Recipe system** | Combine ingredients at fire → specific dish. Declared in metadata. |
| **Prepared meals** | Higher nutrition, better effects, require multiple ingredients |
| **Brewing** | Water + ingredient + time → tea, potions, ale |
| **Drying/preserving** | Rack + meat + time → jerky (never spoils, lower nutrition) |
| **Smoking** | Smokehouse + meat + fire → smoked meat (very long shelf life) |

### Phase 4: World Economy

**Goal:** Food as trade goods, NPC food preferences, tavern mechanics.

| Feature | Description |
|---------|-------------|
| **NPC food trade** | Buy/sell food with merchants |
| **Tavern meals** | Order food at tavern, social interaction |
| **Cooking skill** | Player gets better at cooking over time (burn rate decreases) |
| **Food quality tiers** | Simple / Quality / Masterwork (affects buff strength) |

---

## 11. Open Questions

These require Wayne's input before implementation:

### Q1: Can a candle cook food?

A lit candle has `casts_light = true` but not `fire_source = true`. Should a candle be usable for cooking? Historically, you can heat things over a candle flame, but it's impractical for cooking meat. **Recommendation:** No. Candles cast light but don't cook. Only dedicated fire sources (fireplace, brazier, campfire) have the `fire_source` capability for cooking. This preserves puzzle value — finding/lighting a proper fire becomes meaningful.

### Q2: Does eating raw fruit cause nausea?

Raw meat causes nausea. Raw fruit is safe to eat (it's fruit). But should raw vegetables or raw grain cause issues? **Recommendation:** Category-based rules:
- Raw fruit, herbs, cheese, bread → safe to eat
- Raw meat → nausea (must cook)
- Spoiled anything → food poisoning

### Q3: Should hunger exist as a player stat?

The current design says no — food is buffs, not survival. But a very gentle hunger indicator (*"You're feeling peckish"*) could nudge players toward eating without punishing them. **Recommendation:** Defer. Start with pure Valheim model (no hunger stat). Revisit after playtesting.

### Q4: How many fire sources in Level 1?

Level 1 has 7 rooms. How many should have fire sources for cooking?
- **1 fire source:** Creates a cooking "hub" — player must bring food to the kitchen. More puzzle-oriented.
- **2+ fire sources:** More convenient, less strategic.
**Recommendation:** 1 fire source (kitchen fireplace). Player discovers fire, discovers food, brings food to fire. Classic adventure game loop.

### Q5: Can creatures eat food the player has dropped?

If the rat eats the player's cheese, that's permanent loss (consumption = destruction). This is punishing but realistic. **Recommendation:** Yes — but with delay. The creature must be hungry enough, unafraid, and the food must be unattended for several ticks. This gives the player time to reclaim dropped food while still creating tension.

### Q6: Should cooking require both hands free?

Currently you need food in one hand and fire_source in the other for compound tools. But cooking over a fireplace is different — you hold food over a stationary fire. **Recommendation:** Cooking at a fire-source furniture item requires only the food in one hand. The fire is the room fixture, not a hand-held tool. This distinguishes cooking from compound-tool actions like striking a match.

### Q7: Food containers (pantry, larder, icebox)?

Should there be food-storage containers that slow or prevent spoilage? An icebox could halt the spoilage timer. A pantry shelf could slow it. **Recommendation:** Phase 2 feature. For PoC, food spoils at the same rate everywhere. Storage containers add a nice strategic layer later.

### Q8: Wine integration?

The wine bottle already exists with FSM states (sealed → open → empty). Should wine count as food? It could provide a small health buff and a "tipsy" status effect. **Recommendation:** Yes, integrate wine as a `drink` category food item in Phase 1. The object already has the right structure — just add `food = { category = "drink", nutrition = 5, effects = { add_status("tipsy", 15) } }` to its open state.

---

## Appendix A: Engine Readiness Assessment

| Engine Feature | Status | Food Usage |
|---------------|--------|-----------|
| `edible` flag + `eat` verb | ✅ Exists | Consumption pipeline |
| `drink` verb + FSM transitions | ✅ Exists | Liquid consumption |
| `on_taste` / `on_smell` sensory hooks | ✅ Exists | Food identification |
| `on_taste_effect` | ✅ Exists | Taste-risk mechanic |
| Effects pipeline (injury, status, narrate, mutate) | ✅ Exists | Food effects |
| FSM timer-driven transitions | ✅ Exists | Spoilage lifecycle |
| Mutation hot-swap (`mutation.mutate()`) | ✅ Exists | Cooking transformation |
| Material registry | ✅ Exists | Food materials |
| Creature drives (hunger, fear) | ✅ Designed | Bait mechanic |
| Creature awareness (smell_range) | ✅ Designed | Food detection |
| `cook` verb | ❌ Needs creation | Cooking action |
| `food.effects` processing in `eat` | ❌ Needs addition | Eat-time effects |
| `food-poisoning` injury type | ❌ Needs creation | Spoiled food consequence |
| Food materials (meat, bread, etc.) | ❌ Needs creation | Material properties |
| Fire source furniture | ❌ Needs creation | Cooking location |

**Assessment: The engine is approximately 80% ready.** The core pipelines (eat, drink, FSM, mutation, effects, sensory) all exist. The remaining 20% is new content (food objects, materials, injury type) and minor verb additions (cook, eat-effects). No architectural changes needed.

---

## Appendix B: Cross-References

| Document | Relevance |
|----------|-----------|
| `docs/design/design-directives.md` | D-14 (mutation), sensory system, consumables |
| `docs/architecture/objects/core-principles.md` | Principles 1, 3, 6, 8, 9 |
| `plans/npc-system-plan.md` §6 | Rat hunger drive, smell awareness, bait interaction |
| `docs/design/tools-system.md` | fire_source capability, compound tools |
| `docs/design/material-properties-system.md` | Material registry pattern |
| `src/engine/effects.lua` | Effect processing API |
| `src/engine/fsm/init.lua` | Timer-driven transitions, state application |
| `src/engine/mutation/init.lua` | Object hot-swap API |
| `src/engine/verbs/survival.lua` | Existing eat/drink/pour handlers |
