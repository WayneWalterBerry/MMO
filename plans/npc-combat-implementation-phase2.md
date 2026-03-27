# NPC + Combat Phase 2 Implementation Plan

**Author:** Bart (Architect)
**Date:** 2026-03-26
**Status:** Ready for Review
**Requested By:** Wayne "Effe" Berry
**Governs:** NPC Phase 2 + Combat Phase 2 + Food PoC
**Assembled from:** 6 chunks (Pattern 2a — Chunked Plan Writing)

---
# NPC + Combat Phase 2 — Implementation Plan (Skeleton)

**Author:** Bart (Architect)  
**Date:** 2026-07-30  
**Status:** Chunk 1 of 5 — Skeleton  
**Requested By:** Wayne "Effe" Berry  
**Governs:** Phase 2: Creature Generalization → NPC Combat → Disease → Food PoC  
**Predecessor:** `plans/npc-combat-implementation-phase1.md` (Phase 1 — complete)

---

## Wave Status Tracker

| Wave | Status |
|------|--------|
| WAVE-0 | ✅ PASSED (182 tests) |
| WAVE-1 | ✅ PASSED (182 tests) |
| WAVE-2 | ✅ PASSED (184 tests) |
| WAVE-3 | ✅ PASSED (186 tests) |
| WAVE-4 | ⏳ |
| WAVE-5 | ⏳ |

---

## Section 1: Executive Summary

Phase 2 extends the NPC + Combat foundation shipped in Phase 1 (creature engine 421 LOC, combat FSM 435 LOC, 14 test files, 176 total test files) into a generalized creature ecosystem with inter-NPC combat, disease mechanics, and a food proof-of-concept.

### What We're Building

1. **New creatures** — cat, wolf, spider, bat with body_tree + combat metadata. Spider introduces chitin material.
2. **Creature generalization** — inter-creature reactions (cat chases rat), territorial behavior, NPC stimulus emission. Deferred `attack` action enters Combat FSM.
3. **NPC-vs-NPC combat** — unified combatant interface, combat witness narration, multi-combatant turn order (3+), creature morale/flee.
4. **Disease system** — generic `on_hit` disease delivery. Rabies (rat, 8% chance, incubation → death). Spider venom (100%).
5. **Food PoC** — cheese + bread, food-as-bait (rat hunger + food = lure), eat/drink verb extensions. Minimal scope.

### Why This Order

Strict dependency chain: creatures must exist (WAVE-1) before they can behave (WAVE-2), behave before they can fight each other (WAVE-3), fight before diseases can be delivered via hits (WAVE-4), and food/bait leverages creature drives from WAVE-1/2 (WAVE-5). WAVE-0 clears the runway with engine code review — Phase 1 bugs (#275-278, #264) already fixed, portal TDD (#199-208) burns down in parallel.

### Phase 1 Foundation

| Asset | Location | LOC |
|-------|----------|-----|
| Creature engine | `src/engine/creatures/init.lua` | 421 |
| Combat FSM | `src/engine/combat/init.lua` | 435 |
| Combat narration | `src/engine/combat/narration.lua` | 146 |
| Creature + combat tests | `test/creatures/` + `test/combat/` | 14 files |
| Rat + 7 injury types | `src/meta/creatures/rat.lua`, `src/meta/injuries/` | — |

### Walk-Away Capability

Same protocol as Phase 1: wave → parallel agents → gate → pass → checkpoint → next wave. Gate failure at 1× threshold. Commit/push after every gate. Nelson continuous LLM walkthroughs.

---

## Section 2: Quick Reference Table

| Wave | Name | Parallel Tracks | Gate | Key Deliverables |
|------|------|-----------------|------|------------------|
| **WAVE-0** | Pre-Flight (Review + Cleanup) | 1-2 tracks | — | Engine code review (creatures + combat LOC check), verify Phase 1 bug fixes closed |
| **WAVE-1** | Creature Data (New Creatures) | 4-5 tracks | GATE-1 | cat.lua, wolf.lua, spider.lua, bat.lua, chitin.lua material, test scaffolding |
| **WAVE-2** | Creature Generalization (Behavior) | 3-4 tracks | GATE-2 | creature `attack` → Combat FSM, creature-to-creature reactions, territorial behavior, NPC stimulus emission, predator-prey metadata |
| **WAVE-3** | NPC Combat Integration | 3-4 tracks | GATE-3 | NPC-vs-NPC combat (unified combatant interface), combat witness narration, multi-combatant turn order, creature morale/flee |
| **WAVE-4** | Disease System | 3 tracks | GATE-4 | Generic on_hit disease delivery, rabies injury type, spider venom injury type, injury system integration |
| **WAVE-5** | Food PoC + Polish | 3 tracks | GATE-5 | cheese.lua, bread.lua, food-as-bait mechanic, eat/drink verb extensions, Nelson final LLM walkthrough, Brockman Phase 2 docs |

**Estimated new files:** ~20-25 (code + tests) + 6-8 doc files  
**Estimated modified files:** ~12-15 (engine modules, verbs, test runner)  
**Estimated scope:** 6 waves (WAVE-0 through WAVE-5), 5 gates

---

## Section 3: Dependency Graph

```
WAVE-0: Pre-Flight (Review + Cleanup)
├── [Bart]     Engine code review (creatures 421 LOC, combat 435 LOC)
└── [Nelson]   Verify Phase 1 bug fixes (#275-278, #264)
        │
        ▼  ── (no formal gate — review findings filed, bugs confirmed) ──
        │
WAVE-1: Creature Data (New Creatures)
├── [Flanders] cat.lua, wolf.lua, spider.lua, bat.lua ┐
├── [Flanders] chitin.lua material                     │ parallel
└── [Nelson]   test/creatures/ scaffolding             ┘
        │
        ▼  ── GATE-1 (creatures load, body_tree resolves, chitin registered) ──
        │
WAVE-2: Creature Generalization (Behavior)
├── [Bart]     creatures/init.lua: attack → Combat FSM,┐
│              reactions, territorial, predator-prey    │ parallel
├── [Bart]     NPC stimulus emission points             │
├── [Nelson]   behavior tests + smoke LLM              ┘
        │
        ▼  ── GATE-2 (reactions fire, territory works, stimulus propagates) ──
        │
WAVE-3: NPC Combat Integration
├── [Bart]     combat/init.lua: unified combatant,     ┐
│              NPC-vs-NPC, multi-combatant turn order   │
├── [Bart]     creature morale + flee                   │ parallel
├── [Smithers] combat witness narration                 │
├── [Nelson]   NPC combat tests + LLM walkthrough      ┘
        │
        ▼  ── GATE-3 (NPC combat resolves, witness narration, morale/flee) ──
        │
        │  ═══ NPC COMBAT SHIPS (Brockman docs parallel) ═══
        │
WAVE-4: Disease System
├── [Bart]     Generic on_hit disease delivery         ┐
├── [Flanders] rabies.lua (8%, incubation → death)     │ parallel
├── [Flanders] spider-venom.lua (100% on hit)          │
└── [Nelson]   disease tests                           ┘
        │
        ▼  ── GATE-4 (disease fires on hit, rabies timeline, venom applies) ──
        │
WAVE-5: Food PoC + Polish
├── [Flanders] cheese.lua + bread.lua                  ┐
├── [Bart]     food-as-bait (hunger drive + stimulus)  │ parallel
├── [Smithers] eat/drink verb extensions               │
├── [Brockman] Phase 2 docs (4 architecture files)     │
└── [Nelson]   final LLM walkthrough                   ┘
        │
        ▼  ── GATE-5 (food works, bait lures, docs complete, ZERO regressions) ──
        │
        ═══ PHASE 2 COMPLETE ═══
```

### Key Dependency Chain

```
Phase 1 ──→ W0 (review) ──→ W1 (data) ──→ W2 (behavior) ──→ W3 (NPC combat)
                                                                    │
                                                        ┌───────────┤
                                                        ▼           ▼
                                                  W4 (disease)  W5 (food)
                                                        └─────┬─────┘
                                                              ▼
                                                    GATE-5 (Phase 2 done)
```

Portal TDD (#199-208) burns down in parallel — not blocking Phase 2 waves.

### File Ownership Constraints

No two agents touch the same file in any wave. Key ownership:

| File | Owner | Waves |
|------|-------|-------|
| `src/engine/creatures/init.lua` | Bart | WAVE-2 |
| `src/engine/combat/init.lua` | Bart | WAVE-3 |
| `src/engine/combat/narration.lua` | Smithers | WAVE-3 |
| `src/meta/creatures/*.lua` (new) | Flanders | WAVE-1 |
| `src/meta/injuries/*.lua` (new) | Flanders | WAVE-4 |
| `src/engine/verbs/init.lua` | Smithers | WAVE-5 |
| `test/creatures/*.lua` (new) | Nelson | WAVE-1, WAVE-2 |
| `test/combat/*.lua` (new) | Nelson | WAVE-3 |
| `test/injuries/*.lua` (new) | Nelson | WAVE-4 |

---

*Chunk 1 complete. Chunks 2-5 will add: Implementation Waves (detailed), Testing Gates, Feature Breakdown, and Operations.*

---

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

### Pre-WAVE-0: Module Split Plan (Chalmers review fix)

**Problem:** `creatures/init.lua` (483 LOC) is modified in both WAVE-2 (+60-80 LOC) and WAVE-5 (+60-80 LOC), risking merge conflicts and exceeding the 500 LOC threshold. `combat/init.lua` (487 LOC) gains +80 LOC, also exceeding 500 LOC.

**Decision: Option A — Extract stimulus + predator-prey before WAVE-2.**

Bart performs these extractions during WAVE-0 (before any feature work begins):

| Extract From | New Module | Est. LOC | Rationale |
|-------------|-----------|---------|-----------|
| `creatures/init.lua` | `src/engine/creatures/stimulus.lua` | ~80 | Creature-to-creature stimulus emission + processing. Clear interface boundary. |
| `creatures/init.lua` | `src/engine/creatures/predator-prey.lua` | ~60 | Prey detection, predator reaction, source_filter evaluation. |
| `combat/init.lua` | `src/engine/combat/npc-behavior.lua` | ~50 | NPC response auto-select, NPC stance, NPC target zone. |

**Post-split sizes:**
- `creatures/init.lua`: ~343 LOC (483 - 140) + WAVE-2 adds ~40 (attack action only) = ~383 LOC ✅
- `creatures/stimulus.lua`: ~80 LOC + WAVE-2 adds ~20 = ~100 LOC ✅
- `creatures/predator-prey.lua`: ~60 LOC (stable after WAVE-2) ✅
- `combat/init.lua`: ~437 LOC (487 - 50) + WAVE-3 adds ~30 = ~467 LOC ✅
- `combat/npc-behavior.lua`: ~50 LOC + WAVE-3 adds ~30 = ~80 LOC ✅
- WAVE-5 bait mechanic goes in `creatures/init.lua` (~40 LOC) → ~423 LOC total ✅

**File conflict resolution:** WAVE-2 modifies `creatures/init.lua` (attack action), `stimulus.lua` (creature stimuli), and `predator-prey.lua` (detection). WAVE-5 modifies only `creatures/init.lua` (hunger/bait). No file touched by both WAVE-2 and WAVE-5 for the same subsystem. Merge conflict risk eliminated.

**Timing:** Split happens during WAVE-0 code review (Bart). Committed before GATE-0. All existing tests must pass post-split.

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
- [ ] Module split completed: `stimulus.lua`, `predator-prey.lua`, `npc-behavior.lua` extracted (Chalmers fix)
- [ ] `test/food/` discovered by `lua test/run-tests.lua`
- [ ] Full test suite passes (exit 0)
- [ ] Portal TDD (#199–#208) progress tracked (independent of GATE-0)
- [ ] Lint (#249, #250) addressed or in-progress
- [ ] Phase 1 performance baseline measured and recorded (Marge fix)
- [ ] Tissue material audit: hide, flesh, bone, tooth_enamel, keratin verified or flagged for WAVE-1 creation (Flanders fix)
- [ ] **GATE-0 committed + tagged** before WAVE-1 begins (Marge enforcement fix)

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
- body_tree: cephalothorax (vital), abdomen (vital), legs (grouped as single node — 8 legs treated as one hit zone for simplicity; tissue: chitin shell)
- States: alive-idle, alive-web-building, alive-flee, dead
- Behavior: aggression 10, flee_threshold 60, web_builder true
- Drives: hunger 20 (+1/tick), fear 10, curiosity 10
- Combat: speed 5, weapons — bite (pierce, tooth-enamel, force 1, on_hit: venom effect 60% chance); natural_armor: chitin coverage cephalothorax/abdomen
- Health: 3/3
- **Telegraphing (CBG/Flanders review fix):**
  - `on_listen` (spider room, dark or lit): *"Faint scratching, like tiny claws on stone."*
  - `on_feel` (when player touches web strands): *"You brush sticky silk. Something large moves nearby."*
  - Spider emits `creature_vocalizes` stimulus on player entry: faint hissing sound
  - Web presence in room provides pre-encounter sensory warning before combat

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

### GUID Reservation (Flanders review fix)

Before WAVE-1 kicks off, pre-assign GUIDs for all new objects to avoid collision and enable cross-file references during parallel creation:

| Object | GUID Status | Notes |
|--------|-------------|-------|
| `cat.lua` | TBD — generate before WAVE-1 | Flanders generates via `powershell -c "[guid]::NewGuid()"` |
| `wolf.lua` | TBD — generate before WAVE-1 | |
| `spider.lua` | TBD — generate before WAVE-1 | |
| `bat.lua` | TBD — generate before WAVE-1 | |
| `chitin.lua` | TBD — generate before WAVE-1 | |

**Process:** Flanders generates 5 UUIDs, records them in the creature `.lua` file `guid` fields, and shares with Moe (for room `type_id` references) before parallel work begins. No GUID pool file needed — GUIDs live in the `.lua` source files (Principle 1: code IS the definition).

### Embedding Index Update (Smithers review fix)

**Owner:** Nelson (WAVE-1)
**Task:** After creature files are created, update `assets/parser/embedding-index.json` with new creature/food noun embeddings so Tier 2 semantic matching resolves "animal", "creature", "food" queries to the correct objects.
**Scope:** Add entries for: cat, wolf, spider, bat, cheese, bread, spider-web.
**Gate check:** GATE-1 verifies new keywords appear in embedding index. If deferred, document impact on Tier 2 matching.

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

### Cross-Wave Compatibility Check: WAVE-1→2 (Marge review fix)

**CREATE** `test/creatures/test-wave1-2-compat.lua` (~10 tests)
Run AFTER GATE-1 passes, BEFORE WAVE-2 implementation begins. Validates that WAVE-1 creature data is compatible with WAVE-2 engine expectations:
- Load real `cat.lua` + `rat.lua`; verify `combat.behavior` fields exist for `score_actions()`
- Verify `combat.natural_weapons` structure matches what `resolve_exchange()` expects
- Verify `behavior.prey` array is parseable by predator-prey detection
- Verify `on_hit` field structure on rat bite weapon is compatible with WAVE-4 disease delivery
- **Owner:** Nelson. **SLA:** run within 30 min of GATE-1 pass.

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

### Cross-Wave Compatibility Check: WAVE-2→3 (Marge review fix)

**CREATE** `test/combat/test-wave2-3-compat.lua` (~10 tests)
Run AFTER GATE-2 passes, BEFORE WAVE-3 implementation begins. Validates that WAVE-2 creature attack/combat integration is compatible with WAVE-3 NPC-vs-NPC expectations:
- Verify `creatures.execute_action("attack", target)` completes without error and sets combat state
- Verify `resolve_exchange()` accepts NPC as both attacker and defender
- Verify `on_hit` field structure on weapons is compatible with WAVE-4 disease delivery
- **Owner:** Nelson. **SLA:** run within 30 min of GATE-2 pass.

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
| `src/engine/creatures/init.lua` | Bart | W0 review + split, W2 modify |
| `src/engine/creatures/stimulus.lua` | Bart | W0 create (split), W2 modify |
| `src/engine/creatures/predator-prey.lua` | Bart | W0 create (split), W2 modify |
| `src/engine/combat/init.lua` | Bart | W0 review, W2 modify |
| `src/engine/combat/npc-behavior.lua` | Bart | W0 create (split), W3 modify |
| `test/run-tests.lua` | Nelson | W0 modify |
| `src/meta/creatures/{cat,wolf,spider,bat}.lua` | Flanders | W1 create |
| `src/meta/materials/chitin.lua` | Flanders | W1 create |
| `src/meta/rooms/{courtyard,hallway,deep-cellar,crypt}.lua` | Moe | W1 modify |
| `test/creatures/test-{cat,wolf,spider,bat}.lua` | Nelson | W1 create |
| `test/creatures/test-creature-combat.lua` | Nelson | W2 create |
| `test/creatures/test-predator-prey.lua` | Nelson | W2 create |

---

# NPC + Combat Phase 2 — Chunk 2b: Waves 3–5 (Late)

**Author:** Bart (Architect) · **Date:** 2026-07-30
**Chunk:** 2b of 5 — WAVE-3 (NPC Combat), WAVE-4 (Disease), WAVE-5 (Food PoC)
**Refs:** `plans/combat-system-plan.md` §10, `resources/research/food/food-integration-notes.md`

---

## WAVE-3: NPC Combat Integration

**Depends on:** GATE-2 passed

| Track | Agent | Scope |
|-------|-------|-------|
| 3A | **Bart** | NPC-vs-NPC combat resolution, multi-combatant turn order |
| 3B | **Bart** | Creature morale — `flee_threshold`, cornered fallback |
| 3C | **Smithers** | Combat witness narration (light-dependent) |
| 3D | **Nelson** | Tests + LLM scenario |
| 3E | **Brockman** | NPC combat architecture doc |

### 3A — NPC-vs-NPC Combat (Bart)

**MODIFY** `src/engine/combat/init.lua`

- Extend `resolve_exchange()` for NPC combatants — same `body_tree` → zone → tissue-layer pipeline.
- `context.active_fights` tracking: `{ id, combatants, room_id, round }`. Full FSM phases apply.
- **Turn order** (3+ participants): speed (highest first) → size tiebreak (smaller first) → player last among equals.
- Pairwise resolution: 3-way = 2 exchange cycles/round (priority queue, per R-2).
- NPC target: `prey` list from metadata; fallback to `aggression` threshold.

### 3B — Creature Morale (Bart)

**MODIFY** `src/engine/creatures/init.lua`

- `flee_threshold` check after every RESOLVE phase. `health/max_health < threshold` → flee via random valid exit. Combat entry updated, narration emitted.
- **Cornered fallback:** no valid exits → `cornered` stance, `attack × 1.5`, cannot flee.
- Per-creature thresholds: rat 0.3, cat 0.4, wolf 0.2, spider 0.1 (in creature `.lua` by Flanders).

### 3C — Witness Narration (Smithers)

**MODIFY** `src/engine/combat/narration.lua`

- **Same room + light:** full visual, third-person framing via `narration.describe_exchange()`.
- **Same room + dark:** audio-only keyed to severity (GRAZE→scuffle, HIT→yelps, CRITICAL→death).
- **Adjacent room:** distant audio, 1 line max.
- **Out of range:** nothing emitted.
- Cap per R-9: 2 lines/exchange (same room), 1 line (adjacent), ≤6 lines/round.
- **Narration budget protocol (CBG blocker fix):**
  - Smithers implements `narration_budget` counter per combat round (init 0, cap 6).
  - Each `narration.emit()` call increments counter.
  - When budget reached: suppress non-critical narration (GRAZE/DEFLECT) but always keep critical (HIT/CRITICAL/DEATH).
  - Overflow narration deferred to next round with marker: *"[The melee continues...]"*
  - Player's own combat action narration is **exempt** from the cap (always shown).
  - Morale break narration counts toward cap (1 line each).
  - GATE-3 acceptance criteria: "3-creature fight produces ≤6 NPC narration lines/round."

### 3D — Tests (Nelson)

**CREATE** `test/combat/test-npc-combat.lua` (~25 tests)
Cat-kills-rat resolution, turn order (speed/size/player tiebreak), `active_fights` lifecycle, NPC target selection (prey + aggression fallback), multi-combatant no-infinite-loop, player joins active fight, morale flee success/fail, cornered fallback bonus, dead creature mutation.

**CREATE** `test/combat/test-witness-narration.lua` (~15 tests)
Lit visual narration, dark audio-only, adjacent distant, out-of-range silence, line cap enforcement, severity scaling, third-person framing.

**LLM scenario:** Player watches cat kill rat — `look` → `wait` → witness narration → `wait` → rat dies → `look at dead rat` confirms mutation.

### 3E — Docs (Brockman)

**CREATE** `docs/architecture/combat/npc-combat.md` — NPC resolution flow, combatant interface, turn order algorithm, `active_fights`, morale/flee, witness narration tiers.

### File Ownership — WAVE-3

| File | Action | Owner |
|------|--------|-------|
| `src/engine/combat/init.lua` | MODIFY | Bart |
| `src/engine/creatures/init.lua` | MODIFY | Bart |
| `src/engine/combat/narration.lua` | MODIFY | Smithers |
| `test/combat/test-npc-combat.lua` | CREATE | Nelson |
| `test/combat/test-witness-narration.lua` | CREATE | Nelson |
| `docs/architecture/combat/npc-combat.md` | CREATE | Brockman |

### GATE-3

All ~40 new tests pass. `test/run-tests.lua` zero regressions. LLM cat-kills-rat passes. Doc exists. Multi-combatant order verified (3+ creatures, fixed seed `math.randomseed(42)`). `git diff --stat` clean. **~50 tests total.**

### Cross-Wave Compatibility Check: WAVE-3→4 (Marge review fix)

**CREATE** `test/injuries/test-wave3-4-compat.lua` (~10 tests)
Run AFTER GATE-3 passes, BEFORE WAVE-4 implementation begins. Validates that WAVE-3 combat resolution is compatible with WAVE-4 disease delivery:
- Verify `combat.run_combat()` accepts creature as attacker and calls `resolve_exchange()`
- Verify `resolve_exchange()` checks for `on_hit` field on weapons (even if delivery not yet implemented)
- Verify `restricts` flag structure is present on injury definitions and compatible with verb dispatch
- **Owner:** Nelson. **SLA:** run within 30 min of GATE-3 pass.

---

## WAVE-4: Disease System

**Depends on:** GATE-3 passed

| Track | Agent | Scope |
|-------|-------|-------|
| 4A | **Flanders** | Rabies injury FSM definition |
| 4B | **Flanders** | Spider venom injury FSM definition |
| 4C | **Bart** | Generic `on_hit` disease delivery in combat |
| 4D | **Bart** | Disease progression FSM + `hidden_until_state` in injuries engine |
| 4E | **Nelson** | Disease test files |

### 4A — Rabies (Flanders)

**CREATE** `src/meta/injuries/rabies.lua`

`category = "disease"`, `hidden_until_state = "prodromal"` (silent incubation).
FSM: `incubating`(15t, 0 dmg) → `prodromal`(10t, 1 dmg, restricts `precise_actions`) → `furious`(8t, 3 dmg, restricts `drink`+`precise_actions`) → `fatal`(1t, lethal).
`curable_in = {"incubating", "prodromal"}`. `transmission.probability = 0.08`.

### 4B — Spider Venom (Flanders)

**CREATE** `src/meta/injuries/spider-venom.lua`

`category = "disease"`, no hidden state (immediate symptoms).
FSM: `injected`(3t, 2 dmg) → `spreading`(5t, 3 dmg, restricts `movement`) → `paralysis`(8t, 1 dmg, restricts `movement`+`attack`+`precise_actions`).
`curable_in = {"injected", "spreading"}`. `transmission.probability = 1.0`.

### 4C — on_hit Disease Delivery (Bart)

**MODIFY** `src/engine/combat/init.lua`

After `resolve_exchange()` at severity ≥ HIT: check attacker's `natural_weapon.on_hit = { inflict = "disease_id", probability = N }`. Roll `math.random()` → call `injuries.inflict(target, disease_id)`. Fully generic — no creature-specific engine code (Principle 8). Symmetric for player-vs-NPC and NPC-vs-NPC.

### 4D — Disease Progression FSM (Bart)

**MODIFY** `src/engine/injuries.lua`

- `injuries.tick()` handles `category = "disease"`: decrement `state_turns_remaining`, transition per `transitions` table, apply `damage_per_tick`, emit `message`.
- **`hidden_until_state`:** suppress messages/visibility until state reached.
- **Healing:** `injuries.heal()` checks `curable_in`. Outside list → *"The treatment has no effect."*
- **`restricts`:** `injuries.get_restrictions(player)` returns merged set. Verb dispatcher checks before execution.
- Budget: <10ms for 5 concurrent diseases.

### 4E — Tests (Nelson)

**CREATE** `test/injuries/test-disease-delivery.lua` (~15 tests)
Prob 1.0 always delivers, 0.08 rate verified (fixed seed ±4), DEFLECT/GRAZE don't deliver, NPC-vs-NPC delivery, no `on_hit` → no error, concurrent diseases tick independently.

**CREATE** `test/injuries/test-rabies.lua` (~15 tests)
Incubation hidden, transitions at 15/25/33 ticks, `drink` blocked in furious, fatal kills, early cure works (incubating/prodromal), late cure fails (furious), `compute_health()` reflects disease damage, rabies + wound coexist.

**CREATE** `test/injuries/test-spider-venom.lua` (~15 tests)
Immediate symptoms, transitions at 3/8 ticks, movement/attack restrictions, cure in/out of window, venom + rabies independent.

### File Ownership — WAVE-4

| File | Action | Owner |
|------|--------|-------|
| `src/meta/injuries/rabies.lua` | CREATE | Flanders |
| `src/meta/injuries/spider-venom.lua` | CREATE | Flanders |
| `src/engine/combat/init.lua` | MODIFY | Bart |
| `src/engine/injuries.lua` | MODIFY | Bart |
| `test/injuries/test-disease-delivery.lua` | CREATE | Nelson |
| `test/injuries/test-rabies.lua` | CREATE | Nelson |
| `test/injuries/test-spider-venom.lua` | CREATE | Nelson |

### GATE-4

All ~45 new tests pass. `test/run-tests.lua` zero regressions. Rabies full FSM verified. Venom full FSM verified. `hidden_until_state` confirmed. Healing early/late verified. Concurrent diseases work. `git diff --stat` clean. **~45 tests total.**

---

## WAVE-5: Food Proof-of-Concept + Polish

**Depends on:** GATE-4 passed. Also uses creature behavior from WAVE-2 (hunger drive, stimulus).

| Track | Agent | Scope |
|-------|-------|-------|
| 5A | **Flanders** | Food objects: cheese, bread |
| 5B | **Smithers** | Eat/drink verb extensions |
| 5C | **Bart** | Bait mechanic (hunger drive + food stimulus) |
| 5D | **Nelson** | Tests + LLM end-to-end walkthrough |
| 5E | **Brockman** | Food system PoC doc |

### 5A — Food Objects (Flanders)

**CREATE** `src/meta/objects/cheese.lua`
Template `small-item`. Keywords `{"cheese","wedge","food"}`. Material `cheese`. `food = { edible=true, nutrition=20, bait_value=3, bait_targets={"rat","bat"} }`. FSM: `fresh`(30t) → `stale`(20t) → `spoiled`. All sensory fields including `on_feel`.

**CREATE** `src/meta/objects/bread.lua`
Template `small-item`. Keywords `{"bread","crust","food"}`. Material `bread`. `food = { edible=true, nutrition=15, bait_value=2, bait_targets={"rat"} }`. FSM: `fresh`(20t) → `stale`. All sensory fields including `on_feel`.

### 5B — Eat/Drink Verbs (Smithers)

**MODIFY** `src/engine/verbs/survival.lua`

- `eat`: find by keyword → check `food.edible` → check `restricts` → consume (remove from inventory/registry) → apply `food.nutrition` → emit `on_taste`.
- `drink`: same pattern, check `restricts.drink` (rabies blocks).
- Non-food: *"You can't eat that."* Spoiled: warning message.
- Aliases: `eat`/`consume`/`devour`, `drink`/`sip`/`quaff`.

**MODIFY** `src/engine/verbs/init.lua` — ensure survival module registered with eat/drink aliases.

### 5C — Bait Mechanic (Bart)

**MODIFY** `src/engine/creatures/init.lua`

- Creature tick gains hunger drive: `hunger_level` increments per tick, checks `hunger_threshold`.
- When hungry + food with matching `bait_targets` in same/adjacent room: creature moves toward food → consumes it (object removed, hunger reset).
- Narration: *"The rat scurries toward the cheese and devours it."*
- Bait priority: higher `bait_value` first. In-combat suppresses hunger.
- **Hard boundary (R-5):** no cooking, recipes, or spoilage-driven creature behavior.

### 5D — Tests + LLM (Nelson)

**CREATE** `test/food/test-eat-drink.lua` (~15 tests)
Eat cheese/bread consumed + nutrition, eat non-food rejected, eat without holding, eat in dark works, drink blocked by rabies, spoiled food warning, consume removes from registry, keyword disambiguation.

**CREATE** `test/food/test-bait.lua` (~10 tests)
Drop food + rat approaches, rat consumes food, adjacent room movement, `bait_value` priority, in-combat suppression, non-matching targets ignored, narration emitted, multi-creature eval.

**LLM end-to-end:** bedroom → feel nightstand → take candle → light → navigate to cellar → see rat → attack rat → check rabies → find cheese → drop as bait → rat approaches → eat bread → nutrition applied. Validates full WAVE-1–5 chain.

### 5E — Docs (Brockman)

**CREATE** `docs/design/food-system.md` — food metadata, eat/drink verbs, bait mechanic, PoC scope, refs to food-integration-notes for future expansion.

### File Ownership — WAVE-5

| File | Action | Owner |
|------|--------|-------|
| `src/meta/objects/cheese.lua` | CREATE | Flanders |
| `src/meta/objects/bread.lua` | CREATE | Flanders |
| `src/engine/verbs/survival.lua` | MODIFY | Smithers |
| `src/engine/verbs/init.lua` | MODIFY | Smithers |
| `src/engine/creatures/init.lua` | MODIFY | Bart |
| `test/food/test-eat-drink.lua` | CREATE | Nelson |
| `test/food/test-bait.lua` | CREATE | Nelson |
| `docs/design/food-system.md` | CREATE | Brockman |

### GATE-5

All ~25 new tests pass. `test/run-tests.lua` zero regressions (full baseline). LLM end-to-end passes. Doc exists. Food objects load with all required fields (including `on_feel`). Eat/drink works. Bait triggers rat approach. Rabies blocks drink (cross-wave). `git diff --stat` clean. **~35 tests + LLM.**

---

## Cross-Wave File Map

| File | W-3 | W-4 | W-5 | Owner |
|------|-----|-----|-----|-------|
| `src/engine/combat/init.lua` | 3A | 4C | — | Bart |
| `src/engine/creatures/init.lua` | 3B | — | 5C | Bart |
| `src/engine/injuries.lua` | — | 4D | — | Bart |
| `src/engine/combat/narration.lua` | 3C | — | — | Smithers |
| `src/engine/verbs/survival.lua` | — | — | 5B | Smithers |

No file modified by two agents in same wave. Gates enforce sequential completion.

**Totals:** 13 new files · 5 modified · ~130 tests · 3 LLM scenarios

---

# NPC + Combat Phase 2 — Chunk 3: Gates + Testing

**Author:** Bart (Architect)  
**Date:** 2026-07-28  
**Chunk:** 3 of 5 — Testing Gates, Nelson LLM Scenarios, TDD Test File Map  
**Scope:** Phase 2 = Creature Variety + Disease + Food/Bait  
**Reference:** `plans/npc-combat-implementation-phase1.md` (Phase 1), `plans/combat-system-plan.md` (design), `plans/npc-system-plan.md` (NPC design)

---

## Section 1: Testing Gates

### GATE-0: Pre-Flight (Infrastructure)

**After:** WAVE-0 completes  
**Tests that must pass:**

- `lua test/run-tests.lua` — zero regressions across all existing test files
- New directories registered: `test/creatures/`, `test/combat/`, `test/food/`, `test/scenarios/`
- No engine file exceeds 500 LOC (checked via `wc -l` or Lua line-count script)

**Specific checks:**

| Check | Method | Pass Criteria |
|-------|--------|---------------|
| Test dirs registered | `test/run-tests.lua` discovers new dirs without error | Runner finds 0 files in new dirs (no crash) |
| LOC guard | `wc -l src/engine/**/*.lua` | Every file < 500 lines (post-module-split) |
| No regressions | `lua test/run-tests.lua` | All existing tests pass |
| Module split verified | `ls src/engine/creatures/stimulus.lua src/engine/creatures/predator-prey.lua src/engine/combat/npc-behavior.lua` | All 3 extracted modules exist (Chalmers fix) |
| Performance baseline | `test/creatures/test-phase1-baseline.lua` — `os.clock()` benchmark creature tick + combat resolution | Recorded. Sets GATE-2 budget = baseline + 20% margin (Marge fix) |
| Tissue material audit | `grep -r "hide\|flesh\|bone\|tooth_enamel\|keratin" src/meta/materials/` | All 5 tissue materials exist OR creation added to WAVE-1 (Flanders fix) |

**Pass/fail:** ALL checks pass. Binary.  
**Reviewer:** Bart (architecture)  
**Action on fail:** Fix before proceeding — pre-flight is blocking.

**On pass:** `git add -A && git commit -m "GATE-0: preflight passed — baseline measured, LOC guard verified" && git tag phase2-gate-0 && git push`  
**GATE-0 is enforced** — WAVE-1 cannot begin without the `phase2-gate-0` tag in git history.

---

### GATE-1: Creature Definitions (4 Creatures Load + Validate)

**After:** WAVE-1 completes  
**Tests that must pass:**

- `lua test/creatures/test-cat.lua` — all assertions green
- `lua test/creatures/test-wolf.lua` — all assertions green
- `lua test/creatures/test-spider.lua` — all assertions green
- `lua test/creatures/test-rat-phase2.lua` — rat updates validate (body_tree, combat metadata additions)
- `lua test/creatures/test-creature-materials.lua` — chitin, hide, tooth_enamel, keratin resolve through material registry
- `lua test/run-tests.lua` — zero regressions in ALL existing tests (Phase 1 creature/combat tests still pass)

**Specific assertions:**

| Creature | Required Fields | Key Validations |
|----------|----------------|-----------------|
| Cat | `animate=true`, `template="creature"`, `behavior.prey={"rat"}`, `body_tree` with head/body/legs/tail | Keywords include "cat", "feline"; size is string `"small"`; `on_feel` present |
| Wolf | `animate=true`, `behavior.aggression >= 70`, `body_tree` with head/body/legs | Keywords include "wolf"; size `"medium"`; `combat.natural_weapons` includes bite; `can_open_doors=false` |
| Spider | `animate=true`, `behavior.ambush=true`, `body_tree` with body/legs | Keywords include "spider"; size `"tiny"`; `combat.natural_weapons` bite has `on_hit.inflict="spider-venom"` |
| Rat (updated) | `combat` table added, `body_tree` present | `combat.natural_weapons` bite has `on_hit.inflict="rabies"` with `probability=0.08` |

**Material resolution checks:**

- `chitin` — spider exoskeleton, hardness > flesh, `natural_armor` use
- `hide` — animal outer layer, shear_resistance > skin
- `tooth_enamel` — natural weapon material for bites
- `keratin` — claws/nails material

**Pass/fail:** ALL creature files load via `dofile()`. ALL fields validate against creature template. ALL materials resolve. Zero regressions. Binary.  
**Reviewer:** Bart (architecture), Marge (test sign-off)  
**Action on fail:** File issue, assign to Flanders (creature data) or Nelson (test fix), re-gate.

**On pass:** `git add -A && git commit -m "GATE-1: Phase 2 creature definitions — 4 creatures + materials validated" && git push`

---

### GATE-2: Creature Attack + Predator-Prey + Stimulus

**After:** WAVE-2 completes  
**Tests that must pass:**

- `lua test/creatures/test-creature-combat.lua` — creature attack action works
- `lua test/creatures/test-predator-prey.lua` — predator-prey trigger fires when cat and rat share a room
- `lua test/creatures/test-creature-stimulus.lua` — creature-to-creature stimulus emission + reception
- `lua test/run-tests.lua` — zero regressions

**Specific assertions:**

| Test Case | Input | Expected |
|-----------|-------|----------|
| Cat sees rat → chase | Cat + rat in same room, creature tick | Cat's fear_delta doesn't spike; cat selects "chase" action targeting rat |
| Rat detects cat → flee | Rat has `predator={"cat"}`, cat enters room | Rat's fear spikes above `flee_threshold`; rat selects "flee" action |
| Wolf sees player → attack | Wolf in room, player enters, wolf aggression ≥ 70 | Wolf selects "attack" action targeting player |
| Spider in web → wait | Spider in room with web, player enters | Spider does NOT attack; web triggers trap check |
| Stimulus propagation | Cat kills rat in room A; player in room A | Player receives `creature_died` stimulus message |
| Cross-room stimulus | Loud creature event in room B; player in room A (adjacent) | Player receives sound-range stimulus (if sound_range ≥ 1) |

**Performance budget:** Creature tick completes in <50ms for 10 mock creatures (all 4 types × 2 + 2 rats). Nelson measures via `os.clock()` before/after `creatures.tick(context)`.

**Pass/fail:** ALL tests pass, zero regressions, perf budget met. Binary.  
**Reviewer:** Bart (architecture), Marge (test sign-off)

**On pass:** `git add -A && git commit -m "GATE-2: Phase 2 creature combat + predator-prey validated" && git push`

---

### GATE-3: NPC-vs-NPC Combat + Witness Narration

**After:** WAVE-3 completes  
**Tests that must pass:**

- `lua test/combat/test-npc-combat.lua` — NPC-vs-NPC combat resolves through unified `resolve_exchange()`
- `lua test/combat/test-witness-narration.lua` — player witness narration generates correct output
- `lua test/combat/test-multi-combatant.lua` — turn order with 3+ participants
- `lua test/run-tests.lua` — zero regressions

**Specific assertions:**

| Test Case | Input | Expected |
|-----------|-------|----------|
| Cat kills rat | Cat (attack) vs rat (flee), `math.randomseed(42)` | Combat resolves: cat wins, rat mutates to dead-rat, narration generated |
| Turn order: speed-based | Wolf (speed=2), rat (speed=3), cat (speed=2) | Rat acts first (fastest), then wolf/cat by size tiebreak (smaller first) |
| Multi-combatant: 3 creatures | Cat + rat + wolf in same room | Each creature selects target based on prey/aggression metadata; no infinite loops |
| Witness narration: lit room | Player in room, cat kills rat, light present | Player sees: visual combat narration ("The cat pounces on the rat...") |
| Witness narration: dark room | Same combat, no light | Player hears: audio-only narration ("You hear hissing, then a shriek cut short.") |
| Witness narration: adjacent room | Combat in next room, player sound_range covers it | Player hears: distant sound ("From the next room, you hear scrabbling and a sharp squeal.") |
| NPC morale/flee | Rat at low health vs cat | Rat attempts flee; if successful, exits room; combat ends |
| Player intervention | Player types "attack cat" during cat-vs-rat combat | Player joins as third combatant; turn order recalculated |

**Documentation deliverables that must exist:**

- `docs/architecture/combat/npc-combat.md` — NPC-vs-NPC resolution, witness system
- `docs/architecture/engine/predator-prey.md` — predator-prey metadata and trigger logic
- `docs/design/creature-combat-profiles.md` — wolf, cat, spider, rat combat behavior specs

**Pass/fail:** ALL unit tests pass. All 3 docs exist. Zero regressions. Binary.  
**Reviewer:** Bart (architecture), Nelson (gate signer), Marge (test sign-off)

**On pass:** `git add -A && git commit -m "GATE-3: Phase 2 NPC-vs-NPC combat + witness narration" && git push`

---

### GATE-4: Disease Delivery + Rabies + Venom + Injury Integration

**After:** WAVE-4 completes  
**Tests that must pass:**

- `lua test/injuries/test-disease-delivery.lua` — `on_hit` disease mechanism works generically
- `lua test/injuries/test-rabies.lua` — rabies incubation → prodromal → furious → fatal progression
- `lua test/injuries/test-spider-venom.lua` — spider venom infliction and effect progression
- `lua test/injuries/test-disease-healing.lua` — poultice cures rabies in early stages only
- `lua test/run-tests.lua` — zero regressions

**Specific assertions:**

| Test Case | Input | Expected |
|-----------|-------|----------|
| Rabies delivery: 8% chance | Rat bites player 100 times with `math.randomseed(42)` | ~8 infections (±4 tolerance); `injuries.inflict("rabies")` called |
| Rabies incubation | Player infected, 15 ticks pass | State transitions: `incubating` → `prodromal`; message "You feel feverish..." |
| Rabies hydrophobia | Rabies reaches `furious` state | `restricts.drink = true`; player cannot use `drink` verb |
| Rabies terminal | Rabies reaches `fatal` state | Death message emitted; player dies |
| Rabies early cure | Apply healing-poultice during `incubating` | Rabies cured; injury removed |
| Rabies late cure fails | Apply healing-poultice during `furious` | No effect; rabies continues |
| Venom delivery: 100% | Spider bites player once | `injuries.inflict("spider-venom")` called; always fires (no probability) |
| Venom progression | Spider venom ticks | Damage per tick applied; movement restriction after threshold |
| Disease via NPC combat | Cat bites rat (rat carries rabies) | Disease check runs for NPC targets too (not player-only) |
| Injury system integration | Rabies damage ticks | `injuries.compute_health()` reflects accumulated damage; health decreases |

**Performance budget:** Disease tick (all active injuries) resolves in <10ms for 5 concurrent diseases.

**Pass/fail:** ALL tests pass, zero regressions, perf budget met. Binary.  
**Reviewer:** Bart (architecture), Marge (test sign-off)  
**Action on fail:** File issue, assign to Flanders (injury definitions) or Bart (engine integration), re-gate.

**On pass:** `git add -A && git commit -m "GATE-4: Phase 2 disease delivery — rabies + venom + healing" && git push`

---

### GATE-5: Food + Eat/Drink + Bait + Full LLM Walkthrough

**After:** WAVE-5 completes  
**Tests that must pass:**

- `lua test/food/test-eat-drink.lua` — eat and drink verbs work on food objects
- `lua test/food/test-bait.lua` — bait mechanic triggers creature approach
- `lua test/food/test-food-objects.lua` — all food items load and validate
- `lua test/integration/test-phase2-integration.lua` — multi-command end-to-end scenario
- `lua test/run-tests.lua` — zero regressions (ALL Phase 1 + Phase 2 tests pass)

**Specific assertions:**

| Test Case | Input | Expected |
|-----------|-------|----------|
| Eat cheese | Player holds cheese, types `eat cheese` | Cheese consumed (removed from inventory); hunger drive reduced; message printed |
| Eat non-food | Player tries `eat candle` | Rejection message: "You can't eat that." |
| Drink water | Player holds waterskin, types `drink water` | Water consumed (waterskin state changes); thirst satisfied |
| Drink blocked by rabies | Player has furious rabies, types `drink water` | "You gag at the thought of water." — action blocked by `restricts.drink` |
| Bait placement | Player drops cheese in room with rat | Rat's hunger drive detects food stimulus; rat approaches cheese |
| Bait consumption | Rat reaches cheese, hunger high | Rat "eats" cheese (cheese removed); rat hunger satisfied |
| Bait trap combo | Player drops cheese, hides, rat approaches | Rat moves to cheese; player can then attack distracted rat |
| Food spoilage FSM | Cheese ticks through `fresh → stale → spoiled` | States transition correctly; spoiled food has negative eat effect |

**Documentation deliverables that must exist:**

- `docs/architecture/engine/food-system.md` — eat/drink verbs, food FSM, bait stimulus
- `docs/design/food-mechanics.md` — food objects, spoilage, hunger interaction
- `docs/design/creature-disease-system.md` — rabies, venom, disease delivery overview

**Nelson LLM walkthrough scenarios:** See Section 2 — all 7 scenarios must complete.

**Performance budget:**

- Creature tick <50ms for 10 creatures (maintained from GATE-2)
- Combat resolution <100ms for a 3-creature fight
- Disease tick <10ms for 5 concurrent diseases (maintained from GATE-4)

**Pass/fail:** ALL unit tests pass. ALL 7 LLM scenarios complete without errors. All 3 docs exist. Zero regressions. Binary.  
**Reviewer:** Bart (architecture), Nelson (LLM execution + gate signer), Marge (test sign-off), CBG (player experience check)

**CBG player experience check (GATE-5 only):**

- Does cat-kills-rat feel natural and discoverable? (<3 turns after entering room)
- Does rabies create a meaningful "oh no" moment when symptoms appear?
- Does bait mechanic feel like a puzzle the player would try without hints?
- Design debt captured to `.squad/decisions/inbox/cbg-design-debt-GATE-5.md`

**On pass:** `git add -A && git commit -m "GATE-5: Phase 2 complete — food/bait + full LLM walkthrough + docs" && git push`

---

## Section 2: Nelson LLM Test Scenarios

**Determinism rule:** All LLM walkthroughs seed `math.randomseed(42)` via `--headless` mode. Probabilistic behavior (wander, disease transmission) must trigger within defined tick counts. If a probabilistic test fails, re-run with seed 43, then 44. Three consecutive failures across different seeds = genuine bug.

**Mode:** All scenarios use `--headless`. Input via pipe or `echo`. Output validated against expected substrings.

---

### GATE-1 Scenarios: Creature Data Validation

```
# No LLM walkthrough — unit tests only.
# Validate: 4 creatures load, body_tree validates, materials resolve.
# Static checks in test files, not headless game session.
```

---

### GATE-2 Scenarios: Creature Combat + Predator-Prey

**Scenario P2-A: "Cat Chases Rat Across Rooms"**

```bash
# Setup: Cat and rat both placed in cellar. Player in adjacent room.
# Cat has prey={"rat"}. Rat has predator={"cat"}.
echo "go cellar\nlook\nwait\nwait\nwait\nlook" | lua src/main.lua --headless
```

**Expected output contains:**
- First `look`: see both cat and rat in cellar (lit) OR hear both (dark)
- After waits: cat chases rat; rat flees to adjacent room
- Second `look`: cat has pursued rat OR rat is gone from cellar
- Key validation: creature-to-creature stimulus → action pipeline fires

**Scenario P2-B: "Wolf Attacks Player in Hallway"**

```bash
# Setup: Wolf placed in hallway. Player starts in bedroom.
echo "go north\nlook\nwait" | lua src/main.lua --headless
```

**Expected output contains:**
- Player enters hallway → wolf `player_enters` reaction fires
- Wolf aggression ≥ 70 → wolf attacks player
- Combat narration appears (wolf bite attempt)
- Player receives damage OR gets prompted for response
- Key validation: aggressive creature initiates combat on sight

**Scenario P2-C: "Spider Web Trap"**

```bash
# Setup: Spider in cellar with web object already created.
echo "go cellar\nlook" | lua src/main.lua --headless
```

**Expected output contains:**
- Player enters cellar → web trap check fires
- If web exists in exit path: "You walk into a sticky web..." (trap triggered)
- Spider detects trapped player → may approach
- Key validation: creature-created objects interact with player movement

---

### GATE-3 Scenarios: NPC-vs-NPC Combat + Witness Narration

**Scenario P2-D: "Player Watches Cat Kill Rat"**

```bash
# Setup: Cat and rat in cellar. Player enters with light.
echo "take matchbox\nopen matchbox\ntake match\nlight match\nlight candle\ngo cellar\nlook\nwait\nwait\nwait\nlook" | lua src/main.lua --headless
```

**Expected output contains:**
- Player sees cat and rat in cellar
- Cat-vs-rat combat initiates (predator-prey)
- Witness narration: "The cat pounces on the rat..." or similar visual combat text
- After combat resolves: dead rat on floor OR rat fled
- If rat died: `look` shows dead rat, cat present
- Key validation: witness narration generates for lit-room observer

**Scenario P2-D2: "Witness Combat in Darkness"**

```bash
# Setup: Same as P2-D but no light.
echo "go cellar\nlisten\nwait\nwait\nlisten" | lua src/main.lua --headless
```

**Expected output contains:**
- Player hears combat: "hissing," "shriek," "scrabbling" (audio-only narration)
- No visual descriptions of the fight
- Key validation: dark-room witness narration uses sound only

**Scenario P2-E: "Multi-Combatant Turn Order"**

```bash
# Setup: Wolf, cat, and rat in same room. Player enters.
echo "go cellar\nwait\nwait\nwait" | lua src/main.lua --headless
```

**Expected output contains:**
- Multiple creatures act in speed order
- Rat (fastest) acts first, then cat, then wolf (or by size tiebreak)
- No infinite combat loops — combat resolves or creatures flee
- Key validation: turn order with 3+ participants is correct and terminates

**Scenario P2-E2: "Creature Flees Successfully" (Marge review fix)**

```bash
# Setup: Wolf at low health vs player in hallway. Wolf should flee, not fight to death.
echo "go hallway\nattack wolf\nwait\nattack wolf\nattack wolf\nlook" | lua src/main.lua --headless
```

**Expected output contains:**
- Wolf takes repeated damage → health drops below `flee_threshold` (0.2)
- Wolf morale breaks: "The wolf breaks away and bolts!" or similar flee narration
- Wolf exits room via valid exit
- Second `look`: wolf no longer in hallway
- Key validation: morale/flee logic works end-to-end in headless LLM walkthrough

**Scenario P2-E3: "Player Joins Active NPC Combat" (Marge review fix)**

```bash
# Setup: Cat and rat fighting in cellar. Player enters mid-fight and attacks one.
echo "go cellar\nwait\nwait\nattack rat\nlook" | lua src/main.lua --headless
```

**Expected output contains:**
- Cat-vs-rat combat already in progress (predator-prey trigger)
- Player joins combat with `attack rat`
- Turn order recalculates to include player
- 3-way fight resolves (player + cat vs rat, or similar)
- Key validation: player intervention in active NPC combat works without crash

---

### GATE-4 Scenarios: Disease Delivery

**Scenario P2-F: "Rat Bites Player — Rabies Progression"**

```bash
# Setup: Player provokes rat. Rat bites. Seed chosen for rabies transmission.
# Use math.randomseed that triggers the 8% chance.
echo "go cellar\ngrab rat\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nlook" | lua src/main.lua --headless
```

**Expected output contains:**
- `grab rat` → rat bites → "The rat sinks its teeth into your hand."
- If rabies transmitted (seed-dependent): "The bite wound throbs strangely."
- After 15 waits (incubation): "You feel feverish. The old bite wound itches terribly."
- Key validation: `on_hit` disease delivery fires; rabies FSM progresses on tick

**Scenario P2-F2: "Spider Venom Delivery"**

```bash
# Setup: Spider bites player (100% venom delivery).
echo "go cellar\ngrab spider\nwait\nwait\nwait" | lua src/main.lua --headless
```

**Expected output contains:**
- Spider bites → "The spider's fangs pierce your skin. A burning sensation spreads."
- Venom injury inflicted immediately (100% delivery, no probability)
- After waits: venom progression messages; movement may be restricted
- Key validation: `on_hit.inflict="spider-venom"` fires on spider bite

---

### GATE-5 Scenarios: Food + Bait + Full End-to-End

**Scenario P2-G: "Bait Mechanic — Cheese Lures Rat"**

```bash
# Setup: Player has cheese. Rat is in adjacent room.
echo "take cheese\ngo cellar\ndrop cheese\ngo north\nwait\nwait\nwait\ngo cellar\nlook" | lua src/main.lua --headless
```

**Expected output contains:**
- Player drops cheese in cellar
- After waits: rat detects food stimulus; rat moves toward cheese
- Player returns to cellar: rat is near/eating cheese
- Key validation: food stimulus triggers creature movement; bait mechanic works

**Scenario P2-H: "Eat and Drink Verbs"**

```bash
# Setup: Player has food and waterskin.
echo "take cheese\neat cheese\ntake waterskin\ndrink water" | lua src/main.lua --headless
```

**Expected output contains:**
- `eat cheese`: "You eat the cheese." (or similar); cheese removed from inventory
- `drink water`: "You drink from the waterskin." (or similar); thirst effect
- Key validation: eat/drink verbs consume items, affect player state

**Scenario P2-I: "Rabies Blocks Drinking"**

```bash
# Setup: Player has rabies in furious stage. Tries to drink.
# This may need a save-state or extended wait sequence to reach furious.
echo "go cellar\ngrab rat\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\ntake waterskin\ndrink water" | lua src/main.lua --headless
```

**Expected output contains:**
- Rabies has progressed to `furious` state (hydrophobia)
- `drink water` → "You gag at the thought of water." (action blocked)
- Key validation: `restricts.drink` on disease state blocks the drink verb

**Scenario P2-J: "Full End-to-End Walkthrough"**

```bash
# The complete Phase 2 experience: explore, fight, get diseased, use food, bait creature.
echo "look\n\
take matchbox\n\
open matchbox\n\
take match\n\
light match\n\
light candle\n\
look\n\
take cheese\n\
take silver dagger\n\
go cellar\n\
look\n\
drop cheese\n\
wait\n\
wait\n\
wait\n\
look\n\
attack rat\n\
dodge\n\
attack rat\n\
look\n\
take rat\n\
inventory\n\
go north\n\
look\n\
eat cheese\n\
go hallway\n\
look" | lua src/main.lua --headless
```

**Expected output validation (ordered):**

| Step | Command | Expected Substring or Behavior |
|------|---------|-------------------------------|
| 1 | `look` | Darkness description (game starts 2 AM) |
| 2–6 | Light sequence | Candle lights; room illuminated |
| 7 | `look` | See room contents including cheese and dagger |
| 8–9 | Take items | Cheese and dagger in hands |
| 10 | `go cellar` | Player enters cellar; rat present |
| 11 | `look` | See rat in cellar |
| 12 | `drop cheese` | Cheese on cellar floor |
| 13–15 | `wait` × 3 | Rat may approach cheese (bait stimulus) |
| 16 | `look` | Rat near cheese OR eating cheese |
| 17 | `attack rat` | Combat initiates; dagger vs rat |
| 18 | `dodge` | Player dodges rat counterattack |
| 19 | `attack rat` | Rat takes critical damage (steel dagger vs flesh) |
| 20 | `look` | Dead rat on floor |
| 21 | `take rat` | Dead rat picked up (portable) |
| 22 | `inventory` | Shows: candle (lit), dead rat |
| 23–24 | `go north`, `look` | Player in new room |

**Key validations for P2-J:**
- Bait mechanic (cheese draws rat)
- Combat resolution (dagger kills rat)
- Dead creature pickup (mutation to portable)
- No crashes across 24+ commands
- All Phase 1 mechanics still work (lighting, movement, inventory)

---

### Scenario Log Format

Nelson logs every LLM scenario run to `test/scenarios/gate{N}/`:

```
test/scenarios/gate0/   — (empty, unit tests only)
test/scenarios/gate1/   — (empty, unit tests only)
test/scenarios/gate2/
  ├── p2-a-cat-chases-rat.txt
  ├── p2-b-wolf-attacks-player.txt
  └── p2-c-spider-web-trap.txt
test/scenarios/gate3/
  ├── p2-d-witness-cat-kills-rat.txt
  ├── p2-d2-witness-dark.txt
  └── p2-e-multi-combatant.txt
test/scenarios/gate4/
  ├── p2-f-rabies-progression.txt
  └── p2-f2-spider-venom.txt
test/scenarios/gate5/
  ├── p2-g-bait-cheese-rat.txt
  ├── p2-h-eat-drink.txt
  ├── p2-i-rabies-blocks-drink.txt
  └── p2-j-full-end-to-end.txt
```

Each log file records:
- Seed used (`math.randomseed(N)`)
- Exact input pipe
- Full stdout capture
- PASS/FAIL per expected substring
- Timestamp

---

## Section 3: TDD Test File Map

Every test file listed below is created by Nelson. Tests are written to the **spec** (design plan), not to the implementation. Tests use the existing pure-Lua test framework (`test/parser/test-helpers.lua`).

### Creature Definition Tests (WAVE-1)

| Test File | Module Under Test | Wave | Key Assertions |
|-----------|-------------------|------|----------------|
| `test/creatures/test-cat.lua` | `src/meta/creatures/cat.lua` | WAVE-1 | Loads via `dofile()`; `animate=true`; `template="creature"`; `behavior.prey={"rat"}`; `body_tree` has head/body/legs/tail; `on_feel` present; keywords include "cat"; size is string `"small"` |
| `test/creatures/test-wolf.lua` | `src/meta/creatures/wolf.lua` | WAVE-1 | Loads via `dofile()`; `animate=true`; `behavior.aggression >= 70`; `body_tree` has head/body/legs (no tail); `combat.natural_weapons` includes bite with force ≥ 6; size `"medium"` |
| `test/creatures/test-spider.lua` | `src/meta/creatures/spider.lua` | WAVE-1 | Loads via `dofile()`; `animate=true`; `behavior.ambush=true`; `body_tree` has body/legs only; `combat.natural_weapons` bite has `on_hit.inflict="spider-venom"`; size `"tiny"`; material includes `"chitin"` |
| `test/creatures/test-rat-phase2.lua` | `src/meta/creatures/rat.lua` (modified) | WAVE-1 | `combat` table added; `combat.natural_weapons` bite has `on_hit.inflict="rabies"` with `probability=0.08`; `body_tree` present (head/body/legs/tail); Phase 1 fields still intact |
| `test/creatures/test-creature-materials.lua` | `src/meta/materials/chitin.lua`, `hide.lua`, `tooth_enamel.lua`, `keratin.lua` | WAVE-1 | Each material loads; `density` is number; `hardness` is number; resolves through `engine/materials` registry |

### Creature Combat + Behavior Tests (WAVE-2)

| Test File | Module Under Test | Wave | Key Assertions |
|-----------|-------------------|------|----------------|
| `test/creatures/test-creature-combat.lua` | `src/engine/creatures/init.lua` (attack action) | WAVE-2 | Creature with `aggression >= 70` selects attack action; attack action calls `resolve_exchange()`; attack produces narration; creature with `aggression=0` never attacks unprovoked |
| `test/creatures/test-predator-prey.lua` | `src/engine/creatures/init.lua` (prey detection) | WAVE-2 | Cat in room with rat → cat detects prey → cat selects chase/attack; rat detects predator → flee; prey detection only triggers for alive creatures; dead rat does not trigger cat chase |
| `test/creatures/test-creature-stimulus.lua` | `src/engine/creatures/init.lua` (stimulus) | WAVE-2 | `creature_attacks` stimulus emitted when creature attacks; `creature_died` emitted on death; `creature_fled` emitted on flee; stimuli reach creatures within `awareness.sound_range`; stimuli respect room boundaries |
| `test/creatures/test-creature-perf.lua` | `src/engine/creatures/init.lua` | WAVE-2 | 10 creatures in registry; `creatures.tick(context)` completes in <50ms (measured via `os.clock()`); no memory leak over 100 ticks (collectgarbage + check) |

### NPC-vs-NPC Combat Tests (WAVE-3)

| Test File | Module Under Test | Wave | Key Assertions |
|-----------|-------------------|------|----------------|
| `test/combat/test-npc-combat.lua` | `src/engine/combat/init.lua` (NPC path) | WAVE-3 | `resolve_exchange(cat, rat, cat_bite, "body")` produces result; NPC defense selection reads `combat.behavior.defense`; cat-vs-rat resolves to rat injury or death; both combatants use same `resolve_exchange()` as player combat |
| `test/combat/test-witness-narration.lua` | `src/engine/combat/narration.lua` | WAVE-3 | Lit room: visual narration string contains action verbs ("pounces", "bites"); dark room: audio narration ("you hear"); adjacent room: distant sound; no narration if player not in range; narration varies by severity (≥3 unique strings with seed 42) |
| `test/combat/test-multi-combatant.lua` | `src/engine/combat/init.lua` (turn order) | WAVE-3 | 3 creatures: turn order by speed (descending), size tiebreak (smaller first); player in fight: player acts at correct position in order; combat terminates when all opponents dead or fled; no infinite loops (max 20 rounds safety) |
| `test/combat/test-npc-morale.lua` | `src/engine/creatures/init.lua` (morale) | WAVE-3 | Creature at health < 30% → flee_threshold check fires; morale break mid-combat → creature exits fight; fled creature moves to adjacent room; morale does not trigger on dead creatures |

### Disease + Injury Tests (WAVE-4)

| Test File | Module Under Test | Wave | Key Assertions |
|-----------|-------------------|------|----------------|
| `test/injuries/test-disease-delivery.lua` | `src/engine/injuries.lua` (on_hit extension) | WAVE-4 | `on_hit = { inflict = "X" }` calls `injuries.inflict("X")`; probability field respected (100 trials, ±tolerance); `uses` field decrements and stops delivery at 0; works for both player and NPC targets |
| `test/injuries/test-rabies.lua` | `src/meta/injuries/rabies.lua` | WAVE-4 | Loads via `dofile()`; 4 states defined (incubating/prodromal/furious/fatal); transitions trigger on timer; `restricts.drink` in furious state; `healing_interactions` works for incubating and prodromal only; terminal state has `death_message`; damage_per_tick values correct per state |
| `test/injuries/test-spider-venom.lua` | `src/meta/injuries/spider-venom.lua` | WAVE-4 | Loads via `dofile()`; venom progression states defined; 100% delivery (no probability); damage_per_tick applies; movement restriction after threshold; cure mechanics (if any for Phase 2) |
| `test/injuries/test-disease-healing.lua` | `src/engine/injuries.lua` (healing path) | WAVE-4 | Poultice applied to `incubating` rabies → cured; poultice applied to `furious` rabies → no effect; healing checks `from_states` allowlist; injury removed from player on successful cure |

### Food + Bait Tests (WAVE-5)

| Test File | Module Under Test | Wave | Key Assertions |
|-----------|-------------------|------|----------------|
| `test/food/test-eat-drink.lua` | `src/engine/verbs/init.lua` (eat/drink handlers) | WAVE-5 | `eat` verb on food item → item consumed (removed from inventory); `eat` on non-food → rejection message; `drink` verb on liquid container → liquid consumed; `drink` blocked when `restricts.drink` active (rabies); eating spoiled food inflicts negative effect; uneaten food still in inventory |
| `test/food/test-bait.lua` | `src/engine/creatures/init.lua` (food stimulus) | WAVE-5 | Food item on ground emits `food_stimulus`; creature with hunger drive detects food in same room; creature moves toward food (priority over wander); creature consumes food (item removed); bait works cross-tick (not instant); no stimulus from food in closed containers |
| `test/food/test-food-objects.lua` | `src/meta/objects/cheese.lua`, etc. | WAVE-5 | Food items load; `edible=true` flag present; `nutrition` value defined; FSM states: `fresh → stale → spoiled`; `on_feel`, `on_smell`, `on_taste` present; keywords correct; material is food-appropriate |
| `test/food/test-food-spoilage.lua` | FSM on food objects | WAVE-5 | Fresh food transitions to stale after N ticks; stale transitions to spoiled after M ticks; spoiled food has modified `on_smell` (rotten); spoiled food `eat` effect is negative; spoilage timer pauses in closed containers (optional) |

### Integration + Scenario Tests (WAVE-5)

| Test File | Module Under Test | Wave | Key Assertions |
|-----------|-------------------|------|----------------|
| `test/integration/test-phase2-integration.lua` | Full Phase 2 system | WAVE-5 | Multi-command headless scenario: light → move → encounter creature → combat → disease check → eat food → bait → verify all subsystems integrate; zero crashes across 30+ commands; all Phase 1 features still work |

### Scenario Log Files (Created During Gate Runs)

| Directory | Gate | Contents |
|-----------|------|----------|
| `test/scenarios/gate0/` | GATE-0 | Empty (pre-flight, no scenarios) |
| `test/scenarios/gate1/` | GATE-1 | Empty (unit tests only) |
| `test/scenarios/gate2/` | GATE-2 | `p2-a-cat-chases-rat.txt`, `p2-b-wolf-attacks-player.txt`, `p2-c-spider-web-trap.txt` |
| `test/scenarios/gate3/` | GATE-3 | `p2-d-witness-cat-kills-rat.txt`, `p2-d2-witness-dark.txt`, `p2-e-multi-combatant.txt` |
| `test/scenarios/gate4/` | GATE-4 | `p2-f-rabies-progression.txt`, `p2-f2-spider-venom.txt` |
| `test/scenarios/gate5/` | GATE-5 | `p2-g-bait-cheese-rat.txt`, `p2-h-eat-drink.txt`, `p2-i-rabies-blocks-drink.txt`, `p2-j-full-end-to-end.txt` |

### Test Runner Registration (WAVE-0, Pre-Flight)

Bart adds these directories to `test/run-tests.lua` before any test files are created:

```lua
repo_root .. SEP .. "test" .. SEP .. "creatures",   -- already registered in Phase 1
repo_root .. SEP .. "test" .. SEP .. "combat",      -- already registered in Phase 1
repo_root .. SEP .. "test" .. SEP .. "food",         -- NEW for Phase 2
repo_root .. SEP .. "test" .. SEP .. "scenarios",    -- NEW for Phase 2
```

Phase 1 already registered `test/creatures/` and `test/combat/`. Phase 2 adds `test/food/` and `test/scenarios/`.

### Test Count Summary

| Category | New Test Files | Est. Test Cases | Wave |
|----------|---------------|-----------------|------|
| Creature definitions (4) | 5 files | ~60 | WAVE-1 |
| Creature combat + behavior | 4 files | ~40 | WAVE-2 |
| NPC-vs-NPC combat | 4 files | ~35 | WAVE-3 |
| Disease + injuries | 4 files | ~30 | WAVE-4 |
| Food + bait | 4 files | ~25 | WAVE-5 |
| Integration | 1 file | ~15 | WAVE-5 |
| **Total** | **22 files** | **~205 tests** | |

### Performance Budget Summary

| Metric | Budget | Measured At | Test File |
|--------|--------|-------------|-----------|
| Creature tick (10 creatures) | <50ms | GATE-2, GATE-5 | `test/creatures/test-creature-perf.lua` |
| Combat resolution (3 creatures) | <100ms | GATE-3, GATE-5 | `test/combat/test-multi-combatant.lua` |
| Disease tick (5 concurrent) | <10ms | GATE-4, GATE-5 | `test/injuries/test-disease-delivery.lua` |
| Full game tick (10 creatures + 5 diseases) | <150ms | GATE-5 | `test/integration/test-phase2-integration.lua` |

---

# NPC + Combat Phase 2 — Chunk 4: Feature Breakdown + Integration

**Author:** Bart (Architect)  
**Date:** 2026-07-28  
**Status:** Draft  
**Chunk:** 4 of N  
**Scope:** Detailed system specs + cross-system integration points  
**Governs:** Phase 2 new systems (Creature Generalization, NPC-vs-NPC Combat, Disease, Food PoC)

---

## Table of Contents

- [1. Feature Breakdown per System](#1-feature-breakdown-per-system)
  - [A. Creature Generalization System](#a-creature-generalization-system)
  - [B. NPC-vs-NPC Combat System](#b-npc-vs-npc-combat-system)
  - [C. Disease System](#c-disease-system)
  - [D. Food Proof-of-Concept](#d-food-proof-of-concept)
- [2. Cross-System Integration Points](#2-cross-system-integration-points)

---

## 1. Feature Breakdown per System

### A. Creature Generalization System

Phase 1 built the creature engine around one animal — the rat. Phase 2 proves the system generalizes to creatures with fundamentally different behavior profiles: predators, territorial defenders, ambush trappers. The engine changes are **zero creature-specific code** (Principle 8). Every new behavior emerges from metadata the existing `creature_tick()` already evaluates.

#### A.1 Creature-to-Creature Reactions

**Problem:** Phase 1 creatures only react to player stimuli (`player_enters`, `player_attacks`). Phase 2 creatures must react to each other — a cat must chase a rat, a dog must growl at a cat, a spider must ignore anything too large to trap.

**Solution: Creature-sourced stimuli.** Extend the existing stimulus system so creature actions (movement, vocalization, death) emit stimuli that other creatures can react to. The stimulus pipeline is already generic — `creatures.emit_stimulus(room_id, type, data)` accepts any stimulus type. We add creature-sourced types and creature-targeted reactions.

**New stimulus types:**

| Stimulus | Emitted When | Data Fields |
|----------|-------------|-------------|
| `creature_enters` | Creature moves into a room | `{ source = creature, from_room = id }` |
| `creature_exits` | Creature leaves a room | `{ source = creature, to_room = id }` |
| `creature_dies` | Creature health → 0 | `{ source = creature, killer = attacker_or_nil }` |
| `creature_vocalizes` | Creature performs vocalize action | `{ source = creature, sound = string }` |

**Reaction evaluation change:** `process_stimuli()` currently matches stimulus type against the creature's `reactions` table. No code change needed — a cat that has `creature_enters` in its reactions table already reacts. What changes is the **data**: reactions gain an optional `source_filter` to discriminate which creatures trigger them.

```lua
-- Cat reaction: only triggered by creatures matching its prey list
reactions = {
    creature_enters = {
        source_filter = "prey",   -- only fires if source.id is in behavior.prey
        action = "attack",
        message = "The cat's ears flatten. Its body tenses.",
        delay = 0,
    },
}
```

**`source_filter` resolution** (in `process_stimuli()`):

```lua
-- Pseudocode for source_filter evaluation
if reaction.source_filter == "prey" then
    if not table_contains(creature.behavior.prey, stimulus.data.source.id) then
        skip  -- stimulus source is not prey; ignore
    end
elseif reaction.source_filter == "predator" then
    if not table_contains(creature.behavior.predator, stimulus.data.source.id) then
        skip  -- not a predator; ignore
    end
elseif reaction.source_filter == nil then
    pass  -- no filter; react to all sources (existing behavior)
end
```

**Engine change:** ~15 lines added to `process_stimuli()` in `src/engine/creatures/init.lua`. No new modules.

#### A.2 Predator-Prey Metadata

**Format:** Two optional arrays on the `behavior` table:

```lua
behavior = {
    prey = { "rat", "mouse", "bird" },      -- creatures this one hunts
    predator = { "cat", "wolf", "hawk" },    -- creatures this one flees from
    -- existing fields unchanged
}
```

**Semantics:**

| Field | Effect on Behavior | Used By |
|-------|-------------------|---------|
| `prey` | When a prey creature is in the same room, this creature's `creature_enters` reaction fires with `source_filter = "prey"`. The reaction action is typically `attack` (enters combat). | `process_stimuli()`, `score_actions()` |
| `predator` | When a predator is in the same room, this creature's `creature_enters` reaction fires with `source_filter = "predator"`. The reaction action is typically `flee` with a high fear_delta. | `process_stimuli()`, `score_actions()` |

**Prey/predator is directional.** Cat has `prey = {"rat"}`. Rat has `predator = {"cat"}`. These are independent declarations — the engine doesn't infer one from the other. This is intentional: a wolf might consider a cat prey but a cat might not consider a wolf a predator (cats don't always flee wolves — they climb).

**No predator-prey registry.** Each creature declares its own relationships. The engine discovers them at stimulus time by checking the reacting creature's `prey`/`predator` arrays against the stimulus source's `id`. This follows Principle 8 — the engine reads metadata, not lookup tables.

#### A.3 Territorial Behavior

Phase 1 has `territorial = false` and `home_room = nil` on the creature template. Phase 2 activates these fields for creatures like the guard dog.

**Metadata format:**

```lua
behavior = {
    territorial = true,
    home_room = "hallway",              -- room ID this creature defends
    territory_aggression = "on_intrude", -- when to act aggressively
    territory = { "hallway", "foyer" }, -- optional: multiple rooms in territory
}
```

**`territory_aggression` values:**

| Value | Behavior |
|-------|----------|
| `"on_intrude"` | Attack any non-ally creature or player that enters territory rooms |
| `"on_provoke"` | Growl/vocalize warning on intrude; attack only if provoked |
| `"patrol"` | Wander between territory rooms; attack intruders on sight |

**Engine integration:** `score_actions()` gains a territory bonus. When a creature with `territorial = true` is in one of its `territory` rooms and a non-prey, non-predator entity enters, the `attack` action score gets a territory bonus (+30 by default). This makes territorial creatures strongly prefer attacking intruders in their home turf but still allows fear to override (flee_threshold still applies).

```lua
-- In score_actions(), after existing utility scoring:
if creature.behavior.territorial and
   table_contains(creature.behavior.territory or {creature.behavior.home_room}, current_room_id) and
   has_intruder(context, creature) then
    scores["attack"] = (scores["attack"] or 0) + 30
end
```

**Territory wander:** Creatures with `territory_aggression = "patrol"` get their `wander` action constrained to territory rooms only. The existing `wander` action picks a random valid exit — we add a filter that rejects exits leading outside the territory.

#### A.3.1 Creature Portal Traversal Rules (Moe review fix)

Creatures can traverse portals (stairs, archways, doors) according to these default rules:

| Portal State | Creature Behavior | Notes |
|-------------|-------------------|-------|
| Open passage (archway, stairway) | **YES** — creatures traverse freely | Default for all creatures |
| Open/unlocked door | **YES** — creatures traverse freely | Door must be in open state |
| Closed door (unlocked) | **NO** — creatures cannot open doors unless `can_open_doors=true` | Rat has `can_open_doors=false` (cellar-confined) |
| Locked door | **NO** — no creature can traverse | Requires player to unlock first |

**Territorial override:** Creatures with `territorial=true` do not leave their territory rooms even if passages are open, unless fleeing extreme threat (health < flee_threshold × 0.5). The wolf stays in the hallway; the spider stays in the cellar.

**`can_open_doors` semantics:** This flag controls whether a creature can pass through CLOSED (but unlocked) doors. Default is `false` for all creatures. The rat is confined to the cellar by a closed door, not by invisible walls. If the player opens the cellar door, the rat CAN traverse it on subsequent ticks.

**Multi-room hunting:** Cat hunts rat across rooms via open passages only. Cat in courtyard cannot reach rat in cellar if the connecting door is closed. This creates emergent gameplay — opening doors changes the ecosystem.

#### A.4 Attack Action: creature_tick() → Combat FSM

Phase 1 deferred the `attack` action — when `score_actions()` selected it, the creature fell back to `flee`. Phase 2 enables it.

**Attack action flow:**

```
creature_tick() evaluates behavior
  → score_actions() picks "attack" as highest utility
  → execute_action("attack", creature, context)
    → select target: find_attack_target(creature, context)
    → select weapon: select_natural_weapon(creature)
    → enter combat: combat.initiate_exchange(creature, target, weapon, context)
    → collect narration messages from combat result
    → return messages
```

**`find_attack_target(creature, context)`:**

1. Get all entities in the creature's room (player + other creatures)
2. Filter by `target_priority` from `combat.behavior`:
   - `"closest"` → first entity in room contents (insertion order)
   - `"weakest"` → lowest health fraction (`health / max_health`)
   - `"threatening"` → entity that last attacked this creature (tracked in `creature._last_attacker`)
   - `"random"` → random selection
   - `"prey_only"` → only target creatures in `behavior.prey` list
3. Return target or `nil` (if nil, fall back to `idle`)

**`select_natural_weapon(creature)`:**

Reads `combat.behavior.attack_pattern`:
- `"random"` → pick randomly from `combat.natural_weapons`
- `"strongest"` → pick weapon with highest `force`
- `"cycle"` → round-robin through weapons (track index in `creature._weapon_cycle_idx`)
- specific `id` → always use that weapon

**Integration point:** `execute_action()` in `src/engine/creatures/init.lua` gains an `"attack"` branch that calls into `src/engine/combat/init.lua`. The combat module's `resolve_exchange()` already handles NPC combatants — it reads `combat.behavior` metadata for NPC decisions. No combat module changes required for basic creature-initiated attacks.

#### A.5 Spider Web Creation: Creature-Created Objects

Spiders introduce a new pattern: creatures that create objects as part of their behavior. A web is a normal object — it has a template, sensory fields, FSM states — but it's spawned by the spider's tick, not placed by a room definition.

**Web object definition (`src/meta/objects/spider-web.lua`):**

```lua
return {
    guid = "{new-guid}",
    template = "small-item",
    id = "spider-web",
    name = "a thick spider web",
    keywords = { "web", "spider web", "cobweb", "silk" },
    description = "Sticky silk threads span the passage, glistening faintly.",
    
    on_feel = "Your fingers stick. Thin, incredibly strong threads coat your skin.",
    on_smell = "A faint musty sweetness.",
    on_listen = "Silent, unless something struggles in it.",
    
    material = "silk",
    size = "medium",
    weight = 0.1,
    portable = false,
    
    -- Trap behavior
    trap = {
        type = "ensnare",
        max_size = "small",         -- catches creatures size ≤ small
        on_trigger = {
            message_victim = "You walk into a web! Sticky threads cling to your arms and face.",
            message_room = "Something thrashes in the spider web.",
            effect = "restrained",  -- prevents movement for N turns
            duration = 3,           -- restrained for 3 turns
        },
    },
    
    -- FSM: webs can be destroyed
    initial_state = "intact",
    _state = "intact",
    states = {
        intact = {
            description = "A thick spider web blocks the passage.",
            room_presence = "A spider web stretches across the doorway.",
        },
        damaged = {
            description = "A torn spider web hangs in tatters.",
            room_presence = "Torn webbing hangs from the walls.",
        },
    },
    transitions = {
        { from = "intact", to = "damaged", verb = "cut" },
        { from = "intact", to = "damaged", verb = "break" },
        { from = "intact", to = "damaged", verb = "burn", requires_tool = "fire_source" },
    },
    mutations = {
        burn = { becomes = "spider-web-burned", message = "The web shrivels and blackens." },
    },
}
```

**Spider `create_web` action:**

New action type in the creature action system. When a spider's `score_actions()` selects `create_web`:

```lua
-- In spider behavior metadata:
behavior = {
    default = "idle",
    territorial = true,
    home_room = "cellar",
    territory = { "cellar" },
    territory_aggression = "on_intrude",
    create_web_chance = 30,     -- 30% chance per tick when idle in territory
    max_webs_per_room = 2,      -- don't fill a room with webs
}
```

**`execute_action("create_web")` flow:**

1. Check `creature.behavior.max_webs_per_room` against current web count in room
2. If under limit: instantiate `spider-web` via the loader (same path as room instance loading)
3. Register new object in context.registry
4. Add to current room's contents
5. Emit message: *"The spider works its spinnerets, stretching silk across the passage."*
6. Return messages

**Engine change:** Add `"create_web"` to the action dispatch table in `execute_action()`. The action is generic — it reads `creature.behavior.created_object` (defaults to `"spider-web"`) and instantiates it. Future creatures that create objects (bird nests, ant tunnels) use the same action with different `created_object` values.

```lua
-- Generic object-creation action metadata (on spider):
behavior = {
    created_object = "spider-web",   -- object ID to instantiate
    create_chance = 30,
    max_created_per_room = 2,
}
```

**Trap evaluation:** Traps fire during movement. When a creature or player enters a room, the movement handler checks room contents for objects with a `trap` field. If the moving entity's `size` ≤ `trap.max_size`, the trap triggers. This is a ~10-line check in `movement.lua`, not a creature-specific feature.

---

### B. NPC-vs-NPC Combat System

#### B.1 Unified Combatant Interface

Phase 1's combat FSM already accepts any entity with a `combat` table, `body_tree`, and `health`/`max_health` fields. The `resolve_exchange(attacker, defender, weapon, target_zone)` function makes no distinction between player and creature — the same math, narration, and injury pipeline handles all combatant types.

**What Phase 2 adds:** The initiation pathway. Phase 1 enters combat only through player verbs (`attack rat`). Phase 2 adds creature-initiated combat via the `attack` action in `creature_tick()` (see A.4 above) and automatic predator-prey triggering.

**Combatant interface contract** (any entity that fights must have):

```lua
{
    id = string,              -- creature/player ID
    name = string,            -- display name
    health = number,          -- current HP
    max_health = number,      -- max HP
    alive = true,             -- animate flag
    combat = {                -- combat metadata table
        size = string,        -- "tiny" | "small" | "medium" | "large" | "huge"
        speed = number,       -- initiative (1-10)
        natural_weapons = {}, -- array of weapon specs
        natural_armor = nil,  -- or armor spec
        behavior = {},        -- NPC decision-making (ignored for player)
    },
    body_tree = {},           -- zone specs for targeting
}
```

The player satisfies this via `ctx.player.combat` and `ctx.player.body_tree`. Creatures satisfy it via their `.lua` definition files. No adapter layer needed.

#### B.2 Multi-Combatant Turn Order

Phase 1 is strictly 1v1 — one attacker, one defender per exchange. Phase 2 supports N combatants in a single fight (cat vs. rat while player watches, or player + cat vs. wolf pack).

**Turn order algorithm:**

```
Given: combatants[] -- all entities in the fight

1. Sort combatants by combat.speed (descending)
2. On tie: smaller creature goes first (SIZE_ORDER["tiny"] > SIZE_ORDER["small"] > ...)
3. On tie: player goes first (home-field advantage)

Result: ordered turn list for this round
```

**Round execution:**

```
for each combatant in turn_order:
    if combatant.alive and combatant still in fight:
        target = select_target(combatant, other_combatants)
        if target is nil:
            combatant exits fight (no valid target)
        else:
            weapon = select_weapon(combatant)
            result = resolve_exchange(combatant, target, weapon, zone)
            narration += result.messages
            
            -- Post-exchange checks
            if target.health <= 0:
                handle_death(target)
                remove target from combatants
            if combatant morale check fails:
                combatant flees; remove from combatants
```

**Multi-combatant targeting:** Each NPC combatant uses `combat.behavior.target_priority` to select which opponent to attack. In a 3-way fight (player, cat, rat), the cat targets the rat (prey), the rat targets whoever attacked it (threatening), and the player targets whoever they chose.

**Fight tracking:** A new `combat_state` table tracks active fights:

```lua
-- Stored in context during active combat
context.active_fights = {
    [fight_id] = {
        combatants = { creature1, creature2, ... },
        turn_order = { ... },  -- recalculated each round
        round = 1,
        location = room_id,
    },
}
```

**Entry/exit conditions:**
- **Enter fight:** `attack` action (creature or player), predator-prey auto-trigger
- **Exit fight:** death, flee (successful), no valid targets remain, player intervention separates combatants
- **Fight ends:** ≤1 combatant remains, or all remaining combatants have no hostile relationship

#### B.3 Combat Witness Narration

When NPC-vs-NPC combat occurs, the player may or may not witness it. Narration adapts to perception context using the existing sensory system (Principle 6).

**Narration tiers:**

| Player Location | Light? | Narration Level | Example |
|----------------|--------|----------------|---------|
| Same room | Yes | Full visual detail | *"The cat springs from behind the barrel. Claws flash — the rat squeals — then silence."* |
| Same room | No | Audio-only | *"A sudden scrabbling. A shrill squeak — a wet crunch. Something killed something in the dark."* |
| Adjacent room | Any | Distant sound | *"From the cellar, you hear claws on stone, a high shriek, then silence."* |
| 2+ rooms away | Any | Nothing | (no output) |

**Implementation:** The existing `narration.lua` module in `src/engine/combat/` generates structured narration from combat results. Phase 2 adds a `witness_mode` parameter:

```lua
-- In narration.lua:
function M.narrate_exchange(result, witness_mode)
    if witness_mode == "full" then
        return full_visual_narration(result)
    elseif witness_mode == "audio" then
        return audio_only_narration(result)
    elseif witness_mode == "distant" then
        return distant_sound_narration(result)
    end
    return nil  -- too far, no narration
end
```

**`witness_mode` determination** (in the fight tick):

```lua
local function get_witness_mode(player, fight)
    if player.location == fight.location then
        local room = context.registry:find_room(fight.location)
        if room_has_light(room, context) then
            return "full"
        else
            return "audio"
        end
    elseif rooms_adjacent(player.location, fight.location) then
        return "distant"
    end
    return nil
end
```

**Audio narration templates:** Each natural weapon has a `sound` field (optional, defaults to weapon `message` verb):

```lua
-- On rat bite:
{ id = "bite", ..., sound = "a sharp squeak and the snap of tiny jaws" }
-- On cat claw:
{ id = "claw", ..., sound = "a hiss and the scrape of claws" }
```

Audio narration uses `sound` fields rather than visual descriptions. Death events always produce a sound: *"A final, high-pitched shriek — then nothing."*

#### B.4 Creature Morale: flee_threshold Mid-Combat

Phase 1 implements `flee_threshold` as a fear-driven behavior check. Phase 2 extends it to combat: creatures check morale after receiving damage.

**Morale check (in UPDATE phase of combat exchange FSM):**

```lua
-- After applying damage to defender:
if defender.animate then  -- only creatures have morale
    local health_fraction = defender.health / defender.max_health
    if health_fraction <= defender.combat.behavior.flee_threshold then
        -- Morale broken: creature attempts to flee
        local fled = attempt_flee(defender, context)
        if fled then
            messages[#messages + 1] = defender.name .. " breaks away and bolts!"
            remove_from_fight(defender, fight)
        else
            -- Blocked exit or cornered: fights desperately
            messages[#messages + 1] = defender.name .. " looks for escape but finds none."
            -- Switch defense to "flee" for next round (prioritizes dodging)
            defender._combat_override_defense = "flee"
        end
    end
end
```

**`attempt_flee()` reuses the existing `flee` action** from creature behavior — pick the exit farthest from threat, move creature. Flee can fail if:
- No valid exits (cornered)
- Exits blocked by webs/barriers
- Attacker speed > defender speed (optional: speed-chase check, Phase 3)

**Design note:** The player has no `flee_threshold` — player flee is always voluntary via the `flee` verb. This asymmetry is intentional: the player has agency, creatures have metadata.

---

### C. Disease System

#### C.1 Generic on_hit Disease Delivery

The `on_hit` field on natural weapons is the universal mechanism for combat-transmitted effects. It exists as a concept in the combat plan but Phase 2 implements it.

**`on_hit` field format:**

```lua
-- On a natural weapon:
{
    id = "bite",
    type = "pierce",
    material = "tooth_enamel",
    force = 2,
    on_hit = {
        type = "disease",             -- effect category
        disease = "rabies",           -- injury type ID (matches file in src/meta/injuries/)
        chance = 0.08,                -- probability per successful hit (0.0 – 1.0; reduced from 0.15 per CBG review)
    },
}
```

**Alternate formats (same mechanism, different effects):**

```lua
-- Spider venom: 100% delivery, no chance roll
on_hit = { type = "disease", disease = "spider-venom", chance = 1.0 }

-- Poisoned weapon: limited uses
on_hit = { type = "disease", disease = "poisoned-nightshade", chance = 1.0, uses = 3 }
```

**Engine integration point:** In the RESOLVE phase of the combat exchange FSM (`src/engine/combat/init.lua`), after damage is calculated and a hit is confirmed:

```lua
-- In resolve_exchange(), after severity >= GRAZE:
if weapon.on_hit then
    local roll = math.random()
    if roll <= (weapon.on_hit.chance or 1.0) then
        local injury_type = weapon.on_hit.disease
        injuries.inflict(defender, injury_type, attacker.id, target_zone)
        -- on_hit message comes from the injury definition's on_inflict.message
    end
    -- Decrement uses if applicable
    if weapon.on_hit.uses then
        weapon.on_hit.uses = weapon.on_hit.uses - 1
        if weapon.on_hit.uses <= 0 then
            weapon.on_hit = nil  -- poison exhausted
        end
    end
end
```

**Key design:** `on_hit` is completely generic. The combat engine doesn't know what "rabies" or "spider-venom" means — it calls `injuries.inflict()` with whatever disease ID the weapon metadata specifies. The injury system handles the rest via its FSM progression. This is Principle 8 in action.

#### C.2 Disease as Injury Type with FSM Progression

Diseases use the existing injury system's FSM infrastructure. A disease is structurally identical to any other injury type — it has `states`, `transitions`, `on_inflict`, `healing_interactions`, and `damage_per_tick`. The difference is semantic: diseases have incubation periods, delayed symptoms, and progressive severity.

**Disease FSM pattern:**

```
incubating → symptomatic → critical → fatal
     │            │            │
     └─── cured ──┴─── cured ──┘   (healing only works in early states)
```

**How this maps to `injuries.lua`:**

The existing `injuries.tick()` function already:
1. Iterates `player.injuries` each turn
2. Advances FSM timers on each injury
3. Applies `damage_per_tick` from the current state
4. Checks `timed_events` for auto-transitions
5. Checks terminal states for death

Diseases slot into this pipeline with zero engine changes. The injury definitions declare the FSM states and timers; `injuries.tick()` advances them identically to physical injuries.

**New field for diseases:** `hidden_until_state` — suppresses injury display in `injuries.list()` until symptoms appear:

```lua
-- In a disease definition:
hidden_until_state = "symptomatic",  -- player doesn't see "rabies" during incubation
```

**Engine change:** ~5 lines in `injuries.list()` to check `hidden_until_state` against the injury's current state. If the injury hasn't reached the visible state yet, skip it in the listing. The player knows they were bitten (the bite wound is a separate minor-cut injury from combat) but doesn't know they're infected until symptoms appear.

#### C.3 Rabies Specification

**File:** `src/meta/injuries/rabies.lua`

```lua
return {
    guid = "{new-guid}",
    id = "rabies",
    name = "Rabies",
    category = "disease",
    damage_type = "degenerative",
    initial_state = "incubating",
    hidden_until_state = "prodromal",

    on_inflict = {
        initial_damage = 0,
        damage_per_tick = 0,
        message = "The bite wound throbs strangely.",
    },

    states = {
        incubating = {
            name = "animal bite",
            description = "A bite wound from a wild animal. It looks clean enough.",
            damage_per_tick = 0,
            timed_events = {
                { event = "transition", delay = 15, to_state = "prodromal" },
            },
        },
        prodromal = {
            name = "fever and malaise",
            description = "You feel feverish. The old bite wound itches terribly.",
            damage_per_tick = 2,
            restricts = { precise_actions = true },
            timed_events = {
                { event = "transition", delay = 10, to_state = "furious" },
            },
        },
        furious = {
            name = "hydrophobia",
            description = "You can't drink water. The thought of it makes you gag.",
            damage_per_tick = 5,
            restricts = { drink = true, precise_actions = true },
            timed_events = {
                { event = "transition", delay = 5, to_state = "fatal" },
            },
        },
        fatal = {
            name = "terminal rabies",
            description = "Seizures. Paralysis. The end approaches.",
            terminal = true,
            death_message = "The disease has run its course. You slip into darkness.",
        },
        cured = {
            name = "cured infection",
            description = "The infection has cleared.",
            terminal = true,
        },
    },

    transitions = {
        { from = "incubating", to = "prodromal", trigger = "auto", condition = "timer_expired" },
        { from = "prodromal", to = "furious", trigger = "auto", condition = "timer_expired" },
        { from = "furious", to = "fatal", trigger = "auto", condition = "timer_expired" },
    },

    healing_interactions = {
        ["healing-poultice"] = {
            transitions_to = "cured",
            from_states = { "incubating", "prodromal" },
            message = "The poultice draws out the infection. The fever breaks.",
        },
    },
}
```

**Timeline:** 15 turns incubation (silent) → 10 turns fever → 5 turns hydrophobia → death. Total: 30 turns from bite to death if untreated. Curable only in first 25 turns (incubating + prodromal) with a healing poultice.

**Delivery:** The rat's `bite` natural weapon gains `on_hit = { type = "disease", disease = "rabies", chance = 0.08 }`. Not every rat carries rabies — the 8% chance creates uncertainty without early-game frustration (CBG recommendation: 8% ≈ 1 in 12.5 bites; tunable post-GATE-5 up to max 12%).

**Gameplay intent:** Rabies creates a ticking clock the player doesn't know about. By the time symptoms appear (turn 15), they have only 10 turns to find and apply a healing poultice before it becomes incurable. This rewards players who treat animal bites prophylactically — good real-world-consistent design.

#### C.4 Spider Venom Specification

**File:** `src/meta/injuries/spider-venom.lua`

```lua
return {
    guid = "{new-guid}",
    id = "spider-venom",
    name = "Spider Venom",
    category = "poison",
    damage_type = "degenerative",
    initial_state = "injected",
    hidden_until_state = nil,  -- immediate symptoms; no hidden phase

    on_inflict = {
        initial_damage = 3,
        damage_per_tick = 2,
        message = "Burning pain spreads from the bite. Your skin prickles.",
    },

    states = {
        injected = {
            name = "venom burning",
            description = "The bite site is swollen and hot. Numbness creeps outward.",
            damage_per_tick = 2,
            timed_events = {
                { event = "transition", delay = 5, to_state = "spreading" },
            },
        },
        spreading = {
            name = "spreading numbness",
            description = "Your fingers tingle. Your limbs feel heavy and slow.",
            damage_per_tick = 3,
            restricts = { precise_actions = true, attack_penalty = true },
            timed_events = {
                { event = "transition", delay = 5, to_state = "paralysis" },
            },
        },
        paralysis = {
            name = "partial paralysis",
            description = "You can barely move. Your breathing is shallow.",
            damage_per_tick = 4,
            restricts = {
                precise_actions = true,
                attack = true,
                movement = true,
            },
            timed_events = {
                { event = "transition", delay = 5, to_state = "fatal" },
            },
        },
        fatal = {
            name = "respiratory failure",
            description = "Your diaphragm seizes. You can't breathe.",
            terminal = true,
            death_message = "The venom stops your lungs. Darkness takes you.",
        },
        neutralized = {
            name = "neutralized venom",
            description = "The burning fades. Feeling returns to your limbs.",
            terminal = true,
        },
    },

    transitions = {
        { from = "injected", to = "spreading", trigger = "auto", condition = "timer_expired" },
        { from = "spreading", to = "paralysis", trigger = "auto", condition = "timer_expired" },
        { from = "paralysis", to = "fatal", trigger = "auto", condition = "timer_expired" },
    },

    healing_interactions = {
        ["antidote"] = {
            transitions_to = "neutralized",
            from_states = { "injected", "spreading", "paralysis" },
            message = "The antidote works fast. The numbness recedes.",
        },
        ["healing-poultice"] = {
            transitions_to = "neutralized",
            from_states = { "injected", "spreading" },
            message = "The poultice slows the venom. You can feel your fingers again.",
        },
    },
}
```

**Key differences from rabies:**

| Property | Rabies | Spider Venom |
|----------|--------|-------------|
| Onset | Delayed (15 turns) | Immediate |
| Hidden? | Yes (incubation) | No (instant symptoms) |
| Delivery chance | 8% per bite | 100% per bite |
| Cure window | Early stages only | All non-fatal stages |
| Progression speed | Slow (30 turns total) | Fast (15 turns total) |
| Movement restriction | No | Yes (paralysis) |

**Gameplay intent:** Spider venom is the opposite of rabies — immediate, obvious, fast. The player knows they're poisoned and has limited time to find an antidote or poultice. Venom creates urgency; rabies creates dread.

#### C.5 Integration with injuries.lua

**No structural changes to `injuries.lua` needed.** Diseases are injury types. The existing system already supports:

- ✅ FSM state progression (`states`, `transitions`, `timed_events`)
- ✅ Per-tick damage accumulation (`damage_per_tick`)
- ✅ Terminal state handling (`terminal = true`, `death_message`)
- ✅ Healing via treatment objects (`healing_interactions`)
- ✅ Activity restrictions (`restricts`)
- ✅ Degenerative damage type (`damage_type = "degenerative"`)

**Minor additions to `injuries.lua`:**

1. **`hidden_until_state` support** (~5 lines in `injuries.list()`):
   ```lua
   -- Skip hidden injuries in listing
   if injury.hidden_until_state and injury._state ~= injury.hidden_until_state
      and not has_passed_state(injury, injury.hidden_until_state) then
       goto continue
   end
   ```

2. **Disease category display** (~3 lines in injury status formatting):
   ```lua
   -- Show disease name differently from wound name
   if def.category == "disease" or def.category == "poison" then
       prefix = "Affliction: "
   end
   ```

**Total engine change:** ~10 lines in `injuries.lua`. Everything else is new `.lua` definition files in `src/meta/injuries/`.

---

### D. Food Proof-of-Concept

#### D.1 Food as Objects

Food items are standard objects with `template = "small-item"` plus food-specific metadata. No new template needed — food is a small item you can eat.

**Food metadata fields:**

```lua
-- Added to any object that is edible:
edible = true,
food = {
    nutrition = 20,               -- hunger reduction value
    effects = {},                 -- array of on-eat effects (heal, buff, poison risk)
    bait_value = 50,              -- attractiveness to hungry creatures (0-100)
    spoilage = true,              -- whether this food spoils over time
},
```

**Example: cheese (`src/meta/objects/cheese.lua`):**

```lua
return {
    guid = "{new-guid}",
    template = "small-item",
    id = "cheese",
    name = "a wedge of cheese",
    keywords = { "cheese", "wedge", "food" },
    description = "A wedge of hard yellow cheese, slightly crumbly at the edges.",

    on_feel = "Firm and waxy. Slightly oily surface.",
    on_smell = "Sharp, tangy. Undeniably cheese.",
    on_listen = "Silent.",
    on_taste = "Sharp, salty, rich. Satisfying.",

    material = "organic",
    size = "tiny",
    weight = 0.3,
    portable = true,

    edible = true,
    food = {
        nutrition = 20,
        effects = {
            { type = "heal", amount = 5 },
        },
        bait_value = 70,          -- rats love cheese
        spoilage = true,
    },

    -- Food spoilage FSM
    initial_state = "fresh",
    _state = "fresh",
    states = {
        fresh = {
            description = "A wedge of hard yellow cheese, slightly crumbly at the edges.",
            on_smell = "Sharp, tangy. Good cheese.",
            on_taste = "Sharp, salty, rich. Satisfying.",
            room_presence = "A wedge of cheese sits here.",
            timed_events = {
                { event = "transition", delay = 60, to_state = "stale" },
            },
        },
        stale = {
            description = "A wedge of cheese, going dry and hard at the edges.",
            on_smell = "Still cheesy, but fading.",
            on_taste = "Bland and rubbery. Edible, but barely.",
            room_presence = "A dried-out wedge of cheese sits here.",
            timed_events = {
                { event = "transition", delay = 60, to_state = "rotten" },
            },
        },
        rotten = {
            description = "A moldy, green-spotted lump that was once cheese.",
            on_smell = "An aggressive, sour stink. Definitely off.",
            on_taste = "You gag. That is NOT food anymore.",
            room_presence = "A moldy lump of something organic festers here.",
        },
    },
    transitions = {
        { from = "fresh", to = "stale", trigger = "auto", condition = "timer_expired" },
        { from = "stale", to = "rotten", trigger = "auto", condition = "timer_expired" },
    },
}
```

#### D.2 The `eat` Verb

**File:** `src/engine/verbs/init.lua` (new verb entry)

```lua
verbs.eat = function(context, noun)
    local obj = find_in_hands(context, noun)
    if not obj then
        obj = find_in_room(context, noun)
        if not obj then
            err_not_found(context, noun)
            return
        end
        -- Must be holding food to eat it
        print("You'd need to pick that up first.")
        return
    end

    if not obj.edible then
        print("You can't eat " .. (obj.name or "that") .. ".")
        return
    end

    -- State-dependent effects
    local state = obj._state
    local state_def = obj.states and obj.states[state]

    -- Rotten food: risk of sickness
    if state == "rotten" then
        print("You force down the rotten " .. obj.id .. ". Your stomach lurches.")
        injuries.inflict(context.player, "poisoned-nightshade", obj.id, nil, 3)
    else
        -- Normal consumption
        local taste = (state_def and state_def.on_taste) or obj.on_taste
        if taste then
            print(taste)
        end
        print("You eat " .. obj.name .. ".")
    end

    -- Apply food effects
    if obj.food and obj.food.effects then
        for _, effect in ipairs(obj.food.effects) do
            if effect.type == "heal" then
                -- Reduce total damage from injuries
                heal_player(context.player, effect.amount)
            end
        end
    end

    -- Consume the object (remove from game)
    remove_from_hands(context, obj)
    context.registry:remove(obj.guid)
end
```

**Verb aliases:** `eat`, `consume`, `devour` all map to the same handler. The preprocess pipeline normalizes these.

**Healing via food:** The `heal_player()` helper reduces `damage` on the player's least-severe active injury. It does NOT create new injuries or interact with the injury FSM — it just subtracts from accumulated damage. Simple and predictable for the PoC.

#### D.3 Bait Mechanic

Food creates emergent creature behavior: drop food in a room with a hungry creature, and the creature approaches.

**How it works:**

1. Food objects have `food.bait_value` (0–100)
2. Creatures have a `hunger` drive (already implemented in Phase 1)
3. During `creature_tick()`, in the `score_actions()` function, add a scan for food:

```lua
-- In score_actions(), new food-seeking branch:
if creature.drives.hunger and creature.drives.hunger.value > 40 then
    local food_items = find_food_in_room(context, creature.location)
    if #food_items > 0 then
        local best_food = max_by(food_items, function(f) return f.food.bait_value or 0 end)
        scores["approach_food"] = creature.drives.hunger.value
                                + (best_food.food.bait_value or 0) / 2
                                + random_jitter(-5, 5)
        creature._target_food = best_food
    end
end
```

4. New action `"approach_food"` in `execute_action()`:
   - Move toward food (if in same room: "eat" it — remove from room, reduce hunger)
   - If in adjacent room: move toward room with food (food smell as stimulus)
   - Emit message: *"The rat creeps toward the cheese, whiskers twitching."*

**`find_food_in_room()` helper:**

```lua
local function find_food_in_room(context, room_id)
    local room = context.registry:find_room(room_id)
    local food = {}
    for _, obj in ipairs(room.contents or {}) do
        if obj.edible and obj.food then
            food[#food + 1] = obj
        end
    end
    return food
end
```

**Gameplay loop:** Player finds cheese → drops cheese in hallway → rat smells cheese → rat enters hallway → rat approaches cheese → player can now `catch rat` while it's distracted (fear_delta reduced by food presence). This emerges from existing systems — no scripting.

**Food smell propagation:** Food with `food.bait_value > 0` emits a `food_smell` stimulus to adjacent rooms during the FSM tick (smells travel through exits). Creatures with `smell_range >= 1` detect it and may wander toward the source. This reuses the existing stimulus pipeline.

#### D.4 Food Spoilage FSM

Food spoilage uses the **existing FSM timer system** — no engine changes. Each food object declares its spoilage states inline (see cheese example in D.1).

**Spoilage progression:**

```
fresh → stale → rotten
```

| State | Effect on eat | Effect on bait | Timer |
|-------|-------------|---------------|-------|
| `fresh` | Full nutrition, positive effects | Full bait_value | 60 ticks |
| `stale` | Reduced nutrition (÷2), no heal | Reduced bait_value (÷2) | 60 ticks |
| `rotten` | Poison risk (poisoned-nightshade) | Increased bait_value for some creatures (rats eat anything) | Terminal |

**Design note:** Spoilage timers are intentionally long for the PoC (60 ticks each = 120 ticks total). This can be tuned during playtesting. The point is proving the FSM pattern works, not balancing the numbers.

**Minimal scope:** The PoC needs exactly 2 food objects (cheese and bread/meat) to validate the system. Object-specific variety (wines, berries, mushrooms) is future work.

#### D.5 Integration with Sensory System

Food objects already have `on_taste` and `on_smell` fields — these are standard object properties. Phase 2 adds food-state-aware sensory responses:

**State-dependent sensory text** (already supported by the FSM state system):

```lua
states = {
    fresh = {
        on_smell = "Sharp, tangy. Good cheese.",
        on_taste = "Sharp, salty, rich.",
    },
    rotten = {
        on_smell = "Sour, aggressive. Definitely off.",
        on_taste = "You gag. Not food anymore.",
    },
}
```

The existing look/smell/taste verb handlers already check `state_def.on_X` before falling back to `obj.on_X`. No engine change needed.

**Taste-as-identification:** A player can `taste cheese` to discover its state without eating it. Fresh cheese tastes good; rotten cheese makes them gag (but doesn't cause poisoning — you have to `eat` to get poisoned). This preserves the existing design where taste is a diagnostic tool (see poisoned-nightshade pattern).

---

## 2. Cross-System Integration Points

This section maps where the four systems connect to each other and to existing engine infrastructure.

### 2.1 Integration Matrix

| System A | System B | Integration Point | Direction |
|----------|----------|-------------------|-----------|
| Creature Generalization | NPC-vs-NPC Combat | `attack` action in creature_tick() calls combat FSM | A → B |
| Creature Generalization | Disease | Predator-prey combat delivers diseases via on_hit | A → B → C |
| Creature Generalization | Food PoC | Creature hunger drive responds to food bait | A ← D |
| NPC-vs-NPC Combat | Disease | on_hit field on natural weapons delivers diseases | B → C |
| NPC-vs-NPC Combat | Food PoC | Combat may occur near food (creature defending food) | Indirect |
| Disease | Food PoC | Rotten food causes poisoning (reuses injury system) | C ← D |
| Disease | Existing injuries.lua | Diseases ARE injuries with FSM progression | C → Existing |
| Food PoC | Existing FSM engine | Spoilage uses standard timed FSM transitions | D → Existing |
| All Systems | Existing sensory system | Light/darkness narration, on_feel/on_smell/on_taste | All → Existing |

### 2.2 Creature Generalization ↔ NPC-vs-NPC Combat

**Connection:** The `attack` action in `creature_tick()` is the bridge between creature behavior and the combat system.

**Data flow:**

```
creature_tick()
  → score_actions() picks "attack"
  → find_attack_target() selects target
  → select_natural_weapon() picks weapon
  → combat.resolve_exchange(creature, target, weapon, zone)  ← enters combat system
  → combat returns: { severity, damage, messages, defender_state }
  → creature_tick() applies results (injury, death, narration)
  → if multi-round: track in context.active_fights
```

**Shared state:** `context.active_fights` tracks ongoing multi-combatant fights. Both `creature_tick()` (to decide whether to continue attacking or flee) and the combat module (to track turn order and round progression) read and write this table.

**Conflict avoidance:** The combat module never modifies creature behavior metadata. The creature module never modifies combat resolution logic. They communicate through the fight state table and the `resolve_exchange()` function interface.

### 2.3 NPC-vs-NPC Combat ↔ Disease

**Connection:** The `on_hit` field on natural weapons triggers disease delivery during combat resolution.

**Data flow:**

```
combat.resolve_exchange()
  → severity >= GRAZE (hit lands)
  → check weapon.on_hit
  → if on_hit.type == "disease":
      → roll against on_hit.chance
      → if success: injuries.inflict(defender, on_hit.disease, attacker.id, zone)
  → disease now tracked in defender's injury list
  → injuries.tick() advances disease FSM each turn
```

**Principle 8 compliance:** The combat engine doesn't know what "rabies" or "spider-venom" is. It sees an `on_hit` table with a disease ID and a probability. It calls `injuries.inflict()` with that ID. The injury system loads the disease definition and handles everything from there.

**Cross-species disease:** The same mechanism works for any combatant type. A rat bites a cat → cat might get rabies. A spider bites a rat → rat gets venom. The engine doesn't care about species — it evaluates weapon metadata.

### 2.4 Creature Generalization ↔ Food PoC

**Connection:** The creature hunger drive creates demand for food objects. Food's `bait_value` creates supply for creature attraction.

**Data flow:**

```
creature_tick()
  → update_drives(): hunger increases each tick
  → score_actions(): if hunger > 40, scan room for edible objects
  → if food found: score "approach_food" high
  → execute_action("approach_food"):
      → creature moves toward food
      → creature "eats" food (removes from room, reduces hunger drive)
      → emit message about creature eating
```

**Food smell as stimulus:**

```
FSM tick on food object
  → food emits "food_smell" stimulus to current room + adjacent rooms
  → creature_tick() process_stimuli() checks for food_smell
  → creature with hunger drive scores "wander toward food source" higher
```

**Bait trap pattern:**

```
Player drops food in room
  → food_smell stimulus propagates
  → creature in adjacent room detects smell
  → creature wanders toward food room
  → creature approaches food
  → while creature is distracted: player can catch/attack with advantage
```

### 2.5 Disease ↔ Food PoC

**Connection:** Rotten food causes poisoning through the `eat` verb, using the existing injury system.

**Data flow:**

```
Player eats rotten food
  → eat verb checks obj._state == "rotten"
  → injuries.inflict(player, "poisoned-nightshade", obj.id, nil, 3)
  → existing poisoned-nightshade injury FSM handles symptoms
```

This is a one-way connection. Diseases don't affect food. Food in the `rotten` state becomes a hazard that feeds into the injury system. The `poisoned-nightshade` injury type already exists — no new disease definition needed for food poisoning.

### 2.6 All Systems ↔ Existing Engine Infrastructure

**Shared dependencies (existing, unchanged):**

| Engine Module | Used By | How |
|--------------|---------|-----|
| `injuries.lua` | Disease, Food (rotten), Combat | `inflict()`, `tick()`, `list()`, `try_heal()` |
| `creatures/init.lua` | Creature Gen, NPC Combat, Food | `tick()`, `emit_stimulus()`, `score_actions()` |
| `combat/init.lua` | NPC Combat, Disease (on_hit) | `resolve_exchange()` |
| `combat/narration.lua` | NPC Combat witness | `narrate_exchange()` with `witness_mode` |
| `fsm/init.lua` | Food spoilage, Disease progression | `timed_events`, auto-transitions |
| `registry/init.lua` | All systems | Object lookup, room contents, creature discovery |
| `loop/init.lua` | All systems | Tick ordering: verb → FSM → creature → injury |
| `verbs/init.lua` | Food (eat verb), Creature (attack) | Verb dispatch |

**Tick ordering (unchanged):**

```
Player input → Verb handler → FSM tick → Fire tick → Creature tick → Injury tick → Death check
                                 ↑                        ↑               ↑
                           Food spoilage         NPC combat        Disease progression
                           advances here         happens here      advances here
```

The existing tick order naturally places creature combat (in creature tick) before disease advancement (in injury tick), which means diseases inflicted during combat take effect the same turn. This is correct — a spider bite delivers venom that starts ticking immediately.

### 2.7 File Ownership Summary

| New/Modified File | Owner | Systems |
|-------------------|-------|---------|
| `src/engine/creatures/init.lua` (modified) | Bart | A, B, D |
| `src/engine/combat/init.lua` (modified) | Bart | B, C |
| `src/engine/combat/narration.lua` (modified) | Bart | B |
| `src/engine/injuries.lua` (modified) | Bart | C |
| `src/engine/verbs/init.lua` (modified) | Smithers | D |
| `src/meta/injuries/rabies.lua` (new) | Flanders | C |
| `src/meta/injuries/spider-venom.lua` (new) | Flanders | C |
| `src/meta/objects/spider-web.lua` (new) | Flanders | A |
| `src/meta/objects/cheese.lua` (new) | Flanders | D |
| `src/meta/creatures/cat.lua` (new) | Flanders | A, B |
| `src/meta/creatures/spider.lua` (new) | Flanders | A, C |
| `src/meta/creatures/guard-dog.lua` (new) | Flanders | A |
| `src/engine/verbs/movement.lua` (modified) | Bart | A (trap check) |

**No new engine modules.** All Phase 2 features are extensions of existing modules. This is by design — the architecture from Phase 1 was built to absorb this complexity.

---

# NPC + Combat Phase 2 — Chunk 5: Operations

**Author:** Bart (Architect)
**Date:** 2026-07-30
**Chunk:** 5 of 5 — Risk Register, Autonomous Execution, Gate Failure, Wave Checkpoints, Documentation Deliverables
**Phase:** Phase 2: Creature Variety + Disease + Food PoC

---

## Section 10: Risk Register

| # | Risk | Like. | Impact | Mitigation |
|---|------|-------|--------|------------|
| R-1 | **Creature-to-creature cascade (3+ in one room)** | High | High | Hard cap: max 3 creature reactions per tick per room. Wolf's reaction to cat-kills-rat queues for NEXT tick. Unit test: 3-creature room, no infinite loop. |
| R-2 | **Multi-combatant turn order** | Med | High | Pairwise resolution only. 3-way fight = 2 exchange cycles per round (priority queue). No true N-way combat. Test with 3 fixed-seed combatants. |
| R-3 | **Rabies too lethal** | Med | Med | 15-turn incubation + 8% transmission chance (reduced from 15% per CBG review). Poultice cures early stages. Tuning knob at GATE-4 LLM testing. Max 12% in Level 1. Fallback: extend incubation to 25 turns. |
| R-4 | **Spider venom too punishing** | Med | Med | Spider is ambush-only (`territorial`), player must enter its room. Antidote available same level. CBG reviews at GATE-4. |
| R-5 | **Food system scope creep** | High | High | Hard boundary: eat/drink verbs + 2 food objects + hunger satisfaction ONLY. No cooking/spoilage/recipes. If >1 wave, cut. |
| R-6 | **Engine files approaching 500 LOC** | Med | Med | Module size guard (Pattern 13). Pre-emptive split in WAVE-0 (Chalmers fix): `creatures/init.lua` → `stimulus.lua` + `predator-prey.lua`; `combat/init.lua` → `npc-behavior.lua`. Post-split all files <500 LOC. |
| R-7 | **Spider web — new creature-created object pattern** | Med | High | First runtime-spawned object (not in room files). Prototype in isolation BEFORE WAVE-2. Dedicated test: tick → web in room → valid GUID → keyword resolves. Fallback: defer web to Phase 3, ship spider with bite-only. |
| R-8 | **Performance: 10 creatures ticking** | Low | High | Spatial optimization from Phase 1 (full-tick player's room only). Benchmark at GATE-2 with 10 creatures across 3 rooms. Budget: <50ms total. Fallback: batch ticks (3 per frame, round-robin). |
| R-9 | **NPC combat narration floods output** | Med | Med | Cap witness narration: 2 lines per exchange (same room), 1 line (adjacent room). Test: 3-creature fight ≤6 lines per round. |
| R-10 | **File conflicts between agents** | Med | High | Explicit file ownership per wave. `git diff --stat` verification after each agent. Phase 2 has more creature files — wave assignments must be granular. |
| R-11 | **Phase 1 test regression** | Low | Critical | `lua test/run-tests.lua` at every gate. Phase 1 count is baseline — any decrease is a blocker. |
| R-12 | **Disease + injury FSM interaction** | Med | Med | Both use `injuries.inflict()`. Test: player with wound AND rabies — verify independent ticking, independent healing. |

---

## Section 11: Autonomous Execution Protocol

### Coordinator Execution Loop

```
FOR each WAVE in [WAVE-0 through WAVE-5]:

  1. PRE-WAVE: Verify previous gate passed. Read plan status tracker.

  2. SPAWN parallel agents per wave table.
     - Each agent: task, exact files, TDD reqs. No file overlap. Max 4 agents.

  3. COLLECT results. Verify: files match spec, no unintended changes (git diff --stat).

  4. RUN gate tests:
     a. lua test/run-tests.lua           (zero regressions)
     b. Wave-specific new test files      (all pass)
     c. LLM walkthrough (GATE-3, GATE-5)
     d. Doc existence (GATE-1, GATE-3, GATE-4, GATE-5)
     e. Performance benchmark (GATE-2)

  5. EVALUATE:
     PASS → git tag phase2-gate-N → commit → push → status ✅ → next wave
     FAIL → Gate Failure Protocol (Section 12)

  6. WAVE CHECKPOINT (Section 13)
```

### Commit & Tag Pattern

Commit per gate: `PHASE-2 GATE-N: {description}` with Co-authored-by trailer.
Git tag per gate: `phase2-gate-1` through `phase2-gate-5` for rollback.

### Parallel Agent Constraints

- Max 4 agents per wave, all start simultaneously
- No agent starts until previous GATE passes
- Early-finishing agents do NOT start next wave's work
- Multiple Nelson/Flanders instances OK if writing different files

### Nelson Continuous LLM Testing

| When | Type | Scope |
|------|------|-------|
| After every wave | Smoke (~5 cmds) | Boot + basic interaction + no crash |
| GATE-1 | Unit only | Creature defs load and validate |
| GATE-3 | Full walkthrough | NPC-vs-NPC combat, witness narration, intervention |
| GATE-4 | Disease scenarios | Rabies incubation, venom delivery, dual injury |
| GATE-5 | Food walkthrough | Eat/drink, hunger satisfaction |
| Between waves | Exploratory | Edge cases, darkness, multi-creature rooms |

All runs: `--headless` + `math.randomseed(42)`.

### CBG Design Review

| Gate | Focus |
|------|-------|
| GATE-1 | Creature distinctness, sensory vividness |
| GATE-3 | NPC combat feel, witness narration atmosphere |
| GATE-4 | Disease discoverability, fairness |
| GATE-5 | Food naturalness, PoC minimality |

Design debt → `.squad/decisions/inbox/cbg-design-debt-phase2-WAVE-N.md`.

### Wayne Check-In Points

1. **GATE-3** — witness cat-kills-rat scenario
2. **GATE-5** — play-test disease + food
3. **Any escalation** from 1x-failure rule

### Decision Authority & Autonomy Protocol (Marge review fix)

Phase 2 must be executable without Wayne present for routine decisions. This section defines who decides what.

#### Gate Decision Authority

| Gate | Authority | Rule |
|------|----------|------|
| GATE-0 | Bart (sole authority) | Bart declares pass/fail on LOC guard + regression check |
| GATE-1 | Bart + Marge | Both must agree PASS. Any FAIL = re-work. |
| GATE-2 | Bart + Marge | Bart: architecture correctness. Marge: performance check. |
| GATE-3 | Bart + Nelson | Bart: architecture. Nelson: LLM walkthrough pass. |
| GATE-4 | Bart + Marge | Bart: architecture. Marge: regression analysis. |
| GATE-5 | Bart + Nelson + CBG | Bart: architecture. Nelson: full LLM. CBG: player experience. |

**Decision rule:** Unanimous "PASS" = gate passes. Any "FAIL" = re-work required. Ambiguous outcome (e.g., "performance is 48ms, budget is 50ms") = escalate to Wayne.

#### Parallel Wave Conflict Resolution

When agents disagree during a wave (e.g., Nelson's test fails on Bart's code):

1. **Bart's code fails Nelson's test:** Bart has 4 hours to fix. If unfixed, Nelson escalates to Wayne.
2. **Nelson's test appears wrong:** Nelson has 2 hours to debug/revise test. If unresolved, Bart escalates to Wayne.
3. **Flanders' data incompatible with engine:** Bart + Flanders jointly diagnose (1 hour). If unresolved, escalate to Wayne.
4. **Smithers' narration doesn't match spec:** Smithers has 2 hours to revise. CBG arbitrates tone/content disputes.

#### Emergency Abort Protocol

If a wave discovers a fundamental architectural flaw mid-implementation (e.g., creature predator-prey is O(n²) and runs at 200ms):

1. **Stop current wave.** No further commits.
2. **Bart assesses:** Can it be fixed within 1 day? → Fix in-place, continue wave.
3. **Cannot fix in 1 day:** Wayne decides:
   - (A) Ship with known issue + documented tech debt
   - (B) De-scope feature (e.g., defer food to Phase 3)
   - (C) Re-architect (pause Phase 2, re-plan affected waves)

---

## Section 12: Gate Failure Protocol

### Failure Handling

**Step 1 — First failure:**
- File GitHub issue: gate ID, failed test(s), full error output, implicated file/agent, `git diff`
- Assign fix to file owner. Re-gate failed items only (not full suite).
- **Escalate to Wayne** with diagnostic summary (1x threshold — inherited from Phase 1)

**Step 2 — Second failure (same test):**
- Escalate to Wayne: original failure + fix attempt + second failure + Bart's assessment
- Wayne decides: different agent, redesign, or defer

### Re-gating Rules

- Re-gate tests ONLY failed items. Passing tests not re-run.
- After fix: run failing test file in isolation, then `lua test/run-tests.lua` for regressions.
- Pass → next wave. Fail → Step 2.

### Lockout Policy

Agent fails twice on same issue → locked out. Fresh agent (or Bart for architecture) takes over.

### Phase 2-Specific Escalation

| Condition | Action |
|-----------|--------|
| Gate fails 1x | File issue → fix → re-gate → **escalate Wayne** |
| Unexpected file changes | Reject, re-run. Repeated → lock out agent |
| Phase 1 test regression | **STOP all work.** Fix first. |
| Phase 2 prior-wave regression | Stop current wave. Fix before continuing. |
| LLM fails, unit passes | Integration gap — Bart diagnoses |
| Perf >50ms creature tick | Bart profiles → spatial opt → batch ticks |
| Disease causes injury regression | Isolate, roll back disease changes |
| Spider web fails | Defer web to Phase 3, ship bite-only spider |
| NPC combat infinite loop | Apply cascade cap (R-1). Still loops → pairwise-only |
| Food exceeds scope | Cut to 1 food object + eat verb only |
| Missing docs at gate | Block gate. Assign Brockman. |

### Rollback

Git tags per gate. Revert to `phase2-gate-(N-1)` if needed. Never roll back >2 waves without Wayne.

### Crash & Recovery Protocol (Chalmers review fix)

#### Mid-Wave Failure

If a wave is incomplete (e.g., agent fails, session dies, partial work committed):

1. **Status check:** Each agent reports completed/incomplete files. Coordinator runs `git diff --stat` to assess.
2. **Partial test run:** Run test suite on completed deliverables only. Incomplete files' tests are skipped (not failed).
3. **Resume, don't restart:** Remaining agents pick up where they left off. No re-planning. Completed files are NOT reverted.
4. **Session continuity:** If session dies mid-wave, next session reads Wave Status Tracker, resumes from last verified file. Partial wave with failing tests = re-run the failing agent's task only (`git checkout` their files, re-execute).

#### Gate Failure Classifications

| Failure Type | Owner | SLA | Rollback? | Example |
|-------------|-------|-----|-----------|---------|
| **Data load failure** (creature/object doesn't parse) | Flanders | 1 hour | No (in-place fix) | `cat.lua` syntax error |
| **Test infrastructure failure** (test dir not found, runner crash) | Nelson | 30 min | No (in-place fix) | `test/food/` not registered |
| **Engine bug** (attack action crashes, infinite loop) | Bart | 2 hours | Yes (roll back wave) | `execute_action("attack")` nil error |
| **Material resolution failure** (tissue/chitin not found) | Flanders | 1 hour | No (create missing material) | `hide` material undefined |
| **Narration/verb bug** (output garbled, wrong message) | Smithers | 1 hour | No (in-place fix) | Witness narration shows visual in dark |
| **LLM scenario non-deterministic** (passes sometimes, fails other times) | Nelson | 1 hour (re-seed) | Maybe (investigate first) | Seed 42 fails, 43 passes |
| **Performance budget exceeded** (>50ms creature tick) | Bart | 3 hours | No (optimize in-place) | Predator-prey scan too slow |

#### Gate Failure Escalation Matrix (Chalmers review fix)

| Gate | Failure Category | Primary Owner | Escalation If SLA Expires | Rollback Scope |
|------|-----------------|---------------|--------------------------|----------------|
| GATE-0 | Test dir / LOC guard | Nelson / Bart | Bart takes over | No rollback (pre-flight) |
| GATE-1 | Creature load fails | Flanders | Bart reviews data format | Roll back WAVE-1 creature files |
| GATE-1 | Material resolution | Flanders | Bart creates material stubs | No rollback |
| GATE-2 | Attack action crashes | Bart | Escalate to Wayne | Roll back WAVE-2 engine changes |
| GATE-2 | Predator-prey wrong | Bart | Nelson writes diagnostic test | No rollback (in-place fix) |
| GATE-3 | Multi-combatant hangs | Bart | Escalate to Wayne (re-design?) | Roll back WAVE-3 |
| GATE-3 | Narration wrong | Smithers | Bart reviews spec | No rollback |
| GATE-4 | Disease FSM stuck | Bart or Flanders | Cross-check data vs engine | No rollback (in-place fix) |
| GATE-5 | LLM fails non-deterministic | Nelson | Re-seed (43, 44). 3 fails = bug. | Investigate before rollback |
| GATE-5 | Integration regression | Bart | Full team diagnostic | Roll back to GATE-4 tag |

**Decision rules:**
- Code bugs (Bart/Smithers): SLA 2-3 hours. Roll back wave on second failure.
- Data issues (Flanders/Moe): SLA 1 hour. In-place fix. No rollback.
- Test/infra issues (Nelson): SLA 30 min – 1 hour. In-place fix.
- **If SLA expires:** Escalate to Wayne for judgment (defer wave, split task, re-assign agent).

---

## Section 13: Wave Checkpoint Protocol

### After Every Wave Completes

**1. Verify Completion** — All files from wave table exist, content spot-checked, `git diff --stat` matches, no TODO/FIXME left.

**2. Update Plan Status Tracker**
```
| WAVE-0 | ✅ | WAVE-1 | ✅ | WAVE-2 | 🟡 | WAVE-3–5 | ⏳ |
```

**3. Record Deviations** — What changed, why, impact on future waves.

**4. Capture Test Baseline** — Exact counts per wave. Any decrease = blocker.

**5. Architecture Health Check (Bart)**
- [ ] No module >500 LOC
- [ ] Public API contracts frozen for dependent waves
- [ ] Debug hooks in new engine code
- [ ] Performance baseline measured
- [ ] Consistent error handling
- [ ] No object-specific logic in engine (Principle 8)

**6. Commit + Push** — `PHASE-2 WAVE-N CHECKPOINT: {summary}`

**7. Session Continuity** — Session dies mid-wave → next session reads status tracker, resumes from last complete wave. Partial wave = re-run entirely (`git checkout .`).

### Post-Phase 2 Retrospective

After all waves: actual vs estimated scope, gate failures, new risks, performance actuals, candidate skill patterns, Phase 3 recommendations.

---

## Section 14: Documentation Deliverables

### Per-Gate Documentation Requirements

Documentation is a gate requirement — no gate ships without its docs. Brockman runs in parallel with Nelson's testing.

### New Documents

| Gate | Document | Path |
|------|----------|------|
| GATE-1 | Creature Variety Patterns | `docs/architecture/objects/creature-variety.md` |
| GATE-3 | NPC-vs-NPC Combat | `docs/architecture/combat/npc-combat.md` |
| GATE-4 | Disease System | `docs/architecture/engine/disease-system.md` |
| GATE-5 | Food System PoC | `docs/design/food-system.md` |

**GATE-1 — creature-variety.md:** Template inheritance, behavior profiles, drive tuning, combat metadata scaling. Reference: rat, cat, spider, wolf.

**GATE-3 — npc-combat.md:** Unified combatant interface, predator-prey triggers, pairwise resolution, turn order, witness narration, player intervention, cascade limits.

**GATE-4 — disease-system.md:** Disease as injury type, `on_hit` delivery, probability transmission, incubation FSM, cure interactions. Reference: rabies, spider-venom.

**GATE-5 — food-system.md:** PoC scope (eat/drink only), hunger drive integration, food object pattern, deferred features. Cross-ref: `resources/research/food/`.

### Updates to Existing Docs

| Document | Gate | Changes |
|----------|------|---------|
| `creature-system.md` | GATE-1 | Cat/spider/wolf profiles, creature-created objects pattern |
| `combat-fsm.md` | GATE-3 | NPC-vs-NPC exchange flow, multi-combatant turns, cascade limit |
| `stimulus-system.md` | GATE-3 | New stimuli: `predator_detected`, `prey_detected`, `creature_combat` |
| `object-design-patterns.md` | GATE-1 | Creature-created objects, dynamic GUID generation |
| `player-model.md` | GATE-5 | Hunger drive, food consumption effects |

### Standards

- Architecture/ vs design/ separation (D-BROCKMAN001)
- Brockman writes from implemented code, not plan specs
- Bart reviews for technical accuracy before gate sign-off
- Coordinator verifies: doc exists, non-empty, correct file path references
