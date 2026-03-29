# Linter Improvement Plan

**Author:** Bart (Architecture Lead)  
**Date:** 2026-07-29  
**Status:** Draft  
**Audience:** Squad (all agents), Wayne  
**References:** Frink's linter research (`resources/research/architecture/linters/`), open issues #190, #195, #196, #197

---

## 1. Summary

Meta-lint is the quality gate for all `src/meta/` content. It currently validates 306 rules across 20 categories in a 1,900-line Python + Lark pipeline. It works — 0 false positives on 130+ files, ~180ms per run. But the research and open issues expose gaps: keyword collision noise (#190), unhelpful info-level rules (#195, #196), no portal validation (#197), and no creature validation for the NPC system. We also lack safe/unsafe fix classification, per-rule config, Squad routing, and incremental caching.

**Target state:** A linter that handles EXIT-* portals, CREATURE-* creatures, routes violations to owning agents, supports per-rule configuration, and classifies every fix as safe or unsafe — while staying under 500ms and maintaining 0 false positives.

---

## 2. Current State

### What Works

| Metric | Value |
|--------|-------|
| Total rules | 306 (V1: 144, V2: +162) |
| Categories | 20 (structural, template, GUID, sensory, FSM, transitions, mutations, materials, rooms, nesting, cross-file, levels, composites, effects, lint, templates-v2, injuries, materials-v2, levels-v2, cross-refs) |
| Implementation | Python 3 + Lark Earley parser, 1,876 lines |
| Performance | ~180ms full scan, single-pass |
| False positive rate | 0% (verified by Lisa on 130 files + 3 planted defects) |
| Output formats | Text + JSON (`--format json`) |
| CI integration | GitHub Actions gate + pre-commit hook |

### What Doesn't Work

| Gap | Issue | Impact |
|-----|-------|--------|
| XF-03 keyword collisions | #190 | Shared keywords (e.g., "match" on match + matchbox) trigger false warnings |
| MD-19 dual thermal noise | #195 | INFO on materials with both `melting_point` and `ignition_point` is unhelpful — many materials legitimately have both |
| XR-05 generic material noise | #196 | INFO on `material = "generic"` fires on templates that intentionally lack material — too noisy |
| No portal validation | #197 | EXIT-* portals have no dedicated rules; portal-unification-plan defines 7 needed |
| No creature validation | — | NPC system plan defines 20 CREATURE-* rules; none implemented |
| No safe/unsafe fix classification | — | All 306 rules lack fix safety metadata |
| No per-rule config | — | Can't tune thresholds (e.g., max nesting depth) per level |
| No Squad routing | — | Violations don't indicate which agent owns the fix |
| No incremental caching | — | Full re-scan every run (fine at 130 files, won't scale to 500+) |

---

## 3. Phase 1: Quick Wins

**Timeline:** 1–2 weeks  
**Goal:** Fix open bugs, classify fixes, add per-rule config

### 3.1 Fix #190 — XF-03 Keyword Collision False Positives

**Problem:** `XF-03` warns when a keyword appears in multiple object files. But shared keywords are intentional — "match" belongs to both `match.lua` and `matchbox.lua` because the parser needs to find both.

**Fix:** Change XF-03 from unconditional warning to context-aware:
- **Same-room objects:** Warn only if both objects share a room AND the keyword would create ambiguity (neither has a disambiguating keyword).
- **Cross-room objects:** Downgrade to INFO — different rooms means no player-facing ambiguity.
- **Config opt-out:** Allow `[config.XF-03] allowed_shared = ["match", "key"]` in `meta-lint.toml`.

**Safety:** Safe — reduces false positives, doesn't miss real collisions.  
**Owner:** Smithers (parser/keyword resolution logic)

### 3.2 Fix #195 — MD-19 Dual Thermal Detection

**Problem:** MD-19 fires INFO whenever a material has both `melting_point` and `ignition_point`. This is physically correct for most materials (wax, wood, metal) — the rule generates noise.

**Fix:** Remove MD-19 entirely. Both thermal properties are valid and expected. If we need a rule here, it should validate that `ignition_point < melting_point` for combustible materials — but that's a new rule (MD-20), not MD-19.

**Safety:** Safe — removing an info-level rule that produces only noise.  
**Owner:** Flanders (material definitions)

### 3.3 Fix #196 — XR-05 Generic Material Info

**Problem:** XR-05 fires INFO on any object with `material = "generic"`. Templates intentionally use generic as a placeholder — this is by design, not a defect.

**Fix:** Suppress XR-05 for template-type files (`_detect_kind(path) == "template"`). Keep it for object files where `material = "generic"` likely indicates a missing material assignment.

**Safety:** Safe — templates intentionally use generic; objects should still be flagged.  
**Owner:** Smithers (cross-reference validator)

### 3.4 Safe/Unsafe Fix Classification

**Action:** Audit all 306 rules and tag each with `fixable = "safe" | "unsafe" | false`.

**Classification criteria:**
- **Safe:** Adding a missing required field with a sensible default, fixing GUID format, normalizing `id` casing. Idempotent, no semantic change.
- **Unsafe:** Rewriting descriptions, changing material assignments, altering FSM transitions. Semantic changes that need human review.
- **Not fixable:** Cross-file reference errors, structural violations that require design decisions.

**Output:** Add `fixable` field to JSON violation output. CLI gains `--fix` (safe only) and `--unsafe-fixes` (all) flags, matching Ruff's proven pattern.

**Owner:** Smithers (implementation) + Flanders (audit object rules) + Bart (audit engine rules)

### 3.5 Per-Rule Configuration

**Action:** Extend `meta-lint.toml` (or `.meta-lint.yaml`) to support per-rule options:

```toml
[rules.XF-03]
severity = "info"
allowed_shared = ["match", "key", "door"]

[rules.S-05]
severity = "warning"
pattern = "[a-z0-9-]+"

[rules.XR-05]
skip_templates = true
```

**Implementation:** Add a `_load_config()` phase before validation. Rules check config dict for overrides. Start with 10–15 rules that have known tuning needs.

**Owner:** Bart (config parser) + Smithers (rule integration)

---

## 4. Phase 2: Portal + Creature Validation

**Timeline:** 3–4 weeks (after Phase 1)  
**Goal:** New rule categories for portals and creatures

### 4.1 EXIT-* Portal Validation (7 Rules) — Issue #197

From `plans/portal-unification-design.md`, Section 6.4:

| Rule | Severity | Description |
|------|----------|-------------|
| EXIT-01 | 🔴 Error | Portal must have `portal.target` defined |
| EXIT-02 | 🔴 Error | Portal must have `traversable` on every FSM state |
| EXIT-03 | 🔴 Error | `bidirectional_id` must have exactly one matching partner |
| EXIT-04 | 🟡 Warning | `portal.direction_hint` should match room exit direction key |
| EXIT-05 | 🟡 Warning | Room thin exit should reference an object with `template = "portal"` |
| EXIT-06 | 🔴 Error | No inline exit state allowed (`open`/`locked`/`hidden` on exit table) |
| EXIT-07 | 🟡 Warning | Portal should have `on_feel` (darkness requirement) |

**Implementation:** Add `_validate_portal()` function in `lint.py`. Detect portals by `template = "portal"` or `id` starting with `EXIT-`. EXIT-03 requires cross-file analysis (bidirectional partner matching) — add to the existing cross-file pass alongside XF-01/XF-03.

**Owner:** Sideshow Bob (portal/puzzle design) + Bart (cross-file implementation)

### 4.2 CREATURE-* Creature Validation (20 Rules)

From `plans/npc-system-plan.md`, Section 11:

| Category | Rules | Count |
|----------|-------|-------|
| Core Metadata | CREATURE-001 through 006 | 6 |
| Drive Validation | CREATURE-007, 008 | 2 |
| Reaction Validation | CREATURE-009, 010 | 2 |
| Physical Properties | CREATURE-011 through 013 | 3 |
| Standard Object Rules | CREATURE-014 through 016 | 3 |
| FSM State Validation | CREATURE-017, 018 | 2 |
| Cross-Reference Validation | CREATURE-019, 020 | 2 |

**Detection:** Objects with `animate = true` or `template = "creature"`.  
**Sequencing:** CREATURE-* checks run AFTER standard OBJ-* checks pass. This ensures basic object validity before creature-specific validation.

**Key rules:**
- CREATURE-001: `animate = true` must exist
- CREATURE-002/003: `behavior` table with ≥1 drive
- CREATURE-004: `behavior.states` must include `"idle"` key
- CREATURE-007/008: Drive weights must sum to ≤1.0
- CREATURE-019/020: Room spawn GUIDs and loot table GUIDs must resolve

**Implementation:** Add `_validate_creature()` function. Add `"creature"` to `_detect_kind()` path mapping when creature directory is created. CREATURE-014/015/016 reuse existing OBJ-*/MAT-* checks — no duplication.

**Owner:** Flanders (creature definitions) + Bart (validator implementation)

### 4.3 Environment Variants (Level-Specific Rule Sets)

**Problem:** Level 1 (tutorial) has different constraints than Level 2+. Sandbox mode for testing should be permissive.

**Implementation:** Add environment profiles to config:

```toml
[environments.level-01]
profile = "strict"
disable = []

[environments.level-02]
profile = "moderate"
disable = ["XF-03"]

[environments.sandbox]
profile = "permissive"
disable = ["S-12", "S-13", "XR-05"]
```

CLI: `python scripts/meta-lint/lint.py --env level-01 src/meta/`

**Owner:** Comic Book Guy (defines constraints per level) + Bart (implementation)

---

## 5. Phase 3: Architecture Evolution

**Timeline:** 5–6 weeks (after Phase 2)  
**Goal:** Scale for 500+ objects and multi-agent coordination

### 5.1 Squad Routing Integration

**Problem:** When meta-lint reports 12 violations, nobody knows who should fix them.

**Implementation:** Add owner routing table to config:

```toml
[squad_routing]
"S-*"    = "Smithers"
"SI-*"   = "Flanders"
"RM-*"   = "Moe"
"EXIT-*" = "Sideshow Bob"
"CREATURE-*" = "Flanders"
"FSM-*"  = "Bart"
"MAT-*"  = "Flanders"
"XF-*"   = "Smithers"
"XR-*"   = "Smithers"
```

JSON output gains `"owner"` field per violation. Squad Coordinator can use this to auto-assign work.

**Effort:** ~4 hours  
**Owner:** Bart (routing logic) + Scribe (routing table maintenance)

### 5.2 Incremental Analysis with Caching

**Problem:** Full 130-file scan takes ~180ms now. At 500+ files (Level 2+), this grows linearly.

**Implementation:**
1. Hash each `.lua` file (SHA-256)
2. Cache `(file_hash, rule_results)` in `.meta-lint-cache.json`
3. On re-run, skip files whose hash hasn't changed
4. Invalidate cache for cross-file rules (XF-*, XR-*, EXIT-03) when ANY file changes

**Effort:** ~8 hours  
**Owner:** Bart

### 5.3 Plugin Extensibility (Deferred)

**Decision:** Stay closed-source through Level 2 (per Frink's recommendation). The 306+ built-in rules plus EXIT-* and CREATURE-* cover foreseeable needs. Re-evaluate for Level 3 if community or modding requires third-party rules.

**If needed:** Define a rule interface contract:
```python
class Rule:
    id: str
    severity: str
    applies_to: List[str]  # ["object", "room", "portal"]
    fixable: str  # "safe" | "unsafe" | false
    def check(self, parsed: ParsedFile) -> List[Violation]: ...
```

**Owner:** Bart (if triggered)

---

## 6. Who Does What

| Agent | Phase 1 | Phase 2 | Phase 3 |
|-------|---------|---------|---------|
| **Bart** | Per-rule config parser, fix audit (engine rules) | Creature validator, cross-file EXIT-03 | Squad routing, caching, plugin API |
| **Smithers** | Fix #190 XF-03, fix #196 XR-05, safe/unsafe CLI flags | — | — |
| **Flanders** | Fix #195 MD-19, fix audit (object rules) | CREATURE-* rule definitions | — |
| **Sideshow Bob** | — | EXIT-* portal rules | — |
| **Comic Book Guy** | — | Environment variant definitions | — |
| **Nelson** | Regression tests for #190/#195/#196 fixes | Test suites for EXIT-*/CREATURE-* | Cache invalidation tests |
| **Brockman** | Update rules.md with fix classifications | Document new rule categories | Update usage.md with routing |

---

## 7. Dependencies

```
Phase 1 (no blockers — start immediately)
├── #190 XF-03 fix ← no deps
├── #195 MD-19 fix ← no deps
├── #196 XR-05 fix ← no deps
├── Safe/unsafe audit ← no deps
└── Per-rule config ← no deps

Phase 2 (blocked by Phase 1 config system)
├── EXIT-* rules ← per-rule config (Phase 1.5) + portal-unification-plan completion
├── CREATURE-* rules ← per-rule config (Phase 1.5) + NPC system plan Phase 1
└── Environment variants ← per-rule config (Phase 1.5)

Phase 3 (blocked by Phase 2 rule count)
├── Squad routing ← JSON output (already exists) + routing table definition
├── Incremental caching ← stable rule set (Phase 2 complete)
└── Plugin extensibility ← deferred until Level 3
```

---

## 8. Reference

| Resource | Location |
|----------|----------|
| Linter research index | `resources/research/architecture/linters/INDEX.md` |
| ESLint patterns | `resources/research/architecture/linters/eslint-architecture.md` |
| Ruff patterns | `resources/research/architecture/linters/ruff-architecture.md` |
| Selene patterns | `resources/research/architecture/linters/selene-architecture.md` |
| Game validator patterns | `resources/research/architecture/linters/game-validators.md` |
| Current linter source | `scripts/meta-lint/lint.py` |
| Linter docs | `docs/meta-lint/` (overview, architecture, usage, rules, schemas) |
| Portal unification plan | `plans/portal-unification-design.md` (Section 6.4 — EXIT-* rules) |
| NPC system plan | `plans/npc-system-plan.md` (Section 11 — CREATURE-* rules) |
| Acceptance criteria V1 | `docs/meta-lint/acceptance-criteria.md` |
| Acceptance criteria V2 | `docs/meta-lint/acceptance-criteria-v2.md` |
| Decision: Python + Lark | `.squad/decisions.md` → D-LARK-GRAMMAR |
| Decision: compiler + linter | `.squad/decisions.md` → D-WAYNE-METACOMPILER-COMPILER-LINTER |
| Decision: V2 shipped | `.squad/decisions.md` → D-P0C-META-CHECK-V2 |
