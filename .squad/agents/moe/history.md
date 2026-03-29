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

---

## Learnings

### Portal Unification Pattern (Issue #203)

**Pattern:** Inline exit tables → paired portal objects. Each room-to-room connection gets two `.lua` files (one per side) sharing a `bidirectional_id`.

**Key files for deep-cellar ↔ hallway stairway:**
- `src/meta/objects/deep-cellar-hallway-stairs-up.lua` (deep cellar side, direction: up)
- `src/meta/objects/hallway-deep-cellar-stairs-down.lua` (hallway side, direction: down)
- `test/rooms/test-portal-deep-cellar-hallway.lua` (61 TDD tests)

**Open stairway conventions:**
- Always-open portals: `initial_state = "open"`, `_state = "open"`, single `open` state, no transitions
- Wind traverse: `on_traverse.wind_effect` with `extinguishes`, `spares`, and three message fields
- Room exits use thin references: `{ portal = "portal-id" }` — no inline target/open/locked fields

**Room wiring:**
- Portal objects go in `instances` array (with type_id GUID)
- Exit table uses `{ portal = "portal-id" }` to delegate to the object
- Naming convention: `{from-room}-{to-room}-{feature}-{direction}` (e.g., `deep-cellar-hallway-stairs-up`)

**Linter notes:**
- MAT-03 warnings (material by name) are Flanders' concern, not blocking
- XF-03 keyword overlap between stairs portals is expected — parser handles disambiguation by room context
- EXIT-03 (bidirectional partner check) only works when linting the full `src/meta/objects/` directory

---

## Latest Activity

**Options Review Ceremony (2026-08-02):**
- Reviewed Options project as World & Level Builder
- Verdict: ✅ APPROVE with concerns (0 blockers, 3 concerns, 6 approvals)
- Mapped all 7 Level 1 room goals: 2 multi-phase, 4 single, 1 no-goal
- Validated Phase 5 workload estimate (2.5-3.5 hours)
- See `.squad/decisions/inbox/moe-options-review.md` for full review
- Key concerns: goal completion detection semantics, deep-cellar priority, linter validation
