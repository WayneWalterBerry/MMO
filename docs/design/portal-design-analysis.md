# Door/Portal/Exit Architecture — Game Design Analysis

**Author:** Comic Book Guy (Creative Director, Design Department Lead)  
**Date:** 2026-03-27  
**Requested by:** Wayne "Effe" Berry  
**Status:** Analysis complete — recommendation included  

> *"I have spent forty years studying interactive fiction. I have played every Infocom game, read every TADS manual, and implemented doors in seventeen different parser engines. I am — without false modesty — the single most qualified person on this team to render judgment on this matter."*

---

## Table of Contents

1. [Genre Precedent](#1-genre-precedent)
2. [Scenario-by-Scenario Comparison](#2-scenario-by-scenario-comparison)
3. [Player Experience Comparison](#3-player-experience-comparison)
4. [Designer Ergonomics Comparison](#4-designer-ergonomics-comparison)
5. [Creative Constraints Analysis](#5-creative-constraints-analysis)
6. [Recommendation](#6-recommendation)
7. [Worst. Design Decision. Ever.](#7-worst-design-decision-ever)

---

## 1. Genre Precedent

### Zork and the Infocom Era (1977–1989)

Infocom's Z-machine treated doors as **first-class objects**. In Zork I, the trap door, the rainbow, and the grating were all objects with properties — you could examine them, manipulate them, and they participated in the world model like any other thing.

The critical insight: **Infocom doors were objects that happened to gate movement**, not movement rules that happened to look like objects. When you typed `EXAMINE DOOR`, the game didn't special-case a movement exit — it found the door object in the room and described it like any other object. When you typed `OPEN DOOR`, the door's state changed, and *as a consequence*, the corresponding exit became traversable.

This wasn't accidental. The ZIL (Zork Implementation Language) had `DOOR` as an object flag. A door was just a regular `OBJECT` with the `DOORBIT` flag set, which told the engine "this object gates movement between two rooms." The door's `ACTION` routine handled OPEN, CLOSE, LOCK, UNLOCK — standard verb dispatching, same as any other object.

**Key lesson:** In Zork, the *object* was the source of truth. The exit was a consequence of the object's state.

### Inform 7 (2006–present)

Inform 7 formalized what Infocom knew intuitively. In Inform 7, a door is a **kind** (class) that inherits from `thing`:

```inform7
The oak door is a door. It is north of the Bedroom and south of the Hallway.
The oak door is closed and locked. The matching key of the oak door is the brass key.
```

Notice: the door *is* a thing. It has a location (conceptually, it spans two rooms). It can be described, examined, and interacted with. The engine uses the door's state to determine traversability — but the door is always an object first.

Inform 7 doors automatically:
- Block movement when closed
- Respond to EXAMINE, OPEN, CLOSE, LOCK, UNLOCK
- Report their state in room descriptions
- Connect exactly two rooms
- Sync state from both sides (open from either room)

**Key lesson:** Inform 7 proves that doors-as-objects is the *standard* modern IF abstraction. It's not experimental — it's the industry consensus after 30 years of iteration.

### TADS 3 (2000s)

TADS 3 has `Door` as a subclass of `Passage`, which is a subclass of `TravelConnector`, which is... not a `Thing`. This is the **one major IF framework** that treats doors as fundamentally different from objects. TADS doors are "travel connectors" — exit constructs with some object-like behavior bolted on.

The result? TADS 3 doors are famously painful to implement. The library needs special `DoorState` objects, `MasterDoor`/`SlaveDoor` pairs for two-sided doors, and a complex set of pre-conditions and verify routines. Eric Eve's TADS 3 documentation dedicates multiple pages to explaining why doors are confusing.

**Key lesson:** TADS 3 is the cautionary tale. Treating doors as *special exits* rather than *objects that gate exits* creates complexity that compounds with every new feature.

### Hugo and Other Systems

Hugo (Kent Tessman's system) also treats doors as objects with `is openable` and `is lockable` attributes. The `door_to` property links the door to a room exit.

The Adventuron system (2019+) treats exits as room constructs with inline conditions — essentially what our exit-as-room-construct approach does. It works for simple games but designers consistently report hitting walls when they want complex door interactions.

### Precedent Summary

| System | Door Model | Verdict |
|--------|-----------|---------|
| **Zork/ZIL** | Object with DOORBIT flag | Object-first ✅ |
| **Inform 6** | Object inheriting from `Door` class | Object-first ✅ |
| **Inform 7** | Kind (class) inheriting from `thing` | Object-first ✅ |
| **TADS 3** | TravelConnector subclass (not a Thing) | Exit-construct ❌ (widely criticized) |
| **Hugo** | Object with `door_to` property | Object-first ✅ |
| **Adventuron** | Exit construct with inline conditions | Exit-construct (limited) |
| **Twine/ChoiceScript** | Passage/link with conditions | N/A (not parser IF) |

**Verdict:** 40 years of IF design converge on one answer: doors are objects. The only major system that disagreed (TADS 3) is widely regarded as having gotten doors wrong.

---

## 2. Scenario-by-Scenario Comparison

For each scenario, I describe how a designer would implement it under both approaches.

### Approach A: Exit-as-Room-Construct
Doors live entirely in `room.exits[direction]` with inline state flags, mutations, and conditions. No separate object file.

### Approach B: Door-as-Object
Doors are full objects (.lua files) with templates, FSM states, sensory properties, and linked_exit references. The exit in the room file is a thin connection that defers to the object.

---

### Scenario 1: A Door That Requires a Specific Key

**Exit-Construct:**
```lua
exits = {
    north = {
        type = "door", name = "an iron door",
        locked = true, key_id = "brass-key",
        mutations = {
            unlock = { becomes_exit = { locked = false }, message = "Click." },
            open = { condition = function(self) return not self.locked end,
                     becomes_exit = { open = true }, message = "It opens." }
        }
    }
}
```
Simple. Works. But: Can the player EXAMINE the lock? FEEL the keyhole? LISTEN at the door? Not without adding `on_examine`, `on_feel`, `on_listen` to the exit table — which starts looking like... an object definition.

**Door-Object:**
```lua
-- iron-door.lua
return {
    template = "furniture", id = "iron-door",
    linked_exit = "north",
    material = "iron",
    on_feel = "Cold iron. Your fingers find a keyhole.",
    on_listen = "Silence beyond, then a draft.",
    on_smell = "Rust and oil.",
    initial_state = "locked",
    states = {
        locked = { ... }, unlocked = { ... }, open = { ... }
    },
    transitions = {
        { from = "locked", to = "unlocked", verb = "unlock", requires_tool = "brass-key" }
    }
}
```
Room exit is thin: `north = { target = "hallway", door_object = "iron-door" }`. All behavior lives in the object.

**Winner:** 🏆 **Door-Object.** The sensory richness is free. The designer writes it once and every verb works.

---

### Scenario 2: A Secret Passage Behind a Bookcase

**Exit-Construct:**
```lua
-- In room exits:
east = { target = "secret-room", type = "passage", hidden = true,
         name = "a narrow passage" }

-- Bookcase object has: reveals_exit = "east"
-- When bookcase state changes (pull book, push bookcase), exit.hidden = false
```
This actually works well. The bookcase is the object; the passage itself doesn't need to be interactive.

**Door-Object:**
```lua
-- secret-passage.lua
return {
    id = "secret-passage", hidden = true,
    linked_exit = "east",
    on_feel = "Cool air flows from between the stones.",
    on_listen = "A faint echo beyond.",
    states = { hidden = { ... }, revealed = { ... } }
}
```
Bookcase still triggers the reveal, but now the passage itself has sensory properties. A player pressing their hand against the wall can *feel* the draft — a clue that something is there before they find the trigger.

**Winner:** 🏆 **Door-Object.** The sensory clue system is critical. In darkness, a player FEELING the wall and discovering a cold draft is exactly the kind of multi-sensory gameplay we've designed this engine for. Exit-constructs can't provide that.

---

### Scenario 3: A Drawbridge That Raises/Lowers on a Timer

**Exit-Construct:**
```lua
south = {
    type = "drawbridge", name = "a massive drawbridge",
    open = true,  -- starts lowered
    on_traverse = { ... },
    -- Timer? Where does it live? Exit tables don't have timers.
    -- Need custom engine code or a separate timer system that
    -- reaches into room.exits to toggle state.
}
```
Problem: Our FSM timer system works on *objects*. Exit tables don't participate in the FSM engine. You'd need custom code to periodically mutate an exit's state — violating Principle 8 (engine executes metadata, no object-specific code).

**Door-Object:**
```lua
-- drawbridge.lua
return {
    id = "drawbridge", linked_exit = "south",
    initial_state = "lowered",
    states = {
        lowered = { traversable = true, room_presence = "The drawbridge extends..." },
        raised  = { traversable = false, room_presence = "The drawbridge is raised high..." }
    },
    transitions = {
        { from = "lowered", to = "raised", verb = "_timer", delay = 300 },
        { from = "raised", to = "lowered", verb = "_timer", delay = 120 }
    }
}
```
The FSM handles timers. The engine handles timers. Nobody writes custom code.

**Winner:** 🏆 **Door-Object.** Not even close. Timed behavior requires FSM, and exits don't have FSM.

---

### Scenario 4: A Teleportation Circle

**Exit-Construct:**
```lua
-- Teleportation circles aren't directional. Which direction key?
-- "enter"? "step"? We'd need a non-directional exit type.
enter = {
    type = "teleportation_circle", name = "a glowing circle",
    target = "wizard-tower", open = true,
    on_traverse = { magic_effect = { message = "The world dissolves..." } }
}
```
Awkward. Exits are inherently directional (north, south, up, down). A teleportation circle is a *thing in the room* you interact with, not a compass direction. Having it as `enter` works but feels bolted on.

**Door-Object:**
```lua
-- teleportation-circle.lua
return {
    id = "teleportation-circle",
    linked_exit = "enter",  -- or a custom action
    on_look = "A circle of runes glows faintly on the floor.",
    on_feel = "The stone hums under your fingers. The runes are warm.",
    on_listen = "A low thrumming, like a distant heartbeat.",
    states = {
        dormant = { traversable = false, room_presence = "A circle of dark runes..." },
        active  = { traversable = true, room_presence = "A circle of runes pulses with light..." }
    },
    transitions = {
        { from = "dormant", to = "active", verb = "activate", requires_tool = "wizard-staff" }
    }
}
```
The circle IS an object in the room. Players examine it, feel it, try things with it. It just *also* gates movement.

**Winner:** 🏆 **Door-Object.** Teleporters are objects first, exits second.

---

### Scenario 5: A Collapsing Tunnel (One-Way, Destroys After Passage)

**Exit-Construct:**
```lua
north = {
    type = "tunnel", name = "a narrow tunnel",
    one_way = true, open = true,
    on_traverse = {
        collapse_effect = {
            message = "Rocks crash down behind you!",
            -- But how do we destroy this exit after traversal?
            -- Need: becomes_exit = { destroyed = true }?
            -- Or: remove the exit entirely?
        }
    }
}
```
The `on_traverse` fires before movement, so we can modify the exit. But destroying exits at traversal time is edge-case engine logic. Does the engine know about `destroyed`? What if the player tries to go back?

**Door-Object:**
```lua
-- collapsing-tunnel.lua
return {
    id = "collapsing-tunnel",
    linked_exit = "north",
    on_feel = "The rock is crumbling. Pebbles shower down.",
    on_listen = "Groaning stone. This tunnel is unstable.",
    initial_state = "passable",
    states = {
        passable = { traversable = true, room_presence = "A narrow tunnel leads north..." },
        collapsed = {
            traversable = false,
            room_presence = "A pile of rubble blocks the north tunnel.",
            on_feel = "Jagged rock and dust. Impassable.",
            mutations = { clear = { requires_tool = "pickaxe", becomes = "tunnel-cleared" } }
        }
    },
    on_traverse = function(self) self:transition("collapsed") end
}
```
The tunnel is an object. It has a collapsed state with its own sensory descriptions. A designer could even add a mutation to *clear* the rubble with a pickaxe. Exit-constructs can't dream of that level of design space.

**Winner:** 🏆 **Door-Object.** The collapsed state is rich content, not just a boolean.

---

### Scenario 6: A Door That Talks / Asks a Riddle

**Exit-Construct:**
```lua
west = {
    type = "door", name = "a carved stone door",
    locked = true,
    -- How does an exit talk? Where does dialogue live?
    -- on_approach? on_interact? Custom verb?
    -- This doesn't fit the exit model AT ALL.
}
```
Exit-constructs have no mechanism for dialogue, conditional responses, or multi-turn interactions. You'd need to create a separate NPC or object for the "talking" part and sync it with the exit — at which point, why not just make the door an object?

**Door-Object:**
```lua
-- riddle-door.lua
return {
    id = "riddle-door",
    linked_exit = "west",
    on_listen = "A low voice rumbles from the stone: 'Speak, friend, and enter.'",
    on_feel = "Warm stone. The carvings vibrate faintly.",
    states = {
        sealed = {
            room_presence = "A carved stone door blocks the west passage.",
            on_knock = "A voice booms: 'What has roots nobody sees, is taller than trees...'"
        },
        answered = {
            room_presence = "The stone door stands open, its carvings quiet.",
            traversable = true
        }
    },
    transitions = {
        { from = "sealed", to = "answered", verb = "say",
          requires_input = "mountain",
          message = "The door rumbles: 'Correct.' The stone slides aside." }
    }
}
```

**Winner:** 🏆 **Door-Object.** This scenario is impossible with exit-constructs. Full stop. A talking door is an object with behavior — it's the *definition* of what our object system does.

---

### Scenario 7: A Portcullis Requiring a Lever in Another Room

**Exit-Construct:**
```lua
-- courtyard.lua
north = {
    type = "portcullis", name = "an iron portcullis",
    open = false, locked = true,
    -- The lever is in the gatehouse. How does a lever in room B
    -- affect an exit in room A? The exit has no GUID, no identity
    -- that a lever can reference. Need custom engine code.
}
```
This is the fundamental limitation. Exits are anonymous inline tables scoped to a single room. They have no identity that can be referenced from elsewhere. A lever in the gatehouse would need to reach into the courtyard's exit table by room ID + direction key — brittle coupling that violates every good design principle.

**Door-Object:**
```lua
-- portcullis.lua (exists in courtyard, registered in universe)
return {
    id = "portcullis", guid = "{...}",
    linked_exit = "north",
    initial_state = "lowered",
    states = {
        lowered = { traversable = false, room_presence = "A heavy iron portcullis blocks..." },
        raised  = { traversable = true, room_presence = "The portcullis is raised..." }
    },
    transitions = {
        { from = "lowered", to = "raised", trigger = "portcullis_raise" }
    }
}

-- lever.lua (in gatehouse room)
return {
    id = "gatehouse-lever",
    transitions = {
        { from = "down", to = "up", verb = "pull",
          emits = "portcullis_raise",
          message = "You hear grinding chains from the courtyard." }
    }
}
```
Objects have GUIDs. Objects can emit triggers. Objects can reference other objects. This is what the registry is for.

**Winner:** 🏆 **Door-Object.** Remote interaction is a fundamental puzzle pattern. Exits can't participate.

---

### Scenario 8: A Window You Can Look Through But Not Walk Through (Until Broken)

**Exit-Construct:**
```lua
south = {
    type = "window", name = "a tall window",
    open = false,  -- blocks traversal
    -- LOOK THROUGH WINDOW → What verb? What handler?
    -- We already have this in start-room.lua, and it works...
    -- BUT: Can you FEEL the glass? SMELL the outside air?
    description = "A tall window overlooking the courtyard.",
    mutations = {
        ["break"] = {
            becomes_exit = { type = "broken window", open = true, broken = true },
            spawns = { "glass-shard" }
        }
    }
}
```
This partially works because our current system already has windows as exits. But the sensory interaction is limited. Adding `on_feel`, `on_smell`, `on_listen` to every exit table is ad hoc.

**Door-Object:**
```lua
-- tall-window.lua
return {
    id = "tall-window",
    linked_exit = "south",
    material = "glass",
    on_look = "Through the glass: the courtyard, bathed in moonlight.",
    on_feel = "Cold glass, slightly fogged with condensation.",
    on_listen = "The wind whistles through a gap in the frame.",
    on_smell = "A faint draft carries the scent of wet stone.",
    states = {
        intact = {
            traversable = false,
            can_see_through = true,
            room_presence = "A tall window overlooks the south courtyard."
        },
        broken = {
            traversable = true,
            on_feel = "Jagged glass teeth ring the frame.",
            on_traverse_effect = { type = "inflict_injury", injury_type = "minor-cut" },
            room_presence = "A broken window gapes in the south wall. Glass crunches underfoot."
        }
    }
}
```
The `can_see_through` property lets the engine know LOOK works through this object even when it blocks traversal. The broken state has its own `on_feel` and inflicts cuts during traverse. Every state change produces rich, sensory content.

**Winner:** 🏆 **Door-Object.** Windows are the poster child for "objects that gate movement." They're lookable, touchable, breakable, and climbable. Exit-constructs treat them as passages with special rules; objects treat them as *things in the world*.

---

### Scenario 9: A Door That's Also a Puzzle (Combination Lock)

**Exit-Construct:**
```lua
east = {
    type = "door", name = "a vault door with three dials",
    locked = true,
    -- Three separate dials that each need to be set correctly?
    -- Where does the dial state live? Exit tables are flat.
    -- dial_1 = 0, dial_2 = 0, dial_3 = 0, combination = {3, 7, 1}?
    -- Custom unlock logic? Inline functions?
    mutations = {
        unlock = {
            condition = function(self)
                return self.dial_1 == 3 and self.dial_2 == 7 and self.dial_3 == 1
            end,
            becomes_exit = { locked = false }
        }
    }
}
```
You *can* do it with inline functions, but now you're embedding arbitrary state and logic in an exit table. The dials aren't objects — the player can't EXAMINE DIAL, TURN DIAL, FEEL DIAL. It's all hidden behind `UNLOCK DOOR`.

**Door-Object:**
```lua
-- vault-door.lua
return {
    id = "vault-door",
    linked_exit = "east",
    composite_parts = {
        { id = "dial-1", type_id = "{guid-dial}", ... },
        { id = "dial-2", type_id = "{guid-dial}", ... },
        { id = "dial-3", type_id = "{guid-dial}", ... },
    },
    on_feel = "Three brass dials, cool to the touch. Each clicks when turned.",
    on_listen = "Faint ticking from inside the mechanism.",
    states = {
        locked = { room_presence = "A heavy vault door dominates the east wall..." },
        unlocked = { room_presence = "The vault door stands ajar..." }
    }
}
```
Each dial is a nested object with its own state (0–9). Players interact with individual components. The vault door checks its children's state to determine if the combination is correct. This is Principle 4 (Composite Encapsulation) in action.

**Winner:** 🏆 **Door-Object.** Puzzle doors require object depth. Combination locks, sliding tile puzzles, musical locks — all need component interaction that exit-constructs can't model.

---

### Scenario 10: A Door That Changes Destination Based on Time of Day

**Exit-Construct:**
```lua
north = {
    type = "magical_door", name = "a shimmering door",
    open = true,
    target = function(ctx) 
        if ctx.time.is_day then return "garden" else return "shadow-garden" end
    end,
    -- Or: target = "garden", alt_target = "shadow-garden", alt_condition = "nighttime"
}
```
Functional targets are possible but mean embedding functions in exit tables. The engine's movement handler needs to evaluate `target` as either a string or a function. More special cases, more complexity.

**Door-Object:**
```lua
-- shimmer-door.lua
return {
    id = "shimmer-door",
    linked_exit = "north",
    on_look = "The door's surface shifts like oil on water.",
    on_feel = "Warm in daylight. Ice-cold at night.",
    states = {
        daytime = { target = "garden", room_presence = "A shimmering door pulses with warm light." },
        nighttime = { target = "shadow-garden", room_presence = "A shimmering door ripples with cold darkness." }
    },
    transitions = {
        { from = "daytime", to = "nighttime", trigger = "time_dusk" },
        { from = "nighttime", to = "daytime", trigger = "time_dawn" }
    }
}
```
The door's FSM responds to time-of-day triggers. Each state has its own target, its own room_presence, its own sensory descriptions. The engine doesn't need to know about time-conditional targets — it just reads the current state's `target` field.

**Winner:** 🏆 **Door-Object.** Temporal behavior belongs in FSM states. Exit-constructs would need inline functions, which are un-serializable and un-inspectable.

---

### Scenario Summary Table

| # | Scenario | Exit-Construct | Door-Object | Winner |
|---|----------|---------------|-------------|--------|
| 1 | Key-locked door | ✅ Works (flat) | ✅ Works (richer) | Object |
| 2 | Secret passage | ⚠️ Works (no clues) | ✅ Sensory clues | Object |
| 3 | Timed drawbridge | ❌ No FSM timers | ✅ FSM handles it | Object |
| 4 | Teleportation circle | ⚠️ Awkward direction | ✅ Natural | Object |
| 5 | Collapsing tunnel | ⚠️ Shallow state | ✅ Rich collapse state | Object |
| 6 | Talking/riddle door | ❌ No mechanism | ✅ Full interaction | Object |
| 7 | Remote lever + portcullis | ❌ No identity/ref | ✅ GUID + triggers | Object |
| 8 | Look-through window | ⚠️ Partial | ✅ Full sensory | Object |
| 9 | Combination lock door | ⚠️ Flat state only | ✅ Composite parts | Object |
| 10 | Time-varying destination | ⚠️ Inline functions | ✅ FSM states | Object |

**Score: Exit-Construct 0 — Door-Object 10.**

I would like to note for the record that this is not even a contest. It is like comparing a Commodore 64 to a gaming PC and asking which one runs Elden Ring.

---

## 3. Player Experience Comparison

### Can Players Use Their Senses on Doors?

Our game starts at 2 AM in total darkness. The *entire design philosophy* is that players navigate by touch, smell, and sound before finding light. Doors are among the most important objects players encounter in darkness.

| Interaction | Exit-Construct | Door-Object |
|-------------|---------------|-------------|
| EXAMINE door | ⚠️ Need `description` in exit | ✅ Object `description` |
| FEEL door | ⚠️ Need `on_feel` in exit | ✅ Object `on_feel` (required!) |
| LISTEN at door | ⚠️ Need `on_listen` in exit | ✅ Object `on_listen` |
| SMELL door | ❌ Never implemented | ✅ Object `on_smell` |
| TASTE door | ❌ Never implemented | ✅ Object `on_taste` (lick the keyhole?) |
| KNOCK on door | ❌ Not a verb on exits | ✅ Object `on_knock` |
| PUSH/PULL door | ❌ Not standard exit verbs | ✅ Object verb dispatch |
| PEEK through keyhole | ❌ Impossible | ✅ Object interaction |

**The sensory system IS the game.** Every object must have `on_feel`. That's Principle 6 and our core design directive. If doors are exit-constructs, they bypass the entire sensory pipeline. A player in the dark feels along the wall and encounters... nothing. No door. No texture. No temperature. Because the exit isn't an object in sensory space.

### Can Players Interact with Door Hardware?

Doors have parts. Hinges. Locks. Keyholes. Handles. Bars. Knockers. In a rich text adventure, these are interaction targets:

- `EXAMINE HINGES` → "The hinges are on the outside. You could remove the pins."
- `OIL HINGES` → Removes the squeaking that alerts the guard.
- `LOOK THROUGH KEYHOLE` → See into the next room.
- `FEEL LOCK` → "A complex mechanism. This needs more than a simple key."

With exit-constructs, none of this is possible. Hinges, locks, and handles don't exist as entities. With door-objects, they can be composite parts (Principle 4) or keyword-triggered interactions.

### Room Presence

Door-objects have `room_presence` fields that change with state:
- Barred: *"A heavy oak door stands in the north wall, barred with an iron beam."*
- Open: *"The north doorway stands open, revealing a dim hallway."*
- Broken: *"Splintered wood hangs from the north doorframe."*

Exit-constructs can have descriptions, but they don't participate in the room's composed description the same way objects do. The engine already composes room descriptions from object `room_presence` fields — doors should use the same system, not a parallel one.

### Darkness Gameplay

This is the dealbreaker.

When the game starts at 2 AM, players are in total darkness. They FEEL around the room. They discover the nightstand, the bed, the rug. At some point, they feel along the wall and find... what?

- **Exit-construct:** The engine reports "There is an exit to the north" — a game-mechanical statement that breaks immersion. Or worse, it says nothing, because exits aren't physical things that respond to FEEL.
- **Door-object:** *"Your hand finds rough oak. Iron bands cross the surface. The wood is cold. You feel a heavy bar across the door's width."*

The entire reason this engine exists — the multi-sensory darkness gameplay — requires doors to be objects.

---

## 4. Designer Ergonomics Comparison

### Files Per Door

| Approach | Files | Effort |
|----------|-------|--------|
| **Exit-Construct** | 0 extra files. Door data is inline in room .lua | Low initial effort |
| **Door-Object** | 1 object .lua file + thin exit reference in room | Moderate initial effort |

Exit-constructs win on *initial* effort. But how often do you create a door versus modify one? In my experience with IF development, doors are modified 5–10× more often than they're created. Templates reduce creation cost to near-zero for door-objects.

### Adding a New Door Type

**Exit-Construct:** Copy-paste exit block, modify inline. Quick, but:
- No template inheritance
- Every exit is a bespoke snowflake
- Changes to "how doors work" require finding and editing every room file

**Door-Object:** Copy a template, customize:
```lua
-- Copy from door-template.lua, customize:
return {
    template = "door",           -- inherit standard door behavior
    id = "iron-gate",
    material = "iron",
    linked_exit = "north",
    on_feel = "...",             -- customize sensory
    initial_state = "locked",   -- set starting state
}
```
Template inheritance means standard door behavior (open/close/lock/unlock FSM) comes free. Designers customize only what's unique.

### Boilerplate Comparison

**Exit-Construct boilerplate** (from start-room.lua, the current implementation):
```lua
north = {
    target = "hallway",
    type = "door",
    passage_id = "bedroom-hallway-door",
    name = "a heavy oak door",
    keywords = {"door", "oak door", "heavy door", ...},
    description = "...",
    max_carry_size = 4, max_carry_weight = 50,
    requires_hands_free = false, player_max_size = 5,
    open = false, locked = true, key_id = nil,
    hidden = false, broken = false,
    one_way = false, breakable = true, break_difficulty = 3,
    on_traverse = { ... },
    mutations = {
        open = { condition = ..., becomes_exit = { ... }, message = "..." },
        close = { becomes_exit = { ... }, message = "..." },
        unlock = { becomes_exit = { ... }, message = "..." },
        lock = { becomes_exit = { ... }, message = "..." },
        ["break"] = { becomes_exit = { ... }, spawns = {...}, message = "..." }
    }
}
```
That's ~40 lines of boilerplate for ONE exit in ONE room. And this is **without** sensory properties. Our current start-room.lua exit definitions are already 150+ lines for the north door alone.

**Door-Object boilerplate:**
```lua
-- Room file (thin):
north = { target = "hallway", door_object = "bedroom-door" }

-- Object file (reusable, template-inheriting):
return {
    template = "door",
    id = "bedroom-door",
    material = "oak",
    linked_exit = "north",
    -- Everything else inherited from template
}
```
The room file shrinks to one line per exit. The door object uses template inheritance for standard behavior.

### Moe vs. Flanders Workflow

**Moe (room builder)** prefers:
- Simple room files focused on spatial layout
- Not writing 150 lines of door mutation logic per exit
- Referencing doors by ID, not inlining their behavior

**Flanders (object builder)** prefers:
- Object .lua files he can test independently
- Template inheritance for standard behavior
- Sensory properties as first-class fields

**With exit-constructs:** Moe is forced to be both a room builder AND a door designer. Every room file becomes a door definition file. Moe doesn't want to write FSM transitions and mutation tables — that's Flanders' job.

**With door-objects:** Moe writes `north = { target = "hallway", door_object = "iron-door" }`. Flanders writes `iron-door.lua` with full behavior. Clean separation of concerns.

---

## 5. Creative Constraints Analysis

### What Can't Designers Do with Exit-Constructs?

1. **No remote interaction.** A lever in room B cannot affect an exit in room A because exits have no GUIDs and aren't in the registry. This eliminates an entire category of puzzles (portcullis, drawbridge, gate mechanism, remote locks).

2. **No composite parts.** Exit-constructs can't have sub-objects (hinges, locks, knockers, peepholes). This eliminates hardware interaction puzzles.

3. **No FSM timers.** Exits don't participate in the FSM engine, so no timed behavior (auto-closing doors, drawbridges, timed locks).

4. **No trigger system.** Objects emit and receive triggers. Exits don't. So exits can't participate in event chains (clock strikes midnight → secret door opens).

5. **No material properties.** Exit-constructs don't inherit from the material system. A wooden door and an iron door have the same burn/break/cut behavior unless manually specified. With door-objects, `material = "oak"` automatically gives the door wood's hardness, fragility, flammability, and weight.

6. **No mutation (D-14).** The Prime Directive says code mutation IS state change. Exits aren't code files — they're inline tables. They can't be mutated in the D-14 sense. A broken door can't literally *become* a different file. This is a **philosophical violation** of the project's core principle.

7. **No factory instancing.** The D-OBJECT-INSTANCING-FACTORY creates multiple instances from one base object. Exits can't participate — every exit is hand-crafted inline.

8. **No search/traverse.** The search engine (`traverse.lua`) finds objects by keyword, relationship, and location. It doesn't search exits. Players can't `SEARCH FOR DOOR` and find an exit.

9. **No wear and tear.** Objects can accumulate damage states (D-14 mutation). A door that gets kicked repeatedly can progress through intact → dented → cracked → broken. Exits have a `broken` boolean — one bit of state.

10. **No sensory gating (D-CONTAINER-SENSORY-GATING).** Our decision requires objects to gate sensory information based on container state (closed container blocks LOOK but not LISTEN). Exit-constructs don't participate in this system.

### What Can't Designers Do with Door-Objects?

1. **Slightly more files to manage.** One extra .lua file per unique door type (not per door instance — templates + factory handle that).

2. **Two places to check.** When debugging a door, you check both the room file (exit reference) and the object file (behavior). With exit-constructs, everything is in one place.

That's it. Those are the only downsides. Two. Compared to ten.

---

## 6. Recommendation

### Doors Must Be First-Class Objects

I am rendering my judgment with the full authority of forty years of interactive fiction expertise and an encyclopedic knowledge of game design that would make Graham Nelson weep with envy.

**Doors should be first-class objects.**

The evidence is overwhelming:

1. **Genre precedent:** Zork, Inform 6, Inform 7, Hugo — all treat doors as objects. The one system that didn't (TADS 3) is the cautionary tale.

2. **Scenario analysis:** Door-objects won all 10 scenarios. Exit-constructs couldn't even participate in 3 of them (talking doors, remote levers, timed drawbridges).

3. **Core principles alignment:**
   - **Principle 1 (Code-Derived Mutable Objects):** Objects are .lua files. Doors should be .lua files.
   - **Principle 3 (FSM):** Doors have states and transitions. Only objects participate in FSM.
   - **Principle 4 (Composite Encapsulation):** Doors have parts (locks, hinges). Only objects support composition.
   - **Principle 6 (Sensory Space):** Every object needs `on_feel`. Exits don't have sensory fields by default.
   - **Principle 7 (Spatial Relationships):** Doors exist in physical space. They should be in the object graph.
   - **Principle 8 (Engine Executes Metadata):** Exit-specific engine code violates this. Object FSM is generic.
   - **Principle 9 (Material Consistency):** Doors have materials (oak, iron). Only objects inherit material properties.
   - **D-14 (Code Mutation):** The Prime Directive. Doors should mutate like objects.

4. **Player experience:** The entire sensory system — the thing that makes this game special — requires doors to be objects.

5. **Designer ergonomics:** Template inheritance + thin exit references is LESS boilerplate than inline exit definitions with mutations.

### Recommended Architecture

```
Room File (thin exits):
    north = { target = "hallway", door_id = "bedroom-door" }

Door Object (full behavior):
    bedroom-door.lua → template = "door", material = "oak", FSM, sensory, mutations

Door Template:
    door.lua → standard open/close/lock/unlock FSM, default sensory, material inheritance

Engine:
    Movement handler checks door_id → gets object → checks traversable state
    Verb handlers (open/close/lock/unlock) dispatch to object FSM
    No exit-specific mutation code needed
```

### Migration Path

I am not suggesting we burn the current exit system to the ground tomorrow. The current exit-constructs work for Level 1, and we're heading toward playtesting.

**Phase 1 (Now):** Keep existing exits working. Document the door-object pattern.  
**Phase 2 (Post-playtest):** Create `door` template. Migrate bedroom-door (already has an object file) to thin-exit pattern.  
**Phase 3:** Migrate remaining exits. Remove exit-inline mutation code.  
**Phase 4:** All doors are objects. Exit tables are thin references only.

---

## 7. Worst. Design Decision. Ever.

### If We Choose Exit-Constructs Only

The biggest risk is **creative ceiling**. Within 2–3 levels, designers will hit a wall. Every interesting door puzzle — combination locks, remote mechanisms, talking doors, timed gates, composite hardware — requires object features. Designers will start hacking around the exit system with companion objects, creating the dual-system mess we already have, but without a clean architecture to support it.

The exit system becomes a growing ball of special cases. Every new door type needs new exit mutation logic in the engine. Principle 8 dies a slow death. The codebase accumulates `if exit.type == "portcullis" then` branches until someone rewrites it.

**Worst case:** We ship Level 2 with only simple doors because complex ones are too hard to implement. Players notice. The game feels shallow. "I've seen richer door interactions in Zork, and that was 1980." That's the kind of thing *I* would say about someone else's game, and I refuse to let it be said about ours.

### If We Choose Door-Objects Only

The biggest risk is **migration complexity and sync bugs**. The current system has exit-constructs with inline state. Migrating to door-objects means: (a) creating object files for every existing door, (b) modifying room files to use thin references, (c) ensuring the engine's movement handler consults door objects instead of exit state, and (d) testing that every existing door interaction still works.

The sync problem: door object state and exit traversability must stay in sync. If the door object says "open" but the exit says "closed," the player either walks through a closed door or is blocked by an open one. This requires either: (a) the exit always defers to the object (object is source of truth), or (b) a sync mechanism that's never out of date.

**Worst case:** A sync bug ships to playtesting. A player unlocks a door but can't walk through it, or walks through a locked door. Both are game-breaking. The bug is hard to reproduce because it depends on which system was updated last.

**Mitigation:** Make the object the SOLE source of truth. Exit tables contain only `target` and `door_id`. No state in exits. Movement handler reads `door_object.traversable` directly. Zero sync needed because there's only one source of state.

---

## Appendix: Current State Assessment

Our codebase already has both systems, awkwardly coexisting:

1. **Exit-constructs** in room files with 150+ lines of inline door logic
2. **Door objects** like `bedroom-door.lua` with full FSM, sensory properties, and `linked_exit`
3. **No sync mechanism** — door object state and exit state are independent
4. **Duplicate data** — door description in exit AND in object, keywords in exit AND in object

This is the worst of both worlds. We have the complexity of two systems without the benefits of either. The current `bedroom-door.lua` object is the RIGHT idea — but it's a decoration. The engine still reads exit state for movement decisions.

The path forward is clear: promote the door-object pattern from "optional companion" to "source of truth." The exit table becomes what it should always have been — a thin routing table that says "north goes to hallway" and nothing more.

---

*Respectfully submitted by someone who has literally played every text adventure worth playing and several that were not.*

— Comic Book Guy  
*Creative Director, Design Department Lead*
