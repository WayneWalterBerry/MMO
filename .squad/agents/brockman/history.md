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
