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

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
