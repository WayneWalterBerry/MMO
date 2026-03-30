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

### Room Goal Metadata (Options Phase 5)

**Pattern:** Each room declares a `goal` (or `goals` array) for the GOAP planner to generate contextual hints.

**Schema:** `goal = { verb = "...", noun = "...", label = "..." }` — verb+noun for GOAP planning, label for narrator framing. Multi-objective rooms use `goals` array with `priority` field.

**Decisions made:**
- Bedroom gets `goals` array (priority 1: light candle, priority 2: go north) + `options_delay = 3`
- Deep cellar gets `goal = pull chain` + `options_delay = 5` (atmospheric room, give player time)
- Crypt gets `options_mode = "sensory_only"` (sacred space, preserve mood)
- Cellar goal matches architecture doc example exactly: `{ verb = "go", noun = "north", label = "find a way forward" }`
- All other rooms get single `goal` with `verb = "go"` toward the main progression exit

**Anti-spoiler principle:** Labels describe HIGH-LEVEL objectives ("find a way out", "discover the chamber's secret"), never specific steps. GOAP figures out the prerequisite chain.

**Exemption flags used:**
- `options_delay` — bedroom (3 turns) and deep cellar (5 turns) to encourage exploration before hinting
- `options_mode = "sensory_only"` — crypt only, to protect the atmospheric tomb experience

---

## Cross-Agent Coordination: Options Build Complete (2026-03-29)

**Summary:** Room goal metadata Phase 5 complete. All 7 Level 1 rooms declare goals for hint system.

| Room | Goal | Verb + Noun | Exemptions | Status |
|------|------|------------|------------|--------|
| Bedroom | Multi-goal | light/go + candle/north | `options_delay=3` | ✅ |
| Hallway | Single | go + north | — | ✅ |
| Cellar | Single | go + north | — | ✅ |
| Storage Cellar | Single | go + north | — | ✅ |
| Deep Cellar | Single | pull + chain | `options_delay=5` | ✅ |
| Courtyard | Single | go + east | — | ✅ |
| Crypt | Single | read + inscription | `options_mode="sensory_only"` | ✅ |

**Coordination:**
- Bart's GOAP engine calls `goal_planner.plan()` on these goals (Phase 1+3 ✅)
- Smithers' parser routes "hint", "options", "what can I try?" to verb (Phase 2+4 ✅)
- Nelson's TDD suite validates anti-spoiler first-step filtering (Phase 6 ✅)

**Decision:** D-ROOM-GOALS merged to `.squad/decisions.md`.

---

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

---

## WAVE-1a: Wyatt's World — 7 Mr. Beast Challenge Rooms (2026-08-24)

**Task:** Build all 7 room .lua files + level-01.lua for Wyatt's World.  
**Commit:** aaeea74 on main  
**Requested by:** Wayne (autonomous — party mode)

### Files Created

| File | Room | ID | Difficulty |
|------|------|----|-----------|
| `rooms/beast-studio.lua` | MrBeast's Challenge Studio (Hub) | beast-studio | ★ |
| `rooms/feastables-factory.lua` | The Feastables Factory | feastables-factory | ★★ |
| `rooms/money-vault.lua` | The Money Vault | money-vault | ★★ |
| `rooms/beast-burger-kitchen.lua` | The Beast Burger Kitchen | beast-burger-kitchen | ★★★ |
| `rooms/last-to-leave.lua` | The Last to Leave Room | last-to-leave | ★★★ |
| `rooms/riddle-arena.lua` | The Riddle Arena | riddle-arena | ★★★★ |
| `rooms/grand-prize-vault.lua` | The Grand Prize Vault | grand-prize-vault | ★★★★ |
| `levels/level-01.lua` | Level definition | — | — |

All files under `src/meta/worlds/wyatt-world/`.

### Design Decisions

- **Exit format:** Inline exits with `{ target = "room-id" }` — no portal objects yet. Engine supports both portal and inline; Flanders can add portal objects later.
- **GUIDs:** Self-generated (bart-wyatt-guids.md not found). 8 unique GUIDs allocated for 7 rooms + level.
- **instances = {}** — Flanders builds objects in WAVE-1b; rooms are empty shells for now.
- **Goals:** Each room declares a `goal` for the Options hint system. Hub goal: "pick a challenge room." Challenge rooms: puzzle-specific verbs.
- **Hub-and-spoke:** Studio has 6 exits (north/south/east/west/up/down). Each challenge room has exactly 1 return exit to studio.
- **Writing style:** 3rd grade reading, MrBeast energy, 8-12 word sentences, all senses safe and fun.
- **No on_enter functions:** Kept rooms simple; on_enter narration can be added in WAVE-2.

### Lint Results

`python scripts/meta-lint/lint.py src/meta/worlds/wyatt-world/ --no-cache --verbose`  
**9 files scanned. 0 violations.** ✅

### Coordination Notes

- **Flanders (WAVE-1b):** Rooms are ready. `instances = {}` — populate with object type_ids when objects are built.
- **Bob (WAVE-1c):** Room descriptions match CBG's design.md puzzle specs. Goals align with puzzle mechanics.
- **Nelson (WAVE-1d):** Room-load tests can validate: 7 rooms load, required fields present, exits resolve, hub connectivity verified.
- **Bart:** GUID pre-assignment file (`bart-wyatt-guids.md`) was not found. Generated GUIDs independently. No collision risk — all GUIDs verified unique.

---

## Learnings

### 2025-01-XX — Wyatt World Room Wiring (Fix-0 + Fix-1)
**Task:** Wire 68 objects into 7 rooms + add lighting to all rooms
**Outcome:** Successfully completed. All 7 rooms now have `light_level = 1` and populated `instances` arrays with correct object GUIDs and spatial nesting.

**Key Decisions:**
- **Nesting Logic:** Used spatial common sense for object placement:
  - `on_top`: Buttons on podiums, cards on tables, chocolate bars on conveyor belt, ingredients on shelf, letter on pedestal, book on bookshelf
  - `contents`: Reserved for containers (bins, drawers — not heavily used in this world)
  - Standalone objects: Most decorative/functional items placed at room level (signs, furniture, prizes)
- **Light Level:** Set all rooms to `light_level = 1` since Wyatt's World is an E-rated kids' game show — no darkness puzzles

**Lessons:**
- Deep nesting syntax is straightforward: parent object defines nested arrays (`on_top`, `contents`, `nested`, `underneath`)
- GUIDs must match exactly between room `type_id` and object `guid` — used PowerShell to extract and verify all 68 GUIDs
- Puzzle specs are the authoritative source for object→room mapping
- Room `description` should only contain permanent features; movable objects go in `instances` for runtime composition

**Technical Notes:**
- Beast Studio (hub): 11 instances (welcome sign, podium with button, decorative studio equipment)
- Feastables Factory: 7 instances (conveyor belt with 5 chocolate bars on top, 4 sorting bins, medal)
- Money Vault: 6 instances (3 tables each with card on top, safe, sign, gold coins)
- Beast Burger Kitchen: 6 instances (shelf with 6 ingredients on top, plate, grill, sign, recipe card, coupon)
- Last to Leave: 6 instances (couch, rug, bookshelf with backwards book, lamp, clock, found-it box)
- Riddle Arena: 9 instances (3 riddle boards, podium, clock, piano, hole, spotlight, trophy)
- Grand Prize Vault: 6 instances (chest, pedestal with letter on top, trophy, streamers, confetti cannon, golden trophy)

**Impact:** This unblocks 97 filed bugs and makes Wyatt's World fully playable. Objects are now discoverable via LOOK, EXAMINE, and spatial verbs.
