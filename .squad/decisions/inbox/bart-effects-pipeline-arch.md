# Decision: D-EFFECTS-PIPELINE — Unified Effect Processing Pipeline

**Date:** 2026-07-26  
**Author:** Bart (Architect)  
**Status:** PROPOSED  
**Scope:** Engine architecture  
**Deliverable:** `docs/architecture/engine/effects-pipeline.md`

## Context

The engine currently handles object effects inline in verb handlers. When a player drinks a poison bottle, the drink verb checks `trans.effect == "poison"` and hardcodes a call to `injuries.inflict()` with specific parameters. When a player tastes poison, the taste verb runs an entirely separate code path that calls `os.exit(0)` directly, bypassing the injury system. Every new injury-causing object requires editing engine code.

## Decision

Create a unified Effect Processing Pipeline (`src/engine/effects.lua`) that:

1. **Accepts** structured effect tables from object metadata (or legacy string tags via normalization)
2. **Routes** effects to registered handlers by `type` field (`inflict_injury` → `injuries.inflict()`, `narrate` → `print()`, etc.)
3. **Supports** before/after interceptors for modification, cancellation, and post-processing (armor, immunity, achievements)
4. **Replaces** inline verb handler effect interpretation with a single `effects.process(trans.effect, ctx)` call

## Consequences

- Objects declare *what* happens; the engine decides *when*; the pipeline decides *how*
- New effect types added by registering handlers — zero pipeline changes
- New injury-causing objects require zero engine changes (Principle 8 compliance)
- Fixes the taste verb `os.exit(0)` bug — all injury paths go through the injury system
- ~120 lines new, ~60 lines deleted (net reduction)

## Implementation Priority

- **P0:** Create `effects.lua` with `inflict_injury` + `narrate` handlers
- **P1:** Refactor drink, taste, feel verb handlers to use `effects.process()`
- **P2:** Register `add_status` handler; wire interceptor use cases
- **P3:** Converge `traverse_effects.lua` into unified pipeline
