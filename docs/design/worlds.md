# Worlds System Design

**Version:** 1.0  
**Last Updated:** 2026-08-21  
**Author:** Comic Book Guy (Game Designer)  
**Audience:** Design team, engineers, content creators  
**Related Decision:** `D-WORLDS-CONCEPT`

---

## Executive Summary

The **Worlds system** introduces a new meta hierarchy above Levels. Instead of a single linear progression, the game organizes content as:

```
World → Level → Room → Object
```

A World is a **thematic envelope** containing multiple Levels. It defines the aesthetic, mood, and design constraints that guide all contained content. Examples: "The Manor" (gothic medieval horror), "The Swamp" (post-apocalyptic decay), "The Palace" (courtly intrigue).

The engine boots into a single World, then lazy-loads Levels on demand. World .lua files are small metadata documents; the heavy work (object/room loading) happens at Level granularity.

---

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Hierarchy & Loading Model](#hierarchy--loading-model)
3. [World Format Specification](#world-format-specification)
4. [Theme System](#theme-system)
5. [The Manor — World 1](#the-manor--world-1)
6. [Engine Integration Points](#engine-integration-points)
7. [Future Multi-World Vision](#future-multi-world-vision)
8. [File Locations & Templates](#file-locations--templates)

---

## Design Philosophy

### Why Worlds?

**Single-level games are inherently limited.** As the game grows beyond Level 1, we need a way to:

1. **Organize large amounts of content** without a flat list of 50+ level files
2. **Group thematically related content** (e.g., all manor levels vs. all swamp levels)
3. **Enforce visual/mechanical consistency** across multiple levels (gothic styling, no magic, etc.)
4. **Signal progression to the player** ("You leave the Manor and enter the Swamp")
5. **Enable parallel content tracks** (e.g., "The Palace" pathway for speedrunners, "The Crypt" pathway for dark-mode players)

### The Distinction: World vs. Level

| Aspect | World | Level |
|--------|-------|-------|
| **Scope** | 1–5 related levels (typically) | 1 playable scenario (~20–30 rooms) |
| **Duration** | 2–4 hours of gameplay | 30–60 minutes |
| **Customization** | Theme, progression rules, aesthetic | Start room, rooms, completion criteria |
| **Persistence** | One World per game instance | Can re-enter Levels (optional) |
| **Example** | "The Manor" (Levels 1–3) | "The Bedroom" (Level 1) |

### Theme as Design Guidance

A World's **theme** is NOT shown to the player—it's internal guidance for designers. The theme ensures consistency:

- **Color palette:** Wood, stone, tallow, wool (no neon, no plastic)
- **Technology level:** Medieval domestic horror (no electricity, no internal combustion)
- **Mood:** Claustrophobic, paranoid, vulnerable
- **Forbidden materials:** Glass, steel, concrete (anachronistic or too modern)
- **Sound design:** Creaking wood, howling wind, silence (no modern ambient, no synthesizers)

Each object/puzzle/room must answer: **"Does this fit the World's theme?"** If not, it belongs in a different world.

---

## Hierarchy & Loading Model

### Boot Sequence

```
Game Start
  → Engine selects World (auto-boot for single world)
  → Load World .lua file (small, ~500 bytes)
  → Load Level 1 (lazy)
    → Load Level 1 Rooms (lazy)
      → Load Room objects (lazy)
  → Boot player in World.starting_room
```

### Lazy Loading

- **World files** are loaded at game boot (always in memory)
- **Level files** are loaded on demand (when player crosses boundary)
- **Room files** are loaded on demand (when player navigates to room)
- **Theme files** (optional subsections) are loaded on demand (never at runtime in V1; for designer reference only)

This keeps memory footprint small and startup fast.

### World Entry / Level Transitions

```lua
-- Player starts the game
world_1.starting_room = "start-room"  -- Defined in World

-- After completing Level 1
level_1.boundaries.exit[1].target_level = 2
-- Engine loads level-02.lua and its starting room
```

---

## World Format Specification

Every World is a Lua table returned from `src/meta/worlds/world-NN.lua`:

```lua
return {
    -- Metadata
    guid = "{windows-guid}",                    -- Unique identifier
    template = "world",                        -- Must be "world"
    id = "world-1",                            -- Unique slug
    name = "The Manor",                        -- Player-facing title
    description = "A gothic estate of stone and shadow.",

    -- Entry point when game boots
    starting_room = "start-room",              -- Room ID, must exist in level_1

    -- Ordered list of levels in this world
    levels = {
        1,                                     -- Load level-01.lua
        2,                                     -- Load level-02.lua
        3,                                     -- Load level-03.lua
    },

    -- Theme: internal design guidance (never player-facing)
    theme = {
        pitch = "Gothic domestic horror. Late medieval manor, 1450s-style.",
        era = "Medieval (1400–1500)",
        
        aesthetic = {
            -- Primary materials
            materials = {"stone", "iron", "wood", "tallow", "wool", "leather", "glass", "rope"},
            -- Forbidden materials (anachronistic)
            forbidden = {"steel", "concrete", "plastic", "neon", "electrical"},
            -- Color palette (warm, dark, muted)
            colors = {"ochre", "grey", "brown", "black", "cream", "rust"},
        },
        
        atmosphere = "Claustrophobic. Player is trapped and must find a way out. "
                   .. "Light is scarce; darkness is default. Sounds are organic—"
                   .. "creaking wood, howling wind, animal calls, silence.",
        
        mood = "Paranoid. Vulnerable. Every shadow could hide danger. "
             .. "The manor is not hostile—it's indifferent, and that's worse.",
        
        tone = "Serious. Dark humor is rare. Moments of beauty amid decay.",
        
        -- Designer constraints (not enforced by engine, advisory only)
        constraints = {
            "No magic. All puzzles use real-world physics.",
            "No NPCs with dialogue (Phase 5+).",
            "No projectile weapons (melee only).",
            "No modern technology (electricity, firearms, etc.).",
            "Scarcity of light is the core mechanic.",
        },

        -- Designer notes (not used by engine)
        design_notes = "The Manor is a trap. The player wakes imprisoned. "
                     .. "Escaping teaches the game's core systems: darkness navigation, "
                     .. "tool usage, resource scarcity, FSM states.",
    },

    -- Optional: theme subsections (lazy-loaded for designer reference)
    -- theme_files = {
    --     sound_design = "docs/design/worlds/themes/manor/sound.md",
    --     room_patterns = "docs/design/worlds/themes/manor/room-patterns.md",
    -- },

    -- Progression rules (future expansion)
    -- progression = {
    --     can_respawn_at_level_start = false,
    --     permadeath = true,
    -- },

    -- Optional: mutations (future expansion)
    mutations = {},
}
```

### World Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `guid` | string | ✅ | Windows GUID format, unique across all worlds |
| `template` | string | ✅ | Must be `"world"` |
| `id` | string | ✅ | Unique slug; used in file paths: `world-{id}.lua` |
| `name` | string | ✅ | Player-facing title (e.g., "The Manor") |
| `description` | string | ✅ | Short flavor text for World selection menu (future) |
| `starting_room` | string | ✅ | Room ID where player boots into the world; must exist in Level 1 |
| `levels` | array | ✅ | Ordered list of level numbers (e.g., `{1, 2, 3}`) |
| `theme` | table | ✅ | Theme metadata (aesthetic, atmosphere, mood, constraints) |
| `theme_files` | table | ❌ | Optional subsection file paths (for designer reference only) |
| `progression` | table | ❌ | Optional progression rules (future expansion) |
| `mutations` | table | ❌ | Optional mutation definitions (future expansion) |

---

## Theme System

### Structure

The **theme** table guides designer decisions. It's NEVER enforced by the engine—it's aspirational.

```lua
theme = {
    pitch = "One-liner summary of the world's concept",
    era = "Historical/fantasy era (e.g., 'Medieval 1450s')",
    
    aesthetic = {
        materials = {...},         -- Materials ALLOWED in this world
        forbidden = {...},         -- Materials NOT ALLOWED (anachronistic)
        colors = {...},            -- Color palette
    },
    
    atmosphere = "Multi-sentence description of ambiance",
    mood = "Emotional tone (paranoid, melancholic, etc.)",
    tone = "Narrative voice (serious, comedic, etc.)",
    
    constraints = {
        "Design rule 1",
        "Design rule 2",
        ...
    },
    
    design_notes = "Designer commentary and vision",
}
```

### Examples

**The Manor (World 1 — Gothic Horror)**

```lua
theme = {
    pitch = "Late medieval manor, 1450s. Player trapped, must escape.",
    era = "Medieval (1400–1500)",
    aesthetic = {
        materials = {"stone", "iron", "wood", "tallow", "wool", "leather", "glass"},
        forbidden = {"steel", "concrete", "plastic", "electrical"},
        colors = {"ochre", "grey", "brown", "black", "cream"},
    },
    atmosphere = "Claustrophobic stone chambers. Scarcity of light. "
               .. "Sounds: creaking wood, wind, animal calls. Mostly silence.",
    mood = "Paranoid. Vulnerable. Every shadow is threat.",
    tone = "Serious. Dark humor is rare.",
    constraints = {
        "No magic.",
        "No NPCs with dialogue.",
        "Melee combat only.",
        "No electrical technology.",
    },
}
```

**The Swamp (World 2 — Post-Apocalyptic, Future)**

```lua
theme = {
    pitch = "Flooded marshland, 200 years post-civilization. "
          .. "Salvage, survival, forgotten technology.",
    era = "Post-Apocalyptic (Year 200 AE)",
    aesthetic = {
        materials = {"wood", "steel", "rubber", "concrete", "glass", "plastic"},
        forbidden = {"gold", "silk", "tallow", "medieval-iron"},
        colors = {"rust", "moss", "grey", "black", "neon-green"},
    },
    atmosphere = "Murky. Wet. Decaying civilization reclaimed by nature. "
               .. "Sounds: water, insects, mechanical groans, rain.",
    mood = "Desperate. Resourceful. Wonder mixed with dread.",
    tone = "Grim with moments of discovery.",
    constraints = {
        "Salvage is currency. Everything has value.",
        "Technology works (but is broken/repurposed).",
        "Magic is forbidden (science only).",
    },
}
```

### Why Theme Matters

- **Consistency:** All content in a World should feel cohesive
- **Onboarding:** New designers read the theme to understand what "belongs"
- **Scope:** Theme defines what is IN scope and what is NOT
- **Fun:** Worlds feel distinct; players recognize transitions

---

## The Manor — World 1

This section documents the FIRST world, shipped with V1.

### Specification

```lua
return {
    guid = "550e8400-e29b-41d4-a716-446655440000",
    template = "world",
    id = "world-1",
    name = "The Manor",
    description = "A gothic manor of stone, iron, and shadow. "
               .. "You wake trapped inside, with no memory of how you arrived.",

    starting_room = "start-room",

    levels = {1, 2, 3},  -- Level 1: Bedroom/Cellars, Level 2: Hallway/Grounds, Level 3: ...

    theme = {
        pitch = "Gothic domestic horror. Late medieval manor, 1450s. "
              .. "Player imprisoned and must escape through progressive revelation "
              .. "of the manor's architecture and secrets.",
        
        era = "Medieval (1400–1500). Late medieval domestic architecture, "
            .. "no anachronisms. Stone keep, iron locks, tallow lights, wool tapestry.",
        
        aesthetic = {
            materials = {
                "stone", "iron", "wood", "tallow", "wool", "leather",
                "glass", "rope", "clay", "brass", "copper", "linen", "straw",
            },
            forbidden = {
                "steel", "concrete", "plastic", "electrical", "neon",
                "polyester", "aluminum", "silicon", "vinyl",
            },
            colors = {
                "ochre", "grey", "brown", "black", "cream", "rust",
                "moss-green", "deep-red", "charcoal",
            },
        },
        
        atmosphere = "Stone chambers, cold and damp. Scarcity of light—a single "
                   .. "tallow candle casts dancing shadows on ancient walls. Sounds "
                   .. "are organic: creaking wood, howling wind, distant animal calls, "
                   .. "mostly silence. The manor feels empty and abandoned, yet somehow "
                   .. "watchful. Time moves slowly. Two hours in the manor feel like an eternity.",
        
        mood = "Claustrophobic. Paranoid. Vulnerable. The player is not hunted—"
             .. "they are lost. Every shadow could hide danger, every corner could "
             .. "lead to escape or deeper entrapment. There is a sense of being "
             .. "observed by something indifferent.",
        
        tone = "Serious and dark. Moments of beauty exist (sunlight through "
             .. "crumbling stone, the smell of tallow), but are fleeting and tinged "
             .. "with dread. Humor is rare and gallows-dark.",
        
        constraints = {
            "No magic. All puzzles solve with real-world physics and tools.",
            "No NPCs with dialogue. Environmental creatures only (V1).",
            "No projectile weapons. Melee tools only (knives, clubs, etc.).",
            "No electrical or mechanical technology. Simple mechanical traps only.",
            "Scarcity of light is the CORE mechanic—plan every room around it.",
            "Water is scarce and precious (no bathing, only drinking/cooking).",
            "Cold is pervasive. No heating except fire.",
            "Animal presence: rats, spiders, occasionally wolves or guards.",
        },
        
        design_notes = "The Manor is a training ground. Level 1 teaches "
                     .. "fundamental systems: navigating darkness, using senses "
                     .. "as primary tools, resource scarcity, FSM state changes, "
                     .. "the parser's 5-tier resolution. Level 2 introduces "
                     .. "more complex environments and the first real combat. "
                     .. "Level 3 deepens the mystery. By the time the player escapes "
                     .. "the Manor, they are competent.",
    },

    mutations = {},
}
```

### Levels in The Manor

| Level | Name | Focus | Rooms |
|-------|------|-------|-------|
| **1** | The Awakening | Bedroom/Cellars | 7 rooms; teaches dark navigation |
| **2** | The Descent | Crypt/Passages | 10+ rooms; introduces combat |
| **3** | The Reckoning | Manor Proper | 15+ rooms; final escape or deeper mystery |

(Levels 2 and 3 are FUTURE work; Level 1 is shipped with V1.)

---

## Engine Integration Points

### 1. Boot Sequence (main.lua)

```lua
-- Before starting game loop
local world = loader.load("src/meta/worlds/world-01.lua")
local level = loader.load("src/meta/levels/level-" .. world.levels[1] .. ".lua")
local start_room_id = world.starting_room
local start_room = loader.load("src/meta/rooms/" .. start_room_id .. ".lua")

-- Player boots into world.starting_room
```

### 2. World Selection (Future)

When multiple worlds exist, the player will select one. For V1 (single world), auto-boot:

```lua
local function boot_world()
    local worlds = registry:find_all_by_template("world")
    if #worlds == 1 then
        return worlds[1]  -- Auto-boot single world
    else
        -- Future: present world menu
    end
end
```

### 3. Level Transitions (loop.lua)

When a player crosses a level boundary:

```lua
local exit_config = room.exits[exit_direction]
if exit_config.target_level then
    local target_level = exit_config.target_level
    local new_level = loader.load("src/meta/levels/level-" .. target_level .. ".lua")
    local new_room = loader.load("src/meta/rooms/" .. new_level.start_room .. ".lua")
    context:set_room(new_room)
    print(new_level.completion[1].message or "You enter a new area.")
end
```

### 4. Theme Enforcement (Optional, Designer-Only)

The engine does NOT validate theme constraints. Designers manually check:

- ✅ "Does this object's material fit the palette?"
- ✅ "Is this object/puzzle appropriate for the era?"
- ✅ "Does this violate the constraints?"

Linting tools could future-add these checks.

---

## Future Multi-World Vision

### V2+: Parallel Worlds

Once Level 1 is solid, the game can introduce **parallel worlds**:

- **The Swamp** (200 years post-civilization, salvage-focused)
- **The Palace** (courtly intrigue, politics, NPCs)
- **The Crypt** (dark mode, permadeath, high difficulty)
- **The Archive** (puzzle-only mode, no combat)

Players could choose a world at startup or unlock new worlds via achievements.

### World Linking (Rifts)

Worlds could **merge** for multiplayer moments (D-MULTIVERSE concept):

```lua
-- Rift between Manor and Swamp opens at Level 3 boss
-- Player can call another player's avatar to fight together
-- Then return to solo play
```

This is future architecture; V1 is single-player, single-world.

---

## File Locations & Templates

### Directory Structure

```
src/meta/
├── worlds/
│   ├── world-01.lua          # The Manor (shipped V1)
│   ├── world-02.lua          # The Swamp (future)
│   ├── themes/
│   │   ├── manor/
│   │   │   ├── sound.md      # Sound design notes
│   │   │   └── room-patterns.md
│   │   └── swamp/
│   │       └── sound.md
│   ├── levels/
│   │   ├── level-01.lua      # Level 1 metadata
│   │   ├── level-02.lua
│   │   └── ...
│   ├── rooms/
│   │   ├── start-room.lua
│   │   ├── cellar.lua
│   │   └── ...
│   └── objects/
│       ├── candle.lua
│       └── ...
└── templates/
    ├── world.lua             # NEW: World template
    ├── level.lua             # Existing
    ├── room.lua              # Existing
    └── ...
```

### World Template (src/meta/templates/world.lua)

```lua
return {
    guid = "{guid}",
    template = "world",
    id = "world",
    name = "A World",
    description = "",
    starting_room = "start-room",
    levels = {},
    theme = {
        pitch = "",
        era = "",
        aesthetic = { materials = {}, forbidden = {}, colors = {} },
        atmosphere = "",
        mood = "",
        tone = "",
        constraints = {},
        design_notes = "",
    },
    mutations = {},
}
```

---

## Design Principles (Recap)

These principles guide all World design decisions:

1. **Worlds are thematic envelopes**, not gameplay containers
2. **One World per game instance** (V1); multi-world is future
3. **Auto-boot single world** (no menu for V1)
4. **Theme is aspirational guidance**, not enforced by engine
5. **Lazy loading keeps memory small** (World → Level → Room on demand)
6. **Levels define content**, Worlds define aesthetic
7. **Future: Rifts and world-linking** (multiplayer moments)

---

## Example: Serialized World Load

```lua
-- 1. Boot game
local world = require("src.meta.worlds.world-01")
registry:register(world)

-- 2. Select first level
local level_number = world.levels[1]
local level = require("src.meta.levels.level-" .. level_number)
registry:register(level)

-- 3. Boot into starting room
local room_id = world.starting_room
local room = require("src.meta.rooms." .. room_id)
registry:register(room)

-- 4. Instantiate room objects
for _, instance_tree in ipairs(room.instances) do
    registry:instantiate_tree(instance_tree)
end

-- 5. Player boots into the room
context:set_current_room(room)
print(room.description)
```

---

## Checklist for New Worlds

When designing a new World, ensure:

- [ ] Unique GUID (no duplicates)
- [ ] Theme table complete (all 8 fields)
- [ ] Constraints reflect your era/aesthetic
- [ ] At least one Level defined
- [ ] Starting room exists in Level 1
- [ ] No anachronisms in theme
- [ ] Theme documented and reviewed by team
- [ ] Objects/puzzles validated against theme
- [ ] Designer notes explain the world's purpose

