# Decision: Linter Phase 2 — GUID/EXIT Validation

**Author:** Bart (Architecture Lead)
**Date:** 2026-07-29
**Status:** Active

## What Changed

Added 5 new lint rules in Phase 2 of the linter improvement plan:

| Rule | Severity | Category | Description |
|------|----------|----------|-------------|
| GUID-01 | error | guid-xref | Room instance type_id must reference a known object GUID |
| GUID-02 | warning | guid-xref | Orphan object not referenced by any room instance |
| GUID-03 | error | guid-xref | Duplicate instance id within same room |
| EXIT-01 | error | exit | Exit target must reference a valid room |
| EXIT-02 | warning | exit | Bidirectional exit mismatch |

## Bug Fix: _detect_kind rooms/ directory

`_detect_kind()` was only matching `src/meta/world/` for rooms, but the actual directory is `src/meta/rooms/`. Room files were silently classified as "unknown" and skipped all room-specific validation. Fixed by adding `rooms/` pattern.

## Who This Affects

- **Moe** — GUID-02 reports 21 orphan objects. Some are intentional (mutation targets like matchbox-open, glass-shard). Moe should review which orphans are valid vs which need room placement.
- **Flanders** — GUID-01 now validates every type_id in room instances. Any new object must have its GUID match what rooms reference.
- **Nelson** — 20 new tests in test/meta-check/test_phase2.py. Run with `python test/meta-check/test_phase2.py`.
- **All content authors** — EXIT-01 flags exits to rooms that don't exist yet (4 found: level-2, manor-kitchen, manor-west, manor-east). These can be suppressed via config if they're intentional forward references.

## Configuration

All new rules respect the existing `.meta-check.json` per-rule config system:

```json
{
    "rules": {
        "GUID-02": { "enabled": false },
        "EXIT-01": { "severity": "warning" }
    }
}
```
