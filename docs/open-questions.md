# Open Questions

**Version:** 1.0  
**Last Updated:** 2026-03-21  
**Author:** Brockman (Documentation)  
**Purpose:** Track unresolved design questions and architectural decisions.

---

## Object Model

### Object Instancing

**How should the engine handle multiple instances of the same base object in a single room?** Currently, each object needs its own `.lua` file. Options:

- **(a) Separate .lua files per instance:** Repeat the base object definition for each room-specific instance (e.g., `bedroom-candle.lua`, `kitchen-candle.lua`, `study-candle.lua`)
- **(b) Instance factory pattern:** Build a factory that clones base objects at room load time, assigning unique IDs to each instance while reusing the same base object definition

Wayne is exploring this — not directing yet. The decision will impact how base objects scale across rooms and whether the codebase needs a dedicated instancing system.

---
