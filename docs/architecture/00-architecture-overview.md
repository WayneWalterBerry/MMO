# Architecture Overview

**Version:** 1.2  
**Last Updated:** 2026-03-22
**Author:** Brockman (Documentation)  
**Purpose:** High-level map of how all systems fit together. Detailed specs are in linked docs.

---

## 🏛️ Core Principles

**See [Core Architecture Principles](core-principles.md) for the 7 foundational principles governing the object system:**
1. Code-Derived Mutable Objects
2. Base Objects → Object Instances
3. Objects Have FSM; Instances Know Their State
4. Composite Objects Encapsulate Inner Objects
5. Multiple Instances Per Base Object; Each Instance Has a Unique GUID
6. Objects Exist in Sensory Space; State Determines Perception
7. Objects Exist in Spatial Relationships

---

## The System Stack

### Layer 1: Engine Core

**Runtime:** Lua (5.4)  
**Entry Point:** `src/main.lua`

The engine is a **self-modifying Lua interpreter**. All game state is represented as Lua code/data. When the player acts, the engine rewrites the object definitions to reflect new state.

**Core Files:**
- `src/engine/loop/init.lua` — Main game loop (read command → parse → verb dispatch → tick → render)
- `src/engine/parser/init.lua` — Tier 1 (exact) + Tier 2 (phrase similarity) parser
- `src/engine/verbs/init.lua` — Verb handlers (31 verbs, pluggable)
- `src/engine/registry/init.lua` — Object registry (load, store, query)
- `src/engine/loader/init.lua` — Object template resolution + inheritance
- `src/engine/containment/init.lua` — Containment validation (5-layer checks)
- `src/engine/mutation/init.lua` — Code rewrite engine (object state transitions)

---

### Layer 2: Parser System

**Design:** Three-tier command parsing.

#### Tier 1: Exact Dispatch
- Input → verb alias lookup → handler
- **Cost:** Zero tokens, instant
- **Examples:** "look", "l", "x chair"
- **Success Rate:** ~70% of typical player input

#### Tier 2: Phrase Similarity
- If Tier 1 misses, compute Jaccard token overlap between input and phrase dictionary
- Threshold: 0.40 (tunable)
- **Cost:** Zero tokens, ~5ms per lookup
- **Examples:** "examine the chair" → matches "x", "look at chair" → matches "examine"
- **Success Rate:** ~90% of player input

#### Tier 3: NOT YET IMPLEMENTED
- If Tier 2 misses, **Goal-Oriented Action Planning (GOAP) backward-chaining parser** engages
- Detects missing prerequisites: "Light candle" fails → planner checks candle's prerequisite table
- Builds action chain: [open matchbox, get match, strike match, light candle]
- Executes chain step-by-step through Tier 1
- Stops on first failure
- **Cost:** ~125 object scans per plan, sub-millisecond in Lua
- **Design:** Prerequisite chains object-owned (not centralized). Each transition can declare prerequisites.
- **Performance:** Estimated 3 days of implementation (half day planning, half day content tagging, 1 day tests)

**Key Insight:** Tier 3 is a recovery mechanism, not mind-reading. It asks: "The player wanted X. X failed because Y is missing. Can I satisfy Y?" It does NOT ask: "What might they want to do next?"

**Example:**
```lua
-- User types: "light the candle"
-- Tier 1 routes to LIGHT handler
-- Handler finds: no fire_source in inventory
-- Tier 3 engages:
--   Check candle's prerequisites: needs fire_source
--   Search for fire_source providers: match-1 (state: unlit)
--   Plan needed: get match, strike match
--   Check match's prerequisites: needs holding match (in inventory)
--   Subplan: open matchbox, get match
--   Execute: [open matchbox → get match → strike match → light candle]
--   Player sees: rapid narration of all steps
-- Result: candle is lit (player achieved their goal in one command)
```

---

### Layer 2.5: Terminal UI (Split-Screen Display)

**Design:** Classic IF split-screen: output window (scrollable, top), status bar (top line), input line (bottom).

**Components:**
- **Output Window:** Renders all game output (action results, sensory descriptions). Scrollback buffer holds 500 lines. User can scroll up/down with `/up`, `/down`, `/bottom` commands.
- **Status Bar:** Single-line display at screen top. Left-justified (player name, location) / right-justified (light state, health, etc.). Updates per turn.
- **Input Line:** Bottom line where player types commands. Cursor visible. Separate from output — no game output mixes with user input.
- **ANSI Escape Codes:** Pure Lua implementation, no C libraries. Windows-compatible. Uses scroll regions to isolate status bar.

**Implementation:**
- `src/engine/ui/init.lua` — Terminal UI module
- `display.ui` hook intercepts all `print()` calls
- `--no-ui` flag for fallback to simple REPL (test mode, piped input)

**See Also:** Detailed design in (future: `docs/design/terminal-ui.md`)

---

### Layer 2.75: Timed Events & Ambient Output

**Design:** Objects declare embedded timers that emit ambient events to the output window.

**Types:**
- **One-shot timers:** Fire once after N time units (time bomb, timed door unlock)
- **Recurring timers:** Fire repeatedly every N time units (clock chime, dripping water, creaking floorboards)

**Example (Wall Clock in Bedroom):**
```lua
timers = {
  {
    name = "hourly_chime",
    interval = 3600,  -- 1 in-game hour in seconds
    recurring = true,
    message = function(self, now)
      local hour = math.floor((now % 86400) / 3600)
      local chime_count = (hour == 0) and 12 or (hour % 12)
      return ("The clock chimed %d time%s."):format(chime_count, chime_count == 1 and "" or "s")
    end
  }
}
```

**Output:** Emitted regardless of player action. Creates sense of world simulation.

---

### Layer 3: Verb Dispatch

**Count:** 31 verbs across 4 categories

#### Navigation & Perception (7)
LOOK, EXAMINE, FEEL, SMELL, TASTE, LISTEN, READ

#### Inventory (6)
TAKE, DROP, INVENTORY, WEAR, PUT, OPEN, CLOSE

#### Object Interaction (8)
LIGHT, STRIKE, EXTINGUISH, BREAK, TEAR, WRITE, CUT, SEW, PRICK

#### Movement (6+)
NORTH, SOUTH, EAST, WEST, UP, DOWN, GO, ENTER, EXIT, DESCEND, CLIMB (all route through unified `handle_movement`)

#### Meta (2)
HELP, QUIT

**Architecture: Generic Handlers + Object-Owned FSM**

Verb handlers in `src/engine/verbs/init.lua` are generic infrastructure — they dispatch commands but contain NO object-specific logic. 

Example: The OPEN handler doesn't have special cases for "wooden doors," "drawers," "cursed gates," or "time-locked safes." Instead, each object declares its own transitions and prerequisites in its FSM metadata:

```lua
-- In src/meta/world/bedroom-door.lua
mutations = {
    open = {
        requires_tool = "key",       -- Only object knows it needs a key
        requires_skill = nil,
        becomes = "bedroom-door-open",
        message = "The door swings inward.",
        timed_revert = 30            -- Door auto-closes after 30 ticks
    }
}
```

When the OPEN handler runs:
1. Engine finds the target object (bedroom-door)
2. Looks up the object's transition rules (mutations.open)
3. Checks prerequisites from the **object's FSM**, not engine code
4. Executes the mutation (replaces object definition)
5. Returns the object's message

**Result:** The engine is truly generic. Objects own their state machines. This enables:
- Cursed interactions (object FSM returns nonsense messages)
- Room-specific verb behavior (via object-specific mutations)
- Dynamic verb adaptation (object mutations change based on universe state)
- No engine changes needed for new object types

**Movement Handler Unification:**
- All movement verbs route through `handle_movement(ctx, direction)`
- Handles: direction alias resolution, keyword search, exit accessibility checks (locked doors)
- Room transition: updates `ctx.current_room`, loads room contents, resets view

**Verb Handler Pattern:**
```lua
verb.LIGHT = function(ctx, target, tool)
    -- 1. Resolve target object
    -- 2. Check for requires_tool capability
    -- 3. Check for success conditions (light source present, object lightable)
    -- 4. Execute mutation (swap object definition)
    -- 5. Print message
    -- 6. Return success/fail
end
```

**Tool Resolution:** Verbs can request capabilities (`requires_tool`). Engine searches player inventory for matching `provides_tool`. First match wins.

---

### Layer 2.5.5: Multi-Room System

**Design:** World is multi-room. All rooms load at startup. Objects persist across room boundaries.

**Architecture:**
- **Room Registry:** `context.rooms = { bedroom = {...}, cellar = {...}, ... }`
- **Object Registry:** Single shared registry across all rooms
- **Room Contents:** Each room has `room.contents` array (which objects are in this room)
- **Player Location:** `ctx.current_room` tracks current room ID

**Loading:**
- Startup: Load all `.lua` files from `src/meta/world/`
- Each room returns: `{ id, name, description, contents, ...}`
- Rooms instantiated into `context.rooms` table

**Movement:**
- Player types: "go north"
- `handle_movement` looks up north exit in current room
- Checks accessibility (locked door? key in inventory?)
- Transitions player to new room: `ctx.current_room = "cellar"`
- Resets view: shows room description, contents

**Object Persistence:**
- Drop item in bedroom → item stays in registry with `location = "bedroom"`
- Move to cellar → return to bedroom → item still there
- Objects tick only in current room + player hands (prevents resource burn in other rooms)

---

### Layer 4: Object System

**Architecture:** Single Lua file per logical object (including all states/parts).

#### Object Definition Structure
```lua
{
    id = "candle",
    name = "A tapered candle",
    size = 1,
    weight = 0.1,
    template = "small-item",           -- Inherit defaults from template
    provides_tool = "fire_source",      -- Optional: what capability does this provide?
    casts_light = true,                 -- Optional: does this emit light?
    on_look = function(self) return "..." end,
    on_feel = "Smooth wax.",
    on_smell = "Pleasant vanilla scent.",
    mutations = {
        extinguish = {
            becomes = "candle",         -- Return to unlit state
            message = "The flame goes out.",
        }
    }
}
```

#### Object States via Mutations
- **Match:** unlit → lit (30 ticks) → spent
- **Candle:** unlit → lit (100 ticks) → stub (20 ticks) → spent
- **Nightstand:** closed → open (reversible, container access gate)
- **Paper:** blank → paper-with-writing (one-way, text embedded in definition)

**Code Rewrite Model:** When a mutation triggers, the entire object definition is replaced. Old definition removed from registry, new one inserted. No separate state flags.

#### Composite Objects
- **Single file:** nightstand.lua contains nightstand + drawer definitions
- **Detachable parts:** drawer has factory function; can detach to become independent
- **FSM state names:** `closed_with_drawer`, `closed_without_drawer` (reflect component presence)
- **Part reversibility:** Design choice per part (drawer reversible, cork irreversible)

#### Object Templates
**Single-level inheritance** (no deep chains):
- `sheet.lua` — fabric/cloth family
- `furniture.lua` — heavy immovable objects
- `container.lua` — bags, boxes, chests
- `small-item.lua` — tiny portable items

Instance properties override template properties. Loader uses deep merge.

---

### Layer 5: Containment System

**5-Layer Validation Chain:**

1. **Layer 1:** Is target a container? (has `container` field)
2. **Layer 2:** Does item fit physically? (size tier ≤ max_item_size)
3. **Layer 3:** Is there room left? (total_weight ≤ weight_capacity)
4. **Layer 4:** Category accept/reject? (is item in allowed categories?)
5. **Layer 5:** Weight limit? (item weight + contents < capacity)

**Multi-Surface Support:**
```lua
container = {
    surfaces = {
        top = { capacity = 3, weight_capacity = 20, max_item_size = 3 },
        inside = { capacity = 5, weight_capacity = 15, max_item_size = 2, accessible = false }
    }
}
```

**Key Properties:**
- `weight` (number) — object's own weight
- `weight_capacity` (number) — how much stuff can it hold?
- `size` (1-6) — how large is this object physically?
- `max_item_size` (1-6) — what's the biggest item that fits through opening?
- `categories` (table) — what types does this belong to? (e.g., "book", "clothing", "tool")

---

### Layer 6: Player Model

**Inventory Structure:**
```lua
player = {
    hands = { left = nil, right = nil },     -- What's held in hands?
    worn = {                                  -- What's worn?
        head = nil,
        torso = nil,
        feet = nil,
        -- ... other body slots
    },
    skills = {
        lockpicking = false,
        sewing = false,
        -- ... learned skills
    }
}
```

**Hand Slots:**
- Player has 2 hands total
- Objects declare `hands_required` (0, 1, or 2)
- Heavy/large items tie up both hands
- Worn items don't consume hand slots

**Wearable System:**
- Each worn item occupies one body slot
- Wearables can be containers (backpack on back)
- Some wearables block vision (sack on head)
- Slot conflicts prevent simultaneous wear

**Skills:**
- Binary (have it or don't)
- Gates certain verbs (SEW requires sewing skill)
- Unlocks tool combinations (pin → lock pick WITH skill)
- Discovered through gameplay (find manual, practice, NPC teaching, puzzle solve)

---

### Layer 7: World State & Time

**Game Clock:**
- Real-time OS time × 24 = game seconds
- Always accurate, even between commands
- 24-hour cycle: 6 AM (dawn) to 6 PM (dusk) to 2 AM (night)
- Used for light/dark calculations

**Game State:**
- Collection of all object definitions (mutable Lua code)
- Player state (inventory, worn, skills, location)
- Exit state (locks, open/closed doors)
- Room visibility (light/dark, what's visible)

**Persistence (Cloud):**
- Mutated state persists to cloud storage
- Enables cross-device play
- Supports analytics on universe evolution

---

### Layer 8: Light & Dark System

**Light Sources:**
- Objects with `casts_light = true` emit light (lit candle, torch)
- Room-level check: if any object in room casts light, room is bright
- Daylight: outside areas + time 6 AM to 6 PM + `allows_daylight = true`

**Sensory in Darkness:**
- LOOK requires light (fails with "You see nothing in the darkness")
- FEEL / SMELL / TASTE / LISTEN work in darkness (no light needed)
- EXAMINE has light requirement (only in bright rooms)

**Vision Blocking:**
- Wearables with `blocks_vision = true` (sack, blindfold) disable LOOK
- Even in bright room, blindness overrides light
- Becomes a puzzle element (can't see, but can FEEL/SMELL)

---

### Layer 9: Consumables & Temporal Effects

**Event-Driven Ticks:**
- 1 tick = 1 player command
- Ticks happen BEFORE verb execution (fair resource consumption)
- Each object tracks remaining ticks in current state

**Match Lifecycle:**
1. Unlit (any number of ticks)
2. Strike on matchbox → mutates to `match-lit`
3. Lit (30 ticks, warning at 5 ticks)
4. Auto-transition to `match-spent` (terminal)
5. Spent (can't be relit)

**Candle Lifecycle:**
1. Unlit (any number of ticks)
2. Light with fire source → mutates to `candle-lit`
3. Lit (100 ticks, warning at 10 ticks)
4. Auto-transition to `candle-stub` (medium burn)
5. Stub (20 ticks, warning at 5 ticks — urgent)
6. Auto-transition to `candle-spent` (terminal)
7. Spent (no light, can't be relit)

**Terminal States:**
- Once spent, object cannot transition back to any active state
- "Spent" means destroyed/unusable for puzzle purposes
- Prevents infinite resource loops

---

### Layer 10: Game Loop

**Each Turn:**

```
1. [Tick] Auto-advance object timers (consumables burn, state transitions)
2. [Input] Read command from player
3. [Parse] Tier 1 exact lookup → Tier 2 phrase similarity
4. [Dispatch] Route to appropriate verb handler
5. [Execute] Verb mutates objects, checks conditions
6. [Render] Print output (success/fail message + sensory feedback)
7. [Check] If ctx.game_over, break loop and prompt "Play again?"
8. [Repeat]
```

**Context Object (passed to all verbs):**
```lua
ctx = {
    player = { ... },           -- Current player state
    registry = { ... },         -- All object definitions
    current_room = "bedroom",   -- Player location
    game_over = false,          -- Exit flag
}
```

---

## Data Flow: Command → Verb → Object → FSM → Response

```
Player Types "light candle"
    ↓
Parser (Tier 1): "light" exact match? No.
    ↓
Parser (Tier 2): Phrase similarity to "light"? Yes (score 0.85)
    ↓
Verb Handler: verb.LIGHT(ctx, "candle", nil)
    ↓
Engine: Find candle in registry
    ↓
Check: Mutations.light requires_tool = "fire_source"
    ↓
Search: Player inventory for provides_tool = "fire_source"
    ↓
Result: No fire_source found
    ↓
[NEW: Tier 3 Goal Decomposition Engages]
    ↓
Planner: Query candle's prerequisites
    ↓
Found: prerequisites = [{ need = "fire_source", sources = [{ object = "match", state = "lit" }] }]
    ↓
Backward Chaining: Plan to light a match
    ↓
Check match's prerequisites: needs holding match, has_striker surface
    ↓
Plan: [open matchbox → get match → strike match → light candle]
    ↓
Execute Each Step via Tier 1:
  1. OPEN matchbox → success
  2. GET match → success
  3. STRIKE match → success (match-lit obtained)
  4. LIGHT candle (now fire_source available) → success
    ↓
Output: "You slide the matchbox tray open. You take a match and strike it against 
the strip — it catches with a hiss. The wick catches the flame and curls to life, 
casting a warm amber glow."
    ↓
Game State: candle-lit, match-lit, matchbox-open
    ↓
Continue game loop
```

**Without Tier 3 (old flow):**
```
Player Types "light candle"
  → Tier 1 + Tier 2 route to LIGHT handler
  → Handler finds no fire_source
  → Failure: "You have nothing to light it with."
  → Player must manually: open matchbox → take match → strike match → light candle (4 more commands)
```

---

## Integration Points

### Verb + Object
- Verbs declare requirements: `requires_tool`, `requires_skill`
- Objects declare capabilities: `provides_tool`, `provides_skill`
- Engine matches requirements to capabilities

### Parser + Verb
- Parser returns (verb_id, target_noun, optional_tool_noun)
- Verb handler dispatches based on verb_id
- Target and tool resolved from player location and inventory

### FSM + Mutation
- FSM state names match file naming: `candle`, `candle-lit`, `candle-spent`
- Mutation triggers code swap (old definition → new definition)
- Auto-transitions happen before verb execution

### Container + Inventory
- Player inventory is a container (special: no gravity, tied to player body)
- Worn items are tracked separately (don't consume hand slots)
- Hand slots limited (0/1/2 hands required per object)

### Light + Rendering
- Room renders based on light state (bright/dark)
- Sensory descriptions gated by light/dark
- Wearables can override light state (vision blocking)

### Skills + Verbs
- Verbs gate on `required_skill`
- Player learns skills through gameplay
- Skills unlock tool combinations and new mutations

---

## Design Principles

1. **Code IS State** — No separate flag system. Object definitions are mutable and definitive.
2. **Capability Matching** — Tools provide capabilities; verbs require them. Extensible beyond specific items.
3. **5-Layer Containment** — Systematic validation prevents "put desk in elephant" nonsense.
4. **Event-Driven Time** — Fair resource consumption; ticks before verbs; matches burn urgently.
5. **Sensory Over Visual** — Darkness forces FEEL/SMELL/LISTEN; creates puzzle depth.
6. **Single-File Composites** — All parts of an object live in one file; FSM names reflect states.
7. **Tier 1 + 2 Parser** — Fast exact lookup (70%), graceful phrase similarity (20%), visible fail (10%).
8. **Cloud Persistence** — Universe state lives in cloud; players resume cross-device.
9. **Player-Per-Universe** — Each player has their own world; opt-in multi-player.
10. **LLM at Build Time** — Content generated once at build time; procedurally varied per player; no per-interaction tokens.

---

## Cross-References

- **Parser Details:** `verb-system.md`, `command-variation-matrix.md`
- **Goal-Oriented Parser:** `intelligent-parser.md` (existing), `docs/design/goal-decomposition.md` (planned)
- **Object Details:** `fsm-object-lifecycle.md`, `composite-objects.md`
- **Container Details:** `containment-constraints.md`
- **Wearable Details:** `wearable-system.md`
- **Verb Reference:** `verb-system.md`
- **Tool Patterns:** `tool-objects.md`
- **Skills Design:** `player-skills.md`
- **Room Design:** `dynamic-room-descriptions.md`, `room-exits.md`, `spatial-system.md`
- **Terminal UI:** `docs/design/terminal-ui.md` (planned)
- **Timed Events:** `docs/design/timed-events.md` (planned)
- **Architecture Decisions:** `architecture-decisions.md`, `.squad/decisions.md`

---

## Future Expansion Points

- **Procedural Variation:** Seeded universe templates for replay differentiation
- **Multiverse Merging:** Double-opt-in player universe merges (post-MVP)
- **NPC AI:** Static → Reactive → Proactive (Phase 2+)
- **Combat System:** Turn-based verb system (Phase 2+)
- **Magic System:** High-level verbs triggering LLM effects (Phase 3+)
- **More Verbs:** Start with 31; extensible for custom puzzles
- **ONNX Runtime:** Real vector embeddings in browser (Phase 2)
- **App Store:** Capacitor wrapping for iOS/Android (Phase 3+)

