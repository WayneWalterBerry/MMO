# Test Runner Flags

This document describes the command-line flags available for the MMO test runners: the serial runner (`test/run-tests.lua`) and the parallel runner (`test/run-tests-parallel.ps1`).

---

## Serial Runner (`test/run-tests.lua`)

The serial runner discovers and executes all test files sequentially from the repository root.

**Usage:**
```bash
lua test/run-tests.lua [--bench] [--shard <name>]
```

**Must be run from repository root.**

### Flags

| Flag | Description | Example |
|------|-------------|---------|
| (no flags) | Run all test-* files, skip benchmarks | `lua test/run-tests.lua` |
| `--bench` | Include bench-* benchmark files in addition to test files | `lua test/run-tests.lua --bench` |
| `--shard <name>` | Run only tests in directories matching the shard name | `lua test/run-tests.lua --shard parser` |

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

## CI Behavior

### Matrix Sharding

The CI pipeline (`.github/workflows/squad-ci.yml`) runs all 6 named shards in parallel for ~30 second total wall time:

```yaml
matrix:
  shard: [parser, verbs, creatures, rooms, search, other]
```

Each shard runs:
```bash
lua test/run-tests.lua --bench --shard <shard_name>
```

Benchmarks are **always enabled** in CI (`--bench` flag).

### Auto-Issue Filing

When a shard fails:
1. A GitHub issue is automatically created (labeled `bug`, `ci-failure`, `squad:nelson`)
2. The issue title includes the shard name and commit SHA
3. The issue body contains the workflow run URL and failure details

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

## Performance Targets

| Scenario | Target | Notes |
|----------|--------|-------|
| Serial (all tests, no bench) | ~90s | Baseline with `lua test/run-tests.lua` |
| Serial (all tests with bench) | ~156s | Includes benchmark files |
| Serial (single shard) | ~15–30s | Varies by shard size |
| Parallel (all tests, 8 workers) | ~15s | Excludes benchmarks |
| Parallel (all tests with bench, 8 workers) | ~30s | Includes benchmarks |
| CI (6 shards in parallel) | ~30s | All shards + benchmarks, parallel matrix |

---

## Troubleshooting

**"PowerShell 7+ is required" error**
- Use `pwsh` instead of `powershell`
- Install PowerShell 7+ from [microsoft/PowerShell](https://github.com/microsoft/PowerShell)

**"No test directories match shard" error**
- Check spelling of shard name
- Valid shards: `parser`, `verbs`, `creatures`, `rooms`, `search`, `other`

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

---

## Related Documentation

- [Testing Framework](./framework.md) — Test structure and patterns
- [Testing Design](../design/) — Test strategy and philosophy
- [Architecture: Effects Pipeline](../architecture/engine/effects-pipeline.md) — How tests validate engine behavior
