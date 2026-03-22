# Template Reference Catalog

Templates are **base patterns** that objects inherit from. They define default properties, surfaces, and FSM states. All objects are instances of one or more templates.

## Quick Reference

| Template | Purpose | Key Features |
|----------|---------|--------------|
| **[Container](./container.md)** | Bags, boxes, chests | Portable storage; multiple surfaces (inside, top, under) |
| **[Furniture](./furniture.md)** | Desks, beds, wardrobes | Heavy, stationary; customizable surfaces |
| **[Room](./room.md)** | World locations | Exits, contents, no physical properties |
| **[Sheet](./sheet.md)** | Fabric, cloth, paper | Lightweight; can tear into cloth scraps |
| **[Small Item](./small-item.md)** | Keys, coins, shards | Tiny, portable; minimal weight |

## Template Hierarchy

All templates are **flat** — objects inherit from ONE template, then override properties as needed. There is no multi-level inheritance.

```
Object Instance
├─ Inherits from: Template (container, furniture, room, sheet, small-item)
├─ Overrides: name, description, keywords, custom properties
└─ Adds: instance-specific behaviors via mutations
```

## Common Patterns

### Properties Every Template Defines

- **id** — Template identifier (canonical name)
- **guid** — Unique identifier for this template (used for instance tracking)
- **name** — Default display name
- **keywords** — Search/alias list
- **description** — What players see on LOOK
- **size** — Dimensional category (0-5 scale, higher = larger)
- **weight** — Mass in arbitrary units
- **portable** — Can be picked up and dropped
- **material** — Composition (wood, fabric, generic, etc.)
- **categories** — Tags for grouping (container, furniture, fabric, etc.)

### Surfaces (Containers & Furniture Only)

Surfaces define where items can be placed **on** or **in** an object:

- **inside** — Interior cavity (drawers, bags, boxes)
- **top** — Upper surface (tables, desks, counters)
- **under** — Underside (beneath tables, under beds)
- **left/right** — Sides (walls, bookcases)
- **front** — Facing area

### Mutations (Optional)

Objects can transform via mutations. The `mutations` table defines state transitions:

```lua
mutations = {
  tear = { becomes = nil, spawns = {"cloth"} },
  -- Object is destroyed; cloth scraps appear
}
```

## Design Philosophy

**Templates are intentionally minimal.** They provide:
- Physical properties (size, weight, portability)
- Container mechanics (if applicable)
- Surfaces for placement
- Mutation hooks

**Objects are responsible for:**
- Display personality (name, description, keywords)
- Instance-specific behaviors (verbs, FSM states)
- Content initialization

This keeps templates reusable and objects implementation-clear.

## Implementation Notes

- All templates are defined in `src/meta/templates/{name}.lua`
- Each template returns a Lua table with default properties
- Objects override template defaults in their own definitions
- The engine loader ensures all instances inherit the correct template

---

**See Also:** [Architecture Overview](../architecture/00-architecture-overview.md), [Object Reference](../objects/), [Verb System](../design/verb-system.md)
