# Food Design Patterns — Software Engineering Patterns for Game Food Systems

**Research Date:** March 26, 2026  
**Researcher:** Frink  
**Purpose:** Extract reusable software engineering patterns from food system research

---

## Pattern Index

1. [Finite State Machine (FSM) Pattern](#1-finite-state-machine-fsm-pattern)
2. [State-Based Material Properties](#2-state-based-material-properties)
3. [Time-Driven State Transitions](#3-time-driven-state-transitions)
4. [Sensory Identification Pipeline](#4-sensory-identification-pipeline)
5. [Tool Capability Gating](#5-tool-capability-gating)
6. [Object Mutation Pattern (Code IS State)](#6-object-mutation-pattern-code-is-state)
7. [Effect Composition Pattern](#7-effect-composition-pattern)
8. [Container Modifier Pattern](#8-container-modifier-pattern)
9. [Risk/Reward Identification](#9-riskreward-identification)
10. [Recipe Combination System](#10-recipe-combination-system)
11. [Buff Duration Management](#11-buff-duration-management)
12. [Preservation Transform Chain](#12-preservation-transform-chain)
13. [Creature Interaction Protocol](#13-creature-interaction-protocol)
14. [Economic Value Decay](#14-economic-value-decay)
15. [Layered Effect System](#15-layered-effect-system)

---

## 1. Finite State Machine (FSM) Pattern

### Problem
Food items need to transition through multiple states (fresh, cooked, spoiled) with different properties and behaviors in each state.

### Solution
Implement food lifecycle as an FSM with explicit states and transitions.

### Structure
```lua
-- Food object with FSM states
return {
    guid = "{food-guid}",
    id = "apple",
    
    initial_state = "fresh",
    _state = "fresh",
    
    states = {
        fresh = {
            description = "A crisp, red apple.",
            on_smell = "Sweet and fragrant.",
            on_taste = "Crisp and juicy.",
            edible = true,
            nutrition = 20,
            safe_to_eat = true
        },
        
        spoiling = {
            description = "An apple with soft brown spots.",
            on_smell = "Slightly fermented odor.",
            on_taste = "Mushy and overly sweet.",
            edible = true,
            nutrition = 10,
            safe_to_eat = false,
            poison_risk = 0.3
        },
        
        spoiled = {
            description = "A rotten apple covered in mold.",
            on_smell = "Foul, moldy stench.",
            on_taste = "Disgusting and potentially harmful.",
            edible = false,
            safe_to_eat = false,
            poison_risk = 0.9
        }
    },
    
    transitions = {
        { from = "fresh", to = "spoiling", trigger = "time", duration = 86400 },  -- 1 day
        { from = "spoiling", to = "spoiled", trigger = "time", duration = 43200 }  -- 12 hours
    }
}
```

### Benefits
- Clear state encapsulation
- Prevents invalid transitions
- Easy to debug and extend
- State-specific properties naturally grouped

### Real-World Examples
- **Dwarf Fortress:** Binary (raw vs prepared)
- **NetHack:** Fresh corpse → rotten corpse (30 turns)
- **Cataclysm DDA:** 5-stage freshness scale
- **Don't Starve:** Fresh → stale → spoiled percentage

### Integration with MMO Engine
Our FSM engine (`src/engine/fsm/init.lua`) already supports this! Just define states and transitions in food objects.

---

## 2. State-Based Material Properties

### Problem
Food material properties (hardness, texture, smell) change as food transitions between states.

### Solution
Define material properties per FSM state; property lookups check current state first.

### Structure
```lua
return {
    guid = "{bread-guid}",
    id = "bread-loaf",
    material = "bread",  -- base material
    
    states = {
        fresh = {
            material_overrides = {
                texture = "soft",
                hardness = 2,
                moisture = 0.4
            },
            on_feel = "Soft and spongy.",
            room_presence = "A fresh loaf of bread sits here."
        },
        
        stale = {
            material_overrides = {
                texture = "firm",
                hardness = 5,
                moisture = 0.2
            },
            on_feel = "Hard and dry.",
            room_presence = "A stale loaf of bread lies here."
        },
        
        moldy = {
            material_overrides = {
                texture = "fuzzy",
                hardness = 1,
                moisture = 0.5
            },
            on_feel = "Squishy with fuzzy patches.",
            on_smell = "Musty mold smell.",
            room_presence = "A moldy loaf of bread is here."
        }
    }
}
```

### Benefits
- Material system integrates with food states
- Sensory properties automatically update
- Room descriptions reflect current state
- Supports material-based interactions (e.g., "cut the hard bread")

### Real-World Examples
- **Real Food Science:** Bread staling (retrogradation of starch molecules)
- **Cataclysm DDA:** Texture changes in spoiling food
- **Our Engine:** Material system has 30+ materials; food extends this

---

## 3. Time-Driven State Transitions

### Problem
Food spoilage occurs over time, requiring automatic state transitions without player action.

### Solution
FSM engine ticks time-based transitions; environmental modifiers affect rate.

### Structure
```lua
-- FSM engine handles time-based transitions
-- Food object declares base spoilage rate

return {
    guid = "{meat-guid}",
    id = "raw-meat",
    
    spoilage = {
        enabled = true,
        base_rate = 1.0,  -- baseline decay speed
        current_freshness = 100,  -- 0-100 scale
        
        modifiers = {
            temperature = function(env)
                if env.temperature > 25 then return 2.0 end  -- Hot = 2x spoilage
                if env.temperature < 5 then return 0.2 end   -- Cold = 5x slower
                return 1.0
            end,
            
            container = function(container)
                if container.sealed then return 0.5 end  -- Sealed = 2x slower
                return 1.0
            end,
            
            preserved = function(obj)
                if obj.salted then return 0.1 end  -- Salted = 10x slower
                if obj.smoked then return 0.15 end  -- Smoked = ~7x slower
                return 1.0
            end
        }
    },
    
    transitions = {
        {
            from = "fresh",
            to = "spoiling",
            trigger = "freshness_threshold",
            threshold = 50  -- When freshness drops below 50
        },
        {
            from = "spoiling",
            to = "spoiled",
            trigger = "freshness_threshold",
            threshold = 10
        }
    }
}
```

### Benefits
- Automatic spoilage without manual tracking
- Environmental factors naturally affect rate
- Preservation methods are multipliers (composable)
- Easy to balance (tweak rates without code changes)

### Real-World Examples
- **Dwarf Fortress:** Raw food rots over time
- **Cataclysm DDA:** Hour-by-hour freshness decay
- **Don't Starve:** Percentage-based spoilage
- **Real Food Science:** Microbial growth curves (exponential initially, then plateau)

### Integration with MMO Engine
Our game loop (`src/engine/loop/init.lua`) already ticks time. FSM engine can track freshness decay per object.

---

## 4. Sensory Identification Pipeline

### Problem
Players need to identify food safety without requiring external knowledge or meta-gaming.

### Solution
Multi-stage sensory pipeline: safe observation → risky confirmation

### Structure
```lua
-- Verb implementation leveraging sensory properties

verbs.smell = function(context, noun)
    local obj = context.registry:find_by_keyword(noun)
    if not obj then return err_not_found(context) end
    
    local smell = obj.states[obj._state].on_smell or obj.on_smell or "No discernible smell."
    print(smell)
    
    -- Smell can provide hints about food safety
    if obj.spoilage then
        if obj.spoilage.current_freshness < 30 then
            print("(The smell suggests this food may be unsafe.)")
        elseif obj.spoilage.current_freshness < 60 then
            print("(The smell indicates this food is past its prime.)")
        end
    end
end

verbs.taste = function(context, noun)
    local obj = context.registry:find_by_keyword(noun)
    if not obj then return err_not_found(context) end
    
    -- Tasting is definitive but risky
    local taste = obj.states[obj._state].on_taste or obj.on_taste or "Bland and unremarkable."
    print(taste)
    
    if obj.spoilage and obj.spoilage.current_freshness < 20 then
        print("You immediately spit it out! This food is spoiled!")
        injuries.inflict(context.player, "food_poisoning", { severity = 2 })
    elseif obj.spoilage and obj.spoilage.current_freshness < 50 then
        print("It tastes off. This food may not be safe.")
    end
end
```

### Identification Hierarchy
1. **Look/Examine:** Visual cues (mold, color, texture) — safest
2. **Smell:** Odor detection (fermentation, rot) — very safe
3. **Feel/Touch:** Texture changes (slime, hardness) — safe
4. **Listen:** Rare (fizzing fermentation, insect activity) — safe
5. **Taste:** Definitive but risky (poison, disease) — dangerous

### Benefits
- Player skill develops (learn to interpret sensory cues)
- Mirrors real-world food safety assessment
- Creates risk/reward tension (taste for certainty vs. risk)
- Leverages existing sensory system!

### Real-World Examples
- **NetHack:** Pet test (safe proxy for tasting)
- **Real-World:** Professional food tasters, smell tests for spoilage
- **Our Engine:** Sensory properties already implemented on all objects!

---

## 5. Tool Capability Gating

### Problem
Cooking and preservation should require appropriate tools, not just "magic" transformations.

### Solution
Tool capability system gates food transformations; compound tools create multi-step processes.

### Structure
```lua
-- Tool capability definitions (already exists in engine)

-- Fire source capability (match, candle, torch)
capabilities.fire_source = {
    enables = { "light", "cook", "ignite" }
}

-- Cooking vessel capability (pot, pan, cauldron)
capabilities.cooking_vessel = {
    enables = { "boil", "stew", "brew" }
}

-- Cutting tool capability (knife, axe)
capabilities.cutting_tool = {
    enables = { "cut", "slice", "chop", "prepare" }
}

-- Preservation tool capability (salt, smoking rack)
capabilities.preservation_tool = {
    enables = { "salt", "smoke", "dry", "cure" }
}

-- Verb implementation using tool gating

verbs.cook = function(context, noun)
    local food = context.registry:find_by_keyword(noun)
    if not food or not food.cookable then
        print("You can't cook that.")
        return
    end
    
    -- Check for fire source
    local fire = context.player:find_tool_by_capability("fire_source")
    if not fire then
        print("You need a fire source to cook.")
        return
    end
    
    -- Optional: check for cooking vessel (for complex recipes)
    if food.requires_vessel then
        local vessel = context.player:find_tool_by_capability("cooking_vessel")
        if not vessel then
            print("You need a cooking vessel for that.")
            return
        end
    end
    
    -- Trigger mutation: raw-meat.lua → cooked-meat.lua
    mutation.apply(food, "cook", context)
    print("You cook the " .. food.name .. " over the flames.")
end
```

### Benefits
- Enforces tool realism (can't cook without fire)
- Creates tool scarcity gameplay (need right tools)
- Compound tools enable complex recipes
- Leverages existing tool system

### Real-World Examples
- **Dwarf Fortress:** Kitchen building required for cooking
- **Cataclysm DDA:** Extensive tool requirements (pot, heat source, utensils)
- **Caves of Qud:** Campfire or oven required for cooking
- **Our Engine:** Tool capability system already exists!

---

## 6. Object Mutation Pattern (Code IS State)

### Problem
State changes should transform the object definition itself, not just set flags.

### Solution
Food state transitions trigger file mutations: raw-X.lua → cooked-X.lua (following D-14 principle)

### Structure
```lua
-- raw-chicken.lua (before cooking)
return {
    guid = "{raw-chicken-guid}",
    template = "raw-food",
    id = "raw-chicken",
    name = "a raw chicken breast",
    keywords = {"chicken", "raw chicken", "breast", "meat"},
    description = "A raw chicken breast, pale and slightly moist.",
    
    on_smell = "Raw poultry smell.",
    on_taste = "DO NOT EAT RAW CHICKEN!",
    on_feel = "Cold, slightly slimy meat.",
    
    edible = false,  -- Unsafe to eat raw
    cookable = true,
    material = "meat",
    
    mutations = {
        cook = {
            becomes = "cooked-chicken",
            message = "The chicken sizzles and turns golden brown.",
            requires_tool = "fire_source"
        }
    }
}

-- cooked-chicken.lua (after cooking mutation)
return {
    guid = "{cooked-chicken-guid}",
    template = "cooked-food",
    id = "cooked-chicken",
    name = "a cooked chicken breast",
    keywords = {"chicken", "cooked chicken", "breast", "meat"},
    description = "A golden-brown chicken breast, cooked through.",
    
    on_smell = "Savory roasted poultry.",
    on_taste = "Juicy and flavorful.",
    on_feel = "Warm and firm.",
    
    edible = true,
    nutrition = 50,
    buffs = { stamina = 20, duration = 600 },
    cookable = false,  -- Already cooked
    material = "meat"
}
```

### Benefits
- **Code IS state** (D-14 principle) — no separate state flags
- File mutation preserves object history (can track transformations)
- Each state is a complete, readable object definition
- Impossible to have invalid state combinations

### Real-World Examples
- **Dwarf Fortress Philosophy:** State transformation via processing
- **Our Engine:** Mutation system (`src/engine/mutation/init.lua`) already implements this!

### Integration with MMO Engine
Perfect fit! Our mutation system can rewrite `raw-X.lua → cooked-X.lua` at runtime. The engine's prime directive (D-14).

---

## 7. Effect Composition Pattern

### Problem
Food can provide multiple simultaneous effects (healing, buffs, debuffs, mutations).

### Solution
Compose effects as a list; apply all effects when consumed.

### Structure
```lua
return {
    guid = "{stew-guid}",
    id = "hearty-stew",
    name = "a bowl of hearty stew",
    
    edible = true,
    
    effects = {
        -- Healing effect
        {
            type = "heal",
            amount = 25,
            message = "The warm stew restores your vitality."
        },
        
        -- Stat buff
        {
            type = "buff",
            stat = "stamina",
            amount = 30,
            duration = 900,  -- 15 minutes
            message = "You feel energized!"
        },
        
        -- Secondary buff
        {
            type = "buff",
            stat = "cold_resistance",
            amount = 10,
            duration = 1800,  -- 30 minutes
            message = "The hot stew warms you from within."
        },
        
        -- Morale boost
        {
            type = "mood",
            amount = 5,
            message = "The delicious stew lifts your spirits."
        }
    }
}

-- Verb implementation applies all effects
verbs.eat = function(context, noun)
    local food = context.registry:find_by_keyword(noun)
    if not food or not food.edible then
        print("You can't eat that.")
        return
    end
    
    print("You eat the " .. food.name .. ".")
    
    -- Apply all effects
    if food.effects then
        for _, effect in ipairs(food.effects) do
            effects.apply(context.player, effect)
            if effect.message then print(effect.message) end
        end
    end
    
    -- Remove food from world
    context.registry:remove(food)
end
```

### Benefits
- Modular effect system (easy to add new effect types)
- Multiple simultaneous effects
- Clear declaration (no hidden effects)
- Integrates with existing effects pipeline

### Real-World Examples
- **Caves of Qud:** Multi-ingredient effects, triggered abilities
- **Valheim:** Multi-stat buffs (health + stamina + Eitr)
- **Cataclysm DDA:** Complex effect chains (morale, nutrition, vitamins)
- **Our Engine:** Effects pipeline exists (`src/engine/effects.lua`)!

---

## 8. Container Modifier Pattern

### Problem
Storage containers should affect food preservation without adding complex inventory tracking.

### Solution
Containers provide multipliers to spoilage rate; check container on each freshness tick.

### Structure
```lua
-- Container object with preservation properties
return {
    guid = "{barrel-guid}",
    template = "container",
    id = "wooden-barrel",
    name = "a wooden barrel",
    
    capacity = 50,
    
    preservation = {
        enabled = true,
        spoilage_modifier = 0.3,  -- 70% slower spoilage
        applies_to = { "food", "drink" }
    }
}

-- FSM engine checks container when calculating spoilage
function fsm.tick_spoilage(obj)
    if not obj.spoilage or not obj.spoilage.enabled then return end
    
    local rate = obj.spoilage.base_rate
    
    -- Check if object is in a container
    local container = containment.get_container(obj)
    if container and container.preservation then
        if table_contains(container.preservation.applies_to, obj.template) then
            rate = rate * container.preservation.spoilage_modifier
        end
    end
    
    -- Apply other modifiers (temperature, etc.)
    -- ...
    
    obj.spoilage.current_freshness = obj.spoilage.current_freshness - rate
end
```

### Benefits
- Containers naturally affect contents
- No special inventory logic needed
- Composable with other modifiers
- Leverages existing containment system

### Real-World Examples
- **Dwarf Fortress:** Barrels/pots prevent spoilage
- **Real-World:** Vacuum sealing, canning, refrigeration
- **Our Engine:** Containment system exists (`src/engine/containment/init.lua`)!

---

## 9. Risk/Reward Identification

### Problem
Unknown food should create tension: eat for potential benefits vs. risk poison/disease.

### Solution
Food safety is a probability; risky foods may provide better rewards.

### Structure
```lua
return {
    guid = "{mushroom-guid}",
    id = "unknown-mushroom",
    name = "a strange mushroom",
    
    edible = true,
    unknown = true,  -- Not yet identified
    
    -- Risk/reward probabilities
    outcomes = {
        { weight = 40, type = "safe", nutrition = 15, message = "Edible, but bland." },
        { weight = 30, type = "buff", buff = "night_vision", duration = 600, message = "Your vision sharpens!" },
        { weight = 20, type = "poison", injury = "poisoned", severity = 1, message = "You feel queasy..." },
        { weight = 10, type = "hallucination", effect = "confusion", duration = 300, message = "The world spins..." }
    },
    
    -- Sensory hints
    on_smell = "Earthy and slightly pungent.",
    on_taste = "Unknown. (Risky to taste!)"
}

-- Eating unknown food rolls on outcomes table
verbs.eat = function(context, noun)
    local food = context.registry:find_by_keyword(noun)
    
    if food.unknown then
        local roll = math.random(1, 100)
        local cumulative = 0
        
        for _, outcome in ipairs(food.outcomes) do
            cumulative = cumulative + outcome.weight
            if roll <= cumulative then
                print(outcome.message)
                -- Apply outcome effect
                if outcome.type == "buff" then
                    effects.apply_buff(context.player, outcome.buff, outcome.duration)
                elseif outcome.type == "poison" then
                    injuries.inflict(context.player, outcome.injury, { severity = outcome.severity })
                end
                break
            end
        end
        
        -- After eating, mushroom becomes "identified" (for this playthrough)
        food.unknown = false
    end
end
```

### Benefits
- Creates memorable moments ("That mushroom gave me night vision!")
- Risk/reward encourages experimentation
- Probability-based outcomes prevent save-scumming
- Unknown → known progression (player knowledge growth)

### Real-World Examples
- **NetHack:** Corpse eating (intrinsics vs. poison)
- **Caves of Qud:** Mutation-granting foods
- **Real-World:** Foraging (mushroom identification is life-or-death)

---

## 10. Recipe Combination System

### Problem
Multiple ingredients should combine to create enhanced effects beyond simple addition.

### Solution
Recipe system defines ingredient combinations and resulting bonuses.

### Structure
```lua
-- Recipe definitions
recipes = {
    sandwich = {
        ingredients = { "bread", "cheese", "meat" },
        requires_tool = "cutting_tool",
        result = {
            id = "sandwich",
            name = "a hearty sandwich",
            nutrition = 70,  -- More than ingredient sum
            buffs = {
                { stat = "stamina", amount = 40, duration = 1200 }
            },
            message = "You craft a delicious sandwich."
        }
    },
    
    stew = {
        ingredients = { "meat", "vegetable", "water" },
        requires_tool = { "cooking_vessel", "fire_source" },
        result = {
            id = "stew",
            name = "a savory stew",
            nutrition = 80,
            buffs = {
                { stat = "health_regen", amount = 2, duration = 1800 },
                { stat = "cold_resistance", amount = 15, duration = 1800 }
            },
            message = "The stew bubbles and fills the air with savory aroma."
        }
    }
}

-- Verb checks for recipe matches
verbs.combine = function(context, noun1, noun2, noun3)
    -- Find objects in player inventory
    local ingredients = {
        context.player:find_in_inventory(noun1),
        context.player:find_in_inventory(noun2),
        noun3 and context.player:find_in_inventory(noun3) or nil
    }
    
    -- Check all recipes for match
    for recipe_name, recipe in pairs(recipes) do
        if matches_ingredients(ingredients, recipe.ingredients) then
            -- Check tool requirements
            if recipe.requires_tool then
                local has_tools = check_tools(context.player, recipe.requires_tool)
                if not has_tools then
                    print("You lack the necessary tools.")
                    return
                end
            end
            
            -- Remove ingredients
            for _, ing in ipairs(ingredients) do
                context.registry:remove(ing)
            end
            
            -- Create result
            local result = create_food_from_recipe(recipe.result)
            context.player:add_to_inventory(result)
            
            print(recipe.result.message)
            return
        end
    end
    
    print("Those ingredients don't combine into anything useful.")
end
```

### Benefits
- Encourages experimentation
- Rewards ingredient collection
- Synergy effects (whole > sum of parts)
- Tool requirements create progression

### Real-World Examples
- **Caves of Qud:** 2-3 ingredient cooking with triggered effects
- **Cataclysm DDA:** 500+ recipes with complex ingredient trees
- **Don't Starve:** Crock Pot recipe discovery
- **Valheim:** Tiered cooking (cauldron recipes)

---

## 11. Buff Duration Management

### Problem
Food buffs need to be tracked, displayed, stacked (or not), and expired automatically.

### Solution
Player has active_buffs table; game loop ticks durations, expires buffs automatically.

### Structure
```lua
-- Player model includes buff tracking
player = {
    active_buffs = {},
    
    add_buff = function(self, buff)
        -- Check for existing buff of same type
        for i, existing in ipairs(self.active_buffs) do
            if existing.stat == buff.stat then
                if buff.stacks then
                    -- Stack effect (e.g., stamina buffs add)
                    existing.amount = existing.amount + buff.amount
                    existing.duration = math.max(existing.duration, buff.duration)
                else
                    -- Replace with new buff (whichever is stronger)
                    if buff.amount > existing.amount then
                        self.active_buffs[i] = buff
                    end
                end
                return
            end
        end
        
        -- Add new buff
        table.insert(self.active_buffs, buff)
    end,
    
    get_stat_modifier = function(self, stat)
        local modifier = 0
        for _, buff in ipairs(self.active_buffs) do
            if buff.stat == stat then
                modifier = modifier + buff.amount
            end
        end
        return modifier
    end
}

-- Game loop ticks buffs
function loop.tick_buffs()
    for i = #player.active_buffs, 1, -1 do
        local buff = player.active_buffs[i]
        buff.duration = buff.duration - 1  -- Decrement by 1 second
        
        if buff.duration <= 0 then
            print("Your " .. buff.stat .. " buff has worn off.")
            table.remove(player.active_buffs, i)
        end
    end
end
```

### Benefits
- Automatic expiry (no manual tracking)
- Visible in status display
- Stacking policies (additive, max, replace)
- Integrates with stat system

### Real-World Examples
- **Valheim:** 3 food slots, timed buffs, no stacking same food
- **Caves of Qud:** Buff durations tracked, effects triggered at intervals
- **Cataclysm DDA:** Morale, focus, vitamins tracked with decay

---

## 12. Preservation Transform Chain

### Problem
Multiple preservation methods should be composable (salt + smoke = longest shelf life).

### Solution
Preservation methods are additive modifiers; each method sets a flag and multiplier.

### Structure
```lua
return {
    guid = "{preserved-meat-guid}",
    id = "preserved-meat",
    name = "preserved meat",
    
    preservation_methods = {
        salted = { active = false, modifier = 0.2 },   -- 5x slower spoilage
        smoked = { active = false, modifier = 0.3 },   -- 3.3x slower
        dried = { active = false, modifier = 0.4 }     -- 2.5x slower
    },
    
    spoilage = {
        base_rate = 1.0,
        current_freshness = 100,
        
        get_effective_rate = function(self, obj)
            local rate = self.base_rate
            
            -- Apply preservation modifiers multiplicatively
            if obj.preservation_methods.salted.active then
                rate = rate * obj.preservation_methods.salted.modifier
            end
            if obj.preservation_methods.smoked.active then
                rate = rate * obj.preservation_methods.smoked.modifier
            end
            if obj.preservation_methods.dried.active then
                rate = rate * obj.preservation_methods.dried.modifier
            end
            
            return rate
        end
    }
}

-- Preservation verbs set flags
verbs.salt = function(context, noun)
    local food = context.registry:find_by_keyword(noun)
    if not food.preservation_methods or not food.preservation_methods.salted then
        print("That cannot be salted.")
        return
    end
    
    local salt = context.player:find_tool_by_capability("preservation_tool")
    if not salt or salt.id ~= "salt" then
        print("You need salt to preserve that.")
        return
    end
    
    food.preservation_methods.salted.active = true
    print("You rub salt into the " .. food.name .. ".")
end
```

### Benefits
- Composable preservation (combine methods)
- Each method provides clear benefit
- Flags track what's been done
- Multiplicative stacking (diminishing returns)

### Real-World Examples
- **Cataclysm DDA:** Multiple preservation types (smoking, drying, canning, vacuum sealing)
- **Real-World:** Salting + smoking = long-term meat preservation
- **Dwarf Fortress:** Cooking as single preservation method

---

## 13. Creature Interaction Protocol

### Problem
Creatures (like our rat) should interact with food: hunger drives, feeding, bait mechanics.

### Solution
Creatures have hunger drives; food can satisfy hunger or attract creatures.

### Structure
```lua
-- Rat object (already has hunger drive!)
return {
    guid = "{rat-guid}",
    id = "rat",
    name = "a large rat",
    
    drives = {
        hunger = {
            current = 50,  -- 0-100 scale
            threshold = 30,  -- Below this, seeks food
            behavior = "seek_food"
        }
    },
    
    diet = {
        prefers = { "cheese", "bread", "grain" },
        will_eat = { "meat", "fruit", "vegetable" },
        rejects = { "poison", "metal", "stone" }
    }
}

-- Food as bait mechanic
verbs.place = function(context, noun)
    local food = context.registry:find_by_keyword(noun)
    if not food.edible then
        print("That's not bait material.")
        return
    end
    
    -- Place food in room
    local room = context.player.current_room
    food.is_bait = true
    food.placed_at = game_time.current
    
    print("You carefully place the " .. food.name .. " on the ground.")
    
    -- Creature AI checks for bait on its turn
    -- If rat.drives.hunger < threshold and room has bait → approach bait
end

-- Feeding mechanic
verbs.feed = function(context, noun, target)
    local food = context.registry:find_by_keyword(noun)
    local creature = context.registry:find_by_keyword(target)
    
    if not creature.drives or not creature.drives.hunger then
        print("That creature doesn't eat.")
        return
    end
    
    -- Check if creature will eat this food
    if table_contains(creature.diet.rejects, food.material) then
        print("The " .. creature.name .. " refuses the " .. food.name .. ".")
        return
    end
    
    local preference = "neutral"
    if table_contains(creature.diet.prefers, food.id) then
        preference = "preferred"
    elseif table_contains(creature.diet.will_eat, food.material) then
        preference = "acceptable"
    end
    
    -- Creature eats food
    creature.drives.hunger.current = math.min(100, creature.drives.hunger.current + food.nutrition)
    context.registry:remove(food)
    
    if preference == "preferred" then
        print("The " .. creature.name .. " eagerly devours the " .. food.name .. "!")
        creature.disposition_toward_player = creature.disposition_toward_player + 10
    else
        print("The " .. creature.name .. " eats the " .. food.name .. ".")
    end
end
```

### Benefits
- Creatures react to food naturally
- Bait mechanics for traps/attraction
- Feeding befriends creatures
- Dietary preferences add depth
- **Leverages existing rat hunger drive!**

### Real-World Examples
- **Dwarf Fortress:** Creatures graze autonomously, cats hunt vermin
- **NetHack:** Throw food to tame creatures
- **Minecraft:** Feed animals to breed

---

## 14. Economic Value Decay

### Problem
Food value should decrease as it spoils, affecting trade and economy.

### Solution
Object value tied to freshness; spoiled food has reduced or negative value.

### Structure
```lua
return {
    guid = "{cheese-guid}",
    id = "cheese-wheel",
    
    base_value = 50,  -- Gold coins
    
    spoilage = {
        current_freshness = 100,
        
        get_current_value = function(self, obj)
            local freshness_factor = self.current_freshness / 100
            return math.floor(obj.base_value * freshness_factor)
        end
    }
}

-- Trade system checks current value
verbs.sell = function(context, noun)
    local item = context.player:find_in_inventory(noun)
    if not item then
        print("You don't have that.")
        return
    end
    
    local value = item.base_value
    
    -- Adjust for spoilage
    if item.spoilage then
        value = item.spoilage:get_current_value(item)
        
        if value == 0 then
            print("That item is worthless in its current state.")
            return
        end
    end
    
    print("The merchant offers " .. value .. " gold for the " .. item.name .. ".")
    -- ... trade logic
end
```

### Benefits
- Spoilage creates economic pressure
- Trade value reflects item state
- Encourages timely trading
- Realistic market dynamics

### Real-World Examples
- **Dwarf Fortress:** Quality affects value; spoiled food has zero value
- **Cataclysm DDA:** Spoilage reduces barter weight

---

## 15. Layered Effect System

### Problem
Food should affect multiple player systems simultaneously (health, stamina, mood, status).

### Solution
Effects pipeline applies to all relevant player subsystems in sequence.

### Structure
```lua
-- Effect application pipeline
function effects.apply_food_effects(player, food)
    if not food.effects then return end
    
    for _, effect in ipairs(food.effects) do
        if effect.type == "heal" then
            player.health = math.min(player.max_health, player.health + effect.amount)
            
        elseif effect.type == "buff" then
            player:add_buff({
                stat = effect.stat,
                amount = effect.amount,
                duration = effect.duration
            })
            
        elseif effect.type == "mood" then
            player.mood = player.mood + effect.amount
            
        elseif effect.type == "injury_heal" then
            -- Interact with injury system
            injuries.reduce_severity(player, effect.injury_type, effect.amount)
            
        elseif effect.type == "status" then
            -- Apply status condition (e.g., "well-fed", "energized")
            player:add_status(effect.status, effect.duration)
        end
    end
end
```

### Benefits
- Food integrates with all player systems
- Clear separation of concerns
- Easy to add new effect types
- Leverages existing subsystems

### Real-World Examples
- **Cataclysm DDA:** Food affects calories, vitamins, morale, focus, health
- **Caves of Qud:** Food triggers multiple simultaneous effects
- **Our Engine:** Effects pipeline exists, injury system exists, buff tracking ready

---

## Pattern Summary Table

| Pattern | Complexity | Benefit | Prerequisites |
|---------|------------|---------|---------------|
| FSM Pattern | Medium | Clear state encapsulation | FSM engine |
| State-Based Materials | Medium | Material system integration | Material registry |
| Time-Driven Transitions | High | Automatic spoilage | Game loop, FSM |
| Sensory Identification | Low | Player skill development | Sensory properties |
| Tool Capability Gating | Low | Realism, progression | Tool system |
| Object Mutation | Medium | Code IS state (D-14) | Mutation engine |
| Effect Composition | Low | Modular effects | Effects pipeline |
| Container Modifier | Low | Natural preservation | Containment system |
| Risk/Reward Identification | Medium | Memorable gameplay | Probability system |
| Recipe Combination | High | Ingredient synergy | Recipe database |
| Buff Duration | Medium | Automatic tracking | Game loop |
| Preservation Chain | Medium | Composable methods | Spoilage system |
| Creature Interaction | Medium | NPC engagement | Creature AI |
| Economic Value Decay | Low | Market dynamics | Trade system |
| Layered Effects | Medium | System integration | Multiple subsystems |

---

## Implementation Roadmap

### Phase 1: Foundation (Low-Hanging Fruit)
- Sensory Identification (leverage existing properties)
- Tool Capability Gating (leverage existing system)
- Effect Composition (extend existing effects.lua)
- Object Mutation (leverage existing mutation system)

### Phase 2: Core Mechanics
- FSM Pattern (define food states)
- State-Based Materials (extend material system)
- Container Modifier (extend containment)
- Buff Duration Management (add to loop)

### Phase 3: Advanced Features
- Time-Driven Transitions (spoilage over time)
- Recipe Combination (multi-ingredient cooking)
- Preservation Chain (salting, smoking, drying)
- Risk/Reward Identification (unknown foods)

### Phase 4: Polish & Integration
- Creature Interaction (rat feeding, bait)
- Economic Value Decay (trade integration)
- Layered Effects (multi-system effects)

---

**Patterns Extracted: March 26, 2026**  
**Next Document:** Integration Notes
