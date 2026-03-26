# Creature Template Architecture

**Last updated:** 2026-03-28  
**Audience:** Engine Architects, Game Designers  
**Purpose:** Specification of the creature template — the base class for all animate beings.

---

## Overview

The **creature template** (`src/meta/templates/creature.lua`) is a specialized object template that enables the creation of animate beings — animals, monsters, and eventually humanoids. Creatures are objects with the `animate = true` flag, which enrolls them in the engine's autonomous **creature tick** phase.

Unlike inanimate objects (which respond only to player actions), creatures have:
- **Autonomous behavior** — they act each turn based on drives, reactions, and FSM state
- **Awareness** — they perceive the player and other creatures at configurable ranges
- **Agency** — they make decisions via metadata-driven behavior evaluation, not hard-coded rules

This is **Principle 0a** in action: objects are inanimate by default, but opt-in with `animate = true` to participate in autonomous simulation.

---

## Template Inheritance

The creature template is inherited by specific creature instances. Each creature override fields as needed:

```
creature (base template) ← defines all required creature properties
  ├── rat (creature instance) ← overrides behavior, sensory, size
  ├── cat (creature instance) ← different behavior, larger size
  └── guard-dog (creature instance) ← territorial, higher aggression
```

Creature instances are defined in room `.lua` files (same as furniture and items), but use `template = "creature"` to inherit creature-specific defaults.

---

## Required Fields

Every creature MUST define or inherit these fields:

| Field | Type | Default | Required | Notes |
|-------|------|---------|----------|-------|
| `animate` | boolean | `true` | Yes | Enables creature tick participation |
| `on_feel` | string | "Warm, alive." | Yes | Primary sense in darkness |
| `on_smell` | string | "An animal smell." | Yes | Always available |
| `on_listen` | string | "Quiet breathing." | Yes | Always available |
| `initial_state` | string | "alive-idle" | Yes | FSM starting state |
| `_state` | string | "alive-idle" | Yes | Current FSM state (same as initial) |
| `states` | table | `` | Yes | FSM state definitions (see below) |
| `behavior` | table | `` | Yes | Behavior metadata (see below) |
| `health` | number | 10 | Yes | Current health points |
| `max_health` | number | 10 | Yes | Maximum health (for scaling) |
| `size` | string | "small" | Yes | Physical size enum (tiny, small, medium, large) |
| `weight` | number | 1.0 | Yes | For containment constraints |
| `material` | string | "flesh" | Yes | Physical material type |
| `awareness` | table | `` | Yes | Perception ranges (see below) |
| `movement` | table | `` | Yes | Locomotion rules (see below) |

---

## FSM States

Creatures use the same FSM engine as inanimate objects (Principle 8: objects declare behavior; engine executes it). Creature states follow a standard pattern:

### Standard State Names

| State | Description | Behavior | Example |
|-------|-------------|----------|---------|
| `alive-idle` | Resting, alert | `default` behavior | Rat sits in corner |
| `alive-wander` | Moving around | `wander` behavior | Rat scurries along wall |
| `alive-flee` | Escaping threat | `flee` behavior | Rat bolts toward exit |
| `alive-hurt` | Damaged but alive | Reduced-action behavior | (Phase 2+ combat) |
| `dead` | Health = 0, inanimate | `animate = false` | Creature corpse (pickupable if small) |

### State Definition Structure

Each state in the `states` table defines:

```lua
states = {
    ["alive-idle"] = {
        description = "A rat sits hunched in the corner, whiskers twitching.",
        room_presence = "A rat crouches near the baseboard.",
        on_feel = nil,           -- inherit from creature (optional override)
        on_smell = nil,          -- inherit from creature (optional override)
        on_listen = nil,         -- inherit from creature (optional override)
        behavior_override = nil, -- use default behavior (optional)
        animate = true,          -- stays animated (optional; default true)
        portable = false,        -- can't pick up (optional; default false)
    },
    dead = {
        description = "A dead rat lies motionless, eyes glassy.",
        room_presence = "A dead rat lies on the floor.",
        on_feel = "Cooling fur. Limp body. A tail like wet string.",
        on_smell = "The sharp, coppery smell of blood and the musk of rodent.",
        on_listen = "Nothing. Absolutely nothing.",
        animate = false,         -- creature tick no longer evaluates this
        portable = true,         -- player can pick up corpse
    },
},
```

**Key rules:**
- `description` — shown when player examines creature
- `room_presence` — shown in room listings (changes each turn based on action)
- `animate` — if `false`, removes creature from tick phase (used for death)
- `portable` — set to `true` for dead creatures (if small enough)
- Sensory overrides (`on_feel`, `on_smell`, etc.) are optional; if omitted, inherited from creature top-level

### FSM Transitions

Creature transitions use the same `transitions` table format as objects:

```lua
transitions = {
    { from = "alive-idle",   to = "alive-wander", verb = "_tick", condition = "wander_roll" },
    { from = "alive-wander", to = "alive-idle",   verb = "_tick", condition = "settle_roll" },
    { from = "alive-idle",   to = "alive-flee",   verb = "_tick", condition = "fear_high" },
    { from = "*",            to = "dead",         verb = "_damage", condition = "health_zero" },
},
```

**Creatures can transition on:**
- `verb = "_tick"` — autonomous transitions (behavior-driven)
- `verb = "_damage"` — health-based transitions (to dead)
- `verb = "<verb>"` — player-triggered transitions (same as objects)

---

## Behavior Metadata

The `behavior` table defines autonomous decision-making rules. The creature tick evaluates this metadata to choose actions each turn.

### Standard Behavior Fields

```lua
behavior = {
    default = "idle",           -- fallback action when no drive is urgent
    aggression = 5,             -- 0 = passive, 100 = always attack
    flee_threshold = 30,        -- flee when fear > this value
    wander_chance = 40,         -- 0-100: chance to wander each tick when idle
    settle_chance = 60,         -- 0-100: chance to stop wandering and idle
    territorial = false,        -- does it defend a home room?
    nocturnal = false,          -- more active at night (6 PM - 6 AM)?
    home_room = nil,            -- room ID it considers home (assigned at placement)
},
```

**How the engine uses this:**

1. **Action selection** — Each tick, the engine scores available actions (`idle`, `wander`, `flee`, `hide`, `approach`) using:
   ```
   score = base_utility
         + (hunger_weight × hunger_value)
         + (fear_weight × fear_value)
         + random_jitter(-5, +5)
   ```
   The action with the highest score is executed.

2. **Default behavior** — If no drive is urgent, execute the `default` action (typically `idle`).

3. **Flee threshold** — When `fear_value > flee_threshold`, transition to `alive-flee` state and execute `flee` action.

4. **Wander chance** — Each tick, roll 0-100. If < `wander_chance`, transition from `alive-idle` → `alive-wander`.

---

## Drives System

Drives are internal values (0-100) that bias behavior selection. They decay/grow each turn and spike in response to stimuli.

### Standard Drives

| Drive | Range | Effect on Behavior | Decay Rate |
|-------|-------|-------------------|-----------|
| `hunger` | 0-100 | High hunger → seek food, risk exposure | +2/tick (grows) |
| `fear` | 0-100 | High fear → flee, hide | -5/tick (decays) |
| `curiosity` | 0-100 | Explore new things, investigate | Configurable |

### Drive Definition

```lua
drives = {
    hunger = {
        value = 50,             -- current value (0-100)
        decay_rate = 2,         -- +2 per tick (decay = growth)
        max = 100,              -- cap at 100
        satisfy_action = "eat", -- action that resets this drive
    },
    fear = {
        value = 0,
        decay_rate = -5,        -- -5 per tick (natural decay)
        min = 0,                -- floor at 0
    },
},
```

**Reactions spike drives:**

```lua
reactions = {
    player_enters = {
        fear_delta = 40,        -- add 40 to fear drive
        hunger_delta = -10,     -- subtract 10 from hunger (distraction)
    },
    player_attacks = {
        fear_delta = 80,        -- spike fear sharply
    },
},
```

---

## Reactions System

Reactions map stimuli (events) to responses (drive deltas + actions). They are metadata tables, not code.

### Standard Reactions

| Stimulus | When Fired | Example Reaction |
|----------|-----------|------------------|
| `player_enters` | Player moves into creature's room | Fear +40 |
| `player_leaves` | Player leaves creature's room | Fear -20 |
| `player_attacks` | Player uses attack verb on creature | Fear +80, action = `flee` |
| `loud_noise` | Object breaks, door slams, etc. | Fear +30 |
| `light_change` | Candle lit/extinguished | (Nocturnal creatures respond) |
| `creature_enters` | Another creature enters room | Configurable (territorial?) |
| `food_available` | Food placed in room | Hunger -30 |

### Reaction Definition

```lua
reactions = {
    player_enters = {
        action = "evaluate",        -- re-evaluate behavior
        fear_delta = 40,            -- add 40 to fear
        message = "The rat freezes, beady eyes fixed on you.",
        delay = 0,                  -- react immediately
    },
    player_attacks = {
        action = "flee",            -- execute flee action
        fear_delta = 80,
        message = "The rat squeals and bolts!",
        delay = 0,
    },
},
```

---

## Movement Rules

The `movement` table defines how creatures traverse the world.

```lua
movement = {
    speed = 1,                  -- rooms per tick (1 = move 1 room per turn)
    can_open_doors = false,     -- can it open closed doors?
    can_climb = false,          -- can it climb obstacles?
    size_limit = "small",       -- can squeeze through exits of this size+
},
```

**Speed mechanics:**
- `speed = 0` — creature cannot move (rooted)
- `speed = 1` — can move to 1 adjacent room per tick
- `speed = 2` — can move up to 2 adjacent rooms per tick

**Exit traversal:**
- Creature can only take exits matching `size_limit` (e.g., a rat cannot climb a rope exit it's not sized for)
- If `can_open_doors = false`, closed doors block the creature

---

## Awareness System

The `awareness` table defines what creatures can perceive.

```lua
awareness = {
    sight_range = 1,            -- rooms away to detect player visually
    sound_range = 2,            -- rooms away to hear player
    smell_range = 1,            -- rooms away to smell player/food
},
```

**Perception mechanics:**
- **Same room:** Full perception — creature sees, hears, smells the player immediately
- **Adjacent room (1 exit):** Full sensory range activates if `<range> >= 1`
- **Distant (2+ exits):** Tick fidelity reduced (see Tick System documentation)

Example:
- Rat with `sight_range = 1, sound_range = 2` can:
  - See player if in same room or adjacent
  - Hear player up to 2 rooms away
  - Smell player if in same room or adjacent

---

## Health & Mortality

Creatures track health and can die.

```lua
health = 10,                    -- current health
max_health = 10,                -- maximum health (for scaling damage)
alive = true,                   -- explicit alive flag (optional, derived from health)
```

**Death mechanics:**
- When `health <= 0`, FSM transitions to `dead` state
- Dead creatures are removed from creature tick (animate = false)
- Dead creatures are pickupable if `size <= "small"`
- Dead creatures show death sensory descriptions (`on_feel`, `on_smell`, etc.)

---

## Sensory Properties

Every creature MUST have sensory descriptions. These are the primary way players interact with creatures in darkness.

```lua
on_feel = "Coarse, greasy fur over a warm, squirming body. A thick tail whips against your fingers.",
on_smell = "Musty rodent — damp fur, old nesting material.",
on_listen = "Skittering claws on stone. An occasional high-pitched squeak.",
on_taste = "You'd have to catch it first. And then you'd regret it.",
```

**Rules:**
- `on_feel` is mandatory — primary sense when light = 0
- `on_smell` is mandatory — always safe to perceive
- `on_listen` is mandatory — reveals mechanical/behavioral state
- `on_taste` is optional but recommended for flavor
- Sensory descriptions can be overridden per FSM state (e.g., dead creatures sound/smell different)

---

## Example: Rat Creature

A minimal but complete rat definition:

```lua
return {
    guid = "{new-guid}",
    template = "creature",
    id = "rat",
    name = "a brown rat",
    keywords = {"rat", "rodent", "vermin"},
    description = "A plump brown rat with matted fur and a long, naked tail.",

    -- Object properties
    size = "tiny",
    weight = 0.3,
    portable = false,
    material = "flesh",

    -- Creature extension
    animate = true,

    -- Sensory (all mandatory)
    on_feel = "Coarse, greasy fur over a warm, squirming body.",
    on_smell = "Musty rodent — damp fur and old nesting material.",
    on_listen = "Skittering claws on stone.",
    on_taste = "You'd regret it.",

    -- FSM
    initial_state = "alive-idle",
    _state = "alive-idle",
    states = {
        ["alive-idle"] = {
            description = "A brown rat sits hunched near the baseboard, grooming itself.",
            room_presence = "A rat crouches in the shadows near the wall.",
        },
        ["alive-wander"] = {
            description = "A brown rat scurries across the floor, nose working furiously.",
            room_presence = "A rat scurries along the baseboard.",
        },
        ["alive-flee"] = {
            description = "The rat is a blur of brown fur, darting frantically.",
            room_presence = "A panicked rat zigzags across the floor.",
        },
        dead = {
            description = "A dead rat lies on its side, legs splayed.",
            room_presence = "A dead rat lies crumpled on the floor.",
            animate = false,
            portable = true,
            on_feel = "Cooling fur over a limp body.",
            on_smell = "Blood and musk.",
        },
    },
    transitions = {
        { from = "alive-idle",   to = "alive-wander", verb = "_tick", condition = "wander_roll" },
        { from = "alive-wander", to = "alive-idle",   verb = "_tick", condition = "settle_roll" },
        { from = "alive-idle",   to = "alive-flee",   verb = "_tick", condition = "fear_high" },
        { from = "*",            to = "dead",         verb = "_damage", condition = "health_zero" },
    },

    -- Behavior
    behavior = {
        default = "idle",
        aggression = 5,
        flee_threshold = 30,
        wander_chance = 40,
        settle_chance = 60,
        territorial = false,
        nocturnal = true,
    },

    -- Drives
    drives = {
        hunger = { value = 50, decay_rate = 2 },
        fear = { value = 0, decay_rate = -5 },
    },

    -- Reactions
    reactions = {
        player_enters = {
            action = "evaluate",
            fear_delta = 40,
            message = "The rat freezes, beady eyes fixed on you.",
        },
        player_attacks = {
            action = "flee",
            fear_delta = 80,
            message = "The rat squeals and bolts!",
        },
    },

    -- Movement
    movement = {
        speed = 1,
        can_open_doors = false,
        can_climb = false,
    },

    -- Awareness
    awareness = {
        sight_range = 1,
        sound_range = 2,
        smell_range = 1,
    },

    -- Health
    health = 10,
    max_health = 10,
}
```

---

## See Also

- **Principle 0a:** `.squad/decisions.md` (Animate Extension)
- **NPC System Design:** `docs/design/npc-system.md` (player-facing reference)
- **FSM Lifecycle:** `docs/architecture/engine/fsm-object-lifecycle.md`
- **Instance Model:** `docs/architecture/objects/instance-model.md` (inheritance)
- **Core Principles:** `docs/architecture/objects/core-principles.md` (Principles 0, 8)
