# Furniture Template

> Base pattern for heavy, stationary objects: desks, beds, wardrobes, bookcases, etc.

## Purpose

The Furniture template provides **immobile storage and interaction points**. Objects that inherit from this template are environment pieces — they don't move, but players interact with them in place. They may support surfaces for placing items and can be customized with state-specific behaviors.

**Typical objects:** Desk, nightstand, bed, wardrobe, bookcase, table, chest of drawers, throne, altar

## Default Properties

| Property | Default | Purpose |
|----------|---------|---------|
| `id` | `"furniture"` | Template identifier |
| `guid` | `"45a12525-ae7c-4ff1-ba22-4719e9144621"` | Unique template ID |
| `name` | `"a piece of furniture"` | Display name (overridden by instances) |
| `size` | `5` | Large object (takes up space) |
| `weight` | `30` | Heavy (requires multiple people or tools) |
| `portable` | `false` | **Cannot be picked up or moved** |
| `material` | `"wood"` | Default material |
| `container` | `false` | Not a container (but may have surfaces) |
| `capacity` | `0` | No containment slots |
| `contents` | `{}` | May store surface items (empty table) |
| `location` | `nil` | Which room this furniture is in |
| `categories` | `{"furniture", "wooden"}` | For grouping and queries |
| `mutations` | `{}` | Optional transformations |

## Furniture Mechanics

### Surfaces

Furniture supports **named surfaces** where players place items:
- **top** — Desk surface, table, shelf
- **inside** — Drawers, wardrobes, cabinets
- **under** — Underside, beneath furniture
- **left/right** — Sides, bookcases
- **front** — Facing area

Each surface is a named slot in the `contents` table:

```lua
contents = {
  top = {
    {id = "book", guid = "..."},
    {id = "quill", guid = "..."}
  },
  inside = {
    {id = "letter", guid = "..."}
  }
}
```

### Immobility

`portable = false` means:
- Players **cannot** pick up furniture
- Furniture **stays in place** when the room is saved/loaded
- Furniture persists across player sessions

If an object needs to move, use the **Container** template instead.

## FSM States

Furniture may support state-specific descriptions and interactions:
- **Open/Closed** — Drawer, wardrobe, cabinet states
- **Locked/Unlocked** — Secured furniture
- **Damaged/Intact** — Worn, broken, or repaired states
- **Decorated/Plain** — Aesthetic states

State is typically tracked via `_state` object or `on_look` override, not in the template itself.

## Objects Using This Template

Common instances include:
- `desk` — Writing surface, open/closeable drawers
- `bed` — Sleeping furniture
- `wardrobe` — Clothing storage, openable doors
- `nightstand` — Bedside table, drawer storage
- `bookcase` — Shelf storage
- `throne` — Ceremonial seat
- `altar` — Religious/decorative piece

Check `src/meta/objects/` for the complete inventory.

## Design Notes

### Why Heavy by Default?

Furniture defaults to `weight = 30` because **moving real furniture requires effort**. This reflects gameplay:
- Furniture stays in place
- Players discover and interact with it in context
- Weight can be overridden for lighter pieces (lightweight stools = weight 5)

### Surface Interaction Verbs

Furniture surfaces are accessed via verbs:
- `PUT object ON furniture` — Places item on a surface
- `PUT object IN furniture` — Places item inside (drawer, cabinet)
- `GET object FROM furniture` — Removes item from surface

The instance object must define these verb handlers.

### Room Furniture

Each room contains furniture instances (desks, beds, etc.). The room's `contents` table lists all furniture:

```lua
contents = {
  {id = "desk", guid = "..."},
  {id = "bed", guid = "..."},
  {id = "wardrobe", guid = "..."}
}
```

### Mutations

Furniture can support mutations (e.g., `burn` → `ashes`). These are defined per-instance.

## Implementation Reference

- **File:** `src/meta/templates/furniture.lua`
- **Used by:** Room and containment systems
- **Related Verbs:** `PUT`, `GET`, `OPEN`, `CLOSE`, `EXAMINE`

---

**See Also:** [Container Template](./container.md), [Room Template](./room.md), [Verb System](../design/verb-system.md)
