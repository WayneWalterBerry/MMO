# Container Template

> Base pattern for portable storage objects: bags, boxes, chests, barrels, etc.

## Purpose

The Container template provides **portable storage** with volume and weight limits. Objects that inherit from this template become interactive storage spaces — players can place items inside them, carry them, and move them between rooms.

**Typical objects:** Backpack, satchel, lockbox, barrel, crate, treasure chest, leather bag

## Default Properties

| Property | Default | Purpose |
|----------|---------|---------|
| `id` | `"container"` | Template identifier |
| `guid` | `"f1596a51-4e1f-4f9a-a6d0-93b279066910"` | Unique template ID |
| `name` | `"a container"` | Display name (overridden by instances) |
| `size` | `2` | Medium-sized object |
| `weight` | `0.5` | Base weight (empty) |
| `weight_capacity` | `10` | Max weight items can add |
| `portable` | `true` | Can be picked up and carried |
| `material` | `"generic"` | Default composition |
| `container` | `true` | This is a container |
| `capacity` | `4` | Max number of item slots |
| `contents` | `{}` | Current items inside (empty table) |
| `location` | `nil` | Where the container is placed (room ID) |
| `categories` | `{"container"}` | For grouping and queries |
| `mutations` | `{}` | Optional transformations |

## Container Mechanics

### Capacity

- **Volume Limit:** `capacity` — Maximum number of item slots (default: 4)
- **Weight Limit:** `weight_capacity` — Maximum weight of contents (default: 10 units)

When a player tries to place an item:
1. Check if `#contents < capacity` (number of slots available)
2. Check if `current_weight + item.weight < weight_capacity`
3. If both pass, add item to `contents` table
4. If either fails, display rejection message: "There is not enough room {location}."

### Contents Table

```lua
contents = {
  {id = "coin", guid = "..."},
  {id = "key", guid = "..."},
  {id = "ring", guid = "..."}
}
```

## Surfaces

The Container template does **not** define surfaces. Instance containers may add surfaces via verb handlers (e.g., placing items "on" a box after opening it), but the default template only provides containment.

To support "on" placement, instances should define custom surfaces in their verb handlers.

## FSM States

The Container template does **not** define FSM states. State management is handled by instance objects:
- **Open/Closed** — Controlled by `OPEN` and `CLOSE` verbs
- **Locked/Unlocked** — Controlled by `LOCK` and `UNLOCK` verbs
- **Hidden** — Items can be concealed via describe override

## Objects Using This Template

Common instances include:
- `satchel` — Leather bag, 4-slot container
- `backpack` — Adventurer's pack, 6-slot container
- `chest` — Wooden storage chest, 8-slot container
- `barrel` — Wooden barrel, 12-slot container
- `lockbox` — Secure box with lock, 4-slot container

Check `src/meta/objects/` for the complete inventory.

## Design Notes

### Why Portable by Default?

Containers are portable because **players carry them**. This reflects the gameplay loop:
- Pick up container → Add items to it → Carry to destination
- Drop container → Other players access contents

If an object should be immobile (like a built-in shelf), use the **Furniture** template instead.

### Containment Rejection

When placement fails, the engine provides a specific message:
```
"There is not enough room in the {name}."  (when full by count)
"There is not enough room in the {name}."  (when full by weight)
```

The container's own `name` is interpolated, so messages read naturally: "There is not enough room in the satchel."

### Mutations

Containers can support mutations (e.g., `break` → `splinters`). Define these in the instance object, not in the template.

## Implementation Reference

- **File:** `src/meta/templates/container.lua`
- **Used by:** Containment system in `src/engine/containment/`
- **Related Verb:** `PUT` (places items), `GET` (removes items), `OPEN`/`CLOSE`

---

**See Also:** [Furniture Template](./furniture.md), [Verb System](../design/verb-system.md), [Containment Architecture](../architecture/objects/core-principles.md)
