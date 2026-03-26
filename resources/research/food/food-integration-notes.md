# Food Integration Notes — Connecting Food Systems to MMO Architecture

**Research Date:** March 26, 2026  
**Researcher:** Frink  
**Purpose:** Map food system patterns to existing MMO engine architecture

---

## Integration Overview

Our engine already has **80% of the infrastructure** needed for a robust food system. This document maps research findings to existing systems and identifies integration points.

---

## 1. Material System Integration

### Existing System
**Location:** `src/engine/materials/init.lua`  
**Current Materials:** 30+ defined (wood, metal, stone, cloth, leather, glass, etc.)

### Food Materials to Add

```lua
-- Extend materials registry

materials.cheese = {
    name = "cheese",
    properties = {
        hardness = 3,
        density = 1.1,
        flammable = false,
        edible = true,
        perishable = true,
        spoilage_rate = 0.5,  -- Slower than meat
        texture = "firm",
        moisture = 0.35
    }
}

materials.bread = {
    name = "bread",
    properties = {
        hardness = 2,
        density = 0.6,
        flammable = true,
        edible = true,
        perishable = true,
        spoilage_rate = 0.8,  -- Faster (staling)
        texture = "soft",
        moisture = 0.4
    }
}

materials.meat = {
    name = "meat",
    properties = {
        hardness = 4,
        density = 1.0,
        flammable = false,
        edible = true,
        perishable = true,
        spoilage_rate = 2.0,  -- Very fast spoilage
        texture = "fibrous",
        moisture = 0.7
    }
}

materials.fruit = {
    name = "fruit",
    properties = {
        hardness = 1,
        density = 0.9,
        flammable = false,
        edible = true,
        perishable = true,
        spoilage_rate = 1.5,  -- Fast
        texture = "soft",
        moisture = 0.8
    }
}

materials.vegetable = {
    name = "vegetable",
    properties = {
        hardness = 2,
        density = 0.8,
        flammable = false,
        edible = true,
        perishable = true,
        spoilage_rate = 1.2,
        texture = "fibrous",
        moisture = 0.75
    }
}

materials.grain = {
    name = "grain",
    properties = {
        hardness = 2,
        density = 0.7,
        flammable = true,
        edible = true,
        perishable = false,  -- Dried grains last long
        texture = "granular",
        moisture = 0.15
    }
}

materials.liquid_food = {
    name = "liquid food",
    properties = {
        hardness = 0,
        density = 1.0,
        flammable = false,
        edible = true,
        perishable = true,
        spoilage_rate = 1.8,  -- Milk, soup spoil fast
        texture = "liquid",
        moisture = 1.0
    }
}
```

### Integration Points
- Material properties auto-apply to objects
- Spoilage rate pulled from material definition
- Texture/moisture affect sensory descriptions
- Edible flag gates consumption verbs

---

## 2. FSM Engine Integration

### Existing System
**Location:** `src/engine/fsm/init.lua`  
**Current Use:** Object state machines, transitions, tick-based updates

### Food State Definitions

```lua
-- Food objects declare FSM states
-- Example: apple.lua

return {
    guid = "{apple-guid}",
    template = "small-item",
    id = "apple",
    name = "a red apple",
    keywords = {"apple", "red apple", "fruit"},
    material = "fruit",
    
    -- FSM integration
    initial_state = "fresh",
    _state = "fresh",
    
    states = {
        fresh = {
            description = "A crisp, red apple.",
            on_smell = "Sweet and fragrant.",
            on_taste = "Crisp and juicy.",
            on_feel = "Firm and smooth.",
            room_presence = "A fresh red apple lies here.",
            edible = true,
            nutrition = 20,
            safe_to_eat = true,
            casts_light = false
        },
        
        ripe = {
            description = "A perfectly ripe red apple.",
            on_smell = "Intensely sweet aroma.",
            on_taste = "Peak flavor and juiciness.",
            on_feel = "Slightly soft.",
            room_presence = "A perfectly ripe apple lies here.",
            edible = true,
            nutrition = 25,  -- Peak nutrition
            buffs = { health_regen = 1, duration = 300 },
            safe_to_eat = true
        },
        
        overripe = {
            description = "An overripe apple with soft spots.",
            on_smell = "Overly sweet, fermented.",
            on_taste = "Mushy and overly sweet.",
            on_feel = "Very soft and mushy.",
            room_presence = "An overripe apple with brown spots lies here.",
            edible = true,
            nutrition = 10,
            safe_to_eat = false,
            poison_risk = 0.2
        },
        
        spoiled = {
            description = "A rotten apple, covered in mold.",
            on_smell = "Foul, moldy stench.",
            on_taste = "Disgusting. You spit it out immediately!",
            on_feel = "Slimy and collapsing.",
            room_presence = "A rotten apple lies here, crawling with insects.",
            edible = false,
            safe_to_eat = false,
            poison_risk = 0.9
        }
    },
    
    transitions = {
        { from = "fresh", to = "ripe", trigger = "time", duration = 21600 },      -- 6 hours
        { from = "ripe", to = "overripe", trigger = "time", duration = 14400 },   -- 4 hours
        { from = "overripe", to = "spoiled", trigger = "time", duration = 7200 }  -- 2 hours
    }
}
```

### FSM Engine Changes Needed

**Add to `src/engine/fsm/init.lua`:**

```lua
-- Track time-based transitions
function fsm.tick_food_spoilage(registry, delta_time)
    for _, obj in pairs(registry.objects) do
        if obj.transitions and obj.perishable then
            for _, transition in ipairs(obj.transitions) do
                if transition.trigger == "time" and obj._state == transition.from then
                    -- Accumulate time
                    transition.elapsed = (transition.elapsed or 0) + delta_time
                    
                    -- Apply modifiers (container, temperature, preservation)
                    local effective_duration = transition.duration
                    effective_duration = apply_spoilage_modifiers(obj, effective_duration)
                    
                    if transition.elapsed >= effective_duration then
                        -- Trigger state change
                        fsm.change_state(obj, transition.to)
                        transition.elapsed = 0
                    end
                end
            end
        end
    end
end

-- Apply modifiers based on environment
function apply_spoilage_modifiers(obj, base_duration)
    local duration = base_duration
    
    -- Check if object is in container
    local container = containment.get_container(obj)
    if container and container.preservation then
        duration = duration * (1 / container.preservation.spoilage_modifier)
    end
    
    -- Check for preservation methods (salted, smoked, etc.)
    if obj.preservation_methods then
        if obj.preservation_methods.salted and obj.preservation_methods.salted.active then
            duration = duration * 5  -- 5x longer
        end
        if obj.preservation_methods.smoked and obj.preservation_methods.smoked.active then
            duration = duration * 3
        end
    end
    
    -- Future: check room temperature
    -- if room.temperature > 25 then duration = duration * 0.5 end
    
    return duration
end
```

**Integration Point:** Call `fsm.tick_food_spoilage(registry, delta_time)` from main game loop.

---

## 3. Sensory System Integration

### Existing System
**Location:** Object definitions (every object must have `on_feel`)  
**Properties:** `on_feel`, `on_smell`, `on_taste`, `on_listen`

### Food Sensory Properties (Already Compatible!)

```lua
-- Sensory properties change per state
states = {
    fresh = {
        on_feel = "Firm and cool to the touch.",
        on_smell = "Savory aroma of fresh meat.",
        on_taste = "Rich, clean flavor.",
        on_listen = "Silent."
    },
    
    spoiling = {
        on_feel = "Slightly sticky, warmer than expected.",
        on_smell = "Sour, unpleasant odor beginning to develop.",
        on_taste = "Off-flavor, questionable.",
        on_listen = "Silent."
    },
    
    spoiled = {
        on_feel = "Slimy, disgusting texture.",
        on_smell = "Overwhelming putrid stench.",
        on_taste = "VILE! You spit it out immediately!",
        on_listen = "Faint buzzing of insects."
    }
}
```

### Verb Integration

**Existing Verbs:**
- `LOOK` / `EXAMINE` — visual inspection
- `FEEL` / `TOUCH` — tactile (already implemented)
- `SMELL` / `SNIFF` — olfactory (need to add/extend)
- `TASTE` / `LICK` — gustatory (need to add/extend)
- `LISTEN` / `HEAR` — auditory (already implemented)

**Add Food-Specific Hints:**

```lua
-- Extend smell verb to provide safety hints
verbs.smell = function(context, noun)
    local obj = context.registry:find_by_keyword(noun)
    if not obj then
        err_not_found(context)
        return
    end
    
    local smell = obj.states[obj._state].on_smell or obj.on_smell or "No discernible smell."
    print(smell)
    
    -- Add safety hint for food
    if obj.edible or obj.perishable then
        if obj._state == "spoiled" or obj._state == "rotten" then
            print("\n(The smell strongly suggests this is unsafe to eat.)")
        elseif obj._state == "spoiling" or obj._state == "overripe" then
            print("\n(The smell indicates this food is past its prime.)")
        elseif obj._state == "fresh" or obj._state == "ripe" then
            print("\n(The smell suggests this is fresh and safe.)")
        end
    end
end

-- Extend taste verb for risky identification
verbs.taste = function(context, noun)
    local obj = context.registry:find_by_keyword(noun)
    if not obj then
        err_not_found(context)
        return
    end
    
    local taste = obj.states[obj._state].on_taste or obj.on_taste or "Bland."
    print(taste)
    
    -- Risky identification: tasting spoiled food causes injury
    if obj.states[obj._state].poison_risk then
        local risk = obj.states[obj._state].poison_risk
        if math.random() < risk then
            print("\nYou feel nauseous! The food is spoiled!")
            injuries.inflict(context.player, "food_poisoning", { severity = math.floor(risk * 3) })
        end
    end
end
```

### Integration Complete
Sensory system is **already perfect** for food identification gameplay. Just extend verb logic.

---

## 4. Mutation System Integration (D-14 Principle)

### Existing System
**Location:** `src/engine/mutation/init.lua`  
**Principle:** Code mutation IS state change (D-14)

### Food Cooking Mutations

```lua
-- raw-chicken.lua (before cooking)
return {
    guid = "{raw-chicken-guid}",
    template = "small-item",
    id = "raw-chicken",
    name = "a raw chicken breast",
    keywords = {"chicken", "raw chicken", "breast", "meat"},
    description = "A raw chicken breast, pale and slightly moist.",
    
    material = "meat",
    edible = false,  -- UNSAFE to eat raw
    cookable = true,
    
    on_feel = "Cold, slightly slimy meat.",
    on_smell = "Raw poultry smell.",
    on_taste = "DO NOT EAT RAW CHICKEN!",
    on_listen = "Silent.",
    
    mutations = {
        cook = {
            becomes = "cooked-chicken",
            message = "The chicken sizzles and turns golden brown over the flames.",
            requires_tool = "fire_source",
            duration = 5  -- 5 seconds cooking time
        }
    }
}

-- cooked-chicken.lua (after cooking mutation)
return {
    guid = "{cooked-chicken-guid}",  -- SAME GUID (object transforms)
    template = "small-item",
    id = "cooked-chicken",
    name = "a cooked chicken breast",
    keywords = {"chicken", "cooked chicken", "breast", "meat"},
    description = "A golden-brown chicken breast, cooked through and steaming.",
    
    material = "meat",
    edible = true,  -- NOW SAFE
    cookable = false,  -- Already cooked
    
    on_feel = "Warm and firm.",
    on_smell = "Savory roasted poultry aroma.",
    on_taste = "Juicy and flavorful.",
    on_listen = "Faint sizzling.",
    
    nutrition = 50,
    buffs = { stamina = 20, duration = 600 },  -- 10 min buff
    
    -- Cooked food still spoils, but slower
    initial_state = "fresh",
    _state = "fresh",
    
    states = {
        fresh = {
            description = "A golden-brown chicken breast, still warm.",
            safe_to_eat = true
        },
        spoiling = {
            description = "A cooked chicken breast, now cold and slightly dry.",
            safe_to_eat = false,
            poison_risk = 0.3
        },
        spoiled = {
            description = "A rotten chicken breast, covered in slime.",
            safe_to_eat = false,
            poison_risk = 0.9
        }
    },
    
    transitions = {
        { from = "fresh", to = "spoiling", trigger = "time", duration = 43200 },  -- 12 hours (slower than raw)
        { from = "spoiling", to = "spoiled", trigger = "time", duration = 21600 }  -- 6 hours
    }
}
```

### Verb Integration

```lua
verbs.cook = function(context, noun)
    local food = context.registry:find_by_keyword(noun)
    
    if not food then
        err_not_found(context)
        return
    end
    
    if not food.cookable then
        print("You can't cook that.")
        return
    end
    
    -- Check for fire source tool
    local fire = context.player:find_tool_by_capability("fire_source")
    if not fire then
        print("You need a fire source to cook.")
        return
    end
    
    -- Trigger mutation (raw-chicken.lua → cooked-chicken.lua)
    mutation.apply(food, "cook", context)
end
```

### Integration Complete
Mutation system is **perfect** for cooking transformations. Follows D-14 principle: code rewrite IS state change.

---

## 5. Injury System Integration

### Existing System
**Location:** `src/engine/injuries.lua`  
**Injury Types:** 7 defined (blunt_trauma, laceration, puncture, burn, infection, poison, disease)

### Food Poisoning Injury Type

**Add to `src/meta/injuries/`:**

```lua
-- food-poisoning.lua
return {
    id = "food_poisoning",
    name = "Food Poisoning",
    category = "disease",
    
    severities = {
        {
            level = 1,
            name = "Mild Nausea",
            description = "You feel slightly queasy.",
            effects = {
                stamina_penalty = 5,
                regen_penalty = 0.5
            },
            duration = 300,  -- 5 minutes
            messages = {
                onset = "Your stomach churns unpleasantly.",
                active = "You feel nauseous.",
                recovery = "The nausea passes."
            }
        },
        
        {
            level = 2,
            name = "Food Poisoning",
            description = "You're suffering from food poisoning.",
            effects = {
                stamina_penalty = 15,
                regen_penalty = 0,  -- No regen
                periodic_damage = 1  -- Lose 1 HP every 30 seconds
            },
            duration = 900,  -- 15 minutes
            messages = {
                onset = "Your stomach cramps violently! You've been poisoned!",
                active = "You retch and heave, weakened by poison.",
                recovery = "The food poisoning finally subsides."
            }
        },
        
        {
            level = 3,
            name = "Severe Food Poisoning",
            description = "You're gravely ill from spoiled food.",
            effects = {
                stamina_penalty = 30,
                max_health_penalty = 10,
                regen_penalty = 0,
                periodic_damage = 2,  -- 2 HP every 30 seconds
                movement_penalty = true  -- Can't move far
            },
            duration = 1800,  -- 30 minutes
            requires_treatment = true,  -- Needs medicine or rest
            messages = {
                onset = "You collapse, violently ill! This is serious!",
                active = "You're too weak to do much of anything.",
                recovery = "You finally recover from the severe poisoning."
            }
        }
    }
}
```

### Verb Integration (Eating Spoiled Food)

```lua
verbs.eat = function(context, noun)
    local food = context.registry:find_by_keyword(noun)
    
    if not food or not food.edible then
        print("You can't eat that.")
        return
    end
    
    print("You eat the " .. food.name .. ".")
    
    -- Check for poison risk
    local current_state = food.states[food._state]
    if current_state.poison_risk then
        local risk = current_state.poison_risk
        if math.random() < risk then
            -- Inflict food poisoning based on risk level
            local severity = math.ceil(risk * 3)  -- 0.3 risk = severity 1, 0.9 risk = severity 3
            injuries.inflict(context.player, "food_poisoning", { severity = severity })
        end
    end
    
    -- Apply food effects (nutrition, buffs)
    if current_state.nutrition then
        context.player.hunger = math.max(0, context.player.hunger - current_state.nutrition)
    end
    
    if current_state.buffs then
        for _, buff in ipairs(current_state.buffs) do
            context.player:add_buff(buff)
        end
    end
    
    -- Remove food from world
    context.registry:remove(food)
end
```

### Integration Complete
Food poisoning integrates seamlessly with existing injury system. Just add new injury type definition.

---

## 6. Containment System Integration

### Existing System
**Location:** `src/engine/containment/init.lua`  
**Constraints:** Size, weight, capacity validation

### Container Preservation Modifiers

```lua
-- barrel.lua (container with preservation properties)
return {
    guid = "{barrel-guid}",
    template = "container",
    id = "wooden-barrel",
    name = "a wooden barrel",
    keywords = {"barrel", "wooden barrel", "cask"},
    description = "A sturdy wooden barrel with a removable lid.",
    
    size = 50,
    weight = 20,
    capacity = 50,  -- Can hold 50 units of items
    
    -- NEW: Preservation properties
    preservation = {
        enabled = true,
        spoilage_modifier = 0.3,  -- 70% slower spoilage
        applies_to = { "small-item" },  -- Applies to food items (template: small-item)
        description = "The sealed barrel slows food spoilage significantly."
    },
    
    on_feel = "Rough, sturdy wood.",
    on_smell = "Faint scent of wood and must.",
    on_listen = "Hollow when tapped.",
    
    contents = {},
    nested = {},
    on_top = {},
    underneath = {}
}
```

### FSM Integration for Containers

**Modify spoilage calculation in FSM engine:**

```lua
function apply_spoilage_modifiers(obj, base_duration)
    local duration = base_duration
    
    -- Check if object is in a container
    local container = containment.get_container(obj)
    if container and container.preservation and container.preservation.enabled then
        -- Check if container's preservation applies to this object type
        if table_contains(container.preservation.applies_to, obj.template) then
            duration = duration * (1 / container.preservation.spoilage_modifier)
        end
    end
    
    -- Other modifiers...
    
    return duration
end
```

### Integration Complete
Containers naturally slow spoilage via preservation modifiers. Leverages existing containment constraints.

---

## 7. Creature Drive System Integration

### Existing System
**Location:** `src/meta/creatures/rat.lua` (creature already has hunger drive!)

### Food as Hunger Satisfaction

```lua
-- Extend rat.lua with diet preferences
return {
    guid = "{rat-guid}",
    template = "small-item",
    id = "rat",
    name = "a large rat",
    keywords = {"rat", "rodent"},
    description = "A large brown rat with beady eyes and a long tail.",
    
    -- Existing hunger drive
    drives = {
        hunger = {
            current = 50,  -- 0-100 scale (0 = starving, 100 = full)
            decay_rate = 1,  -- Loses 1 point per game hour
            threshold = 30,  -- Below this, seeks food
            behavior = "seek_food"
        }
    },
    
    -- NEW: Diet preferences
    diet = {
        prefers = { "cheese", "bread", "grain" },  -- Will seek these first
        will_eat = { "meat", "fruit", "vegetable" },  -- Will eat if hungry enough
        rejects = { "poison", "metal", "stone" }  -- Will never eat
    },
    
    -- NEW: Reaction to food
    food_reaction = function(self, food)
        if table_contains(self.diet.rejects, food.material) then
            return "rejects"
        elseif table_contains(self.diet.prefers, food.id) or table_contains(self.diet.prefers, food.material) then
            return "prefers"
        elseif table_contains(self.diet.will_eat, food.material) then
            return "accepts"
        else
            return "neutral"
        end
    end
}
```

### Bait Mechanic

```lua
verbs.place = function(context, noun)
    local food = context.registry:find_by_keyword(noun)
    
    if not food.edible then
        print("That's not suitable as bait.")
        return
    end
    
    -- Place food in room
    local room = context.player.current_room
    food.is_bait = true
    food.bait_placed_at = game_time.current
    containment.place_in_room(food, room)
    
    print("You carefully place the " .. food.name .. " on the ground.")
    print("(Perhaps it will attract something...)")
end
```

### Creature AI Integration

```lua
-- Creature turn: check for food in room
function creature.tick(self, context)
    -- Hunger drive check
    if self.drives.hunger.current < self.drives.hunger.threshold then
        -- Look for food in current room
        local room = containment.get_container(self)
        for _, obj in ipairs(room.contents) do
            if obj.edible then
                local reaction = self:food_reaction(obj)
                
                if reaction == "prefers" then
                    -- Move toward and eat food
                    print("The " .. self.name .. " scurries toward the " .. obj.name .. "!")
                    self:eat_food(obj)
                    return
                elseif reaction == "accepts" and self.drives.hunger.current < 20 then
                    -- Only eat acceptable food if very hungry
                    print("The " .. self.name .. " reluctantly approaches the " .. obj.name .. ".")
                    self:eat_food(obj)
                    return
                end
            end
        end
    end
end

function creature.eat_food(self, food)
    print("The " .. self.name .. " devours the " .. food.name .. "!")
    self.drives.hunger.current = math.min(100, self.drives.hunger.current + food.nutrition)
    
    -- If food was bait and player is present, creature may become friendly
    if food.is_bait then
        print("The " .. self.name .. " looks at you with less hostility.")
        self.disposition_toward_player = (self.disposition_toward_player or 0) + 10
    end
    
    context.registry:remove(food)
end
```

### Integration Complete
Rat hunger drive already exists! Just add diet preferences and food-seeking behavior.

---

## 8. Tool System Integration

### Existing System
**Location:** `src/engine/verbs/init.lua` (tool capability checks)  
**Current Capabilities:** `fire_source`, `cutting_edge`, `blunt_force`

### New Food-Related Capabilities

```lua
-- Add to tool capability definitions

capabilities.cooking_vessel = {
    description = "Can be used for boiling, stewing, or brewing.",
    enables = { "boil", "stew", "brew" }
}

capabilities.preservation_tool = {
    description = "Can be used to preserve food.",
    enables = { "salt", "smoke", "dry", "cure" }
}

capabilities.cutting_tool = {
    description = "Can cut, slice, chop, and prepare ingredients.",
    enables = { "cut", "slice", "chop", "prepare" }
}
```

### Example Tool Objects

```lua
-- pot.lua
return {
    guid = "{pot-guid}",
    template = "container",
    id = "iron-pot",
    name = "an iron pot",
    keywords = {"pot", "iron pot", "cooking pot"},
    description = "A sturdy iron pot with a handle.",
    
    capabilities = { "cooking_vessel" },
    
    capacity = 10,
    on_feel = "Heavy iron, cool to touch.",
    on_smell = "Faint metallic smell.",
    on_listen = "Hollow metallic clang when tapped."
}

-- salt-pouch.lua
return {
    guid = "{salt-pouch-guid}",
    template = "small-item",
    id = "salt-pouch",
    name = "a pouch of salt",
    keywords = {"salt", "pouch", "salt pouch"},
    description = "A leather pouch filled with coarse salt.",
    
    capabilities = { "preservation_tool" },
    consumable = true,
    uses_remaining = 10,  -- Can salt 10 items
    
    on_feel = "Granular crystals through leather.",
    on_smell = "Faint salty smell.",
    on_taste = "Intensely salty!"
}
```

### Verb Tool Checks

```lua
verbs.salt = function(context, noun)
    local food = context.registry:find_by_keyword(noun)
    
    if not food or not food.material or not table_contains({"meat", "fish"}, food.material) then
        print("You can't salt that.")
        return
    end
    
    -- Check for salt tool
    local salt = context.player:find_tool_by_capability("preservation_tool")
    if not salt or not string.find(salt.id, "salt") then
        print("You need salt to preserve that.")
        return
    end
    
    -- Apply salting
    if not food.preservation_methods then food.preservation_methods = {} end
    food.preservation_methods.salted = { active = true, modifier = 0.2 }
    
    print("You rub salt into the " .. food.name .. ", preserving it.")
    
    -- Consume salt usage
    if salt.uses_remaining then
        salt.uses_remaining = salt.uses_remaining - 1
        if salt.uses_remaining == 0 then
            print("The " .. salt.name .. " is now empty.")
            context.registry:remove(salt)
        end
    end
end
```

### Integration Complete
Tool capability system easily extends to food preparation tools.

---

## 9. Effects Pipeline Integration

### Existing System
**Location:** `src/engine/effects.lua`  
**Current Use:** Unified effect processing (traverse, object, injury)

### Food Effect Types

```lua
-- Add to effects pipeline

effects.apply_food = function(player, food)
    local current_state = food.states[food._state]
    
    -- Nutrition (reduces hunger)
    if current_state.nutrition then
        player.hunger = math.max(0, player.hunger - current_state.nutrition)
    end
    
    -- Healing
    if current_state.healing then
        player.health = math.min(player.max_health, player.health + current_state.healing)
        print("You feel revitalized.")
    end
    
    -- Buffs
    if current_state.buffs then
        for _, buff in ipairs(current_state.buffs) do
            player:add_buff(buff)
            print("You feel " .. buff.stat .. " increase!")
        end
    end
    
    -- Debuffs / Injuries
    if current_state.poison_risk and math.random() < current_state.poison_risk then
        local severity = math.ceil(current_state.poison_risk * 3)
        injuries.inflict(player, "food_poisoning", { severity = severity })
    end
    
    -- Mood / Morale
    if current_state.mood_effect then
        player.mood = player.mood + current_state.mood_effect
        if current_state.mood_effect > 0 then
            print("The delicious food lifts your spirits.")
        else
            print("The unpleasant food dampens your mood.")
        end
    end
    
    -- Special effects (temporary mutations, resistances, etc.)
    if current_state.special_effects then
        for _, effect in ipairs(current_state.special_effects) do
            effects.apply(player, effect)
        end
    end
end
```

### Integration Complete
Effects pipeline naturally handles food consumption effects.

---

## 10. Time System Integration

### Existing System
**Location:** `src/engine/loop/init.lua` (game loop ticks time)  
**Current Time:** Tracked as game hours, real time → game time conversion

### Spoilage Time Tracking

```lua
-- Add to game loop (src/engine/loop/init.lua)

function loop.tick()
    -- Existing tick logic...
    
    -- Tick food spoilage (call FSM spoilage ticker)
    local delta_time = calculate_delta_time()  -- Seconds since last tick
    fsm.tick_food_spoilage(context.registry, delta_time)
    
    -- Tick creature hunger
    for _, obj in pairs(context.registry.objects) do
        if obj.drives and obj.drives.hunger then
            obj.drives.hunger.current = math.max(0, obj.drives.hunger.current - obj.drives.hunger.decay_rate * (delta_time / 3600))
        end
    end
    
    -- Tick player buffs
    for i = #context.player.active_buffs, 1, -1 do
        local buff = context.player.active_buffs[i]
        buff.duration = buff.duration - delta_time
        
        if buff.duration <= 0 then
            print("Your " .. buff.stat .. " buff has worn off.")
            table.remove(context.player.active_buffs, i)
        end
    end
end
```

### Integration Complete
Game loop ticks spoilage, hunger, and buff durations automatically.

---

## 11. UI Integration

### Existing System
**Location:** `src/engine/ui/init.lua` (terminal UI), `src/engine/ui/status.lua` (status bar)

### Food Status Display

```lua
-- Add to status bar display

function status.render()
    -- Existing status (health, location, time, light)...
    
    -- Hunger status (if implemented)
    if player.hunger then
        local hunger_status = get_hunger_status(player.hunger)
        print("Hunger: " .. hunger_status)
    end
    
    -- Active buffs
    if #player.active_buffs > 0 then
        print("Buffs: " .. format_active_buffs(player.active_buffs))
    end
    
    -- Active injuries (food poisoning)
    if #player.injuries > 0 then
        print("Status: " .. format_injuries(player.injuries))
    end
end

function get_hunger_status(hunger)
    if hunger < 10 then return "Well-fed"
    elseif hunger < 30 then return "Satisfied"
    elseif hunger < 50 then return "Neutral"
    elseif hunger < 70 then return "Hungry"
    elseif hunger < 90 then return "Very Hungry"
    else return "Starving" end
end
```

### Integration Complete
Status bar displays hunger, buffs, and food-related injuries.

---

## 12. Two-Hand Inventory Integration

### Existing System
**Location:** `src/architecture/player/player-model.md` (two hand slots)

### Food Carrying Strategy

```lua
-- Food in hands is a strategic choice
-- Can hold cooking tools OR food, not both (unless compound action)

verbs.take = function(context, noun)
    local obj = context.registry:find_by_keyword(noun)
    
    -- Check hand availability
    if context.player.left_hand and context.player.right_hand then
        print("Your hands are full.")
        return
    end
    
    -- Place in available hand
    if not context.player.left_hand then
        context.player.left_hand = obj
        print("You take the " .. obj.name .. " in your left hand.")
    else
        context.player.right_hand = obj
        print("You take the " .. obj.name .. " in your right hand.")
    end
    
    containment.remove_from_parent(obj)
end

-- Compound action: hold food + fire source to cook
verbs.cook = function(context, noun)
    -- Must have both food and fire in hands
    local food = context.player:find_in_hands(noun)
    if not food then
        print("You're not holding that.")
        return
    end
    
    local fire = context.player:has_tool_capability_in_hands("fire_source")
    if not fire then
        print("You need a fire source in your other hand.")
        return
    end
    
    -- Cook!
    mutation.apply(food, "cook", context)
end
```

### Integration Complete
Two-hand inventory creates strategic choices for food handling.

---

## Integration Summary

### Systems Ready to Use (No Changes Needed)
1. ✅ **Sensory Properties** — `on_smell`, `on_taste`, `on_feel` already exist
2. ✅ **Tool Capabilities** — Just add new capability types
3. ✅ **Mutation System** — Perfect for cooking (raw → cooked)
4. ✅ **Containment** — Container preservation just adds modifiers
5. ✅ **Two-Hand Inventory** — Food handling naturally fits

### Systems Requiring Minor Extension
6. 🔧 **Material System** — Add 7 food materials (cheese, bread, meat, fruit, vegetable, grain, liquid)
7. 🔧 **FSM Engine** — Add spoilage time tracking (50 lines of code)
8. 🔧 **Injury System** — Add food poisoning injury type (1 new file)
9. 🔧 **Effects Pipeline** — Add food effect application (30 lines)
10. 🔧 **Game Loop** — Tick spoilage, hunger, buffs (20 lines)

### Systems Requiring New Implementation
11. 🆕 **Recipe System** — New module for ingredient combinations
12. 🆕 **Buff Tracking** — Player buff table + display (50 lines)
13. 🆕 **Creature Diet AI** — Food-seeking behavior (100 lines)

### Estimated Effort
- **Phase 1 (Basic Consumables):** 2-4 hours
- **Phase 2 (Cooking + Mutation):** 4-6 hours
- **Phase 3 (Spoilage + FSM):** 8-12 hours
- **Phase 4 (Preservation + Containers):** 6-8 hours
- **Phase 5 (Recipes + Creatures):** 12-16 hours

**Total:** 32-46 hours for full implementation.

---

## Recommended Implementation Order

### Sprint 1: Foundation (8 hours)
1. Add food materials to material system
2. Create 5 basic food objects (bread, cheese, apple, meat, water)
3. Implement `EAT` and `DRINK` verbs with simple effects
4. Add sensory hints to `SMELL` and `TASTE` verbs

**Deliverable:** Players can eat food and get basic buffs; sensory system works.

### Sprint 2: Cooking (10 hours)
1. Create raw food objects (raw-meat, raw-chicken, raw-fish)
2. Define cooking mutations (raw → cooked via mutation system)
3. Implement `COOK` verb with fire_source tool check
4. Add cooked food objects with better buffs

**Deliverable:** Players can cook raw food using fire; cooked food provides better benefits.

### Sprint 3: Spoilage (14 hours)
1. Extend FSM engine with time-based spoilage tracking
2. Define food FSM states (fresh, spoiling, spoiled)
3. Add food poisoning injury type
4. Integrate spoilage ticks into game loop
5. Test spoilage progression over game time

**Deliverable:** Food spoils over time; spoiled food causes injury; sensory identification works.

### Sprint 4: Preservation (10 hours)
1. Add preservation tools (salt, smoking rack)
2. Define preservation methods (salted, smoked, dried)
3. Implement `SALT`, `SMOKE`, `DRY` verbs
4. Add container preservation modifiers
5. Test preservation slows spoilage

**Deliverable:** Players can preserve food; containers extend shelf life.

### Sprint 5: Creatures + Recipes (12 hours)
1. Extend rat with diet preferences
2. Implement creature food-seeking AI
3. Add `FEED` and `PLACE` (bait) verbs
4. Create recipe system
5. Implement `COMBINE` verb for multi-ingredient cooking
6. Test creature interactions and recipes

**Deliverable:** Players can feed creatures, use food as bait, combine ingredients for better meals.

---

## Testing Strategy

### Unit Tests
- Material properties correctly applied
- FSM state transitions trigger at right times
- Spoilage modifiers calculate correctly
- Tool capability checks work
- Mutation system rewrites food files

### Integration Tests
- Food in containers spoils slower
- Cooking transforms raw → cooked
- Eating spoiled food inflicts injury
- Buffs apply and expire correctly
- Creature AI seeks food when hungry

### Playtesting Scenarios
1. Start with raw meat, find fire, cook meat, eat cooked meat
2. Leave food in room, watch it spoil over game days
3. Salt meat, observe extended shelf life
4. Feed rat cheese, observe hunger decrease and disposition improvement
5. Combine ingredients, create complex meal with multiple buffs

---

**Integration Documentation Complete: March 26, 2026**  
**Ready for Design Planning Phase**
