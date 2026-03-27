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

### Recent Work: Unified Sound Implementation Plan (2026-07-31)

**Consolidated 3 draft sections into unified 4-wave implementation plan:**
- Merged Bart engine architecture, CBG game design (30KB), and Gil web pipeline (20KB) into `plans/sound/sound-implementation-plan.md` (333 lines)
- Deleted consolidated drafts: `sound-design-notes.md`, `sound-web-pipeline-notes.md`
- 4 waves: WAVE-0 (sound manager + platform abstraction), WAVE-1 (object metadata + asset sourcing), WAVE-2 (engine event hooks), WAVE-3 (build pipeline + polish + docs)
- 18 design decisions consolidated (D-SOUND-1 through D-SOUND-18)
- File ownership table spanning 10 team members across all waves
- Risk register, architectural constraints, dependency graph
- Followed implementation-plan skill format: status tracker, executive summary, quick reference table, per-wave details with gate criteria

### Prior Work: Sound System Architecture Plan (2026-07-31)

**Sound Implementation Plan — Engine Architecture Section:**
- Wrote `plans/sound-implementation-plan.md` Section 1: Engine Architecture (10 subsections)
- Designed `sounds` table metadata for objects, creatures, and rooms — event-keyed with prefixes (`on_state_`, `ambient_`, `on_verb_`, `on_mutate`)
- Designed lazy loading: `sound_manager:scan_object()` piggybacks on existing loader → registry flow
- Mapped 12 engine event hook points to sound triggers (FSM transitions, verb execution, room entry/exit, mutation, combat, timer expiration)
- Designed `src/engine/sound/init.lua` module: platform-agnostic API with injected driver pattern
- Two platform drivers: Web (Fengari + Web Audio API via JS bridge) and Terminal (os.execute best-effort, no-op fallback)
- Room-scoped audio: earshot = current room + player hands; room transitions stop/start ambients; mutation-aware
- Default verb sounds table for baseline coverage without per-object declarations
- Effects pipeline integration via `play_sound` effect type registration
- Filed 7 sub-decisions: D-SOUND-1 through D-SOUND-7 covering metadata, lazy loading, drivers, room scope, accessibility, compression, effects integration
- **Decisions filed:** D-SOUND-ARCHITECTURE (inbox)

### Prior Work: WAVE-2 — Creature Generalization Engine Work (2026-07-30)

**WAVE-2 Completion — Bart's Engine Work for Creature Attack + NPC Combat:**
- Fleshed out `src/engine/creatures/predator-prey.lua` — `has_prey_in_room()` and `select_prey_target()` scan same-room creatures against `behavior.prey` metadata
- Fleshed out `src/engine/combat/npc-behavior.lua` — `select_response()` reads `combat.behavior.defense`, `select_stance()` maps `attack_pattern` to engine stance, `select_target_zone()` uses `target_priority` for zone bias
- Added `creature_attacked` / `creature_died` convenience emitters to `src/engine/creatures/stimulus.lua`
- Wired attack action in `creatures/init.lua`: `score_actions()` scores attack when prey present (aggression + hunger + territorial bonus), `execute_action()` calls `combat.run_combat()` and emits stimuli
- Added territorial evaluation in `creature_tick()`: reduces fear when in home territory
- NPC support in `combat/init.lua`: auto-select stance/response/target-zone for non-player combatants
- `creatures/init.lua` at 468 LOC (under 500 limit)
- **Test suite:** 184 test files pass (40 WAVE-2 tests now green)
- **Decisions filed:** D-WAVE2-ENGINE

## Learnings

- **Territorial dual-path needed:** Tests call `score_actions()` in isolation (not through `creature_tick()`), so territorial aggression boost must be in `score_actions` directly, not just in `creature_tick`. Fear reduction can stay in `creature_tick` since it affects subsequent ticks.
- **Stimulus routing matters for testability:** Tests monkey-patch `creatures.emit_stimulus` to track emissions. Using `stimulus.emit_creature_attacked()` directly bypasses the intercept. Always route through the module's public `emit_stimulus` function.
- **attack_pattern ≠ stance:** Creature metadata uses `combat.behavior.attack_pattern` (opportunistic/sustained/ambush/hit_and_run/random), not `stance`. The `npc-behavior` module maps these to engine stances (aggressive/defensive/balanced) via `PATTERN_TO_STANCE` table.
- **Prey list lives on behavior, not combat:** `creature.behavior.prey` (not `creature.combat.behavior.prey`) holds the prey ID array. Must read from the right path.

### Prior Work: WAVE-0 — Module Splits & Architecture Prep (2026-03-27)

**WAVE-0 Completion — Bart's Module Splits + Mutation Architecture:**
- Extracted `src/engine/creatures/stimulus.lua` (67 LOC) — queue management for creature behavior
- Created `src/engine/creatures/predator-prey.lua` (38 LOC) stub — ready for WAVE-1 predator-prey mechanics
- Created `src/engine/combat/npc-behavior.lua` (39 LOC) stub — ready for WAVE-1 NPC combat AI
- Registered `test/food/` in test runner — ready for WAVE-1 food system tests
- Audited tissue materials: all 5 needed (hide, flesh, bone, tooth-enamel, keratin) exist
- Comprehensive mutation audit: 23 top-level + ~150 FSM entries documented
- Mutation graph linter plan written: 357 lines, 4-phase implementation roadmap
- Q&A with Wayne on D-14 mutation architecture clarified; 1 bug found (poison-gas-vent-plugged.lua missing)
- **Test suite:** 176 → 178 tests pass (+2 new food tests)
- **Branch:** squad/phase2-wave0-splits
- **Decisions filed:** D-STIMULUS-MODULE, D-PREDATOR-PREY-STUB, D-NPC-BEHAVIOR-STUB, D-TEST-FOOD-DIR, D-TISSUE-MATERIALS-AUDIT, D-MUTATION-GRAPH-LINTER

### Prior Work: #104 Engine Pass 3: player.lua as canonical state (2026-03-30)

**#104 — visited_rooms migrated to player model:**
- Moved `visited_rooms` from `ctx` root to `ctx.player.visited_rooms` — player model is now the single canonical source for all player state
- Updated `src/main.lua`, `src/engine/verbs/movement.lua`, `web/game-adapter.lua` (3 engine files)
- Updated 4 test files (hooks, movement, spatial, context-window) — 13 mock context sites total
- Added `test/verbs/test-player-canonical-state.lua` — 8 tests validating canonical state model
- Wrote architecture doc: `docs/architecture/player/player-pass-3.md`
- Zero regressions across 113 test files
- Decision filed: all new player state must go on `ctx.player`, never on `ctx` root

### Prior Work: #101 Engine Hooks: on_enter_room, on_exit_room, on_pickup, on_drop (2026-03-29)

**#101 — 4 Engine Hooks Implemented (TDD):**
- Added `on_pickup(obj, ctx)` hook in `acquisition.lua` — fires after successful take across all 4 take paths (room, bag, two-hand, single-hand)
- Added `on_drop(obj, ctx)` hook in `acquisition.lua` — fires after drop action in both single-item and "drop all" paths, before event_output
- Added `on_enter_room(room, ctx)` hook in `movement.lua` — fires after player enters target room, before arrival text. Covers both normal movement and "go back" path.
- Added `on_exit_room(room, ctx)` hook in `movement.lua` — fires before player leaves current room, after traverse effects. Covers both normal and "go back" paths.
- All 4 hooks follow established pattern: type-check for function, call with `(obj/room, ctx)`, then check `event_output` one-shot
- Updated `docs/architecture/engine/event-hooks.md` to v3.2
- TDD: 16 tests in `test/verbs/test-engine-hooks-101.lua`
- Zero regressions across full 105-file test suite

### Prior Work: #125 BUG-050 Fix + #103 Open/Close Hooks (2026-03-28)

**#125 BUG-050 — Duplicate Instance Display (TDD):**
- Root cause: objects already described in `room.description` also rendered their `room_presence` text in the presences section — double display (torches ×2, portraits ×3, sarcophagi ×5)
- Fix: Added `room.embedded_presences` — array of object IDs whose presence is already woven into room.description. Look handler builds a hash set and skips those IDs during presences iteration
- Also added `seen_ids` dedup to prevent duplicate object IDs in `room.contents` from rendering multiple presences
- Updated hallway, crypt, courtyard room files with `embedded_presences` lists
- TDD: 6 tests in `test/rooms/test-duplicate-presences.lua`
- Commit: d610975

**#103 Engine Hooks: on_open, on_close (TDD):**
- Added `on_open` hook after successful FSM open transition — `obj.on_open(obj, ctx)` callback pattern
- Added `on_close` hook after successful FSM close transition — same pattern
- Added `event_output` support for `on_open`/`on_close` — one-shot flavor text, nils key after printing
- Follows exact pattern of existing `on_wear`/`on_remove_worn` hooks
- Updated `docs/architecture/engine/event-hooks.md` to v3.1
- TDD: 14 tests in `test/verbs/test-open-close-hooks.lua`
- Zero regressions across full test suite
- Commit: d610975

### Prior Work: #149 Drawer Accessibility Fix (2026-03-28)

**#149 TDD Bug Fix — Search Drawer Items Not Accessible to Get:**
- Root cause: `_fv_surfaces` in `verbs/init.lua` never searched root-level contents of objects with surfaces
- Nightstand has `.surfaces.top` but drawer lives in `.contents` (not any surface zone)
- `_fv_surfaces` had two branches: (1) search surface zones, (2) search non-surface containers — neither reached `nightstand.contents`
- Fix: Added recursive `_search_accessible_chain` inside `_fv_surfaces` that traverses root contents of surface-objects, following `accessible ~= false` through nested containers (depth-limited to 3)
- TDD: 9 tests in `test/search/test-drawer-accessibility.lua` — 3 were red before fix
- Wardrobe→sack regression test passes (surface-based path unchanged)
- Zero regressions across full test suite
- Commit: 222a4f3

### Prior Work: Manifest Completion (2026-03-24)

**#78 P0 Game Crash Fix:**
- Diagnosed crash in `flatten_instances()` during multi-room loading
- Root cause: Type guard missing on FSM state property traversal
- Fix: Added type checks before recursive flattening
- Result: ✅ Game loads multi-room setup without crash, all room transitions work
- Commit: b867eb6
- Impact: Unblocks entire multi-room expansion gameplay

**Manifest Status:** ✅ COMPLETE (orchestration log: `.squad/orchestration-log/2026-03-24T18-50-00Z-bart.md`)

### Prior Work: Effects Pipeline Compatibility Audit (2026-03-24)
- Full inventory audit of all 79 objects in `src/meta/objects/`
- Identified 3 **BROKEN** objects with injury verbs but no pipeline routing
- Confirmed 2 correctly migrated objects (poison-bottle, bear-trap)
- Generated migration report → now merged into D-AUDIT-OBJECTS decision
- Priority: knife (P1 critical), glass-shard (P1 critical), silver-dagger (P2 high)
- Estimated migration effort: ~4.5 hours total
- Status: Report merged; unblocks #50 play-test

### Wayne Contributions Tracker (2026-03-24)
- Created 516-line tracking document for Wayne's Senior Engineer contributions
- Documented design decisions, architectural insights, course corrections, quality gates
- Fulfills Wayne Directive (2026-03-23T22-00-56Z)
- Living document at `.squad/contributions/wayne-contributions-log.md`
- Enables future team retrospectives and contribution analysis

### Effects Pipeline Documentation (EP6) ✅ COMPLETE (2026-03-23)
- Updated Effects Pipeline architecture docs to v2.0
- Updated Trap System architecture docs to v2.0
- Documented new pipeline pattern for maintainers
- Cross-referenced refactored effects (poison-bottle, bear-trap)
- Status: Ready for merge with EP1-EP10 deliverables

**Design Philosophy:** No special-case objects. Everything expressible through .lua metadata (FSM, timers, prerequisites). Engine stays generic; objects own their behavior.

**Decisions Authored:** 45+ (D-14 through D-CLOCK001, including architecture, engines, objects, spatial, UI, GOAP)

## Archives

- `history-archive-2026-03-21.md` — Early sessions
- `history-archive-2026-03-22.md` — Mid sessions
- `history-archive-2026-03-20T22-40Z-bart.md` — Full archive (2026-03-18 to 2026-03-20T22:40Z): engine foundation, verb system, parser pipeline, SLEEP, wearables, FSM engine, composite objects, spatial system, multi-room engine, GOAP Tier 3, terminal UI, timed events, 32+ bug fixes across 7 passes

- `history-archive.md` — Entries before 2026-07-16 (2025-07-18 to 2026-03-30)

## Learnings

### Mutation Graph Analysis (2026-07-28)
- 6 distinct mutation mechanisms in the codebase: file-swap (becomes), FSM in-place (mutate), spawns (from mutations and transitions), crafting (becomes), tool depletion (when_depleted), and dynamic (runtime-generated)
- `becomes = nil` is intentional destruction, NOT a broken link — must be excluded from edge extraction
- 4 known broken edges found: poison-gas-vent-plugged (missing), wood-splinters ×3 (missing)
- Only 1 dynamic mutation exists: paper.lua's write verb — unbounded (player input generates code)
- Template inheritance (e.g., sheet.lua → blanket.lua) means mutations can be inherited — but current objects all redeclare inherited mutations explicitly, so template merging can be deferred
- matchbox ↔ matchbox-open is a valid toggle cycle (not a bug)
- No `when_depleted` fields exist yet — pen/pencil/needle/knife all have `consumes_charge = false`
- sandbox loading must handle objects with embedded Lua functions (on_look, etc.) — use loadfile + restricted env with setfenv
- Graph linter belongs in test/meta/ (new directory), registered in test_dirs alongside parser/inventory/etc.
- Plan delivered to plans/mutation-graph-linter-plan.md — ~240-260 estimated tests across 7 suites

### NPC+Combat Implementation Plan Structure (2026-07-28)
- Unified plan merges NPC Phase 1 and Combat Phase 1 into 6 waves with 6 gates
- Wave/gate pattern: each wave is a batch of parallel agent work, each gate is a binary pass/fail checkpoint
- File ownership map prevents conflicts: no two agents touch the same file in any wave
- NPC Phase 1 (WAVE-1→3) must ship BEFORE Combat Phase 1 (WAVE-4→6) — creature autonomy first, then physical combat
- Key integration seam: `creatures.get_creatures_in_room()` and `creatures.emit_stimulus()` are the two functions Combat Phase 1 consumes from NPC Phase 1
- Creature tick slots into game loop after fire propagation and before injury tick (line ~633 in current loop/init.lua)
- injuries.inflict() already supports body location parameter — Combat Phase 1 uses it directly
- Material registry auto-discovers .lua files — no registration code needed for new tissue materials
- Test runner needs `test/creatures/` and `test/combat/` directories added to its scan list
- Stimulus emission uses pcall-guarded optional require — zero coupling when creatures module absent

### Lark Grammar: Lua Object Parsing is Tractable (2026-07-28)
- Python + Lark (Earley parser) successfully parses ALL 83 object .lua files with a ~30-line grammar
- Three-phase pipeline: tokenize → preprocess (strip preamble, neutralize functions) → Lark parse
- 82/83 objects are pure data tables (`return { ... }` with literals, nested tables, functions-as-values)
- 1/83 (wall-clock.lua) uses programmatic generation — builds tables with `for` loops, references locals. Handled via `ident_ref` rule (bare identifier as value), treated as opaque
- Function bodies (50%+ of objects) are safely replaced with `__FUNC__` placeholders — meta-check validates DATA, not logic
- Nightstand's local function preamble correctly handled by block-depth tracking in the preprocessor
- Key limitation: objects with `ident_ref` values can't be fully validated statically — only runtime Lua knows the computed value
- Decision filed: D-LARK-GRAMMAR
- Deliverable: `scripts/meta-check/lua_grammar.py`

### Loader Is a Sandbox Executor, Not a Validator (2026-07-28)
- `src/engine/loader/init.lua` checks 3 things: Lua compilation, runtime execution, return-type-is-table
- Template/instance resolution checks existence of template and base class by GUID
- The loader checks ZERO field-level properties: no required fields, no type validation, no FSM consistency, no sensory completeness, no material validity, no cross-reference integrity
- An object with only `{ guid = "x" }` loads without error — meta-check must catch everything else
- This minimalism is deliberate and correct for the engine (fast, permissive, forward-compatible)
- The entire validation burden falls on pre-deploy tooling (meta-check) — this is the right architectural layer
- Deliverable: `resources/research/meta-compiler/existing-validation-audit.md`

### Plan Review Fixes: 16 Issues Resolved (2026-07-28)
- Team review of `plans/npc-combat-implementation-plan.md` surfaced 8 blockers + 8 concerns — Wayne treated all 16 as blockers
- Key architecture decisions embedded in fixes: hybrid stance combat (auto-resolve + interrupts), required combat/narration.lua split, WAVE-0 pre-flight for test runner registration
- Player table confirmed at `src/main.lua` lines ~305-324 — this is where body_tree goes in WAVE-4
- Documentation as gate requirement: "No phase ships without its docs" — Brockman writes 9 docs total across WAVE-3 and WAVE-6
- Phase 1 escalation policy: 1x gate failure → escalate to Wayne (not 2x) because first implementation + parallel agents = harder diagnosis
- Gate failure protocol now formalized: re-gate tests only failed items, lockout policy prevents same agent thrashing on same bug
- Combat sub-loop runs inside main game loop, not as separate loop — verb handler calls io.read() for stance, combat.run_combat() returns control after resolution
- Decision filed: `.squad/decisions/inbox/bart-plan-review-fixes.md`

### Effect Pipeline Architecture (2026-07-26)
- Structured effect tables (`{ type = "inflict_injury", ... }`) already exist in Flanders' objects (poison-bottle.lua, bear-trap.lua) — the objects are ahead of the engine
- The taste verb handler bypasses the injury system entirely — calls `os.exit(0)` inline instead of `injuries.inflict()`. The pipeline migration fixes this.
- `traverse_effects.lua` already implements the exact same registry pattern (`register(type, handler)` → `process()`) — good validation that the pattern works; future convergence is natural
- The legacy normalization map (`"poison"` → structured table) guarantees zero-breakage migration. Objects never need to change simultaneously with the engine.
- Before/after interceptors (Inform-style) cost zero overhead when empty — infrastructure can ship on day one without performance concerns

## Recent Updates

### Issue #135 / #132: Compound `find X, get X` corrupts context (2026-07-28)
**Status:** ✅ FIXED  
**Requested by:** Wayne "Effe" Berry  
**Commit:** f92435e

**Root cause:** `containers.open()` in `src/engine/search/containers.lua` set `is_open = true` and `open = true` but did NOT set `accessible = true`. The `find_visible` function checks `obj.accessible ~= false` before searching container contents. So after search traversal opened a closed container (like the matchbox), the container's contents remained invisible to `get`/`take` commands.

**Fix:** One-line addition: `object.accessible = true` in `containers.open()`. When the search system opens a container during traversal, the accessible flag is now set, making contents visible to subsequent verb handlers.

**TDD approach:** 14 tests written first in `test/search/test-compound-search-get.lua`:
- `containers.open` sets accessible flag (root cause validation)
- Search results persist (container accessible after search)
- Separate find + get works
- Compound comma split parsing
- Compound "and" split + pronoun resolution
- No state corruption across turns
- Search integrity (no content duplication/loss)

**All 78 test files pass, zero regressions.**

### Session: EP6 — Update Architecture Docs to Match Implementation (2026-07-27)
**Status:** ✅ COMPLETE  
**Requested by:** Wayne "Effe" Berry

**Task:** Update `effects-pipeline.md` and `event-hooks.md` to reflect what was actually built in `src/engine/effects.lua` and the poison bottle refactor. Eliminate aspirational content; docs must match shipped code.

**Deliverables:**
- `docs/architecture/engine/effects-pipeline.md` → Version 2.0 (Implementation Record)
- `docs/architecture/engine/event-hooks.md` → Version 2.0 (Updated for Implementation)

**Key Changes (effects-pipeline.md):**
- Documented actual public API: `process`, `normalize`, `register`, `unregister`, `has_handler`, `add_interceptor`, `clear_interceptors`
- Documented all 5 shipped handlers: `inflict_injury` (pcall-safe), `narrate`, `add_status`, `remove_status`, `mutate` (with target resolution)
- Added `effects_pipeline = true` flag documentation
- Added `pipeline_effects` array and `pipeline_routed` flag patterns
- Real poison bottle code replaces hypothetical examples
- Migration phases marked as completed
- New Appendix B: full poison bottle migration walkthrough

**Key Changes (event-hooks.md):**
- Hook taxonomy updated: `trans.effect`, `on_taste_effect`, `on_feel_effect` now show "Routes through effects.process()" 
- Gap analysis: 2 of 6 gaps marked RESOLVED (unified processor + effect standardization)
- Poison bottle shown as completed migration reference with actual shipped code
- New Section 9.3: step-by-step migration guide for adopting the pipeline
- Cross-references updated to include `effects.lua` and `poison-bottle.lua`

**Commit:** `f3205d7` — pushed to main

### Session: Effects Pipeline Architecture Document (2026-07-26)
**Status:** ✅ COMPLETE  
**Requested by:** Wayne "Effe" Berry

**Task:** Write comprehensive architecture document for the unified Effect Processing Pipeline.

**Deliverable:** `docs/architecture/engine/effects-pipeline.md`

**Key Design Decisions:**
- Objects declare structured effect tables; pipeline dispatches to subsystem handlers by `type` field
- Before/after interceptors enable armor reduction, immunity cancellation, achievement triggers
- Legacy string effects (`"poison"`, `"cut"`) normalized automatically — backward compatible
- Day-one handlers: `inflict_injury` and `narrate`. Others registered as subsystems arrive.
- ~120 lines new code, ~60 lines of inline verb handler code deleted (net reduction)
- Fixes taste verb `os.exit(0)` bug — all injury paths go through `injuries.inflict()`

**Decision filed:** `D-EFFECTS-PIPELINE` in `.squad/decisions/inbox/bart-effects-pipeline-arch.md`

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

### Session: on_traverse Exit-Effect Engine (Puzzle 015 support)

**Status:** ✅ COMPLETE
**Outcome:** New extensible `on_traverse` exit-effect system implemented. First handler: `wind_effect` for draft-extinguish mechanic.

**Deliverables:**
1. `src/engine/traverse_effects.lua` — New module: type-dispatched effect handler registry. Registered handlers fire when a player moves through an exit with an `on_traverse` field. Ships with built-in `wind_effect` handler.
2. Integration in `src/engine/verbs/init.lua` — `traverse_effects.process(exit, ctx)` called in `handle_movement` BEFORE player location changes, AFTER exit validation passes.
3. `test/parser/test-on-traverse.lua` — 12 tests: normal exits unchanged, wind extinguishes lit items, ignores unlit/already-extinguished, spares wind-resistant, items not in extinguishes list unaffected, custom types registerable, edge cases safe.

**Architecture:**
- `traverse_effects.register(type, handler_fn)` — open for new effect types (water crossings, narrow passages, etc.)
- `traverse_effects.process(exit, ctx)` — single integration point in movement handler
- Wind handler checks `extinguishes` list by obj.id and keywords, respects `wind_resistant` property, uses FSM transition (extinguished or unlit fallback)
- All 51 tests pass (existing 39 + new 12)

## Learnings (on_traverse)

- Exit effects fire BEFORE player moves — this lets the effect reference the origin room's context and print messages in narrative order (effect → arrival)
- The `extinguishes` list matches against both object IDs and keywords, making room metadata flexible (author can use "candle" regardless of whether that's the id or a keyword)
- Wind-resistance check is on the object itself (`obj.wind_resistant`), not on the exit metadata — this keeps the data model clean (objects own their properties, exits declare the environmental condition)
- Type-dispatch pattern (`handlers[effect.type]`) is the right abstraction — each effect type can have completely different fields without the engine caring

## Learnings (BUG-060: on_traverse format mismatch)
- Schema mismatches between engine and room data are insidious — both sides pass their own unit tests but integration fails silently. The engine's process() just returned early when ffect.type was nil (Moe's format had no 	ype field).
- Fix: Added 
ormalize_effect() to accept BOTH flat format ({ type = "wind_effect", ... }) and nested format ({ wind_effect = { ... } }). The nested format is auto-detected by finding a single table-valued key. Ambiguous cases (multiple table keys) are safely rejected.
- This is better than forcing Moe to rewrite room data — room authors shouldn't need to know engine internals, and the nested format is arguably more readable for non-engineers.
- Added 3 tests (nested extinguish, nested spared, ambiguous rejection). Total test count: 54.

## Learnings (Engine Hook Architecture Design)

### Session: Engine Hook Architecture Design (2026-07-22)
**Status:** ✅ COMPLETE (Design only — no code)
**Outcome:** Formalized the engine hook system as a named, documented architecture separate from FSM.

**Deliverables:**
1. `docs/architecture/engine/event-handlers.md` — Full architecture doc: naming justification ("Engine Hooks"), 12 hook types cataloged with metadata examples, registry pattern, integration points, implementation guide, design rules, migration plan from traverse_effects.lua.
2. `D-HOOK001` decision filed — Covers naming, architecture, FSM relationship, migration path.

**Key Design Decisions:**
- Named "Engine Hooks" (not "Verb Handlers" or "Event Handlers") — precise about origin (engine) and mechanism (hooks into game loop)
- Same registry pattern as on_traverse: `register(hook_type, subtype, handler_fn)` + `dispatch(hook_type, effect, ctx)`
- One-way dependency: hooks can trigger FSM, FSM cannot trigger hooks (prevents circular dispatch)
- Unknown subtypes silently ignored (forward-compatible metadata)
- Content authors declare hooks in metadata; engine devs implement handlers — clean separation of concerns

**Hooks Cataloged (12 total):**
- `on_traverse` (implemented), `on_enter_room`, `on_leave_room`, `on_pickup`, `on_drop`, `on_examine`, `on_combine`, `on_use`, `on_timer`, `on_first_visit`, `on_npc_react`, `on_death`

**Learnings:**
- The on_traverse pattern was already the right abstraction — generalizing it to a unified hook registry is a clean extension, not a redesign
- FSM vs hooks distinction is critical: FSM is data-driven per-object state machines (content authors), hooks are engine-wide event handlers (engine devs). They collaborate but don't overlap.
- Timing (before-move vs after-move) matters for narrative order and must be documented per hook type — learned this from on_traverse firing before player moves
- The normalize_effect() lesson from BUG-060 (accept both flat and nested formats) should be baked into the generic dispatcher from day one

## Learnings (Player Health & Injury Architecture)

### Session: Player Health & Injury Architecture Design (2026-07-22)
**Status:** ✅ COMPLETE (Design only — no code)
**Outcome:** Full architecture for player health, damage, injuries, and healing. Three docs shipped.

**Deliverables:**
1. `docs/architecture/player/README.md` — Player system overview linking all subsystems (model, movement, sensory, health, injuries)
2. `docs/architecture/player/health.md` — Health tracking, damage application pipeline, healing types, death condition, per-turn update loop
3. `docs/architecture/player/injuries.md` — Injury FSM system with three damage types (one-time, over-time, degenerative), full bleeding/poisoned/bruise/infection examples, healing interactions, lifecycle

**Key Design Decisions (6 filed as D-HEALTH001–005, D-INJURY001–006):**
- Damage encoded on objects, not engine — object authors (Flanders) control damage values in metadata
- Injuries are FSMs in `src/meta/injuries/` — same pattern as object FSMs (states, transitions, timed_events)
- Three injury types: one-time (bruise), over-time (bleeding), degenerative (infection with escalating damage)
- Healing items declare target injury type — bandage targets "bleeding", antidote targets "poisoned"
- Injury FSM reuses object FSM engine — no duplicate state machine code
- Fatal injury states trigger death independently of health value

**Learnings:**
- The object FSM pattern scales cleanly to injuries — same states/transitions/timers, just stored in player.injuries[] instead of registry
- Degenerative damage needs a cap (max_damage) — without it, infections become instantly fatal after enough turns
- Dual-sided healing declaration (object declares targets_injury, injury declares healing_interactions) provides both convenience and safety
- The engine loop needs a clear phase order: verb dispatch → object tick → injury tick → death check. Injury ticking after object ticking prevents one-frame desync

### Session: Player Architecture Revision — Derived Health, First-Class Inventory (2026-07-22)
**Status:** ✅ COMPLETE
**Directive:** Wayne directive 2026-03-21T19:17Z — Player architecture refinements

---

## Learnings

## Learnings

- **TUI false positives are a category of testing bug.** ANSI escape codes in split-screen UIs can make engine responses invisible to automated terminal readers. Always provide a headless bypass for automated testing.
- **`--no-ui` was insufficient.** It disabled the TUI but still emitted prompt characters and verbose banners that pollute pipe output. Headless mode is a distinct concern from "no TUI" — it's about clean, parseable, delimited output for machine consumption.
- **Response delimiters (`---END---`) are essential for pipe-based testing.** Without them, there's no way to tell where one response ends and another begins in a multi-command session.
- Makes CPU-bound hangs architecturally impossible regardless of game state

**Files Changed:** loop/init.lua, parser/init.lua, preprocess.lua, search/init.lua, main.lua
**Tests:** All 37 files pass (0 failures)

**Applied Result:**
- Rejected formal Decision Matrix (idiom expansion > framework)
- Rejected Humanizer Layer (narrator + error message polish > wrapper)
- Rejected Orchestration Framework (table-driven pipeline > engine)

**Takeaway:** The gap in parser coverage is engineering discipline, not missing patterns. Coverage = width (more synonyms) + tone (better errors) + context (discovery memory). Architecture IS solid; execution is what matters.

**What Changed:**
1. **health.md** — Full rewrite. Health is now DERIVED (max_health - sum(injury.damage)), not stored. Removed player.health field. Removed old damage pipeline that mutated health directly. Healing now removes injury damage instead of "adding HP." Death check uses compute_health().
2. **injuries.md** — Full rewrite. Injury-specific healing: antidote-nightshade cures poisoned-nightshade, NOT poisoned-spider-venom. Dual-side encoding (object cures + injury healing_interactions). Injury types are now specific (e.g., poisoned-nightshade.lua not poisoned.lua). Each injury carries .damage field for derived health computation.
3. **README.md** — Updated canonical player.lua structure. Added inventory as first-class nested array. Removed health field. Added inventory subsystem link. Revised design philosophy (7 principles).
4. **inventory.md** — NEW file. First-class inventory architecture: nested array in player.lua, container nesting, engine mutations (pickup/drop/put-in/take-out), recursive traversal, inventory verb reads directly from array, integration with healing and verb systems.

**Key Architectural Shifts:**
- player.health field is GONE. Health is computed on read: max_health - sum(injury.damage).
- Healing doesn't "add HP" — it removes injuries, which reduces the damage sum, which raises derived health.
- Inventory is a nested array in player.lua. Engine mutates directly. No external system.
- Injury types are specific, not generic. poisoned-nightshade not poisoned. Enables injury-specific healing.
- player.lua is THE single source of truth. Engine reads/mutates only this file.

---

### Session: Inventory Instance Refactor (2026-07-22)
**Status:** COMPLETE
**Outcome:** Inventory now stores object INSTANCES (tables) instead of string IDs

**What Changed:**
- player.hands[i] stores the actual object table (same reference as registry) instead of a string ID
- Each picked-up object gets an instance_id (monotonic counter) to distinguish duplicates
- Added _hid(hand) and _hobj(hand, reg) backward-compatible accessors throughout the engine
- Container contents inside bags preserve nested structure on pickup

**Files Modified (engine only, no meta .lua changes):**
1. src/engine/verbs/init.lua - Added instance helpers; updated take/drop/put/inventory/wear/remove handlers + all internal helpers
2. src/engine/ui/presentation.lua - get_all_carried_ids handles object instances in hands
3. src/engine/loop/init.lua - Post-command FSM tick phase extracts IDs from hand instances
4. src/engine/parser/goal_planner.lua - All hand-reading functions updated
5. src/main.lua - Burnable tick handler reads object instances from hands
6. test/inventory/test-inventory.lua - Updated place_in_hand helper + all 60 assertions

**Test Results:** 126/126 pass (60 inventory + 35 parser + 4 context + 15 on-traverse + 12 search-order)

**Architectural Decision:** D-INV007 - Hands store object instances (tables), not string IDs

### Session: Injury Engine — Pass 2 (2026-07-25)
**Status:** ✅ COMPLETE
**Requested by:** Wayne Berry
**Outcome:** Full injury engine with derived health, per-turn ticking, auto-healing, death detection, and end-to-end poison bottle wiring.

**Deliverables:**

1. **`src/engine/injuries.lua`** — Core injury engine module (~230 lines)
   - `compute_health(player)` — Derived health: `max_health - sum(injury.damage)`
   - `inflict(player, injury_type, source)` — Creates injury instance from meta definition, prints symptom
   - `tick(player)` — Per-turn processing: damage accumulation, degenerative scaling, auto-healing, death check
   - `try_heal(player, healing_object, verb)` — Healing via exact injury type matching + FSM transition
   - `list(player)` — Injury verb output with symptom text and treatment hints
   - `find_by_type(player, type)` — Lookup by exact injury type
   - `register_definition()` / `clear_cache()` — Test injection support

2. **`src/meta/injuries/poisoned-nightshade.lua`** — First injury FSM definition
   - Over-time toxin: 15 initial + 8/tick damage
   - States: active → treated → healed (+ fatal terminal)
   - Healing interaction: antidote-nightshade transitions active → treated
   - Auto-heal after 3 turns in treated state

3. **Player state wired** (`src/main.lua`)
   - Added `player.max_health = 100` and `player.injuries = {}`
   - Health is derived, never stored

4. **Game loop wired** (`src/engine/loop/init.lua`)
   - Injury tick fires after on_tick phase each command
   - Death check: if `compute_health() <= 0` → game over
   - `injuries`/`injury`/`wounds`/`health` added to no_noun_verbs

5. **Verbs wired** (`src/engine/verbs/init.lua`)
   - `injuries` verb: lists active injuries with symptom text + derived health display
   - Aliases: `injury`, `wounds`, `health`
   - `apply` verb: "apply X to Y" or "apply X" — finds healing item, matches cures field, heals
   - Alias: `treat`
   - `drink` (poison bottle): now inflicts `poisoned-nightshade` through injury system instead of instant death
   - Help text updated with injury/apply verbs

6. **Test suite** (`test/injuries/test-injury-engine.lua`) — 49 assertions
   - compute_health: 4 tests (full, reduced, additive, clamped)
   - inflict: 10 tests (creation, type, damage, source, state, message)
   - tick: 9 tests (accumulation, multi-tick, stacking/double drain)
   - auto-healing: 5 tests (bruise heals after N turns)
   - death detection: 3 tests (lethal tick, non-lethal)
   - try_heal: 6 tests (success, transition, wrong cure)
   - treated auto-heal: 5 tests (treated → removed after timer)
   - list: 4 tests (no injuries, header, name, hint)
   - safe with no injuries: 2 tests
   - Test runner updated to scan `test/injuries/` directory

**Test Results:** 175/175 pass (49 injury + 60 inventory + 35 parser + 4 context + 15 on-traverse + 12 search-order)

**Architectural Decisions:**
- D-INJURY010: Injury engine is a standalone module (`engine/injuries.lua`), not embedded in verbs or loop
- D-INJURY011: Injury definitions loaded via `require("meta.injuries." .. type)` with test injection via register_definition()
- D-INJURY012: Poison bottle drink handler wires through injury system (inflict_injury) instead of legacy instant death

### Session: Self-Infliction Verbs + Body Targeting + Bandage Apply/Remove (2026-07-26)
**Status:** ✅ COMPLETE
**Outcome:** Full stab/cut/slash self system, injury location tracking, bandage dual-binding lifecycle

**Engine Changes (`src/engine/injuries.lua`):**
- `inflict()` accepts optional `location` (body area) and `override_damage` (weapon-supplied) parameters
- `find_by_id()` — lookup injury by instance ID for dual-binding
- `resolve_target()` — 5-priority injury targeting (ID → display name → body location → type → ordinal)
- `format_injury_options()` — disambiguation prompt for multiple treatable injuries
- `apply_treatment()` — dual-bind bandage↔injury, transition both FSMs, stop damage drain
- `remove_treatment()` — unbind both sides, revert injury to active, bandage to soiled
- `compute_total_drain()` — sum damage_per_tick across all injuries
- `list()` now shows body location ("bleeding wound on your left arm") and [treated] marker

**Verb Changes (`src/engine/verbs/init.lua`):**
- `stab` verb: new handler for self-infliction, reads weapon `on_stab` profile
- `cut` verb: rewritten — tries self-infliction first (via `on_cut`), falls through to world-object cutting
- `slash` verb: separate handler (no longer aliased to cut), reads `on_slash` profile, falls through to cut for world objects
- Aliases: jab/pierce/stick → stab, slice/nick → cut, carve → slash
- Self-infliction shared logic: body area parsing, weighted random selection, damage modifiers (torso ×1.5, head ×2.0), weapon profile reading, %s description substitution
- `apply` verb: rewritten to support bandage-style items with `cures` + FSM. Uses `resolve_target()` for "apply bandage to left arm". Falls back to legacy `try_heal` for non-bandage items.
- `remove` verb: extended to detect applied bandages (`applied_to` set) and call `remove_treatment()` before checking worn items/detachable parts

**Weapon Objects Updated:**
- `silver-dagger.lua`: Added `on_stab` (dmg 8, bleeding), `on_cut` (dmg 4, minor-cut), `on_slash` (dmg 6, bleeding)
- `knife.lua`: Added `on_stab` (dmg 5, bleeding), `on_cut` (dmg 3, minor-cut)
- `glass-shard.lua`: Added `on_cut` (dmg 3, minor-cut, self_damage), `provides_tool`

**Tests Added:** 105 new tests in `test/injuries/test-self-infliction.lua`:
- inflict with body location (5 tests)
- override damage from weapon (4 tests)
- list shows location (4 tests)
- find_by_id (4 tests)
- resolve_target: auto-target, disambiguation, by location, by type, by ordinal, no injuries, treated skip, display name (13 tests)
- apply_treatment: dual binding, minor-cut, drain stops (12 tests)
- remove_treatment: unbind, soiled state, non-applied error, orphan case (11 tests)
- bandage exclusivity (2 tests)
- compute_total_drain (4 tests)
- weapon damage encoding: profiles, substitution, missing profiles (10 tests)
- body area damage modifiers (3 tests)
- random body area weighted selection (11 tests)
- format_injury_options (5 tests)
- full lifecycle: inflict → tick → bandage → tick → remove → tick (14 tests)
- treated injury marker in list (1 test)

**Test Results:** 280/280 pass (49 injury-engine + 105 self-infliction + 60 inventory + 35 parser + 4 context + 15 on-traverse + 12 search-order)

**Architectural Decisions:**
- D-INJURY013: Self-infliction verbs read weapon `on_stab`/`on_cut`/`on_slash` damage profiles — engine has zero hardcoded damage values
- D-INJURY014: Body area damage modifiers are engine-side (×1.0 baseline, ×1.5 torso/stomach, ×2.0 head) — weapons don't know about body risk
- D-INJURY015: Bandage dual-binding uses mutual references (bandage.applied_to ↔ injury.treatment) — both sides know about the relationship
- D-INJURY016: Bandage removal reverts injury to active state and resumes damage_per_tick — premature removal has consequences
- D-INJURY017: Treatment targeting uses 5-priority resolution (ID/name/location/type/ordinal) with auto-target for single-injury cases

## Learnings

## Learnings

### Session: Engine Hooks — Injury Pipeline Architecture (2026-07-22)
**Status:** ✅ COMPLETE
**Requested by:** Wayne "Effe" Berry

**Task:** Deep architecture analysis of how .lua object files hook into the engine to cause injuries. Two reference cases: consumable → injury (poison bottle), contact → injury (bear trap).

**Deliverable:** `docs/architecture/engine/event-hooks.md` + decision `bart-engine-hooks.md`

**Key Findings:**
- The engine has a robust injury system (`injuries.inflict()`, 6 types, FSM-based progression) and a designed hook framework (12 hooks cataloged in `about.md`), but only `on_traverse` is implemented.
- The critical missing piece is a **unified Effect Processing Pipeline** (`effects.lua`). Today, verb handlers interpret effect strings inline — `effect = "poison"` is a string tag that the drink handler must know how to map to `injuries.inflict("poisoned-nightshade")`. Every new injury-causing object requires verb handler edits.
- Three ad-hoc effect patterns exist: (A) transition `effect` strings, (B) `on_{verb}_effect` strings on states, (C) structured `on_stab`/`on_cut` tables. Pattern C is the most mature and closest to the proposed design.
- **Consumable → Injury needs no new hooks.** FSM transition `effect` field + `effects.process()` handles poison, bad food, all consumables.
- **Contact → Injury on take/feel also needs no new hooks.** Transition effects and sensory `on_feel_effect` already provide the trigger points.
- **Spatial traps (pit, gas) need `on_enter_room` hook.** This is the only net-new hook required for the injury cases analyzed.
- Per-object effect ownership (objects declare effects, engine processes them) is correct and should remain the pattern. Per-verb effect handling was rejected.

**Decisions Made:** bart-engine-hooks (Effect Processing Pipeline for injuries)

---

### Phase A1: Armor System Architecture (684 lines)
- **Status:** DELIVERED
- **File:** `docs/architecture/engine/armor-system.md`
- **Scope:** Complete armor slot system, damage negation calculations, durability tracking, FSM transitions, material integration, wearable verb integration, inventory management
- **Dependency:** Nelson (A3) writing TDD tests as specification

### Phase D1: Brass Spittoon Design Doc
- **Status:** DELIVERED
- **File:** `docs/objects/brass-spittoon.md`
- **Scope:** Aesthetic design, mechanics, flavor text, integration patterns
- **CBG Carry-over:** Chest design doc verified complete (`docs/objects/chest.md`)

### Search Container Fixes (P0 #135 + #132)
- **Decision:** D-SEARCH-ACCESSIBLE merged into decisions.md
- **Fix:** Search now sets `object.accessible = true` when opening containers
- **File:** `src/engine/search/containers.lua` (1-line fix)
- **Tests:** 14 new tests, all passing, zero regressions
- **Commit:** Referenced in orchestration log

## Learnings

## Learnings

### Session: Object Instancing Factory — Issue #105 (2026-07-22)
**Status:** ✅ COMPLETE
**Requested by:** Wayne "Effe" Berry

**Deliverables:**
- New module: `src/engine/factory/init.lua` — Core Principle 5 instancing factory
- `factory.create_instances(base, count, options)` creates N independent deep-copied instances from one base definition
- `factory.create_one(base, overrides)` convenience wrapper for single instances
- Pure Lua UUID v4 generator (`factory.generate_guid()`) — zero external dependencies
- Each instance gets `instance_guid` (runtime identity), `type_id` (traceability to base), sequential `id`
- Supports global overrides, per-instance overrides, location defaults
- 24 tests in `test/objects/test-instancing-factory.lua`

**Key Notes:**
- Factory is self-contained (local `deep_copy` + `deep_merge`) — no coupling to loader internals
- Base object is never mutated — all instances are fully independent deep copies
- `guid` field cleared on instances (belongs to base); `instance_guid` is the runtime identifier
- Pattern formalizes what room files already do implicitly with the `instances` array + `type_id` references
- GUID generator uses `math.random` seeded with `os.time() + os.clock()` — sufficient for single-process game runtime

**Test Results:** 111 test files, 0 regressions

## Learnings

### Session: Player Canonical State — Issue #104 (2026-07-22)
**Status:** ✅ COMPLETE

- Player state was 95% canonical already — only `visited_rooms` was orphaned on `ctx` root
- Clean migration: move field to `ctx.player`, update 3 engine sites + 13 test mock sites
- `ctx.current_room` is a convenience reference (room object), NOT player state — the canonical location is `ctx.player.location` (room ID string). Decided to leave `ctx.current_room` as-is since it's an engine convenience, not player data.
- Test mock contexts are the biggest blast radius for state migrations — always grep tests for the old pattern

## Learnings

## Learnings

### Session: Linter Phase 2 — GUID Cross-Ref & EXIT Validation (2026-07-29)
**Status:** ✅ COMPLETE
**Branch:** squad/linter-phase2

**What was built:**

1. **GUID-01 (error)** — Room instance type_id must resolve to a known object GUID. Recursively walks the full instances tree (on_top, contents, nested, underneath). Normalizes both braced and bare GUID formats. This is the "27 fabricated GUIDs" rule Wayne requested via issue #241.

2. **GUID-02 (warning)** — Orphan object detection. Fires when rooms exist but an object's GUID isn't referenced by any room instance. Found 21 orphan objects on first run (mutation targets, healing items, traps not yet placed).

3. **GUID-03 (error)** — Duplicate instance id within same room. Catches copy-paste errors in room instance arrays.

4. **EXIT-01 (error)** — Exit target must reference a valid room file. Found 4 exits pointing to non-existent rooms (level-2, manor-kitchen, manor-west, manor-east — future content).

5. **EXIT-02 (warning)** — Bidirectional exit consistency. Warns when room A exits to B but B has no return exit to A.

**Bug fix:** `_detect_kind()` only matched `src/meta/world/` for rooms, but the actual directory is `src/meta/rooms/`. Added the `rooms/` pattern. This was a silent bug — rooms were classified as "unknown" and skipped room-specific validation (RM-01, SN-01 for rooms, and all cross-ref checks that depend on room_ids).

**Architecture decisions:**
- GUID normalization strips `{}` from both sides (object GUIDs are braced, room type_ids are usually bare but sometimes braced)
- GUID-02 fires only when rooms exist in the scan — prevents false positives when linting objects-only
- EXIT-02 only checks bidirectional consistency for rooms that ARE in the scan (doesn't flag exits to rooms outside the level)

**Key files:**
- scripts/meta-lint/rule_registry.py — 5 new rules (GUID-01/02/03, EXIT-01/02)
- scripts/meta-lint/lint.py — ~120 lines of validation logic, _detect_kind fix
- test/meta-check/test_phase2.py — 20 tests (6 registry, 14 integration)

**Test results:** 20/20 Phase 2 tests pass, Lua test suite unaffected.


## Learnings

## Learnings

### Portal Phase 2: Bidirectional FSM Sync (2026-07)

**Problem:** Portal objects support bidirectional_id for paired doors (bedroom/hallway), but fsm.transition() never propagated state changes to the partner portal. Also, movement error messages for barred and unbarred states did not match expected patterns.

**Fix 1 -- Bidirectional sync in FSM engine (fsm/init.lua):**
- Added sync_bidirectional(registry, obj) as a local function in the FSM module
- After every successful fsm.transition(), if the object has portal.bidirectional_id, scans registry:list() for the partner and applies the same state via apply_state()
- This is generic -- reads portal metadata only, no object-specific logic (Principle 8)
- Lives in FSM engine, not in verb handlers -- so ANY verb that triggers an FSM transition automatically syncs

**Fix 2 -- Portal blocked-movement messages (movement.lua):**
- barred state now prints 'is barred.' (was incorrectly grouped with closed)
- unbarred state now prints 'is closed.' (was falling through to generic 'blocks your path')

**Key architectural decision:** Bidirectional sync belongs in the FSM engine, not in individual verb handlers. This ensures consistency regardless of which verb triggers the transition.

---

## 2026-03-26T15:30Z: NPC Plan Combat Alignment Complete — CBG Coordination

**What:** Comic Book Guy applied 13 alignment fixes to `plans/npc-system-plan.md`. Coordination completed with combat system plan. All conflicts resolved.

**Your Work Ahead:**
- **Creature tick system:** Handle deferred `attack` action (fallback to flee in Phase 1; Combat FSM integration in Phase 2)
- **Combat FSM integration:** Phase 2+ after Combat Phase 1 engine is ready
- **Portal Phase 2 Room Wiring:** Already complete (2026-07-28 session) — reference for room/exit pattern

**Decision Filed:** D-NPC-COMBAT-ALIGNMENT, D-COMBAT-NPC-PHASE-SEQUENCING — decisions.md updated.

**Impact:** NPC system plan 100% aligned with combat plan. Creature autonomy focus in Phase 1. Combat systems deferred to Phase 2+.

---

## 2026-07-30T00:00Z: WAVE-2 — Creature Engine + Game Loop Integration

**Status:** ✅ COMPLETE
**Branch:** main (direct commit)

**What was built:**

1. **src/engine/creatures/init.lua (418 LOC)** — The creature behavior engine module.
   - **emit_stimulus()** — Queues stimuli (player_enters, loud_noise, light_change, etc.) for creatures to process on next tick.
   - **get_creatures_in_room()** — Returns all animate creatures at a given room location.
   - **creature_tick()** — Per-creature evaluation: drives → reactions → utility-scored behavior → action execution.
   - **tick()** — Master tick iterating all animate objects, pcall-guarded per creature.
   - **Drive system:** Updates hunger (+decay_rate), fear (decay toward 0), curiosity (+decay_rate), all clamped to [min, max].
   - **Reaction system:** BFS-based perception range. Same-room = full reaction, adjacent = 50% scaled, 2+ rooms = skip.
   - **Behavior selection:** Utility-scored from drives: idle (base 10), wander (curiosity + wander_chance), flee (fear > threshold), vocalize (moderate fear/curiosity). Random jitter breaks ties.
   - **Movement:** Portal-aware exit traversal. Validates traversable state and can_open_doors. Updates both room.contents and obj.location.
   - **FSM transitions:** alive-idle ↔ alive-wander ↔ alive-flee → dead. State set directly in tick.
   - **Attack action:** Explicitly a no-op (D-COMBAT-NPC-PHASE-SEQUENCING).
   - **Registry abstraction:** Compatible with both real registry (:list/:get) and test mocks (:all/get_location) for seamless testing.

2. **src/engine/loop/init.lua (+9 lines)** — Creature tick wired after fire propagation, before injury tick. pcall-guarded: if creatures module fails, game continues.

**Architecture decisions:**
- Creature tick is generic (Principle 8) — knows about nimate, drives, reactions, behavior tables. Does NOT know about rats.
- Simple exit format ({ target, open }) and portal format ({ portal = id }) both supported for test/production flexibility.
- BFS room distance bounded at depth 10 to prevent pathological map traversal.
- Stimulus queue drained after ALL creatures process (not per-creature) — ensures consistent stimulus delivery.

**Test results:** 25/25 creature tick tests pass, 17/17 stimulus tests pass. 3 pre-existing failures in unrelated files (weapon pipeline, material migration, object templates). Game boots cleanly in --headless mode.

**Performance:** 5-creature tick completes in <50ms (GATE-2 requirement met).

**Key files:**
- src/engine/creatures/init.lua — creature behavior engine (NEW)
- src/engine/loop/init.lua — game loop integration (+9 lines)
### Creatures directory split (2026-08)
- Added `src/meta/creatures/` and moved `src/meta/objects/rat.lua` → `src/meta/creatures/rat.lua`.
- Loader now scans `meta/objects/` then `meta/creatures/` before room resolution; both feed `base_classes` and `object_sources`.
- Updated paths in tests, plans/docs, and meta-lint detection so creature files get object-grade validation (template, GUID, keywords, senses).

## Learnings

### Phase 2 WAVE-0: Module Splits + Pre-Flight (2026-08)

**Status:** ✅ COMPLETE
**Branch:** squad/phase2-wave0-splits

**What was done:**

1. **Extracted `src/engine/creatures/stimulus.lua`** — Moved stimulus queue, emit, clear, and process_stimuli logic (~80 LOC) into dedicated module. `creatures/init.lua` delegates via `require("engine.creatures.stimulus")`. Helper functions (get_location, get_room_distance) passed as a helpers table to avoid duplicating navigation code.

2. **Created `src/engine/creatures/predator-prey.lua` (stub)** — No predator-prey code exists in Phase 1 monolith. Created stub with `detect_prey`, `evaluate_source_filter`, `predator_reaction` functions that return safe defaults. Documented what WAVE-2 will populate. Required by creatures/init.lua.

3. **Created `src/engine/combat/npc-behavior.lua` (stub)** — No NPC-specific combat decision code exists in Phase 1. Created stub with `select_response`, `select_stance`, `select_target_zone` functions. Required by combat/init.lua.

4. **Registered `test/food/` in test runner** — Added to `test_dirs` in `test/run-tests.lua`. Directory created with .gitkeep.

5. **Tissue material audit: ALL 5 materials exist** — hide.lua, flesh.lua, bone.lua, tooth-enamel.lua (name: "tooth-enamel"), keratin.lua all present in `src/meta/materials/`. No gaps for WAVE-1 body_tree tissue layers.

6. **Performance baseline:** 176 test files, 1 pre-existing failure (injuries/test-injuries-comprehensive.lua). Zero regressions from module splits.

**Key architectural pattern:** When extracting code that depends on local helper functions, pass helpers as a table parameter rather than duplicating them in the new module. Keeps the dependency graph clean and testable.

### Phase 2 WAVE-3: NPC-vs-NPC Combat + Creature Morale (2026-08)

**Status:** ✅ COMPLETE

**What was done:**

1. **Track 3A — NPC Combat Resolution (combat/init.lua +26 lines):**
   - `active_fights` tracking: `start_fight()`, `end_fight()`, `join_fight()`, `remove_combatant()`, `find_fight_for_combatant()`
   - `sort_combatants()`: speed desc → size asc → player last among equals
   - `resolve_round()`: iterates ordered combatants, each attacks once, removes dead
   - `select_npc_target(attacker, combatants)`: prey list priority, aggression>20 fallback (smallest target)
   - `select_target(context, attacker)`: context-aware wrapper using `get_creatures_in_room`
   - `cornered_bonus` in `resolve_damage()` multiplies base_force × 1.5

2. **Track 3B — Creature Morale (creatures/morale.lua, creatures/init.lua):**
   - `check_morale(creature)`: simple threshold check (health/max_health < flee_threshold), no context needed
   - `attempt_flee(context, creature)`: delegates to `morale.check()` with helpers table
   - Reads `combat.behavior.flee_threshold` (decimal ratio 0.0-1.0), fallback to `behavior.flee_threshold`
   - Cornered fallback: `_cornered=true`, `alive-cornered` state, attack×1.5 via opts
   - Morale check wired into attack action: checks both defender and attacker post-combat

3. **Module extractions (LOC budget compliance):**
   - Extracted `creatures/navigation.lua` (100 LOC): exit resolution, BFS distance, passability checking
   - `creatures/morale.lua` expanded (85 LOC): full flee/cornered logic with helpers table pattern
   - `creatures/init.lua` at 496 LOC (under 500 limit)

4. **npc-behavior.lua updates:**
   - `cornered` attack_pattern → aggressive stance
   - Cornered creatures block `flee` defense → `counter` instead
   - `select_stance()` returns `aggressive` when `_cornered` flag set

**Test results:** 186 test files pass. 25/25 NPC combat tests green. Zero regressions.
