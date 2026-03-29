# Level 2 — Board

**Owner:** 📊 Kirk (PM coordination) + 🎮 CBG (Game Design lead) + 🏗️ Moe (World Building lead)  
**Last Updated:** 2026-03-30  
**Overall Status:** 🟡 Planning

---

## Next Steps (Prioritized)

| Priority | Task | Owner | Status | Gate |
|----------|------|-------|--------|------|
| **P0** | Design review: CBG to draft Level 2 vision document (themes, difficulty progression, new mechanics) | CBG | ⏳ Pending | GATE-0 (vision approved) |
| **P0** | World planning: Moe to map Level 2 room layout (room count, connections, environment style) | Moe | ⏳ Pending | GATE-0 (layout approved) |
| **P1** | Creature design: Flanders to propose new creature types for escalated intelligence | Flanders | ⏳ Pending | GATE-1 (creature spec ready) |
| **P1** | Portal completion: Lisa working on #205 (hallway → level-2 staircase boundary portal) | Lisa | 📋 In Progress | GATE-1 (portal TDD passes) |
| **P2** | Infrastructure gate: Ensure Level 1 stability (T0 bugs fixed, 257 tests green) | Marge + Nelson | 📋 In Progress | GATE-1 (zero regressions) |

---

## Overall Status

🟡 **Planning Phase** — Waiting for design + world layout approvals. No code work starts until CBG vision doc and Moe room map are locked. Infrastructure dependencies (#203-208 portal TDD, Level 1 stability) on track.

---

## Scope — What Level 2 Includes

### New Areas
- **New wing of the manor** (or new area entirely — TBD by design team in GATE-0)
- **Room count:** TBD by Moe after world planning (estimated 8–12 rooms based on expansion scope)
- **Environment style:** TBD (current leading concepts: deeper cellar, garden exterior, library wing, attic — awaiting CBG vision)

### Creature Intelligence Escalation
- **Smarter behaviors:** Improved pack tactics, territorial intelligence, ambush patterns (follows Phase 5 creature behavior engine)
- **New creature types:** TBD by Flanders (examples in-scope: larger predators, multi-part creatures, creatures with tool use)
- **Difficulty curve:** Harder than Level 1, consistent with Phase 5 NPC combat scope

### New Puzzle Chains
- **Sideshow Bob to design:** Escalated puzzle complexity, multi-room dependencies, creature interactions
- **Objects needed:** New inventory items, containers, mechanisms (locked by world layout)

### New Objects + Materials
- **Objects:** Flanders to propose ~15–25 new objects per Level 2 area (scope TBD)
- **Materials:** Standard materials (stone, iron, wood, tallow, wool, leather); no new material types in MVP

### Portal System Integration
- **Level 1 → Level 2 boundary:** Hallway staircase (#205) implemented by Lisa (portal TDD refactor)
- **Portal unification:** All portals (doors, stairs, archways) follow unified system per #203-208
- **No multiplayer in MVP:** Single-player only (Rift mechanics deferred to Phase 6+)

---

## Dependencies

### Must Complete Before Level 2 Starts

| Dependency | Current Status | Owner | Impact |
|------------|---|---|---|
| **Level 1 Stability (T0 bugs fixed)** | 🟢 In progress (#406, #315) | Moe, Lisa | Cannot ship beta with broken Level 1 |
| **Portal TDD Refactors (#203-208)** | 🟡 Pending (Wave 2 ready) | Lisa, Moe | Hallway-level2 staircase needs unified portal system |
| **Creature behavior engine (Phase 5)** | 📋 Planned | Bart | Level 2 creatures use Phase 5 behavior system |
| **World system (WAVE-2 boot integration)** | 📋 Pending (Bart + Moe) | Bart, Moe | Level 2 defined as world-01 level-02 (or new world) |

### Non-Blocking (Can Parallel)

| Item | Owner | Timeline |
|------|-------|----------|
| Sound system integration | Bart + Gil | WAVE-0-3 (phases 2026-08+) |
| NPC combat Phase 5 (advanced) | Bart | After creature basics |
| Clothing/wardrobe system | CBG + Flanders | Phase 6 (deferred) |

---

## Open Questions (Blockers for Vision Lock)

1. **What is Level 2's theme?**
   - Manor wing (library, attic, storage)?
   - Basement depth (catacombs, crypts)?
   - Garden / exterior (fresh air, outdoor threats)?
   - Combination (mixed environments)?

2. **How many rooms?** (Impacts level design complexity, puzzle chains, creature variety)
   - Estimate: 8–12 rooms (vs Level 1's 7)
   - Branching factor: linear chain, grid, or hub-and-spoke?

3. **What new creature types?** (Impacts Flanders' object design)
   - Larger predators (bears, boars)?
   - Multi-part creatures (swarms, hives)?
   - Intelligent creatures (crows, humanoid outlines)?
   - Deferred creatures (werewolves, humanoids — Phase 5+ scope per D-WAYNE-PHASE5-DECISIONS)?

4. **Difficulty curve:** How much harder than Level 1?
   - Creature intelligence: Pack tactics only, or territorial + ambush?
   - Puzzle gates: Single-object solutions (like Level 1), or multi-room chains?
   - Time pressure: Do creatures hunt more aggressively? Poison more lethal?

5. **Boundary design:** What is the narrative crossing from Level 1 → Level 2?
   - Staircase descends (deeper manor)?
   - Door opens (new wing)?
   - Portal effect (magical transition)?

---

## Success Criteria (Gating)

### GATE-0: Vision + Layout Locked
- ✅ CBG vision document approved (themes, difficulty, mechanics, 2–3 page narrative)
- ✅ Moe room map approved (room count, connections, descriptions, starting_room)
- ✅ Wayne sign-off on scope (no scope creep mid-design)

### GATE-1: Infrastructure Ready
- ✅ Level 1 T0 bugs fixed + 257 tests green (Marge verified)
- ✅ Portal TDD refactors complete (#203-208, Lisa + Moe signed off)
- ✅ World system WAVE-2 boot integration complete (Bart + Moe)
- ✅ Flanders creature design spec ready (new creature types + behaviors)

### GATE-2: Design Assets Created
- ✅ Creature types implemented + tested (Flanders)
- ✅ Room definitions + topology (Moe)
- ✅ Puzzle chains designed (Sideshow Bob)
- ✅ Objects created + integrated (Flanders, Moe)

### GATE-3: Integration Complete
- ✅ All Level 2 objects, creatures, rooms load + play
- ✅ Portal (hallway → level-2) connects + works
- ✅ Puzzle chains playable end-to-end
- ✅ 300+ total tests passing (no regression)

### GATE-4: Beta Ready
- ✅ Sound ambients + creature sounds (if Phase 2+ prioritized)
- ✅ LLM walkthrough (Nelson) — full Level 2 playthrough
- ✅ Documentation updated (Brockman)
- ✅ Ready for beta playtester feedback

---

## Roadmap — Estimated Timeline

**Phase Breakdown (subject to GATE-0 approval):**

| Phase | Weeks | Owner(s) | Gate | Notes |
|-------|-------|----------|------|-------|
| **Vision + Design** | 1–2 | CBG, Moe, Kirk | GATE-0 | Design docs locked, no code work |
| **Infrastructure Ready** | 1 | Lisa, Bart, Moe, Nelson | GATE-1 | Portal TDD, world boot, L1 stability |
| **Asset Creation** | 2–3 | Flanders, Moe, Sideshow Bob | GATE-2 | Creatures, rooms, objects, puzzles |
| **Integration + Testing** | 1–2 | All | GATE-3 | Full suite pass, regression check |
| **Beta Polish** | 1 | Gil, Brockman, Nelson | GATE-4 | Docs, sounds (if prioritized), LLM walkthrough |

**Total Estimate:** 6–9 weeks (after GATE-0 lock)

---

## Ownership & Charter Alignment

| Role | Owner | Responsibility | Charter |
|------|-------|---|---|
| **PM Coordination** | Kirk | Cross-project scheduling, blocker escalation | Project Manager |
| **Game Design Lead** | CBG | Theme, difficulty curve, mechanics | Game Designer |
| **World Building Lead** | Moe | Room layout, topology, world data | World & Level Builder |
| **Creature Design** | Flanders | New creature types, behaviors, objects | Content Lead |
| **Puzzle Design** | Sideshow Bob | Puzzle chains, multi-room mechanics | Puzzle Designer |
| **Portal Implementation** | Lisa | #205 hallway-level2 staircase TDD | Portal System (assigned in #203-208) |
| **Infrastructure (world system)** | Bart | World WAVE-2 boot integration | Architecture Lead |
| **Infrastructure (portal system)** | Moe + Lisa | #203-208 portal TDD refactors | World Building / Portal System |
| **QA & Regression** | Marge + Nelson | 300+ test pass gate, LLM walkthrough | Test & QA Lead |
| **Documentation** | Brockman | Architecture docs, design patterns update | Documentation Lead |

---

## Priority in Project Portfolio

**Tier:** 🟡 Background (Future work, after T0-T4)

Per `projects/priorities.md`:
- **T0:** Testing (steady state)
- **T1:** Worlds (design ready, pre-WAVE-1)
- **T2:** Sound (design complete, team review pending)
- **T3:** Food (90% done)
- **T4:** NPC Combat (Phase 5 plan reviewed)
- **Background:** Level 2, Parser Improvements

**Why background?** Level 1 must be stable + portal system unified before Level 2 design locks. Expected to move to T0-T1 after Phase 5 / portal TDD completion (~3-4 weeks).

---

## Key Decisions Affecting This Project

| ID | Decision | Status | Impact on Level 2 |
|----|----------|--------|---|
| **D-14** | Code mutation is state change | 🟢 Active | Level 2 object state changes via mutation |
| **D-INANIMATE** | Objects are inanimate (no NPCs yet) | 🟢 Active | Level 2 creatures (Phase 5) separate from objects |
| **D-WORLDS-CONCEPT** | Worlds are top-level containers | 🟢 Active | Level 2 is world-01 level-02 (or new world) |
| **D-WAYNE-PHASE5-DECISIONS** | Phase 5 scope: werewolf NPC, salt preservation, simplified pack tactics | 🟢 Active | Level 2 creatures use Phase 5 behavior engine |
| **D-DEPLOY-ON-MERGE** | Deploy-on-merge to GitHub Pages | 🟢 Active | Level 2 ships on main branch merge |

---

## Plan Files

| File | Purpose |
|------|---------|
| `projects/level-2/board.md` | This board — roadmap, dependencies, gating |
| (Future) `projects/level-2/vision.md` | CBG design vision (themes, difficulty, mechanics) |
| (Future) `projects/level-2/world-layout.md` | Moe's room topology + connections |
| (Future) `projects/level-2/creature-spec.md` | Flanders creature types + behaviors |
| (Future) `projects/level-2/puzzle-chains.md` | Sideshow Bob puzzle design |

---

*Board created by Kirk (Project Manager). Update after each gate completion.*
