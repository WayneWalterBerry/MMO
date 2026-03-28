# Phase 5 — Chunk 5: Operations

**Author:** Bart (Architecture Lead) | **Date:** 2026-03-28 | **Chunk:** 5/5  
**References:** Chunk 1 skeleton, Chalmers draft v0.1

---

## 1. Risk Register

Wayne's Q1–Q7 decisions significantly reduce risk: werewolf-as-NPC (Q1=B) avoids injury-system entanglement, salt-only (Q2=A) keeps WAVE-3 lean, humanoid NPCs deferred (Q3=C) eliminates the largest complexity source.

| # | Risk | L | I | Mitigation |
|---|------|---|---|------------|
| R1 | L2 room design incomplete at WAVE-1 start | Med | High | Moe + Bart complete sketch in PRE-WAVE; gate on sign-off |
| R2 | Pack role scope creep (zone-targeting bleeds in) | Med | Med | Scope locked at Q4=A; zone-targeting hard-deferred to P6 |
| R3 | Salt mutation conflicts with existing food FSM | Low | Med | Audit Phase 4 food objects in PRE-WAVE; document state grammar |
| R4 | Brass-key L1→L2 wiring breaks Level 1 exits | Low | High | Nelson regression after WAVE-1; transition tested in isolation |
| R5 | Werewolf stat imbalance (too strong/weak) | Med | Med | Wolf baseline × 1.5 multiplier; CBG reviews at GATE-1 |
| R6 | Test baseline regression from L2 integration | Low | High | Full suite at every gate; zero-regression; tag rollback |
| R7 | W2/W3 parallel hidden dependency on creature metadata | Low | Med | File ownership pre-assigned: pack.lua (Bart) vs salt (Flanders) |
| R8 | Pack AI performance with 3+ wolves per room | Low | High | Profile in WAVE-2; cap at 4 wolves/room; optimize if measured |
| R9 | Phase 5 overscope (4 waves + ~800 LOC) | Med | Med | WAVE-4 is pressure valve — ship with reduced polish if W1–W3 pass |
| R10 | Embedding index stale after new nouns | Low | Med | Smithers updates index in WAVE-1 and WAVE-3; verified at gates |

3 High-impact risks (R1, R4, R6) — all mitigated by gate-level regression + PRE-WAVE design sign-off.

---

## 2. Autonomous Execution Protocol

Per Skill Pattern 9 — walk-away capable. Coordinator orchestrates without Wayne unless escalation triggers.

### Execution Loop

```
WAVE-N → spawn parallel agents → agents complete → Nelson smoke-test
       → GATE-N (full suite + LLM walkthrough + arch review)
       → PASS? → git tag + commit + push → update status → checkpoint → WAVE-(N+1)
       → FAIL? → Gate Failure Protocol (§3)
```

### Rules

- **No file overlap:** No two agents touch the same file in the same wave
- **Multiple instances OK:** Same member on different files (label clearly)
- **Commits:** After every passing gate: `git commit` + `git tag phase5-gate-N` + push
- **Mid-wave emergency:** Commit WIP with `[WIP]` prefix, file issue
- **Nelson continuous testing:** Smoke after each agent, full suite at gates, exploratory between waves
- **All Nelson runs:** `--headless` mode, `math.randomseed(42)` for deterministic reproducibility

---

## 3. Gate Failure Protocol

### 1× Failure (autonomous)

1. Diagnose: identify failing tests + responsible agent
2. File GitHub issue: `[Phase 5] GATE-N failure: {description}`, labels: `phase5`, `gate-failure`
3. Assign fix agent → targeted fix only (no scope expansion)
4. Re-run full gate suite (not just failing tests)
5. If pass → resume normal flow

### 2× Failure on Same Gate (escalate)

1. **Escalate to Wayne:** "GATE-N failed twice. Root cause: X. Recommended fix: Y."
2. Do NOT proceed past the gate or attempt a third fix
3. Wayne chooses: approve fix, descope feature to Phase 6, or rollback

### Rollback Strategy

- **Tags:** `phase5-pre-wave`, `phase5-gate-1`, `phase5-gate-2`, etc.
- **Rollback:** `git reset --hard phase5-gate-N` → re-plan affected wave
- **Nuclear:** `git reset --hard phase5-pre-wave` if WAVE-1 itself is compromised

| Failure Count | Action | Decider |
|---------------|--------|---------|
| 1× | File issue → fix agent → re-gate | Coordinator |
| 2× same gate | Escalate → wait | Wayne |
| Post-rollback | Re-plan wave → fresh attempt | Coordinator + Bart |

---

## 4. Wave Checkpoint Protocol

After each wave completes and its gate passes:

1. **Verify:** All agents report done; no outstanding WIP commits
2. **Test:** `lua test/run-tests.lua` — record exact pass count
3. **Update tracker:** Wave status → `✅ Complete` with test count and date
4. **Commit:** `git commit -m "Phase 5 WAVE-N checkpoint: {wave name} complete"`
5. **Tag + push:** `git tag phase5-gate-N` → `git push --tags`
6. **Note deviations:** Document scope changes, file renames, unexpected dependencies
7. **Check readiness:** Verify WAVE-(N+1) dependencies satisfied → spawn next wave

---

## 5. Documentation Deliverables (Brockman)

"No phase ships without its docs" (Skill Pattern 7).

### After GATE-2

| File | Content |
|------|---------|
| `docs/design/level2-ecology.md` | L2 room descriptions, creature habitats, biome types, treasure placement, navigation map |
| `docs/architecture/creatures/werewolf-mechanics.md` | Stats, patrol behavior, territorial AI, combat multipliers, Phase 6 dialogue hooks |

### After GATE-3

| File | Content |
|------|---------|
| `docs/design/food-preservation-system.md` | Salt verb usage, mutation pipeline, spoilage comparison (fresh vs salted), Phase 6 hooks |
| `docs/architecture/creatures/pack-tactics-v2.md` | Coordination engine, alpha selection, omega reserve, stagger sequencing, performance budget |

### After GATE-4

| File | Content |
|------|---------|
| Phase 5 summary in implementation plan | Lessons, actual vs estimated LOC, gate failures, new risks, candidate skills |
| Updated `docs/design/design-directives.md` | New directives from Phase 5 (preservation, pack roles) |

All docs reference the governing decision (e.g., "Per Q1=B, werewolf is NPC type").

---

## 6. Phase 6 Preview

Deferred per Wayne's Q1–Q7 decisions and Chalmers' draft §10:

### 6a: Intelligence + Navigation
- **A* pathfinding** (250–300 LOC) — random-exit acceptable for V1 (Q5=B)
- **Environmental combat** — push/throw/climb (180–220 LOC) — combat-plan sequel (Q6=B)
- **Creature-to-creature looting** (150–200 LOC) — requires AI value evaluation

### 6b: Humanoid NPCs
- **Full NPC system** (400–600 LOC) — dialogue, memory, quests, factions (Q3=C)
- **Dialogue framework + quest hooks** (350–500 LOC) — prerequisite chain

### 6c: Systems Expansion
- **Full preservation** — smoking, drying, root cellar (200–250 LOC) — salt validates pattern first (Q2=A)
- **Zone-targeting pack attacks** (200–250 LOC) — simplified model sufficient for P5 (Q4=A)
- **Armor/weapon degradation** (100–150 LOC) — material system overhaul
- **Multi-ingredient cooking** (120–180 LOC) — recipe system beyond mutation

Recommended sequencing: 6a → 6b → 6c (smarter navigation unblocks NPC AI).

---

## 7. Success Criteria

Phase 5 is complete when ALL are true (binary pass/fail):

| # | Criterion | Verification |
|---|-----------|-------------|
| SC-1 | 7 Level 2 rooms instantiate with correct exits, zero orphans | Room instantiation tests |
| SC-2 | Brass key unlocks L1→L2 transition without breaking L1 | Nelson walkthrough: start → brass key → L2 |
| SC-3 | Werewolf exists as NPC type with combat stats + patrol + territory | Unit tests: spawn, attack, patrol, territory |
| SC-4 | Wolf pack coordination: stagger attacks, alpha by highest HP | Pack tests: 3-wolf turn-taking, alpha verified |
| SC-5 | Salt verb: salt + meat → salted-meat via mutation | Preservation tests: verb resolves, mutation fires |
| SC-6 | Salted meat spoils 3× slower than fresh (FSM timer) | Timer test: salted decay = fresh decay × 3 |
| SC-7 | ≥270 tests pass, ZERO regressions vs Phase 4 (223) | `lua test/run-tests.lua` |
| SC-8 | Full LLM walkthrough in `--headless` mode succeeds | Nelson: L1→key→L2→werewolf→pack→butcher→salt |
| SC-9 | All 4 design docs delivered and signed off | File existence + Brockman sign-off |
| SC-10 | All P0 issues closed or deferred with tracking ticket | Issue audit at GATE-4 |

---

**END OF CHUNK 5 (OPERATIONS)**

---

*Plan authored by Bart (Architecture Lead). Chunk 5/5 — Risk, autonomous execution, documentation deliverables, and Phase 6 preview.*
