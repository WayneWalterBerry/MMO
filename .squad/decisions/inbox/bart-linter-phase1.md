# D-LINTER-PHASE1 — Meta-Check Rule Registry & Configuration

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-30  
**Status:** Implemented  
**Branch:** squad/linter-improvements

## Decision

Meta-check now has three new architectural layers:

### 1. Rule Registry (`scripts/meta-check/rule_registry.py`)

Every rule the linter can emit is registered with metadata:
- `severity`: default error/warning/info level
- `fixable`: whether the violation can be auto-fixed
- `fix_safety`: "safe" (idempotent) or "unsafe" (needs human review)
- `category`: grouping key for bulk enable/disable
- `description`: human-readable description

**110+ rules registered** across 13 categories (parse, structure, guid, template, injury, material, level, sensory, fsm, transition, material-ref, room, cross-file, cross-ref).

### 2. Per-Rule Configuration (`.meta-check.json`)

Teams can customize which rules run via a JSON config file:

```json
{
    "rules": {
        "XF-03": { "enabled": false },
        "MD-19": { "severity": "error" }
    },
    "categories": {
        "injury": { "enabled": false }
    },
    "keyword_allowlist": ["door", "barrel"]
}
```

**Rule override beats category override** — if a rule is explicitly enabled but its category is disabled, the rule still runs.

### 3. Safe/Unsafe Fix Classification

JSON output now includes `fixable` and `fix_safety` fields per violation, plus summary counts. This enables future auto-fix tooling to distinguish:
- **Safe fixes**: Can be applied automatically (e.g., id/filename mismatch)
- **Unsafe fixes**: Need human review (e.g., keyword collision resolution)

### 4. Rule Gap Fixes

- **XF-03**: Smart keyword collision filtering — built-in category keywords (garment, clothing, weapon, etc.) and config allowlist suppress false positives
- **MD-19**: Upgraded from simple INFO to conflict detection — warns when melting_point ≤ ignition_point with actual values in the message
- **XR-05b**: New rule — warns when objects inherit a template with `material="generic"` without overriding the material

## Who Should Know

- **Nelson/Lisa (QA)**: New test file at `test/meta-check/test_phase1.py` (29 tests). Config can suppress noisy rules during development.
- **Flanders (Objects)**: XR-05b may flag objects that are missing material overrides.
- **Gil (CI)**: JSON output format bumped to v2.0 with `fixable`/`fix_safety` fields.
- **All**: Use `--list-rules` to see all rules, `--init-config` to generate a default config file.
