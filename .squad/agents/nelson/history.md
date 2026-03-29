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

- **Cross-Agent Mutation Linter Review (2026-03-28):** Nine-agent review wave on mutation-graph-linter implementation plan. Cross-agent infrastructure concerns for Nelson: (1) **Gil CI gaps:** GitHub Actions runners default to Python 3.8 or 3.10, NOT 3.9. WAVE-0 pre-flight must add `setup-python@v4` action or tests will fail. (2) **Python environment validation:** mutation-lint.ps1 assumes Python is on PATH — needs version check + graceful error if 3.9 unavailable. (3) **PowerShell 7 compat:** GitHub Actions uses PS7 but `.ps1` may not explicitly specify version guard. Need `-Version 7.0` check or explicit `pwsh` binary call. Nelson's test infrastructure must validate these environment prereqs before running WAVE-1 tests. 12 test improvements identified (negative edge cases, deep nesting coverage, fixture isolation, regression tests on dynamic path skipping, parallel output interleaving verification). Lesson: environment setup is as critical as test logic — pre-flight gates prevent false negatives in CI.

### WAVE-0 Edge Extractor Tests (2026-08-23)
- Built `test/meta/test-edge-extractor.lua` — 47 tests across 7 suites for `scripts/mutation-edge-check.lua`.
- **Module loading trick:** Bart's script uses all-local functions and calls `main()` + `os.exit()` at the bottom. Can't `require()` it. Solution: read source, strip trailing `main()`, append return table exporting locals, load the modified chunk. Works cleanly.
- **`scan_meta_root` returns 2 values** (`files, subdirs`). Don't try to parse subdirectory names from filepaths — use the second return value.
- **`main()` doesn't return data.** Wrote `run_pipeline()` wrapper that calls the 4 extracted functions (scan, safe_load, extract_edges, resolve_target) in sequence and returns structured results for assertions.
- **Actual counts confirmed:** 206 files, 66 edges (47 original + 19 creature), 5 broken edges (wood-splinters ×4, poison-gas-vent-plugged ×1), 1 dynamic path (paper.lua write).
- **Registered `test/meta` in run-tests.lua:** added to `test_dirs`, `source_to_tests` mapping for `scripts/mutation-edge-check.lua`, and shard note ("other" shard).
- **All 256 test files pass** including the new one. No regressions.

### WAVE-1 Mutation-Lint Integration Tests (2026-08-23)
- Built `test/meta/test-mutation-lint-integration.lua` — 13 tests across 5 suites for end-to-end mutation-lint pipeline.
- **Python availability guard:** Checks `io.popen("python --version")` — if unavailable, prints "SKIP: Python not available" and exits 0 (not a failure). Critical for CI environments without Python.
- **`suite()` is just a print header, NOT a function wrapper.** Tests follow directly after `suite("name")` calls — no nesting. Initial version used `suite("name", function()...)` which broke test discovery.
- **`--targets` output includes WARNING lines for broken edges.** Parser must skip lines starting with "WARNING:" to get clean filepath list. Without filtering, file existence checks fail on warning text.
- **Test coverage:** (1) `--targets` runs without crash and outputs filepaths, (2) all listed files exist on disk, (3) known targets present (cloth.lua, glass-shard.lua, matchbox.lua, silk-bundle.lua, rag.lua), (4) lint.py executes without crashing on first target + known target, (5) wrapper script existence check (graceful skip if Bart's task incomplete).
- **`run_command()` helper:** Uses `io.popen(cmd .. " 2>&1")` to capture both stdout and stderr. Returns output string + success boolean. Essential for cross-platform command execution.
- **All 257 test files pass** including the new integration test. No regressions.

### WAVE-2 JSON Tests + Issue Filing (2026-08-23)
- Added 11 JSON output tests (Suite 8) to `test/meta/test-edge-extractor.lua` — total now 58 tests across 8 suites.
- **`--json` already implemented by Bart.** Tests run live, not SKIPped. SKIP logic retained for backward compatibility.
- **`broken_targets` is 2, not 4.** Task spec said 4 but Bart's JSON counts unique target IDs (wood-splinters + poison-gas-vent-plugged = 2). Adjusted test to match implementation.
- **JSON test coverage:** structure validation (summary/broken/dynamic keys), summary count assertions (files_scanned > 150, edges_found > 40, broken_edges == 5, broken_targets == 2, dynamic_paths >= 1), broken edge content (poison-gas-vent-plugged, wood-splinters), dynamic path content (paper.lua).
- **GitHub issues filed (3):**
  - #403 — `[mutation-lint] Create poison-gas-vent-plugged.lua mutation target` (squad:flanders)
  - #404 — `[mutation-lint] Create wood-splinters.lua spawn target` (squad:flanders)
  - #405 — `[mutation-lint] courtyard-kitchen-door wood-splinters spawn routes to Moe (room boundary)` (squad:🏗️ moe)
- bedroom-hallway-door-south → wood-splinters NOT filed as separate issue (same target as #404, noted in body).
- **All 257 test files pass** after WAVE-2 additions. No regressions.
- **Workstream 1 complete.** WAVE-0, GATE-0, WAVE-1, GATE-1, WAVE-2 all passed. Session log: 2026-03-28T23-33-01Z-mutation-graph-linter-complete.md. Commit: 6b96bd8.

### Options Review Ceremony (2026-08-02)

- Reviewed Options project as QA Engineer
- Verdict: ⚠️ CONCERNS (4 blockers: Phase 5 test refs, performance budget, GATE-5 criteria, empty room edge case)
- 15 findings identified; 7 non-blocking gaps
- Provided comprehensive test matrix: 12-scenario LLM walkthrough spec (vs vague 5)
- See `.squad/decisions/inbox/nelson-options-review.md` for full review
