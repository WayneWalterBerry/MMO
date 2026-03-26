# NPC + Combat Phase 2 — Chunk 5: Operations

**Author:** Bart (Architect)
**Date:** 2026-07-30
**Chunk:** 5 of 5 — Risk Register, Autonomous Execution, Gate Failure, Wave Checkpoints, Documentation Deliverables
**Phase:** Phase 2: Creature Variety + Disease + Food PoC

---

## Section 10: Risk Register

| # | Risk | Like. | Impact | Mitigation |
|---|------|-------|--------|------------|
| R-1 | **Creature-to-creature cascade (3+ in one room)** | High | High | Hard cap: max 3 creature reactions per tick per room. Wolf's reaction to cat-kills-rat queues for NEXT tick. Unit test: 3-creature room, no infinite loop. |
| R-2 | **Multi-combatant turn order** | Med | High | Pairwise resolution only. 3-way fight = 2 exchange cycles per round (priority queue). No true N-way combat. Test with 3 fixed-seed combatants. |
| R-3 | **Rabies too lethal** | Med | Med | 15-turn incubation + 15% transmission chance. Poultice cures early stages. Tuning knob at GATE-4 LLM testing. Fallback: extend incubation to 25 turns. |
| R-4 | **Spider venom too punishing** | Med | Med | Spider is ambush-only (`territorial`), player must enter its room. Antidote available same level. CBG reviews at GATE-4. |
| R-5 | **Food system scope creep** | High | High | Hard boundary: eat/drink verbs + 2 food objects + hunger satisfaction ONLY. No cooking/spoilage/recipes. If >1 wave, cut. |
| R-6 | **Engine files approaching 500 LOC** | Med | Med | Module size guard (Pattern 13). Likely splits: `creatures/init.lua` → `tick.lua` + `actions.lua`; `combat/init.lua` already split in Phase 1. Trigger `engine-code-review` skill before shipping. |
| R-7 | **Spider web — new creature-created object pattern** | Med | High | First runtime-spawned object (not in room files). Prototype in isolation BEFORE WAVE-2. Dedicated test: tick → web in room → valid GUID → keyword resolves. Fallback: defer web to Phase 3, ship spider with bite-only. |
| R-8 | **Performance: 10 creatures ticking** | Low | High | Spatial optimization from Phase 1 (full-tick player's room only). Benchmark at GATE-2 with 10 creatures across 3 rooms. Budget: <50ms total. Fallback: batch ticks (3 per frame, round-robin). |
| R-9 | **NPC combat narration floods output** | Med | Med | Cap witness narration: 2 lines per exchange (same room), 1 line (adjacent room). Test: 3-creature fight ≤6 lines per round. |
| R-10 | **File conflicts between agents** | Med | High | Explicit file ownership per wave. `git diff --stat` verification after each agent. Phase 2 has more creature files — wave assignments must be granular. |
| R-11 | **Phase 1 test regression** | Low | Critical | `lua test/run-tests.lua` at every gate. Phase 1 count is baseline — any decrease is a blocker. |
| R-12 | **Disease + injury FSM interaction** | Med | Med | Both use `injuries.inflict()`. Test: player with wound AND rabies — verify independent ticking, independent healing. |

---

## Section 11: Autonomous Execution Protocol

### Coordinator Execution Loop

```
FOR each WAVE in [WAVE-0 through WAVE-5]:

  1. PRE-WAVE: Verify previous gate passed. Read plan status tracker.

  2. SPAWN parallel agents per wave table.
     - Each agent: task, exact files, TDD reqs. No file overlap. Max 4 agents.

  3. COLLECT results. Verify: files match spec, no unintended changes (git diff --stat).

  4. RUN gate tests:
     a. lua test/run-tests.lua           (zero regressions)
     b. Wave-specific new test files      (all pass)
     c. LLM walkthrough (GATE-3, GATE-5)
     d. Doc existence (GATE-1, GATE-3, GATE-4, GATE-5)
     e. Performance benchmark (GATE-2)

  5. EVALUATE:
     PASS → git tag phase2-gate-N → commit → push → status ✅ → next wave
     FAIL → Gate Failure Protocol (Section 12)

  6. WAVE CHECKPOINT (Section 13)
```

### Commit & Tag Pattern

Commit per gate: `PHASE-2 GATE-N: {description}` with Co-authored-by trailer.
Git tag per gate: `phase2-gate-1` through `phase2-gate-5` for rollback.

### Parallel Agent Constraints

- Max 4 agents per wave, all start simultaneously
- No agent starts until previous GATE passes
- Early-finishing agents do NOT start next wave's work
- Multiple Nelson/Flanders instances OK if writing different files

### Nelson Continuous LLM Testing

| When | Type | Scope |
|------|------|-------|
| After every wave | Smoke (~5 cmds) | Boot + basic interaction + no crash |
| GATE-1 | Unit only | Creature defs load and validate |
| GATE-3 | Full walkthrough | NPC-vs-NPC combat, witness narration, intervention |
| GATE-4 | Disease scenarios | Rabies incubation, venom delivery, dual injury |
| GATE-5 | Food walkthrough | Eat/drink, hunger satisfaction |
| Between waves | Exploratory | Edge cases, darkness, multi-creature rooms |

All runs: `--headless` + `math.randomseed(42)`.

### CBG Design Review

| Gate | Focus |
|------|-------|
| GATE-1 | Creature distinctness, sensory vividness |
| GATE-3 | NPC combat feel, witness narration atmosphere |
| GATE-4 | Disease discoverability, fairness |
| GATE-5 | Food naturalness, PoC minimality |

Design debt → `.squad/decisions/inbox/cbg-design-debt-phase2-WAVE-N.md`.

### Wayne Check-In Points

1. **GATE-3** — witness cat-kills-rat scenario
2. **GATE-5** — play-test disease + food
3. **Any escalation** from 1x-failure rule

---

## Section 12: Gate Failure Protocol

### Failure Handling

**Step 1 — First failure:**
- File GitHub issue: gate ID, failed test(s), full error output, implicated file/agent, `git diff`
- Assign fix to file owner. Re-gate failed items only (not full suite).
- **Escalate to Wayne** with diagnostic summary (1x threshold — inherited from Phase 1)

**Step 2 — Second failure (same test):**
- Escalate to Wayne: original failure + fix attempt + second failure + Bart's assessment
- Wayne decides: different agent, redesign, or defer

### Re-gating Rules

- Re-gate tests ONLY failed items. Passing tests not re-run.
- After fix: run failing test file in isolation, then `lua test/run-tests.lua` for regressions.
- Pass → next wave. Fail → Step 2.

### Lockout Policy

Agent fails twice on same issue → locked out. Fresh agent (or Bart for architecture) takes over.

### Phase 2-Specific Escalation

| Condition | Action |
|-----------|--------|
| Gate fails 1x | File issue → fix → re-gate → **escalate Wayne** |
| Unexpected file changes | Reject, re-run. Repeated → lock out agent |
| Phase 1 test regression | **STOP all work.** Fix first. |
| Phase 2 prior-wave regression | Stop current wave. Fix before continuing. |
| LLM fails, unit passes | Integration gap — Bart diagnoses |
| Perf >50ms creature tick | Bart profiles → spatial opt → batch ticks |
| Disease causes injury regression | Isolate, roll back disease changes |
| Spider web fails | Defer web to Phase 3, ship bite-only spider |
| NPC combat infinite loop | Apply cascade cap (R-1). Still loops → pairwise-only |
| Food exceeds scope | Cut to 1 food object + eat verb only |
| Missing docs at gate | Block gate. Assign Brockman. |

### Rollback

Git tags per gate. Revert to `phase2-gate-(N-1)` if needed. Never roll back >2 waves without Wayne.

---

## Section 13: Wave Checkpoint Protocol

### After Every Wave Completes

**1. Verify Completion** — All files from wave table exist, content spot-checked, `git diff --stat` matches, no TODO/FIXME left.

**2. Update Plan Status Tracker**
```
| WAVE-0 | ✅ | WAVE-1 | ✅ | WAVE-2 | 🟡 | WAVE-3–5 | ⏳ |
```

**3. Record Deviations** — What changed, why, impact on future waves.

**4. Capture Test Baseline** — Exact counts per wave. Any decrease = blocker.

**5. Architecture Health Check (Bart)**
- [ ] No module >500 LOC
- [ ] Public API contracts frozen for dependent waves
- [ ] Debug hooks in new engine code
- [ ] Performance baseline measured
- [ ] Consistent error handling
- [ ] No object-specific logic in engine (Principle 8)

**6. Commit + Push** — `PHASE-2 WAVE-N CHECKPOINT: {summary}`

**7. Session Continuity** — Session dies mid-wave → next session reads status tracker, resumes from last complete wave. Partial wave = re-run entirely (`git checkout .`).

### Post-Phase 2 Retrospective

After all waves: actual vs estimated scope, gate failures, new risks, performance actuals, candidate skill patterns, Phase 3 recommendations.

---

## Section 14: Documentation Deliverables

### Per-Gate Documentation Requirements

Documentation is a gate requirement — no gate ships without its docs. Brockman runs in parallel with Nelson's testing.

### New Documents

| Gate | Document | Path |
|------|----------|------|
| GATE-1 | Creature Variety Patterns | `docs/architecture/objects/creature-variety.md` |
| GATE-3 | NPC-vs-NPC Combat | `docs/architecture/combat/npc-combat.md` |
| GATE-4 | Disease System | `docs/architecture/engine/disease-system.md` |
| GATE-5 | Food System PoC | `docs/design/food-system.md` |

**GATE-1 — creature-variety.md:** Template inheritance, behavior profiles, drive tuning, combat metadata scaling. Reference: rat, cat, spider, wolf.

**GATE-3 — npc-combat.md:** Unified combatant interface, predator-prey triggers, pairwise resolution, turn order, witness narration, player intervention, cascade limits.

**GATE-4 — disease-system.md:** Disease as injury type, `on_hit` delivery, probability transmission, incubation FSM, cure interactions. Reference: rabies, spider-venom.

**GATE-5 — food-system.md:** PoC scope (eat/drink only), hunger drive integration, food object pattern, deferred features. Cross-ref: `resources/research/food/`.

### Updates to Existing Docs

| Document | Gate | Changes |
|----------|------|---------|
| `creature-system.md` | GATE-1 | Cat/spider/wolf profiles, creature-created objects pattern |
| `combat-fsm.md` | GATE-3 | NPC-vs-NPC exchange flow, multi-combatant turns, cascade limit |
| `stimulus-system.md` | GATE-3 | New stimuli: `predator_detected`, `prey_detected`, `creature_combat` |
| `object-design-patterns.md` | GATE-1 | Creature-created objects, dynamic GUID generation |
| `player-model.md` | GATE-5 | Hunger drive, food consumption effects |

### Standards

- Architecture/ vs design/ separation (D-BROCKMAN001)
- Brockman writes from implemented code, not plan specs
- Bart reviews for technical accuracy before gate sign-off
- Coordinator verifies: doc exists, non-empty, correct file path references
