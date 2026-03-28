# Mutation Graph Linter — Implementation Plan (Phase 1)

**Author:** Bart (Architecture Lead)
**Requested by:** Wayne "Effe" Berry
**Date:** 2026-08-23
**Status:** PLAN — Ready for review
**Version:** v1.0
**Source:** `plans/linter/mutation-graph-linter-design.md` (revised expand-and-lint approach)

---

## Status Tracker

| Wave | Status | Gate | Status |
|------|--------|------|--------|
| WAVE-0: Lua Edge Extractor | ⏳ Pending | GATE-0 | ⏳ |
| WAVE-1: Meta-Lint Integration | ⏳ Pending | GATE-1 | ⏳ |
| WAVE-2: Full Run + Docs + Issues | ⏳ Pending | — | — |

---

## Executive Summary

Build a Lua edge extractor (~100-150 LOC) that scans all `.lua` files under `src/meta/`, extracts mutation edges, verifies target files exist, and outputs target file paths. Pipe those paths to the existing Python meta-lint (`scripts/meta-lint/lint.py`) for full 200+ rule validation.

**Why this approach (per Wayne's direction):**
- No custom graph library, no BFS/DFS, no cycle detection — the extractor just walks files and checks edges
- No duplicate validation code — the existing linter (200+ rules, fix_safety, `--env` profiles) applies to ALL mutation targets for free
- Edge existence checking is a simple file-exists test
- Dynamic mutations flagged but not followed (same as original design)
- Two tools, each doing what it's good at: Lua loads Lua objects; Python lints them

**Key deliverables:**
1. `scripts/mutation-edge-check.lua` — Lua edge extractor (~100-150 LOC)
2. `test/meta/test-edge-extractor.lua` — Tests for the extractor
3. `scripts/mutation-lint.ps1` — Wrapper that runs both tools
4. `docs/testing/mutation-graph-linting.md` — Documentation
5. `.squad/skills/mutation-graph-lint/SKILL.md` — Reusable skill
6. GitHub issues filed for all broken edges

**Scope:** 3 waves, 2 gates, 3 agents (Bart, Nelson, Brockman). Estimated ~4-5 hours total.

---

## Quick Reference Table

| Wave | Agent(s) | Deliverables | Gate |
|------|----------|-------------|------|
| WAVE-0 | Bart, Nelson (parallel) | `scripts/mutation-edge-check.lua`, `test/meta/test-edge-extractor.lua` | GATE-0: Extractor finds 4 broken edges, all tests pass |
| WAVE-1 | Bart, Nelson (parallel) | `scripts/mutation-lint.ps1`, integration tests | GATE-1: Full pipeline runs, targets lint clean (or violations captured) |
| WAVE-2 | Brockman, Bart, Nelson | Docs, skill file, full run, issue filing | — (final deliverable) |

---

## Dependency Graph

```
WAVE-0: Lua Edge Extractor
  │  Bart: scripts/mutation-edge-check.lua
  │  Nelson: test/meta/test-edge-extractor.lua (parallel — different file)
  │
  ▼
GATE-0 ── extractor: 4 broken edges detected, paper.lua dynamic flagged, all tests pass
  │
  ▼
WAVE-1: Meta-Lint Integration
  │  Bart: scripts/mutation-lint.ps1 (wrapper)
  │  Nelson: integration test (piped output → lint)
  │
  ▼
GATE-1 ── full pipeline: edge check + lint on targets, zero crashes
  │
  ├──────────────────────┬──────────────────────┐
  ▼                      ▼                      ▼
WAVE-2a: Docs          WAVE-2b: Skill         WAVE-2c: Full Run
  Brockman               Bart                   Nelson
  mutation-graph-        SKILL.md               full run + issue
  linting.md                                    filing
  │                      │                      │
  └──────────────────────┴──────────────────────┘
  │
  ▼
DONE ── issues filed, docs complete, plan finished
```

---

## Implementation Waves

### WAVE-0: Lua Edge Extractor

**Purpose:** Build the standalone Lua script that scans meta files, extracts mutation edges, and verifies target file existence. Write tests in parallel.

| Task | Agent | File | Action |
|------|-------|------|--------|
| Create test dir | Nelson | `test/meta/` | `mkdir test\meta` |
| Register test dir | Nelson | `test/run-tests.lua` | Add `test/meta` to `test_dirs` array |
| Edge extractor | Bart | `scripts/mutation-edge-check.lua` | New file (~100-150 LOC) |
| Extractor tests | Nelson | `test/meta/test-edge-extractor.lua` | New file (~80-120 LOC) |

**File ownership:** No conflicts — Bart writes the script, Nelson writes the tests (different files). Nelson also owns `test/run-tests.lua` (per D-TEST-SPEED-IMPL-WAVES).

#### `scripts/mutation-edge-check.lua` — Specification

**CLI interface:**
```
lua scripts/mutation-edge-check.lua [options]

Options:
  --targets-only    Output only valid target file paths (one per line)
                    Broken edges go to stderr. Designed for piping to lint.py.
  --json            Output structured JSON (for programmatic consumption)
  (default)         Human-readable report with broken edges and stats
```

**Functions (5):**

1. **`scan_meta_root(root)`**
   - Input: `"src/meta"` (relative to repo root)
   - Output: Array of `{ filepath, id }` where `id` is extracted from the filename (strip `.lua`)
   - Behavior: Two-pass scan via `io.popen`. Discovers ALL subdirs at runtime.
   - Platform: `dir /b /ad` (Windows) / `ls -d */` (Unix) for subdirs; `dir /b *.lua` / `ls *.lua` for files.

2. **`safe_load(filepath)`**
   - Input: Path to `.lua` file
   - Output: `table, nil` | `nil, error_string`
   - Behavior: `loadfile()` with restricted env (`math`, `string`, `table`, `pairs`, `ipairs`, `tostring`, `tonumber`, `type`, `print` = no-op, `require` = stub). `pcall(fn)`. Validates result is a table.
   - Lua 5.1: `setfenv(fn, env)`.

3. **`extract_edges(obj, source_id)`**
   - Input: Loaded object table, source ID
   - Output: `edges[]`, `dynamics[]`
   - Extracts from 5 mechanisms: `mutations[verb].becomes`, `mutations[verb].spawns[]`, `transitions[i].spawns[]`, `crafting[verb].becomes`, `on_tool_use.when_depleted`
   - `dynamic == true` → add to dynamics, skip edges
   - `becomes == nil` → intentional destruction, NOT an edge

4. **`resolve_target(target_id, file_map)`**
   - Input: Target ID (e.g., `"cloth"`), map of `id → filepath`
   - Output: Filepath if found, nil if broken
   - Simple lookup: `file_map[target_id]`

5. **`main(root)`**
   - Orchestrator. Scans files, loads each, extracts edges, resolves targets.
   - Builds `file_map` (id → filepath) from all scanned files for O(1) lookups.
   - Returns: `{ files_scanned, edges, broken, dynamics, valid_targets }`
   - Prints report or targets list based on CLI flag.

**Exit codes:**
- `0` — No broken edges
- `1` — One or more broken edges found

#### `test/meta/test-edge-extractor.lua` — Specification

Uses `test/parser/test-helpers.lua` (existing framework). Tests the extractor functions by importing them or by running the script and checking output.

**Test suites (~30-40 tests):**

| Suite | Tests | Description |
|-------|-------|-------------|
| File scanning | ~5 | `scan_meta_root` discovers expected subdirs, returns .lua files, no hardcoded list |
| Sandbox loading | ~5 | `safe_load` loads valid objects, returns nil for bad files, sandboxes correctly |
| Edge extraction | ~10 | Extracts `becomes`, `spawns`, `crafting.becomes`, `on_tool_use.when_depleted`, handles `becomes=nil`, handles `dynamic=true` |
| Broken edge detection | ~5 | Finds the 4 known broken edges, doesn't false-positive on valid edges |
| Dynamic flagging | ~2 | `paper.lua` flagged as dynamic, verb = `write` |
| CLI output | ~5 | Default mode shows report, `--targets-only` outputs file paths, broken edges on stderr |
| Integration sanity | ~3 | Full run against real `src/meta/`, edge count > 20, file count > 80 |

**Known assertions:**
- Broken edges == 4 (poison-gas-vent-plugged ×1, wood-splinters ×3)
- Dynamic paths >= 1 (paper.lua write)
- Files scanned > 80 (currently ~91+)
- Edges found > 20 (currently ~47)

**Estimate:** ~2 hours (Bart: extractor, Nelson: tests — parallel).

---

### GATE-0: Edge Extractor Works

| Criterion | Verification |
|-----------|-------------|
| `scripts/mutation-edge-check.lua` exists and runs | `lua scripts/mutation-edge-check.lua` exits without crash |
| 4 broken edges detected | Output contains all 4 known broken targets |
| `paper.lua` dynamic flagged | Output shows dynamic path for paper/write |
| `--targets-only` outputs file paths | Pipe to `wc -l` shows > 0 valid targets |
| All tests pass | `lua test/meta/test-edge-extractor.lua` — zero failures |
| No regressions | `lua test/run-tests.lua` — full suite passes |

**Binary pass/fail:** All 6 criteria must pass.

---

### WAVE-1: Meta-Lint Integration

**Purpose:** Wire the Lua extractor output to the Python meta-lint for full rule coverage on all mutation targets.

| Task | Agent | File | Action |
|------|-------|------|--------|
| Wrapper script | Bart | `scripts/mutation-lint.ps1` | New file — runs both tools |
| Shell wrapper | Bart | `scripts/mutation-lint.sh` | New file — Unix equivalent |
| Integration test | Nelson | `test/meta/test-mutation-lint-integration.lua` | Verifies piped output works |

#### `scripts/mutation-lint.ps1` — Specification

```powershell
# Mutation Lint — Full Parallel Pipeline
# Objects are expanded and linted in parallel (D-MUTATION-LINT-PARALLEL)
# Step 1: Edge check (broken edges report)
# Step 2: Lint all valid targets concurrently with -Parallel

param(
    [switch]$EdgesOnly,    # Skip lint step, just check edges
    [string]$Format = "text",
    [string]$Env = $null,
    [int]$ThrottleLimit = 4  # Parallel lint workers
)

# Step 1: Edge check
$edgeResult = lua scripts/mutation-edge-check.lua
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠ Broken mutation edges found (see above)"
}

if (-not $EdgesOnly) {
    # Step 2: Lint all valid targets in parallel
    $targets = lua scripts/mutation-edge-check.lua --targets-only
    if ($targets) {
        $targets | ForEach-Object -Parallel {
            python scripts/meta-lint/lint.py $_ --format $using:Format
        } -ThrottleLimit $ThrottleLimit
    }
}
```

#### `scripts/mutation-lint.sh` — Specification

```bash
#!/bin/bash
# Mutation Lint — Full Parallel Pipeline
# Objects are expanded and linted in parallel (D-MUTATION-LINT-PARALLEL)
WORKERS=${1:-4}

# Step 1: Edge check (runs concurrently with lint via background job)
lua scripts/mutation-edge-check.lua &
EDGE_PID=$!

# Step 2: Lint targets in parallel (starts immediately, streams from extractor)
lua scripts/mutation-edge-check.lua --targets-only | xargs -P "$WORKERS" -I {} python scripts/meta-lint/lint.py {}

# Wait for edge report to finish
wait $EDGE_PID
```

#### Integration Test

Nelson writes a test that:
1. Runs `lua scripts/mutation-edge-check.lua --targets-only`
2. Verifies output is one filepath per line
3. Verifies each listed file actually exists
4. Verifies known targets appear (e.g., `cloth.lua`, `glass-shard.lua`)
5. Runs `python scripts/meta-lint/lint.py {first target}` — verifies it exits without crash

**Estimate:** ~1 hour (Bart: wrapper scripts, Nelson: integration test — parallel).

---

### GATE-1: Full Pipeline Works

| Criterion | Verification |
|-----------|-------------|
| Wrapper runs without crash | `.\scripts\mutation-lint.ps1` completes |
| Edge check + lint both execute | Both steps produce output |
| Targets lint successfully | Python linter runs on each target without crash |
| Integration test passes | `lua test/meta/test-mutation-lint-integration.lua` — zero failures |
| No regressions | `lua test/run-tests.lua` — full suite passes |

**Binary pass/fail:** All 5 criteria must pass.

---

### WAVE-2: Full Run + Docs + Issues

**Purpose:** Run the full pipeline, write documentation, create skill file, file GitHub issues for all broken edges.

| Task | Agent | File | Action |
|------|-------|------|--------|
| Documentation | Brockman | `docs/testing/mutation-graph-linting.md` | New file — per Phase 1 spec |
| Skill file | Bart | `.squad/skills/mutation-graph-lint/SKILL.md` | New file — per Phase 3 spec |
| Full pipeline run | Nelson | — | Run `mutation-lint.ps1`, capture output |
| Issue filing | Nelson + Bart | GitHub | File issues for 4 broken edges + any lint violations |

**Issue filing rules:** Per Phase 4 of the design doc. Broken edges → squad:flanders. Lint violations → routed per `squad_routing.py`.

**Estimate:** ~1.5 hours (Brockman: docs, Bart: skill, Nelson: run + issues — all parallel).

---

## Testing Gates

### Test File Map

| File | Coverage | Agent |
|------|----------|-------|
| `test/meta/test-edge-extractor.lua` | Lua extractor: scanning, loading, extraction, broken edges, dynamic, CLI | Nelson |
| `test/meta/test-mutation-lint-integration.lua` | Full pipeline: extractor → lint piping, target validity | Nelson |

### Regression Baseline

Record test count before WAVE-0 and verify unchanged after each gate.

---

## Feature Breakdown

### Lua Edge Extractor (`scripts/mutation-edge-check.lua`)

**What it does:** Walks all `.lua` files under `src/meta/`, loads each in a Lua sandbox, extracts mutation edges from 5 mechanisms, checks if each target file exists, reports broken edges.

**What it does NOT do:**
- No graph library (no nodes/edges data structure beyond simple arrays)
- No BFS/DFS traversal
- No cycle detection (not needed — edges are checked independently)
- No unreachable node detection
- No test-harness integration (it's a script, not a test)

**Why this is enough:** The original design built a full graph library to do validation inline. With the expand-and-lint approach, the existing Python linter handles ALL validation. The Lua script just needs to answer two questions: (1) does the target file exist? (2) what are the target files? Everything else is the Python linter's job.

### Python Meta-Lint Integration

**What it does:** Receives a list of target file paths from the Lua extractor and runs the full 200+ rule engine on each.

**What this gives us for free:**
- Required field validation (id, on_feel, template, keywords, etc.)
- Naming conventions
- Sensory field completeness
- Material consistency
- GUID format validation
- Template inheritance checks
- Exit/door validation
- Creature rule validation
- Fix-safety classification
- `--env` profile support
- Incremental caching (via `--no-cache` to force full scan)

**What we'd have had to duplicate without this:** All of the above, either as custom Lua checks or as a separate validation layer.

---

## Cross-System Integration Points

| System A | System B | Integration |
|----------|----------|-------------|
| Lua extractor | Python meta-lint | File path list (stdout pipe or xargs) |
| Lua extractor | test/run-tests.lua | Test file registered in `test/meta/` dir |
| Python meta-lint | squad_routing.py | Lint violations routed to correct agent |

---

## Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| `io.popen` platform differences | Extractor fails on Unix | Same cross-platform pattern as `test/run-tests.lua` — proven working |
| Python not installed | Lint step fails | Edge check still works standalone; wrapper script checks for Python |
| New mutation mechanism added | Extractor misses edges | `extract_edges()` is the single place to update — documented in skill |
| Large file count slows lint | Pipeline takes minutes | Python linter has incremental caching; `--no-cache` only for full runs |
| Sandbox doesn't match engine loader | Objects fail to load | Sandbox mirrors `engine/loader/init.lua` pattern — same restricted env |

---

## Autonomous Execution Protocol

- WAVE-0 → parallel (Bart + Nelson) → GATE-0 → pass? → WAVE-1
- WAVE-1 → parallel (Bart + Nelson) → GATE-1 → pass? → WAVE-2
- WAVE-2 → parallel (Brockman + Bart + Nelson) → DONE
- Gate failure → file GitHub issue, assign fix to Bart, re-gate
- Escalate to Wayne after 1x gate failure (per implementation-plan skill)
- Commit/push after every gate

---

## Gate Failure Protocol

- 1st failure: File GitHub issue describing the failure, assign to responsible agent, re-attempt
- 2nd failure on same gate: Escalate to Wayne with issue link and failure details
- Rollback: Git revert to last passing gate tag if needed

---

## Wave Checkpoint Protocol

After each wave completes:
1. Update Status Tracker at top of this document
2. Record actual vs. estimated time
3. Note any deviations from plan
4. Commit updated plan

---

## Documentation Deliverables

| Document | Owner | Gate |
|----------|-------|------|
| `docs/testing/mutation-graph-linting.md` | Brockman | WAVE-2 |
| `.squad/skills/mutation-graph-lint/SKILL.md` | Bart | WAVE-2 |
| This plan (status updates) | Bart | Every wave |
