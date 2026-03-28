# Narration Pipeline

> Architecture document for the unified text output pipeline.
> **Owner:** Smithers (UI Engineer) + Bart (Engine Architect)
> **Status:** Interface design (WAVE-0). Implementation deferred to WAVE-3+.

## Problem

Phase 4 introduces multiple subsystems that produce player-facing text: butchery narration, loot drop messages, stress effects, creature ambient behavior, spider web creation, and combat results. Today, each subsystem calls `ctx.print()` or `print()` directly with no unified formatting, filtering, or presentation control.

This creates problems:
1. **Message flooding** — killing a wolf could produce 8+ lines (death, stress, loot drops, butchery, etc.)
2. **Inconsistent tone** — each verb handler formats differently
3. **No batching** — related messages aren't grouped
4. **No filtering** — player can't control verbosity
5. **No testability** — text output mixed with game logic

## Solution: `ctx.narrate()`

A single narration entry point that all subsystems use instead of `ctx.print()`. The narration pipeline receives structured messages, batches them, applies formatting, and emits them through the display layer.

## Interface Contract

### `ctx.narrate(source, type, message, opts)`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | string | yes | Subsystem origin. See Source Registry below. |
| `type` | string | yes | Message category. See Type Registry below. |
| `message` | string | yes | The player-facing text. |
| `opts` | table | no | Optional metadata (see Options below). |

### Source Registry

| Source | Subsystem | Example |
|--------|-----------|---------|
| `"combat"` | Combat resolution engine | `"The wolf snarls and lunges."` |
| `"butchery"` | Butchery verb handler | `"You begin carving the wolf carcass..."` |
| `"creature"` | Creature behavior/ambient | `"The spider spins a web in the corner."` |
| `"stress"` | Stress injury system | `"Your hands are shaking."` |
| `"loot"` | Loot table drops | `"Something tumbles from the wolf's body."` |
| `"crafting"` | Craft verb handler | `"You twist the silk into a rope."` |
| `"injury"` | Injury subsystem | `"Blood seeps from the wound."` |
| `"environment"` | Room/ambient events | `"A cold draft sweeps through the cellar."` |
| `"parser"` | Parser feedback/errors | `"I don't understand that."` |
| `"system"` | Engine/meta messages | `"Game saved."` |

New sources can be registered at runtime. Unknown sources are logged as warnings and passed through.

### Type Registry

| Type | Meaning | Display Behavior |
|------|---------|-----------------|
| `"action"` | Player's action narrated | Normal weight. Always shown. |
| `"result"` | Outcome of an action | Normal weight. Always shown. |
| `"ambient"` | Background flavor text | Can be suppressed in terse mode. |
| `"injury"` | Injury infliction/status | Normal weight. Color: red. |
| `"status"` | Status change notification | Can be batched with other status messages. |
| `"error"` | Parser/validation error | Normal weight. Distinct formatting. |
| `"prompt"` | Disambiguation prompt | Requires player response. |
| `"internal"` | Debug/trace output | Only shown with `--debug` flag. |

### Options Table

```lua
opts = {
    delay = 0,          -- ticks to delay before display (0 = immediate)
    priority = 5,       -- 1-10, higher = shown first in batch (default 5)
    batch_key = nil,    -- string key to group related messages
    color = nil,        -- override default type color ("red", "yellow", etc.)
    suppress_if = nil,  -- function(ctx) returning bool; if true, message is dropped
}
```

## Pipeline Stages

```
  Subsystem                 Narration Pipeline                    Display
  ─────────    ─────────────────────────────────────────    ──────────────
                                                           
  combat ─┐    ┌─────────┐   ┌─────────┐   ┌──────────┐   ┌────────────┐
  stress ─┤    │         │   │         │   │          │   │            │
  loot   ─┼──→ │ Collect  │──→│  Batch   │──→│  Format  │──→│  Display   │
  craft  ─┤    │         │   │         │   │          │   │            │
  injury ─┘    └─────────┘   └─────────┘   └──────────┘   └────────────┘
                                                           
               Stage 1:       Stage 2:       Stage 3:       Stage 4:
               Validate       Group by       Apply type     Word-wrap +
               source/type,   batch_key,     formatting,    emit via
               apply          sort by        color codes,   display.lua
               suppress_if    priority       terse filter   
```

### Stage 1: Collect

- Validate `source` is registered (warn if unknown, pass through)
- Validate `type` is recognized (reject if unknown)
- Evaluate `suppress_if` — drop message if returns true
- Append to frame buffer

### Stage 2: Batch

- Group messages by `batch_key` (nil = ungrouped)
- Sort within groups by `priority` (descending)
- Apply delay: deferred messages held for N ticks

### Stage 3: Format

- Apply type-specific formatting:
  - `"injury"` → red text (if terminal supports color)
  - `"error"` → distinct prefix or formatting
  - `"ambient"` → suppressed if terse mode active
  - `"internal"` → suppressed unless `--debug` flag
- Apply `opts.color` override if present

### Stage 4: Display

- Pass formatted text to `display.lua` for word-wrapping
- Emit to terminal (or web UI via Fengari bridge)
- In `--headless` mode, emit raw text with `---END---` delimiters

## Usage Examples

### Butchery (WAVE-1)

```lua
-- In butcher verb handler
ctx.narrate("butchery", "action", butch.narration.start)

for _, prod in ipairs(butch.products) do
    -- instantiate products...
end

ctx.narrate("butchery", "result", butch.narration.complete, {
    batch_key = "butchery-" .. target.guid,
})
```

### Stress Infliction (WAVE-3)

```lua
-- In trauma hook
ctx.narrate("stress", "status", "Your hands are shaking.", {
    priority = 3,
    suppress_if = function(ctx)
        return ctx.player.stress_level < 3  -- don't narrate below threshold
    end,
})
```

### Creature Ambient (WAVE-4)

```lua
-- In creature tick
ctx.narrate("creature", "ambient", "The spider spins a web in the corner.", {
    priority = 2,
    delay = 1,  -- show after player action resolves
})
```

### Combat Result (existing, adapted)

```lua
-- In combat resolution
ctx.narrate("combat", "result", "The wolf yelps and retreats.", {
    priority = 8,
    color = "yellow",
})
```

### Disambiguation Prompt

```lua
-- In parser
ctx.narrate("parser", "prompt", "Which bandage? The linen bandage or the silk bandage?", {
    priority = 10,  -- always shown first
})
```

## Module Interface

```lua
-- src/engine/narration/init.lua
local M = {}

-- Initialize narration pipeline
function M.init(display, config)
    -- display: reference to display.lua module
    -- config: { terse = false, debug = false, headless = false }
end

-- Primary entry point
function M.narrate(source, type, message, opts)
    -- Validate, collect, queue for emission
end

-- Flush queued messages (called once per game loop tick)
function M.flush()
    -- Batch → Format → Display
end

-- Register a new source at runtime
function M.register_source(name)
end

-- Set verbosity mode
function M.set_terse(enabled)
end

-- Get narration log (for testing)
function M.get_log()
    -- Returns array of {source, type, message, timestamp}
end

-- Clear narration log
function M.clear_log()
end

return M
```

## Integration with Game Loop

```lua
-- In src/engine/loop/init.lua (sketch)
local narration = require("engine.narration")

function game_loop_tick(ctx)
    -- 1. Read player input
    -- 2. Parse & dispatch verb
    -- 3. Creature ticks (may call ctx.narrate)
    -- 4. Injury ticks (may call ctx.narrate)
    -- 5. FSM ticks (may call ctx.narrate)
    
    -- 6. Flush all queued narration for this tick
    narration.flush()
end
```

## Context Object Extension

The `ctx` table gains a `narrate` method:

```lua
-- In context construction (loop/init.lua or wherever ctx is built)
ctx.narrate = function(source, type, message, opts)
    narration.narrate(source, type, message, opts)
end
```

This keeps the existing `ctx.print()` working for backward compatibility. Subsystems migrate to `ctx.narrate()` incrementally — no big-bang rewrite required.

## Migration Strategy

1. **WAVE-0** (now): Interface design documented (this file)
2. **WAVE-1**: `ctx.narrate()` stub created — passes through to `ctx.print()`. Butchery uses it.
3. **WAVE-3**: Stress narration uses full pipeline (batching, suppress_if). Flush integrated into game loop.
4. **WAVE-4**: Creature ambient narration uses delay and priority. Terse mode available.
5. **Post-Phase 4**: Full pipeline with color, headless support, web UI bridge.

## Testing

```lua
-- test/narration/test-narration-pipeline.lua
local narration = require("engine.narration")

-- Test: messages are collected
narration.narrate("combat", "result", "The wolf falls.")
local log = narration.get_log()
assert(#log == 1)
assert(log[1].source == "combat")

-- Test: suppress_if works
narration.narrate("stress", "ambient", "Quiet dread.", {
    suppress_if = function() return true end,
})
local log2 = narration.get_log()
assert(#log2 == 1)  -- suppressed message not added

-- Test: batch ordering by priority
narration.clear_log()
narration.narrate("loot", "result", "A bone falls.", { priority = 3 })
narration.narrate("combat", "result", "The wolf dies.", { priority = 8 })
narration.flush()
-- combat message should appear first (higher priority)
```

## Open Questions (for Bart review)

1. **Flush timing:** Should `flush()` happen once per tick, or after each verb handler returns? Once-per-tick batches better but delays feedback.
2. **ctx.print() deprecation:** When do we stop supporting `ctx.print()` and require `ctx.narrate()`? Suggest: never fully deprecate — `ctx.print()` becomes a thin wrapper around `ctx.narrate("system", "action", msg)`.
3. **Web UI bridge:** Does Fengari need a different emit path, or can we just swap `display.lua`?

**Signed:** Smithers (UI Engineer), WAVE-0 Pre-Flight
**Pending:** Bart (Engine Architect) review and co-sign
