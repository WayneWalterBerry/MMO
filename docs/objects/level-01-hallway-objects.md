# Level 1 — Hallway Objects

**Room:** The Manor Hallway / The Ground Floor Corridor  
**Room ID:** `hallway`  
**Author:** Flanders (Object Designer)  
**Date:** 2026-07-21  
**Status:** Specification — Ready for Build  
**Source:** `docs/levels/level-01-intro.md` (CBG Master Design)

---

## Room Context

A wide, wood-paneled corridor lit by flickering torches in wall brackets. Polished oak floor, clean and well-maintained. Portraits line the walls. Warmer here — almost welcoming after the cold cellars. Doors lead off to other rooms (locked). At the far end, a grand staircase ascends.

**Connections:**
- DOWN → Deep Cellar (stone stairway — player just came through)
- SOUTH → Bedroom (oak door — connects to bedroom's NORTH exit)
- NORTH → Level 2 (grand staircase or corridor — level transition)

**Puzzle Support:**
- None — this is a reward/transition room. No puzzles.

**Total Objects:** 5 new base objects

**New Materials Needed:**
- None — all materials available in registry.

---

## Object 1: torch

### Identity
| Field | Value |
|-------|-------|
| **id** | `torch` |
| **name** | "a burning torch" |
| **keywords** | torch, brand, firebrand, flambeau, light, fire |
| **categories** | light source, tool, wooden |
| **weight** | 1.5 (kg — wooden shaft wrapped in pitch-soaked rags) |
| **size** | 3 (medium — about three feet long) |
| **portable** | Yes (removable from bracket) |

### Material
`wood` — ✓ In registry. Wooden shaft. The burning head is pitch-soaked fabric wrapped around the end.

### FSM States & Transitions

```
lit → extinguished ↔ relit → spent (terminal)
```

**Note:** Torches in the hallway START in `lit` state (the hallway is already illuminated).

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell | on_listen | Special |
|-------|--------------------|--------------------|----------|-----------|---------|
| lit | A torch burns with a bright, smoky orange flame. The pitch-soaked rags at the head crackle and spit. It throws harsh, dancing light — cruder than a candle, but far brighter. Smoke curls upward, blackening the ceiling. | Warm wooden shaft, smooth from use. The head radiates intense heat — don't touch that end. | Burning pitch and smoke. Sharp, resinous, and slightly acrid. A working smell. | Crackling and spitting. The pitch pops and hisses. A low roar from the flame. | `casts_light = true, light_radius = 4, provides_tool = "fire_source"` |
| extinguished | A torch, recently put out. The head is a charred mass of rags and pitch, still smoking faintly. The wooden shaft is warm. It could be relit. | Warm wood. The head is hot and sticky with half-melted pitch — don't grab that end. Charred fabric crumbles at the touch. | Hot pitch and smoke. Dying embers. | A faint hissing as the pitch cools. | `casts_light = false` |
| spent | A burnt-out torch. The wooden shaft is charred halfway down. The head is a lump of carbon and ash. It's done. | Charred wood, crumbly. The head is a brittle carbon mass that breaks apart in your hand. | Stale smoke and cold carbon. | Silent. | `casts_light = false, terminal = true` |

**Transitions:**

| From | To | Verb | Guard / Requires | Message | Mutate |
|------|-----|------|-----------------|---------|--------|
| lit | extinguished | extinguish, put out, douse, snuff | — | "You smother the torch. The flame dies with a hiss and a curl of acrid smoke. The head glows dull orange for a moment, then fades." | `weight = function(w) return w * 0.8 end, keywords = { add = "extinguished" }` |
| extinguished | lit | light, relight, ignite | `requires_tool = "fire_source"` | "The pitch catches again, and the torch roars back to life. Bright orange flame, heat, and the smell of burning resin." | `keywords = { remove = "extinguished" }` |
| lit | spent | — | `trigger = "auto", condition = "timer_expired"` | "The torch gutters, spits, and dies. The last of the pitch is consumed, leaving a charred stump trailing a thin banner of smoke." | `weight = 0.5, categories = { remove = "light source" }, keywords = { add = "spent", add = "charred" }` |

**Timer:**
```lua
burn_duration = 10800,   -- 3 hours game time (30 ticks) — longer than candle, shorter than lantern
remaining_burn = 10800,
```

### Spatial Context
- **Location:** In wall brackets (torch-bracket instances) along the hallway walls. 2-3 torch instances.
- **room_presence (lit):** "Torches burn in iron brackets along the walls, casting dancing orange light."
- **room_presence (extinguished):** "A spent torch smolders in its bracket."

### GOAP Prerequisites
```lua
prerequisites = {
    light = { requires = {"fire_source"} },
}
```

### Puzzle Role
- None directly. The torches illuminate the hallway (reward after dark cellars). Player can take one as a portable light source for exploring other areas.
- **Strategic choice:** Torch is brighter (radius 4) but heavier and burns faster than the lantern. Trade-off.

### Principle 8 Compliance
Consumable cycle FSM matching the candle pattern. Timer-based auto-depletion. All behavior in metadata.

---

## Object 2: portrait

### Identity
| Field | Value |
|-------|-------|
| **id** | `portrait` |
| **name** | "a portrait" |
| **keywords** | portrait, painting, picture, face, frame, art |
| **categories** | decorative, wooden |
| **weight** | 5 (kg — heavy wooden frame, canvas) |
| **size** | 4 (large — about three feet tall in heavy frame) |
| **portable** | No (hung on wall, could be removed but heavy/awkward) |

### Material
`wood` — ✓ In registry (frame). Canvas is `fabric` ✓.

### FSM States & Transitions
None — static object. Examinable only.

### Sensory Properties

**Note:** Multiple portrait instances, each with different description overrides. Below is the base object; instance overrides provide unique faces, names, and lore per portrait.

**Base sensory properties:**

| Sense | Description |
|-------|-------------|
| description | A portrait in a heavy gilded frame, depicting [subject — instance override]. The paint is dark with age and varnish, but the face is clear — stern eyes that seem to follow you. A small brass plate at the bottom reads [name — instance override]. |
| on_feel | Heavy wooden frame, carved and gilded — the gold leaf is flaking. The canvas is rough under your fingers. The frame is bolted to the wall. |
| on_smell | Old varnish and linseed oil. Dust in the frame's crevices. |

**Instance Overrides (examples for 3 portraits):**

```lua
-- Portrait 1: The Patriarch
{ type_id = "portrait", overrides = {
    name = "a portrait of Lord Aldric Blackwood",
    description = "A portrait of a stern, bearded man in black robes. His eyes are pale and cold. One hand rests on a book; the other holds a silver key. A brass plate reads: 'Lord Aldric Blackwood, Founder, 1138-1197.'",
    on_look_detail = "The book under his hand is open to a page covered in symbols — the same symbols carved on the altar below. His expression is not cruel, exactly. It's the face of a man who made hard choices and never regretted them.",
}}

-- Portrait 2: The Scholar
{ type_id = "portrait", overrides = {
    name = "a portrait of Lady Eleanor Blackwood",
    description = "A portrait of a woman with dark hair and sharp features, dressed in a blue gown. She holds a quill, poised over a scroll. Her expression is knowing — almost amused. A brass plate reads: 'Lady Eleanor Blackwood, Keeper, 1165-1221.'",
    on_look_detail = "The scroll under her quill bears text too small to read in the painting. But the symbols on its border match those on the deep cellar altar. The 'Keeper' — of what?",
}}

-- Portrait 3: The Last
{ type_id = "portrait", overrides = {
    name = "a portrait of a young man",
    description = "A portrait of a young man, barely out of boyhood, in a dark doublet. His face is pale and haunted — dark circles under wide eyes. No brass plate at the bottom — just an empty bracket where one was removed. The newest painting in the row.",
    on_look_detail = "This is the most recent portrait. The young man looks frightened. His hand is raised, palm out, as if warding something away. Or reaching for help.",
}}
```

### Spatial Context
- **Location:** Hung on the walls along the hallway. 3 portrait instances.
- **room_presence:** "Portraits of stern-faced figures line the walls, their eyes following you in the torchlight."

### Puzzle Role
- **Lore delivery:** Portraits establish the Blackwood family (or whatever Wayne decides). The names, dates, and titles provide backstory about the manor's inhabitants.
- **Foreshadowing:** The last portrait (no nameplate, frightened face) hints at recent events.

### Principle 8 Compliance
Static metadata objects with instance overrides for unique content. No engine-specific code.

---

## Object 3: side-table

### Identity
| Field | Value |
|-------|-------|
| **id** | `side-table` |
| **name** | "an oak side table" |
| **keywords** | table, side table, hall table, oak table, small table |
| **categories** | furniture, wooden |
| **weight** | 20 (kg) |
| **size** | 4 (large) |
| **portable** | No |

### Material
`oak` — ✓ In registry. Polished dark oak with turned legs.

### FSM States & Transitions
None — static furniture.

### Sensory Properties

| Sense | Description |
|-------|-------------|
| description | A narrow oak table with turned legs, placed against the wall between two portraits. Its top is polished to a dark gleam. A ceramic vase sits upon it, stuffed with dry flowers. The table is clean — no dust. Someone maintains this hallway. |
| on_feel | Smooth polished oak, warm after the cold stone of the cellars. Turned legs, steady — good craftsmanship. Not a scratch on it. |
| on_smell | Beeswax polish and old wood. A faint floral scent from the dry flowers. |

### Surfaces
```lua
surfaces = {
    top = {
        capacity = 3, max_item_size = 2, weight_capacity = 10,
        contents = {"vase-1"},
        accessible = true,
    },
}
```

### Spatial Context
- **Location:** Against the east wall, between portraits
- **room_presence:** "A polished oak side table stands between the portraits, a vase of dry flowers upon it."

### Puzzle Role
- None. Environmental furniture. Its cleanliness is a worldbuilding detail — the hallway is maintained, unlike the dusty cellars.

### Principle 8 Compliance
Static furniture with surface. Standard metadata pattern.

---

## Object 4: vase

### Identity
| Field | Value |
|-------|-------|
| **id** | `vase` |
| **name** | "a ceramic vase" |
| **keywords** | vase, ceramic vase, pot, flower vase, urn |
| **categories** | decorative, fragile, ceramic, container |
| **weight** | 2 (kg — with dried flowers) |
| **size** | 2 (small) |
| **portable** | Yes |

### Material
`ceramic` — ✓ In registry. Glazed ceramic, deep blue with gold accents.

### FSM States & Transitions

```
intact → broken (terminal)
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell |
|-------|--------------------|--------------------|----------|
| intact | A tall ceramic vase, glazed deep blue with gold bands around the neck. Dry flowers — lavender and baby's breath — sprout from the top in a dusty bouquet. The glaze catches the torchlight. | Smooth, cool ceramic. Rounded belly, narrow neck. Dry flowers bristle at the top — papery and brittle. The glaze is glass-smooth under your fingers. | Dried lavender — faint but still present after all this time. Dust. |
| broken | Shattered ceramic and scattered dry flowers litter the floor. Blue and gold shards, petals, and dust. | Sharp ceramic edges — careful! Dry flower petals crumble between your fingers. | Lavender, stronger now that the flowers are crushed. Ceramic dust. |

**Transitions:**

| From | To | Verb | Guard / Requires | Message | Mutate |
|------|-----|------|-----------------|---------|--------|
| intact | broken | break, smash, drop, throw, knock | — | "The vase hits the floor and shatters. Blue and gold shards skitter across the polished oak, trailing dry lavender petals. The flowers' scent releases one last time, stronger in death." | `weight = 0, categories = { remove = "container" }` (spawns glass-shard equivalent — ceramic-shard) |

### Spatial Context
- **Location:** On top of side-table
- **room_presence:** Described as part of the side-table.

### Puzzle Role
- None directly. Breaking it is a choice with no reward — teaches that destruction isn't always useful. The lavender scent mirrors the bedroom (continuity).

### Principle 8 Compliance
Simple destructible object. Two-state FSM. Behavior in metadata.

---

## Object 5: locked-door

### Identity
| Field | Value |
|-------|-------|
| **id** | `locked-door` |
| **name** | "a locked oak door" |
| **keywords** | door, locked door, oak door, wooden door, side door |
| **categories** | architecture, wooden |
| **weight** | — (architectural, immovable) |
| **size** | 6 (massive) |
| **portable** | No |

### Material
`oak` — ✓ In registry. Heavy oak door with iron fittings.

### FSM States & Transitions

```
locked (only state in Level 1)
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell | on_listen |
|-------|--------------------|--------------------|----------|-----------|
| locked | A heavy oak door with iron bands and a large keyhole. It doesn't budge when you push. A brass plate above the handle reads [room name — instance override: "Study", "Library", "Dining Hall"]. Beyond this door lies the rest of the manor — but not today. | Heavy oak, iron bands crossing the surface. The handle turns but the bolt holds fast. A large keyhole — you can feel the lock mechanism. | Oak and iron. Faint traces from beyond — [instance override: "leather and paper", "old food and candle smoke"]. | Nothing from the other side. Or — is that the wind? Hard to tell. |

**Transitions:**
None in Level 1. The door is permanently locked for this level. In Level 2, the FSM could expand to `locked → unlocked → open`.

**Fail Messages:**
- `open` / `push` / `pull`: "The door is locked. It doesn't move. Through the keyhole, you can make out [room hint — instance override]."
- `break` / `kick`: "The oak is thick and the iron bands are solid. This door was built to keep people out. You'll need a key."
- `pick lock` (with pin): "The lock is far too complex for a simple pin. This needs a proper key."

### Spatial Context
- **Location:** Along the hallway walls. 2-3 instances, each leading to a different locked room.
- **room_presence:** "Oak doors with brass plates line the hallway — all locked."

### Puzzle Role
- **Level 2 foreshadowing:** The locked doors tell the player there's more to explore. They set expectations for the next level.
- **Boundary enforcement:** Prevents the player from accessing Level 2 content prematurely.

### Principle 8 Compliance
Single-state object with fail messages for attempted interactions. Future FSM expansion is data-only.

---

## Object Interaction Map

```
                    Hallway — Object Relationships

    [torch] × 2-3 ── in torch-bracket (existing object type from cellar)
         │                provides light, removable
         │
    [portrait] × 3 ── lore delivery via instance overrides
         │                Blackwood family history
         │
    [side-table] ── surface: top ── [vase]
         │                              │
         │                         breakable (cosmetic only)
         │
    [locked-door] × 2-3 ── Level 2 boundary
         │
    EXIT NORTH → Level 2 (grand staircase / corridor)
    EXIT DOWN → Deep Cellar (stairway)
    EXIT SOUTH → Bedroom (oak door)
```

---

## Summary

| # | Object | Material | FSM? | Portable | Puzzle |
|---|--------|----------|------|----------|--------|
| 1 | torch | wood ✓ | Yes (3 states) | Yes | — (utility) |
| 2 | portrait | wood/fabric ✓ | No | No | Lore delivery |
| 3 | side-table | oak ✓ | No | No | — (furniture) |
| 4 | vase | ceramic ✓ | Yes (2 states) | Yes | — (cosmetic) |
| 5 | locked-door | oak ✓ | No (1 state) | No | L2 boundary |
