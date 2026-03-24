# Search System Design

> Search is a convenience command that saves the player from manually looking in every container. But it shouldn't be too convenient — the player pays real time for this service.

## Design Philosophy

**Search as Costly Convenience**

Search and find are **progressive room traversals** — engines that walk through a room step-by-step, narrating discoveries, with time cost and interruptibility. The mechanic transforms discovery from instant (query a database) to earned (traverse, invest time, manage risk).

**Core Principle:** Discovery is not instant; it's a time commitment with narrative pacing that makes exploration feel real.

**Why Time Costs Matter:**
- **Incentive to search strategically** — Player won't search if bleeding out
- **Risk-reward tension** — Finding something may cost you dearly (injuries tick during search)
- **Rewards knowledge** — Targeted search is faster than blind sweep
- **Realism** — Thorough exploration takes time
- **Agency** — Player can escape a long search by interrupting

This design ensures search feels like a deliberate choice, not a convenience shortcut that bypasses all discovery.

---

## Mechanical Behavior

### Traversal Ordering: Proximity Lists

**Definition:** Proximity ordering is a **fixed, per-room ordered list** of furniture objects, arranged from closest to farthest from the player's current position.

Each room includes a `proximity_list` in its metadata:

```lua
bedroom = {
  name = "Master Bedroom",
  proximity_list = {
    "bed",           -- Player is likely on this
    "nightstand",    -- Adjacent to bed
    "vanity",        -- Across from bed
    "wardrobe",      -- Corner
    "dresser",       -- Wall
    "bookshelf",     -- Far wall
  }
}
```

During search/find, the engine iterates through `proximity_list` in order, examining each object and its surfaces/contents.

**Why Proximity?**
- Proximity feels real — explore closest objects first, expanding outward
- Fixed per room allows designers to shape discovery narrative through ordering
- Predictable — players learn room layouts through repeated searches
- Optimization — order is metadata, not calculated at runtime

### Search Scope Rules

**Three Search Patterns:**

1. **Undirected Sweep (`search` or `search around`)**
   - Full room traversal following proximity list
   - Narrates all discoverable objects
   - Continues until all furniture exhausted or player interrupts
   
2. **Targeted Search (`search for matchbox` or `find matchbox`)**
   - Follows same proximity ordering
   - **Stops immediately upon finding target**
   - Narrates path to discovery only

3. **Scoped Search (`search nightstand` or `search for candle in drawer`)**
   - Limits traversal to single object + contents
   - Still follows priority: surfaces before nested containers
   - Narrates only within that scope

### Turn Cost Model

**Each step (each furniture object examined) costs one game turn.**

Effects during search turn:
- Injuries tick (bleeding, poison, etc. worsen by 1 tick)
- Clock advances (game time moves forward)
- NPC actions process
- Weather changes occur

Example: 3-step search takes 3 turns.
```
> search for knife
You begin searching...

[Turn 1] You feel the dresser — nothing.
[Turn 2] You move to the nightstand — you pull open the drawer...
[Turn 3] Inside, your fingers find: a kitchen knife.

You have found: a kitchen knife.
```

**Design Intent:**
- Search is a real cost, not a freebie
- Incentivizes players to search strategically
- Creates time pressure and tension

### Container Mechanics During Search

**Unlocked Containers:**
- Auto-open **silently** during traversal (no extra turn cost)
- Remain **open after search** (reflects realism — you physically opened them)
- Contents become visible in subsequent `look` commands
- Player sees fruits of search effort

Example:
```
You reach out to a small nightstand. It has a drawer...
You pull the drawer open.
Inside, your fingers find: a small matchbox and a candle.
```

**Locked Containers:**
- Skip with narrative note (no turn cost for the skip itself)
- Container remains locked
- Player must use `unlock` verb separately
- Acknowledges presence without breaking flow

Example:
```
You spot a locked chest in the corner.
You examine it, but it's locked tight.
```

**Container State Persistence:**
- Containers opened during search **stay open** after search completes
- Reflects world consistency (no magical closing)
- Creates strategic considerations (opened containers expose items to NPCs)
- Players must manage consequences of opened containers

### Surface Priority

Surfaces are always searched **before** nested containers:

```
Nightstand search order:
1. Nightstand top surface
2. Nightstand drawer contents (container)

Dresser search order:
1. Dresser top surface
2. Dresser drawer 1 contents
3. Dresser drawer 2 contents
```

This ensures player explores obvious places before digging into nested storage.

### Discovery, Not Acquisition

**Core Principle:** Finding an object **does NOT pick it up**. It announces it and sets context.

Workflow:
```
[Find succeeds]
You have found: a small matchbox.

[Object becomes context]
> pick up
You pick up the matchbox.  -- Works without repeating "matchbox"

[Or explicit take]
> take it
You take the matchbox.  -- Works with pronoun
```

When an object is found, its identifier is stored in command context:
- Allows follow-up commands to reference it without re-stating name
- Persists until new object found or player moves

**Benefits:**
- Pacing — find announces; take is separate
- Agency — player chooses to acquire or leave
- Narrative clarity — "found" ≠ "obtained"
- Realism — discovery is not possession

### Interruption Handling

**Trigger:** Any new player command interrupts current search traversal.

**Clean Termination:**
1. Search loop breaks immediately
2. Turn cost applied **only for steps completed**
3. Engine resumes normal command processing
4. No lingering state

Example:
```
> search for torch
You begin searching...

[Turn 1] You feel the bed — nothing there.

> look
[Search interrupted]

You are in a dark bedroom...
```

- Only 1 turn was spent (Step 1 completed)
- Injuries ticked by 1
- New `look` command processes normally
- Search loop fully cleaned up

**Design Rationale:**
- Agency — player can escape if search takes too long
- Tactical depth — player chooses when to search, when to interrupt
- Narrative flexibility — interruption allows dynamic scene changes

---

## Sensory Narration

Narration adapts to light level and available senses:

**In Daylight (Light Available):**
```
You search the room...

Your eyes scan across a large bed — nothing useful.

You turn toward the nightstand and notice: a small lamp.
```

**In Darkness (No Light):**
```
You search the room...

You feel the edge of a large bed — nothing there.

Your hand brushes a nightstand. It has a drawer...
You pull it open.
Inside, your fingers find: a small matchbox.
```

**Sound-Based Discovery:**
```
You listen carefully...

You hear the faint tick of a clock. Moving closer, you locate: a wall-mounted clock.
```

### Narrative Templates

**Proximity step (nothing found):**
- Light: "Your eyes scan the {object} — nothing notable."
- Dark: "You feel the {object} — nothing there."
- Sound: "You listen near the {object} — silence."

**Container discovery (unlocked):**
- "The {object} has a drawer..."
- "You notice it's slightly ajar. You pull it open."
- "Inside, your fingers find: {contents}."

**Container discovery (locked):**
- "You spot a locked {object}. You can't open it without a key."

**Target found:**
- "You have found: {object name}."

---

## Search-Related Decisions

All decisions below are from `.squad/` and recorded in this doc to ensure they're respected in implementation:

| Decision | Rationale |
|----------|-----------|
| **Turn cost per step** | Makes search a real commitment, not a convenience shortcut. Encourages strategic use. |
| **Proximity-ordered traversal** | Feels real and gives designers control over discovery flow. Avoids random search chaos. |
| **Auto-open unlocked containers** | Saves turn cost on obvious containers; speeds up intended discovery flow. |
| **Skip locked containers** | Prevents search from immediately revealing all locked areas. Maintains suspense. |
| **Containers stay open** | Reflects realism (you physically opened them). Creates narrative consequences. |
| **Found ≠ acquired** | Separates discovery from possession. Gives player agency to leave items. |
| **Interruptible** | Player can escape long searches. Creates tactical tension. |
| **Same-room-only traversal** | Prevents search from crossing room boundaries (unrealistic). |
| **Surfaces before nested containers** | Ensures obvious places explored before digging deeper. |

---

## Design Principles: Lessons in Search Mechanics

The search system evolved through extensive playtesting to embody these core principles:

### 1. **Scope Precision is Sacred**

Players must always control *what* they're searching. A scoped search (`search nightstand`) must be tight and predictable — if the engine wanders into unintended containers, players lose trust in the command. The traversal engine must recognize that **drawers, shelves, and nested containers are valid search targets**, not just top-level furniture. This means:

- Containers must be addressable by name during search
- The preprocessor must strip natural language fluff ("search the drawer" = "search drawer") without losing target identity
- Fuzzy matching is a hidden danger: if the player says "search dresser" and the engine fuzzy-matches to "desk," the wrong container opens

### 2. **Recursion Must Be Bounded**

Players expect to search "inside the wardrobe" and get the contents, but the system must prevent infinite loops through nested containers. A drawer in a cabinet in a chest must be searchable but bounded. This requires:

- Visited set tracking to prevent re-traversing already-examined containers
- Clear depth limits to keep traversal predictable
- Narrative confirmation when entering nested depths ("You notice the drawer. You pull it open. Inside you find...")

### 3. **Articles and Politeness Must Vanish Silently**

Players use natural language: "search the nightstand," "find a matchbox," "look for something sharp." The engine strips these decorations (`the`, `a`, modifiers like `thoroughly`, `carefully`, `check`) but must do so without breaking compound commands like "find a match and light it" or misinterpreting "find something that can light a candle." The parser is complex; the experience must be seamless.

### 4. **Narration Must Be Articulate**

Sensory narration adapts to light conditions, but more fundamentally: **the player must never see doubled articles, misnamed objects, or grammatically broken prose**. When a container is opened during search ("You pull the drawer open"), the object must be named cleanly the first time. This teaches us:

- Container references must be tracked and correctly introduced ("the drawer," "a shelf," "the chest")
- Found objects must be named with proper grammar
- Proximity steps narrate cleanly with consistent sensory language

### 5. **Container Discovery ≠ Item Discovery**

When search narrates finding a container (`You notice the drawer...`), that's *different* from finding an item inside it (`Inside, your fingers find: a matchbox`). The system must:

- Announce container presence before contents
- Surface items before nested containers within that surface
- Ensure that once a container is opened during search, items inside become immediately accessible for `take` or `get` commands

### 6. **Target Recognition Must Be Exact at Scope Boundaries**

When a player searches for a specific item, the engine must **not** be tricked by fuzzy matching at the container level. If the player says "search for match," the engine searches containers, not guessing which drawer might have matches based on fuzzy item names. This prevents:

- Wrong container opening
- Search scope hijacking (fuzzy matching pulling in unrelated containers)
- Player confusion about *where* the item was found

### 7. **Multi-Step Goals Need Gentle Parsing**

Commands like "find a match and light it" are sequences, not atomic queries. The parser must:

- Understand that "and" can join verbs (find / light) with a single noun (match)
- Not hang when trying to plan multi-step goals
- Separate goal planning from search execution

### 8. **Surface Mapping Must Be Consistent**

When the player "feels inside the drawer," they should get the drawer's contents, not the nightstand's surface or some other confusing mix. Surface state must be:

- Correctly mapped during container traversal
- Persist across search steps
- Not confused between nested containers

These principles emerged from playtesting and are honored by regression tests to ensure the system remains stable as it evolves.

---

## Goal-Oriented Search (TBD)

**Syntax Examples:**
```
find something that can [action]
find something that can light [target]
find something sharp
find something to write with
```

**Two Implementation Approaches** (Wayne wants unit tests to decide):

#### Option A: Property Matching (Simple, Fast)
- Objects have simple properties: `is_sharp`, `is_fire_source`, `is_writing_tool`, etc.
- Engine searches for objects matching required property
- Fastest but less flexible
- Example: `find something sharp` → searches for `is_sharp = true`

#### Option B: GOAP-Driven (Flexible, Heavier)
- Uses GOAP (Goal-Oriented Action Planning)
- Determines if found object can achieve goal through available actions
- More flexible but computationally heavier
- Example: `find something that can cut` → checks cutting actions

**Current Status:** Not yet implemented. Design is in place; unit tests needed to determine best approach.

---

## Integration with Other Systems

### Container System
Search module queries container properties:
- `is_locked` — Skip with narrative
- `is_open` — Check state before opening
- Container state persists after search

Reuses existing container open/close logic — no duplication.

### Light System
Narration adapts based on room light level:
- Light available → vision-based prose
- Darkness → touch-based prose
- Hearing → sound-based discovery

### Context System
Found objects set command context:
- Enables `find matchbox` → `take it` (pronoun resolution)
- Persists until new object found or player moves

### Injury System
Turn cost causes injuries to tick:
- Each search step advances turn counter
- Active injuries worsen during search
- Creates time pressure

### FSM Engine
Search steps trigger FSM transitions:
- Container opening fires state transitions
- Narration respects object state changes

### Smithers UI System
Narrative generation is owned by Smithers:
- Adapts prose to available senses
- Manages narrative pacing
- Handles streaming output (line-by-line reveal)

---

## Module Architecture

**File Structure:**
```
src/engine/search/
├── init.lua          -- Public API and state coordination
├── traverse.lua      -- Walk algorithm and proximity ordering
├── containers.lua    -- Container interaction during search
├── narrator.lua      -- Narrative generation system
└── goals.lua         -- Goal-oriented matching (TBD)
```

**Verb Handlers** (verbs/init.lua):
- `handlers["search"]` — Parses syntax, delegates to search module
- `handlers["find"]` — Targeted search, goal-oriented variants

**Game Loop Integration:**
Search module manages ALL traverse state internally. Game loop calls `search.tick()` once per turn; search module handles step machine internally.

---

## Testing Coverage

### Unit Tests (15+ test files)
- Proximity ordering validation
- Turn cost application
- Container auto-open (unlocked) vs skip (locked)
- Interruption state cleanup
- Context setting on discovery
- Narration adaptation (light vs dark)
- Fuzzy scope hijack prevention (BUG-146)
- Article stripping
- Politeness/idiom handling
- Nested container recursion

### Regression Tests
All 38 bugs fixed during playtesting have regression tests to prevent recurrence.

### Integration Tests
- Search → take workflow
- Find → interruption workflow
- Multiple searches with persistent container state
- Time pressure scenarios (injuries ticking)
- Sensory narration across light levels

---

## Future Considerations

- **Partial matches:** Multiple objects qualify for goal-oriented search
- **Search efficiency:** Player learns to search efficiently (faster searches for known objects)
- **NPC awareness:** NPCs notice opened containers; affects story state
- **Search memory:** Track what's been searched, skip on re-search
- **Learning system:** Player gets faster at searching known locations

---

## System Ownership

- **Brockman:** Documentation, design narrative
- **Bart:** Architecture, traversal logic, goal matching
- **Smithers:** Narrative generation, sensory-aware prose templates, UI presentation
- **Wayne:** Design direction, decisions, playtest oversight

