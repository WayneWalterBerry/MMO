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
├── docs/
│   └── architecture/           # Architectural decisions and design docs
├── newspaper/                  # The MMO Gazette — daily team updates & decisions
├── resources/
│   └── research/
│       └── architecture/       # Background research on IF engines & data structures
├── .squad/                     # AI team coordination and state
└── README.md                   # This file
```

### Key Folders

| Folder | Purpose |
|--------|---------|
| `docs/` | Project documentation, architecture decisions, and technical specifications |
| `newspaper/` | Daily editions of The MMO Gazette — team updates, decisions, and progress |
| `resources/research/` | Reference materials on classic IF (Zork, Inform, TADS) and modern approaches |
| `.squad/` | Team coordination, agent state, and governance |

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
