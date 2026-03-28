# Comic Book Guy — History (Summarized)

## Project Context

- **Project:** MMO — A text adventure MMO with multiverse architecture
- **Owner:** Wayne "Effe" Berry
- **Role:** Game Designer responsible for object definitions, sensory descriptions, and content creation

## Core Context

**Agent Role:** Game Designer specializing in multi-sensory object systems and interactive content that works in complete darkness.

**Design Philosophy:** Darkness is not a wall — it's a different mode of play. Every sense gives different information about the same object. TASTE is the "learn by dying" sense that teaches caution and consequence.

## Archives

- `history-archive-2026-03-22.md` — Early sessions
- `history-archive-2026-03-20T22-40Z-comic-book-guy.md` — Full archive (2026-03-18 to 2026-03-20T22:40Z): 37+ objects, multi-sensory convention, skills system, FSM lifecycle, command variation matrix, composite objects, spatial system

- `history-archive.md` — Entries before 2026-07-14 (2026-03-19 to 2026-03-28)

## Learnings

### Worlds Meta Concept (2026-08-21)
- Created `docs/design/worlds.md` — the authoritative design spec for the new **Worlds** top-level meta concept.
- **Content hierarchy** updated: World → Level → Room → Object/Creature/Puzzle. Worlds sit above Levels as thematic envelopes.
- **World .lua file format** defined: `template = "world"`, GUID, id, name, description, `starting_room`, `levels` (ordered list), `theme` table, optional `theme_files` for lazy-loaded subsections.
- **Theme structure** is the heart of the World: `pitch`, `era`, `atmosphere`, `aesthetic` (materials + forbidden), `tone`, `constraints`. Theme is internal design guidance — never player-facing.
- **Two starting rooms**: `world.starting_room` (game boot) vs `level.start_room` (intra-level respawn). Distinct purposes, may differ.
- **Lazy loading**: World files loaded at boot (small), levels loaded on demand, rooms loaded on demand (unchanged), theme files loaded on demand (V1: never at runtime).
- **Single-world auto-boot**: With one World, engine auto-selects — no UI needed. Multi-world selection is future design.
- **File location**: `src/meta/worlds/world-01.lua`, themes in `src/meta/worlds/themes/`. New template `src/meta/templates/world.lua`.
- **World 1** ("The Manor") sketched: gothic domestic horror, late medieval era, stone/iron/wood/tallow/wool palette, consumable light, no magic, real animals only.
- Decision filed: `D-WORLDS-CONCEPT` in `.squad/decisions/inbox/cbg-worlds-concept.md`.

## Recent Updates
