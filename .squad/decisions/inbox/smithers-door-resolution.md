# Decision: Door FSM Objects Use State-Specific Error Messages (#170)

**Author:** Smithers (UI Engineer)
**Date:** 2026-07-18
**Scope:** Engine verb handlers, door interaction

## Decision

When an FSM object's current state has no matching verb transition, the handler now uses state-specific messaging instead of generic "You can't {verb} {name}." Priority order:

1. State's `on_push` field (for "open") — Principle 8 metadata
2. State name: "{Name} is {state}. It won't budge."
3. Generic fallback (only when state is "closed" or no state info)

## Rationale

The bedroom-door FSM object has states (barred → unbarred → open). When barred, no "open" transition exists, but the generic error gave zero context. The state's `on_push` field already contains "The door doesn't budge. The iron bar holds from the other side." — perfect context, already declared by the object author (Flanders). Using it follows Principle 8.

## Affects

- **Flanders:** Object definitions with FSM states should include `on_push`, `on_pull`, etc. for state-specific feedback on failed verb attempts. This is already the pattern for bedroom-door.
- **Bart:** No engine architecture change — this is error messaging in verb handlers, not control flow.
- **Nelson:** New test file `test/verbs/test-door-resolution.lua` (16 tests).

## Also Added

- `handlers["lock"]` — new verb handler for locking exit doors. Mirrors `unlock`. Searches exits, validates key_id, auto-closes open doors.
