# NPC + Combat Phase 4 Implementation Plan

**Author:** Bart (Architecture Lead)
**Date:** 2026-08-16
**Version:** v1.0 (initial draft)
**Status:** 📝 DRAFT — Pending Wayne review
**Requested By:** Wayne "Effe" Berry
**Governs:** Phase 4: Butchery System → Loot Tables → Stress Injury → Spider Web Creation → Creature Crafting → Advanced Behaviors
**Predecessor:** `plans/npc-combat/npc-combat-implementation-phase3.md` (Phase 3 — ✅ COMPLETE, ~209 tests)

---

## Wave Status Tracker

| Wave | Name | Status | Gate | Tests |
|------|------|--------|------|-------|
| WAVE-0 | Pre-Flight (Audit + GUID Assignment + Architecture Docs) | ⏳ Pending | GATE-0 | ~209 |
| WAVE-1 | Butchery System | ⏳ Pending | GATE-1 | ~215 |
| WAVE-2 | Loot Tables Engine | ⏳ Pending | GATE-2 | ~223 |
| WAVE-3 | Stress Injury System | ⏳ Pending | GATE-3 | ~230 |
| WAVE-4 | Spider Ecology (Web Creation + Silk Crafting) | ⏳ Pending | GATE-4 | ~240 |
| WAVE-5 | Advanced Creature Behaviors + Docs + Polish | ⏳ Pending | GATE-5 | ~250 |

---

## Section 1: Executive Summary

Phase 4 completes the **resource processing loop** and introduces **advanced creature intelligence**. Phase 3 delivered the creature lifecycle (death → corpse → cook → eat) but left gaps: wolf corpses are furniture (too big to cook whole), creatures have fixed inventories (no variety), stress injury was deferred, spider silk drops but has no crafting use, and creature AI lacks coordination. Phase 4 closes these loops.

### What We're Building

1. **Butchery system** — `butcher` verb handler converts large corpses (wolf) into portable meat cuts + bones + hide using a knife. Solves the "wolf is too big to cook" problem identified in Phase 3. Enables full resource extraction from any creature.

2. **Loot tables engine** — Probabilistic creature drops with weighted rolls, quantity ranges, and conditional drops. Replaces fixed `inventory` GUIDs with `loot_table` metadata. Enables variety: each wolf drops different loot.

3. **Stress injury** — The third core injury type (alongside rabies, spider-venom). Inflicted by witnessing traumatic events (creature death, near-death combat). Causes debuffs (can't attack, movement penalty). Cured by rest + time.

4. **Spider web creation** — Spider creature can spawn objects (webs) in rooms. Establishes the `create_object` creature action pattern. Web objects trap small creatures (rat). Player can walk through (sticky but passable).

5. **Silk crafting** — Silk bundles (from dead spiders) can be crafted into useful items: silk-rope, silk-bandage. Requires `craft` verb extensions.

6. **Advanced creature behaviors** — Pack tactics (wolves coordinate attacks), territorial marking (wolf marks territory, other wolves respect it), ambush positioning (spider waits near web).

### Why This Order

Strict dependency chain: butchery must exist (WAVE-1) before loot tables can drop butchered components (WAVE-2), loot tables before stress injury (WAVE-3, which tests loot variety), spider webs require creature-creates-object engine pattern (WAVE-4), and advanced behaviors are polish (WAVE-5). WAVE-0 ensures module health and pre-assigns all Phase 4 GUIDs.

### Phase 4 Theme: "The Crafting Loop"

- **Phase 2 theme:** "Creatures exist and fight"
- **Phase 3 theme:** "Creatures die and become useful"
- **Phase 4 theme:** "Resources flow through the crafting pipeline"

The narrative arc: Player kills wolf → butchers corpse → gets wolf-meat + wolf-hide + wolf-bone → cooks meat, crafts hide into armor patch, uses bone as improvised weapon. The ecosystem becomes a resource production system.

### Phase 3 Foundation (Already Built)

| Asset | Location | LOC |
|-------|----------|-----|
| Creature engine | `src/engine/creatures/init.lua` | ~550 |
| Creature death reshape | `src/engine/creatures/death.lua` | ~120 |
| Combat engine | `src/engine/combat/init.lua` | ~445 |
| Combat resolution | `src/engine/combat/resolution.lua` | ~250 |
| Verbs: crafting | `src/engine/verbs/crafting.lua` | ~430 |
| Verbs: cooking | `src/engine/verbs/cooking.lua` | ~200 |
| Verbs: survival | `src/engine/verbs/survival.lua` | ~365 |
| Respawn engine | `src/engine/creatures/respawn.lua` | ~150 |
| 5 creatures | `src/meta/creatures/{rat,cat,wolf,spider,bat}.lua` | — |
| 9 injury types | `src/meta/injuries/` | — |
| Food objects | `src/meta/objects/{cooked-rat-meat,cooked-cat-meat,etc}.lua` | — |
| ~209 test files | `test/` | — |

### Walk-Away Capability

Same protocol as Phase 1/2/3: wave → parallel agents → gate → pass → checkpoint → next wave. Gate failure at 1× threshold. Commit/push after every gate. Nelson continuous LLM walkthroughs.

---

## Section 2: Quick Reference Table

| Wave | Name | Parallel Tracks | Gate | Key Deliverables |
|------|------|-----------------|------|------------------|
| **WAVE-0** | Pre-Flight (Audit + GUID Assignment + Architecture Docs) | 4 tracks | GATE-0 | LOC audit (all modules <500), GUID pre-assignment (~18 GUIDs), test verification, Brockman architecture docs (butchery-system.md, loot-tables.md) |
| **WAVE-1** | Butchery System | 4 tracks | GATE-1 | `butcher` verb handler, butchery_products metadata on creatures, wolf-meat/wolf-bone/wolf-hide objects, tool requirement (knife) |
| **WAVE-2** | Loot Tables Engine | 4 tracks | GATE-2 | `loot_table` metadata spec, weighted roll engine, loot instantiation on death, meta-lint for loot tables |
| **WAVE-3** | Stress Injury System | 4 tracks | GATE-3 | stress.lua injury type, trauma_trigger hooks, stress debuffs (attack penalty, flee bias), rest-based cure |
| **WAVE-4** | Spider Ecology (Web + Crafting) | 5 tracks | GATE-4 | `create_object` creature action, spider-web.lua object, web-trap mechanic, silk-rope + silk-bandage crafting, `craft` verb extensions |
| **WAVE-5** | Advanced Behaviors + Docs + Polish | 4 tracks | GATE-5 | Pack tactics (wolf coordination), territorial marking, ambush behavior, Phase 4 design docs, final LLM walkthrough |

**Estimated new files:** ~30-35 (code + tests) + 4-6 doc files
**Estimated modified files:** ~25-30 (engine modules, verbs, creature files, test runner, embedding index)
**Estimated scope:** 6 waves (WAVE-0 through WAVE-5), 6 gates (GATE-0 through GATE-5)

---

## Section 3: Dependency Graph

```
WAVE-0: Pre-Flight (Audit + GUID Assignment + Architecture Docs)
├── [Bart]     LOC audit: verify all modules <500 post-Phase 3
├── [Bart]     GUID pre-assignment for Phase 4 objects (~18 GUIDs)
├── [Brockman] Architecture docs: butchery-system.md, loot-tables.md
├── [Bart]     Review Brockman architecture docs for accuracy
└── [Nelson]   Verify ~209 test files pass, register new test dirs
        │
        ▼  ── GATE-0 (all modules healthy, GUIDs assigned, architecture docs complete) ──
        │
WAVE-1: Butchery System
├── [Smithers] `butcher` verb handler + aliases                    ┐
├── [Flanders] butchery_products metadata on wolf + spider         │ parallel
├── [Flanders] wolf-meat.lua, wolf-bone.lua, wolf-hide.lua objects │
├── [Flanders] butcher-knife.lua (tool with butchering capability) │
└── [Nelson]   Butchery tests (verb, tool requirement, products)   ┘
        │
        ▼  ── GATE-1 (butcher wolf → meat + bone + hide, requires knife) ──
        │
WAVE-2: Loot Tables Engine
├── [Bart]     Loot table engine (weighted rolls, instantiation)   ┐
├── [Bart]     loot_table metadata spec                            │ parallel
├── [Flanders] Convert wolf/spider inventory → loot_table          │
├── [Nelson]   Loot table tests (weights, ranges, conditionals)    │
└── [Nelson]   Meta-lint: loot_table validation rules              ┘
        │
        ▼  ── GATE-2 (creature death → weighted loot drops, meta-lint passes) ──
        │
WAVE-3: Stress Injury System
├── [Bart]     Trauma hooks in combat/creature-death               ┐
├── [Flanders] stress.lua injury type                              │ parallel
├── [Flanders] stress debuff effects (attack_penalty, flee_bias)   │
├── [Smithers] Stress narration integration                        │
└── [Nelson]   Stress tests (infliction, debuffs, cure via rest)   ┘
        │
        ▼  ── GATE-3 (witness death → stress infliction → debuffs → rest cure) ──
        │
WAVE-4: Spider Ecology (Web Creation + Silk Crafting)
├── [Bart]     `create_object` creature action engine              ┐
├── [Flanders] spider-web.lua object (trap mechanics)              │ parallel
├── [Flanders] silk-rope.lua, silk-bandage.lua craftable objects   │
├── [Smithers] `craft` verb extensions for silk recipes            │
├── [Moe]      Spider placement in cellar with web spawn points    │
└── [Nelson]   Web trap tests, silk crafting tests, LLM walkthrough┘
        │
        ▼  ── GATE-4 (spider creates web, web traps rat, silk→rope/bandage works) ──
        │
WAVE-5: Advanced Behaviors + Docs + Polish
├── [Bart]     Pack tactics engine (wolf coordination)             ┐
├── [Bart]     Territorial marking system                          │ parallel
├── [Bart]     Ambush behavior (spider web proximity)              │
├── [Brockman] Phase 4 design docs (crafting-system.md, etc.)      │
├── [Smithers] Weapon combat metadata on remaining weapons         │
└── [Nelson]   Behavior tests + final LLM walkthrough              ┘
        │
        ▼  ── GATE-5 (pack tactics work, docs complete, ZERO regressions) ──
        │
        ═══ PHASE 4 COMPLETE ═══
```

### Key Dependency Chain

```
Phase 3 ──→ W0 (audit) ──→ W1 (butchery) ──→ W2 (loot tables) ──┐
                                   │                              │
                                   ├─────→ W3 (stress) ←─────────┘
                                   │       (W3 can test varied loot)
                                   │
                                   ├─────→ W4 (spider ecology)
                                   │       (independent of W2/W3)
                                   │
                                   └─────→ W5 (behaviors + docs)
                                           (needs all prior waves stable)
```

**Parallelization note:** After W1, waves W2 and W4 could theoretically run in parallel since they touch different subsystems. The serial chain is the conservative approach. W3 (stress) needs W2's loot table tests but has minimal file overlap.

---

## Section 4: Implementation Waves (Detailed)

### WAVE-0 — Pre-Flight (Audit + GUID Assignment + Architecture Docs)

**Goal:** Verify Phase 3 left the engine healthy. Pre-assign all Phase 4 GUIDs. Write architecture foundation docs before WAVE-1 code.

#### Assignments

| Agent | Task | Details |
|-------|------|---------|
| Bart | **LOC audit** | Verify all engine modules remain <500 LOC after Phase 3. Expected healthy: combat/init.lua (~445), survival.lua (~365), crafting.lua (~430), creatures/init.lua (~550 — needs watch). If creatures/init.lua exceeds 500, propose butchery.lua extraction before WAVE-1. |
| Bart | **GUID pre-assignment** | Generate ~18 Windows GUIDs for Phase 4 objects: wolf-meat, wolf-bone, wolf-hide, wolf-pelt, butcher-knife, stress injury, spider-web, silk-rope, silk-bandage, territory-marker, wolf-pack-alpha, wolf-pack-beta, etc. Record in decision inbox. |
| Brockman | **Architecture docs** | Write `docs/architecture/engine/butchery-system.md` (butchery pipeline, tool requirements, product metadata) and `docs/architecture/engine/loot-tables.md` (weighted roll algorithm, metadata spec, instantiation flow). |
| Bart | **Doc review** | Review Brockman's architecture docs for technical accuracy before GATE-0 sign-off. |
| Nelson | **Test verification** | Run `lua test/run-tests.lua`, verify ~209 tests pass. Register `test/butchery/`, `test/loot/`, `test/stress/` directories in test runner. |

#### Files Modified/Created

| File | Agent | Action |
|------|-------|--------|
| `docs/architecture/engine/butchery-system.md` | Brockman | CREATE |
| `docs/architecture/engine/loot-tables.md` | Brockman | CREATE |
| `test/run-tests.lua` | Nelson | MODIFY (register new dirs) |
| `.squad/decisions/inbox/bart-phase4-guids.md` | Bart | CREATE |

#### GATE-0 Criteria

- [ ] All engine modules <500 LOC (or split plan documented)
- [ ] ~18 GUIDs pre-assigned and recorded
- [ ] `docs/architecture/engine/butchery-system.md` exists and reviewed ✓
- [ ] `docs/architecture/engine/loot-tables.md` exists and reviewed ✓
- [ ] `lua test/run-tests.lua` — ~209 tests pass, new dirs registered
- [ ] Git commit: `chore: Phase 4 WAVE-0 pre-flight complete`

---

### WAVE-1 — Butchery System

**Goal:** Enable large corpse processing. Wolf corpses (furniture template, not portable) can be butchered into portable meat/bone/hide using a knife.

#### The Problem

From Phase 3: wolf death reshapes the instance to furniture template (not portable). Player cannot pick up wolf corpse, cannot cook it directly (too big), cannot extract resources. The wolf corpse is a dead-end asset.

**Solution:** `butcher` verb with knife tool requirement converts wolf corpse into portable products.

#### Butchery Metadata Spec

Each creature with `death_state` can declare `butchery_products`:

```lua
-- In wolf.lua death_state block
death_state = {
    template = "furniture",  -- too big to carry
    portable = false,
    -- ... existing death_state fields ...

    -- NEW: butchery products
    butchery_products = {
        requires_tool = "butchering",  -- capability, not ID
        duration = "5 minutes",        -- game time
        products = {
            { id = "wolf-meat", quantity = 3 },
            { id = "wolf-bone", quantity = 2 },
            { id = "wolf-hide", quantity = 1 },
        },
        narration = {
            start = "You begin carving the wolf carcass...",
            complete = "You finish butchering the wolf. Meat, bones, and hide lie at your feet.",
        },
        removes_corpse = true,  -- corpse disappears after butchering
    },
},
```

#### Butcher Verb Handler

```lua
-- src/engine/verbs/crafting.lua (or new butchery.lua if split)
verbs.butcher = function(ctx, noun)
    local target = resolve_object(ctx, noun)
    if not target then return err_not_found(ctx) end

    -- Must be a dead creature (reshaped)
    if not target.death_state or not target.is_corpse then
        return ctx.print("You can't butcher that.")
    end

    -- Must have butchery_products declared
    local butch = target.death_state.butchery_products
    if not butch then
        return ctx.print("There's nothing useful to carve from this corpse.")
    end

    -- Tool check: player needs butchering capability
    local tool = ctx.player:find_tool_with_capability(butch.requires_tool)
    if not tool then
        return ctx.print("You need a knife to butcher this.")
    end

    -- Execute butchery
    ctx.print(butch.narration.start)
    
    -- Instantiate products into room
    for _, prod in ipairs(butch.products) do
        for i = 1, prod.quantity do
            local instance = registry:instantiate(prod.id)
            ctx.room:add_object(instance)
        end
    end

    -- Remove corpse if specified
    if butch.removes_corpse then
        ctx.room:remove_object(target)
        registry:deregister(target.guid)
    end

    ctx.print(butch.narration.complete)
end
```

#### Assignments

| Agent | Task | Details |
|-------|------|---------|
| Smithers | **`butcher` verb handler** | Implement verb in crafting.lua (or butchery.lua if split in WAVE-0). Aliases: `carve`, `skin`, `fillet`. Tool capability check for "butchering". |
| Flanders | **butchery_products on wolf** | Add `death_state.butchery_products` block to `src/meta/creatures/wolf.lua`. 3 meat, 2 bone, 1 hide. Duration 5 min. |
| Flanders | **butchery_products on spider** | Add to `src/meta/creatures/spider.lua`. Products: 1 spider-meat (poison risk!), 1 silk-bundle (already exists from Phase 3). |
| Flanders | **wolf-meat.lua** | Cookable small-item. Nutrition 35, heal 8. Similar to cooked-rat-meat but raw. FSM: raw → cooked. |
| Flanders | **wolf-bone.lua** | Small-item. Can be used as improvised weapon (blunt, force 3). Material: bone. |
| Flanders | **wolf-hide.lua** | Small-item. Crafting material for armor repairs (Phase 5+). Material: hide. |
| Flanders | **butcher-knife.lua** | Tool object. Capabilities: `butchering`, `cutting`. Keywords: knife, butcher knife, carving knife. |
| Nelson | **Butchery tests** | `test/butchery/test-butcher-verb.lua` (verb resolution, tool requirement, product instantiation). `test/butchery/test-butchery-products.lua` (wolf products, spider products). ~6 tests. |

#### Files Created/Modified

| File | Agent | Action |
|------|-------|--------|
| `src/engine/verbs/crafting.lua` | Smithers | MODIFY (add butcher verb) |
| `src/meta/creatures/wolf.lua` | Flanders | MODIFY (add butchery_products) |
| `src/meta/creatures/spider.lua` | Flanders | MODIFY (add butchery_products) |
| `src/meta/objects/wolf-meat.lua` | Flanders | CREATE |
| `src/meta/objects/wolf-bone.lua` | Flanders | CREATE |
| `src/meta/objects/wolf-hide.lua` | Flanders | CREATE |
| `src/meta/objects/butcher-knife.lua` | Flanders | CREATE |
| `test/butchery/test-butcher-verb.lua` | Nelson | CREATE |
| `test/butchery/test-butchery-products.lua` | Nelson | CREATE |
| `src/engine/parser/embedding-index.json` | Smithers | MODIFY (butcher aliases) |

#### GATE-1 Criteria

- [ ] `butcher wolf` with knife → produces wolf-meat (×3), wolf-bone (×2), wolf-hide (×1)
- [ ] `butcher wolf` without knife → error: "You need a knife"
- [ ] `butcher rat` → error (rat is small-item, not furniture; can be cooked directly)
- [ ] wolf-meat can be cooked with existing `cook` verb
- [ ] butcher-knife recognized by parser, has butchering capability
- [ ] `lua test/run-tests.lua` — ~215 tests pass
- [ ] Git commit: `feat: butchery system (WAVE-1)`

---

### WAVE-2 — Loot Tables Engine

**Goal:** Replace fixed creature inventories with probabilistic loot tables. Enable variety in creature drops.

#### The Problem

From Phase 3 Q6 decision: "Fixed inventory only. Loot tables add value when we have 20+ creature types and randomized dungeons — that's Phase 4 territory."

Phase 4 is that territory. With butchery products (WAVE-1), loot tables enable interesting combinations: wolf might drop gnawed-bone OR silver-coin OR nothing.

#### Loot Table Metadata Spec

From `creature-inventory-plan.md` Section 5.3, adapted for Phase 4:

```lua
-- In wolf.lua (replaces fixed inventory)
loot_table = {
    -- Always drop (100% chance)
    always = {
        { template = "gnawed-bone" },
    },

    -- Weighted roll on death (pick one)
    on_death = {
        { item = { template = "silver-coin" }, weight = 20 },
        { item = { template = "torn-cloth" }, weight = 30 },
        { item = nil, weight = 50 },  -- 50% chance nothing
    },

    -- Quantity rolls (e.g., 1-3 coins)
    variable = {
        { template = "copper-coin", min = 0, max = 3 },
    },

    -- Conditional drops (based on kill method)
    conditional = {
        fire_kill = { { template = "charred-hide" } },
        poison_kill = { { template = "tainted-meat" } },
    },
},
```

#### Loot Engine Design

```lua
-- src/engine/creatures/loot.lua (NEW)
local M = {}

function M.roll_loot_table(creature, death_context)
    local loot = creature.loot_table
    if not loot then return {} end

    local drops = {}

    -- Always drops
    for _, item in ipairs(loot.always or {}) do
        table.insert(drops, { template = item.template, quantity = item.quantity or 1 })
    end

    -- Weighted roll
    if loot.on_death then
        local roll = M.weighted_select(loot.on_death)
        if roll and roll.item then
            table.insert(drops, { template = roll.item.template, quantity = 1 })
        end
    end

    -- Variable quantity
    for _, v in ipairs(loot.variable or {}) do
        local qty = math.random(v.min, v.max)
        if qty > 0 then
            table.insert(drops, { template = v.template, quantity = qty })
        end
    end

    -- Conditional
    if death_context and death_context.kill_method then
        local cond = loot.conditional and loot.conditional[death_context.kill_method]
        if cond then
            for _, item in ipairs(cond) do
                table.insert(drops, { template = item.template, quantity = 1 })
            end
        end
    end

    return drops
end

function M.weighted_select(options)
    local total = 0
    for _, opt in ipairs(options) do
        total = total + opt.weight
    end
    local roll = math.random() * total
    local cumulative = 0
    for _, opt in ipairs(options) do
        cumulative = cumulative + opt.weight
        if roll <= cumulative then
            return opt
        end
    end
    return options[#options]
end

return M
```

#### Assignments

| Agent | Task | Details |
|-------|------|---------|
| Bart | **Loot engine** | Create `src/engine/creatures/loot.lua` (~100 LOC). `roll_loot_table()`, `weighted_select()`, `instantiate_drops()`. Integrate with `reshape_instance()` death path. |
| Bart | **loot_table spec** | Document metadata format in `docs/architecture/engine/loot-tables.md` (already created in WAVE-0). |
| Flanders | **Convert wolf** | Replace wolf `inventory` with `loot_table`. Always: gnawed-bone. On_death: 20% silver-coin, 30% torn-cloth, 50% nothing. |
| Flanders | **Convert spider** | Spider `loot_table`. Always: silk-bundle. On_death: 10% spider-fang (new object, poison weapon component). |
| Flanders | **spider-fang.lua** | Small-item. Poison component for future weapon crafting. Material: tooth-enamel. |
| Nelson | **Loot table tests** | `test/loot/test-loot-engine.lua` (weighted_select, roll_loot_table). `test/loot/test-loot-integration.lua` (kill wolf → drops appear). ~8 tests with deterministic seed. |
| Nelson | **Meta-lint rules** | Add LOOT-001 through LOOT-005: validate loot_table structure, weight sums, template refs. |

#### Files Created/Modified

| File | Agent | Action |
|------|-------|--------|
| `src/engine/creatures/loot.lua` | Bart | CREATE |
| `src/engine/creatures/death.lua` | Bart | MODIFY (integrate loot engine) |
| `src/meta/creatures/wolf.lua` | Flanders | MODIFY (inventory → loot_table) |
| `src/meta/creatures/spider.lua` | Flanders | MODIFY (inventory → loot_table) |
| `src/meta/objects/spider-fang.lua` | Flanders | CREATE |
| `test/loot/test-loot-engine.lua` | Nelson | CREATE |
| `test/loot/test-loot-integration.lua` | Nelson | CREATE |
| `scripts/meta-lint/rules/loot.lua` | Nelson | CREATE |

#### GATE-2 Criteria

- [ ] Kill wolf 10 times (deterministic seed) → verify weighted distribution matches spec
- [ ] Wolf always drops gnawed-bone
- [ ] Spider always drops silk-bundle
- [ ] Spider 10% chance drops spider-fang
- [ ] Loot appears in room after death (not inside corpse)
- [ ] Meta-lint passes on all creature files with loot_table
- [ ] `lua test/run-tests.lua` — ~223 tests pass
- [ ] Git commit: `feat: loot tables engine (WAVE-2)`

---

### WAVE-3 — Stress Injury System

**Goal:** Introduce psychological damage. Witnessing traumatic events inflicts stress injury with gameplay-affecting debuffs.

#### The Problem

From Phase 3 Q5 decision: "Stress adds significant complexity with state restrictions (can't attack, can't move) that require extensive playtesting. Ship Phase 3 without it; expand in Phase 4 after live feedback."

Phase 4 is the expansion. Stress completes the injury triad: physical (cuts, bites), disease (rabies, venom), psychological (stress).

#### Stress Injury Spec

```lua
-- src/meta/injuries/stress.lua
return {
    guid = "{assigned-in-WAVE-0}",
    template = "injury",
    id = "stress",
    name = "acute stress",
    category = "psychological",

    -- Severity levels
    levels = {
        { name = "shaken", threshold = 1, description = "Your hands tremble slightly." },
        { name = "distressed", threshold = 3, description = "You're breathing hard, heart pounding." },
        { name = "overwhelmed", threshold = 5, description = "Panic grips you. Everything feels wrong." },
    },

    -- Effects at each level
    effects = {
        shaken = { attack_penalty = -1 },
        distressed = { attack_penalty = -2, flee_bias = 0.2 },
        overwhelmed = { attack_penalty = -4, flee_bias = 0.5, movement_penalty = 0.5 },
    },

    -- Cure conditions
    cure = {
        method = "rest",
        duration = "2 hours",  -- game time
        requires = { safe_room = true },  -- no creatures in room
        description = "With time and safety, the panic subsides.",
    },

    -- Stress sources (trauma triggers)
    triggers = {
        witness_creature_death = 1,      -- +1 stress per witnessed death
        near_death_combat = 2,           -- +2 stress when health < 10%
        player_first_kill = 3,           -- +3 stress on first kill (one-time)
        witness_gore = 1,                -- +1 stress seeing butchery
    },
},
```

#### Trauma Hook Design

```lua
-- Integration points in engine
-- In src/engine/creatures/death.lua
local function on_creature_death(creature, killer, ctx)
    -- ... existing death logic ...

    -- Trauma hook: player witnessed death
    if ctx.player.room == creature.room then
        local stress = require("src.engine.injuries").get("stress")
        stress.add(ctx.player, "witness_creature_death")
    end
end

-- In src/engine/combat/init.lua
local function on_combat_resolved(attacker, defender, result, ctx)
    -- Near-death check
    if defender == ctx.player and ctx.player.health < ctx.player.max_health * 0.1 then
        local stress = require("src.engine.injuries").get("stress")
        stress.add(ctx.player, "near_death_combat")
    end
end
```

#### Assignments

| Agent | Task | Details |
|-------|------|---------|
| Bart | **Trauma hooks** | Add stress trigger points in `creatures/death.lua`, `combat/init.lua`. Create `injuries.add_stress()` convenience function. |
| Bart | **Stress debuff application** | Integrate stress effects with combat resolution (attack_penalty) and movement (movement_penalty). |
| Flanders | **stress.lua injury** | Create injury definition with 3 levels, effects per level, cure conditions. |
| Smithers | **Stress narration** | Add stress-level narration to status output. "You feel shaken." / "Panic rises." UI integration for stress indicator. |
| Nelson | **Stress tests** | `test/stress/test-stress-infliction.lua` (trigger → stress gain). `test/stress/test-stress-debuffs.lua` (attack penalty, flee bias). `test/stress/test-stress-cure.lua` (rest in safe room). ~7 tests. |

#### Files Created/Modified

| File | Agent | Action |
|------|-------|--------|
| `src/meta/injuries/stress.lua` | Flanders | CREATE |
| `src/engine/injuries.lua` | Bart | MODIFY (add stress system) |
| `src/engine/creatures/death.lua` | Bart | MODIFY (trauma hooks) |
| `src/engine/combat/init.lua` | Bart | MODIFY (near-death trauma) |
| `src/engine/ui/status.lua` | Smithers | MODIFY (stress indicator) |
| `test/stress/test-stress-infliction.lua` | Nelson | CREATE |
| `test/stress/test-stress-debuffs.lua` | Nelson | CREATE |
| `test/stress/test-stress-cure.lua` | Nelson | CREATE |

#### GATE-3 Criteria

- [ ] Witness creature death → player gains +1 stress
- [ ] Near-death combat (health < 10%) → player gains +2 stress
- [ ] Stress level "shaken" → -1 attack penalty (verified in combat)
- [ ] Stress level "overwhelmed" → -4 attack, +50% flee bias, 50% movement penalty
- [ ] Rest in safe room for 2 hours → stress cured
- [ ] Stress visible in status output
- [ ] `lua test/run-tests.lua` — ~230 tests pass
- [ ] Git commit: `feat: stress injury system (WAVE-3)`

---

### WAVE-4 — Spider Ecology (Web Creation + Silk Crafting)

**Goal:** Enable creature-created objects. Spider can spawn webs. Silk bundles can be crafted into useful items.

#### The Problem

From Phase 3 deferred: "Spider web creation (creature-spawned objects) — Requires creature-creates-object engine pattern."

This establishes a reusable pattern for any creature that creates environmental objects (bird nests, ant tunnels, future).

#### Create Object Action Design

```lua
-- In src/engine/creatures/init.lua action dispatch
actions = {
    -- ... existing actions ...
    create_object = function(creature, ctx)
        local obj_template = creature.behavior.creates_object
        if not obj_template then return end
        
        -- Check creation conditions
        if obj_template.cooldown and creature._last_creation then
            local elapsed = ctx.game_time - creature._last_creation
            if elapsed < obj_template.cooldown then return end
        end
        
        -- Instantiate object in creature's room
        local instance = registry:instantiate(obj_template.template)
        instance.creator = creature.guid  -- track creator
        ctx.room:add_object(instance)
        creature._last_creation = ctx.game_time
        
        -- Narration
        if obj_template.narration then
            ctx.print(obj_template.narration)
        end
    end,
}
```

#### Spider Web Mechanics

```lua
-- src/meta/objects/spider-web.lua
return {
    guid = "{assigned-in-WAVE-0}",
    template = "small-item",
    id = "spider-web",
    name = "a sticky spider web",
    keywords = {"web", "spider web", "cobweb", "silk"},
    description = "Glistening threads span the corner, sticky to the touch.",
    on_feel = "Tacky, clinging strands. They stick to your fingers.",
    
    material = "silk",
    
    -- Trap mechanic
    trap = {
        active = true,
        affects_sizes = {"tiny", "small"},  -- rat, spider, bat (not player, cat, wolf)
        effect = "immobilize",
        escape_difficulty = 3,  -- 1-5 scale
        message_trigger = "Something skitters into the web and struggles.",
        message_escape = "It tears free of the web.",
    },
    
    -- Player interaction
    passable = true,  -- player can walk through
    on_enter = "You brush through the sticky web. Threads cling to your clothes.",
}
```

#### Spider Behavior Extension

```lua
-- In spider.lua behavior
behavior = {
    -- ... existing drives, states, reactions ...
    
    creates_object = {
        template = "spider-web",
        cooldown = "30 minutes",  -- game time
        condition = function(creature, ctx)
            -- Only create web if none in room
            local webs = ctx.room:find_by_template("spider-web")
            return #webs < 2  -- max 2 webs per room
        end,
        narration = "The spider spins a web in the corner.",
    },
    
    -- Ambush behavior near web
    web_ambush = {
        priority = 0.8,
        condition = function(creature, ctx)
            -- If prey trapped in web, attack
            local webs = ctx.room:find_by_template("spider-web")
            for _, web in ipairs(webs) do
                if web.trapped_creature then return true end
            end
            return false
        end,
    },
},
```

#### Silk Crafting Recipes

```lua
-- In src/engine/verbs/crafting.lua
crafting_recipes = {
    ["silk-rope"] = {
        ingredients = { { id = "silk-bundle", quantity = 2 } },
        requires_tool = nil,  -- no tool needed
        result = { id = "silk-rope", quantity = 1 },
        narration = "You twist the silk bundles together into a strong, lightweight rope.",
    },
    ["silk-bandage"] = {
        ingredients = { { id = "silk-bundle", quantity = 1 } },
        requires_tool = nil,
        result = { id = "silk-bandage", quantity = 2 },
        narration = "You tear the silk into strips suitable for bandaging wounds.",
    },
}
```

#### Assignments

| Agent | Task | Details |
|-------|------|---------|
| Bart | **create_object action** | Add to creatures/init.lua action dispatch. Cooldown tracking, condition checking, instantiation. ~50 LOC. |
| Flanders | **spider-web.lua** | Trap object with affects_sizes, escape_difficulty, passable=true for player. |
| Flanders | **silk-rope.lua** | Craftable item. Can be used for climbing (Phase 5+), binding. |
| Flanders | **silk-bandage.lua** | Craftable item. Healing item (heal 5 HP, single use). |
| Flanders | **spider.lua update** | Add creates_object behavior, web_ambush behavior. Max 2 webs per room. |
| Smithers | **craft verb extensions** | Add recipe lookup for `craft rope from silk`, `craft bandage from silk`. Parser aliases. |
| Moe | **cellar spider placement** | Place spider in cellar.lua with appropriate spawn_point for web creation. |
| Nelson | **Web/trap tests** | `test/creatures/test-spider-web.lua` (creation, trap trigger, escape). `test/crafting/test-silk-crafting.lua` (silk→rope, silk→bandage). ~8 tests. |
| Nelson | **LLM walkthrough** | kill spider → get silk → craft rope → use rope (or bandage for healing). |

#### Files Created/Modified

| File | Agent | Action |
|------|-------|--------|
| `src/engine/creatures/init.lua` | Bart | MODIFY (create_object action) |
| `src/meta/objects/spider-web.lua` | Flanders | CREATE |
| `src/meta/objects/silk-rope.lua` | Flanders | CREATE |
| `src/meta/objects/silk-bandage.lua` | Flanders | CREATE |
| `src/meta/creatures/spider.lua` | Flanders | MODIFY (creates_object, web_ambush) |
| `src/engine/verbs/crafting.lua` | Smithers | MODIFY (craft recipes) |
| `src/meta/world/cellar.lua` | Moe | MODIFY (spider placement) |
| `test/creatures/test-spider-web.lua` | Nelson | CREATE |
| `test/crafting/test-silk-crafting.lua` | Nelson | CREATE |
| `src/engine/parser/embedding-index.json` | Smithers | MODIFY (craft aliases) |

#### GATE-4 Criteria

- [ ] Spider creates web after 30 min cooldown (deterministic test)
- [ ] Web traps rat (tiny) — rat immobilized
- [ ] Web does NOT trap wolf (medium) — size filter works
- [ ] Player can walk through web (passable)
- [ ] `craft rope from silk` (2 silk-bundle) → silk-rope
- [ ] `craft bandage from silk` (1 silk-bundle) → 2 silk-bandage
- [ ] silk-bandage heals 5 HP when used
- [ ] Spider attacks trapped rat (web_ambush behavior)
- [ ] `lua test/run-tests.lua` — ~240 tests pass
- [ ] Git commit: `feat: spider ecology - webs and silk crafting (WAVE-4)`

---

### WAVE-5 — Advanced Behaviors + Docs + Polish

**Goal:** Add creature coordination (pack tactics), territorial systems, and complete Phase 4 documentation.

#### Pack Tactics Design

Wolves in the same room coordinate attacks:

```lua
-- In wolf.lua behavior
behavior = {
    -- ... existing ...
    
    pack_tactics = {
        enabled = true,
        role_selection = function(wolves, ctx)
            -- Alpha: highest aggression attacks
            -- Beta: flanks (targets different zone)
            -- Omega: holds back as reserve
            table.sort(wolves, function(a, b)
                return a.behavior.aggression > b.behavior.aggression
            end)
            wolves[1].combat_role = "alpha"  -- primary attacker
            if wolves[2] then wolves[2].combat_role = "beta" end
            if wolves[3] then wolves[3].combat_role = "omega" end
        end,
        coordination = {
            alpha = { target_zone = "torso", priority = 1 },
            beta = { target_zone = "legs", priority = 0.8, delay = 1 },
            omega = { target_zone = "arms", priority = 0.5, condition = "alpha_injured" },
        },
    },
},
```

#### Territorial Marking System

```lua
-- In wolf.lua behavior
behavior = {
    -- ... existing ...
    
    territorial = {
        marks_territory = true,
        mark_object = "territory-marker",  -- invisible marker object
        mark_radius = 2,  -- rooms
        mark_duration = "1 day",
        
        response_to_mark = function(wolf, marker, ctx)
            if marker.owner == wolf.guid then
                return "patrol"  -- defend own territory
            elseif wolf.behavior.aggression > 0.7 then
                return "challenge"  -- aggressive wolf fights intruder
            else
                return "avoid"  -- submissive wolf leaves
            end
        end,
    },
},
```

#### Assignments

| Agent | Task | Details |
|-------|------|---------|
| Bart | **Pack tactics engine** | In creatures/init.lua or new pack.lua module. Role assignment (alpha/beta/omega), coordinated attack timing, zone distribution. ~100 LOC. |
| Bart | **Territorial marking** | In creatures/init.lua. Mark placement, mark detection, response dispatch. ~80 LOC. |
| Bart | **Ambush behavior** | Spider ambush near web (from WAVE-4) + general ambush pattern for any creature with `behavior.ambush = true`. |
| Flanders | **territory-marker.lua** | Invisible object (description = nil, not findable by player). Tracks owner, timestamp, radius. |
| Smithers | **Weapon combat metadata** | Add combat metadata (force, damage_type, reach) to remaining weapon objects: candlestick, poker, broken-bottle, etc. |
| Brockman | **Phase 4 design docs** | `docs/design/crafting-system.md` (butchery, silk crafting). `docs/design/stress-system.md` (stress injury). `docs/design/creature-ecology.md` (webs, pack tactics, territory). |
| Nelson | **Behavior tests** | `test/creatures/test-pack-tactics.lua` (role assignment, coordination). `test/creatures/test-territorial.lua` (marking, response). ~8 tests. |
| Nelson | **Final LLM walkthrough** | Full Phase 4 scenario: kill wolf → butcher → cook meat → eat. Kill spider → get silk → craft rope. Witness death → stress → rest cure. 2+ wolves → pack attack. |

#### Files Created/Modified

| File | Agent | Action |
|------|-------|--------|
| `src/engine/creatures/pack.lua` | Bart | CREATE |
| `src/engine/creatures/territorial.lua` | Bart | CREATE |
| `src/engine/creatures/init.lua` | Bart | MODIFY (integrate pack + territorial) |
| `src/meta/objects/territory-marker.lua` | Flanders | CREATE |
| `src/meta/objects/candlestick.lua` | Smithers | MODIFY (combat metadata) |
| `src/meta/objects/fire-poker.lua` | Smithers | MODIFY (combat metadata) |
| `docs/design/crafting-system.md` | Brockman | CREATE |
| `docs/design/stress-system.md` | Brockman | CREATE |
| `docs/design/creature-ecology.md` | Brockman | CREATE |
| `test/creatures/test-pack-tactics.lua` | Nelson | CREATE |
| `test/creatures/test-territorial.lua` | Nelson | CREATE |

#### GATE-5 Criteria

- [ ] 2 wolves in room → alpha attacks first, beta targets different zone
- [ ] Wolf marks territory after entering new room
- [ ] Different wolf responds to territory mark (avoid/challenge based on aggression)
- [ ] All weapon objects have combat metadata
- [ ] `docs/design/crafting-system.md` exists and complete
- [ ] `docs/design/stress-system.md` exists and complete
- [ ] `docs/design/creature-ecology.md` exists and complete
- [ ] Final LLM walkthrough passes (full Phase 4 loop)
- [ ] `lua test/run-tests.lua` — ~250 tests pass
- [ ] Git commit: `feat: advanced behaviors + Phase 4 docs (WAVE-5)`

---

## Section 5: Testing Gates

### GATE-0 — Pre-Flight

| Check | Owner | Criteria |
|-------|-------|----------|
| Module health | Bart | All engine modules <500 LOC |
| GUID assignment | Bart | ~18 GUIDs documented in decision inbox |
| Test baseline | Nelson | ~209 tests pass |
| Docs complete | Brockman | butchery-system.md + loot-tables.md reviewed |

### GATE-1 — Butchery

| Check | Owner | Criteria |
|-------|-------|----------|
| Butcher verb | Smithers | Verb resolves, aliases work |
| Tool requirement | Nelson | Butchering without knife fails |
| Product instantiation | Nelson | Wolf → 3 meat, 2 bone, 1 hide |
| Wolf-meat cookable | Nelson | cook wolf-meat → cooked-wolf-meat |
| Test count | Nelson | ~215 tests pass |

### GATE-2 — Loot Tables

| Check | Owner | Criteria |
|-------|-------|----------|
| Weighted distribution | Nelson | 10 kills match expected probability (±10%) |
| Always drops | Nelson | gnawed-bone appears every wolf kill |
| Conditional drops | Nelson | Fire kill → charred-hide (if implemented) |
| Meta-lint | Nelson | LOOT-001 through LOOT-005 pass |
| Test count | Nelson | ~223 tests pass |

### GATE-3 — Stress

| Check | Owner | Criteria |
|-------|-------|----------|
| Trauma triggers | Nelson | Witness death → +1 stress |
| Debuff application | Nelson | Shaken → -1 attack in combat test |
| Cure mechanics | Nelson | Rest 2 hours safe room → stress cleared |
| Status display | Smithers | Stress level visible in UI |
| Test count | Nelson | ~230 tests pass |

### GATE-4 — Spider Ecology

| Check | Owner | Criteria |
|-------|-------|----------|
| Web creation | Nelson | Spider creates web after cooldown |
| Trap mechanic | Nelson | Rat trapped, wolf not trapped |
| Silk crafting | Nelson | 2 silk → rope, 1 silk → 2 bandage |
| Bandage healing | Nelson | Use bandage → +5 HP |
| Ambush behavior | Nelson | Spider attacks trapped prey |
| Test count | Nelson | ~240 tests pass |

### GATE-5 — Advanced Behaviors

| Check | Owner | Criteria |
|-------|-------|----------|
| Pack tactics | Nelson | Alpha/beta role assignment works |
| Territorial | Nelson | Mark placement + response dispatch |
| Docs complete | Brockman | 3 design docs reviewed |
| LLM walkthrough | Nelson | Full scenario passes |
| Zero regressions | Nelson | ~250 tests pass |

---

## Section 6: Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **Loot table RNG makes tests flaky** | Medium | High | Use deterministic seed (math.randomseed(42)) in all loot tests |
| **Stress system feels punishing** | Medium | Medium | Tune thresholds based on LLM playtesting; cure should be accessible |
| **Pack tactics coordination is expensive** | Low | Medium | Limit to 3 wolves per pack; spatial optimization already in place |
| **Butchery duration blocks gameplay** | Low | Low | Duration is game-time, not real-time; can be skipped with time_skip |
| **Spider web creation spam** | Low | Low | 30 min cooldown + max 2 per room cap |
| **Module size regression** | Medium | Medium | LOC audit in WAVE-0; split proactively |
| **Crafting recipe explosion** | Low | Medium | Phase 4 adds only 2 recipes (silk); cap scope |
| **Territorial marking invisible to player** | Medium | Low | Add "You smell wolf scent here" narration when entering marked room |

---

## Section 7: File Ownership Table

| File | Wave | Primary Owner | Collaborators |
|------|------|---------------|---------------|
| `src/engine/verbs/crafting.lua` | W1, W4 | Smithers | — |
| `src/engine/creatures/loot.lua` | W2 | Bart | — |
| `src/engine/creatures/death.lua` | W2, W3 | Bart | — |
| `src/engine/creatures/pack.lua` | W5 | Bart | — |
| `src/engine/creatures/territorial.lua` | W5 | Bart | — |
| `src/engine/creatures/init.lua` | W4, W5 | Bart | — |
| `src/engine/injuries.lua` | W3 | Bart | — |
| `src/engine/combat/init.lua` | W3 | Bart | — |
| `src/engine/ui/status.lua` | W3 | Smithers | — |
| `src/meta/creatures/wolf.lua` | W1, W2, W5 | Flanders | — |
| `src/meta/creatures/spider.lua` | W1, W2, W4 | Flanders | — |
| `src/meta/objects/wolf-*.lua` | W1 | Flanders | — |
| `src/meta/objects/spider-*.lua` | W2, W4 | Flanders | — |
| `src/meta/objects/silk-*.lua` | W4 | Flanders | — |
| `src/meta/injuries/stress.lua` | W3 | Flanders | — |
| `src/meta/world/cellar.lua` | W4 | Moe | — |
| `docs/architecture/engine/*.md` | W0 | Brockman | Bart (review) |
| `docs/design/*.md` | W5 | Brockman | — |
| `test/butchery/*.lua` | W1 | Nelson | — |
| `test/loot/*.lua` | W2 | Nelson | — |
| `test/stress/*.lua` | W3 | Nelson | — |
| `test/creatures/test-spider-web.lua` | W4 | Nelson | — |
| `test/crafting/test-silk-crafting.lua` | W4 | Nelson | — |
| `test/creatures/test-pack-tactics.lua` | W5 | Nelson | — |
| `test/creatures/test-territorial.lua` | W5 | Nelson | — |

---

## Section 8: Conflict Prevention Matrix

| Wave | Bart | Flanders | Smithers | Moe | Nelson | Brockman |
|------|------|----------|----------|-----|--------|----------|
| W0 | LOC audit, GUIDs | — | — | — | test verify | arch docs |
| W1 | — | creatures, objects | butcher verb | — | tests | — |
| W2 | loot engine, death | creatures, spider-fang | — | — | tests, lint | — |
| W3 | injuries, combat | stress.lua | status UI | — | tests | — |
| W4 | creatures/init | spider, silk objects | craft verb | cellar | tests | — |
| W5 | pack, territorial | territory-marker | weapon meta | — | tests, LLM | design docs |

**No overlaps detected.** Each agent has exclusive file ownership per wave.

---

## Section 9: Parser Integration Matrix

| Wave | New Nouns | Verb Aliases | Embedding Index Update | Owner |
|------|-----------|--------------|------------------------|-------|
| W1 | wolf meat, wolf bone, wolf hide, butcher knife | butcher, carve, skin, fillet | ~20 phrases | Smithers |
| W2 | spider fang | — | ~5 phrases | Smithers |
| W3 | (no new objects) | — | — | — |
| W4 | spider web, silk rope, silk bandage | craft [X] from [Y] | ~15 phrases | Smithers |
| W5 | (invisible territory marker) | — | — | — |

**Total: ~40 new embedding index phrases.**

---

## Section 10: Open Questions (For Wayne)

### Q1: Butchery Time — Real-Time or Skip?

**Context:** Butchery takes "5 minutes" game time. Should this be:
- **A: Instant** — butchery is immediate, duration is flavor text only
- **B: Time passes** — butchery advances game clock 5 minutes (triggers FSM ticks, spoilage, etc.)
- **C: Interruptible** — butchery starts, player can do other actions, completes after 5 min

**Recommendation:** Option B (time passes). Consistent with existing `cook` verb which advances time. Adds strategic depth (spoilage during butchery).

### Q2: Stress Cure — Safe Room Definition

**Context:** Stress cures with "rest in safe room." What makes a room safe?
- **A: No creatures** — any room without creatures qualifies
- **B: No hostile creatures** — friendly creatures (future: pets) don't break safety
- **C: Designated safe rooms** — only rooms with `safe_room = true` metadata

**Recommendation:** Option A (no creatures). Simple, consistent with current ecosystem. Option B introduces complexity we don't need until pets exist.

### Q3: Spider Web Visibility in Darkness

**Context:** At 2 AM (darkness), can player see spider webs?
- **A: No** — webs are visual, invisible in dark
- **B: Feel only** — player walks through, feels sticky threads
- **C: Both** — `on_feel` triggers when entering, visible with light

**Recommendation:** Option C. Webs have `on_feel` per existing sensory standards. Player in darkness feels them; with light, sees them.

### Q4: Pack Tactics — Alpha Selection Criteria

**Context:** How is pack alpha chosen?
- **A: Highest aggression** — most aggressive wolf leads
- **B: Highest health** — strongest wolf leads
- **C: First to enter room** — territorial precedence
- **D: Explicit metadata** — wolf.lua declares `pack_role = "alpha"`

**Recommendation:** Option A (highest aggression). Emergent behavior from existing metadata. No new data required.

### Q5: Territorial Marking — Player Detection

**Context:** Can player detect wolf territory markers?
- **A: Invisible** — markers exist but player cannot see/smell/feel them
- **B: Smell only** — `look` fails, `smell` reveals "You catch a musky animal scent."
- **C: Visual + Smell** — with light, see scratches on trees; smell works in dark

**Recommendation:** Option B (smell only). Adds gameplay depth without visual clutter. Consistent with sensory-first design.

### Q6: Silk Bandage Healing — Instant or Over Time?

**Context:** Silk bandage heals 5 HP. Should this be:
- **A: Instant** — use bandage → +5 HP immediately
- **B: Over time** — bandage applies, +1 HP per 10 minutes until +5 total
- **C: Bleeding-only** — bandage stops bleeding injury progression, doesn't heal HP

**Recommendation:** Option A (instant). Keeps crafting reward immediate and satisfying. Over-time healing adds complexity without clear gameplay benefit.

### Q7: Phase 4 Scope — Food Preservation?

**Context:** Phase 3 deferred food preservation (salting, smoking, drying). Include in Phase 4?
- **A: Yes** — add preservation as WAVE-6 (7 waves total)
- **B: No** — defer to Phase 5, keep Phase 4 focused on crafting loop
- **C: Partial** — add salt-curing only (simplest preservation)

**Recommendation:** Option B (defer to Phase 5). Phase 4 already has 6 waves. Food preservation is significant scope (new verb, spoilage FSM changes, salt object). Better as Phase 5 focus.

---

## Section 11: What We Deliberately Defer to Phase 5

| Feature | Why Deferred | Design Plan Reference |
|---------|--------------|----------------------|
| **Food preservation** (salting, smoking, drying) | Significant scope, deserves focused phase | — |
| **Wrestling/grapple** | Combat Phase 3 feature, not creature-focused | combat-system-plan.md §11 |
| **Environmental combat** (push barrel, slam door) | Requires object-in-combat interaction model | combat-system-plan.md §11 |
| **Weapon/armor degradation** | Fragility system adds complexity | combat-system-plan.md §11 |
| **Humanoid NPCs** (dialogue, memory, quests) | Phase 4 of NPC plan — massive scope | npc-system-plan.md §9 |
| **Multi-ingredient cooking** | Recipe system beyond single-item mutation | — |
| **Creature-to-creature looting** | Requires creature AI to evaluate loot value | creature-inventory-plan.md §8 |
| **A* pathfinding** | Current random-exit selection sufficient | npc-system-plan.md §9 |

---

## Section 12: Lessons from Phase 3

Applied to Phase 4 planning:

1. **In-place reshape worked well** — death_state architecture (v1.3) is solid. Butchery extends the same pattern.
2. **Wayne directive before writing** — Got reshape architecture directive before Phase 3 code. Apply same: get Q1-Q7 answers before implementation.
3. **5 fewer GUIDs with reshape** — Continue pattern: no separate butchered-wolf.lua, just wolf-meat + wolf-bone + wolf-hide as products.
4. **Architecture docs in WAVE-0** — Wayne directive compliance. Brockman writes arch docs before engine code.
5. **Parallel-friendly wave design** — Phase 3 parallelized well. Phase 4 continues: agent-per-subsystem, no file conflicts.

---

## Appendix A: GUID Reservation Table

To be filled during WAVE-0 by Bart:

| Object | GUID | Wave | Status |
|--------|------|------|--------|
| wolf-meat.lua | TBD | W1 | — |
| wolf-bone.lua | TBD | W1 | — |
| wolf-hide.lua | TBD | W1 | — |
| butcher-knife.lua | TBD | W1 | — |
| spider-fang.lua | TBD | W2 | — |
| stress.lua (injury) | TBD | W3 | — |
| spider-web.lua | TBD | W4 | — |
| silk-rope.lua | TBD | W4 | — |
| silk-bandage.lua | TBD | W4 | — |
| cooked-wolf-meat.lua | TBD | W1 | — |
| territory-marker.lua | TBD | W5 | — |

*Additional GUIDs TBD during WAVE-0 audit.*

---

## Appendix B: Estimated LOC Budget

| Wave | New LOC | Modified LOC | Test LOC | Total |
|------|---------|--------------|----------|-------|
| W0 | 0 | 20 (test runner) | 0 | 20 |
| W1 | ~120 (verb) + ~200 (objects) | ~50 (creatures) | ~60 | 430 |
| W2 | ~100 (loot engine) | ~80 (death, creatures) | ~70 | 250 |
| W3 | ~80 (stress injury) | ~60 (injuries, combat) | ~60 | 200 |
| W4 | ~150 (create_object, crafting) | ~100 (spider, verbs) | ~80 | 330 |
| W5 | ~180 (pack, territorial) | ~50 (weapons, marker) | ~80 | 310 |

**Total: ~1,540 LOC new + modified code, ~350 LOC tests**

---

## Phase 4 Completion Criteria

Phase 4 is complete when:

1. ✅ Wolf corpse can be butchered into meat + bone + hide
2. ✅ Loot tables replace fixed inventory on all creatures
3. ✅ Stress injury inflicts on trauma, debuffs combat, cures with rest
4. ✅ Spider creates webs that trap small creatures
5. ✅ Silk bundles craft into rope and bandages
6. ✅ Wolves coordinate attacks with pack tactics
7. ✅ All design docs complete (crafting, stress, ecology)
8. ✅ ~250 tests pass with zero regressions
9. ✅ Final LLM walkthrough demonstrates full Phase 4 loop

---

## Next: Phase 5

Phase 5 will address **food preservation** (salting, smoking, drying), **environmental combat** (push/throw/slam), and preparation for **humanoid NPCs** (dialogue stubs, memory framework). The crafting pipeline established in Phase 4 becomes the foundation for preservation mechanics.

---

*Plan authored by Bart (Architecture Lead). Awaiting Wayne's input on 7 open questions before execution.*
