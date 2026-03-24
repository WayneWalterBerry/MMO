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

### Documentation Requirements
- Test results go in `test-pass/` using Nelson's established format (tables with ✅/❌/⚠️, structured bug reports)
- Object test inventories reference `src/meta/objects/*.lua` by filename
- Bug reports: Severity/Input/Expected/Actual/Notes format (established by Nelson pass-001 onward)

### Testing Philosophy (Principle 8)
"Testing is data-driven — verify transitions produce correct state, not that engine 'understands' objects"
- Test WHAT objects do, not HOW the engine does it
- Derive tests from .lua metadata: states, transitions, mutate fields, sensory properties
- Every object gets independently verified before it's considered done
- The engine is a generic FSM executor with zero object-specific logic — tests validate metadata correctness
- `apply_mutations()` in `src/engine/fsm/init.lua` supports: direct values, functions (computed), list ops (add/remove)
- `apply_state()` removes old state keys, applies new state properties, preserves containment

### Architecture Foundation
- 8 Core Principles govern all objects (`docs/architecture/objects/core-principles.md`)
- Base objects (immutable .lua templates) → Object instances (mutable runtime tables)
- Generic `mutate` field on FSM transitions can change ANY property (weight, size, keywords, categories, portable)
- GOAP backward-chaining parser resolves prerequisite chains (max depth 5)
- All mutation is in-memory; .lua files never change at runtime
- Dwarf Fortress property-bag architecture is the reference model (D-DF-ARCHITECTURE)
- Containment: 5-layer validation (container identity → size → capacity → category → weight)
- Surfaces model: objects can have multiple containment zones (top, inside, underneath)
- Instance model: type_id (GUID) references base class; overrides for instance-specific values

---

## Testing Methodology (from research)

### FSM Testing: Coverage Strategies

**1. State Coverage (visit every state)**
- For each FSM object, enumerate ALL states from the `states` table
- Create at least one test that enters each state
- Verify state-specific properties are correctly applied (name, description, sensory fields, capabilities)
- Example: candle has 4 states (unlit, lit, extinguished, spent) — need tests entering each

**2. Transition Coverage (exercise every transition)**
- For each transition in the `transitions` array, create a test that fires it
- Verify: from-state correct, to-state reached, message displayed, mutate fields applied
- Include BOTH verb-driven and auto (timer_expired) transitions
- 0-switch coverage: each transition once; 1-switch coverage: pairs of transitions (e.g., light→extinguish→relight)

**3. Path Coverage (exercise state sequences)**
- Test critical multi-step paths: unlit→lit→extinguished→lit→spent
- Round-trip paths: closed→open→closed (wardrobe, window, curtains, vanity)
- Dead-end paths: any path leading to terminal states (spent candle, empty bottle)
- Complete path coverage is infeasible for wall-clock (24 cyclic states) — test key paths only

**4. Boundary Testing for Guards**
- `requires_property` guards: test with property present AND absent
  - Match: requires `has_striker` on context.target — test with matchbox (has it) and without
- `requires_tool` guards: test with tool in inventory AND without
  - Candle light: requires `fire_source` — test with lit match and without
- Custom `guard` functions: test true and false conditions
- Terminal state guards: verify no transitions fire from terminal states (spent match, empty bottle)

**5. Invalid/Negative Testing**
- Attempt transitions that don't exist (e.g., "light" on an already-lit candle)
- Attempt transitions from wrong state (e.g., "extinguish" on unlit candle)
- Verify engine returns correct error codes: "not_fsm", "terminal", "no_transition", "requires_property", "guard_failed"

### Data-Driven Testing Strategies

**1. Property-Based Testing (QuickCheck-style)**
- Define invariants that must hold for ALL objects regardless of state:
  - "Every FSM object must have a `_state` field matching one of its `states` keys"
  - "Every transition's `from` and `to` must reference valid state names"
  - "Terminal states must have no outgoing transitions"
  - "Every state must define `description` and `name`"
  - "Weight must be > 0 for all portable objects"
- Auto-generate test cases by iterating all .lua files and checking invariants

**2. Metamorphic Testing (if input changes, how should output change?)**
- Metamorphic relations for our system:
  - "If a candle transitions lit→extinguished, weight should decrease (mutate function applies)"
  - "If a container is opened, its inside surface should become accessible"
  - "If an object transitions to a terminal state, no further verb-driven transitions should be possible"
  - "If a mutate adds a keyword, that keyword should appear in obj.keywords"
  - "If a mutate removes a category, that category should not appear in obj.categories"

**3. Oracle Strategy (how to know the "right answer")**
- The .lua metadata IS the oracle — it declares expected behavior
- For each transition: read `to` state → look up that state's properties → those ARE the expected values
- For each mutate: read mutate table → compute expected property values → compare to actual
- Schema validation: every object must conform to its template's structure

**4. Deriving Test Cases Automatically from .lua Metadata**
- Parse each object's `states` table → enumerate all states
- Parse each object's `transitions` array → enumerate all transitions
- For each transition with `mutate`: generate before/after property assertion
- For each state: verify all sensory fields match metadata (on_feel, on_smell, on_listen, on_taste)
- For each container state: verify surface accessibility matches state definition

### How to Test Mutate Fields

**Before/After Property Verification Pattern:**
1. Record object properties BEFORE transition
2. Fire the transition
3. Read `mutate` table from the transition definition
4. For each mutate entry:
   - Direct value: assert `obj[key] == expected_value`
   - Function: compute `expected = mutate_fn(before_value)`, assert `obj[key] == expected`
   - List add: assert keyword/category IS in the list
   - List remove: assert keyword/category is NOT in the list
5. Verify non-mutated properties are unchanged

**Three mutate forms to test:**
- `weight = 0.05` → direct assignment
- `weight = function(w) return math.max(w * 0.7, 0.1) end` → computed
- `keywords = { add = "half-burned" }` / `categories = { remove = "light source" }` → list ops

### Game Industry Testing Patterns (from AAA research)

- **State machine automation**: Script simulations of all possible state paths through CI/CD
- **Regression suites**: Re-run all tests after every balance change or new content
- **AI-driven simulation**: Simulate thousands of gameplay hours to detect breakpoints
- **Manual + automated hybrid**: Automation catches state logic bugs; humans catch "feel" issues
- **Incremental testing**: Test after each change (Dwarf Fortress modder pattern)

### Dwarf Fortress Lessons

- DF has NO automated test suite for raw files — all testing is manual + community-driven
- Modders verify by: launching game, observing behavior, checking if objects appear correctly
- Third-party static analysis tools check raw file syntax but not semantic correctness
- DFHack Lua scripts can automate some checks — analogous to what we could build
- **Key takeaway**: We can do BETTER than DF by leveraging our .lua metadata as machine-readable test oracles

---

## Object Inventory (what to test)

### FSM Objects (15 total — HIGHEST PRIORITY)

| Object | States | Transitions | Mutate Opps | Sensory | Priority |
|--------|--------|-------------|-------------|---------|----------|
| **candle** | 4 (unlit/lit/extinguished/spent) | 4 (light/extinguish/relight/auto-spent) | weight↓, size↓, keywords+nub, categories−light source | feel/smell/listen | 🔴 CRITICAL |
| **match** | 3 (unlit/lit/spent) | 3 (strike/extinguish/auto-spent) | weight↓, keywords+burning/blackened, categories+useless | feel/smell/listen | 🔴 CRITICAL |
| **poison-bottle** | 3 (sealed/open/empty) | 4 (uncork/detach-cork/drink/pour) | weight↓, keywords+uncorked/empty, categories−dangerous | feel/smell/listen/taste | 🔴 CRITICAL |
| **window** | 2 (closed/open) | 2 (open/close) | keywords±open, categories±ventilation | feel/listen/smell(open) | 🔴 HIGH |
| **nightstand** | 4 (closed/open × with/without drawer) | 5 (open/close/detach/reattach×2) | weight±2 (drawer mass) | feel/smell | 🔴 HIGH |
| **vanity** | 4 (closed/open × intact/broken) | 6 (open/close×2/break×2) | keywords+broken/open, weight 40→38 | feel/smell | 🔴 HIGH |
| **wall-clock** | 24 (hour_1..hour_24 cyclic) | 24 auto-transitions | none (deferred) | feel/smell/listen | 🟡 MEDIUM |
| **wardrobe** | 2 (closed/open) | 2 (open/close) | keywords±open | feel/smell | 🟡 MEDIUM |
| **curtains** | 2 (closed/open) | 2 (open/close) | keywords±open | feel/smell | 🟡 MEDIUM |
| **trap-door** | 3 (hidden/revealed/open) | 2 (reveal/open) | keywords+open | smell | 🟡 MEDIUM |
| **candle-holder** | 2 (with_candle/empty) | 2 (detach/reattach) | weight±1 (candle mass) | feel/smell | 🟡 MEDIUM |
| **bed** | non-FSM but movable | spatial push | — | feel/smell | 🟢 LOW |
| **rug** | non-FSM but movable | spatial move, reveals trap-door | — | feel | 🟢 LOW |
| **matchbox/matchbox-open** | old mutations (becomes) | open/close swap | — | feel/smell/listen | 🟢 LOW |

### Non-FSM Objects (22 total — lower priority, test sensory + mutations)

**Wearables (test slot assignment, vision blocking):** sack, wool-cloak, terrible-jacket, chamber-pot
**Crafting chain (test mutation spawns):** cloth→bandage/rag, cloth+cloth→terrible-jacket, blanket→cloth+cloth+rag, curtains→cloth+cloth+rag, sack→cloth×3, wool-cloak→cloth×2
**Tool providers (test provides_tool resolution):** knife (cutting_edge/injury_source), needle (sewing_tool), pen/pencil (writing_instrument), thread (sewing_material), pin (injury_source + conditional lockpick)
**Skill system (test skill granting):** sewing-manual (grants sewing), pin (lockpicking-gated lockpick)
**Containers (test containment):** barrel, matchbox/matchbox-open, pillow (hidden pin inside), sack
**Static objects (minimal testing needed):** bandage, bed-sheets, blanket, brass-key, glass-shard, paper, rag, torch-bracket

### GOAP Prerequisite Chains to Test

| Goal | Chain | Objects Involved |
|------|-------|-----------------|
| "light candle" (cold start) | take matchbox → open matchbox → take match → strike match (on matchbox) → light candle | matchbox, match, candle |
| "light candle" (match in hand, no striker) | fail: requires has_striker | match, candle |
| "read sewing manual" | take manual → read manual → skill "sewing" granted | sewing-manual |
| "sew cloth" | need: needle + thread + cloth + sewing skill | needle, thread, cloth, sewing-manual |
| "unlock iron door" | take brass-key → go to cellar → unlock door with key | brass-key, trap-door |

---

## Test Case Templates

### Template 1: FSM Transition Test

```
## TEST: [Object] — [From State] → [To State] via [Verb]

**Object:** [object-id] (`src/meta/objects/[file].lua`)
**Precondition:** Object is in `[from-state]` state
**Action:** Player executes `[verb] [object]`
**Guard:** [requires_property/requires_tool/guard function, or "none"]

### Assertions:
| Property | Before | Expected After | Actual | Status |
|----------|--------|----------------|--------|--------|
| _state | [from] | [to] | | |
| name | [old name] | [new name] | | |
| description | [old desc] | [new desc] | | |
| on_feel | [old] | [new] | | |
| on_smell | [old] | [new] | | |
| message displayed | — | [transition.message] | | |

### Guard Tests:
| Condition | Expected Result | Actual | Status |
|-----------|----------------|--------|--------|
| Guard satisfied | Transition succeeds | | |
| Guard NOT satisfied | Transition fails, fail_message shown | | |

**Result:** ✅ PASS / ❌ FAIL — [notes]
```

### Template 2: Mutate Field Test

```
## TEST: [Object] — Mutate on [From] → [To]

**Transition:** [from] → [to] via [verb/auto]
**Mutate definition:** [paste mutate table from .lua]

### Property Mutations:
| Property | Type | Before | Expected After | Actual | Status |
|----------|------|--------|----------------|--------|--------|
| weight | direct/function | [val] | [val] | | |
| keywords | add "[kw]" | [list] | [list + kw] | | |
| categories | remove "[cat]" | [list] | [list - cat] | | |

### Persistence Check:
| Non-mutated Property | Before | After (should be unchanged) | Status |
|---------------------|--------|---------------------------|--------|
| size | [val] | [val] | |
| portable | [val] | [val] | |

**Result:** ✅ PASS / ❌ FAIL — [notes]
```

### Template 3: Sensory Property Test

```
## TEST: [Object] — Sensory in [State]

**Object:** [object-id] in state `[state]`
**Light conditions:** [lit/dark/daylight]

### Sensory Outputs:
| Sense | Command | Expected Output | Actual | Status |
|-------|---------|----------------|--------|--------|
| Sight | examine [obj] | [description from state] | | |
| Touch | feel [obj] | [on_feel from state] | | |
| Smell | smell [obj] | [on_smell from state] | | |
| Sound | listen [obj] | [on_listen from state, or nil] | | |
| Taste | taste [obj] | [on_taste from state, or nil] | | |
| Presence | look (room) | [room_presence from state] | | |

### Dark Conditions (if applicable):
| Sense | Expected in Dark | Status |
|-------|-----------------|--------|
| Sight | "It is too dark to see" | |
| Touch | [on_feel still works] | |
| Smell | [on_smell still works] | |

**Result:** ✅ PASS / ❌ FAIL — [notes]
```

### Template 4: GOAP Chain Test

```
## TEST: GOAP Chain — [Goal Description]

**Starting conditions:** [what player has, room state, light conditions]
**Command:** `[player input]`
**Expected chain length:** [N steps]

### Prerequisite Steps (auto-executed by GOAP):
| Step | Action | Object | Expected Result | Status |
|------|--------|--------|----------------|--------|
| 1 | [verb] | [obj] | [result] | |
| 2 | [verb] | [obj] | [result] | |
| ... | | | | |

### Final State:
| Check | Expected | Actual | Status |
|-------|----------|--------|--------|
| Goal object state | [state] | | |
| Consumed objects | [list] | | |
| Player inventory | [state] | | |

**Result:** ✅ PASS / ❌ FAIL — [notes]
```

---

## Previous Bug Patterns (from Nelson's 8 test passes, 34 bugs)

### Bug Categories & Frequency

| Category | Bugs | Pattern |
|----------|------|---------|
| Parser/Noun Resolution | BUG-003,005,014,028 | Fuzzy matching too aggressive or too lenient; synonyms not recognized; adjectives required when should be optional |
| FSM State Leakage | BUG-019,027 | Internal state labels like "(drawer open)" or "(open)" leak into player-visible object names |
| Internal ID Leakage | BUG-010,015 | Display names not used; players see "candle" and "poison-bottle" instead of proper names |

---

## Learnings

### 2026-03-21: Object Update Test Pass

**What I tested:** All 10 FSM objects updated by Flanders (mutate fields + material properties) and Bart (material registry + threshold checking). Ran `lua src/main.lua --no-ui` and exercised transitions, sensory properties, mutate fields, and material verification.

**Bugs found (5):**
- BUG-101: "relight" verb alias not recognized — GOAP wastes a match, then parser fails. Use "light" instead.
- BUG-102: "pour bottle" fires the drink transition message instead of pour. Verb-to-transition matching may be first-match or synonym collision.
- BUG-103: material "oak" not in registry — affects wardrobe, nightstand, vanity. Either add "oak" or change objects to "wood".
- BUG-104: candle-holder.lua and trap-door.lua missing `material` field entirely.
- BUG-105: material "velvet" not in registry — affects curtains. Either add "velvet" or change to "fabric".

**Key patterns learned:**
- Verb alias bugs are a recurring theme (Nelson's BUG-003, BUG-005 were similar parser issues). Aliases defined in transition metadata don't always resolve through the parser/embedding layer.
- GOAP chain behavior is impressive — it auto-strikes matches before lighting candles — but when the final verb fails, the prerequisite action (match strike) is wasted and irreversible. GOAP needs a way to validate the final verb before executing prerequisites.
- Material registry has 13 entries but objects use material names that don't match (oak vs wood, velvet vs fabric). Need a naming convention decision: specific materials (oak, velvet, pine) or generic categories (wood, fabric).
- Mutate field values (weight changes, keyword adds/removes) are not directly observable in the REPL — need a debug/inspect command to verify runtime property values. Testing currently relies on inference from sensory output changes.
- Match burn_duration of 30 seconds resolves to 0 game ticks in practice — the match auto-expires on the same turn it's struck. This prevents testing the "blow match" verb manually.
- The `feel` command appears to bypass surface accessibility flags (wardrobe shows inside contents even when closed). May be intentional per D-37 (sensory verbs work in darkness) but could be a containment bug.
| Missing Features | BUG-004,026 | Movement verbs, unlock verb — critical path blockers |
| Container/Inventory | BUG-012,017 | "take match" resolves wrong instance; drawer replacement destroys surface objects |
| Game Mechanics | BUG-008,024 | Poison doesn't kill; sack equips to wrong slot |
| Text/Display | BUG-001,020,023 | Text wrapping, capitalization, Unicode encoding |
| Verb Parsing Edge Cases | BUG-034 | "put out" treated as PUT instead of phrasal extinguish |

### 2026-03-25: meta-check Tool Validation (P0-B Step 2)

**What I tested:** Smithers' `scripts/meta-check/check.py` v1.0 against all 103 meta files (83 objects, 7 rooms, 13 others). Validated against my 144 acceptance criteria in `docs/meta-check/acceptance-criteria.md`.

**Results:**
- 0 errors on valid production files (no false positives)
- 137 warnings (136 keyword overlap XF-03 + 1 missing description S-11)
- 3 false-negative tests all caught correctly (missing on_feel, bad GUID, bad FSM refs)
- JSON output valid and parseable
- 19 of 144 checks implemented (13% coverage)

**Key findings:**
- The tool is solid for what it covers — zero false positives, zero crashes on all 103 files
- 4 severity discrepancies vs. spec (S-11 and MAT-01 too lenient, XF-03 and S-09 too strict)
- Empty string values not treated as missing (SN-03 gap)
- 125 checks still missing — biggest gaps: template-specific validation, room exit/instance checks, mutation validation, composite parts, effects pipeline, level definitions, lint rules

**Verdict:** PASS WITH NOTES. Strong V1 foundation. Report at `test-pass/2026-03-25-meta-check-validation.md`.

### Objects Most Likely to Break

1. **Nightstand** (5 bugs) — composite detach/reattach + surfaces + state leakage
2. **Matchbox** (3 bugs) — multi-instance disambiguation + container tracking
3. **Candle** (3 bugs) — timer + relight cycles + GOAP chain terminus
4. **Wardrobe** (2 bugs) — internal ID display + parser collision
5. **Trap door** (2 bugs) — hidden→revealed state + examineability

### Where Objects Are Most Likely to Break

- **Composite part operations** (detach/reattach): highest-risk — BUG-017 was CRITICAL (drawer replace destroyed objects)
- **Multi-instance containers**: disambiguation when taking items from matchbox with spent matches elsewhere
- **State-to-display mapping**: FSM state names leaking into player text
- **GOAP terminus objects**: objects at the end of prerequisite chains (candle, iron door) where chain failures cascade
- **Timer-based transitions**: candle burn, match burn — timing edge cases during sleep

### Nelson's Testing Evolution (Pass 001→008)
- Started exploratory (pass 001), evolved to systematic regression (pass 004+)
- By pass 007: exhaustive variant testing (11 GOAP phrase variants)
- Each pass re-verifies ALL previous bugs — regression discipline
- Total: 34 bugs found, most fixed between passes, 2 remaining (BUG-033, BUG-034)

---

## Learnings

### Key File Paths
- **Object definitions:** `src/meta/objects/*.lua` (37 files)
- **FSM engine:** `src/engine/fsm/init.lua` (apply_state, apply_mutations, transition, tick, tick_timers)
- **Verb handlers:** `src/engine/verbs/init.lua` (keyword matching, hand inventory, all verb logic)
- **Game loop:** `src/engine/loop/init.lua` (REPL, NLP preprocessing, GOAP integration, FSM tick phase)
- **Core principles:** `docs/architecture/objects/core-principles.md`
- **Instance model:** `docs/architecture/objects/instance-model.md`
- **Containment:** `docs/architecture/engine/containment-constraints.md`
- **Mutation research:** `resources/research/architecture/dynamic-object-mutation.md`
- **Mutate audit:** `.squad/decisions/inbox/cbg-object-mutate-audit.md`
- **Test passes:** `test-pass/` (8 files, pass-001 through pass-008)
- **Run command:** `lua src/main.lua` (with UI) or `lua src/main.lua --no-ui` (plain text)

### Engine Contract (what Lisa tests against)
1. Engine loads .lua metadata as tables
2. `fsm.transition()` fires transitions: checks state, finds matching transition, checks guards, calls apply_state + apply_mutations + on_transition
3. `fsm.tick()` processes on_tick callbacks for auto-transitions
4. `fsm.tick_timers()` decrements timers, fires auto-transitions on expiry
5. Engine NEVER contains object-specific logic — no `if obj.id == "candle"` anywhere
6. Containment validated by 5-layer system before any move

### Wayne's Preferences
- Dwarf Fortress-inspired property-bag architecture
- Zero engine changes for new objects — all behavior in metadata
- Deterministic: same actions + same world state = same results
- Testing validates metadata correctness, not engine implementation
- LLMs used upstream (authoring) not downstream (runtime) — Decision 19
- Objects must be perceivable through ALL senses in every state
- GOAP chains must be testable end-to-end

### Testing Tools Available
- Lua runtime (`lua` command) for direct execution
- No existing automated test framework — tests are currently manual (Nelson's pass format)
- Could build automated tests by loading .lua files and programmatically checking properties
- `src/engine/fsm/init.lua` functions are unit-testable: `fsm.load()`, `fsm.transition()`, `fsm.tick()`, `fsm.get_transitions()`

### Critical Insight for Object Testing
The .lua metadata files ARE the test oracle. Every assertion can be derived by:
1. Reading the object's `states` table for expected state properties
2. Reading the object's `transitions` array for expected transitions
3. Reading each transition's `mutate` table for expected property changes
4. Reading each state's sensory fields for expected perception outputs
5. Comparing actual runtime behavior against these declared expectations

This is the core advantage over Dwarf Fortress: our metadata is structured, machine-readable Lua — we can auto-generate test cases from it.

### meta-check Acceptance Criteria (2026-03-24)
- Authored `docs/meta-check/acceptance-criteria.md` — 144 checks across 15 categories
- Examined all 5 templates, 83 objects, 7 rooms, 1 level, 23 materials to derive rules
- Key insight: GUID format inconsistency (some braced, some bare) across rooms vs objects — flagged as WARNING
- Key insight: rooms often lack sensory properties (on_feel, on_smell, on_listen) that are critical for darkness navigation — flagged as WARNING
- Some room exit targets reference future rooms (level-2, manor-west, manor-east) — these need WARNING not ERROR to avoid blocking
- Composite parts (nightstand drawer, poison cork) need their own validation pass — factory functions must produce objects with on_feel
- Cross-file checks (GUID uniqueness, type_id resolution, bidirectional exits) are the most complex to implement but catch the most dangerous bugs
- The .lua metadata IS the oracle — meta-check codifies what I've been verifying manually into machine-checkable rules

---

## Archives

- `history-archive-2026-03-20T22-40Z-lisa.md` — Full archive (2026-03-18 to 2026-03-20T22:40Z): onboarding, object testing methodology, FSM coverage strategies, testing framework design
