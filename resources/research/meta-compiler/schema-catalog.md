# Schema Catalog: Validation Rules by Template

**Author:** Frink  
**Date:** 2026-03-28  
**Focus:** Formal specification of what makes a valid object, room, or template

---

## Executive Summary

Five template types define valid objects and rooms:

1. **small-item** — Tiny portable items (< 5 size)
2. **container** — Generic containers/bags
3. **furniture** — Heavy immobile objects
4. **room** — Playable spaces with instances and exits
5. **sheet** — (Used for injury/status effects; secondary)

For each, we specify:
- Required fields (must always be present)
- Optional fields (valid but not required)
- Field constraints (type, enum, range, format)
- Template-specific rules (FSM, nesting, references)
- Cross-references (material registry, room targets, state consistency)

---

## 1. small-item Schema

### Purpose
Tiny portable items: coins, keys, shards, consumables, tools. Maximum size ~5, weight <1 typical.

### Required Fields

| Field | Type | Format | Note |
|-------|------|--------|------|
| `guid` | string | `{UUID}` | Must be valid UUID in braces |
| `template` | string | literal | Must equal `"small-item"` |
| `id` | string | `[a-z0-9\-]+` | Kebab-case identifier |
| `name` | string | Any | Human-readable name (e.g., "a brass key") |
| `material` | string | Registry key | Must exist in material registry |
| `keywords` | array[string] | List | At least one keyword for parsing |
| `size` | number | 0-10 | Inventory grid size |
| `weight` | number | ≥ 0 | kg (optional unit) |
| `description` | string | Any | Long-form description |

### Optional Fields

| Field | Type | Scope | Default |
|-------|------|-------|---------|
| `categories` | array[string] | Tags | `[]` |
| `portable` | boolean | Movability | `true` |
| `on_feel` | string | Sensory | Not set |
| `on_smell` | string | Sensory | Not set |
| `on_listen` | string | Sensory | Not set |
| `on_taste` | string | Sensory | Not set |
| `on_look` | function | Callback | Not set |
| `casts_light` | boolean | Light source | `false` |
| `light_radius` | number | If light | Not applicable |
| `provides_tool` | string | Tool system | Not set |
| `burn_duration` | number | Consumable | Not set |
| `container` | boolean | Containment | `false` |
| `capacity` | number | If container | Not applicable |
| `contents` | array[table] | If container | `{}` |
| `states` | table | FSM | Not set |
| `initial_state` | string | FSM | Not set |
| `transitions` | array[table] | FSM | `{}` |
| `prerequisites` | table | Gates | Not set |
| `mutations` | table | Behaviors | `{}` |
| `location` | any | Runtime | `nil` |

### Field Constraints

**guid:** UUID Format
```lua
guid = "{816862a1-c892-45ba-8d0f-2a72315f8eb2}"  -- ✓ Valid
guid = "816862a1-c892-45ba-8d0f-2a72315f8eb2"    -- ✗ Missing braces
guid = "{INVALID}"                                -- ✗ Invalid format
```

**template:** Enum
```lua
template = "small-item"  -- ✓ Valid (must be exactly this)
template = "Small-Item"  -- ✗ Case mismatch
```

**id:** Kebab-Case Pattern
```lua
id = "torch"             -- ✓ Valid
id = "silver-key"        -- ✓ Valid
id = "item_1"            -- ✗ Snake-case, not kebab-case
id = "ItemOne"           -- ✗ CamelCase, not kebab-case
```

**name:** String (No Constraints)
```lua
name = "a burning torch"        -- ✓ Valid
name = ""                       -- ✓ Technically valid but bad UX
```

**material:** Must Exist in Registry
```lua
material = "wood"       -- ✓ Valid (exists in materials/init.lua)
material = "wax"        -- ✓ Valid
material = "unobtanium" -- ✗ Not in registry
```

**keywords:** Non-Empty Array
```lua
keywords = {"torch", "brand", "fire"}  -- ✓ Valid
keywords = {"key"}                     -- ✓ Valid (single keyword)
keywords = {}                          -- ✗ Empty keywords (no search terms)
keywords = "torch"                     -- ✗ String, not array
```

**size:** Number Range [0, 10]
```lua
size = 1                -- ✓ Valid
size = 5                -- ✓ Valid
size = 0                -- ✓ Valid (unusual but allowed)
size = 11               -- ✗ Out of range
size = -1               -- ✗ Negative
size = "large"          -- ✗ String, not number
```

**weight:** Non-Negative Number
```lua
weight = 0              -- ✓ Valid
weight = 1.5            -- ✓ Valid
weight = 50             -- ✓ Valid
weight = -1             -- ✗ Negative
weight = "heavy"        -- ✗ String, not number
```

**description:** String (No Constraints)
```lua
description = "A torch burns..."  -- ✓ Valid
```

### FSM Validation (If States Defined)

If `states` table exists:

1. **initial_state must exist in states**
   ```lua
   initial_state = "lit",
   states = {
       lit = { ... },
       extinguished = { ... },
   }  -- ✓ Valid
   
   initial_state = "burning",  -- ✗ "burning" not in states
   ```

2. **All transitions must reference valid states**
   ```lua
   transitions = {
       { from = "lit", to = "extinguished", ... },  -- ✓ Both exist
       { from = "lit", to = "spent", ... },        -- ✗ "spent" not in states
   }
   ```

3. **No orphan states** (states not used in transitions)
   ```lua
   states = {
       lit = { ... },
       extinguished = { ... },
       unknown = { ... },  -- ✗ Never referenced in transitions
   }
   ```

### Container Validation (If container = true)

1. **capacity must be positive**
   ```lua
   container = true,
   capacity = 8,    -- ✓ Valid
   capacity = 0,    -- ✗ Invalid (can't hold anything)
   ```

2. **contents must be array of valid GUIDs/IDs**
   ```lua
   contents = {
       { id = "item-1", type_id = "{guid}" },  -- ✓ Valid
   }
   ```

### Example: Valid torch

```lua
return {
    guid = "{816862a1-c892-45ba-8d0f-2a72315f8eb2}",
    template = "small-item",
    id = "torch",
    material = "wood",
    keywords = {"torch", "brand", "fire"},
    size = 3,
    weight = 1.5,
    name = "a burning torch",
    description = "A torch burns with a bright, smoky orange flame...",
    on_feel = "Warm wooden shaft, smooth from use...",
    
    casts_light = true,
    light_radius = 4,
    provides_tool = "fire_source",
    
    initial_state = "lit",
    states = {
        lit = { ... },
        extinguished = { ... },
        spent = { ... },
    },
    transitions = { ... },
    
    mutations = {},
}
```

---

## 2. container Schema

### Purpose
Bags, boxes, baskets that hold items. Intermediate between small-item and furniture in size/weight.

### Required Fields

Same as small-item, except:

| Field | Override |
|-------|----------|
| `template` | Must equal `"container"` |
| `container` | Must be `true` |
| `capacity` | Required (number > 0) |

### Additional Constraints

**capacity:** Must be positive integer
```lua
capacity = 4    -- ✓ Valid
capacity = 0    -- ✗ Invalid
```

**weight_capacity:** Optional maximum weight
```lua
weight_capacity = 10    -- ✓ Optional, but if present, must be > 0
```

**max_item_size:** Optional maximum size of items that fit
```lua
max_item_size = 3   -- ✓ Items larger than 3 can't fit
```

---

## 3. furniture Schema

### Purpose
Heavy, immobile objects: beds, wardrobes, desks. Typically not portable.

### Required Fields

Same as small-item, except:

| Field | Override |
|-------|----------|
| `template` | Must equal `"furniture"` |
| `portable` | Typically `false` |

### Constraints

**portable:** Usually false for furniture, but not enforced (edge cases exist)

**size/weight:** Larger typical ranges
```lua
size = 5        -- ✓ Reasonable for furniture
weight = 30     -- ✓ Heavy
```

---

## 4. room Schema

### Purpose
Playable spaces. Top-level containers for instances and exits.

### Required Fields

| Field | Type | Format | Note |
|-------|------|--------|------|
| `guid` | string | `{UUID}` | Must be valid UUID in braces |
| `template` | string | literal | Must equal `"room"` |
| `id` | string | `[a-z0-9\-]+` | Kebab-case |
| `name` | string | Any | Room name (e.g., "The Bedroom") |
| `level` | table | `{ number = N, name = "..." }` | Level reference |
| `keywords` | array[string] | List | At least one keyword |
| `description` | string | Any | Long-form description |
| `instances` | array[table] | Room instances | May be empty array `{}` |
| `exits` | table | Exit map | May be empty table `{}` |

### Optional Fields

| Field | Type |
|-------|------|
| `short_description` | string |
| `on_feel` | string |
| `on_smell` | string |
| `on_listen` | string |
| `on_enter` | function |
| `temperature` | number |
| `moisture` | number |
| `light_level` | number |
| `mutations` | table |

### Room Instances Schema

Each instance in the `instances` array:

```lua
instances = {
    {
        id = "bed",                                    -- Must be unique in room
        type_id = "{8b1e3c6f-4a9d-11e6-b3f5-...}",   -- Object template GUID
        on_top = { ... },                             -- Nesting: items on surface
        contents = { ... },                           -- Nesting: items inside
        nested = { ... },                             -- Nesting: items in slot
        underneath = { ... },                         -- Nesting: items hidden below
    },
}
```

#### Nesting Relationship Keys

**on_top:** Items resting on a surface
```lua
on_top = {
    { id = "pillow", type_id = "{...}" },
    { id = "sheets", type_id = "{...}" },
}
```

**contents:** Items inside a container (cavity, interior)
```lua
contents = {
    { id = "matches", type_id = "{...}" },
}
```

**nested:** Items in a physical slot (like a drawer in a nightstand)
```lua
nested = {
    { id = "drawer", type_id = "{...}", contents = { ... } },
}
```

**underneath:** Items hidden beneath (under rug, under bed)
```lua
underneath = {
    { id = "brass-key", type_id = "{...}" },
    { id = "trap-door", type_id = "{...}", hidden = true },
}
```

### Instance Nesting Validation

1. **id must be unique within room**
   ```lua
   instances = {
       { id = "bed", ... },
       { id = "bed", ... },  -- ✗ Duplicate
   }
   ```

2. **Nesting depth limit: 6 levels** (soft limit, warn if exceeded)
   ```lua
   on_top = {
       { contents = {
           { contents = {
               { contents = {
                   { contents = {
                       { contents = {  -- Level 5, ok
                           { id = "deep", ... }  -- Level 6, ok
                       } }
                   } }
               } }
           } }
       } }
   }
   ```

3. **Forbidden nesting in object files** (nesting only in rooms)
   ```lua
   -- In torch.lua (an object):
   on_top = { ... }  -- ✗ Error: nesting not allowed in objects
   
   -- In start-room.lua (a room):
   on_top = { ... }  -- ✓ Valid: nesting allowed in rooms
   ```

### Room Exits Schema

Exits are a table mapping direction/name to exit definition:

```lua
exits = {
    north = {
        target = "hallway",              -- Room ID to traverse to
        type = "door",                   -- Exit type
        passage_id = "passage-id-1",     -- Unique passage identifier
        name = "a heavy oak door",       -- Display name
        keywords = {"door", "oak"},      -- Search terms
        description = "A heavy door...", -- Visual description
        open = false,                    -- Is exit open?
        locked = true,                   -- Is exit locked?
        hidden = false,                  -- Is exit hidden?
        one_way = false,                 -- One-way passage?
        breakable = true,                -- Can it be broken?
        max_carry_size = 4,              -- Size limit to pass through
        max_carry_weight = 50,           -- Weight limit to pass through
    },
}
```

#### Exit Validation

1. **target must be a valid room ID**
   ```lua
   target = "hallway"      -- ✓ Must exist in src/meta/world/
   target = "invalid-room" -- ✗ Room doesn't exist
   ```

2. **type must be a valid exit type**
   ```lua
   type = "door"       -- ✓ Valid
   type = "window"     -- ✓ Valid
   type = "archway"    -- ✓ Valid
   type = "portal"     -- ✗ Unknown type
   ```

3. **passage_id must be globally unique**
   ```lua
   -- In start-room.lua
   passage_id = "bedroom-hallway-door"
   
   -- In hallway.lua
   passage_id = "bedroom-hallway-door"  -- ✗ Duplicate!
   ```

### Example: Valid start-room

```lua
return {
    guid = "44ea2c40-...",
    template = "room",
    id = "start-room",
    name = "The Bedroom",
    level = { number = 1, name = "The Awakening" },
    keywords = {"bedroom", "chamber"},
    description = "You stand in a dim bedchamber...",
    
    instances = {
        { id = "bed", type_id = "{...}",
            on_top = {
                { id = "pillow", type_id = "{...}" },
            },
        },
        { id = "window", type_id = "{...}" },
    },
    
    exits = {
        north = {
            target = "hallway",
            type = "door",
            passage_id = "bedroom-hallway-door",
            open = false,
            locked = true,
        },
    },
    
    on_enter = function(self) return "You enter the bedroom." end,
    mutations = {},
}
```

---

## 5. sheet Schema

### Purpose
Sheets define status effects, injuries, or modifiers. Secondary to objects/rooms; simpler schema.

### Required Fields

| Field | Type |
|-------|------|
| `guid` | string |
| `template` | string ("sheet") |
| `id` | string |
| `name` | string |
| `description` | string |
| `modifier_type` | string |

### Example

```lua
return {
    guid = "{...}",
    template = "sheet",
    id = "bleeding",
    name = "Bleeding",
    description = "Active blood loss.",
    modifier_type = "condition",
    severity = "moderate",
}
```

---

## 6. Cross-Reference Validation Rules

### Material Registry

Every `material = "..."` value must exist in `src/engine/materials/init.lua`:

```lua
materials.registry = {
    wax = { ... },
    wood = { ... },
    fabric = { ... },
    wool = { ... },
    iron = { ... },
    steel = { ... },
    stone = { ... },
    bone = { ... },
    ceramic = { ... },
    glass = { ... },
    silver = { ... },
    bronze = { ... },
    oak = { ... },
    -- ... others
}
```

**Validation:** All `material` fields must match a key in `materials.registry`.

### Template Validation

Objects must reference a valid template:

```lua
template = "small-item"   -- ✓ Valid
template = "furniture"    -- ✓ Valid
template = "container"    -- ✓ Valid
template = "custom-item"  -- ✗ Not a valid template
```

### Room Target Validation

Exit targets must reference existing rooms:

```lua
target = "hallway"      -- ✓ Must be in src/meta/world/hallway.lua
target = "non-room"     -- ✗ No such room exists
```

### GUID Uniqueness

All GUIDs must be unique across the entire project:

```lua
-- torch.lua
guid = "{816862a1-c892-45ba-8d0f-2a72315f8eb2}"

-- Another file using same GUID
guid = "{816862a1-c892-45ba-8d0f-2a72315f8eb2}"  -- ✗ Duplicate
```

---

## 7. Core Principles to Enforce

From `docs/architecture/objects/core-principles.md`:

1. **Objects Are Inanimate:** No NPC/creature attributes
2. **Room .lua Files Use Deep Nesting:** Nesting syntax validated
3. **Code-Derived Mutable Objects:** Objects have state (mutations)
4. **Base Objects → Instances:** Templates define base; instances override
5. **Objects Have FSM; Instances Know State:** FSM validation if states exist
6. **Composite Objects Encapsulate Inner Objects:** Nesting encapsulation
7. **Multiple Instances Per Base; Each Has GUID:** GUID uniqueness
8. **Objects Exist in Sensory Space:** Sensory fields (on_feel, on_smell, etc.)
9. **Material Consistency:** Material must exist in registry

---

## 8. Validation Pseudocode

```python
def validate_object(filepath, ast):
    template_type = ast["template"]
    schema = SCHEMAS[template_type]
    errors = []
    
    # Check required fields
    for field in schema["required"]:
        if field not in ast:
            errors.append(MissingField(field, filepath, ast))
    
    # Check field types
    for field, value in ast.items():
        constraint = schema["fields"].get(field)
        if constraint and not matches_type(value, constraint["type"]):
            errors.append(TypeError(field, value, constraint, filepath))
    
    # Check cross-references
    if "material" in ast:
        if not material_exists(ast["material"]):
            errors.append(BrokenReference("material", ast["material"], filepath))
    
    # Check FSM (if present)
    if "states" in ast:
        errors.extend(validate_fsm(ast, filepath))
    
    # Check nesting (only in rooms)
    if template_type == "room":
        errors.extend(validate_nesting(ast, filepath))
    
    # Check nesting forbidden (in objects)
    if template_type != "room":
        if has_nesting_keys(ast):
            errors.append(InvalidNesting("nesting not allowed in objects", filepath))
    
    return errors
```

---

## 9. Summary: What Gets Validated

✓ Required fields present  
✓ Field types correct (string, number, boolean, array, table, function)  
✓ Field values in valid enums  
✓ Field values match patterns (GUID, UUID, kebab-case)  
✓ Numeric ranges (size 0-10, capacity > 0)  
✓ Material references resolve  
✓ Template types exist  
✓ Room targets exist  
✓ FSM states consistent  
✓ GUID uniqueness  
✓ Nesting rules (only in rooms)  
✓ Instance ID uniqueness within room  

---

## References

- Core principles: `docs/architecture/objects/core-principles.md`
- Deep nesting: `docs/architecture/objects/deep-nesting-syntax.md`
- Material registry: `src/engine/materials/init.lua`
- Template definitions: `src/meta/templates/`
