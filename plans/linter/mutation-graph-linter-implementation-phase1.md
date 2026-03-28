# Mutation Graph Linter — Implementation Plan (Phase 1)

**Author:** Bart (Architecture Lead)
**Requested by:** Wayne "Effe" Berry
**Date:** 2026-08-22
**Status:** PLAN — Ready for review
**Version:** v1.0
**Source:** `plans/linter/mutation-graph-linter-design.md` (all 4 design phases)

---

## Status Tracker

| Wave | Status | Gate | Status |
|------|--------|------|--------|
| WAVE-0: Pre-flight | ⏳ Pending | GATE-0 | ⏳ |
| WAVE-1: Core Implementation | ⏳ Pending | GATE-1 | ⏳ |
| WAVE-2: Docs + Skill + Verify | ⏳ Pending | GATE-2 | ⏳ |
| WAVE-3: Full Run + Issue Filing | ⏳ Pending | — | — |

---

## Executive Summary

Build a pure-Lua mutation graph linter that statically validates all mutation edges across every `.lua` file under `src/meta/`. The linter discovers files dynamically (no hardcoded directory list), extracts 6 mutation mechanism types, builds a directed graph, detects cycles, and reports broken edges. It runs as a standard test file within `test/run-tests.lua`.

**Key deliverables:**
1. `test/meta/test-mutation-graph.lua` — Graph library + 7 test suites (~240-260 tests)
2. `docs/testing/mutation-graph-linting.md` — Documentation for the linter
3. `.squad/skills/mutation-graph-lint/SKILL.md` — Reusable skill document
4. GitHub issues filed for all broken edges discovered

**Scope:** 4 waves, 3 gates, 3 agents (Bart, Nelson, Brockman). Estimated ~6 hours total.

**Architecture decision:** Single-file pattern. The graph library and test harness coexist in `test/meta/test-mutation-graph.lua`, consistent with existing test file patterns in this project. This means WAVE-1 is single-author (Bart) — no parallel file edits possible within the test file itself.

---

## Quick Reference Table

| Wave | Agent(s) | Deliverables | Gate |
|------|----------|-------------|------|
| WAVE-0 | Nelson | Create `test/meta/`, register in `test/run-tests.lua` | GATE-0: Runner discovers test/meta |
| WAVE-1 | Bart | `test/meta/test-mutation-graph.lua` (graph lib + 7 suites) | GATE-1: 240+ tests pass, 4 broken edges detected |
| WAVE-2 | Brockman, Bart, Nelson | Docs, skill file, verification run | GATE-2: Full suite zero regressions, docs complete |
| WAVE-3 | Nelson, Bart | Full run, cycle review, GitHub issue filing | — (final deliverable) |

---

## Dependency Graph

```
WAVE-0: Pre-flight
  │  Nelson: create test/meta/, register in run-tests.lua
  │
  ▼
GATE-0 ── test runner discovers test/meta directory
  │
  ▼
WAVE-1: Core Implementation
  │  Bart: write test-mutation-graph.lua (graph lib + all 7 test suites)
  │
  ▼
GATE-1 ── standalone run: 240+ tests, 4 broken edges, paper.lua dynamic, matchbox cycle
  │
  ├──────────────────────┬──────────────────────┐
  ▼                      ▼                      ▼
WAVE-2a: Docs          WAVE-2b: Skill         WAVE-2c: Verify
  Brockman               Bart                   Nelson
  mutation-graph-        SKILL.md               full suite run
  linting.md                                    zero regressions
  │                      │                      │
  └──────────────────────┴──────────────────────┘
  │
  ▼
GATE-2 ── docs complete, skill created, full suite passes
  │
  ▼
WAVE-3: Full Run + Issue Filing
  │  Nelson: run linter, capture output
  │  Bart: review cycles (toggle vs bug)
  │  Bart/Nelson: file GitHub issues for broken edges
  │
  ▼
DONE ── issues filed, plan complete
```

---

## Implementation Waves

### WAVE-0: Pre-flight

**Purpose:** Establish infrastructure so test files in `test/meta/` are discovered by the test runner.

| Task | Agent | File | Action |
|------|-------|------|--------|
| Create directory | Nelson | `test/meta/` | `mkdir test\meta` |
| Register test dir | Nelson | `test/run-tests.lua` | Add `test/meta` to `test_dirs` array |
| Smoke test | Nelson | — | Run `lua test/run-tests.lua`, verify no errors from empty dir |

**File ownership:** Nelson owns `test/run-tests.lua` (established in D-TEST-SPEED-IMPL-WAVES).

**Exact change to `test/run-tests.lua`:**
Add one line to the `test_dirs` array (after the last existing entry):
```lua
repo_root .. SEP .. "test" .. SEP .. "meta",
```

**TDD:** No tests in this wave — it's infrastructure. The smoke test verifies the runner doesn't crash on an empty directory.

**Estimate:** 15 minutes.

---

### GATE-0: Runner Infrastructure

| Criterion | Verification |
|-----------|-------------|
| `test/meta/` directory exists | `Test-Path test\meta` |
| `test/run-tests.lua` includes `test/meta` | `grep "meta" test/run-tests.lua` |
| Runner doesn't crash on empty dir | `lua test/run-tests.lua` exits 0 |
| No regressions | Test count unchanged from baseline |

**Binary pass/fail:** All 4 criteria must pass.

---

### WAVE-1: Core Implementation

**Purpose:** Build the complete mutation graph linter in a single test file.

| Task | Agent | File |
|------|-------|------|
| Graph library + 7 test suites | Bart | `test/meta/test-mutation-graph.lua` |

**Single-author rationale:** The design specifies a single-file pattern (graph lib + test harness in one file). Per wave design rules, no two agents touch the same file. Bart writes the complete file.

**File structure (top to bottom):**

```
test/meta/test-mutation-graph.lua (~350-400 LOC)
├── Header / require test-helpers
├── Constants (SEP, repo_root)
├── scan_meta_root(root)          -- recursive dir scanner
├── safe_load(filepath)           -- sandboxed loader
├── extract_edges(obj, source_id) -- 6-mechanism edge extractor
├── build_graph(root)             -- orchestrator
├── detect_cycles(nodes, edges)   -- DFS coloring
├── find_unreachable(nodes, edges)-- orphan detection
├── report(graph_result, ...)     -- summary printer
├── Suite 1: File loading (~91 tests)
├── Suite 2: Required fields (~91 tests)
├── Suite 3: Edge resolution (~30 tests)
├── Suite 4: Target validity (~30 tests)
├── Suite 5: Dynamic detection (~2 tests)
├── Suite 6: Graph statistics (~6 tests)
├── Suite 7: Cycle detection (~3 tests)
└── summary()
```

#### Function Specifications

**`scan_meta_root(root)`**
- Input: `"src/meta"` (relative to repo root)
- Output: Array of file paths, e.g., `{"src/meta/objects/candle.lua", ...}`
- Behavior: Two-pass scan. First pass: enumerate subdirectories of `root` via `io.popen`. Second pass: enumerate `*.lua` files in each subdirectory. No hardcoded directory list — discovers `objects/`, `creatures/`, `injuries/`, `rooms/`, `templates/`, `levels/`, `materials/`, and any future subdirectories automatically.
- Platform: Uses `dir /b /ad` (Windows) / `ls -d */` (Unix) for subdirs, `dir /b *.lua` / `ls *.lua` for files. Same `SEP` / platform detection as `test/run-tests.lua`.

**`safe_load(filepath)`**
- Input: Absolute or relative path to a `.lua` file
- Output: `table, nil` on success; `nil, error_string` on failure
- Behavior: Uses `loadfile()` with a restricted environment providing `math`, `string`, `table`, `pairs`, `ipairs`, `tostring`, `tonumber`, `type`, `print` (no-op), `require` (stub returning `{}`). Calls `pcall(fn)` and validates the result is a table.
- Lua 5.1: Uses `setfenv(fn, env)`.
- Pattern reference: Mirrors `src/engine/loader/init.lua` sandbox approach (but does NOT import it — test is self-contained).

**`extract_edges(obj, source_id)`**
- Input: Loaded object table, source file ID
- Output: `edges[]`, `dynamics[]`
- Edge types extracted:

| # | Mechanism | Data Path | Edge Type String |
|---|-----------|-----------|-----------------|
| 1 | File-swap mutation | `mutations[verb].becomes` | `"file-swap"` |
| 2 | Mutation spawns | `mutations[verb].spawns[]` | `"spawn"` |
| 3 | Transition spawns | `transitions[i].spawns[]` | `"spawn-transition"` |
| 4 | Crafting | `crafting[verb].becomes` | `"crafting"` |
| 5 | Tool depletion | `on_tool_use.when_depleted` | `"tool-depletion"` |
| 6 | Dynamic (flagged only) | `mutations[verb].dynamic == true` | N/A (added to dynamics list) |

- `becomes = nil` handling: Intentional destruction — NOT an edge, NOT a broken link. Extraction checks `m.becomes ~= nil` before adding.
- FSM `transitions[].mutate`: Property patches, not file swaps. NOT edges. Validated for structural correctness but not added to the graph.

**`build_graph(root)`**
- Orchestrator. Calls `scan_meta_root`, then `safe_load` + `extract_edges` for each file.
- Returns: `{ nodes = {}, edges = {}, dynamics = {}, broken = {}, load_errors = {} }`
- `nodes`: Map from `id` → `{ id, filepath, template, has_on_feel, is_template }`.
- `edges`: Array of `{ from, to, type, verb }`.
- `broken`: Array of `{ from, to, type, verb, reason }` — populated after all nodes loaded by checking each edge's `to` against `nodes`.
- `load_errors`: Array of `{ filepath, error }` — files that failed sandbox loading.
- Template detection: Files from `src/meta/templates/` are flagged `is_template = true`.

**`detect_cycles(nodes, edges)`**
- DFS with 3-color marking (white/gray/black).
- Returns: Array of cycles. Each cycle is an array of node IDs forming the cycle path.
- Semantics: ALL cycles reported. 2-node A↔B cycles are "toggles" (likely intentional). 3+ node cycles are flagged for review.

**`find_unreachable(nodes, edges)`**
- Returns: Array of node IDs that have zero incoming edges AND are not templates.
- Templates excluded from unreachable report (they're base classes, not instantiable).
- Informational only — unreachable nodes are not errors.

**`report(graph_result, cycles, unreachable)`**
- Prints formatted summary to stdout (see design doc for format).
- Sections: Nodes, Edges, Broken, Dynamic, Cycles, Unreachable.

#### Test Suite Specifications

**Suite 1: File Loading (~91 dynamic tests)**
- One test per `.lua` file discovered under `src/meta/`.
- Asserts: `safe_load` returns a table (not nil).
- Dynamic count: grows automatically as content is added.

**Suite 2: Required Fields (~91 dynamic tests)**
- For each loaded object: assert `obj.id` exists.
- For objects/creatures (not injuries, templates, levels, materials, rooms): assert `obj.on_feel` exists.
- Uses `obj.template` to determine if `on_feel` is required (rooms, injuries, levels have different field requirements).

**Suite 3: Edge Resolution (~30 tests)**
- For each edge in the graph: assert `nodes[edge.to]` exists.
- Known failures (4 broken edges):
  - `poison-gas-vent` → `poison-gas-vent-plugged` (file does not exist)
  - `bedroom-hallway-door-north` → `wood-splinters` (file does not exist)
  - `bedroom-hallway-door-south` → `wood-splinters` (file does not exist)
  - `courtyard-kitchen-door` → `wood-splinters` (file does not exist)
- These are expected failures — the suite reports them but does NOT fail the test run. The broken edges are captured in `graph.broken` and validated in Suite 6.

**Suite 4: Target Validity (~30 tests)**
- For each resolved (non-broken) target: assert `target.id` exists.
- For object/creature targets: assert `target.on_feel` exists.

**Suite 5: Dynamic Detection (~2 tests)**
- Assert `dynamics` list is non-empty.
- Assert `paper` is flagged with verb `write`.

**Suite 6: Graph Statistics (~6 tests)**
- `total nodes > 80` (currently ~91+)
- `total edges > 20` (currently ~47)
- `broken edges == 4` (known count)
- `dynamic paths >= 1` (paper.lua)
- `cycles detected >= 1` (matchbox toggle)
- `load errors == 0` (all files should load)

**Suite 7: Cycle Detection (~3 tests)**
- Assert matchbox ↔ matchbox-open cycle exists.
- Assert cycle is classified as 2-node toggle.
- Assert no unexpected long cycles (3+ nodes).

#### Broken Edge Handling Strategy

The 4 known broken edges are **expected findings**, not test failures. The implementation handles them as:
1. `extract_edges` adds edges regardless of target existence.
2. `build_graph` populates `broken[]` by checking each edge's `to` against `nodes`.
3. Suite 3 reports broken edges informationally (prints them) but uses the broken list from Suite 6 for assertion.
4. Suite 6 asserts `#broken == 4` (exact known count).
5. When Flanders creates the missing files, the count drops and Suite 6 needs updating.

#### Template Inheritance Note

Per the design: "for Phase 1 simplicity: since all current instances that inherit mutations also redeclare them explicitly, template merging can be deferred." A TODO comment is added in `extract_edges()` noting that template-inherited mutations should be merged in a future pass. A placeholder test in Suite 3 verifies at least one inherited mutation from `sheet.lua` → `cloth` resolves (via the instance that redeclares it).

**Estimate:** 3-4 hours.

---

### GATE-1: Standalone Linter Passes

| Criterion | Verification |
|-----------|-------------|
| Standalone run succeeds | `lua test/meta/test-mutation-graph.lua` exits cleanly |
| Test count ≥ 240 | Summary line shows 240+ passed |
| 4 broken edges detected | Report shows exactly 4 broken edges |
| paper.lua dynamic flagged | Report shows 1+ dynamic path (paper/write) |
| matchbox cycle detected | Report shows 1+ cycle (matchbox ↔ matchbox-open) |
| Graph report accurate | Node count > 80, edge count > 20 |
| Zero load errors | All `src/meta/` files load in sandbox |

**Binary pass/fail:** All 7 criteria must pass.

**Gate reviewers:** Bart (architecture correctness), Nelson (test assertion quality).

---

### WAVE-2: Documentation + Skill + Verification

**Purpose:** Create documentation, skill file, and verify integration with the full test suite.

Three parallel tasks — no file conflicts.

| Task | Agent | File | Depends On |
|------|-------|------|-----------|
| Write linter docs | Brockman | `docs/testing/mutation-graph-linting.md` | GATE-1 (needs accurate counts) |
| Write skill doc | Bart | `.squad/skills/mutation-graph-lint/SKILL.md` | GATE-1 (needs patterns to document) |
| Full suite regression | Nelson | — (runs `lua test/run-tests.lua`) | GATE-1 (test file exists) |

#### WAVE-2a: Documentation (Brockman)

**File:** `docs/testing/mutation-graph-linting.md`

**Contents (from design Phase 1):**
1. What it validates — all 6 mutation mechanisms with table
2. How it traverses — BFS/DFS pseudocode
3. Dynamic mutations — why skipped, reference to `src/engine/mutation/init.lua`
4. Graph algorithm — pseudocode (nodes, edges, broken, dynamic, cycles)
5. Cycle semantics — toggle vs bug distinction
6. Running the linter — `lua test/meta/test-mutation-graph.lua` standalone, or via `lua test/run-tests.lua`
7. Reading the report — section-by-section explanation of output format
8. Adding new mutation mechanisms — how to extend `extract_edges()`

**Estimate:** 1 hour.

#### WAVE-2b: Skill Document (Bart)

**File:** `.squad/skills/mutation-graph-lint/SKILL.md`

**Frontmatter:**
```yaml
name: "mutation-graph-lint"
description: "Static validation of all mutation chains across meta .lua files"
domain: "testing, meta-validation, graph analysis"
confidence: "high"
source: "earned — mutation graph linter implementation"
```

**Patterns documented:**
1. Auto-discovery of `src/meta/` subdirectories (no hardcoded list)
2. Adding new edge types (add case in `extract_edges()`)
3. Sandbox loader handling function-containing objects
4. Why dynamic mutations are skipped (unbounded runtime generation)
5. Cycle report interpretation (2-node toggle vs 3+ node bug)
6. Gate integration (runs in regular suite, failures block deploy)

**Reusable gate check pattern:**
- Pre-deploy: `lua test/run-tests.lua` includes mutation graph validation
- Pre-PR: same — any broken edge count change fails the suite
- Object authoring: Flanders adds `becomes` target → linter catches missing files

**Estimate:** 30 minutes.

#### WAVE-2c: Verification (Nelson)

**Run:** `lua test/run-tests.lua` (full suite)

**Verification checklist:**
- [ ] test/meta/test-mutation-graph.lua discovered and executed
- [ ] Zero regressions — total pass count = baseline + new mutation graph tests
- [ ] No test isolation violations (mutation graph tests don't interfere with other suites)
- [ ] Report output doesn't corrupt test runner summary

**Estimate:** 30 minutes.

---

### GATE-2: Integration + Documentation

| Criterion | Verification |
|-----------|-------------|
| Full suite passes | `lua test/run-tests.lua` exits 0, zero regressions |
| Mutation graph tests included | Runner output shows `meta/test-mutation-graph.lua` |
| Docs complete | `docs/testing/mutation-graph-linting.md` exists, covers all 8 sections |
| Skill doc complete | `.squad/skills/mutation-graph-lint/SKILL.md` exists, covers all 6 patterns |
| No regressions | Pass count = baseline + mutation graph additions |

**Binary pass/fail:** All 5 criteria must pass.

**Gate reviewers:** Bart (architecture), Nelson (test integration), Brockman (docs completeness).

---

### WAVE-3: Full Run + Issue Filing

**Purpose:** Execute the linter against the live codebase, review all findings, and file GitHub issues for broken edges.

| Task | Agent | Action |
|------|-------|--------|
| Execute linter | Nelson | `lua test/meta/test-mutation-graph.lua`, capture full output |
| Review cycles | Bart | Classify each cycle as toggle (intentional) or bug |
| File broken edge issues | Bart + Nelson | One issue per unique missing target |

#### Issue Filing Rules (from design Phase 4)

Every broken edge becomes a GitHub issue:

| Broken Edge | Issue Title | Labels | Assignee |
|-------------|-------------|--------|----------|
| `poison-gas-vent` → `poison-gas-vent-plugged` | Missing mutation target: poison-gas-vent-plugged.lua | `squad:flanders`, `bug` | Flanders |
| `*-door-*` → `wood-splinters` (×3) | Missing spawn target: wood-splinters.lua | `squad:flanders`, `bug` | Flanders |
| Any future broken edge in objects/ | Missing mutation/spawn target: {file} | `squad:flanders`, `bug` | Flanders |
| Any broken edge in creatures/ | Missing creature mutation target | `squad:flanders`, `bug` | Flanders |
| Any broken edge in rooms/ | Missing room reference | `squad:moe`, `bug` | Moe |

**Issue template:**
```markdown
## Missing Mutation Target

**Source file:** `src/meta/objects/{source}.lua`
**Edge type:** {file-swap|spawn|crafting|tool-depletion}
**Verb:** `{verb}`
**Target:** `{target-id}` — file does not exist in any scanned directory

**Found by:** Mutation Graph Linter (`test/meta/test-mutation-graph.lua`)

**Fix:** Create `src/meta/objects/{target-id}.lua` with all required fields (id, template, on_feel, keywords, name, description).
```

**Consolidated issue optimization:** The 3 `wood-splinters` broken edges (from 3 different door objects) are filed as ONE issue since they share the same missing target.

**Cycle review:** Cycles are NOT auto-filed as issues. Bart reviews each cycle:
- 2-node A↔B (e.g., matchbox ↔ matchbox-open): Toggle — intentional, no issue.
- 3+ node cycles: Likely bug — filed manually after investigation.

**Estimate:** 1 hour.

---

## Feature Breakdown

### System 1: File Scanner (`scan_meta_root`)

**Responsibility:** Recursively discover all `.lua` files under `src/meta/`.

**No hardcoded directory list.** The scanner enumerates subdirectories at runtime:
1. First pass: `dir /b /ad src\meta` (Windows) / `ls -d src/meta/*/` (Unix)
2. Second pass: For each subdirectory, `dir /b *.lua` / `ls *.lua`

**Current subdirectories (auto-discovered):**
- `src/meta/objects/` (~74+ files)
- `src/meta/creatures/` (wolf, spider, rat, etc.)
- `src/meta/injuries/` (7 injury types)
- `src/meta/rooms/` (7 rooms — may contain exit door mutations)
- `src/meta/templates/` (5 base templates)
- `src/meta/levels/` (level definitions)
- `src/meta/materials/` (17+ materials)

**Future-proofing:** When `src/meta/food/`, `src/meta/npcs/`, or `src/meta/worlds/` are added, the scanner picks them up with zero code changes.

### System 2: Sandbox Loader (`safe_load`)

**Responsibility:** Load `.lua` files safely for static analysis.

**Environment whitelist:** `math`, `string`, `table`, `pairs`, `ipairs`, `tostring`, `tonumber`, `type`, `print` (no-op), `require` (stub → `{}`).

**Why stub `require`?** Some objects use `require` for shared utilities. Stubbing it prevents side effects during static analysis while allowing the file to load.

**Why no-op `print`?** Some object files have debug prints that would pollute test output.

**Lua 5.1 compatibility:** Uses `setfenv(fn, env)` for sandboxing.

**Failure modes:**
- Syntax error in `.lua` file → `loadfile` returns nil + error string
- Runtime error during execution → `pcall` catches, returns nil + error string
- File doesn't return a table → returns nil + "did not return a table"

### System 3: Edge Extractor (`extract_edges`)

**Responsibility:** Parse a loaded object table and extract all mutation edges.

**6 mechanisms handled:**

| # | Mechanism | Guard | Edge Fields |
|---|-----------|-------|-------------|
| 1 | File-swap | `m.becomes ~= nil` and `not m.dynamic` | `{from=obj.id, to=m.becomes, type="file-swap", verb=verb}` |
| 2 | Spawn (mutation) | `m.spawns` exists, iterate | `{from=obj.id, to=spawn_id, type="spawn", verb=verb}` |
| 3 | Spawn (transition) | `t.spawns` exists, iterate | `{from=obj.id, to=spawn_id, type="spawn-transition", verb=t.verb or "auto"}` |
| 4 | Crafting | `recipe.becomes ~= nil` | `{from=obj.id, to=recipe.becomes, type="crafting", verb=verb}` |
| 5 | Tool depletion | `on_tool_use.when_depleted ~= nil` | `{from=obj.id, to=when_depleted, type="tool-depletion", verb="use"}` |
| 6 | Dynamic | `m.dynamic == true` | No edge — added to dynamics list |

**Edge cases:**
- `becomes = nil`: Destruction — not an edge, not broken.
- `mutations = {}`: Empty table — no edges, no error.
- Self-referencing becomes: Valid cycle (self-edge). Reported.
- Duplicate spawn IDs: `{"cloth", "cloth"}` → two edges to same target. Valid.
- Spider-fang crafting: Has `category` and `applies_to` but no `becomes` — no edge.

### System 4: Cycle Detector (`detect_cycles`)

**Algorithm:** DFS with 3-color marking.
- White: Unvisited
- Gray: In current DFS path (back-edge to gray = cycle)
- Black: Fully explored

**Output:** Array of cycles, each cycle = ordered array of node IDs.

**Cycle classification (done by Bart in WAVE-3, not automated):**
- 2-node toggle (A↔B): Typically verb/undo pairs (matchbox open/close). Intentional.
- Self-edge (A→A): Typically state reset. Intentional.
- 3+ node cycle: Likely a bug — investigate.

---

## Cross-System Integration Points

| System A | System B | Integration |
|----------|----------|-------------|
| File Scanner | Build Graph | Scanner output feeds `build_graph` as file list |
| Sandbox Loader | Engine Loader | Pattern reference only — test doesn't import engine loader |
| Edge Extractor | Object Definitions | Reads mutation/transition/crafting/tool_use tables from loaded objects |
| Cycle Detector | Edge Extractor | Operates on edges produced by extractor |
| Test Runner | Test File | `test/run-tests.lua` discovers `test/meta/test-mutation-graph.lua` via `test_dirs` |
| Linter Output | GitHub Issues | Broken edge report drives issue filing in WAVE-3 |
| Meta-lint (Python) | Mutation Graph (Lua) | Conceptually parallel — no overlap. Python validates syntax/structure; Lua validates mutation graph. |

**Key isolation:** The mutation graph linter is entirely self-contained in the test file. It does NOT import any engine modules. It loads object files directly via `loadfile()` with its own sandbox.

---

## Nelson LLM Test Scenarios

### Scenario 1: Smoke Test (GATE-0)
```
> lua test/run-tests.lua
# Verify: no crash, test/meta/ directory present in runner output
# Verify: total test count matches baseline (no additions yet)
```

### Scenario 2: Standalone Linter (GATE-1)
```
> lua test/meta/test-mutation-graph.lua
# Verify: 240+ tests pass
# Verify: Report shows "Broken: 4 edges"
# Verify: Report shows "Dynamic: 1 path (paper write)"
# Verify: Report shows "Cycles: 1 detected"
# Verify: Report shows "Nodes: 8x+" (80+)
```

### Scenario 3: Full Suite Integration (GATE-2)
```
> lua test/run-tests.lua
# Verify: meta/test-mutation-graph.lua appears in runner output
# Verify: zero regressions (pass count = baseline + mutation graph tests)
# Verify: test-mutation-graph results don't corrupt summary
```

### Scenario 4: Broken Edge Discovery (GATE-1)
```
> lua test/meta/test-mutation-graph.lua
# Verify broken edges in output:
#   ✗ poison-gas-vent → poison-gas-vent-plugged
#   ✗ bedroom-hallway-door-north → wood-splinters
#   ✗ bedroom-hallway-door-south → wood-splinters
#   ✗ courtyard-kitchen-door → wood-splinters
```

---

## TDD Test File Map

| File | Owner | Wave | Coverage |
|------|-------|------|----------|
| `test/meta/test-mutation-graph.lua` | Bart | WAVE-1 | All 7 suites: file loading, required fields, edge resolution, target validity, dynamic detection, graph stats, cycle detection |

**Suite breakdown:**

| Suite | Approx Tests | What It Validates |
|-------|-------------|-------------------|
| Suite 1: File Loading | ~91 | Every `src/meta/` `.lua` file loads in sandbox |
| Suite 2: Required Fields | ~91 | `id` on all objects; `on_feel` on objects/creatures |
| Suite 3: Edge Resolution | ~30 | Every mutation target resolves to an existing node |
| Suite 4: Target Validity | ~30 | Resolved targets have required fields |
| Suite 5: Dynamic Detection | ~2 | `paper.lua` write flagged as dynamic |
| Suite 6: Graph Statistics | ~6 | Node count, edge count, broken count, dynamic count, cycle count, load errors |
| Suite 7: Cycle Detection | ~3 | Matchbox toggle cycle exists, no unexpected long cycles |

**Total:** ~240-260 tests (dynamic — grows with content additions).

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| `setfenv` not available (Lua 5.2+) | Low | High | Project uses Lua 5.1 exclusively. Add version check at top of file with clear error message. |
| `io.popen` unavailable on some platforms | Low | High | Same pattern used by `test/run-tests.lua` — if it works there, it works here. |
| Object files with side effects during load | Medium | Medium | Sandbox environment stubs `require` and `print`. Any remaining side effects are caught by `pcall`. |
| New mutation mechanism added to engine | Medium | Low | Design doc covers 6 mechanisms. `extract_edges` has clear structure — adding a 7th is a single `if` block. |
| Object count changes break Suite 6 stats | High | Low | Suite 6 uses `>` thresholds, not exact counts. Only broken edge count is exact (4). |
| Broken edges fixed by Flanders → Suite 6 needs update | High | Low | Update `broken edges == N` assertion when Flanders creates missing files. |
| Template inheritance gap | Medium | Low | Phase 1 defers template merging. TODO comment + placeholder test. All current instances redeclare inherited mutations. |
| Windows path separator issues | Medium | Medium | Uses `package.config:sub(1,1)` for SEP, same as `test/run-tests.lua`. |

---

## Autonomous Execution Protocol

### Execution Flow
```
WAVE-0 → GATE-0 → WAVE-1 → GATE-1 → WAVE-2 (parallel) → GATE-2 → WAVE-3 → DONE
```

### Coordinator Instructions

1. **WAVE-0:** Spawn Nelson. One task: create dir + register. Wait for GATE-0.
2. **GATE-0:** Verify runner infrastructure. If fail → fix and re-gate.
3. **WAVE-1:** Spawn Bart. Single file write. Wait for GATE-1.
4. **GATE-1:** Run `lua test/meta/test-mutation-graph.lua`. Verify 7 criteria. If fail → Bart fixes.
5. **WAVE-2:** Spawn 3 agents in parallel:
   - Brockman → `docs/testing/mutation-graph-linting.md`
   - Bart → `.squad/skills/mutation-graph-lint/SKILL.md`
   - Nelson → `lua test/run-tests.lua` (full suite regression)
6. **GATE-2:** Verify 5 criteria. If fail → identify which agent's deliverable failed, re-run that agent only.
7. **WAVE-3:** Spawn Bart + Nelson. Execute linter, review cycles, file issues.
8. **Commit/push** after each gate passes.

### Checkpoints
- After WAVE-0: commit "chore: register test/meta in test runner"
- After WAVE-1: commit "feat: mutation graph linter (7 suites, 240+ tests)"
- After WAVE-2: commit "docs: mutation graph linting documentation + skill"
- After WAVE-3: commit "chore: file issues for broken mutation edges"

---

## Gate Failure Protocol

| Failure | Action | Escalation |
|---------|--------|-----------|
| GATE-0 fail | Nelson re-runs, checks path separators | 1x fail → file issue, assign Nelson |
| GATE-1 fail (test count low) | Bart reviews extraction logic, checks for missed files | 1x fail → Wayne notified |
| GATE-1 fail (wrong broken count) | Bart audits known broken edges vs actual | 1x fail → Wayne notified |
| GATE-2 fail (regression) | Nelson isolates — is it mutation graph test or pre-existing? | 1x fail → Wayne notified |
| GATE-2 fail (docs incomplete) | Brockman re-runs with explicit section checklist | 1x fail → file issue, assign Brockman |

**Threshold:** 1x gate failure → escalate to Wayne (Phase 1 threshold per implementation-plan skill).

---

## Wave Checkpoint Protocol

After each wave completes:

1. **Update Status Tracker** at top of this document (⏳ → ✅)
2. **Record actual test count** vs estimated
3. **Note any deviations** from plan (e.g., more/fewer files than expected)
4. **Git tag** per gate: `mutation-graph-linter-gate-{N}`
5. **Commit/push** all changes

---

## Documentation Deliverables

| Deliverable | Owner | Wave | Gate Requirement |
|-------------|-------|------|-----------------|
| `docs/testing/mutation-graph-linting.md` | Brockman | WAVE-2 | GATE-2 |
| `.squad/skills/mutation-graph-lint/SKILL.md` | Bart | WAVE-2 | GATE-2 |
| GitHub issues for broken edges | Bart + Nelson | WAVE-3 | — (final deliverable) |

**Rule:** No phase ships without its docs (per implementation-plan skill Pattern 7).

---

## Architecture Safeguards

### Interface Contracts

| Wave | Contract | Consumers |
|------|----------|-----------|
| WAVE-0 | `test/meta/` registered in `test_dirs` | WAVE-1 (test file location) |
| WAVE-1 | `build_graph("src/meta")` returns `{ nodes, edges, dynamics, broken, load_errors }` | WAVE-2 (docs reference), WAVE-3 (issue filing) |
| WAVE-1 | Report format (see design doc) | WAVE-2 (Brockman docs), WAVE-3 (Nelson capture) |

### Module Size Guard

Single file target: ~350-400 LOC. Well under the 500 LOC threshold from the implementation-plan skill. If the file exceeds 400 LOC, consider extracting the graph library into `test/meta/graph-helpers.lua` (not expected for Phase 1).

### Rollback Strategy

Git tag per gate. If WAVE-2 reveals WAVE-1 was wrong:
1. Revert to `mutation-graph-linter-gate-0` tag
2. Re-plan WAVE-1 with fixes
3. Re-run from WAVE-1

---

## Estimated Effort

| Wave | Agent(s) | Estimate | Design Phase |
|------|----------|----------|-------------|
| WAVE-0 | Nelson | 15 min | — (pre-flight) |
| WAVE-1 | Bart | 3-4 hours | Phase 2 |
| WAVE-2 | Brockman, Bart, Nelson (parallel) | 1 hour (wall clock) | Phase 1, Phase 3 |
| WAVE-3 | Bart, Nelson | 1 hour | Phase 4 |
| **Total** | | **~6 hours** | |

---

## Success Criteria (from design)

1. ✅ `lua test/meta/test-mutation-graph.lua` runs with 240+ passing tests
2. ✅ All 4 known broken edges detected and reported
3. ✅ `paper.lua`'s dynamic mutation flagged, not followed
4. ✅ `matchbox` ↔ `matchbox-open` cycle detected and reported
5. ✅ Graph report shows accurate node/edge/broken/dynamic/cycle counts
6. ✅ Integrates cleanly into `lua test/run-tests.lua` (zero regressions)
7. ✅ GitHub issues filed for every broken edge
8. ✅ Skill doc created for reuse
