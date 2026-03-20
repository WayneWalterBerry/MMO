# Composite & Detachable Object System Design

**Date:** 2026-03-25  
**Designer:** Comic Book Guy (Game Design)  
**Status:** Design Complete (Ready for Implementation)  
**Approval:** Wayne Berry (Lead Designer)

---

## Executive Summary

An object in MMO is not always a single, indivisible thing. A nightstand has a drawer. A poison bottle has a cork. A four-poster bed has curtains. These **sub-objects (parts) can sometimes be detached**, becoming independent objects in the world. The critical insight: **one `.lua` file defines the parent AND all its parts**. When a part detaches, the engine instantiates it as a new object in the game world, and the parent transitions to a new state.

This document defines:
1. The **composite object model** — how parts nest within a parent
2. The **detachment mechanics** — how parts become independent
3. The **single-file architecture** — how one Lua file contains parent + all parts
4. The **state model** — parent state changes reflect part detachment
5. The **verb system** — which actions trigger detachment
6. The **part inheritance** — properties and reversibility
7. The **two-handed carry system** — interactions with hand slots
8. Complete implementation examples and edge cases

---

## 1. Composite Object Model: Architecture

### 1.1 Core Concept

A **composite object** is a parent object that logically contains 0 or more **detachable parts**. Each part:
- Has a unique ID within the parent's namespace (e.g., `drawer` inside `nightstand`)
- Has its own sensory descriptions (FEEL, SMELL, TASTE, LOOK, LISTEN)
- Has its own properties (weight, size, keywords, portable, etc.)
- Can be accessed/manipulated before detachment
- **Can be detached to become an independent object** in the world

A **non-detachable part** is simply a sub-object that exists for description/interaction but cannot be separated (e.g., a nightstand's legs, which are permanently part of the structure).

### 1.2 Single-File Architecture

All parts are defined in **one parent file**. Example: `nightstand.lua` defines:

1. **Parent metadata** (the nightstand itself)
   - id, name, description, weight, size, keywords, etc.
   - Sensory descriptions (on_feel, on_smell, on_look, etc.)
   - Initial state and FSM (if applicable)

2. **Parts table** — each detachable part
   ```lua
   parts = {
       drawer = { id = "nightstand-drawer", ... },
       -- future: mirror = { id = "nightstand-mirror", ... }
   }
   ```

3. **Part factories** — functions to instantiate parts into the world
   - Called when `detach_part("drawer")` is invoked
   - Return a full object instance with location, state, etc.

4. **Transition rules** — state changes when parts detach
   - Parent FSM rules: `closed_with_drawer` → `closed_without_drawer`
   - New descriptions, sensory text, surfaces, capabilities

### 1.3 Detachable Parts vs. Non-Detachable

**Detachable part example:**
```lua
parts = {
    drawer = {
        id = "nightstand-drawer",
        detachable = true,  -- KEY FLAG
        keywords = {"drawer"},
        name = "a small drawer",
        description = "A shallow wooden drawer, about 12 inches wide.",
        size = 3,
        weight = 2,
        -- ... full object properties
        factory = function(parent) return { ... } end
    }
}
```

**Non-detachable part example:**
```lua
parts = {
    legs = {
        id = "nightstand-legs",
        detachable = false,  -- Cannot be taken
        keywords = {"leg", "legs", "wooden legs"},
        name = "four wooden legs",
        description = "Sturdy wooden legs carved from matching pine.",
        -- for description/examination only, not interaction
    }
}
```

---

## 2. Detachment Mechanics: From Part to Object

### 2.1 The Detachment Flow

When a player issues a detachment command (e.g., `PULL DRAWER`):

1. **Parser recognizes the verb and target part** (e.g., PULL → `detach_verb`, target = drawer)
2. **Engine checks preconditions:**
   - Is the part `detachable = true`?
   - Is the parent in a state that allows detachment? (some FSM states may lock parts)
   - Does the parent's `can_detach_part(part_id)` callback return true?
3. **Factory instantiates the part as an independent object**
   - Calls `parts.drawer.factory(parent)` → returns a complete object instance
   - This instance has all properties: id, keywords, description, size, weight, etc.
   - The instance is placed in the parent's location (same room)
4. **Parent transitions to a new state**
   - FSM rule: `closed_with_drawer` → `closed_without_drawer`
   - Parent's description updates: "The drawer is gone."
   - Parent's surfaces change: `inside` becomes empty/inaccessible
5. **Detached part is now independent**
   - Player can TAKE, EXAMINE, PUT IN (containers), etc.
   - Part is no longer associated with parent

### 2.2 Detached Part Identity

When a drawer is detached from a nightstand, **what is it?**

**Option A: Unique sub-type**
- The drawer IS a unique object: `nightstand-drawer`
- It has its own ID, keywords, full description
- It's placed in the room as a new inventory item
- Player can carry it, examine it, put things in it (if it's a container)

**Option B: Generic "drawer" object**
- Too generic; loses context
- Not recommended for richness

**We choose Option A.** Each detachable part is a **named sub-type** with full object properties.

### 2.3 Detachment Examples

#### Example 1: Pulling a Drawer from a Nightstand

**Before:**
```
Nightstand (state: closed_with_drawer)
├── top surface (capacity 3)
├── drawer (inaccessible inside)
└── non-detachable parts (legs, wood grain, etc.)
```

**Command:** `PULL DRAWER`

**Processing:**
1. Parser: verb = "pull", target = "drawer" (part within nightstand)
2. Precondition check:
   - nightstand.parts.drawer.detachable == true ✓
   - nightstand:can_detach_part("drawer") → state == "closed_with_drawer" ✓
3. Factory call: `nightstand.parts.drawer.factory(nightstand)` 
   - Returns a complete `nightstand-drawer` object instance
   - location = nightstand.location (same room as parent)
4. FSM transition: closed_with_drawer → closed_without_drawer
   - Description: "...its drawer is gone from the front."
   - surfaces.inside → empty, inaccessible
   - on_feel: "Smooth wooden surface...the drawer slot is empty."
5. Room updates:
   - Parent still exists (nightstand without drawer)
   - New object appears: a portable nightstand-drawer

**After:**
```
Room:
  - nightstand (state: closed_without_drawer, drawer gone)
  - nightstand-drawer (portable, independent object)
```

#### Example 2: Uncorking a Bottle

**Before:**
```
Poison-Bottle (state: sealed)
├── cork (detachable)
└── liquid inside (non-detachable part of sealed state)
```

**Command:** `UNCORK BOTTLE` or `PULL CORK`

**Processing:**
1. Parser: verb = "uncork"/"pull", target = "cork"
2. Precondition: poison-bottle.parts.cork.detachable == true ✓
3. Factory: creates a cork object
   - `poison-cork` instance, placed in same room
   - Properties: size=0.5, weight=0.1, keywords={"cork", "cork stopper", "stopper"}
4. FSM transition: sealed → open
   - Parent state: "an uncorked bottle"
   - Description: "...the cork is removed. Sickly vapor rises."
   - on_smell now warns of poison
   - on_taste: deadly
5. Result: both cork (new object) and uncorked bottle (parent, state changed) in room

---

## 3. Single-File Architecture: Data Structure

### 3.1 Composite Object File Structure

```lua
-- nightstand.lua
return {
    -- === PARENT METADATA ===
    guid = "d40b15e6-7d64-489e-9324-ea00fb915602",
    id = "nightstand",
    keywords = {"nightstand", "night stand", "bedside table", "side table"},
    size = 4,
    weight = 15,
    categories = {"furniture", "wooden"},
    portable = false,
    room_position = "stands beside the bed",
    on_smell = "Old pine wood and melted tallow.",
    on_feel = "Smooth wooden surface, crusted with hardened wax drippings.",
    
    -- === FSM FOR PARENT ===
    initial_state = "closed_with_drawer",
    _state = "closed_with_drawer",
    
    states = {
        closed_with_drawer = {
            name = "a small nightstand",
            description = "A squat nightstand of knotted pine with a small drawer at the front.",
            surfaces = {
                top = { capacity = 3, max_item_size = 2, contents = {} },
                inside = { capacity = 2, max_item_size = 1, contents = {}, accessible = false },
            },
            -- ... full state definition
        },
        closed_without_drawer = {
            name = "a small nightstand (drawer missing)",
            description = "A squat nightstand of knotted pine. The front is empty where the drawer used to be.",
            surfaces = {
                top = { capacity = 3, max_item_size = 2, contents = {} },
                inside = { capacity = 2, max_item_size = 1, contents = {}, accessible = false },
            },
            -- ... drawer slot is gone
        },
    },
    
    transitions = {
        { from = "closed_with_drawer", to = "open_with_drawer", verb = "open" },
        { from = "open_with_drawer", to = "closed_with_drawer", verb = "close" },
        -- Detachment transitions are handled by part factories, not FSM
    },

    -- === PARTS ===
    parts = {
        drawer = {
            id = "nightstand-drawer",
            detachable = true,
            keywords = {"drawer", "small drawer", "nightstand drawer"},
            name = "a small drawer",
            description = "A shallow wooden drawer, about 12 inches wide and 6 inches deep.",
            size = 3,
            weight = 2,
            categories = {"furniture", "wooden", "container"},
            portable = true,  -- Can be carried once detached
            carries_contents = true,  -- Drawer keeps its contents when detached
            
            -- Sensory descriptions
            on_feel = "Wood, smooth but slightly sticky from old wax. It's empty inside.",
            on_smell = "Pine wood, lingering candle wax.",
            on_listen = "Hollow, wooden sound when tapped.",
            on_look = "A simple wooden drawer, empty now.",
            
            -- Factory: called when detach_part("drawer") happens
            factory = function(parent)
                return {
                    guid = "drawer-guid-here",
                    id = "nightstand-drawer",
                    keywords = {"drawer", "small drawer", "nightstand drawer"},
                    name = "a small drawer",
                    description = "A shallow wooden drawer, about 12 inches wide.",
                    size = 3,
                    weight = 2,
                    portable = true,
                    location = parent.location,  -- Place in same room as parent
                    -- Object can now be TAKE, EXAMINE, PUT IN other containers, etc.
                    
                    surfaces = {
                        inside = { capacity = 2, max_item_size = 1, contents = parent.surfaces.inside.contents }
                    },
                    
                    on_look = function(self)
                        return "A shallow wooden drawer. Inside is " ..
                               (#self.surfaces.inside.contents == 0 and "empty." or "some items.")
                    end,
                }
            end,
        },
        
        legs = {
            id = "nightstand-legs",
            detachable = false,  -- Cannot be separated
            keywords = {"leg", "legs", "wooden legs", "four legs"},
            name = "four wooden legs",
            description = "Four sturdy legs carved from matching pine, holding the nightstand aloft.",
            on_feel = "Solid wood, smooth and well-sanded.",
            on_smell = "Pine wood.",
            -- No factory — not detachable
        },
    },
    
    -- === HELPER METHODS ===
    can_detach_part = function(self, part_id)
        -- Override if certain states prevent detachment
        -- Default: allow if part.detachable == true
        return self.parts[part_id] and self.parts[part_id].detachable
    end,
    
    detach_part = function(self, part_id)
        if not self:can_detach_part(part_id) then
            return nil, "Cannot detach " .. part_id
        end
        
        local part = self.parts[part_id]
        if not part.factory then
            return nil, "Part " .. part_id .. " has no factory"
        end
        
        -- Create instance
        local instance = part.factory(self)
        
        -- Transition parent state based on what was detached
        if part_id == "drawer" then
            self._state = "closed_without_drawer"
        end
        
        return instance
    end,
}
```

### 3.2 Part Object Instance

When a part is detached, the factory returns a **complete object instance**:

```lua
{
    guid = "unique-guid",
    id = "nightstand-drawer",
    keywords = {"drawer", "small drawer"},
    name = "a small drawer",
    description = "A shallow wooden drawer.",
    size = 3,
    weight = 2,
    portable = true,
    location = room_obj,  -- Now in a location, independent of parent
    
    -- Can have its own container surfaces
    surfaces = {
        inside = { capacity = 2, contents = {...} }
    },
    
    -- Can have its own FSM if needed
    states = { ... },
    _state = "default",
    
    -- Can have its own verbs/methods
    on_look = function(self) ... end,
    on_feel = function(self) ... end,
}
```

---

## 4. State Model: Parent Transitions

### 4.1 FSM State Names for Composite Parents

When a parent has detachable parts, FSM state names should reflect **which parts are currently attached**:

```
Nightstand:
  - closed_with_drawer
  - closed_without_drawer
  - open_with_drawer
  - open_without_drawer
```

Each state has:
- **description:** Reflects current part configuration
- **surfaces:** Different accessibility depending on which parts are present
- **keywords/verbs:** Available based on parts present

### 4.2 State Transitions on Detachment

**Transition rule:** When part detaches, parent transitions to corresponding state.

```lua
detach_part = function(self, part_id)
    if not self:can_detach_part(part_id) then
        return nil, "Cannot detach"
    end
    
    -- Create instance
    local instance = self.parts[part_id].factory(self)
    
    -- Transition: remove part from state name
    local from_state = self._state
    local to_state = from_state:gsub("_with_" .. part_id, "_without_" .. part_id)
    
    if to_state ~= from_state then
        self._state = to_state
        -- Update description, surfaces, etc. from new state
    end
    
    return instance
end
```

### 4.3 Example: Four-Poster Bed with Curtains

```lua
-- bed.lua
states = {
    full = {
        -- All 4 curtains present
        description = "A four-poster bed with flowing velvet curtains hung on all sides.",
    },
    curtain_missing_left = {
        -- Left curtain removed
        description = "A four-poster bed. The left curtain hangs torn and missing.",
    },
    curtain_missing_all = {
        -- All 4 curtains gone
        description = "A four-poster bed, naked and stark. All curtains have been stripped away.",
    },
}

parts = {
    curtain_left = {
        id = "bed-curtain-left",
        detachable = true,
        keywords = {"curtain", "left curtain"},
        factory = function(parent) return { ... } end,
    },
    curtain_right = { ... },
    curtain_front = { ... },
    curtain_back = { ... },
}
```

---

## 5. Verb System for Detachment

### 5.1 Detachment Verbs

Which verbs trigger detachment? We need a **general pattern**, not per-object special cases.

**Verbs:**
- **PULL:** Generic detachment, works for most objects
  - `PULL DRAWER` → detach drawer
  - `PULL CORK` → detach cork
  - Aliases: `YANK`, `TUG`, `EXTRACT`

- **REMOVE:** Explicit separation
  - `REMOVE CORK` → detach cork
  - `REMOVE CURTAIN` → detach curtain
  - Aliases: `TAKE OFF`, `SEPARATE`, `DETACH`

- **UNCORK:** Specific for cork/stopper-like objects
  - `UNCORK BOTTLE` → detach cork
  - Aliases: `UNSTOP`, `UNSEAL`

- **OPEN/CLOSE:** For reversible parts (drawers)
  - `OPEN DRAWER` → state transition (not detachment, drawer stays attached)
  - Separate from `PULL DRAWER` (detachment)

### 5.2 Verb Resolution

The parser must distinguish between:
- **Part interaction** (furniture-like, state change): `OPEN DRAWER` on nightstand → state: closed → state: open
- **Part detachment** (removal-like, creates object): `PULL DRAWER` on nightstand → state: open_with_drawer → state: open_without_drawer, plus new drawer object in room

**Proposed rule:**
- `OPEN/CLOSE NOUN`: targets part, triggers state transition on parent
- `PULL/REMOVE NOUN`: targets part, triggers detachment (factory → new object, parent state change)

### 5.3 Verb Aliasing

Parts can define their own verb aliases:

```lua
parts = {
    cork = {
        detachable_verbs = {
            "uncork",    -- primary detachment verb
            "pull cork",
            "remove cork",
            "pop cork",
        },
        factory = function(parent) ... end,
    },
}
```

The engine **adds these verbs to the parent's verb dictionary** when the parent is in a state where the part is accessible.

---

## 6. Part Inheritance & Reversibility

### 6.1 Carrying Contents Through Detachment

When a drawer is detached from a nightstand, **does it carry its contents?**

**Design Decision:** **Yes, by default.** The drawer is a container; it keeps what's inside.

```lua
parts = {
    drawer = {
        id = "nightstand-drawer",
        carries_contents = true,  -- DEFAULT: preserve contents
        
        factory = function(parent)
            return {
                id = "nightstand-drawer",
                surfaces = {
                    inside = {
                        capacity = parent.surfaces.inside.capacity,
                        contents = parent.surfaces.inside.contents,  -- KEEP THE CONTENTS
                    }
                }
            }
        end,
    }
}
```

**Non-container example:** A cork does not carry contents (it's not a container):
```lua
parts = {
    cork = {
        id = "poison-cork",
        carries_contents = false,  -- Corks don't hold items
        factory = function(parent)
            return {
                id = "poison-cork",
                keywords = {"cork", "cork stopper"},
                name = "a cork stopper",
                -- No surfaces; not a container
            }
        end,
    }
}
```

### 6.2 Reversibility: Can Parts Be Re-Attached?

**Design Decision:** **Maybe.** Reversibility is per-part, not automatic.

**Reversible example (drawer):**
- Drawer can be removed and replaced
- Player `CLOSE DRAWER` on nightstand → state transitions (if drawer is still attached)
- Once removed, player cannot `PUT DRAWER BACK` yet (no verb defined)
- Later: `INSTALL DRAWER` verb could be added

**Irreversible example (cork):**
- Cork is removed from bottle
- Cork becomes independent object (possibly repurposed — fishing float!)
- Bottle cannot be "re-corked" by the same cork
- The cork is now a separate object with its own journey

### 6.3 What Happens to Parent's Slot After Detachment

**Container case (drawer):**
- Nightstand had `surfaces.inside` (the drawer's contents)
- After drawer detached: `surfaces.inside` becomes **empty, inaccessible**
- Parent description: "The drawer slot is empty."
- If drawer is re-attached (future verb), `surfaces.inside` becomes accessible again

**Non-container case (cork):**
- Bottle had cork as a part
- After uncorking: bottle state changes to "open"
- No new slot created; the bottle itself changes
- Parent can now be drunk from

---

## 7. Two-Handed Carry System

### 7.1 Hand Capacity Model

A player has **2 hands**. Each hand can carry one item:

```
Player:
├── left_hand: <item or empty>
└── right_hand: <item or empty>
```

### 7.2 Carrying Requirements

Objects have a **hands_required** property:

```lua
objects = {
    match = {
        hands_required = 0,  -- Can hold without hands (in pocket, etc.)
    },
    sword = {
        hands_required = 1,  -- One-handed weapon
    },
    longbow = {
        hands_required = 2,  -- Two-handed; requires both hands free
    },
    nightstand_drawer = {
        hands_required = 2,  -- Drawer full of stuff is bulky, needs 2 hands to carry
    },
}
```

### 7.3 Interaction with Wearables

**Constraint:** Wearables consume hand slots:

```
Player with backpack (worn on back):
├── left_hand: <can hold items>
└── right_hand: <can hold items>
└── back: backpack (worn; doesn't consume hand slot, but provides capacity)

Player with gloves (worn on hands):
├── hands: gloves (worn; still have 2 hand slots for carrying items)
└── left_hand: <can hold items>
└── right_hand: <can hold items>
```

**Key insight:** Worn items on hands (gloves, rings) don't consume **carrying capacity**, but two-handed items do.

### 7.4 Carrying a Two-Handed Object

**Command:** `TAKE DRAWER`

**Processing:**
1. Drawer requires 2 hands
2. Check player's hands:
   - If both empty: success, drawer now occupies both hands
   - If one full: fail, "You need both hands free."
   - If both full: fail, "Your hands are full."

**Result:** Player is carrying drawer with both hands. Player cannot take other items until drawer is dropped.

### 7.5 Containers That Add Capacity

**Backpack example:**
- Backpack worn on back
- Adds 10 inventory slots
- Doesn't consume hand slots
- Hands are still free for 1-2 handed items

**Sack example:**
- Sack is a wearable on back OR carried in hand
- If worn: adds capacity, frees hands
- If carried: occupies hand slot, adds capacity

---

## 8. Implementation Notes for Bart

### 8.1 Engine Changes Required

1. **Part instantiation system**
   - Call `part.factory(parent)` to create instance
   - Place instance in parent's room
   - Remove part from parent's accessible parts

2. **FSM state naming convention**
   - Support suffixes like `_with_PART` and `_without_PART`
   - Auto-transition based on part detachment

3. **Verb dispatch for parts**
   - When parent has part with `detachable_verbs`, add those verbs to parent's verb dictionary
   - Dispatch to `detach_part()` method on parent
   - Parent handles state transition + factory call

4. **Two-handed carry system**
   - Track `hands_required` on objects
   - Enforce hand slot limits during TAKE action
   - Update carried objects when player actions affect hand slots

5. **Container contents preservation**
   - When part is detached with `carries_contents = true`, copy `surfaces.contents` to new instance
   - Ensure contents remain valid in new object's context

### 8.2 Object File Changes Required

1. **Add `parts` table** to composite objects
2. **Add `detach_part()` method** to handle detachment logic
3. **Add `can_detach_part()` callback** for precondition checks
4. **Update FSM states** to reflect part presence
5. **Define factory functions** for each detachable part

### 8.3 Parser Changes Required

1. **Part target resolution**
   - When player says `PULL DRAWER`, parser must recognize "drawer" as a **part of nightstand**, not a standalone object
   - Dispatch to `nightstand:detach_part("drawer")`

2. **Verb aliasing for parts**
   - Load detachable_verbs from parts table
   - Add dynamic verbs to parent's verb dictionary

### 8.4 Example Implementation Sequence

1. **Phase 1:** Implement part instantiation and factory pattern
   - Engine calls `part.factory(parent)` → new object instance
   - Place instance in parent's location

2. **Phase 2:** Implement FSM state transitions
   - Naming: `_with_PART` and `_without_PART`
   - Auto-transition on detachment

3. **Phase 3:** Implement verb dispatch for parts
   - Parser recognizes detachable_verbs
   - Dispatch to parent's `detach_part()` method

4. **Phase 4:** Implement two-handed carry
   - Track hand slots during TAKE/DROP
   - Enforce `hands_required` limits

---

## 9. Edge Cases & Design Questions

### 9.1 What If a Part Has Its Own Container?

**Question:** Drawer contains items. When detached, does the drawer keep its items?

**Answer:** Yes, if `carries_contents = true`. The contents are preserved in the new instance.

**Question:** What if someone puts a NEW item in the drawer AFTER detachment?

**Answer:** The drawer is now an independent object. New items go into the drawer's `surfaces.inside`. Original parent nightstand is unchanged.

### 9.2 What If a Part Is Detached While in the Player's Inventory?

**Question:** Can a player carry an open nightstand, then PULL the drawer while carrying it?

**Answer:** Depends on implementation. Suggest:
- If drawer is accessible (state allows), yes, detach it
- Detached drawer appears in same location as parent (still in player's inventory, conceptually)
- or: drawer appears on the ground near the player

### 9.3 Reversibility & State

**Question:** If drawer is detached, can it be re-attached?

**Answer:** Not in initial implementation. Reversibility is a separate feature to design later.

### 9.4 Multiple Parts of the Same Type

**Question:** Four-poster bed has 4 curtains. Are they all in one `parts.curtains` entry or separate?

**Answer:** Separate entries:
```lua
parts = {
    curtain_front = { ... },
    curtain_back = { ... },
    curtain_left = { ... },
    curtain_right = { ... },
}
```

Each has its own factory, keywords, and detachment verb.

### 9.5 Partial Detachment

**Question:** Can a player remove 2 of 4 curtains and leave 2 attached?

**Answer:** Yes. Each part is independent. FSM states would be:
- `full` (4 curtains)
- `missing_front` (3 remaining)
- `missing_front_back` (2 remaining, sides intact)
- `stripped` (0 remaining)

Or use a more granular naming scheme.

### 9.6 Part Inheritance Chain

**Question:** Can a part contain its own parts (nested composites)?

**Answer:** Not in initial implementation. Future feature. Start with single-level nesting (parent → parts, no parts within parts).

---

## 10. Design Examples

### 10.1 Complete Example: Poison Bottle with Cork

**File:** `poison-bottle.lua`

```lua
return {
    guid = "a1043287-aeeb-4eb7-91c4-d0fcd11f86e3",
    id = "poison-bottle",
    keywords = {"bottle", "glass bottle", "poison", "vial", "potion"},
    size = 1,
    weight = 0.4,
    portable = true,
    
    initial_state = "sealed",
    _state = "sealed",
    
    states = {
        sealed = {
            name = "a small glass bottle",
            description = "A small glass bottle with a skull and crossbones label...",
            on_feel = "Smooth glass, cold to the touch. A cork stopper on top.",
            on_smell = "Even through the cork, something acrid and chemical.",
        },
        open = {
            name = "an open glass bottle",
            description = "A small glass bottle, its cork removed...",
            on_feel = "Smooth glass, cold to the touch. The mouth is open.",
            on_smell = "Acrid, chemical, and unmistakably poisonous.",
        },
        empty = {
            name = "an empty glass bottle",
            description = "A small glass bottle, empty now...",
            terminal = true,
        },
    },
    
    transitions = {
        { from = "sealed", to = "open", verb = "uncork", aliases = {"remove cork", "pull cork"} },
        { from = "open", to = "empty", verb = "drink", effect = "poison" },
    },
    
    parts = {
        cork = {
            id = "poison-cork",
            detachable = true,
            keywords = {"cork", "cork stopper", "stopper", "plug"},
            name = "a cork stopper",
            description = "A cork stopper, slightly sticky with old wine.",
            size = 0.5,
            weight = 0.05,
            portable = true,
            carries_contents = false,
            
            on_feel = "Cork, rough and slightly compressed.",
            on_smell = "Wine-soaked cork.",
            
            detachable_verbs = {
                "uncork",
                "remove cork",
                "pull cork",
                "pop cork",
            },
            
            factory = function(parent)
                return {
                    guid = "cork-guid-unique",
                    id = "poison-cork",
                    keywords = {"cork", "cork stopper", "stopper", "plug"},
                    name = "a cork stopper",
                    description = "A cork stopper, slightly sticky with old wine.",
                    size = 0.5,
                    weight = 0.05,
                    portable = true,
                    location = parent.location,
                    
                    on_look = function(self)
                        return "A cork stopper, slightly sticky. This cork once sealed something dangerous."
                    end,
                    on_feel = function(self)
                        return "Cork, rough and slightly compressed."
                    end,
                }
            end,
        },
    },
    
    can_detach_part = function(self, part_id)
        -- Cork can only be detached from sealed or open states
        if part_id == "cork" then
            return self._state == "sealed" or self._state == "open"
        end
        return false
    end,
    
    detach_part = function(self, part_id)
        if not self:can_detach_part(part_id) then
            return nil, "Cannot detach cork from empty bottle"
        end
        
        local part = self.parts[part_id]
        if not part.factory then
            return nil, "Cork has no factory"
        end
        
        local instance = part.factory(self)
        
        -- Transition to open state
        if part_id == "cork" and self._state == "sealed" then
            self._state = "open"
        end
        
        return instance
    end,
}
```

### 10.2 Complete Example: Nightstand with Drawer

**File:** `nightstand.lua`

```lua
return {
    guid = "d40b15e6-7d64-489e-9324-ea00fb915602",
    id = "nightstand",
    keywords = {"nightstand", "night stand", "bedside table", "side table"},
    size = 4,
    weight = 15,
    categories = {"furniture", "wooden"},
    portable = false,
    on_smell = "Old pine wood and melted tallow.",
    
    initial_state = "closed_with_drawer",
    _state = "closed_with_drawer",
    
    states = {
        closed_with_drawer = {
            name = "a small nightstand",
            description = "A squat nightstand of knotted pine with a small drawer at the front.",
            on_feel = "Smooth wooden surface, crusted with hardened wax drippings.",
            surfaces = {
                top = { capacity = 3, max_item_size = 2, contents = {} },
                inside = { capacity = 2, max_item_size = 1, contents = {}, accessible = false },
            },
        },
        open_with_drawer = {
            name = "a small nightstand (drawer open)",
            description = "A squat nightstand with the drawer pulled out.",
            on_feel = "Smooth wooden surface. The drawer slides open under your fingers.",
            surfaces = {
                top = { capacity = 3, max_item_size = 2, contents = {} },
                inside = { capacity = 2, max_item_size = 1, contents = {}, accessible = true },
            },
        },
        closed_without_drawer = {
            name = "a small nightstand",
            description = "A squat nightstand of knotted pine. The drawer slot is now empty.",
            on_feel = "Smooth wooden surface. The front drawer is missing.",
            surfaces = {
                top = { capacity = 3, max_item_size = 2, contents = {} },
            },
        },
        open_without_drawer = {
            name = "a small nightstand (drawer removed)",
            description = "A squat nightstand with the drawer removed entirely.",
            on_feel = "Smooth wooden surface. The drawer slot gapes empty.",
            surfaces = {
                top = { capacity = 3, max_item_size = 2, contents = {} },
            },
        },
    },
    
    transitions = {
        { from = "closed_with_drawer", to = "open_with_drawer", verb = "open" },
        { from = "open_with_drawer", to = "closed_with_drawer", verb = "close" },
    },
    
    parts = {
        drawer = {
            id = "nightstand-drawer",
            detachable = true,
            keywords = {"drawer", "small drawer", "nightstand drawer"},
            name = "a small drawer",
            description = "A shallow wooden drawer, about 12 inches wide.",
            size = 3,
            weight = 2,
            portable = true,
            carries_contents = true,
            
            on_feel = "Wood, smooth but slightly sticky from old wax.",
            on_smell = "Pine wood, lingering candle wax.",
            
            detachable_verbs = {
                "pull drawer",
                "remove drawer",
                "take out drawer",
                "extract drawer",
            },
            
            factory = function(parent)
                return {
                    guid = "drawer-guid-unique",
                    id = "nightstand-drawer",
                    keywords = {"drawer", "small drawer", "nightstand drawer"},
                    name = "a small drawer",
                    description = "A shallow wooden drawer, about 12 inches wide.",
                    size = 3,
                    weight = 2,
                    portable = true,
                    location = parent.location,
                    hands_required = 2,  -- Heavy when full
                    
                    surfaces = {
                        inside = {
                            capacity = 2,
                            contents = parent.surfaces.inside.contents,  -- CARRY CONTENTS
                        }
                    },
                    
                    on_look = function(self)
                        if #self.surfaces.inside.contents == 0 then
                            return "A wooden drawer, empty now."
                        else
                            return "A wooden drawer containing some items."
                        end
                    end,
                    on_feel = function(self)
                        return "Smooth wooden drawer. It's portable."
                    end,
                }
            end,
        },
        
        legs = {
            id = "nightstand-legs",
            detachable = false,
            keywords = {"leg", "legs", "wooden legs"},
            name = "four wooden legs",
            description = "Four sturdy wooden legs.",
            on_feel = "Solid wood, well-sanded.",
        },
    },
    
    can_detach_part = function(self, part_id)
        if part_id == "drawer" then
            return self.parts.drawer.detachable
        end
        return false
    end,
    
    detach_part = function(self, part_id)
        if not self:can_detach_part(part_id) then
            return nil, "Cannot detach that"
        end
        
        local part = self.parts[part_id]
        local instance = part.factory(self)
        
        -- Transition state
        if part_id == "drawer" then
            if self._state == "closed_with_drawer" then
                self._state = "closed_without_drawer"
            elseif self._state == "open_with_drawer" then
                self._state = "open_without_drawer"
            end
        end
        
        return instance
    end,
}
```

---

## 11. Future Enhancements

### 11.1 Nested Composites

Allow parts to contain sub-parts:
- Wardrobe has doors, which have hinges
- Hinges can be removed separately
- Creates a hierarchy

### 11.2 Re-Attachment Mechanics

Allow removed parts to be put back:
- `PUT DRAWER IN NIGHTSTAND` — restores to `_with_drawer` state
- Preconditions: nightstand must be in matching state, drawer must be compatible
- Inverse factory functions

### 11.3 Part Mutations

Parts can transform when detached:
- Nightstand drawer detached → becomes a container the player can carry
- Poison cork detached → becomes a fishing float (different properties)
- Use factories to define transformations

### 11.4 Dynamic Part Discovery

Parts only appear/disappear based on game state:
- Painting on wall → detachable only after removing nails
- Mirror on wardrobe → detachable only after breaking mounting clips
- Conditional `detachable` flag based on parent state

### 11.5 Weight Redistribution

When a large part is removed, parent's weight/balance changes:
- Nightstand with drawer: weight = 15
- Nightstand without drawer: weight = 13
- Affects movement, carrying, physics

---

## 12. Summary

The **composite object system** transforms static containers into **dynamic, deconstructible puzzles**. A nightstand is no longer just "a place to put things" — it's now a **constructed object with separable parts**, teaching players that the world is **mutable and interactive**.

**Key design decisions:**
1. **Single-file architecture:** Parent + all parts in one `.lua` file
2. **Factory pattern:** Parts become independent objects via instantiation
3. **FSM naming:** `_with_PART` and `_without_PART` reflect part presence
4. **Verb dispatch:** PULL/REMOVE/UNCORK trigger detachment
5. **Content preservation:** Containers carry their contents through detachment
6. **Two-handed carry:** Heavy items require both hands
7. **Extensibility:** New parts and verbs can be added without engine changes

This design enables:
- **Puzzle mechanics:** Find the hidden compartment by removing the drawer
- **Resource scarcity:** Burn the cork as a replacement light source
- **World reactivity:** Objects change when disassembled
- **Player agency:** Deconstruct the environment to solve problems

The architecture is **minimal, extensible, and grounded in proven game design patterns** from *Resident Evil 4*, *Silent Hill*, and classic *Zork*-style interactive fiction.

---

**Next Steps:**
- Bart implements part instantiation and factory pattern
- Bart implements FSM state naming and transitions
- Bart implements verb dispatch for parts
- Bart implements two-handed carry system
- Comic Book Guy creates detachable versions of existing objects (drawer, cork, curtains, doors, mirrors)
