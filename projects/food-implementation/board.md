# Food Implementation Board

**Owner:** Flanders (Object Engineer) + Bart (Architecture Lead) co-owner  
**Last Updated:** 2026-08-17 (Flanders audit)  
**Overall Status:** ✅ PHASE 1 COMPLETE — No blocking gaps remain

---

## Audit Results (2026-08-17, Flanders)

### P0: Audit — DONE ✅

**Key finding:** The board previously claimed "4 raw-meat objects missing (raw-rat, raw-bat, raw-cat, raw-wolf)". This was **incorrect**:

1. **`wolf-meat.lua` already exists** — raw wolf meat produced by butchering. Cooks into `cooked-wolf-meat.lua`. ✅
2. **Rat, bat, cat do NOT need separate raw-meat .lua files.** Their dead corpses ARE the raw meat. Each creature's `death_state` includes `food = { raw = true, cookable = true }` and `crafting.cook = { becomes = "cooked-{type}-meat" }`. The cook verb reads these properties directly from the reshaped corpse.
3. This matches CBG's design recommendation: **Option A for Phase 1 — cook whole corpse.** (See `food-creature-transformation-design.md` Q2.)
4. The wolf/spider path uses butchery (large creatures) — a separate, deeper path that ALSO works. Both pathways are implemented.

### Corrections to Previous Board
- ~~"4 raw-meat objects missing"~~ → **0 missing.** wolf-meat.lua exists; rat/bat/cat use corpse-as-raw-meat.
- ~~"9 test files"~~ → **11 test files** (missed `test-butcher-verb.lua` and `test-consumption-verbs.lua`).
- ~~"90% done"~~ → **Phase 1 is functionally complete.** All food chains work end-to-end.
- Missing from inventory: `grain-handful.lua`, `grain-sack.lua`, `cold-water.lua`, `food-poisoning.lua` injury.

---

## Next Steps

### P1: Remaining Polish (Low Priority)
**Owner:** Flanders (objects), Bart (engine review)

- [ ] Verify fire_source gating works with all fire objects (cellar-brazier, torch, candle) — functional test
- [ ] Consider adding herbs/dried-mint, wrinkled-apple for Phase 2 Level 2 food variety (deferred, not Phase 1)
- [ ] Consider Option C from design doc: butcher-then-cook path for small creatures as "skilled bonus" (Phase 2)

### P2: Phase 2 Expansion (Deferred)
- [ ] Herbs, spices, multi-ingredient recipes
- [ ] Brewing & fermentation
- [ ] Nutrition tracking & starvation clock
- [ ] Farming & crop growth (future worlds)

---

## What Already Exists

### Food Objects (14 implemented)
| Object | File | Status | Notes |
|--------|------|--------|-------|
| Bread | `bread.lua` | ✅ | FSM: fresh→stale. Bait for rats. nutrition=15 |
| Cheese | `cheese.lua` | ✅ | FSM: fresh→stale→spoiled. Bait for rats/bats. nutrition=20 |
| Flatbread | `flatbread.lua` | ✅ | Cooked product of grain-handful. nutrition=10 |
| Grain Handful | `grain-handful.lua` | ✅ | Raw cookable ingredient → flatbread via fire_source |
| Grain Sack | `grain-sack.lua` | ✅ | Container source for grain. Puzzle 009 (hides iron-key) |
| Wine Bottle | `wine-bottle.lua` | ✅ | FSM: sealed→open→empty/broken. Full test coverage |
| Cold Water | `cold-water.lua` | ✅ | Drinkable + burn treatment. FSM: full→empty |
| Wolf Meat (raw) | `wolf-meat.lua` | ✅ | Raw butchery product. cookable=true → cooked-wolf-meat |
| Cooked Rat Meat | `cooked-rat-meat.lua` | ✅ | From cooking dead rat corpse. nutrition=15, heal=3 |
| Cooked Bat Meat | `cooked-bat-meat.lua` | ✅ | From cooking dead bat corpse. nutrition=10, 10% poison risk |
| Cooked Cat Meat | `cooked-cat-meat.lua` | ✅ | From cooking dead cat corpse. nutrition=20, heal=4 |
| Cooked Wolf Meat | `cooked-wolf-meat.lua` | ✅ | From cooking wolf-meat. nutrition=35, heal=8 |
| Spider Meat | `spider-meat.lua` | ✅ | Edible with 30% spider-venom risk. nutrition=8 |
| Tainted Meat | `tainted-meat.lua` | ✅ | Poisoned meat — inflicts food-poisoning on eat |

### Food Tools (1 implemented)
| Tool | File | Status | Notes |
|------|------|--------|-------|
| Butcher Knife | `butcher-knife.lua` | ✅ | Provides `butchering` + `cutting_edge` capabilities |

### Creature Food Chains (5 creatures, all implemented)
| Creature | Path | Status | Notes |
|----------|------|--------|-------|
| Rat | kill → dead rat (cookable corpse) → cook → cooked-rat-meat | ✅ | Small creature, Option A |
| Bat | kill → dead bat (cookable corpse) → cook → cooked-bat-meat | ✅ | Small creature, Option A |
| Cat | kill → dead cat (cookable corpse) → cook → cooked-cat-meat | ✅ | Small creature, Option A |
| Wolf | kill → dead wolf → butcher → wolf-meat (x3) + wolf-bone (x2) + wolf-hide → cook wolf-meat → cooked-wolf-meat | ✅ | Large creature, butchery path |
| Spider | kill → dead spider → butcher → spider-meat + silk-bundle | ✅ | Medium creature, butchery path. Spider-meat is directly edible (no cook needed) |

### Injury (1 implemented)
| Injury | File | Status | Notes |
|--------|------|--------|-------|
| Food Poisoning | `src/meta/injuries/food-poisoning.lua` | ✅ | FSM: onset→nausea→recovery. Inflicted by raw meat / tainted meat |

### Verbs (5 implemented)
| Verb | File | Status | Notes |
|------|------|--------|-------|
| **COOK** | `src/engine/verbs/cooking.lua` | ✅ | Reads `obj.crafting.cook`, requires fire_source, D-14 mutation |
| **ROAST/BAKE/GRILL** | `cooking.lua` | ✅ | Aliases to COOK |
| **EAT** | `src/engine/verbs/consumption.lua` | ✅ | Food effects, raw-meat gating with poisoning, injury restriction checks |
| **DRINK** | `consumption.lua` | ✅ | Beverage handling, FSM transitions |
| **BUTCHER** | `src/engine/verbs/butchery.lua` | ✅ | Corpse → products via `death_state.butchery_products`. Tool-gated |

### Tests (11 files verified)
| Test File | Coverage | Status |
|-----------|----------|--------|
| `test/food/test-cook-verb.lua` | Cook verb mechanics, fire_source gating | ✅ |
| `test/food/test-cookable-gating.lua` | Raw meat edibility, grain rejection | ✅ |
| `test/food/test-food-poisoning.lua` | Food-poisoning injury FSM lifecycle | ✅ |
| `test/food/test-eat-effects.lua` | Eat verb effects (buffs, nutrition) | ✅ |
| `test/food/test-eat-drink.lua` | Consumption pipeline end-to-end | ✅ |
| `test/food/test-bait.lua` | Food as creature bait | ✅ |
| `test/food/test-corpse-spoilage.lua` | Dead creature FSM spoilage states | ✅ |
| `test/verbs/test-wine-fsm.lua` | Wine bottle FSM (sealed/open/empty) | ✅ |
| `test/butchery/test-butchery-products.lua` | Butcher → meat/bone/hide extraction | ✅ |
| `test/butchery/test-butcher-verb.lua` | Butcher verb handler, tool gating, edge cases | ✅ |
| `test/verbs/test-consumption-verbs.lua` | Eat/drink handler basics, empty noun, not-found | ✅ |

**Related tests (creature system, not food-specific):**
- `test/creatures/test-death-drops.lua` — creature death loot instantiation
- `test/creatures/test-reshaped-corpse-properties.lua` — corpse food/cookable properties
- `test/creatures/test-creature-death-reshape.lua` — death reshape pipeline

---

## Design Status

### Design Docs (Authoritative)
1. **`food-system-design.md`** (Comic Book Guy, revised 2026-07-28)
   - ✅ PoC COMPLETE — cheese + bread created, eat/drink verbs implemented, bait mechanic done (Phase 2 WAVE-5)
   - Full design remains **draft** (Phase 3+ deferred)
   - Covers: Edibility model, food objects, creature-to-food transformation, cooking as craft gate, FSM states, sensory integration, bait mechanics

2. **`food-creature-transformation-design.md`** (Comic Book Guy, dated 2026-08-15)
   - 🟢 **Design Proposal** — Awaiting Wayne Approval
   - Synthesizes Wayne's 3 directives + Bart's 2 architecture decisions + Frink's 2 research docs
   - Defines: D-14 mutation chains (creature death → raw meat → cooked), edibility model, cooking gates, creature inventory + loot drops

### Key Architecture Decisions (Finalized)

| Decision | Choice | Rationale | Decision By |
|----------|--------|-----------|-------------|
| Food modeling | **Metadata trait** (`edible = true`, `food = {...}`) on any object | No food template. Pure Principle 8 (Engine Executes Metadata) | Bart, 2026-07-28 |
| Creature→Food transformation | **D-14 Mutation** (`mutations.die = {...}`) | Creature .lua declares death mutation target | Wayne Directive W-FOOD-1 |
| Cooking gates edibility | **Yes** — raw vs. cooked state enforced | Raw meat gating, cook verb mutates | Wayne Directive W-FOOD-2 |
| Creature inventory | **Reuse containment system** (`container = true`) | Same as chests/bags, no new mechanics | Wayne Directive W-FOOD-3 |
| Loot drops on death | **Instantiate to room floor** | Creature inventory → independent room objects | creature-inventory-plan Phase 1 |
| Small creature cooking | **Option A: cook whole corpse** | Dead rat/bat/cat corpses are directly cookable — no butchery needed | CBG recommendation, Phase 1 |

### Principles & Compliance
- ✅ **Principle 8 (Engine Executes Metadata):** Objects declare `food = {...}`, engine reads and acts
- ✅ **Principle 9 (Material Consistency):** Rat flesh is flesh; material properties determine cook/burn/cut behavior
- ✅ **D-14 (Code IS State):** Dead corpse cooks directly into cooked-meat via mutation
- ✅ **Principle 0 (Objects Are Inanimate):** Dead creatures become objects; creature→object boundary via mutation

---

## Ownership

### Flanders (Primary)
- **Domain:** `src/meta/objects/` — all food object .lua definitions
- **Responsibility:**
  - All food item files (bread, cheese, meat, etc.)
  - FSM states (raw, cooked, spoiled, etc.)
  - Sensory properties (on_feel, on_smell, on_taste, on_listen)
  - `food = {...}` metadata traits
  - `crafting.cook` recipe declarations
  - Mutation targets (`becomes = "cooked-X"`)

### Bart (Co-owner — Architecture)
- **Domain:** `src/engine/mutation/`, `src/engine/effects/`, verb architecture
- **Responsibility:**
  - Mutation chain execution (creature death → raw meat → cooked meat)
  - Effects pipeline integration (food buffs, nutrition, poison)
  - `fire_source` tool capability system
  - Contamination/spoilage FSM lifecycle
  - Creature inventory containment system
  - Cook/eat/drink verb architecture

### Smithers (Auxiliary)
- **Concern:** Parser/UI (text output only, not logic)
- Already implemented: Cook/eat verb handlers, text feedback

### Willie (Auxiliary)
- **Concern:** Creature definitions with loot tables
- Determines which creatures carry food items (inventory)

---

## Scope

### Phase 1 (MVP — Level 1)
**Status:** ✅ COMPLETE

- ✅ Food objects: bread, cheese, flatbread, grain-handful, wine, cold-water (14 total)
- ✅ Eat/Drink verbs with injury restriction checks
- ✅ Cook verb + D-14 mutation (corpse/raw → cooked), fire_source gated
- ✅ Raw meat consequences (food-poisoning on force-eat raw meat)
- ✅ Sensory-first design (smell → feel → taste escalation on all food objects)
- ✅ Food as creature bait (bread→rat, cheese→rat/bat)
- ✅ Creature death → corpse (spoilage FSM on bat/rat/cat)
- ✅ Creature inventory (loot drops to room floor)
- ✅ Two cooking pathways: corpse-direct (small) + butchery (large)
- ✅ Butcher verb + butcher-knife tool + product instantiation
- ✅ Food-poisoning injury type with FSM lifecycle
- ✅ 11 dedicated test files + 3 related creature tests

### Phase 2+ (Deferred)
- Herbs, dried mint, spices (food variety for Level 2+)
- Option C: butcher-then-cook as "skilled bonus" for small creatures
- Farming & crop growth (scope: future worlds)
- Brewing & fermentation (scope: future levels)
- Nutrition tracking & starvation clock (scope: decision pending)
- Multi-ingredient recipes (scope: later, uses `craft X from Y` syntax)
- Meal quality ratings (scope: Dwarf Fortress advanced, deferred)

---

## Plan Files

| Document | Location | Purpose |
|----------|----------|---------|
| **Food System Design** | `projects/food-implementation/food-system-design.md` | Game design: food objects, mechanics, sensory system |
| **Food–Creature Transformation** | `projects/food-implementation/food-creature-transformation-design.md` | Technical design: D-14 mutations, edibility model, creature loot |

---

## How to Read This Board

1. **Audit Results** (top) — Flanders audit corrected previous misconceptions
2. **Next Steps** — Only polish and Phase 2 items remain
3. **What Already Exists** — Phase 1 is complete: 14 food objects, 5 creature chains, 5 verbs, 11 tests
4. **Design Status** — Decisions are final, Flanders + Bart are clear on domain split
5. **Scope** — Phase 1 done; Phase 2 is tracked
6. **Ownership** — Flanders leads objects, Bart owns mutations/engine

**Decision:** Food system Phase 1 is **complete.** No blocking implementation gaps remain.

