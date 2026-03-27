# D-PHASE3-REVIEW-FIXES — Phase 3 Plan v1.1 Blocker Resolutions

**Author:** Bart (Architecture Lead)
**Date:** 2026-08-16
**Status:** 🟢 Active
**Affects:** Flanders, Smithers, Nelson, Moe, CBG, Chalmers

---

## 9 Blockers Resolved

### 1. WAVE-0 Comprehensive Module Splits
**Source:** CBG B1, Chalmers B1, Marge CONCERN-2

WAVE-0 now splits ALL modules over 500 LOC, not just combat/init.lua:
- `combat/init.lua` (695) → init.lua (~445) + resolution.lua (~250)
- `verbs/survival.lua` (715) → survival.lua (~365) + consumption.lua (~200) + rest.lua (~150)
- `verbs/crafting.lua` (629) → crafting.lua (~430) + cooking.lua (~200)
- `engine/injuries.lua` (556) → injuries.lua (~356) + cure.lua (~200)
- `creatures/init.lua` (466→586): growth guard at GATE-2

### 2. `mutations.die` Standardized
**Source:** Flanders B-1

Standardized on `mutations.die` (not `mutations.kill`). Matches `mutations.break`, `mutations.cook` naming convention. D-FOOD-ARCHITECTURE references to `mutations.kill` are superseded.

### 3. Dead-Cat/Dead-Bat Cook Targets Added
**Source:** Flanders B-2

- `dead-cat.lua` → `cooked-cat-meat.lua` (nutrition=20, heal=4)
- `dead-bat.lua` → `cooked-bat-meat.lua` (nutrition=10, heal=2, 10% disease risk)
- 2 new files added to Flanders' WAVE-3 scope

### 4. Cross-Wave Compatibility Tests Added
**Source:** Marge BLOCKER-1

5 new compat test files following Phase 2 pattern:
- `test-p3-wave0-1-compat.lua` through `test-p3-wave4-5-compat.lua`
- ~50 additional tests, total estimate raised from ~190 to ~240

### 5. Combat Sound Propagation → Bart
**Source:** Chalmers B2

Reassigned from Smithers to Bart per `.squad/routing.md` (Bart owns `src/engine/**`). Smithers provides narration API, Bart calls it.

### 6. Rat `home_room` Fixed
**Source:** Moe BLOCKER #1

Changed from `start-room (cellar)` to `cellar`.

### 7. Spawn Position Documented
**Source:** Moe BLOCKER #2

Added: "Creatures spawn as room-level objects with no spatial nesting."

### 8. Food Economy Balance Note
**Source:** CBG B2

Added positive-sum requirement with specific numbers:
- Rat: ~5 HP damage, +3 heal from food = net positive
- Cat: ~8 HP damage, +4 heal = net positive
- Bat: ~3 HP damage, +2 heal = net positive
- Rule: `cooked_food_heal >= average_damage_from_killing`

### 9. Embedding Index → Smithers
**Source:** Smithers C-3

Assigned Smithers as owner of embedding index updates per wave in Appendix B. ~100 new phrases total. Synonym table updates also assigned.

## Additional Concerns Addressed

- **Spider silk:** Changed from inventory to `mutations.die.byproducts` (death mutation byproduct)
- **Raw meat:** Changed from flat rejection to edible-with-consequences (guaranteed food-poisoning)
- **Dead-spider portability:** Fixed Q4 text — spider is small-item (portable), only wolf is furniture
- **Parallelization:** Added note that W3/W4 can run parallel after W2 if schedule requires
- **Dual cooking metadata:** Removed redundant `mutations.cook` block, kept `crafting.cook` only
- **Food preservation:** Added to Phase 4 deferrals (Section 11)
- **"No formal gate" removed:** GATE-0 is real — text updated in dependency graph

---

*— Bart, Architecture Lead*
