# NPC + Combat Phase 2 — Implementation Plan (Skeleton)

**Author:** Bart (Architect)  
**Date:** 2026-07-30  
**Status:** Chunk 1 of 5 — Skeleton  
**Requested By:** Wayne "Effe" Berry  
**Governs:** Phase 2: Creature Generalization → NPC Combat → Disease → Food PoC  
**Predecessor:** `plans/npc-combat-implementation-phase1.md` (Phase 1 — complete)

---

## Wave Status Tracker

| Wave | Status |
|------|--------|
| WAVE-0 | ⏳ |
| WAVE-1 | ⏳ |
| WAVE-2 | ⏳ |
| WAVE-3 | ⏳ |
| WAVE-4 | ⏳ |
| WAVE-5 | ⏳ |

---

## Section 1: Executive Summary

Phase 2 extends the NPC + Combat foundation shipped in Phase 1 (creature engine 421 LOC, combat FSM 435 LOC, 14 test files, 176 total test files) into a generalized creature ecosystem with inter-NPC combat, disease mechanics, and a food proof-of-concept.

### What We're Building

1. **New creatures** — cat, wolf, spider, bat with body_tree + combat metadata. Spider introduces chitin material.
2. **Creature generalization** — inter-creature reactions (cat chases rat), territorial behavior, NPC stimulus emission. Deferred `attack` action enters Combat FSM.
3. **NPC-vs-NPC combat** — unified combatant interface, combat witness narration, multi-combatant turn order (3+), creature morale/flee.
4. **Disease system** — generic `on_hit` disease delivery. Rabies (rat, 15% chance, incubation → death). Spider venom (100%).
5. **Food PoC** — cheese + bread, food-as-bait (rat hunger + food = lure), eat/drink verb extensions. Minimal scope.

### Why This Order

Strict dependency chain: creatures must exist (WAVE-1) before they can behave (WAVE-2), behave before they can fight each other (WAVE-3), fight before diseases can be delivered via hits (WAVE-4), and food/bait leverages creature drives from WAVE-1/2 (WAVE-5). WAVE-0 clears the runway with engine code review — Phase 1 bugs (#275-278, #264) already fixed, portal TDD (#199-208) burns down in parallel.

### Phase 1 Foundation

| Asset | Location | LOC |
|-------|----------|-----|
| Creature engine | `src/engine/creatures/init.lua` | 421 |
| Combat FSM | `src/engine/combat/init.lua` | 435 |
| Combat narration | `src/engine/combat/narration.lua` | 146 |
| Creature + combat tests | `test/creatures/` + `test/combat/` | 14 files |
| Rat + 7 injury types | `src/meta/creatures/rat.lua`, `src/meta/injuries/` | — |

### Walk-Away Capability

Same protocol as Phase 1: wave → parallel agents → gate → pass → checkpoint → next wave. Gate failure at 1× threshold. Commit/push after every gate. Nelson continuous LLM walkthroughs.

---

## Section 2: Quick Reference Table

| Wave | Name | Parallel Tracks | Gate | Key Deliverables |
|------|------|-----------------|------|------------------|
| **WAVE-0** | Pre-Flight (Review + Cleanup) | 1-2 tracks | — | Engine code review (creatures + combat LOC check), verify Phase 1 bug fixes closed |
| **WAVE-1** | Creature Data (New Creatures) | 4-5 tracks | GATE-1 | cat.lua, wolf.lua, spider.lua, bat.lua, chitin.lua material, test scaffolding |
| **WAVE-2** | Creature Generalization (Behavior) | 3-4 tracks | GATE-2 | creature `attack` → Combat FSM, creature-to-creature reactions, territorial behavior, NPC stimulus emission, predator-prey metadata |
| **WAVE-3** | NPC Combat Integration | 3-4 tracks | GATE-3 | NPC-vs-NPC combat (unified combatant interface), combat witness narration, multi-combatant turn order, creature morale/flee |
| **WAVE-4** | Disease System | 3 tracks | GATE-4 | Generic on_hit disease delivery, rabies injury type, spider venom injury type, injury system integration |
| **WAVE-5** | Food PoC + Polish | 3 tracks | GATE-5 | cheese.lua, bread.lua, food-as-bait mechanic, eat/drink verb extensions, Nelson final LLM walkthrough, Brockman Phase 2 docs |

**Estimated new files:** ~20-25 (code + tests) + 6-8 doc files  
**Estimated modified files:** ~12-15 (engine modules, verbs, test runner)  
**Estimated scope:** 6 waves (WAVE-0 through WAVE-5), 5 gates

---

## Section 3: Dependency Graph

```
WAVE-0: Pre-Flight (Review + Cleanup)
├── [Bart]     Engine code review (creatures 421 LOC, combat 435 LOC)
└── [Nelson]   Verify Phase 1 bug fixes (#275-278, #264)
        │
        ▼  ── (no formal gate — review findings filed, bugs confirmed) ──
        │
WAVE-1: Creature Data (New Creatures)
├── [Flanders] cat.lua, wolf.lua, spider.lua, bat.lua ┐
├── [Flanders] chitin.lua material                     │ parallel
└── [Nelson]   test/creatures/ scaffolding             ┘
        │
        ▼  ── GATE-1 (creatures load, body_tree resolves, chitin registered) ──
        │
WAVE-2: Creature Generalization (Behavior)
├── [Bart]     creatures/init.lua: attack → Combat FSM,┐
│              reactions, territorial, predator-prey    │ parallel
├── [Bart]     NPC stimulus emission points             │
├── [Nelson]   behavior tests + smoke LLM              ┘
        │
        ▼  ── GATE-2 (reactions fire, territory works, stimulus propagates) ──
        │
WAVE-3: NPC Combat Integration
├── [Bart]     combat/init.lua: unified combatant,     ┐
│              NPC-vs-NPC, multi-combatant turn order   │
├── [Bart]     creature morale + flee                   │ parallel
├── [Smithers] combat witness narration                 │
├── [Nelson]   NPC combat tests + LLM walkthrough      ┘
        │
        ▼  ── GATE-3 (NPC combat resolves, witness narration, morale/flee) ──
        │
        │  ═══ NPC COMBAT SHIPS (Brockman docs parallel) ═══
        │
WAVE-4: Disease System
├── [Bart]     Generic on_hit disease delivery         ┐
├── [Flanders] rabies.lua (15%, incubation → death)    │ parallel
├── [Flanders] spider-venom.lua (100% on hit)          │
└── [Nelson]   disease tests                           ┘
        │
        ▼  ── GATE-4 (disease fires on hit, rabies timeline, venom applies) ──
        │
WAVE-5: Food PoC + Polish
├── [Flanders] cheese.lua + bread.lua                  ┐
├── [Bart]     food-as-bait (hunger drive + stimulus)  │ parallel
├── [Smithers] eat/drink verb extensions               │
├── [Brockman] Phase 2 docs (4 architecture files)     │
└── [Nelson]   final LLM walkthrough                   ┘
        │
        ▼  ── GATE-5 (food works, bait lures, docs complete, ZERO regressions) ──
        │
        ═══ PHASE 2 COMPLETE ═══
```

### Key Dependency Chain

```
Phase 1 ──→ W0 (review) ──→ W1 (data) ──→ W2 (behavior) ──→ W3 (NPC combat)
                                                                    │
                                                        ┌───────────┤
                                                        ▼           ▼
                                                  W4 (disease)  W5 (food)
                                                        └─────┬─────┘
                                                              ▼
                                                    GATE-5 (Phase 2 done)
```

Portal TDD (#199-208) burns down in parallel — not blocking Phase 2 waves.

### File Ownership Constraints

No two agents touch the same file in any wave. Key ownership:

| File | Owner | Waves |
|------|-------|-------|
| `src/engine/creatures/init.lua` | Bart | WAVE-2 |
| `src/engine/combat/init.lua` | Bart | WAVE-3 |
| `src/engine/combat/narration.lua` | Smithers | WAVE-3 |
| `src/meta/creatures/*.lua` (new) | Flanders | WAVE-1 |
| `src/meta/injuries/*.lua` (new) | Flanders | WAVE-4 |
| `src/engine/verbs/init.lua` | Smithers | WAVE-5 |
| `test/creatures/*.lua` (new) | Nelson | WAVE-1, WAVE-2 |
| `test/combat/*.lua` (new) | Nelson | WAVE-3 |
| `test/injuries/*.lua` (new) | Nelson | WAVE-4 |

---

*Chunk 1 complete. Chunks 2-5 will add: Implementation Waves (detailed), Testing Gates, Feature Breakdown, and Operations.*
