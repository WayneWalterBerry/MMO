# Squad Decisions

**Last Updated:** 2026-07-20T14:12:00Z  
**Last Merge:** 2026-07-20T14:12:00Z (2 decisions from Wave 3-4 inbox merged)
**Scribe:** Session Logger & Memory Manager

## How to Use This File

**Agents:** Scan the Decision Index first. Active decisions have full details below. Archived decisions are in `decisions-archive.md`.

**To add a new decision:** Create `inbox/{agent-name}-{slug}.md`, Scribe will merge it here.

---

## Decision Index

Quick-reference table of **active + most recent decisions**.

| ID | Category | Status | One-Line Summary |
|----|----------|--------|------------------|
| D-14 | Architecture | 🟢 Active | Code mutation is state change — objects rewritten at runtime |
| D-INANIMATE | Architecture | 🟢 Active | Objects are inanimate; creatures future phase |
| D-WORLDS-CONCEPT | Architecture | 🟢 Active | Worlds meta concept — top-level container above Levels |
| D-ENGINE-REFACTORING-WAVE2 | Architecture | 🟢 Active | Engine refactoring sequencing: 6 files, 5 modules each, after test baselines |
| D-LINTER-IMPL-WAVES | Process | 🟢 Active | Linter improvement: 6 waves with 5 gates, serialized lint.py edits |
| D-ENGINE-REFACTORING-REVIEW | General | 🟢 Active | Ongoing engine architecture review |
| D-HIRING-DEPT | General | 🟢 Active | All new hires must have department assignment |
| D-WAYNE-CODE-REVIEW-DIRECTIVE | Process | 🟢 Active | Mandatory code review before pull requests |
| D-TESTFIRST | Testing | 🟢 Active | Test-first directive for all bug fixes |
| D-EXIT-DOOR-RESOLUTION | Architecture | 🟢 Active | Exit door fallback pattern for verb handlers (Smithers) |
| D-CREATE-OBJECT-TEMPLATE | Architecture | 🟢 Active | Spider web uses template instantiation + max_per_room (Flanders) |
| D-CREATURE-ZONE-NAMES | Architecture | ✅ Implemented | Creature-specific body zone narration names; engine-side zone_text(zone, body_tree) |
| D-TERRITORY-SENSORY-FIXES | Architecture | ✅ Implemented | Territory marker registration, narration cleanup, sensory deduplication |
| D-WAVE1-BUTCHERY-CREATURES-SPLIT | Architecture | ✅ Implemented | creatures/init.lua split to actions.lua; -190 LOC headroom |
| D-WAVE1-BURNDOWN | Process | ✅ Complete | Triaged 54 issues, 39 Wave 3 ready, 15 deferred to Phase 5 |
| D-WAVE5-BEHAVIORS | Architecture | ✅ Implemented | Pack tactics, territorial, ambush behavior engine design |
| D-CREATE-OBJECT-ACTION | Architecture | ✅ Implemented | Metadata-driven creature object creation + NPC obstacle detection |
| D-STRESS-HOOKS | Architecture | ✅ Implemented | Stress trauma hooks delegate to central injuries.add_stress() API |

---

## D-14: True Code Mutation (Objects Rewritten, Not Flagged)

**Status:** 🟢 Foundational Principle

When a player breaks a mirror or defeats a creature, the engine does NOT set a flag. Instead, it **rewrites the .lua file itself**. The code IS the state.

**Example:**
- Player: `break mirror`
- Engine: Mutates `mirror.lua` → `mirror-broken.lua` in registry
- Result: All subsequent `look mirror` use broken state; code transformation is permanent for that game instance

---

## D-INANIMATE: Objects Are Inanimate (Creatures Are Future)

**Status:** 🟢 Active  
**Author:** Wayne "Effe" Berry + Flanders (Object Engineer)

**Scope:** Version 1 (V1) supports **inanimate objects and environmental creatures only**. NPCs (interactive, dialogue-driven creatures) are Phase 5+.

**Why:**
- Creatures currently: Simple AI (wander, attack, flee, drop loot) — no agency or memory
- NPC requirements: Dialogue trees, quest state, multi-turn memory — requires entirely different architecture

**Current scope (V1):**
- ✅ Environmental creatures (wolf, spider, rat) with simple behavior
- ✅ Inanimate objects with state mutations
- ⏳ Phase 5: Interactive NPCs with dialogue and quests

---

## D-WAVE1-BURNDOWN: Triage + Deduplication Report

**Status:** ✅ Complete  
**Author:** Chalmers (Project Manager)  
**Date:** 2026-03-28

**Overview:** 91 reported issues triaged into 63 unique (28 duplicates closed). Phase 4 closed 15 Wave 1–2 integration bugs today.

**Wave 3 Assignment (39 bugs ready):**
- **Tier P0 (Critical):** 6 bugs (stress system, territorial wolves, butchery guards)
- **Tier P1 (High):** 15 bugs (combat loops, creature AI, dark sense)
- **Tier P2 (Medium):** 12 bugs (edge cases, UX clarification)
- **Tier P3 (Low):** 6 bugs (ghost objects, parser edge cases)

**Deferred to Phase 5 (15 issues):**
- Portal refactoring (6 issues, Lisa)
- Puzzle 017 (5 issues, deep-cellar chain mechanism)
- Features/design (4 issues, blocked on Wayne Q1 decisions)

**Team Assignment:**
- **Bart:** 12 bugs (engine/parser/FSM)
- **Smithers:** 16 bugs (parser/verbs/UI)
- **Flanders:** 8 bugs (objects/creatures)
- **Moe:** 1 bug (rooms)

---

## D-STRESS-HOOKS: Stress Trauma Hook Architecture

**Status:** ✅ Implemented  
**Author:** Bart (Architect)  
**Date:** 2026-03-28  
**Phase:** Phase 4 WAVE-3

**Decision:** Stress trauma hooks follow the same pattern as C11/C12 injury and stimulus hooks — minimal integration points that delegate to `injuries.add_stress()`.

**Three hooks, three files:**
1. `witness_creature_death` (death.lua)
2. `near_death_combat` (combat/init.lua)
3. `witness_gore` (butchery.lua)

**Stress debuffs as multipliers:**
- Attack penalty: 15% force reduction per point (floor 0.3×) in `resolution.resolve_damage`
- Movement penalty: Probability of movement failure + reduced flee speed in verbs
- Flee bias: Auto-selects flee in headless mode; hints in interactive mode

---

## D-CREATE-OBJECT-ACTION: Creature Object Creation Engine

**Status:** ✅ Implemented  
**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-28  
**Phase:** Phase 4 WAVE-4

**Decision:** Added `create_object` action to creature action dispatch system. This is **metadata-driven** — any creature can create environmental objects by declaring `behavior.creates_object`.

**Key Design:**
1. **Cooldown uses `os.time()` (real seconds)** — not coupled to presentation layer
2. **Object instantiation via shallow copy + `registry:register()`** — template provided in creature metadata
3. **NPC obstacle check in `navigation.lua`** — `room_has_npc_obstacle()` scans target room for `obstacle.blocks_npc_movement = true`

**Principle 8 Compliance:** No spider-specific logic anywhere. Engine reads `behavior.creates_object` metadata generically.

---

## D-WORLDS-CONCEPT: Worlds Meta Structure

**Status:** 🟢 Active  
**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-03-28  
**Category:** Architecture / Design  
**Affects:** Bart (engine boot), Moe (room design), Flanders (objects), Bob (puzzles), Brockman (docs)

**Summary:** Worlds are a new top-level meta concept that sits above Levels in the content hierarchy. A World is a thematically unified container that defines the creative atmosphere, aesthetic constraints, and design guidance for all content within it.

**Updated hierarchy:** World → Level → Room → Object/Creature/Puzzle

**Key Decisions:**
1. **World .lua file format** follows project patterns: single table return, GUID, template = "world", lazy loaded
2. **`starting_room`** lives on the World (game boot spawn); Levels retain `start_room` for intra-level respawn
3. **Theme table** is the core creative brief: `pitch`, `era`, `atmosphere`, `aesthetic` (materials + forbidden), `tone`, `constraints`
4. **Theme files** allow optional lazy-loaded `.lua` subsections for complex worlds
5. **Single-world auto-boot**: With one World, engine auto-selects — no selection UI
6. **File location**: `src/meta/worlds/` for world files, `src/meta/worlds/themes/` for subsections
7. **New template needed**: `src/meta/templates/world.lua`
8. **World 1** is "The Manor" — gothic domestic horror, late medieval

**Full specification:** `docs/design/worlds.md`

**Impact:**
- **Bart**: Implement world discovery, boot sequence, lazy loading
- **Moe**: Consult theme when designing rooms
- **Flanders**: Validate object materials against theme constraints
- **Bob**: Design puzzles within theme constraints
- **All creators**: Apply theme consistency checklist

---

## D-ENGINE-REFACTORING-WAVE2: Priority Refactoring Schedule

**Status:** 🟢 Active  
**Author:** Bart (Architect)  
**Date:** 2026-03-28  
**Category:** Architecture / Code Quality  
**Blocker:** Nelson test baselines (required before Phase 3)

**Summary:** Phase 1 code review complete. Six engine files identified for splitting in priority order.

**Priority Split Candidates:**
1. `verbs/helpers.lua` (1634 → 5 modules) — highest payoff, every verb depends on it
2. `parser/preprocess.lua` (1282 → 6 modules) — lowest risk, pure pipeline stages
3. `loop/init.lua` (624 → 4 modules) — highest contention (52 commits), zero tests
4. `verbs/sensory.lua` (1113 → 3 modules) — clean split by sense
5. `search/traverse.lua` (871 → 3 modules) — step() at 437 lines
6. `injuries/init.lua` (540 → 3 modules) — stress/injury boundary

**Sequencing (CRITICAL):**
**No refactoring starts until Nelson establishes test baselines.** Specifically:
- `loop/init.lua` needs integration tests (zero coverage on highest-contention file)
- `verbs/helpers.lua` needs per-category unit tests
- Full suite run with pass/fail counts recorded

**Affects:**
- **Nelson:** Must write baselines before Phase 3
- **Smithers/Flanders/Bart:** After helpers.lua split, re-export layer maintains `require()` compatibility
- **Smithers:** Parser preprocess split adds `parser/preprocess/` subdirectory
- **Everyone:** No refactoring on active feature branches

**Full analysis:** `docs/architecture/engine/refactoring-review-2026-03-28.md`

---

## D-LINTER-IMPL-WAVES: 6-Wave Linter Improvement Plan

**Status:** 🟢 Active  
**Author:** Bart (Architect)  
**Date:** 2026-03-28  
**Category:** Process / Testing  
**Scope:** Meta-lint improvement — all 3 phases

**Summary:** Linter improvement uses 6 waves (WAVE-0 → WAVE-5) with 5 gates, not 1:1 phase mapping.

**Rationale:** Single-file bottleneck on `lint.py` prevents parallel edits. Bug fixes (#190, #195, #196) have different owners but both need `lint.py`, so they serialize across waves. Multi-module structure enables parallel work on non-lint.py files.

**Key Decisions:**
1. **D-LINTER-EXIT-VERIFIED**: EXIT-01 through EXIT-07 already implemented in rule_registry.py; WAVE-4 verifies correctness, not implementation
2. **D-LINTER-CREATURE-GREENFIELD**: 0 of 20 CREATURE-* rules exist; WAVE-4 implements all (~150 LOC lint.py + 20 entries registry)
3. **D-LINTER-TEST-INFRA**: Use pytest for linter tests (linter is Python); Nelson builds infrastructure in WAVE-0
4. **D-LINTER-FIX-AUDIT**: Two-phase (offline docs in WAVE-2, integration in WAVE-3) avoids rule_registry conflicts

**Wave Mapping:**
- **Phase 1** → WAVE-1 (bugs #190/#196), WAVE-2 (bug #195 + audit), WAVE-3 (classification + CLI)
- **Phase 2** → WAVE-4 (EXIT/CREATURE verification + implementation), WAVE-5 (environment variants)
- **Phase 3** → WAVE-5 (routing/caching enhancements — already partially implemented)

**Affected Agents:**
- **Nelson** — most impacted, builds pytest infrastructure
- **Smithers, Flanders** — bug owners, serialize across waves
- **Sideshow Bob** — scope reduced to EXIT-* test fixtures only
- **Bart** — sole lint.py editor in WAVE-4

**Full plan:** `plans/linter/linter-implementation-plan.md`

---

## Standing Directives

### D-WAYNE-CODE-REVIEW-DIRECTIVE (2026-03-24)

**Status:** 🟢 Active  
**Author:** Wayne "Effe" Berry

All PRs must include **code review summaries** from lead team members before merge. No review = no merge.

### D-TESTFIRST

**Status:** 🟢 Active

Every bug fix must include regression tests verifying the fix. TDD workflow:
1. Write failing test demonstrating the bug
2. Make the fix
3. Verify test passes + no regressions

### D-HEADLESS

**Status:** 🟢 Active

For automated testing, always use `--headless` mode to disable TUI, suppress prompts, emit `---END---` delimiters.

---

---

## D-HELPERS-SPLIT-PHASE3: Modularization of verbs/helpers.lua

**Status:** ✅ Implemented  
**Author:** Bart (Architect)  
**Date:** 2026-03-28  
**Phase:** Phase 3 Engine Refactoring (Wave 1)

**Decision:** Split `src/engine/verbs/helpers.lua` (1634 LOC) into focused modules under `src/engine/verbs/helpers/`:
- `core.lua` — shared dependencies, time/light helpers
- `inventory.lua` — hands, part detach/reattach, inventory weight
- `search.lua` — keyword matching, find_visible, search subroutines
- `tools.lua` — tool capability lookup, charge handling
- `mutation.lua` — container access, mutations, spatial movement
- `combat.lua` — self-infliction, try_fsm_verb
- `portal.lua` — portal lookup, bidirectional sync

**Outcome:** Re-export layer maintains API compatibility; all 1634 lines split with zero behavior change.

---

## D-PREPROCESS-SPLIT-PHASE3: Modularization of parser/preprocess.lua

**Status:** ✅ Implemented  
**Author:** Bart (Architect)  
**Date:** 2026-03-28  
**Phase:** Phase 3 Engine Refactoring (Wave 1)

**Decision:** Split `src/engine/parser/preprocess.lua` (1282 LOC) into focused submodules:
- Data structures
- Word helpers
- Core parsing
- Phrase transforms
- Compound actions
- Movement transforms
- Command splitting

**Constraints:** Zero behavior changes; preserve public API; maintain pipeline ordering and test expectations.

---

## D-SENSORY-SPLIT-PHASE3: Modularization of verbs/sensory.lua

**Status:** ✅ Implemented  
**Author:** Bart (Architect)  
**Date:** 2026-03-28  
**Phase:** Phase 3 Engine Refactoring (Wave 1)

**Decision:** Split `src/engine/verbs/sensory.lua` (1113 LOC) into focused modules under `src/engine/verbs/sensory/`:
- look.lua
- touch.lua
- search.lua
- smell.lua
- taste.lua
- listen.lua

**Constraints:** Zero behavior changes; preserve verb registration and aliasing; maintain output text and order.

---

## D-TRAVERSE-EFFECTS-SPLIT-PHASE3: Modularization of traverse_effects.lua

**Status:** ✅ Implemented  
**Author:** Bart (Architect)  
**Date:** 2026-03-28  
**Phase:** Phase 3 Engine Refactoring (Wave 1)

**Decision:** Split `src/engine/traverse_effects.lua` into:
- `engine/traverse_effects/registry.lua` — registry + processing
- `engine/traverse_effects/effects.lua` — built-in handlers

Thin wrapper preserves public API and auto-registers built-ins.

**Constraints:** Zero behavior changes; preserve handler registration and processing semantics.

---

## D-WORLDS-IMPL-PLAN: Worlds Phase 1 Engine Implementation

**Status:** 🟢 Active  
**Author:** Bart (Architect)  
**Date:** 2026-03-28  
**Phase:** Phase 3 (Worlds Phase 1)

**Decision:** Implement Phase 1 Worlds architecture per D-WORLDS-PLAN and CBG's design spec:

1. **New module:** `src/engine/world/init.lua` — World discovery, loading, selection, starting-level resolution
2. **Zero fallback:** No world files = FATAL error (fail fast)
3. **Metadata placement:** World table on `context.world`, NOT in registry
4. **One-directional:** World → Level only; Levels do NOT reference parent World
5. **Dependency injection:** Zero require() calls in world.lua; all deps passed as parameters
6. **Level dir resolution:** Use `level_dir` parameter to construct level file paths

**Implementation impact:**
- **main.lua:** ~30 lines added, ~15 removed
- **context:** Gains `world` field
- **Tests:** 21 new tests across 2 files

**Affects:**
- **Nelson:** Tests gate Phase 1 acceptance
- **Smithers, Moe, Flanders, Bob:** Phase 2 content design uses world theme

---

## D-WORLDS-DESIGN: Worlds Design Plan

**Status:** 🟢 Active  
**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-03-28  
**Category:** Design / Architecture

**Summary:** The Worlds Design Plan (`plans/worlds/worlds-design.md`) defines the complete roadmap for integrating Worlds into the game.

**Key Decisions:**
1. Three-phase rollout: Phase 1 (engine boots from World), Phase 2 (theme integration), Phase 3 (multi-world design)
2. Phase 1 scope deliberately minimal — zero visible player change
3. Fail fast, not fallback
4. World boot logic in new module (`engine/world/init.lua`)
5. World NOT registered in registry
6. One-directional: World → Level only
7. Theme is design guidance only (not consumed by engine in V1)
8. Theme files merge via deep_merge

**Affects:** Bart (engine), Nelson (tests), Brockman (docs), Smithers (context), Moe/Flanders/Bob (content)

---

## D-WORLDS-LUA-IMPL: Flanders — World .lua Implementation

**Status:** ✅ Implemented  
**Author:** Flanders (Object & Injury Systems Engineer)  
**Date:** 2026-03-28  
**Phase:** Phase 3 (Worlds Phase 1)

**Decision:** Created first World definition file and supporting infrastructure per CBG's spec.

**Files created:**
| File | Purpose |
|------|---------|
| `src/meta/worlds/world-01.lua` | World 1 "The Manor" — full definition with theme, level references, starting room |
| `src/meta/templates/world.lua` | Base world template with empty defaults |
| `src/meta/worlds/themes/` | Directory for future theme subsection files |

**Key details:**
- GUID: `fbfaf0de-c263-4c05-b827-209fac43bb20`
- starting_room: `start-room` (matches level-01.lua)
- Theme: Fully populated per spec
- theme_files: Placeholder comments for manor-architecture.lua, manor-creatures.lua, manor-history.lua

**Affects:** Bart (engine boot discovery), Moe (room theme constraints), Bob (puzzle design constraints)

---

## DIRECTIVE-2026-03-28T1332Z: User Directive — Test Baseline Discovery

**Status:** 🟢 Active  
**Author:** Wayne "Effe" Berry (via Copilot)  
**Date:** 2026-03-28

**Directive:** All pre-existing test failures discovered during engine code review baselines must be logged as separate GitHub issues. Don't waste the discovery effort. Update the engine-code-review skill to include this as a standard step.

---

## DIRECTIVE-2026-03-28T1444Z: User Directive — Test Baseline Before Refactor

**Status:** 🟢 Active  
**Author:** Wayne "Effe" Berry (via Copilot)  
**Date:** 2026-03-28

**Directive:** Engine code review skill must log ALL pre-existing test failures as GitHub issues during the first baseline test pass, then STOP. Do not continue to the refactor phase. This allows the caller to run work-down-issues skill to get the baseline to zero bugs before refactoring.

**Rationale:** Earned lesson — Bart spent 80+ minutes debugging because the baseline had 90 pre-existing failures mixed in with his work. Baseline is meaningless if contaminated by pre-existing bugs.

---

## D-ISSUE-PRIORITIES: Issue Priority Triage — Pre-Refactor Baseline

**Status:** 🟢 Active  
**Author:** Marge (Test Manager)  
**Date:** 2026-03-28  
**Category:** Process / Quality

**Summary:** All 17 open issues (#8–#24) from Nelson's pre-refactor test baseline have been triaged, prioritized, and labeled.

**Priority assignment:**
| Priority | Issues | Count |
|----------|--------|-------|
| CRITICAL | #8, #9 | 2 |
| HIGH | #10, #11, #12, #20, #24 | 5 |
| MEDIUM | #14, #15, #16, #17, #18, #19, #22 | 7 |
| LOW | #13, #21, #23 | 3 |

**Key findings:**
- #8 and #9 CRITICAL (movement + door interaction foundational)
- #20 and #24 share root cause (require path fix — quick win)
- No refactoring starts until CRITICALs resolved
- Quick wins: #14, #15, #16, #18, #20/#24

**Team assignment:**
- **Bart:** 6 issues (#10, #14, #17, #20, #21, #24)
- **Smithers:** 8 issues (#8, #9, #11, #12, #13, #15, #19, #22, #23)
- **Flanders:** 3 issues (#16, #18)

---

## D-TEST-BASELINE: Nelson — Pre-Refactor Test Baseline Established

**Status:** 🟢 Active  
**Author:** Nelson (Tester)  
**Date:** 2026-03-28  
**Phase:** Engine Code Review — Phase 2

**Decision:** Pre-refactor test baseline is established. No refactoring should begin until Bart reviews this baseline.

**Baseline numbers:**
| Metric | Before | After (with new tests) |
|--------|--------|----------------------|
| Test files | 243 | 245 (+3 new) |
| Passed | 6,704 | 6,770 |
| Failed | 87 | 86 |
| Total assertions | 6,791 | 6,856 |

**Pre-existing failures (4 files):** silk-crafting, predator-prey, spider-web, combat-verbs (predate this work).

**New test files:**
1. `test/verbs/test-helpers-api.lua` — 74 assertions on helpers.lua public API
2. `test/verbs/test-sensory-verbs.lua` — 37 assertions on sensory verb handlers
3. `test/verbs/test-acquisition-verbs.lua` — 28 assertions on take/get/drop handlers

**High-risk modules for refactoring:**
| Module | Lines | Risk |
|--------|-------|------|
| verbs/helpers.lua | 1,634 | **Now covered** (74 tests) |
| verbs/sensory.lua | 1,113 | **Now covered** (37 tests) |
| verbs/acquisition.lua | 792 | **Now covered** (28 tests) |
| verbs/fire.lua | 725 | Partial (existing test-fire-verbs.lua) |
| loop/init.lua | 624 | **Uncovered** — hard to unit test |
| verbs/meta.lua | 543 | **Uncovered** |
| verbs/equipment.lua | 482 | **Uncovered** |

**Critical note:** Do NOT modify these 3 new test files during refactoring. They exist to catch behavioral regressions.

---

---

## D-CREATURE-ZONE-NAMES: Creature-Specific Body Zone Narration

**Status:** ✅ Implemented  
**Author:** Flanders (Object & Injury Systems Engineer)  
**Date:** 2026-07-20  
**Issues:** #369, #337  
**Phase:** Wave 3 (Parallel Fix)

### Decision

Modified `src/engine/combat/narration.lua::zone_text()` to accept an optional `body_tree` parameter. If the zone has a `names` array, `zone_text()` picks narration from those instead of the default hardcoded `zone_words` table.

### Implementation

1. **Object-side:** Added `names` array to each body_tree zone in creature metadata (all 5 creatures: spider, rat, wolf, cat, bat)
2. **Engine-side:** 6-line change to `narration.lua`; fallback path unchanged
3. **Principle 8 Compliance:** Objects declare behavior (names); engine executes it generically

### Impact

- All creatures now narrate anatomically correct zone names (spider "cephalothorax" instead of "chest")
- 13 TDD tests validate creature narration
- Zero regressions (255/255 test files pass)

---

## D-TERRITORY-SENSORY-FIXES: Territory Markers + Narration Cleanup

**Status:** ✅ Implemented  
**Author:** Flanders (Object & Injury Systems Engineer)  
**Date:** 2026-07-20  
**Issues:** #296, #312, #323, #338, #346  
**Phase:** Wave 4 (Parallel Fix)

### Cross-Domain Changes

| File | Domain | Change | Reason |
|------|--------|--------|--------|
| `src/engine/creatures/territorial.lua` | Bart | Territory markers use unique ids (`territory-marker-{uid}`) instead of shared id | Shared id caused registry overwrite |
| `src/engine/creatures/init.lua` | Bart | `_last_marked_room` only set on successful mark | Previous failure-set prevented retry |
| `src/engine/combat/narration.lua` | Bart | `material_text("tooth-enamel")` returns clean subset; `render()` removes dangling prepositions | Raw material names leaked into prose |
| `src/engine/verbs/sensory/smell.lua` | Smithers | Added `seen_ids` deduplication; state-aware sensory text | Creatures appeared twice; missing FSM state awareness |
| `src/engine/verbs/sensory/listen.lua` | Smithers | Same as smell.lua | Same root cause |

### Metadata Changes

- `src/meta/rooms/cellar.lua`: Added cellar-spider-web instance
- `src/meta/creatures/wolf.lua`: Added behavior.lingering_scent metadata

### Impact

- Territory markers now persistent + retrievable
- Creature narration clean (no dangling prepositions, no raw material names)
- Sensory deduplication prevents creature double-reporting
- 21 TDD tests validate all fixes
- Zero regressions (255/255 test files pass)

---

## D-EXIT-DOOR-RESOLUTION: Smithers — Exit Door Fallback Pattern

**Status:** 🟢 Active  
**Author:** Smithers (UI Engineer)  
**Date:** 2026-03-28  
**Affects:** Bart, Moe, Flanders, verb handlers  

### Decision

Any verb handler that acts on doors (open, close, lock, unlock, knock, bash, etc.) **MUST** search oom.exits as a fallback after ind_visible() returns nil. Exit doors are NOT registry objects — they live as plain tables in oom.exits[direction].

Use ind_exit_by_keyword(ctx, noun) from ngine.verbs.helpers.search to resolve exits by direction name, keyword, name substring, or target room id. Returns (exit_table, direction_key) or (nil, nil).

### Rationale

Issues #387 and #388 revealed that exit doors were completely invisible to verb handlers because ind_visible() only searches the registry. This caused 43 test failures across movement, open, close, unlock, and lock verbs.

### Impact

- New verb handlers that interact with doors must include the exit fallback pattern
- Portal objects (D-PORTAL-ARCHITECTURE) are separate — they ARE registry objects and get found by ind_visible(). This fallback is only for legacy oom.exits entries.
- Fixes committed in 031b27d (Smithers)

---

## D-CREATE-OBJECT-TEMPLATE: Flanders — Template Instantiation for Creature Objects

**Status:** 🟢 Active  
**Author:** Flanders (Object Designer)  
**Date:** 2026-03-28  
**Affects:** Bart (engine), all creature designers  

### Context

The xecute_action("create_object") handler in src/engine/creatures/actions.lua previously used obj_spec.object_def (an inline object table) to build instances. Creature metadata like the spider specified 	emplate = "spider-web" instead, which was ignored. The handler also lacked support for max_per_room.

### Decision

1. When creates_object.template is set, the engine now calls egistry:instantiate(template) to create a proper deep-copy with a new GUID.
2. creates_object.max_per_room is enforced natively by counting objects in the room whose id starts with the template name.
3. object_def path is preserved as fallback for inline definitions.

### Impact

- Creature authors should use 	emplate (referencing an object in src/meta/objects/) rather than object_def for created objects.
- max_per_room is now a first-class declarative field — no need for condition functions.
- Bart: please review the ctions.lua changes when convenient. Flanders crossed into engine territory to unblock #379.
- Generic capability added to engine (not object-specific logic per Principle 8)
- Fixes committed in 4827a5e (Flanders)

