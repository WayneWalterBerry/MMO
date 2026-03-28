# Mutation Graph Linting

Mutation graph linting validates that all mutation chains in the game engine are safe — every mutation target file exists and passes structural validation.

## Motivation

In MMO, **code IS state** (see D-14 in `.squad/decisions.md`). When a player performs an action that triggers a mutation — breaking a mirror, depleting a tool, defeating a creature — the engine **rewrites the .lua file itself**. The broken mirror becomes `mirror-broken.lua` in the registry, and all subsequent interactions use that new code.

If a mutation target file doesn't exist, the player encounters a runtime error during gameplay. This is the worst possible time to discover the problem.

### Real-world Example Trace

```
1. Player: "plug vent with cloth"
2. Engine: looks up mutations["plug"] on poison-gas-vent.lua
3. Engine: finds becomes = "poison-gas-vent-plugged"
4. Engine: tries to load src/meta/objects/poison-gas-vent-plugged.lua
5. Engine: FILE NOT FOUND → runtime error / silent failure
```

Mutation graph linting catches this at steps 2–3, **statically, before the game runs**. Combined with structural validation (Python meta-lint), it ensures:

- **Edge existence:** Every mutation target resolves to an existing `.lua` file
- **Target validity:** Every target file passes 200+ structural rules (missing `on_feel`, bad GUID, invalid state declarations, etc.)

## How It Works: Expand-and-Lint Pipeline

The mutation linter uses a two-stage pipeline:

### Stage 1: Lua Edge Extraction

`scripts/mutation-edge-check.lua` scans all `.lua` files in `src/meta/`, loads each in a sandbox, and **extracts 12 types of mutation edges**:

| Mechanism | Data Path | Example |
|-----------|-----------|---------|
| File-swap | `mutations[verb].becomes` | `poison-gas-vent` → `poison-gas-vent-plugged` |
| Spawns (mutation) | `mutations[verb].spawns[]` | `blanket` tear → `{"cloth", "cloth"}` |
| Spawns (transition) | `transitions[].spawns[]` | `mirror` break → `{"glass-shard"}` |
| Crafting | `crafting[verb].becomes` | `cloth` sew → `terrible-jacket` |
| Tool depletion | `on_tool_use.when_depleted` | match burned → (future-proofed) |
| Loot (always) | `loot_table.always[].template` | `wolf` loot → `gnawed-bone` |
| Loot (on death) | `loot_table.on_death[].item.template` | `wolf` death → `silver-coin` |
| Loot (variable) | `loot_table.variable[].template` | `wolf` dynamic loot → `copper-coin` |
| Loot (conditional) | `loot_table.conditional[key][].template` | `wolf` fire_kill → `charred-hide` |
| Corpse cooking | `death_state.crafting[verb].becomes` | `rat` cook → `cooked-rat-meat` |
| Butchery | `death_state.butchery_products.products[].id` | `wolf` → `wolf-meat`, `wolf-hide` |
| Creature objects | `behavior.creates_object.template` | `spider` creates → `spider-web` |

For each edge, the extractor checks: **Does the target file exist?** Broken edges are logged; valid target files are collected for the next stage.

### Stage 2: Python Linting

All valid target files are passed to the existing Python meta-lint engine (`scripts/meta-lint/lint.py`), which applies 200+ structural rules to each target:

- Required fields: `on_feel` (always dark-readable), `guid`, valid state transitions
- Naming consistency: IDs match conventions
- FSM validity: all `from` states exist, `transitions` are well-formed
- Container constraints: `max_weight` vs. `contains`, nesting depth
- And 195+ other rules

This two-stage approach divides responsibility:
- **Lua extractor:** Graph traversal (is the edge reachable?)
- **Python linter:** Structural validation (does the target obey the object schema?)

## Running the Tools

### Quick Start: Check for Broken Edges

```bash
lua scripts/mutation-edge-check.lua
```

Output:
```
=== Mutation Edge Report ===

Files scanned:    206
Subdirs found:    7
Edges found:      66
Valid targets:    61
Broken edges:     5
Dynamic paths:    1

--- Broken Edges ---
  src/meta/objects/poison-gas-vent.lua -> poison-gas-vent-plugged
    via: mutations.becomes (verb: plug)
  src/meta/objects/bedroom-hallway-door-north.lua -> wood-splinters
    via: mutations.becomes (verb: break)
  ...

All mutation edges checked.
```

Exit code: `0` if all edges resolve; `1` if broken edges found.

### Full Pipeline: Check Edges + Lint Targets

```bash
# PowerShell
.\scripts\mutation-lint.ps1

# Bash
./scripts/mutation-lint.sh
```

This runs:
1. **Phase 1:** Edge existence check (reports broken edges)
2. **Phase 2:** Lint all valid targets in parallel (or sequentially on PS5)

Example output:
```
=== Phase 1: Edge Existence Check ===
... (edge check output)

=== Phase 2: Target Lint Validation ===
--- src/meta/objects/candle.lua ---
(no output if all rules pass)

--- src/meta/objects/poison-gas-vent-plugged.lua ---
ERROR: Required field missing: on_feel
```

### Edges Only (Skip Lint)

```bash
.\scripts\mutation-lint.ps1 -EdgesOnly
```

Useful for quick checks during development.

### Target Files Only (For Custom Lint)

```bash
lua scripts/mutation-edge-check.lua --targets
```

Outputs one valid target file path per line (deduplicated). Use this to pipe to custom validation:

```bash
lua scripts/mutation-edge-check.lua --targets | xargs -I {} echo "Checking: {}"
```

### Different Lint Profiles

The Python linter supports environment-specific rules:

```bash
.\scripts\mutation-lint.ps1 -Env "prod"
```

Valid profiles: `dev`, `test`, `prod` (see `scripts/meta-lint/config.py`).

## Known Broken Edges

As of this revision, 5 broken edges exist (4 target files missing):

| Source | Target | Mechanism | Verb |
|--------|--------|-----------|------|
| `poison-gas-vent.lua` | `poison-gas-vent-plugged` | `mutations.becomes` | plug |
| `bedroom-hallway-door-north.lua` | `wood-splinters` | `mutations.becomes` | break |
| `bedroom-hallway-door-south.lua` | `wood-splinters` | `mutations.becomes` | break |
| `courtyard-kitchen-door.lua` | `wood-splinters` | `mutations.becomes` | break |

These are tracked as GitHub issues. To see all:

```bash
lua scripts/mutation-edge-check.lua | grep "Broken Edges" -A 20
```

### Fixing a Broken Edge

1. **Create the target file:** If `poison-gas-vent-plugged` is missing, create `src/meta/objects/poison-gas-vent-plugged.lua` with the mutated state.
2. **Run the linter:** `lua scripts/mutation-edge-check.lua` to verify the edge is now valid.
3. **Lint the target:** `python scripts/meta-lint/lint.py src/meta/objects/poison-gas-vent-plugged.lua` to ensure it passes all rules.

## Dynamic Mutations

Some objects declare dynamic mutations — mutations where the target is generated at runtime from player input. Example:

```lua
mutations = {
    write = {
        dynamic = true,
        handler = function(context, content)
            -- generates target like "paper-001-written"
        end
    }
}
```

The edge extractor **logs these but does not follow them**. Why? The target ID cannot be predicted statically. The mutation engine (`src/engine/mutation/init.lua`) handles dynamic targets at runtime, generating filenames based on player action. Static analysis cannot enumerate these.

Current dynamic mutations:
- `paper.lua` write verb

## Architecture

The mutation graph linter is part of the broader **meta-lint system**:

```
src/meta/
  ├── objects/          (206 .lua files, 66 mutation edges)
  ├── rooms/
  ├── templates/
  ├── injuries/
  └── levels/

scripts/
  ├── mutation-edge-check.lua     (Stage 1: edge extraction)
  ├── mutation-lint.ps1            (Wrapper: orchestrate both stages)
  ├── mutation-lint.sh
  └── meta-lint/
      ├── lint.py                  (Stage 2: Python linter, 200+ rules)
      ├── rule_registry.py
      ├── config.py
      └── squad_routing.py
```

## Future Work

### D-MUTATION-CYCLES-V2: Multi-Hop Chain Validation

Current validation checks each edge independently. Future work (Phase 2) will trace **complete mutation chains**:

```
candle (lit) → candle-burned → ash
```

This requires:
- A-→B and B-→C edges to exist
- Target B passes lint (to ensure C is reachable)
- Cycle detection (A-→B-→A is harmless but should be logged)

### Parts[] Extraction

Some creatures (birds, large beasts) have `parts[] = { name = "", template = "..." }` that spawn loot on death. Future extraction will validate these templates exist.

## See Also

- `plans/linter/mutation-graph-linter-design.md` — Design overview and motivation
- `scripts/meta-lint/README.md` — Python linter rules and integration
- `docs/architecture/objects/core-principles.md` — Principle 1: Code mutation IS state change
- `.squad/decisions.md` — D-14 (true code mutation)
