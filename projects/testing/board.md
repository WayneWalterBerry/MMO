# Testing — Board

**Owner:** 🏠 Marge (Test Manager) + 🧪 Nelson (QA Engineer)
**Last Updated:** 2026-03-29
**Overall Status:** ✅ Baseline healthy — 257 test files passing

---

## Test Suite Health

| Metric | Value |
|--------|-------|
| Total test files | 257 |
| All passing | ✅ Yes (as of session end) |
| Pre-existing failures | 0 (7 in test-playtest-bugs.lua resolved in prior session) |
| Edge extractor tests | 57 (updated from 58 after broken edge fix) |
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

| Wave | New Tests | Test Files | Target Count |
|------|-----------|-----------|--------------|
| WAVE-1 | Level 2 rooms, creatures, transition | 5 files | 238+ |
| WAVE-2 | Pack tactics v1.1 | 5 files | 248+ |
| WAVE-3 | Salt preservation | 6 files | 258+ |
| WAVE-4 | Integration walkthrough | 2 files | 270+ (stretch 300+) |

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

*Board maintained by Marge + Nelson. Update after each phase gate.*
