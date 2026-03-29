# Worlds — Board

**Owner:** 🏗️ Bart (Architecture Lead) + 🏗️ Moe (World & Level Builder)
**Last Updated:** 2026-03-30 (WAVE-0 + WAVE-1 loader completed by Bart)
**Overall Status:** 🚧 IN PROGRESS — WAVE-0 ✅ Done, WAVE-1 loader ✅ Done, WAVE-1 data + WAVE-2/3 pending

---

## Next Steps (WAVE-0 through WAVE-3 as per implementation plan)

| Priority | Wave | Task | Owner | Status | Gate |
|----------|------|------|-------|--------|------|
| **P0** | WAVE-0 | Create `src/meta/worlds/` and `src/meta/worlds/themes/` directories | Bart | ✅ Done | — |
| **P0** | WAVE-0 | Register `test/worlds/` in test runner (`test/run-tests.lua`) | Bart | ✅ Done | — |
| **P0** | WAVE-1 | Implement world loader engine (`src/engine/world/init.lua`) | Bart | ✅ Done | GATE-1 |
| **P0** | WAVE-1 | Write world loader tests (`test/worlds/test-world-loader.lua`) | Nelson | ✅ Done (Bart) | GATE-1 |
| **P1** | WAVE-1 | Write world definition tests (`test/worlds/test-world-definition.lua`) | Nelson | ⏳ Pending | GATE-1 |
| **P1** | WAVE-1 | **Design Team: Fill out theme subsections** for `src/meta/worlds/world-01.lua` — create `src/meta/worlds/themes/manor-architecture.lua`, `manor-creatures.lua`, `manor-history.lua` (uncomment theme_files in world-01.lua) | CBG + Willie + Moe | ⏳ Pending | GATE-1 |
| **P1** | WAVE-2 | Integrate boot sequence (world-driven `main.lua` boot) | Bart | ⏳ Pending | GATE-2 |
| **P1** | WAVE-2 | Write boot integration tests (`test/worlds/test-world-boot.lua`, `test/integration/test-world-integration.lua`) | Nelson | ⏳ Pending | GATE-2 |
| **P2** | WAVE-3 | Architecture docs (`docs/architecture/engine/world-system.md`) | Brockman | ⏳ Pending | GATE-3 |
| **P2** | WAVE-3 | Update design docs (`docs/design/worlds.md`, `docs/architecture/objects/world-template.md`) | Brockman | ⏳ Pending | GATE-3 |
| **P2** | WAVE-3 | LLM walkthrough (verify no gameplay regression) | Nelson | ⏳ Pending | GATE-3 |

**Note:** See `projects/worlds/worlds-implementation-phase1.md` for full 4-wave implementation plan with detailed specifications.

---

## Implementation Status

| Wave | Name | Status | Gate | Key Deliverables |
|------|------|--------|------|-----------------|
| WAVE-0 | Pre-Flight (dirs + test runner) | ✅ Done | — | Directory creation, test runner update |
| WAVE-1 | World Loader + Data (foundation) | ✅ Done (loader + tests) | GATE-1 | `engine/world/init.lua`, tests (16 pass) |
| WAVE-2 | Boot Integration (engine wiring) | ⏳ Pending | GATE-2 | `main.lua` world-driven boot, integration tests |
| WAVE-3 | Documentation + Verification (ship gate) | ⏳ Pending | GATE-3 | Architecture docs, LLM walkthrough |

**Parallel tracks:** Each wave uses parallelizable tasks per implementation plan Section 3.

---

## What Already Exists (Complete)

| Artifact | Status | Location | Notes |
|----------|--------|----------|-------|
| Design spec (full, comprehensive) | ✅ Complete | `docs/design/worlds.md` (496 lines) | Reference spec with 9 sections, theme system, The Manor concept, rollout plan |
| World template | ✅ Exists | `src/meta/templates/world.lua` | Base template with required fields: guid, id, name, levels, starting_room, theme |
| World 1 (The Manor) definition | ✅ Exists | `src/meta/worlds/world-01.lua` (81 lines) | Full theme spec with 8 fields, references level-01, starting_room = "start-room" |
| `src/meta/worlds/` directory | ✅ Exists | `src/meta/worlds/` | Holds all world definitions; `world-01.lua` currently present |
| Decision D-WORLDS-CONCEPT | ✅ Active | `.squad/decisions.md` | Architecture decision for worlds as top-level container; active in Bart + Moe histories |
| Implementation plan (Phase 1) | ✅ Complete | `projects/worlds/worlds-implementation-phase1.md` (586 lines) | 4-wave plan, dependency graph, detailed task specs, gate criteria, owner assignments |
| World loader engine module | ✅ Complete | `src/engine/world/init.lua` | discover(), load(), validate(), select(), get_starting_room() |
| Test directory | ✅ Created | `test/worlds/` | Created + registered in test runner |
| Test runner registration | ✅ Updated | `test/run-tests.lua` | `test/worlds/` in test_dirs + source_to_tests mapping |
| Boot integration | ❌ NOT started | `src/main.lua` (to-do) | Needs world-driven boot logic per WAVE-2 spec |
| Tests — world-loader | ✅ Written | `test/worlds/test-world-loader.lua` | 16 tests: discover, validate, select, load, get_starting_room + real world-01 integration |
| Tests — world-definition | ❌ NOT written | `test/worlds/test-world-definition.lua` (to-do) | WAVE-1 remaining (Nelson) |
| Tests — world-boot | ❌ NOT written | `test/worlds/test-world-boot.lua` (to-do) | WAVE-2 (Nelson) |

---

## Concept: The Manor (World 1) — Gothic Domestic Horror

- **Theme:** Gothic domestic horror, medieval 1450s, 2 AM darkness, isolation, escape narrative
- **Levels:** 3 total (Level 1 live now; Level 2–3 future)
  - Level 1: The Awakening (7 rooms) — bedroom start, cellar, hallway navigation
  - Level 2–3: Deferred to Phase 5+
- **8-field theme system:** pitch, era, aesthetic, atmosphere, mood, tone, constraints, design_notes
- **Purpose:** Top-level organizational hierarchy (World → Level → Room → Object) for 100+ levels
- **Materiality:** Stone, iron, wood, tallow, wool, leather. Forbidden: steel, concrete, plastic, electrical.
- **Current state in codebase:** Template and world-01.lua fully defined per design spec. Awaiting engine loader implementation.

---

## Scope: Phase 1 (This Board) vs Phase 2+ (Deferred)

**Phase 1 (READY TO EXECUTE):**
- ✅ World loader module (`src/engine/world/init.lua`) — generic, dependency-injected, no-hardcodes
- ✅ Single-world auto-select: If 1 world exists → use it; 0 worlds → FATAL error; 2+ worlds → "not implemented" (Phase 2)
- ✅ World-driven boot: `main.lua` loads World → resolves Level → resolves starting room (data-driven, not hardcoded)
- ✅ Test foundation: discover, validate, select logic; boot integration; LLM walkthrough
- ✅ Documentation: architecture, template, design updates

**Phase 2+ (DEFERRED):**
- ❌ Multi-world selection UI (requires 2+ worlds)
- ❌ Rift mechanics (multiplayer co-op, world transitions)
- ❌ Theme enforcement linting (optional designer aid)
- ❌ Difficulty modes per world
- ❌ New worlds (The Swamp, The Palace, etc.)

---

## Ownership & Charter Alignment

| Domain | Owner | Charter | Notes |
|--------|-------|---------|-------|
| World loader engine (`src/engine/world/`, WAVE-1) | Bart | Architecture Lead — engine modules | Dependency-injected, no hardcodes. Discover → Validate → Select → Load orchestration |
| World template + data (`src/meta/worlds/`, `src/meta/templates/world.lua`) | Moe | World & Level Builder | Manages world definitions, theme specs, starting_room references |
| World-driven boot integration (`src/main.lua`, WAVE-2) | Bart | Architecture Lead — engine boot | Replaces hardcoded `level-01` with world-driven data fetch |
| Test suite (test/worlds/) | Nelson | QA & Test Automation | 3 test files: world-loader, world-definition, world-boot + integration |
| Documentation (docs/architecture/, docs/design/) | Brockman | Documentation Lead | 3 doc files: world-system.md, world-template.md, design update |

---

## Plan Files

| File | Purpose |
|------|---------|
| `projects/worlds/worlds-design.md` | Full design spec |
| `projects/worlds/worlds-implementation-phase1.md` | 4-wave implementation plan |

---

*Board maintained by Coordinator. Update after each wave.*
