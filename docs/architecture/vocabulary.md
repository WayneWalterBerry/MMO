# MMO Text Adventure Engine: Project Vocabulary

**Version:** 1.1  
**Purpose:** A living glossary of terms from interactive fiction, modern game architecture, and code-as-data languages. Use this when discussing design decisions and implementation.

**Last Updated:** 2026-03-19

---

## Table of Contents

1. [Interactive Fiction Architecture](#interactive-fiction-architecture)
2. [Data Structures & Patterns](#data-structures--patterns)
3. [Languages & Runtime Systems](#languages--runtime-systems)
4. [Game Loop & Command Execution](#game-loop--command-execution)
5. [Narrative & World Logic](#narrative--world-logic)
6. [Advanced Concepts](#advanced-concepts)
7. [Engine & Mutation Architecture](#engine--mutation-architecture)
8. [Multiverse & Universe Architecture](#multiverse--universe-architecture)

---

## Interactive Fiction Architecture

### Core Concepts

**Actor**  
A character entity that can hold inventory and move; represents NPCs and the player character. All interactive fiction engines model actors with location awareness and property bags. Relevant to our world model.

**Backdrop**  
An object visible from multiple rooms simultaneously without being physically located in each. Useful for modeling sky, walls, or other omnipresent scenery. Reduces redundancy in our containment tree.

**Container**  
An object that holds other objects "in" it; has capacity constraints and open/locked states. Core to the containment hierarchy that underpins the entire world model.

**Enterable**  
An object type the player can enter (e.g., beds, cages). Part of Inform 7's spatial relationship system; relevant to supporting varied object interactions.

**Fixture**  
An object permanently part of a room; cannot be moved. Used in Inform 7 to model immovable features like fireplaces, windows, or door frames.

**Room**  
A top-level container representing a location; nodes in the world graph where scenes occur. The foundational unit of spatial organization; rooms connect via exits.

**Supporter**  
An object that holds other objects "on" it (like a table holds items on its surface). Distinct from container (in/on relationship). Critical for modeling realistic object placement.

**Thing**  
The base entity type for all game objects in IF engines. In Inform 7, all in-game entities inherit from Thing; establishes common interface.

### Spatial Organization

**Containment**  
Hierarchical parent-child relationship where objects exist "in" or "on" other objects; fundamental to IF modeling. Every object except the world root has exactly one parent location.

**Containment Hierarchy**  
Tree structure where each object has a parent pointer (location) and child list (contents); enables nested object modeling. Proven industry standard (Zork, Inform 7, TADS). Simple, efficient, memory-friendly.

**Containment Tree**  
The data structure implementing containment hierarchy using parent pointers and children lists. All proven IF engines use this; we use it as our primary world representation.

**Exit**  
Directional passage connecting rooms; may have conditional state (locked, requires key). Edges in the room graph; can be one-way or bidirectional.

**Graph Topology**  
Directed graph model for room connections where nodes are rooms and edges are exits/passages. Overlays onto the containment tree; tracks horizontal navigation.

**Inventory**  
Collection of items the player character carries; typically a container property. Special-cased in most IF engines; affects reachability and visibility.

**Location**  
Parent pointer indicating where an object is contained; used in tree traversal. Essential for tracking position in containment hierarchy.

**Reachability**  
Whether an object is accessible to the player (depends on container types and visibility). Constrains which objects can be examined, taken, or interacted with.

**Room Connections**  
Graph edges between rooms; can be bidirectional or one-way. Managed separately from containment tree to support flexible navigation.

**Spatial Containment**  
Inform 7 term for the objects-in/on/part-of relationship system. Provides mental model for hierarchical spatial relationships.

**Visibility Rules**  
Conditional logic determining what objects player can perceive (e.g., can't see into closed opaque containers). Complex rules govern what's accessible.

**World Model**  
Representation and simulation of the game world including rooms, objects, state, and rules. The complete engine responsible for simulating game reality.

### Interactive Fiction Frameworks

**Inform 7**  
Natural-language DSL for interactive fiction; compiles to Z-machine or Glulx bytecode. Industry-leading authoring system; demonstrates homoiconicity through readable syntax.

**Inform 7 Natural Language**  
Human-readable syntax for defining game world ("The Kitchen is a room"; "The player carries a sandwich"). Makes IF accessible to non-programmers.

**Kind**  
Object type or class in Inform 7 (e.g., "A shirt is a kind of clothing"). Classification system; supports inheritance and shared properties.

**Object Definition**  
Creating game entities with properties and behaviors in code. Every game object is formally defined with initial state and methods.

**Object/Entity Model**  
System treating all in-game entities as objects with properties and location. Universal approach across all major IF systems.

**Parser**  
Component that converts natural language user input into structured commands. Bridges human language and machine execution.

**Parser-Based Engine**  
IF engine using natural language parsing (Inform 7, TADS); contrasts with choice-based systems. Requires sophisticated NLP-like processing; more expressive but harder to implement.

**TADS (The Adventure Development System)**  
Mature OOP language and system for interactive fiction with rich standard library. A powerful alternative to Inform 7; emphasizes object-oriented design.

**Z-code / Z-machine**  
Virtual machine and bytecode format for interactive fiction; used by Infocom games and Inform. Bytecode designed for minimal memory footprint on 1980s systems.

**ZIL (Zork Implementation Language)**  
Lisp-based language used to develop Zork; demonstrates homoiconicity in IF. Historical significance; shows code-as-data philosophy in practice.

**Zork/ZIL**  
Property-based system where each object has attributes and implicit location property. Early proof-of-concept for hierarchical object systems.

---

## Data Structures & Patterns

### Core Data Models

**Circular Containment**  
Prevents an object from containing itself directly or indirectly; validation enforces constraint. Runtime check; prevents infinite loops in tree traversal.

**Class-Based OOP**  
Object system using classes as templates; inheritance via subclassing; used by TADS and many modern engines. Contrasts with prototype-based inheritance.

**Contents List**  
Direct children of an object in a containment tree. Queried frequently; often cached or indexed for performance.

**Data Structure**  
Organized format for representing game world information (tree, graph, table, etc.). Choice of data structure affects performance and expressiveness.

**Entity-Component-System (ECS)**  
Architecture where entities are containers for data-only components; systems apply logic. Modern game engine pattern; separates data from behavior. Scales to thousands of entities.

**Graph-Based Containment**  
Uses graph database or semantic network for flexible multi-parent relationships. More flexible than tree; allows items in multiple places simultaneously.

**Graph Database**  
Database optimized for storing and querying relationships (e.g., Neo4j); natural fit for IF world modeling. Efficient path queries; semantic relationship support.

**JSON Format**  
Human-readable data format; used for object definitions and state serialization on mobile. Platform-independent; readable by humans and machines.

**JSON-LD Serialization**  
Linked Data JSON format for semantic relationships; interoperable world definition. Enables AI/tool integration; supports Semantic Web standards.

**Metatables**  
Lua mechanism for prototype-based inheritance; enables delegation and shared behavior. Elegant metaprogramming technique.

**Neo4j**  
Graph database using Cypher query language; models rooms, items, NPCs as nodes with semantic edges. Production-grade; supports complex queries.

**Parent Pointer**  
Reference from object to its container in containment tree. Single pointer per object; O(1) upward traversal.

**Prototype-Based OOP**  
Object system where objects clone prototypes; inheritance via delegation; good for unique per-entity customization. Flexible; enables runtime modification.

**Relational (SQLite)**  
Database using tables and primary keys; efficient for mobile; ACID guarantees. Perfect for offline-first mobile architecture.

**Tables (Lua)**  
Lua's only data structure; serves as both arrays and objects; can hold both data and functions. Elegantly simple; enables code-as-data patterns.

**Tree Traversal**  
Algorithm to find location path of an object by following parent pointers to root. Used for visibility, reachability, and serialization.

### Modern Architectural Patterns

**CQRS (Command Query Responsibility Segregation)**  
Separates command side (apply changes, emit events) from query side (efficient read projections). Enables scaling and testing; complex to implement.

**DAG (Directed Acyclic Graph)**  
Graph structure used in procedural narrative; storylets arranged without cycles. Prevents narrative loops; ensures termination.

**Event Log**  
Immutable record of all state changes; enables replay, undo, and debugging. Central to event sourcing; persisted to storage.

**Event Sourcing**  
Architecture treating all state changes as immutable events; current state rebuilt by replaying events. Enables rich history, debugging, and undo; requires snapshots for performance.

**Offline-First Architecture**  
Mobile pattern where local database is primary; cloud is secondary for sync. Essential for resilience; user never blocked by network.

**RDF/Ontologies**  
Semantic networks representing relationships as subject-predicate-object triples. Formal knowledge representation; enables reasoning.

**Semantic Network**  
Knowledge representation using relationships with meaning. Flexible graph model; enables inference and navigation.

**Snapshot**  
Copy of entire game state at key moments; used for performance optimization in event sourcing. Reduces replay time; stored periodically in event log.

### Serialization & Storage

**JSON Schema**  
Machine-readable description of valid JSON structure. Used for validation and documentation of world definition format.

**Persistence**  
Saving and restoring game state across sessions. Critical for mobile experience; enables "one-day adventure" gameplay.

**Serialization**  
Converting game state to a storable format (JSON, YAML, binary). Required for save/load and cloud sync.

**Sync Queue**  
List of mutations pending cloud synchronization; enables offline-first mobile architecture. Queued locally; synced when network available.

**YAML Format**  
Human-readable data serialization; slightly more compact than JSON. Alternative to JSON for world definitions; less common in production.

---

## Languages & Runtime Systems

### Language Features & Concepts

**Anonymous Function**  
Function without a name; used in Lua and Lisp contexts. Enables functional programming patterns; used for callbacks and higher-order functions.

**API (Application Programming Interface)**  
Set of functions/objects exposed by a library for external code to use. Every engine has a core API; our world model will be exposed via API.

**AST (Abstract Syntax Tree)**  
Tree representation of program structure; each node represents a syntactic construct. Generated by parsers; used by compilers and interpreters.

**Bytecode**  
Intermediate representation between source code and machine code; platform-independent. Used by VMs like Z-machine, Java, Lua; enables portability.

**Build-Time LLM**  
Using a large language model as a build tool — generating content once at build time — rather than as a runtime dependency. Eliminates per-player or per-interaction LLM token costs. In this project, the LLM generates the universe template once; players receive unique worlds through procedural variation, not individual LLM calls. See [D-17] in `docs/design/architecture-decisions.md`.

**C API (Lua C API)**
Clean, low-overhead interface for calling C from Lua or embedding Lua in C. Enables tight integration of Lua scripting in C/C++ engines.

**C Integration**  
Ability to call C functions from scripting language or vice versa; core to Lua embedding. Performance-critical code written in C; glued by Lua.

**Closure**  
Function bundled with the environment (variables) it captures at creation time. Enables encapsulation and stateful callbacks.

**Code as Data**  
Fundamental property of homoiconic languages; programs manipulate code like data structures. Enables macros, metaprogramming, and DSL creation.

**Code Generation**  
Process of generating code from high-level specifications or templates. Used in DSL compilers; reduces boilerplate.

**Compiler**  
Tool converting source code to machine code or bytecode. Compilers provide safety checks; interpreters offer flexibility.

**Compiled**  
Code converted to machine/bytecode before execution. Provides performance; requires compilation step.

**Control Flow**  
Order in which program statements execute; affected by conditionals, loops, function calls. Essential for understanding program behavior.

**Declarative Programming**  
Style specifying *what* should happen, not *how* (vs. imperative). Easier to reason about; harder to optimize.

**Declarative Rules System**  
Rule-based approach to expressing world logic; used in Inform 7. Natural for expressing IF rules; enables inference engines.

**Decorators**  
Python feature allowing function/class modification; enables DSL patterns. Syntactic sugar for higher-order functions.

**Delegation**  
Prototype-based inheritance mechanism where methods are looked up through the prototype chain. Alternative to class hierarchy.

**Domain-Specific Language (DSL)**  
Programming language tailored to a narrow problem domain (e.g., SQL for databases). Reduces complexity; less general but more expressive for specific domain.

**Dynamic Typing**  
Type checking performed at runtime (vs. static typing at compile-time). Flexible; allows late binding and runtime specialization.

**EDSL (Embedded DSL)**  
DSL built as extension within a general-purpose language (vs. external DSL with separate parser). Easier to implement; shares host language semantics.

**Embedding**  
Integrating a scripting language into a larger application or game engine. Standard practice for extending engines; Lua is industry standard.

**Eval**  
Function parsing and executing a string as code at runtime. Powerful but dangerous; allows dynamic behavior.

**FFI (Foreign Function Interface)**  
Mechanism allowing a language to call functions in other languages (typically C). Enables code reuse and performance optimization.

**First-Class Function**  
Functions treated as values; can be passed as arguments, returned, stored in variables. Enables functional programming; essential for callbacks.

**Functional Programming**  
Paradigm emphasizing immutability, pure functions, and function composition. Contrasts with imperative style; enables easier reasoning and testing.

**Garbage Collection (GC)**  
Automatic memory management; runtime reclaims unused memory. Simplifies development; may introduce pauses.

**Homoiconicity / Code-as-Data**  
Property where language's code and data share identical data structures. Lisp, Rebol, Tcl; enables powerful metaprogramming.

**Interpreter**  
Runtime system directly executing code (often from bytecode) without prior compilation to machine code. Flexible; slower than compiled code.

**Introspection**  
Ability of a program to inspect its own structure and behavior at runtime. Enables metaprogramming and dynamic adaptation.

**Lambda (λ)**  
Anonymous function; used in lambda calculus and functional programming. Common in functional languages; enables concise function definitions.

**Lazy Evaluation**  
Delaying computation until its result is actually needed. Enables infinite data structures; default in functional languages.

**Lexer / Tokenizer**  
Component splitting source code into tokens (atomic units like keywords, identifiers). First stage of parsing.

**loadstring()**  
Lua function (also spelled `load()` in Lua 5.2+) that parses a string as Lua code and returns it as an executable function. The primary mechanism by which the engine rewrites world object definitions at runtime. Enables true code mutation: the engine generates a new object definition as a string and loads it into the running environment. See [D-14], [D-16] in `docs/design/architecture-decisions.md`.

**Lexical Scope / Lexical Binding**
Variable scope determined by program text structure (vs. dynamic scope). Standard in modern languages; enables closures.

**Live Reloading**  
Updating code/data at runtime without restarting application. Essential for MUD development; used in game editors.

**Macro**  
Program construct generating code; often extends language syntax; powerful in Lisp. Enables syntactic abstraction; meta-level programming.

**Meta-Code**  
The Lua code that defines world objects and their behavior. Meta-code is simultaneously code and data — a Lua table holding properties, functions, and mutation logic for a game entity. When the engine rewrites a broken mirror into `broken_mirror`, it is rewriting meta-code. The engine and its meta-code are the same language (Lua), with no boundary between them. See [D-15], [D-16] in `docs/design/architecture-decisions.md`.

**Metaprogramming**
Code that manipulates, generates, or inspects other code. Enables DSLs, frameworks, and runtime customization.

**Meta-Code Rewrite** (also: **True Code Rewrite**)  
The mutation model where the engine replaces an object's definition entirely rather than toggling flags on the existing definition. When a player breaks a mirror, the engine does not set `mirror.is_broken = true`; it rewrites the object into a new entity (`broken_mirror`) with different properties, descriptions, and available verbs. The original definition is gone. This is the project's core design mechanic. See [D-14] in `docs/design/architecture-decisions.md`.

**Metaclass**
Class whose instances are classes; enables metaprogramming. Used in Python; rarely needed in dynamic languages.

**Monomorphization**  
Process of specializing generic code for specific types at compile-time. Performance optimization; used in C++ templates and Rust.

**Namespace**  
Named scope limiting identifier visibility; avoids naming conflicts. Essential for large codebases.

**Opcode**  
Individual operation in bytecode (e.g., ADD, LOAD_VAR). Building blocks of bytecode; interpreted by VM.

**Operator Overloading**  
Allowing standard operators (+, -, etc.) to work with custom types. Common in OOP languages; enables natural syntax.

**Parser**  
Component converting source code text into an AST. Critical compilation stage.

**PEG (Parsing Expression Grammar)**  
Grammar formalism for parsing; alternative to context-free grammars. Simpler to reason about; used in some game scripting languages.

**Reflection**  
Ability to inspect and modify program structure at runtime. Superset of introspection; enables dynamic adaptation.

**REPL (Read-Eval-Print Loop)**  
Interactive environment where expressions are evaluated and results printed. Essential for exploratory development and debugging.

**Runtime Dispatch**  
Choosing which function to call based on runtime type information (vs. compile-time dispatch). Enables polymorphism.

**S-Expression (Symbolic Expression)**  
In Lisp, nested lists representing code/data; e.g., (+ 2 3). Uniform syntax; enables code-as-data.

**Specialization**  
Optimization creating specialized versions of code for specific types/values. Common JIT technique; speeds up hot paths.

**Strict Evaluation**  
Eagerly evaluating function arguments before calling function (vs. lazy evaluation). Default in imperative languages.

**Syntax Macros / Syntax Quotation**  
Lisp mechanism (backtick, comma) for generating code structures. Powerful template system; enables DSL extension.

**Type Checking**  
Validation ensuring operations use compatible types. Compile-time or runtime; catches errors early.

**Type Safety**  
Preventing type-related errors through compile-time or runtime checks. Static typing catches errors earlier; dynamic typing more flexible.

**Unification**  
In logic programming, process of finding substitutions making logical terms identical. Used in Prolog; enables backward chaining.

**Virtual Machine (VM)**  
Abstract computer executing bytecode or intermediate representations. Enables portability; adds one layer of indirection.

**Wrapper**  
Function or object encapsulating another; often adds functionality or modifies behavior. Design pattern; enables composition.

### Compilation & Performance

**AOT (Ahead-of-Time) Compilation**  
Compiling code to machine code before execution (vs. JIT). Provides early error detection; slower development cycle.

**Guard (in JIT)**  
Runtime check ensuring a trace's assumptions hold; if not, code exits to interpreter. Enables speculative optimization; fallback to interpreter.

**Hot Code / Hot Path**  
Frequently executed code section; JIT prioritizes compilation of hot paths. JIT focuses effort where it matters most.

**JIT (Just-In-Time) Compilation**  
Compilation strategy compiling code to machine code during execution. Performance of compiled code; flexibility of interpretation.

**Optimization Pass**  
Phase in compiler/JIT improving code efficiency (e.g., dead code elimination, inlining). Improves final code quality.

**Trace (in JIT)**  
Linear sequence of operations extracted from code path; candidate for compilation. Used by tracing JIT; often loop-centric.

**Tracing JIT**  
JIT strategy recording traces of hot code paths and compiling them; used by LuaJIT. Effective for loop-heavy code; lower compilation overhead.

### Programming Languages

**AngelScript**  
Full-featured scripting language for games; more complex than Lua. More features; larger footprint.

**Clojure**  
JVM-based Lisp dialect; strong immutability; access to Java ecosystem. Excellent for data transformation; access to vast Java libraries.

**Fennel**  
Lisp dialect compiling to Lua; runs on any Lua platform; small and fast. Lisp syntax on Lua runtime; homoiconic.

**Forth**  
Stack-based language using words (code/data interchangeably); self-modifying; used in historic games like Starflight. Self-referential language; steep learning curve.

**GraalVM**  
Polyglot VM supporting multiple languages with shared JIT compilation via Truffle. Run multiple languages on same VM; shared optimizations.

**Janet**  
Custom bytecode VM; small, embeddable (~400 KB); Lisp-like language for scripting. Lightweight; homoiconic.

**JavaScript/TypeScript**  
V8 JIT provides excellent performance; web-native; large ecosystem. Universal language; runs in browser; massive library ecosystem.

**Lisp Dialects**  
Languages including Fennel, Racket, Clojure, Janet; maximum homoiconicity and metaprogramming. Code-as-data philosophy; powerful macros.

**LPC (Lars Pensjö C)**  
Object-oriented scripting language designed for MUD engines; code-as-data philosophy. MUD-specific; designed for multiplayer persistence.

**Lua**  
Lightweight, embeddable scripting language; industry standard for game development. ~27 KB runtime; perfect for embedding; clean syntax.

**LuaJIT**  
Optional JIT compilation for Lua providing 5–10x speedup; memory footprint ~100–200 KB. Fast scripting; minimal overhead.

**Python**  
Slow runtime; requires PyPy JIT for speed; large community; easy to learn. Batteries included; slower than Lua; requires PyPy for performance.

**Prolog**  
Logic-based language using backward-chaining inference and Horn clauses. Declarative; constraint solving; used in AI.

**PyPy**  
JIT-compiled Python runtime; slower than LuaJIT but faster than CPython. Speeds up Python significantly; not universally compatible.

**Racket**  
General-purpose language creation toolkit; powerful metaprogramming; heavy runtime. Language-building language; rich ecosystem; slower than Lua.

**Rebol/Red**  
High-level, human-readable, homoiconic; designed for scripting. Accessible syntax; homoiconic; small community.

**Squirrel**  
Similar to Lua; more C++-like syntax; smaller community. Lua alternative; less widely used.

**Tcl**  
String-based, extremely permissive evaluation; homoiconic. Everything-is-a-string model; flexible; niche.

**Truffle**  
Framework for building language interpreters that integrate with GraalVM JIT. Enables polyglot compilation.

**Wren**  
Similar to Lua; designed for game scripting; class-based; less mature. Lua alternative; under active development.

---

## Game Loop & Command Execution

### Command Processing Pipeline

**Ambiguity Resolution**  
When multiple objects match, ask player for clarification. User experience; prevents wrong action on wrong object.

**Action Dispatch**  
Routing parsed commands to handler functions based on verb. Maps verbs to behaviors; may be global or per-object.

**Command Dispatch**  
Selecting appropriate handler for a player command. Core of game loop; directs input to behavior.

**Command Parsing**  
Converting natural language input into structured representation. Bridge between human language and execution.

**Command Pattern**  
Design pattern where each command is reversible (execute/undo pair). Enables undo/redo; separates concerns.

**Container Context**  
Searching for objects within specific containers (e.g., "take key in box"). Resolves ambiguous object references; contextual search.

**Dictionary/Map Lookup**  
Most common verb dispatch mechanism. Simple hash table; fast O(1) lookup.

**Filter Fillers**  
Removing non-meaningful words from parsed input. Noise removal; improves parsing accuracy.

**Grammar Rules**  
Pattern matching for command structures (e.g., "[VERB] [OBJECT] [PREP] [OBJECT2]"). Formal specification of command syntax.

**Lemmatization**  
Converting verb tenses and word forms to canonical form. Normalizes input; "takes" → "take".

**Object Method Dispatch**  
Each object has methods for relevant verbs; called instead of global handler. Object-oriented approach; enables custom behavior per object.

**Object Resolution**  
Finding game objects referenced in player input. Converts noun phrases to entity references.

**Parser Pipeline**  
Sequential steps converting input to executable command. Architecture of parsing subsystem.

**POS Tagging**  
Part-of-speech tagging identifying nouns vs. verbs. NLP technique; aids parsing.

**Pronoun Handling**  
Resolving "it", "him", "that" to previously mentioned objects. Context-dependent interpretation.

**Rich Synonym Mapping**  
Parser approach using extensive alias tables to make structured commands feel natural. Instead of simple verb-noun dispatch, a broad synonym dictionary maps player input variations ("grab", "snatch", "take", "get") to canonical verbs. Our chosen approach for making structured commands feel like natural language without runtime LLM cost. See [D-19] in `docs/design/architecture-decisions.md`.

**Tokenization**
Splitting input text into individual tokens (words). First parsing step.

**Verb Handler**  
Function implementing behavior for a specific verb. Called by command dispatch.

**Verb Resolution**  
Mapping user input verbs to handler functions; handles synonyms. Normalizes verb input; supports synonyms.

### State Management

**Flags/Counters**  
Boolean or numeric state tracking game progression (e.g., has_visited_library, items_collected). Simple flags; easy to query.

**Global Variables**  
State tracking overall game progression and story flags. Quick to access; can become messy.

**Memento Pattern**  
Design storing snapshots of entire game state at key moments. Enables undo; uses memory.

**Object Properties**  
State like is_door_locked, is_light_on. Per-object state; fine-grained control.

**Redo Stack**  
Commands available to reexecute after undo. Tracks forward history; limited depth often imposed.

**Redo/Redo Support**  
Allowing player to reverse undo operations. User experience; common in modern games.

**Save/Load Architecture**  
System for serializing and restoring game state. Persistence; requires serialization format.

**State Machine**  
Model where entity transitions between discrete states based on events. Formal model of behavior; enables verification.

**State Mutation**  
Modifying game state as result of player action. Core game mechanic; all actions mutate state.

**Undo Stack**  
Historical commands for reverting to previous states. Enables state restoration; limited depth often imposed.

**Undo/Redo Support**  
Allowing player to reverse and reapply actions. User experience feature; complex to implement correctly.

---

## Narrative & World Logic

### Narrative Structures

**Branching Narrative**  
Story with multiple paths influenced by player choices. Multiple endings; player agency.

**Choice-Based Framework**  
Narrative engine where player selects from presented choices (Twine, Ink, ChoiceScript). Simpler than parser-based; explicit choice presentation.

**Dialogue**  
Conversation system with conditionals and branching. NPC interaction; narrative branch point.

**Dynamic Story Generation**  
Procedurally generating narratives during gameplay. Infinite variety; requires careful design to maintain coherence.

**Passage-Based**  
Twine architecture where each scene/choice point is a passage node. Graph-based narrative; node-and-edge model.

**Procedural Generation**  
Algorithmic generation of game content (worlds, scenarios, rules). Creates variety; hard to ensure quality.

**Procedural Variation**  
The system that creates unique multiverse instances for each player by applying deterministic seeds and parameter ranges to a shared universe template. Distinct from full procedural generation in that it starts from a hand-tuned canonical template rather than generating from scratch. Ensures uniqueness without per-player LLM cost. See [D-17] in `docs/design/architecture-decisions.md`.

### World Simulation

**Behavior Tree**  
Hierarchical tree-based formalism for encoding behavior; used in game AI. Cleaner than state machines; supports composition.

**Conditional Exits**  
Room exits that may be locked/require keys; dynamically available. Enables puzzle mechanics; conditional navigation.

**Conditional State**  
Exit availability based on game state conditions. Dynamic world; changes during gameplay.

**Drama Management**  
Dynamically adjusting narrative to maintain tension and pacing. Narrative AI; maintains engagement.

**Dynamic Exits**  
Exits added/removed during game (e.g., cave-in blocks a passage). Dynamic topology; world changes.

**Event Handler**  
Function triggered when specific event occurs. Callback mechanism; enables reactive programming.

**Inference Engine**  
Component of rule-based system applying rules to derive new facts. Forward chaining; derives consequences.

**Narrative Emergence**  
Objects spawning other objects, creating chains of emergent events. Complex behavior from simple rules.

**NPC (Non-Player Character)**  
Character controlled by AI, not by player. Populates world; adds interactivity.

**Procedural Narrative**  
Narrative generated algorithmically from rules and constraints. Scales narrative; requires careful design.

**Universe Template**  
The canonical world definition generated by LLM at build time, before any hand-tuning or per-player variation. The template is the starting point for all player universes; it is improved by human authors and then used as the seed for procedural variation at player start. See [D-17] in `docs/design/architecture-decisions.md`.

**Production Rule**
Rule in production system (forward-chaining); IF-THEN form. Declarative rule format.

**Rule Engine**  
System executing production rules; used in forward-chaining inference. Implements rule-based logic.

**Storylet**  
Modular narrative node with preconditions and tags; used in procedural systems like Lume. Reusable narrative unit; tagged for dynamic selection.

### Narrative Systems

**Chapbook**  
Story format for Twine. Minimalist Twine format.

**ChoiceScript**  
Scene-based choice-driven IF engine; stat-tracking for gamebooks. Professional-grade choice-based system; used commercially.

**Harlowe**  
Story format for Twine; supports variables and scripting. Popular Twine format; enables dynamic content.

**Ink by Inkle**  
Knot/stitch-based narrative language; compiles to JSON; used professionally. Industry-standard narrative language; professional tool chain.

**Jiuzhou Engine**  
Modern ECS-based engine using GenAI narrative generation. Research system; explores AI-driven narrative.

**Lume**  
UCSC system using storylets for procedural narrative; modular narrative nodes with preconditions. Academic research; modular narrative architecture.

**SugarCube**  
Story format for Twine; supports variables and scripting. Popular Twine format; mature ecosystem.

**Texture**  
Drag-and-drop word-placement IF; JSON serialization. Experimental IF authoring; visual paradigm.

**Twine**  
Passage-based IF framework; visual authoring; targets web. Most popular IF authoring tool; web-based; active community.

**Twinery**  
Web-based IDE for Twine development. Browser-based Twine development.

**WorldWeaver**  
UPenn system for procedural world generation using LLMs. Research system; explores LLM-driven world generation.

---

## Advanced Concepts

### Logic & Inference

**Backward Chaining**  
Inference strategy starting from goal, working backward to find facts; used in Prolog. Goal-driven; used in theorem proving.

**Forward Chaining**  
Inference strategy starting from known facts, applying rules to derive new facts. Data-driven; used in production systems.

**Horn Clause**  
Logical formula "conclusion :- condition1, condition2, ..."; used in Prolog. Declarative rule format; enables inference.

**Query**  
Question/goal posed to logic system (e.g., Prolog "?- father(john, X);"). Query interface to knowledge base.

**RDF (Resource Description Framework)**  
Format representing semantic relationships as triples (subject-predicate-object). W3C standard; enables linked data.

### Functional Concepts

**Church Encoding**  
Representing data structures (booleans, numbers) as pure lambda functions. Lambda calculus foundation; theoretical construct.

**Continuation**  
Function representing "rest of computation" after a point; enables advanced control flow. Powerful control abstraction; enables coroutines, backtracking.

**Fungible**  
Interchangeable; items with no unique identity (vs. non-fungible unique items). Inventory modeling; stack fungible items, track unique items separately.

**Immutability**  
Data that cannot be modified after creation; enables safe concurrency. Simplifies reasoning; enables safe sharing.

**Memoization**  
Caching function results to avoid recomputation. Performance optimization; trades memory for speed.

**Monad**  
Functional programming abstraction for composing operations with side effects. Encapsulates stateful computation; enables monadic composition.

**Persistent Data Structure**  
Structure preserving old versions after modifications; enables efficient undo/versioning. Copy-on-write; enables history without memory overhead.

**Tail Call**  
Function call as last operation; optimizable into jump (tail call optimization). Enables recursive functions without stack overflow; critical in functional languages.

### Multiplayer Systems

**DGD (Dworkin's Game Driver)**  
Specialized system for multiplayer text worlds using LPC. Industry standard for LPC-based MUDs; proven architecture.

**Fog of War (Ghost Context)**  
Ghost visibility model where inter-universe observers only see the current room or immediate area, not the whole host universe. Chosen for efficiency: only current room state needs to be streamed to the ghost player. Also limits scouting and reduces information overload. See [D-20] in `docs/design/architecture-decisions.md`.

**Hot-Reloadable**
Code and data updated while world runs; used in DGD/LPC MUD systems. No server restart; live code updates.

**LPC & DGD**  
Specialized system for multiplayer text worlds; objects as fundamental unit. MUD standard; 30-year track record.

**MUD (Multi-User Dungeon)**  
Multiplayer text-based game environment; precursor to MMORPGs. Historic significance; technical proof-of-concept for persistent worlds.

**No-Merge Model**  
The design decision that universe interaction does not blend or merge universe states. When a ghost becomes a full participant in a host's universe, they simply join as-is; their home universe pauses separately. Eliminates the need for CRDTs, OT, or conflict resolution. The host universe is canonical. See [D-21] in `docs/design/architecture-decisions.md`.

**Procedurally Driven Drama Management (DODM)**
Using complex state representations to model story futures and enable proactive narrative management. Advanced narrative AI; enables foresight.

**Universe Pause**  
When a ghost player joins another universe as a full participant, their home universe freezes in place. The paused universe is not destroyed or merged — it is suspended and resumable when the player returns. Persisted in cloud storage. See [D-21] in `docs/design/architecture-decisions.md`.

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-03-18 | Initial vocabulary extracted from three research reports. Organized by category; 200+ terms. |
| 1.1 | 2026-03-19 | Added 11 terms from architecture decisions session (D-14 through D-21). Added two new sections: Engine & Mutation Architecture, Multiverse & Universe Architecture. |

---

## Contributing

This is a **living document**. As the project evolves:

1. **New terms:** Add to appropriate category, alphabetically sorted
2. **Clarifications:** Update definitions when implementation reveals nuance
3. **Deprecations:** Move obsolete terms to an "Archive" section; note when/why deprecated
4. **Cross-references:** Link related terms where one builds on another

**Update process:**
- Make changes locally; document rationale
- Include term in commit message: "docs: add vocabulary term X"
- Maintain alphabetical order within categories
- Keep definitions concise (1-3 sentences max)

---

## See Also

- **Classic IF Architecture:** `resources/research/architecture/text-adventure-architecture.md`
- **Modern Data Structures:** `resources/research/architecture/modern-text-adventure-data-structures.md`
- **Code-Data Languages:** `resources/research/architecture/code-data-blended-languages.md`
- **Architecture Decisions:** `.squad/decisions.md`
- **Architecture Decisions (detailed):** `docs/design/architecture-decisions.md`

---

## Engine & Mutation Architecture

Terms specific to this project's self-modifying engine design. See `docs/design/architecture-decisions.md` for the full decisions behind these concepts.

**loadstring()** → see [Languages & Runtime Systems > Language Features & Concepts](#language-features--concepts)

**Meta-Code** → see [Languages & Runtime Systems > Language Features & Concepts](#language-features--concepts)

**Meta-Code Rewrite / True Code Rewrite** → see [Languages & Runtime Systems > Language Features & Concepts](#language-features--concepts)

**Build-Time LLM** → see [Languages & Runtime Systems > Language Features & Concepts](#language-features--concepts)

**The Company**  
In-game meta-entity and analytics pipeline that observes how player worlds evolve over time. Enabled by cloud persistence: "The Company" reads universe snapshots to track mutations, divergence from the template, and emergent player behaviors. The Company is both a narrative element (in-world observer) and a technical pipeline (out-of-world analytics). See [D-18] in `docs/design/architecture-decisions.md`.

---

## Multiverse & Universe Architecture

Terms specific to this project's multiverse and inter-universe interaction model. See `docs/design/architecture-decisions.md` for the full decisions behind these concepts.

**Fog of War (Ghost Context)** → see [Advanced Concepts > Multiplayer Systems](#multiplayer-systems)

**No-Merge Model** → see [Advanced Concepts > Multiplayer Systems](#multiplayer-systems)

**Universe Pause** → see [Advanced Concepts > Multiplayer Systems](#multiplayer-systems)

**Procedural Variation** → see [Narrative & World Logic > Narrative Structures](#narrative-structures)

**Universe Template** → see [Narrative & World Logic > Narrative Structures](#narrative-structures)

**Rich Synonym Mapping** → see [Game Loop & Command Execution > Command Processing Pipeline](#command-processing-pipeline)
