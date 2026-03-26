# Food Systems Research: Comprehensive Investigation

**Research Date:** March 26, 2026  
**Researcher:** Frink (Squad Research Agent)  
**Purpose:** Investigate food systems across games, MUDs, board games, and real-world biology to inform MMO text adventure food design

---

## Executive Summary

This document synthesizes food system research from 15+ games/systems, examining how food operates as:
- **Resource** (hunger, satiation, spoilage)
- **Crafting system** (cooking, recipes, tools)
- **Game mechanic** (buffs/debuffs, poison, healing)
- **World-building** (cuisine, creature diets, ecosystems)
- **Puzzle content** (quests, challenges)
- **Health system** (nutrition, disease, medicine)
- **NPC behavior** (hunger drives, feeding, bait)
- **Material** (properties, state transitions, decay)

**Key Finding:** Dwarf Fortress provides the most comprehensive food simulation, balancing resource management, preservation, creature preferences, and emotional impact. NetHack offers the most risk/reward depth. Modern survival games (Valheim, Don't Starve) demonstrate buff-driven food as strategic choice. MUDs show minimal food systems designed for immersion, not survival challenge.

---

## 1. Dwarf Fortress — The Gold Standard

**Wayne's Primary Design Inspiration**

### Food Acquisition & Processing
- **Sources:** Farming (most reliable), plant gathering, fishing, hunting, livestock, eggs, trapping, trading
- **Processing Required:** Fat → tallow, raw fish → cleaned, crops → milled/brewed before cooking
- Seeds require preservation strategy (brew vs. cook trade-off)

### Cooking System
- **Kitchen Mechanics:**
  - 3 meal types by ingredient count: Easy (2), Fine (3), Lavish (4)
  - Quality modifiers from cook skill dramatically increase value
  - Cooking destroys seeds UNLESS crop is brewed/processed first
  - Prepared meals are **immune to spoilage** (key preservation method)
- **Happiness Impact:** Eating preferred meals boosts dwarf morale; variety matters

### Brewing
- **Critical for Dwarves:** Alcohol is essential (they drink booze, not water)
- Operates at stills; plump helmets are primary ingredient
- **Strategic Trade-off:** Don't cook all brewables or you lose alcohol supply

### Preservation & Spoilage
- **Cooking as Preservation:** Converting raw → prepared meal prevents rot
- **Raw Food Spoilage:** Produces miasma (unhappy thoughts in enclosed spaces)
- **Storage:** Barrels/pots required; prevents spoilage, enables efficient hauling
- **Exception:** Some items (dwarven syrup, tallow) don't spoil

### Creature Diets & Preferences
- **Dwarves:** Need ~2 food units/season; have individual food/drink preferences
- **Livestock:** May graze or require specific feeds
- **Carnivores:** Cats hunt vermin autonomously
- **Preference System:** Matching preferred meals = happiness boost

### Storage Architecture
- Designated stockpiles near kitchens/dining rooms minimize hauling
- Containers (barrels/pots) made from wood, metal, stone, clay, glass
- Insufficient storage → food rots on ground, becomes inaccessible

### Design Implications for MMO
- Food as emotional mechanic (preferences, morale)
- Cooking solves spoilage problem (state transition: perishable → preserved)
- Container system creates logistics puzzle
- Seed preservation creates strategic tension (cook now vs. plant later)
- Multi-step processing (raw → cleaned → cooked → meal)

---

## 2. MUDs — Minimalist Hunger Mechanics

### Discworld MUD

**Philosophy:** Food is primarily for roleplay flavor, not survival challenge

- **Verbs:** `eat`, `eat from`, `drink`, `quaff`, `sip`, `taste` (granular liquid consumption)
- **Decay:** Food items decay over time unless preserved (pickling)
- **Effects:** Most food is aesthetic; some causes nausea, poison, drunkenness, healing
- **Combat Interaction:** Drinking during combat risks enemies smashing your container
- **Quirky Edibles:** Paper, magical fluff, corpse parts for roleplay/side effects
- **NPC Feeding:** Summoned fruitbat requires feeding (rare mechanic)

### Achaea / Iron Realms Games

**Philosophy:** Hunger exists but doesn't interrupt gameplay flow

- **Hunger/Thirst:** Light mechanic; mild penalties if ignored (reduced regen)
- **Verbs:** `eat <item>`, `drink <item>`, `quaff <potion>` (potions ≠ food)
- **Buffs:** Some foods/drinks provide buffs, healing, or cure afflictions
- **Economy:** Food creates in-game markets (taverns, crafted goods)
- **Design Choice:** Avoids intrusive survival pressure; focuses on combat/RP

### LegendMUD & Classic MUDs

- **Traditional RPG:** Eat/drink to satisfy hunger/thirst
- **Impact:** Stat debuff or regen penalty if ignored
- **Verbs:** `eat`, `drink`, `fill`, `pour` (container management)
- **Generally:** More pronounced than Achaea but still light-touch

### MUD Design Patterns
1. **Non-Intrusive:** Food systems never block progression or become tedious
2. **Roleplay Enhancement:** Text descriptions, quirky items, cultural flavor
3. **Optional Engagement:** Players can ignore food unless building specific RP scenarios
4. **Verb Granularity:** MUDs excel at verb variety (`sip` vs. `quaff` vs. `drink`)

---

## 3. NetHack — High-Risk Food Identification

**Philosophy:** Food is a core survival mechanic with deadly consequences

### Nutrition & Hunger States
- **Hunger Levels:** Not Hungry (150-999) → Hungry (50-149) → Weak (0-49) → Fainting → Death
- **Oversatiation:** Eating above 1000/2000 nutrition risks choking (fatal)
- **Starvation Penalties:** Stat penalties, collapse, death

### Comestible Types
1. **Prepared Food:** Food rations (800 nutrition), cram rations, lembas wafers, fruit
   - Safe but can randomly become "rotten" (~1/7 chance if unblessed)
   - Rotten food causes confusion, blindness, or nausea
2. **Monster Corpses:** Dramatically variable nutrition, safety, effects

### Corpse Eating: The Core Risk/Reward System

**Nutrition Range:** Lichen (200), lizard (40), wide variance by creature

**Rotting Mechanic:**
- Most corpses rot after 30 turns → food poisoning (fatal without cure)
- **Never Rot:** Lichen, lizard (always safe emergency food)
- **Preservation:** Ice box, tinning kit

**Danger Vectors:**
- **Poison/Acid:** Some corpses are toxic without resistances
- **Cockatrice/Chickatrice:** Instant petrification if eaten unprotected
- **Food Poisoning:** Requires prayer or unicorn horn cure

**Intrinsic Rewards:**
- Fire giant corpse → fire resistance
- Killer bee corpse → poison resistance  
- Floating eye corpse → telepathy
- **Strategic Depth:** Risk death for permanent power-ups

### Food Identification Strategy
- **Pet Test:** Pets avoid poisonous corpses (except tripe); use as safety check
- **Safe Bets:** Lichen/lizard = zero-risk backup food
- **Monster Knowledge:** Undead/magical creatures tend to be unsafe; mundane animals safer
- **Blessed/Cursed:** Affects taint rate for prepared food

### Design Implications for MMO
- Food as **risk/reward** mechanic (poison vs. buffs)
- Identification mini-game (smell, pet test, trial-and-error)
- **State-based danger:** Fresh vs. rotten corpses
- Emergency safe food (our equivalent: bread ration?)
- Tinning/preservation as crafting skill

---

## 4. Text IF (Zork, Infocom) — Food as Flavor & Puzzle

**Philosophy:** Food exists for immersion and occasional puzzle utility

### Zork I Food Mechanics
- **Items:** Lunch (brown sack in kitchen), garlic clove
- **Verb:** `EAT LUNCH`, `EAT GARLIC`
- **Response:** Descriptive flavor text ("Chewy, but not bad.")
- **Puzzle Role:** Minimal—garlic may have utility; lunch is purely consumable flavor

### Parser Behavior
- Objects with `[edible]` property respond to `EAT` verb
- Invalid targets get witty rebuffs ("You can't eat the sword.")
- `TASTE` verb rarely implemented unless puzzle-specific

### Food in Infocom Canon
- **Primary Use:** Realism, humor, world-building
- **Occasional Puzzles:** Distracting creatures, bribery, identifying poisoned items
- **Hunger Mechanics:** Rare; usually time-limited scenarios, not persistent stat

### Modern IF (Post-Infocom)
- **Expanded Mechanics:** Games like "Violet" or "Counterfeit Monkey" use taste/food for plot advancement
- **Inform 7 / TADS:** Custom food mechanics easy to implement; developers create complex taste/nutrition systems

### Design Implications for MMO
- Food as **atmospheric detail** (lunch in starting room)
- `TASTE` verb integration (we already have `on_taste` sensory property!)
- Puzzle utility (feed creature to befriend, bait traps)
- Humorous parser responses for invalid attempts

---

## 5. Survival Games — Buff-Driven Strategic Food

### Don't Starve

**Philosophy:** Food is life-or-death survival challenge

- **Hunger Meter:** Reaches zero → rapid health loss → death
- **Food Stages:** Raw (berries, meat) → Cooked (roasted) → Crock Pot recipes (advanced)
- **Cooking Benefits:** Improves health/hunger/sanity restoration, manages spoilage
- **Recipes:** Meatballs, Pierogi, Ratatouille (each optimized for hunger/health/sanity)
- **Preservation:** Drying racks for jerky (extended shelf life + sanity boost)
- **Strategic Depth:** Recipe choice matters; spoilage creates urgency

### Valheim

**Philosophy:** Food as buff system, not survival challenge

- **Mechanic:** No hunger bar; food provides **timed buffs** (health, stamina, Eitr)
- **3 Food Slots:** Can eat 3 different foods; can't eat same food twice until buff fades
- **Food Types:**
  - Health foods (Lox Meat Pie)
  - Stamina foods (Fish Wraps)
  - Eitr foods (magic energy)
- **Cooking Tiers:** Raw → Cooking Station → Cauldron → Oven (progression-locked)
- **Strategic Planning:** Choose food loadout before tough battles/exploration
- **Fermentation:** Mead (potions) via fermenter

### Minecraft (Vanilla + Mods)

**Vanilla:**
- **Hunger Bar:** Must eat to maintain; low hunger stops regen/sprinting
- **Cooking:** Furnace, smoker, campfire increases saturation
- **Food Range:** Apples, bread → golden carrots, cake

**Modded (Pam's HarvestCraft, Farmer's Delight, Spice of Life):**
- **Valheim-Style:** Spice of Life mod requires 3 different foods for max health/regen
- **Recipe Depth:** Hundreds of new foods, cooking stations, effects
- **Variety Incentive:** Punishes "chugging bread"; rewards creative cooking

### Comparative Insights

| Game | Food Purpose | Failure State | Complexity | Preservation |
|------|--------------|---------------|------------|--------------|
| Don't Starve | Survival | Death | High | Drying, Crock Pot |
| Valheim | Strategic buffs | Weakness | Medium | Mead fermentation |
| Minecraft | Maintenance | Stat loss | Low (vanilla) | Cooking only |
| Minecraft (modded) | Strategic variety | Weakness | High | Varies by mod |

---

## 6. Roguelikes — Food as Character Development

### Caves of Qud

**Philosophy:** Food creates buffs and temporary mutations

- **Hunger:** Basic resource; starvation develops slowly (not punishing)
- **Cooking System:** Combine up to 3 ingredients at campfire/oven
  - Skills: Meal Preparation, Spicer, Carbide Chef
  - Effects: Buffs, triggered abilities ("When afraid, emit frost rays")
  - **Mutations:** Some meals grant temporary mutations
- **Recipe Learning:** Unlock recipes for reliable buff effects
- **Mushroom Meals:** Exotic foods with unique effects

### Cataclysm: Dark Days Ahead (CDDA)

**Philosophy:** Hardcore survival simulation

- **Detailed Tracking:** Calories, thirst, vitamins, nutrition
- **Malnutrition:** Vitamin deficiencies, disease, food poisoning
- **Preservation:** Smoking, dehydrating, fermenting, canning
- **Crafting Depth:** Chemistry, mutagen serums (food as mutation vector)
- **Mutation System:** Permanent via serums; themed categories (rat, plant)

### Dungeon Crawl Stone Soup (DCSS)

**Philosophy:** Streamlined—hunger removed in recent versions

- **Current State:** Food mostly for healing or mutation cures
- **No Cooking/Crafting:** Focus on tactical combat, not resource management
- **Mutations:** From magic/monster attacks, not food

### Roguelike Design Patterns

| Game | Food Role | Mutation Source | Crafting | Survival Pressure |
|------|-----------|-----------------|----------|-------------------|
| Caves of Qud | Buff engineering | Food + injectors | Medium | Low |
| Cataclysm DDA | Realistic survival | Mutagen chemistry | Very High | Very High |
| DCSS | Minimal utility | Magic/monsters | None | None |

---

## 7. Board Games — Food as Resource Economy

### Agricola

**Mechanic:** 17th-century farming; worker placement
- **Core Tension:** Feed family every harvest or suffer harsh penalties
- **Resources:** Wood, clay, stone, grain, animals
- **Food Pressure:** Relentless; must balance expansion with sustainable food production
- **Strategy:** Tight action spaces; high blocking competition

### Viticulture

**Mechanic:** Vineyard management; seasonal worker placement
- **Resources:** Grapes, wine, money, visitor cards
- **Food Role:** Wine production (not survival food)
- **Seasons:** Actions locked to specific seasons (planning critical)
- **Strategy:** Efficient wine creation process, fulfilling orders

### A Feast for Odin

**Mechanic:** Viking resource collection; polyomino tile placement
- **Resources:** Huge array (fish, meat, vegetables, treasures)
- **Food Requirement:** Each round, "hold a feast" (set of food types) or suffer penalties
- **Worker Placement:** 60+ action choices (less blocking than Agricola)
- **Polyomino Puzzle:** Place resource tiles to cover penalties, maximize income
- **Strategy:** Diversify resources, explore via boats, cover negative spaces

### Board Game Design Patterns

| Game | Food Pressure | Worker Placement | Additional Mechanic | Player Interaction |
|------|---------------|------------------|---------------------|-------------------|
| Agricola | Very High | Tight (blocking) | None | High (cutthroat) |
| Viticulture | Low (wine focus) | Moderate (seasonal) | Visitor cards | Moderate |
| A Feast for Odin | Medium (flexible) | Expansive (60+ spaces) | Polyomino tile puzzle | Low (many options) |

### Key Insight
Board games model food as **economic pressure**, forcing strategic choices about resource allocation, timing, and risk management.

---

## 8. MTG Food Tokens — Food as Game Resource

**Introduced:** Throne of Eldraine (2019)

### Mechanics
- **Token:** Colorless artifact with subtype "Food"
- **Ability:** `{2}, {T}, Sacrifice: Gain 3 life`
- **Speed:** Instant (can respond to threats)

### Strategic Uses
1. **Lifegain:** Basic utility in attrition/racing strategies
2. **Sacrifice Payoffs:** Trigger abilities (Korvold, Fae-Cursed King draws cards on sacrifice)
3. **Artifact Synergies:** Counts as artifact for metalcraft, affinity, etc.
4. **Alternative Uses:** Tempting Witch (sacrifice Food → opponent loses 3 life)

### Flavor
- Fairy-tale inspired (Throne of Eldraine theme)
- Joins Clue and Treasure tokens as artifact resources
- Recurring mechanic (appeared in Modern Horizons 2, LOTR, Wilds of Eldraine)

### Design Implications for MMO
- Food as **token/resource** (not just consumable)
- Multiple uses beyond eating (crafting component, bait, trade goods)
- Sacrifice for benefit (eat now vs. use later tension)

---

## 9. Real-World Food Science

### Preservation Methods

#### Drying
- **Principle:** Reduces water activity (aw); halts microbial growth
- **Effective Against:** Most bacteria, yeast, mold (exceptions: spore-formers, some fungi)
- **Examples:** Jerky, sun-dried tomatoes, dried fish
- **Game Mechanic:** Time + weather dependent; risk mold if humidity too high

#### Smoking
- **Principle:** Drying + antimicrobial smoke compounds (formaldehyde, phenols)
- **Effective Against:** Surface microbes, insects
- **Often Combined:** With salting/drying for long-term storage
- **Examples:** Smoked salmon, ham, bacon
- **Game Mechanic:** Smokehouse, wood type, temperature; improper technique risks spoilage

#### Salting
- **Principle:** Osmotic stress; draws water from food and microbes
- **Effective Against:** Most bacteria (less effective vs. salt-tolerant yeasts/molds)
- **Examples:** Salted fish, salt pork, pickled vegetables
- **Game Mechanic:** Salt as resource; balance amount (too little = spoilage, too much = unpalatable)

#### Fermentation
- **Principle:** Beneficial microbes produce acids/alcohols, lowering pH
- **Effective Against:** Pathogens via hostile acidic/alcoholic environment
- **Examples:** Sauerkraut, kimchi, miso, yogurt, cheese, pickles
- **Game Mechanic:** Starter cultures, time/temperature monitoring; failure → mold/spoilage

### Spoilage Factors
- **Temperature:** High accelerates; refrigeration slows
- **Humidity:** Affects bread, cheese (higher = faster spoilage)
- **Microbial Load:** Time + air exposure increases risk
- **Intrinsic:** Water activity, pH, fat/protein content

### Food Chains & Ecology

#### Trophic Levels
- **Producers:** Plants (photosynthesis)
- **Primary Consumers:** Herbivores (eat plants)
- **Secondary/Tertiary Consumers:** Carnivores/omnivores (eat animals)
- **Decomposers:** Break down dead matter

#### Animal Diets
- **Herbivores:** Plant-only (deer, rabbits)
- **Carnivores:** Animal-only (lions, hawks)
- **Omnivores:** Both (bears, humans, rats)

#### Predator-Prey Dynamics
- Predator populations rise/fall with prey availability
- Prey develop defenses (camouflage, toxins)
- Classic cycles: lynx/hare, wolf/deer

### Material Properties by Food Type

| Food | Moisture | Spoilage Rate | Key Risks | Preservation Methods |
|------|----------|---------------|-----------|---------------------|
| Cheese | Low-Medium | Slow-Medium | Mold, hardening | Wax coating, refrigeration |
| Bread | Low | Fast (staling) | Mold (humid), drying | Wrapping, toasting when stale |
| Meat | High | Very Fast | Bacteria (Pseudomonas, Listeria) | Smoking, salting, drying, cooking |
| Eggs | Medium | Medium | Internal rot, sulfurous odor | Refrigeration, pickling |
| Milk | Very High | Very Fast | Souring, curdling, bacteria | Pasteurization, refrigeration, cheese-making |

---

## 10. Cross-System Patterns & Insights

### Pattern 1: Food as State Machine
**Implementation:** Fresh → Stale/Old → Spoiled → Rotten
- Dwarf Fortress: Raw → Prepared (preservation via cooking)
- NetHack: Fresh corpse → Rotten corpse (30 turns)
- Survival games: Raw → Cooked → Preserved (jerky, etc.)
- **FSM Architecture:** State-based design pattern; transitions triggered by time, temperature, or player actions

### Pattern 2: Multiple Food Purposes
Games layer food functions:
1. **Survival** (hunger satisfaction)
2. **Buffs** (stat boosts, abilities)
3. **Healing** (HP restoration)
4. **Economy** (trade goods, currency)
5. **Puzzle** (bait, bribes, keys)
6. **Crafting ingredient** (recipes, potions)
7. **Risk** (poison, disease)

### Pattern 3: Sensory Identification
- **Smell:** Safe detection method (NetHack pet test, real-world spoilage detection)
- **Taste:** High-risk identification (poison, but definitive)
- **Visual:** Color, mold, texture (rot indicators)
- **Touch:** Texture changes (slimy meat, hard cheese)
- **Our Engine:** Already has `on_smell`, `on_taste`, `on_feel` sensory properties!

### Pattern 4: Creature Hunger as Behavior Driver
- Dwarf Fortress: Creatures graze, hunt vermin autonomously
- Our Rat: Already has hunger drive!
- Potential: Food as bait, feeding befriends creatures, hunger drives exploration

### Pattern 5: Cooking as Value-Add
Every system with cooking shows: Raw < Cooked < Recipe Meal
- Dwarf Fortress: Ingredient count determines meal tier
- Caves of Qud: Ingredient combinations create triggered effects
- Valheim: Cooking tier unlocks determine buff power
- Don't Starve: Crock Pot recipes optimize stat restoration

### Pattern 6: Container/Storage Logistics
- Dwarf Fortress: Barrels/pots prevent spoilage, enable hauling
- Real-world: Jars, crocks, barrels for fermentation/preservation
- Potential: Our containment system already tracks capacity/size/weight

---

## 11. Implications for MMO Text Adventure

### What We Already Have (Leverage These!)

1. **Sensory System:**
   - `on_feel` (required on all objects—tactile identification)
   - `on_smell` (safe food identification method!)
   - `on_taste` (risky but definitive)
   - `on_listen` (cooking sounds, spoilage fizzing?)

2. **FSM Engine:**
   - Perfect for food states: fresh → cooked → spoiled
   - Transitions: time-based, temperature-based, action-triggered
   - Mutation system (D-14): raw-chicken.lua → cooked-chicken.lua

3. **Material System:**
   - 30+ materials already defined
   - Food materials: cheese, bread, meat, milk (need properties!)
   - Properties: perishable, edible, nutritious, cookable

4. **Containment:**
   - Size/weight/capacity constraints
   - Food in containers (barrel, pot, sack)
   - Preservation via containment (sealed jar prevents spoilage?)

5. **Injury System:**
   - Food poisoning as injury type
   - Healing via food consumption
   - Poison integration (bad food = poison injury)

6. **Creature Drives:**
   - Rat already has hunger drive!
   - Feeding mechanics (player feeds creature)
   - Bait system (food attracts creatures)

7. **Two-Hand Inventory:**
   - Carrying food is strategic choice
   - Compound tools: knife + food → prepared food?

8. **Tool System:**
   - Fire source + raw food → cooked food
   - Knife + raw ingredients → prepared meal
   - Container + salt + meat → preserved meat

### What We Could Add

1. **Hunger Mechanic (Optional):**
   - Light-touch like MUDs (minor stat penalty, not death)
   - Or Valheim-style (food = buffs, not survival)
   - Or Don't Starve-style (critical survival resource)
   - **Recommendation:** Start with optional buffs; test before making critical

2. **Cooking Verbs:**
   - `COOK <food> WITH <tool>` (knife, fire, pot)
   - `PRESERVE <food> WITH <method>` (salt, smoke, dry)
   - `TASTE <food>` (already have sensory property!)
   - `FEED <creature> <food>` (creature interaction)

3. **Food Objects:**
   - Base templates: raw-food, cooked-food, preserved-food, spoiled-food
   - Instances: apple, bread, cheese, meat, fish, egg, milk
   - Properties: nutrition, spoilage_rate, edible, cookable, perishable

4. **Time-Based Spoilage:**
   - Integrate with game clock (2 AM start, 1 real hour = 1 game day)
   - Spoilage timer per food item
   - Environmental factors (room temperature, container type)

5. **Recipe System:**
   - Combine ingredients for better effects
   - Caves of Qud style: 2-3 ingredients → buff/effect
   - Dwarf Fortress style: Ingredient count determines value

6. **Food Puzzles:**
   - Bait trap with cheese (attract rat)
   - Feed guard dog to befriend
   - Poison food to eliminate threat
   - Cooking challenge to unlock area

### Design Philosophy Recommendations

**Based on Wayne's Dwarf Fortress Inspiration:**

1. **Food as Emotional System** (not just stat management)
   - Preferred foods boost morale
   - Variety matters (eating same food = diminishing returns)
   - Quality impacts experience (burnt food vs. lavish meal)

2. **Cooking Solves Spoilage** (preservation via transformation)
   - Raw meat rots → Cooked meat preserved
   - Milk spoils → Cheese lasts (fermentation)
   - Mutation system perfect for this: raw-meat.lua → cooked-meat.lua

3. **Strategic Resource Management**
   - Salt, containers, fire as limited resources
   - Preservation choices (eat now vs. preserve for later)
   - Storage logistics (barrel capacity, spoilage risk)

4. **Risk/Reward Identification** (NetHack influence)
   - Unknown food requires sensory testing
   - `SMELL` safe but limited info
   - `TASTE` definitive but risky (poison)
   - Observation via `LOOK` (visual spoilage indicators)

5. **Multi-Purpose Food** (layer functions)
   - Survival (hunger)
   - Buffs (stamina, health)
   - Puzzle (bait, bribes)
   - Economy (trade goods)
   - Crafting (ingredient for recipes)

6. **Light-Touch Implementation** (avoid tedious micromanagement)
   - MUD lesson: Don't make food intrusive
   - Optional engagement (buffs, not mandatory)
   - If hunger exists, make it forgiving (long timers)

---

## 12. Technical Architecture Considerations

### FSM States for Food Items

```
States:
- fresh: Initial state, full value, safe to eat
- ripe: (fruit only) Peak flavor, short window
- cooked: Preserved, enhanced nutrition, longer shelf life
- stale: (bread) Edible but reduced value, still safe
- spoiling: Early decay, visual/smell indicators, risky to eat
- spoiled: Unsafe, poison risk, should be discarded
- rotten: Completely decayed, toxic, produces miasma

Transitions:
- fresh → cooked (verb: cook, requires: fire_source)
- fresh → spoiling (time-based, affected by: temperature, container)
- spoiling → spoiled (time-based)
- spoiled → rotten (time-based)
- fresh → preserved (verb: preserve, requires: salt/smoke/dry tool)
```

### Material Properties for Food

```lua
return {
    guid = "{food-guid}",
    template = "consumable",
    material = "meat",  -- links to materials system
    
    -- Edible properties
    edible = true,
    nutrition = 50,  -- hunger satisfaction
    buffs = { stamina = 10, duration = 300 },  -- 5 minutes
    healing = 5,  -- HP restoration
    
    -- Spoilage properties
    perishable = true,
    spoilage_rate = 1.0,  -- base decay speed
    current_freshness = 100,  -- 0-100 scale
    spoilage_modifiers = {
        temperature = 1.0,  -- multiplier
        container = 0.5,  -- sealed container slows decay
        preserved = 0.1   -- if salted/smoked
    },
    
    -- Sensory detection
    on_smell = "Fresh and savory.",
    on_taste = "Rich and meaty.",
    on_feel = "Cool and slightly moist.",
    
    -- State-specific overrides
    states = {
        fresh = {
            on_smell = "Fresh and savory.",
            safe_to_eat = true
        },
        spoiling = {
            on_smell = "Slightly sour odor.",
            safe_to_eat = false,
            poison_risk = 0.3
        },
        spoiled = {
            on_smell = "Foul, rancid stench.",
            safe_to_eat = false,
            poison_risk = 0.9
        }
    }
}
```

### Cooking Verb Pattern

```lua
verbs.cook = function(context, noun)
    local food = context.registry:find_by_keyword(noun)
    if not food or not food.cookable then
        print("You can't cook that.")
        return
    end
    
    local fire_source = context.player:find_tool_by_capability("fire_source")
    if not fire_source then
        print("You need a fire source to cook.")
        return
    end
    
    -- Trigger mutation: raw-meat.lua → cooked-meat.lua
    mutation.apply(food, "cook", context)
    print("You cook the " .. food.name .. " over the flames.")
end
```

---

## 13. Research Gaps & Future Investigation

### Areas Requiring Deeper Dive
1. **Nutrition Science:** Calorie calculations, macro/micronutrients (if going CDDA route)
2. **Recipe Algorithms:** Procedural recipe generation, ingredient compatibility matrices
3. **Taste Profile Systems:** Sweet/salty/bitter/sour/umami balancing (if complex cooking)
4. **Economic Modeling:** Food as trade goods, pricing, inflation from spoilage
5. **Cultural Cuisine:** Regional food variations, NPC culture-specific preferences

### Competitive Analysis Gaps
- **Rimworld:** Similar to Dwarf Fortress; worth examining food mood system
- **Project Zomboid:** Detailed nutrition/freshness tracking
- **Stardew Valley:** Cooking as friendship mechanic
- **Monster Hunter:** Food buffs as mission prep strategy
- **Ultima Series:** Historical context for early food systems

### Technical Deep-Dives Needed
- **Spoilage Algorithms:** Linear vs. exponential decay curves
- **Performance:** Tracking freshness for 100+ food items in game world
- **Save/Load:** Persisting spoilage timers, mid-decay state
- **Text Generation:** Dynamic descriptions based on freshness state

---

## 14. Conclusions & Recommendations

### Top 5 Design Principles (from Research)

1. **Food as Multi-Dimensional System** (not just hunger bar)
   - Nutrition, buffs, crafting, puzzles, economy, NPC interaction
   - Layer mechanics; don't reduce to single purpose

2. **Leverage Existing Architecture** (sensory system, FSM, materials, mutations)
   - We already have 80% of infrastructure needed
   - FSM perfect for state transitions (fresh → cooked → spoiled)
   - Mutation system IS state changes (D-14 principle)
   - Sensory properties enable food identification gameplay

3. **Start Simple, Add Complexity** (MUD lesson)
   - Phase 1: Basic consumables with buffs (no spoilage)
   - Phase 2: Add cooking (raw → cooked via mutation)
   - Phase 3: Add spoilage (time-based state transitions)
   - Phase 4: Add preservation (salt, smoke, containers)
   - Phase 5: Recipe system (multi-ingredient combinations)

4. **Make Food Strategic, Not Tedious** (Valheim lesson)
   - Buffs > Survival pressure
   - Optional engagement (benefits for using, no punishment for ignoring)
   - If adding hunger: long timers, gentle warnings, forgiving penalties

5. **Integrate with World Systems** (Dwarf Fortress lesson)
   - Creature hunger drives (rat already has this!)
   - Room temperature affects spoilage
   - Container system for preservation
   - Material properties determine food behavior
   - Tool capabilities enable cooking/preservation

### Recommended Implementation Path

**Phase 1: Basic Consumables** (Minimal Viable Food)
- 3-5 food objects (bread, apple, cheese, jerky, water)
- `EAT` and `DRINK` verbs
- Simple buffs (restore 10 HP, boost stamina)
- Use existing sensory system (on_taste, on_smell)

**Phase 2: Cooking** (State Transformation)
- Add raw food objects (raw-meat, raw-fish)
- Implement `COOK` verb (requires fire_source tool)
- Mutation: raw-meat.lua → cooked-meat.lua
- Cooked food provides better buffs than raw

**Phase 3: Spoilage** (Time-Based FSM)
- Add freshness tracking to perishables
- Time-based state transitions (fresh → spoiling → spoiled)
- Sensory detection (smell spoiled food)
- Risk system (eating spoiled = poison injury)

**Phase 4: Preservation** (Extended Mechanics)
- Add preservation verbs (SALT, SMOKE, DRY)
- Container effects (barrel slows spoilage)
- Preserved food has extended shelf life

**Phase 5: Recipes** (Combination System)
- Multi-ingredient cooking (bread + cheese + meat = sandwich)
- Enhanced buffs for complex recipes
- Recipe discovery mechanic

### Success Metrics
- Does food enhance immersion without becoming tedious?
- Do players engage with cooking/preservation voluntarily?
- Does food create interesting strategic choices?
- Do sensory verbs (smell, taste) add gameplay depth?
- Does food integrate with existing systems (creatures, materials, FSM)?

---

## Sources & References

### Games Researched
- Dwarf Fortress (primary inspiration)
- Discworld MUD
- Achaea / Iron Realms MUDs
- LegendMUD
- NetHack
- Caves of Qud
- Cataclysm: Dark Days Ahead
- Dungeon Crawl Stone Soup
- Zork I (Infocom)
- Don't Starve
- Valheim
- Minecraft (vanilla + mods)
- Magic: The Gathering (Throne of Eldraine)
- Agricola
- Viticulture
- A Feast for Odin

### Key Resources
- Dwarf Fortress Wiki (kitchen, storage, food guide)
- NetHack Wiki (comestibles, corpses, nutrition)
- MUD help files and documentation
- Board game strategy guides
- Food science literature (preservation, spoilage, microbiology)
- Ecology resources (food chains, predator-prey dynamics)

### Software Engineering Patterns
- Finite State Machine (FSM) for food states
- State pattern for consumable systems
- Observer/Event pattern for consumption effects
- Component-based design for food properties
- Material system integration

---

**Research Complete: March 26, 2026**  
**Next Steps:** Create comparison matrix, extract design patterns, draft integration notes
