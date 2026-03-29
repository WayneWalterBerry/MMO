# Food Implementation Board

**Owner:** Flanders (Object Engineer) + Bart (Architecture Lead) co-owner  
**Last Updated:** 2026-08-16  
**Overall Status:** 📋 DESIGNED — Ready for audit & implementation planning

---

## Next Steps

### P0: Audit Existing Implementation
**Owner:** Flanders (primary), Bart (architecture questions)

- [ ] Search `src/meta/objects/` for food object definitions already implemented:
  - `bread.lua`, `cheese.lua`, `flatbread.lua` (✅ exist)
  - `cooked-rat-meat.lua`, `cooked-bat-meat.lua`, `cooked-cat-meat.lua`, `cooked-wolf-meat.lua` (✅ exist)
  - `wine-bottle.lua` (✅ exists — FSM implemented, see `test/verbs/test-wine-fsm.lua`)
  - `spider-meat.lua` (✅ exists)
  - `tainted-meat.lua` (✅ exists)
  - Raw meat variants needed: `raw-rat-meat.lua`, `raw-bat-meat.lua`, etc.
- [ ] Check `src/engine/verbs/cooking.lua` — **COOK verb already implemented** (Phase 3 WAVE-0)
- [ ] Check `src/engine/verbs/consumption.lua` — **EAT/DRINK verbs already implemented** (Phase 3 WAVE-0)
- [ ] Check `src/engine/verbs/butchery.lua` — meat extraction from creatures (Phase 4)
- [ ] List all food-related tests in `test/food/` (9 test files identified: cook-verb, cookable-gating, food-poisoning, eat-effects, eat-drink, bait, corpse-spoilage)
- [ ] Determine what's **Phase 1 ready** vs **deferred to Phase 2+**

**Outcome:** Written audit report with implementation gaps, scope clarity, and owner assignment.

### P1: Implementation Plan Review
**Owner:** Flanders (primary), Bart (engine decisions)

If audit reveals gaps:
- [ ] Request implementation plan from Bart (if engine changes needed) per implementation-plan skill
- [ ] Review design docs for Phase 1 scope vs deferral
- [ ] Clarify owner boundaries: Flanders owns food objects, Bart owns mutation engine & effects

### P2: Execute Implementation
**Owner:** Flanders + Bart (split by domain)

- [ ] Flanders: Create missing raw-meat objects, sensory properties, FSM states
- [ ] Bart: Verify mutation chain (creature death → raw meat → cooked meat), effects pipeline integration
- [ ] Both: Verify all 9 tests pass before merge

---

## What Already Exists

### Food Objects (Implemented)
| Object | File | Status | Notes |
|--------|------|--------|-------|
| Bread | `bread.lua` | ✅ | Basic food item |
| Cheese | `cheese.lua` | ✅ | Basic food item |
| Flatbread | `flatbread.lua` | ✅ | Basic food item |
| Wine Bottle | `wine-bottle.lua` | ✅ | FSM: sealed/open/empty states (full tests in `test-wine-fsm.lua`) |
| Cooked Rat Meat | `cooked-rat-meat.lua` | ✅ | Result of cooking raw-rat-meat |
| Cooked Bat Meat | `cooked-bat-meat.lua` | ✅ | Result of cooking raw-bat-meat |
| Cooked Cat Meat | `cooked-cat-meat.lua` | ✅ | Result of cooking raw-cat-meat |
| Cooked Wolf Meat | `cooked-wolf-meat.lua` | ✅ | Result of cooking raw-wolf-meat |
| Spider Meat | `spider-meat.lua` | ✅ | Creature flesh |
| Tainted Meat | `tainted-meat.lua` | ✅ | Poisoned/spoiled meat |

### Verbs (Implemented)
| Verb | File | Status | Notes |
|------|------|--------|-------|
| **COOK** | `src/engine/verbs/cooking.lua` | ✅ | Full handler — raw → cooked mutation, fire_source required |
| **ROAST/BAKE/GRILL** | `cooking.lua` | ✅ | Aliases to cook |
| **EAT** | `src/engine/verbs/consumption.lua` | ✅ | Food effects, raw-meat gating, cookable checks |
| **DRINK** | `consumption.lua` | ✅ | Beverage handling |
| **BUTCHER/CARVE/SKIN** | `src/engine/verbs/butchery.lua` | ✅ | Creature meat extraction |

### Tests (Implemented)
| Test File | Coverage | Status |
|-----------|----------|--------|
| `test/food/test-cook-verb.lua` | Cook verb mechanics | ✅ |
| `test/food/test-cookable-gating.lua` | Raw vs. cooked state gates | ✅ |
| `test/food/test-food-poisoning.lua` | Raw meat consequences | ✅ |
| `test/food/test-eat-effects.lua` | Eat verb effects (buffs, nutrition) | ✅ |
| `test/food/test-eat-drink.lua` | Consumption pipeline | ✅ |
| `test/food/test-bait.lua` | Food as creature bait | ✅ |
| `test/food/test-corpse-spoilage.lua` | Dead creature FSM states | ✅ |
| `test/verbs/test-wine-fsm.lua` | Wine bottle FSM (sealed/open/empty) | ✅ |
| `test/butchery/test-butchery-products.lua` | Butcher → meat extraction | ✅ |

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

### Principles & Compliance
- ✅ **Principle 8 (Engine Executes Metadata):** Objects declare `food = {...}`, engine reads and acts
- ✅ **Principle 9 (Material Consistency):** Rat flesh is flesh; material properties determine cook/burn/cut behavior
- ✅ **D-14 (Code IS State):** `raw-chicken.lua` → `cooked-chicken.lua` via mutation
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
**Status:** 🟢 MOSTLY COMPLETE (10 audit gaps to resolve)

- ✅ Food objects (bread, cheese, cooked meats, wine)
- ✅ Eat/Drink verbs
- ✅ Cook verb + mutation (raw → cooked)
- ✅ Raw meat consequences (poisoning on force-eat)
- ✅ Sensory-first design (smell → feel → taste escalation)
- ✅ Food as creature bait
- ✅ Creature death → corpse (spoilage FSM)
- ✅ Creature inventory (loot drops)
- ⚠️ Raw meat objects — need 4 variants (raw-rat, raw-bat, raw-cat, raw-wolf)
- ⚠️ Cooking recipes — need review on fire_source gating

### Phase 2+ (Deferred)
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

1. **Next Steps** (top) — Audit first, then implementation planning, then execute
2. **What Already Exists** — 90% done; audit fills the gaps
3. **Design Status** — Decisions are final, Flanders + Bart are clear on domain split
4. **Scope** — Phase 1 is MVP; deferred work is tracked
5. **Ownership** — Flanders leads objects, Bart owns mutations/engine

**Decision:** Food implementation is **not blocked.** Ready to assign to Flanders for Phase 1 audit + implementation.

