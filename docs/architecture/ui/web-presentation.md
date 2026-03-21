# Web Presentation & UI/UX Specifications

**Version:** 1.0  
**Author:** Wayne Berry (Play Testing & UX Director)  
**Last Updated:** 2026-03-24  
**Purpose:** Web-specific UI/UX requirements discovered during play testing. Documents visual presentation, room traversal behavior, and bug reporting system.

---

## Overview

This document captures four critical UX findings from Wayne's play testing sessions. Each requirement improves player clarity and engagement:

1. **Room Titles — Visual Prominence** — First thing players see must stand out
2. **Short Descriptions on Revisit** — Classic IF behavior (Zork, Infocom) for fluidity
3. **Command Input Styling** — Player input must be immediately distinguishable from output
4. **Bug Report Metadata** — Rich context for issue reporting and debugging

These requirements apply primarily to the **Web client** (HTML/CSS/JavaScript), with CLI equivalent noted where applicable.

---

## 1. Room Titles — Bold/Visually Prominent

**Requirement:** When entering a room, the room name/title must be **bold** or otherwise visually prominent. This is the first element the player sees and must stand out clearly from the room description text.

### Design Rationale

Players need an immediate visual anchor. The room title should dominate the visual hierarchy:
- **First glance:** "Where am I?" → Room title (bold/large)
- **Second glance:** "What's here?" → Description (normal weight)
- **Third glance:** "What can I do?" → Exits (normal weight)

### Web Implementation

**Use `<strong>` tag or `font-weight: bold` CSS:**

```html
<!-- Example room output -->
<div class="room-output">
  <h2 class="room-title"><strong>A Small Bedroom</strong></h2>
  <p class="room-description">
    Stone walls surround you, bare and cold. A single window admits faint 
    starlight. The air smells faintly of tallow and dust.
  </p>
  <p class="room-contents">
    A four-poster bed dominates the room, its linen sheets rumpled. A small 
    nightstand sits beside it. A heavy wardrobe stands against the far wall.
  </p>
  <div class="exits">
    <strong>Exits:</strong>
    <ul>
      <li>north: A wooden door (locked)</li>
    </ul>
  </div>
</div>
```

**CSS Styling:**

```css
.room-title {
  font-size: 1.5em;
  font-weight: bold;
  margin: 1em 0 0.5em 0;
  color: #fff;  /* Light gray on dark terminal background */
}

.room-description {
  font-weight: normal;
  margin-bottom: 0.5em;
  line-height: 1.5;
}
```

### CLI Implementation

**Use ANSI bold escape codes** (if terminal supports it):

```lua
-- src/engine/display.lua
function display.room_title(title)
  -- ANSI codes for bold output (if supported)
  if display.supports_ansi then
    print("\27[1m" .. title .. "\27[0m")  -- \27[1m = bold, \27[0m = reset
  else
    print(title)  -- Fallback: plain text (limited terminal)
  end
end
```

**Result in Terminal:**
```
A Small Bedroom              <- Appears bold (if terminal supports it)

Stone walls surround you...  <- Normal weight
```

### Affected Code Locations

- **Web:** Game output rendering component (React/Vue/HTML template)
- **CLI:** `src/engine/verbs/init.lua` — `cmd_look` function prints room title

---

## 2. Short Room Descriptions on Revisit

**Requirement:** After the first visit to a room, re-entering should show a SHORT description (1-2 lines), not the full sensory text. The full description is only shown on first entry or when the player explicitly types `look`.

### Design Rationale

This is classic IF game behavior (Zork, Infocom). It solves:
- **Tedium:** Players don't re-read verbose descriptions when backtracking
- **Pacing:** Game feels faster and more fluid on revisits
- **Player Control:** Explicit `look` command always grants full details

### Implementation Requirements

#### 1. Tracking Visited Rooms

Add a **`visited_rooms` table/set** to the game context:

```lua
-- src/main.lua (initialization)
context = {
  registry        = registry,
  current_room    = room,
  player          = player,
  visited_rooms   = {},  -- NEW: Track visited rooms
  -- ... rest of context
}

-- src/engine/loop/init.lua (after each room transition)
function cmd_go(ctx, direction)
  local next_room = find_exit(ctx.current_room, direction)
  if next_room then
    ctx.current_room = next_room
    ctx.visited_rooms[next_room.id] = true  -- Mark as visited
    cmd_look(ctx, "")  -- Show room (abbreviated if revisit)
  end
end
```

#### 2. Description Display Rules

**First Visit:**
```
> go north
A Small Bedroom

Stone walls surround you, bare and cold. A single window admits faint 
starlight. The air smells faintly of tallow and dust.

A four-poster bed dominates the room, its linen sheets rumpled. A small 
nightstand sits beside it. A heavy wardrobe stands against the far wall.

Exits:
  north: A wooden door (locked)
```

**Revisit (Short):**
```
> go south
(back to the hall)

> go north
A Small Bedroom

You've been here before. Stone walls, a bed, a wardrobe. Exits north 
(locked door).
```

**Explicit Look (Always Full):**
```
> go north
A Small Bedroom

You've been here before. Stone walls, a bed, a wardrobe. Exits north (locked).

> look
A Small Bedroom

Stone walls surround you, bare and cold. A single window admits faint 
starlight. The air smells faintly of tallow and dust.

A four-poster bed dominates the room, its linen sheets rumpled. A small 
nightstand sits beside it. A heavy wardrobe stands against the far wall.

Exits:
  north: A wooden door (locked)
```

#### 3. Short Description Field

Add optional `short_description` field to room objects:

```lua
-- rooms/bedroom.lua
bedroom = {
  id = "bedroom",
  name = "A Small Bedroom",
  
  description = [[
    Stone walls surround you, bare and cold. A single window admits faint 
    starlight. The air smells faintly of tallow and dust.
  ]],
  
  short_description = [[
    You've been here before. Stone walls, a bed, a wardrobe.
  ]],
  
  -- ... rest of room definition
}
```

If `short_description` is not provided, engine generates a fallback:

```lua
function generate_short_description(room, registry)
  local objects = {}
  for _, obj_id in ipairs(room.contents) do
    local obj = registry:get(obj_id)
    if obj and not obj.hidden then
      table.insert(objects, obj.name)
    end
  end
  
  local obj_list = table.concat(objects, ", ")
  return "You've been here before. " .. room.base_description:sub(1, 50) .. 
         "... " .. obj_list .. "."
end
```

#### 4. Updated Look Handler

Modify `cmd_look` to check visit status:

```lua
-- src/engine/verbs/init.lua
verbs["look"] = function(ctx, noun)
  local room = ctx.current_room
  
  -- Check light state
  if not has_light(room, ctx) then
    print("You can't see anything. The darkness is absolute.")
    return
  end
  
  -- Always show full description when explicitly commanded
  print(room.name)
  print(compose_room_description(room, ctx.registry))
end

-- New handler for room entry
function enter_room(ctx, room)
  ctx.current_room = room
  
  -- Mark as visited
  ctx.visited_rooms[room.id] = true
  
  -- Display appropriate description
  print(room.name)
  
  if ctx.visited_rooms[room.id] and room.short_description then
    -- Revisit: show short description
    print(room.short_description)
  else
    -- First visit: show full description
    print(compose_room_description(room, ctx.registry))
  end
end
```

**Bug:** Current code marks as visited *after* displaying. Fix: mark *before* checking.

#### 5. Web Implementation

The web client should maintain visited rooms across sessions (localStorage):

```javascript
// src/web/game-client.js
class GameClient {
  constructor() {
    this.visitedRooms = this.loadVisitedRooms() || {};
    this.currentRoom = null;
  }
  
  loadVisitedRooms() {
    return JSON.parse(localStorage.getItem('visited_rooms') || '{}');
  }
  
  saveVisitedRooms() {
    localStorage.setItem('visited_rooms', JSON.stringify(this.visitedRooms));
  }
  
  enterRoom(room) {
    this.currentRoom = room;
    
    if (this.visitedRooms[room.id]) {
      // Revisit: show short description
      this.displayShortDescription(room);
    } else {
      // First visit: show full description
      this.displayFullDescription(room);
    }
    
    this.visitedRooms[room.id] = true;
    this.saveVisitedRooms();
  }
}
```

### Affected Code Locations

- **Engine:** `src/engine/verbs/init.lua` (look/go handlers)
- **Engine:** `src/main.lua` (context initialization)
- **Data:** Room definitions (add `short_description` field)
- **Web:** Game client (localStorage persistence)

---

## 3. Command Input Styling

**Requirement:** Player input should be visually distinct from game output, but light gray (#888) doesn't stand out enough. Input must be immediately scannable in the transcript.

### Current Problem

**Current styling (too subtle):**
```
Dark background (#222)
Game output: Light gray (#ccc)
Player input: Light gray (#888) ← Blends with background
```

Result: Players can't quickly scan who said what. Hard to review transcript.

### Design Options

The goal is **maximum visual distinction** while maintaining readability. Evaluate these options:

#### Option A: White Text + Gray Output

```
Player input:  White text (#fff)        ← HIGH CONTRAST
Game output:   Light gray (#ccc)        ← Normal
```

**Pros:** Simple, classic IF style. High contrast.  
**Cons:** White can feel harsh on dark backgrounds.

**CSS:**
```css
.game-input {
  color: #fff;        /* White */
  font-weight: normal;
}

.game-output {
  color: #ccc;        /* Light gray */
}
```

#### Option B: Cyan/Teal Accent Color

```
Player input:  Cyan (#0ff or #00e0e0)  ← DISTINCT & READABLE
Game output:   Light gray (#ccc)
```

**Pros:** Thematic (early terminal aesthetic). Highly distinct. Easy on eyes.  
**Cons:** May feel retro/dated on modern web.

**CSS:**
```css
.game-input {
  color: #00e0e0;      /* Bright cyan */
  font-weight: normal;
}

.game-output {
  color: #ccc;
}
```

#### Option C: Prompt Character Prefix

```
Player input: > light candle          ← Prompt character makes input clear
Game output:  You touch the lit match...
```

Combine with color change (Option A or B) for maximum clarity:

```css
.game-input::before {
  content: "> ";
  color: #888;  /* Gray prompt */
  font-weight: bold;
}

.game-input {
  color: #fff;  /* White text */
}
```

**Result on screen:**
```
> light candle              (prompt in gray, text in white)
You touch the lit match to the candle wick...
```

### Recommended Approach

**Use Option B (Cyan) + Option C (Prompt Character):**

```
> light candle              (cyan text with gray > prefix)
You touch the lit match...   (light gray)
```

This combines:
- **High visual distinction** — Cyan stands out from gray
- **Classic IF feel** — Prompt character is familiar
- **Accessibility** — Color + symbol redundancy (not color-blind dependent)
- **Scanability** — Players can quickly scan: "where are my inputs?"

### Web Implementation

**HTML:**
```html
<div class="game-transcript">
  <!-- Game output -->
  <div class="output-line">You can make out vague shapes in the darkness.</div>
  
  <!-- Player input -->
  <div class="input-line">
    <span class="input-prompt">&gt;</span> 
    <span class="input-text">light candle</span>
  </div>
  
  <!-- Game response -->
  <div class="output-line">The wick catches. Warm amber light fills the room.</div>
</div>
```

**CSS:**
```css
.input-line {
  margin: 0.5em 0;
  display: flex;
}

.input-prompt {
  color: #888;          /* Gray */
  margin-right: 0.5em;
  font-weight: bold;
}

.input-text {
  color: #00e0e0;       /* Bright cyan */
}

.output-line {
  color: #ccc;          /* Light gray */
  margin: 0.25em 0;
  line-height: 1.4;
}
```

### CLI Implementation

**ANSI color codes for terminal:**

```lua
-- src/engine/display.lua
local CYAN = "\27[36m"
local GRAY = "\27[90m"
local RESET = "\27[0m"

function display.print_input(text)
  print(GRAY .. "> " .. RESET .. CYAN .. text .. RESET)
end
```

### Affected Code Locations

- **Web:** Game transcript rendering component (CSS styling, template markup)
- **Web:** Game input handler (append input to transcript when entered)
- **CLI:** `src/engine/display.lua` (override print for input)
- **CLI:** `src/engine/loop/init.lua` (when displaying player input)

---

## 4. Bug Report Metadata

**Requirement:** The `report bug` command should include rich metadata to help debugging. Players should describe the issue in their own words, but the system provides context.

### Current State

Likely missing or minimal. Proposal:

### Rich Metadata Fields

The bug report should capture:

```
┌─ BUG REPORT ─────────────────────────────────────────────────────┐
│                                                                   │
│ **Level:** Level 1: The Awakening                                │
│ **Room:** The Bedroom                                            │
│ **Time:** 2:15 AM (10 ticks elapsed)                             │
│ **Inventory:** match, candle (2/10 slots used)                   │
│ **Recent Commands (Last 5):**                                    │
│   1. look                                                        │
│   2. examine drawer                                              │
│   3. open drawer                                                 │
│   4. take matchbox                                               │
│   5. light candle                                                │
│                                                                  │
│ **Recent Output (Last 50 Lines):**                               │
│   You run your hands over rough linen sheets. The bed is soft... │
│   A small drawer slides out with a wooden scrape.                │
│   Inside you find: a matchbox, a brass key, a folded note.       │
│   ...                                                            │
│                                                                  │
│ **What's Wrong?** (describe in your own words)                   │
│ _______________________________________________________________  │
│ _______________________________________________________________  │
│ _______________________________________________________________  │
│                                                                   │
│ [SUBMIT BUG]  [CANCEL]                                           │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

### Field Specifications

#### 1. Level Name
```
**Level:** Level 1: The Awakening
```
Displayed as level ID from game context.

#### 2. Room Name
```
**Room:** The Bedroom
```
Captured at report time. Helps reproduce issues in specific locations.

#### 3. Game Time
```
**Time:** 2:15 AM (10 ticks elapsed)
```
Real game time + elapsed ticks. Helps identify time-dependent bugs.

#### 4. Player Inventory
```
**Inventory:** match, candle (2/10 slots used)
```
Current inventory state. Shows if issue is inventory-related.

#### 5. Recent Commands (Last 5)
```
**Recent Commands:**
1. look
2. examine drawer
3. open drawer
4. take matchbox
5. light candle
```

Location: `src/engine/loop/init.lua`

```lua
-- Track last N commands
context.command_history = {}
context.MAX_HISTORY = 5

function record_command(ctx, command)
  table.insert(ctx.command_history, command)
  if #ctx.command_history > ctx.MAX_HISTORY then
    table.remove(ctx.command_history, 1)
  end
end
```

#### 6. Last 50 Lines of Output
```
**Recent Output (Last 50 Lines):**
Stone walls surround you, bare and cold...
A four-poster bed dominates the room...
...
```

**NOT** just the last 20 commands. Include full game output. This captures:
- State of objects (lit/unlit, open/closed)
- Descriptive text (sensory details)
- Error messages (shows what player saw)

Location: `src/engine/display.lua`

```lua
-- Override print() to capture output
display.output_buffer = {}
display.MAX_BUFFER = 50

local original_print = print
function print(text)
  table.insert(display.output_buffer, text)
  if #display.output_buffer > display.MAX_BUFFER then
    table.remove(display.output_buffer, 1)
  end
  original_print(text)
end
```

#### 7. User Description
```
**What's Wrong?** (describe in your own words)
[Text area for player input]
```

Free-form text field. Players describe the bug in their own words.

### Implementation: `report bug` Command

**Handler location:** `src/engine/verbs/init.lua`

```lua
verbs["report"] = function(ctx, noun)
  if noun ~= "bug" then
    print("Did you mean 'report bug'?")
    return
  end
  
  -- Gather metadata
  local bug_report = {
    level = ctx.current_level.name,
    room = ctx.current_room.name,
    time = format_game_time(ctx),
    ticks = ctx.ticks_elapsed,
    inventory = format_inventory(ctx.player),
    recent_commands = ctx.command_history,
    recent_output = display.output_buffer,
    user_description = nil,  -- Filled by player input below
  }
  
  -- Show form to player
  print("=== BUG REPORT ===")
  print("Level: " .. bug_report.level)
  print("Room: " .. bug_report.room)
  print("Time: " .. bug_report.time .. " (" .. bug_report.ticks .. " ticks)")
  print("Inventory: " .. bug_report.inventory)
  print()
  print("Recent Commands:")
  for i, cmd in ipairs(bug_report.recent_commands) do
    print("  " .. i .. ". " .. cmd)
  end
  print()
  print("Recent Output (last 50 lines):")
  for _, line in ipairs(bug_report.recent_output) do
    print("  " .. line)
  end
  print()
  print("Describe the issue (type on the next line):")
  
  -- Wait for player input
  local description = io.read()
  bug_report.user_description = description
  
  -- Submit to bug tracker
  submit_bug_report(bug_report)
  
  print("Bug report submitted. Thank you!")
end
```

### Output Format (Markdown)

Bug reports should be formatted as **GitHub issue markdown** for easy parsing:

```markdown
## Bug Report

**Level:** Level 1: The Awakening  
**Room:** The Bedroom  
**Time:** 2:15 AM (10 ticks elapsed)  
**Inventory:** match, candle (2/10 slots)  

### Recent Commands
1. look
2. examine drawer
3. open drawer
4. take matchbox
5. light candle

### Recent Output
Stone walls surround you, bare and cold. A single window admits faint starlight...

### Description
When I light the candle, the room still says "You can't see anything" even though 
the candle is lit. The light description doesn't update.

---
*Submitted: 2026-03-24 14:15 UTC*
```

### Web Implementation

**HTML Form:**
```html
<div class="bug-report-modal">
  <h2>Report a Bug</h2>
  
  <div class="metadata">
    <div class="field">
      <label>Level:</label>
      <span id="level-name"></span>
    </div>
    <div class="field">
      <label>Room:</label>
      <span id="room-name"></span>
    </div>
    <div class="field">
      <label>Time:</label>
      <span id="game-time"></span>
    </div>
    <div class="field">
      <label>Inventory:</label>
      <span id="inventory"></span>
    </div>
  </div>
  
  <div class="section">
    <h3>Recent Commands</h3>
    <ul id="command-history"></ul>
  </div>
  
  <div class="section">
    <h3>Recent Output</h3>
    <div id="output-buffer" class="scrollable"></div>
  </div>
  
  <div class="section">
    <h3>Describe the Issue</h3>
    <textarea id="bug-description" placeholder="What went wrong?"></textarea>
  </div>
  
  <button onclick="submitBugReport()">Submit</button>
  <button onclick="closeBugReport()">Cancel</button>
</div>
```

**JavaScript:**
```javascript
function submitBugReport() {
  const report = {
    level: gameState.currentLevel.name,
    room: gameState.currentRoom.name,
    time: formatGameTime(gameState),
    inventory: formatInventory(gameState.player),
    recent_commands: gameState.commandHistory,
    recent_output: gameClient.outputBuffer,
    description: document.getElementById('bug-description').value,
  };
  
  // Send to backend
  fetch('/api/bug-reports', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(report)
  })
  .then(res => res.json())
  .then(data => {
    alert('Bug report submitted! Thank you.');
    closeBugReport();
  });
}
```

### Affected Code Locations

- **Engine:** `src/engine/verbs/init.lua` (report command)
- **Engine:** `src/engine/display.lua` (output buffer)
- **Engine:** `src/engine/loop/init.lua` (command history)
- **Web:** Bug report modal (HTML + CSS + JavaScript)
- **Web:** Backend API endpoint (`/api/bug-reports`)

---

## Additional UI Features

### Build Timestamp in Loading Messages

Display when the game was built during startup:

```
=== MMO: The Awakening ===
Loading... (build: 2026-03-24 14:15:32 UTC)
```

**Location:** `src/main.lua`

```lua
BUILD_TIME = os.date("%Y-%m-%d %H:%M:%S UTC", os.time())
print("Loading... (build: " .. BUILD_TIME .. ")")
```

### File Sizes in Loading Messages

Show asset loading progress:

```
Loading... (build: 2026-03-24 14:15:32 UTC)
  Engine: 245 KB
  Rooms: 128 KB
  Objects: 64 KB
  Parser: 35 KB
Total: 472 KB loaded
```

### Light Gray Status Messages

Boot-time status messages should use light gray to distinguish from game output:

```
┌─────────────────────────────────────────────────────┐
│ [Gray] Loading engine...                            │
│ [Gray] Initializing parser...                       │
│ [Gray] Loading rooms...                             │
│ [Gray] Game ready!                                  │
│                                                     │
│ [White] > _                                         │
└─────────────────────────────────────────────────────┘
```

**CSS:**
```css
.startup-message {
  color: #888;  /* Light gray */
  margin: 0.25em 0;
}

.startup-complete {
  color: #0f0;  /* Green */
  font-weight: bold;
}
```

### GoatCounter Analytics

Track player engagement:
- Session start/end
- Room visits
- Command frequency
- Bug reports submitted
- Play time

**Documentation:** See [docs/design/analytics.md](../../design/analytics.md) (TBD)

**Integration Point:** Web client JavaScript

```javascript
// Track page load
_paq.push(['trackPageView']);

// Track room visits
function enterRoom(room) {
  _paq.push(['trackEvent', 'Gameplay', 'RoomVisit', room.id]);
  // ... rest of room entry
}

// Track commands
function submitCommand(cmd) {
  _paq.push(['trackEvent', 'Gameplay', 'Command', cmd.verb]);
  // ... execute command
}

// Track bug reports
function submitBugReport(report) {
  _paq.push(['trackEvent', 'Gameplay', 'BugReport', report.room]);
  // ... submit report
}
```

---

## Summary of Changes

| Requirement | Component | Status | Priority |
|-------------|-----------|--------|----------|
| Room titles bold | Web (CSS) + CLI (ANSI) | TBD | High |
| Short descriptions on revisit | Engine (visited_rooms table) | TBD | High |
| Command input styling | Web (CSS) + CLI (ANSI) | TBD | Medium |
| Bug report metadata | Engine (report verb) + Web | TBD | Medium |
| Build timestamp | Main | TBD | Low |
| File sizes in loading | Main | TBD | Low |
| Gray status messages | Web (CSS) | TBD | Low |
| GoatCounter analytics | Web (JavaScript) | TBD | Medium |

---

## Testing Checklist

- [ ] Room titles display in bold on first visit
- [ ] Room titles display in bold on revisit (if shown)
- [ ] Short descriptions appear on revisit (not full description)
- [ ] Explicit `look` command always shows full description
- [ ] Visited rooms persist across sessions (web localStorage)
- [ ] Player input displays in cyan with `>` prompt (web)
- [ ] Player input displays in ANSI cyan with `>` prompt (CLI)
- [ ] `report bug` command captures all metadata fields
- [ ] Bug report includes last 50 lines of output (not just 20 commands)
- [ ] Bug report submits as formatted markdown
- [ ] Build timestamp displays in loading messages
- [ ] File sizes display during asset loading
- [ ] Status messages appear in light gray
- [ ] GoatCounter events fire on room visit, command, bug report

---

## Related Systems

- **Text Presentation:** [text-presentation.md](text-presentation.md)
- **Verb System:** [../../design/verb-system.md](../../design/verb-system.md)
- **Parser Pipeline:** [parser-overview.md](parser-overview.md)
- **Analytics (Design Doc):** [../../design/analytics.md](../../design/analytics.md) (TBD)

---

**END OF WEB PRESENTATION**  
*Captured from Wayne's play testing sessions on 2026-03-24.*
