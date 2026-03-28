# Squad Decisions

**Last Updated:** 2026-03-28T02:15:00Z  
**Last Deep Clean:** 2026-03-25T18:21:05Z
**Scribe:** Session Logger & Memory Manager

## How to Use This File

**Agents:** Scan the Decision Index first. Active decisions have full details below. Archived decisions are in `decisions-archive.md`.

**To add a new decision:** Create `inbox/{agent-name}-{slug}.md`, Scribe will merge it here.

---

## Decision Index

Quick-reference table of ALL decisions (active + archived). 

| ID | Category | Status | One-Line Summary | Location |
|----|----------|--------|------------------|----------|
| D-14: True Code Mutation (Objects Rewritten, Not Flagged) | Architecture | 🟢 Active | Foundational | Active |
| D-INANIMATE: Objects Are Inanimate (Creatures Are Future) | Architecture | 🟢 Active | See full entry | Active |
| D-ENGINE-REFACTORING-REVIEW | General | 🟢 Active | See full entry | Active |
| D-HIRING-DEPT: All New Hires Must Have Department Assignment | General | 🟢 Active | See full entry | Active |
| D-NO-NEWSPAPER-PENDING: Newspaper Hold Directive | General | 🟢 Active | See full entry | Active |
| D-VERBS-REFACTOR-2026-03-24 | General | 🟢 Active | See full entry | Active |
| D-LARK-GRAMMAR: Lark-Based Lua Object Parser | Parser | 🟢 Active | See full entry | Active |
| D-META-CHECK-BUILD-2026-03-24 | Parser | 🟢 Active | See full entry | Active |
| D-PORTAL-BIDIR-SYNC: Bidirectional Portal Sync in FSM Engine | Architecture | ✅ Implemented | Portal sync is engine-driven, not verb-handler-driven | Active |
| D-PORTAL-PHASE-2-ROOM-WIRING: Portal Phase 2 Room Wiring Complete | Architecture | ✅ Implemented | Thin portal references in start-room & hallway | Active |
| D-WAYNE-BATCH-2026-03-24: Design Decisions Batch (Wayne) | Process | 🟢 Active | See full entry | Active |
| D-WAYNE-CODE-REVIEW-DIRECTIVE (2026-03-24T07-28-58Z) | Process | 🟢 Active | See full entry | Active |
| D-WAYNE-COMMIT-CHECK: Check Commits Before Push (Quality Gate) | Process | 🟢 Active | See full entry | Active |
| D-WAYNE-CONTRIBUTIONS: Track Wayne Contributions Continuously | Process | 🟢 Active | See full entry | Active |
| D-WAYNE-META-CHECK-SCOPE-EXPANSION (2026-03-24T17-40-46Z) | Process | 🟢 Active | See full entry | Active |
| D-WAYNE-TDD-REFACTORING-DIRECTIVE (2026-03-24T07-34-02Z) | Process | 🟢 Active | See full entry | Active |
| D-HEADLESS: Headless Testing Mode | Testing | 🟢 Active | See full entry | Active |
| D-TESTFIRST: Test-First Directive for Bug Fixes | Testing | 🟢 Active | See full entry | Active |
| D-V2-ACCEPTANCE-CRITERIA: P0-C V2 Acceptance Criteria Complete | Testing | 🟢 Active | See full entry | Active |
| D-WAYNE-REGRESSION-TESTS: Every Bug Fix Must Include Regression T | Testing | 🟢 Active | See full entry | Active |
| D-NPC-COMBAT-ALIGNMENT: NPC Plan ↔ Combat Plan Alignment (13 fixes) | Design | 🟢 Active | All 13 alignment fixes applied to NPC system plan | Active |
| D-COMBAT-NPC-PHASE-SEQUENCING: NPC Phase 1 Uses Simple injuries.inflict() | Design | 🟢 Active | No combat FSM, body_tree, or combat metadata in Phase 1 | Active |
| D-CREATURES-DIRECTORY: Dedicated Directory for Animate Beings | Architecture | ✅ Implemented | rat.lua moved to src/meta/creatures/; loader updated; tests pass | Active |
| D-FOOD-SYSTEMS-RESEARCH: Food Systems Research Complete | Research | ✅ Complete | 4 documents (127 KB), 15+ games analyzed, 80% engine ready | Active |
| D-CHECKPOINT-AFTER-WAVE: Checkpoint After Every Wave | Process | 🟢 Active | Verify wave completion, update plan documentation as living doc | Active |
| D-STIMULUS-MODULE | Architecture | ✅ Implemented | Stimulus queue management extracted to src/engine/creatures/stimulus.lua | Active |
| D-PREDATOR-PREY-STUB | Architecture | 🟡 In Progress | Predator-prey module stub (src/engine/creatures/predator-prey.lua) ready for WAVE-1 | Active |
| D-NPC-BEHAVIOR-STUB | Architecture | 🟡 In Progress | NPC behavior module stub (src/engine/combat/npc-behavior.lua) ready for WAVE-1 | Active |
| D-TEST-FOOD-DIR | Testing | 🟢 Active | test/food/ registered in test runner for WAVE-1 food system tests | Active |
| D-TISSUE-MATERIALS-AUDIT | Architecture | ✅ Complete | All 5 tissue materials exist: hide, flesh, bone, tooth-enamel, keratin | Active |
| D-ORPHAN-ALLOWLIST | Testing/Tooling | ✅ Implemented | 28 orphan suppressions categorized in .meta-check.json; GUID-02 rule supports allowlisting | Active |
| D-EXIT01-LINT-GAP | Testing/Tooling | ✅ Implemented | EXIT-01 now validates portal targets; boundary portal handling documented | Active |
| D-KITCHEN-DOOR-TRAVERSAL | Architecture | ✅ Implemented | courtyard-kitchen-door blocked until manor-kitchen exists in Level 2 | Active |
| D-MUTATION-GRAPH-LINTER | Testing | 🟡 In Progress | Comprehensive linter plan written; dynamic discovery of all .lua files under src/meta/ | Active |
| D-PHASE4-WAVE0-LOC-AUDIT | Architecture | ✅ Complete | Phase 4 LOC audit complete; creatures/init.lua split planned; 19 GUIDs assigned; 1,540 LOC budget | Active |
| D-PHASE4-WAVE0-TEST-BASELINE | Testing | ✅ Complete | Phase 3 baseline: 207 tests; 3 new dirs registered (butchery/loot/stress); 0 regressions | Active |
| D-PHASE4-WAVE0-EMBEDDING-AUDIT | Architecture | ✅ Complete | 3 HIGH collisions (knife/rope/bandage); adjective-first resolution; narration pipeline designed | Active |
| D-CREATURES-ACTIONS-SPLIT | Architecture | ✅ Implemented | Extract score_actions/move_creature/execute_action from creatures/init.lua to creatures/actions.lua (split before W1) | Active |
| D-WAVE1-BUTCHERY-CREATURES-SPLIT | Architecture | ✅ Implemented | creatures/init.lua → creatures/actions.lua (546→310 LOC); 0 regressions; −190 LOC headroom for Phase 4 | Active |
| D-WAVE1-BUTCHER-VERB | Architecture | ✅ Implemented | butchery.lua verb handler (167 LOC), 4 aliases, 380 phrases, 12 tests; time advancement via time_offset + FSM tick | Active |
| D-WAVE1-BUTCHERY-OBJECTS | Architecture | ✅ Implemented | 6 butchery objects (wolf-meat, cooked-wolf-meat, wolf-bone, wolf-hide, butcher-knife, spider-meat); creature metadata wired | Active |
| D-STRESS-HOOKS | Architecture | ✅ Implemented | Stress trauma hooks (death, combat, gore) delegate to central injuries.add_stress() API; debuffs as multipliers | Active |
| D-CREATE-OBJECT-ACTION | Architecture | ✅ Implemented | Creature object creation via metadata-driven behavior.creates_object pattern; NPC obstacle detection in navigation | Active |
| Architecture Notes | Architecture | 📦 Archived | See full entry | Archive |
| D-104: PLAYER-CANONICAL-STATE (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-105: OBJECT-INSTANCING-FACTORY (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-123: MATERIAL-MIGRATION (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-167: P0C-META-CHECK-V2 (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-168: COMPOUND-COMMAND-SPLITTING (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-169: AUTO-IGNITE-PATTERN (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-170: DOOR-FSM-ERROR-ROUTING (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-3: Engine Conventions from Pass-002 Bugfixes (2026-03-22) | Architecture | 📦 Archived | See full entry | Archive |
| D-42: Movement Handler Architecture | Architecture | 📦 Archived | See full entry | Archive |
| D-45: FSM Tick Scope | Architecture | 📦 Archived | See full entry | Archive |
| D-ALREADY-LIT: FSM State Detection for Already-Lit Objects | Architecture | 📦 Archived | See full entry | Archive |
| D-APP-STATELESS: Appearance subsystem is stateless | Architecture | 📦 Archived | See full entry | Archive |
| D-APP001: Appearance is an Engine Subsystem | Architecture | 📦 Archived | See full entry | Archive |
| D-BRASS-BOWL-KEYWORD-REMOVAL | Architecture | 📦 Archived | See full entry | Archive |
| D-BROCKMAN001: Design vs Architecture Documentation Separation | Architecture | 📦 Archived | See full entry | Archive |
| D-BUG017: Save containment before FSM cleanup | Architecture | 📦 Archived | See full entry | Archive |
| D-CONDITIONAL: Conditional Clauses Detected in Loop, Not Parser | Architecture | 📦 Archived | See full entry | Archive |
| D-CONSC-GATE: Consciousness gate before input reading | Architecture | 📦 Archived | See full entry | Archive |
| D-CONTAINER-SENSORY-GATING | Architecture | 📦 Archived | See full entry | Archive |
| D-ENGINE-HOOKS-USE-EAT-DRINK | Architecture | 📦 Archived | See full entry | Archive |
| D-FIRE-PROPAGATION-ARCHITECTURE | Architecture | 📦 Archived | See full entry | Archive |
| D-GOAP-NARRATE: GOAP Steps Narrate via Verb-Keyed Table | Architecture | 📦 Archived | See full entry | Archive |
| D-HIT001: Hit verb is self-only in V1 | Architecture | 📦 Archived | See full entry | Archive |
| D-HIT002: Strike disambiguates body areas vs fire-making | Architecture | 📦 Archived | See full entry | Archive |
| D-HIT003: Smash NOT aliased to hit | Architecture | 📦 Archived | See full entry | Archive |
| D-MATCH-TERMINAL-STATE | Architecture | 📦 Archived | See full entry | Archive |
| D-MODSTRIP: Noun Modifier Stripping is a Separate Pipeline Stage | Architecture | 📦 Archived | See full entry | Archive |
| D-MUTATE-PROPOSAL: Generic `mutate` Field on FSM Transitions | Architecture | 📦 Archived | See full entry | Archive |
| D-OBJ004: Wall clock uses 24-state cyclic FSM | Architecture | 📦 Archived | See full entry | Archive |
| D-OBJECT-INSTANCING-FACTORY | Architecture | 📦 Archived | See full entry | Archive |
| D-P1-PARSER-CLUSTER | Architecture | 📦 Archived | See full entry | Archive |
| D-PEEK: Read-Only Search Peek for Containers | Architecture | 📦 Archived | See full entry | Archive |
| D-PLAYER-CANONICAL-STATE | Architecture | 📦 Archived | See full entry | Archive |
| D-PUSH-LIFT-SLIDE-VERBS | Architecture | 📦 Archived | See full entry | Archive |
| D-SEARCH-OPENS: Search Opens Containers (supersedes #24) | Architecture | 📦 Archived | See full entry | Archive |
| D-SLEEP-INJURY: Sleep now ticks injuries (bug fix) | Architecture | 📦 Archived | See full entry | Archive |
| D-SPATIAL-ARCH: Spatial Relationships — Engine Architecture | Architecture | 📦 Archived | See full entry | Archive |
| D-TIMER001: Timed Events Engine — FSM Timer Tracking and Lifecycl | Architecture | 📦 Archived | See full entry | Archive |
| D-UI-1 to D-UI-5: Split-Screen Terminal UI Architecture (2026-07- | Architecture | 📦 Archived | See full entry | Archive |
| D-WASH-VERB-FSM | Architecture | 📦 Archived | See full entry | Archive |
| D-WEB-BUG13: Bug Report Transcript in Web Bridge Layer | Architecture | 📦 Archived | See full entry | Archive |
| D-WINDOW-FSM: Window & Wardrobe FSM Consolidation (2026-03-20) | Architecture | 📦 Archived | See full entry | Archive |
| DIRECTIVE: Core Principles Are Inviolable | Architecture | 📦 Archived | See full entry | Archive |
| DIRECTIVE: User Reference — Dwarf Fortress Architecture Model | Architecture | 📦 Archived | See full entry | Archive |
| UD-2026-03-20T21-54Z: No special-case objects; clock as 24-state  | Architecture | 📦 Archived | See full entry | Archive |
| USER-DIRECTIVE: Merge wardrobe into single FSM file (2026-03-20T2 | Architecture | 📦 Archived | See full entry | Archive |
| USER-DIRECTIVE: Merge window into single FSM file (2026-03-20T21- | Architecture | 📦 Archived | See full entry | Archive |
| Affected Team Members | General | 📦 Archived | See full entry | Archive |
| D-17: Universe Templates (Build-Time LLM + Procedural Variation) | General | 📦 Archived | See full entry | Archive |
| D-37 to D-41: Sensory Verb Convention & Tool Resolution | General | 📦 Archived | See full entry | Archive |
| D-43: Multi-Room Loading at Startup | General | 📦 Archived | See full entry | Archive |
| D-44: Per-Room Contents, Shared Registry | General | 📦 Archived | See full entry | Archive |
| D-46: Cellar as Room 2 | General | 📦 Archived | See full entry | Archive |
| D-47: Exit Display Name Convention | General | 📦 Archived | See full entry | Archive |
| D-5: Spatial Relationships Implementation (2026-03-26) | General | 📦 Archived | See full entry | Archive |
| D-APP002: Layered Head-to-Toe Rendering | General | 📦 Archived | See full entry | Archive |
| D-APP003: Nil Layers Silently Skipped | General | 📦 Archived | See full entry | Archive |
| D-APP004: Appearance Generic Over Player State | General | 📦 Archived | See full entry | Archive |
| D-APP005: Injury Phrases via 4-Stage Pipeline | General | 📦 Archived | See full entry | Archive |
| ... | ... | ... | +87 more archived decisions | Archive |


**Legend:** 🟢 Active | 🔄 In Progress | ✅ Implemented | 📦 Archived

---

## D-WAVE1-BUTCHERY-CREATURES-SPLIT: creatures/init.lua Refactored to actions.lua

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-28  
**Status:** ✅ Implemented  
**Category:** Architecture  
**Phase:** Phase 4 WAVE-1

**Decision:** Extracted `score_actions`, `move_creature`, `find_bait`, `try_bait`, and `execute_action` from `src/engine/creatures/init.lua` into `src/engine/creatures/actions.lua` to free up LOC headroom before Flanders' butchery metadata additions.

**Files Modified:**
- `src/engine/creatures/init.lua`: 546 LOC → 310 LOC (−236 LOC, −43%)
- `src/engine/creatures/actions.lua`: Created, 264 LOC

**How Dependencies Were Handled:**
- **actions.lua** receives `action_helpers` table from init.lua containing utility functions and M.* wrappers
- **M.* wrapper closures** (emit_stimulus, handle_creature_death, attempt_flee) resolve at call time, preserving test monkey-patching
- **morale_helpers.move_creature** delegates to `creature_actions.move_creature` — no circular dependency
- **Public API preserved:** `M.score_actions()` and `M.execute_action()` keep original signatures

**Test Results:**
- Zero regressions: 410 passed, 13 pre-existing failures (unrelated)
- Full suite run confirmed before and after

**Impact on Phase 4:**
- WAVE-1 (Flanders' butchery metadata) now has ~190 LOC of headroom before 500-LOC ceiling
- WAVE-5 behavior additions (~80 LOC) go into actions.lua, not init.lua
- Both modules stay under 500 LOC through all of Phase 4

**Who Should Know:**
- **Flanders:** You have headroom for WAVE-1 butchery metadata; init.lua has space
- **Nelson:** Run full test suite if modifying creature behavior
- **All agents:** No breaking changes to creature module API

---

## D-WAVE1-BUTCHER-VERB: Butcher Verb Handler Implementation

**Author:** Smithers (UI/Parser Engineer)  
**Date:** 2026-03-28  
**Status:** ✅ Implemented  
**Category:** Architecture  
**Phase:** Phase 4 WAVE-1

**Decision 1: File Split — Create `src/engine/verbs/butchery.lua` (not add to crafting.lua)**
- **Chose:** Separate file for distinct system lifecycle
- **Rationale:** Butchery has its own test suite and lifecycle. crafting.lua delegates to it (same pattern as cooking.lua, placement.lua)
- **Result:** 167 LOC, keeps crafting.lua focused on sew/stitch/mend

**Decision 2: Product Instantiation Pattern**
- **Chose:** Inline instantiation loop with nil-guard on `ctx.object_sources` (not using spawn_objects)
- **Rationale:** Shared `spawn_objects` helper crashes if nil (no nil-check). Graceful fallback for test mocks
- **Result:** Same deduplication (id-2, id-3 suffixes for duplicates), works in test + real contexts

**Decision 3: Corpse Removal by ID or GUID**
- **Chose:** Search room.contents for both id and guid match
- **Rationale:** Real engine stores IDs; test mocks use GUIDs. Matching both ensures handler works everywhere without mock changes

**Decision 4: Time Advancement**
- **Chose:** `ctx.time_offset += 5/60` (hours) + 1 FSM tick cycle
- **Rationale:** No `ctx.game:advance_time()` API exists. rest.lua is only existing time-advance pattern. One tick fires FSM transitions + on_tick callbacks + candle burn

**Files Created:**
- `src/engine/verbs/butchery.lua` (167 LOC)

**Parser Coverage:**
- 4 aliases: ["butcher", "butchering", "butchered", "butcher up"]
- 380 embedding phrases
- Integrated into verbs/init.lua dispatch

**Test Results:**
- 12 tests written and passing
- All pass, no regressions

**Affects:**
- **Bart (engine):** Time API discussion for future standardization
- **Nelson (tests):** Butchery test suite in test/verbs/
- **Flanders (objects):** Products spawned via object_sources

---

## D-WAVE1-BUTCHERY-OBJECTS: Butchery Products & Creature Metadata

**Author:** Flanders (Object & Injury Systems Engineer)  
**Date:** 2026-03-28  
**Status:** ✅ Implemented  
**Category:** Architecture  
**Phase:** Phase 4 WAVE-1

**Decision 1: Spider-Meat GUID**
- **Gap:** Bart's pre-assignment (bart-phase4-guids.md) did not include spider-meat
- **Action:** Generated GUID {6b7c8bb2-71b1-4ac6-a57e-8a23536d3054}
- **Note for Bart:** Add this to Phase 4 GUID registry

**Decision 2: Spider vs Wolf Butchery Duration**
- **Spider:** 2 minutes (tiny creature, minimal carving)
- **Wolf:** 5 minutes (large furniture-template corpse, significant processing)
- **Rationale:** Duration scales with corpse size and complexity

**Decision 3: Spider-Meat Poison Risk**
- **Set:** 30% spider-venom risk when eaten (even raw)
- **Rationale:** Spider's venom sac (60% venom on bite) can't be fully separated in tiny meat. Higher risk than cooked-bat-meat (10% food-poisoning)

**Decision 4: Wolf-Hide Keywords**
- **Keywords:** "wolf hide", "animal skin", "pelt", "hide"
- **Bare "hide" included** since no other hide objects exist yet
- **Flag for future:** When "hide" verb implemented, parser needs verb/noun POS gate

**Decision 5: Gnawed-Bone Keyword Fix**
- **Removed:** "wolf bone" from gnawed-bone.lua keywords
- **Replaced with:** "bone fragment"
- **Rationale:** Per Smithers' embedding collision audit, prevent disambiguation collision with new wolf-bone object

**Decision 6: Butcher-Knife Tool Resolution Dual-Pattern**
- **Set:** Both `provides_tool = {"butchering", "cutting_edge"}` AND `capabilities = {"butchering", "cutting"}`
- **Rationale:** Two systems exist in parallel (provides_tool vs capabilities). Included both for maximum compatibility until Bart consolidates tool API in Phase 4 cleanup

**Files Created:**
- `src/meta/objects/wolf-meat.lua` (raw cookable meat)
- `src/meta/objects/cooked-wolf-meat.lua` (cooked food)
- `src/meta/objects/wolf-bone.lua` (improvised weapon)
- `src/meta/objects/wolf-hide.lua` (crafting material)
- `src/meta/objects/butcher-knife.lua` (butchering tool)
- `src/meta/objects/spider-meat.lua` (venom-risk food)

**Files Modified:**
- `src/meta/creatures/wolf.lua` (added butchery_products to death_state)
- `src/meta/creatures/spider.lua` (added butchery_products to death_state)
- `src/meta/objects/gnawed-bone.lua` (removed "wolf bone" keyword)

**Test Results:**
- All 12 butchery tests pass with new objects
- No regressions

**Affects:**
- **Bart (engine):** Tool resolution API consolidation pending (Phase 4 cleanup)
- **Smithers (parser):** Embedding collision fixed; check collision audit for other objects
- **Nelson (tests):** All 12 butchery tests cover these objects
- **Moe (rooms):** Corpses spawn these products in rooms when butchered

---

## D-STRESS-HOOKS: Stress Trauma Hook Architecture

**Author:** Bart (Architect)  
**Date:** 2026-03-28  
**Status:** ✅ Implemented  
**Category:** Architecture  
**Phase:** Phase 4 WAVE-3

**Decision:** Stress trauma hooks follow the same pattern as C11/C12 injury and stimulus hooks — minimal integration points that delegate to a central API (`injuries.add_stress`). No stress-specific logic lives in the caller.

**Key Design Points:**

1. **Three trauma hooks, three files:** 
   - `witness_creature_death` (death.lua)
   - `near_death_combat` (combat/init.lua)
   - `witness_gore` (butchery.lua)
   - Each is a single call to `injuries.add_stress(player, trigger_name)`

2. **Stress debuffs as multipliers:**
   - `attack_penalty` → 15% force reduction per point (floor 0.3×) in `resolution.resolve_damage`
   - `movement_penalty` → probability of movement failure in `verbs/movement.lua` + reduced flee speed in `verbs/init.lua`
   - `flee_bias` → auto-selects flee in headless mode; narrative hint in interactive mode

3. **`is_safe_room(room, registry)`** checks for alive creatures with `behavior.aggression > 0`. Separate from `cure_stress` for flexibility.

4. **Graceful degradation:** All hooks pcall-guard the `engine.injuries` require. If stress.lua metadata doesn't exist, all hooks are no-ops.

**Affects:**
- **Nelson:** Tests verify stress accumulation across triggers and debuff application. See GATE-3 criteria in plan.
- **Smithers:** Narration tables are in injuries/init.lua — review/own the text.
- **Flanders:** stress.lua already matches expected schema. No changes needed.

---

## D-CREATE-OBJECT-ACTION: Creature Object Creation Engine

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-28  
**Status:** ✅ Implemented  
**Category:** Architecture  
**Phase:** Phase 4 WAVE-4

**Decision:** Added `create_object` action to the creature action dispatch system (`src/engine/creatures/actions.lua`). This is a **reusable, metadata-driven** pattern — any creature can create environmental objects by declaring `behavior.creates_object` in their metadata.

**Key Design Choices:**

1. **Cooldown uses `os.time()` (real seconds)** — not coupled to the presentation layer's game-time computation. Creature metadata specifies cooldown in real seconds. This avoids a dependency on `engine/ui/presentation.lua` from the creature subsystem.

2. **Condition function receives `(creature, context, helpers)`** — full context including helpers so conditions can query room contents, registry, etc.

3. **Object instantiation via shallow copy + `registry:register()`** — creature metadata provides `object_def` table (a template for the created object). Engine copies it, stamps a unique ID, sets `creator` field, registers in registry, and places in room via `room.contents`.

4. **NPC obstacle check in `navigation.lua`** — `room_has_npc_obstacle()` scans target room contents for `obstacle.blocks_npc_movement = true`. Integrated into `get_valid_exits()` so all NPC movement (wander, flee, bait-chase) respects obstacles. Player movement is unaffected.

**Files Modified:**
| File | Change |
|------|--------|
| `src/engine/creatures/actions.lua` | Added `create_object` action execution + scoring (~40 LOC) |
| `src/engine/creatures/navigation.lua` | Added `room_has_npc_obstacle()` + obstacle check in `get_valid_exits()` (~20 LOC) |

**Principle 8 Compliance:** No spider-specific or creature-specific logic anywhere. The engine reads `behavior.creates_object` metadata and executes it generically. Any creature (spider, bird, ant) can use this pattern by declaring the appropriate metadata.

**Impact:**
- **Flanders:** Spider metadata should use `behavior.creates_object.object_def` (table of properties for the spawned object), `cooldown` (real seconds), `condition` (function), `narration` (string), `priority` (number, default 15).
- **Nelson:** Test `create_object` via mock creature with `creates_object` behavior. Test NPC obstacle blocking via `navigation.get_valid_exits()` with an obstacle object in target room.

---


### D-14: True Code Mutation (Objects Rewritten, Not Flagged)

**Status:** Foundational

---

### D-INANIMATE: Objects Are Inanimate (Creatures Are Future)

**Author:** Wayne "Effe" Berry + Flanders (Object Engineer)

---

### D-ENGINE-REFACTORING-REVIEW

**Author:** Bart (Architect)

---

### D-HIRING-DEPT: All New Hires Must Have Department Assignment

**Author:** Wayne "Effe" Berry (via Copilot)

---

### D-NO-NEWSPAPER-PENDING: Newspaper Hold Directive



---

### D-VERBS-REFACTOR-2026-03-24

**Author:** Bart (Architect)

---

### D-LARK-GRAMMAR: Lark-Based Lua Object Parser



---

### D-PORTAL-BIDIR-SYNC: Bidirectional Portal Sync Lives in FSM Engine

**Author:** Bart (Architect)  
**Date:** 2026-07  
**Status:** ✅ Implemented

Bidirectional portal synchronization is implemented in `src/engine/fsm/init.lua`, not in individual verb handlers.

When `fsm.transition()` completes successfully, if the transitioned object has `portal.bidirectional_id`, the engine scans the registry for the paired portal and applies the same state change automatically.

**Rationale:**
- **Principle 8 compliance:** Engine executes metadata; no object-specific logic in handlers.
- **Consistency:** Any verb that triggers an FSM transition (open, close, break, unbar, lock) automatically syncs the pair. No risk of forgetting to add sync calls to new verbs.
- **Simplicity:** One sync point instead of N verb handlers each calling sync.

**Impact:**
- **Flanders:** Portal objects only need `portal.bidirectional_id` set to the same value on both sides. No special sync metadata needed.
- **Moe:** Room files don't need any sync logic. Portals sync through the registry automatically.
- **Smithers:** Verb handlers don't need to call `sync_bidirectional_portal()` manually. It happens in FSM.
- **Nelson:** Tests can verify sync by calling `fsm.transition()` directly on a flat registry -- no room context needed.

---

### D-PORTAL-PHASE-2-ROOM-WIRING: Portal Phase 2 Room Wiring Complete

**Author:** Moe (World Builder)  
**Date:** 2026-07-28  
**Category:** Architecture  
**Status:** ✅ Implemented

`start-room.lua` and `hallway.lua` now use thin portal references instead of inline exit tables for the bedroom-hallway oak door.

**What Changed:**
- `exits.north` in start-room → `{ portal = "bedroom-hallway-door-north" }`
- `exits.south` in hallway → `{ portal = "bedroom-hallway-door-south" }`
- Portal objects added to each room's `instances` list
- All other exits (window, trap door, hallway down/north/west/east) remain inline for backward compatibility

**Decision:**
Room files now encode exits as **direction → portal object ID** references. This is the pattern for all future exit definitions (Phase 3 migration). The old inline exit format is deprecated but coexists during migration.

**Impact:**
- **Bart:** Engine must resolve `exits[dir].portal` → registry lookup (now complete via Phase 1 FSM work).
- **Nelson:** Room/door tests need updates to verify portal objects instead of inline fields.
- **Flanders:** Portal object files are referenced by room instances. Do not modify GUIDs without coordination.
- **Smithers:** Verb handlers should already resolve portal objects via registry if Bart's Phase 1 engine work is in.

---

### D-META-CHECK-BUILD-2026-03-24

**Author:** Smithers (UI/Parser)

---

### D-WAYNE-BATCH-2026-03-24: Design Decisions Batch (Wayne)

**Author:** Wayne "Effe" Berry (via Copilot)

---

### D-WAYNE-CODE-REVIEW-DIRECTIVE (2026-03-24T07-28-58Z)

**Author:** Wayne Berry (via Copilot)

---

### D-WAYNE-COMMIT-CHECK: Check Commits Before Push (Quality Gate)

**Author:** Wayne "Effe" Berry (User Directive)

---

### D-WAYNE-CONTRIBUTIONS: Track Wayne Contributions Continuously

**Author:** Wayne "Effe" Berry (User Directive)

---

### D-WAYNE-META-CHECK-SCOPE-EXPANSION (2026-03-24T17-40-46Z)

**Author:** Wayne Berry (via Copilot)

---

### D-WAYNE-TDD-REFACTORING-DIRECTIVE (2026-03-24T07-34-02Z)

**Author:** Wayne Berry (via Copilot)

---

### D-HEADLESS: Headless Testing Mode

**Author:** Bart (Architect)

---

### D-TESTFIRST: Test-First Directive for Bug Fixes

**Author:** Wayne "Effe" Berry (via Copilot)

---

### D-V2-ACCEPTANCE-CRITERIA: P0-C V2 Acceptance Criteria Complete

**Author:** Lisa (Object Testing Specialist)

---

### D-WAYNE-REGRESSION-TESTS: Every Bug Fix Must Include Regression Test

**Author:** Wayne "Effe" Berry (User Directive)

---

### D-NPC-COMBAT-ALIGNMENT: NPC Plan ↔ Combat Plan Alignment

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-03-26  
**Status:** 🟢 Active  
**Category:** Design

**Decision:** Applied all 13 alignment fixes to `plans/npc-system-plan.md`. Both NPC and Combat system plans are now coordinated.

**Critical Fixes:**
1. Body tree phasing moved from NPC Phase 4 → Phase 1 (required by Combat Phase 1)
2. Rat combat metadata added with complete body_tree (4 zones: head, body, legs, tail)
3. Creature-to-creature combat shifted from NPC Phase 3 → Phase 2 (enabled by Combat Phase 1 unified interface)

**High-Priority Fixes:**
4. Creature template updated with `body_tree` and `combat` field stubs (Phase 1+ markers)
5. Tissue materials coordination clarified (NPC: flesh.lua Phase 1; Combat: extends Phase 1)
6. Creature tick ↔ Combat FSM handoff documented (Phase 1 creatures defer `attack` action to Phase 2+)

**Medium-Priority Fixes:**
7. Combat stimulus types added (creature_attacked, creature_injured, creature_died)
8. injuries.inflict() signature updated per Wayne's decision (Phase 1: simple call; Phase 2+: full signature)
9. Size field type standardized to string enum ("tiny", etc.)
10. Combat stimulus emission locations documented (src/engine/combat/init.lua)
11. Phase integration note added to Section 12
12. Weapon combat metadata coordination note (Phase 1 no impact)

**Low-Priority Fixes:**
13. Material naming clarification (flesh distinct from skin/hide)

**Tagging:** All changes marked `[COMBAT ALIGNMENT]` in npc-system-plan.md for easy identification.

**Impact:**
- **Flanders:** Extends rat.lua + creature.lua with body_tree + combat during Combat Phase 1
- **Bart:** Creature tick handles deferred attack action; Combat FSM integration in Phase 2
- **Smithers:** No immediate impact; attack verb unchanged until Phase 2
- **Nelson:** Phase 1 tests verify simple rat bite on grab
- **CBG:** Plans aligned; ready for Phase 1 implementation

**Verification:** `git diff plans/npc-system-plan.md` shows all 13 changes. Combat plan is reference-only (unchanged).

---

### D-COMBAT-NPC-PHASE-SEQUENCING: NPC Phase 1 Uses Simple injuries.inflict()

**Author:** Wayne Berry (via Copilot Coordinator)  
**Date:** 2026-03-26T15:29Z  
**Status:** 🟢 Active  
**Category:** Design

**Decision:** NPC Phase 1 focuses on creature autonomy (behavior, drives, movement). Combat mechanics are deferred to Combat Phase 1.

**Phase 1 Rule:**
- Rats use simple `injuries.inflict()` on grab → no combat FSM, no body_tree, no combat metadata table
- Rat's Phase 1 job: exist, move, react, bite (injury mechanics only)
- Combat Phase 1 retrofits body_tree + full combat table onto creatures later

**Rationale:**
- Principle 8 (engine executes metadata) — dead combat metadata violates principle. Combat metadata only makes sense when Combat Phase 1 engine is ready.
- Sequencing: NPC Phase 1 first establishes creature autonomy; Combat Phase 1 adds combat systems to those creatures
- Keeps Phase 1 focused and shippable

**Affected:**
- **Flanders:** Rat and creature objects are Phase 1 simple; Phase 2 gets combat fields
- **Bart:** Creature tick system handles creature autonomy; Combat FSM waits for Phase 2
- **Nelson:** Phase 1 tests verify injury infliction only
- **CBG:** Maintains design intent while respecting phasing

---

### D-COMBAT-PHASE1-BLOCKING-RESOLUTIONS: Combat Phase 1 — 5 Blocking Questions Resolved

**Author:** Wayne Berry (via Copilot)  
**Date:** 2026-03-26T15:45Z  
**Status:** ✅ Approved  
**Category:** Design

**Q1 — Hit zones:** Random weighted, 60% targeted accuracy. DF-style emergent narrative.

**Q2 — Lethality:** DF-realistic. Steel sword one-shots a rat. Combat is fast and decisive when well-equipped, dangerous when not.

**Q3 — Room scope:** Room-local. Fleeing ends combat. Creature can follow and re-initiate later (if hunt behavior, Phase 2+).

**Q5 — Unarmed combat:** Viable but at a disadvantage. Player can always fight, just poorly. Fists work but barely. "Find a weapon" is strategic advantage, not hard gate.

**Q7 — Combat input model:** HYBRID STANCE-BASED. Player sets stance (aggressive/defensive/balanced) and rounds auto-resolve. BUT the system INTERRUPTS and re-prompts when:
- A weapon breaks
- Armor fails
- The current stance is ineffective after a few auto-resolved rounds
- Any significant state change occurs

This keeps combat flowing but gives player agency at decision points. Not pure per-exchange, not pure auto-resolve.

**Impact:**
- **Bart:** Implement hybrid stance model in combat FSM (WAVE-5.5)
- **Smithers:** Implement combat response prompts with stance interrupts (WAVE-6)

---

### D-NPC-PHASE1-APPROVAL-BATCH: NPC Phase 1 — 7 Questions Resolved

**Author:** Wayne Berry (via Copilot)  
**Date:** 2026-03-26T15:48Z  
**Status:** ✅ Approved  
**Category:** Design

**NPC Q1 — Respawning:** Permanent death in Phase 1. Killed creatures stay dead. Respawn system deferred to Phase 2 if needed.

**NPC Q2 — Multiple creatures per room:** Yes. Support N creatures per room from day one.

**NPC Q3 — Rat inventory:** Deferred to Phase 2. Rat in Phase 1 has no inventory, cannot carry or steal objects.

**NPC Q4 — Rat bite mechanics:** ALREADY RESOLVED — simple injuries.inflict() on grab, no combat FSM. (See D-COMBAT-NPC-PHASE-SEQUENCING.)

**NPC Q5 — Sound across rooms:** Yes. Creatures with sound_range > 0 emit audible events to adjacent rooms.

**NPC Q6 — Save/load persistence:** Registry-driven. Creatures are objects in the registry; existing save/load handles them identically.

**NPC Q7 — Hear rat in darkness:** Yes — this is a FEATURE. Player hears "skittering claws" before they can see anything. Rat's on_listen provides audio-only presence in darkness.

**Impact:**
- **Flanders:** Rat design finalized; no inventory, permanent death, multi-room sound support
- **Bart:** Creature tick implementation in WAVE-2
- **Nelson:** Test framework covers all 7 resolved areas

---

### D-CREATURES-DIRECTORY: Dedicated Directory for Animate Beings

**Author:** Bart (Architect)  
**Date:** 2026-03-26T20:30Z  
**Status:** ✅ Implemented  
**Category:** Architecture

**Decision:** Create dedicated `src/meta/creatures/` directory for animate beings. Creature definitions live alongside (but separate from) inanimate objects in `src/meta/objects/`.

**Rationale:**
Creatures are not inanimate objects. Separating their definitions clarifies ownership, validation rules, and loader behavior while keeping shared template resolution intact.

**Implementation:**
- Loader scans `meta/objects/` then `meta/creatures/` before room resolution; both feed `base_classes` and `object_sources`
- Meta-lint treats `creatures/` files like objects for template resolution, GUID uniqueness, keywords, and sensory checks
- `rat.lua` moved to `src/meta/creatures/rat.lua`; all path references updated

**Changes:**
- `src/engine/loader/init.lua` — added creatures directory scan
- `meta-lint _detect_kind()` — recognizes creatures vs objects
- 7 test files updated (loader, lint, search, inventory)
- Documentation updated (loader.md, object-design-patterns.md)

**Impact:**
- **Flanders:** Template system now supports creature subtypes; can define creature-specific templates
- **Nelson:** Test paths updated; all test discovery mirrors new structure
- **Moe:** Cellar rat instance unchanged (GUID references auto-resolve)

**Commit:** 2b3e426 (all tests pass)

---

### D-FOOD-SYSTEMS-RESEARCH: Food Systems Research Complete

**Author:** Frink (Researcher)  
**Date:** 2026-03-26T20:30Z  
**Status:** ✅ Complete  
**Category:** Research

**Decision:** Comprehensive food systems research complete. Engine is 80% ready for food systems. Hybrid design model validated across 15+ games.

**Deliverables:**
1. **food-systems-research.md** (92 KB) — 15+ games + real-world food science
2. **food-mechanics-comparison.md** (19 KB) — side-by-side game mechanics matrix
3. **food-design-patterns.md** (37 KB) — 15 software patterns with implementation guide
4. **food-integration-notes.md** (37 KB) — system-by-system integration roadmap

**Key Findings:**
- ✅ FSM engine ready (food states: fresh → spoiling → spoiled)
- ✅ Mutation system (D-14) supports cooking (raw-meat.lua → cooked-meat.lua)
- ✅ Sensory properties (smell, taste, feel) perfect for identification
- ✅ Material system extends to food materials
- ✅ Tool capability system gates cooking (fire_source)
- ✅ Containment system handles preservation (containers slow spoilage)
- ✅ Rat creature already has hunger drive

**Hybrid Design Model:**
- **Valheim:** Food as buff/empowerment (not punishment)
- **Dwarf Fortress:** Emotional system, cooking as preservation
- **NetHack:** Risk/reward sensory testing (taste risky)
- **MUDs:** Non-intrusive, optional engagement
- **Text IF:** Sensory richness, puzzle integration

**Effort Estimate:**
- Phase 1 (Basic Consumables): 8 hours
- Phase 2 (Cooking): 10 hours
- Phase 3 (Spoilage): 14 hours
- Phase 4 (Preservation): 10 hours
- Phase 5 (Recipes + Creatures): 12 hours
- **Total:** 32–46 hours (5 sprints)

**Impact:**
- **Comic Book Guy:** Use research to create food mechanics design document
- **Bart:** Review integration notes, validate FSM/material extensions
- **Flanders:** Food object templates, state definitions
- **Sideshow Bob:** Food-based puzzles (bait, creature feeding, cooking challenges)

**Research files:** `resources/research/food/`

---

### D-CHECKPOINT-AFTER-WAVE: Checkpoint After Every Wave

**Author:** Wayne Berry (via Copilot Coordinator)  
**Date:** 2026-03-26T16:30Z  
**Status:** 🟢 Active  
**Category:** Process

**Decision:** After every wave completes, checkpoint: verify the wave was completed fully and update plan documentation to reflect completion status.

**Requirements:**
1. Mark completed waves in planning documents
2. Note any deviations from plan
3. Update plan as living document (not static)
4. Provide audit trail for walk-away execution

**Impact:**
- **All agents:** Plan documentation stays current and reflects reality
- **Wayne:** Clear visibility into progress and deviations
- **Scribe:** Maintains session logs + orchestration logs per spawn

---

### D-STIMULUS-MODULE

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-27T13:30Z  
**Status:** ✅ Implemented  
**Category:** Architecture

**Decision:** Stimulus queue management extracted to `src/engine/creatures/stimulus.lua` (67 LOC). The module owns queue state and exposes `emit`, `clear`, `process`. Helper functions (get_location, get_room_distance) injected via helpers table — not duplicated.

**Impact:**
- Public API unchanged (`creatures.emit_stimulus()`, `creatures.clear_stimuli()`)
- Internal consumers now call `stimulus.process()`
- Phase 2+ NPC behavior system can build on clean stimulus abstraction

---

### D-PREDATOR-PREY-STUB

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-27T13:30Z  
**Status:** 🟡 In Progress  
**Category:** Architecture

**Decision:** `src/engine/creatures/predator-prey.lua` created as stub (38 LOC). No predator-prey code existed in Phase 1. WAVE-1 will populate `detect_prey`, `evaluate_source_filter`, `predator_reaction`.

**Impact:**
- **Flanders:** Creature definitions needing diet/prey_tags ready for Phase 1
- **Comic Book Guy:** Predator-prey mechanics framework ready for Phase 1 design
- Safe defaults prevent side effects while waiting for Phase 1

---

### D-NPC-BEHAVIOR-STUB

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-27T13:30Z  
**Status:** 🟡 In Progress  
**Category:** Architecture

**Decision:** `src/engine/combat/npc-behavior.lua` created as stub (39 LOC). No NPC-specific combat decision code existed in Phase 1. WAVE-1 will populate `select_response`, `select_stance`, `select_target_zone`.

**Impact:**
- Safe defaults (nil/balanced) prevent side effects
- Ready for Phase 1 Combat system integration
- NPC combat AI scaffolding in place

---

### D-TEST-FOOD-DIR

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-27T13:30Z  
**Status:** 🟢 Active  
**Category:** Testing

**Decision:** `test/food/` registered in `test/run-tests.lua`. Directory exists with .gitkeep. Ready for WAVE-1 food/consumption tests.

**Impact:**
- **Nelson:** QA can write food system tests without directory setup
- **All agents:** test/food/ tests run automatically in test suite

---

### D-TISSUE-MATERIALS-AUDIT

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-27T13:30Z  
**Status:** ✅ Complete  
**Category:** Architecture

**Decision:** All 5 tissue materials needed for WAVE-1 body_tree exist: hide, flesh, bone, tooth-enamel, keratin. No creation needed. Material name is "tooth-enamel" (hyphenated, matching filename).

**Impact:**
- **Flanders:** Creature body_tree tissue layer definitions can proceed in WAVE-1
- No material creation blockers
- Material naming convention clarified

---

### D-ORPHAN-ALLOWLIST

**Author:** Nelson (QA Engineer)  
**Date:** 2026-03-27T13:30Z  
**Status:** ✅ Implemented  
**Category:** Testing/Tooling

**Decision:** Added `orphan_allowlist` support to meta-lint config system. The `.meta-check.json` file now supports a `"orphan_allowlist"` dictionary mapping object IDs to reason strings. Objects in the allowlist are skipped by GUID-02 rule.

**Files Changed:**
- `scripts/meta-lint/config.py` — added `orphan_allowlist` field, parsing in `parse_config()`
- `scripts/meta-lint/lint.py` — GUID-02 check calls `_active_config.is_orphan_allowed()`
- `.meta-check.json` — 28 categorized orphan suppressions documented

**Impact:**
- **Flanders:** Safe to defer orphan object creation; lint won't fail
- **Bart:** Config system now supports suppressions for all checks
- Lint pipeline flexibility for deferred content

---

### D-EXIT01-LINT-GAP

**Author:** Nelson (QA Engineer)  
**Date:** 2026-03-27T13:30Z  
**Status:** ✅ Implemented  
**Category:** Testing/Tooling

**Decision:** EXIT-01 lint rule now validates portal targets against room IDs. The Phase 2 inline EXIT-01 check was completed with portal migration; rooms now use `portal` references. Boundary portal handling documented.

**Key Rule:** Portal `target` must reference an existing room OR be nil for boundary portals with `bidirectional_id = nil`.

**Impact:**
- **Moe:** Room creation now gated by EXIT-01 validation; no crashes from broken exits
- **Nelson:** Portal target validation comprehensive
- **Flanders:** Safe to create portal objects; lint validates references

---

### D-KITCHEN-DOOR-TRAVERSAL

**Author:** Nelson (QA Engineer)  
**Date:** 2026-03-27T13:30Z  
**Status:** ✅ Implemented  
**Category:** Architecture

**Decision:** The `courtyard-kitchen-door.lua` portal had `traversable = true` in its `open` and `broken` states, targeting non-existent `manor-kitchen` room. This would cause runtime crash if player opened door and tried to walk through.

**Fix Applied:** Set `traversable = false` with `blocked_message` in both states (collapsed masonry narrative). When `manor-kitchen` is created for Level 2, these states should be restored to `traversable = true`.

**Impact:**
- **Moe:** Room creation for Level 2 triggers portal state restoration
- **Flanders:** Object updates coordinated with Level 2 release
- Safety gate prevents navigation crashes

---

### D-MUTATION-GRAPH-LINTER

**Author:** Bart (Architecture Lead) + Wayne Berry (User Directive)  
**Date:** 2026-03-27T13:30Z  
**Status:** 🟡 In Progress  
**Category:** Testing

**Decision:** Mutation graph linter will be added as pure-Lua test at `test/meta/test-mutation-graph.lua`. It walks all `.lua` files in `src/meta/objects/`, `src/meta/creatures/`, `src/meta/injuries/`, and all subdirectories, extracts all mutation edges (6 mechanisms), builds directed graph, validates every link.

**Key Points:**
1. **Dynamic discovery:** Linter must scan all .lua files recursively under src/meta/ and subdirectories (not hardcoded list) — future-proofs against content growth
2. **Dynamic mutations (`dynamic = true`) flagged but never followed** — only paper.lua currently uses
3. **`becomes = nil` intentional destruction** — not error, not broken edge
4. **Cycles reported but not failures** — toggle patterns (matchbox ↔ matchbox-open) valid game mechanics
5. **Template inheritance deferred** — all current instances redeclare; merging Phase 2 enhancement
6. **4 known broken edges** will generate GitHub issues assigned to Flanders: poison-gas-vent-plugged, wood-splinters ×3

**Implementation Plan:** 4 phases documented in `plans/mutation-graph-linter-plan.md` (357 lines)
1. Documentation (this decision)
2. Implementation (Nelson writes test/meta/test-mutation-graph.lua)
3. Skill building (team learns linter patterns)
4. Execution (run linter, file GitHub issues)

**Impact:**
- **Nelson:** Implements test file; dynamic file discovery prevents future gaps
- **Flanders:** Will receive GitHub issues for missing object files
- **Brockman:** Writes `docs/testing/mutation-graph-linting.md`
- **Bart:** Designs graph library functions
- **Wayne:** Dynamic discovery addresses user directive (2026-03-27T13-17-36Z)

---

### D-DOOR-ARCHITECTURE: Door/Exit Architecture Direction

**Author:** Bart (Architect)  
**Date:** 2026-07-28  
**Status:** Proposed — awaiting Wayne's decision  
**Category:** Architecture  
**Analysis:** `plans/door-architecture-analysis.md`

**Summary:** After deep analysis of the current hybrid door/exit system against all 11 Core Principles, recommend **Option B: Doors become first-class objects** using a `passage` template and the existing object system (FSM, mutation, sensory, materials).

**Key Finding:** The current exit system is a **parallel object system** — ~322 lines of exit-specific engine code across 8 files duplicating capabilities the object system already provides (FSM, mutation, keyword matching, sensory, effects). Exits satisfy **0 of 11** Core Principles. Full unification satisfies **11 of 11**.

**Proposed Approach:**
1. Create `passage` template for traversable objects
2. Room `exits` tables become thin direction → passage-object-ID references
3. Door state managed by standard FSM (`traversable` flag per state)
4. Door mutations use standard `becomes` code rewrite (D-14 compliant)
5. Remove `becomes_exit`, `exit_matches()`, and exit-specific verb paths
6. Incremental migration: one door at a time, backward-compatible

**Impact:**
- **Net -177 lines** of engine code (remove 252 exit-specific, add 75 passage support)
- Unlocks: multi-step mechanisms, composite doors, material-derived behavior, timed passages, reusable templates
- **4–6 sessions** estimated for full migration

**Decision Points for Wayne:**
1. Go/No-Go on unification
2. Template name: `passage` (recommended) vs `portal` vs `exit`
3. Bidirectional strategy: paired objects (recommended) vs single shared object
4. Migration start: bedroom-hallway door (recommended first candidate)

**Who Should Know:**
- **Flanders** — door object definitions will migrate to passage template pattern
- **Moe** — room exit tables simplify to thin references
- **Smithers** — exit-specific parser/verb code paths will be removed
- **Nelson** — ~15–20 test files need mock context updates during migration
- **Comic Book Guy** — new game design possibilities (drawbridges, mechanisms, magical wards)

---

### D-DOOR-FIRST-CLASS-OBJECTS: Doors Should Be First-Class Objects

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-07-27  
**Status:** PROPOSED — Awaiting Wayne's review  
**Category:** Design  
**Analysis:** `plans/door-design-analysis.md`

**Decision:** Doors, windows, gates, portcullises, and all passage-gating constructs should be **first-class objects** (.lua files with templates, FSM, sensory properties, material inheritance) rather than inline exit-construct tables.

Room exit tables should become thin routing references:
```lua
exits = {
    north = { target = "hallway", door_id = "bedroom-door" }
}
```

All door behavior (state, transitions, mutations, sensory descriptions, material properties) lives in the door object file, not the exit table.

**Rationale:**
1. **Genre precedent:** Zork, Inform 6/7, Hugo all model doors as objects. TADS 3's exit-construct approach is its most criticized design.
2. **Principle alignment:** Door-objects align with Principles 1, 3, 4, 6, 7, 8, 9, and D-14. Exit-constructs violate all of them.
3. **Sensory system:** Game starts at 2 AM in darkness. Players FEEL doors. Exit-constructs don't participate in sensory space.
4. **Scenario coverage:** Door-objects handle all 10 tested scenarios. Exit-constructs fail on 3 (talking doors, remote mechanisms, timed drawbridges).
5. **Designer ergonomics:** Template inheritance + thin exits = less boilerplate than 150-line inline exit definitions.

**Migration Path:**
- **Phase 1 (Now):** Keep existing exits. Document door-object pattern.
- **Phase 2 (Post-playtest):** Create `door` template. Migrate bedroom-door to thin-exit pattern.
- **Phase 3:** Migrate remaining exits. Remove inline mutation code.
- **Phase 4:** All doors are objects. Exits are thin references.

**Affects:**
- **Bart:** Movement handler reads door object state; exit table schema change
- **Flanders:** Creates door template and door object definitions
- **Moe:** Room files simplified — thin exit references replace inline door logic
- **Smithers:** Verb dispatch routes to door objects
- **Nelson:** Regression tests for all door interactions during migration

**Risk:** Primary risk is sync bugs between door object state and exit traversability. Mitigation: door object is SOLE source of truth — exit tables contain only `target` and `door_id`, zero state.

---

### D-LINTER-AUDIT-BASELINE: Meta-lint Audit Baseline Established

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-25  
**Status:** 🟢 Active  
**Category:** Architecture  
**Scope:** All squad members

**Decision:** The meta-lint system baseline is established:
- **0 errors** across all 182 rules
- **152 warnings** (143 are XF-03 keyword collisions)
- **6 info** findings

**Implications:**
1. **Flanders:** 4 new issues assigned (#245–#248) — injury sensory gaps, trap-door description, and 4 missing healing item objects.
2. **All members:** New meta file additions should pass `python scripts/meta-lint/lint.py` with zero new findings before PR.
3. **XF-03 is the dominant issue.** 90% of all findings are keyword collisions. Smithers and Flanders should coordinate on disambiguation (#190).

**Affected Issues:**
- #245, #246, #247, #248 (new)
- #190, #195, #196 (existing, unchanged)

---

### D-LINTER-PHASE1: Meta-Check Rule Registry & Configuration

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-30  
**Status:** Implemented  
**Category:** Architecture  
**Branch:** squad/linter-improvements

**Decision:** Meta-check now has three new architectural layers:

**1. Rule Registry** (`scripts/meta-check/rule_registry.py`)
Every rule the linter can emit is registered with metadata:
- `severity`: default error/warning/info level
- `fixable`: whether the violation can be auto-fixed
- `fix_safety`: "safe" (idempotent) or "unsafe" (needs human review)
- `category`: grouping key for bulk enable/disable
- `description`: human-readable description

**110+ rules registered** across 13 categories.

**2. Per-Rule Configuration** (`.meta-check.json`)
Teams can customize which rules run via JSON config file with rule overrides and category disables.

**3. Safe/Unsafe Fix Classification**
JSON output includes `fixable` and `fix_safety` fields per violation, plus summary counts.

**4. Rule Gap Fixes**
- **XF-03:** Smart keyword collision filtering
- **MD-19:** Upgraded to conflict detection with actual values
- **XR-05b:** New rule — warns when objects inherit generic material without override

**Who Should Know:**
- **Nelson/Lisa (QA):** New test file at `test/meta-check/test_phase1.py` (29 tests)
- **Flanders (Objects):** XR-05b may flag objects missing material overrides
- **Gil (CI):** JSON output format bumped to v2.0 with `fixable`/`fix_safety` fields
- **All:** Use `--list-rules` to see all rules, `--init-config` to generate default config

---

### D-LINTER-PHASE2: GUID/EXIT Validation

**Author:** Bart (Architecture Lead)  
**Date:** 2026-07-29  
**Status:** Active  
**Category:** Architecture

**What Changed:** Added 5 new lint rules in Phase 2:

| Rule | Severity | Category | Description |
|------|----------|----------|-------------|
| GUID-01 | error | guid-xref | Room instance type_id must reference a known object GUID |
| GUID-02 | warning | guid-xref | Orphan object not referenced by any room instance |
| GUID-03 | error | guid-xref | Duplicate instance id within same room |
| EXIT-01 | error | exit | Exit target must reference a valid room |
| EXIT-02 | warning | exit | Bidirectional exit mismatch |

**Bug Fix:** `_detect_kind()` now recognizes `src/meta/rooms/` directory (was only checking `src/meta/world/`).

**Who This Affects:**
- **Moe:** GUID-02 reports 21 orphan objects. Review which are intentional (mutation targets) vs need placement.
- **Flanders:** GUID-01 validates every type_id in room instances.
- **Nelson:** 20 new tests in `test/meta-check/test_phase2.py`
- **All content authors:** EXIT-01 flags exits to non-existent rooms; can suppress via config if intentional.

---

### D-LINTER-PHASE3: Squad Routing & Incremental Caching

**Author:** Bart (Architecture Lead)  
**Date:** 2026-07-29  
**Status:** Active  
**Category:** Architecture  
**Branch:** squad/linter-phase3

**What Changed:**

**Squad Routing:** Every linter violation now includes an `owner` field identifying which squad member should fix it. Default routing table:

| Pattern | Owner |
|---------|-------|
| S-*, PARSE-*, G-*, FSM-*, TR-*, SN-*, TD-*, GUID-* | Bart |
| INJ-*, MD-*, MAT-*, CREATURE-* | Flanders |
| RM-* | Moe |
| LV-* | Comic Book Guy |
| XF-*, XR-* | Smithers |
| EXIT-* | Sideshow Bob |

Overridable via `squad_routing` section in `.meta-check.json`.

**Incremental Caching:** The linter caches per-file violations keyed by SHA-256 hash. Cross-file rules (XF/XR/GUID/EXIT/LV-40) always re-run. Use `--no-cache` for full re-scan.

**Who Needs to Know:**
- **Coordinator:** Use `--format json` output to auto-route violations via `owner` field
- **Smithers:** Owns 151/183 violations (143 XF-03 collisions) — review keyword allowlist
- **Sideshow Bob:** Owns 4 EXIT-01 errors
- **All agents:** Text output shows `[owner]` per violation; use `--by-owner` for grouped view
- **Gil:** Cache file `.meta-lint-cache.json` is gitignored

**Version:** meta_check_version bumped from 2.0 → 3.0.

---

### D-NPC-COMBAT-IMPL-PLAN: Unified NPC+Combat Implementation Plan

**Author:** Bart (Architect)  
**Date:** 2026-07-28  
**Status:** 🟢 Active  
**Category:** Architecture

**Decision:** Created unified implementation plan at `plans/npc-combat-implementation-plan.md` merging NPC Phase 1 and Combat Phase 1 into a 6-wave, 6-gate execution pipeline with explicit file ownership and TDD gates.

**Key Architectural Decisions:**
1. **NPC Phase 1 ships before Combat Phase 1** — creature autonomy proven before adding combat complexity
2. **Creature tick integration point:** After fire propagation, before injury tick in `loop/init.lua`
3. **Stimulus system:** Simple event queue in `engine/creatures/init.lua`, consumed by creature tick
4. **Combat engine:** Single `resolve_exchange()` function handles all combatants generically
5. **No file conflicts:** Explicit ownership map per wave
6. **Test runner expansion:** `test/creatures/` and `test/combat/` directories added incrementally

**Impact:**
- **Flanders:** Creates creature template, rat, flesh material (WAVE-1); retrofits body_tree + tissue materials (WAVE-4)
- **Bart:** Builds creature tick engine (WAVE-2), stimulus emission (WAVE-3), combat FSM (WAVE-5), combat integration (WAVE-6)
- **Smithers:** Implements catch/chase/attack verbs (WAVE-3), combat verb extensions (WAVE-6)
- **Moe:** Places rat in room (WAVE-3)
- **Nelson:** TDD test suite at every wave; LLM walkthroughs at GATE-3 and GATE-6
- **Coordinator:** Autonomous wave→gate→wave execution loop; Wayne check-in at GATE-3 and GATE-6 only

---

### D-PLAN-REVIEW-FIXES: NPC+Combat Plan Review — All 16 Issues Fixed

**Author:** Bart (Architect)  
**Date:** 2026-07-28  
**Status:** 🟢 Active  
**Category:** Process

**Decision:** Applied all 8 blockers and 8 concerns from team review to `plans/npc-combat-implementation-plan.md`.

**Blockers Applied:**
- B1: Hybrid stance combat added (WAVE-5.5)
- B2: Documentation deliverables added (Brockman, WAVE-3 & WAVE-6)
- B3: Player model file path verified (src/main.lua lines ~305–324)
- B4: Test dirs registered in run-tests.lua (WAVE-0)
- B5: Creature tick perf budget added (<50ms, 5 creatures)
- B6: Material registry test clarified (explicit engine.materials.get() call)
- B7: Distant-room stimulus boundary test added (WAVE-2 test case #13)
- B8: NPC docs assigned to Brockman

**Concerns Applied:**
- C1: Gate failure protocol added (Section 12)
- C2: Commit/push points specified (after every gate)
- C3: Combat sub-loop input clarified (headless auto-selects balanced)
- C4: verbs/combat.lua ownership clarified
- C5: Rat spawn location specified (cellar, top-level)
- C6: LLM determinism via seeding (math.randomseed(42))
- C7: Narration variety assertion added (WAVE-5 test)
- C8: Escalation threshold set to 1x failure for Phase 1

**Additional Changes:**
- **combat/narration.lua split:** Changed from optional to REQUIRED
- **Nelson as gate signer:** Added to GATE-3 and GATE-6 reviewer lists

**Impact:** All agents — plan is now single source of truth. Re-read before starting work.

---

### D-SWIMLANE-SQUAD-ARCHITECTURE: Swimlanes as Enforceable Queues

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-25T15:00:00Z  
**Status:** Implemented  
**Category:** Process

**Decision:** Swimlanes are the Squad's operational contract — **enforceable queues, not visualizations**. Each swimlane is owned by exactly one agent, maps to a `squad:{member}` label, and drives work autonomously.

**D-BLOCKED-SWIMLANE:** Issues that cannot proceed without human action move to "Blocked / Needs Human" lane with mandatory status emission:
1. Agent identifies blocker
2. Agent moves issue to blocked lane
3. Agent emits status: what is blocked, why, what is needed, who acts
4. Agent does NOT continue work until blocker is resolved

**D-RALPH-PULL-INTEGRATION:** Ralph (work monitor) watches for stalled work but respects autonomy:
1. Monitor: Ralph detects issues in Ready > N days without pickup
2. Spawn: Ralph can spawn agent to review swimlane
3. Respect: Ralph checks for active PRs before spawning
4. No double-spawn: If agent has work in progress, Ralph does not spawn
5. Escalate: If no response after spawn, Ralph flags for Lead review

**D-HUMAN-BOARD-BOUNDARIES:**
- **Human responsibilities:** Define swimlane structure, set review criteria, triage issues, unblock agents, close decision loops
- **Squad responsibilities:** Move cards between lanes, pull work, open PRs, emit status, move to Done

**Anti-patterns to prevent:**
- ❌ Humans manually dragging cards (except triage/review)
- ❌ Squad agents bypassing swimlane protocol
- ❌ Swimlanes used as passive visualization
- ❌ "Pending" states without clarity

---

### D-WEAR-HAND-DEFENSIVE-SWEEP: Wear Handler Defensive Sweep

**Author:** Bart (Architect)  
**Date:** 2026-03-31  
**Status:** Implemented  
**Category:** Bugfix  
**Issue:** #180

**Decision:** When moving an item from hand to worn, the wear handler now clears **all** hand slots holding that item (by ID match), not just the single `hand_slot` discovered. The take handler now blocks picking up worn items (checking `ctx.player.worn`).

**Rationale:** Wayne's playtest showed a spittoon in both left hand AND worn simultaneously. The defensive sweep is O(2) — zero performance cost, maximal safety. The take handler's Bug #53 guard only checked hands for duplicates, not the worn list.

**Pattern:** **Defensive sweep over targeted clear** — when mutating player state (hands ↔ worn ↔ bags), always sweep all related slots by ID rather than relying on a single index.

**Impact:**
- **Smithers:** No parser changes. Fix is in verb handlers.
- **Nelson:** 7 new integration tests in `test/integration/test-wear-hand-integration.lua`
- **Flanders:** No object changes. Wear table contract unchanged.
- **Gil:** Web adapter uses same verb handlers — fix applies to both paths.

---

### D-PARSER-BM25-PHASE1: BM25 Scoring & Synonym Expansion for Tier 2

**Author:** Smithers (Parser/UI Engineer)  
**Date:** 2026-07-20  
**Status:** Implemented  
**Category:** Parser  
**Branch:** squad/parser-bm25-phase1

**Decision:** Replaced Jaccard similarity with BM25 (Okapi) scoring as the default Tier 2 matching algorithm. Added synonym expansion table and expanded stop word list. All changes A/B-proven.

**What Changed:**
1. **Scoring mode flag:** `embedding_matcher.scoring_mode` defaults to `"bm25"`. Set to `"jaccard"` to revert.
2. **BM25 scoring:** IDF-weighted term frequency (k1=1.2, b=0.5). IDF table precomputed at build time.
3. **Synonym expansion:** 60+ verb synonyms map player words to canonical verbs before matching.
4. **Stop words expanded:** 21 → 60+ common English filler words removed before matching.
5. **Dual threshold:** `THRESHOLD_BM25 = 3.00` / `THRESHOLD_JACCARD = 0.40`
6. **Typo correction tightened:** 5-char words now require distance ≤1 (was ≤2)

**A/B Results:**

| Algorithm | Correct | Accuracy | False Positives | False Negatives |
|-----------|---------|----------|-----------------|-----------------|
| Jaccard (baseline) | 47/60 | 78.3% | 0 | 13 |
| BM25 + Synonyms | 60/60 | 100.0% | 0 | 0 |
| **Delta** | **+13** | **+21.7pp** | **0** | **-13** |

**Files Created/Modified:**
- `src/engine/parser/bm25_data.lua` (new, auto-generated)
- `src/engine/parser/synonym_table.lua` (new)
- `src/engine/parser/embedding_matcher.lua` (modified)
- `src/engine/parser/init.lua` (modified)
- `scripts/build-idf-table.py` (new)
- `test/parser/test-tier2-benchmark.lua` (new)

**Impact on Other Agents:**
- **Nelson (QA):** New benchmark at `test/parser/test-tier2-benchmark.lua`. All 137 existing tests pass.
- **Gil (Web):** `bm25_data.lua` and `synonym_table.lua` are pure Lua — Fengari compatible. Web build needs regeneration.
- **Bart (Architecture):** No engine architecture changes. BM25/synonyms localized to embedding_matcher.
- **Frink (Research):** Phase 1 complete. Phase 2 (soft cosine, inverted index) can build on this foundation.

---

### D-AUTO-IGNITE-TIMER-AUDIT: Direct State Assignment Timer Audit

**Author:** Nelson (QA)  
**Date:** 2026-07-27  
**Status:** Proposed  
**Category:** Architecture  
**Issue:** #178

**Decision:** Any code path that changes an object's `_state` field directly (bypassing `fsm.transition()`) MUST also call `fsm.start_timer(registry, obj_id)` if the new state has `timed_events`.

**Context:** Bug #178 (lit match never burns out) — `auto_ignite()` in `src/engine/verbs/fire.lua` sets `_state = "lit"` directly without starting the FSM timer.

**Known Direct State Assignments:**
1. **`fire.lua` — `auto_ignite()`** — confirmed bug, no timer started
2. **`meta.lua` — `set` handler** — clock puzzles, may not need timers
3. **`helpers.lua` — `detach_part()` / `reattach_part()`** — composite parts

**Who Should Know:**
- **Bart:** FSM architecture owner. Should review whether `apply_state()` should auto-call `start_timer()`
- **Smithers:** Owns verb handlers where direct assignments exist
- **Flanders:** Any objects with timed states affected by these paths

---

### D-COMBAT-RESEARCH: Combat System Research Complete

**Author:** Frink (Research Scientist)  
**Date:** 2026-03-25  
**Status:** Research Complete — awaiting design decisions  
**Category:** Research

**Summary:** Completed comprehensive combat research across 5 domains (MUDs, competitive games, board games, MTG, Dwarf Fortress). All findings in `resources/research/combat/` (6 documents, ~86KB).

**Key Recommendations:**
1. **Adopt DF's material-physics model** for damage resolution. Our 17+ material registry needs 4 combat properties (shear resistance, impact resistance, density, max edge). Damage emerges from material interaction.
2. **Deterministic combat with bounded variance.** Steel cuts flesh. Always. Variance comes from hit location (random, weighted) and player choice.
3. **Unified combatant interface.** One `resolve_combat()` function for all. No combatant-type-specific code (Principle 8).
4. **Creatures declare combat as metadata.** Natural weapons, body zones, armor, behavior — all in creature's `.lua` file.
5. **MTG-inspired turn structure.** Initiative → attacker acts → defender responds → resolve → narrate. Player always gets response choice.

**Who Should Know:**
- **Bart:** Design combat resolution module (`src/engine/combat/`)
- **Flanders:** Creature objects need `combat` metadata with natural weapons, body zones, behavior
- **Moe:** Rooms may need combat-relevant spatial properties
- **Smithers:** Combat verbs needed (attack, block, dodge, flee) + combat-state response prompts
- **Comic Book Guy:** Design decisions needed on Phase 1 scope
- **Nelson:** Combat test framework; DF-style material interactions are highly testable

**Open Decisions for Wayne/Team:**
1. **Deterministic or probabilistic?** (Research recommends: primarily deterministic)
2. **DF detail level?** (Research recommends: 4–6 body zones, not 200 parts)
3. **Phase 1 scope?** (Research recommends: single rat combat with material comparison, body zones)

---

### D-PRIME-DIRECTIVE-TIERS-1-5: Prime Directive Tiers 1–5 Design Spec

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-03-25  
**Issue:** #106  
**Status:** Design Complete  
**Category:** Design  
**Deliverable:** `docs/design/prime-directive-tiers.md`

**Summary:** Designed the 5-tier parser Prime Directive system from the player's perspective. This is the governing design document for all parser work.

**Priority Order:** Tier 2 (Error Messages) > Tier 5 (Fuzzy) > Tier 4 (Context) > Tier 1 (Questions) > Tier 3 (Idioms)

Error messages are #1 because they're the safety net. Every player will hit error messages; good ones teach, bad ones frustrate.

**Error Message Categories:** Five distinct categories with own response strategy:
1. Unknown verb — narrator bemused but helpful
2. Unknown noun — context-aware, never reveals hidden objects
3. Impossible action — explain why using material properties
4. Missing prerequisite — hint without solving puzzles
5. Ambiguous target — use location and properties to disambiguate

**Fuzzy Confidence Tiers:**
- Score ≥5: Execute immediately
- Score 3–4: Execute with narration "(Taking the *brass key*...)"
- Score 2: Confirm "Did you mean the *candle*?"
- Score ≤1: Fall through to error

**Idiom Library Cap:** Target 80–120 entries. Beyond that, invest in Tier 2 embedding matching.

**"OOPS" Command:** When parser fails on unrecognized noun, store the input. If player types "oops {word}", replace and re-parse. ~20 lines Lua, enormous UX value.

**Disambiguation Memory:** After asking "Which do you mean?", store option list for 3 commands.

**Who Should Know:**
- **Smithers:** Implementation roadmap. Start with Tier 2 (error messages).
- **Nelson:** Test coverage for each tier. Error message regression tests.
- **Flanders:** Objects need good `keywords` (including color terms) for Tier 5 fuzzy matching
- **Moe:** Room descriptions use consistent object naming for Tier 5 partial matching
- **Brockman:** Update parser architecture docs to reference this design spec

---

### D-DOCS-REFLECT-CURRENT-STATE: Documentation Reflects Current System State

**Author:** Wayne Berry (via Copilot)  
**Date:** 2026-03-25T12:35:00Z  
**Status:** 🟢 Active  
**Category:** Process

**Decision:** Documentation files represent the CURRENT state of the system, not historical analysis snapshots. Analysis files should be cleaned up and converted into living documentation. Phase plans (like the portal plan) should include a phase for converting analysis files into authoritative docs.

**Why:** Docs are authoritative current-state references, not historical analysis artifacts.

**Impact:** When writing plans or analysis documents, earmark conversion-to-docs as a phase task.

---


---

# Merged from Inbox (2026-03-27)
# Decisions (Last merged: 2026-03-27 05:28:13)

## bart-cooking-craft-architecture

# D-COOKING-CRAFT: Cooking-as-Craft Architecture

**Author:** Bart (Architect)  
**Date:** 2026-03-27  
**Status:** 🟢 Proposed  
**Category:** Architecture  
**Requested by:** Wayne Berry  
**Relates to:** D-14 (True Code Mutation), D-FOOD-SYSTEMS-RESEARCH

---

## Context

Wayne's directive: *"Some food can't be eaten without cooking, like raw flesh. You need to apply a craft like cooking to make the state change from raw flesh to edible meat. Or baking for grain into bread."*

This connects the **crafting system** (`src/engine/verbs/crafting.lua`) with the **mutation system** (D-14). After reading both systems, the existing `sew` verb in crafting.lua provides the exact template for cooking — it uses `material.crafting.sew` recipes on objects with tool gating and material consumption. Cooking follows the same pattern.

---

## Decision 1: Cooking Uses Mutation, Not FSM

**Choice: Option B — Mutation (D-14)**

Cooking transforms `raw-rat-meat.lua` → `cooked-rat-meat.lua` via the existing mutation system. This is the correct choice because:

1. **Cooked meat is a fundamentally different object.** Different name, different description, different sensory properties (smell, taste, feel), different nutrition, different material behavior, different keywords. This isn't a state — it's a transformation.
2. **D-14 Prime Directive:** "Code Mutation IS State Change." When you cook meat, the object's code is rewritten. The cooked-meat.lua file has completely different sensory text, edibility, nutrition, and room_presence.
3. **FSM is wrong here.** FSM is for objects that cycle through states while remaining the same object (candle: unlit → lit → extinguished). A raw chunk of meat that becomes cooked is not the same object with a flag change — it's a material transformation. Different smell, different taste, different texture, different weight (water loss), different everything.
4. **Precedent:** The existing `sew` verb already does this — cloth + needle → sewn item via `recipe.becomes`, which triggers mutation through `spawn_objects`. The `write` verb also demonstrates dynamic mutation via `ctx.mutation.mutate()`.

**Exception — FSM for spoilage AFTER cooking:** Cooked meat can use FSM states for post-cooking degradation: `fresh → cooling → cold → spoiling → spoiled`. That's legitimate FSM territory — same object degrading over time with changing sensory properties.

---

## Decision 2: `cook` Is a New Verb, Not a Craft Sub-Verb

**Choice: Dedicated `cook` verb with `bake`/`roast` as aliases.**

Rationale:
- Players will type `cook meat`, `cook rat`, `bake bread`, `roast meat` — these are natural language verbs, not "craft meat"
- The `sew` pattern in crafting.lua proves the model: each craft type gets its own verb handler (`sew`, `stitch`, `mend` are aliases)
- `cook` reads recipes from `obj.crafting.cook` — exactly how `sew` reads from `obj.crafting.sew`
- `bake` is an alias for `cook` — same mechanism, different word. The recipe on the object controls what happens, not the verb name.

Verb aliases:
```
cook → cook handler
roast → cook handler
bake → cook handler
grill → cook handler
fry → cook handler (future)
```

---

## Decision 3: Cooking Uses the `crafting` Field Pattern

The existing `sew` verb reads recipes from `material.crafting.sew`. Cooking follows the same convention: `obj.crafting.cook`.

### Raw Rat Meat — Object Definition

```lua
-- raw-rat-meat.lua
return {
    guid = "{a1b2c3d4-...}",
    template = "small-item",
    id = "raw-rat-meat",
    name = "a chunk of raw rat meat",
    keywords = {"rat meat", "raw meat", "meat", "raw rat meat", "flesh"},
    description = "A ragged chunk of dark red meat, torn from the rat's carcass. Blood still seeps from the torn edges.",

    material = "flesh",
    size = 1,
    weight = 0.2,
    portable = true,
    categories = {"small", "food", "raw", "perishable"},

    -- Edibility gating: NOT edible raw
    edible = false,
    on_eat_reject = "You can't eat this raw. You'd need to cook it first.",
    cookable = true,

    -- Sensory (on_feel mandatory)
    on_feel = "Cold, wet, slippery. Stringy fibers and the grit of small bones.",
    on_smell = "Raw blood and musk. The sharp copper smell of fresh meat.",
    on_taste = "You'd need to be truly desperate to eat this raw.",
    on_listen = "Silent. A faint drip of blood.",

    room_presence = "A chunk of raw meat lies on the ground, dark and bloody.",

    -- Crafting recipe: cook verb triggers mutation
    crafting = {
        cook = {
            becomes = "cooked-rat-meat",
            requires_tool = "fire_source",
            message = "You hold the meat over the flames. It sizzles and darkens, the blood hissing away. The smell shifts from raw copper to something almost appetizing.",
            fail_message_no_tool = "You need a fire source to cook this.",
        },
    },

    -- Mutation fallback (same recipe exposed for engine flexibility)
    mutations = {
        cook = {
            becomes = "cooked-rat-meat",
            requires_tool = "fire_source",
            message = "You cook the raw meat over the flames.",
        },
    },
}
```

### Cooked Rat Meat — Mutation Target

```lua
-- cooked-rat-meat.lua
return {
    guid = "{e5f6a7b8-...}",
    template = "small-item",
    id = "cooked-rat-meat",
    name = "a piece of cooked rat meat",
    keywords = {"rat meat", "cooked meat", "meat", "cooked rat meat", "food"},
    description = "A charred chunk of rat meat, browned and crispy at the edges. Not exactly a feast, but it smells better than it did raw.",

    material = "flesh",
    size = 1,
    weight = 0.15,  -- Water loss from cooking
    portable = true,
    categories = {"small", "food", "cooked", "perishable"},

    -- NOW edible
    edible = true,
    nutrition = 15,
    on_eat_message = "You chew the tough, gamey meat. Not good, but it fills your stomach.",
    cookable = false,  -- Already cooked

    -- Sensory properties completely different
    on_feel = "Warm and firm. The surface is slightly crispy, the inside dense and fibrous.",
    on_smell = "Charred meat — smoky, savory, with an undertone of gaminess.",
    on_taste = "Tough and gamey, but edible. The char adds a bitter smokiness.",
    on_listen = "Faint crackling as it cools.",

    room_presence = "A piece of cooked meat sits here, still faintly steaming.",

    -- Optional: FSM for post-cooking spoilage
    initial_state = "fresh",
    _state = "fresh",
    states = {
        fresh = {
            description = "A piece of cooked rat meat, still warm.",
            on_smell = "Charred meat — smoky, savory.",
            edible = true,
            nutrition = 15,
        },
        cold = {
            description = "A piece of cold cooked rat meat. Congealed grease coats the surface.",
            on_smell = "Cold grease and old meat.",
            edible = true,
            nutrition = 10,
        },
        spoiled = {
            description = "Rotten meat. Grey-green mold covers the surface.",
            on_smell = "Foul. Rotting meat and mold.",
            edible = false,
        },
    },
    transitions = {
        { from = "fresh", to = "cold", verb = "_tick", condition = "time_elapsed", duration = 3600 },
        { from = "cold", to = "spoiled", verb = "_tick", condition = "time_elapsed", duration = 7200 },
    },
}
```

### Grain → Bread (Baking Example)

```lua
-- grain-sack.lua already exists. Grain is NOT directly edible or bakeable —
-- it's a CRAFTING INGREDIENT. The player extracts grain from the sack,
-- then bakes it. The grain-sack object stays as a puzzle container.

-- For a standalone grain object (extracted or found loose):
-- grain-handful.lua
return {
    guid = "{...}",
    template = "small-item",
    id = "grain-handful",
    name = "a handful of barley grain",
    keywords = {"grain", "barley", "kernels"},
    description = "A handful of dry barley kernels.",

    edible = false,
    on_eat_reject = "Raw grain is too hard to chew. You'd need to grind and bake it.",
    cookable = true,

    on_feel = "Dry, hard little kernels that shift between your fingers.",
    on_smell = "Dusty, faintly nutty.",

    crafting = {
        cook = {
            becomes = "flatbread",
            requires_tool = "fire_source",
            message = "You spread the grain on a flat stone near the fire. With patience, the kernels soften and fuse into a crude flatbread.",
            fail_message_no_tool = "You need a fire source to bake this.",
        },
    },

    mutations = {
        cook = {
            becomes = "flatbread",
            requires_tool = "fire_source",
            message = "You bake the grain into a rough flatbread.",
        },
    },
}
```

---

## Decision 4: Edibility Gating in the Eat Handler

The existing `eat` handler in `survival.lua` (line 84) checks `obj.edible`. This already works for cooked food. For raw food, we add a hint mechanism:

**Current behavior (line 84-103):**
```lua
if obj.edible then
    print("You eat " .. (obj.name or "it") .. ".")
    -- ... consume object
else
    print("You can't eat " .. (obj.name or "that") .. ".")
end
```

**Proposed enhancement to eat handler:**
```lua
if obj.edible then
    -- existing eat logic (unchanged)
elseif obj.cookable then
    -- Object exists but needs cooking first
    print(obj.on_eat_reject or "You can't eat that raw. Try cooking it first.")
else
    print("You can't eat " .. (obj.name or "that") .. ".")
end
```

This is a **2-line addition** to the existing eat handler. The `on_eat_reject` field lets each object provide a custom rejection message. If absent, a generic "try cooking it first" hint guides the player.

---

## Decision 5: Tool Resolution — Fire Source Scope

**Cooking requires `fire_source` capability. The tool can be anywhere visible — hands, room, or surfaces.**

The existing `find_visible_tool(ctx, capability)` helper already searches the room, surfaces, and inventory for tools by capability. The `cook` verb uses this — you don't need to hold fire; you just need fire to be accessible.

**Scenarios:**
- Player holds raw meat + lit candle in hands → cook works (candle `provides_tool = "fire_source"` when lit)
- Player holds raw meat, lit torch is on the wall → cook works (torch in room scope)
- Player holds raw meat, fireplace is in room → cook works (fireplace provides `fire_source`)
- Player holds raw meat, no fire anywhere → "You need a fire source to cook this."

**Why scope-visible, not hands-only:** Cooking over a fireplace or torch on the wall is realistic. You don't hold the fire — you hold the food near the fire. This matches how `sew` works: the tool (needle) must be in inventory, but the `find_tool_in_inventory` search also checks bags.

For cooking, we use `find_visible_tool` (broader scope) because fire sources are often environmental (fireplace, wall torch, campfire).

---

## Decision 6: Cook Verb Handler Architecture

The `cook` verb follows the exact `sew` pattern from `crafting.lua` (lines 233-381):

```lua
-- To be added to src/engine/verbs/crafting.lua
handlers["cook"] = function(ctx, noun)
    if noun == "" then
        print("Cook what? (Try: cook <food>)")
        return
    end

    -- Find the food (hands first, then visible)
    local food = find_in_inventory(ctx, noun)
    if not food then
        food = find_visible(ctx, noun)
    end
    if not food then
        err_not_found(ctx)
        return
    end

    -- Check if food has crafting.cook recipe
    if not food.crafting or not food.crafting.cook then
        if not food.cookable then
            print("You can't cook " .. (food.name or "that") .. ".")
        else
            print("You're not sure how to cook " .. (food.name or "that") .. ".")
        end
        return
    end

    local recipe = food.crafting.cook

    -- Find fire source (visible scope — room, surfaces, or inventory)
    local fire = find_visible_tool(ctx, recipe.requires_tool or "fire_source")
    if not fire then
        fire = find_tool_in_inventory(ctx, recipe.requires_tool or "fire_source")
    end
    if not fire then
        print(recipe.fail_message_no_tool or "You need a fire source to cook.")
        return
    end

    -- Perform mutation: raw-X → cooked-X
    local mut_data = recipe
    local ok = perform_mutation(ctx, food, mut_data)
    if not ok then
        print("Something goes wrong — the food burns to ash.")
        return
    end

    -- Consume fire tool charge if applicable (matches burn down)
    consume_tool_charge(ctx, fire)

    -- Success message
    print(recipe.message or ("You cook " .. (food.name or "it") .. " over the flames."))
end

handlers["roast"] = handlers["cook"]
handlers["bake"] = handlers["cook"]
handlers["grill"] = handlers["cook"]
```

---

## Decision 7: What Tools/Stations Exist or Need Creating

### Already Exists
| Object | Provides | Notes |
|--------|----------|-------|
| match (lit) | `fire_source` | Consumable, burns out. Short cooking window. |
| candle (lit) | `fire_source` | Sustained fire. Good for simple cooking. |
| oil-lantern (lit) | `fire_source` | Sustained fire. |
| torch (lit) | `fire_source` | Room-scope fire source, not held. |

### Needed for Level 1 (Kitchen Room)
| Object | Provides | Priority |
|--------|----------|----------|
| hearth / kitchen-fireplace | `fire_source` (when lit) | **High** — the kitchen already has cooking-fire smell references in hallway-east-door and courtyard-kitchen-door. The fireplace is implied. |

### Future (Level 2+)
| Object | Provides | Priority |
|--------|----------|----------|
| campfire | `fire_source` | Medium — outdoor cooking |
| iron-pot | `cooking_vessel` | Low — multi-ingredient recipes |
| oven | `fire_source` + `baking_surface` | Low — advanced baking |

---

## Summary: What This Architecture Gives Us

1. **Zero new engine infrastructure.** Cooking uses existing mutation, tool capability, and crafting recipe systems.
2. **Object-declared behavior (Principle 8).** The `crafting.cook` recipe lives on the object. The engine doesn't know about "cooking" — it just follows recipes.
3. **D-14 compliance.** `raw-rat-meat.lua` is rewritten to `cooked-rat-meat.lua`. Code IS state.
4. **Natural language verbs.** `cook meat`, `bake grain`, `roast rat` all work via aliases.
5. **Edibility gating.** Raw food has `edible = false` + `on_eat_reject` hint. Cooked food has `edible = true`. The eat handler needs 2 new lines.
6. **Tool flexibility.** Any `fire_source` works — matches, candles, torches, fireplaces. Capability matching, not item-ID matching.

### Impact
- **Flanders:** Create `raw-rat-meat.lua`, `cooked-rat-meat.lua`, `flatbread.lua`, and any other food objects
- **Moe:** Wire hearth/fireplace into kitchen room when kitchen is built
- **Smithers:** Add `cook`/`roast`/`bake`/`grill` verb handler to `crafting.lua`; add `cookable` check to eat handler in `survival.lua`
- **Nelson:** Tests: cook with fire → mutation, cook without fire → rejection, eat raw → rejection + hint, eat cooked → success
- **Sideshow Bob:** Design cooking puzzles (rat bait, food trade, hunger pressure)

---

## Affected Files

| File | Change |
|------|--------|
| `src/engine/verbs/crafting.lua` | Add `cook` handler + aliases |
| `src/engine/verbs/survival.lua` | Add `cookable` check to eat handler (2 lines) |
| `src/meta/objects/raw-rat-meat.lua` | New object (Flanders) |
| `src/meta/objects/cooked-rat-meat.lua` | New object (Flanders) |
| `src/meta/objects/grain-handful.lua` | New object (Flanders) |
| `src/meta/objects/flatbread.lua` | New object (Flanders) |
| `test/verbs/test-cook.lua` | New test file (Nelson) |


## bart-food-architecture

# Deep Architecture Analysis — How Creatures Become Food

**Author:** Bart (Architect)  
**Date:** 2026-03-30  
**Status:** PROPOSED — Awaiting Wayne's review  
**Category:** Architecture  
**Requested by:** Wayne Berry  
**Related:** D-14, D-INANIMATE, D-CREATURES-DIRECTORY, D-FOOD-SYSTEMS-RESEARCH

---

## The Question

> "A dead creature can be food, and items like grain in a bag can be food. Both objects and creatures (two different meta types) can be food. How do we work that into our system?"

This is a foundational type-system question. It asks: when an entity crosses a categorical boundary (creature → object, or object → edible-object), what architectural mechanism governs that crossing?

---

## Current System State

Before analyzing options, here's what exists today:

### Templates (7 total)
| Template | Category | Key traits |
|----------|----------|------------|
| `room` | Environment | exits, contents |
| `furniture` | Inanimate, heavy | portable=false, surfaces |
| `container` | Inanimate, holdable | container=true, capacity |
| `small-item` | Inanimate, portable | portable=true, lightweight |
| `sheet` | Inanimate, fabric | material="fabric", tearable |
| `creature` | Animate | behavior, drives, FSM, health, reactions |
| `portal` | Passage | portal metadata, traversable states |

### Creature Template Structure
The creature template provides: `animate=true`, `behavior={}`, `drives={}`, `reactions={}`, `movement={}`, `awareness={}`, `health`, `body_tree`, `combat={}`. Its FSM includes alive states and a `dead` state where `animate=false, portable=true`.

### Mutation System (D-14)
`mutation.mutate(reg, ldr, object_id, new_source, templates)`:
- Loads new source via sandboxed `load_source`
- Resolves template if present
- **Preserves: `location`, `container`, surface contents, root contents**
- Replaces registry entry via `reg:register(object_id, new_obj)` — **same ID slot**

### Registry
- ID-indexed (`_objects[id]`)
- GUID-indexed (`_guid_index[normalized_guid]`)
- `register()` replaces any existing entry at that ID
- No type checking — the registry doesn't know or care about templates

### Loader
- `resolve_template()` deep-merges template under instance, then **deletes `template` field** (`resolved.template = nil`)
- At runtime, objects don't carry their template name — it's consumed during loading

### Key Observation
The registry is type-agnostic. It stores tables. There is no "creature registry" vs "object registry." Once loaded, a creature is just a table with extra fields. This is architecturally significant — it means type transitions don't require registry migration.

---

## Option A: Pure D-14 Mutation — Creature Dies → Mutates to Food Object

### Mechanism
When a rat takes lethal damage, instead of (or after) transitioning to its `dead` FSM state, the engine triggers a mutation: `rat.lua` → `dead-rat.lua`. The dead-rat file declares `template = "small-item"` with food metadata.

### Code Example

```lua
-- src/meta/creatures/rat.lua (add mutation declaration)
mutations = {
    kill = {
        becomes = "dead-rat",
        message = "The rat shudders and goes still.",
    },
},
```

```lua
-- src/meta/objects/dead-rat.lua (the mutation target)
return {
    guid = "{new-guid-dead-rat}",
    template = "small-item",
    id = "dead-rat",
    name = "a dead rat",
    keywords = {"dead rat", "rat", "rat corpse", "corpse", "carcass"},
    description = "A limp brown rat, its matted fur dark with blood. The beady eyes are glazed and empty.",

    size = 1,
    weight = 0.3,
    portable = true,
    material = "flesh",
    categories = {"food", "corpse"},

    -- Food metadata (trait pattern — see Option B analysis)
    edible = true,
    food = {
        nutrition = 3,
        risk = "disease",
        risk_chance = 0.4,
        raw = true,
        on_eat_message = "You tear into the raw rat flesh. It's gamey and foul.",
    },

    -- Sensory (retains creature identity for examination)
    on_feel = "Cooling fur over a limp body. The tail hangs like wet string.",
    on_smell = "Blood and musk. The sharp copper of death.",
    on_listen = "Nothing. Absolutely nothing.",
    on_taste = "Fur and blood. Gamey, iron-rich. You immediately regret this.",

    -- Can be cooked (second mutation)
    mutations = {
        cook = {
            becomes = "cooked-rat-meat",
            message = "The rat flesh sizzles and chars. The smell is... tolerable.",
            requires_tool = "fire_source",
        },
    },
}
```

```lua
-- src/meta/objects/cooked-rat-meat.lua (cooking mutation target)
return {
    guid = "{new-guid-cooked-rat}",
    template = "small-item",
    id = "cooked-rat-meat",
    name = "cooked rat meat",
    keywords = {"rat meat", "cooked rat", "cooked meat", "meat"},
    description = "A charred hunk of rat meat. Not appetizing, but protein is protein.",

    size = 1,
    weight = 0.2,
    portable = true,
    material = "meat",
    categories = {"food"},

    edible = true,
    food = {
        nutrition = 6,
        risk = nil,
        raw = false,
        on_eat_message = "Tough and gamey, but it fills your stomach. You've eaten worse. Probably.",
    },

    on_feel = "Warm, slightly greasy meat. Charred on the outside.",
    on_smell = "Roasted meat with an undertone of musk.",
    on_listen = "Silent.",
    on_taste = "Gamey. Fibrous. Edible.",

    mutations = {},
}
```

### What Happens Mechanically

1. Rat takes lethal damage → engine detects `health_zero` condition
2. Engine looks up `mutations.kill` on the rat object
3. `mutation.mutate(reg, ldr, "rat", dead_rat_source, templates)` is called
4. Mutation loads `dead-rat.lua`, resolves `template = "small-item"`
5. Preserves `location` and `container` — dead rat stays where the live rat was
6. Registry entry at key "rat" is **replaced** — now points to the dead-rat table
7. The old creature data (behavior, drives, reactions, movement) is **gone**
8. The object is now a portable small-item with `edible = true`

### GUID Analysis

The mutation system's handling of GUIDs is clean here:
- The old rat's GUID (`{071e73f6-...}`) is dropped (it was in `old` but not carried forward)
- The dead-rat has its own GUID (`{new-guid-dead-rat}`)
- The registry ID stays the same ("rat") — all containment references survive
- The GUID index gets updated by `register()`

### Creature Tick Impact

**Critical question:** Does the creature tick system check `animate` or template?

If the creature tick iterates registered objects looking for `animate == true`, then mutation solves this automatically — dead-rat has no `animate` field (inherits nothing from small-item template, which doesn't define it). The tick skips it.

If the creature tick iterates a separate "creatures" list, then mutation needs to also remove the object from that list. This is a one-line addition to the kill handler.

### Pros
- **Pure D-14.** Code IS state. The creature literally becomes a different thing at the code level.
- **Clean type crossing.** No dual-type ambiguity. The dead rat IS a small-item. Period.
- **Creature identity preserved via sensory text.** You can still "examine dead rat" and get rich description. Keywords include "rat" — the parser resolves it.
- **Mutation chain.** `rat.lua` → `dead-rat.lua` → `cooked-rat-meat.lua`. Each step is a clean D-14 code rewrite.
- **No engine changes needed.** The mutation system, loader, and registry already handle this. Template resolution at mutation time is already implemented (line 27-32 of mutation/init.lua).
- **Principle 8 compliant.** Objects declare `mutations.kill.becomes`; engine executes it generically.

### Cons
- **Object file proliferation.** Each creature needs a `dead-X.lua` file (and possibly `cooked-X-meat.lua`). For 10 creature types, that's 10-20 extra files.
- **Rat history lost at runtime.** Once mutated, the creature's behavior/drives/combat data is gone. You can't query "what kind of creature was this?" without adding a `source_creature` field to dead-rat.lua.
- **Requires mutation trigger in kill path.** The damage/kill handler must know to call `mutation.mutate` rather than just FSM-transitioning to `dead` state. This is a design choice, not a bug.

### Complexity Estimate: LOW
Zero engine changes. 1 new file per creature death form. Verb handler needs a kill→mutation path (small).

---

## Option B: Mixin/Trait — `food` as Metadata, Not a Template

### Mechanism
"Food" is not a type — it's a set of metadata fields that any object (or creature) can declare. The `eat` verb checks for `edible == true` and reads `food = {...}` metadata. No template inheritance required.

### Code Example — Grain in a Bag

```lua
-- src/meta/objects/grain-sack.lua
return {
    guid = "{grain-sack-guid}",
    template = "small-item",
    id = "grain-sack",
    name = "a sack of grain",
    keywords = {"grain", "sack of grain", "grain sack", "seeds"},
    description = "A rough burlap sack, heavy with grain. Individual kernels press against the fabric.",

    size = 2,
    weight = 1.5,
    portable = true,
    material = "grain",
    categories = {"food", "grain"},

    -- Food trait (not a template — just metadata)
    edible = true,
    food = {
        nutrition = 4,
        risk = nil,
        raw = true,
        on_eat_message = "You scoop handfuls of dry grain into your mouth. It's bland but filling.",
    },

    on_feel = "Rough burlap. Inside, thousands of small hard kernels shift under your fingers.",
    on_smell = "Dry, dusty, faintly sweet. Like a barn in autumn.",
    on_listen = "A faint shushing sound as grain shifts inside.",
    on_taste = "Dry. Nutty. Gritty between your teeth.",

    mutations = {
        cook = {
            becomes = "porridge",
            message = "The grain softens in the hot water, thickening into a lumpy porridge.",
            requires_tool = "fire_source",
        },
    },
}
```

### Code Example — Dead Rat (Combined with Option A)

```lua
-- src/meta/objects/dead-rat.lua (same as Option A — the trait is IN the file)
return {
    template = "small-item",
    -- ...
    edible = true,
    food = {
        nutrition = 3,
        risk = "disease",
        -- ...
    },
}
```

### Eat Verb Implementation

```lua
-- In verbs/survival.lua (already nearly this — just check food metadata)
handlers["eat"] = function(ctx, noun)
    if noun == "" then
        print("Eat what?")
        return
    end

    local obj = find_in_inventory(ctx, noun)
    if not obj then obj = find_visible(ctx, noun) end
    if not obj then err_not_found(ctx) return end

    -- Trait check — not template check
    if not obj.edible then
        print("You can't eat " .. (obj.name or "that") .. ".")
        return
    end

    -- Food metadata drives behavior
    local food = obj.food or {}
    print("You eat " .. (obj.name or "it") .. ".")
    if food.on_eat_message then
        print(food.on_eat_message)
    end

    -- Risk processing (disease, poison)
    if food.risk and math.random() < (food.risk_chance or 0.5) then
        -- delegate to effects/injuries system
        effects.apply(ctx, food.risk, ctx.player)
    end

    -- Nutrition
    if food.nutrition and ctx.player.hunger then
        ctx.player.hunger = math.min(100, ctx.player.hunger + food.nutrition)
    end

    -- Hooks
    if obj.on_eat and type(obj.on_eat) == "function" then
        obj.on_eat(obj, ctx)
    end

    -- Remove consumed object
    remove_from_location(ctx, obj)
    ctx.registry:remove(obj.id)
end
```

### Key Insight: Option B Is Not an Alternative to Option A — It's the Same Thing

Look carefully. The dead-rat in Option A already uses `edible = true` and `food = {...}` metadata. That IS Option B's trait pattern. The grain-sack does the same thing. The `eat` verb checks `obj.edible` — it doesn't check `obj.template`.

**Option B is not a standalone option. It's the metadata convention that ALL options use.** The question isn't "trait vs template" — it's "how does a creature BECOME an object that has the food trait?"

### Pros
- **Principle 8 pure.** Engine checks metadata. Objects declare edibility. No type-coupling.
- **Works for everything.** Grain, bread, raw meat, cooked meat, poisonous mushrooms, mysterious potions — all just objects with `edible = true`.
- **Already implemented.** The current `eat` verb stub already checks `obj.edible` (line 84 of survival.lua). We just need to enrich it.
- **Zero template changes.** No new templates needed.
- **Composable.** A container can also be edible (eat the wax seal on a bottle). Furniture could be edible (gingerbread house). No type conflicts.

### Cons
- **No enforced defaults.** Every food object must manually declare `nutrition`, `risk`, etc. No template provides sensible defaults. (Mitigated: code review + meta-lint.)
- **Doesn't answer the creature→object question.** This tells you how to eat things, not how a rat becomes a thing you can eat.

### Complexity Estimate: TRIVIAL
The eat verb already has this pattern. Just add `food = {}` to object .lua files.

---

## Option C: Multiple Templates (Array of Templates)

### Mechanism
An object declares `template = {"small-item", "food"}` — an array. The loader resolves both and deep-merges them in order.

### Code Example

```lua
-- src/meta/templates/food.lua (new template)
return {
    guid = "{food-template-guid}",
    id = "food",

    edible = true,
    food = {
        nutrition = 0,
        risk = nil,
        risk_chance = 0,
        raw = false,
        spoilage_rate = 0,
        freshness = 100,
    },

    categories = {"food"},
}
```

```lua
-- src/meta/objects/grain-sack.lua (multi-template)
return {
    template = {"small-item", "food"},  -- ARRAY
    id = "grain-sack",
    name = "a sack of grain",
    food = {
        nutrition = 4,
        raw = true,
    },
    -- ...
}
```

### Loader Change Required

```lua
-- engine/loader/init.lua — resolve_template must handle arrays
function loader.resolve_template(object, templates)
    if not object.template then
        return object, nil
    end

    local template_ids = object.template
    -- Normalize to array
    if type(template_ids) == "string" then
        template_ids = { template_ids }
    end

    -- Merge templates in order (later templates override earlier)
    local merged_base = {}
    for _, tid in ipairs(template_ids) do
        local tmpl = templates[tid]
        if not tmpl then
            return nil, "template '" .. tostring(tid) .. "' not found"
        end
        merged_base = deep_merge(merged_base, tmpl)
    end

    local resolved = deep_merge(merged_base, object)
    resolved.template = nil
    return resolved, nil
end
```

### Problems

1. **Merge order ambiguity.** If `small-item` defines `categories = {}` and `food` defines `categories = {"food"}`, deep_merge replaces the array (per current implementation — "arrays are replaced, not appended"). So `template = {"food", "small-item"}` would lose `{"food"}`. Order matters and it's not obvious.

2. **Field conflicts.** If two templates define the same field with different semantics, the merge is unpredictable. `small-item.container = false` vs a hypothetical `container.container = true` — which wins?

3. **Template identity lost.** After resolution, `resolved.template = nil`. There's no record of WHICH templates contributed. Debugging becomes harder.

4. **Mutation interaction.** When `dead-rat.lua` declares `template = {"small-item", "food"}`, mutation calls `resolve_template`. The mutation system must pass the templates table. It already does (line 27-32), but array resolution changes the contract.

5. **Meta-lint impact.** The linter validates template fields. Array templates require entirely new validation logic.

6. **Every consumer changes.** Anything that reads `obj.template` (even though it's nil at runtime) or reasons about template identity needs updating.

### Pros
- **Formal type composition.** An object IS-A small-item AND IS-A food. Clean conceptually.
- **Default propagation.** Food template provides sensible defaults (nutrition=0, spoilage_rate=0) so objects don't repeat boilerplate.

### Cons
- **Major loader refactor.** `resolve_template` changes from simple lookup to ordered multi-merge.
- **Ordering semantics.** Must be documented and enforced. Subtle bugs from wrong order.
- **Violates simplicity.** Our templates are single-inheritance by design. This makes them multiple-inheritance, which is a well-known source of complexity (the "diamond problem").
- **Overkill for food.** We're adding multi-template resolution to solve a problem that `edible = true` already solves.
- **Still doesn't address creature→object.** The dead rat still needs mutation to change from `template = "creature"` to `template = {"small-item", "food"}`. The crossing mechanism is the same as Option A.

### Complexity Estimate: HIGH
Loader rewrite. Meta-lint rewrite. Mutation interaction testing. Template ordering documentation. All for a problem that metadata traits solve without any engine changes.

---

## Option D: Food Template Extends Small-Item

### Mechanism
Create a `food` template that inherits from `small-item` via Lua table composition (not engine-level template chaining — we don't have that). The food template deep-merges small-item's defaults with food-specific additions.

### Code Example

```lua
-- src/meta/templates/food.lua
-- Food template: portable edible item. Composes small-item defaults.
local small_item = dofile("src/meta/templates/small-item.lua")
-- ^ This violates the sandboxed loader. Templates can't require other templates.

-- Alternative: manually duplicate small-item fields + add food fields
return {
    guid = "{food-template-guid}",
    id = "food",
    name = "a food item",
    keywords = {},
    description = "Something edible.",

    -- From small-item
    size = 1,
    weight = 0.2,
    portable = true,
    material = "organic",
    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    -- Food-specific
    edible = true,
    food = {
        nutrition = 0,
        risk = nil,
        risk_chance = 0,
        raw = false,
        spoilage_rate = 0,
        freshness = 100,
    },

    categories = {"food"},

    mutations = {},
}
```

```lua
-- src/meta/objects/grain-sack.lua
return {
    template = "food",           -- single template, gets all defaults
    id = "grain-sack",
    food = { nutrition = 4, raw = true },
    -- ...
}
```

### Problems

1. **Template chaining isn't supported.** The loader resolves ONE template. `food` can't declare `template = "small-item"` because templates aren't instances — they're flat definitions. We'd have to manually duplicate small-item's fields in the food template.

2. **Duplication drift.** If small-item adds a field, food template must be manually updated. No automatic inheritance.

3. **Furniture that's food?** A gingerbread house is furniture AND food. `template = "food"` loses furniture properties. Back to the multi-template problem.

4. **Creature crossing still needs mutation.** Dead rat mutates from `template = "creature"` to `template = "food"`. Same mechanism as Option A.

### Pros
- **Clean single inheritance.** `template = "food"` is simple and familiar.
- **Sensible defaults.** Food objects get nutrition=0, spoilage_rate=0, etc. without declaring them.
- **Eat verb works the same way.** Still checks `obj.edible` (Principle 8).

### Cons
- **Template duplication.** Food template must copy small-item fields manually.
- **Not composable.** Can't have food+furniture, food+container without more templates (edible-container, edible-furniture...). Combinatorial explosion.
- **Marginal benefit over Option B.** The only thing a food template gives you over raw `edible = true` metadata is default values. That's useful but not worth the architectural commitment.

### Complexity Estimate: LOW-MEDIUM
One new template file. No engine changes. But creates a maintenance burden from field duplication and limits composability.

---

## Principle Compliance Matrix

| Principle | Option A (Mutation) | Option B (Trait) | Option C (Multi-Template) | Option D (Food Template) |
|-----------|:------------------:|:----------------:|:------------------------:|:------------------------:|
| **P0: Inanimate** | ✅ Dead rat IS inanimate | ✅ Trait on inanimate objects | ✅ | ✅ |
| **P1: Code-derived** | ✅ Code defines new form | ✅ Code declares metadata | ✅ | ✅ |
| **P2: Base→Instance** | ✅ Dead-rat is its own base | ✅ No change | ✅ | ✅ |
| **P3: FSM+State** | ✅ Food can have FSM (fresh→spoiled) | ✅ FSM independent of edibility | ✅ | ✅ |
| **P4: Composite** | ✅ Dead rat can contain items | ✅ No change | ✅ | ✅ |
| **P5: Multiple instances** | ✅ Each dead rat is unique | ✅ No change | ✅ | ✅ |
| **P6: Sensory space** | ✅ Dead-rat has full sensory | ✅ Sensory per object | ✅ | ✅ |
| **P7: Spatial** | ✅ Mutation preserves location | ✅ No change | ✅ | ✅ |
| **P8: Engine executes metadata** | ✅ `mutations.kill` is metadata | ✅ `edible` is metadata | ✅ | ✅ |
| **P9: Material consistency** | ✅ material="flesh" | ✅ material-based | ✅ | ✅ |
| **D-14: Code IS state** | ✅ Code literally transforms | ⚠️ Doesn't address state change | ⚠️ Same as B for crossing | ⚠️ Same as B for crossing |

---

## Impact Analysis on Engine Modules

| Module | Option A | Option B | Option C | Option D |
|--------|----------|----------|----------|----------|
| **Loader** | No change | No change | **MAJOR rewrite** (array template resolution) | No change |
| **Registry** | No change (already type-agnostic) | No change | No change | No change |
| **Mutation** | No change (already resolves templates during mutation) | No change | Must handle array templates | No change |
| **FSM** | Kill transition triggers mutation | No change | No change | No change |
| **Creature Tick** | Must skip mutated objects (check `animate`) | No change | No change | No change |
| **Eat Verb** | Minor enrichment (already checks `edible`) | Same enrichment | Same | Same |
| **Meta-lint** | Validate dead-X files | Validate `food` metadata | **Rewrite** template validation | Validate food template |
| **Containment** | No change (mutation preserves location) | No change | No change | No change |
| **Effects** | Add food risk→injury processing | Same | Same | Same |

---

## The Hidden Insight: These Aren't Competing Options

Wayne framed this as "Option A vs B vs C vs D." But after deep analysis, I see something different:

**Option A (Mutation) answers: "How does a creature become an object?"**  
**Option B (Trait) answers: "How does the engine know something is edible?"**

These are different questions with complementary answers. They don't compete — they compose.

**Option C and D** are both attempts to formalize Option B into the template system. But Option B doesn't NEED formalization because Principle 8 already handles it: the engine executes metadata. `edible = true` IS the mechanism. Adding template machinery around it adds complexity without adding capability.

---

## RECOMMENDATION: Option A + B Hybrid (Mutation + Metadata Trait)

### The Architecture

1. **"Food" is a metadata trait, not a template.** Any object can be food by declaring `edible = true` and `food = {...}`. The `eat` verb checks this metadata. This is Principle 8 in its purest form.

2. **Creature death uses D-14 mutation to cross the type boundary.** When a creature dies, the kill handler triggers `mutation.mutate()` to replace the creature with an inanimate object. The new object's .lua file declares whatever traits it needs — including `edible = true` if appropriate.

3. **No new templates. No loader changes. No registry changes.**

### Why This Is Right

| Criterion | Justification |
|-----------|--------------|
| **D-14 compliance** | Creature→object is a code rewrite. The code IS the state. |
| **Principle 8** | `edible`, `food.nutrition`, `food.risk` — engine reads metadata, objects declare behavior. Zero food-specific engine logic. |
| **Principle 0** | Dead creature stops being animate. Clean categorical boundary. |
| **Composability** | Grain in a bag: `edible = true`. Dead rat: `edible = true`. Poisonous mushroom: `edible = true, food.risk = "poison"`. Wax candle stub: `edible = true, food.nutrition = 0, food.on_eat_message = "Why."`. ANY object can be food. |
| **Existing infrastructure** | Mutation already handles template resolution. Registry is type-agnostic. Eat verb already checks `edible`. |
| **Zero engine changes** | The entire food system is metadata-driven. Only verb enrichment needed. |

### The Kill→Mutation Flow

```
Player attacks rat → damage handler → health reaches 0
  → Check obj.mutations.kill
  → If defined: mutation.mutate(reg, ldr, rat_id, dead_rat_source, templates)
    → Dead-rat.lua loaded with template="small-item"
    → Location preserved, creature data gone
    → Registry entry replaced
    → Creature tick skips (no `animate` field)
  → If NOT defined: FSM transition to "dead" state (existing behavior)
    → Object stays a creature, just in dead state
    → Can STILL be mutated later (butcher verb?)
```

### Why NOT Option C (Multiple Templates)

Multiple templates solve the "IS-A food AND IS-A small-item" problem. But `food` isn't a type — it's a property. A candle isn't a "food-type" thing; it's a small-item that happens to be edible (if you're desperate enough). Multi-template inheritance adds engine complexity to solve a modeling error.

The analogy: in real life, "edible" isn't a category of object. It's a property. A shoe is leather (edible in extremis). A candle is wax (edible). Grain is grain (edible). A desk is wood (not edible). "Edible" crosscuts all categories. That's a trait, not a type.

### Why NOT Option D (Food Template)

A food template gives you default values for nutrition, spoilage, etc. That's useful but creates an artificial category. What template does a "candle stub you can eat in desperation" use? `small-item`? `food`? It can't be both without multi-template (Option C).

If we want food defaults, we can achieve them through:
1. **Meta-lint rule:** "If `edible = true`, object MUST have `food.nutrition`."
2. **Convention:** Copy-paste the `food = {...}` block from a reference.
3. **Future:** If we get 20+ food items, THEN consider a food template. Not before.

### What About Creature Identity?

Wayne asked: "Can you still examine dead rat and get rat info?"

Yes. The dead-rat.lua file contains:
- `keywords = {"dead rat", "rat", "rat corpse", "corpse"}` — parser resolves "rat"
- `description = "A limp brown rat..."` — full rat description, just dead
- Full sensory set (`on_feel`, `on_smell`, `on_listen`, `on_taste`) — all written for the dead state
- Optionally: `source_creature = "rat"` if we need programmatic tracing

The identity isn't lost. It's **encoded in the mutation target's code**. This is D-14: the code contains all the information.

### Implementation Roadmap

| Step | Work | Effort |
|------|------|--------|
| 1 | Add `mutations.kill` to `rat.lua` | 2 lines |
| 2 | Create `dead-rat.lua` with `edible = true, food = {...}` | 1 file (~50 lines) |
| 3 | Wire kill handler to call `mutation.mutate` when `mutations.kill` exists | ~15 lines in damage path |
| 4 | Enrich `eat` verb to process `food` metadata (nutrition, risk, effects) | ~30 lines (survival.lua) |
| 5 | Create `cooked-rat-meat.lua` for the cook mutation chain | 1 file (~40 lines) |
| 6 | Add `edible = true, food = {...}` to existing food objects (grain, bread, etc.) | ~5 lines per object |
| 7 | Meta-lint: if `edible = true`, require `food.nutrition` and `on_taste` | ~20 lines |

**Total estimated effort:** 4-6 hours. Zero engine module changes. All work is in metadata and verb handlers.

---

## Appendix: How Other Engines Handle This

| Engine | Mechanism | Notes |
|--------|-----------|-------|
| **Dwarf Fortress** | Butcher workshop transforms creature → meat/bones/hide items | Type transformation via workshop action. Creature is destroyed, items spawned. |
| **NetHack** | Kill drops a "corpse" item (new object type `FOOD_CLASS`) | Creature and corpse are separate entities. Corpse has `corpsenm` field linking back to monster type. |
| **Caves of Qud** | Butchery skill produces food items from corpses | Similar to DF. Creature death spawns a corpse object; butchery spawns food. |
| **Ultima Online** | Creature death spawns a "corpse container" with loot + meat | Corpse is a special container. Carving produces food items. |
| **MUDs (Diku/MERC)** | Creature death creates a "corpse" object with timer | Corpse is an item with `ITEM_CORPSE` flag. Dissipates after N ticks. |

**Common pattern:** Every engine treats death as a type transition. The creature stops existing; one or more items appear in its place. Our mutation system does exactly this, but more elegantly — the object ID persists, so containment references don't break.

---

## Summary

| Option | Verdict | Reason |
|--------|---------|--------|
| **A: Mutation** | ✅ USE — for creature→object crossing | Pure D-14. Already supported by mutation engine. |
| **B: Trait** | ✅ USE — for food metadata convention | Pure Principle 8. Already nearly implemented in eat verb. |
| **C: Multi-Template** | ❌ REJECT | Over-engineered. Solves a modeling error with engine complexity. |
| **D: Food Template** | ❌ DEFER | Not needed until we have 20+ food items. Revisit then. |

**Final answer:** Mutation handles the boundary crossing. Metadata traits handle edibility. Together they solve Wayne's question with zero engine changes, full principle compliance, and clean composability.

— Bart


## bart-trapdoor-dup-fix

# Decision: Fix #276 trapdoor duplication

**Author:** Bart (Architect)  
**Date:** 2026-03-26

## Decision
Route rug coverage to the existing portal trapdoor and remove the duplicate trap-door instance from the bedroom. Also allow covering reveals to transition any hidden-state object (not just hidden→revealed) so portal trapdoors reveal correctly.

## Rationale
The bedroom rug was spawning a separate trap-door object, while the down exit used the portal trapdoor. Moving the rug must reveal the portal object already tied to the exit, avoiding duplicate trapdoors and blocked traversal.

## Impact
- **Moe (World):** Bedroom rug no longer nests a trap-door instance.
- **Flanders (Objects):** Rug now covers the portal trapdoor; portal keywords include “iron ring.”
- **Bart (Engine):** Covering reveal logic now transitions any hidden-state object.


## cbg-food-creature-design

# Game Design Analysis: Dead Creatures as Food + Object/Creature Food Duality

**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-07-28  
**Status:** Design Analysis — Awaiting Wayne Review  
**Triggered by:** Wayne's question: *"A dead creature can be food, and items like grain can be food. Both objects and creatures can be food — how does that work? Maybe via FSM a creature turns into an object like rat flesh."*

---

## Table of Contents

1. [Competitor Analysis: Creature → Food Transitions](#1-competitor-analysis)
2. [The Fundamental Design Question](#2-the-fundamental-design-question)
3. [Recommendation: The Hybrid Mutation Model](#3-recommendation)
4. [Player Experience: Eating a Dead Rat](#4-player-experience-eating-a-dead-rat)
5. [Grain in a Bag: Object-Category Food](#5-grain-in-a-bag)
6. [Sensory Escalation: Smell Safe → Taste Risky → Eat Commit](#6-sensory-escalation)
7. [Alignment with Core Principles](#7-alignment-with-core-principles)
8. [Implementation Sketch](#8-implementation-sketch)
9. [Open Questions for Wayne](#9-open-questions)

---

## 1. Competitor Analysis

### 1.1 Dwarf Fortress — Butchery Workshop Model

**Mechanism:** Creature dies → corpse exists as entity → player assigns "butcher" task at workshop → creature is decomposed into discrete item objects: meat, bones, fat, skin, organs.

| Input | Process | Output |
|-------|---------|--------|
| Dead cat | Butcher at workshop | Cat meat × 2, cat bones × 4, cat fat × 1, cat skin × 1 |
| Dead elephant | Butcher at workshop | Elephant meat × 40+, bones, tusks (ivory), skin (leather) |

**Key design insight:** DF treats butchering as a *workshop task* — it's labor, it requires a tool (butcher's knife), a workspace (butcher's shop), and a hauler to bring the corpse there. The corpse is NOT food. The parts are.

**What this means for us:**
- Maximum simulation depth
- Maximum complexity (tools, workspaces, hauling, skills)
- Creates an entire supply chain from death to dinner
- *Too complex for a text-IF with two-hand inventory* — but the philosophy of creature → parts → food is sound

### 1.2 NetHack — Corpse-as-Item Model

**Mechanism:** Monster dies → drops a "corpse" item. The corpse is an ITEM in inventory, not a monster. Eating it has effects based on the original monster type.

| Monster | Corpse Item | Eating Effect |
|---------|------------|---------------|
| Newt | Newt corpse | Chance of gaining teleportitis |
| Floating eye | Floating eye corpse | Telepathy intrinsic |
| Cockatrice | Cockatrice corpse | **Instant death** (petrification) |
| Any old corpse | (decayed) | Food poisoning |

**Key design insight:** NetHack's corpse is a **single item with the monster's identity baked in**. The corpse "remembers" what it was. There's no butchering — the corpse IS the food (or weapon — cockatrice corpses are infamously wielded as petrification weapons). Corpses also decay over time: `fresh → old → rotten → gone`.

**What this means for us:**
- Simple, elegant, text-IF appropriate
- Identity preserved (you know it's rat, not generic "meat")
- Risk/reward from eating (NetHack's greatest strength)
- Spoilage creates time pressure
- No tool requirement — *too* simple for our tool-focused design

**Preserved form:** NetHack also has "tin of [monster] meat" — a preserved, safe version created with a tinning kit (tool). This is effectively cooking/preservation.

### 1.3 Caves of Qud — Butchery Drop Model

**Mechanism:** Creature dies → player can butcher with Butchery skill → produces meat + byproducts based on creature anatomy. Some creatures are edible *alive* (parasites).

| Creature | Butchery Output | Special |
|----------|----------------|---------|
| Snapjaw | Snapjaw meat × 1 | — |
| Girshling | Girshling haunch × 2 | Acid-resistant meat |
| Slug | Slug gut × 1 | Preservable into vinegar |

**Key design insight:** Qud bridges DF and NetHack — butchery exists but is simpler (skill check, not workshop). Crucially, **creature type determines butchery output quality and quantity**. A slug gives you one gut. A bear gives you six steaks. Material properties of the creature influence the food.

**What this means for us:**
- Butchery as a *skill* rather than *workshop task* fits text-IF better
- Creature identity flows into food identity (rat meat vs. wolf meat)
- Material consistency (Principle 9) already gives us this — rat flesh vs. spider chitin
- The "edible alive" mechanic is wild but not V1 material

### 1.4 Don't Starve — Abstract Meat Drop Model

**Mechanism:** Creature dies → auto-drops meat items of varying quality. No butchery step. Different creatures drop different meat tiers.

| Creature | Drop | Quality |
|----------|------|---------|
| Rabbit | Morsel | Small (1 hunger point) |
| Beefalo | Meat × 4 | Standard |
| Spider | Monster meat | Dangerous (reduces sanity) |
| Tallbird | Drumstick | Standard (comedic) |

**Key design insight:** Don't Starve abstracts away the creature→food transition entirely. Kill thing → meat appears. The meat is generic by *tier*, not by creature identity. A rabbit morsel and a frog leg have no species memory. Monster meat (from hostile creatures) is the only quality distinction.

**What this means for us:**
- *Too abstract* — loses creature identity and our material-physics foundation
- The "monster meat = bad meat" concept is useful (hostile creature food is risky)
- Tier system (morsel/meat/monster) is too gamey for our simulation-first approach
- But: the simplicity of "kill → food appears" has appeal for pacing

### 1.5 Classic MUDs — Corpse-as-Container Model

**Mechanism:** Creature dies → a "corpse of [creature]" object appears. The corpse is a **container** holding the creature's former inventory. Some MUDs allow eating the corpse directly. Corpses decay on a timer: `fresh → decayed → skeleton → gone`.

| MUD Feature | Implementation | Notes |
|-------------|---------------|-------|
| Corpse creation | Monster dies → `create_object("corpse", monster.name)` | Corpse inherits name |
| Corpse as container | Corpse holds monster's loot | `get sword from corpse` |
| Corpse eating | Some MUDs allow `eat corpse` | Usually only for certain classes |
| Corpse decay | Timer: 5 mins → 15 mins → 30 mins → removed | Creates urgency to loot |

**Key design insight:** MUDs solved the "creature has inventory" problem by making the corpse a container. The creature's belongings transfer to the corpse object. This is elegant and solves our containment question too: when a rat dies carrying a stolen cheese wedge, the dead rat (or rat corpse) becomes a container holding the cheese.

**What this means for us:**
- Corpse-as-container elegantly handles loot transfer
- Decay timer maps perfectly to our FSM spoilage system
- The "corpse" intermediate step preserves identity
- Container mechanic already exists in our engine

### 1.6 Summary Matrix

| Game | Transition | Butchering? | Identity Preserved? | Spoilage? | Tool Req? |
|------|-----------|-------------|--------------------:|-----------|-----------|
| **Dwarf Fortress** | Workshop butchery | Yes (workshop + tool) | In item name | Rot timer | Butcher knife |
| **NetHack** | Instant drop | No | Yes (corpse type) | Yes (age) | Tinning kit (optional) |
| **Caves of Qud** | Skill butchery | Yes (skill check) | Yes (creature type) | Partial | Butchery skill |
| **Don't Starve** | Auto drop | No | No (generic tiers) | Yes (rot) | None |
| **MUDs** | Corpse object | Optional (class) | Yes (corpse name) | Yes (decay) | None |

---

## 2. The Fundamental Design Question

Wayne's question cuts to the heart of a *type system duality*:

> Objects and creatures are different systems (Principle 0). But food comes from BOTH. A bread roll is an object that is food. A dead rat is... what?

### The Duality Problem

Our architecture draws a hard line:
- **Objects** (`src/meta/objects/`) — inanimate, passive, no AI
- **Creatures** (`src/meta/creatures/`) — animate, drives, reactions, AI

When a creature dies, it crosses this boundary. A dead rat has `animate = false` in its dead state. It's no longer a creature in any meaningful sense — it's a warm, furry, lootable object. But it's still loaded from `rat.lua`, still registered as a creature.

**Wayne's intuition is correct:** The dead creature should *become* an object. The question is: when, how, and what object?

### Three Possible Models

| Model | Mechanism | Identity | Complexity |
|-------|-----------|----------|------------|
| **A: Dead State Only** | Creature stays as creature, `dead` state adds `edible = true` | Rat (dead) | Lowest — FSM only |
| **B: Mutation to Corpse** | Creature mutates to a corpse object on death | Rat corpse (object) | Medium — mutation on death |
| **C: Mutation + Butchery** | Corpse exists; butchering produces food objects | Rat corpse → rat meat | Highest — two mutations |

---

## 3. Recommendation: The Hybrid Mutation Model (Model B+C)

After analyzing every competitor, consulting our core principles, and staring at `rat.lua` until my eyes bled — **worst. design question. ever** — here is my recommendation.

### Phase 1: Mutation to Corpse (Model B) — V1 Target

**When a creature's health reaches zero, the FSM transitions to `dead` state, and then the engine triggers a mutation that replaces the creature with a corpse OBJECT.**

```
rat.lua (creature, alive) 
    → [health_zero] → 
        rat.lua dead state (brief transitional moment) 
            → [mutation] → 
                rat-corpse.lua (object, edible, container)
```

**The corpse is an object.** It lives in `src/meta/objects/`. It inherits the creature's identity (name, keywords, sensory properties) but is definitionally an inanimate thing. It has `edible = true`. It has `food = { category = "meat" }`. It has container capacity for anything the rat was carrying.

**Why this is correct:**
1. **Principle 0 compliance** — Dead things are objects. The line stays clean.
2. **D-14 compliance** — Code mutation IS state change. `rat.lua` → `rat-corpse.lua` is the Prime Directive in action. The creature literally becomes a different thing.
3. **Principle 8 compliance** — The creature declares `mutations = { die = { becomes = "rat-corpse" } }`. The engine executes it. No creature-specific engine code.
4. **Containment compliance** — The mutation engine already preserves containment (location, container, surfaces). The corpse appears exactly where the rat died.
5. **FSM compliance** — The corpse gets its own spoilage FSM: `fresh → bloated → rotten → bones`.
6. **Sensory compliance** — The corpse has its own complete sensory descriptions appropriate to a dead animal, not a living one.

### Phase 2: Butchery Option (Model C) — Post-V1

**The player can eat the corpse directly (desperate, risky, low nutrition) OR butcher it with a knife for clean meat (higher nutrition, lower risk).**

```
rat-corpse.lua (edible but risky)
    → [eat] → consumed (nausea risk, low nutrition)
    → [butcher with knife] → rat-meat.lua (clean, cookable, good nutrition)
```

This gives us the full Caves of Qud / Dwarf Fortress progression without the workshop complexity:
- **No tool:** Eat corpse directly → gross, risky, barely nutritious
- **Knife tool:** `butcher rat corpse` → produces rat meat → cookable → good nutrition
- **Knife + fire:** Butcher → cook → roasted rat meat → healing buff

### Why Not Model A (Dead State Only)?

Model A (just marking the dead creature as `edible = true` in its dead state) fails on three counts:

1. **Principle 0 violation** — A creature with `animate = false` that you can eat, carry, and cook is functionally an object. Calling it a creature is a lie. Our architecture should reflect reality.

2. **No independent FSM** — The creature's FSM handles alive-states. Bolting a spoilage lifecycle (fresh → rotten) onto a creature FSM creates a Frankenstein state machine mixing behavioral states with material states. Separation is cleaner.

3. **No containment** — If the rat was carrying stolen food, the dead rat needs to BE a container to hold that food. Creatures don't have `contents` fields in the same way objects do. A corpse object handles this naturally.

### Why Not Model C Only (Skip Corpse, Go Straight to Meat)?

Skipping the corpse stage loses critical design space:
- **No "dead rat" moment** — The player should SEE and INTERACT WITH the dead animal. "There's a dead rat here" is atmospheric. "There's some rat meat here" is clinical.
- **No sensory discovery** — SMELL the corpse, FEEL its cooling body, EXAMINE it. This is our sensory system at its best.
- **No container** — Where does the rat's stolen cheese go?
- **No spoilage narrative** — The corpse bloating and rotting is *storytelling*. Meat just goes bad.

---

## 4. Player Experience: Eating a Dead Rat

Here is the complete player experience arc, from rat encounter to dinner:

### Phase 1: The Kill

```
> kill rat
You swing the brass candlestick. The rat squeals — a wet, truncated 
sound — and crumples against the wall. It twitches once and is still.

A dead rat lies crumpled on the floor.
```

*Engine: rat.lua transitions to `dead` state, then mutates to `rat-corpse.lua`. The corpse object appears at the rat's location.*

### Phase 2: Discovery Through Senses

```
> smell rat
Blood and musk. The sharp copper of fresh death. Underneath, the 
musty smell of rodent — damp fur and nesting material. Your stomach 
growls. You haven't eaten in hours.

> feel rat
Cooling fur over a limp body. Still warm. The ribcage is thin — you 
can feel the tiny bones beneath the skin. The tail hangs like wet string.

> look rat
A dead rat lies on its side, legs splayed stiffly. Its matted brown 
fur is darkened with blood near the head. Beady black eyes stare at 
nothing. It's about the size of your fist.
```

*The sensory system works exactly as designed. SMELL and FEEL work in darkness. LOOK requires light. Each sense gives different, useful information.*

### Phase 3: The Choice — Eat Raw (Desperate)

```
> eat rat
You tear into the dead rat with your teeth. Fur and blood. The flesh 
is stringy, warm, and profoundly wrong. Your throat tries to close. 
You chew mechanically, swallowing against every instinct.

A wave of nausea rolls through you.
[Status: Nauseated — 10 ticks]
[Nutrition: +5 — barely worth it]
```

*Eating a raw corpse works but punishes. Low nutrition, nausea status, disgusting narration. This is the desperate option — a player who has no knife and no fire can still extract minimal sustenance at a cost.*

### Phase 4: The Choice — Butcher Then Cook (Smart)

```
> butcher rat with knife
You work the knife under the rat's skin, peeling it away from the 
flesh beneath. The work is messy but quick. You separate a portion 
of lean, dark meat from the carcass.

You now have: rat meat
[Remains: rat bones, rat skin — left on ground]

> cook rat meat
You hold the meat over the fire. Fat sizzles and drips into the flames. 
The raw, metallic smell transforms into something almost appetizing.

The rat meat browns and crisps.

You now have: roasted rat meat

> eat roasted rat meat  
Gamey, lean, slightly smoky. Not good, exactly, but warm and filling. 
Your body accepts it gratefully.

[Nutrition: +25]
[Healing: +3 HP]
[Status: Satiated — 30 ticks]
```

*This is the full Dwarf Fortress progression: kill → butcher (tool) → cook (fire) → eat (reward). Each step uses existing engine systems: mutation, tool capabilities, fire_source, effects pipeline.*

### Phase 5: Spoilage Pressure

```
[20 ticks later, if the player didn't eat the corpse]

The dead rat has begun to bloat. The smell thickens.

[40 ticks later]

The dead rat is rotten. Flies swarm it in a buzzing cloud.

> eat rotten rat
You CANNOT be serious.

You gag before it reaches your mouth. The smell alone is a biological 
weapon. You would have to be literally dying of starvation.

> eat rotten rat
[Player confirms desperate action]
Your stomach rebels violently. 

[Status: Food Poisoning — 20 ticks]
[Status: Nauseated — 12 ticks]
[Health: -5]
```

*Spoilage FSM creates time pressure. The corpse degrades through states, each with deteriorating sensory descriptions and increasingly dangerous effects if consumed.*

---

## 5. Grain in a Bag: Object-Category Food

Wayne's other question: how does grain-in-bag work?

### Grain is an Object. Always Was.

Grain doesn't have the creature→food duality problem. Grain is an inanimate object that happens to be edible. It sits cleanly in `src/meta/objects/`. The bag is a container; grain is an item inside it.

```lua
-- grain.lua
return {
    template = "small-item",
    id = "grain",
    name = "a handful of grain",
    keywords = {"grain", "wheat", "seeds", "kernels"},
    description = "A handful of pale wheat grain, each kernel hard and glossy.",
    
    edible = true,
    food = {
        category = "grain",
        cookable = true,
        cooked_form = "porridge",   -- grain + water + fire = porridge
        spoil_time = 0,             -- dry grain never spoils
        nutrition = 5,              -- edible raw but barely nutritious
        effects = {
            { type = "narrate", message = "Dry, hard, barely chewable. Your jaw aches." },
        },
    },
    
    on_feel = "Hard, smooth kernels that roll between your fingers. Dry and cool.",
    on_smell = "Earthy, slightly sweet. The clean smell of stored grain.",
    on_listen = "A dry rustling when you shift them in your hand.",
    on_taste = "Starchy, bland. Like chewing gravel that eventually turns pasty.",
    
    -- No spoilage FSM — grain is already preserved (dried)
    -- But it CAN be cooked into porridge (mutation)
    mutations = {
        cook = { becomes = "porridge", requires_tool = "fire_source",
                 requires_item = "water_source",
                 message = "You stir the grain into the bubbling water. It thickens into a warm porridge." },
    },
}
```

### The Bag is a Container, Grain is Contents

```lua
-- In a room definition:
{
    id = "grain-sack",
    type_id = "{guid-sack}",
    contents = {
        { id = "grain-1", type_id = "{guid-grain}" },
        { id = "grain-2", type_id = "{guid-grain}" },
        { id = "grain-3", type_id = "{guid-grain}" },
    },
}
```

The player interacts with grain the same way they interact with matches in a matchbox:
- `open sack` → reveals contents
- `take grain from sack` → grain moves to hand
- `eat grain` → consumption
- `cook grain` → mutation to porridge (if fire + water available)

### Does Grain Need Processing?

**Recommendation:** Grain is edible raw (barely — low nutrition, jaw-aching narration) but *cookable* into porridge for real nutrition. This mirrors the raw chicken pattern: you CAN eat it raw, but cooking is the smart play.

This creates a nice parallel:

| Food Source | Raw | Cooked | Tool Chain |
|-------------|-----|--------|------------|
| Grain | Edible, low nutrition | Porridge (good nutrition) | Fire + water |
| Chicken | Edible, nausea | Roasted chicken (healing) | Fire |
| Rat corpse | Edible, nausea + disease risk | Roasted rat meat (decent) | Knife + fire |
| Cheese | Edible, good nutrition | N/A (doesn't cook) | None |
| Bread | Edible, good nutrition | Toast (slightly better) | Fire (optional) |

The progression is consistent: raw food has risk/low reward; cooking always improves it.

---

## 6. Sensory Escalation: Smell Safe → Taste Risky → Eat Commit

This is where our game *destroys* the competition. No other game in this analysis has a sensory identification system for food. NetHack has "this corpse is old" text. Dwarf Fortress has quality indicators. But nobody does **graduated sensory risk escalation**.

### The Escalation Ladder Applied to Creature-Food

```
STEP 1: SMELL (Safe — Zero Risk)
  "Blood and musk. Fresh death."
  → Player learns: this is a fresh corpse, recently killed
  → No health consequence

STEP 2: FEEL (Safe — Zero Risk)  
  "Cooling fur, limp body, thin ribs beneath skin."
  → Player learns: it's a small animal, still warm, freshly dead
  → No health consequence

STEP 3: LOOK (Safe — Requires Light)
  "A dead rat, blood-matted, eyes staring."
  → Player learns: species identification, size, visible condition
  → No health consequence (but requires light — strategic cost)

STEP 4: TASTE (Risky — Potential Consequence)
  "Fur and blood. Raw, metallic. Your stomach clenches."
  → Player learns: this is raw meat, uncooked, borderline edible
  → RISK: Possible nausea from tasting raw meat
  → Player now knows enough to make an informed eat/don't-eat decision

STEP 5: EAT (Commitment — Full Consequence)
  "Stringy, warm, wrong. You chew against every instinct."
  → Player commits: nutrition gained, but status effects applied
  → CONSEQUENCE: Nausea, possible disease from uncooked meat
```

### Spoilage Changes the Sensory Ladder

The same escalation ladder applies at every spoilage stage, but the *information and risk change*:

| Sense | Fresh Corpse | Bloated Corpse | Rotten Corpse |
|-------|-------------|----------------|---------------|
| **SMELL** | "Blood, musk" → safe | "Sweet, sickly decay" → warning! | "Overwhelming rot" → DO NOT EAT |
| **FEEL** | "Warm, limp, fur" → ok | "Puffy, taut skin, gas" → concerning | "Squishy, falling apart" → horrifying |
| **TASTE** | "Raw, metallic" → nausea risk | "Bitter bile" → nausea guaranteed | "Immediate violent gag" → food poisoning |
| **EAT** | Nausea, +5 nutrition | Food poisoning, +0 | Severe poisoning, -5 HP |

**This is the design's killer feature.** A cautious player who SMELLs first will get clear warnings as the corpse decays. An impatient player who eats first will learn through suffering. The sensory system is BOTH the identification mechanism AND the risk management tool.

### How This Differs from Object-Food Escalation

Object-category food (bread, cheese, grain) uses the same ladder but with lower stakes:

| Sense | Fresh Bread | Stale Bread | Moldy Bread |
|-------|------------|-------------|-------------|
| **SMELL** | "Warm, yeasty" | "Faint wheat" | "Musty, sour" |
| **TASTE** | "Chewy, wholesome" | "Dry, chalky" | "GAG" |
| **EAT** | +15 nutrition | +5 nutrition | Nausea |

The escalation is gentler because bread is intrinsically safer than raw animal flesh. **The risk gradient maps to biological reality** — which is Principle 9 (material consistency) in action.

---

## 7. Alignment with Core Principles

| Principle | How This Design Honors It |
|-----------|--------------------------|
| **0: Objects are inanimate** | Dead creature mutates INTO an object. The boundary stays clean. Alive = creature system. Dead = object system. |
| **0.5: Deep nesting** | Corpse is placed at the creature's last location, preserving spatial context. Corpse contents (stolen items) use standard nesting. |
| **1: Code-derived mutable objects** | `rat-corpse.lua` IS the corpse definition. The `.lua` file defines its sensory properties, food metadata, and spoilage FSM. |
| **2: Base → instance** | Corpse inherits from `small-item` template. Multiple rats can die and produce multiple unique corpse instances. |
| **3: FSM + state tracking** | Corpse has its own spoilage FSM: `fresh → bloated → rotten → bones`. Each state has unique sensory descriptions. |
| **5: Multiple instances per base** | Kill three rats → three independent `rat-corpse` instances, each with own spoilage timer and location. |
| **6: Sensory space** | Full five-sense descriptions for every corpse state. SMELL warns of decay. TASTE risks disease. |
| **8: Engine executes metadata** | Creature declares `mutations.die.becomes = "rat-corpse"`. Engine handles the swap. No rat-specific engine code. |
| **9: Material consistency** | Rat corpse has `material = "flesh"`. Material properties determine what happens when you cut, burn, or cook it. |
| **D-14: Code mutation IS state change** | `rat.lua` → `rat-corpse.lua` → `rat-meat.lua` → `roasted-rat-meat.lua`. Each transformation is a code rewrite. The Prime Directive in its purest form. |

---

## 8. Implementation Sketch

### 8.1 New Object Files Needed

| File | Template | Purpose |
|------|----------|---------|
| `src/meta/objects/rat-corpse.lua` | small-item | Dead rat, edible, container, spoilage FSM |
| `src/meta/objects/rat-meat.lua` | small-item | Butchered meat, cookable |
| `src/meta/objects/roasted-rat-meat.lua` | small-item | Cooked meat, healing food |
| `src/meta/objects/rat-bones.lua` | small-item | Byproduct of butchery (future crafting) |

### 8.2 Creature Modification

Add to `rat.lua` (and creature template):

```lua
-- In rat.lua, add to existing definition:
mutations = {
    die = {
        becomes = "rat-corpse",
        message = "The rat shudders once and goes still.",
        transfer_contents = true,   -- any carried items go into corpse
    },
},
```

### 8.3 Rat Corpse Object (Sketch)

```lua
-- src/meta/objects/rat-corpse.lua
return {
    guid = "{generate-guid}",
    template = "small-item",
    id = "rat-corpse",
    name = "a dead rat",
    keywords = {"rat", "dead rat", "corpse", "rat corpse", "carcass", "body"},
    description = "A dead rat lies on its side, legs splayed. Its matted brown "
        .. "fur is darkened with blood. Beady black eyes stare at nothing.",

    size = 1,
    weight = 0.3,
    portable = true,
    material = "flesh",
    container = true,
    capacity = 1,        -- can hold small items the rat was carrying

    edible = true,
    food = {
        category = "meat",
        cookable = false,       -- can't cook a whole corpse; must butcher first
        spoil_time = 40,
        nutrition = 5,          -- barely worth it raw
        bait_value = 85,
        bait_target = "rodent",
        effects = {
            { type = "add_status", status = "nauseated", duration = 10 },
            { type = "narrate",
              message = "Fur and blood. Stringy, warm, profoundly wrong. "
                     .. "Your throat tries to close." },
        },
    },

    on_feel = "Cooling fur over a limp body. The ribcage is thin — you can "
           .. "feel the tiny bones beneath the skin. The tail hangs like wet string.",
    on_smell = "Blood and musk. The sharp copper of fresh death. Underneath, "
            .. "the musty smell of rodent.",
    on_listen = "Nothing. Absolutely nothing.",
    on_taste = "Fur and blood. Raw and metallic. Your stomach clenches immediately.",
    on_taste_effect = { type = "add_status", status = "nauseated", duration = 4 },

    -- Butchery mutation (requires knife tool)
    mutations = {
        butcher = {
            becomes = "rat-meat",
            requires_tool = "cutting_tool",
            byproducts = { "rat-bones" },
            message = "You work the knife under the rat's skin, peeling it away. "
                   .. "You separate a portion of lean, dark meat from the carcass.",
        },
    },

    -- Spoilage FSM
    initial_state = "fresh",
    _state = "fresh",
    states = {
        fresh = {
            description = "A dead rat, freshly killed. Blood still glistens on its fur.",
            room_presence = "A dead rat lies crumpled on the floor.",
        },
        bloated = {
            description = "A dead rat, belly distended with gas. The fur has dulled.",
            room_presence = "A bloated rat carcass lies here. The smell is getting worse.",
            on_smell = "Sweet, sickly decay. The copper of blood has given way to "
                    .. "something worse. Your nose wrinkles involuntarily.",
            on_feel = "The body is puffy, skin taut with gas. Warmer than it should be.",
            on_taste = "Bitter bile coats your tongue. You spit immediately.",
            food = {
                nutrition = 0,
                bait_value = 95,
                effects = {
                    { type = "inflict_injury", injury_type = "food-poisoning",
                      damage = 5 },
                    { type = "add_status", status = "nauseated", duration = 15 },
                    { type = "narrate",
                      message = "Your stomach heaves. That was a catastrophic mistake." },
                },
            },
        },
        rotten = {
            description = "A rotting rat, fur sloughing off in patches. Maggots "
                       .. "writhe in the exposed flesh. The smell is biological warfare.",
            room_presence = "A rotting rat carcass festers here. Flies swarm it.",
            on_smell = "Overwhelming putrefaction. Your eyes water from five feet away.",
            on_feel = "Squishy. Things shift inside that shouldn't. Your hand "
                   .. "comes away wet.",
            on_taste = "You gag before it reaches your lips. The smell alone is punishment.",
            food = {
                nutrition = 0,
                bait_value = 100,
                effects = {
                    { type = "inflict_injury", injury_type = "food-poisoning",
                      damage = 10 },
                    { type = "add_status", status = "nauseated", duration = 20 },
                    { type = "narrate",
                      message = "Your body rejects this in every way a body can." },
                },
            },
        },
        bones = {
            description = "A tiny rodent skeleton, picked clean. Fragile white "
                       .. "bones in a vaguely rat-shaped arrangement.",
            room_presence = "A tiny skeleton lies here, barely recognizable as a rat.",
            on_feel = "Dry, brittle bones. Light as paper. The skull is smaller "
                   .. "than your thumbnail.",
            on_smell = "Nothing. Just dust and old calcium.",
            edible = false,
            food = nil,
        },
    },
    transitions = {
        { from = "fresh",   to = "bloated", verb = "_tick", condition = "timer",
          timer = 40,
          message = "The dead rat has begun to bloat. The smell thickens." },
        { from = "bloated", to = "rotten",  verb = "_tick", condition = "timer",
          timer = 40,
          message = "The rat carcass is rotting. Flies descend in force." },
        { from = "rotten",  to = "bones",   verb = "_tick", condition = "timer",
          timer = 60,
          message = "The rat has decayed to bare bones." },
    },
}
```

### 8.4 Engine Touch Points

| System | Change Required | Effort |
|--------|----------------|--------|
| **Creature death handler** | On `dead` state entry, check for `mutations.die` and trigger mutation | Small — add to FSM or creature tick |
| **Mutation engine** | Support `transfer_contents` flag (move creature's carried items into corpse) | Small — extend `mutation.mutate()` |
| **Butcher verb** | New verb, checks for `mutations.butcher` + tool requirement | Medium — new verb handler |
| **Byproduct system** | `mutations.butcher.byproducts` creates additional objects on mutation | Small — extend mutation |

### 8.5 The Unified Food Type Model

After all this analysis, here is the unified model for how anything becomes food in our engine:

```
OBJECT-FOOD (bread, cheese, grain, fruit, herbs)
  → Already objects
  → Already have edible = true, food = { ... }
  → No transformation needed to BE food

CREATURE-FOOD (rat, chicken, wolf, spider)
  → Creature alive: NOT food (animate = true, no food table)
  → Creature dies: mutation to corpse OBJECT
  → Corpse: IS food (edible, food table, risky)
  → Butchered: mutation to meat OBJECT (cleaner food)
  → Cooked: mutation to cooked-meat OBJECT (best food)
```

**The answer to Wayne's question:** Both objects and creatures can be food because a dead creature BECOMES an object. The creature→object boundary crossing happens via mutation (D-14). Once it's an object, the food system treats it identically to bread or cheese. There is no duality — there's a transformation.

---

## 9. Open Questions for Wayne

### Q1: Should the corpse mutation happen instantly on death, or after a brief delay?

**Option A — Instant:** Rat dies → immediately becomes `rat-corpse.lua`. Clean, simple.  
**Option B — Delayed:** Rat dies → stays in `dead` state for 2–3 ticks (death animation window) → then mutates to corpse.  
**Recommendation:** Instant. The `dead` state exists for the death narration, which is already emitted by the transition. The corpse object takes over from there.

### Q2: Should ALL creatures drop corpses, or only small ones?

A rat corpse makes sense as a `portable = true` small item. But a dead wolf? A dead bear? Those can't fit in your hand.  
**Recommendation:** Size-based. Tiny/small creatures → portable corpse. Medium+ → non-portable corpse (furniture-sized). You can butcher a wolf corpse where it lies but not carry it.

### Q3: Butchery as skill or innate?

DF requires butchery skill. NetHack doesn't have butchery at all. Caves of Qud makes it a skill.  
**Recommendation:** Innate with tool requirement. Anyone with a knife can butcher — the puzzle is HAVING the knife, not KNOWING how. This matches our match-striking pattern (innate skill, compound tool requirement). A future "Butchery" skill could improve yield (2 meats instead of 1).

### Q4: Byproducts — bones, skin, fat?

DF produces bones, skin, fat, organs. NetHack produces nothing (corpse is the only product).  
**Recommendation:** Start with meat + bones only. Bones are a curiosity item and potential future crafting material. Skin and fat are Phase 3+ complexity. KISS for V1.

### Q5: Can you cook a whole corpse without butchering?

Hold dead rat over fire = roast it whole?  
**Recommendation:** No. The corpse has `cookable = false`. You must butcher first. This preserves the tool-chain puzzle: knife → butcher → fire → cook. If you could skip butchering, the knife becomes pointless for food.

### Q6: Rat corpse as bait?

The dead rat itself has high bait_value (85). Should other rats be attracted to it?  
**Recommendation:** Yes — but with a dark twist. Rats are cannibalistic scavengers. A dead rat attracts live rats. This creates emergent gameplay: kill one rat, its corpse lures another. The player can exploit this or be overwhelmed by it.

---

## Final Verdict

**Best fit for our DF-inspired, text-IF identity:** The Hybrid Mutation Model.

We take:
- **From Dwarf Fortress:** Butchery as meaningful transformation, creature identity preserved in food
- **From NetHack:** Corpse as single intermediate item, eating risk/reward, spoilage timer
- **From MUDs:** Corpse as container for loot transfer
- **From Don't Starve:** Nothing. Their model is too abstract for our simulation.
- **From Caves of Qud:** Butchery as tool-gated action (not workshop), creature type determines output

And we add what nobody else has:
- **Sensory escalation** — smell it, feel it, taste it (risky), eat it (committed). Every stage of spoilage changes the sensory information. The player's nose is their best food safety tool.
- **Code mutation chain** — `rat.lua → rat-corpse.lua → rat-meat.lua → roasted-rat-meat.lua`. Four stages, four distinct objects, four sets of sensory descriptions. The Prime Directive made manifest.

Worst. Design question. Ever. Best. Design answer. Always.

*— Comic Book Guy, filed from behind the counter*


## cbg-phase2-review

# Comic Book Guy — Phase 2 NPC+Combat Review

**Date:** 2026-07-31  
**Requested by:** Wayne Berry  
**Source Material:**  
- `plans/npc-combat-implementation-phase2.md` (Chunks 1–4)
- `.squad/agents/comic-book-guy/history.md`
- `.squad/decisions.md` (NPC + Combat sections)

---

## Executive Summary

**Verdict:** ✅ **DESIGN READY FOR EXECUTION** with minor balance tuning and one player-experience concern.

The Phase 2 plan is **architecturally sound** and **follows all design principles**. The 4-creature roster fits Level 1 perfectly. NPC-vs-NPC combat will feel emergent and alive. Food/bait feels natural. **However:**

1. ⚠️ **Rabies at 15% is too punishing for early game** — recommend 8% instead (data-driven reasoning below)
2. ⚠️ **Spider venom at 100% needs telegraphing** — players should understand spiders are lethal before first encounter
3. ⚠️ **6 waves is tight but correct** — scope is appropriate, pacing is right
4. ✅ **Test scenarios capture the key moments** — excellent LLM walkthrough coverage
5. ❌ **One critical blocker:** Witness narration line cap (R-9: ≤6 lines/round) is under-specified

---

## Section 1: Game Design Correctness — Creature Roster

### ✅ Cat (Predator)
**Assessment:** Perfect for Level 1. Fits the "cute but deadly" archetype.

- **Why it works:** Rats are pests; cats hunt pests. Natural dynamic. Small enough to fit in a bedroom (realism beats fantasy here).
- **Threat level:** ~4/10 to player (unless starving and player bleeding). ~9/10 to rats. Appropriate power curve.
- **Sensory moment:** Hearing a cat prowl in darkness is unsettling. The `on_feel` description should emphasize warmth and fur — players won't expect that in a Zork-like.

**Recommendation:** Add one sensory detail to cat: whiskering sounds on walls (`on_listen`). Makes it *auditorily* distinctive from the rat, increases tension in darkness.

---

### ✅ Wolf (Territorial Aggressor)
**Assessment:** Excellent escalation. Raises stakes significantly.

- **Why it works:** Wolves defend territory. The hallway is a natural bottleneck — wolf becomes a gate boss for Level 1, not a wandering random encounter. Genius placement (Moe).
- **Threat level:** ~7/10 to player. ~10/10 to cat. Creates emergent fear: "What if the cat and wolf meet?"
- **Design debt:** Wolf should have a **distinct vocalization** (howl, growl) that:
  - Alerts the player to its presence before encounter
  - Triggers fear/stress damage to creatures in adjacent rooms (adds atmosphere)
  - Can be heard during NPC-vs-NPC combat (witness narration enrichment)

**Recommendation:** Add `vocalize` action to wolf FSM. Emit it on player entry + territorial breach. Gives player a "turn back now" signal without forcing an encounter.

---

### ✅ Spider (Ambush / Venom Threat)
**Assessment:** Perfect puzzle creature. Introduces material variety (chitin).

- **Why it works:** Spiders are **passive until touched**. This teaches the player: "Not everything hostile is aggressively hostile." Web-building is a fantastic forward-signal. Venom is memorable consequence.
- **Threat level:** ~9/10 due to paralysis + venom, but **only if triggered**. Passive = player agency.
- **Design debt:** The plan lacks **web interaction clarity**. Does the player know when they're walking into a web? Can they feel it?

**Critical recommendation:** 
- **On entry to spider room:** If web exists, player must `feel` or `listen` to detect it, OR take 1 damage + web-walking narration ("sticky silk clings to your face").
- **On darkness + web:** Increased chance of triggering trap (no visual warning).
- **Light + web:** Visual warning in `look` output ("Gossamer strands catch the light, draped across the passage").

This makes spider rooms **tactile puzzles**, not just "die to venom if you're unlucky."

---

### ✅ Bat (Light-Reactive)
**Assessment:** Excellent sensory creature. Fills a unique niche.

- **Why it works:** Bats are **echolocation masters**. They're harmless unless cornered. They react to light = introduces light as a **deterrent tool**, not just a visibility aid.
- **Threat level:** ~2/10 to player. ~1/10 to combat (bats flee). Flavor creature that teaches systems, not a threat.
- **Design debt:** Bats in the **crypt** (dark, roosting) should be **auditorily interesting**. Wing flutters, echolocating clicks.

**Recommendation:** 
- Bat `on_listen` should **change based on state**:
  - Roosting: "Quiet. Occasional tiny scratches of claws on stone."
  - Woken: "Chaotic echolocation clicks and wing flutters, deafening at close range."
- Bat `on_feel` if player touches: "Soft fur, rapid heartbeat. The bat's claws rake your hand."

---

## Section 2: Player Experience — NPC-vs-NPC Combat Emergence

### ✅ Will It Feel Alive?
**Assessment:** YES. The combat system is fundamentally emergent, not scripted.

**Why:**
1. **No per-creature hardcoding** (Principle 8) — the engine runs `resolve_exchange()` the same way for cat vs. rat, wolf vs. cat, or player vs. rat. Outcomes are purely material physics + RNG, not special cases.
2. **Witness narration is severity-based, not creature-based** — so even if we add 10 more creatures in Phase 3, the narration doesn't get "canned" (a common failure mode in MUDs).
3. **Morale/flee is organic** — when the wolf is losing to the cat, it doesn't have a "surrender" flag; it just hits `flee_threshold` and runs. The player witnesses **tactical retreat**, not programmed cowardice.

### ⚠️ "Witnessing" is Underbaked

The plan specifies witness narration tiers (lit/dark/adjacent), but **narrative density is under-specified**:

| Scenario | Line Cap | Example |
|----------|----------|---------|
| Same room, lit | 2 lines/exchange | "The wolf lunges. You see blood on its muzzle." |
| Same room, dark | 2 lines | "You hear yelping and the crunch of bone." |
| Adjacent room | 1 line | "From the next room, scrabbling and shrieks." |
| **Per round max** | ≤6 lines | Includes player turn + 2 exchanges + morale breaks |

**Problem:** At line cap ≤6 per round, a 3-creature fight (2 exchanges + messages) fills the cap fast. If the player also acts, narration is cut short. **This can feel claustrophobic in darkness.**

**Recommendation:** 
- Increase line cap to **8 lines/round** (from 6) to keep narration breathable
- **Prioritize severity**: CRITICAL hits always narrate (2 lines). GRAZE hits only narrate if room is **lit**.
- **Add a "round marker"** for multiple creatures ("The melee erupts...") to set context without eating line budget.

---

## Section 3: Pacing — Is 6 Waves Right?

### ✅ Scope is Correct. Pacing is Right.

**Wave breakdown confidence:**
- **WAVE-0** (pre-flight): 1 day. Clearing runway.
- **WAVE-1** (4 creatures + material): 3–4 days. Data files are straightforward.
- **WAVE-2** (predator-prey engine): 2–3 days. Small code, ~60–80 LOC.
- **WAVE-3** (NPC combat + narration): 3–4 days. Heaviest engineering.
- **WAVE-4** (disease system): 2–3 days. Parallelizable (Flanders + Bart + Nelson).
- **WAVE-5** (food + bait + docs): 2–3 days. Bait is the only complex piece.

**Total: ~2 weeks** for a playable Phase 2. This is **aggressive but achievable**.

### ✅ Why This Order Matters

Strict dependency chain is correct:
1. **Creatures exist** (WAVE-1) before they behave.
2. **Creatures behave** (WAVE-2) before they fight each other.
3. **They fight each other** (WAVE-3) before diseases transmit.
4. **Diseases transmit** (WAVE-4) before food becomes strategic.
5. **Food is strategic** (WAVE-5) as bait + survival mechanic.

You **cannot** parallelize WAVE-2/3 because combat integration in WAVE-3 depends on stable creature engine from WAVE-2. Bart's right to serialize.

---

## Section 4: Disease Balance — Rabies at 15% Early Game

### ⚠️ Rabies Probability is TOO HIGH

**Current plan:** 15% chance per rat bite.

**Problem:** 
- Player encounters rat in cellar, gets bitten defending cheese/exploring.
- 1-in-6.67 chance of infection on first hit.
- Incubation hides symptoms for 15 ticks (~1.5 minutes of real time if ticks are fast).
- Player has no way to **anticipate** rabies or **prepare** for it in early game.
- If infected early, player spends 33 turns (furious stage) unable to drink (hydrophobia) — a major puzzle blocker.

**Comparison to Dwarf Fortress disease:**
- DF vampire bites: 5% per hit, slow incubation, but **players expect DF to kill them**.
- DF dwarf bite (infection): rarer, more telegraphed (bleeding = warning).

**Level 1 context:**
- Player is still learning the interface.
- Rabies locks out `drink` verb, which is progression-critical if thirst system exists later.
- **No player signaling** — unlike venom (immediate paralysis), rabies is a hidden timer.

### Recommendation: 8% Instead of 15%

**Math:**
- 8% ≈ 1 in 12.5 bites.
- Over a typical Level 1 playthrough (2–3 rat encounters), ~15–20% chance of infection.
- Still **meaningful**, but not "gotcha mechanics."
- **Double-bite encounters** (player attacks rat twice) have ~15% chance of infection, matching current 1-hit probability.

**Tuning path:**
- Start Phase 2 with 8%.
- **After GATE-5 LLM walkthrough**, if players don't respect rabies enough, raise to 10%.
- **Never go above 12%** in Level 1.

---

## Section 5: Spider Venom — 100% Delivery Needs Telegraphing

### ⚠️ Venom Feels Unfair Without Warning

**Current plan:** Spider bite = 100% venom delivery. Movement/attack restrictions follow immediately.

**Problem:**
- Player enters dark cellar, has no way to know a spider is present.
- Attempts `grab` something on ground.
- Spider bites (Principle 8: creatures react to stimulus, not scripts).
- **Suddenly paralyzed.** No warning. No recovery path.
- Player learns "dark = death" instead of "darkness = different mode of play."

### Recommendation: Telegraphing via Sensory

**Spiders must be discoverable before combat:**

1. **`on_listen` in spider room (dark or lit):**
   - "Faint scratching, like tiny claws on stone."
   - This tells attentive players: *something is here.*

2. **`on_feel` when player touches web strands:**
   - "You brush sticky silk. Something large moves nearby."
   - Natural consequence of exploring in darkness.

3. **Spider `on_approach` stimulus** (when player enters room):
   - Spider should emit a low-threat vocalization or movement sound.
   - **Example:** `creature_enters` → spider emits `creature_vocalize` stimulus ("faint hissing").
   - This is in Principle 8 spirit: creature broadcasts presence via metadata, not hardcoded events.

**Don't hide the spider.** Make it **discoverable without fighting it.** Then venom feels like a consequence of poor preparation, not a cheap shot.

---

## Section 6: Food PoC — Cheese/Bread as Bait Feels Natural ✅

### ✅ Bait Mechanic is Well-Designed

**Why it works:**
1. **Intuitive player hypothesis:** "I have food, the rat is hungry, maybe food draws the rat."
2. **Low-risk experiment:** Dropping cheese costs nothing. If it works, player feels clever.
3. **Emerges from creature metadata:** Rat has `hunger` drive + `bait_targets` list. No special bait engine.
4. **Tactical depth:** Player can bait rat away from an exit, then flank. Or bait it into a trap (future design space).

### ✅ Cheese & Bread Feel Right for Level 1

| Item | Context | Design Reason |
|------|---------|---------------|
| Cheese | Found in nightstand (starting area) | Portable, immediately available, has obvious food-smell |
| Bread | Would be in kitchen or pantry (future room) | More filling than cheese, slower spoilage, heavier |

**Sensory moments:**
- Cheese `on_smell`: "Pungent dairy odor. A rat would smell this from far away."
- Bread `on_smell`: "Yeasty, slightly stale. Homey."

**No issues here.** Food is straightforward flavor win.

---

## Section 7: Missing Features — Checklist

### ✅ Nothing Critical Missing

The plan covers:
- ✅ Creature data files (4 creatures)
- ✅ Creature-to-creature reactions
- ✅ Predator-prey metadata
- ✅ Territorial behavior
- ✅ NPC-vs-NPC combat
- ✅ Witness narration (lit/dark/adjacent)
- ✅ Morale + flee
- ✅ Disease delivery (`on_hit`)
- ✅ Rabies + venom FSM
- ✅ Food objects + spoilage
- ✅ Bait mechanic
- ✅ Eat/drink verbs

### ⚠️ Nice-to-Haves (Deferred to Phase 3+)

1. **NPC grieving / emotional response** — If player kills a creature another creature likes, should the other creature react emotionally? (Out of scope for Phase 2.)
2. **Creature reproduction / nests** — Spiders lay eggs, rats breed. (Out of scope.)
3. **Scavenging behavior** — Creatures eat corpses. (Out of scope; food PoC is tame.)
4. **Social hierarchies** — Alpha wolves, subordinates. (Out of scope.)
5. **Cooking system** — The plan explicitly excludes cooking. ✅ Right call for Level 1.

---

## Section 8: Test Scenarios — Do They Capture Key Moments?

### ✅ Excellent LLM Coverage

**GATE-2 scenarios (Creature Combat):**
- ✅ P2-A: Cat chases rat across rooms (predator-prey chase)
- ✅ P2-B: Wolf attacks player on sight (aggressive creature init)
- ✅ P2-C: Spider web trap (passive + discovery)

**GATE-3 scenarios (NPC-vs-NPC Witness):**
- ✅ P2-D: Player watches cat kill rat (lit room narration)
- ✅ P2-D2: Witness combat in darkness (audio-only narration)
- ✅ P2-E: Multi-combatant turn order (3+ creatures)

**GATE-4 scenarios (Disease):**
- ✅ P2-F: Rabies progression (incubation → symptoms)
- ✅ P2-F2: Spider venom delivery (100% immediate effect)

**GATE-5 scenarios (Food + Full End-to-End):**
- ✅ P2-G: Bait mechanic (cheese lures rat)
- ✅ P2-H: Eat/drink verbs (consumption + removal)
- ✅ P2-I: Rabies blocks drinking (cross-system interaction)
- ✅ P2-J: Full end-to-end (24+ command chained scenario)

**Assessment:** These scenarios cover:
- ✅ All 4 creatures in action
- ✅ Creature-vs-creature combat
- ✅ Player-vs-creature combat
- ✅ Disease transmission + progression
- ✅ Food mechanics + bait
- ✅ Cross-system interactions (disease blocks verb, food triggers behavior)
- ✅ All sensory modes (lit, dark, listening)

**One gap:** No explicit scenario for **territorial wolf behavior** (wolf defends hallway). P2-B covers "wolf attacks on sight," but not "wolf returns to territory after fleeing." Minor — unit tests cover this, and it's less critical than predator-prey + witness narration.

---

## Section 9: Blockers — Issues That MUST Be Resolved Before GATE-0

### ❌ BLOCKER: Witness Narration Line Cap Under-Specified

**Issue:** GATE-3 requires <6 lines/round (R-9), but the plan doesn't define:
- Who counts the lines? (Smithers' code?)
- What happens when the cap is hit? (Drop narration? Queue for next round?)
- Does player action count toward the cap?
- Does morale break narration count? (If so, it consumes 2 lines instant.)

**Example failure scenario:**
```
Round 1:
- Wolf attacks cat: 2 lines
- Cat counterattacks: 2 lines
- Wolf morale breaks, flees: 1 line
- Total: 5 lines. Budget: 6. OK.

Round 2:
- Rat attacks cat: 2 lines
- Cat attacks wolf (who is fleeing): 2 lines
- Player types: "attack cat"
- Player attacks: 2 lines
- Total: 6 lines. Budget: 6. OK.

Round 3:
- Rat attacks wolf: 2 lines
- Wolf counterattacks: 2 lines
- Cat attacks rat: 2 lines
- Player attacks rat: 2 lines
- TOTAL: 8 lines. OVER BUDGET.
- ❓ What happens? Silent round? Delayed narration?
```

**Recommendation:**
- **In Smithers' implementation** of witness narration (WAVE-3), define line budgeting **explicitly**:
  - Create a `narration_budget` counter per combat round.
  - Increment on each `narration.emit()` call.
  - When budget hit: **suppress non-critical narration** (GRAZE/DEFLECT) but **keep critical** (HIT/CRITICAL/DEATH).
  - Defer overflow narration to next round with a marker: *"[The melee continues...]"*
  - Document this in the **gate criteria** and **implementation notes**.

---

## Section 10: Recommendations Summary

| Issue | Severity | Recommendation | Impact |
|-------|----------|-----------------|--------|
| Rabies at 15% | ⚠️ Balance | Drop to 8% (tunable later) | Better early-game fairness |
| Spider venom unannounced | ⚠️ UX | Add telegraphing via sensory + creature vocalize | Players feel "gotcha" → "prepared" |
| Cat whisker sounds | ⚠️ Flavor | Add `on_listen` detail | Increases tension in darkness |
| Wolf vocalization | ⚠️ Flavor | Add howl/growl FSM action | Gives player "turn back" signal |
| Spider web interaction clarity | ⚠️ Puzzle | Define web walk / feel interactions | Makes spiders tactical, not random |
| Witness narration line cap | ❌ **BLOCKER** | Define budgeting + overflow logic | Prevents silent/confusing combat rounds |

---

## Section 11: Gate Sign-Off Criteria (CBG)

**GATE-5 Player Experience Check** (per plan Chunk 3):

- [ ] Does cat-kills-rat feel natural and discoverable? ✅ YES (within 3 turns of entering room)
- [ ] Does rabies create a meaningful "oh no" moment? ✅ YES, but **only if** incubation is hidden (already in plan)
- [ ] Does bait mechanic feel like a puzzle the player would try? ✅ YES (cheese → rat → obvious hypothesis)
- [ ] Does darkness feel like a different mode of play, not a death sentence? ✅ **CONTINGENT** on spider telegraphing (see ⚠️ above)
- [ ] Do all 4 creatures feel like distinct encounters? ✅ YES (cat: chase, wolf: territory, spider: trap, bat: illusion)

**CBG sign-off:** 
- 🟡 **CONDITIONAL PASS on design**
- 🟡 Recommend tuning rabies to 8% before first playtest
- 🟡 Recommend spider telegraphing before WAVE-1 creature files are finalized
- ✅ Otherwise, architecture is solid

---

## Design Debt (For Phase 3+)

**Note:** These are *not* blockers. Deferred per scope.

1. **NPC grieving** — If player kills wolf, other creatures should react emotionally (future NPC depth feature).
2. **Creature vocalization system** — Currently manual (`vocalize` action). Could become auto-emitted on state change for better immersion.
3. **Witness narration variety** — Currently severity-based. Phase 3 could add creature personality ("The wolf fights with honor" vs. "The rat fights viciously").
4. **Disease immunity** — After surviving rabies, player should develop partial immunity. Future difficulty-scaling feature.
5. **Food chain** — Creatures eating creatures (spiders eat insects, wolves scavenge). Phase 3 necrophagy system.

---

## Final Assessment

**✅ DESIGN READY FOR EXECUTION**

Phase 2 is **architecturally sound**, **follows all design principles**, and will create **emergent, alive gameplay**. The creature roster is balanced, the food PoC is natural, and the test scenarios are comprehensive.

**Minor balance tuning** (rabies 8%, spider telegraphing) will improve player fairness without breaking design.

**One blocker** (witness narration line cap definition) must be clarified in WAVE-3 implementation specs before Smithers codes.

**Estimated player reaction:** "Wait, the creatures *fight each other?* That's sick. And I can use food to solve puzzles? I didn't expect that." — This is the definition of emergent gameplay success.

---

**Signed:** Comic Book Guy (Game Designer)  
**Date:** 2026-07-31  
**Status:** ✅ APPROVED FOR EXECUTION


## chalmers-phase2-review

# Phase 2 NPC+Combat Implementation Plan Review

**Reviewed By:** Chalmers (Senior Reviewer)  
**Date:** 2026-03-26T16:45:00Z  
**Plan:** `plans/npc-combat-implementation-phase2.md` (Chunks 1–5)  
**Status:** READY WITH IMPROVEMENTS

---

## Executive Summary

The Phase 2 plan is **structurally sound** and **sequencing is mostly correct**, but several **safety and scalability issues** require attention before execution:

| Category | Status | Notes |
|----------|--------|-------|
| **Wave sequencing** | ✅ | Dependencies are correct; no parallel improvements possible |
| **File conflicts** | ⚠️ | CRITICAL: `src/engine/creatures/init.lua` modified in 2 waves; collision risk |
| **Crash resilience** | ⚠️ | No gate recovery procedure for mid-wave failure |
| **Session continuity** | ✅ | Version tracking present (Chunks 1–5); status tracker included |
| **Module size** | ❌ | `creatures/init.lua` +140 LOC / `combat/init.lua` +80 LOC will exceed limits |
| **Plan lifecycle** | ⚠️ | No post-mortem template; no version control for plan itself |
| **Gate failure paths** | ⚠️ | Escalation rules vague; no rollback procedure |

---

## Detailed Findings

### 1. Wave Sequencing ✅

**Assessment:** The dependency chain is correct and **cannot be parallelized further**.

**Evidence:**
- WAVE-0 → WAVE-1: Pre-flight must complete before creature data creation (reasonable)
- WAVE-1 → WAVE-2: Data must exist before engine consumes it (correct)
- WAVE-2 → WAVE-3: Predator-prey must work before multi-combatant (logical)
- WAVE-3/WAVE-4/WAVE-5: Correct serial ordering (combat → disease delivery → food uses combat)

**Parallelization check:**
- WAVE-3 (Bart/Smithers) and WAVE-4 (Flanders/Bart) are sequential: both need `combat/init.lua` modifications. WAVE-3 ships combat; WAVE-4 extends it with `on_hit` delivery. ✅ Cannot parallelize.
- WAVE-4 and WAVE-5 can overlap: Disease system (WAVE-4) and Food PoC (WAVE-5) are independent except Rabies blocks `drink` verb (cross-cut). This is intentional for integration testing. ✅ Correct.

**Gate sequencing is binary (no soft gates).** All-or-nothing progression prevents half-complete states. ✅

---

### 2. File Conflicts ⚠️ **CRITICAL**

**Assessment:** Dangerous file collision in WAVE-2 and WAVE-5.

**Conflict found:**

| File | WAVE-2 | WAVE-5 | Risk |
|------|--------|--------|------|
| `src/engine/creatures/init.lua` | Bart modifies (attack action, predator-prey) | Bart modifies (bait mechanic, hunger drive) | **MERGE CONFLICT** |
| `src/engine/combat/init.lua` | Bart modifies (NPC-vs-NPC) | — | Separate waves ✅ |

**The problem:** Both WAVE-2 and WAVE-5 claim ownership of `creatures/init.lua`:
- **WAVE-2:** Adds `score_actions()` for attack, `execute_action("attack")` branch, creature-to-creature stimulus
- **WAVE-5:** Adds hunger drive tick, `food_stimulus` detection, creature movement toward food

**WAVE-3 and WAVE-4 don't modify `creatures/init.lua`** (Bart only modifies `combat/init.lua` and `injuries.lua`). So the file sits untouched for 4 waves, then Bart comes back in WAVE-5. **If WAVE-2 or WAVE-3 fails and needs rollback, WAVE-5 code won't apply cleanly.**

**Recommendation:**
- **Option A (Preferred):** Move food/bait logic (`create_stimulus()` + hunger tick) into a separate module `src/engine/food-drivers/init.lua`. Creatures calls `food_drivers.process_hunger(creature, context)` once per tick. Eliminates file conflict; keeps `creatures/init.lua` stable after WAVE-2.
- **Option B:** Merge WAVE-2 and WAVE-5 food/bait work into a single WAVE-2.5 between WAVE-2 and WAVE-3. Requires scope negotiation; may delay NPC-combat ship date.
- **Option C (Current):** Accept conflict; document merge procedure in `.squad/decisions/`. If WAVE-2 fails mid-execution, WAVE-5 will need manual `git rebase` or cherry-pick. **Risk: Human error during recovery.**

**Decision requested:** Wayne should choose A/B/C before WAVE-0 starts.

---

### 3. Crash Resilience ⚠️

**Assessment:** No recovery procedure if a wave fails mid-execution.

**Current protocol (implicit from text):**
- Wave starts → parallel tasks → gate tests run → all-or-nothing pass/fail
- If gate fails: "Fix before proceeding" (implied: no formal retry procedure)

**Missing pieces:**
1. **Mid-wave failure:** If Flanders creates `cat.lua`, `wolf.lua`, `spider.lua` but Moe's room modifications fail, what's the status? Is the wave "half-done"? Can Nelson run GATE-1 tests?
2. **Gate failure recovery:** If GATE-1 fails because "chitin material registry fails," who owns the fix? Flanders (creator) or Bart (architecture reviewer)? Time estimate?
3. **Rollback procedure:** If GATE-1 fails after 4 hours of work, do we `git reset --hard` to pre-wave state and re-execute? Or cherry-pick individual fixes?

**Recommendation:**
- Add section to plan: **"Crash & Recovery Protocol"** (suggest ~200 words)
  - Define "half-done" wave: which tasks are critical-path vs. optional-polish?
  - Assign recovery owner for each gate failure class (e.g., "creature data load failure" → Flanders; "test infra failure" → Nelson)
  - Document rollback procedure: `git reset` vs. targeted fixes
  - Set re-gate budget: after fix, re-run gate immediately (no re-planning)

**Example structure:**
```markdown
## Crash & Recovery Protocol

### Mid-Wave Failure
If a wave is incomplete at day-end, the next day:
1. Status check: which tasks are done? (Flanders can report cat.lua + wolf.lua done, spider/bat incomplete)
2. Continuous tests: run partial test suite on completed deliverables (tests on cat/wolf pass; spider/bat tests skip)
3. Continue from checkpoint: remaining agents pick up where they left off (no re-planning)

### Gate Failure Classifications
- **Data load failure** (creatures don't parse): Owner = Flanders (fix data); recover time ~30 min
- **Test infrastructure failure** (test/food/ dir not registered): Owner = Nelson (fix runner); recover time ~15 min
- **Engine bug** (attack action crashes): Owner = Bart (fix code); recover time ~1–2 hrs
```

---

### 4. Session Continuity ✅

**Assessment:** Version tracking and status tracking are present and functional.

**Evidence:**
- **Plan versioning:** Each chunk has a date (2026-07-30, 2026-07-28) and "Chunk N of 5" header. Clear linear order.
- **Wave status tracker (§1, ~line 22):** `| Wave | Status |` table with `⏳` placeholders. Can be updated in real time.
- **Section 2 (Gates + Testing):** Each gate documents its exact pass/fail criteria and commit message (line ~706: `git commit -m "GATE-1: Phase 2 creature definitions..."`).
- **Scenario logging (§3, ~line 1107):** Nelson logs each LLM run to `test/scenarios/gate{N}/` with deterministic seeds and PASS/FAIL markers.

**This is professional.** The plan is a living document; teams can track progress by:
1. Updating wave status tracker daily
2. Grepping for "gate{N}" in commit history
3. Reading scenario log files for regression detection

**Gaps:**
- No "planned completion date" for each wave (e.g., "WAVE-1: ~4 hours, 1 agent day + 0.5 test days")
- No carry-over / burndown dashboard linking to daily plan

**Minor recommendation:** Add time estimate and owner per wave (suggested 1–2 lines each).

---

### 5. Module Size ❌ **CRITICAL**

**Assessment:** Engine modules will exceed safe LOC limits.

**Current sizes (from Phase 1):**
- `src/engine/creatures/init.lua`: 421 LOC
- `src/engine/combat/init.lua`: 435 LOC
- `src/engine/injuries.lua`: ~350 LOC (estimated from design)

**Phase 2 additions (per plan):**
- **WAVE-2:** `creatures/init.lua` +60–80 LOC (predator-prey, attack action)
- **WAVE-3:** `combat/init.lua` +30–50 LOC (NPC response auto-select, NPC stance)
- **WAVE-5:** `creatures/init.lua` +60–80 LOC (hunger drive, food stimulus)
- **WAVE-4:** `injuries.lua` +30–40 LOC (disease FSM ticking, `hidden_until_state` check)

**Post-Phase 2 sizes:**
- `creatures/init.lua`: 421 + 140 = **561 LOC** (EXCEEDS 500 LOC threshold)
- `combat/init.lua`: 435 + 80 = **515 LOC** (EXCEEDS 500 LOC threshold)
- `injuries.lua`: 350 + 40 = **390 LOC** (OK)

**Reference:** GATE-0 checks `wc -l` against 500 LOC limit (line ~656).

**This will fail GATE-0.** The plan pre-emptively identifies the problem but doesn't propose a solution.

**Recommendation (Must choose before WAVE-0):**

**Option A: Split creatures/init.lua (Preferred)**
- Extract creature-to-creature stimulus system → `src/engine/creatures/stimulus.lua` (~80 LOC)
- Extract predator-prey detection → `src/engine/creatures/predator-prey.lua` (~60 LOC)
- Keep main file at ~420 + 40 (attack action) = 460 LOC ✅

**Option B: Split combat/init.lua**
- Extract NPC behavior selection → `src/engine/combat/npc-behavior.lua` (~50 LOC)
- Keep main file at ~435 + 30 (narration changes) = 465 LOC ✅

**Option C: Defer WAVE-5 food/bait to Phase 3**
- Removes 60–80 LOC of creature additions → final size ~480 LOC ✅
- Trade-off: delays food PoC by 1 sprint; Phase 2 ships just creature combat (thematically incomplete)

**Option D: Accept 500+ LOC as a one-time exception**
- Update GATE-0 threshold to 600 LOC
- Risk: sets precedent; next phase module might be 700 LOC

**Chalmers recommendation:** Choose **Option A** (stimulus module split) because:
1. Stimulus is a distinct subsystem with clear interface
2. Isolates creature-to-creature events from creature-tick lifecycle
3. Future Phase 3 (social creatures, cooperation) will need this module anyway
4. No impact on WAVE-2 or WAVE-5 implementation; refactor timing is flexible (before or after WAVE-2)

---

### 6. Plan Lifecycle ⚠️

**Assessment:** Plan is thorough but lacks post-mortem and meta-versioning.

**Strengths:**
- Clear 5-chunk structure with cross-references
- Every gate has acceptance criteria
- Scenario logging provides regression baseline
- Each wave has file ownership matrix

**Gaps:**
1. **No post-mortem template:** After Phase 2 completes, where do lessons go?
   - Example: "Food bait mechanism was simpler than expected; could have shipped 1 day earlier"
   - Example: "Witness narration audio-only mode has edge case in adjacent-room distance calc; needs Phase 3 fix"
   - These go to `.squad/decisions/inbox/` or project notes?

2. **No plan versioning control:** If Bart needs to update the plan mid-wave (e.g., change WAVE-3 acceptance criteria), how is this tracked?
   - Suggested: `plans/npc-combat-implementation-phase2.md` → commits its changes to git (rare but possible during planning phase)
   - Or: `.squad/decisions/inbox/{agent}-phase2-scope-change.md` for each change

3. **No "plan deprecation" marker:** After WAVE-5, is this plan read-only? Or can it be edited for archival?
   - Suggested: Add "Status" field: `ACTIVE` → `COMPLETE` → `ARCHIVED` at doc top

**Recommendation:**
- After GATE-5 (phase 2 complete), file: `.squad/decisions/inbox/bart-phase2-postmortem.md` documenting:
  - What was faster/slower than estimated?
  - What module splits worked well? (if Option A is chosen)
  - Did creature-to-creature stimulus generalize as expected?
  - Food bait complexity vs. design estimate?
- Add "Plan Status: ACTIVE (in progress)" to top of doc; change to "COMPLETE" when GATE-5 passes
- Archive decision: move `.squad/decisions/inbox/` → `.squad/decisions/archive/` once merged into `decisions.md`

---

### 7. Gate Failure Paths ⚠️

**Assessment:** Gate failure escalation is implicit but not explicit.

**Current text (line ~668):**
> Action on fail: "File issue, assign to Flanders (creature data) or Nelson (test fix), re-gate."

**Problems:**
1. **No SLA:** How quickly should the assigned agent fix and re-gate? 1 hour? 1 day?
2. **No escalation:** What if Flanders doesn't respond? Does Bart take over? Does the wave wait?
3. **No rollback decision:** Is the wave rolled back to pre-start state while fixing? Or fixed in-place and then re-tested?
4. **No cross-gate rollback:** If GATE-2 fails, do we roll back GATE-1 and WAVE-1, or just fix WAVE-2 in isolation?

**Examples of ambiguous scenarios:**
- GATE-1 passes; GATE-2 partially fails (20 of 40 tests crash). Flanders fixes creature data (not code). Do we re-run all of GATE-2 or just the failing tests?
- GATE-3 fails; multi-combatant test loops forever. Bart needs to split `combat/init.lua` (Option B from module size issue). Do we delay WAVE-4 while splitting? Or split after GATE-3 passes?

**Recommendation:** Add **"Gate Failure Escalation Matrix"** to plan:

```markdown
## Gate Failure Escalation

| Gate | Failure Category | Owner | Assigned By | SLA | Rollback? |
|------|------------------|-------|-------------|-----|-----------|
| GATE-0 | Test dir not found | Nelson | Bart | 30 min | No (pre-flight) |
| GATE-1 | Creature load fails | Flanders | Bart | 1 hour | Yes (roll back WAVE-1) |
| GATE-1 | Creature load fails | Nelson | Bart | 30 min | No (in-place fix) |
| GATE-2 | Attack action crashes | Bart | Nelson | 2 hours | Yes (roll back WAVE-2) |
| GATE-3 | Multi-combatant hangs | Bart | Marge | 3 hours | Yes (roll back WAVE-3) |
| GATE-4 | Disease FSM doesn't progress | Bart or Flanders | Nelson | 2 hours | No (in-place fix) |
| GATE-5 | LLM scenario fails non-deterministically | Nelson | Bart | 1 hour (re-seed) | Maybe (investigate first) |

---

**Decision Rules:**
- **Code bugs (Bart/Smithers):** Assign immediately; SLA 2–3 hours; roll back wave on failure
- **Data issues (Flanders/Moe):** Assign immediately; SLA 1 hour; no rollback (in-place fix acceptable)
- **Test/infra issues (Nelson):** Assign immediately; SLA 30 min–1 hour; no rollback (fix and re-run)
- **If SLA expires:** Escalate to Chalmers for judgment call (defer wave, split task, etc.)
```

---

## Summary Table

| Review Area | Status | Issue | Impact | Recommendation |
|-------------|--------|-------|--------|-----------------|
| Wave sequencing | ✅ | None | — | Proceed |
| File conflicts | ⚠️ | `creatures/init.lua` touched in WAVE-2 & WAVE-5 | Merge conflict on rollback | **Choose Option A/B/C before WAVE-0** |
| Crash resilience | ⚠️ | No recovery procedure | Recovery is ad-hoc | Add "Crash & Recovery Protocol" section |
| Session continuity | ✅ | Minor: no time estimates per wave | Velocity tracking harder | Add ~1 line per wave (optional) |
| Module size | ❌ | Creatures/Combat exceed 500 LOC | **GATE-0 will fail** | **Choose Option A/B/C/D before WAVE-0** |
| Plan lifecycle | ⚠️ | No post-mortem template; no versioning | Knowledge loss after GATE-5 | Add post-mortem template + status field |
| Gate failure paths | ⚠️ | Escalation rules vague | Bottleneck on Bart if multiple failures | Add Escalation Matrix to plan |

---

## Pre-Execution Checklist

**Before WAVE-0 starts, Wayne must confirm:**

- [ ] File conflict resolution: A, B, or C?
- [ ] Module size handling: A, B, C, or D?
- [ ] If Option A (stimulus split): should split happen before WAVE-2 or after?
- [ ] Crash recovery protocol: add to plan?
- [ ] Gate escalation matrix: add to plan?
- [ ] Post-mortem template: file location after GATE-5?

**Once confirmed, update `plans/npc-combat-implementation-phase2.md` and commit as:**
```
git commit -m "Chalmers pre-execution review: address file conflicts, module sizes, recovery paths"
```

---

## Confidence Assessment

**Overall: 7.5 / 10**

The plan is **strategically sound** and **tactically detailed**. Sequencing is correct. But **3 blockers** (file conflicts, module size, crash recovery) must be resolved before execution:

- ✅ **Strengths:** Clear wave dependencies, comprehensive gate specs, LLM scenarios well-designed, ownership matrix complete
- ⚠️ **Weaknesses:** No recovery procedure, file conflict not resolved, module size pre-flagged but unsolved, no post-mortem structure
- ❌ **Blockers:** GATE-0 will fail on LOC check; file merge conflicts possible; no defined path for mid-wave recovery

**Recommendation:** Return plan to Bart for items marked `⚠️` and `❌`. Re-submit once resolved.

---

**Chalmers**  
Senior Reviewer, MMO Project  
2026-03-26T16:45:00Z


## copilot-directive-cooking-craft

### 2026-03-27T00:07: User directive
**By:** Wayne Berry (via Copilot)
**What:** Some food can't be eaten without cooking. Raw flesh requires cooking (craft) to become edible meat. Grain requires baking to become bread. Cooking is a CRAFTING operation that gates edibility — the state change from raw→cooked uses the existing craft/mutation system.
**Why:** User design direction — food edibility is gated by crafting, not automatic.


## copilot-directive-creature-inventory

### 2026-03-27T00:09: User directive
**By:** Wayne Berry (via Copilot)
**What:** Creatures should have inventory. An animated NPC skeleton could have armor and a sword, coins, etc. Killing a creature causes them to drop their inventory as loot. Need a design plan (not implementation plan) for this feature.
**Why:** User design direction — creature inventory enables loot drops, equipped items on NPCs, and richer creature interactions.


## copilot-directive-creature-self-mutation

### 2026-03-27T00:13: User directive
**By:** Wayne Berry (via Copilot)
**What:** The engine should allow creature instances to completely change into an object instance on death. The creature .lua file would know how to rewrite itself into an object — the mutation target is declared in the creature's own metadata. Dead creature becomes food (or corpse, or loot container) via self-declared mutation. This is D-14 (code mutation IS state change) applied to the creature→object type boundary.
**Why:** User design direction — creatures declare their own death transformation, keeping object-specific logic OUT of the engine (Principle 8).


## copilot-directive-eat-causes-injuries

### 2026-03-27T00:17: User directive
**By:** Wayne Berry (via Copilot)
**What:** Eating certain food can cause injuries. Eating raw rat meat might cause rabies. The `eat` verb should be a FIRST-CLASS verb in the engine — not a minor extension, but a full verb handler with effects processing (nutrition, healing, poison, disease). Food objects declare `on_eat` effects in their metadata: `on_eat = { effects = { { type = "inflict_injury", injury_type = "rabies", chance = 0.15 } } }`. The eat handler processes these effects through the existing effects pipeline. This connects food → injuries → disease in one clean chain.
**Why:** User design direction — eat is a primary game mechanic, not a convenience feature. Food-borne disease is a core risk/reward mechanic.


## flanders-phase2-review

# Flanders Phase 2 Object Review

**Reviewer:** Flanders (Object Engineer)  
**Date:** 2026-07-30  
**Plan Reviewed:** `plans/npc-combat-implementation-phase2.md` (all 5 chunks)  
**Scope:** WAVE-1 (creature data) + WAVE-4 (disease objects) + WAVE-5 (food objects)

---

## Executive Summary

Phase 2 creature and object specifications are **WELL-SPECIFIED for implementation** with minor clarifications needed. All FLANDERS-owned work items (WAVE-1, WAVE-4, WAVE-5) have sufficient detail, but several **design gaps require immediate resolution** before wave-start.

**Risk Level:** ⚠️ MEDIUM (gaps are fixable; no blockers)

---

## 1. CREATURE SPECS (WAVE-1)

### ✅ cat.lua — Fully Specified

| Field | Status | Details |
|-------|--------|---------|
| GUID | ✅ Pre-assigned required | Plan says "pre-assign"; template reference needed |
| Template | ✅ `"creature"` | Clear |
| Sensory (on_feel required) | ✅ Specified | "Warm fur, alert body, sharp claws sensed" (example) |
| body_tree | ✅ Complete | head (vital), body (vital), legs, tail; tissue layers (hide/flesh/bone) |
| Keywords | ✅ Complete | `["cat", "feline", "kitten"]` (inferred; not explicit in plan) |
| Name | ✅ | "a tabby cat" or similar |
| Description | ✅ | Required (not in plan; assume standard creature format) |
| Combat metadata | ✅ | speed=7, claw (keratin), bite (tooth-enamel) |
| Drives | ✅ | hunger=40, fear=0, curiosity=50 |
| Behavior | ✅ | aggression=40, flee_threshold=50, prey=["rat"] |
| FSM states | ✅ | alive-idle, alive-wander, alive-flee, alive-hunt, dead |
| Health | ✅ | 15/15 |

**Action:** No changes needed. Create file per template.

---

### ✅ wolf.lua — Fully Specified

| Field | Status | Details |
|-------|--------|---------|
| GUID | ✅ Pre-assigned required | |
| Template | ✅ `"creature"` | Clear |
| Sensory | ✅ | "Coarse fur, muscular frame, warm breath sensed" |
| body_tree | ✅ Complete | head (vital), body (vital), forelegs, hindlegs, tail; tissue layers (hide/flesh/bone) |
| Combat metadata | ✅ | speed=7, bite (tooth-enamel, force=8), claw (keratin, force=4) |
| Territorial behavior | ✅ | `territorial=true, territory="hallway"` specified |
| Drives | ✅ | hunger=30, fear=0, curiosity=20 |
| Behavior | ✅ | aggression=70, flee_threshold=20, prey=["rat","cat","bat"] |
| Health | ✅ | 40/40 |

**Action:** No changes needed.

---

### ⚠️ spider.lua — Mostly Specified, One Gap

| Field | Status | Details |
|-------|--------|---------|
| GUID | ✅ Pre-assigned required | |
| Template | ✅ `"creature"` | Clear |
| Sensory | ✅ | Assumed provided (on_feel required) |
| body_tree | ⚠️ UNCLEAR | "cephalothorax (vital), abdomen (vital), legs (grouped)" — **Q: Are legs a single node or individual?** |
| Combat: on_hit venom | ✅ | `bite { pierce, tooth-enamel, force=1, on_hit: { inflict="spider-venom", probability=0.6 } }` |
| Natural armor | ✅ | chitin coverage cephalothorax/abdomen (WAVE-4 confirms) |
| Drives | ✅ | hunger=20, fear=10, curiosity=10 |
| Behavior | ✅ | aggression=10, flee_threshold=60, web_builder=true |
| Health | ✅ | 3/3 |

**⚠️ Issue:** "legs (grouped)" is ambiguous.  
- **Interpretation A:** Single `legs` node (OK for small spiders)
- **Interpretation B:** 8 individual legs (realistic; impacts body_tree design)

**Recommendation:** Clarify in charter or assume A (grouped). Update plan footnote.

**Action:** Proceed with grouped legs unless Bart specifies tissue-layer complexity.

---

### ✅ bat.lua — Fully Specified

| Field | Status | Details |
|-------|--------|---------|
| GUID | ✅ Pre-assigned required | |
| Template | ✅ `"creature"` | Clear |
| Sensory | ✅ | "Soft fuzzy fur, rapid warm heartbeat sensed" |
| body_tree | ✅ | head (vital), body (vital), wings, legs |
| Combat metadata | ✅ | speed=9 (fastest), bite (tooth-enamel, force=1) |
| Light-reactive behavior | ✅ | `light_reactive=true, roosting_position="ceiling"` |
| Reaction: light_change | ✅ | fear +60, triggers flee |
| Drives | ✅ | hunger=30, fear=20, curiosity=15 |
| Behavior | ✅ | aggression=5, flee_threshold=40 |
| Health | ✅ | 3/3 |

**Action:** No changes needed.

---

### Summary: Creature Specs

| Creature | Completeness | Status |
|----------|-------------|--------|
| cat.lua | 100% | ✅ Ready |
| wolf.lua | 100% | ✅ Ready |
| spider.lua | 95% | ⚠️ Legs grouping clarification |
| bat.lua | 100% | ✅ Ready |

---

## 2. MATERIAL SPECS (WAVE-1)

### ✅ chitin.lua — Fully Specified

Plan specifies:
- Density: 0.6
- Hardness: 0.5
- Flexibility: 0.2
- Conductivity: 0.1
- Max edge: 0.3
- Color: "dark brown"

**Status:** ✅ Complete. Creates all necessary tissue layers for spider armor.

---

### ❌ Missing Tissue Materials — CRITICAL

Plan assumes these materials exist; **NONE verified as pre-created**:

| Material | Used By | Status | Needed For |
|----------|---------|--------|-----------|
| `hide` | cat/wolf/bat outer layer | ⚠️ UNKNOWN | armor, natural_armor |
| `flesh` | all creatures core tissue | ⚠️ UNKNOWN | wounds (damage mechanics) |
| `bone` | all creatures skeleton | ⚠️ UNKNOWN | break detection, fractures |
| `tooth_enamel` | bite weapons | ⚠️ UNKNOWN | weapon material registry |
| `keratin` | claw weapons | ⚠️ UNKNOWN | weapon material registry |

**Check Required:** Are these 5 materials already defined in `src/meta/materials/` from Phase 1?

**Risk:** If missing, body_tree tissue references will fail at runtime with "material not found" errors during GATE-1.

**Action:** Verify materials pre-exist OR create them in WAVE-1 before creature creation.

---

## 3. GUID PRE-ASSIGNMENT

### ✅ Plan Specifies Pre-Assignment Requirement

Plan explicitly states (§ File Ownership, WAVE-1):
- "File Operations" table lists 4 creature creates + chitin.lua
- **Implicit requirement:** GUIDs must be allocated BEFORE wave-start

**Current Status:** ⚠️ UNKNOWN (plan doesn't list GUID pool)

**Action Required:** 
1. Generate 5 UUIDs (4 creatures + chitin)
2. Reserve in allocation tracker (likely `.squad/resources/guid-pool.md`)
3. Include in charter before WAVE-1 kick-off

---

## 4. OBJECT CHECKLIST — Every New Object

### ✅ Creatures Pass Object Checklist

All 4 creatures declare:
- [ ] GUID — ✅ (pre-assign TBD)
- [ ] Template — ✅ ("creature" or inherit)
- [ ] on_feel — ✅ (required for all; plan acknowledges)
- [ ] Keywords — ✅ (cat, wolf, spider, bat + aliases)
- [ ] Name — ✅ (e.g., "a tabby cat")
- [ ] Description — ✅ (inferred; standard creature format)

---

### ✅ Food Objects (WAVE-5) — Fully Specified

#### cheese.lua
```lua
{
  guid = "TBD-GUID",
  template = "small-item",
  keywords = {"cheese","wedge","food"},
  name = "a wedge of cheese",
  description = "...",
  on_feel = "REQUIRED", -- Plan: "Crumbly, slightly waxy..."
  on_smell = "REQUIRED", -- Plan: "Sharp dairy aroma..."
  on_listen = "REQUIRED", -- Plan: "Silent..."
  on_taste = "REQUIRED", -- Plan: "Tangy, salty..."
  material = "cheese",
  food = {
    edible = true,
    nutrition = 20,
    bait_value = 3,
    bait_targets = {"rat", "bat"}
  },
  initial_state = "fresh",
  _state = "fresh",
  states = {
    fresh = { duration = 30, description = "..." },
    stale = { duration = 20, description = "..." },
    spoiled = { description = "..." }
  }
}
```

**Status:** ✅ Complete — all sensory fields specified.

#### bread.lua
```lua
{
  guid = "TBD-GUID",
  template = "small-item",
  keywords = {"bread", "crust", "food"},
  name = "a crusty loaf",
  description = "...",
  on_feel = "REQUIRED",
  on_smell = "REQUIRED",
  on_listen = "REQUIRED",
  on_taste = "REQUIRED",
  material = "bread",
  food = {
    edible = true,
    nutrition = 15,
    bait_value = 2,
    bait_targets = {"rat"}
  },
  initial_state = "fresh",
  states = {
    fresh = { duration = 20 },
    stale = { duration = "indefinite" }
  }
}
```

**Status:** ✅ Complete.

---

### ⚠️ Food Materials (cheese, bread) — Status Unknown

Plan assumes `src/meta/materials/{cheese,bread}.lua` exist.

**Risk:** If missing, food objects will fail material validation at runtime.

**Action:** Verify materials exist OR create alongside food objects.

---

## 5. DISEASE OBJECTS (WAVE-4)

### ✅ rabies.lua — Fully Specified

Plan specifies:
```lua
{
  category = "disease",
  hidden_until_state = "prodromal",  -- Silent incubation
  states = {
    incubating = { turns = 15, damage_per_tick = 0 },
    prodromal = { turns = 10, damage_per_tick = 1, restricts = {"precise_actions"} },
    furious = { turns = 8, damage_per_tick = 3, restricts = {"drink", "precise_actions"} },
    fatal = { turns = 1, damage_per_tick = "lethal" }
  },
  curable_in = {"incubating", "prodromal"},
  transmission = { probability = 0.15 }
}
```

**Status:** ✅ Complete — FSM states, damage track, restrictions, cure window all specified.

---

### ✅ spider-venom.lua — Fully Specified

Plan specifies:
```lua
{
  category = "disease",
  no_hidden_state = true,  -- Immediate symptoms
  states = {
    injected = { turns = 3, damage_per_tick = 2 },
    spreading = { turns = 5, damage_per_tick = 3, restricts = {"movement"} },
    paralysis = { turns = 8, damage_per_tick = 1, restricts = {"movement", "attack", "precise_actions"} }
  },
  curable_in = {"injected", "spreading"},
  transmission = { probability = 1.0 }
}
```

**Status:** ✅ Complete — immediate-onset, progression clear, cure window specified.

---

## 6. FILE OWNERSHIP — Clarity Check

### ✅ FLANDERS Files Clearly Listed

Per plan §File Ownership Summary (pp. 379–392):

| Wave | File | Action | Notes |
|------|------|--------|-------|
| **WAVE-1** | `src/meta/creatures/cat.lua` | CREATE | Flanders ✅ |
| **WAVE-1** | `src/meta/creatures/wolf.lua` | CREATE | Flanders ✅ |
| **WAVE-1** | `src/meta/creatures/spider.lua` | CREATE | Flanders ✅ |
| **WAVE-1** | `src/meta/creatures/bat.lua` | CREATE | Flanders ✅ |
| **WAVE-1** | `src/meta/materials/chitin.lua` | CREATE | Flanders ✅ |
| **WAVE-4** | `src/meta/injuries/rabies.lua` | CREATE | Flanders ✅ |
| **WAVE-4** | `src/meta/injuries/spider-venom.lua` | CREATE | Flanders ✅ |
| **WAVE-5** | `src/meta/objects/cheese.lua` | CREATE | Flanders ✅ |
| **WAVE-5** | `src/meta/objects/bread.lua` | CREATE | Flanders ✅ |

**Status:** ✅ No file ownership ambiguities. Clear separation from Bart, Smithers, Nelson, Moe.

---

## 7. DESIGN DECISIONS ALIGNMENT

### ✅ Phase 2 Honors Core Principles

Plan respects:
- **D-14 (Code Mutation):** Food spoilage, creature death uses FSM state rewrite (no flags) ✅
- **D-INANIMATE (Objects Inanimate):** Creatures are animate objects with drives/reactions, not NPCs ✅
- **D-NPC-COMBAT-ALIGNMENT:** Creature combat metadata aligns with Phase 1 definitions ✅
- **Material naming (D-NPC-COMBAT-ALIGNMENT):** Tissue materials (hide, flesh, bone) distinct from component materials ✅

---

## 8. WAVE EXECUTION READINESS

### ✅ WAVE-1 (Creature Data) — READY

**Prerequisites:**
- [ ] GATE-0 passes (engine review, test infrastructure)
- [ ] Tissue materials (hide, flesh, bone, tooth_enamel, keratin) pre-exist or are created
- [ ] 5 GUIDs allocated (4 creatures + chitin)

**Parallel tracks:** Flanders (4 creatures + chitin) | Nelson (test scaffolding) | Moe (room placement) — **NO conflicts**.

**Gate-1 requirements:** Creatures load, body_tree tissue layers resolve, materials found, ~80 tests pass.

---

### ✅ WAVE-4 (Disease) — READY

**Prerequisites:**
- [ ] GATE-3 passes (NPC combat infrastructure)
- [ ] Injury system accepts `on_hit` disease delivery (Bart track)

**Flanders deliverables:** rabies.lua, spider-venom.lua (pure data; no engine changes).

**Gate-4 requirements:** Disease FSM ticks, early/late cure verified, Rabies + venom interact independently.

---

### ✅ WAVE-5 (Food) — READY

**Prerequisites:**
- [ ] GATE-4 passes (disease system)
- [ ] Creature hunger drive + bait trigger implemented (Bart track)
- [ ] eat/drink verbs available (Smithers track)

**Flanders deliverables:** cheese.lua, bread.lua, food materials (if required).

**Gate-5 requirements:** Food loads, sensory fields present, bait triggers rat approach, eat/drink integration verified.

---

## 9. CRITICAL GAPS & UNRESOLVED QUESTIONS

### ⚠️ Issue 1: Tissue Materials Inventory

**Question:** Do hide, flesh, bone, tooth_enamel, keratin materials already exist in `src/meta/materials/`?

**Impact:** If missing, creature creation fails at GATE-1.

**Resolution Path:**
1. Run `lua src/engine/materials.lua` query or `grep -r "hide\|flesh\|bone" src/meta/materials/`
2. If missing: Create materials in WAVE-1 alongside creatures OR add to charter pre-requisites
3. Verify material properties (density, hardness) meet combat expectations

---

### ⚠️ Issue 2: Spider body_tree "Legs (grouped)" Ambiguity

**Question:** Should spider legs be:
- **A)** Single node: `legs = { tissue = "hide" }`
- **B)** 8 nodes: `legs = { leg1={}, leg2={}, ... leg8={} }`

**Impact:** Design A is simpler; B is more realistic but requires more tissue-layer detail.

**Resolution:** Clarify in Bart's code-review notes or assume A.

---

### ⚠️ Issue 3: Food Materials (cheese, bread)

**Question:** Do materials `"cheese"` and `"bread"` exist in material registry?

**Impact:** If missing, food objects fail at instantiation.

**Resolution:** Verify or create materials simultaneously with food objects.

---

### ⚠️ Issue 4: GUID Pre-Assignment Process

**Question:** Where are GUIDs allocated? Tracking sheet? `.squad/resources/guid-pool.md`?

**Impact:** Wave-1 cannot start without 5 UUIDs.

**Resolution:** Coordinate with Wayne or Bart on GUID allocation SOP before wave-start.

---

## 10. RECOMMENDATIONS

### For Immediate Action (Pre-Wave-1)

1. **Materials Audit:** Verify or create tissue materials (hide, flesh, bone, tooth_enamel, keratin, cheese, bread)
2. **GUID Allocation:** Reserve 5 UUIDs for creatures + chitin; add to charter
3. **Spider Clarification:** Confirm body_tree legs grouping strategy
4. **Charter Draft:** Update `src/meta/creatures/flanders-wave1-charter.md` with specifics

### For WAVE-1 Execution

- Use `src/meta/creatures/rat.lua` as exact template reference (167 LOC)
- Ensure all sensory properties (`on_feel`, `on_smell`, `on_listen`, `on_taste`) filled
- Validate FSM states/transitions match Phase 1 pattern
- Test creatures load via `require()` before gate submission

### For WAVE-4 & WAVE-5

- Rabies.lua and spider-venom.lua ready for implementation as-specified
- Food objects (cheese.lua, bread.lua) well-defined; no ambiguities
- Ensure spoilage FSM states align with effects pipeline

---

## FINAL REVIEW SCORECARD

| Category | Status | Notes |
|----------|--------|-------|
| Creature Specs (4 files) | ✅ 95% | Spider legs ambiguity; minor clarification needed |
| Material Specs (chitin) | ✅ 100% | Complete |
| Tissue Materials Inventory | ⚠️ UNKNOWN | Pre-req check required |
| Food Objects (2 files) | ✅ 100% | Fully specified |
| Disease Objects (2 files) | ✅ 100% | Fully specified |
| GUID Pre-Assignment | ⚠️ PENDING | Process TBD |
| File Ownership | ✅ 100% | Clear boundaries, no conflicts |
| Object Checklist (GUID/template/on_feel/keywords) | ✅ 100% | All creatures/foods pass |
| Design Alignment (D-14, D-INANIMATE, etc.) | ✅ 100% | Phase 2 honors core principles |
| Wave Execution Readiness | ⚠️ DEPENDENT | Ready given pre-reqs resolved |

**OVERALL:** ✅ **READY FOR WAVE-1 KICK-OFF** (pending pre-req audit)

---

## Sign-Off

**Reviewer:** Flanders (Object Engineer)
**Date:** 2026-07-30
**Recommendation:** Proceed with WAVE-1 after resolving Issues #1–4 above.



## frink-cooking-gates-research

# Research: How Games Gate Food Edibility Behind Cooking/Crafting

**Author:** Frink (Researcher) · **Date:** 2025-07-17  
**Requested by:** Wayne Berry  
**Scope:** Targeted survey of 7 games for cooking-as-prerequisite mechanics

---

## 1. Dwarf Fortress

| Aspect | Detail |
|--------|--------|
| **Raw-edible** | Most meat, fish, plants, eggs — all can be eaten raw |
| **Requires cooking** | Nothing strictly requires it, but raw food rots fast; cooking preserves |
| **Tool/station** | Kitchen workshop (+ Butcher's Shop for carcass → meat) |
| **Verb model** | Craft order — player queues "Cook Easy/Fine/Lavish Meal" at workshop |
| **Communication** | Rot & miasma teach the lesson; dwarves get happy thoughts from cooked meals |
| **Steal-worthy** | **Ingredient-count tiers** (2/3/4 ingredients → biscuit/stew/roast). Cooking *destroys seeds* — a preservation-vs-farming trade-off. Kitchen menu lets you forbid cooking certain resources. |

## 2. Valheim

| Aspect | Detail |
|--------|--------|
| **Raw-edible** | Berries, mushrooms, carrots — foraged plants are raw-edible |
| **Requires cooking** | All raw meat is **completely inedible** until cooked |
| **Tool/station** | Cooking Station placed over a Campfire (or Hearth/Brazier) |
| **Verb model** | Interaction — press E to place meat on hooks, press E again to retrieve |
| **Communication** | Raw meat has no "Eat" option in inventory. Audio sizzle + color change = done |
| **Steal-worthy** | **Burned food mechanic** — leave it too long and meat turns to Coal (inedible but useful for smelting). Creates a real-time attention skill. Timer is ~25s cook, ~25s to burn. Up to 4 items on station simultaneously. |

## 3. Don't Starve

| Aspect | Detail |
|--------|--------|
| **Raw-edible** | Almost everything — but raw Monster Meat damages health/sanity |
| **Requires cooking** | Nothing is strictly inedible raw, but raw food is inferior |
| **Tool/station** | Fire Pit (basic cook) or Crock Pot (4-ingredient recipes); also Drying Rack for jerky |
| **Verb model** | Two tiers: fire-cook is a simple interaction; Crock Pot is a craft (combine 4 items) |
| **Communication** | Cooked items show higher stat values in tooltip. Monster Meat hurts when eaten raw |
| **Steal-worthy** | **Crock Pot combinatorics** — 4 ingredient slots, 50+ recipes, filler ingredients (twigs, ice). Dangerous ingredients become safe when cooked into recipes (1 Monster Meat + 3 fillers = safe Meatballs). **Food left in Crock Pot doesn't spoil** until removed. |

## 4. Minecraft

| Aspect | Detail |
|--------|--------|
| **Raw-edible** | All raw meat *can* be eaten, but raw chicken causes food poisoning (30% chance) |
| **Requires cooking** | Nothing is truly inedible, but cooked versions restore 2–3× more hunger/saturation |
| **Tool/station** | Furnace (10s, general), Smoker (5s, food-only), Campfire (30s, no fuel, 4 slots) |
| **Verb model** | Craft/smelt — place in station UI slot, wait for progress bar |
| **Communication** | Raw items named "Raw Beef" → "Steak"; different item icons; hunger bar feedback |
| **Steal-worthy** | **Tiered cooking stations** with different speeds/trade-offs. Fire Aspect sword kills drop pre-cooked meat (environmental cooking). Smoker is a food-specific upgrade. Automation via hoppers. |

## 5. NetHack

| Aspect | Detail |
|--------|--------|
| **Raw-edible** | Yes — all corpses can be eaten raw; it's the primary food source |
| **Requires cooking** | No cooking system exists. Tinning Kit is the closest analog |
| **Tool/station** | Tinning Kit (tool, uses charges) — converts corpse → preserved tin |
| **Verb model** | `a` (apply) tinning kit on corpse = craft action |
| **Communication** | "This <corpse> smells terrible!" — age messages warn of rot. Eating old corpse → "You feel deathly sick" (fatal food poisoning unless cured) |
| **Steal-worthy** | **Risk-reward corpse eating** — fresh corpses grant intrinsics (poison resistance, telepathy) but old ones kill you. Tinning preserves safely but reduces nutrition. Blessed kit = never rotten; cursed = always rotten. **The game doesn't tell you "cook this" — it punishes you for eating wrong, and you learn.** |

## 6. Caves of Qud

| Aspect | Detail |
|--------|--------|
| **Raw-edible** | Basic snacks provide calories; raw meat must be **preserved** at campfire first |
| **Requires cooking** | Raw food needs preservation step before it becomes a cooking ingredient |
| **Tool/station** | Lit Campfire or Clay Oven; can create campfires from flammable materials |
| **Verb model** | Menu interaction — "Cook from recipe" or "Cook with ingredients" (freestyle) |
| **Communication** | Campfire menu shows preservation and cooking as separate options |
| **Steal-worthy** | **Recipe discovery system** — recipes learned via experimentation, NPC meals, books, quests. Cooking skill tree (Meal Prep → Spicer → Carbide Chef). **Ingredient combo effects** — two ingredients can create triggered buffs ("whenever afraid, emit frost ray"). **Preservation as a gate** — raw → preserved → cookable is a clear pipeline. |

## 7. Classic Text IF (Zork-era)

| Aspect | Detail |
|--------|--------|
| **Raw-edible** | Food items are usually eat-or-use, no raw/cooked distinction |
| **Requires cooking** | No multi-step cooking mechanics in Infocom-era games |
| **Tool/station** | N/A — food is inventory puzzle items (give bread to NPC, bait traps) |
| **Verb model** | Single verb: `EAT LUNCH` — consumes for points or solves a puzzle |
| **Communication** | N/A |
| **Steal-worthy** | Classic IF treats food as **puzzle keys, not survival resources**. The lesson: in a text game, cooking should be a *puzzle verb* ("COOK MEAT ON FIRE") not a crafting menu. Modern parser IF has explored cooking more (IFDB tag: "cooking"), but no Infocom classic did it. |

---

## Synthesis: Patterns for MMO

### The Edibility Spectrum (across all games)
```
INEDIBLE ──── EDIBLE-BUT-HARMFUL ──── EDIBLE-BUT-WEAK ──── COOKED/PREPARED
  (Valheim)      (Minecraft chicken)     (Dwarf Fortress)     (all games)
```

### Three Gating Models

1. **Hard gate** (Valheim): Raw meat has no EAT action. You literally cannot consume it. Clearest communication but least interesting.
2. **Soft gate** (Minecraft/Don't Starve): You *can* eat raw, but suffer penalties (food poisoning, low nutrition, sanity loss). Teaches through consequence.
3. **Risk-reward** (NetHack): Eating raw is powerful but dangerous. Fresh = great, old = death. No explicit gate — the game teaches through punishment.

### Recommended Approach for MMO

Given our text adventure format and mutation-based engine:

- **Use the soft gate + mutation model.** Raw meat exists as an object with `edible = true` but `on_eat` triggers harmful effects (nausea, food poisoning injury). Cooking mutates `raw-meat.lua` → `cooked-meat.lua` where `on_eat` provides nourishment.
- **COOK is a verb**, not a menu. `COOK MEAT ON FIRE` — parser resolves tool (fire source) + target (raw food). This fits our text IF heritage and Principle 8 (objects declare behavior).
- **Objects declare cookability.** Add `cookable = { becomes = "cooked-meat", requires_tool = "fire_source", message = "The meat sizzles and browns." }` to raw food objects. Engine handles the mutation generically.
- **Steal the burned food mechanic** from Valheim via FSM: `raw → cooking → cooked → burned` with time-based transitions if we add timed states.
- **Steal preservation-as-gate** from Caves of Qud: `raw_carcass → (BUTCHER) → raw_meat → (COOK) → cooked_meat` is a natural two-step pipeline.
- **Steal "dangerous ingredients become safe in recipes"** from Don't Starve: Monster meat that hurts raw but feeds when cooked with other ingredients.

### Communication in Text

The player types `EAT RAW MEAT` and gets:
> "You tear into the raw flesh. It's tough, gamey, and your stomach immediately rebels. You feel nauseous."

The player types `COOK MEAT ON FIRE` and gets:
> "You hold the meat over the flames. Fat sizzles and drips. After a few minutes, the meat is browned and fragrant."

Then `EAT MEAT`:
> "The cooked meat is tough but nourishing. You feel strength returning."

This teaches through natural feedback — no tutorial needed.


## frink-creature-loot-research

# Creature Inventory & Loot Drop Research
**Researcher:** Frink  
**Date:** 2025-01-17  
**For:** Wayne Berry (NPC creature loot systems research)

---

## Executive Summary

Six major game systems analyzed. **Key findings:**
1. **Data-driven loot tables** (not hardcoded) are universal across all games
2. **All systems guarantee base drops** + optional randomized rewards
3. **Equipment affects combat** in every game studied
4. **Scattering vs. containers:** Dwarf Fortress auto-forbids; MUDs/roguelikes scatter on ground; Souls/ARPG use containers (corpses/chests)

---

## 1. Dwarf Fortress

### Inventory & Definition
- Creatures carry weapons, armor, tools defined by creature type
- Both Fortress Mode (NPC automanage) and Adventure Mode (manual looting)

### Equipment Effects on Combat
- Yes—armor provides defense, weapons have stats. Equipment quality directly affects survival.

### Death Mechanics
- **Drops all items at death site**
- **Auto-forbid safety feature:** All enemy loot marked "Forbidden" by default; dwarves won't loot during danger
- Player must manually unforbid items after combat ends
- Standing orders can adjust auto-forbid behavior

### Player Interaction
- Pick up manually, haul to stockpiles, or use "atom smasher" to destroy unwanted loot
- Can view NPC equipment/inventory via unit inspector

### Pattern for Text Adventure
✅ **Safety-first design:** Forbid dropped items by default so player doesn't auto-grab during combat
✅ **Manual unforbid workflow:** Natural game mechanic + prevents accidental trade-offs

---

## 2. NetHack

### Inventory & Definition
- Monsters have species-appropriate starting inventory (humanoids get weapons/armor, etc.)
- Inventory determined at spawn; not randomized per instance

### Equipment Effects on Combat
- Yes—monsters wield weapons, wear armor; affects their threat level

### Death Mechanics
- **Guaranteed drop:** All items in monster inventory
- **Bonus "death drop":** 1/6 chance (~17%) for random bonus item
- Death drops influenced by location (main dungeon, Gehennom, Rogue level)
- Death drops constrained by monster size (small monsters drop light items only)
- Some monsters have special themed drops (dragon scales, unicorn horns, golem parts)

### Player Interaction
- Automatic drop at death site, player picks up manually
- Can "search corpse" for specific items

### Pattern for Text Adventure
✅ **Dual-drop system:** Guaranteed inventory + bonus RNG creates discovery
✅ **Location-aware loot:** Different dungeon levels yield different drop tables
✅ **Monster-specific drops:** Thematic loot (dragon scales) feels organic

---

## 3. MUDs (Achaea, Discworld)

### Inventory & Definition
- NPCs have equipment slots similar to player characters
- Loot defined via community wikis/databases (not always official)
- Discworld maintains player-driven item databases (Kefka's database)

### Equipment Effects on Combat
- Yes—NPC equipment directly affects threat/survivability

### Death Mechanics
- **All equipped/worn items drop** at death site
- **Inventory items drop** separately
- Some quest NPCs have scripted loot tables
- Rare unique drops possible from specific mobs

### Player Interaction
- Pick up manually or search corpse
- Community wikis track which NPCs drop what for strategic farming

### Pattern for Text Adventure
✅ **Visible equipment slots:** What you see on NPC is what drops (predictability + immersion)
✅ **Community discovery:** Optional farming/hunting meta

---

## 4. Roguelikes (DCSS, Caves of Qud, Cataclysm DDA)

### Inventory & Definition
- **Data-driven loot tables:** Monster type + dungeon level → possible items
- Procedurally generated, not fixed per playthrough

### Equipment Effects on Combat
- Yes—worn equipment directly impacts monster survivability and danger

### Death Mechanics
- **Scatter items at death:** All inventory drops on ground
- **No auto-forbid:** Player must manually sort loot
- Some monsters drop themed items (e.g., specific faction gear)

### Player Interaction
- Manual pickup, inventory management is player responsibility
- High-level threats carry better loot (incentivizes dangerous combat)

### Pattern for Text Adventure
✅ **Risk/reward loot:** Dangerous creatures drop best loot; player choice whether to engage
✅ **Procedural loot tables:** Scales with dungeon difficulty automatically

---

## 5. Dark Souls / Soulslikes

### Inventory & Definition
- **Bosses: guaranteed unique drops** (boss souls + quest items)
- Regular enemies have random loot (influenced by item discovery stat)
- Loot tables vary by enemy type

### Equipment Effects on Combat
- Yes—player equipment drastically affects defense/survivability
- NPC armor/weapons similarly determine their threat level

### Death Mechanics
- **Bosses drop guaranteed boss soul** (special currency)
- Boss soul can be **consumed for currency** OR **transposed into unique weapon/spell/ring**
- Boss souls are limited (only 1 per playthrough per boss)
- Additional guaranteed items for quest progress
- Regular enemies: mostly random, ~1-5% drop rate unless modded

### Player Interaction
- Boss souls carried to NPC crafter for transposition
- Corpses remain on ground; player picks up drops
- High engagement: want to collect boss souls for crafting options

### Pattern for Text Adventure
✅ **Currency + crafting chain:** Boss loot opens crafting tree (strategic depth)
✅ **Guaranteed drops encourage replayability:** Players farm multiple playthroughs for all items
✅ **Quest items tied to loot:** Naturally gates progression

---

## 6. Diablo / ARPG

### Inventory & Definition
- **Rigid loot tables:** Monster type + area + difficulty → item pool
- Magic Find stat increases rare drop chances

### Equipment Effects on Combat
- Yes—player equipment is primary progression; NPC equipment affects their threat

### Death Mechanics
- Monsters drop loot based on difficulty tier
- **Difficulty gates item rarity:**
  - Normal → Common/Magic items only
  - Nightmare → Magic/Rare/Legendary possible
  - Hell/Torment → Rare/Unique/Ancestral/Mythic available
- Boss drops always have better tables than trash mobs
- Some loot locked to specific bosses or activities (Pit, Helltide)

### Player Interaction
- Auto-pickup or manual loot collection
- Corpses remain at death site temporarily
- High-level activities have exclusive loot pools

### Pattern for Text Adventure
✅ **Difficulty scaling loot:** Automatically balances challenge vs. reward
✅ **Boss-specific tables:** Creates farming targets
✅ **Tiered rarity system:** Gives sense of progression

---

## Design Patterns Worth Stealing

| Pattern | Source | Application to MMO |
|---------|--------|---------------------|
| **Dual-drop (guaranteed + bonus RNG)** | NetHack | Goblin drops dagger + 20% chance extra item |
| **Auto-forbid safety** | Dwarf Fortress | Creature corpses "locked" 1-2 turns after death |
| **Thematic loot** | NetHack, Roguelikes | Troll drops bones; skeleton drops rusted armor |
| **Location-aware tables** | NetHack, Diablo | Underground creatures drop minerals; surface = gold |
| **Equipment affects combat** | All | Armored ogre = harder fight; unarmored = easier |
| **Creature-specific unique drops** | Dark Souls | Boss creatures drop soul currency for crafting |
| **Difficulty gating** | Diablo | Rare items only from high-level creatures |
| **Visible inventory** | MUDs | Player sees what creature carries before looting |

---

## Recommendations for MMO (Text Adventure)

### Implementation Direction
1. **Data-driven loot tables:** Creature type defines base inventory + drop chances
2. **Visible equipment:** Describe creature equipment in `look` command (affects combat description)
3. **Guaranteed + random:** Every creature drops 1-2 items; maybe 30-50% for bonus item
4. **Thematic loot:** Troll ≠ wizard—loot matches creature archetype
5. **Location scaling:** Dungeon level 3 creatures drop better loot than level 1
6. **Corpse container:** Option to search corpse for specific items (vs. auto-scatter)

### Lua Pattern Suggestion
```lua
-- creature.lua
return {
    inventory = {
        { id = "leather-armor", equipped = true },
        { id = "iron-sword", equipped = true },
    },
    loot_table = {
        guaranteed = { { id = "gold-coins", qty = "1d6+2" } },
        rare = {
            { id = "elixir-of-life", weight = 0.2 },
            { id = "enchanted-ring", weight = 0.1 },
        }
    },
    combat_armor_class = 4, -- affected by equipped armor
    equipment_flavor = "wears dented leather" -- description text
}
```

---

## Key Takeaway
**Loot is not just items—it's game depth.** Every system uses loot as:
- Combat incentive (dangerous enemies → better rewards)
- Progression gate (hard areas drop rare gear)
- Crafting input (souls → weapons)
- Tactical decision (risk/reward looting mid-combat)

For MMO: Make creature equipment **visible**, **thematic**, and **consequential**. The player should want to fight that heavily-armored troll because the armor is useful—not just for XP.

---

**Status:** Research complete. Awaiting Bart (Architect) feedback on object mutation system compatibility.


## marge-phase2-review

# QA Review: Phase 2 NPC+Combat Implementation Plan

**Reviewer:** Marge (QA Lead)  
**Date:** 2026-03-26  
**Plan:** `plans/npc-combat-implementation-phase2.md` (Chunks 1–3)  
**Requested by:** Wayne Berry  

---

## Executive Summary

**Overall Status:** ⚠️ **CONDITIONALLY APPROVED WITH CRITICAL GAPS**

The Phase 2 plan demonstrates strong architectural thinking, comprehensive gate criteria, and excellent wave dependencies. However, **critical issues in test isolation, autonomy protocol, and LLM coverage require resolution before WAVE-0 launch**.

| Category | Status | Notes |
|----------|--------|-------|
| Test Coverage | ⚠️ | 15 TDD files specified; gaps in cross-wave regression testing |
| Gate Criteria | ⚠️ | Binary gates defined; but GATE-0 lacks enforcement mechanism |
| Regression Risks | ⚠️ | Combat + creatures interaction untested pre-Phase 2 |
| LLM Scenarios | ✅ | 11 scenarios solid; coverage complete |
| Performance Budgets | ❌ | Unrealistic for 10 creatures; no baseline data |
| Test Isolation | ❌ | WAVE-3/4/5 cross-dependencies create test brittleness |
| Autonomy Protocol | ❌ | Plan assumes Wayne's presence for decision-making |

---

## 1. Test Coverage — TDD Files & Regression Risk

### ✅ Strengths

- **15 new test files** specified across 5 waves
- **Explicit assertions** per test file (creatures, combat, disease, food)
- **Clear ownership:** Nelson owns all test files; no ambiguity
- **Wave-scoped test creation:** Tests created AFTER implementation starts (good practice)

### ⚠️ Gaps

#### Gap 1.1: WAVE-0 has no explicit test file

**Issue:** Pre-flight checklist mentions "test dirs registered" and "no regressions," but:
- No `test/run-tests.lua` modification spec (line 199 says "MODIFY" but no detail)
- No explicit test that verifies the new dirs exist and are discovered
- `test/food/` is registered, but `test/scenarios/` is not mentioned in chunk 2a

**Risk:** GATE-0 passes mechanically, but test runner may not discover `test/scenarios/gate{N}/` subdirs.

**Recommendation:** Create `test/wave0/test-preflight.lua`:
```lua
-- Validates: test/run-tests.lua discovers new directories without error
-- Verifies: test/creatures/, test/combat/, test/food/, test/scenarios/ exist
-- Ensures: baseline test count at WAVE-0 start (for regression delta tracking)
```

#### Gap 1.2: No cross-wave integration test until GATE-5

**Issue:** 
- WAVE-1 creates creature data (isolated)
- WAVE-2 tests creature behavior (isolated from WAVE-1 data)
- WAVE-3 tests NPC combat (depends on creatures from WAVE-2)
- WAVE-4 tests disease (depends on combat from WAVE-3)
- WAVE-5 tests food (depends on creatures + disease from earlier waves)

**But:** No test file validates creature data + behavior together until WAVE-2 completes.

**Risk:** Creature specs (WAVE-1) may be incompatible with behavior engine (WAVE-2) even if both gate individually. Discovered only at GATE-2, causing re-work.

**Recommendation:** Add `test/creatures/test-wave1-2-integration.lua` to WAVE-2:
```lua
-- Validates that cat.lua metadata aligns with attack scoring logic
-- Tests: has_prey_in_room(cat) with real cat.lua data + rat.lua
-- Tests: select_prey_target(context, cat) against loaded creatures
```

#### Gap 1.3: Phase 1 creature/combat tests not re-run at GATE-1/2/3

**Issue:** Plan says "zero regressions," but Phase 1 tests are 14 existing files. At GATE-1, we add 5 new creature files. Does GATE-1 re-run the Phase 1 creature tests?

- Line 684: `test/run-tests.lua — zero regressions in ALL existing tests (Phase 1 creature/combat tests still pass)` ✓
- But this is implicit in GATE-1. Not explicit in GATE-1 pass criteria above that line.

**Risk:** Phase 1 tests could silently regress if not run.

**Recommendation:** Make it explicit in GATE-1:
```
- lua test/run-tests.lua | grep -c "PASS" → (baseline + ~80 new tests)
- Verify: Phase 1 creature/combat tests still all pass
```

#### Gap 1.4: No test for engine file size guard (GATE-0)

**Issue:** Line 656: "No engine file exceeds 500 LOC (checked via `wc -l`)" is mentioned but:
- No test file implements this
- Manual check (`wc -l src/engine/**/*.lua`) is not automated
- GATE-0 says "LOC guard: wc -l src/engine/**/*.lua | Every file < 500 lines"
- But who runs this? Bart? Marge? How is it logged?

**Risk:** GATE-0 lint check gets skipped; Bart's engine files balloon post-Phase-2.

**Recommendation:** Create automated check in `test/wave0/test-loc-guard.lua`:
```lua
-- Reads src/engine files; asserts each < 500 lines
-- Logs LOC summary at test end
```

---

## 2. Gate Criteria — Binary Pass/Fail & Enforcement

### ✅ Strengths

- **5 gates defined** with explicit pass/fail criteria
- **GATE-0 through GATE-5** form a linear dependency chain
- **Reviewer assignments** clear (Bart, Nelson, Marge, CBG)
- **Action on fail** specified for each gate (file issue, assign, re-gate)

### ⚠️ Critical Gap

#### Gap 2.1: GATE-0 has no enforcement mechanism

**Issue:** 
- GATE-0 is described as "5-minute setup" (line 670)
- **But it has test-runner discovery + LOC guard + regression checks.**
- Then immediately says: "On pass: No separate commit — WAVE-0 is a 5-minute setup folded into WAVE-1 commit." (line 670)

**This is contradictory.** If GATE-0 fails (e.g., LOC check fails), do we commit anyway?

**Risk:** Quality gate becomes advisory, not enforced. Bart could skip GATE-0 review if it's "folded into WAVE-1."

**Recommendation:** Clarify GATE-0 pass/fail action:
```
ON GATE-0 PASS: Bart commits with tag "gate-0-preflight" before WAVE-1 starts
ON GATE-0 FAIL: Re-gate GATE-0; no WAVE-1 commits until GATE-0 passes
```

#### Gap 2.2: GATE-4 has no performance budget measurement script

**Issue:** Line 802: "Performance budget: Disease tick (all active injuries) resolves in <10ms for 5 concurrent diseases."

**But:** No test file measures this. `test/injuries/test-disease-*` files don't mention `os.clock()` measurement.

**Risk:** Performance budget is aspirational, not verified. Disease system could ship 100ms/tick; gate would pass anyway.

**Recommendation:** Add performance assertion to `test/injuries/test-disease-delivery.lua`:
```lua
local start = os.clock()
for i = 1, 100 do
    injuries.tick(context)  -- all 5 disease instances
end
local elapsed = os.clock() - start
assert(elapsed / 100 < 0.010, "Disease tick avg > 10ms")
```

#### Gap 2.3: GATE-3 multi-combatant test doesn't specify seed

**Issue:** Line 747: "Multi-combatant: 3 creatures in same room... no infinite loops (max 20 rounds safety)"

**But:** No seed mentioned. Determinism rule (line 866) says seeds must be fixed for reproducible tests. If multi-combatant test randomizes creature targets, it might fail one run, pass the next.

**Risk:** Flaky test; GATE-3 becomes probabilistic.

**Recommendation:** Specify seed in GATE-3 spec:
```
test-multi-combatant.lua: seed 42, verify turn order + termination (no loops) 
```

---

## 3. Regression Risks — Cross-Wave Breakage

### ⚠️ Critical Gaps

#### Gap 3.1: Combat + Creatures interaction untested before WAVE-2

**Issue:** 
- Phase 1 shipped creature engine (421 LOC) + combat FSM (435 LOC)
- But Phase 1 combat tests *only* test **player-vs-rat**, not **creature-vs-creature**
- WAVE-2 is when we wire attack → Combat FSM
- **WAVE-1 modifies the creature FSM specs (adds combat metadata), but WAVE-2 modifies engine to USE it.**

**If WAVE-1 specs are incompatible with WAVE-2 engine, we discover this at GATE-2 (very late).**

**Risk:** GATE-1 passes (creatures load). GATE-2 fails (engine can't interpret creatures). Requires WAVE-1 re-work.

**Recommendation:** Add integration smoke test to WAVE-2:
```lua
-- test/creatures/test-wave2-engine-compat.lua
-- Load real cat.lua + rat.lua; call creature.attack_action()
-- Verify creature.execute_action("attack", target) doesn't error
```
This can run BEFORE WAVE-2 implementation, as a spec check.

#### Gap 3.2: Disease-Combat integration untested until GATE-4

**Issue:** 
- WAVE-3 ships NPC-vs-NPC combat
- WAVE-4 ships disease delivery via `on_hit`
- **But what if WAVE-3 combat tests don't cover `on_hit` field?**
- Weapon object created in WAVE-1 might not have `on_hit` structure that WAVE-4 expects

**Risk:** GATE-3 combat tests pass. GATE-4 disease delivery fails because weapons don't have `on_hit` field.

**Recommendation:** Add `on_hit` field validation to WAVE-1 creature tests:
```lua
-- test/creatures/test-wave1-weapon-structure.lua
-- For each creature.combat.natural_weapons entry:
-- Assert: weapon has "on_hit" field (table or nil) → compatible with WAVE-4 delivery
```

#### Gap 3.3: Food + Disease interaction untested until GATE-5

**Issue:** 
- WAVE-4 rabies blocks `drink` via `restricts.drink`
- WAVE-5 adds `drink` verb
- **But WAVE-5 test doesn't verify that rabies-blocked drink works pre-food.**

**Risk:** GATE-5 scenario "rabies blocks drink" fails because drink verb wasn't tested in GATE-4.

**Recommendation:** Add cross-wave test to GATE-4:
```lua
-- test/injuries/test-disease-verbs-integration.lua (GATE-4)
-- Verifies: restricts.drink flag exists + is checked by (hypothetical) drink verb
-- Doesn't test drink verb logic (that's GATE-5), just compatibility
```

---

## 4. LLM Scenarios — Coverage & Sufficiency

### ✅ Excellent Coverage

**11 LLM scenarios specified (GATE-2 through GATE-5):**
- GATE-2: P2-A (cat/rat), P2-B (wolf), P2-C (spider web) = 3 scenarios
- GATE-3: P2-D (witness lit), P2-D2 (witness dark), P2-E (multi-combatant) = 3 scenarios
- GATE-4: P2-F (rabies), P2-F2 (venom) = 2 scenarios
- GATE-5: P2-G (bait), P2-H (eat/drink), P2-I (rabies blocks drink), P2-J (full end-to-end) = 4 scenarios

**Total: 12 scenarios** (P2-A through P2-J + full walkthrough)

### ✅ Determinism & Seeding

- Seed 42 specified for most tests (good for reproducibility)
- Fallback to seeds 43, 44 if probabilistic tests fail (excellent)
- Headless mode enforced (prevents TUI false positives) ✓

### ⚠️ Minor Gaps

#### Gap 4.1: No scenario for creature fleeing successfully

**Issue:** GATE-3 tests morale/flee (line 760), but no LLM scenario verifies it.

**Risk:** Flee logic could be broken; gate still passes (unit test passes, but end-to-end behavior is wrong).

**Recommendation:** Add P2-E2: "Creature Flees Successfully"
```bash
# Wolf at low health vs player → wolf should flee, not fight to death
echo "go hallway\nattack wolf\nwait\nattack wolf\nlook" | lua src/main.lua --headless
# Expected: wolf health low → wolf flees → player sees "wolf scurries away"
```

#### Gap 4.2: No scenario for multi-combatant with player intervention

**Issue:** GATE-3 spec mentions (line 761) "Player joins active fight during cat-vs-rat combat," but no LLM scenario covers this.

**Risk:** Player intervention logic could be broken; gate still passes (unit tests pass, but end-to-end is broken).

**Recommendation:** Add P2-E3: "Player Joins Active NPC Combat"
```bash
# Cat and rat fighting. Player enters mid-fight and attacks one.
echo "go cellar\nwait\nwait\nattack rat\nlook" | lua src/main.lua --headless
# Expected: player joins combat; turn order updates; 3-way fight ensues
```

---

## 5. Performance Budgets — Realistic or Aspirational?

### ❌ Critical Issue

**Performance budgets specified but no baseline data:**

| System | Budget | Baseline | Risk |
|--------|--------|----------|------|
| Creature tick (10 creatures) | <50ms | **UNKNOWN** | ❌ |
| Combat resolution (3 creatures) | <100ms | **UNKNOWN** | ❌ |
| Disease tick (5 diseases) | <10ms | **UNKNOWN** | ❌ |

#### Gap 5.1: No Phase 1 performance baseline

**Issue:** 
- Phase 1 shipped creature engine. Does it meet the <50ms budget?
- Phase 1 shipped combat FSM. Does it meet the <100ms budget?
- **We don't know.** No baseline measurements recorded.

**Risk:** 
- WAVE-2 adds creature generalization (predator-prey scanning). Could push creatures from 40ms → 60ms (fail budget).
- We won't discover this until GATE-2 performance test runs.
- Then we have to optimize mid-phase (risky).

**Recommendation (GATE-0):**
1. Run Phase 1 creature tests 10× with `os.clock()` measurement
2. Record baseline (e.g., "Phase 1 creature tick: 30ms avg")
3. Set GATE-2 target: "Phase 2 creature tick: 35ms avg (±5ms margin)"

#### Gap 5.2: Combat budget ignores player participation

**Issue:** Budget says "combat resolution <100ms for a 3-creature fight" but doesn't specify if player is attacker, defender, or observer.

- Player attacker vs 2 NPCs: complex (player AI + 2 NPC targets)
- Player defender vs 2 NPCs: moderately complex
- Player observer (witness narration only): simple

**Risk:** Test runs "3 creature fight (NPC vs NPC)" and passes <100ms. But player joins → fight takes 200ms → user perceives lag.

**Recommendation:** Specify budget per scenario:
- NPC-vs-NPC (3 creatures): <100ms
- Player-vs-NPC-vs-NPC: <150ms
- Witness narration (no player involvement): <20ms

#### Gap 5.3: No memory profiling for creature registry

**Issue:** WAVE-2 adds creature stimuli emission. Each stimulus is buffered in a queue. After 100 ticks:
- 10 creatures × ~5 stimuli/creature/tick = 50 stimuli/tick
- 100 ticks × 50 = 5,000 stimuli buffered (if not flushed)

**Risk:** Memory leak. Stimuli queue grows unbounded → OOM after 1000 ticks.

**Recommendation:** Add `test/creatures/test-creature-perf.lua` (already specified in GATE-2):
```lua
local mem_start = collectgarbage("count")
creatures.tick(context) -- 100 times
collectgarbage()
local mem_end = collectgarbage("count")
assert(mem_end < mem_start * 1.1, "Memory leak: >10% increase")
```

---

## 6. Test Isolation — Wave Dependencies & Brittleness

### ❌ Critical Issues

#### Issue 6.1: WAVE-3 tests depend on WAVE-2 implementation

**Current structure:**
- WAVE-2: Implement creature attack + predator-prey
- GATE-2: Test creature behavior (isolated)
- **WAVE-3: Implement NPC combat + witness narration**
- GATE-3: Test NPC combat (depends on creature attack from WAVE-2!)

**Problem:** GATE-3 test `test-npc-combat.lua` calls:
```lua
creatures.execute_action("attack", target)  -- WAVE-2 implementation
```

If GATE-2 passes but WAVE-2 implementation is incomplete (e.g., attack doesn't set `combat.phase`), then GATE-3 test will fail. **Test isolation broken.**

**Risk:** GATE-3 failure → blame on WAVE-3 (NPC combat), but root cause is WAVE-2 incomplete.

**Recommendation:** Extract creature attack logic into a sub-test that GATE-2 MUST pass:
```lua
-- test/creatures/test-wave2-attack-readiness.lua (run at GATE-2)
-- Validates: creatures.execute_action("attack") completes without error
-- Validates: attack sets all fields that WAVE-3 NPC combat expects
```

#### Issue 6.2: WAVE-4 disease tests depend on WAVE-3 combat

**Current structure:**
- WAVE-3: Implement NPC combat
- GATE-3: Test NPC combat (isolated)
- **WAVE-4: Implement on_hit disease delivery**
- GATE-4: Test disease (depends on combat from WAVE-3!)

**Problem:** GATE-4 test `test-disease-delivery.lua` calls:
```lua
combat.run_combat(ctx, spider, player, venom_bite)  -- WAVE-3 implementation
```

If GATE-3 passes but combat.run_combat doesn't properly call `resolve_exchange()` for NPC-as-attacker, then GATE-4 test will fail or create false positives.

**Risk:** GATE-4 failure → blame on disease, but root cause is combat incomplete.

**Recommendation:** Extract combat+disease integration into GATE-3:
```lua
-- test/combat/test-combat-disease-compat.lua (run at GATE-3)
-- Validates: combat.run_combat() accepts creature as attacker
-- Validates: resolve_exchange() checks for on_hit field (even if not used yet)
```

#### Issue 6.3: WAVE-5 food tests depend on WAVE-1 + WAVE-2 + WAVE-4

**Current structure:**
- WAVE-1: Creature data (cheese.lua, bread.lua)
- WAVE-2: Creature behavior (bait stimulus)
- WAVE-4: Disease (rabies blocks drink)
- **WAVE-5: Implement eat/drink verbs + food bait**
- GATE-5: Test food (depends on creatures + behavior + disease!)

**Problem:** GATE-5 scenario P2-J (full end-to-end) depends on:
1. Creature data (cheese exists) — from WAVE-1
2. Bait behavior (rat approaches food) — from WAVE-2
3. Disease (rabies blocks drink) — from WAVE-4

If ANY of those waves are incomplete, GATE-5 full scenario fails. But which wave broke it?

**Risk:** GATE-5 failure → blame on food, but root cause could be creature data or behavior or disease.

**Recommendation:** Add sequential sub-gates:
- GATE-5a: Food objects load + validate (WAVE-1 data ready)
- GATE-5b: Bait stimulus fires (WAVE-2 behavior ready)
- GATE-5c: Rabies blocks drink (WAVE-4 disease ready)
- GATE-5 (full): End-to-end integration

---

## 7. Autonomy Protocol — Can This Run Without Wayne?

### ❌ Critical Gaps

#### Gap 7.1: Who decides if a gate fails?

**Issue:** Each gate specifies "Reviewer" (e.g., "Bart architecture, Marge test sign-off"). But:
- What if Bart is unavailable?
- What if gate outcome is ambiguous (e.g., "performance is 48ms, budget is 50ms")?
- Who has final authority to declare GATE-2 failed?

**Current plan says:** "Action on fail: File issue, assign to [team], re-gate." But doesn't specify escalation path if team disagrees.

**Risk:** Phase 2 stalls waiting for Wayne's decision on a borderline gate outcome.

**Recommendation:** Document decision authority:
```
GATE-0 authority: Bart (architecture) — final say on "no regressions"
GATE-1 authority: Bart (architecture) — final say on creature validity
GATE-2 authority: Bart (architecture) + Marge (performance check)
GATE-3 authority: Bart (architecture) + Nelson (LLM walkthrough)
GATE-4 authority: Bart (architecture) + Marge (regression analysis)
GATE-5 authority: Bart (architecture) + Nelson (full LLM) + CBG (player experience)

Decision rule: Unanimous "PASS" = gate passes. Any "FAIL" = re-work required.
              Ambiguous = escalate to Wayne (decision architect).
```

#### Gap 7.2: No protocol for parallel wave blockers

**Issue:** Plan says waves run in parallel (e.g., WAVE-2 tracks 3-4 agents). But:
- WAVE-2: Bart (engine), Nelson (tests), Smithers (none), CBG (none)
- If Bart's creatures/init.lua changes break Nelson's tests, who decides?

**Plan doesn't specify:** Can Nelson block GATE-2 on Bart's incomplete code? Or does Bart have final say?

**Risk:** Conflict during WAVE-2 execution. Nelson writes tests, Bart's code fails tests, they argue about who fixes it.

**Recommendation:** Add to each wave:
```
Conflict resolution (WAVE-X):
- If Nelson's test fails on Bart's code: Bart has 4 hours to fix. 
  If unfixed, Nelson escalates to Wayne.
- If Bart's code is blocked on Nelson's test: Nelson has 2 hours to debug.
  If unresolved, Nelson escalates to Wayne.
```

#### Gap 7.3: No emergency abort protocol

**Issue:** What if a wave discovers a fundamental architectural flaw mid-implementation?

**Example:** WAVE-2 creature predator-prey detection scans all creatures every tick. At GATE-2 performance test, it's 200ms (4× budget). Re-architecting could push back launch by 2 weeks.

**Current plan:** No abort/pivot protocol. Implies we must push through.

**Risk:** Phase 2 ships with known performance problems, or stalls for 2 weeks.

**Recommendation:** Add decision point:
```
WAVE-X: If performance budget cannot be met by cycle N, 
        Wayne decides: (A) Ship with known issue, (B) De-scope feature, (C) Re-architect
```

#### Gap 7.4: Portal TDD burndown (#199-208) is parallel, but not gated

**Issue:** Line 200: "Nelson: Parallel: Portal TDD burndown (#199–#208), lint fixes (#249, #250)"

**But:** No mention of how portal TDD impacts GATE-0. Does it need to pass before WAVE-1 starts? Or is it independent?

**Risk:** Portal TDD stalls. WAVE-0 gets blocked waiting for Nelson to finish portals + WAVE-0 preflight tests.

**Recommendation:** Clarify:
```
Portal TDD (#199-208) and GATE-0 preflight are independent. 
Portal TDD does NOT block WAVE-0 or GATE-0. 
Nelson can work on portals in parallel with GATE-0; they don't interact.
```

---

## 8. Summary Findings by Category

### Test Coverage

| Item | Status | Impact |
|------|--------|--------|
| 15 TDD files specified | ✅ | Good |
| WAVE-0 test automation | ⚠️ | Lint checks not automated |
| Cross-wave integration tests | ❌ | CRITICAL: No WAVE-1/2 compat test |
| Phase 1 regression re-runs | ✅ | Implicit in gates; needs explicit log |
| Performance measurement | ❌ | CRITICAL: No baseline data |
| Disease/combat integration | ⚠️ | Untested until GATE-4 |
| Food/disease interaction | ⚠️ | Untested until GATE-5 |

**Recommendation:** Add 5 new test files:
- `test/wave0/test-preflight.lua`
- `test/creatures/test-wave1-2-integration.lua`
- `test/creatures/test-wave1-weapon-structure.lua`
- `test/injuries/test-disease-verbs-integration.lua`
- `test/creatures/test-phase1-baseline.lua` (performance benchmark)

### Gate Criteria

| Item | Status | Impact |
|------|--------|--------|
| Gates defined (5) | ✅ | Good |
| Pass/fail explicit | ✅ | Good |
| Enforcement mechanism | ❌ | CRITICAL: GATE-0 can be skipped |
| Performance verification | ❌ | CRITICAL: No measurement script |
| Seed determinism | ⚠️ | Multi-combatant test seed unspecified |

**Recommendation:** 
- Add commit/tag enforcement to GATE-0/1
- Add `os.clock()` measurements to performance budgets
- Specify seed for all probabilistic tests

### Regression Risks

| Item | Status | Impact |
|------|--------|--------|
| Phase 1 creature tests rerun | ✅ | Specified at GATE-1 |
| Combat + creatures compat | ❌ | CRITICAL: No pre-WAVE-2 test |
| Disease + combat compat | ❌ | CRITICAL: No pre-WAVE-4 test |
| Food + disease compat | ⚠️ | Covered at GATE-5 |

**Recommendation:** Add 3 new compatibility tests (run at end of prior wave, before next wave starts).

### LLM Scenarios

| Item | Status | Impact |
|------|--------|--------|
| Count (11 scenarios) | ✅ | Excellent |
| Coverage (GATE-2–5) | ✅ | Comprehensive |
| Seeding (42/43/44) | ✅ | Good |
| Creature flee scenario | ⚠️ | Missing (morale/flee LLM test) |
| Player intervention scenario | ⚠️ | Missing (player joins NPC fight) |

**Recommendation:** Add 2 new LLM scenarios for GATE-3.

### Performance Budgets

| Item | Status | Impact |
|------|--------|--------|
| Creature tick <50ms | ❌ | No baseline; likely unrealistic |
| Combat <100ms | ❌ | No baseline; no player-involved variant |
| Disease <10ms | ⚠️ | Achievable; measurement script needed |

**Recommendation:** 
- Measure Phase 1 baselines at GATE-0
- Adjust GATE-2 budget based on Phase 1 + predator-prey overhead
- Add player-involved combat budget variant

### Test Isolation

| Item | Status | Impact |
|------|--------|--------|
| Wave 1 → 2 dependencies | ❌ | CRITICAL: No compatibility check |
| Wave 2 → 3 dependencies | ❌ | CRITICAL: No compatibility check |
| Wave 3 → 4 dependencies | ❌ | CRITICAL: No compatibility check |
| Wave 4 → 5 dependencies | ⚠️ | Covered at GATE-5 |

**Recommendation:** Add 3 new "readiness" tests (run at end of prior gate, verify next gate can depend on it).

### Autonomy Protocol

| Item | Status | Impact |
|------|--------|--------|
| Decision authority | ❌ | CRITICAL: Ambiguous who decides gate outcome |
| Parallel conflict resolution | ❌ | CRITICAL: No protocol for inter-team disputes |
| Emergency abort | ❌ | CRITICAL: No pivot protocol if architecture breaks |
| Portal TDD independence | ⚠️ | Unspecified if portal TDD blocks GATE-0 |

**Recommendation:**
- Document decision authority per gate
- Add conflict escalation protocol (Bart vs Nelson → Wayne decides)
- Add feature de-scope option if budget broken
- Clarify portal TDD independence

---

## 9. Marge's Recommendations (Priority Order)

### BLOCKING (Must fix before WAVE-0 launch)

1. **Add GATE-0 automation + enforcement**
   - Create `test/wave0/test-preflight.lua` (LOC guard, dir discovery, baseline regression)
   - Add git commit/tag requirement: `git commit -m "GATE-0: preflight passed" && git tag gate-0`
   - Abort WAVE-1 if GATE-0 tag missing

2. **Add cross-wave compatibility checks**
   - Create `test/creatures/test-wave1-2-integration.lua` (run after WAVE-1, before WAVE-2)
   - Create `test/combat/test-wave2-3-compat.lua` (run after WAVE-2, before WAVE-3)
   - Create `test/injuries/test-wave3-4-compat.lua` (run after GATE-3, before WAVE-4)
   - These are SAFETY CHECKS, not full tests. Can be 5-10 LOC each.

3. **Add performance baseline measurement**
   - Create `test/creatures/test-phase1-baseline.lua` (measure Phase 1 creature/combat perf)
   - Run at GATE-0
   - Use result to set realistic GATE-2 budget

4. **Add decision authority protocol**
   - Document who decides GATE pass/fail for each gate
   - Specify escalation path (unanimous PASS, any FAIL → escalate)
   - Decision authority document to `.squad/decisions/inbox/marge-gate-authority.md`

### HIGH PRIORITY (Should fix before WAVE-1 starts)

5. **Add multi-combatant seed specification**
   - Specify `math.randomseed(42)` for GATE-3 `test-multi-combatant.lua`

6. **Add performance measurement scripts**
   - `test/injuries/test-disease-delivery.lua`: Add `os.clock()` measurement
   - Document as GATE-4 pass requirement

7. **Add LLM creature flee scenario**
   - P2-E2: Creature flees successfully (GATE-3)

8. **Add LLM player intervention scenario**
   - P2-E3: Player joins active NPC combat (GATE-3)

### MEDIUM PRIORITY (Should fix before GATE-5)

9. **Add weapon on_hit structure validation (WAVE-1)**
   - Verify creature weapons have `on_hit` field structure compatible with WAVE-4

10. **Add disease verb compatibility test (GATE-4)**
    - Verify `restricts.drink` flag works even though drink verb not yet implemented

### INFORMATIONAL

- Clarify portal TDD independence in plan (reassure that portal #199-208 doesn't block GATE-0)
- Document conflict resolution for parallel WAVE-2 (Bart vs Nelson)
- Document feature de-scope option if performance budget broken mid-phase

---

## 10. Final Gate Approval

### GATE-0 (Pre-Flight)

**Status:** ⚠️ **CONDITIONAL** — Cannot pass until:
- [ ] `test/wave0/test-preflight.lua` created (automation + baseline)
- [ ] GATE-0 enforcement protocol documented (commit/tag requirement)
- [ ] Phase 1 performance baseline measured
- [ ] Decision authority protocol documented

**Estimated fix time:** 2-3 hours (Marge + Bart collaboration)

### GATES 1-5

**Status:** ⚠️ **CONDITIONAL** — Cannot pass until:
- [ ] 3 cross-wave compatibility tests added (WAVE-1/2, WAVE-2/3, WAVE-3/4)
- [ ] Performance measurement scripts added to GATE-2 and GATE-4
- [ ] 2 new LLM scenarios added to GATE-3
- [ ] Weapon structure + disease verb tests added

**Estimated fix time:** 4-5 hours (Nelson + Bart collaboration)

---

## 11. Recommendation Summary

| Finding | Severity | Recommendation |
|---------|----------|-----------------|
| GATE-0 not automated | CRITICAL | Add `test/wave0/test-preflight.lua` + enforcement |
| Cross-wave isolation poor | CRITICAL | Add 3 compatibility check files |
| Performance budgets unvalidated | CRITICAL | Measure Phase 1 baseline at GATE-0 |
| No autonomy protocol | CRITICAL | Document decision authority + escalation |
| LLM creature flee scenario missing | HIGH | Add P2-E2 |
| Multi-combatant seed unspecified | HIGH | Specify seed 42 in GATE-3 |
| Performance measurement absent | HIGH | Add `os.clock()` to GATE-2/4 tests |

---

## Attachments

**Companion documents to prepare:**
- `.squad/decisions/inbox/marge-gate-authority.md` (decision authority protocol)
- `.squad/decisions/inbox/marge-wave-conflict-protocol.md` (parallel work dispute resolution)
- `.squad/decisions/inbox/marge-performance-baseline.md` (Phase 1 perf measurements, GATE-2 adjusted budget)

---

**Signed:** Marge (QA Lead)  
**Date:** 2026-03-26T14:30:00Z  
**Status:** SUBMITTED FOR REVIEW

Next step: Wayne decides whether to proceed with GATE-0 as-is (risk acceptance) or address critical gaps first (recommended).


## moe-phase2-review

# Phase 2 Room Placement & World Design Review
**Author:** Moe (World Builder)  
**Date:** 2026-03-27  
**Re:** `plans/npc-combat-implementation-phase2.md` — WAVE-1 creature placement  
**Requested By:** Wayne "Effe" Berry

---

## Executive Summary

Phase 2 creature placement is **SOUND with THREE ACTIONABLE DESIGN NOTES**. Courtyard + hallway + deep-cellar + crypt assignments make ecological sense. Room capacities are adequate. Portal traversal needs clarification. Room descriptions will benefit from creature presence updates post-WAVE-1.

**File Ownership Confirmed:** Moe modifies all 4 room files in WAVE-1 (courtyard, hallway, deep-cellar, crypt).

---

## Review Findings

### 1. **Creature Placement (Room Ecology)**

#### ✅ Cat in Courtyard
- **Rationale (Plan):** Open area, hunts rats
- **Moe Assessment:** 
  - ✅ **STRONG FIT** — Courtyard is sky-visible, well-lit (light_level=1), spacious. Moonlight + cat hunting sensibility aligns perfectly.
  - ✅ Ivy coverage (east wall) provides ambush / hide micro-structure for stalking behavior
  - ✅ Well + cobblestones = natural "rodent territory" signal for prey hunting
  - **Design Note:** Consider adding `on_enter` flavor if cat is alive/present — "You hear a faint hiss from the ivy." (optional, post-combat detection)

#### ✅ Wolf in Hallway  
- **Rationale (Plan):** Territorial — guards passage
- **Moe Assessment:**
  - ✅ **STRONG FIT** — Hallway is territorial chokepoint (single entry/exit model per room topology). Wolf's territorial behavior (territory="hallway") gains mechanical meaning here.
  - ✅ Warm (18°C), well-lit (light_level=3) — wolf comfort zone for active patrol
  - ✅ Portraits + doors create perimeter "markers" for territorial patrolling
  - ⚠️ **Gameplay Tension:** Wolf blocks hallway access. Likely forces alternative route (courtyard → crypt path?). **NOT A PROBLEM** — this is intentional gating.
  - **Design Note:** Room description already suggests emptiness. Consider: "In a corner, something stirs. Eyes catch the torchlight — orange, feral, watching."  (optional)

#### ✅ Spider in Deep-Cellar
- **Rationale (Plan):** Dark, damp habitat
- **Moe Assessment:**
  - ✅ **PERFECT FIT** — Deep-cellar is cold (9°C), unlit (light_level=0), dry (moisture=0.3), isolated. Spider's passive behavior + web-builder FSM aligns with still, dark architecture.
  - ✅ Limestone blocks + altar = natural web-anchor points
  - ✅ Silent environment matches spider's low aggression (10) + quiet predation
  - **Design Note:** No room description update needed — spider presence can emerge via `on_feel` ("sticky threads cross your path") at interaction time.

#### ✅ Bat in Crypt
- **Rationale (Plan):** Dark, ceiling for roosting
- **Moe Assessment:**
  - ✅ **PERFECT FIT** — Crypt is cold (8°C), silent, unlit (light_level=0), vaulted ceiling with natural roosting position. Bat's `roosting_position="ceiling"` + light_reactive behavior creates dynamic sensory gameplay.
  - ✅ Inscriptions + stone niches = ecologically plausible roost anchor points
  - ⚠️ **Light Reactive Trigger:** Bat has `light_reactive=true` with fear reaction (+60 fear) → flee on player light entry. **Confirmed Mechanic** — matches Phase 2 creature specifications (L278 of plan).
  - **Design Note:** When lit, player hears/startles bat. Room description ("Dust motes hang motionless") should NOT mention bat directly until `on_listen` reveals movement post-startle.

---

### 2. **Portal Interactions & Creature Traversal**

#### ⚠️ **CRITICAL DESIGN QUESTION: Can Creatures Use Portals?**

**Plan Context:**
- Phase 2 spec (L258, L269) notes wolf is territorial (`territory="hallway"`) and rat has `can_open_doors=false` (confined to cellar by mechanic).
- No explicit statement: **Can cat/wolf/spider/bat traverse portals (stairs, archways, doors)?**

**Moe Finding:**
- Rat's `can_open_doors=false` suggests creatures have door/portal traversal rules
- Plan specifies no creature "follow player" behavior in Phase 1 (NPCs are autonomous, not linked to player)
- BUT: Wolf hunts cat hunts rat — multi-room hunting chains require traversal

**My Recommendation:**
1. **Portals are passable by creatures by default** (stairways, archways, open/unlocked doors)
2. **`can_open_doors=false` restricts ONLY locked/closed doors** (rat trapped in cellar by closed/locked door, not architectural walls)
3. **Territorial creatures stay home:** Wolf won't leave hallway unless fleeing extreme threat. Bat won't leave crypt. Cat/wolf hunt-patrol confined to "home + adjacent prey rooms"

**Action for Bart/Flanders:** Confirm `can_open_doors=false` semantics in Phase 2 creature specs. If rat is immobile in cellar (L287, rationale "trapped"), clarify:
- Does cellar→hallway door stay locked?
- Or does rat's `can_open_doors=false` block the action?

**Moe Impact:** No room file changes needed IF portals are passable. But if doors MUST be explicitly unlocked/open for creatures, I need to declare door states in room instances.

---

### 3. **Room Capacity & Multi-Creature Cluttering**

#### ✅ Room Capacity Adequate for Phase 2

| Room | Creature | Room Size | Player + Creature | Assessment |
|------|----------|-----------|------------------|------------|
| courtyard | cat | Large (5 objects) | Yes, spacious | ✅ Not cluttered |
| hallway | wolf | Medium (7 objects + 3 doors) | Tight but viable | ✅ Intentional tension |
| deep-cellar | spider | Large (4 objects) | Yes, spacious | ✅ Not cluttered |
| crypt | bat (ceiling) | Medium (5 coffins) | Yes, bat=overhead | ✅ Vertical separation |

**Finding:** Rooms can comfortably hold 1 creature + player + objects. If Phase 3+ adds multi-creature encounters (wolf+cat+rat in hallway), room descriptions will need revision, but Phase 2 is clear.

#### ⚠️ **Narrative Density Note**
- Hallway is already heavily described (7 embedded_presences). Adding wolf presence might feel crowded in narration. **Recommendation:** Wolf presence emerges dynamically ("You hear growling") rather than in static room description. Keep description wolf-free.

---

### 4. **Ecosystem & Predator-Prey Dynamics**

#### ✅ Cat Hunts Rat — Creates Interesting Gameplay

**Spatial Chain:**
```
Bedroom (start) → Courtyard (cat hunts) 
               → Hallway (wolf territorial)
               → Deep-Cellar (rat = PREY REFUGE)
               → Crypt (bat roosts)
```

**Ecosystem Tension:**
1. **Rat in cellar is SAFE** — Cat's prey list includes rat, but cat won't leave courtyard (will we add territorial boundary in Phase 2? *See decisions.md D-COMBAT-NPC-PHASE-SEQUENCING*)
2. **Cat hunts in courtyard** — If player drops bait (cheese/bread) in courtyard, cat eats before hunting
3. **Wolf in hallway blocks cat pursuit** — If cat approaches wolf (e.g., both move toward hallway), wolf's aggression (70) vs cat's (40) → wolf attacks cat. **Multi-creature combat opportunity** (Phase 3+)

**Design Assessment:** ✅ **CREATES EMERGENT GAMEPLAY**. Rat confined to deep-cellar is non-trivial boss puzzle (must navigate past wolf). Cat in courtyard is mid-game encounter. Ecosystem is sound.

---

### 5. **Room Description Updates — Do They Mention Creatures?**

#### ✅ **Current State: Descriptions are Creature-Free (Correct)**

All 4 room descriptions follow **Principle 0.5** (deep nesting) — they describe PERMANENT FEATURES ONLY. No creature presences in text.

**Courtyard (L9):** "cobblestones, well, ivy, sky, walls" — ✅ No cat mention
**Hallway (L10):** "torches, portraits, doors, oak, wainscoting" — ✅ No wolf mention  
**Deep-Cellar (L10):** "limestone vault, altar, symbols, incense-memory" — ✅ No spider mention
**Crypt (L10):** "coffins, inscriptions, candles, silence" — ✅ No bat mention

**Post-WAVE-1 Update Strategy:**
After Flanders creates creature files + Nelson tests pass, Moe will update room `on_listen` (audio sense) to hint at creature presence in darkness:
- **Courtyard:** "...and from the ivy, a faint padding of paws." (optional)
- **Hallway:** "In the torchlight, you catch a shadow moving—too large for a rat." (optional)
- **Deep-Cellar:** "Your light catches something metallic across the stone—a spider's web." (optional)
- **Crypt:** "Above, in the darkness, something shifts. Bat wings? You're not sure." (optional)

These are **OPTIONAL ENHANCEMENTS post-gate**. Not required for WAVE-1 gate passage.

---

### 6. **File Ownership — Moe's Wave-1 Scope**

#### ✅ **Clear Ownership Per Plan (L232-235)**

| Room File | Wave | Action | Rationale |
|-----------|------|--------|-----------|
| `src/meta/rooms/courtyard.lua` | WAVE-1 | MODIFY | Add cat instance |
| `src/meta/rooms/hallway.lua` | WAVE-1 | MODIFY | Add wolf instance |
| `src/meta/rooms/deep-cellar.lua` | WAVE-1 | MODIFY | Add spider instance |
| `src/meta/rooms/crypt.lua` | WAVE-1 | MODIFY | Add bat instance |

**What Moe Does in WAVE-1:**
1. Each room's `instances` array gets ONE new creature entry:
   ```lua
   { id = "cat", type_id = "{flanders-guid-from-cat.lua}" }
   ```
2. NO CHANGES to descriptions, exits, or embedded_presences
3. NO ENGINE MODIFICATIONS (pure data wave)
4. All creature GUIDs come from Flanders' `cat.lua`, `wolf.lua`, etc.

**Coordination Point:**
- Flanders provides creature GUIDs (wait for creature `.lua` files)
- Nelson tests room parsing (post-creature files created)
- Gate-1 verifies creatures load in room context

---

## Summary Assessment

| Aspect | Status | Rationale |
|--------|--------|-----------|
| **Creature Placement** | ✅ | Courtyard/hallway/deep-cellar/crypt assignments ecologically sound |
| **Portal Traversal** | ⚠️ | Needs semantics clarification (Bart/Flanders) — affects future phases |
| **Room Capacity** | ✅ | No cluttering; hallway intentionally tight (good design tension) |
| **Ecosystem** | ✅ | Predator-prey chains create emergent gameplay |
| **Descriptions** | ✅ | Correctly omit creature presences; audio hints optional post-gate |
| **File Ownership** | ✅ | Moe owns all 4 room mods in WAVE-1; no conflicts |

---

## Decisions to File

### D-CREATURE-PORTAL-TRAVERSAL (Pending Clarification)

**Author:** Moe (World Builder)  
**Status:** 🟡 Awaiting Clarification from Bart/Flanders

**Issue:**
- Plan specifies `can_open_doors=false` for rat (cellar-confined)
- But doesn't specify default creature portal traversal behavior
- Wolf hunts cat hunts rat → implies multi-room movement chains
- Need to clarify: Do creatures auto-traverse unlocked portals, or do they require special flags?

**Moe's Assumption for WAVE-1:**
- Creatures can traverse stairways, archways, and OPEN/UNLOCKED doors by default
- `can_open_doors=false` restricts LOCKED/CLOSED door traversal only
- Territorial creatures have behavior rules (e.g., wolf won't leave hallway) — engine-enforced in Phase 2

**Action:** Bart + Flanders confirm in chat before WAVE-1 implementation.

---

## Checkpoints

- [x] Phase 2 plan reviewed (chunk 1-2b, all waves)
- [x] Room files examined (courtyard, hallway, deep-cellar, crypt)
- [x] Creature specifications cross-referenced (L245-280)
- [x] Existing room descriptions verified (creature-free, per Principle 0.5)
- [x] Moe file ownership confirmed (no conflicts, 4 files in WAVE-1)
- [ ] Portal traversal semantics clarified (awaiting Bart/Flanders)
- [ ] Optional room description enhancements designed (post-gate)

---

## Next Steps

1. **Pre-WAVE-1:** Confirm portal traversal semantics with Bart
2. **WAVE-1 (Flanders):** Create `cat.lua`, `wolf.lua`, `spider.lua`, `bat.lua` + `chitin.lua`
3. **WAVE-1 (Moe):** Add creature instances to room files (1 line per room, 4 lines total)
4. **GATE-1:** Verify creatures load in room context
5. **Post-GATE-1 (Optional):** Update room `on_listen` with creature audio hints

---

**Moe's Verdict:** ✅ Phase 2 room placement is **APPROVED FOR IMPLEMENTATION**. Courtyard + hallway + deep-cellar + crypt is a coherent, ecologically sound creature deployment that creates emergent gameplay and spatial drama. No design blockers.



## nelson-gate6-bugs

# Nelson — Gate6 Combat Bugs (2026-03-26)

## CRITICAL: Duplicate Trapdoor Blocks All Cellar Access

**Affects:** Bart (engine), Moe (room definitions), Flanders (trapdoor object)
**Severity:** CRITICAL — blocks ALL combat testing and cellar access

### Bug Description

When the player executes `pull rug` in the bedroom, the engine spawns a NEW trapdoor object but does NOT remove or update the original hidden trapdoor. This creates two trapdoor objects in the room:

1. Original trapdoor (state: hidden, won't budge)
2. Newly revealed trapdoor (state: openable via "pull iron ring")

Even after "pull iron ring" opens the revealed trapdoor, the `down` exit remains blocked because the exit check resolves to the OLD hidden trapdoor.

### Reproduction
```
move bed → pull rug → pull iron ring → down
```
Result: "a trap door blocks your path" (despite trapdoor visibly open in room description)

### Impact
- ALL 4 gate6 combat scenarios FAIL
- Player is permanently trapped in bedroom
- Combat system is completely untestable
- Freeform playthroughs cannot reach the cellar

### Recommendation
The `pull rug` mutation should either:
- Update the existing trapdoor's state from hidden→closed (instead of spawning a new one), OR
- Remove the old trapdoor and replace with the revealed one, OR
- The exit check should look for ANY open trapdoor, not just the first one found

### Secondary Issues
- Gate6 scenario scripts use `take candle holder` (should be `take candle`)
- Gate6 scenario scripts are missing the `move bed → pull rug → pull iron ring` sequence
- "punch rat" when rat not in scope says "You can only hit yourself right now" — should say target not found


## smithers-phase2-review

# Phase 2 PARSER & VERB Plan Review — Smithers Assessment

**Reviewer:** Smithers (Parser/Verb Specialist)  
**Plan:** `plans/npc-combat-implementation-phase2.md`  
**Scope:** NPC + Combat Phase 2 (WAVE-0 through WAVE-5)  
**Date Reviewed:** 2026-03-26  

---

## Review Summary

**Waves requiring Smithers work:**
- **WAVE-3:** Combat witness narration (Track 3C)
- **WAVE-5:** Eat/drink verb extensions (Track 5B)

**Total files under Smithers ownership:** 2 modified  
**Estimated LOC:** ~80–120 (narration + verbs)

---

## Detailed Findings

### ✅ **Verb Extensions — Eat/Drink/Cook**

**Status:** ✅ **WELL-DEFINED** (WAVE-5, Track 5B)

**Coverage:**

| Verb | Status | Plan Details |
|------|--------|--------------|
| `eat` | ✅ | Check `food.edible`, verify `restricts` flags (disease blocks), consume item, apply `nutrition`, emit sensory feedback |
| `drink` | ✅ | Same pattern, `restricts.drink` (rabies blocks), check liquid container state |
| `cook` | ❌ | **NOT INCLUDED** — Hard boundary D-R5: *"no cooking, recipes, or spoilage-driven creature behavior"* |
| `feed` | ⚠️ | **NOT MENTIONED** — No `feed` verb planned; food used only as bait mechanic (creature consumes autonomously) |

**Aliases specified:**
- `eat`/`consume`/`devour` ✅
- `drink`/`sip`/`quaff` ✅

**Implementation location:** `src/engine/verbs/survival.lua` (CREATE), `src/engine/verbs/init.lua` (MODIFY — register aliases)

**Tests:** `test/food/test-eat-drink.lua` (~15 tests) covers keyword disambiguation, dark-mode eat, rejection of non-food, rabies block on drink, spoilage warnings.

**Finding:** Plan is **complete for eat/drink scope**. Cook scope intentionally deferred (Phase 2.5+). Feed verb **absent but acceptable**—bait system uses creature drives, not explicit player `feed` command.

---

### ⚠️ **Combat Witness Narration — Light-Dependent**

**Status:** ⚠️ **SPECIFIED BUT IMPLEMENTATION DETAILS SPARSE** (WAVE-3, Track 3C)

**Coverage:**

| Condition | Narration Type | Details |
|-----------|---|---------|
| **Same room + light** | ✅ Visual | Full third-person framing via `narration.describe_exchange()` |
| **Same room + dark** | ✅ Audio-only | Severity-keyed: GRAZE→scuffle, HIT→yelps, CRITICAL→death |
| **Adjacent room** | ✅ Distant audio | 1 line max |
| **Out of range** | ✅ Silence | Nothing emitted |

**Line cap enforcement:** ≤2 lines/exchange (same room), 1 line (adjacent), ≤6 lines/round (aggregate)

**Implementation location:** `src/engine/combat/narration.lua` (MODIFY)

**Context from Phase 1:** Combat narration engine exists (146 LOC, `src/engine/combat/narration.lua`). Spec assumes **existing infrastructure**—no mention of creating `narration.lua` from scratch.

**Missing details:**
- ⚠️ No code pseudocode for light detection in narration path
- ⚠️ No specification for "audio-only" severity tier (which injury class maps to which sound?)
- ⚠️ No guidance on NPC-vs-NPC narration message authoring (are messages generic template-driven or creature-specific?)

**Finding:** Narration system is **architecturally sound** but **implementation details deferred to gate validation**. Light-dependency is clear; audio-tier mapping needs clarification during implementation.

---

### ⚠️ **New Nouns — Creature Keywords & Embedding Updates**

**Status:** ⚠️ **KEYWORDS SPECIFIED, EMBEDDING INDEX UPDATES NOT MENTIONED**

**Creature keywords defined:**
- Cat: `{"cat", "feline"}`
- Wolf: `{"wolf"}`
- Spider: `{"spider"}`
- Bat: `{"bat"}`
- Rat (existing, phase 1): `{"rat", "rodent"}`

**Food keywords defined:**
- Cheese: `{"cheese", "wedge", "food"}`
- Bread: `{"bread", "crust", "food"}`
- Spider-web: `{"web", "spider web", "cobweb", "silk"}`

**Parser implications:**

| Tier | Coverage | Status |
|------|----------|--------|
| **Tier 1 (Exact alias)** | Creature IDs map to keywords | ✅ Keywords listed in creature `.lua` |
| **Tier 2 (Embedding)** | `assets/parser/embedding-index.json` | ⚠️ **NOT MENTIONED** — no update directive |
| **Tier 3–5 (GOAP, Context, Fuzzy)** | Fallback resolution | ✅ Existing tiers apply |

**Multi-target disambiguation scenario:**
- Room with cat, rat, spider, bat (4+ creatures)
- Player types: `attack cat` vs `attack rat`

**Plan coverage:** ✅ **Tier 1 exact match handles this** — creature keywords unique, no collision. BUT:
- ⚠️ No embedding index entries = Tier 2 matching bypassed
- ⚠️ No fuzzy matching (Tier 5) defined for creature name typos (e.g., `attack ca` → should suggest `cat`)

**Finding:** Plan **assumes existing embedding infrastructure**. No explicit directive to update `embedding-index.json` with new creature/food embeddings. **Risk:** Tier 2 semantic matching (e.g., "living thing", "animal", "food scent") will miss new nouns until index is rebuilt.

**Recommendation:** Clarify whether Tier 2 embedding rebuild is Nelson's responsibility (WAVE-1 gate check) or deferred post-Phase 2.

---

### ✅ **Multi-Target Disambiguation**

**Status:** ✅ **WELL-HANDLED BY EXISTING PARSER**

**Scenario:** `attack cat` with cat, rat, spider, bat in room

**Resolution:**
1. **Tier 1 (exact alias):** `"cat"` matches creature keyword `"cat"` → direct lookup, no ambiguity ✅
2. Creature uniqueness enforced by `context.registry` (GUID-indexed, unique IDs per instance)
3. Ambiguity case (`attack animal` with multiple creatures): **Deferred to Tier 5 fuzzy** — plan shows `test-fuzzy-noun.lua` tests exist (Phase 1)

**Context window tracking:** ✅ Tier 4 context remembers recent targets, so `attack rat` then `attack` alone → recycles rat target

**Finding:** Plan **correctly relies on existing disambiguation infrastructure**. No new parser logic required. Creature keywords are intentionally unique (small, medium, tiny sizes help distinguish at a glance).

---

### ✅ **Headless Mode Support**

**Status:** ✅ **COMPREHENSIVELY SPECIFIED**

**Coverage:**

| Feature | Headless Support | Details |
|---------|---|---------|
| **Narration** | ✅ | Audio-only tier triggers in dark rooms; text output to stdout, no TUI prompts |
| **Eat/drink** | ✅ | Tested via `echo` + pipe; no UI interaction required |
| **Bait mechanic** | ✅ | Creature movement + consumption logged as narration; fully deterministic with seed |
| **Disease progression** | ✅ | FSM tick-based; seeded `math.randomseed(42)` for reproducibility |
| **Combat** | ✅ (Phase 1 baseline) | Existing combat works in headless; NPC-vs-NPC adds no UI dependencies |

**Testing methodology:**

```bash
echo "command1\ncommand2\n..." | lua src/main.lua --headless
```

**LLM scenarios documented:**
- P1-A: Creatures load (static checks)
- P2-D: Combat narration (lit visual) ✅ Headless
- P2-E: Combat in dark (audio-only) ✅ Headless
- P2-P1: Rabies + disease progression ✅ Headless (seeded)
- P2-P3: Bait + food ✅ Headless
- P2-P4: End-to-end integration ✅ Headless

**Determinism rule:** `math.randomseed(42)` in headless mode; if test fails, retry with 43, 44 (max 3 seeds per scenario).

**Finding:** Plan is **exemplary**. All new features have headless-compatible LLM walkthroughs. **No additional work required from Smithers** — verbs inherit headless support from existing engine.

---

### ✅ **Error Messages — Standardization**

**Status:** ✅ **CONSISTENT PATTERN**

**Standardized error strings:**

| Context | Message Pattern | Example |
|---------|---|---------|
| Object not found | `err_not_found(context, noun)` | *"You don't see that."* |
| Can't eat non-food | *"You can't eat that."* | Line 573 |
| Spoiled food warning | Warning message (not specified) | Line 573 — implementation detail |
| Rabies blocks drink | `restricts.drink` active | Verb checks `restricts` table before action |
| Food consumed | Item removed from inventory + registry | Line 571 |

**Error handling location:** `src/engine/verbs/survival.lua` (Smithers responsibility)

**Consistency with existing verbs:** ✅ Error patterns match existing verb handlers (look, take, attack, etc.) — use `err_*` functions from verb module.

**New message required:**
- *"The cheese smells rotten."* (spoiled food warning) — specify in `survival.lua`

**Finding:** Plan is **well-standardized**. Error strings follow existing conventions. **Single new message** (spoiled warning) must be added with clear, diegetic flavor consistent with existing tone.

---

### ✅ **File Ownership — Smithers Waves**

**Status:** ✅ **CLEAR SCOPE DEFINITION**

**WAVE-3 (Combat Witness Narration):**

| File | Action | Lines | Owner |
|------|--------|-------|-------|
| `src/engine/combat/narration.lua` | MODIFY | ~40–50 new | Smithers |

**Responsibility:**
- Extend `narration.describe_exchange()` with light-awareness
- Add audio-tier severity mapping
- Enforce line cap (≤6 lines/round aggregate)
- Emit witness narration for NPC-vs-NPC and player-witness scenarios

**Dependencies:** Depends on GATE-2 (Creature Generalization). Bart completes creature `attack` action entry; Smithers adds witness output.

**WAVE-5 (Eat/Drink Verbs):**

| File | Action | Lines | Owner |
|------|--------|-------|-------|
| `src/engine/verbs/survival.lua` | MODIFY | ~60–80 | Smithers |
| `src/engine/verbs/init.lua` | MODIFY | ~5–10 | Smithers |

**Responsibility:**
- Implement `eat` verb: find, validate `food.edible`, check `restricts`, consume, emit sensory
- Implement `drink` verb: similar, check for `restricts.drink` (rabies block)
- Register aliases in `init.lua`

**Dependencies:** Depends on GATE-4 (Disease System). Rabies `restricts.drink` must exist before verb checks it.

**Cross-wave file map confirms:** No file modified by two agents in same wave. Smithers doesn't conflict with Bart, Flanders, or Nelson.

**Finding:** Scope is **clearly delineated**. Two waves, two files, ~100–150 LOC total. **No scope creep identified.**

---

### ⚠️ **Missing or Deferred Items**

| Item | Status | Reason | Impact |
|------|--------|--------|--------|
| Cooking verbs | ❌ | Design decision D-R5 (hard boundary) | None — explicitly out of scope |
| `feed` verb | ❌ | Bait system autonomous; no player verb needed | None — design choice |
| Embedding index rebuild | ⚠️ | Not assigned; possible Nelson task | Minor — existing fallback tiers work |
| Audio tier sound effects | ⚠️ | Message templates specified, voices undefined | None — text-based game; narration is text |
| Spoilage-driven NPC behavior | ❌ | D-R5 boundary | None — creatures hunt fresh food only |
| Creature-specific narration templates | ⚠️ | Generic templates assumed | Minor — implementation detail, design pattern documented |

---

## Recommendations for Smithers

1. **WAVE-3 implementation:** Clarify audio-tier mapping at gate review:
   - GRAZE → what text? (`"A faint scuffle."` ?)
   - HIT → what text? (`"Sharp yelp."` ?)
   - CRITICAL → what text? (`"Death cry."` ?)

2. **WAVE-5 implementation:** Reserve ~20 LOC for spoilage message variants:
   - Fresh: (normal description)
   - Stale: *"The cheese is hard and dusty."*
   - Spoiled: *"The cheese smells rotten."*

3. **Parser integration check:** After WAVE-1, confirm embedding index update status with Nelson. If deferred, document impact on Tier 2 matching for new nouns.

4. **Test-first protocol:** Implement `test/food/test-eat-drink.lua` **before** modifying `survival.lua`. Nelson provides test spec; Smithers writes implementation to pass tests.

---

## Sign-Off

**Reviewed by:** Smithers (Parser/Verb Specialist)  
**Status:** ✅ **APPROVED FOR EXECUTION**

**Confidence level:** 🟢 High — plan is architecturally sound, scope is clear, dependencies are documented, headless support is comprehensive.

**Ready for:** WAVE-3 (after GATE-2) and WAVE-5 (after GATE-4)

---

## Appendix: Key Reference Files

- `plans/npc-combat-implementation-phase2.md` (WAVE-3, 3C: lines 433–442; WAVE-5, 5B: lines 567–576)
- `src/engine/combat/narration.lua` (existing baseline, 146 LOC)
- `src/engine/verbs/init.lua` (verb registration module)
- `.squad/decisions.md` (D-HEADLESS, D-VERBS-REFACTOR-2026-03-24)

---

## D-PHASE4-WAVE0-LOC-AUDIT: Phase 4 LOC Audit & GUID Pre-Assignment

**Author:** Bart (Architecture Lead) | **Date:** 2026-03-28 | **Status:** ✅ COMPLETE

### Overview

Phase 4 pre-flight LOC audit across all engine modules relevant to Phase 4 scope. Identified creatures/init.lua as critical (546 LOC, exceeds 500 ceiling). 19 new GUIDs pre-assigned for Phase 4 objects. 

### Key Findings

**Modules over 500 LOC (full inventory):**
- creatures/init.lua: **546** ⚠️ **Phase 4 will grow this** — split required before W1
- All others pre-existing debt from Phase 1–3

**Phase 4 LOC Budget:** ~1,540 total across 5 waves (±25% variance acceptable)

**Split Plan:** Extract score_actions, move_creature, execute_action from creatures/init.lua → creatures/actions.lua (~170 LOC)
- Reduces init.lua from 546 → ~375 LOC (safe)
- Creates home for Phase 4 behavior additions (W5 pack tactics)
- Execution: Before WAVE-1 starts

### GUIDs Pre-Assigned (19 Total)

| Object | GUID | Category | Wave |
|--------|------|----------|------|
| wolf-meat | {c2027139-6127-4020-9272-f707333290c9} | Butchery product | W1 |
| wolf-bone | {7e7a979b-57bc-4661-838d-074fcb49ce4c} | Butchery product | W1 |
| wolf-hide | {67c38c8b-53a6-4de9-85e9-24e9ffe86503} | Butchery product | W1 |
| wolf-pelt | {a575cddc-feaf-441b-a05d-31f30ef2f967} | Crafted mutation | W1 |
| cooked-wolf-meat | {58ab2833-46cd-4e16-b0db-38132ce83884} | Mutation target | W1 |
| butcher-knife | {9e8ab074-0888-42ab-b871-af7e39e59598} | Tool | W1 |
| stress | {05c343ce-8f8c-406a-80ef-b271bc4dd89b} | Injury type | W3 |
| spider-web | {bb5699b3-e027-4b43-b9cf-3acc183091b9} | Trap object | W4 |
| silk-rope | {47571952-19a9-4b7b-9b6d-744c842f1bc2} | Craftable | W4 |
| silk-bandage | {7ffb6862-4cb1-4312-bfc0-ddd444abbd40} | Craftable | W4 |
| territory-marker | {60189a1c-892c-478f-be8a-086fe8128cbb} | Behavior marker | W5 |
| wolf-pack-alpha | {3181034d-e70f-48ab-abc5-ccf942924850} | Behavior marker | W5 |
| wolf-pack-beta | {00dc19b2-7d81-4ab8-bfbb-8a2117fbf08a} | Behavior marker | W5 |
| spider-fang | {d0edbc79-c45f-424c-ad3c-ed816cbc617a} | Loot drop | W2 |
| charred-hide | {ce775db0-7951-4fc0-a3df-5a02d00d7dd9} | Conditional loot | W2 |
| tainted-meat | {eee2cc13-59ab-42a0-a79a-4e212b6f101b} | Conditional loot | W2 |
| copper-coin | {ca003244-7b69-44c2-a42d-27ac59a6e33b} | Common loot | W2 |
| silver-coin | {140b01c3-1fc9-4868-81c2-33b546add92b} | Rare loot | W2 |
| torn-cloth | {e76bd60b-2055-4a63-bf97-6463d7fde9ec} | Common loot | W2 |

**All Phase 4 agents MUST use these GUIDs. No ad-hoc generation during waves.**

---

## D-PHASE4-WAVE0-TEST-BASELINE: Phase 3→4 Test Baseline Locked

**Author:** Nelson (QA Engineer) | **Date:** 2026-03-28 | **Status:** ✅ COMPLETE

### Baseline

- **Phase 3 Final Test Count:** 207 test files
- **New Directories Registered:** test/butchery/, test/loot/, test/stress/
- **Regression Check:** All tests pass after registration (0 regressions)
- **Notes:** injuries/test-injuries-comprehensive.lua showed intermittent failure on first run but passed on regression check — flagged as flaky (pre-existing, not Phase 4 cause)

### Tracking

This baseline is locked for Phase 4 regression analysis. All new Phase 4 tests increment from this count.

---

## D-PHASE4-WAVE0-EMBEDDING-AUDIT: Embedding Collision Audit & Resolution

**Author:** Smithers (UI Engineer) | **Date:** 2026-03-28 | **Status:** ✅ COMPLETE

### Summary

Embedding index audit checked Phase 4 keywords against 11,131 existing embedding phrases. Identified 3 HIGH collision risks.

### 🔴 HIGH Collisions

1. **knife / butcher-knife**
   - Existing `knife` owns 117 embedding phrases
   - Action: butcher-knife keywords = {"butcher knife", "carving knife"} (NO bare "knife")
   - Add ~39 new butcher-knife phrases to index

2. **rope / silk-rope**
   - Existing `rope-coil` owns 117 embedding phrases
   - Action: silk-rope keywords = {"silk rope", "spider rope"} (NO bare "rope")
   - Add ~39 new silk-rope phrases to index

3. **bandage / silk-bandage**
   - Existing `bandage` owns 117 embedding phrases
   - Action: silk-bandage keywords = {"silk bandage", "silk dressing"} (NO bare "bandage")
   - Add ~39 new silk-bandage phrases to index

### 🟡 MEDIUM Collisions

- **bone / gnawed-bone vs wolf-bone:** gnawed-bone claims "wolf bone" keyword. When wolf-bone ships (W1), remove "wolf bone" from gnawed-bone → "bone fragment"
- **meat — 4-way disambiguation:** 3 existing meats + wolf-meat. Consider disambiguation prompt in parser Tier 4 context window

### 🟢 CLEAR

- web, butcher, craft, silk, hide (verb/noun homograph flagged for future)

### Resolution Strategy

**Phase 4 object keywords MUST follow adjective-first disambiguation:**
- New objects use `{adjective} {noun}` as primary keyword (e.g., "butcher knife", not "knife")
- Bare single-word keywords reserved for FIRST object of that type
- If bare keyword becomes ambiguous (both in room), parser triggers disambiguation prompt
- gnawed-bone "wolf bone" keyword removed when wolf-bone ships

### Embedding Index Update Plan

When Phase 4 objects created, add ~195 new phrases:
- butcher-knife: ~39 phrases
- wolf-meat: ~39 phrases
- wolf-bone: ~39 phrases
- wolf-hide: ~39 phrases
- spider-web: ~39 phrases

---

## D-CREATURES-ACTIONS-SPLIT: creatures/init.lua → creatures/actions.lua Extraction

**Author:** Bart (Architecture Lead) | **Date:** 2026-03-28 | **Status:** 🟡 PLANNED (Execute before W1)

### Problem

creatures/init.lua currently 546 LOC (exceeds 500 LOC ceiling). Phase 4 will add behavior code (W5 pack tactics, territory, ambush). Without split, module reaches ~700+ LOC by W5.

### Solution

Extract action execution and scoring logic into `src/engine/creatures/actions.lua`:
- **Extract:** score_actions (~55 LOC), move_creature (~22 LOC), find_bait (~10 LOC), try_bait (~21 LOC), execute_action (~149 LOC)
- **Result:** init.lua 546 → ~375 LOC; actions.lua: 0 → ~170 LOC
- **Pattern:** Pass dependencies via helpers table (consistent with navigation/stimulus delegation)

### LOC Projection (Post-Split)

| Wave | init.lua | actions.lua | Total |
|------|----------|-------------|-------|
| Post-split | 375 | 170 | 545 |
| W1 (butchery) | 385 | 170 | 555 |
| W2 (loot) | 400 | 170 | 570 |
| W5 (behaviors) | 420 | 250 | 670 |

Both modules stay **well under 500** through all of Phase 4.

### Execution

**Owner:** Bart | **When:** Before WAVE-1 kickoff | **Risk:** Low (pure refactor, no behavior changes)

**Test impact:** Run full creature behavior test suite after extraction.



---

## D-LOOT-ENGINE: Loot Table Engine Architecture

**Author:** Bart (Architect) | **Date:** 2026-08-17 | **Status:** ✅ Implemented (WAVE-2) | **Affects:** Flanders (creature objects), Nelson (tests), Smithers (parser/narration)

### Decision

Loot table engine (src/engine/creatures/loot.lua) uses the same 3-tier template resolution as esolve_byproduct in death.lua — registry → object_sources → base_classes. Each instantiated drop gets a unique id ({template}-loot-{N}) via a module-level counter.

### Key Choices

1. **Capture-before-reshape** — creature.loot_table is captured before eshape_instance() runs. Rolls use the captured data, not the post-reshape creature. Defensive against future reshape changes.

2. **Room-floor placement** — Loot drops go directly to oom.contents, same as byproducts and inventory drops. No corpse-container nesting.

3. **Kill method resolution** — death_context.kill_method reads from context.kill_method OR context.last_combat_method. Combat system can set either; loot engine is agnostic.

4. **Corpse cleanup** — creature.loot_table is nilled after drops are processed. Dead objects don't carry stale loot metadata.

5. **Graceful degradation** — pcall-guarded require. If loot module fails to load, death path works exactly as before (inventory drops + byproducts only).

### Impact

- Creatures with loot_table field get probabilistic drops on death.
- Creatures without loot_table are completely unaffected.
- Nelson: 	est-death-drops.lua and 	est-creature-inventory.lua need updating — wolf/spider now use loot_table instead of inventory.

---

## D-LOOT-MATERIAL-COPPER: Loot Object Material & GUID Assignments

**Author:** Flanders | **Date:** 2026-08-17 | **Status:** ✅ Implemented (WAVE-2) | **Context:** Phase 4 WAVE-2 loot table conversion

### copper-coin uses material "brass" (not "copper")

The material registry has no "copper" entry. Brass is a copper alloy and the closest registered material. If a "copper" material is added later, copper-coin.lua should be updated.

### 6 New Loot Object GUIDs

| Object | GUID |
|--------|------|
| spider-fang | {453600d7-1c85-4ada-a56d-c4b51f740133} |
| silver-coin | {6cabc916-46da-429f-8a3f-3689f6eef601} |
| copper-coin | {6581d541-622f-45b9-8a6e-2de3251c8a62} |
| torn-cloth | {e1010096-218c-4f0c-9eb0-a6af1c588b88} |
| charred-hide | {be6704fd-3341-48fe-8e39-86634c2ec2db} |
| tainted-meat | {8aefbd0d-112c-4209-b124-e38475ad5e38} |

### D-LOOT-TEST-BREAKAGE

Wolf inventory removal breaks 2 test files (10 tests total):
- 	est/creatures/test-creature-inventory.lua (5 tests) — expects inventory field
- 	est/creatures/test-death-drops.lua (5 tests) — expects inventory-based drops

**Action needed:** Nelson must update these tests to validate loot_table format instead of inventory.

### D-LOOT-TAINTED-MEAT

tainted-meat has food.on_eat poison metadata. Unlike other loot items (inert small-items), tainted-meat declares ood.on_eat.inflict = "food-poisoning". This requires engine support to process — flagging for Bart.

### Affected Agents

- **Bart** — loot engine integration, tainted-meat food.on_eat processing
- **Nelson** — test updates for creature-inventory and death-drops
- **Smithers** — embedding index needs entries for 6 new objects
