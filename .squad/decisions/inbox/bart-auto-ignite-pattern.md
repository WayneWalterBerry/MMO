# Decision: Auto-Ignite Pattern for Fire Source Detection

**Author:** Bart (Architect)
**Date:** 2025-07-19
**Context:** Bug #169 fix

## Decision

When `find_fire_source()` detects an object whose FSM states (but not current state) provide the required tool capability, it auto-transitions that object to the capable state. This bypasses FSM guards like `requires_property`.

## Rationale

- An unlit match's `lit` state provides `fire_source`, but the normal FSM transition requires `has_striker` (matchbox). When a player says "light candle" while holding a match, auto-striking is a natural convenience action.
- The auto-ignite uses direct state application (not `fsm.transition`) because it's an implicit engine action, not a player verb. Guard checks don't apply.

## Impact

- **Flanders:** Objects with multi-state tool provision (like the match) now work automatically as tools. No changes needed to object definitions.
- **Smithers:** Parser doesn't need to handle "strike match then light candle" as a compound command for this case — the engine handles it.
- **Nelson:** Tests should verify auto-ignite modifies the tool's state (match goes to `lit`), not just the target's state.

## Scope

Only affects `find_fire_source()` in `src/engine/verbs/fire.lua`. Does not change FSM module or general tool resolution.
