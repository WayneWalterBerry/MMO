# NPC + Combat Phase 5 Planning Draft

**Author:** Chalmers (Project Manager)  
**Date:** 2026-03-28  
**Version:** v0.1 (Draft — awaiting Wayne review)  
**Status:** 🟡 Awaiting Direction  
**Requested By:** Wayne "Effe" Berry  
**Governs:** Phase 5 scope, sequencing, and Level 2 expansion  
**Predecessor:** `plans/npc-combat/npc-combat-implementation-phase4.md` (Phase 4 — ✅ COMPLETE)

---

## Section 1: Phase 5 Theme & Vision

**Proposed Theme:** "Ecosystem Expansion + Creature Intelligence Escalation"

Phase 4 established the **crafting loop**: kill creature → harvest resources → craft items. Phase 5 builds outward on three fronts:

1. **Ecosystem Expansion** — Level 2 rooms (7 new), new creature types (werewolf, humanoid NPCs?), expanded biomes
2. **Creature Intelligence Escalation** — Pack coordination with zone-targeting, omega reserve strategies, smarter predator-prey tactics
3. **Resource System Evolution** — Food preservation (salting, smoking), multi-ingredient crafting, creature-to-creature looting

### Narrative Arc

**Phase 4:** "I killed a wolf. Now I have meat."  
**Phase 5:** "Wolves hunt in coordinated packs across territories. I must preserve food to survive the deeper dungeon."

---

## Section 2: Scope Candidates (Backlog)

### 2.1 Deferrals from Phase 4

Explicitly deferred in Phase 4 plan (§11):

| Feature | Complexity | Est. LOC | Priority |
|---------|-----------|---------|----------|
| **Food preservation** (salting, smoking, drying) | High | 200–300 | P0 |
| **Pack role system: Alpha/Beta/Omega** (full coordination) | Very High | 250–350 | P1 |
| **Zone-targeting for coordinated attacks** | High | 200–250 | P1 |
| **Environmental combat** (push barrel, slam door, climb) | High | 180–220 | P2 |
| **Weapon/armor degradation** (fragility system) | Medium | 100–150 | P3 |
| **Multi-ingredient cooking** (recipe system beyond mutation) | Medium | 120–180 | P2 |
| **Creature-to-creature looting** (AI evaluates loot value) | High | 150–200 | P2 |
| **A* pathfinding** (vs current random-exit selection) | High | 250–300 | P3 |
| **Humanoid NPC stubs** (dialogue framework, memory, quests) | Massive | 400–600 | P1* |
| **Wrestling/grapple verbs** (non-weapon combat) | Medium | 100–150 | P3 |

*Phase 4 of NPC plan, massive scope. Deferred decision: separate phase or Phase 5 Wave?

### 2.2 Open GitHub Issues (Currently 17)

**Injury System (P0):**
- #263: Rabies as injury type (should integrate existing injury-infliction pipeline)
- #262: Werewolf/lycanthropy as injury or disease (transformation mechanic?)
- #261: Stress as injury ✅ **IMPLEMENTED in Phase 4** — ready to close

**Object/Wiring Issues (P0):**
- #265: Wearing clothes requires empty hands + no pocket storage (UX constraint clarification)
- #250: meta-lint GUID-02 — 21 orphan objects (refactoring debt)

**Puzzle 017 (P0 — Assigned to Flanders + Moe):**
- #254: Update deep-cellar.lua room (Moe)
- #255: Create incense-stick.lua object (Flanders)
- #256: Create altar-candle.lua object (Flanders)
- #257: Create stone-alcove.lua object (Flanders)
- #258: Update incense-burner for incense objects (Bart)

**Portal Architecture (Portal Phase 2 — TDD Refactor, Lisa):**
- #203–208: TDD + refactor 6 doors (deep-cellar-hallway, courtyard-kitchen, hallway trio, stairs)

**Legacy Issues (P3–P4):**
- #126: Deep-cellar chain puzzle undefined

### 2.3 Natural Next Steps

From Phase 4 completion and Level 1 playtesting:

| Next Step | Phase | Rationale |
|-----------|-------|-----------|
| **Fix wiring bugs** (silk disambiguation, craft recipe, brass key) | Pre-Wave | Blockers from Phase 4 walkthrough |
| **Upgrade Level 1 ending** (brass-key → Level 2 access) | Wave 0 | Level 2 requires L1 transition |
| **Design Level 2 geography** (7 new rooms, new creatures) | Wave 1 | Prerequisite for expansion |
| **Implement werewolf mechanic** (lycan injury?) | Wave 1–2 | Design direction unclear |
| **Implement rabies properly** | Wave 1 | Currently simplified; Phase 4 used generic injuries |
| **Begin pack role system** (Alpha/Beta placeholder logic) | Wave 2 | Scaffolding for zone-targeting |
| **Design preservation system** | Wave 3–4 | Significant scope; needs design phase |
| **Humanoid NPC stubs** (dialogue, memory hooks) | Wave 5+ | Depends on design direction |

---

## Section 3: Proposed Wave Structure (Draft)

**Note:** This is a rough skeleton. Exact wave boundaries and parallel tracks depend on Wayne's decisions in §5.

### Pre-Wave: Bug Triage & Level 2 Design
- **Agents:** Nelson (QA), Bart (Architecture), Moe (Rooms)
- **Deliverables:**
  - 3 wiring bugs fixed from Phase 4 walkthrough
  - Level 2 geography sketch (7 new rooms, creature placement)
  - Decision: Werewolf mechanic (disease vs curse vs new NPC type?)
  - Decision: Preservation scope (salt-only vs full system?)

### WAVE-1: Level 2 Foundation + Creature Expansion
- **Scope:** 7 new rooms, 2–3 new creature types, werewolf scaffold
- **Parallel Tracks:** Moe (rooms) | Flanders (creatures) | Bart (werewolf FSM stubs)
- **Gate:** Level 2 fully instantiable, no regressions

### WAVE-2: Pack Role System (Alpha/Beta/Omega Framework)
- **Scope:** Extended wolf AI, role-based action scoring, territorial zone expansion
- **Parallel Tracks:** Bart (pack engine) | Flanders (wolf metadata) | Nelson (tests)
- **Gate:** Wolves coordinate in packs, territory overlap detected, no L1 regressions

### WAVE-3: Food Preservation System
- **Scope:** Spoilage FSM enhancements, salt/smoking verbs, preservation state transitions
- **Parallel Tracks:** Smithers (verbs) | Flanders (objects) | Nelson (tests)
- **Gate:** Food lasts longer when salted, spoils realistically, preservation loop closes

### WAVE-4: Humanoid NPC Stubs (if in scope)
- **Scope:** Dialogue framework, memory persistence, simple AI skeleton, quest hooks (non-functional)
- **Parallel Tracks:** Bart (NPC engine) | Smithers (dialogue verbs) | Nelson (tests)
- **Gate:** NPC can be queried, remembers player actions, has non-blocking quest stubs

### WAVE-5: Polish + Docs
- **Scope:** Final walkthrough, design documentation (preservation, pack tactics, Level 2 ecology), artifact cleanup
- **Agents:** Brockman (docs), Nelson (LLM walkthrough), Scribe (checkpoint)
- **Gate:** Full Phase 5 feature list verified, all design docs complete

---

## Section 4: Dependencies & Sequencing

### Hard Blockers

```
PRE-WAVE (bug fixes) ← Must complete before WAVE-1
   ↓
WAVE-1 (Level 2 foundation) ← Prerequisite for WAVE-2 & WAVE-3
   ├→ WAVE-2 (pack tactics) ← Depends on Level 2 wolf placement
   ├→ WAVE-3 (preservation) ← Depends on Level 2 creatures (new food sources)
   └→ WAVE-4 (humanoid NPCs?) ← Can start in parallel or after WAVE-1
       ↓
WAVE-5 (polish + docs)
```

### Design Decisions Block Implementation

- **Werewolf mechanic:** Is it a disease (like rabies), a curse, a humanoid NPC? Affects WAVE-1 scope.
- **Food preservation scope:** Salt-only (simple) vs full (smoking, drying, root cellar)? Affects WAVE-3 LOC budget.
- **Humanoid NPCs:** Separate phase or Phase 5 WAVE-4? Architectural decision.
- **Pack role system:** Simplified (stagger attacks) vs full (zone-targeting, reserve tactics)? Affects WAVE-2 LOC budget.

---

## Section 5: Open Questions for Wayne

Before Phase 5 begins, Wayne must resolve:

### Q1: Werewolf Feature Design

**Options:**

- **A: Disease model** — Werewolf infection as injury type (like rabies). Player contracts it from wolf bite. At specific times (full moon?) or stress levels, player is forced to transform. Transformation grants combat buffs but loses control (auto-attack nearest creature). High complexity; affects injury system + combat.

- **B: NPC type** — Werewolf as separate creature (not wolf mutation). Can appear in Level 2, semi-intelligent, territorial. May have dialogue hooks (future). Simpler than disease model.

- **C: Puzzle element** — Werewolf is a level-specific puzzle/boss, not a general mechanic. Appears once in specific room/context. Minimal scope.

- **D: Defer to Phase 6** — Don't implement yet. Focus Phase 5 on pack tactics, Level 2 foundation, preservation.

**Recommendation:** Option B (NPC type) or Option D (defer). Option A adds significant complexity to injury system mid-phase.

---

### Q2: Food Preservation Scope

**Options:**

- **A: Salt-only (minimal)** — One new verb (`salt`), one new object (salt). Meat + salt → salted-meat (mutation). Salted meat spoils 3× slower. ~80 LOC. Fits WAVE-3 easily.

- **B: Full system (ambitious)** — Salt, smoking (fire + smoke objects), drying (time-based). Root cellar room with preservation shelf. Conditional FSM on food objects (fresh, salting, salted, smoking, smoked, drying, dried). New `preserve` verb with recipe selection. ~250–300 LOC. May require WAVE-3 + WAVE-4.

- **C: Smoking-only** — Intermediate scope. Fire + food → smoked variant. Smoked meat lasts longer, requires proximity to fire. ~120 LOC.

**Recommendation:** Option A (salt-only) for Phase 5. Option B (full system) as Phase 6 expansion. Salt is immediately useful in Level 2, gets preservation into the loop without overloading scope.

---

### Q3: Humanoid NPC In Phase 5?

**Options:**

- **A: Full WAVE-4** — Implement dialogue framework, memory persistence, simple AI, quest stubs (non-blocking). ~400–500 LOC. Requires design phase first. Extends Phase 5 by 1–2 weeks.

- **B: Stubs only** — Create NPC objects (skeleton, innkeeper) with placeholder dialogue. No memory, no AI. ~50–100 LOC. Provides Level 2 visual interest without functionality.

- **C: Defer entirely** — Phase 5 stays creature-focused (pack tactics, preservation). Humanoid NPCs = Phase 6 centerpiece. Keeps Phase 5 focused.

**Recommendation:** Option B or Option C. Option B provides content without overcommitting. Option C keeps Phase 5 lean and delivers deep pack/preservation mechanics instead.

---

### Q4: Pack Role System — Simplified or Full?

**Options:**

- **A: Simplified (Phase 4 v1.1)** — Wolves stagger attacks (take turns). Alpha selected by health. Individual pathfinding. ~150 LOC.

- **B: Zone-targeting (full)** — Alpha assigns attack zones. Beta covers flanks. Omega reserves (flee if wounded). Coordinated movement. Multi-round tactics. ~300–400 LOC. Requires new creature action types + coordinator loop.

- **C: Hybrid** — Add omega reserve conditions (retreat if alpha falls). Keep zone-targeting deferred. ~200 LOC.

**Recommendation:** Option A or C. Option B is substantial scope. If time permits after WAVE-3, Option C (omega reserves) adds depth without architecture overhaul.

---

### Q5: A* Pathfinding — In Phase 5?

**Options:**

- **A: Implement now** — Creatures use A* instead of random-exit selection. Smarter navigation, especially in Level 2 multi-exit rooms. ~250–300 LOC. Requires graph construction at startup.

- **B: Defer** — Keep random-exit selection. Acceptable for V1 prototype. Phase 6+ feature.

**Recommendation:** Option B. Random-exit selection works for L1. Level 2 benefit unclear. Defer unless creature placement in Level 2 creates obvious navigation issues.

---

### Q6: Environmental Combat — In Phase 5?

**Options:**

- **A: Include** — Verbs: `push`, `throw`, `climb`. Objects can be used as combat tools or obstacles. ~200 LOC. Adds tactical depth.

- **B: Defer** — Phase 5 stays NPC+Creature focused. Environmental combat = Combat Phase 3 feature (separate plan).

**Recommendation:** Option B. Environmental combat belongs to combat system, not creature system. Defer to combat-plan sequel.

---

### Q7: Portal Refactoring (Lisa's TDD Pass)

**Status:** 6 doors tagged (#203–208). Lisa (Porter) assigned TDD + refactor work.

**Decision needed:** Does this start in Pre-Wave or after WAVE-1?

**Recommendation:** Pre-Wave. Portal infrastructure cleanup unblocks Level 2 room integration. ~3–4 hours. Parallel with wiring bug fixes.

---

## Section 6: Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| **Werewolf design ambiguity blocks WAVE-1** | Medium | High | Resolve Q1 before Pre-Wave |
| **Pack role system scope creep** | High | Medium | Lock WAVE-2 scope in Pre-Wave; Full zone-targeting → Phase 6 |
| **Preservation system requires FSM overhaul** | Medium | High | Prototype salt mutation in Pre-Wave; don't redesign FSM |
| **Level 2 design incomplete** | Medium | High | Assign Moe + Bart 2 days pre-phase for sketch |
| **Humanoid NPC expectations unclear** | High | Medium | Resolve Q3 early; communicate "stubs only" if choosing B |
| **Portal refactoring uncovers deeper issues** | Low–Medium | Medium | Time-box Lisa's work; defer architectural changes to Phase 6 |
| **Test baseline regression from L2 integration** | Low | High | Run full test suite after WAVE-1; gate on 0 new failures |
| **Preservation FSM conflicts with existing food objects** | Medium | Medium | Audit Phase 4 food objects before WAVE-3; document state grammar |
| **Pack coordination AI creates performance issues** | Low | High | Profile pack scoring loop in Pre-Wave; optimize pathfinding if needed |
| **Phase 5 overscope vs 4-week target** | High | High | Lock wave sequence in Pre-Wave; defer Wave 5 to Phase 6 if needed |

---

## Section 7: Estimate & Timeline

### Phase 5 Scope Estimate (Preliminary)

Assumes:
- Q1: Werewolf = Option B (NPC type)
- Q2: Preservation = Option A (salt-only)
- Q3: Humanoid NPCs = Option B (stubs only)
- Q4: Pack roles = Option A (simplified)
- Q5: A* pathfinding = Option B (defer)
- Q6: Environmental combat = Option B (defer)

| Wave | Code LOC | Test LOC | Days | Est. Team Size |
|------|----------|----------|------|----------------|
| Pre-Wave | 50 | 20 | 2 | 4 (Nelson, Bart, Moe, Lisa) |
| WAVE-1 | 400–500 | 80–100 | 5 | 5 (Moe, Flanders, Bart, Nelson, Smithers) |
| WAVE-2 | 150–200 | 40–60 | 3 | 3 (Bart, Flanders, Nelson) |
| WAVE-3 | 80–120 | 30–50 | 2 | 3 (Smithers, Flanders, Nelson) |
| WAVE-4 | 50–100 | 20–30 | 1 | 2 (Flanders, Nelson) |
| WAVE-5 | 0 | 0 | 2 | 3 (Brockman, Nelson, Scribe) |
| **TOTAL** | **730–920 LOC** | **190–260 LOC** | **15 days** | — |

**Phase 5 Duration:** ~3–4 weeks (4 parallel waves, 1 pre-wave, 1 polish wave)  
**Test Target:** 270+ passing tests (no regressions vs Phase 4 baseline: 223)

---

## Section 8: Deliverables Checklist (Draft)

### Code

- [ ] 7 new Level 2 room definitions (instances + exits)
- [ ] 2–3 new creature types (werewolf, centaur?, or NPCs stubs)
- [ ] Extended wolf pack AI (roles, territory expansion)
- [ ] Preservation system (salt verb, salted-food mutation)
- [ ] Food object FSM updates (fresh → salted states)
- [ ] NPC dialogue stubs (if Q3=B; placeholder responses)
- [ ] 190–260 tests (new + regression)

### Design Docs (Brockman)

- [ ] `docs/architecture/creatures/pack-tactics-v2.md` (extended roles)
- [ ] `docs/design/food-preservation-system.md` (salt, spoilage, economics)
- [ ] `docs/design/level2-ecology.md` (room descriptions, creature habitats, treasure placement)
- [ ] `docs/architecture/npc/dialogue-framework.md` (if Q3=A; or minimal stubs doc)
- [ ] `docs/design/werewolf-mechanics.md` (chosen option from Q1)

### Artifacts

- [ ] Phase 5 completion checkpoint (Scribe)
- [ ] Final LLM walkthrough (Nelson)
- [ ] Git commits (1 per wave + final)
- [ ] Session log (.squad/log/...)

---

## Section 9: Success Criteria

Phase 5 is complete when:

1. ✅ All 7 Level 2 rooms instantiate, exits route correctly, no orphans
2. ✅ Werewolf mechanic works (chosen option from Q1)
3. ✅ Pack coordination: wolves stagger attacks or coordinate zones (Q4 option)
4. ✅ Food preservation: salt verb works, salted meat lasts longer
5. ✅ 270+ tests pass with 0 regressions vs Phase 4 baseline
6. ✅ Full playthrough: start room → Level 1 challenges → brass-key transition → Level 2 exploration → new creature encounters → resource preservation → safe rest
7. ✅ Design docs complete (ecology, pack tactics, preservation, Level 2 map)
8. ✅ All open GitHub issues (P0) closed or explicitly deferred with tracking ticket

---

## Section 10: Phase 6 Preview (Defer)

Post-Phase-5 pipeline (not in scope):

| Feature | Est. Phase | Rationale |
|---------|-----------|-----------|
| **Full environmental combat** | Phase 6a | Belongs to combat system |
| **A* pathfinding** | Phase 6a | Nice-to-have after L2 creature placement validated |
| **Creature-to-creature looting** | Phase 6a | Requires creature AI evaluation (expensive) |
| **Humanoid NPC full system** | Phase 6b | Dialogue trees, memory, quests, faction reputation |
| **Armor degradation** | Phase 6c | Weapon/armor material system overhaul |
| **Multi-ingredient cooking** | Phase 6c | Recipe system beyond single-item mutation |
| **Weapon improvements** | Phase 6c | Crafted weapon variants, enchantment stubs |

---

## Appendix A: Decision Tracking

This plan succeeds or fails on **Q1–Q7 answers**. Wayne's decision on each question gates Pre-Wave work.

**Pre-Wave Gate:** All 7 questions answered + documented in `.squad/decisions/inbox/wayne-phase5-decisions.md`

Template:

```
## Wayne Phase 5 Decisions (2026-03-28)

Q1: Werewolf Feature Design → **Option [A/B/C/D]**
Q2: Food Preservation Scope → **Option [A/B/C]**
Q3: Humanoid NPCs in Phase 5 → **Option [A/B/C]**
Q4: Pack Role System → **Option [A/B/C]**
Q5: A* Pathfinding → **Option [A/B]**
Q6: Environmental Combat → **Option [A/B]**
Q7: Portal Refactoring Timeline → **Pre-Wave / Post-WAVE-1**

Rationale: [Brief justification for each choice]
```

---

## Appendix B: Phase 4→5 Handoff Checklist

From Phase 4 completion (now.md):

- [x] Phase 4 all 6 waves complete
- [x] 223 tests passing (Phase 3 baseline + Phase 4 additions)
- [x] Wiring bugs documented (silk, craft, brass-key) — queued for Pre-Wave
- [x] Issue #261 (Stress) ready to close
- [x] Puzzle 017 objects assigned to Flanders (4 objects) + Moe (1 room)
- [ ] Phase 5 decisions from Wayne
- [ ] Level 2 design sketch
- [ ] Phase 5 wave sequence locked

---

**Next:** Wayne reviews §5 (Open Questions), provides answers → Chalmers finalizes wave sequence → Phase 5 Pre-Wave begins.

---

*Plan authored by Chalmers (Project Manager). v0.1 — Draft for Wayne review.*
