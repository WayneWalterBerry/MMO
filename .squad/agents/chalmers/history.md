# Project Context

- **Owner:** Wayne "Effe" Berry
- **Project:** MMO
- **Created:** 2026-03-18

## Core Context

Agent Chalmers initialized as Project Manager for the MMO project.

## Recent Updates

📌 Team initialized on 2026-03-18

## Learnings

### Phase 5 Planning (2026-03-28)

**Context:** Phase 4 shipped all 6 waves (crafting loop complete). Level 1 has 74+ objects, 7 rooms, 31+ verbs, 223 passing tests. Phase 5 gated on Wayne's decisions re: werewolf design, preservation scope, NPC humanoids, and pack role system.

**Decisions Documented:**
- 7 Open Questions (Q1–Q7) with 3–4 options each, blocking Pre-Wave
- Risk register: 10 risks identified (werewolf ambiguity, scope creep, FSM conflicts highest)
- Estimated scope: ~730–920 LOC new, ~190–260 LOC tests, 3–4 week duration

**Phase 5 Theme:** "Ecosystem Expansion + Creature Intelligence Escalation"
- WAVE-1: Level 2 foundation (7 rooms, 2–3 new creatures)
- WAVE-2: Pack role system (alpha/beta/omega, territories)
- WAVE-3: Food preservation (salt-only recommended)
- WAVE-4: Humanoid NPC stubs (if Q3 = Option B)
- WAVE-5: Polish + design docs

**Key Deferrals (from Phase 4 plan §11):**
- Zone-targeting for pack coordination (defer to Q4 decision)
- Full preservation system (recommend salt-only, full system = Phase 6)
- A* pathfinding (insufficient L2 benefit, defer)
- Environmental combat (belongs to combat system)
- Humanoid NPC full system (massive scope, Phase 6 centerpiece)

**Backlog Assessed:**
- 17 open GitHub issues triaged: P0 (wiring, Puzzle 017, #261 close), P1 (werewolf, NPC), P2–P4 (environmental, pathfinding, portal refactor)
- Portal Phase 2 (Lisa): 6 doors tagged for TDD + refactor (#203–208), ~3–4 hours, can run in Pre-Wave parallel

**Dependencies Documented:**
- Hard blocker: Pre-Wave (bug fixes, decisions) → WAVE-1 → WAVE-2/3 (parallel) → WAVE-4 (optional) → WAVE-5
- Design blocker: Q1, Q2, Q3 answers required before WAVE-1 scope lock

**Recommendations to Wayne:**
1. Werewolf: Option B (NPC type) or Option D (defer) — avoid disease model (complexity)
2. Preservation: Option A (salt-only, ~80 LOC) — full system is Phase 6
3. Humanoid NPCs: Option B (stubs only) or Option C (defer) — keep Phase 5 focused
4. Pack roles: Option A (simplified) or Option C (omega reserves only) — zone-targeting is Phase 6
5. Portal refactor: Pre-Wave parallel with bug fixes

**Deliverables:**
- `plans/npc-combat/phase5-planning-draft.md` created (18.5 KB)
- 8 design docs queued (pack tactics v2, preservation, Level 2 ecology, werewolf, dialogue stubs)
- Phase 5 success criteria: L2 rooms, creature mechanics, preservation loop, 270+ tests, full playthrough demonstration

### Walk-Away Execution Model (Phase 4 Analysis, 2026-03-28)

**What worked:**
1. Pre-written decision documents (D-WAVE1–D-WAVE5) drove execution without human approval gates
2. Wave-by-wave structure with Scribe merging prevented merge conflicts (0 across 26 agents)
3. Parallel spawning scaled to 5 agents per wave without coordination overhead
4. Clear charter boundaries (Bart→engine, Flanders→objects, etc.) prevented stepping-on-toes
5. Integration occurred post-deploy; bugs were wiring-only (fixable <1 hour each)

**What didn't:**
1. Test flakiness uncovered (pack_tactics fails in suite, passes standalone) — needs root cause
2. TDD broken (tests written AFTER implementation in parallel tracks)
3. Pre-existing TDD-red tests polluted dashboard (should separate or close)
4. 3 wiring bugs escaped: silk disambiguation, craft recipe wiring, key/padlock state
5. Integration checkpoints missing (modules tested in isolation)

**Key insight:** Walk-away is 3–4x faster than serial but at cost of post-ship bug finding. Acceptable for isolated features, risky for core subsystems. Hybrid model recommended for Phase 5.

**Phase 5 actions:**
- Add mid-wave integration smoke test (30 min, catches bugs early)
- Investigate test flakiness (registry state leaking?)
- Separate TDD-red tests from active suite (noise reduction)
- Revive TDD discipline with hybrid approach (wave tests BEFORE spawn, feature tests AFTER)
