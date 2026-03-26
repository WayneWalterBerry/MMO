# MMO — A Text Adventure Game for Mobile

Welcome to **MMO**, a modern text adventure game inspired by the timeless design of *Zork*. This is a working prototype implementing a **Lua-based interactive fiction engine** with containment hierarchies, a mutation-based object system, and a verb-dispatch command parser.

## What Is This?

MMO is a functional **text adventure engine** built on Lua, featuring:
- **Containment hierarchy**: objects exist in/on other objects (coins in bags, bags in rooms, etc.)
- **Instance/base-class architecture**: objects are defined as templates with per-room instantiation
- **Mutations**: objects transform via verb handlers (e.g., breaking a mirror spawns shards)
- **Tool system**: verbs require capabilities (e.g., cutting requires a sharp tool)
- **Sensory verbs**: look, feel, smell, taste, listen (not just examine)
- **Dynamic light**: time-of-day system with light sources, daylight, and darkness mechanics
- **Two-hand inventory**: strategic inventory management with compound tool actions

## How to Run

```bash
lua src/main.lua
```

The game starts in a dark bedroom at 2 AM. Use sensory verbs to explore and interact with objects.

## Folder Structure

```
MMO/
├── src/
│   ├── main.lua                        # Entry point — REPL game loop
│   ├── engine/
│   │   ├── fsm/                        # Finite state machine engine (apply_mutations, thresholds)
│   │   ├── materials/                  # Material registry (17+ materials, numeric properties)
│   │   ├── parser/                     # Parser pipeline (Tiers 1-5) + GOAP goal planner
│   │   ├── ui/                          # UI presentation layer (status bar, text formatting)
│   │   └── loop/                       # Game loop, environment context
│   └── meta/
│       ├── objects/                     # 74+ inanimate object .lua definitions
│       ├── creatures/                   # Creature .lua definitions (animate)
│       ├── world/                       # 7 room .lua definitions (Level 1 complete)
│       ├── levels/                      # Level .lua definitions (level-01.lua)
│       └── templates/                   # Base templates (room template)
├── web/                                 # Fengari browser wrapper (beta testing)
├── blog/                                # 📝 Blog post drafts and source files
│   ├── blog-squad-specialists.md        # Published: AI specialist teams
│   └── blog-research-driven-development.md  # Draft: development methodology
├── docs/
│   ├── architecture/
│   │   ├── objects/                     # Core principles (8 inviolable principles)
│   │   ├── engine/                      # Engine architecture (FSM, materials, parser, levels)
│   │   ├── player/                      # Player model, movement, sensory
│   │   ├── rooms/                       # Room architecture
│   │   └── ui/                          # UI architecture (text output, parser UX, code ownership)
│   ├── design/
│   │   ├── puzzles/                     # Puzzle design methodology (rating, classification, patterns)
│   │   ├── rooms/                       # Room design methodology
│   │   └── levels/                      # Level design methodology (considerations, principles)
│   ├── objects/                         # Object documentation (shared across levels)
│   └── levels/
│       └── 01/                          # Level 1 — "The Awakening"
│           ├── level-01-intro.md        # Level overview
│           ├── rooms/                   # Room docs for Level 1
│           └── puzzles/                 # Puzzle docs for Level 1 (001-014)
├── newspaper/                           # 📰 The MMO Gazette — daily team newspapers
│   ├── 2026-03-18.md                    # Edition 1 — Project launch
│   ├── 2026-03-19.md                    # Edition 2 — Engine advances
│   ├── 2026-03-20-morning.md            # Edition 3 — Morning update
│   ├── 2026-03-20-evening.md            # Edition 4 — Evening wrap-up
│   └── 2026-03-21-special-edition.md    # Edition 5 — Special Edition
├── resources/
│   └── research/
│       ├── architecture/                # Dynamic object mutation research (37KB)
│       ├── competitors/                 # Dwarf Fortress architecture comparison (36KB)
│       ├── rooms/                       # Room design research (42KB)
│       └── puzzles/                     # Puzzle design research (47KB)
├── test-pass/
│   ├── gameplay/                        # Nelson's gameplay test passes
│   └── objects/                         # Lisa's object test passes
├── .squad/                              # AI team coordination and state
└── README.md                            # This file
```

### Key Folders

| Folder | Purpose |
|--------|---------|
| `src/` | Game source code — engine, objects, rooms, levels, templates |
| `src/meta/levels/` | Level definitions (level-01.lua) |
| `src/meta/creatures/` | Creature definitions (animate, ticked every turn) |
| `web/` | Fengari browser wrapper for web-based beta testing |
| `blog/` | 📝 Blog post drafts and source files (not game docs) |
| `docs/architecture/` | Architectural decisions, core principles, engine specs |
| `docs/design/` | Design methodology — how to design puzzles, rooms, levels |
| `docs/levels/01/` | Level 1 docs — room and puzzle specs organized per level |
| `docs/objects/` | Object documentation (shared across all levels) |
| `newspaper/` | 📰 **The MMO Gazette** — daily team newspapers with updates, decisions, and progress. Named by date (e.g., `2026-03-20-evening.md`) |
| `resources/research/` | Research documents — IF history, DF comparison, room/puzzle design (200KB+ total) |
| `test-pass/` | Test pass results — `gameplay/` (Nelson) and `objects/` (Lisa) |
| `.squad/` | Team coordination, agent charters, decisions, casting |

## Project Stage

✅ **Prototype Phase**

The core engine is functional and playable. The V1 bedroom scenario with 45+ objects, sensory interactions, light mechanics, and tool-based puzzles is ready for playtesting.

## Documentation

- **[Source structure guide](docs/architecture/src-structure.md)** — How the engine is organized
- **[Vocabulary](docs/architecture/vocabulary.md)** — Terms used across the project
- **[Verb system](docs/design/verb-system.md)** — Complete list of implemented verbs and handlers
- **[Instance model](docs/architecture/instance-model.md)** — How objects are defined and instantiated
- **[Design directives](docs/design/design-directives.md)** — Game design rules and mechanics
- **[Puzzles](docs/puzzles/)** — Design docs for in-game puzzles

## Getting Started

- **Play the game**: `lua src/main.lua`
- **Explore the code**: Start with `src/main.lua`, then `src/engine/` for the core systems
- **Check the latest news**: See [newspaper editions](newspaper/) for team updates and changes
- **Understand the design**: Read [architecture decisions](docs/design/architecture-decisions.md)

## Team

This project is developed by a coordinated team of specialists (both human and AI). See `.squad/team.md` for roles and governance.

---

*Last updated: 2026-03-21*
