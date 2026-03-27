# D-PHASE4-PLAN: Phase 4 Implementation Plan Draft

**Author:** Bart (Architect)
**Date:** 2026-08-16
**Status:** 📝 DRAFT — Awaiting Wayne review

## Decision

Created `plans/npc-combat/npc-combat-implementation-phase4.md` — a 6-wave implementation plan for Phase 4: Resource Processing & Advanced Creature Behavior.

## Theme

**"The Crafting Loop"** — Building on Phase 3's "creatures die and become useful," Phase 4 completes the resource processing pipeline. The ecosystem becomes a production system: kill → butcher → cook/craft → use.

## Waves

| Wave | Name | Key Deliverables |
|------|------|------------------|
| WAVE-0 | Pre-Flight | LOC audit, ~18 GUID assignment, architecture docs |
| WAVE-1 | Butchery System | `butcher` verb, wolf-meat/bone/hide, butcher-knife tool |
| WAVE-2 | Loot Tables Engine | Weighted probabilistic drops, meta-lint validation |
| WAVE-3 | Stress Injury System | Psychological damage, trauma triggers, rest cure |
| WAVE-4 | Spider Ecology | Web creation, trap mechanics, silk crafting |
| WAVE-5 | Advanced Behaviors | Pack tactics, territorial marking, design docs |

## Open Questions

7 questions require Wayne input before execution:

1. **Q1:** Butchery time — instant, time-passes, or interruptible?
2. **Q2:** Safe room definition — no creatures, no hostile creatures, or designated?
3. **Q3:** Spider web visibility in darkness
4. **Q4:** Pack tactics alpha selection criteria
5. **Q5:** Territorial marking player detection
6. **Q6:** Silk bandage healing — instant or over time?
7. **Q7:** Food preservation in Phase 4 scope?

## Estimates

- **Files:** ~30-35 new, ~25-30 modified
- **Tests:** ~250 at completion (from ~209 baseline)
- **LOC:** ~1,540 new/modified code + ~350 test LOC

## Source Documents Analyzed

1. `plans/npc-combat/combat-system-plan.md` — identified deferred: wrestling, environmental combat, weapon degradation, pack tactics
2. `plans/npc-combat/creature-inventory-plan.md` — identified deferred: loot tables, creature-to-creature looting
3. `plans/npc-combat/npc-system-plan.md` — identified deferred: humanoid NPCs, A* pathfinding, spider web creation
4. `plans/npc-combat/npc-combat-implementation-phase3.md` — Phase 3 complete, deferred: stress injury, loot tables, butchery, silk crafting
5. `plans/npc-combat/npc-combat-implementation-phase2.md` — Phase 2 complete, creature ecosystem established

## Deferred to Phase 5

- Food preservation (salting, smoking, drying)
- Wrestling/grapple combat
- Environmental combat (push barrel, slam door)
- Weapon/armor degradation
- Humanoid NPCs (dialogue, memory, quests)
- Multi-ingredient cooking

## Affected Agents

| Agent | Phase 4 Responsibility |
|-------|------------------------|
| Bart | Loot engine, stress hooks, pack tactics, territorial, create_object action |
| Flanders | Butchery products, wolf/spider objects, stress injury, silk crafting objects |
| Smithers | Butcher verb, craft verb extensions, status UI, weapon combat metadata |
| Moe | Spider placement in cellar |
| Nelson | All test waves, meta-lint, LLM walkthroughs |
| Brockman | Architecture docs (W0), design docs (W5) |

## Next Steps

1. Wayne reviews plan and answers 7 open questions
2. Team review (CBG, Marge, Chalmers, Flanders, Smithers, Moe)
3. Blocker resolution pass if needed
4. WAVE-0 kickoff

---

*Filed by Bart (Architect)*
