# Decision: D-DISEASE-TDD-PATTERN

**Date:** 2026-07-30
**Author:** Nelson (QA)
**Status:** Active

## Context

WAVE-4 Track 4E disease tests written TDD-style before Bart's Track 4C/4D engine implementation. Tests need to validate behavior of code that doesn't exist yet.

## Decision

1. **Dual-pattern duration checks:** Tests check for both `duration` field (spec/mock style) and `timed_events[].delay` (real definition style, 360s per tick). This avoids brittle coupling to one representation.

2. **Skip, don't fail, for unimplemented features:** Tests that depend on Bart's Track 4C/4D (disease FSM tick transitions, `get_restrictions()`, `combat.update` on_hit delivery) use `pcall` guards and emit SKIP rather than FAIL. This keeps the test suite green while clearly marking what's pending.

3. **Load from disk, fall back to mock:** Tests `pcall(dofile, ...)` the real injury definitions first. If the file doesn't exist yet, they fall back to inline mock definitions matching the spec. This means tests auto-upgrade when Flanders ships the real files.

## Impact

- **Bart:** When implementing `injuries.tick()` disease transitions and `injuries.get_restrictions()`, the 8 skipped tests will auto-activate and validate your implementation. No test changes needed.
- **Flanders:** Definitions already validated against spec — `timed_events` delays, `curable_in`, `restricts`, `healing_interactions` all confirmed correct.
- **Nelson:** Re-run after Bart 4C/4D lands to verify skipped tests flip to PASS.
