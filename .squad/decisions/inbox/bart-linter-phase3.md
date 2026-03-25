# Decision: Linter Phase 3 — Squad Routing + Incremental Caching

**Author:** Bart (Architecture Lead)
**Date:** 2026-07-29
**Branch:** squad/linter-phase3

## What Changed

### Squad Routing
Every linter violation now includes an `owner` field identifying which squad member should fix it. The routing table maps rule ID patterns to owners using fnmatch. The default table covers all 15 rule categories:

| Pattern | Owner |
|---------|-------|
| S-*, PARSE-*, G-*, FSM-*, TR-*, SN-*, TD-*, GUID-* | Bart |
| INJ-*, MD-*, MAT-*, CREATURE-* | Flanders |
| RM-* | Moe |
| LV-* | Comic Book Guy |
| XF-*, XR-* | Smithers |
| EXIT-* | Sideshow Bob |

Overridable via `squad_routing` section in `.meta-check.json`.

### Incremental Caching
The linter now caches per-file violations keyed by SHA-256 hash. On re-run with no file changes, single-file validation is skipped entirely. Cross-file rules (XF/XR/GUID/EXIT/LV-40) always re-run. Use `--no-cache` for full re-scan.

## Who Needs to Know

- **Coordinator:** Can now use `--format json` output to auto-route violations to owning agents via the `owner` field
- **Smithers:** Owns 151/183 violations (143 XF-03 keyword collisions) — may want to review the keyword allowlist
- **Sideshow Bob:** Owns 4 EXIT-01 errors (exits to non-existent rooms)
- **All agents:** Text output now shows `[owner]` per violation; use `--by-owner` for grouped view
- **Gil:** Cache file `.meta-lint-cache.json` is gitignored; no web build impact

## Version

meta_check_version bumped from 2.0 → 3.0. JSON schema adds `owner` field to violations and `by_owner`/`cache` to summary.
