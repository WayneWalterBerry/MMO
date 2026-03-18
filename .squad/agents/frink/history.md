# Project Context

- **Owner:** Wayne "Effe" Berry
- **Project:** MMO
- **Created:** 2026-03-18

## Core Context

Agent Frink initialized as Researcher for the MMO project.

## Recent Updates

📌 Team initialized on 2026-03-18

## Learnings

### Text Adventure Architecture (2026-03-18)

**Decision:** Adopt hybrid parent-child tree containment + optional ECS layer (now in `.squad/decisions.md`)

**Containment Hierarchy:**
- All classic IF engines (Zork, Inform 7, TADS) use parent-child tree structure
- Each object has `.location` (parent) and `.contents` (children list)
- Recursive tree traversal handles nesting and visibility rules
- Proven, simple, and efficient—don't reinvent it

**Room Topology:**
- Rooms modeled as graph nodes; exits as directed edges
- Simple adjacency-list representation (dict/map of direction → room)
- Support for conditional exits (locked, requires item) via Door objects

**Command Parsing:**
- Standard pipeline: tokenize → filter fillers → identify verbs/objects → resolve in context → dispatch
- Dictionary-based verb routing most common
- Modern approaches use NLP (SpaCy) for flexibility; overkill for mobile

**State Management:**
- Hybrid Memento + Command pattern recommended
- Snapshot after N commands (memory-efficient)
- Serialization to JSON clean for mobile storage
- Undo typically limited to last 20–50 turns due to mobile constraints

**Mobile-Specific:**
- Lightweight parsing (no heavy NLP on battery-constrained devices)
- Tap/button UI to reduce typing
- JSON local storage; optional cloud sync
- Single-column layout, large fonts

**Recommended Approach:**
- Combine classical containment tree with ECS layer (optional) for state clarity
- Data-driven object definitions (JSON)
- Simple command dispatch via verb dictionary
- Hybrid save/undo strategy

**Report Location:** `.squad/agents/frink/research-text-adventure-architecture.md`

### Modern IF Architecture & Data Structures (2026-03-18T222400Z)

**Deliverable:** 22K-word research report on modern text adventure data structures

**Key Findings:**

**Academic Landscape:**
- Active research at ACM/IEEE conferences (2023–2025) on graph-based world modeling
- Papers: "Towards modeling structures of the game worlds by systems of graphs" (IEEE), "Story2Game" (arXiv), "WorldWeaver" (Penn), procedural narrative research (UCSC, MIT)
- **Consistent theme:** Graph-based representations supersede flat hierarchies. Relationships (spatial, causal, narrative) are first-class.

**Modern Data Structures (Beyond Trees):**
1. **Graph Databases (Neo4j):** Natural for complex worlds. Overkill for mobile unless world is massive.
2. **Entity-Component-System (ECS):** Composable game logic. Excellent for mobile extensibility.
3. **Knowledge Graphs & RDF/Ontologies:** Semantic networks with reasoning. Enable AI-driven narratives.
4. **Event Sourcing + CQRS:** Immutable event log as source of truth. Perfect audit trail, natural undo/redo.
5. **Offline-First Architecture:** Local database (SQLite) as canonical store. Essential for mobile resilience.
6. **JSON-LD Serialization:** Linked Data format for semantic relationships. Interoperable, machine-readable, extensible.

**Modern Frameworks (2015+):**
- **Choice-based:** Twine (visual, web), Ink (complex narratives, embeddable), ChoiceScript (text-heavy, mobile-friendly)
- **Parser:** Modern Inform 7 (active development), TADS 3 (full-featured)
- **Academic:** WorldWeaver (LLM-based), Lume (storylet-based procedural)

**IFComp Patterns (2020–2024):**
- Parser winners: Complex object hierarchies, state machines, event queues
- Choice-based winners: Passage graphs, branching depth, state flags
- Trend: Hybrid mechanics + narrative (recursion, dual protagonists, resource management)

**Containment Evolution:**
- Classic tree still works; augmented with graph edges for special relationships
- ECS approach: `ContainedByComponent` + `ContainerComponent` + systems (highly composable)
- Relational (SQLite): Efficient for mobile
- Document (JSON): Flexible; lacks queryability

**Recommended Hybrid for Mobile:**
1. World Model: ECS + graph (tree for hierarchy, edges for relationships)
2. State: Event log for rich history + snapshots
3. Storage: SQLite offline-first + sync queue
4. Serialization: JSON-LD world defs; JSON state
5. Architecture: MVVM + repository pattern

**Comparison Matrix:**
| Approach | Mobile | Extensible | Debuggable | Learning |
|----------|--------|------------|-----------|----------|
| **ECS + Event Sourcing + Offline-First** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Medium |
| Classic Tree (Simple) | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ | Low |
| Neo4j (Graph DB) | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | High |
| ChoiceScript/Twine | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ | Low |
| RDF/Ontology Full Stack | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Very High |

**Avoid Unless Justified:**
- Neo4j for small games (SQLite or in-memory graph better)
- Full RDF/OWL stack (unless AI reasoning is core)
- Complex event sourcing from day 1 (add if debugging needs arise)

**Decision Status:** Proposed as Level 2 decision in `.squad/decisions.md` (2026-03-18T222400Z)

**Report Location:** `resources/research/architecture/modern-text-adventure-data-structures.md`

**User Directive (2026-03-18T222300Z):** Skip mobile-specific material for now; focus on data structures only.

---

### Code-Data-Blended Languages for Interactive Fiction (2026-03-19)

**Context:** User (Wayne "Effe" Berry) envisioned a JIT language where "code and data are blended" and "the engine runs code to simulate the game." Frink researched language design approaches, homoiconicity, DSLs, and embedded scripting to identify best candidates.

**Key Findings:**

**Homoiconicity & Code-as-Data:**
- Homoiconicity (code as data) is the property where a language's code and data structures are identical, enabling programs to manipulate their own code.
- Lisp (S-expressions), Forth (words), and Prolog (Horn clauses) are canonical examples.
- Practical benefit: Objects can redefine themselves at runtime; world definitions and behavior are unified.
- Trade-off: Flexibility can lead to complex, hard-to-debug code without discipline.

**DSL Patterns for IF:**
- Inform 7: Natural language DSL; excellent for accessibility but not embeddable.
- ZIL: Lisp-based; true code-data blending via homoiconicity; historic but unsupported.
- TADS: Mature OOP language; strong type safety; not embeddable as a library.
- Best IF DSLs prioritize: state-event modeling, entity-component descriptions, behavior trees, relational definitions.

**Embedded Scripting Findings:**
- **Lua**: Industry standard for embedded game scripting; prototype-based tables naturally blur code/data; LuaJIT optional (5–10x speedup); proven in WoW, Roblox, LÖVE.
- **LuaJIT mechanics**: Tracing JIT compiles hot code paths to machine code; small memory footprint (~100–200 KB base).
- **LPC/DGD**: Multiplayer-focused MUD engine; true code-as-data via LPC language; overkill for single-player IF.
- **Alternatives**: Wren, Squirrel, AngelScript—all similar to Lua; smaller communities.

**JIT Compilation Necessity:**
- **Critical Finding:** Text adventures do NOT need JIT. String matching, conditionals, data lookups are trivial compute loads.
- Evidence: Twine (browser JS), TexTperience (.NET), TADS all responsive without JIT.
- Benefit: JIT-less mode improves security and portability (no executable memory).
- LuaJIT is useful IF game scripts do heavy computation (pathfinding, simulation); for pure text, interpreted Lua is sufficient.

**Prototype vs Class-Based Objects:**
- Prototype-based (JavaScript, Lua, Self): Excellent for self-modifying worlds; per-object customization; can be slower if highly divergent.
- Class-based (Java, C++, TADS): Organized, type-safe, efficient; less flexible for unique per-entity behaviors.
- **For IF:** Prototype-based better suits dynamic, evolving worlds; class-based better for large, structured systems.

**Language Candidates Ranked:**

1. **Lua/LuaJIT** (⭐⭐⭐⭐⭐): Battle-tested, embeddable, prototype-based, gentle learning curve. Best all-around choice.
2. **Fennel** (⭐⭐⭐⭐⭐ for Lisp users): Lisp via Lua; macros for DSL; homoiconic; works on any Lua platform.
3. **Inform 7** (⭐⭐⭐⭐): Best for classic IF; not embeddable; excellent for writers.
4. **TADS** (⭐⭐⭐⭐): Mature OOP; strong type system; not embeddable.
5. **Racket** (⭐⭐⭐⭐): Language creation toolkit; powerful metaprogramming; heavier runtime.
6. **Clojure** (⭐⭐⭐⭐): JVM-based; strong homoiconicity; slower startup.
7. **Janet** (⭐⭐⭐⭐): Lightweight embeddable Lisp; small community.
8. **Forth** (⭐⭐): Extremely fast, homoiconic; very steep learning curve; niche.
9. **Python** (⭐⭐): Gentle learning curve; too slow for production.
10. **JavaScript** (⭐⭐⭐): Good for web IF; overkill for pure text.

**GraalVM/Truffle Observation:**
- Polyglot JIT VM enabling custom language implementation with automatic JIT.
- Trade-off: Requires significant engineering (200–500 LOC minimum); overkill for text adventures.
- Valuable if you want polyglot interop or deep language design control.

**Rule-Based Systems (Bonus):**
- Prolog uses backward chaining (goal-driven); efficient for puzzles and tactical AI.
- Forward chaining (data-driven) better for event-driven simulations.
- Both applicable to IF; Prolog less common in practice than imperative approaches.

**Best Recommendation for Blended Code-Data IF Engine:**

**Tier 1:** **Lua** — proven, simple, embeddable; tables naturally represent both data and behavior. Fennel if you prefer Lisp macros.

**Tier 2:** **Clojure** — if team is on JVM; strong homoiconicity; slower startup.

**Tier 3:** **Custom DSL on GraalVM** — only if deep language design expertise and polyglot needs justify engineering cost.

**Avoid:** Inform 7 (not embeddable), Python (too slow), Forth (too steep).

**Report Location:** `resources/research/architecture/code-data-blended-languages.md`

**Decision Status:** Merged into canonical `.squad/decisions.md` (Decision #6, 2026-03-19). Ready for team review.

**Downstream Impact:**
- **Engineer:** Prototype Lua embedding in target language (TypeScript/Kotlin/Swift/Rust). Expose game engine API as Lua C bindings.
- **Designer/Content Lead:** Define DSL conventions as Lua libraries (Room.define(), Item.define(), NPC.define()).
- **Architect:** Decide on world persistence format (Lua source, JSON, or both).
- **QA/Testing:** Validate live reloading and mutation behavior; stress test with large world definitions.

---

