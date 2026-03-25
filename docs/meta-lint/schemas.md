# Meta-Lint: Schema Definitions

**Date:** 2026-07-19  
**Version:** 2.0  
**Author:** Brockman (Documentation)  
**Purpose:** Complete field contracts for each template type. Meta-Lint enforces these schemas.

---

## What is a Schema?

A schema is a **contract** that defines:
- Which fields are **required**
- Which fields are **optional**
- What **type** each field should be (string, number, boolean, table, function, etc.)
- Valid **value ranges** or **enum values**
- **Inheritance rules** (templates inherit from base templates)

Meta-Lint validates all objects against their template schema.

---

## Template Hierarchy

```
small-item
  ├─ Inherited by: consumables, projectiles, treasures, tools, light-sources
container
  ├─ Inherited by: holdable containers, bags, baskets
furniture
  ├─ Inherited by: stationary objects, fixtures, anchored containers
sheet
  ├─ Inherited by: wearables, armor, textiles, clothing
room
  └─ Inherited by: level rooms, chambers, areas
```

---

## Template: small-item

**File:** `src/meta/templates/small-item.lua`  
**GUID:** `c2960f69-67a2-42e4-bcdc-dbc0254de113`  
**Usage:** Generic portable items (coins, keys, candles, matches, scrolls, etc.)

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `guid` | string | Windows GUID format: `{xxxx-xxxx-...}`. Must be globally unique. |
| `template` | string | Must be `"small-item"`. |
| `id` | string | Kebab-case identifier. Must match filename (without `.lua`). |
| `name` | string | Player-facing name. E.g., `"a tallow candle"`. |
| `keywords` | table | Array of strings for parser matching. E.g., `{"candle", "tallow", "light"}`. |
| `description` | string or function | Detailed description shown on EXAMINE. |
| `on_feel` | string or function | **CRITICAL.** Tactile description — primary sense in darkness. |
| `size` | number | Physical size for containment math. Must be > 0. Typical: 1–3. |
| `weight` | number | Mass for inventory weight tracking. Must be > 0. Typical: 0.1–1.0. |
| `material` | string | Material from registry (wood, iron, glass, fabric, etc.). No `"generic"`. |

### Optional Fields (Recommended)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `location` | nil | nil | Explicitly `nil` for clarity. Computed at runtime. |
| `on_smell` | string or function | nil | Olfactory description. Recommended for immersion. |
| `on_listen` | string or function | nil | Auditory description. |
| `on_taste` | string or function | nil | Gustatory description. Warning: may be dangerous. |
| `categories` | table | {} | String tags: `{"treasure"}`, `{"consumable"}`, etc. Affects gameplay and parser. |
| `mutations` | table | {} | State changes. E.g., `{ burn = { becomes = "ash" } }`. |

### Optional Fields (Advanced)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `portable` | boolean | true | Small items default to portable. If false, flag for review. |
| `container` | boolean | false | Small items are not containers. Set to true only if exceptions exist. |
| `capacity` | number | 0 | Only if `container = true`. Max items that fit inside. |
| `weight_capacity` | number | 0 | Only if `container = true`. Max total weight of contents. |
| `contents` | table | {} | List of contained item GUIDs (computed at runtime, usually empty in definition). |
| `room_presence` | string | nil | How object appears in room description. E.g., `"a candle sits on the nightstand"`. |
| `provides_tool` | string | nil | Grants tool capability to player. E.g., `"fire_source"` (match can light candles). |
| `is_consumable` | boolean | false | If true, object disappears after use. |
| `burn_duration` | number | nil | If set, object produces light for N time units when lit. |

### FSM Extensions (Optional)

| Field | Type | Description |
|-------|------|-------------|
| `states` | table | Finite State Machine definition. E.g., `{ lit = {...}, unlit = {...} }`. |
| `initial_state` | string | Starting state. Must be a key in `states` table. |
| `_state` | string | Current state (runtime, initialize to `initial_state`). |
| `transitions` | table | Array of state transition definitions. Each: `{ from = "...", to = "...", verb = "..." }`. |

### Example: Candle (small-item with FSM)

```lua
return {
    guid = "{12345678-1234-1234-1234-123456789012}",
    template = "small-item",
    id = "candle",
    name = "a tallow candle",
    keywords = {"candle", "tallow", "light"},
    description = "A stubby tallow candle, slightly charred at the wick.",
    on_feel = "Waxy cylinder, cool to the touch.",
    on_smell = "Faint tallow smell.",
    size = 1,
    weight = 0.2,
    material = "wax",
    
    initial_state = "unlit",
    _state = "unlit",
    states = {
        unlit = {
            name = "an unlit candle",
            description = "The candle's wick is dark.",
            on_feel = "Waxy, cool.",
        },
        lit = {
            name = "a lit candle",
            description = "Flames dance on the wick.",
            on_feel = "Waxy, warm from the flame.",
        },
    },
    transitions = {
        { from = "unlit", to = "lit", verb = "light", requires_tool = "fire_source" },
        { from = "lit", to = "unlit", verb = "extinguish" },
    },
    
    mutations = {},
    location = nil,
}
```

---

## Template: container

**File:** `src/meta/templates/container.lua`  
**GUID:** `f1596a51-4e1f-4f9a-a6d0-93b279066910`  
**Usage:** Portable holdable containers (sacks, baskets, chests)

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `guid` | string | Windows GUID format. Globally unique. |
| `template` | string | Must be `"container"`. |
| `id` | string | Kebab-case identifier. |
| `name` | string | Player-facing name. |
| `keywords` | table | Parser matching. |
| `description` | string or function | Detailed description. |
| `on_feel` | string or function | **CRITICAL.** Tactile description. |
| `size` | number | Physical dimensions. Typical: 2–4 for holdable containers. |
| `weight` | number | Mass. Typical: 0.5–2.0. |
| `material` | string | From material registry. |
| `container` | boolean | Must be `true`. Defines this as a holdable container. |
| `capacity` | number | Max items that fit. Must be > 0. Typical: 4–10. |

### Optional Fields (Recommended)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `location` | nil | nil | Explicit nil. Computed at runtime. |
| `on_smell` | string or function | nil | Olfactory description. |
| `on_listen` | string or function | nil | Auditory description. |
| `on_taste` | string or function | nil | Gustatory description. |
| `categories` | table | `{"container"}` | Recommended: at least include `"container"`. |
| `mutations` | table | {} | State changes. E.g., `{ break = { becomes = "broken-sack" } }`. |

### Optional Fields (Advanced)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `portable` | boolean | true | Containers are typically portable. If false, use furniture template instead. |
| `weight_capacity` | number | 0 | Max total weight of contents. If 0, no weight limit. |
| `max_item_size` | number | 0 | Max size of individual items. If 0, no limit. |
| `contents` | table | {} | Array of contained item GUIDs (runtime). |
| `openable` | boolean | false | If true, container has open/close states. |
| `open` | boolean | true | If `openable = true`, is it initially open? |
| `room_presence` | string | nil | How container appears in room. E.g., `"a leather sack lies on the floor"`. |
| `search_priority` | number | 50 | Priority for search order. Higher = searched first. |

### FSM Extensions (Optional)

Containers can have FSM (open/close):

```lua
states = {
    open = {
        name = "an open sack",
        description = "The sack is open, its contents visible.",
        openable = true,
        open = true,
    },
    closed = {
        name = "a closed sack",
        description = "The sack is sealed.",
        openable = true,
        open = false,
    },
},
transitions = {
    { from = "open", to = "closed", verb = "close" },
    { from = "closed", to = "open", verb = "open" },
},
```

### Example: Leather Sack (container)

```lua
return {
    guid = "{87654321-4321-4321-4321-210987654321}",
    template = "container",
    id = "leather-sack",
    name = "a leather sack",
    keywords = {"sack", "leather", "bag"},
    description = "A sturdy leather sack, worn but serviceable.",
    on_feel = "Supple leather, slightly stiff with age.",
    on_smell = "Leather and dust.",
    size = 3,
    weight = 0.8,
    material = "leather",
    
    container = true,
    capacity = 8,
    weight_capacity = 20,
    max_item_size = 3,
    contents = {},
    
    location = nil,
    categories = {"container"},
    mutations = {},
}
```

---

## Template: furniture

**File:** `src/meta/templates/furniture.lua`  
**GUID:** `45a12525-ae7c-4ff1-ba22-4719e9144621`  
**Usage:** Heavy non-portable objects (beds, desks, wardrobes, stationary containers)

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `guid` | string | Windows GUID format. Globally unique. |
| `template` | string | Must be `"furniture"`. |
| `id` | string | Kebab-case identifier. |
| `name` | string | Player-facing name. |
| `keywords` | table | Parser matching. |
| `description` | string or function | Detailed description. |
| `on_feel` | string or function | **CRITICAL.** Tactile description. |
| `size` | number | Physical dimensions. Typical: 5–20. |
| `weight` | number | Mass (heavy). Typical: 10–100. |
| `material` | string | From registry. Typical: wood, oak, stone, iron. |

### Optional Fields (Recommended)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `location` | nil | nil | Explicit nil. Computed at runtime. |
| `on_smell` | string or function | nil | Olfactory description. |
| `on_listen` | string or function | nil | Auditory description. |
| `on_taste` | string or function | nil | Gustatory description. |
| `categories` | table | `{"furniture"}` | Recommended: at least include `"furniture"`. |
| `mutations` | table | {} | State changes. |

### Optional Fields (Advanced)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `portable` | boolean | false | Furniture defaults to non-portable. If true, must declare `hands_required`. |
| `hands_required` | number | nil | If portable, how many hands to carry? (1 or 2) |
| `container` | boolean | false | If true, furniture acts as a container (nightstand with drawer). |
| `capacity` | number | 0 | If container, max items. |
| `contents` | table | {} | Runtime list of contained items. |
| `room_presence` | string | nil | How furniture appears in room. E.g., `"a heavy oak bed dominates the room"`. |
| `surfaces` | table | {} | Named surfaces for placement. E.g., `{ top = {...}, inside = {...} }`. |
| `search_priority` | number | 40 | Priority in search order. |

### FSM Extensions (Optional)

Furniture can have FSM (open/close for drawers, wardrobe doors):

```lua
states = {
    closed = {
        name = "a closed wardrobe",
        description = "The wardrobe doors are closed.",
        surfaces = { front = {...} },
    },
    open = {
        name = an open wardrobe",
        description = "The wardrobe doors are open, revealing shelves.",
        surfaces = { front = {...}, inside = {...} },
    },
},
transitions = {
    { from = "closed", to = "open", verb = "open" },
    { from = "open", to = "closed", verb = "close" },
},
```

### Example: Nightstand with Drawer (furniture container + FSM)

```lua
return {
    guid = "{abcdefab-cdef-abcd-efab-cdefabcdefab}",
    template = "furniture",
    id = "nightstand",
    name = "a wooden nightstand",
    keywords = {"nightstand", "table", "furniture"},
    description = "A small wooden table with a single drawer.",
    on_feel = "Smooth oak wood, cool to the touch.",
    on_smell = "Oak and polish.",
    size = 4,
    weight = 20,
    material = "oak",
    
    container = true,
    capacity = 3,
    contents = {},
    
    initial_state = "drawer-closed",
    _state = "drawer-closed",
    states = {
        ["drawer-closed"] = {
            name = "a closed nightstand",
            description = "The drawer is shut.",
            on_feel = "Smooth, with a recessed drawer.",
        },
        ["drawer-open"] = {
            name = "an open nightstand",
            description = "The drawer is pulled open.",
            on_feel = "Open drawer reveals interior.",
        },
    },
    transitions = {
        { from = "drawer-closed", to = "drawer-open", verb = "open" },
        { from = "drawer-open", to = "drawer-closed", verb = "close" },
    },
    
    location = nil,
    categories = {"furniture"},
    mutations = {},
}
```

---

## Template: sheet

**File:** `src/meta/templates/sheet.lua`  
**GUID:** `ada88382-de1e-4fbc-908c-05d121e02f84`  
**Usage:** Fabric/textile items (sheets, cloaks, rags, armor, clothing)

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `guid` | string | Windows GUID format. Globally unique. |
| `template` | string | Must be `"sheet"`. |
| `id` | string | Kebab-case identifier. |
| `name` | string | Player-facing name. |
| `keywords` | table | Parser matching. |
| `description` | string or function | Detailed description. |
| `on_feel` | string or function | **CRITICAL.** Tactile description. |
| `size` | number | Physical dimensions. Typical: 1–3 for wearables. |
| `weight` | number | Mass. Typical: 0.2–1.0. |
| `material` | string | From fabric-class: fabric, wool, cotton, linen, velvet, burlap, hemp. **Not** iron, glass, etc. |

### Optional Fields (Recommended)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `location` | nil | nil | Explicit nil. Computed at runtime. |
| `on_smell` | string or function | nil | Olfactory description. |
| `on_listen` | string or function | nil | Auditory description. |
| `on_taste` | string or function | nil | Gustatory description. |
| `categories` | table | `{"fabric"}` | Recommended: at least include `"fabric"`. |
| `mutations` | table | {} | State changes. E.g., `{ tear = { spawns = {"cloth-scraps"} } }`. |

### Optional Fields (Advanced)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `portable` | boolean | true | Sheets are typically portable. |
| `container` | boolean | false | Sheets are not containers. |
| `is_wearable` | boolean | false | If true, player can `wear` this item. |
| `worn_on` | string | nil | If wearable: `"body"`, `"head"`, `"feet"`, `"hands"`, etc. |
| `protection` | number | 0 | If armor: protection value (0–1.0). Derived from material + fit. |
| `fit` | string | `"fitted"` | Fit type: `"makeshift"` (0.5×), `"fitted"` (1.0×), `"masterwork"` (1.2×). |
| `room_presence` | string | nil | How sheet appears in room. E.g., `"a tattered cloth hangs on the wall"`. |

### FSM Extensions (Optional)

Sheets can have FSM (intact/torn/shattered for armor):

```lua
states = {
    intact = {
        name = "a wool cloak",
        description = "The cloak is in good condition.",
        on_feel = "Soft wool, well-woven.",
        protection = 0.4,
    },
    torn = {
        name = "a torn wool cloak",
        description = "Large tears expose the lining.",
        on_feel = "Tattered wool, now fragile.",
        protection = 0.2,
    },
},
transitions = {
    { from = "intact", to = "torn", verb = "tear", requires_tool = "sharp_blade" },
},
```

### Example: Wool Cloak (sheet, wearable)

```lua
return {
    guid = "{f1f2f3f4-f5f6-f7f8-f9fa-fbfcfdfeff00}",
    template = "sheet",
    id = "wool-cloak",
    name = "a wool cloak",
    keywords = {"cloak", "wool", "garment"},
    description = "A heavy woolen cloak, dyed deep blue.",
    on_feel = "Thick wool, warm to the touch.",
    on_smell = "Lanolin and dye.",
    size = 2,
    weight = 0.7,
    material = "wool",
    
    is_wearable = true,
    worn_on = "body",
    protection = 0.5,
    fit = "fitted",
    
    location = nil,
    categories = {"fabric", "wearable", "armor"},
    mutations = {
        tear = { spawns = {"cloth-scraps"} },
    },
}
```

---

## Template: room

**File:** `src/meta/templates/room.lua`  
**GUID:** `071e1b6a-17ae-498b-b7af-0cbb8948cd0d`  
**Usage:** Game world rooms/areas

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `guid` | string | Windows GUID format (may be bare without braces in rooms). Globally unique. |
| `template` | string | Must be `"room"`. |
| `id` | string | Room identifier. Used in exit targets. E.g., `"start-room"`, `"cellar"`. |
| `name` | string | Player-facing room name. E.g., `"Bedroom"`. |
| `description` | string | Detailed room description (permanent features only: walls, floor, atmosphere). |

### Optional Fields (Recommended)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `on_feel` | string | nil | Tactile description. How the room feels (cold, warm, smooth walls). |
| `on_smell` | string | nil | Olfactory description. What the room smells like. |
| `on_listen` | string | nil | Auditory description. Environmental sounds. |
| `on_taste` | string | nil | Gustatory description. Rare, but useful for caves. |
| `short_description` | string | nil | Brief description on revisit. Saves text volume. |

### Required Structural Fields

| Field | Type | Description |
|-------|------|-------------|
| `exits` | table | Exit definitions. Keys: direction (e.g., `"north"`, `"south"`, `"up"`, `"down"`). |
| `instances` | table | Array of object instances in the room. Each has `id`, `type_id`, and nested children. |

### Optional Structural Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `keywords` | table | {} | Room keywords for parser (rarely used). |
| `contents` | table | {} | Runtime list of instance GUIDs. |
| `level` | table | nil | `{ number = 1, name = "Level 1" }` — which level this room is in. |
| `categories` | table | {} | Room tags (e.g., `{"indoor"}`, `{"dangerous"}`). |

### Exit Fields (Within `exits` table)

| Field | Type | Description |
|-------|------|-------------|
| `north` / `south` / ... | table | Exit definition. Contains: `target`, `type`, `name`, `description`, `keywords`, `locked`, `open`. |
| `target` | string | Room ID to exit to. E.g., `"hallway"`. Or PENDING: `"level-2"` (future room). |
| `type` | string | Exit type: `"door"`, `"stairway"`, `"window"`, `"trap_door"`, `"passage"`, etc. |
| `name` | string | Player-facing exit name. E.g., `"a wooden door"`. |
| `description` | string | Description of the exit. E.g., `"An old oak door, slightly warped."`. |
| `keywords` | table | Keywords for parser. E.g., `{"door", "oak"}`. |
| `locked` | boolean | Is the exit locked? |
| `open` | boolean | Is the exit currently open? (For doors) |
| `key_id` | string | Object ID of the key that unlocks this exit (if applicable). |
| `passage_id` | string | Shared passage ID (for bidirectional consistency). |
| `one_way` | boolean | If true, exit only goes one direction (trap). |

### Instance Fields (Within `instances` array)

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Instance identifier within room. E.g., `"nightstand"`. |
| `type_id` | string | GUID of the object template. Must match an object file's `guid`. |
| `on_top` | table | Objects sitting on this instance's top surface. Array of instances. |
| `contents` | table | Objects inside this instance (if it's a container). Array of instances. |
| `nested` | table | Objects in slots within this instance. Array of instances. |
| `underneath` | table | Objects hidden underneath this instance. Array of instances. |

### Example: Bedroom (room)

```lua
return {
    guid = "11111111-1111-1111-1111-111111111111",
    template = "room",
    id = "start-room",
    name = "Bedroom",
    description = "You are in a modest bedroom. Pale morning light filters through heavy curtains.",
    on_feel = "Cool wooden floor, slightly drafty.",
    on_smell = "Dust and old fabric.",
    short_description = "You are back in the bedroom.",
    
    exits = {
        north = {
            target = "hallway",
            type = "door",
            name = "a wooden door",
            description = "A heavy oak door, slightly swollen from age.",
            keywords = {"door", "oak"},
            locked = false,
            open = false,
        },
    },
    
    instances = {
        {
            id = "nightstand",
            type_id = "abcdefab-cdef-abcd-efab-cdefabcdefab",
            on_top = {
                { id = "candle", type_id = "12345678-1234-1234-1234-123456789012" },
            },
            contents = {
                { id = "matches", type_id = "87654321-4321-4321-4321-210987654321" },
            },
        },
    },
    
    keywords = {},
    contents = {},
    level = { number = 1, name = "Level 1" },
    categories = {"indoor"},
    mutations = {},
}
```

---

## Field Type Reference

| Type | Lua Representation | Example |
|------|-------------------|---------|
| String | `"value"` | `"candle"`, `"lit"`, `"{uuid}"` |
| Number | `1`, `0.5`, `-42` | `1`, `0.5`, `42` |
| Boolean | `true`, `false` | `true` |
| Table | `{ key = value, ... }` | `{ name = "x", id = "y" }` |
| Array | `{ value1, value2, ... }` | `{"candle", "tallow"}` |
| Function | `function(...) ... end` | `function(ctx) return "X" end` |
| Nil | `nil` | `nil` (absence of value) |

---

## Validation Steps for Schemas

Meta-Lint validates objects in this order:

1. **File Structure** — Does the file return a table?
2. **Required Fields** — Are all required fields present?
3. **Field Types** — Does each field have the correct type?
4. **Field Values** — Are values in valid ranges (positive numbers, known materials, etc.)?
5. **Cross-Field Consistency** — Do interdependent fields align?
6. **Cross-File References** — Do all references (GUIDs, material names) resolve?

---

## Inheritance and Overrides

Objects inherit from templates but can override any field:

```lua
-- Template default:
small-item: { portable = true }

-- Object override:
candle: { template = "small-item", portable = false }  -- Unusual but allowed

-- Meta-Lint will flag this as a warning (small items should be portable)
```

---

## Common Schema Violations

| Violation | Severity | Fix |
|-----------|----------|-----|
| Missing `on_feel` | 🔴 | Add: `on_feel = "Tactile description."` |
| `material = "generic"` in real object | 🟡 | Replace with actual material name. |
| `capacity = 0` on container | 🔴 | Set positive capacity. |
| Duplicate GUID across files | 🔴 | Generate new GUID. |
| `initial_state` not in `states` | 🔴 | Add state definition or fix initial_state value. |
| `type_id` in room doesn't match object GUID | 🔴 | Correct the GUID reference. |

---

## Schema: Template Definition (V2)

**Files:** `src/meta/templates/*.lua`  
**New in V2.** Templates define field contracts for objects. They are NOT objects themselves — they have no `template` field.

### Physical Template (container, furniture, small-item, sheet)

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `guid` | string | ✅ | Bare format (no braces) |
| `id` | string | ✅ | Must match filename |
| `name` | string | ✅ | Display name |
| `keywords` | table | ✅ | Empty valid for templates |
| `description` | string | ✅ | |
| `size` | number | ✅ | > 0 |
| `weight` | number | ✅ | > 0 |
| `portable` | boolean | ✅ | |
| `material` | string | ✅ | "generic" acceptable |
| `container` | boolean | ✅ | |
| `capacity` | number | ✅ | >= 0 |
| `contents` | table | ✅ | Should be empty |
| `location` | nil | 🟡 | Structural clarity |
| `categories` | table | 🟡 | Strings if present |
| `mutations` | table | 🟡 | Even if empty |

### Room Template

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `guid` | string | ✅ | Bare format |
| `id` | string | ✅ | "room" |
| `name` | string | ✅ | |
| `keywords` | table | ✅ | |
| `description` | string | ✅ | |
| `contents` | table | ✅ | Empty |
| `exits` | table | ✅ | Empty |
| `mutations` | table | 🟡 | |

### Key Constraints

- Templates must NOT declare a `template` field (TD-09).
- Container template: `container = true`, `capacity > 0` (TD-21, TD-22).
- Room template must NOT have physical properties: `size`, `weight`, `portable`, `material`, `capacity`, `container` (TD-24).
- Sheet template `material` should be fabric-class (TD-27).

---

## Schema: Injury Definition (V2)

**Files:** `src/meta/injuries/*.lua`  
**New in V2.** Injuries define damage models, FSM states, transitions, and healing interactions.

### Required Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `guid` | string | ✅ | Braced format `{xxxx-xxxx-...}` |
| `id` | string | ✅ | Must match filename |
| `name` | string | ✅ | Display name |
| `category` | string | ✅ | physical / environmental / toxin / unconsciousness |
| `description` | string | ✅ | |
| `damage_type` | string | ✅ | "over_time" or "one_time" |
| `initial_state` | string | ✅ | Key in `states` table |
| `on_inflict` | table | ✅ | `{initial_damage, damage_per_tick, message}` |
| `states` | table | ✅ | Keyed by state name. Min 2. Each has `name`, `description`. Non-terminal: `on_feel`, `damage_per_tick`. Terminal: `terminal = true`. |
| `transitions` | table | ✅ | Array of `{from, to, verb/trigger, message}`. |
| `healing_interactions` | table | ✅ | Keyed by item ID. Each has `transitions_to`, `from_states`. |

### Optional Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `causes_unconsciousness` | boolean | optional | Only for concussion-type |
| `unconscious_duration` | table | optional | Requires `causes_unconsciousness = true` |

### State Structure

Each entry in the `states` table:

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `name` | string | ✅ | State display name |
| `description` | string | ✅ | |
| `on_feel` | string | ✅ (non-terminal) | Tactile description |
| `damage_per_tick` | number | ✅ (non-terminal) | >= 0 |
| `terminal` | boolean | optional | `true` for healed/fatal states |
| `on_look` | string | 🟢 | Visual description |
| `on_smell` | string | 🟢 | For bleeding/infected states |
| `timed_events` | table | optional | `[{event, delay, to_state}]` |
| `restricts` | table | optional | `{action = true}` |

### Healing Interaction Structure

Each entry in `healing_interactions` (keyed by item ID):

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `transitions_to` | string | ✅ | Target state (must exist in `states`) |
| `from_states` | table | ✅ | Array of state names (should be non-terminal) |

---

## Schema: Material Definition (V2)

**Files:** `src/meta/materials/*.lua`  
**New in V2.** Materials define physical properties used by the containment and effects systems.

### Required Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `name` | string | ✅ | Must match filename |
| `density` | number | ✅ | > 0, kg/m³ |
| `hardness` | number | ✅ | 0–10 |
| `flexibility` | number | ✅ | 0.0–1.0 |
| `absorbency` | number | ✅ | 0.0–1.0 |
| `opacity` | number | ✅ | 0.0–1.0 |
| `flammability` | number | ✅ | 0.0–1.0 |
| `conductivity` | number | ✅ | 0.0–1.0 |
| `fragility` | number | ✅ | 0.0–1.0 |
| `value` | number | ✅ | > 0, integer |
| `melting_point` | number/nil | ✅ | nil = doesn't melt |
| `ignition_point` | number/nil | ✅ | nil = doesn't ignite |

### Optional Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `rust_susceptibility` | number | optional | 0.0–1.0, ferrous materials only |

### Cross-Field Constraints

- `flammability > 0` requires `ignition_point` to be set (MD-17).
- `flammability = 0` implies `ignition_point` should be nil (MD-18).
- High `flexibility` + high `fragility` is unusual — flagged as warning (MD-20).
- `conductivity > 0` on non-metal is info-level (MD-21).
- Materials must NOT have `guid` or `id` fields (MD-04, MD-05).

---

## Schema: Level Definition (V2)

**Files:** `src/meta/levels/*.lua`  
**New in V2.** Extended schema covering intro, completion, boundaries, and restricted objects.

### Required Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `guid` | string | ✅ | Bare format |
| `template` | string | ✅ | Must be "level" |
| `number` | number | ✅ | Positive integer, unique |
| `name` | string | ✅ | Level title |
| `description` | string | ✅ | Narrative arc |
| `rooms` | table | ✅ | Non-empty array of room ID strings |
| `start_room` | string | ✅ | Must be in `rooms` list |

### Recommended Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `intro` | table | 🟡 | `{title, narrative: [strings], help, subtitle?}` |
| `completion` | table | 🟡 | `[{type, room, from?, message}]` |
| `boundaries` | table | 🟡 | `{entry: [rooms], exit: [{room, exit_direction, target_level}]}` |

### Optional Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `restricted_objects` | table | optional | Array of object ID strings |

### Intro Structure

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `title` | string | ✅ | Non-empty |
| `narrative` | table | ✅ | Array of strings |
| `help` | string | 🟡 | Help text for new players |
| `subtitle` | string | 🟢 | String if present |

### Completion Structure

Each entry in the `completion` array:

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `type` | string | ✅ | E.g., "reach_room" |
| `room` | string | ✅ (for reach_room) | Must be in `rooms` list |
| `from` | string | 🟡 | Source room reference |
| `message` | string | 🟡 | Player-facing completion text |

### Boundaries Structure

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `entry` | table | ✅ | Non-empty array of room IDs in `rooms` list |
| `exit` | table | 🟡 | Array of exit definitions |

Each exit in `boundaries.exit`:

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `room` | string | ✅ | Must be in `rooms` list |
| `exit_direction` | string | ✅ | Direction on the room |
| `target_level` | number | ✅ | Should be > current `number` |

---

## References

- **Template Files:** `src/meta/templates/` (source definitions)
- **Object Examples:** `src/meta/objects/` (83 objects following these schemas)
- **Room Examples:** `src/meta/world/` (7 rooms following room schema)
- **Injury Definitions:** `src/meta/injuries/` (7 injury types)
- **Material Definitions:** `src/meta/materials/` (17+ materials)
- **Level Definitions:** `src/meta/levels/` (level configurations)
- **Rules:** `docs/meta-lint/rules.md` (validation rules per field)

