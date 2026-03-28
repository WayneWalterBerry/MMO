# Mutation Graph Linter — CI & Build Pipeline Review

**Reviewer:** Gil (Web Engineer)  
**Date:** 2026-08-23  
**Plans Reviewed:**
- `plans/linter/mutation-graph-linter-design.md` (Phase 1-4)
- `plans/linter/mutation-graph-linter-implementation-phase1.md` (WAVE-0 through WAVE-2)

---

## CI GAPS: Missing Components

### 1. **No Lint Step in CI Workflow**
**Finding:** `squad-ci.yml` runs ONLY parser unit tests (`lua test/run-tests.lua`), no linting stage.

**Current CI Flow:**
- Test job runs on `ubuntu-latest`
- Uses Lua 5.4 only
- No Python environment
- No `meta-lint` pipeline

**Gap:** The mutation-lint plan calls for:
- `lua scripts/mutation-edge-check.lua` (edge validation)
- `python scripts/meta-lint/lint.py` (full 200+ rule validation)
- These MUST run in CI to prevent broken edges from merging

**Severity:** 🔴 **CRITICAL** — Without CI integration, mutation edges won't be validated on PR, missing design goal.

### 2. **No Python Setup in CI**
**Finding:** `squad-ci.yml` does NOT install Python or Python dependencies.

**Current setup:** Only Lua 5.4
**Required:** 
- Python 3.8+ (for `meta-lint/lint.py`)
- Python dependencies from `scripts/requirements.txt` (openai, sentence-transformers, onnxruntime, transformers, torch, numpy)

**Issue:** Installing `torch` alone takes 2+ minutes; `onnxruntime` adds another 1+ minute. Full dependency install could add **5-7 minutes** to every CI run.

**Options:**
- A) Add lightweight Python 3.8 + subset of deps (numpy, transformers lite)
- B) Cache pip dependencies (GitHub Actions `setup-python` has built-in caching)
- C) Make `meta-lint` CI step optional, gate it separately (not blocking tests)
- D) Skip Python in CI, only run Lua edge check (catches 50% of issues)

### 3. **No Mutation-Lint in Pre-Deploy Gate**
**Finding:** `test/run-before-deploy.ps1` runs only `lua test/run-tests.lua` then `web/build-engine.ps1`.

**Current gate:**
```powershell
# Step 1: Run unit tests
lua $testRunner

# Step 2: Build engine
& powershell -File $buildScript
```

**Missing:** Mutation edge validation should fire BEFORE the build.

**Proposed flow:**
```powershell
# Step 1: Run unit tests
lua test/run-tests.lua

# Step 2: Validate mutation edges (NEW)
lua scripts/mutation-edge-check.lua
if ($LASTEXITCODE -ne 0) { exit 1 }

# Step 3: Build engine (current Step 2)
& powershell -File web/build-engine.ps1
```

**Why:** Pre-deploy gate prevents broken edges from reaching production.

---

## SCRIPT ISSUES: Wrapper Script Compliance

### 1. **Line Ending Management**
**Finding:** Plan creates `scripts/mutation-lint.ps1` and `scripts/mutation-lint.sh`.

**Current `.gitattributes`:**
```
.squad/decisions.md merge=union
.squad/agents/*/history.md merge=union
.squad/log/** merge=union
.squad/orchestration-log/** merge=union
```

**Issue:** No line-ending rules for shell scripts.

**Problem:**
- `.ps1` files should have **CRLF** (Windows native)
- `.sh` files should have **LF** (Unix native, required by shebang)
- If committed with wrong endings, scripts fail on target platform

**Required `.gitattributes` additions:**
```
# Shell scripts — UNIX line endings (required for shebang)
scripts/mutation-lint.sh text eol=lf

# PowerShell scripts — Windows line endings (standard on Windows)
scripts/mutation-lint.ps1 text eol=crlf
```

**Severity:** 🟡 **MEDIUM** — Without this, cross-platform scripts break silently.

### 2. **Script Consistency with Existing Patterns**
**Finding:** Project has existing wrapper patterns to check against.

**Existing wrappers/scripts:**
- `test/run-before-deploy.ps1` — PowerShell gate script
- `test/run-tests.lua` — Test runner (Lua, cross-platform)
- `web/build-engine.ps1` — Build wrapper (PS5+)

**Pattern Analysis:**
- ✅ PowerShell scripts use `.ps1` extension
- ✅ Lua scripts use `.lua` extension
- ✅ Error handling: `if ($LASTEXITCODE -ne 0) { exit 1 }` (PS) or `exit 1` (Lua)
- ✅ Logging: `Write-Host` for PS, `print()` for Lua
- ⚠️ Shell scripts: **No existing `.sh` files in project**

**Issue:** Plan introduces Unix shell wrapper (`.sh`) for first time. This is CORRECT (xargs-based parallel exec), but adds new platform dependency.

**Compliance check for `scripts/mutation-lint.ps1`:**
```powershell
# Per test/run-before-deploy.ps1 pattern:
param([switch]$EdgesOnly, [string]$Format = "text", [int]$ThrottleLimit = 4)
$ErrorActionPreference = "Stop"

# Use Write-Host for logging (consistent)
# Use $LASTEXITCODE checks (consistent)
# Use ForEach-Object -Parallel for threading (PS7+)
```

**Compliance check for `scripts/mutation-lint.sh`:**
```bash
#!/bin/bash
# Use xargs -P for parallel exec (POSIX standard)
# Error propagation: set -e or || exit 1
# Use bash, not sh (bash is POSIX superset, available on CI)
```

**Severity:** 🟢 **LOW** — Scripts follow existing patterns; shell script is new but correct.

### 3. **PowerShell 7 Requirement (`-Parallel`)**
**Finding:** Wrapper calls `ForEach-Object -Parallel` (PS7 feature).

**Issue:** `-Parallel` is **PowerShell 7+ only**. Older PowerShell 5.x (Windows default) does NOT have this feature.

**Where it matters:**
- ✅ GitHub Actions ubuntu-latest: Has `pwsh` (PS7)
- ✅ Modern Windows 11: Can install `pwsh` package
- ⚠️ Legacy Windows Server 2019: May still have only PS5
- ⚠️ Local developer machines: Mix of PS5/PS7

**Solution options:**
- A) Require PowerShell 7+ (add check to wrapper)
- B) Use sequential fallback for older PowerShell
- C) Document PS7 requirement in README
- D) Use shell version for parallel, PS version for sequential

**Recommended:** Add PS version check:
```powershell
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "⚠ Warning: PowerShell 7+ required for parallel execution"
    Write-Host "  Sequential mode (slower)"
    # Fallback to sequential ForEach
}
```

**Severity:** 🟡 **MEDIUM** — Parallel feature may not work on all Windows machines.

---

## PRE-DEPLOY CONCERNS: Gate Placement

### 1. **Should mutation-lint be in the pre-deploy gate?**

**YES — Strongly Recommended**

**Reasoning:**
- Pre-deploy gate is the final validation before pushing to production
- Broken mutation edges are BUGS (missing target files are data integrity issues)
- Edge check (`lua scripts/mutation-edge-check.lua`) is fast (~1-2 sec)
- No Python dependencies needed for edge check alone
- Catches errors at deploy time, not at player runtime

**Proposed addition to `test/run-before-deploy.ps1`:**
```powershell
# Step 2a: Validate mutation edges (before build)
Write-Host "Step 2a: Validating mutation edges..."
lua scripts/mutation-edge-check.lua
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "DEPLOY BLOCKED: Broken mutation edges found. Fix before deploying." -ForegroundColor Red
    exit 1
}
```

**Impact:** +1-2 seconds per pre-deploy run (negligible).

### 2. **Should full mutation-lint (edge check + Python linting) be in pre-deploy?**

**NO — Not in pre-deploy gate**

**Reasoning:**
- Python dependencies add 5-7 minutes to every deploy
- Full linting catches STYLE issues (naming, field order), not DATA integrity issues
- Pre-deploy should be FAST (rules: <10 sec)
- Linting should run in CI (catch issues on PR), not on deploy

**Better flow:**
```
PR submitted
  ↓
CI runs: unit tests + edge check + full lint (slow, parallel)
  ↓
[CI passes]
  ↓
Developer runs: test/run-before-deploy.ps1 (fast, edge-check only)
  ↓
[Local check passes]
  ↓
Deploy
```

**Severity:** 🟢 **GOOD PRACTICE** — Separates concerns (data integrity vs. style).

### 3. **Should mutation-lint run on every PR?**

**YES — But needs gating**

**Current behavior:** CI runs only unit tests. Mutation edges not validated.

**Proposed:** Add lint step to CI, but make it non-blocking on first implementation.

**Phase 1 (WAVE-0):** Edge check only, blocking:
```yaml
- name: Check mutation edges
  run: lua scripts/mutation-edge-check.lua
```

**Phase 2 (after Python setup):** Full lint, non-blocking initially:
```yaml
- name: Full mutation linting
  run: |
    lua scripts/mutation-edge-check.lua --targets-only | \
    xargs -P 4 -I {} python scripts/meta-lint/lint.py {}
  continue-on-error: true  # Non-blocking on first run
```

**Severity:** 🟡 **MEDIUM** — Needs decision on when to enforce.

---

## CRITICAL PATH DEPENDENCIES

### Runner OS Compatibility

| Feature | Windows (PS7) | Linux (bash) | macOS | CI (ubuntu-latest) |
|---------|------|------|-------|------------|
| `lua` | ✅ (installed) | ✅ (apt) | ✅ (brew) | ✅ (apt) |
| `python` | ✅ (native) | ✅ (native) | ✅ (native) | ⚠️ NOT IN CURRENT CI |
| `ForEach-Object -Parallel` | ✅ (PS7+) | ✗ (PS-only) | ✗ (PS-only) | ✅ (pwsh available) |
| `xargs -P` | ✗ (PS-only) | ✅ (POSIX) | ✅ (BSD) | ✅ (POSIX) |

**Gap:** CI has no Python. Mutation-lint wrapper assumes Python is available.

---

## SUMMARY OF RECOMMENDATIONS

### Immediate (WAVE-0)

1. **✅ Add edge-check to pre-deploy gate** (fast, no deps)
   - File: `test/run-before-deploy.ps1`
   - Cost: +1-2 sec per deploy
   - Blocks: Broken edges

2. **⚠️ Add `.gitattributes` for shell scripts**
   - File: `.gitattributes`
   - Add: `scripts/mutation-lint.sh text eol=lf`
   - Add: `scripts/mutation-lint.ps1 text eol=crlf`

3. **⚠️ Add Python version check to `mutation-lint.ps1`**
   - Detect PS version < 7, fallback to sequential
   - Add warning comment to docs

### Phase 2 (After WAVE-1)

4. **🔴 Add CI lint step with Python**
   - Requires: `setup-python@v4` with caching
   - Action: `python -m pip install -r scripts/requirements.txt`
   - Run: Edge check (blocking) + full lint (report-only, initially)

5. **🔴 Add .github/workflows/mutation-lint.yml** (optional)
   - Separate workflow for detailed lint reports
   - Runs on schedule (e.g., nightly) OR on demand
   - Non-blocking on primary CI

---

## ACTION ITEMS FOR GIL

- [ ] Review squad-ci.yml with Bart (architecture/testing implications)
- [ ] Recommend Python caching strategy (setup-python vs. actions/cache)
- [ ] Decide: Full lint in CI (slow) OR edge-check only (fast) + lint on schedule?
- [ ] Write or review `.gitattributes` update
- [ ] Create `scripts/mutation-lint.sh` with bash error handling
- [ ] Create `scripts/mutation-lint.ps1` with PS7 fallback

---

## FINAL ASSESSMENT

**Current State:** CI gap is significant. Plan is well-designed but assumes CI environment has Python + parallel tools.

**Risk Level:** 🟡 **MEDIUM** — Edge check can run without CI changes, but full validation (plan's goal) blocked by Python setup.

**Blocking:**
- Mutation edges will NOT be validated in CI until Python is available
- Pre-deploy gate won't catch broken edges until edge-check is added
- Cross-platform wrapper scripts need `.gitattributes` to work correctly

**Not Blocking:**
- Design is sound; implementation is correct
- Scripts follow existing patterns
- Lua edge extractor is self-contained (no deps)

