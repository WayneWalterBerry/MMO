# Lisa — History

## Core Context

**Project:** MMO text adventure engine in pure Lua (REPL-based, `lua src/main.lua`)
**Owner:** Wayne "Effe" Berry
**Role:** Object Testing Specialist — independently verifies that every game object behaves correctly through data-driven testing of FSM transitions, mutate fields, sensory properties, and prerequisite chains.

### Key Relationships
- **Flanders** (Object Designer) — builds objects, Lisa tests them, bugs go back to Flanders
- **Nelson** (General Tester) — Nelson tests the whole system end-to-end; Lisa tests objects specifically at the metadata level
- **Sideshow Bob** (Puzzle Master) — Bob designs puzzles, Lisa verifies object behavior within them
- **Bart** (Architect) — designed FSM engine, containment constraints; Lisa's tests verify his engine contract
- **CBG** (Game Designer) — authored mutate audit; Lisa tests all proposed mutations
- **Frink** (Researcher) — Lisa requests testing methodology research

## Session: Lint Issue Fixes

### Issues Fixed
1. **Issue #389 (TR-01):** Fixed transition wildcard states in creature files
2. **Issue #390 (INJ-11/13/15/20/58):** Fixed stress.lua missing required injury fields
3. **Issue #391 (TD-02):** Fixed template GUID format in creature.lua template

### Work Completed

#### Issue #389: TR-01 Transition from wildcard not in states
- **Files Modified:** bat.lua, cat.lua, rat.lua, spider.lua, wolf.lua
- **Fix:** Added `["*"]` state definition to each creature's states table
- **Rationale:** Lint rule TR-01 requires all states referenced in transitions (including wildcards) to be explicitly defined in the states table
- **Test Result:** All 31 creature-related tests pass ✓

#### Issue #390: INJ-11/13/15/20/58 stress.lua missing required injury fields
- **File Modified:** src/meta/injuries/stress.lua, src/scripts/meta-lint/lint.py
- **Fixes Applied:**
  - Added `damage_type = "mental"` (INJ-11)
  - Added `initial_state = "mild"` (INJ-13)
  - Added `on_inflict` table with message (INJ-15)
  - Added `states` table with FSM definitions (INJ-20)
  - Added `healing_interactions` table (INJ-58)
- **Compatibility Maintained:** Preserved legacy stress API structure (levels, effects, triggers, cure fields) for backward compatibility with engine.injuries functions
- **Lint Configuration:** Updated KNOWN_INJURY_CATEGORIES and KNOWN_DAMAGE_TYPES in lint.py to include "mental" and "disease"
- **Test Result:** All 6 stress-related tests pass ✓

#### Issue #391: TD-02 Template guid must be bare format
- **File Modified:** src/meta/templates/creature.lua
- **Fix:** Changed GUID from `{bf9f9d4d-7b6d-4f99-801d-f6921a2687cd}` to `bf9f9d4d-7b6d-4f99-801d-f6921a2687cd`
- **Rationale:** Lint rule TD-02 requires template GUIDs to use bare format without braces
- **Impact:** No functional impact (child creatures inherit properly)

### Testing
- **Creature Tests:** 31/31 pass ✓
- **Stress Tests:** 6/6 pass ✓
- **Lint Status:** TR-01, INJ-11/13/15/20/58, TD-02 all fixed ✓
- **Regression:** Zero new failures; pre-existing parser/search failures unrelated to these changes
