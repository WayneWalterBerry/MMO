# Decision: Multi-Sensory Object Convention

**Proposed by:** Comic Book Guy (Game Designer)
**Date:** 2026-03-20
**Status:** Proposed
**Requested by:** Wayne "Effe" Berry

## Summary

All objects now carry multi-sensory description fields (`on_feel`, `on_smell`, `on_taste`, `on_listen`) in addition to visual `description`. These enable the dark-room mechanic where players use non-visual senses to navigate, identify objects, and make risk/reward decisions.

## Decision

1. **Every object MUST have `on_feel`** — it is the primary dark-navigation sense.
2. **`on_smell` is recommended** for objects with distinctive scents — it is the safe identification sense.
3. **`on_listen` is for active/mechanical objects only** — things that make sounds when interacted with.
4. **`on_taste` is the danger sense** — reserved for objects where tasting has real consequences. Rarity is intentional.
5. **`on_feel_effect` and `on_taste_effect`** trigger engine-level state changes (e.g., `"cut"` from glass shard, `"poison"` from poison bottle). The engine must check for `_effect` suffixes on all sensory fields.

## Sensory Hierarchy

| Sense | Safety | Information | Coverage |
|-------|--------|-------------|----------|
| FEEL | Medium | Shape, texture, temperature, weight | 100% |
| SMELL | Safe | Chemical identity, materials, age | ~65% |
| LISTEN | Safe | Mechanical state, contents, environment | ~16% |
| TASTE | DANGEROUS | Chemical composition — at a cost | ~8% |

## Design Philosophy

- Darkness is not a wall — it's a different mode of play
- Every sense gives different information about the same object
- SMELL is the safe way to identify liquids and chemicals
- TASTE is the "learn by dying" sense — real consequences, teaches caution
- The poison bottle is the canonical teaching moment: SMELL warns you, TASTE kills you

## Impact

- Engine must implement FEEL, SMELL, TASTE, LISTEN verbs that read corresponding `on_*` fields
- Engine must check for `_effect` suffixes and apply state changes
- All future objects must include at least `on_feel`
- Mutation variants must carry their own sensory fields (state-dependent)

## Files Changed

- 36 existing objects in `src/meta/objects/` updated with sensory fields
- 1 new object: `src/meta/objects/poison-bottle.lua`
- `nightstand.lua` and `nightstand-open.lua` updated to place poison bottle
