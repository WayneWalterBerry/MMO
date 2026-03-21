# Decision: Self-Infliction Mechanic Design

**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-07-25  
**Status:** PROPOSED  
**Design Doc:** `docs/design/player/self-infliction.md`  
**Requested By:** Wayne Berry

---

## Summary

Designed the "stab self" mechanic — deliberate self-injury as both a test harness for the injury system and a gameplay mechanic (blood offerings, desperate escapes, ritual puzzles).

## Key Decisions

1. **Three verbs:** `stab`, `cut`, `slash` — each reads a different damage profile from the weapon (`on_stab`, `on_cut`, `on_slash`). Different verbs produce different injuries from the same weapon.
2. **9 body areas:** left/right arm, left/right hand, left/right leg, torso, stomach, head. Weighted random selection when unspecified. Head excluded from random — must be explicit.
3. **Weapon-encoded damage:** All damage values, injury types, and descriptions live on the weapon object. Engine reads metadata only. Follows Principle 8.
4. **Body area modifiers:** Arms/hands/legs = ×1.0, torso/stomach = ×1.5, head = ×2.0. Engine-side, not weapon-side.
5. **Glass shard self-damage:** Cutting with an unwrapped shard also injures the holding hand. Reinforces "wrap before use" lesson.
6. **Narrative tone:** Three-beat structure (Resolve → Action → Consequence). Never casual. Escalates on repeated self-injury.
7. **Combat precursor:** Same weapon profiles reused for future combat. Self-infliction validates the entire injury→treatment pipeline.

## Handoffs

| Agent | Task |
|-------|------|
| **Bart** | New verb handlers for `stab`/`cut`/`slash` with self-target detection, instrument resolution, body area parsing, damage profile reading, body modifier application, injury instantiation, confirmation gates for head/bandaged targets |
| **Flanders** | Add `on_stab`/`on_cut`/`on_slash` damage profiles to: silver-dagger, kitchen-knife, glass-shard, pin. Add `self_damage` flag to glass shard `on_cut` |
| **Nelson** | Test all parser patterns, disambiguation flows, weapon validation failures, accumulation from stacking, body modifiers, death from repeated self-injury |
| **CBG** | Review blood-offering puzzle integration, narrative tone guidelines, overall pacing of self-injury as mechanic |

## Open Questions (Wayne)

1. Bare "arm" disambiguation — auto-select non-dominant, or always ask?
2. Head targeting — confirmation prompt or narrative warning?
3. `slash` verb — now or deferred to combat?
4. Bare-hand self-injury (`punch self` → bruise)?
5. Per-turn self-injury cap?

## Dependencies

- Injury system must be implemented (bleeding.lua, minor-cut.lua templates)
- Treatment targeting must work (for testing the bandage-after-stab loop)
- Parser must support `with X` instrument phrases and `my BODY_PART` targeting
