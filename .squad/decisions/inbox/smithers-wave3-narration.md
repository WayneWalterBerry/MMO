# Decision: WAVE-3 Witness Narration API Surface

**Author:** Smithers (Parser/UI Engineer)
**Date:** 2026-07-27
**Track:** WAVE-3 Track 3C

## Context

NPC-vs-NPC combat needs player-visible narration based on proximity and lighting. Bart's combat engine (Track 3A) will call narration functions after resolving exchanges.

## Decisions

### D-WITNESS-API: Narration entry points for Bart

Three main entry points added to `src/engine/combat/narration.lua`:

1. **`describe_exchange(result, opts)`** — Unified dispatcher. `opts.light` selects visual vs audio-only. `opts.distance` selects proximity tier ("adjacent", "out_of_range"). Default = same room + lit.

2. **`emit_witness(result, player_room_id, combat_room_id, light, exits, is_player_combat)`** — Full-context entry point using proximity detection. Calls `describe_exchange` internally, applies module-level budget.

3. **`emit(result, budget, opts)`** — Budget-aware emit. Pass explicit budget from `new_budget(cap)`. Detects calling convention: table first arg = budget-aware, string first arg = simple/legacy.

### D-NARRATION-BUDGET: Budget protocol

- Cap = 6 NPC narration lines per combat round (configurable via `new_budget(cap)`).
- Non-critical (GRAZE/DEFLECT severity) suppressed when over cap.
- Critical (HIT/SEVERE/CRITICAL) always passes even over budget.
- Player combat exempt via `opts.player_combat = true`.
- Overflow marker deferred to `overflow_text(budget)` — NOT auto-emitted in `emit()`.
- Morale break narration counts toward cap (1 line each).
- Budget resets per round via `reset_budget()` or creating new budget object.

### D-WITNESS-TEMPLATES: Template keyword compliance

All dark/audio templates validated against Nelson's keyword list (hear, sound, thud, crack, squeal, shriek, yelp, whimper, impact, wet, etc.). Every template contains ≥1 matching substring.

## Affected Agents

- **Bart:** Call `emit_witness()` or `describe_exchange()` from combat engine after `resolve_exchange()`.
- **Nelson:** 16 TDD tests in `test/combat/test-witness-narration.lua` all pass.
- **Brockman:** Document narration tiers in `docs/architecture/combat/npc-combat.md`.
