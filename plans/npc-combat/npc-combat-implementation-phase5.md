# NPC + Combat Phase 5 Implementation Plan

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-28  
**Version:** v1.0 (Skeleton — Chunk 1/5)  
**Status:** 🟡 IN PROGRESS — Chunk 1 of 5 complete  
**Requested By:** Wayne "Effe" Berry  
**Governs:** Phase 5: Level 2 Expansion → Werewolf NPC → Pack Coordination → Salt Preservation → Integration  
**Predecessor:** `plans/npc-combat/npc-combat-implementation-phase4.md` (Phase 4 — ✅ COMPLETE, 223 tests)  
**Reviewers:** [TBD — pending full plan completion]

---

## Wave Status Tracker

| Wave | Name | Status | Gate | Tests |
|------|------|--------|------|-------|
| PRE-WAVE | Bug Triage + Level 2 Design Sketch | ⏳ Pending | — | 223 |
| WAVE-1 | Level 2 Foundation (7 Rooms + Creatures) | ⏳ Pending | GATE-1 | TBD |
| WAVE-2 | Pack Role System (Simplified Coordination) | ⏳ Pending | GATE-2 | TBD |
| WAVE-3 | Salt Preservation System | ⏳ Pending | GATE-3 | TBD |
| WAVE-4 | Integration + Polish + Docs | ⏳ Pending | GATE-4 | TBD |

---

## Section 1: Executive Summary

Phase 5 expands the world vertically and horizontally — **Level 2 geography** unlocks the deeper dungeon, **werewolf NPCs** introduce a new creature intelligence tier, **pack tactics** escalate wolf coordination to full role-based behavior, and **salt preservation** closes the resource sustainability loop. This is the ecosystem expansion phase.

### What We're Building

1. **Level 2 foundation** — 7 new rooms forming the deep dungeon's first zone. Brass key (from Level 1 finale) unlocks access. New biomes: catacombs, underground streams, collapsed cellars. New creature habitats: werewolf lair, wolf pack territories, spider nests.

2. **Werewolf as NPC type** — Wayne's Q1 decision: **Option B** (separate creature, not disease model). Werewolves are semi-intelligent territorial NPCs with enhanced combat stats, patrol behavior, and future dialogue hooks (Phase 6 scaffold only). Distinct from wolves — they are their own creature class.

3. **Pack role system (simplified)** — Wayne's Q4 decision: **Option A** (stagger attacks, alpha by health). Wolves coordinate attacks with turn-taking, alpha selection by highest HP, and basic reserve conditions (omega retreats if wounded). Zone-targeting deferred to Phase 6.

4. **Salt preservation** — Wayne's Q2 decision: **Option A** (salt-only, ~80 LOC). New `salt` verb, salt object, salted-meat mutation pipeline. Salted meat spoils 3× slower than fresh. Enables sustainable food storage for deep dungeon exploration.

5. **Integration + polish** — Final LLM walkthrough (brass key → Level 2 transition → new creature encounters → butcher → salt meat → rest safely), design documentation (Level 2 ecology, pack tactics v2, preservation economics), and regression testing.

### Why This Order

**Level 2 geography must exist first** (PRE-WAVE + WAVE-1) — everything else depends on it. Pack tactics require wolf placement in Level 2 territories (WAVE-2), salt preservation needs new food sources from Level 2 creatures (WAVE-3), and integration tests the full flow (WAVE-4). The strict dependency chain prevents rework.

### Phase 5 Theme: "Ecosystem Expansion"

- **Phase 3 theme:** "Creatures die and become useful"
- **Phase 4 theme:** "Resources flow through the crafting pipeline"
- **Phase 5 theme:** "The dungeon deepens, packs coordinate, survival requires planning"

The narrative arc: Player completes Level 1 → unlocks brass-key door → descends to Level 2 catacombs → encounters werewolf (territorial, dangerous) → witnesses coordinated wolf pack attacks → learns that food spoils fast in the deeper dungeon → salts meat for long-term storage → prepares for extended exploration.

### Scope Decisions Applied (Wayne's Q1-Q7)

| Question | Wayne's Decision | Impact on Phase 5 |
|----------|------------------|-------------------|
| Q1: Werewolf design | **Option B** (NPC type) | Werewolf is separate creature definition, not disease. Simplifies WAVE-1. |
| Q2: Preservation scope | **Option A** (salt-only) | One verb, one object, mutation pipeline. ~80 LOC total. WAVE-3 stays lean. |
| Q3: Humanoid NPCs | **Option C** (defer to Phase 6) | No dialogue framework, no memory system. Phase 5 stays creature-focused. |
| Q4: Pack roles | **Option A** (simplified) | Stagger attacks, alpha by health. No zone-targeting. ~150 LOC. |
| Q5: A* pathfinding | **Option B** (defer) | Keep random-exit selection. Phase 6+ feature. |
| Q6: Environmental combat | **Option B** (defer) | Push/throw/climb deferred to Combat Phase 3. |
| Q7: Portal refactoring | **Removed from scope** | Lisa's TDD work (#203-208) tracked independently. |

### Phase 4 Foundation (Already Built)

| Asset | Location | LOC |
|-------|----------|-----|
| Butchery system | `src/engine/verbs/butchery.lua` | ~120 |
| Loot tables engine | `src/engine/creatures/loot.lua` | ~180 |
| Stress injury | `src/meta/injuries/stress.lua` | ~90 |
| Spider web creation | `src/engine/creatures/actions.lua` (create_object) | ~60 |
| Silk crafting | `src/engine/verbs/crafting.lua` (extensions) | ~50 |
| Pack tactics v1 | `src/engine/creatures/pack.lua` | ~150 |
| 5 creatures | `src/meta/creatures/{rat,cat,wolf,spider,bat}.lua` | — |
| 10 injury types | `src/meta/injuries/` | — |
| ~223 tests passing | `test/` | — |

### Walk-Away Capability

Same protocol as Phase 1-4: wave → parallel agents → gate → pass → checkpoint → next wave. Gate failure at 1× threshold (escalate to Wayne immediately). Commit/push after every gate. Nelson continuous LLM walkthroughs.

---

## Section 2: Quick Reference Table

| Wave | Name | Parallel Tracks | Gate | Key Deliverables |
|------|------|-----------------|------|------------------|
| **PRE-WAVE** | Bug Triage + Level 2 Design Sketch | 4 tracks | — | 3 wiring bugs fixed (silk, craft, brass-key), Level 2 geography sketch (7 rooms), werewolf design spec, preservation design spec |
| **WAVE-1** | Level 2 Foundation (7 Rooms + Creatures) | 5 tracks | GATE-1 | 7 room definitions (catacombs, underground stream, werewolf lair, collapsed cellar, wolf territory, spider nest, storage room), werewolf.lua creature, brass-key transition wiring, Level 2 creature placement |
| **WAVE-2** | Pack Role System (Simplified Coordination) | 4 tracks | GATE-2 | Pack coordination engine (stagger attacks), alpha selection (highest HP), omega reserve (retreat if wounded), wolf metadata updates (pack_role field), territory expansion |
| **WAVE-3** | Salt Preservation System | 4 tracks | GATE-3 | `salt` verb handler, salt.lua object, salted-meat mutations (wolf-meat → salted-wolf-meat), FSM spoilage rate updates (3× slower for salted), tool requirement (container) |
| **WAVE-4** | Integration + Polish + Docs | 4 tracks | GATE-4 | Final LLM walkthrough (L1 → L2 full flow), design docs (level2-ecology.md, pack-tactics-v2.md, preservation-system.md), regression testing (ZERO failures vs Phase 4 baseline), Phase 5 checkpoint |

**Estimated new files:** ~25-30 (code + tests) + 3-4 doc files  
**Estimated modified files:** ~20-25 (engine modules, verbs, creature files, room definitions, test runner)  
**Estimated scope:** 5 waves (PRE-WAVE + WAVE-1 through WAVE-4), 4 gates (GATE-1 through GATE-4)  
**Test target:** 270+ passing tests (Phase 4 baseline: 223; Phase 5 adds ~50+ new tests)

---

## Section 3: Dependency Graph

```
PRE-WAVE: Bug Triage + Level 2 Design Sketch
├── [Nelson]   Fix 3 wiring bugs (silk disambiguation, craft recipe, brass key/padlock)
├── [Moe]      Level 2 geography sketch (7 rooms, exits, placement)
├── [Bart]     Werewolf design spec (stats, behavior, territorial AI)
└── [Bart]     Preservation design spec (salt mutation pipeline, spoilage rates)
        │
        ▼  ── (no formal gate — PRE-WAVE is setup for WAVE-1) ──
        │
WAVE-1: Level 2 Foundation (7 Rooms + Creatures)
├── [Moe]      7 room definitions (catacombs, stream, lair, cellar, territory, nest, storage) ┐
├── [Flanders] werewolf.lua creature (combat stats, patrol behavior, territorial AI)           │
├── [Flanders] Brass key object update (unlocks → deep-cellar-hallway door)                    │ parallel
├── [Bart]     Brass key transition logic (Level 1 end → Level 2 start)                        │
├── [Nelson]   Level 2 instantiation tests (all rooms load, exits route, creatures spawn)      │
└── [Smithers] Room presence updates for Level 2 objects                                        ┘
        │
        ▼  ── GATE-1 (Level 2 fully instantiable, brass key unlocks L2, werewolf exists, ZERO regressions) ──
        │
WAVE-2: Pack Role System (Simplified Coordination)
├── [Bart]     Pack coordination engine (stagger attacks, alpha selection, omega reserve)      ┐
├── [Flanders] Wolf metadata updates (pack_role field: alpha/beta/omega)                       │ parallel
├── [Bart]     Territory expansion (wolf pack zones in Level 2)                                │
├── [Nelson]   Pack tactics tests (stagger behavior, alpha selection, omega retreat)           │
└── [Smithers] Pack narration updates (combat text for coordinated attacks)                    ┘
        │
        ▼  ── GATE-2 (wolves coordinate attacks, alpha/omega roles work, ZERO regressions) ──
        │
WAVE-3: Salt Preservation System
├── [Smithers] `salt` verb handler + aliases                                                   ┐
├── [Flanders] salt.lua object (small-item, consumable, preservative capability)               │ parallel
├── [Flanders] Salted-meat mutations (wolf-meat → salted-wolf-meat, etc.)                      │
├── [Bart]     FSM spoilage rate updates (salted = 3× slower decay)                            │
├── [Nelson]   Preservation tests (salt verb, mutations, spoilage rates, tool requirements)    │
└── [Smithers] Preservation narration (salting process, salted-meat descriptions)              ┘
        │
        ▼  ── GATE-3 (salt verb works, salted meat lasts longer, ZERO regressions) ──
        │
WAVE-4: Integration + Polish + Docs
├── [Nelson]   Final LLM walkthrough (brass key → L2 → werewolf → pack → butcher → salt)      ┐
├── [Brockman] Design docs (level2-ecology.md, pack-tactics-v2.md, preservation-system.md)     │ parallel
├── [Bart]     Regression testing (full test suite vs Phase 4 baseline)                        │
├── [Scribe]   Phase 5 checkpoint (orchestration log, decision merge, status update)           │
└── [Nelson]   Test flakiness audit (document any non-deterministic tests)                     ┘
        │
        ▼  ── GATE-4 (Phase 5 COMPLETE — full feature set verified, docs complete, ZERO regressions) ──
        │
        ═══ PHASE 5 COMPLETE ═══
```

### Key Dependency Chain

```
Phase 4 ──→ PRE-WAVE (bugs + design) ──→ W1 (Level 2 foundation) ──┐
                                              │                      │
                                              ├─────→ W2 (pack) ────┤
                                              │                      │
                                              ├─────→ W3 (salt) ─────┤
                                              │                      │
                                              └──────────────────────┴──→ W4 (integration + docs)
```

**Hard blockers:**
- PRE-WAVE must complete before WAVE-1 (bug fixes prevent test pollution)
- WAVE-1 must complete before WAVE-2 and WAVE-3 (Level 2 geography is prerequisite)
- WAVE-2 and WAVE-3 can run in parallel (no file overlap)
- WAVE-4 requires WAVE-1, WAVE-2, and WAVE-3 all complete (integration testing)

**Parallelization opportunities:**
- PRE-WAVE: Nelson, Moe, Bart all work independently (different files)
- WAVE-1: 5-6 parallel tracks (rooms, creatures, objects, tests, room presence)
- WAVE-2 and WAVE-3: Can run simultaneously after WAVE-1 (independent subsystems)
- WAVE-4: 4-5 parallel tracks (testing, docs, regression, checkpoint)

---

**END OF CHUNK 1 (SKELETON)**

---

*Next chunks:*
- **Chunk 2:** Implementation Waves (detailed task breakdowns for each wave)
- **Chunk 3:** Testing Gates + Nelson LLM Scenarios + TDD Test File Map
- **Chunk 4:** Feature Breakdown (Level 2 rooms, werewolf spec, pack system, preservation)
- **Chunk 5:** Risk Register + Autonomous Execution Protocol + Documentation Deliverables

*Plan authored by Bart (Architecture Lead). Chunk 1/5 — skeleton structure complete.*
