# Documentation Index

This is the main documentation hub. Browse by purpose:

## Architecture & Systems
- **`architecture/`** — Engine architecture, player system, web delivery, event handlers, UI

## Design & Gameplay
- **`design/`** — Gameplay design: player health, injuries, healing items, levels
  - **🎯 Prime Directive:** Game feels like talking to an AI — natural and forgiving — but runs entirely on client with zero runtime tokens. See `design/00-design-requirements.md`

## Reference Documentation

Reference docs explain *what things are*:

- **`objects/`** — Per-object reference docs
- **`templates/`** — Template system: container, furniture, room, sheet, small-item
- **`injuries/`** — Per-injury reference docs  
- **`verbs/`** — Verb reference: command syntax, behavior, and design patterns
- **`rooms/`** — Per-room reference docs
- **`puzzles/`** — Per-puzzle reference docs

## Testing & Quality
- **`testing/`** — Test framework, test patterns, CI guidelines
  - **`testing/mutation-graph-linting.md`** — Mutation graph linter: edge extraction, validation, and debugging broken mutations

## Other Resources
- **`levels/`** — Level design and intro docs
- **`contributing/`** — Contribution guidelines and project standards

---

**Navigation Rule:** When a new folder is added to `docs/`, update this README to maintain discoverability.
