# Wyatt's World — Implementation Plan

**Version:** 2.1  
**Author:** Bart (Architect)  
**Date:** 2026-08-23  
**Status:** `WAVE-0: ⏳ | WAVE-1: ⏳ | WAVE-2: ⏳ | WAVE-3: ⏳`  
**Replaces:** v2.0 (2026-08-22) — Kirk's v1.0 plan (2026-03-27)  
**Source Design:** `projects/wyatt-world/design.md` (CBG v1.0, 543 lines)  
**Decisions:** D-WORLDS-CONCEPT, D-WORLDS-LOADER-WAVE0, D-WYATT-WORLD, D-RATING-TWO-LAYER  
**v2.1 Changes:** Fixed 3 blockers (B1–B3) + 12 concerns (C1–C12) from 6-agent team review

---

## 1. Executive Summary

**What:** A Mr. Beast–themed text adventure world for Wyatt (age 10). Seven rooms, seven puzzles, ~70 objects. Hub-and-spoke layout. 3rd-grade reading, 5th-grade puzzles. Bright, fun, safe — the opposite of The Manor.

**Why now:** The engine already has a world loader (D-WORLDS-LOADER-WAVE0) but it errors on 2+ worlds. Wayne wants Wyatt's World to coexist with The Manor. That means the engine needs multi-world support first, then content gets built on top.

**How (4 waves):**

| Wave | What | Who | Gate |
|------|------|-----|------|
| WAVE-0 | Multi-world engine loader | Bart | Engine boots either world |
| WAVE-1 | 7 rooms + ~70 objects + 7 puzzle specs | Moe, Flanders, Bob | All rooms load, all objects register |
| WAVE-2 | Parser polish + full testing | Smithers, Nelson | All puzzles solvable, reading-level pass |
| WAVE-3 | Creative review + web deploy | CBG, Wayne, Gil | Wyatt plays in browser |

**Key constraint correction from Kirk's v1.0:** Kirk's plan said "no engine changes." Wayne overruled — multi-world loader goes in WAVE-0 as engine work (Bart's domain). The engine currently `return nil, "world selection not implemented"` when it finds 2+ worlds. That must be fixed before any Wyatt content is loadable.

---

## 2. Quick Reference Table

| Wave | Agent(s) | Files Created/Modified | Gate | Est. LOC |
|------|----------|----------------------|------|----------|
| **WAVE-0** | Bart | `src/engine/world/init.lua`, `src/main.lua`, `src/meta/worlds/wyatt-world.lua`, dirs, E-rating enforcement | GATE-0: Both worlds boot + E-rating enforced | ~200 |
| **WAVE-1a** | Moe | `src/meta/worlds/wyatt-world/rooms/*.lua` (7 files) | GATE-1: All rooms load | ~700 |
| **WAVE-1b** | Flanders | `src/meta/worlds/wyatt-world/objects/*.lua` (~70 files) | GATE-1: All objects register | ~3500 |
| **WAVE-1c** | Bob | `projects/wyatt-world/puzzles/*.md` (7 specs) | GATE-1: Puzzle specs reviewed | ~350 |
| **WAVE-1d** | Nelson | `test/worlds/wyatt/*.lua` (test files) | GATE-1: Tests pass | ~400 |
| **WAVE-2a** | Smithers | `src/engine/parser/`, `src/engine/verbs/init.lua` (if needed) | GATE-2: Parser handles all Wyatt nouns |~50 |
| **WAVE-2b** | Nelson | `test/worlds/wyatt/test-*.lua` (puzzle walkthroughs) | GATE-2: All puzzles solved by LLM | ~600 |
| **WAVE-3a** | CBG | Review pass (no code) | GATE-3: Creative sign-off | 0 |
| **WAVE-3b** | Wayne | Text audit (edits only) | GATE-3: Reading-level sign-off | ~100 |
| **WAVE-3c** | Gil | `web/`, world selector | GATE-3: Web live | ~200 |

**Total estimated new LOC:** ~6,050

---

## 3. Dependency Graph

```
WAVE-0: Engine (Bart)
  │
  ├── Upgrade world/init.lua select() for multi-world
  ├── Add --world CLI flag to main.lua
  ├── Refactor main.lua content loading to be world-aware
  ├── Create wyatt-world.lua definition + directory structure
  ├── E-rating enforcement: verb dispatch interception (B1)
  ├── Tests: multi-world selection, content isolation, E-rating blocks
  └── Pre-assign GUID block for ~80 entities (B3)
  │
  ▼ GATE-0: `lua src/main.lua --world world-1` boots The Manor
  │          `lua src/main.lua --world wyatt-world` boots (empty world, no crash)
  │          E-rating: combat/harm verbs blocked in wyatt-world
  │          `lua test/run-tests.lua` — zero regressions
  │
  ╔═══════════════════════════╦═══════════════════════╦═══════════════════════╗
  ║ WAVE-1a: Rooms (Moe)     ║ WAVE-1b: Objects (FL) ║ WAVE-1c: Puzzles (Bob)║
  ║ 7 room .lua files        ║ ~70 object .lua files ║ 7 puzzle specs (.md)  ║
  ║ rooms/*.lua               ║ objects/*.lua          ║ puzzles/*.md           ║
  ╚═══════════╦═══════════════╩═══════════╦═══════════╩═══════════╦═══════════╝
              │                           │                       │
              │     WAVE-1d: Nelson       │                       │
              │     (test scaffolding)    │                       │
              │                           │                       │
              ▼───────────────────────────▼───────────────────────▼
  GATE-1: All 7 rooms load. All objects register. No GUID collisions.
  │        Puzzle specs approved by CBG. Hub exits connect. Zero regressions.
  │
  ╔═════════════════════════════╦══════════════════════════════════╗
  ║ WAVE-2a: Parser (Smithers)  ║ WAVE-2b: Testing (Nelson)        ║
  ║ Kid-friendly error msgs     ║ Puzzle walkthroughs (headless)   ║
  ║ Embedding index update      ║ Sensory coverage                 ║
  ║ (if needed)                 ║ Reading-level scan               ║
  ╚═════════════╦═══════════════╩══════════════════╦═══════════════╝
                ▼──────────────────────────────────▼
  GATE-2: All 7 puzzles solvable via LLM walkthrough (headless).
  │        All sensory verbs work on all objects. Zero regressions.
  │        No reading-level violations flagged.
  │
  ╔════════════════════╦══════════════════╦═════════════════════╗
  ║ WAVE-3a: CBG       ║ WAVE-3b: Wayne   ║ WAVE-3c: Gil        ║
  ║ Creative review    ║ Text audit       ║ Web world selector  ║
  ╚════════╦═══════════╩════════╦═════════╩══════════╦══════════╝
           ▼────────────────────▼────────────────────▼
  GATE-3: CBG creative sign-off. Wayne reading-level sign-off.
           Web live with world selector. Wyatt can play in browser.
```

---

## 4. Implementation Waves

### WAVE-0: Multi-World Engine Loader (Bart)

**Goal:** Make the engine load different worlds from world-specific content directories. The Manor continues working unchanged. Wyatt's World loads from its own directory (empty at first — content comes in WAVE-1).

**Prerequisite:** None. This is engine-only.

#### 4.0.1 World Content Root Convention

Each world .lua file gains an optional `content_root` field:

```lua
-- In world-01.lua (The Manor):
-- content_root is nil → loader uses legacy paths:
--   rooms:   src/meta/rooms/
--   objects: src/meta/objects/
--   levels:  src/meta/levels/

-- In wyatt-world.lua:
content_root = "worlds/wyatt-world",
-- Resolves to: src/meta/worlds/wyatt-world/
--   rooms:   src/meta/worlds/wyatt-world/rooms/
--   objects: src/meta/worlds/wyatt-world/objects/
--   levels:  src/meta/worlds/wyatt-world/levels/
```

**Why relative path?** `content_root` is relative to `src/meta/`. This keeps paths portable across OS and avoids hardcoding absolute paths. The engine prepends `meta_root` at load time.

#### 4.0.2 World Loader Upgrades (`src/engine/world/init.lua`)

| Change | Description |
|--------|-------------|
| `select(worlds, world_id)` | New signature. If `world_id` is provided, find by ID. If nil and 1 world, auto-select. If nil and 2+ worlds, return error with available IDs. |
| `get_content_paths(world, meta_root)` | New function. Returns `{ rooms_dir, objects_dir, creatures_dir, levels_dir }` resolved from `content_root` or legacy defaults. |
| Backward compat | `select({one_world})` still works (auto-select). Zero-arg select path unchanged. |

#### 4.0.3 Main.lua Refactoring (`src/main.lua`)

| Change | Description |
|--------|-------------|
| `--world <id>` CLI flag | New flag. Passed to `world.select()`. |
| Content loading | Replace hardcoded `meta_root .. SEP .. "rooms"` etc. with paths from `world.get_content_paths()`. |
| Level loading | Load level file(s) from world-specific levels dir instead of hardcoded `level-01.lua`. |
| Intro text | Read intro from level data as before — but the level comes from the selected world's level dir. |
| World on context | Already exists (`context.world`). Ensure it's populated from the selected world. |

#### 4.0.4 Wyatt World Definition — Rating Field (B1)

The world definition file at `src/meta/worlds/wyatt-world.lua` **must** declare `rating = "E"`:

```lua
return {
    guid = "{6F129CCE-4798-446D-9CD8-198B36F04EF0}",
    template = "world",
    id = "wyatt-world",
    name = "Wyatt's World",
    rating = "E",  -- Everyone (engine-enforced: no combat/harm verbs)
    description = "A MrBeast challenge course! Seven rooms. Seven puzzles. "
               .. "Can you solve them all and win the grand prize?",
    starting_room = "beast-studio",
    content_root = "worlds/wyatt-world",
    levels = { 1 },
    theme = { ... },  -- per CBG design.md § Engine Compatibility Notes
    mutations = {},
}
```

The `rating` field is read by the engine at verb dispatch time (see §4.0.7). Future worlds declare their own rating ("E", "T", or nil for legacy).

#### 4.0.6 Directory Structure Creation

```
src/meta/worlds/wyatt-world/
├── rooms/          (empty — WAVE-1a populates)
├── objects/        (empty — WAVE-1b populates)
└── levels/         (empty — WAVE-1b populates)
```

**Agent:** Bart  
**Files touched:** `src/engine/world/init.lua`, `src/main.lua`, `src/meta/worlds/wyatt-world.lua`, test files, empty dirs  
**TDD:** Write tests first for `select(worlds, id)` and `get_content_paths()`, then implement.  
**Estimated LOC:** ~200 new/modified (was ~150; +50 for E-rating enforcement)  
**Risk:** Main.lua refactoring could break existing boot. Mitigated by running full test suite + headless Manor boot as regression check.

#### 4.0.7 E-Rating Enforcement (B1 — Two-Layer Model)

**Directive:** Per `copilot-directive-rating-system.md` and `copilot-directive-rating-two-layer.md`, every world declares a `rating` field. The engine enforces rating restrictions at verb dispatch time.

**Two-Layer Enforcement Model:**

| Layer | What | How | Owner |
|-------|------|-----|-------|
| **Engine-enforced (hard block)** | Combat, attack, self-harm, injury verbs | Verb dispatch checks `context.world.rating` before execution. If verb is E-restricted, refuse with kid-friendly message. | Bart (WAVE-0) |
| **Design-enforced (soft guideline)** | No poison objects, no scary content, no hostile creatures, taste always safe | Designers simply don't create harmful objects for E-rated worlds. Engine doesn't block the VERB — content just doesn't include dangerous objects. | CBG / Flanders (WAVE-1) |

**E-Restricted Verbs (hard-blocked in `rating = "E"` worlds):**
- `attack`, `fight`, `kill`, `stab`, `slash`, `punch`, `kick`
- `harm`, `hurt`, `injure`, `wound`
- `self-harm` (any self-directed damage verb)
- All combat-related aliases that resolve to the above

**NOT restricted (safe in E-rated worlds):**
- `taste`, `lick` — safe because E-world content has no poison (design-enforced)
- `break`, `smash` — safe because E-world objects break harmlessly (design-enforced)
- `look`, `feel`, `smell`, `listen`, `examine`, `read`, `take`, `drop`, `put`, `press`, `open`, `close`, `go`, `enter` — all safe

**Dispatch Interception Point (C8):**

The E-rating check lives in `src/engine/verbs/init.lua` at the top of the verb dispatch function, BEFORE the handler executes:

```lua
-- In verb dispatch (src/engine/verbs/init.lua):
local E_RESTRICTED_VERBS = {
    attack = true, fight = true, kill = true, stab = true,
    slash = true, punch = true, kick = true,
    harm = true, hurt = true, injure = true, wound = true,
}

-- At dispatch time, before calling handler:
if context.world and context.world.rating == "E" and E_RESTRICTED_VERBS[verb] then
    context.output("That's not part of this world.")
    return
end
```

**Why verb dispatch, not parser preprocess:** The parser should still PARSE "attack the sign" (the player typed valid English). The block happens at execution — the engine refuses to RUN the verb handler. This preserves clean parser semantics and makes the error message contextual.

**Error message:** `"That's not part of this world."` — neutral, encouraging, age-appropriate. Doesn't shame the player. Doesn't explain the rating system. Just redirects.

#### 4.0.8 GUID Pre-Assignment Block (B3)

All ~80 GUIDs for Wyatt's World entities are pre-assigned by Bart before WAVE-1 starts. Published to `.squad/decisions/inbox/bart-wyatt-guids.md`. Moe and Flanders use sequential GUIDs from this block — no independent GUID generation.

See `bart-wyatt-guids.md` for the complete assignment table.

#### 4.0.9 Tests (Extended)

| Test File | What It Tests |
|-----------|---------------|
| `test/worlds/test-world-loader.lua` | Extended: `select(worlds, id)` by ID, `get_content_paths()`, legacy fallback, multi-world discovery |
| `test/worlds/test-multi-world-boot.lua` | Integration: discovers both worlds from disk, selects each by ID, content paths resolve correctly |
| `test/worlds/test-e-rating-blocks.lua` | **New (B2).** E-rating enforcement: attack/fight/stab/kill/harm verbs blocked in E-rated worlds; taste/look/feel/take etc. still work normally |

---

### WAVE-1: Content Foundation (Moe + Flanders + Bob + Nelson — Parallel)

**Prerequisite:** GATE-0 passes. Engine boots both worlds.

All four agents work in parallel on different files. No conflicts possible — Moe writes rooms, Flanders writes objects, Bob writes puzzle specs, Nelson writes test scaffolding.

#### WAVE-1a: Room Building (Moe)

**Goal:** Build 7 room .lua files per CBG's design (§ Room Concepts).

**Files created:**

| File | Room | Difficulty |
|------|------|-----------|
| `src/meta/worlds/wyatt-world/rooms/beast-studio.lua` | MrBeast's Challenge Studio (Hub) | ★ |
| `src/meta/worlds/wyatt-world/rooms/feastables-factory.lua` | The Feastables Factory | ★★ |
| `src/meta/worlds/wyatt-world/rooms/money-vault.lua` | The Money Vault | ★★ |
| `src/meta/worlds/wyatt-world/rooms/beast-burger-kitchen.lua` | The Beast Burger Kitchen | ★★★ |
| `src/meta/worlds/wyatt-world/rooms/last-to-leave.lua` | The Last to Leave Room | ★★★ |
| `src/meta/worlds/wyatt-world/rooms/riddle-arena.lua` | The Riddle Arena | ★★★★ |
| `src/meta/worlds/wyatt-world/rooms/grand-prize-vault.lua` | The Grand Prize Vault | ★★★★ |

**Exit table (from CBG design § Map Layout):**

| From | Direction | To |
|------|-----------|-----|
| beast-studio | north | feastables-factory |
| beast-studio | south | money-vault |
| beast-studio | east | beast-burger-kitchen |
| beast-studio | west | last-to-leave |
| beast-studio | up | riddle-arena |
| beast-studio | down | grand-prize-vault |
| (each room) | (reverse) | beast-studio |

**Room rules:**
- `template = "room"` — same as The Manor
- `description` = permanent features only (3 sentences max, per CBG writing guide)
- All exits are open archways or doors — **never locked, never closed**
- No darkness mechanic — all rooms are brightly lit
- `instances` use deep-nesting syntax (`on_top`, `contents`, `nested`, `underneath`)
- Every room gets a `goal` field (for the options system, per D-OPTIONS-ENGINE-HYBRID)
- All text at 3rd-grade reading level
- **Ambient sound specification (C9):** Each room description MUST include at least one non-visual sensory detail (sound and/or smell) in the 3-sentence description. Examples: "A big grill sizzles in the corner." (Burger Kitchen), "The whole room smells like chocolate." (Feastables Factory). Room-level `on_listen` is environmental flavor in the description, not a separate verb target (rooms are passive — objects have `on_listen`).

**Agent:** Moe  
**TDD:** Nelson writes room-load tests in parallel (WAVE-1d)

#### WAVE-1b: Object Building (Flanders)

**Goal:** Build ~70 object .lua files per CBG's design (§ Object Categories).

**File location:** `src/meta/worlds/wyatt-world/objects/`

**Object categories (from CBG design):**

| Category | Count | Examples |
|----------|-------|---------|
| Challenge props | ~25 | Big red button, colored buttons, combo dials, sorting bins, conveyor belt bars, recipe card, burger plate, safe keypad, riddle podium buttons |
| Prize items | ~8 | Golden trophy, Beast Burger coupon, medals, confetti, cash bundles |
| MrBeast brand items | ~10 | 5 Feastables bars (flavors), assembled burger, MrBeast merch, play button |
| Reading/clue objects | ~12 | Welcome sign, instruction signs, MrBeast letter, bin labels, recipe cards, 3 riddle boards, scoreboard |
| Set dressing | ~15 | Giant screens, cameras, speakers, banners, confetti floor, spotlights, streamers |
| **Total** | **~70** | |

**Object rules:**
- Every object MUST have `on_feel` (engine requirement)
- All sensory descriptions at 3rd-grade reading level
- `on_taste` is ALWAYS safe and silly (no poison — this is not The Manor)
- FSM states for interactive objects (buttons, dials, bins, keypad, scoreboard)
- GUIDs: Windows format `{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}`, all unique
- Templates: `small-item`, `furniture`, `container`, `sheet` — same as existing
- Keywords: simplest possible words ("button" not "actuator", "sign" not "placard")

**GUID Pre-Assignment:** Bart reserves a GUID block before WAVE-1 starts (per implementation-plan skill §15). Written to `.squad/decisions/inbox/bart-wyatt-guids.md`. Prevents collisions during parallel authoring.

**Agent:** Flanders  
**TDD:** Nelson writes object-load tests in parallel (WAVE-1d)

#### WAVE-1c: Puzzle Design Specs (Sideshow Bob)

**Goal:** Write detailed puzzle implementation specs for all 7 rooms.

**Files created:** `projects/wyatt-world/puzzles/` — one .md per room

| File | Puzzle | Core Mechanic |
|------|--------|--------------|
| `puzzle-01-studio.md` | Read the welcome sign, press the right button | Careful reading |
| `puzzle-02-feastables.md` | Sort chocolate bars into flavor bins | Categorization + elimination |
| `puzzle-03-money-vault.md` | Calculate money totals, enter safe code | Multiplication + addition |
| `puzzle-04-burger-kitchen.md` | Build burger in recipe order (6 steps) | Sequential instructions |
| `puzzle-05-last-to-leave.md` | Find 3 fake objects by reading descriptions | Close observation |
| `puzzle-06-riddle-arena.md` | Solve 3 riddles, interact with answer objects | Lateral thinking |
| `puzzle-07-grand-prize.md` | Extract 3 numbers from MrBeast's letter | Reading comprehension |

**Each spec includes:**
- Puzzle name and room
- Goal statement (player-facing)
- Solution path: exact verb sequence to solve
- FSM states for puzzle objects (initial → intermediate → solved)
- Wrong-answer responses (funny, not punishing — per CBG § Puzzle Philosophy)
- Hint escalation (1st wrong = gentle, 2nd = stronger, 3rd = nearly gives it away)
- Required objects (cross-reference with Flanders' object list)
- Victory message and prize

**Puzzle constraint: single-room, self-contained.** No item from one room is needed in another. No knowledge from one room unlocks another. Each room is an island.

**Agent:** Sideshow Bob  
**Review:** CBG reviews specs before GATE-1

#### WAVE-1d: Test Scaffolding (Nelson)

**Goal:** Write test files that verify WAVE-1a/1b/1c deliverables load correctly.

**Files created:**

| File | Tests |
|------|-------|
| `test/worlds/wyatt/test-room-load.lua` | All 7 rooms load, have required fields, exits resolve, description present |
| `test/worlds/wyatt/test-object-load.lua` | All objects load, have `on_feel`, GUIDs unique, templates resolve |
| `test/worlds/wyatt/test-hub-connectivity.lua` | From hub, every exit reaches the correct room. Every room has a return exit to hub. |
| `test/worlds/wyatt/test-no-scary-content.lua` | No object has `poison`, `injury`, `damage`, `death`, `dark` in descriptions. No room has `locked` exits. Uses Lua pattern word-boundary matching for variants (C6): `"dark"`, `"darken"`, `"darkened"`, `"shadow"`, `"shadows"`, `"shadowy"`, `"dim"`, `"dimly"`, `"can't see"`. |

**Agent:** Nelson  
**Parallel with:** Moe, Flanders, Bob (different files)

#### WAVE-1e: Level Definition (Flanders)

**Goal:** Create the Wyatt world level file.

**File:** `src/meta/worlds/wyatt-world/levels/level-01.lua`

```lua
return {
    guid = "{new-guid}",
    template = "level",
    number = 1,
    name = "MrBeast's Challenge Arena",
    description = "Seven rooms. Seven challenges. Can you solve them all?",
    intro = {
        title = "WYATT'S WORLD — MrBeast Challenge Arena",
        subtitle = "A Text Adventure for Wyatt",
        narrative = {
            "You walk through a giant golden door.",
            "A huge room with flashing lights stretches out in front of you.",
            "A booming voice says: Welcome, Wyatt! You are Contestant #1!",
        },
        help = "Type 'help' for commands. Try 'look' to see the room!",
    },
    rooms = {
        "beast-studio",
        "feastables-factory",
        "money-vault",
        "beast-burger-kitchen",
        "last-to-leave",
        "riddle-arena",
        "grand-prize-vault",
    },
    start_room = "beast-studio",
    completion = {
        { type = "all_puzzles_solved", message = "You did it! You solved every challenge! MrBeast is SO impressed!" },
    },
    boundaries = {
        entry = { "beast-studio" },
        exit = {},
    },
    restricted_objects = {},
}
```

**Agent:** Flanders  
**Parallel with:** Moe (rooms), Bob (puzzles)

---

### GATE-0: Multi-World Boot

**Binary pass/fail criteria:**

| # | Check | Command | Pass |
|---|-------|---------|------|
| G0-1 | The Manor boots via `--world world-1` | `echo "quit" \| lua src/main.lua --headless --world world-1` | Exits 0, shows Manor intro |
| G0-2 | Wyatt's World boots via `--world wyatt-world` | `echo "quit" \| lua src/main.lua --headless --world wyatt-world` | Exits 0, shows Wyatt intro (or "empty world" gracefully) |
| G0-3 | No `--world` with 1 world auto-selects | Temporarily rename one world file, run without flag | Auto-selects remaining world |
| G0-4 | No `--world` with 2+ worlds gives helpful error | `echo "quit" \| lua src/main.lua --headless` | Prints available world IDs, exits nonzero |
| G0-5 | Full test suite passes | `lua test/run-tests.lua` | ≥269 pass, ≤3 pre-existing failures |
| G0-6 | World loader unit tests pass | `lua test/worlds/test-world-loader.lua` | All pass |
| G0-7 | Multi-world integration tests pass | `lua test/worlds/test-multi-world-boot.lua` | All pass |
| G0-8 | E-rating enforcement verified (B2) | `lua test/worlds/test-e-rating-blocks.lua` | All pass: attack/fight/stab/kill/harm blocked; taste/look/feel/take allowed |
| G0-9 | Wyatt world declares `rating = "E"` (B1) | Check field in `src/meta/worlds/wyatt-world.lua` | `rating == "E"` present |

**Gate reviewers:** Bart (architecture), Nelson (test sign-off)  
**Action on pass:** Commit, push, update board, proceed to WAVE-1.  
**Action on fail:** File GitHub issue, fix, re-gate.

---

### GATE-1: Content Foundation

**Binary pass/fail criteria:**

| # | Check | Pass |
|---|-------|------|
| G1-1 | All 7 rooms load without error | `test/worlds/wyatt/test-room-load.lua` passes |
| G1-2 | All ~70 objects load and register | `test/worlds/wyatt/test-object-load.lua` passes |
| G1-3 | Hub connectivity (6 exits + 6 returns) | `test/worlds/wyatt/test-hub-connectivity.lua` passes |
| G1-4 | No scary content | `test/worlds/wyatt/test-no-scary-content.lua` passes |
| G1-5 | Zero GUID collisions (across BOTH worlds) | Test checks uniqueness across all discovered objects |
| G1-6 | Every object has `on_feel` | Automated check in object-load test |
| G1-7 | Puzzle specs reviewed by CBG | CBG sign-off on all 7 puzzle specs |
| G1-8 | Full test suite passes | `lua test/run-tests.lua` — zero regressions |
| G1-9 | Headless boot of Wyatt's World | `echo "look" \| lua src/main.lua --headless --world wyatt-world` shows studio description |

**Gate reviewers:** Bart (architecture), Nelson (tests), CBG (puzzle specs)  
**Action on pass:** Commit, push, update board, proceed to WAVE-2.

---

### WAVE-2: Integration + Polish (Smithers + Nelson — Parallel)

**Prerequisite:** GATE-1 passes.

#### WAVE-2a: Parser & UI Polish (Smithers)

**Goal:** Ensure the parser handles all Wyatt's World nouns cleanly and error messages are kid-friendly.

**Tasks:**

| Task | Description |
|------|-------------|
| Embedding index update | Add Wyatt object keywords to `src/assets/parser/embedding-index.json` if needed for Tier 2 matching |
| Kid-friendly error messages | Review all `err_not_found`, `err_cant_do` messages. For Wyatt's World, tone should be encouraging ("Hmm, try looking around!" not "I don't understand that.") |
| Verb alias check | Verify all verbs used in puzzles have aliases in the parser (e.g., "sort", "place", "enter", "type") |
| No new parser code expected | The 5-tier pipeline should handle all Wyatt content. If gaps found, minimal patches only. |

**Agent:** Smithers  
**Files touched:** `src/assets/parser/embedding-index.json` (if needed), `src/engine/verbs/init.lua` (if needed)

#### WAVE-2b: Full Testing (Nelson)

**Goal:** LLM-driven puzzle walkthroughs, sensory coverage, reading-level scan.

**Test files:**

| File | Tests |
|------|-------|
| `test/worlds/wyatt/test-puzzle-studio.lua` | Walkthrough: read sign → press correct button → confetti |
| `test/worlds/wyatt/test-puzzle-feastables.lua` | Walkthrough: examine bars → sort into bins → find mystery bar |
| `test/worlds/wyatt/test-puzzle-money-vault.lua` | Walkthrough: examine tables → calculate totals → enter code → safe opens |
| `test/worlds/wyatt/test-puzzle-burger.lua` | Walkthrough: read recipe → place 6 ingredients in order → burger complete |
| `test/worlds/wyatt/test-puzzle-last-to-leave.lua` | Walkthrough: examine objects → find 3 fakes → drop in box |
| `test/worlds/wyatt/test-puzzle-riddle-arena.lua` | Walkthrough: read riddles → examine answer objects → all 3 boards green |
| `test/worlds/wyatt/test-puzzle-grand-prize.lua` | Walkthrough: read letter → extract 3 numbers → enter combo → chest opens |
| `test/worlds/wyatt/test-sensory-coverage.lua` | Every object responds to look, feel, smell, listen, taste |
| `test/worlds/wyatt/test-safety-audit.lua` | No injury, no poison, no darkness, no scary content, taste always safe |

**LLM walkthrough method:**
- All tests use `--headless` mode with deterministic seeds (`math.randomseed(42)`)
- Each test sends exact command sequences and asserts on output
- Wrong-answer paths tested too (verify funny feedback, not punishment)
- Hint escalation tested (1st, 2nd, 3rd wrong attempt)

**Reading-level scan (C12 — explicit in WAVE-2b):**
- Nelson extracts all player-facing text (descriptions, messages, hints)
- Flags any sentence >12 words or any word >3 syllables (unless on CBG's approved list: "chocolate", "scoreboard", "champion", "confetti", "contestant")
- Violations reported to Wayne for fixing in WAVE-3b (C2 — reading-level fix responsibility: Wayne owns fixes, not Nelson)

**Agent:** Nelson  
**Parallel with:** Smithers (different files)

---

### GATE-2: Puzzle Walkthrough + Safety

**Binary pass/fail criteria:**

| # | Check | Pass |
|---|-------|------|
| G2-1 | All 7 puzzle walkthrough tests pass | Each `test-puzzle-*.lua` exits 0 |
| G2-2 | Sensory coverage: all objects respond to all 5 senses | `test-sensory-coverage.lua` passes |
| G2-3 | Safety audit: zero violations | `test-safety-audit.lua` passes |
| G2-4 | Wrong-answer paths produce friendly feedback | Tested in puzzle walkthrough files |
| G2-5 | Hint escalation works (3 levels) | Tested in puzzle walkthrough files |
| G2-6 | Full test suite passes | `lua test/run-tests.lua` — zero regressions |
| G2-7 | Reading-level report generated | Nelson delivers report to Wayne |
| G2-8 | Parser handles all Wyatt nouns | No "I don't understand" for any valid Wyatt keyword |

**Gate reviewers:** Bart (architecture), Nelson (tests), CBG (gameplay feel)  
**Action on pass:** Commit, push, update board, proceed to WAVE-3.

---

### WAVE-3: Review + Deploy (CBG + Wayne + Gil)

**Prerequisite:** GATE-2 passes.

#### WAVE-3a: Creative Review (CBG)

**Tasks:**
- Play through all 7 rooms in headless mode
- Verify MrBeast tone: big, exciting, generous, silly (per CBG design § Tone)
- Verify difficulty progression: ★ → ★★ → ★★★ → ★★★★
- Verify celebration messages are "over-the-top" (not bland)
- Verify wrong-answer messages are funny, not punishing
- Log design debt to `.squad/decisions/inbox/cbg-wyatt-design-debt.md`
- **Design debt tracking (C5):** CBG maintains a running list of non-blocking design issues discovered during review (e.g., "puzzle feels too easy but passes gate", "celebration message is bland but not wrong"). Issues go to `.squad/decisions/inbox/cbg-wyatt-design-debt.md` with severity tags (polish, tweak, rethink). Wayne triages after GATE-3.

**Agent:** CBG

#### WAVE-3b: Reading-Level Audit (Wayne)

**Tasks:**
- Review Nelson's reading-level report
- Read ALL player-facing text (descriptions, messages, hints, signs, letters)
- Flag and fix any text above 3rd-grade level
- Verify no scary, dark, or violent language
- Final approval: "This is appropriate for Wyatt"

**Agent:** Wayne (human review)

#### WAVE-3c: Web Deploy (Gil)

**Tasks:**
- Add world selector to web build (`web/` directory)
- Game start presents: "Choose your world: [The Manor] [Wyatt's World]"
- Wyatt's World loads from `src/meta/worlds/wyatt-world/` paths
- Deploy to GitHub Pages
- Verify browser playthrough works end-to-end

**Agent:** Gil  
**Files touched:** `web/` directory, possibly `web/game-adapter.lua` or equivalent

---

### GATE-3: Ship It

**Binary pass/fail criteria:**

| # | Check | Pass |
|---|-------|------|
| G3-1 | CBG creative sign-off | Written approval in decision inbox |
| G3-2 | Wayne reading-level sign-off | Written approval |
| G3-3 | Web live with world selector | URL loads, both worlds selectable |
| G3-4 | Wyatt's World playable in browser | Full 7-room playthrough in web |
| G3-5 | The Manor still works in browser | Regression check |
| G3-6 | Full test suite passes | `lua test/run-tests.lua` — zero regressions |

**Action on pass:** Tag release. Notify Wayne. Wyatt plays.

---

## 5. Feature Breakdown

### 5.1 Multi-World Engine (WAVE-0 — Bart)

**Module:** `src/engine/world/init.lua`

**Current state:** 5 functions (discover, validate, select, get_starting_room, load). `select()` errors on 2+ worlds.

**New/modified functions:**

| Function | Change |
|----------|--------|
| `select(worlds, world_id)` | **Modified.** Accepts optional `world_id`. If provided, find by `world.id == world_id`. If nil + 1 world → auto-select. If nil + 2+ worlds → return error listing IDs. |
| `get_content_paths(world, meta_root)` | **New.** Returns table: `{ rooms_dir, objects_dir, creatures_dir, levels_dir }`. If `world.content_root` is set, paths derive from `meta_root/content_root/rooms/` etc. If nil, use legacy: `meta_root/rooms/`, `meta_root/objects/`, etc. |
| `load(worlds_dir, list_lua_files, read_file, load_source, world_id)` | **Modified.** Passes `world_id` through to `select()`. |
| E-rating verb dispatch (B1) | **New.** In `src/engine/verbs/init.lua`: check `context.world.rating` before executing restricted verbs. See §4.0.7 for interception point and verb list. |

**Main.lua changes:**

| Section | Change |
|---------|--------|
| CLI parsing | Add `--world <id>` flag |
| World loading | Call `world.load()` with `world_id` from CLI |
| Content paths | Call `world.get_content_paths()` for selected world |
| Object loading | Use content_paths.objects_dir instead of hardcoded |
| Room loading | Use content_paths.rooms_dir instead of hardcoded |
| Creature loading | Use content_paths.creatures_dir instead of hardcoded |
| Level loading | Scan content_paths.levels_dir for level files |
| Context | Set `context.world = selected_world` |

**Backward compatibility guarantee:**
- `lua src/main.lua` with 1 world file → auto-selects (unchanged behavior)
- `lua src/main.lua --world world-1` → selects The Manor explicitly
- All existing tests pass without modification

### 5.2 Room System (WAVE-1a — Moe)

**7 rooms, hub-and-spoke layout.** All follow existing room template.

**Hub room (beast-studio) special features:**
- Scoreboard object: FSM tracks puzzle completion (0/6 → 6/6)
- 6 exits (north, south, east, west, up, down) — all always open
- Welcome sign with puzzle-start instructions
- Confetti cannon that fires on puzzle completions

**Challenge rooms (6 rooms) common pattern:**
- Single return exit to hub
- Puzzle objects with FSM states
- Prize object appears or unlocks on puzzle completion
- No locked doors, no darkness, no danger

### 5.3 Object System (WAVE-1b — Flanders)

**~70 objects across 5 categories.** All use existing templates.

**Templates used:**

| Template | Used For |
|----------|----------|
| `small-item` | Chocolate bars, money stacks, trophy, coupon, medals, recipe card, letter |
| `furniture` | Signs, riddle boards, scoreboard, screens, cameras, speakers, banners, spotlights, conveyor belt, grill, shelves, bookshelf, couch, TV, clock, lamp |
| `container` | Sorting bins, "Found It!" box, burger plate, treasure chest, safe |
| `sheet` | Recipe card, MrBeast letter, labels |

**FSM objects (interactive):**

| Object | States | Transitions |
|--------|--------|------------|
| Big red button | unpressed → pressed | press → pressed (triggers confetti) |
| Colored buttons | unpressed → correct / wrong | press → check answer |
| Sorting bins | empty → partial → sorted | put → check category match |
| Safe keypad | locked → unlocked | enter code → check total |
| Burger plate | empty → step1 → step2 → ... → complete | place ingredient → check order |
| Fake objects | hidden → found | examine → reveal fake |
| Riddle boards | unsolved → solved | interact with answer → green |
| Combo lock dials | each dial: 0–9 | turn → set number |
| Scoreboard | 0/6 → 1/6 → ... → 6/6 | puzzle_solved → increment |
| Treasure chest | locked → unlocked → open | enter combo → unlock → open |

### 5.4 Puzzle System (WAVE-1c — Bob)

**7 puzzles, all single-room, self-contained.** Detailed specs in `projects/wyatt-world/puzzles/`.

**Difficulty progression:**

| # | Room | Skill | Steps | Time |
|---|------|-------|-------|------|
| 1 | Studio | Reading directions | 2–3 | 30s |
| 2 | Feastables | Categorization | 5–6 | 1min |
| 3 | Money Vault | Math + reading | 4–5 | 1–2min |
| 4 | Burger Kitchen | Sequential order | 6–8 | 2min |
| 5 | Last to Leave | Close observation | 6–9 | 2–3min |
| 6 | Riddle Arena | Lateral thinking | 6–9 | 2–3min |
| 7 | Grand Prize | Reading comprehension | 3–4 | 1–2min |

**Failure design (per CBG § Puzzle Philosophy):**
- Wrong answers → funny sound + encouraging message
- No damage, no game over, no penalty
- Hint escalation: wrong #1 = gentle hint, wrong #2 = stronger hint, wrong #3 = nearly gives it away
- Hints are always optional reading (signs, voice messages) — never force-fed

### 5.5 Parser & UI (WAVE-2a — Smithers)

**Expectation: minimal or zero parser changes.** The 5-tier pipeline handles this content.

**Parser verb coverage pre-flight (C3):** Before WAVE-2a starts, Smithers verifies that all verbs used in puzzle solutions are handled by existing verb handlers or aliases. Specific verbs to verify: `sort` (→ existing `put`), `enter [code]` / `type [number]` (→ existing `interact` or FSM input), `place` (→ existing `put` alias). If gaps found, Smithers estimates effort and reports at GATE-1. This could slip WAVE-2a if new handlers are needed (low likelihood).

**Potential work items (assess at GATE-1):**

| Item | Likelihood | Why |
|------|-----------|-----|
| Embedding index update | Medium | New nouns (feastables, scoreboard, confetti) may need Tier 2 entries |
| New verb aliases | Low | "sort", "enter [code]", "type [number]" may need aliases |
| Kid-friendly error messages | Medium | World-specific error tone (encouraging vs. terse) |
| New verb handlers | Very Low | All puzzle mechanics should work with existing verbs (put, press, examine, read) |

---

## 6. Cross-System Integration Points

| Point | Systems | Contract |
|-------|---------|----------|
| **World → Content paths** | Engine (world loader) → Main.lua (content loader) | `get_content_paths()` returns `{ rooms_dir, objects_dir, creatures_dir, levels_dir }` |
| **Room → Objects** | Rooms (Moe) → Objects (Flanders) | Room `instances` reference object GUIDs via `type_id`. GUID list shared before WAVE-1. |
| **Puzzle → FSM states** | Puzzle specs (Bob) → Object definitions (Flanders) | Bob specifies FSM states/transitions; Flanders implements them in object .lua files. |
| **Puzzle → Room** | Puzzle specs (Bob) → Room definitions (Moe) | Bob specifies which objects must be in which room; Moe includes them in room `instances`. |
| **Objects → Parser** | Object keywords (Flanders) → Embedding index (Smithers) | Flanders provides keyword list; Smithers updates embedding index if needed. |
| **World → Web selector** | World definition (Bart) → Web build (Gil) | World ID and name available from world .lua files. Gil reads these for selector UI. |
| **Scoreboard → Puzzle completion** | Hub scoreboard (Flanders) → Puzzle FSM events | When a puzzle is solved, the engine updates the scoreboard FSM. May need a puzzle_solved effect or mutation trigger. |

**Scoreboard integration note:** The scoreboard tracking "puzzles solved" is the trickiest cross-system point. Options:
1. **Mutation approach:** When a room's puzzle is solved (FSM → solved state), the engine fires a mutation on the scoreboard. Requires the puzzle object's FSM to trigger a cross-room mutation — not currently supported for objects in other rooms.
2. **Context counter approach:** Add `context.wyatt_puzzles_solved` counter. Each puzzle completion increments it. Scoreboard reads the counter when examined. Simpler but world-specific engine code (violates Principle 8).
3. **Player state approach (LOCKED — C4):** Track solved puzzles in `player.state.puzzles_completed = {}`. Scoreboard's `on_look` reads from player state. No engine code — just object metadata reading player state. **Decision: This is the confirmed approach.** Bob and Flanders implement during WAVE-1. Scoreboard FSM reads `#player.state.puzzles_completed` to determine display state (0/6 → 6/6).

**FSM State Name Coordination (C10):** Before WAVE-1c starts, Bob and Flanders must agree on FSM state naming conventions. Standardized names: `unpressed`/`pressed`, `locked`/`unlocked`, `empty`/`partial`/`complete`, `unsolved`/`solved`, `correct`/`wrong`. Bob specifies states in puzzle specs; Flanders implements them in object .lua files. Both must use identical names. Coordination point: WAVE-1 kickoff.

**Burger Assembly Ordering (C11):** The Burger Kitchen puzzle requires placing 6 ingredients in a specific order on a plate. The plate is a container with `ordered = true`. The engine validates order on each `put` — if wrong ingredient placed, plate resets (burger falls apart with funny splat sound). Player can retry immediately. Flanders defines the plate FSM (`empty → step1 → step2 → ... → complete`). On wrong order: plate mutates back to `empty` state, all ingredients return to shelves. No permanent penalty.

---

## 7. Nelson Test Scenarios

### 7.1 Smoke Tests (Post-WAVE-0)

```
# S1: Manor still boots
echo "quit" | lua src/main.lua --headless --world world-1
# Expected: Manor intro text, clean exit

# S2: Wyatt world boots (empty)
echo "quit" | lua src/main.lua --headless --world wyatt-world
# Expected: Wyatt intro text (or graceful "no rooms" message), clean exit

# S3: World selector error (no --world, 2 worlds)
echo "quit" | lua src/main.lua --headless
# Expected: Error listing available worlds
```

### 7.2 Room Walkthrough (Post-WAVE-1)

```
# S4: Hub exploration
echo -e "look\nnorth\nlook\nsouth\nlook\neast\nlook\nwest\nlook\nup\nlook\ndown\nlook\nquit" | \
  lua src/main.lua --headless --world wyatt-world
# Expected: Studio described, all 6 rooms reachable and described, all return to studio

# S5: Sensory sweep (one room)
echo -e "look\nfeel button\nsmell button\nlisten button\ntaste button\nquit" | \
  lua src/main.lua --headless --world wyatt-world
# Expected: All 5 senses produce responses, taste is safe
```

### 7.3 Puzzle Walkthroughs (Post-WAVE-2)

**Each puzzle has an exact command sequence. Example for Studio puzzle:**

```
# S6: Studio puzzle
echo -e "look\nlook sign\npress red button\nquit" | \
  lua src/main.lua --headless --world wyatt-world
# Expected: Sign text visible, correct button → confetti celebration
```

**Full puzzle walkthrough sequences defined in Bob's puzzle specs (WAVE-1c).**

### 7.4 Safety Audit (Post-WAVE-2)

```
# S7: No darkness
# Verify no room description contains "dark", "shadow", "dim", "can't see"

# S8: No injury
# Verify no object description contains "injury", "wound", "blood", "pain", "hurt"

# S9: Taste safety
# TASTE every object in every room — none should produce harm/poison/injury

# S10: No locked exits
# Verify every exit in every room has open = true (or no lock state)
```

### 7.5 10-Year-Old Simulation (Post-WAVE-2)

```
# S11: "The Confused Player" (C7 — bounded test script)
# Fixed set of 8 inputs simulating a confused 10-year-old:
echo -e "idk\nhelp\nwhat do i do\ngo home\nhello\npls\nwhere am i\nlook\nquit" | \
  lua src/main.lua --headless --world wyatt-world
# Pass criteria (all must be true):
#   1. Exit code 0 (no crash)
#   2. No "error" or stack trace in output
#   3. At least 3 of 8 inputs produce a response containing "look" or "try" or "help"
#      (parser returns HINT tier or graceful "I don't understand")
#   4. Max runtime: 30 seconds total (bailout if exceeded)
#   5. If ≥3 consecutive "I don't understand that" responses, test still passes
#      (realistic: confused child gives up, which is OK)

# S12: "The Rusher"
# Skip reading signs, try random verbs on random objects
# Expected: Funny feedback, hints, no dead ends

# S13: "The Explorer"
# EXAMINE everything in every room before attempting puzzles
# Expected: Rich descriptions, consistent tone, no missing on_feel
```

---

## 8. TDD Test File Map

| Test File | Covers | Wave |
|-----------|--------|------|
| `test/worlds/test-world-loader.lua` | Extended: select by ID, get_content_paths, multi-world | WAVE-0 |
| `test/worlds/test-multi-world-boot.lua` | Integration: real world files, both worlds boot | WAVE-0 |
| `test/worlds/test-e-rating-blocks.lua` | **New (B2).** E-rating: combat/harm verbs blocked; safe verbs allowed | WAVE-0 |
| `test/worlds/wyatt/test-room-load.lua` | All 7 rooms load, fields present, exits valid | WAVE-1 |
| `test/worlds/wyatt/test-object-load.lua` | All objects load, on_feel present, GUIDs unique | WAVE-1 |
| `test/worlds/wyatt/test-hub-connectivity.lua` | Hub 6-way connectivity, all return exits | WAVE-1 |
| `test/worlds/wyatt/test-no-scary-content.lua` | No dark/scary/violent/poison content (word-boundary matching) | WAVE-1 |
| `test/worlds/wyatt/test-puzzle-studio.lua` | Studio puzzle walkthrough | WAVE-2 |
| `test/worlds/wyatt/test-puzzle-feastables.lua` | Feastables puzzle walkthrough | WAVE-2 |
| `test/worlds/wyatt/test-puzzle-money-vault.lua` | Money Vault puzzle walkthrough | WAVE-2 |
| `test/worlds/wyatt/test-puzzle-burger.lua` | Burger Kitchen puzzle walkthrough | WAVE-2 |
| `test/worlds/wyatt/test-puzzle-last-to-leave.lua` | Last to Leave puzzle walkthrough | WAVE-2 |
| `test/worlds/wyatt/test-puzzle-riddle-arena.lua` | Riddle Arena puzzle walkthrough | WAVE-2 |
| `test/worlds/wyatt/test-puzzle-grand-prize.lua` | Grand Prize puzzle walkthrough | WAVE-2 |
| `test/worlds/wyatt/test-sensory-coverage.lua` | All objects × 5 senses | WAVE-2 |
| `test/worlds/wyatt/test-safety-audit.lua` | No injury, poison, darkness, scary content | WAVE-2 |

**Total new test files:** 16 (was 15; +1 for E-rating enforcement)  
**Test registration:** `test/worlds/wyatt/` added to `test/run-tests.lua` test_dirs in WAVE-0.

---

## 9. Risk Register

| # | Risk | Impact | Probability | Mitigation |
|---|------|--------|-------------|------------|
| R1 | Main.lua refactoring breaks Manor boot | High | Medium | Full regression suite after every change. Headless Manor boot in GATE-0. Git tag before WAVE-0. |
| R2 | Reading-level creep in object/room text | Medium | High | Nelson automated scan (WAVE-2). Wayne final audit (WAVE-3). Approved word list from CBG design. |
| R3 | GUID collisions between worlds | High | Low | GUID pre-assignment (Bart). Automated uniqueness check across both worlds in GATE-1. |
| R4 | Puzzle too hard for a 10-year-old | Medium | Medium | Bob designs for 5th grade max. Nelson LLM walkthroughs simulate a rushed, distracted kid. CBG reviews. |
| R5 | Puzzle too easy (boring) | Low | Low | Difficulty progression ★→★★★★. CBG creative review in WAVE-3. |
| R6 | Scoreboard cross-room tracking | Medium | Medium | Recommend player-state approach (§6). Decision locked before WAVE-1. |
| R7 | Parser doesn't handle kid input patterns | Medium | Low | Nelson "Confused Player" test (S11). Smithers WAVE-2 polish. Existing parser already handles typos (Tier 5). |
| R8 | Web world selector breaks existing Manor web play | High | Low | Gil regression tests Manor in browser. GATE-3 requires both worlds work. |
| R9 | Fengari (browser Lua) incompatibility with new engine code | Medium | Low | Zero external deps. All world loader code uses pure Lua. Test in browser early (WAVE-3c). |
| R10 | Scope creep (>7 rooms, >70 objects) | Low | Medium | CBG owns 7-room constraint. Object count tracked in GATE-1. Board enforces scope. |

---

## 10. Autonomous Execution Protocol

### Walk-Away Pipeline

```
Coordinator spawns WAVE-0 (Bart)
  → GATE-0: pass? → checkpoint, commit, push
  → Coordinator spawns WAVE-1 (Moe + Flanders + Bob + Nelson — parallel)
  → GATE-1: pass? → checkpoint, commit, push
  → Coordinator spawns WAVE-2 (Smithers + Nelson — parallel)
  → GATE-2: pass? → checkpoint, commit, push
  → Coordinator spawns WAVE-3 (CBG + Wayne + Gil)
  → GATE-3: pass? → tag release, notify Wayne
```

### Failure Escalation

| Condition | Action |
|-----------|--------|
| Gate fails 1st time | File GitHub issue, assign fix agent, re-gate |
| Gate fails 2nd time | Escalate to Wayne (1x threshold — first-time project) |
| Agent task fails | Coordinator retries with refined prompt |
| Agent task fails 2nd time | Coordinator attempts manual fix or escalates |

### Checkpoint Protocol

After each wave completes:
1. Update status tracker at top of this plan: `WAVE-N: ✅`
2. Record actual vs. estimated LOC
3. Note any deviations from plan
4. Commit and push
5. Proceed to next wave

### Session Continuity

If a session dies mid-wave:
1. Next session reads status tracker at top of plan
2. Resumes from last completed wave
3. Checks `test/run-tests.lua` for baseline
4. Continues autonomous execution

### Commit Protocol

- Commit after every gate passes
- Commit message format: `feat(wyatt): WAVE-N complete — [summary]`
- Always include: `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`
- Push to `main` after each gate

---

## 11. Documentation Deliverables (Brockman)

| Deliverable | Gate | Location |
|-------------|------|----------|
| Multi-world loader architecture | GATE-0 | `docs/architecture/engine/world-loader.md` |
| Wyatt's World player guide | GATE-2 | `docs/worlds/wyatt-world.md` |
| World creation guide (how to add a new world) | GATE-2 | `docs/guides/creating-a-world.md` |

---

## 12. Decisions Made

1. **Multi-world engine support in WAVE-0** — Wayne decision. Kirk's v1.0 said "no engine changes." Overruled. The engine's `select()` currently errors on 2+ worlds.
2. **`content_root` convention** — Bart decision. Each world .lua file optionally specifies where its content lives. The Manor uses legacy paths (nil). Wyatt's World uses `worlds/wyatt-world`.
3. **`--world <id>` CLI flag** — Bart decision. Required for world selection when 2+ worlds exist. Auto-select when 1 world.
4. **Player-state approach for scoreboard (LOCKED — C4)** — Bart decision, confirmed v2.1. Track solved puzzles in `player.state.puzzles_completed = {}`. Scoreboard reads from player state. No cross-room mutations. No engine-specific code.
5. **All exits always open** — CBG design decision. No locked doors in Wyatt's World. Can't get stuck.
6. **No darkness mechanic** — CBG design decision. All rooms brightly lit. `casts_light` irrelevant.
7. **Taste always safe** — CBG design decision. No poison. No harmful taste. Silly and fun.
8. **Hub-and-spoke layout** — CBG design decision. Studio hub + 6 challenge rooms. Can't get lost.
9. **GUID pre-assignment before WAVE-1 (B3)** — Bart decision. ~80 GUIDs reserved in `bart-wyatt-guids.md`. Prevents collisions during parallel authoring.
10. **E-rating two-layer enforcement (B1)** — Wayne directive + Bart implementation. World declares `rating = "E"`. Engine hard-blocks combat/harm verbs at dispatch. Design soft-enforces no-poison/no-scary via content choices. See §4.0.7.
11. **E-rating test gate (B2)** — Nelson requirement. `test/worlds/test-e-rating-blocks.lua` verifies enforcement before GATE-0 passes.
12. **Reading-level fix responsibility (C2)** — Wayne owns text fixes in WAVE-3b. Nelson flags violations in WAVE-2b; Wayne edits.

---

## 13. References

| Topic | Location |
|-------|----------|
| CBG's creative design | `projects/wyatt-world/design.md` |
| Frink's MrBeast research | `projects/wyatt-world/research-mrbeast.md` |
| Project board | `projects/wyatt-world/board.md` |
| Core object principles | `docs/architecture/objects/core-principles.md` |
| Deep nesting syntax | `docs/architecture/objects/deep-nesting-syntax.md` |
| Object design patterns | `docs/design/object-design-patterns.md` |
| World loader (existing) | `src/engine/world/init.lua` |
| World concept decision | `.squad/decisions.md` — D-WORLDS-CONCEPT |
| World loader shipped | `.squad/decisions.md` — D-WORLDS-LOADER-WAVE0 |

---

**Plan Version:** 2.1  
**Author:** Bart (Architect)  
**Last Updated:** 2026-08-23  
**v2.1 Review Fixes:** B1 (E-rating field), B2 (E-rating test gate), B3 (GUID pre-assignment), C1–C12 (concerns from CBG/Nelson/Smithers/Moe/Bob/Flanders)
