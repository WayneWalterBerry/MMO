# Test Speed — Implementation Plan (Phase 1)

**Author:** Bart (Architect)  
**Date:** 2026-08-22  
**Status:** PLAN ONLY — Not yet executed  
**Requested By:** Wayne "Effe" Berry  
**Governs:** Test execution speed across 3 design phases (Benchmark Gating → CI Excellence → Developer Experience)  
**Source Plan:** `plans/testing/test-speed-design.md`

---

## Section 1: Executive Summary

The MMO test suite runs 260 test files serially in ~156 seconds. A single benchmark (`test-inverted-index.lua`) consumes 61.6 seconds — 40% of total runtime. Tests are already process-isolated via `io.popen`, making parallelism safe with zero test modifications.

This plan implements design phases 1–3 in 5 waves with 4 gates:

- **Phase 1 (Quick Wins)** → WAVE-1 through WAVE-2: Gate benchmarks behind `--bench` flag (-66s instant win), build PowerShell parallel runner (6× speedup), configure basic CI
- **Phase 2 (CI Excellence)** → WAVE-3: Auto-file/close GitHub issues on failure, matrix sharding across 6 runners
- **Phase 3 (Developer Experience)** → WAVE-4: Git-diff-based `--changed` flag, cross-platform Unix parallel runner

**Phase 4 (File Splitting)** from the design plan is deferred — file size doesn't correlate with runtime, and splitting is a maintainability concern handled separately by D-ENGINE-REFACTORING-WAVE2.

**Target outcomes:**
- Developer machine: **156s → ~15s** (benchmark gating + 8-worker parallelism)
- CI pipeline: **unconfigured → ~30s** (matrix sharding across 6 runners)
- Incremental developer: **~15s → <5s** (only run tests affected by changes)
- Automated regression tracking via CI auto-issue filing

**Why this order:** Benchmark gating is the single highest-ROI change (2h work, -66s). Parallel runner is next (2h, 6× on remaining tests). CI enables team-wide protection. Incremental testing is the endgame polish.

**Key architectural decisions:**
1. **Separate parallel runner** — `test/run-tests-parallel.ps1` (new file) keeps `run-tests.lua` as the serial fallback. No risk to existing workflow.
2. **`run-tests.lua` stays pure Lua** — `--bench`, `--shard`, and `--changed` are additive flags. Zero external dependencies.
3. **PowerShell 7 for Windows parallelism** — `ForEach-Object -Parallel` is the simplest path. Unix gets a shell script.
4. **CI sharding by directory** — maps to existing test directory structure. `--shard parser` runs only `test/parser/` files.
5. **Benchmarks via naming convention** — `bench-*.lua` prefix, not metadata or config files. Simple, grep-able, discoverable.

**Estimated scope:** 5 waves (WAVE-0 through WAVE-4), 4 gates, ~300 lines new code + ~50 lines test runner modifications  
**Total new files:** 3 (`run-tests-parallel.ps1`, `run-tests-parallel.sh`, docs)  
**Total modified files:** 2 (`run-tests.lua`, `squad-ci.yml`) + 2–3 renamed test files

---

## Section 2: Quick Reference

| Wave | Name | Parallel Tracks | Gate | Key Deliverable |
|------|------|-----------------|------|-----------------|
| **WAVE-0** | Pre-Flight (Baseline) | 1 track | — | Timing baseline recorded, bench candidates verified |
| **WAVE-1** | Benchmark Gating | 2 tracks | GATE-1 | bench-* renames, `--bench` flag, dev runtime <100s |
| **WAVE-2** | Parallel Runner + Basic CI | 3 tracks | GATE-2 | PowerShell parallel runner, CI configured, `--shard` flag |
| **WAVE-3** | CI Auto-Issues + Matrix | 2 tracks | GATE-3 | Auto-file/close issues, 6-shard matrix, CI <40s |
| **WAVE-4** | Incremental + Cross-Platform | 3 tracks | GATE-4 | `--changed` flag, Unix parallel runner, full docs |

---

## Section 3: Dependency Graph

```
WAVE-0: Pre-Flight (Baseline)
└── [Nelson]   Timing baseline + bench candidate audit ─────────┐
        │                                                       │
        ▼  ── (no gate — baseline data only, verified by output review) ──
        │
WAVE-1: Benchmark Gating
├── [Nelson]   Rename bench files + --bench flag ───────────────┐
│              (run-tests.lua: sole editor this wave)           │ (parallel, no
└── [Marge]    Verify test count pre/post rename ───────────────┘  file overlap)
        │
        ▼  ── GATE-1 (run-tests.lua without --bench < 100s; --bench includes all) ──
        │
WAVE-2: Parallel Runner + Basic CI
├── [Bart]     test/run-tests-parallel.ps1 ─────────────────────┐
│              (NEW file, PowerShell 7 parallel runner)         │
├── [Gil]      .github/workflows/squad-ci.yml ──────────────────┤ (parallel, no
│              (Lua install, serial test run)                    │  file overlap)
└── [Nelson]   run-tests.lua: --shard flag ─────────────────────┘
               (sole run-tests.lua editor this wave)
        │
        ▼  ── GATE-2 (parallel runner <25s; CI workflow green; --shard filters correctly) ──
        │
        │  ═══ PHASE 1 (QUICK WINS) SHIPS HERE ═══
        │
WAVE-3: CI Auto-Issues + Matrix Sharding
├── [Gil]      squad-ci.yml: auto-file/close + matrix ──────────┐
│              (sole CI editor this wave)                        │ (parallel, no
└── [Brockman] docs/testing/test-runner-flags.md ───────────────┘  file overlap)
        │
        ▼  ── GATE-3 (matrix CI runs 6 shards; auto-issue fires on forced failure) ──
        │
        │  ═══ PHASE 2 (CI EXCELLENCE) SHIPS HERE ═══
        │
WAVE-4: Incremental Testing + Cross-Platform
├── [Nelson]   run-tests.lua: --changed flag ───────────────────┐
│              (sole run-tests.lua editor this wave)            │
├── [Bart]     test/run-tests-parallel.sh ──────────────────────┤ (parallel, no
│              (NEW file, Unix parallel runner)                  │  file overlap)
└── [Brockman] Update docs with all flags + parallel usage ─────┘
        │
        ▼  ── GATE-4 (--changed filters correctly; Unix runner <25s; docs complete) ──
        │
        │  ═══ PHASE 3 (DEVELOPER EXPERIENCE) SHIPS HERE ═══
```

**Key constraint:** Only ONE agent edits `run-tests.lua` per wave. Nelson is the sole editor in WAVE-1, WAVE-2, and WAVE-4.

---

## Section 4: Implementation Waves

### WAVE-0: Pre-Flight (Baseline)

**Goal:** Record timing baseline for all test files. Verify that benchmark candidates are genuinely benchmarks (not correctness tests).

| Task | Agent | Files Created/Modified | Scope |
|------|-------|------------------------|-------|
| Timing baseline | Nelson | **RUN** full suite with per-file timing | Small |
| Bench candidate audit | Nelson | **REVIEW** 3 files for correctness vs benchmark content | Small |

**Nelson instructions — timing baseline:**

Run the full test suite with per-file timing and record results. Use a wrapper that times each `lua` invocation:

```powershell
# Record per-file timing
$results = @()
Get-ChildItem -Recurse test\ -Filter "test-*.lua" | ForEach-Object {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $output = lua $_.FullName 2>&1
    $sw.Stop()
    $results += [PSCustomObject]@{
        File = $_.FullName.Replace((Get-Location).Path + "\", "")
        TimeMs = $sw.ElapsedMilliseconds
        ExitCode = $LASTEXITCODE
    }
}
$results | Sort-Object TimeMs -Descending | Format-Table -AutoSize
$total = ($results | Measure-Object TimeMs -Sum).Sum
Write-Host "Total: ${total}ms across $($results.Count) files"
```

Record: total file count, total time, top 10 slowest files with times. This becomes the baseline for gate comparisons.

**Nelson instructions — bench candidate audit:**

Review these 3 files and confirm they are benchmarks, not correctness tests:

| File | Expected Finding |
|------|-----------------|
| `test/parser/test-inverted-index.lua` | Benchmark: 100 iterations of embedding scan, measures performance not correctness |
| `test/parser/test-tier2-benchmark.lua` | Benchmark: explicitly named "benchmark", measures tier-2 matching speed |
| `test/parser/test-bm25-deep.lua` | **Audit needed**: "bm25-deep" could be correctness testing of BM25 scoring. Check if it asserts on score values (correctness) or just measures speed (benchmark). If correctness → do NOT rename. |

For each file: read the source, check whether assertions test _correctness_ (expected values, pass/fail on output) or _performance_ (timing, iteration counts, throughput). Only pure performance tests get the `bench-*` rename.

**Verification:** Baseline data recorded. Bench candidates classified as benchmark or correctness.

---

### WAVE-1: Benchmark Gating

**Goal:** Rename benchmark files to `bench-*` prefix. Add `--bench` flag to `run-tests.lua` so benchmarks are skipped by default and included on demand. Developer runtime drops from ~156s to ~90s.

**Depends on:** WAVE-0 complete (baseline recorded, candidates verified)

| Task | Agent | Files Modified/Created | Scope |
|------|-------|------------------------|-------|
| Rename benchmark files | Nelson | **RENAME** 2–3 files from `test-*` to `bench-*` | Small |
| Add `--bench` flag to runner | Nelson | **MODIFY** `test/run-tests.lua` | Small |
| Verify file counts | Marge | **RUN** count validation | Tiny |

**File ownership (no overlap):**
- Nelson: `test/run-tests.lua`, benchmark file renames
- Marge: verification only (no file edits)

**Nelson instructions — rename benchmark files:**

Based on WAVE-0 audit results, rename confirmed benchmarks. Minimum set:

```
test/parser/test-inverted-index.lua  →  test/parser/bench-inverted-index.lua
test/parser/test-tier2-benchmark.lua →  test/parser/bench-tier2-benchmark.lua
```

If WAVE-0 audit confirms `test-bm25-deep.lua` is a pure benchmark (no correctness assertions), also rename:
```
test/parser/test-bm25-deep.lua      →  test/parser/bench-bm25-deep.lua
```

Use `git mv` for renames to preserve history:
```powershell
git mv test/parser/test-inverted-index.lua test/parser/bench-inverted-index.lua
git mv test/parser/test-tier2-benchmark.lua test/parser/bench-tier2-benchmark.lua
```

**Nelson instructions — `--bench` flag:**

Add `--bench` CLI flag to `test/run-tests.lua`. Changes are backward-compatible and small (~20 lines).

1. **Parse `--bench` from command line args:**

```lua
-- After the existing SEP definition (line 8), add:
local include_bench = false
for _, arg in ipairs(arg or {}) do
    if arg == "--bench" then
        include_bench = true
    end
end
```

2. **Modify the file discovery loop to also discover `bench-*` files when `--bench` is set:**

In the directory scanning loop (lines 54–76), after the existing `test-*` file discovery, add a second pass:

```lua
-- After the existing test-*.lua discovery block, add:
if include_bench then
    local bench_cmd
    if is_windows then
        bench_cmd = 'dir /b "' .. test_dir .. '\\bench-*.lua" 2>nul'
    else
        bench_cmd = 'ls "' .. test_dir .. '"/bench-*.lua 2>/dev/null'
    end
    local bench_handle = io.popen(bench_cmd)
    if bench_handle then
        for line in bench_handle:lines() do
            local fname = line:match("([^/\\]+)$") or line
            if fname:match("^bench%-") and fname:match("%.lua$") then
                local subdir = test_dir:match("([^/\\]+)$")
                test_entries[#test_entries + 1] = {
                    filepath = test_dir .. SEP .. fname,
                    display = subdir .. "/" .. fname,
                }
            end
        end
        bench_handle:close()
    end
end
```

3. **Update the header output to show benchmark status:**

```lua
print("========================================")
print("  MMO Test Suite")
if include_bench then
    print("  (including benchmarks)")
end
print("========================================")
```

**Marge instructions — verify file counts:**

After Nelson completes:
1. Run `lua test/run-tests.lua` (no flags) — count should be ~257–258 (total minus renamed benchmarks)
2. Run `lua test/run-tests.lua --bench` — count should be ~260 (full original count)
3. Verify no test name collisions (no `test-inverted-index.lua` AND `bench-inverted-index.lua`)

---

### GATE-1: Benchmark Gating Verified

| Criterion | Pass Condition | Verifier |
|-----------|---------------|----------|
| Benchmark skip | `lua test/run-tests.lua` does NOT run any `bench-*` files | Marge |
| Benchmark include | `lua test/run-tests.lua --bench` discovers and runs `bench-*` files | Marge |
| Runtime reduction | Serial runtime without benchmarks < 100 seconds | Marge |
| Zero regressions | All `test-*` files still pass (exit code 0) | Nelson |
| File count | Without `--bench`: ≥255 files. With `--bench`: ≥258 files | Marge |
| History preserved | `git log --follow bench-inverted-index.lua` shows rename from test-* | Nelson |

**Verification commands:**
```powershell
# 1. Run without benchmarks
lua test/run-tests.lua

# 2. Run with benchmarks
lua test/run-tests.lua --bench

# 3. Verify bench files not discovered without flag
lua test/run-tests.lua 2>&1 | Select-String "bench-"
# Expected: no output (bench files not run)

# 4. Verify bench files discovered with flag
lua test/run-tests.lua --bench 2>&1 | Select-String "bench-"
# Expected: bench-inverted-index.lua, bench-tier2-benchmark.lua appear
```

**On pass:** Commit and push.
```
GATE-1: Benchmark gating — bench-* files skip by default

- Renamed 2-3 benchmark files to bench-* prefix
- Added --bench flag to run-tests.lua
- Developer runtime: ~156s → ~90s (benchmarks excluded)
- Tests: 0 regressions, file counts verified

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

---

### WAVE-2: Parallel Runner + Basic CI

**Goal:** Build the PowerShell parallel runner for 6× speedup on dev machines. Configure basic CI with Lua. Add `--shard` flag for CI matrix support.

**Depends on:** GATE-1 pass

| Task | Agent | Files Modified/Created | Scope |
|------|-------|------------------------|-------|
| PowerShell parallel runner | Bart | **CREATE** `test/run-tests-parallel.ps1` | Medium |
| Basic CI configuration | Gil | **MODIFY** `.github/workflows/squad-ci.yml` | Small |
| `--shard` flag in runner | Nelson | **MODIFY** `test/run-tests.lua` | Small |

**File ownership (no overlap):**
- Bart: `test/run-tests-parallel.ps1` (new file)
- Gil: `.github/workflows/squad-ci.yml`
- Nelson: `test/run-tests.lua` (sole editor)

**Bart instructions — PowerShell parallel runner:**

Create `test/run-tests-parallel.ps1` — a standalone parallel test runner that launches up to N `lua` processes simultaneously. Requirements:

1. **Discover test files** the same way `run-tests.lua` does — scan hardcoded directories for `test-*.lua` files. Skip `bench-*` files by default; include them with `-Bench` switch.

2. **Parallel execution** using `ForEach-Object -Parallel` (requires PowerShell 7+):

```powershell
#!/usr/bin/env pwsh
# test/run-tests-parallel.ps1
# Parallel test runner for MMO test suite.
# Requires PowerShell 7+ for ForEach-Object -Parallel.
#
# Usage:
#   ./test/run-tests-parallel.ps1              # Run test-* files, 8 workers
#   ./test/run-tests-parallel.ps1 -Workers 4   # Run with 4 workers
#   ./test/run-tests-parallel.ps1 -Bench        # Include bench-* files
#   ./test/run-tests-parallel.ps1 -Shard parser # Run only test/parser/ files

param(
    [int]$Workers = 8,
    [switch]$Bench,
    [string]$Shard = ""
)

$ErrorActionPreference = "Stop"

# Test directories (mirrors run-tests.lua)
$testDirs = @(
    "test\parser",
    "test\parser\pipeline",
    "test\inventory",
    "test\injuries",
    "test\verbs",
    "test\search",
    "test\nightstand",
    "test\integration",
    "test\ui",
    "test\rooms",
    "test\objects",
    "test\armor",
    "test\wearables",
    "test\sensory",
    "test\fsm",
    "test\creatures",
    "test\combat",
    "test\food",
    "test\butchery",
    "test\loot",
    "test\stress",
    "test\crafting",
    "test\engine"
)

# Shard filter
if ($Shard) {
    $testDirs = $testDirs | Where-Object { $_ -match "test\\$Shard" }
    if ($testDirs.Count -eq 0) {
        Write-Error "No test directories match shard: $Shard"
        exit 1
    }
}
```

3. **File discovery** — collect all `test-*.lua` (and optionally `bench-*.lua`) files from the filtered directories.

4. **Parallel execution with output buffering** — each worker captures stdout/stderr into a buffer. On completion, the worker emits its result. No interleaved output.

```powershell
$results = $testFiles | ForEach-Object -Parallel {
    $file = $_
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $output = & lua $file.FullName 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    $sw.Stop()
    [PSCustomObject]@{
        File     = $file.RelativePath
        TimeMs   = $sw.ElapsedMilliseconds
        ExitCode = $exitCode
        Output   = $output
        Passed   = ($exitCode -eq 0)
    }
} -ThrottleLimit $Workers
```

5. **Results summary** — after all workers finish:
   - Print PASS/FAIL per file (one line each, with timing)
   - Print failed file output in full (for debugging)
   - Print total time, pass count, fail count
   - Exit with code 1 if any file failed, 0 if all passed

6. **Output format:**

```
========================================
  MMO Test Suite (Parallel — 8 workers)
========================================

Found 257 test file(s)

  ✓ parser/test-preprocess.lua (142ms)
  ✓ parser/test-context.lua (89ms)
  ✗ verbs/test-combat.lua (312ms)
  ...

========================================
  Failures:
========================================

>> verbs/test-combat.lua:
   [full captured output here]

========================================
  RESULT: 256 passed, 1 failed (14.2s wall time, 8 workers)
========================================
```

7. **PowerShell 7 guard** — check `$PSVersionTable.PSVersion.Major -ge 7` at startup. If not, print error and suggest `pwsh` instead of `powershell`.

**Gil instructions — basic CI configuration:**

Replace the placeholder `squad-ci.yml` with a working Lua CI pipeline:

```yaml
name: Squad CI

on:
  pull_request:
    branches: [dev, preview, main, insider]
    types: [opened, synchronize, reopened]
  push:
    branches: [dev, insider]

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Lua
        run: sudo apt-get update && sudo apt-get install -y lua5.4

      - name: Run tests
        run: lua test/run-tests.lua --bench
```

Key decisions:
- Use `lua5.4` from apt (matches local dev environment)
- Run with `--bench` in CI — benchmarks always execute in CI, just not on dev machines
- Keep it simple for now — matrix sharding comes in WAVE-3
- `permissions: contents: read` is sufficient for basic test runs

**Nelson instructions — `--shard` flag:**

Add `--shard <name>` CLI flag to `test/run-tests.lua` that filters test directories by prefix. This enables CI matrix sharding.

1. **Parse `--shard` from command line args:**

```lua
local shard_filter = nil
for i, a in ipairs(arg or {}) do
    if a == "--bench" then
        include_bench = true
    elseif a == "--shard" and arg[i + 1] then
        shard_filter = arg[i + 1]
    end
end
```

2. **Filter `test_dirs` by shard name:**

After the `test_dirs` table definition, add:

```lua
if shard_filter then
    local filtered = {}
    for _, dir in ipairs(test_dirs) do
        -- Match shard name against directory path
        -- e.g., --shard parser matches test/parser and test/parser/pipeline
        local dir_name = dir:match("([^/\\]+)$")
        local parent_name = dir:match("([^/\\]+)[/\\][^/\\]+$")
        if dir_name == shard_filter or parent_name == shard_filter then
            filtered[#filtered + 1] = dir
        end
    end
    if #filtered == 0 then
        print("No test directories match shard: " .. shard_filter)
        os.exit(1)
    end
    test_dirs = filtered
end
```

3. **Shard mapping for CI matrix:**

The shard names map to directory groupings:

| Shard Name | Directories |
|-----------|-------------|
| `parser` | parser/, parser/pipeline/ |
| `verbs` | verbs/ |
| `creatures` | creatures/, combat/ |
| `rooms` | rooms/, integration/ |
| `search` | search/, inventory/, nightstand/ |
| `other` | all remaining: injuries/, ui/, objects/, armor/, wearables/, sensory/, fsm/, food/, butchery/, loot/, stress/, crafting/, engine/ |

The `other` shard is a catch-all. Add special handling:

```lua
if shard_filter == "other" then
    local known_shards = {
        parser = true, verbs = true, creatures = true,
        combat = true, rooms = true, integration = true,
        search = true, inventory = true, nightstand = true,
    }
    local filtered = {}
    for _, dir in ipairs(test_dirs) do
        local dir_name = dir:match("([^/\\]+)$")
        if not known_shards[dir_name] then
            filtered[#filtered + 1] = dir
        end
    end
    test_dirs = filtered
end
```

4. **Update header to show shard:**

```lua
if shard_filter then
    print("  (shard: " .. shard_filter .. ")")
end
```

---

### GATE-2: Parallel Runner + Basic CI Verified

| Criterion | Pass Condition | Verifier |
|-----------|---------------|----------|
| Parallel runner works | `./test/run-tests-parallel.ps1` completes with 0 failures | Marge |
| Parallel speedup | Wall-clock time < 25 seconds (without benchmarks) | Marge |
| Output buffered | No interleaved output between test files | Marge |
| CI workflow valid | `squad-ci.yml` passes YAML validation | Gil |
| CI green | Push to branch triggers CI; all tests pass | Gil |
| Shard flag works | `lua test/run-tests.lua --shard parser` runs only parser tests | Nelson |
| Shard coverage | All 6 shards combined cover all test files (no orphans) | Nelson |
| Zero regressions | Serial runner (`lua test/run-tests.lua`) still passes | Nelson |
| Backward compat | `lua test/run-tests.lua` with no flags behaves identically to pre-plan | Marge |

**Verification commands:**
```powershell
# 1. Parallel runner (target: <25s)
./test/run-tests-parallel.ps1

# 2. Parallel runner with benchmarks
./test/run-tests-parallel.ps1 -Bench

# 3. Serial runner still works
lua test/run-tests.lua

# 4. Shard filtering
lua test/run-tests.lua --shard parser
lua test/run-tests.lua --shard verbs
lua test/run-tests.lua --shard creatures
lua test/run-tests.lua --shard rooms
lua test/run-tests.lua --shard search
lua test/run-tests.lua --shard other

# 5. Verify shard coverage (sum of all shards = total)
# Run each shard, count files, sum should equal total without --bench
```

**On pass:** Commit and push.
```
GATE-2: Parallel runner + basic CI

- Created test/run-tests-parallel.ps1 (PowerShell 7, 8-worker parallel)
- Configured squad-ci.yml with Lua 5.4 + --bench
- Added --shard flag to run-tests.lua for CI matrix support
- Dev runtime: ~90s → ~15s (parallel), CI: functional
- Tests: 0 regressions

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

**═══ PHASE 1 (QUICK WINS) SHIPS HERE ═══**

---

### WAVE-3: CI Auto-Issues + Matrix Sharding

**Goal:** CI automatically files GitHub issues on test failures and closes them on success. Matrix strategy runs 6 shards in parallel for ~30s CI time.

**Depends on:** GATE-2 pass (CI functional, `--shard` flag exists)

| Task | Agent | Files Modified/Created | Scope |
|------|-------|------------------------|-------|
| CI matrix + auto-issue filing | Gil | **MODIFY** `.github/workflows/squad-ci.yml` | Medium |
| Test runner flags documentation | Brockman | **CREATE** `docs/testing/test-runner-flags.md` | Small |

**File ownership (no overlap):**
- Gil: `.github/workflows/squad-ci.yml` (sole editor)
- Brockman: `docs/testing/test-runner-flags.md` (new file)

**Gil instructions — matrix sharding + auto-issues:**

Expand `squad-ci.yml` to use matrix strategy with 6 shards plus auto-issue filing/closing:

```yaml
name: Squad CI

on:
  pull_request:
    branches: [dev, preview, main, insider]
    types: [opened, synchronize, reopened]
  push:
    branches: [dev, insider]

permissions:
  contents: read
  issues: write

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        shard: [parser, verbs, creatures, rooms, search, other]
    steps:
      - uses: actions/checkout@v4

      - name: Install Lua
        run: sudo apt-get update && sudo apt-get install -y lua5.4

      - name: Run tests (shard ${{ matrix.shard }})
        run: lua test/run-tests.lua --bench --shard ${{ matrix.shard }}

      - name: File issue on failure
        if: failure()
        uses: actions/github-script@v7
        with:
          script: |
            const { owner, repo } = context.repo;
            const run = context.runId;
            const sha = context.sha.substring(0, 7);
            const branch = context.ref.replace('refs/heads/', '');
            const shard = '${{ matrix.shard }}';

            // Check for existing open issue to avoid duplicates
            const existing = await github.rest.issues.listForRepo({
              owner, repo,
              labels: 'bug,ci-failure',
              state: 'open',
              per_page: 10
            });

            const dupes = existing.data.filter(i =>
              i.title.includes('CI Test Failure') && i.body.includes(shard));

            if (dupes.length === 0) {
              await github.rest.issues.create({
                owner, repo,
                title: `CI Test Failure: ${shard} shard on ${branch} (${sha})`,
                body: [
                  `## Automated CI Failure Report`,
                  ``,
                  `**Branch:** \`${branch}\``,
                  `**Commit:** ${context.sha}`,
                  `**Shard:** \`${shard}\``,
                  `**Run:** ${context.serverUrl}/${owner}/${repo}/actions/runs/${run}`,
                  ``,
                  `### Next Steps`,
                  `1. Check the [workflow logs](${context.serverUrl}/${owner}/${repo}/actions/runs/${run})`,
                  `2. Identify the failing test(s) in the \`${shard}\` shard`,
                  `3. Fix and push — this issue auto-closes when CI passes`,
                ].join('\n'),
                labels: ['bug', 'ci-failure', 'squad:nelson']
              });
            }

  close-issues:
    runs-on: ubuntu-latest
    needs: test
    if: success()
    permissions:
      issues: write
    steps:
      - name: Close CI failure issues on success
        uses: actions/github-script@v7
        with:
          script: |
            const { owner, repo } = context.repo;
            const issues = await github.rest.issues.listForRepo({
              owner, repo,
              labels: 'ci-failure',
              state: 'open'
            });
            for (const issue of issues.data) {
              await github.rest.issues.update({
                owner, repo,
                issue_number: issue.number,
                state: 'closed',
                state_reason: 'completed'
              });
              await github.rest.issues.createComment({
                owner, repo,
                issue_number: issue.number,
                body: `✅ CI passing again as of ${context.sha.substring(0, 7)}. Auto-closing.`
              });
            }
```

Key design decisions:
- **`fail-fast: false`** — all shards run to completion even if one fails. This gives full failure picture.
- **`permissions: issues: write`** — required for auto-filing. Add to workflow-level permissions.
- **Duplicate detection** — checks for existing open issues with same shard name before creating new ones.
- **Per-shard issues** — one issue per failing shard, not one mega-issue. Routes better.
- **Auto-close job** — runs only when ALL shards pass (`needs: test` + `if: success()`).
- **Labels** — `bug`, `ci-failure`, `squad:nelson` for automatic triage routing.
- **All shards run `--bench`** — benchmarks always execute in CI.

**Brockman instructions — test runner flags documentation:**

Create `docs/testing/test-runner-flags.md` documenting all test runner flags:

```markdown
# Test Runner Flags

## Serial Runner (`test/run-tests.lua`)

| Flag | Description | Example |
|------|-------------|---------|
| (no flags) | Run all test-* files, skip benchmarks | `lua test/run-tests.lua` |
| `--bench` | Include bench-* benchmark files | `lua test/run-tests.lua --bench` |
| `--shard <name>` | Run only tests in matching directories | `lua test/run-tests.lua --shard parser` |

### Available Shards

| Shard | Directories | Approx. Files |
|-------|-------------|---------------|
| `parser` | parser/, parser/pipeline/ | ~42 |
| `verbs` | verbs/ | ~61 |
| `creatures` | creatures/, combat/ | ~46 |
| `rooms` | rooms/, integration/ | ~24 |
| `search` | search/, inventory/, nightstand/ | ~26 |
| `other` | All remaining directories | ~61 |

## Parallel Runner (`test/run-tests-parallel.ps1`)

Requires PowerShell 7+.

| Flag | Description | Default | Example |
|------|-------------|---------|---------|
| `-Workers N` | Number of parallel workers | 8 | `./test/run-tests-parallel.ps1 -Workers 4` |
| `-Bench` | Include bench-* benchmark files | off | `./test/run-tests-parallel.ps1 -Bench` |
| `-Shard <name>` | Run only tests in matching directories | (all) | `./test/run-tests-parallel.ps1 -Shard parser` |

## CI Behavior

CI runs all shards in parallel with `--bench` enabled. On failure:
- A GitHub issue is filed automatically (labeled `ci-failure`, `squad:nelson`)
- When CI passes again, the issue is auto-closed
```

---

### GATE-3: CI Auto-Issues + Matrix Verified

| Criterion | Pass Condition | Verifier |
|-----------|---------------|----------|
| Matrix runs | All 6 shards execute in parallel in CI | Gil |
| CI time | Total CI wall time < 40 seconds (parallel shards) | Marge |
| Auto-file works | Force a test failure; verify issue is created with correct labels | Gil |
| Duplicate guard | Push same failure twice; verify only 1 issue created | Gil |
| Auto-close works | Fix the failure; verify issue is closed with comment | Gil |
| Labels correct | Auto-filed issues have `bug`, `ci-failure`, `squad:nelson` labels | Gil |
| Docs complete | `docs/testing/test-runner-flags.md` covers all flags | Brockman |

**Verification procedure (auto-issue testing):**

1. Create a temporary test file that always fails:
   ```lua
   -- test/parser/test-gate3-temp-fail.lua
   print("Intentional failure for GATE-3 verification")
   os.exit(1)
   ```
2. Push to a branch → verify CI fails → verify issue is created
3. Remove the failing test file → push → verify CI passes → verify issue is closed
4. Delete the temporary test file

**On pass:** Commit and push.
```
GATE-3: CI auto-issues + matrix sharding

- 6-shard matrix strategy (parser, verbs, creatures, rooms, search, other)
- Auto-file GitHub issues on failure with duplicate detection
- Auto-close issues when CI passes
- CI time: ~30s (6 parallel shards)
- Documentation: docs/testing/test-runner-flags.md

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

**═══ PHASE 2 (CI EXCELLENCE) SHIPS HERE ═══**

---

### WAVE-4: Incremental Testing + Cross-Platform

**Goal:** Add `--changed` flag for git-diff-based test filtering. Build Unix parallel runner for CI/Mac/Linux developers.

**Depends on:** GATE-3 pass

| Task | Agent | Files Modified/Created | Scope |
|------|-------|------------------------|-------|
| `--changed` flag | Nelson | **MODIFY** `test/run-tests.lua` | Medium |
| Unix parallel runner | Bart | **CREATE** `test/run-tests-parallel.sh` | Medium |
| Update documentation | Brockman | **MODIFY** `docs/testing/test-runner-flags.md` | Small |

**File ownership (no overlap):**
- Nelson: `test/run-tests.lua` (sole editor)
- Bart: `test/run-tests-parallel.sh` (new file)
- Brockman: `docs/testing/test-runner-flags.md`

**Nelson instructions — `--changed` flag:**

Add `--changed` CLI flag to `test/run-tests.lua` that uses `git diff` to determine which source files changed, then maps those to relevant test directories.

1. **Parse `--changed` from command line args:**

```lua
local changed_only = false
for i, a in ipairs(arg or {}) do
    if a == "--bench" then
        include_bench = true
    elseif a == "--shard" and arg[i + 1] then
        shard_filter = arg[i + 1]
    elseif a == "--changed" then
        changed_only = true
    end
end
```

2. **Source-to-test mapping table:**

```lua
local source_to_tests = {
    ["src/engine/verbs/"]       = {"verbs"},
    ["src/engine/parser/"]      = {"parser"},
    ["src/engine/fsm/"]         = {"fsm"},
    ["src/engine/containment/"] = {"inventory", "search"},
    ["src/engine/injuries/"]    = {"injuries", "stress"},
    ["src/engine/creatures/"]   = {"creatures", "combat"},
    ["src/engine/ui/"]          = {"ui"},
    ["src/meta/objects/"]       = {"objects", "sensory"},
    ["src/meta/world/"]         = {"rooms"},
    ["src/meta/injuries/"]      = {"injuries"},
    ["src/engine/effects.lua"]  = {"verbs", "integration"},
    ["src/engine/display.lua"]  = {"ui"},
    -- Engine core changes → run everything
    ["src/engine/registry/"]    = nil,  -- nil = run all
    ["src/engine/loader/"]      = nil,
    ["src/engine/loop/"]        = nil,
    ["src/engine/mutation/"]    = nil,
    ["src/main.lua"]            = nil,
    -- Test changes → run the changed test's directory
    ["test/"]                   = "self",  -- special: detect dir from test path
}
```

3. **Git diff parsing:**

```lua
if changed_only then
    local git_cmd = "git diff --name-only HEAD"
    local pipe = io.popen(git_cmd)
    local changed_files = {}
    if pipe then
        for line in pipe:lines() do
            changed_files[#changed_files + 1] = line
        end
        pipe:close()
    end

    -- Also include unstaged changes
    local unstaged_pipe = io.popen("git diff --name-only")
    if unstaged_pipe then
        for line in unstaged_pipe:lines() do
            changed_files[#changed_files + 1] = line
        end
        unstaged_pipe:close()
    end

    -- Map changed source files to test directories
    local needed_dirs = {}
    local run_all = false

    for _, file in ipairs(changed_files) do
        local matched = false
        for prefix, test_dirs_for_prefix in pairs(source_to_tests) do
            if file:find(prefix, 1, true) == 1 then
                matched = true
                if test_dirs_for_prefix == nil then
                    run_all = true
                    break
                elseif test_dirs_for_prefix == "self" then
                    local dir = file:match("test/([^/]+)/")
                    if dir then needed_dirs[dir] = true end
                else
                    for _, d in ipairs(test_dirs_for_prefix) do
                        needed_dirs[d] = true
                    end
                end
            end
        end
        if run_all then break end
        -- Unmatched files: conservative, run all
        if not matched and not file:match("^docs/")
                       and not file:match("^plans/")
                       and not file:match("^%.squad/")
                       and not file:match("^resources/")
                       and not file:match("^web/")
                       and not file:match("^scripts/") then
            run_all = true
            break
        end
    end

    if not run_all and next(needed_dirs) then
        -- Filter test_dirs to only needed directories
        local filtered = {}
        for _, dir in ipairs(test_dirs) do
            local dir_name = dir:match("([^/\\]+)$")
            if needed_dirs[dir_name] then
                filtered[#filtered + 1] = dir
            end
        end
        test_dirs = filtered
    end
    -- If run_all or no changes found, run everything (safe default)
end
```

4. **Update header:**

```lua
if changed_only then
    if run_all then
        print("  (--changed: core change detected, running all)")
    else
        local dirs = {}
        for d in pairs(needed_dirs) do dirs[#dirs+1] = d end
        print("  (--changed: " .. table.concat(dirs, ", ") .. ")")
    end
end
```

5. **Edge cases:**
- No changes detected (`git diff` returns empty): run all tests (safe default)
- Core engine change (registry, loader, loop, mutation, main.lua): run all tests
- Documentation/plans/scripts changes: skip (no test impact)
- Test file changes: run that test's directory
- Unknown source file: run all (conservative)
- `--changed` combined with `--shard`: shard filter applies AFTER changed filter

**Bart instructions — Unix parallel runner:**

Create `test/run-tests-parallel.sh` — a POSIX-compatible parallel runner using `xargs` and background jobs.

```bash
#!/bin/bash
# test/run-tests-parallel.sh
# Parallel test runner for MMO test suite (Unix/macOS/CI).
#
# Usage:
#   ./test/run-tests-parallel.sh              # 8 workers
#   ./test/run-tests-parallel.sh -w 4         # 4 workers
#   ./test/run-tests-parallel.sh --bench      # Include benchmarks
#   ./test/run-tests-parallel.sh --shard parser  # Run only parser tests

set -euo pipefail

WORKERS=8
BENCH=false
SHARD=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--workers) WORKERS="$2"; shift 2 ;;
        --bench) BENCH=true; shift ;;
        --shard) SHARD="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done
```

Key implementation:
1. **File discovery** — `find test/ -name "test-*.lua"` (and `bench-*.lua` if `--bench`)
2. **Shard filtering** — grep on directory path
3. **Parallel execution** — use `xargs -P $WORKERS` for portability:
   ```bash
   find_test_files | xargs -P "$WORKERS" -I{} bash -c '
       output=$(lua "{}" 2>&1)
       exitcode=$?
       if [ $exitcode -eq 0 ]; then
           echo "  ✓ {}"
       else
           echo "  ✗ {}"
           echo "$output" >> "$FAIL_LOG"
       fi
   '
   ```
4. **Results aggregation** — write failures to a temp log, print summary at end
5. **Exit code** — 0 if all pass, 1 if any fail
6. **Make executable** — `chmod +x test/run-tests-parallel.sh`

**Brockman instructions — update docs:**

Update `docs/testing/test-runner-flags.md` to include:
- `--changed` flag documentation with source-to-test mapping table
- Unix parallel runner usage (`test/run-tests-parallel.sh`)
- CI behavior section (matrix shards, auto-issues)
- Quick reference for common workflows:
  - "Fast local check after editing verbs": `lua test/run-tests.lua --changed`
  - "Full local run": `./test/run-tests-parallel.ps1`
  - "Run specific area": `lua test/run-tests.lua --shard parser`

---

### GATE-4: Incremental + Cross-Platform Verified

| Criterion | Pass Condition | Verifier |
|-----------|---------------|----------|
| `--changed` filters | Edit a file in `src/engine/verbs/`, run `--changed`, only verbs/ tests run | Nelson |
| `--changed` core fallback | Edit `src/engine/registry/init.lua`, run `--changed`, ALL tests run | Nelson |
| `--changed` no-change | Clean working tree → `--changed` runs all tests (safe default) | Nelson |
| `--changed` + `--shard` | Both flags combine correctly (shard narrows further) | Nelson |
| `--changed` docs skip | Edit only `docs/` files → `--changed` runs all (no test dirs matched, safe) | Nelson |
| Unix runner works | `./test/run-tests-parallel.sh` completes with 0 failures on Unix | Bart |
| Unix runner speed | Wall-clock time < 25 seconds (without benchmarks) | Marge |
| Docs complete | All 3 runner modes documented with examples | Brockman |
| Zero regressions | Serial runner still passes, parallel runner still passes | Marge |

**Verification commands:**
```powershell
# 1. Test --changed with a verb edit
# (make a trivial change to src/engine/verbs/init.lua, then:)
lua test/run-tests.lua --changed
# Expected: only verbs/ tests run

# 2. Test --changed with core edit
# (make a trivial change to src/engine/registry/init.lua, then:)
lua test/run-tests.lua --changed
# Expected: all tests run (core change)

# 3. Test --changed with clean tree
git stash
lua test/run-tests.lua --changed
# Expected: all tests run (no changes = safe default)
git stash pop

# 4. Combination test
lua test/run-tests.lua --changed --shard parser
# Expected: only parser tests if parser-related files changed; nothing if not
```

```bash
# 5. Unix parallel runner (on Linux/macOS or CI)
chmod +x test/run-tests-parallel.sh
./test/run-tests-parallel.sh
./test/run-tests-parallel.sh --bench
./test/run-tests-parallel.sh --shard parser
```

**On pass:** Commit and push.
```
GATE-4: Incremental testing + cross-platform parallel

- Added --changed flag: git-diff-based test filtering with source-to-test mapping
- Created test/run-tests-parallel.sh for Unix/CI parallelism
- Updated docs/testing/test-runner-flags.md with all flags
- Incremental dev feedback: <5s for typical changes
- Tests: 0 regressions

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

**═══ PHASE 3 (DEVELOPER EXPERIENCE) SHIPS HERE ═══**

---

## Section 5: Cross-System Integration Points

### File Ownership Map

```
test/run-tests.lua          — Nelson (all modifications across WAVE-1, WAVE-2, WAVE-4)
test/run-tests-parallel.ps1 — Bart (WAVE-2, new file)
test/run-tests-parallel.sh  — Bart (WAVE-4, new file)
.github/workflows/squad-ci.yml — Gil (WAVE-2, WAVE-3)
docs/testing/test-runner-flags.md — Brockman (WAVE-3, WAVE-4)
test/parser/bench-*.lua     — Nelson (WAVE-1, renames)
```

### Dependencies Between Components

```
run-tests.lua (serial runner, pure Lua)
├── --bench flag (WAVE-1) — controls bench-* file discovery
├── --shard flag (WAVE-2) — filters test directories for CI matrix
└── --changed flag (WAVE-4) — git-diff-based test directory filtering

run-tests-parallel.ps1 (PowerShell 7 runner)
├── Mirrors run-tests.lua directory list (manually synced)
├── -Bench flag (mirrors --bench)
└── -Shard flag (mirrors --shard)

run-tests-parallel.sh (Unix runner)
├── find-based discovery (independent of run-tests.lua)
├── --bench flag (mirrors --bench)
└── --shard flag (mirrors --shard)

squad-ci.yml (GitHub Actions)
├── Depends on: run-tests.lua --bench --shard (WAVE-2+)
├── Matrix strategy: 6 shards (WAVE-3)
├── Auto-issue: actions/github-script@v7 (WAVE-3)
└── Labels: bug, ci-failure, squad:nelson
```

### Directory List Synchronization

**Risk:** Three files maintain the list of test directories — `run-tests.lua`, `run-tests-parallel.ps1`, and `run-tests-parallel.sh`. If a new test directory is added, all three must be updated.

**Mitigation:** The parallel runners are wrappers. For the PowerShell runner, consider having it read the directory list from `run-tests.lua` or a shared config. However, for Phase 1, manual synchronization is acceptable — the directory list changes rarely (last addition was `test/engine/` months ago). Document this sync requirement in `docs/testing/test-runner-flags.md`.

**Future improvement (out of scope):** Extract directory list to a shared `test/test-dirs.txt` file read by all three runners.

### CI Label Requirements

The auto-issue filing in WAVE-3 requires these labels to exist in the GitHub repository:
- `bug` (likely exists)
- `ci-failure` (must be created)
- `squad:nelson` (likely exists from squad label sync)

Gil must verify label existence before WAVE-3 or create them as part of WAVE-3 setup.

---

## Section 6: TDD Test File Map

This plan is unusual in that it modifies _test infrastructure_ rather than game code. The "tests" are verification commands rather than new `.lua` test files. Each gate defines explicit pass/fail criteria that serve the same purpose.

| Feature | Verification Method | Written In | Key Assertions |
|---------|-------------------|-----------|----------------|
| `--bench` flag | Gate commands | GATE-1 | bench-* files excluded by default, included with flag |
| bench-* renames | File count check | GATE-1 | Total count matches, git history preserved |
| Parallel runner (PS) | Direct execution | GATE-2 | 0 failures, <25s wall time, no interleaved output |
| `--shard` flag | Per-shard runs | GATE-2 | Each shard runs only its directories, full coverage |
| Basic CI | Workflow execution | GATE-2 | CI triggers on push, all tests pass |
| Auto-issue filing | Forced failure test | GATE-3 | Issue created with correct labels, no duplicates |
| Auto-close | Fix + push | GATE-3 | Issue closed with comment |
| Matrix sharding | CI run | GATE-3 | 6 shards run in parallel, <40s total |
| `--changed` flag | Directed edits | GATE-4 | Correct directory filtering for each source prefix |
| Parallel runner (Unix) | Direct execution | GATE-4 | 0 failures, <25s wall time |

**Why no new `test-*.lua` files:** The deliverables are test runner modifications and CI configuration — infrastructure that is verified by running the runner itself. Adding a `test-test-runner.lua` would create circular dependencies (testing the test runner with the test runner). Gate verification commands provide equivalent coverage.

---

## Section 7: Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| **PowerShell 7 not available** | Medium | High | Guard at script startup: check `$PSVersionTable.PSVersion.Major -ge 7`, print clear error with install instructions. Serial runner (`run-tests.lua`) always available as fallback. |
| **Parallel output corruption** | Low | Medium | Each worker buffers output to string; prints complete block on completion. `ForEach-Object -Parallel` returns objects, not interleaved streams. |
| **bench-* rename breaks references** | Low | Medium | Search codebase for references to renamed files before renaming. No documentation or CI config references exist currently (design plan confirmed). |
| **`--shard other` misses new directories** | Medium | Medium | "Other" shard is a catch-all (everything NOT in named shards). New directories automatically fall into `other`. Document: when adding a named shard, update both `run-tests.lua` and `squad-ci.yml`. |
| **`--changed` mapping staleness** | Medium | Low | Conservative fallback: unmapped source files trigger "run all." Only `docs/`, `plans/`, `.squad/`, `resources/`, `web/`, `scripts/` are skipped. Any unknown source file = run all. |
| **`--changed` misses regressions** | Low | High | `--changed` is for local dev speed only. CI always runs everything. Developer docs emphasize: "use `--changed` for quick checks, run full suite before pushing." |
| **CI shard imbalance** | Medium | Low | Shard sizes vary (verbs=61 files, search=26 files). Wall time depends on slowest shard. If imbalanced, re-distribute in a follow-up. Benchmarks spread across shards help. |
| **GitHub Actions minutes cost** | Low | Medium | 6 shards × ~30s each = ~3 minutes per push. At ~20 pushes/week = ~60 min/week. Well within free tier (2000 min/month). |
| **`git diff` unavailable in some contexts** | Low | Low | `--changed` fails gracefully: if `git diff` returns error, run all tests (safe default). Log a warning. |
| **Test directory list drift** | Medium | Medium | Three files maintain dir lists. Document sync requirement. Future: extract to shared config file. |
| **`actions/github-script@v7` API changes** | Low | Low | Pin to `@v7`. GitHub Scripts API is stable. If it breaks, CI tests still run — only auto-filing fails. |
| **bm25-deep is a correctness test** | Medium | Medium | WAVE-0 audit explicitly checks this. If it's correctness, don't rename. Only confirmed benchmarks get `bench-*` prefix. |

---

## Section 8: Autonomous Execution Protocol

### Coordinator Execution Loop

```
FOR each WAVE in [WAVE-0, WAVE-1, WAVE-2, WAVE-3, WAVE-4]:

  1. SPAWN parallel agents per wave assignment table
     - Each agent gets: task description, exact files, implementation spec
     - Only ONE agent touches run-tests.lua per wave (Nelson)
     - Only ONE agent touches squad-ci.yml per wave (Gil)

  2. COLLECT results from all agents
     - Check: all files created/modified as specified
     - Check: no unintended file changes (git diff --stat)

  3. RUN gate tests (skip for WAVE-0):
     lua test/run-tests.lua          # serial still works
     lua test/run-tests.lua --bench  # benchmarks included
     + wave-specific gate commands (see gate definitions)

  4. EVALUATE gate:
     IF all criteria pass:
       COMMIT with gate message
       git push
       → PROCEED to next wave

     IF any criterion fails:
       FILE issue with failure details
       ASSIGN fix to the agent who owns the failing component
       RE-RUN gate after fix
       IF gate fails 1x: ESCALATE to Wayne
```

### Commit Pattern

One commit per gate, message format:
```
GATE-N: Test speed {phase description}

- {summary of changes}
- Runtime: {before} → {after}
- Tests: 0 regressions

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

### Wayne Check-In Points

Wayne only needs to be involved at:
1. **GATE-2** (Phase 1 complete) — verify parallel runner output format, CI green
2. **GATE-3** (Phase 2 complete) — verify auto-issue filing works as expected
3. **Any escalation** from gate failures

### Session Continuity

If a session dies mid-wave:
1. Check git log for last GATE-N commit
2. Resume from the NEXT wave
3. If mid-wave (no gate commit), check `git diff --stat` for partial work
4. Re-run the entire wave if partial work detected (waves are designed to be idempotent)

---

## Section 9: Gate Failure Protocol

### Failure Handling Procedure

**Step 1: First failure**
- Coordinator files a GitHub issue with: which gate failed, which criterion failed, full diagnostic output
- Assign fix to the agent who owns the failing component:
  - `run-tests.lua` issues → Nelson
  - `run-tests-parallel.ps1` issues → Bart
  - `squad-ci.yml` issues → Gil
  - Documentation issues → Brockman
- Re-gate: run the full gate criteria
- **Escalate to Wayne** with diagnostic summary (1x threshold)

**Step 2: Second failure (same criterion)**
- Escalate immediately to Wayne with full diagnostic
- Wayne decides: retry with different approach, modify the plan, or defer the failing component

### Common Failure Scenarios

| Failure | Likely Cause | Fix Agent |
|---------|-------------|-----------|
| Parallel runner hangs | Worker deadlock on output | Bart — add timeout per worker |
| CI workflow syntax error | YAML formatting | Gil — validate with actionlint |
| `--shard` misses files | Directory matching regex | Nelson — fix filter logic |
| `--changed` runs too much | Overly conservative mapping | Nelson — refine mapping (acceptable to over-run, not under-run) |
| Auto-issue not created | Missing labels or permissions | Gil — verify labels exist, check `permissions:` block |

### Lockout Policy

If an agent's code fails a gate twice on the same criterion, a fresh agent takes over. The original agent's partial work is preserved in git; the replacement agent builds on it.

---

## Section 10: Staffing Matrix

| Agent | WAVE-0 | WAVE-1 | WAVE-2 | WAVE-3 | WAVE-4 |
|-------|--------|--------|--------|--------|--------|
| **Nelson** | Timing baseline, bench audit | run-tests.lua (--bench), bench renames | run-tests.lua (--shard) | — | run-tests.lua (--changed) |
| **Bart** | — | — | run-tests-parallel.ps1 | — | run-tests-parallel.sh |
| **Gil** | — | — | squad-ci.yml (basic) | squad-ci.yml (matrix + auto-issues) | — |
| **Marge** | — | Verify file counts | — | — | Final gate verification |
| **Brockman** | — | — | — | test-runner-flags.md | Update docs with --changed + Unix runner |

---

## Section 11: Performance Budget

| Metric | Before | After GATE-1 | After GATE-2 | After GATE-4 |
|--------|--------|-------------|-------------|-------------|
| Serial (dev, no bench) | ~156s | <100s | <100s | <100s |
| Serial (CI, with bench) | ~156s | ~156s | ~156s | ~156s |
| Parallel (dev, no bench) | N/A | N/A | <25s | <25s |
| Parallel (CI, with bench) | N/A | N/A | N/A | <40s (matrix) |
| Incremental (dev, typical) | N/A | N/A | N/A | <5s |

These are targets, not hard gates. The parallel speedup depends on hardware (core count, disk speed). The <25s target assumes 8 workers on a modern machine with the ~90s serial baseline (no benchmarks).

---

## Section 12: References

| Resource | Location |
|----------|----------|
| Source design plan | `plans/testing/test-speed-design.md` |
| Current test runner | `test/run-tests.lua` |
| Current CI config | `.github/workflows/squad-ci.yml` (placeholder) |
| Implementation plan skill | `.squad/skills/implementation-plan/SKILL.md` |
| Linter impl plan (format reference) | `plans/linter/linter-improvement-implementation-phase1.md` |
| Engine refactoring decision | D-ENGINE-REFACTORING-WAVE2 (file splitting deferred to this) |

---

## Section 13: Deferred Work (Phase 4)

The design plan's Phase 4 (Test File Splitting) is **deferred** from this implementation plan:

- 9 files exceed 40KB, but file size doesn't correlate with runtime
- The 60KB `test-verb-comprehensive.lua` runs in 220ms
- Splitting is a maintainability concern, not a speed concern
- Already tracked under D-ENGINE-REFACTORING-WAVE2
- Recommend: revisit after Phase 3 ships, as parallel execution may make splitting even less impactful

---

> **Footer — Future Enhancements:**
> - Watch mode (`--watch`) for auto-rerun on file save — requires OS-specific file watcher, deferred
> - Shared `test/test-dirs.txt` config to eliminate directory list drift across 3 runner files
> - Test timing database for smarter shard balancing (run slowest files first)
> - Coverage-based mapping to replace manual `source_to_tests` table
