# Text Adventure Game Architecture: Research Report

**Research Date:** 2026-03-18  
**Researcher:** Frink  
**Focus:** Containment hierarchies and architecture patterns for mobile text adventure games  
**Scope:** Classic engines (Zork, Inform 7, TADS), modern frameworks, and mobile-specific considerations

---

## Executive Summary

Classic text adventure engines (Zork, Inform 7, TADS) use **hierarchical parent-child tree structures** to model object containment. The player is a container, rooms are containers, boxes are containers—each maintains a list of contents and a reference to its parent. This design elegantly handles nested containment, visibility rules, and state mutations. Modern frameworks (Twine, ChoiceScript) focus on narrative branching rather than physics simulation. For mobile games, a **hybrid ECS (Entity Component System) approach** offers scalability and clarity, while maintaining the classical tree model for spatial relationships.

**Key Finding:** The containment problem is well-solved. Focus your architecture design on command parsing, state mutation tracking, and mobile UI constraints—not on reinventing containment.

---

## 1. Object/Entity Model in Classic Text Adventures

### 1.1 Core Pattern: Everything is an Object

All classic IF engines treat every in-game entity as an **object** with properties and a location:

- **Zork/ZIL** (1980s): Property-based system where each object has attributes (description, flags like "takeable", "openable", state variables) and an implicit location property
- **Inform 7** (2000s): Natural-language-first; objects are "Things" with properties (description, properties like "openable", "transparent")
- **TADS 3** (1990s+): Object-oriented inheritance; everything derives from a "Thing" base class

**Universal Principle:** An object's type is determined by its *properties*, not rigid class hierarchy.

### 1.2 Class/Type Hierarchies

#### Zork/ZIL Hierarchy
```
Object (all things)
  Room (top-level container, static)
  Item (portable thing)
    Container (holds things "in")
    Surface/Supporter (holds things "on")
  Actor (character, can hold inventory)
  Door (bidirectional connection)
```

#### Inform 7 Hierarchy
```
Thing (everything in the world)
  Room (location, top-level container)
    Object (item, furniture)
      Container (can hold things "in")
      Supporter (can hold things "on")
      Enterable (player can enter: beds, cages, etc.)
  Person (character, NPC)
  Backdrop (visible from multiple rooms)
  Backdrop (scenery object)
```

#### TADS 3 Hierarchy
```
Thing (base for all objects)
  Room (top-level container)
  Actor (character, can move and hold items)
  Item (generic object)
    Container (closeable, holds things "in")
    Surface (holds things "on")
    Actor subtype (for creatures)
  Fixture (permanently part of a room)
```

### 1.3 Data-Driven vs. Code-Defined

- **Zork/ZIL:** Code-defined; objects are defined in code with properties and custom verbs
- **Inform 7:** Hybrid; objects defined in natural language syntax, but can include procedural code
- **TADS:** Code-defined in OOP style; room/object hierarchies built in code
- **Modern (Twine, ChoiceScript):** Largely data-driven (passage/passage-link networks in Twine; scene files in ChoiceScript)

**Recommendation for Mobile:** Data-driven dominates modern tools because it's easier to edit, version control, and iterate. Consider JSON or YAML for object definitions rather than pure code.

---

## 2. Containment Hierarchy (THE KEY QUESTION)

### 2.1 Core Data Structure: Parent-Pointer Tree

All classic text adventure engines use **a parent-child tree structure** where:

```
Each object has:
  - location (parent pointer): Who/where contains me?
  - contents (child list): What do I contain?
  - type: How do I behave? (Container vs. Supporter vs. Room, etc.)
```

**Conceptual Example:**
```
World (root)
  └─ Kitchen (Room)
      ├─ Table (Supporter)
      │   ├─ Plate (Thing)
      │   │   └─ Apple (Thing)
      │   └─ Napkin (Thing)
      ├─ Box (Container)
      │   ├─ Key (Thing)
      │   └─ Letter (Thing)
      └─ Player (Actor)
          ├─ Backpack (Container)
          │   ├─ Flashlight (Thing)
          │   └─ Rope (Thing)
          └─ Gold Coin (Thing)
```

### 2.2 Implementation Patterns

#### Zork/ZIL Pattern
- Objects have a `.has` property listing direct children
- Objects have a `.location` property pointing to parent
- Containment queries use recursive `.location` traversal
- Simple but effective for small to medium-sized worlds

#### Inform 7 Pattern
- Uses "spatial containment" model: objects are "in", "on", or "part of" others
- Provides automatic visibility/reachability calculations:
  - Can't see things in closed opaque containers
  - Can only interact with reachable objects
- Supports special types: "Enterable" things (you can GET IN a bed), "Backdrops" (visible from multiple rooms)

**Inform 7 Code Example:**
```
The kitchen is a room. "A cozy kitchen."
The table is a supporter in the kitchen.
The apple is a thing on the table.
The box is a closed container in the kitchen.
The key is a thing in the box.
The player carries a backpack.
```

Inform automatically handles: "I can see the apple on the table. The key is in the box (closed, so not visible)."

#### TADS 3 Pattern
- Each Thing has `.location` pointing to parent
- Each Thing has `.contents` list of direct children
- "Senses" system: objects can have different visibility rules (light, sound, smell)
- Multiple containment types: physical (in/on/under), logical, worn, etc.

### 2.3 Edge Cases and Constraints

All classic engines enforce certain rules:

| Constraint | How Handled | Example |
|-----------|-----------|---------|
| **You can't put a room in a box** | Type checking; Rooms are never movable | If location changes, validate that new parent accepts children |
| **Nested containers** | Recursive tree traversal | Box in Backpack in Player works; engine checks weight limits at each level |
| **Circular containment** | Prevent direct moves; Box can't contain itself | Check that new parent isn't already a descendant |
| **Weight/volume limits** | Property-based validation | Before moving object to container, sum weight of contents vs. capacity |
| **Visibility through nesting** | Recursive visibility rules | Look at parent's type; if closed container, can't see contents |
| **Can't reach nested items** | Reachability calculation | Player can't `take key` if key is in closed box in another room |

### 2.4 Data Structure Implementation

**Simple Python-style pseudocode (all engines follow similar patterns):**

```python
class GameObject:
    def __init__(self, name, obj_type="thing"):
        self.name = name
        self.obj_type = obj_type  # "room", "container", "supporter", etc.
        self.location = None  # parent pointer
        self.contents = []    # child list
        self.properties = {   # state
            "weight": 0,
            "capacity": None,
            "is_open": False,
            "is_locked": False,
            # ... custom properties
        }
    
    def add_child(self, child):
        """Move child into this object."""
        if child.location is not None:
            child.location.contents.remove(child)
        child.location = self
        self.contents.append(child)
        
    def can_contain(self, obj):
        """Validation: can I hold this object?"""
        if self.obj_type == "room":
            return True  # rooms hold everything
        if self.obj_type == "supporter":
            if obj.obj_type == "room":
                return False  # rooms can't go on supporters
            return True
        if self.obj_type == "container":
            # Check capacity
            total_weight = sum(c.properties["weight"] for c in self.contents)
            if total_weight + obj.properties["weight"] > self.properties["capacity"]:
                return False
            # Check if container is open
            if not self.properties["is_open"]:
                return False
            return True
        return False

# Movement example:
player.add_child(backpack)        # player contains backpack
backpack.add_child(key)           # backpack contains key
# Key's location chain: key → backpack → player (root: world)
```

**Tree Traversal Example:** "Where is the key?"
```python
def get_location_path(obj):
    path = [obj.name]
    current = obj
    while current.location is not None:
        current = current.location
        path.append(current.name)
    return " → ".join(reversed(path))

get_location_path(key)
# Output: "World → Kitchen → Backpack → Key"
```

### 2.5 Why This Works So Well

1. **Intuitive:** Reflects real-world containment
2. **Efficient:** Tree operations (insert, delete, traverse) are O(n) or better
3. **Scalable:** Handles hundreds of objects without issue
4. **Declarative:** Easy to visualize and reason about
5. **Flexible:** Supports varied container types via properties, not complex class hierarchies

---

## 3. Room/World Model

### 3.1 Room Connections: Graph Topology

Rooms are connected via a **directed graph** where:
- **Nodes** = Rooms
- **Edges** = Exits (doors, passages, portals)
- **Edge labels** = Direction (north, south, up, down) + conditional state (locked, requires key, etc.)

**Data Structure:**
```python
class Room:
    def __init__(self, name, description):
        self.name = name
        self.description = description
        self.exits = {}  # direction -> Room | (Room, Door object)
        self.contents = []  # things in this room

# Example:
kitchen = Room("Kitchen", "A cozy room with a stove.")
living_room = Room("Living Room", "A comfortable space with a sofa.")

kitchen.exits["north"] = living_room
living_room.exits["south"] = kitchen
```

### 3.2 Advanced Room Topology Features

- **One-way passages:** `room1.exits["north"] = room2` but `room2.exits` doesn't include room1
- **Conditional exits:** Door objects with locked/unlocked state; parser checks before allowing move
- **Dynamic exits:** Exits can be added/removed during game (e.g., cave-in blocks a passage)
- **Cycles:** The graph can have loops (non-euclidean maze topology)
- **Disconnected components:** Some rooms unreachable from others (valid for certain game designs)

### 3.3 Map Representation

Most engines don't store an explicit map. Instead:
- **Inform 7:** Provides `map` verb for debugging; automatically computes connectivity
- **TADS:** Uses region objects to group rooms; provides navigation helpers
- **Zork/ZIL:** No built-in map; game developer defines room network in code

For visualization/debugging, engines can export maps as:
- **JSON/YAML:** Flat representation of all rooms and exits
- **Graphviz DOT:** Renders as visual diagram
- **ASCII map:** Text representation for small worlds

---

## 4. Command Parsing & Dispatch (Brief Overview)

### 4.1 Parsing Pipeline

All text adventure parsers follow this flow:

```
User Input ("use gold key on door")
  ↓
[TOKENIZE] → ["use", "gold", "key", "on", "door"]
  ↓
[FILTER FILLERS] → ["use", "gold", "key", "on", "door"] (no change in this case)
  ↓
[IDENTIFY COMPONENTS]
  - Verb: "use"
  - Object1: "gold key"
  - Preposition: "on"
  - Object2: "door"
  ↓
[RESOLVE OBJECTS]
  - Find in room/inventory: key = Gold Key object, door = Door object
  ↓
[DISPATCH TO HANDLER] → use_handler(key, door)
  ↓
[EXECUTE & REPORT]
```

### 4.2 Verb Resolution

Parsers typically have:
- **Dictionary of verbs** mapping synonyms to handlers:
  ```python
  {
    "take": handle_take,
    "grab": handle_take,
    "pick up": handle_take,
    "get": handle_take,
    ...
  }
  ```
- **Grammar rules** matching command patterns:
  ```
  Pattern: "[VERB] [OBJECT]"
  Pattern: "[VERB] [OBJECT1] [PREP] [OBJECT2]"
  Pattern: "[VERB] [DIRECTION]"
  ```

### 4.3 Object Resolution

- **Pronoun handling:** "it", "him", "that" → remember last referenced object
- **Ambiguity resolution:** If multiple keys exist, ask player "Which key?"
- **Container context:** "take key in box" → search inside the box object first
- **Reachability:** Can only act on visible/reachable objects

### 4.4 Modern NLP Approaches

Some modern IF engines use **SpaCy**, **Compromise NLP**, or **BERT** for:
- Lemmatization (handle verb tenses)
- POS tagging (identify nouns vs. verbs)
- Entity extraction
- More flexible phrasing

**Trade-off:** Adds complexity but enables more natural commands like "Please take the old gold key and use it to open that rusty door."

### 4.5 Action Dispatch

Once parsed, commands dispatch via:
- **Dictionary/map lookup:** Most common; verb → handler function
- **Object method dispatch:** Each object has methods for relevant verbs
- **Hybrid:** Parser checks verb handler first, then asks object if it supports custom behavior

**Example (OOP-style):**
```python
# In parser
def handle_examine(obj):
    if hasattr(obj, 'custom_examine'):
        return obj.custom_examine()
    else:
        return f"You see {obj.description}"

# In door object (custom behavior)
class Door:
    def custom_examine(self):
        if self.is_locked:
            return "The door is locked. You need a key."
        else:
            return "The door is open."
```

---

## 5. State Management

### 5.1 What Needs to be Persisted?

For save/load/undo to work, the engine must track:

| State Type | Example | Persistence |
|-----------|---------|-------------|
| **Object locations** | Which room is the player in? | Save |
| **Inventory** | What does player carry? | Save |
| **Object properties** | Is door locked? Is light on? | Save |
| **Flags/counters** | Has player visited library? How many items collected? | Save |
| **Global variables** | Game progression state, story flags | Save |
| **Command history** | For undo; which commands executed? | Optional (undo stack) |
| **UI state** | Scroll position, selected menu item | Don't save |

### 5.2 Save/Load Architecture

**Serialization Formats:**
- **JSON:** Human-readable, easy to debug, good for web/mobile
- **YAML:** Slightly more compact, human-readable
- **Binary:** Most compact, faster to load (rarely worth it for IF)

**Example (JSON):**
```json
{
  "player": {
    "location": "kitchen",
    "inventory": ["backpack", "key", "coin"],
    "health": 100
  },
  "objects": {
    "kitchen": {
      "location": "world",
      "contents": ["table", "box"],
      "description": "A cozy room..."
    },
    "table": {
      "location": "kitchen",
      "contents": ["apple"],
      "type": "supporter"
    },
    "box": {
      "location": "kitchen",
      "contents": ["letter"],
      "is_open": false,
      "is_locked": true
    }
  },
  "flags": {
    "visited_library": true,
    "has_key_to_cellar": false
  }
}
```

### 5.3 Undo/Redo Support

Two main patterns:

#### Memento Pattern (Full Snapshots)
Store snapshots of entire game state at key moments:
- After each command (expensive but most flexible)
- After puzzle solutions (balanced approach)
- Configurable depth (e.g., keep last 50 turns)

**Pros:** Simple to implement; easy to debug  
**Cons:** Memory-intensive for large worlds

#### Command Pattern (Action-Based)
Each command is reversible:
```python
class Command:
    def execute(self):
        # Apply changes
        pass
    
    def undo(self):
        # Reverse changes
        pass

# Maintain command stack
undo_stack = []
redo_stack = []

def execute_command(cmd):
    cmd.execute()
    undo_stack.append(cmd)
    redo_stack.clear()  # clear redo after new action

def undo():
    cmd = undo_stack.pop()
    cmd.undo()
    redo_stack.append(cmd)
```

**Pros:** Memory-efficient  
**Cons:** Complex to implement correctly; some commands (like "show time") can't be undone

**Hybrid Approach (Recommended):** Use command pattern with periodic snapshots. Undo reverts to nearest snapshot + replays or unreplays commands.

### 5.4 Real-World Examples

- **Inform 7/TADS:** Built-in save/restore; typically VM-level serialization (serialize entire interpreter state)
- **Libzork:** YAML-based; each object serialized individually; clean architecture
- **Naninovel (visual novel):** JSON + binary formats; cross-device state sync; auto-save at scene changes

---

## 6. Modern Approaches & Frameworks

### 6.1 Branching Narrative Frameworks (Not Physics-Sim)

These prioritize narrative flow over spatial simulation:

#### Twine
- **Architecture:** Passage-based (node graph); each passage is a scene/choice point
- **Connection:** Passages linked via `[[link text|target passage]]`
- **State:** Variables tracked via scripting (SugarCube, Harlowe, etc.)
- **Data Model:** NOT a tree of physical objects; rather a tree of narrative branches
- **Best for:** Interactive fiction, visual novels, branching stories
- **Not ideal for:** Physics-based puzzles, complex item manipulation

**Story Format Examples:**
```
:: Kitchen [passage]
You're in the kitchen.
[[Take the key|With Key]]
[[Leave it|Without Key]]

:: With Key [passage]
You now have the key.
...
```

#### ChoiceScript
- **Architecture:** Scene-based; scenes are text files with conditional branching
- **State:** Variables (stats, flags) tracked in scene files
- **Syntax:** Simple choice-based; optimized for stat-tracking (like "Magium" or "Choice of Games")
- **Best for:** Stat-driven gamebooks, narrative-first experiences
- **Not ideal for:** Spatial exploration, inventory puzzles

**Example:**
```
*choice
  #Take the key
    *set has_key true
    You take the key.
  #Leave it
    *set has_key false
    You leave the key.
```

### 6.2 Entity Component System (ECS)

For more complex games, **ECS architecture** provides clarity:

```
Entities: Unique identifiers (e.g., "player_001", "kitchen_1")

Components: Pure data
  - PositionComponent { x, y, location_id }
  - InventoryComponent { contents: [item_ids] }
  - PhysicsComponent { weight, mass, collider_type }
  - DescriptionComponent { text, long_description }
  - StateComponent { is_open, is_locked, health }

Systems: Logic that operates on entities with specific components
  - MovementSystem: Moves entities with Position + can_move flags
  - InventorySystem: Adds/removes items from InventoryComponent
  - PhysicsSystem: Checks weight limits, prevents circular containment
  - RenderSystem: Generates description text for entities
  - SaveSystem: Serializes all components to JSON
```

**Benefit:** Decouples narrative (game rules) from state management (what's where). Makes save/load/undo very clean.

**Example (Pseudocode):**
```
Event: Player wants to take key from locked box
  ↓
MovementSystem checks:
  - Is key reachable? (check visibility rules via Location tree)
  - Is key movable? (check PhysicsComponent.is_movable)
  ↓
InventorySystem checks:
  - Player's inventory under weight limit? (sum PhysicsComponent.weight)
  ↓
If all pass: Update components
  - Remove key from box.InventoryComponent.contents
  - Add key to player.InventoryComponent.contents
  - Update key.PositionComponent.location = player
  ↓
SaveSystem automatically serializes all changed components
```

**Real-world Example:** Jiuzhouworld's Jiuzhou Engine uses ECS with GenAI narrative generation; ensures logic consistency.

### 6.3 Mobile-Specific Considerations

#### Small Screen / Touch Input
- **Single-column layout:** Stack text above input
- **Soft keyboard integration:** Don't overlap game text
- **Tap-to-select:** Common words/objects as buttons (reduces typing)
- **Gesture support:** Swipe up to scroll, double-tap to expand
- **Font sizing:** Large enough to read on small screens

#### Performance Constraints
- **No heavy NLP:** SpaCy/BERT too slow on mobile; use simpler tokenization
- **Lazy load assets:** Load room descriptions on demand, not all at startup
- **Limit undo depth:** Keep undo stack to last 20–50 turns, not infinite
- **Batch save/load:** Serialize in background thread; show spinner

#### Battery/Data
- **Save to local storage first:** SQLite, UserDefaults (iOS), SharedPreferences (Android)
- **Optional cloud sync:** If user wants cross-device save, use lightweight protocol
- **Compress saves:** Mobile storage is precious; gzip JSON before storing

#### UI/UX Patterns
- **Status bar:** Current room, inventory (collapsible)
- **Command shortcuts:** Common verbs as buttons; type for advanced commands
- **Help/tutorial:** Teach verb syntax early
- **Font choice:** Monospace (classic) or sans-serif (modern); ensure legibility

---

## 7. Synthesis: Architecture Recommendation for Mobile

### 7.1 Recommended Hybrid Approach

**For a mobile text adventure game, combine:**

1. **Containment Model:** Use the classical parent-child tree (proven, simple, efficient)
   - Each object has `.location` (parent) and `.contents` (children)
   - Enforce constraints: rooms never move, circular containment prevented, weight limits checked
   - Optional: ECS layer on top for cleaner state management

2. **Rooms/World:** Graph topology (standard rooms connected by exits)
   - Simple adjacency-list representation
   - Support for conditional exits (locked doors, requires item)

3. **Command Parsing:** Lightweight tokenizer + verb dispatch
   - No heavy NLP; use regex or simple grammar rules
   - Provide tap/button UI for common verbs to reduce typing
   - Allow full input for advanced players

4. **State Management:** Hybrid Memento + Command
   - Snapshot after every 5–10 commands (memory-efficient)
   - Full save/load to local storage (JSON)
   - Optional undo up to nearest snapshot + command replay

5. **Data Format:** JSON for objects + YAML for configuration (optional)
   ```json
   {
     "objects": [
       {"id": "kitchen", "type": "room", "name": "Kitchen", "exits": {"north": "living_room"}},
       {"id": "table", "type": "supporter", "location": "kitchen", "contents": ["apple"]},
       {"id": "apple", "type": "thing", "location": "table", "weight": 0.1}
     ],
     "gameState": {
       "player": {"location": "kitchen", "inventory": [], "health": 100},
       "flags": {"visited_library": false}
     }
   }
   ```

### 7.2 Architecture Layers

```
┌─────────────────────────────────────────┐
│         Mobile UI Layer                  │  (Touch input, buttons, status bar)
├─────────────────────────────────────────┤
│         Parser Layer                     │  (Tokenize, resolve objects, dispatch)
├─────────────────────────────────────────┤
│       ECS/State Layer (Optional)         │  (Components: Position, Inventory, Physics, etc.)
├─────────────────────────────────────────┤
│      Game Logic Layer                    │  (Verb handlers, rules, state mutations)
├─────────────────────────────────────────┤
│    Containment Tree + Graph Rooms        │  (Parent pointers, location tree, room exits)
├─────────────────────────────────────────┤
│    Persistence Layer                     │  (Save/load JSON, undo snapshots)
├─────────────────────────────────────────┤
│    Mobile Storage (SQLite / JSONFiles)   │  (Local storage, optional cloud sync)
└─────────────────────────────────────────┘
```

### 7.3 File Structure Suggestion

```
src/
├── game/
│   ├── world.ts              # World root, room/object graph
│   ├── object.ts             # GameObject base class
│   ├── room.ts               # Room with exits
│   ├── container.ts          # Container logic (weight, capacity)
│   └── actor.ts              # Player character
├── parser/
│   ├── tokenizer.ts          # Tokenize input
│   ├── resolver.ts           # Resolve objects in current context
│   └── dispatcher.ts         # Route to verb handlers
├── handlers/
│   ├── take.ts               # Handle "take" command
│   ├── open.ts               # Handle "open" command
│   ├── examine.ts            # Handle "look" command
│   └── move.ts               # Handle movement ("go north", etc.)
├── state/
│   ├── game-state.ts         # Current game state
│   ├── undo-stack.ts         # Undo/redo management
│   └── serializer.ts         # Save/load
├── ui/
│   ├── mobile-ui.ts          # Touch-friendly layout
│   ├── display.ts            # Render text to screen
│   └── input.ts              # Handle user input (keyboard + buttons)
└── config/
    └── objects.json          # Object definitions (data-driven)
```

---

## 8. References & Further Reading

### Classic References
- **Zork I Source Code:** https://github.com/historicalsource/zork1
  - Game Architecture: https://deepwiki.com/historicalsource/zork1/2-game-architecture
  - Command Parsing: https://deepwiki.com/bcorfman/zorkdemo/6.4-commands-and-actions
- **Inform 7 Handbook:** https://inform-7-handbook.readthedocs.io/
  - Containers & Supporters: https://ganelson.github.io/inform-website/book/RB_8_4.html
- **TADS 3 Documentation:** http://www.tads.org/t3doc/doc/index.htm
  - Learning TADS 3: https://faroutscience.com/adv3lite_docs/learning/LearningT3Lite.pdf
  - Object Containment: https://tads.dev/docs/adv3lite/docs/tutorial/containment.htm

### Modern Frameworks
- **Twine:** https://twinery.org/
- **ChoiceScript:** https://www.choiceofgames.com/
- **Jiuzhou Engine (ECS example):** https://github.com/Jiuzhouworld/Jiuzhou-Engine-Docs
- **Libzork (Modern C++ IF Engine):** https://github.com/ibrahimoxx/libzork-engine

### Technical Articles
- **Tree Data Structure:** https://en.wikipedia.org/wiki/Tree_(abstract_data_type)
- **Graph Topology in Text Adventures:** https://arxiv.org/pdf/1911.09194
- **Memento Pattern (Undo/Redo):** https://www.devleader.ca/2024/01/29/the-memento-pattern-in-c-how-to-achieve-effortless-state-restoration
- **ECS Architecture:** https://en.wikipedia.org/wiki/Entity_component_system

### Mobile-Specific
- **Quest Documentation (Containers):** https://docs.textadventures.co.uk/quest/containers.html
- **Written Realms (Mobile-friendly IF):** https://writtenrealms.com/
- **Text Adventures on Mobile (itch.io):** https://itch.io/games/tag-interactive-fiction/tag-text-based

---

## 9. Key Takeaways for Your Mobile Project

✅ **What's Proven:**
- Parent-child tree for containment works. Don't reinvent it.
- Graph topology for rooms is the standard. Keep it simple.
- Serialization to JSON is clean and mobile-friendly.

⚠️ **Watch Out For:**
- Don't over-engineer object hierarchy; properties beat complex class trees.
- Mobile UI is harder than the engine. Plan for that.
- Heavy NLP parsing will drain battery; keep it lightweight.

💡 **Novel Opportunity:**
- Combine classical containment with ECS for state clarity.
- Use tap-buttons to reduce typing on mobile.
- Build data-driven object definitions; easier to iterate narrative.

🎯 **Next Steps:**
- Prototype the containment tree in your chosen language (TypeScript/Kotlin/Swift recommended for mobile)
- Test command parsing with a few key verbs (take, drop, examine, go)
- Measure performance on target device; optimize if needed
- Iterate on UI with real players; mobile UX is critical to enjoyment

---

**End of Report**  
*Compiled by Frink, 2026-03-18*
