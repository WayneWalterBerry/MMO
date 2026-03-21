# Inventory System — Architecture

**Version:** 1.0  
**Author:** Bart (Architect)  
**Date:** 2026-07-22  
**Status:** Design  
**Purpose:** Technical specification for first-class inventory in player.lua — nested array structure, container nesting, engine mutations, and verb integration.

---

## Overview

Inventory is a **first-class nested array** in `player.lua`. Objects the player is carrying are stored directly in this array. The engine mutates this array on pickup/drop. There is no external inventory system — the `inventory` array in `player.lua` IS the inventory.

**Core invariant:** The engine interacts with `player.lua` only. Inventory is part of the player's canonical mutable state, alongside injuries, effects, and visited rooms.

---

## Data Structure

```lua
player = {
    inventory = {
        -- Simple items: string IDs
        "brass-key",
        "oil-lantern",

        -- Containers: tables with id + contents (nested)
        {
            id = "leather-bag",
            contents = {
                "bandage",
                "antidote-nightshade",
            },
        },

        -- Containers can nest further
        {
            id = "backpack",
            contents = {
                "rope",
                {
                    id = "pouch",
                    contents = { "gold-coin", "silver-coin" },
                },
            },
        },
    },
}
```

### Entry Types

| Type | Format | Example |
|---|---|---|
| **Simple item** | `string` (object ID) | `"brass-key"` |
| **Container** | `table` with `id` and `contents` | `{ id = "leather-bag", contents = { ... } }` |

### Nesting Rules

- Containers have a `contents` array that can hold simple items or other containers.
- Nesting depth is theoretically unlimited but practically constrained by container definitions (a coin purse doesn't hold a sword).
- Container capacity and allowed categories are defined in the container object's `.lua` metadata (see containment system in [Object Core Principles](../objects/core-principles.md)).

---

## Engine Mutations

The engine mutates `player.inventory` directly. All inventory changes go through the engine — there is no intermediary system.

### Pickup (add to inventory)

When the player picks up an object from a room:

```lua
function engine.pickup(player, object_id, room)
    -- 1. Validate object exists in room
    local obj = room_find_object(room, object_id)
    if not obj then
        print("You don't see that here.")
        return false
    end

    -- 2. Validate player can carry it (weight, capacity, hands)
    if not can_carry(player, obj) then
        print("You can't carry that.")
        return false
    end

    -- 3. Remove from room
    room_remove_object(room, object_id)

    -- 4. Add to player inventory
    if obj.contents then
        -- Container: add as table with contents
        player.inventory[#player.inventory + 1] = {
            id = obj.id,
            contents = obj.contents or {},
        }
    else
        -- Simple item: add as string ID
        player.inventory[#player.inventory + 1] = obj.id
    end

    return true
end
```

### Drop (remove from inventory)

When the player drops an object:

```lua
function engine.drop(player, object_id, room)
    -- 1. Find in inventory (may be at top level or inside a container)
    local item, parent, index = inventory_find(player.inventory, object_id)
    if not item then
        print("You're not carrying that.")
        return false
    end

    -- 2. Remove from inventory array
    table.remove(parent, index)

    -- 3. Place in room
    room_add_object(room, object_id)

    return true
end
```

### Put In (move item into container)

```lua
function engine.put_in(player, item_id, container_id)
    -- 1. Find both in inventory
    local item, item_parent, item_index = inventory_find(player.inventory, item_id)
    local container = inventory_find_container(player.inventory, container_id)

    if not item then
        print("You're not carrying that.")
        return false
    end
    if not container then
        print("You don't have that container.")
        return false
    end

    -- 2. Validate container can hold this item
    local container_def = load_object_definition(container_id)
    if not container_allows(container_def, item_id) then
        print("That won't fit in there.")
        return false
    end

    -- 3. Move: remove from current location, add to container contents
    table.remove(item_parent, item_index)
    container.contents[#container.contents + 1] = item

    return true
end
```

### Take Out (remove item from container)

```lua
function engine.take_out(player, item_id, container_id)
    local container = inventory_find_container(player.inventory, container_id)
    if not container then
        print("You don't have that container.")
        return false
    end

    -- Find item inside container
    local item, parent, index = inventory_find(container.contents, item_id)
    if not item then
        print("That's not in there.")
        return false
    end

    -- Move to top-level inventory
    table.remove(parent, index)
    player.inventory[#player.inventory + 1] = item

    return true
end
```

---

## Object Resolution Order

When resolving a player's reference to an object (e.g., "take candle" or "light candle"), the engine searches through available locations in a verb-dependent order. This ensures the player's intent is respected: "light candle" targets a held candle first (the one you're acting on), while "take candle" targets a candle in the room (the one you're reaching for).

### Interaction Verbs (Acting On Held Objects)

**Verbs:** use, light, drink, open, close, pour, eat

**Search order:** Hands → Bags → Room → Surfaces

These verbs assume the player is acting on something they control. Search the player's hands first, then containers they're carrying, then fall back to the room if necessary.

**Example:** Player is holding a candle and another candle sits on the table.
- Command: "light candle"
- Resolution: Finds the held candle first → lights that one
- Player intent: "Act on what I'm holding"

### Acquisition Verbs (Reaching For Objects)

**Verbs:** take, examine, look, search, feel

**Search order:** Room → Surfaces → Containers → Hands → Bags

These verbs assume the player is reaching for or examining something in their world. Search the room and surfaces first, then containers, then only fall back to what they're already carrying.

**Example:** Player is holding a candle and another candle sits on the table.
- Command: "take candle"
- Resolution: Finds the candle on the table first → picks up that one
- Player intent: "Reach for something in the world"

### Rationale

The verb category determines search priority because:
- **Interaction verbs** target objects the player controls → prioritize the player's body (hands, bags)
- **Acquisition verbs** target objects in the world → prioritize the environment (room, surfaces)

This design prevents ambiguity. If a player holds a key and there's a key on the floor, "use key" and "take key" resolve to different keys based on the player's likely intent.

---

## Inventory Traversal

Because inventory is nested, finding an item requires recursive search:

```lua
function inventory_find(inventory, target_id)
    for i, entry in ipairs(inventory) do
        if type(entry) == "string" and entry == target_id then
            return entry, inventory, i
        elseif type(entry) == "table" and entry.id == target_id then
            return entry, inventory, i
        elseif type(entry) == "table" and entry.contents then
            -- Recurse into container
            local found, parent, index = inventory_find(entry.contents, target_id)
            if found then return found, parent, index end
        end
    end
    return nil
end
```

### Finding containers specifically

```lua
function inventory_find_container(inventory, container_id)
    for _, entry in ipairs(inventory) do
        if type(entry) == "table" and entry.id == container_id and entry.contents then
            return entry
        elseif type(entry) == "table" and entry.contents then
            local found = inventory_find_container(entry.contents, container_id)
            if found then return found end
        end
    end
    return nil
end
```

---

## The `inventory` Verb

The `inventory` verb reads directly from `player.inventory` and renders a human-readable list:

```lua
function verb_inventory(player)
    if #player.inventory == 0 then
        print("You are carrying nothing.")
        return
    end

    print("You are carrying:")
    render_inventory(player.inventory, 1)
end

function render_inventory(items, depth)
    local indent = string.rep("  ", depth)
    for _, entry in ipairs(items) do
        if type(entry) == "string" then
            local obj_def = load_object_definition(entry)
            print(indent .. "- " .. obj_def.name)
        elseif type(entry) == "table" then
            local obj_def = load_object_definition(entry.id)
            print(indent .. "- " .. obj_def.name)
            if entry.contents and #entry.contents > 0 then
                print(indent .. "  (containing:)")
                render_inventory(entry.contents, depth + 1)
            end
        end
    end
end
```

**Example output:**

```
You are carrying:
  - a brass key
  - an oil lantern
  - a leather bag
    (containing:)
      - a clean linen bandage
      - a vial of nightshade antidote
```

---

## Integration with Other Systems

### Healing (Inventory → Injury System)

Healing items are carried in inventory. When a healing verb fires, the engine:

1. Finds the healing object in `player.inventory` (via `inventory_find`).
2. Reads the object's `.lua` metadata for `cures` field.
3. Calls `injury_system.try_heal()` with the object.
4. If consumable, removes the item from inventory.

```lua
-- Example: player uses "antidote-nightshade" from inventory
local item, parent, index = inventory_find(player.inventory, "antidote-nightshade")
if item then
    local obj_def = load_object_definition("antidote-nightshade")
    local healed = injury_system.try_heal(player, obj_def, "drink")
    if healed and obj_def.on_drink.consumable then
        table.remove(parent, index)  -- Remove consumed item
    end
end
```

### Verb System (Inventory → Object Interaction)

Many verbs target objects the player is carrying. The verb system resolves targets from inventory:

```lua
-- Verb resolution: check inventory for target object
function resolve_target(player, room, object_id)
    -- Check inventory first
    local item = inventory_find(player.inventory, object_id)
    if item then return item, "inventory" end

    -- Then check room
    local obj = room_find_object(room, object_id)
    if obj then return obj, "room" end

    return nil, nil
end
```

### Room Objects ↔ Inventory

Objects exist in one place at a time:
- In a room's object list, OR
- In `player.inventory`

Pickup moves from room → inventory. Drop moves from inventory → room. The engine maintains this invariant.

### Cloud Persistence

`player.inventory` is persisted with the rest of `player.lua` each turn. On load, inventory is restored exactly as it was — including nested container structures.

---

## Design Decisions

| ID | Decision | Rationale |
|---|---|---|
| D-INV001 | Inventory is a first-class array in player.lua | Single source of truth. Engine mutates one file. No external inventory system. |
| D-INV002 | Containers are nested tables with `contents` | Natural representation of "bag contains items." Recursive traversal is simple. |
| D-INV003 | Simple items are string IDs, containers are tables | Minimal representation. Strings are lightweight; tables only needed for nesting. |
| D-INV004 | Engine mutates inventory directly | No intermediary system. Pickup/drop are array insert/remove operations on player.lua. |
| D-INV005 | `inventory` verb reads from player.inventory | No external lookup. The array IS the canonical state. |
| D-INV006 | Consumable items removed on use | Healing items, food, single-use objects are removed from the array after use. |

---

## Related

- [README.md](README.md) — Player system overview, canonical player.lua structure
- [health.md](health.md) — Derived health (healing objects are inventory items)
- [injuries.md](injuries.md) — Injury-specific healing (requires matching item from inventory)
- [player-model.md](player-model.md) — Hands, worn items, skills (complementary to inventory)
- [Object Core Principles](../objects/core-principles.md) — Containment rules, object metadata
