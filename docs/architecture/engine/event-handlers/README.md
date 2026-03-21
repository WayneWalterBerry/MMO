# Engine Event Handlers

Engine Event Handlers are extensible code hooks that fire in response to game events. They are **NOT state machines** — those handle data-driven state transitions on objects. Instead, event handlers are **pre-built mechanics that metadata authors wire into their data files** without writing engine code.

See [Puzzle Designer Guide](./puzzle-designer-guide.md) for how to use these mechanics in your puzzles.

## Currently Implemented

### Environmental Mechanics
- [wind_effect](./wind_effect.md) — A draft/wind that extinguishes carried lit items (Puzzle 015)

## Planned / Proposed Handlers

*(Bart is designing the priority list for next handlers. Watch this space.)*

- `trigger_sound` — Play a sound effect when an event occurs
- `spawn_object` — Materialize an object in a room or inventory
- `apply_status` — Add a temporary status/buff to the player
- `damage_item` — Reduce durability/integrity of carried items
- `unlock_exit` — Toggle an exit's locked property

## How It Works: The Handler Pattern

Handlers are registered once in engine startup:

```lua
register("wind_effect", wind_effect_handler)
register("trigger_sound", sound_handler)
-- etc.
```

Then room/object metadata invokes them by name:

```lua
on_traverse = {
  type = "wind_effect",
  description = "...",
  extinguishes = { ... }
}
```

The engine looks up the handler by type, validates the parameters, and runs it. **No engine code needs to change when adding new handlers.**

## Architecture Context

For a deep technical dive into how handlers integrate with the event system, see Bart's event architecture doc: `docs/architecture/engine/event-handlers.md` (forthcoming).

---

**Metadata Authors:** Read the individual handler docs to learn what's available. **Puzzle designers:** See the [Puzzle Designer Guide](./puzzle-designer-guide.md).
