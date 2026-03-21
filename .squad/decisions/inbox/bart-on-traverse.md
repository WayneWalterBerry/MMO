# Decision: on_traverse Exit-Effect Pattern

**ID:** D-TRAVERSE001
**Author:** Bart (Architect)
**Date:** 2026-07-22
**Status:** Implemented
**Scope:** Engine — movement system

---

## Context

Puzzle 015 (Draft Extinguish) requires that environmental effects fire when a player moves through an exit. The stairway from the deep cellar creates a draft that extinguishes unprotected candles. This is the first instance of exit-triggered effects, but the pattern needs to be generic for future use (water crossings, narrow passages, hot rooms, etc.).

## Decision

Exits in room metadata support an optional `on_traverse` field containing a typed effect definition. The engine dispatches to registered handlers by `type` string.

### Room metadata format:
```lua
exits = {
  up = {
    target = "storage-cellar",
    on_traverse = {
      type = "wind_effect",
      description = "A cold draft rushes up the stairway...",
      extinguishes = { "candle" },
      message_extinguish = "The draft snuffs out your candle!",
      message_spared = "Your lantern holds steady."
    }
  }
}
```

### Engine architecture:
- **Module:** `src/engine/traverse_effects.lua`
- **API:** `traverse_effects.register(type, handler_fn)` — register new effect types
- **API:** `traverse_effects.process(exit, ctx)` — called by movement handler
- **Integration point:** `handle_movement` in `src/engine/verbs/init.lua`, fires BEFORE player location changes

### Built-in handler: `wind_effect`
- Checks player inventory for items matching `extinguishes` list (by id or keywords)
- Only affects items in "lit" state
- Respects `wind_resistant` property on objects (lantern survives)
- Uses FSM transition (`extinguished` preferred, `unlit` fallback)

## Rationale

- **Extensible:** Type-dispatch pattern means new effect types (water, heat, narrow passage) can be added by registering a handler — zero changes to movement code.
- **Data-driven:** Room authors declare effects in metadata; no Lua code needed per-room.
- **Before-move timing:** Effects fire before the player moves so messages print in narrative order and the origin room's context is available.
- **Object-owns-properties:** Wind resistance lives on the object (`wind_resistant = true`), not in the exit metadata. The exit declares the environmental condition; objects declare their resilience.

## Alternatives Considered

1. **Room on_enter callback** — Would fire AFTER movement, wrong narrative timing. Also requires code in room files.
2. **Special-case in go verb** — Would work but not extensible. Every new effect type would require modifying the movement handler.
3. **Event system** — Too heavy for this use case. on_traverse is a focused pattern for exit-triggered effects.

## Files Changed

- `src/engine/traverse_effects.lua` — NEW: effect dispatcher + wind_effect handler
- `src/engine/verbs/init.lua` — MODIFIED: require + process call in handle_movement
- `test/parser/test-on-traverse.lua` — NEW: 12 tests covering all cases
