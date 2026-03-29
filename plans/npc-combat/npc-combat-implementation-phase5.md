# NPC + Combat Phase 5 Implementation Plan

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-28  
**Version:** v2.0 (All 8 reviewer findings incorporated)  
**Revised:** 2026-03-29  
**Status:** 🟢 REVIEW-CLEAN — 17 fixes applied, 0 blockers  
**Requested By:** Wayne "Effe" Berry  
**Governs:** Phase 5: Level 2 Expansion → Werewolf NPC → Pack Coordination → Salt Preservation → Integration  
**Predecessor:** `plans/npc-combat/npc-combat-implementation-phase4.md` (Phase 4 — ✅ COMPLETE, 223 tests)  
**Reviewers:** CBG (game design), Marge (testing), Chalmers (sequencing/skill audit), Flanders (objects), Smithers (verbs/parser), Moe (rooms), Nelson (QA), Bart (architecture)

---

## Wave Status Tracker

| Wave | Name | Status | Gate | Tests |
|------|------|--------|------|-------|
| PRE-WAVE | Bug Triage + Level 2 Design Sketch | ⏳ Pending | — | 223 |
| WAVE-1 | Level 2 Foundation (7 Rooms + Creatures) | ⏳ Pending | GATE-1 | TBD |
| WAVE-2 | Pack Role System (Simplified Coordination) | ⏳ Pending | GATE-2 | TBD |
| WAVE-3 | Salt Preservation System | ⏳ Pending | GATE-3 | TBD |
| WAVE-4 | Integration + Polish + Docs | ⏳ Pending | GATE-4 | TBD |

---

## Section 1: Executive Summary

Phase 5 expands the world vertically and horizontally — **Level 2 geography** unlocks the deeper dungeon, **werewolf NPCs** introduce a new creature intelligence tier, **pack tactics** escalate wolf coordination to full role-based behavior, and **salt preservation** closes the resource sustainability loop. This is the ecosystem expansion phase.

### What We're Building

1. **Level 2 foundation** — 7 new rooms forming the deep dungeon's first zone. Brass key (from Level 1 finale) unlocks access. New biomes: catacombs, underground streams, collapsed cellars. New creature habitats: werewolf lair, wolf pack territories, spider nests.

2. **Werewolf as NPC type** — Wayne's Q1 decision: **Option B** (separate creature, not disease model). Werewolves are semi-intelligent territorial NPCs with enhanced combat stats, patrol behavior, and future dialogue hooks (Phase 6 scaffold only). Distinct from wolves — they are their own creature class.

3. **Pack role system (simplified)** — Wayne's Q4 decision: **Option A** (stagger attacks, alpha by health). Wolves coordinate attacks with turn-taking, alpha selection by highest HP, and basic reserve conditions (omega retreats if wounded). Zone-targeting deferred to Phase 6.

4. **Salt preservation** — Wayne's Q2 decision: **Option A** (salt-only, ~80 LOC). New `salt` verb, salt object, salted-meat mutation pipeline. Salted meat spoils 3× slower than fresh. Enables sustainable food storage for deep dungeon exploration.

5. **Integration + polish** — Final LLM walkthrough (brass key → Level 2 transition → new creature encounters → butcher → salt meat → rest safely), design documentation (Level 2 ecology, pack tactics v2, preservation economics), and regression testing.

### Why This Order

**Level 2 geography must exist first** (PRE-WAVE + WAVE-1) — everything else depends on it. Pack tactics require wolf placement in Level 2 territories (WAVE-2), salt preservation needs new food sources from Level 2 creatures (WAVE-3), and integration tests the full flow (WAVE-4). The strict dependency chain prevents rework.

### Phase 5 Theme: "Ecosystem Expansion"

- **Phase 3 theme:** "Creatures die and become useful"
- **Phase 4 theme:** "Resources flow through the crafting pipeline"
- **Phase 5 theme:** "The dungeon deepens, packs coordinate, survival requires planning"

The narrative arc: Player completes Level 1 → unlocks brass-key door → descends to Level 2 catacombs → encounters werewolf (territorial, dangerous) → witnesses coordinated wolf pack attacks → learns that food spoils fast in the deeper dungeon → salts meat for long-term storage → prepares for extended exploration.

### Scope Decisions Applied (Wayne's Q1-Q7)

| Question | Wayne's Decision | Impact on Phase 5 |
|----------|------------------|-------------------|
| Q1: Werewolf design | **Option B** (NPC type) | Werewolf is separate creature definition, not disease. Simplifies WAVE-1. |
| Q2: Preservation scope | **Option A** (salt-only) | One verb, one object, mutation pipeline. ~80 LOC total. WAVE-3 stays lean. |
| Q3: Humanoid NPCs | **Option C** (defer to Phase 6) | No dialogue framework, no memory system. Phase 5 stays creature-focused. |
| Q4: Pack roles | **Option A** (simplified) | Stagger attacks, alpha by health. No zone-targeting. ~150 LOC. |
| Q5: A* pathfinding | **Option B** (defer) | Keep random-exit selection. Phase 6+ feature. |
| Q6: Environmental combat | **Option B** (defer) | Push/throw/climb deferred to Combat Phase 3. |
| Q7: Portal refactoring | **Removed from scope** | Lisa's TDD work (#203-208) tracked independently. |

### Phase 4 Foundation (Already Built)

| Asset | Location | LOC |
|-------|----------|-----|
| Butchery system | `src/engine/verbs/butchery.lua` | ~120 |
| Loot tables engine | `src/engine/creatures/loot.lua` | ~180 |
| Stress injury | `src/meta/injuries/stress.lua` | ~90 |
| Spider web creation | `src/engine/creatures/actions.lua` (create_object) | ~60 |
| Silk crafting | `src/engine/verbs/crafting.lua` (extensions) | ~50 |
| Pack tactics v1 | `src/engine/creatures/pack.lua` | ~150 |
| 5 creatures | `src/meta/creatures/{rat,cat,wolf,spider,bat}.lua` | — |
| 10 injury types | `src/meta/injuries/` | — |
| ~223 tests passing | `test/` | — |

### Walk-Away Capability

Same protocol as Phase 1-4: wave → parallel agents → gate → pass → checkpoint → next wave. Gate failure at 1× threshold (escalate to Wayne immediately). Commit/push after every gate. Nelson continuous LLM walkthroughs.

---

## Section 2: Quick Reference Table

| Wave | Name | Parallel Tracks | Gate | Key Deliverables |
|------|------|-----------------|------|------------------|
| **PRE-WAVE** | Bug Triage + Level 2 Design Sketch | 4 tracks | — | 3 wiring bugs fixed (silk, craft, brass-key), Level 2 geography sketch (7 rooms), werewolf design spec, preservation design spec |
| **WAVE-1** | Level 2 Foundation (7 Rooms + Creatures) | 5 tracks | GATE-1 | 7 room definitions (catacombs, underground stream, werewolf lair, collapsed cellar, wolf territory, spider nest, storage room), werewolf.lua creature, brass-key transition wiring, Level 2 creature placement |
| **WAVE-2** | Pack Role System (Simplified Coordination) | 4 tracks | GATE-2 | Pack coordination engine (stagger attacks), alpha selection (highest HP), omega reserve (retreat if wounded), wolf metadata updates (pack_role field), territory expansion |
| **WAVE-3** | Salt Preservation System | 4 tracks | GATE-3 | `salt` verb handler, salt.lua object, salted-meat mutations (wolf-meat → salted-wolf-meat), FSM spoilage rate updates (3× slower for salted), tool requirement (container) |
| **WAVE-4** | Integration + Polish + Docs | 4 tracks | GATE-4 | Final LLM walkthrough (L1 → L2 full flow), design docs (level2-ecology.md, pack-tactics-v2.md, preservation-system.md), regression testing (ZERO failures vs Phase 4 baseline), Phase 5 checkpoint |

**Estimated new files:** ~25-30 (code + tests) + 3-4 doc files  
**Estimated modified files:** ~20-25 (engine modules, verbs, creature files, room definitions, test runner)  
**Estimated scope:** 5 waves (PRE-WAVE + WAVE-1 through WAVE-4), 4 gates (GATE-1 through GATE-4)  
**Test target:** 270+ passing tests (Phase 4 baseline: 223; Phase 5 adds ~50+ new tests)

---

## Section 3: Dependency Graph

```
PRE-WAVE: Bug Triage + Level 2 Design Sketch
├── [Nelson]   Fix 3 wiring bugs (silk disambiguation, craft recipe, brass key/padlock)
├── [Moe]      Level 2 geography sketch (7 rooms, exits, placement)
├── [Bart]     Werewolf design spec (stats, behavior, territorial AI)
└── [Bart]     Preservation design spec (salt mutation pipeline, spoilage rates)
        │
        ▼  ── (no formal gate — PRE-WAVE is setup for WAVE-1) ──
        │
WAVE-1: Level 2 Foundation (7 Rooms + Creatures)
├── [Moe]      7 room definitions (catacombs, stream, lair, cellar, territory, nest, storage) ┐
├── [Flanders] werewolf.lua creature (combat stats, patrol behavior, territorial AI)           │
├── [Flanders] Brass key object update (unlocks → deep-cellar-hallway door)                    │ parallel
├── [Bart]     Brass key transition logic (Level 1 end → Level 2 start)                        │
├── [Nelson]   Level 2 instantiation tests (all rooms load, exits route, creatures spawn)      │
└── [Smithers] Room presence updates for Level 2 objects                                        ┘
        │
        ▼  ── GATE-1 (Level 2 fully instantiable, brass key unlocks L2, werewolf exists, ZERO regressions) ──
        │
WAVE-2: Pack Role System (Simplified Coordination)
├── [Bart]     Pack coordination engine (stagger attacks, alpha selection, omega reserve)      ┐
├── [Flanders] Wolf metadata updates (pack_role field: alpha/beta/omega)                       │ parallel
├── [Bart]     Territory expansion (wolf pack zones in Level 2)                                │
├── [Nelson]   Pack tactics tests (stagger behavior, alpha selection, omega retreat)           │
└── [Smithers] Pack narration updates (combat text for coordinated attacks)                    ┘
        │
        ▼  ── GATE-2 (wolves coordinate attacks, alpha/omega roles work, ZERO regressions) ──
        │
WAVE-3: Salt Preservation System
├── [Smithers] `salt` verb handler + aliases                                                   ┐
├── [Flanders] salt.lua object (small-item, consumable, preservative capability)               │ parallel
├── [Flanders] Salted-meat mutations (wolf-meat → salted-wolf-meat, etc.)                      │
├── [Bart]     FSM spoilage rate updates (salted = 3× slower decay)                            │
├── [Nelson]   Preservation tests (salt verb, mutations, spoilage rates, tool requirements)    │
└── [Smithers] Preservation narration (salting process, salted-meat descriptions)              ┘
        │
        ▼  ── GATE-3 (salt verb works, salted meat lasts longer, ZERO regressions) ──
        │
WAVE-4: Integration + Polish + Docs
├── [Nelson]   Final LLM walkthrough (brass key → L2 → werewolf → pack → butcher → salt)      ┐
├── [Brockman] Design docs (level2-ecology.md, pack-tactics-v2.md, preservation-system.md)     │ parallel
├── [Bart]     Regression testing (full test suite vs Phase 4 baseline)                        │
├── [Scribe]   Phase 5 checkpoint (orchestration log, decision merge, status update)           │
└── [Nelson]   Test flakiness audit (document any non-deterministic tests)                     ┘
        │
        ▼  ── GATE-4 (Phase 5 COMPLETE — full feature set verified, docs complete, ZERO regressions) ──
        │
        ═══ PHASE 5 COMPLETE ═══
```

### Key Dependency Chain

```
Phase 4 ──→ PRE-WAVE (bugs + design) ──→ W1 (Level 2 foundation) ──┐
                                              │                      │
                                              ├─────→ W2 (pack) ────┤
                                              │                      │
                                              ├─────→ W3 (salt) ─────┤
                                              │                      │
                                              └──────────────────────┴──→ W4 (integration + docs)
```

**Hard blockers:**
- PRE-WAVE must complete before WAVE-1 (bug fixes prevent test pollution)
- WAVE-1 must complete before WAVE-2 and WAVE-3 (Level 2 geography is prerequisite)
- WAVE-2 and WAVE-3 can run in parallel (no file overlap)
- WAVE-4 requires WAVE-1, WAVE-2, and WAVE-3 all complete (integration testing)

**Parallelization opportunities:**
- PRE-WAVE: Nelson, Moe, Bart all work independently (different files)
- WAVE-1: 5-6 parallel tracks (rooms, creatures, objects, tests, room presence)
- WAVE-2 and WAVE-3: Can run simultaneously after WAVE-1 (independent subsystems)
- WAVE-4: 4-5 parallel tracks (testing, docs, regression, checkpoint)

---

## Section 4: Implementation Waves (Detailed)

### PRE-WAVE — Bug Triage + Level 2 Design Sketch

**Purpose:** Fix 3 Phase 4 wiring bugs that would pollute Level 2 testing, then produce the design specs that WAVE-1 depends on — Level 2 geography, werewolf creature design, and salt preservation pipeline.

#### Bug Triage (3 Known Wiring Bugs)

| Bug | Symptom | Root Cause (Suspected) | Fix Owner |
|-----|---------|------------------------|-----------|
| **Silk disambiguation** | `craft silk` resolves wrong object when silk-bundle and silk-rope both present | Parser keyword overlap — `silk` matches both; needs adjective disambiguation or priority | Smithers |
| **Craft recipe lookup** | `craft silk-bandage` fails with "unknown recipe" despite recipe existing | Recipe registry key mismatch — recipe ID vs object ID format discrepancy in `src/engine/verbs/crafting.lua` | Smithers |
| **Brass key/padlock FSM** | `unlock door with brass-key` in deep-cellar doesn't trigger FSM transition for Level 2 stairs | Exit wiring incomplete — `hallway-level2-stairs-up` exit target undefined; FSM transition missing `provides_tool` on brass-key or transition not declared on exit object | Bart |

#### Assignments

| Agent | Task | Details |
|-------|------|---------|
| Smithers | **Fix silk disambiguation** | Update `src/meta/objects/silk-bundle.lua` and `src/meta/objects/silk-rope.lua` keywords to use distinct adjective-prefixed entries. Update `src/assets/parser/embedding-index.json` if needed. Verify `craft silk-rope` and `craft silk-bandage` both resolve correctly. |
| Smithers | **Fix craft recipe lookup** | Debug recipe key format in `src/engine/verbs/crafting.lua`. Ensure recipe IDs match the `id` field of target objects. Add guard for common key mismatches. |
| Bart | **Fix brass key/padlock wiring** | Wire `src/meta/objects/hallway-level2-stairs-up.lua` exit to target Level 2 entry room. Verify `src/meta/objects/brass-key.lua` has `provides_tool = "unlocking"` or equivalent. Add FSM transition on the stairs exit object (`locked → unlocked` via brass-key capability). |
| Moe | **Level 2 geography sketch** | Design 7-room layout for Level 2 (catacombs zone). Produce room topology document: room names, exit connections, biome types, creature placement zones, light conditions. Write to `.squad/decisions/inbox/moe-level2-geography.md`. Rooms: catacombs-entrance, underground-stream, werewolf-lair, collapsed-cellar, wolf-den, spider-cavern, deep-storage. |
| Bart | **Werewolf design spec** | Write creature spec: combat stats (health, attack, defense), territorial behavior pattern, patrol routes (room-to-room), semi-intelligent AI hooks (future dialogue scaffold). Distinct from wolf — separate creature class, higher stats, solo hunter. Write to `.squad/decisions/inbox/bart-werewolf-spec.md`. |
| Bart | **Salt preservation design spec** | Write preservation pipeline spec: `salt` verb handler flow, salt object definition, mutation path (wolf-meat → salted-wolf-meat), spoilage FSM rate modifier (3× slower decay), tool requirement (salt must be in hand). Write to `.squad/decisions/inbox/bart-salt-preservation-spec.md`. |
| Nelson | **Regression baseline** | Run `lua test/run-tests.lua`, record exact test count as PHASE-4-FINAL-COUNT (expected: 223). Verify zero failures. Register new test directories: `test/level2/`, `test/pack/`, `test/preservation/`. |
| Bart | **GUID pre-assignment** | Reserve Windows-format GUIDs for all 12+ Phase 5 new objects (werewolf, werewolf-pelt, werewolf-fang, werewolf-meat, cooked-werewolf-meat, silver-pendant, torn-journal-page, salt, salted-wolf-meat, cooked-salted-wolf-meat, salted-werewolf-meat, cooked-salted-werewolf-meat). Write to `.squad/decisions/inbox/bart-phase5-guids.md`. Flanders and Smithers reference this file during WAVE-1 and WAVE-3. Prevents GUID collisions during parallel authoring. |
| Moe | **Level 2 environmental specifications** | Produce `docs/design/levels/level2-environmental-specifications.md` — full sensory specs for all 7 L2 rooms: `description` (lit), `on_feel` (dark), `on_smell`, `on_listen` per room, spatial instance trees (what objects go where using `on_top`/`contents`/`nested`/`underneath`), and puzzle hooks. **Must complete before WAVE-1** so Moe can write room `.lua` files with proper sensory depth. |
| Smithers | **Preserve/cure alias audit** | Audit `src/engine/verbs/init.lua` verb dispatch for collisions between new salt aliases (`preserve`, `cure`, `rub salt on`) and existing verbs (e.g., `cure poison` in injury system). Document precedence rules: most-specific verb wins. If collision found, file decision to `.squad/decisions/inbox/smithers-alias-precedence.md`. Check `src/assets/parser/embedding-index.json` for semantic overlaps. |

#### File Ownership Table

| File | Agent | Action |
|------|-------|--------|
| `src/meta/objects/silk-bundle.lua` | Smithers | MODIFY (keywords) |
| `src/meta/objects/silk-rope.lua` | Smithers | MODIFY (keywords) |
| `src/engine/verbs/crafting.lua` | Smithers | MODIFY (recipe key fix) |
| `src/assets/parser/embedding-index.json` | Smithers | MODIFY (silk entries) |
| `src/meta/objects/hallway-level2-stairs-up.lua` | Bart | MODIFY (exit target + FSM) |
| `src/meta/objects/brass-key.lua` | Bart | MODIFY (provides_tool if missing) |
| `.squad/decisions/inbox/moe-level2-geography.md` | Moe | CREATE |
| `.squad/decisions/inbox/bart-werewolf-spec.md` | Bart | CREATE |
| `.squad/decisions/inbox/bart-salt-preservation-spec.md` | Bart | CREATE |
| `test/run-tests.lua` | Nelson | MODIFY (register 3 new dirs) |
| `.squad/decisions/inbox/bart-phase5-guids.md` | Bart | CREATE |
| `docs/design/levels/level2-environmental-specifications.md` | Moe | CREATE |
| `.squad/decisions/inbox/smithers-alias-precedence.md` | Smithers | CREATE (if collision found) |

**File conflict check:** ✅ No overlaps. Smithers owns silk objects + crafting verb. Bart owns brass-key objects + design specs. Moe owns geography sketch. Nelson owns test runner.

#### TDD Requirements

Nelson verifies bug fixes by running existing tests — no new test files in PRE-WAVE. Bug fixes validated by existing Phase 4 tests (silk crafting, recipe lookup, brass-key unlock). New test directory registration only.

#### Scope Estimate

- Bug fixes: ~30-50 LOC modified across 4 files
- Design specs: ~3 markdown docs (~2-3KB each)
- Test runner update: ~5 LOC
- **Total: ~35-55 LOC code + 3 design documents**

---

### WAVE-1 — Level 2 Foundation (7 Rooms + Creatures)

**Purpose:** Build the Level 2 physical world — 7 new rooms forming the deep dungeon catacombs zone, werewolf creature type, 1-2 additional creature variants, brass-key transition wiring, and Level 2 loader registration. After WAVE-1, a player can unlock the stairs, descend to Level 2, and explore all 7 rooms with new creatures spawned.

#### Level 2 Room Layout (from Moe's PRE-WAVE geography sketch)

```
                    [spider-cavern]
                          |
[catacombs-entrance] ── [collapsed-cellar] ── [wolf-den]
        |                                         |
[underground-stream]                        [werewolf-lair]
        |
  [deep-storage]
```

All Level 2 rooms start in darkness (no natural light). Player must bring light source from Level 1.

#### Assignments

| Agent | Task | Details |
|-------|------|---------|
| Moe | **catacombs-entrance.lua** | Entry room from Level 1. Stone archway, damp walls, faint echo. Exits: up (to hallway via brass-key stairs), east (collapsed-cellar), south (underground-stream). Permanent features only in description. |
| Moe | **underground-stream.lua** | Subterranean stream, cold water, slippery stone. Exits: north (catacombs-entrance), south (deep-storage). Contains: cold-water source (drinkable). Ambient sound: running water. |
| Moe | **collapsed-cellar.lua** | Partially caved-in room, rubble piles, narrow passage. Exits: west (catacombs-entrance), east (wolf-den), north (spider-cavern). Hazard: loose stones (future trap hook). |
| Moe | **wolf-den.lua** | Wolf pack territory, bones scattered, musky smell. Exits: west (collapsed-cellar), south (werewolf-lair). Creature spawn: 2 wolves. Territorial markers present. |
| Moe | **werewolf-lair.lua** | Large cavern, claw marks on walls, rank animal smell. Exits: north (wolf-den). Creature spawn: 1 werewolf. Boss room — single exit forces confrontation. |
| Moe | **spider-cavern.lua** | Web-covered walls, low ceiling, silk strands everywhere. Exits: south (collapsed-cellar). Creature spawn: 2 spiders. Web obstacles (from Phase 4 web creation). |
| Moe | **deep-storage.lua** | Ancient storage vault, dusty shelves, rotting crates. Exits: north (underground-stream). Contains: salt object (discovery point), provisions, old supplies. Quest-relevant items for WAVE-3. |
| Flanders | **werewolf.lua creature** | New creature type. Health: 45 (wolf=20), Attack: 12 (wolf=6), Defense: 8 (wolf=3). Territorial behavior (solo patrol, 2-room radius). Semi-intelligent: does not attack immediately — growls first (1-turn warning). Loot table: werewolf-pelt, werewolf-fang, werewolf-meat. Keywords: werewolf, beast, creature. |
| Flanders | **werewolf-pelt.lua** | Small-item, crafting material. Material: hide. `on_feel = "Coarse, thick fur — unnaturally warm."` Future armor crafting input. |
| Flanders | **werewolf-fang.lua** | Small-item, weapon (piercing, force 5). Material: bone. `on_feel = "A curved fang, razor-sharp at the tip."` |
| Flanders | **werewolf-meat.lua** | Small-item, cookable. Nutrition: 50 (higher than wolf-meat=35). FSM: raw → cooked. Material: meat. `on_feel = "Dense, dark meat — heavy for its size."` Mutation target: `cooked-werewolf-meat.lua`. |
| Flanders | **cooked-werewolf-meat.lua** | Mutation result of cooking werewolf-meat. Nutrition: 50, heal: 15. `on_taste = "Rich and gamey, surprisingly satisfying."` |
| Bart | **Level 2 loader registration** | Create `src/meta/levels/level-02.lua` — level definition file referencing all 7 rooms, creature spawn tables, light conditions (all dark), and entry point (catacombs-entrance). Register in `src/engine/loader/init.lua` level table. |
| Bart | **Brass-key transition wiring** | Complete the unlock-stairs → load-Level-2 pipeline. In `src/engine/verbs/movement.lua`, detect when player uses stairs exit that targets a different level. Call loader to instantiate Level 2 rooms on first entry. Lazy-load pattern: Level 2 rooms created only when player first descends. |
| Smithers | **Level 2 room presence** | Add `room_presence` strings for all new objects placed in Level 2 rooms (salt, provisions, cold-water, scattered bones, web obstacles). Update embedding index with new Level 2 nouns. |
| Nelson | **Level 2 instantiation tests** | `test/level2/test-room-loading.lua`: all 7 rooms load without error, exits route correctly (bidirectional), creature spawn counts match. `test/level2/test-brass-transition.lua`: brass-key unlocks stairs, player moves to catacombs-entrance, Level 2 rooms instantiated. ~10-12 tests. |

#### File Ownership Table

| File | Agent | Action |
|------|-------|--------|
| `src/meta/rooms/catacombs-entrance.lua` | Moe | CREATE |
| `src/meta/rooms/underground-stream.lua` | Moe | CREATE |
| `src/meta/rooms/collapsed-cellar.lua` | Moe | CREATE |
| `src/meta/rooms/wolf-den.lua` | Moe | CREATE |
| `src/meta/rooms/werewolf-lair.lua` | Moe | CREATE |
| `src/meta/rooms/spider-cavern.lua` | Moe | CREATE |
| `src/meta/rooms/deep-storage.lua` | Moe | CREATE |
| `src/meta/creatures/werewolf.lua` | Flanders | CREATE |
| `src/meta/objects/werewolf-pelt.lua` | Flanders | CREATE |
| `src/meta/objects/werewolf-fang.lua` | Flanders | CREATE |
| `src/meta/objects/werewolf-meat.lua` | Flanders | CREATE |
| `src/meta/objects/cooked-werewolf-meat.lua` | Flanders | CREATE |
| `src/meta/levels/level-02.lua` | Bart | CREATE |
| `src/engine/loader/init.lua` | Bart | MODIFY (register Level 2) |
| `src/engine/verbs/movement.lua` | Bart | MODIFY (level transition) |
| `src/assets/parser/embedding-index.json` | Smithers | MODIFY (Level 2 nouns) |
| `test/level2/test-room-loading.lua` | Nelson | CREATE |
| `test/level2/test-brass-transition.lua` | Nelson | CREATE |

**File conflict check:** ✅ No overlaps. Moe owns all 7 room files. Flanders owns creature + object files. Bart owns level definition + engine modules. Smithers owns parser index. Nelson owns test files.

#### TDD Requirements

Nelson writes tests **in parallel** with implementation (different files):
- `test/level2/test-room-loading.lua` — room instantiation, exit graph, creature spawn counts
- `test/level2/test-brass-transition.lua` — brass-key unlock, level transition, lazy-load

Tests written to spec (from Moe's geography sketch + Bart's level-02.lua definition), not to implementation. Failures become fix tasks for the implementer.

#### Scope Estimate

- 7 room files: ~100-140 LOC each = **700-980 LOC**
- Werewolf creature: ~120 LOC
- 4 werewolf product objects: ~40 LOC each = ~160 LOC
- Level 2 loader + registration: ~60-80 LOC
- Level transition wiring: ~40-60 LOC
- Room presence + embedding updates: ~30-50 LOC
- Tests: ~80-100 LOC
- **Total: ~1,190-1,550 LOC**

---

### WAVE-2 — Pack Role System (Simplified Coordination)

**Purpose:** Upgrade Phase 4's basic pack awareness (stagger attacks, alpha by aggression) to a full role system with alpha selected by health, omega reserve behavior, and coordinated attack sequencing. This makes Level 2 wolf encounters tactically challenging — packs fight as a unit, not as individuals.

#### Pack Role Design

Phase 4 delivered simplified pack awareness in `src/engine/creatures/pack-tactics.lua`:
- Stagger attacks (wolves don't all strike the same turn)
- Alpha selection by highest aggression

Phase 5 upgrades to:
- **Alpha selection by highest HP** (Wayne Q4 decision: Option A) — healthiest wolf leads
- **Stagger attacks with turn-taking** — alpha strikes first, betas follow in HP order, 1-turn delay between each
- **Omega reserve** — lowest-HP wolf retreats to adjacent room if health < 30% (per code spec), returns when healed
- **Pack awareness radius** — wolves within 2 rooms sense each other (reuses territorial BFS from Phase 4)

```lua
-- Pack role assignment (computed each tick, not stored)
-- In src/engine/creatures/pack-tactics.lua
function M.assign_roles(wolves_in_range)
    table.sort(wolves_in_range, function(a, b) return a.health > b.health end)
    wolves_in_range[1].pack_role = "alpha"
    for i = 2, #wolves_in_range - 1 do
        wolves_in_range[i].pack_role = "beta"
    end
    if #wolves_in_range > 1 then
        wolves_in_range[#wolves_in_range].pack_role = "omega"
    end
end
```

#### Assignments

| Agent | Task | Details |
|-------|------|---------|
| Bart | **Pack role assignment** | Rewrite `src/engine/creatures/pack-tactics.lua` — replace aggression-based alpha with HP-based. Add `assign_roles()` function (computed each creature tick, not persisted). Roles: alpha (highest HP), beta (middle), omega (lowest HP). |
| Bart | **Stagger attack sequencing** | Update attack dispatch in `src/engine/creatures/pack-tactics.lua` — alpha attacks on turn N, betas on N+1 (in HP order), omega holds unless alpha is dead. Add `get_attack_order()` function. |
| Bart | **Omega reserve behavior** | Add retreat logic to `src/engine/creatures/pack-tactics.lua` — omega flees to adjacent room when health < 30%. Returns after 3 ticks if health > 50%. Uses `src/engine/creatures/navigation.lua` for exit selection. |
| Flanders | **Wolf pack_role metadata** | Update `src/meta/creatures/wolf.lua` — add `pack_tactics.role_eligible = true` flag. Add `pack_tactics.retreat_threshold = 0.3` and `pack_tactics.return_threshold = 0.5`. Do NOT set `pack_role` statically — roles are computed by engine. |
| Flanders | **Werewolf pack exclusion** | Update `src/meta/creatures/werewolf.lua` — add `pack_tactics.role_eligible = false`. Werewolves are solo hunters, never join wolf packs. |
| Smithers | **Pack narration** | Add coordinated attack narration to `src/engine/verbs/combat.lua`. Alpha, beta, and omega attacks must be **visually distinct** in combat text (CBG requirement). Distinct messages: alpha = "The largest wolf **lunges forward**, teeth bared." beta = "Another wolf **hesitates, waiting for an opening**, then strikes." omega = "The wounded wolf **backs away and flees through [exit]**." Role-variant text ensures players understand wolves are coordinating — not just individually weak. |
| Nelson | **Pack role tests** | `test/pack/test-role-assignment.lua`: 3 wolves → correct alpha/beta/omega by HP. HP changes → roles reassign. `test/pack/test-stagger-attacks.lua`: attack order follows role priority. `test/pack/test-omega-reserve.lua`: omega flees at <30% HP, returns at >50%. ~10-12 tests. |

#### File Ownership Table

| File | Agent | Action |
|------|-------|--------|
| `src/engine/creatures/pack-tactics.lua` | Bart | MODIFY (role system rewrite) |
| `src/meta/creatures/wolf.lua` | Flanders | MODIFY (pack metadata) |
| `src/meta/creatures/werewolf.lua` | Flanders | MODIFY (pack exclusion) |
| `src/engine/verbs/combat.lua` | Smithers | MODIFY (pack narration) |
| `test/pack/test-role-assignment.lua` | Nelson | CREATE |
| `test/pack/test-stagger-attacks.lua` | Nelson | CREATE |
| `test/pack/test-omega-reserve.lua` | Nelson | CREATE |

**File conflict check:** ✅ No overlaps. Bart owns pack-tactics engine module. Flanders owns creature metadata files. Smithers owns combat verb narration. Nelson owns test files.

#### TDD Requirements

Nelson writes tests **in parallel** with Bart's engine work (different files):
- `test/pack/test-role-assignment.lua` — role assignment by HP, dynamic reassignment
- `test/pack/test-stagger-attacks.lua` — attack ordering, turn delay
- `test/pack/test-omega-reserve.lua` — retreat trigger, return condition, navigation

Tests use deterministic seed (`math.randomseed(42)`) for reproducible pack behavior.

#### Scope Estimate

- Pack role rewrite: ~80-100 LOC (modify existing ~150 LOC file)
- Stagger sequencing: ~40-60 LOC
- Omega reserve: ~50-70 LOC
- Wolf metadata updates: ~10-15 LOC × 2 files = ~20-30 LOC
- Pack narration: ~30-40 LOC
- Tests: ~80-100 LOC
- **Total: ~300-400 LOC**

---

### WAVE-3 — Salt Preservation System

**Purpose:** Close the food sustainability loop — players can salt raw meat to slow spoilage 3× (Wayne Q2 decision: Option A, salt-only). This enables long-term food storage for deep dungeon exploration where fresh food sources are scarce.

#### Salt Preservation Pipeline

```
[raw meat] + [salt] --salt verb--> [salted-raw-meat]
                                        |
                              (spoilage rate: 3× slower)
                                        |
                              [cook verb] --> [cooked-salted-meat]
                                               (spoilage rate: 3× slower, preserved)
```

Salt is consumed on use (1 salt → 1 salted meat). Player must hold salt in one hand and meat in the other (two-hand system).

#### Assignments

| Agent | Task | Details |
|-------|------|---------|
| Smithers | **`salt` verb handler** | Create handler in `src/engine/verbs/crafting.lua` (or new `preservation.lua` if crafting exceeds 500 LOC). Verb: `salt`. Aliases: `preserve`, `cure`, `rub salt on`. Requires: salt object in one hand, meat object in other hand. Validates target has `preservable = true` flag. Triggers mutation on meat object. Consumes salt object. **Narration requirement (CBG):** Salt verb MUST telegraph expedition benefit — e.g., "You work the salt crystals into the meat. This should keep much longer now." Examining salted meat should also reinforce value: "The salt has formed a protective crust — this will last far longer than fresh meat." |
| Smithers | **Embedding index update** | Add `salt`, `preserve`, `cure`, `rub salt` to `src/assets/parser/embedding-index.json`. Verify no collision with existing entries. |
| Flanders | **salt.lua object** | Create `src/meta/objects/salt.lua`. Template: small-item. Consumable (consumed on use). Material: mineral. `on_feel = "Coarse, dry crystals."` `on_taste = "Intensely salty — stings the tongue."` Capabilities: `preserving`. Keywords: salt, rock salt, salt crystals. Placed in deep-storage room (Level 2). |
| Flanders | **salted-wolf-meat.lua** | Mutation target from wolf-meat. `preservable = true` on wolf-meat source. FSM: raw-salted → cooked-salted. Spoilage rate: `spoil_multiplier = 3.0` (3× slower). `on_feel = "Firm, salt-crusted flesh."` `on_smell = "Sharp salt and dried meat."` Nutrition: 35 (same as wolf-meat). |
| Flanders | **cooked-salted-wolf-meat.lua** | Mutation result of cooking salted-wolf-meat. Nutrition: 35, heal: 10. Spoilage: `spoil_multiplier = 3.0`. `on_taste = "Salty and rich — well-preserved."` |
| Flanders | **salted-werewolf-meat.lua** | Mutation target from werewolf-meat. Same pattern as wolf variant. Spoilage rate: `spoil_multiplier = 3.0`. Nutrition: 50. |
| Flanders | **cooked-salted-werewolf-meat.lua** | Mutation result of cooking salted-werewolf-meat. Nutrition: 50, heal: 18. Spoilage: `spoil_multiplier = 3.0`. |
| Flanders | **wolf-meat.lua update** | Add `preservable = true` and `mutations.salt = { becomes = "salted-wolf-meat", message = "You rub salt into the wolf meat..." }` to existing object. |
| Flanders | **werewolf-meat.lua update** | Add `preservable = true` and `mutations.salt` block (same pattern as wolf-meat). |
| Bart | **FSM spoilage rate — decision: NO engine change** | Per Principle 8 and Bart's architecture review: objects declare actual `duration` values directly in their FSM states. No `spoil_multiplier` field on objects, no engine check. Salted-meat objects simply declare `duration = 21600` (3× the base 7200) in their state definitions. Engine ticks `duration` generically — it already does this. **Decision:** `.squad/decisions/inbox/bart-spoilage-no-engine-change.md`. This resolves the §1.4 vs §4 contradiction (line 998 says "no engine changes"; previous text said ~20-30 LOC change). Objects own their timing; engine stays generic. |
| Nelson | **Preservation tests** | `test/preservation/test-salt-verb.lua`: salt verb resolves, requires salt + meat in hands, consumes salt, produces salted-meat. `test/preservation/test-spoilage-rate.lua`: salted meat decays 3× slower than unsalted (FSM tick comparison). `test/preservation/test-salt-cook-chain.lua`: salted-raw → cook → salted-cooked preserves multiplier. ~10-12 tests. |

#### File Ownership Table

| File | Agent | Action |
|------|-------|--------|
| `src/engine/verbs/crafting.lua` | Smithers | MODIFY (salt verb handler) |
| `src/assets/parser/embedding-index.json` | Smithers | MODIFY (salt aliases) |
| `src/meta/objects/salt.lua` | Flanders | CREATE |
| `src/meta/objects/salted-wolf-meat.lua` | Flanders | CREATE |
| `src/meta/objects/cooked-salted-wolf-meat.lua` | Flanders | CREATE |
| `src/meta/objects/salted-werewolf-meat.lua` | Flanders | CREATE |
| `src/meta/objects/cooked-salted-werewolf-meat.lua` | Flanders | CREATE |
| `src/meta/objects/wolf-meat.lua` | Flanders | MODIFY (preservable flag + mutation) |
| `src/meta/objects/werewolf-meat.lua` | Flanders | MODIFY (preservable flag + mutation) |
| `src/engine/fsm/init.lua` | Bart | MODIFY (spoil_multiplier support) |
| `test/preservation/test-salt-verb.lua` | Nelson | CREATE |
| `test/preservation/test-spoilage-rate.lua` | Nelson | CREATE |
| `test/preservation/test-salt-cook-chain.lua` | Nelson | CREATE |

**File conflict check:** ✅ No overlaps. Smithers owns verb handler + embedding index. Flanders owns all object files (salt + mutations + meat updates). Bart owns FSM engine. Nelson owns test files.

**Cross-wave note:** Smithers touched `crafting.lua` in PRE-WAVE (recipe key fix) and again here (salt verb). No conflict — PRE-WAVE completes before WAVE-3 starts. Flanders touches `werewolf-meat.lua` created in WAVE-1 and modified here — no conflict, WAVE-1 completes before WAVE-3.

#### TDD Requirements

Nelson writes tests **in parallel** with implementation (different files):
- `test/preservation/test-salt-verb.lua` — verb resolution, two-hand requirement, salt consumption, mutation trigger
- `test/preservation/test-spoilage-rate.lua` — FSM tick comparison (salted vs unsalted decay)
- `test/preservation/test-salt-cook-chain.lua` — full mutation chain preservation

Tests use deterministic time (`ctx.game_time = fixed`) for reproducible spoilage comparisons.

#### Scope Estimate

- Salt verb handler: ~40-60 LOC
- Embedding index: ~10 LOC
- Salt object: ~40 LOC
- 4 salted-meat objects: ~35 LOC each = ~140 LOC
- 2 meat updates: ~10 LOC each = ~20 LOC
- FSM spoilage modifier: ~20-30 LOC
- Tests: ~80-100 LOC
- **Total: ~350-470 LOC**

---

### WAVE-4 — Integration + Polish + Docs

**Purpose:** Validate the complete Phase 5 feature set end-to-end — brass-key transition through Level 2 exploration, creature encounters, pack coordination, butchery, and salt preservation. Produce design documentation. File issues for anything broken.

#### Integration Test Scenario (Nelson LLM Walkthrough)

Full player journey test in `--headless` mode:

```
1. Start in hallway (Level 1) with brass-key, knife, candle (lit)
2. > unlock stairs with brass-key
3. > go down                        → arrives at catacombs-entrance (Level 2)
4. > look                           → room description (dark — needs candle)
5. > go south                       → underground-stream
6. > go south                       → deep-storage
7. > take salt                      → salt in hand
8. > go north, go north, go east    → collapsed-cellar
9. > go east                        → wolf-den (2 wolves present)
10. [combat: wolves use pack tactics — alpha attacks first, stagger]
11. [kill wolf]
12. > butcher wolf                   → wolf-meat × 3, wolf-bone × 2, wolf-hide × 1
13. > take wolf-meat
14. > salt wolf-meat                 → salted-wolf-meat (salt consumed)
15. > go south                       → werewolf-lair (werewolf growls — 1-turn warning)
16. [combat: werewolf attacks on turn 2]
17. [verify: omega wolf retreated if wounded]
18. > go north, go west, go north    → spider-cavern
19. [verify: spiders + webs present]
20. > go south, go west, go up       → return to hallway (Level 1)
21. [verify: Level 2 rooms persist on re-entry]
```

#### Assignments

| Agent | Task | Details |
|-------|------|---------|
| Nelson | **Full LLM walkthrough** | Execute the 21-step scenario above in `--headless` mode with `math.randomseed(42)`. Record in `test/scenarios/phase5-full-walkthrough.txt`. Pass criteria: all 21 steps complete without error, creatures behave as specified, salted meat mutation succeeds. |
| Nelson | **Regression test suite** | Run full `lua test/run-tests.lua`. Target: 270+ tests, zero failures vs PHASE-4-FINAL-COUNT baseline. Document any new failures as GitHub issues. |
| Nelson | **Test flakiness audit** | Identify any non-deterministic tests added in WAVE-1 through WAVE-3. Add fixed seeds or mark `@skip-ci` with issue link. Document in `test/scenarios/phase5-flakiness-report.txt`. |
| Brockman | **Level 2 ecology doc** | Write `docs/design/level2-ecology.md`. Content: Level 2 room descriptions, creature placement rationale, biome types, light conditions, discovery flow, connection to Level 1. |
| Brockman | **Pack tactics v2 doc** | Write `docs/design/pack-tactics-v2.md`. Content: role assignment algorithm (alpha by HP), stagger attack sequencing, omega reserve behavior, comparison to Phase 4 simplified version, balance notes. |
| Brockman | **Preservation system doc** | Write `docs/design/preservation-system.md`. Content: salt verb pipeline, mutation chain, spoilage multiplier mechanic, two-hand requirement, future extensibility (smoking, drying — Phase 6+). |
| Bart | **Full regression run** | Run `lua test/run-tests.lua` independently. Cross-check with Nelson's results. Verify no engine module exceeds 500 LOC post-Phase 5. If `pack-tactics.lua` exceeded budget, document split proposal. |
| Scribe | **Phase 5 checkpoint** | Update `.squad/decisions.md` with Phase 5 decisions. Merge all decision inbox files. Update `plans/npc-combat/npc-combat-implementation-phase5.md` wave status tracker to ✅ for all waves. Log Phase 5 completion in `.squad/log/`. |

#### File Ownership Table

| File | Agent | Action |
|------|-------|--------|
| `test/scenarios/phase5-full-walkthrough.txt` | Nelson | CREATE |
| `test/scenarios/phase5-flakiness-report.txt` | Nelson | CREATE |
| `docs/design/level2-ecology.md` | Brockman | CREATE |
| `docs/design/pack-tactics-v2.md` | Brockman | CREATE |
| `docs/design/preservation-system.md` | Brockman | CREATE |
| `plans/npc-combat/npc-combat-implementation-phase5.md` | Scribe | MODIFY (status tracker) |
| `.squad/decisions.md` | Scribe | MODIFY (merge decisions) |

**File conflict check:** ✅ No overlaps. Nelson owns test scenarios. Brockman owns design docs. Scribe owns plan updates + decisions. Bart runs verification only (no file writes).

#### TDD Requirements

WAVE-4 is validation, not implementation. No new unit tests. Nelson's walkthrough IS the integration test. Regression suite run is the gate check.

#### Scope Estimate

- LLM walkthrough scenario: ~50 lines (scripted input)
- Flakiness report: ~20 lines
- 3 design docs: ~3-5KB each = ~9-15KB markdown
- Plan/decision updates: ~30 lines modified
- **Total: ~100 LOC test artifacts + ~9-15KB documentation**

---

## Wave Summary — Aggregate Metrics

| Wave | New Files | Modified Files | LOC Range | New Tests | Agents |
|------|-----------|----------------|-----------|-----------|--------|
| PRE-WAVE | 3 (design specs) | 7 | 35-55 | 0 (baseline only) | Bart, Smithers, Moe, Nelson |
| WAVE-1 | 13 (7 rooms, 4 objects, 1 creature, 1 level def) | 5 | 1,190-1,550 | ~12 | Moe, Flanders, Bart, Smithers, Nelson |
| WAVE-2 | 3 (test files) | 4 | 300-400 | ~12 | Bart, Flanders, Smithers, Nelson |
| WAVE-3 | 8 (1 salt, 4 salted-meats, 3 test files) | 5 | 350-470 | ~12 | Smithers, Flanders, Bart, Nelson |
| WAVE-4 | 5 (2 test artifacts, 3 docs) | 2 | ~100 + 9-15KB docs | 0 (walkthrough) | Nelson, Brockman, Bart, Scribe |
| **TOTAL** | **~32** | **~23** | **~1,975-2,575 LOC** | **~36 new tests** | **7 agents** |

**Phase 5 test target:** 223 (Phase 4 baseline) + ~36 new = **~259-270 tests**

---

## Section 5: Testing Gates

### Regression Baseline Protocol

Run `lua test/run-tests.lua` on Phase 4 HEAD before Phase 5 work. Record as PHASE-4-FINAL-COUNT (current: ~258 files, 223 tracked tests). Each gate adds incrementally: GATE-1 +15, GATE-2 +10, GATE-3 +10, GATE-4 +15. Final target: **270+ passing tests, ZERO regressions.**

### Flaky Test Quarantine Protocol (Marge)

1. **Prevention:** All new Phase 5 tests MUST use `math.randomseed(42)` by default for deterministic replay
2. **Detection threshold:** Any test that fails in ≥1 of 3 consecutive runs (95% pass rate floor) triggers investigation
3. **Quarantine:** Failing flaky tests are tagged `@skip-ci` in the test file with linked GitHub issue:
   ```lua
   -- @skip-ci: Issue #NNN (non-deterministic creature tick ordering)
   ```
4. **Recovery:** Quarantined test must pass 3 consecutive green runs before `@skip-ci` is removed
5. **Gate impact:** Flaky tests with `@skip-ci` + issue link do NOT block gates; untagged flaky tests DO block
6. **Audit:** WAVE-4 includes Nelson's flakiness audit — any test added in WAVE-1 through WAVE-3 without fixed seed is flagged

### LLM Scenario Log Format (Nelson)

Each scenario run outputs to a separate file: `test/scenarios/phase5-{name}.log`

```
=== Scenario 2.N: {Name} ===
[DATE] YYYY-MM-DDTHH:MM:SSZ
[SEED] math.randomseed(42)
[INPUT] echo "..." | lua src/main.lua --headless
[STDOUT]
... game output ...
[STDERR]
... errors (if any) ...
[VERDICT] PASS | FAIL
[NOTES] {Free-text observations}
```

- **File naming:** `test/scenarios/phase5-level2-exploration.log`, `test/scenarios/phase5-pack-tactics.log`, etc.
- **Aggregate report:** `test/scenarios/phase5-scenario-summary.txt` — one line per scenario with verdict
- **Retention:** Logs committed to git with each gate tag
- **Gate rule:** If any scenario FAIL verdict, gate fails; logs provide RCA evidence

---

### GATE-1 — Level 2 Foundation

**After:** WAVE-1 | **Reviewers:** Bart (architecture sign-off) + Nelson (QA sign-off)

#### Pass/Fail Criteria

- [ ] All 7 L2 rooms instantiate — `lua test/rooms/test-level2-rooms.lua`
- [ ] Exits route correctly (bidirectional, no orphans) — `lua test/rooms/test-level2-exits.lua`
- [ ] Brass key unlocks L1→L2 door — `lua test/rooms/test-brass-key-transition.lua`
- [ ] Werewolf creature loads (stats, patrol, territorial) — `lua test/creatures/test-werewolf.lua`
- [ ] L2 creatures spawn in correct rooms — `lua test/creatures/test-level2-placement.lua`
- [ ] Room presence text correct — Manual review
- [ ] Embedding index updated for L2 nouns — `lua test/parser/test-embedding-index.lua` (moved from GATE-4 per Smithers: catch noun resolution gaps early)
- [ ] Zero regressions + ~238 tests pass — `lua test/run-tests.lua`

**Perf:** L2 instantiation < 200ms | **LLM:** Scenario 2.1 | **Commit:** `feat: Level 2 foundation (WAVE-1)`

---

### GATE-2 — Pack Role System

**After:** WAVE-2 | **Reviewers:** Bart (architecture sign-off) + Nelson (QA sign-off)

#### Pass/Fail Criteria

- [ ] Stagger attacks (alpha first, others delay 1 turn) — `lua test/creatures/test-pack-stagger.lua`
- [ ] Alpha = highest HP; re-evaluates on damage — `lua test/creatures/test-pack-alpha.lua`
- [ ] Omega (< 30% HP) retreats — `lua test/creatures/test-pack-omega.lua`
- [ ] `pack_role` field on wolf instances — `lua test/creatures/test-wolf-pack-metadata.lua`
- [ ] Territory zones map to L2 topology — `lua test/creatures/test-level2-territory.lua`
- [ ] Coordinated attack narration correct — Manual review
- [ ] Zero regressions + ~248 tests pass — `lua test/run-tests.lua`

**Perf:** Pack scoring < 50ms/tick | **LLM:** Scenario 2.4 | **Commit:** `feat: pack roles (WAVE-2)`

---

### GATE-3 — Salt Preservation System

**After:** WAVE-3 | **Reviewers:** Bart (architecture sign-off) + Nelson (QA sign-off)

#### Pass/Fail Criteria

- [ ] Salt verb resolves (aliases: salt, preserve, cure) — `lua test/verbs/test-salt-verb.lua`
- [ ] Salt object loads (small-item, preservative) — `lua test/objects/test-salt-object.lua`
- [ ] `salt wolf-meat` → salted-wolf-meat mutation — `lua test/preservation/test-salt-mutation.lua`
- [ ] Spoilage = 3× slower (deterministic) — `lua test/preservation/test-spoilage-rate.lua`
- [ ] Fails without salt in hand — `lua test/preservation/test-salt-requirement.lua`
- [ ] Salted meat distinct sensory fields — `lua test/preservation/test-salted-sensory.lua`
- [ ] Zero regressions + ~258 tests pass — `lua test/run-tests.lua`

**Perf:** Salt mutation < 20ms | **LLM:** Scenario 2.3 | **Commit:** `feat: salt preservation (WAVE-3)`

---

### GATE-4 — Phase 5 Complete

**After:** WAVE-4 | **Reviewers:** Bart (architecture sign-off) + Nelson (QA sign-off) + Brockman (docs sign-off)

#### Pass/Fail Criteria

- [ ] Full LLM walkthrough passes (Scenarios 2.1-2.5) — headless
- [ ] 3 design docs meet acceptance criteria (below)
- [ ] Zero regressions + 270+ tests pass — `lua test/run-tests.lua`
- [ ] No flaky tests (3 consecutive runs, 100%) — `lua test/run-tests.lua` × 3
- [ ] No engine module > 500 LOC — manual audit
- [ ] Meta-lint passes (0 errors) — `lua scripts/meta-lint.lua`
- [ ] Embedding index validated (salt aliases verified; L2 nouns validated at GATE-1) — `lua test/parser/test-embedding-index.lua`

#### Docs Acceptance

| Doc | Min Content | Sign-Off |
|-----|-------------|----------|
| `docs/design/level2-ecology.md` | 7-room map, habitats, biomes, treasure, difficulty | Bart |
| `docs/architecture/creatures/pack-tactics-v2.md` | Stagger algo, alpha, omega reserve, Phase 6 preview | Bart |
| `docs/design/preservation-system.md` | Salt pipeline, mutation spec, spoilage math, future hooks | Bart |

**Commit:** `feat: Phase 5 complete (WAVE-4)` | **Tag:** `phase-5-complete`

---

## Section 6: Nelson LLM Test Scenarios

All scenarios use `--headless` mode with deterministic seeds (`math.randomseed(42)`). Navigation paths are approximate — adjust after WAVE-1 room wiring.

### 2.1 Scenario: Level 2 Exploration (GATE-1 + GATE-4)

**Goal:** Navigate from Level 1 → unlock brass key door → enter Level 2 → explore all 7 rooms.

```bash
echo "look
take brass key
go north
go north
go north
unlock door with brass key
open door
go north
look
go east
look
go south
look
go west
look
go north
look
go east
look
go south
look" | lua src/main.lua --headless
```

**Expected patterns:** `brass key` (pickup), `unlock` (door), `catacombs` (L2 entry), ≥4 distinct L2 room names, no `error`/`nil`, no `You can't go that way` after valid exits.

**Pass:** Player reaches L2, visits ≥5 of 7 rooms, all descriptions render cleanly.

---

### 2.2 Scenario: Werewolf Encounter (GATE-1 + GATE-4)

**Goal:** Find werewolf in Level 2, engage combat, defeat it, loot remains.

```bash
echo "look
take brass key
go north
go north
go north
unlock door with brass key
open door
go north
go east
go east
look
feel
smell
attack werewolf
attack werewolf
attack werewolf
attack werewolf
attack werewolf
look
examine corpse
butcher werewolf
look" | lua src/main.lua --headless
```

**Expected patterns:** `werewolf` (present), `attack`/`hit`/`strike` (combat), `dead`/`corpse`/`collapses` (death), `meat`/`hide`/`bone` (loot). No `You can't` for valid combat.

**Pass:** Werewolf found in L2, combat resolves, butchery yields products.

---

### 2.3 Scenario: Salt Preservation (GATE-3 + GATE-4)

**Goal:** Find salt, salt meat, verify salted meat has different properties from fresh.

```bash
echo "look
take knife
take salt
go south
go south
look
attack wolf
attack wolf
attack wolf
attack wolf
butcher wolf
take wolf-meat
salt wolf-meat
examine salted-wolf-meat
feel salted-wolf-meat
taste salted-wolf-meat
smell salted-wolf-meat" | lua src/main.lua --headless
```

**Expected patterns:** `salt` (pickup/verb), `salted` (mutation confirmation), `crusted`/`dry` (on_feel), `salty` (on_taste). No `You don't have`, no mutation errors.

**Pass:** Salt verb transforms fresh meat into salted variant with distinct sensory properties. Mutation pipeline clean.

---

### 2.4 Scenario: Pack Tactics (GATE-2 + GATE-4)

**Goal:** Encounter wolf pack, trigger combat, verify stagger attacks and alpha/omega behavior.

```bash
echo "look
take knife
go north
go north
go north
unlock door with brass key
open door
go north
go west
look
attack wolf
look
attack wolf
attack wolf
look
attack wolf
attack wolf
attack wolf
look
feel" | lua src/main.lua --headless
```

**Expected patterns:** `wolf` (multiple mentions — pack present), `lunges forward`/`largest wolf`/`alpha` (alpha attacks first), `hesitates`/`waiting`/`follows` (beta delayed 1 turn), `backs away`/`flees`/`retreats` (omega if wounded below 30% HP). Sequential attack text — attacks must NOT appear simultaneous. No creature tick errors.

**Pass:** Alpha attacks first, beta staggers 1 turn, omega retreats when wounded below 30% HP. Pack combat demonstrates coordinated behavior through distinct role narration.

**Note:** Combat commands (`attack wolf`) advance game time AND trigger creature ticks. Multiple rounds verify stagger sequencing and omega retreat behavior under actual combat conditions.

---

### 2.5 Scenario: Full Phase 5 Loop (GATE-4 — integration)

**Goal:** End-to-end: L1 → brass key → L2 → wolf combat → butcher → salt → werewolf → rest.

```bash
echo "look
take brass key
take knife
go north
go north
go north
unlock door with brass key
open door
go north
go east
attack wolf
attack wolf
attack wolf
attack wolf
butcher wolf
take wolf-meat
take salt
salt wolf-meat
go west
go east
go east
attack werewolf
attack werewolf
attack werewolf
attack werewolf
attack werewolf
butcher werewolf
go west
go south
rest" | lua src/main.lua --headless
```

**Expected patterns:** Combines Scenarios 1-4 patterns + `rest`/`calm`/`safe` + `---END---`. No `nil`, no stack traces.

**Pass:** Full Phase 5 arc completes in one session — L1→L2, combat, butcher, salt, rest.

---

## Section 7: TDD Test File Map

### New Test Files for Phase 5

| File | Wave | Coverage | Agent | Tests |
|------|------|----------|-------|-------|
| `test/rooms/test-level2-rooms.lua` | W1 | 7 L2 rooms load, fields present, descriptions non-empty | Nelson | 7 |
| `test/rooms/test-level2-exits.lua` | W1 | L2 exits route to valid targets, bidirectional, no orphans | Nelson | 8 |
| `test/rooms/test-brass-key-transition.lua` | W1 | Brass key unlocks L1→L2 door, FSM state | Nelson | 4 |
| `test/creatures/test-werewolf.lua` | W1 | Werewolf instantiation, stats, patrol, territorial, sensory | Nelson | 6 |
| `test/creatures/test-level2-placement.lua` | W1 | Creatures in correct L2 rooms per geography | Nelson | 5 |
| `test/creatures/test-pack-stagger.lua` | W2 | Alpha first, beta delayed 1 turn, sequence correct | Nelson | 4 |
| `test/creatures/test-pack-alpha.lua` | W2 | Highest HP = alpha; re-evaluates; deterministic tie-break | Nelson | 4 |
| `test/creatures/test-pack-omega.lua` | W2 | Omega retreat at < 30% HP, path selection | Nelson | 3 |
| `test/creatures/test-wolf-pack-metadata.lua` | W2 | `pack_role` field present, updates dynamically | Nelson | 3 |
| `test/creatures/test-level2-territory.lua` | W2 | BFS radius in L2 room graph, zone boundaries | Nelson | 4 |
| `test/verbs/test-salt-verb.lua` | W3 | Aliases resolve, requires salt in hand | Nelson | 4 |
| `test/objects/test-salt-object.lua` | W3 | Salt loads, preservative capability, keywords | Nelson | 3 |
| `test/preservation/test-salt-mutation.lua` | W3 | wolf-meat → salted-wolf-meat, GUID + metadata | Nelson | 3 |
| `test/preservation/test-spoilage-rate.lua` | W3 | Salted = 3× fresh decay (deterministic time test) | Nelson | 2 |
| `test/preservation/test-salt-requirement.lua` | W3 | Fails without salt, fails on non-food, salt consumed | Nelson | 3 |
| `test/preservation/test-salted-sensory.lua` | W3 | on_feel, on_taste, on_smell differ from fresh | Nelson | 3 |
| `test/integration/test-level2-full-flow.lua` | W4 | L1→L2 → combat → butcher → salt → rest | Nelson | 5 |
| `test/integration/test-phase5-regression.lua` | W4 | Phase 4 scenarios unchanged (candle, cook, craft, stress) | Nelson | 8 |

### New Directory: `test/preservation/` — register in `test/run-tests.lua` during PRE-WAVE or WAVE-3.

### Summary

| Wave | Files | Tests | Cumulative |
|------|-------|-------|------------|
| W1 | 5 | ~30 | ~253 |
| W2 | 5 | ~18 | ~271 |
| W3 | 6 | ~18 | ~289 |
| W4 | 2 | ~13 | ~302 |
| **Total** | **18** | **~79** | **~302** |

**Target:** 270+ (conservative), 300+ (stretch). **Baseline:** Phase 4 = 223 tracked. **Zero regression tolerance.**

---

## Section 8: Feature Breakdown (Per System)

### 1.1 Level 2 Rooms System

**Transition:** Brass key (from `start-room` rug, `src/meta/objects/brass-key.lua`) unlocks hallway `north` exit → `catacombs-entrance`. New `src/meta/levels/level-02.lua` mirrors `level-01.lua` structure. Loader initializes L2 rooms on boundary crossing. All L2 rooms start dark (light=0).

#### 7 Room Definitions

| Room ID | Name | Biome | Atmosphere Summary | Exits |
|---------|------|-------|--------------------|-------|
| `catacombs-entrance` | Catacombs Entrance | catacombs | Narrow stone passage, carved arch, faded inscriptions, cold draft, dust | S→hallway(L1), N→bone-gallery, E→collapsed-cellar |
| `bone-gallery` | The Bone Gallery | catacombs | Vaulted corridor, bone-patterned walls, niches, lime-dust air. 6°C | S→catacombs-entrance, W→underground-stream, N→werewolf-lair(stone door) |
| `underground-stream` | Underground Stream | water | Natural cavern, limestone stream, echoing water, mineral smell, dripping. 5°C, moisture 0.8 | E→bone-gallery, N→wolf-den(narrow) |
| `collapsed-cellar` | Collapsed Wine Cellar | rubble | Half-buried room, snapped beams, broken casks, vinegar-rot. 8°C | W→catacombs-entrance, Down→spider-cavern(hole) |
| `wolf-den` | Wolf Den | den | Low ceiling, packed earth, gnawed bones, musky predator stink, claw marks. 10°C | S→underground-stream, E→werewolf-lair(tunnel) |
| `spider-cavern` | Spider Cavern | web | High grotto, thick webs wall-to-wall, desiccated husks, sticky air. 9°C | Up→collapsed-cellar, N→wolf-den(crack, size-limited) |
| `werewolf-lair` | The Lair | lair | Largest chamber, rough pillars, human artifacts (torn clothing, broken lantern), deep stone gouges, rank musk. 11°C | S→bone-gallery(stone door), W→wolf-den(tunnel) |

**Topology:** Two paths to werewolf-lair: bone-gallery direct (stone door) or wolf-den via stream (longer, wolf encounters). Spider-cavern loops back through wolf-den crack. All 7 room `.lua` files → Moe (WAVE-1). `level-02.lua` → Moe + Bart (WAVE-1).

#### Biome Types

| Biome | Gameplay Effect |
|-------|----------------|
| `catacombs` | Sound carries 2 rooms; combat alerts creatures |
| `water` | Extinguishes unprotected flames; wet items |
| `rubble` | Some exits require clearing |
| `den` | Creature respawn point; territorial scent markers |
| `web` | Web traps; fire effective |
| `lair` | Boss territory; unique loot |

---

### 1.2 Werewolf Creature System

**Decision (Q1=B):** Separate NPC creature, not disease. No lycanthropy/transformation in Phase 5.

#### FSM States (6)

| State | Room Presence | Key Transitions |
|-------|---------------|-----------------|
| `alive-idle` | "A massive shape crouches motionless in the dark." | →patrol(timer:30), →aggressive(threat), →hunt(hunger) |
| `alive-patrol` | "A hulking figure stalks the passage." | →idle(complete), →aggressive(threat) |
| `alive-hunt` | "Something large moves with terrible purpose." | →aggressive(prey_found), →patrol(prey_lost) |
| `alive-aggressive` | "A werewolf looms — half-human, half-beast — fangs bared." | →idle(threat_gone), →flee(health<15%) |
| `alive-flee` | "The werewolf crashes away into the darkness." | →idle(safe_room) |
| `dead` | "In death, the face is almost human." | (final) |

**Behavior vs wolf:** aggression=85 (wolf:70), flee_threshold=15% (wolf:20%), `nocturnal=true`, `can_open_doors=true`, territory=`werewolf-lair`, patrol_rooms=`{werewolf-lair, bone-gallery}`. **Pack exclusion:** `pack_tactics = { role_eligible = false }` — werewolves are solo hunters, never join wolf packs (Flanders review, Principle 8 compliant).

#### Combat Stats

- **Size:** large (wolf: medium) | **Health:** 45 (wolf: 22) | **Speed:** 5
- **Weapons:** claw-swipe (slash, keratin, force=8, target=torso) + bite (pierce, tooth_enamel, force=7, target=arms)
- **Armor:** hide, coverage={body,head,arms,legs}, thickness=3 (wolf: 2)
- **Behavior:** territorial, counter defense, cycle attack pattern, pack_size=1

#### Loot Table

- **Always:** werewolf-hide, werewolf-claw
- **Weighted:** silver-pendant (25%), torn-journal-page (35%), nothing (40%)
- **Variable:** gnawed-bone ×1-3

#### Territory & Respawn

Home: `werewolf-lair`. Patrol: `{werewolf-lair, bone-gallery}`. Respawn: 400 ticks, max_population=1 (boss). Lingering scent in patrol rooms warns player. Death corpse: 4-stage spoilage (fresh→bloated→rotten→bones, 25% longer than wolf). Butchery: 4× werewolf-meat, 3× werewolf-bone, 1× werewolf-hide.

**Files (Flanders, WAVE-1):** `werewolf.lua`, `werewolf-hide.lua`, `werewolf-claw.lua`, `silver-pendant.lua`, `torn-journal-page.lua`, `werewolf-meat.lua`

---

### 1.3 Pack Tactics v1.1

**Decision (Q4=A):** Stagger attacks + alpha by health. No zone-targeting (Phase 6).

#### Existing Foundation (pack-tactics.lua, 110 LOC)

`select_alpha()` (health-based), `plan_attack()` (stagger +1/wolf), `should_retreat()` (health<20%), `get_pack_in_room()` — all ✅ implemented.

#### v1.1 Additions (~40 LOC)

**1. Dynamic pack_role:** `alpha` = highest health, `beta` = health>40%, `omega` = health≤40%. Recalculated each combat tick.

**2. Omega reserve:** New `evaluate_omega(creature, pack, ctx)` — omega disengages, moves toward nearest den exit. All-omega = full pack retreat.

**3. Alpha howl narration:** "The largest wolf throws back its head and howls. The pack surges forward." (Smithers)

**4. Stagger cap:** Max delay capped at 3 turns (prevents large packs feeling sequential).

#### Wolf Metadata Changes

- Add `pack_role = "beta"` (dynamic field)
- Change `pack_size` from 1 → 3 for Level 2 wolves
- Place 3 wolves in `wolf-den`, 1-2 in `underground-stream`

**Deferred (Phase 6):** Zone-targeting, formation behavior, howl-to-summon, pack morale, cross-room coordination.

**Files:** `pack-tactics.lua` modify (Bart, WAVE-2), `wolf.lua` modify (Flanders, WAVE-2), narration (Smithers, WAVE-2)

---

### 1.4 Salt Preservation System

**Decision (Q2=A):** Salt-only, ~80 LOC. No smoking/drying/pickling.

#### New Verb: `salt`

**Owner:** Smithers | **Aliases:** `salt`, `preserve`, `cure`

Checks: (1) target has `mutations.salt`, (2) player holds salt (`provides_tool = "preservative"`), (3) target in `fresh` state. Executes `context.mutation:apply(obj, "salt")`, consumes one salt use.

#### New Object: `salt.lua`

Template: `small-item`. Size: tiny, weight: 0.3. `provides_tool = "preservative"`, `consumable = true`, `uses = 3`. Sensory: soft leather pouch, coarse granules, sharp mineral smell, intensely salty. **Placement:** `collapsed-cellar` (shelf) and `werewolf-lair` (floor).

#### Mutation Pipeline

Meat objects gain `mutations.salt = { becomes = "salted-wolf-meat", message = "..." }`. Salted-meat objects are new definitions with 3-state FSM (fresh→stale→spoiled).

#### Spoilage Rates

| Type | Fresh | Stale | Total Edible |
|------|-------|-------|-------------|
| Unsalted meat | 7200s (2h) | — | 7200s |
| Salted meat | 21600s (6h) | 21600s (6h) | 43200s (12h) |

Spoilage multiplier lives in object FSM `duration` fields — no engine changes (Principle 8).

**Files (WAVE-3):** `salt` verb handler (Smithers), `salt.lua` + `salted-wolf-meat.lua` + `salted-werewolf-meat.lua` (Flanders), `wolf-meat.lua`/`werewolf-meat.lua` modify (Flanders), parser aliases (Smithers)

---

## Section 9: Cross-System Integration Points

### Integration Matrix

| Source → Target | Integration Point | Wave |
|----------------|-------------------|------|
| **L2 rooms → creature placement** | Wolves in wolf-den(×3) + stream(×1-2); werewolf in lair(×1); spiders in cavern(×2) | W1 |
| **L2 rooms → creature territory** | Wolf territory=wolf-den, patrol=stream. Werewolf territory=lair, patrol=bone-gallery | W1 |
| **L2 rooms → respawn system** | New home_rooms; caps: wolf=3, werewolf=1, spider=2 | W1 |
| **L2 rooms → level transition** | level-02.lua room membership; hallway.north → catacombs-entrance; loader init | W1 |
| **Werewolf → loot system** | Death triggers `roll_loot_table()`; always: hide+claw; weighted: pendant/journal | W1 |
| **Werewolf → butchery** | Corpse → 4×meat, 3×bone, 1×hide via existing butchery.lua | W1 |
| **Werewolf → spoilage FSM** | 4-state corpse decay (fresh→bloated→rotten→bones), 25% longer than wolf | W1 |
| **Pack tactics → combat engine** | `plan_attack()` stagger schedule feeds combat FSM turn-order | W2 |
| **Pack tactics → creature actions** | `evaluate_omega()` hooks creature tick; omega→retreat action | W2 |
| **Pack tactics → wolf metadata** | Wolf gains `pack_role` + `pack_size=3`; alpha/omega read/write per tick | W2 |
| **Pack tactics → narration** | Alpha howl + role-variant attack text ("alpha lunges" vs "another wolf presses") | W2 |
| **Salt verb → mutation engine** | `mutation:apply(obj, "salt")` — same pipeline as break/burn mutations | W3 |
| **Salt object → tool system** | `provides_tool = "preservative"` checked by `find_tool_in_hands()` | W3 |
| **Salted meat → food FSM** | Object declares 3× longer `duration` in FSM states; engine ticks generically | W3 |
| **Salt → consumable system** | `consumable=true, uses=3`; decremented per use, removed at 0 | W3 |
| **L2 rooms → salt placement** | Salt in collapsed-cellar (shelf) and werewolf-lair (floor) | W3 |

### Critical Integration Risks

| Risk | Mitigation |
|------|------------|
| Level transition breaks Level 1 | GATE-1: all 223 Phase 4 tests must pass |
| Werewolf loot references missing objects | Flanders creates loot objects in same wave as creature (WAVE-1) |
| Pack stagger vs combat FSM conflict | Nelson stagger-specific tests; deterministic seed `math.randomseed(42)` |
| Salt mutation targets nonexistent salted-meat | Parallel object+verb creation in WAVE-3 |
| Spoilage timers don't tick in L2 rooms | GATE-3 test: carry meat into L2, verify timer advances |
| Salt uses tracking | Nelson tests: salt 3 items, verify salt removed after 3rd |

---

## Section 10: Risk Register

Wayne's Q1–Q7 decisions significantly reduce risk: werewolf-as-NPC (Q1=B) avoids injury-system entanglement, salt-only (Q2=A) keeps WAVE-3 lean, humanoid NPCs deferred (Q3=C) eliminates the largest complexity source.

| # | Risk | L | I | Mitigation |
|---|------|---|---|------------|
| R1 | L2 room design incomplete at WAVE-1 start | Med | High | Moe + Bart complete sketch in PRE-WAVE; gate on sign-off |
| R2 | Pack role scope creep (zone-targeting bleeds in) | Med | Med | Scope locked at Q4=A; zone-targeting hard-deferred to P6 |
| R3 | Salt mutation conflicts with existing food FSM | Low | Med | Audit Phase 4 food objects in PRE-WAVE; document state grammar |
| R4 | Brass-key L1→L2 wiring breaks Level 1 exits | Low | High | Nelson regression after WAVE-1; transition tested in isolation |
| R5 | Werewolf stat imbalance (too strong/weak) | Med | Med | Wolf baseline × 1.5 multiplier; CBG reviews at GATE-1 |
| R6 | Test baseline regression from L2 integration | Low | High | Full suite at every gate; zero-regression; tag rollback |
| R7 | W2/W3 parallel hidden dependency on creature metadata | Low | Med | File ownership pre-assigned: pack.lua (Bart) vs salt (Flanders) |
| R8 | Pack AI performance with 3+ wolves per room | Low | High | Profile in WAVE-2; cap at 4 wolves/room; optimize if measured |
| R9 | Phase 5 overscope (4 waves + ~800 LOC) | Med | Med | WAVE-4 is pressure valve — ship with reduced polish if W1–W3 pass |
| R10 | Embedding index stale after new nouns | Low | Med | Smithers updates index in WAVE-1 and WAVE-3; verified at gates |

3 High-impact risks (R1, R4, R6) — all mitigated by gate-level regression + PRE-WAVE design sign-off.

---

## Section 11: Autonomous Execution Protocol

Per Skill Pattern 9 — walk-away capable. Coordinator orchestrates without Wayne unless escalation triggers.

### Execution Loop

```
WAVE-N → spawn parallel agents → agents complete → Nelson smoke-test
       → GATE-N (full suite + LLM walkthrough + arch review)
       → PASS? → git tag + commit + push → update status → checkpoint → WAVE-(N+1)
       → FAIL? → Gate Failure Protocol (§3)
```

### Rules

- **No file overlap:** No two agents touch the same file in the same wave
- **Multiple instances OK:** Same member on different files (label clearly)
- **Commits:** After every passing gate: `git commit` + `git tag phase5-gate-N` + push
- **Mid-wave emergency:** Commit WIP with `[WIP]` prefix, file issue
- **Nelson continuous testing:** Smoke after each agent, full suite at gates, exploratory between waves
- **All Nelson runs:** `--headless` mode, `math.randomseed(42)` for deterministic reproducibility

### Session Continuity (Chalmers Pattern 14)

If execution session dies (crash, network drop, timeout):

1. Next session loads this plan file and checks Wave Status Tracker (top of document)
2. Find last wave with `✅ Complete` status
3. Verify corresponding gate tag exists: `git tag phase5-gate-N`
4. Resume from WAVE-(N+1) with fresh agent spawning
5. Re-run gate-N tests to confirm state before proceeding (no stale assumptions)

### Gate Review Protocol (Marge + Nelson)

- **Bart (Architecture Lead):** Verifies engine modules, integration points, Principle 8 compliance, module size guard. Sign-off: "GATE-N architecture OK"
- **Nelson (QA):** Runs full test suite (`lua test/run-tests.lua`), LLM walkthroughs, flakiness audit. Sign-off: "GATE-N tests pass"
- **Acceptance:** Both signatures required (Bart AND Nelson). Disagreement escalates to Coordinator.
- **Coordinator Role:** The session orchestrator (or first available Squad member who is not Bart/Nelson). On escalation, Coordinator files GitHub issue and notifies Wayne.
- **Gate passes iff:** (A) Bart signs architecture, (B) Nelson signs QA, (C) No new P0 bugs opened during gate review.

---

## Section 12: Gate Failure Protocol

### 1× Failure (autonomous)

1. Diagnose: identify failing tests + responsible agent
2. File GitHub issue: `[Phase 5] GATE-N failure: {description}`, labels: `phase5`, `gate-failure`
3. Assign fix agent → targeted fix only (no scope expansion)
4. Re-run full gate suite (not just failing tests)
5. If pass → resume normal flow

### 2× Failure on Same Gate (escalate)

1. **Escalate to Wayne:** "GATE-N failed twice. Root cause: X. Recommended fix: Y."
2. Do NOT proceed past the gate or attempt a third fix
3. Wayne chooses: approve fix, descope feature to Phase 6, or rollback

### Rollback Strategy

- **Tags:** `phase5-pre-wave`, `phase5-gate-1`, `phase5-gate-2`, etc.
- **Rollback:** `git reset --hard phase5-gate-N` → re-plan affected wave
- **Nuclear:** `git reset --hard phase5-pre-wave` if WAVE-1 itself is compromised

| Failure Count | Action | Decider |
|---------------|--------|---------|
| 1× | File issue → fix agent → re-gate | Coordinator |
| 2× same gate | Escalate → wait | Wayne |
| Post-rollback | Re-plan wave → fresh attempt | Coordinator + Bart |

### Version Tracking (Chalmers Pattern 14)

After all reviewer findings are addressed and gates pass:
- Increment version: v1.0 → v2.0 (review findings), v2.1 (post-gate-1), v2.2 (post-gate-2), etc.
- Commit: `git commit -m "Phase 5 plan updated to v{version}: {reason}"`
- Reviewers reference the plan version when filing concerns

---

## Section 13: Wave Checkpoint Protocol

After each wave completes and its gate passes:

1. **Verify:** All agents report done; no outstanding WIP commits
2. **Test:** `lua test/run-tests.lua` — record exact pass count
3. **Update tracker:** Wave status → `✅ Complete` with test count and date
4. **Commit:** `git commit -m "Phase 5 WAVE-N checkpoint: {wave name} complete"`
5. **Tag + push:** `git tag phase5-gate-N` → `git push --tags`
6. **Note deviations:** Document scope changes, file renames, unexpected dependencies
7. **Check readiness:** Verify WAVE-(N+1) dependencies satisfied → spawn next wave

---

## Section 14: Documentation Deliverables (Brockman)

"No phase ships without its docs" (Skill Pattern 7).

### After GATE-2

| File | Content |
|------|---------|
| `docs/design/level2-ecology.md` | L2 room descriptions, creature habitats, biome types, treasure placement, navigation map |
| `docs/architecture/creatures/werewolf-mechanics.md` | Stats, patrol behavior, territorial AI, combat multipliers, Phase 6 dialogue hooks |

### After GATE-3

| File | Content |
|------|---------|
| `docs/design/food-preservation-system.md` | Salt verb usage, mutation pipeline, spoilage comparison (fresh vs salted), Phase 6 hooks |
| `docs/architecture/creatures/pack-tactics-v2.md` | Coordination engine, alpha selection, omega reserve, stagger sequencing, performance budget |

### After GATE-4

| File | Content |
|------|---------|
| Phase 5 summary in implementation plan | Lessons, actual vs estimated LOC, gate failures, new risks, candidate skills |
| Updated `docs/design/design-directives.md` | New directives from Phase 5 (preservation, pack roles) |

All docs reference the governing decision (e.g., "Per Q1=B, werewolf is NPC type").

---

## Section 15: Phase 6 Preview

Deferred per Wayne's Q1–Q7 decisions and Chalmers' draft §10:

### 6a: Intelligence + Navigation
- **A* pathfinding** (250–300 LOC) — random-exit acceptable for V1 (Q5=B)
- **Environmental combat** — push/throw/climb (180–220 LOC) — combat-plan sequel (Q6=B)
- **Creature-to-creature looting** (150–200 LOC) — requires AI value evaluation

### 6b: Humanoid NPCs
- **Full NPC system** (400–600 LOC) — dialogue, memory, quests, factions (Q3=C)
- **Dialogue framework + quest hooks** (350–500 LOC) — prerequisite chain

### 6c: Systems Expansion
- **Full preservation** — smoking, drying, root cellar (200–250 LOC) — salt validates pattern first (Q2=A)
- **Zone-targeting pack attacks** (200–250 LOC) — simplified model sufficient for P5 (Q4=A)
- **Armor/weapon degradation** (100–150 LOC) — material system overhaul
- **Multi-ingredient cooking** (120–180 LOC) — recipe system beyond mutation

Recommended sequencing: 6a → 6b → 6c (smarter navigation unblocks NPC AI).

---

## Section 16: Success Criteria

Phase 5 is complete when ALL are true (binary pass/fail):

| # | Criterion | Verification |
|---|-----------|-------------|
| SC-1 | 7 Level 2 rooms instantiate with correct exits, zero orphans | Room instantiation tests |
| SC-2 | Brass key unlocks L1→L2 transition without breaking L1 | Nelson walkthrough: start → brass key → L2 |
| SC-3 | Werewolf exists as NPC type with combat stats + patrol + territory | Unit tests: spawn, attack, patrol, territory |
| SC-4 | Wolf pack coordination: stagger attacks, alpha by highest HP | Pack tests: 3-wolf turn-taking, alpha verified |
| SC-5 | Salt verb: salt + meat → salted-meat via mutation | Preservation tests: verb resolves, mutation fires |
| SC-6 | Salted meat spoils 3× slower than fresh (FSM timer) | Timer test: salted decay = fresh decay × 3 |
| SC-7 | ≥270 tests pass, ZERO regressions vs Phase 4 (223) | `lua test/run-tests.lua` |
| SC-8 | Full LLM walkthrough in `--headless` mode succeeds | Nelson: L1→key→L2→werewolf→pack→butcher→salt |
| SC-9 | All 4 design docs delivered and signed off | File existence + Brockman sign-off |
| SC-10 | All P0 issues closed or deferred with tracking ticket | Issue audit at GATE-4 |

---

## Section 17: Post-Mortem Template (Chalmers Pattern 14)

*To be filled after Phase 5 completion — all waves done, GATE-4 passed.*

### Actual vs Estimated

- Total LOC: {actual} vs ~1,975–2,575 estimated
- Duration: {actual days} vs ~3–4 weeks estimated
- Test count: {actual} vs 270+ target
- New files: {actual} vs ~32 estimated
- Modified files: {actual} vs ~23 estimated

### Gate Failures

- GATE-1: {count and resolution}
- GATE-2: {count and resolution}
- GATE-3: {count and resolution}
- GATE-4: {count and resolution}

### New Risks Discovered

- {Risk} → {candidate mitigations}

### Candidate Skills to Formalize

- {Skill from Phase 5 execution pattern} → `.squad/skills/{name}/SKILL.md`

### Deviations from Plan

- {Scope changes, file renames, unexpected dependencies, unplanned work}

---

**END OF CHUNK 5 (OPERATIONS)**

---

*Plan authored by Bart (Architecture Lead). Assembled from 5 chunks per implementation-plan skill Pattern 2a. Updated to v2.0 after 8-reviewer team review cycle.*