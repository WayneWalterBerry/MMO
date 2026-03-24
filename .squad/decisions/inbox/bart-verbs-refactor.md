# Bart Decision: Verbs Refactor Split

**Date:** 2026-03-27
**Context:** P0-A Step 4 (verbs/init.lua refactor)

## Decision
Split `src/engine/verbs/init.lua` into helper + 10 verb modules using a `register(handlers)` pattern, with a registry-only `init.lua`.

## Details
- Added `src/engine/verbs/helpers.lua` as the shared utility module (core helpers + optional parser modules).
- Added verb modules: `sensory`, `acquisition`, `containers`, `destruction`, `fire`, `combat`, `crafting`, `equipment`, `survival`, `movement`, `meta`.
- Moved self-infliction parsing helpers (`parse_self_infliction`, `handle_self_infliction`) into helpers for reuse by strike → hit routing.

## Impact
- Verb behavior is unchanged; module boundaries are now explicit and easier to edit.
- `engine.verbs` remains the public entry point (registry only).

## Tests
- `lua test/run-tests.lua`
