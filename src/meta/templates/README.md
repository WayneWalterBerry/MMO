# src/meta/templates/ — Shared Base Templates

Templates define the structural shape of objects. They are shared across all worlds.

## Templates

| Template | Description |
|----------|-------------|
| `room.lua` | Room definition (exits, instances, description) |
| `furniture.lua` | Large immovable objects (surfaces, capacity) |
| `container.lua` | Openable containers (chest, barrel, sack) |
| `small-item.lua` | Portable objects (candle, key, knife) |
| `sheet.lua` | Flat flexible objects (cloth, paper, bandage) |
| `creature.lua` | Living entities (rat, wolf, spider) |
| `portal.lua` | Door/passage between rooms (FSM states) |
| `world.lua` | World definition (theme, levels, starting room) |

## How Templates Work

Objects declare `template = "small-item"` and inherit all base properties.
The engine's `loader.resolve_template()` deep-merges the template under the object.
Instance overrides always win — the template provides defaults only.
