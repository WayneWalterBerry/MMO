# NPC + Combat Phase 3 Implementation Plan

**Author:** Bart (Architecture Lead)
**Date:** 2026-08-16
**Version:** v1.4 (all 6-reviewer blocker fixes)
**Status:** ✅ APPROVED — Ready for implementation
**Changelog v1.4:** Fixed ALL blockers identified by 6-reviewer team (CBG, Chalmers, Flanders, Smithers, Moe, Marge). Changes: (1) WAVE-0 now includes Brockman architecture docs (creature-death-reshape.md, creature-inventory.md) as a parallel track — Wayne directive compliance. GATE-0 criteria updated with doc verification checkboxes. Bart reviews Brockman's docs before GATE-0 sign-off. (2) WAVE-5 Brockman scope narrowed to design docs only (food-system.md, cure-system.md) — architecture docs moved to WAVE-0. (3) Death reshape narration clarified: `reshape_narration` optional field added to death_state spec; combat death handler emits reshape narration if present, otherwise silent (player discovers on next `look`). (4) Combat sound propagation narration API specified: `emit_combat_sound(room, intensity, witness_text)` function defined for WAVE-4 with player-perspective narration per distance tier. (5) Cellar brazier room placement explicitly assigned to Moe in WAVE-3 with cellar.lua update task. (6) Moe pre-flight home room verification added before WAVE-5 respawn work. (7) File ownership, conflict matrix, quick reference, and dependency graph all updated.
**Changelog v1.3:** Wayne directed fundamental change to creature death: no separate dead-creature files. Creatures contain their own `death_state` metadata block. Engine reshapes instances in-place on death (template switch creature→small-item/furniture). Eliminates 5 object files. New `reshape_instance()` engine function replaces `mutation.mutate()` for death. Stronger D-14 alignment — creature code literally transforms.
**Requested By:** Wayne "Effe" Berry
**Governs:** Phase 3: Death Consequences → Creature Inventory → Full Food System → Combat Polish → Cure System → Respawning
**Predecessor:** `plans/npc-combat/npc-combat-implementation-phase2.md` (Phase 2 — ✅ COMPLETE, 191 tests)

---

## Wave Status Tracker

| Wave | Name | Status | Gate | Tests |
|------|------|--------|------|-------|
| WAVE-0 | Pre-Flight (Audit + Module Splits + Architecture Docs) | ✅ PASSED | GATE-0 | 191 |
| WAVE-1 | Death Consequences (In-Place Reshape) | ✅ PASSED | GATE-1 | 194 |
| WAVE-2 | Creature Inventory + Loot Drops | ✅ PASSED | GATE-2 | 198 |
| WAVE-3 | Full Food System + Cooking | ✅ PASSED | GATE-3 | ~201+ |
| WAVE-4 | Combat Polish + Cure System | ⏳ Not Started | GATE-4 | — |
| WAVE-5 | Respawning + Design Docs + Polish | ⏳ Not Started | GATE-5 | — |

---

## Section 1: Executive Summary

Phase 3 completes the **creature lifecycle loop** and the **kill→loot→cook→eat gameplay arc** that Phase 2's creature ecosystem made possible. Phase 2 shipped 5 creatures with behavior, NPC-vs-NPC combat, disease, and a food PoC (cheese + bread). Phase 3 closes the gaps: when a creature dies, it becomes a lootable corpse; corpses can be cooked into food; creatures carry items that scatter on death; the player gets combat polish verbs; disease becomes curable; and creatures respawn to prevent extinction.

### What We're Building

1. **Death consequences** — creature death triggers in-place reshape: the engine switches the creature instance's template from "creature" to "small-item" (or "furniture" for wolf) and applies the `death_state` metadata block declared inside the creature file itself. Same GUID, different shape. No separate dead-creature files — all death state (sensory text, cookability, portability, spoilage FSM) lives inside each creature's `.lua` file. This is D-14 in its purest form: the creature code literally transforms.
2. **Creature inventory** — creatures can declare carried/worn items via `inventory` metadata. Death instantiates items to room floor. Meta-lint validates inventory constraints.
3. **Full food system** — `cook` verb handler, cookable check in `eat`, food effects pipeline, food-poisoning injury type, creature→food mutation chain (dead rat → cook → cooked meat), spoilage FSM.
4. **Combat polish** — wire `kick` verb to combat, combat sound propagation (attracts nearby creatures), weapon combat metadata on existing weapon objects. ⚠️ Stress injury deferred to Phase 4 per Q5 decision.
5. **Cure system** — healing-poultice cures rabies (early stages), antidote cures spider-venom, cure mechanics in injury system.
6. **Creature respawning** — population management engine, respawn timers on creature metadata, extinction prevention.

### Why This Order

Strict dependency chain: creatures must reshape into corpse objects on death (WAVE-1) before corpses can carry inventory (WAVE-2), carry inventory before the full cook-from-corpse loop works (WAVE-3), food and combat polish are parallel concerns (WAVE-4), and respawning + docs wrap the phase (WAVE-5). WAVE-0 addresses critical module size violations — combat/init.lua (695 LOC), survival.lua (715 LOC), crafting.lua (629 LOC), and injuries.lua (556 LOC, projected 596 after Phase 3) all breach or will breach the 500 LOC limit.

**Death architecture key name:** This plan standardizes on **`death_state`** as the metadata block name (replacing the prior `mutations.die` approach). The `death_state` block is NOT a mutation in the file-swap sense — it's a **reshape declaration** that tells the engine how to transform the living creature instance into a dead object instance in-place. The engine calls `reshape_instance()` (not `mutation.mutate()`) to apply the `death_state` block. This is a stronger D-14 pattern: the instance transforms, no file swap occurs. D-FOOD-ARCHITECTURE references to `mutations.kill` and the prior v1.2 `mutations.die` are both superseded by this plan.

### Phase 2 Foundation (Already Built)

| Asset | Location | LOC |
|-------|----------|-----|
| Creature engine | `src/engine/creatures/init.lua` | 466 |
| Creature stimulus | `src/engine/creatures/stimulus.lua` | 91 |
| Creature predator-prey | `src/engine/creatures/predator-prey.lua` | 65 |
| Creature morale | `src/engine/creatures/morale.lua` | 75 |
| Creature navigation | `src/engine/creatures/navigation.lua` | 96 |
| Combat engine | `src/engine/combat/init.lua` | 695 |
| Combat narration | `src/engine/combat/narration.lua` | 457 |
| NPC combat behavior | `src/engine/combat/npc-behavior.lua` | 79 |
| Verbs: combat | `src/engine/verbs/combat.lua` | 321 |
| Verbs: crafting | `src/engine/verbs/crafting.lua` | 629 |
| Verbs: survival | `src/engine/verbs/survival.lua` | 715 |
| 5 creatures | `src/meta/creatures/{rat,cat,wolf,spider,bat}.lua` | — |
| 9 injury types | `src/meta/injuries/` | — |
| 2 food objects | `src/meta/objects/{cheese,bread}.lua` | — |
| Player body_tree | `src/main.lua` (lines 354-361) | — |
| 194 test files | `test/` | — |

### Walk-Away Capability

Same protocol as Phase 1/2: wave → parallel agents → gate → pass → checkpoint → next wave. Gate failure at 1× threshold. Commit/push after every gate. Nelson continuous LLM walkthroughs.

---

## Section 2: Quick Reference Table

| Wave | Name | Parallel Tracks | Gate | Key Deliverables |
|------|------|-----------------|------|------------------|
| **WAVE-0** | Pre-Flight (Audit + Module Splits + Architecture Docs) | 5 tracks | GATE-0 | Combat split (695→~445+~250), survival split (715→~365+~200+~150), crafting split (629→~430+~200), injuries split (556→~356+~200), creatures/init growth guard, GUID pre-assignment, test verification, **Brockman architecture docs** (creature-death-reshape.md, creature-inventory.md), Bart doc review |
| **WAVE-1** | Death Consequences (In-Place Reshape) | 3-4 tracks | GATE-1 | `reshape_instance()` engine function, `death_state` blocks on 5 creature files, template switch creature→object on death |
| **WAVE-2** | Creature Inventory + Loot Drops | 3-4 tracks | GATE-2 | Inventory metadata on creatures, death→room instantiation, meta-lint validation |
| **WAVE-3** | Full Food System + Cooking | 4-5 tracks | GATE-3 | `cook` verb, cookable eat check, food effects, food-poisoning injury, cooked-rat-meat, spoilage FSM, meat material |
| **WAVE-4** | Combat Polish + Cure System | 3-4 tracks | GATE-4 | `kick` verb, stress injury, cure mechanics, antidote objects, combat sound propagation |
| **WAVE-5** | Respawning + Design Docs + Polish | 3-4 tracks | GATE-5 | Respawn engine, respawn metadata, Phase 3 design docs (food-system.md, cure-system.md), final LLM walkthrough |

**Estimated new files:** ~25-30 (code + tests) + 4-6 doc files (5 fewer than v1.2 — dead-creature object files eliminated)
**Estimated modified files:** ~20-25 (engine modules, verbs, creature files, test runner, embedding index, synonym table)
**Estimated scope:** 6 waves (WAVE-0 through WAVE-5), 6 gates (GATE-0 through GATE-5)

---

## Section 3: Dependency Graph

```
WAVE-0: Pre-Flight (Audit + Module Splits + Architecture Docs)
├── [Bart]     Combat module split: init.lua (695 LOC) → init.lua + resolution.lua
├── [Bart]     Survival module split: survival.lua (715 LOC) → survival.lua + consumption.lua + rest.lua
├── [Bart]     Crafting module split: crafting.lua (629 LOC) → crafting.lua + cooking.lua
├── [Bart]     Injuries module split: injuries.lua (556 LOC) → injuries.lua + cure.lua
├── [Bart]     GUID pre-assignment for all new objects (~15 GUIDs)
├── [Brockman] Architecture docs: creature-death-reshape.md + creature-inventory.md
├── [Bart]     Review Brockman architecture docs for accuracy
└── [Nelson]   Verify 194 test files pass post-splits, register new test dirs
        │
        ▼  ── GATE-0 (all module splits verified, all 194 tests pass, architecture docs complete + reviewed) ──
        │
WAVE-1: Death Consequences (In-Place Reshape)
├── [Bart]     reshape_instance() engine function           ┐
├── [Flanders] death_state blocks on 5 creature files      │ parallel
├── [Flanders] meat.lua material                           │
└── [Nelson]   creature death → reshape tests              ┘
        │
        ▼  ── GATE-1 (kill creature → instance reshapes to object, portable, correct sensory) ──
        │
WAVE-2: Creature Inventory + Loot Drops
├── [Bart]     Inventory metadata → room instantiation    ┐
├── [Flanders] Inventory metadata on wolf + spider        │ parallel
├── [Flanders] Equipment objects for creature inventory   │
├── [Nelson]   Inventory + death drop tests               │
└── [Nelson]   Meta-lint: creature inventory validation   ┘
        │
        ▼  ── GATE-2 (creature dies → items scatter to room, reshaped instance in room, meta-lint passes) ──
        │
WAVE-3: Full Food System + Cooking
├── [Smithers] `cook` verb handler + aliases              ┐
├── [Smithers] Cookable check + food effects in eat verb  │
├── [Flanders] cooked-rat-meat.lua, food-poisoning.lua    │ parallel
├── [Flanders] grain-handful.lua, flatbread.lua           │
├── [Flanders] cellar-brazier.lua (fire_source object)    │
├── [Moe]      cellar.lua room update (brazier placement) │
├── [Nelson]   Cook + eat + spoilage tests                │
└── [Nelson]   LLM walkthrough: kill→cook→eat loop        ┘
        │
        ▼  ── GATE-3 (cook dead rat → cooked meat → eat → effects, spoilage ticks) ──
        │
        │  ═══ FOOD SYSTEM SHIPS (Brockman design docs in WAVE-5; architecture docs already shipped in WAVE-0) ═══
        │
WAVE-4: Combat Polish + Cure System
├── [Bart]     Cure mechanics in injury system            ┐
├── [Bart]     Combat sound propagation (engine/***)      │ parallel
├── [Smithers] `kick` verb → combat                       │
├── [Smithers] `emit_combat_sound()` narration API        │
├── [Flanders] antidote.lua object, healing-poultice cure metadata update │
└── [Nelson]   Kick + cure + sound tests                  ┘
        │
        ▼  ── GATE-4 (kick resolves, poultice cures rabies, antidote cures venom, sounds attract) ──
        │
WAVE-5: Respawning + Design Docs + Polish
├── [Bart]     Respawn engine (population manager)        ┐
├── [Flanders] Respawn metadata on creature definitions   │ parallel
├── [Smithers] Weapon combat metadata on existing weapons │
├── [Brockman] Phase 3 design docs (food-system.md, cure-system.md) │
├── [Nelson]   Respawn tests + final LLM walkthrough      ┘
        │
        ▼  ── GATE-5 (respawns work, docs complete, ZERO regressions) ──
        │
        ═══ PHASE 3 COMPLETE ═══
```

### Key Dependency Chain

```
Phase 2 ──→ W0 (splits) ──→ W1 (death) ──→ W2 (inventory) ──┐
                                  │                           │
                                  ├─────→ W3 (food) ←────────┘
                                  │                    (W3 needs reshaped corpse instances from W1;
                                  │                     W2 inventory data enriches corpse
                                  │                     containers but is not strictly required)
                                  ├─────→ W4 (combat+cure)
                                  │       (needs W0 combat split stable,
                                  │        independent of food/inventory)
                                  └─────→ W5 (respawn+docs)
                                          (needs creature death from W1,
                                           not food or inventory)
```

**Parallelization note:** After W1, waves W3/W4/W5 could theoretically run in parallel since they touch different files. The serial chain (W2→W3→W4→W5) is the conservative approach for gate quality — each gate validates the prior wave's output before building on it. If schedule pressure requires, W3+W4 can run in parallel after W2 since they have no file conflicts. W5 (respawn + docs) should remain last as the integration/polish wave.

---

## Section 4: Implementation Waves (Detailed)

### WAVE-0 — Pre-Flight (Audit + Module Splits + Architecture Docs)

**Goal:** Address ALL module size violations before building on them. Four engine modules currently breach or will breach the 500 LOC limit after Phase 3 additions. Pre-assign GUIDs for all Phase 3 objects. **Write architecture foundation docs before any WAVE-1 code** (Wayne directive: all affected docs in `docs/architecture/` must be updated in WAVE-0 before proceeding to WAVE-1).

**Critical Issue:** Multiple engine modules have grown past the 500 LOC guard from implementation-plan skill Pattern 13:

| File | Current LOC | Phase 3 Adds | Projected | % Over 500 | Split Required? |
|------|------------|-------------|-----------|-------------|-----------------|
| `combat/init.lua` | 695 | ~15 (sound) | ~710 | **42%** | ✅ YES |
| `verbs/survival.lua` | 715 | ~30 (eat effects) | ~745 | **49%** | ✅ YES |
| `verbs/crafting.lua` | 629 | ~50 (cook verb) | ~679 | **36%** | ✅ YES |
| `engine/injuries.lua` | 556 | ~40 (cure) | ~596 | **19%** | ✅ YES |
| `creatures/init.lua` | 466 | ~120 (W1+W2+W5) | ~586 | **17%** | ⚠️ GUARD |

All five must be addressed in WAVE-0 — building Phase 3 features on top of modules already in violation is unacceptable.

#### Assignments

| Agent | Task | Details |
|-------|------|---------|
| Bart | **Combat module split** | Extract damage resolution logic (~250 LOC) into `src/engine/combat/resolution.lua`. `init.lua` retains combat FSM orchestration, `resolution.lua` gets `resolve_damage()`, `resolve_exchange()`, layer penetration, severity mapping. Post-split: init.lua ~445, resolution.lua ~250. |
| Bart | **Survival module split** | Extract eat/drink handlers (~200 LOC) into `src/engine/verbs/consumption.lua`. Extract sleep/rest handlers (~150 LOC) into `src/engine/verbs/rest.lua`. `survival.lua` retains shelter, temperature, thirst checks. Post-split: survival.lua ~365, consumption.lua ~200, rest.lua ~150. |
| Bart | **Crafting module split** | Extract cook-related logic into `src/engine/verbs/cooking.lua` (~200 LOC). `crafting.lua` retains sew, repair, assemble. Post-split: crafting.lua ~430, cooking.lua ~200. WAVE-3 cook additions go to cooking.lua directly, never exceeding 500. |
| Bart | **Injuries module split** | Extract cure/healing logic (~200 LOC) into `src/engine/injuries/cure.lua`. `injuries.lua` retains infliction, FSM progression. Post-split: injuries.lua ~356, cure.lua ~200. WAVE-4 cure mechanics go to cure.lua. |
| Bart | **Creatures/init.lua growth guard** | Currently 466 LOC, projected 586 after Phase 3. Not yet over 500, but will be after WAVE-1+2+5 additions (~120 LOC). Add LOC check at GATE-2: if creatures/init.lua exceeds 500 LOC after WAVE-2, extract spawn/inventory logic into `creatures/inventory.lua` before WAVE-3. |
| Bart | **GUID pre-assignment** | Generate ~11 Windows GUIDs for: cooked-rat-meat, cooked-cat-meat, cooked-bat-meat, grain-handful, flatbread, food-poisoning injury, antidote, meat material, silk-bundle, cellar-brazier, gnawed-bone. Record in decision inbox. **Note:** 5 fewer GUIDs than v1.2 — dead-creature object GUIDs eliminated (no separate dead-rat.lua through dead-bat.lua). Creature instances retain their existing GUIDs through the reshape. Stress injury GUID deferred to Phase 4 (Q5 decision). |
| Nelson | **Test suite verification** | Run full suite post-splits, confirm 194 files pass. Register any new test dirs needed. |
| Brockman | **Architecture doc: creature-death-reshape.md** | Create `docs/architecture/engine/creature-death-reshape.md` (~500 words). Covers: D-14 in-place reshape pattern, `reshape_instance()` function API, `death_state` metadata block format, template switching (creature→small-item/furniture), GUID preservation, distinction from `mutation.mutate()` (file-swap), backward compatibility (creatures without death_state keep FSM dead state), inventory drop pipeline overview. |
| Brockman | **Architecture doc: creature-inventory.md** | Create `docs/architecture/engine/creature-inventory.md` (~300 words). Covers: inventory metadata format (hands/worn/carried), death drop instantiation to room floor, containment reuse for reshaped corpse containers, meta-lint validation rules (INV-01 through INV-04). |
| Bart | **Architecture doc review** | Review both Brockman architecture docs for technical accuracy against planned `reshape_instance()` implementation. Sign off that WAVE-1 code will match documented architecture. (~30 min) |

#### GATE-0 Criteria

- [x] `combat/init.lua` ≤ 500 LOC after split
- [x] `combat/resolution.lua` exists with clean interface
- [x] `verbs/survival.lua` ≤ 400 LOC after split
- [x] `verbs/consumption.lua` exists (eat/drink handlers)
- [x] `verbs/rest.lua` exists (sleep/rest handlers)
- [x] `verbs/crafting.lua` ≤ 450 LOC after split
- [x] `verbs/cooking.lua` exists (cook handler target for WAVE-3)
- [x] `engine/injuries.lua` ≤ 400 LOC after split
- [x] `engine/injuries/cure.lua` exists (cure path for WAVE-4)
- [x] All 194 test files pass (zero regressions)
- [x] GUIDs pre-assigned and recorded
- [x] `docs/architecture/engine/creature-death-reshape.md` exists and explains reshape_instance() pattern, D-14 alignment, death_state format, backward compat
- [x] `docs/architecture/engine/creature-inventory.md` exists and documents inventory metadata format, death drop pipeline, containment reuse
- [x] Bart has reviewed and signed off on both architecture docs
- [x] **Committed + tagged** before WAVE-1

---

### WAVE-1 — Death Consequences (In-Place Reshape)

**Goal:** When a creature's health reaches zero, the engine reshapes the creature instance in-place into a portable corpse object. The creature file itself contains ALL death state data — no separate dead-creature files exist. This is D-14 in its purest form: the instance transforms, same GUID, different shape.

**Design Source:** `plans/npc-combat/creature-inventory-plan.md` §4, `plans/food-system-plan.md` §5, Wayne directive (2026-03-27: in-place death reshape)

**Key Architecture Decision (v1.3 — Wayne directive):** Instead of file-swap mutation (`mutation.mutate()` to a separate `dead-rat.lua`), the engine **reshapes the creature instance in-place** using a new `reshape_instance()` function. Each creature file declares a `death_state` metadata block containing everything the dead version needs: new template, name, description, sensory text, food properties, container properties, and spoilage FSM. On death, the engine:
1. Switches the instance's template from "creature" to the `death_state.template` value ("small-item" or "furniture")
2. Overwrites descriptive/sensory properties from the `death_state` block
3. Deregisters the instance from the creature tick system
4. Registers the instance as a room object
5. Preserves the GUID (same instance, different shape)

**Why not `mutation.mutate()`?** `mutation.mutate()` swaps to a **different .lua file** — it replaces the instance's backing code. `reshape_instance()` transforms the **same instance** by applying a metadata overlay and switching the template. No new file is loaded. The creature code contains both its living and dead forms. This is a stronger D-14 pattern: the code declares all its possible shapes.

#### Engine Changes (Bart)

**New function:** `reshape_instance(instance, death_state)` in `src/engine/creatures/init.lua` (~60 LOC)

```lua
-- reshape_instance: transforms a creature instance into a dead object in-place
-- Called when creature health reaches 0 and death_state is declared
function M.reshape_instance(instance, death_state, registry, room)
    -- 1. Switch template
    instance.template = death_state.template  -- "small-item" or "furniture"

    -- 2. Overwrite identity properties
    instance.name = death_state.name
    instance.description = death_state.description
    instance.keywords = death_state.keywords
    instance.room_presence = death_state.room_presence

    -- 3. Overwrite sensory properties
    instance.on_feel = death_state.on_feel
    instance.on_smell = death_state.on_smell
    instance.on_listen = death_state.on_listen
    instance.on_taste = death_state.on_taste

    -- 4. Apply physical properties
    instance.portable = death_state.portable
    instance.size = death_state.size or instance.size
    instance.weight = death_state.weight or instance.weight
    instance.animate = false
    instance.alive = false

    -- 5. Apply food properties (if cookable)
    if death_state.food then
        instance.food = death_state.food
    end

    -- 6. Apply crafting properties (cook recipe)
    if death_state.crafting then
        instance.crafting = death_state.crafting
    end

    -- 7. Apply container properties
    if death_state.container then
        instance.container = death_state.container
    end

    -- 8. Apply spoilage FSM
    if death_state.states then
        instance.states = death_state.states
        instance.initial_state = death_state.initial_state or "fresh"
        instance._state = instance.initial_state
        instance.transitions = death_state.transitions
    end

    -- 9. Deregister from creature tick system
    M.deregister_creature(instance.guid)

    -- 10. Register as room object
    registry:register_as_room_object(instance, room)

    -- 11. Clear creature-only metadata (behavior, drives, reactions, combat, etc.)
    instance.behavior = nil
    instance.drives = nil
    instance.reactions = nil
    instance.movement = nil
    instance.awareness = nil
    instance.health = nil
    instance.max_health = nil
    instance.body_tree = nil
    instance.combat = nil
end
```

**File:** `src/engine/creatures/init.lua` — In the death handler (where creature health reaches 0):
- Check for `death_state` on the creature (not `mutations.die`)
- If present: call `reshape_instance()` to transform the instance in-place
- Emit `creature_died` stimulus (already exists in stimulus.lua)
- If `death_state.transfer_contents` is true, any future inventory transfers to the reshaped corpse
- If `death_state.byproducts` exists, instantiate byproducts to room floor (spider silk)

**Behavior without `death_state`:** Creatures that DON'T declare `death_state` keep existing behavior (FSM dead state). This is backward-compatible — no existing behavior changes.

#### Death Reshape Narration (Smithers review blocker fix)

**What the player sees when a creature dies and reshapes:**

The combat death handler already emits death narration (e.g., "The rat collapses, dead."). The reshape itself can optionally emit additional narration via the `reshape_narration` field in `death_state`:

```lua
-- Optional field in death_state:
reshape_narration = "The rat's body goes rigid, cooling in place.",
```

**Behavior:**
1. Combat handler prints combat death text (existing)
2. If `death_state.reshape_narration` is present, print it immediately after combat death text
3. If `death_state.reshape_narration` is nil, reshape is silent — player discovers the dead form on next `look` via `room_presence` text
4. The `room_presence` field in death_state (e.g., "A dead rat lies crumpled on the floor.") always appears in subsequent room descriptions regardless

**Design intent:** Silent reshape (no `reshape_narration`) is the default — less spammy, lets combat narration stand on its own. The field exists for creatures where the death transformation is dramatically interesting (e.g., a spider whose abdomen splits open, a wolf that crashes to the ground). Flanders decides per-creature whether to include it.

#### Creature File `death_state` Blocks (Flanders)

Instead of creating 5 separate dead-creature `.lua` files, Flanders adds a `death_state` metadata block to each creature file. This block contains EVERYTHING the dead version needs:

| Creature File | death_state.template | Portable? | Edible? | Container? | Key Properties |
|---------------|---------------------|-----------|---------|------------|----------------|
| `rat.lua` | small-item | Yes | Yes (cookable) | Yes (small — 1 capacity) | food.category=meat, food.raw=true, crafting.cook.becomes=cooked-rat-meat, spoilage FSM |
| `cat.lua` | small-item | Yes | Yes (cookable) | Yes (small — 2 capacity) | food.category=meat, food.raw=true, crafting.cook.becomes=cooked-cat-meat, larger than rat |
| `wolf.lua` | furniture | No (too large) | Yes (cookable, but requires butchery Phase 4) | Yes (medium — 5 capacity) | Too large to carry (portable=false), food.cookable=false (too big) |
| `spider.lua` | small-item | Yes | No (chitin) | No | Not edible — chitin exoskeleton. byproducts = { "silk-bundle" } |
| `bat.lua` | small-item | Yes | Yes (cookable) | No | food.category=meat, food.raw=true, crafting.cook.becomes=cooked-bat-meat, tiny |

**Example `death_state` block (rat.lua):**

```lua
-- Added inside rat.lua alongside existing living creature data
death_state = {
    template = "small-item",
    name = "a dead rat",
    description = "A dead rat lies on its side, legs splayed stiffly. Its fur is matted with blood and its beady eyes stare at nothing.",
    keywords = {"dead rat", "rat corpse", "rat carcass", "dead rodent", "rat"},
    room_presence = "A dead rat lies crumpled on the floor.",

    -- Physical
    portable = true,
    size = "tiny",
    weight = 0.3,

    -- Sensory (on_feel mandatory — primary dark sense)
    on_feel = "Cooling fur over a limp body. The tail hangs like wet string.",
    on_smell = "Blood and musk. The sharp copper of death.",
    on_listen = "Nothing. Absolutely nothing.",
    on_taste = "Fur and blood. You immediately regret this decision.",

    -- Food properties
    food = {
        category = "meat",
        raw = true,
        edible = false,        -- must cook first
        cookable = true,
    },

    -- Cooking recipe (read by cook verb)
    crafting = {
        cook = {
            becomes = "cooked-rat-meat",
            requires_tool = "fire_source",
            message = "You hold the rat over the flames. The fur singes away and the flesh darkens.",
            fail_message_no_tool = "You need a fire source to cook this.",
        },
    },

    -- Container (small corpse can hold 1 item)
    container = {
        capacity = 1,
        categories = { "tiny" },
    },

    -- Spoilage FSM
    initial_state = "fresh",
    states = {
        fresh = {
            description = "A freshly killed rat. The blood is still wet.",
            room_presence = "A dead rat lies crumpled on the floor.",
            duration = 30,
        },
        bloated = {
            description = "The rat's body has swollen, its belly distended with gas.",
            room_presence = "A bloated rat carcass lies on the floor, reeking.",
            on_smell = "The sweet, cloying stench of decay.",
            food = { cookable = false },
            duration = 40,
        },
        rotten = {
            description = "The rat is a putrid mess of matted fur and exposed tissue.",
            room_presence = "A rotting rat carcass festers on the floor.",
            on_smell = "Overwhelming rot. Your eyes water.",
            food = { cookable = false, edible = false },
            duration = 60,
        },
        bones = {
            description = "A tiny scatter of cleaned rat bones.",
            room_presence = "A small pile of rat bones sits on the floor.",
            on_smell = "Nothing — just dry bone.",
            on_feel = "Tiny, fragile bones. They click together.",
            food = nil,
        },
    },
    transitions = {
        { from = "fresh", to = "bloated", verb = "_tick", condition = "timer_expired" },
        { from = "bloated", to = "rotten", verb = "_tick", condition = "timer_expired" },
        { from = "rotten", to = "bones", verb = "_tick", condition = "timer_expired" },
    },

    transfer_contents = true,
},
```

**Sensory requirements:** Every `death_state` MUST have `on_feel` (primary dark sense), `on_smell` (blood/death/decay), `on_listen` (silence), full description, `room_presence` text. Spoilage FSM on edible corpses: fresh → bloated → rotten → bones (see food-system-plan.md §5).

**Material:** `meat.lua` — new material for raw animal flesh (density 1050, ignition 300, hardness 1).

#### Tests (Nelson)

| Test File | Coverage | Est. Tests |
|-----------|----------|------------|
| `test/creatures/test-creature-death-reshape.lua` | Kill each creature type → instance reshapes (template switches, sensory text updates, GUID preserved), creature removed from tick system, reshaped instance registered as room object | ~20 |
| `test/creatures/test-reshaped-corpse-properties.lua` | Reshaped creatures: portable (small), sensory text correct, edible where expected, container where expected, creature metadata cleared | ~20 |
| `test/food/test-corpse-spoilage.lua` | Reshaped rat spoilage FSM: fresh → bloated → rotten → bones, timer-driven | ~10 |

#### GATE-1 Criteria

- [x] Kill rat → rat instance reshapes to small-item template, same GUID preserved
- [x] Kill cat/wolf/spider/bat → each reshapes correctly per death_state
- [x] Reshaped rat is portable, examinable, has full sensory text from death_state
- [x] Reshaped wolf is NOT portable (template = furniture)
- [x] Reshaped rat spoilage FSM ticks correctly (fresh → bloated → rotten → bones)
- [x] Creature metadata cleared after reshape (behavior, drives, reactions, combat = nil)
- [x] Instance deregistered from creature tick system
- [x] Instance registered as room object
- [x] meat.lua material registered
- [x] Spider death → silk-bundle byproduct appears on room floor
- [x] Creatures WITHOUT death_state still use FSM dead state (backward compat)
- [x] All existing tests pass (zero regressions)
- [x] **Committed + tagged**

---

### WAVE-2 — Creature Inventory + Loot Drops

**Goal:** Creatures can declare items they carry. On death, inventory items instantiate to the room floor alongside the reshaped corpse instance.

**Design Source:** `plans/npc-combat/creature-inventory-plan.md` §2, §4, §6

#### Engine Changes (Bart)

**File:** `src/engine/creatures/init.lua` (~60 LOC addition)

1. **Inventory loading:** When creature spawns, validate `inventory` metadata (hands max 2, worn slots valid, carried items resolve to registry)
2. **Death drop:** When creature dies (reshape fires), iterate inventory → instantiate each item as room-floor object. Items become independent registry objects. The reshaped corpse instance is already in the room from WAVE-1's `reshape_instance()` — inventory items scatter alongside it.
3. **Sensory integration:** Worn equipment appears in creature `description` / `room_presence` text. "A wolf, something glinting at its feet." → when wolf dies, items drop.

**File:** `src/engine/creatures/init.lua` — creature tick must not double-process inventory items as room objects.

#### Inventory Metadata Format

```lua
-- On a creature .lua file
inventory = {
    hands = {},                          -- max 2 items (GUIDs)
    worn = {},                           -- slot → GUID mapping
    carried = {},                        -- array of GUIDs (loose items)
},
```

Phase 3 uses **direct GUID references** (Option A from creature-inventory-plan.md). Loot tables (Option B) deferred to Phase 4.

#### Creature Updates (Flanders)

| Creature | Inventory Additions | Rationale |
|----------|-------------------|-----------|
| wolf | `carried = { "gnawed-bone-01" }` | Wolves carry prey remains |
| spider | (none — silk is a death byproduct, not inventory) | See WAVE-1 `death_state.byproducts` below |
| rat | (none — rats carry nothing in Phase 3) | Keep simple |
| cat | (none) | Cats don't carry items |
| bat | (none) | Bats don't carry items |

**Spider silk as death reshape byproduct (not inventory):** Spiders don't *carry* silk — they *produce* it from spinnerets. Instead of modeling silk as inventory, the spider's `death_state` declaration includes a `byproducts` array. When the spider dies, `reshape_instance()` instantiates byproducts to the room floor alongside the reshaped corpse: `death_state.byproducts = { "silk-bundle" }`. Death narration: "The spider's abdomen splits, spilling a tangle of silk." This is cleaner than carried inventory and doesn't require WAVE-2 inventory mechanics — the silk drops in WAVE-1 via the death reshape path.

#### New Objects (Flanders)

| File | Description |
|------|-------------|
| `src/meta/objects/gnawed-bone.lua` | Small-item, wolf loot drop. Material: bone. Keywords: bone, gnawed bone. |
| `src/meta/objects/silk-bundle.lua` | Small-item, spider loot drop. Material: silk (or cotton as proxy). Keywords: silk, web silk, bundle. |

#### Meta-Lint Extension (Nelson)

Add creature inventory validation rules:

| Rule | Check |
|------|-------|
| INV-01 | `inventory.hands` has max 2 items |
| INV-02 | `inventory.worn` slots are valid (head, torso, arms, legs, feet) |
| INV-03 | Every GUID in inventory resolves to an object in registry |
| INV-04 | Carried items respect size constraints |

#### Tests (Nelson)

| Test File | Coverage | Est. Tests |
|-----------|----------|------------|
| `test/creatures/test-creature-inventory.lua` | Inventory loads, validates, wolf carries bone | ~15 |
| `test/creatures/test-death-drops.lua` | Kill wolf → bone appears on floor, kill spider → silk appears | ~15 |
| `test/creatures/test-inventory-edge-cases.lua` | Empty inventory, over-hand-limit validation, GUID resolution failure | ~10 |

#### GATE-2 Criteria

- [x] Wolf dies → gnawed-bone appears on room floor
- [x] Spider dies → silk-bundle appears on room floor
- [x] Creature with empty inventory → nothing drops (no crash)
- [x] Meta-lint INV-01 through INV-04 pass
- [x] Items are independent room objects post-drop (take, examine work)
- [x] Reshaped corpse and dropped items coexist in room correctly
- [x] All existing tests pass (zero regressions)
- [x] **Committed + tagged**

---

### WAVE-3 — Full Food System + Cooking

**Goal:** Complete the kill→cook→eat gameplay arc. The `cook` verb transforms raw food into cooked food via D-14 mutation. The cook target is the reshaped creature instance (now a small-item with `crafting.cook` metadata declared in the creature file's `death_state` block). Eating food applies effects. Spoiled food causes food poisoning.

**Design Source:** `plans/food-system-plan.md` §6, §7, §8, §12

#### Cook Verb Handler (Smithers)

**File:** `src/engine/verbs/crafting.lua` (~50 LOC addition)

```lua
handlers["cook"] = function(ctx, noun)
    -- 1. Find food in inventory or visible scope
    -- 2. Check food.crafting.cook exists
    -- 3. Find fire_source (visible tool search)
    -- 4. Perform mutation: raw → cooked via mutation.mutate()
    -- 5. Consume tool charge on fire source
    -- 6. Print recipe.message
end
handlers["roast"] = handlers["cook"]
handlers["bake"] = handlers["cook"]
handlers["grill"] = handlers["cook"]
```

Follows existing `sew` pattern in crafting.lua. Recipe declared on the food object (or the reshaped creature instance's `death_state.crafting` block), not in the verb handler (Principle 8). **Note:** The cook verb reads `obj.crafting.cook` — this works identically whether the object is a standalone `.lua` file (like grain-handful.lua) or a reshaped creature instance (where `crafting.cook` was applied by `reshape_instance()` from the creature's `death_state` block).

#### Eat Handler Extensions (Smithers)

**File:** `src/engine/verbs/survival.lua` (~30 LOC modification)

1. **Raw meat edible with consequences:** If `obj.cookable == true` and `obj.edible ~= true` and `obj.food.raw == true`, allow eating but inflict food-poisoning injury. Print warning from sensory text first: `obj.on_taste or "The raw flesh tastes foul."` then `"You choke it down. Your stomach rebels almost immediately."` If `obj.cookable == true` and `obj.food.raw ~= true` (e.g., raw grain), reject with hint: `obj.on_eat_reject or "You can't eat that raw. Try cooking it first."`
2. **Food effects pipeline:** After successful eat, process `obj.food.effects` array through existing effects pipeline. Supports: `narrate` (print message), `heal` (restore health), `inflict_injury` (food poisoning).

#### New Food Objects (Flanders)

| File | Type | Description |
|------|------|-------------|
| `src/meta/objects/cooked-rat-meat.lua` | small-item | Cooked rat meat. edible=true, nutrition=15, heal=3. |
| `src/meta/objects/cooked-cat-meat.lua` | small-item | Cooked cat meat. edible=true, nutrition=20, heal=4. |
| `src/meta/objects/cooked-bat-meat.lua` | small-item | Cooked bat meat. edible=true, nutrition=10, heal=2. food.risk=food-poisoning (10% — bat meat carries disease risk even when cooked). |
| `src/meta/objects/grain-handful.lua` | small-item | Raw grain. edible=false, cookable=true, cook_to=flatbread. |
| `src/meta/objects/flatbread.lua` | small-item | Baked flatbread. edible=true, nutrition=10. |
| `src/meta/injuries/food-poisoning.lua` | injury | Nausea + damage, moderate severity, 20-tick duration. |

#### Cellar Brazier Object + Room Placement (Flanders object, Moe room update)

**Object:** `src/meta/objects/cellar-brazier.lua` (Flanders, WAVE-3) — furniture, `fire_source=true`, emits light, warm to touch. Keywords: brazier, iron brazier, fire. Not portable (too heavy). Per Q3 resolution.

**Room placement:** `src/meta/world/cellar.lua` (Moe, WAVE-3) — Add brazier as a room-level instance in the cellar's `instances` array. The cellar description should reference "an iron brazier" to ground the object spatially. Brazier is room-level furniture (no `on_top`/`underneath` nesting). This ensures the fire source is available for WAVE-3 cook verb testing.

**Dead-cat cooking integration:** The cat creature file's `death_state.crafting` block already declares `cook = { becomes = "cooked-cat-meat", requires_tool = "fire_source", message = "You hold the cat over the flames. The fur blackens and curls away, leaving dark meat." }`. No separate file update needed — the cook verb reads `obj.crafting.cook` from the reshaped instance.

**Dead-bat cooking integration:** The bat creature file's `death_state.crafting` block already declares `cook = { becomes = "cooked-bat-meat", requires_tool = "fire_source", message = "You singe the bat's leathery wings over the fire. The meat underneath is thin but edible." }`. No separate file update needed.

#### Food Economy Balance Note

**Positive-sum requirement:** The kill→cook→eat loop MUST be net-positive for the player or nobody will cook. Specific numbers:

| Creature | Avg Damage Taken Killing | Cooked Nutrition | Cooked Heal | Net HP After Loop |
|----------|------------------------|-----------------|-------------|-------------------|
| rat | ~5 HP (2-3 exchanges) | 15 | +3 heal | **+3 net** (eat recovers more than damage taken) |
| cat | ~8 HP (3-4 exchanges) | 20 | +4 heal | **+4 net** (cat is harder but more rewarding) |
| bat | ~3 HP (1-2 exchanges) | 10 | +2 heal | **+2 net** (easy kill, small reward, disease risk) |

**Rule:** `cooked_food_heal >= average_damage_from_killing`. If playtesting shows the loop is net-negative (player loses more HP killing than gained eating), buff food heal values before GATE-3 closes. The entire point of Phase 3 is making this loop rewarding.

#### Dead-Rat Cooking Integration (Flanders)

The rat creature file's `death_state.crafting` block already declares the cook recipe (see WAVE-1 example). The cook verb reads `obj.crafting.cook` from the reshaped instance — no separate file update needed. For reference:

```lua
-- Already declared in rat.lua death_state (from WAVE-1):
crafting = {
    cook = {
        becomes = "cooked-rat-meat",
        requires_tool = "fire_source",
        message = "You hold the rat over the flames. The fur singes away and the flesh darkens.",
        fail_message_no_tool = "You need a fire source to cook this.",
    },
},
```

**Note:** The cook verb reads from `obj.crafting.cook` (following the `sew` pattern). When cooking a reshaped corpse, `mutation.mutate()` IS used to transform the dead-rat instance into `cooked-rat-meat.lua` — this is a legitimate file-swap mutation (the cooked meat is a genuinely new object type, not a reshape). Cooked meat objects (cooked-rat-meat.lua, cooked-cat-meat.lua, cooked-bat-meat.lua) are STILL separate `.lua` files — these are truly new objects with their own templates, not reshapes of the creature.

#### Tests (Nelson)

| Test File | Coverage | Est. Tests |
|-----------|----------|------------|
| `test/food/test-cook-verb.lua` | Cook dead-rat → cooked meat, cook grain → flatbread, cook without fire fails | ~15 |
| `test/food/test-eat-effects.lua` | Eat cooked meat → health restored, eat spoiled food → food poisoning | ~12 |
| `test/food/test-cookable-gating.lua` | Eat raw grain → rejection message, eat dead rat raw → risk message | ~8 |
| `test/food/test-food-poisoning.lua` | Food poisoning injury: infliction, FSM progression, recovery | ~10 |

#### Nelson LLM Walkthrough: Kill→Cook→Eat Loop

```bash
echo "attack rat\nlook\ntake dead rat\ncook rat\neat rat meat" | lua src/main.lua --headless
```

Expected: Rat dies → rat instance reshapes to dead-rat (same GUID) → player takes it → cooks over fire → eats cooked meat → nutrition effect.

#### GATE-3 Criteria

- [x] `cook dead rat` with fire source → produces cooked-rat-meat (via mutation.mutate, not reshape)
- [x] `cook grain` with fire source → produces flatbread
- [x] `cook dead rat` without fire → rejection message (reads death_state.crafting.cook.fail_message_no_tool)
- [x] `eat grain` (raw) → rejection with cooking hint
- [x] `eat cooked rat meat` → health effect applies
- [x] `eat` spoiled food → food-poisoning injury inflicted
- [x] Food-poisoning injury FSM progresses correctly
- [x] Full kill→cook→eat loop works in headless mode
- [x] Cellar brazier placed in cellar.lua (Moe) and functional as fire_source
- [x] All existing tests pass (zero regressions)
- [x] **Committed + tagged**

---

### WAVE-4 — Combat Polish + Cure System

**Goal:** Wire remaining combat verbs, make diseases curable, propagate combat sounds to attract creatures. ⚠️ Stress injury deferred to Phase 4 per Q5 decision.

**Design Sources:** `plans/npc-combat/combat-system-plan.md` §8.2 (verbs), §10.4 (rabies cure); `plans/npc-combat/npc-system-plan.md` §5.4 (stimuli)

#### Kick Verb (Smithers)

**File:** `src/engine/verbs/init.lua` (~2 LOC)

Currently `punch` routes to `hit` (line 481), but `kick` does not. Add:
```lua
handlers["kick"] = handlers["hit"]
```

This routes `kick rat` through the existing combat pipeline. The player's natural weapon selection in combat already resolves based on what's in the player's hands.

#### Cure Mechanics (Bart)

**File:** `src/engine/injuries.lua` (~40 LOC addition)

Add `healing_interactions` processing to the injury system:

1. When a healing object is applied to a patient (via `use poultice on wound`), check injury's `healing_interactions` table
2. If the healing object matches and the injury is in a curable state, transition to `cured`/`recovered`
3. If the injury is past the curable window (e.g., rabies in furious state), reject with message

**Metadata-driven:** Cure eligibility is declared on the injury definition (which states are curable and what cures them). No disease-specific engine code.

```lua
-- Already in rabies.lua design, needs implementation:
healing_interactions = {
    ["healing-poultice"] = {
        transitions_to = "cured",
        from_states = { "incubating", "prodromal" },
    },
},
```

#### Antidote Object (Flanders)

**File:** `src/meta/objects/antidote-vial.lua`

Small-item, liquid, cures spider-venom. Keywords: antidote, vial, cure. Placed in Level 1 (location TBD by Moe — study shelf or cellar cabinet).

Update `spider-venom.lua` injury with healing_interactions for antidote-vial.

#### Combat Sound Propagation (Bart)

**File:** `src/engine/combat/init.lua` (~15 LOC addition)

After combat narration phase (NARRATE), emit `loud_noise` stimulus to current room + adjacent rooms. This triggers creature reactions:
- Creatures in adjacent rooms may flee away from combat sounds
- Predators in adjacent rooms may investigate (approach)

Uses existing stimulus infrastructure from `creatures/stimulus.lua`. Sound propagation uses the room exit graph for adjacency — "acoustically adjacent" means connected by an exit. Smithers provides the narration API; Bart calls it from the engine.

#### Combat Sound Narration API (Smithers review blocker fix)

**Function:** `emit_combat_sound(room, intensity, witness_text)` in `src/engine/combat/narration.lua` (~20 LOC addition)

**Parameters:**
- `room` — origin room where combat occurs
- `intensity` — 0-10 scale (unarmed=3, weapon=6, creature-death=8)
- `witness_text` — template string for what the player hears

**Player-perspective narration by distance:**
1. **Same room (player in combat room):** No separate sound narration needed — combat narration already covers it. Adjacent creatures react (flee/investigate) silently from player's perspective.
2. **Adjacent room (1 exit away):** `"You hear violent sounds from the [direction]. Something crashes."` — the `[direction]` is resolved from the exit graph (e.g., "north", "below").
3. **2+ exits away:** No narration — sound doesn't propagate that far in Phase 3.

**Creature reaction narration (same or adjacent room):**
- Fleeing creature: `"[creature name] skitters away from the noise."` (if player can see it)
- Investigating predator: `"[creature name] perks up, drawn toward the sounds."` (if player can see it)

**Integration:** Bart emits `loud_noise` stimulus from `combat/init.lua` after NARRATE phase. The stimulus triggers creature reactions via `stimulus.lua`. Smithers adds narration templates to `combat/narration.lua` for player-facing text. Creature reactions use existing `stimulus.lua` → creature behavior pipeline.

#### Tests (Nelson)

| Test File | Coverage | Est. Tests |
|-----------|----------|------------|
| `test/verbs/test-kick-combat.lua` | kick rat → combat resolves, kick aliases work | ~5 |
| `test/injuries/test-cure-mechanics.lua` | Poultice cures rabies (early), rejects late rabies, antidote cures venom | ~15 |
| `test/combat/test-combat-sound.lua` | Combat emits loud_noise, adjacent creatures react | ~8 |

#### GATE-4 Criteria

- [ ] `kick rat` resolves through combat pipeline
- [ ] Healing poultice cures rabies in incubating/prodromal states
- [ ] Healing poultice FAILS to cure rabies in furious state
- [ ] Antidote cures spider venom
- [ ] Combat sounds attract/repel creatures in adjacent rooms
- [ ] `emit_combat_sound()` narration API implemented — player in adjacent room hears combat text
- [ ] All existing tests pass (zero regressions)
- [ ] **Committed + tagged**

---

### WAVE-5 — Respawning + Documentation + Polish

**Goal:** Prevent creature extinction via respawn timers. Complete Phase 3 documentation. Final LLM walkthrough.

**Design Source:** `plans/npc-combat/creature-inventory-plan.md` §11 Q5 (respawning)

#### Respawn Engine (Bart)

**File:** `src/engine/creatures/respawn.lua` (~100 LOC new module)

**Design:**
- Creatures with `respawn` metadata get tracked by the respawn manager
- When a creature dies, a respawn timer starts
- When the timer expires and the player is NOT in the creature's home room, a new instance spawns
- Population cap per room prevents infinite accumulation
- Respawn is a metadata declaration — no creature-specific engine code (Principle 8)

**Spawn position:** Creatures spawn as room-level objects with no spatial nesting. They are added directly to the room registry, equivalent to their original placement. No `on_top`, `underneath`, or other spatial sub-location applies to creatures. If Phase 4 ever adds creatures that nest (e.g., "rat under the barrel"), the respawn system would need spawn-point metadata — but for Phase 3, room-level is correct.

```lua
-- On creature .lua file
respawn = {
    timer = 100,              -- ticks until respawn
    home_room = "cellar",     -- where it respawns
    max_population = 2,       -- max creatures of this type per room
},
```

**File:** `src/engine/creatures/init.lua` (~20 LOC) — Wire respawn tick into creature_tick.

#### Creature Respawn Metadata (Flanders)

Add `respawn` table to all 5 creature definitions:

| Creature | Timer | Home Room | Max Pop | Notes |
|----------|-------|-----------|---------|-------|
| rat | 60 | cellar | 3 | Rats breed fast |
| cat | 120 | courtyard | 1 | Solitary |
| wolf | 200 | hallway | 1 | Territorial — one at a time |
| spider | 80 | deep-cellar | 2 | Web-builders repopulate |
| bat | 60 | crypt | 3 | Bats colony |

#### Weapon Combat Metadata (Smithers)

Add `combat` table to existing weapon objects so held weapons properly feed the combat resolution:

| Weapon | combat.type | combat.force | Notes |
|--------|-------------|-------------|-------|
| brass-candlestick | blunt | 4 | Improvised weapon |
| iron-poker (if exists) | blunt | 5 | Fireplace tool |
| letter-opener (if exists) | edged | 2 | Small blade |

This ensures `attack rat with candlestick` uses the candlestick's material properties (brass) in damage resolution rather than defaulting to natural weapons.

#### Documentation (Brockman — WAVE-5 design docs only)

**Note:** Architecture docs (`creature-death-reshape.md`, `creature-inventory.md`) are now written in **WAVE-0** (per Wayne directive). WAVE-5 Brockman scope is limited to **design docs** that document the completed food and cure systems after implementation + playtesting:

| Document | Location | Content |
|----------|----------|---------|
| `docs/design/food-system.md` | Design | Cook verb, edibility tiers, mutation chain (corpse→cooked meat), spoilage FSM, food effects, food economy balance |
| `docs/design/cure-system.md` | Design | Healing interactions metadata, cure eligibility, antidote pattern, disease-specific cure windows |

#### Pre-Flight Validation (Moe — before WAVE-5 respawn work)

**Task:** Verify all 5 `home_room` IDs exist in `src/meta/world/` before respawn implementation begins:
- [ ] `cellar` — exists (rat habitat)
- [ ] `courtyard` — exists (cat habitat)
- [ ] `hallway` — exists (wolf habitat)
- [ ] `deep-cellar` — verify exists or flag for creation
- [ ] `crypt` — verify exists or flag for creation

If any home_room is missing, Moe creates the room `.lua` file before WAVE-5 respawn work. Creature instances must be populated in the room's `instances` array.

#### Tests (Nelson)

| Test File | Coverage | Est. Tests |
|-----------|----------|------------|
| `test/creatures/test-respawn.lua` | Respawn timer, population cap, player-not-in-room check | ~15 |
| `test/creatures/test-respawn-edge-cases.lua` | No respawn metadata = no respawn, max pop reached, timer edge | ~10 |

#### Nelson Final LLM Walkthrough

Full Phase 3 gameplay loop in `--headless` mode:

```
> look                          # see room + creatures
> attack rat                    # combat → rat dies → rat instance reshapes to dead-rat (same GUID)
> take dead rat                 # portable corpse (reshaped instance)
> cook rat                      # near fire → cooked-rat-meat (file-swap mutation)
> eat rat meat                  # nutrition + healing effect
> attack wolf                   # wolf dies → reshapes to furniture, gnawed-bone drops
> take bone                     # loot from wolf corpse
> wait (×60)                    # rat respawns in home room
> go to cellar                  # new rat present
```

#### GATE-5 Criteria

- [ ] Dead rat respawns after timer expires (player not in room)
- [ ] Population cap prevents more than max_population creatures
- [ ] No respawn if player is in room (prevents "spawn in face" moments)
- [ ] Weapon combat metadata feeds damage resolution
- [ ] All 5 home_room IDs verified as existing rooms (Moe pre-flight)
- [ ] Design docs complete (food-system.md, cure-system.md)
- [ ] Full LLM walkthrough passes
- [ ] All tests pass (zero regressions)
- [ ] **Committed + tagged**

---

## Section 5: Testing Gates Summary

| Gate | After Wave | Test Count (Est.) | Key Validation |
|------|-----------|-------------------|----------------|
| GATE-0 | WAVE-0 | 204 (+10 compat) | Module splits work, no regressions |
| GATE-1 | WAVE-1 | ~264 (+50 + 10 compat) | Creature death → in-place reshape, template switch, GUID preserved |
| GATE-2 | WAVE-2 | ~309 (+40 + 10 compat) | Inventory loads, death drops work |
| GATE-3 | WAVE-3 | ~364 (+45 + 10 compat) | Cook→eat loop, food effects, spoilage |
| GATE-4 | WAVE-4 | ~412 (+38 + 10 compat) | Kick, stress, cure, combat sound |
| GATE-5 | WAVE-5 | ~437 (+25) | Respawning, weapon metadata, docs |

**Estimated total new test files:** ~25 (20 feature + 5 cross-wave compat)
**Estimated total new tests:** ~240

---

## Section 6: TDD Test File Map

| Test File | Wave | Module Tested | Est. Tests |
|-----------|------|---------------|------------|
| `test/creatures/test-creature-death-reshape.lua` | 1 | creatures/init.lua reshape_instance() | 20 |
| `test/creatures/test-reshaped-corpse-properties.lua` | 1 | reshaped creature instances | 20 |
| `test/food/test-corpse-spoilage.lua` | 1 | reshaped rat spoilage FSM | 10 |
| `test/creatures/test-creature-inventory.lua` | 2 | creatures/init.lua inventory | 15 |
| `test/creatures/test-death-drops.lua` | 2 | death → room instantiation | 15 |
| `test/creatures/test-inventory-edge-cases.lua` | 2 | validation, edge cases | 10 |
| `test/food/test-cook-verb.lua` | 3 | verbs/crafting.lua cook | 15 |
| `test/food/test-eat-effects.lua` | 3 | verbs/survival.lua effects | 12 |
| `test/food/test-cookable-gating.lua` | 3 | eat handler cookable check | 8 |
| `test/food/test-food-poisoning.lua` | 3 | food-poisoning injury | 10 |
| `test/verbs/test-kick-combat.lua` | 4 | verbs/init.lua kick alias | 5 |
| `test/injuries/test-cure-mechanics.lua` | 4 | injuries.lua cure path | 15 |
| `test/combat/test-combat-sound.lua` | 4 | combat sound propagation | 8 |
| `test/creatures/test-respawn.lua` | 5 | creatures/respawn.lua | 15 |
| `test/creatures/test-respawn-edge-cases.lua` | 5 | edge cases | 10 |

### Cross-Wave Compatibility Tests

Following the Phase 2 pattern (`test-wave1-2-compat.lua`, `test-wave2-3-compat.lua`, etc.), Phase 3 adds compatibility tests between every wave pair:

| Test File | After Gate | Validates | Est. Tests |
|-----------|-----------|-----------|------------|
| `test/creatures/test-p3-wave0-1-compat.lua` | GATE-0 | Split combat module still resolves damage correctly in creature death path; survival split preserves eat handler for W3 food effects; crafting split preserves sew pattern for W3 cook verb | 10 |
| `test/creatures/test-p3-wave1-2-compat.lua` | GATE-1 | Reshaped corpse instances from W1 are valid containers for W2 inventory drops; reshaped creatures with `container` in death_state pass containment validation | 10 |
| `test/food/test-p3-wave2-3-compat.lua` | GATE-2 | Reshaped creature instances carry `crafting.cook` metadata (from death_state) needed by W3 cook verb; reshaped rat/cat/bat all have `crafting.cook.becomes` pointing to valid target objects | 10 |
| `test/injuries/test-p3-wave3-4-compat.lua` | GATE-3 | Food-poisoning injury compatible with W4 cure mechanics pipeline; `healing_interactions` table structure matches cure engine expectations | 10 |
| `test/creatures/test-p3-wave4-5-compat.lua` | GATE-4 | Cured creatures can be targets for W5 respawn tracking; combat sound emission doesn't interfere with respawn timers | 10 |

---

## Section 7: File Ownership Summary

### New Files

| File | Owner | Wave | Type |
|------|-------|------|------|
| `src/engine/combat/resolution.lua` | Bart | 0 | Engine (extracted) |
| `src/engine/verbs/consumption.lua` | Bart | 0 | Engine (extracted from survival.lua) |
| `src/engine/verbs/rest.lua` | Bart | 0 | Engine (extracted from survival.lua) |
| `src/engine/verbs/cooking.lua` | Bart | 0 | Engine (extracted from crafting.lua) |
| `src/engine/injuries/cure.lua` | Bart | 0 | Engine (extracted from injuries.lua) |
| `src/engine/creatures/respawn.lua` | Bart | 5 | Engine |
| `src/meta/materials/meat.lua` | Flanders | 1 | Material |
| `src/meta/objects/gnawed-bone.lua` | Flanders | 2 | Object |
| `src/meta/objects/silk-bundle.lua` | Flanders | 1 | Object (death reshape byproduct) |
| `src/meta/objects/cooked-rat-meat.lua` | Flanders | 3 | Object |
| `src/meta/objects/cooked-cat-meat.lua` | Flanders | 3 | Object |
| `src/meta/objects/cooked-bat-meat.lua` | Flanders | 3 | Object |
| `src/meta/objects/grain-handful.lua` | Flanders | 3 | Object |
| `src/meta/objects/flatbread.lua` | Flanders | 3 | Object |
| `src/meta/injuries/food-poisoning.lua` | Flanders | 3 | Injury |
| `src/meta/objects/antidote-vial.lua` | Flanders | 4 | Object |
| `src/meta/objects/cellar-brazier.lua` | Flanders | 3 | Object (fire_source furniture) |
| `docs/architecture/engine/creature-death-reshape.md` | Brockman | 0 | Architecture doc |
| `docs/architecture/engine/creature-inventory.md` | Brockman | 0 | Architecture doc |
| `docs/design/food-system.md` | Brockman | 5 | Design doc |
| `docs/design/cure-system.md` | Brockman | 5 | Design doc |

### Modified Files

| File | Owner | Wave | Change |
|------|-------|------|--------|
| `src/engine/combat/init.lua` | Bart | 0, 4 | W0: extract resolution.lua; W4: sound emission |
| `src/engine/verbs/survival.lua` | Bart | 0 | W0: extract consumption.lua + rest.lua |
| `src/engine/verbs/crafting.lua` | Bart | 0 | W0: extract cooking.lua |
| `src/engine/injuries.lua` | Bart | 0 | W0: extract cure.lua |
| `src/engine/creatures/init.lua` | Bart | 1, 2, 5 | W1: reshape_instance() function + death_state wiring; W2: inventory processing; W5: respawn tick |
| `src/engine/verbs/cooking.lua` | Smithers | 3 | Cook verb handler (new file from W0 split) |
| `src/engine/verbs/consumption.lua` | Smithers | 3 | Cookable check + food effects in eat (new file from W0 split) |
| `src/engine/verbs/init.lua` | Smithers | 4 | Kick alias |
| `src/engine/parser/synonym_table.lua` | Smithers | 3 | Cook aliases (roast, bake, grill, sear, fry) |
| `src/assets/parser/embedding-index.json` | Smithers | 1-5 | ~100 new embedding phrases across all waves |
| `src/meta/creatures/rat.lua` | Flanders | 1, 5 | W1: death_state block; W5: respawn metadata |
| `src/meta/creatures/cat.lua` | Flanders | 1, 5 | W1: death_state block; W5: respawn metadata |
| `src/meta/creatures/wolf.lua` | Flanders | 1, 2, 5 | W1: death_state block; W2: inventory; W5: respawn |
| `src/meta/creatures/spider.lua` | Flanders | 1, 5 | W1: death_state block (with byproducts); W5: respawn |
| `src/meta/creatures/bat.lua` | Flanders | 1, 5 | W1: death_state block; W5: respawn |
| `src/meta/injuries/rabies.lua` | Flanders | 4 | Add healing_interactions |
| `src/meta/injuries/spider-venom.lua` | Flanders | 4 | Add healing_interactions |
| `test/run-tests.lua` | Nelson | 0 | Register new test dirs |
| `src/meta/world/cellar.lua` | Moe | 3 | Add cellar-brazier instance to room |
| `src/engine/combat/narration.lua` | Smithers | 4 | Add `emit_combat_sound()` narration templates |

### File Conflict Prevention

**No two agents touch the same file in any wave:**

| Wave | Bart Files | Flanders Files | Smithers Files | Brockman Files | Moe Files | Nelson Files |
|------|-----------|----------------|----------------|----------------|-----------|--------------|
| W0 | combat/init.lua, combat/resolution.lua, survival.lua, consumption.lua, rest.lua, crafting.lua, cooking.lua, injuries.lua, injuries/cure.lua | — | — | creature-death-reshape.md, creature-inventory.md | — | test/run-tests.lua |
| W1 | creatures/init.lua | silk-bundle.lua, meat.lua, creature files (death_state blocks) | embedding-index.json | — | — | test/creatures/*.lua |
| W2 | creatures/init.lua | creature files (inventory), gnawed-bone | embedding-index.json | — | — | test/creatures/*.lua |
| W3 | — | cooked-rat-meat, cooked-cat-meat, cooked-bat-meat, grain, flatbread, food-poisoning, cellar-brazier.lua | cooking.lua, consumption.lua, synonym_table.lua, embedding-index.json | — | cellar.lua (room update) | test/food/*.lua |
| W4 | injuries/cure.lua, combat/init.lua (sound) | antidote.lua, rabies.lua, spider-venom.lua | init.lua (kick), combat/narration.lua, embedding-index.json | — | — | test/ |
| W5 | creatures/respawn.lua, creatures/init.lua | creature files (respawn) | weapon objects, embedding-index.json | food-system.md, cure-system.md | home_room verification | test/creatures/*.lua |

**Note WAVE-0 additions (v1.4):** Brockman writes architecture docs in parallel with Bart's module splits. These are GATE-0 deliverables per Wayne directive. No file conflicts — Brockman writes to `docs/`, Bart writes to `src/engine/`.

**Note WAVE-3 additions (v1.4):** Moe updates cellar.lua to place the brazier instance. Flanders creates the brazier object. No conflict — different files.

**Note WAVE-4 ownership clarification:** Bart owns combat sound propagation (`combat/init.lua`) per `.squad/routing.md` (Bart owns `src/engine/**`). Smithers owns the `kick` alias in `verbs/init.lua`, `emit_combat_sound()` narration templates in `combat/narration.lua`, and embedding index updates. No file conflicts — Bart touches `combat/init.lua`, Smithers touches `combat/narration.lua`.

---

## Section 8: Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| **Combat module split breaks existing tests** | Medium | High | Comprehensive test run at GATE-0 before any feature work. Git tag for rollback. |
| **Death reshape path conflicts with existing FSM dead state** | Medium | High | Backward-compatible: only creatures WITH death_state use the new reshape path. Existing dead state still works for creatures without death_state. |
| **Reshaped instances retain stale creature metadata** | Low | Medium | reshape_instance() explicitly nils out creature-only fields (behavior, drives, reactions, combat, etc.). Test coverage validates cleanup. |
| **Cook verb collision with crafting.lua patterns** | Low | Medium | Follow existing `sew` pattern exactly — same structure, same mutation call, same tool resolution. |
| **Respawn timing feels wrong** | Medium | Medium | Tunable per-creature metadata. Playtest in LLM walkthroughs. Default timers conservative (60-200 ticks). |
| **Inventory instantiation order creates race conditions** | Low | Medium | Death drop happens in a single synchronous pass — iterate inventory, instantiate each item, THEN remove creature. |
| **food effects pipeline conflicts with existing eat handler** | Low | Medium | Effects processing is an additive extension — runs AFTER existing eat logic, doesn't replace it. |
| **crafting.lua LOC addressed in W0 split** | N/A | N/A | W0 splits crafting.lua → crafting.lua (~430) + cooking.lua (~200). Cook handler goes to cooking.lua, never exceeding 500. |

---

## Section 9: Autonomous Execution Protocol

Same as Phase 1/2:
- Wave → parallel agents → collect → gate → pass? → checkpoint → next wave
- Gate failure at 1× threshold → file GitHub issue, assign fix agent, re-gate
- Escalate to Wayne after 1× gate failure
- Commit/push after every gate
- Checkpoint plan doc after every wave (update status tracker)
- Nelson runs smoke-test LLM walkthrough after every wave
- Nelson runs full scenario suite at GATE-3 (food loop) and GATE-5 (final)

### Gate Failure Protocol

1. First failure: file GitHub issue with failure details, assign implementer to fix
2. Second failure (same gate): escalate to Wayne with options
3. Rollback available: Git tag per gate allows revert to known-good state

### Wave Checkpoint Protocol

After each wave:
1. Update Wave Status Tracker at top of this document
2. Record actual test count vs. estimate
3. Note any deviations from plan
4. Verify no LOC threshold violations in modified modules

---

## Section 10: Open Questions

These questions need Wayne's input before or during implementation.

### Q1: Corpse as Container vs. Scatter to Floor

**Question:** When a creature with inventory dies, should items scatter directly to the room floor, or should the corpse become a container the player must `search` / `open`?

**Options:**
| Option | Pros | Cons |
|--------|------|------|
| **A: Scatter to floor** | Simple, immediate, no new container mechanics needed | Clutters room description, loses context ("where did this sword come from?") |
| **B: Corpse as container** | Richer gameplay (loot corpse), cleaner room, enables grave-robbing | More engine work (corpse becomes searchable container), adds commands |
| **C: Hybrid** | Small items scatter, large items stay with corpse | Most realistic, but complex implementation |

**✅ RESOLVED — Wayne's Answer: Option B**

Player searches corpse to find items. Phase 3 reshaped corpse instances already have `container` set in death_state with capacity. The `search` verb already exists. Player types `search dead wolf` → sees inventory. `take sword from dead wolf` → gets it. Minimal engine work on top of WAVE-1 reshaped corpse instances.

---

### Q2: Creature Respawning — Timer-Based vs. Event-Based

**Question:** How should creatures respawn?

**Options:**
| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A: Timer-based** | Respawn N ticks after death when player not in room | Predictable, simple, testable | Feels mechanical, player can "camp" a spawn |
| **B: Event-based** | Respawn triggered by player leaving the area for N rooms/turns | More natural feeling | Harder to test, harder to predict |
| **C: Off-screen only** | Respawn only happens when player hasn't visited room in N turns | Most natural, prevents farming | May cause permanent extinction in frequently-visited areas |

**✅ RESOLVED — Wayne's Answer: CUSTOM**

**Respawning is per-creature metadata declared in the room .lua file.** Some creatures (like rats) respawn on a timer. Boss monsters are one-of-a-kind — once defeated, they don't reappear. This is NOT a global system. Each creature instance in the room file has a meta setting controlling whether it respawns.

- Rats (abundant): `respawn: { timer = 60, home_room = "cellar", max_population = 3 }`
- Wolf (territorial, solitary): `respawn: { timer = 200, home_room = "hallway", max_population = 1 }`
- Spider (web-builder): `respawn: { timer = 80, home_room = "deep-cellar", max_population = 2 }`
- Bat (colony): `respawn: { timer = 60, home_room = "crypt", max_population = 3 }`
- Cat (solitary predator): `respawn: { timer = 120, home_room = "courtyard", max_population = 1 }`

This design honors creature ecology (some reproduce, some are unique) while keeping implementation simple: each respawn is independent, tied to the creature instance metadata, not a global "respawn manager" decision.

**Implementation note:** Respawn respects the "player not in room" guard. If the player is currently in the creature's home room, respawn waits. This prevents "spawn in your face" moments and forces the player to leave and return.

---

### Q3: Fire Source for Cooking in Level 1

**Question:** Cooking requires `fire_source`. The kitchen hearth is in manor-kitchen (Level 2, blocked by D-KITCHEN-DOOR-TRAVERSAL). Where does the Level 1 fire source for cooking go?

**Options:**
| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A: Lit candle/match counts** | Existing lit candle has fire_source capability | Zero new objects needed | Physically absurd (cooking over a candle?) |
| **B: Cellar brazier** | New object: a small iron brazier in the cellar | Thematic (medieval), justifiable location | One more object to create |
| **C: Courtyard fire pit** | New object: outdoor fire pit or cooking fire | Outdoor cooking makes sense | Needs a room that supports it |

**✅ RESOLVED — Wayne's Answer: Option B**

New iron brazier object in the cellar. The cellar is a natural location for a fire source, and it's already a creature-dense room. Creates interesting gameplay: cook your rat kill right where you found it.

**Implementation:** `src/meta/objects/cellar-brazier.lua` (furniture, fire_source=true, emits light, warm to touch). The brazier is a room-level object, not inventory-able (too heavy).

---

### Q4: Dead Wolf — Portable or Furniture?

**Question:** Dead wolves are medium-sized. Should the corpse be portable (carry in hands) or furniture-sized (interact in place)?

**Options:**
| Option | Pros | Cons |
|--------|------|------|
| **A: Portable (large item)** | Player can drag it to fire, simpler interaction | Breaks physical plausibility (carrying a 35kg wolf?) |
| **B: Furniture (not portable)** | Realistic, forces in-place butchering | Requires butcher verb (Phase 4) to get meat, can't move |
| **C: Portable with encumbrance** | Carry but can't do anything else (both hands, movement penalty) | Most realistic but complex |

**✅ RESOLVED — Wayne's Answer: Option B**

Dead wolf is furniture (not portable). Stays where it died. Small creatures (rat/cat/bat/spider) are portable.

**Implementation Detail:**
- Dead rat/cat/bat: `small-item` template, portable=true (can pick up and carry)
- Dead wolf: `furniture` template, portable=false (stays in place, searchable on the ground)
- Dead spider: `small-item` template, portable=true (small creature)

---

### Q5: Stress Injury Scope

**Question:** How complex should the stress injury system be in Phase 3?

**Options:**
| Option | Tiers | Restricts | Complexity |
|--------|-------|-----------|------------|
| **A: Minimal (2-tier)** | shaken → recovered | precise_actions only | Low — ship it fast |
| **B: Full (3-tier)** | shaken → panicked → shell-shocked → recovered | precise + attack + movement | Medium — richer gameplay |
| **C: Deferred** | No stress in Phase 3 | — | Zero — ship it in Phase 4 |

**✅ RESOLVED — Wayne's Answer: Option C**

**Stress injury is DEFERRED to Phase 4. Remove stress from Phase 3 scope entirely.**

This decision simplifies WAVE-4 (Combat Polish) to focus on:
- `kick` verb wiring to combat
- Cure mechanics for rabies + spider venom
- Combat sound propagation (attracts creatures)
- Weapon combat metadata

Stress adds significant complexity with state restrictions (can't attack, can't move) that require extensive playtesting. Ship Phase 3 without it; expand in Phase 4 after live feedback.

---

### Q6: Loot Tables (Phase 3 or Phase 4?)

**Question:** Should Phase 3 implement probabilistic loot tables, or stick with fixed inventory only?

**Options:**
| Option | Scope | Pros | Cons |
|--------|-------|------|------|
| **A: Fixed only** | Creatures carry exact items declared in metadata | Simple, deterministic, testable | Less variety — every wolf drops the same bone |
| **B: Fixed + simple loot table** | Add `loot_table.on_death` with weighted probability | Adds variety without full system | More implementation work |

**✅ RESOLVED — Wayne's Answer: Option A**

Fixed inventory only. No loot tables in Phase 3. Fixed inventory is sufficient for 5 creatures. Loot tables add value when we have 20+ creature types and randomized dungeons — that's Phase 4 territory.

---

## Section 11: What We Deliberately Defer to Phase 4

| Feature | Why Deferred | Design Plan Reference |
|---------|-------------|----------------------|
| **Loot tables** (probabilistic drops) | Need more creature types to justify complexity | creature-inventory-plan.md §5 |
| **Butcher verb** (knife + corpse = meat + bones) | Only needed for medium+ corpses (wolf) | food-system-plan.md §16 Phase 3 |
| **Pack tactics** (coordinated wolf attacks) | Requires AI coordination system not yet designed | combat-system-plan.md §11 Phase 3 |
| **Wrestling/grapple** | Phase 3 of combat plan; rich feature, low priority | combat-system-plan.md §11 Phase 3 |
| **Environmental combat** (push barrel, slam door) | Requires object-in-combat interaction model | combat-system-plan.md §11 Phase 3 |
| **Weapon/armor degradation** | Fragility checks in combat add complexity | combat-system-plan.md §11 Phase 3 |
| **Humanoid NPCs** (dialogue, memory, quests) | Phase 4 of NPC plan — massive scope | npc-system-plan.md §9 Phase 4 |
| **Spider web creation** (creature-spawned objects) | Requires creature-creates-object engine pattern | npc-system-plan.md §9 Phase 3 |
| **Lycanthropy** | Requires humanoid NPCs | combat-system-plan.md §10.3 |
| **Multi-ingredient cooking** | Requires recipe system beyond single-item mutation | food-system-plan.md §16 Phase 3 |
| **Food preservation** (salting, smoking, drying) | Players will ask "how do I preserve food?" after discovering spoilage — explicitly deferred to Phase 4 to prevent scope creep | — |
| **Creature-to-creature looting** | Requires creature AI to evaluate loot value | creature-inventory-plan.md §8 Phase 3 |
| **Stress injury** | Complex cascading restrictions (can't attack, can't move) need extensive playtesting | Phase 4 — deferred per Q5 decision |

---

## Section 12: Lessons from Phase 2

Applied to Phase 3 planning:

1. **Module split before building** (Learned: combat/init.lua grew to 695 LOC, survival.lua to 715, crafting.lua to 629). WAVE-0 addresses ALL violations proactively — not just the worst one.
2. **GUID pre-assignment prevents collisions** (Learned: Phase 2 needed late GUID coordination). WAVE-0 generates all GUIDs upfront.
3. **Backward compatibility is non-negotiable** (Learned: death_state reshape path must not break existing FSM dead state). Opt-in design.
4. **Territorial dual-path** (Learned: test isolation vs. tick integration). New code must work both in isolation AND through the full tick pipeline.
5. **chunked plan writing** (Learned: Phase 2 opus crashed at 43 min). This plan is written as a single document (~30KB) since it's smaller scope than Phase 2's 70KB+.

---

## Appendix A: GUID Reservation Table

To be filled during WAVE-0 by Bart:

| Object | GUID | Status |
|--------|------|--------|
| ~~dead-rat.lua~~ | ELIMINATED (v1.3) | ~~No longer needed — creature instance retains its GUID through reshape~~ |
| ~~dead-cat.lua~~ | ELIMINATED (v1.3) | ~~No longer needed~~ |
| ~~dead-wolf.lua~~ | ELIMINATED (v1.3) | ~~No longer needed~~ |
| ~~dead-spider.lua~~ | ELIMINATED (v1.3) | ~~No longer needed~~ |
| ~~dead-bat.lua~~ | ELIMINATED (v1.3) | ~~No longer needed~~ |
| meat.lua (material) | TBD | — |
| gnawed-bone.lua | TBD | — |
| silk-bundle.lua | TBD | — |
| cooked-rat-meat.lua | TBD | — |
| cooked-cat-meat.lua | TBD | — |
| cooked-bat-meat.lua | TBD | — |
| grain-handful.lua | TBD | — |
| flatbread.lua | TBD | — |
| food-poisoning.lua | TBD | — |
| antidote-vial.lua | TBD | — |
| cellar-brazier.lua | TBD | — |

---

## Appendix B: Parser Integration Matrix

New nouns and keywords introduced per wave. **Embedding index updates owned by Smithers** (parallel-tracked per wave — without index updates, Tier 2 matching won't find new objects):

| Wave | New Nouns | Verb Aliases | Embedding Index Update | Owner |
|------|-----------|-------------|----------------------|-------|
| W1 | dead rat, rat corpse, carcass, dead cat, dead wolf, dead spider, dead bat | — | Yes: ~30 phrases (5 creature death_state keyword sets × 6 verb variants) | **Smithers** |
| W2 | gnawed bone, silk bundle, silk, web silk | — | Yes: ~12 phrases (loot item keywords) | **Smithers** |
| W3 | cooked rat meat, cooked cat meat, cooked bat meat, cooked meat, grain, barley, flatbread, bread | cook, roast, bake, grill, sear, fry | Yes: ~50 phrases (food keywords + "cook X" for all cookable objects) | **Smithers** |
| W4 | antidote, vial, cure | kick (alias to hit) | Minimal: ~6 phrases (antidote-vial) | **Smithers** |
| W5 | brazier (if Q3=B) | — | Yes: ~6 phrases (fire source) | **Smithers** |

**Synonym table updates (Smithers, WAVE-3):** Add to `src/engine/parser/synonym_table.lua`: `roast→cook, bake→cook, grill→cook, sear→cook, fry→cook`.

**Total: ~100 new embedding index phrases across all waves.**
