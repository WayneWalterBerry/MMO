# Player Movement

**Version:** 1.0  
**Extracted from:** 00-architecture-overview.md  
**Purpose:** Specify how player movement works, exit systems, and location tracking.

---

## Overview

Player movement is the primary way players navigate between rooms. The movement system is unified through a single `handle_movement` handler that routes all directional verbs.

---

## Movement Verbs

**Supported Directions:** NORTH, SOUTH, EAST, WEST, UP, DOWN, GO, ENTER, EXIT, DESCEND, CLIMB

**Routing:** All movement verbs route through unified `handle_movement(ctx, direction)`

**Handler Responsibilities:**
- Direction alias resolution (GO → direction lookup)
- Keyword search (ENTER → match to exit keyword)
- Exit accessibility checks (locked doors? key in inventory?)
- Room transition (update `ctx.current_room`, load room contents, reset view)

---

## Movement Workflow

**Step 1: Parse Direction**
```
Player types: "go north"
handle_movement extracts direction: "north"
```

**Step 2: Exit Lookup**
- Find current room in `ctx.rooms[ctx.current_room]`
- Look up exit with direction "north"
- If no exit, fail: "You can't go that way"

**Step 3: Accessibility Checks**
```lua
-- Current room has exit:
exit = { direction = "north", target = "cellar", locked = true }

-- Check accessibility
if exit.locked then
    Check: is key in player.hands?
    if not found: "The door is locked. You need a key."
    else: proceed to transition
end
```

**Step 4: Room Transition**
```lua
ctx.current_room = exit.target  -- Move player to new room
reset_view()                    -- Show new room description + contents
```

---

## Location Tracking

**Player Location:**
- Stored in `ctx.current_room` (room ID string)
- Updated atomically on successful movement
- Reverted on failed movement (stay in original room)

**Location Impact:**
1. **Sensory Scope:** What can player see/feel? (objects in current room)
2. **Object Ticking:** Only objects in current room + player hands tick
   - Prevents resource burn in other rooms (matches don't burn while player is elsewhere)
3. **Verb Targeting:** LOOK/EXAMINE target objects in current room
4. **Exit Validation:** Can only use exits from current room

---

## Multi-Room Architecture

**Room Storage:**
- All rooms loaded at startup from `src/meta/world/*.lua`
- Stored in `context.rooms = { bedroom = {...}, cellar = {...}, ... }`
- Each room contains: id, name, description, contents array, exits

**Room Contents Array:**
- `room.contents` lists object GUIDs currently in this room
- When player enters room, display objects in room
- When object drops, add to room contents
- When object taken, remove from room contents

**Object Persistence:**
- Drop item in bedroom → item stays in registry with `location = "bedroom"`
- Move to cellar → return to bedroom → item still there
- Objects don't "disappear" when player leaves room

**Object Ticking Scope:**
- Objects tick only when in:
  1. Current room (where player is), OR
  2. Player hands (being held/worn)
- Objects in other rooms don't tick (matches don't burn, timers don't count)
- Enables exploration without resource drain

---

## Exit System

**Exit Structure:**
```lua
exit = {
    direction = "north",
    target = "cellar",
    locked = false,
    requires_key = "cellar_key",  -- optional
    -- alias keywords for ENTER/EXIT/GO commands
    keywords = { "north", "n", "forward" }
}
```

**Exit Accessibility:**
- **Locked Exits:** Require key in player inventory
- **Conditional Exits:** Can be gated by room state (cave-in blocks exit)
- **One-Way Exits:** Can be traversable only from one direction (future)

**Keyword Matching:**
- NORTH → matches direction
- ENTER → searches exit keywords for "enter" or room-specific keywords
- EXIT → searches for applicable exits

---

## Design Rationale

1. **Unified Movement Handler:** Single place for movement logic; extensible for new mechanics
2. **Exit Accessibility Checks:** Doors and locks handled at movement time, not at exit definition
3. **Location Tracking:** Enables efficient object ticking (only active area) and sensory filtering
4. **Multi-Room at Startup:** All rooms load together; enables reference between rooms (exits)
5. **Object Persistence:** Dropped items stay put; creates memorable world state

---

## Related Systems

- **Sensory:** See Light & Dark System for room-based visibility
- **Objects:** Object location determined by room ID + inventory slot
- **Verbs:** Some verbs (OPEN) work on doors that block exits
- **Player State:** See player-model.md for `ctx.current_room` storage
