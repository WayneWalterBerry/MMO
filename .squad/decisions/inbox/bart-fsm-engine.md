# Decision: FSM Engine Architecture

**Date:** 2026-03-23
**Author:** Bart (Architect)
**Status:** Implemented and tested

## Context

Wayne directed unifying multi-file object state management (match.lua + match-lit.lua, nightstand.lua + nightstand-open.lua) into single FSM definitions. Comic Book Guy designed the FSM object lifecycle system (docs/design/fsm-object-lifecycle.md). This decision covers the engine implementation choices.

## Decision

### 1. Table-driven FSM with lazy-loading definitions

FSM definitions live in `src/meta/fsms/{id}.lua` and are loaded on demand via `require()`. The engine caches loaded definitions. Each definition contains: `shared` properties (immutable across states), `states` (per-state property overrides), and `transitions` (from/to/verb/guards).

### 2. In-place object mutation (not replacement)

Unlike the old mutation system (which hot-swaps the entire object via `loadstring`), the FSM engine modifies the existing object table in-place. This preserves the registry reference, containment data, and any runtime-assigned fields. The `apply_state` function: saves containment → removes old state keys → applies shared → applies new state.

### 3. Verb handlers check FSM before old mutations

Each modified verb handler checks `obj._fsm_id` first. If present, the FSM path runs. If not, the old `find_mutation`/`perform_mutation` path runs. This enables gradual migration — only match and nightstand use FSM today; all other objects keep working.

### 4. FSM tick in the game loop, not in verb handlers

Auto-transitions (burn countdown) are processed in a dedicated FSM tick phase in the game loop, after each command. This is separate from verb dispatch. The tick iterates room contents, surface contents, and player inventory. Objects without `_state` are skipped.

### 5. on_tick returns structured data, not side effects

The `on_tick` function in FSM state definitions returns `{ trigger = "..." }` or `{ warning = "..." }` instead of performing transitions directly. The engine interprets the return value and applies the transition. This keeps the FSM definition declarative.

## Consequences

- Match and nightstand no longer need separate files per state (match-lit.lua, nightstand-open.lua deprecated)
- 5 more FSM objects to convert (candle, vanity, wardrobe, window, curtains) — same pattern
- Old mutation system remains for non-FSM objects indefinitely (no rush to remove)
- Three pre-existing search bugs (keyword substring, hand/bag priority, bag extraction) fixed as a side effect

## Files Changed

- `src/engine/fsm/init.lua` — New FSM engine (~130 lines)
- `src/meta/fsms/match.lua` — Match FSM definition
- `src/meta/fsms/nightstand.lua` — Nightstand FSM definition
- `src/engine/verbs/init.lua` — FSM integration in open/close/strike/extinguish handlers
- `src/engine/loop/init.lua` — FSM tick phase after each command
- `src/main.lua` — Skip FSM objects in old tick_burnable
- `src/meta/objects/match.lua` — Simplified, FSM-aware
- `src/meta/objects/nightstand.lua` — Simplified, FSM-aware
- `src/meta/objects/_deprecated/` — Old match-lit.lua, nightstand-open.lua
