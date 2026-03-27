# Decision: Disease Engine API Contract (WAVE-4)

**Author:** Bart (Architecture Lead)
**Date:** 2025-07-28
**Scope:** injuries.lua, combat/init.lua

## What Changed

### New APIs

1. **`injuries.get_restrictions(player)`** — Returns a table of restriction keys (`{ drink = true, movement = true, ... }`) merged from all active injury state definitions. Verb handlers should call this before execution to enforce disease restrictions.

2. **`injuries.heal(player, injury_type)`** — Standalone disease cure. Checks `curable_in` array on the definition; returns `false` with "The treatment has no effect." if outside the cure window.

3. **`injuries.try_heal()`** now checks `curable_in` before `healing_interactions`, providing defense-in-depth for disease injuries.

### Disease Instance Fields

When `category = "disease"`, injury instances gain:
- `category` — "disease"
- `state_turns_remaining` — countdown to next auto-transition
- `_hidden` — `true` while disease is pre-symptomatic
- `hidden_until_state` — state name that clears `_hidden`

### on_hit Weapon Field

Weapons with `on_hit = { inflict = "disease_id", probability = N }` will automatically deliver diseases in combat at severity >= HIT. This is processed in `combat.update()` — no verb or creature-specific code needed.

## Who This Affects

- **Smithers:** Verb handlers should call `injuries.get_restrictions(player)` and check keys before allowing actions (e.g., `drink` blocked by rabies furious state). This is NOT yet wired into verb dispatch — Smithers owns that integration.
- **Flanders:** Disease injury definitions should include `category = "disease"`, `curable_in`, and states with `duration` (turns) or `timed_events`. Weapon `on_hit` fields on creatures are already working (spider has it).
- **Nelson:** All 3 disease test files (127 tests) pass with zero skips.
