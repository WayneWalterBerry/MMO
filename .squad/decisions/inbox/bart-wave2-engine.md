# D-WAVE2-ENGINE: WAVE-2 Creature Generalization Engine Work

**Author:** Bart (Architecture Lead)
**Date:** 2026-07-30
**Status:** ✅ Implemented
**Category:** Architecture

## Decision

WAVE-2 engine work implemented: creature attack action, predator-prey detection, NPC combat integration, territorial behavior, and stimulus emission.

## Changes Made

### src/engine/creatures/init.lua (468 LOC, under 500 limit)
- `score_actions()`: Attack action scored when `has_prey_in_room()` returns true. Score = `aggression * 0.5 + hunger * 0.5`. Territorial bonus: `+aggression * 0.3` when in home territory.
- `execute_action()`: `"attack"` case calls `predator_prey.select_prey_target()` then `combat.run_combat()`. Emits `creature_attacked` and `creature_died` stimuli via `M.emit_stimulus`. Narrates to player if in same room.
- `creature_tick()`: Territorial evaluation reduces fear by 10 when creature is in home territory (before drive update).
- Exposed `has_prey_in_room`, `select_prey_target`, `score_actions`, `execute_action` as module-level functions for testing.

### src/engine/creatures/predator-prey.lua (fleshed out from stub)
- `has_prey_in_room(creature, context, get_creatures_fn, get_location_fn)`: Scans same-room creatures against `creature.behavior.prey`. Skips dead/inanimate.
- `select_prey_target(context, creature, get_creatures_fn, get_location_fn)`: Returns first alive prey match (priority order from prey list).

### src/engine/creatures/stimulus.lua (added convenience emitters)
- `emit_creature_attacked(room_id, attacker, defender)`: Convenience wrapper for creature_attacked stimulus.
- `emit_creature_died(room_id, creature, killer)`: Convenience wrapper for creature_died stimulus.

### src/engine/combat/init.lua (NPC support)
- `resolve_damage()`: NPC stance auto-select via `npc_behavior.select_stance()` for non-player attackers.
- `resolve_damage()`: NPC response auto-select via `npc_behavior.select_response()` when no response provided for non-player defenders.
- `resolve_damage()`: NPC stance modifier applied to both attack force and defense multiplier for non-balanced stances.
- `run_combat()`: NPC target zone via `npc_behavior.select_target_zone()` for non-player attackers.
- `run_combat()`: NPC defense response auto-selected for non-player defenders.

### src/engine/combat/npc-behavior.lua (fleshed out from stub)
- `select_response(creature)`: Reads `combat.behavior.defense` (dodge/block/flee/counter).
- `select_stance(creature)`: Maps `combat.behavior.attack_pattern` to engine stance (aggressive/defensive/balanced).
- `select_target_zone(creature, defender)`: Uses `combat.behavior.target_priority` — "weakest" targets vital zones, "threatening" targets largest zone.

## Key Design Decisions

1. **Prey list on behavior, not combat**: `creature.behavior.prey` drives predator-prey detection. Matches existing creature data structure.
2. **Attack pattern → Stance mapping**: Creature `attack_pattern` values (sustained, ambush, etc.) map to engine stances via `PATTERN_TO_STANCE` table. No hardcoded creature logic.
3. **Stimulus routing through M.emit_stimulus**: Attack/death stimuli routed through creatures module's `emit_stimulus` for testability (monkey-patchable).
4. **Territorial dual effect**: Territory both reduces fear (in creature_tick) and boosts attack score (in score_actions). Both needed since tests call score_actions in isolation.

## Affected Agents

- **Nelson**: 40 WAVE-2 tests now pass (test-creature-combat.lua + test-predator-prey.lua)
- **Flanders**: No creature data files modified (pure engine wave)
- **Smithers**: No parser/UI changes
