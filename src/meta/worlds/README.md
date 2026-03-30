# src/meta/worlds/ — World Definitions

Each subfolder is a self-contained world with its own objects, rooms, creatures, levels, and injuries.

## Creating a New World

1. Create a subfolder: `src/meta/worlds/{world-id}/`
2. Add a `world.lua` definition (see template below).
3. Add content subdirectories: `objects/`, `rooms/`, `creatures/`, `levels/`, `injuries/`.
4. The engine discovers worlds by scanning for `{world-id}/world.lua` files.

## World Definition Template

```lua
return {
    guid = "{generate-new-guid}",
    template = "world",
    id = "{world-id}",
    name = "Display Name",
    rating = "E",  -- E (Everyone) or M (Mature)
    content_root = "worlds/{world-id}",
    start_level = "level-01",
    description = "One-paragraph world description.",
    starting_room = "start-room",
    levels = { 1 },
    theme = {
        pitch = "...",
        era = "...",
        aesthetic = { materials = {}, forbidden = {} },
        atmosphere = "...",
        mood = "...",
        tone = "...",
        constraints = {},
        design_notes = "",
    },
    mutations = {},
}
```

## Existing Worlds

| ID | Name | Rating | Status |
|----|------|--------|--------|
| `manor` | The Manor | M | Playable (Level 1) |

## Rules

- World content MUST NOT reference objects/rooms from other worlds.
- Templates (`src/meta/templates/`) and materials (`src/meta/materials/`) are shared.
- Each world's `content_root` tells the engine where to find its files.
