# Test Runner Flags

This document describes the command-line flags available for the MMO test runners: the serial runner (`test/run-tests.lua`), the Windows parallel runner (`test/run-tests-parallel.ps1`), and the Unix parallel runner (`test/run-tests-parallel.sh`).

---

## Serial Runner (`test/run-tests.lua`)

The serial runner discovers and executes all test files sequentially from the repository root. Runs on any system with Lua installed.

**Usage:**
```bash
lua test/run-tests.lua [--bench] [--shard <name>] [--changed]
```

**Must be run from repository root.**

### Flags

| Flag | Description | Example |
|------|-------------|---------|
| (no flags) | Run all test-* files, skip benchmarks | `lua test/run-tests.lua` |
| `--bench` | Include bench-* benchmark files in addition to test files | `lua test/run-tests.lua --bench` |
| `--shard <name>` | Run only tests in directories matching the shard name | `lua test/run-tests.lua --shard parser` |
| `--changed` | Run only tests for directories affected by recent git changes | `lua test/run-tests.lua --changed` |

**Benchmark Behavior:**
- Benchmark failures are **informational only** — they track parser accuracy over time
- Benchmarks with failing tests do NOT block CI or return non-zero exit codes
- The summary shows benchmark pass rate as a percentage (e.g., "84% (169/200)")
- Regular test failures still block CI as expected

### `--changed` Flag: Incremental Testing

The `--changed` flag enables fast iteration by running only tests relevant to files you've modified. It uses `git diff` to detect staged and unstaged changes, then maps source files to test directories.

**How it works:**
- Runs `git diff --name-only HEAD` and `git diff --name-only` to detect changes
- Maps changed source files to relevant test directories using a predefined mapping table
- If core engine files change, runs all tests (safe default)
- If documentation/plans/scripts change, skips tests (no code impact)
- If git tree is clean, runs all tests (safe default)

**Source-to-Test Mapping Table:**

| Changed Source Files | Test Directories Run |
|-----|------|
| `src/engine/verbs/**` | `verbs` |
| `src/engine/parser/**` | `parser` |
| `src/engine/fsm/**` | `fsm` |
| `src/engine/containment/**` | `inventory`, `search` |
| `src/engine/injuries/**` | `injuries`, `stress` |
| `src/engine/creatures/**` | `creatures`, `combat` |
| `src/engine/ui/**` | `ui` |
| `src/meta/objects/**` | `objects`, `sensory` |
| `src/meta/world/**` | `rooms` |
| `src/meta/injuries/**` | `injuries` |
| `src/engine/effects.lua` | `verbs`, `integration` |
| `src/engine/display.lua` | `ui` |
| **Core engine changes:** `src/engine/registry/**`, `src/engine/loader/**`, `src/engine/loop/**`, `src/engine/mutation/**`, `src/main.lua` | **ALL TESTS** (conservative) |
| `test/**` files | Test directory matching the changed test file |
| Documentation, plans, scripts | **SKIPPED** (no code impact) |

**Edge Cases:**

- **Clean working tree:** If `git diff` returns no changes, all tests run (safe default)
- **Unknown source file:** If a source file doesn't match any mapping, all tests run (conservative)
- **Combined with `--shard`:** The `--shard` filter applies AFTER the `--changed` filter, further narrowing the test set
  ```bash
  lua test/run-tests.lua --changed --shard parser
  # Runs parser tests ONLY IF parser-related files changed; otherwise runs nothing
  ```

**Example: Fast iteration on verb handlers**
```bash
# After editing src/engine/verbs/combat.lua:
lua test/run-tests.lua --changed
# Only runs: test/verbs/**

# Add benchmarks:
lua test/run-tests.lua --changed --bench
```

### Available Shards

Shards allow you to partition the test suite for parallel CI execution. Each shard is a named group of test directories.

| Shard Name | Directories | Approx. Files | Purpose |
|-----------|-------------|---|---------|
| `parser` | test/parser/, test/parser/pipeline/ | ~30 | Input preprocessing, semantic matching, context, GOAP planning, fuzzy resolution |
| `verbs` | test/verbs/ | ~62 | Verb handlers: combat, wine, wear, poison, crafting, butchery, and more |
| `creatures` | test/creatures/, test/combat/ | ~46 | Creature AI, combat mechanics, death, loot tables |
| `rooms` | test/rooms/, test/integration/ | ~24 | Room definitions, multi-command scenarios, world state |
| `search` | test/search/, test/inventory/, test/nightstand/ | ~28 | Object discovery, containment, inventory management, spatial traversal |
| `other` | All remaining directories | ~57 | UI, FSM, sensory, objects, wearables, armor, food, crafting, stress, loot, engine subsystems |

**Example: Run only parser tests**
```bash
lua test/run-tests.lua --shard parser
```

**Example: Run all tests except parser**
```bash
lua test/run-tests.lua --shard other
```

**Example: Run parser tests with benchmarks**
```bash
lua test/run-tests.lua --bench --shard parser
```

---

## Parallel Runner (`test/run-tests-parallel.ps1`)

The parallel runner executes test files concurrently using multiple workers. **Requires PowerShell 7+** (use `pwsh` instead of `powershell`).

**Usage:**
```powershell
./test/run-tests-parallel.ps1 [-Workers N] [-Bench] [-Shard <name>]
```

**Must be run from repository root.**

### Flags

| Flag | Type | Default | Description | Example |
|------|------|---------|-------------|---------|
| `-Workers` | integer | 8 | Number of parallel worker threads | `./test/run-tests-parallel.ps1 -Workers 4` |
| `-Bench` | switch | off | Include bench-* benchmark files | `./test/run-tests-parallel.ps1 -Bench` |
| `-Shard` | string | (all) | Run only tests in directories matching shard name | `./test/run-tests-parallel.ps1 -Shard verbs` |

### Output Format

The parallel runner displays results per test file with elapsed time:

```
========================================
  MMO Test Suite (Parallel — 8 workers)
========================================

Found 260 test file(s)

  ✓ parser/test-preprocess.lua (142ms)
  ✓ parser/test-context.lua (89ms)
  ✓ verbs/test-combat.lua (312ms)
  ✗ search/test-inventory.lua (156ms)
  ...

========================================
  Failures:
========================================

>> search/test-inventory.lua:
   [full captured output here]

========================================
  RESULT: 259 passed, 1 failed (14.2s wall time, 8 workers)
========================================
```

**Exit code:** 0 on success, 1 if any test fails.

### Practical Examples

**Run all tests with 4 workers (fast iteration)**
```powershell
./test/run-tests-parallel.ps1 -Workers 4
```

**Run parser tests in parallel**
```powershell
./test/run-tests-parallel.ps1 -Shard parser
```

**Run all tests with benchmarks using 6 workers**
```powershell
./test/run-tests-parallel.ps1 -Workers 6 -Bench
```

**Run creatures shard (creatures + combat) with default 8 workers**
```powershell
./test/run-tests-parallel.ps1 -Shard creatures
```

---

## Parallel Runner (`test/run-tests-parallel.sh`) — Unix/macOS/CI

The Unix parallel runner executes test files concurrently using `xargs` and background jobs. **Requires bash and lua on PATH.** Works on Linux, macOS, and Windows Subsystem for Linux (WSL).

**Usage:**
```bash
./test/run-tests-parallel.sh [-w|--workers N] [--bench] [--shard <name>]
```

**Must be run from repository root.** Make executable first: `chmod +x test/run-tests-parallel.sh`

### Flags

| Flag | Type | Default | Description | Example |
|------|------|---------|-------------|---------|
| `-w`, `--workers` | integer | 8 | Number of parallel worker processes | `./test/run-tests-parallel.sh -w 4` |
| `--bench` | switch | off | Include bench-* benchmark files | `./test/run-tests-parallel.sh --bench` |
| `--shard` | string | (all) | Run only tests in directories matching shard name | `./test/run-tests-parallel.sh --shard parser` |

### Output Format

The Unix parallel runner displays results per test file with elapsed time:

```
========================================
  MMO Test Suite (Parallel — 8 workers, Unix)
========================================

Found 260 test file(s)

  ✓ parser/test-preprocess.lua (142ms)
  ✓ parser/test-context.lua (89ms)
  ✓ verbs/test-combat.lua (312ms)
  ✗ search/test-inventory.lua (156ms)
  ...

========================================
  Failures:
========================================

>> search/test-inventory.lua:
   [full captured output here]

========================================
  RESULT: 259 passed, 1 failed (14.2s wall time, 8 workers)
========================================
```

**Exit code:** 0 on success, 1 if any test fails.

### Practical Examples

**Run all tests with 4 workers (fast iteration)**
```bash
./test/run-tests-parallel.sh -w 4
```

**Run parser tests with default 8 workers**
```bash
./test/run-tests-parallel.sh --shard parser
```

**Run all tests with benchmarks using 6 workers**
```bash
./test/run-tests-parallel.sh -w 6 --bench
```

**Run creatures shard (creatures + combat) with default 8 workers**
```bash
./test/run-tests-parallel.sh --shard creatures
```

---

## CI Behavior

### Matrix Sharding

The CI pipeline (`.github/workflows/squad-ci.yml`) runs all 6 named shards in parallel using the serial runner, achieving ~30 second total wall time:

```yaml
matrix:
  shard: [parser, verbs, creatures, rooms, search, other]
```

Each shard runs on a separate GitHub Actions runner:
```bash
lua test/run-tests.lua --bench --shard <shard_name>
```

Benchmarks are **always enabled** in CI (`--bench` flag).

### Auto-Issue Filing

When a shard fails:
1. A GitHub issue is automatically created (labeled `bug`, `ci-failure`, `squad:nelson`)
2. The issue title includes the shard name and commit SHA
3. The issue body contains the workflow run URL and failure details
4. Duplicate detection prevents creating multiple issues for the same failure

When all shards pass again:
1. All open `ci-failure` issues are automatically closed
2. A comment is added to each closed issue with the commit SHA

**Example auto-filed issue:**
```
CI Test Failure: parser shard on dev (a1b2c3d)

## Automated CI Failure Report

**Branch:** `dev`
**Commit:** a1b2c3d...
**Shard:** `parser`
**Run:** https://github.com/owner/repo/actions/runs/12345

### Next Steps
1. Check the workflow logs
2. Identify the failing test(s) in the `parser` shard
3. Fix and push — this issue auto-closes when CI passes
```

---

## Quick Reference: Common Workflows

### Fast local check after editing code

**Scenario:** You edited `src/engine/verbs/combat.lua` and want to run only the affected tests.

```bash
lua test/run-tests.lua --changed
# Runs: test/verbs/ only
# Time: ~5s (depends on shard size)
```

**Scenario:** You edited a parser module and want to verify without benchmarks.

```bash
lua test/run-tests.lua --changed
# Runs: test/parser/ and test/parser/pipeline/
# Time: ~15s
```

**Scenario:** You edited a core engine module (registry, loader, etc.) — all tests must pass.

```bash
lua test/run-tests.lua --changed
# Runs: ALL tests (detected core change)
# Time: ~90s
```

### Full local run (baseline verification)

**Windows (PowerShell 7):**
```powershell
./test/run-tests-parallel.ps1 -Workers 8
# All tests, 8 parallel workers
# Time: ~15s
```

**Unix/macOS/WSL:**
```bash
./test/run-tests-parallel.sh -w 8
# All tests, 8 parallel workers
# Time: ~15s
```

**Serial baseline (all systems):**
```bash
lua test/run-tests.lua
# All tests, sequential, no benchmarks
# Time: ~90s
```

### Run a specific area

**Parser tests only (serial):**
```bash
lua test/run-tests.lua --shard parser
# Time: ~15s
```

**Combat tests only (parallel):**
```powershell
./test/run-tests-parallel.ps1 -Shard creatures
# Includes: test/creatures/, test/combat/
# Time: ~8s
```

**Parser + benchmarks (CI-style, serial):**
```bash
lua test/run-tests.lua --bench --shard parser
# Time: ~30s
```

### Include benchmarks

**Local machine (skip benchmarks by default):**
```bash
lua test/run-tests.lua
# Skips: bench-*.lua files
# Time: ~90s
```

**Include benchmarks for performance measurement:**
```bash
lua test/run-tests.lua --bench
# Includes: bench-*.lua files
# Time: ~156s
```

**CI-style run (always includes benchmarks):**
```bash
lua test/run-tests.lua --bench --shard parser
# Time: ~30s for parser shard
```

---

## Performance Targets

| Scenario | Target | Notes |
|----------|--------|-------|
| Serial (all tests, no bench) | ~90s | Baseline with `lua test/run-tests.lua` |
| Serial (all tests with bench) | ~156s | Includes benchmark files |
| Serial (single shard) | ~15–30s | Varies by shard size |
| Serial (incremental, `--changed`) | <5s–15s | Depends on scope of changes; fast for localized edits |
| Parallel (all tests, 8 workers, Windows) | ~15s | Uses PowerShell 7 `ForEach-Object -Parallel` |
| Parallel (all tests, 8 workers, Unix) | ~15s | Uses xargs-based parallelism |
| Parallel (all tests with bench, 8 workers) | ~30s | Includes benchmarks |
| CI (6 shards in parallel) | ~30s | All shards + benchmarks, GitHub Actions matrix |

---

## Troubleshooting

**"PowerShell 7+ is required" error**
- Use `pwsh` instead of `powershell`
- Install PowerShell 7+ from [microsoft/PowerShell](https://github.com/microsoft/PowerShell)
- Or use the Unix runner instead: `./test/run-tests-parallel.sh`

**"bash: ./test/run-tests-parallel.sh: No such file or directory" on Unix**
- Make the script executable: `chmod +x test/run-tests-parallel.sh`
- Verify the script exists: `ls -la test/run-tests-parallel.sh`

**"No test directories match shard" error**
- Check spelling of shard name
- Valid shards: `parser`, `verbs`, `creatures`, `rooms`, `search`, `other`

**`--changed` flag runs all tests (not filtered)**
- Check git status: `git status`
- Check what files changed: `git diff --name-only HEAD` and `git diff --name-only`
- If no changes detected, all tests run (safe default)
- Core engine changes (registry, loader, loop, mutation, main.lua) always trigger all tests

**Test file hangs or doesn't complete**
- Add `--headless` flag to individual test files (for CI automation)
- Ensure TUI (terminal UI) is not blocking on prompts

**Verify shard coverage (all tests accounted for)**
```powershell
# Run each shard, verify no test files are orphaned
foreach ($shard in @("parser", "verbs", "creatures", "rooms", "search", "other")) {
    lua test/run-tests.lua --shard $shard
}
```

**Parallel runner shows "xargs: unknown option" on Unix**
- Ensure you have GNU or BSD `xargs` available
- Verify bash is in use: `echo $SHELL` should show bash or compatible shell

**Unix runner hangs or produces interleaved output**
- Check if lua process is available: `which lua` and `lua --version`
- Try reducing worker count: `./test/run-tests-parallel.sh -w 2`
- Verify no test files are hanging (test with `-w 1` for serial execution)

---

## Related Documentation

- [Testing Framework](./framework.md) — Test structure and patterns
- [Testing Design](../design/) — Test strategy and philosophy
- [Architecture: Effects Pipeline](../architecture/engine/effects-pipeline.md) — How tests validate engine behavior
