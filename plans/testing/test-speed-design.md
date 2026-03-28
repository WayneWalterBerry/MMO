# Design Plan: Faster Unit Test Execution

**Author:** Bart (Architect)
**Date:** 2026-08-22
**Status:** Draft — awaiting Wayne's review
**Requested by:** Wayne Berry

---

## Executive Summary

The MMO test suite currently takes **~156 seconds** to run 257 test files serially. A single benchmark test (`test-inverted-index.lua`) consumes **61.6 seconds — 40% of total runtime**. With the three highest-impact changes (benchmark gating, parallel execution, CI offload), we can reach **<20 seconds on developer machines** and **<40 seconds in CI with auto-issue filing**.

---

## Current State

### Timing Profile

| Metric | Value |
|--------|-------|
| Total test files | 257 |
| Total runtime | ~156 seconds |
| Test runner | Serial (one `io.popen` subprocess per file) |
| Slowest file | `test/parser/test-inverted-index.lua` — **61.6s** (benchmark: 100 iterations × 10 inputs × full embedding scan) |
| 2nd slowest | `test/integration/test-playtest-bugs.lua` — **10.3s** |
| 3rd slowest | `test/parser/test-tier2-benchmark.lua` — **4.4s** |
| Top 5 total | **~82s** (53% of total runtime) |
| Remaining 252 files | **~74s** (median ~200ms per file) |

### Test Runner Architecture (`test/run-tests.lua`)

- Discovers `test-*.lua` files across 22 hardcoded directories
- Runs each file as a **separate Lua subprocess** via `io.popen("lua file.lua 2>&1")`
- Captures stdout, checks exit code — files are already **process-isolated**
- No parallelism, no timing, no caching, no filtering

### File Size Distribution

| Category | Count | Notes |
|----------|-------|-------|
| >40KB (1000+ lines) | 9 | Comprehensive test suites |
| 30–40KB | 6 | Large integration tests |
| 20–30KB | 37 | Medium test files |
| 5–20KB | 196 | Standard test files |
| <5KB | 9 | Small focused tests |

### Test Directory Breakdown

| Directory | Files | Total Size | Notes |
|-----------|-------|-----------|-------|
| verbs/ | 61 | 979KB | Largest category |
| parser/ | 42 | 491KB | Contains the 61s benchmark |
| creatures/ | 34 | 454KB | |
| rooms/ | 13 | 296KB | |
| search/ | 17 | 272KB | |
| injuries/ | 12 | 263KB | |
| combat/ | 12 | 212KB | |
| objects/ | 14 | 177KB | |
| integration/ | 11 | 125KB | Contains the 10s playtest-bugs |
| inventory/ | 8 | 127KB | |
| *13 others* | 33 | ~383KB | |

### Isolation Analysis

Tests are **already process-isolated** — each runs as a separate `lua` process. Key findings:

- **No shared disk state:** Zero files use `io.open(..., "w")` in test code
- **Module cache reset:** 3 integration tests manually clear `package.loaded` (defensive cleanup for engine module singletons)
- **Registry usage:** 93 files `require("engine.registry")` — but each in its own process, so no cross-test contamination
- **Verdict:** Tests are safe to run in parallel with zero modifications

### Existing CI

`squad-ci.yml` exists but is **unconfigured** — a placeholder with `echo "No build commands configured"`. No Lua runtime is installed in CI.

---

## Approach A: Benchmark Gating (Quick Win)

### Problem

`test-inverted-index.lua` runs 100 iterations of embedding matching (full-scan vs inverted-index) as a **performance benchmark**, not a correctness test. It's 40% of total runtime and provides zero regression value during normal development.

### Proposal

Split benchmark tests into a separate category that only runs on-demand or in CI:

1. **Tag benchmark files** with a naming convention: `bench-*.lua` (rename `test-inverted-index.lua` → `bench-inverted-index.lua`, `test-tier2-benchmark.lua` → `bench-tier2-benchmark.lua`)
2. **Default runner skips `bench-*` files** — only runs `test-*.lua`
3. **Add `--bench` flag** to `run-tests.lua` to include benchmarks
4. **CI always runs `--bench`** — benchmarks execute in CI but not on dev machines

### Impact

| Scenario | Before | After | Speedup |
|----------|--------|-------|---------|
| Developer (no benchmarks) | 156s | ~90s | 1.7× |
| CI (all tests) | 156s | 156s | (same) |

### Effort: **2 hours**

- Rename 2–3 files
- Add `--bench` flag to runner (10 lines)
- Update CI config

### Pros
- Instant win, no architectural risk
- Benchmarks still run in CI
- Developer feedback loop drops by 66 seconds

### Cons
- Doesn't address the remaining 90 seconds
- Developers might forget to check benchmarks

---

## Approach B: Parallel Test Execution

### Problem

The runner is serial. 257 test files × ~600ms average = ~156s. Modern machines have 8–16 cores sitting idle.

### Proposal: Multi-Process Parallel Runner

Since tests already run as isolated `lua` subprocesses, we can launch N processes simultaneously.

#### Option B1: PowerShell Parallel Runner (Simplest)

A PowerShell wrapper that uses `Start-Job` or `ForEach-Object -Parallel`:

```powershell
# Conceptual — run-tests-parallel.ps1
$testFiles = Get-ChildItem -Recurse test/ -Filter "test-*.lua"
$testFiles | ForEach-Object -Parallel {
    $result = lua $_.FullName 2>&1
    [PSCustomObject]@{ File=$_.Name; ExitCode=$LASTEXITCODE; Output=$result }
} -ThrottleLimit 8
```

**Pros:** Zero Lua changes, works today
**Cons:** Windows-only, PowerShell 7 required, less portable

#### Option B2: Lua Parallel Runner (Cross-Platform)

Refactor `run-tests.lua` to batch-launch processes:

```lua
-- Conceptual: launch N processes, poll for completion
local workers = {}
local MAX_WORKERS = 8
for _, entry in ipairs(test_entries) do
    while #workers >= MAX_WORKERS do
        poll_and_collect(workers)
    end
    workers[#workers + 1] = launch_async(entry)
end
```

**Challenge:** Pure Lua has no native async I/O. Options:
1. **`io.popen` + polling loop** — launch up to N processes, check each for completion (hacky but works)
2. **OS-level wrapper** — shell script that launches `lua` processes in background (`&` on Unix, `Start-Process` on Windows)
3. **LuaSocket or LuaLanes** — adds external dependency (violates zero-dependency rule for engine, but test runner is exempt)

**Recommended:** Option B2 with OS-level wrapper — a thin `run-tests-parallel.ps1` (Windows) and `run-tests-parallel.sh` (Unix) that parallelize `lua` invocations. Keep `run-tests.lua` as the serial fallback.

#### Option B3: GNU Parallel / xargs (Unix CI only)

```bash
find test -name 'test-*.lua' | xargs -P 8 -I{} lua {} 2>&1
```

**Pros:** One-liner, zero code changes
**Cons:** Unix-only (fine for CI), output interleaving needs management

### Theoretical Speedup

| Workers | Est. Time (no benchmarks) | Speedup |
|---------|--------------------------|---------|
| 1 (serial) | ~90s | 1× |
| 4 | ~25s | 3.6× |
| 8 | ~15s | 6× |
| 16 | ~10s | 9× |

With benchmarks excluded from dev runs and 8-worker parallelism: **~15 seconds**.

### Effort: **4–8 hours**

- B1 (PowerShell): 2 hours
- B2 (cross-platform Lua + shell): 6 hours
- B3 (CI-only): 30 minutes

### Pros
- Dramatic speedup (6–9× with 8 workers)
- Tests already isolated — zero test modification needed
- Scales with hardware

### Cons
- Output interleaving requires buffering (each worker must capture output, print on completion)
- Failure reporting needs aggregation
- Slightly more complex runner

---

## Approach C: Test File Splitting

### Problem

9 files exceed 40KB (1000+ lines). Large files are harder to maintain and slower to execute (more setup/teardown, longer output).

### Candidates for Splitting

| File | Size | Lines | Recommendation |
|------|------|-------|----------------|
| `test-navigation-comprehensive.lua` | 64KB | 1272 | Split by room pair |
| `test-fsm-comprehensive.lua` | 63KB | 1473 | Split by FSM feature |
| `test-verb-comprehensive.lua` | 61KB | 1450 | Split by verb category |
| `test-bear-trap.lua` | 60KB | 1266 | Split: setup/trigger/damage/escape |
| `test-injuries-comprehensive.lua` | 47KB | 919 | Split by injury type |
| `test-senses-comprehensive.lua` | 46KB | 1076 | Split by sense |
| `test-regression-comprehensive.lua` | 46KB | 1175 | Split by bug ID |
| `test-portal-system.lua` | 45KB | 952 | Split by portal pair |
| `test-poison-bottle.lua` | 45KB | 885 | Split: craft/use/effects |

### Effort: **8–16 hours** (1–2 hours per file)

### Pros
- Better test organization, easier to debug failures
- Enables finer-grained parallel scheduling
- Aligns with engine refactoring direction (D-ENGINE-REFACTORING-WAVE2)

### Cons
- High effort for modest speed gain (files already run in <1s each, even at 60KB)
- Risk of breaking test helper imports
- Splitting doesn't help speed unless combined with parallelism

### Verdict: **Low priority.** File size doesn't correlate with runtime — the 60KB `test-verb-comprehensive.lua` runs in 220ms while the 8KB `test-inverted-index.lua` takes 61s. Split for maintainability later, not for speed.

---

## Approach D: GitHub Actions CI

### Problem

The existing `squad-ci.yml` is unconfigured. Tests don't run in CI at all.

### Proposal: Full CI Pipeline with Parallel Matrix

#### D1: Basic CI Setup

```yaml
name: Squad CI
on:
  pull_request:
    branches: [dev, preview, main, insider]
  push:
    branches: [dev, insider]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Lua
        run: sudo apt-get update && sudo apt-get install -y lua5.4
      
      - name: Run tests
        run: lua test/run-tests.lua
```

**Effort:** 30 minutes

#### D2: Parallel Matrix Strategy

Split tests into shards and run across multiple runners:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        shard: [parser, verbs, creatures, combat, integration, other]
    steps:
      - uses: actions/checkout@v4
      - name: Install Lua
        run: sudo apt-get update && sudo apt-get install -y lua5.4
      - name: Run shard
        run: lua test/run-tests.lua --shard ${{ matrix.shard }}
```

This requires adding `--shard` support to the test runner (filter by directory prefix).

**Theoretical CI time:** ~30s per shard (6 parallel runners) vs 156s serial.

**Effort:** 4 hours (runner changes + CI config)

#### D3: Auto-File GitHub Issues on Test Failures

**Yes, GitHub Actions can automatically file issues on test failures.** Using `actions/github-script`:

```yaml
      - name: File issue on failure
        if: failure()
        uses: actions/github-script@v7
        with:
          script: |
            const { owner, repo } = context.repo;
            const run = context.runId;
            const sha = context.sha.substring(0, 7);
            const branch = context.ref.replace('refs/heads/', '');
            
            // Check for existing open issue to avoid duplicates
            const existing = await github.rest.issues.listForRepo({
              owner, repo,
              labels: 'bug,ci-failure',
              state: 'open',
              per_page: 5
            });
            
            const dupes = existing.data.filter(i => 
              i.title.includes('CI Test Failure'));
            
            if (dupes.length === 0) {
              await github.rest.issues.create({
                owner, repo,
                title: `CI Test Failure on ${branch} (${sha})`,
                body: [
                  `## Automated CI Failure Report`,
                  ``,
                  `**Branch:** \`${branch}\``,
                  `**Commit:** ${context.sha}`,
                  `**Run:** ${context.serverUrl}/${owner}/${repo}/actions/runs/${run}`,
                  `**Shard:** \`${{ matrix.shard }}\``,
                  ``,
                  `### Next Steps`,
                  `1. Check the [workflow logs](${context.serverUrl}/${owner}/${repo}/actions/runs/${run})`,
                  `2. Identify the failing test(s)`,
                  `3. Fix and push — this issue auto-closes when CI passes`,
                ].join('\n'),
                labels: ['bug', 'ci-failure', 'squad:nelson']
              });
            }
```

**Key features:**
- Duplicate detection (won't spam issues for the same failure)
- Links directly to the workflow run
- Labels with `squad:nelson` so QA gets routed
- Can be extended to parse test output and include specific failure details

**Effort:** 2 hours

#### D4: Auto-Close on Success

```yaml
      - name: Close CI failure issues on success
        if: success()
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

### Effort Summary (CI)

| Component | Effort |
|-----------|--------|
| D1: Basic CI | 30 min |
| D2: Parallel matrix | 4 hours |
| D3: Auto-file issues | 2 hours |
| D4: Auto-close issues | 1 hour |
| **Total** | **~8 hours** |

### Pros
- Tests run on every PR without developer action
- Parallel matrix gives ~6× speedup in CI
- Auto-issue filing catches regressions fast
- Doesn't require any changes to test files themselves
- Ubuntu runners have Lua 5.4 available via apt

### Cons
- GitHub Actions minutes cost (free tier: 2000 min/month for private repos)
- Lua installation adds ~10s to each job
- Matrix strategy spawns multiple runners (uses more minutes)

---

## Approach E: Incremental Testing

### Problem

Running all 257 tests after a one-file change is wasteful.

### Proposal: Git-Diff-Based Test Filtering

#### E1: Source-to-Test Mapping

Build a mapping from source files to test directories:

```lua
local source_to_tests = {
    ["src/engine/verbs/"]       = {"test/verbs/"},
    ["src/engine/parser/"]      = {"test/parser/"},
    ["src/engine/fsm/"]         = {"test/fsm/"},
    ["src/engine/containment/"] = {"test/inventory/", "test/search/"},
    ["src/engine/injuries/"]    = {"test/injuries/", "test/stress/"},
    ["src/engine/creatures/"]   = {"test/creatures/", "test/combat/"},
    ["src/meta/objects/"]       = {"test/objects/", "test/sensory/"},
    ["src/meta/world/"]         = {"test/rooms/"},
    -- Engine core changes → run everything
    ["src/engine/registry/"]    = {"test/"},
    ["src/engine/loader/"]      = {"test/"},
    ["src/engine/loop/"]        = {"test/"},
}
```

#### E2: `--changed` Flag

```bash
# Only run tests affected by uncommitted changes
lua test/run-tests.lua --changed

# Implementation: parse `git diff --name-only HEAD`, map to test dirs
```

#### E3: Watch Mode (Future)

A file-watcher that re-runs affected tests on save. Requires a polling loop or OS-specific watcher — complexity may not be worth it for a Lua project.

### Effort: **4–6 hours** (mapping + runner flag)

### Pros
- Fastest possible developer feedback (only run what changed)
- Complements parallelism — fewer files × parallel = near-instant

### Cons
- Mapping requires maintenance as new modules/tests are added
- Edge cases: shared utility changes need "run everything" fallback
- Risk of missing regressions if mapping is incomplete
- `--changed` doesn't help CI (CI should always run everything)

---

## Recommended Implementation Order

### Phase 1: Quick Wins (Week 1) — Target: 90s → ~15s dev, CI enabled

| Priority | Action | Impact | Effort |
|----------|--------|--------|--------|
| **P0** | **A: Gate benchmarks** — rename to `bench-*`, skip by default | -66s (156→90s) | 2h |
| **P1** | **B1: PowerShell parallel runner** — 8 workers | 90s→~15s | 2h |
| **P2** | **D1: Basic CI** — configure `squad-ci.yml` with Lua | CI enabled | 30m |

### Phase 2: CI Excellence (Week 2) — Target: Full CI with auto-issues

| Priority | Action | Impact | Effort |
|----------|--------|--------|--------|
| **P3** | **D3+D4: Auto-file/close issues** | Automated regression tracking | 3h |
| **P4** | **D2: Matrix sharding** | CI: 156s→~30s | 4h |

### Phase 3: Developer Experience (Week 3+) — Target: Near-instant feedback

| Priority | Action | Impact | Effort |
|----------|--------|--------|--------|
| **P5** | **E1+E2: Incremental testing** | Only test what changed | 5h |
| **P6** | **B2: Cross-platform parallel** | Unix/CI parallelism | 6h |

### Phase 4: Maintenance (Ongoing)

| Priority | Action | Impact | Effort |
|----------|--------|--------|--------|
| **P7** | **C: Split large files** | Maintainability | 8–16h |

---

## Answering Wayne's Questions

### Does "faster" mean parallel? Small files? Refactoring? CI? All of the above?

**All of the above, in priority order:**

1. **Benchmark gating** is the single biggest win (40% of runtime, 2 hours of work)
2. **Parallel execution** is the next biggest (6× speedup, tests are already isolated)
3. **CI** is orthogonal — tests should run in CI regardless of local speed
4. **File splitting** helps maintainability but barely affects speed
5. **Incremental testing** is the endgame — only run what changed

The fastest path to <20s dev feedback: gate benchmarks + parallel runner. That's 4 hours of work.

### Can GitHub Actions log issues on failures?

**Yes.** Using `actions/github-script@v7`, the workflow can:

- Create a GitHub issue with failure details, commit SHA, and a direct link to the workflow run
- Label it `bug` + `ci-failure` + `squad:nelson` for routing
- Detect duplicates to avoid spam
- Auto-close when CI passes again

See **Approach D3** for the complete implementation.

---

## Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| Parallel output interleaving | Buffer per-worker output, print on completion |
| Flaky tests under parallelism | Tests are process-isolated — no shared state risk |
| Mapping staleness (incremental) | "Run everything" fallback for unmapped changes |
| CI cost (matrix × minutes) | Start with 3 shards, expand as needed |
| Benchmark gating hides regressions | CI always runs `--bench` |

---

## Appendix: Raw Timing Data

### Top 10 Slowest Test Files

| File | Time (ms) | % of Total |
|------|-----------|-----------|
| `test/parser/test-inverted-index.lua` | 61,645 | 39.6% |
| `test/integration/test-playtest-bugs.lua` | 10,256 | 6.6% |
| `test/parser/test-tier2-benchmark.lua` | 4,389 | 2.8% |
| `test/parser/test-issue-14-15-16-17.lua` | 3,815 | 2.5% |
| `test/integration/test-bugs-066-067-069-070-071.lua` | 3,017 | 1.9% |
| `test/parser/test-bm25-deep.lua` | 2,976 | 1.9% |
| `test/parser/test-issue-174-embedding-overhaul.lua` | 2,285 | 1.5% |
| `test/integration/test-phase4-bugfixes.lua` | 2,033 | 1.3% |
| `test/integration/test-bugs-081-082-083.lua` | 1,938 | 1.2% |
| `test/integration/test-room-override.lua` | 1,486 | 1.0% |

### Timing Distribution

- Files >1s: 10 (~80% of runtime)
- Files 200ms–1s: ~40
- Files <200ms: ~207 (median: ~150ms)
