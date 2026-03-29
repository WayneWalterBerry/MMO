# NPC Combat — Board

**Owner:** 📊 Kirk (PM coordination) + 🏗️ Bart (Architecture lead) + 🌿 Flanders (Creatures lead)
**Last Updated:** 2026-04-02
**Overall Status:** 🟢 Active — Phase 5 (Creature Intelligence Escalation)

---

## Next Steps (Prioritized)

| Priority | Task | Owner | Status | Gate |
|----------|------|-------|--------|------|
| **P0** | PRE-WAVE: GUID pre-assignment for 12+ new objects | Flanders | ⏳ Pending | Unblock WAVE-1 |
| **P0** | PRE-WAVE: Level 2 room sensory specs (7 rooms) | Moe | ⏳ Pending | Unblock WAVE-1 |
| **P0** | PRE-WAVE: Preserve/cure verb alias collision audit | Smithers | ⏳ Pending | Unblock WAVE-1 |
| **P1** | WAVE-1: Implement 7 Level 2 rooms + werewolf creature | Moe, Flanders | ⏳ Pending | GATE-WAVE1 |
| **P1** | WAVE-1: Brass key transition mechanics | Bart | ⏳ Pending | GATE-WAVE1 |
| **P2** | WAVE-2: Pack tactics v1.1 (alpha/stagger/omega) | Bart, Smithers | ⏳ Pending | GATE-WAVE2 |
| **P2** | WAVE-3: Salt preservation verb + salted-meat mutation | Smithers, Flanders | ⏳ Pending | GATE-WAVE3 |

---

## Priority Status

| Project | Tier | Status | Notes |
|---------|------|--------|-------|
| **NPC Combat (Phase 5)** | **🔴 T4 (ACTIVE)** | 🟢 Ready to start | Elevated from background; all decisions locked; PRE-WAVE tasks in flight |
| Worlds | T0 | 🟢 Planning | Gate-0 |
| Sound | T1 | 🟢 Wave-0 complete | Review cycles done |
| Food Implementation | T2 | 🟡 In progress | Final integration |
| Testing Infrastructure | T3 | 🟢 Steady state | Baseline maintained |
| Level 2 | Background | 🟡 Planning | Depends on Phase 5 creature engine |
| Parser Improvements | Background | 🟢 Phase 3 shipped | MaxSim pending |

---

## Phase History

| Phase | Status | Scope | Key Deliverable |
|-------|--------|-------|-----------------|
| Phase 1 | ✅ Complete | Rat creature, basic NPC tick loop | First animate object |
| Phase 2 | ✅ Complete | Cat, bat, multi-creature rooms | Creature coexistence |
| Phase 3 | ✅ Complete | Combat system, body zones, weapons | Hit/damage/death pipeline |
| Phase 4 | ✅ Complete | Loot, butchery, stress, pack tactics v1, territory | Crafting loop closed |
| **Phase 5** | 🟢 **ACTIVE v2.0** | Level 2, werewolf, salt preservation, pack v1.1 | Ecosystem expansion |

---

## Phase 5 — Current Status

**Plan:** `projects/npc-combat/npc-combat-implementation-phase5.md` (v2.0, 68KB)
**Decisions:** Q1-Q7 resolved, 17 reviewer fixes applied

### Waves

| Wave | Status | Scope | Key Agents |
|------|--------|-------|------------|
| PRE-WAVE | ⏳ Pending | Bug fixes, L2 design, GUID reservation, alias audit | Bart, Moe, Flanders, Smithers |
| WAVE-1 | ⏳ Pending | 7 Level 2 rooms, werewolf, brass key transition | Moe, Willie, Bart, Nelson |
| WAVE-2 | ⏳ Pending | Pack tactics v1.1 (alpha/stagger/omega 30%) | Bart, Willie, Smithers, Nelson |
| WAVE-3 | ⏳ Pending | Salt preservation (salt verb + salted-meat mutation) | Smithers, Flanders, Bart, Nelson |
| WAVE-4 | ⏳ Pending | Integration, LLM walkthrough, docs, polish | Nelson, Brockman, Scribe |

### PRE-WAVE Tasks (6 items before WAVE-1)

| Task | Owner | Status |
|------|-------|--------|
| GUID pre-assignment for 12+ new objects | Flanders | ⏳ |
| Level 2 room sensory specs (7 rooms) | Moe | ⏳ |
| Omega retreat threshold → 30% (standardized) | ✅ Done in plan | ✅ |
| Spoilage: objects declare FSM `duration` directly | ✅ Done in plan | ✅ |
| Preserve/cure verb alias collision audit | Smithers | ⏳ |
| Embedding index update moved to GATE-1 | ✅ Done in plan | ✅ |

### Wayne's Decisions (Q1-Q7)

| Q | Decision | Choice |
|---|----------|--------|
| Q1 | Werewolf | **B: NPC type** (separate creature, not disease) |
| Q2 | Preservation | **A: Salt-only** (~80 LOC) |
| Q3 | Humanoid NPCs | **C: Defer** to Phase 6 |
| Q4 | Pack Roles | **A: Simplified** (stagger, alpha by health) |
| Q5 | A* Pathfinding | **B: Defer** |
| Q6 | Environmental Combat | **B: Defer** |
| Q7 | Portal Refactoring | **Removed** from Phase 5 scope |

---

## Team Review (7/7 Complete)

| Reviewer | Verdict | Key Finding |
|----------|---------|-------------|
| 🎮 CBG | ✅ Approved | Pack narration needs visual distinction |
| 🏗️ Bart | ✅ Approved | Spoilage multiplier → Principle 8 clarification |
| 🧪 Nelson | 🟡 Ready | 7 concerns (omega threshold, LLM gaps) — all fixed in v2.0 |
| 🏠 Marge | 🟡 Conditional | Flaky quarantine, log format, reviewer roles — all fixed in v2.0 |
| 🏗️ Moe | ⚠️ Concerns | Room sensory specs → PRE-WAVE task added |
| ⚛️ Smithers | ✅ Approved | Embedding timing moved to GATE-1 |
| 🔨 Flanders | ✅ Approved | GUID pre-assignment → PRE-WAVE task added |

**Skill audit (Chalmers):** 81% compliance → 17 fixes applied → v2.0

---

## Ownership (Phase 5)

| Domain | Owner | Scope |
|--------|-------|-------|
| Engine (pack tactics, FSM, loot) | Bart | `src/engine/` only |
| Level 2 rooms + level definition | Moe | `src/meta/world/`, `src/meta/levels/` |
| Werewolf + Level 2 creatures | Willie | `src/meta/creatures/` |
| Objects (salt, salted-meat, loot items) | Flanders | `src/meta/objects/`, templates, materials |
| Salt verb, pack narration, embedding | Smithers | `src/engine/parser/`, `src/engine/verbs/` |
| Tests (all waves) | Nelson | `test/` |
| Docs (after GATE-2, GATE-3, GATE-4) | Brockman | `docs/` |
| Linting (run before commit) | Wiggum | `scripts/meta-lint/` |

---

## Artifacts

| File | Purpose |
|------|---------|
| `npc-combat-implementation-phase5.md` | v2.0 assembled plan (68KB, 1204 lines) |
| `phase5-planning-draft.md` | Chalmers' original planning draft |
| `phase5-skill-audit.md` | Chalmers' 16-pattern compliance audit |
| `phase5-review-*.md` | 7 reviewer reports (CBG, Bart, Nelson, Marge, Moe, Smithers, Flanders) |
| `phase4-post-mortem.md` | Phase 4 lessons learned |
| `npc-combat-implementation-phase{1-4}.md` | Prior phase plans (reference) |
| `npc-system-design.md` | NPC system design |
| `combat-system-design.md` | Combat system design |
| `creature-inventory-design.md` | Creature inventory design |

---

## Phase 6 Preview (Deferred)

| Feature | Est. Phase |
|---------|-----------|
| Humanoid NPC full system (dialogue, memory, quests) | 6b |
| A* pathfinding | 6a |
| Environmental combat (push, throw, climb) | 6a |
| Full preservation (smoking, drying, root cellar) | 6c |
| Zone-targeting pack tactics | 6a |
| Creature-to-creature looting | 6a |

---

*Board maintained by Coordinator. Update after each wave/gate.*
