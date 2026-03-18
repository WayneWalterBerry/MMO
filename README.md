# MMO — A Text Adventure Game for Mobile

Welcome to **MMO**, a modern text adventure game for mobile phones, inspired by the timeless design of *Zork*. This project explores how classic interactive fiction can thrive on contemporary platforms through elegant architecture and containment hierarchies.

## What Is This?

MMO is an early-stage research and architecture exploration project. Our core concept: **containment hierarchies** — the idea that game objects exist within other objects (coins in bags, people in rooms, items on tables). This simple model unlocks rich interactive possibilities while keeping the system clean and maintainable.

Think of it as building a new engine for text-based adventure games, starting with the fundamentals and scaling thoughtfully.

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

🔬 **Research & Architecture Phase**

We're currently exploring and validating the core architectural patterns. Expect experimentation, design documents, and research artifacts. This is not a shipping product—yet.

## Getting Started

- Check the latest **[newspaper edition](newspaper/)** for recent team updates
- Review **[architecture research](resources/research/architecture/)** to understand the problem space
- Explore **[design decisions](docs/architecture/)** for architectural choices

## Team

This project is developed by a coordinated team of specialists (both human and AI). See `.squad/team.md` for roles and governance.

---

*Last updated: 2026-03-18*
