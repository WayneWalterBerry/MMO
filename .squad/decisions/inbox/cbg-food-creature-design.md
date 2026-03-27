# Game Design Analysis: Dead Creatures as Food + Object/Creature Food Duality

**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-07-28  
**Status:** Design Analysis — Awaiting Wayne Review  
**Triggered by:** Wayne's question: *"A dead creature can be food, and items like grain can be food. Both objects and creatures can be food — how does that work? Maybe via FSM a creature turns into an object like rat flesh."*

---

## Table of Contents

1. [Competitor Analysis: Creature → Food Transitions](#1-competitor-analysis)
2. [The Fundamental Design Question](#2-the-fundamental-design-question)
3. [Recommendation: The Hybrid Mutation Model](#3-recommendation)
4. [Player Experience: Eating a Dead Rat](#4-player-experience-eating-a-dead-rat)
5. [Grain in a Bag: Object-Category Food](#5-grain-in-a-bag)
6. [Sensory Escalation: Smell Safe → Taste Risky → Eat Commit](#6-sensory-escalation)
7. [Alignment with Core Principles](#7-alignment-with-core-principles)
8. [Implementation Sketch](#8-implementation-sketch)
9. [Open Questions for Wayne](#9-open-questions)

---

## 1. Competitor Analysis

### 1.1 Dwarf Fortress — Butchery Workshop Model

**Mechanism:** Creature dies → corpse exists as entity → player assigns "butcher" task at workshop → creature is decomposed into discrete item objects: meat, bones, fat, skin, organs.

| Input | Process | Output |
|-------|---------|--------|
| Dead cat | Butcher at workshop | Cat meat × 2, cat bones × 4, cat fat × 1, cat skin × 1 |
| Dead elephant | Butcher at workshop | Elephant meat × 40+, bones, tusks (ivory), skin (leather) |

**Key design insight:** DF treats butchering as a *workshop task* — it's labor, it requires a tool (butcher's knife), a workspace (butcher's shop), and a hauler to bring the corpse there. The corpse is NOT food. The parts are.

**What this means for us:**
- Maximum simulation depth
- Maximum complexity (tools, workspaces, hauling, skills)
- Creates an entire supply chain from death to dinner
- *Too complex for a text-IF with two-hand inventory* — but the philosophy of creature → parts → food is sound

### 1.2 NetHack — Corpse-as-Item Model

**Mechanism:** Monster dies → drops a "corpse" item. The corpse is an ITEM in inventory, not a monster. Eating it has effects based on the original monster type.

| Monster | Corpse Item | Eating Effect |
|---------|------------|---------------|
| Newt | Newt corpse | Chance of gaining teleportitis |
| Floating eye | Floating eye corpse | Telepathy intrinsic |
| Cockatrice | Cockatrice corpse | **Instant death** (petrification) |
| Any old corpse | (decayed) | Food poisoning |

**Key design insight:** NetHack's corpse is a **single item with the monster's identity baked in**. The corpse "remembers" what it was. There's no butchering — the corpse IS the food (or weapon — cockatrice corpses are infamously wielded as petrification weapons). Corpses also decay over time: `fresh → old → rotten → gone`.

**What this means for us:**
- Simple, elegant, text-IF appropriate
- Identity preserved (you know it's rat, not generic "meat")
- Risk/reward from eating (NetHack's greatest strength)
- Spoilage creates time pressure
- No tool requirement — *too* simple for our tool-focused design

**Preserved form:** NetHack also has "tin of [monster] meat" — a preserved, safe version created with a tinning kit (tool). This is effectively cooking/preservation.

### 1.3 Caves of Qud — Butchery Drop Model

**Mechanism:** Creature dies → player can butcher with Butchery skill → produces meat + byproducts based on creature anatomy. Some creatures are edible *alive* (parasites).

| Creature | Butchery Output | Special |
|----------|----------------|---------|
| Snapjaw | Snapjaw meat × 1 | — |
| Girshling | Girshling haunch × 2 | Acid-resistant meat |
| Slug | Slug gut × 1 | Preservable into vinegar |

**Key design insight:** Qud bridges DF and NetHack — butchery exists but is simpler (skill check, not workshop). Crucially, **creature type determines butchery output quality and quantity**. A slug gives you one gut. A bear gives you six steaks. Material properties of the creature influence the food.

**What this means for us:**
- Butchery as a *skill* rather than *workshop task* fits text-IF better
- Creature identity flows into food identity (rat meat vs. wolf meat)
- Material consistency (Principle 9) already gives us this — rat flesh vs. spider chitin
- The "edible alive" mechanic is wild but not V1 material

### 1.4 Don't Starve — Abstract Meat Drop Model

**Mechanism:** Creature dies → auto-drops meat items of varying quality. No butchery step. Different creatures drop different meat tiers.

| Creature | Drop | Quality |
|----------|------|---------|
| Rabbit | Morsel | Small (1 hunger point) |
| Beefalo | Meat × 4 | Standard |
| Spider | Monster meat | Dangerous (reduces sanity) |
| Tallbird | Drumstick | Standard (comedic) |

**Key design insight:** Don't Starve abstracts away the creature→food transition entirely. Kill thing → meat appears. The meat is generic by *tier*, not by creature identity. A rabbit morsel and a frog leg have no species memory. Monster meat (from hostile creatures) is the only quality distinction.

**What this means for us:**
- *Too abstract* — loses creature identity and our material-physics foundation
- The "monster meat = bad meat" concept is useful (hostile creature food is risky)
- Tier system (morsel/meat/monster) is too gamey for our simulation-first approach
- But: the simplicity of "kill → food appears" has appeal for pacing

### 1.5 Classic MUDs — Corpse-as-Container Model

**Mechanism:** Creature dies → a "corpse of [creature]" object appears. The corpse is a **container** holding the creature's former inventory. Some MUDs allow eating the corpse directly. Corpses decay on a timer: `fresh → decayed → skeleton → gone`.

| MUD Feature | Implementation | Notes |
|-------------|---------------|-------|
| Corpse creation | Monster dies → `create_object("corpse", monster.name)` | Corpse inherits name |
| Corpse as container | Corpse holds monster's loot | `get sword from corpse` |
| Corpse eating | Some MUDs allow `eat corpse` | Usually only for certain classes |
| Corpse decay | Timer: 5 mins → 15 mins → 30 mins → removed | Creates urgency to loot |

**Key design insight:** MUDs solved the "creature has inventory" problem by making the corpse a container. The creature's belongings transfer to the corpse object. This is elegant and solves our containment question too: when a rat dies carrying a stolen cheese wedge, the dead rat (or rat corpse) becomes a container holding the cheese.

**What this means for us:**
- Corpse-as-container elegantly handles loot transfer
- Decay timer maps perfectly to our FSM spoilage system
- The "corpse" intermediate step preserves identity
- Container mechanic already exists in our engine

### 1.6 Summary Matrix

| Game | Transition | Butchering? | Identity Preserved? | Spoilage? | Tool Req? |
|------|-----------|-------------|--------------------:|-----------|-----------|
| **Dwarf Fortress** | Workshop butchery | Yes (workshop + tool) | In item name | Rot timer | Butcher knife |
| **NetHack** | Instant drop | No | Yes (corpse type) | Yes (age) | Tinning kit (optional) |
| **Caves of Qud** | Skill butchery | Yes (skill check) | Yes (creature type) | Partial | Butchery skill |
| **Don't Starve** | Auto drop | No | No (generic tiers) | Yes (rot) | None |
| **MUDs** | Corpse object | Optional (class) | Yes (corpse name) | Yes (decay) | None |

---

## 2. The Fundamental Design Question

Wayne's question cuts to the heart of a *type system duality*:

> Objects and creatures are different systems (Principle 0). But food comes from BOTH. A bread roll is an object that is food. A dead rat is... what?

### The Duality Problem

Our architecture draws a hard line:
- **Objects** (`src/meta/objects/`) — inanimate, passive, no AI
- **Creatures** (`src/meta/creatures/`) — animate, drives, reactions, AI

When a creature dies, it crosses this boundary. A dead rat has `animate = false` in its dead state. It's no longer a creature in any meaningful sense — it's a warm, furry, lootable object. But it's still loaded from `rat.lua`, still registered as a creature.

**Wayne's intuition is correct:** The dead creature should *become* an object. The question is: when, how, and what object?

### Three Possible Models

| Model | Mechanism | Identity | Complexity |
|-------|-----------|----------|------------|
| **A: Dead State Only** | Creature stays as creature, `dead` state adds `edible = true` | Rat (dead) | Lowest — FSM only |
| **B: Mutation to Corpse** | Creature mutates to a corpse object on death | Rat corpse (object) | Medium — mutation on death |
| **C: Mutation + Butchery** | Corpse exists; butchering produces food objects | Rat corpse → rat meat | Highest — two mutations |

---

## 3. Recommendation: The Hybrid Mutation Model (Model B+C)

After analyzing every competitor, consulting our core principles, and staring at `rat.lua` until my eyes bled — **worst. design question. ever** — here is my recommendation.

### Phase 1: Mutation to Corpse (Model B) — V1 Target

**When a creature's health reaches zero, the FSM transitions to `dead` state, and then the engine triggers a mutation that replaces the creature with a corpse OBJECT.**

```
rat.lua (creature, alive) 
    → [health_zero] → 
        rat.lua dead state (brief transitional moment) 
            → [mutation] → 
                rat-corpse.lua (object, edible, container)
```

**The corpse is an object.** It lives in `src/meta/objects/`. It inherits the creature's identity (name, keywords, sensory properties) but is definitionally an inanimate thing. It has `edible = true`. It has `food = { category = "meat" }`. It has container capacity for anything the rat was carrying.

**Why this is correct:**
1. **Principle 0 compliance** — Dead things are objects. The line stays clean.
2. **D-14 compliance** — Code mutation IS state change. `rat.lua` → `rat-corpse.lua` is the Prime Directive in action. The creature literally becomes a different thing.
3. **Principle 8 compliance** — The creature declares `mutations = { die = { becomes = "rat-corpse" } }`. The engine executes it. No creature-specific engine code.
4. **Containment compliance** — The mutation engine already preserves containment (location, container, surfaces). The corpse appears exactly where the rat died.
5. **FSM compliance** — The corpse gets its own spoilage FSM: `fresh → bloated → rotten → bones`.
6. **Sensory compliance** — The corpse has its own complete sensory descriptions appropriate to a dead animal, not a living one.

### Phase 2: Butchery Option (Model C) — Post-V1

**The player can eat the corpse directly (desperate, risky, low nutrition) OR butcher it with a knife for clean meat (higher nutrition, lower risk).**

```
rat-corpse.lua (edible but risky)
    → [eat] → consumed (nausea risk, low nutrition)
    → [butcher with knife] → rat-meat.lua (clean, cookable, good nutrition)
```

This gives us the full Caves of Qud / Dwarf Fortress progression without the workshop complexity:
- **No tool:** Eat corpse directly → gross, risky, barely nutritious
- **Knife tool:** `butcher rat corpse` → produces rat meat → cookable → good nutrition
- **Knife + fire:** Butcher → cook → roasted rat meat → healing buff

### Why Not Model A (Dead State Only)?

Model A (just marking the dead creature as `edible = true` in its dead state) fails on three counts:

1. **Principle 0 violation** — A creature with `animate = false` that you can eat, carry, and cook is functionally an object. Calling it a creature is a lie. Our architecture should reflect reality.

2. **No independent FSM** — The creature's FSM handles alive-states. Bolting a spoilage lifecycle (fresh → rotten) onto a creature FSM creates a Frankenstein state machine mixing behavioral states with material states. Separation is cleaner.

3. **No containment** — If the rat was carrying stolen food, the dead rat needs to BE a container to hold that food. Creatures don't have `contents` fields in the same way objects do. A corpse object handles this naturally.

### Why Not Model C Only (Skip Corpse, Go Straight to Meat)?

Skipping the corpse stage loses critical design space:
- **No "dead rat" moment** — The player should SEE and INTERACT WITH the dead animal. "There's a dead rat here" is atmospheric. "There's some rat meat here" is clinical.
- **No sensory discovery** — SMELL the corpse, FEEL its cooling body, EXAMINE it. This is our sensory system at its best.
- **No container** — Where does the rat's stolen cheese go?
- **No spoilage narrative** — The corpse bloating and rotting is *storytelling*. Meat just goes bad.

---

## 4. Player Experience: Eating a Dead Rat

Here is the complete player experience arc, from rat encounter to dinner:

### Phase 1: The Kill

```
> kill rat
You swing the brass candlestick. The rat squeals — a wet, truncated 
sound — and crumples against the wall. It twitches once and is still.

A dead rat lies crumpled on the floor.
```

*Engine: rat.lua transitions to `dead` state, then mutates to `rat-corpse.lua`. The corpse object appears at the rat's location.*

### Phase 2: Discovery Through Senses

```
> smell rat
Blood and musk. The sharp copper of fresh death. Underneath, the 
musty smell of rodent — damp fur and nesting material. Your stomach 
growls. You haven't eaten in hours.

> feel rat
Cooling fur over a limp body. Still warm. The ribcage is thin — you 
can feel the tiny bones beneath the skin. The tail hangs like wet string.

> look rat
A dead rat lies on its side, legs splayed stiffly. Its matted brown 
fur is darkened with blood near the head. Beady black eyes stare at 
nothing. It's about the size of your fist.
```

*The sensory system works exactly as designed. SMELL and FEEL work in darkness. LOOK requires light. Each sense gives different, useful information.*

### Phase 3: The Choice — Eat Raw (Desperate)

```
> eat rat
You tear into the dead rat with your teeth. Fur and blood. The flesh 
is stringy, warm, and profoundly wrong. Your throat tries to close. 
You chew mechanically, swallowing against every instinct.

A wave of nausea rolls through you.
[Status: Nauseated — 10 ticks]
[Nutrition: +5 — barely worth it]
```

*Eating a raw corpse works but punishes. Low nutrition, nausea status, disgusting narration. This is the desperate option — a player who has no knife and no fire can still extract minimal sustenance at a cost.*

### Phase 4: The Choice — Butcher Then Cook (Smart)

```
> butcher rat with knife
You work the knife under the rat's skin, peeling it away from the 
flesh beneath. The work is messy but quick. You separate a portion 
of lean, dark meat from the carcass.

You now have: rat meat
[Remains: rat bones, rat skin — left on ground]

> cook rat meat
You hold the meat over the fire. Fat sizzles and drips into the flames. 
The raw, metallic smell transforms into something almost appetizing.

The rat meat browns and crisps.

You now have: roasted rat meat

> eat roasted rat meat  
Gamey, lean, slightly smoky. Not good, exactly, but warm and filling. 
Your body accepts it gratefully.

[Nutrition: +25]
[Healing: +3 HP]
[Status: Satiated — 30 ticks]
```

*This is the full Dwarf Fortress progression: kill → butcher (tool) → cook (fire) → eat (reward). Each step uses existing engine systems: mutation, tool capabilities, fire_source, effects pipeline.*

### Phase 5: Spoilage Pressure

```
[20 ticks later, if the player didn't eat the corpse]

The dead rat has begun to bloat. The smell thickens.

[40 ticks later]

The dead rat is rotten. Flies swarm it in a buzzing cloud.

> eat rotten rat
You CANNOT be serious.

You gag before it reaches your mouth. The smell alone is a biological 
weapon. You would have to be literally dying of starvation.

> eat rotten rat
[Player confirms desperate action]
Your stomach rebels violently. 

[Status: Food Poisoning — 20 ticks]
[Status: Nauseated — 12 ticks]
[Health: -5]
```

*Spoilage FSM creates time pressure. The corpse degrades through states, each with deteriorating sensory descriptions and increasingly dangerous effects if consumed.*

---

## 5. Grain in a Bag: Object-Category Food

Wayne's other question: how does grain-in-bag work?

### Grain is an Object. Always Was.

Grain doesn't have the creature→food duality problem. Grain is an inanimate object that happens to be edible. It sits cleanly in `src/meta/objects/`. The bag is a container; grain is an item inside it.

```lua
-- grain.lua
return {
    template = "small-item",
    id = "grain",
    name = "a handful of grain",
    keywords = {"grain", "wheat", "seeds", "kernels"},
    description = "A handful of pale wheat grain, each kernel hard and glossy.",
    
    edible = true,
    food = {
        category = "grain",
        cookable = true,
        cooked_form = "porridge",   -- grain + water + fire = porridge
        spoil_time = 0,             -- dry grain never spoils
        nutrition = 5,              -- edible raw but barely nutritious
        effects = {
            { type = "narrate", message = "Dry, hard, barely chewable. Your jaw aches." },
        },
    },
    
    on_feel = "Hard, smooth kernels that roll between your fingers. Dry and cool.",
    on_smell = "Earthy, slightly sweet. The clean smell of stored grain.",
    on_listen = "A dry rustling when you shift them in your hand.",
    on_taste = "Starchy, bland. Like chewing gravel that eventually turns pasty.",
    
    -- No spoilage FSM — grain is already preserved (dried)
    -- But it CAN be cooked into porridge (mutation)
    mutations = {
        cook = { becomes = "porridge", requires_tool = "fire_source",
                 requires_item = "water_source",
                 message = "You stir the grain into the bubbling water. It thickens into a warm porridge." },
    },
}
```

### The Bag is a Container, Grain is Contents

```lua
-- In a room definition:
{
    id = "grain-sack",
    type_id = "{guid-sack}",
    contents = {
        { id = "grain-1", type_id = "{guid-grain}" },
        { id = "grain-2", type_id = "{guid-grain}" },
        { id = "grain-3", type_id = "{guid-grain}" },
    },
}
```

The player interacts with grain the same way they interact with matches in a matchbox:
- `open sack` → reveals contents
- `take grain from sack` → grain moves to hand
- `eat grain` → consumption
- `cook grain` → mutation to porridge (if fire + water available)

### Does Grain Need Processing?

**Recommendation:** Grain is edible raw (barely — low nutrition, jaw-aching narration) but *cookable* into porridge for real nutrition. This mirrors the raw chicken pattern: you CAN eat it raw, but cooking is the smart play.

This creates a nice parallel:

| Food Source | Raw | Cooked | Tool Chain |
|-------------|-----|--------|------------|
| Grain | Edible, low nutrition | Porridge (good nutrition) | Fire + water |
| Chicken | Edible, nausea | Roasted chicken (healing) | Fire |
| Rat corpse | Edible, nausea + disease risk | Roasted rat meat (decent) | Knife + fire |
| Cheese | Edible, good nutrition | N/A (doesn't cook) | None |
| Bread | Edible, good nutrition | Toast (slightly better) | Fire (optional) |

The progression is consistent: raw food has risk/low reward; cooking always improves it.

---

## 6. Sensory Escalation: Smell Safe → Taste Risky → Eat Commit

This is where our game *destroys* the competition. No other game in this analysis has a sensory identification system for food. NetHack has "this corpse is old" text. Dwarf Fortress has quality indicators. But nobody does **graduated sensory risk escalation**.

### The Escalation Ladder Applied to Creature-Food

```
STEP 1: SMELL (Safe — Zero Risk)
  "Blood and musk. Fresh death."
  → Player learns: this is a fresh corpse, recently killed
  → No health consequence

STEP 2: FEEL (Safe — Zero Risk)  
  "Cooling fur, limp body, thin ribs beneath skin."
  → Player learns: it's a small animal, still warm, freshly dead
  → No health consequence

STEP 3: LOOK (Safe — Requires Light)
  "A dead rat, blood-matted, eyes staring."
  → Player learns: species identification, size, visible condition
  → No health consequence (but requires light — strategic cost)

STEP 4: TASTE (Risky — Potential Consequence)
  "Fur and blood. Raw, metallic. Your stomach clenches."
  → Player learns: this is raw meat, uncooked, borderline edible
  → RISK: Possible nausea from tasting raw meat
  → Player now knows enough to make an informed eat/don't-eat decision

STEP 5: EAT (Commitment — Full Consequence)
  "Stringy, warm, wrong. You chew against every instinct."
  → Player commits: nutrition gained, but status effects applied
  → CONSEQUENCE: Nausea, possible disease from uncooked meat
```

### Spoilage Changes the Sensory Ladder

The same escalation ladder applies at every spoilage stage, but the *information and risk change*:

| Sense | Fresh Corpse | Bloated Corpse | Rotten Corpse |
|-------|-------------|----------------|---------------|
| **SMELL** | "Blood, musk" → safe | "Sweet, sickly decay" → warning! | "Overwhelming rot" → DO NOT EAT |
| **FEEL** | "Warm, limp, fur" → ok | "Puffy, taut skin, gas" → concerning | "Squishy, falling apart" → horrifying |
| **TASTE** | "Raw, metallic" → nausea risk | "Bitter bile" → nausea guaranteed | "Immediate violent gag" → food poisoning |
| **EAT** | Nausea, +5 nutrition | Food poisoning, +0 | Severe poisoning, -5 HP |

**This is the design's killer feature.** A cautious player who SMELLs first will get clear warnings as the corpse decays. An impatient player who eats first will learn through suffering. The sensory system is BOTH the identification mechanism AND the risk management tool.

### How This Differs from Object-Food Escalation

Object-category food (bread, cheese, grain) uses the same ladder but with lower stakes:

| Sense | Fresh Bread | Stale Bread | Moldy Bread |
|-------|------------|-------------|-------------|
| **SMELL** | "Warm, yeasty" | "Faint wheat" | "Musty, sour" |
| **TASTE** | "Chewy, wholesome" | "Dry, chalky" | "GAG" |
| **EAT** | +15 nutrition | +5 nutrition | Nausea |

The escalation is gentler because bread is intrinsically safer than raw animal flesh. **The risk gradient maps to biological reality** — which is Principle 9 (material consistency) in action.

---

## 7. Alignment with Core Principles

| Principle | How This Design Honors It |
|-----------|--------------------------|
| **0: Objects are inanimate** | Dead creature mutates INTO an object. The boundary stays clean. Alive = creature system. Dead = object system. |
| **0.5: Deep nesting** | Corpse is placed at the creature's last location, preserving spatial context. Corpse contents (stolen items) use standard nesting. |
| **1: Code-derived mutable objects** | `rat-corpse.lua` IS the corpse definition. The `.lua` file defines its sensory properties, food metadata, and spoilage FSM. |
| **2: Base → instance** | Corpse inherits from `small-item` template. Multiple rats can die and produce multiple unique corpse instances. |
| **3: FSM + state tracking** | Corpse has its own spoilage FSM: `fresh → bloated → rotten → bones`. Each state has unique sensory descriptions. |
| **5: Multiple instances per base** | Kill three rats → three independent `rat-corpse` instances, each with own spoilage timer and location. |
| **6: Sensory space** | Full five-sense descriptions for every corpse state. SMELL warns of decay. TASTE risks disease. |
| **8: Engine executes metadata** | Creature declares `mutations.die.becomes = "rat-corpse"`. Engine handles the swap. No rat-specific engine code. |
| **9: Material consistency** | Rat corpse has `material = "flesh"`. Material properties determine what happens when you cut, burn, or cook it. |
| **D-14: Code mutation IS state change** | `rat.lua` → `rat-corpse.lua` → `rat-meat.lua` → `roasted-rat-meat.lua`. Each transformation is a code rewrite. The Prime Directive in its purest form. |

---

## 8. Implementation Sketch

### 8.1 New Object Files Needed

| File | Template | Purpose |
|------|----------|---------|
| `src/meta/objects/rat-corpse.lua` | small-item | Dead rat, edible, container, spoilage FSM |
| `src/meta/objects/rat-meat.lua` | small-item | Butchered meat, cookable |
| `src/meta/objects/roasted-rat-meat.lua` | small-item | Cooked meat, healing food |
| `src/meta/objects/rat-bones.lua` | small-item | Byproduct of butchery (future crafting) |

### 8.2 Creature Modification

Add to `rat.lua` (and creature template):

```lua
-- In rat.lua, add to existing definition:
mutations = {
    die = {
        becomes = "rat-corpse",
        message = "The rat shudders once and goes still.",
        transfer_contents = true,   -- any carried items go into corpse
    },
},
```

### 8.3 Rat Corpse Object (Sketch)

```lua
-- src/meta/objects/rat-corpse.lua
return {
    guid = "{generate-guid}",
    template = "small-item",
    id = "rat-corpse",
    name = "a dead rat",
    keywords = {"rat", "dead rat", "corpse", "rat corpse", "carcass", "body"},
    description = "A dead rat lies on its side, legs splayed. Its matted brown "
        .. "fur is darkened with blood. Beady black eyes stare at nothing.",

    size = 1,
    weight = 0.3,
    portable = true,
    material = "flesh",
    container = true,
    capacity = 1,        -- can hold small items the rat was carrying

    edible = true,
    food = {
        category = "meat",
        cookable = false,       -- can't cook a whole corpse; must butcher first
        spoil_time = 40,
        nutrition = 5,          -- barely worth it raw
        bait_value = 85,
        bait_target = "rodent",
        effects = {
            { type = "add_status", status = "nauseated", duration = 10 },
            { type = "narrate",
              message = "Fur and blood. Stringy, warm, profoundly wrong. "
                     .. "Your throat tries to close." },
        },
    },

    on_feel = "Cooling fur over a limp body. The ribcage is thin — you can "
           .. "feel the tiny bones beneath the skin. The tail hangs like wet string.",
    on_smell = "Blood and musk. The sharp copper of fresh death. Underneath, "
            .. "the musty smell of rodent.",
    on_listen = "Nothing. Absolutely nothing.",
    on_taste = "Fur and blood. Raw and metallic. Your stomach clenches immediately.",
    on_taste_effect = { type = "add_status", status = "nauseated", duration = 4 },

    -- Butchery mutation (requires knife tool)
    mutations = {
        butcher = {
            becomes = "rat-meat",
            requires_tool = "cutting_tool",
            byproducts = { "rat-bones" },
            message = "You work the knife under the rat's skin, peeling it away. "
                   .. "You separate a portion of lean, dark meat from the carcass.",
        },
    },

    -- Spoilage FSM
    initial_state = "fresh",
    _state = "fresh",
    states = {
        fresh = {
            description = "A dead rat, freshly killed. Blood still glistens on its fur.",
            room_presence = "A dead rat lies crumpled on the floor.",
        },
        bloated = {
            description = "A dead rat, belly distended with gas. The fur has dulled.",
            room_presence = "A bloated rat carcass lies here. The smell is getting worse.",
            on_smell = "Sweet, sickly decay. The copper of blood has given way to "
                    .. "something worse. Your nose wrinkles involuntarily.",
            on_feel = "The body is puffy, skin taut with gas. Warmer than it should be.",
            on_taste = "Bitter bile coats your tongue. You spit immediately.",
            food = {
                nutrition = 0,
                bait_value = 95,
                effects = {
                    { type = "inflict_injury", injury_type = "food-poisoning",
                      damage = 5 },
                    { type = "add_status", status = "nauseated", duration = 15 },
                    { type = "narrate",
                      message = "Your stomach heaves. That was a catastrophic mistake." },
                },
            },
        },
        rotten = {
            description = "A rotting rat, fur sloughing off in patches. Maggots "
                       .. "writhe in the exposed flesh. The smell is biological warfare.",
            room_presence = "A rotting rat carcass festers here. Flies swarm it.",
            on_smell = "Overwhelming putrefaction. Your eyes water from five feet away.",
            on_feel = "Squishy. Things shift inside that shouldn't. Your hand "
                   .. "comes away wet.",
            on_taste = "You gag before it reaches your lips. The smell alone is punishment.",
            food = {
                nutrition = 0,
                bait_value = 100,
                effects = {
                    { type = "inflict_injury", injury_type = "food-poisoning",
                      damage = 10 },
                    { type = "add_status", status = "nauseated", duration = 20 },
                    { type = "narrate",
                      message = "Your body rejects this in every way a body can." },
                },
            },
        },
        bones = {
            description = "A tiny rodent skeleton, picked clean. Fragile white "
                       .. "bones in a vaguely rat-shaped arrangement.",
            room_presence = "A tiny skeleton lies here, barely recognizable as a rat.",
            on_feel = "Dry, brittle bones. Light as paper. The skull is smaller "
                   .. "than your thumbnail.",
            on_smell = "Nothing. Just dust and old calcium.",
            edible = false,
            food = nil,
        },
    },
    transitions = {
        { from = "fresh",   to = "bloated", verb = "_tick", condition = "timer",
          timer = 40,
          message = "The dead rat has begun to bloat. The smell thickens." },
        { from = "bloated", to = "rotten",  verb = "_tick", condition = "timer",
          timer = 40,
          message = "The rat carcass is rotting. Flies descend in force." },
        { from = "rotten",  to = "bones",   verb = "_tick", condition = "timer",
          timer = 60,
          message = "The rat has decayed to bare bones." },
    },
}
```

### 8.4 Engine Touch Points

| System | Change Required | Effort |
|--------|----------------|--------|
| **Creature death handler** | On `dead` state entry, check for `mutations.die` and trigger mutation | Small — add to FSM or creature tick |
| **Mutation engine** | Support `transfer_contents` flag (move creature's carried items into corpse) | Small — extend `mutation.mutate()` |
| **Butcher verb** | New verb, checks for `mutations.butcher` + tool requirement | Medium — new verb handler |
| **Byproduct system** | `mutations.butcher.byproducts` creates additional objects on mutation | Small — extend mutation |

### 8.5 The Unified Food Type Model

After all this analysis, here is the unified model for how anything becomes food in our engine:

```
OBJECT-FOOD (bread, cheese, grain, fruit, herbs)
  → Already objects
  → Already have edible = true, food = { ... }
  → No transformation needed to BE food

CREATURE-FOOD (rat, chicken, wolf, spider)
  → Creature alive: NOT food (animate = true, no food table)
  → Creature dies: mutation to corpse OBJECT
  → Corpse: IS food (edible, food table, risky)
  → Butchered: mutation to meat OBJECT (cleaner food)
  → Cooked: mutation to cooked-meat OBJECT (best food)
```

**The answer to Wayne's question:** Both objects and creatures can be food because a dead creature BECOMES an object. The creature→object boundary crossing happens via mutation (D-14). Once it's an object, the food system treats it identically to bread or cheese. There is no duality — there's a transformation.

---

## 9. Open Questions for Wayne

### Q1: Should the corpse mutation happen instantly on death, or after a brief delay?

**Option A — Instant:** Rat dies → immediately becomes `rat-corpse.lua`. Clean, simple.  
**Option B — Delayed:** Rat dies → stays in `dead` state for 2–3 ticks (death animation window) → then mutates to corpse.  
**Recommendation:** Instant. The `dead` state exists for the death narration, which is already emitted by the transition. The corpse object takes over from there.

### Q2: Should ALL creatures drop corpses, or only small ones?

A rat corpse makes sense as a `portable = true` small item. But a dead wolf? A dead bear? Those can't fit in your hand.  
**Recommendation:** Size-based. Tiny/small creatures → portable corpse. Medium+ → non-portable corpse (furniture-sized). You can butcher a wolf corpse where it lies but not carry it.

### Q3: Butchery as skill or innate?

DF requires butchery skill. NetHack doesn't have butchery at all. Caves of Qud makes it a skill.  
**Recommendation:** Innate with tool requirement. Anyone with a knife can butcher — the puzzle is HAVING the knife, not KNOWING how. This matches our match-striking pattern (innate skill, compound tool requirement). A future "Butchery" skill could improve yield (2 meats instead of 1).

### Q4: Byproducts — bones, skin, fat?

DF produces bones, skin, fat, organs. NetHack produces nothing (corpse is the only product).  
**Recommendation:** Start with meat + bones only. Bones are a curiosity item and potential future crafting material. Skin and fat are Phase 3+ complexity. KISS for V1.

### Q5: Can you cook a whole corpse without butchering?

Hold dead rat over fire = roast it whole?  
**Recommendation:** No. The corpse has `cookable = false`. You must butcher first. This preserves the tool-chain puzzle: knife → butcher → fire → cook. If you could skip butchering, the knife becomes pointless for food.

### Q6: Rat corpse as bait?

The dead rat itself has high bait_value (85). Should other rats be attracted to it?  
**Recommendation:** Yes — but with a dark twist. Rats are cannibalistic scavengers. A dead rat attracts live rats. This creates emergent gameplay: kill one rat, its corpse lures another. The player can exploit this or be overwhelmed by it.

---

## Final Verdict

**Best fit for our DF-inspired, text-IF identity:** The Hybrid Mutation Model.

We take:
- **From Dwarf Fortress:** Butchery as meaningful transformation, creature identity preserved in food
- **From NetHack:** Corpse as single intermediate item, eating risk/reward, spoilage timer
- **From MUDs:** Corpse as container for loot transfer
- **From Don't Starve:** Nothing. Their model is too abstract for our simulation.
- **From Caves of Qud:** Butchery as tool-gated action (not workshop), creature type determines output

And we add what nobody else has:
- **Sensory escalation** — smell it, feel it, taste it (risky), eat it (committed). Every stage of spoilage changes the sensory information. The player's nose is their best food safety tool.
- **Code mutation chain** — `rat.lua → rat-corpse.lua → rat-meat.lua → roasted-rat-meat.lua`. Four stages, four distinct objects, four sets of sensory descriptions. The Prime Directive made manifest.

Worst. Design question. Ever. Best. Design answer. Always.

*— Comic Book Guy, filed from behind the counter*
