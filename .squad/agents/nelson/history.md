# Nelson — Tester History

## Project Context
- **Owner:** Wayne "Effe" Berry
- **Project:** MMO — Lua text adventure engine
- **Stack:** Pure Lua, REPL-based, run via `lua src/main.lua`
- **Game starts in darkness** — player must feel around, find matchbox, light match to see
- **Key systems:** FSM engine for object state, Tier 2 embedding parser, container model, sensory verbs

## Critical Path
1. feel around → discover nightstand
2. open drawer → access matchbox
3. get matchbox → open matchbox → get match
4. light match (or strike match on matchbox) → room is lit
5. look around → see the room for the first time

## Core Context

**Agent Role:** Tester responsible for playtest validation, bug discovery, and regression verification.

**Testing Summary (2026-03-19 to 2026-03-23):**
- 12 playtests completed, 346+ tests run, 284+ passed
- Critical path: bedroom → cellar → storage-cellar → deep-cellar → hallway ✅ COMPLETE
- 60 unique bugs discovered (8 CRITICAL/HIGH, 20 MEDIUM+MAJOR, 4 LOW, 28 MINOR/COSMETIC)
- Phase 3 features (hit/unconsciousness/appearance/mirror): engine solid, parser gaps identified

## Learnings

### Phase 4 Walkthrough TDD Tests (2026-07-10)
- Wrote `test/integration/test-phase4-bugfixes.lua` — 5 tests for 3 Phase 4 wiring bugs (D-TESTFIRST)
- **Bug 1: Silk-bundle disambiguation** — `take silk-bundle` with 2 identical silk-bundles triggers "Which do you mean: a bundle of spider silk or a bundle of spider silk?" — impossible choice. Unit test confirms.
- **Bug 2: Silk crafting 2-ingredient recipes broken** — `craft silk-rope` (needs 2 silk-bundles) fails with "don't have enough" even when player holds both. Root cause: craft handler can't resolve 2nd ingredient from hand strings. 1-ingredient recipes (silk-bandage) work fine.
- **Bug 3: Unlock verb is a stub** — `handlers["unlock"]` just says "You can't unlock" without checking FSM transitions. The door has a proper `locked→closed` transition with `requires_tool = "brass-key"`, and the brass-key has `provides_tool = "brass-key"`, but the verb never calls `fsm.transition()`.
- Pre-existing test failures (4 files: silk-crafting, predator-prey, spider-web, combat-verbs) predate this change.
- `loader` is a static module (no `.new()`), `loader.load_source()` takes a SOURCE STRING not a file path.
- `verbs.create()` returns handlers directly — no `register_all` method.

### Linter Test Infrastructure — WAVE-0 + WAVE-1 (2026-07-29)
- Built pytest scaffold at `test/linter/` for meta-lint testing (D-LINTER-TEST-INFRA)
- **Files created:** `__init__.py`, `conftest.py` (5 fixtures: `lint_runner`, `tmp_meta_dir`, `sample_object`, `sample_room`, `sample_creature`, `sample_portal`), `helpers.py` (constants + assertion helpers), `fixtures/` (5 .lua files)
- **Baseline snapshot:** 206 files, 462 violations (1 error, 319 warnings, 142 info) — stored in `test/linter/baseline-snapshot.json`
- **test_xf03.py** — 5 tests for XF-03 keyword collision smart filtering (#190): same-room WARNING, cross-room INFO downgrade, allowlist suppression, disambiguator suppression, regression on true ambiguity. All pass.
- **test_xr05.py** — 3 tests for XR-05 generic material detection (#196): template suppression, object XR-05b warning, real material no-fire. All pass.
- **Discovery:** WAVE-1 XF-03 and XR-05 fixes are already implemented in `lint.py` — room-aware filtering, disambiguator logic, `get_rule_config()` API, and template XR-05 suppression are all live. Tests validate the existing implementation.
- **Key pattern:** lint.py resolves project root from `Path(__file__).resolve().parents[2]`, NOT cwd. Tests must use `--config` to isolate from project `.meta-check.json`. The `lint_runner` fixture handles this.
- `conftest.py` uses `_load_sibling()` importlib pattern (same as lint.py) for module imports.
- Tests use subprocess to call lint.py with `--format json --no-cache`, parse JSON output, filter by rule_id.

### Test Speed WAVE-0 + WAVE-1: Benchmark Gating (2026-08-22)
- **Baseline:** 255 test files, ~180s wall clock, 1 pre-existing failure (pre-rename).
- **Audit results:** `test-inverted-index.lua` → BENCHMARK (100-iter timing loop, mixed with correctness equivalence tests). `test-tier2-benchmark.lua` → BENCHMARK (parser accuracy benchmark, 550 lines). `test-bm25-deep.lua` → CORRECTNESS (pure assertion-based: verb/noun matching, score thresholds, edge cases, known bug docs, zero timing code). Only the first two were renamed.
- **Renames:** `test-inverted-index.lua` → `bench-inverted-index.lua`, `test-tier2-benchmark.lua` → `bench-tier2-benchmark.lua`. Used `git mv` for history preservation.
- **`--bench` flag:** Added to `test/run-tests.lua`. Parses CLI args, discovers `bench-*.lua` in a second pass per directory, shows "(including benchmarks)" in header. Backward compatible — default behavior unchanged.
- **Verification:** Without `--bench`: 255 files. With `--bench`: 257 files (+2 bench). Header message correct. All 255 correctness tests pass.
- **Key fact:** `test-bm25-deep.lua` looks like it could be a benchmark by name but is 100% correctness testing (asserts on specific verb/noun/score values). Don't rename it.

### Mutation Graph Linter — Test Plan Review (2026-08-23)
- Reviewed `plans/linter/mutation-graph-linter-implementation-phase1.md` test specs and gate criteria.
- **`test/meta/` does NOT exist yet.** Not in `test_dirs` array (lines 36-60 of `test/run-tests.lua`). Plan correctly identifies both tasks.
- **`test-helpers.lua` lacks `assert_gt`/`assert_gte`.** Only has `assert_eq`, `assert_truthy`, `assert_nil`, `assert_no_error`. Integration tests needing `> 20 edges` or `> 80 files` must use `assert_truthy(count > N, msg)` workaround.
- **`on_tool_use.when_depleted` has ZERO real objects.** 6 objects have `on_tool_use` but none use `when_depleted`. Mechanism 5 is purely theoretical. Tests need synthetic fixtures.
- **Actual file count is 206, not ~91+.** Plan says "Files scanned > 80 (currently ~91+)" — the threshold is fine but the documented count is very wrong.
- **`source_to_tests` in run-tests.lua (line 137) skips `scripts/`.** Changes to `scripts/mutation-edge-check.lua` won't trigger `test/meta/` tests via `--changed` flag. Needs a mapping entry.
- **`test/linter/` exists with 11 Python pytest files** — no naming conflict with Lua `test/meta/` tests.
- **Current test file count: 258** (before adding meta tests).
- **Key subdirs under src/meta/ not mentioned in plan:** `worlds/` (5 files), `materials/` (32 files) — scanner must handle these but plan doesn't test them specifically.
