# Worlds System — Implementation Plan (Phase 1)

**Author:** Bart (Architect)  
**Date:** 2026-08-21  
**Status:** PLAN ONLY — Not yet executed  
**Requested By:** Wayne "Effe" Berry  
**Governs:** World-driven engine boot (Phase 1 — single-world support)  
**Decision:** D-WORLDS-CONCEPT

---

## Quick Reference

| Wave | Name | Parallel Tracks | Gate | Key Deliverable |
|------|------|-----------------|------|-----------------|
| **WAVE-0** | Pre-Flight (Infrastructure) | 1 track | — | Directory creation, test runner registration |
| **WAVE-1** | World Loader + Data (Foundation) | 3 tracks | GATE-1 | `engine/world/init.lua`, world template, `the-manor.lua`, tests |
| **WAVE-2** | Boot Integration (Engine Wiring) | 2 tracks | GATE-2 | `main.lua` world-driven boot, integration tests |
| **WAVE-3** | Documentation + Verification (Ship Gate) | 3 tracks | GATE-3 | Docs, LLM walkthrough, meta-lint world awareness |

**Total new files:** ~8 (code + tests) + 3 doc files  
**Total modified files:** ~2 (`main.lua`, `test/run-tests.lua`)  
**Estimated scope:** 4 waves (WAVE-0 through WAVE-3), 3 gates, ~400 lines code + ~300 lines tests + ~3 architecture/design docs

---

## Section 1: Executive Summary

We're introducing **Worlds** as the top-level container in the content hierarchy: **World → Level → Room → Object/Creature/Puzzle**. A World is a thematically unified container that defines the creative atmosphere, aesthetic constraints, and the set of Levels it contains. World 1 is "The Manor" — gothic domestic horror, late medieval.

**Phase 1 scope:** Single-world auto-select. The engine discovers all `.lua` files in `src/meta/worlds/`, loads them like rooms (lazy-load, sandboxed), and boots into the single World. With one World, there's no selection UI — the engine auto-selects. Zero Worlds = FATAL error, not silent degradation.

**Key architectural decision:** A new module `src/engine/world/init.lua` encapsulates all world discovery and loading logic. It follows the dependency injection pattern (zero `require()` calls — loader, read_file, and templates are passed as parameters), matching the isolation pattern established in `engine/loader`. The World is metadata on `context.world`, NOT a game entity — it is NOT registered in the object registry.

**Why this matters:** The existing boot sequence in `main.lua` hardcodes `level-01.lua` and `start-room = "start-room"`. The worlds system makes boot data-driven: the World declares which Level to start, which declares which room to spawn in. This enables multi-world support (Phase 2) without engine changes.

**Walk-away capability:** Each wave is a batch of parallel work. Coordinator spawns agents, collects results, runs gate tests. Pass → next wave. Fail → file issue, assign fix, re-gate. Wayne doesn't need to be in the loop unless a gate fails.

---

## Section 2: Dependency Graph

```
WAVE-0: Pre-Flight (Infrastructure)
└── [Bart]     Create src/meta/worlds/ and src/meta/worlds/themes/ directories
    [Bart]     Register test/worlds/ in test/run-tests.lua
        │
        ▼  ── (no gate — directory creation + 1-line test runner change) ──
        │
WAVE-1: World Loader + Data (Foundation)
├── [Bart]     engine/world/init.lua ─────────────────┐
│              (discover, load, validate, select)      │
├── [Flanders] src/meta/templates/world.lua ──────────┤ (parallel, no file overlap)
│              src/meta/worlds/the-manor.lua           │
└── [Nelson]   test/worlds/test-world-loader.lua ─────┘
               test/worlds/test-world-definition.lua
        │
        ▼  ── GATE-1 (world loads, template validates, loader discovers + selects) ──
        │
WAVE-2: Boot Integration (Engine Wiring)
├── [Bart]     main.lua world-driven boot ────────────┐
│              (replace hardcoded level-01 path)       │ (parallel, no file overlap)
└── [Nelson]   test/worlds/test-world-boot.lua ───────┘
               test/integration/test-world-integration.lua
        │
        ▼  ── GATE-2 (game boots via world, existing gameplay unaffected) ──
        │
WAVE-3: Documentation + Verification (Ship Gate)
├── [Brockman] docs/architecture/engine/world-system.md ──┐
│              docs/design/worlds.md (update)              │
│              docs/architecture/objects/world-template.md  │ (parallel, no file overlap)
├── [Nelson]   LLM walkthrough (headless) ────────────────┤
└── [Bart]     Meta-lint world awareness (optional) ──────┘
        │
        ▼  ── GATE-3 (Worlds Phase 1 COMPLETE — docs + LLM walkthrough) ──
```

**Key constraint:** No two agents in any wave touch the same file. File ownership is explicit in Section 3.

---

## Section 3: Implementation Waves

### WAVE-0: Pre-Flight (Infrastructure)

**Goal:** Create directories and register test paths before any files are created.

| Task | Agent | Files Modified/Created | Scope |
|------|-------|------------------------|-------|
| Create `src/meta/worlds/` directory | Bart | **CREATE** directory | Tiny |
| Create `src/meta/worlds/themes/` directory | Bart | **CREATE** directory | Tiny |
| Register `test/worlds/` in test runner | Bart | **MODIFY** `test/run-tests.lua` | Tiny (1 line) |

**Bart instructions:**

1. Create directories: `src/meta/worlds/` and `src/meta/worlds/themes/`
2. Add one entry to the `test_dirs` table in `test/run-tests.lua`:
```lua
repo_root .. SEP .. "test" .. SEP .. "worlds",
```

**Verification:** Run `lua test/run-tests.lua` — must pass with zero regressions. The new directory doesn't exist yet for tests, so the runner finds no test files in it (no error).

---

### WAVE-1: World Loader + Data (Foundation)

**Goal:** The world loader module exists, discovers world files, loads them via the sandbox, and validates required fields. World 1 ("The Manor") and its template exist and load cleanly.

**Depends on:** WAVE-0 complete (directories exist, test runner updated)

| Task | Agent | Files Created/Modified | TDD Test File | Scope |
|------|-------|------------------------|---------------|-------|
| World loader module | Bart | **CREATE** `src/engine/world/init.lua` | `test/worlds/test-world-loader.lua` (Nelson) | Medium |
| World template | Flanders | **CREATE** `src/meta/templates/world.lua` | `test/worlds/test-world-definition.lua` (Nelson) | Small |
| The Manor world definition | Flanders | **CREATE** `src/meta/worlds/the-manor.lua` | (same test file) | Small |
| World test suite | Nelson | **CREATE** `test/worlds/test-world-loader.lua`, `test/worlds/test-world-definition.lua` | — | Medium |

**File ownership (no overlap):**
- Bart: `src/engine/world/init.lua`
- Flanders: `src/meta/templates/world.lua`, `src/meta/worlds/the-manor.lua`
- Nelson: `test/worlds/test-world-loader.lua`, `test/worlds/test-world-definition.lua`

**Bart instructions — engine/world/init.lua (~150–200 lines):**

The module must be generic (Principle 8). It does NOT know about "The Manor". It knows about:
- Tables with `template == "world"`
- A `levels` table listing level references
- A `starting_room` field (game boot spawn)
- A `theme` table (creative brief metadata — not engine-consumed in Phase 1)

**Dependency injection pattern (CRITICAL):** Zero `require()` calls. All dependencies are passed as parameters:
```lua
local M = {}

function M.discover(worlds_dir, list_lua_files, read_file, load_source)
    -- Discover all .lua files in worlds_dir
    -- Load each via sandboxed load_source
    -- Return array of world tables
end

function M.select(worlds)
    -- Single-world: return worlds[1]
    -- Zero worlds: return nil, "FATAL: no worlds found"
    -- Multi-world (Phase 2): return nil, "world selection not implemented"
end

function M.validate(world)
    -- Required fields: guid, template == "world", id, name, levels, starting_room
    -- Returns true or false, error_message
end

function M.load(worlds_dir, list_lua_files, read_file, load_source, resolve_template, templates)
    -- Orchestrator: discover → validate each → select
    -- Returns selected world or nil, error
end

return M
```

**Design decisions embedded in the module:**
1. **No hardcoded fallback** — zero worlds = FATAL error, not silent degradation. Fail fast.
2. **World NOT registered in object registry** — it's metadata on `context.world`, not a game entity.
3. **One-directional relationship** — World → Level (references level IDs). No `world_id` on levels.
4. **`list_lua_files` duplicated** rather than extracting a shared utility — acceptable for Phase 1 scope; D-ENGINE-REFACTORING-WAVE2 handles extraction later.
5. **Level path resolution uses `level_dir` parameter**, not raw `file` field — avoids cross-platform path issues.

**Flanders instructions — world.lua template:**

```lua
return {
    guid = "{generate-fresh-windows-guid}",
    template = "world",
    id = "world",
    name = "World",
    description = "",

    -- Levels contained in this world (ordered by progression)
    levels = {},

    -- Game boot: player spawns in this room
    starting_room = "",

    -- Creative brief (consumed by creators, not engine in Phase 1)
    theme = {
        pitch = "",
        era = "",
        atmosphere = "",
        aesthetic = {
            materials = {},
            forbidden = {},
        },
        tone = "",
        constraints = {},
    },
}
```

Required fields: `guid`, `template = "world"`, `id`, `name`, `levels` (non-empty array), `starting_room` (string, must resolve to a room ID).

**Flanders instructions — the-manor.lua:**

```lua
return {
    guid = "{generate-fresh-windows-guid}",
    template = "world",
    id = "the-manor",
    name = "The Manor",
    description = "A crumbling medieval manor house, haunted by its own history. "
               .. "Stone walls weep with damp, corridors twist into darkness, "
               .. "and every locked door hides another secret.",

    levels = {
        { id = "level-01", file = "level-01.lua" },
    },

    starting_room = "start-room",

    theme = {
        pitch = "Gothic domestic horror — you wake trapped in a medieval manor at 2 AM.",
        era = "Late medieval (13th–14th century)",
        atmosphere = "Oppressive darkness, damp stone, creaking wood, unseen things.",
        aesthetic = {
            materials = { "stone", "wood", "iron", "wax", "wool", "linen", "clay", "brass" },
            forbidden = { "plastic", "electricity", "glass (modern)", "rubber" },
        },
        tone = "Dread through texture — every object feels wrong in the dark.",
        constraints = {
            "No modern materials (post-1400)",
            "Light is scarce and consumable",
            "Sound carries — actions have consequences",
            "Smell and touch are primary senses",
        },
    },
}
```

**Key rules for the-manor.lua:**
- `starting_room = "start-room"` must match an actual room ID in level-01's room list
- `levels` references level-01 by ID — the engine resolves the file path via `level_dir` parameter
- Theme is metadata for creators; the engine does NOT enforce theme constraints in Phase 1

**Nelson instructions — test scaffolding:**

*test-world-loader.lua (~80 lines):*
1. Module loads without error: `require("engine.world")`
2. `discover()` with mock `list_lua_files` returning 1 file: returns 1 world table
3. `discover()` with mock returning 0 files: returns empty array
4. `select()` with 1 world: returns that world
5. `select()` with 0 worlds: returns nil + FATAL error message
6. `select()` with 2 worlds: returns nil + "not implemented" error (Phase 2)
7. `validate()` with valid world: returns true
8. `validate()` missing `starting_room`: returns false + error
9. `validate()` missing `levels`: returns false + error
10. `validate()` empty `levels`: returns false + error
11. `load()` orchestrator: full flow with mock dependencies, returns world

*test-world-definition.lua (~50 lines):*
1. World template loads via dofile: required fields exist
2. The Manor loads via dofile: `id == "the-manor"`, `name == "The Manor"`
3. The Manor has non-empty `levels` array
4. The Manor `starting_room == "start-room"`
5. The Manor has `theme` table with `pitch`, `era`, `atmosphere`
6. The Manor `levels[1].id == "level-01"`

---

### WAVE-2: Boot Integration (Engine Wiring)

**Goal:** `main.lua` uses the world loader to determine which level to load and which room to start in, replacing the hardcoded `level-01.lua` and `start-room` references.

**Depends on:** GATE-1 pass (world loader works, The Manor validates)

| Task | Agent | Files Created/Modified | TDD Test File | Scope |
|------|-------|------------------------|---------------|-------|
| World-driven boot in main.lua | Bart | **MODIFY** `src/main.lua` | `test/worlds/test-world-boot.lua` (Nelson) | Medium |
| Boot integration tests | Nelson | **CREATE** `test/worlds/test-world-boot.lua`, `test/integration/test-world-integration.lua` | — | Medium |

**File ownership (no overlap):**
- Bart: `src/main.lua`
- Nelson: `test/worlds/test-world-boot.lua`, `test/integration/test-world-integration.lua`

**Bart instructions — main.lua world-driven boot:**

The changes are additive — the existing boot logic is wrapped, not rewritten.

**Before (current hardcoded boot):**
```lua
-- Load level data
local level_source = read_file(level_dir .. SEP .. "level-01.lua")
...
local start_room_id = start_room_override or "start-room"
```

**After (world-driven boot):**
```lua
-- Load world
local world_mod = require("engine.world")
local worlds_dir = meta_root .. SEP .. "worlds"
local world, world_err = world_mod.load(
    worlds_dir, list_lua_files, read_file,
    loader.load_source, loader.resolve_template, templates
)
if not world then
    io.stderr:write("FATAL: " .. tostring(world_err) .. "\n")
    os.exit(1)
end

-- Resolve level from world
local level_ref = world.levels[1]
local level_source = read_file(level_dir .. SEP .. level_ref.file)
...

-- Use world's starting_room (unless --room override)
local start_room_id = start_room_override or world.starting_room
```

**Critical behavior preservation:**
1. `--room` / `--start-room` CLI flag STILL overrides the world's `starting_room`
2. `--list-rooms` STILL works (rooms loaded after world selects the level)
3. All existing gameplay is UNCHANGED — same level, same rooms, same objects
4. The only behavioral difference: boot path is data-driven instead of hardcoded

**What `context.world` contains (set before game loop starts):**
```lua
context.world = world  -- Full world table (id, name, theme, levels, starting_room)
```
The game loop and verb handlers can read `context.world` but Phase 1 does NOT use it for any gameplay logic. It's available for future features (theme enforcement, multi-level transitions).

**Nelson instructions — boot tests:**

*test-world-boot.lua (~60 lines):*
1. Game boots successfully with The Manor world: `echo "quit" | lua src/main.lua --headless` exits cleanly
2. Starting room is "start-room" (from world, not hardcoded)
3. `--room cellar` still overrides world's starting_room
4. `--list-rooms` still works and shows all rooms
5. Level intro text still displays (from level-01, which world references)

*test-world-integration.lua (~40 lines, headless):*
1. Full boot + first command: `echo "feel" | lua src/main.lua --headless` produces sensory output
2. Multiple rooms work: `echo "feel bed\nopen nightstand\ntake matchbox" | lua src/main.lua --headless`
3. No regressions: existing test suite passes after main.lua changes

---

### WAVE-3: Documentation + Verification (Ship Gate)

**Goal:** Architecture docs describe the world system. LLM walkthrough confirms gameplay unchanged. Meta-lint is optionally made aware of the new `src/meta/worlds/` directory.

**Depends on:** GATE-2 pass (world-driven boot works, zero regressions)

| Task | Agent | Files Created/Modified | Scope |
|------|-------|------------------------|-------|
| World system architecture doc | Brockman | **CREATE** `docs/architecture/engine/world-system.md` | Medium |
| Worlds design doc (update) | Brockman | **UPDATE** `docs/design/worlds.md` | Small |
| World template doc | Brockman | **CREATE** `docs/architecture/objects/world-template.md` | Small |
| LLM walkthrough | Nelson | (no files created — headless verification) | Medium |
| Meta-lint world awareness | Bart | **MODIFY** `scripts/meta-lint/lint.py` (optional, small) | Small |

**File ownership (no overlap):**
- Brockman: all docs files
- Nelson: test execution only (no file creation)
- Bart: `scripts/meta-lint/lint.py` (optional)

**Brockman instructions — documentation (3 files):**

- `docs/architecture/engine/world-system.md`: Document the world loader module (`src/engine/world/init.lua`). Cover: dependency injection pattern, discover/validate/select/load API, zero-world FATAL behavior, single-world auto-select, context.world placement. Reference D-WORLDS-CONCEPT.
- `docs/design/worlds.md` (update existing): Add implementation status section noting Phase 1 ships single-world support. Reference the engine module and template. Note multi-world selection is Phase 2.
- `docs/architecture/objects/world-template.md`: Document the world template format (`src/meta/templates/world.lua`). Cover: required fields, theme table structure, levels array format, starting_room semantics, relationship to level template.

**Nelson instructions — LLM walkthrough:**

```bash
# Scenario A: Normal boot (world-driven)
echo "feel\nlook\nsmell" | lua src/main.lua --headless
# Expected: same output as before worlds system — darkness, linen, no change

# Scenario B: Room override still works
echo "look" | lua src/main.lua --headless --room cellar
# Expected: player starts in cellar, not start-room

# Scenario C: Full Level 1 walkthrough still works
echo "feel bed\nfeel nightstand\nopen nightstand\ntake matchbox\nopen matchbox\ntake match\nlight match\nlight candle\nlook" | lua src/main.lua --headless
# Expected: same gameplay sequence as before — light candle, see room
```

**Rule: No phase ships without its docs.** GATE-3 requires all 3 doc files to exist.

**Bart instructions — meta-lint (optional):**

If time permits, add `"world"` to the `_detect_kind()` function's path mapping so the linter recognizes `src/meta/worlds/*.lua` files. This enables future WORLD-* validation rules but is NOT required for Phase 1 ship.

---

## Section 4: Testing Gates

### GATE-1: World Foundation Validation

**After:** WAVE-1 completes  
**Tests that must pass:**
- `lua test/worlds/test-world-loader.lua` — all 11 assertions green
- `lua test/worlds/test-world-definition.lua` — all 6 assertions green
- `lua test/run-tests.lua` — zero regressions in existing test files

**Pass/fail:** ALL tests pass, zero regressions. Binary.  
**Reviewer:** Bart (architecture), Marge (test sign-off)  
**Action on fail:** File issue, assign to Bart (loader fix), Flanders (data fix), or Nelson (test fix), re-gate.

**On pass:** `git add -A && git commit -m "GATE-1: World Foundation — loader + template + The Manor validated" && git push`

---

### GATE-2: Boot Integration Validation

**After:** WAVE-2 completes  
**Tests that must pass:**
- `lua test/worlds/test-world-boot.lua` — all 5 assertions green
- `lua test/integration/test-world-integration.lua` — all 3 assertions green
- `lua test/run-tests.lua` — zero regressions (ALL prior tests still pass)

**Specific assertions:**
- Game boots via world discovery (not hardcoded level path)
- `--room` CLI override still works
- `--list-rooms` still works
- Level intro text still displays
- Existing gameplay unaffected (feel/look/take all work as before)

**Pass/fail:** ALL tests pass, zero regressions. Binary.  
**Reviewer:** Bart (architecture), Marge (test sign-off)

**On pass:** `git add -A && git commit -m "GATE-2: World Boot Integration — main.lua uses world-driven boot" && git push`

---

### GATE-3: Worlds Phase 1 Complete (Ship Gate)

**After:** WAVE-3 completes  
**Tests that must pass:**
- All tests from GATE-1 and GATE-2 still pass
- `lua test/run-tests.lua` — zero regressions
- LLM walkthrough Scenarios A, B, C all produce expected output

**Documentation deliverables that must exist:**
- `docs/architecture/engine/world-system.md`
- `docs/design/worlds.md` (updated with implementation status)
- `docs/architecture/objects/world-template.md`

**Pass/fail:** ALL tests pass. LLM walkthrough completes all scenarios. All 3 docs exist. Zero regressions. Binary.  
**Reviewer:** Bart (architecture), Nelson (LLM execution + gate signer), Marge (test sign-off)

**On pass:** `git add -A && git commit -m "GATE-3: Worlds Phase 1 complete — docs + LLM walkthrough" && git push`

---

## Section 5: Feature Breakdown — World Loader Module

### `src/engine/world/init.lua` — Public API

| Function | Purpose | Parameters | Returns |
|----------|---------|------------|---------|
| `M.discover(worlds_dir, list_lua_files, read_file, load_source)` | Find and load all world .lua files | Injected I/O functions | `worlds[]` |
| `M.select(worlds)` | Pick the active world (auto-select for single world) | Array of world tables | `world` or `nil, err` |
| `M.validate(world)` | Check required fields | Single world table | `true` or `false, err` |
| `M.load(worlds_dir, list_lua_files, read_file, load_source, resolve_template, templates)` | Full orchestrator | All injected deps | `world` or `nil, err` |

### Validation Rules

| Field | Rule | Error on violation |
|-------|------|--------------------|
| `guid` | Must be non-empty string | "world missing guid" |
| `template` | Must equal `"world"` | "not a world template" |
| `id` | Must be non-empty string | "world missing id" |
| `name` | Must be non-empty string | "world missing name" |
| `levels` | Must be non-empty array | "world has no levels" |
| `levels[n].id` | Each level must have an `id` | "level entry missing id" |
| `starting_room` | Must be non-empty string | "world missing starting_room" |

### Error Handling

- **Zero worlds discovered:** `FATAL: no worlds found in {worlds_dir}` → `os.exit(1)` in main.lua
- **Multiple worlds discovered (Phase 1):** `FATAL: multiple worlds found — world selection not implemented` → `os.exit(1)`
- **World validation fails:** `FATAL: world '{id}' validation failed: {reason}` → `os.exit(1)`
- **All errors are FATAL.** No silent fallback. No degraded mode. The game cannot boot without a valid world.

---

## Section 6: Cross-System Integration Points

### What World Loader Consumes (Existing Modules)

| Interface | Provider | Usage |
|-----------|----------|-------|
| `loader.load_source(source)` | `engine/loader/init.lua` | Sandbox-loads world .lua file content |
| `loader.resolve_template(def, templates)` | `engine/loader/init.lua` | Resolves world against world template |
| `read_file(path)` | `main.lua` (local function) | Reads .lua file from disk |
| `list_lua_files(dir)` | `main.lua` (local function) | Lists .lua files in a directory |

### What World Loader Exposes (for main.lua)

| Interface | Consumer | Usage |
|-----------|----------|-------|
| `world.starting_room` | `main.lua` boot sequence | Determines player spawn room |
| `world.levels[1]` | `main.lua` level loading | Determines which level file to load |
| `context.world` | Game loop, verb handlers | World metadata available at runtime |
| `world.theme` | Future: creators, linter | Theme constraints (not enforced in Phase 1) |

### Relationship to Existing Level System

The world system **wraps** the existing level system, it does NOT replace it:

```
BEFORE:  main.lua → hardcoded "level-01.lua" → hardcoded "start-room"
AFTER:   main.lua → world.load() → world.levels[1] → level-01.lua → world.starting_room
```

- `level-01.lua` is UNCHANGED — same format, same fields, same behavior
- Levels still have their own `start_room` (for intra-level respawn); the world's `starting_room` is for initial game boot only
- The world's `levels` array provides ordering and grouping; levels themselves don't know which world they belong to (one-directional relationship, per D-WORLDS-CONCEPT)

---

## Section 7: Nelson LLM Test Scenarios

**Determinism rule:** All LLM walkthroughs use `--headless` mode.

### GATE-1 Scenario: Data Validation
```
# No LLM walkthrough — unit tests only.
# Validate: world template loads, The Manor loads, world loader discovers + selects.
```

### GATE-2 Scenario: Boot Integration
```
# Smoke test only — verify game boots and responds to first command.
echo "feel" | lua src/main.lua --headless
# Expected: sensory output (unchanged from pre-worlds behavior)
```

### GATE-3 Scenarios: Full Verification

**Scenario A: "Normal World-Driven Boot"**
```bash
echo "feel\nlook\nsmell" | lua src/main.lua --headless
```
Expected: darkness, linen feel, no visible change from pre-worlds output.

**Scenario B: "Room Override Preserved"**
```bash
echo "look" | lua src/main.lua --headless --room cellar
```
Expected: player starts in cellar, not start-room.

**Scenario C: "Full Level 1 Critical Path"**
```bash
echo "feel bed\nfeel nightstand\nopen nightstand\ntake matchbox\nopen matchbox\ntake match\nlight match\nlight candle\nlook" | lua src/main.lua --headless
```
Expected: same gameplay as pre-worlds — light candle, see room contents.

---

## Section 8: TDD Test File Map

| Engine Module | Test File | Written In | Key Assertions |
|---------------|-----------|-----------|----------------|
| `src/engine/world/init.lua` | `test/worlds/test-world-loader.lua` | WAVE-1 | 11 tests: discover, select, validate, load orchestrator |
| `src/meta/templates/world.lua` + `src/meta/worlds/the-manor.lua` | `test/worlds/test-world-definition.lua` | WAVE-1 | 6 tests: template loads, manor loads, fields validate |
| `src/main.lua` (world boot) | `test/worlds/test-world-boot.lua` | WAVE-2 | 5 tests: boot via world, CLI override, list-rooms, intro text |
| Full integration | `test/integration/test-world-integration.lua` | WAVE-2 | 3 tests: boot + command, multi-room, no regressions |

### Test Runner Integration

**WAVE-0 (pre-flight):** Bart adds the directory to `test/run-tests.lua` before any test files exist:
```lua
repo_root .. SEP .. "test" .. SEP .. "worlds",
```

---

## Section 9: Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| **World loader breaks existing boot** | Low | High | WAVE-2 wraps existing logic, doesn't rewrite. All existing tests must pass. |
| **`list_lua_files` platform differences** | Medium | Medium | Duplicated from main.lua (same implementation). Same platform handling. |
| **Template resolution for world type** | Low | Low | Uses existing `loader.resolve_template()` — same code path as objects/rooms. |
| **Multi-world accidentally supported** | Low | Medium | `select()` explicitly rejects >1 world with clear error. No silent behavior. |
| **main.lua edit conflicts with other branches** | Medium | Medium | Changes are localized to boot section (~15 lines changed). Git merge should handle. |
| **Theme table format changes before Phase 2** | Medium | Low | Theme is metadata-only in Phase 1. Format changes don't break engine. |

---

## Section 10: Autonomous Execution Protocol

### Coordinator Execution Loop

```
FOR each WAVE in [WAVE-0, WAVE-1, WAVE-2, WAVE-3]:

  1. SPAWN parallel agents per wave assignment table
     - Each agent gets: task description, exact files, TDD requirements
     - No two agents touch the same file
  
  2. COLLECT results from all agents
     - Check: all files created/modified as specified
     - Check: no unintended file changes (git diff --stat)
  
  3. RUN gate tests:
     lua test/run-tests.lua
     + wave-specific test files
     + LLM walkthrough (GATE-3 only)
     + doc existence check (GATE-3 only)
  
  4. EVALUATE gate:
     IF all tests pass AND zero regressions AND docs exist (where required):
       COMMIT: git add -A && git commit -m "GATE-N: {description}" && git push
       → PROCEED to next wave
     
     IF any test fails:
       FILE issue with failure details
       ASSIGN fix to the agent who owns the failing file
       RE-RUN gate after fix
       IF gate fails 1x: ESCALATE to Wayne
       (Phase 1 policy — first worlds implementation.)
```

### Commit Pattern

One commit per gate, message format:
```
GATE-N: Worlds {layer name}

- {summary of what was created/modified}
- Tests: {count} new, 0 regressions

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

### Wayne Check-In Points

Wayne only needs to be involved at:
1. **GATE-3** (Worlds Phase 1 complete) — verify game boots correctly
2. **Any escalation** from the 1x-failure rule

Everything else runs autonomously.

---

## Section 11: Gate Failure Protocol

### Failure Handling Procedure

**Step 1: First failure**
- Coordinator files a GitHub issue with: which gate failed, which test(s) failed, full error output, which agent's file is implicated
- Assign fix to the appropriate agent
- Re-gate: run ONLY the failed test items
- **Escalate to Wayne** with diagnostic summary (Phase 1 policy — 1x threshold)

**Step 2: Second failure (same test)**
- Escalate immediately to Wayne with full diagnostic
- Wayne decides: retry with different agent, redesign approach, or defer

### Lockout Policy

If an agent's code failed a gate twice, that agent is locked out of fixing that specific issue. A fresh agent takes over.

---

## Section 12: Documentation Deliverables

| Document | Author | Gate | Purpose |
|----------|--------|------|---------|
| `docs/architecture/engine/world-system.md` | Brockman | GATE-3 | World loader architecture, DI pattern, API reference |
| `docs/design/worlds.md` | Brockman | GATE-3 | Updated design doc with Phase 1 implementation status |
| `docs/architecture/objects/world-template.md` | Brockman | GATE-3 | World template format specification |

**Rule: No phase ships without its docs.** GATE-3 requires all 3 documents.

---

## Phase 2 Roadmap (Not in Scope)

Phase 2 will add:
- Multi-world selection (UI or CLI flag)
- World-specific settings (time scale, weather, ambient sound)
- Theme enforcement in meta-lint (WORLD-* rules)
- Inter-world portals (if multiverse design proceeds)
- `context.world.theme` consumption by engine for material validation

Phase 2 requires NO changes to Phase 1 modules — the `select()` function's multi-world branch is the only code that changes.
