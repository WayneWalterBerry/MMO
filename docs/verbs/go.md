# Go

> Move in a direction using compass directions or named exits.

## Synonyms
- `go` — Go in a direction
- `go [direction]` — Go north/south/east/west/up/down/etc.
- `go through [exit]` — Go through a named exit
- `move` — Move in a direction (generic movement)
- `shift` — Move smoothly
- `slide` — Move smoothly
- `walk` — Walk in a direction (normal speed)
- `travel` — Travel in a direction
- `run` — Run in a direction (fast movement)
- `head` — Head in a direction (purposeful movement)
- `climb` — Climb stairs, ladders, or obstacles
- `enter` — Enter through an exit or into a location
- `north` / `n` — Move north (cardinal shorthand)
- `south` / `s` — Move south (cardinal shorthand)
- `east` / `e` — Move east (cardinal shorthand)
- `west` / `w` — Move west (cardinal shorthand)
- `up` / `u` — Move up (vertical shorthand)
- `down` / `d` — Move down (vertical shorthand)
- Used as dispatcher for directional movement

## Sensory Mode
- **Works in darkness?** ✅ Yes — can navigate by memory/touch
- **Light requirement:** None (though disorientation possible in complete darkness)

## Syntax

### Primary Movement
- `go north` — Move north (or: `go n`)
- `go south/east/west` — Directional movement
- `go up/down` — Vertical movement
- `go through [door/exit]` — Go through a named exit
- `go [direction]` — Any compass direction

### Alternative Verbs
- `walk north` — Walk in a direction (normal speed)
- `walk [direction]` — Walk in any compass direction
- `travel [direction]` — Travel (synonym for walk)
- `run north` — Run north (fast movement)
- `run [direction]` — Run in any compass direction
- `head north` — Head in a direction (purposeful movement)
- `head [direction]` — Head in any compass direction

### Climbing
- `climb up` — Climb upstairs
- `climb down` — Climb downstairs
- `climb [object]` — Climb a specific obstacle
- `climb up [object]` — Climb up something
- `climb down [object]` — Climb down something

### Entering
- `enter [exit]` — Enter through a door or exit
- `enter [location]` — Enter into a location
- `go through [exit]` — Alternative syntax for entering

### Directional Shortcuts
- `north` — Move north (equivalent to `go north`)
- `n` — Shorthand for north
- `south`, `s` — Move south
- `east`, `e` — Move east
- `west`, `w` — Move west
- `up`, `u` — Move up
- `down`, `d` — Move down

### Spatial Movement (generic)
- `move [object]` — Move something
- `move [object] aside` — Move aside
- `shift [object]` — Shift (synonym)
- `slide [object]` — Slide (synonym)

## Behavior

### Basic Movement
- **Direction parsing:** Normalized from "north" → "n", "south" → "s", etc.
- **Room transition:** Player moves from current room to adjacent room
- **Exit checking:** Room must have exit in that direction
- **State change:** `ctx.player.location` updated to new room
- **Message:** "You go [direction]." or descriptive room entry message
- **Failure:** "You can't go that way." if no exit

### Walk (Normal Speed)
- **Speed:** Normal walking pace (narrative flavor vs. `run`)
- **Direction parsing:** Accepts cardinal and vertical directions
- **Delegation:** Typically delegates to `go` handler
- **Narrative:** May print different message than bare direction

### Run (Fast Speed)
- **Speed:** Faster than walking (narrative flavor vs. `walk`)
- **Direction parsing:** Accepts cardinal and vertical directions
- **Delegation:** Typically delegates to `go` handler
- **Narrative:** May print "You run" instead of "You go"
- **No stamina mechanics:** (Currently simple, no fatigue tracking)

### Head (Purposeful)
- **Movement:** Similar to `go`/`walk`/`run`, different narrative tone
- **Direction parsing:** Accepts cardinal and vertical directions
- **Purpose:** Implies intentional, directed movement
- **Delegation:** Typically wraps `go` handler

### Climb (Obstacles)
- **Obstacle checking:** Object must be climbable (`climbable = true`)
- **Direction support:** "up"/"down" directions for stairs and ladders
- **Destination:** Moves player to above/below room
- **State update:** `ctx.player.location` changed via traverse_effects
- **Failure:** "You can't climb that." if not climbable
- **Risky in darkness:** Can climb by touch but dangerous

### Enter (Named Exits)
- **Exit lookup:** Resolves exit by name
- **Room transition:** Moves player through exit to destination room
- **State update:** `ctx.player.location` changed
- **Description:** May print entry message from exit definition
- **Failure:** "You can't enter that." if exit not found

### Move (Spatial Objects)
- **Movable check:** Object must be movable
- **Spatial movement:** Uses spatial object movement system
- **Search order:** Hands first (interaction verb)
- **State change:** Object repositioned
- **Message:** "You move X."

## Design Notes

### Movement Dispatcher
- **Primary verb:** `go` is the main movement verb; directional commands may delegate to `go`
- **Named exits:** Can also use exit object names (e.g., "go through door")
- **Darkness tolerance:** Player can navigate in darkness (relies on memory)

### Flavor Verbs
- **Walk:** Identical mechanically to `go`, but with different narrative tone
- **Run:** Mechanically identical to `go`/`walk`, purely narrative (suggests urgency)
- **Head:** Implies intentional, directed movement with narrative distinction

### Specialized Movement
- **Climb:** Different from simple `go up/down` — implies effort and climbing mechanics
- **Enter:** Provides alternative to "go north" — can "enter door" instead
- **Touch navigation:** Can move obstacles by feel; climbing in darkness is risky but possible

## Related Verbs
- `pull` — Detach parts or move objects
- `push` — Move heavy objects aside
- `lift` — Lift and reveal

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["go"]`, `handlers["walk"]`, `handlers["run"]`, `handlers["head"]`, `handlers["climb"]`, `handlers["enter"]`, `handlers["north"]`, `handlers["s"]`, etc.
- **Movement logic:** `src/engine/traverse_effects.lua` handles room transitions
- **Spatial system:** Uses `move_spatial_object()` for obstacle movement
- **Aliases:** `walk`, `travel`, `run`, `head` all delegate to `go` with context
- **Directional handlers:** Each n/s/e/w/u/d is a wrapper around `go` handler
- **Ownership:** Bart (Architect) — game state mutation, room transitions
