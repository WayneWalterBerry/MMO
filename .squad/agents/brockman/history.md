# Project Context

- **Owner:** Wayne "Effe" Berry
- **Project:** MMO
- **Created:** 2026-03-18

## Core Context

Agent Brockman initialized as Documentation specialist for the MMO project.

## Recent Updates

📌 Team initialized on 2026-03-18

## Learnings

### Documentation-First Mindset
- Team emphasizes documentation as a product feature, not an afterthought
- Decisions are recorded centrally in `.squad/decisions.md` for team consensus
- Architecture decisions and governance get formal treatment

### MMO Project Team
The project has six core roles:
- **Wayne "Effe" Berry** (Human, Visionary)
- **Squad** (Coordinator, route/orchestrate work)
- **Frink** (Research & Analysis)
- **Chalmers** (Project Management)
- **Scribe** (Session logging)
- **Ralph** (Work monitoring)

### Team Governance
- Folder naming convention: lowercase with dashes (e.g., `my-folder`)
- All meaningful changes require team consensus
- Logs are kept in `.squad/log/` and `.squad/orchestration-log/`

### Initial Setup (2026-03-18)
- Team is freshly assembled, no prior log entries
- Created inaugural newspaper at `newspaper/2026-03-18.md`
- Newspaper is the daily communication hub for team updates

### README Creation (2026-03-18T222400Z)
- Created root README.md explaining project vision and folder structure
- Key file locations documented:
  - `C:\src\MMO\README.md` — Primary entry point for new readers
  - `C:\src\MMO\newspaper/` — Daily team gazette (one file per day, YYYY-MM-DD.md format)
  - `C:\src\MMO\resources/research/architecture/` — Background research and reference materials
  - `C:\src\MMO\docs/architecture/` — Design decisions and technical specs
  - `C:\src\MMO\.squad/decisions.md` — Team governance and architectural decisions
- Convention: All folder names use lowercase with dashes (no spaces or underscores)
- README emphasizes MMO's core concept (containment hierarchies) and research-phase status
- Design: Welcoming tone, clear navigation, respect for team governance structure

### Project Vocabulary Extraction (2026-03-18T235900Z)
- **Task:** Create `docs/architecture/vocabulary.md` — unified glossary for team architecture discussions
- **Source Material:** Extracted terms from three research reports:
  1. `resources/research/architecture/text-adventure-architecture.md` — Classic IF (Zork, Inform, TADS)
  2. `resources/research/architecture/modern-text-adventure-data-structures.md` — Modern approaches (ECS, event sourcing, graphs)
  3. `resources/research/architecture/code-data-blended-languages.md` — Code-as-data, DSLs, homoiconicity (includes glossary)
- **Extracted Terms:** 200+ terms covering:
  - IF Architecture: Actor, Room, Container, Inventory, Parser, Containment Hierarchy, World Model
  - Data Structures: ECS, Event Sourcing, Graph Database, Containment Tree, Neo4j, SQLite, JSON-LD
  - Languages & Runtime: Homoiconicity, DSL, Lua, LuaJIT, Lisp, Prolog, JIT/AOT compilation, REPL
  - Game Loop: Command Parsing, Command Dispatch, Verb Resolution, State Management, Undo/Redo
  - Narrative: Storylet, Drama Management, Branching Narrative, Rule Engine, NPC
  - Advanced: Event Sourcing, CQRS, Backward/Forward Chaining, Immutability, Persistent Data Structures
- **Format & Organization:**
  - Organized into 6 categories: IF Architecture (with 3 subsections), Data Structures, Languages & Runtime (with 5 subsections), Game Loop, Narrative & World Logic, Advanced Concepts
  - Alphabetically sorted within each category for easy reference
  - Each term includes: definition (1-3 sentences), context for MMO project
  - Living document design with contribution guidelines
  - Cross-references to source research files and decisions
- **Key Features:**
  - Respects team terminology preferences (containment hierarchy, world model, etc.)
  - Bridges classical IF (Zork, Inform 7, TADS) with modern patterns (ECS, event sourcing)
  - Includes lesser-known terms (Storylet, DODM, Hot-Reloadable) alongside fundamentals
  - Document includes version tracking and contribution process
- **Output File:** `C:\src\MMO\docs\architecture\vocabulary.md` (200+ entries, 200+ KB)

### Architecture Decisions Document (2026-03-19)
- **Task:** Document eight architecture decisions (D-14 through D-21) from Wayne's 2026-03-19 session
- **Output Files:**
  - `C:\src\MMO\docs\design\architecture-decisions.md` — comprehensive decisions document
  - `C:\src\MMO\docs\architecture\vocabulary.md` — updated with 11 new terms (v1.1)
- **Decisions captured:**
  - D-14: Mutation Model: True Code Rewrite (engine replaces object definitions, not flag-flips)
  - D-15: Meta-Code Format: Deferred (likely Lua tables/closures)
  - D-16: Engine Language: Lua (for both engine and meta-code; `loadstring()` enables self-modification)
  - D-17: Universe Templates: LLM build-time + hand-tuning + procedural variation (no per-player LLM cost)
  - D-18: Persistence: Cloud Storage (supports session resumption and "The Company" analytics)
  - D-19: Parser: NLP or Rich Synonyms (not simple verb-noun; local LLM is stretch goal)
  - D-20: Ghost Visibility: Fog of War (current room only; efficient streaming)
  - D-21: Universe Merge: No Merge (ghost joins host universe as-is; home universe pauses)
- **New vocabulary terms added (11):**
  - Build-Time LLM, Fog of War (Ghost Context), loadstring(), Meta-Code, Meta-Code Rewrite / True Code Rewrite
  - No-Merge Model, Procedural Variation, Rich Synonym Mapping, The Company, Universe Pause, Universe Template
- **New vocabulary sections added (2):**
  - Engine & Mutation Architecture (index/cross-reference section)
  - Multiverse & Universe Architecture (index/cross-reference section)
- **Document structure for architecture-decisions.md:**
  - Summary table at top (all 8 decisions with status and impact area)
  - Per-decision sections: Context, Decision, Rationale, Implications, Connections to prior decisions
  - Deferred/Open items table
  - Decision dependency map (visual ASCII)
  - Relationship to prior decisions table
  - Cross-references
- **Key architectural insight documented:** D-16 (Lua) is the foundation; D-14 (True Code Rewrite) is the defining mechanic; D-20 + D-21 together define the complete inter-universe interaction model
- **Prior decisions affected:**
  - D-3 (simple tokenizer) superseded by D-19
  - D-5 (local SQLite) superseded by D-18
  - D-7 (merge roadmap) superseded by D-21
  - D-6 (Lua recommendation) confirmed and elevated by D-16

### Session Update: Architecture Decisions Session (2026-03-18)
- **Task:** Document 8 architecture decisions from Wayne's session (D-14 through D-21)
- **Status:** ✅ COMPLETE
- **Deliverables:**
  - `docs/design/architecture-decisions.md` — Comprehensive decisions document with summary table, per-decision analysis, dependency maps
  - `docs/architecture/vocabulary.md` v1.1 — Added 11 new terms (Build-Time LLM, Fog of War, loadstring(), Meta-Code, etc.) and 2 navigation sections
- **Key Decisions Documented:**
  - D-14: Mutation Model (True Code Rewrite)
  - D-15: Meta-Code Format (Deferred — Lua tables/closures)
  - D-16: Engine Language (Lua)
  - D-17: Universe Templates (Build-time LLM + procedural variation)
  - D-18: Persistence (Cloud Storage)
  - D-19: Parser (NLP or Rich Synonyms)
  - D-20: Ghost Visibility (Fog of War)
  - D-21: Universe Merge (No Merge)
- **Orchestration Log:** `.squad/orchestration-log/2026-03-18T23-22-00Z-brockman.md`
- **Session Log:** `.squad/log/2026-03-18T23-22-00Z-architecture-decisions.md`

### Vocabulary Refinement Session (2026-03-20)
- **Task:** Review and refine vocabulary document (docs/architecture/vocabulary.md) against all 24 architecture decisions
- **Status:** ✅ COMPLETE
- **Approach:**
  1. Cross-referenced vocabulary against .squad/decisions.md (all 24 decisions D-1 through D-24)
  2. Identified and updated conflicting or outdated terms
  3. Added missing terminology for new game systems
  4. Updated version to 1.2; bumped last-modified date
- **Key Findings & Updates:**
  - **ECS term superseded:** Decision 3 recommended hybrid ECS, but team chose containment hierarchy (D-3) + Lua prototype-based inheritance. Updated term to clarify; preserved ECS as reference material.
  - **State Flags superseded:** Decision 22 (Code Mutation Over State Flags) makes flags inappropriate. Updated Flags/Counters term with ⚠️ note; emphasized code mutation IS the state.
  - **Persistence model changed:** Decision 18 (Cloud Storage) supersedes earlier Decision 5 (local SQLite). Updated Relational/SQLite, Offline-First Architecture, Sync Queue terms.
  - **Language choice clarified:** Decision 16 (Engine Language: Lua) is foundational; removed any speculative references to TypeScript/Kotlin/Swift.
- **New Terms Added (10):**
  1. **Mutation Variant** — Pattern of multi-state object files (vanity.lua, vanity-open.lua, etc.)
  2. **Room Presence** — Field for dynamic room description composition
  3. **Surface** — Multi-zone containment within objects (top, inside, underneath)
  4. **Registry** — Live in-memory object store (ID → object table)
  5. **Sandbox Loader** — Lua execution environment for object definitions
  6. **Light Source** — Objects with casts_light = true property
  7. **Game Clock** — Accelerated time system (1 real hour = 1 game day)
  8. **Ghost** — Inter-universe observer player with limited interaction
  9. **Universe Fork** — Per-player universe creation from base template
  10. **Template** — Base definition pattern for object classes (with inheritance explanation)
- **Updated Cross-References (4):**
  - Container: Added Surface reference
  - Supporter: Added Surface reference
  - Updated 15+ terms with explicit Decision cross-references ([D-XX])
- **Coverage Analysis:**
  - All 24 decisions now covered in vocabulary or cross-referenced
  - Speculative/superseded content marked with ⚠️ warnings
  - Architecture research terms (ECS, Event Sourcing, etc.) preserved as reference material
  - New game systems documented: Light system, Time system, Multi-surface containment, Dynamic room composition
  - Multiverse architecture comprehensively covered
- **Commit:** 50cf334 — "docs: refine vocabulary document v1.2 — align with all 24 architecture decisions"
- **Document Quality:**
  - 200+ terms maintained, 10 new terms added
  - All decisions cross-referenced where applicable
  - Living document contribution guidelines preserved
  - Markdown structure and TOC intact
- **Commit:** 50cf334 — "docs: refine vocabulary document v1.2 — align with all 24 architecture decisions"
- **Document Quality:**
  - 200+ terms maintained, 10 new terms added
  - All decisions cross-referenced where applicable
  - Living document contribution guidelines preserved
  - Markdown structure and TOC intact

### Session: Documentation Refresh (2026-03-20)

**Parallel Tasks:** 3 documentation tasks completed in parallel session

**Task 1: Newspaper Republish (Comic + Op-Ed)**
- Duration: ~1 minute
- Deliverable: 
ewspaper/2026-03-18.md — Republished with comic strip and op-ed sections
- Outcome: Comic section (visual humor about bedroom setup) and op-ed (reflections on V1 REPL readiness) established as recurring sections

**Task 2: Vocabulary Refinement v1.2**
- Duration: ~4 minutes
- Deliverable: docs/architecture/vocabulary.md — Updated glossary aligned with all 24 architecture decisions
- Changes: 10 new terms, 4 updated terms with cross-references, 15+ terms linked to [D-XX] decisions
- Coverage: All 24 decisions now covered

**Task 3: Design Directives Consolidation**
- Duration: ~2 minutes
- Deliverable: docs/design/design-directives.md — Consolidated user directives from Wayne
- Captured: V1 scope, light/time systems, paper/writing, skills, crafting, puzzle design, single-file mutation QUESTION

**Captured Wayne's Expanded Directives (12+ new features):**
- D-27: Keep docs current (not lagging behind implementation)
- D-28: Newspaper format (comic + op-ed recurring sections)
- D-29: Fire source for lighting (LIGHT requires tool)
- D-30: Paper and writing system (WRITE verb with pen/pencil/blood)
- D-31: Paper mutation on writing (paper's code rewrites to include written text)
- D-32: Blood as writing instrument (injury mechanics, knife/pin → blood resource)
- D-33: Player skills system (lockpicking, sewing, crafting unlocks new tool combos)
- D-34: Puzzle-first design philosophy (puzzles are first-class goal, not side effect)
- D-35: Single-file vs. multi-file mutation objects (OPEN QUESTION — challenges D-14 implementation)
- D-36: Sewing as crafting skill (cloth + needle + sewing skill → wearable items)
