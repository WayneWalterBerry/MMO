# Flanders Review: Phase 3 Implementation Plan — Object/Creature Data Perspective

**Author:** Flanders (Object & Injury Systems Engineer)
**Date:** 2026-08-16
**Status:** 📋 REVIEW
**Reviewing:** `plans/npc-combat/npc-combat-implementation-phase3.md` v1.0
**Requested By:** Wayne "Effe" Berry

---

## VERDICT: CONDITIONAL APPROVE

Phase 3 is architecturally sound and well-scoped. The mutation chain design is pure D-14, the template assignments are correct, and the wave ordering respects dependencies. I can build every object assigned to me.

However, there are **2 blockers** and **7 concerns** that need resolution before implementation begins.

---

## BLOCKERS (Must Fix Before WAVE-1)

### B-1: `mutations.die` vs `mutations.kill` Naming Conflict

**Severity:** 🔴 BLOCKER — engine code will check ONE key, not both.

The Phase 3 plan consistently uses `mutations.die` (lines 201, 205, 207, 227, etc.). But the approved D-FOOD-ARCHITECTURE decision in `decisions.md` (bart-food-architecture) uses `mutations.kill` throughout (lines 1717, 1747, 2090, 2150, 2192).

These are different mutation key names. The engine will wire ONE of them. If I write creature files with `mutations.die` but Bart's engine checks `mutations.kill`, the death path silently fails — creatures enter FSM `dead` state instead of producing corpses.

**Resolution needed:** Bart and Wayne agree on ONE name. I prefer `mutations.die` (Phase 3 plan) since it reads as "what happens when this thing dies" — but either works as long as it's consistent everywhere.

### B-2: Dead-Cat and Dead-Bat Missing Cook Targets

**Severity:** 🔴 BLOCKER — incomplete mutation chain breaks GATE-3.

The WAVE-1 table (line 216-219) says dead-cat and dead-bat are both `cookable = true` with `food.raw = true`. But NO cook target (`food.cook_to` / `crafting.cook.becomes`) is specified for either.

- `dead-rat.lua` → `cooked-rat-meat.lua` ✅ (line 375)
- `dead-cat.lua` → ??? ❌
- `dead-bat.lua` → ??? ❌

The cook verb will call `mutation.mutate()` with whatever `becomes` value is declared. If it's nil, the mutation fails.

**Resolution needed:** Either:
- (A) Create `cooked-cat-meat.lua` and `cooked-bat-meat.lua` (3 distinct cooked meats) — adds 2 files to my WAVE-3 scope
- (B) Create a generic `cooked-game-meat.lua` that all small cookable corpses produce — simpler but loses identity
- (C) Defer cat/bat cooking to Phase 4, mark them `cookable = false` for now — simplest

**My recommendation:** Option A. Each creature should produce distinct cooked meat with unique sensory text. A cooked rat and a cooked bat should taste and feel different. This is 2 extra files (~40 lines each) — trivial scope.

---

## CONCERNS (Should Fix, Not Blocking)

### C-1: `meat.lua` Material Duplicates Existing `flesh.lua`

The plan calls for a new `meat.lua` material (line 223: "density 1050, ignition 300, hardness 1"). But `flesh.lua` already exists with **identical** properties:

```
flesh.lua: density=1050, ignition_point=300, hardness=1, flexibility=0.8, fragility=0.7
```

"Meat" and "flesh" are the same material. Creating both is confusing — which do objects use? I recommend:
- Use `material = "flesh"` on all dead creature objects
- Skip creating `meat.lua` entirely
- If the word "meat" is preferred for cooked objects, rename `flesh.lua` to `meat.lua` (but that breaks rat.lua and any creature using `material = "flesh"`)

**Simplest path:** Dead creatures use `material = "flesh"` (raw). Cooked meat objects use `material = "flesh"` too — cooking doesn't change the base material, just the state. If we later need distinct cooked-material properties, we add it then.

### C-2: Dual Cooking Metadata Path on dead-rat.lua

Lines 384-396 show BOTH a `crafting.cook` block AND a `mutations.cook` block:

```lua
crafting = {
    cook = { becomes = "cooked-rat-meat", requires_tool = "fire_source", ... },
},
mutations = {
    cook = { becomes = "cooked-rat-meat", requires_tool = "fire_source" },
},
```

D-COOKING-CRAFT decision says the cook verb reads from `obj.crafting.cook` (following the `sew` pattern in crafting.lua). The `mutations.cook` block is redundant — or worse, it implies a different code path.

**Resolution:** Pick one. The `crafting.cook` block is correct per the decision. Remove the `mutations.cook` block to avoid confusion. The cook verb handler calls `mutation.mutate()` internally using the `crafting.cook.becomes` value — the object doesn't need to declare it twice.

### C-3: `edible` Field Location Inconsistency

Three different patterns in the codebase:

| Source | Pattern | Example |
|--------|---------|---------|
| cheese.lua (existing) | `food = { edible = true }` | Nested in food table |
| D-FOOD-ARCHITECTURE decision | `edible = true` (root) | Top-level field |
| Phase 3 plan, line 368 | `obj.cookable == true` and `obj.edible ~= true` | Top-level field |

The eat verb handler will check ONE location. Bart needs to confirm: is edibility checked at `obj.edible` or `obj.food.edible`? I'll follow whatever Bart wires, but the plan should be explicit.

**My preference:** Root-level `edible = true` and `cookable = true` (Principle 8 — flat metadata the engine reads directly). The `food = {}` table holds nutrition/risk/effects data.

### C-4: Sensory Fields Missing from New Object Specs

The plan specifies sensory requirements for dead creatures (line 221: "MUST have on_feel, on_smell, on_listen") but provides NO sensory specs for:

| Object | on_feel | on_smell | on_taste | on_listen | description |
|--------|---------|----------|----------|-----------|-------------|
| cooked-rat-meat.lua | ❌ | ❌ | ❌ | ❌ | ❌ |
| gnawed-bone.lua | ❌ | ❌ | ❌ | ❌ | ❌ |
| silk-bundle.lua | ❌ | ❌ | ❌ | ❌ | ❌ |
| grain-handful.lua | ❌ | ❌ | ❌ | ❌ | ❌ |
| flatbread.lua | ❌ | ❌ | ❌ | ❌ | ❌ |
| antidote-vial.lua | ❌ | ❌ | ❌ | ❌ | ❌ |

**Not blocking** — I'll write all sensory text during implementation (it's my core job). But the plan should at minimum note that `on_taste` is required on ALL dead creatures since the food system uses taste for risk identification. The D-COOKING-CRAFT decision in decisions.md already has good example sensory text for grain and cooked grain that I can reference.

### C-5: Q1 (Corpse Container) vs WAVE-2 (Scatter to Floor) Contradiction

Open Question Q1 recommends **Option B: Corpse as container** (line 775: "Player types `search dead wolf` → sees inventory"). But WAVE-2 engine changes say **"iterate inventory → instantiate each item as room-floor object"** (line 272) — that's Option A (scatter to floor).

If Q1=B is approved, WAVE-2's engine changes need rewriting. If Q1=A, the container fields on dead creatures (`container = true, capacity = N`) from the WAVE-1 table are unnecessary.

**My recommendation:** Option B (corpse as container) is richer and proven by existing patterns (matchbox.lua, sack.lua are small-item containers). I've already validated the containment system handles this. But Wayne must decide before WAVE-2 starts.

### C-6: Stress Injury Spec is Too Sparse

The stress.lua spec (lines 448-458) provides states and restrictions but is missing required injury fields based on the rabies.lua pattern:

| Required Field | Specified? |
|---------------|------------|
| guid | ❌ (TBD in GUID table) |
| id, name | ✅ (implied) |
| category | ❌ — "psychological"? "trauma"? |
| damage_type | ❌ — "none"? "over_time"? |
| on_inflict block | ❌ — initial message, damage? |
| transitions with conditions | ❌ — only says "10 turns safety" |
| healing_interactions | ❌ — is stress curable by items? |
| on_feel (if manifest physically) | ❌ — trembling hands? |

I can fill all these in during implementation, but Bart should confirm whether stress does HP damage (I'd say no — it restricts actions only) and whether any items cure it (I'd say no — time-only for Phase 3).

### C-7: Food-Poisoning Injury Equally Sparse

Line 378 says "Nausea + damage, moderate severity, 20-tick duration." This needs:

- FSM states: nauseated → weakened → recovering → recovered? Or single-state with timer?
- damage_per_tick value
- Which actions are restricted (eating more? precise actions?)
- Is it curable? (healing_interactions for an herbal remedy?)
- Does vomiting accelerate recovery? (Phase 4?)

I'll design the full FSM during WAVE-3 based on the food-system-plan §8 guidance, but the Phase 3 plan should acknowledge this needs fleshing out.

---

## WHAT'S GOOD (Confirmed Sound)

### ✅ Template Assignments
- Dead rat/cat/bat → `small-item` (portable) — correct
- Dead wolf → `furniture` (portable=false) — correct, wolf is too heavy
- Dead spider → `small-item` — correct, spiders are small

### ✅ Container Approach Is Validated
- matchbox.lua proves `template = "small-item"` + `container = true` works in the existing engine
- sack.lua proves container with capacity/weight limits works
- Containment system's 4-layer validation (identity → size → capacity → category) handles this transparently
- Dead-rat capacity=1, dead-cat capacity=2, dead-wolf capacity=5 are reasonable

### ✅ D-14 Mutation Chain Is Pure
- `rat.lua` (creature) → `dead-rat.lua` (small-item) → `cooked-rat-meat.lua` (small-item)
- Each link is a complete code rewrite — the file IS the state
- Backward-compatible: creatures without `mutations.die` keep FSM dead state

### ✅ Spoilage FSM Follows Proven Pattern
- fresh → bloated → rotten → bones mirrors cheese.lua's fresh → stale → spoiled
- Timed auto-transitions via existing engine infrastructure
- Per-state sensory descriptions (I'll write these)

### ✅ Existing Materials Cover Most Needs
- `flesh.lua` — dead creatures ✅
- `bone.lua` — gnawed-bone ✅
- `cotton.lua` — silk-bundle proxy ✅ (plan acknowledges "or cotton as proxy")
- `glass.lua` — antidote-vial ✅

### ✅ Respawn Metadata Is Clean
- Per-creature timer, home_room, max_population — pure metadata, Principle 8
- Values are reasonable (rat=60 fast, wolf=200 slow)

### ✅ No New Injury Types Needed Beyond What's Planned
- 9 existing injuries cover current combat
- stress.lua (WAVE-4) and food-poisoning.lua (WAVE-3) are the right additions
- healing_interactions on rabies.lua and spider-venom.lua are straightforward additions

### ✅ File Ownership Is Clean
- No agent conflicts per wave
- All my files are metadata-only (objects, injuries, creature updates)

---

## MY SCOPE SUMMARY (If Approved)

| Wave | Files I Build/Modify | Est. Lines |
|------|---------------------|------------|
| W1 | 5 dead creature objects, meat.lua material*, 5 creature mutations.die updates | ~350 |
| W2 | wolf/spider inventory metadata, gnawed-bone.lua, silk-bundle.lua | ~120 |
| W3 | cooked-rat-meat.lua, grain-handful.lua, flatbread.lua, food-poisoning.lua, dead-rat crafting update | ~250 |
| W4 | stress.lua, antidote-vial.lua, rabies.lua + spider-venom.lua healing_interactions | ~180 |
| W5 | 5 creature respawn metadata updates | ~25 |
| **Total** | **~16 new files, ~5 modified files** | **~925 lines** |

*Pending C-1 resolution — may use existing flesh.lua instead.

If B-2 is resolved as Option A (distinct cooked meats), add ~80 lines for cooked-cat-meat.lua and cooked-bat-meat.lua.

---

## ACTION ITEMS

| # | Who | What | When |
|---|-----|------|------|
| B-1 | Bart + Wayne | Settle `mutations.die` vs `mutations.kill` naming | Before WAVE-0 |
| B-2 | Wayne | Decide cook targets for dead-cat and dead-bat | Before WAVE-1 |
| C-1 | Flanders + Bart | Confirm meat.lua vs flesh.lua material question | Before WAVE-1 |
| C-2 | Bart | Clarify single cooking metadata path (crafting.cook only) | Before WAVE-3 |
| C-3 | Bart | Confirm edible field location (root vs food table) | Before WAVE-3 |
| C-5 | Wayne | Decide Q1 (corpse container vs scatter) — affects WAVE-2 design | Before WAVE-2 |
| C-6 | Bart + Flanders | Flesh out stress injury spec | Before WAVE-4 |
| C-7 | Flanders | Design full food-poisoning FSM (I'll handle this in WAVE-3) | During WAVE-3 |

---

*Neighborino verdict: This plan is nearly ready. Fix the two blockers, and I'll start building dead critters on day one of WAVE-1.*
