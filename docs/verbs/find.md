# Find

> Progressive targeted discovery verb — locates specific objects using traversal, with support for goal-oriented search.

## Synonyms
- `find` — Find a specific object
- `find [object]` — Search for and locate something
- `find something that can [action]` — Goal-oriented search (GOAP or property matching)
- Preprocessor converts "find X" patterns to find verb

## Sensory Mode
- **Works in darkness?** ✅ Yes — uses any available sense
- **Senses used:** Vision (light), Touch (dark), Hearing, Smell, Taste
- **Adaptive narrative:**
  - Light: "You look around and find the..."
  - Darkness: "You feel around and discover a..."
  - Hearing: "You listen and locate a faint..."

## Syntax
- `find [object]` — Find something specific
- `find the [object]` — Find with article
- `find [sound]` — Find something by hearing (e.g., "find the ticking")
- `find something that can [action]` — Goal-oriented search (e.g., "find something that can light the candle")

## Behavior

### Basic Targeted Search
Find operates as a **focused traversal**:

1. **Proximity Ordering:** Follows same room proximity order as search
   - Closest furniture first → farthest furniture
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

### Goal-Oriented Search (TBD)
**Syntax:** `find something that can [action]`

Examples:
- `find something that can light the candle`
- `find something sharp`
- `find something to write with`

**Implementation approach (to be determined via unit tests):**
- **Option A:** GOAP-driven — engine determines if object can achieve goal
- **Option B:** Property matching — simple checks for `fire_source`, `sharp`, `writing_tool` properties

Wayne wants unit tests to explore smart object matching. This is a design TBD.

### Discovery Output
Once target is found:
- Announces discovery with sensory narration
- **Does NOT auto-pickup** — player must manually `take` or `get`
- Found object is set as **context** for follow-up commands
- Bare `pick up` or `take` works without re-specifying object name

### Narrative Style

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

## Design Notes

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
- `search` — All-sense discovery, can be undirected (`search`) or directed (`search for X`)
- `look` — Vision-only observation (instant, no turn cost)
- `listen` — Hearing-based discovery (narrower scope)
- `smell` — Olfactory discovery (narrower scope)
- `feel` — Touch-based discovery (narrower scope, localized)
- `examine` — Close inspection of a single object

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["find"]`
- **Preprocessor:** `src/engine/parser/preprocess.lua` converts patterns to find verb
- **Traverse engine:** `src/engine/systems/traverse.lua` — walks room objects, stops on match
- **Goal-oriented logic:** `src/engine/systems/goal-matcher.lua` (GOAP or property matching, TBD)
- **Container logic:** Auto-opens unlocked containers during traversal
- **Ownership:** Brockman (Documentation & Design), Bart (Architect — traversal & goal matching), Smithers (UI — narrative output)

