# Decision: Engine Hook Architecture

**ID:** D-HOOK001
**Author:** Bart (Lead Engineer)
**Date:** 2026-07-22
**Status:** Design (approved for implementation)
**Scope:** Engine — extensible game event system

---

## Context

The `on_traverse` exit-effect system (D-TRAVERSE001) proved that a registry-based handler pattern works well for engine-level game events. Wayne wants to formalize this as a named, extensible system — separate from FSM — that can be expanded with new hook types as gameplay requires.

The question was: what do we call these, how do they relate to FSM, and what other game events should have hooks?

## Decision

### Naming: "Engine Hooks"

We adopt **"Engine Hooks"** as the formal name for engine-built handler functions that fire in response to game events.

- Not "Verb Handlers" — some hooks fire from engine events (timers, room entry), not player verbs.
- Not "Event Handlers" — too generic, would collide with FSM callbacks (`on_transition`, `timed_events`).
- "Engine Hooks" is precise: engine-owned code that hooks into the game loop at defined points.

### Architecture

- **Registry pattern:** `hooks.register(hook_type, subtype, handler_fn)` — same pattern as `traverse_effects.register()`.
- **Dispatch:** `hooks.dispatch(hook_type, effect, ctx)` — called from exactly one integration point per hook type.
- **Metadata declaration:** Content authors declare hooks in `.lua` metadata files with `{ type = "subtype", ... }` tables.
- **Module home:** `src/engine/hooks/` — one file per hook type, plus `init.lua` for the registry.

### Relationship to FSM

- **Engine Hooks** = engine code that fires on game events (engine devs create these).
- **FSM** = data-driven state transitions on objects (content authors create these).
- Hooks CAN trigger FSM transitions. FSM does NOT fire hooks (no circular dispatch).

### Hook Catalog (12 types identified)

Priority hooks (needed for current gameplay): `on_traverse` (done), `on_enter_room`, `on_pickup`, `on_examine`, `on_first_visit`.

Future hooks: `on_leave_room`, `on_drop`, `on_combine`, `on_use`, `on_timer`, `on_npc_react`, `on_death`.

### Migration

Existing `src/engine/traverse_effects.lua` becomes `src/engine/hooks/on_traverse.lua` with the generic registry extracted to `src/engine/hooks/init.lua`.

## Rationale

- **Extensible:** New hook types require zero changes to existing engine code — register a handler, add a dispatch call.
- **Separation of concerns:** Engine devs write handlers; content authors write metadata. Neither needs to understand the other's domain deeply.
- **Forward-compatible:** Unknown subtypes are silently ignored, so metadata can reference future handlers.
- **Proven pattern:** `on_traverse` has been running in production with 15+ tests. This decision generalizes a working pattern.

## Full Design Doc

See `docs/architecture/engine/event-handlers.md` for the complete architecture, all 12 hook types with examples, implementation guide, and design rules.
