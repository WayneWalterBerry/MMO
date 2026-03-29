# Willie — Project History

## Project Context
- **Project:** MMO — Lua text adventure game inspired by Zork
- **Owner:** Wayne "Effe" Berry
- **Tech:** Pure Lua engine, zero external dependencies
- **My role:** Creature Designer — I own all creature/NPC .lua files and behavior metadata

## Core Context
- Creatures are objects with `animate = true` — they follow ALL standard object rules plus creature-specific fields
- Creature template at `src/meta/templates/creature.lua`
- Existing creatures: rat, cat, bat, wolf (Phase 1-4 builds)
- Phase 4 added: loot tables, butchery, stress, pack tactics v1, territorial behavior, creature actions
- Phase 5 plan ready: werewolf NPC, simplified pack v1.1, Level 2 creatures
- 12 mutation edge mechanisms — 7 are creature-specific (loot_table.*, death_state.*, behavior.creates_object)
- Lint before commit: `python scripts/meta-lint/lint.py {file}` — Wiggum owns the linter, I just run it
- Flanders previously owned creatures — I'm inheriting from him. Consult Flanders history for creature patterns.

## Learnings
- Joined the team 2026-03-29. Inheriting creature work from Flanders.
