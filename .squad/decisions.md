# Squad Decisions

## Active Decisions

### 1. Newspaper Format & Purpose (2026-03-18)
**Author:** Brockman  
**Status:** Approved  

Established a daily newspaper (markdown format, timestamped by date) as the primary communications hub for team updates, decisions, and milestones.

**Format:**
- Location: `newspaper/` folder at repo root
- Naming: `YYYY-MM-DD.md` (date-based, one edition per day)
- Structure: Masthead, headlines, updates, decisions, team spotlights, editor's note
- Tone: Professional but playful

**Rationale:** Creates a central, readable log of team activity that's accessible and engaging. Keeps communication from feeling like dry logs. Provides context for new team members.

**Next Steps:** Establish rotation/schedule, decide on auto-generation vs. human curation, link archives to README.

---

### 2. Folder Naming Convention (2026-03-18)
**Author:** Wayne "Effe" Berry  
**Status:** Active  

Prefer lowercase folder names with dashes instead of spaces (e.g., `my-folder`, not `MyFolder` or `my_folder`). User directive captured for team memory.

---

### 3. Text Adventure Containment Architecture (2026-03-18)
**Author:** Frink (Researcher)  
**Status:** Ready for team review  
**Impact:** Architecture-level; affects core engine design  

**Recommendation:** Adopt a hybrid approach combining classical parent-child tree containment with optional ECS for state management.

**Key Findings:**
1. **Containment Model:** All proven IF engines (Zork, Inform 7, TADS) use identical parent-child tree structure. This is the industry standard and is simple, efficient, and proven.
2. **Room Topology:** Rooms modeled as graph nodes; exits as edges. Standard adjacency-list representation works well.
3. **State Management:** Hybrid Memento + Command pattern balances memory efficiency with undo flexibility. Snapshots after every N commands, not per-turn.
4. **Parsing:** Simple tokenizer + verb dictionary dispatch (proven pattern). No heavy NLP (SpaCy/BERT overkill).

**Architecture Details:**
- Each object has `.location` (parent reference) and `.contents` (children list)
- Enforce constraints: rooms never move, circular containment prevented, weight limits checked
- Simple adjacency-list representation for rooms (dict: direction → room)
- Support conditional exits via Door objects (locked, requires key, etc.)
- JSON serialization with snapshot-based undo for memory efficiency

**Action Items:**
- [ ] Engineer: Prototype containment tree in target language (TypeScript/Kotlin/Swift recommended)
- [ ] Engineer: Test command parsing with 3–5 core verbs
- [ ] Designer: Define object types and properties for game content
- [ ] QA: Validate weight limits and containment constraints

**Full Research:** `.squad/agents/frink/research-text-adventure-architecture.md`

---

### 4. User Directive: Skip Mobile-Specific Material (2026-03-18T222300Z)
**Author:** Wayne "Effe" Berry (via Copilot)  
**Status:** Active  

Skip mobile-specific material for now. Focus research on data structures only.

---

### 5. Modern IF Architecture for MMO Project (2026-03-18T222400Z)
**Author:** Frink, Researcher  
**Status:** Proposed (awaiting team review)  
**Related Research:** `resources/research/architecture/modern-text-adventure-data-structures.md`

**Recommendation:** Hybrid ECS + Event-Sourced + Offline-First Architecture

**Rationale:**
Modern academic research emphasizes graph-based relationships over tree-only models. ECS pattern is industry standard across Unity, Unreal, Godot. Event sourcing enables rich state history and debugging. Offline-first with SQLite is essential for mobile resilience.

**Architecture Stack:**
1. **Entity-Component-System (ECS)** — World model layer with composable entities
2. **Event Sourcing** — Immutable log with periodic snapshots
3. **Offline-First SQLite** — Local canonical store, mutation queue for sync
4. **JSON-LD Serialization** — Semantic world definitions for interoperability

**Data Flow:**
Player Input → Command Parser → Event Emission → SQLite Persist → ECS Update → UI Render → Sync Queue

**Strengths:**
- Mobile-Ready: SQLite blazing fast; offline-first eliminates network waits
- Extensible: ECS makes adding mechanics (cursed items, traps, dialogues) trivial
- Debuggable: Event log enables session replay
- Future-Proof: JSON-LD enables AI/tool integration

**Implementation Roadmap:**
- Phase 1: Minimal ECS (5 components) + SQLite schema + JSON-LD example
- Phase 2: Full command loop, containment system, undo mechanism
- Phase 3: Extensibility validation (add 3+ new mechanics)
- Phase 4: Optimization, snapshots, UI polish

**Decision Authority:** Level 2 (architecture-affecting, requires team consensus)

**Approvers Needed:**
- Wayne "Effe" Berry (Product Owner)
- Squad Lead (if designated)

**Timeline:** Proposal → Review (1 week) → Approval/Iteration → Prototype (2 weeks)

**Risk Mitigations:**
| Risk | Severity | Mitigation |
|------|----------|-----------|
| Event log grows large | Medium | Snapshots every N events; prune after snapshot |
| ECS overkill for small game | Low | Start with 5–10 components; architecture scales down |
| Team unfamiliar with ECS | Medium | Tutorial & reference implementations provided |
| JSON-LD serialization complexity | Low | Use existing libraries; start simple |

---

### 6. Language & Runtime for Blended Code-Data IF Engine (2026-03-19)
**Author:** Frink (Researcher)  
**Status:** Ready for team review  
**Impact:** Architecture-level; affects core engine design and scripting approach  

**Recommendation:** Use **Lua** as the primary scripting language for the text adventure engine, with **Fennel** (Lisp on Lua) as a powerful alternative.

**Key Findings:**
1. **Code-Data Blending:** Lua's prototype-based tables naturally unify code (functions) and data (values), enabling emergent game systems.
2. **JIT Not Needed:** Critical finding — text adventures have trivial compute workloads. Plain Lua is sufficient; LuaJIT is optional.
3. **Industry Standard:** 100+ games use Lua for embedded scripting (WoW, Roblox, LÖVE, Defold, Garry's Mod).
4. **Embeddable:** ~200 KB runtime; clean C API; live reloading capable.
5. **Prototype-Based > Class-Based:** Self-modifying worlds benefit from per-object customization, not shared class structure.

**Three-Tier Recommendation:**
- **Tier 1 (Primary):** Lua — battle-tested, embeddable, prototype-based, DSL-friendly
- **Tier 2 (Alternative):** Fennel — full homoiconicity via Lisp syntax + Lua runtime
- **Tier 3 (Advanced):** Custom DSL on GraalVM/Truffle — only if team has compiler expertise (likely overkill)

**Example Lua World Definition:**
```lua
local world = {
  rooms = {
    dungeon = {
      name = "Dungeon",
      description = "A dark chamber.",
      on_enter = function() print("You feel a chill.") end,
      exits = { north = "hallway" }
    }
  },
  items = {
    sword = {
      name = "Iron Sword",
      damage = 10,
      on_take = function() print("The sword hums.") end
    }
  }
}
world.rooms.dungeon.on_enter()
world.items.sword.cursed = true  -- mutate at runtime
```

**Next Steps:**
1. **Engineer:** Prototype Lua embedding in target language (TypeScript/Kotlin/Swift/Rust)
2. **Designer:** Define DSL conventions as Lua libraries (Room.define(), Item.define(), etc.)
3. **Architect:** Decide on world persistence format (Lua source, JSON, or both)
4. **QA:** Validate hot-reloading and mutation behavior

**Full Research:** `resources/research/architecture/code-data-blended-languages.md` (40K+ words, 10+ candidates, 30+ glossary terms)

---

---

### 7. Multiverse MMO Architecture

**Author:** Frink (Researcher)  
**Date:** 2026-03-19  
**Status:** Proposed (awaiting team review)  
**Priority:** High (affects core architecture)  

**Proposal:** Adopt a multiverse MMO architecture where each player gets their own private universe by default. Universes can merge opt-in via raid mechanics, events, and social triggers.

**Key Benefits:**
- Infinite scalability with no shared bottleneck
- No resource contention; rare items don't compete across players
- Per-player narrative pacing; quests progress at player speed
- Opt-in multiplayer (raids, events, trading are consensual)
- Auditable state via event sourcing; full history preserved
- Git-compatible; state stored as Lua source with natural diffs

**Technical Stack:**
```
Lua VM (per-universe)
  → Event Sourcing (immutable log)
  → Copy-on-Write Snapshots (efficient storage; 1000 players × 10 MB ≈ 110 MB)
  → Git-Like DAG (universe relationships)
  → Procedural Generation (infinite universes via deterministic seeds)
  → Storage Tiers (RAM → Hibernation → Archive → Forgotten)
```

**Implementation Roadmap:**
1. Single canonical universe; event sourcing
2. Per-player forks; CoW snapshots
3. Merging; conflict resolution
4. Procedural generation; scaling
5. Advanced features (dimensional rifts, multi-universe events)

**Key Trade-Offs:**
- Players isolated by default; merge mechanics must be compelling
- Merge conflicts require explicit resolution (last-write-wins, conflict markers, OT)
- Procedural generation must be deterministic (seed-based)

**Risks & Mitigations:**
- Merge conflicts intractable → Design game logic to prevent conflicts; use CRDTs
- State explosion → Procedural + CoW; aggressive archival
- Lua VM overhead → LuaJIT lightweight; profile and optimize
- Universe hopping to grief → Identity/XP tied to primary universe

**Research Deliverable:** `resources/research/architecture/multiverse-mmo-architecture.md` (52K)

**Next Steps:** Architecture team feasibility review; design merge conflict resolution; engineer prototyping.

**Decision Ready for Team Merge** ✓

---

### 8. Game Design Foundations

**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-03-19  
**Status:** Proposed (awaiting team review)  
**Impact:** Establishes core gameplay pillars; affects engine design  

**Core Decisions:**

#### 8.1 Verb-Based Interaction System
- 15–20 core verbs (LOOK, TAKE, DROP, GO, OPEN, etc.)
- Framework for custom puzzle-specific verbs
- Proven by 40+ years of text adventures
- Rationale: natural for players; directly maps intent to command
- Implications: engine must parse commands; each verb has preconditions + side effects

#### 8.2 Code Mutation Over State Flags
- Game state is MUTATED CODE, not hidden flags
- Example: `mirror.description = "Shattered..."; mirror.on_look = new_func(...)`
- Philosophically purer; easier to reason about; enables emergent behaviors
- Trade-off: may be LLM-costly; less efficient than flags
- Recommendation: Start with flags (faster iteration); migrate if LLM cost acceptable

#### 8.3 Object Taxonomy & Containment
- Five core types: Room, Item, Container, Door, Actor
- Rules: no circular containment; weight limits; closed containers hide contents
- Standard hooks: `on_look`, `on_take`, `on_enter`, etc.
- Proven by Inform 7 and TADS; prevents logic errors

#### 8.4 Player-Per-Universe Model (Multiverse)
- Each player gets parallel universe by default; isolated unless explicitly merged
- Merge triggers: cooperative boss, trading hub, rift portal, summoning ritual (all voluntary)
- Conflict handling: owner's universe canonical; merge takes A's version of shared objects
- Implications: DB must support versioning; session manager tracks universe_id per player

#### 8.5 Narrative: Main Quest + Sandbox
- Balance authored story (main quest) with player freedom (sandbox, side quests)
- Main quest: linear story beats, core NPCs, climax
- Sandbox: optional puzzles, trading, exploration
- Implications: design both main arc AND open-world; NPCs need personality + dialogue trees

#### 8.6 Moral Choices & Permanent Consequences
- Player choices are permanent and change world code (via mutation)
- Example: betray NPC → NPC's code changes (faction, dialogue, behavior)
- No undo beyond loading old save; increases player investment
- Recommendation: allow save/load to multiple slots for experimentation

**Open Design Questions:**
- Combat system: turn-based vs real-time? verbs or mechanics? (→ Turn-based, verb-based, Phase 1)
- Magic system: LLM-generated? sandboxed Lua? verb aliases? (→ High-level verbs triggering LLM effects)
- Persistence format: Lua source? JSON snapshots? both? (→ JSON snapshots + optional Lua export)
- NPC AI: static? reactive? proactive? (→ Reactive for Phase 1)
- Universe scale: hard one-player constraint or soft? (→ Soft; owner + temporary merges)

**Alignment with Prior Decisions:**
✅ Containment hierarchies (Frink) — parent-child tree model  
✅ Lua scripting (Frink) — code-as-data blending  
✅ Multiverse model (Wayne) — concrete merge mechanics  
✅ Code mutation (Wayne) — engine-driven, not player-driven  
✅ Text-based interaction (Wayne) — verb-based parser  

**Design Document:** `docs/design/game-design-foundations.md`

**Next Steps:** Engineer feasibility review (code mutation + Lua); PM database schema review; narrative outline; Phase 1 scope narrowing; parser + verb dispatcher prototype.

**Decision Ready for Team Review** ✓

---

### 9. Directive: LLM-Written Code — Complexity Not a Factor

**Author:** Wayne "Effe" Berry  
**Date:** 2026-03-19  
**Type:** Architecture Directive  
**Status:** Active  

All code in this project will be written by the LLM. Therefore, implementation complexity is NOT a factor when choosing languages, systems, or architectures. Choose the best tool for the job regardless of learning curve or code complexity.

---

### 10. Directive: Multiverse MMO Architecture (User Direction)

**Author:** Wayne "Effe" Berry  
**Date:** 2026-03-19  
**Type:** Architecture Direction (Exploratory)  
**Status:** Active  

The MMO operates as a **multiverse** — an infinite set of parallel universes. Each player exists in their own universe by default (NOT a shared 40-player lobby). Players can be pulled or pushed into a shared universe with other players (conditions TBD). Resources are NOT scarce across the multiverse — each universe has its own state.

**Key Constraints:**
- No shared-world lobby model
- Infinite universe scaling (not fixed instances)
- Universe forking/merging must be first-class concept
- Per-universe state isolation is the default

**Alignment:** Formalized in Decision 7 (Multiverse MMO Architecture).

---

### 11. Directive: Self-Modifying Universe Code

**Author:** Wayne "Effe" Berry  
**Date:** 2026-03-19  
**Type:** Architecture Direction (Exploratory)  
**Status:** Active  

The game language should be **self-modifying** — player actions can change the source code of their universe. Player interactions mutate the actual code/data files that define the universe (in a restricted/sandboxed way). The universe literally evolves through play — the code IS the world state. "Saving the game" = saving the modified source files.

**Key Implications:**
- Language must support safe, restricted self-modification (not arbitrary injection)
- Player actions = code transformations (e.g., picking up sword modifies room source)
- Universe divergence is literally source code divergence
- Code IS runtime state (not just scripting)
- Connects to homoiconicity (code that inspects and rewrites itself)

**Alignment:** Operationalized in Decision 8.2 (Code Mutation Over State Flags).

---

### 12. Directive: Engine-Driven Code Mutation, Not Player-Driven

**Author:** Wayne "Effe" Berry  
**Date:** 2026-03-19  
**Type:** Design Directive (Clarification)  
**Status:** Active  

**Key Distinction:**
- ❌ Player modifies code directly
- ✅ Player interacts naturally → engine modifies code on their behalf
- Code changes are a consequence of gameplay, not a player authoring tool

**Example:** Mirror object exists in code. When player types "break mirror," the engine rewrites the mirror's code to reflect its broken state. The player never touches code — they interact naturally; the engine translates their actions into code mutations.

**Open Question:** Is mutating code the right approach, or should state changes use property flags instead? Still being explored.

**Alignment:** Formalized in Decision 8.2; implementation details TBD.

---

### 13. Directive: Ghost Mechanic for Inter-Universe Interaction

**Author:** Wayne "Effe" Berry  
**Date:** 2026-03-19  
**Type:** Design Direction (Exploratory)  
**Status:** Active  

**Vision:** Players from other universes appear as **ghosts** — visible but unable to modify objects. Ghosts CANNOT interact with host universe's objects. The host player can choose to **transform** a ghost into a full participant in their universe. Even after transformation, safeguards needed to prevent griefing.

**Constraints:**
- No "lobby of ghosts" — don't want 40 spectral players cluttering experience
- No universe-hopping to grief — players can't jump to someone's universe to break things
- Ghost visibility limited/curated (not every online player appears)
- Transformation is deliberate, host-initiated action

**Open Questions:**
- How many ghosts can appear at once? (1? 3? context-dependent?)
- What triggers ghost visibility? (proximity? shared quest? random?)
- What permissions does transformed player get? (full? limited? time-boxed?)
- Can host revoke transformation (eject player back to ghost/their universe)?
- Do ghosts see host universe state, or filtered version?

**Alignment:** Refinement of multiverse model (Decision 7, 10); coordinates with universe merging mechanics.

---

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
