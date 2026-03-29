# Squad Decisions

**Last Updated:** 20260329T000802Z  
**Last Merge:** 20260329T000802Z (3 decisions from phase5/linter inbox merged)
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
| D-MUTATION-LINT-PIVOT | Process | 🟢 Active | Mutation graph linter uses expand-and-lint (Python meta-lint) instead of standalone Lua graph library |
| D-PARALLEL-EXPAND-LINT | Process | 🟢 Active | Objects expanded and linted in parallel — each object's mutation targets can run concurrently |
| D-MUTATION-EDGE-EXTRACTION | Process | 🟢 Active | 5 mutation edge types formalized: file-swap, destruction, state-transition, composite-part, linked-exit |
| D-LINTER-IMPL-WAVES | Process | 🟢 Active | Linter improvement: 6 waves with 5 gates, serialized lint.py edits |
| D-WAYNE-PHASE5-DECISIONS | Process | 🟢 Active | Phase 5 scope: werewolf NPC, salt-only preservation, defer A*/env-combat/humanoid NPCs |
| D-LINTER-ENGINEER-HIRE | Process | 🟢 Active | Hire dedicated linter engineer (Wiggum) to own 306-rule Python linter system |
| D-FLANDERS-META-OWNERSHIP | Architecture | 🟢 Active | Flanders owns ALL src/meta/objects engineering; Bart focuses on src/engine/ only |
| D-TEST-SPEED-IMPL-WAVES | Process | 🟢 Active | Test speed: 5-wave, 4-gate implementation; Nelson owns run-tests.lua; benchmark gating |
| D-BENCHMARK-GATING | Testing | 🟢 Active | Benchmark files use `bench-*.lua` prefix; `--bench` flag includes benchmarks |
| D-WAVE1-ALREADY-IMPLEMENTED | Testing | ✅ Complete | WAVE-1 regression tests pass; GATE-1 ready |
| D-XF03-UNPLACED-OBJECTS | Testing | 🟢 Active | Unplaced objects retain WARNING-level XF-03; disambiguation requires room context |
| D-ENGINE-REFACTORING-REVIEW | General | 🟢 Active | Ongoing engine architecture review |
| D-HIRING-DEPT | General | 🟢 Active | All new hires must have department assignment |
| D-WAYNE-CODE-REVIEW-DIRECTIVE | Process | 🟢 Active | Mandatory code review before pull requests |
| D-TESTFIRST | Testing | 🟢 Active | Test-first directive for all bug fixes |
| D-EXIT-DOOR-RESOLUTION | Architecture | 🟢 Active | Exit door fallback pattern for verb handlers (Smithers) |
| D-CREATE-OBJECT-TEMPLATE | Architecture | 🟢 Active | Spider web uses template instantiation + max_per_room (Flanders) |
| D-TEMP-DIR-DIRECTIVE | Process | 🟢 Active | Temp files → temp/ directory; keep repo root clean |
| D-SURFACE-OBJECT-NARRATION | Architecture | ✅ Implemented | Surface object undirected narration fix (#394, Flanders) |
| D-CREATURE-ZONE-NAMES | Architecture | ✅ Implemented | Creature-specific body zone narration names; engine-side zone_text(zone, body_tree) |
| D-TERRITORY-SENSORY-FIXES | Architecture | ✅ Implemented | Territory marker registration, narration cleanup, sensory deduplication |
| D-WAVE1-BUTCHERY-CREATURES-SPLIT | Architecture | ✅ Implemented | creatures/init.lua split to actions.lua; -190 LOC headroom |
| D-WAVE1-BURNDOWN | Process | ✅ Complete | Triaged 54 issues, 39 Wave 3 ready, 15 deferred to Phase 5 |
| D-WAVE5-BEHAVIORS | Architecture | ✅ Implemented | Pack tactics, territorial, ambush behavior engine design |
| D-CREATE-OBJECT-ACTION | Architecture | ✅ Implemented | Metadata-driven creature object creation + NPC obstacle detection |
| D-STRESS-HOOKS | Architecture | ✅ Implemented | Stress trauma hooks delegate to central injuries.add_stress() API |

---

## D-WAYNE-PHASE5-DECISIONS: Phase 5 Scope Decisions

**Status:** 🟢 Active  
**Author:** Wayne "Effe" Berry  
**Date:** 2026-03-28T23:33Z  
**Category:** Process / Planning

### Summary

Phase 5 scope locked on 7 key decisions:

| Decision | Option | Rationale |
|----------|--------|-----------|
| Q1: Werewolf Feature | Option B (NPC type, separate creature) | Not a disease; creatures are separate game objects |
| Q2: Food Preservation | Option A (salt-only, ~80 LOC) | Minimal, focused implementation |
| Q3: Humanoid NPCs | Option C (defer to Phase 6) | Heavy lift; keep Phase 5 lean |
| Q4: Pack Role System | Option A (simplified: stagger attacks, alpha by health) | Behavioral depth without A* |
| Q5: A* Pathfinding | Option B (defer to Phase 6+) | Complex; defer |
| Q6: Environmental Combat | Option B (defer to Combat Phase 3) | Out of Phase 5 scope |
| Q7: Portal Refactoring | Removed from Phase 5 scope | Track independently as #203-208 |

### Rationale

Keep Phase 5 focused on **Level 2 foundation + creature expansion + salt preservation**. Defer heavy systems (humanoid NPCs, A* pathfinding, environmental combat) to future phases. Portal refactoring is infrastructure work, not NPC/Combat scope.

### Impact

- **Flanders/Moe:** Clear object/room requirements for Phase 5
- **Bart:** Creature behavior system scoped (no A*, no humanoid NPC engine)
- **All agents:** Phase 5 is greenlit and ready to execute

---

## D-LINTER-ENGINEER-HIRE: Dedicated Linter Engineer

**Status:** 🟢 Active  
**Author:** Wayne "Effe" Berry (via Copilot)  
**Date:** 2026-03-28T23:35Z  
**Category:** Process / Team

### Decision

Hire a dedicated engineering role to maintain and evolve the linter system. The linter has grown to 306 rules, 6 Python modules, mutation-edge-check, 2 wrapper scripts, and CI integration — too complex for shared ownership across Bart/Nelson/Lisa.

### New Role: Wiggum (Linter Engineer)

- **Domain:** `scripts/meta-lint/`, `scripts/mutation-lint.ps1`, linter CI integration
- **Responsibilities:** Evolve linter rules, maintain mutation-edge-check, CI pipelines
- **Reports to:** Bart (Architecture Lead)
- **Owns:** All lint rule creation and modification; acts as single point of contact for lint issues

### Charter

[See `.squad/agents/wiggum/charter.md`]

### Impact

- **Bart:** Wiggum becomes dedicated linter point-of-contact
- **Nelson:** Wiggum + Nelson share testing responsibilities for linter
- **All agents:** Lint questions → Wiggum
- **Consistency:** Single owner prevents rule conflicts and drift

---

## D-FLANDERS-META-OWNERSHIP: Flanders Owns All Meta Object Engineering

**Status:** 🟢 Active  
**Author:** Wayne "Effe" Berry (via Copilot)  
**Date:** 2026-03-28T23:56Z  
**Category:** Architecture / Team

### Decision

**Flanders** has sole ownership of all meta object engineering in `src/meta/objects/`. **Bart does NOT create object .lua files.** Bart owns `src/engine/` and engine-level features only.

### Ownership Boundary

| Directory | Owner | Notes |
|-----------|-------|-------|
| `src/meta/objects/**` | **Flanders** | Object definitions, mutations, states, sensory text |
| `src/meta/rooms/**` | **Moe** | Room definitions, exit layout, object instances |
| `src/meta/levels/**` | **Moe** | Level definitions |
| `src/meta/injuries/**` | **Flanders** | Injury type definitions |
| `src/engine/**` | **Bart** | Engine architecture, module design, FSM, effects, verbs |
| `scripts/meta-lint/` | **Wiggum** | Linter rules and evolution |

### Rationale

During linter Phase 1 fixes, Bart created `wood-splinters.lua` and `poison-gas-vent-plugged.lua` to resolve broken mutation edges. This crosses into Flanders' domain. Objects declare behavior; Bart executes it (Principle 8). Clear boundaries reduce merge conflicts and duplication.

### Impact

- **Bart:** Focus on engine features; file bugs when object changes are needed
- **Flanders:** Single point of contact for all `src/meta/objects/` work
- **Consistency:** No dual object ownership; cleaner code review
- **Principle 8 Compliance:** Engine executes object metadata generically

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

---

## D-TEST-SPEED-IMPL-WAVES: Test Speed Implementation Plan

**Status:** 🟢 Active  
**Author:** Bart (Architect)  
**Date:** 2026-08-22  

### Decision

Test speed improvement follows a 5-wave, 4-gate implementation plan covering design phases 1–3.

**Key architecture decisions affecting other agents:**

1. **Nelson owns ALL `run-tests.lua` modifications.** No other agent touches this file. Nelson adds `--bench` (WAVE-1), `--shard` (WAVE-2), and `--changed` (WAVE-4) flags sequentially.

2. **Parallel runner is a SEPARATE file.** `test/run-tests-parallel.ps1` (Windows) and `test/run-tests-parallel.sh` (Unix) are new files. `run-tests.lua` remains the serial fallback — no structural changes.

3. **Benchmark files use `bench-*` naming convention.** Rename `test-inverted-index.lua` → `bench-inverted-index.lua` (and similar). Runner skips `bench-*` by default; `--bench` flag includes them.

4. **CI uses 6 named shards:** `parser`, `verbs`, `creatures`, `rooms`, `search`, `other`. The `--shard` flag in `run-tests.lua` filters by directory name. `other` is a catch-all for everything not in a named shard.

5. **Three files maintain test directory lists** (run-tests.lua, .ps1, .sh). When adding a new test directory, all three must be updated. Shared config extraction deferred.

6. **CI auto-issues are per-shard** (not one mega-issue). Labels: `bug`, `ci-failure`, `squad:nelson`. `ci-failure` label must be created if it doesn't exist.

### Affects

- **Nelson:** Primary implementer for run-tests.lua changes
- **Gil:** CI workflow owner (squad-ci.yml)
- **Brockman:** Documentation deliverables in WAVE-3 and WAVE-4
- **Marge:** Gate verification at every gate
- **All agents adding test directories:** Must update 3 files

---

## D-BENCHMARK-GATING: Benchmark Gating Convention

**Status:** 🟢 Active  
**Author:** Nelson (Tester)  
**Date:** 2026-08-22  

### Decision

- Benchmark files use `bench-*.lua` prefix (not `test-*`).
- `lua test/run-tests.lua` skips benchmarks by default.
- `lua test/run-tests.lua --bench` includes benchmarks.
- `test-bm25-deep.lua` is classified as CORRECTNESS (not a benchmark) despite the name — it asserts on expected verb/noun values, not speed.

### Rationale

Two files consumed ~65s of the ~180s test suite (inverted-index + tier2-benchmark). Gating them behind `--bench` drops default developer runtime by ~36%. The naming convention (`bench-*`) is grep-able, requires no config files, and matches the plan in `plans/testing/test-speed-implementation-phase1.md`.

### Impact

- **Nelson/Marge:** Default test runs are faster. Use `--bench` for full regression.
- **Gil (CI):** CI can run `--bench` on nightly, skip on PR checks for speed.
- **All agents:** New performance-only test files should use `bench-` prefix.

---

## D-WAVE1-ALREADY-IMPLEMENTED: WAVE-1 Fixes Already Implemented

**Status:** ✅ Complete  
**Author:** Nelson (Tester)  
**Date:** 2026-07-29  

### Context

While building WAVE-0/WAVE-1 test infrastructure per the linter improvement plan, discovered that WAVE-1 code changes for both XF-03 (#190) and XR-05 (#196) are **already implemented** in `lint.py` and `config.py`:

- **XF-03:** Room-aware keyword collision filtering, disambiguator detection, cross-room severity downgrade, and `get_rule_config()` API are live.
- **XR-05:** Template material="generic" suppression is live. XR-05b object-level detection works.
- **config.py:** `DEFAULT_RULE_CONFIG` with `XF-03.allowed_shared` and `XF-03.cross_room_severity` exists. `CheckConfig.get_rule_config()` method exists.

### Decision

All 8 WAVE-1 regression tests pass against the current codebase. **GATE-1 can be evaluated now** — no further code changes needed for WAVE-1.

### Impact

- Smithers: No WAVE-1 work remaining on lint.py
- Bart: No WAVE-1 work remaining on config.py
- Coordinator: Can skip WAVE-1 implementation and proceed to GATE-1 evaluation

---

## D-XF03-UNPLACED-OBJECTS: XF-03 Unplaced Object Handling

**Status:** 🟢 Active  
**Author:** Smithers (UI Engineer)  
**Date:** 2026-07-21  
**Issues:** #190 (XF-03 false positives)

### Decision

Objects not placed in any room (no GUID referenced in room instances) retain WARNING-level XF-03 severity for shared keywords. Disambiguation logic only applies to objects with confirmed same-room placement.

### Rationale

Three-tier XF-03 severity requires room context:
1. **Cross-room (INFO):** Both objects confirmed in different rooms
2. **Same-room (disambiguation):** Both objects confirmed sharing a room
3. **Unplaced (WARNING):** Either object lacks room assignment → conservative

Applying disambiguation to unplaced objects would suppress warnings for objects still being authored. Keeping WARNING ensures keyword collisions are visible until room placement confirms the context.

### Impact

No change to XF-03 behavior. Rule remains active as-is for V1.

---

## D-MUTATION-LINT-PIVOT: Mutation Graph Linter — Expand-and-Lint

**Status:** 🟢 Active  
**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-28  
**Requested by:** Wayne "Effe" Berry  
**ID:** D-MUTATION-LINT-PIVOT

### Decision

The mutation graph linter will use an **expand-and-lint** approach instead of a standalone Lua graph validator.

**Old approach (superseded):**
- Pure-Lua graph library with BFS/DFS, cycle detection, unreachable node detection
- ~350-400 LOC in `test/meta/test-mutation-graph.lua`
- ~240 tests across 7 test suites
- Custom validation logic duplicating what the Python linter already does

**New approach (active):**
- **Lua edge extractor** (`scripts/mutation-edge-check.lua`, ~100-150 LOC): scans `src/meta/`, extracts 5 mutation edge types, verifies target file existence
- **Python meta-lint** (`scripts/meta-lint/lint.py`): receives target files, applies full 200+ rules
- **Wrapper script** (`scripts/mutation-lint.ps1`): runs both tools in sequence
- 3 waves / 2 gates instead of 4 waves / 3 gates

### Rationale

- Composing existing tools is simpler and more powerful than building a custom validator
- Full 200+ rule coverage on mutation targets comes for free
- No duplicate validation code
- Edge existence is a simple file-exists test — no graph library needed

### Impact

| Agent | Impact |
|-------|--------|
| **Bart** | Writes `scripts/mutation-edge-check.lua` (~100-150 LOC instead of ~350-400) |
| **Nelson** | Tests the extractor (simpler test surface — ~30-40 tests instead of ~240) |
| **Brockman** | Documentation scope reduced (no graph algorithm to explain) |
| **Flanders** | No change — still creates missing target files when issues are filed |

### Supersedes

This decision supersedes any prior plans to build `test/meta/test-mutation-graph.lua` as a graph library with cycle detection, BFS/DFS, or unreachable node analysis.

---

## D-PARALLEL-EXPAND-LINT: Parallel Mutation Expansion and Linting

**Status:** 🟢 Active  
**Author:** Wayne "Effe" Berry (via Copilot)  
**Date:** 2026-03-28  
**ID:** D-PARALLEL-EXPAND-LINT

### Decision

Objects can be expanded and linted in parallel — the Lua edge extractor and Python meta-lint don't need to run serially. Each object's mutation targets can be expanded and linted concurrently, with outputs combined for the final report.

### Rationale

With 91+ meta files and 47+ mutation edges, serial processing (one object → expand → lint → next) is slower than parallel. Parallel execution (expand all → lint all targets concurrently → collect results) scales to CI environments with 4+ workers.

### Implementation Notes

- **Edge extractor** (`mutation-edge-check.lua`) outputs all edges upfront (not streaming)
- **Python lint step** (`lint.py --parallel`) runs with `-j {worker_count}` (default: 4)
- **Output collection:** Wrapper script collects per-file lint results, then prints sequentially (no interleaving)

### Impact

- WAVE-1 linter execution time reduced from ~2m (serial) to ~30s (parallel, 4 workers)
- CI integration must collect output to prevent interleaving (Smithers UX requirement)

---

## D-MUTATION-EDGE-EXTRACTION: 5 Mutation Edge Types

**Status:** 🟢 Active  
**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-28  
**ID:** D-MUTATION-EDGE-EXTRACTION

### Decision

Five formalized mutation edge types capture all state change patterns in the engine:

| Type | Pattern | Example | Target |
|------|---------|---------|--------|
| **file-swap** | `mutations[verb].becomes` | `break → mirror-broken` | Sibling `.lua` file |
| **destruction** | `mutations[verb].becomes = nil` | `burn → (nil)` | None (object vanishes) |
| **state-transition** | `transitions[i].to` (FSM state names) | `lock → locked` | Internal FSM state (no file) |
| **composite-part** | `detachable_parts[part].becomes` | `cut limb → limb-severed` | Sibling `.lua` file |
| **linked-exit** | `mutations[verb].becomes_exit` | `plug hole → exit closed` | Room exit state property |

### Coverage

- **File-swap edges:** Must verify target `.lua` file exists (linter rule XM-01)
- **Destruction edges:** No target file needed (by design)
- **State-transition edges:** No target file needed (internal FSM)
- **Composite-part edges:** Must verify target `.lua` file exists (linter rule XM-02)
- **Linked-exit edges:** No target file needed (exit is runtime-updated)

### Broken Edge Handling

- **Broken edges** = file-swap or composite-part edges where target file does NOT exist
- **Linter reports:** Exit code 1 + stderr list of broken edges + issue template
- **Developer action:** Create target file or update `becomes` field

### Impact

This taxonomy enables the edge extractor to classify mutations and determine which need file-existence checks.


- **Flanders/Moe:** Object/room authors see WARNINGs for unplaced objects with shared keywords. These resolve to INFO automatically once objects are placed in different rooms.
- **Nelson:** Test 4 in `test_xf03.py` (disambiguator suppression) uses unplaced objects — stays xfail until a future wave adds room context to the test fixtures.



---

# Decision: Mutation Graph Linter — Pivot to Expand-and-Lint

**Author:** Bart (Architecture Lead)
**Date:** 2026-08-23
**Requested by:** Wayne "Effe" Berry
**Status:** 🟢 Active
**ID:** D-MUTATION-LINT-PIVOT

## Decision

The mutation graph linter will use an **expand-and-lint** approach instead of a standalone Lua graph validator.

### Old approach (superseded):
- Pure-Lua graph library with BFS/DFS, cycle detection, unreachable node detection
- ~350-400 LOC in `test/meta/test-mutation-graph.lua`
- ~240 tests across 7 test suites
- Custom validation logic duplicating what the Python linter already does

### New approach (active):
- **Lua edge extractor** (`scripts/mutation-edge-check.lua`, ~100-150 LOC): scans `src/meta/`, extracts 5 mutation edge types, verifies target file existence
- **Python meta-lint** (`scripts/meta-lint/lint.py`): receives target files, applies full 200+ rules
- **Wrapper script** (`scripts/mutation-lint.ps1`): runs both tools in sequence
- 3 waves / 2 gates instead of 4 waves / 3 gates

### Rationale
- Composing existing tools is simpler and more powerful than building a custom validator
- Full 200+ rule coverage on mutation targets comes for free
- No duplicate validation code
- Edge existence is a simple file-exists test — no graph library needed

## Impact

| Agent | Impact |
|-------|--------|
| **Bart** | Writes `scripts/mutation-edge-check.lua` (~100-150 LOC instead of ~350-400) |
| **Nelson** | Tests the extractor (simpler test surface — ~30-40 tests instead of ~240) |
| **Brockman** | Documentation scope reduced (no graph algorithm to explain) |
| **Flanders** | No change — still creates missing target files when issues are filed |

## Files Changed

- `plans/linter/mutation-graph-linter-design.md` — Rewritten Phase 2, updated Phases 1/3/4
- `plans/linter/mutation-graph-linter-implementation-phase1.md` — Deleted old, created new (3 waves / 2 gates)

## Supersedes

This decision supersedes any prior plans to build `test/meta/test-mutation-graph.lua` as a graph library with cycle detection, BFS/DFS, or unreachable node analysis.


---

### 2026-03-28T22:13: User directive
**By:** Wayne Berry (via Copilot)
**What:** Objects can be expanded and linted in parallel — the Lua edge extractor and Python meta-lint don't need to run serially. Each object's mutation targets can be expanded and linted concurrently, with outputs combined for the final report.
**Why:** User request — captured for team memory. Affects mutation-graph-linter design and implementation plan.


---

# Smithers — Mutation Graph Linter UI/Parser Review

**Author:** Smithers (UI Engineer)
**Date:** 2026-08-23
**Reviewing:** `plans/linter/mutation-graph-linter-implementation-phase1.md` + `plans/linter/mutation-graph-linter-design.md`
**Requested by:** Wayne Berry

---

## OUTPUT FORMAT ISSUES

### 1. The ⚡ symbol for dynamic paths is novel — no precedent in the codebase

The design proposes `⚡ paper → write (mutator: write_on_surface)` for dynamic paths. The lightning bolt symbol is not used anywhere else in the project. The existing conventions are:

- `✓` / `✗` — used in `run-tests-parallel.sh`
- `⚠` (U+26A0) — used in `lint.py` for stderr warnings
- Plain `PASS`/`FAIL`/`RESULT:` — used in `test-helpers.lua` and `run-tests.lua`

**Recommendation:** Replace `⚡` with `⚠` (already established for warnings) or plain text `[DYNAMIC]` prefix. Keep the symbol vocabulary small. If we want to distinguish "broken" from "dynamic," use `✗` for broken and `⚠` for dynamic — both are already in the project palette.

### 2. The report header uses inconsistent indentation style

The proposed report:
```
=== Mutation Edge Report ===
  Files scanned:  91
  Edges found:    47
```

The Python linter uses `=== {label} ({count}) ===` for group headers. The test runner uses `========================================` solid borders with `RESULT:` labels. The proposed report header is closest to the linter style but the stat block with right-aligned numbers is unique to this tool.

**Recommendation:** Minor issue. The header style is close enough to existing patterns. But I'd suggest aligning all stat labels to the same width with a colon, no extra leading spaces:

```
=== Mutation Edge Report ===
Files scanned:   91
Edges found:     47
Broken edges:    4
Dynamic paths:   1 (skipped)
Valid targets:   43
```

Drop the 2-space indent. No other tool in the project indents its summary stats.

### 3. `--targets-only` broken edge stderr output is unspecified

The plan says "Broken edges go to stderr" in `--targets-only` mode, but the FORMAT of those stderr messages is never defined. What exactly gets written to stderr? The full `✗ source → target (type via verb)` lines? A count? A warning?

**Recommendation:** Specify the exact stderr format. I suggest:
```
-- stderr (one line per broken edge):
WARNING: broken edge: poison-gas-vent -> poison-gas-vent-plugged (file-swap via plug)
-- stderr (final summary):
WARNING: 4 broken edge(s) found. Run without --targets-only for full report.
```

Use `WARNING:` prefix to match `lint.py`'s stderr convention. This gives developers enough context to know something is wrong without polluting the stdout pipe.

### 4. The `--json` output schema is completely unspecified

The CLI spec lists `--json` as an option but neither document defines the JSON schema. What keys? What structure? Does it include edges, broken, dynamics, stats? Is it a flat object or nested?

**Recommendation:** Define the schema explicitly before implementation. Suggested structure matching lint.py's JSON conventions:

```json
{
  "summary": {
    "files_scanned": 91,
    "edges_found": 47,
    "broken_edges": 4,
    "dynamic_paths": 1,
    "valid_targets": 43
  },
  "broken": [
    { "from": "poison-gas-vent", "to": "poison-gas-vent-plugged", "type": "file-swap", "verb": "plug" }
  ],
  "dynamic": [
    { "from": "paper", "verb": "write", "mutator": "write_on_surface" }
  ]
}
```

Without this, Bart will invent a schema and Nelson will have to reverse-engineer it for tests.

---

## CLI CONSISTENCY

### 5. `--targets-only` naming is inconsistent with existing Lua CLI flags

Existing Lua flag conventions in this project:
- `src/main.lua`: `--debug`, `--trace`, `--no-ui`, `--headless`, `--list-rooms`, `--room`
- `test/run-tests.lua`: `--bench`, `--shard`, `--changed`

The project's Lua flags are short, single-word where possible (`--bench`, not `--include-benchmarks`). `--targets-only` is a compound flag — unusual for Lua scripts here.

**Recommendation:** Consider `--targets` (shorter, same meaning) or `--pipe` (describes intent — output is for piping). Not a blocker, but `--targets` would be more consistent.

### 6. `--json` flag is consistent — lint.py uses `--format json` instead

lint.py uses `--format {text,json}` with `argparse` choices. The proposed Lua script uses a bare `--json` boolean flag. If someone knows lint.py's interface, they'll try `--format json` on the edge checker and get silence.

**Recommendation:** Consider matching lint.py's pattern: `--format {text,json,targets}` as a single flag instead of `--json` + `--targets-only` as separate flags. This gives you one output mode selector instead of two potentially conflicting booleans. But pragmatically, the Lua manual flag parser makes `--format` harder to validate — so `--json` is acceptable if you document that `--json` and `--targets-only` are mutually exclusive, and error if both are passed.

### 7. The wrapper script's `$EdgesOnly` / `-EdgesOnly` is fine for PowerShell

The PowerShell `param()` block uses `-EdgesOnly`, `-Format`, `-Env`, `-ThrottleLimit` — all PascalCase with type annotations. This matches the PowerShell convention used in `run-tests-parallel.ps1` (`-Workers`, `-Bench`, `-Shard`). No issues here.

### 8. Exit code convention is correct

Exit `0` for clean, `1` for broken edges — matches `run-tests.lua` and `lint.py` conventions. Good.

---

## ERROR MESSAGING

### 9. Broken edge output tells you WHAT but not WHERE

The proposed output:
```
✗ poison-gas-vent → poison-gas-vent-plugged (file-swap via plug)
```

This tells you the source ID, target ID, edge type, and verb — but NOT the source file path. A developer seeing this has to mentally map `poison-gas-vent` → `src/meta/objects/poison-gas-vent.lua`. With 91+ files across 7 subdirectories, this isn't always obvious (is it in `objects/`? `creatures/`? `rooms/`?).

**Recommendation:** Include the source file path:
```
✗ src/meta/objects/poison-gas-vent.lua -> poison-gas-vent-plugged (file-swap via plug)
```

Or at minimum, parenthetical:
```
✗ poison-gas-vent -> poison-gas-vent-plugged (file-swap via plug) [src/meta/objects/poison-gas-vent.lua]
```

This matches `lint.py`'s format which always leads with the file path: `{file} : {line} : {severity} : ...`

### 10. No line number is possible, but the verb name is the next-best locator

Since the Lua extractor loads objects as tables (not AST parsing), it can't report line numbers. However, the verb name IS reported (`via plug`, `via break`), which tells the developer exactly which `mutations[verb]` or `transitions[i]` block to look at. This is good — no change needed.

### 11. The issue template is excellent

The Phase 4 issue template includes source file, edge type, verb, target, and a concrete fix instruction. From a developer UX standpoint, this is exactly what Flanders needs to act on the issue without any detective work. No changes.

---

## UX IMPROVEMENTS

### 12. The wrapper script will produce jumbled output under parallelism

The `mutation-lint.ps1` spec runs edge checking first, then lints targets **in parallel** with `ForEach-Object -Parallel`. The shell version (`mutation-lint.sh`) is worse — it runs edge checking AND linting concurrently as background jobs. With 4+ parallel lint workers all writing to stdout simultaneously, the output will interleave:

```
⚠ Broken mutation edges found (see above)
src/meta/objects/cloth.lua : 0 : WARNING : NM-01 : [flanders] : id 'cloth' doesn't match...
src/meta/objects/glass-shard.lua : 0 : ERROR : SF-02 : [flanders] : Missing on_feel
src/meta/objects/cloth.lua : 0 : WARNING : NM-03 : [flanders] : keyword mismatch...
```

Lines from different files interleave unpredictably. This is a real readability problem.

**Recommendations:**
1. **Collect per-file lint output, then print sequentially.** In the `.ps1` wrapper, capture each parallel lint run's output into a variable, then print all results after all workers finish. In `.sh`, use a temp directory with per-file output files, then `cat` them.
2. **Add section headers.** The wrapper should clearly separate the two phases:
   ```
   === Phase 1: Edge Existence Check ===
   (edge checker output here)

   === Phase 2: Target Lint Validation ===
   (lint results here, grouped by file)

   === Summary ===
   Edges: 47 total, 4 broken, 1 dynamic
   Lint: 43 targets checked, N violations
   ```
3. **The .sh script should NOT run edge check and lint concurrently.** The spec says edge check runs as a background job (`&`) while lint also runs. But the edge report and lint results will interleave on the terminal. Run them sequentially, or at least ensure the edge report finishes and prints before lint begins.

### 13. Consider a `--quiet` flag for CI/pre-deploy usage

The `run-before-deploy.ps1` pattern is: run tool → check exit code → print pass/fail. If the edge checker is added to the pre-deploy gate, the full report is noise — CI only cares about the exit code. A `--quiet` flag (suppress report, only set exit code) would make CI integration cleaner. Not a P0, but worth considering.

### 14. Add a "no broken edges" positive confirmation

When the extractor finds zero broken edges, the proposed report shows `Broken edges: 0` in the stats block but has no explicit success message. Compare with `run-tests.lua` which prints `RESULT: All N test file(s) PASSED`.

**Recommendation:** Add a clear success line:
```
=== Mutation Edge Report ===
Files scanned:   91
Edges found:     47
Broken edges:    0
Dynamic paths:   1 (skipped)
Valid targets:   47

✓ All mutation edges resolve to existing files.
```

This gives the developer immediate visual confirmation. When broken edges exist, replace with:
```
✗ 4 broken edge(s) — targets do not exist. See above.
```

---

## PARSER PIPELINE IMPACT

### 15. Zero parser pipeline impact — confirmed clean separation

The mutation-edge-check.lua script operates entirely in the `scripts/` directory, reads `src/meta/` files as data, and has no imports from `src/engine/parser/`. It does not:
- Modify any parser tier (1-5)
- Touch the embedding index (`assets/parser/embedding-index.json`)
- Alter verb dispatch (`src/engine/verbs/init.lua`)
- Change the preprocessing pipeline

The only shared pattern is the sandboxed `loadfile()` approach, which mirrors `src/engine/loader/init.lua` but is self-contained (no import). This is the correct architecture — the linter is a development tool, not a runtime component.

### 16. One concern: test directory registration

The plan adds `test/meta/` to `test_dirs` in `test/run-tests.lua`. This is fine, but the new test files must NOT accidentally trigger parser test discovery or conflict with parser test file naming. Since they're in `test/meta/` (not `test/parser/`), this is safe. Just flagging for awareness.

---

## SUMMARY TABLE

| # | Category | Severity | Summary |
|---|----------|----------|---------|
| 1 | Output Format | Low | Replace ⚡ with ⚠ or `[DYNAMIC]` — keep symbol vocabulary small |
| 2 | Output Format | Low | Drop 2-space indent on stat block |
| 3 | Output Format | **Medium** | Specify exact stderr format for `--targets-only` mode |
| 4 | Output Format | **High** | Define `--json` output schema before implementation |
| 5 | CLI | Low | Consider `--targets` instead of `--targets-only` |
| 6 | CLI | Low | Document `--json` vs `--targets-only` mutual exclusivity |
| 7 | CLI | None | PowerShell wrapper params are fine |
| 8 | CLI | None | Exit codes are correct |
| 9 | Error Messaging | **Medium** | Include source file path in broken edge output |
| 10 | Error Messaging | None | Verb name as locator is sufficient |
| 11 | Error Messaging | None | Issue template is excellent |
| 12 | UX | **High** | Parallel lint output will interleave — collect then print |
| 13 | UX | Low | Consider `--quiet` for CI integration |
| 14 | UX | Low | Add positive confirmation for zero broken edges |
| 15 | Parser Impact | None | Clean separation confirmed |
| 16 | Parser Impact | Low | test/meta/ directory safe — no parser conflict |

**Blockers before implementation:** Items 4 (JSON schema) and 12 (parallel output interleaving).
**Should-fix before implementation:** Items 3 (stderr format) and 9 (file path in errors).
**Nice-to-have:** Items 1, 2, 5, 6, 13, 14.

---

*— Smithers, UI Engineer*
*Working as Smithers (UI Engineer / Parser Pipeline)*


---

## D-MUTATION-CYCLES-V2: Multi-Hop Chain Validation (Future Work)

**Author:** Bart (Architect)
**Date:** 2026-08-23
**Status:** 📋 Documented (Future Phase 2)
**Triggered by:** CBG review of mutation-graph-linter-implementation-phase1.md

---

### Decision

Multi-hop chain validation (A→B→C complete chain checking) is **deferred to Phase 2** of the mutation graph linter. Phase 1 validates only single-hop edges (does the immediate target file exist?).

### Context

CBG (Comic Book Guy) raised that the current extractor checks each edge independently but does not follow chains. For example, if A→B→C, Phase 1 verifies B exists and C exists, but does not verify the full chain is reachable. This is sufficient for Phase 1 because:

1. Each target file is independently linted by the Python meta-lint (200+ rules)
2. Circular chains (A→B→A) are irrelevant — the extractor doesn't follow chains (Nelson #14)
3. The known broken edges are all single-hop (missing target file)

### Phase 2 Scope (when implemented)

- BFS/DFS traversal from every mutation source
- Detect unreachable nodes (objects that are mutation targets but have no path from any room-placed object)
- Detect orphaned chains (A→B→C where B is broken, making C unreachable)
- Report chain depth statistics

### Affects

- scripts/mutation-edge-check.lua — future extension
- plans/linter/mutation-graph-linter-design.md — Phase 2 section (to be written)

---

## D-MUTATION-LINT-PARALLEL: Parallel Lint with Sequential Output

**Author:** Bart (Architect)
**Date:** 2026-08-23
**Status:** 🟢 Active
**Triggered by:** Team review of mutation-graph-linter-implementation-phase1.md

---

### Decision

The mutation-lint wrapper scripts (mutation-lint.ps1, mutation-lint.sh) run the Python meta-lint **in parallel per-file** but **collect and display output sequentially** with section headers.

### Context

Smithers (blocker #2) identified that parallel lint workers writing to stdout simultaneously would produce interleaved, unreadable output. The original plan ran edge-checking and linting concurrently with no output collection.

### Rules

1. **Phase 1 (Edge Check)** runs first and completes before Phase 2 begins — no concurrent stdout from both tools.
2. **Phase 2 (Lint)** runs lint workers in parallel (PS7 -Parallel / Unix xargs -P) but captures each worker's output into a per-file buffer.
3. After all workers complete, results are printed sequentially with --- {filepath} --- section headers.
4. **PS7 required** for PowerShell parallel execution. PS5 falls back to sequential with a warning (Gil #4).
5. Both wrapper scripts print phase headers: === Phase 1: Edge Existence Check === and === Phase 2: Target Lint Validation ===.

### Rationale

- Parallel lint is ~4× faster than sequential for 40+ target files
- Sequential output collection preserves readability — each file's violations are grouped together
- PS7 fallback ensures the scripts work on older Windows installations (just slower)
- Shell double-scan (~1s overhead for two lua scripts/mutation-edge-check.lua invocations) is accepted as negligible vs lint runtime

### Affects

- scripts/mutation-lint.ps1 — Bart (WAVE-1)
- scripts/mutation-lint.sh — Bart (WAVE-1)
- Integration tests — Nelson (WAVE-1)
