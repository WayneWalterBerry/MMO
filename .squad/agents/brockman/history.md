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
