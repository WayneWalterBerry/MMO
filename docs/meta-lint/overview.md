# Meta-Lint: Overview

**Date:** 2026-03-24  
**Version:** 1.0  
**Author:** Brockman (Documentation)  
**Audience:** Developers, CI/CD pipeline, QA  

---

## What is Meta-Lint?

Meta-Lint is a **static validation tool** that analyzes Lua object, room, and level definition files before they reach the game engine. It combines compiler-like semantic analysis with linter-like style enforcement to catch bugs at CI time, not runtime.

**In short:** Before a `.lua` file in `src/meta/` is merged, meta-lint verifies that every field exists, has the correct type, references valid resources, and follows core principles.

---

## Why It Exists

### The Problem

The MMO engine is permissive by design. Its Lua loader:
- Checks syntax (compiles without error)
- Validates template resolution (inherits from base template)
- Handles instance flattening (room tree → flat array)
- **Does NOT check field-level correctness**

This is the right trade-off for runtime performance. But it means broken objects reach the game:

- **38 historical bugs** found in `src/meta/` commits (Frink's audit):
  - 21 missing metadata fields (e.g., `material` on 20 objects)
  - 10 invalid cross-references (e.g., GUID mismatches in room files)
  - 3 structural inconsistencies (FSM states missing surfaces)
  - 1 architectural violation (furniture with container properties)

- **22 validation gaps** identified in the loader (Bart's audit):
  - No required field checking
  - No type validation
  - No FSM consistency checks
  - No sensory completeness (every object must have `on_feel`)
  - No material registry validation
  - No keyword collision detection

**Result:** Players encounter invisible objects (missing `on_feel`), unreachable objects (missing keywords), and state crashes (FSM transitions to non-existent states).

### The Solution

Meta-Lint is the **primary quality gate** for Lisa (Object Testing Specialist) and automated CI. It enforces:

1. **Structural correctness** — All required fields present, correct types
2. **Reference integrity** — GUIDs unique, materials/templates/rooms exist
3. **FSM validity** — States reachable, transitions consistent
4. **Core principles** — Every object has `on_feel`, proper nesting syntax, material consistency
5. **Style consistency** — Naming conventions, field ordering, sensory completeness

---

## Goals

| Goal | Metric |
|------|--------|
| **Catch structural bugs at CI** | 100% of 38 historical bug types must be detectable |
| **No false positives** | <2% of merge-blocked PRs are false alarms |
| **Fast execution** | <500 ms per full meta validation (pre-commit viable) |
| **Clear error messages** | File, line, severity, rule ID, message, suggested fix |
| **Integration** | GitHub Actions gate + pre-commit hook + manual invocation |

---

## Both a Compiler AND a Linter

Meta-Lint is **hybrid**:

### Compiler Aspect
- Parses Lua table syntax (nested objects, arrays, FSM definitions)
- Builds an AST (Abstract Syntax Tree)
- Performs semantic analysis (are all references valid?)
- Catches structural errors that would crash the engine

### Linter Aspect
- Enforces naming conventions (`id` must be kebab-case)
- Suggests improvements (sensory completeness)
- Detects style inconsistencies (missing `location = nil`)
- Warns about anti-patterns (non-portable furniture, zero-capacity containers)

---

## Meta-Lint as Lisa's Primary Tool

Lisa (Object Testing Specialist) will use meta-lint **before any manual testing**:

```bash
# Run meta-lint on a new object file
python scripts/meta-lint/lint.py src/meta/objects/my-new-item.lua

# Scan an entire directory
python scripts/meta-lint/lint.py src/meta/objects/

# Full meta validation (objects + rooms + levels)
python scripts/meta-lint/lint.py src/meta/
```

**Workflow:**
1. Developer creates `src/meta/objects/candle.lua`
2. Developer (or CI) runs meta-lint → catches missing fields, typos, broken references
3. Lisa reviews, validates gameplay semantics
4. Object merges only if meta-lint passes + Lisa approves

---

## Architecture Overview

Meta-Lint is a **6-phase pipeline**:

```
Phase 1: Tokenization
  ↓ Lua source → function placeholders + stripped preambles
Phase 2: Preprocessing
  ↓ Normalize for Lark parser
Phase 3: Lark Earley Parser
  ↓ Tokenized source → AST (nested table structure)
Phase 4: Semantic Analysis
  ↓ Validate AST against template-specific schemas
Phase 5: Cross-File Analysis
  ↓ GUID uniqueness, keyword collisions, reference resolution
Phase 6: Error Reporter
  ↓ File, line, severity, rule, message, suggestion
```

**Technology:** Python 3 + Lark (battle-tested, recursive-descent Earley parser)

**Why Python + Lark:**
- Lark is proven: successfully parses **83/83 objects** with ~30-line grammar
- Python ecosystem: easy CI integration, pre-commit hooks
- Zero runtime dependencies: no external compilation required
- Extensible: grammar handles room files, level files, and future features

---

## Key Design Insight

**82 of 83 objects are pure data tables** (return { ... } with only literals, tables, and functions). Wall-clock.lua is the sole outlier—it generates states/transitions with for-loops, then references them by variable name. Meta-Lint treats function bodies as opaque (validated by Lua runtime) and focuses on the data layer.

---

## What Meta-Lint Does NOT Do

- **Runtime validation** — Function logic is Lua's job (e.g., `on_look` implementations)
- **Gameplay semantics** — "Is this object fun?" is Lisa's job, not the compiler's
- **Mutation testing** — Verifying a mutation actually works requires engine execution
- **Type checking beyond literals** — Identifier references (wall-clock pattern) can't be validated statically

---

## Next: Read the Documentation

1. **[architecture.md](architecture.md)** — The 6-phase pipeline, technical design
2. **[usage.md](usage.md)** — How to run meta-lint, CLI interface
3. **[rules.md](rules.md)** — Complete catalog of 144 validation rules (15 categories)
4. **[schemas.md](schemas.md)** — Template-specific field contracts

---

## References

- **Bug Catalog:** `resources/research/meta-compiler/bug-catalog.md` (38 bugs, 7 categories)
- **Cross-Reference Inventory:** `resources/research/meta-compiler/cross-reference-inventory.md` (103 GUIDs, 23 materials, 401 keywords)
- **Lark Grammar Proof:** `scripts/meta-lint/lua_grammar.py` (parses 83/83 objects)
- **Validation Audit:** `resources/research/meta-compiler/existing-validation-audit.md` (loader checks 3 things, 22 gaps)
- **Architecture Decision:** `.squad/decisions/inbox/bart-lark-grammar.md` (Python + Lark proven strategy)
- **Acceptance Criteria:** `docs/meta-lint/acceptance-criteria.md` (144 checks, Lisa's specification)

