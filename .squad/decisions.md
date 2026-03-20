# Squad Decisions

## Active Decisions

### 1. Engine Conventions from Pass-002 Bugfixes (2026-03-22)

**Author:** Bart (Architect)  
**Date:** 2026-03-22  
**Status:** Approved  
**Affects:** Object display functions, feel handler, game loop, CLI flags

#### Conventions Established

1. **`on_look(self, registry)` signature** — Object `on_look` functions may now accept optional second argument: the registry instance. This allows display functions to resolve child object IDs to display names. Existing functions that only accept `(self)` are unaffected — Lua silently drops extra arguments.

2. **`on_feel` can be string or function** — The feel handler now dispatches based on `type(obj.on_feel)`. Functions receive `(self)` and return a string. This enables dynamic tactile descriptions (e.g., matchbox varying by match count).

3. **`ctx.game_over` flag for death/ending** — Setting `ctx.game_over = true` from any verb handler causes the game loop to break after the current tick cycle. The loop prints a "Play again?" prompt and exits. Extensible for future death causes beyond poison.

4. **`--debug` CLI flag** — Parser diagnostic output is now off by default. Pass `--debug` to `lua src/main.lua` to re-enable `[Parser]` matching diagnostics on stderr/stdout. Keeps player experience clean during normal play.

**Team Impact:** QA testing with parser analysis should use `lua src/main.lua --debug`. Content creators can use either `on_feel = "static text"` or `on_feel = function(self) ... end`. Any lethal interaction should set the game_over flag.

---

### 2. Design Decision: Composite & Detachable Object System (2026-03-25)

**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-03-25  
**Status:** Ready for Team Review  
**Impact:** Object architecture, puzzle design, player agency

**Summary:** Objects in MMO are not always singular. A nightstand has a drawer. A poison bottle has a cork. These **sub-objects (parts) can sometimes be detached**, becoming independent objects.

**Core Solution:** Single-file architecture where one `.lua` file defines parent + all parts. Parts detach via factory functions, becoming independent. Parent transitions to new FSM state reflecting missing parts.

#### Key Design Decisions

1. **Single-File Architecture** — All parts and parent logic live in one Lua file (nightstand.lua defines nightstand, drawer, legs, FSM states)
2. **Part Factory Pattern** — Each detachable part has a factory function that instantiates it as independent object
3. **FSM State Naming** — `{base_state}_with_PART` and `{base_state}_without_PART` (e.g., closed_with_drawer, closed_without_drawer)
4. **Verb Dispatch for Parts** — General verbs trigger detachment; parts define verb aliases (uncork, remove cork, pull cork)
5. **Contents Preservation** — Container parts carry contents when detached (by default)
6. **Two-Handed Carry System** — Objects have `hands_required` (0/1/2); player has 2 hands total
7. **Reversibility as Design Choice** — Each part's reversibility is design-time decision (drawer reversible, cork irreversible)
8. **Non-Detachable Parts Valid** — Parts can have `detachable = false` for description-only (nightstand legs, bed posts)

#### Implementation Requirements (For Bart)

1. Part instantiation via factory; FSM state transitions
2. Verb dispatch routing for parts
3. Precondition system for detachment constraints
4. Two-handed carry tracking and enforcement

#### Success Criteria

- Nightstand + drawer detachment works end-to-end
- Poison bottle + cork detachment works
- Two-handed carry enforced
- Dark playability maintained
- No existing content breakage

**Approved by:** Comic Book Guy (Author), Wayne Berry (Lead Designer)  
**Ready for Implementation:** Bart (Architect)

---

### 3. User Directive: Newspaper editions in separate files (2026-03-20T03:40Z)

**Author:** Wayne Berry (via Copilot)  
**Status:** Active  
**Type:** Design Directive

The morning edition and late/evening edition of the newspaper should be in different files, not the same file. Keeps editions distinct and readable.

---

### 4. User Directive: Room layout and movable furniture (2026-03-20T03:43Z)

**Author:** Wayne Berry (via Copilot)  
**Status:** Active  
**Type:** Design Directive

**Room Layout & Spatial Relationships:**
- Bed is ON the rug
- Rug COVERS a trap door
- Layered spatial positioning — objects on top of other objects
- Moving top object reveals what's underneath

**Movable Furniture:** Players should be able to move objects around the room (push bed, pull rug, etc.)

**Hidden Objects:** Trap door is hidden under rug. Moving the rug reveals it (discovery mechanic).

**Stacking Rules:** Some objects stackable, some not. Objects declare stackability and weight/size support.

**Next Test Pass (pass-003):** Nelson should test moving things, discovering what's underneath, interacting with spatial relationships.

---

### 1-OLD. Newspaper Format & Purpose (2026-03-18)
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

### 4. Cross-Agent Directive: No Fallback Past Tier 2 (2026-03-19T17:22:26Z)
**Author:** Wayne "Effe" Berry (via Copilot)  
**Status:** Active  
**Affects:** Parser architecture, error handling, testability

When the embedding parser encounters a miss (no good match), it must fail visibly rather than falling back to lower-tier heuristics. Misses should surface clearly for analysis and iteration, enabling empirical QA of parser quality.

**Rationale:** Early visibility of parser shortcomings supports rapid iteration and prevents silent failures masking design gaps.

---

### 5. User Directive: Trim Index & Play Test Empirically (2026-03-19T18:10:37Z)
**Author:** Wayne "Effe" Berry (via Copilot)  
**Status:** Active  
**Affects:** Index size, browser deployment, parser tuning

The 32.5MB gzipped embedding index is too large for browser asset delivery. Trim it down, then play test empirically. If parser quality drops below acceptable, that means too much was trimmed — iterate from there. Prefer data-driven decisions over theoretical coverage projections.

**Rationale:** Ship lean, test, expand only if needed. Avoid over-engineering for unknown requirements.

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

### 6. Tier 2 Parser Wiring (Lua REPL) (2026-03-19)
**Author:** Bart (Architect)  
**Date:** 2026-03-22  
**Status:** Implemented  
**Impact:** Parser, game loop, runtime architecture

Tier 2 (embedding-based) parser is now wired into the Lua game loop. When Tier 1 (exact verb dispatch) fails, the loop falls back to Tier 2 phrase-text similarity matching. If Tier 2 also misses (score ≤ 0.40), the command fails with diagnostic output showing the input, best match, and score.

**Key Decisions:**
1. **No ONNX in Lua.** The embedding index is loaded as a phrase dictionary. Matching uses Jaccard token-overlap similarity, not vector cosine similarity. Real embedding similarity comes later in the browser via ONNX Runtime Web.
2. **No fallback past Tier 2.** If the matcher misses, the command fails visibly. Diagnostic mode is on by default during playtesting.
3. **Embedding index serves dual purpose:**
   - Lua REPL: phrase dictionary (text matching, vectors ignored)
   - Browser runtime (future): vector index (ONNX Runtime Web cosine similarity)
4. **Index trimmed via `--max-variations` flag:** Round-robin synonym distribution ensures verb diversity per combo. 29,582 → 4,337 phrases, gzip 34MB → 4.9MB.
5. **Threshold 0.40** for Tier 2 acceptance. Below this, matches tend to be wrong-verb. Tunable via `parser.THRESHOLD` in `src/engine/parser/init.lua`.

**Files:**
- `src/engine/parser/init.lua` — Tier 2 module entry point
- `src/engine/parser/embedding_matcher.lua` — Jaccard phrase matcher
- `src/engine/parser/json.lua` — Minimal JSON decoder for Lua
- `src/engine/loop/init.lua` — Tier 2 fallback wired after Tier 1
- `src/main.lua` — Parser module loaded at startup
- `scripts/generate_parser_data.py` — `--max-variations` flag added

**Team Impact:**
- **Comic Book Guy:** The ~400 command variation matrix can now be validated against Tier 2 matching. Run the game and test variations to find coverage gaps.
- **QA:** Diagnostic output shows every Tier 2 invocation — use it to build a test matrix of what matches and what doesn't.
- **Future:** When browser runtime is implemented, the same embedding-index.json gets loaded by ONNX Runtime Web for real vector similarity. The Lua Jaccard matching is a stopgap.

---

### 7. FSM Object Lifecycle System Design (2026-03-23)
**Author:** Comic Book Guy (Game Designer)  
**Status:** Ready for Implementation  
**Related:** Wayne's directive to unify match-lit.lua and match.lua; FSM adoption for object state management

**Problem Statement:**
Objects have multiple states (match: unlit → lit → spent; nightstand: closed ↔ open), currently managed as separate files. This creates duplication, coordination overhead, and ambiguity on finality.

**Solution Overview:**
**Unified FSM with Hybrid File Organization**
- One logical object per FSM (match, candle, nightstand, etc.)
- Unified state machine definition (initial state, transitions, auto-conditions)
- File-per-state preserved for properties (sensory descriptions, capabilities)
- Engine maps: ID → FSM → current state → load state properties

**Scope:**
- **FSM Objects (7 total):** match, candle, nightstand, vanity, wardrobe, window, curtains
- **Static Objects (32 total):** No state transitions needed. Continue current object definitions.

**Consumable Pattern: Finite Duration, Terminal States**
- **Match:** unlit → (STRIKE on matchbox) → lit (30 ticks) → spent [TERMINAL]
- **Candle:** unlit → (LIGHT with fire_source) → lit (100 ticks) → stub (20 ticks) → spent [TERMINAL]
- Duration is event-driven (1 tick = 1 player command)
- Warning thresholds: match at 5 ticks, candle at 10 ticks (tunable)
- Ticks happen **before** verb execution (fair resource consumption)

**Container Pattern: Reversible Access Gates**
- Examples: nightstand (closed ↔ open), wardrobe, window, curtains
- No consumption, no terminal states
- Bidirectional: OPEN → open, CLOSE → closed
- Persistence: A closed drawer stays closed if not opened

**Design Rules:**
1. One object, many states. Unify match.lua + match-lit.lua into single FSM object.
2. Consumables are terminal by default. Spent match cannot be recycled.
3. Containers are reversible. No destruction on container state change.
4. Tick happens before action. Fair resource consumption; no ambiguity.
5. Warning threshold tunable. Design team can adjust urgency per puzzle.
6. File-per-state for properties preserved. Designers keep beautiful descriptions.
7. Shared properties outside FSM. id, name, keywords, size, weight go once, referenced by all states.

**Implementation Roadmap:**
- Phase 1: FSM Engine (Architect) — Create FSM data structure, dispatcher, tick counter, warning system
- Phase 2: Consumable Objects (Design) — Convert match/candle to FSM, tune durations
- Phase 3: Container Objects (Design) — Convert nightstand, wardrobe, etc.
- Phase 4: Tuning & Playtest — Adjust durations and thresholds

**Success Criteria:**
- FSM objects transition correctly
- Auto-transitions fire at the right time (before verb execution)
- Warning messages appear at threshold without spamming
- Puzzle pacing feels right (matches create urgency, candles provide relief)
- Terminal states prevent impossible actions
- Reversible states toggle smoothly

**Approved by:** Comic Book Guy  
**Next review:** After Phase 1 (FSM engine implementation)

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
- Matches consumed after one use (strike → light something → match gone).

---

### 13. Play Test Bug Fix Patterns (2026-03-22)
**Author:** Bart (Architect)  
**Date:** 2026-03-22  
**Context:** Wayne play-tested with Tier 2 active and found 4 bugs. All fixed and verified.

## Decisions Made

### 1. Surface Zone Keyword Aliasing
When a piece of furniture has a surface zone (like `surfaces.inside` for a drawer), add the surface's natural name as a keyword alias on the parent object rather than building engine-level surface-name resolution. This keeps the fix local to data (object files) rather than engine code.

**Applied:** Added "drawer" keyword to nightstand object.

### 2. Container Accessibility Gating
Added `accessible` field check to `find_visible` for non-surface containers. Closed containers (`accessible = false`) now hide their contents from verbs like take/get. This mirrors the existing `accessible` field on surface zones. File-per-state pattern used for matchbox open/closed states.

**Applied:** 
- Matchbox: Added accessible=false; created matchbox-open.lua for open state
- Engine: find_visible() now checks accessible field before listing contents

### 3. Levenshtein Typo Correction in Tier 2
Added edit-distance-based verb correction as a Tier 2 preprocessing step (not Tier 1). Rationale:
- Tier 1 should remain exact-match for predictability
- Tier 2 already handles fuzzy input — typo correction fits naturally here
- Known verbs extracted from the phrase index (no separate config needed)
- Edit distance ≤ 2 with length guard prevents false corrections

**Applied:** embedding_matcher.lua now includes Levenshtein correction with dynamic verb extraction.

### 4. NLP Preprocessing for Contextual Queries
Mapped "what's inside" to `look` as a minimal fix. Full context tracking (last-examined object, pronoun resolution) is deferred. When context tracking is built, this mapping should be updated to target the last-opened container.

**Applied:** Engine loop now preprocess "what's inside" → "look" before parser.

## Files Changed
- `src/meta/objects/nightstand.lua` — added "drawer" keyword
- `src/meta/objects/matchbox.lua` — added accessible=false, open mutation
- `src/meta/objects/matchbox-open.lua` — **NEW** file (open state)

---

### 6. Compound Command Architecture & Pronoun Resolution (2026-03-22)
**Author:** Bart (Architect)  
**Status:** Implemented  
**Affects:** Game loop, find_visible, parser pipeline

Play test batch 2 revealed players naturally type compound commands ("get a match and light it") and use pronouns ("it", "one"). The existing single-command pipeline rejected these entirely.

#### Decision Points

**1. Split on " and " in the game loop (not the parser)**
- Compound splitting happens at the REPL level before any parsing
- Each sub-command flows through the full preprocess → parse → Tier 1 → Tier 2 chain independently
- Keeps the parser pipeline unaware of compound syntax
- **Rationale:** Simpler than teaching the parser about conjunctions. The split is mechanical (string operation), not semantic. Risk of false splits (e.g., "bread and butter") is negligible in a game with no such items.

**2. Pronoun resolution via find_visible wrapper**
- Added a wrapper around `find_visible` that (a) tracks the last-found object on every successful lookup and (b) resolves "it", "one", "that" to that object
- Zero changes to verb handlers
- **Rationale:** Pronoun resolution is a cross-cutting concern. Wrapping the lookup function means every verb automatically supports pronouns without individual handler changes. The "last found" heuristic matches player intent in sequential commands.

**3. Em dashes replaced globally with double-dash**
- All Unicode em dashes (U+2014) replaced with ASCII `--` across the entire src/ tree
- Permanent style decision — no Unicode punctuation in player-visible text
- **Rationale:** Windows terminals default to codepage 437/850, not UTF-8. Setting console codepage is fragile and platform-specific. ASCII double-dash is universally safe and reads naturally in prose.

#### Trade-offs
- Compound split is naive (doesn't handle "and" as a noun). Acceptable for current game content.
- Pronoun resolution is single-depth (last object only, no stack). Sufficient for "verb X and verb it" patterns.
- Double-dash is less typographically elegant than em dash. Acceptable for a terminal game.

---

### 7. User Directive: Nightstand as Container Model (2026-03-19, filed 2026-03-22)
**Author:** Wayne "Effe" Berry (via Copilot)  
**Status:** Approved  
**Affects:** FSM design, object interaction, play test iteration

The nightstand should be modeled as a container, not just a furniture piece with surface zones. It keeps causing bugs because the surface-zone model doesn't behave like players expect.

**Player Mental Model:**
- A thing with a top (candle, bottle) and a drawer (matchbox)
- The drawer is a container you open
- The top is a surface you can see/feel things on
- Both should work like containers — players can "look in", "feel", "get things from" them naturally

**Why:** The current surfaces system is fighting the player's mental model. Repeated play test bugs (drawer not found, contents not shown, examine fails).

**Impact:** FSM design updated (section 2.3 in fsm-object-lifecycle.md); pattern applied to wardrobe, vanity, window. Simplifying to container model should fix the interaction pattern.

---

## 20. FSM Engine Architecture (2026-03-23)
**Author:** Bart (Architect)
**Status:** Implemented and tested
**Affects:** Object state management, consumables, containers, game loop

Wayne directed unifying multi-file object state management (match.lua + match-lit.lua, nightstand.lua + nightstand-open.lua) into single FSM definitions. Comic Book Guy designed the FSM object lifecycle system (docs/design/fsm-object-lifecycle.md). This decision covers the engine implementation choices.

### FSM Design Pattern

**1. Table-driven FSM with lazy-loading definitions**
- FSM definitions live in `src/meta/fsms/{id}.lua` and are loaded on demand via `require()`. The engine caches loaded definitions.
- Each definition contains: `shared` properties (immutable across states), `states` (per-state property overrides), and `transitions` (from/to/verb/guards).

**2. In-place object mutation (not replacement)**
- Unlike the old mutation system (which hot-swaps the entire object via `loadstring`), the FSM engine modifies the existing object table in-place.
- This preserves the registry reference, containment data, and any runtime-assigned fields.
- The `apply_state` function: saves containment → removes old state keys → applies shared → applies new state.

**3. Verb handlers check FSM before old mutations**
- Each modified verb handler checks `obj._fsm_id` first. If present, the FSM path runs. If not, the old `find_mutation`/`perform_mutation` path runs.
- This enables gradual migration — only match and nightstand use FSM today; all other objects keep working.

**4. FSM tick in the game loop, not in verb handlers**
- Auto-transitions (burn countdown) are processed in a dedicated FSM tick phase in the game loop, after each command.
- The tick iterates room contents, surface contents, and player inventory. Objects without `_state` are skipped.

**5. on_tick returns structured data, not side effects**
- The `on_tick` function in FSM state definitions returns `{ trigger = "..." }` or `{ warning = "..." }` instead of performing transitions directly.
- This keeps the FSM definition declarative.

### Consequences & Timeline

- Match and nightstand no longer need separate files per state (match-lit.lua, nightstand-open.lua deprecated)
- 5 more FSM objects to convert (candle, vanity, wardrobe, window, curtains) — same pattern
- Old mutation system remains for non-FSM objects indefinitely (no rush to remove)
- Three pre-existing search bugs (keyword substring, hand/bag priority, bag extraction) fixed as a side effect
- **Result:** Match burns 3 turns on tick. Nightstand is container with compartment swapping. 9 test cases pass.

### Files Implemented

- `src/engine/fsm/init.lua` — New FSM engine (~130 lines)
- `src/meta/fsms/match.lua` — Match FSM definition (3 states: unlit, lit, burned-out)
- `src/meta/fsms/nightstand.lua` — Nightstand FSM definition (2 states: closed, open)
- `src/engine/verbs/init.lua` — FSM integration in open/close/strike/extinguish handlers
- `src/engine/loop/init.lua` — FSM tick phase after each command
- `src/main.lua` — Skip FSM objects in old tick_burnable
- `src/meta/objects/match.lua` — Simplified, FSM-aware
- `src/meta/objects/nightstand.lua` — Simplified, FSM-aware
- `src/meta/objects/_deprecated/` — Old match-lit.lua, nightstand-open.lua archived
- `src/engine/search.lua` — 3 keyword resolution bugs fixed (side effect)

---

### 8. CYOA Branching Patterns for Engine Design (2026-07-24, filed 2026-03-22)
**Author:** Frink (Researcher)  
**Status:** Proposed  
**Context:** Choose Your Own Adventure book series research

**Decision:** The text adventure engine should use **bottleneck/diamond branching** as its primary narrative structure, with **time-cave branching** reserved for critical story moments only. Hidden/unreachable content should be implemented as a first-class feature.

**Rationale:** Analysis of 13 CYOA books (1979–1984) reveals that pure time-cave branching (every choice unique) creates exponential content requirements — unsustainable for any non-trivial game. The best CYOA books use convergent paths (bottleneck/diamond) to manage scope while preserving player agency.

**Engine Advantage:** Lua engine has an advantage CYOA books never had — **state tracking**. We can make reconvergent paths feel personalized by having the world remember prior choices — flavor text, NPC reactions, available objects all change based on history.

**Key Design Principles from CYOA Research:**
1. **Bottleneck convergence** — key rooms/events all paths must pass through
2. **Hidden nodes** — secret content discoverable through unconventional interaction (UFO 54-40 pattern)
3. **Quick failure cycles** — cheap death/restart encourages experimentation
4. **Depth as commitment** — going deeper = harder to return (Underground Kingdom pattern)
5. **Risk/reward proportionality** — boldest choices lead to best AND worst outcomes

**Research Files:** `resources/research/choose-your-own-adventure/` — 14 research files covering series overview and 13 individual books.
- `src/engine/verbs/init.lua` — accessible check in find_visible
- `src/engine/loop/init.lua` — NLP preprocessing for "what's inside"
- `src/engine/parser/embedding_matcher.lua` — Levenshtein typo correction

## Impact
- All playtest bugs fixed ✅
- Parser robustness improved (typo correction)
- Container model validated (file-per-state for open/closed)
- UX improved (contextual query support)

## Cross-Agent Notes
- **To CBG:** matchbox-open.lua confirms file-per-state FSM approach is sound
- **From CBG:** FSM design ready; Bart can now implement FSM engine


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

### 28. Composite Object Implementation Patterns (2026-03-25)

**Author:** Bart (Architect)  
**Date:** 2026-03-25  
**Status:** Implemented  
**Affects:** Object architecture, verb dispatch, hand/carry system

#### Decisions Made

**1. Direct State Application for Part Transitions**  
Detach/reattach transitions bypass `fsm.transition()` and apply state directly. Reason: FSM's `transition()` finds the first from→to match, which is ambiguous when multiple transitions share the same from/to states (e.g., both "open" and "detach_part" go from sealed→open on the bottle). The detach helpers know exactly which transition they want, so they apply state properties directly.

**2. Factory GUIDs Use math.random**  
Factory functions in object files run inside the sandbox (no `os` access). GUIDs for instantiated parts use `math.random(100000, 999999)`. Sufficient for single-player; multiverse will need proper UUID generation at the engine level.

**3. Search Priority: Real Objects > Parts**  
`find_visible` returns real objects (room, surface, hand) before parts. This means a detached drawer on the floor takes priority over the nightstand's drawer part definition. This prevents stale part descriptions from masking the actual independent object.

**4. Two-Handed Items Occupy Both Hand Slots**  
A two-handed item sets both `ctx.player.hands[1]` and `[2]` to the same object ID. DROP and PUT clear both. This is simpler than a separate tracking field and naturally blocks all single-hand operations.

**5. Reattachment Via PUT Verb**  
Reattachment uses the existing PUT verb handler. When `item.reattach_to == target.id`, the handler delegates to `reattach_part()` instead of containment logic. No new verb needed.

#### Team Impact

- **Content creators:** Composite objects define `parts = {}` table. Each detachable part needs a `factory` function, `detach_verbs` list, and appropriate FSM states on the parent.
- **QA:** Test `pull drawer` only after `open drawer`. Test `uncork bottle` directly. Test two-handed carry blocks with full hands.
- **Game designer:** Reversibility is per-part (`reversible = true/false`). Cork is irreversible. Drawer is reversible.

---

### 29. Spatial Relationships & Stacking System Design Decision (2026-03-26)

**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-03-26  
**Status:** Ready for Team Review  
**Impact:** Puzzle design, player interaction, room escape mechanics

#### Decision Summary

Objects in MMO exist in three-dimensional space. This design formalizes how they stack, hide, move, and interact spatially.

**Core Contribution:** Five distinct spatial relationships (ON/UNDER/BEHIND/COVERING/INSIDE) with separate mechanics for each. Stacking rules enforced via weight/size capacity. Hidden objects created via covering relationships. Movable furniture reveals what's underneath.

#### Design Scope

##### Five Spatial Relationships

| Relationship | Mechanic | Example | Visibility |
|--------------|----------|---------|-----------|
| **ON** | Object rests on surface | Candle ON nightstand | Visible if surface exposed |
| **UNDER** | Hidden beneath something | Key UNDER bed | Invisible until covering moves |
| **BEHIND** | Blocked by obstacle | Note BEHIND wardrobe | Invisible until blocker moves |
| **COVERING** | Object conceals what's below | Rug COVERS trap door | Bottom object hidden |
| **INSIDE** | In a container | Matches INSIDE drawer | Accessible if container open |

##### Stacking Rules

- **Stackable declaration:** Objects declare `is_stackable_surface = true/false`
- **Capacity limits:** Surfaces have `weight_capacity` and `size_capacity`
- **Weight categories:** Light (0-5 lbs), Medium (5-30), Heavy (30+)
- **Hard rule:** Heavy furniture cannot stack on light surfaces (physical realism)
- **Four surface models:** Flat (nightstand: 3 items), large (bed: 10+), stacking (rug: furniture), container (drawer: 4 items)

##### Hidden Object Discovery

- **Three states:** Hidden (not discoverable) → Hinted (tactile clue) → Revealed (fully interactive)
- **Triggers:** Covering object moves, player searches, state change
- **Declarative:** Objects specify `discovery_trigger = "covering_object_moves"`
- **Example:** Trap door under rug invisible until rug moves; discovery message fires on reveal

##### Movable Furniture

- **Declarations:** `can_be_pushed = true`, `can_be_pulled = true`
- **Move verbs:** PUSH, PULL, MOVE (with optional directions)
- **Consequences:** Moving object updates covering relationships, reveals hidden objects
- **Difficulty tiers:** Easy (1 tick), Moderate (2 ticks), Hard (3+ ticks)

##### Spatial Verbs

**New/Modified verbs:**
- LIFT / RAISE — Temporary peek without full removal
- LOOK UNDER / FEEL UNDER — Tactile discovery (works in darkness)
- LOOK BEHIND — Spatial occlusion queries
- PUSH — Furniture movement
- PULL — Furniture movement (may reveal)
- MOVE — Generic relocation with direction

#### Eight Core Design Decisions

1. **Five Distinct Relationships** — Why not merge UNDER and BEHIND? Different mechanics: UNDER is concealment by mass above (rug covers trap door); BEHIND is concealment by occlusion (wardrobe blocks note). Different verbs: LOOK BEHIND vs. PULL RUG.

2. **Covering is Bi-Directional** — Both perspectives needed: Rug perspective: `covering = ["trap_door"]`; Trap door perspective: `covered_by = "rug"`. Redundancy acceptable for clarity; queries check both sides.

3. **Weight & Size Capacity are Hard Rules** — Can a player cheat by stacking wardrobe on nightstand? No. Hard validation prevents this. Player must find alternative.

4. **Hidden Objects Don't Exist Until Revealed** — Can player EXAMINE trap door while under rug? No. Hidden objects not in room.contents. Only after rug moves does trap door exist. Discovery is the puzzle.

5. **Discovery Triggers Are Declarative** — Objects declare their triggers (`covering_object_moves`, `player_searches`, `state_change`). Allows designer flexibility without engine changes.

6. **Movement Updates All Relationships Atomically** — When bed moves off rug, all relationships update in one transaction. No partial states.

7. **LIFT is Different from MOVE** — LIFT: Temporary peek; object returns to position. MOVE: Permanent relocation. LIFT enables discovery without commitment.

8. **Darkness Doesn't Disable Spatial Verbs** — Player can PUSH furniture in complete darkness with tactile feedback. PUSH bed in dark: "The bed scrapes against the floor." (no visual detail). Results are tactile not visual.

#### Integration Points

**With Composite Objects (Detachable Parts):**
- Drawer detaches from nightstand → becomes independent object
- Drawer has `surfaces.contents` (container) + `surfaces.on_top` (stacking)

**With FSM (Object Lifecycle):**
- Candle burns → light_radius changes → affects spatial visibility
- Mirror breaks → covering relationship changes

**With Sensory System:**
- PUSH bed: multi-sense feedback (on_feel, on_listen, on_look if light)
- FEEL UNDER bed: tactile discovery, works in darkness

#### Success Criteria (MVP)

✅ Objects declare stackability and capacity  
✅ Surfaces reject items exceeding capacity  
✅ Players can PUT ON surfaces  
✅ Players can MOVE furniture (PUSH/PULL)  
✅ Moving furniture reveals what's underneath  
✅ Hidden objects transition hidden → revealed  
✅ Discovery messages fire appropriately  
✅ LIFT, LOOK UNDER, LOOK BEHIND verbs work  
✅ Spatial integrates with FSM  
✅ Spatial integrates with composite parts  
✅ Dark/light supports spatial manipulation  

#### Implementation Roadmap

**Phase 1 (MVP):** Core spatial model, surfaces, movement, hidden reveal  
**Phase 2:** Hidden object discovery states, triggers, discovery messages  
**Phase 3:** Advanced verbs (LIFT, LOOK UNDER, LOOK BEHIND)  
**Phase 4:** Integration with FSM, composite parts, sensory feedback  

#### Next Steps

1. Bart: Review implementation roadmap; propose Phase 1 timeline
2. Team: Approve spatial design principles
3. Content creators: Create object definitions using spatial properties
4. Nelson: Playtest spatial interactions once Phase 1 is live

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

---

### 22. Parser Pipeline Architecture (Phase 1 + 2) — Decision: Bart

**Author:** Bart (Architect)  
**Date:** 2026-03-21  
**Status:** Implemented  
**Impact:** Build tools, CI/CD pipeline, parser data flow

## Decision

The embedding parser's build pipeline is two Python scripts in `scripts/`, producing artifacts consumed at runtime. Both scripts are **build tools only** — they never run in the game engine.

## Key Design Choices

1. **Two-mode data generation:** `--mode=local` (offline, zero deps) vs `--mode=llm` (GPT-4 via OpenAI API). Local mode is the development/CI default. LLM mode is for higher-quality production data.

2. **CSV as intermediate format:** Phase 1 outputs CSV → Phase 2 reads CSV. This decouples the scripts and allows manual editing/review of training data between phases.

3. **Verb extraction via regex, not Lua parser:** The `handlers["verb"]` pattern in `verbs/init.lua` is consistent enough that regex extraction is reliable and dependency-free. No need for a Lua parser.

4. **All 54 verbs covered:** Both primary handlers (31) and aliases (23) generate training pairs. Aliases are real player input paths.

5. **Model caching in `models/`:** GTE-tiny is downloaded once and cached. Directory is gitignored. CI/CD should cache this directory between runs.

6. **Dual output (JSON + gzip):** Uncompressed JSON for debugging, gzip for production. Both in `src/assets/parser/`.

## File Ownership

| File | Owner | When Updated |
|------|-------|-------------|
| `scripts/generate_parser_data.py` | Bart / Pipeline | When verbs or objects change |
| `scripts/build_embedding_index.py` | Bart / ML | When encoding approach changes |
| `data/parser/training-pairs.csv` | Generated | Regenerated per build |
| `src/assets/parser/embedding-index.*` | Generated | Regenerated per build |

## Dependencies

- Phase 1 local mode: Python 3.8+ stdlib only
- Phase 1 LLM mode: `openai` package + API key
- Phase 2: `sentence-transformers` or `transformers` + `torch` + `onnxruntime`

## Next Steps

- Phase 3 (Runtime integration) consumes the gzip index
- Phase 5 (CI/CD) automates both scripts on verb/object changes

**Files Created:**
- `scripts/generate_parser_data.py`
- `scripts/build_embedding_index.py`
- `scripts/requirements.txt`
- `data/parser/.gitkeep`
- `src/assets/parser/.gitkeep`

**Verification:** Phase 1 local mode tested: 29,582 training pairs generated successfully.

---

### 23. Command Variation Matrix for Embedding Parser — Decision: Comic Book Guy

**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-03-22  
**Status:** Ready for Review  
**Related:** `docs/design/command-variation-matrix.md`

## The Decision

Define a canonical command variation matrix — all natural language variations players might type for the 31 verbs in the game — to serve as training data for the embedding-based parser (Tier 2).

## Context

The MMO engine has 31 verbs (23 canonical + 8 aliases). Players will not always use the canonical form:
- "grab" instead of "take"
- "pick up" instead of "pick"
- "examine" instead of "x"
- "go north" vs. "north" vs. "n"

An embedding-based parser needs examples of natural language variations to train accurately. This matrix provides ~400+ variations across all verbs, ensuring the embedding model understands player intent even when they don't use the exact canonical form.

## Key Design Decisions Embedded

### 1. Pronoun Resolution: Last-Examined Object
When a player types "it", "this", or "that", the parser resolves to the **last-examined object** (tracked via `ctx.last_object`).

**Rationale:**
- Simplest implementation (no discourse tracking or anaphora resolution)
- Fits the terse adventure game interface
- Avoids ambiguity in most cases

### 2. Darkness Verbs Are First-Class
FEEL, SMELL, TASTE, and LISTEN all have **darkness-aware variations** where feedback is sensory, not visual.

**Rationale:**
- Game is playable in pitch darkness
- These senses provide alternative information channels
- Sensory hierarchy: FEEL (primary), SMELL (safe ID), LISTEN (mechanics), TASTE (danger)

### 3. Tool Verbs Are Explicit About Requirements
WRITE, CUT, SEW, STRIKE, PRICK all have **tool-present** and **tool-absent** variations.

**Rationale:**
- Clear feedback guides player exploration (search for missing tool)
- Teaches the capability/requirement system
- Enables puzzles based on tool availability

### 4. Bare Commands Prompt for Clarification
Verbs that require objects (TAKE, OPEN, LIGHT) should prompt when called bare.

**Rationale:**
- Teaches players the verb interface gradually
- Prevents silent failures
- Natural MUD/IF convention

### 5. Compound Actions Are Explicit
STRIKE, SEW, PRICK SELF have two-object or special-case variations.

**Rationale:**
- Compounds teach real-world logic (fire needs fuel + friction)
- Mutations are predictable (match → match-lit)
- Failure states are educational (bent pin, tangled thread)

### 6. Edge Cases Are Documented
The matrix includes edge cases like pronouns, ambiguous targets, non-standard phrasings.

**Rationale:**
- Parser needs to handle these gracefully
- Teaches QA team what to test
- Future embedding model will see these variations in training data

## Variations Documented

| Category | Verb Count | Variation Range | Example |
|----------|-----------|-----------------|---------|
| Navigation | 8 (LOOK, EXAMINE, READ, SEARCH, FEEL, SMELL, TASTE, LISTEN) | 12-18 per verb | FEEL: "feel around", "touch", "grope", "run fingers" |
| Inventory | 7 (TAKE, GET, PICK, GRAB, DROP, INVENTORY, PUT, OPEN, CLOSE) | 10-20 per verb | TAKE: "grab", "pick up", "snatch", "collect" |
| Interaction | 8 (LIGHT, STRIKE, EXTINGUISH, BREAK, TEAR, WRITE, CUT, SEW, PRICK) | 10-18 per verb | STRIKE: "strike match on matchbox", "rub against", "friction" |
| Movement | (GO + directions) | 8+ per direction | "go north", "north", "n", "head north", "walk north" |
| Meta | 2 (HELP, QUIT) | 5-8 per verb | QUIT: "quit", "exit", "goodbye", "bye" |

**Total: ~400+ variations**

## Training Pipeline Integration

### What Bart's Script Does
1. Reads all variations from this matrix
2. For each variation, generates an embedding vector
3. Groups vectors by canonical verb (training label)
4. Trains the embedding model to cluster variations by verb
5. Produces a lookup table: embedding → verb

### What QA Phase Does
1. Takes a subset of variations from this matrix
2. Passes them through the embedding matcher
3. Validates that the matcher returns the correct canonical verb
4. Catches any misclassifications or edge cases

## Impact

**Parser Team (Bart):**
- Training data for embedding model now defined
- Clear specifications for what variations to expect
- Confidence that all major edge cases are covered

**QA Team:**
- Clear test plan: validate all variations map to correct verbs
- Context variations give testing depth (darkness, tools, containers)
- Pronoun resolution scope is defined

**Design Team:**
- Command variation matrix is canonical reference
- Future verbs should follow same pattern
- Sensory hierarchy is now documented

**Player Experience:**
- Game understands ~400 variations of natural player input
- Darkness gameplay is proven viable (sensory hierarchy)
- Tool verbs teach real-world logic through mechanics

## Approval

**Ready for:** Wayne "Effe" Berry (Project Owner), Bart (Parser/Architecture), QA Lead  

---

### 24. Directive: No Fallback Past Tier 2 — Parser Directive

**Author:** Wayne "Effe" Berry (via Copilot)  
**Date:** 2026-03-19T17-22-26Z  
**Type:** System Architecture Directive  
**Status:** Active  
**Firmness:** FIRM

## The Directive

No fallback to natural language / "I don't understand" in the parser pipeline. The embedding matcher (Tier 2) should be the terminal tier — if it doesn't match, the command fails. This keeps the SLM testable.

## Rationale

If there's a fallback that papers over misses, it becomes impossible to measure what the SLM/embedding matcher is actually catching vs missing. Testability of the embedding parser is a priority.

## Implementation Implication

**Tier 1 (Rules)** → **Tier 2 (Embedding)** → **FAIL** (no Tier 3)

If the embedding matcher cannot confidently match the player's command to any verb, return a visible error rather than attempting LLM fallback or natural language guessing.

**Error Format:** `[UNKNOWN COMMAND]` or similar, encouraging player to try `HELP` for verb listing.

---

### 19. FSM Definitions Live Inline in Object Files (2026-03-20)
**Author:** Bart (Architect), per Wayne's directive  
**Date:** 2026-03-20  
**Status:** Implemented  
**Affects:** All FSM-managed objects, engine/fsm, engine/verbs

FSM state definitions are embedded directly in the object file. One file = one object = one FSM. The `src/meta/fsms/` directory has been deleted.

**Format:**
```lua
return {
    id = "match",
    keywords = {"match", "stick"},
    size = 1, weight = 0.01, portable = true,
    initial_state = "unlit",
    _state = "unlit",
    states = {
        unlit = { name = "a wooden match", casts_light = false, ... },
        lit   = { name = "a lit match", casts_light = true, on_tick = function(obj) ... end },
        spent = { name = "a spent match", terminal = true },
    },
    transitions = {
        { from = "unlit", to = "lit", verb = "strike", requires_property = "has_striker" },
        { from = "lit", to = "spent", trigger = "auto", condition = "duration_expired" },
    },
}
```

**Detection:**
- `obj.states` exists → FSM-managed
- `obj.states` absent → plain object (backward compatible)
- `_fsm_id` is retired

**Hybrid Model:**
Objects can have BOTH `states`/`transitions` (FSM for reversible state changes) AND `mutations` (for destructive transformations). Example: curtains use FSM for open/close, mutations for tear.

**Rationale:**
- Eliminates file scatter (4 vanity files → 1)
- Single source of truth per object
- FSM engine unchanged in purpose, just reads from a different location
- Verb handlers check `obj.states` instead of `obj._fsm_id`

---

### 20. FSM Transition Alias Pattern (2026-03-20)
**Author:** Bart (Architect)  
**Date:** 2026-03-20  
**Status:** Implemented  
**Context:** Play Test Bug Fixes — FSM object design

FSM transition definitions can carry an `aliases` array field (e.g., `aliases = {"light", "ignite"}`). The FSM engine itself does NOT interpret this field — verb handlers are responsible for checking it when deciding whether to delegate to another verb's handler.

**Rationale:**
The match FSM defines a `strike` transition. Players naturally say "light match" not "strike match". Rather than duplicating FSM transitions for each synonym verb or adding synonym resolution to the FSM engine, verb handlers check for FSM transitions matching their verb or its known aliases, then delegate to the canonical verb handler. This keeps the FSM engine simple and puts synonym knowledge in the verb layer where it belongs.

**Implications:**
- New FSM objects that need verb synonym support should add `aliases` arrays to their transitions
- The verb handler (not the FSM engine) is the authority on verb synonyms
- This pattern scales: any verb handler can check any FSM transition's aliases before falling back to "can't do that"

---

### 21. User Directive: Empirical LLM Testing — No Predefined Scripts (2026-03-20)
**Author:** Wayne "Effe" Berry (via Copilot)  
**Date:** 2026-03-20  
**Type:** Testing Methodology  
**Status:** Active  

Nelson (Tester) must use his LLM intelligence to test the game -- NOT predefined scripts or unit tests. He should play the game like a real player would: think about what to try, type natural language commands, react to what happens, try unexpected things. No scripted test sequences, no assert statements, no automation frameworks. Just run `lua src/main.lua`, play, think, and report what breaks.

**Why:** The whole point of having an AI tester is that it can improvise, not follow a checklist. Predefined scripts only test what you already thought of. An LLM tester finds what you didn't.

**Outcome:** First playtest found 7 bugs in critical path (window state, match countdown, text wrapping, prepositions, bare verbs, drink verb, typos).

---

### 22. User Directive: Playtest Transcripts at Repo Root (2026-03-20)
**Author:** Wayne "Effe" Berry (via Copilot)  
**Date:** 2026-03-20  
**Type:** Artifact Organization  
**Status:** Active  

Nelson's play test reports go to `test-pass/` at the repo root (NOT in .squad/). Each file should show both sides of the interaction (input AND output) and be dated with pass numbers. Format: `test-pass/YYYY-MM-DD-pass-NNN.md`. The file should be a readable transcript of the full interactive session so Wayne can see exactly what the tester typed and what the game responded.

**Why:** Play test transcripts are a product artifact, not squad internal state. They belong at the repo root where Wayne can review them easily.

---

### 23. User Directive: Incremental Playtest Output — Stream to File (2026-03-20)
**Author:** Wayne "Effe" Berry (via Copilot)  
**Date:** 2026-03-20  
**Type:** Testing Infrastructure  
**Status:** Active  

Nelson must write his test-pass output file incrementally AS HE PLAYS -- not just at the end. Each command/response pair gets appended to the file immediately. This way if the session crashes or times out, the transcript so far is preserved. Write to `test-pass/YYYY-MM-DD-pass-NNN.md` and append after each interaction.

**Why:** If Nelson's session dies mid-play, you lose the whole transcript. Streaming to file preserves progress.

---

### 24. User Directive: Wearable System Architecture (2026-03-20)
**Author:** Wayne "Effe" Berry (via Copilot)  
**Date:** 2026-03-20  
**Type:** Game Design  
**Status:** Designed, pending implementation  

Some objects are wearable (e.g., the cloak). Objects need a `wearable = true` property and a WEAR verb that moves them from inventory to a "worn" slot. Worn items should affect gameplay -- a cloak might provide warmth, a bandage might stop bleeding. The WEAR/REMOVE verbs need to work with the FSM system if the wearable has states (e.g., cloak: folded → worn → torn).

**Why:** Design directive for wearable object category. Expands the object property system.

---

### 25. User Directive: Wearable Slot System — Objects Define Wear Metadata (2026-03-20)
**Author:** Wayne "Effe" Berry (via Copilot)  
**Date:** 2026-03-20  
**Type:** Game Design  
**Status:** Designed, pending implementation  

Wearable objects define their own wear slots and layering rules -- the object knows where it goes, not the engine.

**Design Principles:**

1. **Wear slots are defined on the object**, not hardcoded in the engine. e.g., `wear_slot = "head"`, `wear_slot = "torso"`, `wear_slot = "feet"`. The engine just checks for conflicts.

2. **Slot conflict rules:** Only one item per slot UNLESS layering is allowed. A hat goes on "head" -- if you try a second hat, it fails ("You're already wearing a hat"). The object doesn't need to say "put it on my head" -- the engine infers from wear_slot.

3. **Layering:** Some slots support layers. A cloak (`wear_layer = "outer"`) can go over a shirt (`wear_layer = "inner"`). But two outer layers conflict. Two inner layers conflict. The object defines its layer.
   - Examples that work: shirt (inner) + cloak (outer), shirt (inner) + armor (outer)
   - Examples that fail: two hats, two pairs of pants, two pairs of shoes, two sets of armor

4. **Slot list lives on the object:**
   ```lua
   wearable = true,
   wear_slot = "head",      -- where it goes
   wear_layer = "outer",    -- layering (inner/outer/accessory)
   ```

5. **The engine's job is simple:** check if the slot+layer combo is already occupied. The object provides all the metadata.

6. **Flexibility:** New slots can be invented by new objects without changing the engine. A ring could use `wear_slot = "finger"`. Gloves use `wear_slot = "hands"`. The engine doesn't need to know about these in advance.

**Why:** Objects own their wear metadata, engine just enforces slot/layer conflicts. This keeps the system extensible without engine changes.

---

### 26. User Directive: Wearable-Container Dual Property (2026-03-20)
**Author:** Wayne "Effe" Berry (via Copilot)  
**Date:** 2026-03-20  
**Type:** Game Design  
**Status:** Designed, pending implementation  

Some wearable objects are also containers:
- **Backpacks:** wearable (wear_slot = "back") AND container. You wear it and it holds stuff.
- **Sacks/bags:** can be worn on head (wear_slot = "head") but **blocks vision** -- if worn on head, player can't see (casts_blindness = true or similar). Encode this in the Lua object.
- **Pots:** can be worn on head as a bad helmet (wear_slot = "head", wear_quality = "improvised"). Provides minimal protection but looks ridiculous.

Key principle: Objects can be BOTH wearable AND containers. The object defines what happens when worn -- a backpack on your back is useful, a sack on your head is blinding. The object's wear metadata controls the gameplay effect, not the engine.

This means `wearable = true` and `container = true` can coexist on the same object. When worn, the container's contents are still accessible (backpack) or become inaccessible (sack over head -- you can't reach in).

**Why:** Wearable + container intersection. Objects define their own gameplay effects when worn. Emergent behavior from combining properties.

---

### 27. User Directive: Chamber-Pot Inheritance — Pot Base Class (2026-03-20)
**Author:** Wayne "Effe" Berry (via Copilot)  
**Date:** 2026-03-20  
**Type:** Game Design  
**Status:** Designed, pending implementation  

Chamber-pot is a type of pot (inherits from pot base class). Pots can be worn on your head as improvised head armor. So: chamber-pot is wearable (wear_slot = "head", wear_layer = "outer"). Yes, this means you can wear a chamber pot on your head. It's a terrible helmet but it works. The object hierarchy matters here -- pot is a base type, chamber-pot inherits pot's wearability.

**Why:** Establishes object inheritance (base class → subtype) and confirms pots-as-helmets gameplay. The chamber pot on head is both functional (head protection) and hilarious (it's a chamber pot).


---

### 28. Nelson — Play Test Pass 002 Bug Report (2026-03-20)
# Nelson — Play Test Pass 002 Bug Report
**Date:** 2026-03-20  
**Author:** Nelson (Tester)

## Key Finding: Poison Has No Consequence

**BUG-008** is the highest priority finding. Drinking poison produces great narrative text ("the world goes dark...") but the player suffers no actual consequence — they wake up 4 hours later and continue playing. This needs a design decision:

1. **Option A:** Poison kills the player → game over screen
2. **Option B:** Poison causes lasting debilitation (blurred vision, weakness, countdown timer)
3. **Option C:** Current "blackout + time skip" is intentional (if so, needs clearer wakeup text)

## Parser Debug Leaking (BUG-009)

The `[Parser] No match found...` diagnostic output is being shown to players when commands don't match. This should be suppressed and replaced with a player-friendly "I don't understand" message. This was noted as "no feedback on failed parses" in pass 001 — it's actually the opposite problem now: *too much* raw feedback.

## Full Bug List: BUG-008 through BUG-014

See `test-pass/2026-03-20-pass-002.md` for complete reproduction steps.

## What's Working Well

- Matchbox container inventory tracking is solid
- Poison bottle FSM has 4 distinct visual states and 3 smell states
- Container nesting (matchbox in sack) works
- Wear system works
- "take match from matchbox" prepositional parsing works
- "put match in matchbox" returns match and count updates


---

### 29. Frink — MUD Verb Research & Strategic Implications (2026-03-20)
# Frink's MUD Verb Research — Strategic Implications for Our Multiplayer Game

**Date:** 2026-07-25  
**Research Report:** `resources/research/competitors/mud-clients/verbs.md` (27KB)

## Executive Summary

MUDs represent the most mature multiplayer text adventure verb system in existence. Our research revealed a critical insight: **multiplayer text adventures require 5-10× more verbs than single-player IF**, not because mechanics are more complex, but because social coordination (party, guild, chat channels) and commerce introduce entirely new verb categories.

This research identifies three strategic decisions for our game design:

1. **Multiplayer Verbs as First-Class Primitives** — Party, guild, and economy verbs should be designed into the core system from day one, not bolted on later.
2. **Social Verbs Drive Retention** — A small catalog of predefined socials (50+) enables roleplay and significantly increases engagement.
3. **Natural Language Parsing Enables Better UX** — Accept multiple phrasings of the same command (e.g., `get apple`, `take the apple`, `pick up the apple`).

---

## Key Findings

### Multiplayer MUDs Have 300-500+ Verbs vs. 20-40 in Single-Player IF

| Game Type | Typical Count | Breakdown |
|-----------|---------------|-----------|
| Classic IF (Infocom) | 20-40 | Core verbs only |
| CircleMUD | 170+ | 40 base + 50 socials + 80 spells |
| Discworld MUD | 300-500+ | 80 core + 150 standard + 200+ socials + 50-100 guild/skill |
| Achaea (Modern) | 250-400+ | 100 universal + 50-100 class-specific + 100+ skill-based |

**The Gap:** Multiplayer verbs account for 30-40% of the total. These include:
- **Party verbs:** party create, invite, accept, leave, info, chat, assist, follow, rescue (9 verbs)
- **Guild verbs:** guild create, invite, join, leave, info, chat, promote, demote, disband, tribute, withdraw (11 verbs)
- **Economy verbs:** auction, bid, bank, trade, offer, accept trade (6 verbs)
- **PvP verbs:** challenge, duel, pvp toggle, track, yield, surrender (6 verbs)
- **Social verbs:** emotes and roleplay commands (200+ in Discworld MUD)

**Single-Player IF has zero of these verb categories.**

---

### Social Verbs Drive Long-Term Retention

**Finding:** Discworld MUD features 200+ predefined "soul" commands (emotes) with minimal mechanical impact.

- Examples: wave, smile, laugh, bow, nod, shrug, hug, kiss, slap, bite, punch, dance, prance, cower, salute, wink, and dozens more
- These verbs provide **zero mechanical reward** (no XP, no damage, no progression)
- Yet they are used frequently and enable core roleplay functionality
- MUSH games (social-focused MUDs) prioritize socials; some have zero combat verbs but 200+ emotes

**Implication:** Our game should include 50-100 predefined socials from MVP. They are retention drivers, not after-thoughts.

---

### Natural Language Parsing Enables Superior UX

**Finding:** LPMud-based systems (Discworld MUD, Islands of Myth) accept multiple phrasings of the same command.

**Example:** All of these work identically:
- `get apple`
- `take the apple`
- `pick up the apple`
- `get all apples`
- `get all but the knife`

**Contrast:** CircleMUD (C-based, rigid dispatch) requires exact syntax. Phrasings like "pick up" fail silently.

**Implication:** Our Tier 2 embedding parser should aim for this flexibility. It's a UX multiplier—especially on mobile where typing is painful. Combined with tap-to-suggest UI, this could be a differentiator vs. competitors.

---

### Abbreviations Are Mandatory, Not Optional

**Finding:** Every successful MUD supports single-letter abbreviations for frequent verbs.

- Movement: `n`, `s`, `e`, `w`, `u`, `d` (never typed out in practice)
- Inventory: `i` (for inventory), `l` (for look)
- Combat: `k` (for kill), `a` (for attack)

**Why They Matter:**
1. **Speed** — Single letter vs. full word during high-stress combat
2. **Muscle Memory** — Enables rapid reflexive patterns
3. **Accessibility** — Reduces cognitive load for new players

**Implication:** Design abbreviations into the verb system from day one. Don't retrofit them later.

---

### Verb Systems Vary Dramatically by Architecture

Three dominant architectures emerged:

#### 1. C-Based (DikuMUD / CircleMUD): ~170 Verbs
- Fixed command dispatch model
- No natural language parsing
- Rigid syntax requirements
- Adding verbs often requires recompile

#### 2. LPC-Based (LPMud / MudOS): ~300+ Verbs
- Natural language parser built into driver
- Verbs registered with parsing rules
- Dynamic verb registration (no recompile)
- Flexible syntax; multiple phrasings accepted
- **Modern Example:** Discworld MUD (300-500 verbs)

#### 3. Social-Focused (MUSH/MOO): ~200-300 Verbs
- Minimalist mechanical verb set
- Extensive predefined socials (100-200+)
- Emphasis on roleplay over mechanics
- Often zero combat verbs

**Implication:** Our architecture should lean toward LPC-style natural language parsing. This enables both rich mechanical depth (for combat, crafting) and social expression (for roleplay).

---

### Multiplayer Verbs Require New Game State

**Critical Insight:** Party, guild, PvP, and economy verbs cannot be tacked on to a single-player engine. They require new game state and persistence semantics:

- **Party verbs** require: party roster, group-wide buffs/debuffs, shared loot rules, tactical targeting
- **Guild verbs** require: guild roster, persistent guild treasury, permission hierarchy, guild chat channels
- **PvP verbs** require: PvP flags, faction alignment, guard rules, murder reputation
- **Economy verbs** require: shared auction house, player-to-player trades, market history, transaction logs

**Implication:** These should be **designed into the core architecture from day one**, not retrofitted as expansions. Their absence in single-player IF is the key difference between IF and MUDs.

---

### Alias System Enables Power-User Customization

**Finding:** MUDs provide an `alias` command allowing custom shortcuts and command chaining.

**Examples:**
- `alias loot get all from corpse; put all in bag; sit` (loot automation)
- `alias setup inv; eq; score; who` (quick status check)
- `alias flee cast feetwings; west; north; south` (tactical escape)

**Implication:** A post-MVP alias system could be a differentiator. Top MUD players maintain 50+ aliases for rapid responses. This could drive engagement and power-user retention.

---

## Strategic Recommendations

### Phase 1: Core Verbs (MVP)
Implement a minimal verb set; no multiplayer verbs yet:

**Navigation:** north, south, east, west, up, down, enter, leave, go, look, examine (11)  
**Inventory:** get, drop, inventory, wear, remove, take, put, give (8)  
**Interaction:** open, close, push, pull, read (5)  
**Information:** score, help, commands, look, search (5)  
**Social:** say, emote, shout (3)

**Total MVP:** ~30 verbs

**Design Commitment:** Abbreviations (`n`, `i`, `l`, etc.) must be built into the system from day one.

---

### Phase 2: Multiplayer Additions
Add multiplayer-specific verbs and basic socials:

**Communication:** tell, reply, gossip (3)  
**Multiplayer Mechanics:** 
- Party: party create, party invite, party accept, party leave, party chat, follow, assist (7)
- Guild: guild create, guild invite, guild leave, guild chat (4)
- Trade: trade, auction, bid (3)
- PvP: challenge, duel (2)

**Social/Emotes:** 50 predefined socials (wave, smile, laugh, bow, hug, etc.) (50)

**Total Phase 2:** ~70 new verbs (100 cumulative)

**Design Commitment:** Multiplayer verbs should be first-class, not bolted-on. Party and guild systems should feel integrated from day one.

---

### Phase 3: Expansion (Post-MVP)
Deepen verb system as content scales:

**Crafting:** craft, brew, forge, cook, weave, enchant, disenchant, smith, carve (9)  
**Magic:** cast, chant, invoke, memorize, scribe, summon, conjure (7)  
**Advanced Socials:** Expand emote library to 100+ variants (50 additional)  
**Economy:** Guild treasury, faction rep, specialized trading, banking verbs (10+)  
**Aliases:** Support custom alias creation and chaining (system addition)

**Total Phase 3:** ~100 new verbs (200+ cumulative)

---

### Design Philosophy
1. **Abbreviations First:** Every verb must have a designed abbreviation.
2. **Multiplayer as First-Class:** Party and guild verbs are core, not optional.
3. **Social Verbs Matter:** 50-100 predefined socials enable roleplay and retention.
4. **Scalable Discovery:** Verbs unlock progressively (fresh character ~30 verbs, max-level ~200+ verbs).
5. **Natural Language Parsing:** Accept multiple phrasings (our Tier 2 embedding parser should target this).

---

## Questions for the Squad

1. **Multiplayer-First Architecture:** Should our core engine be designed for multiplayer from day one, even if MVP is single-player? (Our recommendation: Yes—retrofitting multiplayer verbs later would be painful.)

2. **Social Verb Investment:** How much effort should go into predefined socials for MVP? (Our recommendation: 50 minimal; 100 preferred. They're retention drivers.)

3. **Natural Language Parsing:** Should Tier 2 embedding parser accept multiple phrasings, or stick to exact match only? (Our recommendation: Multiple phrasings—UX multiplier, especially on mobile.)

4. **Abbreviation System:** Should we build abbreviations into the verb system from day one, or retrofit them later? (Our recommendation: From day one; retrofitting is error-prone and confusing.)

5. **Alias System:** Should this be a Phase 2 or Phase 3 feature? (Our recommendation: Phase 3, post-MVP. Post-MVP feature for power-user retention.)

---

## Implementation Notes

- **Verb Dispatch:** Consider LPC-style natural language parser (see Discworld MUD, Islands of Myth)
- **Verb Registration:** Dynamic registration (no recompile for new verbs) enables rapid iteration
- **Parsing Rules:** Specify allowed syntax patterns (at LIV, in OBJ, with OBJ) for flexibility
- **Verb Aliases:** Build into verb system natively; don't bolt on as afterthought
- **Social Verbs:** Pre-populate with 50-100 socials; enable builder creation of custom socials post-MVP

---

## References

- Full report: `resources/research/competitors/mud-clients/verbs.md`
- Discworld MUD Wiki: https://dwwiki.mooo.com/wiki/Category:Commands
- CircleMUD GitHub: https://github.com/Yuffster/CircleMUD/blob/master/lib/text/help/commands.hlp
- Islands of Myth LPC Parser: http://islandsofmyth.org/wiz/parser_guide.html
- Achaea Wiki: https://wiki.achaea.com/Newbie_Guide

---

## Next Steps

1. **Team Review:** Review this decision and strategic recommendations with squad.
2. **Verb Planning:** Create detailed verb registry for Phase 1 MVP.
3. **Parser Design:** Specify natural language parsing rules and abbreviation system.
4. **Social Verb Library:** Curate 50-100 predefined socials for launch.
5. **Multiplayer Design:** Architect party/guild systems with verb dispatch in mind.


---

### 30. Frink — Competitive Landscape Findings (2026-03-20)
# Decision: Competitive Landscape Findings — Strategic Implications

**Agent:** Frink (Researcher)  
**Date:** 2026-07-24  
**Status:** PROPOSED  
**Relates to:** Decisions 17, 19; Parser architecture; Multiplayer design

## Context

Completed competitive analysis of 16 mobile text adventure / interactive fiction competitors across parser-based, choice-based, MUD/multiplayer, and narrative game categories.

## Key Strategic Decisions Proposed

### 1. Tap-to-Suggest UI Is Required (Not Optional)

Every parser game on mobile suffers from "typing on phones sucks." Choice-based games dominate downloads *specifically because* they eliminated typing. Our embedding parser solves the NLP problem, but we still need a **tap-to-suggest interface** that displays contextual verb/noun options alongside the text input. This makes the parser feel like a choice game for casual players while preserving free-form input for power users.

**Evidence:** Frotz (4.8★ but keyboards are top complaint), Son of Hunky Punk (word-tap feature is most praised UX), Choice of Games (240K downloads with zero typing).

### 2. Async Multiplayer First, Real-Time Later

80 Days' asynchronous multiplayer (seeing other players on a globe without direct interaction) is the most elegant solution studied. Low server cost, high emotional impact. Our first multiplayer feature should be async — show other players' universe states, discoveries, or progress. Real-time MUD-style multiplayer is expensive and fragile.

**Evidence:** 80 Days (BAFTA-nominated, 4.5★), Torn City (1M+ downloads but clunky), MUDs (decades of server maintenance burden).

### 3. Ship Complete Experiences

Magium's #1 complaint is unfinished content despite 1.3M downloads and 4.9★ rating. Players hate waiting for incomplete stories. Each release should be a **complete, self-contained experience** — even if small. Better to ship a perfect 2-hour game than a 20-hour game missing its ending.

### 4. A Dark Room's Progression Model Is the Template

A Dark Room's genre-evolution (idle → resource management → exploration RPG) is the most successful text game structure ever created (#1 App Store). Our "start in darkness" should similarly transform — from tactile exploration to puzzle-solving to world-building to multiplayer discovery. Each phase should feel like a new game.

### 5. Our Biggest Risk Is Discovery, Not Quality

As a PWA without app store presence, we face the same discovery problem as Twine games (thousands exist, nobody can find them) and Kingdom of Loathing (20-year community but zero mobile presence). We need a distribution strategy beyond "build it and they'll come."

## Recommendation

Proceed with current architecture (Lua engine, Wasmoon PWA, embedding parser). Add tap-to-suggest UI to parser roadmap. Design first multiplayer feature as async. Plan content releases as complete chapters.


---

### 31. Copilot Directive — Detachable Parts & Two-Handed Carry (2026-03-20T01:26Z)
### 2026-03-20T01:26Z: User directive — Detachable object parts + two-handed carry
**By:** Wayne Berry (via Copilot)
**What:**
1. **Detachable parts:** Instances of objects can come apart and become their own independent object instances. Examples:
   - The nightstand drawer can be pulled out entirely and carried as a container.
   - The poison bottle has a cork; when removed, the cork becomes its own object instance (with a backing object file). The cork could later be used as a fishing float, etc.
   - Each detached part has its own object file defining its properties.
2. **Two-handed carry:** Some objects require two hands to carry. This implies a hand-slot system where the player has two hands and some objects occupy both.

**Why:** User request — enables emergent gameplay through object decomposition. Parts become puzzle pieces in new contexts (cork → fishing float). Two-handed carry adds tactical inventory decisions.


---

### 32. Bart — Wearable Object System Architecture (2026-03-20)
# Decision: Wearable Object System Architecture

**Author:** Bart (Architect)
**Date:** 2026-03-25
**Status:** Implemented
**Impact:** Engine architecture, object metadata, verb system

## Decision

Wearable items use **object-owned metadata** (`wear = { slot, layer }`). The engine enforces conflicts but never hardcodes slot names — any string is a valid slot. This means new body locations can be invented by content authors without engine changes.

## Key Rules

1. **One inner + one outer per slot** — accessories are unlimited (up to `max_per_slot`)
2. **Vision blocking** is a wear property (`blocks_vision = true`), checked separately from room darkness
3. **Legacy support** — objects with `wearable = true` but no `wear` table default to `torso/outer`
4. **Player.worn** is a flat list (same pattern as `player.hands`) — slot queries iterate it

## Rationale

- Matches D-14 (objects own their own state) — wear metadata lives in the object file
- No enum of valid slots means content can grow without engine PRs
- Flat worn list is simple and sufficient — slot-indexed maps would add complexity for marginal gain at current scale

## Files Changed

- `src/engine/verbs/init.lua` — wear/remove handlers, conflict algorithm, vision blocking
- `src/engine/loop/init.lua` — NLP preprocessing for put on/take off
- `src/meta/objects/` — wool-cloak, sack, chamber-pot, terrible-jacket wear metadata

