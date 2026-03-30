# Bart -- History (Summarized)

## Project Context

- **Project:** MMO - A text adventure MMO with multiverse architecture
- **Owner:** Wayne 'Effe' Berry
- **Stack:** Lua (engine + meta-code), cloud persistence
- **Key Concepts:** Each player gets their own universe instance with self-modifying meta-code. Objects are rewritten (not flagged) when state changes. Code IS the state.

## Core Context (Key Learnings & Patterns)

**Role:** Architect - engine design, verb systems, FSM mechanics, mutation patterns, puzzle systems

**Architecture Decisions Documented:**
- D-14: Code mutation IS state change (objects rewritten at runtime, not flagged)
- D-WORLDS-CONCEPT: Worlds meta concept - top-level container above Levels
- D-ENGINE-REFACTORING-WAVE2: Engine refactoring sequencing (6 files, 5 modules each)
- D-MUTATION-LINT-PIVOT: Mutation graph linter uses expand-and-lint (Python meta-lint)
- D-MUTATION-CYCLES-V2: Multi-hop chain validation deferred to Phase 2

**Major Systems Built (Phase 3 Completion):**
- **Engine Foundation:** Loader (sandboxed execution), Registry (GUID-indexed), Mutation (hot-swap via loadstring), Loop (REPL)
- **Verb System:** 31+ verbs; tool resolution via capabilities (supports virtual tools like blood)
- **FSM Architecture:** Inline state machines with timer tracking (two-phase), room pause/resume, cyclic states
- **Phase 3 Refactoring Completed:** Split helpers.lua (1634->5 modules), preprocess.lua (1282->6 modules), sensory.lua (1113->3 modules), traverse_effects.lua (2-module split). All splits maintain backward API compatibility via thin facade pattern. Full test suite: 243/243 passing.

**Critical Bugs Fixed (Wave 3):**
- #372 & #376: require(engine.verbs.helpers) failures - root cause was split-related import paths. Added regression test test/engine/test-helpers-facade.lua (12 assertions).
- #386: Linked exit sync - FSM transitions now properly sync room exit state via becomes_exit mutations
- #382: Burn no-flame message - updated error message to match test assertions
- #375: Level intro in headless - verified already fixed, no action needed
- #368: Rename goto-teleport - swapped primary/alias in movement.lua
- **Brass Key/Padlock Fix:** Both unlock and lock verb handlers lacked FSM transition logic AND key objects lacked provides_tool fields - double-bug pattern now recognized

**File Paths (Ongoing Responsibility):**
- src/engine/ - core engine modules
- src/meta/objects/, src/meta/world/ - object/world definitions
- src/engine/verbs/init.lua - verb dispatch
- docs/architecture/engine/ - engine architecture docs
- scripts/mutation-edge-check.lua - mutation linter (Phase 1 implemented; Phase 2 chains deferred)

**Learnings (Session Patterns):**
1. Phase 3 refactoring was chunked by file size (large monoliths split), but dependencies were the real complexity (e.g., helpers.lua required by all verb modules).
2. Facade pattern (X.lua alongside X/ directory) works in Lua but non-standard; future convention could standardize on init.lua.
3. Linter improvement (WAVE-1 through WAVE-6) requires serialized lint.py edits - only one agent per wave can touch the bottleneck file.
4. Two-phase FSM tick system (timers + state checks) is robust but adds complexity to testing edge cases.
5. Material properties and object nesting syntax remain the two most frequently referenced patterns in design.
6. **WAVE-1 Mutation Linter Wrappers:** Implemented PowerShell and shell wrapper scripts for mutation-lint pipeline. PS7 uses ForEach-Object -Parallel with collected output to avoid interleaving (Smithers blocker #2); PS5 falls back to sequential. Shell uses xargs -P with temp dir collection. Both wrappers pre-check Python availability (exit 2 if missing unless -EdgesOnly flag). Key pattern: parallel execution, sequential output display — respects D-MUTATION-LINT-PARALLEL decision.
7. **WAVE-2 JSON Output Mode:** Added `--json` flag to mutation-edge-check.lua (pure Lua JSON output, no dependencies). Updated .squad/skills/mutation-graph-lint/SKILL.md with invocation signature. Enables scripted tooling integration. Commit: e1efa39.



**Sound System Architecture Review (2026-07-31):**
- Reviewed `projects/sound/sound-implementation-plan.md` v1.0 as Architecture Lead (Pattern 5 team review).
- Verdict: ⚠️ Concerns — 7 spec gaps, 0 blockers. Plan is architecturally sound.
- Key findings: C1 terminal driver blocking (os.execute), C2 dual integration path ambiguity (effects vs direct trigger), C3 crossfade not in driver contract, C4 board/plan parallelism contradiction, C5 .ogg/.opus extension mismatch, C6 sound key resolution chain unspecified, C7 scan_object lifecycle timing unclear.
- Confirmed all 12 engine hook points are realistic against current codebase (fsm.transition L225, effects.register, mutation.mutate L53, loop.run L468).
- Review written to `.squad/decisions/inbox/bart-sound-review.md`. Board updated.
- Commit: d5962c6.

9. **Sound Plan v1.1 Consolidation (2026-07-31):**
   - Consolidated ALL findings from 7-agent team review (Bart, CBG, Marge, Chalmers, Flanders, Smithers, Moe) per implementation-plan skill Pattern 6.
   - Resolved 10 blockers: LLM test scenarios defined (Marge), regression baseline protocol (Marge), headless coverage on all gates (Marge), CBG parallelism clarified (Chalmers), GATE-0 interface contract freeze (Chalmers), WAVE-3 rollback plan (Chalmers), GUID pre-assignment protocol (Flanders), field naming convention standardized (Flanders+Moe), creature death state lifecycle (Flanders), verb integration pattern specified (Smithers).
   - Resolved 11 concerns: terminal driver io.popen() fix (C1), effects pipeline canonical path (C2), driver fade params (C3), board/plan parallelism reconciled (C4), .opus standardized (C5), sound key resolution chain (C6), scan_object lifecycle (C7), narration timing (Smithers), time-of-day Phase 2 (CBG), dead creature on_listen (CBG), gate failure escalation (Chalmers+Marge).
   - New plan sections: Gate Failure Escalation Protocol, Phase 2 Deferred Scope, dependency graph with WAVE-2 partial overlap.
   - Board updated: P0a ✅ complete, P0b set to Wayne final review.
   - Commit: 3bd51f1.

8. **Worlds WAVE-0 + WAVE-1 Loader (2026-03-30):**
   - Executed WAVE-0: Created `test/worlds/` directory, registered in `test/run-tests.lua` (test_dirs + source_to_tests mapping).
   - Executed WAVE-1 (loader portion): Built `src/engine/world/init.lua` with 5 functions: discover(), validate(), select(), get_starting_room(), load().
   - Module follows dependency injection pattern (zero require() calls) — list_lua_files, read_file, load_source passed as parameters.
   - Single-world auto-select: 0 worlds → FATAL, 1 world → return it, 2+ → "not implemented" (Phase 2).
   - Wrote `test/worlds/test-world-loader.lua` — 16 tests covering all functions + real world-01.lua integration.
   - Full suite: 258 test files, all passing (257 existing + 1 new). Zero regressions.
   - Board updated: WAVE-0 ✅ Done, WAVE-1 loader ✅ Done. Remaining: WAVE-1 data (Flanders), WAVE-2 boot, WAVE-3 docs.
   - Note: world-01.lua already existed in `src/meta/worlds/` (built by Moe previously). Template `world.lua` also already exists. The plan's WAVE-1 references "the-manor.lua" but the actual file is "world-01.lua" with `id = "world-1"` — no rename needed, the loader is generic.

10. **Sound WAVE-0 — Sound Manager + Null Driver + Defaults (2026-08-01):**
    - Executed WAVE-0 Track 0A per sound-implementation-plan.md v1.1, approved by Wayne.
    - Created `src/engine/sound/init.lua` (~300 LOC): Full sound manager with 21-method API surface.
      - Construction: `new()`, `init(driver, options)`, `shutdown()`
      - Driver injection: `set_driver(driver)`, `get_driver()`
      - Object scanning: `scan_object(obj)`, `flush_queue()`
      - Playback: `play(filename, opts)`, `stop(play_id)`, `stop_by_owner(owner_id)`
      - Room transitions: `enter_room(room)`, `exit_room(room)`, `unload_room(room_id)`
      - Event dispatch: `trigger(obj, event_key)` — 3-step resolution chain (obj.sounds → defaults → nil)
      - Settings: `set_volume(level)`, `get_volume()`, `set_enabled(bool)`, `mute()`, `unmute()`, `is_muted()`, `is_enabled()`
    - Created `src/engine/sound/defaults.lua`: 15-entry verb-to-sound fallback table (on_verb_break → generic-break.opus, etc.)
    - Created `src/engine/sound/null-driver.lua`: Pure no-op driver implementing full driver interface (load, play, stop, stop_all, set_master_volume, unload, fade).
    - Created `test/sound/test-sound-manager.lua`: 47 tests across 12 suites covering module load, construction, driver injection, nil-driver no-op, mock driver playback, volume clamping, mute/unmute, set_enabled, scan_object, trigger resolution chain, room transitions, concurrency limits (4 oneshots, 3 ambients), null driver integration, GATE-0 API surface verification.
    - Registered `test/sound/` in `test/run-tests.lua` (test_dirs + source_to_tests mapping).
    - Full suite: 259 test files, all passing (258 baseline + 1 new). Zero regressions.
    - Board updated: WAVE-0 Bart track ✅ Done. Gil (web bridge) and Nelson (mock driver scaffolding) tracks still pending for full GATE-0.
    - Key design choices: OOP with metatables (`M.new()` + colon methods), volume 0.0–1.0 (not 0–100), pcall wraps all driver calls, concurrency limits enforced via eviction (oldest-first for oneshots, lowest-priority for ambients).

11. **Sound WAVE-2 Track 2A — Engine Event Hooks (2026-08-01):**

## Cross-Agent Coordination: Options Build Complete (2026-03-29)

**Summary:** All 4 phases of options system delivered and tested. System ready for deployment.

| Phase | Agent | Deliverable | Commit/Status |
|-------|-------|-------------|----------------|
| 1+3 | Bart | Core options engine (~400 LOC), hybrid generator | 26400a8 ✅ |
| 2+4 | Smithers | Parser aliases (10 routes), number selection | ✅ |
| 5 | Moe | Room goal metadata (7 rooms) | ✅ |
| 6 | Nelson | TDD suite (53 tests) | ✅ |

**Decision archive:** D-OPTIONS-ENGINE-HYBRID, D-OPTIONS-ALIASES, D-ROOM-GOALS, D-OPTIONS-TESTS merged to `.squad/decisions.md`.
    - Executed WAVE-2 Track 2A per sound-implementation-plan.md v1.1. Wired 12 hook points across 9 files, 70 insertions.
    - **FSM hook** (`fsm/init.lua`): `context.sound_manager:trigger(obj, "on_state_" .. target_state)` after successful transition. Nil-safe via `if context and context.sound_manager`.
    - **Verb dispatch hook** (`loop/init.lua`): `context.sound_manager:trigger(nil, "on_verb_" .. verb)` after successful handler dispatch. Generic pattern — one line covers all 31+ verbs.
    - **Mutation hook** (`mutation/init.lua`): Added optional `ctx` 6th parameter. Sequence: `stop_by_owner(old_id)` → `trigger(old, "on_mutate")` → `reg:register()` → `scan_object(new_obj)`. Updated 3 callers (helpers/mutation.lua, cooking.lua, helpers/tools.lua) to pass ctx.
    - **Movement hooks** (`verbs/movement.lua`): `exit_room(old)` before text, `enter_room(new)` after text. Applied at all 4 room transition code paths (go-back, portal, legacy exit, teleport).
    - **Effects pipeline** (`effects.lua`): Registered `play_sound` effect type — canonical sound dispatch path. Supports `key` (trigger resolution) and `filename` (direct play) modes.
    - **Loader hook** (`loader/init.lua`): Added `loader.scan_for_sounds(sound_manager, obj)` utility for post-registration scanning.
    - Full suite: 260 test files, all passing. Zero regressions.
    - Commit: 2669e5e.
    - Key patterns: nil-safe guards (`if ctx.sound_manager then`), text-first/sound-concurrent ordering, effects pipeline as canonical path (no direct trigger from verb handlers), mutation ctx threading for sound lifecycle.

## Learnings

12. **Mutation ctx threading:** `mutation.mutate()` had no context access. Added optional 6th `ctx` parameter — backward compatible (nil = no sound hooks). This pattern will recur for any future cross-cutting concern that needs runtime context in mutation.
13. **Movement has 4 room transition paths:** go-back, portal, legacy exit, teleport. All needed sound hooks independently — no shared helper. Future refactor opportunity: extract `change_room(ctx, old_room, new_room)` helper.
14. **Effects pipeline as canonical sound path:** The `play_sound` effect handler is the single entry point from object metadata. Direct `trigger()` calls only happen from engine internals (FSM, mutation, verb dispatch). This keeps the dual-path concern (C2) cleanly resolved.
15. **Options architecture blockers resolved:** Fixed 6 blockers (B1/B6/B7/B9/B11/B12) in `projects/options/architecture.md` v2. Key additions: API contracts define `OptionEntry` structure and context requirements, numeric precedence rule ensures object names like "2" work when `pending_options` is nil, performance budget <50ms with graceful GOAP degradation, empty room fallback returns generic prompts never empty list, state-based goal detection (not action-based) ensures failed actions don't count as goal completion. Wayne approved Approach C (goal-driven hybrid), Option C context window (stable goals + rotating sensory), free hints, state-based goals.
16. **Options Engine Phase 1+3 Complete (2026-03-29):** Built core options/hint system per approved architecture v2. Created `src/engine/options/init.lua` (~400 LOC) with 3-phase hybrid generator: (1) GOAP goal steps via existing planner (0-2 items), (2) sensory exploration with light-level awareness and rotation (1-2 items), (3) dynamic object scan via FSM/container scoring (fill to 4). Created `src/engine/verbs/options.lua` verb handler, hooked into verbs/init.lua. API exports `generate_options(ctx)` returning `OptionsResult` with `options[]` and `flavor_text`. Supports room exemptions (options_disabled, options_mode="sensory_only", options_delay=N), flavor text escalation based on request count. Full test suite passes (265/268 files, 11 pre-existing failures). Architecture Pattern: GOAP reused for goal decomposition without modification — wrapper function `generate_goal_steps()` calls existing `goal_planner.plan()`. Anti-spoiler Rule 1 enforced: show only first step, not full chain. Context window Option C implemented: goal steps stable (same GOAP result), sensory suggestions rotate (filter recently used verbs). Performance target <50ms deferred to Phase 2 testing. Key decision: no object-specific engine code — all behavior via metadata (room.goal, room.options_mode, obj.transitions, obj.container). Commit: 26400a8.
17. **Wyatt's World Implementation Plan (2026-08-22):** Wrote full implementation plan (`projects/wyatt-world/plan.md` v2.0) replacing Kirk's v1.0 placeholder. 4 waves, 3 gates, 15 new test files, ~6,050 estimated LOC. Key architecture decisions: (a) `content_root` convention — each world.lua specifies where its rooms/objects/levels live relative to `src/meta/`, Manor uses legacy nil (existing paths), Wyatt uses `worlds/wyatt-world`; (b) `--world <id>` CLI flag for world selection with 2+ worlds, auto-select with 1; (c) `select(worlds, world_id)` upgraded from error-on-multi to ID-based selection; (d) `get_content_paths(world, meta_root)` new function returns resolved dirs. WAVE-0 is engine-only (Bart), WAVE-1 is parallel content (Moe/Flanders/Bob/Nelson), WAVE-2 is polish+testing (Smithers/Nelson), WAVE-3 is review+deploy (CBG/Wayne/Gil). Recommended player-state approach for cross-room scoreboard tracking (avoids cross-room mutations and Principle 8 violations). Board updated. Decision written to inbox.
18. **Wyatt's World Plan v2.1 — Review Fixes (2026-08-23):** Fixed all 3 blockers + 12 concerns from 6-agent team review (CBG, Nelson, Smithers, Moe, Bob, Flanders). **Blockers resolved:** B1: Added `rating = "E"` field to wyatt-world.lua definition + two-layer enforcement model (engine hard-blocks combat/harm at verb dispatch in `src/engine/verbs/init.lua`; design soft-enforces no-poison/no-scary). B2: Added `test/worlds/test-e-rating-blocks.lua` to TDD test map + E-rating verification to GATE-0 criteria (G0-8, G0-9). B3: Pre-assigned ~80 GUIDs for all Wyatt entities in `.squad/decisions/inbox/bart-wyatt-guids.md`. **Concerns resolved:** C1: E-rating in WAVE-0 scope. C2: Wayne fixes reading-level violations in WAVE-3b. C3: Parser verb coverage pre-flight check added. C4: Player-state scoreboard approach LOCKED. C5: Design debt tracking mechanism added to WAVE-3a. C6: Synonym matching expanded (dark/darken/darkened/shadow/shadows/shadowy/dim/dimly). C7: Bounded test script for S11 "Confused Player" (8 inputs, max 30s, bailout condition). C8: Dispatch interception point documented (verb dispatch, not parser preprocess). C9: Ambient sound spec added to room rules. C10: FSM state name coordination with Flanders before WAVE-1c. C11: Burger assembly ordering logic clarified (plate resets on wrong order). C12: Reading-level audit explicitly in WAVE-2b. Test file count: 15→16. LOC estimate: ~150→~200. Board updated. GUID block published.

19. **World Folder Restructure — Manor Isolation (2026-08-24):** Executed full restructure of `src/meta/` to world subfolders per Wayne's directive. Moved 168 files via `git mv` from `src/meta/{category}/` to `src/meta/worlds/manor/{category}/`. Templates and materials remain shared at `src/meta/templates/` and `src/meta/materials/`. Engine changes: `main.lua` derives content paths from `world_content_root`; `engine/injuries/init.lua` gets configurable `set_content_root()` for require path; `engine/world/init.lua` discovers worlds from subdirectories (not .lua files); `web/build-meta.ps1` and `web/game-adapter.lua` updated for new paths; `scripts/mutation-edge-check.lua` updated to recursive scan; `scripts/meta-lint/lint.py` `_detect_kind()` updated for nested paths. Updated 90+ test files across all path pattern variants (literal strings, SEP concatenation, multi-line, require() paths). Created 4 README.md files. Test suite: 268 PASSED, 4 FAILED (same 12 pre-existing). Zero regressions. Commit: 177e8c8. Decision: D-WORLD-FOLDER-STRUCTURE.
    - **Key learning:** Path references in this codebase use 6+ distinct patterns (literal forward-slash, literal backslash, SEP variable single-line, SEP variable multi-line, require() dot-path, Python os.sep). A bulk find-replace only catches literal strings — iterative grep passes are needed to find all patterns.
    - **Key learning:** The lint.py `_detect_kind()` function hardcodes filesystem paths to classify file types. Any path restructure MUST update this function or lint rules silently stop firing.
    - **Key learning:** The injury engine uses `require()` (Lua module system) not `io.open()` (filesystem). Path updates for require-based loading need a different approach than filesystem-based loading — either update `package.path` or change the require string.
