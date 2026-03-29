# Squad Decisions

**Last Updated:** 2026-03-29T16:57:20Z  
**Last Merge:** 2026-03-29T16:57:20Z (8 decisions merged: Wyatt's World spawn manifesto)
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
| D-PARSER-PHASE-NEXT | Parser | 🟢 Active | Parser Phase 3 soft matching design (91.2% → 93%+): MaxSim, 70/30 BM25, 2-3 synonyms |
| D-MAXSIM-INTEGRATION | Parser | 🟢 Active | MaxSim re-ranker implemented: hybrid score internal-only, stable sort tiebreaker |
| D-MUTATION-LINT-PIVOT | Process | 🟢 Active | Mutation graph linter uses expand-and-lint (Python meta-lint) instead of standalone Lua graph library |
| D-PARALLEL-EXPAND-LINT | Process | 🟢 Active | Objects expanded and linted in parallel — each object's mutation targets can run concurrently |
| D-MUTATION-EDGE-EXTRACTION | Process | 🟢 Active | 5 mutation edge types formalized: file-swap, destruction, state-transition, composite-part, linked-exit |
| D-LINTER-IMPL-WAVES | Process | 🟢 Active | Linter improvement: 6 waves with 5 gates, serialized lint.py edits |
| D-WAYNE-PHASE5-DECISIONS | Process | 🟢 Active | Phase 5 scope: werewolf NPC, salt-only preservation, defer A*/env-combat/humanoid NPCs |
| D-LINTER-ENGINEER-HIRE | Process | 🟢 Active | Hire dedicated linter engineer (Wiggum) to own 306-rule Python linter system |
| D-DEPLOY-ON-MERGE | Process | 🟢 Active | Deploy-on-merge workflow: auto-deploy to GitHub Pages after PR merge to main |
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
| D-OPTIONS-ENGINE-HYBRID | Options | ✅ Implemented | Bart: core engine, hybrid generator (goal + sensory + dynamic scan) |
| D-OPTIONS-ALIASES | Options | ✅ Implemented | Smithers: 10 parser aliases + loop number selection |
| D-ROOM-GOALS | Options | ✅ Implemented | Moe: goal metadata on 7 Level 1 rooms |
| D-OPTIONS-TESTS | Options | ✅ Implemented | Nelson: 53-test TDD suite, zero regressions |
| D-SURFACE-OBJECT-NARRATION | Architecture | ✅ Implemented | Surface object undirected narration fix (#394, Flanders) |
| D-CREATURE-ZONE-NAMES | Architecture | ✅ Implemented | Creature-specific body zone narration names; engine-side zone_text(zone, body_tree) |
| D-TERRITORY-SENSORY-FIXES | Architecture | ✅ Implemented | Territory marker registration, narration cleanup, sensory deduplication |
| D-WAVE1-BUTCHERY-CREATURES-SPLIT | Architecture | ✅ Implemented | creatures/init.lua split to actions.lua; -190 LOC headroom |
| D-WAVE1-BURNDOWN | Process | ✅ Complete | Triaged 54 issues, 39 Wave 3 ready, 15 deferred to Phase 5 |
| D-WAVE5-BEHAVIORS | Architecture | ✅ Implemented | Pack tactics, territorial, ambush behavior engine design |
| D-CREATE-OBJECT-ACTION | Architecture | ✅ Implemented | Metadata-driven creature object creation + NPC obstacle detection |
| D-STRESS-HOOKS | Architecture | ✅ Implemented | Stress trauma hooks delegate to central injuries.add_stress() API |
| D-WORLDS-LOADER-WAVE0 | Architecture | ✅ Complete | World loader infrastructure complete; WAVE-0 shipped (16 tests, 258 total) |
| D-SOUND-REVIEW-CYCLE | Process | ⚠️ Concerns | 7-agent architecture review complete; 10 blockers, 11 concerns (all fixed in v1.1) |
| D-SOUND-WAVE0-COMPLETE | Architecture | ✅ Complete | Bart WAVE-0 complete: sound manager + null driver + defaults + 47 tests, 259 total tests pass |
| D-SOUND-MUTATION-CTX | Architecture | 🟢 Active | `mutation.mutate()` accepts optional ctx parameter for sound lifecycle hooks |
| D-LEVEL2-DESIGN-LOCK | Design | 🟢 Active | Level 2: 7 parameters locked (garden theme, 8-12 rooms, gradual difficulty, weather system, etc.) |
| D-LEVEL2-COURTYARD-PORTAL | Architecture | 🟢 Active | Level 2 entry: Courtyard portal to garden (not staircase); staircase → mausoleum |
| D-LEVEL2-MAUSOLEUM-PORTAL | Architecture | 🟢 Active | Mausoleum in Level 2 garden; dual role (arrival from Level 1 staircase + Level 3 gate) |
| D-LEVEL-TOPOLOGY-MAP | Architecture | 🟢 Active | Full level transition topology: L1→L2 (courtyard + staircase→mausoleum), L2→L3 (mausoleum puzzle), L2→L4+ (hedge maze→moorland) |
| DIRECTIVE-COPILOT-THEME-PRECEDENT | Design | 🟢 Active | Design team uses existing code as inspiration for theme subsection files |
| D-OPTIONS-V2 | Architecture | 🟢 Active | Options architecture v2: 12 blockers resolved (API contracts, performance, empty room fallback, state-based goals) |
| D-OPTIONS-B5 | Parser | ✅ Verified | "help me" NOT in options aliases — stays mapped to help verb; 10-alias options system final |
| D-OPTIONS-ANTISPOILER | Design | 🟢 Active | 3-tier escalating specificity (Standard→Context→Mercy) + puzzle exemption system (3-tier flags) |
| D-OPTIONS-PLAN-V1 | Planning | 🟢 Active | Options plan v1.0 — GATE-1 READY; 5 phases defined, 12 blockers resolved, quantitative GATE-5 thresholds |
| D-WYATT-WORLD | Design | 🟢 Active | New world: MrBeast Challenge Arena, 7 rooms, E-rated, single-room puzzles, 3rd grade reading level |
| D-WYATT-PLAN | Architecture | 🟢 Active | Wyatt's World implementation plan v2.1: 4 waves, 3 gates, 15 TDD files, all blockers resolved |
| D-WYATT-GUIDS | Planning | 🟢 Active | GUID pre-assignment block: 1 world + 7 rooms + 1 level + ~70 objects. Sequential use, no collision risk |
| D-RATING-SYSTEM | Architecture | 🟢 Active | Content rating system: E-rated worlds block combat/self-harm verbs at engine level (hard blocks) |
| D-RATING-TWO-LAYER | Architecture | 🟢 Active | Two-layer rating enforcement: engine-enforced (hard blocks) + design-enforced (soft guidelines) |

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

## D-PARSER-PHASE-NEXT: Parser Phase 3 Soft Matching Design

**Status:** 🟢 Active  
**Author:** Frink (Research Scientist)  
**Requested by:** Wayne "Effe" Berry  
**Date:** 2026-03-29
**Category:** Parser / Architecture

### Summary

Parser Phase 3 design decisions for soft matching to push accuracy from 91.2% (134/147 benchmark) to 93%+:

| Decision | Recommendation | Rationale |
|----------|---------------|-----------|
| D1: Hybrid weights | 70/30 BM25-heavy, two-stage pipeline | Short queries favor lexical precision; semantic re-ranking handles ties |
| D2: Synonym scope | 2-3 per noun (conservative) | Lu et al. research; no synonym-caused failures in remaining 13; drift risk above 3 |
| D3: Scoring approach | MaxSim first, soft cosine fallback | Simpler, debuggable, noise-robust, equivalent accuracy at this scale |
| D4: Accuracy target | 93%, then beta + reassess | 3 cases achievable; diminishing returns above 93%; real player data > benchmarks |

### Key Insights

1. **Two-stage pipeline (BM25 → semantic re-rank)** is cleaner than linear combination — avoids score normalization issues
2. **MaxSim (O(n×m))** vs soft cosine (O(n²)) complexity is irrelevant at query scale; MaxSim debuggability wins
3. **Target 93%** is defensible milestone; diminishing returns above; beta playtesting data will drive next iteration
4. **Noun synonyms:** Conservative 2-3 expansion validated by corpus — zero remaining failures caused by missing synonyms

### Impact

- **Smithers:** Implement MaxSim re-ranker in `embedding_matcher.lua`
- **Nelson:** Update benchmark target to 93%
- **Wayne:** Beta timeline now clear — 93% accuracy gate before playtesting

---

## D-MAXSIM-INTEGRATION: MaxSim Re-Ranker Implementation

**Status:** 🟢 Active  
**Author:** Smithers (UI Engineer)  
**Date:** 2026-03-30  
**Category:** Parser / Implementation

### Decisions Implemented

#### S1: Hybrid Score Internal-Only

The hybrid score (70/30 BM25+MaxSim) is used exclusively for candidate ranking inside `match()`. The externally returned score remains the raw BM25 value.

**Reasoning:** Multiple test suites assert score thresholds calibrated to raw BM25 ranges (~3.0+). Returning normalized hybrid scores (0-1) would break 100+ test assertions. The hybrid score's purpose is ranking, not magnitude.

#### S2: Stable Sort Tiebreaker

Both BM25 and hybrid re-sort use `phrase.id` (original index position) as tiebreaker when scores are equal.

**Reasoning:** Lua's `table.sort` is not stable. Without a tiebreaker, candidates with identical hybrid scores produced non-deterministic results — tests flapped. Using phrase index position preserves implicit ordering from the embedding index, which was prior behavior under pure BM25.

### Impact

- **Nelson:** Test expectations unchanged (raw BM25 scores); deterministic results
- **Frink:** Hybrid is internal ranking only; no caller-facing change
- **Benchmark:** Accuracy expected to improve 91.2% → 92–93% with MaxSim + 2-3 noun synonyms

---

## D-DEPLOY-ON-MERGE: Deploy-on-Merge Workflow

**Status:** 🟢 Active  
**Author:** Gil (Web Engineer)  
**Date:** 2026-03-29  
**Category:** CI/CD

### Summary

Created `.github/workflows/squad-deploy.yml` — an automated deploy pipeline that triggers on push to `main` (after PR merge). It runs the full sharded test suite, builds engine + meta bundles via PowerShell, and pushes to `WayneWalterBerry/WayneWalterBerry.github.io` → `play/`.

### Key Features

1. **Sharded tests** mirror squad-ci.yml (same 6-shard matrix for consistency)
2. **No-op deploy guard** — if build produces identical files, no commit is pushed
3. **BUILD_TIMESTAMP logged** — printed to Actions output for post-deploy verification
4. **Cross-repo auth** via x-access-token (standard GitHub PAT pattern)

### Requirements

Repository secret `PAGES_DEPLOY_TOKEN` must be configured:
- Fine-grained PAT scoped to `WayneWalterBerry/WayneWalterBerry.github.io`
- Permission: Contents (read & write)
- Set in MMO repo → Settings → Secrets → Actions

### Impact

- **All squad members:** Merging to `main` now auto-deploys. No manual `web/deploy.ps1` needed for routine deploys.
- **Nelson / QA:** Test gate runs before deploy — broken code won't reach Pages.
- **Wayne:** Must configure `PAGES_DEPLOY_TOKEN` secret.
- **Gil:** Manual deploys still available via `web/deploy.ps1` for hotfixes.

---

## DIRECTIVE-2026-03-29T0139Z: User Directive — Project Priority Order

**Status:** 🟢 Active  
**Author:** Wayne Berry  
**Date:** 2026-03-29

### Directive

Project priorities set by Wayne:

**Stability First:** Testing + Linter (get product stable)

**New improvements in order:**
1. Worlds (high-value architecture)
2. Sound (creative direction)
3. Food (close to done, quick win)
4. NPC Combat (most destabilization risk — deferred to Phase 5+)

**Always nice / background:** Parser improvements

### Rationale

Stability before features. Least-disruptive features first. Heavy lifting (combat, NPCs) deferred until core is rock-solid.

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

## D-SOUND-WAVE0-COMPLETE: Sound Manager + Null Driver Implementation

**Status:** ✅ Complete  
**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-29T11:40Z  
**Category:** Architecture / Implementation

### Decision

Completed WAVE-0 Track 0A of the sound implementation: Sound manager module, null driver, defaults table, and comprehensive test suite.

### What Was Delivered

1. **`src/engine/sound/init.lua`** (~300 LOC) — Sound manager with 21-method API:
   - Construction: `new()`, `init(driver, options)`, `shutdown()`
   - Driver injection: `set_driver(driver)`, `get_driver()`
   - Playback: `play(filename, opts)`, `stop(play_id)`, `stop_by_owner(owner_id)`
   - Room transitions: `enter_room(room)`, `exit_room(room)`, `unload_room(room_id)`
   - Event dispatch: `trigger(obj, event_key)` — 3-step resolution (obj.sounds → defaults → nil)
   - Settings: volume, mute, unmute, enabled state

2. **`src/engine/sound/defaults.lua`** (15 entries) — Verb-to-sound fallback table (on_verb_break → generic-break.opus, etc.)

3. **`src/engine/sound/null-driver.lua`** (7 methods) — No-op driver implementing full interface contract

4. **`test/sound/test-sound-manager.lua`** (47 tests, 12 suites) — Comprehensive coverage:
   - Manager construction and initialization
   - Driver injection with mock drivers
   - Nil-driver no-op behavior
   - Volume clamping (0.0–1.0)
   - Mute/unmute state management
   - Trigger resolution chain
   - Room transitions (enter/exit/unload)
   - Concurrency limits (4 oneshots, 3 ambients)
   - GATE-0 API surface verification

### Test Results

- **Total test files:** 259 (baseline 258 + new 1 `test/sound/test-sound-manager.lua`)
- **Total tests:** All passing
- **Regressions:** Zero
- **Gate Criteria:** GATE-0 Infrastructure Ready — ✅ PASSED

### Design Decisions Captured

- **Volume range:** 0.0–1.0 (matches Web Audio API convention, clamped)
- **Driver interface:** Colon-method syntax, 7 methods (load, play, stop, stop_all, set_master_volume, unload, fade)
- **Concurrency:** Enforced via eviction (oldest-first for oneshots, FIFO for ambients)
- **Null driver:** Returns filename as handle for test identity checks
- **OOP pattern:** Metatables + M.new() + colon methods

### API Frozen at GATE-0

Methods are now stable and documented in the driver interface contract:
- `M.new()`, `M:init(driver, options)`, `M:shutdown()`
- `M:scan_object(obj)`, `M:flush_queue()`
- `M:play(filename, opts)`, `M:stop(play_id)`, `M:stop_by_owner(owner_id)`

---

## D-OPTIONS-ENGINE-HYBRID: Options Engine Phase 1+3 — Hybrid Generator

**Status:** ✅ Implemented  
**Author:** Bart (Architect)  
**Date:** 2026-03-29  
**Category:** Options System  
**Affected:** Moe (rooms declare goals), Sideshow Bob (puzzle exemptions), Smithers (parser integration)

### Decision

Built the core Options Engine per approved architecture v2 (`projects/options/architecture.md`). Wayne's choices: Approach C (goal-driven hybrid), Option C context window (stable goals + rotating sensory), free hints.

### What Was Built

#### Phase 1: Core API
- **Module:** `src/engine/options/init.lua` (~400 LOC)
- **API:** `generate_options(ctx)` returns `{ options = OptionEntry[], flavor_text = string }`
- **Verb Handler:** `src/engine/verbs/options.lua` — registered in `verbs/init.lua`

#### Phase 3: Hybrid Generator Algorithm

Three-phase generator (0-4 items total):

1. **Goal Steps (0-2 items):** Calls existing `goal_planner.plan(ctx, goal.verb, goal.noun)` to backward-chain from `room.goal`. Shows ONLY first step (anti-spoiler Rule 1). If first step is movement (`go`), shows step 2 as well.

2. **Sensory Exploration (1-2 items):** Rotates between feel/listen/smell (dark) or look/examine/search (lit). Filters recently used verbs via `ctx.recent_commands` to avoid repeats.

3. **Dynamic Object Scan (fill to 4):** Scores room objects by interestingness:
   - Unopened container: +2
   - FSM transition available: +3
   - Locked exit: +2
   - Not examined: +1

4. **Fallback (if < 2 items):** Generic sensory verb + available exits + "wait" as ultimate fallback.

### Architecture Patterns Used

- **GOAP Reuse:** No modifications to `goal_planner.lua` — the options engine just calls `plan()` with room goal and filters result.
- **Principle 8 Compliance:** All behavior via metadata — no object-specific engine logic.
- **Context Window Option C:** Goal steps stable (same GOAP plan), sensory suggestions rotate (filter by recent use).
- **Module Pattern:** Standard Lua `local M = {} ... return M` with `generate_options(ctx)` as single export.

### Integration Points

#### For Moe (Room Designer)
Rooms can now declare optional goals:

```lua
-- Single goal
goal = { verb = "go", noun = "north", label = "find a way forward" }

-- Multiple priority goals
goals = {
    { verb = "light", noun = "candle", label = "find light", priority = 1 },
    { verb = "go", noun = "down", label = "explore deeper", priority = 2 },
}
```

Goals are **optional**. Rooms without goals get sensory + dynamic suggestions only.

#### For Bob (Puzzle Designer)
Rooms can set exemption flags to protect puzzle moments:

```lua
options_disabled = true,              -- Block hints entirely
options_mode = "sensory_only",        -- Only sensory verbs, no goal steps
options_delay = 3,                    -- No hints for first 3 turns
```

These flags can change dynamically in `on_state_change` hooks for multi-phase puzzles.

#### For Smithers (Parser Engineer)
Phase 2 work (Phase 2+4 now complete): Numbered selection system. When player types `options`, store mapping in `ctx.player.pending_options`. Main loop checks for numeric input and substitutes before parser.

**Precedence rule:** `pending_options` only intercepts numbers when it's set (after calling `options`). When `nil`, numbers route normally — no collision with numeric object names.

### What Was NOT Built in Phase 1+3

Deferred to Phase 2+4:
- Loop integration (numbered selection) — Smithers ✅
- Parser integration (aliases, idioms) — Smithers ✅

### Testing

Full test suite passes (265/268 files, 11 pre-existing failures). Zero new regressions.

### Files Changed

- Created: `src/engine/options/init.lua`
- Created: `src/engine/verbs/options.lua`
- Modified: `src/engine/verbs/init.lua` (added require + register)

### Commit

`26400a8` — feat(options): core options engine + hybrid generator (Phase 1+3)

---

## D-OPTIONS-ALIASES: Options Parser Integration Phase 2+4

**Status:** ✅ Implemented  
**Author:** Smithers (UI Engineer)  
**Date:** 2026-03-29  
**Category:** Parser  
**Affected:** Bart (options verb hooks), Nelson (number selection tests), players (hint interface)

### Decisions Made

#### D-OPTIONS-ALIASES: 10 Parser Aliases for `options` Verb

Three routing layers:
1. **phrases.lua transform_questions:** "what are my options", "give me options", "what can i try", "i'm stuck", "hint", "hints", "nudge"
2. **data.lua IDIOM_TABLE + idioms.lua:** "give me a nudge", "give me a hint", "suggest something"
3. **data.lua KNOWN_VERBS:** `options`, `hint`, `hints` added

D-OPTIONS-B5 respected: "help me" NOT in options aliases — stays mapped to `help`.

**Breaking change:** `idioms.lua` "give me a hint" redirected from `help` → `options`. This is intentional per architecture spec.

#### D-OPTIONS-NUMBER-INTERCEPT: Loop-Level Number Selection

Number interception in `loop/init.lua` fires after input trim but before parser pipeline:
- `pending_options` set by options verb handler (Bart's engine domain)
- Valid number 1-N → substitutes command string, clears state
- Invalid number → error message, short-circuits
- Non-numeric → clears state silently
- `options` added to `no_noun_verbs` table

### Impact on Other Agents

| Agent | Impact |
|-------|--------|
| **Bart** | `pending_options` field on `ctx.player` is now consumed by the loop. Phase 1 verb handler must set it. |
| **Moe** | Room `goal` fields (Phase 5) feed the options generator — no parser impact. |
| **Nelson** | Parser tests unaffected (7,361 pass). Phase 4 tests for number selection should cover edge cases. ✅ |

### Files Changed

- `src/engine/parser/preprocess/data.lua` — KNOWN_VERBS + IDIOM_TABLE
- `src/engine/parser/preprocess/phrases.lua` — transform_questions
- `src/engine/parser/idioms.lua` — "give me a hint" redirect
- `src/engine/loop/init.lua` — number interception + no_noun_verbs

### Testing

All 10 aliases verified functional. Number selection edge cases covered (invalid 0, too-high, non-numeric).

---

## D-ROOM-GOALS: Room Goal Metadata for Options Phase 5

**Status:** ✅ Implemented  
**Author:** Moe (World & Level Builder)  
**Date:** 2026-03-29  
**Category:** Game World  
**Affects:** Bart (GOAP integration), Sideshow Bob (puzzle exemptions), Smithers (hint display)

### Decision

All 7 Level 1 rooms now declare `goal` metadata for the Options hint system GOAP planner. Goals follow the schema from `projects/options/architecture.md` section 4.5.

### Room Goals Summary

| Room | Goal Type | Verb | Noun | Label | Exemptions |
|------|-----------|------|------|-------|------------|
| Bedroom | `goals` array | light / go | candle / north | "find a source of light" / "find a way out of the bedroom" | `options_delay = 3` |
| Hallway | `goal` | go | north | "find a way upstairs" | — |
| Cellar | `goal` | go | north | "find a way forward" | — |
| Storage Cellar | `goal` | go | north | "press deeper into the cellars" | — |
| Deep Cellar | `goal` | pull | chain | "discover the chamber's secret" | `options_delay = 5` |
| Courtyard | `goal` | go | east | "find another way into the manor" | — |
| Crypt | `goal` | read | inscription | "decipher the tomb's secrets" | `options_mode = "sensory_only"` |

### Design Rationale

1. **Bedroom multi-goal:** The bedroom has two distinct phases — finding light (priority 1) then escaping (priority 2). Single goal wouldn't capture this.

2. **Deep cellar chain puzzle:** The chain mechanism revealing the hidden alcove is the room's signature mechanic. Goal says "discover the secret" not "pull the chain to reveal the alcove" (anti-spoiler).

3. **Crypt sensory_only:** The crypt is the deepest, most atmospheric room. `sensory_only` preserves the sacred tomb experience — no goal steps, just sensory nudges. Bob may want to adjust this.

4. **options_delay usage:** Bedroom (3 turns) and deep cellar (5 turns) both benefit from forcing initial exploration. Players should absorb the atmosphere before the hint system engages.

5. **Progression-focused goals:** Most rooms use `verb = "go"` because Level 1 is about spatial discovery and forward movement. The engine's GOAP planner handles locked doors, missing keys, etc. as prerequisites.

### For Bob

The crypt `options_mode = "sensory_only"` and deep cellar `options_delay = 5` are Moe's recommendations based on room atmosphere. Bob owns puzzle exemptions per D-OPTIONS-ANTISPOILER — adjust these flags as needed for puzzle flow.

### For Bart

The bedroom uses `goals` (array) while all other rooms use `goal` (single). The engine's goal picker needs to handle both forms per architecture section 4.5.

### Files Changed

- `src/meta/world/bedroom.lua` — goals array (multi-phase)
- `src/meta/world/hallway.lua` — goal metadata
- `src/meta/world/cellar.lua` — goal metadata
- `src/meta/world/storage-cellar.lua` — goal metadata
- `src/meta/world/deep-cellar.lua` — goal + options_delay
- `src/meta/world/courtyard.lua` — goal metadata
- `src/meta/world/crypt.lua` — goal + options_mode

### Testing

All room instantiation tests pass. Goal field validation confirmed.

---

## D-OPTIONS-TESTS: Options TDD Test Suite Phase 6

**Status:** ✅ Implemented  
**Author:** Nelson (QA & Test Automation)  
**Date:** 2026-03-29  
**Category:** Testing  
**Affects:** Bart (engine coverage), Smithers (parser coverage), Moe (room coverage)

### Work Completed

- 53 tests across 4 files
  - `test-options-api.lua` — options engine functionality
  - `test-parser-aliases.lua` — all 10 parser aliases
  - `test-number-selection.lua` — loop-level interception
  - `test-anti-spoiler.lua` — GOAP filter, first-step only
- All tests passing, zero regressions

### Test Coverage

- ✅ Goal steps (GOAP planning)
- ✅ Sensory rotation + recent-command filter
- ✅ Dynamic object scoring
- ✅ Fallback logic (generic sensory + exits)
- ✅ Puzzle exemptions (`options_disabled`, `options_mode`, `options_delay`)
- ✅ Number selection 1-N validation
- ✅ Invalid number error handling
- ✅ Anti-spoiler first-step filtering

### Regression Testing

- Parser tests: 7,361/7,361 pass
- Verb tests: all pass
- Integration tests: all pass

### Gate Status

✅ GATE-6 READY — All phases complete, 53 tests passing, zero regressions. Ready for deployment.

### Files Changed

- Created: `test/options/test-options-api.lua`
- Created: `test/options/test-parser-aliases.lua`
- Created: `test/options/test-number-selection.lua`
- Created: `test/options/test-anti-spoiler.lua`
- `M:enter_room(room)`, `M:exit_room(room)`, `M:unload_room(room_id)`
- `M:trigger(obj, event_key)` — resolution chain: obj.sounds → defaults → nil
- `M:set_volume(level)`, `M:mute()`, `M:unmute()`, `M:set_driver(driver)`

### Impact on Other Agents

- **Gil:** Web driver must implement 7-method driver interface contract
- **Nelson:** Mock driver pattern established (see test file); test scaffolding ready
- **Flanders/Moe:** Object `sounds` table format validated via `scan_object()`
- **Smithers:** `trigger(obj, event_key)` is the verb integration point for sound dispatch

### Downstream Tasks

- **Gil:** Implement web audio bridge (WAVE-0 Gil track)
- **Nelson:** Mock driver scaffolding + additional integration tests (WAVE-0 Nelson track)
- **Flanders/Moe:** Object/room sound metadata (WAVE-1)
- **Smithers:** Verb-handler sound integration (WAVE-2)

### Commit

9645abe — Sound WAVE-0 delivery

---

## DIRECTIVE-COPILOT-THEME-PRECEDENT: Design Theme Precedent

**Status:** 🟢 Active  
**Author:** Wayne Berry (via Copilot)  
**Date:** 2026-03-29T11:32Z  
**Category:** Design / Process

### Directive

The Design Team (CBG, Willie, Moe) should use existing objects, rooms, and creatures in the codebase as inspiration and precedent when filling out the world-01 theme subsection files (manor-architecture, manor-creatures, manor-history). The code already establishes the world's look and feel.

### Rationale

The 74+ objects, 7 rooms, and 5 creatures already define The Manor's aesthetic. Theme files should codify what exists, not invent from scratch. This ensures design documentation remains in sync with actual game content.

### Impact

- **CBG:** Use existing creatures/rooms as design precedent when writing theme docs
- **Willie:** Reference existing spatial patterns for architecture themes
- **Moe:** Room definitions ARE the architecture spec; theme docs elaborate on it



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

---

## D-WORLDS-LOADER-WAVE0: Worlds WAVE-0 Infrastructure Complete

**Status:** ✅ Complete  
**Author:** Bart (Architect)  
**Date:** 2026-03-30  
**Category:** Architecture / Implementation

### What Happened

Executed WAVE-0 (infrastructure) and WAVE-1 (world loader) from `projects/worlds/worlds-implementation-phase1.md`.

### Delivered
- `src/engine/world/init.lua` — world loader module (discover, validate, select, get_starting_room, load)
- `test/worlds/test-world-loader.lua` — 16 tests, all passing
- `test/run-tests.lua` — registered `test/worlds/` in test_dirs and source_to_tests
- Board updated: `projects/worlds/board.md`
- **Total test suite:** 258 tests passing (16 new + 242 baseline)

### Design Decisions
1. **Dependency injection** — zero `require()` calls in the world module. All dependencies (list_lua_files, read_file, load_source) passed as parameters.
2. **Validation requires non-empty `levels` array and non-empty `starting_room` string** — empty values fail validation, not just nil.
3. **Tests include real world-01.lua integration** — not just mocks. Discovers and validates the actual file on disk.

### Impact
- **Moe/Flanders:** Clear loader contract for world definitions
- **Nelson:** World module integration tested
- **Brockman:** Ready for documentation
- **Team:** WAVE-0 gating complete, WAVE-1 underway

---

## D-SOUND-REVIEW-CYCLE: 7-Agent Sound Plan Review (All Blockers Fixed)

**Status:** ⚠️ Concerns (All fixable in v1.1)  
**Date:** 2026-03-30  
**Category:** Architecture / Planning  
**Reviewed by:** Bart, Comic Book Guy, Chalmers, Flanders, Marge, Moe, Smithers

### Context

Sound implementation plan (`projects/sound/sound-implementation-plan.md`) underwent full 7-agent architecture review. 10 blockers identified, 11 concerns raised — **all fixable in coordinated v1.1 pass**.

### Overall Verdict

**Architecture is sound.** The driver injection pattern (Principle 8), effects pipeline integration, and accessibility dual-channel design are production-ready. The plan CAN ship after fixing specification gaps.

### Key Findings Summary

| Reviewer | Focus | Issues | Severity |
|----------|-------|--------|----------|
| **Bart** (Architect) | System design | 7 spec gaps (C1-C7) | ⚠️ Medium — fixable in v1.1 |
| **CBG** (Creative Dir) | Game design | 2 concerns (silence education, time-of-day scope) | ⚠️ Low — good framing |
| **Chalmers** (Auditor) | Planning | 3 blockers (parallelism, gate handoff, rollback) | ⚠️ Medium — coordination issues |
| **Flanders** (Object Eng) | Metadata | 3 blockers (GUID safety, naming, creature death) | ⚠️ Medium — must coordinate |
| **Marge** (Test Lead) | QA gates | 3 blockers (LLM scenarios, baseline, headless) | ⚠️ Medium — test spec gaps |
| **Moe** (World Builder) | Rooms | 2 blockers (field naming, exit transitions) | ⚠️ Low — simple clarifications |
| **Smithers** (UI/Parser) | Integration | 2 blockers (verb handler pattern, narration sync) | ⚠️ Medium — integration points |

### Top 3 Blocker Categories

1. **Naming conventions:** Standardize field names (`ambient_loop` vs `on_ambient` vs `ambient_sound`) across objects and rooms
2. **Coordination points:** Clarify which tool is authoritative (effects vs direct trigger, door vs room exit)
3. **Integration gaps:** Define exact verb-handler integration, sound-manager lifecycle hooks, creature death FSM state

### v1.1 Action Plan

1. **Bart:** Consolidate all concerns, write `.squad/decisions/inbox/bart-sound-v1-1-fixes.md` with unified answers
2. **Pair workshops:** Bart+Smithers (verb integration), Bart+Flanders (metadata spec), Bart+Moe (room field naming)
3. **Update plan:** Finalize `projects/sound/sound-implementation-plan.md` with all clarifications
4. **Re-review:** Quick pass by reviewers (30 min each) to confirm all blockers resolved
5. **Ship:** WAVE-0 → GATE-0 approval

### Impact
- **Flanders/Moe:** Object/room metadata spec finalized before WAVE-1
- **Bart:** Coordinate blocker resolutions (1-2 hours)
- **Smithers:** Verb-handler integration pattern documented (1 hour)
- **Marge:** LLM test scenarios written, baseline captured (2 hours)
- **Nelson:** Can begin mock driver + gate framework (1 hour)

---

## D-SOUND-MUTATION-CTX: mutation.mutate() Context Parameter

**Status:** 🟢 Active  
**Author:** Bart (Architect)  
**Date:** 2026-03-29T11:52Z  
**Category:** Architecture / Engine  
**Phase:** Sound WAVE-2 Track 2A

### Decision

\mutation.mutate(reg, ldr, object_id, new_source, templates, ctx)\ now accepts an optional 6th \ctx\ parameter. When provided and \ctx.sound_manager\ is non-nil, the mutation sequence fires sound lifecycle hooks in this order:

1. \stop_by_owner(old_id)\ — stop sounds emitted by the old object
2. \	rigger(old, "on_mutate")\ — fire the mutation sound event
3. \eg:register()\ — swap the object in registry
4. \scan_object(new_obj)\ — scan replacement for new sound declarations

### Rationale

Mutation had no access to runtime context. Sound hooks need the sound manager, which lives on \ctx\. The optional parameter is backward compatible — existing callers that don't pass \ctx\ get nil, and all sound hooks are nil-guarded. This follows the fire-and-forget pattern: sound failures never crash the game.

### Implementation

- **src/engine/mutation/init.lua** — Added \ctx\ parameter, conditional hook dispatch
- **src/engine/verbs/init.lua** — All verb handlers that call \perform_mutation()\ now pass \ctx\
- **Zero behavior change** — Mutations work identically whether ctx is passed or not

### Affected Agents

- **Flanders:** Object mutation definitions (\ecomes\ field) — no change needed, but \on_mutate\ sound key is now live for sound dispatch
- **Smithers:** Verb handlers that call \perform_mutation()\ — already updated to pass \ctx\
- **Nelson:** Integration tests should verify mutation sound lifecycle (stop old, trigger event, scan new)

---

## D-LEVEL2-DESIGN-LOCK: Level 2 Design Parameters

**Status:** 🟢 Active  
**Author:** Wayne \"Effe\" Berry (via Copilot)  
**Date:** 2026-03-29T11:45Z  
**Category:** Design / Planning

### Summary

Level 2 design parameters finalized after Q&A with design team. All 7 parameters are binding — design and content work must stay within these constraints.

### Parameters Locked

| # | Parameter | Decision | Rationale |
|----|-----------|----------|-----------|
| 1 | **Theme** | Garden & grounds (greenhouse, hedge maze, stables) | Exterior transition from manor interior; natural progression |
| 2 | **Size** | 8-12 rooms (medium expansion) | More exploration than Level 1 (7 rooms) without bloat |
| 3 | **Difficulty** | Gradual progression from Level 1 endgame | No major mechanic jumps; learning curve continues smoothly |
| 4 | **Creatures** | Mix of natural (owls, snakes, foxes, insects) + one supernatural | Grounded exploration + mystery element |
| 5 | **Lighting** | Time-of-day dependent (actual game clock) | First exterior level; natural light finally matters at noon |
| 6 | **Weather** | Mechanical, not cosmetic (rain extinguishes fire, wind carries sound, fog limits visibility) | New engine subsystem; adds environmental challenge |
| 7 | **Travel** | Two-way (player can freely return to Level 1 via portal) | No level-locking; exploration is player-driven |

### Impact

- **Moe:** 8-12 rooms, courtyard expansion, garden hub layout
- **Flanders:** 20+ garden objects (plants, furniture, interactive elements) + 6-8 creature types
- **CBG:** Design synthesis, validate map flow against constraints
- **Bart:** Implement weather subsystem (new engine work)
- **Sideshow Bob:** Mausoleum puzzle design within garden theme
- **Nelson:** Integration tests for weather system + Level 2 smoke tests

---

## D-LEVEL2-COURTYARD-PORTAL: Courtyard as Level 2 Gateway

**Status:** 🟢 Active  
**Author:** Wayne \"Effe\" Berry (via Copilot)  
**Date:** 2026-03-29T11:49Z  
**Category:** Architecture / Design

### Decision

The Level 1 → Level 2 (garden & grounds) portal should connect through the **courtyard**, not the hallway staircase. A staircase is not a natural transition from interior to exterior — the courtyard (already exterior, already connected to bedroom via window portal #199) is the logical gateway to the garden.

### Implementation Requirements

- New portal object in courtyard (garden gate, archway, or garden path)
- Courtyard becomes the hub connecting Level 1 interior to Level 2 exterior
- Consider intermediate transition room (walled garden, kitchen garden, or terrace) if needed for pacing
- Issue #205 scope changed: hallway staircase now targets **upper floors** (future level), not Level 2

### Why

Architectural logic: Manors don't access gardens via staircases. The courtyard is the natural exterior transition point. This aligns with real-world manor/estate topology.

### Impact

- **Moe:** Courtyard expansion, portal design, garden layout anchoring to courtyard
- **Lisa:** Issue #205 scope change (staircase destination = upper floors, not Level 2)
- **CBG:** Map flow validation — courtyard becomes Level 2 hub
- **Flanders:** Courtyard portal object design

---

## D-LEVEL2-MAUSOLEUM-PORTAL: Mausoleum as Level 2→3 Gate

**Status:** 🟢 Active  
**Author:** Wayne \"Effe\" Berry (via Copilot)  
**Date:** 2026-03-29T11:48Z  
**Category:** Architecture / Design

### Decision

In Level 2 (garden & grounds), there is a small freestanding **mausoleum** structure. The mausoleum serves a dual role:

1. **Arrival point FROM Level 1** — The deep cellar staircase ascends through the mausoleum floor; players complete Level 1 underground puzzles, then emerge in the mausoleum
2. **Portal to Level 3** — Mausoleum contains a puzzle-locked gate/descent into Level 3

The mausoleum should be a discoverable structure in the garden that feels like a natural landmark, not a hidden secret.

### Ownership

- **Moe:** Mausoleum room definition + garden layout
- **Flanders:** Mausoleum object structure + interactive elements
- **Sideshow Bob:** Puzzle design (what locks the Level 3 gate)
- **Bart:** Portal implementation in engine (already exists)

### Why

Completes the Level 1→2→3 transition narrative. The staircase ascent feels earned (deep underground → emergence). The mausoleum becomes a landmark and emotional beats for player progression.

### Impact

- Level 1 completion feels climactic (deep cellar ascent)
- Level 2 has a visual anchor (mausoleum monument)
- Level 3 gate is guarded by a real location, not an arbitrary invisible barrier

---

## D-LEVEL-TOPOLOGY-MAP: Full Level Transition Architecture

**Status:** 🟢 Active  
**Author:** Wayne \"Effe\" Berry (via Copilot)  
**Date:** 2026-03-29T11:52Z  
**Category:** Architecture / Planning

### Summary

Complete level transition topology locked for Levels 1–4+. This is the binding map for all level design work.

### Level 1 → Level 2 (two paths)

1. **Bedroom window → Courtyard → Garden (early access shortcut)**
   - Existing portal #199 (already implemented)
   - Player can reach Level 2 early but garden is just the start
   
2. **Deep cellar staircase → Mausoleum (completion exit)**
   - Player completes Level 1 underground puzzles
   - Staircase ascends **through the mausoleum floor**
   - Emerges in mausoleum (dramatic climax)
   - This is the \"true\" Level 1 completion path

### Mausoleum (Level 2) — Dual Role

- **Arrival point:** Where staircase from Level 1 leads
- **Level 3 gate:** Puzzle-locked descent into Level 3

### Level 2 → Level 3

- **Mausoleum puzzle gate** (Sideshow Bob designs the puzzle)
- Players must solve mausoleum puzzle to access Level 3

### Level 2 → Level 4+

- **Hedge maze exit → Moorland / wild countryside**
- Garden's manicured geometry dissolves into untamed landscape
- Estate boundary — civilization ends; wilderness begins

### Rework Needed

- **Issue #205 scope:** Hallway staircase no longer goes to Level 2 garden. It's the path to upper floors (attic, tower, servant quarters) — future level
- **Last room in Level 1 underground:** Needs to feel like a culmination before the staircase ascent
- **Courtyard-to-garden connection:** Needs a portal (garden gate, archway, or path) per D-LEVEL2-COURTYARD-PORTAL

### Impact

- **Moe:** Room design (Level 2 rooms + mausoleum + courtyard)
- **CBG:** Map flow validation
- **Sideshow Bob:** Mausoleum puzzle design
- **Lisa:** Issue #205 scope change (hallway staircase = upper floors)
- **Level 2 board:** Full topology integrated
- **Level 3 planning:** Mausoleum gate is the entry point

---

## 2026-08-02: Options Project Team Review Ceremony — 12 Blockers, Architecture Approved

**By:** Squad (Coordinator) — consolidating 5 reviewer reports  
**Date:** 2026-03-29T21-13-50Z (reviewed 2026-08-02)  
**Category:** Architecture Review / Implementation Planning  
**Status:** ⚠️ CONCERNS — 12 blockers identified, all addressable

### Summary

Five-agent team review (Bart, Smithers, Moe, Nelson, Sideshow Bob) of the Options project — a goal-driven hint system for stuck players. The **Approach C hybrid architecture** (goal suggestions + sensory suggestions + dynamic actions + GOAP integration) was **unanimously approved**. However, **12 blockers across 6 categories** must be resolved before GATE-1 approval.

### Verdicts

| Reviewer | Verdict | Blockers |
|----------|---------|----------|
| Bart (Architecture) | ⚠️ CONCERNS | 2 (API contracts, context window decision) |
| Smithers (Parser/UI) | ⚠️ CONCERNS | 4 ("help me" collision, numeric precedence, numbered exits, Phase 4 tests) |
| Moe (World Builder) | ✅ APPROVE | 0 (3 defer to Phase 5) |
| Nelson (QA) | ⚠️ CONCERNS | 4 (Phase 5 spec contradiction, performance test, GATE-5 criteria, empty room) |
| Sideshow Bob (Puzzle Master) | ⚠️ CONCERNS | 2 (anti-spoiler gaps, puzzle exemption system) |

### 12 Consolidated Blockers

#### Architecture (4)
- **B1:** API contracts missing (option table structure, context requirements) — Bart adds to architecture (30 min)
- **B2:** Context window decision unresolved (stable A, rotate B, hybrid C) — Wayne decides
- **B3:** Anti-spoiler Rule 5 punishes stuck players — replace with escalating specificity (Bob/Bart, 1 hour)
- **B4:** No puzzle room exemption system — add `options_disabled`, `options_mode`, `options_delay` (Bob/Moe, 1 hour)

#### Parser/UI (3)
- **B5:** "help me" collides with help verb — remove from options aliases (Smithers, 15 min)
- **B6:** Numeric object names precedence undefined — clarify: pending_options active when exists (Smithers/Bart, 15 min)
- **B7:** Numbered exits conflict undocumented — reserve numeric input, prohibit "go 1" (Bart, 15 min)

#### Test/Specification (4)
- **B8:** Phase 5 tests reference `room.hints` (architecture uses `room.goal`) — rewrite specs (Kirk, 30 min)
- **B9:** Performance budget (<50ms) not testable — add `test/options/test-performance.lua` (Bart/Nelson, 30 min)
- **B10:** GATE-5 criteria subjective — define "All 7 CRITICAL scenarios pass, no HIGH/CRITICAL bugs" (Kirk, 15 min)
- **B11:** Empty room edge case uncovered — add test + design decision (Bart, 30 min)

#### Meta (1)
- **B12:** Goal completion detection unclear (action-based vs state-based) — clarify in architecture (Bart, 30 min)

### Key Highlights

✅ **Architecture unanimously approved** — Approach C is the right design  
✅ **GOAP reuse praised** — smart engineering, battle-tested existing code  
✅ **Sensory-first priority** preserves core dark-room gameplay  
✅ **Parser integration clean** — Tier 1 dispatch, no pipeline changes  
✅ **Room design impact minimal** — 2.5-3.5 hours workload, no field conflicts  
✅ **Bob proposed 3-tier exemption system** — excellent design addition  
✅ **Nelson provided comprehensive test matrix** — 12-scenario spec vs vague 5

### Next Steps

1. Bart — add API contracts to architecture (B1), clarify goal completion detection (B12) — 1 hour
2. Wayne — decide context window behavior (B2)
3. Bob + Bart — revise anti-spoiler rules + exemption system (B3, B4) — 2 hours
4. Smithers — remove "help me" alias, document numeric precedence (B5, B6, B7) — 30 min
5. Kirk — fix Phase 5 test refs, quantify GATE-5, add test scenario matrix (B8, B10) — 1 hour
6. Nelson — add performance test to Phase 1, empty room test, expand LLM scenarios (B9, B11) — 1 hour
7. **GATE-1 READY** — after all fixes complete

**Estimated fix time: 1 day** (parallel work across 4 agents)

**Related documents:**
- `.squad/decisions/inbox/bart-options-review.md` — Detailed architecture findings
- `.squad/decisions/inbox/smithers-options-review.md` — Parser/UI analysis
- `.squad/decisions/inbox/moe-options-review.md` — Room metadata assessment
- `.squad/decisions/inbox/nelson-options-review.md` — QA and test coverage
- `.squad/decisions/inbox/bob-options-review.md` — Anti-spoiler and puzzle integrity
- `.squad/decisions/inbox/squad-options-review-ceremony.md` — Full ceremony transcript

**Status:** APPROVE with mandatory blocker fixes before GATE-1

---

## D-OPTIONS-V2: Options Architecture v2 — 12 Blockers Resolved

**Status:** 🟢 Active  
**Author:** Bart (Architecture Lead)  
**Date:** 2026-08-02  
**Category:** Architecture / Implementation

### What Was Fixed

Resolved 6 of 12 blockers identified in the Options team review ceremony:

- **B1 (API Contracts):** Added section 4.0 defining `OptionEntry` structure (`command`, `display`, `source` fields), context requirements (`ctx.current_room`, `ctx.player`, `ctx.light_level`, `ctx.recent_commands`, `ctx.options_request_count`), and `OptionsResult` return type. Complete interface contract between options system and engine.

- **B6 (Numeric Object Names Precedence):** Added precedence rule to section 4.3 — `pending_options` is ONLY active after player calls `options` verb. When `nil` (default state), numeric input passes through parser unchanged. Objects with numeric names (e.g., "2") work normally unless player has an active options window.

- **B7 (Numeric Exits Collision):** Added collision avoidance paragraph to section 4.3 — numbers 1-4 reserved for option selection only when `pending_options` active. Rooms with numeric exit names (if any) require "go 1" instead of bare "1" during active options window. Collision window is minimal (only between `options` call and acting on suggestion).

- **B9 (Performance Budget):** Added section 4.4.1 — <50ms total budget (30ms GOAP, 10ms sensory, 10ms dynamic). If GOAP exceeds 30ms, graceful degradation skips goal phase and returns only sensory+dynamic suggestions. Uses `os.clock()` timing with backoff pattern for rooms that consistently timeout. Ensures instant response (<100ms perception threshold).

- **B11 (Empty Room Edge Case):** Added section 4.4.2 — when room has no goal, no interesting objects, no scored candidates, return generic exploration prompts (look/feel based on light, listen, available exits). Ultimate fallback: single `wait` option with "Nothing obvious comes to mind..." flavor text. System never returns empty list — UI failure prevention.

- **B12 (State-Based Goal Detection):** Added goal completion detection subsection to section 4.5 — goals complete when postcondition state is true in game world, NOT when player attempts action. Failed actions (locked door, too dark, missing tool) don't count as completion. Uses `goal_complete(ctx, goal)` function with FSM state-query infrastructure. Includes escape hatch `complete_when` function for goals that don't map to FSM/inventory checks.

### Architecture Decisions Confirmed by Wayne

- **Approach C:** Goal-driven hybrid (room declares goal, GOAP plans path, sensory suggestions fill slots)
- **Option C Context Window:** Stable goal steps + rotating sensory suggestions
- **Free Hints:** No cost to player (accessibility, not cheat code)
- **State-Based Goals:** Completion detected via game state, not action attempts

### Status

Architecture approved for implementation. Proceed with Phase 1 (core verb + number selection).

### Impact

Unblocks GATE-1. Implementation phases defined in section 8. Bart handles Phase 1-2 (core verb, GOAP integration), Moe handles Phase 3 (room goals), Smithers+Bob handle Phase 4 (polish).

---

## D-OPTIONS-B5: "help me" Removed from Options Aliases

**Status:** ✅ Verified  
**Author:** Smithers (Parser/UI Engineer)  
**Date:** 2026-08-02  
**Category:** Parser

### Decision

**"help me" is NOT included in the options verb aliases.** It stays mapped to the existing `help` verb (command reference).

### Rationale

- **Different player intents:** "help me" seeks the command reference; "options" seeks contextual guidance
- **Collision risk:** Players saying "help me" expect the help verb to respond, not options suggestions
- **Clear separation:** The architecture maintains this distinction at the parser level

### Final Options Aliases

10 confirmed options triggers:
- "what are my options" → options
- "give me options" → options
- "what can I try" → options
- "I'm stuck" → options
- "hint" / "hints" → options
- "nudge" / "give me a nudge" → options
- "give me a hint" / "suggest something" → options

### Verification

- ✅ Section 4.2 code blocks do NOT include "help me"
- ✅ Executive Summary and Problem Statement don't mention "help me" as options trigger
- ✅ `preprocess/phrases.lua` block: 7 patterns, none are "help me"
- ✅ `preprocess/idioms.lua` block: 3 idiom mappings, none are "help me"

### Impact

- Parser: No changes needed (already correct)
- Verbs: No changes needed (existing `help` verb unaffected)
- Documentation: No prose updates needed; architecture already reflects correct design

---

## D-OPTIONS-ANTISPOILER: 3-Tier Escalating Specificity + Puzzle Exemption System

**Status:** 🟢 Active  
**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-08-02  
**Category:** Design

### What Was Fixed

Replaced diminishing returns (rule 5) with 3-tier escalating specificity: **Standard → Context Clues → Mercy Mode**. Added 7-rule anti-spoiler framework. Added puzzle room exemption system with 3 flags.

### Three Escalating Tiers

1. **Standard (First Request):** Generic exploration nudges
   - "What can I sense?" (light-dependent LOOK/FEEL)
   - "What's nearby?" (exit list)
   - Goal-driven "Try XYZ" (sensory only, no spoilers)

2. **Context Clues (2nd–4th Requests):** Moderate hint escalation
   - Tools/materials mentioned: "You need fire to proceed"
   - Spatial relationships: "The object below the table..."
   - Past attempts remembered: "You tried that; what else?"

3. **Mercy Mode (5+ Requests):** Explicit guidance
   - Direct commands: "Try `put candle in holder`"
   - Synonym hints: "The vessel that holds fire..."
   - Action sequences: "First light the candle, THEN touch the wick"

### Anti-Spoiler Framework (7 Rules)

1. Never spoil end-game puzzles (final room exemption)
2. Never name NPCs before discovery
3. Never reveal mutation targets (outcomes, not triggers)
4. Context clues teach verb/material use, not solutions
5. Mercy mode avoids story spoilers (mechanics only)
6. Timer prevents hint spam abuse (escalation counter resets on success)
7. Puzzle rooms can opt-out entirely (exemption flags)

### Puzzle Exemption System (3-Tier Flags)

- **`options_disabled`:** No hints at all (2-3 climactic moments per level max) — player is entirely on their own
- **`options_mode="sensory_only"`:** Only sensory suggestions (look/feel/listen), no goal steps — preserves atmosphere without abandoning player
- **`options_delay=N`:** Hints only after N minutes of inactivity — lets skilled players solve solo before receiving help

Per-phase exemptions supported via `on_state_change` hook.

### Impact

- **Bart:** Implements escalation counter (`ctx.options_request_count`) and reset logic
- **Moe:** Adds exemption flags to puzzle room definitions
- **Options system:** Scales from gentle exploration nudges (Standard) to explicit commands (Mercy Mode) based on player need
- **Player retention:** Stuck players get progressive help; skips punishment/sarcasm entirely

---

## D-OPTIONS-PLAN-V1: Options Plan v1.0 — GATE-1 READY

**Status:** 🟢 Active  
**Author:** Kirk (Project Manager)  
**Date:** 2026-08-02  
**Category:** Planning

### What Was Fixed

Fixed 4 of 12 blockers + updated plan to v1.0 with all questions resolved:

- **B8 (Phase 5 Test Refs):** Rewritten specs to reference `room.goal` (architecture term) instead of `room.hints` (discarded). Phase 5 integration tests now target correct object names.

- **B10 (Quantitative GATE-5 Criteria):** Defined binding thresholds:
  - 12/12 critical scenarios pass (no workarounds)
  - 5/5 context window aliases verified functional
  - <50ms response time (measured on target hardware)
  - 0 regressions (parser, verbs, containment)

- **B11 (Empty Room Edge Case):** Documented fallback behavior — when no goal/objects/scored candidates exist, return single `wait` option with generic prompt.

- **B12 (State-Based Goal Detection):** Documented that goals complete when postcondition is true in game world (FSM states, inventory), not when player attempts action.

### Plan v1.0 Contents

- **Executive Summary:** Approach C approved, 5 phases defined, 12 blockers resolved
- **Phase 1 (Core Verb + Selection):** 3 days, Bart-led
- **Phase 2 (GOAP Integration):** 2 days, Bart-led
- **Phase 3 (Room Goals):** 2 days, Moe-led
- **Phase 4 (Polish):** 2 days, Smithers+Bob
- **Phase 5 (LLM Testing):** 1 day, Nelson-led
- **All questions answered:** Wayne's decisions captured, team alignment confirmed

### Status

**GATE-1 READY** — All blockers resolved by team (Bart: B1/B6/B7/B9/B11/B12, Smithers: B5, Bob: B3/B4, Kirk: B8/B10). Architecture approved. Plan finalized. Implementation can begin immediately.

### Dates Locked

- **GATE-1 READY:** 2026-08-02
- **Implementation window:** Phase 1 starts 2026-08-05 (after merge/approval)
- **GATE-5 target:** End of Phase 5 (~2026-08-16)

---

## D-WYATT-WORLD: Wyatt's World — MrBeast Challenge Arena

**Status:** 🟢 Active  
**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-08-22  
**Category:** Design / New World  
**Affected:** Moe (rooms), Flanders (objects), Sideshow Bob (puzzles), Smithers (parser), Nelson (testing), Gil (web)

### Summary

Wyatt's World is a standalone world built for Wyatt (age 10) themed around MrBeast's YouTube brand. 7 rooms, hub-and-spoke layout, single-room puzzles, 3rd grade reading level, 5th grade puzzle difficulty. E-rated (no combat, injury, darkness, or danger).

### Key Design Decisions

1. **Hub-and-spoke layout:** MrBeast's Challenge Studio is the central hub. 6 challenge rooms branch off. Every room connects back to the hub. Player can't get lost.
2. **Single-room puzzles only:** No multi-room dependency chains. Every puzzle solvable with only items and clues in that room.
3. **3rd grade reading level:** 8–12 word sentences, simple vocabulary, active voice, present tense.
4. **No darkness, injury, poison, or danger:** All senses safe. TASTE never harms. No horror content.
5. **Reading IS the puzzle:** Every challenge's core mechanic is careful reading — signs, labels, recipes, letters, riddles.
6. **Failure is funny:** Wrong answers produce silly sounds and encouraging hints, never punishment.
7. **Same engine, different content:** Uses identical verb/FSM/mutation/containment systems. Only theme and tone differ from The Manor.
8. **~70 objects** across 5 categories: challenge props, prizes, brand items, reading/clue objects, set dressing.
9. **Modern era aesthetic:** Plastic, metal, glass, cardboard, bright colors. Forbidden: stone, bone, tallow, iron, gothic materials.

### Rooms (7 total)

| Room | Hub? | Puzzle | Difficulty |
|------|------|--------|-----------|
| MrBeast's Challenge Studio | ✓ Hub | Press correct button after reading sign | ★ |
| The Feastables Factory | Spoke | Sort chocolates by flavor into bins | ★★ |
| The Money Vault | Spoke | Calculate totals, enter safe code | ★★ |
| The Beast Burger Kitchen | Spoke | Build burger in recipe order | ★★★ |
| The Last to Leave Room | Spoke | Find 3 fake objects by reading descriptions | ★★★ |
| The Riddle Arena | Spoke | Solve 3 riddles, interact with answer objects | ★★★★ |
| The Grand Prize Vault | Spoke | Extract numbers from letter, enter code | ★★★★ |

### Full Specification

Full design document: `projects/wyatt-world/design.md`

### Impact

- **Moe:** Build 7 room .lua files + world .lua. Hub room id = `beast-studio`.
- **Flanders:** ~70 object definitions with kid-friendly sensory descriptions. No weapon/armor templates.
- **Sideshow Bob:** 7 self-contained puzzles with hint escalation.
- **Smithers:** No parser changes. Simple keywords only. Kid-friendly error messages.
- **Nelson:** Test zero-harm invariant (no injury, darkness, or poison). Test hub connectivity. Test puzzle isolation.
- **Gil:** Web deployment (no special build changes).

### Rationale

This world proves the engine can serve radically different audiences using the same mechanics. If the verb/object/FSM system works for both gothic horror AND a kids' MrBeast game show, the engine architecture is validated for multi-world expansion.

---

## D-WYATT-PLAN: Wyatt's World Implementation Plan v2.1

**Status:** 🟢 Active  
**Author:** Bart (Architecture Lead)  
**Date:** 2026-08-22 (v2.0), 2026-08-23 (v2.1 fixes)  
**Category:** Architecture / Planning  
**Affected:** All agents — Bart (WAVE-0 engine), Moe (WAVE-1a rooms), Flanders (WAVE-1b objects), Sideshow Bob (WAVE-1c puzzles), Nelson (WAVE-1d testing), Smithers (WAVE-2a parser), Gil (WAVE-3c web)

### Summary

Comprehensive implementation plan for Wyatt's World. 4 waves, 3 gates, 15 TDD files, ~6,050 estimated LOC. All blockers resolved in v2.1.

### Four Waves

- **WAVE-0 (Bart):** Multi-world loader upgrade + `--world <id>` CLI flag
- **WAVE-1 (Parallel):** Content authoring
  - WAVE-1a (Moe): 7 rooms + world .lua file
  - WAVE-1b (Flanders): ~70 objects + level file
  - WAVE-1c (Sideshow Bob): 7 puzzle specs + hint escalation
  - WAVE-1d (Nelson): Test scaffolding
- **WAVE-2 (Smithers):** Parser polish + object narration
- **WAVE-3 (All):** Web deploy + final audit

### Three Gates

- **GATE-0:** Multi-world boot verified
- **GATE-1:** Content loads, 7 rooms connected, puzzles isolated, E-rating enforced
- **GATE-2:** All puzzles solvable, sensory coverage 100%, reading level certified
- **GATE-3:** Web deployment, reading-level sign-off, final regression

### Test Files (15 TDD)

- `test-world-loader.lua` — Multi-world loading
- `test-multi-world-boot.lua` — Boot regression
- `test-wyatt-rooms.lua` — Content loading
- `test-wyatt-objects.lua` — Object GUID uniqueness
- `test-wyatt-hub-connectivity.lua` — Hub-and-spoke topology
- `test-wyatt-sensory-coverage.lua` — All senses available
- `test-wyatt-safety-audit.lua` — No darkness/injury/poison
- `test-wyatt-e-rating-blocks.lua` — Combat verbs blocked
- 7 per-puzzle tests (`test-wyatt-studio-puzzle.lua` through `test-wyatt-grand-prize.lua`)

### Key Implementation Decisions

1. **Multi-world engine in WAVE-0:** World loader's `select()` upgraded to handle 2+ worlds. Mandatory engine change.
2. **`content_root` convention:** Each world .lua file gains optional `content_root` field. If nil, use legacy paths. If set, load from subdirectory.
3. **`--world <id>` CLI flag:** Required when 2+ worlds exist. Auto-select when 1 world (backward compat).
4. **Player-state scoreboard:** Track puzzle completion in `player.state.puzzles_completed = {}`. Recommended, to be confirmed by Bob + Flanders.
5. **GUID pre-assignment:** Bart reserves GUID block for all Wyatt objects (1 world + 7 rooms + 1 level + ~70 objects) to prevent collisions during parallel authoring.

### Blockers Fixed (v2.1)

1. ✅ **Content Root Convention:** Multi-world loader now supports per-world `content_root` field
2. ✅ **GUID Collision:** Pre-assigned block of ~80 GUIDs (bart-wyatt-guids.md)
3. ✅ **E-Rating Enforcement:** Engine blocks combat/self-harm verbs, test gate G2-8 added

### Concerns Fixed (v2.1 — 12 total)

All 12 concerns from team review resolved:
- Risk register expanded (6 risks with mitigations)
- Success criteria clarified
- Test file structure formalized (15 TDD files)
- Object catalog fully specified (5 categories, ~70 objects)
- Reading-level audit gates added (WAVE-2 auto-scan + GATE-3 manual audit)
- Web regression explicitly covered (GATE-3)
- Cross-agent coordination documented
- Backward compatibility (The Manor) confirmed in regression tests

### Impact

- **Bart:** Executes WAVE-0 (engine loader upgrade, main.lua refactoring, E-rating enforcement)
- **Moe:** WAVE-1a rooms blocked on GATE-0
- **Flanders:** WAVE-1b objects + level file blocked on GATE-0
- **Bob:** WAVE-1c puzzle specs blocked on GATE-0
- **Nelson:** WAVE-1d test scaffolding blocked on GATE-0
- **Smithers:** WAVE-2a parser polish blocked on GATE-1
- **Gil:** WAVE-3c web deploy blocked on GATE-2

### Full Specification

`projects/wyatt-world/plan.md` (v2.1, final)

---

## D-WYATT-GUIDS: Wyatt's World GUID Pre-Assignment Block

**Status:** 🟢 Active  
**Author:** Bart (Architecture Lead)  
**Date:** 2026-08-23  
**Category:** Planning / GUID Management  
**Purpose:** Prevent GUID collisions during parallel authoring (WAVE-1). Moe and Flanders use ONLY GUIDs from this block. No independent GUID generation.

### Rules

1. **Sequential assignment:** Use GUIDs in order from each category. Don't skip or shuffle.
2. **No reuse:** Each GUID is used exactly once.
3. **Overflow:** If a category runs out, take from the Overflow pool (end of list).
4. **Format:** Windows `{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}` — curly braces included.

### GUID Blocks

**World Definition (1 GUID)**
- W1: `{6F129CCE-4798-446D-9CD8-198B36F04EF0}` — wyatt-world.lua (Bart)

**Room GUIDs (7 GUIDs — Moe)**
- R1: `{2CC1419B-3F68-44DD-BDA6-A5627650C410}` — MrBeast's Challenge Studio (beast-studio.lua)
- R2: `{D4B094DA-842B-4011-B9A0-BE0007825BE4}` — The Feastables Factory (feastables-factory.lua)
- R3: `{4DB5FAE6-6FB1-4CDA-9292-FC76B0B50581}` — The Money Vault (money-vault.lua)
- R4: `{17873274-B097-4669-B4D5-2B6524579835}` — The Beast Burger Kitchen (beast-burger-kitchen.lua)
- R5: `{C9E72A2F-E1AD-465C-A4E0-9AE69816F752}` — The Last to Leave Room (last-to-leave.lua)
- R6: `{611A8C30-3C89-4018-B143-5448F383D9E1}` — The Riddle Arena (riddle-arena.lua)
- R7: `{803085D7-5E49-4AAC-A035-391148E7AB5C}` — The Grand Prize Vault (grand-prize-vault.lua)

**Level GUID (1 GUID — Flanders)**
- L1: `{440AC83D-D479-4832-A2F2-482FC4E5014A}` — Level 01 — MrBeast's Challenge Arena (level-01.lua)

**Object GUIDs (~70 GUIDs — Flanders)**
- Challenge Props (~25): Big red button, colored buttons, dials, bins, conveyor, safe, podium, plates, etc.
- Prize Items (~8): Trophy, coupons, medals, confetti, cash
- Brand Items (~10): Feastables bars (5 flavors), burger components, merch, play button
- Reading/Clue Objects (~12): Welcome sign, letter, labels, recipe card, riddle boards, scoreboard
- Set Dressing (~15): Screens, cameras, speakers, banners, spotlights, streamers

**Total:** ~80 GUIDs (1 world + 7 rooms + 1 level + ~70 objects) — fully pre-assigned, zero collision risk.

### Usage Rules

- Moe: Use Room GUIDs (R1–R7) sequentially
- Flanders: Use Level GUID (L1) and Object GUIDs (O1–O70+) sequentially
- No trading or reordering
- If you need an extra GUID not in your category, escalate to Bart (overflow pool exists)

---

## D-RATING-SYSTEM: Content Rating System

**Status:** 🟢 Active  
**Author:** Bart (Architecture Lead)  
**Date:** 2026-08-23  
**Category:** Architecture / Safety  
**Affects:** All future worlds, verb dispatch, engine enforcement

### Decision

Implement a world-level rating system that blocks restricted verbs at the engine level for E-rated worlds.

### E-Rated Restrictions

- **Self-harm verbs** blocked: `self-injure`, `self-harm`, `hurt-self`, etc.
- **Combat verbs** blocked: `attack`, `fight`, `harm`, `kill`, `injure`, `combat`, etc.
- **Injury system** mechanically disabled (no damage calculations)
- **Poison system** disabled (taste always safe)
- **Darkness** optional (designer's choice, but no penalty for darkness in E-rated worlds)

### Implementation Points

1. **World .lua declares rating:** `rating = "E"` field in world definition
2. **Engine dispatch checks rating:** `context.world.rating` checked before verb execution
3. **Blocked verb behavior:** Returns safe error message ("That's not part of this world.") to player
4. **Design enforcement:** Designers should not create restricted-verb content in E-rated worlds, but engine blocks at dispatch layer for safety

### Wyatt's World Application

- Rating: `E` (kids' content)
- Restricted verbs automatically unavailable
- No combat, injury, or self-harm mechanics possible
- All sensory interactions safe by design

### Future Expansion

Other ratings possible (T, M, etc.) with different restriction sets, but E-rating is the first.

---

## D-RATING-TWO-LAYER: Two-Layer Rating Enforcement

**Status:** 🟢 Active  
**Author:** Bart (Architecture Lead)  
**Date:** 2026-08-23  
**Category:** Architecture / Design  
**Affects:** World design, object metadata, engine dispatch

### Decision

Content rating enforcement operates on **two layers:**

1. **Engine-enforced (Hard blocks):** Combat, self-harm, injury system verbs are mechanically blocked at verb dispatch
2. **Design-enforced (Soft guidelines):** Designers apply constraints: no poisons, no scary darkness, no hostile creatures

### Why Two Layers

- **Hard blocks** prevent accidental inclusion of forbidden verbs (safety first)
- **Soft guidelines** guide creative direction (tone, aesthetics, themes)
- **Combined approach** catches both technical violations (verb dispatch) and design violations (object creation)

### Wyatt's World Application

- **Engine layer:** Combat/self-harm verbs blocked; players cannot access them
- **Design layer:** Flanders avoids poison, gothic materials, and hostile creatures when creating objects

### Compliance Matrix

| Restriction | Engine Block | Design Guidance |
|------------|--------------|-----------------|
| Combat verbs | ✅ Hard-blocked | Objects designed without combat properties |
| Self-harm verbs | ✅ Hard-blocked | No self-harm props (knives, poison, etc.) |
| Injury system | ✅ Disabled | No injury objects |
| Poison | ✅ Can't activate | Never used in taste descriptions |
| Darkness | ⚠️ Optional | Designer decides (ok if non-punitive) |
| Hostile creatures | ⚠️ Not blocked | Objects designed as friendly/neutral only |

---
