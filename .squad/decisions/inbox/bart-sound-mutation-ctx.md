# Decision: mutation.mutate() accepts optional ctx parameter

**Author:** Bart (Architect)
**Date:** 2026-08-01
**Scope:** Engine API change — `src/engine/mutation/init.lua`

## Decision

`mutation.mutate(reg, ldr, object_id, new_source, templates, ctx)` now accepts an optional 6th `ctx` parameter. When provided and `ctx.sound_manager` is non-nil, the mutation sequence fires sound lifecycle hooks:

1. `stop_by_owner(old_id)` — stop sounds from the old object
2. `trigger(old, "on_mutate")` — fire the mutation sound event
3. `reg:register()` — swap the object
4. `scan_object(new_obj)` — scan replacement for new sound declarations

## Rationale

Mutation had no access to runtime context. Sound hooks need the sound manager, which lives on `ctx`. The optional parameter is backward compatible — existing callers that don't pass it get nil, and all sound hooks are nil-guarded.

## Affected Agents

- **Flanders:** Object mutation definitions (`becomes` field) — no change needed, but `on_mutate` sound key is now live.
- **Smithers:** Verb handlers that call `perform_mutation()` — already updated to pass `ctx`.
- **Nelson:** Integration tests should verify mutation sound lifecycle.
