# Testing — Board

**Owner:** 🏠 Marge (Test Manager) + 🧪 Nelson (QA Engineer)
**Last Updated:** 2026-03-29
**Overall Status:** ✅ Baseline healthy — 257 test files passing

---

## Test Suite Health

| Metric | Value |
|--------|-------|
| Total test files | 257 |
| All passing | ✅ Yes (verified 2026-03-29) |
| Pre-existing failures | 0 |
| Edge extractor tests | 58 |
| Integration tests | 13 (mutation-lint pipeline) |
| Linter tests (pytest) | Scaffold exists at `test/linter/` |

---

## Test Directories

| Directory | Coverage | Owner |
|-----------|----------|-------|
| `test/parser/` | Parser pipeline (preprocess, context, GOAP, fuzzy, embedding) | Nelson |
| `test/parser/pipeline/` | Per-stage preprocessing (7 files, 224+ tests) | Nelson |
| `test/verbs/` | Verb handlers (wine, wear, combat, poison, etc.) | Nelson |
| `test/search/` | Object discovery, traversal, spatial, containers | Nelson |
| `test/inventory/` | Inventory management, put/take, search order | Nelson |
| `test/injuries/` | Injury system, weapon pipeline, self-infliction | Nelson |
| `test/integration/` | Multi-command scenarios, regression tests | Nelson |
| `test/rooms/` | Room-level interaction tests | Nelson |
| `test/ui/` | UI/status bar tests | Nelson |
| `test/meta/` | Edge extractor (57), lint integration (13) | Nelson |
| `test/creatures/` | Creature behavior, combat, loot, pack tactics | Nelson |
| `test/wearables/` | Armor, helmets, material fragility | Nelson |
| `test/preservation/` | (Phase 5 — not yet created) | Nelson |
| `test/linter/` | pytest scaffold for meta-lint rules | Nelson |

---

## Upcoming Test Work

### Phase 5 (per implementation plan v2.0)

| Wave | New Tests | Test Files | Target Count | Status |
|------|-----------|-----------|--------------|--------|
| WAVE-1 | Level 2 rooms, creatures, transition | 5 files | 238+ | 🔴 Not started |
| WAVE-2 | Pack tactics v1.1 | 5 files | 248+ | 🔴 Not started |
| WAVE-3 | Salt preservation | 6 files | 258+ | 🔴 Not started |
| WAVE-4 | Integration walkthrough | 2 files | 270+ (stretch 300+) | 🔴 Not started |

**Phase 5 Test Infrastructure Gaps:**
- `test/preservation/` directory NOT created (Phase 5 WAVE-3)
- Phase 5 level-2 room test files not yet written
- Pack tactics test suite not yet scaffolded

> **Linter test work** (pytest scaffold, rule tests) is tracked in `projects/linter/board.md` — Wiggum's domain.

---

## Test Standards (from Phase 5 review)

| Standard | Status |
|----------|--------|
| Regression baseline snapshot | ✅ Phase 4 = 223 tracked tests |
| Deterministic seeds | ✅ `math.randomseed(42)` for pack/loot |
| Headless mode (`--headless`) | ✅ All LLM scenarios |
| Flaky test quarantine | ✅ Defined (95% threshold, `@skip-ci`, 3-run recovery) |
| LLM scenario log format | ✅ One file per scenario in `test/scenarios/` |
| Performance budgets | ✅ L2 <200ms, pack <50ms/tick, salt <20ms |

---

## Test Runner

```bash
lua test/run-tests.lua                    # Run all tests
lua test/run-tests.lua --bench            # Include benchmarks
lua test/parser/test-preprocess.lua       # Run specific file
pytest test/linter/                       # Run linter tests (Python)
```

**Pre-deploy:** `.\test\run-before-deploy.ps1` (tests + edge check + build)

---

## Open Issues Affecting Tests

| Issue | Impact | Status |
|-------|--------|--------|
| 7 pre-existing playtest bugs | Were in test-playtest-bugs.lua | ✅ Resolved (prior session) |
| Edge extractor count assertions | Updated after broken edge fixes | ✅ Fixed this session |

---

## Next Steps (2026-03-29)

### ✅ STEADY STATE — Phase 4 Complete
- All 257 test files passing (verified 2026-03-29)
- Edge extractor baseline: 206 files, 66 edges, 5 broken, 1 dynamic
- Mutation-lint integration tests live (13 tests)
- Linter pytest scaffold ready for rule testing

### ⏳ PRE-WAVE Testing Work (Before Phase 5 Execution)

**Priority 1: Infrastructure Preparation**
1. **Create `test/preservation/` directory** — scaffold for Phase 5 WAVE-3 salt preservation tests (Marge + Nelson)
   - Template test file: `test/preservation/test-salt-preservation-mechanics.lua`
   - Define test coverage area: object decay, salt slots, preservation state machines

2. **Create Phase 5 Level 2 room test structure** — 5 test files for WAVE-1
   - Template files: `test/integration/test-level2-rooms-*.lua` 
   - Placeholder test for each L2 room (east-corridor, kitchen, etc.)
   - Coverage: room transitions, new objects, sensory descriptions

3. **Create pack tactics test scaffold** — 5 test files for WAVE-2
   - Template file: `test/creatures/test-pack-tactics-*.lua`
   - Placeholder test structure for: alpha health logic, stagger attacks, loot distribution, pack detection
   - Cross-reference: Nelson's creature behavior checklist from Phase 4

**Priority 2: Flaky Test Quarantine Implementation**
- Current: Quarantine protocol documented in board (95% threshold, `@skip-ci`, 3-run recovery)
- Action: Create `.squad/decisions/inbox/marge-flaky-test-quarantine-implementation.md` documenting enforcement procedure
  - When test hit <95%, who files the quarantine issue? 
  - Tag convention for `@skip-ci` blocks in code
  - Recovery process: 3 consecutive passes → re-enable

**Priority 3: LLM Scenario Template Review**
- Current: Headless mode (`--headless`) defined; `test/scenarios/` directory ready for .log files
- Action: Verify scenario log format with Brockman + Comic Book Guy
  - Input/output separator?
  - Metadata format (scenario name, phase, timestamp)?
  - Integration with bug classification?

**Priority 4: Test Speed Phase 1 Execution**
- Current: Plan ready (`test-speed-implementation-phase1.md`), not yet executed
- WAVE-0 baseline verified: 257 test files, ~180s wall clock (2026-03-29 run)
- Next: Execute WAVE-1 (benchmark gating) — Nelson + Marge coordinate with Bart

### When Blocked: Waiting On
- **Flanders:** Phase 5 object definitions (preservation mechanics, Level 2 items)
- **Moe:** Level 2 room definitions (east-corridor, kitchen, etc.)
- **Bart:** Creature behavior engine finalization (pack tactics API)
- **Comic Book Guy:** Phase 5 puzzle definitions

---

*Board maintained by Marge + Nelson. Update after each phase gate.*
