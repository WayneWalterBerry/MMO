# Decision: Split traverse effects into modules

Date: $ts
Owner: Bart
Issue: Phase 3 refactor (traverse_effects split)

## Decision
Split `src/engine/traverse_effects.lua` into `engine/traverse_effects/registry.lua` (registry + processing) and `engine/traverse_effects/effects.lua` (built-in handlers), with a thin wrapper preserving the public API and auto-registering built-ins.

## Rationale
The traverse effects engine is small but a shared dependency; isolating built-ins keeps the registry focused while preserving behavior.

## Constraints
- Zero behavior changes
- Preserve handler registration and processing semantics
