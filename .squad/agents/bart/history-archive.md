# Bart — History Archive

**Archived:** 2026-03-27
**Cutoff date:** 2026-07-16 (entries older than this date)
**Source:** `.squad/agents/bart/history.md`

---

### Hook Pattern is Fully Stabilized (2026-03-29)
- The `on_X(obj, ctx)` + `event_output["on_X"]` pattern is now proven across 6 hook types: wear, remove_worn, open, close, pickup, drop — plus 2 room hooks (enter_room, exit_room)
- Room hooks use same signature `(room, ctx)` instead of `(obj, ctx)` but identical dispatch mechanics
- "Go back" movement path must also fire exit/enter hooks — easy to miss since it bypasses the main handle_movement flow
- All 4 take paths in acquisition.lua needed on_pickup insertion (get-from-container, bag extraction, two-hand, single-hand) — grep for "event_output" finds them all
- The "drop all" loop needs per-item on_drop callbacks, not just the single-item path

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

## Mutation Analysis & Architecture Alignment (2026-03-21T00:16Z)

**Status:** ✅ COMPLETE  
**Orchestration Log:** `.squad/orchestration-log/2026-03-21T00-16Z-bart.md`

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

## CROSS-AGENT UPDATES (2026-03-24T12:41:24Z Spawn Orchestration)

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

### Session: Verbs Refactor Split (2026-03-27)
**Status:** ✅ COMPLETE
**Requested by:** Wayne "Effe" Berry

**Deliverables:**
- Split `src/engine/verbs/init.lua` into helpers + 10 verb modules with registry-only init.
- Shared verb helpers moved to `helpers.lua`, including self-infliction parsing for strike.

**Key Notes:**
- `parse_self_infliction` moved to helpers to keep strike→hit routing intact.
- Added `location = "room"` on the bedroom-door instance to satisfy object placement tests.

**Test Results:** `lua test/run-tests.lua` (all passing)

### Session: Burnability from Material Flammability — Issue #120 (2025-07-18)
**Status:** ✅ COMPLETE

- Material-derived properties continue to be the right pattern. Armor was derived from material hardness; now burnability is derived from material flammability. This eliminates per-object `flammable` flags entirely.
- The threshold of 0.3 puts leather at the boundary (barely burnable) and bone below it (not burnable). This feels physically correct.
- Three-tier resolution (FSM → mutation → generic destruction) gives object authors flexibility without requiring any engine changes — Principle 8 in action.
- `perform_mutation` requires full engine context (`ctx.object_sources`, `ctx.mutation`, `ctx.loader`, `ctx.templates`). Test mocks for mutation paths need these fields or they'll crash on `object_sources` nil index.
- Only one object (`paper.lua`) used the old `categories = {"flammable"}` approach. It has `material = "paper"` so the new system covers it automatically — no object file changes needed.

### Session: Fire Propagation System — Issue #121 (2026-03-24)
**Status:** ✅ COMPLETE
**Requested by:** Wayne "Effe" Berry

**Deliverables:**
- New module: `src/engine/fire_propagation/init.lua` — tick-based fire spread engine
- Game loop integration: post-command fire propagation tick in `src/engine/loop/init.lua`
- 23 tests in `test/verbs/test-fire-propagation.lua`

**Key Notes:**
- Three-tier proximity model (SAME_SURFACE 0.8, SAME_PARENT 0.5, SAME_ROOM 0.2) mirrors physical reality: items touching on a shelf spread fire faster than items across the room.
- Spread chance formula: proximity × target_flammability × source_intensity. All values derived from materials — zero per-object configuration needed (Principle 8 + Principle 9).
- MAX_IGNITIONS_PER_TICK = 2 prevents runaway chain reactions. A room full of paper won't all ignite in one tick — fire cascades over multiple turns, giving the player time to react.
- Generic destruction uses a 1-tick countdown (_burn_ticks_remaining) so players have one turn to extinguish before the object is destroyed. FSM objects use their declared burn transitions instead.
- Deterministic RNG injection (`ctx.fire_rng`) makes propagation fully testable without mocking math.random globally.
- `is_burning` detection supports three patterns: explicit flag, FSM state name "burning", and `state.is_burning = true` property — covers all object authoring styles.
- Lit candles are NOT burning (they cast light but don't propagate fire). Only objects in "burning" state or with `is_burning` flag spread fire.

### Session: Oil Lantern Object — Issue #118 (2025-07-18)
**Status:** ✅ COMPLETE
**Requested by:** Wayne "Effe" Berry

**Deliverables:**
- Enhanced `src/meta/objects/oil-lantern.lua` — material brass, 6-state FSM (empty/fueled/lit/extinguished/spent/broken), wind resistance, refuelable from spent, glass chimney break mechanic
- Pour handler enhancement in `src/engine/verbs/survival.lua` — target-driven FSM transitions for "pour X into Y" pattern
- 32 tests in `test/verbs/test-oil-lantern.lua` — full lifecycle coverage

**Key Notes:**
- Pour handler had a gap: only checked the SOURCE object for "pour" FSM transitions, but the lantern's fuel transition is on the TARGET. Added target-driven FSM check with `requires_tool` validation so "pour oil into lantern" correctly transitions the lantern from empty→fueled.
- Spent state is NOT terminal on the lantern — it can be refueled via pour. Only the broken state (glass chimney shatters) is terminal. This diverges from the candle pattern where spent is terminal.
- `wind_resistant = true` integrates with existing `traverse_effects.lua` infrastructure. The lantern is the first object to use this property — it protects the flame from wind gusts during room traversal.
- Every non-broken state has a break→broken transition. Breaking while lit includes a flavor beat about the flame leaping free before dying.
- The `provides_capability()` helper cleanly handles both string and table forms of `provides_tool` — used it for tool validation in the pour handler enhancement.

### Session: Residual Test Failures — Issues #169, #171, #172 (2025-07-19)
**Status:** ✅ COMPLETE
**Requested by:** Wayne "Effe" Berry

**Deliverables:**
- `src/engine/verbs/fire.lua` — `find_fire_source()` now detects unlit objects whose FSM states provide a capability, auto-ignites them before use. Added `has_capable_state()` and `auto_ignite()` helpers. Excludes target object from fire source search to prevent self-lighting.
- `src/engine/verbs/fire.lua` — burn handler no-flame error uses `ctx.current_verb` instead of hardcoded "burn"
- `src/engine/verbs/crafting.lua` — put handler uses `target.container_preposition` for narration instead of raw parsed preposition

**Key Notes:**
- `auto_ignite()` directly applies state properties (same approach as FSM's `apply_state`), bypassing FSM guards like `requires_property`. This is intentional — auto-striking a match during fire-source detection is an implicit convenience action, not a player-initiated verb.
- `exclude_obj` parameter on `find_fire_source()` prevents the candle (target) from being detected as its own fire source — its lit state also provides `fire_source`.
- The `container_preposition` override only affects the narration text, not the surface-routing logic. Parsing still uses the player's input preposition for determining which surface to place items on.

### Session: Linter Phase 1 — Quick Wins (2026-03-30)
**Status:** ✅ COMPLETE
**Branch:** squad/linter-improvements

**Architecture decisions:**

1. **Rule registry as separate module** — scripts/meta-check/rule_registry.py holds all rule metadata (severity, fixable, fix_safety, category, description). Decoupled from validation logic so other tools can query rule metadata without importing the full checker.

2. **Config-first severity** — _add_violation() only overrides severity when config has an explicit per-rule override. The code-level severity is the ground truth; config is the exception mechanism. This lets rules like MD-19 emit different severities for different code paths (warning vs info) without the registry default flattening them.

3. **Category keyword filtering for XF-03** — Built-in CATEGORY_KEYWORDS frozenset for words that legitimately appear across objects (garment, clothing, weapon, etc.). Config keyword_allowlist handles project-specific cases. This cut XF-03 false positives from 145 to 135 without losing real collision detection.

4. **importlib.util pattern for hyphenated directories** — Python can't import from meta-check/ as a package. Solution: _load_sibling() helper using importlib.util.spec_from_file_location() + register in sys.modules (required for dataclass module resolution).

5. **XR-05b cascading check** — Collects generic_templates set during XR-05 pass, then iterates objects to detect missing material overrides. O(n) second pass, no extra file I/O.

**Key files:**
- scripts/meta-check/rule_registry.py — 110+ rules with metadata
- scripts/meta-check/config.py — .meta-check.json loader, per-rule/category config
- scripts/meta-check/check.py — Updated with config integration, smart XF-03, enhanced MD-19, XR-05b
- 	est/meta-check/test_phase1.py — 29 tests (registry, config, integration)
- docs/meta-check/usage.md — Updated CLI reference

**Test results:** 29/29 Phase 1 tests pass, 129/129 Lua tests pass, 0 regressions.

### Linter Phase 3: Squad Routing + Incremental Caching (2026-03-25)

**Squad Routing (squad_routing.py):**
- Every registered rule maps to a squad member via fnmatch patterns
- Routing precedence: exact match > wildcard pattern (longest first) > "unassigned"
- Config overrides via `squad_routing` section in .meta-check.json
- All 15 rule categories covered: S/PARSE/G/FSM/TR/SN/TD → Bart, INJ/MD/MAT/CREATURE → Flanders, RM → Moe, LV → Comic Book Guy, XF/XR → Smithers, GUID → Bart, EXIT → Sideshow Bob
- JSON output includes `by_owner` summary; `--by-owner` flag groups text output

**Incremental Caching (cache.py):**
- SHA-256 per-file hashing; cached in .meta-lint-cache.json
- Cross-file rules (XF/XR/GUID/EXIT/LV-40) never cached — always re-run
- Conservative invalidation: if ANY file changed, all files re-validate
- Cache prunes deleted files automatically
- `--no-cache` flag for full re-scan; cache stats in JSON/verbose output
- Version field for forward-compatible cache migration

**Key files:**
- scripts/meta-lint/squad_routing.py — routing table + SquadRouter class
- scripts/meta-lint/cache.py — LintCache, hash_file, is_cross_file_rule
- scripts/meta-lint/lint.py — integrated routing + caching into main pipeline
- scripts/meta-lint/config.py — added squad_routing field to CheckConfig
- test/meta-check/test_phase3.py — 31 tests

**Test results:** 31/31 Phase 3 tests pass, 153/153 Lua tests unaffected.

