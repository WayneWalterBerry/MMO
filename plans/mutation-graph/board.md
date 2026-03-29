# Mutation-Graph Linter — Sprint Board

**Owner:** 🔍 Wiggum (Linter Engineer)
**Last Updated:** 2026-03-29
**Phase 1 Status:** ✅ COMPLETE — Production-ready
**Phase 2 Status:** 🔵 DEFERRED — Revisit when edges > 150 or chains > 2 hops

---

## Phase 1 — Expand & Lint Pipeline

| Wave | Status | Deliverables | Gate |
|------|--------|-------------|------|
| WAVE-0 | ✅ DONE | `scripts/mutation-edge-check.lua`, `test/meta/test-edge-extractor.lua` (58 tests) | GATE-0 ✅ |
| WAVE-1 | ✅ DONE | `scripts/mutation-lint.ps1`, `scripts/mutation-lint.sh`, integration tests (13 tests) | GATE-1 ✅ |
| WAVE-2 | ✅ DONE | `--json` flag, docs, skill, CI integration, 3 issues filed (#403-#405) | — |

### Broken Edges (was 5, now 0)

| Target | Source(s) | Status | Issue |
|--------|-----------|--------|-------|
| ~~poison-gas-vent-plugged~~ | poison-gas-vent.lua | ✅ Created | #403 closed |
| ~~wood-splinters~~ | 3 doors (bedroom-N, bedroom-S, courtyard-kitchen) | ✅ Created | #404 closed |
| courtyard-kitchen-door (2 edges) | duplicate spawn review | ✅ Intentional (documented) | #405 closed |

### Artifacts

| File | Type | Status |
|------|------|--------|
| `scripts/mutation-edge-check.lua` | Lua extractor (12 mechanisms) | ✅ Production |
| `scripts/mutation-lint.ps1` | PowerShell wrapper (PS7 parallel) | ✅ Production |
| `scripts/mutation-lint.sh` | Shell wrapper (xargs -P) | ✅ Production |
| `test/meta/test-edge-extractor.lua` | 58 tests | ✅ All pass |
| `test/meta/test-mutation-lint-integration.lua` | 13 tests | ✅ All pass |
| `.squad/skills/mutation-graph-lint/SKILL.md` | Skill file | ✅ Created |
| `.squad/skills/running-the-linter/SKILL.md` | Linter operations skill | ✅ Created |
| `docs/testing/mutation-graph-linting.md` | User guide | ✅ Created |
| `scripts/meta-lint/README.md` | Integration docs | ✅ Created |

### CI Integration

| Step | Location | Status |
|------|----------|--------|
| Lua edge check | `squad-ci.yml` | ✅ Active (continue-on-error) |
| Python meta-lint | `squad-ci.yml` | ✅ Active (continue-on-error) |
| Pre-deploy edge check | `run-before-deploy.ps1` | ✅ Active |
| `.gitattributes` line endings | `.gitattributes` | ✅ *.sh=LF, *.ps1=CRLF |

### Post-Mortem (Phase 1)

| Reviewer | Verdict | Report |
|----------|---------|--------|
| Bart | Design 100% delivered | `plans/mutation-graph/phase1-postmortem-bart.md` |
| Nelson | 71/71 tests, 100% mechanism coverage | `plans/mutation-graph/phase1-postmortem-nelson.md` |
| Brockman | Docs 9/10, production-ready | `plans/mutation-graph/phase1-postmortem-brockman.md` |
| Chalmers | Plan 100% adhered, rec: lightweight Phase 2 | `plans/mutation-graph/phase1-postmortem-chalmers.md` |
| **Wiggum** | **Defer Phase 2** — fix edges first (done), no 3+ hop chains exist | Assessment in history |

---

## Phase 2 — Multi-Hop Chain Validation (DEFERRED)

**Decision:** D-MUTATION-CYCLES-V2 — Deferred per Wiggum's recommendation

| Item | Priority | Status | Trigger to Revisit |
|------|----------|--------|-------------------|
| Multi-hop chain validation (A→B→C) | Low | 🔵 Deferred | Edges > 150 OR chains > 2 hops |
| `parts[]` extraction | None | ❌ Dropped | Inline definitions only — no file edges to validate |
| Circular chain detection | Low | 🔵 Deferred | Same trigger as multi-hop |

**Current metrics (Phase 1 baseline):**
- Files scanned: 208 (was 206, +2 new objects this session)
- Edges found: ~68
- Max chain depth: 2 hops
- Broken edges: 0

---

## Key Decisions

| ID | Decision | Status |
|----|----------|--------|
| D-MUTATION-LINT-PIVOT | Expand-and-lint (Lua extractor + Python meta-lint) | 🟢 Active |
| D-PARALLEL-EXPAND-LINT | Objects expanded and linted in parallel | 🟢 Active |
| D-MUTATION-LINT-PARALLEL | Sequential output display, parallel execution | 🟢 Active |
| D-MUTATION-CYCLES-V2 | Multi-hop chains deferred to Phase 2 | 🔵 Deferred |

---

## Ownership

| Domain | Owner | Boundary |
|--------|-------|----------|
| All mutation-graph tooling | Wiggum | `scripts/mutation-edge-check.lua`, wrappers, design, Phase 2 |
| All meta-lint tooling | Wiggum | `scripts/meta-lint/`, rules, config, CI |
| Tests (run, not modify) | Nelson | Can run linter, can't modify it |
| CI wiring | Gil (co-owned) | Gil wires CI steps, Wiggum owns the tool |

---

*Sprint board maintained by Wiggum. Update after each session touching mutation-graph scope.*
