# Session Log: FSM Engine Implementation

**Date:** 2026-03-19
**Session ID:** 2026-03-19-145450
**Topic:** FSM Engine Shipped — Dynamic Object State Machines
**Agent Lead:** Bart (Architect)

## Context

Wayne directed unified object state management into FSM definitions. Comic Book Guy designed the FSM object lifecycle system. This session implements the engine.

## Outcome

**FSM Engine is live.** Match and nightstand now use table-driven state machines with in-place mutation. Auto-transitions run on tick. Game loop integration complete. 9 test cases pass. 3 search bugs fixed.

## Key Deliverables

### 1. FSM Engine (`src/engine/fsm/init.lua`)

```lua
-- ~130 lines
-- Loads FSM definitions on demand
-- Applies state transitions in-place
-- Integrates with game loop tick
-- Maintains backward compatibility
```

**Core Functions:**
- `load_fsm(id)` — Lazy-load and cache FSM definition
- `apply_state(obj, state)` — Mutate object in-place
- `tick(obj)` — Process auto-transitions
- `find_transition(obj, verb, args)` — Dispatch verb-triggered transitions

### 2. Match FSM (`src/meta/fsms/match.lua`)

```lua
match = {
  shared = { ... },
  states = {
    unlit = { on_strike = "lit", on_burn = { warning = true } },
    lit = { on_extinguish = "unlit", on_tick = { trigger = "burned-out", after = 3 } },
    burned_out = { on_look = "scorched", locked = true }
  },
  transitions = { ... }
}
```

**Lifecycle:** unlit → lit (strike) → burned-out (3-turn auto-burn)

### 3. Nightstand FSM (`src/meta/fsms/nightstand.lua`)

```lua
nightstand = {
  shared = { surface = {...} },
  states = {
    closed = { contents_visible = false },
    open = { contents_visible = true }
  },
  transitions = { open = "open", close = "closed" }
}
```

**Mechanics:** Closed surface hides contents; open surface exposes them.

### 4. Game Loop Integration (`src/engine/loop/init.lua`)

```lua
-- After each command:
fsm_tick(room.contents)
fsm_tick(room.surfaces[...].contents)
fsm_tick(player.inventory)
```

Processes all stateful objects; skips non-FSM objects.

### 5. Bug Fixes (Side Effect)

**src/engine/search.lua:**
- Keyword substring matching → substring_match flag
- Hand priority over bag in search order
- Bag extraction edge case when item is in multiple containers

**Impact:** All 9 test cases pass; backward compatibility maintained.

## Design Rationale

1. **Why table-driven?** Definitions are data, not code. Enables runtime introspection, validation, and potential editor UI.

2. **Why in-place mutation?** Registry references and containment data must be preserved. Object replacement would break these invariants.

3. **Why tick in the loop, not in handlers?** Separates state management from verb dispatch. Auto-transitions are deterministic and time-based, not event-based.

4. **Why fallback to old system?** Gradual migration. Only 7 objects need FSM. Other 32 objects keep working with old mutation system indefinitely.

5. **Why structured return from on_tick?** Keeps FSM definitions declarative. State functions don't perform transitions directly — they describe the outcome, and the engine applies it.

## Test Results

- ✅ Match unlit → lit → burned-out (3-turn duration)
- ✅ Nightstand closed ↔ open (property swapping)
- ✅ Auto-burn tick verified
- ✅ Verb handlers correctly route to FSM
- ✅ Non-FSM objects unaffected
- ✅ Backward compatibility: 3 search bugs fixed, all tests pass
- ✅ Containment and registry preserved through mutations

## Consequences

**Deprecated Files:**
- `src/meta/objects/match-lit.lua`
- `src/meta/objects/nightstand-open.lua`
- Archived to `src/meta/objects/_deprecated/`

**Enabled Future Work:**
- Candle FSM (3 states: unlit, lit, burned)
- Vanity FSM (mirror, locked drawer, cosmetics)
- Wardrobe FSM (hanging clothes, drawers, shoe racks)
- Window FSM (closed, open, locked, broken)
- Curtains FSM (open, closed, drawn)

**Blocked Pending FSM Completion:**
- Paper dynamics (requires paper/ink FSM)
- Knife/pin as injury tools (requires safe FSM)
- Sewing mechanics (requires wardrobe FSM)

## Cross-Agent Context

**To CBG:** FSM engine is live. Your design implemented exactly. Match and nightstand validated the table-driven approach. Ready for remaining 5 objects.

**To Frink:** FSM architecture validates table-driven Lua approach from your research. Homoiconicity proved valuable for runtime introspection and state mutation.

## Git Commit

**Branch:** Main
**Files:** 
- Added: `src/engine/fsm/init.lua`, `src/meta/fsms/match.lua`, `src/meta/fsms/nightstand.lua`
- Modified: `src/engine/loop/init.lua`, `src/engine/verbs/init.lua`, `src/main.lua`, `src/engine/search.lua`, `src/meta/objects/match.lua`, `src/meta/objects/nightstand.lua`
- Archived: `src/meta/objects/_deprecated/match-lit.lua`, `src/meta/objects/_deprecated/nightstand-open.lua`

**Message:**
```
FSM engine shipped: match 3-turn, nightstand container, 3 search bugs fixed

- Built FSM engine (~130 lines) with lazy-loading definitions and in-place mutation
- Match FSM: unlit → lit → burned-out (3-turn auto-burn)
- Nightstand FSM: closed ↔ open with compartment swapping
- Game loop FSM tick phase after each command
- Verb handlers check FSM before old mutation system
- 3 keyword resolution bugs fixed in search
- All 9 test cases pass
- Backward compatibility: 32 non-FSM objects unaffected
- Deprecated: match-lit.lua, nightstand-open.lua

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

## Next Session Priorities

1. **Candle FSM** — 3 states (unlit, lit, burned), drips mechanic
2. **Vanity FSM** — Mirror, drawers, cosmetics mechanics
3. **Wardrobe FSM** — Hanging space, drawer storage, try-on mechanics
4. **Player Skills System** — Pending FSM foundation (lighting, sewing, etc.)

---

**Scribed by:** Scribe Agent
**Status:** COMPLETE
