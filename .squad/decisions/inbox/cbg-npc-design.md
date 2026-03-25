# Decision: NPC System Design Plan

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-03-28  
**Status:** Design Complete — Awaiting Wayne Approval  
**Deliverable:** `plans/npc-system-plan.md`

## Summary

Designed the comprehensive NPC/creature system for the MMO text adventure engine. Introduces Principle 0a (animate opt-in) to cleanly extend the object system for living creatures. Uses Dwarf Fortress–inspired data-driven architecture where creature `.lua` files declare behavior metadata and the engine evaluates it generically.

## Key Decisions

### 1. Principle 0a: Animate Extension
Objects with `animate = true` participate in the creature tick phase. This is a clean opt-in that preserves Principle 0 (objects are inanimate by default) while enabling creatures. The engine treats all objects identically for loading, registration, and keyword resolution; the creature tick is an additional evaluation phase for animate objects only.

### 2. Metadata-Driven Behavior (Principle 8 Compliance)
No creature-specific engine code. Creatures declare `behavior`, `drives`, and `reactions` tables. The engine evaluates these generically using utility-scored action selection. A rat, a cat, and a guard dog all use the same engine code — they just have different metadata values.

### 3. Start with a Rat
Phase 1 implements a single rat with:
- 3 drives (hunger, fear, curiosity)
- 4 FSM states (alive-idle, alive-wander, alive-flee, dead)
- 4 reaction types (player_enters, player_attacks, loud_noise, light_change)
- Utility-based action selection with random jitter
- Complete sensory descriptions for all 5 senses

### 4. Four-Phase Scaling Path
1. **Rat** — foundation system, single creature
2. **Creature Variety** — cat, bat, guard dog, spider (proves generalization)
3. **Creature Ecology** — creature-to-creature interactions (cat hunts rat)
4. **Humanoid NPCs** — inventory, dialogue, memory, quests (north star)

### 5. Creature Tick Integration
Creature tick slots into the game loop after fire propagation and before injury tick. Follows same pattern as existing tick systems (~6 lines of integration code).

## Affected Team Members

| Member | Impact |
|--------|--------|
| **Bart** | Build `engine/creatures/init.lua`, game loop integration, stimulus emission points |
| **Flanders** | Build `creature.lua` template, `rat.lua` definition, `flesh.lua` material |
| **Smithers** | New verbs (catch, chase), creature room presence in look, attack extensions |
| **Nelson** | TDD for creature tick, rat behavior, verb interactions, integration |
| **Moe** | Creature placement in room definitions |
| **CBG** | Design complete; reviews all implementation for gameplay quality |

## Open Questions for Team

1. Creature respawning: permanent death or timed respawn?
2. Creature-to-player combat mechanics (rat biting)
3. Creature noise audible from adjacent rooms?
4. Save/load handling for creature state

## Risk

Primary risk is scope creep into humanoid features. Phase boundaries are hard-locked. Phase 1 is ONLY the rat and the creature foundation.
