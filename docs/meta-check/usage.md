# Meta-Check: Usage

**Date:** 2026-03-24  
**Version:** 1.0  
**Author:** Brockman (Documentation)  
**Audience:** Developers, CI/CD operators, QA (Lisa)  

---

## Quick Start

```bash
# Check a single object file
python scripts/meta-check/check.py src/meta/objects/candle.lua

# Scan all objects in a directory
python scripts/meta-check/check.py src/meta/objects/

# Full meta validation (all objects + rooms + levels)
python scripts/meta-check/check.py src/meta/

# With JSON output (for CI parsing)
python scripts/meta-check/check.py --format=json src/meta/objects/

# Suppress info/warning messages (errors only)
python scripts/meta-check/check.py --severity=error src/meta/

# Run with verbose output (debug mode)
python scripts/meta-check/check.py --verbose src/meta/
```

---

## Command-Line Interface

### Syntax
```bash
python scripts/meta-check/check.py [OPTIONS] [PATH]
```

### Arguments

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `PATH` | file or directory | `src/meta/` | File or directory to validate. If directory, recursively scans `.lua` files. |

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--format` | `text` \| `json` \| `tap` | `text` | Output format. `json` for CI parsing, `tap` for pre-commit hooks. |
| `--severity` | `all` \| `warning` \| `error` | `all` | Minimum severity to report. `error` suppresses warnings. |
| `--output` | filepath | stdout | Write output to file instead of stdout. |
| `--fix` | flag | off | Auto-fix simple issues (see [Auto-Fix](#auto-fix)). |
| `--verbose` | flag | off | Print debug info (tokenization, AST, phase timings). |
| `--config` | filepath | `.meta-check.yaml` | Load validation rules from config file. |
| `--exclude` | glob | (none) | Exclude files matching glob (e.g., `*.bak`). |

### Exit Codes

| Code | Meaning |
|------|---------|
| **0** | ✅ All checks passed |
| **1** | ❌ Errors found (must fix before merge) |
| **2** | ⚠️ Warnings found (author should review, non-blocking) |
| **64** | 💥 Invalid arguments or configuration |
| **65** | 💥 File I/O error (permission denied, file not found) |

---

## Output Formats

### Text Format (Human-Readable)

**Default output:**
```
meta-check v1.0 — Validating src/meta/

src/meta/objects/candle.lua
  [ERROR]   S-02 (line 5)  Missing guid field
            Add: guid = "{...}" (Windows GUID format)
  [WARNING] S-05 (line 7)  Id should be lowercase-with-dashes
            Change: id = "Candle" to id = "candle"
  [ERROR]   SF-REQ-ON_FEEL (line 20)  on_feel is required
            Add: on_feel = "..." (required sensory field)

src/meta/objects/torch.lua
  [INFO]    S-12 (line 10)  Explicit location = nil recommended
            Consider: location = nil (for clarity)

────────────────────────────────────────────────────────────
Results: 2 errors, 1 warning, 1 info (3/5 objects passed)
Exit code: 1 (errors found)
```

**With colors (terminal):**
- 🔴 **[ERROR]** in red
- 🟡 **[WARNING]** in yellow
- 🟢 **[INFO]** in green
- Line numbers in blue hyperlinks (some terminals support click-to-open)

### JSON Format (CI Integration)

```json
{
  "meta_check_version": "1.0",
  "timestamp": "2026-03-24T14:30:00Z",
  "files_scanned": 83,
  "violations": [
    {
      "file": "src/meta/objects/candle.lua",
      "line": 5,
      "column": 1,
      "severity": "error",
      "rule_id": "S-02",
      "message": "Missing guid field",
      "suggestion": "Add: guid = \"{...}\" (Windows GUID format)",
      "context": "return {"
    },
    {
      "file": "src/meta/objects/candle.lua",
      "line": 7,
      "column": 3,
      "severity": "warning",
      "rule_id": "S-05",
      "message": "Id should be lowercase-with-dashes",
      "suggestion": "Change: id = \"Candle\" to id = \"candle\"",
      "context": "id = \"Candle\","
    }
  ],
  "summary": {
    "total_files": 83,
    "passed": 81,
    "failed": 2,
    "errors": 2,
    "warnings": 1,
    "infos": 1
  },
  "exit_code": 1
}
```

### TAP Format (Test Anything Protocol)

```
1..83
ok 1 - src/meta/objects/candle.lua
not ok 2 - src/meta/objects/torch.lua
  ---
  message: 'ERROR S-02: Missing guid field'
  severity: error
  line: 5
  ...
ok 3 - src/meta/objects/sword.lua
...
# Tests: 83, Passed: 81, Failed: 2, Errors: 2, Warnings: 1
```

---

## Integration Examples

### GitHub Actions Workflow

```yaml
name: meta-check

on: [pull_request, push]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      
      - name: Install Lark
        run: pip install lark
      
      - name: Run meta-check
        run: |
          python scripts/meta-check/check.py --format=json \
            --output=meta-check-report.json src/meta/
      
      - name: Check results
        run: |
          if [ $? -eq 1 ]; then
            echo "❌ Meta-check failed (errors found)"
            cat meta-check-report.json
            exit 1
          fi
```

### Pre-Commit Hook

**File: `.git/hooks/pre-commit`**

```bash
#!/bin/bash

# Run meta-check on staged Lua files
STAGED_LUA=$(git diff --cached --name-only --diff-filter=ACM | grep '\.lua$')

if [ -z "$STAGED_LUA" ]; then
  exit 0
fi

python scripts/meta-check/check.py --format=tap $STAGED_LUA
EXIT_CODE=$?

if [ $EXIT_CODE -eq 1 ]; then
  echo "❌ meta-check found errors. Fix before commit."
  exit 1
elif [ $EXIT_CODE -eq 2 ]; then
  echo "⚠️ meta-check found warnings. Review before commit."
  # Non-blocking — allow commit with --no-verify
fi

exit 0
```

### Manual CI Check (GitHub Actions)

```bash
# In a GitHub Actions workflow
python scripts/meta-check/check.py --severity=error --format=json src/meta/ \
  | jq '.summary | select(.errors > 0) | error("Found \(.errors) errors")'
```

---

## Practical Workflows

### Workflow 1: Developer Creates New Object

```bash
# 1. Create object file
cat > src/meta/objects/my-item.lua << 'EOF'
return {
    guid = "12345678-1234-1234-1234-123456789012",
    template = "small-item",
    id = "my-item",
    name = "my item",
    keywords = {"item"},
    description = "An item.",
    on_feel = "Smooth.",
    size = 1,
    weight = 0.5,
    material = "wood"
}
EOF

# 2. Run meta-check
python scripts/meta-check/check.py src/meta/objects/my-item.lua

# Output:
# src/meta/objects/my-item.lua
#   [INFO] S-12 (line 1) Explicit location = nil recommended
#   [INFO] S-13 (line 1) Explicit mutations = {} recommended

# 3. Fix recommendations
# ... developer adds location = nil, mutations = {}

# 4. Re-run
python scripts/meta-check/check.py src/meta/objects/my-item.lua
# Output: OK (exit code 0)

# 5. Commit
git add src/meta/objects/my-item.lua
git commit -m "Add my-item object"
```

### Workflow 2: Lisa QA Testing

```bash
# 1. Scan entire meta directory before manual testing
python scripts/meta-check/check.py src/meta/

# If errors → stop, report to developers
# If warnings → proceed with caution
# If OK → proceed to gameplay testing

# 2. During playtesting, if object is buggy:
# a. Check if meta-check should have caught it
# b. If yes → add rule to meta-check
# c. If no → document as semantic rule (gameplay design)

# Example: Object has state but transitions are impossible
python scripts/meta-check/check.py src/meta/objects/broken-fsm.lua
# Output: [ERROR] FSM-STATE-UNREACHABLE (line 25)
#         State 'open' is unreachable from initial state 'closed'
```

### Workflow 3: Pre-Deploy Gate

```bash
#!/bin/bash
# script: test/run-before-deploy.ps1 (PowerShell equivalent)

set -e

echo "Step 1: Running meta-check..."
python scripts/meta-check/check.py --severity=error src/meta/
if [ $? -eq 1 ]; then
  echo "❌ Deployment blocked: meta-check errors found"
  exit 1
fi

echo "Step 2: Running game tests..."
lua test/run-tests.lua
if [ $? -ne 0 ]; then
  echo "❌ Deployment blocked: game tests failed"
  exit 1
fi

echo "Step 3: Building web bundle..."
npm run build
if [ $? -ne 0 ]; then
  echo "❌ Deployment blocked: web build failed"
  exit 1
fi

echo "✅ All checks passed. Ready to deploy."
```

---

## Auto-Fix Mode

**Flag: `--fix`**

Meta-check can auto-fix common, **low-risk issues**:

```bash
python scripts/meta-check/check.py --fix src/meta/objects/
```

**Auto-fixable issues:**

| Issue | Fix |
|-------|-----|
| Missing `location = nil` | Add field with nil value |
| Missing `mutations = {}` | Add empty mutations table |
| Non-kebab-case `id` | Sanitize to lowercase-with-dashes (requires review) |
| Trailing commas in arrays | Remove (Lua-compliant) |
| Inconsistent GUID format | Normalize to `{xxxx-xxxx-...}` format |

**NOT auto-fixable** (require human review):

- Missing required fields (developer chooses values)
- Invalid references (requires research)
- Type mismatches (developer chooses correction)
- FSM structure issues (gameplay-critical)

**Workflow with --fix:**

```bash
# 1. Run with --fix to auto-correct simple issues
python scripts/meta-check/check.py --fix src/meta/objects/

# 2. Review changes
git diff src/meta/objects/

# 3. If changes look good, commit
git add src/meta/objects/
git commit -m "Auto-fix: meta-check style issues"

# 4. Re-run without --fix to verify all violations are addressed
python scripts/meta-check/check.py src/meta/objects/
```

---

## Configuration File

**File: `.meta-check.yaml` (optional)**

```yaml
# Meta-Check Configuration

version: 1.0

# Which files to validate
paths:
  - src/meta/objects/
  - src/meta/rooms/
  - src/meta/levels/

# Exclude patterns
exclude:
  - "*.bak"
  - "*-draft.lua"
  - "temp/*"

# Rule enforcement
rules:
  # Override default severity for specific rules
  S-05:  # id kebab-case
    severity: info  # downgrade from warning
  
  FU-04:  # furniture portable check
    severity: error  # upgrade from warning

# Template-specific configurations
templates:
  small-item:
    required_keywords_min: 2
    required_senses: ["on_feel", "on_smell"]
  
  furniture:
    material_classes_preferred:
      - "wood"
      - "stone"
      - "oak"
      - "iron"

# Cross-file validation
cross_file:
  material_registry: src/engine/materials/init.lua
  keyword_collision_threshold: 3  # warn if keyword appears on 3+ objects

# Reporting
reporting:
  max_errors_display: 100
  show_context_lines: 2  # lines of code around error
  colorize: auto  # auto, on, off
```

---

## Troubleshooting

### "lark not installed"

```bash
pip install lark
```

### "File not found or permission denied"

```bash
# Check file exists
ls src/meta/objects/candle.lua

# Check permissions
chmod +r src/meta/objects/candle.lua
```

### "Parse error: unexpected token"

This means the Lua source is syntactically invalid. Check:
- Mismatched braces: `{ { }` (missing closing)
- Unclosed strings: `name = "candle` (missing quote)
- Invalid characters: non-UTF-8 encoding

Run with `--verbose` to see preprocessed token stream.

### "Cross-file check failed: type_id mismatch"

The `type_id` in a room file doesn't match any object's `guid`. Check:
- Typo in `type_id` (copy-paste error)
- Object file doesn't exist
- Object file has wrong `guid`

Run: `grep -r "type_id_value" src/meta/` to find all references.

---

## Performance

For a typical repository (83 objects, 7 rooms):

| Command | Time | Memory |
|---------|------|--------|
| Single file | ~50 ms | 10 MB |
| All objects | ~150 ms | 25 MB |
| Full meta | ~200 ms | 30 MB |

Pre-commit hook overhead: ~200 ms (acceptable for staged files).

---

## References

- **Rules Catalog:** `docs/meta-check/rules.md` (144 rules across 15 categories)
- **Schemas:** `docs/meta-check/schemas.md` (template-specific field contracts)
- **Architecture:** `docs/meta-check/architecture.md` (6-phase pipeline)
- **Acceptance Criteria:** `docs/meta-check/acceptance-criteria.md` (Lisa's specification)

