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

---

**User Directive (2026-03-18T222300Z):** Skip mobile-specific material for now; focus on data structures only.

