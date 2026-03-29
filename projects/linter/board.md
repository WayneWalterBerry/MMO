# Linter Improvement — Board

**Owner:** 🔍 Wiggum (Linter Engineer)
**Last Updated:** 2026-03-29
**Overall Status:** 🚀 EXECUTING — 5/6 waves complete, GATE-4 blocking
**Plan:** `plans/linter/linter-improvement-implementation-phase1.md`

---

## Next Steps

**Test Score:** 70/74 pytest passing (94%)

| Priority | Task | Blocker | Owner |
|----------|------|---------|-------|
| P0 | Fix 4 CREATURE validation bugs (CREATURE-003, 004, 007, 008) in lint.py | Closes GATE-4 | Bart |
| P1 | Update linter board after GATE-4 passes → mark all waves complete | Blocked by P0 | Wiggum |
| P2 | Mutation-graph Phase 2 deferred | Future work | — |

---

## Execution Status

| Wave | Name | Status | Gate | Owner (lint.py) |
|------|------|--------|------|-----------------|
| WAVE-0 | Pre-Flight (pytest scaffold) | ✅ Done | — | Nelson |
| WAVE-1 | Bug Fixes A (#190 XF-03, #196 XR-05) | ✅ Done | GATE-1 | Smithers |
| WAVE-2 | Bug Fix B (#195 MD-19) + Fix-Safety Audit | ✅ Done | GATE-2 | Flanders |
| WAVE-3 | Fix Classification + CLI (`--fix`) | ✅ Done | GATE-3 | Smithers |
| WAVE-4 | EXIT-* Verification + CREATURE-* Implementation | ⚠️ Partial (27 rules, EXIT 6/6 ✅, CREATURE 4 bugs) | GATE-4 | Bart |
| WAVE-5 | Env Variants + Routing + Caching | ✅ Done | GATE-5 | Bart |

**Constraint:** Only ONE agent edits `lint.py` per wave (serialized bottleneck).

---

## Open Bugs

| Issue | Rule | Problem | Wave | Owner | Status |
|-------|------|---------|------|-------|--------|
| #190 | XF-03 | Keyword collision false positives (match/matchbox) | WAVE-1 | Smithers | ✅ CLOSED |
| #195 | MD-19 | Dual thermal noise (melting + ignition both valid) | WAVE-2 | Flanders | ✅ CLOSED |
| #196 | XR-05 | Generic material fires on templates (intentional) | WAVE-1 | Smithers | ✅ CLOSED |

---

## Rule Categories

| Category | Rules | Status | Wave |
|----------|-------|--------|------|
| Existing 306 rules | V1 (144) + V2 (162) | ✅ Production | — |
| EXIT-01 through EXIT-07 | 7 portal rules | ✅ Verification done (6/6 tests) | WAVE-4 |
| CREATURE-001 through CREATURE-020 | 20 creature rules | ⚠️ 27 registered, 4 validation bugs (003, 004, 007, 008) | WAVE-4 |
| Fix-safety classification | All 220 rules | ✅ All classified + metadata applied | WAVE-2/3 |
| Environment profiles (dev/prod) | Config system | ✅ --env flag working | WAVE-5 |
| Squad routing (owner per violation) | All rules | ✅ squad_routing working | WAVE-5 |
| Incremental caching | SHA-256 keyed | ✅ All 11 tests pass | WAVE-5 |

**Current rule count:** 220 (after MD-19 removal)

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
| WAVE-1 | WAVE-0 (pytest scaffold) | ✅ GATE-0 |
| WAVE-2 | GATE-1 | ✅ GATE-1 |
| WAVE-3 | GATE-2 | ✅ GATE-2 |
| WAVE-4 | GATE-3 | ✅ GATE-3 (blocked by 4 CREATURE bugs) |
| WAVE-5 | GATE-4 | ✅ GATE-4 (waiting on CREATURE fix) |

---

## Key Decisions

| ID | Decision | Status |
|----|----------|--------|
| D-LINTER-IMPL-WAVES | 6 waves, serialized lint.py edits | 🟢 Active |
| D-BENCHMARK-GATING | bench-*.lua prefix, --bench flag | 🟢 Active |
| D-LINTER-AUDIT-BASELINE | New meta files must pass lint with zero new findings | 🟢 Active |

---

*Board maintained by Wiggum. Update after each wave completion.*
