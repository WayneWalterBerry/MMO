# Modern Data Structures and Architectures for Text Adventure Games

**Research Date:** March 2026  
**Prepared by:** Frink, Researcher  
**Scope:** Evolution beyond classic IF engines (Zork, Inform 7, TADS) to modern approaches  

---

## Executive Summary

Modern text adventure architecture has diverged into specialized branches: **choice-based narrative systems** (Twine, Ink), **parser-driven engines** (still evolving from Inform), and **procedural/AI-driven approaches**. The most promising modern pattern for a mobile-first implementation combines:

- **Graph-based world modeling** (Neo4j for complex worlds, JSON graphs for simpler ones)
- **Entity-Component-System (ECS)** for composable game logic
- **Offline-first architecture** with sync queues for mobile resilience
- **Event sourcing** for rich state history and debugging
- **JSON-LD serialization** for semantic relationships and interoperability

---

## 1. Academic Research on IF Data Structures

### 1.1 Key Papers & Publications

**Foundational Resources:**
- **ACM Digital Library** and **IEEE Xplore** host hundreds of papers on game world modeling, data structures for games, and interactive media.
- **IEEE Transactions on Games** publishes state-of-the-art research on world generation, AI-driven narratives, and data structures.

**Notable Recent Papers:**

1. **"Towards modeling structures of the game worlds by systems of graphs"** (IEEE, 2023)
   - Formal model representing game worlds using interconnected graphs for locations, characters, items, and quests.
   - Demonstrates that **graph-based rules** optimize world structure and game mechanics handling.
   - Key insight: Scalable, adaptable IF systems leverage graph abstractions.

2. **"Story2Game: Generating (Almost) Everything in an Interactive Fiction Game"** (arXiv, 2025)
   - Uses LLMs to dynamically generate worlds, interactions, and game code.
   - Touches on **adaptive data structures** that evolve during gameplay to handle player-driven story changes.
   - Highlights challenge of maintaining coherence with dynamic world generation.

3. **"Declarative optimization-based drama management in interactive fiction"** (IEEE, 2024)
   - DODM (Declarative Optimization-Based Drama Management) systems use **complex state representations** to model possible story futures.
   - Enables proactive narrative management by projecting player actions.

4. **Procedural Narrative Research** (UCSC, MIT Media Lab, TU Delft)
   - **Lume** system uses "storylets" (modular narrative nodes) arranged as trees.
   - **All Stories Are One Story** framework maps emotional arcs onto procedural structures.
   - Data structures: **Directed Acyclic Graphs (DAGs), state machines, event queues**.

**Research Collections:**
- **Text Game Research List** (textgames.org): Curated papers on world modeling, automated generation, and agent simulation.

### 1.2 Key Finding
Modern academic work emphasizes **graph-based representations** over flat hierarchies. Relationships (spatial, causal, narrative) are first-class citizens, not afterthoughts.

---

## 2. Modern Data Structures (Beyond Parent-Child Trees)

### 2.1 Graph Databases: Neo4j

**Why:** Natural fit for modeling entities and relationships.

**Structure:**
- Nodes: Rooms, items, NPCs, events, dialogue choices
- Edges: Semantic relationships (`CONTAINS`, `CONNECTS_TO`, `OWNED_BY`, `KNOWS`, `LEADS_TO`)
- Properties: Mutable state (open/closed, taken/found, health, dialogue options)

**Example Cypher Query:**
```cypher
MATCH (hero:Player {name: 'Hero'})-[:IS_IN]->(room:Room)<-[:LOCATED_IN]-(item)
RETURN item
// Returns all items in the room the hero occupies
```

**Strengths:**
- Flexible schema; add new entity types without migrations.
- Fast relationship traversals (no costly SQL joins).
- Natural fit for AI/NPC reasoning and emergent gameplay.
- Visualization tools (Neo4j Bloom) aid debugging and design.

**Weaknesses:**
- Overkill for small, linear games.
- Server overhead not suitable for mobile deployment.

**Use Case:** Large, interconnected worlds with complex NPC behaviors and emergent systems.

---

### 2.2 Entity-Component-System (ECS)

**Core Idea:** Entities (unique IDs) are containers for data-only components. Systems apply logic.

**Example Structure:**

```
Entity 1234 (locked door)
├─ DescriptionComponent { text: "A sturdy oak door" }
├─ OpenableComponent { isOpen: false }
├─ LockableComponent { isLocked: true, keyId: 777 }
└─ InteractiveComponent { verb: "open/unlock" }

System: OpenSystem
- Operates on entities with OpenableComponent
- Checks LockableComponent before allowing action
- Updates isOpen state
```

**Advantages:**
- **Composability:** Mix-and-match behaviors without inheritance hierarchies.
- **Separation of concerns:** Game data decoupled from logic.
- **Runtime flexibility:** Add/remove components to evolve entities (curse an item, make an NPC angry).
- **Extensibility:** New mechanics don't break existing code.

**Mobile Suitability:** Excellent. Scales from tiny games to Disco Elysium-scale experiences.

**Example in Python-like pseudocode:**

```python
class Entity:
    def __init__(self, id):
        self.id = id
        self.components = {}
    
    def add_component(self, name, component):
        self.components[name] = component

class DescriptionSystem:
    def render(self, entity):
        if 'description' in entity.components:
            return entity.components['description'].text

class OpenSystem:
    def try_open(self, entity):
        if 'lockable' in entity.components and entity.components['lockable'].is_locked:
            return "Door is locked."
        entity.components['openable'].is_open = True
        return "Door opens."
```

---

### 2.3 Knowledge Graphs & RDF/Ontologies

**What:** Semantic networks representing relationships with meaning.

**Structure:**
- **RDF Triples:** Subject–Predicate–Object (e.g., `(Hero, holdingItem, Sword)`)
- **Ontologies:** Formal schema defining entity types and valid relationships.
- **Reasoning:** Automatic inference (e.g., if locked door, then player cannot pass).

**Example Ontology:**

```
Entity Types:
- Room, Item, Character, Container

Relationships:
- contains (Room contains Item)
- locatedIn (Item locatedIn Room)
- knows (Character knows Character)
- openable (Room/Container has property)
- locked (Room/Container has property)

Rules:
- if (X locatedIn Room) and (Room isLocked) then X cannot exit Room
- if (Player carriedBy Item) and (Item isCursed) then Player takesDamage
```

**Tools:**
- **Neo4j with Neosemantics plugin:** Adds RDF/OWL support.
- **SPARQL query language:** Query semantic graphs.
- **Protégé:** Ontology editor.

**Strengths:**
- Machine-interpretable; systems can reason about game state.
- Enables dynamic story generation and smart NPC behavior.
- Integrates naturally with AI/LLM systems.

**Weaknesses:**
- Steep learning curve for traditional game developers.
- Overhead for small games.

**Use Case:** AI-driven narratives, smart world reasoning, procedural generation.

---

### 2.4 Event Sourcing + CQRS

**Event Sourcing:** Treat every game state change as an immutable event.

**Structure:**
- Events are the source of truth (e.g., `PlayerMovedToRoom(roomId)`, `ItemPickedUp(itemId)`).
- Current state reconstructed by replaying events.
- Optional snapshots for performance.

**CQRS (Command Query Responsibility Segregation):**
- **Command side:** Applies changes, emits events.
- **Query side:** Maintains efficient read projections (inventory, room state).

**Example Event Log:**

```json
[
  { "type": "GameStarted", "timestamp": 1000, "playerId": "p1" },
  { "type": "PlayerEnteredRoom", "timestamp": 1001, "roomId": "r1" },
  { "type": "ItemPickedUp", "timestamp": 1002, "itemId": "i1" },
  { "type": "DoorUnlocked", "timestamp": 1003, "doorId": "d1", "withKeyId": "k1" },
  { "type": "PlayerEnteredRoom", "timestamp": 1004, "roomId": "r2" }
]
```

**Strengths:**
- Perfect audit trail; replay any point in history.
- Natural undo/redo support.
- Debugging via log inspection.
- Scales well with complex game logic.

**Weaknesses:**
- More complex than traditional state mutations.
- Event logs can grow large (mitigate with snapshots).

**Use Case:** Rich narrative games with undo, time travel, or extensive debugging needs.

---

### 2.5 Offline-First Architecture (Mobile)

**Pattern:** Local database is primary; cloud is secondary.

**Data Layer:**
- SQLite (Room on Android), Realm, Core Data (iOS), Isar (Flutter).
- All reads/writes to local store first.
- Optimistic UI updates (instant feedback).

**Sync Layer:**
- Mutations queued locally (JSON-serialized commands).
- Background job queues (Android WorkManager, iOS BackgroundTasks) trigger sync on connectivity.
- Conflict resolution: Last-write-wins, versioning, or user-driven.

**Example State Structure:**

```json
{
  "player_progress": {
    "current_node": "scene_42",
    "completed_nodes": ["scene_1", "scene_2"],
    "inventory": ["torch", "key"],
    "stats": {"health": 8, "morale": 5},
    "revision": 1532
  },
  "sync_queue": [
    {
      "id": "mut_a1b2c3",
      "type": "CHOICE_MADE",
      "scene": "scene_41",
      "choice": "take_path_north",
      "timestamp": 1700324582
    }
  ]
}
```

**Benefits:**
- Never waits for server; instant play.
- No data loss; choices always saved locally.
- Seamless recovery when connectivity returns.

**Challenges:**
- Conflict resolution complexity.
- Requires thorough offline/reconnect testing.

**Technologies:**
- Repository pattern: Abstracts local/remote data sources.
- Sync workers: Handle background mutations.

---

### 2.6 JSON-LD Serialization

**What:** Linked Data JSON format for semantic relationships.

**Structure:**
- `@context`: Defines schema (ontology mapping).
- `@type`: Entity type (Location, Item, Character).
- `@id`: Unique identifier.
- Properties with semantic links.

**Example Game World:**

```json
{
  "@context": {
    "name": "http://schema.org/name",
    "Location": "http://example.com/if/Location",
    "connectedTo": {"@id": "http://example.com/if/connectedTo", "@type": "@id"},
    "contains": {"@id": "http://example.com/if/contains", "@type": "@id"}
  },
  "@graph": [
    {
      "@id": "room_library",
      "@type": "Location",
      "name": "Library",
      "connectedTo": "room_hallway",
      "contains": ["item_tome", "npc_librarian"]
    },
    {
      "@id": "item_tome",
      "@type": "Item",
      "name": "Ancient Tome"
    }
  ]
}
```

**Strengths:**
- Interoperable; aligns with Linked Data standards (schema.org).
- Machine-readable; tools can analyze/manipulate worlds.
- Extensible; add external references naturally.

**Use Case:** Serialization, interoperability, tool integration, LLM grounding.

---

## 3. Modern Frameworks & Engines (2015+)

### 3.1 Choice-Based Frameworks

#### Twine
- **Data Model:** Passages (nodes) and links (edges); directed graph.
- **Formats:** Harlowe, SugarCube, Chapbook.
- **State:** Variables (dict-like) + passage-specific logic.
- **Serialization:** HTML with embedded JSON metadata.
- **Best For:** Visual authoring, web deployment, branching narratives.

#### Ink (Inkle)
- **Data Model:** Knots/stitches (nested sections); compiles to JSON.
- **Execution:** JSON runtime (inkjs) with choice management.
- **State:** Built-in variable tracking and save/load.
- **Integration:** Runtime-agnostic; embeds in Unity, web, mobile.
- **Best For:** Rich, complex narratives; professional game studios.

#### ChoiceScript
- **Data Model:** Imperative scene files (`.txt`) with indentation-based commands.
- **Flow:** Sequential scenes with `*goto`, `*goto_scene` branches.
- **State:** Text-based variable definitions (numeric, boolean, string).
- **Execution:** JavaScript interpreter.
- **Best For:** Text-heavy interactive novels; mobile distribution (itch.io).

#### Texture
- **Data Model:** Drag-and-drop "words" onto "blanks" in sentences.
- **Serialization:** JSON specifying sentences, interactive options, and effects.
- **Best For:** Visual, accessible, template-driven narratives.

### 3.2 Parser-Based Engines

**Modern Inform 7 (2015+):**
- OOP-based object model with inheritance.
- Natural language input parsing.
- Built-in containment trees and visibility rules.
- Compiles to Z-machine or Glulx bytecode.
- **Active community** with ongoing language improvements.

**TADS 3:**
- Full-featured Turing-complete language.
- Rich world model with default behaviors.
- Complex state management via classes.

### 3.3 Academic/Experimental Systems

**WorldWeaver (Penn 2024):**
- Procedural world generation using LLMs.
- Generates game code and descriptions.
- Data structures: Graph-based world layouts, state machines.

**Lume (UCSC):**
- Storylet-based procedural narrative.
- Modular scene nodes with preconditions and tags.
- Enables flexible story assembly.

---

## 4. IFComp Winning Games (2020–2024): Patterns

**Parser Winners (Inform 7, TADS):**
- Complex object hierarchies, state machines, event queues.
- Emphasize world simulation and puzzle design.
- Examples: *The Bat*, *Repeat the Ending*, *The Grown-Up Detective Agency*.

**Choice-Based Winners (Twine, Ink):**
- Passage graphs with conditional logic and state flags.
- Emphasize branching narratives and player agency.
- Examples: *And Then You Come to a House*, *The Den*.

**Narrative Trends:**
- Recursion and time loops (*Repeat the Ending*).
- Dual protagonists and parallel play states.
- Resource management and mechanical puzzles.

**Key Insight:** **Winning games blend narrative and mechanics.** Parser games add constraints and resource management; choice-based games add state complexity and branching depth.

---

## 5. Containment in Modern Context

### 5.1 Classic Tree (Still Effective)

```python
class Container:
    def __init__(self):
        self.parent = None
        self.contents = []
    
    def add_item(self, item):
        item.parent = self
        self.contents.append(item)
```

**Strengths:** Simple, efficient, proven.  
**Limitation:** Awkward for multi-parent containment (item in multiple containers simultaneously).

### 5.2 Graph-Based Containment

Uses a graph database or semantic network:

```
Item1 -[CONTAINED_IN]-> Container1
Item1 -[VISIBLE_IN]-> Room1  // For AI visibility
Item1 -[KNOWN_BY]-> Player1  // For narrative state
```

**Strengths:** Flexible; supports multiple relationships.  
**Limitation:** More complex queries.

### 5.3 ECS Approach

```python
class ContainedByComponent:
    def __init__(self, container_id):
        self.container_id = container_id

class ContainerComponent:
    def __init__(self):
        self.contained_items = []

class ContainmentSystem:
    def move_item(self, item_entity, new_container_id):
        item_entity.contained_by.container_id = new_container_id
        # Update any cached visibility, weight, etc.
```

**Strengths:** Composable; easy to add new mechanics (weight limits, restrictions).  
**Ideal for:** Games with rich, evolving mechanics.

### 5.4 Relational (SQLite on Mobile)

```sql
CREATE TABLE items (
    id TEXT PRIMARY KEY,
    name TEXT,
    parent_id TEXT REFERENCES items(id)
);

-- Query: find all items in a container
SELECT * FROM items WHERE parent_id = 'container_1';
```

**Strengths:** Efficient for mobile; ACID guarantees.  
**Limitation:** Lacks semantic richness.

### 5.5 Document-Based (JSON/NoSQL)

```json
{
  "id": "item_1",
  "name": "Torch",
  "containedIn": "room_1",
  "tags": ["light", "flammable"],
  "metadata": {
    "weight": 0.5,
    "visible": true,
    "cursed": false
  }
}
```

**Strengths:** Flexible; easy to add attributes dynamically.  
**Limitation:** Less queryable than relational.

---

## 6. Recommended Modern Architecture for Mobile Text Adventure

### 6.1 Hybrid Approach

**Best for:** Rich, offline-first mobile game with branching narrative and emergent mechanics.

**Components:**

1. **World Model Layer (ECS + Graph):**
   - Entities (rooms, items, NPCs) with components (description, state, location).
   - Graph edges for relationships (spatial, narrative, mechanical).
   - Systems for movement, interaction, state progression.

2. **State Management (Event Sourcing):**
   - Immutable event log (player choices, state changes).
   - Snapshots every N events for performance.
   - Enables undo, rewind, debugging.

3. **Storage Layer (SQLite):**
   - Offline-first: local DB as canonical store.
   - Mutation queue for cloud sync.
   - JSON serialization for portability.

4. **Serialization (JSON + JSON-LD):**
   - JSON-LD for world definitions (interoperable, extensible).
   - Event log as JSON for portability.
   - Optional RDF export for AI reasoning.

### 6.2 Tech Stack (Example: React Native + SQLite)

```
Frontend (UI)
    ↓
Game Engine (ECS + Command Dispatch)
    ↓
Repository (Local/Remote Data Abstraction)
    ↓
Local DB (SQLite + Event Log)
    ↓
Sync Worker (Background Job Queue)
    ↓
Cloud (Optional Backup/Multiplayer)
```

### 6.3 Data Flow Example

```
User Input: "take torch"
    ↓
Command Parser: TakeCommand(entity="torch")
    ↓
Command Validation: Can player access torch?
    ↓
Event Emission: ItemPickedUp(playerId, itemId, timestamp)
    ↓
Event Log: Persist to SQLite
    ↓
ECS Update: Move item to player inventory (update Location component)
    ↓
Sync Queue: Add mutation for cloud sync
    ↓
UI Render: Update inventory display (optimistic)
    ↓
Background Sync: Queue mutation to server when online
```

---

## 7. Comparison Matrix: Modern Approaches

| Approach | Complexity | Mobile-Ready | Scalability | Extensibility | Best Use Case |
|----------|-----------|--------------|-------------|---------------|---------------|
| **ECS** | Medium | ⭐⭐⭐⭐⭐ | Large | ⭐⭐⭐⭐ | Evolving game mechanics |
| **Neo4j (Graph DB)** | High | ⭐⭐ | Very Large | ⭐⭐⭐⭐⭐ | Complex world simulation |
| **Event Sourcing** | High | ⭐⭐⭐⭐ | Medium–Large | ⭐⭐⭐ | Rich narrative + debugging |
| **Offline-First** | Medium | ⭐⭐⭐⭐⭐ | Medium | ⭐⭐⭐ | Mobile + unreliable network |
| **RDF/Ontology** | High | ⭐⭐ | Very Large | ⭐⭐⭐⭐⭐ | AI-driven narratives |
| **Classic Tree** | Low | ⭐⭐⭐⭐⭐ | Small–Medium | ⭐⭐ | Simple worlds |
| **ChoiceScript/Twine** | Low | ⭐⭐⭐⭐ | Small–Medium | ⭐⭐ | Linear branching stories |

---

## 8. Key Findings & Insights

### 8.1 Modern Trends

1. **Graph-Centric:** All modern approaches treat relationships as first-class. Classic hierarchies (tree of containment) are still used but augmented with edges.

2. **Separation of Concerns:** ECS and CQRS decouple data from logic, enabling extensibility.

3. **Offline-First is Standard:** Mobile games assume unreliable networks; local-first architecture is expected.

4. **Event-Driven:** Game state changes as immutable events enables rich history, undo, and debugging.

5. **Semantic Web Integration:** JSON-LD, RDF, and ontologies gain traction for AI integration and tool support.

### 8.2 For Mobile Phone Text Adventure

**Recommended Stack:**

1. **Containment:** Hybrid tree + graph (tree for hierarchy, edges for special relationships).
2. **State:** ECS for composable mechanics; event log for rich history.
3. **Storage:** SQLite offline-first with sync queue.
4. **Serialization:** JSON-LD for world definitions; JSON for state.
5. **Architecture:** MVVM or MVC with repository pattern; separate concerns cleanly.

### 8.3 Avoid (Unless Justified)

- **Neo4j for small games:** Overkill; use SQLite or graph-in-memory.
- **Full RDF/OWL stack:** Unless AI reasoning is core mechanic.
- **Complex event sourcing:** Start simple; add if debugging needs arise.

---

## 9. Academic & Industry References

### Papers
- "Towards modeling structures of the game worlds by systems of graphs" – IEEE (2023)
- "Story2Game: Generating (Almost) Everything in an Interactive Fiction Game" – arXiv (2025)
- "Lume: A System for Procedural Story Generation" – UCSC
- "All Stories Are One Story: Emotional Arc Guided Procedural Game Level Generation" – arXiv (2024)
- "Procedural Generation of Narrative Worlds" – TU Delft
- "WorldWeaver: Procedural World Generation for Text Adventure Games using LLMs" – UPenn (2024)

### Standards & Tools
- **JSON-LD 1.1** – W3C Linked Data standard (https://www.w3.org/TR/json-ld11/)
- **Neo4j Documentation** – https://neo4j.com/docs/
- **RDFlib** (Python) – Semantic web library
- **SPARQL** – Query language for RDF graphs
- **Entity-Component-System Architecture** – Industry standard (Unity, Unreal, Godot)

### Frameworks
- **Twine** (https://twinery.org/)
- **Ink by Inkle** (https://github.com/inkle/ink)
- **ChoiceScript** (https://choicescriptdev.fandom.com/)
- **Inform 7** (http://inform7.com/)

### Datasets & Collections
- **Text Game Research List** – https://www.textgames.org/
- **IFArchive** – https://ifarchive.org/
- **Interactive Fiction Database (IFDB)** – https://ifdb.org/
- **LIGHT Dataset** – Learning in Interactive Games with Humans and Text

---

## 10. Conclusion

The evolution from classic IF engines to modern architectures reflects broader trends in software engineering: **decoupling, graph-centrism, and mobile-first thinking.** No single approach dominates; instead, modular patterns (ECS, event sourcing, offline-first) combine to suit specific needs.

**For a modern mobile text adventure, start with a pragmatic hybrid:**
- ECS for extensibility.
- SQLite + offline-first for mobile resilience.
- Event log for rich narrative support.
- JSON-LD for world definitions (future-proofs for AI integration).

This foundation is simple to implement, scales gracefully, and leaves room for sophisticated AI/semantic integration as complexity grows.

---

**Document Status:** Complete research synthesis  
**Next Steps:** Prototype hybrid architecture; validate with small proof-of-concept.
