# Language Evaluation for Meta-Compiler Implementation

**Author:** Frink  
**Date:** 2026-03-28  
**Focus:** Choosing the best language to build the meta-compiler

---

## Executive Summary

**Recommendation: Python + Lark**

Rationale:
- Fastest to build (~2-3 hours for MVP)
- Easy to integrate into CI/CD (scripts/ already uses Python)
- Lark parser library is mature and well-documented
- Error messages can be excellent with minimal effort
- Team already has Python expertise

Second choice: **Rust** (if long-term performance is critical)  
Third choice: **TypeScript/Node** (if web integration is needed)

---

## 1. Python + Lark

### Strengths
✅ **Speed to MVP:** 2-3 hours for a working parser + semantic validator  
✅ **Lark library:** EBNF grammar, automatic AST, excellent for DSLs  
✅ **Error messages:** Can give precise line/column, semantic errors, suggestions  
✅ **Integration:** Already in scripts/; easy to add as CI/CD step  
✅ **Team fit:** Familiar to team; Lua is Python-like in simplicity  
✅ **Ecosystem:** Rich standard library for file I/O, regex, JSON output  
✅ **Debugging:** Easy to print/inspect AST during development  

### Weaknesses
❌ **Runtime performance:** Slower than compiled languages (not a blocker for batch validation)  
❌ **Startup time:** ~100-200ms Python startup (acceptable for CI/CD)  
❌ **Distribution:** Need Python 3.8+ installed (acceptable for dev tooling)  

### Estimated Implementation

```
Lexer/Parser (Lark grammar):    50 lines
AST Transformer:                100 lines
Semantic Analyzer:              150 lines
Field Validators:               200 lines (required fields, types, cross-refs)
FSM Validator:                  100 lines (state declarations, transitions)
Error Reporter:                 100 lines
CLI/Integration:                 50 lines
---
Total MVP:                       750 lines
```

**Time estimate:** 8-12 hours for MVP (parser + basic validation + error reporting)

### Example Workflow

```bash
# Run on single file
python meta-compiler.py src/meta/objects/torch.lua

# Run on directory
python meta-compiler.py src/meta/objects/ --strict

# Integrate with pre-commit
# .git/hooks/pre-commit calls: python meta-compiler.py src/meta/

# CI/CD (GitHub Actions)
# meta-compiler.py src/meta/ --fail-on-error
```

### Code Example (Lark-based)

```python
from lark import Lark, Transformer, v_args

# Grammar
LUA_GRAMMAR = """
    ?start: RETURN value

    ?value: table
          | STRING
          | NUMBER
          | BOOL
          | NIL

    table: LBRACE (entry (COMMA entry)* COMMA?)? RBRACE

    entry: IDENT EQUALS value

    IDENT: /[a-zA-Z_][a-zA-Z0-9_]*/
    STRING: /"[^"]*"/ | /'[^']*'/
    NUMBER: /[0-9]+(\.[0-9]+)?/
    BOOL: "true" | "false"
    NIL: "nil"
    
    RETURN: "return"
    EQUALS: "="
    COMMA: ","
    LBRACE: "{"
    RBRACE: "}"
    
    %import common.WS
    %ignore WS
    %ignore /--[^\n]*/
"""

class LuaTransformer(Transformer):
    def table(self, entries):
        return {"_type": "table", "entries": dict(entries)}
    
    def entry(self, items):
        key, value = items
        return (key, value)
    
    def IDENT(self, token):
        return str(token)

parser = Lark(LUA_GRAMMAR, transformer=LuaTransformer())

# Usage
ast = parser.parse("""
return {
    id = "torch",
    template = "small-item",
    weight = 1.5,
}
""")
```

---

## 2. Rust (nom parser combinators)

### Strengths
✅ **Performance:** ~1000x faster than Python (not needed for this task)  
✅ **Compile-time safety:** Type system prevents bugs  
✅ **Deployment:** Single binary, no runtime dependencies  
✅ **Error messages:** Can be excellent with careful error handling  
✅ **Long-term:** Best choice if this tool will run on thousands of files  

### Weaknesses
❌ **Speed to MVP:** 8-12 hours due to Rust learning curve  
❌ **Team fit:** Less familiar to team (except for experienced Rustaceans)  
❌ **Development friction:** Borrow checker, compilation time  
❌ **Overkill:** For a tool that runs a few times per day in CI/CD  

### Estimated Implementation

```
nom parser (declarative):       200 lines
Semantic Analyzer:              150 lines
Field Validators:               150 lines
FSM Validator:                  100 lines
Error Reporter:                 100 lines
CLI/Main:                        80 lines
---
Total MVP:                       780 lines
```

**Time estimate:** 10-14 hours for MVP

### When to Choose Rust
- Performance is critical (validating 10,000+ files per day)
- Distributing to end-users (single binary > Python + dependencies)
- Long-term maintenance by experienced Rust developers
- Performance-sensitive CI/CD pipeline

**For our use case: Rust is premature optimization.**

---

## 3. TypeScript/Node

### Strengths
✅ **Ecosystem:** Good parser libraries (Babel, TypeScript compiler API)  
✅ **Team fit:** Web developers familiar with TypeScript  
✅ **Integration:** Could share tooling with web-based object editor  
✅ **Speed:** Decent performance (faster than Python, slower than Rust)  
✅ **Type safety:** TypeScript catches many bugs  

### Weaknesses
❌ **Complexity:** Need Node.js + npm; package.json dependencies  
❌ **Slower than Rust:** Not fast enough to matter, but more overhead  
❌ **Unfamiliar to server team:** Wayne, Bart, Lisa likely prefer Python/Go  
❌ **Parser libraries:** Not as optimized as Lark for DSLs  

### Estimated Implementation

```
Babel/Acorn parser wrapper:     100 lines (wrapping existing parser)
Semantic Analyzer:              150 lines
Field Validators:               150 lines
FSM Validator:                  100 lines
Error Reporter:                 100 lines
CLI/Integration:                 80 lines
---
Total MVP:                       680 lines
```

**Time estimate:** 6-8 hours (faster due to smaller codebase)

### When to Choose TypeScript
- Goal: Build web UI + CLI validator together
- Team strongly prefers JavaScript/TypeScript
- Integrating with web build pipeline (webpack, etc.)

**For our use case: Not justified unless we're also building a web UI.**

---

## 4. Go

### Strengths
✅ **Simplicity:** Clean, minimal syntax; fast to learn  
✅ **Performance:** Compiled; single binary; ~50ms startup  
✅ **CLI tools:** Excellent for command-line applications  
✅ **Error handling:** Explicit (not exception-based), clear error flow  

### Weaknesses
❌ **Parser libraries:** Limited ecosystem compared to Python/Rust  
❌ **Team fit:** Nobody on team has recent Go experience  
❌ **Development speed:** Slower than Python/Node due to weak parsing libraries  
❌ **Error messages:** More manual work to create helpful diagnostics  

### Estimated Implementation

```
Parser combinator (hand-written):   300 lines
Semantic Analyzer:                  150 lines
Field Validators:                   150 lines
FSM Validator:                      100 lines
Error Reporter:                     100 lines
CLI/Main:                           100 lines
---
Total MVP:                         900 lines
```

**Time estimate:** 12-16 hours (hand-written parser)

### When to Choose Go
- Goal: Distribute as single binary to non-technical users
- Performance critical (unlikely for us)
- Team has Go expertise

**For our use case: Go is a middle ground, but slower to implement than Python.**

---

## 5. Lua (Dogfooding)

### Strengths
✅ **Dogfooding:** Same language as the game engine  
✅ **Understanding:** Intimate knowledge of Lua semantics  
✅ **Integration:** Can be called directly from Lua code  

### Weaknesses
❌ **No standard parsing libraries:** Lua has limited parser ecosystem  
❌ **Manual parsing:** Would need hand-written recursive descent (~400 lines)  
❌ **Performance:** Not faster than Python  
❌ **Integration:** Awkward for CI/CD (needs Lua runtime)  
❌ **Team fit:** Nobody *wants* to write a parser in Lua  

### Estimated Implementation

```
Recursive descent parser:       400 lines
Semantic Analyzer:              150 lines
Field Validators:               150 lines
FSM Validator:                  100 lines
Error Reporter:                 100 lines
CLI/Main:                        100 lines
---
Total MVP:                       1000 lines
```

**Time estimate:** 14-18 hours (hand-written parser, unfamiliar domain)

### When to Choose Lua
- Game engine needs to perform validation internally (won't happen — engine trusts validated data)
- Team insists on dogfooding

**For our use case: Lua is a poor choice. Don't do it.**

---

## 6. Comparative Table

| Language | Speed to MVP | Performance | Team Fit | Integration | Maintenance |
|----------|--------------|-------------|----------|-------------|------------|
| **Python + Lark** | 2-3 hours | ~1000 files/min | ✅✅ | ✅✅ | ✅✅ |
| Rust | 8-12 hours | ~100k files/min | ✅ | ✅ | ✅ |
| TypeScript/Node | 6-8 hours | ~5k files/min | ✅ | ⚠️ (web only) | ✅ |
| Go | 12-16 hours | ~50k files/min | ⚠️ | ✅ | ✅ |
| Lua | 14-18 hours | ~1000 files/min | ❌ | ❌ | ❌ |

**Performance note:** "1000 files/min" means processing 100 object/room files takes ~6 seconds. This is plenty for:
- Pre-commit hook (runs on changed files only, ~1-10 files)
- CI/CD (runs full suite, takes ~5 seconds)
- IDE integration (latency not critical)

---

## 7. Error Message Quality Comparison

### Python + Lark (Best)

```
Error in src/meta/objects/torch.lua line 12:
  Expected: template (string or identifier)
  Got: 123 (number)

  Error Context:
  10. id = "torch",
  11. template = {broken},   <-- Unexpected table here
  12.   guid = "...",

  Suggestion: template should be a string like "small-item"
```

### Rust (Good)

```
Error [E001]: Type mismatch in src/meta/objects/torch.lua:11
  Expected: string
  Got: number

  Value: 123
  Context: Field 'template' on line 11
```

### Go (OK)

```
Parse error: unexpected token '123' at line 11, column 12
Expected: STRING or IDENTIFIER
```

### TypeScript (Good)

```
Error: Invalid value for field 'template'
  File: src/meta/objects/torch.lua
  Line: 11, Column: 12
  Expected: string
  Got: number
```

---

## 8. Build Time and Dependency Analysis

### Python + Lark
- **Dependencies:** lark, pyyaml (for schema files, optional)
- **Build time:** ~10 seconds (pip install lark)
- **Distribution:** Copy script + require Python 3.8+
- **CI/CD:** Add `pip install lark` to workflow

### Rust
- **Dependencies:** nom, regex, serde (parser combinators + serialization)
- **Build time:** 1-2 minutes (Rust compilation)
- **Distribution:** Single binary (~5-10MB)
- **CI/CD:** Use `cargo build --release`

### TypeScript/Node
- **Dependencies:** typescript, babel, eslint, etc.
- **Build time:** ~30 seconds (tsc compile)
- **Distribution:** Node project (node_modules/ directory)
- **CI/CD:** Use `npm run build`

### Go
- **Dependencies:** None (stdlib only, preferably)
- **Build time:** 5-10 seconds (go build)
- **Distribution:** Single binary (~2-5MB)
- **CI/CD:** Use `go build -o meta-compiler`

---

## 9. Integration into Project

### Where the Tool Lives

**Option A: scripts/meta-compiler.py**
```
scripts/
├── meta-compiler.py          (300 lines: CLI + integration)
└── lib/
    └── meta_compiler/
        ├── __init__.py
        ├── parser.py          (50 lines: Lark grammar)
        ├── ast.py             (50 lines: AST nodes)
        ├── semantics.py       (150 lines: validation)
        ├── validators.py      (200 lines: field-specific rules)
        └── errors.py          (50 lines: error reporting)
```

### Integration Points

1. **Pre-commit hook** — `.git/hooks/pre-commit` calls `python scripts/meta-compiler.py --staged`
2. **GitHub Actions CI** — Runs on every PR: `python scripts/meta-compiler.py src/meta/`
3. **IDE (VS Code)** — Extension that runs validator on save (optional, future)
4. **Lisa's workflow** — `python scripts/meta-compiler.py src/meta/objects/[filename].lua`

### CI/CD Integration Example

```yaml
# .github/workflows/validate-meta.yml
name: Validate Meta Objects

on:
  push:
    paths:
      - "src/meta/**/*.lua"
      - "scripts/meta-compiler.py"
  pull_request:
    paths:
      - "src/meta/**/*.lua"

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - run: pip install lark
      - run: python scripts/meta-compiler.py src/meta/ --fail-on-error
```

---

## 10. Recommendation

### Primary: Python + Lark

**Reasons:**
1. Fastest MVP (2-3 hours)
2. Already using Python in scripts/
3. Lark is the de facto standard for DSL validation
4. Error messages can be excellent
5. Easy to maintain and extend
6. Perfect for a tool that runs in CI/CD

**Implementation Plan:**
1. **Hour 1-2:** Write Lark grammar (EBNF) for Lua subset
2. **Hour 2-3:** Implement semantic analyzer (required fields, types, cross-refs)
3. **Hour 3-4:** Add FSM-specific validation (states, transitions)
4. **Hour 4-5:** Build error reporter with line/column/suggestion
5. **Hour 5-6:** Create CLI and integrate with scripts/

### Secondary: Rust (If Performance Becomes Issue)

If/when we scale to:
- 1000+ object files
- Performance bottleneck in CI/CD
- Need for distributed deployment

At that point, port the Python implementation to Rust (structure already clear from Python version).

---

## References

- Lark Parser: https://lark-parser.readthedocs.io/
- nom (Rust parser combinators): https://docs.rs/nom/latest/nom/
- TypeScript Compiler API: https://github.com/Microsoft/TypeScript/wiki/Using-the-Compiler-API
- Go standard library: https://golang.org/pkg/
