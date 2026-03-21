# Principle 8 Draft: The Engine Is a Generic State Machine Executor

**Author:** Bart (Architect)  
**Date:** 2026-03-22  
**Status:** DRAFT — Awaiting Wayne's review before inclusion in core-principles.md  
**References:** Harel statecharts (1987), Entity-Component-System pattern, Dwarf Fortress property-bag architecture  

---

## Proposed Wording

### 8. The Engine Executes Metadata; Objects Declare Behavior

The engine is a **generic state machine executor** with zero knowledge of specific object types. It does not know what a candle is, what burning means, or why a door locks. Its sole job is to read FSM metadata from object tables and execute the declared transitions, mutations, guards, and timers.

**All behavior lives in the object .lua files.** Objects declare:
- **States** with sensory properties (what the object looks like, smells like, feels like in each state)
- **Transitions** with triggers, guards, and messages (how and when state changes occur)
- **Mutations** on transitions (what properties change when a transition fires — weight, keywords, capabilities, any arbitrary property)
- **Timed events** (automatic state changes driven by elapsed time)

**The engine's contract:**
1. Load object metadata as Lua tables
2. Execute FSM transitions when triggered (apply state, apply mutations, fire callbacks)
3. Tick timers and fire auto-transitions when they expire
4. Never contain object-specific logic — no `if obj.id == "candle"` anywhere in engine code

**FSM transitions can mutate ANY property on an object instance.** Through the `mutate` field, transitions declare arbitrary property changes: direct values (`weight = 0.5`), computed values (`weight = function(cur) return cur - 0.05 end`), and list operations (`keywords = { add = "stub", remove = "tall" }`). The engine applies these generically without understanding what the properties mean.

### Why This Principle Exists

This is the Dwarf Fortress lesson: the simulation engine operates on **property bags**, not on named object types. Dwarf Fortress doesn't have special "dwarf code" or "door code" — it has material properties, physical simulation rules, and data-driven definitions. Our engine follows the same pattern: a generic FSM executor operating on metadata-rich object tables.

This principle is the architectural complement to Principle 1 (Code-Derived Mutable Objects) and Principle 3 (Objects Have FSM). Where Principle 1 says objects are mutable tables, and Principle 3 says objects carry FSM blueprints, **Principle 8 says the engine is the generic machine that executes those blueprints without understanding them.**

### Design Consequences

1. **New object types require zero engine changes** — add a .lua file, done
2. **New property types require zero engine changes** — the `mutate` applicator is property-agnostic
3. **Object complexity is bounded by metadata expressiveness**, not by engine code
4. **Testing is data-driven** — verify transitions produce correct state, not that engine "understands" objects
5. **The engine can be reasoned about independently of any specific game content**

### Academic & Industry Lineage

- **Harel Statecharts (1987):** Hierarchical state machines with orthogonal regions — our FSM model is a flat specialization of this
- **Entity-Component-System (ECS):** Components are data bags; systems are generic processors. Our objects are entities with inline component data; the FSM engine is the system.
- **Dwarf Fortress (2006–present):** Property-bag material/object system where the simulation engine has no concept of named object types — it operates on physical properties. This is our direct architectural reference model per Wayne's directive (D-DF-ARCHITECTURE).
