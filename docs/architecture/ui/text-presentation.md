# Text Presentation & Output Formatting

**Version:** 1.0  
**Author:** Smithers (UI Engineer)  
**Last Updated:** 2026-03-22  
**Purpose:** Complete specification of how text is formatted, presented, and adapted based on game state.

---

## Overview

The MMO presents all game information as formatted text. This document describes:
1. **Room Descriptions** — How rooms are dynamically composed and presented
2. **Object Descriptions** — State-aware sensory descriptions
3. **Action Feedback** — Success/failure messages
4. **Error Messages** — Constraint-explaining failure reporting
5. **Sensory Output** — Dark vs lit, blocked vision, multi-sense descriptions
6. **Word-Wrapping** — Terminal-width formatting

---

## Core Principle: Dynamic Composition

**Hard-Coded Descriptions Are Anti-Pattern**

Traditional text adventures hard-code room descriptions:
```lua
-- WRONG: Hard-coded description (anti-pattern)
room.description = "A small bedroom. There is a bed here. A nightstand. A wardrobe."
```

**Problem:** When objects move, the description lies. Player takes the candle → description still says "candle on nightstand."

**The MMO Approach:** Dynamic composition from three sources:
```lua
-- RIGHT: Dynamic composition
room_description = compose_from(
  room.base_description,    -- Permanent architectural features
  object_presences,         -- Each object's room_presence text
  visible_exits             -- Exit list with current state
)
```

**Location:** `src/engine/loop/init.lua` (function `cmd_look`)

---

## Room Descriptions

### Three-Part Structure

Every room description is composed from:

#### Part 1: Base Description (Permanent Features)
Architectural and immovable details that never change:
```lua
room.description = [[
Stone walls surround you, bare and cold. A single window admits faint 
starlight. The air smells faintly of tallow and dust.
]]
```

**What Belongs Here:**
- Walls, floor, ceiling materials
- Fixed windows, fireplaces, architectural features
- Ambient sensory details (smells, temperature, sounds)
- Room size and shape

**What Does NOT Belong:**
- Movable objects (bed, furniture)
- Object states (lit candle, open door)
- Anything that can change during gameplay

#### Part 2: Object Presences (Dynamic Elements)
Each visible object contributes its `room_presence` field:
```lua
-- Object definition
bed = {
  id = "bed",
  name = "a four-poster bed",
  room_presence = "A four-poster bed dominates the room, its linen sheets rumpled."
}

nightstand = {
  id = "nightstand",
  name = "a small nightstand",
  room_presence = "A small nightstand sits beside the bed."
}
```

**Composition:**
```lua
-- Engine concatenates all room_presence strings
for _, obj_id in ipairs(room.contents) do
  local obj = registry:get(obj_id)
  if obj and not obj.hidden and obj.room_presence then
    presences[#presences + 1] = obj.room_presence
  end
end
```

**Result:**
```
A four-poster bed dominates the room, its linen sheets rumpled. A small 
nightstand sits beside the bed. A heavy wardrobe stands against the far 
wall.
```

#### Part 3: Visible Exits
Exit list shows each exit's name and current state:
```lua
-- Exit state formatting
Exits:
  north: A wooden door (locked)
  east: A narrow hallway
```

**Exit States:**
- `(locked)` — Locked door/gate
- `(closed)` — Closed but unlocked
- `(open)` — Explicitly open (if needed for clarity)
- *(no state)* — Passageway (always open)

**Hidden Exits:**
Exits with `hidden = true` don't appear in the list until discovered.

### Room Description Example (Full)

```
> look

A Small Bedroom

Stone walls surround you, bare and cold. A single window admits faint 
starlight. The air smells faintly of tallow and dust.

A four-poster bed dominates the room, its linen sheets rumpled. A small 
nightstand sits beside the bed. A heavy wardrobe stands against the far 
wall.

Exits:
  north: A wooden door (locked)
```

### Light-Dependent Room Descriptions

Room descriptions adapt to light state:

**Dark Room (No Light):**
```
> look
You can't see anything. The darkness is absolute.
```

**Dim Room (Twilight/Faint Glow):**
```
> look
A Small Bedroom (Dim)

Shadows fill the room. You can make out vague shapes but no details. 
Faint starlight filters through a window.

You sense something large to your left (probably the bed).

Exits:
  north: Something that might be a door
```

**Bright Room (Daylight or Light Source):**
```
> look
A Small Bedroom

Dawn light pours through the window. A lit candle on the nightstand casts 
a warm amber glow.

(Full description with all details visible)
```

**Implementation:**
```lua
-- Tri-state light system (from D-26, Wayne's directives)
function get_light_state(room, registry)
  -- Check for light sources in room
  for _, obj_id in ipairs(room.contents) do
    local obj = registry:get(obj_id)
    if obj and obj.casts_light then
      return "lit"
    end
  end
  
  -- Check for daylight (6 AM to 6 PM + window)
  if room.has_window and is_daytime() then
    return "lit"
  end
  
  -- Check for ambient/indirect light
  if room.ambient_light then
    return "dim"
  end
  
  return "dark"
end
```

---

## Object Descriptions

### State-Aware Descriptions

Objects return different descriptions based on their current FSM state:

**Example: Candle (Unlit)**
```
> examine candle
A tapered candle made of yellow tallow. The wick is dark and unlit.
```

**Example: Candle (Lit)**
```
> examine candle
A tapered candle made of yellow tallow. The wick burns with a steady 
amber flame, casting warm light around the room.
```

**Example: Candle (Spent)**
```
> examine candle
A guttered candle stub. The wick is blackened and useless.
```

**Implementation:**
Each FSM state defines its own description field:
```lua
-- candle.lua
states = {
  unlit = {
    description = "A tapered candle made of yellow tallow. The wick is dark and unlit."
  },
  lit = {
    description = "A tapered candle... The wick burns with a steady amber flame...",
    casts_light = true
  },
  spent = {
    description = "A guttered candle stub. The wick is blackened and useless."
  }
}
```

### Multi-Sensory Descriptions

Objects can provide different descriptions for different senses:

```lua
poison_bottle = {
  description = "A small glass bottle filled with iridescent green liquid.",
  
  sensory = {
    smell = "It smells sharply of bitter almonds. Your nose wrinkles instinctively.",
    taste = "Acrid and burning. Your throat constricts. (This kills you.)",
    feel = "The glass is cool and smooth. The bottle is sealed with a cork.",
    listen = "The liquid sloshes faintly inside the glass."
  }
}
```

**Usage:**
```
> look at bottle
A small glass bottle filled with iridescent green liquid.

> smell bottle
It smells sharply of bitter almonds. Your nose wrinkles instinctively.

> taste bottle
Acrid and burning. Your throat constricts.
(You have died from poison. Game over.)
```

**Why Multi-Sensory?**
From D-27 (Wayne's directives on sensory system):
- Darkness forces non-visual exploration
- SMELL warns of danger (poison, gas) before TASTE kills
- FEEL enables navigation without light
- LISTEN reveals mechanical state (ticking clock, dripping water)

**Verb Gating by Sense:**
| Sense | Requires Light? | Requires Vision? | Safety |
|-------|----------------|------------------|--------|
| **Sight (LOOK, EXAMINE)** | YES | YES | Safe |
| **Touch (FEEL)** | No | No | Medium risk (glass shard cuts) |
| **Smell (SMELL)** | No | No | Safe |
| **Sound (LISTEN)** | No | No | Safe |
| **Taste (TASTE)** | No | No | **DANGEROUS** (poison, acid) |

See [../player/player-sensory.md](../player/player-sensory.md) for complete sensory rules.

---

## Action Feedback

### Success Messages

When an action succeeds, the engine prints:
1. **What happened** (action result)
2. **State change** (if object mutated)
3. **Sensory feedback** (new perceptions)

**Example: Lighting a Candle**
```
> light candle
You touch the lit match to the candle wick. The wax catches fire, and 
warm amber light fills the room.

(The room description automatically updates to "lit" state)
```

**Example: Opening a Container**
```
> open drawer
You pull the small drawer open. It slides out with a soft wooden scrape.

Inside you find: a matchbox, a brass key, a folded note.
```

### Failure Messages

Failed actions explain the *constraint* blocking success:

**Physical Constraint:**
```
> take bed
The bed is far too heavy to lift. It would take multiple people to move 
it.
```

**State Constraint:**
```
> take match from matchbox
The matchbox is closed. You'll need to open it first.
```

**Capability Constraint:**
```
> light candle
You need a fire source to light the candle. Perhaps a match?
```

**Sensory Constraint:**
```
> examine drawer
You can't see anything in the darkness. Try using FEEL to explore by 
touch.
```

**Inventory Constraint:**
```
> take drawer
You need both hands free to lift that. Your hands are full.

(Hands: left = torch, right = matchbox)
```

---

## Error Messages

### Philosophy: Explain the "Why"

**Bad Error (Cryptic):**
```
> flibber the candle
I don't understand that.
```

**Good Error (Helpful):**
```
> flibber the candle
I don't recognize "flibber" as a verb. Did you mean "light"? 
Try 'help' for a full list of commands.
```

**Better Error (Diagnostic Mode):**
```
> flibber the candle
[Parser] Tier 1 miss: "flibber" not in verb table
[Parser] Tier 2: best match "light" (score: 0.35, threshold: 0.40)
[Parser] No match found.

I don't understand that. Try 'help' for a full list of commands.
```

### Standard Error Categories

**1. Unknown Verb**
```
> xyzzy
I don't recognize "xyzzy" as a command. Type 'help' to see all available 
commands.
```

**2. Missing Object**
```
> examine banana
You don't see that here.
```

**3. Ambiguous Object**
```
> take match
Which match do you mean?
  - the lit match (in your hand)
  - the wooden match (in the matchbox)
```

**4. Constraint Violation**
```
> push bed
The bed is too heavy to move on your own.
```

**5. Invalid Action for Object**
```
> light the rug
The rug cannot be lit. It's not a flammable light source.
```

**6. Question Redirect**
```
> what is this?
Try 'look' to look around, or 'examine <object>' to inspect something 
specific.
```

### Error Message Implementation

**Location:** Individual verb handlers (in `src/engine/verbs/init.lua`)

Each verb checks preconditions and returns helpful errors:
```lua
verbs["take"] = function(ctx, noun)
  local obj = resolve_object(noun, ctx)
  
  if not obj then
    print("You don't see that here.")
    return
  end
  
  if obj.immovable then
    print("The " .. obj.name .. " is too heavy to lift.")
    return
  end
  
  local hands_needed = obj.hands_required or 1
  local hands_free = count_free_hands(ctx.player)
  
  if hands_needed > hands_free then
    print("You need " .. hands_needed .. " hands free to lift that.")
    print("(You have " .. hands_free .. " hands available)")
    return
  end
  
  -- Success path...
end
```

---

## Sensory Output Formatting

### Vision-Dependent Output

**Bright Room:**
```
> look
A Small Bedroom

Dawn light pours through the window. The stone walls are rough and bare. 
A four-poster bed dominates the room with rumpled linen sheets.
```

**Dark Room:**
```
> look
You can't see anything. The darkness is absolute.

> feel
You run your hands along rough stone walls. Cool air flows from your 
left—perhaps a window? You feel the edge of something large and soft 
(probably a bed).
```

**Vision Blocked (Wearing Sack on Head):**
```
> look
Your sight is completely blocked. Perhaps you could remove what's 
covering your eyes?

> remove sack
You pull the burlap sack off your head. Light floods your vision.

> look
(Now normal room description appears)
```

### Multi-Sense Integration

When light is unavailable, players rely on other senses:

**Darkness Exploration Sequence:**
```
> feel
You grope around in the darkness. Your hands find:
  - Rough stone walls (cold to the touch)
  - A wooden frame (probably a bed)
  - Smooth glass (a window?)
  - A small wooden box (on a table or nightstand?)

> smell
The air smells faintly of tallow (candle wax) and old wood. A slight 
draft carries cooler air from your left.

> listen
Silence. Very faint creaking from the bed frame. A distant dripping 
sound from somewhere beyond the walls.

> smell box
Waxy. Definitely candle-related. Perhaps it contains matches?
```

---

## Word-Wrapping

### Why Word-Wrapping Matters

**Without Word-Wrapping (BAD):**
```
A four-poster bed dominates the room, its linen sheets rumpled and the wooden frame creaking
 softly. A small nightstand sits beside it with a single drawer half-open.
```
(Text splits mid-word at terminal edge, potentially duplicating characters)

**With Word-Wrapping (GOOD):**
```
A four-poster bed dominates the room, its linen sheets rumpled and the 
wooden frame creaking softly. A small nightstand sits beside it with a 
single drawer half-open.
```
(Text wraps cleanly at word boundaries)

### Implementation

**Location:** `src/engine/display.lua`

```lua
display.WIDTH = 78  -- Default terminal width

function display.word_wrap(text, width)
  width = width or display.WIDTH
  
  local output = {}
  -- Split on existing newlines
  for segment in (text .. "\n"):gmatch("(.-)\n") do
    if segment == "" then
      output[#output + 1] = ""
    else
      -- Preserve leading whitespace (for indented lists)
      local indent = segment:match("^(%s*)") or ""
      local content = segment:sub(#indent + 1)
      
      if #indent + #content <= width then
        output[#output + 1] = segment
      else
        -- Word-wrap long lines
        local line = indent
        for word in content:gmatch("%S+") do
          if line == indent then
            line = indent .. word
          elseif #line + 1 + #word > width then
            output[#output + 1] = line
            line = indent .. word
          else
            line = line .. " " .. word
          end
        end
        if line ~= indent then
          output[#output + 1] = line
        end
      end
    end
  end
  
  return table.concat(output, "\n")
end
```

### Global Print Override

All output automatically word-wraps:
```lua
-- Install at startup (in main.lua)
display.install()

-- Now all print() calls wrap text:
print("This is a very long line that will automatically wrap at word boundaries to fit the terminal width.")
```

**Result:**
```
This is a very long line that will automatically wrap at word boundaries 
to fit the terminal width.
```

### UI Integration

When split-screen terminal UI is active:
```lua
if ui_active then
  display.ui = ui
  display.WIDTH = ui.get_width()  -- Sync width with UI window
end
```

All `print()` calls route through `ui.output()` which handles scrollback buffering.

---

## Status Bar (Terminal UI)

**Location:** `src/main.lua` (function `context.update_status`)

When terminal UI is enabled, a status bar shows:
- Room name (left side)
- Game time (left side)
- Match count (right side)
- Candle state (right side)

**Example Status Bar:**
```
┌────────────────────────────────────────────────────────────────────────┐
│ A SMALL BEDROOM  2:15 AM                    Matches: 7  Candle: *      │
└────────────────────────────────────────────────────────────────────────┘
```

**Symbols:**
- `*` — Candle lit (casts light)
- `o` — Candle unlit (dark)
- `?` — Match count unknown (matchbox not examined)

**Game Clock:**
- 24x real-time speed: 1 real second = 24 game seconds
- Display format: `12:15 AM` (12-hour clock)
- Updates every command (status bar refresh in REPL loop)

**Implementation:**
```lua
context.update_status = function(ctx)
  if not ctx.ui then return end
  
  -- Compute game time
  local real_elapsed = os.time() - ctx.game_start_time
  local total_hours = (real_elapsed * 24) / 3600
  local hour = math.floor((2 + total_hours) % 24)
  local minute = math.floor((total_hours * 60) % 60)
  
  local time_str = string.format("%d:%02d %s", 
    hour % 12, minute, hour >= 12 and "PM" or "AM")
  
  -- Room name
  local room_name = ctx.current_room.name:upper()
  
  -- Match count
  local matchbox = ctx.registry:get("matchbox")
  local match_count = matchbox and #matchbox.contents or "?"
  
  -- Candle state
  local candle_icon = ctx.player.state.has_flame > 0 and "*" or "o"
  
  -- Format status bar
  local left = " " .. room_name .. "  " .. time_str
  local right = "Matches: " .. match_count .. "  Candle: " .. candle_icon .. " "
  ctx.ui.status(left, right)
end
```

---

## Related Systems

- **Parser Pipeline:** [parser-overview.md](parser-overview.md)
- **Verb Handlers:** [../../design/verb-system.md](../../design/verb-system.md)
- **Player Sensory:** [../player/player-sensory.md](../player/player-sensory.md)
- **Object FSM:** [../objects/core-principles.md](../objects/core-principles.md)
- **Light System:** [../../design/design-directives.md](../../design/design-directives.md) (D-26)

---

## Examples from Newspapers

**From 2026-03-19 (Wayne's First Play Test):**

Wayne encountered three presentation issues:
1. **Dawn/dark contradiction** — "Dawn light pours through window" + "drawer is pitch black" (physically impossible)
   - **Fix:** Tri-state light system (lit/dim/dark) prevents contradictions
2. **No tactile feedback** — Tried to FEEL bed, no verb existed
   - **Fix:** Added FEEL, TOUCH, GROPE verbs with tactile descriptions
3. **Cryptic errors** — "TAKE FAILED" with no explanation
   - **Fix:** All errors now explain constraints

**From 2026-03-20 (Evening Edition):**

GOAP parser shipped. Complex multi-step feedback:
```
> light candle
You'll need to prepare first...
You pull the small drawer open. It slides out with a soft wooden scrape.
You slide the matchbox tray open with your thumb. Inside, a clutch of 
wooden matches rests snugly in a row.
You take a wooden match from an open matchbox.
You drag the match head across the striker strip. It sputters once, 
twice -- then catches...
The wick catches the flame and curls to life, throwing a warm amber glow 
across the room.
```

**Five prerequisite actions → One success message chain**

This demonstrates:
- Dynamic feedback composition (each step narrates its own action)
- State change visibility (drawer opens, matchbox reveals contents)
- Sensory details (scraping sound, amber glow)
- Natural flow (reads like prose, not system messages)

---

**END OF TEXT PRESENTATION**  
*Next: [parser-overview.md](parser-overview.md) for complete parser architecture.*
