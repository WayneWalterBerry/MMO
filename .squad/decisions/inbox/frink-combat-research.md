# D-COMBAT-RESEARCH — Combat System Research Complete

**Author:** Frink (Research Scientist)
**Date:** 2026-03-25
**Status:** Research Complete — awaiting design decisions

## Summary

Completed comprehensive combat research across 5 domains (MUDs, competitive games, board games, MTG, Dwarf Fortress). All findings in `resources/research/combat/` (6 documents, ~86KB).

## Key Recommendations

1. **Adopt DF's material-physics model** for damage resolution. Our 17+ material registry needs 4 combat properties (shear resistance, impact resistance, density, max edge). No abstract damage points — damage emerges from material interaction.

2. **Deterministic combat with bounded variance.** Steel cuts flesh. Always. Variance comes from hit location (random, weighted by zone size) and player choice (attack/dodge/block/flee). No "you miss" on reasonable attacks.

3. **Unified combatant interface.** One `resolve_combat()` function for player-vs-rat, cat-vs-rat, guard-vs-thief. No combatant-type-specific code in the engine (Principle 8).

4. **Creatures declare combat as metadata.** Natural weapons, body zones, armor, behavior, flee thresholds — all in the creature's `.lua` file. Engine executes, objects declare.

5. **MTG-inspired turn structure.** Each exchange: initiative → attacker acts → defender responds → resolve → narrate. Player always gets a response choice.

## Who Should Know

- **Bart** — needs to design the combat resolution module (`src/engine/combat/`)
- **Flanders** — creature objects need `combat` metadata tables with natural weapons, body zones, behavior
- **Moe** — rooms may need combat-relevant spatial properties (cover, escape routes, cramped spaces)
- **Smithers** — combat verbs needed: `attack`, `block`, `dodge`, `flee` + combat-state response prompts
- **Comic Book Guy** — design decisions needed on Phase 1 scope, see INDEX.md Section 4
- **Nelson** — combat test framework needed; DF-style material interactions are highly testable

## Open Decisions for Wayne/Team

1. **Deterministic or probabilistic?** (Research recommends: primarily deterministic)
2. **DF detail level?** (Research recommends: 4-6 body zones, not 200 parts)
3. **Phase 1 scope?** (Research recommends: single rat combat with material comparison, body zones, player choices)
