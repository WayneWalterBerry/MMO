# Search

> Progressive room traversal verb — explores a room step-by-step, narrating discoveries, with time cost and interruptibility.

## Synonyms
- `search` — Search the room (full sweep, step-by-step)
- `search around` — Same as search (normalized by preprocessor)
- `search for [object]` — Targeted search for a specific object

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

## Related Verbs
- `find` — Targeted discovery with goal-oriented variant ("find something that can light the candle")
- `look` — Vision-only observation (instant, no turn cost)
- `feel` — Touch-based groping (no traversal cost, localized)
- `listen` — Hearing-based discovery (narrower scope than search)
- `examine` — Close inspection of a single object

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["search"]`
- **Preprocessor:** `src/engine/parser/preprocess.lua` normalizes "search around" → search ""
- **Traverse engine:** `src/engine/systems/traverse.lua` — walks room objects, manages turn cost, handles interruption
- **Proximity system:** Room metadata defines furniture ordering
- **Container logic:** Auto-opens unlocked containers during traversal
- **Ownership:** Brockman (Documentation & Design), Bart (Architect — traversal system), Smithers (UI — narrative output)
