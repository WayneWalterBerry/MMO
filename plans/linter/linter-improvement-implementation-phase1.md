# Linter Improvement — Implementation Plan (Phase 1)

**Author:** Bart (Architect)  
**Date:** 2026-07-29  
**Status:** PLAN ONLY — Not yet executed  
**Requested By:** Wayne "Effe" Berry  
**Governs:** Meta-lint improvement across all 3 phases (Quick Wins → Portal/Creature Validation → Architecture Evolution)  
**Decision:** D-LINTER-IMPL-WAVES  
**Source Plan:** `plans/linter-improvement-plan.md`

---

## Quick Reference

| Wave | Name | Parallel Tracks | Gate | Key Deliverable |
|------|------|-----------------|------|-----------------|
| **WAVE-0** | Pre-Flight (Test Infrastructure) | 2 tracks | — | pytest scaffold, test fixtures, baseline snapshot |
| **WAVE-1** | Bug Fixes Batch A (#190, #196) | 3 tracks | GATE-1 | XF-03 smart filtering, XR-05 template suppression, regression tests |
| **WAVE-2** | Bug Fix #195 + Fix-Safety Audit | 2 tracks | GATE-2 | MD-19 removal, offline fix-safety audit doc |
| **WAVE-3** | Fix Classification + CLI Integration | 2 tracks | GATE-3 | rule_registry.py fix_safety fields, `--fix`/`--unsafe-fixes` CLI flags |
| **WAVE-4** | EXIT-* Verification + CREATURE-* Implementation | 3 tracks | GATE-4 | EXIT-* rules verified, 20 CREATURE-* rules implemented, test suites |
| **WAVE-5** | Environment Variants + Routing + Caching | 3 tracks | GATE-5 | Per-level config profiles, squad routing, incremental caching |

**Total new files:** ~12 (test files + config)  
**Total modified files:** ~5 (`lint.py`, `rule_registry.py`, `config.py`, `squad_routing.py`, `cache.py`)  
**Estimated scope:** 6 waves (WAVE-0 through WAVE-5), 5 gates, ~600 lines new code + ~800 lines tests + config updates

---

## Section 1: Executive Summary

Meta-lint is the quality gate for all `src/meta/` content. It currently validates 306 rules across 20 categories in a Python + Lark pipeline (~2,538 lines in `lint.py` plus supporting modules: `config.py`, `rule_registry.py`, `cache.py`, `squad_routing.py`). It works — 0 false positives on 130+ files, ~180ms per run. But research and open issues expose gaps: keyword collision noise (#190), unhelpful info-level rules (#195, #196), no creature validation, incomplete fix-safety classification, and no per-environment configuration.

This plan implements all 3 phases from `plans/linter-improvement-plan.md` in 6 waves with 5 gates:

- **Phase 1 (Quick Wins)** → WAVE-1 through WAVE-3: Fix 3 bugs, audit fix safety, add `--fix`/`--unsafe-fixes` CLI
- **Phase 2 (Portal + Creature Validation)** → WAVE-4: Verify 7 EXIT-* rules (already implemented), implement 20 CREATURE-* rules
- **Phase 3 (Architecture Evolution)** → WAVE-5: Environment variant config, squad routing integration, incremental caching

**Why 6 waves instead of 3 phases?** The single-file bottleneck on `lint.py` (~2,538 lines) prevents parallel edits. Bug fixes #190, #195, and #196 have different owners (Smithers, Flanders) but both require `lint.py` changes, so they serialize across waves. The multi-module structure (`config.py`, `rule_registry.py`, `cache.py`, `squad_routing.py`) enables parallel work on non-lint.py files within each wave.

**Key architecture decisions:**
1. **D-LINTER-EXIT-VERIFIED**: EXIT-01 through EXIT-07 are already implemented in `rule_registry.py` — WAVE-4 verifies correctness via test fixtures, not greenfield implementation
2. **D-LINTER-CREATURE-GREENFIELD**: 0 of 20 CREATURE-* rules exist — WAVE-4 implements all (~150 LOC in lint.py + 20 entries in registry)
3. **D-LINTER-TEST-INFRA**: Use pytest for linter tests (linter is Python, not Lua) — Nelson builds infrastructure in WAVE-0
4. **D-LINTER-FIX-AUDIT**: Two-phase approach — offline audit docs in WAVE-2, integration in WAVE-3 — avoids `rule_registry.py` conflicts

**Walk-away capability:** Each wave is a batch of parallel work. Coordinator spawns agents, collects results, runs gate tests. Pass → next wave. Fail → file issue, assign fix, re-gate.

---

## Section 2: Dependency Graph

```
WAVE-0: Pre-Flight (Test Infrastructure)
├── [Nelson]   test/linter/ pytest scaffold ──────────┐
│              conftest.py, fixtures, helpers          │ (parallel, no file overlap)
└── [Nelson]   Baseline snapshot (current pass/fail)──┘
        │
        ▼  ── (no gate — infrastructure only, verified by pytest --collect-only) ──
        │
WAVE-1: Bug Fixes Batch A (#190, #196)
├── [Smithers] lint.py: XF-03 smart keyword filter ───┐
│              lint.py: XR-05 template suppression     │
├── [Nelson]   test/linter/test_xf03.py ──────────────┤ (parallel, no file overlap)
│              test/linter/test_xr05.py                │
└── [Bart]     config.py: XF-03 allowed_shared list ──┘
        │
        ▼  ── GATE-1 (#190 XF-03 false positives eliminated, #196 XR-05 suppressed on templates) ──
        │
WAVE-2: Bug Fix #195 + Fix-Safety Audit
├── [Flanders] lint.py: Remove MD-19 rule ────────────┐
│              (Smithers from WAVE-1 is done;          │
│               Flanders takes lint.py in this wave)   │ (parallel, no file overlap)
└── [Bart]     Fix-safety audit document ─────────────┘
               (offline — no code changes)
        │
        ▼  ── GATE-2 (#195 MD-19 removed, audit doc complete with all 306 rules classified) ──
        │
WAVE-3: Fix Classification + CLI Integration
├── [Smithers] rule_registry.py: Add fix_safety ──────┐
│              to all 306 rules from audit doc         │
│              lint.py: --fix / --unsafe-fixes flags   │ (parallel, no file overlap)
└── [Nelson]   test/linter/test_fix_safety.py ────────┘
               test/linter/test_cli_flags.py
        │
        ▼  ── GATE-3 (Phase 1 complete — all 306 rules classified, CLI --fix works) ──
        │
        │  ═══ PHASE 1 (QUICK WINS) SHIPS HERE ═══
        │
WAVE-4: EXIT-* Verification + CREATURE-* Implementation
├── [Sideshow Bob] test/linter/fixtures/portals/ ─────┐
│                  (EXIT-* test fixture .lua files)    │
├── [Bart]         lint.py: _validate_creature() ──────┤ (parallel, no file overlap)
│                  20 CREATURE-* rules                 │
│                  rule_registry.py: CREATURE entries   │
├── [Nelson]       test/linter/test_exit_rules.py ─────┤
│                  test/linter/test_creature_rules.py   │
└── [Flanders]     test/linter/fixtures/creatures/ ────┘
                   (CREATURE-* test fixture .lua files)
        │
        ▼  ── GATE-4 (EXIT-* verified, CREATURE-* implemented, all tests pass) ──
        │
        │  ═══ PHASE 2 (PORTAL + CREATURE VALIDATION) SHIPS HERE ═══
        │
WAVE-5: Environment Variants + Routing + Caching
├── [Bart]         config.py: Environment profiles ───┐
│                  lint.py: --env flag                 │
├── [Bart]         squad_routing.py: Enhanced routing ─┤ (parallel within Bart —
│                  (routing already exists, expand it) │  different files)
├── [Bart]         cache.py: Incremental analysis ─────┤
└── [Nelson]       test/linter/test_environments.py ───┘
                   test/linter/test_routing.py
                   test/linter/test_caching.py
        │
        ▼  ── GATE-5 (Phase 3 complete — env profiles, routing JSON, cache invalidation) ──
        │
        │  ═══ PHASE 3 (ARCHITECTURE EVOLUTION) SHIPS HERE ═══
```

**Key constraint:** Only ONE agent edits `lint.py` per wave. This serialization is the primary driver for the 6-wave structure.

---

## Section 3: Implementation Waves

### WAVE-0: Pre-Flight (Test Infrastructure)

**Goal:** Establish pytest infrastructure for linter testing. No linter code changes.

| Task | Agent | Files Created | Scope |
|------|-------|---------------|-------|
| pytest scaffold | Nelson | **CREATE** `test/linter/conftest.py`, `test/linter/__init__.py` | Medium |
| Test helpers | Nelson | **CREATE** `test/linter/helpers.py` | Small |
| Fixture directory | Nelson | **CREATE** `test/linter/fixtures/` with sample .lua files | Small |
| Baseline snapshot | Nelson | **RUN** `python scripts/meta-lint/lint.py src/meta/ --format json` and record counts | Tiny |

**Nelson instructions:**

*conftest.py:*
- Configure pytest to find `scripts/meta-lint/` modules via `sys.path` manipulation
- Provide fixtures: `lint_runner` (calls lint.py programmatically), `sample_object` (minimal valid .lua file content), `sample_room` (minimal valid room .lua), `sample_creature` (minimal valid creature .lua), `sample_portal` (minimal valid portal .lua)
- Provide `tmp_meta_dir` fixture that creates a temporary `src/meta/`-like structure for isolated testing

*helpers.py:*
- `run_lint(files, flags=[])` → runs lint.py on given files, returns JSON output
- `assert_violation(output, rule_id)` → asserts a specific rule violation exists
- `assert_no_violation(output, rule_id)` → asserts no violation for that rule
- `count_violations(output, rule_id)` → counts violations for a rule

*fixtures/:*
- `valid-object.lua` — minimal valid object (guid, id, name, template, on_feel, keywords, description)
- `valid-room.lua` — minimal valid room (guid, id, name, template, instances, exits)
- `template-with-generic.lua` — template file with `material = "generic"` (for XR-05 testing)
- `keyword-collision-a.lua` and `keyword-collision-b.lua` — two objects sharing keywords (for XF-03 testing)

*Baseline snapshot:*
- Run full lint on current `src/meta/` and record: total violations by severity, total files scanned, execution time
- Store as `test/linter/baseline-snapshot.json`

**Verification:** `pytest test/linter/ --collect-only` lists all fixtures and test functions. No tests execute yet.

---

### WAVE-1: Bug Fixes Batch A (#190 XF-03, #196 XR-05)

**Goal:** Fix the two highest-noise false positives. XF-03 stops warning on intentionally shared keywords. XR-05 stops firing on templates.

**Depends on:** WAVE-0 complete (test infrastructure exists)

| Task | Agent | Files Modified/Created | TDD Test File | Scope |
|------|-------|------------------------|---------------|-------|
| XF-03 smart keyword filtering | Smithers | **MODIFY** `scripts/meta-lint/lint.py` | `test/linter/test_xf03.py` (Nelson) | Medium |
| XR-05 template suppression | Smithers | **MODIFY** `scripts/meta-lint/lint.py` | `test/linter/test_xr05.py` (Nelson) | Small |
| XF-03 config: allowed_shared list | Bart | **MODIFY** `scripts/meta-lint/config.py` | (covered by test_xf03.py) | Small |
| XF-03 regression tests | Nelson | **CREATE** `test/linter/test_xf03.py` | — | Medium |
| XR-05 regression tests | Nelson | **CREATE** `test/linter/test_xr05.py` | — | Small |

**File ownership (no overlap):**
- Smithers: `scripts/meta-lint/lint.py` (sole lint.py editor this wave)
- Bart: `scripts/meta-lint/config.py`
- Nelson: `test/linter/test_xf03.py`, `test/linter/test_xr05.py`

**Smithers instructions — XF-03 fix:**

Change XF-03 from unconditional warning to context-aware:
1. **Same-room objects:** Warn only if both objects share a room AND the keyword would create ambiguity (neither has a disambiguating keyword).
2. **Cross-room objects:** Downgrade to INFO — different rooms means no player-facing ambiguity.
3. **Config opt-out:** Read `config.get_rule_config("XF-03", "allowed_shared")` for a list of keywords that are intentionally shared (e.g., `["match", "key", "door"]`). Skip warning entirely for these.

The existing cross-file pass that checks XF-03 already collects keyword→file mappings. Add room membership resolution: look up which room each object belongs to via the room instances list. If both objects are in different rooms, downgrade severity.

**Smithers instructions — XR-05 fix:**

In the `_validate_cross_refs()` function (or wherever XR-05 fires), add a guard:
```python
if detected_kind == "template":
    continue  # Templates intentionally use generic material
```

This suppresses XR-05 for any file detected as `kind == "template"` by `_detect_kind()`. Object files with `material = "generic"` continue to trigger XR-05.

**Bart instructions — config.py:**

Add XF-03 default configuration:
```python
DEFAULT_RULE_CONFIG = {
    "XF-03": {
        "allowed_shared": ["match", "key", "door"],
        "cross_room_severity": "info",
    },
    ...
}
```

Ensure `config.get_rule_config(rule_id, key)` returns the value if configured, or None. Smithers' lint.py code calls this to check overrides.

**Nelson instructions — test suites:**

*test_xf03.py (~60 lines):*
1. Two objects in SAME room sharing keyword "match" with no disambiguator → WARNING
2. Two objects in DIFFERENT rooms sharing keyword "match" → INFO (downgraded)
3. Keyword in `allowed_shared` config list → no violation
4. Two objects sharing keyword where one has unique disambiguating keyword → no violation
5. Regression: objects with genuinely ambiguous keywords still trigger WARNING

*test_xr05.py (~30 lines):*
1. Template file with `material = "generic"` → no XR-05 violation
2. Object file with `material = "generic"` → XR-05 INFO fires
3. Object file with `material = "wool"` → no XR-05 violation

---

### WAVE-2: Bug Fix #195 + Fix-Safety Audit

**Goal:** Remove the noisy MD-19 rule. Complete the offline fix-safety audit for all 306 rules.

**Depends on:** GATE-1 pass (WAVE-1 fixes clean)

| Task | Agent | Files Modified/Created | TDD Test File | Scope |
|------|-------|------------------------|---------------|-------|
| Remove MD-19 rule | Flanders | **MODIFY** `scripts/meta-lint/lint.py` | `test/linter/test_md19.py` (Nelson) | Small |
| Fix-safety audit document | Bart | **CREATE** `docs/meta-lint/fix-safety-audit.md` | — | Large |
| MD-19 removal tests | Nelson | **CREATE** `test/linter/test_md19.py` | — | Small |

**File ownership (no overlap):**
- Flanders: `scripts/meta-lint/lint.py` (sole lint.py editor this wave — Smithers done in WAVE-1)
- Bart: `docs/meta-lint/fix-safety-audit.md` (offline doc, no code)
- Nelson: `test/linter/test_md19.py`

**Flanders instructions — MD-19 removal:**

Remove the MD-19 rule entirely from `lint.py`:
1. Delete the `_check_md19_dual_thermal()` function (or equivalent)
2. Remove MD-19 from the rule dispatch table
3. Remove MD-19 from `rule_registry.py` registration
4. Total rule count drops from 306 to 305

**Why remove instead of fix:** MD-19 fires INFO on materials with both `melting_point` and `ignition_point`. This is physically correct for most materials (wax, wood, metal). The rule generates only noise with zero actionable violations. If a dual-thermal check is needed later, it should be a NEW rule (MD-20) that validates `ignition_point < melting_point` for combustible materials.

**Bart instructions — fix-safety audit doc:**

Audit all 305 remaining rules (after MD-19 removal) and classify each:

| Classification | Definition | Example |
|---------------|------------|---------|
| `safe` | Idempotent, no semantic change. Adding missing required field with sensible default, fixing GUID format, normalizing casing. | S-01 (missing `id`), G-01 (GUID format) |
| `unsafe` | Semantic change requiring human review. Rewriting descriptions, changing materials, altering FSM transitions. | D-01 (description too short), MAT-05 (wrong material) |
| `false` (not fixable) | Requires design decision or cross-file coordination. Cannot be automated. | XF-01 (missing cross-reference), RM-03 (room layout) |

Document format:
```markdown
| Rule ID | Severity | Category | Fix Classification | Rationale |
|---------|----------|----------|-------------------|-----------|
| S-01    | Error    | Structure| safe              | Add template field with detected type |
| ...     | ...      | ...      | ...               | ...       |
```

This document is consumed by Smithers in WAVE-3 to populate `rule_registry.py` without conflicts.

**Nelson instructions — test_md19.py:**

*test_md19.py (~20 lines):*
1. Material with both `melting_point` and `ignition_point` → no MD-19 violation (rule removed)
2. Material with only `melting_point` → no MD-19 violation
3. Regression: other MD-* rules still fire (e.g., MD-01 missing density)

---

### WAVE-3: Fix Classification + CLI Integration

**Goal:** All 305 rules have `fix_safety` metadata in `rule_registry.py`. CLI supports `--fix` (safe only) and `--unsafe-fixes` (all fixable).

**Depends on:** GATE-2 pass (MD-19 removed, audit doc complete)

| Task | Agent | Files Modified/Created | TDD Test File | Scope |
|------|-------|------------------------|---------------|-------|
| Populate fix_safety in registry | Smithers | **MODIFY** `scripts/meta-lint/rule_registry.py` | `test/linter/test_fix_safety.py` (Nelson) | Large |
| `--fix` / `--unsafe-fixes` CLI flags | Smithers | **MODIFY** `scripts/meta-lint/lint.py` | `test/linter/test_cli_flags.py` (Nelson) | Medium |
| Fix-safety tests | Nelson | **CREATE** `test/linter/test_fix_safety.py`, `test/linter/test_cli_flags.py` | — | Medium |

**File ownership (no overlap):**
- Smithers: `scripts/meta-lint/rule_registry.py`, `scripts/meta-lint/lint.py`
- Nelson: `test/linter/test_fix_safety.py`, `test/linter/test_cli_flags.py`

**Smithers instructions — rule_registry.py:**

For each of the 305 rules, add `fix_safety` field using Bart's audit document as source:
```python
RULES = {
    "S-01": {
        "severity": "error",
        "category": "structure",
        "fixable": True,
        "fix_safety": "safe",
        "description": "...",
    },
    "D-01": {
        "severity": "warning",
        "category": "description",
        "fixable": True,
        "fix_safety": "unsafe",
        "description": "...",
    },
    "XF-01": {
        "severity": "error",
        "category": "cross-file",
        "fixable": False,
        "fix_safety": None,
        "description": "...",
    },
    ...
}
```

The `fixable` field already exists on ~5 rules. Extend it to all 305 and add `fix_safety` alongside.

**Smithers instructions — CLI flags:**

Add two new CLI flags to `lint.py`:
- `--fix`: Apply safe fixes only. For each violation where `fix_safety == "safe"`, apply the auto-fix and report what was changed. Skip `unsafe` and non-fixable.
- `--unsafe-fixes`: Apply ALL fixable violations (safe + unsafe). Requires explicit opt-in. Print a warning: "Applying unsafe fixes — review changes before committing."

Pattern follows Ruff's proven `--fix` / `--unsafe-fixes` model.

Both flags require `--format` to NOT be `json` (fixes modify files in place, not compatible with JSON output).

**Nelson instructions — test suites:**

*test_fix_safety.py (~50 lines):*
1. Every rule in registry has `fix_safety` field (not None for fixable rules)
2. `fix_safety` is one of: `"safe"`, `"unsafe"`, `None`
3. Rules with `fixable = True` must have `fix_safety` in (`"safe"`, `"unsafe"`)
4. Rules with `fixable = False` must have `fix_safety = None`
5. Count check: at least 305 rules registered (no rules accidentally dropped)
6. Known safe rules (from audit) verify correctly: spot-check 10 rules

*test_cli_flags.py (~40 lines):*
1. `--fix` on fixture with safe violation → file modified, violation reported as fixed
2. `--fix` on fixture with unsafe violation → file NOT modified, violation still reported
3. `--unsafe-fixes` on fixture with unsafe violation → file modified with warning
4. `--fix` with `--format json` → error message (incompatible flags)
5. No flags → normal reporting (no fixes applied)

---

### WAVE-4: EXIT-* Verification + CREATURE-* Implementation

**Goal:** Verify the 7 EXIT-* portal rules work correctly. Implement all 20 CREATURE-* rules from scratch.

**Depends on:** GATE-3 pass (Phase 1 complete, fix safety integrated)

| Task | Agent | Files Modified/Created | TDD Test File | Scope |
|------|-------|------------------------|---------------|-------|
| EXIT-* test fixtures | Sideshow Bob | **CREATE** `test/linter/fixtures/portals/*.lua` | — | Small |
| CREATURE-* validator | Bart | **MODIFY** `scripts/meta-lint/lint.py` | `test/linter/test_creature_rules.py` (Nelson) | Large |
| CREATURE-* registry entries | Bart | **MODIFY** `scripts/meta-lint/rule_registry.py` | (same test file) | Medium |
| EXIT-* verification tests | Nelson | **CREATE** `test/linter/test_exit_rules.py` | — | Medium |
| CREATURE-* tests | Nelson | **CREATE** `test/linter/test_creature_rules.py` | — | Large |
| CREATURE-* test fixtures | Flanders | **CREATE** `test/linter/fixtures/creatures/*.lua` | — | Small |

**File ownership (no overlap):**
- Bart: `scripts/meta-lint/lint.py`, `scripts/meta-lint/rule_registry.py` (sole lint.py editor this wave)
- Sideshow Bob: `test/linter/fixtures/portals/*.lua`
- Flanders: `test/linter/fixtures/creatures/*.lua`
- Nelson: `test/linter/test_exit_rules.py`, `test/linter/test_creature_rules.py`

**Sideshow Bob instructions — EXIT-* fixtures:**

Create test fixture `.lua` files in `test/linter/fixtures/portals/`:
- `valid-portal.lua` — portal with all required fields (target, traversable per state, bidirectional_id)
- `missing-target.lua` — portal without `portal.target` (triggers EXIT-01)
- `missing-traversable.lua` — portal with FSM states lacking `traversable` (triggers EXIT-02)
- `orphan-bidirectional.lua` — portal with `bidirectional_id` but no matching partner (triggers EXIT-03)
- `mismatched-direction.lua` — portal where `direction_hint` doesn't match room exit key (triggers EXIT-04)
- `inline-state-exit.lua` — room exit with inline `open`/`locked` fields (triggers EXIT-06)
- `no-on-feel-portal.lua` — portal without `on_feel` (triggers EXIT-07)

**Bart instructions — CREATURE-* implementation (~150 LOC lint.py + 20 entries registry):**

Add `_validate_creature()` function to `lint.py`. Detection: objects with `animate = true` OR `template = "creature"`.

CREATURE-* rules run AFTER standard OBJ-* checks pass (ensures basic object validity first).

| Rule | Severity | Check |
|------|----------|-------|
| CREATURE-001 | Error | `animate = true` must exist |
| CREATURE-002 | Error | `behavior` table must exist |
| CREATURE-003 | Error | `behavior` must have ≥1 drive entry |
| CREATURE-004 | Error | `behavior.states` must include `"idle"` key |
| CREATURE-005 | Error | `health` and `max_health` must be numbers |
| CREATURE-006 | Error | `alive` must be boolean |
| CREATURE-007 | Warning | Drive weights must each be 0.0–1.0 |
| CREATURE-008 | Warning | Drive weights must sum to ≤1.0 |
| CREATURE-009 | Error | `reactions` table must exist with ≥1 entry |
| CREATURE-010 | Warning | Each reaction must have `drive_deltas` table |
| CREATURE-011 | Error | `size` must be string enum (`tiny`, `small`, `medium`, `large`, `huge`) |
| CREATURE-012 | Error | `weight` must be positive number |
| CREATURE-013 | Warning | `material` must resolve to registered material |
| CREATURE-014 | Error | Standard OBJ `on_feel` check (reuse existing) |
| CREATURE-015 | Error | Standard OBJ `keywords` check (reuse existing) |
| CREATURE-016 | Error | Standard OBJ `description` check (reuse existing) |
| CREATURE-017 | Error | FSM must include `dead` state |
| CREATURE-018 | Warning | `dead` state should set `animate = false`, `portable = true` |
| CREATURE-019 | Warning | Room spawn GUIDs in placement must resolve to existing rooms |
| CREATURE-020 | Warning | Loot table GUIDs must resolve to existing objects |

CREATURE-014/015/016 reuse existing OBJ-*/MAT-* check functions — no code duplication.

Add `"creature"` to `_detect_kind()` path mapping:
```python
if "creatures" in parts:
    return "creature"
```

Register all 20 rules in `rule_registry.py` with appropriate `fix_safety`:
- Most are `fixable = False` (design decisions needed)
- CREATURE-001 (`animate = true` missing): `fixable = True, fix_safety = "safe"`
- CREATURE-006 (`alive` missing): `fixable = True, fix_safety = "safe"` (default `true`)

**Nelson instructions — test suites:**

*test_exit_rules.py (~80 lines):*
1. Valid portal fixture → no EXIT-* violations
2. Missing target → EXIT-01 error
3. Missing traversable → EXIT-02 error
4. Orphan bidirectional → EXIT-03 error
5. Mismatched direction → EXIT-04 warning
6. Inline state on exit → EXIT-06 error
7. Missing on_feel → EXIT-07 warning

*test_creature_rules.py (~120 lines):*
1. Valid creature fixture → no CREATURE-* violations
2. Missing `animate` → CREATURE-001 error
3. Missing `behavior` → CREATURE-002 error
4. Empty drives → CREATURE-003 error
5. No `idle` state → CREATURE-004 error
6. Non-numeric health → CREATURE-005 error
7. Drive weight > 1.0 → CREATURE-007 warning
8. Drive weights sum > 1.0 → CREATURE-008 warning
9. Missing reactions → CREATURE-009 error
10. Invalid size string → CREATURE-011 error
11. Missing `dead` FSM state → CREATURE-017 error
12. `dead` state without `animate = false` → CREATURE-018 warning
13. Valid creature with body_tree → no violations (body_tree is optional)

---

### WAVE-5: Environment Variants + Routing + Caching

**Goal:** Per-level configuration profiles. Squad routing in JSON output. Incremental caching.

**Depends on:** GATE-4 pass (Phase 2 complete)

| Task | Agent | Files Modified/Created | TDD Test File | Scope |
|------|-------|------------------------|---------------|-------|
| Environment profiles | Bart | **MODIFY** `scripts/meta-lint/config.py`, `scripts/meta-lint/lint.py` | `test/linter/test_environments.py` (Nelson) | Medium |
| Squad routing enhancement | Bart | **MODIFY** `scripts/meta-lint/squad_routing.py` | `test/linter/test_routing.py` (Nelson) | Small |
| Incremental caching | Bart | **MODIFY** `scripts/meta-lint/cache.py` | `test/linter/test_caching.py` (Nelson) | Medium |
| Phase 3 test suite | Nelson | **CREATE** `test/linter/test_environments.py`, `test/linter/test_routing.py`, `test/linter/test_caching.py` | — | Medium |

**File ownership (no overlap):**
- Bart: `scripts/meta-lint/config.py`, `scripts/meta-lint/lint.py`, `scripts/meta-lint/squad_routing.py`, `scripts/meta-lint/cache.py`
- Nelson: all test files

**Note:** Bart edits 4 files in this wave. This is acceptable because all 4 are under Bart's sole ownership and there are no parallel lint.py editors.

**Bart instructions — environment profiles (config.py + lint.py):**

Add environment profiles to config system:
```python
ENVIRONMENTS = {
    "level-01": {
        "profile": "strict",
        "disable": [],
    },
    "level-02": {
        "profile": "moderate",
        "disable": ["XF-03"],
    },
    "sandbox": {
        "profile": "permissive",
        "disable": ["S-12", "S-13", "XR-05"],
    },
}
```

Add `--env` CLI flag to `lint.py`:
```bash
python scripts/meta-lint/lint.py --env level-01 src/meta/
```

When `--env` is set, load the environment profile and filter out disabled rules before validation. Default (no `--env`): all rules active (current behavior preserved).

Environment config can also come from `.meta-lint.toml` or `.meta-check.json` (extend existing config file support).

**Bart instructions — squad routing (squad_routing.py):**

The `squad_routing.py` module already exists (~2,326 bytes). Enhance it:
1. Ensure all rule prefixes map to owning agents (from `plans/linter-improvement-plan.md` Section 5.1):
```python
ROUTING_TABLE = {
    "S-*":        "Smithers",
    "SI-*":       "Flanders",
    "RM-*":       "Moe",
    "EXIT-*":     "Sideshow Bob",
    "CREATURE-*": "Flanders",
    "FSM-*":      "Bart",
    "MAT-*":      "Flanders",
    "XF-*":       "Smithers",
    "XR-*":       "Smithers",
    "G-*":        "Bart",
    "D-*":        "Smithers",
    "T-*":        "Smithers",
}
```
2. Add `"owner"` field to JSON violation output
3. Add `--by-owner` CLI flag for grouped-by-agent output

**Bart instructions — incremental caching (cache.py):**

The `cache.py` module already exists (~3,167 bytes). Enhance it:
1. SHA-256 hash each `.lua` file
2. Cache format: `{ file_path: { hash: "abc...", violations: [...], timestamp: "..." } }`
3. On re-run: skip files whose hash hasn't changed
4. **Cross-file invalidation:** When ANY file changes, invalidate cache for cross-file rules (XF-*, XR-*, EXIT-03, CREATURE-019, CREATURE-020). Single-file rules remain cached.
5. Cache location: `.meta-lint-cache.json` in project root
6. `--no-cache` flag to force full re-scan
7. Target: <100ms for incremental runs with 1-2 file changes (vs ~180ms full scan)

**Nelson instructions — test suites:**

*test_environments.py (~40 lines):*
1. `--env level-01` runs all rules (strict profile)
2. `--env level-02` skips XF-03 (moderate profile)
3. `--env sandbox` skips S-12, S-13, XR-05 (permissive profile)
4. No `--env` flag → all rules active (backward compatible)
5. Unknown env name → clear error message

*test_routing.py (~30 lines):*
1. S-01 violation routes to "Smithers"
2. CREATURE-001 violation routes to "Flanders"
3. EXIT-01 violation routes to "Sideshow Bob"
4. JSON output includes `"owner"` field
5. `--by-owner` groups violations by agent name

*test_caching.py (~50 lines):*
1. First run with empty cache → full scan, cache file created
2. Second run (no changes) → cached result, faster execution
3. One file modified → only that file re-scanned + cross-file rules re-run
4. `--no-cache` → full scan regardless of cache
5. Cross-file rules invalidated when any file changes
6. Cache format validates (hash, violations, timestamp)

---

## Section 4: Testing Gates

### GATE-1: Bug Fixes A (XF-03 + XR-05)

**After:** WAVE-1 completes  
**Tests that must pass:**
- `pytest test/linter/test_xf03.py` — all 5 assertions green
- `pytest test/linter/test_xr05.py` — all 3 assertions green
- `python scripts/meta-lint/lint.py src/meta/ --format json` — zero false positives from XF-03 on known-shared keywords, zero XR-05 on templates
- Full lint run: no regressions in violation count (compare to WAVE-0 baseline — violations should DECREASE)

**Pass/fail:** ALL tests pass, violation count decreased or unchanged. Binary.  
**Reviewer:** Bart (architecture), Marge (test sign-off)  
**Action on fail:** File issue, assign to Smithers (lint.py fix) or Nelson (test fix), re-gate.

**On pass:** `git add -A && git commit -m "GATE-1: Linter Phase 1A — XF-03 + XR-05 false positives fixed (#190, #196)" && git push`

---

### GATE-2: Bug Fix B + Audit (MD-19 + Fix Safety)

**After:** WAVE-2 completes  
**Tests that must pass:**
- `pytest test/linter/test_md19.py` — all 3 assertions green
- Full lint run: MD-19 no longer fires
- `docs/meta-lint/fix-safety-audit.md` exists with all 305 rules classified

**Pass/fail:** ALL tests pass, audit doc complete. Binary.  
**Reviewer:** Bart (architecture), Marge (test sign-off)

**On pass:** `git add -A && git commit -m "GATE-2: Linter Phase 1B — MD-19 removed (#195), fix-safety audit complete" && git push`

---

### GATE-3: Phase 1 Complete (Fix Classification Integrated)

**After:** WAVE-3 completes  
**Tests that must pass:**
- `pytest test/linter/test_fix_safety.py` — all 6 assertions green
- `pytest test/linter/test_cli_flags.py` — all 5 assertions green
- Full lint run: zero regressions
- `--fix` dry run on test fixtures: safe fixes applied correctly

**Pass/fail:** ALL tests pass, all 305 rules have fix_safety metadata. Binary.  
**Reviewer:** Bart (architecture), Marge (test sign-off)

**On pass:** `git add -A && git commit -m "GATE-3: Linter Phase 1 complete — fix classification + --fix CLI" && git push`

---

### GATE-4: Phase 2 Complete (EXIT + CREATURE Validation)

**After:** WAVE-4 completes  
**Tests that must pass:**
- `pytest test/linter/test_exit_rules.py` — all 7 EXIT-* rules verified
- `pytest test/linter/test_creature_rules.py` — all 13+ CREATURE-* tests green
- Full lint on `src/meta/` with creature files: new CREATURE-* rules fire correctly
- Full lint run: zero regressions in non-creature/portal rules
- Total rule count: 325 (305 remaining + 20 CREATURE-*)

**Pass/fail:** ALL tests pass, zero regressions. Binary.  
**Reviewer:** Bart (architecture), Marge (test sign-off)

**On pass:** `git add -A && git commit -m "GATE-4: Linter Phase 2 complete — EXIT-* verified, CREATURE-* implemented (325 rules)" && git push`

---

### GATE-5: Phase 3 Complete (Architecture Evolution)

**After:** WAVE-5 completes  
**Tests that must pass:**
- `pytest test/linter/test_environments.py` — all 5 environment profile tests green
- `pytest test/linter/test_routing.py` — all 5 routing tests green
- `pytest test/linter/test_caching.py` — all 6 caching tests green
- Full lint run: zero regressions
- Performance: incremental re-run with 1 changed file < 100ms

**Pass/fail:** ALL tests pass, zero regressions, perf target met. Binary.  
**Reviewer:** Bart (architecture), Marge (test sign-off)

**On pass:** `git add -A && git commit -m "GATE-5: Linter Phase 3 complete — env profiles, routing, caching (325 rules)" && git push`

---

## Section 5: Feature Breakdown — Per System

### 5.1 Bug Fixes (#190, #195, #196)

| Issue | Rule | Problem | Fix | Wave | Owner |
|-------|------|---------|-----|------|-------|
| #190 | XF-03 | Shared keywords trigger false warnings | Context-aware: same-room = warn, cross-room = info, config opt-out | WAVE-1 | Smithers |
| #196 | XR-05 | Templates with `generic` material flagged | Suppress for `kind == "template"` | WAVE-1 | Smithers |
| #195 | MD-19 | Dual thermal properties = noise | Remove rule entirely | WAVE-2 | Flanders |

### 5.2 Fix-Safety Classification

- **WAVE-2:** Bart produces offline audit doc (`docs/meta-lint/fix-safety-audit.md`) classifying all 305 rules
- **WAVE-3:** Smithers integrates classifications into `rule_registry.py` and adds CLI support
- Two-phase approach avoids `rule_registry.py` conflicts between WAVE-1 (Smithers editing lint.py) and WAVE-2 (Flanders editing lint.py)

### 5.3 EXIT-* Portal Validation (7 Rules)

Already implemented in `rule_registry.py` (per D-LINTER-EXIT-VERIFIED). WAVE-4 provides:
- Test fixtures (Sideshow Bob) covering each EXIT-* rule
- pytest verification (Nelson) confirming rules fire correctly
- No new lint.py code needed — just verification

### 5.4 CREATURE-* Creature Validation (20 Rules)

Greenfield implementation (0/20 exist). WAVE-4 provides:
- `_validate_creature()` function in lint.py (~150 LOC)
- 20 rule entries in `rule_registry.py`
- Test fixtures (Flanders) with valid and invalid creature definitions
- pytest suite (Nelson) covering all 20 rules

### 5.5 Environment Variants

Per-level rule configuration. Three built-in profiles:
- `strict` (Level 1): all rules active
- `moderate` (Level 2+): noisy rules disabled
- `permissive` (sandbox): minimal rules for rapid iteration

### 5.6 Squad Routing

Violation-to-agent routing. JSON output gains `"owner"` field. `--by-owner` flag for grouped output. Uses existing `squad_routing.py` module.

### 5.7 Incremental Caching

SHA-256 file hashing with per-file violation cache. Cross-file rules invalidate on any change. Target: <100ms incremental on 1-2 file changes.

---

## Section 6: Cross-System Integration Points

### Dependencies Between Linter Modules

```
lint.py (main pipeline, ~2,538 LOC)
├── imports config.py (per-rule configuration, environment profiles)
├── imports rule_registry.py (rule metadata, fix_safety, severity)
├── imports squad_routing.py (violation → agent mapping)
├── imports cache.py (incremental analysis, SHA-256 hashing)
└── imports lua_grammar.py (Lark Earley parser for .lua files)
```

### Single-File Bottleneck

`lint.py` is the bottleneck file. Only ONE agent can edit it per wave:
- WAVE-1: Smithers (XF-03 + XR-05 fixes)
- WAVE-2: Flanders (MD-19 removal)
- WAVE-3: Smithers (CLI flags)
- WAVE-4: Bart (CREATURE-* validator)
- WAVE-5: Bart (env flag + routing integration)

This serialization is the primary driver for the 6-wave structure.

### External Dependencies

- **NPC system (for CREATURE-*):** CREATURE-* rules in WAVE-4 can be implemented and tested with fixture files before the actual creature objects exist. The rules validate file format, not runtime behavior.
- **Portal unification (for EXIT-*):** EXIT-* rules are already implemented. WAVE-4 verifies them with fixtures independent of the portal unification plan's execution.

---

## Section 7: Nelson LLM Test Scenarios

Not applicable — linter is a CLI tool, not a game. All testing uses pytest.

### Verification Commands

```bash
# Run all linter tests
pytest test/linter/ -v

# Run full lint to check for regressions
python scripts/meta-lint/lint.py src/meta/ --format json

# Verify specific fix
python scripts/meta-lint/lint.py src/meta/ --format json | python -c "import json,sys; d=json.load(sys.stdin); print([v for v in d.get('violations',[]) if v['rule']=='XF-03'])"

# Test incremental caching
python scripts/meta-lint/lint.py src/meta/ --format json  # first run
python scripts/meta-lint/lint.py src/meta/ --format json  # second run (cached)
```

---

## Section 8: TDD Test File Map

| Feature | Test File | Written In | Key Assertions |
|---------|-----------|-----------|----------------|
| XF-03 keyword collision fix | `test/linter/test_xf03.py` | WAVE-1 | Same-room vs cross-room, config opt-out, disambiguator |
| XR-05 generic material fix | `test/linter/test_xr05.py` | WAVE-1 | Template suppression, object still flagged |
| MD-19 removal | `test/linter/test_md19.py` | WAVE-2 | Rule no longer fires, other MD-* unaffected |
| Fix-safety registry | `test/linter/test_fix_safety.py` | WAVE-3 | All rules classified, field types valid, count ≥ 305 |
| CLI fix flags | `test/linter/test_cli_flags.py` | WAVE-3 | --fix safe only, --unsafe-fixes all, JSON incompatibility |
| EXIT-* portal rules | `test/linter/test_exit_rules.py` | WAVE-4 | All 7 EXIT rules verified with fixtures |
| CREATURE-* rules | `test/linter/test_creature_rules.py` | WAVE-4 | All 20 rules with valid/invalid creature fixtures |
| Environment profiles | `test/linter/test_environments.py` | WAVE-5 | strict/moderate/permissive profiles, backward compat |
| Squad routing | `test/linter/test_routing.py` | WAVE-5 | Owner field in JSON, by-owner grouping |
| Incremental caching | `test/linter/test_caching.py` | WAVE-5 | Cache creation, skip, invalidation, --no-cache |

---

## Section 9: Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| **lint.py edit conflict between waves** | PREVENTED | — | Only ONE agent edits lint.py per wave. Strict ownership enforcement. |
| **XF-03 fix over-suppresses real collisions** | Medium | Medium | Test includes same-room ambiguous keywords case. Config opt-out is explicit. |
| **CREATURE-* rules fire on non-creature objects** | Low | Medium | Detection gated on `animate = true` OR `template = "creature"`. Standard objects don't have these. |
| **Fix-safety audit misclassifies a rule** | Medium | Low | Audit doc is reviewed by Smithers before WAVE-3 integration. Misclassification is correctable. |
| **Cache invalidation misses cross-file dependency** | Medium | Medium | Conservative: ANY file change invalidates ALL cross-file rules. Over-invalidation is safe; under-invalidation is not. |
| **pytest not available in CI** | Low | High | WAVE-0 verifies pytest installation. Add to CI requirements if missing. |
| **EXIT-* rules have bugs despite being "implemented"** | Medium | Medium | WAVE-4 is specifically a VERIFICATION wave. Test fixtures designed to hit each rule's edge cases. |
| **Environment profiles break existing CI** | Low | Medium | No `--env` flag = all rules active. Backward compatible by default. |
| **rule_registry.py merge conflicts** | Medium | Medium | Only Smithers edits registry in WAVE-3. Bart edits in WAVE-4. Never parallel. |

---

## Section 10: Autonomous Execution Protocol

### Coordinator Execution Loop

```
FOR each WAVE in [WAVE-0, WAVE-1, WAVE-2, WAVE-3, WAVE-4, WAVE-5]:

  1. SPAWN parallel agents per wave assignment table
     - Each agent gets: task description, exact files, TDD requirements
     - Only ONE agent touches lint.py per wave
  
  2. COLLECT results from all agents
     - Check: all files created/modified as specified
     - Check: no unintended file changes (git diff --stat)
  
  3. RUN gate tests:
     pytest test/linter/ -v
     + python scripts/meta-lint/lint.py src/meta/ --format json (regression check)
     + compare violation counts to baseline
  
  4. EVALUATE gate:
     IF all tests pass AND zero regressions:
       COMMIT: git add -A && git commit -m "GATE-N: {description}" && git push
       → PROCEED to next wave
     
     IF any test fails:
       FILE issue with failure details
       ASSIGN fix to the agent who owns the failing file
       RE-RUN gate after fix
       IF gate fails 1x: ESCALATE to Wayne
```

### Commit Pattern

One commit per gate, message format:
```
GATE-N: Linter {phase description}

- {summary of changes}
- Tests: {count} new, 0 regressions
- Rule count: {current total}

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

### Wayne Check-In Points

Wayne only needs to be involved at:
1. **GATE-3** (Phase 1 complete) — review fix-safety audit, test `--fix` behavior
2. **GATE-5** (Phase 3 complete) — review squad routing, environment profiles
3. **Any escalation** from gate failures

---

## Section 11: Gate Failure Protocol

### Failure Handling Procedure

**Step 1: First failure**
- Coordinator files a GitHub issue with: which gate failed, which test(s) failed, full error output
- Assign fix to the appropriate agent
- Re-gate: run ONLY the failed test items
- **Escalate to Wayne** with diagnostic summary (1x threshold)

**Step 2: Second failure (same test)**
- Escalate immediately to Wayne with full diagnostic
- Wayne decides: retry with different agent, redesign approach, or defer

### Lockout Policy

If an agent's code failed a gate twice, that agent is locked out. Fresh agent takes over.

---

## Section 12: Who Does What (Staffing Matrix)

| Agent | WAVE-0 | WAVE-1 | WAVE-2 | WAVE-3 | WAVE-4 | WAVE-5 |
|-------|--------|--------|--------|--------|--------|--------|
| **Bart** | — | config.py (XF-03 config) | Audit doc (offline) | — | lint.py (CREATURE-*), registry | config.py, lint.py, squad_routing.py, cache.py |
| **Smithers** | — | lint.py (XF-03, XR-05) | — | registry, lint.py (CLI) | — | — |
| **Flanders** | — | — | lint.py (MD-19) | — | fixtures/creatures/ | — |
| **Sideshow Bob** | — | — | — | — | fixtures/portals/ | — |
| **Nelson** | pytest scaffold, fixtures, baseline | test_xf03.py, test_xr05.py | test_md19.py | test_fix_safety.py, test_cli_flags.py | test_exit_rules.py, test_creature_rules.py | test_environments.py, test_routing.py, test_caching.py |
| **Brockman** | — | — | — | Update rules.md | Document new categories | Update usage.md |

---

## Section 13: References

| Resource | Location |
|----------|----------|
| Source design plan | `plans/linter-improvement-plan.md` |
| Current linter source | `scripts/meta-lint/lint.py` (~2,538 LOC) |
| Rule registry | `scripts/meta-lint/rule_registry.py` |
| Config module | `scripts/meta-lint/config.py` |
| Squad routing module | `scripts/meta-lint/squad_routing.py` |
| Cache module | `scripts/meta-lint/cache.py` |
| Linter docs | `docs/meta-lint/` |
| Portal unification plan | `plans/portal-unification-plan.md` (EXIT-* rules, Section 6.4) |
| NPC system plan | `plans/npc-system-plan.md` (CREATURE-* rules, Section 11) |
| Linter research | `resources/research/architecture/linters/INDEX.md` |

---

> **Footer — Mutation Graph Linter:**  
> The mutation graph linter (`plans/mutation-graph-linter-plan.md`) is a **separate effort** from this plan. It is a pure-Lua test that validates mutation edges (becomes, spawns, crafting), NOT a Python meta-lint rule. It runs via `test/run-tests.lua`, not `scripts/meta-lint/lint.py`. The two efforts are independent and can be implemented in parallel.
