# Linter Improvement — Board

**Owner:** 🔍 Wiggum (Linter Engineer)
**Last Updated:** 2026-03-29
**Overall Status:** 📋 PLANNED — Not yet executed
**Plan:** `plans/linter/linter-improvement-implementation-phase1.md`

---

## Execution Status

| Wave | Name | Status | Gate | Owner (lint.py) |
|------|------|--------|------|-----------------|
| WAVE-0 | Pre-Flight (pytest scaffold) | ⏳ Pending | — | Nelson |
| WAVE-1 | Bug Fixes A (#190 XF-03, #196 XR-05) | ⏳ Pending | GATE-1 | Smithers |
| WAVE-2 | Bug Fix B (#195 MD-19) + Fix-Safety Audit | ⏳ Pending | GATE-2 | Flanders |
| WAVE-3 | Fix Classification + CLI (`--fix`) | ⏳ Pending | GATE-3 | Smithers |
| WAVE-4 | EXIT-* Verification + CREATURE-* Implementation | ⏳ Pending | GATE-4 | Bart |
| WAVE-5 | Env Variants + Routing + Caching | ⏳ Pending | GATE-5 | Bart |

**Constraint:** Only ONE agent edits `lint.py` per wave (serialized bottleneck).

---

## Open Bugs

| Issue | Rule | Problem | Wave | Owner | Status |
|-------|------|---------|------|-------|--------|
| #190 | XF-03 | Keyword collision false positives (match/matchbox) | WAVE-1 | Smithers | ⏳ Pending |
| #195 | MD-19 | Dual thermal noise (melting + ignition both valid) | WAVE-2 | Flanders | ⏳ Pending |
| #196 | XR-05 | Generic material fires on templates (intentional) | WAVE-1 | Smithers | ⏳ Pending |

---

## Rule Categories

| Category | Rules | Status | Wave |
|----------|-------|--------|------|
| Existing 306 rules | V1 (144) + V2 (162) | ✅ Production | — |
| EXIT-01 through EXIT-07 | 7 portal rules | ⏳ Verification needed | WAVE-4 |
| CREATURE-001 through CREATURE-020 | 20 creature rules | ⏳ Not implemented | WAVE-4 |
| Fix-safety classification | All 306 rules | ⏳ Audit not started | WAVE-2/3 |
| Environment profiles (dev/prod) | Config system | ⏳ Not implemented | WAVE-5 |
| Squad routing (owner per violation) | All rules | ⏳ Not implemented | WAVE-5 |
| Incremental caching | SHA-256 keyed | ⏳ Not implemented | WAVE-5 |

**Target rule count after WAVE-4:** 325 (306 - 1 MD-19 removed + 20 CREATURE-*)

---

## Staffing Matrix

| Agent | WAVE-0 | WAVE-1 | WAVE-2 | WAVE-3 | WAVE-4 | WAVE-5 |
|-------|--------|--------|--------|--------|--------|--------|
| Wiggum | Oversee | Oversee | Oversee | Oversee | Oversee | Oversee |
| Bart | — | config.py | Audit doc | — | lint.py (CREATURE-*) | config, routing, cache |
| Smithers | — | lint.py (XF-03, XR-05) | — | rule_registry.py, CLI | — | — |
| Flanders | — | — | lint.py (MD-19) | — | creature fixtures | — |
| Sideshow Bob | — | — | — | — | portal fixtures | — |
| Nelson | pytest scaffold | test_xf03, test_xr05 | test_md19 | test_fix_safety, test_cli | test_exit, test_creature | test_env, test_routing, test_cache |

---

## Current Metrics

| Metric | Value |
|--------|-------|
| Total rules | 306 |
| Categories | 20 |
| Performance | ~180ms full scan |
| False positive rate | 0% |
| Files scanned | ~208 |
| Test infrastructure | pytest at `test/linter/` (scaffold exists) |

---

## Dependencies

| Blocked | Blocked By | Status |
|---------|-----------|--------|
| WAVE-1 | WAVE-0 (pytest scaffold) | ⏳ |
| WAVE-2 | GATE-1 | ⏳ |
| WAVE-3 | GATE-2 | ⏳ |
| WAVE-4 | GATE-3 | ⏳ |
| WAVE-5 | GATE-4 | ⏳ |

---

## Key Decisions

| ID | Decision | Status |
|----|----------|--------|
| D-LINTER-IMPL-WAVES | 6 waves, serialized lint.py edits | 🟢 Active |
| D-BENCHMARK-GATING | bench-*.lua prefix, --bench flag | 🟢 Active |
| D-LINTER-AUDIT-BASELINE | New meta files must pass lint with zero new findings | 🟢 Active |

---

*Board maintained by Wiggum. Update after each wave completion.*
