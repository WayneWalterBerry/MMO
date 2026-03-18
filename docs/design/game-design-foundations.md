# MMO Text Adventure: Game Design Foundations

**Version:** 1.0  
**Last Updated:** 2026-03-19  
**Author:** Comic Book Guy (Game Designer)  
**Audience:** Design team, engineers, content creators

---

## Executive Summary

This is a **text-based MMO playground** where each player inhabits their own parallel universe. Unlike traditional MMOs, there is no shared lobby—only universes that can optionally merge for co-op moments. The game world is a **self-modifying program**. When a player types `break mirror`, the engine doesn't just flip a Boolean; it rewrites the mirror object's source code to reflect the broken state. This blurs the line between game state and game logic in ways classic IF engines never attempted.

This document establishes the design framework for:
1. **Verb/action resolution** — how players interact
2. **Object taxonomy** — what exists in the world
3. **Room design** — how the world is structured
4. **Player model** — what a player is
5. **Puzzle design** — adventure design in a code-mutating world
6. **Multiverse gameplay** — parallel universes, merges, rift mechanics
7. **Narrative framework** — story, quests, NPCs
8. **Concrete play scenarios** — three walk-throughs showing the system in action

---

## 1. Core Verb/Action System

### Philosophy

Text adventures succeed or fail on **verb repertoire**. Zork has ≈50 verbs. Inform 7 supports 100+. We should start lean but extensible: **15–20 core verbs**, with a framework for custom verbs per puzzle or object.

**Design principle:** Every verb should feel necessary, not make-work. If a verb appears once in the game, it's probably wrong.

### Core Verbs (Phase 1)

| Verb | Synonyms | Effect | Example |
|------|----------|--------|---------|
| **LOOK** | EXAMINE, INSPECT | Describe current room/object in detail | `look` → room description; `look mirror` → mirror details |
| **TAKE** | GET, GRAB, PICK UP | Move object into inventory | `take coin` → coin now in backpack |
| **DROP** | LEAVE, PUT DOWN | Move object from inventory to room | `drop coin` → coin on floor |
| **INVENTORY** | I, INV | List what player carries | `i` → "You carry: backpack, lantern, key" |
| **GO** | MOVE, TRAVEL | Exit room via direction | `go north` or `n` → move to north room |
| **OPEN** | UNLOCK | Access interior of container/door | `open door` → door opens, reveals interior |
| **CLOSE** | LOCK, SHUT | Seal container/door | `close chest` → chest sealed |
| **PUT** | PLACE, INSERT | Put object into container | `put coin in chest` → coin moves to chest.contents |
| **USE** | INTERACT, ACTIVATE | Trigger object function | `use key on door` → engine checks if key fits |
| **TALK** | ASK, SPEAK, CONVERSE | Interact with NPC | `talk to sage` → NPC dialogue tree |
| **GIVE** | HAND, OFFER | Transfer object to NPC | `give bread to dwarf` → NPC receives, may advance quest |
| **READ** | SCAN | Read text on object | `read scroll` → displays inscription |
| **PUSH** | SHOVE, PRESS | Apply force to object/mechanism | `push button` → triggers trap door |
| **PULL** | DRAG, TUG | Draw object toward player | `pull lever` → gate slides open |
| **HELP** | COMMANDS, HINT | Get assistance | `help` → lists verbs or hints |

### Verb Resolution Order

When player types: `put the golden key in the iron chest`

1. **Parse** — tokenize: `[put, the, golden, key, in, the, iron, chest]`
2. **Normalize** — strip articles: `[put, golden, key, iron, chest]`
3. **Resolve objects** — find `golden key` (search inventory first, then room) and `iron chest` (search room)
4. **Check preconditions** — is key in inventory? Is chest open?
5. **Execute verb function** — call `put(key, chest)`
6. **Update state** — move key to `chest.contents`
7. **Trigger side effects** — if chest has `on_item_added` hook, execute it
8. **Describe** — print "You place the golden key in the iron chest."

### Custom Verbs & Puzzle-Specific Verbs

**Example: Mirror puzzle**

```lua
mirror.verbs.break = function(player)
  if mirror.is_broken then
    return "The mirror is already broken."
  end
  mirror.is_broken = true
  mirror.description = "A shattered mirror, fragments glinting dangerously."
  mirror.on_look = function() return mirror.description end
  player:receive("The mirror shatters with a terrible crash!")
  return "Mirror broken. You can now pass through to the other side."
end
```

When player types `break mirror`, the engine:
1. Finds `mirror` object in current room
2. Checks if `mirror.verbs.break` exists
3. Executes the function, which **mutates the mirror's source code**
4. Returns success message

This is the heart of the design: **no state-flag toggles**. The code literally changes.

### Verb Synonyms & Natural Language

```lua
-- Engine maintains synonym map
verbs.synonyms = {
  take = {"get", "grab", "pick up", "obtain"},
  drop = {"leave", "put down"},
  go = {"move", "travel", "walk"},
  examine = {"look", "inspect", "check"},
}

-- Parser recognizes all variants
function parse_verb(token)
  if verbs[token] then return token end
  for verb, synonyms in pairs(verbs.synonyms) do
    if table.contains(synonyms, token) then return verb end
  end
  return nil  -- unknown verb
end
```

---

## 2. Object Taxonomy

### Fundamental Object Types

Everything in the world is an object. All objects inherit from a base **Entity** type with these properties:

```lua
Entity = {
  id = "unique-identifier",
  name = "Human-readable name",
  description = "Detailed description",
  location = nil,  -- parent (room or container)
  contents = {},   -- children (if container)
  properties = {}, -- arbitrary key-value pairs
  verbs = {},      -- custom verb functions
  on_look = function() end,     -- hook called on LOOK
  on_take = function() end,     -- hook called on TAKE
  on_drop = function() end,
  on_enter = function() end,    -- for rooms/containers
  on_exit = function() end,
  on_item_added = function() end,   -- when item placed in container
  on_item_removed = function() end,
}
```

### Concrete Object Types

#### **Room**
Container for objects and exits. Rooms never have a `.location` (they are top-level). 
```lua
Room = {
  id = "dungeon-chamber",
  name = "Dungeon Chamber",
  description = "A vast underground cavern...",
  exits = {
    north = "hallway",     -- direction → room ID
    south = "treasury",
    up = "balcony"
  },
  contents = {},  -- items, NPCs, doors in this room
  atmosphere = "dark",  -- mood/flavor (used by LLM for descriptions)
}
```

#### **Item**
Generic object—sword, coin, key, scroll. Can be taken and placed in containers.
```lua
Item = {
  id = "iron-sword",
  name = "Iron Sword",
  weight = 2.5,
  can_be_taken = true,
  damage = 10,  -- game-specific property
  on_take = function(player) 
    player:receive("The sword hums in your hand.")
  end,
}
```

#### **Container**
Holds other objects. Can be opened/closed, locked/unlocked. Examples: chest, backpack, bag, cabinet.
```lua
Container = {
  id = "treasure-chest",
  name = "Treasure Chest",
  contents = {},  -- items inside
  is_open = false,
  is_locked = false,
  capacity = 100,  -- weight limit (sum of contents.weight)
  on_open = function()
    return "You pry open the chest. Inside you see golden coins."
  end,
}
```

#### **Door** (Exit Conditional)
Doors bridge rooms. They can be locked, require keys, or have custom conditions.
```lua
Door = {
  id = "iron-gate",
  name = "Iron Gate",
  from_room = "dungeon-chamber",
  to_room = "throne-room",
  direction = "north",
  is_open = false,
  is_locked = true,
  required_key = "iron-key",  -- item.id that unlocks it
  on_open = function(player, key)
    if not key or key.id ~= "iron-key" then
      return "The gate is locked. You need a key."
    end
    -- Player has correct key; open it
    door.is_open = true
    return "The gate swings open."
  end,
}
```

#### **Actor** (NPC / Player)
Agents with agency—can move, talk, perform actions. NPCs are stateful—they remember conversations, quests, mood.
```lua
Actor = {
  id = "sage-aldor",
  name = "Sage Aldor",
  description = "A wise old man with silver hair.",
  is_player = false,
  inventory = {},
  stats = {hp = 100, mana = 50},
  mood = "thoughtful",
  quests = {},  -- active quests involving this NPC
  on_talk = function(player, topic)
    if topic == "sword" then
      return "Ah, the sword... a dangerous artifact. Beware."
    end
  end,
  on_give = function(player, item)
    if item.id == "ancient-tome" then
      actor.quests["tome-delivered"] = true
      return "Thank you! At last I can read this..."
    end
  end,
}
```

#### **Player**
Special Actor. Represents the human.
```lua
Player = {
  id = player_id,
  name = "Your Name",  -- set at game start
  is_player = true,
  location = "starting-room",
  inventory = {},
  stats = {
    hp = 100,
    mana = 50,
    xp = 0,
    level = 1,
  },
  universe_id = "unique-universe-uuid",  -- which parallel world this player inhabits
  session_id = "session-uuid",
  progress = {
    quests_completed = {},
    items_found = {},
    rooms_visited = {},
  },
}
```

### Containment Rules & Constraints

1. **Circular containment prevention:** An object cannot contain itself, even indirectly.
   ```lua
   function can_place(item, container)
     -- Prevent: chest in chest in chest (infinite loop)
     local current = container
     while current.location do
       if current.location.id == item.id then
         return false  -- would create cycle
       end
       current = current.location
     end
     return true
   end
   ```

2. **Weight limits:** Containers and player inventory have maximum weight.
   ```lua
   function can_take(item, player)
     local current_weight = sum(player.inventory, "weight")
     local new_weight = current_weight + item.weight
     if new_weight > player.inventory.capacity then
       return false, "Too heavy to carry."
     end
     return true
   end
   ```

3. **Takeable items:** Some objects have `can_be_taken = false` (e.g., wall, statue, NPC).
   ```lua
   function take(item, player)
     if not item.can_be_taken then
       return "You cannot take that."
     end
     -- continue...
   end
   ```

4. **Container access:** Objects in a closed container are hidden; you cannot TAKE from a closed chest.
   ```lua
   function search_for_item(item_name, player)
     -- Search inventory
     for item in player.inventory do
       if item.name:lower() == item_name:lower() then
         return item
       end
     end
     -- Search current room
     local room = world:get_room(player.location)
     for obj in room.contents do
       if obj.name:lower() == item_name:lower() then
         return obj
       end
       -- If obj is a container and open, search its contents
       if obj.is_container and obj.is_open then
         for inner_item in obj.contents do
           if inner_item.name:lower() == item_name:lower() then
             return inner_item
           end
         end
       end
     end
     return nil
   end
   ```

---

## 3. Room & World Design

### Room Structure

```lua
Room = {
  id = "chamber-of-echoes",
  name = "Chamber of Echoes",
  description = "A cavernous space. Your footsteps echo off stone walls.",
  atmosphere = "mysterious",  -- LLM uses this to flavor descriptions
  
  -- Exits: map direction to room ID
  exits = {
    north = "throne-room",
    east = "library",
    down = "crypt",
    ["west/through-gate"] = "garden",  -- compound direction
  },
  
  -- Objects in this room
  contents = {
    "torch",  -- Item IDs
    "ancient-pedestal",
    "wise-sage",  -- NPC Actor ID
  },
  
  -- Events / triggers
  on_enter = function(player)
    -- Called when player enters this room
    player:receive("As you step in, torches flicker to life.")
  end,
  
  on_exit = function(player, direction)
    -- Called when player leaves
  end,
  
  on_turn = function()
    -- Called each game turn (optional)
  end,
  
  -- Atmospheric details
  sounds = "distant dripping water",
  smells = "damp stone and decay",
  
  -- Puzzle-specific data
  is_dark = true,
  requires_light = true,  -- player needs lantern to navigate
}
```

### Room Types

1. **Hub Rooms** — Starting points, safe zones, commerce areas
   - Example: Tavern, Town Square, Sanctuary
   - Properties: `is_hub = true`, `is_safe_zone = true`
   - No hostile NPCs; common meeting grounds

2. **Dungeon/Perilous Rooms** — Combat zones, trap rooms, puzzles
   - Example: Dragon's Lair, Spike Pit, Wizard's Tower
   - Properties: `danger_level = "extreme"`, `is_hostile = true`
   - May contain traps, hostile NPCs, or scarce resources

3. **Exploration Rooms** — Mystery, discovery, secrets
   - Example: Lost Library, Abandoned Mine, Enchanted Grove
   - Properties: `has_secrets = true`, `is_explorable = true`
   - Reward curious players; may contain lore, treasure, or knowledge

4. **Quest Rooms** — Specifically for quest objectives
   - Example: Blacksmith's Forge (repair sword quest), Oracle's Chamber (prophecy quest)
   - Tied to specific NPCs or plot points
   - May be inaccessible until quest requirements are met

### Exit Types

```lua
-- Standard exit
exits.north = "next-room-id"

-- Conditional exit (locked door)
exits.east = Door {
  id = "gate",
  to_room = "forbidden-chamber",
  is_locked = true,
  required_key = "iron-key",
}

-- Conditional exit (requires item or property)
exits.down = ConditionalExit {
  to_room = "treasure-vault",
  requires = {item = "rope", property = "has_climbed_before"},
  on_attempt = function(player)
    if not player:has_item("rope") then
      return "You'd need a rope to descend safely."
    end
  end,
}

-- Hidden exit (only visible if condition met)
exits["secret-passage"] = HiddenExit {
  to_room = "secret-treasury",
  revealed_by = "ancient-map",  -- must have examined this item
}
```

### Environmental Effects & Room Events

```lua
Room {
  id = "storm-chamber",
  on_turn = function()
    -- Each turn, random weather effect
    if math.random() > 0.7 then
      world:broadcast_to_room(
        "The wind howls. You struggle to stay upright."
      )
      -- Possible mechanic: player must pass strength check
    end
  end,
}

Room {
  id = "cursed-hall",
  on_enter = function(player)
    player.stats.hp = player.stats.hp - 10
    player:receive("A dark presence drains your life force!")
  end,
}

Room {
  id = "healing-sanctuary",
  on_turn = function()
    for actor in world:actors_in_room("healing-sanctuary") do
      if actor.is_player then
        actor.stats.hp = math.min(actor.stats.hp + 5, actor.stats.max_hp)
      end
    end
  end,
}
```

---

## 4. Player Model

### What IS a Player?

A **Player** is a special **Actor** that represents a human. It has:
- **Persistent identity** across sessions
- **A parallel universe** (multiverse model)
- **Inventory & stats** (resources, progression)
- **Agency** (makes decisions; NPCs don't control them)
- **Session lifecycle** (login/logout)

### Player State

```lua
Player = {
  -- Identity
  id = "player-uuid",
  name = "Kayla the Bold",
  
  -- Current game state
  location = "tavern-common-room",
  inventory = {},
  stats = {
    hp = 100,
    max_hp = 100,
    mana = 50,
    max_mana = 50,
    xp = 0,
    level = 1,
  },
  
  -- Universe assignment
  universe_id = "universe-uuid-12345",  -- each player gets own parallel world
  
  -- Session tracking
  session_id = "session-uuid",
  login_time = 1234567890,
  last_action_time = 1234567891,
  
  -- Progression
  quests_active = {},
  quests_completed = {},
  items_discovered = {},
  rooms_visited = {
    "tavern-common-room": true,
  },
  achievements = {},
  
  -- Playable stats (could drive progression)
  playstyle = "explorer",  -- explorer, fighter, puzzle-solver, socialite
  death_count = 0,
  longest_session = 3600,  -- seconds
}
```

### Inventory Model

Players carry items in a **backpack** (default container):

```lua
player.inventory = Container {
  id = "backpack-" .. player.id,
  name = "Backpack",
  contents = {
    Item {id = "iron-key", name = "Iron Key", weight = 0.5},
    Item {id = "bread", name = "Loaf of Bread", weight = 0.3},
  },
  capacity = 50,  -- max weight in kg
}

-- INVENTORY command lists contents
function cmd_inventory(player)
  local weight = sum(player.inventory.contents, "weight")
  local capacity = player.inventory.capacity
  print(string.format("Backpack (%d/%d kg):", weight, capacity))
  for item in player.inventory.contents do
    print(string.format("  - %s", item.name))
  end
end
```

### Death & Resurrection

**Option 1: Permadeath (hardcore)**
```lua
if player.stats.hp <= 0 then
  player.is_dead = true
  world:remove_player(player.id)
  player:disconnect("You have perished.")
end
```

**Option 2: Resurrection/Respawn (narrative)**
```lua
if player.stats.hp <= 0 then
  player.location = "sanctuary-temple"  -- respawn location
  player.stats.hp = player.stats.max_hp / 2  -- half health
  player.stats.mana = player.stats.max_mana / 2
  player.death_count = player.death_count + 1
  player:receive("You awaken in the sanctuary, alive but weakened.")
end
```

**Design note:** For MMO, permadeath is brutal. Recommendation: Respawn in neutral hub with XP/item penalty.

### Session Persistence

```lua
-- On login:
function player_login(player_id)
  local player = database:load_player(player_id)
  if not player then
    return "Player not found"
  end
  local universe = database:load_universe(player.universe_id)
  world:add_player(player)
  player:receive("Welcome back to " .. universe.name)
end

-- On logout (auto-save):
function player_logout(player_id)
  local player = world:get_player(player_id)
  database:save_player(player)
  database:save_universe(player.universe_id)
  world:remove_player(player_id)
end

-- Periodic auto-save (every 5 minutes or every 20 actions):
function auto_save_check()
  for player in world:active_players() do
    if player.last_action_time < now() - 300 then  -- 5 min
      database:save_player(player)
    end
  end
end
```

---

## 5. Puzzle Design Patterns

### Classic Text Adventure Puzzle Types

#### **Type 1: The Locked Door**
Player must find a key or solve a condition to unlock passage.

**Classic:** Zork's East/West doors (requires matching key)  
**Twist:** In a code-mutating world, finding the key also changes its shape.

```lua
-- Initial state
Door {
  id = "vault-door",
  to_room = "treasury",
  is_locked = true,
  required_key = "brass-key",
  on_open = function(player, key)
    if not player:has_item("brass-key") then
      return "The door is locked."
    end
    -- Unlock: engine mutates door code
    vault_door.is_locked = false
    vault_door.description = "A heavy door, now hanging open."
    return "The lock clicks. The door swings open."
  end,
}

-- Later: if player curses the key, the door's code changes:
brass_key.is_cursed = true
vault_door.required_key = nil  -- curse breaks the lock mechanism
vault_door.is_locked = false   -- now open, but unpredictable
vault_door.on_open = function(player)
  if math.random() > 0.5 then
    return "The door slams shut! Something is wrong."
  end
end
```

**Player path:**
1. `go east` → "The door is locked."
2. `look around` → finds clue about key
3. Search rooms → finds `brass-key`
4. `use brass-key on door` → door opens
5. **Later:** If player curses key, door behavior changes

#### **Type 2: The Riddle**
NPC asks a riddle; correct answer unlocks knowledge or passage.

```lua
Riddle {
  id = "sphinx-riddle",
  question = "What has cities but no houses, forests but no trees, water but no fish?",
  correct_answer = "map",
  on_correct = function(player)
    player:receive("Correct! The sphinx bows respectfully.")
    sphinx.mood = "impressed"
    sphinx.on_talk = function() return "You are wise. I will aid you." end
    return true
  end,
  on_incorrect = function(player)
    player:receive("Wrong! The sphinx snarls and attacks!")
    sphinx:attack(player)
  end,
}
```

**Design in code-mutation:** Solving the riddle changes the NPC's code—their dialogue branches, their willingness to help.

#### **Type 3: The Inventory Puzzle**
Player must gather specific items and use them in sequence. Classic: monkey/coconut/rope puzzle.

```lua
Quest {
  id = "raise-ship",
  steps = {
    {
      requires_items = {"rope"},
      action = "tie rope to ship",
      result = "Ship is now anchored",
    },
    {
      requires_items = {"pulley", "rope"},
      action = "attach pulley to mast",
      result = "Pulley is ready",
    },
    {
      requires_items = {"chain"},
      action = "attach chain to pulley",
      result = "The ship rises from the depths!",
    },
  },
}
```

#### **Type 4: The Environment Puzzle**
Player manipulates the room to change its state. Example: draining a flooded room by finding the plug.

```lua
Room {
  id = "flooded-cavern",
  is_flooded = true,
  description = "Water fills the cavern to chest height.",
  contents = {"drain-plug"},  -- hidden object that can be found
  
  on_enter = function(player)
    if flooded_cavern.is_flooded then
      player:receive("Water sloshes around you. You can't see the floor.")
    end
  end,
}

Item {
  id = "drain-plug",
  name = "A plug (in the floor)",
  on_take = function(player)
    flooded_cavern.is_flooded = false
    flooded_cavern.description = "The cavern is now dry. You see an entrance below."
    flooded_cavern.contents:remove("drain-plug")
    flooded_cavern:broadcast("The water drains away!")
  end,
}
```

#### **Type 5: The Logic Puzzle**
Player must deduce connections and apply rules. Example: Minesweeper, Nonogram, or Mastermind.

```lua
Puzzle {
  id = "combination-lock",
  description = "A lock with three rotating dials: red, green, blue",
  correct_combo = {red=3, green=7, blue=2},
  
  verbs.try_combination = function(player, combo)
    if combo.red == puzzle.correct_combo.red and
       combo.green == puzzle.correct_combo.green and
       combo.blue == puzzle.correct_combo.blue then
      -- Success: engine mutates the lock
      combination_lock.is_locked = false
      return "Click! The lock opens."
    else
      return "The lock doesn't budge."
    end
  end,
}

-- Player types: `try combination red=3 green=7 blue=2`
```

#### **Type 6: The Moral/Choice Puzzle**
Player faces a dilemma with no "correct" answer—consequences depend on choice.

```lua
NPC {
  id = "beggar",
  name = "Ragged Beggar",
  
  on_talk = function(player, topic)
    if topic == "help" then
      player:receive("I'm starving. Do you have food?")
      -- Player now must decide: give food or refuse
    end
  end,
}

Item {
  id = "bread",
  verbs.give = function(player, target)
    if target.id == "beggar" then
      beggar.mood = "grateful"
      beggar.on_talk = function() 
        return "Thank you. I'll remember your kindness."
      end
      -- Consequence: Later, beggar helps player escape trap
      player.achievements["compassion"] = true
      return "The beggar thanks you profusely."
    end
  end,
}
```

### Code Mutation in Puzzles

**Critical insight:** Traditional text adventures use state flags. We use code mutation.

```lua
-- Traditional approach (wrong for this design):
mirror.is_broken = true  -- just flip a flag

-- Our approach (code mutation):
mirror.verbs.break = function(player)
  -- This FUNCTION itself is what changes
  mirror.description = "A shattered mirror..."
  mirror.on_look = function() return "Jagged glass reflects..." end
  mirror.on_take = function() return "You cut your hand!" end
  mirror.can_be_taken = false  -- now hazardous
  
  -- Puzzle consequence: the mirror now DOES different things
  -- It's not just a flag; the code that governs it changed
end
```

**Why this matters:**
- **Emergent behavior:** Items can gain entirely new capabilities post-mutation.
- **Debugging:** The code state IS the truth. No hidden flags.
- **Extensibility:** New verbs can be added to objects on the fly.
- **Lore:** A cursed item's code mutates—becomes dangerous or helpful.

---

## 6. Multiverse Gameplay

### Overview

Each player inhabits a **parallel universe**. These universes are normally isolated, but they can **merge** for cooperative play or special events.

### Multiverse Model

```lua
Universe = {
  id = "universe-uuid-player-001",
  owner = "player-001",  -- which player "owns" this universe
  
  -- The universe is a Lua program
  rooms = {
    ["starting-room"] = Room { ... },
    ["library"] = Room { ... },
  },
  items = {
    ["iron-key"] = Item { ... },
  },
  actors = {
    ["sage-aldor"] = NPC { ... },
  },
  
  -- Timeline / versioning
  created_at = 1234567890,
  version = 42,  -- incremented after each mutation
  mutations_log = {
    {timestamp=..., actor_id=..., change="mirror.is_broken=true"},
  },
  
  -- Merge state (if merged with another universe)
  is_merged = false,
  merged_with = nil,  -- other universe UUID
  merge_expiry = nil,  -- auto-unmerge after X seconds (optional)
}
```

### Unique Universe Features

By default, universes are **totally isolated**:
- Each player has their own copy of NPCs (no one shares the Sage)
- Items are not shared (each player's key is unique)
- Progress is personal (one player's solved riddle doesn't affect another)

**Why?** Prevents trivial solutions. No workarounds like "wait for someone else to solve it."

### Merge Triggers

Universe merges happen when:

#### **1. Cooperative Boss**
Two players voluntarily decide to team up for a hard encounter.

```lua
Boss {
  id = "dragon-smaug",
  hp = 500,
  solo_hp = 200,  -- if only one player fights, HP scales down
  
  on_merge_with = function(other_boss)
    -- Dragon becomes harder when fighting multiple players
    smaug.hp = 500
    smaug.attacks_per_turn = 3
  end,
}

-- Mechanics: `merge with player-002`
-- System: Finds player-002, creates temporary shared universe
-- Both players enter shared instance; boss gets harder
```

#### **2. Trading Hub**
Players temporarily merge just to trade items.

```lua
TradingPost {
  id = "marketplace",
  allow_merges = true,  -- players can meet here
  
  on_player_join = function(player)
    player:receive("Welcome to the marketplace. Other traders are here.")
    -- Broadcast to all players in merged universe
    world:broadcast("A new trader has arrived.")
  end,
}
```

#### **3. Rift (Portal)**
A rare portal links two universes. Players can step through temporarily.

```lua
Portal {
  id = "dimensional-rift",
  description = "A shimmering tear in reality, connecting two worlds.",
  
  verbs.enter = function(player)
    local other_universe = database:get_random_other_player()
    player.universe_id = other_universe.id
    player:receive("You step through the rift...")
    -- Player is now in another player's universe
    -- After 10 minutes, they're pulled back
    defer(function()
      player.universe_id = player.default_universe_id
      player:receive("You're pulled back through the rift!")
    end, 600)
  end,
}
```

#### **4. Summoning Ritual**
Player casts a spell to bring another player into their universe.

```lua
Spell {
  id = "summon-ally",
  verbs.cast = function(player, target_player_id)
    local target = database:get_player(target_player_id)
    if not target then return "That player is not online." end
    
    target:notify("You are being summoned! Accept? (yes/no)")
    -- If target accepts:
    target.universe_id = player.universe_id
    player:receive(target.name .. " appears in a flash of light!")
    -- Player is now in summoner's universe, both see each other
  end,
}
```

### Merge Conflict Handling

**Scenario:** Two players merge into same universe. What happens to divergent state?

**Design decision:** The **owner's universe is canonical**. When merging into Player A's universe:
- Player A's version of the Sage is the "real" Sage
- Player B's version disappears
- Items found by Player B before merge are still in their inventory
- Puzzle solutions persist (if Sage was already talked to, stays talked-to)

```lua
function merge_universes(universe_a, universe_b)
  -- universe_a is the "host" (player-a's universe)
  -- Merge universe_b into it temporarily
  
  for actor_id, actor in pairs(universe_b.actors) do
    if universe_a.actors[actor_id] == nil then
      -- Actor only exists in B; copy it over
      universe_a.actors[actor_id] = actor
    else
      -- Actor exists in both; use A's version (canonical)
      -- B's version is discarded
    end
  end
  
  -- Mark merge
  universe_a.is_merged = true
  universe_a.merged_with = universe_b.id
  universe_a.merge_expiry = now() + 3600  -- auto-unmerge after 1 hour
end
```

### Cross-Universe Communication

**Important:** Players can only communicate if their universes are merged.

```lua
function talk_command(player, actor_name)
  local npc = search_for_actor(actor_name, player.location)
  if npc then
    return npc:on_talk(player)
  else
    return "There's no one here by that name."
  end
end

function say_command(player, message)
  local room = world:get_room(player.location)
  
  -- Broadcast to all players in THIS room (may be multiple if merged)
  for other_player in room:get_players() do
    if other_player.id ~= player.id then
      other_player:receive(player.name .. " says: " .. message)
    end
  end
end
```

If universes are separate, `say` broadcasts only to NPCs in that universe.  
If merged, `say` is heard by other players in the shared room.

---

## 7. Narrative Framework

### Overarching Story vs. Sandbox

We balance **authored narrative** with **emergent sandbox**:

- **Authored:** Main quest line, key NPCs, story beats, world lore
- **Sandbox:** Exploration, side quests, optional puzzles, player agency

**Example structure:**

```
ACT 1: The Awakening
  - Player wakes in tavern, has no memory
  - Sage offers a quest: recover the three shards
  - Player can accept or refuse (sandbox freedom)

ACT 2: The Shards
  - Main quest: find three shards scattered in dungeons
  - Side content: optional NPCs, optional puzzles, trading
  - Player can complete main quest or get sidetracked

ACT 3: The Convergence
  - All players who collected shards converge at temple
  - Cooperative finale: defeat guardian
  - Story concludes; universe resets for next chapter (or continues)
```

### Quest Systems

#### **Main Quest** (Story-driven)
```lua
Quest {
  id = "recover-three-shards",
  status = "active",
  narrative = "The sage believes three shards of an ancient artifact..."
  
  stages = {
    {
      id = "find-shard-1",
      objective = "Recover the Shard of Fire from the Volcanic Cavern",
      location = "volcano",
      reward = {xp = 100, item = "shard-1"},
    },
    {
      id = "find-shard-2",
      objective = "Recover the Shard of Ice from the Frozen Peak",
      location = "glacier",
      reward = {xp = 100, item = "shard-2"},
    },
    {
      id = "find-shard-3",
      objective = "Recover the Shard of Earth from the Crystal Mine",
      location = "mine",
      reward = {xp = 100, item = "shard-3"},
    },
    {
      id = "deliver-shards",
      objective = "Bring all three shards to the Sage",
      npc = "sage-aldor",
      reward = {xp = 500, achievement = "shard-bearer"},
    },
  }
}
```

#### **Side Quest** (Optional)
```lua
Quest {
  id = "missing-cat",
  status = "available",  -- not auto-active
  giver = "old-woman",
  objective = "Find Whiskers the cat, lost in the woods",
  reward = {xp = 25, item = "cat-collar"},
}
```

#### **Dynamic Quest** (Generated by engine)
```lua
DynamicQuest {
  id = "hungry-npc",
  trigger = function(player)
    -- Triggered when player meets an NPC with low "fullness"
    if npc.fullness < 20 then
      npc:say("I'm so hungry! Do you have food?")
      return {
        objective = "Bring food to " .. npc.name,
        reward = {item = "blessing-" .. npc.id},  -- NPC grants blessing
      }
    end
  end,
}
```

### NPC Dialogue & Personality

```lua
NPC {
  id = "merchant-tolan",
  name = "Merchant Tolan",
  personality = "greedy",  -- influences dialogue
  mood = "neutral",  -- shifts based on player interactions
  
  dialogue_tree = {
    greeting = {
      text = "Welcome to my shop. I have exotic wares.",
      options = {
        {text="What do you sell?", next="inventory"},
        {text="I'm just looking.", next="dismiss"},
      }
    },
    inventory = {
      text = "I sell weapons, potions, and rare artifacts. Your coin, please.",
      options = {
        {text="Show me weapons.", next="weapons"},
        {text="Never mind.", next="dismiss"},
      }
    },
    weapons = {
      text = "I have swords, bows, and staffs. Prices vary.",
      options = {
        {text="How much for the sword?", next="price_sword"},
        {text="I'll browse elsewhere.", next="dismiss"},
      }
    },
    price_sword = {
      text = "The blade? 100 gold coins. A bargain.",
      options = {
        {text="Deal.", action="trade", next="goodbye"},
        {text="Too expensive.", next="dismiss"},
      }
    },
  },
  
  on_mood_change = function(old_mood, new_mood)
    if new_mood == "angry" then
      merchant.dialogue_tree.greeting.text = "Get out of my sight!"
    elseif new_mood == "happy" then
      merchant.dialogue_tree.greeting.text = "Ah, my friend! Welcome back."
    end
  end,
}
```

### World Lore & Environmental Storytelling

Lore is embedded in objects and rooms:

```lua
Item {
  id = "ancient-tome",
  name = "Ancient Tome",
  on_read = function()
    return [[
      "Chapter VI: The Sundering
       
       In ages past, the Three Realms were one. But hubris drove the
       Mages to fracture reality itself. Now parallel worlds exist,
       each a mirror of the other, yet forever separate..."
    ]]
  end,
}

Room {
  id = "ruined-temple",
  description = "Crumbling columns covered in vines. Murals depict a civilization long gone.",
  on_look = function()
    local text = "Murals on the wall show: "
    if player:has_item("ancient-tome") then
      text = text .. "You recognize the symbols from the tome! They match."
    end
    return text
  end,
}
```

---

## 8. Example Scenarios

### Scenario 1: The Solo Puzzle (New Player)

**Player:** Arriving in the game for the first time.  
**Goal:** Learn core verbs and solve the Mirror Puzzle.

```
Welcome to the Multiverse.

You awaken in a tavern common room. Warm light flickers from a hearth.
A barkeeper polishes a glass. To the east, you see a corridor.

> look
You are in a tavern common room. A cozy atmosphere. The barkeeper 
nods at you from behind the bar. To the east, a corridor leads away.

> look at barkeeper
He's a jolly fellow, wiping down glasses. He notices you staring.
"First time here, eh? You look lost."

> talk to barkeeper
Barkeeper says: "Welcome, wanderer. I don't know your story, but the 
Sage upstairs might. She reads minds. Head east and up."

> go east
You walk through the corridor. The walls are lined with paintings.

> go up
(Player enters an upstairs chamber)

You stand in the Sage's chamber. Candlelight dances. On the wall, a 
large mirror reflects the candlelight. The Sage sits in a chair, eyes 
closed. To the north, a locked door.

> look at mirror
It's a beautiful mirror, ancient and ornate. You see your reflection—
but something feels wrong about it. It's watching you.

> talk to sage
Sage says: "To escape this place, you must break the mirror. But beware—
breaking it may change you forever. Or perhaps free you."

> break mirror
You reach for the mirror and strike it with your fist. It shatters 
with a terrible crash.

As the glass falls away, the mirror's frame MUTATES:
- The broken frame spirals open, becoming a doorway
- Sage's dialogue changes: "You did it. You broke the illusion. Go north."
- The locked door to the north is now open

> go north
(Player escapes and enters the wider world)
```

**Learning:** Verbs (LOOK, TALK, GO, BREAK), object interaction, consequences.

---

### Scenario 2: Cooperative Puzzle (Two Players)

**Players:** Alex and Jordan (friends playing together)  
**Goal:** Defeat the Hydra boss together.

```
[Merged universe: Alex's world]

Alex is in the Volcanic Cavern.
Jordan (visible to Alex): "Alright, I'm here. Let's do this."

> look
You stand in a vast cavern. Lava flows in channels. At the center,
the HYDRA coils, a seven-headed serpent. Its eyes glow red.

Hydra Status (Cooperative mode):
  - Health: 500 HP
  - Attacks per turn: 3
  - Special: Regeneration (heals 20 HP every 2 turns)

Alex types: > attack hydra with sword
  Alex strikes the left head. It hisses and strikes back!
  Alex takes 30 damage. (Alex: 70/100 HP)

Jordan types: > attack hydra with staff
  Jordan blasts the middle head with fire magic.
  Hydra takes 50 damage. (Hydra: 450/500 HP)

[Several rounds of combat...]

After Hydra is defeated:
  Hydra dissolves into ash and treasure.
  Reward: 200 XP each, Hydra's Fang (rare item)
  
Both players: "Victory! Let's merge to split the treasure."

[Merge triggers automatically]

Alex sees: Jordan opens the treasure chest.
Jordan sees: Alex opens the treasure chest.

Treasure is automatically duplicated (each player gets one of each reward).
```

**Learning:** Cooperation, combat, shared consequences, merging mechanics.

---

### Scenario 3: Moral Choice (Story-driven)

**Player:** Casey (mid-level, exploring side content)  
**Goal:** Decide whether to help or betray an NPC.

```
Casey enters the Bandit's Hideout.

Inside, Garrett (the bandit chief) lies bleeding on the ground.
He looks up at Casey.

Garrett says: "Please... I'm dying. My rival, the Sheriff, poisoned me.
If you help me escape, I'll reward you handsomely. But the Sheriff... 
he's chasing me. Will you hide me or turn me in?"

OPTIONS:
1. HELP Garrett: Hide him and face off against the Sheriff
2. BETRAY Garrett: Give him to the Sheriff for a reward
3. IGNORE: Leave and never return

Casey chooses: help garrett

> help garrett

You hide Garrett in the basement.

[Code mutation happens:]
- Garrett's faction: "Bandit" → "Hunted"
- Garrett's mood: "grateful"
- New dialogue options unlock: "I owe you my life."
- Sheriff is now hostile to Casey
- Sheriff's on_encounter: "You harbour a criminal!"

Later, Sheriff confronts Casey:

Sheriff: "I know what you did. You're harboring a fugitive."

OPTIONS:
1. DENY: "I don't know what you mean."
2. CONFESS: "He needed help."
3. FIGHT: Draw weapon

Casey chooses: confess

Sheriff's code mutates:
- He respects Casey's honesty
- New dialogue: "I misjudged you. The law isn't always just."
- Quest opens: "Uncover the truth about the poisoning"

Later, if Casey solves the investigation:
- Garrett is pardoned
- Sheriff is promoted
- Casey gains: "Truthseeker" achievement
- Canon story changes: citizens respect Casey's moral integrity
```

**Learning:** Choices matter. Code mutation reflects narrative consequences. No "right" answer—only consequences.

---

### Scenario 4: Multiverse Rift (Advanced)

**Player:** Morgan (high-level, seeks challenge)  
**Goal:** Explore another player's universe.

```
Morgan discovers a rare portal in the Forgotten Shrine.

> examine portal

A shimmering tear in reality. You sense another world beyond it.

> enter portal

You step through. Reality shifts around you.

A flash of light—

You find yourself in a DIFFERENT TAVERN (Player-Xavier's universe).

Description: "This tavern is DIFFERENT from yours. The decor is alien.
The barkeeper is not the same person. On the wall, a portrait of
someone you don't recognize."

Morgan realizes: "This is someone else's universe."

> look at portrait

It's Xavier, the tavern's legendary hero (in his own universe).

> talk to barkeeper

Xavier's barkeeper: "Welcome, stranger. You look out of place. 
Are you from Beyond?"

This universe has:
- Different puzzle solutions (Xavier solved different riddles)
- Different NPC fates (some are dead, some are allies)
- Different items (some are cursed, some are blessed)

Morgan explores Xavier's world, solves a few side puzzles, finds a unique item
(cursed amulet that Xavier never found).

After 10 minutes:

You feel a tugging sensation. The portal is calling you back.

The amulet pulses with energy. The tavern shimmers and fades.

[Morgan is pulled back to their own universe]

Morgan's inventory now contains: cursed-amulet (from Xavier's world)

Back home:
> examine cursed-amulet

"An amulet from another realm. It radiates strange power."

The curse: Morgan's next attack does double damage (but at cost of sanity).
```

**Learning:** Multiverse exploration, alternate world-states, cross-universe artifacts, consequences of merging.

---

## Anti-Patterns: The Worst Design Decisions Ever

> *"I have catalogued every catastrophic design failure in the history of interactive fiction. I now share this knowledge so that you may avoid becoming a footnote in my mental encyclopedia of shame."*

These are the design decisions that **will ruin this game** if allowed. They are presented in order of how often I have seen otherwise intelligent developers commit them.

### ❌ "Guess the Verb" Hell
**Problem:** Player knows what they want to do but cannot find the magic word. Classic example: early Sierra games where `EXAMINE`, `LOOK AT`, and `INSPECT` all failed but `X` worked. Players who reach for natural language and receive "I don't understand that" forty times in a row do not write positive reviews.  
**Solution:** Robust synonym tables. When a verb fails, suggest nearby verbs: *"I don't understand OBSERVE CRYSTAL. Did you mean EXAMINE CRYSTAL?"* Err on the side of acceptance, not rejection.

### ❌ Silent Failures
**Problem:** Player types `GET KEY`. Key is there. Nothing happens. No error message. This is inexcusable — worse than a clear failure, because it makes the player question reality.  
**Solution:** Every failed action produces a specific, informative message. Never silent failure. Never.

### ❌ Maze Rooms (The Twisty Passages Trap)
**Problem:** Zork had "a maze of twisty little passages, all alike." This was tolerable once, in 1977, because it was novel. It is not tolerable now. Making players draw graphs on paper is not a puzzle — it is a clerical task.  
**Solution:** Mazes must be navigable through deduction, not memorization. Distinctive rooms, consistent exit relationships, or an in-world mapping mechanic.

### ❌ Inventory Scavenger Hunt Softlocks
**Problem:** Player needs Object X that was available two hundred rooms ago and they dropped it. Now the puzzle is unsolvable and they don't know it. This is interactive fiction's equivalent of a save-corruption bug.  
**Solution:** Critical puzzle items should not be permanently destroyable without explicit warning. Provide alternatives, or warn the player before the point of no return.

### ❌ Combat as a Puzzle Substitute
**Problem:** "The room has a monster. Kill the monster. Take the item." This is not a puzzle. This is a checkbox with violence attached.  
**Solution:** Every combat encounter must have at least one non-combat resolution path. Fight, negotiate, sneak, trick, run. The monster is a puzzle with one obvious solution and at least two non-obvious ones.

### ❌ Merge Without Consent
**Problem:** Forcing a player into a merge event without consent destroys the sense of a personal universe and enables griefing at the architectural level.  
**Solution:** All player-initiated merges require double-consent. World-triggered merges are pre-announced and declinable.

### ❌ Mutation Without Memory
**Problem:** The universe changes but the player cannot tell what changed or why. Self-modification becomes noise. Players become paranoid.  
**Solution:** Every world mutation produces a visible description. Mutations are logged in the universe's "Chronicle" (a Document the player can READ to see their world's history of changes).

### ❌ NPC Oracles (The Magic Information Dispenser)
**Problem:** An NPC who exists solely to give the player a piece of information, then has nothing else to say or do. This is a dialogue box wearing a costume.  
**Solution:** Every NPC has a life beyond their puzzle relevance. They have opinions, preferences, routines. The information they hold is earned through relationship, not interrogation.

---

## Design Philosophy Summary

1. **Verbs, not mechanics:** Every action is expressed as a verb. Keep the verb list lean and meaningful.

2. **Code as truth:** No hidden state flags. If something changed, it changed in the code. Players can reason about the world because the code IS the world.

3. **Sandbox with narrative spine:** Main quest gives direction, but players are free to ignore it and explore. Emergent stories arise from player choices.

4. **Isolation by default, merge by choice:** Universes are separate until players decide to merge. This prevents trivial solutions and keeps each world personal.

5. **Consequences are permanent:** Player choices mutate the code. You can't undo choices (though you can load an old save). Moral weight.

6. **Complexity is allowed:** All code is LLM-written. We're not constrained by what's easy to code. Make the world rich.

7. **Text is the medium:** No graphics. Description is everything. Encourage imagination.

---

## Next Steps & Open Questions

1. **Code mutation vs. state flags:** Should we truly rewrite code on every action, or use flags + lazy code generation? Trade-off: mutation is pure but expensive; flags are efficient but less elegant. **Recommendation:** Start with flags, migrate to mutation if LLM cost permits.

2. **Persistence format:** Should universes be stored as Lua source code (elegant but fragile) or JSON snapshots (less elegant but robust)? **Recommendation:** JSON snapshots with optional Lua export for debugging.

3. **Combat resolution:** Not covered here. Do we use turn-based combat, real-time, or narrative resolution? **Recommendation:** Turn-based for simplicity; combat verbs (attack, defend, cast-spell).

4. **Magic system:** If Lua is the world's language, can players "cast spells" that are literally code injections? **Recommendation:** Yes, but sandboxed. Spells run in restricted Lua environment.

5. **Scaling:** One player per universe is cozy but limiting. Should we support multi-player single-universe (Shared world)? **Recommendation:** Not for Phase 1. Keep universes isolated and sacred.

---

## References

- **Zork** — The grandfather of text adventures (1980). Pioneered parser-based interaction.
- **Inform 7** — Modern IF language. Demonstrates sophisticated verb systems and world model.
- **TADS** — Technical Author's Dream System. Shows how to build deep, interactive worlds.
- **Twine** — Choice-driven narrative. Shows how non-parser IF works.
- **Lua in games** — WoW, Roblox, LÖVE, Defold all use Lua for embedded scripting.
- **Prototype-based programming** — Self-modifying code is natural in prototype-based languages.

---

**Document Status:** Ready for team review and implementation.  
**Author:** Comic Book Guy  
**Date:** 2026-03-19
