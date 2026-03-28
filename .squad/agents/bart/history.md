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

---

## Archives

- Prior detailed session logs: .squad/log/
- Linked decisions: .squad/decisions.md (search 'D-*' keys)

