# Wearable Object System Design

**Date:** 2026-03-24  
**Designer:** Comic Book Guy (Game Design)  
**Status:** Design Complete (Ready for Implementation)  
**Approval:** Wayne Berry (Lead Designer)

---

## Executive Summary

Objects in MMO can be worn on the player's body. Wearable items are defined by **where they go** (slot: head, hands, torso, etc.) and **what layer they occupy** (inner, outer, accessory). The critical insight from *Silent Hill* and *Resident Evil 4*: **objects define their own wear metadata**. The engine doesn't hardcode slots — it just enforces conflicts. This keeps the system extensible: new slots can be invented without changing the engine.

This document defines:
1. The complete set of wear slots on the human body
2. How layering works and when conflicts occur
3. The data model for wear metadata on objects
4. Conflict resolution algorithm and player feedback
5. Wearable-container interactions (backpacks, sacks, pots)
6. Type inheritance for wear properties
7. Complete scenario walkthroughs
8. WEAR/REMOVE verb syntax

---

## 1. Wear Slots: The Body as a Game Board

A human body has **nine primary wear slots**. Each represents a distinct location where objects can be worn:

| Slot | Body Part | Examples | Capacity | Notes |
|------|-----------|----------|----------|-------|
| **head** | Crown of skull | Hat, helmet, sack, pot, crown | 1 per layer | Most common; sacks block vision |
| **face** | Eyes, nose, mouth | Mask, goggles, blindfold | 1 per layer | Distinct from head; affects vision |
| **neck** | Throat, shoulders | Necklace, scarf, collar | 1 per layer | Accessory-friendly |
| **torso** | Chest, ribs, abdomen | Shirt, armor, tunic, vest | 1 per layer | Torso-specific items |
| **back** | Shoulders, spine, posterior | Backpack, cloak, cape | 1 per layer | Load-bearing; backpacks add capacity |
| **hands** | Wrists, fingers, palms | Gloves, rings, bracelets, cuffs | 2 per layer* | **Pair slots** — both hands or none |
| **waist** | Hips, abdomen line | Belt, rope sash, chain | 1 per layer | Utility; can hold light items |
| **legs** | Thighs, calves, shins | Pants, greaves, leggings, skirt | 1 per layer | Leg-specific; covers both legs |
| **feet** | Ankles, toes | Boots, shoes, sandals, gaiters | 1 per layer | Ground contact; affects movement |

*"**hands**" is special: gloves come in pairs. A single glove object should specify this (see Data Model section).

---

## 2. Layering: Inner, Outer, Accessory

Not all slots stack infinitely. We use **three layer types**:

### 2.1 Layer Definitions

| Layer | Purpose | Wear Order | Stack Limit | Examples |
|-------|---------|-----------|-------------|----------|
| **inner** | Worn directly against skin | 1st (closest to body) | 1 per slot | Undershirt, leggings, base layer |
| **outer** | Worn over inner layer | 2nd (over base) | 1 per slot | Cloak, armor, coat, jacket |
| **accessory** | Jewelry, decoration, small items | N/A (independent) | Many | Rings, necklaces, scarves |

### 2.2 Layering Rules

**Rule 1:** Only one "inner" layer per slot.
- You can't wear two undershirts on your torso (conflict).
- You can wear one undershirt + one cloak (different layers, stacking allowed).

**Rule 2:** Only one "outer" layer per slot.
- You can't wear two suits of armor on your torso.
- You can't wear two hats on your head.

**Rule 3:** Accessory layers don't conflict with inner or outer.
- You can wear a necklace (accessory) with a shirt (inner) and cloak (outer) on the torso area... wait, necklaces aren't torso wear. Let me rephrase:
- You can wear multiple accessories **if they use different slots**. E.g., a ring on hands + a necklace on neck.
- You can wear multiple accessories **on the same slot** IF the object allows it (e.g., multiple rings). This is per-object: `max_accessories = 3` for a "ring" wear slot.

**Rule 4:** Accessory layers don't interact with inner/outer layers.
- A ring on your hands doesn't conflict with gloves on your hands.
- A necklace (accessory, neck) coexists peacefully with a scarf (outer, neck).

**Rule 5:** Strict inner/outer stacking.
- Inner layers must be worn before outer layers in visual description.
- When checking conflicts, inner ≠ outer (no conflict). Inner ≠ inner (conflict). Outer ≠ outer (conflict).

### 2.3 Wear Order Visualization

**Example: Dressing a player in full winter gear**

```
Slot: torso
  Layer: inner   → undershirt    (worn first, closest to skin)
  Layer: outer   → wool coat     (worn over undershirt)
  Layer: accessory → None        (torso doesn't typically have accessories)

Slot: hands
  Layer: inner   → None
  Layer: outer   → leather gloves (worn on hands)
  Layer: accessory → None         (or: ring on finger, if finger were a slot)

Slot: neck
  Layer: inner   → None
  Layer: outer   → scarf         (wound around neck)
  Layer: accessory → necklace    (hanging over scarf, doesn't interfere)

Slot: head
  Layer: inner   → None
  Layer: outer   → wool hat      (sits on crown)
  Layer: accessory → None

Slot: feet
  Layer: inner   → wool socks    (worn on feet, under boots)
  Layer: outer   → leather boots (worn over socks)
```

When player looks at themselves: "You are wearing an undershirt, a wool coat, leather gloves, a scarf, a necklace, a wool hat, wool socks, and leather boots."

---

## 3. The Data Model: Wear Metadata on Objects

Each wearable object defines its own wear properties. The object **knows** where it goes and what layer it occupies.

### 3.1 Core Wearable Properties

```lua
-- In any .lua object file, add a 'wear' table:

wear = {
    -- REQUIRED: Where on the body this goes
    slot = "head",              -- string: "head", "face", "neck", "torso", "back", "hands", "waist", "legs", "feet"
    
    -- REQUIRED: What layer (inner, outer, or accessory)
    layer = "outer",            -- string: "inner", "outer", "accessory"
    
    -- OPTIONAL: Max items on this slot (default 1 for non-accessory, >1 for accessory)
    max_per_slot = 1,           -- number: how many of THIS object can be worn on this slot
    
    -- OPTIONAL: Does wearing this block vision?
    blocks_vision = false,      -- boolean: true = player can't see while wearing
    
    -- OPTIONAL: Does wearing this block smell/taste?
    blocks_smell = false,       -- boolean: true = olfactory input blocked
    
    -- OPTIONAL: Gameplay effects (encoded as flags)
    provides_warmth = false,    -- boolean: wearing this adds warmth (flavor)
    provides_armor = 0,         -- number: 0-10 scale, protection level
    is_ceremonial = false,      -- boolean: ceremonial items trigger special events
    
    -- OPTIONAL: Container interaction (for wearable containers)
    container_access_when_worn = true,  -- can I reach inside while wearing?
    
    -- OPTIONAL: Quality rating (fluff, but helps with feedback)
    wear_quality = "normal",    -- string: "makeshift", "normal", "fine", "ceremonial"
}
```

### 3.2 Example Objects

#### Example 1: Simple Hat (wool-hat.lua)

```lua
return {
    guid = "example-guid-1",
    id = "wool-hat",
    name = "a wool hat",
    keywords = {"hat", "wool hat", "cap"},
    description = "A simple wool hat, knitted in a cream color.",
    
    size = 0.5,
    weight = 0.1,
    portable = true,
    categories = {"fabric", "wearable"},
    
    wear = {
        slot = "head",
        layer = "outer",
        max_per_slot = 1,
        blocks_vision = false,
        provides_warmth = true,  -- flavor: tells player why it's useful
        wear_quality = "normal",
    },
    
    on_look = function(self)
        return self.description
    end,
}
```

#### Example 2: Sack (wearable + container, blocks vision)

```lua
return {
    guid = "4720ace5-baed-4133-b5db-977257f5b680",
    template = "container",
    id = "sack",
    name = "a burlap sack",
    keywords = {"sack", "bag", "burlap sack", "burlap", "pouch"},
    description = "A rough burlap sack, cinched at the top with rope.",
    
    size = 1,
    weight = 0.3,
    portable = true,
    categories = {"fabric", "container", "wearable"},
    
    -- Container properties
    container = true,
    capacity = 4,
    max_item_size = 2,
    weight_capacity = 10,
    contents = {"needle", "thread"},
    
    -- Wearable properties: can be worn on head, but blocks vision
    wear = {
        slot = "head",
        layer = "outer",
        max_per_slot = 1,
        blocks_vision = true,   -- KEY: wearing a sack on your head blinds you
        container_access_when_worn = false,  -- can't reach inside while it's on your head
        provides_warmth = false,
        wear_quality = "makeshift",
    },
    
    on_look = function(self)
        if #self.contents == 0 then
            return self.description .. "\n\nIt is empty."
        end
        local lines = {self.description, "\nInside the sack:"}
        for _, id in ipairs(self.contents) do
            table.insert(lines, "  " .. id)
        end
        return table.concat(lines, "\n")
    end,
}
```

#### Example 3: Backpack (wearable + container, accessible while worn)

```lua
return {
    guid = "example-guid-3",
    template = "container",
    id = "backpack",
    name = "a sturdy backpack",
    keywords = {"backpack", "pack", "rucksack", "bag"},
    description = "A well-made leather backpack with straps and buckles.",
    
    size = 2,
    weight = 1.0,
    portable = true,
    categories = {"leather", "container", "wearable"},
    
    container = true,
    capacity = 8,
    max_item_size = 3,
    weight_capacity = 20,
    contents = {},
    
    wear = {
        slot = "back",
        layer = "outer",
        max_per_slot = 1,
        blocks_vision = false,
        container_access_when_worn = true,  -- you can reach inside while wearing it
        provides_warmth = false,
        wear_quality = "normal",
    },
    
    on_look = function(self)
        if #self.contents == 0 then
            return self.description .. "\n\nIt is empty."
        end
        local lines = {self.description, "\nContains:"}
        for _, id in ipairs(self.contents) do
            table.insert(lines, "  " .. id)
        end
        return table.concat(lines, "\n")
    end,
}
```

#### Example 4: Pot (wearable as makeshift helmet)

```lua
return {
    guid = "example-guid-4",
    id = "pot",
    name = "a ceramic pot",
    keywords = {"pot", "ceramic pot", "cooking pot"},
    description = "A ceramic cooking pot, suitable for stews.",
    
    size = 1.5,
    weight = 1.5,
    portable = true,
    categories = {"ceramic", "container"},
    
    container = true,
    capacity = 3,
    contents = {},
    
    -- Pots can be worn on the head as improvised armor
    wear = {
        slot = "head",
        layer = "outer",
        max_per_slot = 1,
        blocks_vision = false,      -- you can see around the rim
        provides_armor = 1,         -- minimal protection, mostly comedic
        wear_quality = "makeshift", -- signals improvisation
    },
    
    on_look = function(self)
        if #self.contents == 0 then
            return self.description
        end
        local lines = {self.description, "\nIt contains:"}
        for _, id in ipairs(self.contents) do
            table.insert(lines, "  " .. id)
        end
        return table.concat(lines, "\n")
    end,
}
```

#### Example 5: Chamber-Pot (inherits pot wearability)

```lua
return {
    guid = "9a9ff109-93a0-4dcf-9d6e-0f0f4b83f4ba",
    type_id = "pot",           -- inherits from pot base class
    id = "chamber-pot",
    name = "a ceramic chamber pot",
    keywords = {"chamber pot", "pot", "ceramic pot"},
    description = "A squat ceramic chamber pot with quiet dignity.",
    
    size = 2,
    weight = 3,
    portable = true,
    categories = {"ceramic", "container", "wearable"},  -- inherited wearable category
    
    container = true,
    capacity = 2,
    contents = {},
    
    -- Inherits wear metadata from pot type
    -- (or can override/extend if needed)
    wear = {
        slot = "head",
        layer = "outer",
        max_per_slot = 1,
        blocks_vision = false,
        provides_armor = 1,
        wear_quality = "makeshift",
        -- This is ridiculous, which is the point.
    },
    
    on_look = function(self)
        if self.contents and #self.contents > 0 then
            local text = self.description .. "\n\nInexplicably, it contains:"
            for _, id in ipairs(self.contents) do
                text = text .. "\n  " .. id
            end
            return text
        end
        return self.description .. "\n\nIt is, thankfully, empty."
    end,
}
```

#### Example 6: Gloves (pair, hands slot)

```lua
return {
    guid = "example-guid-6",
    id = "leather-gloves",
    name = "a pair of leather gloves",
    keywords = {"gloves", "leather gloves", "pair of gloves"},
    description = "Supple leather gloves, dyed a rich brown.",
    
    size = 0.5,
    weight = 0.2,
    portable = true,
    categories = {"leather", "wearable"},
    
    wear = {
        slot = "hands",
        layer = "outer",
        max_per_slot = 1,       -- ONE PAIR of gloves per hands slot
        is_pair = true,         -- OPTIONAL: flag for UI clarity
        blocks_vision = false,
        provides_warmth = true,
        wear_quality = "normal",
    },
    
    on_look = function(self)
        return self.description
    end,
}
```

#### Example 7: Ring (accessory, hands slot, multiple allowed)

```lua
return {
    guid = "example-guid-7",
    id = "gold-ring",
    name = "a gold ring",
    keywords = {"ring", "gold ring", "band"},
    description = "A simple gold band, worn smooth with age.",
    
    size = 0.05,
    weight = 0.01,
    portable = true,
    categories = {"jewelry", "wearable", "accessory"},
    
    wear = {
        slot = "hands",         -- rings go on hands (could be "finger" if granular)
        layer = "accessory",
        max_per_slot = 10,      -- multiple rings can be worn on hands
        blocks_vision = false,
        is_ceremonial = false,
        wear_quality = "fine",
    },
    
    on_look = function(self)
        return self.description
    end,
}
```

### 3.3 Wear Metadata Schema (Lua)

**Minimal valid wear table:**
```lua
wear = {
    slot = "head",
    layer = "outer",
}
```

**Full table (all optional beyond slot/layer):**
```lua
wear = {
    slot = "head",                              -- required
    layer = "outer",                            -- required
    max_per_slot = 1,                           -- optional, default 1
    blocks_vision = false,                      -- optional, default false
    blocks_smell = false,                       -- optional, default false
    provides_warmth = false,                    -- optional, default false
    provides_armor = 0,                         -- optional, default 0
    is_ceremonial = false,                      -- optional, default false
    is_pair = false,                            -- optional, default false (for gloves)
    container_access_when_worn = true,          -- optional, default true
    wear_quality = "normal",                    -- optional, default "normal"
    description_when_worn = "...",              -- optional: custom desc while worn
}
```

---

## 4. Conflict Resolution Algorithm

When a player issues `WEAR <object>`, the engine checks:

### 4.1 Wear Conflict Check Pseudocode

```
function can_wear(player, object):
    
    // Step 1: Is the object wearable?
    if not object.wear then
        return false, "You can't wear that."
    
    // Step 2: Extract object's slot and layer
    slot = object.wear.slot
    layer = object.wear.layer
    
    // Step 3: Find what player is already wearing on this slot
    currently_worn_on_slot = player.worn_items[slot] or {}
    
    // Step 4: Check for layer conflicts
    for each worn_item in currently_worn_on_slot:
        if layer == "accessory":
            // Accessory layers don't conflict with inner/outer
            // But check max_per_slot for accessories
            if worn_item.wear.layer == "accessory":
                accessory_count = count_accessories_on_slot(player, slot)
                if accessory_count >= object.wear.max_per_slot:
                    return false, "You're already wearing too many things on your " + slot
        else:
            // inner or outer layers
            if worn_item.wear.layer == layer:
                // Conflict! Same layer on same slot
                return false, "You're already wearing a " + object.name + " there. Remove it first."
    
    // Step 5: Is player's inventory full?
    if worn_items_count >= player.wear_capacity:
        return false, "You're already wearing too much."
    
    // Step 6: Is the object currently in a container or held?
    if object.location != player.inventory:
        return false, "You need to pick that up first."
    
    return true, "OK to wear"
```

### 4.2 Player Feedback Messages

| Scenario | Message |
|----------|---------|
| Can't wear (not wearable) | "You can't wear that." |
| Slot conflict (same layer) | "You're already wearing [object]. Remove it first." |
| Accessory limit reached | "You're already wearing the maximum number of rings." |
| Object not in inventory | "You need to pick that up first." |
| Inventory full | "You're wearing too much already." |
| Success | "[Player name] puts on the [object]." / "You put on the [object]." |

---

## 5. Wearable + Container Interactions

### 5.1 The Three Types of Wearable Containers

| Type | Example | Slot | Container Accessible While Worn | Vision Impact | Notes |
|------|---------|------|-------------------------------|---------------|-------|
| **Functional** | Backpack | back | YES | No impact | Designed to be worn; adds inventory space |
| **Blinding** | Sack, bag | head | NO | Blocks sight | Worn over head; makes player blind |
| **Hybrid** | Pot | head | Depends | No impact | Can be worn or used; as helmet, contents inaccessible |

### 5.2 Scenario: Wearing a Backpack

```
> PUT KNIFE IN BACKPACK
(If backpack is on ground, you pick it up, add knife to contents)

> WEAR BACKPACK
You put on the backpack. It settles comfortably on your shoulders.

> INVENTORY
You are carrying: a backpack (containing a knife, a rope, and other items)

> PUT ROPE ON GROUND
(From inside the backpack, while wearing it — container_access_when_worn = true)
The rope falls to the ground.

> EXAMINE BACKPACK
The backpack is strapped to your back. It contains: a knife.
```

### 5.3 Scenario: Wearing a Sack on Your Head

```
> WEAR SACK
You pull the burlap sack down over your head. It cinches tightly. You can't see anything!

> LOOK
It is pitch black. You can't see a thing.

> TAKE NEEDLE FROM SACK
You fumble blindly, but you can't quite reach inside the sack while it's over your head.
(container_access_when_worn = false prevents this)

> REMOVE SACK
You pull the sack off your head and gasp for air.

> LOOK
(Vision restored)
```

### 5.4 Scenario: Pot as Helmet + Container

```
> WEAR POT
You place the ceramic pot on your head. It's not comfortable, but it's surprisingly sturdy.
(No vision loss, but blocks things slightly)

> EXAMINE POT
A ceramic pot sits awkwardly on your head. It contains: some food scraps.

> PUT COIN IN POT
You toss a coin into the pot overhead. It clinks inside.

> REMOVE POT
You carefully lift the pot off your head and examine it.
```

---

## 6. Type Inheritance for Wear Metadata

Objects that inherit from a base type should inherit its wearability. Chamber-pot inherits from pot; so it's wearable in the same way.

### 6.1 Inheritance Pattern

```lua
-- pot.lua (base type, not instantiated)
pot = {
    type_id = nil,      -- base type
    id = "pot",
    name = "a pot",
    wear = {
        slot = "head",
        layer = "outer",
        provides_armor = 1,
        wear_quality = "makeshift",
    },
}

-- chamber-pot.lua (derived type)
return {
    guid = "...",
    type_id = "pot",        -- inherits from pot
    id = "chamber-pot",
    -- Automatically inherits wear properties unless overridden
    wear = {
        -- Inherits: slot = "head", layer = "outer", provides_armor = 1, wear_quality = "makeshift"
        -- Can override here if needed
    },
}
```

**Engine Resolution:** When loading chamber-pot, if `wear` exists but is incomplete, inherit missing fields from base type's wear table.

---

## 7. WEAR and REMOVE Verbs

### 7.1 WEAR Verb Syntax

**Accepted syntaxes:**

```
WEAR <object>                  // Standard
PUT ON <object>               // Natural language alias
DON <object>                  // Archaic but clear
DRESS IN <object>             // For full outfits (treated as WEAR)
PUT <object> ON               // Alternative word order
```

**Examples:**

```
> WEAR HAT
You put on the wool hat.

> PUT ON JACKET
You slip into the terrible burlap jacket.

> DON BOOTS
You lace up the leather boots.

> WEAR CLOAK
You drape the wool cloak across your shoulders.
```

### 7.2 REMOVE Verb Syntax

**Accepted syntaxes:**

```
REMOVE <object>               // Standard
TAKE OFF <object>             // Natural language alias
DOFF <object>                 // Archaic but clear
UNDRESS <object>              // For full outfits
```

**Examples:**

```
> REMOVE HAT
You take off the wool hat.

> TAKE OFF JACKET
You shrug out of the terrible burlap jacket.

> DOFF BOOTS
You unlace and remove the leather boots.
```

### 7.3 Edge Cases

**What if player tries to remove something not worn?**
```
> REMOVE KNIFE
You're not wearing the knife.
```

**What if the slot name conflicts with other verbs?**
Example: "PUT ON X" could mean put item X in a container ON something.
- Parser disambiguates based on object properties: if object has `wear`, it's WEAR. If it's a location, it's PLACE.

**What if player wears a sack over their head and tries to examine something?**
```
> LOOK
It is pitch black. You can't see anything.

> EXAMINE KNIFE (held in hand, but head is covered)
You know the knife is there (inventory awareness), but you can't see it.
```

---

## 8. Player Feedback and Immersion

### 8.1 Wear State Descriptions

When a player is wearing items, all feedback should reflect this:

**Inventory view:**
```
> INVENTORY
You are carrying: a torch (unlit), a key
You are wearing: a wool hat, a wool coat, leather boots
```

**Self-examination:**
```
> EXAMINE SELF
You are a figure of humble bearing, dressed in weathered clothes:
- On your head: a wool hat
- On your torso: a wool coat (over an undershirt)
- On your feet: leather boots

Your hands hang free.
```

**Vision impairment:**
```
> WEAR SACK
You pull the sack over your head. Darkness swallows you.

> LOOK
(nothing)
```

**Armor effects (flavor):**
```
> WEAR POT
You place the ceramic pot on your head. It makes an ridiculous helmet, but you feel... slightly tougher?
```

**Warmth effects (flavor):**
```
> WEAR COAT
You slip into the wool coat. Its warmth immediately envelops you. Much better.
```

### 8.2 World-Facing Messages

When other players or observers see you wearing things:
```
> (Another player) LOOK
You see: (Player name), wearing a wool hat, a wool coat, and boots.
```

---

## 9. Design Scenarios: Complete Walkthroughs

### Scenario 1: Layering (Shirt + Cloak)

**Setup:** Player has undershirt (inner layer) and cloak (outer layer).

```
> WEAR UNDERSHIRT
You slip on the undershirt. It's snug against your skin.

> WEAR CLOAK
You drape the wool cloak across your shoulders. It settles comfortably over the undershirt.

> EXAMINE SELF
You are wearing:
- On your torso: an undershirt and a wool cloak (draped over)

> WEAR CLOAK (second attempt)
You're already wearing a cloak. Remove it first.
```

**Mechanic:** Different layers (inner vs outer) stack. Same layer (outer vs outer) conflicts.

---

### Scenario 2: One Hat, Not Two

**Setup:** Player has two hats in inventory.

```
> WEAR WOOL-HAT
You put on the wool hat.

> WEAR LEATHER-HAT (second attempt)
You're already wearing a wool hat. Remove it first.

> REMOVE WOOL-HAT
You take off the wool hat.

> WEAR LEATHER-HAT
You put on the leather hat.
```

**Mechanic:** Only one outer layer per slot.

---

### Scenario 3: Sack on Head (Blindness)

**Setup:** Player has sack in inventory, can see the room.

```
> WEAR SACK
You pull the burlap sack over your head. Everything goes dark.

> LOOK
(nothing — player is blind)

> INVENTORY
You are carrying: a needle, a thread
You are wearing: a burlap sack

> EXAMINE NEEDLE
You know the needle is in your inventory, but you can't see it.

> REMOVE SACK
You pull the sack off and blink in the light.

> LOOK
(Room visible again)
```

**Mechanic:** `blocks_vision = true` prevents LOOK/EXAMINE of the environment.

---

### Scenario 4: Backpack as Inventory Extension

**Setup:** Player has backpack, is at inventory limit.

```
> INVENTORY
You are carrying: 8 items (inventory full)
Free hands: 0

> TAKE RING
Your hands are full. You can't carry that.

> WEAR BACKPACK
You put on the backpack. It settles on your shoulders.

> INVENTORY
You are carrying: 8 items
You are wearing: backpack (contains: empty)
Backpack capacity: 8 items available

> TAKE RING
You place the ring in your backpack.

> INVENTORY
You are carrying: 8 items
You are wearing: backpack (contains: ring)
Backpack capacity: 7 items available
```

**Mechanic:** Wearing a container adds its capacity to the player's total inventory space. Doesn't bypass limits; extends them.

---

### Scenario 5: Pot as Helmet + Container

**Setup:** Player has a ceramic pot with stew inside.

```
> EXAMINE POT
A ceramic cooking pot. It contains: stew

> WEAR POT
You place the ceramic pot on your head. It's uncomfortable and probably not effective, but you feel oddly protected.

> EXAMINE SELF
You are wearing: a ceramic pot (contains: stew)

> LOOK
(Normal vision — pot doesn't block sight)

> PUT SPOON IN POT
You reach up and place the spoon in the pot. It clinks against the inside.

> REMOVE POT
You carefully lift the pot off your head.

> EXAMINE POT
The pot contains: stew, spoon
```

**Mechanic:** Wearable containers can still hold items while worn (if `container_access_when_worn = true`).

---

### Scenario 6: Rings (Multiple Accessories)

**Setup:** Player has three gold rings in inventory.

```
> WEAR RING (first)
You slip on the gold ring. It fits perfectly.

> WEAR RING (second)
You slip on another gold ring.

> WEAR RING (third)
You slip on another gold ring.

> INVENTORY
You are carrying: (nothing)
You are wearing: 3 gold rings (on hands)

> WEAR RING (fourth attempt, but max_per_slot = 3)
You're already wearing the maximum number of rings.

> REMOVE RING
Which ring? You have 3 gold rings on your hands:
 1. the first ring
 2. the second ring
 3. the third ring

> REMOVE RING 1
You remove the first ring.
```

**Mechanic:** Accessory layers can stack up to `max_per_slot`. Removal prompts for disambiguation if multiple of the same item are worn.

---

### Scenario 7: Ceremony (Ceremonial Items)

**Setup:** Crown is marked `is_ceremonial = true`. Wearing it triggers a reaction.

```
> WEAR CROWN
You place the ornate crown upon your head. You feel a surge of authority—as if you are meant to wear this.

> EXAMINE SELF
You are wearing: an ornate crown (ceremonial)

(Optional: wearing ceremonial items could unlock special dialogue, trigger NPCs to react, or unlock rooms.)
```

**Mechanic:** Ceremonial items can have special effects encoded in object-specific Lua (on_wear_ceremonial hook).

---

## 10. Edge Cases and Special Handling

### 10.1 Wearing Objects During Combat

**Rule:** Wearables can be worn/removed during combat. Each action takes a turn (balance).

```
Combat scenario:
> REMOVE CLOAK
(1 turn spent)
> ATTACK ENEMY
(1 turn spent)
> WEAR CLOAK
(1 turn spent)
```

### 10.2 Wearing Objects While Holding Others

**Rule:** Wearing doesn't interfere with hand-held items. A player can wear gloves and hold a sword simultaneously.

```
> WEAR GLOVES
You put on the gloves.

> INVENTORY
You are carrying: a sword
You are wearing: leather gloves

> ATTACK (with sword, while wearing gloves)
You slash with the sword. The gloves don't interfere.
```

### 10.3 Dropping Worn Items

**Rule:** Worn items must be removed before dropping them.

```
> DROP CLOAK
You're wearing the cloak. Remove it first.

> REMOVE CLOAK
You take off the cloak.

> DROP CLOAK
You drop the cloak to the ground.
```

### 10.4 Container Inside a Wearable Container

**Rule:** Nested containers can be worn if they're inside a wearable container, but not directly worn.

```
> WEAR BAG (where bag is inside a backpack)
You're not carrying the bag. You need to remove it from your backpack first.

> (Remove bag from backpack first, then:)
> WEAR BAG
You put on the bag.
```

### 10.5 Examining Worn Items

**Rule:** Examining a worn item shows its description + "You are wearing this" note.

```
> EXAMINE HAT (while wearing)
A wool hat, knitted in cream color. You are currently wearing this.

> EXAMINE HAT (while not wearing)
A wool hat, knitted in cream color.
```

---

## 11. Implementation Notes for Engineers

### 11.1 Data Structure: Player Worn Items

```lua
player.worn_items = {
    head = {
        {object_id = "wool-hat", layer = "outer"},
    },
    hands = {
        {object_id = "leather-gloves", layer = "outer"},
        {object_id = "gold-ring", layer = "accessory"},
        {object_id = "gold-ring", layer = "accessory"},
        {object_id = "gold-ring", layer = "accessory"},
    },
    torso = {
        {object_id = "undershirt", layer = "inner"},
        {object_id = "wool-coat", layer = "outer"},
    },
    back = {
        {object_id = "backpack", layer = "outer"},
    },
    feet = {},
    neck = {},
    face = {},
    waist = {},
    legs = {},
}
```

### 11.2 Verb Dispatch

**Parser routing:**
- If object has `wear = {}` table, route to WEAR verb handler
- If input is "PUT ON <obj>", "WEAR <obj>", "DON <obj>", "DRESS IN <obj>", treat as WEAR
- If input is "REMOVE <obj>", "TAKE OFF <obj>", "DOFF <obj>", treat as REMOVE

### 11.3 Conflict Check (Pseudocode to Production)

See Section 4.1 pseudocode. Implement in engine's wearable handler. Check:
1. Object has `wear` table
2. No layer conflict on slot
3. Accessory count within limit
4. Object in player inventory
5. Player wear capacity not exceeded

### 11.4 Vision Block Handling

If any worn item has `blocks_vision = true`:
- Block all LOOK/EXAMINE of the room
- Block all EXAMINE of objects not in inventory
- Allow EXAMINE of worn items and inventory items

### 11.5 Container Access While Worn

If object is wearable + container + `container_access_when_worn = true`:
- Player can PUT/TAKE items from it while wearing
- If `container_access_when_worn = false`:
  - Player cannot PUT/TAKE from it while wearing
  - Message: "You can't reach inside while wearing it."

---

## 12. Design Philosophy & Reasoning

### Why Objects Define Their Own Wear Metadata

**Classic games like *Silent Hill 2* and *Resident Evil 4*** let the player equip and unequip items freely, but each item type has a predetermined role. The game doesn't ask: "Where do you want to wear this?" The item knows. A hat goes on your head. Gloves go on your hands. This directness reduces friction and keeps the player immersed.

**In our system:** Each object carries `wear_slot` and `wear_layer`. The engine enforces slot conflicts but never asks the player where things go. New objects can define new slots (e.g., `wear_slot = "finger"` for a ring) without changing the engine.

### Why Layers Matter

**Layering allows logical stacking** (shirt under cloak) without infinite complexity. Real clothing layering follows this pattern: underwear, mid-layer, outer layer. Accessories (rings, necklaces) sit independently. This feels natural and gives designers intuitive constraints.

### Why Sacks and Bags Block Vision

**From adventure games like *Zork II*:** Putting a bag over your head blinds you. It's a puzzle mechanic: "I need to see, but I need to carry stuff." Trade-offs make puzzles interesting.

### Why Pots Are Wearable

**Comedic gameplay + puzzle extensibility.** A player might try to wear a pot on their head as a makeshift helmet. It works, barely, and telegraphs desperation. This is the kind of emergent, player-driven interaction that makes text adventures feel alive.

---

## 13. Future Expansions

### 13.1 Wear-Specific Verbs (Not in MVP)

Future: `ADJUST HAT` (shifts it, triggers a sensory description). `TIGHTEN BELT` (adjusts fit). These would be object-specific Lua hooks, not engine features.

### 13.2 Body Slots We Didn't Define

**Finger slots:** If granular enough, `wear_slot = "finger"` could allow multiple rings on specific fingers. Not required for MVP; could be added later.

**Chest / Torso Split:** Right now, all chest items use "torso". If we need to distinguish (e.g., amulet on chest vs. shirt), split into "chest" and "torso_lower".

### 13.3 Wear Effects System

Future: Objects define `on_wear`, `on_remove`, `on_tick_while_worn` callbacks. A cursed ring might stay stuck (`on_remove` blocks removal). A cloak might prevent climbing (`on_tick_while_worn` returns failure for climb actions).

---

## 14. Examples: Building New Wearable Objects

### 14.1 Template: Creating a New Wearable

```lua
return {
    guid = "unique-guid-here",
    id = "new-object-id",
    name = "a item name",
    keywords = {"item", "keyword1", "keyword2"},
    description = "A detailed description of the item.",
    
    on_feel = "What it feels like to touch.",
    on_smell = "What it smells like.",
    
    size = 1,
    weight = 0.5,
    portable = true,
    categories = {"category1", "wearable"},
    
    wear = {
        slot = "head",          -- or "hands", "torso", "back", "feet", etc.
        layer = "outer",        -- or "inner", "accessory"
        max_per_slot = 1,
        blocks_vision = false,
        provides_warmth = false,
        provides_armor = 0,
        wear_quality = "normal",
    },
    
    on_look = function(self)
        return self.description
    end,
}
```

### 14.2 Template: Wearable + Container

```lua
return {
    guid = "unique-guid-here",
    template = "container",
    id = "new-bag",
    name = "a item name",
    -- ... (description, feel, smell, etc.)
    
    container = true,
    capacity = 5,
    max_item_size = 2,
    weight_capacity = 10,
    contents = {},
    
    wear = {
        slot = "back",          -- or "head", "hands", etc.
        layer = "outer",
        container_access_when_worn = true,  -- can reach inside while wearing
        blocks_vision = false,
    },
    
    on_look = function(self)
        if #self.contents == 0 then
            return self.description .. "\n\nIt is empty."
        end
        local lines = {self.description, "\nContains:"}
        for _, id in ipairs(self.contents) do
            table.insert(lines, "  " .. id)
        end
        return table.concat(lines, "\n")
    end,
}
```

---

## 15. Testing Checklist (for QA)

- [ ] Player can wear a hat; INVENTORY shows "wearing: wool hat"
- [ ] Second hat attempt fails with "You're already wearing a hat"
- [ ] Player can wear shirt + cloak simultaneously (different layers)
- [ ] Player can't wear two armor pieces on torso (same layer)
- [ ] Wearing sack on head: LOOK returns nothing (blindness)
- [ ] Sack blocks all EXAMINE except inventory items
- [ ] Removing sack restores vision
- [ ] Backpack worn: INVENTORY shows capacity expanded
- [ ] Putting items in backpack while wearing works
- [ ] Removing worn backpack requires "Remove first" message if not using REMOVE command
- [ ] Pot worn on head: allows sight, allows continued container access
- [ ] Ring worn: multiple rings stack (up to max_per_slot)
- [ ] Wearing/removing items during combat takes a turn
- [ ] Dropped items while wearing show "Remove first" message
- [ ] Parser accepts "PUT ON", "DON", "WEAR" as synonyms
- [ ] Parser accepts "REMOVE", "TAKE OFF", "DOFF" as synonyms
- [ ] Type inheritance: chamber-pot inherits pot's wear metadata

---

## Conclusion

The wearable object system is **simple, extensible, and grounded in gameplay clarity**. Objects define where they go and what layers they occupy. The engine enforces conflicts and tracks wear state. Players experience clothing as a natural, tactile part of their avatar's presence in the world.

This design respects the player's agency (they choose what to wear), maintains immersion (they never hear "specify wear_slot"), and allows designers to add new wearables without engine changes (new slots are just new string values on objects).

---

---

## Appendix A: Implementation Status (Shipped, Phase A7)

**Status:** ✅ **Fully Implemented**  
**Location:** `src/engine/verbs/equipment.lua` (wear/remove handlers)  
**Related:** `src/engine/armor.lua`, `src/engine/player/appearance.lua`  

### A.1 Event Hooks (Implemented)

The system implements two event hooks for custom object behavior:

#### `on_wear` Hook

Fired **after** an item is equipped and flavor text is printed.

```lua
-- Signature: function(obj, ctx)
-- Receives: (object, game context)

-- Example: armor registration
on_wear = function(obj, ctx)
    local armor = require("engine.armor")
    if armor and armor.register_worn_item then
        armor.register_worn_item(obj, ctx)
    end
end
```

**Use Cases:**
- Register armor protection with damage interceptor
- Apply stat bonuses/penalties
- Trigger sensory narration (e.g., pot smell)
- Update player state for cursed items

#### `on_remove_worn` Hook

Fired **after** an item is removed from worn list and return message is printed.

```lua
-- Signature: function(obj, ctx)

on_remove_worn = function(obj, ctx)
    -- De-register armor, remove stat effects, etc.
end
```

### A.2 One-Shot Flavor Text System

Objects declare one-shot messages via `event_output`:

```lua
event_output = {
    on_wear = "This is going to smell worse than I thought.",
    on_remove_worn = "You quickly take it off.",
}
```

**Engine behavior:**
1. Prints message after state change
2. Nils the key (`event_output["on_wear"] = nil`)
3. Subsequent wears/removes don't repeat

### A.3 Appearance Rendering

The appearance subsystem renders worn items in mirror/self-examine:

```lua
-- Object declaration:
appearance = {
    worn_description = "A ceramic chamber pot sits absurdly atop your head.",
}

-- Engine renders via appearance.describe(player, registry)
-- Output: "A ceramic chamber pot sits absurdly atop your head."
```

### A.4 Armor Integration (Material-Derived)

Worn items automatically provide protection based on material properties:

```lua
-- Material property lookup: materials.get(item.material)
-- Formula: prot = hardness*1.0 + flexibility*1.0 + (density/3000)*0.5
-- Modified by: coverage × fit_multiplier × state_multiplier

-- State degradation (FSM):
-- intact (1.0x) → cracked (0.7x) → shattered (0.0x)

-- Example: ceramic pot (wear.coverage = 0.8, fit = "makeshift" = 0.5x)
-- Base ceramic hardness ≈ 7 → protection ≈ 7 × 0.8 × 0.5 = 2.8 points/hit
```

### A.5 Actual Wear Table Properties (From Equipment Handler)

```lua
wear = {
    slot = "head",              -- body location (required)
    layer = "outer",            -- layer: inner/outer/accessory (required)
    
    coverage = 0.8,             -- 0-1, fraction of body covered (armor calc)
    fit = "makeshift",          -- "makeshift"(0.5x), "fitted"(1.0x), "masterwork"(1.2x)
    wear_quality = "makeshift", -- display flavor text
    
    blocks_vision = true,       -- helmet pulls over head → "Everything goes dark"
    provides_armor = N,         -- legacy (now material-derived)
    provides_warmth = true,     -- flavor: "Its warmth immediately envelops you"
    
    max_per_slot = 1,           -- for accessories: count limit
}
```

### A.6 Slot Override Feature

Players can wear items on alternate slots:

```lua
-- Object declaration:
wear = { slot = "feet", layer = "outer" }
wear_alternate = {
    head = { slot = "head", layer = "outer", coverage = 0.6, fit = "makeshift" }
}

-- Player input: WEAR SACK ON HEAD
-- Engine applies alternate config, player feels ridiculous
```

### A.7 Conflict Resolution (Implemented Algorithm)

```lua
-- For each item already worn:
if (new_slot == worn_slot) then
    if (new_layer == "accessory" and worn_layer == "accessory") then
        -- Check max_per_slot counter
        if count >= max_per_slot then reject end
    elseif (new_layer != "accessory" and worn_layer != "accessory") then
        -- Both non-accessory
        if (new_layer == worn_layer) then
            reject "You're already wearing X. Remove it first."
        end
    end
    -- Otherwise: different layers or one is accessory → allow
end
```

### A.8 Two-Hand Inventory Prerequisite

```lua
-- Wear only works if item is in player.hands[1] or player.hands[2]
-- Auto-pickup from room (Infocom pattern):
--   1. Check if item is wearable (has wear table)
--   2. If found in room/container, auto-pick into first empty hand
--   3. Then equip to worn list in same action
```

### A.9 Vision Blocking (Implemented)

```lua
-- If any worn item has: wear.blocks_vision = true
-- Then: all LOOK/EXAMINE of room blocked
--       only inventory items visible
-- Example: sack on head, chamber pot with blocks_vision=true

-- Flavor message: "You pull X over your head. Everything goes dark."
-- Remove message: "You pull X off. Light floods back in."
```

### A.10 Related Files

| File | Purpose |
|------|---------|
| `src/engine/verbs/equipment.lua` | WEAR/REMOVE handlers, conflict detection, state transitions |
| `src/engine/armor.lua` | Material→protection calculation, degradation on impact |
| `src/engine/player/appearance.lua` | Render worn items in mirror description per slot |
| `docs/architecture/engine/event-hooks.md` | Lifecycle documentation for `on_wear`/`on_remove_worn` |

### A.11 Example Objects Shipped

| Object | Slot | Layer | Notes |
|--------|------|-------|-------|
| `chamber-pot.lua` | head | outer | Makeshift helmet, ceramic armor, vision allowed, container while worn |
| `wool-cloak.lua` | back | outer | Provides warmth flavor, no armor, shows in appearance |
| `terrible-jacket.lua` | torso | outer | Makeshift quality, poor armor (fabric), no vision block |
| `bronze-ring.lua` | finger | accessory | Multiple stacking, no armor |

---

**Implementation Verified:** 2026-03-24  
**Shipper:** Smithers (UI/Parser Engineer)  
**Documented By:** Brockman (Documentation Specialist)
