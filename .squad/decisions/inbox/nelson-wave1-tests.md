# Decision: WAVE-1 Creature Health Schema

**From:** Nelson (QA)
**Date:** 2026-07-27
**Affects:** Flanders (objects), Bart (engine), Nelson (tests)

## Context

While writing WAVE-1 creature TDD tests, discovered that creature health uses flat number fields (`health = 15`, `max_health = 15`) rather than the nested table (`health = { current = 15, max = 15 }`) assumed in the Phase 2 plan's test specifications.

## Decision

Tests aligned to match the ACTUAL creature file schema: `health` (number) and `max_health` (number) as separate top-level fields. This is consistent across all 5 creatures (rat, cat, wolf, spider, bat).

## Impact

- Any engine code reading creature health should use `creature.health` and `creature.max_health` (not `creature.health.current` / `creature.health.max`)
- WAVE-2 combat damage should decrement `creature.health` directly
- Wolf dead state is `portable = false` (too heavy) — differs from small creatures; engine code checking lootability should respect per-creature dead state metadata

## Action Required

None — informational. Tests already aligned.
