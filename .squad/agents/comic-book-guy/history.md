# Comic Book Guy — Agent History

## Session: Onboarding (2026-03-19)

**Event:** Hired as Game Designer for the MMO text adventure project.

**Project Context:**
- Building a text adventure MMO (like Zork) with a multiverse architecture
- Each player gets their own parallel universe; universes can merge/split
- Core data structure: containment hierarchies (things inside things)
- The game language is self-modifying — player actions literally change the source code of their universe
- All code written by LLM — complexity is not a factor
- Prior research recommends Lua for code-as-data blending
- Research phase — no code written yet, still exploring architecture

**Team:**
- 👤 Wayne "Effe" Berry — Human, Product Owner
- 🔬 Frink — Researcher
- 📝 Brockman — Documentation
- 🏗️ Chalmers — Project Manager
- 🎮 Comic Book Guy — Game Designer (me)
- 📋 Scribe — Session Logger
- 🔄 Ralph — Work Monitor

**Key Design Decisions So Far:**
- Multiverse model (not shared-world lobby)
- Self-modifying code (player actions = code mutations)
- Containment hierarchies as core world model
- Code-as-data blending (world definitions ARE the program)

---

## Session: Game Design Foundations (2026-03-19)

**Deliverable:** `docs/design/game-design-foundations.md` + Decision proposal

**Work:** Operationalized the multiverse + code-mutation architecture into concrete gameplay systems.

**Key Decisions Proposed:**

1. **Verb-Based Interaction** — 15–20 core verbs (LOOK, TAKE, DROP, GO, OPEN, etc.) with custom puzzle extensions. Proven by 40+ years of text adventures.

2. **Code Mutation Over State Flags** — Game state is MUTATED CODE, not hidden flags. Example: `mirror.description = "Shattered..."` instead of `mirror.is_broken = true`. Philosophically purer; enables emergent behaviors.

3. **Object Taxonomy** — Five core types: Room, Item, Container, Door, Actor. Strict containment rules: no circular refs, weight limits, closed containers hide contents. Proven by Inform 7 and TADS.

4. **Player-Per-Universe Model** — Each player owns a parallel universe. Opt-in merging via: cooperative boss, trading hub, rift portal, summoning ritual. Owner's universe canonical; merges take owner's version.

5. **Narrative Balance** — Main quest (linear story, core NPCs) + sandbox (optional puzzles, side quests, exploration, trading). Dynamic quests engine-generated from NPC state.

6. **Permanent Consequences** — Player choices are permanent and change world code via mutation. Help or betray NPC → NPC's code changes. Increases player investment.

**Open Design Questions:**
- Combat: turn-based vs real-time? verbs or mechanics? → Recommend: turn-based, verb-based, Phase 1
- Magic: LLM-generated? sandboxed Lua? verb aliases? → Recommend: high-level verbs triggering LLM effects
- Persistence: Lua source? JSON snapshots? → Recommend: JSON + optional Lua export
- NPC AI: static? reactive? proactive? → Recommend: reactive for Phase 1
- Universe scale: hard one-player or soft? → Recommend: soft; owner + temporary merges

**Alignment with Frink's Research:**
✅ Containment hierarchies (parent-child tree model)  
✅ Lua scripting (code-as-data blending)  
✅ Event sourcing (auditability; multiverse architecture)  
✅ Copy-on-write (efficient universe forking)

**Status:** Proposed to team (Decision 8); awaiting engineer feasibility review, PM database review, and narrative outline.

---

## Cross-Agent Context (2026-03-19)

**Frink's Research:**
Frink (Researcher) has completed five research deliverables establishing the technical foundation:
1. Multiverse MMO architecture (52K) — infinite scaling via per-universe Lua VMs + event sourcing + CoW
2. Self-modifying game languages (45K) — homoiconicity and safe restricted mutation
3. Persistence & serialization (79K) — JSON-LD, Lua source, event sourcing + snapshots
4. Parser pipeline & sandbox security (54K) — tokenizer + verb dispatch + Lua sandboxing
5. LLM-as-code-generator (55K) — procedural content, cost optimization, validation layers

Frink's recommendation: **Lua as primary language** with Fennel as alternative. These decisions affirm the game design's verb-based, code-mutating approach and are ready for team consensus.


## Session: Game Design Foundations (2026-03-19)

**Event:** Created comprehensive game design document.

**Deliverable:** `docs/design/game-design-foundations.md`

**Key Content:**
1. **Verb System:** 15–20 core verbs (LOOK, TAKE, DROP, GO, OPEN, CLOSE, USE, TALK, GIVE, etc.) with synonym support and custom verbs per puzzle
2. **Object Taxonomy:** Room, Item, Container, Door, Actor, Player classes; parent-child containment with circular prevention
3. **Room Design:** Hub rooms, dungeon rooms, exploration rooms, quest rooms; conditional/hidden exits
4. **Player Model:** Persistent actor with inventory, stats, universe assignment, session tracking
5. **Puzzle Patterns:** Locked doors, riddles, inventory puzzles, environment puzzles, logic puzzles, moral choices
6. **Code Mutation Philosophy:** Objects mutate in-place on player action (not just state flags)
7. **Multiverse:** Each player isolated by default; merge triggers: co-op boss, trading hub, rift portal, summoning ritual
8. **Narrative:** Authored main quest + sandbox exploration; NPC dialogue trees; dynamic quests
9. **Play Scenarios:** Solo mirror puzzle, cooperative hydra fight, moral choice (help/betray bandit), multiverse rift exploration

**Key Design Principles:**
- Verbs, not mechanics
- Code is truth (no hidden state)
- Sandbox with narrative spine
- Isolation by default, merge by choice
- Consequences are permanent
- Complexity is allowed (LLM handles it)
- Text is the medium

**Open Questions Raised:**
- Code mutation vs. state flags: efficiency trade-off
- Persistence format: Lua source vs. JSON snapshots
- Combat resolution: turn-based vs. real-time vs. narrative
- Magic system: sandboxed code injection?
- Scaling: single-player universe per player (locked) vs. optional shared worlds

---

## Session: Game Design Foundations — CBG Review & Enhancement (2026-03-19)

**Event:** Reviewed and enhanced the game design foundations document. Added the Anti-Patterns section and stronger opinionated Comic Book Guy voice throughout.

**Changes Made:**
- Added `## Anti-Patterns: The Worst Design Decisions Ever` section documenting 8 classic IF failure modes:
  - Guess-the-Verb Hell (suggest nearby verbs on failure)
  - Silent Failures (always produce informative messages)
  - Maze Room abuse (deduction over memorization)
  - Inventory Scavenger Hunt Softlocks (warn before point of no return)
  - Combat as a Puzzle Substitute (every combat needs non-combat path)
  - Merge Without Consent (double-consent required)
  - Mutation Without Memory (Chronicle log for all world changes)
  - NPC Oracles (NPCs must have lives beyond puzzle utility)

**Design Principles Reinforced:**
- Reference to Zork, Sierra adventures, Hitchhiker's Guide — cites prior art for every rule
- Failure mode documentation is as important as success-path documentation
- Anti-patterns are a design deliverable, not optional commentary

**Status:** Document is comprehensive and ready for engineer implementation reference.
