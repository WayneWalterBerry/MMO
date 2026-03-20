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
