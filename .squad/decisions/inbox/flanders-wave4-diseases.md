# Decision: WAVE-4 Disease Injury Definitions Complete

**From:** Flanders (Object & Injury Systems Engineer)
**Date:** 2026-07-28
**Tracks:** WAVE-4 4A + 4B

## What Was Decided

Created two new disease-type injury definitions: `rabies.lua` and `spider-venom.lua`. Both files introduce 3 new metadata fields not present in existing injury templates:

1. **`hidden_until_state`** — Rabies uses `"prodromal"` to suppress messages during incubation. Spider venom does not use this (immediate symptoms).
2. **`curable_in`** — Array of state names where healing items work. Outside this list, treatment fails.
3. **`transmission`** — `{ probability = N, via = "bite" }` for `on_hit` disease delivery in combat.

## Who This Affects

- **Bart (4C + 4D):** These 3 new fields require engine implementation:
  - `injuries.tick()` must handle `hidden_until_state` (suppress messages/visibility until that state is reached)
  - `injuries.heal()` must check `curable_in` before allowing healing transitions
  - Combat `on_hit` must read `transmission.probability` and `transmission.via`
  - `injuries.get_restrictions()` must merge `restricts` tables from active disease states
- **Nelson (4E):** Test files can now be written — both injury definitions are committed and loadable via `dofile()`. Key test points: rabies transitions at ticks 15/25/33, spider venom at 3/8, `drink` blocked in furious rabies, healing-poultice cures rabies in incubating/prodromal but fails in furious.

## Design Notes

- Rabies `initial_state = "incubating"` (not "active") — follows disease semantics rather than generic injury naming.
- Spider venom is NOT fatal — paralysis auto-resolves after 8 ticks. This is intentional: spider bites are dangerous but survivable.
- Spider venom accepts both `antivenom` and `healing-poultice` in healing_interactions. Rabies only accepts `healing-poultice`.
