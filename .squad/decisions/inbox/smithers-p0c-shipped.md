# Decision: P0-C Shipped — Meta-Check V2

**Author:** Smithers (UI Engineer)
**Date:** 2026-07-19
**Status:** Shipped
**Issue:** #167

## What Shipped

Meta-check V2: full validation coverage for ALL `.lua` files under `src/meta/`.

### New Rule Categories

| Category | Rules | Coverage |
|----------|-------|----------|
| Template Definitions (TD) | 27 | `src/meta/templates/` (5 files) |
| Injury Definitions (INJ) | 69 | `src/meta/injuries/` (7 files) |
| Material Definitions (MD) | 24 | `src/meta/materials/` (23 files) |
| Level Definitions (LV ext.) | 31 | `src/meta/levels/` (1 file) |
| Cross-References (XR) | 11 | Cross-type validation |
| **Total V2 new** | **~160** | Combined with V1: **~306 total** |

### MAT-02 Fix

The `_load_materials()` function was reading material names from `src/engine/materials/init.lua` (stale hardcoded registry), causing 87 false-positive errors. Fixed to scan `src/meta/materials/*.lua` filenames dynamically.

## Impact on Other Agents

- **Flanders (Objects):** New objects will be validated against material cross-references (XR-04/MAT-02). Material field must match a `.lua` file in `src/meta/materials/`.
- **Moe (Rooms):** Rooms are now checked for level membership (XR-10). Orphaned rooms get a WARNING.
- **Lisa (QA):** V2 acceptance criteria fully implemented. 130 files, 0 errors. Ready for test verification.
- **Nelson (Tests):** No test files changed. Meta-check is a standalone Python tool.
- **Brockman (Docs):** `rules.md` and `schemas.md` updated to V2.

## Verification

```
python scripts/meta-check/check.py src/meta/ --severity error --verbose
# Files scanned: 130, Violations: 0
```
