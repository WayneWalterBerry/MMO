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
│   │   ├── materials/                  # Material registry (13+ materials, numeric properties)
│   │   ├── parser/                     # Parser pipeline (Tiers 1-5) + GOAP goal planner
│   │   └── loop/                       # Game loop, environment context
│   └── meta/
│       ├── objects/                     # 37+ object .lua definitions (candle, matchbox, bed, etc.)
│       ├── world/                       # Room .lua definitions (start-room, cellar)
│       └── templates/                   # Base templates (room template)
├── docs/
│   ├── architecture/
│   │   ├── objects/                     # Core principles (8 inviolable principles)
│   │   ├── engine/                      # Engine architecture (FSM, materials, parser tiers)
│   │   ├── player/                      # Player model, movement, sensory
│   │   ├── rooms/                       # Room architecture
│   │   └── ui/                          # UI architecture (text output, parser UX)
│   ├── design/
│   │   ├── puzzles/                     # Puzzle design methodology (rating, classification, patterns)
│   │   ├── rooms/                       # Room design methodology
│   │   └── levels/                      # Level design methodology (considerations, principles)
│   ├── puzzles/                         # Individual puzzle specs (001-008)
│   ├── objects/                         # Individual object documentation
│   ├── rooms/                           # Individual room documentation
│   └── levels/                          # Individual level designs (level-01-intro.md)
├── newspaper/                           # 📰 The MMO Gazette — daily team newspapers
│   ├── 2026-03-18.md                    # Edition 1 — Project launch
│   ├── 2026-03-19.md                    # Edition 2 — Engine advances
│   ├── 2026-03-20-morning.md            # Edition 3 — Morning update
│   └── 2026-03-20-evening.md            # Edition 4 — Evening wrap-up
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
| `src/` | Game source code — engine, objects, rooms, templates |
| `docs/architecture/` | Architectural decisions, core principles, engine specs |
| `docs/design/` | Design methodology — how to design puzzles, rooms, levels |
| `docs/puzzles/` | Individual puzzle specifications (001–008+) |
| `docs/levels/` | Individual level design documents |
| `docs/objects/` | Individual object documentation |
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
