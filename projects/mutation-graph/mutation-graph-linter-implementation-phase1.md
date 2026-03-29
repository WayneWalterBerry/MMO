# Mutation Graph Linter — Implementation Plan (Phase 1)

**Author:** Bart (Architecture Lead)
**Requested by:** Wayne "Effe" Berry
**Date:** 2026-08-23
**Revised:** 2026-08-23 (team review — 9 agents, all findings incorporated)
**Status:** PLAN — Team-reviewed, WAVE-0 ready (no open questions)
**Version:** v2.0
**Source:** `plans/linter/mutation-graph-linter-design.md` (revised expand-and-lint approach)
**Reviewers:** Nelson (QA), Smithers (UI), Flanders (Objects), Moe (Rooms), Sideshow Bob (Puzzles), Brockman (Docs), Gil (CI), CBG (Design), Bart (self-review)

---

## Status Tracker

| Wave | Status | Gate | Status |
|------|--------|------|--------|
| WAVE-0: Lua Edge Extractor | ✅ Complete | GATE-0 | ✅ Pass |
| WAVE-1: Meta-Lint Integration | ✅ Complete | GATE-1 | ✅ Pass |
| WAVE-2: Full Run + Docs + Issues | ✅ Complete | — | — |

---

## Executive Summary

Build a Lua edge extractor (~130-190 LOC) that scans all `.lua` files under `src/meta/`, extracts mutation edges from **12 mechanisms** (including 7 creature-specific patterns [Flanders]), verifies target files exist, and outputs target file paths. Pipe those paths to the existing Python meta-lint (`scripts/meta-lint/lint.py`) for full 200+ rule validation.

**Why this approach (per Wayne's direction):**
- No custom graph library, no BFS/DFS, no cycle detection — the extractor just walks files and checks edges
- No duplicate validation code — the existing linter (200+ rules, fix_safety, `--env` profiles) applies to ALL mutation targets for free
- Edge existence checking is a simple file-exists test
- Dynamic mutations flagged but not followed (same as original design)
- Two tools, each doing what it's good at: Lua loads Lua objects; Python lints them
- Circular chains (A→B→A) are irrelevant — the extractor checks each edge independently, not chains [Nelson #14]

**Key deliverables:**
1. `scripts/mutation-edge-check.lua` — Lua edge extractor (~130-190 LOC)
2. `test/meta/test-edge-extractor.lua` — Tests for the extractor
3. `scripts/mutation-lint.ps1` — Wrapper that runs both tools (sequential output collection [Smithers blocker #2])
4. `docs/testing/mutation-graph-linting.md` — Documentation (with motivation section [Brockman #1])
5. `.squad/skills/mutation-graph-lint/SKILL.md` — Reusable skill
6. GitHub issues filed for all broken edges

**Scope:** 3 waves, 2 gates, 3+ agents (Bart, Nelson, Brockman, Gil). Estimated ~5-6 hours total.

**Deferred to WAVE-2:** `--json` output mode [Smithers blocker #1 / Wayne approved] — no consumer specified for WAVE-0/1.

**Deferred to Phase 2:** Multi-hop chain validation (A→B→C complete chain checking) [CBG]. Document as D-MUTATION-CYCLES-V2 future work.

---

## Quick Reference Table

| Wave | Agent(s) | Deliverables | Gate |
|------|----------|-------------|------|
| WAVE-0 | Bart, Nelson (parallel) | `scripts/mutation-edge-check.lua`, `test/meta/test-edge-extractor.lua` | GATE-0: Extractor finds 4 broken targets (5 edge entries), all tests pass |
| WAVE-1 | Bart, Nelson (parallel) | `scripts/mutation-lint.ps1`, `scripts/mutation-lint.sh`, integration tests | GATE-1: Full pipeline runs, targets lint without crash [Nelson #12], Python pre-check passes |
| WAVE-2 | Brockman, Bart, Nelson, Gil | Docs, skill file, `--json` flag, CI integration, full run, issue filing | — (final deliverable) |

---

## Dependency Graph

```
WAVE-0: Lua Edge Extractor
  │  Bart: scripts/mutation-edge-check.lua
  │  Nelson: test/meta/test-edge-extractor.lua (parallel — different file)
  │
  ▼
GATE-0 ── extractor: 4 broken targets (5 edges) detected, paper.lua dynamic flagged, all tests pass
  │
  ▼
WAVE-1: Meta-Lint Integration
  │  Bart: scripts/mutation-lint.ps1 (wrapper)
  │  Nelson: integration test (piped output → lint)
  │
  ▼
GATE-1 ── full pipeline: edge check + lint on targets, zero crashes (not zero violations) [Nelson #12]
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
| Edge extractor | Bart | `scripts/mutation-edge-check.lua` | New file (~130-190 LOC) [Flanders: +30-40 LOC for creature edges] |
| Extractor tests | Nelson | `test/meta/test-edge-extractor.lua` | New file (~80-120 LOC) |

**File ownership:** No conflicts — Bart writes the script, Nelson writes the tests (different files). Nelson also owns `test/run-tests.lua` (per D-TEST-SPEED-IMPL-WAVES).

#### `scripts/mutation-edge-check.lua` — Specification

**CLI interface:**
```
lua scripts/mutation-edge-check.lua [options]

Options:
  --targets         Output only valid target file paths (one per line) [Smithers #5: shortened from --targets-only]
                    Broken edges go to stderr in WARNING: format. Designed for piping to lint.py.
  (default)         Human-readable report with broken edges and stats
```

> **`--json` deferred to WAVE-2** [Smithers blocker #1 / Wayne approved]. No consumer in WAVE-0/1. Schema will be defined when implemented — see WAVE-2 deliverables.

**Functions (5):**

1. **`scan_meta_root(root)`**
   - Input: `"src/meta"` (relative to repo root)
   - Output: Array of `{ filepath, id }` where `id` is extracted from the filename (strip `.lua`)
   - Behavior: Two-pass scan via `io.popen`. Discovers ALL subdirs at runtime (must find ≥ 7 subdirectories including `objects/`, `creatures/`, `injuries/`, `rooms/`, `templates/`, `levels/`, `materials/`) [Nelson #7, #8].
   - Platform: `dir /b /ad` (Windows) / `ls -d */` (Unix) for subdirs; `dir /b *.lua` / `ls *.lua` for files. Include `2>nul` (Windows) / `2>/dev/null` (Unix) error suppression — same pattern as `test/run-tests.lua` lines 243-245.
   - **Note:** `src/meta/worlds/` will be auto-discovered when it exists — scanner is future-proof [Wayne Q3 answer].

2. **`safe_load(filepath)`**
   - Input: Path to `.lua` file
   - Output: `table, nil` | `nil, error_string`
   - Behavior: `loadfile()` with restricted env matching engine sandbox (`math`, `string`, `table`, `pairs`, `ipairs`, `next`, `select`, `tostring`, `tonumber`, `type`, `unpack or table.unpack`, `error`, `pcall`, `print` = no-op, `require` = stub). `pcall(fn)`. **Validates result is a table — non-table returns yield `nil, "did not return a table"` [Nelson #4].**
   - Lua 5.4: `loadfile(filepath, "t", env)`. Lua 5.1 fallback: `loadfile()` + `setfenv(fn, env)`.
   - **Must match `src/engine/loader/init.lua` `make_sandbox()` — see version-branching pattern at lines 70-76.**

3. **`extract_edges(obj, source_id)`**
   - Input: Loaded object table, source ID (and `source_filepath` for error messages [Smithers #9])
   - Output: `edges[]`, `dynamics[]`
   - Extracts from **12 mechanisms** (5 original + 7 creature-specific [Flanders]):
     
     **Original 5:**
     - `mutations[verb].becomes` — file-swap mutation
     - `mutations[verb].spawns[]` — spawn on mutation
     - `transitions[i].spawns[]` — spawn on FSM transition
     - `crafting[verb].becomes` — crafting recipe
     - `on_tool_use.when_depleted` — tool depletion (100% theoretical — all tests use synthetic fixtures [Nelson #2])
     
     **Creature-specific 7 [Flanders]:**
     - `loot_table.always[].template` — guaranteed loot drops
     - `loot_table.on_death[].item.template` — weighted loot (note: nested in `.item`)
     - `loot_table.variable[].template` — variable-quantity loot
     - `loot_table.conditional.{key}[].template` — kill-method-gated loot
     - `death_state.crafting[verb].becomes` — corpse cooking (nested 2 levels deep!)
     - `death_state.butchery_products.products[].id` — butchery products
     - `behavior.creates_object.template` — creature-spawned objects (e.g., spider → spider-web)
   
   - `dynamic == true` → add to dynamics, skip edges
   - `becomes == nil` → intentional destruction, NOT an edge
   - `mutations = {}` (empty table) → zero edges, zero errors [Nelson #5]
   - **Circular chains (A→B→A) are irrelevant** — the extractor checks each edge independently, not chains [Nelson #14]
   - Each edge record includes `source_filepath` for developer-friendly error output [Smithers #9]
   - **`death_state` recursive pass:** After top-level extraction, also check `obj.death_state` with the same extraction logic for nested `crafting` and `butchery_products` [Flanders Risk #1]
   - **Skip `parts` for Phase 1** — composition edges are a different validation concern [Flanders recommendation #4]

4. **`resolve_target(target_id, file_map)`**
   - Input: Target ID (e.g., `"cloth"`), map of `id → filepath`
   - Output: Filepath if found, nil if broken
   - Simple lookup: `file_map[target_id]`

5. **`main(root)`**
   - Orchestrator. Scans files, loads each, extracts edges, resolves targets.
   - Builds `file_map` (id → filepath) from all scanned files for O(1) lookups.
   - Returns: `{ files_scanned, edges, broken, dynamics, valid_targets }`
   - Prints report or targets list based on CLI flag (`--targets`).

**Exit codes:**
- `0` — No broken edges
- `1` — One or more broken edges found

#### `test/meta/test-edge-extractor.lua` — Specification

Uses `test/parser/test-helpers.lua` (existing framework). Tests the extractor functions by importing them or by running the script and checking output.

**Test suites (~40-55 tests):**

| Suite | Tests | Description |
|-------|-------|-------------|
| File scanning | ~7 | `scan_meta_root` discovers expected subdirs, returns .lua files, no hardcoded list; **scanner finds files in `materials/`, `creatures/`, `injuries/`** [Nelson #7]; **scanner discovers ≥ 7 subdirectories** [Nelson #8] |
| Sandbox loading | ~7 | `safe_load` loads valid objects, returns nil for bad files, sandboxes correctly; **non-table return yields nil + error** [Nelson #4] |
| Edge extraction | ~15 | Extracts `becomes`, `spawns`, `crafting.becomes`, `on_tool_use.when_depleted` (synthetic fixtures only [Nelson #2]), handles `becomes=nil`, handles `dynamic=true`; **empty `mutations = {}` produces zero edges** [Nelson #5]; **duplicate spawn IDs (blanket.lua cloth×2) produce 2 edges to same target** [Nelson #6]; **creature `loot_table`, `death_state.crafting`, `death_state.butchery_products`, `behavior.creates_object`** [Flanders] |
| Broken edge detection | ~5 | Finds the 4 known broken targets (5 edge entries — courtyard-kitchen-door has 2 [Flanders #3]), doesn't false-positive on valid edges |
| Dynamic flagging | ~2 | `paper.lua` flagged as dynamic, verb = `write` |
| CLI output | ~5 | Default mode shows report with success/failure footer [Smithers #14], `--targets` outputs file paths, broken edges on stderr in `WARNING:` format [Smithers #3] |
| Integration sanity | ~4 | Full run against real `src/meta/`, edge count > 20, **file count > 150** (actual is ~206) [Nelson #3] |

**Test helper note:** Use `assert_truthy(count > N)` for threshold assertions — `assert_gt` does not exist in test-helpers.lua. Document this pattern in test file header. [Nelson #1]

**Known assertions:**
- Broken targets == 4, broken edge entries == 5 (poison-gas-vent-plugged ×1, wood-splinters ×3 sources but courtyard-kitchen-door contributes 2 edges) [Flanders #3]
- Dynamic paths >= 1 (paper.lua write)
- Files scanned > 150 (actual is ~206) [Nelson #3]
- Edges found > 40 (currently ~66 with creature edges — 47 original + 19 creature [Flanders])
- Creature loot edges >= 10 [Flanders]

**Estimate:** ~2.5 hours (Bart: extractor, Nelson: tests — parallel). Increased from 2h due to creature edge extraction [Flanders].

---

### GATE-0: Edge Extractor Works

| Criterion | Verification |
|-----------|-------------|
| `scripts/mutation-edge-check.lua` exists and runs | `lua scripts/mutation-edge-check.lua` exits without crash |
| 4 broken targets detected (5 edge entries) | `lua scripts/mutation-edge-check.lua 2>&1 \| grep "poison-gas-vent-plugged"` returns 1 line; `grep "wood-splinters"` returns 3 lines [Nelson #11] |
| `paper.lua` dynamic flagged | `lua scripts/mutation-edge-check.lua 2>&1 \| grep "paper"` shows dynamic path |
| Creature edges extracted | `lua scripts/mutation-edge-check.lua 2>&1 \| grep "loot\|butchery\|corpse-cooking\|creates-object"` returns ≥ 1 line per type [Flanders, Nelson #11] |
| `--targets` outputs file paths | `lua scripts/mutation-edge-check.lua --targets \| Measure-Object -Line` shows > 0 valid targets [Smithers #5: renamed flag] |
| All tests pass | `lua test/meta/test-edge-extractor.lua` — zero failures |
| No regressions | `lua test/run-tests.lua` — full suite passes |

**Binary pass/fail:** All 7 criteria must pass.

---

### WAVE-1: Meta-Lint Integration

**Purpose:** Wire the Lua extractor output to the Python meta-lint for full rule coverage on all mutation targets.

| Task | Agent | File | Action |
|------|-------|------|--------|
| Wrapper script | Bart | `scripts/mutation-lint.ps1` | New file — runs both tools, collects output per-file [Smithers blocker #2] |
| Shell wrapper | Bart | `scripts/mutation-lint.sh` | New file — Unix equivalent, sequential phases [Smithers blocker #2] |
| Integration test | Nelson | `test/meta/test-mutation-lint-integration.lua` | Verifies piped output works, Python availability guard [Nelson #13] |

#### `scripts/mutation-lint.ps1` — Specification

```powershell
# Mutation Lint — Full Pipeline with Sequential Output Collection
# Decision: D-MUTATION-LINT-PARALLEL — parallel lint per-file, sequential output display [Smithers blocker #2]
# Step 1: Edge check (broken edges report)
# Step 2: Lint all valid targets — collect output per-file, then print sequentially

param(
    [switch]$EdgesOnly,    # Skip lint step, just check edges
    [string]$Format = "text",
    [string]$Env = $null,
    [int]$ThrottleLimit = 4  # Parallel lint workers
)

# Pre-check: Python availability [Nelson #13, Gil #4]
if (-not $EdgesOnly) {
    $pythonCheck = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonCheck) {
        Write-Error "Python not found — required for lint step. Install Python or use -EdgesOnly."
        exit 2
    }
}

Write-Host "=== Phase 1: Edge Existence Check ==="

# Step 1: Edge check
$edgeResult = lua scripts/mutation-edge-check.lua
$edgeExit = $LASTEXITCODE
if ($edgeExit -ne 0) {
    Write-Host "`n⚠ Broken mutation edges found (see above)"
}

if (-not $EdgesOnly) {
    Write-Host "`n=== Phase 2: Target Lint Validation ==="

    # Step 2: Lint all valid targets
    $targets = lua scripts/mutation-edge-check.lua --targets
    # Build optional --env argument
    $envArg = if ($Env) { @("--env", $Env) } else { @() }

    if ($targets) {
        # [Smithers blocker #2] Collect output per-file, then print sequentially
        # PS7 path: ForEach-Object -Parallel [Gil #4]
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $results = $targets | ForEach-Object -Parallel {
                $output = python scripts/meta-lint/lint.py $_ --format $using:Format @using:envArg 2>&1
                [PSCustomObject]@{ File = $_; Output = $output }
            } -ThrottleLimit $ThrottleLimit

            foreach ($r in $results) {
                if ($r.Output) {
                    Write-Host "`n--- $($r.File) ---"
                    Write-Host $r.Output
                }
            }
        } else {
            # [Gil #4] Fallback for PS5: sequential execution (no -Parallel)
            Write-Warning "PowerShell < 7 detected — running lint sequentially (install PS7 for parallel)"
            foreach ($t in $targets) {
                $output = python scripts/meta-lint/lint.py $t --format $Format @envArg 2>&1
                if ($output) {
                    Write-Host "`n--- $t ---"
                    Write-Host $output
                }
            }
        }
    }

    Write-Host "`n=== Summary ==="
    Write-Host "Edge check exit code: $edgeExit"
}
```

#### `scripts/mutation-lint.sh` — Specification

```bash
#!/bin/bash
# Mutation Lint — Full Pipeline with Sequential Output Collection
# Decision: D-MUTATION-LINT-PARALLEL [Smithers blocker #2: sequential phases, parallel per-file]
WORKERS=${1:-4}

# Pre-check: Python availability [Nelson #13, Gil #4]
if ! command -v python &>/dev/null; then
    echo "ERROR: Python not found — required for lint step." >&2
    echo "Run 'lua scripts/mutation-edge-check.lua' alone for edge checking without Python." >&2
    exit 2
fi

echo "=== Phase 1: Edge Existence Check ==="

# Step 1: Edge check — runs FIRST, completes before lint [Smithers blocker #2: no concurrent output]
lua scripts/mutation-edge-check.lua
EDGE_EXIT=$?
if [ $EDGE_EXIT -ne 0 ]; then
    echo ""
    echo "⚠ Broken mutation edges found (see above)"
fi

echo ""
echo "=== Phase 2: Target Lint Validation ==="

# Step 2: Lint targets in parallel, collect output per-file then display [Smithers blocker #2]
OUTDIR=$(mktemp -d)
lua scripts/mutation-edge-check.lua --targets | xargs -P "$WORKERS" -I {} sh -c '
    OUTFILE="$1/$(echo "$2" | tr "/" "_")"
    python scripts/meta-lint/lint.py "$2" > "$OUTFILE" 2>&1
' _ "$OUTDIR" {}

# Print collected results sequentially
for f in "$OUTDIR"/*; do
    [ -s "$f" ] && {
        TARGET=$(basename "$f" | tr "_" "/")
        echo ""
        echo "--- $TARGET ---"
        cat "$f"
    }
done
rm -rf "$OUTDIR"

echo ""
echo "=== Summary ==="
echo "Edge check exit code: $EDGE_EXIT"
```

#### Integration Test

Nelson writes a test that:
1. **Python availability guard:** Check `io.popen("python --version")` — if Python unavailable, skip lint tests gracefully with a message (not a failure) [Nelson #13]
2. Runs `lua scripts/mutation-edge-check.lua --targets` [Smithers #5: renamed flag]
3. Verifies output is one filepath per line
4. Verifies each listed file actually exists
5. Verifies known targets appear (e.g., `cloth.lua`, `glass-shard.lua`)
6. Runs `python scripts/meta-lint/lint.py {first target}` — verifies it exits **without crash** (exit 0 or 1 both acceptable — "no crash" not "no violations") [Nelson #12]

**Estimate:** ~1.5 hours (Bart: wrapper scripts with output collection, Nelson: integration test — parallel). Increased from 1h due to parallel output fix.

---

### GATE-1: Full Pipeline Works

| Criterion | Verification |
|-----------|-------------|
| Wrapper runs without crash | `.\scripts\mutation-lint.ps1` completes (PS7) or `.\scripts\mutation-lint.ps1` with sequential fallback (PS5) [Gil #4] |
| Python pre-check works | `.\scripts\mutation-lint.ps1` with Python absent prints error + exits 2 (not crash) [Nelson #13] |
| Edge check + lint both execute | Both Phase 1 and Phase 2 sections produce output with section headers [Smithers blocker #2] |
| Targets lint without crash | Python linter runs on each target **without crashing** — exit 0 (clean) or exit 1 (violations found) both acceptable. "Lint successfully" means "no crash," NOT "no violations." [Nelson #12] |
| Output is not interleaved | Parallel lint results are collected per-file and printed sequentially with `--- {file} ---` headers [Smithers blocker #2] |
| Integration test passes | `lua test/meta/test-mutation-lint-integration.lua` — zero failures |
| No regressions | `lua test/run-tests.lua` — full suite passes |

**Binary pass/fail:** All 7 criteria must pass.

---

### WAVE-2: Full Run + Docs + Issues + Deferred Features

**Purpose:** Run the full pipeline, write documentation, create skill file, implement `--json` flag, CI integration, file GitHub issues for all broken edges.

| Task | Agent | File | Action |
|------|-------|------|--------|
| Documentation | Brockman | `docs/testing/mutation-graph-linting.md` | New file — per Phase 1 spec, with "Motivation" section [Brockman #1] and real-world example trace [Brockman #2] |
| Design doc motivation | Brockman | `plans/linter/mutation-graph-linter-design.md` | Add "Motivation" section [Brockman #1] |
| Skill file | Bart | `.squad/skills/mutation-graph-lint/SKILL.md` | New file — per Phase 3 spec |
| `--json` flag | Bart | `scripts/mutation-edge-check.lua` | Implement JSON output mode [Smithers blocker #1, deferred from WAVE-0] |
| JSON tests | Nelson | `test/meta/test-edge-extractor.lua` | Add JSON output tests |
| docs/README.md update | Brockman | `docs/README.md` | Add meta-lint and testing sections [Brockman #3] |
| Mutation doc cross-ref | Brockman | `docs/architecture/engine/` | Cross-reference to meta-lint docs [Brockman #5] |
| scripts/meta-lint/README.md | Brockman | `scripts/meta-lint/README.md` | Flag for creation — edge checker integration docs [Brockman #4] |
| CI: Python + lint step | Gil | `.github/workflows/squad-ci.yml` | Add Python setup + mutation-edge-check step [Gil #1] |
| CI: Pre-deploy gate | Gil | `test/run-before-deploy.ps1` | Add lightweight edge-check [Gil #2] |
| CI: .gitattributes | Gil | `.gitattributes` | Add line-ending rules for .sh/.ps1 [Gil #3] |
| Full pipeline run | Nelson | — | Run `mutation-lint.ps1`, capture output |
| Issue filing | Nelson + Bart | GitHub | File issues for 4 broken targets + any lint violations |

**Issue filing rules:** Per Phase 4 of the design doc. Broken edges → squad:flanders. **Exception: `courtyard-kitchen-door` → `wood-splinters` routes to squad:moe (room boundary issue, not object)** [CBG routing correction].

**`--json` schema** (defined for WAVE-2 implementation) [Smithers blocker #1]:
```json
{
  "summary": {
    "files_scanned": 206,
    "edges_found": 66,
    "broken_targets": 4,
    "broken_edges": 5,
    "dynamic_paths": 1,
    "valid_targets": 62
  },
  "broken": [
    { "from": "poison-gas-vent", "to": "poison-gas-vent-plugged", "type": "file-swap", "verb": "plug", "source_file": "src/meta/objects/poison-gas-vent.lua" }
  ],
  "dynamic": [
    { "from": "paper", "verb": "write", "mutator": "write_on_surface" }
  ]
}
```

**Future work documented:**
- D-MUTATION-CYCLES-V2: Multi-hop chain validation (A→B→C) [CBG]
- `parts[].id` extraction for static composition references [Flanders recommendation]

**Estimate:** ~2 hours (Brockman: docs, Bart: skill + --json, Nelson: run + issues, Gil: CI — all parallel). Increased from 1.5h due to additional deliverables.

---

## Testing Gates

### Test File Map

| File | Coverage | Agent |
|------|----------|-------|
| `test/meta/test-edge-extractor.lua` | Lua extractor: scanning, loading, extraction (12 mechanisms), broken edges, dynamic, CLI, creature edges | Nelson |
| `test/meta/test-mutation-lint-integration.lua` | Full pipeline: extractor → lint piping, target validity, Python availability guard | Nelson |

### Test Runner Registration [Nelson #9, #10]

**`test/run-tests.lua` changes:**
- Add `test/meta` to `test_dirs` array
- Add `source_to_tests` mapping: `["scripts/mutation-edge-check.lua"] = {"meta"}` [Nelson #9]
- **Shard assignment:** `test/meta/` falls in the `"other"` shard catch-all (per D-TEST-SPEED-IMPL-WAVES shard definitions). Document this — no explicit shard entry needed. [Nelson #10]

### Regression Baseline

Record test count before WAVE-0 and verify unchanged after each gate.

---

## Feature Breakdown

### Lua Edge Extractor (`scripts/mutation-edge-check.lua`)

**What it does:** Walks all `.lua` files under `src/meta/`, loads each in a Lua sandbox, extracts mutation edges from **12 mechanisms** (5 original + 7 creature-specific [Flanders]), checks if each target file exists, reports broken edges with source file paths [Smithers #9].

**What it does NOT do:**
- No graph library (no nodes/edges data structure beyond simple arrays)
- No BFS/DFS traversal
- No cycle detection (not needed — edges are checked independently [Nelson #14])
- No unreachable node detection
- No multi-hop chain validation (deferred to Phase 2 / D-MUTATION-CYCLES-V2 [CBG])
- No test-harness integration (it's a script, not a test)
- No `parts[]` extraction (composition, not mutation [Flanders recommendation])

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
| Lua extractor | test/run-tests.lua | Test file registered in `test/meta/` dir; source_to_tests mapping [Nelson #9] |
| Python meta-lint | squad_routing.py | Lint violations routed to correct agent |
| Wrapper scripts | squad-ci.yml | CI runs edge-check + lint [Gil #1] |
| Edge checker | run-before-deploy.ps1 | Pre-deploy gate includes lightweight edge-check [Gil #2] |

---

## Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| `io.popen` platform differences | Extractor fails on Unix | Same cross-platform pattern as `test/run-tests.lua` — proven working |
| Python not installed | Lint step fails | Edge check still works standalone; wrapper script checks for Python and exits 2 with clear error [Nelson #13] |
| New mutation mechanism added | Extractor misses edges | `extract_edges()` is the single place to update — documented in skill. 12 mechanisms documented with data paths. |
| Large file count slows lint | Pipeline takes minutes | Python linter has incremental caching; `--no-cache` only for full runs |
| Sandbox doesn't match engine loader | Objects fail to load | Sandbox mirrors `engine/loader/init.lua` `make_sandbox()` — same restricted env. **Must use Lua 5.4 `loadfile(filepath, "t", env)` pattern (not 5.1 `setfenv`).** |
| Creature `death_state` nesting missed | 8 edges invisible | Recursive extraction pass on `obj.death_state` — same logic applied at 2nd level [Flanders Risk #1] |
| `loot_table` inconsistent nesting | Loot edges missed | 4 sub-pattern extractors handle all shapes: `always`, `on_death` (`.item` wrapper), `variable`, `conditional` (extra key level) [Flanders Risk #2] |
| PS7 not available | `-Parallel` fails | PowerShell version check: PS7+ uses `-Parallel`, PS5 falls back to sequential with warning [Gil #4] |
| Parallel output interleaving | Unreadable output | Wrapper scripts collect per-file output, print sequentially with section headers [Smithers blocker #2] |
| `courtyard-kitchen-door` double spawn | Assertion confusion | Distinguish: 4 broken targets vs 5 broken edge entries. Gate asserts on target count. [Flanders #3] |
| Shell scripts have wrong line endings | Scripts fail on Unix/Windows | `.gitattributes` rules for `.sh` (LF) and `.ps1` (CRLF) [Gil #3] |

---

## Autonomous Execution Protocol

- WAVE-0 → parallel (Bart + Nelson) → GATE-0 → pass? → WAVE-1
- WAVE-1 → parallel (Bart + Nelson) → GATE-1 → pass? → WAVE-2
- WAVE-2 → parallel (Brockman + Bart + Nelson + Gil) → DONE
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
| `docs/README.md` (meta-lint + testing sections) | Brockman | WAVE-2 [Brockman #3] |
| `scripts/meta-lint/README.md` (edge checker integration) | Brockman | WAVE-2 [Brockman #4] |
| Mutation doc cross-reference to `docs/meta-lint/` | Brockman | WAVE-2 [Brockman #5] |
| `.squad/skills/mutation-graph-lint/SKILL.md` | Bart | WAVE-2 |
| `.gitattributes` (line endings for .sh/.ps1) | Gil | WAVE-2 [Gil #3] |
| This plan (status updates) | Bart | Every wave |

---

## Output Format Specification

### Default Mode (human-readable report)

[Smithers #2: no indent on stat block, #14: success/failure footer, #1: ⚠ for dynamic]

```
=== Mutation Edge Report ===
Files scanned:   206
Edges found:     66
Broken targets:  4 (5 edge entries)
Dynamic paths:   1 (skipped)
Valid targets:   62

Broken edges:
  ✗ src/meta/objects/poison-gas-vent.lua -> poison-gas-vent-plugged (file-swap via plug)
  ✗ src/meta/objects/bedroom-hallway-door-north.lua -> wood-splinters (spawn-transition via break)
  ✗ src/meta/objects/bedroom-hallway-door-south.lua -> wood-splinters (spawn-transition via break)
  ✗ src/meta/rooms/courtyard-kitchen-door.lua -> wood-splinters (spawn-transition via break) [×2 edges]

Dynamic paths (not followed):
  ⚠ paper -> write (mutator: write_on_surface)

✗ 4 broken target(s) — files do not exist. See above.
```

When zero broken edges [Smithers #14]:
```
✓ All mutation edges resolve to existing files.
```

### `--targets` Mode (pipe-friendly) [Smithers #5: renamed from --targets-only]

**stdout:** One valid target filepath per line.
```
src/meta/objects/cloth.lua
src/meta/objects/glass-shard.lua
src/meta/objects/terrible-jacket.lua
...
```

**stderr:** [Smithers #3: specified format]
```
WARNING: broken edge: poison-gas-vent -> poison-gas-vent-plugged (file-swap via plug) [src/meta/objects/poison-gas-vent.lua]
WARNING: broken edge: bedroom-hallway-door-north -> wood-splinters (spawn-transition via break) [src/meta/objects/bedroom-hallway-door-north.lua]
WARNING: broken edge: bedroom-hallway-door-south -> wood-splinters (spawn-transition via break) [src/meta/objects/bedroom-hallway-door-south.lua]
WARNING: broken edge: courtyard-kitchen-door -> wood-splinters (spawn-transition via break) [src/meta/rooms/courtyard-kitchen-door.lua]
WARNING: 4 broken target(s) found. Run without --targets for full report.
```

Uses `WARNING:` prefix to match `lint.py`'s stderr convention [Smithers #3].

---

## Creature Edge Extraction Spec [Flanders]

Added ~30-40 LOC to `extract_edges()` for 7 creature-specific mechanisms. All 19 edges currently resolve (0 new broken edges), but extraction is needed to catch future regressions.

### Extraction Logic (creature-specific additions)

```lua
-- 5. Loot table — 4 sub-patterns [Flanders]
if obj.loot_table then
    -- 5a. Always drops
    if obj.loot_table.always then
        for _, entry in ipairs(obj.loot_table.always) do
            if entry.template then
                table.insert(edges, { from = source_id, to = entry.template, type = "loot-always", verb = "kill", source_file = source_filepath })
            end
        end
    end
    -- 5b. Weighted on_death drops (note: wrapped in .item)
    if obj.loot_table.on_death then
        for _, entry in ipairs(obj.loot_table.on_death) do
            if entry.item and entry.item.template then
                table.insert(edges, { from = source_id, to = entry.item.template, type = "loot-weighted", verb = "kill", source_file = source_filepath })
            end
        end
    end
    -- 5c. Variable-quantity drops
    if obj.loot_table.variable then
        for _, entry in ipairs(obj.loot_table.variable) do
            if entry.template then
                table.insert(edges, { from = source_id, to = entry.template, type = "loot-variable", verb = "kill", source_file = source_filepath })
            end
        end
    end
    -- 5d. Conditional (kill-method gated) — extra nesting level
    if obj.loot_table.conditional then
        for method, entries in pairs(obj.loot_table.conditional) do
            for _, entry in ipairs(entries) do
                if entry.template then
                    table.insert(edges, { from = source_id, to = entry.template, type = "loot-conditional", verb = "kill:" .. method, source_file = source_filepath })
                end
            end
        end
    end
end

-- 6. Creature-spawned objects [Flanders]
if obj.behavior and obj.behavior.creates_object and obj.behavior.creates_object.template then
    table.insert(edges, { from = source_id, to = obj.behavior.creates_object.template, type = "creates-object", verb = "behavior", source_file = source_filepath })
end

-- 7. death_state recursive pass [Flanders Risk #1]
if obj.death_state then
    -- 7a. Corpse cooking (death_state.crafting — nested 2 levels deep)
    if obj.death_state.crafting then
        for verb, recipe in pairs(obj.death_state.crafting) do
            if recipe.becomes then
                table.insert(edges, { from = source_id, to = recipe.becomes, type = "corpse-cooking", verb = verb, source_file = source_filepath })
            end
        end
    end
    -- 7b. Butchery products
    if obj.death_state.butchery_products and obj.death_state.butchery_products.products then
        for _, product in ipairs(obj.death_state.butchery_products.products) do
            if product.id then
                table.insert(edges, { from = source_id, to = product.id, type = "butchery", verb = "butcher", source_file = source_filepath })
            end
        end
    end
end
```

### Creature Edge Summary [Flanders]

| Mechanism | Data Path | Edges Today | Currently Broken |
|-----------|-----------|-------------|------------------|
| Loot (always) | `loot_table.always[].template` | 2 | 0 |
| Loot (on_death) | `loot_table.on_death[].item.template` | 3 | 0 |
| Loot (variable) | `loot_table.variable[].template` | 1 | 0 |
| Loot (conditional) | `loot_table.conditional.{key}[].template` | 4 | 0 |
| Corpse cooking | `death_state.crafting[verb].becomes` | 3 | 0 |
| Butchery | `death_state.butchery_products.products[].id` | 5 | 0 |
| Creates object | `behavior.creates_object.template` | 1 | 0 |
| **Total new** | | **19** | **0** |

---

## Resolved Review Questions

All open questions from v1.0 are now resolved. No blockers remain.

| Question | Resolution | Source |
|----------|------------|--------|
| D-MUTATION-LINT-PARALLEL — is this a real decision? | Yes — filed as decision. Parallel lint per-file, sequential output display. | Wayne (default approved) |
| `--json` flag — define schema now or defer? | Defer to WAVE-2. No consumer in WAVE-0/1. Schema defined in WAVE-2 section above. | [Smithers blocker #1] / Wayne approved |
| `src/meta/worlds/` — scan it? | Scanner auto-discovers all subdirs. worlds/ will be picked up when it exists. Fine to scan. | Wayne (default approved) |
| Shell double-scan overhead (~1s) | Accept. Parallel lint is the goal; 1s overhead is negligible vs lint runtime. | Wayne (default approved) |
| Broken edge count: 4 or 5? | 4 unique broken targets, 5 broken edge entries. Gate asserts on target count (4). | [Flanders #3] |
| `courtyard-kitchen-door` routing | Routes to squad:moe (room boundary issue), not squad:flanders. | [CBG routing correction] |
| Circular chains (A→B→A) | Irrelevant — extractor checks each edge independently, not chains. | [Nelson #14] |
| Multi-hop validation (A→B→C) | Deferred to Phase 2. Documented as D-MUTATION-CYCLES-V2 future work. | [CBG] |

---

## Team Review Attribution Index

Every change from v1.0 → v2.0 is tagged with the reviewer who raised it:

| Tag | Reviewer | Items |
|-----|----------|-------|
| [Nelson #1-#14] | Nelson (QA) | 14 items: test helpers, thresholds, new test cases, verification commands, Python guards, circular chains |
| [Smithers blocker #1-#2] | Smithers (UI) | 2 blockers: --json schema deferral, parallel output interleaving |
| [Smithers #1-#14] | Smithers (UI) | 14 items: symbol vocabulary, indentation, stderr format, CLI naming, file paths in errors, success footer |
| [Flanders] | Flanders (Objects) | 7 creature edge mechanisms (19 edges), death_state nesting, courtyard double-spawn, parts skip |
| [Moe] | Moe (Rooms) | All clear — rooms have zero mutations, triggers excluded correctly |
| [Sideshow Bob] | Sideshow Bob (Puzzles) | All clear — 7 crafting chains covered, nested chains work passively |
| [Brockman #1-#5] | Brockman (Docs) | 5 items: motivation section, example traces, README updates, cross-references |
| [Gil #1-#4] | Gil (CI) | 4 items: CI Python+lint step, pre-deploy gate, .gitattributes, PS7 fallback |
| [CBG] | Comic Book Guy (Design) | 3 items: courtyard routing to Moe, multi-hop as Phase 2, D-MUTATION-CYCLES-V2 |
