# Naming and Architecture for the Meta-Compiler

**Author:** Frink  
**Date:** 2026-03-28  
**Focus:** What to call it, how it fits into the project, design principles

---

## Executive Summary

**Tool Name:** `meta-check` (or `meta-validator`)  
**Full Name:** MMO Meta Validator — validates `.lua` object and room definitions  
**Metaphor:** Static analyzer / schema validator (not quite a compiler, but uses compiler techniques)  
**Input:** Path to `.lua` file or directory  
**Output:** JSON-formatted error list (or human-readable CLI output)  
**Architecture:** CLI tool for CI/CD integration, optional IDE extension

---

## 1. Naming Analysis

### Candidates

| Name | Pros | Cons |
|------|------|------|
| **meta-check** | Clear, short, emphasizes validation | Generic |
| **meta-validator** | Explicit about function | Verbose |
| **meta-analyzer** | Suggests deep analysis | Implies output code generation |
| **meta-compiler** | Technically accurate (compiler techniques) | Misleading (produces no compiled output) |
| **lua-lint** | Familiar to Lua devs | Implies cosmetic style checking |
| **object-lint** | Domain-specific | Doesn't cover rooms |
| **schema-check** | Emphasizes validation rules | Too generic, not Lua-specific |
| **luacheck** | Concise, existing tool name (conflict) | Conflicts with existing `luacheck` linter |

### Recommendation: **meta-check**

**Rationale:**
- Short and memorable
- Clear: checks the "meta" layer (objects, rooms, templates)
- Part of established naming: "meta-compiler" (concept) → "meta-check" (tool)
- Fits alongside future tools: `meta-lint`, `meta-test`, `meta-profile`
- Not trademarked or widely used in Lua ecosystem

### Full Name

**"MMO Meta Validator"** — Long form for documentation
**"meta-check"** — Short form for CLI commands, files, documentation

---

## 2. Conceptual Model: Is It a Compiler?

### Compiler vs. Validator

**A compiler is:**
- Reads source code in language A
- Parses it into intermediate form (AST)
- Analyzes it (type checking, optimization)
- Generates target code in language B
- Produces executable output

**A validator is:**
- Reads source code or data
- Parses it into intermediate form (AST)
- Analyzes it (schema checking, invariant validation)
- Reports errors/warnings
- Produces no executable output

### Our Tool

- ✅ Uses compiler-style techniques (lexer, parser, semantic analysis)
- ❌ Doesn't produce compiled output (`.lua` files are not transformed)
- ✅ Validates against domain schema (objects, rooms, templates)
- ✅ Analyzes for semantic errors (missing fields, broken references, invalid FSM)
- ✅ Reports structured errors

**Classification: Static analyzer / Domain-specific validator**

**Better metaphors:**
- **Static analyzer** (like Pylint, ESLint, clippy)
- **Schema validator** (like JSON Schema validators)
- **Domain-specific validator** (validates our specific domain)
- **Semantic analyzer** (validates meaning, not just syntax)

### Why "meta-compiler" Works (Technically)

The term "compiler" in computer science includes:
- **Front-end:** Lexer, parser, semantic analysis → IR
- **Back-end:** Optimization, code generation → output

Our tool is a **"compiler front-end"** — it does lexing, parsing, and semantic analysis, but stops before code generation. The game engine is the "back-end" that consumes the validated `.lua` files.

So "meta-compiler" is **technically correct but slightly misleading.** Use it for architecture discussions; use "meta-check" for user-facing naming.

---

## 3. Tool Architecture

### Design Principles

1. **Layered:** Lexer → Parser → Semantic Analyzer → Error Reporter
2. **Composable:** Each phase is independent; can be tested separately
3. **Extensible:** Easy to add new validation rules without changing core
4. **Fast:** Processes 100+ files in <5 seconds
5. **Helpful:** Errors include line, column, context, suggestion

### Component Structure

```
meta-check/
├── cli.py                    # Entry point, argument parsing
├── parser.py                 # Lexer + Parser (Lark)
├── ast_nodes.py              # AST data structures
├── semantic_analyzer.py      # Validation orchestrator
├── validators/               # Validation modules
│   ├── field_validator.py    # Required/optional fields
│   ├── type_validator.py     # Field type checking
│   ├── reference_validator.py # Cross-reference checks
│   ├── fsm_validator.py      # FSM-specific rules
│   └── nesting_validator.py  # Deep-nesting rules
├── schema.py                 # Schema definitions (per template)
├── error_reporter.py         # Error formatting
└── tests/
    ├── test_parser.py
    ├── test_validators.py
    └── test_end_to_end.py
```

### Data Flow

```
File (torch.lua)
    ↓
Lexer (tokenization)
    ↓
Parser (AST construction)
    ↓
Semantic Analyzer
    ├── Field Validator (required fields present?)
    ├── Type Validator (correct types?)
    ├── Reference Validator (cross-references valid?)
    ├── FSM Validator (state/transition rules?)
    └── Nesting Validator (nesting rules?)
    ↓
Error Collector
    ↓
Error Reporter (format errors)
    ↓
Output (JSON or human-readable)
```

### Input/Output

**Input:** `.lua` file or directory

```bash
meta-check src/meta/objects/torch.lua          # Single file
meta-check src/meta/objects/                   # Directory
meta-check src/meta/                           # Recursive
```

**Output: JSON (machine-readable)**

```json
{
  "file": "src/meta/objects/torch.lua",
  "status": "error",
  "errors": [
    {
      "line": 12,
      "column": 5,
      "type": "missing_field",
      "field": "template",
      "message": "Required field 'template' is missing",
      "expected": "string",
      "suggestion": "Add: template = \"small-item\""
    },
    {
      "line": 35,
      "column": 10,
      "type": "invalid_reference",
      "field": "material",
      "value": "unobtanium",
      "message": "Material 'unobtanium' does not exist in registry",
      "valid_options": ["wood", "stone", "iron", "wax", "fabric", "wool", "bone"],
      "suggestion": "Use one of the valid materials listed above"
    }
  ]
}
```

**Output: Human-Readable (CLI default)**

```
Error: src/meta/objects/torch.lua

  1 error(s) found:

  Line 12, Column 5 [missing_field]
    Required field 'template' is missing
    Expected: string
    Suggestion: Add: template = "small-item"

  Line 35, Column 10 [invalid_reference]
    Material 'unobtanium' does not exist in registry
    Valid options: wood, stone, iron, wax, fabric, wool, bone
    Suggestion: Use one of the valid materials listed above

Summary: 1 object(s) validated, 2 error(s) found
```

---

## 4. Integration Points

### 1. Pre-Commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

python scripts/meta-check.py --staged --fail-on-error

if [ $? -ne 0 ]; then
  echo "Validation failed. Fix errors before committing."
  exit 1
fi
```

**Triggers:** On `git commit`, validates only changed `.lua` files in meta/  
**Blocks:** If validation fails, commit is blocked  
**Timing:** ~1 second for changed files

### 2. GitHub Actions CI/CD

```yaml
# .github/workflows/meta-check.yml
name: Validate Meta Objects

on:
  push:
    branches: [main]
  pull_request:

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - run: pip install -q lark
      - run: python scripts/meta-check.py src/meta/ --fail-on-error --json > results.json
      - if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: validation-results
          path: results.json
      - if: failure()
        run: cat results.json | python -m json.tool | head -50 && exit 1
```

**Triggers:** On every push to main and every PR  
**Fails:** If any errors found  
**Output:** JSON artifact for debugging  
**Timing:** ~5 seconds for full suite

### 3. IDE Extension (Optional, Future)

```typescript
// VSCode extension: .vscode/meta-check.js
import { spawn } from 'child_process';

export function activateMeta(context) {
  const diagnosticCollection = languages.createDiagnosticCollection('meta');
  
  workspace.onDidSaveTextDocument(doc => {
    if (!doc.fileName.includes('src/meta')) return;
    
    const proc = spawn('python', ['scripts/meta-check.py', doc.fileName, '--json']);
    let output = '';
    
    proc.stdout.on('data', (data) => output += data);
    proc.on('close', () => {
      const results = JSON.parse(output);
      const diagnostics = results.errors.map(e => new Diagnostic(
        new Range(e.line - 1, e.column - 1, e.line, e.column),
        e.message,
        DiagnosticSeverity.Error
      ));
      diagnosticCollection.set(doc.uri, diagnostics);
    });
  });
}
```

**Triggers:** On file save  
**Shows:** Inline errors with suggestions  
**Timing:** ~2 seconds per file

### 4. Manual Use (Lisa)

```bash
# Lisa's workflow: validate an object before committing
python scripts/meta-check.py src/meta/objects/new-vase.lua

# Output:
# ✓ new-vase.lua: 1 object validated, 0 errors

# Or:
# ✗ new-vase.lua: 1 error(s) found
#   Line 8, Column 5 [missing_field]
#     Required field 'material' is missing
```

---

## 5. CLI Interface

### Basic Commands

```bash
# Validate single file
meta-check src/meta/objects/torch.lua

# Validate directory
meta-check src/meta/objects/

# Validate with options
meta-check src/meta/ --strict         # Fail on warnings
meta-check src/meta/ --json           # JSON output
meta-check src/meta/ --fail-on-error  # Exit with status 1 on error
meta-check src/meta/ --verbose        # Detailed output
meta-check src/meta/ --show-suggestions  # Include suggestions

# Check only staged files (pre-commit integration)
meta-check --staged

# Check specific template type
meta-check src/meta/objects/ --template small-item
```

### Return Codes

```
0   : All files validated successfully, no errors
1   : Validation errors found (default) or --fail-on-error set
2   : Usage error (bad arguments, file not found, etc.)
```

### Environment Variables

```bash
META_REGISTRY="/path/to/custom/registry.lua"  # Override material registry
META_TEMPLATES="/path/to/custom/templates/"   # Override templates
META_STRICT=1                                   # Default to --strict
```

---

## 6. Schema Definition (Per Template)

### How Schemas Are Defined

```python
# schema.py
TEMPLATES = {
    "small-item": {
        "required": [
            "id", "template", "guid", "name", "material",
            "keywords", "size", "weight", "description"
        ],
        "optional": [
            "categories", "portable", "container", "capacity",
            "on_feel", "on_smell", "on_listen", "on_taste",
            "states", "transitions", "initial_state", "mutations"
        ],
        "fields": {
            "id": {"type": "string", "pattern": "^[a-z0-9\-]+$"},
            "template": {"type": "string", "enum": ["small-item"]},
            "guid": {"type": "string", "pattern": "^\\{[0-9a-f\\-]+\\}$"},
            "material": {"type": "string", "reference": "material_registry"},
            "keywords": {"type": "array[string]"},
            "size": {"type": "number", "min": 0, "max": 10},
            "weight": {"type": "number", "min": 0},
        }
    },
    "furniture": {
        "required": ["id", "template", "guid", "name", "material", "keywords", "size", "weight", "description"],
        "optional": ["portable", "container", "capacity", ...],
        "fields": {
            "portable": {"type": "boolean", "default": False},
            ...
        }
    },
    "room": {
        "required": ["id", "template", "guid", "name", "level", "keywords", "description", "instances", "exits"],
        "optional": ["on_feel", "on_enter", "on_smell", "temperature", ...],
        "fields": {
            "instances": {"type": "array[table]", "items_schema": "room_instance"},
            "exits": {"type": "table[string => exit]"},
            ...
        }
    }
}
```

### Schema is Declarative + Extensible

Each schema entry defines:
- **Required fields** — must be present
- **Optional fields** — may be omitted
- **Field constraints** — type, enum, pattern, min/max, references
- **Special rules** — FSM validation, nesting rules, cross-references

---

## 7. Error Categories

### Parser Errors (Syntax)

```
[parse_error] Invalid Lua syntax
  Expected: table literal or function
  Got: "invalid"
  Line 5, Column 1
```

### Type Errors (Semantic)

```
[type_error] Wrong type for field 'weight'
  Expected: number
  Got: string
  Value: "heavy"
  Line 12, Column 10
```

### Validation Errors (Domain)

```
[missing_field] Required field missing
  Field: 'material'
  Template: 'small-item'
  Line 8, Column 1
  Suggestion: Add: material = "wood"
```

```
[invalid_reference] Cross-reference broken
  Field: 'material'
  Value: 'unobtanium'
  Expected: one of [wood, stone, iron, ...]
  Line 35, Column 10
```

```
[fsm_error] Invalid FSM definition
  Type: missing_state
  Transition references state 'lit' but no such state exists
  Line 75, Column 1
  Suggestion: Add state 'lit' to states table
```

```
[nesting_error] Invalid nesting
  Field: 'on_top'
  Context: object (not allowed in objects, only in rooms)
  Line 45, Column 1
```

---

## 8. Why This Architecture Works

### Separation of Concerns

- **Parser:** Doesn't know about schemas; just builds AST
- **Validators:** Don't know about parsing; just check AST against rules
- **Error reporter:** Doesn't know about parsing or validation; just formats errors
- **CLI:** Doesn't know about parsing/validation; just orchestrates components

### Testing

- **Parser tests:** "Does `{ id = "x", name = "y" }` parse correctly?"
- **Validator tests:** "Does `{ id = 123 }` fail type check?"
- **Integration tests:** "Does broken reference get caught?"

### Extensibility

- **Add new validation rule:** Add new validator class, inherit from base
- **Add new template type:** Add entry to `TEMPLATES` schema dict
- **Add new error type:** Add new `Error` subclass
- **Add new output format:** Add new formatter class

---

## 9. Next Steps (Bart's Work)

Once this research is complete, Bart should:

1. **Design the parser** — Finalize Lark EBNF grammar
2. **Define schemas** — Formalize field definitions for each template
3. **Plan validator modules** — Outline each semantic check
4. **Estimate LOC/time** — Refine implementation estimate
5. **Prototype** — Build working MVP in 1 day

---

## References

- Static analyzers: ESLint, Pylint, clippy, Lua code checkers
- Schema validators: JSON Schema, Ajv, OpenAPI validators
- Error reporting: Rust compiler error format, Babel error output
