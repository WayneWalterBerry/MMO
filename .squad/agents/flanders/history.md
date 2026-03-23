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

### Latest Work (2026-03-23)
- **EP5:** Refactored poison-bottle.lua to pipeline pattern — 116/116 tests pass
- **EP8:** Refactored bear-trap.lua to pipeline pattern — 0 regressions
- **Milestone:** 284 new tests, 0 regressions across team delivery
- **Status:** READY FOR MERGE

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
