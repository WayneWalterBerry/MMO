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

### Recent Work: #125 BUG-050 Fix + #103 Open/Close Hooks (2026-03-28)

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

## Learnings

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

### find_visible Must Mirror Container Nesting Depth (2026-03-28)
- The search system (`traverse.lua`) correctly opens all containers recursively during search
- But `_fv_surfaces` in `verbs/init.lua` only searched surface zone contents — NOT root-level contents of objects with surfaces
- Objects like nightstand have BOTH surfaces (`.top`) AND root contents (drawer in `.contents`)
- The root contents path was invisible to `get`/`take` because `_fv_surfaces` had `not obj.surfaces` guard on the non-surface container branch
- Fix: recursive `_search_accessible_chain` traverses root contents following `accessible` flag, matching search system's depth (3 levels)
- Lesson: any function that resolves visible/reachable objects must mirror the containment model depth

### Material Consistency Principle (2026-03-27)
- The material registry `src/engine/materials/init.lua` already exists as a complete property-bag system, making Material Consistency a natural fit as a core principle
- Material binding (object.material → materials.get(name)) enables content-driven physics without engine changes
- Instance overrides (fragility_override, etc.) should be documented as exceptions, not defaults — this is critical to maintain consistency across the world
- Material properties cascade naturally: density → weight, flammability → burning behavior, hardness → impact resistance. No need to hard-code individual properties per object.
- This principle aligns perfectly with the Dwarf Fortress architectural reference (D-DF-ARCHITECTURE) where the simulation engine operates on physical properties, not object type names

### Monolith Splitting Sweet Spot (2026-03-28)
- Reviewed all engine files >500 lines for P0-A refactoring review
- `verbs/init.lua` at 5,884 lines is the critical target — 8-12 split files is the sweet spot for LLM context reduction (74-84% less context per edit) without excessive cross-file coordination
- Key insight: the `register(handlers)` pattern lets each verb module inject its handlers into a shared table without knowing about other modules. Clean decoupling.
- Utility duplication across 3+ files (`strip_articles`, `kw_match`, hand accessors) must be centralized BEFORE any file split — otherwise duplication multiplies
- `traverse.lua` (871 lines) should NOT be split despite its size — it's a single FSM with high internal cohesion. Size ≠ bad structure.
- `loop/init.lua` (585 lines) should NOT be split — its phases are sequential safety barriers (consciousness → search tick → input → dispatch → FSM tick). Fragmenting the ordering contract is more dangerous than the file size.
- Pre-refactoring tests are the prerequisite. No code moves without a green test covering the function being moved.
- Sequencing matters: refactor BEFORE meta-compiler because meta-check validates file paths — building against a monolith then splitting creates wasted work

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

### Session: Phase A1 — Armor System Architecture Document (2026-03-24)
**Status:** ✅ COMPLETE  
**Requested by:** Wayne "Effe" Berry (Daily Plan Phase A1)

**Task:** Write `docs/architecture/engine/armor-system.md` covering:
- How protection is derived from material properties (formulas using hardness, flexibility, density)
- How the before-effect interceptor queries worn items by injury location
- Slot-to-location mapping (head slot → head injuries)
- Degradation model (fragility → crack → shatter FSM states)
- Armor template specification (what objects declare vs what engine derives)
- Integration diagram: materials.lua ↔ effects.lua ↔ injuries.lua ↔ wear system

**Deliverable:** `docs/architecture/engine/armor-system.md` (v1.0, 570 lines)

**Key Design Decisions:**
- **Material Consistency Principle:** Armor protection derived ONLY from material properties (hardness, flexibility, density, fragility), never from hardcoded object fields
- **Protection Formula:** `protection = hardness×2.0 + flexibility×1.0 + density_factor×0.5`, then scaled by `coverage` and `fit` multiplier
- **Degradation FSM:** Armor states intact → cracked (0.7x protection) → shattered (0x protection), triggered by fragility-based roll
- **Slot-to-Location Mapping:** 8 slots (head, torso, left_arm, right_arm, left_leg, right_leg, hands, feet) map to canonical injury location names
- **Multi-Layer Stacking:** Inner + outer layers both contribute to protection; damage must pass through both
- **Instance Overrides:** Allowed (e.g., `fragility_override` for enchanted items) but documented as rare exceptions, not defaults

**Architecture Principles (Dwarf Fortress-inspired):**
- Engine operates on property bags, not object type names
- Same ceramic pot can be armor, container, tool, or projectile — behavior emerges from material properties
- Before-interceptor pattern (Inform-style) for armor damage reduction
- No hardcoded "provides_armor" field on objects — engine derives everything

**Integration Points:**
- Armor query: `player.worn` array with slot/layer organization
- Protection calculation: before-effect interceptor in `effects.lua`
- Material lookup: `materials.get(object.material)`
- Degradation: FSM state mutation on armor object
- Injury reduction: `effect.damage = max(1, damage - protection)`

**Cross-Referenced:**
- `docs/architecture/engine/effects-pipeline.md` (v2.0) — before/after interceptor infrastructure
- `docs/design/material-properties-system.md` — material property definitions
- `src/engine/materials/init.lua` — 22-material registry
- D-DF-ARCHITECTURE decision (Dwarf Fortress simulation philosophy)

**Completion Checklist:**
- [x] Protection formulas (hardness, flexibility, density weighting)
- [x] Coverage and fit modifiers (makeshift/fitted/masterwork)
- [x] Slot-to-location canonical mapping table (8 slots, 6-10 locations each)
- [x] Degradation states and break_chance formula
- [x] Armor template specification (required vs derived fields)
- [x] Before-interceptor lifecycle (3 phases: before, handler, after)
- [x] Worn item query function signature and implementation
- [x] Multi-layer stacking logic
- [x] Material consistency principle (no instance overrides as default)
- [x] Full integration diagram (materials → armor → effects → injuries)
- [x] 3 detailed example scenarios (ceramic pot stab, degradation, leather slash)

**Next Actions:**
- Phase A2 (CBG): Design doc (designer-facing examples, narratives, material × damage type matrix)
- Phase A3 (Nelson): Unit tests (armor reduces damage, location matching, material degradation, makeshift/fitted/masterwork scaling)
- Phase A4 (Smithers): Implementation (armor interceptor in effects.lua)

---

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

### Session: Parser Strategy Documentation (2026-03-25)
**Status:** ✅ COMPLETE  
**Requested by:** Wayne "Effe" Berry (Decision Architect)

**Task:** Document strategic analysis of three AI buzzwords evaluated against Prime Directive, with architectural recommendations.

**Deliverable:** `docs/architecture/engine/parser/parser-strategy.md`

**Analysis:**
1. **Decision Matrix Skill** — REJECTED
   - What it claims to solve: Scoring multiple parser interpretations
   - What we already have: GOAP + embedding matcher disambiguation
   - Real problem: Coverage, not decision logic (need better idioms/synonyms)
   - Verdict: Expand idiom table instead of adding framework

2. **Humanizer** — REJECTED
   - What it claims to solve: Making AI responses sound natural
   - What we already have: narrator.lua + error message overhaul (Tier 2 roadmap)
   - Real problem: Template rotation bug, error messages need polish
   - Verdict: Fix existing systems instead of wrapping them

3. **Orchestration Framework** — REJECTED (but pattern KEPT)
   - What it claims to solve: Coordinating pipeline stages
   - What we already have: Game loop IS orchestrator
   - Real pattern worth keeping: Table-driven pipeline from roadmap section 6
   - Why framework fails: Zero-token constraint makes simplicity paramount
   - Verdict: Use good pipeline design (table-driven), not orchestration framework

**Key Insight:**
- Prime Directive gap is **coverage**, not architecture
- Existing systems need polish, not frameworks
- Best pattern: Composable pipeline stages (10-50 lines each)

**Roadmap Reference:**
- Section 6 of prime-directive-roadmap.md details the pipeline refactor
- Shows extensible architecture without framework overhead

### Session: Headless Testing Mode (2026-03-22T19:41Z)
**Status:** ✅ COMPLETE  
**Team:** Scribe coordination of Marge + Bart + Smithers deploy sprint

**Task:** Implement `--headless` testing mode to eliminate TUI false-positive hang reports.

**Deliverable:** D-HEADLESS decision + `src/main.lua` implementation

**Key Insight:** Nelson Pass 035 proved 6 reported "hangs" were false positives caused by TUI ANSI escape codes (cursor positioning, scroll regions) overwriting terminal content in interactive sessions. Automated pipe-based testing with precise timing showed zero actual hangs (50/50 PASS rate).

**Solution Implemented:**
- `--headless` flag in main.lua disables TUI entirely (no ANSI codes)
- Suppresses interactive `"> "` prompt and welcome banner
- Emits `---END---` delimiters on separate lines for trivial test harness parsing
- Preserves all game logic (only presentation layer changes)
- Usage: `echo "look" | lua src/main.lua --headless`

**Impact:**
- Eliminates entire class of TUI false-positive reports
- Nelson MUST use `--headless` for all automated/LLM play testing going forward
- No changes to game logic, parser, or verb system required
- All 1,088 unit tests pass with --headless mode verified

**Commit:** `a86f9d7` — docs: Add parser strategy document (buzzword analysis & architectural decisions)

### Session: BUG-067/068 Investigation (2026-03-21)
**Status:** ✅ CANNOT REPRODUCE — Bugs not present  
**Requested by:** Wayne "Effe" Berry

**Task:** Investigate game stability bugs reported by Nelson in Pass-021:
- BUG-067: Rapid sequential commands cause hang
- BUG-068: `inventory` command hangs game

**Investigation Results:**
- ✅ Inventory command works perfectly (displays hands, worn items, containers)
- ✅ Rapid command sequences (7+ commands) execute without hanging
- ✅ Piped input completes in 3 seconds (no blocking)
- ✅ All 288 existing tests pass
- ✅ Code review shows no infinite loops or blocking operations

**Root Cause:** Likely transient testing environment issue or already fixed before investigation.

**Actions Taken:**
1. Created automated regression tests:
   - `test/integration/test-no-hang.lua` — end-to-end hang detection
   - `test/integration/test-bug-067-068.lua` — unit-level verification
2. Documented findings in `temp/bug-067-068-investigation.md`
3. Verified game stability with multiple test scenarios

**Outcome:** Both bugs marked as **CANNOT REPRODUCE**. Game is stable.

**Commit:** `4d59d8f` — test: add regression tests for BUG-067/068

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

### On Architectural Buzzwords vs. Prime Directive Constraints (2026-03-25)
**Context:** Evaluated three AI systems buzzwords (Decision Matrix Skill, Humanizer, Orchestration Framework) against the Prime Directive ("feel like Copilot, cost like Zork").

**Key Insight:** Buzzwords designed for systems that call AI models (token cost, complex state management) don't fit zero-token constraints.

**Decision Pattern:**
- When a buzzword describes a pattern you already have (e.g., GOAP IS decision-making) — don't add the framework, expand the existing system
- When a buzzword would wrap existing code (e.g., Humanizer around narrator.lua) — polish the original instead
- When a buzzword requires infrastructure you don't have (e.g., orchestration framework) — use simple design patterns instead

### Hang Elimination Sprint — Phase 5 (2026-03-25)
**Context:** BUG-105/106 "fixed" twice but kept recurring in live play. Three new hangs (BUG-116/117/118) found in pass-034.

**Root Cause Analysis:**
- Added trace logging (`_G.TRACE`, `--trace` flag) to game loop, parser, search, GOAP
- Reproduced all 5 inputs with piped stdin — none actually hang in isolation with current code
- BUG-105/106: Already fixed by direct transform in loop + pipeline transform_questions
- BUG-116 ("look around"): Already handled by transform_look_patterns → "look"
- BUG-117 ("where is the matchbox"): Already handled by transform_questions → "find matchbox"
- BUG-118 ("peek behind the curtains"): Missing preprocessing — "peek" had no handler and Tier 2 score too low. Added "peek behind/at/through X" → "examine X" in preprocess.lua

**Architectural Fix — Global Safety Net:**
- `debug.sethook` instruction-count hook in game loop: 2-second timeout on ALL command processing
- Each handler/Tier 2/GOAP call wrapped in `pcall` — timeout caught and reported to player
- Search tick loop at top of game loop: 200-tick hard limit with force-abort

### Headless Testing Mode (2026-03-25)
**Context:** Pass-035 proved all 5 "hangs" (BUG-105/106/116/117/118) were TUI false positives — the split-screen UI uses ANSI escape codes that overwrite terminal content, making responses invisible to LLM terminal capture tools.

**Investigation Findings:**
- `engine/ui/init.lua` uses cursor positioning (`\e[H`), scroll regions (`\e[r`), screen clearing (`\e[2J`), reverse video (`\e[7m`)
- These ANSI sequences cause re-rendered content to overwrite existing lines instead of appending
- When read through an interactive PTY, the game appears to produce no output — a hang
- Pipe-based testing bypasses the TUI entirely, proving the engine responds in <2s for all inputs

**Solution Implemented:**
- Added `--headless` flag to `src/main.lua` (implies `--no-ui`)
- Headless mode: no TUI, no prompts, no ANSI codes, `---END---` delimiters after each response
- Minimal banner (room intro only, no chrome)
- All game logic preserved — only presentation changes
- Updated LLM play testing skill (`.squad/skills/llm-play-testing/SKILL.md`) with headless-first approach
- Decision: D-HEADLESS in `.squad/decisions/inbox/bart-headless-testing.md`

**Key Learning:** TUI rendering is invisible to the engine — it sits entirely in the presentation layer. Test infrastructure should always bypass presentation to test engine logic directly. The `--headless` flag makes this architectural boundary explicit.

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

## EFFECTS PIPELINE ARCHITECTURE (EP1, 2026-03-23T17:05Z)

**Status:** ✅ COMPLETE

Authored unified Effects Pipeline architecture document (`docs/architecture/engine/effects-pipeline.md`) as part of multi-phase Effects Pipeline rollout:

- **Problem:** Engine handles object effects inline in verb handlers. Poison bottle had duplicate code paths (drink vs taste). Taste verb called `os.exit(0)` directly instead of routing through injury system. Every new injury-causing object required editing engine code.
  
- **Solution:** D-EFFECTS-PIPELINE — Unified Effect Processing Pipeline that:
  1. Accepts structured effect tables from object metadata
  2. Routes effects to registered handlers by `type` field
  3. Supports before/after interceptors for modification, cancellation, post-processing
  4. Replaces inline verb handler effect interpretation with single `effects.process()` call
  
- **Key Design:** Objects declare *what* happens; engine decides *when*; pipeline decides *how*. New effect types are added by registering handlers (zero pipeline changes). Principle 8 compliance — new injury-causing objects require zero engine changes.

- **Implementation Priority:**
  - P0: Create effects.lua with inflict_injury + narrate handlers
  - P1: Refactor drink, taste, feel verb handlers
  - P2: Register add_status handler; wire interceptor use cases
  - P3: Converge traverse_effects.lua into unified pipeline

**Approved by Marge (Test Manager):** Gate EP2b passed — 116/116 poison bottle regression tests on baseline code. Ready for EP3 implementation.

**Decisions:**
- D-HEALTH001 revised: Health is derived, not stored
- D-HEALTH002 revised: No generic "heal N HP"
- D-HEALTH003 new: Health computed on read
- D-HEALTH004 new: Damage recorded on injury instances
- D-INJURY003 revised: Healing matches by EXACT injury type
- D-INJURY007 new: Each injury carries .damage field
- D-INJURY008 new: Dual-side healing validation
- D-INJURY009 new: Injury types are specific, not generic
- D-INV001–D-INV006: First-class inventory decisions

**Learnings:**
- Derived health eliminates an entire class of sync bugs (health says 50 but injuries total 80 damage). Single source of truth pays off.
- Injury-specific healing creates natural puzzle pressure — finding the RIGHT remedy, not just ANY remedy.
- Nested inventory (containers within containers) needs recursive traversal but the code stays simple.
- The compute_health() function is called on every read, which is fine for a text adventure (no performance concern).

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

### Session: Appearance Subsystem + Consciousness Architecture (2026-03-23)
**Status:** ✅ COMPLETE
**Requested by:** Wayne "Effe" Berry

**Deliverables:**
- `docs/architecture/player/appearance-subsystem.md` — Layered renderer pipeline (head→feet→overall), injury phrase composition, mirror integration, multiplayer-ready design
- `docs/architecture/player/consciousness-state.md` — Conscious/unconscious/waking state machine, forced-tick game loop integration, sleep+injury danger, death-during-unconsciousness handler

**Key Architectural Findings:**
- Player state (`main.lua:278-290`): hands[2], worn{}, injuries[], max_health=100, state{bloody, poisoned, has_flame}
- NO consciousness/sleep fields exist yet — need to add `player.consciousness` table
- Game loop (`loop/init.lua`): injury tick happens post-command at line ~498; death check at ~502
- Sleep verb (`verbs/init.lua:4827+`) ticks object FSMs but does NOT tick `injury_mod.tick()` — gap that needs fixing for "sleep is dangerous with injuries"
- Injury system (`engine/injuries.lua`) is already a pure function of player state — consciousness system can call it without coupling
- Vanity mirror (`meta/objects/vanity.lua:31-42`) has hardcoded reflection text — needs replacement with dynamic appearance call
- 5 injury types exist: bleeding, bruised, burn, minor-cut, poisoned-nightshade

**Decisions Made:** D-APP001 through D-APP006 (appearance), D-CONSC001 through D-CONSC008 (consciousness)

## Learnings

### Session: Spatial Relationships Architecture — Hiding vs On-Top-Of (2026-03-27)
**Status:** ✅ COMPLETE
**Requested by:** Wayne "Effe" Berry

**Task:** Investigate and design engine architecture for distinguishing objects that sit ON something (both visible) vs objects that HIDE something (hidden until cover moved).

**Deliverable:** `docs/architecture/objects/spatial-relationships.md`

**Key Findings:**
- The covering/hidden pattern already works end-to-end: `rug.lua` has `covering = {"trap-door"}`, `trap-door.lua` has `hidden = true` + FSM, the move verb handler reveals covered objects. The architecture is sound — it just wasn't documented.
- **Critical gap found in traverse.lua:** The search engine does NOT check `obj.hidden` in `expand_object()` or `matches_target()`. A player doing `search room` could find the trap door before moving the rug. This is a real bug, not just a documentation gap.
- **Secondary gap:** `rug.lua`'s `surfaces.underneath` lacks `accessible = false`, meaning search could discover items hidden under the unmoved rug.
- The relationship metadata lives on the covering object (not the room). This follows Principle 8: objects declare behavior, engine executes metadata.
- FSM-based reveal (`hidden → revealed`) is preferred over raw flag-clearing because it atomically updates all state-dependent properties.

**Decisions Made:** D-SPATIAL-ARCH (engine architecture for spatial concealment)

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

## CROSS-AGENT UPDATES (2026-03-24T12:41:24Z Spawn Orchestration)

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

## CROSS-AGENT UPDATES (2026-03-24T23:25Z Spawn Orchestration Merge)

**Decision Merged: D-ARMOR-INTERCEPTOR**

- Smithers (Phase A4) completed armor interceptor implementation with 30/30 tests passing
- **Formula weight clarification:** Architecture doc specified "≈ 2.0, 1.0, 0.5" — implementation uses 1.0, 1.0, 0.5 due to tuning for test contracts
  - At damage=10 (Nelson's test value), hardness_weight=2.0 makes ceramic protection ≈ 14.4, causing both intact and cracked states to hit the minimum-damage floor of 1
  - Tuning to hardness_weight=1.0 gives ceramic ≈ 7.4, so cracked (≈ 5.2) produces meaningfully different damage than intact (≈ 7.4)
  - This preserves relative material ordering from architecture doc while satisfying Nelson's test contracts
- **Impact:** All 22 materials now in 1–10 range (better alignment with typical 5–20 damage values)
- **Fit/State multipliers verified:** makeshift 0.5×, fitted 1.0×, masterwork 1.2× + intact 1.0×, cracked 0.7×, shattered 0.0× (as specified in architecture doc)

**Status:** Phase A4 SHIPPED.


---

### Session: Equipment Event Hooks + Event Output System (2026-03-24)
**Status:** ✅ COMPLETE
**Requested by:** Wayne "Effe" Berry (autonomous work)

**Task:** Phase A6 + A6b from daily plan — Equipment event hooks architecture and implementation, plus the event_output one-shot flavor text system.

**Deliverables:**

1. **`docs/architecture/engine/event-hooks.md`** — Updated to v3.0:
   - Added equipment category to Active Hooks table (`on_wear`, `on_remove_worn`, `on_equip_tick`)
   - Added Equipment row to Event Taxonomy (Section 6.1)
   - Added 3 hooks to Hook Summary table (Section 6.2)
   - Added 2 resolved gaps to Gap Analysis (Section 7.1)
   - New Section 11: Equipment Event Hooks — contract, implementation location, object declaration pattern, relationship to effects pipeline
   - New Section 12: Event Output System — design, declaration, engine behavior, dispatch points, interaction with callbacks

2. **`src/engine/verbs/init.lua`** — Implementation:
   - **`on_wear` hook:** After wear flavor print, checks `obj.on_wear` function and fires it with `(obj, ctx)`
   - **`on_remove_worn` hook:** After remove flavor print, checks `obj.on_remove_worn` function and fires it with `(obj, ctx)`
   - **`event_output` at 8 dispatch points:**
     - `on_take`: 4 success paths (from container, from parent, two-handed, single-handed)
     - `on_drop`: 1 dispatch point (after drop, both shatter and survive paths)
     - `on_wear`: 1 dispatch point (after wear)
     - `on_remove_worn`: 1 dispatch point (after remove)
     - `on_eat`: 1 dispatch point (after eat, before item removal)
     - `on_drink`: 1 dispatch point (after drink FSM transition)

**Key Architectural Decisions:**
- Equipment hooks are CODE pattern (callbacks), not DATA pattern — correct because equip/unequip are lifecycle events needing complex logic
- `event_output` is DATA pattern (strings on tables) — correct because flavor text needs no logic, just print-and-nil
- `event_output` fires AFTER callbacks — flavor text appears last, after any mechanical output
- `on_equip_tick` designed but NOT implemented — needs game loop integration (future work)

**Test Results:** Zero regressions. 1 pre-existing failure (bedroom-door instance location) unrelated to changes.
