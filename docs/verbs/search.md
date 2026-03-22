# Search

> Progressive room traversal verb — explores a room step-by-step, narrating discoveries, with time cost and interruptibility.

## Synonyms
- `search` — Search the room (full sweep, step-by-step)
- `search around` — Same as search (normalized by preprocessor)
- `search for [object]` — Targeted search for a specific object
- `find` — Find a specific object (synonym for targeted search)

## Sensory Mode
- **Works in darkness?** ✅ Yes — adapts narration to available senses
- **Senses used:** Vision (light), Touch (dark), Hearing, Smell, Taste
- **Adaptive narrative:**
  - Light: "You search and spot the..."
  - Darkness: "You feel out a nightstand..."
  - Hearing: "You hear a faint ticking..."

## Syntax
- `search` — Search the room (undirected full sweep)
- `search around` — Same as search (normalized by preprocessor)
- `search for [object]` — Targeted search for a specific object

## Behavior

### Traversal Mechanics
Search is a **progressive traversal**, not an instant list. The engine walks through the room object-by-object, narrating as it goes:

1. **Proximity Ordering:** Starts with closest furniture to player, expands outward
   - Example (bedroom): bed (player is on it) → nightstand (beside bed) → vanity → wardrobe → etc.
   - Order is fixed per room based on room metadata (proximity list)

2. **Turn Cost:** Each step costs **one game turn**
   - Injuries tick during the search
   - Clock advances per step
   - Searching is a TIME commitment

3. **Auto-open Containers:** Engine opens unlocked containers during search
   - Locked containers are skipped with narrative note: "You find a locked chest... you can't open it"
   - Containers remain **open after search** (realistic — you opened them)
   - Never forces locked containers

4. **Interruptible:** Player can abort mid-search by typing any command
   - Current search terminates immediately
   - Any new command takes over

### Targeted vs. Undirected Search

**Undirected search (`search`):**
- Full room sweep from closest to farthest furniture
- Narrates all discoverable objects
- Continues until all furniture exhausted or player interrupts

**Targeted search (`search for matchbox`):**
- Follows same proximity ordering
- Stops immediately upon finding target
- Narrates path to discovery

### Discovery Output
Once target is found:
- Announces discovery: "You have found a matchbox."
- **Does NOT auto-pickup** — player must manually `take`
- BUT found object is set as **context** — bare `pick up` or `take` works without re-specifying

### Narrative Style

Example undirected search (dark room):
```
> search
You begin searching the room...

You feel the edge of a large four-poster bed. Nothing useful on the sheets.

You reach out further — a small nightstand. It has a drawer...
You pull the drawer open.
Inside, your fingers find: a small matchbox.

[2 turns elapsed, injuries ticked]
```

Example targeted search (light room):
```
> search for lamp
You begin searching the room...

Your eyes scan the dresser — nothing notable.

You turn toward the bookshelf and spot: an old brass lamp.

You have found: an old brass lamp.
```

## Design Notes

- **Core mechanic:** Search is a traverse — not an instant result list
- **Time investment:** Each step is one turn; searching costs game time
- **Realistic interaction:** Containers opened during search stay open
- **Proximity system:** Room metadata defines furniture order (closest to farthest)
- **Sensory adaptation:** Narration adapts to light level and available senses
- **Interruptibility:** Any command breaks the search; clean termination
- **Context awareness:** Found objects become context for follow-up commands

## Find (Targeted Search)

> Progressive targeted discovery verb — locates specific objects using traversal, with support for goal-oriented search.

### Find Syntax
- `find [object]` — Find something specific
- `find the [object]` — Find with article
- `find [sound]` — Find something by hearing (e.g., "find the ticking")
- `find something that can [action]` — Goal-oriented search (e.g., "find something that can light the candle")

### Find Behavior

**Basic Targeted Search:**
Find operates as a **focused traversal** following the same proximity ordering as undirected search:

1. **Proximity Ordering:** Follows room proximity order (closest to farthest)
   - Auto-opens unlocked containers along the way
   - Locked containers skipped with narrative note

2. **Turn Cost:** Each step costs **one game turn**
   - Injuries tick during traversal
   - Clock advances per step

3. **Stops on Discovery:** Traversal halts immediately when target found
   - Announces: "You have found a matchbox."
   - **Does NOT auto-pickup** — player must manually take
   - Found object becomes **context** — bare `pick up` or `take` works

4. **Interruptible:** Player can abort by typing any command

**Goal-Oriented Search (TBD):**

Examples:
- `find something that can light the candle`
- `find something sharp`
- `find something to write with`

**Implementation approach (to be determined via unit tests):**
- **Option A:** GOAP-driven — engine determines if object can achieve goal
- **Option B:** Property matching — simple checks for `fire_source`, `sharp`, `writing_tool` properties

Wayne wants unit tests to explore smart object matching. This is a design TBD.

### Find Narrative Example

Example basic search (dark room):
```
> find the matchbox
You begin searching for the matchbox...

You feel the edge of a large four-poster bed. Nothing there.

You reach out to a small nightstand. It has a drawer...
You pull the drawer open.
Inside, your fingers find: a small matchbox.

You have found: a matchbox.
```

Example goal-oriented search (light room):
```
> find something that can cut
You begin searching for something that can cut...

Your eyes scan the dresser — nothing useful.

You turn to the toolbox and spot: a sharp knife.

You have found: a sharp knife.
```

### Find Design Notes

- **Wayne's Q&A Session:** Find and search both traverse progressively, not instant
- **Distinction from search:**
  - `find X` = always needs a noun argument (targeted)
  - `search` can be undirected (`search` without target)
  - `find something that can X` = goal-oriented (smart object matching, TBD)
- **Discovery, not acquisition:** Found object is NOT auto-picked-up, but context is set
- **Container behavior:** Unlocked containers auto-open during traversal; locked ones skipped
- **Container persistence:** Opened containers stay open (realistic)
- **Time cost:** Finding is a game mechanic with turn cost, not instant
- **Sensory adaptation:** Narrative adapts to light level (vision in light, touch in dark, hearing for sounds)
- **Interruptibility:** Any new command breaks the find traversal cleanly

## Related Verbs
- `look` — Vision-only observation (instant, no turn cost)
- `feel` — Touch-based groping (no traversal cost, localized)
- `listen` — Hearing-based discovery (narrower scope than search)
- `examine` — Close inspection of a single object

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["search"]` and `handlers["find"]`
- **Preprocessor:** `src/engine/parser/preprocess.lua` normalizes "search around" → search "" and converts find patterns to find verb
- **Traverse engine:** `src/engine/systems/traverse.lua` — walks room objects, manages turn cost, handles interruption, stops on match for find
- **Goal-oriented logic:** `src/engine/systems/goal-matcher.lua` (GOAP or property matching, TBD)
- **Proximity system:** Room metadata defines furniture ordering
- **Container logic:** Auto-opens unlocked containers during traversal
- **Ownership:** Brockman (Documentation & Design), Bart (Architect — traversal & goal matching), Smithers (UI — narrative output)
