---
name: "mutation-graph-lint"
description: "Expand-and-lint pattern for validating mutation edges in Lua object definitions"
domain: "linting, mutation-system, code-quality"
confidence: "high"
source: "earned — WAVE-0/1/2 mutation-graph linter implementation (plans/linter/mutation-graph-linter-implementation-phase1.md)"
---

## Context

The MMO engine uses code mutation as state change (D-14): when a candle breaks, `candle.lua` is rewritten to `candle-broken.lua` at runtime. Every such mutation creates a directed edge in an implicit graph. If a target file doesn't exist, the mutation silently fails at runtime.

This skill applies when:
- Adding or modifying `mutations`, `transitions`, `crafting`, `on_tool_use`, `loot_table`, `butchery_products`, or `behavior.creates_object` fields in object `.lua` files
- Validating that all mutation targets resolve to real files
- Running CI checks on the mutation graph
- Extending the linter with new extraction mechanisms

## Patterns

### The Expand-and-Lint Pattern

Two tools, each doing what it does best:

1. **Lua edge extractor** (`scripts/mutation-edge-check.lua`) — loads `.lua` object files in a sandbox, extracts all mutation edges from 12 mechanisms, verifies target files exist.
2. **Python meta-linter** (`scripts/meta-lint/lint.py`) — validates the content of target files against 200+ rules.

The extractor outputs target file paths; the linter consumes them. No custom graph library, no BFS/DFS, no cycle detection — just walk files and check edges.

### 12 Extraction Mechanisms

| # | Mechanism | Field Path |
|---|-----------|------------|
| 1 | File swap | `mutations[verb].becomes` |
| 2 | Spawn | `mutations[verb].spawns[]` |
| 3 | Transition spawn | `transitions[i].spawns[]` |
| 4 | Crafting | `crafting[verb].becomes` |
| 5 | Depletion | `on_tool_use.when_depleted` |
| 6 | Loot (always) | `loot_table.always[].template` |
| 7 | Loot (on_death) | `loot_table.on_death[].item.template` |
| 8 | Loot (variable) | `loot_table.variable[].template` |
| 9 | Loot (conditional) | `loot_table.conditional.{key}[].template` |
| 10 | Butchery | `butchery_products.products[].id` |
| 11 | Creature spawn | `behavior.creates_object.template` |
| 12 | Death-state recursion | All of the above nested under `death_state.*` |

Dynamic mutations (`mutations[verb].dynamic = true`) are flagged but not followed — they use runtime function-based mutation that can't be statically resolved.

### CLI Modes

```bash
# Human-readable report (default)
lua scripts/mutation-edge-check.lua

# JSON output for tooling/CI integration
lua scripts/mutation-edge-check.lua --json

# Target file paths to stdout (for piping to meta-lint)
lua scripts/mutation-edge-check.lua --targets
```

`--json` and `--targets` are mutually exclusive; `--json` wins if both specified.

### JSON Schema

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
    { "from": "source-id", "to": "target-id", "type": "file-swap", "verb": "break", "source_file": "src/meta/objects/mirror.lua" }
  ],
  "dynamic": [
    { "from": "paper", "verb": "write", "mutator": "mutations" }
  ]
}
```

Type mapping from mechanism: `mutations.becomes` → `file-swap`, `mutations.spawns` / `transitions.spawns` → `spawn`, `crafting.becomes` → `crafting`, `on_tool_use.when_depleted` → `depletion`, `loot_table.*` → `loot`, `behavior.creates_object` → `creature-spawn`, `butchery_products` → `butchery`.

### Parallel Execution (D-MUTATION-LINT-PARALLEL)

The wrapper scripts (`scripts/mutation-lint.ps1`, `scripts/mutation-lint.sh`) run Lua extraction first, then pipe targets to Python lint. PowerShell 7 uses `ForEach-Object -Parallel` with collected output to avoid interleaving; PS5 falls back to sequential. Shell uses `xargs -P` with temp dir collection. Pattern: **parallel execution, sequential output display**.

### Creature-Specific Nesting

Creatures (e.g., rats, spiders) use deeply nested patterns:
- `death_state.butchery_products.products[].id` — butchery yields after death
- `death_state.loot_table.*` — loot drops on death
- `behavior.creates_object.template` — creature spawns objects (e.g., webs)

The extractor handles this via a two-pass approach: extract from top-level object, then recurse into `death_state` if present.

## Examples

```bash
# Full pipeline: extract edges + lint targets
lua scripts/mutation-edge-check.lua --targets 2>warnings.txt | \
  python scripts/meta-lint/lint.py --env objects -

# CI integration: JSON output for automated processing
lua scripts/mutation-edge-check.lua --json > mutation-report.json

# PowerShell wrapper (handles both tools)
.\scripts\mutation-lint.ps1
.\scripts\mutation-lint.ps1 -EdgesOnly   # skip Python lint
```

## Anti-Patterns

- **Don't build a custom graph library** — the expand-and-lint pattern avoids graph algorithms entirely; each edge is checked independently
- **Don't duplicate lint rules in Lua** — the Python meta-linter already has 200+ rules; the Lua extractor only checks edge existence
- **Don't follow dynamic mutations** — mutations with `dynamic = true` use runtime functions that can't be statically resolved; flag them, don't trace them
- **Don't use external Lua dependencies** — the extractor must work in zero-dependency environments (Fengari browser compat)
- **Don't validate multi-hop chains in Phase 1** — A→B→C chain validation is deferred to Phase 2 (D-MUTATION-CYCLES-V2)
- **Don't add object-specific logic to the extractor** — it reads metadata generically; Principle 8 applies
