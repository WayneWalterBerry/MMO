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

## Session: Test Suite Speed Audit

### Task
Wayne requested a full audit of the test suite for speed optimization opportunities.

### Key Findings
- **261 test files**, 91,356 total lines, 312.3s total sequential execution time
- **Top 10 slowest files account for 82.7% of total time** (258.3s)
- **Two files dominate:** `test-inverted-index.lua` (79.5s benchmark) and `run-tests.lua` (148.8s orchestrator)
- **43 files exceed 500 lines** — largest is `test-fsm-comprehensive.lua` at 1,473 lines
- **Nightstand gating tests are duplicated** (`test-container-gating.lua` vs `test-container-gating-pass028.lua`)
- **Inventory tests overlap** (`test-inventory.lua` vs `test-containment-comprehensive.lua`)
- **Tests are parallelism-unsafe** — file-scoped handlers, no `package.loaded` cleanup, no teardown hooks
- **3,000–5,000 lines of duplicated boilerplate** across files (`capture_output`, `make_ctx`, etc.)

### Recommendations (by impact)
1. **Tag 3 benchmark files as opt-in** → saves 88s (54% of test time)
2. **Parallelize pure-function tests** (parser/pipeline, objects, sensory, ui) → saves ~40s
3. **Extract shared test helpers** to `test/common.lua` → reduces maintenance burden
4. **Merge nightstand gating duplicates** → cleaner coverage
5. **Split 5 slow+large files** (armor-interceptor, npc-combat, inventory, combat-integration, fsm-comprehensive)

### Output
- Full report written to `temp/test-audit-report.md`
- No test files modified (audit only)

## Session: Portal TDD — Issues #204, #205

### Task
Write TDD tests for two portal issues: #204 (deep-cellar ↔ crypt archway) and #205 (hallway → level-2 boundary staircase).

### Findings

#### Issue #204 (Deep Cellar-Crypt Archway)
- **Already complete.** Portal objects (`deep-cellar-crypt-archway-west.lua`, `crypt-deep-cellar-archway-east.lua`) already existed with full FSM (locked/closed/open), silver-key lock/unlock, bidirectional sync via shared `bidirectional_id`.
- Test file `test/rooms/test-portal-deep-cellar-crypt.lua` already existed with 75 passing tests covering: file loading, structure, metadata, FSM states, transitions, sensory, movement, bidirectional sync, room wiring, keywords.
- Room files (`deep-cellar.lua`, `crypt.lua`) already wired with `{ portal = "..." }` syntax. No inline exits remain.
- **Status:** No new work needed. Verified 75/75 tests pass.

#### Issue #205 (Hallway-Level2 Boundary Staircase)
- Portal object `hallway-level2-stairs-up.lua` already existed — boundary portal with `blocked` state, `blocked_message`, no transitions, `bidirectional_id = nil`.
- Room file `hallway.lua` already wired: `north = { portal = "hallway-level2-stairs-up" }`.
- **Missing:** No test file existed. Created `test/rooms/test-portal-hallway-level2.lua` with 46 tests covering: file loading, structure, metadata, FSM state (blocked), boundary blocking, sensory (P6 on_feel), movement blocking (go north, go staircase, go stairs all blocked), room wiring, keywords, descriptions.
- **Status:** 46/46 tests pass. Committed and pushed.

### Linter Results
- Pre-existing MAT-03 warnings (material by name) on all 3 portal files
- Pre-existing EXIT-04 warning: direction_hint 'up' vs room exit 'north' on hallway-level2 staircase (design decision — staircase ascends UP but is at the NORTH end of the hallway)
- XF-03 info: cross-room keyword sharing (expected for paired portals)
- No new lint issues introduced

### Test Suite
- Full suite: 260 test files, all PASSED
- Zero regressions

## Session: Portal TDD — Issues #206, #207, #208

### Task
Write TDD tests for three boundary portal issues: #206 (hallway-west door), #207 (hallway-east door), #208 (courtyard-kitchen door).

### Findings

#### Issue #206 (Hallway-West Door → manor-west boundary)
- Portal object `hallway-west-door.lua` already existed — boundary portal with single `locked` state, `blocked_message`, no transitions, `bidirectional_id = nil`.
- Room file `hallway.lua` already wired: `west = { portal = "hallway-west-door" }`, instance included.
- **Created:** `test/rooms/test-portal-hallway-west.lua` with 45 tests covering: file loading, object structure, portal metadata (target=manor-west), FSM state (locked, not traversable), blocked_message, no transitions, sensory properties (P6 on_feel + all 5 senses + per-state sensory), movement blocking (go west, west shorthand, go door), room wiring (portal reference, no legacy inline exit), keywords (door, west door, oak door, locked door), atmospheric descriptions.
- **Status:** 45/45 tests pass ✓

#### Issue #207 (Hallway-East Door → manor-east boundary)
- Portal object `hallway-east-door.lua` already existed — boundary portal with `locked` and `unlatched` states, pry transition (locked→unlatched, requires cutting_edge tool), both states non-traversable.
- Room file `hallway.lua` already wired: `east = { portal = "hallway-east-door" }`, instance included.
- **Created:** `test/rooms/test-portal-hallway-east.lua` with 59 tests covering: file loading, object structure, portal metadata (target=manor-east), FSM states (locked + unlatched both non-traversable), transitions (locked→unlatched via pry verb, requires cutting_edge), blocked_messages (latch hint + collapse explanation), sensory per both states, movement blocking in both states, room wiring, keywords, atmospheric descriptions (kitchen smells).
- **Status:** 59/59 tests pass ✓

#### Issue #208 (Courtyard-Kitchen Door → manor-kitchen boundary)
- Portal object `courtyard-kitchen-door.lua` already existed — most complex boundary portal with 4 states (locked/closed/open/broken), 5 transitions (unlock, open, close, break×2), ALL states non-traversable, spawns wood-splinters on break.
- Room file `courtyard.lua` already wired: `east = { portal = "courtyard-kitchen-door" }`, instance included.
- **Created:** `test/rooms/test-portal-courtyard-kitchen.lua` with 82 tests covering: file loading, object structure, portal metadata (target=manor-kitchen), all 4 FSM states (non-traversable boundary), 5 transitions (unlock locked→closed, open closed→open, close open→closed, break locked→broken with strength=3, break closed→broken with strength=2), blocked_messages for open+broken states (collapsed masonry), spawns (wood-splinters), sensory per all 4 states, movement blocking in ALL 4 states, room wiring, keywords, atmospheric descriptions.
- **Status:** 82/82 tests pass ✓

### Linter Results
- All pre-existing errors only (CREATURE-003 creature drives, TD-06 world template)
- Pre-existing warnings (GUID-02 unplaced objects, MAT-03 material by name, EXIT-04 direction hint mismatches)
- No new lint issues introduced by portal objects or tests

### Test Suite
- Full suite: 263 test files, ALL PASSED
- Zero regressions
- New tests: 186 total (45 + 59 + 82)

### Learnings
- Boundary portal pattern confirmed: `blocked_message` in non-traversable states, `bidirectional_id = nil`, no paired object
- Hallway-east-door is a "progressive boundary" — has a pry mechanic that reveals the passage is physically collapsed, giving players a sense of discovery even at a dead end
- Courtyard-kitchen-door is the most complex boundary portal — full FSM lifecycle (lock/unlock/open/close/break) but all states remain non-traversable until manor-kitchen exists in a future level
- All three portal objects were already created and room-wired by Flanders; Lisa's role was pure TDD verification
