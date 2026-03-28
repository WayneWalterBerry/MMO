# Phase 5 — Chunk 2: Implementation Waves (Detailed)

**Author:** Bart (Architecture Lead)
**Date:** 2026-03-28
**Chunk:** 2 of 5 — Implementation Waves
**References:** Chunk 1 skeleton (`plans/npc-combat/npc-combat-implementation-phase5.md`)

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
- **Omega reserve** — lowest-HP wolf retreats to adjacent room if health < 30%, returns when healed
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
| Smithers | **Pack narration** | Add coordinated attack narration to `src/engine/verbs/combat.lua`. Distinct messages: "The alpha wolf lunges first...", "The pack follows in sequence...", "The omega wolf retreats, whimpering." |
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
| Smithers | **`salt` verb handler** | Create handler in `src/engine/verbs/crafting.lua` (or new `preservation.lua` if crafting exceeds 500 LOC). Verb: `salt`. Aliases: `preserve`, `cure`, `rub salt on`. Requires: salt object in one hand, meat object in other hand. Validates target has `preservable = true` flag. Triggers mutation on meat object. Consumes salt object. |
| Smithers | **Embedding index update** | Add `salt`, `preserve`, `cure`, `rub salt` to `src/assets/parser/embedding-index.json`. Verify no collision with existing entries. |
| Flanders | **salt.lua object** | Create `src/meta/objects/salt.lua`. Template: small-item. Consumable (consumed on use). Material: mineral. `on_feel = "Coarse, dry crystals."` `on_taste = "Intensely salty — stings the tongue."` Capabilities: `preserving`. Keywords: salt, rock salt, salt crystals. Placed in deep-storage room (Level 2). |
| Flanders | **salted-wolf-meat.lua** | Mutation target from wolf-meat. `preservable = true` on wolf-meat source. FSM: raw-salted → cooked-salted. Spoilage rate: `spoil_multiplier = 3.0` (3× slower). `on_feel = "Firm, salt-crusted flesh."` `on_smell = "Sharp salt and dried meat."` Nutrition: 35 (same as wolf-meat). |
| Flanders | **cooked-salted-wolf-meat.lua** | Mutation result of cooking salted-wolf-meat. Nutrition: 35, heal: 10. Spoilage: `spoil_multiplier = 3.0`. `on_taste = "Salty and rich — well-preserved."` |
| Flanders | **salted-werewolf-meat.lua** | Mutation target from werewolf-meat. Same pattern as wolf variant. Spoilage rate: `spoil_multiplier = 3.0`. Nutrition: 50. |
| Flanders | **cooked-salted-werewolf-meat.lua** | Mutation result of cooking salted-werewolf-meat. Nutrition: 50, heal: 18. Spoilage: `spoil_multiplier = 3.0`. |
| Flanders | **wolf-meat.lua update** | Add `preservable = true` and `mutations.salt = { becomes = "salted-wolf-meat", message = "You rub salt into the wolf meat..." }` to existing object. |
| Flanders | **werewolf-meat.lua update** | Add `preservable = true` and `mutations.salt` block (same pattern as wolf-meat). |
| Bart | **FSM spoilage rate modifier** | Update `src/engine/fsm/init.lua` — when ticking food spoilage timers, check for `spoil_multiplier` field on object. If present, divide decay rate by multiplier. ~20-30 LOC change. Affects all food objects with the field (future-proof for smoking, drying, etc.). |
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

*Chunk 2/5 complete. Next: Chunk 3 (Testing Gates + Nelson LLM Scenarios + TDD Test File Map).*

*Plan authored by Bart (Architecture Lead). Working as Bart (Architecture Lead).*
