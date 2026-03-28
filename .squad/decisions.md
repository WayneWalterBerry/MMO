# Squad Decisions

**Last Updated:** 2026-03-28T13:00:00Z  
**Last Merge:** 2026-03-28T13:00:00Z (4 decisions from inbox)  
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

**For older decisions, design discussions, and completed Phase 3 work, see `decisions-archive.md`.**
