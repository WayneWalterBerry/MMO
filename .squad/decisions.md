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

---

### 14. Architecture Decision: Code Rewrite Mutation Model (2026-03-18)

**Author:** Wayne "Effe" Berry  
**Date:** 2026-03-18  
**Status:** Approved  
**Firmness:** FIRM  
**Risk Level:** LOW  

**Decision:** Full rewrite mutation model. When game state changes, the object's definition/code is literally transformed — "the code IS the state." No separate state flags. The old definition ceases to exist and is replaced by the new one.

**Rationale:** 
- Aligns with the meta-code vision where code and data are blended
- No distinction between "the object" and "the object's state"
- Philosophically pure; creates emergent, magical player experience
- More semantically honest than flag-based mutations

**Implementation Notes:**
- Requires careful state serialization and undo/redo handling
- Version tagging for saved games vs. mutated instances needed
- Immutable baseline + mutable overlays pattern recommended (don't rewrite baseline)

**Mitigation:** Prototype mutation mechanics early (first 2 weeks of engine dev)

---

### 15. Architecture Decision: Meta-Code Format (2026-03-18)

**Author:** Wayne "Effe" Berry  
**Date:** 2026-03-18  
**Status:** Deferred  
**Firmness:** SOFT  
**Risk Level:** HIGH  

**Current Status:** "Likely Lua tables/closures" but not formalized

**Options Being Considered:**
1. Pure Lua source (saveable via `string.dump` or as `.lua` files)
2. JSON representation of Lua tables (cleaner for LLM, harder to execute)
3. Hybrid (templates in Lua, mutations in JSON)

**Why it Matters:**
- Affects serialization strategy (Lua source vs. JSON)
- Affects LLM mutation capability
- Affects hot-reload mechanics
- Gates template authoring work

**Recommendation:** Lock this down by end of week 1 of Phase 1. Multiple parallel prototypes may be needed to decide.

---

### 16. Architecture Decision: Engine Language is Lua (2026-03-18)

**Author:** Wayne "Effe" Berry  
**Date:** 2026-03-18  
**Status:** Approved  
**Firmness:** FIRM  
**Risk Level:** LOW  

**Decision:** Lua for both engine core AND meta-code (universe templates). Single language stack.

**Rationale:**
- Industry standard for game scripting
- Homoiconic properties support self-modifying code patterns
- Removes language boundary and serialization impedance mismatch
- LLM proficiency with Lua well-established

**Benefits:**
- Simpler dev workflow, faster iteration
- Universe divergence is literally source code divergence
- No bridging complexity between engine and game logic

---

### 17. Architecture Decision: Universe Templates Generated at Build Time (2026-03-18)

**Author:** Wayne "Effe" Berry  
**Date:** 2026-03-18  
**Status:** Approved  
**Firmness:** FIRM  
**Risk Level:** LOW  

**Decision:** Universe templates are generated once at build time via LLM, hand-tuned by designers, then procedurally varied per player.

**Rationale:**
- Eliminates per-player LLM calls (HUGE cost savings: ~$5K–10K/month estimated)
- Hand-tuning ensures quality at build time
- Procedural variation (seeded) provides replay differentiation
- Aligns with "all code written by LLM" directive without per-player overhead

**Implementation:**
- LLM generates base template + variation rules at build time
- Designers hand-tune templates for quality
- Each player's universe seeded for deterministic but varied content

**Limitations:**
- Mutations generated once at build time
- Changes to game logic require rebuilding
- Acceptable trade-off; plan post-launch content patches

---

### 18. Architecture Decision: Cloud Persistence Storage (2026-03-18)

**Author:** Wayne "Effe" Berry  
**Date:** 2026-03-18  
**Status:** Approved  
**Firmness:** FIRM  
**Risk Level:** MEDIUM  

**Decision:** Player universe state persists to cloud storage (not local only).

**Rationale:**
- Enables cross-device play
- Supports "The Company" narrative infrastructure
- Allows analytics pipeline for game design insights

**Infrastructure Required:**
- Database schema (universe state, mutations, player analytics)
- Authentication + rate limiting
- Sync protocol (merge conflicts, consistency)
- Cost monitoring for analytics storage growth

**Recommendation:** Design infrastructure first; prototype with minimal dataset. Use CRDT or event-sourced log to avoid merge conflicts.

---

### 19. Architecture Decision: Parser Approach (2026-03-18)

**Author:** Wayne "Effe" Berry  
**Date:** 2026-03-18  
**Status:** Deferred  
**Firmness:** SOFT  
**Risk Level:** MEDIUM  

**Decision:** Parser approach deferred between two viable options: NLP or rich synonyms.

**Options:**
- **Option A:** NLP-based parsing (costs tokens; feels smarter)
- **Option B:** Rule-based rich synonyms (costs dev time; feels predictable)
- **Stretch Goal:** Local LLM parser (ggml or ollama)

**Why Deferred:** Both paths viable with different cost/complexity profiles.

**Recommendation:** 1-week prototype race (week 1 of Phase 1):
- Prototype 1: Rule-based rich synonyms for 10 core verbs
- Prototype 2: Call LLM parser via API
- Prototype 3 (if time): Local LLM parser
- Pick winner based on accuracy + cost + dev velocity

---

### 20. Architecture Decision: Ghost Visibility (Fog of War) (2026-03-18)

**Author:** Wayne "Effe" Berry  
**Date:** 2026-03-18  
**Status:** Approved  
**Firmness:** FIRM  
**Risk Level:** LOW  

**Decision:** Ghosts see only the current room. Room-scoped visibility enforced (fog of war).

**Rationale:**
- Simplifies networking (no large-area state sync needed)
- Reduces network bandwidth
- Design choice accepted; not a technical constraint

**Limitations:**
- Removes exploration-as-shared-experience
- May feel limiting for cooperative play

**Mitigation:** Compensate with rich shared-room interactions

---

### 21. Architecture Decision: No Universe Merge (MVP Scope) (2026-03-18)

**Author:** Wayne "Effe" Berry  
**Date:** 2026-03-18  
**Status:** Approved  
**Firmness:** FIRM  
**Risk Level:** MEDIUM  

**Decision:** Ghost joins host's universe; host's universe does NOT merge with ghost's original universe. Each universe maintains independent state.

**Rationale:**
- Eliminates OT, CRDT, or last-write-wins conflict resolution complexity
- Simplifies network sync protocol significantly
- Scope reduction: ~2 weeks of engineering effort saved

**Limitations:**
- Caps social play (raids, shared dungeons limited)
- Players may feel isolated early on

**Mitigation:**
- Design "opt-in merge" UX early (future feature)
- Prototype small-scale merge for 2-player raids post-MVP
- Monitor player feedback; iterate based on usage

---

### 22. Game Design Decision: Mutation is Authoritative State (2026-03-19)

**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-03-19  
**Status:** Proposed (awaiting team review)  
**Firmness:** FIRM  
**Risk Level:** MEDIUM  

**Decision:** World state is represented by mutated Lua code, not Boolean flags. When the mirror breaks, `mirror.description` changes in the source. When the door unlocks permanently, the Door object becomes an OpenExit.

**Rationale:** 
- This is the defining mechanic of the game
- Flags-plus-templates produce "Zork Lite"
- Actual code mutation produces a genuinely self-modifying world

**Risk:** More expensive to implement. LLM generates mutations; requires sandboxed execution.

**Fallback:** Flags for Phase 1, migrate to mutation in Phase 2

**Vote Needed From:** Engineers (feasibility), Wayne (cost/timeline tradeoff)

---

### 23. Game Design Decision: Double-Opt-In Merge Consent (2026-03-19)

**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-03-19  
**Status:** Proposed (awaiting team review)  

**Decision:** Player-initiated universe merges require explicit acceptance from both players. World-triggered rift events are opt-out (player can DECLINE), not opt-in.

**Rationale:** 
- Forced merges enable griefing and destroy the personal-universe promise
- This is a social contract decision

**Impact:** Multiverse event system, UI for merge invitation

**Vote Needed From:** Wayne (product philosophy), Engineers (implementation)

---

### 24. Game Design Decision: NPC Death Permanence (2026-03-19)

**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-03-19  
**Status:** Proposed (awaiting team review)  

**Decision:** When a player kills an NPC, that NPC is permanently dead in their universe. The NPC's services, quests, and dialogue are gone.

**Rationale:** 
- Consequence = investment (Ultima IV proved this)
- Skyrim's essential NPCs proved the opposite — players feel nothing when they can't affect the world

**Risk:** Players can softlock their own universe by killing quest-critical NPCs.

**Mitigation:** 
- Quest-critical NPCs warn before combat: "This NPC is important. Are you sure?"
- OR quest has a fallback path that functions without the NPC

**Vote Needed From:** Wayne (design philosophy), Engineers (NPC state persistence)

**Alignment:** Refinement of multiverse model (Decision 7, 10); coordinates with universe merging mechanics.

---

### 14. Mutation Model: True Code Rewrite (2026-03-19)

**Author:** Wayne "Effe" Berry  
**Status:** Active  
**Impact:** Engine architecture — defines how object state changes work  
**Resolves:** Open question from Decision 12 (flags vs. code mutation)

When a player breaks a mirror, the engine rewrites the object definition entirely. The mirror becomes a fundamentally different entity (e.g., `broken_mirror`), not a flag flip on the same object. This is a **true code rewrite** — the old entity ceases to exist and a new one takes its place in the world model.

**Implications:**
- Engine must support full entity replacement, not just property updates
- Object identity changes on mutation (old ID → new ID)
- Containment tree must handle entity replacement gracefully
- Supersedes the "start with flags" recommendation in Decision 8.2

---

### 15. Meta-Code Format: Deferred — Likely Lua Tables/Closures (2026-03-19)

**Author:** Wayne "Effe" Berry  
**Status:** Deferred (leaning Lua tables/closures)  
**Impact:** Engine internals — representation of mutable world definitions  

Not yet formally decided, but since Lua was chosen as the engine language (Decision 16), the meta-code representation will likely be **Lua tables and closures**. This keeps engine and world definition in the same language with no serialization boundary.

**Open for:** Final confirmation once prototyping begins.

---

### 16. Engine Language: Lua (2026-03-19)

**Author:** Wayne "Effe" Berry  
**Status:** Active  
**Impact:** Foundational — affects all engine and world code  
**Confirms:** Decision 6 recommendation (Frink's Lua research)

Lua for **both** the engine AND the meta-code. Lua can rewrite and re-interpret itself via `loadstring()`. There is no boundary between engine code and meta-code — they are the same language, the same runtime, the same representation.

**Key Properties:**
- Self-modifying via `loadstring()` / `load()`
- Tables unify code and data (prototype-based)
- ~200 KB runtime, embeddable
- Industry-proven (WoW, Roblox, LÖVE, Defold)

---

### 17. Universe Templates: LLM Once at Build Time + Hand-Tuning + Procedural Variation (2026-03-19)

**Author:** Wayne "Effe" Berry  
**Status:** Active  
**Impact:** Content pipeline, cost model, player experience  

**Pipeline:**
1. **Build time:** LLM generates a canonical universe template once when the game ships
2. **Hand-tuning:** Humans review and alter the template to improve quality
3. **Player start:** Procedural variation creates a unique multiverse instance per player

**Key Constraint:** No per-player LLM token cost. The LLM is a build tool, not a runtime dependency. Players get unique worlds through deterministic procedural variation from the hand-tuned template, not from individual LLM calls.

**Implications:**
- Need a procedural variation system (seeds, parameter ranges)
- Template format must support parameterized variation points
- Quality depends on the template + variation design, not on LLM quality at runtime

---

### 18. Persistence: Cloud Storage (2026-03-19)

**Author:** Wayne "Effe" Berry  
**Status:** Active  
**Impact:** Infrastructure, data model, multiplayer architecture  

Mutated universe state is persisted in the cloud so players can resume across sessions and devices. Cloud persistence also enables **"The Company"** (in-game meta-entity) to analyze how player worlds evolve over time.

**Implications:**
- Need cloud storage service (specific provider TBD)
- Serialization format for mutated Lua state must be cloud-friendly
- "The Company" analytics pipeline can process universe snapshots
- Replaces local-only SQLite persistence model from Decision 5

---

### 19. Parser: NLP or Rich Synonyms — No Simple Verb-Noun (2026-03-19)

**Author:** Wayne "Effe" Berry  
**Status:** Active (details TBD)  
**Impact:** Player interaction model, engine complexity  

The parser will NOT be simple verb-noun. Two acceptable approaches:
1. **Natural language processing** — full NLP parsing of player input
2. **Structured commands with extensive synonym/alias mapping** — rich synonym tables that make structured commands feel natural

**LLM-powered parsing** is acceptable only if running locally (no per-interaction token cost). Local LLM is a **stretch goal**, not a requirement.

**Supersedes:** Decision 3's "simple tokenizer + verb dictionary" recommendation.

---

### 20. Ghost Visibility: Fog of War (2026-03-19)

**Author:** Wayne "Effe" Berry  
**Status:** Active  
**Impact:** Multiplayer architecture, networking, streaming  
**Refines:** Decision 13 (Ghost Mechanic)

Ghosts (players from other universes) only see the **immediate vicinity** — the current room or area — not the whole universe. This is a fog-of-war model applied to inter-universe observation.

**Benefits:**
- Efficient for streaming — only current room state needs to be shared
- Reduces information overload for ghost players
- Limits scouting/griefing potential
- Simplifies network sync (room-scoped, not universe-scoped)

---

### 21. Universe Merge: No Merge (2026-03-19)

**Author:** Wayne "Effe" Berry  
**Status:** Active  
**Impact:** Multiplayer architecture, simplifies universe interaction model  
**Supersedes:** Decision 7's merge/conflict resolution roadmap

When a ghost is **transformed** into a full participant in a host's universe, they simply join as-is. Their own universe **pauses** separately — it doesn't merge, blend, or conflict-resolve with the host universe.

**Key Properties:**
- No complex merge/conflict resolution needed
- Ghost's home universe is frozen in place, resumable later
- Host universe is canonical — the transformed player plays in it
- Dramatically simplifies the multiverse interaction model
- Removes need for CRDTs, OT, or last-write-wins conflict handling

---

### 22. Object Inheritance / Template System + Weight/Categories/Multi-Surface (2026-03-19)

**Author:** Bart (Architect)  
**Status:** Implemented  
**Impact:** Architecture-level; affects object definitions, loader, registry, containment, mutation  

**Decision:** Three interlocking systems added to the engine:

1. **Template Inheritance** — Objects can declare `template = "sheet"` to inherit base properties. The loader deep-merges the template under instance overrides. Instance always wins.

2. **Weight + Categories** — All objects now carry `weight` (number) and `categories` (table of strings). Containers carry `weight_capacity`. The containment validator checks weight alongside size.

3. **Multi-Surface Containment** — Objects can define `surfaces = { top = {...}, inside = {...} }` to support multiple containment zones. Each zone has its own capacity, max_item_size, weight_capacity, and accessibility flag.

**Template System:**
| Template | Purpose | Key defaults |
|----------|---------|-------------|
| `sheet.lua` | Fabric/cloth family | size 1, weight 0.2, portable, tearable |
| `furniture.lua` | Heavy immovable objects | size 5, weight 30, not portable |
| `container.lua` | Bags, boxes, chests | container true, capacity 4, weight_capacity 10 |
| `small-item.lua` | Tiny portable items | size 1, weight 0.1, portable |

**Engine Changes:**
| File | Changes |
|------|---------|
| `engine/loader/init.lua` | Added `resolve_template()`, `load_template()`, `deep_merge()` |
| `engine/registry/init.lua` | Added `find_by_category()`, `total_weight()`, `contents_weight()` |
| `engine/containment/init.lua` | Enhanced with weight + multi-surface validator |
| `engine/mutation/init.lua` | Surface content preservation, optional template re-resolution |

**Rationale:**
- Templates are single-level (not deep inheritance chains) to avoid debugging nightmares
- Weight is continuous, not tiered — exact values for realistic stacking
- Surfaces use `accessible` flag (not absence) — locked drawer still has contents
- Template resolution is loader concern — registry doesn't need to know about templates

---

### 23. V1 REPL Architecture (2026-03-20)

**Author:** Bart (Architect)  
**Status:** Implemented  
**Impact:** Full stack — engine wiring, verb system, light/time systems  

**Decision:** Built three new files that wire the existing engine into a playable game:

1. **Object sources as mutation fuel** — All object `.lua` files loaded as raw strings at startup, indexed by ID. Mutation variants (vanity-open, candle-lit, etc.) exist as dormant strings until a verb triggers them. No filesystem access at runtime.

2. **Verbs module returns a factory** — `verbs.create()` returns a handler table. No closures over context; handlers receive `ctx` as a parameter from the loop. Clean dependency injection.

3. **Light via object properties** — `casts_light = true` (candle-lit) and `allows_daylight = true` (open curtains). No light "system" — just property checks in the verb layer. Easy to extend.

4. **Real-time game clock** — `os.time()` delta × 24 = game seconds. No tick-based advancement. Time is always accurate, even between commands.

5. **Exit mutations are partial merge, object mutations are full replacement** — Exits modify fields in-place. Objects swap the entire registry entry. Different semantics for different structural roles.

**Consequences:**
- The game is playable now. `lua src/main.lua` from repo root.
- Future verbs just add handlers to the verbs module.
- Future rooms just need a room file + placement in a room graph.
- Light/time systems are intentionally minimal — extend when needed.

**Files Created:**
- `src/main.lua` — entry point
- `src/engine/verbs/init.lua` — verb handlers
- `src/meta/templates/room.lua` — room template

---

### 24. Bedroom Design Patterns (2026-03-20)

**Author:** Comic Book Guy (Game Designer)  
**Status:** Implemented  
**Impact:** Object model, engine requirements  

**Decision:** Established five core design patterns for the bedroom:

1. **Multi-Surface Containment Model** — Objects with multiple interaction zones use `surfaces` instead of flat `contents`. Each surface has `capacity`, `max_item_size`, and `contents`. Examples: bed (top, underneath), nightstand (top, inside), vanity (top, inside, mirror_shelf), rug (underneath).

2. **Composite Mutation Matrix** — When an object has N independent toggleable properties, it requires 2^N mutation files. The vanity has 2 axes (drawer open/closed, mirror intact/broken) = 4 files. Each is a complete standalone object definition.

3. **Template Inheritance for Object Families** — Objects that share a base type use `template = "sheet"` to inherit default properties. Instance overrides win. Used for: bed-sheets, curtains.

4. **Hidden Object Discovery Pattern** — Objects can contain hidden items (rug → brass-key underneath). The `on_look` function should hint at hidden content without revealing it. Separate verbs (LOOK UNDER, SEARCH) expose hidden contents.

5. **Room Object Hierarchy** — Room `contents` lists top-level furniture. Portable items live inside furniture surfaces, not directly in the room. This creates a natural discovery hierarchy: enter room → see furniture → examine furniture → find items.

6. **Bedroom as Start Room** — The player now starts in a bedroom instead of a study. More natural for a "waking up" narrative opening and provides immediate interactive objects.

**Objects Created:**
- Vanity (4 variants: open, closed, mirror-broken, open+broken)
- Bed, pillow, bed-sheets, blanket
- Nightstand (2 variants: open, closed with matchbox)
- Candle (2 variants: dark, lit)
- Wardrobe (2 variants: open, closed)
- Rug with brass key underneath
- Curtains (2 variants: closed, open with daylight)
- Window, chamber-pot, wool-cloak

---

### 25. Tool Object Convention (requires_tool / provides_tool) (2026-03-20)

**Author:** Comic Book Guy (Game Designer)  
**Status:** Proposed  
**Impact:** Engine verb resolution, object schema, puzzle design  
**Firmness:** FIRM  
**Risk Level:** LOW  

**Decision:** Introduce a **tool convention** for objects that enable verb actions on other objects:

- **`requires_tool = "capability"`** on mutation targets — declares that a verb/mutation needs a tool with a specific capability
- **`provides_tool = "capability"`** on tool objects — declares what capability this tool provides

The engine resolves tool requirements by searching the player's inventory for any object whose `provides_tool` matches the target's `requires_tool`. This is **capability matching**, not item-ID matching.

**How It Differs from `requires` (Key Pattern):**

| Pattern | Matches by | Example |
|---------|-----------|---------|
| `requires = "item-id"` | Specific item ID | Brass key → bedroom door |
| `requires_tool = "capability"` | Any provider of capability | Matchbox (fire_source) → candle |

**Consumable Tools:**

Tools can have limited charges via the `charges` property and `on_tool_use` block. Charge decrement follows D-14 (full code rewrite). When depleted, the tool mutates to its `when_depleted` variant.

**First Implementation:**

- `matchbox.lua` — provides `fire_source`, 3 charges, depletes to `matchbox-empty.lua`
- `candle.lua` — mutation `light` requires_tool `fire_source`, mutates to `candle-lit.lua`
- `candle-lit.lua` — gains `casts_light = true` for the light/dark system

**Engine Requirements:**

1. When processing a mutation with `requires_tool`, search player inventory for matching `provides_tool`
2. Handle both string and list values for `provides_tool`
3. Compose tool use messages with target mutation messages
4. Rewrite tool charges per D-14 code mutation model
5. Mutate depleted tools to their `when_depleted` variant

**Rationale:**
- Proven pattern: Zork's torch, Monkey Island's tools, Inform 7's "doing it with" rules
- Capability matching is more extensible than item-ID matching
- Consumable charges create resource tension and meaningful player choices
- Integrates cleanly with existing mutation and code-rewrite systems
- Does not break any existing patterns (additive, not breaking)

---

### 26. Lua Hosting Platform (2026-03-20)

**Author:** Frink (Researcher)  
**Status:** Proposed  
**Priority:** High  
**Impact:** Architecture-level; affects how players access the game  

**Proposal:** Adopt **Wasmoon (Lua 5.4 → WebAssembly) + Progressive Web App** as the primary host platform for delivering the game to players' phones and browsers.

**Phase 1 (Prototype): PWA with Wasmoon**
- HTML/CSS/JS host application runs Lua engine via Wasmoon in browser
- PWA manifest + service worker for installability and offline play
- Deploy to any static host (GitHub Pages, Netlify)
- **Timeline: 3 days to playable prototype on phones**

**Phase 2 (App Store): Capacitor wrapping**
- Same codebase wrapped in Capacitor for iOS App Store + Google Play Store
- Add native features: push notifications, haptics, storage
- **Timeline: 2 weeks to store submission**

**Phase 3 (Future): Defold migration (if needed)**
- Only if graphical elements become important
- Lua engine code transfers directly to Defold

**Rationale:**
1. HTML/CSS is the best text rendering engine available — superior to any game engine for our text adventure
2. Wasmoon runs our existing Lua engine files unmodified
3. PWA = fastest distribution (URL sharing, no app store approval)
4. Capacitor provides App Store path when ready
5. Performance is a non-issue — text adventures need <2ms per command cycle

**Aligns With:**
- Decision 16: Engine language is Lua (FIRM)
- Decision 18: Cloud persistence (FIRM)
- Decision 14: Code rewrite mutation model (FIRM)
- Decision 9: LLM-written code, complexity not a factor
- Decision 10: Multiverse per-player universes

**Needs Review From:**
- Wayne "Effe" Berry (Product Owner)
- Gil (Lead Engineer) — for implementation feasibility

---

## User Directives (Captured 2026-03-19)

### D-25: V1 Play Test Scope (2026-03-19T012051Z)

**By:** Wayne "Effe" Berry  
**What:** Single room, breakable objects, text REPL. That's the first playable version. Goal is to get to play test as fast as possible.

### D-26: Light and Time Systems (2026-03-19T012411Z)

**By:** Wayne "Effe" Berry  
**What:**
1. **Light system:** There is light in the game. Some objects cast light (e.g., torch, candle). Outside areas during daytime have natural light. Inside areas need either a window to daytime OR objects that cast light.
2. **Time system:** The game has time, and it moves faster than real time. One real-time hour = one full in-game day.

### D-27: Keep Docs Current (2026-03-19T013009Z)

**By:** Wayne "Effe" Berry  
**What:** Keep the architecture and design docs up to date as decisions and implementation progress. Docs should reflect current state, not lag behind.

### D-28: Newspaper Format (2026-03-19T013254Z)

**By:** Wayne "Effe" Berry  
**What:** Every daily newspaper edition must include a comic strip and an op-ed piece. These are recurring sections, not one-offs.

### D-29: Fire Source for Lighting (2026-03-19T014223Z)

**By:** Wayne "Effe" Berry  
**What:** You need a match (or similar fire source object) to light the candle. Players can't just "light candle" from nothing — they need to find/have a fire source item first. This is a gameplay constraint and puzzle element.

### D-30: Paper and Writing System (2026-03-19T014604Z)

**By:** Wayne "Effe" Berry  
**What:** There should be a sheet of paper object that words can be written on. Writing requires a tool: pen, pencil, or blood. The paper + writing instrument interaction is another tool-based verb pattern (WRITE ON {paper} WITH {instrument}). Blood as a writing instrument implies injury or a blood source — dark gameplay element.

### D-31: Paper Mutation on Writing (2026-03-19T014629Z)

**By:** Wayne "Effe" Berry  
**What:** The paper object is mutable — when words are written on it, the paper's definition mutates to include those words. "WRITE hello ON paper WITH pen" → the paper object's code is rewritten to include "hello" in its description/content. This is the code-mutation model applied to player-authored content. The paper literally becomes a different object (paper-with-writing) via the mutation engine.

### D-32: Blood as Writing Instrument (2026-03-19T014726Z)

**By:** Wayne "Effe" Berry  
**What:** A player can cut themselves with a knife (a tool) or prick themselves with a pin (another tool) to draw blood. Blood is a writing instrument for the paper. The knife and pin are tools in the "injury_source" category — they provide blood as a resource. This creates a tool chain: knife/pin → blood → write on paper. The player must actively choose to injure themselves to get the writing material. Dark, consequential, intentional.

### D-33: Player Skills System (2026-03-19T014811Z)

**By:** Wayne "Effe" Berry  
**What:** Introduce a player skills system. Players can learn skills (e.g., lockpicking). A skill unlocks new tool+verb combinations that weren't available before. Example: without lockpicking skill, a pin is just a pin. WITH lockpicking skill, a pin becomes a tool that can PICK LOCK on a door — an alternative to using the brass key. Skills are learned through gameplay (finding a book, practicing, being taught by an NPC, etc.).

### D-34: Puzzle-First Design Philosophy (2026-03-19T015115Z)

**By:** Wayne "Effe" Berry  
**What:** Making puzzles is good. When designing objects, rooms, and mechanics, the team should actively think about puzzle design — how objects interact, what requires what, what chains of actions lead to discoveries. Puzzles are a first-class design goal, not a side effect.

### D-35: Single-File vs. Multi-File Mutation Objects (2026-03-19T015239Z)

**By:** Wayne "Effe" Berry  
**Status:** OPEN QUESTION  
**What:** Questioning the separate-file mutation variant pattern (nightstand.lua + nightstand-open.lua as two files). Maybe objects should be a single file with states instead of multiple files. The nightstand open/closed is the same object with different states — not two different objects. This potentially challenges Decision 14 (true code rewrite) or at least how we implement it. The question is: does "code rewrite" mean "swap the entire file" or can it mean "mutate properties within the same object definition"?

### D-36: Sewing as Crafting Skill (2026-03-19T015318Z)

**By:** Wayne "Effe" Berry  
**What:** Sewing is a player skill. With sewing skill + a needle (tool), a player can craft cloth into clothing. This introduces crafting as a skill-gated activity. Cloth already exists as an object in the bedroom (cloth.lua). With sewing skill, cloth becomes a raw material that can be transformed into wearable items. Without sewing skill, cloth is just cloth. Needle is the tool that provides "sewing_tool" capability.

---

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction

## Merged from Inbox (2026-03-21)

---
# Decision: Game Start Time + Sensory Verb System

**Author:** Bart (Architect)  
**Date:** 2026-03-21  
**Status:** IMPLEMENTED

## Game Start Time: 2 AM

Changed from 6 AM to 2 AM. The player now wakes in absolute darkness. Dawn at 6 AM arrives after ~10 real minutes (at 24x game speed). This forces the candle puzzle — players cannot simply LOOK around, they must FEEL, SMELL, LISTEN their way to the candle and matches.

## Sensory Verb Convention

All sensory verbs work in complete darkness. Objects support these optional fields:

| Field | Verb | Light required? |
|-------|------|----------------|
| `on_feel` | FEEL/TOUCH | No |
| `on_smell` | SMELL/SNIFF | No |
| `on_taste` | TASTE/LICK | No |
| `on_taste_effect` | (triggered by TASTE) | No |
| `on_listen` | LISTEN/HEAR | No |

Room-level ambient fields: `room.on_smell`, `room.on_listen`.

Objects without these fields get graceful defaults ("nothing distinctive", "makes no sound", etc.).

## Poison Mechanic (V1)

`on_taste_effect = "poison"` → immediate death. Future: antidote, timed effects, partial poisoning.

## Team Impact

- **Comic Book Guy:** Add `on_feel`, `on_smell`, `on_taste`, `on_listen` fields to objects. `on_taste_effect` on dangerous items. `on_smell` and `on_listen` on start-room.
- **All:** LOOK still requires light. All other senses do not.

---
# Decision: V2 Verb Handlers — Tool Pipeline & Dynamic Mutation

**Author:** Bart (Architect)  
**Date:** 2026-03-20  
**Status:** IMPLEMENTED

## Context

V1 REPL had 12 verbs but no tool-capability resolution. Comic Book Guy created tool objects (pen, knife, pin, needle, matchbox, paper) with `provides_tool`/`requires_tool` convention. Engine needed verb handlers that resolve tools by capability, consume charges, and — critically — perform the first dynamic mutation (WRITE on paper).

## Decisions

### D-37: Tool Resolution is a Verb-Layer Concern
Tool-finding helpers (`find_tool_in_inventory`, `provides_capability`, `consume_tool_charge`) live in `engine/verbs/init.lua` as local functions, not in a separate engine module. Rationale: tool resolution is tightly coupled to verb dispatch logic. If tool resolution becomes needed outside verbs (e.g., NPC actions), extract then.

### D-38: Dynamic Mutation via string.format + %q
The WRITE verb generates Lua source at runtime using `string.format()` with `%q` for player-provided text. This sanitizes arbitrary player input through Lua's own string escaper. The generated source includes a runtime `on_look` function (reads `self.written_text` at call time) and preserves the `write` mutation entry for appending more text. Generated source is stored back in `object_sources` for future mutation chains.

### D-39: Blood as Virtual Tool
When `player.state.bloody == true`, the tool resolver returns a synthetic tool object (not registered, not in inventory) that provides `writing_instrument`. This keeps the world model clean — blood isn't an inventory item, it's a player state that enables a capability.

### D-40: CUT vs PRICK Capability Split
CUT SELF requires `cutting_edge` (knife only). PRICK SELF requires `injury_source` (pin or knife). Both produce the same `bloody` state. This gives the player two paths to the same result with different tools and different narrative weight.

### D-41: Future Verb Stubs (SEW, PICK LOCK)
Stubbed with "you don't know how to" messages that hint at a learnable skill system. When the skill system ships, these stubs become the integration points.

## Impact
- Enables the full chain: find knife → cut self → write in blood on paper → read paper
- Enables: find matchbox → light candle (with charge tracking)
- Sets pattern for all future tool-gated verbs

---
# Decision: Multi-Sensory Object Convention

**Proposed by:** Comic Book Guy (Game Designer)
**Date:** 2026-03-20
**Status:** Proposed
**Requested by:** Wayne "Effe" Berry

## Summary

All objects now carry multi-sensory description fields (`on_feel`, `on_smell`, `on_taste`, `on_listen`) in addition to visual `description`. These enable the dark-room mechanic where players use non-visual senses to navigate, identify objects, and make risk/reward decisions.

## Decision

1. **Every object MUST have `on_feel`** — it is the primary dark-navigation sense.
2. **`on_smell` is recommended** for objects with distinctive scents — it is the safe identification sense.
3. **`on_listen` is for active/mechanical objects only** — things that make sounds when interacted with.
4. **`on_taste` is the danger sense** — reserved for objects where tasting has real consequences. Rarity is intentional.
5. **`on_feel_effect` and `on_taste_effect`** trigger engine-level state changes (e.g., `"cut"` from glass shard, `"poison"` from poison bottle). The engine must check for `_effect` suffixes on all sensory fields.

## Sensory Hierarchy

| Sense | Safety | Information | Coverage |
|-------|--------|-------------|----------|
| FEEL | Medium | Shape, texture, temperature, weight | 100% |
| SMELL | Safe | Chemical identity, materials, age | ~65% |
| LISTEN | Safe | Mechanical state, contents, environment | ~16% |
| TASTE | DANGEROUS | Chemical composition — at a cost | ~8% |

## Design Philosophy

- Darkness is not a wall — it's a different mode of play
- Every sense gives different information about the same object
- SMELL is the safe way to identify liquids and chemicals
- TASTE is the "learn by dying" sense — real consequences, teaches caution
- The poison bottle is the canonical teaching moment: SMELL warns you, TASTE kills you

## Impact

- Engine must implement FEEL, SMELL, TASTE, LISTEN verbs that read corresponding `on_*` fields
- Engine must check for `_effect` suffixes and apply state changes
- All future objects must include at least `on_feel`
- Mutation variants must carry their own sensory fields (state-dependent)

## Files Changed

- 36 existing objects in `src/meta/objects/` updated with sensory fields
- 1 new object: `src/meta/objects/poison-bottle.lua`
- `nightstand.lua` and `nightstand-open.lua` updated to place poison bottle

---
### 2026-03-19T123739Z: User directive
**By:** Wayne "Effe" Berry (via Copilot)
**What:** File-per-state is the chosen object model. Keep separate .lua files for each object state (nightstand.lua + nightstand-open.lua, candle.lua + candle-lit.lua, etc.). This resolves the open question from D-35. Wayne considered single-file-with-states but prefers the current pattern. Each state is a complete, self-contained object definition. Mutation = swap the entire file.
**Why:** User decision — resolves architecture question. File-per-state stays. No refactoring needed.

---

### 2026-03-19T140600Z: Architecture clarification — Any meta property overridable
**By:** Wayne "Effe" Berry (via Copilot)
**What:** ANY meta property of a base object can be overridden at the instance level. This isn't limited to descriptions — size, weight, capacity, categories, sensory descriptions, tool capabilities, ANYTHING.

**Example:** The base `bed` class defines a standard bed. But:
- Bedroom instance: `overrides = { size = 4, description = "A massive four-poster bed..." }`
- Servant's quarters instance: `overrides = { size = 2, description = "A narrow cot with a thin mattress." }`
- King's chamber instance: `overrides = { size = 6, weight = 200, description = "An enormous canopied bed..." }`

Same base class GUID, completely different feel per room. The base provides defaults. The instance makes it unique.

This applies to EVERY property: weight, size, capacity, on_feel, on_smell, on_taste, on_listen, room_presence, categories, requires_tool, provides_tool, surfaces, contents, keywords — all overridable.

**Why:** Clarification of instance model. Designers define base objects once, then customize per room via lightweight overrides. Massive content reuse with room-specific character.

---

### 2026-03-19T141309Z: Architecture directive — Field naming: type and type_id
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Rename instance fields:
- `name` → `type` (human-readable type name, e.g., "Matchbox", "Poison Bottle")
- `base_guid` → `type_id` (the GUID that references the base class definition)

**Final instance field convention:**
```lua
{
  id = "matchbox-1",                              -- unique instance ID within this room
  type = "Matchbox",                              -- human-readable type (what kind of thing)
  type_id = "a1b2c3d4-e5f6-4a7b-8c9d-...",       -- GUID of the base class definition
  location = "nightstand-1.inside",
  overrides = {},
  contents = {}
}
```

**Rationale:** 
- `type` is more accurate than `name` — it describes WHAT KIND of thing this is, not what this specific instance is called. A room might have "Grandmother's Rocking Chair" (instance display name) but its TYPE is "Chair".
- `type_id` clearly communicates "this is the ID that resolves the type definition"
- `id` remains the instance's unique identifier within the room

This applies everywhere:
- All instance definitions in room files
- The loader/resolver uses `type_id` to find the base class
- Architecture docs should use this terminology

**IMPORTANT:** Capture all of this (instance model, overrides, type/type_id, room as container, GUID resolution) in docs/architecture/instance-model.md.

**Why:** User request — clearer naming convention. Type describes the class, type_id is the resolvable reference.

---

### 2026-03-22T120000Z: Hybrid Parser Architecture (Rule-Based + Local SLM)
**Proposed by:** Frink (Researcher)
**Status:** Proposed
**Requested by:** Wayne "Effe" Berry
**Related Decisions:** D-17 (No per-player LLM cost), D-19 (Parser: NLP or Rich Synonyms)

**Summary:** Resolves Decision 19 (Parser approach — currently "Deferred/SOFT") with a hybrid architecture:

1. **Primary:** Rule-based rich synonym parser handles ~85% of commands instantly (<1ms). Zero download, zero battery cost, works on all devices.
2. **Secondary (progressive enhancement):** Local SLM (Qwen2.5-0.5B-Instruct, Q4 quantized, ~350MB) handles ambiguous natural language as fallback, running entirely in-browser via WebLLM + WebGPU. Zero cloud tokens.

**Rationale:**
- Satisfies Decision 17: no per-player LLM token cost (everything on-device)
- Rule-based parser is the MVP; SLM is the stretch goal from D-19
- 350MB model download is only for capable devices on WiFi — game works without it
- Grammar-constrained JSON generation guarantees valid command output
- Fine-tuning via LoRA on 500 build-time-generated training pairs is cheap (~1 hour, ~$2–5)

**Impact:**
- Parser engine needs a fallback chain: rule-based → SLM → ask player to rephrase
- WebLLM dependency added as optional (not required for gameplay)
- Need to generate 500 training pairs for fine-tuning (build-time LLM cost)
- CDN hosting for model weights (~350MB, one-time per player)

**Full Research:** `resources/research/architecture/local-slm-parser.md`

---

### Play Test Log #2 (2026-03-19)
**By:** Wayne "Effe" Berry
**Build:** Post compound-tools (commit 50c9021)

**Transcript:**
```
> grope around what is around me
You can't feel anything like that nearby.

> feel around
You can't feel anything like that nearby.

> what is around me?
It is too dark to see. You need a light source.
(Try 'feel' to grope around in the darkness.)
```

**Issues:**
1. **"feel around" doesn't work** — "around" is parsed as noun, handler looks for object called "around" and fails. FEEL with no noun or "around" should trigger room-sweep (list reachable objects by touch).
2. **"grope around" same problem** — alias of feel, same bug.
3. **Multi-word natural language still fails** — "what is around me" parsed as verb="what". Need either better parsing or friendlier error pointing to FEEL.

**Fix needed:** FEEL with no noun, "around", or "room" should trigger the ambient feel-around behavior.

---
### 2026-03-19T125251Z: User directive — Matchbox/Match Interaction Rethink
**By:** Wayne "Effe" Berry (via Copilot)
**What:** The matchbox interaction needs to be richer and more realistic:
1. The matchbox is a CONTAINER that holds individual match objects (7 in this room, varies per matchbox)
2. The matchbox has a STRIKER on the side
3. To light a match, you STRIKE the match ON the matchbox — two objects are required
4. The lit match is then the fire_source tool you use to light the candle
5. This raises the question: is the match the tool? The matchbox? Both?

Wayne's answer (implied): BOTH are required for different steps:
- Matchbox = container + striker surface (not a tool itself, but a required surface)
- Match = the item that becomes a fire_source AFTER being struck on the matchbox
- Lit match = the actual fire_source tool (mutation: match → match-lit)
- Match-lit burns out after one use (consumed)

This creates a richer puzzle chain:
OPEN matchbox → TAKE match → STRIKE match ON matchbox → match-lit (fire_source) → LIGHT candle WITH match

This REPLACES the current "matchbox with charges" design. Individual matches as objects, not a counter.

**Why:** User request — design philosophy: realistic object interactions create better puzzles. Two-tool interactions add depth. Challenges the simple "charges" model.

---
### 2026-03-19T125500Z: User directive — Compound Tool Interactions
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Some skills require TWO tools used together. This is a "compound tool" pattern:
- Lighting a match = a skill everyone knows, but requires match + matchbox (striker) together
- Sewing = a learned skill that requires needle + thread together
- The engine needs to support: SKILL + TOOL A + TOOL B → action

This reframes the tool system:
- Single-tool actions: LIGHT candle WITH match-lit (one tool)
- Compound-tool actions: STRIKE match ON matchbox (two tools, innate skill)
- Compound-tool + learned skill: SEW cloth WITH needle AND thread (two tools + learned skill)

The complexity isn't in HAVING a skill — lighting a match is innate. The complexity is in HAVING BOTH required objects. This is the puzzle: find the match AND the matchbox. Find the needle AND the thread.

**Implications:**
- Tool convention needs a `requires_tools` (plural) field — array of required capabilities
- Skills can be innate (everyone knows) or learned (lockpicking, sewing)
- Thread is a new object needed for sewing (needle alone isn't enough)
- The STRIKE verb is a compound-tool verb

**Why:** User request — major game mechanic. Compound tools add realistic puzzle depth. Every crafting/interaction becomes: do you have ALL the pieces?

---
### 2026-03-19T125825Z: User directive — Two-Hand Inventory + Bags
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Players have TWO HANDS. That's their base inventory — they can carry/hold two items max. However:
- A BAG (held in one hand) expands capacity — bag contents don't count against hand slots, but the bag itself takes one hand
- A BACKPACK (worn on back) frees BOTH hands — backpack contents available without using hand slots
- TOOL USAGE REQUIRES HANDS. To strike a match on a matchbox, you need BOTH hands free (one for match, one for matchbox). If you're holding a bag, you must DROP BAG first.
- This creates real inventory management puzzles:
  - Carrying a bag + sword = no free hands = can't light match
  - Drop bag → strike match → light candle → pick up bag
  - Wearing a backpack = hands free for tool use
  - Backpack is a major upgrade item (not available in bedroom?)

**Implications:**
- Player state needs: hands[] (array of 2 slots) + worn[] (backpack slot) + bag contents
- Items need a `held_in` property: "hand", "bag", "backpack", "worn"
- Compound tool actions check: are both hands available?
- DROP becomes strategically important (not just discarding)
- Bags and backpacks are containers the player carries
- The sack in the bedroom could be the first bag!

**Puzzle depth this creates:**
- Dark room: you're holding the bed sheet. Drop sheet → open drawer → take match → take matchbox → strike match → light candle. That's 6 actions just to get light. Real gameplay.
- Trade-offs: carry the knife (protection) or the candle (light)? Can't hold both + a bag.

**Why:** User request — major inventory mechanic. Transforms inventory from "magic pocket" to physical constraint. Every item held is a choice. Every compound tool action requires hand management.

---
### 2026-03-19T130000Z: User directive — Sensory Descriptions + Start Time + Poison
**By:** Wayne "Effe" Berry (via Copilot)

**Part 1 — Game Start Time:**
Don't start at dawn. Start BEFORE dawn (middle of the night — say 2 AM or 3 AM). The room is truly dark. Dawn comes later (6 AM = after ~3-4 minutes real time at 1hr=1day rate). The match/candle puzzle MATTERS because the player is in real darkness and dawn is NOT imminent. They NEED to light the candle to see. Dawn eventually rescues them if they can't solve it, but that's minutes of fumbling in the dark.

**Part 2 — Multi-Sensory Object Descriptions:**
Every object should have multiple sensory descriptions:
- `on_look` / `description` — what it looks like (requires light)
- `on_feel` — what it feels like by touch (works in dark!)
- `on_smell` — what it smells like (works in dark!)
- `on_taste` — what it tastes like (works always, but risky...)
- `on_listen` — what it sounds like (works in dark!)

This means in the dark, players can FEEL, SMELL, TASTE, and LISTEN to identify objects without seeing them. This is the core dark-room mechanic:
- FEEL nightstand → "Your hands find a smooth wooden surface with a small drawer."
- SMELL candle → "Waxy, slightly sweet. Definitely a candle."
- TASTE bottle → "BITTER! You spit it out. That tasted like poison." (consequences!)

**Part 3 — Poison Bottle:**
Add a bottle of poison on the nightstand. This creates a deadly puzzle in the dark:
- Player feels around → finds bottle on nightstand
- If they TASTE it in the dark (trying to identify it) → POISONED
- If they can see (have light) → LOOK at bottle reveals skull and crossbones label
- SMELL bottle → "Smells acrid and chemical. Something dangerous."
- This is a consequence-driven design: tasting unknown things in the dark can kill you

**Why:** User request — transforms the dark room from frustration into rich sensory gameplay. Every sense is a tool. Tasting is dangerous. The poison bottle is the first lethal puzzle.

---
### 2026-03-19T130100Z: Architecture question — Verbs as Meta-Code
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Wayne wonders if verbs should be defined in src/meta/verbs/ (as Lua data files) rather than hardcoded in src/engine/verbs/init.lua. This would make verbs part of the world definition, not the engine. Each verb = a .lua file returning a table with handler, aliases, prerequisites. Engine just loads and dispatches. Verbs become mutable — a cursed room could change how LOOK works. New verbs = new files, no engine changes. Aligns with "code IS the world" philosophy.
**Status:** Open question — Wayne exploring, not directing yet. Needs Bart (Architect) analysis.
**Why:** Architectural consistency. If objects are meta-code, why aren't verbs? Could enable room-specific verbs, mutable actions, per-universe verb sets.

---
### 2026-03-19T130200Z: User directive — Prime Directive
**By:** Wayne "Effe" Berry (via Copilot)
**What:** The main goal is ALWAYS to honor Effe's directives and designs and work towards play testing. This is the team's prime directive. Every decision, every implementation, every architecture choice serves two masters: (1) Wayne's vision as expressed through his directives, and (2) getting to a playable state as fast as possible. When in doubt, ask: "Does this honor Wayne's design? Does this get us closer to play testing?" If both answers are yes, do it.
**Why:** User request — this is the governing principle above all others. Captured as the team's prime directive.

---
### 2026-03-19T131013Z: User directive — Puzzle Documentation
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Start documenting puzzles in docs/puzzles/ (new subfolder). Every puzzle the team designs should be documented there for reference. This is a living reference for game designers and play testers. Each puzzle doc should cover: setup, required objects, solution steps, alternative solutions (if any), what the player learns, and consequences of failure.
**Why:** User request — puzzles are first-class design artifacts. They need their own documentation, not scattered across design docs and object files.

---
### 2026-03-19T131234Z: User directive — Consumables System
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Objects can be consumable — when consumed, they are REMOVED from the universe entirely:
- Candles burn down over time (consumed by burning)
- Food can be eaten (consumed by eating)
- Paper can be burned (consumed by fire)
- Matches are consumed when struck and burned out
- When consumed, the object is removed from the registry. It no longer exists. Gone.

This is different from mutation (object becomes something else) — consumption is DESTRUCTION. The object ceases to exist. No variant file, no replacement. Just gone.

**Engine implications:**
- Registry needs a `destroy(id)` or `remove(id)` method (already has `remove` — verify it works for this)
- Candles need a burn timer — after N turns of being lit, candle is consumed (dark again!)
- EAT verb needed (future)
- BURN verb needed (future — burn paper, burn cloth, etc.)
- Matches consumed after one use (strike → light something → match gone)

**Gameplay implications:**
- Candles are FINITE. You can't leave one burning forever. Resource management.
- Matches are one-use. 7 matches = 7 chances to light things.
- Food is survival. Eat it and it's gone.
- This creates urgency and scarcity — core to good puzzle design.

**Why:** User request — adds resource management and scarcity to the game. Objects are precious because they can be permanently lost.

---
### 2026-03-19T131234Z: User directive — Matchbox as Container (not separate empty file)
**By:** Wayne "Effe" Berry (via Copilot)
**What:** The matchbox should NOT have a matchbox.lua + matchbox-empty.lua pattern. The matchbox is a CONTAINER (like the sack) with a contents array listing what's inside it (individual matches). When all matches are used, the matchbox is just empty — same object, empty contents array. No separate "empty" variant file. This is different from the file-per-state decision for objects like candle/nightstand — the matchbox isn't changing STATE, it's just having items removed from it. It's a container, not a state machine.

**Clarification on file-per-state:** File-per-state is for objects that CHANGE WHAT THEY ARE (candle → candle-lit, nightstand → nightstand-open). Containers that just have stuff taken out of them don't need variant files — their contents array changes.

**Why:** User request — simplifies container objects. Aligns with containment model. The sack doesn't have a sack-empty.lua, so neither should the matchbox.

---
### 2026-03-19T124327Z: Play Test Log #1
**By:** Wayne "Effe" Berry
**Date:** 2026-03-19
**Build:** V1 REPL (commit bd9c55a)

#### Transcript:
```
> look
It is too dark to see. You need a light source.
Dawn breaks on the horizon. It is 6:02 AM.

> find side table
You don't know how to 'find'.

> look
It is too dark to see. You need a light source.
Dawn breaks on the horizon. It is 6:08 AM.

> open curtains
It is too dark to see what you're doing.

> what is around me
You don't know how to 'what'.
```

#### Issues Identified:
1. **Dawn + dark = contradiction.** It's 6:02 AM (dawn), but the room is pitch dark. If it's dawn, shouldn't there be SOME light through the window?
2. **Dark room is a dead end.** Player can't open curtains (too dark), can't find nightstand (too dark), can't do anything. No way to progress without blind groping.
3. **No FEEL/TOUCH/GROPE verb.** In darkness, player should be able to feel around to find nearby objects.
4. **"find" is not a verb.** Natural language expectation gap.
5. **"what is around me" fails.** Player is trying to orient — needs a way to get bearings in the dark.
6. **Error messages unhelpful.** "You don't know how to 'find'" sounds like a character flaw, not a parser limitation. Should suggest valid verbs.

#### Severity: HIGH — game is unsolvable as-is at dawn.



---

# Decision: Feel Verb Enumerates Container/Surface Contents (2026-03-19)

**Author:** Bart (Architect)  
**Date:** 2026-03-19  
**Status:** IMPLEMENTED  
**Impact:** Verb system, gameplay progression  

## Context

The "feel {object}" verb handler printed only the object's on_feel text but never enumerated accessible contents of containers or surfaces. This broke the darkness gameplay loop — players couldn't discover the matchbox inside the open nightstand drawer by touch.

## Decision

After printing the sensory description, the feel handler now enumerates:

1. **Surface zones** (obj.surfaces) — each zone where ccessible ~= false and contents exist. Prefix: "Your fingers find {zone_name}:"
2. **Simple containers** (obj.container + obj.contents) — if container has contents. Prefix: "Inside you feel:"

Both use ctx.registry:get(id) to resolve item names, falling back to raw ID.

## Rationale

- Matches the progressive disclosure design: "feel around" = summary (object names), "feel {object}" = detail + accessible contents.
- Tactile language ("Your fingers find", "Inside you feel") stays consistent with darkness atmosphere.
- Respects the ccessible == false gate — closed drawers hide contents from touch, same as from sight.
- Follows the same enumeration pattern already established in the LOOK handler.

## Files Changed

- src/engine/verbs/init.lua — feel handler (~20 lines added after line 841)

---

# Decision Memo: Player Skills System Architecture (2026-03-21)

**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-03-21  
**Decision Level:** 1 (Design-level, ready for implementation review)  
**Status:** Proposed (awaiting team consensus)  

## Summary

Binary skills model with discovery-based acquisition, integrated as a second gate in verb handler dispatch. Supports emergent gameplay while respecting dark, tactile aesthetic.

## Key Design Decisions Ratified

### 1. Binary Skills (Have / Don't Have) in V1

\\\lua
player.skills = {
  lockpicking = false,  -- Player cannot PICK LOCK yet
  sewing = false,       -- Player cannot SEW yet
}
\\\

**Rationale:** Simplicity + discovery. Skills are milestones, not XP bars. When the player reads the lockpicking manual or practices packing enough times, the skill becomes available.

### 2. Skills Unlock Alternatives, Not Replacements

A pin can **always** be used to prick and draw blood (no skill required). With lockpicking skill, it **also** picks locks.

**Rationale:** Respects player agency. No puzzle becomes unsolvable without a skill. Skills accelerate, don't gatekeep.

### 3. Skill + Tool + Verb Gating (Double Dispatch)

Verb handlers enforce two requirements in series: skill gate → tool gate.

**Rationale:** Separation of concerns. Engine code remains simple.

### 4. Failure Has Consumable Consequences

When a player attempts a skilled action without the skill, the tool is consumed:
- **Failed lock pick:** Pin bends (bent-pin.lua created)
- **Failed sewing:** Thread tangles (tangled-mess.lua created)

**Rationale:** Teaches design language through play. Resources are finite.

### 5. Blood Writing Is Transgressive and Costly

\\\
PRICK SELF WITH pin → Player loses 5 HP → Blood object created (time-limited, ~5 game-minutes) → WRITE "text" ON paper WITH blood → Paper becomes permanent
\\\

**Rationale:** Embodies the dark, tactile tone. Blood is not a convenience—it's a desperate measure.

### 6. Paper Mutations Are File-Per-State

When the player writes on paper, the engine creates \paper-with-writing.lua\ with embedded player text.

**Rationale:** Code-as-state. Player text persists across saves. Designer can inspect player-authored papers.

### 7. Skill Discovery Is Multi-Path, Not Gated by Progression

Four acquisition methods:
1. Find & Read manuals
2. Practice (use pin multiple times)
3. NPC Teaching (future)
4. Puzzle Solve (future)

**Rationale:** No forced order. Player discovers skills naturally.

## Implementation Notes

**For Engineers:**
- Add \player.skills\ table (hash of skill_id → boolean)
- Verb handlers check \player.skills[required_skill]\ before allowing action
- Tool lookup validates both \provides_tool\ AND skill requirement

**For Designers:**
- Create skill manuals as readable objects in rooms
- Mark blood writes as disturbing in design docs
- Test that every puzzle has a no-skill solution

## Risk Assessment

| Risk | Likelihood | Severity | Mitigation |
|------|-----------|----------|-----------|
| Players ignore skills | Low | Low | Design multiple paths |
| Blood writing alienates players | Medium | Medium | Document dark tone upfront |
| Consumable failures frustrate players | Low | Medium | Make failures recoverable |
| Input sanitization fails | Low | High | Whitelist chars, escape quotes |

## Decision Authority

**Level 1** (design-level decision). Requires Wayne + Bart + Game Design team approval.

## Timeline

Proposal → Review (3–5 days) → Approval/Iteration → Implementation (1 week for MVP)

## Open Questions for Team

1. **Paper mutations:** File-per-state or in-place?
2. **Proficiency levels:** Prototype now or defer to V2?
3. **NPC teaching:** Reserve verb gate for future?
4. **Blood availability:** Time-limited or persistent across rooms?

## Related Decisions

**Supports:** Decision D-28 (Multi-Sensory Convention). Skills discovered by feeling/smelling objects.

---

# Decision: Tier 2 Embedding Parser Implementation Plan Approved for Review (2026-03-20)

**Author:** Chalmers (Project Manager)  
**Date:** 2026-03-20  
**Status:** Ready for Wayne Review  
**Related Decisions:** D-19 (Parser approach), D-17 (Build-time LLM)  
**Decision Authority:** Level 2 (Architecture-affecting)

## Summary

Comprehensive implementation plan for Tier 2 embedding-based parser fallback system. Plan covers all 6 phases needed to integrate GTE-tiny ONNX embeddings into game loop, with ~10 working days timeline.

**Deliverable:** \plan/llm-slm-parser-plan.md\ (445 lines, committed to main)

## Key Decisions

### 1. Embedding Model Choice: GTE-tiny ONNX INT8
- 5.5MB model size
- No GPU required (ONNX Runtime Web + WASM)
- 10–30ms inference latency per phrase

**Rationale:** Balances semantic understanding with PWA constraints.

### 2. Index Strategy: Pre-Computed, Updatable
- ~2,000 canonical phrases encoded at build time
- JSON lookup table (~400KB compressed)
- Regenerated automatically when verbs/objects change

**Rationale:** Decouples content changes from model tuning.

### 3. Fallback Chain: Tier 1 → Tier 2 → Fail
- Tier 1 (rule-based) remains at 85% coverage, unchanged
- Tier 2 only invoked after Tier 1 miss
- Threshold: 0.75 score → execute, 0.50–0.75 → disambiguate, <0.50 → fail

**Rationale:** Preserves existing reliability, zero Tier 1 regressions.

### 4. Test Coverage Target: 90%+ Accuracy
- Canonical command set + edge cases
- Latency targets: p50 <30ms, p99 <100ms

### 5. CI/CD Automation
- Automatic rebuild of embedding index on verb/object change
- LLM cost ~\.05 per rebuild

## Open Questions for Wayne

1. **Accuracy Threshold:** Should threshold be 0.65 (lenient), 0.75 (moderate), or 0.85 (strict)?
2. **Training Data Volume:** 2,000 phrases sufficient, or scale to 5,000–10,000?
3. **Disambiguation UX:** Show "Did you mean...?" or use context to pick best match?
4. **Tier 3 (Optional):** Reserve room for future Qwen2.5 SLM (~350MB)?
5. **Fallback on Error:** Silently degrade to Tier 1 or fail game startup?

## Timeline

| Phase | Duration | Owner |
|-------|----------|-------|
| 1–2 | 2 days | LLM/Pipeline |
| 3 | 3 days | Runtime Engineer |
| 4 | 2 days | Engine Lead |
| 5 | 2 days | DevOps |
| 6 | 3 days | QA |
| **Total** | **~10 days** | **6 people** |

## Success Metrics

- ✅ Tier 2 handles 12%+ of Tier 1 misses
- ✅ Latency <100ms p99, median ~30ms
- ✅ Accuracy 90%+ on canonical test set
- ✅ Index <500KB, model <10MB memory
- ✅ Zero Tier 1 regressions

## Recommendation

**APPROVE.** Plan is concrete, actionable, de-risks the embedding approach. Ready for Week 1 kickoff pending Wayne's answers to open questions.

---

# Decision Proposal: Embedding-Primary Hybrid Parser Architecture (2026-07-23)

**Filed by:** Frink (Researcher)  
**Date:** 2026-07-23  
**Related to:** D-17, D-19  

## Proposal

Replace two-tier parser (rule-based + 350MB SLM) with three-tier architecture inserting **5.5MB embedding similarity layer** between rule-based parser and optional SLM.

## Architecture

| Tier | Method | Coverage | Latency | Size | GPU? |
|------|--------|----------|---------|------|------|
| 1 | Rule-based synonyms | ~85% | <1ms | 0 | No |
| 2 | Embedding similarity (GTE-tiny ONNX INT8) | ~12% | 10–30ms | 5.5MB | No (WASM) |
| 3 | Generative SLM (Qwen2.5-0.5B, optional) | ~3% | 200–1500ms | 350MB | Yes (WebGPU) |

## Why

- Tier 2 handles 80% of what SLM was supposed to handle, at 70× less size and 20× less latency
- No WebGPU dependency — works on all browsers via WASM
- Trivial to update: appending embedding vectors requires no GPU, no retraining, ~35 seconds
- Integrates into CI/CD as CPU-only build step
- Annual cost: ~\ (LLM training + occasional retrain)

## Impact

- D-17 still satisfied: zero per-player token cost
- D-19 improves: smart parser drops from 350MB optional to 5.5MB near-mandatory
- Build pipeline gains automatic parser training data generation

## Action Needed

Wayne to review and decide whether to adopt three-tier architecture or stay with two-tier.

---

# Decision: Wasmoon PWA Deployment Path (2025-07-24)

**Author:** Frink (Researcher)  
**Date:** 2025-07-24  
**Status:** Proposed  
**Impact:** Architecture — adds browser deployment path  

## Recommendation

Adopt Wasmoon (Lua 5.4 → WASM) as the browser deployment path for the MMO engine, wrapped as a vanilla PWA.

## Key Points

1. **Wasmoon runs our Lua engine with minimal adaptation.** Only \io.popen\ (directory listing), blocking REPL loop, and \print\/\io.write\ need browser-specific alternatives. All 6 engine modules and all game content run unmodified.

2. **Create \main_browser.lua\ as parallel entry point.** Don't modify \main.lua\ — terminal REPL continues. Browser variant replaces filesystem scanning with JS-provided file lists and replaces blocking loop with \process_command()\ function.

3. **Use \mountFile\ + build-time bundling.** Node.js build script reads all \.lua\ files, embeds as JS constants, mounts into Wasmoon VFS. Standard \equire()\ works against VFS.

4. **Vanilla PWA, no framework.** HTML + CSS + ~100 lines of JS. Service worker for offline play. Manifest for installability. Total: ~168KB gzipped.

5. **Prototype effort: ~5-7 hours.** Hello-world to fully playable browser REPL with PWA wrapper.

## Constraints

- Wasmoon WASM requires modern browser (96%+ coverage, no IE11)
- \io.popen\ permanently unavailable in browser
- No async Lua→JS callbacks (not needed for synchronous game model)

## Decision Authority

Level 2 — architecture-affecting, team review recommended.

---

# User Directive: Summary vs Detail Descriptions (2026-03-19T153051Z)

**By:** Wayne "Effe" Berry (via Copilot)  
**Date:** 2026-03-19  
**Status:** Active  

## Directive

When doing a room sweep (FEEL AROUND, LOOK), show **SHORT summaries only** — not full detailed descriptions. Detailed text is too much for a list. Players should EXAMINE or FEEL {specific object} for deep description.

## Two Tiers of Description

**Summary** (room sweep / FEEL AROUND / LOOK):
- Brief, 5-10 words max
- Examples: "a small nightstand", "a ceramic chamber pot", "heavy velvet curtains"

**Detail** (EXAMINE {object} / FEEL {object}):
- Full rich description
- Example: "Smooth wooden surface, crusted with hardened wax drippings. A small drawer handle protrudes from the front."

## Implementation

- Objects need \summary\ or short \
ame\ field for list view
- \on_feel\ / \description\ remain DETAILED versions (shown on direct examination only)
- Room sweep: "Your hands find: a small nightstand, heavy velvet curtains, a ceramic chamber pot..."
- FEEL nightstand → shows full on_feel text
- Same principle for LOOK: room description brief, EXAMINE gives detail

## Rationale

Information hierarchy. Don't dump everything at once. Progressive disclosure. Let player drill down.

---

# Play Test Log #3 — 2026-03-19

**By:** Wayne "Effe" Berry  
**Build:** Post summary fix (commit 1f98cbe)  
**Status:** FINDINGS LOGGED  

## Session Notes

Player attempted darkness gameplay loop: feel around room, discover nightstand, open drawer by feel, discover matchbox.

## Issues Found

1. **OPEN blocked by darkness** [SEVERITY: HIGH]
   - Player felt the drawer handle but couldn't OPEN it
   - Physical actions (OPEN, CLOSE, TAKE from felt containers) should work in dark
   - You don't need eyes to pull a drawer

2. **EXAMINE fails in dark, should fall back to FEEL** [SEVERITY: MEDIUM]
   - EXAMINE in darkness should give on_feel description, not dead end
   - Current: "You can't see it"
   - Expected: "You can't see it, but you feel: {on_feel}"

3. **Parser strips "the" inconsistently** [SEVERITY: LOW]
   - "feel the nightstand" works, so parser handles articles
   - Marked as working as intended

## Impact

Puzzle unsolvable: player finds drawer by feel but can't open it. Blocks core darkness gameplay loop.

## Recommendations

- Implement tactile gating: OPEN/CLOSE/TAKE work in darkness from felt objects
- Implement EXAMINE fallback: if object can't be seen, show on_feel instead
- Consider "touch-to-interact" model: any verb requiring fine motor control (OPEN, CLOSE, TAKE, WRITE, CUT, PRICK, SEW, PICK LOCK) should work by feel
