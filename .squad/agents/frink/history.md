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

