# Mutation Graph Linter — Design Plan

**Author:** Bart (Architecture Lead)  
**Requested by:** Wayne "Effe" Berry  
**Date:** 2026-07-28  
**Revised:** 2026-08-23 (pivot to expand-and-lint approach per Wayne's direction; team review additions)  
**Status:** PLAN — Ready for implementation

---

## Executive Summary

Validate mutation chains by **expanding all mutation targets and running the existing Python meta-lint on them**. Instead of building a standalone Lua graph validator with custom BFS/DFS/cycle detection, this approach uses two tools working together:

1. **Lua edge extractor** (~100-150 LOC) — walks all `.lua` files in `src/meta/`, loads them in a sandbox, extracts every mutation edge (`becomes`, `spawns`, `crafting.becomes`, `on_tool_use.when_depleted`), verifies each target file exists, and outputs the list of target files.
2. **Python meta-lint** (`scripts/meta-lint/lint.py`) — runs against each target file, giving full 200+ rule coverage on every mutation target for free.

This is simpler AND more powerful than the original graph-library approach:
- No custom graph library needed — edge extraction is just table traversal
- No duplicate validation code — the existing linter (200+ rules, fix_safety, `--env` profiles) applies to ALL targets
- Edge existence checking is a simple file-exists test
- Dynamic mutations still flagged but not followed (same as before)

**CRITICAL: No hardcoded directory list.** The scanner recursively enumerates all subdirectories of `src/meta/` at runtime.

**Known broken edges found during analysis:**
- `poison-gas-vent.lua` → `poison-gas-vent-plugged` (file does not exist)
- `bedroom-hallway-door-north.lua` → `wood-splinters` (file does not exist)
- `bedroom-hallway-door-south.lua` → `wood-splinters` (file does not exist)
- `courtyard-kitchen-door.lua` → `wood-splinters` (file does not exist)

---

## Motivation [Brockman #1]

**Why static analysis instead of runtime validation?**

The mutation engine (`src/engine/mutation/init.lua`) resolves target files at runtime — when a player performs an action that triggers a mutation. If the target file doesn't exist, the player gets a runtime error (or silent failure) during gameplay. This is the worst possible time to discover a missing file.

Static analysis catches these problems before anyone plays:
- **Author-time:** When Flanders creates an object with `becomes = "broken-vase"` but never creates `broken-vase.lua`
- **Merge-time:** When a PR deletes or renames a target file without updating all references
- **Pre-deploy:** As a gate check before pushing to production

The expand-and-lint approach adds a second validation layer: not only must target files *exist*, they must also pass the full 200+ rule meta-lint. A target file with a missing `on_feel` field or invalid GUID would pass the edge-existence check but fail the lint check — catching a class of bugs that pure graph validation would miss.

**Real-world example trace [Brockman #2]:**
```
1. Player: "plug vent with cloth"
2. Engine: looks up mutations["plug"] on poison-gas-vent.lua
3. Engine: finds becomes = "poison-gas-vent-plugged"
4. Engine: tries to load src/meta/objects/poison-gas-vent-plugged.lua
5. Engine: FILE NOT FOUND → runtime error
```
The edge checker catches this at step 2-3, statically, without running the game.

### Deliverable
`docs/testing/mutation-graph-linting.md`

### Contents

1. **What it validates** — Two complementary checks on every mutation chain in `src/meta/`:
   - **Edge existence:** Every mutation target resolves to an existing `.lua` file
   - **Target validity:** Every target file passes the full Python meta-lint ruleset (200+ rules)

   Covers **12 mutation edge mechanisms** (5 original + 7 creature-specific [Flanders]):

   | Mechanism | Data Path | Example |
   |-----------|-----------|---------|
   | File-swap mutation | `mutations[verb].becomes` | `poison-gas-vent.lua` → `poison-gas-vent-plugged` |
   | Spawns (mutation) | `mutations[verb].spawns` | `blanket.lua` tear → `{"cloth", "cloth"}` |
   | Spawns (transition) | `transitions[].spawns` | `mirror.lua` break → `{"glass-shard"}` |
   | Crafting | `crafting[verb].becomes` | `cloth.lua` sew → `terrible-jacket` |
   | Tool depletion | `on_tool_use.when_depleted` | (None currently exist — future-proof) |
   | Loot (always) | `loot_table.always[].template` | `wolf.lua` → `gnawed-bone` |
   | Loot (weighted) | `loot_table.on_death[].item.template` | `wolf.lua` → `silver-coin` |
   | Loot (variable) | `loot_table.variable[].template` | `wolf.lua` → `copper-coin` |
   | Loot (conditional) | `loot_table.conditional.{key}[].template` | `wolf.lua` fire_kill → `charred-hide` |
   | Corpse cooking | `death_state.crafting[verb].becomes` | `rat.lua` → `cooked-rat-meat` |
   | Butchery | `death_state.butchery_products.products[].id` | `wolf.lua` → `wolf-meat`, `wolf-bone`, `wolf-hide` |
   | Creates object | `behavior.creates_object.template` | `spider.lua` → `spider-web` |

   Note: FSM `transitions[].mutate` entries are NOT edges — they're in-place property patches on the same node. They're already validated by the Python linter as structural fields.

2. **How it works** — Two tools, each doing what it's good at:
   - **Lua edge extractor** scans all `.lua` files under `src/meta/`, loads each in a sandbox, extracts mutation edges, checks if target files exist. Outputs: broken edges list + list of all valid target file paths.
   - **Python meta-lint** receives the list of target files and validates each with the full 200+ rule engine. This catches field violations, naming issues, sensory gaps, etc. that would only surface by following the mutation chain.

3. **Dynamic mutations** — When `mutations[verb].dynamic == true`, the extractor logs the path as "dynamic/unbounded" and does NOT follow it. Reason: the target is generated at runtime from player input (e.g., `paper.lua`'s `write` verb creates arbitrary text). The doc explains why they're safe to skip: the mutation engine (`src/engine/mutation/init.lua`) handles dynamic targets at runtime; static analysis cannot predict them.

4. **Algorithm** — Described in pseudocode:
   ```
   targets = []     -- list of target file paths for linting
   edges = []       -- list: { from, to, type, verb }
   dynamic = []     -- list: { from, verb, mutator }
   broken = []      -- list: { from, to, type, verb }

   for each .lua file in src/meta/ (recursive):
       load file via sandboxed loadfile
       for each mutations[verb]:
           if .dynamic == true → add to dynamic list, skip
           if .becomes ~= nil → add edge, check file exists
           for each entry in .spawns → add edge, check file exists
       for each transitions[i]:
           for each entry in .spawns → add edge, check file exists
       for each crafting[verb]:
           if .becomes ~= nil → add edge, check file exists
       if on_tool_use.when_depleted:
           add edge, check file exists

   for each edge where target file exists:
       add target path to targets list

   report broken edges
   output targets list (for piping to meta-lint)
   ```

5. **Integration** — Two usage modes:
   - **Standalone:** `lua scripts/mutation-edge-check.lua` — reports broken edges, prints target files
   - **Piped:** `lua scripts/mutation-edge-check.lua --targets | python scripts/meta-lint/lint.py -` — or pass targets via xargs/foreach

---

## Phase 2: Implementation

### File: `scripts/mutation-edge-check.lua`

A standalone Lua script (~130-190 LOC) that extracts mutation edges from 12 mechanisms and verifies target file existence. NOT a test file — it's a script that can be run directly or piped to the Python linter.

### Dependencies
- Pure Lua file I/O (`io.popen` for directory listing, `loadfile` for loading `.lua` objects)
- No external dependencies (zero-dep constraint)
- `scripts/meta-lint/lint.py` — existing Python linter, called separately on output

### Module Structure

Single file, 5 functions:

```lua
-- Recursively scan ALL subdirectories of src/meta/ for .lua files
-- No hardcoded directory list — discovers subdirs at runtime
-- signature: scan_meta_root(root) → { "src/meta/objects/candle.lua", ... }
local function scan_meta_root(root)

-- Load a single .lua file in sandbox, return table or nil+error
-- Uses loadfile() with restricted env (same pattern as engine loader)
-- signature: safe_load(filepath) → table, nil | nil, error_string
local function safe_load(filepath)

-- Extract all mutation edges from a loaded object table
-- Returns: edges[], dynamic_flags[]
-- signature: extract_edges(obj, source_id) → edges, dynamics
--   where edge = { from=string, to=string, type=string, verb=string }
--   where dynamic = { from=string, verb=string, mutator=string }
local function extract_edges(obj, source_id)

-- Resolve an edge target ID to a file path
-- Looks for {target_id}.lua in all scanned directories
-- signature: resolve_target(target_id, file_map) → filepath | nil
local function resolve_target(target_id, file_map)

-- Main: scan, extract, verify, report
-- signature: main(root) → { edges, broken, dynamic, targets }
local function main(root)
```

### Extraction Logic

For each loaded object table `obj`:

```lua
-- 1. File-swap mutations
if obj.mutations then
    for verb, m in pairs(obj.mutations) do
        if m.dynamic then
            -- Flag as dynamic, skip
            table.insert(dynamics, { from = obj.id, verb = verb, mutator = m.mutator })
        else
            if m.becomes ~= nil then  -- becomes=nil means "destroy"
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

-- 5. Loot table — 4 sub-patterns [Flanders]
if obj.loot_table then
    if obj.loot_table.always then
        for _, entry in ipairs(obj.loot_table.always) do
            if entry.template then
                table.insert(edges, { from = obj.id, to = entry.template, type = "loot-always", verb = "kill" })
            end
        end
    end
    if obj.loot_table.on_death then
        for _, entry in ipairs(obj.loot_table.on_death) do
            if entry.item and entry.item.template then
                table.insert(edges, { from = obj.id, to = entry.item.template, type = "loot-weighted", verb = "kill" })
            end
        end
    end
    if obj.loot_table.variable then
        for _, entry in ipairs(obj.loot_table.variable) do
            if entry.template then
                table.insert(edges, { from = obj.id, to = entry.template, type = "loot-variable", verb = "kill" })
            end
        end
    end
    if obj.loot_table.conditional then
        for method, entries in pairs(obj.loot_table.conditional) do
            for _, entry in ipairs(entries) do
                if entry.template then
                    table.insert(edges, { from = obj.id, to = entry.template, type = "loot-conditional", verb = "kill:" .. method })
                end
            end
        end
    end
end

-- 6. Creature-spawned objects [Flanders]
if obj.behavior and obj.behavior.creates_object and obj.behavior.creates_object.template then
    table.insert(edges, { from = obj.id, to = obj.behavior.creates_object.template, type = "creates-object", verb = "behavior" })
end

-- 7. death_state recursive pass [Flanders]
if obj.death_state then
    if obj.death_state.crafting then
        for verb, recipe in pairs(obj.death_state.crafting) do
            if recipe.becomes then
                table.insert(edges, { from = obj.id, to = recipe.becomes, type = "corpse-cooking", verb = verb })
            end
        end
    end
    if obj.death_state.butchery_products and obj.death_state.butchery_products.products then
        for _, product in ipairs(obj.death_state.butchery_products.products) do
            if product.id then
                table.insert(edges, { from = obj.id, to = product.id, type = "butchery", verb = "butcher" })
            end
        end
    end
end
```

**Note:** Circular chains (A→B→A) are irrelevant — the extractor checks each edge independently, not chains [Nelson #14].

### Output Modes

The script supports two output modes via CLI flags (note: `--json` deferred to WAVE-2 [Smithers blocker #1]):

1. **Default (full report):** `lua scripts/mutation-edge-check.lua`
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

2. **Targets only:** `lua scripts/mutation-edge-check.lua --targets`
   ```
   src/meta/objects/cloth.lua
   src/meta/objects/glass-shard.lua
   src/meta/objects/terrible-jacket.lua
   ...
   ```
   Outputs one file path per line — only valid (existing) targets. Broken edges go to stderr in `WARNING:` format [Smithers #3]. Designed for piping to Python linter.

### Parallel Execution

**Objects can be expanded and linted in parallel.** The Lua edge extractor and Python meta-lint are independent per-object — there's no global dependency between "expand all" and "lint all." This enables three levels of parallelism:

1. **Per-object streaming:** The extractor emits target paths as it finds them (one per line to stdout). The linter can begin processing the first target before the extractor finishes scanning.
2. **Parallel linting:** Multiple linter instances run concurrently on different target files (`xargs -P` on Unix, `ForEach-Object -Parallel` on PowerShell 7).
3. **Combined report:** Broken edges (from Lua) and lint violations (from Python) are collected independently, then merged into a single final report by the wrapper script.

This means the wall-clock time is roughly `max(extract_time, lint_time)` instead of `extract_time + lint_time`.

### Integration with Python Meta-Lint

Usage patterns (all support parallel execution):

```bash
# 1. Check edge existence only (Lua)
lua scripts/mutation-edge-check.lua

# 2. Full parallel validation: edges + lint rules on all targets
# Unix — parallel linting with 4 workers
lua scripts/mutation-edge-check.lua --targets | xargs -P 4 -I {} python scripts/meta-lint/lint.py {}

# 3. Windows — parallel linting with PowerShell 7
lua scripts/mutation-edge-check.lua --targets | ForEach-Object -Parallel { python scripts/meta-lint/lint.py $_ } -ThrottleLimit 4
```

Wrapper scripts (`scripts/mutation-lint.ps1` / `scripts/mutation-lint.sh`) run both steps with parallel linting and combine the outputs into a single report.

### Sandbox Loading Pattern

Same pattern as the original design — mirrors `src/engine/loader/init.lua`:

```lua
local function safe_load(filepath)
    local env = {
        -- Must match engine/loader/init.lua make_sandbox()
        math = math, string = string, table = table,
        pairs = pairs, ipairs = ipairs, next = next, select = select,
        tostring = tostring, tonumber = tonumber, type = type,
        unpack = unpack or table.unpack, error = error, pcall = pcall,
        -- Script-specific stubs (not in engine sandbox)
        print = function() end,
        require = function() return {} end,
    }

    -- Version-branching: same pattern as engine/loader/init.lua lines 70-76
    local fn, err
    if _VERSION == "Lua 5.1" then
        fn, err = loadfile(filepath)
        if fn then setfenv(fn, env) end
    else
        fn, err = loadfile(filepath, "t", env)
    end
    if not fn then return nil, err end

    local ok, result = pcall(fn)
    if not ok then return nil, result end
    if type(result) ~= "table" then return nil, "did not return a table" end
    return result, nil
end
```

### `becomes = nil` Handling

Many objects have `becomes = nil` (e.g., `blanket.lua` tear, `paper.lua` burn). This means "destroy the object — no replacement." The extractor does NOT treat `nil` as a broken edge. The extraction logic explicitly checks `m.becomes ~= nil` before adding an edge.

### File Discovery

Uses `io.popen` + `dir /b` (Windows) / `ls` (Unix) — same cross-platform pattern as `test/run-tests.lua`. **Dynamically discovers ALL subdirectories of `src/meta/`.**

Current subdirectories (auto-discovered, not hardcoded):
- `src/meta/objects/` — game objects
- `src/meta/creatures/` — animate beings
- `src/meta/injuries/` — injury type definitions
- `src/meta/rooms/` — room definitions (may contain mutation edges via exit doors)
- `src/meta/templates/` — base templates
- `src/meta/levels/` — level definitions
- `src/meta/materials/` — material definitions

### Edge Cases

1. **`becomes = nil`** — Intentional destruction. Not an edge. Not a broken link.
2. **`mutations = {}`** — Empty table. No edges. No error.
3. **Duplicate spawn IDs** — `blanket.lua` spawns `{"cloth", "cloth"}`. Two edges to same target. Both reported; target file checked once.
4. **Template files** — Files in `src/meta/templates/` are scanned and their edges validated. Template mutations are inherited by instances.
5. **Objects with only FSM mutations** — Objects like `candle.lua` that use only `transitions[].mutate` (property patches) have no outgoing file-swap edges. They are valid leaf nodes.

---

## Phase 3: Skill Update

### Deliverable
`.squad/skills/mutation-graph-lint/SKILL.md`

### Contents

```yaml
name: "mutation-graph-lint"
description: "Expand all mutation targets and validate with existing meta-lint"
domain: "testing, meta-validation, linting"
confidence: "high"
source: "earned — mutation edge extractor + meta-lint integration"
```

**Patterns documented:**
1. How the Lua scanner auto-discovers all `src/meta/` subdirectories (no hardcoded list)
2. How to add new edge types (add extraction case in `extract_edges()`)
3. How the sandbox loader handles function-containing objects
4. Why dynamic mutations are skipped (unbounded runtime generation)
5. How the Lua extractor + Python linter compose: two tools, each doing what it's good at
6. How to interpret broken edges (missing target files) vs. lint violations (rule failures on existing targets)

**Reusable patterns:**
- Pre-deploy: `lua scripts/mutation-edge-check.lua` catches broken edges
- Pre-PR: same — pipe to meta-lint for full validation
- Object authoring: when Flanders adds a new object with `becomes`, the extractor catches missing targets before merge

---

## Phase 4: Full Run + Issue Filing

### Execution
```bash
# Full parallel run: extract + lint concurrently
# Unix
lua scripts/mutation-edge-check.lua --targets | xargs -P 4 -I {} python scripts/meta-lint/lint.py {} > lint-results.txt &
lua scripts/mutation-edge-check.lua > edge-results.txt &
wait
# Combine: edge-results.txt + lint-results.txt → final report

# Or use the wrapper (recommended):
./scripts/mutation-lint.sh    # Unix
.\scripts\mutation-lint.ps1   # Windows
```

### Issue Filing Rules

Every broken edge becomes a GitHub issue:

| Broken Edge | Issue Title | Label | Assignee |
|-------------|-------------|-------|----------|
| `poison-gas-vent` → `poison-gas-vent-plugged` | Missing mutation target: poison-gas-vent-plugged.lua | `squad:flanders`, `bug` | Flanders |
| `*-door-*` → `wood-splinters` (×3) | Missing spawn target: wood-splinters.lua | `squad:flanders`, `bug` | Flanders |
| Any future broken edge in objects/ | Missing mutation/spawn target: {file} | `squad:flanders`, `bug` | Flanders |
| Any broken edge in creatures/ | Missing creature mutation target | `squad:flanders`, `bug` | Flanders |
| Any broken edge in world/ rooms | Missing room reference | `squad:moe`, `bug` | Moe |
| Any broken edge in injuries/ | Missing injury mutation target | `squad:flanders`, `bug` | Flanders |

Lint violations on target files are reported as separate issues, using the same squad routing as the Python linter (`scripts/meta-lint/squad_routing.py`).

**Issue template (broken edge):**
```markdown
## Missing Mutation Target

**Source file:** `src/meta/objects/{source}.lua`
**Edge type:** {file-swap|spawn|crafting|tool-depletion}
**Verb:** `{verb}`
**Target:** `{target-id}` — file does not exist in any scanned directory

**Found by:** Mutation Edge Checker (`scripts/mutation-edge-check.lua`)

**Fix:** Create `src/meta/objects/{target-id}.lua` with all required fields (id, template, on_feel, keywords, name, description).
```

---

## Integration with Existing Infrastructure

| Component | How It Integrates |
|-----------|-------------------|
| `scripts/meta-lint/lint.py` | Receives target file list from Lua extractor — applies full 200+ rules |
| `scripts/meta-lint/squad_routing.py` | Routes lint violations to correct squad member |
| `src/engine/loader/init.lua` | Pattern reference for sandbox loading. NOT imported — extractor is self-contained. |
| `src/engine/mutation/init.lua` | Architectural reference only. The extractor validates the DATA that this module would consume at runtime. |

---

## Estimated Effort

| Phase | Owner | Estimate |
|-------|-------|----------|
| Phase 1: Documentation | Brockman | 1 hour |
| Phase 2: Lua edge extractor | Bart | 1-2 hours |
| Phase 2: Meta-lint integration | Bart | 30 min |
| Phase 3: Skill Update | Bart | 30 min |
| Phase 4: Full Run + Filing | Nelson + Bart | 1 hour |
| **Total** | | **~4-5 hours** |

---

## Success Criteria

1. `lua scripts/mutation-edge-check.lua` runs and reports all edges + broken edges
2. All 4 known broken edges are detected and reported
3. `paper.lua`'s dynamic mutation is flagged, not followed
4. `--targets` output pipes cleanly to `python scripts/meta-lint/lint.py`
5. Full 200+ rule coverage applies to every mutation target
6. GitHub issues filed for every broken edge
7. Skill doc created for reuse
