# Squad Decisions

**Last Updated:** 2026-03-26T15:30:00Z  
**Last Deep Clean:** 2026-03-25T18:21:05Z  
**Scribe:** Session Logger & Memory Manager

## How to Use This File

**Agents:** Scan the Decision Index first. Active decisions have full details below. Archived decisions are in `decisions-archive.md`.

**To add a new decision:** Create `inbox/{agent-name}-{slug}.md`, Scribe will merge it here.

---

## Decision Index

Quick-reference table of ALL decisions (active + archived). 

| ID | Category | Status | One-Line Summary | Location |
|----|----------|--------|------------------|----------|
| D-14: True Code Mutation (Objects Rewritten, Not Flagged) | Architecture | 🟢 Active | Foundational | Active |
| D-INANIMATE: Objects Are Inanimate (Creatures Are Future) | Architecture | 🟢 Active | See full entry | Active |
| D-ENGINE-REFACTORING-REVIEW | General | 🟢 Active | See full entry | Active |
| D-HIRING-DEPT: All New Hires Must Have Department Assignment | General | 🟢 Active | See full entry | Active |
| D-NO-NEWSPAPER-PENDING: Newspaper Hold Directive | General | 🟢 Active | See full entry | Active |
| D-VERBS-REFACTOR-2026-03-24 | General | 🟢 Active | See full entry | Active |
| D-LARK-GRAMMAR: Lark-Based Lua Object Parser | Parser | 🟢 Active | See full entry | Active |
| D-META-CHECK-BUILD-2026-03-24 | Parser | 🟢 Active | See full entry | Active |
| D-PORTAL-BIDIR-SYNC: Bidirectional Portal Sync in FSM Engine | Architecture | ✅ Implemented | Portal sync is engine-driven, not verb-handler-driven | Active |
| D-PORTAL-PHASE-2-ROOM-WIRING: Portal Phase 2 Room Wiring Complete | Architecture | ✅ Implemented | Thin portal references in start-room & hallway | Active |
| D-WAYNE-BATCH-2026-03-24: Design Decisions Batch (Wayne) | Process | 🟢 Active | See full entry | Active |
| D-WAYNE-CODE-REVIEW-DIRECTIVE (2026-03-24T07-28-58Z) | Process | 🟢 Active | See full entry | Active |
| D-WAYNE-COMMIT-CHECK: Check Commits Before Push (Quality Gate) | Process | 🟢 Active | See full entry | Active |
| D-WAYNE-CONTRIBUTIONS: Track Wayne Contributions Continuously | Process | 🟢 Active | See full entry | Active |
| D-WAYNE-META-CHECK-SCOPE-EXPANSION (2026-03-24T17-40-46Z) | Process | 🟢 Active | See full entry | Active |
| D-WAYNE-TDD-REFACTORING-DIRECTIVE (2026-03-24T07-34-02Z) | Process | 🟢 Active | See full entry | Active |
| D-HEADLESS: Headless Testing Mode | Testing | 🟢 Active | See full entry | Active |
| D-TESTFIRST: Test-First Directive for Bug Fixes | Testing | 🟢 Active | See full entry | Active |
| D-V2-ACCEPTANCE-CRITERIA: P0-C V2 Acceptance Criteria Complete | Testing | 🟢 Active | See full entry | Active |
| D-WAYNE-REGRESSION-TESTS: Every Bug Fix Must Include Regression T | Testing | 🟢 Active | See full entry | Active |
| D-NPC-COMBAT-ALIGNMENT: NPC Plan ↔ Combat Plan Alignment (13 fixes) | Design | 🟢 Active | All 13 alignment fixes applied to NPC system plan | Active |
| D-COMBAT-NPC-PHASE-SEQUENCING: NPC Phase 1 Uses Simple injuries.inflict() | Design | 🟢 Active | No combat FSM, body_tree, or combat metadata in Phase 1 | Active |
| D-CREATURES-DIRECTORY: Dedicated Directory for Animate Beings | Architecture | ✅ Implemented | rat.lua moved to src/meta/creatures/; loader updated; tests pass | Active |
| D-FOOD-SYSTEMS-RESEARCH: Food Systems Research Complete | Research | ✅ Complete | 4 documents (127 KB), 15+ games analyzed, 80% engine ready | Active |
| D-CHECKPOINT-AFTER-WAVE: Checkpoint After Every Wave | Process | 🟢 Active | Verify wave completion, update plan documentation as living doc | Active |
| Architecture Notes | Architecture | 📦 Archived | See full entry | Archive |
| D-104: PLAYER-CANONICAL-STATE (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-105: OBJECT-INSTANCING-FACTORY (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-123: MATERIAL-MIGRATION (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-167: P0C-META-CHECK-V2 (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-168: COMPOUND-COMMAND-SPLITTING (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-169: AUTO-IGNITE-PATTERN (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-170: DOOR-FSM-ERROR-ROUTING (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-3: Engine Conventions from Pass-002 Bugfixes (2026-03-22) | Architecture | 📦 Archived | See full entry | Archive |
| D-42: Movement Handler Architecture | Architecture | 📦 Archived | See full entry | Archive |
| D-45: FSM Tick Scope | Architecture | 📦 Archived | See full entry | Archive |
| D-ALREADY-LIT: FSM State Detection for Already-Lit Objects | Architecture | 📦 Archived | See full entry | Archive |
| D-APP-STATELESS: Appearance subsystem is stateless | Architecture | 📦 Archived | See full entry | Archive |
| D-APP001: Appearance is an Engine Subsystem | Architecture | 📦 Archived | See full entry | Archive |
| D-BRASS-BOWL-KEYWORD-REMOVAL | Architecture | 📦 Archived | See full entry | Archive |
| D-BROCKMAN001: Design vs Architecture Documentation Separation | Architecture | 📦 Archived | See full entry | Archive |
| D-BUG017: Save containment before FSM cleanup | Architecture | 📦 Archived | See full entry | Archive |
| D-CONDITIONAL: Conditional Clauses Detected in Loop, Not Parser | Architecture | 📦 Archived | See full entry | Archive |
| D-CONSC-GATE: Consciousness gate before input reading | Architecture | 📦 Archived | See full entry | Archive |
| D-CONTAINER-SENSORY-GATING | Architecture | 📦 Archived | See full entry | Archive |
| D-ENGINE-HOOKS-USE-EAT-DRINK | Architecture | 📦 Archived | See full entry | Archive |
| D-FIRE-PROPAGATION-ARCHITECTURE | Architecture | 📦 Archived | See full entry | Archive |
| D-GOAP-NARRATE: GOAP Steps Narrate via Verb-Keyed Table | Architecture | 📦 Archived | See full entry | Archive |
| D-HIT001: Hit verb is self-only in V1 | Architecture | 📦 Archived | See full entry | Archive |
| D-HIT002: Strike disambiguates body areas vs fire-making | Architecture | 📦 Archived | See full entry | Archive |
| D-HIT003: Smash NOT aliased to hit | Architecture | 📦 Archived | See full entry | Archive |
| D-MATCH-TERMINAL-STATE | Architecture | 📦 Archived | See full entry | Archive |
| D-MODSTRIP: Noun Modifier Stripping is a Separate Pipeline Stage | Architecture | 📦 Archived | See full entry | Archive |
| D-MUTATE-PROPOSAL: Generic `mutate` Field on FSM Transitions | Architecture | 📦 Archived | See full entry | Archive |
| D-OBJ004: Wall clock uses 24-state cyclic FSM | Architecture | 📦 Archived | See full entry | Archive |
| D-OBJECT-INSTANCING-FACTORY | Architecture | 📦 Archived | See full entry | Archive |
| D-P1-PARSER-CLUSTER | Architecture | 📦 Archived | See full entry | Archive |
| D-PEEK: Read-Only Search Peek for Containers | Architecture | 📦 Archived | See full entry | Archive |
| D-PLAYER-CANONICAL-STATE | Architecture | 📦 Archived | See full entry | Archive |
| D-PUSH-LIFT-SLIDE-VERBS | Architecture | 📦 Archived | See full entry | Archive |
| D-SEARCH-OPENS: Search Opens Containers (supersedes #24) | Architecture | 📦 Archived | See full entry | Archive |
| D-SLEEP-INJURY: Sleep now ticks injuries (bug fix) | Architecture | 📦 Archived | See full entry | Archive |
| D-SPATIAL-ARCH: Spatial Relationships — Engine Architecture | Architecture | 📦 Archived | See full entry | Archive |
| D-TIMER001: Timed Events Engine — FSM Timer Tracking and Lifecycl | Architecture | 📦 Archived | See full entry | Archive |
| D-UI-1 to D-UI-5: Split-Screen Terminal UI Architecture (2026-07- | Architecture | 📦 Archived | See full entry | Archive |
| D-WASH-VERB-FSM | Architecture | 📦 Archived | See full entry | Archive |
| D-WEB-BUG13: Bug Report Transcript in Web Bridge Layer | Architecture | 📦 Archived | See full entry | Archive |
| D-WINDOW-FSM: Window & Wardrobe FSM Consolidation (2026-03-20) | Architecture | 📦 Archived | See full entry | Archive |
| DIRECTIVE: Core Principles Are Inviolable | Architecture | 📦 Archived | See full entry | Archive |
| DIRECTIVE: User Reference — Dwarf Fortress Architecture Model | Architecture | 📦 Archived | See full entry | Archive |
| UD-2026-03-20T21-54Z: No special-case objects; clock as 24-state  | Architecture | 📦 Archived | See full entry | Archive |
| USER-DIRECTIVE: Merge wardrobe into single FSM file (2026-03-20T2 | Architecture | 📦 Archived | See full entry | Archive |
| USER-DIRECTIVE: Merge window into single FSM file (2026-03-20T21- | Architecture | 📦 Archived | See full entry | Archive |
| Affected Team Members | General | 📦 Archived | See full entry | Archive |
| D-17: Universe Templates (Build-Time LLM + Procedural Variation) | General | 📦 Archived | See full entry | Archive |
| D-37 to D-41: Sensory Verb Convention & Tool Resolution | General | 📦 Archived | See full entry | Archive |
| D-43: Multi-Room Loading at Startup | General | 📦 Archived | See full entry | Archive |
| D-44: Per-Room Contents, Shared Registry | General | 📦 Archived | See full entry | Archive |
| D-46: Cellar as Room 2 | General | 📦 Archived | See full entry | Archive |
| D-47: Exit Display Name Convention | General | 📦 Archived | See full entry | Archive |
| D-5: Spatial Relationships Implementation (2026-03-26) | General | 📦 Archived | See full entry | Archive |
| D-APP002: Layered Head-to-Toe Rendering | General | 📦 Archived | See full entry | Archive |
| D-APP003: Nil Layers Silently Skipped | General | 📦 Archived | See full entry | Archive |
| D-APP004: Appearance Generic Over Player State | General | 📦 Archived | See full entry | Archive |
| D-APP005: Injury Phrases via 4-Stage Pipeline | General | 📦 Archived | See full entry | Archive |
| ... | ... | ... | +87 more archived decisions | Archive |


**Legend:** 🟢 Active | 🔄 In Progress | ✅ Implemented | 📦 Archived

---

## Active Decisions

These are decisions agents need to know about RIGHT NOW.


### D-14: True Code Mutation (Objects Rewritten, Not Flagged)

**Status:** Foundational

---

### D-INANIMATE: Objects Are Inanimate (Creatures Are Future)

**Author:** Wayne "Effe" Berry + Flanders (Object Engineer)

---

### D-ENGINE-REFACTORING-REVIEW

**Author:** Bart (Architect)

---

### D-HIRING-DEPT: All New Hires Must Have Department Assignment

**Author:** Wayne "Effe" Berry (via Copilot)

---

### D-NO-NEWSPAPER-PENDING: Newspaper Hold Directive



---

### D-VERBS-REFACTOR-2026-03-24

**Author:** Bart (Architect)

---

### D-LARK-GRAMMAR: Lark-Based Lua Object Parser



---

### D-PORTAL-BIDIR-SYNC: Bidirectional Portal Sync Lives in FSM Engine

**Author:** Bart (Architect)  
**Date:** 2026-07  
**Status:** ✅ Implemented

Bidirectional portal synchronization is implemented in `src/engine/fsm/init.lua`, not in individual verb handlers.

When `fsm.transition()` completes successfully, if the transitioned object has `portal.bidirectional_id`, the engine scans the registry for the paired portal and applies the same state change automatically.

**Rationale:**
- **Principle 8 compliance:** Engine executes metadata; no object-specific logic in handlers.
- **Consistency:** Any verb that triggers an FSM transition (open, close, break, unbar, lock) automatically syncs the pair. No risk of forgetting to add sync calls to new verbs.
- **Simplicity:** One sync point instead of N verb handlers each calling sync.

**Impact:**
- **Flanders:** Portal objects only need `portal.bidirectional_id` set to the same value on both sides. No special sync metadata needed.
- **Moe:** Room files don't need any sync logic. Portals sync through the registry automatically.
- **Smithers:** Verb handlers don't need to call `sync_bidirectional_portal()` manually. It happens in FSM.
- **Nelson:** Tests can verify sync by calling `fsm.transition()` directly on a flat registry -- no room context needed.

---

### D-PORTAL-PHASE-2-ROOM-WIRING: Portal Phase 2 Room Wiring Complete

**Author:** Moe (World Builder)  
**Date:** 2026-07-28  
**Category:** Architecture  
**Status:** ✅ Implemented

`start-room.lua` and `hallway.lua` now use thin portal references instead of inline exit tables for the bedroom-hallway oak door.

**What Changed:**
- `exits.north` in start-room → `{ portal = "bedroom-hallway-door-north" }`
- `exits.south` in hallway → `{ portal = "bedroom-hallway-door-south" }`
- Portal objects added to each room's `instances` list
- All other exits (window, trap door, hallway down/north/west/east) remain inline for backward compatibility

**Decision:**
Room files now encode exits as **direction → portal object ID** references. This is the pattern for all future exit definitions (Phase 3 migration). The old inline exit format is deprecated but coexists during migration.

**Impact:**
- **Bart:** Engine must resolve `exits[dir].portal` → registry lookup (now complete via Phase 1 FSM work).
- **Nelson:** Room/door tests need updates to verify portal objects instead of inline fields.
- **Flanders:** Portal object files are referenced by room instances. Do not modify GUIDs without coordination.
- **Smithers:** Verb handlers should already resolve portal objects via registry if Bart's Phase 1 engine work is in.

---

### D-META-CHECK-BUILD-2026-03-24

**Author:** Smithers (UI/Parser)

---

### D-WAYNE-BATCH-2026-03-24: Design Decisions Batch (Wayne)

**Author:** Wayne "Effe" Berry (via Copilot)

---

### D-WAYNE-CODE-REVIEW-DIRECTIVE (2026-03-24T07-28-58Z)

**Author:** Wayne Berry (via Copilot)

---

### D-WAYNE-COMMIT-CHECK: Check Commits Before Push (Quality Gate)

**Author:** Wayne "Effe" Berry (User Directive)

---

### D-WAYNE-CONTRIBUTIONS: Track Wayne Contributions Continuously

**Author:** Wayne "Effe" Berry (User Directive)

---

### D-WAYNE-META-CHECK-SCOPE-EXPANSION (2026-03-24T17-40-46Z)

**Author:** Wayne Berry (via Copilot)

---

### D-WAYNE-TDD-REFACTORING-DIRECTIVE (2026-03-24T07-34-02Z)

**Author:** Wayne Berry (via Copilot)

---

### D-HEADLESS: Headless Testing Mode

**Author:** Bart (Architect)

---

### D-TESTFIRST: Test-First Directive for Bug Fixes

**Author:** Wayne "Effe" Berry (via Copilot)

---

### D-V2-ACCEPTANCE-CRITERIA: P0-C V2 Acceptance Criteria Complete

**Author:** Lisa (Object Testing Specialist)

---

### D-WAYNE-REGRESSION-TESTS: Every Bug Fix Must Include Regression Test

**Author:** Wayne "Effe" Berry (User Directive)

---

### D-NPC-COMBAT-ALIGNMENT: NPC Plan ↔ Combat Plan Alignment

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-03-26  
**Status:** 🟢 Active  
**Category:** Design

**Decision:** Applied all 13 alignment fixes to `plans/npc-system-plan.md`. Both NPC and Combat system plans are now coordinated.

**Critical Fixes:**
1. Body tree phasing moved from NPC Phase 4 → Phase 1 (required by Combat Phase 1)
2. Rat combat metadata added with complete body_tree (4 zones: head, body, legs, tail)
3. Creature-to-creature combat shifted from NPC Phase 3 → Phase 2 (enabled by Combat Phase 1 unified interface)

**High-Priority Fixes:**
4. Creature template updated with `body_tree` and `combat` field stubs (Phase 1+ markers)
5. Tissue materials coordination clarified (NPC: flesh.lua Phase 1; Combat: extends Phase 1)
6. Creature tick ↔ Combat FSM handoff documented (Phase 1 creatures defer `attack` action to Phase 2+)

**Medium-Priority Fixes:**
7. Combat stimulus types added (creature_attacked, creature_injured, creature_died)
8. injuries.inflict() signature updated per Wayne's decision (Phase 1: simple call; Phase 2+: full signature)
9. Size field type standardized to string enum ("tiny", etc.)
10. Combat stimulus emission locations documented (src/engine/combat/init.lua)
11. Phase integration note added to Section 12
12. Weapon combat metadata coordination note (Phase 1 no impact)

**Low-Priority Fixes:**
13. Material naming clarification (flesh distinct from skin/hide)

**Tagging:** All changes marked `[COMBAT ALIGNMENT]` in npc-system-plan.md for easy identification.

**Impact:**
- **Flanders:** Extends rat.lua + creature.lua with body_tree + combat during Combat Phase 1
- **Bart:** Creature tick handles deferred attack action; Combat FSM integration in Phase 2
- **Smithers:** No immediate impact; attack verb unchanged until Phase 2
- **Nelson:** Phase 1 tests verify simple rat bite on grab
- **CBG:** Plans aligned; ready for Phase 1 implementation

**Verification:** `git diff plans/npc-system-plan.md` shows all 13 changes. Combat plan is reference-only (unchanged).

---

### D-COMBAT-NPC-PHASE-SEQUENCING: NPC Phase 1 Uses Simple injuries.inflict()

**Author:** Wayne Berry (via Copilot Coordinator)  
**Date:** 2026-03-26T15:29Z  
**Status:** 🟢 Active  
**Category:** Design

**Decision:** NPC Phase 1 focuses on creature autonomy (behavior, drives, movement). Combat mechanics are deferred to Combat Phase 1.

**Phase 1 Rule:**
- Rats use simple `injuries.inflict()` on grab → no combat FSM, no body_tree, no combat metadata table
- Rat's Phase 1 job: exist, move, react, bite (injury mechanics only)
- Combat Phase 1 retrofits body_tree + full combat table onto creatures later

**Rationale:**
- Principle 8 (engine executes metadata) — dead combat metadata violates principle. Combat metadata only makes sense when Combat Phase 1 engine is ready.
- Sequencing: NPC Phase 1 first establishes creature autonomy; Combat Phase 1 adds combat systems to those creatures
- Keeps Phase 1 focused and shippable

**Affected:**
- **Flanders:** Rat and creature objects are Phase 1 simple; Phase 2 gets combat fields
- **Bart:** Creature tick system handles creature autonomy; Combat FSM waits for Phase 2
- **Nelson:** Phase 1 tests verify injury infliction only
- **CBG:** Maintains design intent while respecting phasing

---

### D-COMBAT-PHASE1-BLOCKING-RESOLUTIONS: Combat Phase 1 — 5 Blocking Questions Resolved

**Author:** Wayne Berry (via Copilot)  
**Date:** 2026-03-26T15:45Z  
**Status:** ✅ Approved  
**Category:** Design

**Q1 — Hit zones:** Random weighted, 60% targeted accuracy. DF-style emergent narrative.

**Q2 — Lethality:** DF-realistic. Steel sword one-shots a rat. Combat is fast and decisive when well-equipped, dangerous when not.

**Q3 — Room scope:** Room-local. Fleeing ends combat. Creature can follow and re-initiate later (if hunt behavior, Phase 2+).

**Q5 — Unarmed combat:** Viable but at a disadvantage. Player can always fight, just poorly. Fists work but barely. "Find a weapon" is strategic advantage, not hard gate.

**Q7 — Combat input model:** HYBRID STANCE-BASED. Player sets stance (aggressive/defensive/balanced) and rounds auto-resolve. BUT the system INTERRUPTS and re-prompts when:
- A weapon breaks
- Armor fails
- The current stance is ineffective after a few auto-resolved rounds
- Any significant state change occurs

This keeps combat flowing but gives player agency at decision points. Not pure per-exchange, not pure auto-resolve.

**Impact:**
- **Bart:** Implement hybrid stance model in combat FSM (WAVE-5.5)
- **Smithers:** Implement combat response prompts with stance interrupts (WAVE-6)

---

### D-NPC-PHASE1-APPROVAL-BATCH: NPC Phase 1 — 7 Questions Resolved

**Author:** Wayne Berry (via Copilot)  
**Date:** 2026-03-26T15:48Z  
**Status:** ✅ Approved  
**Category:** Design

**NPC Q1 — Respawning:** Permanent death in Phase 1. Killed creatures stay dead. Respawn system deferred to Phase 2 if needed.

**NPC Q2 — Multiple creatures per room:** Yes. Support N creatures per room from day one.

**NPC Q3 — Rat inventory:** Deferred to Phase 2. Rat in Phase 1 has no inventory, cannot carry or steal objects.

**NPC Q4 — Rat bite mechanics:** ALREADY RESOLVED — simple injuries.inflict() on grab, no combat FSM. (See D-COMBAT-NPC-PHASE-SEQUENCING.)

**NPC Q5 — Sound across rooms:** Yes. Creatures with sound_range > 0 emit audible events to adjacent rooms.

**NPC Q6 — Save/load persistence:** Registry-driven. Creatures are objects in the registry; existing save/load handles them identically.

**NPC Q7 — Hear rat in darkness:** Yes — this is a FEATURE. Player hears "skittering claws" before they can see anything. Rat's on_listen provides audio-only presence in darkness.

**Impact:**
- **Flanders:** Rat design finalized; no inventory, permanent death, multi-room sound support
- **Bart:** Creature tick implementation in WAVE-2
- **Nelson:** Test framework covers all 7 resolved areas

---

### D-CREATURES-DIRECTORY: Dedicated Directory for Animate Beings

**Author:** Bart (Architect)  
**Date:** 2026-03-26T20:30Z  
**Status:** ✅ Implemented  
**Category:** Architecture

**Decision:** Create dedicated `src/meta/creatures/` directory for animate beings. Creature definitions live alongside (but separate from) inanimate objects in `src/meta/objects/`.

**Rationale:**
Creatures are not inanimate objects. Separating their definitions clarifies ownership, validation rules, and loader behavior while keeping shared template resolution intact.

**Implementation:**
- Loader scans `meta/objects/` then `meta/creatures/` before room resolution; both feed `base_classes` and `object_sources`
- Meta-lint treats `creatures/` files like objects for template resolution, GUID uniqueness, keywords, and sensory checks
- `rat.lua` moved to `src/meta/creatures/rat.lua`; all path references updated

**Changes:**
- `src/engine/loader/init.lua` — added creatures directory scan
- `meta-lint _detect_kind()` — recognizes creatures vs objects
- 7 test files updated (loader, lint, search, inventory)
- Documentation updated (loader.md, object-design-patterns.md)

**Impact:**
- **Flanders:** Template system now supports creature subtypes; can define creature-specific templates
- **Nelson:** Test paths updated; all test discovery mirrors new structure
- **Moe:** Cellar rat instance unchanged (GUID references auto-resolve)

**Commit:** 2b3e426 (all tests pass)

---

### D-FOOD-SYSTEMS-RESEARCH: Food Systems Research Complete

**Author:** Frink (Researcher)  
**Date:** 2026-03-26T20:30Z  
**Status:** ✅ Complete  
**Category:** Research

**Decision:** Comprehensive food systems research complete. Engine is 80% ready for food systems. Hybrid design model validated across 15+ games.

**Deliverables:**
1. **food-systems-research.md** (92 KB) — 15+ games + real-world food science
2. **food-mechanics-comparison.md** (19 KB) — side-by-side game mechanics matrix
3. **food-design-patterns.md** (37 KB) — 15 software patterns with implementation guide
4. **food-integration-notes.md** (37 KB) — system-by-system integration roadmap

**Key Findings:**
- ✅ FSM engine ready (food states: fresh → spoiling → spoiled)
- ✅ Mutation system (D-14) supports cooking (raw-meat.lua → cooked-meat.lua)
- ✅ Sensory properties (smell, taste, feel) perfect for identification
- ✅ Material system extends to food materials
- ✅ Tool capability system gates cooking (fire_source)
- ✅ Containment system handles preservation (containers slow spoilage)
- ✅ Rat creature already has hunger drive

**Hybrid Design Model:**
- **Valheim:** Food as buff/empowerment (not punishment)
- **Dwarf Fortress:** Emotional system, cooking as preservation
- **NetHack:** Risk/reward sensory testing (taste risky)
- **MUDs:** Non-intrusive, optional engagement
- **Text IF:** Sensory richness, puzzle integration

**Effort Estimate:**
- Phase 1 (Basic Consumables): 8 hours
- Phase 2 (Cooking): 10 hours
- Phase 3 (Spoilage): 14 hours
- Phase 4 (Preservation): 10 hours
- Phase 5 (Recipes + Creatures): 12 hours
- **Total:** 32–46 hours (5 sprints)

**Impact:**
- **Comic Book Guy:** Use research to create food mechanics design document
- **Bart:** Review integration notes, validate FSM/material extensions
- **Flanders:** Food object templates, state definitions
- **Sideshow Bob:** Food-based puzzles (bait, creature feeding, cooking challenges)

**Research files:** `resources/research/food/`

---

### D-CHECKPOINT-AFTER-WAVE: Checkpoint After Every Wave

**Author:** Wayne Berry (via Copilot Coordinator)  
**Date:** 2026-03-26T16:30Z  
**Status:** 🟢 Active  
**Category:** Process

**Decision:** After every wave completes, checkpoint: verify the wave was completed fully and update plan documentation to reflect completion status.

**Requirements:**
1. Mark completed waves in planning documents
2. Note any deviations from plan
3. Update plan as living document (not static)
4. Provide audit trail for walk-away execution

**Impact:**
- **All agents:** Plan documentation stays current and reflects reality
- **Wayne:** Clear visibility into progress and deviations
- **Scribe:** Maintains session logs + orchestration logs per spawn

---

### D-DOOR-ARCHITECTURE: Door/Exit Architecture Direction

**Author:** Bart (Architect)  
**Date:** 2026-07-28  
**Status:** Proposed — awaiting Wayne's decision  
**Category:** Architecture  
**Analysis:** `plans/door-architecture-analysis.md`

**Summary:** After deep analysis of the current hybrid door/exit system against all 11 Core Principles, recommend **Option B: Doors become first-class objects** using a `passage` template and the existing object system (FSM, mutation, sensory, materials).

**Key Finding:** The current exit system is a **parallel object system** — ~322 lines of exit-specific engine code across 8 files duplicating capabilities the object system already provides (FSM, mutation, keyword matching, sensory, effects). Exits satisfy **0 of 11** Core Principles. Full unification satisfies **11 of 11**.

**Proposed Approach:**
1. Create `passage` template for traversable objects
2. Room `exits` tables become thin direction → passage-object-ID references
3. Door state managed by standard FSM (`traversable` flag per state)
4. Door mutations use standard `becomes` code rewrite (D-14 compliant)
5. Remove `becomes_exit`, `exit_matches()`, and exit-specific verb paths
6. Incremental migration: one door at a time, backward-compatible

**Impact:**
- **Net -177 lines** of engine code (remove 252 exit-specific, add 75 passage support)
- Unlocks: multi-step mechanisms, composite doors, material-derived behavior, timed passages, reusable templates
- **4–6 sessions** estimated for full migration

**Decision Points for Wayne:**
1. Go/No-Go on unification
2. Template name: `passage` (recommended) vs `portal` vs `exit`
3. Bidirectional strategy: paired objects (recommended) vs single shared object
4. Migration start: bedroom-hallway door (recommended first candidate)

**Who Should Know:**
- **Flanders** — door object definitions will migrate to passage template pattern
- **Moe** — room exit tables simplify to thin references
- **Smithers** — exit-specific parser/verb code paths will be removed
- **Nelson** — ~15–20 test files need mock context updates during migration
- **Comic Book Guy** — new game design possibilities (drawbridges, mechanisms, magical wards)

---

### D-DOOR-FIRST-CLASS-OBJECTS: Doors Should Be First-Class Objects

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-07-27  
**Status:** PROPOSED — Awaiting Wayne's review  
**Category:** Design  
**Analysis:** `plans/door-design-analysis.md`

**Decision:** Doors, windows, gates, portcullises, and all passage-gating constructs should be **first-class objects** (.lua files with templates, FSM, sensory properties, material inheritance) rather than inline exit-construct tables.

Room exit tables should become thin routing references:
```lua
exits = {
    north = { target = "hallway", door_id = "bedroom-door" }
}
```

All door behavior (state, transitions, mutations, sensory descriptions, material properties) lives in the door object file, not the exit table.

**Rationale:**
1. **Genre precedent:** Zork, Inform 6/7, Hugo all model doors as objects. TADS 3's exit-construct approach is its most criticized design.
2. **Principle alignment:** Door-objects align with Principles 1, 3, 4, 6, 7, 8, 9, and D-14. Exit-constructs violate all of them.
3. **Sensory system:** Game starts at 2 AM in darkness. Players FEEL doors. Exit-constructs don't participate in sensory space.
4. **Scenario coverage:** Door-objects handle all 10 tested scenarios. Exit-constructs fail on 3 (talking doors, remote mechanisms, timed drawbridges).
5. **Designer ergonomics:** Template inheritance + thin exits = less boilerplate than 150-line inline exit definitions.

**Migration Path:**
- **Phase 1 (Now):** Keep existing exits. Document door-object pattern.
- **Phase 2 (Post-playtest):** Create `door` template. Migrate bedroom-door to thin-exit pattern.
- **Phase 3:** Migrate remaining exits. Remove inline mutation code.
- **Phase 4:** All doors are objects. Exits are thin references.

**Affects:**
- **Bart:** Movement handler reads door object state; exit table schema change
- **Flanders:** Creates door template and door object definitions
- **Moe:** Room files simplified — thin exit references replace inline door logic
- **Smithers:** Verb dispatch routes to door objects
- **Nelson:** Regression tests for all door interactions during migration

**Risk:** Primary risk is sync bugs between door object state and exit traversability. Mitigation: door object is SOLE source of truth — exit tables contain only `target` and `door_id`, zero state.

---

### D-LINTER-AUDIT-BASELINE: Meta-lint Audit Baseline Established

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-25  
**Status:** 🟢 Active  
**Category:** Architecture  
**Scope:** All squad members

**Decision:** The meta-lint system baseline is established:
- **0 errors** across all 182 rules
- **152 warnings** (143 are XF-03 keyword collisions)
- **6 info** findings

**Implications:**
1. **Flanders:** 4 new issues assigned (#245–#248) — injury sensory gaps, trap-door description, and 4 missing healing item objects.
2. **All members:** New meta file additions should pass `python scripts/meta-lint/lint.py` with zero new findings before PR.
3. **XF-03 is the dominant issue.** 90% of all findings are keyword collisions. Smithers and Flanders should coordinate on disambiguation (#190).

**Affected Issues:**
- #245, #246, #247, #248 (new)
- #190, #195, #196 (existing, unchanged)

---

### D-LINTER-PHASE1: Meta-Check Rule Registry & Configuration

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-30  
**Status:** Implemented  
**Category:** Architecture  
**Branch:** squad/linter-improvements

**Decision:** Meta-check now has three new architectural layers:

**1. Rule Registry** (`scripts/meta-check/rule_registry.py`)
Every rule the linter can emit is registered with metadata:
- `severity`: default error/warning/info level
- `fixable`: whether the violation can be auto-fixed
- `fix_safety`: "safe" (idempotent) or "unsafe" (needs human review)
- `category`: grouping key for bulk enable/disable
- `description`: human-readable description

**110+ rules registered** across 13 categories.

**2. Per-Rule Configuration** (`.meta-check.json`)
Teams can customize which rules run via JSON config file with rule overrides and category disables.

**3. Safe/Unsafe Fix Classification**
JSON output includes `fixable` and `fix_safety` fields per violation, plus summary counts.

**4. Rule Gap Fixes**
- **XF-03:** Smart keyword collision filtering
- **MD-19:** Upgraded to conflict detection with actual values
- **XR-05b:** New rule — warns when objects inherit generic material without override

**Who Should Know:**
- **Nelson/Lisa (QA):** New test file at `test/meta-check/test_phase1.py` (29 tests)
- **Flanders (Objects):** XR-05b may flag objects missing material overrides
- **Gil (CI):** JSON output format bumped to v2.0 with `fixable`/`fix_safety` fields
- **All:** Use `--list-rules` to see all rules, `--init-config` to generate default config

---

### D-LINTER-PHASE2: GUID/EXIT Validation

**Author:** Bart (Architecture Lead)  
**Date:** 2026-07-29  
**Status:** Active  
**Category:** Architecture

**What Changed:** Added 5 new lint rules in Phase 2:

| Rule | Severity | Category | Description |
|------|----------|----------|-------------|
| GUID-01 | error | guid-xref | Room instance type_id must reference a known object GUID |
| GUID-02 | warning | guid-xref | Orphan object not referenced by any room instance |
| GUID-03 | error | guid-xref | Duplicate instance id within same room |
| EXIT-01 | error | exit | Exit target must reference a valid room |
| EXIT-02 | warning | exit | Bidirectional exit mismatch |

**Bug Fix:** `_detect_kind()` now recognizes `src/meta/rooms/` directory (was only checking `src/meta/world/`).

**Who This Affects:**
- **Moe:** GUID-02 reports 21 orphan objects. Review which are intentional (mutation targets) vs need placement.
- **Flanders:** GUID-01 validates every type_id in room instances.
- **Nelson:** 20 new tests in `test/meta-check/test_phase2.py`
- **All content authors:** EXIT-01 flags exits to non-existent rooms; can suppress via config if intentional.

---

### D-LINTER-PHASE3: Squad Routing & Incremental Caching

**Author:** Bart (Architecture Lead)  
**Date:** 2026-07-29  
**Status:** Active  
**Category:** Architecture  
**Branch:** squad/linter-phase3

**What Changed:**

**Squad Routing:** Every linter violation now includes an `owner` field identifying which squad member should fix it. Default routing table:

| Pattern | Owner |
|---------|-------|
| S-*, PARSE-*, G-*, FSM-*, TR-*, SN-*, TD-*, GUID-* | Bart |
| INJ-*, MD-*, MAT-*, CREATURE-* | Flanders |
| RM-* | Moe |
| LV-* | Comic Book Guy |
| XF-*, XR-* | Smithers |
| EXIT-* | Sideshow Bob |

Overridable via `squad_routing` section in `.meta-check.json`.

**Incremental Caching:** The linter caches per-file violations keyed by SHA-256 hash. Cross-file rules (XF/XR/GUID/EXIT/LV-40) always re-run. Use `--no-cache` for full re-scan.

**Who Needs to Know:**
- **Coordinator:** Use `--format json` output to auto-route violations via `owner` field
- **Smithers:** Owns 151/183 violations (143 XF-03 collisions) — review keyword allowlist
- **Sideshow Bob:** Owns 4 EXIT-01 errors
- **All agents:** Text output shows `[owner]` per violation; use `--by-owner` for grouped view
- **Gil:** Cache file `.meta-lint-cache.json` is gitignored

**Version:** meta_check_version bumped from 2.0 → 3.0.

---

### D-NPC-COMBAT-IMPL-PLAN: Unified NPC+Combat Implementation Plan

**Author:** Bart (Architect)  
**Date:** 2026-07-28  
**Status:** 🟢 Active  
**Category:** Architecture

**Decision:** Created unified implementation plan at `plans/npc-combat-implementation-plan.md` merging NPC Phase 1 and Combat Phase 1 into a 6-wave, 6-gate execution pipeline with explicit file ownership and TDD gates.

**Key Architectural Decisions:**
1. **NPC Phase 1 ships before Combat Phase 1** — creature autonomy proven before adding combat complexity
2. **Creature tick integration point:** After fire propagation, before injury tick in `loop/init.lua`
3. **Stimulus system:** Simple event queue in `engine/creatures/init.lua`, consumed by creature tick
4. **Combat engine:** Single `resolve_exchange()` function handles all combatants generically
5. **No file conflicts:** Explicit ownership map per wave
6. **Test runner expansion:** `test/creatures/` and `test/combat/` directories added incrementally

**Impact:**
- **Flanders:** Creates creature template, rat, flesh material (WAVE-1); retrofits body_tree + tissue materials (WAVE-4)
- **Bart:** Builds creature tick engine (WAVE-2), stimulus emission (WAVE-3), combat FSM (WAVE-5), combat integration (WAVE-6)
- **Smithers:** Implements catch/chase/attack verbs (WAVE-3), combat verb extensions (WAVE-6)
- **Moe:** Places rat in room (WAVE-3)
- **Nelson:** TDD test suite at every wave; LLM walkthroughs at GATE-3 and GATE-6
- **Coordinator:** Autonomous wave→gate→wave execution loop; Wayne check-in at GATE-3 and GATE-6 only

---

### D-PLAN-REVIEW-FIXES: NPC+Combat Plan Review — All 16 Issues Fixed

**Author:** Bart (Architect)  
**Date:** 2026-07-28  
**Status:** 🟢 Active  
**Category:** Process

**Decision:** Applied all 8 blockers and 8 concerns from team review to `plans/npc-combat-implementation-plan.md`.

**Blockers Applied:**
- B1: Hybrid stance combat added (WAVE-5.5)
- B2: Documentation deliverables added (Brockman, WAVE-3 & WAVE-6)
- B3: Player model file path verified (src/main.lua lines ~305–324)
- B4: Test dirs registered in run-tests.lua (WAVE-0)
- B5: Creature tick perf budget added (<50ms, 5 creatures)
- B6: Material registry test clarified (explicit engine.materials.get() call)
- B7: Distant-room stimulus boundary test added (WAVE-2 test case #13)
- B8: NPC docs assigned to Brockman

**Concerns Applied:**
- C1: Gate failure protocol added (Section 12)
- C2: Commit/push points specified (after every gate)
- C3: Combat sub-loop input clarified (headless auto-selects balanced)
- C4: verbs/combat.lua ownership clarified
- C5: Rat spawn location specified (cellar, top-level)
- C6: LLM determinism via seeding (math.randomseed(42))
- C7: Narration variety assertion added (WAVE-5 test)
- C8: Escalation threshold set to 1x failure for Phase 1

**Additional Changes:**
- **combat/narration.lua split:** Changed from optional to REQUIRED
- **Nelson as gate signer:** Added to GATE-3 and GATE-6 reviewer lists

**Impact:** All agents — plan is now single source of truth. Re-read before starting work.

---

### D-SWIMLANE-SQUAD-ARCHITECTURE: Swimlanes as Enforceable Queues

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-25T15:00:00Z  
**Status:** Implemented  
**Category:** Process

**Decision:** Swimlanes are the Squad's operational contract — **enforceable queues, not visualizations**. Each swimlane is owned by exactly one agent, maps to a `squad:{member}` label, and drives work autonomously.

**D-BLOCKED-SWIMLANE:** Issues that cannot proceed without human action move to "Blocked / Needs Human" lane with mandatory status emission:
1. Agent identifies blocker
2. Agent moves issue to blocked lane
3. Agent emits status: what is blocked, why, what is needed, who acts
4. Agent does NOT continue work until blocker is resolved

**D-RALPH-PULL-INTEGRATION:** Ralph (work monitor) watches for stalled work but respects autonomy:
1. Monitor: Ralph detects issues in Ready > N days without pickup
2. Spawn: Ralph can spawn agent to review swimlane
3. Respect: Ralph checks for active PRs before spawning
4. No double-spawn: If agent has work in progress, Ralph does not spawn
5. Escalate: If no response after spawn, Ralph flags for Lead review

**D-HUMAN-BOARD-BOUNDARIES:**
- **Human responsibilities:** Define swimlane structure, set review criteria, triage issues, unblock agents, close decision loops
- **Squad responsibilities:** Move cards between lanes, pull work, open PRs, emit status, move to Done

**Anti-patterns to prevent:**
- ❌ Humans manually dragging cards (except triage/review)
- ❌ Squad agents bypassing swimlane protocol
- ❌ Swimlanes used as passive visualization
- ❌ "Pending" states without clarity

---

### D-WEAR-HAND-DEFENSIVE-SWEEP: Wear Handler Defensive Sweep

**Author:** Bart (Architect)  
**Date:** 2026-03-31  
**Status:** Implemented  
**Category:** Bugfix  
**Issue:** #180

**Decision:** When moving an item from hand to worn, the wear handler now clears **all** hand slots holding that item (by ID match), not just the single `hand_slot` discovered. The take handler now blocks picking up worn items (checking `ctx.player.worn`).

**Rationale:** Wayne's playtest showed a spittoon in both left hand AND worn simultaneously. The defensive sweep is O(2) — zero performance cost, maximal safety. The take handler's Bug #53 guard only checked hands for duplicates, not the worn list.

**Pattern:** **Defensive sweep over targeted clear** — when mutating player state (hands ↔ worn ↔ bags), always sweep all related slots by ID rather than relying on a single index.

**Impact:**
- **Smithers:** No parser changes. Fix is in verb handlers.
- **Nelson:** 7 new integration tests in `test/integration/test-wear-hand-integration.lua`
- **Flanders:** No object changes. Wear table contract unchanged.
- **Gil:** Web adapter uses same verb handlers — fix applies to both paths.

---

### D-PARSER-BM25-PHASE1: BM25 Scoring & Synonym Expansion for Tier 2

**Author:** Smithers (Parser/UI Engineer)  
**Date:** 2026-07-20  
**Status:** Implemented  
**Category:** Parser  
**Branch:** squad/parser-bm25-phase1

**Decision:** Replaced Jaccard similarity with BM25 (Okapi) scoring as the default Tier 2 matching algorithm. Added synonym expansion table and expanded stop word list. All changes A/B-proven.

**What Changed:**
1. **Scoring mode flag:** `embedding_matcher.scoring_mode` defaults to `"bm25"`. Set to `"jaccard"` to revert.
2. **BM25 scoring:** IDF-weighted term frequency (k1=1.2, b=0.5). IDF table precomputed at build time.
3. **Synonym expansion:** 60+ verb synonyms map player words to canonical verbs before matching.
4. **Stop words expanded:** 21 → 60+ common English filler words removed before matching.
5. **Dual threshold:** `THRESHOLD_BM25 = 3.00` / `THRESHOLD_JACCARD = 0.40`
6. **Typo correction tightened:** 5-char words now require distance ≤1 (was ≤2)

**A/B Results:**

| Algorithm | Correct | Accuracy | False Positives | False Negatives |
|-----------|---------|----------|-----------------|-----------------|
| Jaccard (baseline) | 47/60 | 78.3% | 0 | 13 |
| BM25 + Synonyms | 60/60 | 100.0% | 0 | 0 |
| **Delta** | **+13** | **+21.7pp** | **0** | **-13** |

**Files Created/Modified:**
- `src/engine/parser/bm25_data.lua` (new, auto-generated)
- `src/engine/parser/synonym_table.lua` (new)
- `src/engine/parser/embedding_matcher.lua` (modified)
- `src/engine/parser/init.lua` (modified)
- `scripts/build-idf-table.py` (new)
- `test/parser/test-tier2-benchmark.lua` (new)

**Impact on Other Agents:**
- **Nelson (QA):** New benchmark at `test/parser/test-tier2-benchmark.lua`. All 137 existing tests pass.
- **Gil (Web):** `bm25_data.lua` and `synonym_table.lua` are pure Lua — Fengari compatible. Web build needs regeneration.
- **Bart (Architecture):** No engine architecture changes. BM25/synonyms localized to embedding_matcher.
- **Frink (Research):** Phase 1 complete. Phase 2 (soft cosine, inverted index) can build on this foundation.

---

### D-AUTO-IGNITE-TIMER-AUDIT: Direct State Assignment Timer Audit

**Author:** Nelson (QA)  
**Date:** 2026-07-27  
**Status:** Proposed  
**Category:** Architecture  
**Issue:** #178

**Decision:** Any code path that changes an object's `_state` field directly (bypassing `fsm.transition()`) MUST also call `fsm.start_timer(registry, obj_id)` if the new state has `timed_events`.

**Context:** Bug #178 (lit match never burns out) — `auto_ignite()` in `src/engine/verbs/fire.lua` sets `_state = "lit"` directly without starting the FSM timer.

**Known Direct State Assignments:**
1. **`fire.lua` — `auto_ignite()`** — confirmed bug, no timer started
2. **`meta.lua` — `set` handler** — clock puzzles, may not need timers
3. **`helpers.lua` — `detach_part()` / `reattach_part()`** — composite parts

**Who Should Know:**
- **Bart:** FSM architecture owner. Should review whether `apply_state()` should auto-call `start_timer()`
- **Smithers:** Owns verb handlers where direct assignments exist
- **Flanders:** Any objects with timed states affected by these paths

---

### D-COMBAT-RESEARCH: Combat System Research Complete

**Author:** Frink (Research Scientist)  
**Date:** 2026-03-25  
**Status:** Research Complete — awaiting design decisions  
**Category:** Research

**Summary:** Completed comprehensive combat research across 5 domains (MUDs, competitive games, board games, MTG, Dwarf Fortress). All findings in `resources/research/combat/` (6 documents, ~86KB).

**Key Recommendations:**
1. **Adopt DF's material-physics model** for damage resolution. Our 17+ material registry needs 4 combat properties (shear resistance, impact resistance, density, max edge). Damage emerges from material interaction.
2. **Deterministic combat with bounded variance.** Steel cuts flesh. Always. Variance comes from hit location (random, weighted) and player choice.
3. **Unified combatant interface.** One `resolve_combat()` function for all. No combatant-type-specific code (Principle 8).
4. **Creatures declare combat as metadata.** Natural weapons, body zones, armor, behavior — all in creature's `.lua` file.
5. **MTG-inspired turn structure.** Initiative → attacker acts → defender responds → resolve → narrate. Player always gets response choice.

**Who Should Know:**
- **Bart:** Design combat resolution module (`src/engine/combat/`)
- **Flanders:** Creature objects need `combat` metadata with natural weapons, body zones, behavior
- **Moe:** Rooms may need combat-relevant spatial properties
- **Smithers:** Combat verbs needed (attack, block, dodge, flee) + combat-state response prompts
- **Comic Book Guy:** Design decisions needed on Phase 1 scope
- **Nelson:** Combat test framework; DF-style material interactions are highly testable

**Open Decisions for Wayne/Team:**
1. **Deterministic or probabilistic?** (Research recommends: primarily deterministic)
2. **DF detail level?** (Research recommends: 4–6 body zones, not 200 parts)
3. **Phase 1 scope?** (Research recommends: single rat combat with material comparison, body zones)

---

### D-PRIME-DIRECTIVE-TIERS-1-5: Prime Directive Tiers 1–5 Design Spec

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-03-25  
**Issue:** #106  
**Status:** Design Complete  
**Category:** Design  
**Deliverable:** `docs/design/prime-directive-tiers.md`

**Summary:** Designed the 5-tier parser Prime Directive system from the player's perspective. This is the governing design document for all parser work.

**Priority Order:** Tier 2 (Error Messages) > Tier 5 (Fuzzy) > Tier 4 (Context) > Tier 1 (Questions) > Tier 3 (Idioms)

Error messages are #1 because they're the safety net. Every player will hit error messages; good ones teach, bad ones frustrate.

**Error Message Categories:** Five distinct categories with own response strategy:
1. Unknown verb — narrator bemused but helpful
2. Unknown noun — context-aware, never reveals hidden objects
3. Impossible action — explain why using material properties
4. Missing prerequisite — hint without solving puzzles
5. Ambiguous target — use location and properties to disambiguate

**Fuzzy Confidence Tiers:**
- Score ≥5: Execute immediately
- Score 3–4: Execute with narration "(Taking the *brass key*...)"
- Score 2: Confirm "Did you mean the *candle*?"
- Score ≤1: Fall through to error

**Idiom Library Cap:** Target 80–120 entries. Beyond that, invest in Tier 2 embedding matching.

**"OOPS" Command:** When parser fails on unrecognized noun, store the input. If player types "oops {word}", replace and re-parse. ~20 lines Lua, enormous UX value.

**Disambiguation Memory:** After asking "Which do you mean?", store option list for 3 commands.

**Who Should Know:**
- **Smithers:** Implementation roadmap. Start with Tier 2 (error messages).
- **Nelson:** Test coverage for each tier. Error message regression tests.
- **Flanders:** Objects need good `keywords` (including color terms) for Tier 5 fuzzy matching
- **Moe:** Room descriptions use consistent object naming for Tier 5 partial matching
- **Brockman:** Update parser architecture docs to reference this design spec

---

### D-DOCS-REFLECT-CURRENT-STATE: Documentation Reflects Current System State

**Author:** Wayne Berry (via Copilot)  
**Date:** 2026-03-25T12:35:00Z  
**Status:** 🟢 Active  
**Category:** Process

**Decision:** Documentation files represent the CURRENT state of the system, not historical analysis snapshots. Analysis files should be cleaned up and converted into living documentation. Phase plans (like the portal plan) should include a phase for converting analysis files into authoritative docs.

**Why:** Docs are authoritative current-state references, not historical analysis artifacts.

**Impact:** When writing plans or analysis documents, earmark conversion-to-docs as a phase task.

---
