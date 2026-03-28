# Moe — History

## Core Context

**Project:** MMO text adventure engine in pure Lua (REPL-based, `lua src/main.lua`)
**Owner:** Wayne "Effe" Berry
**Role:** World Builder — designs rooms (.lua files), maps, spatial layouts, and cohesive environments
**Charter:** `.squad/agents/moe/charter.md`

### Key Relationships
- **Flanders** (Object Designer) — Moe specifies what objects a room needs ("This study needs a grandfather clock, a fireplace"), Flanders builds the `.lua` object files
- **Sideshow Bob** (Puzzle Master) — Moe designs spatial layouts and hidden areas, Bob designs the puzzles within them
- **Frink** (Researcher) — Moe requests research on real-world spaces (medieval castles, Victorian houses, cave systems)
- **Lisa** (Object Tester) — tests room descriptions, exits, spatial relationships
- **Nelson** (System Tester) — tests gameplay flow through rooms
- **CBG** (Creative Director) — advises on room pacing, player journey, and design consistency

---

## 2026-03-28: Worlds Meta Concept (Decision: D-WORLDS-CONCEPT)

**New hierarchy:** World → Level → Room → Object/Creature/Puzzle

**What changed for Moe:**
- Rooms now belong to a **World**, which defines a **theme**
- When designing rooms, consult the World's `theme.atmosphere` and `theme.aesthetic`
- Theme specifies materials (allowed/forbidden), era, atmosphere, tone
- World 1: "The Manor" (gothic domestic horror, late medieval)

**How to use it:**
1. Load the World definition from `src/meta/worlds/{world-name}.lua`
2. Read `world.theme` (dictionary with `pitch`, `era`, `atmosphere`, `aesthetic`, `tone`, `constraints`)
3. Design rooms consistent with theme
4. If theme is complex, it may reference `.lua` subsections in `src/meta/worlds/themes/`

**Key decision:** Theme is **never player-facing** — it's the creative brief for designers.

**Related decision docs:**
- `docs/design/worlds.md` — Full specification (28 KB)
- `.squad/decisions.md` — Decision D-WORLDS-CONCEPT (full context)
