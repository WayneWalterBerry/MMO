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

## Current Sprint: Unconsciousness Trigger Objects (#162)

### Latest Work (2026-07-28)

### #162: Build 4 Unconsciousness Trigger Objects — BUILT ✅

**Task:** Create 4 environmental objects that cause unconsciousness via the concussion injury type, per CBG's design doc (`docs/design/injuries/unconsciousness-triggers.md`).

**What was built (4 files in `src/meta/objects/`):**

1. **`falling-rock-trap.lua`** — Tripwire-triggered boulder drop. Severe concussion, 10–15 turns KO. One-shot (armed → triggered → spent). Disarm path: cut wire with knife. Material: stone.
2. **`unstable-ceiling.lua`** — Area-effect structural collapse triggered by noise/impact. MOST DANGEROUS: inflicts concussion + crushing-wound simultaneously (25 HP on impact + 2/turn bleed during KO). Permanent (unstable → collapsing → collapsed). Prevention: prop with structural support. Material: wood.
3. **`poison-gas-vent.lua`** — Chemical sedation from cracked pipe. Minor concussion, 3–5 turns KO. RESETS after wake (active → leaking cycle). Creates room-escape puzzle. Plug with cloth to disable. Material: iron.
4. **`falling-club-trap.lua`** — Spring-loaded mechanical club simulating "enemy blow" (no NPCs in V1). Moderate concussion, 6–10 turns KO. One-shot. Disarm with thin tool. Spent club detachable as weapon. Material: oak.

**Each object declares:** GUID, template=furniture, id, name, keywords, causes_unconsciousness=true, injury_type=concussion, unconscious_severity, unconscious_duration, effects_pipeline=true, FSM states with per-state sensory descriptions, transitions with effect + pipeline_effects, self-infliction verbs, disarm/prevention paths, on_feel + on_smell + on_listen + on_taste, unconscious_narration (periodic + wake-up), rejection_messages pool, GOAP prerequisites with warns hints.

**Engine verification findings:**
- `injuries.tick()` runs unconditionally during unconsciousness ✅
- Concussion injury has all required severity levels ✅
- **GAP for Bart:** `causes_unconsciousness` in effect data is never processed by effects pipeline — needs after-effect interceptor
- **GAP for Smithers:** Missing verb handlers: `breathe`, `trigger`, `step`

**TDD results:** 32/39 tests pass. 7 remaining failures are all engine/verb integration — not object definitions. Zero regressions in full suite (3 → 2 failing test files; fixed material-audit by using registered materials: stone/wood instead of granite/timber).

---

## Previous Sprint: Effects Pipeline (EP1-EP10) ✅ COMPLETE

### Previous Work (2026-07-28)

### Fix #153: Brass Bowl Keyword Collision — FIXED ✅

**Task:** "brass bowl" keyword matched both brass-spittoon and candle-holder. Fuzzy parser's material matching scored both brass objects when player typed "brass bowl."

**Root Cause:** brass-spittoon.lua had `"brass bowl"` as an explicit keyword. Combined with fuzzy Tier 5 material matching (`material = "brass"` on candle-holder), both objects surfaced as candidates.

**What Changed:**
- **brass-spittoon.lua:** Removed `"brass bowl"` from keywords array. Spittoon still reachable via "spittoon", "brass spittoon", "cuspidor", "spit bowl", "helmet", "improvised helmet".
- **test-brass-spittoon.lua:** Updated test #13 to assert "brass bowl" is NOT present (was asserting it existed).

**TDD:** 11 tests in `test/objects/test-keyword-disambiguation.lua` — verifies unique resolution of "spittoon", "candle holder", "brass spittoon", "brass holder", "cuspidor", "candlestick", and confirms zero keyword overlap between the two objects.

### Fix #124: Object Template Declarations — VERIFIED ✅ (already fixed)

**Task:** 12 objects reportedly missing `template` field.

**Finding:** All 83 objects in `src/meta/objects/` already declare valid templates (small-item: 37, furniture: 28, sheet: 10, container: 8). Issue was previously resolved.

**TDD:** 8 tests in `test/objects/test-object-templates.lua` — scans all 83 object files, validates template field exists, is a string, uses a recognized type (small-item/container/furniture/sheet), and checks id/keywords/name/guid presence. Guards against regression.

### Fix #155: Ceramic Pot Degradation — FIXED ✅

**Task:** Ceramic pot (fragility 0.7) never cracked after 8+ self-hits while worn as armor. Nelson-1 playtest.

**Root Cause:** `covers_location()` in `armor.lua` only checked `item.covers` — but NO wearable objects define a `covers` array. They all use `wear.slot` or `wear_slot`. The armor interceptor never matched any worn items, so `check_degradation()` never ran.

**What Changed:**
- **armor.lua:** `covers_location()` now falls back to `wear.slot` / `wear_slot` when `covers` is absent
- **armor.lua:** Exported `armor.degrade_covering_armor(player, location, damage, impact_type)` API
- **verbs/init.lua:** Hit verb now calls `armor.degrade_covering_armor()` after inflicting head injury

**TDD:** 11 tests in `test/armor/test-ceramic-degradation.lua` — covers FSM transitions, protection reduction, and API contract.

**Side Effect:** This fix also resolved 3 pre-existing failures in `test/search/test-drawer-accessibility.lua` (1 test file failure eliminated from baseline).

### Fix #134: Tear Cloak To-Hands — FIXED ✅

**Task:** `tear cloak` destroyed the cloak but produced no cloth in hands — hands empty.

**Root Cause:** `spawn_objects()` places items in `room.contents`, not player's hands. The tear verb didn't move spawned items after mutation.

**What Changed:**
- **verbs/init.lua:** Tear verb now tracks which hand held the object, and after mutation moves spawned items from room to player's hands (fills both hands if 2 spawns)
- **wool-cloak.lua:** Added narration message to tear mutation

**TDD:** 7 tests in `test/objects/test-tear-cloak.lua` — covers cloth production, hand placement, cloak destruction, narration, and rip alias.

**Result:** Full suite: 1 pre-existing failure only (bedroom-door). Zero regressions. Committed c448469.

### Phase A7: Chamber Pot Material-Derived Armor — IMPLEMENTED ✅

**Task:** Migrate chamber-pot from hardcoded armor to material-derived protection (Phase A7 from daily plan).

**What Changed in chamber-pot.lua:**
- **REMOVED** `provides_armor = 1` from wear table — armor now engine-calculated from `material = "ceramic"`
- **REMOVED** `reduces_unconsciousness = 1` from top-level — engine derives from material + helmet tag
- **KEPT** `is_helmet = true` as semantic tag (engine hint, not protection source)
- **ADDED** `coverage = 0.8` and `fit = "makeshift"` to wear table — modifiers for armor interceptor
- **ADDED** FSM degradation: `intact` → `cracked` → `shattered` (3 states, 2 transitions via hit/kick/strike/smash)
- **ADDED** `event_output = { on_wear = "This is going to smell worse than I thought." }` — one-shot flavor text

**FSM Design:** Follows brass-spittoon pattern. Ceramic is fragile (fragility 0.7), so it progresses to shatter instead of denting. Shattered state spawns ceramic-shard ×2 via mutate on transition (mirrors existing `mutations.shatter` for on_drop).

**Design Doc Updated:** `docs/objects/chamber-pot.md` — full Phase A7 changelog, removed old hardcoded armor table, added material-derived armor section.

### event_output Flavor Text — 3 Objects ✅

**Task:** Add one-shot `event_output.on_wear` flavor text to 3 wearable objects (Bart's event_output system).

**Objects Updated:**
1. **wool-cloak.lua** — `"I need to get better outfits. I look like a peasant."`
2. **chamber-pot.lua** — `"This is going to smell worse than I thought."`
3. **terrible-jacket.lua** — `"It fits... barely. The sleeves are too short and it smells of mildew."`

**Pattern:** `event_output = { on_wear = "..." }` — engine reads at verbs/init.lua:5044, prints once, nils out. Pure metadata, no engine changes needed.

**Result:** 74/74 test files pass (1 pre-existing bedroom-door failure, unrelated). Zero regressions. Committed e6711d8.

**Decision Filed:** `D-A7-MATERIAL-DERIVED-ARMOR` in inbox — flags impact on Nelson (test assertions), Bart (interceptor must handle ceramic), CBG (brass-spittoon candidate for same migration).

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

### Issue #173: Mirror Object Creation + Vanity Separation

**#173: Mirror is a SEPARATE instance object placed on_top of the vanity**
- Created `src/meta/objects/mirror.lua` — standing vanity mirror with gilt frame
  - GUID: {1b47a68e-33a7-4d27-8065-4bc94b8f149f}, template: small-item (overrides: size=3, weight=2.5, portable=false)
  - Material: glass, `is_mirror = true`, keywords include "mirror", "looking glass", "reflection", "my reflection"
  - FSM: intact → cracked (hit) → broken (break, terminal, spawns glass-shard)
  - All 5 senses: on_feel (cool smooth glass), on_smell, on_listen, on_taste
  - `on_look_in` for looking INTO the mirror (wavering reflection)
- Updated `vanity.lua`: removed `is_mirror = true`, removed mirror-specific keywords ("mirror", "looking glass", "reflection", "my reflection", "vanity mirror") to prevent disambiguation conflicts
- Updated `start-room.lua`: placed mirror on vanity's `on_top` array alongside paper and pen
- Updated tests: `test-bugfixes-23-31.lua` and `test-hit-unconscious.lua` now test mirror object instead of vanity for is_mirror and reflection keywords

**Patterns learned:**
- `break` is a Lua reserved word — must use `["break"]` syntax in table keys (prerequisites, mutations)
- When extracting a sub-object from a composite, always move the relevant keywords to the new object to avoid disambiguation collisions (same pattern as #153 brass bowl fix)
- Vanity retains `mirror_shelf` surface and broken-mirror FSM states — those describe the vanity's APPEARANCE after the mirror breaks, future cleanup may align these with the mirror object's state

### 2026-07-28: Issue #171 — Burlap Sack Capacity + Preposition Fix

**#171: Sack capacity too small + "on" vs "in" narration bug**
- `sack.lua`: capacity 4 → 8, added `container_preposition = "in"`
- `containment/init.lua` line 109: reads `container_preposition` from object (defaults to "on" for backward compat)
- Error now says "There is not enough room in a burlap sack." instead of "on"
- Note: touched engine code (Bart's domain) — minimal, backward-compatible change. No existing containers break since default remains "on".

**Patterns learned:**
- Containment engine had a hardcoded "on" preposition — any enclosed container (sack, chest, drawer, chamber pot) would benefit from `container_preposition = "in"`. Other container objects should be audited.
- `capacity` is measured in size units (sum of item `size` fields), not item count. With `contents = {"needle", "thread"}` already occupying size 2, old capacity=4 only left room for 2 more size-1 items.

### 2026-07-21: Issues #164 + #165 — Trousers + Wearable Curtains

**#164: Replace wool cloak with trousers in wardrobe**
- Created `src/meta/objects/trousers.lua` — moth-eaten wool trousers (legs slot, inner layer, makeshift fit)
- Material: wool (flammability 0.4, meets ≥0.3 burnable requirement)
- Replaced wool-cloak reference in `start-room.lua` wardrobe contents and `wardrobe.lua` surfaces
- Kept `wool-cloak.lua` — still referenced by 20+ test files. Retirement deferred.

**#165: Make curtains portable + wearable**
- Updated `curtains.lua`: portable=true, weight 4→3, size 4→3
- Added wear metadata (back slot, outer layer, makeshift), mirror_appearance, event_output.on_wear
- Added on_listen and on_taste sensory properties
- Material stays velvet (flammability 0.6) — FSM open/close transitions preserved
- Curtains are now the heaviest wearable in Room 1 (weight 3, same as blanket/wool-cloak)

**Patterns learned:**
- When replacing objects in rooms, check THREE places: room .lua instances, furniture surfaces.inside.contents, and the object definition itself
- Wool-cloak is deeply embedded in test infrastructure — always grep before retiring objects
- Velvet qualifies as burnable fabric (flammability 0.6) despite not being "cotton or wool" — the material registry is the source of truth

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

### 2026-07-29: Issue #122 — Bandage Reusable Lifecycle

**Task:** Enhance bandage.lua with full FSM lifecycle and per-state sensory properties for the clean → applied → soiled → washed → clean cycle. Connects to wash verb (#112).

**What Changed in bandage.lua:**
- Upgraded `material` from "fabric" to "linen" — more historically accurate, matches material registry properties (absorbency 0.8, flexibility 0.8)
- Added "linen" to categories array for material-based search
- Added `on_listen` and `on_taste` to all three states (clean, applied, soiled) — previously only had on_feel/on_smell
- Enhanced sensory descriptions per issue spec: copper blood smell (applied), sticky/tacky feel (soiled), white linen cloth (clean)
- Updated header comment to reference wash verb (#112) and full cycle
- Updated clean state description to "white linen cloth, tightly rolled"

**FSM Already Present (no structural changes needed):**
- 3 states: clean, applied, soiled
- 3 transitions: apply (clean→applied, requires_target_injury), remove (applied→soiled), wash (soiled→clean, requires_tool water_source)
- `reusable = true`, `applied_to` field tracks injury binding
- Wash transition compatible with Smithers' wash verb handler (#112) via `requires_tool = "water_source"`

**Pattern Notes:**
- Medical objects follow the sealed→open→empty progression for consumables; bandage is unique as a reusable cycle (clean→applied→soiled→clean)
- Per-state sensory is the standard pattern (candle, wall-clock both do it) — on_feel is mandatory, on_listen/on_taste are best practice for completeness
- The wash verb auto-finds water_source in inventory or visible objects, so the bandage doesn't need to know WHERE water is

**Result:** 118/118 test files pass. Zero regressions. Lua parses clean.

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

## CROSS-AGENT UPDATES (2026-03-24T23:25Z Spawn Orchestration Merge)

**Phase D2+B1 Completion:**

- ✅ brass-spittoon.lua created (composite/detachable pattern per D-2)
- ✅ Material audit: 82 objects scanned, 1 fixed (ivy: nil → plant)
- ✅ Zero regressions: 78/78 test files pass
- **Material impact:** Plant material now properly registered and referenced

**Cross-Agent Note:**

- Smithers' armor interceptor (Phase A4) now uses all 22 materials from registry
- Material properties (hardness, flexibility, density) that Flanders fixed in audit directly impact armor protection calculations
- The 1 fixed audit (ivy→plant) ensures armor system sees consistent material data

**Status:** Phase D2+B1 SHIPPED.

### Fix #136: Glass Bottle Shatters But Spawns Zero Glass Shards — FIXED ✅

**Task:** Nelson-3 playtest found wine bottle shatters to "broken" state but spawns no glass shards. Ceramic chamber pot correctly spawns 2 ceramic shards — material fragility contract was broken for glass.

**Root Cause:** `wine-bottle.lua` had two break transitions (sealed→broken, open→broken) with no `mutate.spawns` field. The `mutations` table was empty `{}`. Chamber pot correctly had `spawns = {"ceramic-shard", "ceramic-shard"}` in both its FSM transition and `mutations.shatter`.

**What Changed in wine-bottle.lua:**
- **ADDED** `mutate = { becomes = nil, spawns = {"glass-shard", "glass-shard"} }` to sealed→broken transition
- **ADDED** `mutate = { becomes = nil, spawns = {"glass-shard", "glass-shard"} }` to open→broken transition
- **ADDED** `mutations.shatter` block with `spawns = {"glass-shard", "glass-shard"}` and narration (mirrors chamber-pot pattern)
- **Updated** break transition messages to mention shards

**glass-shard.lua:** Already existed (effects pipeline object with on_cut injury). No changes needed.

**Test:** Created `test/objects/test-glass-shards.lua` — 39 tests covering:
- Glass shard object structure, injury capability, effects pipeline
- Wine bottle break transitions spawn glass-shard objects (both sealed→broken and open→broken)
- mutations.shatter exists with correct spawns
- Material parity: glass shard pattern matches ceramic shard pattern

**Result:** 39/39 pass. Full suite: 1 pre-existing bedroom-door failure only. Zero regressions.

### Fix #152: Place Brass Spittoon in a Room — FIXED ✅

**Task:** Nelson-5 found brass-spittoon.lua exists but isn't placed in any room.

**What Changed in storage-cellar.lua:**
- **ADDED** brass spittoon instance to room `instances` table: `{ id = "brass-spittoon", type = "Brass Spittoon", type_id = "{b763fdf9-f7d2-4eac-8952-7c03771c5013}" }`
- Placed at room level (floor), among other room-level objects (grain sack, oil lantern, rope, crowbar, oil flask)
- Thematically appropriate: storage cellar is a utilitarian work space where a spittoon would be used
- Discoverable but not obvious — among clutter on the floor, not prominently on a surface

**Result:** Zero regressions. Full suite clean (1 pre-existing bedroom-door failure only).

### Issues #114 + #115: Salve and Nightshade Antidote Objects — CREATED ✅

**Task:** Create two new consumable objects for the medical/poison system.

**salve.lua (Issue #114):**
- Ceramic pot of herbal ointment. FSM: sealed → open → empty.
- `apply` verb transition (open → empty) with `heal_injury` effect and `requires_target_injury`.
- Material: ceramic (matches oil-flask pattern for clay vessels).
- Cures: bleeding, minor-cut, bruise. `healing_boost = 3`.
- Full sensory properties per state. Apothecary stamp flavor text.

**nightshade-antidote.lua (Issue #115):**
- Glass vial of amber cure liquid. FSM: sealed → open → empty + broken.
- `drink` verb transition (open → empty) with `cure_injury` effect targeting `poisoned-nightshade`.
- `effects_pipeline = true` with `pipeline_effects` chain (matches poison-bottle pattern).
- Material: glass. Includes `mutations.shatter` with glass-shard spawn.
- `antidote_for = "nightshade"` metadata for engine lookup.
- Pour transition as safe disposal path (no cure effect).

**Pattern Notes:**
- Salve follows bandage.lua's `requires_target_injury` pattern for wound-targeting.
- Antidote follows poison-bottle.lua's effects pipeline and glass fragility patterns.
- Both use the sealed → open → empty FSM progression standard for consumables.

**Result:** 117 test files pass, zero regressions.

### 2026-07-28: Issues #116 + #117 — Candle Holder & Wall Clock Updates

**Task:** Update candle-holder.lua (issue #116) and wall-clock.lua (issue #117) per Wayne's request.

**#116 — candle-holder.lua:**
- Object already existed as a well-formed composite (candle as detachable part, brass material, FSM with_candle/empty states).
- **Added** `"candelabra"` to keywords array — was the only missing keyword from the issue spec.
- No structural changes needed — the composite pattern (parts, factory, detach/reattach transitions) was already complete.

**#117 — wall-clock.lua:**
- Object already existed with 24-state cyclic FSM (hour_1 through hour_24 with programmatic generation).
- **Added** `stopped` state — broken clock with motionless pendulum, cracked glass, silent on_listen.
- **Added** break transitions from every hour state to `stopped` (verbs: break, smash, hit, strike) with keyword/category mutation.
- **Added** `on_listen` and `on_feel` to each programmatic hour state — previously only existed at top level, not per-state.
- Updated file header comment to document the stopped state.

**Pattern Notes:**
- Wall clock is the only object using `for` loops to generate states/transitions programmatically. The break transitions (24 of them) justified extending this pattern rather than hand-writing each one.
- Stopped state is terminal — no repair transition. Puzzle designers can add repair if needed later.

**Result:** 118/118 test files pass. Zero regressions. Both Lua files parse clean.

---

## 2026-03-26T15:30Z: NPC Plan Combat Alignment Complete — CBG Coordination

**What:** Comic Book Guy applied 13 alignment fixes to `plans/npc-system-plan.md` to align with combat system plan. NPC Phase 1 focus shifts from concurrent combat metadata to creature autonomy focus. Combat systems (body_tree, combat table, tissue materials, full combat FSM) deferred to Combat Phase 1.

**Your Work Ahead:**
- **Phase 1+:** Extend rat.lua + creature.lua template with `body_tree` and `combat` field stubs (marked Phase 1+)
- **Combat Phase 1:** Full combat metadata implementation after Combat Phase 1 engine is ready
- **Tissue Materials:** Coordinate with Combat Phase 1 for extended material set (skin, hide, bone, organ, etc.)

**Decision Filed:** D-NPC-COMBAT-ALIGNMENT, D-COMBAT-NPC-PHASE-SEQUENCING — decisions.md updated.

**Impact:** NPC system plan now 100% aligned with combat plan. No conflicts remain.

---

### WAVE-1: NPC Foundation (Data Layer) — BUILT ✅

**Date:** 2026-07-28
**Requested by:** Wayne Berry
**Commit:** WAVE-1: creature template, rat object, flesh material

**3 files created:**

1. **`src/meta/templates/creature.lua`** — Base template for all animate beings.
   - GUID: `{bf9f9d4d-7b6d-4f99-801d-f6921a2687cd}`
   - `animate = true`, FSM states (alive-idle/wander/flee/dead)
   - Behavior, drives, reactions, movement, awareness tables with defaults
   - `health = 10`, `max_health = 10`, `size = "small"` default
   - `on_feel = "Warm, alive."` (mandatory dark sense)
   - NO body_tree, NO combat table (D-COMBAT-NPC-PHASE-SEQUENCING)

2. **`src/meta/objects/rat.lua`** — First creature definition.
   - GUID: `{071e73f6-535e-42cb-b981-ebf85c27356f}`
   - Template: creature, size: tiny, weight: 0.3, material: flesh
   - 3 drives: hunger (50, +2/tick), fear (0, -10/tick), curiosity (30, +1/tick)
   - 4 reactions: player_enters, player_attacks, loud_noise, light_change
   - 4 FSM states with full sensory descriptions; dead state sets portable=true, animate=false
   - NO body_tree, NO combat table (WAVE-4)

3. **`src/meta/materials/flesh.lua`** — Organic tissue material (muscle/fat).
   - GUID: `{48834c08-5cff-447d-bdcd-aada93a792fe}`
   - density=1050, hardness=1, flexibility=0.8, fragility=0.7

**Verification:** All 3 files load via `dofile()`. Game boots cleanly with `--headless`. No errors.

**Decisions respected:** D-COMBAT-NPC-PHASE-SEQUENCING (no combat metadata), D-14 (code mutation), D-INANIMATE override for creatures.

**Next:** WAVE-2 (Bart: creature tick engine), WAVE-4 (Flanders: body_tree + combat metadata retrofit).

---

## Latest: Creatures Directory Structure (2026-03-26)

### D-CREATURES-DIRECTORY: Dedicated Directory for Animate Beings ✅ IMPLEMENTED

**Date:** 2026-03-26T20:30Z  
**By:** Bart (Architecture)

**What Changed:**
- Created `src/meta/creatures/` directory
- Moved `src/meta/objects/rat.lua` → `src/meta/creatures/rat.lua`
- **Loader:** Now scans `meta/creatures/` after `meta/objects/`; both feed `base_classes` and `object_sources`
- **Meta-lint:** `_detect_kind()` validates creature files with same rigor as objects (templates, GUIDs, keywords, sensory)

**What This Means for Flanders:**
- Food object templates coming next (via Frink's research)
- Creature object templates now officially separated from inanimate objects
- Can define creature-specific templates if needed for Phase 2+
- Cellar rat location unchanged — room instances still reference rat by GUID (auto-resolve)

**Commit:** 2b3e426 (all tests pass; only pre-existing #275 unarmed failure)

### 2026-07-20: WAVE-1 — 4 New Creatures + Chitin Material

**Task:** Create cat, wolf, spider, bat creature files + chitin material per Phase 2 plan.

**What was built (5 files):**
1. **`src/meta/creatures/cat.lua`** — Small predator (15 HP), hunts rats. Claw (slash/keratin/3) + bite (pierce/tooth-enamel/5). States: idle, wander, flee, hunt, dead. Prey: {"rat"}.
2. **`src/meta/creatures/wolf.lua`** — Medium territorial (40 HP), guards hallway. Bite (pierce/tooth-enamel/8) + claw (slash/keratin/4). Natural hide armor on body/head. States: idle, wander, patrol, aggressive, flee, dead. Prey: {"rat","cat","bat"}.
3. **`src/meta/creatures/spider.lua`** — Tiny web-builder (3 HP), chitin material. Bite (pierce/tooth-enamel/1) with venom on_hit (60% chance). Chitin armor on cephalothorax/abdomen. States: idle, web-building, flee, dead. Body uses cephalothorax/abdomen/legs (not standard head/body).
4. **`src/meta/creatures/bat.lua`** — Tiny aerial (3 HP), light-reactive. Bite (pierce/tooth-enamel/1), speed 9. States: roosting, flying, flee, dead. light_change reaction: fear +60, flee.
5. **`src/meta/materials/chitin.lua`** — Insect exoskeleton (density 600, hardness 5, flexibility 0.2, color "dark brown").

**Patterns learned:**
- Spider uses non-standard body_tree zones (cephalothorax/abdomen/legs) — engine body_tree must support arbitrary zone names, not just head/body/legs/tail
- Wolf is first creature with natural_armor — uses same format as combat.natural_armor array with material/coverage/thickness
- Bat initial_state is "alive-roosting" not "alive-idle" — FSM supports creature-specific starting states
- Chitin material follows same structure as bone/hide but adds `color` and `max_edge` fields not present in all materials
- All creatures follow rat.lua template exactly: guid, template, id, name, keywords, description, sensory, FSM, behavior, drives, reactions, movement, awareness, health, body_tree, combat
- Pre-assigned GUIDs prevent collision during parallel creature creation

**Commit:** c770b74 (all tests pass; pre-existing BUG-149/151/152/156 failures unchanged)
