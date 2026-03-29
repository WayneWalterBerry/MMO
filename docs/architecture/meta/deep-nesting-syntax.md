# Deep Nesting Architecture & Syntax Reference

**Version:** 1.0  
**Date:** 2026-03-26  
**Author:** Bart (Architecture Lead)  
**Status:** Active — Core Architectural Document  
**Gold standard:** `src/meta/rooms/start-room.lua`

---

## Table of Contents

1. [Philosophy](#1-philosophy)
2. [Room Instance Nesting Keys](#2-room-instance-nesting-keys)
3. [Object Template Rules](#3-object-template-rules)
4. [Syntax Examples](#4-syntax-examples)
5. [Anti-Patterns](#5-anti-patterns)
6. [Engine Integration](#6-engine-integration)
7. [Copy-Paste Templates](#7-copy-paste-templates)

---

## 1. Philosophy

### Why Deep Nesting?

**The nesting IS the room's physical description.** A room `.lua` file is not a flat list of objects with location strings — it is a spatial tree where indentation mirrors physical containment. When you read the Lua, you see the room.

```
Nightstand
  ├── on_top: candle holder
  │     └── contents: candle
  ├── on_top: poison bottle
  └── nested: drawer
        └── contents: matchbox
              └── contents: match-1, match-2, ...
```

This tree IS the nightstand corner of the bedroom. No separate map file. No spatial database. No cross-referencing. The code is the territory.

### The Spatial Model

Objects exist in **physical space**, not abstract databases. Every relationship has a physical analogy:

- A candle **sits on** a nightstand → `on_top`
- Matches are **inside** a matchbox → `contents`
- A drawer **occupies a slot** in a nightstand → `nested`
- A key is **hidden under** a rug → `underneath`

These are not arbitrary metadata tags. They encode **how a player would describe the room in plain English**. The data structure mirrors the physical reality.

### The Visibility Principle

> "If you can't see it in the `.lua`, it doesn't exist in the room."

Every object in the room is declared in the `instances` tree. There is no hidden spawning, no lazy loading, no database lookup. When the engine loads a room, it walks the nesting tree and that tree is the complete, authoritative state of the room.

### Self-Documenting Rooms

A new team member (human or AI) should be able to:

1. Open a room `.lua` file
2. Read the indented structure
3. Understand the physical layout of the room
4. Know where every object is and how it relates to other objects

If the room file requires a separate document to explain where things are, **the room file is wrong**.

---

## 2. Room Instance Nesting Keys

Four relationship keys encode the spatial topology of a room. Each key appears on a **parent** object and contains an array of **child** instances.

### Quick Reference

| Key | Meaning | Example | Default Visibility |
|-----|---------|---------|-------------------|
| `on_top` | Sitting on a surface | candle on nightstand | ✅ Visible immediately |
| `contents` | Inside a container | matchbox in drawer | ❌ Hidden until opened |
| `nested` | Physical slot/component | drawer in nightstand | ✅ Visible as part of parent |
| `underneath` | Hidden below something | brass key under rug | ❌ Hidden until parent moved |

---

### 2.1 `on_top` — Surface Placement

**When to use:** An object is resting on the horizontal surface of another object. Both objects are immediately visible to the player.

**Physical analogy:** You walk into a room and see a candle holder sitting on a nightstand. No interaction needed — it's right there.

```lua
{ id = "nightstand", type = "Nightstand", type_id = "d40b15e6-...",
    on_top = {
        { id = "candle-holder", type = "Candle Holder", type_id = "0aeaff45-..." },
        { id = "poison-bottle", type = "Poison Bottle", type_id = "a1043287-..." },
    },
},
```

**How the engine interprets it:**
- At load time, child objects are registered and their location is set to the parent
- Parent's `surfaces.top.contents` is populated with child IDs
- Children appear in room descriptions (via parent's `on_look` or `room_presence`)

**Player actions:**
- `LOOK` → sees items on the surface
- `TAKE candle holder` → removes from parent's surface
- `PUT X ON nightstand` → adds to parent's `surfaces.top` (if capacity allows)

**When parent is moved/removed:**
- Items on top come with the parent OR fall to the room floor (design choice per object)
- If parent is picked up (portable furniture), surface items transfer to parent's inventory or spill

**Capacity enforcement:** The parent's `surfaces.top.capacity` and `max_item_size` constrain what can be placed. The engine rejects `PUT` if the surface is full or the item is too large.

---

### 2.2 `contents` — Container Contents

**When to use:** An object is inside a container. The container must have `container = true` in its template. Contents are hidden until the container is opened.

**Physical analogy:** You open a drawer and find a matchbox inside. You open the matchbox and find matches.

```lua
{ id = "drawer", type = "Drawer", type_id = "83dda7fe-...",
    contents = {
        { id = "matchbox", type = "Matchbox", type_id = "41eb8a2f-...",
            contents = {
                { id = "match-1", type = "Match", type_id = "009b0347-..." },
                { id = "match-2", type = "Match", type_id = "009b0347-..." },
            },
        },
    },
},
```

**How the engine interprets it:**
- At load time, child objects are registered with location set to the parent container
- Parent's `contents` array is populated with child IDs
- Children are NOT visible until the parent container is opened (`accessible = true`)
- Containers track open/closed state via FSM — `accessible` flips on state transition

**Player actions:**
- `OPEN drawer` → transitions drawer state, sets `accessible = true`
- `LOOK IN drawer` → lists contents (only if open)
- `TAKE matchbox FROM drawer` → removes from parent contents
- `PUT X IN drawer` → adds to parent contents (if capacity allows and accessible)
- `SEARCH drawer` → engine traverses contents (respects accessibility)

**When parent is moved/removed:**
- Contents travel with the container (the matchbox goes wherever the drawer goes)
- `carries_contents = true` on the template confirms this behavior

**Nesting depth:** Contents can nest arbitrarily deep. Drawer → matchbox → matches is three levels. The engine recurses through the tree.

**Key constraint:** Only objects whose template has `container = true` may have a `contents` key in the room file. The engine rejects `PUT X IN Y` if Y is not a container.

---

### 2.3 `nested` — Physical Slot / Component

**When to use:** An object occupies a designed physical slot in its parent. It is NOT "inside" the parent — it is a **component** of the parent. Think: drawer in a nightstand, phone in a cradle, sword in a scabbard.

**Physical analogy:** A nightstand has a rectangular slot where a drawer lives. The drawer is part of the nightstand, visible as a feature of the nightstand, but is its own independent object.

```lua
{ id = "nightstand", type = "Nightstand", type_id = "d40b15e6-...",
    nested = {
        { id = "drawer", type = "Drawer", type_id = "83dda7fe-...",
            contents = {
                { id = "matchbox", type = "Matchbox", type_id = "41eb8a2f-..." },
            },
        },
    },
},
```

**How the engine interprets it:**
- At load time, the nested child is registered as a first-class object with its own GUID
- The child is visible as part of the parent (referenced in parent's `room_presence` and `on_look`)
- The parent's `parts` table (in the template) defines the slot and detach/reattach mechanics

**Player actions:**
- `LOOK nightstand` → description mentions the drawer
- `OPEN drawer` → interacts with the nested object directly
- `PULL drawer` / `REMOVE drawer` → **detaches** the child (becomes independent portable object)
- `PUT drawer IN nightstand` → **reattaches** the child to the parent's slot

**Detach/reattach mechanics (composite parts):**
1. Nested object starts attached → parent FSM state reflects "with_drawer"
2. Player detaches → parent transitions to "without_drawer" state, child becomes room-level object
3. Child retains its own contents (matchbox stays in the detached drawer)
4. Player reattaches → parent transitions back, child returns to slot

**When parent is moved/removed:**
- Nested components travel with the parent (they are physically part of it)
- If the child is detached first, it becomes independent and is NOT affected by parent movement

**Key distinction from `contents`:** A drawer is NOT "inside" the nightstand. It occupies a **slot**. You don't "put the drawer in the nightstand" — you "slide the drawer into its slot." The semantic difference matters for player commands: `PUT X IN nightstand` fails (not a container), but `REATTACH drawer` succeeds (composite slot).

---

### 2.4 `underneath` — Hidden Below

**When to use:** An object is concealed beneath another object. The hidden object is NOT visible until the parent is moved, lifted, or flipped.

**Physical analogy:** A brass key hidden under a rug. A trap door beneath a rug, invisible until the rug is pulled aside.

```lua
{ id = "rug", type = "Rug", type_id = "7275e1d9-...",
    underneath = {
        { id = "brass-key", type = "Brass Key", type_id = "4586b2cd-..." },
        { id = "trap-door", type = "Trap Door", type_id = "a3f8c7d1-...", hidden = true },
    },
},
```

**How the engine interprets it:**
- At load time, children are registered but marked hidden (`hidden = true`)
- Parent's `surfaces.underneath` or `covering` array tracks hidden objects
- Children do NOT appear in room descriptions, search results, or sensory output
- When parent is moved: children are revealed (`hidden` set to `false`)

**Player actions:**
- `LOOK` → does NOT reveal underneath items
- `MOVE rug` / `LIFT rug` → triggers parent's `move_message`, reveals children
- Once revealed, children become normal room-level objects
- `SEARCH` → does NOT find underneath items (they are hidden, not just inaccessible)

**The `hidden = true` flag on children:**
- Items in `underneath` are hidden by default — the `underneath` key implies concealment
- Adding `hidden = true` explicitly on a child provides **extra** concealment: even after the parent moves, the object may require additional discovery (e.g., a trap door that looks like floor)

**When parent is moved/removed:**
- Moving the parent reveals underneath items (the whole point)
- The parent's template declares `movable = true`, `covering = {"trap-door"}`, and includes `move_message` for the reveal narrative
- Revealed items become independent room-level objects

**Relationship to `covering`:** The parent template's `covering` array lists IDs of objects it conceals. When the engine processes `MOVE rug`, it checks `rug.covering`, finds `"trap-door"`, and triggers the trap door's reveal transition (FSM: `hidden` → `revealed`).

---

### Summary: Choosing the Right Key

Ask these questions in order:

```
Is this object ON TOP of the parent (resting on a surface)?
  → on_top

Is this object INSIDE the parent (in a cavity/container)?
  → contents

Is this object a COMPONENT of the parent (occupies a designed slot)?
  → nested

Is this object HIDDEN BENEATH the parent (concealed until parent moves)?
  → underneath

Is this object just in the room (not related to any other object)?
  → Top-level instance (no nesting key)
```

---

## 3. Object Template Rules

The room file describes **where** objects are. The object template describes **what** objects are. The relationship between nesting keys and template capabilities must be consistent.

### 3.1 Containers

**Examples:** drawer, barrel, crate, wardrobe, sack, chest, matchbox, candle holder

**Template characteristics:**
```lua
return {
    container = true,          -- CAN hold items
    capacity = 4,              -- how many items fit
    weight_capacity = 10,      -- weight limit (optional)
    max_item_size = 2,         -- size limit per item
    openable = true,           -- has open/close states (optional)
    accessible = false,        -- starts closed → items hidden
    contents = {},             -- runtime: populated by engine
}
```

**Room file nesting:** Use `contents` key to place items inside.

**Rules:**
- MAY have `contents` in the room file (items placed inside at room creation)
- MAY have `surfaces.inside` in the template (engine-side container surface)
- Player can `PUT X IN Y` — engine checks `container = true` and capacity
- Player can `TAKE X FROM Y` — engine checks accessibility
- Must have capacity limits (`capacity`, `max_item_size`, optionally `weight_capacity`)
- If openable, contents are hidden until opened (`accessible` flips via FSM)

**Wardrobe example (large container):**
```lua
-- Template: wardrobe.lua
surfaces = {
    inside = { capacity = 8, max_item_size = 4, accessible = false, contents = {} },
},
```
```lua
-- Room file: wardrobe with contents
{ id = "wardrobe", type = "Wardrobe", type_id = "9c4701d1-...",
    contents = {
        { id = "wool-cloak", type = "Wool Cloak", type_id = "ecdccb0f-..." },
        { id = "sack", type = "Sack", type_id = "4720ace5-...",
            contents = {
                { id = "needle", type = "Needle", type_id = "07b9daaf-..." },
                { id = "thread", type = "Thread", type_id = "8a7edb7e-..." },
            },
        },
    },
},
```

---

### 3.2 Furniture (Solid — No Internal Storage)

**Examples:** bed, side-table, altar

**Template characteristics:**
```lua
return {
    template = "furniture",
    portable = false,
    container = false,         -- NOT a container — solid construction
    surfaces = {
        top = { capacity = 3, max_item_size = 2, contents = {} },
        -- NO surfaces.inside — this is SOLID furniture
    },
}
```

**Room file nesting:** Use `on_top` key to place items on the surface. Do NOT use `contents`.

**Rules:**
- Have `surfaces.top` ONLY (if they have a flat surface)
- Do **NOT** have `surfaces.inside` — they are SOLID
- Player can `PUT X ON Y` → adds to `surfaces.top`
- Player can **NOT** `PUT X IN Y` → engine rejects (no container capability)
- The engine checks `container == true` before allowing `PUT X IN Y`; furniture fails this check

**Bed example (furniture with top surface and underneath):**
```lua
-- Template: bed.lua
surfaces = {
    top = { capacity = 8, max_item_size = 5, contents = {} },
    underneath = { capacity = 4, max_item_size = 3, contents = {} },
},
```
```lua
-- Room file: bed with items on top and hidden underneath
{ id = "bed", type = "Four-Poster Bed", type_id = "b8e37cb6-...",
    on_top = {
        { id = "pillow", type = "Pillow", type_id = "f973058d-..." },
        { id = "bed-sheets", type = "Bed Sheets", type_id = "6bb22862-..." },
        { id = "blanket", type = "Blanket", type_id = "7eb14362-..." },
    },
    underneath = {
        { id = "knife", type = "Knife", type_id = "b0c650c6-..." },
    },
},
```

**Nightstand example (solid furniture — no inside surface):**
```lua
-- Template: nightstand.lua
surfaces = {
    top = { capacity = 3, max_item_size = 2, contents = {} },
    -- NO surfaces.inside — the nightstand itself is solid wood
},
```

---

### 3.3 Composite Objects (Furniture with Detachable Parts)

**Examples:** nightstand with drawer, desk with drawer, cabinet with doors

**The pattern:** A piece of furniture (the parent) has no internal storage itself. Storage comes from a **nested child object** — a first-class container with its own GUID in the object templates, connected to the parent via the `nested` key in the room file.

**Template characteristics (parent — nightstand):**
```lua
return {
    template = "furniture",
    container = false,             -- nightstand itself is NOT a container
    surfaces = {
        top = { capacity = 3, max_item_size = 2, contents = {} },
        -- NO surfaces.inside
    },
    parts = {
        drawer = {
            id = "nightstand-drawer",
            detachable = true,         -- can be pulled out
            reversible = true,         -- can be put back
            carries_contents = true,   -- contents travel with drawer
            requires_state_match = "open_with_drawer",  -- must be open first
        },
    },
}
```

**Template characteristics (child — drawer):**
```lua
return {
    template = "furniture",
    container = true,              -- drawer IS a container
    openable = true,
    accessible = false,            -- starts closed
    capacity = 2,
    max_item_size = 1,
    reattach_to = "nightstand",    -- knows where it came from
}
```

**Room file nesting:**
```lua
{ id = "nightstand", type = "Nightstand", type_id = "d40b15e6-...",
    on_top = {
        { id = "candle-holder", type = "Candle Holder", type_id = "0aeaff45-..." },
    },
    nested = {
        { id = "drawer", type = "Drawer", type_id = "83dda7fe-...",
            contents = {
                { id = "matchbox", type = "Matchbox", type_id = "41eb8a2f-..." },
            },
        },
    },
},
```

**Key rules for composite objects:**

1. **Parent has NO inside surface.** The nightstand is solid wood. Storage comes from the drawer.
2. **Child is a first-class object** with its own GUID in `src/meta/objects/`. It is not just a surface — it is a real object with FSM states, sensory text, and its own template.
3. **Child nests via `nested` key** in the room file. This indicates a physical slot, not containment.
4. **Child can be detached** (player pulls the drawer out → it becomes an independent portable container).
5. **When detached:** parent FSM transitions to `without_drawer` state; child appears as room-level object.
6. **When reattached:** parent FSM transitions back; child returns to its slot.
7. **Contents travel with the child.** When the drawer is detached, the matchbox (and its matches) come along.

**Detach flow:**
```
OPEN nightstand     → nightstand FSM: closed_with_drawer → open_with_drawer
PULL drawer         → nightstand FSM: open_with_drawer → open_without_drawer
                    → drawer becomes independent room object
                    → drawer retains its contents (matchbox, etc.)
```

**Reattach flow:**
```
PUT drawer IN nightstand  → nightstand FSM: *_without_drawer → *_with_drawer
                          → drawer returns to nested slot
                          → drawer retains its contents
```

---

### 3.4 Covering Objects (Objects That Hide Things Beneath Them)

**Examples:** rug, tarp, blanket on floor, false panel

**Template characteristics:**
```lua
return {
    movable = true,
    moved = false,
    covering = {"trap-door"},      -- IDs of objects this hides
    surfaces = {
        underneath = { capacity = 3, max_item_size = 2, contents = {}, accessible = false },
    },
    move_message = "You grab the edge and pull it aside...",
    moved_room_presence = "The rug lies bunched against the wall...",
}
```

**Room file nesting:**
```lua
{ id = "rug", type = "Rug", type_id = "7275e1d9-...",
    underneath = {
        { id = "brass-key", type = "Brass Key", type_id = "4586b2cd-..." },
        { id = "trap-door", type = "Trap Door", type_id = "a3f8c7d1-...", hidden = true },
    },
},
```

**Reveal mechanics:**
1. `MOVE rug` → engine checks `rug.movable`, fires `move_message`
2. Engine reads `rug.covering` → finds `"trap-door"` → triggers trap door reveal (FSM: `hidden` → `revealed`)
3. Engine reads `rug.surfaces.underneath.contents` → reveals brass key
4. Both objects become visible room-level items
5. Rug transitions to moved state (`moved = true`, description updates)

---

## 4. Syntax Examples

### 4.1 Simple Room — Furniture with Items on Surfaces

A room with a table, some items on it, and a couple of standalone objects.

```lua
return {
    guid = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
    template = "room",

    id = "study",
    name = "The Study",
    description = "A small, dusty study with stone walls lined in empty bookshelves.",
    short_description = "A dusty study.",

    instances = {
        -- Table with items on top
        { id = "writing-desk", type = "Writing Desk", type_id = "{guid}",
            on_top = {
                { id = "ink-pot", type = "Ink Pot", type_id = "{guid}" },
                { id = "quill", type = "Quill", type_id = "{guid}" },
                { id = "journal", type = "Journal", type_id = "{guid}" },
            },
        },

        -- Standalone objects on the floor
        { id = "chair", type = "Wooden Chair", type_id = "{guid}" },
        { id = "fireplace", type = "Fireplace", type_id = "{guid}" },
    },

    exits = { ... },
}
```

**What the player sees:** The writing desk with ink pot, quill, and journal on it. A chair. A fireplace.

---

### 4.2 Room with Containers and Hidden Items

A room with a chest containing items and a wardrobe with nested containers.

```lua
instances = {
    -- Chest: a container with items inside
    { id = "chest", type = "Iron Chest", type_id = "{guid}",
        contents = {
            { id = "gold-ring", type = "Gold Ring", type_id = "{guid}" },
            { id = "pouch", type = "Leather Pouch", type_id = "{guid}",
                contents = {
                    { id = "coin-1", type = "Silver Coin", type_id = "{guid}" },
                    { id = "coin-2", type = "Silver Coin", type_id = "{guid}" },
                },
            },
        },
    },

    -- Wardrobe: large container
    { id = "wardrobe", type = "Wardrobe", type_id = "{guid}",
        contents = {
            { id = "cloak", type = "Wool Cloak", type_id = "{guid}" },
            { id = "boots", type = "Leather Boots", type_id = "{guid}" },
        },
    },
},
```

**Nesting depth:** The chest → pouch → coins is three levels deep. The engine recurses through all levels.

---

### 4.3 Room with Composite Objects (Nightstand + Drawer)

The gold standard pattern from `start-room.lua`:

```lua
instances = {
    { id = "nightstand", type = "Nightstand", type_id = "d40b15e6-...",
        -- Items on the nightstand surface
        on_top = {
            { id = "candle-holder", type = "Candle Holder", type_id = "0aeaff45-...",
                -- Candle inside the holder (holder is a container)
                contents = {
                    { id = "candle", type = "Candle", type_id = "992df7f3-..." },
                },
            },
            { id = "poison-bottle", type = "Poison Bottle", type_id = "a1043287-..." },
        },
        -- Drawer is a physical component, not "inside" the nightstand
        nested = {
            { id = "drawer", type = "Drawer", type_id = "83dda7fe-...",
                -- Items inside the drawer (drawer is a container)
                contents = {
                    { id = "matchbox", type = "Matchbox", type_id = "41eb8a2f-...",
                        -- Matches inside the matchbox (matchbox is a container)
                        contents = {
                            { id = "match-1", type = "Match", type_id = "009b0347-..." },
                            { id = "match-2", type = "Match", type_id = "009b0347-..." },
                            { id = "match-3", type = "Match", type_id = "009b0347-..." },
                        },
                    },
                },
            },
        },
    },
},
```

**Four nesting levels visible in the indentation:**
1. Nightstand (room-level)
2. → Drawer (nested component) / Candle holder (on top)
3. → → Matchbox (inside drawer) / Candle (inside holder)
4. → → → Matches (inside matchbox)

This is the power of deep nesting: the structure IS the physical layout.

---

### 4.4 Room with Underneath Hiding (Rug + Trap Door)

```lua
instances = {
    { id = "rug", type = "Rug", type_id = "7275e1d9-...",
        underneath = {
            { id = "brass-key", type = "Brass Key", type_id = "4586b2cd-..." },
            { id = "trap-door", type = "Trap Door", type_id = "a3f8c7d1-...", hidden = true },
        },
    },
},
```

**Player interaction sequence:**
1. `LOOK` → "A threadbare rug covers the cold stone floor..." (no mention of key or trap door)
2. `FEEL rug` → "One corner feels slightly raised." (hint!)
3. `MOVE rug` → "You grab the edge and pull it aside..." → brass key revealed, trap door revealed
4. `LOOK` → now shows brass key on the floor and the trap door
5. `OPEN trap door` → access to cellar below

---

### 4.5 The Complete Gold Standard — start-room.lua

The bedroom from `src/meta/rooms/start-room.lua` demonstrates every relationship:

```lua
instances = {
    -- === Bed (furniture with surfaces) ===
    { id = "bed", type = "Four-Poster Bed", type_id = "b8e37cb6-...",
        on_top = {                                      -- ← SURFACE
            { id = "pillow", type = "Pillow", type_id = "f973058d-...",
                contents = {                            -- ← CONTAINER (pillow has a pocket)
                    { id = "pin", type = "Pin", type_id = "f5cd5850-..." },
                },
            },
            { id = "bed-sheets", type = "Bed Sheets", type_id = "6bb22862-..." },
            { id = "blanket", type = "Blanket", type_id = "7eb14362-..." },
        },
        underneath = {                                  -- ← HIDDEN
            { id = "knife", type = "Knife", type_id = "b0c650c6-..." },
        },
    },

    -- === Nightstand (composite: furniture + nested drawer) ===
    { id = "nightstand", type = "Nightstand", type_id = "d40b15e6-...",
        on_top = { ... },                               -- ← SURFACE
        nested = {                                      -- ← COMPONENT SLOT
            { id = "drawer", type = "Drawer", type_id = "83dda7fe-...",
                contents = { ... },                     -- ← CONTAINER
            },
        },
    },

    -- === Wardrobe (container furniture) ===
    { id = "wardrobe", type = "Wardrobe", type_id = "9c4701d1-...",
        contents = { ... },                             -- ← CONTAINER
    },

    -- === Rug (covering object) ===
    { id = "rug", type = "Rug", type_id = "7275e1d9-...",
        underneath = { ... },                           -- ← HIDDEN
    },

    -- === Standalone room objects (no nesting) ===
    { id = "window", type = "Window", type_id = "4ecd1058-..." },
    { id = "curtains", type = "Curtains", type_id = "cc981807-..." },
    { id = "chamber-pot", type = "Chamber Pot", type_id = "9a9ff109-..." },
    { id = "bedroom-door", type = "Bedroom Door", type_id = "e4a7f3b2-..." },
},
```

---

### 4.6 ❌ WRONG Patterns — With Explanations

#### Wrong: Flat location strings (removed pattern)

```lua
-- ❌ WRONG — old flat-list pattern
instances = {
    { id = "nightstand", type_id = "{guid}", location = "room" },
    { id = "candle",     type_id = "{guid}", location = "nightstand.top" },
    { id = "drawer",     type_id = "{guid}", location = "nightstand" },
    { id = "matchbox",   type_id = "{guid}", location = "drawer" },
    { id = "match-1",    type_id = "{guid}", location = "matchbox" },
}
```

**Why wrong:** Flat list with string locations destroys readability. You cannot see the spatial tree. You must mentally reconstruct nesting from location strings. Error-prone: a typo in `location = "nighstand"` silently breaks containment.

#### Wrong: `contents` on solid furniture

```lua
-- ❌ WRONG — nightstand is solid furniture, NOT a container
{ id = "nightstand", type = "Nightstand", type_id = "{guid}",
    contents = {
        { id = "matchbox", type = "Matchbox", type_id = "{guid}" },
    },
},
```

**Why wrong:** The nightstand has no inside. You cannot put things "in" it. The matchbox should be in the **drawer** (a container), which is **nested** in the nightstand (a composite slot). Use `nested` for the drawer, then `contents` on the drawer.

#### Wrong: `surfaces.inside` on solid furniture template

```lua
-- ❌ WRONG — nightstand template should NOT have inside surface
return {
    id = "nightstand",
    surfaces = {
        top = { capacity = 3, contents = {} },
        inside = { capacity = 2, contents = {} },  -- ← WRONG: nightstand is solid
    },
}
```

**Why wrong:** If the nightstand has `surfaces.inside`, the engine would accept `PUT X IN nightstand`. But a nightstand is solid wood — you can't put things inside it. The storage comes from the drawer (a nested composite part). Remove `surfaces.inside` from the template.

#### Wrong: Nested component with `surface` mapping

```lua
-- ❌ WRONG — the drawer should NOT be mapped to a parent surface
{ id = "nightstand", type = "Nightstand", type_id = "{guid}",
    nested = {
        { id = "drawer", type = "Drawer", type_id = "{guid}",
            surface = "inside",  -- ← WRONG: drawer is NOT a surface
        },
    },
},
```

**Why wrong:** Nested components occupy **slots**, not surfaces. The drawer is a first-class container object, not a proxy for the nightstand's interior. Remove `surface` — the `nested` key already expresses the relationship.

#### Wrong: Top-level items that should be nested

```lua
-- ❌ WRONG — candle should be on/in the candle holder, not free-floating
instances = {
    { id = "nightstand", type = "Nightstand", type_id = "{guid}" },
    { id = "candle-holder", type = "Candle Holder", type_id = "{guid}" },
    { id = "candle", type = "Candle", type_id = "{guid}" },
}
```

**Why wrong:** The candle is inside the candle holder, which is on the nightstand. Flattening destroys the spatial relationships. The room description would incorrectly show them as three unrelated objects on the floor.

---

## 5. Anti-Patterns

A quick-reference checklist of what NOT to do:

| # | Anti-Pattern | Why It's Wrong | Correct Pattern |
|---|---|---|---|
| 1 | ❌ `location = "room"` flat strings | Destroys spatial tree readability | Deep nesting with relationship keys |
| 2 | ❌ `location = "nightstand.inside"` dot notation | Cross-references instead of inline nesting | Inline `contents` / `on_top` / `nested` / `underneath` |
| 3 | ❌ `surfaces.inside` on solid furniture | Nightstand/bed/altar are solid — not containers | Use `surfaces.top` only; storage via `nested` components |
| 4 | ❌ `surface = "inside"` on nested parts | Nested parts are slot-based, not surface-mapped | `nested` key is sufficient; child is a first-class object |
| 5 | ❌ `contents` on non-containers | Objects without `container = true` cannot hold items | Only use `contents` for objects with `container = true` |
| 6 | ❌ Flat instance lists | Cannot see spatial relationships; location strings are fragile | Deep nesting; structure IS the layout |
| 7 | ❌ Mixing nesting keys on same children | A child has ONE relationship to its parent | Each child exists under exactly one key |
| 8 | ❌ Omitting `type_id` on instances | Engine cannot resolve the base class | Every instance MUST have `type_id` (GUID of the template) |

---

## 6. Engine Integration

### 6.1 Room Load Pipeline

When the engine loads a room `.lua` file, it processes the `instances` tree:

```
1. Parse room file                → get instances array
2. Walk the instance tree         → depth-first traversal of all nesting keys
3. For each instance:
   a. Resolve base class          → look up type_id GUID, deep-merge with template
   b. Apply instance overrides    → sparse overrides win over base class defaults
   c. Register in object registry → indexed by instance id
   d. Set location                → parent id (or "room" for top-level)
4. Build containment:
   - on_top children     → parent.surfaces.top.contents
   - contents children   → parent.contents (container)
   - nested children     → parent.parts (composite slots)
   - underneath children → parent.surfaces.underneath.contents + hidden flags
5. Build room.contents            → IDs of all top-level instances
6. Ready for gameplay
```

### 6.2 How "PUT X IN/ON Y" Resolves

When a player issues a placement command, the engine resolves it against the target's capabilities:

```
"PUT candle ON nightstand"
  1. Find target: nightstand
  2. Check: does nightstand have surfaces.top?
     → YES → check capacity, check item size
     → Add candle to surfaces.top.contents
     → Set candle.location = "nightstand"

"PUT matchbox IN drawer"
  1. Find target: drawer
  2. Check: is drawer a container (container == true)?
     → YES → check accessible (is it open?), check capacity
     → Add matchbox to drawer.contents
     → Set matchbox.location = "drawer"

"PUT matchbox IN nightstand"
  1. Find target: nightstand
  2. Check: is nightstand a container?
     → NO (container == false, no surfaces.inside)
     → REJECT: "You can't put things inside the nightstand."
```

### 6.3 How Search Traverses the Nesting Tree

The `SEARCH` command recursively walks the containment tree, respecting visibility and accessibility:

```
SEARCH room
  → For each object in room.contents:
      Is it hidden? → SKIP
      Is it a container AND accessible? → recurse into contents
      Has surfaces? → check each surface's contents (if accessible)
      Has nested parts? → include visible parts
      Has underneath? → SKIP (hidden until parent moved)

SEARCH drawer (when open)
  → For each object in drawer.contents:
      List the object
      If it's a container AND accessible → recurse deeper
```

**Key rules:**
- `hidden = true` objects are invisible to search
- `accessible = false` containers block search (must open first)
- `underneath` items are never found by search (must MOVE parent)
- Nested parts ARE visible to search (they are physical components, not hidden)

### 6.4 How "MOVE rug" Reveals Underneath Items

```
"MOVE rug"
  1. Find target: rug
  2. Check: rug.movable == true
  3. Execute: set rug.moved = true
  4. Fire: rug.move_message → "You grab the edge and pull it aside..."
  5. Check: rug.covering → ["trap-door"]
     → For each covered ID:
         Find object → trap-door
         Trigger reveal → FSM transition: hidden → revealed
         Set trap-door.hidden = false
         Fire: trap-door.discovery_message
  6. Check: rug.surfaces.underneath
     → For each item in underneath.contents:
         Set item.hidden = false
         Move item to room-level (item.location = "room")
         Fire: reveal message
  7. Update rug: description, room_presence change to moved variants
```

---

## 7. Copy-Paste Templates

### Room File Skeleton

```lua
return {
    guid = "GENERATE-A-UUID-V4-HERE",
    template = "room",

    id = "room-id",
    name = "Room Name",
    level = { number = 1, name = "Level Name" },
    keywords = {"room", "chamber"},
    description = "Full room description.",
    short_description = "Short room description.",

    instances = {
        -- Furniture with items on top
        { id = "table", type = "Wooden Table", type_id = "{guid}",
            on_top = {
                { id = "item-1", type = "Item", type_id = "{guid}" },
            },
        },

        -- Container with items inside
        { id = "chest", type = "Chest", type_id = "{guid}",
            contents = {
                { id = "item-2", type = "Item", type_id = "{guid}" },
            },
        },

        -- Composite object (furniture + nested component)
        { id = "desk", type = "Desk", type_id = "{guid}",
            on_top = {
                { id = "item-3", type = "Item", type_id = "{guid}" },
            },
            nested = {
                { id = "desk-drawer", type = "Drawer", type_id = "{guid}",
                    contents = {
                        { id = "item-4", type = "Item", type_id = "{guid}" },
                    },
                },
            },
        },

        -- Covering object with hidden items
        { id = "carpet", type = "Carpet", type_id = "{guid}",
            underneath = {
                { id = "hidden-item", type = "Item", type_id = "{guid}" },
            },
        },

        -- Standalone objects
        { id = "torch-sconce", type = "Torch Sconce", type_id = "{guid}" },
    },

    exits = {
        north = {
            target = "other-room",
            type = "door",
            passage_id = "room-otherroom-door",
            name = "a wooden door",
            keywords = {"door", "north door"},
            description = "A simple wooden door.",
            open = false,
            locked = false,
            mutations = {},
        },
    },

    on_enter = function(self)
        return "You step into the room."
    end,

    mutations = {},
}
```

### Instance Entry Skeleton

```lua
-- Minimal instance (standalone room object)
{ id = "object-id", type = "Human Name", type_id = "uuid-v4-guid" },

-- Instance with surface items
{ id = "object-id", type = "Human Name", type_id = "uuid-v4-guid",
    on_top = {
        { id = "child-id", type = "Child Name", type_id = "uuid-v4-guid" },
    },
},

-- Instance with contents (parent MUST have container = true in template)
{ id = "container-id", type = "Container Name", type_id = "uuid-v4-guid",
    contents = {
        { id = "item-id", type = "Item Name", type_id = "uuid-v4-guid" },
    },
},

-- Instance with nested component (parent defines part slot in template)
{ id = "parent-id", type = "Parent Name", type_id = "uuid-v4-guid",
    nested = {
        { id = "component-id", type = "Component Name", type_id = "uuid-v4-guid",
            contents = { ... },
        },
    },
},

-- Instance with hidden items underneath
{ id = "cover-id", type = "Cover Name", type_id = "uuid-v4-guid",
    underneath = {
        { id = "hidden-id", type = "Hidden Name", type_id = "uuid-v4-guid" },
        { id = "extra-hidden-id", type = "Name", type_id = "uuid-v4-guid", hidden = true },
    },
},
```

---

## See Also

- **Core Principles:** [`core-principles.md`](core-principles.md) — Principle 0.5 (Deep Nesting overview)
- **Spatial Relationships:** [`spatial-relationships.md`](spatial-relationships.md) — Engine architecture for spatial visibility
- **Instance Model:** [`instance-model.md`](instance-model.md) — Base class vs instance resolution
- **Design Directives:** [`../../design/design-directives.md`](../../design/design-directives.md) — Room Nesting Architecture section
- **Gold Standard Room:** `src/meta/rooms/start-room.lua` — The definitive example

---

*This document is the definitive reference for room nesting syntax. If a room file contradicts this document, the room file is wrong.*
