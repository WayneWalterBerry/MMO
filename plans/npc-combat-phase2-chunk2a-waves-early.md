# Phase 2 — Early Waves (WAVE-0 / WAVE-1 / WAVE-2)

> **Author:** Bart (Architecture Lead) · **Series:** chunk2a-waves-early
> **Companions:** chunk1-skeleton · chunk3-gates · chunk4-systems · chunk5-operations

| Wave | Name | Status | Gate |
|------|------|--------|------|
| 0 | Pre-Flight | ⏳ | GATE-0 |
| 1 | Creature Data | ⏳ | GATE-1 |
| 2 | Creature Generalization | ⏳ | GATE-2 |

---

## WAVE-0 — Pre-Flight (Engine Review + Remaining Bugs)

**Goal:** Verify engine foundations before building on them. Fix test infra gaps.

### Assignments

| Agent | Task |
|-------|------|
| Bart | Code review `src/engine/creatures/init.lua` (483 LOC) — audit stimulus queue, drive updates, action scoring, movement; identify attack-action + predator-prey integration points |
| Bart | Code review `src/engine/combat/init.lua` (487 LOC) — audit resolve_damage stance/response paths; confirm NPC-as-attacker viability in `M.run_combat`; map player-hardcoded assumptions |
| Bart | MODIFY `test/run-tests.lua` — register `test/food/` in `test_dirs` array (~line 41) |
| Nelson | Parallel: Portal TDD burndown (#199–#208), lint fixes (#249, #250) |

### Engine Review Focus

**creatures/init.lua:** (1) `score_actions` — where `attack` plugs in, (2) `execute_action` — where attack branches to combat FSM, (3) `creature_tick` — where predator-prey scan goes, (4) stimulus emission — `creature_attacked`/`creature_died` events.

**combat/init.lua:** (1) `resolve_damage` stance modifier is player-only (~L228) — needs NPC path, (2) defender response is player-only (~L259) — needs `combat.behavior.defense` auto-select, (3) `pick_weapon` already works for NPCs ✅, (4) target zone needs NPC `target_priority` driver, (5) death mutation verified for NPC defenders.

### GATE-0

- [ ] Engine review notes captured; integration points documented
- [ ] `test/food/` discovered by `lua test/run-tests.lua`
- [ ] Full test suite passes (exit 0)
- [ ] Portal TDD (#199–#208) progress tracked
- [ ] Lint (#249, #250) addressed or in-progress

---

## WAVE-1 — Creature Data (4 New Creatures + Material)

**Goal:** Define cat, wolf, spider, bat as pure data files. Add chitin material. Place in rooms. No engine changes.
**Depends on:** GATE-0

### File Operations

| Op | File | Owner | Agent |
|----|------|-------|-------|
| CREATE | `src/meta/creatures/cat.lua` | Flanders | Flanders |
| CREATE | `src/meta/creatures/wolf.lua` | Flanders | Flanders |
| CREATE | `src/meta/creatures/spider.lua` | Flanders | Flanders |
| CREATE | `src/meta/creatures/bat.lua` | Flanders | Flanders |
| CREATE | `src/meta/materials/chitin.lua` | Flanders | Flanders |
| MODIFY | `src/meta/rooms/courtyard.lua` | Moe | Moe |
| MODIFY | `src/meta/rooms/hallway.lua` | Moe | Moe |
| MODIFY | `src/meta/rooms/deep-cellar.lua` | Moe | Moe |
| MODIFY | `src/meta/rooms/crypt.lua` | Moe | Moe |
| CREATE | `test/creatures/test-cat.lua` | Nelson | Nelson |
| CREATE | `test/creatures/test-wolf.lua` | Nelson | Nelson |
| CREATE | `test/creatures/test-spider.lua` | Nelson | Nelson |
| CREATE | `test/creatures/test-bat.lua` | Nelson | Nelson |

### Creature Specifications

Template reference: `src/meta/creatures/rat.lua` (167 LOC). All creatures follow identical structure: guid, template "creature", id, name, keywords, description, sensory (on_feel required), FSM states/transitions, behavior, drives, reactions, movement, combat (body_tree + natural_weapons), health.

**cat.lua** — Predator, hunts rat
- Size: small, weight 4.0, material "flesh"
- body_tree: head (vital), body (vital), legs, tail — tissue: hide/flesh/bone
- States: alive-idle, alive-wander, alive-flee, alive-hunt, dead
- Behavior: aggression 40, flee_threshold 50, prey: `["rat"]`
- Drives: hunger 40 (+3/tick), fear 0, curiosity 50
- Combat: speed 7, weapons — claw (slash, keratin, force 3), bite (pierce, tooth-enamel, force 5)
- Health: 15/15

**wolf.lua** — Aggressive, territorial
- Size: medium, weight 35.0, material "flesh"
- body_tree: head (vital), body (vital), forelegs, hindlegs, tail
- States: alive-idle, alive-wander, alive-patrol, alive-aggressive, alive-flee, dead
- Behavior: aggression 70, flee_threshold 20, territorial true, territory "hallway", prey: `["rat","cat","bat"]`
- Drives: hunger 30 (+1/tick), fear 0, curiosity 20
- Combat: speed 7, weapons — bite (pierce, tooth-enamel, force 8), claw (slash, keratin, force 4); natural_armor: hide coverage body/head
- Health: 40/40

**spider.lua** — Passive, web-builder, venom
- Size: tiny, weight 0.05, material "chitin"
- body_tree: cephalothorax (vital), abdomen (vital), legs (grouped)
- States: alive-idle, alive-web-building, alive-flee, dead
- Behavior: aggression 10, flee_threshold 60, web_builder true
- Drives: hunger 20 (+1/tick), fear 10, curiosity 10
- Combat: speed 5, weapons — bite (pierce, tooth-enamel, force 1, on_hit: venom effect 60% chance); natural_armor: chitin coverage cephalothorax/abdomen
- Health: 3/3

**bat.lua** — Aerial, light-reactive
- Size: tiny, weight 0.02, material "flesh"
- body_tree: head (vital), body (vital), wings, legs
- States: alive-roosting, alive-flying, alive-flee, dead
- Behavior: aggression 5, flee_threshold 40, light_reactive true, roosting_position "ceiling"
- Drives: hunger 30 (+2/tick), fear 20, curiosity 15
- Reactions: light_change → fear +60, flee (key differentiator)
- Combat: speed 9, weapons — bite (pierce, tooth-enamel, force 1)
- Health: 3/3

**chitin.lua** — Insect exoskeleton material
- density 0.6, hardness 0.5, flexibility 0.2, conductivity 0.1, max_edge 0.3, color "dark brown"

### Room Placement (Moe)

| Room | Creature | Rationale |
|------|----------|-----------|
| `src/meta/rooms/courtyard.lua` | cat | Open area, hunts rats |
| `src/meta/rooms/hallway.lua` | wolf | Territorial — guards passage |
| `src/meta/rooms/deep-cellar.lua` | spider | Dark, damp habitat |
| `src/meta/rooms/crypt.lua` | bat | Dark, ceiling for roosting |

### TDD (~80 tests across 4 files)

Each test file validates: loads without error, required fields present, sensory fields (on_feel required), FSM states valid, body_tree zones have tissue layers, combat weapons reference valid materials, drive values in bounds, health > 0. Creature-specific: cat has prey ["rat"], wolf has territorial true, spider has on_hit venom, bat has light_reactive true.

### GATE-1

- [ ] All 4 creature files load via `require()` — valid tables returned
- [ ] `chitin.lua` resolves in material registry
- [ ] Template validation passes for all creatures
- [ ] Body tree tissue layers reference existing materials
- [ ] Creatures placed in rooms — room files parse without error
- [ ] ~80 tests pass; full suite exit 0
- [ ] No engine files modified (pure data wave)

---

## WAVE-2 — Creature Generalization (Behavior + Combat)

**Goal:** Wire attack action into creature_tick. Enable NPC-as-attacker in combat. Implement predator-prey detection. All engine changes — no creature data files modified.
**Depends on:** GATE-1

### File Operations

| Op | File | Owner | Agent | LOC Δ |
|----|------|-------|-------|-------|
| MODIFY | `src/engine/creatures/init.lua` | Bart | Bart | +60–80 |
| MODIFY | `src/engine/combat/init.lua` | Bart | Bart | +30–50 |
| CREATE | `test/creatures/test-creature-combat.lua` | Nelson | Nelson | ~20 tests |
| CREATE | `test/creatures/test-predator-prey.lua` | Nelson | Nelson | ~20 tests |

### creatures/init.lua — Modifications (Bart)

**1. Predator-prey detection** — New helper `has_prey_in_room(creature, context)`: scans `get_creatures_in_room()` against `creature.combat.behavior.prey` list. Skips dead creatures.

**2. Prey target selection** — New helper `select_prey_target(context, creature)`: returns first alive creature matching prey list in same room.

**3. Attack action scoring** — In `score_actions()` (~L297): add `attack` action when `has_prey_in_room()` is true. Score = aggression + (hunger × 0.5) + jitter.

**4. Attack execution** — In `execute_action()` (~L415): new `"attack"` case calls `select_prey_target()` then `combat.run_combat(context, creature, target)`.

**5. Creature-to-creature stimulus** — After attack resolves: emit `creature_attacked` stimulus. On kill: emit `creature_died` stimulus with attacker/defender IDs.

**6. Territorial evaluation** — In `creature_tick()`: if `creature.behavior.territorial` and creature is in home territory, reduce fear and boost aggression scoring.

### combat/init.lua — Modifications (Bart)

**1. NPC response auto-select** — In `resolve_damage()` (~L259): if no player response provided, read `defender.combat.behavior.defense` (dodge/block/flee/none).

**2. NPC stance support** — In `resolve_damage()` (~L228): if attacker has `combat.behavior.stance`, apply stance modifier.

**3. NPC target zone** — In `run_combat`/`resolve_exchange`: if no player target zone, use `attacker.combat.behavior.target_priority` to drive weighted zone selection.

### TDD Scope (~40 tests)

**test-creature-combat.lua** (~20): attack action scored when prey present; not scored when no prey; execute_action calls run_combat; defender health decrements; dead state applied (alive=false, animate=false, portable=true); creature_attacked/creature_died stimuli emitted; NPC weapon selected from natural_weapons; NPC response from combat.behavior.defense; NPC zone from target_priority.

**test-predator-prey.lua** (~20): has_prey_in_room true/false/dead cases; select_prey_target returns correct creature or nil; cat hunts rat (attack scored); cat ignores wolf (no attack); wolf hunts rat + cat; same-room requirement; dead prey skipped; empty prey list safe; territorial wolf aggression boost in hallway; non-territorial creature no bonus; stimulus chain (cat kills rat → creature_died → wolf reacts).

### GATE-2

- [ ] Attack action scores correctly when prey present in room
- [ ] `execute_action("attack")` invokes `combat.run_combat` and returns messages
- [ ] Cat + rat in same room → cat attacks → rat takes damage
- [ ] Predator-prey triggers from `combat.behavior.prey` metadata
- [ ] NPC-as-attacker: `combat.run_combat(ctx, cat, rat)` succeeds
- [ ] NPC response auto-selected from `combat.behavior.defense`
- [ ] NPC target zone from `combat.behavior.target_priority`
- [ ] Territorial wolf shows aggression boost in hallway
- [ ] Dead creature: alive=false, animate=false, portable=true
- [ ] Stimuli emitted: creature_attacked, creature_died
- [ ] ~40 tests pass; full suite exit 0
- [ ] No creature data files modified (pure engine wave)

---

## Dependency Graph

```
WAVE-0 ──► GATE-0 ──► WAVE-1 ──► GATE-1 ──► WAVE-2 ──► GATE-2 ──► chunk2b
  Bart: review          Flanders: data       Bart: engine
  Bart: test/food reg   Nelson: tests        Nelson: tests
  Nelson: portals ║     Moe: rooms
  Nelson: lint    ║
```

## File Ownership Summary

| File | Owner | Wave |
|------|-------|------|
| `src/engine/creatures/init.lua` | Bart | W0 review, W2 modify |
| `src/engine/combat/init.lua` | Bart | W0 review, W2 modify |
| `test/run-tests.lua` | Nelson | W0 modify |
| `src/meta/creatures/{cat,wolf,spider,bat}.lua` | Flanders | W1 create |
| `src/meta/materials/chitin.lua` | Flanders | W1 create |
| `src/meta/rooms/{courtyard,hallway,deep-cellar,crypt}.lua` | Moe | W1 modify |
| `test/creatures/test-{cat,wolf,spider,bat}.lua` | Nelson | W1 create |
| `test/creatures/test-creature-combat.lua` | Nelson | W2 create |
| `test/creatures/test-predator-prey.lua` | Nelson | W2 create |
