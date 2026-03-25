# D-WEAR-HAND-DEFENSIVE-SWEEP

**Author:** Bart (Architect)
**Date:** 2026-03-31
**Status:** Implemented
**Issue:** #180

## Decision

When moving an item from hand to worn, the wear handler now clears **all** hand slots holding that item (by ID match), not just the single `hand_slot` discovered during search. The take handler now blocks picking up worn items (checking `ctx.player.worn`) in addition to the existing hand-duplicate check.

## Rationale

Wayne's playtest showed a spittoon appearing in both left hand AND worn simultaneously. The handler-level logic was correct (Nelson's 9 unit tests pass), but the single-slot clear (`hands[hand_slot] = nil`) didn't defend against edge-case integration paths where stale references could survive. The defensive sweep is O(2) — zero performance cost, maximal safety.

The take handler's Bug #53 guard only checked hands for duplicates, not the worn list. This allowed `take <worn_item>` to re-acquire a worn item into a hand slot.

## Impact

- **Smithers:** No parser changes needed. The fix is in the verb handlers.
- **Nelson:** 7 new integration tests in `test/integration/test-wear-hand-integration.lua`. Unit tests unchanged.
- **Flanders:** No object definition changes. The `wear` table contract is unchanged.
- **Gil:** Web adapter uses the same verb handlers — fix applies to both native and Fengari paths.

## Pattern

**Defensive sweep over targeted clear** — when mutating player state (hands ↔ worn ↔ bags), always sweep all related slots by ID rather than relying on a single index. This prevents state inconsistencies from integration-layer edge cases.
