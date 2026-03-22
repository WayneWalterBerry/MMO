# Search/Find Engine Architecture

**Module:** `src/engine/search/`  
**Ownership:** Bart (Architect)  
**Status:** Design Phase  

## Overview

The search/find engine is a progressive room traversal system that transforms discovery from an instant database query into a time-bound, interruptible, narratively-rich exploration mechanic.

**Core Philosophy:** Discovery is not instant; it's a time commitment with narrative pacing that makes exploration feel real.

## Key Features

- **Progressive Traversal** — Step-by-step room exploration (not instant results)
- **Turn Cost** — Each search step costs one game turn (injuries tick, clock advances)
- **Interruptible** — Player can abort mid-search with any command
- **Auto-Open Containers** — Unlocked containers open automatically during search
- **Persistent State** — Opened containers stay open (realistic)
- **Discovery vs Acquisition** — Finding announces but doesn't auto-pickup
- **Context Setting** — Found objects become targets for follow-up commands
- **Sensory Adaptation** — Narration adapts to light (vision) vs dark (touch)
- **Goal-Oriented Search** — "find something that can light" (GOAP or property matching, TBD)

## Design Decisions (16 Total)

| # | Decision | Answer |
|---|----------|--------|
| 1 | Turn cost | Each step = 1 game turn (injuries tick, clock advances) |
| 2 | Interruptible | Yes — any command aborts the search |
| 3 | Proximity | Closest furniture first (room metadata ordering) |
| 4 | Auto-open | Unlocked containers opened, locked skipped with note |
| 5 | Container state | Stays open after search (realistic) |
| 6 | On find | Announce only — don't auto-pickup. Target set as context for bare "pick up" |
| 7 | Goal search | TBD — unit tests to decide GOAP vs property matching |
| 8 | Room boundaries | Same room only — never crosses rooms |
| 9 | Failed search | Full narration one object per turn, summary on completion |
| 10 | Scoped search | "search nightstand" = just that object + contents |
| 11 | Scoped cost | Per-surface (nightstand top + drawer = 2 turns) |
| 12 | Darkness speed | Same speed, different narration (touch vs vision) |
| 13 | Search memory | Remembers what's been searched, skips on re-search |
| 14 | Surfaces included | Yes — tops, undersides, shelves all searched |
| 15 | Object ordering | Surfaces FIRST, then nested containers (recursive depth-first) |
| 16 | Separate module | `src/engine/search/` — own module, thin verb handler |

## Syntax Patterns

### Basic Search
- `search` — Undirected room sweep
- `search for [target]` — Room-wide targeted search
- `search [scope]` — Scoped sweep ("search nightstand")
- `search the room` — Explicit full sweep

### Basic Find
- `find [target]` — Targeted discovery
- `find [target] in [scope]` — Scoped targeted search

### Compound Patterns
- `search [scope] for [target]` — "search the nightstand for the matchbox"
- `find [target] in [scope]` — "find the matchbox in the nightstand"
- Fuzzy matching: "matches" finds "match" inside "matchbox" inside drawer
- Chained: "search for a match, light it and light the candle"

### Goal-Oriented (TBD Implementation)
- `find something that can [action]` — "find something that can light the candle"
- `find something [property]` — "find something sharp"

## Architecture Documents

1. **[module-design.md](./module-design.md)** — Module structure and component responsibilities
2. **[state-machine.md](./state-machine.md)** — Search state machine and transitions
3. **[data-model.md](./data-model.md)** — Data structures and persistence
4. **[parser-integration.md](./parser-integration.md)** — Parser syntax handling and context

## Module Structure

```
src/engine/search/
├── init.lua          ← Public API: search(), find(), abort(), is_searching()
├── traverse.lua      ← Walk algorithm: proximity ordering, step machine
├── containers.lua    ← Container open/close/lock detection during search
├── narrator.lua      ← Narrative generation (dark vs light, sense selection)
└── goals.lua         ← Goal-oriented matching (GOAP or property-based TBD)
```

## Integration Points

### Verb Handlers
- `verbs/init.lua` — Thin handlers that parse and delegate to search module
- Parse syntax patterns → extract scope/target → call `search.search()` or `search.find()`

### Game Loop
- `loop/init.lua` — Calls `search.tick()` once per turn
- Search module manages ALL traverse state internally
- Loop doesn't need to know about search state

### Container System
- Search module queries existing container properties (`is_locked`, `is_open`)
- Reuses container open/close logic — no duplication

### Context System
- Found objects set `ctx.last_noun` for pronoun resolution
- Enables: `find matchbox` → `take it` (without re-specifying)

## Testing Strategy

### Unit Tests Required
1. Proximity ordering respected in traversal
2. Turn cost applied per step
3. Container auto-open (unlocked) and skip (locked)
4. Interruption cleans up state
5. Context set correctly on discovery
6. Goal-oriented search (both approaches for comparison)
7. Sensory narration adapts to light level

### Integration Tests Required
1. Search + take workflow
2. Find + interruption workflow
3. Multiple searches with persistent container state
4. Goal-oriented search with various object types
5. Time pressure scenario (injuries ticking during search)

## Related Systems

- **FSM Engine** — Search steps trigger FSM transitions (container opening)
- **Injury System** — Turn cost causes injuries to tick
- **Time System** — Clock advances during search
- **Verb System** — Search/find verbs delegate to this module
- **Parser** — Handles compound syntax patterns, context chaining

## Design References

- [search-traverse.md](../../../design/search-traverse.md) — Original design doc by Brockman
- [search.md](../../../verbs/search.md) — Search verb specification
- [find.md](../../../verbs/find.md) — Find verb specification
- Wayne's Q&A directives in `.squad/decisions/inbox/`

## Future Considerations

- **Partial matches** — Multiple objects qualify for goal-oriented search
- **Learning system** — Player gets faster at searching known locations
- **NPC awareness** — NPCs notice opened containers
- **Search efficiency** — Skill-based speed improvements
