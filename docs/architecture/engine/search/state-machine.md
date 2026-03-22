# Search State Machine

**Module:** `src/engine/search/`  
**Owner:** Bart (Architect)  
**Status:** Design Phase  

## Overview

The search system operates as a **state machine** that processes one step per game turn. The game loop calls `search.tick()` each turn, and the search module manages all state transitions internally.

**Key Principle:** Search is interruptible — any new player command immediately aborts the current search and transitions back to idle.

---

## State Diagram

```
                    ┌─────────────────────────────────┐
                    │                                 │
                    ▼                                 │
              ┌──────────┐                           │
         ┌───│   IDLE   │◄──────────────────┐       │
         │    └──────────┘                   │       │
         │         │                         │       │
         │         │ search() or find()      │       │
         │         │ called                  │       │
         │         ▼                         │       │
         │    ┌──────────────┐               │       │
         │    │ INITIALIZING │               │       │
         │    └──────────────┘               │       │
         │         │                         │       │
         │         │ queue built            │       │
         │         ▼                         │       │
         │    ┌──────────────┐               │       │
         └───►│  SEARCHING   │               │       │
              └──────────────┘               │       │
                   │                         │       │
       ┌───────────┼───────────┐             │       │
       │           │           │             │       │
       │ tick()    │           │ abort()     │       │
       │           │           │ (new cmd)   │       │
       ▼           ▼           ▼             │       │
  ┌────────┐  ┌────────┐  ┌──────────────┐  │       │
  │  STEP  │  │ FOUND  │  │ INTERRUPTED  │──┘       │
  └────────┘  └────────┘  └──────────────┘          │
       │           │                                 │
       │           │                                 │
       │           └─────────────────────────────────┘
       │                                             
       │ queue exhausted?                           
       ▼                                             
  ┌──────────────┐                                   
  │  EXHAUSTED   │───────────────────────────────────┘
  └──────────────┘
```

---

## States

### IDLE
**Description:** No search is active. Engine is waiting for a search/find command.

**Properties:**
- `_state.active = false`
- No queue exists
- No narrative output

**Entry Conditions:**
- System startup
- Search completion (FOUND, EXHAUSTED, INTERRUPTED)

**Exit Conditions:**
- `search()` or `find()` called by verb handler

---

### INITIALIZING
**Description:** Building the search queue based on room proximity list and parameters.

**Properties:**
- `_state.active = true`
- `_state.target` and `_state.scope` set
- Queue being built

**Actions:**
1. Get current room
2. Build proximity-ordered queue via `traverse.build_queue()`
3. Set `current_index = 1`
4. Set `current_step = 0`
5. Output initial message: "You begin searching..."

**Exit Conditions:**
- Queue built → transition to SEARCHING

**Duration:** Instantaneous (same turn as command)

---

### SEARCHING
**Description:** Active search in progress. Waiting for game loop to call `tick()`.

**Properties:**
- `_state.active = true`
- Queue populated
- `current_index` points to next object

**Actions:**
- Wait for game loop to call `tick()`

**Exit Conditions:**
- `tick()` called → transition to STEP
- `abort()` called (new command) → transition to INTERRUPTED

**Duration:** Between turns (waiting for next tick)

---

### STEP
**Description:** Processing one step of the search (examining one object).

**Properties:**
- Examining `queue[current_index]`
- Turn cost applied (1 turn)
- Injuries tick
- Clock advances

**Actions:**
1. Get current object from queue
2. Check if it's a container:
   - If locked → generate "locked" narrative, skip
   - If unlocked and closed → open it via `containers.open()`
3. Check object's surfaces and contents
4. If targeted search:
   - Check if target found
   - If yes → transition to FOUND
5. Generate step narrative via `narrator.step_narrative()`
6. Output narrative
7. Mark object as searched in search memory
8. Increment `current_index`
9. Increment `current_step`
10. Apply turn cost (1 turn)

**Exit Conditions:**
- Target found → transition to FOUND
- Queue exhausted (`current_index > #queue`) → transition to EXHAUSTED
- Not done → transition back to SEARCHING

**Duration:** 1 game turn

---

### FOUND
**Description:** Target has been found. Search complete.

**Properties:**
- `_state.active = false` (about to be)
- Target object identified

**Actions:**
1. Generate completion narrative: "You have found: {target}."
2. Set context: `ctx.last_noun = target_object.id`
3. Add to `_state.found_items`
4. Output completion message
5. Clean up state
6. Transition to IDLE

**Exit Conditions:**
- Immediately transitions to IDLE after actions complete

**Duration:** End of current turn

**Context Setting:**
```lua
-- After found
ctx.last_noun = target_object.id
-- Enables follow-up commands:
-- > find matchbox
-- > take it  ← "it" resolves to matchbox
-- > light it ← still resolves to matchbox
```

---

### EXHAUSTED
**Description:** Search completed but target not found (or undirected search finished).

**Properties:**
- `_state.active = false` (about to be)
- Queue fully traversed

**Actions:**
1. If targeted search:
   - Generate failure narrative: "You finish searching. No {target} found."
2. If undirected sweep:
   - Generate summary: "You finish searching the room."
   - List discovered items (if any)
3. Clean up state
4. Transition to IDLE

**Exit Conditions:**
- Immediately transitions to IDLE after actions complete

**Duration:** End of current turn

---

### INTERRUPTED
**Description:** Player issued a new command mid-search. Abort cleanly.

**Properties:**
- `_state.active = false` (immediately)
- Turn cost applied only for completed steps

**Actions:**
1. Output interruption message: "[Search interrupted]"
2. Apply turn cost for `current_step` (steps already taken)
3. Clean up state (clear queue, reset counters)
4. Transition to IDLE
5. Allow new command to process

**Exit Conditions:**
- Immediately transitions to IDLE

**Duration:** Instantaneous (same turn as interruption)

**Design Note:** Only completed steps cost turns. If interrupted during step 3, player pays for 2 completed steps, not 3.

---

## State Transitions

### Transition Table

| From State    | Event               | To State     | Turn Cost | Notes |
|---------------|---------------------|--------------|-----------|-------|
| IDLE          | `search()` called   | INITIALIZING | 0         | Same turn |
| IDLE          | `find()` called     | INITIALIZING | 0         | Same turn |
| INITIALIZING  | Queue built         | SEARCHING    | 0         | Same turn |
| SEARCHING     | `tick()` called     | STEP         | 1         | Each step = 1 turn |
| STEP          | Target found        | FOUND        | 0         | Completes this turn |
| STEP          | Queue exhausted     | EXHAUSTED    | 0         | Completes this turn |
| STEP          | More to search      | SEARCHING    | 0         | Continue next turn |
| SEARCHING     | New command         | INTERRUPTED  | 0         | Immediate abort |
| STEP          | New command         | INTERRUPTED  | 0         | Immediate abort |
| FOUND         | (automatic)         | IDLE         | 0         | Same turn |
| EXHAUSTED     | (automatic)         | IDLE         | 0         | Same turn |
| INTERRUPTED   | (automatic)         | IDLE         | 0         | Same turn |

---

## Game Loop Integration

### Loop Structure

```lua
-- In loop/init.lua
function loop.tick(ctx)
  -- 1. Check for player input
  local input = io.read()
  
  -- 2. If search is active and new input arrives, interrupt it
  if search.is_searching() and input then
    search.abort(ctx)
    -- Fall through to process new command
  end
  
  -- 3. Process search step if active and no new input
  if search.is_searching() and not input then
    local continue = search.tick(ctx)
    if not continue then
      -- Search finished this turn
      return
    end
  end
  
  -- 4. Process new command if present
  if input then
    local verb, args = parser.parse(input)
    handlers[verb](ctx, args)
  end
  
  -- 5. Tick injuries, clock, FSMs, etc.
  injuries.tick(ctx)
  time.tick(ctx)
  fsm.tick_all(ctx)
end
```

### Interruption Detection

The loop checks for new player input **before** calling `search.tick()`. If input exists and search is active:
1. Call `search.abort(ctx)` immediately
2. Search transitions to INTERRUPTED → IDLE
3. New command processes normally

---

## State Data Structure

```lua
-- In init.lua
_state = {
  active = false,              -- Is search currently running?
  target = nil,                -- What we're looking for (nil = sweep)
  scope = nil,                 -- Where we're searching (nil = full room)
  queue = {},                  -- Ordered list of {object_id, depth, is_container}
  current_index = 1,           -- Current position in queue
  current_step = 0,            -- Number of steps taken (turn counter)
  found_items = {},            -- Objects discovered so far
  room_id = nil,               -- Which room is being searched
  is_goal_search = false,      -- Goal-oriented search?
  goal_type = nil,             -- "action" | "property" (if goal search)
  goal_value = nil,            -- e.g., "light" | "sharp" (if goal search)
}
```

### State Cleanup

When transitioning to IDLE, all state is reset:

```lua
function _reset_state()
  _state.active = false
  _state.target = nil
  _state.scope = nil
  _state.queue = {}
  _state.current_index = 1
  _state.current_step = 0
  _state.found_items = {}
  _state.room_id = nil
  _state.is_goal_search = false
  _state.goal_type = nil
  _state.goal_value = nil
end
```

---

## Example: Full Search Workflow

### Scenario: "search for matchbox" in dark bedroom

**Turn 0: IDLE → INITIALIZING → SEARCHING**
```
> search for matchbox
You begin searching for the matchbox...

[State: INITIALIZING]
- Build queue: [bed, nightstand_top, nightstand_drawer, vanity, wardrobe]
- target = "matchbox"
- current_step = 0

[State: SEARCHING]
- Waiting for first tick
```

**Turn 1: SEARCHING → STEP → SEARCHING**
```
[State: STEP]
- Examine bed
- Not a container
- No matchbox found
- current_step = 1

[Output:]
You feel the edge of a large four-poster bed. Nothing there.

[State: SEARCHING]
- current_index = 2 (nightstand_top next)
```

**Turn 2: SEARCHING → STEP → SEARCHING**
```
[State: STEP]
- Examine nightstand_top (surface)
- Check for matchbox
- Not found on surface
- current_step = 2

[Output:]
You reach out to a small nightstand. Nothing on top.

[State: SEARCHING]
- current_index = 3 (nightstand_drawer next)
```

**Turn 3: SEARCHING → STEP → FOUND → IDLE**
```
[State: STEP]
- Examine nightstand_drawer (container)
- is_locked = false, is_open = false
- Call containers.open()
- Check contents: ["matchbox", "candle"]
- Target found!
- current_step = 3

[Output:]
It has a drawer... you pull it open.
Inside, your fingers find: a small matchbox.

You have found: a small matchbox.

[State: FOUND]
- ctx.last_noun = "matchbox"
- Output completion message

[State: IDLE]
- _reset_state() called
- Ready for next command
```

**Result:**
- 3 turns elapsed
- Injuries ticked 3 times
- Clock advanced 3 times
- Nightstand drawer now permanently open
- Player can now type "take it" or "pick up" (references matchbox)

---

## Example: Interrupted Search

**Turn 0-1: Start search**
```
> search for torch
You begin searching for the torch...

[Turn 1: STEP]
You feel the edge of a bed — nothing there.
```

**Turn 2: Player interrupts**
```
> look
[Search interrupted]

[State: INTERRUPTED]
- current_step = 1 (only completed step 1)
- Apply turn cost: 1 turn
- _reset_state()
- Transition to IDLE

[State: IDLE]
- Process "look" command normally
```

**Result:**
- Only 1 turn elapsed (1 completed step)
- Injuries ticked 1 time
- Clock advanced 1 time
- Search memory: bed marked as searched
- Player in full control again

---

## Turn Cost Accounting

### During Normal Search
Each STEP state costs **1 turn**:
- Injuries tick
- Clock advances
- NPCs act (if implemented)
- Weather changes (if implemented)

### During Interruption
Only **completed steps** cost turns:
- If interrupted during step 3, pay for steps 1-2 (not 3)
- Step currently being processed is NOT charged

### On Completion
No additional turn cost beyond steps taken:
- FOUND state: 0 turns
- EXHAUSTED state: 0 turns
- Turn cost = number of STEP states entered

---

## State Persistence

### Within a Session
Search state is volatile — stored in module-local `_state` variable:
- Lives only while game is running
- Cleared on game exit

### Across Sessions
Search state is NOT persisted:
- Cannot save mid-search
- If player saves during search, search is aborted
- On load, system starts in IDLE

### Search Memory Persistence
**Search memory** (what's been searched) IS persisted:
- Stored on room object: `room.searched_objects = {bed = true, nightstand = true}`
- Saved to disk with room state
- Allows "you've already searched here" optimization

---

## Error Handling

### Invalid State Transitions
If an unexpected state transition is attempted:
```lua
function _transition(from_state, to_state)
  if not _valid_transition(from_state, to_state) then
    error("Invalid search state transition: " .. from_state .. " -> " .. to_state)
  end
  _state.current = to_state
end
```

### Empty Queue
If queue is empty after initialization:
```lua
-- In INITIALIZING state
if #queue == 0 then
  output("There's nothing to search here.")
  _transition("INITIALIZING", "IDLE")
  return
end
```

### Circular Containment
Traverse depth is limited to prevent infinite loops:
```lua
-- In traverse.expand_object()
if depth > 5 then
  warn("Max search depth exceeded for " .. object.id)
  return {}  -- Stop recursion
end
```

---

## Testing Requirements

### State Transition Tests
- `test_idle_to_searching` — Normal search start
- `test_searching_to_found` — Target found mid-search
- `test_searching_to_exhausted` — Queue fully traversed
- `test_searching_to_interrupted` — Player aborts mid-search
- `test_interrupted_turn_cost` — Only completed steps charged

### Turn Cost Tests
- `test_turn_cost_per_step` — Each step = 1 turn
- `test_injury_ticking` — Injuries worsen during search
- `test_clock_advance` — Time moves forward
- `test_interrupted_partial_cost` — Partial turn cost on abort

### Context Setting Tests
- `test_found_sets_context` — last_noun set correctly
- `test_context_persists` — Context survives until next noun
- `test_pronoun_resolution` — "it" resolves to found object

### Edge Case Tests
- `test_empty_room_search` — No objects to search
- `test_all_locked_containers` — Can't open anything
- `test_rapid_commands` — Multiple searches in sequence
- `test_search_during_search` — Start new search mid-search (should abort first)
