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

**Testing Summary (2026-03-19 to 2026-03-21):**
- 10 playtests completed, 266+ tests run, 221+ passed
- Critical path: bedroom → cellar → storage-cellar → BLOCKED at crate contents (BUG-048)
- 54 unique bugs discovered (8 CRITICAL/HIGH, 15 MEDIUM+MAJOR, 2 LOW, 29 MINOR/COSMETIC)
- All Level 1 rooms load, connect, and render correctly — writing is exceptional
- 2 CRITICAL open (BUG-036, BUG-048)

**Current Status:**
- Engine core: ✅ SOLID
- Parser: ✅ WORKING (Tier 2 embedding), missing "with" preposition + "pry" verb
- Level 1 Rooms: ✅ ALL LOAD (5/5 rooms, 15/15 exits correct)
- Level 1 Puzzle: ✅ COMPLETE — crate `.inside` surface FIXED (BUG-048), iron key accessible
- Display: ✅ FIXED — duplicate instance descriptions resolved (BUG-050)
- Critical Path: ✅ VERIFIED END-TO-END (bedroom → cellar → storage-cellar → deep-cellar → hallway)

## Archives

- `history-archive-2026-03-20T22-40Z-nelson.md` — Full archive (2026-03-19 to 2026-03-20T22:40Z): all 7 playtests, 32 bugs, regression verification, pass-by-pass findings

## Recent Updates

### Pass-017: Puzzle Retest — BUG-060/061/062 (2026-03-21)

**Status:** ✅ COMPLETE — 11 retests, 4 passed, 6 failed, 1 blocked (36%)

| Category | Tests | Passed | Failed | Blocked | Notes |
|----------|-------|--------|--------|---------|-------|
| Puzzle 015: Draft Extinguish | 4 | 3 | 0 | 1 | ✅ BUG-060 FIXED |
| Puzzle 016: Wine Drink | 6 | 0 | 6 | 0 | 🔴 BUG-061 NOT FIXED |
| Oil Flask Drink Rejection | 1 | 1 | 0 | 0 | ✅ BUG-062 FIXED |

**Bug Verdicts:**
- BUG-060 ✅ FIXED: `normalize_effect` handles both formats. Wind extinguishes candle on deep-cellar→hallway traversal.
- BUG-061 ❌ NOT FIXED: Wine bottle `location = "wine-rack"` needs to be `"wine-rack.inside"`. One-line data fix.
- BUG-062 ✅ FIXED: Drink handler fallback checks `on_drink_reject`. Oil flask prints custom gagging text.

**Blocked:** Oil lantern wind-resistance test — can't fuel lantern (pour/fill/fuel verbs don't resolve two-object interaction)
**Full Report:** test-pass/2026-03-21-pass-017-puzzle-retest.md

### Pass-016: Puzzles & UX Polish Playtest (2026-03-21)

**Status:** ✅ COMPLETE — 26 tests, 15 passed, 11 failed (58%)

| Category | Tests | Passed | Failed | Notes |
|----------|-------|--------|--------|-------|
| Multi-Command Input | 6 | 6 | 0 | All separators work perfectly |
| Visited Room Tracking | 5 | 5 | 0 | Short desc on revisit, full on look |
| Report Bug Command | 3 | 3 | 0 | URL, intro mention, context-aware |
| Puzzle 015: Draft Extinguish | 4 | 0 | 4 | 🔴 Schema mismatch — never fires |
| Puzzle 016: Wine Drink | 6 | 0 | 6 | 🔴 Wine bottles not accessible |
| Oil Flask Drink Rejection | 2 | 1 | 1 | Generic msg, not custom rejection |
| **TOTAL** | **26** | **15** | **11** | |

**New Bugs (3):**
- BUG-060 (CRITICAL): `on_traverse` wind effect schema mismatch — engine vs room data contract broken
- BUG-061 (HIGH): Wine bottles not instantiated in wine rack — ID mismatch
- BUG-062 (LOW): Drink verb ignores `on_drink_reject` custom text

**Major Wins:** Multi-command input, visited room tracking, report bug command all PASS
**Full Report:** test-pass/2026-03-21-pass-016-puzzles-ux.md
**Bug Report:** .squad/decisions/inbox/nelson-puzzle-test.md

### Pass-015: Deep Level 1 Playtest (2026-03-21)

**Status:** ✅ COMPLETE — 149 tests, 137 passed, 12 failed (92%)

| Category | Tests | Passed | Failed | Notes |
|----------|-------|--------|--------|-------|
| Room Visits (all 7) | 7 | 7 | 0 | All rooms load and connect |
| Object Interactions | 53 | 49 | 4 | Rat feel, plural forms, drawer |
| Verb Coverage | 22 | 19 | 3 | pry ✅, match hand bug |
| Compound Commands | 5 | 5 | 0 | "X and Y" chains perfectly |
| Natural Language | 14 | 11 | 3 | "I want to..." fixed |
| Edge Cases | 12 | 12 | 0 | Clean rejections throughout |
| Bug Verification | 12 | 11 | 1 | BUG-049/050 fixed, 036 partial |
| Sleep/Time/Death | 5 | 5 | 0 | All working |
| Dark Room Behavior | 8 | 8 | 0 | Sensory verbs work in dark |
| **TOTAL** | **149** | **137** | **12** | |

**New Bugs (5):**
- BUG-055 (HIGH): Spent match stays in hand after "dropping" — blocks taking candle
- BUG-056 (MEDIUM): Plural object names not recognized by parser
- BUG-057 (LOW): Rat feel description says "heavy piece of furniture"
- BUG-058 (MEDIUM): `feel inside drawer` fails (inconsistent with crate)
- BUG-059 (LOW): uncork/drink work without holding object

**Verified Fixes:** BUG-049 (pry), BUG-050 (duplicates), BUG-036 (partial), Moe's north door fix
**Full Report:** test-pass/2026-03-21-pass-015-deep-level1.md

### Pass-014: Critical Path Test — Level 1 (2026-03-21)

**Status:** ✅ COMPLETE — CRITICAL PATH VERIFIED

| Category | Tests | Passed | Failed | Notes |
|----------|-------|--------|--------|-------|
| Bedroom Setup | 5 | 5 | 0 | Feel, drawer, matchbox, GOAP light candle |
| Bedroom Puzzle | 4 | 4 | 0 | Push bed, pull rug, brass key, trap door |
| Cellar Navigation | 3 | 3 | 0 | Unlock + open door with brass key |
| Crate Interaction (BUG-048) | 6 | 5 | 1 | Iron key accessible — FIX VERIFIED |
| Deep Cellar → Hallway | 3 | 3 | 0 | Unlock with iron key, go up |
| Duplicate Presences (BUG-050) | 2 | 2 | 0 | Hallway clean — FIX VERIFIED |
| Inventory Management | 3 | 3 | 0 | Two-hand limit, drop/get cycle |
| **TOTAL** | **26** | **25** | **1** | |

**Key Findings:**
1. **BUG-048 FIXED**: `look inside crate`, `feel inside crate`, `get iron key` all work after prying open
2. **BUG-050 FIXED**: Hallway displays torches/portraits/table once each, no duplicates
3. **OBS-001**: North exit from bedroom to hallway is UNLOCKED — bypasses entire cellar puzzle
4. **BUG-049 still open**: `pry crate` → "I don't understand that"

**Full Report:** test-pass/2026-03-21-pass-014-critical-path.md

### Pass-013: Full Level 1 Room-by-Room Testing (2026-03-21)

**Status:** ✅ COMPLETE

| Category | Tests | Passed | Failed | Notes |
|----------|-------|--------|--------|-------|
| Room Loading | 5 | 5 | 0 | All 5 Level 1 rooms load |
| Feel in Dark | 5 | 5 | 0 | All rooms list objects by touch |
| Examine Objects | 14 | 14 | 0 | on_feel fallback works everywhere |
| Sensory Verbs | 8 | 8 | 0 | smell/listen in hallway, courtyard, crypt |
| Exit Navigation | 15 | 15 | 0 | All exits connect or block correctly |
| Get/Drop Items | 6 | 6 | 0 | Crowbar, candle, key, match |
| Container Puzzle | 4 | 2 | 2 | Crate opens, contents trapped |
| Unlock/Open Doors | 3 | 3 | 0 | Brass key + cellar door |
| Parser (with) | 2 | 0 | 2 | "pry" unknown, "with" fails |
| Display (dupes) | 6 | 0 | 6 | 3 rooms have duplicate instances |
| Light System | 2 | 1 | 1 | Hallway lit, courtyard moonlight ignored |
| Critical Path | 12 | 11 | 1 | Blocked at crate contents |
| **TOTAL** | **94** | **82** | **12** | |

**New Bugs (7):**
- BUG-048 (🔴 CRITICAL): Iron key trapped inside crate — `.inside` surface never exposed after prying open. BLOCKS ALL Level 1 progression.
- BUG-049 (🟡 MAJOR): "pry X with Y" and "open X with Y" both fail — parser doesn't handle tool prepositions
- BUG-050 (🟡 MAJOR): Duplicate instance descriptions — torches ×2, portraits ×3, sarcophagi ×5 repeat identical text
- BUG-051 (🟠 MEDIUM): Courtyard moonlight (light_level=1) ignored — outdoor room treated as dark
- BUG-052 (🟠 MEDIUM): 5 identical sarcophagi in crypt — no way to target specific ones
- BUG-053 (⚪ MINOR): on_enter text references "your light" when player has no light source
- BUG-054 (⚪ MINOR): Rat has no on_feel description

**Major Wins:**
1. Writing quality across all 5 rooms is extraordinary — best atmospheric text in a text adventure
2. Hallway warmth-after-darkness is a genuine emotional payoff
3. All 15 exits tested — connections correct, locked doors block, Level 2 boundary holds
4. GOAP crowbar auto-use on crate is magic
5. Candle timer creates real resource management tension
6. Carried light works across room transitions seamlessly

**Full Report:** test-pass/gameplay/013-pass-2026-03-21.md
**Puzzle Feedback:** .squad/decisions/inbox/nelson-puzzle-feedback-pass013.md

### Pass-012: Natural Language + New Player Simulation (2026-03-21)

**Status:** ✅ COMPLETE

| Category | Tests | Passed | Failed | Notes |
|----------|-------|--------|--------|-------|
| Natural Language | 14 | 7 | 7 | "I" prefix, "what's around me", "use X on Y" |
| Multi-Word Objects | 12 | 10 | 2 | Hyphen in "four-poster" breaks match |
| Typos/Near-Misses | 4 | 0 | 4 | ≤4-char words skip fuzzy (by design D-BUG018) |
| Confused Player | 12 | 8 | 4 | Directions, scenery, verb routing |
| Sensory Verbs | 4 | 4 | 0 | listen/smell are extraordinary |
| GOAP/Critical Path | 8 | 8 | 0 | Zero regressions |
| Edge Cases | 10 | 7 | 3 | drop all, examine self, noun-only |
| Random/Gibberish | 4 | 4 | 0 | Clean error messages |
| Help System | 4 | 4 | 0 | "what can I do", "how do I get out" → help |
| Ambiguity | 6 | 4 | 2 | "light" bare, search intransitive |
| **TOTAL** | **78** | **56** | **22** | |

**New Bugs (12):**
- BUG-036 (🔴 CRITICAL): "I" at sentence start triggers inventory — any "I want to..." shows hands
- BUG-037 (🟡 MAJOR): "what's around me" not understood
- BUG-038 (🟡 MAJOR): "what am I holding" not understood
- BUG-039 (🟡 MAJOR): "use X on Y" not understood
- BUG-040–047: Minor parser/UX issues (hyphen matching, typo tolerance, noun-only input, drop all, search room, climb routing, bare verb suggestions, feel-in-drawer)

**Major Wins:**
1. Sensory verbs (listen, smell, feel) are best-in-class — incredible atmospheric writing
2. GOAP still magical — "light candle" from cold start chains 5 steps flawlessly
3. Multi-word matching works for 10/12 tested objects (only hyphenated name fails)
4. "what can I do", "where am I", "what do I see" all map naturally to help/look
5. Error messages for nonexistent objects are clear and consistent
6. Candle burn timer creates real gameplay tension

**Full Report:** test-pass/gameplay/012-pass-2026-03-21.md

### Pass-009 Execution: Material Properties & Mutate Fields (2026-03-21)

**Status:** ✅ COMPLETE

| Category | Tests | Passed | Failed | Notes |
|----------|-------|--------|--------|-------|
| Material System | 8 | 6 | 2 | 2 registry mismatches |
| Mutate Fields | 10 | 9 | 1 | GOAP relight bug |
| Core Gameplay | 12 | 12 | 0 | Zero regressions |
| Timed Events | 3 | 3 | 0 | All fire correctly |
| GOAP | 4 | 3 | 1 | First light ✅; relight ❌ |
| **TOTAL** | **37** | **33** | **4** | |

**New Bugs:**
- BUG-033 (LOW): Material "oak" missing from registry (3 objects affected)
- BUG-034 (LOW): Material "velvet" missing from registry (curtains)
- BUG-035 (MEDIUM): GOAP relight picks spent match instead of fresh one

**Major Wins:**
1. `apply_mutations()` works perfectly — weight functions, keyword add/remove, category ops all verified
2. Window open/close: keywords + feel changes + categories all mutate correctly
3. Wardrobe open/close: keywords mutate correctly
4. Nightstand open drawer: keyword mutation + room description update confirmed
5. Candle burn timer fires naturally during gameplay — excellent urgency
6. Zero regressions across entire critical path

**Full Report:** test-pass/2026-03-21-pass-009.md
**Puzzle Feedback:** .squad/decisions/inbox/nelson-puzzle-feedback-pass009.md

### Pass-007 Execution: GOAP Tier 3 + UNLOCK Verb Validation (2026-03-20T21:45Z)

**Status:** ✅ COMPLETE
**Build:** 634a96e

| Category | Tests | Passed | Failed | Notes |
|----------|-------|--------|--------|-------|
| GOAP Cold Start | 11 | 4 | 3 | 4 edge cases |
| UNLOCK Verb | 7 | 7 | 0 | All clean |
| Multi-Room Nav | 10 | 10 | 0 | Perfect |
| Regression | 20 | 20 | 0 | Zero regressions |
| Edge Cases | 5 | 5 | 0 | All graceful |
| Bug Verification | 4 | 4 | 0 | All fixed |
| **TOTAL** | **57** | **50** | **3** | **4 edge cases** |

**Major Wins:**
1. **GOAP Tier 3 is TRANSFORMATIVE** — "light candle" from cold start auto-chains 5 prerequisite steps
2. **UNLOCK verb fully polished** — 3 phrasings, clean error states, dynamic descriptions
3. **4 previous bugs FIXED** (BUG-015, BUG-028, BUG-029, BUG-030)
4. **Zero regressions** across all systems

**New Minor Issues:**
- BUG-031 (MINOR): Compound "and" + GOAP mixed output
- BUG-032 (MINOR): "burn candle" doesn't trigger GOAP

**Critical Path:** feel → `light candle` (GOAP!) → push bed → pull rug → get key → open trap door → down → unlock door → open door → [Room 3 needed]
**Full Report:** test-pass/2026-03-20-pass-007.md

### Cross-Agent Updates (2026-03-20)
- **From Bart (2026-03-20T22:00Z):** 4 new objects ready for testing (candle-holder, wall-clock, enhanced candle/match) + BUG-031/BUG-032 fixes
- **From Frink:** MUD verb research — 50-100 predefined socials recommended for MVP

### GOAP Tier 3 Implementation (2026-03-20T21:15Z)
**Status:** Ready for testing. Bart delivered UNLOCK verb + auto prerequisite planning.

## Bug Track Summary (62 unique)
- CRITICAL/HIGH (11): BUG-001, BUG-004, BUG-008, BUG-017, BUG-026, BUG-030 (ALL FIXED), BUG-036 (✅ PARTIALLY FIXED), BUG-048 (✅ FIXED), BUG-055, BUG-060 (✅ FIXED — on_traverse schema), BUG-061 (OPEN — wine bottle location needs `.inside` suffix)
- MAJOR (5): BUG-037, BUG-038, BUG-039 (parser), BUG-049 (✅ FIXED), BUG-050 (✅ FIXED)
- MEDIUM (13): Most FIXED; BUG-035 (GOAP spent match), BUG-051 (courtyard moonlight), BUG-052 (sarcophagus ambiguity), BUG-056 (plural names), BUG-058 (feel inside drawer)
- LOW (5): BUG-033, BUG-034, BUG-057 (rat feel), BUG-059 (uncork/drink no hold check), BUG-062 (✅ FIXED — drink verb checks on_drink_reject)
- MINOR/COSMETIC (28): Most fixed; BUG-040–047 open, BUG-053, BUG-054

## Learnings

- GOAP is game-changing (single command replaces 7-step manual sequence)
- Systematic regression testing catches reintroductions early
- Spatial puzzles (push bed → pull rug → discover) are excellent game design
- Multi-room navigation, inventory persistence, light sources: all robust
- Container nesting handled correctly at all levels
- Wearable system is polished and extensible
- Critical path now proven end-to-end (darkness → light → spatial → multi-room → unlock)
- Content (Room 3) is the next blocker, not engine mechanics
- Material registry works for gameplay display but has data gaps (oak/velvet missing from registry, 20 objects lack material field)
- `apply_mutations()` handles all three types (direct, function, list ops) correctly — tested across candle, match, window, wardrobe, nightstand
- GOAP spent match selection is a real usability problem — first light is magic, relight is broken
- Spent matches accumulate inside matchbox after GOAP chains — root cause of relight failures
- Candle burn timer fires correctly over gameplay time, creating real urgency
- Match burn timer fires same-turn (by design) — you can't hold a lit match between commands
- Level 1 rooms all load, connect, and render correctly — writing is best-in-class
- Container `.inside` surfaces need explicit exposure when container is opened/broken (BUG-048)
- Rooms with multiple instances of same type_id need display deduplication (hallway, crypt worst)
- Room `light_level` field is unused by engine — only `casts_light` on objects counts
- The hallway warmth-after-darkness reveal is the emotional highlight of Level 1
- Carried candle provides portable light across room transitions — works perfectly
- Two-hand inventory creates meaningful resource tension (light vs tools vs keys)
- BUG-048 FIXED: Crate `.inside` surface now exposes iron key after prying open — `look inside crate`, `feel inside crate`, `get iron key` all work
- BUG-050 FIXED: Hallway torches/portraits/side table display once each — no duplicate instance descriptions
- GOAP auto-resolves crowbar from room when player types `open crate` without holding it — excellent UX
- North exit from bedroom to hallway is UNLOCKED — entire cellar puzzle chain is bypassable (design question raised)
- `feel inside drawer` still fails even though `feel inside crate` works — `.inside` surface inconsistency on drawer
- Full Level 1 critical path verified end-to-end: bedroom → cellar → storage-cellar → deep-cellar → hallway
- Candle burn timer is tight but fair — expires around storage cellar, player finishes deep cellar in dark
- BUG-055: Match FSM says "You drop the blackened stub" but spent match stays in player's hand — blocks picking up candle/other items. HIGH impact.
- BUG-056: Plural object names ("torches", "portraits") not matched by parser — room descriptions use plurals but examine only works with singular
- BUG-057: Rat on_feel returns "A heavy piece of furniture" — template/base class fallback issue
- BUG-058: `feel inside drawer` still broken — `.inside` surface not exposed for feel verb. Crate works, drawer doesn't.
- BUG-059: uncork/drink work on objects not in hand — design decision needed on whether surface interactions require holding
- BUG-049 FIXED: `pry crate` now works — pry verb recognized by parser
- BUG-036 PARTIALLY FIXED: "I want to..." prefix handled correctly by NL parser. Only bare "I" triggers inventory (intended).
- Moe's bedroom north door fix VERIFIED: heavy oak door is locked, cellar route is now the only path
- Compound commands ("open drawer and get matchbox") work cleanly — split on "and" with GOAP integration
- Death system works: drinking poison bottle produces "YOU HAVE DIED" game over
- Sleep/rest/nap all advance time by 1 hour — time system fully functional
- All 7 Level 1 rooms visited and tested: bedroom, cellar, storage-cellar, deep-cellar, hallway, courtyard, crypt
- Crypt writing is extraordinary — silence description is best-in-class atmospheric text
- Courtyard smell/listen are world-class — wind, owl, rain, empty manor watching
- Multi-command input (Issue #1) works perfectly: comma, semicolon, "then" separators all split correctly. Empty segments ignored. 6-command chains execute flawlessly.
- `--no-ui` flag is essential for reliable automated testing — TUI mode blanks output on complex sequences
- Visited room tracking is elegant: short_description on revisit, full description on explicit `look`, bold `**Title**` markers throughout
- `report bug` command generates context-aware GitHub issue URL with room name and timestamp — production quality
- BUG-060 (CRITICAL): `on_traverse` wind effect never fires — schema mismatch between engine (expects `{type: "wind_effect"}`) and room data (provides `{wind_effect: {...}}`). Both directions broken.
- BUG-061 (HIGH): Wine bottles not instantiated in wine rack — instance ID mismatch (`wine-bottle` vs `wine-bottle-1/2/3`). Puzzle 016 completely untestable.
- BUG-062 (LOW): Drink verb uses generic rejection instead of object's `on_drink_reject` custom text
- Schema mismatches between engine and data are a recurring category — the code patterns are solid but the contracts between layers aren't enforced
- Multi-command makes speed-running the critical path trivial: `light candle` → 6-command chain → 3-command chain → at deep cellar in 3 inputs
- Bug count: 62 unique bugs discovered total (BUG-001 through BUG-062)
- BUG-060 VERIFIED FIXED: `normalize_effect()` handles both `{type: "wind_effect"}` and `{wind_effect: {...}}` nested formats. Wind effect fires correctly on deep-cellar→hallway traversal. Candle FSM transitions lit→extinguished cleanly.
- BUG-062 VERIFIED FIXED: Drink handler fallback checks `on_drink_reject` field before generic refusal. Oil flask prints vivid custom rejection text.
- BUG-061 STILL OPEN: Wine bottle ID was fixed but instance `location` field was not updated. Engine requires explicit `.inside` surface suffix (`location = "wine-rack.inside"`), not bare container name (`location = "wine-rack"`). Same pattern as iron-key using `large-crate.inside`. One-line data fix needed in storage-cellar.lua line 28.
- Container surface placement is a recurring gotcha: the engine's `loc:match("^(.-)%.(.+)$")` regex requires the dot-suffix. Bare container names fall through to root-level contents which are invisible to `look inside` / `take from`.
- Oil lantern fueling is BLOCKED by parser: "pour oil flask into lantern", "fill lantern", "fuel lantern with oil flask" all fail. The FSM transition requires `lamp-oil` tool but parser can't resolve two-object pour/fill interactions. Likely same class as BUG-039 ("use X on Y" not understood).
- Wind effect atmospheric writing is excellent — the stairway gust description is a standout moment
- Extinguished candle description ("wick is black and still warm, trailing a thin wisp of smoke") is first-rate detail
- **Inventory unit test suite created** (60 tests): Covers take, drop, put, inventory, containment, registry, find_visible, surfaces, containers, two-handed objects, round-trips, edge cases. All 114 tests pass (60 new + 54 existing).
- Self-containment guard (BUG-036b) uses object identity (`==`), not ID comparison — two different tables with same `.id` won't be caught. This is by-design since objects are always looked up from registry, but worth knowing for refactoring.
- `put` verb requires item to be in player's **hands** specifically (not bag/worn) — if you want to move something from a bag to a container, you must first `take` it from the bag.
- `drop` only works on items directly in hands — items in bags get a helpful "get it out of the bag first" message rather than auto-extracting.
- Test runner updated to discover tests from multiple subdirectories (parser + inventory), not just parser.
## Learnings

### Pass 019: BUG-063 Fix Verification (2026-03-21)

**Status:** PARTIAL — Found critical blocker

**BUG-063 FIXED:**
- GUID normalization now works correctly
- \eel around\ properly discovers nightstand in the bedroom
- Critical path Step 1 (discover nightstand) works as intended
- The fix is solid and complete

**NEW BUG-064 DISCOVERED (CRITICAL):**
- **Severity**: CRITICAL — Blocks critical path progression
- **Commands**: \search drawer\, \xamine drawer\, \eel drawer\
- **Problem**: Container search only describes surface, doesn't reveal contents
- **Expected**: Should list "a small matchbox" inside drawer
- **Actual**: Only tactile description of drawer wood/handle
- **Impact**: Real players cannot discover matchbox without meta-knowledge
- **Workaround**: Direct \get matchbox\ still works (object exists, just hidden)

**What Passed:**
- ✅ Nightstand appears in \eel around\ output (BUG-063)
- ✅ \open nightstand\ works
- ✅ \get matchbox\ (direct) works
- ✅ \open matchbox\ reveals matches
- ✅ \get match\ decrements match count (7→6)
- ✅ \light match\ works with beautiful atmospheric prose
- ✅ Match burns out over time with vivid description

**Quality Notes:**
- Match lighting prose is excellent: "sputters once, twice -- then catches with a sharp hiss and a curl of sulphur smoke"
- Match burnout: "The match flame reaches your fingers and dies. You drop the blackened stub."
- Writing quality remains consistently high

**Pattern Observed:**
- Container search is a separate issue from container opening
- Opening works (drawer opens)
- Search/examine/feel don't enumerate contents
- This is distinct from the surface placement issue (BUG-061) which was about .inside suffix
- Likely issue with dark-mode container inspection logic

**Recommendation:**
BUG-064 must be fixed before Pass 020. This is a showstopper. The critical path is:
1. feel around → discover nightstand ✅
2. open nightstand → drawer opens ✅
3. search/examine drawer → discover matchbox 🔴 BROKEN
4. get matchbox, light match, etc.

Without step 3, no player will progress.

**Tests Not Completed (due to BUG-064):**
- Injury system (stabbing, targeting, damage)
- Bandage system
- Poison system
- Puzzle 015/016 retests
- Parser variations
- Edge cases

