# Nelson — Tester History

## Project Context
- **Owner:** Wayne "Effe" Berry
- **Project:** MMO — Lua text adventure engine
- **Stack:** Pure Lua, REPL-based, run via `lua src/main.lua`
- **Game starts in darkness** — player must feel around, find matchbox, light match to see
- **Key systems:** FSM engine for object state, Tier 2 embedding parser, container model, sensory verbs

## Critical Path
1. feel around → discover nightstand
2. open drawer → access matchbox
3. get matchbox → open matchbox → get match
4. light match (or strike match on matchbox) → room is lit
5. look around → see the room for the first time

## Core Context

**Agent Role:** Tester responsible for playtest validation, bug discovery, and regression verification.

**Testing Summary (2026-03-19 to 2026-03-23):**
- 12 playtests completed, 346+ tests run, 284+ passed
- Critical path: bedroom → cellar → storage-cellar → deep-cellar → hallway ✅ COMPLETE
- 60 unique bugs discovered (8 CRITICAL/HIGH, 20 MEDIUM+MAJOR, 4 LOW, 28 MINOR/COSMETIC)
- Phase 3 features (hit/unconsciousness/appearance/mirror): engine solid, parser gaps identified

### Effects Pipeline (EP1-EP10) ✅ COMPLETE (2026-03-23)
- **EP4:** Independently verified poison-bottle.lua refactor — 116/116 pass
- **EP9-EP10:** Authored 168 comprehensive bear-trap tests — 168/168 pass
- **Status:** Flanders' pipeline refactors validated, full coverage established
- **Impact:** 284 new tests, 0 regressions across pipeline milestone

**Current Status (2026-03-24 — Manifest Completion):**
- Put-Phrasing Test Pass: ✅ COMPLETE (36/36 tests, 15 pass rate)
- Issue Discovery: ✅ 6 ISSUES FILED (#79-84, all actionable)
- Engine core: ✅ SOLID
- Parser: ✅ EXCELLENT (Tier 2 embedding, "move" synonym, "feel around", sleep without "for", pronouns+prepositions+aliases)
- Level 1 Rooms: ✅ ALL LOAD (5/5 rooms, 15/15 exits correct)
- Level 1 Puzzle: ✅ COMPLETE — crate `.inside` surface FIXED (BUG-048), iron key accessible
- Display: ✅ FIXED — duplicate instance descriptions resolved (BUG-050)
- Critical Path: ✅ VERIFIED END-TO-END (bedroom → cellar → storage-cellar → deep-cellar → hallway)
- Dawn Light: ✅ NEW FEATURE — sleep until dawn enables `look` without matches
- Issue Fixes: ✅ ALL VERIFIED (#2, #3, #4, #5, BUG-065, #72, #78-84)

## Archives

- `history-archive-2026-03-20T22-40Z-nelson.md` — Full archive (2026-03-19 to 2026-03-20T22:40Z): all 7 playtests, 32 bugs, regression verification, pass-by-pass findings

- `history-archive.md` — Entries before 2026-07-14 (2025-07-17 to 2026-03-28)

## Bug Track Summary (62 unique)
- CRITICAL/HIGH (11): BUG-001, BUG-004, BUG-008, BUG-017, BUG-026, BUG-030 (ALL FIXED), BUG-036 (✅ PARTIALLY FIXED), BUG-048 (✅ FIXED), BUG-055, BUG-060 (✅ FIXED — on_traverse schema), BUG-061 (OPEN — wine bottle location needs `.inside` suffix)
- MAJOR (5): BUG-037, BUG-038, BUG-039 (parser), BUG-049 (✅ FIXED), BUG-050 (✅ FIXED)
- MEDIUM (13): Most FIXED; BUG-035 (GOAP spent match), BUG-051 (courtyard moonlight), BUG-052 (sarcophagus ambiguity), BUG-056 (plural names), BUG-058 (feel inside drawer)
- LOW (5): BUG-033, BUG-034, BUG-057 (rat feel), BUG-059 (uncork/drink no hold check), BUG-062 (✅ FIXED — drink verb checks on_drink_reject)
- MINOR/COSMETIC (28): Most fixed; BUG-040–047 open, BUG-053, BUG-054

## Recent Updates

### WAVE-0 Parallel: Lint Fixes #249, #250 + Portal TDD #203, #204 (2026-07-26)

**Status:** ✅ COMPLETE — All fixes applied, 178/178 test files pass

#### #249 — EXIT-01: 4 exits target non-existent rooms
- EXIT-01 no longer fires in lint (portal migration resolved inline exit checks)
- Found real bug: `courtyard-kitchen-door.lua` open/broken states were `traversable = true` targeting non-existent `manor-kitchen` — would cause runtime crash
- Fix: set `traversable = false` + `blocked_message` on open/broken states (collapsed masonry narrative)
- Other 3 boundary portals (hallway-level2-stairs-up, hallway-west-door, hallway-east-door) already safely blocked
- Commit: `621d27d`

#### #250 — GUID-02: 28 orphan objects not referenced by any room
- Added `orphan_allowlist` support to lint config system (`config.py` + `lint.py`)
- Created `.meta-check.json` with categorized suppressions:
  - 5 mutation targets, 3 portal variants, 5 traps, 6 healing/crafting, 9 unplaced objects
- All 28 GUID-02 warnings now suppressed with documented reasons
- Commit: `621d27d`

#### #203 — Portal TDD: deep-cellar ↔ hallway stairway (61 tests)
- Always-open stairway, wind traverse effects, bidirectional sync
- Commit: `b675174`

#### #204 — Portal TDD: deep-cellar ↔ crypt archway (75 tests)
- Locked/closed/open FSM with silver-key, bidirectional sync
- Commit: `b675174`

## Learnings

- EXIT-01 has a lint gap: portals can target non-existent rooms but the lint only validates `portal.target` exists as a string, not that the target room exists. The Phase 2 inline EXIT-01 check was bypassed by the portal migration.
- The `orphan_allowlist` pattern in `.meta-check.json` is a good model for other per-object suppressions. The config system only supports global rule enable/disable, not per-file. This extension adds targeted suppressions.
- `courtyard-kitchen-door` had a real traversal bug hiding behind the lint issue — the EXIT-01 warning was gone but the runtime error remained. Always verify runtime behavior, not just lint status.
- Portal TDD tests follow a consistent 10-section pattern: file loading → structure → metadata → states → transitions → sensory → movement → bidirectional sync → room wiring → keywords.

### P0 Fix Verification — Issues #132, #133, #135 (2026-07-25)

**Status:** ✅ ALL VERIFIED AND CLOSED

Verified Smithers' and Bart's P0 fixes for three issues. Full test suite + targeted test runs, zero regressions.

| Issue | Fix | Test File | Result |
|-------|-----|-----------|--------|
| **#133** — hit head max_health nil + second hit kills | max_health defensive init, damage ceiling | `test/injuries/test-hit-head.lua` | **14/14 PASS** |
| **#135** — compound find/get loses context | containers.open sets accessible, state persists | `test/search/test-compound-search-get.lua` | **14/14 PASS** |
| **#132** — `find match and get it` fails | compound 'and' split + pronoun resolution | `test/search/test-compound-search-get.lua` | **14/14 PASS** |

**Full suite:** 78/78 test files PASS, zero regressions.

**Actions taken:**
- Commented verification results on all three issues
- Closed #132, #133, #135 as completed

### Phase M4: Mirror/Appearance Quality Review (2026-07-25)

**Status:** ✅ COMPLETE — 8 scenarios tested, 6 bugs filed, 26 regression tests written

Full QA pass on the mirror/appearance system using `--headless` mode. Tested all player states: fresh, injured, bleeding, wearing items, holding items, multiple injuries, low health, unconscious.

| Test | Scenario | Mirror Output Grade | Issues |
|------|----------|-------------------|--------|
| T1 | Fresh player (empty hands) | ACCEPTABLE — "You appear healthy and alert." is functional but minimal | — |
| T2 | Single injury (stab self) | ACCEPTABLE — Shows gash+location but missing severity adjective | #93 |
| T3 | Bleeding player (bloody state) | ACCEPTABLE — Shows blood + injury but "and" chain awkward | #95 |
| T4 | Worn items (cloak + pot) | ROBOTIC — Cloak invisible, pot shows double period | #90, #91 |
| T5 | Holding items (knife + matchbox) | NATURAL — "your left hand grips a small matchbox" reads well | — |
| T6 | Multiple injuries (2 stabs) | ACCEPTABLE — Different locations shown; same-location collapsed | #92 |
| T7 | Low health (4 stabs) | NATURAL — "you look pale and unsteady" is good prose | — |
| T8 | Unconscious | NATURAL — "You can't examine yourself — you're unconscious." clear | — |

**Bugs filed (label: bug):**
- **#90** — Worn cloak invisible in mirror — appearance.lua only checks obj.wear_slot, not obj.wear.slot
- **#91** — Double period in mirror output when worn_description ends with period
- **#92** — Duplicate injuries at same body location silently collapsed
- **#93** — Injury severity never set — mirror shows bare nouns without adjectives
- **#94** — Mirror mixes grammatical structures in hands layer (held items + injuries joined awkwardly)
- **#95** — Overall health "and" joining produces awkward double-and phrasing

**Regression tests:** `test/verbs/test-mirror-appearance-m4.lua` — 26 tests (22 pass, 4 expected-fail tracking #90/#91/#92/#95)

**Additional findings:**
- "examine reflection", "examine self", "examine my reflection", "look at myself" all correctly route to appearance system ✅
- "look in mirror" route works ✅
- Health tiers (76-100%, 51-75%, 26-50%, 0-25%) all render correctly ✅
- Treated injuries show "wrapped in a bandage" ✅
- Sentence capitalization after periods works ✅
- Deathly pale tier (0-25%) may be unreachable in normal gameplay due to bleeding tick damage

---

### Put Verb Phrasing Test Pass (2026-07-25)

**Status:** ✅ COMPLETE — 36 tests (15 passed, 5 failed, 13 missing, 3 blocked)

Full test pass on "put" verb phrasing — all ways a player might place objects in/on/under furniture. Tested in headless mode in the start-room (bedroom).

| Category | Tests | Pass | Fail | Missing | Blocked |
|----------|-------|------|------|---------|---------|
| Put ON surfaces | 5 | 4 | 0 | 0 | 1 |
| Put IN containers | 5 | 3 | 0 | 0 | 2 |
| Put UNDER things | 3 | 0 | 0 | 3 | 0 |
| Invalid placements | 3 | 0 | 1 | 2 | 0 |
| Drawer interactions | 6 | 4 | 1 | 1 | 0 |
| Other placement verbs | 7 | 1 | 0 | 6 | 0 |
| Edge cases | 7 | 4 | 3 | 0 | 0 |

**Bugs filed (label: bug):**
- **#79** — Put in closed drawer bypasses accessibility check (wardrobe blocks correctly)
- **#80** — "put X in Y" silently misroutes to wrong surface when Y has no inside
- **#81** — Pronoun "that"/"it" not resolved in put verb hand search

**Features filed (label: feature):**
- **#82** — Put verb needs "under" and "inside" preposition support
- **#83** — Missing placement verb aliases (set, drop on, hide, stuff, toss, slide)

**Blockers found during setup:**
- Deep nesting flattener was already fixed (commit b867eb6)
- `_fv_parts` live-object lookup already fixed (same commit)
- Removed leftover debug dump from main.lua (commit 52610e7)

**Key findings:**
- Core put ON/IN works well for surfaces and open containers
- "under" preposition completely missing from put verb (3/3 fail)
- 6 natural placement verbs unrecognized (hide, stuff, toss, slide, set as put, drop on)
- Closed drawer accepts items but closed wardrobe correctly blocks — inconsistent
- "put X in nightstand/vanity" silently routes to top surface with misleading "in" narration
- Nightstand capacity=3 fills quickly (candle-holder + poison-bottle already on top)
- Brass key under rug inaccessible (rug blocked by bed) — 3 tests couldn't run

**Commit:** 52610e7

---

### Bedroom Door Regression Tests (2026-07-25)

**Status:** ✅ COMPLETE — 57 tests (50 passed, 0 failed, 7 skipped)

Pre-refactor regression tests for the bedroom north exit (heavy oak door) defined as exit metadata in `src/meta/world/start-room.lua`. Written BEFORE Wayne's planned refactor into a proper interactable object.

| Category | Tests | Status |
|----------|-------|--------|
| Door state (type, locked, key_id, breakable) | 12 | ✅ PASS |
| Mutation structure (open/close/break) | 13 | ✅ PASS |
| Verb interactions (open/unlock/go) | 8 | ⏭️ 7 SKIP (need full engine) |
| Exit integrity (all 3 exits) | 10 | ✅ PASS |
| Keyword matching | 3 | ✅ PASS |
| Passage constraints | 4 | ✅ PASS |
| Description/narrative | 5 | ✅ PASS |
| Negative tests | 2 | ✅ PASS |

**Key findings:** 7 verb handler tests skipped because `engine.verbs` requires full engine context to initialise. These tests are structured and ready — they will activate once handlers can be loaded in isolation or via integration test harness.

**Test file:** `test/rooms/test-bedroom-door.lua`
**Commit:** b2deaeb

---

### Stab & Hit-Head Regression Tests (2026-07-25)

**Status:** ✅ COMPLETE — 43 tests, 43 passed, 0 failed (100%)

Contract-first regression tests for issues #50 (stab doesn't create injuries), #49 (weapon inference), and #55 (hit head doesn't create injuries). Written BEFORE fixes to define the expected behavior.

| Category | Tests | Status |
|----------|-------|--------|
| Stab creates bleeding injury (#50) | 4 | ✅ PASS |
| Stab wound in injuries output (#50) | 2 | ✅ PASS |
| Stab wound ticks bleeding damage (#50) | 2 | ✅ PASS |
| Multiple stabs → multiple injuries (#50) | 3 | ✅ PASS |
| Weapon auto-inference (#49) | 2 | ✅ PASS |
| No weapon → helpful error (#49) | 1 | ✅ PASS |
| Multiple weapons → disambiguation (#49) | 1 | ✅ PASS |
| Knife metadata contract | 5 | ✅ PASS |
| Hit head → concussion + unconscious (#55) | 5 | ✅ PASS |
| Unconsciousness duration (#55) | 2 | ✅ PASS |
| Hit arm → bruise (#55) | 3 | ✅ PASS |
| Hit leg → bruise (#55) | 3 | ✅ PASS |
| Hit injuries in injuries output (#55) | 3 | ✅ PASS |
| Helmet armor reduction (#55) | 3 | ✅ PASS |
| Effects Pipeline integration (#55) | 2 | ✅ PASS |
| Bleed out during unconsciousness (#55) | 2 | ✅ PASS |

**Key finding:** All 43 tests PASS at the handler/unit level. The verb handlers (`stab`, `hit`) correctly create injuries when called directly. Bugs #50 and #55 are likely **integration-layer issues** — parser routing, injury definition loading, or game context initialization — not handler logic bugs.

**Test files:**
- `test/verbs/test-stab-regression.lua` (20 tests)
- `test/verbs/test-hit-head-regression.lua` (23 tests)

**Commit:** 0336ad9
**Bug refs:** #49, #50, #55
**Full suite:** 54 test files, all pass (no regressions)

### Nightstand Search Regression Tests (2026-07-25)

**Status:** ✅ COMPLETE — 44 tests, 44 passed, 0 failed (100%)

Permanent regression lock for the nightstand search bug that recurred 3 times across sessions. Written at Wayne's request after the bug kept coming back due to missing test coverage.

| Category | Tests | Status |
|----------|-------|--------|
| Object placement (matchbox in drawer) | 4 | ✅ PASS |
| "search for match" deeper-match logic | 3 | ✅ PASS |
| Search works in darkness (touch-based) | 4 | ✅ PASS |
| "search nightstand" finds drawer contents | 3 | ✅ PASS |
| No contradictory "nothing there" narration | 3 | ✅ PASS |
| Drawer resolves distinctly from nightstand | 3 | ✅ PASS |
| Nightstand "container" category (root cause) | 5 | ✅ PASS |
| Matchbox contains 7 fresh matches | 4 | ✅ PASS |
| Deeper search through nested containers | 4 | ✅ PASS |
| Touch-based discovery in darkness | 3 | ✅ PASS |
| Sleep idiom regression (to/til/till dawn) | 3 | ✅ PASS |
| End-to-end integration scenarios | 5 | ✅ PASS |

**Test file:** `test/search/test-nightstand-regression.lua`
**Commit:** 58605da
**Bug refs:** #22, #33, #34, #40, #43, #44, BUG-125
**Full suite:** 49 test files, all pass (no regressions)

### EP2: Poison Bottle Regression Tests (2026-07-25)

**Status:** ✅ COMPLETE — 116 tests, 116 passed, 0 failed (100%)

Pre-refactoring safety net for the Effects Pipeline refactor. These tests lock down the current poison bottle + nightshade injury behavior so any regression introduced by the refactor is caught immediately.

| Category | Tests | Status |
|----------|-------|--------|
| Identity & metadata | 11 | ✅ PASS |
| FSM state transitions (sealed→open→empty, rejected paths, aliases) | 32 | ✅ PASS |
| Consumption → injury flow (nightshade definition, inflict/tick/death) | 19 | ✅ PASS |
| Sensory properties (per-state descriptions, all senses) | 22 | ✅ PASS |
| Fair warning chain (label, smell, taste hierarchy) | 10 | ✅ PASS |
| Nested parts (cork detach, factory, label, liquid tracking, GOAP) | 22 | ✅ PASS |

**Test file:** `test/verbs/test-poison-bottle.lua`
**Commit:** c9047d8
**Full suite:** 45 test files, all pass (no regressions)

## Learnings

### EP2: Poison Bottle Regression Testing (2026-07-25)

- **Writing pre-refactor regression tests is the RIGHT approach.** These 116 tests define the contract before the Effects Pipeline refactor starts. If a test that passes now fails after refactoring, the refactor broke something — not the test.
- **dofile() is the cleanest way to load object/injury definitions** for testing. The `return { ... }` pattern in definition files makes them directly evaluable. No need for complex loaders in unit tests.
- **The wine-fsm test in test/verbs/ is the gold standard** for FSM object testing: fresh object → registry → transition → assert. Followed same pattern for poison bottle.
- **on_taste_effect structured table is NOT currently processed** by the taste handler in verbs/init.lua. The handler only checks for hardcoded string enums ("poison", "nausea"), not the `{ type = "inflict_injury", ... }` table. The definition has the data, but it's dead code until the Effects Pipeline refactor connects it.
- **deep_copy utility handles Lua functions correctly** — functions are copied by reference (not duplicated), which is correct since closures capture their environment.
- **Injury engine test definitions differ from actual definitions.** test-injury-engine.lua uses `initial_damage = 15` for its test nightshade definition, but the actual `src/meta/injuries/poisoned-nightshade.lua` uses `initial_damage = 10`. My tests lock down the ACTUAL values.
- **Test count:** Full suite now has 45 test files (was 44). The poison bottle test adds 116 individual assertions.

### Verification: Issues #85, #86, #87 (2026-07-25)

**Status:** ✅ FIXES VERIFIED — 11/12 pass, 1 new bug found (BUG-116)

Verified Smithers' fixes for search traversal (#85), wear auto-pickup (#86), and get-from-container (#87).

| Issue | Fix | Tests | Result |
|-------|-----|-------|--------|
| #85 | expand_object queues root container contents | 3 | ✅ ALL PASS |
| #86 | wear auto-pickup from open container | 3 | ✅ ALL PASS |
| #87 | get X from Y container extraction | 5 | ✅ 4 PASS, 1 FAIL |
| Regression | basic take from floor | 1 | ✅ PASS |

**New bug filed:** BUG-116 — `get X from Y` ignores container `accessible` flag. When a drawer is closed (`accessible = false`), `get matchbox from drawer` still succeeds. The `get X from Y` code path at verbs/init.lua:2296 checks `bag.container and bag.contents` but never checks `bag.accessible`. Surface-based containers DO gate on `zone.accessible ~= false` (line 2301), but root-content containers don't.

**Regression suite:** 73 test files, 71 pass, 2 fail. Failures are:
- `test-mirror-appearance-m4.lua` — 4 expected-fail tests (pre-existing #90/#91/#92/#95)
- `test-verify-85-86-87.lua` — 1 new fail (BUG-116)

**Test file:** `test/verbs/test-verify-85-86-87.lua` — 12 tests

## Learnings

### Issue #128: BUG-061 Wine Bottle Puzzle Retest (2026-07-24)

**Status:** ✅ PASS — bug confirmed fixed, regression tests expanded
**Test file:** `test/verbs/test-wine-fsm.lua` — 34 tests (23 existing + 11 new), all pass
**Issue:** #128

- BUG-061 root cause was type_id mismatch between wine-bottle.lua GUID and storage-cellar.lua instance
- Fix verified: type_id now matches, wine-bottle properly nested in wine-rack contents
- Full headless playtest: navigate to storage-cellar → take wine bottle → open → drink → terminal state all work
- Added 11 regression tests: sensory per-state changes, pour-from-sealed blocked, drink aliases (quaff/sip/swig), throw alias, full puzzle chain
- Test fixture `fresh_wine_bottle()` needed sensory fields (on_feel, on_taste) added to match actual object definition
- Full suite: 107/107 test files pass, zero regressions

### Issue #123: TDD Material Migration Safety Tests (2026-07-25)

**Status:** ✅ GREEN BASELINE — 15/15 tests pass, 121/121 full suite pass
**Test file:** `test/objects/test-material-migration.lua`
**Issue:** #123

- Wrote 15 TDD tests across 3 suites (Public API, Cross-reference, Migration Safety) before Smithers migrates materials from monolithic `src/engine/materials/init.lua` to per-file `src/meta/materials/`
- Discovery: `src/meta/materials/` already exists with 23 per-file .lua files — test 11 confirmed they load correctly via dofile
- Existing tests (`test-material-properties.lua`, `test-material-audit.lua`) covered property completeness and object→material audit but lacked migration-specific contract testing (exact count=23, value spot-checks, armor/burn cross-reference, per-file directory detection)
- Cross-reference tests verify the two main engine consumers: armor system (hardness-based protection) and burn system (flammability >= 0.3 threshold)
- Spot-check values pinned: ceramic.hardness=7, brass.fragility=0.1, glass.fragility=0.9, silver.density=10490, wax.melting_point=60
- Key learning: TDD-first for migrations is extremely valuable — the tests document the exact API contract that must survive, making the migration a mechanical transformation rather than a risky refactor

**Bug Status:** 0 CRITICAL, 0 HIGH (Phase 3 regressions prevented)

**Outcome:** Engine SOLID, ready for Phase 3+ expansion. Foundation validated.

**Output:** `.squad/log/2026-03-23T16-00Z-wave2-bugfix-objects.md`
- ❌ BUG-074: 'look for the matchbox' triggers 'look' instead of 'find' (HIGH priority)
- ❌ BUG-075: 'search nightstand' finds nothing (CRITICAL regression — drawer exists but not discovered)
- ❌ BUG-076: 'find something to light' HANGS game (CRITICAL)
- ❌ BUG-077: 'search for a match' HANGS game (CRITICAL, likely same root as BUG-076)

**Part 2: Nightstand Regression**
- ✅ Full chain works: feel around → examine nightstand → open drawer → feel drawer → get matchbox → open matchbox → get match → light match → look
- ✅ Writing quality exceptional throughout
- ❌ BUG-075 confirmed: 'search nightstand' regression (says "nothing there" despite drawer+matchbox)
- ⚠️ Inconsistency: 'search around' opens drawers automatically, 'search nightstand' does not

**Critical Issues**:
1. **BUG-076, BUG-077** — Game hangs (infinite loop) on abstract/multi-word targets
2. **BUG-075** — Discovery regression breaks natural 'search [object]' command
3. **BUG-074** — "look for X" is common English but misinterpreted as "look"
4. **BUG-073** — "search the room" should work like "search around"

**Incomplete Testing** (~25 tests blocked):
- Compound commands ('search X for Y')
- Abstract targets ('something to...', 'anything...')
- Question phrasings ('where is...', 'what's in...')
- Creative verbs ('hunt', 'rummage', 'check')

**Player Experience**:
- Confused Newbie: C+ (major command misfires)
- Impatient Gamer: D (hangs unacceptable)
- Natural Language Speaker: D+ (too many natural phrasings fail)

**Verdict**: ⚠️ CONDITIONAL PASS — core critical path works perfectly, writing excellent, but 5 critical bugs (3 P0, 1 P1, 1 P2) must be fixed before release. DO NOT SHIP until hangs resolved.

**Action Required**:
1. Fix BUG-076, BUG-077 (hangs) — blocks further testing
2. Fix BUG-075 (search regression) — breaks discovery
3. Fix BUG-074 ("look for X")
4. Re-run Pass-025 with remaining creative phrasings

**Reports**:
- Test pass: test-pass/2026-03-22-pass-024.md
- Bug inbox: .squad/decisions/inbox/nelson-search-playtest-bugs.md

### F1 Verification Pass (2026-07-25)

**Status:** ✅ COMPLETE — 20 new verification tests, all pass. 6 mirror bugs now resolved.

**Part 1: F1 Bug Fix Verification (Smithers commit 5738359)**

| Bug | Summary | Verified | Tests |
|-----|---------|----------|-------|
| #47 | Dark search narration uses "feel"/"grope" not "find"/"see" | ✅ PASS | V47-1 through V47-5 |
| #49 | "stab yourself" auto-infers weapon from hands | ✅ PASS | V49-1 through V49-4 |
| #52 | Mirror shows worn items, held items, injuries, health | ✅ PASS | V52-1 through V52-5 |
| #53 | "get pot" outputs take message exactly once | ✅ PASS | V53-1 through V53-3 |
| BUG-116 | "get X from Y" blocked when container closed | ✅ PASS | V116-1 through V116-3 |

**Part 2: Mirror Bugs #90-95 — Status After Smithers' #52 Fix**

All 6 mirror bugs are now FIXED. The 4 previously expected-fail tests in `test-mirror-appearance-m4.lua` now pass:

| Bug | Summary | Status | How Fixed |
|-----|---------|--------|-----------|
| #90 | Worn cloak invisible (wear.slot not checked) | ✅ FIXED | `get_wear_slot()` now checks both `obj.wear_slot` and `obj.wear.slot` |
| #91 | Double period in mirror output | ✅ FIXED | `describe()` strips trailing periods before joining with ". " |
| #92 | Duplicate injuries at same location collapsed | ✅ FIXED | `compose_natural()` deduplicates identical phrases; distinct injuries (different index → different adjective) survive |
| #93 | Injury severity adjectives dead code | ✅ FIXED | `render_injury_phrase()` uses `pick_severity_adjective()` with severity field, "moderate" → "deep"/"nasty" |
| #94 | Hands layer grammar mixes structures | ✅ FIXED | `render_hands()` uses consistent "your X hand grips Y" + injury phrases through `compose_natural()` |
| #95 | Overall health double-and chain | ✅ FIXED | `render_overall()` uses semicolons between phrases when they contain "and" |

**Regression Suite:** 74/74 test files pass (0 failures).

**Test file:** `test/verbs/test-verify-f1-bugs.lua` — 20 tests

- Smithers' #52 fix was comprehensive — addressed wear.slot resolution, double-periods, injury deduplication, severity adjectives, hands grammar, and overall health composition in one commit
- The semicolon fix for #95 is elegant — avoids awkward "healthy and alert and dried blood" by using "; " as separator when phrases already contain "and"
- Mirror appearance system is now production-quality — all 26 M4 tests pass, all 6 filed bugs resolved

---

### Phase A3: Armor Interceptor TDD Tests (30 tests)
- **Status:** DELIVERED
- **File:** `test/armor/interceptor/`
- **Test Results:** 14 pass, 16 fail (by design, awaiting implementation)
- **Purpose:** Serve as implementation specification for Bart (Phase A1)
- **Dependency:** Bart implementing armor system to make these tests pass

### Decision Updates
- **D-PLANT-MATERIAL:** Added `plant` material to registry (ivy.lua, future botanical objects)
- **D-SELF-INFLICT-CEILING:** Self-inflicted injuries can never kill (except external damage can)
- **D-SEARCH-ACCESSIBLE:** Search container open must set `accessible = true`

### Cross-Team Notes
- Material audit validation test should include plant material verification
- No engine changes needed for plant material — registry is self-extending
### Material Audit CI Test (#163) (2026-07-16)

**Status:** ✅ COMPLETE — 6/6 tests pass

Wrote `test/objects/test-material-audit.lua` — structural CI gate that prevents material regressions.

**What it checks:**
- Every `.lua` file in `src/meta/objects/` loads successfully
- Every object declares a `material` field (string type)
- Every material value exists in `src/engine/materials/init.lua` registry
- Registry sanity (10+ materials present)

**Results:** 83/83 objects scanned, 23 materials in registry, all valid.

**Pattern:** Followed `test-object-templates.lua` structural test pattern (file discovery → load → field validation → registry cross-check). Already picked up by `test/run-tests.lua` via the `test/objects/` directory scan.

**Note:** Pre-existing failure in `injuries/test-weapon-pipeline.lua` ("dagger stab damage is 8") — unrelated to this change.


### Issue #113: Tutorial Coverage Gaps — EXTINGUISH, EAT, BURN (2026-07-22)

**Status:** COMPLETE — 12/12 tests pass, 106/106 full suite pass, 0 regressions

**What was done:**
- Added one-shot hint system (`show_hint()` in helpers.lua) tracked on `player.state.hints_shown`
- EXTINGUISH hint triggers after successful `light` verb — teaches `extinguish` / `blow out`
- BURN hint triggers after successful `light` verb — teaches `burn [item]` on flammable objects
- EAT hint triggers after eating edible objects AND when tasting edible objects — teaches `eat [item]`
- Enhanced no-noun messages for all three verbs with tutorial guidance
- 12 new tests in `test/verbs/test-tutorial-hints.lua`

**Files changed:** `src/engine/verbs/helpers.lua`, `src/engine/verbs/fire.lua`, `src/engine/verbs/survival.lua`, `src/engine/verbs/sensory.lua`

**Key learning:** The project has no dedicated tutorial system — tutorial coverage is achieved through contextual hints embedded in verb handlers and object interactions. One-shot hints tracked on `player.state` is a clean, non-invasive pattern. Room contents arrays hold string IDs, not object tables (caught by failing test).

### Issue #123: Material Data Migration — QA Verification (2026-07-24)

**Status:** ✅ VERIFIED — registry data is complete and correct, migration not yet performed
**Issue:** #123
**New test file:** `test/objects/test-material-properties.lua` — 11 tests, all pass

- Material registry holds 23 materials in `src/engine/materials/init.lua`, each with complete 11-property bag
- Core properties: density, melting_point, ignition_point, hardness, flexibility, absorbency, opacity, flammability, conductivity, fragility, value
- Iron and steel have bonus `rust_susceptibility` property — acceptable extension
- 83/83 objects declare a valid material field referencing the registry
- Templates (container, small-item) use `material = "generic"` as default — not in registry but safe since all instantiated objects override
- The monolithic→per-file migration (`src/meta/materials/`) has NOT been performed yet — data is ready for it
- Existing `test-material-audit.lua` (6 tests) covers object→registry linkage; new `test-material-properties.lua` (11 tests) covers property completeness, value ranges, API behavior
- Full suite: 109 test files, all passing, zero regressions

**Key learning:** The material registry is well-structured — every material has a consistent schema with no missing properties. The `generic` material in templates is a design choice (template defaults get overridden), not a bug. When validating data migrations, check both the source data completeness AND whether the migration itself has been executed.

### Issue #166: Fabric Burn Verification (2026-07-25)

**Status:** ✅ COMPLETE — 35 tests, 35 PASS, 0 bugs found
**Test file:** `test/verbs/test-fabric-burn.lua`
**Issue:** #166

**Design Verification:**
- All 7 fabric materials in registry have flammability ≥ 0.3 (burn threshold from #120):
  fabric (0.6), wool (0.4), cotton (0.7), velvet (0.6), linen (0.5), hemp (0.5), burlap (0.6)
- All 15 fabric objects have correct material assignment: curtains (velvet), wool-cloak (wool),
  bandage (linen), bed-sheets (cotton), terrible-jacket (fabric), blanket (wool), cloth (fabric),
  cloth-scraps (fabric), rag (fabric), sack (fabric), grain-sack (burlap), pillow (linen),
  rug (wool), rope-coil (hemp), thread (cotton)
- No `trousers.lua` exists yet. No silk material in registry (none needed).
- **Verdict: Zero bugs.** Every fabric object can burn.

**Tests written (35):**
- 7 material registry threshold checks (flammability ≥ 0.3 for each fabric material)
- 15 fabric object burn tests (every fabric object catches fire with flame)
- 3 narration quality tests (fire-related language in output)
- 4 negative tests (stone, steel, brass, silver correctly refuse to burn)
- 4 full-chain tests (hold + burn = destroyed + hand empty)
- 2 no-flame rejection tests (fabric won't burn without flame source)

**Full suite:** 120/120 test files pass, zero regressions.

**Key learning:** The existing `test-burn-material.lua` (from #120) already covered generic material
thresholds, but lacked per-object fabric coverage. This new file ensures every actual fabric object
in the game world — not just the material type — correctly participates in the burn system.
The wool material at 0.4 is the lowest fabric flammability, just above the 0.3 threshold;
future fabric materials should stay above 0.3 or explicitly document why they don't burn.

## Learnings

- **Match provides_tool is state-gated:** The real match.lua only has `provides_tool = "fire_source"`
  inside `states.lit`, not at root. The test-fire-verbs.lua existing tests use a SIMPLIFIED match
  with root-level provides_tool, which bypasses the bug. Always use REALISTIC object definitions
  in tests matching the actual .lua files.
- **Door object vs exit duality:** Rooms can have BOTH a door OBJECT (with FSM states) and an EXIT
  DOOR (in room.exits). The open handler's find_visible finds the object first; if the FSM can't
  open it, the handler returns without checking exits. This was fixed (#170) with state-specific
  error messages using on_push.
- **Container preposition leaks:** The put handler uses parsed `prep` instead of
  `container_preposition` for success messages. Error messages correctly use container_preposition
  (from containment engine), but success messages don't.
- **Burn redirect error messages:** When the light→burn redirect fires, error messages from the
  burn handler mention "burn" instead of "light", confusing the player.
- **Full verification pass (2026-07-24):** Ran complete test suite after bugs #168-#173 were fixed.
  126 test files, 3342 tests, 0 failures. All 6 bug-specific test files pass: test-light-fire-source (4/4),
  test-light-burn-redirect (5/5), test-sack-capacity (6/6), test-door-resolution (16/16),
  test-compound-commands (29/29). Headless smoke tests confirm critical path works: search around,
  get candle, and compound 'get candle, and light it' all execute correctly. Commented verified on
  all 6 issues (#168-#173). Verdict: PASS.
- **TDD Red Phase for Prime Directive Tiers 1-5 (#106):** Wrote 73 failing tests across 5 tiers.
  Used pcall-protected requires for non-existent modules (idioms.lua, questions.lua, errors.lua)
  so each test fails with a meaningful message rather than a blanket module-not-found crash.
  For existing modules (context.lua, fuzzy.lua), tested new API functions that don't exist yet.
  Key pattern: test the CONTRACT (what behavior should exist) not the implementation details.
  Test files: test-idioms.lua (21), test-questions.lua (16), test-error-messages.lua (+12),
  test-context-window.lua (+10), test-fuzzy-resolution.lua (14). Zero regressions in existing suite.

- **Verification of Prime Directive Tiers 1-5 (#106) (2026-03-24):** Smithers
  implemented all 5 tiers. Full verification pass: 129 test files, 0 suite failures. All 5 tier test
  files pass clean — test-idioms (21/21), test-questions (16/16), test-error-messages (19/19),
  test-context-window (53/53), test-fuzzy-resolution (18/18) — 127 tier-specific tests total.
  Headless smoke tests confirm live pipeline: 'take a look' resolves via idiom tier, 'where am I?'
  resolves via question tier, 'examine candel' resolves via fuzzy tier in darkness. Pre-existing
  failures in search (#24) and burn unrelated to parser tiers. Commented on #106. Verdict: PASS.

- **#174 — SLM Embedding Index Overhaul** (Smithers)
  Verified slim index loads correctly: embedding-index.json is 361.6 KB (down from 15.3 MB full).
  Archived full index preserved at resources/archive/embedding-index-full.json (15.3 MB).
  All 129 test files PASSED — zero regressions. Smoke tests: 'take a look' resolved to look,
  'gimme candle' processed without crash, 'examine match' resolved to examine in darkness.
  Parser pipeline loads slim index and processes all input. Commented on #174. Verdict: PASS.

- **#162 — TDD Red Phase: Unconsciousness Triggers** (2026-07-26)
  Wrote `test/injuries/test-unconsciousness-triggers.lua` — 39 tests across 12 suites.
  TDD contract for 4 trigger objects (falling-rock-trap, unstable-ceiling, poison-gas-vent,
  falling-club-trap) per CBG's design doc. Results: 31 FAIL / 8 PASS (expected red phase).
  8 passing tests verify existing engine behavior: injury ticking during KO, wake-in-same-room,
  self-KO + external bleeding death, inventory/get rejection while unconscious.
  Bug found: `look` while unconscious crashes (sensory.lua:163 nil noun) — verb handlers
  don't gate on consciousness state. Commented on #162 with handoff to Flanders/Smithers/Bart.
  Branch: `squad/162-tdd-unconsciousness-triggers`. Zero regressions in existing suite.

- **#178 — TDD Red Phase: Match Burn-Out via auto_ignite Bypass** (2026-07-27)
  Wrote `test/verbs/test-match-burnout.lua` — 10 tests across 4 suites. 4 FAIL / 6 PASS.
  **Root cause found:** `auto_ignite()` in `fire.lua` sets `_state = "lit"` directly without calling
  `fsm.start_timer()`. When player types "light candle" with an unlit match, the match is auto-ignited
  through this bypass path — no burn timer registered, match stays lit forever. The explicit
  `strike match on matchbox` path works correctly because it goes through `fsm.transition()` which
  calls `start_timer()`. Fix: `auto_ignite()` must call `fsm_mod.start_timer(registry, obj_id)`.
  Key insight: ANY code path that changes `_state` outside `fsm.transition()` will bypass timers.
  Search for direct `_state =` assignments — there are at least 3 in the codebase (auto_ignite,
  meta.lua set handler, helpers.lua detach/reattach). All may need timer auditing.

- **#180 — TDD Regression Guards: Wear-From-Hand Slot Clearing** (2026-07-27)
  Wrote `test/inventory/test-wear-hand.lua` — 9 tests across 3 suites. 9 PASS / 0 FAIL.
  The `wear` handler in `equipment.lua` correctly clears the hand slot in all three code paths
  (direct hand, auto-pickup from room, auto-fetch from container). Wayne's bug (spittoon in both
  hand AND worn) does NOT reproduce at the handler level. Bug likely manifests at integration level
  (parser routing, compound commands, or game-loop state). Tests serve as regression guards.

- **WAVE-2 TDD: Creature Tick + Stimulus System** (2026-07-28)
  Wrote 2 test files for WAVE-2 of NPC+Combat implementation plan.
  `test/creatures/test-creature-tick.lua` — 25 tests across 9 suites. 25 PASS / 0 FAIL.
  Tests drive updates (hunger/fear/curiosity), drive clamping (min 0, max 100), behavior selection
  (high fear → flee, low fear → idle/wander), edge cases (empty room, dead creatures skipped),
  wander movement via portal-based exits, closed-door blocking, flee movement, multiple creature
  independence, 5-creature performance gate (<50ms), perception range boundary (distant creatures
  excluded from stimuli), get_creatures_in_room filtering, phase sequencing guard (no combat actions
  per D-COMBAT-NPC-PHASE-SEQUENCING), and message collection scoped to player room.
  `test/creatures/test-stimulus.lua` — 17 tests across 7 suites. 17 PASS / 0 FAIL.
  Tests stimulus emission (player_enters, loud_noise, light_change), fear_delta application,
  multiple stimuli stacking, perception range boundary for stimulus delivery, pcall guards
  (nil type, nil data, nonexistent room, unknown stimulus type), empty room safety, and
  stimulus queue consumption after tick.
  All 42 tests PASS against Bart's existing `engine/creatures/init.lua`. Mocks use portal-based
  exits matching the real engine API (registry:list(), creature.location, context.rooms table).
  Key finding: engine module already exists from Bart's WAVE-2 work — tests validate the
  implementation rather than serving as pure red-phase TDD. No regressions in existing suite.

---
