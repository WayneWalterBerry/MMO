# UI Architecture Overview

**Version:** 1.0  
**Author:** Smithers (UI Engineer)  
**Last Updated:** 2026-03-22  
**Purpose:** Complete specification of the user interface layer, text presentation, and parser pipeline.

---

## Overview

The MMO UI layer handles all player interaction: input capture, command parsing, text formatting, sensory output, and feedback presentation. It is the translation layer between natural language player commands and engine-level verb dispatch.

**Key Components:**
1. **REPL Loop** — Read-Eval-Print Loop for command input/output
2. **Parser Pipeline** — 5-tier system for interpreting player commands
3. **Display System** — Text formatting, word-wrapping, sensory presentation
4. **Terminal UI** — Split-screen interface (optional) with status bar
5. **Feedback Layer** — Success/failure messages, error reporting, disambiguation

---

## Core Principles

The UI layer is governed by these design principles from the 8 Core Principles (see `docs/architecture/objects/core-principles.md`):

- **Principle 6: Objects Exist in Sensory Space** — State determines perception. Dark room ≠ lit room.
- **Principle 8: The Engine Executes Metadata; Objects Declare Behavior** — UI layer interprets object metadata (sensory descriptions, on_look callbacks) without hard-coding object-specific display logic.

**UI-Specific Principles:**
1. **Natural Language First** — Players type commands in plain English, not code
2. **Zero-Token Path** — Most commands (90%+) resolved without LLM calls (Tier 1-3)
3. **Graceful Degradation** — Parser tiers cascade: fast exact match → phrase similarity → GOAP planning
4. **Sensory-Aware** — All output adapts to light/dark, player vision state, worn items
5. **Diagnostic Transparency** — Failed commands show what the parser tried (in debug mode)

---

## Architecture: The Three Layers

```
┌──────────────────────────────────────────────────────────┐
│  LAYER 1: INPUT CAPTURE & PREPROCESSING                  │
│  - Read player command from terminal/UI                   │
│  - Natural language preprocessing (strip punctuation,     │
│    expand common phrases, normalize case)                 │
└──────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────┐
│  LAYER 2: PARSER PIPELINE (Tier 1-5)                     │
│  - Tier 1: Exact verb dispatch (70% coverage)            │
│  - Tier 2: Embedding phrase similarity (20% coverage)     │
│  - Tier 3: GOAP backward-chaining (8% coverage)          │
│  - Tier 4: Context-aware inference (1% coverage)          │
│  - Tier 5: SLM fallback (optional, future)               │
└──────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────┐
│  LAYER 3: OUTPUT FORMATTING & FEEDBACK                   │
│  - Room descriptions (dynamic composition)                │
│  - Object descriptions (state-aware, sensory)             │
│  - Action feedback (success/failure messages)             │
│  - Error messages (helpful, constraint-explaining)        │
│  - Word-wrapping (78-char terminal width)                 │
└──────────────────────────────────────────────────────────┘
```

---

## File Structure

```
src/
  main.lua                   — Entry point, wires everything together
  engine/
    loop/
      init.lua               — REPL loop: read input → parse → dispatch → tick
    parser/
      init.lua               — Parser wrapper: Tier 2 embedding matcher
      embedding_matcher.lua  — Token-based similarity matching (Tier 2)
      goal_planner.lua       — GOAP backward-chaining (Tier 3)
      json.lua               — JSON parser for embedding index
    verbs/
      init.lua               — Verb handlers (31 verbs)
    display.lua              — Word-wrapping, print() override
    ui.lua                   — (Not found — terminal UI may be external or TBD)
docs/
  architecture/
    ui/                      — THIS DIRECTORY
      README.md              — This file
      text-presentation.md   — Output formatting, sensory descriptions
      parser-overview.md     — Parser pipeline architecture
    engine/
      parser-tier-1-basic.md       — Exact verb dispatch
      parser-tier-2-compound.md    — Phrase similarity fallback
      parser-tier-3-goap.md        — Backward-chaining planner
      parser-tier-4-context.md     — Context window (designed)
      parser-tier-5-slm.md         — SLM fallback (designed)
```

---

## The REPL Loop

**Location:** `src/engine/loop/init.lua`

The Read-Eval-Print Loop (REPL) is the heartbeat of the UI:

```lua
while true do
  -- UPDATE: Refresh status bar (level, room, time, matches, candle state)
  if context.ui then context.update_status(context) end
  
  -- READ: Capture player input
  input = read_input()
  
  -- PARSE: Natural language preprocessing
  verb, noun = preprocess_natural_language(input)
  if not verb then verb, noun = parse(input) end
  
  -- DISPATCH: Route to handler
  -- Tier 1: Check verb table for exact match
  if context.verbs[verb] then
    context.verbs[verb](context, noun)
  -- Tier 2: Embedding fallback
  elseif context.parser then
    parser_mod.fallback(context.parser, input, context)
  -- Tier 3: GOAP planning (if goal_planner module present)
  elseif goal_planner then
    plan = goal_planner.plan(verb, noun, context)
    goal_planner.execute(plan, context)
  else
    print("I don't understand that.")
  end
  
  -- TICK: Post-command FSM updates (burn timers, etc.)
  if context.on_tick then context.on_tick(context) end
  
  -- GAME OVER: Check death conditions
  if context.game_over then break end
end
```

**Key Features:**
- **Compound Commands:** "get match and light candle" splits on "and" → multiple commands
- **Question Handling:** "what's inside?" → "look in"
- **Scroll Support:** `/up`, `/down`, `/bottom` (if terminal UI active)
- **Tick System:** Every command = 1 tick (360 game seconds for timers)

---

## The Parser Pipeline

See [parser-overview.md](parser-overview.md) for complete details.

**Quick Summary:**
- **Tier 1:** Hash table lookup (exact verb or alias match) — `<1ms`
- **Tier 2:** Jaccard token similarity (phrase matching) — `~5ms`
- **Tier 3:** GOAP backward-chaining (multi-step goal decomposition) — `~50-100ms`
- **Tier 4:** Context window (recent discoveries inform inference) — *Designed, not built*
- **Tier 5:** SLM fallback (on-device model for novel patterns) — *Designed for Phase 2+*

**Coverage:**
- Tier 1+2 resolve ~90% of typical player input
- Tier 3 adds another ~8% (complex multi-step goals)
- Tier 4+5 target the remaining ~2% (unusual phrasings, novel combinations)

**No Fallback Past Tier 2 (Current):**
- Per D-4 (Cross-Agent Directive), Tier 2 is the current fallback limit
- Tier 3 exists but may not be fully enabled yet
- Failed commands show diagnostic output (parser score, closest match)
- This enables empirical QA: watch what players type, improve phrase dictionary

---

## Text Presentation

See [text-presentation.md](text-presentation.md) for complete details.

**Key Systems:**
- **Dynamic Room Descriptions** — Composed from three sources: room description, object presences, visible exits
- **Sensory Output** — Objects return different descriptions based on light state, player vision
- **Word-Wrapping** — All text wrapped at 78 characters (configurable) to prevent terminal line-splitting
- **Error Messages** — Failures explain *why* (constraint blocking action, not just "command failed")

**Example Output:**

```
> look
A Small Bedroom

Stone walls surround you, bare and cold. A single window admits faint 
starlight. The air smells faintly of tallow and dust.

A four-poster bed dominates the room, its linen sheets rumpled. A small 
nightstand sits beside it. A heavy wardrobe stands against the far wall.

Exits:
  north: A wooden door (locked)
```

---

## Terminal UI (Optional)

**Status:** UI module referenced in `src/main.lua` but `src/engine/ui.lua` not found. This may be:
1. External dependency (not in repo yet)
2. Future enhancement (split-screen TUI)
3. Conditionally built (only for certain platforms)

**Features (from main.lua context):**
- **Split-screen layout** — Status bar (top) + output window + input area
- **Status bar** — Level + room name, game time, matches remaining, candle state (see `engine/ui/status.lua`)
- **Scrollback buffer** — Players can scroll output history with `/up`, `/down`
- **Word-wrapping integration** — UI window width syncs with `display.WIDTH`

**Activation:**
```lua
-- In main.lua:
ui_active = ui.init()
if ui_active then
  display.ui = ui
  display.WIDTH = ui.get_width()
end
```

**Fallback:**
When UI is not active, REPL uses standard `io.read()` and `print()` (with word-wrapping).

---

## Sensory System Integration

The UI layer is **sensory-aware**. Output adapts based on:
1. **Light State** — Room is lit/dim/dark
2. **Player Vision** — Wearing blindfold/sack blocks LOOK
3. **Object State** — Candle lit vs unlit, door open vs closed

**Examples:**

```
# Bright room, candle lit:
> look
A Small Bedroom
Dawn light pours through the window. A lit candle on the nightstand casts 
a warm glow.

# Dark room, no light:
> look
You can't see anything. The darkness is absolute.

# Wearing sack on head (vision blocked):
> look
Your sight is blocked. Perhaps you could remove what's covering your eyes?

# Dark room, using FEEL instead:
> feel
You run your hands over rough linen sheets. The bed is soft beneath your 
fingers. The air feels cool.
```

**Verb Gating:**
- `LOOK`, `EXAMINE`, `READ` — Require light AND unblocked vision
- `FEEL`, `SMELL`, `TASTE`, `LISTEN` — Work in darkness, bypass vision blocking

See [player-sensory.md](../player/player-sensory.md) for complete sensory rules.

---

## Error Messages & Feedback

**Design Philosophy:** Errors should explain the *constraint* blocking the action, not just fail silently.

**Bad Error (Old):**
```
> take rug
TAKE FAILED.
```

**Good Error (Current):**
```
> take rug
The rug is too heavy for you to lift. Perhaps it could be moved aside 
instead?
```

**Constraint Categories:**
- **Physical:** Too heavy, too large, immovable
- **State:** Container closed, door locked, object broken
- **Capability:** Need tool (fire_source to light candle), need skill (sewing to sew)
- **Sensory:** Too dark to see, vision blocked
- **Inventory:** Hands full, backpack at capacity

**Diagnostic Mode:**
When `--debug` flag is active, failed commands show parser internals:
```
> flibber the candle
[Parser] Tier 1 miss: "flibber" not in verb table
[Parser] Tier 2 match: "light candle" via "flibber candle" (score: 0.35)
[Parser] Below threshold (0.40). No match found.
I don't understand that. Try 'help' for a list of commands.
```

This enables Wayne to see what players type → update phrase dictionary → improve coverage.

---

## Verb Handlers

**Location:** `src/engine/verbs/init.lua`

Each verb is a Lua function that receives `(context, noun)`:

```lua
verbs["look"] = function(ctx, noun)
  local room = ctx.current_room
  -- Check light state
  if not has_light(room, ctx) then
    print("You can't see anything. The darkness is absolute.")
    return
  end
  -- Check player vision
  if player_vision_blocked(ctx.player) then
    print("Your sight is blocked.")
    return
  end
  -- Compose room description
  print(room.name)
  print(compose_room_description(room, ctx.registry))
end
```

**Verb Categories:**
1. **Navigation & Perception** (8 verbs): LOOK, EXAMINE, READ, SEARCH, FEEL, SMELL, TASTE, LISTEN
2. **Inventory Management** (7 verbs): TAKE, DROP, INVENTORY, WEAR, REMOVE, PUT, OPEN, CLOSE
3. **Object Interaction** (9 verbs): LIGHT, STRIKE, EXTINGUISH, BREAK, TEAR, WRITE, CUT, SEW, PRICK
4. **Movement** (4 verbs): GO, NORTH, SOUTH, EAST, WEST, UP, DOWN
5. **Meta & Help** (3 verbs): HELP, QUIT, TIME

**Total:** 31 verbs (as of 2026-03-22)

See [docs/design/verb-system.md](../../design/verb-system.md) for complete verb reference.

---

## Context Tracking

The REPL maintains context for Tier 3+ parsing:

```lua
context = {
  registry       = registry,      -- Live object registry
  current_room   = room,          -- Player location
  player         = player,        -- Player state (hands, worn, skills)
  verbs          = verb_handlers, -- Verb dispatch table
  parser         = parser_module, -- Tier 2 embedding matcher
  last_tool      = nil,           -- Last tool used (for Tier 3 context)
  known_objects  = {},            -- Objects player has examined
  game_start_time = os.time(),    -- Real-world start time
  game_start_hour = 2,            -- Game clock: 2 AM
  on_tick        = tick_callback, -- Post-command FSM update
  update_status  = status_updater,-- Status bar refresh (if UI active)
}
```

**Context Usage:**
- **Tier 3 GOAP** — Uses `known_objects` to infer tool sources ("light candle" → infers match from matchbox)
- **Tier 4 (future)** — Will track `recent_commands`, confidence scores, discovery timestamps
- **Game Clock** — UI status bar shows game time (24x real-time speed)
- **FSM Tick** — Post-command phase triggers timer countdowns (match burns, candle depletes)

---

## Natural Language Preprocessing

**Location:** `src/engine/loop/init.lua` (function `preprocess_natural_language`)

Before parsing, the REPL expands common question patterns into verb+noun:

```lua
"what is around?"       → "look" ""
"what's in the box?"    → "look" "in box"
"what time is it?"      → "time" ""
"what am I carrying?"   → "inventory" ""
"take out match"        → "pull" "match"
"roll up rug"           → "move" "rug"
"put out candle"        → "extinguish" "candle"
"put on gloves"         → "wear" "gloves"
"take off gloves"       → "remove" "gloves"
"go to bed"             → "sleep" ""
"use needle on cloth"   → "sew" "cloth with needle"
```

**Why Preprocessing?**
- Converts natural questions into canonical verb forms
- Reduces Tier 2 dictionary size (fewer phrases to match)
- Faster than embedding similarity (deterministic pattern matching)
- Easier to debug and extend than phrase similarity

**Trade-off:**
- More hard-coded patterns to maintain
- BUT: Covers 90% of common phrasings with zero token cost

---

## Related Systems

- **Parser Pipeline:** [parser-overview.md](parser-overview.md)
- **Text Presentation:** [text-presentation.md](text-presentation.md)
- **Verb System:** [../../design/verb-system.md](../../design/verb-system.md)
- **Player Sensory:** [../player/player-sensory.md](../player/player-sensory.md)
- **Core Principles:** [../objects/core-principles.md](../objects/core-principles.md)

---

## Open Questions & Improvement Areas

**From Newspapers & Wayne's Directives:**

1. **Terminal UI Status** — `ui.lua` referenced but not found. Is this:
   - External dependency (ncurses, blessed, etc.)?
   - Future enhancement (TBD)?
   - Platform-specific (mobile vs desktop)?

2. **Parser Diagnostic Toggle** — `--debug` flag controls diagnostic output. Should this be:
   - Always-on for early playtesting?
   - User-configurable in settings menu?
   - Different verbosity levels (silent, basic, verbose)?

3. **Tier 3 GOAP Integration** — Goal planner exists but may not be fully wired. Status unclear from code:
   - Is it only activated for specific verbs?
   - Does it run on all Tier 2 misses?
   - What's the performance budget?

4. **Context Window (Tier 4)** — Designed but not implemented. Key questions:
   - How long should context window last? (5 ticks? 20 ticks? Session-long?)
   - What triggers context decay? (Time? Distance? New room?)
   - How does confidence scoring work in practice?

5. **Error Message Coverage** — Some verbs have helpful errors, others don't. Need systematic audit:
   - All 31 verbs should explain failures
   - Standard constraint categories (physical, state, capability, sensory, inventory)
   - Template-based error generation?

6. **Mobile UI Adaptation** — When PWA ships (per Frink's Wasmoon plan), UI needs:
   - Touch-friendly input (virtual keyboard, autocomplete?)
   - Swipe gestures for scrollback?
   - Smaller text width (40-60 chars)?
   - Status bar persistence (always visible)?

---

**END OF OVERVIEW**  
*See individual UI architecture docs for implementation details.*
