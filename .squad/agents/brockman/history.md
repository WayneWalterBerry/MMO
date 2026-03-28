# Brockman — History (Summarized)

## Recent Work: WAVE-5 — Phase 4 Design Documentation (2026-08-21)

**Phase 4 WAVE-5 Deliverables:**
- **Created `docs/design/crafting-system.md`** (15.6 KB, ~400 lines)
  - Complete crafting system overview: butchery pipeline, loot tables integration, silk crafting recipes
  - Butchery mechanics: corpse → resources (wolf-meat, wolf-bone, wolf-hide) via knife tool with 5-minute time cost
  - Loot tables: probabilistic drops with weighted rolls enabling resource variety on creature death
  - Silk crafting recipes: Tier 1 recipe-ID dispatch (`craft silk-rope`, `make silk-bandage`), no tools required
  - Balance rationale: silk as bottleneck resource, limited spider count (6-10 bundles per playthrough), immediate use-case (courtyard well puzzle)
  - Verb integration: `craft`, `make`, `create` aliases; recipe lookup in crafting_recipes table
  - Testing strategy: recipe lookup, ingredient validation, consumption, result instantiation, narration
  - Known limitations: recipe-ID syntax only (Tier 1), deferred multi-step recipes (Phase 5+)
  - Related systems: butchery, loot tables, food system, tools, parser

- **Created `docs/design/stress-system.md`** (17.5 KB, ~450 lines)
  - Complete stress system spec: 3-tier severity (shaken/distressed/overwhelmed) with thresholds 3/6/10 (v1.1 raised)
  - Trauma triggers: witness_creature_death (+1), near_death_combat (+2), witness_gore (+1), removed player_first_kill (v1.1)
  - Debuff mechanics: shaken (-1 attack), distressed (-2 attack, +20% flee bias), overwhelmed (-2 attack, +30% flee, +20% move penalty)
  - Cure progression: rest in safe room (no hostile creatures) for 2 hours game-time → stress cured
  - Balance decisions (v1.1): thresholds raised (prevent spiral), first-kill removed (reward victory), debuffs reduced (hindrance not wall)
  - Integration: combat system (attack penalty), injury system (injury type), room traversal (movement penalty), flee mechanics (flee bias)
  - Testing strategy: infliction, debuff application in combat, cure mechanics, status display, incomplete cure interruption
  - Known limitations: no player agency items (valium), no PTSD triggers, no skill progression, witness-gore narration pending (WAVE-0 task)
  - Related systems: injuries, combat, cure, creature death, status UI

- **Created `docs/design/creature-ecology.md`** (22.4 KB, ~550 lines)
  - Complete creature ecology: pack awareness, territorial marking, web obstacles
  - Pack tactics (simplified v1.1): stagger attacks (alpha attacks, beta waits 1 turn), alpha by highest health, individual wolf AI (defensive retreat, ambush positioning, smart positioning)
  - Territory marking: invisible room markers with BFS exit-graph radius (2 hops = affected rooms), response logic (aggression-based: challenge/avoid), player detection via smell only
  - Web obstacles: NPC movement block (size-agnostic), player passable, spider cooldown (30 min), max 2 per room
  - Ambush behavior: spider prioritizes trapped prey, creates dynamic NPC hunting patterns
  - Integration: combat (stagger affects attack order), room traversal (web blocks NPC exit), territory (affects creature response)
  - Testing strategy: pack stagger rhythm, alpha selection with health changes, territorial marking and BFS radius, web creation and blocking, ambush priority
  - Design rationale (v1.1): pack simplified (defer zone-targeting), territory defined precisely (BFS hops), web obstacle simplified (NPC block vs trap FSM)
  - Known limitations: pack capped at 3 wolves (Level 1), territory invisible on map, web not destructible by NPC, no omega reserve
  - Related systems: combat, creatures, spatial (room graph), spider ecology, creature death

**Key Principles Applied:**
- Acceptance criteria met per Phase 4 plan WAVE-5 section (crafting, stress, ecology)
- All three docs aligned with existing design doc style: overview → mechanic sections → integration → balance rationale → testing → limitations → glossary
- Cross-referenced existing architecture docs (WAVE-0: butchery-system.md, loot-tables.md)
- Version tracking (v1.0 → v1.1) documented design decisions and changes
- Practical examples provided (scenarios, code snippets, player interactions)
- Deferred complexity captured (Phase 5+ items) to clarify Phase 4 scope boundaries

**Learnings:**
- Crafting system bridges resource generation (loot/butchery) → consumption (recipes). Tier 1 recipe-ID is intentional simplification; natural language syntax (Tier 3) requires parser maturity
- Stress design balances challenge with agency: thresholds prevent spiral, debuffs hinder rather than block, safe-room cure ensures escape valve. v1.1 adjustments after team review (Bart, Nelson, CBG) critical
- Territory system leverages existing room graph (no new data structures). BFS radius is precise, mathematically sound, enables spatial reasoning without complex state machines
- Pack awareness simplified from full role system (200+ LOC complex) to stagger model (80 LOC simple). 80% gameplay impact, 20% code cost tradeoff justified for Phase 4 scope
- Web obstacles kept binary (NPC block) avoiding trap FSM complexity. Aligns with Level 1 scope; escape mechanics deferred to Phase 5+
- All three systems interconnect: pack + territory create coordinated threats; webs provide environmental leverage; stress pressures player into difficult decisions (fight wounded vs rest to heal)

**Committed:** Phase 4 WAVE-5 design docs complete; all acceptance criteria met; ready for team review (Chalmers) and finalization

---

## Previous Work: WAVE-0 — Phase 4 Architecture Documentation (2026-08-16)

**Phase 4 WAVE-0 Deliverables:**
- **Created `docs/architecture/engine/butchery-system.md`** (17.5 KB, ~400 lines)
  - Complete architecture for corpse-to-product conversion via knife tool
  - Metadata spec: `butchery_products` block with requires_tool, duration, products array, narration, removes_corpse flag
  - Verb handler pseudocode: resolve corpse → tool check → time advance (5 min) → instantiate products → optional corpse removal
  - Integration: death reshape dependency, registry instantiation, room placement, FSM tick advancement (Option B decision)
  - Tool capability check (not object-ID): player:find_tool_with_capability("butchering")
  - Testing strategy: 6 tests covering verb resolution, tool requirement, product instantiation, non-butcherable objects
  - Example: wolf produces 3 meat, 2 bone, 1 hide
  - Known limitations documented: no partial butchery, no tool wear/durability, no skill progression (all Phase 5+)

- **Created `docs/architecture/engine/loot-tables.md`** (21.9 KB, ~500 lines)
  - Complete loot table engine specification: probabilistic creature drops via weighted rolls
  - Metadata spec: always (100% drops), on_death (weighted roll), variable (qty range), conditional (kill_method)
  - Weighted selection algorithm: normalize weights, cumulative search, deterministic with math.randomseed(42)
  - Instantiation flow: roll_loot_table() → weighted_select() → instantiate_drops() → room:add_object()
  - Testing strategy: 8 tests covering weights, distributions, determinism, integration (kill → drops appear)
  - Meta-lint rules: LOOT-001 through LOOT-005 (structure, weights, templates, quantity, kill methods)
  - Example: wolf always drops gnawed-bone, 20% silver-coin, 30% torn-cloth, 50% nothing, 0-3 copper-coins
  - Deterministic testing with fixed seed prevents flaky tests
  - Decision rationale: why weighted (vs fixed), why room-floor (vs corpse container), why separate module

**Key Principles Documented:**
- Principle 8: "Engine executes metadata." All butchery/loot logic defined in creature.lua, engine reads and applies
- D-14 (True Code Mutation): Butchery doesn't swap files; death reshape creates corpse in-place, butchery consumes it
- Metadata-driven: No creature-specific verb code. One butcher handler serves all creatures via declarative specs
- Deterministic RNG: Loot tests use math.randomseed(42) for reproducible sequences (no flaky tests)
- Time advancement (Option B): Butchery costs game time, triggering FSM ticks, spoilage, respawns (strategic depth)

**Learnings:**
- Butchery bridges two domain transitions: (1) furniture (non-portable corpse) → multiple small-items (portable), (2) creature death pattern → crafting input
- Capability-based tool check ("butchering") scales: knife, cleaver, dagger all work without verb code changes
- Loot tables replace fixed Phase 3 inventory: each creature death now unique (variety), but deterministic for testing
- Metadata blocks for butchery + loot keep death handler simple and generic; details authored in creature files
- Time advancement during butchery creates emergent gameplay: player manages spoilage/respawns while processing corpse
- Weighted roll algorithm (cumulative search) is industry-standard (Diablo, Dark Souls); normalizing weights simplifies authoring
- Room-floor loot placement (vs corpse container) avoids "search corpse" verb complexity and aligns with Phase 3 behavior
- Both docs align with existing engine docs style: problem statement → architecture diagram → metadata spec → implementation checklist

**Committed:** Phase 4 WAVE-0 architecture docs reviewed, ready for WAVE-1 code assignments

---

## Previous Work: WAVE-5 — Phase 3 Design Documentation (2026-08-16)

**Phase 3 WAVE-5 Design Docs Delivery:**
- **Completed `docs/design/food-system.md`** (2,432 words, ~10 KB)
  - Cook verb mechanics: aliases (roast/bake/grill), fire_source requirement, recipe structure, mutation flow
  - Edibility tiers: Tier 1 (cooked, safe), Tier 2 (raw meat, conditional), Tier 3 (non-meat raw, rejected)
  - Mutation chain: creature death → corpse → cooked via D-14 code rewrite
  - Spoilage FSM: fresh→bloated→rotten→bones with timed transitions
  - Food effects pipeline: heal, narrate, inflict_injury with probability gating
  - Food economy: positive-sum balance, nutrition rates (rest -0.5, walk -1.0, combat -2.0)
  - Raw meat consequences: food-poisoning injury with onset/nausea/recovery/cleared states (20 tick total)
  - Cooked rat meat object pattern example with full sensory (on_feel, on_smell, on_taste)
  
- **Created `docs/design/cure-system.md`** (1,721 words, ~14 KB)
  - Healing interactions metadata format: transitions_to, from_states, success/fail messages
  - Cure window gating: early (curable), late (incurable), never via state array
  - Antidote pattern: object ID → healing_interactions key matching
  - Rabies example: incubating/prodromal curable, furious/fatal incurable
  - Food-poisoning example: no healing_interactions (incurable, must run course)
  - Interactive cure API: try_heal(), apply_healing_interaction(), resolve_target()
  - Injury targeting priority: exact ID, display name, location, type, ordinal index
  - Per-antidote cure windows: multiple antidotes can have different from_states arrays
  - State-based success/fail narration with customizable messages
  - Rabies injury definition example with healing-poultice cure and full state tree

- **Committed:** `Phase 3 WAVE-5: food-system + cure-system design docs` (db0c0fe)
- Implementation cross-reference verified: cooking.lua, consumption.lua, cure.lua, cooked-rat-meat.lua, food-poisoning.lua, rabies.lua

**Key Principles Documented:**
- D-14 (Code Mutation IS State Change): cook verb rewrites raw-meat.lua → cooked-meat.lua at runtime
- Principle 8 (Engine executes metadata): food.effects array, healing_interactions metadata
- Zero disease-specific engine code: disease definitions declare cures; engine applies them
- Positive-sum economy: players accumulate nutrition faster than depletion (survival phase → abundance)
- Cure windows as resource puzzles: find antidote before disease escalates beyond cure window

**Learnings:**
- Food system bridges creature death (WAVE-1) and combat loop (WAVE-2, WAVE-3): corpse→cooked food
- Raw meat gate creates strategic tension: immediate nutrition risk vs. cooking discovery time
- Food-poisoning is both injury consequence AND tutorial: teaches cooking importance
- Rabies cure window (incubating + prodromal only) encourages early exploration for antidotes
- Metadata-driven cures scale: add new disease → add healing_interactions block → no engine changes

---

## Previous Work: WAVE-0 — Phase 3 Architecture Docs (2026-08-16)

**Phase 3 WAVE-0 Documentation Delivery:**
- Created `docs/architecture/engine/creature-death-reshape.md` (19.7 KB, ~500 words)
  - D-14 in-place reshape pattern: code IS state, creature instances transform without file swap
  - `reshape_instance()` function API (template switch, property overlay, deregister from tick system)
  - `death_state` metadata block format: template selection, sensory properties, food/crafting/container/spoilage FSM
  - Template switching: creature→small-item (rat, cat, spider, bat) or creature→furniture (wolf)
  - GUID preservation & backward compatibility (creatures without death_state keep FSM dead state)
  - Distinction from `mutation.mutate()` (file-swap) vs. reshape (in-place instance transform)
  - Narration API: optional `reshape_narration`, optional byproducts (spider silk)
  - Testing strategy: kill creature → reshape, sensory text correct, GUID preserved, deregister from tick
  
- Created `docs/architecture/engine/creature-inventory.md` (14.3 KB, ~300 words)
  - Inventory metadata format: `hands` (max 2), `worn` (5 slots), `carried` (loose items)
  - Death drop instantiation pipeline: reshape → iterate inventory → create room-floor objects
  - Containment reuse: reshaped corpse inherits `death_state.container` capacity
  - Meta-lint validation: INV-01 (hands max 2), INV-02 (worn slots valid), INV-03 (GUIDs resolve), INV-04 (size constraints)
  - Phase 3 assignments: wolf carries `gnawed-bone-01`, spider silk is byproduct not inventory
  - Gnawed bone object creation path for WAVE-2
  - Testing strategy: wolf dies → bone drops, container works, meta-lint passes
  
- Committed: `Phase 3 WAVE-0: architecture docs for death reshape + creature inventory`
- Key decisions documented:
  - D-CREATURE-DEATH-RESHAPE (in-place reshape, not file swap)
  - D-CREATURE-INVENTORY (direct GUIDs in Phase 3, loot tables deferred to Phase 4)
  - Backward compat guaranteed (creatures without death_state work as-is)
  - Direct GUID references for Phase 3 (Option A from creature-inventory-plan.md)

**Learnings:**
- Both docs align with existing architecture style (problem statement → architecture → implementation checklist)
- Heavy cross-referencing to core principles (D-14), phase plan, and related systems
- Code examples essential for engineer clarity (reshape_instance pseudocode, death_state block template)
- Meta-lint rules keep inventory data well-formed and debuggable
- Distinction between inventory drop (what creature carries before death) vs. corpse container (empty space for future items) prevents confusion

## Previous Work: WAVE-0 — Testing Framework Documentation (2026-03-27)

**WAVE-0 Completion — Brockman's Testing Documentation:**
- Created `docs/testing/README.md` — test framework overview, running tests, CI/CD gates
- Created `docs/testing/framework.md` — pure Lua test helper API, assertions, summary reporting
- Created `docs/testing/patterns.md` — common testing patterns, fixtures, test data strategies
- Created `docs/testing/directory-structure.md` — test directory organization, coverage by area
- Total: 30 KB comprehensive testing documentation
- Documented headless mode (`--headless` CLI flag for CI/LLM automation)
- Documented pre-deploy gate sequence (`test/run-before-deploy.ps1`)
- Purpose: Enable WAVE-1 agents with complete reference material for consistent test patterns
- Decisions documented: D-HEADLESS, D-TESTFIRST

## Prior Context

- **Owner:** Wayne "Effe" Berry
- **Project:** MMO
- **Created:** 2026-03-18

## Core Context (Summarized)

**Role:** Documentation Specialist — capture decisions, maintain glossaries, publish team communications, keep docs as source of truth

**Major Documentation Systems Created:**
- **Core Docs:** README.md, vocabulary.md (200+ terms, 6 categories), architecture-decisions.md, design-directives.md
- **Design Docs:** 11 files in docs/design/ (gameplay mechanics, player-facing systems)
- **Architecture Docs:** 6 files in docs/architecture/ (engine internals, technical patterns)
- **Newspaper (MMO Gazette):** In-universe daily updates; multiple editions per day; op-ed sections
- **Decision Log:** decisions.md (canonical source for squad process + architecture choices)

**Key Achievements:**
- Established documentation-first culture; docs as source of truth
- Clear design/architecture separation (gameplay vs engine internals)
- 40+ cross-references updated and verified
- Vocabulary v1.3 maintained (synchronized with codebase)

**Patterns Established:**
- Gameplay design belongs in docs/design/ from the start
- Object-specific behavior documented in docs/objects/{object}.md
- Newspaper as primary team communication hub

**Decisions Authored:** D-BROCKMAN001 (design/architecture separation), D-BROCKMAN002 (directive sweep)

## Archives

- `history-archive-2026-03-20T22-40Z-brockman.md` — Full archive (2026-03-18 to 2026-03-20T22:40Z): core docs, design sweep, squad manifest, newspaper, design consolidation, reorganization

## Recent Updates

### Session: WAVE-5 Track 5E — Food System PoC Documentation (Current)
**Status:** ✅ COMPLETED
**Deliverable:** `docs/design/food-system.md` (~150 lines, 9.6 KB)

**What I Created:**
1. **Food Metadata Reference** — `edible`, `food = {}` table with nutrition, bait_value, bait_target, spoil_time fields
2. **Eat/Drink Verb Documentation** — Handler signatures, checks (edible flag, inventory/visible search), removal flow
3. **Bait Mechanic Explanation** — Stimulus emission, creature detection, cross-tick pathfinding, bait priority, containment limitations
4. **PoC Scope Matrix** — Included (metadata, eat/drink, spoilage FSM, bait stimulus, test coverage) vs. deferred (cooking, nutrition tracking, hunger meter, recipes, farming)
5. **Sample Food Objects** — Cheese and bread with full FSM, sensory descriptions, bait configuration
6. **Future Expansion Roadmap** — References to food-system-plan.md for cooking, NPC starvation, food trade, farming

**Key Code References:**
- `src/engine/verbs/survival.lua`: `eat` and `drink` handlers (lines 69–187)
- `src/meta/objects/`: cheese.lua, bread.lua (sample objects with FSM and bait metadata)
- `src/engine/creatures/init.lua`: Hunger drive stimulus detection (WAVE-5 implementation)
- `test/food/`: Four test suites covering eat/drink/bait/spoilage/objects

**Learnings:**
- Food is a **metadata trait, not a template** — any object can be edible by declaring `edible = true` + `food = {...}`
- Bait works via **creature stimulus detection** — hunger drive polls for food within smell range; bait_target matches creature type; priority is evaluated cross-tick
- Spoilage FSM uses **state machine with timer transitions** — fresh → stale → spoiled, with sensory updates (on_smell changes for stale/spoiled)
- PoC scope is **lean but complete** — eat/drink/bait work end-to-end; cooking/farming/nutrition defer to full vision
- **No per-player hunger meter** — follows Valheim philosophy: eating is optional buff, not survival requirement (frees inventory for puzzles)

---

### Session: WAVE-3 Track 3E — NPC Combat Architecture Documentation
**Status:** ✅ COMPLETED
**Deliverable:** `docs/architecture/combat/npc-combat.md` (11.6 KB, ~200 lines)

**What I Created:**
1. **NPC Combat Resolution Flow** — 6-phase pipeline (INITIATE → DECLARE → RESPOND → RESOLVE → NARRATE → UPDATE), unified combatant interface, NPC auto-selection of weapon/zone/defense via `npc_behavior` modules
2. **Combatant Interface** — Required fields (combat.speed, body_tree, health), optional NPC fields (behavior, flee_threshold, cornered_bonus)
3. **Turn Order Algorithm** — Speed (highest first) → size tiebreak (smaller first) → player-last, with SIZE_MODIFIERS lookup table
4. **active_fights Tracking** — Fight lifecycle (create → round loop → resolve → cleanup), budget tracking for narration, combat_active flag to suppress wander
5. **Morale & Flee System** — Threshold check after RESOLVE, creature-specific values (rat 0.3, cat 0.4, wolf 0.2, spider 0.1), cornered fallback (1.5× force multiplier when no exits)
6. **Witness Narration Tiers** — 4 locality/light combinations (same room light, same room dark, adjacent, out of range), with Tier 1–2 examples
7. **Narration Budget Protocol** — 6-line cap/round, critical exemptions (death, player action always shown), GRAZE/DEFLECT deferred when over budget, round reset

**Key Code References:**
- `src/engine/combat/init.lua`: `resolve_exchange()`, `run_combat()`, STANCE_MODIFIERS, SIZE_MODIFIERS
- `src/engine/combat/npc-behavior.lua`: `select_response()`, `select_stance()`, `select_target_zone()`
- `src/engine/creatures/init.lua`: Drive system, stimulus integration, flee pathfinding
- `src/engine/combat/narration.lua`: Light-dependent templates, witness tiers

**Learnings:**
- NPC combat is **not a separate path** — same `resolve_exchange()` pipeline for all combatants; NPC-ness is expressed via behavior metadata + auto-selection functions
- Turn order algorithm has a **subtle player disadvantage**: player acts last in tiebreaks, modeling humanoid vulnerability
- Narration budget prevents **exponential output spam** in 3+ creature fights; critical narration always bypasses cap to preserve death messages
- `active_fights` lifecycle mirrors game loop tick structure: create fight on first NPC-NPC exchange, loop through combatants each tick, resolve when list depleted
- Morale **threshold is a fraction**, not absolute health — allows scaling across creature sizes (rat with 10 max health flees at health < 3; wolf with 50 max health flees at health < 10)
- Cornered creatures can't flee but get defensive bonus instead — avoids "trap door" behavior where caged creatures are helpless



### Session: Documentation Reorganization — Design vs Architecture (2026-03-20T22:15Z)
**Status:** ✅ COMPLETED
**Outcome:** Clear separation of gameplay design from technical implementation; 40+ cross-references updated

**Files Reorganization:**
- Moved 6 files to docs/architecture/ (engine internals)
- 11 files remain in docs/design/ (gameplay mechanics)
- 40+ cross-references verified and updated
- Decision D-BROCKMAN001 filed

**Key Insight:** The distinction is **perspective**, not content. Design asks "What can the player do?" Architecture asks "How does the engine make that possible?"

### Session: Design Consolidation & Manifest Completion (2026-03-20T12:32Z)
**Status:** ✅ COMPLETED

- Created 00-design-requirements.md (unified spec, implementation status)
- Created 00-architecture-overview.md (design-to-code mapping)
- Published newspaper/2026-03-20-morning.md
- Merged Decision 28 (Composite) and Decision 29 (Spatial) into decisions.md

### Session: Morning Edition Publication (2026-03-20T06:00Z)
**Status:** ✅ COMPLETE
- Created newspaper/2026-03-20-morning.md (overnight progress, composite objects, bug fixes)
- Maintained in-universe voice with op-ed sections

### Session: Post-Integration Documentation Sweep (2026-03-21)
**Status:** ✅ COMPLETE
- README.md updated to "prototype phase" with "How to Run"
- docs/design/verb-system.md created (31 verbs, 4 categories)
- docs/architecture/src-structure.md updated
- All cross-references verified, no broken links

### Session: Squad Manifest Completion (2026-03-21)
**Status:** ✅ DECISIONS MERGED
- Processed 12 inbox decisions into canonical decisions.md
- Hybrid parser, property-override, type/type_id naming

### Session: Play Test Iteration (2026-03-19T13:22Z)
**Status:** ✅ COMPLETE
- Documented 4 core puzzles, merged D-37 to D-41

## Directives Captured
1. Newspaper editions in separate files (2026-03-20T03:40Z)
2. Room layout and movable furniture (2026-03-20T03:43Z)

## Recent Updates (Continued)

### Session: Testing Process Documentation (Current)
**Status:** ✅ COMPLETED
**Outcome:** Created comprehensive testing documentation in `docs/testing/` (4 files, ~29KB)

**Files Created:**
- `docs/testing/README.md` — Testing system overview (quick start, how it works, headless mode)
- `docs/testing/framework.md` — API reference (test helpers, assertions, pcall wrapping, error handling)
- `docs/testing/patterns.md` — Patterns & conventions (file structure, context factory, output capture, examples)
- `docs/testing/directory-structure.md` — Test directory layout (16 directories, 200+ test files, discovery mechanism)

**Key Insights Documented:**
- Pure-Lua framework with zero external dependencies (ideal for browser deployment)
- Test runner uses subprocess isolation (`io.popen`) — one failure doesn't contaminate others
- Context factory pattern (`make_ctx()`) for test isolation
- Output capture pattern for narration testing
- Test file structure: package.path setup → imports → suites → summary → exit code
- Framework uses `pcall()` wrapping to safely catch assertion errors
- Exit code contract: 0 = pass, 1 = fail; runner aggregates subprocess codes
- 16 test directories organized by subsystem (parser, verbs, search, inventory, injuries, etc.)
- 200+ test files total across all directories
- Directory discovery is hardcoded in `test/run-tests.lua` — add new dirs there

**Coverage Areas:**
- Parser pipeline (30+ tests) — preprocessing, normalization, verb/noun splitting
- Verb handlers (80+ tests) — spatial, interaction, fire/light, combat, container verbs
- Inventory system (11 tests) — take/drop, hand management, containers
- Object discovery (23 tests) — keyword matching, nesting, spatial relationships
- Integration scenarios (7 tests) — multi-command sequences

**Design Decision:** Documentation focuses on **framework mechanics, patterns, and conventions** — NOT on what individual tests test (that belongs in test code comments). This enables developers to: (1) write new tests quickly, (2) understand test isolation, (3) add new test directories, (4) navigate the test suite by subsystem.

## Learnings
- Documentation consolidation prevents design drift
- Update foundational docs immediately after features land
- Newspaper as team communication hub works well (morning/evening/late editions)
- Design vs. architecture distinction is about perspective, not content
- Research scales with organizational infrastructure (subfolders early)
- Design directives create implementation clarity
- File reorganization can leave duplicates behind; periodic cleanup sweeps catch orphaned refs
- When adding approved principles: update TOC first, then append full section following the exact formatting pattern of existing principles, preserve all wording from approved draft
- Parser tier extraction: split complex layered systems by logical boundaries (Tier 1+2 vs Tier 3+) for clarity; update all cross-references (overview, related docs) in single pass
- **Parser tier refactoring learning:** When splitting composite docs into per-tier files, create separate .md per tier (not per layer group). This enables: (1) independent status tracking (✅ Built vs 🔷 Designed), (2) bidirectional cross-references, (3) focused navigation for specific tier. Always preserve ZERO content loss and include implementation file paths in built tiers.
- **Test pass organization:** Flat test directories scale poorly as team grows. Organize early with ownership (Nelson→gameplay/, Lisa→objects/), zero-padded sequential numbering (001, 002...), date-aware filenames (YYYY-MM-DD-pass-NNN), and clear README explaining naming conventions. Enables parallel work, clear responsibility, and easy browsing of related test runs.
- **Evening edition (2026-03-22):** Created newspaper/2026-03-22-evening.md (~4,500 words, 12 sections). Covered 3 sessions: Phase 7 deploy, Phase 3 five-feature blitz (hit verb, unconsciousness, sleep fix, appearance, mirror), Wayne's iPhone play-test (19 issues), spatial relationship design. Key stats: 40 git commits, 1,117+ tests, 8 team members, 20 decisions, 3 deploys. Pattern: when a day spans morning + evening editions, the evening must explicitly reference the morning's cliffhangers (deploy blocked → deploy shipped) to create narrative continuity. Multi-session days benefit from a chronological session-by-session structure rather than thematic grouping.
- **Code examples in newspapers:** Include 6-10 code examples per edition for technical depth. Code examples should illustrate the *architectural insight*, not just the implementation — e.g., the consciousness gate example shows the game loop paradigm shift, not just an if-statement.
- **Morning edition (2026-03-23):** Created newspaper/2026-03-23-morning.md (~5,800 words, 14 sections). Covered the most productive single session in project history: 25 issues closed (34→3), Effects Pipeline (EP1–EP10) designed/built/tested/shipped, 284 new pipeline tests with 0 regressions, 3 objects built (poison bottle, bear trap, crushing wound), 30+ parser phrase transforms. Pattern: when a session has a clear 3-wave chronological structure (burndown → design → implementation), organize sections by wave to preserve narrative momentum. The "before/after" architecture diagram (spaghetti vs pipeline) is the most effective way to explain why an architectural change matters. Running gags (os.exit(0)) create narrative threads readers can follow. Wayne's interventions (test ordering, hook questions) deserve their own narrative weight — they changed the session's trajectory.
- **Mega-session coverage:** Sessions with 40+ agent spawns and 10+ pipeline phases benefit from a phase-by-phase walkthrough (EP1→EP10) rather than grouping by role. Readers want to see the *sequence* — architecture → safety net → gate → build → verify → refactor → document. Each phase gets its own subsection with owner emoji, phase number, and outcome. This creates a "progress bar" effect that makes the session's momentum tangible.
- **Wayne's design doc directive:** Design documentation should NOT list bug fixes, issue numbers, or fix history. Bug fixes belong in issues and changelogs. Instead, design docs should capture the DESIGN INSIGHTS that emerged from bugs — what principles did they reveal? What patterns does the system need to honor? Example: instead of "BUG-078: Drawer not searched—fixed by recursive traversal," write "Containers inside containers must be traversable because players think in physical spaces, not object trees. The traversal engine recursively follows nested containers." Transform chronological bug lists into thematic "Design Principles" or "Lessons Learned" sections that read as timeless design guidance, not historical bug trackers.
- **OP-ED IS MANDATORY:** The op-ed section (established March 18 as a permanent daily feature) is NOT optional. Every newspaper edition must include a `## 📰 OP-ED` section written by a rotating team member. The op-ed should be 3-5 substantive paragraphs tied to that session's work, expressing an opinion or architectural argument. If a paper ships without an op-ed, it is incomplete. Never skip this section.

### Session: SLM/Embedding Architecture Documentation (2026-03-24T21:15Z)
**Status:** ✅ COMPLETED  
**Issue:** #175  
**Related:** #174 (SLM lazy-load audit), #176 (Frink's embedding research)

**Outcome:** Created comprehensive **docs/architecture/parser/embedding-system.md** (11 sections, 362 KB ~18,900 chars)

**What Was Documented:**
1. **System Overview** — Tier 2 semantic matcher in 5-tier pipeline, purpose (convert player paraphrases to verb+noun), Jaccard token matching algorithm (8.1ms lookup)
2. **Index Structure** — Slim format (362 KB text/verb/noun only), 4,579 phrases, 48 verbs × 41 nouns with ~3 variants each, entry format
3. **Generation Pipeline** — Phase 1 (generate_parser_data.py: extract verbs/objects from Lua, generate training CSV), Phase 2 (build_embedding_index.py: GTE-tiny encoding, save slim+archive), regeneration workflow
4. **Runtime Usage** — Lua matcher API, Jaccard algorithm with prefix bonus, tokenization + stop-word filtering, typo correction, tiebreaker logic (prefer base-state nouns), performance budget (8.1ms/4,579 phrases)
5. **Web/Browser Architecture** — Fengari/browser loading, caching strategy (1-day browser cache, lazy load), future ONNX path for real vector similarity
6. **D-KEEP-JACCARD Decision** — Frink's research: 68% Jaccard vs 45% cosine-BOW, runtime encoding blocker (GTE-tiny can't run in Lua), 23pp accuracy advantage, vectors archived for future experiments
7. **Size Analysis** — Slim 362KB (42x reduction), Full archived 15.3MB with vectors, compression ratio, archive strategy (enable ONNX experimentation)
8. **Cross-references** — Links to all related docs, implementation files, tier overview
9. **Testing** — Unit tests (test-embedding-matcher.lua), integration tests
10. **Troubleshooting** — Common issues (missing index, low quality, performance regression)
11. **Summary** — Key decisions + production readiness status

**Key Technical Decisions Documented:**
- **D-KEEP-JACCARD** embedded from #176 research (full decision context, research summary, alternatives analysis)
- **Generation accuracy:** 4,579 phrases generated via hard-coded templates (reproducible), optional LLM paraphrasing available
- **Web delivery:** Gzipped index 100KB, lazy loading, browser cache 1 day
- **Performance:** 8.1ms/lookup verified, well under 10ms budget, Fengari ~24-81ms acceptable
- **Regeneration:** Clear workflow documented (2 Python steps, ~60 seconds total)

**Cross-linking Added:**
- Referenced from docs/design/verb-system.md (48 verbs confirmed)
- Referenced from docs/design/prime-directive-tiers.md (Tier 2 context)
- Cross-refs to Tier 1 (exact), Tier 3 (GOAP), Tier 4 (context), Tier 5 (fuzzy)
- Links to implementation files (embedding_matcher.lua, build scripts, test suite)

**GitHub Comment:** Submitted summary to #175 with all acceptance criteria marked complete

**Learning:** Technical system documentation should embed decision research (Frink's 60-test comparison) and include practical troubleshooting (index regeneration, performance regression detection). Accurate technical docs require code verification (embedding_matcher.lua algorithm, build_embedding_index.py process).
- **Post-ship documentation verification (Issue #130):** When a feature ships without a design doc, read the implementation (verbs, engine integration, event hooks) in parallel with the existing design spec. If design was written pre-implementation, add an "Implementation Status" appendix capturing: (1) actual event hook signatures, (2) related file paths, (3) shipped object examples, (4) any design→code divergences. This creates a bridge between "What we designed" and "What shipped," helping future readers understand both intent and reality. The appendix should be sparse (facts only, no narrative) to avoid duplicating the design spec. Wearable system: verified design doc already existed (Comic Book Guy, Phase A7), added Appendix A (Implementation Status) with event hooks, armor integration, appearance rendering, conflict algorithm, and shipped examples.

### Session: Morning Edition (2026-03-24T08:30Z)
**Status:** ✅ COMPLETED
**File:** newspaper/2026-03-24-morning.md (~6,800 words)

**Coverage:**
- Armor System (Phase A): Material-derived protection values (22 materials, 1-10 scale)
- Fit multipliers (makeshift 0.5×, fitted 1.0×, masterwork 1.2×)
- State multipliers (intact 1.0×, cracked 0.7×, shattered 0.0×)
- Equipment event hooks (on_wear, on_remove_worn callbacks)
- Instance-level flavor text system (event_output, one-shot)
- Parser bug cluster (#137-145, #156): Hit synonyms, case normalization, keyword collisions, nested access
- Flanders fixes: Ceramic pot degradation (#155), cloak tear mechanics (#134), brass bowl collision
- Architecture decisions: D-EQUIP-HOOKS, D-EVENT-OUTPUT
- Test coverage: 60+ new regression tests, 1,067+ total tests, 74/74 files passing
- Stats: 15+ issues closed, 12+ commits, 2+ deploys

**Key Themes:**
- Material-derived systems enforce Core Principle 9 (Material Consistency) without hardcoding
- Protection formula: (hardness × 0.4) + (density × 0.3) + (thickness × 0.3)
- Equipment callbacks + instance flavor text add expressiveness without mutation
- Parser centralization (scattered synonyms → unified dispatch) reduces bugs and improves maintainability
- Chamber pot helmet achieves peak absurd game design

**Tone:** Technical depth with architectural insights; celebration of material-consistency principle; preview of afternoon code review and meta-compiler tool

### Session: Meta-Check Design Documentation (2026-03-24T16:00Z)
**Status:** ✅ COMPLETED
**Requestor:** Wayne Berry (P0-B directive: "Before writing a single line of code, create design docs")
**Outcome:** 5 comprehensive design documents for the meta-lint tool, 144 validation rules catalog

**Files Created:**
1. `docs/meta-lint/overview.md` (6.9 KB) — What meta-lint is, why it exists, goals, hybrid compiler/linter role
2. `docs/meta-lint/architecture.md` (14.1 KB) — 6-phase pipeline: tokenization → preprocessing → Lark parse → semantic analysis → cross-file checks → error reporting
3. `docs/meta-lint/usage.md` (12.4 KB) — CLI interface, output formats (text/JSON/TAP), integration examples (GitHub Actions, pre-commit hooks), workflows
4. `docs/meta-lint/rules.md` (22.0 KB) — 144 validation rules across 15 categories, organized by severity (🔴/🟡/🟢), top 10 critical rules
5. `docs/meta-lint/schemas.md` (24.0 KB) — Field contracts per template type (small-item, container, furniture, sheet, room), required/optional fields, examples

**Research Inputs Synthesized:**
- Lisa's acceptance-criteria.md (144 checks across 15 categories) — rules catalog
- Frink's bug-catalog.md (38 bugs, top: missing fields) — justification for validation priorities
- Frink's cross-reference-inventory.md (103 GUIDs, 23 materials, 401 keywords) — data integrity scope
- Bart's lua_grammar.py (Lark parser, 83/83 objects tested) — architecture foundation
- Bart's existing-validation-audit.md (loader checks 3 things, 22 gaps) — validation gap analysis
- Bart's lark-grammar decision (D-LARK-GRAMMAR) — proven architecture strategy

**Key Insights Documented:**
- Meta-check is BOTH compiler (semantic analysis) AND linter (style enforcement)
- 82/83 objects are pure data tables; wall-clock.lua is the sole programmatic outlier
- Function bodies are opaque to static analysis (validated by Lua runtime)
- Critical rule SN-01 (🔴 on_feel required): every object must be perceivable in darkness
- Three-phase pipeline proven: tokenize → preprocess (neutralize functions) → Lark parse
- 38 historical bugs justify validation: missing fields (21), invalid references (10), structural issues (3), architectural violations (1)
- Cross-file validation catches GUID duplicates, keyword collisions, unresolved mutations
- Exit code protocol: 0=pass, 1=errors, 2=warnings

**Documentation Style Applied:**
- Overview: problem/solution/goals (non-technical overview for stakeholders)
- Architecture: phase-by-phase technical design (for implementers)
- Usage: CLI interface + practical workflows (for developers + CI/CD)
- Rules: comprehensive catalog with severity, organization by category + workflow (reference for developers)
- Schemas: field contracts per template, examples (contract enforcement for meta-lint)

**Learnings:**
- **Meta-check specification complexity:** When a tool must enforce 144+ rules across 15+ categories, organize into: (1) high-level overview (why we need this), (2) architecture spec (how it works), (3) usage guide (how to run it), (4) rules catalog (what it checks), (5) schema contracts (what fields are required). Trying to fit all of this into one doc creates cognitive overload. Splitting into 5 focused docs allows developers to navigate by use case.
- **Design-first creates clarity:** Wayne's directive ("design docs before code") prevents 3 problems: (1) scope creep during implementation (dev realizes they didn't understand the requirement), (2) architectural conflicts (different parts of implementation make conflicting assumptions), (3) incomplete rule coverage (implementing rules A+B then discovering rule C's dependency on both). With design docs locked in, implementation becomes straightforward.
- **Validation gap analysis is critical:** Frink's audit of the loader (what it checks vs. what it doesn't) revealed 22 gaps. Each gap becomes a must-have rule in meta-lint. Without this audit, meta-lint would likely miss half its rules.
- **Evidence-based rule priority:** The 38-bug catalog provides justification for every rule. Top 3 bug types (missing materials, GUID mismatches, FSM state errors) become top 3 meta-lint rules. Developers trust rules that have evidence behind them.
- **Template-specific schemas:** Objects inherit from 5 templates, each with different field requirements. Instead of one monolithic schema, 5 focused schemas (one per template) make validation clear and rules easier to understand.

**Commit:** (pending implementation; design phase only)

### Session: Player System Extraction (2026-03-22)
**Status:** ✅ COMPLETED
- Created docs/architecture/player/ subfolder
- Extracted player-model.md (inventory, hands, worn items, skills)
- Extracted player-movement.md (exits, location tracking, room transitions)
- Extracted player-sensory.md (light/dark system, vision blocking)
- Updated 00-architecture-overview.md with cross-references
- All content preserved; nothing lost in reorganization
- Commit: f1935c7

### Session: Duplicate Core-Principles Cleanup (2026-03-22)
**Status:** ✅ COMPLETED
- Discovered and removed duplicate core-principles.md at root level
- Kept authoritative copy at docs/architecture/objects/core-principles.md
- Updated 4 cross-references in 4 files (00-architecture-overview.md, open-questions.md, decisions.md, orchestration-log)
- Commit: 92601d2

### Session: Parser Documentation Extraction (2026-03-25)
**Status:** ✅ COMPLETED
- Created docs/architecture/engine/basic-parser.md (202 lines, 7.4 KB)
- Extracted Tier 1 (Exact Dispatch) and Tier 2 (Phrase Similarity) from 00-architecture-overview.md
- Comprehensive coverage: design, characteristics, implementation strategy, flow diagrams, testing strategy, performance notes
- Updated 00-architecture-overview.md: removed 13 lines, added 1-line cross-reference
- Updated intelligent-parser.md: added basic-parser.md to REFERENCES section
- All content preserved; overview reduced by ~150 lines in focused extraction
- Commit: b1c49d2

### Session: Parser Tier Refactoring — 5 Dedicated Files (2026-03-25)
**Status:** ✅ COMPLETED
**Requestor:** Wayne Berry
**Outcome:** ONE .md file per parser tier (exactly 5 files) + updated architecture overview

**Files Created:**
1. `parser-tier-1-basic.md` (2.5 KB) — Exact verb dispatch [✅ Built]
2. `parser-tier-2-compound.md` (7.5 KB) — Phrase similarity fallback [✅ Built]
3. `parser-tier-3-goap.md` (19.6 KB) — GOAP backward-chaining [🔷 Designed]
4. `parser-tier-4-context.md` (7.7 KB) — Context window memory [🔷 Designed]
5. `parser-tier-5-slm.md` (9.7 KB) — SLM/LLM fallback, Phase 2+ [🔷 Designed]

**Files Deleted:**
- `basic-parser.md` (replaced by Tiers 1+2)
- `intelligent-parser.md` (replaced by Tiers 3-5)

**Changes to Overview:**
- Updated 00-architecture-overview.md Layer 2 section
- Added all 5 tier files with status badges (✅ Built vs 🔷 Designed)
- Cross-referenced each tier to its dedicated file
- Added architecture example showing tier fallback flow

**Content Preservation:** Zero loss — all content from both source files (basic-parser.md + intelligent-parser.md) split into tier-specific files with clear headers, status markers, and bidirectional cross-references.

**Each Tier File Includes:**
- Clear header: "# Parser Tier N: {Name}"
- Status badge: ✅ Built or 🔷 Designed (not yet implemented)
- File path of implementation (for built tiers)
- Cross-references to adjacent tiers
- Full design, examples, implementation notes
- Integration points with other tiers

**Commit:** e9cf2f0 with Co-authored-by trailer

---

## CROSS-AGENT UPDATES (2026-03-24T12:41:24Z Spawn Orchestration)

### Search Design Docs Rewrite
- **Status:** DELIVERED
- **Change:** Removed bug fix history from design docs (docs/design/verbs/search.md)
- **Added:** 8 formal design principles
- **Principles:**
  1. Search is non-mutating (read-only observation)
  2. Hidden objects remain invisible until revealed
  3. Containers are peekable during search (no state change)
  4. Content reporting on target miss
  5. Search cost reflects deliberateness
  6. Spatial relationships determine accessibility
  7. Container-accessible vs physically-blocked distinction
  8. Search reveals game world structure
- **Rationale:** Wayne directive — design docs capture design insights, not bug archaeology. Bugs belong in issues/changelogs.

### Decision Updated
- **D-WAYNE-DIRECTIVE-DESIGN-DOCS:** Design docs should NOT document bug fixes; capture design principles instead

### Session: Documentation Update — Issues #160 & #161 (2026-03-28T14:00Z)
**Status:** ✅ COMPLETED
**Outcome:** Two documentation issues fixed with comprehensive armor interceptor and equipment hook documentation

**Files Updated:**
1. `docs/architecture/engine/effects-pipeline.md`
   - Updated version from 2.0 to 3.0
   - Added Section 4.3: Armor Interceptor — Material-Derived Protection (SHIPPED)
   - Documented core protection formula: `actual_damage = max(1, incoming - protection)`
   - Documented protection calculation including: hardness (1.0×), flexibility (1.0×), density (0.5×)
   - Documented fit multipliers: makeshift 0.5×, fitted 1.0× (default), masterwork 1.2×
   - Documented degradation state multipliers: intact 1.0×, cracked 0.7×, shattered 0.0×
   - Documented location coverage via explicit `covers` array or `wear.slot` matching
   - Documented degradation transition formula: `break_chance = fragility × (damage / 20) × impact_factor`
   - Documented impact factors: piercing 0.5×, slashing 1.0×, blunt 1.5×
   - Referenced actual implementation at `src/engine/armor.lua`
   - Renamed section 4.4 to 4.5 (Interceptor Ordering)

2. `docs/architecture/engine/event-hooks.md`
   - Updated Section 2.2 table (Currently Active Hooks) to fix implementation location references:
     - `on_drop`: corrected to `acquisition.lua` (was `verbs/init.lua`)
     - `on_wear`: corrected to `equipment.lua` (was `verbs/init.lua`)
     - `on_remove_worn`: corrected to `equipment.lua` (was `verbs/init.lua`)
     - `on_open`: corrected to `containers.lua` (was `verbs/init.lua`)
     - `on_close`: corrected to `containers.lua` (was `verbs/init.lua`)
   - Updated Section 11.3 Implementation Location: removed stale line number references, emphasized file organization
   - Updated Section 12.5 Dispatch Points table: added `on_open` and `on_close`, corrected file references to match refactored verb handlers

**GitHub Issues Closed (via comment, not automated):**
- Issue #160: "Update event-hooks.md — add on_drop hook + equipment category" → DOCUMENTED
- Issue #161: "Update effects-pipeline.md to v3.0 — document armor interceptor" → DOCUMENTED

**Testing:**
- All 101 tests pass (0 regressions)
- Documentation changes verified to not break any gameplay systems

**Key Insights:**
- **Refactored verb system:** When verbs are split from `verbs/init.lua` into dedicated files (`equipment.lua`, `acquisition.lua`, `containers.lua`), documentation must be updated to reflect the new file structure. References like "line 5011" become outdated immediately.
- **Armor interceptor is high-value documentation:** Material-derived protection values, degradation model, and fit multipliers are complex mechanics that warrant detailed section treatment. Breaking it into subsections (calculation, location coverage, degradation, narration) improves readability.
- **One-shot pattern (event_output) is a good teaching example:** The pattern of "print text, then nil the field" is elegant and worth documenting as a DATA pattern alternative to callbacks. Content authors can use this for first-time flavor text without writing Lua functions.
- **Precision in file paths matters:** When documentation lists implementation locations, keep them current as code reorganizes. The effect.pipeline.md example of armor shows how important it is to reference actual, working code paths.

### Session: Bedroom Objects Design Docs — Matchbox Documentation (2026-07-24T10:15Z)
**Status:** ✅ COMPLETED
**Outcome:** Created comprehensive design documentation for matchbox object (only bedroom object lacking docs)**Files Created:**
1. `docs/objects/matchbox.md`
   - Description and material (cardboard)
   - Location & puzzle role (primary fire source, limited supply)
   - Containment structure (holds 7 matches in closed/open states)
   - FSM states: closed (inaccessible) ↔ open (accessible)
   - Sensory descriptions (all 4 senses for both states)
   - Transitions (closed→open via `open`, open→closed via `close`)
   - Container capacity and weight properties
   - Special properties: `has_striker=true` for compound interactions
   - Keywords and aliases (matchbox, match box, tinderbox, lucifers, etc.)
   - Integration with Match system (7-tick total burn economy)
   - Puzzle dependencies (nightstand → matchbox → matches → fire interactions)**Status Check:**
- ✅ Nightstand: doc exists (`nightstand.md`)
- ✅ Matchbox: NEW doc created (`matchbox.md`)
- ✅ Wardrobe: doc exists (`wardrobe.md`)
- ✅ Bed: doc exists (`bed.md`)
- ✅ Rug: doc exists (`rug.md`)
- ✅ Trap Door: doc exists (`trap-door.md`)**Key Learnings:**
- Matchbox is a critical puzzle junction: container + striker tool + limited consumable resource
- Container accessibility pattern: `accessible=false` (closed) prevents contents access; mutation to `matchbox-open` sets `accessible=true`
- Fire economy: 7 matches × 3-tick burn time = 21 total ticks. Scarcity drives player decision-making
- Compound verbs require `has_striker=true` metadata on matchbox (not just conceptual)
- All bedroom objects now fully documented with design directives, sensory properties, and puzzle roles
