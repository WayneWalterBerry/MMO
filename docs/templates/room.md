# Room Template

> Base pattern for world locations: areas, chambers, outdoor spaces.

## Purpose

The Room template provides the **minimum essentials** for a game location. Unlike other templates, Room is intentionally sparse — instance rooms override nearly every property to define their unique identity, exits, contents, and lighting.

**Typical objects:** Bedroom, tavern, forest clearing, throne room, cave, courtyard, dungeon cell

## Default Properties

| Property | Default | Purpose |
|----------|---------|---------|
| `id` | `"room"` | Template identifier |
| `guid` | `"071e1b6a-17ae-498b-b7af-0cbb8948cd0d"` | Unique template ID |
| `name` | `"A room"` | Display name (nearly always overridden) |
| `keywords` | `{}` | Search aliases (overridden per-room) |
| `description` | `""` | Room description (overridden per-room) |
| `contents` | `{}` | Objects in this room (furniture, items, NPCs) |
| `exits` | `{}` | Passages to other rooms |
| `mutations` | `{}` | Optional transformations |

## Room Mechanics

### Contents Table

All objects currently in the room:

```lua
contents = {
  {id = "desk", guid = "..."},
  {id = "bed", guid = "..."},
  {id = "torch", guid = "..."},
  {id = "character", guid = "..."}
}
```

Contents include:
- **Furniture** — Fixed pieces (desks, beds, altars)
- **Portable Items** — Objects players can pick up
- **Characters** — NPCs and other players
- **Decorative Objects** — Scenery items

### Exits Table

Connections to adjacent rooms:

```lua
exits = {
  north = {room = "forest_clearing", door = "heavy_oak_door"},
  south = {room = "tavern"},
  up = {room = "tower_top"}
}
```

Each exit specifies:
- **Direction** — `north`, `south`, `east`, `west`, `up`, `down`, etc.
- **Destination room** — Target room ID
- **Door object** (optional) — If passage is blocked/locked

### Lighting

Rooms may define lighting via instance properties:

```lua
light_level = 2  -- 0 (dark) to 3 (bright)
light_sources = {"chandelier", "torch"}
```

This controls player sensory access (LOOK, LISTEN require light; FEEL, SMELL work in darkness).

## No Physical Properties

Room template intentionally **does not** define:
- `size` — Rooms are abstract containers
- `weight` — Rooms don't move
- `portable` — Rooms are stationary
- `material` — Not relevant to locations
- `container` — Rooms hold things differently

Rooms are **abstract spaces**, not physical objects. Players don't interact with the room itself — they interact with objects *in* the room.

## FSM States

Rooms can support state transitions:
- **Weather/Atmosphere** — Clear, rainy, foggy, stormy
- **Lighting** — Bright, dim, dark, torch-lit
- **Damage/Decay** — Intact, damaged, collapsed
- **Population** — Empty, crowded, hostile

State is tracked per-room, not in the template. The instance room defines its own states.

## Objects Using This Template

All game locations inherit from this template:
- `starting_chamber` — Player spawn room
- `bedroom_small` — Personal quarters
- `tavern` — Social hub
- `forest_clearing` — Outdoor area
- `dungeon_cell` — Captive room
- `throne_room` — Authority chamber
- `tower_top` — High vantage point

Check `src/meta/rooms/` for the complete room inventory.

## Design Notes

### Minimal Template, Rich Instances

The Room template is intentionally lightweight because **every room is unique**. Instance rooms define:
- Atmospheric description
- Specific exits
- Starting furniture and objects
- Lighting and sensory properties
- Special interactions and events

### Player Entry/Exit

When a player enters/leaves a room, the engine:
1. Updates `room.contents` (adds/removes player entry)
2. Updates `player.location` (tracks current room)
3. Sends transition messages to other players in that room
4. Loads related room data (objects, furniture, exits)

### Room Persistence

Rooms are **persistent**:
- Objects placed in a room stay there
- Furniture configurations don't reset
- Changes accumulate across player sessions
- Housekeeping/reset mechanics must be explicit

### Multi-Room Puzzles

Complex puzzles span multiple rooms:
- A key in one room opens a chest in another
- Lighting a torch in one room reveals a path in another
- NPC conversations trigger events across locations

Each room definition includes links to related puzzles and their cross-room dependencies.

## Implementation Reference

- **File:** `src/meta/templates/room.lua`
- **Used by:** Movement and location systems in `src/engine/`
- **Related Architecture:** [Player Movement](../architecture/player/player-movement.md), [Player Sensory](../architecture/player/player-sensory.md)

---

**See Also:** [Furniture Template](./furniture.md), [Container Template](./container.md), [Room Reference](../rooms/), [Puzzle Catalog](../puzzles/)
