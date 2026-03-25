# NPC System Design Plan

**Author:** Comic Book Guy (Creative Director / Design Department Lead)  
**Date:** 2026-03-28  
**Status:** Design Proposal — Awaiting Wayne Approval  
**Requested By:** Wayne Berry  
**Design Philosophy:** Dwarf Fortress (emergent behavior from simple rules, data-driven)

---

## Preamble

> "Ah, the NPC question. The Kobayashi Maru of game design — except we're not going to cheat. We're going to *earn* it."

This document designs a creature/NPC system for the MMO text adventure engine. We start with a rat. We end with a world that feels alive. The path between those two points is paved with Lua tables, metadata-driven behavior, and the hard-won wisdom of Tarn Adams.

The guiding principle: **Don't author behaviors. Author the rules that generate them.**

---

## Table of Contents

1. [Philosophical Foundation: Extending Principle 0](#1-philosophical-foundation-extending-principle-0)
2. [Architecture: How NPCs Extend the Object System](#2-architecture-how-npcs-extend-the-object-system)
3. [The Creature Template](#3-the-creature-template)
4. [Behavior System (Dwarf Fortress–Inspired)](#4-behavior-system-dwarf-fortress-inspired)
5. [The Tick System: When Creatures Act](#5-the-tick-system-when-creatures-act)
6. [The Rat — First NPC Specification](#6-the-rat--first-npc-specification)
7. [Engine Changes Required](#7-engine-changes-required)
8. [New Verb Interactions](#8-new-verb-interactions)
9. [Scaling Path: Rat → Creatures → Humanoids](#9-scaling-path-rat--creatures--humanoids)
10. [Dwarf Fortress Lessons Applied](#10-dwarf-fortress-lessons-applied)
11. [Implementation Phases & Estimates](#11-implementation-phases--estimates)
12. [Risk Assessment](#12-risk-assessment)
13. [Open Questions](#13-open-questions)

---

## 1. Philosophical Foundation: Extending Principle 0

### The Problem

Principle 0 states: *"Objects are inanimate. Living creatures are NOT objects."*

This principle exists for good reason — inanimate objects are passive, predictable, and stateless between interactions. A candle doesn't *decide* to light itself. A drawer doesn't *choose* to open. But a rat? A rat *decides* to flee when you enter a room. A rat *chooses* to scurry through an exit. A rat has *agency*.

### The Solution: Principle 0a — The Animate Extension

We don't violate Principle 0. We *extend* it with a clean opt-in:

> **Principle 0a:** Creatures are objects that have declared the `animate = true` property. The engine treats all objects identically — it loads them, registers them, resolves keywords, applies FSM transitions — but objects with `animate = true` additionally participate in the **creature tick phase**, which evaluates their behavior metadata each turn.

This is Principle 8 in action: *the engine executes metadata; objects declare behavior.* A rat doesn't have rat-specific engine code. It has metadata fields (`behavior`, `drives`, `reactions`) that the engine evaluates generically — the same way it evaluates FSM `transitions` on a candle.

### The Key Insight from Dwarf Fortress

Dwarf Fortress creatures are defined in RAW text files — pure data, not code. A dwarf's personality, needs, body parts, and materials are all declared in structured text. The DF engine doesn't know what a "dwarf" is. It knows how to simulate entities with needs, bodies, and personalities. The creature definition tells the engine *what to simulate*; the engine decides *how*.

We apply the same principle: a rat `.lua` file declares behavior metadata. The engine's generic creature tick evaluates that metadata. No rat-specific engine code exists. Ever.

### What Makes Creatures Different from Objects

| Property | Inanimate Object | Creature |
|----------|-----------------|----------|
| `animate` | `false` (default) | `true` |
| Agency | None — responds only to player actions | Has drives, makes decisions each tick |
| Movement | Stays where placed (unless moved by player) | Can move between rooms autonomously |
| FSM | Player-triggered transitions | Autonomous + player-triggered transitions |
| Sensory | Static descriptions per state | State-dependent + context-dependent descriptions |
| Room presence | Static text | Dynamic text (may change each turn) |
| Tick participation | FSM auto-transitions only | Full behavior evaluation |
| Mortality | Destroyed via mutation | Dies via health/injury system |

---

## 2. Architecture: How NPCs Extend the Object System

### Creatures ARE Objects

A creature has everything an object has:

- **GUID** — unique identity in the registry
- **Template** — inherits from the new `creature` base template
- **Keywords** — resolved by the parser (`rat`, `rodent`, `vermin`)
- **Sensory properties** — `on_feel`, `on_smell`, `on_listen`, `on_taste`, `description`
- **Material** — `flesh` (new material definition needed)
- **FSM states** — `alive-idle`, `alive-wandering`, `alive-fleeing`, `dead`
- **Location** — exists in a room, tracked by the registry
- **Size/weight** — physical properties for containment validation

A creature ALSO has:

- **`animate = true`** — the opt-in flag that enrolls it in the creature tick
- **`behavior`** — a table of behavioral rules (metadata, not code)
- **`drives`** — a table of need values that bias behavior selection
- **`reactions`** — a table mapping stimuli to responses
- **`movement`** — rules for autonomous room traversal
- **`awareness`** — what the creature can perceive (sight range, sound sensitivity)

### The Dwarf Fortress "RAW" Analogy

In DF, a creature RAW file declares:

```
[CREATURE:RAT]
[BODY:BASIC_2PARTBODY]
[CREATURE_TILE:'r']
[NATURAL_SKILL:DODGING:3]
[PREFSTRING:twitching whiskers]
```

In our engine, a creature `.lua` file declares:

```lua
return {
    guid = "{...}",
    template = "creature",
    id = "rat",
    animate = true,
    behavior = {
        default = "wander",
        aggression = 0,
        flee_threshold = 0.1,
    },
    drives = {
        hunger = { value = 50, decay_rate = 2, ... },
    },
    -- ...
}
```

Same principle: **data-driven creature definition**. The engine doesn't know what a rat is. It knows how to evaluate `behavior`, `drives`, and `reactions` tables.

### Relationship to Existing Systems

| Existing System | How Creatures Use It |
|-----------------|---------------------|
| **Registry** | Creatures are registered like any object (GUID-indexed) |
| **Loader** | Creature `.lua` files are loaded via the sandboxed loader |
| **FSM** | Creature states use the existing FSM engine (same `states`, `transitions`, `_state`) |
| **Containment** | Dead creatures can be picked up if small enough; live ones resist |
| **Materials** | Creature material (`flesh`) uses the existing material registry |
| **Effects pipeline** | Creature reactions route through the effects system |
| **Room nesting** | Creatures placed in rooms via `instances` array (same as objects) |
| **Parser** | Creatures resolved by keyword (same pipeline — Tier 1 through Tier 5) |

---

## 3. The Creature Template

A new base template: `src/meta/templates/creature.lua`

```lua
-- template: creature
-- Base template for animate beings (animals, monsters, eventually humanoids).
-- Creatures are objects with behavior metadata evaluated by the creature tick.

return {
    guid = "{new-guid}",
    id = "creature",
    name = "a creature",
    keywords = {},
    description = "A living creature.",

    -- Object properties (inherited from object system)
    size = 1,
    weight = 1.0,
    portable = false,       -- live creatures resist being carried
    material = "flesh",
    container = false,
    capacity = 0,
    contents = {},
    location = nil,
    categories = {"creature"},
    mutations = {},

    -- ═══ CREATURE EXTENSION (Principle 0a) ═══
    animate = true,

    -- Required sensory (on_feel is mandatory per engine rules)
    on_feel = "Warm, alive.",
    on_smell = "An animal smell.",
    on_listen = "Quiet breathing.",
    on_taste = nil,          -- creatures typically bite back

    -- FSM: creatures use the same FSM engine as objects
    initial_state = "alive-idle",
    _state = "alive-idle",
    states = {},             -- overridden by specific creatures
    transitions = {},        -- overridden by specific creatures

    -- Behavior metadata (engine evaluates generically)
    behavior = {
        default = "idle",    -- what to do when no drive is urgent
        aggression = 0,      -- 0 = passive, 100 = always attacks
        flee_threshold = 50, -- flee when fear > this value
        wander_chance = 0,   -- probability of moving rooms per tick (0-100)
        territorial = false, -- does it defend a home room?
        nocturnal = false,   -- active at night, sleeps during day?
        home_room = nil,     -- room ID it considers "home"
    },

    -- Drives (Dwarf Fortress needs system, simplified)
    drives = {
        -- Each drive: { value = 0-100, decay_rate = per-tick change,
        --               satisfy_action = what satisfies it }
        -- hunger = { value = 50, decay_rate = 1 },
        -- fear   = { value = 0,  decay_rate = -5 },
    },

    -- Reactions: stimulus → response mapping (metadata-driven)
    reactions = {
        -- player_enters  = { action = "flee", message = "..." },
        -- player_attacks  = { action = "flee", message = "..." },
        -- loud_noise      = { action = "hide", message = "..." },
    },

    -- Movement rules
    movement = {
        speed = 1,           -- rooms per tick (1 = can move 1 room per turn)
        can_open_doors = false,
        can_climb = false,
        size_limit = nil,    -- can squeeze through exits this size or larger
    },

    -- Awareness
    awareness = {
        sight_range = 1,     -- rooms away it can detect player visually
        sound_range = 2,     -- rooms away it can hear player
        smell_range = 1,     -- rooms away it can smell player
    },

    -- Health/mortality
    health = 10,
    max_health = 10,
    alive = true,
}
```

### Template Inheritance

Just like `small-item` inherits from a base and objects override fields, creature instances inherit from the `creature` template and override everything specific:

```
creature (base template)
  └── rat (creature instance — overrides behavior, drives, sensory, size)
  └── cat (creature instance — overrides differently)
  └── guard-dog (creature instance)
```

---

## 4. Behavior System (Dwarf Fortress–Inspired)

### 4.1 The Behavior Loop

Each creature's turn follows this evaluation order:

```
1. UPDATE DRIVES     → decay/grow drive values based on time
2. CHECK REACTIONS   → has a stimulus occurred? (player entered, attacked, etc.)
3. EVALUATE BEHAVIOR → pick the highest-priority action
4. EXECUTE ACTION    → perform the chosen action (move, flee, idle, etc.)
5. EMIT PRESENCE     → generate room_presence text for the player
```

This is **not code in the engine per creature**. This is a generic loop that reads metadata. The engine asks: "What are this creature's drives? What reactions match current stimuli? What behavior has the highest utility?" All answers come from the creature's `.lua` data.

### 4.2 Drive System (Simplified Dwarf Fortress Needs)

Dwarf Fortress tracks 30+ personality facets and a dozen need categories. We start with **three drives** for Phase 1:

| Drive | Range | Effect on Behavior | Rat Value |
|-------|-------|-------------------|-----------|
| **hunger** | 0–100 | High hunger → seek food, risk exposure | Starts 50, decays +2/tick |
| **fear** | 0–100 | High fear → flee, hide | Starts 0, spikes on stimulus |
| **curiosity** | 0–100 | High curiosity → investigate new things | Starts 30, low priority |

**Drive Resolution** (utility scoring, Dwarf Fortress–style):

```
For each possible action:
  score = base_utility
        + (hunger_weight × hunger_value)
        + (fear_weight × fear_value)
        + (curiosity_weight × curiosity_value)
        + random_jitter(-5, +5)

Pick the action with the highest score.
```

The random jitter prevents robotic predictability — a DF lesson. Two rats in identical states should occasionally make different choices.

### 4.3 Creature FSM States

Creatures use the existing FSM engine but with creature-appropriate states:

```
┌──────────┐    stimulus    ┌──────────┐
│alive-idle│──────────────→│alive-flee│
└────┬─────┘               └─────┬────┘
     │ wander_chance              │ safe
     ↓                            ↓
┌────────────┐              ┌──────────┐
│alive-wander│             │alive-idle│
└────────────┘              └──────────┘
     │ all states
     ↓ (damage)
┌──────────┐    health=0   ┌──────┐
│alive-hurt│──────────────→│ dead │
└──────────┘               └──────┘
```

Each state has different behavior metadata:

```lua
states = {
    ["alive-idle"] = {
        description = "A rat sits hunched in the corner, whiskers twitching.",
        room_presence = "A rat crouches near the baseboard.",
        behavior_override = nil,  -- uses default behavior
    },
    ["alive-wander"] = {
        description = "A rat scurries across the floor.",
        room_presence = "A rat scurries along the baseboard.",
        behavior_override = "wander",
    },
    ["alive-flee"] = {
        description = "A rat darts frantically, looking for an escape.",
        room_presence = "A rat is bolting toward the nearest exit.",
        behavior_override = "flee",
    },
    dead = {
        description = "A dead rat lies motionless, eyes glassy.",
        room_presence = "A dead rat lies on the floor.",
        portable = true,  -- dead creatures can be picked up
        animate = false,  -- no longer participates in creature tick
        on_feel = "Cooling fur. Limp body. A tail like wet string.",
        on_smell = "The sharp, coppery smell of blood and the musk of rodent.",
    },
}
```

### 4.4 Reaction System

Reactions are the stimulus→response mappings that make creatures feel alive. They are **metadata tables**, not engine code:

```lua
reactions = {
    player_enters = {
        action = "evaluate",  -- re-evaluate behavior with fear spike
        fear_delta = 40,      -- spike fear by 40
        message = "The rat freezes, beady eyes fixed on you.",
        delay = 0,            -- react immediately
    },
    player_attacks = {
        action = "flee",
        fear_delta = 80,
        message = "The rat squeals and bolts!",
        delay = 0,
    },
    loud_noise = {
        action = "flee",
        fear_delta = 30,
        message = "The rat startles and scurries away.",
        delay = 0,
    },
    player_offers_food = {
        action = "approach",
        hunger_delta = -20,   -- reduces hunger drive
        fear_delta = -10,     -- slightly less afraid
        message = "The rat cautiously sniffs the air, whiskers working.",
        delay = 1,            -- takes a turn to decide
    },
}
```

The engine doesn't know what "player_enters" means in rat terms. It knows: *when this stimulus fires, apply these drive deltas and execute this action*. Same engine code handles a rat fleeing from a player and (eventually) a guard dog growling at an intruder.

### 4.5 How Actions Work

Actions are the verbs of the creature world — what a creature *does* during its tick:

| Action | Engine Behavior | Example |
|--------|----------------|---------|
| `idle` | Do nothing; emit idle presence text | Rat sits in corner |
| `wander` | Pick a random valid exit; move to adjacent room | Rat scurries north |
| `flee` | Pick the exit farthest from threat; move immediately | Rat bolts through doorway |
| `hide` | Reduce visibility; become harder to target | Rat squeezes under furniture |
| `approach` | Move toward target (food, curiosity source) | Rat edges toward crumbs |
| `attack` | Apply damage to target via effects pipeline | (Phase 3+: aggressive creatures) |
| `vocalize` | Emit a sound in the room | Rat squeaks |

Each action is a **generic engine function** that reads the creature's metadata to determine specifics. The `flee` action doesn't know it's a rat — it reads `movement.speed`, checks available exits, and picks the best one based on threat direction.

---

## 5. The Tick System: When Creatures Act

### 5.1 Integration Point

The game loop currently has this post-command structure:

```
1. Player enters command
2. Parse → verb dispatch → handler executes
3. FSM auto-transition tick (candle burn, etc.)
4. Timed events tick
5. Fire propagation tick
6. Injury tick
7. Game over check
8. ---END--- delimiter
```

The creature tick slots in **after the FSM tick and before injury tick** — this is the natural point where world simulation advances:

```
1. Player enters command
2. Parse → verb dispatch → handler executes
3. FSM auto-transition tick (candle burn, etc.)
4. Timed events tick
5. Fire propagation tick
6. ★ CREATURE TICK (new) ★         ← creatures act here
7. Injury tick
8. Game over check
9. ---END--- delimiter
```

### 5.2 The Creature Tick Algorithm

```
creature_tick(context):
    for each creature in registry where animate == true:
        1. Update drives (decay hunger up, decay fear down, etc.)
        2. Check for stimuli since last tick:
           - Did the player enter this creature's room?
           - Did the player attack this creature?
           - Did a loud noise occur?
           - Did another creature enter/leave?
        3. Apply reaction drive deltas from any matching stimuli
        4. Score available actions via utility calculation
        5. Execute the highest-scoring action
        6. If creature is in player's current room:
           - Emit any messages (creature action narration)
           - Update room_presence text
        7. If creature moved rooms:
           - If moved INTO player's room: emit arrival narration
           - If moved OUT OF player's room: emit departure narration
           - Update registry location
```

### 5.3 Perception Range

Not every creature ticks at full fidelity every turn. Borrowing from Dwarf Fortress's spatial optimization:

| Creature Location | Tick Fidelity | What Updates |
|-------------------|--------------|--------------|
| **Same room as player** | Full | All drives, reactions, actions, narration |
| **Adjacent room (1 exit away)** | Partial | Drives decay, movement allowed, sound narration |
| **Distant (2+ rooms away)** | Minimal | Drives decay only; no movement, no narration |

This means a rat two rooms away still gets hungrier over time, but doesn't waste computation on pathfinding or message generation. When the player walks into its room, it snaps to full fidelity.

### 5.4 Stimulus Events

The engine needs to emit stimulus events that creatures can react to. These are NOT creature-specific — they're generic world events:

| Stimulus | Trigger | Source |
|----------|---------|--------|
| `player_enters` | Player moves into a room containing creatures | Room transition code |
| `player_leaves` | Player leaves a room containing creatures | Room transition code |
| `player_attacks` | Player uses an attack verb on a creature | Verb handler dispatch |
| `loud_noise` | Player breaks something, slams door, etc. | Effects pipeline |
| `light_change` | Room light level changes (candle lit/extinguished) | FSM transition |
| `creature_enters` | Another creature enters the room | Creature tick (movement) |
| `creature_dies` | A creature in the room dies | Health/damage system |
| `food_available` | Food object placed in room or on surface | Containment system |

---

## 6. The Rat — First NPC Specification

### 6.1 Creature Definition

File: `src/meta/objects/rat.lua`

```lua
return {
    guid = "{generate-new-guid}",
    template = "creature",
    id = "rat",
    name = "a brown rat",
    keywords = {"rat", "rodent", "vermin", "brown rat", "creature"},
    description = "A plump brown rat with matted fur and a long, naked tail. Its beady black eyes dart nervously, and its whiskers twitch with constant, anxious energy.",

    -- Physical properties
    size = 1,
    weight = 0.3,
    portable = false,         -- can't pick up a live rat
    material = "flesh",

    -- ═══ ANIMATE ═══
    animate = true,

    -- Sensory (MANDATORY: on_feel is primary dark sense)
    on_feel = "Coarse, greasy fur over a warm, squirming body. A thick tail whips against your fingers. It bites.",
    on_smell = "Musty rodent — damp fur, old nesting material, and the faint ammonia of urine.",
    on_listen = "Skittering claws on stone. An occasional high-pitched squeak.",
    on_taste = "You'd have to catch it first. And then you'd regret it.",

    -- FSM
    initial_state = "alive-idle",
    _state = "alive-idle",
    states = {
        ["alive-idle"] = {
            description = "A brown rat sits hunched near the baseboard, grooming itself with tiny pink paws.",
            room_presence = "A rat crouches in the shadows near the wall.",
            on_listen = "Quiet chittering. The soft rasp of fur being groomed.",
        },
        ["alive-wander"] = {
            description = "A brown rat scurries across the floor, nose working furiously.",
            room_presence = "A rat scurries along the baseboard.",
            on_listen = "The rapid click of tiny claws on stone.",
        },
        ["alive-flee"] = {
            description = "The rat is a blur of brown fur, darting frantically toward the nearest exit.",
            room_presence = "A panicked rat zigzags across the floor.",
            on_listen = "Frantic squeaking and the scrabble of claws.",
        },
        dead = {
            description = "A dead rat lies on its side, legs splayed. Its fur is matted with blood.",
            room_presence = "A dead rat lies crumpled on the floor.",
            portable = true,
            animate = false,
            on_feel = "Cooling fur over a limp body. The tail hangs like wet string.",
            on_smell = "Blood and musk. The sharp copper of death.",
            on_listen = "Nothing. Absolutely nothing.",
            on_taste = "Fur and blood. You immediately regret this decision.",
        },
    },
    transitions = {
        { from = "alive-idle",   to = "alive-wander", verb = "_tick", condition = "wander_roll" },
        { from = "alive-wander", to = "alive-idle",   verb = "_tick", condition = "settle_roll" },
        { from = "alive-idle",   to = "alive-flee",   verb = "_tick", condition = "fear_high" },
        { from = "alive-wander", to = "alive-flee",   verb = "_tick", condition = "fear_high" },
        { from = "alive-flee",   to = "alive-idle",   verb = "_tick", condition = "fear_low" },
        { from = "*",            to = "dead",          verb = "_damage", condition = "health_zero" },
    },

    -- Behavior metadata
    behavior = {
        default = "idle",
        aggression = 5,        -- very low — rats almost never attack
        flee_threshold = 30,   -- flees when fear > 30 (rats are cowardly)
        wander_chance = 40,    -- 40% chance to wander each tick when idle
        settle_chance = 60,    -- 60% chance to stop wandering and idle again
        territorial = false,
        nocturnal = true,      -- more active at night (game starts at 2 AM!)
        home_room = nil,       -- assigned by room placement
    },

    -- Drives (simplified DF needs)
    drives = {
        hunger = {
            value = 50,
            decay_rate = 2,       -- gets hungrier by 2 per tick
            max = 100,
            satisfy_action = "eat",
            satisfy_threshold = 80, -- starts actively seeking food at 80
        },
        fear = {
            value = 0,
            decay_rate = -10,     -- fear decays by 10 per tick (rats calm down fast)
            max = 100,
            min = 0,
        },
        curiosity = {
            value = 30,
            decay_rate = 1,       -- slowly more curious
            max = 60,             -- rats aren't very curious (cap low)
        },
    },

    -- Reactions (stimulus → response)
    reactions = {
        player_enters = {
            action = "evaluate",
            fear_delta = 35,
            message = "A rat freezes, beady eyes fixed on you. Its whiskers quiver.",
        },
        player_attacks = {
            action = "flee",
            fear_delta = 80,
            message = "The rat squeals — a piercing, desperate sound — and bolts!",
        },
        loud_noise = {
            action = "flee",
            fear_delta = 25,
            message = "The rat startles at the noise and scurries into the shadows.",
        },
        light_change = {
            action = "evaluate",
            fear_delta = 15,
            message = "The rat's eyes flash red in the sudden light. It flinches.",
        },
    },

    -- Movement
    movement = {
        speed = 1,
        can_open_doors = false,  -- rats can't open doors
        can_climb = true,        -- rats can use climb-only exits
        size_limit = 1,          -- can squeeze through tiny openings
    },

    -- Awareness
    awareness = {
        sight_range = 1,
        sound_range = 2,
        smell_range = 3,         -- rats have excellent noses
    },

    -- Health
    health = 5,
    max_health = 5,
    alive = true,
}
```

### 6.2 Room Placement

Rats are placed in rooms the same way objects are — via the `instances` array:

```lua
-- In a room definition (e.g., cellar.lua)
instances = {
    { id = "cellar-rat", type_id = "{guid-rat}" },
    { id = "wine-barrel", type_id = "{guid-barrel}",
        contents = { ... }
    },
}
```

The rat appears in the room just like any object. The difference is that `animate = true` means the creature tick will evaluate it.

### 6.3 Player Interactions with the Rat

| Player Action | Verb | What Happens |
|---------------|------|-------------|
| `look rat` | look | Displays current state description |
| `examine rat` | examine | Detailed description + behavioral observation |
| `feel rat` | feel | "Coarse, greasy fur..." — rat bites (minor damage) |
| `smell rat` | smell | "Musty rodent..." — safe, informative |
| `listen rat` | listen | State-dependent sound description |
| `taste rat` | taste | "You'd have to catch it first." |
| `catch rat` | catch | New verb — attempts to grab (requires free hand, dexterity check) |
| `kick rat` / `hit rat` / `attack rat` | attack | Deals damage, triggers flee reaction |
| `chase rat` | chase | New verb — follows rat if it flees (may lead to adjacent room) |
| `throw [object] at rat` | throw | Ranged attack via thrown object |

### 6.4 Emergent Rat Behaviors (From Rules, Not Scripts)

These are NOT scripted. They emerge from the drive/reaction/behavior system:

1. **Rat flees when player enters** — because `player_enters` reaction spikes fear above `flee_threshold`
2. **Rat returns after player is still for a few turns** — because fear decays at -10/tick, eventually dropping below threshold
3. **Rat is more active at night** — because `nocturnal = true` increases wander_chance during night hours
4. **Rat squeaks when startled by noise** — because `loud_noise` reaction includes a vocalization message
5. **Rat ignores player in adjacent room** — because `awareness.sight_range = 1` means it only sees the current room
6. **Rat scurries through small openings player can't use** — because `movement.size_limit = 1` allows tiny exits
7. **Dead rat can be picked up** — because `dead` state sets `portable = true` and `animate = false`

This is the Dwarf Fortress lesson in miniature: **simple rules → emergent behavior**.

---

## 7. Engine Changes Required

All changes must respect Principle 8: **generic, not creature-specific**.

### 7.1 New Module: `src/engine/creatures/init.lua`

A new engine module that handles the creature tick. It does NOT know about rats, cats, or dogs. It knows about:

- Tables with `animate = true`
- Drive decay/growth
- Stimulus matching against `reactions` tables
- Utility-scored action selection
- Generic action execution (move, flee, idle, vocalize, etc.)

**Estimated size:** ~200–300 lines of Lua.

### 7.2 Game Loop Integration

Add creature tick to `src/engine/loop/init.lua` after fire propagation:

```lua
-- Creature tick: evaluate behavior for all animate objects
local creature_ok, creature_mod = pcall(require, "engine.creatures")
if creature_ok and creature_mod then
    local creature_msgs = creature_mod.tick(context)
    for _, msg in ipairs(creature_msgs) do
        print(msg)
    end
end
```

This is identical in pattern to fire propagation, injury ticks, and FSM ticks — ~6 lines.

### 7.3 New Material: `src/meta/materials/flesh.lua`

```lua
return {
    name = "flesh",
    density = 1050,
    melting_point = nil,
    ignition_point = 300,
    hardness = 1,
    flexibility = 0.8,
    absorbency = 0.6,
    opacity = 1.0,
    flammability = 0.2,
    conductivity = 0.1,
    fragility = 0.7,
    value = 0,
}
```

### 7.4 New Template: `src/meta/templates/creature.lua`

As specified in Section 3 above.

### 7.5 Stimulus Event Emission

Several existing engine points need to emit stimulus events for creature reactions:

| Location | Change | Stimulus Emitted |
|----------|--------|-----------------|
| Room transition (verbs/init.lua) | After player moves to new room | `player_enters` for creatures in new room; `player_leaves` for creatures in old room |
| Attack verb handler | After player attacks a creature | `player_attacks` for the target creature |
| Effects pipeline | After loud effects (break, slam) | `loud_noise` for creatures in same room |
| FSM transition (light change) | After light source lit/extinguished | `light_change` for creatures in same room |

These are **generic event emissions**, not creature-specific code. The stimulus system is a simple event bus:

```lua
-- In engine/creatures/init.lua
local stimulus_queue = {}

function creatures.emit_stimulus(room_id, stimulus_type, data)
    stimulus_queue[#stimulus_queue + 1] = {
        room = room_id,
        type = stimulus_type,
        data = data or {},
    }
end
```

### 7.6 Verb Extensions

New verbs or verb modifications:

| Verb | Type | Description |
|------|------|-------------|
| `catch` | New | Attempt to grab a small creature (requires free hand, creature must be alive) |
| `chase` | New | Follow a fleeing creature to the adjacent room |
| `attack`/`hit`/`kick` | Modified | Extend to target creatures, apply damage, trigger reactions |
| `look` | Modified | Include creature room_presence in room descriptions |
| `throw` | Modified | Allow targeting creatures |

### 7.7 Room Description Integration

When the player `look`s at a room, creature `room_presence` text should be appended to the room description, the same way object `room_presence` text is composed today. Creatures in the room add their presence dynamically:

```
Cellar
Stone walls weep with moisture. The air is cold and smells of old wine.

A rat crouches in the shadows near the wall.

Exits: north (stairs up), east (passage)
```

---

## 8. New Verb Interactions

### 8.1 `catch` Verb

```lua
verbs.catch = function(context, noun)
    local creature = resolve_creature(context, noun)
    if not creature then
        err_not_found(context)
        return
    end
    if not creature.animate or not creature.alive then
        print("It's not going anywhere. You can just pick it up.")
        -- fall through to "take" behavior
        return
    end
    if creature.size > 2 then
        print("It's far too large to catch with your bare hands.")
        return
    end
    -- Catch attempt: compare player dexterity vs creature flee speed
    local success = math.random(100) > (creature.behavior.flee_threshold + 20)
    if success then
        print("You snatch the " .. creature.id .. "! It squirms in your grip.")
        -- Move to player's hand, set state to "caught"
    else
        print("The " .. creature.id .. " darts away just as your fingers close!")
        creatures.emit_stimulus(context.current_room.id, "player_attacks", { target = creature.id })
    end
end
```

### 8.2 `chase` Verb

```lua
verbs.chase = function(context, noun)
    local creature = resolve_creature(context, noun)
    if not creature or creature._state ~= "alive-flee" then
        print("Nothing to chase.")
        return
    end
    -- If creature just fled through an exit, player follows
    if creature._last_exit then
        print("You dash after the " .. creature.id .. "!")
        -- Trigger room transition through creature's exit
    end
end
```

---

## 9. Scaling Path: Rat → Creatures → Humanoids

### Phase 1: The Rat (Foundation)

**Scope:** Single creature type, basic behavior, flee/wander/idle.

| Deliverable | Owner | Description |
|-------------|-------|-------------|
| `creature` template | Flanders | Base template with animate fields |
| `rat.lua` definition | Flanders | First creature, complete metadata |
| `flesh.lua` material | Flanders | New material for organic creatures |
| `engine/creatures/init.lua` | Bart | Generic creature tick engine |
| Game loop integration | Bart | ~6 lines in loop/init.lua |
| Stimulus emission | Bart | 4–5 emit points in existing code |
| `catch` verb | Smithers | New verb handler |
| Room presence integration | Smithers | Creature text in room descriptions |
| Tests | Nelson | Creature tick, rat behavior, verb interactions |

**What we learn:** Does the metadata-driven behavior system feel alive? Is the tick integration smooth? Does the drive system produce interesting behavior or robotic predictability?

### Phase 2: Creature Variety (3–4 more creatures)

**Scope:** Prove the system generalizes beyond rats.

| Creature | Behavior Profile | New Mechanics |
|----------|-----------------|---------------|
| **Cat** | Predator — hunts rat, ignores player unless threatened | Creature-to-creature interaction |
| **Bat** | Flies, startles player, hangs from ceiling | Vertical movement (up/down exits) |
| **Guard dog** | Territorial, aggressive, patrols area | Aggression, territory defense |
| **Spider** | Passive, weaves webs (creates traps), venomous | Creature-created objects (web) |

**Key system additions:**
- Creature-to-creature reactions (cat sees rat → chase)
- Territorial behavior (dog defends room)
- Creature-created objects (spider web as a new object spawned by creature tick)

### Phase 3: Creature Ecology (Emergent Interactions)

**Scope:** Creatures interact with each other, creating emergent ecosystems.

| Interaction | Rules Involved | Emergent Result |
|-------------|---------------|----------------|
| Cat catches rat | Cat has `prey = {"rat"}` in behavior; rat has `predator = {"cat"}` | Cat population controls rat population |
| Dog chases cat | Territorial defense → cat triggers dog's territory reaction | Food chain emerges |
| Bats flee from light | `light_change` reaction with high fear_delta | Lighting a torch clears bats from room |
| Spider web catches rat | Web object has trap effect; rat size ≤ trap size | Environmental hazard for creatures |

**The DF lesson here:** None of these interactions are scripted. They emerge from:
- Prey/predator metadata on creatures
- Generic creature-to-creature stimulus events
- The same drive/reaction/utility system used for player interactions

### Phase 4: Humanoid NPCs (The North Star)

**Scope:** Full NPC system with inventory, dialogue, memory, quests.

| New Capability | Extends | Complexity |
|----------------|---------|------------|
| **Inventory** | Creatures gain `contents`/hand slots (same as player) | Moderate |
| **Dialogue** | New `dialogue` metadata field with conversation trees | High |
| **Memory** | Event log per NPC (DF thought system, simplified) | Moderate |
| **Quests** | Quest-giver archetype with objective tracking | High |
| **Relationships** | NPC-to-NPC and NPC-to-player relationship scores | High |
| **Schedules** | Time-based behavior overrides (patrol at night, sleep at day) | Moderate |

**What we're deferring to Phase 4:**
- Full A* pathfinding (Phases 1–3 use random valid exit selection)
- Social relationships between creatures
- Dialogue/conversation system
- Quest tracking
- NPC inventory management
- Complex personality facets (DF's 30+ traits)

---

## 10. Dwarf Fortress Lessons Applied

### What We Borrow

| DF Concept | Our Adaptation | Phase |
|------------|---------------|-------|
| **Creature RAWs** | Creature `.lua` files as pure data definitions | 1 |
| **Needs/drives** | Simplified 3-drive system (hunger, fear, curiosity) | 1 |
| **Material system** | Creature material (`flesh`) in existing material registry | 1 |
| **Utility-based action selection** | Score actions by drive state + jitter | 1 |
| **Personality facets** | Per-creature behavior tuning (aggression, flee_threshold) | 1 |
| **Thought system** | Stimulus → reaction → drive delta → action | 1 |
| **Spatial optimization** | Tick fidelity based on distance from player | 1 |
| **Creature-to-creature interaction** | Prey/predator metadata + generic stimulus | 3 |
| **Mood/emotion state** | Fear as primary emotional drive, expandable | 1–2 |
| **Autonomous goal pursuit** | Drive satisfaction as goal (hunger → seek food) | 2+ |

### What We Deliberately Omit (Too Complex for Text Adventure)

| DF Feature | Why We Skip It | When to Reconsider |
|------------|---------------|-------------------|
| **Body part simulation** | Our combat system is simpler; creature health is a single number | Phase 4 (humanoids may need body parts) |
| **30+ personality facets** | Overkill for animals; 3–5 behavior tuning values suffice | Phase 4 (humanoid NPCs with personality) |
| **Social contagion** | Requires group dynamics we don't have yet | Phase 4+ |
| **Strange moods** | Narrative system for dwarves; animals don't have creative drives | Phase 4+ |
| **Skill progression** | Creatures don't learn in Phases 1–3 | Phase 4 (humanoids learn) |
| **Job assignment** | Player doesn't manage creature labor | Phase 4 (ally NPCs) |
| **Multi-century history generation** | We're a text adventure, not a civilization sim | Never (probably) |

### The Core Lesson

> "Worst mistake I see in NPC design — and I've seen it in approximately one million bad fan games — is trying to script *behavior*. You can't script enough behaviors to make an NPC feel alive. Dwarf Fortress proved that the answer is: **script the rules, not the behaviors**. Rules compose. Behaviors don't." — Comic Book Guy

---

## 11. Implementation Phases & Estimates

### Phase 1: The Rat (Foundation Sprint)

**Estimated effort:** 2–3 sessions of focused work across the team.

| Task | Owner | Files | Est. Lines | TDD Tests Required |
|------|-------|-------|-----------|-------------------|
| Design creature template | CBG (done — this doc) | — | — | — |
| Implement `creature.lua` template | Flanders | `src/meta/templates/creature.lua` | ~50 | Template loads, fields validate |
| Implement `flesh.lua` material | Flanders | `src/meta/materials/flesh.lua` | ~15 | Material properties resolve |
| Implement `rat.lua` definition | Flanders | `src/meta/objects/rat.lua` | ~120 | Object loads, all fields valid, FSM states resolve |
| Build `engine/creatures/init.lua` | Bart | `src/engine/creatures/init.lua` | ~250 | Drive update, stimulus matching, action selection, movement, tick integration |
| Game loop integration | Bart | `src/engine/loop/init.lua` | ~6 | Creature tick fires post-command |
| Stimulus emission points | Bart | `src/engine/verbs/init.lua`, `src/engine/fsm/init.lua` | ~20 | Stimuli emitted on room enter, attack, noise, light change |
| Room presence integration | Smithers | `src/engine/verbs/init.lua` (look handler) | ~15 | Creature presence appears in room descriptions |
| `catch` verb handler | Smithers | `src/engine/verbs/init.lua` | ~30 | Catch attempts on live creatures, dead creatures, non-creatures |
| `chase` verb handler | Smithers | `src/engine/verbs/init.lua` | ~25 | Chase fleeing creature, chase non-fleeing creature, nothing to chase |
| Attack verb extension | Smithers | `src/engine/verbs/init.lua` | ~20 | Attack creature, damage applied, death transition |
| Creature tick tests | Nelson | `test/creatures/test-creature-tick.lua` | ~150 | Drive decay, stimulus reaction, action selection, movement, room boundaries |
| Rat behavior tests | Nelson | `test/creatures/test-rat.lua` | ~100 | Rat flees on player enter, rat wanders, rat dies, dead rat portable |
| Verb interaction tests | Nelson | `test/creatures/test-creature-verbs.lua` | ~100 | catch, chase, attack, look, feel, smell, listen on creatures |
| Integration tests | Nelson | `test/integration/test-creature-integration.lua` | ~80 | Full game loop with rat: enter room, rat reacts, player catches, etc. |

**Total new lines:** ~960 (code) + ~430 (tests) = ~1,390 lines

**Files created:** 5 new files, 3 modified files

### Phase 2: Creature Variety

**Estimated effort:** 2 sessions per creature.

- 3–4 new creature definitions (~120 lines each)
- Creature-to-creature stimulus system (~100 lines in creatures module)
- Territorial behavior (~50 lines)
- Extended tests (~200 lines per creature)

### Phase 3: Creature Ecology

**Estimated effort:** 3–4 sessions total.

- Prey/predator interaction system (~150 lines)
- Creature-spawned objects (spider web) (~100 lines + object definitions)
- Food chain simulation (~100 lines)
- Ecology integration tests (~300 lines)

### Phase 4: Humanoid NPCs

**Estimated effort:** 8–12 sessions (this is the big one).

- Dialogue system (~500 lines)
- NPC memory/thought system (~300 lines)
- Quest framework (~400 lines)
- Inventory for NPCs (~200 lines — reuse player inventory code)
- Relationship tracking (~200 lines)
- 3–5 humanoid NPC definitions (~150 lines each)
- Extensive testing (~1,000+ lines)

---

## 12. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| **Creature tick slows game loop** | Low | Medium | Spatial optimization (only full-tick creatures in/near player room) |
| **Behavior feels robotic** | Medium | High | Random jitter on utility scores; fear decay creates variation |
| **Creature movement breaks room state** | Medium | Medium | Use existing registry location tracking; test movement extensively |
| **Scope creep into humanoid features** | High | High | Hard phase boundaries; Phase 1 is ONLY rat + foundation |
| **Sensory descriptions stale after repeated encounters** | Medium | Low | State-dependent descriptions; consider description pools (Phase 2) |
| **Creature-to-creature interactions cascade** | Low | Medium | Limit cascade depth (max 3 creature-to-creature reactions per tick) |
| **Dead creature pickup conflicts with containment** | Low | Low | `dead` state sets `portable = true`; containment system handles normally |
| **Existing tests break** | Low | Medium | Creature tick is opt-in; no creatures in existing rooms means zero impact |

---

## 13. Open Questions

These questions should be resolved before or during Phase 1 implementation:

1. **Creature respawning:** Do killed creatures stay dead forever (permanent consequence) or respawn after time? Recommendation: permanent death in Phase 1 (DF-style), respawn system added in Phase 2 if needed.

2. **Multiple creatures per room:** Can a room have multiple creatures? Recommendation: yes, the system should support N creatures per room from day one.

3. **Creature inventory:** Can the rat carry objects (e.g., steal a shiny key)? Recommendation: defer to Phase 2. Rat in Phase 1 has no inventory.

4. **Creature-to-player combat:** If the rat bites back when grabbed (`on_feel` implies it does), how does that work mechanically? Recommendation: minor damage via the existing injury/effects pipeline. Effect type: `bite`, injury severity: `minor`.

5. **Creature noise as parser input:** If a rat squeaks, can the player `listen` to the squeak from an adjacent room? Recommendation: yes, creatures with `awareness.sound_range > 0` emit audible events to adjacent rooms.

6. **Save/load:** How do creature states persist across save/load? Recommendation: creatures are objects in the registry; the existing save/load system (when built) should handle them identically.

7. **The dark room question:** At 2 AM (game start), the player is in darkness. Can they hear the rat? Recommendation: absolutely yes. This is a *feature*. Player hears "skittering claws" in the darkness before they can see anything. The rat's `on_listen` provides audio-only presence in darkness.

---

## Summary

> "I've read every text adventure from Zork to AI Dungeon, analyzed Dwarf Fortress's architecture until my eyes bled, and reviewed every MUD NPC system from DikuMUD to Evennia. This plan is the distillation of forty years of game design wisdom, adapted for our Lua metadata-driven engine. The rat is not the destination. The rat is the proof of concept. If the rat *feels* alive — if it scurries when you enter, calms down when you're still, and squeaks when you break something — then we've built a foundation that scales from rodents to NPCs to civilizations. And if it doesn't? Well. Worst. Rat. Ever."

— Comic Book Guy, 2026-03-28
