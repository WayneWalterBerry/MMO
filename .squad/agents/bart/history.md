# Bart — History (Summarized)

## Project Context

- **Project:** MMO — A text adventure MMO with multiverse architecture
- **Owner:** Wayne "Effe" Berry
- **Stack:** Lua (engine + meta-code), cloud persistence
- **Key Concepts:** Each player gets their own universe instance with self-modifying meta-code. Objects are rewritten (not flagged) when state changes. Code IS the state.

## Core Context (Summarized)

**Role:** Architect — engine design, verb systems, FSM mechanics, mutation patterns, puzzle systems

**Major Systems Built:**
- **Engine Foundation:** Loader (sandboxed execution), Registry (object storage), Mutation (via loadstring), Loop (REPL)
- **Verb System:** 31 verbs across 4 categories (sensory, inventory, object interaction, meta); tool resolution (capabilities-based, supports virtual tools like blood)
- **FSM Architecture:** Inline state machines for all objects; timer tracking (two-phase tick), room pause/resume, cyclic states
- **Containment:** 4-layer validation (identity, size, capacity, categories)
- **Composite Objects:** Single-file pattern with detachable parts; two-hand carry system
- **Skill System:** Binary table lookup; skill gates; crafting recipes on materials
- **GOAP Planner:** Tier 3 backward-chaining; prerequisite resolution; in-place container handling
- **Terminal UI:** Split-screen (status bar + scrollable output + input); pure Lua; ANSI support
- **Multi-Room Engine:** All rooms loaded at startup; shared registry; per-room FSM ticking

**Architectural Patterns (Foundational):**
- Objects use FSM states with sensory text; mutation is code-level only
- `engine/mutation/` is ONLY code that hot-swaps objects
- Tool resolution: capabilities (not tool IDs)
- Sensory verbs work in darkness
- Skills: double-dispatch gating (skill gate + tool gate)

**Design Philosophy:** No special-case objects. Everything expressible through .lua metadata (FSM, timers, prerequisites). Engine stays generic; objects own their behavior.

**Decisions Authored:** 45+ (D-14 through D-CLOCK001, including architecture, engines, objects, spatial, UI, GOAP)

## Archives

- `history-archive-2026-03-21.md` — Early sessions
- `history-archive-2026-03-22.md` — Mid sessions
- `history-archive-2026-03-20T22-40Z-bart.md` — Full archive (2026-03-18 to 2026-03-20T22:40Z): engine foundation, verb system, parser pipeline, SLEEP, wearables, FSM engine, composite objects, spatial system, multi-room engine, GOAP Tier 3, terminal UI, timed events, 32+ bug fixes across 7 passes

## Recent Updates

### Session: Object Lua Batch + Bugfix Pass-007 (2026-03-20T22:00Z)
**Status:** ✅ COMPLETE
**Outcome:** 4 object .lua files shipped + 2 minor bugs fixed

**Object Batch Deliverables:**
1. `src/meta/objects/candle-holder.lua` — composite object, detachable candle (parts pattern)
2. `src/meta/objects/wall-clock.lua` — 24-state cyclic FSM (hour_1 → hour_24 → hour_1, 3600s per state)
3. `src/meta/objects/candle.lua` — enhanced (extinguish/partial burn/timed_events)
4. `src/meta/objects/match.lua` — enhanced (no-relight path, timed_events)

**Architectural Decisions (6 filed):**
- D-OBJ001: timed_events replaces on_tick for timer-driven objects
- D-OBJ002: Candle uses remaining_burn for pause/resume timer
- D-OBJ003: Match extinguish → spent (terminal), NOT unlit
- D-OBJ004: Wall clock = 24-state cyclic FSM (no engine special-case code)
- D-OBJ005: Candle holder uses parts pattern for detachable candle
- D-OBJ006: Terminal spent states carry consumable flag

**Bugfix Pass-007:**
- **BUG-031 FIXED:** Compound "and" + GOAP clean output
- **BUG-032 FIXED:** "burn" as GOAP synonym for "light"

**User Directives Captured:**
- UD-2026-03-20T21:54Z: No special-case objects; clock as 24-state FSM (architectural purity)
- UD-2026-03-20T21:57Z: Wall clock supports misset time for puzzles (instance-level time_offset)

### Session: Timed Events Engine + READ Verb + Wall Clock Misset (2026-03-20T22:15Z)

**Status:** ✅ COMPLETE
**Outcome:** FSM timer tracking, skill-granting READ verb, wall clock puzzle support

**Timed Events Engine (D-TIMER001):**
- FSM timer tracking with two-phase tick pattern (collect expired, then process)
- Timer lifecycle: start on state entry, stop on state exit (automatic via fsm.transition)
- Room load/unload: pause timers on unload, resume on re-entry
- Sleep integration: timers advance per sleep tick (consistent with 10 ticks/hour model)
- Cyclic state support: wall clock hour transitions (hour_1→hour_24→hour_1)

**READ Verb Skill-Granting (D-READ001):**
- Full skill grant protocol: inventory/visibility check, readable category check, burn state rejection
- Skill mutation: `player.skills[skill] = true` AND `obj.skill_granted = true` (marker)

**Wall Clock Misset Puzzle Support (D-CLOCK001):**
- Instance-level configuration: time_offset, adjustable, target_hour, on_correct_time
- SET/ADJUST verb advances clock by one hour per invocation

### Session: Window & Wardrobe FSM Consolidation (2026-03-20T21:45Z)

**Status:** ✅ COMPLETE
**Outcome:** Single-file FSM pattern established for all openable objects
- Merged window.lua + window-open.lua into single unified FSM
- Deleted window-open.lua, wardrobe-open.lua
- Pattern: all openable objects follow single-file FSM architecture

### Session: GOAP Tier 3 Backward-Chaining Implementation (2026-03-20T21:15Z)
**Status:** ✅ COMPLETE
**Outcome:** Goal-oriented action planning with automatic prerequisite resolution

- Backward-chaining prerequisite resolver (~220 lines) in `src/engine/parser/goal_planner.lua`
- "light candle" auto-chains: open drawer → open matchbox → take match → strike match → light candle
- UNLOCK verb for exits (doors), key_id matching, NLP: "use key on door" → "unlock door with key"
- BUG-029/BUG-030 fixed (iron door examinable, unlock verb works)
- Pre-check mechanism (runs BEFORE verb handler), stop-on-failure

### Session: Movement Verbs + Room 2 + Multi-Room Engine (2026-03-20)
**Status:** ✅ COMPLETE
- Direction verbs: N/S/E/W/U/D + go/enter/descend/ascend + aliases
- All rooms loaded at startup, shared registry, per-room contents, room state persists
- Cellar room created (dark, locked iron door, barrel, torch bracket)
- BUG-027/028 fixes

### Session: Terminal UI (2026-03-20)
**Status:** ✅ COMPLETE
- Split-screen: status bar + scrollable output + input prompt
- Print interception via display module, scrollback via /up /down /bottom
- --no-ui flag, pcall wrapper for cleanup

### Session: Spatial Relationships & Rug/Trap Door Puzzle (2026-03-20)
**Status:** ✅ COMPLETE
- Spatial movement system, PUSH/MOVE/SHIFT/SLIDE/SHOVE/LIFT handlers
- Rug + trap door puzzle: push bed → pull rug → reveal trap door → open → exit
- Blocking relationships, covering system, hidden object reveal

### Session: Composite/Detachable Object System (2026-03-20)
**Status:** ✅ COMPLETE
- Parts table with factory pattern, detach/reattach, two-handed carry
- PULL/REMOVE/UNCORK verbs; nightstand (4-state), poison bottle cork

### Session: Player Skills System + Gap Fixes (2026-03-20)
**Status:** ✅ COMPLETE
- Skill gate checking, READ verb grants skills, SEW verb crafting
- Sewing manual object, curtains FSM, wearable container (sack), blood persistence, wardrobe FSM

## Versioning Architecture (2026-07-22)

**Status:** ✅ DESIGN COMPLETE  
**Requested by:** Wayne "Effe" Berry

### What Was Designed

Comprehensive versioning strategy addressing GitHub Pages caching, version visibility, and independent component release cycles.

**Deliverables:**

1. **`docs/architecture/web/versioning.md`** — Web-specific versioning doc with cache-busting via content-hash query params, bootstrap messages, and build pipeline integration

2. **`docs/architecture/engine/versioning.md`** — General engine versioning covering CLI, web, and release lifecycle

3. **`.squad/decisions/inbox/bart-versioning.md`** — Decision D-VERSION001 through D-VERSION006

### Key Design Choices

**Single Source (D-VERSION001):**
- All versions in `src/version.lua` (bootstrapper, engine, meta, game)
- No duplication across package.json, comments, or build scripts

**Semantic Versioning (D-VERSION002):**
- Each component (bootstrapper, engine, meta) increments independently
- MAJOR on breaking changes, MINOR on features, PATCH on fixes
- Game version coordinates major releases

**Cache-Busting (D-VERSION003):**
- Content-hash query params: `?v=HASH` (12-char SHA256 prefix)
- Build scripts compute hashes at build time
- File changed → hash changed → new URL → fresh download
- Eliminates GitHub Pages cache issues without manual cache invalidation

**Version Display (D-VERSION004):**
- Bootstrap messages show versions: "Loading Bootstrapper v1.0.0..."
- CLI supports `--version` flag
- JIT loader messages show meta version
- Aids troubleshooting and cache validation

**CLI Integration (D-VERSION005):**
- `lua src/main.lua --version` outputs: `MMO 0.1.0 (engine: 0.3.1)`
- Engine version applies to both CLI and web (same codebase)

**Manifest File Optional (D-VERSION006):**
- `versions.json` not required for V1
- Future feature for client-side update notifications

### Release Lifecycle

| Scenario | Action |
|----------|--------|
| Engine bug fix | Bump engine PATCH → rebuild → new hash → fresh download |
| New verb system | Bump engine MINOR → message shows new version |
| New Level 2 | Bump meta MINOR, optionally game MINOR → coordinate release |
| Major overhaul | Bump MAJOR, include in game version, update all messages |

### Addressed Concerns

✅ **GitHub Pages caching:** Content-hash query params force fresh downloads regardless of cache headers  
✅ **Version visibility:** Bootstrap messages + CLI flag + in-game output  
✅ **Independent versioning:** Each component (bootstrapper/engine/meta) increments separately  
✅ **Cache-busting:** Automatic via content hashes, no manual invalidation needed  
✅ **General architecture:** Applies to CLI and web equally  

### Implementation Notes for Smithers

1. Create `src/version.lua` with initial versions (bootstrapper 1.0.0, engine 0.1.0, meta 0.1.0, game 0.1.0)
2. Add `--version` flag to `src/main.lua`
3. Update build scripts (build-engine.ps1, build-meta.ps1) to extract versions and compute hashes
4. Wire versions into bootstrapper.js (embed at build time)
5. Rewrite URLs in index.html and bootstrapper.js with `?v=HASH`
6. Test CLI: `lua src/main.lua --version`
7. Test web: Verify bootstrap messages display correct versions

---

## Learnings

- FSM state transitions that touch `surfaces` are dangerous — save containment BEFORE cleanup
- Fuzzy matching thresholds must scale with word length (short words = exact match only)
- State labels in object names are anti-pattern (use _state, express through description)
- Debug output should be gated at construction time (pass flag in constructor)
- Skills as binary table lookup is right for V1
- Crafting recipes belong ON the material object
- "Take X from Y" must handle both containers and surfaces with accessible checks
- Tier 2 runtime: Jaccard + prefix bonus, threshold 0.40, Levenshtein typo correction (≤2 edit distance)
- Spatial relationships as per-object properties (not separate graph module)
- Covering objects dump surfaces underneath AND reveal covering list (two mechanisms)
- Exit mutations and room object state are separate systems — sync needed on mutation
- `apply_mutations()` must run AFTER `apply_state()` but BEFORE `on_transition` — state sets baseline, mutate adjusts instance, callback sees final result
- Three mutation types cover all cases: direct value, computed function, list ops (add/remove) — no need for a fourth
- Hook mutations into all three transition paths (manual, on_tick auto, timer-expired auto) or objects will silently skip mutations on timed transitions
- Material properties are a data layer, not a class hierarchy — Lua table registry with `get(name)` is the right pattern
- Threshold checking extends the FSM tick (step 2 after on_tick), never replaces it — backward compatibility is preserved by nil-checking `obj.thresholds`
- Lazy-loading the material registry via pcall avoids hard dependency — FSM module works fine without materials loaded
- Environment context (temperature, wetness, etc.) belongs on the room table and is assembled per-tick in the loop, not stored globally
- Support both direct numeric thresholds (`above = 62`) and material-referenced (`above_material = "melting_point"`) for flexibility — objects can hardcode or delegate to registry
- GOAP terminal state detection must be comprehensive — checking just `_state == "spent"` misses `state.terminal`, `consumable` flag, and "useless" category. Use a single `is_spent_or_terminal()` helper for all checks.
- When multiple FSM transitions share the same from→to pair (drink and pour both go open→empty), `fsm.transition()` needs a verb_hint parameter to disambiguate — first-match is wrong when verbs differ.
- GOAP container cleanup: spent matches in containers block fresh ones because the take verb grabs the first keyword match. Plan must include take+drop steps for preceding spent items.
- Material registry must stay in sync with object material fields — cross-reference check caught "cardboard" (matchbox) and "linen" (pillow) as additional missing entries beyond the reported "oak" and "velvet".
- CLI arg parsing: Lua's `arg` table is positional — use while-loop with manual index advance for `--flag value` pairs (not ipairs)
- Debug/test features should gate behind explicit flags and print visible warnings so testers never confuse backdoor starts with normal gameplay

## Mutation Analysis & Architecture Alignment (2026-03-21T00:16Z)

**Status:** ✅ COMPLETE  
**Orchestration Log:** `.squad/orchestration-log/2026-03-21T00-16Z-bart.md`

### Engine Mutation Surface Audit

Comprehensive analysis of all property mutations across the engine:

**FSM Transition Engine (`engine/fsm/init.lua`):**
- 14 properties mutated via `apply_state()`: _state, name, description, room_presence, sensory verbs (on_feel/on_smell/on_listen/on_taste/on_look), casts_light, light_radius, provides_tool, consumable, surfaces

**Verb Handlers:** 
- 60+ distinct mutations across player and object state
- Player mutations: hands, worn, location, state.bloody, state.bleed_ticks, state.has_flame, state.poisoned, state.nauseated, state.dead
- Object mutations: all properties except core 5 (weight/size/keywords/categories/portable)

**Key Finding:** Core object properties (weight, size, keywords, categories, portable) are architecturally stable — never mutated across all systems.

### Proposal: Generic `mutate` Field

Added to decisions.md as D-MUTATE-PROPOSAL. Enables:
- Explicit transition-time mutation declarations
- Arbitrary property changes at FSM transition time
- Maintains engine genericity (no object special-casing)
- ~25 lines Lua implementation

Aligns with user directive: Dwarf Fortress property-bag architecture validates this approach.

### Decision Filed

- **D-MUTATE-PROPOSAL:** Generic `mutate` field on FSM transitions
- **D-PRINCIPLE-GOVERNANCE:** Core principles are hard constraints
- **D-DF-ARCHITECTURE:** Dwarf Fortress reference model (property-bag over special-casing)

## Level Data Architecture (2026-07-21)

**Status:** ✅ COMPLETE  
**Requested by:** Wayne "Effe" Berry

### What Was Built

Designed and implemented the level data architecture — a two-layer system for grouping rooms into levels with completion criteria and boundary definitions.

**Deliverables:**

1. **`src/meta/levels/level-01.lua`** — Level 1 definition file (The Awakening). Contains room list, completion criteria (reach hallway from deep-cellar OR courtyard), boundaries (entry: start-room, exit: hallway→north→Level 2), and restricted_objects placeholder.

2. **`level` field on all 7 room .lua files** — Added `level = { number = 1, name = "The Awakening" }` to: start-room, cellar, storage-cellar, deep-cellar, hallway, courtyard, crypt. Smithers' status bar can now read `room.level` directly; the hardcoded `LEVEL_MAP` fallback is obsolete.

3. **`docs/architecture/engine/levels.md`** — Full architecture doc covering both data sources, schema definitions, completion criteria format, boundary enforcement model, and future engine integration points.

**Design Decisions (2 filed):**
- D-LEVEL001: Two-layer level data model (room field + level definition file)
- D-LEVEL002: Completion criteria are declarative OR'd conditions; restricted objects are advisory (not auto-enforced)

**Key Design Choices:**
- Courtyard is Level 1 (per CBG's master plan), not Level 2 (corrects Smithers' interim LEVEL_MAP)
- Completion criteria use `reach_room` type with optional `from` constraint
- `restricted_objects` is advisory — designers must build diegetic removal puzzles (per Wayne's directive in level-design-considerations.md)
- Level file is source of truth; room-level field is denormalized for fast UI reads

**Validated:** Game starts cleanly with `lua src/main.lua --no-ui --room start-room`. All 7 rooms load with level fields intact.

## JIT Loader Architecture (2026-07-21)

**Status:** ✅ DESIGN COMPLETE  
**Requested by:** Wayne "Effe" Berry

### What Was Designed

Architecture for replacing the monolithic `game-bundle.js` with a JIT loading system for the web version. Engine code stays bundled (~2-3MB); meta files (objects, rooms, levels, templates) served individually and fetched on demand.

**Deliverables:**
1. `docs/architecture/web/jit-loader.md` — Full architecture doc: web loader API, static file layout, loading flow, error handling, build pipeline, implementation order
2. `.squad/decisions/inbox/bart-jit-loader.md` — Decision D-JIT001

**Key Design Choices:**
- New `src/engine/loader/web.lua` wraps existing loader — no engine core changes
- Objects served at GUID-based URLs (matches `type_id` references in rooms)
- Rooms served at ID-based URLs (matches `exit.target` references)
- All meta types already have UUID-format GUIDs — no GUID expansion needed
- `fetch_room_bundle()` is the primary API: fetches room → discovers objects → parallel fetch
- Write-once cache, graceful degradation on single-object failure
- CLI mode completely unchanged

## Learnings

- All rooms and levels already have UUID-format GUIDs — checked all 7 rooms and level-01
- The coroutine yield/resume pattern in game-adapter.lua can be reused for async HTTP fetches (same mechanism as io.read yields)
- Object files need GUID-based renaming at build time because room instances reference by type_id (GUID), not filename
- Template count is small enough (5 files, ~2KB) to always fetch at init — no JIT needed for templates
- The VFS layer (vfs_get/vfs_list) can stay for engine require() resolution while meta files use a separate HTTP fetch path
- Wayne's full web architecture is THREE layers, not two: (1) JS bootstrapper fetches+decompresses, (2) compressed engine bundle, (3) JIT Lua loader for meta files
- The bootstrapper is the ONLY JS file loaded by HTML — everything else flows from it
- Engine bundle is published pre-compressed as engine.lua.gz (~500KB); bootstrapper decompresses client-side using DecompressionStream API
- SLM embeddings (~15MB) are a SEPARATE file from the engine bundle — only loaded if AI features needed
- Status messages during load are light gray and progress through both JS (bootstrapper) and Lua (JIT loader) phases
- Source dir `src/meta/world/` maps to URL path `meta/rooms/` — the build script handles the rename for cleaner URL semantics
- build-engine.ps1 outputs pure Lua (not JS strings) — the engine.lua file is valid Lua that Fengari executes directly after decompression

## GUID Audit (2026-07-21)

**Status:** ✅ NO CHANGES NEEDED — All GUIDs already present

Wayne requested GUIDs be added to all room and level .lua files. Audit confirmed every file already has a properly formatted `guid` field (lowercase, hyphens, no braces). This aligns with the earlier JIT Loader learnings entry.

**Verified GUIDs (all pre-existing):**

| File | GUID |
|------|------|
| `src/meta/world/start-room.lua` | `44ea2c40-e898-47a6-bb9d-77e5f49b3ba0` |
| `src/meta/world/cellar.lua` | `b7d2e3f4-a891-4c56-9e38-d7f1b2c4a605` |
| `src/meta/world/storage-cellar.lua` | `a1aa73d3-cd9d-4d13-9361-bd510cf0d46d` |
| `src/meta/world/deep-cellar.lua` | `64da418f-1fb2-4898-a016-50a5c0a6f4da` |
| `src/meta/world/hallway.lua` | `bb964e65-2233-4624-8757-9ec31d278530` |
| `src/meta/world/courtyard.lua` | `8fa16d57-41ea-4695-a61b-2ccc3f68c1b6` |
| `src/meta/world/crypt.lua` | `dea3ae62-c67e-4092-a361-fe3911c3fd4e` |
| `src/meta/levels/level-01.lua` | `c4a71e20-8f3d-4b61-a9c5-2d7e1f03b8a6` |
| `src/meta/templates/container.lua` | `f1596a51-4e1f-4f9a-a6d0-93b279066910` |
| `src/meta/templates/furniture.lua` | `45a12525-ae7c-4ff1-ba22-4719e9144621` |
| `src/meta/templates/room.lua` | `071e1b6a-17ae-498b-b7af-0cbb8948cd0d` |
| `src/meta/templates/sheet.lua` | `ada88382-de1e-4fbc-908c-05d121e02f84` |
| `src/meta/templates/small-item.lua` | `c2960f69-67a2-42e4-bcdc-dbc0254de113` |

**Learnings:**
- GUID coverage was already 100% across rooms, levels, and templates — prior JIT Loader session had already noted this

### Session: Parser Unit Test Framework (2026-07-21)

**Status:** ✅ COMPLETE  
**Outcome:** 26 tests across 2 test files, all passing. Pre-deploy gate script created.

**Deliverables:**
1. `test/parser/test-helpers.lua` — minimal pure-Lua test framework (test, assert_eq, assert_truthy, assert_nil, assert_no_error)
2. `test/parser/test-preprocess.lua` — 22 tests covering preprocess.parse() and preprocess.natural_language()
3. `test/parser/test-context.lua` — 4 tests covering pronoun resolution, context retention bug, crash protection, BUG-049 alias
4. `test/run-tests.lua` — test runner with auto-discovery of test-*.lua files
5. `test/run-before-deploy.ps1` — pre-deploy gate (tests must pass before build)
6. `docs/architecture/engine/testing.md` — framework documentation

**Decisions Filed:**
- D-TEST001: Pure-Lua test framework, no external dependencies
- D-TEST002: Tests gate deployment (run-before-deploy.ps1)
- D-TEST003: Test files run as isolated subprocesses
- D-TEST004: Known bugs documented as passing tests (not "expected failures")

**Context Retention Bug Confirmed:**
- After "search wardrobe", bare "open" says "Open what?" — `ctx.last_object` is set but verb handlers with `noun == ""` don't consult it
- Test documents current behavior and fix path inline
- Fix target: verb handlers should check `ctx.last_object` when noun is empty

## Learnings

- `verbs.create()` returns a handler table — not `verbs.init()`. The module has no init function.
- Verb handler tests need `game_start_time` and `time_offset` in context because presentation.lua calculates game time from real time
- `search` is aliased to `examine` (with noun) or `look` (bare) — it goes through find_visible, which sets last_object
- The pronoun resolution wrapper around find_visible works for "it"/"one"/"that" but NOT for empty noun — that's the gap causing the context retention bug
- Test files must run as subprocesses because the verb module loads the full dependency graph (FSM, containment, presentation, materials)

### Session: Visited Room Tracking + Bold Room Titles (2026-07-24)
**Status:** ✅ COMPLETE
**Outcome:** Two engine UX features implemented — visited room tracking with short descriptions on revisit, and bold room title markers.

**Deliverables:**
1. **Visited room tracking** — `ctx.visited_rooms` (set of room IDs) initialized in `main.lua` and `web/game-adapter.lua`. Starting room marked visited at startup. `handle_movement` in `verbs/init.lua` checks visited set; first visit triggers full auto-look, revisit shows only bold title + `short_description`.
2. **Bold room titles** — Room titles wrapped in `**markdown bold**` markers in all display paths: bare "look" (lit and dark), and movement arrival. Web layer can detect `**...**` for `<strong>` rendering.
3. **Short descriptions** — All 7 room files (`start-room`, `hallway`, `cellar`, `storage-cellar`, `deep-cellar`, `courtyard`, `crypt`) now have `short_description` fields. Fallback: if missing, only title shown.

**Key design decisions:**
- Bold markers use `**text**` (markdown convention) — engine-agnostic, web layer converts to HTML `<strong>`
- "look" verb ALWAYS shows full description regardless of visit history
- `visited_rooms` is a flat Lua table used as a set — O(1) lookup, no serialization overhead
- Room template unchanged — `short_description` is optional metadata on room instances

## Learnings

- Multi-command splitting must happen BEFORE the existing " and " compound split in the game loop — the two are layered (outer: commas/semicolons/then, inner: " and ")
- Lua string pattern %f[%a] (frontier) is useful for word-boundary matching but tricky for the " then " separator — simpler to rely on the space characters in the literal " then " pattern
- The fast path (no separators → single command) avoids allocation overhead for 99% of inputs
- Quoted text protection via character-by-character scan is more reliable than trying to do regex with Lua patterns
