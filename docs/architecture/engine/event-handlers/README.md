# Engine Event Handlers

**Engine Event Handlers** (also called "Engine Hooks") are **a core architecture principle** alongside FSM, the parser pipeline, and JIT delivery. They are extensible code hooks that fire in response to game events. They are **NOT state machines** — those handle data-driven state transitions on objects. Instead, event handlers are **pre-built mechanics that metadata authors wire into their data files** without writing engine code.

**Architecture Status:** Layer 3.5 in the engine (between Verb Dispatch and Object System). See [Architecture Overview](../00-architecture-overview.md#layer-35-engine-hooks-event-driven-extensibility) for how hooks fit into the overall design.

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

For a deep technical dive into how handlers integrate with the event system, see [Bart's event architecture doc](./about.md).

All future game mechanics that fire on events should be implemented as engine hooks. This is a **design principle**, not a suggestion. Hooks keep the engine simple and the content system powerful.

---

**Metadata Authors:** Read the individual handler docs to learn what's available. **Puzzle designers:** See the [Puzzle Designer Guide](./puzzle-designer-guide.md).
