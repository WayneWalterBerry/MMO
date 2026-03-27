# Mutation Graph Linter + Test Suite — Plan

**Author:** Bart (Architecture Lead)  
**Requested by:** Wayne "Effe" Berry  
**Date:** 2026-07-28  
**Status:** PLAN ONLY — No implementation  

---

## Executive Summary

Build a pure-Lua test that walks every `.lua` file in `src/meta/objects/`, `src/meta/creatures/`, and `src/meta/injuries/`, extracts all mutation edges (becomes, spawns, crafting, tool depletion), builds a directed graph of all possible object states, and validates every link. Dynamic mutations (`dynamic = true`) are detected and flagged but never followed. The linter runs as part of the regular test suite via `test/run-tests.lua`.

**Known broken edges found during analysis:**
- `poison-gas-vent.lua` → `poison-gas-vent-plugged` (file does not exist)
- `bedroom-hallway-door-north.lua` → `wood-splinters` (file does not exist)
- `bedroom-hallway-door-south.lua` → `wood-splinters` (file does not exist)
- `courtyard-kitchen-door.lua` → `wood-splinters` (file does not exist)

---

## Phase 1: Documentation

### Deliverable
`docs/testing/mutation-graph-linting.md`

### Contents

1. **What it validates** — Every outgoing mutation edge from every meta `.lua` file resolves to an existing, loadable, valid `.lua` file. Covers 6 mutation mechanisms:

   | Mechanism | Data Path | Example |
   |-----------|-----------|---------|
   | File-swap mutation | `mutations[verb].becomes` | `poison-gas-vent.lua` → `poison-gas-vent-plugged` |
   | FSM in-place mutation | `transitions[].mutate` | `candle.lua` lit → extinguished (property patch, no file swap) |
   | Spawns (mutation) | `mutations[verb].spawns` | `blanket.lua` tear → `{"cloth", "cloth"}` |
   | Spawns (transition) | `transitions[].spawns` | `mirror.lua` break → `{"glass-shard"}` |
   | Crafting | `crafting[verb].becomes` | `cloth.lua` sew → `terrible-jacket` |
   | Tool depletion | `on_tool_use.when_depleted` | (None currently exist — future-proof) |

2. **How it traverses** — BFS/DFS from every source file. Each file is a node. Each `becomes`, each `spawns` entry, each `crafting[*].becomes`, and each `on_tool_use.when_depleted` is a directed edge. FSM `transitions[].mutate` entries are NOT edges (they're in-place property patches on the same node) but are validated for structural correctness.

3. **Dynamic mutations** — When `mutations[verb].dynamic == true`, the linter logs the path as "dynamic/unbounded" and does NOT follow it. Reason: the target is generated at runtime from player input (e.g., `paper.lua`'s `write` verb creates arbitrary text). These paths are infinite by definition. The doc explains why they're safe to skip: the mutation engine (`src/engine/mutation/init.lua`) handles dynamic targets at runtime; static analysis cannot predict them.

4. **Graph algorithm** — Described in pseudocode:
   ```
   nodes = {}       -- map: file_id → file metadata
   edges = {}       -- list: { from, to, type, verb }
   dynamic = {}     -- list: { from, verb, mutator }
   broken = {}      -- list: { from, to, type, verb, reason }

   for each .lua file in scan_dirs:
       load file via sandboxed dofile
       extract id, on_feel, template (for validation)
       for each mutations[verb]:
           if .dynamic == true → add to dynamic list, skip
           if .becomes ~= nil → add edge(file.id, becomes, "file-swap", verb)
           for each entry in .spawns → add edge(file.id, entry, "spawn", verb)
       for each transitions[i]:
           for each entry in .spawns → add edge(file.id, entry, "spawn-transition", verb)
       for each crafting[verb]:
           if .becomes ~= nil → add edge(file.id, becomes, "crafting", verb)
       if on_tool_use.when_depleted:
           add edge(file.id, when_depleted, "tool-depletion", "use")

   for each edge:
       if target not in nodes → add to broken list

   cycle_detect(edges)  -- Tarjan's or DFS back-edge detection
   report(nodes, edges, broken, dynamic, cycles)
   ```

5. **Cycle semantics** — Some cycles are intentional (e.g., `poison-gas-vent` ↔ `poison-gas-vent-plugged` is a toggle). The linter reports ALL cycles but does not fail on them — they are flagged for human review. The doc explains the distinction between "toggle cycles" (2-node A↔B, typically verb/undo pairs) and "longer cycles" (3+ nodes, likely bugs).

---

## Phase 2: Implementation

### File: `test/meta/test-mutation-graph.lua`

**Registration:** Add `test/meta` to the `test_dirs` array in `test/run-tests.lua`:
```lua
repo_root .. SEP .. "test" .. SEP .. "meta",
```

### Dependencies
- `test/parser/test-helpers.lua` (existing — `test()`, `assert_eq()`, `assert_truthy()`, `assert_nil()`, `suite()`, `summary()`)
- Pure Lua file I/O (`io.popen` for directory listing, `dofile`/`loadfile` for loading .lua objects)
- No external dependencies (zero-dep constraint)

### Module Structure

The test file contains both the graph-building library and the test harness. No separate module needed — single file, consistent with existing test patterns.

#### Key Functions

```lua
-- Scan directories and return list of .lua file paths
-- signature: scan_dirs(dirs) → { "src/meta/objects/candle.lua", ... }
local function scan_dirs(dirs)

-- Load a single .lua file in sandbox, return table or nil+error
-- Uses loadfile() with empty env (same pattern as engine loader)
-- signature: safe_load(filepath) → table, nil | nil, error_string
local function safe_load(filepath)

-- Extract all mutation edges from a loaded object table
-- Returns: edges[], dynamic_flags[]
-- signature: extract_edges(obj, source_id) → edges, dynamics
--   where edge = { from=string, to=string, type=string, verb=string }
--   where dynamic = { from=string, verb=string, mutator=string }
local function extract_edges(obj, source_id)

-- Build the full graph from all scanned files
-- Returns: nodes{}, edges[], dynamics[], broken[], load_errors[]
-- signature: build_graph(scan_dirs) → graph_result
local function build_graph(dirs)

-- Detect cycles using DFS with coloring (white/gray/black)
-- Returns: list of cycles, each cycle = { node1, node2, ... }
-- signature: detect_cycles(nodes, edges) → cycles[]
local function detect_cycles(nodes, edges)

-- Find unreachable nodes (files that exist but have no incoming edges
-- and are not source files referenced by any room)
-- signature: find_unreachable(nodes, edges) → unreachable_ids[]
local function find_unreachable(nodes, edges)

-- Print the graph report (summary stats)
-- signature: report(graph_result, cycles, unreachable)
local function report(graph_result, cycles, unreachable)
```

### Extraction Logic (Detail)

For each loaded object table `obj`:

```lua
-- 1. File-swap mutations
if obj.mutations then
    for verb, m in pairs(obj.mutations) do
        if m.dynamic then
            -- Flag as dynamic, skip traversal
            table.insert(dynamics, { from = obj.id, verb = verb, mutator = m.mutator })
        else
            if m.becomes and m.becomes ~= nil then  -- becomes=nil means "destroy"
                table.insert(edges, { from = obj.id, to = m.becomes, type = "file-swap", verb = verb })
            end
            if m.spawns then
                for _, spawn_id in ipairs(m.spawns) do
                    table.insert(edges, { from = obj.id, to = spawn_id, type = "spawn", verb = verb })
                end
            end
        end
    end
end

-- 2. Transition spawns (FSM)
if obj.transitions then
    for _, t in ipairs(obj.transitions) do
        if t.spawns then
            for _, spawn_id in ipairs(t.spawns) do
                table.insert(edges, { from = obj.id, to = spawn_id, type = "spawn-transition", verb = t.verb or "auto" })
            end
        end
    end
end

-- 3. Crafting
if obj.crafting then
    for verb, recipe in pairs(obj.crafting) do
        if recipe.becomes then
            table.insert(edges, { from = obj.id, to = recipe.becomes, type = "crafting", verb = verb })
        end
    end
end

-- 4. Tool depletion (future-proof)
if obj.on_tool_use and obj.on_tool_use.when_depleted then
    table.insert(edges, { from = obj.id, to = obj.on_tool_use.when_depleted, type = "tool-depletion", verb = "use" })
end
```

### Test Suites

#### Suite 1: File Loading (~90 tests, 1 per .lua file)
```lua
t.suite("All meta files load successfully")
-- For each file in src/meta/objects/, src/meta/creatures/, src/meta/injuries/:
--   t.test("loads: candle.lua", function()
--       local obj, err = safe_load(filepath)
--       t.assert_truthy(obj, "failed to load: " .. filepath .. " — " .. tostring(err))
--   end)
```
Estimated count: ~90 files (83 objects + 1 creature + 7 injuries = ~91)

#### Suite 2: Required Fields (~90 tests)
```lua
t.suite("All meta files have required fields")
-- For each loaded object:
--   t.test("required fields: candle", function()
--       t.assert_truthy(obj.id, "missing id")
--       t.assert_truthy(obj.on_feel, "missing on_feel")
--   end)
```
Note: `on_feel` is mandatory per core principles. `id` is mandatory for the graph (node identity). Injuries may have different required fields — the test checks `id` universally and `on_feel` for objects/creatures only.

#### Suite 3: Edge Resolution (~25-35 tests, 1 per non-nil becomes/spawns target)
```lua
t.suite("All mutation targets resolve")
-- For each edge in the graph:
--   t.test("edge resolves: poison-gas-vent → poison-gas-vent-plugged", function()
--       t.assert_truthy(nodes[edge.to], "broken edge: " .. edge.from .. " → " .. edge.to)
--   end)
```
Estimated count: ~23 becomes + ~30 spawns entries (some duplicates like glass-shard appear many times but resolve to 1 file) = ~25-35 unique target checks.

#### Suite 4: Target Validity (~25-35 tests)
```lua
t.suite("All mutation targets are valid objects")
-- For each resolved target:
--   t.test("target valid: glass-shard", function()
--       local target = nodes[edge.to]
--       t.assert_truthy(target.id, "target missing id")
--       t.assert_truthy(target.on_feel, "target missing on_feel")
--   end)
```

#### Suite 5: Dynamic Detection (~1-2 tests)
```lua
t.suite("Dynamic mutations detected and skipped")
-- t.test("paper.lua write mutation flagged as dynamic", function()
--     t.assert_truthy(#dynamics > 0)
--     t.assert_eq("paper", dynamics[1].from)
--     t.assert_eq("write", dynamics[1].verb)
-- end)
```

#### Suite 6: Graph Statistics (5-8 tests)
```lua
t.suite("Graph statistics")
-- t.test("total nodes > 80", ...)        -- sanity: we have 90+ files
-- t.test("total edges > 20", ...)        -- sanity: we have 23+ mutation entries
-- t.test("broken edges reported", ...)   -- currently 4 known broken
-- t.test("cycles detected", ...)         -- poison-gas-vent ↔ poison-gas-vent (self-ref)
-- t.test("dynamic paths flagged", ...)   -- paper.lua write
```

#### Suite 7: Cycle Detection (2-3 tests)
```lua
t.suite("Cycle detection")
-- t.test("toggle cycles identified", function()
--     -- matchbox ↔ matchbox-open is a valid toggle
--     -- poison-gas-vent → poison-gas-vent-plugged is a valid toggle
--     -- (if poison-gas-vent-plugged existed, which it doesn't yet)
-- end)
```

### Total Test Estimate: ~240-260 tests

Breakdown:
- Suite 1 (loading): ~91
- Suite 2 (required fields): ~91
- Suite 3 (edge resolution): ~30
- Suite 4 (target validity): ~30
- Suite 5 (dynamic detection): ~2
- Suite 6 (graph stats): ~6
- Suite 7 (cycle detection): ~3

### Sandbox Loading Pattern

The loader must handle objects that contain Lua functions (most do — `on_look`, etc.). Use `loadfile()` with a restricted environment that provides `math`, `string`, `table`, `pairs`, `ipairs`, `tostring`, `tonumber`, `type`, `require` (stubbed). This mirrors `src/engine/loader/init.lua`'s approach.

```lua
local function safe_load(filepath)
    local fn, err = loadfile(filepath)
    if not fn then return nil, err end

    local env = {
        math = math, string = string, table = table,
        pairs = pairs, ipairs = ipairs, tostring = tostring,
        tonumber = tonumber, type = type, print = function() end,
        require = function() return {} end,  -- stub
    }
    setfenv(fn, env)  -- Lua 5.1
    local ok, result = pcall(fn)
    if not ok then return nil, result end
    if type(result) ~= "table" then return nil, "did not return a table" end
    return result, nil
end
```

### `becomes = nil` Handling

Many objects have `becomes = nil` (e.g., `blanket.lua` tear, `paper.lua` burn). This means "destroy the object — no replacement." The linter must NOT treat `nil` as a broken edge. The extraction logic explicitly checks `m.becomes ~= nil` before adding an edge.

### Report Output

The test prints a summary after all assertions:

```
=== Mutation Graph Report ===
  Nodes:    91 files scanned
  Edges:    47 mutation paths
  Broken:   4 edges (targets missing)
  Dynamic:  1 path (paper.lua write — skipped)
  Cycles:   1 detected (matchbox ↔ matchbox-open)
  Unreachable: 12 files (no incoming edges)

Broken edges:
  ✗ poison-gas-vent → poison-gas-vent-plugged (file-swap via plug)
  ✗ bedroom-hallway-door-north → wood-splinters (spawn-transition via break)
  ✗ bedroom-hallway-door-south → wood-splinters (spawn-transition via break)
  ✗ courtyard-kitchen-door → wood-splinters (spawn-transition via break)

Dynamic paths (not followed):
  ⚡ paper → write (mutator: write_on_surface)

Cycles:
  ↻ matchbox → matchbox-open → matchbox
```

---

## Phase 3: Skill Update

### Deliverable
`.squad/skills/mutation-graph-lint/SKILL.md`

### Contents

```yaml
name: "mutation-graph-lint"
description: "Static validation of all mutation chains across meta .lua files"
domain: "testing, meta-validation, graph analysis"
confidence: "high"
source: "earned — mutation graph linter implementation"
```

**Patterns documented:**
1. How to add new scan directories (just add path to `scan_dirs` list)
2. How to add new edge types (add extraction case in `extract_edges()`)
3. How the sandbox loader handles function-containing objects
4. Why dynamic mutations are skipped (unbounded runtime generation)
5. How to interpret cycle reports (toggle vs. bug)
6. Gate integration: this test runs in the regular suite, failures block deploy

**Reusable gate check pattern:**
- Pre-deploy: `lua test/run-tests.lua` includes mutation graph validation
- Pre-PR: same — any broken edge fails the suite
- Object authoring: when Flanders adds a new object with `becomes`, the linter catches missing targets before merge

---

## Phase 4: Full Run + Issue Filing

### Execution
```bash
lua test/meta/test-mutation-graph.lua
```

### Issue Filing Rules

Every broken edge / missing target / validation failure becomes a GitHub issue:

| Broken Edge | Issue Title | Label | Assignee |
|-------------|-------------|-------|----------|
| `poison-gas-vent` → `poison-gas-vent-plugged` | Missing mutation target: poison-gas-vent-plugged.lua | `squad:flanders`, `bug` | Flanders |
| `*-door-*` → `wood-splinters` (×3) | Missing spawn target: wood-splinters.lua | `squad:flanders`, `bug` | Flanders |
| Any future broken edge in objects/ | Missing mutation/spawn target: {file} | `squad:flanders`, `bug` | Flanders |
| Any broken edge in creatures/ | Missing creature mutation target | `squad:flanders`, `bug` | Flanders |
| Any broken edge in world/ rooms | Missing room reference | `squad:moe`, `bug` | Moe |
| Any broken edge in injuries/ | Missing injury mutation target | `squad:flanders`, `bug` | Flanders |

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

### Cycle Review

Cycles are NOT auto-filed as issues. They're reported in the test output for human review. The reviewer (Bart) determines if each cycle is intentional (toggle) or a bug. Bugs get filed manually.

---

## Implementation Notes

### Integration with Existing Infrastructure

| Component | How It Integrates |
|-----------|-------------------|
| `test/run-tests.lua` | Add `test/meta` to `test_dirs` array (1-line change) |
| `test/parser/test-helpers.lua` | Used directly — `require("test-helpers")` via existing package.path |
| `scripts/meta-lint/lint.py` | Conceptually parallel — Python validates syntax/structure, Lua validates mutation graph. No overlap. |
| `src/engine/loader/init.lua` | Pattern reference for sandbox loading. NOT imported — test is self-contained. |
| `src/engine/mutation/init.lua` | Architectural reference only. The linter validates the DATA that this module would consume at runtime. |

### File Discovery

Uses the same `io.popen` + `dir /b` (Windows) / `ls` (Unix) pattern as `test/run-tests.lua`. Scans:
- `src/meta/objects/*.lua`
- `src/meta/creatures/*.lua`
- `src/meta/injuries/*.lua`

### Edge Cases

1. **`becomes = nil`** — Intentional destruction. Not an edge. Not a broken link.
2. **`mutations = {}`** — Empty table. No edges. No error.
3. **Self-referencing becomes** — `poison-gas-vent` unplug → becomes `poison-gas-vent` (same file). Valid cycle (self-edge). Reported but not an error.
4. **Duplicate spawn IDs** — `blanket.lua` spawns `{"cloth", "cloth"}`. Two edges to same target. Valid (creates 2 instances). Edge count reflects duplicates; target validation deduplicates.
5. **Template-only files** — Files in `src/meta/templates/` are NOT scanned as nodes. They are base classes, not instantiable objects. However, if a template has `mutations` (like `sheet.lua` has `tear.spawns = {"cloth"}`), those edges ARE validated because instances inherit them.
6. **Objects with only FSM mutations** — Objects like `candle.lua` that use only `transitions[].mutate` (property patches) have no outgoing file-swap edges. They are valid leaf nodes in the graph.

### Template Inheritance

Templates (e.g., `sheet.lua`) define default mutations that instances inherit. The linter must account for this:
- Load templates separately from `src/meta/templates/`
- For each object with a `template` field, merge template mutations with instance mutations (instance overrides)
- This ensures inherited `spawns` from `sheet.lua` → `cloth` are validated even if the instance doesn't redeclare them

However, for Phase 1 simplicity: since all current instances that inherit mutations also redeclare them explicitly (e.g., `blanket.lua` overrides `sheet.lua`'s tear), template merging can be deferred. Add a TODO comment and a "template inheritance" test that verifies at least one inherited mutation resolves.

---

## Estimated Effort

| Phase | Owner | Estimate |
|-------|-------|----------|
| Phase 1: Documentation | Brockman | 1 hour |
| Phase 2: Implementation | Nelson (tests) + Bart (graph lib) | 3-4 hours |
| Phase 3: Skill Update | Bart | 30 min |
| Phase 4: Full Run + Filing | Nelson + Bart | 1 hour |
| **Total** | | **~6 hours** |

---

## Success Criteria

1. `lua test/meta/test-mutation-graph.lua` runs and produces 240+ passing tests
2. All 4 known broken edges are detected and reported
3. `paper.lua`'s dynamic mutation is flagged, not followed
4. `matchbox` ↔ `matchbox-open` cycle is detected and reported
5. Graph report shows accurate node/edge/broken/dynamic/cycle counts
6. Test integrates cleanly into `lua test/run-tests.lua` (zero regressions)
7. GitHub issues filed for every broken edge
8. Skill doc created for reuse
