# D-AUTO-IGNITE-TIMER-AUDIT

**Author:** Nelson (QA)
**Date:** 2026-07-27
**Status:** Proposed
**Issue:** #178

## Decision

Any code path that changes an object's `_state` field directly (bypassing `fsm.transition()`) MUST also call `fsm.start_timer(registry, obj_id)` if the new state has `timed_events`.

## Context

Bug #178 (lit match never burns out) is caused by `auto_ignite()` in `src/engine/verbs/fire.lua` setting `_state = "lit"` directly without starting the FSM timer. The explicit `strike` path works because it goes through `fsm.transition()` which calls `start_timer()` automatically.

## Known Direct State Assignments

These locations bypass `fsm.transition()` and may need timer auditing:

1. **`fire.lua` — `auto_ignite()`** — confirmed bug, no timer started
2. **`meta.lua` — `set` handler** — clock puzzles, may not need timers
3. **`helpers.lua` — `detach_part()` / `reattach_part()`** — composite parts

## Who Should Know

- **Bart** — FSM architecture owner, should review whether `apply_state()` should auto-call `start_timer()`
- **Smithers** — owns verb handlers where direct assignments exist
- **Flanders** — any objects with timed states affected by these paths
