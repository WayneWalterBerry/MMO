# Flanders — History

*Last comprehensive training: 2026-07-20*

---

## Core Context

**Project:** MMO text adventure engine in pure Lua (REPL-based, lua src/main.lua)
**Owner:** Wayne "Effe" Berry
**Role:** Object Designer / Builder — I design and implement all real-world game objects as .lua files in src/meta/objects/.

### Team Relationships
- **Bart** = Engine Architect — builds FSM engine, verbs, parser, containment system. My objects DECLARE behavior; Bart's engine EXECUTES it.
- **CBG (Comic Book Guy)** = Game Designer — audits objects for design quality, proposes mutate opportunities, writes design docs. He reviews my work.
- **Nelson** = Test Engineer — tests objects in the engine, catches regressions.
- **Frink** = Researcher — provides CS foundations (ECS, Harel statecharts, DF architecture analysis).
- **Brockman** = Documentation — writes architecture docs.
- **Wayne** = Owner — sets directives, approves designs. References Dwarf Fortress as the gold standard.

### Key Directives
- Dwarf Fortress property-bag architecture is the reference model (D-DF-ARCHITECTURE)
- All mutation is in-memory only; .lua files on disk never change at runtime
- No LLM at runtime (D-19) — everything deterministic and offline
- Each command tick = 360 game seconds (10 ticks per game hour)
- Game starts at hour 2 (2 AM), darkness is default starting condition

---

## Current Sprint: Effects Pipeline (EP1-EP10) ✅ COMPLETE

### Latest Work (2026-07-27)

### Phase D2: Brass Spittoon Object — IMPLEMENTED ✅

**Task:** Create `src/meta/objects/brass-spittoon.lua` per daily plan Phase D2.

**What Was Built:**
- GUID `{b763fdf9-f7d2-4eac-8952-7c03771c5013}` (Windows-generated)
- Material: `brass` (from registry — hardness 6, fragility 0.1, density 8500)
- Container: capacity 2, holds small items
- Wearable helmet: head slot, outer layer, coverage 0.7, fit makeshift, armor 2
- `is_helmet = true`, `reduces_unconsciousness = 1`
- FSM: clean → stained → dented (cosmetic degradation only, brass never shatters)
- Transitions: use/spit (clean→stained), dent/kick/hit/strike (→dented)
- Full sensory: on_feel, on_smell, on_listen, on_taste, on_smell_worn
- Mirror/appearance: worn_description for reflection
- Keywords: spittoon, brass spittoon, brass bowl, cuspidor, spit bowl, helmet, improvised helmet
- Weight: 4 (appropriate for brass density)
- Design doc already existed (CBG authored `docs/objects/brass-spittoon.md`), staged with commit

**Pattern:** Follows chamber-pot.lua for wearable helmet architecture. Key differences: brass material (dents, doesn't shatter), higher armor (2 vs 1), heavier weight (4 vs 3), FSM degradation states instead of shatter mutation.

### Phase B1: Object-Material Audit — COMPLETE ✅

**Task:** Audit all objects for material fields, fix missing ones, validate against registry.

**Results:**
- **82 objects checked** in `src/meta/objects/`
- **81 had valid material fields** — all references exist in `src/engine/materials/init.lua`
- **1 missing: ivy.lua** — added `material = "plant"`
- **New material added:** `plant` to materials registry (density 500, hardness 2, fragility 0.3, flammability 0.5, flexibility 0.8)
- **rat.lua:** Already removed per D-INANIMATE decision — no action needed
- **0 mismatches found** — all material names correctly reference existing registry entries
- **0 misspellings found** — all material strings valid

**Test Results:** 78/78 test files pass, 0 regressions.

### Previous Work (2026-03-24)

### Manifest Completion Tasks
- **#79-#80:** Accessibility audit (closed drawer) and put routing verification
  - Examined FSM state transitions for nightstand drawer
  - Verified put routing to correct surface layer
  - Result: ✅ 9 tests pass, no changes needed (engine already correct)
  
- **Effects Pipeline Refactors (EP5 & EP8):**
  - **EP5:** poison-bottle.lua → pipeline pattern (116/116 tests)
  - **EP8:** bear-trap.lua → pipeline pattern (168/168 tests)
  - Total: 284 new tests, 0 regressions

**Status:** ✅ MANIFEST COMPLETION READY FOR MERGE

## Archives

- `history-archive-2026-03-20T22-40Z-flanders.md` — Full archive (2026-03-18 to 2026-03-20T22:40Z): initial object design, FSM patterns, effects pipeline design, foundational systems

### Prior Work (2026-03-23)
- **EP5:** Refactored poison-bottle.lua to pipeline pattern — 116/116 tests pass
- **EP8:** Refactored bear-trap.lua to pipeline pattern — 0 regressions
- **Milestone:** 284 new tests, 0 regressions across team delivery

### Team Coordination
- Nelson verified poison-bottle (116/116) and authored bear-trap tests (168/168)
- Marge gate-approved EP4, noted effects.lua unit test gap
- Bart updated architecture docs v2.0
- All deliverables documented in `.squad/orchestration-log/2026-03-23T17-20Z-*.md`

---

## Archived Sessions Summary (Cumulative Achievements)

This section summarizes 50+ prior sessions covering object design, FSM architecture, injury systems, and Level 1 object specification. For detailed session logs, see .squad/log/.

**Key Accomplishments:**
- Designed & built 37+ Level 1 objects across 5 rooms
- Implemented 5 injury templates (minor-cut, bleeding, bruised, burn, poisoned-nightshade)
- Built bandage FSM treatment object with injury targeting architecture
- Standardized 78 objects with proper GUID format
- Created comprehensive object & injury documentation (45+ design docs)
- Established patterns: composite objects, nested containers, FSM injury progression
- Built poison-bottle upgrade with structured effects & readable parts

**Object Architecture Mastered:**
- Code-derived mutable objects (Principle 1) — objects are live Lua tables from immutable source
- FSM behavior (Principle 3) — all state transitions declared in transitions table
- Composite objects (Principle 4) — single file defines parent + nested inner objects
- Sensory space (Principle 6) — state determines perception (dark ≠ lit, blind ≠ seeing)
- Engine executes metadata (Principle 8) — objects are pure data, engine is generic interpreter

**Injury System Architecture:**
- 7 injury types with self-healing, worsening, and treatment mechanics
- Dual-binding injury targeting (injury ↔ treatment item linkage)
- Healing interactions per injury type (bandage, poultice, antidote, etc.)
- Severity-based state progression (active → worsened → critical → fatal/healed)
- Restriction system (injuries restrict capabilities: climb, run, fight)

**Materials & Templates:**
- 4 new materials needed in registry: stone, silver, hemp, bone
- Template system: container, small-item, furniture, sheet (all documented)
- Creature objects as pure FSM (rat pattern: hidden→visible→fleeing→gone)

---

## Learnings

### 2026-03-23: Wave2 — Decision Documentation & Cross-Agent Propagation

**Wave2 Spawn:** Scribe merged all decision documents into decisions.md

**Decisions Documented:**
- **D-INJURY001:** Structured effect tables over legacy strings (impacts Bart's effect processing pipeline)
- **D-INJURY002:** Crushing wound as new injury type (distinct from bleeding/bruised — hybrid immediate+ongoing damage)
- **D-INJURY003:** Label as non-detachable readable part (enables proper ead label verb support via composite object system)
- **D-INJURY004:** Bear trap disarm uses guard function (runtime context checks for skill validation, not just tool requirements)
- **D-INJURY005:** Bear trap self-transitions for safe take (enables custom messages and property mutations in safe states)

**Cross-Agent Context:**
- Marge verified all object implementations and injured-system patterns
- Smithers' parser handles complex multi-step interactions (disarm requires lockpicking + thin tool)
- Bart will integrate structured effects into effect processing pipeline
- All 5 injury-system decisions are now canonical and merge-ready

**Impact Summary:**
- 3 new objects + 1 new injury type now documented
- Effect pipeline ready for Bart's integration phase
- Injury targeting architecture documented in decisions
- Ready for cross-team execution phase

### 2026-03-24: Afternoon Wave — Objects Are Inanimate + Deep Nesting Complete

**Afternoon Wave Decisions Merged:**
- **D-INANIMATE:** Objects are inanimate; creatures are future work
  - Removed rat object from meta/objects/
  - Removed all rat references (storage-cellar, web dist)
  - Added core principle documentation
  - Clean, zero broken references — IMPLEMENTED ✅

- **D-AUDIT-OBJECTS:** Effects Pipeline Compatibility Audit (Bart)
  - 79 objects inventoried: 2 pipeline-routed, 3 broken, 74 passive
  - Knife/glass-shard/silver-dagger missing `effects_pipeline = true`
  - Migration priority: knife (P1), glass-shard (P1), silver-dagger (P2)
  - ~4.5 hours total work to unblock #50

- **D-NEW-OBJECTS-PUZZLES:** Objects needed for puzzles 020–031 (Bob)
  - Priority 1: wax-written-scroll, charcoal, bread-loaf, bait-meat, hand-mirror (using existing patterns)
  - Priority 2: wooden-barricade, pressure-platform, portcullis, sealed-wall-section, light-beam (need engine features)
  - Ready to implement Priority 1 objects now

- **D-WAYNE-REGRESSION-TESTS:** Every bug fix MUST include regression test
  - Rationale: nightstand search broke 3+ times
  - Enforcement: process bug if test missing
  - Impact: Nelson's audit now has all fixes locked with tests

**Deep Nesting Refactor Complete:**
- 6 Level 1 rooms converted to deep-nested furniture
- Pattern: furniture → drawers/slots → contents (3+ levels)
- All `location=` fields removed
- Play-test verified: sensory works at all depths
- Establishes canonical architecture for Level 1 discovery chains

### 2026-07-26: EP5 — Poison Bottle Effects Pipeline Refactor

**Task:** Refactor poison-bottle.lua to route through the unified Effects Pipeline (D-EFFECTS-PIPELINE).

**What Changed:**
- Added `effects_pipeline = true` flag — signals engine to use `effects.process()` for all effect declarations
- Added `pipeline_effects` array on drink transition — full atomic pipeline chain (inflict_injury + mutate effects) alongside backward-compatible `effect` + `mutate` blocks
- Marked `on_taste_effect` as `pipeline_routed = true` — confirms it's consumed by `effects.process()` in the taste verb handler
- Added GOAP `warns` hints on drink and taste prerequisites per D-EFFECTS-PIPELINE §3.6
- Updated file header to reference pipeline routing and decision IDs

**Key Constraint:** 116 regression tests (Nelson) lock down the data structure. Tests access `drink_trans.effect.type` directly (single table format), so `effect` must remain a single structured table — cannot convert to array. `effects.normalize()` handles this correctly (wraps single table in array).

**Pipeline Integration Points (engine side, already wired by Bart/Smithers):**
- Drink verb handler: `effects.process(trans.effect, ctx)` at verbs/init.lua:4829
- Taste verb handler: `effects.process(obj.on_taste_effect, ctx)` at verbs/init.lua:2148
- FSM mutations: still via `apply_mutations(obj, trans.mutate)` — FSM engine handles these independently

**Backward Compatibility Strategy:**
- `effect` (single table) + `mutate` block preserved for current FSM engine
- `pipeline_effects` (array) available for future atomic processing
- `effects.normalize()` handles both formats transparently

**Result:** 116/116 tests pass. Zero regressions. Committed and pushed.

### 2026-07-26: EP8 — Bear Trap Effects Pipeline Refactor

**Task:** Refactor bear-trap.lua to route through the unified Effects Pipeline (D-EFFECTS-PIPELINE), following the poison-bottle pattern from EP5.

**What Changed:**
- Added `effects_pipeline = true` flag — signals engine to use `effects.process()` for all effect declarations
- Added `pipeline_effects` arrays on take and touch transitions (set → triggered) — full atomic pipeline chains: inflict_injury + narrate + mutate effects alongside backward-compatible `effect` + `mutate` blocks
- Marked `on_feel_effect` as `pipeline_routed = true` — confirms it's consumed by `effects.process()` in the feel verb handler
- Added GOAP `warns` hints on take, touch, and feel prerequisites per D-EFFECTS-PIPELINE §3.6
- Updated file header to reference pipeline routing, decision IDs (D-EFFECTS-PIPELINE, D-INJURY001, D-INJURY002), and effect routing paths

**Key Constraint:** Same as EP5 — existing tests access `trans.effect.type` directly (single table format), so `effect` must remain a single structured table. `effects.normalize()` handles this correctly (wraps single table in array).

**Pipeline Integration Points (engine side, already wired by Bart/Smithers):**
- Take verb handler: `effects.process(trans.effect, ctx)` — contact trigger on armed trap
- Touch verb handler: `effects.process(trans.effect, ctx)` — contact trigger on armed trap
- Feel verb handler: `effects.process(state.on_feel_effect, ctx)` — sensory contact injury
- Disarm: guard function blocks FSM transition before pipeline processing (no change needed)
- FSM mutations: still via `apply_mutations(obj, trans.mutate)` — FSM engine handles independently

**Backward Compatibility Strategy:**
- `effect` (single table) + `mutate` block preserved for current FSM engine
- `pipeline_effects` (array) available for future atomic processing
- `effects.normalize()` handles both formats transparently
- Safe-take transitions (triggered/disarmed states) untouched — no effects to pipeline

**Result:** 45/45 test files pass, 0 failures. Zero regressions. Committed f872ed3 and pushed.

### 2026-07-26: EP-WEAPONS — Knife, Glass-Shard, Silver-Dagger Pipeline Migration

**Task:** Migrate 3 weapon objects to effects pipeline (#50, #55). Bart's audit found they had injury verbs but lacked `effects_pipeline = true`, causing stab/cut/hit to fail silently.

**Objects Migrated:**

1. **knife.lua** — Added `effects_pipeline = true`, `pipeline_effects` on `on_stab` (bleeding, 5dmg) and `on_cut` (minor-cut, 3dmg). Added GOAP warns hints. Added file header with effect routing map.

2. **glass-shard.lua** — Added `effects_pipeline = true`, `pipeline_effects` on `on_cut` (minor-cut, 3dmg). Upgraded `on_feel_effect` from bare string `"cut"` to structured pipeline table (`inflict_injury`, minor-cut, 1dmg, pipeline_routed=true). Added GOAP warns hints.

3. **silver-dagger.lua** — Added `effects_pipeline = true`, `pipeline_effects` on `on_stab` (bleeding, 8dmg), `on_cut` (minor-cut, 4dmg), `on_slash` (bleeding, 6dmg). Added GOAP warns hints. Added file header with effect routing map.

**Injury Types Verified:** All referenced types (`bleeding`, `minor-cut`) exist in `src/meta/injuries/`. No new injury types needed.

**Backward Compatibility:** All legacy fields (`damage`, `injury_type`, `description`, `pain_description`, `self_damage`) preserved on every verb block. `effects.normalize()` handles both old single-table format and new pipeline_effects arrays.

**Regression Tests:** 74 new tests in `test/injuries/test-weapon-pipeline.lua`:
- Data structure validation (pipeline flag, pipeline_effects arrays, source fields)
- Backward compat checks (legacy fields preserved)
- GOAP prerequisites present
- Functional: stab self with knife → bleeding injury
- Functional: cut self with glass shard → minor-cut injury
- Functional: stab/slash self with silver dagger → bleeding
- Functional: injuries appear in `injuries` list output
- Injury type definitions loadable from disk

**Result:** 51/51 test files pass (74 new tests, 0 regressions). Committed in 7d1733b and pushed.

### 2026-07-27: Chamber Pot — Wearable as Improvised Helmet (Issue #54)

**Task:** Make the ceramic chamber pot wearable on the head as an improvised helmet with minimal protection.

**What Changed in chamber-pot.lua:**
- Added `wear_slot = "head"` (top-level) — engine helmet detection in `appearance.lua` and concussion system
- Added `is_helmet = true` (top-level) — belt-and-suspenders helmet detection
- Added `reduces_unconsciousness = 1` (top-level) — reduces KO duration by 1 turn on head hits
- Added `appearance = { worn_description = "A ceramic chamber pot sits absurdly atop your head." }` — consumed by `render_head()` in `engine/player/appearance.lua`
- Added `on_smell_worn` — worn-state smell feedback metadata for future ambient smell system
- Added helmet-related keywords: "helmet", "head pot", "improvised helmet"
- Added file header comment with doc and issue references

**Engine Integration Points (no engine changes needed):**
- Wear verb: `wear.provides_armor = 1` + `wear.wear_quality = "makeshift"` triggers existing comedic narration at verbs/init.lua:4636
- Appearance/mirror: `appearance.worn_description` read by `engine/player/appearance.lua:114` in `render_head()`
- Concussion reduction: `reduces_unconsciousness` read at `engine/verbs/init.lua:3841` when head hit detected
- Slot conflict: standard slot/layer conflict system blocks wearing pot if outer headgear already equipped (engine/verbs/init.lua:4576-4611)

**Design Doc Updated:** `docs/objects/chamber-pot.md` — full wearable specification, armor stats, appearance/mirror description, Wayne's design intent (real-world object creativity).

**Result:** 50/50 test files pass, 0 failures. Zero regressions. Committed 011094d and pushed.

### 2026-07-27: Chest — Two-Handed Oak Container (Issue from CBG Design Doc)

**Task:** Implement `chest.lua` from CBG's complete design doc at `docs/objects/chest.md`.

**What Was Built in chest.lua:**
- GUID `{6cf2ab69-60e5-4c14-9b3a-c559b6037cf4}` (Windows-generated)
- Material: `oak` (from material registry, Principle 9 satisfied)
- `size = 5`, `weight = 20`, `portable = true`, `hands_required = 2`
- FSM: `closed` (default) ↔ `open` — two transitions with narration from CBG's design
- Container: `capacity = 8`, `max_item_size = 3`, `weight_capacity = 30`
- Sensory gating: `accessible = false` (closed) / `accessible = true` (open)
- Per-state sensory properties: `on_look` (function with contents listing), `on_feel` (function with contents detection in open state), `on_smell`, `on_listen`
- `mutate` on transitions: `keywords = { add = "open" }` / `keywords = { remove = "open" }`
- Categories: container, furniture, wooden
- Keywords: chest, trunk, storage, wooden chest, heavy chest, treasure chest

**Pattern:** Follows drawer.lua exactly — same FSM + container + sensory gating architecture. Key differences: larger capacity (8 vs 2), heavier (20 vs 2), standalone (no `reattach_to`), richer narration per CBG's design.

**Design Doc Updated:** `docs/objects/chest.md` — status changed from "Design complete; implementation pending" to "🟢 In Game — src/meta/objects/chest.lua". Added implementation credit.

**Result:** 74/74 test files pass, 0 regressions. Committed 57c38b4 and pushed.

---

## CROSS-AGENT UPDATES (2026-03-24T12:41:24Z Spawn Orchestration)

### D-PLANT-MATERIAL Decision Logged
- **Status:** Implemented
- **Material:** `plant` added to registry
- **Properties:** 500 density, 280 ignition_point, 0.8 flexibility, 0.5 flammability, etc.
- **Use Case:** ivy.lua now has `material = "plant"` (previously missing in audit)
- **Future:** Botanical objects (moss, hedges, vines) can reference without engine changes
- **Cross-Team:** Nelson's material audit validation test should include plant material check
