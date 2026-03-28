# Meta-Lint: Python Structural Validator

`scripts/meta-lint/lint.py` is the core Python linter that validates 200+ structural rules on game objects, rooms, and other meta files. It ensures consistency, completeness, and adherence to the object schema before runtime.

## Overview

The meta-linter applies rules in two modes:

1. **Direct mode:** `python lint.py <file>` — validates a single `.lua` file
2. **Mutation mode:** Called by the mutation graph linter to validate all mutation targets

## What It Validates

### Core Fields
- **GUID:** Every object must have a valid Windows GUID (format validation)
- **ID:** Matches filename conventions (kebab-case)
- **Name & Description:** Present and non-empty
- **Sensory Fields:** 
  - `on_feel` is **mandatory** (primary dark sense)
  - `on_smell`, `on_listen`, `on_taste` strongly recommended
  - Narration present for sensory state changes

### Templates & Inheritance
- **Template field:** Valid template exists (room, furniture, container, sheet, small-item)
- **Inheritance:** Parent template fields are correctly overridden
- **Instance fields:** Rooms properly declare instances with valid `type_id` references

### Object Behavior
- **FSM states:** All declared states are well-formed; transitions reference valid states
- **Mutations:** All `becomes` targets reference existing files; `spawns` arrays are non-empty
- **Crafting recipes:** `becomes` targets are valid, ingredients list is non-empty
- **Loot tables:** Templates exist, weights are positive, conditional keys are valid

### Containers
- **Weight/size constraints:** `max_weight`, `max_volume` are positive, containment rules are consistent
- **Nesting depth:** Containers don't nest beyond safe limits
- **Capacity matches contents:** Declared capacity is consistent with actual size/weight constraints

### Rooms
- **Exits:** All exit targets reference valid room IDs
- **Instances:** All room objects have valid `type_id` references; placement is sensible

## Mutation Graph Linter Integration

When validating mutation chains, the `mutation-edge-check.lua` extractor outputs a list of valid mutation targets. These are passed to the meta-linter:

```bash
# Extract edges, collect valid targets, lint each
lua scripts/mutation-edge-check.lua --targets | python scripts/meta-lint/lint.py -
```

Or via the wrapper:
```bash
# Full pipeline (edges + lint)
./scripts/mutation-lint.ps1
```

This ensures that:
- **Edge exists:** Target file is present on disk
- **Target is valid:** Target file passes all 200+ structural rules
- **Mutation is safe:** Both source and target are well-formed

## Environment Profiles

The linter supports different validation profiles for different contexts:

```bash
# Production rules (strictest)
python scripts/meta-lint/lint.py myobject.lua --env prod

# Development rules (relaxed)
python scripts/meta-lint/lint.py myobject.lua --env dev

# Test rules (focus on critical issues)
python scripts/meta-lint/lint.py myobject.lua --env test
```

Profiles are defined in `config.py` and control rule severity, exclusions, and fix recommendations.

## Usage

### Quick Check
```bash
python scripts/meta-lint/lint.py src/meta/objects/candle.lua
```

Output on success (no rules violated):
```
(no output)
Exit code: 0
```

Output on failure:
```
ERROR: Required field missing: on_feel
WARNING: Field 'name' is empty
Exit code: 1
```

### Batch Linting
```bash
# Lint all objects
python scripts/meta-lint/lint.py src/meta/objects/*.lua

# Lint all rooms
for room in src/meta/rooms/*.lua; do
    python scripts/meta-lint/lint.py "$room"
done
```

### Format Options
```bash
# Text output (default)
python scripts/meta-lint/lint.py myobject.lua --format text

# JSON output (for CI integration)
python scripts/meta-lint/lint.py myobject.lua --format json
```

JSON format returns violations as structured data for automated processing.

## Rule Architecture

### Rule Registry (`rule_registry.py`)
Central registry of all 200+ rules. Each rule:
- Has a unique ID (e.g., `R-001-GUID-INVALID`)
- Declares its severity (ERROR, WARNING, INFO)
- Specifies which profiles it applies to
- Implements a `check(obj)` method

### Squad Routing (`squad_routing.py`)
Maps rule violations to responsible agents for quick problem escalation:
- **Flanders** owns object definitions (missing on_feel, bad loot tables, etc.)
- **Moe** owns room definitions (broken exits, bad instances, etc.)
- **Smithers** owns parser/UI impact (narration issues, sensory field gaps)
- **Bart** owns engine-level constraints (FSM, containment, material properties)

When a rule fails, the linter suggests who should fix it.

## Output Format

### Text Mode
```
src/meta/objects/poison-gas-vent.lua:
  ERROR: Mutation target missing: poison-gas-vent-plugged
    → (objects, mutations, plug verb)
    → Squad routing: Flanders (Object definitions)
  
  WARNING: Sensory narration missing for state 'plugged'
    → (objects, sensory, narration)
    → Squad routing: Smithers (Parser/UI)
```

### JSON Mode
```json
{
  "file": "src/meta/objects/poison-gas-vent.lua",
  "violations": [
    {
      "id": "R-008-MUTATION-TARGET-MISSING",
      "severity": "ERROR",
      "message": "Mutation target missing: poison-gas-vent-plugged",
      "field": "mutations.plug.becomes",
      "owner": "Flanders",
      "fixable": true
    }
  ],
  "exit_code": 1
}
```

## How It Works

1. **Load:** Parse the `.lua` file (linter does NOT execute Lua; it parses AST)
2. **Validate:** Run all applicable rules from the registry
3. **Collect:** Aggregate violations with metadata (field, severity, responsible agent)
4. **Output:** Format violations per the requested output mode
5. **Exit:** Return 0 (all passed) or 1 (violations found)

## Configuration

Edit `config.py` to:
- Add new environment profiles
- Adjust rule severity per profile
- Exclude rules for specific contexts
- Configure fix recommendations

## Integration with CI

The mutation-lint pipeline is designed for pre-deploy gates:

```powershell
# Pre-merge check: lint all changed objects
.\scripts\mutation-lint.ps1 -Env "test"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Lint failed - PR blocked"
    exit 1
}
```

This prevents broken mutations from entering production.

## See Also

- `docs/testing/mutation-graph-linting.md` — Full mutation pipeline documentation
- `scripts/mutation-edge-check.lua` — Edge extraction (Stage 1 of pipeline)
- `.squad/routing.md` — Squad ownership boundaries
- `plans/linter/mutation-graph-linter-design.md` — Design overview
