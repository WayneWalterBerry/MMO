---
name: "running-the-linter"
description: "How, when, and why to run the meta-lint and mutation-edge-check pipeline"
domain: "quality, linting, CI"
confidence: "high"
source: "earned — mutation-graph linter WAVE-0 through WAVE-2 (2026-03-28), meta-lint V1+V2 validation passes, 306 rules across 20 categories"
---

## Context

The project has two complementary lint tools that compose into a full validation pipeline. Every agent who creates or modifies `.lua` files under `src/meta/` should run the linter before committing. This skill defines how.

Applies when:
- Creating or modifying any `.lua` file in `src/meta/` (objects, creatures, rooms, injuries, materials, levels, templates)
- Adding new mutation targets (becomes, spawns, crafting)
- Before opening PRs that touch meta files
- At gate checkpoints during wave-based execution
- During CI (automated)

## Tools

### 1. Meta-Lint (Python) — `scripts/meta-lint/lint.py`

**What:** 306 rules across 20 categories validating object structure, naming, GUIDs, sensory fields, FSM, transitions, mutations, materials, rooms, cross-file references, creatures, injuries, and more.

**Run on a single file:**
```bash
python scripts/meta-lint/lint.py src/meta/objects/candle.lua
```

**Run on all files:**
```bash
python scripts/meta-lint/lint.py src/meta/
```

**JSON output (for CI/scripting):**
```bash
python scripts/meta-lint/lint.py src/meta/ --format json
```

**With environment profile:**
```bash
python scripts/meta-lint/lint.py src/meta/ --env dev    # development rules
python scripts/meta-lint/lint.py src/meta/ --env prod   # production rules (stricter)
```

**Skip cache (full re-scan):**
```bash
python scripts/meta-lint/lint.py src/meta/ --no-cache
```

**Requires:** Python 3.8+

### 2. Mutation Edge Check (Lua) — `scripts/mutation-edge-check.lua`

**What:** Scans all `.lua` files under `src/meta/`, extracts mutation edges from 12 mechanisms, verifies target files exist.

**Human-readable report:**
```bash
lua scripts/mutation-edge-check.lua
```

**Target paths only (for piping to lint.py):**
```bash
lua scripts/mutation-edge-check.lua --targets
```

**JSON output:**
```bash
lua scripts/mutation-edge-check.lua --json
```

**Requires:** Lua 5.4 (or 5.1 with setfenv fallback). Zero dependencies.

**Exit codes:** 0 = no broken edges, 1 = broken edges found.

### 3. Full Pipeline — `scripts/mutation-lint.ps1` / `scripts/mutation-lint.sh`

**What:** Runs both tools in sequence: edge check first, then Python lint on all valid mutation targets.

**PowerShell (Windows):**
```powershell
.\scripts\mutation-lint.ps1                    # Full pipeline
.\scripts\mutation-lint.ps1 -EdgesOnly         # Skip Python lint, just check edges
.\scripts\mutation-lint.ps1 -Env prod          # Use production rules
.\scripts\mutation-lint.ps1 -ThrottleLimit 8   # More parallel workers (PS7)
```

**Shell (Unix):**
```bash
./scripts/mutation-lint.sh        # Full pipeline (4 workers default)
./scripts/mutation-lint.sh 8      # 8 parallel workers
```

**Parallel execution:** Per D-MUTATION-LINT-PARALLEL, lint runs on multiple files concurrently (PS7 `-Parallel` / Unix `xargs -P`) but output is collected per-file and displayed sequentially with `--- {file} ---` headers to prevent interleaving.

## Patterns

### When to Run What

| Situation | Tool | Why |
|-----------|------|-----|
| Edited a single object file | `python scripts/meta-lint/lint.py {file}` | Quick single-file validation |
| Created a new mutation target | `lua scripts/mutation-edge-check.lua` | Verify the edge resolves |
| Before committing meta changes | `lua scripts/mutation-edge-check.lua && python scripts/meta-lint/lint.py src/meta/` | Catch issues pre-commit |
| At a gate checkpoint | `.\scripts\mutation-lint.ps1` | Full pipeline validation |
| In CI (automated) | Edge check step in `squad-ci.yml` | Catch regressions on push |
| Pre-deploy | Edge check in `run-before-deploy.ps1` | Fast safety net |

### Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| ERROR | Rule violation that will cause runtime failure | Must fix before merge |
| WARNING | Potential issue, may cause unexpected behavior | Should fix, can defer with justification |
| INFO | Style/convention suggestion | Optional fix |

### Squad Routing

Every lint violation includes an `owner` field indicating which squad member should fix it. Default routing:

| Rule prefix | Owner |
|-------------|-------|
| OBJ-*, SEN-*, MAT-*, FSM-*, MUT-* | Flanders (objects) |
| EXIT-*, ROOM-* | Moe (rooms) |
| CREATURE-*, LOOT-* | Flanders (creatures) |
| GUID-*, XF-*, XR-* | Bart (cross-cutting) |
| INV-* | Bart (inventory engine) |
| LV-* | Bart (level structure) |

### D-LINTER-AUDIT-BASELINE Rule

**All team members:** New meta file additions should pass `python scripts/meta-lint/lint.py` with zero new findings before PR. This is an active decision — treat it as a gate.

## Anti-Patterns

- **Don't skip the linter because "it's just a small change"** — small changes break edges
- **Don't fix lint violations without understanding the rule** — some WARNINGs are intentional (check orphan_allowlist)
- **Don't modify `scripts/meta-lint/lint.py` without coordinating with Wiggum** — single-file bottleneck, per D-LINTER-IMPL-WAVES
- **Don't ignore exit code 1 from mutation-edge-check** — broken edges mean runtime crashes when players trigger mutations
- **Don't run the full pipeline in CI without caching** — use `--no-cache` only for validation passes, not regular CI

## Configuration

- `.meta-check.json` — Project-level lint config (orphan allowlist, rule overrides)
- `.meta-lint-cache.json` — Incremental cache (gitignored), keyed by SHA-256 hash
- `scripts/requirements.txt` — Python dependencies for meta-lint
