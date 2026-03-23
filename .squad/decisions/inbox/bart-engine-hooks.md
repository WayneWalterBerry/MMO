# Decision: Engine Hooks — Effect Processing Pipeline for Injuries

**Author:** Bart (Architect)
**Date:** 2026-07-22
**Status:** PROPOSED
**Requested by:** Wayne "Effe" Berry
**Scope:** `src/engine/effects.lua` (new), `src/engine/verbs/init.lua` (refactor), object metadata format

---

## Context

Objects cause injuries through three ad-hoc patterns: string `effect` fields on transitions ("poison"), `on_{verb}_effect` fields on states ("cut"), and structured `on_stab`/`on_cut` tables. Each pattern requires inline interpretation by verb handlers. Adding new injury-causing mechanics requires editing verb handler code, violating the "engine stays generic; objects own behavior" principle.

## Decision

**Create a unified Effect Processing Pipeline** (`src/engine/effects.lua`) that:

1. Accepts both string effects (backward compatible) and structured effect tables
2. Dispatches to registered effect handlers by `type` field
3. Ships with `inflict_injury` as the primary built-in handler, which calls `injuries.inflict()`
4. Replaces all inline verb-handler effect interpretation

**Object metadata format changes to:**
```lua
effect = {
    type = "inflict_injury",
    injury_type = "poisoned-nightshade",
    source = "poison-bottle",
    damage = 10,
    message = "A bitter taste burns...",
}
```

**Legacy format still works** via `normalize_effect()` string-to-table mapping.

## Key Architectural Decisions

1. **Effects are per-object, not per-verb.** Objects declare what happens; engine decides when.
2. **Effect processor is separate from hook framework.** Hooks determine *when* code runs (on_traverse, on_enter_room). Effects determine *what* happens (inflict_injury, fsm_transition). Hooks can invoke effects, but effects also fire from FSM transitions and sensory callbacks — they're not hook-exclusive.
3. **No new hooks needed for consumable injuries.** Existing FSM transition `effect` field + `effects.process()` handles poison, bad food, all consumables.
4. **`on_enter_room` hook needed for spatial traps.** Pit traps, gas clouds, falling rocks require room-level hook. Follows existing `traverse_effects.lua` pattern.
5. **Backward compatible.** Zero breaking changes. Existing string effects normalize to structured tables.

## Consequences

- **Positive:** Every new injury-causing object requires zero engine code changes. Object authors declare effects in metadata.
- **Positive:** Effect types are extensible. `fsm_transition`, `spawn_object`, `heal` can be added as effect handlers without touching existing code.
- **Negative:** Minor refactor needed in `verbs/init.lua` to replace inline effect checks with `effects.process()` calls.
- **Negative:** Legacy string effects create an implicit mapping that must be maintained.

## Implementation Priority

P0: `effects.lua` module + `inflict_injury` handler + `normalize_effect()`
P1: Verb handler refactor to use `effects.process()`
P2: `on_enter_room` hook + `trap_effect` subtype

## Full Analysis

See: `docs/architecture/engine/event-hooks.md`
