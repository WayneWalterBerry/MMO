# Decision: Self-Infliction Verbs + Bandage Dual-Binding

**Author:** Bart (Lead Engineer)  
**Date:** 2026-07-26  
**Status:** IMPLEMENTED  
**Scope:** Engine (injuries.lua, verbs/init.lua), Objects (silver-dagger, knife, glass-shard, bandage)

---

## What Was Built

Implemented Bob's stab-self design and Flanders' bandage dual-binding architecture as engine features.

### 1. Self-Infliction Verbs (stab/cut/slash)
- Three verbs with distinct weapon profile lookups: `on_stab`, `on_cut`, `on_slash`
- Parser handles: "stab self with knife", "cut my arm with dagger", "stab arm", bare "stab self"
- Body area targeting: 8 areas with weighted random selection (arms 37.5%, hands 25%, legs 25%, torso 6.25%, stomach 6.25%, head 0% random)
- Body area damage modifiers: ×1.0 baseline, ×1.5 torso/stomach, ×2.0 head
- Weapon description `%s` substitution with body area at runtime

### 2. Injury Location Tracking
- `inflict()` now accepts `location` and `override_damage` parameters
- `list()` shows: "bleeding wound on your left arm — Blood flows steadily."
- Targeting can match by location: "apply bandage to left arm"

### 3. Bandage Apply/Remove (Dual Binding)
- `apply bandage [to target]` → resolves injury via 5-priority targeting → dual-binds bandage↔injury
- Bandage FSM: clean → applied (drain stops, healing_boost active)
- `remove bandage` → unbinds both sides → bandage → soiled, injury → active (drain resumes)
- One bandage per injury, one injury per bandage (mutual exclusion)

### 4. Weapon Objects Updated
- Silver dagger: stab(8/bleeding), cut(4/minor-cut), slash(6/bleeding)
- Knife: stab(5/bleeding), cut(3/minor-cut)
- Glass shard: cut(3/minor-cut) with self_damage flag

## Key Decisions

| ID | Decision | Rationale |
|---|---|---|
| D-INJURY013 | Weapon profiles own damage values, not engine | Principle 8: engine executes metadata. Different weapons produce different injuries. |
| D-INJURY014 | Body area modifiers are engine-side | Weapons shouldn't need to know about anatomical risk. Universal scaling. |
| D-INJURY015 | Dual-binding with mutual references | Both bandage and injury know about each other. No orphaned references. |
| D-INJURY016 | Premature bandage removal resumes drain | Risk/reward: strip one bandage to save another wound, but the first reopens. |
| D-INJURY017 | 5-priority targeting resolution | Flexible input: players can say "bleeding", "left arm", "first wound", or just "apply bandage". |

## Test Coverage

105 new tests. 280 total (all passing). Covers: infliction with location, override damage, targeting resolution, dual binding, removal lifecycle, drain math, weighted random selection, weapon encoding, body modifiers, disambiguation display.

## Dependencies Consumed

- Bob's design: `docs/design/player/self-infliction.md` — verb patterns, body areas, weapon encoding
- Flanders' architecture: `docs/architecture/player/injury-targeting.md` — targeting resolution, dual binding, removal
- Bob's bandage design: `docs/design/injuries/bandage-lifecycle.md` — FSM states, lifecycle
- Flanders' bandage FSM: `src/meta/objects/bandage.lua` — object metadata with transitions
