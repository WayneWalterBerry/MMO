# Decision: Injury Lua Templates — First 5 Implementations

**Author:** Flanders (Object & Injury Systems Engineer)  
**Date:** 2026-07-25  
**Status:** Implemented  
**Files Created/Modified:**
- `src/meta/injuries/minor-cut.lua` (new)
- `src/meta/injuries/bleeding.lua` (new)
- `src/meta/injuries/poisoned-nightshade.lua` (replaced prototype)
- `src/meta/injuries/burn.lua` (new)
- `src/meta/injuries/bruised.lua` (new)

---

## What Was Done

Created the first 5 injury `.lua` template files in `src/meta/injuries/`, implementing Bob's design docs using the canonical format from `docs/architecture/player/injury-template-example.md`. Each file is a complete FSM definition with GUID, states, transitions, timers, and healing interactions.

## Key Decisions

1. **Nightshade uses "neutralized" not "treated"** — Bob's design distinguishes poison-curing (neutralization) from physical wound treatment. This is semantically clearer and prevents confusion in the healing item matching system.

2. **Burn blistered-path uses source-object timer override** — The active state's default timed_event leads to self-heal (minor burns). Severe burn sources override the instance timer to point to `blistered` instead. This avoids dual-timer conflicts in the state definition.

3. **Bruised has empty healing_interactions** — Rest/sleep are verb-triggered transitions, not item-based healing. The empty table satisfies the schema while correctly expressing that no healing item works on bruises.

4. **Nightshade worsened→neutralized uses `_timer_delay` mutate** — Recovery from stage 2 takes 6 turns instead of 4. The transition mutate sets `_timer_delay = 2160` to override the neutralized state's default 1440-second timer. Engine needs to honor this field.

5. **Bleeding timers align with Bob's design** — 15 turns to worsen (vs. template example's 20), 10 turns to heal when treated. These match Bob's design doc specifications.

## Needs Attention

- **Bart:** The `_timer_delay` mutate pattern (used in nightshade worsened→neutralized) may need engine support. The FSM engine should check transition mutates for timer overrides when entering a new state.
- **Bob:** Nightshade antidote object (`antidote-nightshade`) needs to be designed and placed in Level 1. The injury template references it in healing_interactions but the object doesn't exist yet.
- **Moe:** Burn treatment objects (`cold-water`, `damp-cloth`, `salve`) need `cures = "burn"` in their object metadata for dual-side validation.
- **Nelson:** These 5 injury templates need test coverage — FSM transitions, timer values, healing interaction matching.
