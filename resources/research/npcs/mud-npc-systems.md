# MUD NPC Systems: Text-Based Game Precedent

**Comparative Research** — Classic MUDs established practical patterns for text-based NPC interaction, memory, and behavior. Learn what worked, what didn't, and how modern MUD frameworks innovate.

---

## Executive Summary

MUDs pioneered NPC systems in purely text-based games. From DikuMUD's simple hardcoded mobs to LPMud's scriptable creatures, MUDs demonstrate:

1. **What works:** Scripting systems for NPC behavior (MOBPrograms), persistent world state, stat-based combat, simple scheduling
2. **What's hard:** Conversation memory, natural dialogue, scale management, emergent narrative
3. **Modern innovations:** Frameworks like Evennia add memory systems, LLM integration, and better dialogue handling

**For MMO:** MUDs establish patterns (wander behavior, quest-giver archetypes, stat progression) but also show their limits. Modern approaches combine MUD patterns with contemporary AI (LLMs, behavior trees, memory management).

---

## I. DikuMUD: The Hardcoded Foundation

### A. Core MOB Definition

In DikuMUD (C-based, late 1980s), NPCs ("mobs") are defined as static C structs:

```c
struct mob_data {
    char *name;           // e.g., "goblin warrior"
    int level;
    int hit_points;
    int max_hit_points;
    int attack_power;
    int defenses;
    int gold;
    struct obj_data *inventory[MAX_INV];
    int movement_pattern;  // 0=wander, 1=pace, 2=flee
    void (*action_func)(); // Function pointer to mob behavior
};
```

**Key Limitation:** Behavior is hardcoded via function pointers or switch statements on mob type. Adding new behavior requires:
1. Writing C code
2. Recompiling the server
3. Rebooting the world

### B. MOBPrograms: The Breakthrough

Later Diku-derived MUDs (ROM, CircleMUD, SMAUG) introduced **MOBPrograms**—small scripts attached to mobs:

```
>speech_prog 100~
if $n.name == player_name
  say Hello, $n.name!
  give potion $n
endif
~
```

**Capabilities:**
- **Triggers:** speech (keyword), entry (entering room), command (emote), time (periodic), combat, death
- **Actions:** say, emote, force, give, teleport, open door, cast spell
- **Conditionals:** if/else, simple variable checks
- **Minimal learning curve:** Builders could script mobs without C knowledge

**Impact:**
- Reduced hardcoding burden
- Enabled diverse mob personalities and quests
- Still very limited (no state memory, no personality, no complex logic)

### C. Key NPC Archetypes

DikuMUD established lasting patterns:

1. **Wandering Guard/Creature**
   - Patrol a fixed room list
   - Attack on sight under conditions
   - Loot drops on death

2. **Shopkeeper**
   - Stationary in shop room
   - `buy` command: sells items at markup
   - `sell` command: buys items at discount
   - Restocks periodically

3. **Quest-Giver**
   - Accepts quest trigger (keyword or `quest` command)
   - Gives item or directive
   - Tracks completion via flags
   - Offers reward

4. **Healer/Cleric**
   - Stationary or patrol
   - Cast heal on nearby allies
   - May refuse service if player is flagged enemy

---

## II. LPMud: The Programmable Alternative

### A. Architecture

LPMud (1989 onward) split infrastructure from content:

- **Driver:** C-based "virtual machine" (like Java's JVM)
- **Mudlib:** All game content written in LPC (interpreted language, similar to C)
- **Objects:** Rooms, mobs, items are LPC objects that inherit/compose

### B. NPC as Scriptable Object

Each mob is an LPC object file (`/domains/dwarf.c`):

```lpc
#pragma strict_types

inherit MONSTER;  // Base monster class

void create() {
    ::create();
    SetName("dwarf");
    SetBody("humanoid");
    SetLevel(5);
    SetStats("str", 16);
    SetSkill("melee combat", 60);
}

void heart_beat() {
    ::heart_beat();
    
    if(!QueryCurrentEnemy()) {
        // Wander or idle
        if(random(100) < 30) {
            ForceMe("emote grunts");
        }
    }
}

void init() {
    ::init();
    add_action("talk_func", "talk");
}

int talk_func(string str) {
    if(str && str[0..4] == "dwarf") {
        notify_fail("The dwarf grunts at you unintelligibly.");
        write("The dwarf says: Aye, what d'ye want?");
        say(query_cap_name() + " says: Aye, what d'ye want?");
        return 1;
    }
    return 0;
}
```

**Advantages:**
- NPCs are *first-class objects* with inheritance, state, and methods
- No recompilation required; reload object via `update` command
- Support for custom stats, inventory, behaviors
- Event-driven (`heart_beat()` called periodic, `init()` on player entry)
- Highly expressive (full programming language)

### C. State & Persistence

LPC objects maintain state between sessions:
- Global variables persist (e.g., `int questCompletions = 42;`)
- Can save/load object state via serialization
- Enables NPC evolution (skill increases, relationships, quest progress)

---

## III. Comparison: DikuMUD vs. LPMud

| Aspect | DikuMUD | LPMud |
|--------|---------|-------|
| **Mob Definition** | C struct | LPC object |
| **Behavior Scripting** | MOBPrograms or C code | LPC methods |
| **Recompilation Required** | Yes (for new behavior) | No (hot reload) |
| **State Persistence** | Flags/numbers only | Full object state |
| **Complexity Ceiling** | Moderate (simple triggers) | High (full programming) |
| **Ease of Use** | Easy (MOBPrograms) | Harder (LPC required) |
| **Scalability** | Good (hardcoded efficiency) | Fair (interpreted overhead) |

**Verdict:** LPMud is more powerful and flexible; DikuMUD is more efficient and accessible. Modern MUDs often blend: use a high-level scripting language (Python, JavaScript) on an efficient driver.

---

## IV. Classic MUD NPC Patterns

### A. Shopkeeper Pattern

Persistent merchant with inventory management:

```lua
function npc_talk(player, verb, subject)
    if subject == "shop" or subject == "wares" then
        list_inventory(player)
    elseif subject == "price" then
        describe_pricing(player)
    end
end

function player_buy(item_name)
    if has_item_in_stock(item_name) then
        cost = get_price(item_name)
        if player.gold >= cost then
            give_item_to_player(item_name)
            take_gold_from_player(cost)
            return "You buy the " .. item_name
        else
            return "You don't have enough gold."
        end
    else
        return "Sorry, I'm out of stock."
    end
end
```

**Limitations:**
- No negotiation or haggling
- No personality (treats all customers identically)
- No memory of past transactions
- No dynamic pricing

### B. Wandering Patrol

Simple cyclic movement pattern:

```lua
patrol_route = { "room_1", "room_2", "room_3", "room_4" }
current_index = 1

function heart_beat()
    if not in_combat then
        move_to_room(patrol_route[current_index])
        current_index = (current_index % #patrol_route) + 1
    end
end
```

**Limitations:**
- Predictable (players learn route and ambush)
- No contextual adjustment (e.g., avoid dangerous areas if weak)
- No interaction between patrols

### C. Quest-Giver

Trigger-based quest assignment:

```lua
function talk(player, keyword)
    if keyword == "quest" then
        if not player:has_quest("kill_rats") then
            player:give_quest("kill_rats", {target=10})
            return "Please kill 10 rats in the sewers and return."
        elseif player:quest_complete("kill_rats") then
            player:complete_quest("kill_rats")
            player:give_reward_gold(100)
            return "Excellent! Here's your reward."
        else
            return "How are you progressing?"
        end
    end
end
```

**Limitations:**
- Quest state is tied to player flags, not NPC memory
- No conversation flow (always same response)
- No personality in quest text

---

## V. Modern MUD Innovations

### A. Evennia Framework

Evennia (Python-based modern MUD framework) adds:

1. **Rich Object Model:** Typeclasses for NPCs, items, rooms with full OOP
2. **Persistent Database:** Every object's state saved automatically
3. **Script System:** Custom scripts attach to objects, triggered by events
4. **Memory System:** NPCs can maintain notes, relationships, visit history
5. **Command Parsing:** Full verb resolution with object matching (what DF/modern games use)

Example (Evennia):

```python
from evennia import DefaultCharacter

class Shopkeeper(DefaultCharacter):
    def at_object_creation(self):
        self.db.shop_stock = {"sword": 100, "shield": 50}
        self.db.shop_prices = {"sword": 50, "shield": 25}
        self.db.sales_log = []  # Remember customers
        
    def handle_buy(self, buyer, item):
        price = self.db.shop_prices.get(item)
        if price and buyer.db.gold >= price:
            buyer.db.gold -= price
            buyer.get_item(item)
            self.db.sales_log.append((buyer.name, item, timestamp))
            self.msg(f"You sell {item} to {buyer}.")
            return True
        return False
```

### B. Ranvier Framework

Ranvier (JavaScript-based) emphasizes:

1. **Behavioral Scripts:** Mobs defined with state machines
2. **Quest System:** Structured quest framework with state tracking
3. **Memory:** Per-NPC memory for learning and relationship tracking
4. **Command Routing:** Full IF-style parser integration

### C. TaleWeave AI

Recent innovation combining:
- **LLM Dialogue:** OpenAI/Anthropic models for natural conversation
- **Memory Management:** Persistent NPC memory (facts, relationships, history)
- **Behavioral States:** Mood/emotion system driving action selection
- **Scalability:** Fixed memory limits per NPC to keep costs down

---

## VI. MUD Strengths for NPCs

### A. Persistence

MUD NPCs are **truly persistent**:
- Inventory survives server restart
- Relationships/flags accumulate
- Experience/level progress recorded
- World state changes are permanent (unless explicitly reset)

**For MMO:** This is critical. NPCs should remember player interactions across sessions.

### B. Statefulness

NPCs maintain state (quest flags, inventory, money), enabling:
- Quest tracking (without player participation)
- Economy (shopkeepers restock, prices fluctuate)
- Aging (NPCs grow older, change disposition)
- Learning (skill progression, relationship evolution)

### C. Scalability

MUDs handle 50-200 concurrent players with 500+ NPCs efficiently:
- Tick-based updates (e.g., 20 ticks per second)
- Distance-based simulation culling
- Caching of expensive calculations
- Simple pathfinding (hop lists, not A*)

---

## VII. MUD Shortcomings for NPCs

### A. Limited Dialogue

MUDs have *triggers* (keywords), not *conversation*:
- "say quest" → triggered response
- No multi-turn dialogue
- No natural language understanding
- Responses are static strings, not contextual

**Problem:** Players quickly learn all dialogue trees and stop talking to NPCs.

### B. Shallow Personality

Most MUD NPCs have:
- Name, stats, inventory
- Simple behavior rules
- NO personality traits
- NO emotional state
- NO long-term goals

**Result:** NPCs feel like machines (or worse, punchbags).

### C. No Emergent Behavior

NPCs follow hardcoded or scripted paths:
- Shopkeepers never move beyond shop
- Guards follow fixed patrols
- No NPC-to-NPC interaction
- No adapting to player or world changes

### D. Poor Inter-NPC Interaction

Most MUDs have *no NPC-to-NPC system*:
- NPCs ignore each other
- No teamwork (guards don't coordinate)
- No relationships between NPCs
- No emergent conflicts or alliances

---

## VIII. Text Adventure vs. MUD NPC Needs

| Need | MUD | Text Adventure |
|------|-----|-----------------|
| **Persistent State** | ✅ Critical | ✅ Critical |
| **Dialogue** | ⚠️ Triggers only | ✅ Must support full conversation |
| **Emotion/Personality** | ❌ Missing | ✅ Needed for immersion |
| **Memory** | ⚠️ Flags only | ✅ Rich memory system |
| **Relationship Tracking** | ⚠️ Limited | ✅ Must track relationships |
| **Autonomy** | ❌ Limited | ✅ Should pursue own goals |
| **NPC-to-NPC Interaction** | ❌ Missing | ✅ Adds richness |
| **Combat/Agency** | ✅ Well-established | ⚠️ Single-player context |

---

## IX. Modern Synthesis: LLM-Enhanced NPCs

### A. Hybrid Approach (2024-2025)

Cutting-edge MUD/text-adventure frameworks combine:

1. **Simulation Layer:** State machine (need, mood, task) driving NPC behavior
2. **Memory Layer:** Structured memory (facts, relationships, history) accessible to dialogue
3. **Dialogue Layer:** LLM-powered conversation, grounded in memory and simulation state
4. **Economy/Social Layer:** NPCs interact with each other, building relationships and world state

### B. Example: Mantella (Skyrim Mod)

Replaces NPC dialogue with LLM dialogue, backed by:
- NPC stats (race, level, personality)
- Recent conversation history
- World context (current quest, NPC location)
- Relationship state (trust, grudge, faction)

Result: NPCs are *far more engaging*, but also:
- Latency issues (LLM API calls are slow)
- Hallucination (NPCs invent facts)
- Cost (token usage)

### C. Fixed-Persona Small Language Models (2024)

Recent research emphasizes:
- Fine-tune small models (7B-13B) on a specific character
- Attach modular memory (persistent facts, history)
- Reduce inference cost and latency vs. GPT-4
- Maintain persona consistency better

**Application:** Per-NPC small model + shared memory backend = scalable, responsive dialogue.

---

## X. Lessons for MMO NPC Architecture

### A. From DikuMUD: Simplicity Wins

- **Keep behavior logic simple** (triggers, actions, state)
- **Avoid monolithic AI** (many small systems > one giant planner)
- **Reusability** (base classes, inheritance patterns)

### B. From LPMud: State Machines Rock

- **Objects are NPCs:** Each NPC is a self-contained entity with state and methods
- **Hot reload:** Enable rapid iteration (not all servers support this, but critical for development)
- **Inheritance hierarchy:** Base creature class → specific species/role → individual NPC

### C. From Evennia: Structured Systems

- **Persistent database:** Everything saved automatically (no manual serialization)
- **Event system:** Objects emit/listen to events (player entered, damage taken, quest completed)
- **Type safety:** Defined attributes on classes, not free-form dicts

### D. From Modern Frameworks: Layers

- **Separate concerns:** Behavior ≠ Dialogue ≠ Combat ≠ Economy
- **Pluggable dialogue:** Easy to swap between simple triggers, dialogue trees, LLM
- **Memory as data:** Treat NPC knowledge as queryable database, not hardcoded facts

---

## XI. Practical Implementation for MMO

Recommended pattern:

```lua
-- NPC Base Class (Lua)
local NPC = {
    name = "generic npc",
    stats = { str = 10, int = 10, wis = 10 },
    needs = { hunger = 0, thirst = 0, social = 0 },  -- 0-100 scale
    mood = "neutral",  -- or happy, angry, tired, afraid
    tasks = {},  -- Queue of current tasks
    relationships = {},  -- {npc_id => {type, strength}}
    memory = {},  -- Event log
}

function NPC:tick()
    self:update_needs()  -- Age needs (hunger increases)
    self:update_mood()   -- Mood based on recent events
    self:decide_action() -- Choose next task based on needs, mood, relationships
end

function NPC:hear_player(text)
    -- Query memory for relevant facts
    local context = self:query_relevant_memory(text)
    -- Check personality/relationship with player
    local personality_bias = self:get_personality_bias(player)
    -- Use dialogue engine (triggers, dialogue tree, or LLM) to generate response
    local response = dialogue_engine:generate_response(context, personality_bias)
    return response
end
```

---

## XII. References & Further Reading

- DikuMUD source and wiki
- LPMud documentation: https://www.lpmuds.net/
- Evennia framework: https://www.evennia.com/
- Ranvier framework: https://ranviermud.com/
- TaleWeave AI: https://github.com/ssube/taleweave-ai

---

**Next:** Read `npc-engineering-patterns.md` for architectural patterns (FSM, BT, GOAP, etc.).
