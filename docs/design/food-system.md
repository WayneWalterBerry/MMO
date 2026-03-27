# Food System Design

## Overview

The food system provides a complete pipeline for cooking raw food, managing edibility tiers, tracking spoilage state, and applying nutritional effects with injury consequences. It is implemented in Phase 3 WAVE-3 via the cook verb, consumption pipeline, and food object pattern.

The system is **positive-sum** — players accumulate nutrition faster than depletion, preventing starvation loops while maintaining survival tension through early-game food scarcity and cooking discovery.

---

## 1. Cook Verb: Raw → Cooked Transformation

### Activation

The cook verb transforms raw food into cooked food over a fire source using **D-14 Code Mutation** (Principle 8: Engine executes metadata). When a player cooks a food item, the engine rewrites the object's Lua definition at runtime.

### Aliases

The cook verb accepts four aliases for narrative flexibility:
- `cook` — primary verb
- `roast` — direct flame cooking
- `bake` — oven/enclosed heat
- `grill` — open-fire cooking

All four map to the identical handler in `src/engine/verbs/cooking.lua`.

### Mechanics: fire_source Requirement

The cook verb requires a **fire_source** tool in either:
1. **Player's inventory** (checked first)
2. **Visible room scope** (fallback)

The fire_source is identified via the object's `tool_capabilities` array or exact ID match. If no fire source is present, the verb fails with a custom message (defaulting to "You need a fire source to cook this.").

### Recipe Structure

Each cookable food object declares cooking metadata in `obj.crafting.cook`:

```lua
crafting = {
    cook = {
        requires_tool = "fire_source",   -- tool capability required
        becomes = "cooked-rat-meat",     -- target object type_id after mutation
        message = "You cook [...] over the flames.",
        fail_message_no_tool = "You need a fire source to cook this."
    }
}
```

### Mutation Flow

1. Player holds raw food (e.g., raw rat corpse)
2. Fire source located in inventory or room
3. `perform_mutation()` fires: object mutates from `raw-rat-meat.lua` → `cooked-rat-meat.lua`
4. Tool charge consumed (if applicable)
5. Narration printed: "You cook [food] over the flames."
6. Hint emitted: "Cooking raw meat makes it safe to eat and more nourishing."

The mutation replaces the object entirely via `ctx.mutation.mutate()`, which rewrites the .lua file and updates the registry in-place. The player's hands are automatically adjusted if needed (inventory validation).

## 2. Edibility Tiers

### Tier 1: Cooked (Safe)

**Edibility flag:** `food.edible = true`  
**Examples:** `cooked-rat-meat`, `roasted grain`

Cooked foods are immediately edible and safe. They grant full nutrition and any declared effects (heal, narration, injuries).

Activation: `eat [food]` verb. Food must be in inventory; it is consumed and removed from registry.

### Tier 2: Raw Meat (Conditional)

**Edibility flags:** `food.raw = true`, `food.cookable = true`, `food.category = "meat"`  
**Examples:** `raw-rat-meat`, `bat-corpse` flesh

Raw meat is **edible but dangerous**. When consumed:
- **Narration:** "You choke it down. Your stomach rebels almost immediately."
- **Consequence:** Inflicts `food-poisoning` injury (immediate onset state)
- **Nutrition:** Reduced bonus (half of cooked value) due to incomplete digestion
- **Hint:** "Cooking raw meat makes it safe to eat and more nourishing."
- **Removal:** Object is consumed and removed from registry

**Design rationale:** Raw meat encourages cooking as a survival strategy while permitting high-risk shortcuts during food scarcity. The food-poisoning consequence (nausea, restricted actions, 1 damage-per-tick) incapacitates the player for ~12 ticks, reinforcing the cook-first meta.

### Tier 3: Raw Grain & Non-Meat (Rejected)

**Edibility flags:** `food.raw = true`, `food.cookable = true`, `food.category ≠ "meat"`  
**Examples:** `wheat`, `mushroom` (uncooked)

Raw non-meat foods are **rejected** and cannot be force-eaten. Attempting to eat them produces:
- **Message:** `obj.on_eat_reject` or "You can't eat that raw. Try cooking it first."
- **Result:** Action fails; food remains in inventory

**Design rationale:** Separation of edible-raw (meat) vs. non-edible-raw (vegetables, grain) establishes distinct survival challenges.

## 3. Spoilage FSM Chain

Food objects progress through timed states representing freshness and decay via automatic FSM transitions:

1. **fresh** (0–24 hours game time) — full nutrition, full effects
2. **bloated** (24–48 hours) — visible signs of decay (description changes); minor nutrition loss
3. **rotten** (48–72 hours) — severe visual decay; 50% nutrition, slight illness risk
4. **bones** (72+ hours) — inedible husk; no nutrition; high poison risk or automatic rejection

Spoilage is tracked via `obj._state` (FSM) and timed events that auto-transition after duration via `timed_events` array. Player is warned: "This food looks spoiled... but you eat it anyway." when consuming non-fresh food.

Each state defines `on_feel`, `on_smell`, `on_taste` sensory descriptions so the player can identify decay via dark senses.

---

## 4. Mutation Chain: Death → Corpse → Cooked

The complete pipeline from live creature to consumed food:

```
CREATURE (rat, bat, etc.)
    ↓ [dies from combat → reshape to corpse]
CORPSE (raw rat corpse, bat corpse)
    ↓ [cooked over fire_source via cook verb]
COOKED FOOD (cooked rat meat, roasted bat)
    ↓ [eaten by player via eat verb]
REMOVED FROM REGISTRY — nutrition applied, effects processed
```

Each transition is a code-level mutation:
- **Death → Corpse:** Engine rewrites creature.lua → creature-corpse.lua; corpse inherits creature's inventory
- **Corpse → Cooked:** Player-triggered cook verb rewrites corpse.lua → cooked-meat.lua via recipe; mutate() updates registry

## 5. Food Metadata

Food is declared via a `food = {}` table on any object:

```lua
food = {
    edible = true,                    -- Object can be consumed immediately
    raw = true,                       -- Flagged as raw (optional, for raw-tier)
    cookable = true,                  -- Can be cooked via cook verb
    category = "meat",                -- "meat", "grain", "plant", "liquid" (gating)
    nutrition = 15,                   -- Buff strength applied on consumption
    effects = {
        { type = "heal", amount = 3 },
        { type = "narrate", message = "..." },
        { type = "inflict_injury", injury_type = "food-poisoning", probability = 0.10 },
    },
    drinkable = false,                -- Can be drunk instead of eaten (for liquids)
}
```

**Key Rules:**
- `edible = true` → immediately consumable; `edible = false` + `cookable = true` → only edible when cooked
- **Every food object MUST declare `on_feel`, `on_smell`, `on_taste`** — primary sensory descriptions (darkness accessibility)
- Objects inherit `small-item` template; no dedicated `food` template exists

---

## 6. Eat/Drink Verbs

### `eat` Handler

Located in `src/engine/verbs/consumption.lua`:

```lua
handlers["eat"] = function(ctx, noun)
    if noun == "" then
        print("Eat what?")
        return
    end
    
    local obj = find_in_inventory(ctx, noun) or find_visible(ctx, noun)
    if not obj then
        err_not_found(ctx)
        return
    end
    
    -- WAVE-5 food objects require holding; legacy edible objects are grandfathered
    if obj.food and not find_in_inventory(ctx, noun) then
        print("You'll need to pick that up first.")
        return
    end
    
    -- Check injury restrictions (e.g. jaw injuries could block eating)
    if inj_ok and injury_mod then
        local restricts = injury_mod.get_restrictions(ctx.player)
        if restricts.eat then
            print("Your injuries prevent you from eating.")
            return
        end
    end
    
    local food = obj.food
    
    -- WAVE-3: Raw meat with consequences
    if food and food.raw == true and food.cookable == true then
        if food.edible ~= true then
            if food.category == "meat" then
                -- Raw meat: allow eating but with food-poisoning consequence
                print(obj.on_taste or "The raw flesh tastes foul.")
                print("You choke it down. Your stomach rebels almost immediately.")
                injury_mod.inflict(ctx.player, "food-poisoning", obj.id or "raw meat", nil, nil)
                if food.nutrition then
                    ctx.player.nutrition = (ctx.player.nutrition or 0) + food.nutrition
                end
                remove_from_location(ctx, obj)
                ctx.registry:remove(obj.id)
                return
            else
                -- Non-meat raw cookable (grain, vegetables) — reject
                print(obj.on_eat_reject or "You can't eat that raw. Try cooking it first.")
                return
            end
        end
    end
    
    -- Standard edibility check
    local is_edible = (food and food.edible) or obj.edible
    if not is_edible then
        print("You can't eat " .. (obj.name or "that") .. ".")
        return
    end
    
    print("You eat " .. (obj.name or "it") .. ".")
    if obj.on_taste then
        print(obj.on_taste)
    end
    
    -- Apply nutrition
    if food and food.nutrition then
        ctx.player.nutrition = (ctx.player.nutrition or 0) + food.nutrition
    end
    
    -- Food effects pipeline
    if food and food.effects then
        effects.process(food.effects, {
            player = ctx.player,
            registry = ctx.registry,
            source = obj,
            source_id = obj.id or obj.guid,
            game_over = false,
        })
    end
    
    remove_from_location(ctx, obj)
    ctx.registry:remove(obj.id)
end
```

**Checks:**
- Object must be in inventory (new food objects) or visible (legacy edible objects)
- Injury restrictions checked first (e.g., rabies blocks precise actions, food-poisoning blocks eating)
- **Raw meat tier:** Special handling for `food.raw = true` + `food.category = "meat"` → inflicts food-poisoning
- **Non-raw-edible check:** Cooked foods and other edible items require `food.edible = true`
- Effects pipeline processes all declared effects (heal, narration, inflict_injury)
- Object is consumed and removed from inventory and registry

**Aliases:** `consume`, `devour`

### `drink` Handler

```lua
handlers["drink"] = function(ctx, noun)
    if noun == "" then print("Drink what?") return end
    
    -- Check injury restrictions before object resolution (rabies hydrophobia)
    if inj_ok and injury_mod then
        local restricts = injury_mod.get_restrictions(ctx.player)
        if restricts.drink then
            print("You can't bring yourself to drink — the mere thought of water fills you with terror.")
            return
        end
    end
    
    -- Strip "from" preposition: "drink from bottle" → "bottle"
    local target = noun:match("^from%s+(.+)") or noun
    
    local obj = find_in_inventory(ctx, target)
    if not obj then
        err_not_found(ctx)
        return
    end
    
    -- FSM path: check for "drink" transition
    if obj.states then
        local transitions = fsm_mod.get_transitions(obj)
        local target_trans = ...
        if target_trans then
            fsm_mod.transition(ctx.registry, obj.id, target_trans.to, {}, "drink")
            return
        end
    end
    
    -- Food-as-drink path (WAVE-5): objects with food.drinkable
    if obj.food and obj.food.drinkable then
        if obj.on_taste then print(obj.on_taste) end
        if obj.food.nutrition then
            ctx.player.nutrition = (ctx.player.nutrition or 0) + obj.food.nutrition
        end
        print("You drink " .. (obj.name or "it") .. ".")
        remove_from_location(ctx, obj)
        ctx.registry:remove(obj.id)
        return
    end
    
    print("You can't drink " .. (obj.name or "that") .. ".")
end
```

**Checks:**
- Injury restrictions checked first (e.g., rabies hydrophobia blocks drinking)
- Preposition strip: "drink from bottle" → "bottle"
- FSM path: objects with "drink" transition execute state machine first
- Food-as-drink path: `food.drinkable = true` enables drinking objects as consumables
- Aliases: `quaff`, `sip`

---

## 7. Food Effects Pipeline

Each food object can declare a `food.effects` array that processes upon consumption:

```lua
food = {
    edible = true,
    nutrition = 15,
    effects = {
        { type = "heal", amount = 3 },
        { type = "narrate", message = "The rat meat is gamey but filling." },
        { type = "inflict_injury", injury_type = "food-poisoning", probability = 0.10 },
    }
}
```

### Effect Types

| Effect | Function | Example |
|--------|----------|---------|
| `heal` | Restore health | `{ type = "heal", amount = 5 }` |
| `narrate` | Print flavor text | `{ type = "narrate", message = "..." }` |
| `inflict_injury` | Apply disease/wound | `{ type = "inflict_injury", injury_type = "food-poisoning", probability = 0.10 }` |

### Processing Order

1. Base nutrition applied to `player.nutrition`
2. All declared effects execute in array order via `effects.process(food.effects, {...})`
3. Injury inflictions roll probability (if declared)
4. Player narration outputs occur after healing/injury messages

### Example: Cooked Rat Meat

```lua
food = {
    edible = true,
    nutrition = 15,
    effects = {
        { type = "heal", amount = 3 },
        { type = "narrate", message = "The rat meat is gamey but filling." },
    }
}
```

When consumed:
1. Nutrition: +15
2. Health: +3
3. Narration: "The rat meat is gamey but filling."

---

## 8. Food Economy: Positive-Sum Balance

The food system is designed to be **positive-sum** — players accumulate nutrition faster than depletion over time, preventing starvation loops that frustrate gameplay. However, early-game scarcity creates tension.

### Nutritional Balance

| Food Source | Nutrition | Tier | Risk | Strategy |
|-------------|-----------|------|------|----------|
| Raw rat meat | 8 | Immediate | Food poisoning | Desperation; high survival cost |
| Cooked rat meat | 15 | After fire-finding | None | Safe, preferred path |
| Bat corpse (cooked) | 12 | After bat combat | None | Combat reward |
| Foraged grain (cooked) | 10 | After cooking | None | Utility backup |

### Depletion Rates

- **Resting:** -0.5 nutrition/tick (minimal)
- **Walking:** -1.0 nutrition/tick (moderate)
- **Combat:** -2.0 nutrition/tick (high exertion)

### Equilibrium Example

Player finds fire source and 2 rats:
- Cook 1 rat → +15 nutrition
- Eat → -1 tick (moderate activity) = net +14 nutrition gain
- Accumulation reaches 40+ nutrition, permitting 40+ ticks of exploration

This creates a **survival phase** (finding fire + cooking) followed by **abundance** (multiple cooked meals). Players are not mechanically starved but narratively motivated to cook.

## 9. Food Object Pattern Example

### Cooked Rat Meat

```lua
return {
    guid = "{971e819c-8ad2-4f6e-934c-48236d7c5660}",
    template = "small-item",
    
    id = "cooked-rat-meat",
    name = "a piece of cooked rat meat",
    keywords = {"cooked rat", "rat meat", "cooked meat", "meat"},
    description = "A small piece of dark, charred meat. The fur has been singed away, leaving browned flesh scored with grill marks. It smells better than it looks.",
    
    material = "meat",
    size = 1,
    weight = 0.3,
    portable = true,
    categories = {"small-item", "food", "consumable"},
    
    on_feel = "Warm and greasy. The surface is firm where it charred, softer underneath. Small bones poke through the flesh.",
    on_smell = "Smoky and rich, with an underlying gamey musk. Not appetizing by choice, but your stomach disagrees.",
    on_listen = "Silent. It cools with a faint tick as the fat contracts.",
    on_taste = "Gamey and tough, with a smoky char. The flavor is strong -- wild, not farmed. Edible, if you don't think about it.",
    
    food = {
        edible = true,
        nutrition = 15,
        effects = {
            { type = "heal", amount = 3 },
            { type = "narrate", message = "The rat meat is gamey but filling." },
        },
    },
    
    mutations = {},
}
```

---

## 10. Raw Meat Consequence: Food-Poisoning Injury

Eating raw meat inflicts **food-poisoning** injury with these characteristics:

### Onset State

- **Duration:** 3 ticks (1080 seconds game time)
- **Effect:** Initial cramps; eating blocked (`restricts.eat = true`)
- **Damage:** None yet
- **Narration:** "Your stomach lurches. Something you ate is fighting back."

### Nausea State

- **Duration:** 12 ticks (4320 seconds game time)
- **Effect:** Severe nausea; damage-per-tick = 1; eating + precise actions blocked
- **Consequence:** Cumulative health loss during critical exploration period
- **Narration:** "Waves of nausea roll through you. Your hands shake."

### Recovery State

- **Duration:** 5 ticks (1800 seconds game time)
- **Effect:** Subsiding symptoms; no damage; player regains mobility
- **Narration:** "The nausea begins to ebb. Your stomach unclenches."

### Cleared State

- **Terminal:** Yes — injury automatically removed when terminal state reached
- **Narration:** "Your strength returns. The food poisoning has finally cleared."

**Total duration:** 20 ticks (max ~8 minutes game time). The penalty aligns with raw meat risk: players are incapacitated during a dangerous period, reinforcing the cook-first strategy.

### Injury Definition

See `src/meta/injuries/food-poisoning.lua` for complete FSM.

## 11. Implementation Files

| File | Role |
|------|------|
| `src/engine/verbs/cooking.lua` | Cook verb handler + write verb |
| `src/engine/verbs/consumption.lua` | Eat/drink handlers with raw-meat consequence |
| `src/engine/effects.lua` | Food effects pipeline (heal, narrate, inflict_injury) |
| `src/meta/objects/cooked-rat-meat.lua` | Food object pattern example |
| `src/meta/injuries/food-poisoning.lua` | FSM injury definition |
