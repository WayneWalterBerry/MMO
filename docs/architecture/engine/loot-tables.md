# Loot Tables

**Author:** Brockman (Documentation)  
**Date:** 2026-08-16  
**Version:** 1.0  
**Status:** Approved for WAVE-2 Implementation  
**Related:** `butchery-system.md`, `creature-inventory.md`, `creature-death-reshape.md`, `../../.squad/decisions.md` (D-CREATURE-INVENTORY)

---

## 1. The Problem Space

### Why Loot Tables Exist

Phase 3 fixed creature inventories: each wolf carried the same `gnawed-bone-01` GUID. This created monotony. Loot variety requires probabilistic drops: one wolf drops bone, another drops a coin, another drops nothing.

Phase 3 decision (Q6, creature-inventory-plan.md): "Fixed inventory only. Loot tables add value when we have 20+ creature types and randomized dungeons — that's Phase 4 territory."

Phase 4 is that territory. **Loot tables** replace fixed inventory GUIDs with probabilistic specs:

- **Always drop:** 100% guaranteed items
- **Weighted roll:** Pick ONE item based on weights (20% coin, 30% cloth, 50% nothing)
- **Variable quantity:** Roll 1-3 coins instead of fixed count
- **Conditional drops:** Different items based on kill method (fire_kill, poison_kill)

Result: Each creature death produces unique loot, encouraging exploration and repetition.

---

## 2. Architecture Overview

### Pipeline Diagram

```
┌─────────────────────────────────────┐
│ Player kills wolf                   │
│ (combat resolution)                 │
└──────────────┬──────────────────────┘
               │
               ▼
    ┌──────────────────────────┐
    │ kill_handler() detects   │
    │ death                    │
    └──────────────┬───────────┘
                   │
                   ▼
    ┌──────────────────────────┐
    │ reshape_instance()       │
    │ creature → corpse        │
    │ (death_state)            │
    └──────────────┬───────────┘
                   │
                   ▼
    ┌──────────────────────────┐
    │ roll_loot_table()        │
    │ consult creature.        │
    │ loot_table metadata      │
    └──────────────┬───────────┘
                   │
                   ▼
    ┌──────────────────────────┐
    │ FOR each loot_item:      │
    │  - weighted_select()     │
    │    (for on_death)        │
    │  - random(min, max)      │
    │    (for variable qty)    │
    │  - check conditionals    │
    └──────────────┬───────────┘
                   │
                   ▼
    ┌──────────────────────────┐
    │ drops[] = []             │
    │ FOR each product:        │
    │   instantiate()          │
    │   add to drops[]         │
    └──────────────┬───────────┘
                   │
                   ▼
    ┌──────────────────────────┐
    │ FOR each drop in room:   │
    │   room:add_object()      │
    │   (floor placement)      │
    └──────────────┬───────────┘
                   │
                   ▼
    ┌──────────────────────────┐
    │ Loot visible on ground   │
    │ Ready for player pickup  │
    └──────────────────────────┘
```

### Core Concepts

1. **Metadata-driven drops** — Creature's `loot_table` block defines all possible drops. No hard-coded creature logic.

2. **Weighted selection** — `weighted_select()` implements normalized probability. Weights sum to 100 (or arbitrary total); RNG roll picks one item proportionally.

3. **Deterministic for testing** — `math.randomseed(42)` ensures reproducible rolls in tests. Same seed → same loot sequence.

4. **Room-floor placement** — Loot appears on room ground (not in corpse container). Player picks up directly, no "search corpse" step.

5. **Integration with death reshape** — Loot rolls AFTER corpse is reshaped, so creatures can reference `death_state` metadata if needed.

---

## 3. Metadata Specification

### `loot_table` Block

Placed in creature definition (e.g., `src/meta/creatures/wolf.lua`):

```lua
loot_table = {
    -- OPTIONAL: items that always drop (100% chance)
    always = {
        { template = "gnawed-bone" },
        { template = "fur-scrap", quantity = 2 },
    },

    -- OPTIONAL: weighted one-per-roll (pick ONE)
    on_death = {
        { item = { template = "silver-coin" }, weight = 20 },
        { item = { template = "torn-cloth" }, weight = 30 },
        { item = nil, weight = 50 },  -- 50% nothing
    },

    -- OPTIONAL: variable quantity rolls
    variable = {
        { template = "copper-coin", min = 0, max = 3 },
        { template = "berry", min = 1, max = 2 },
    },

    -- OPTIONAL: conditional drops (based on kill method)
    conditional = {
        fire_kill = {
            { template = "charred-hide" },
        },
        poison_kill = {
            { template = "tainted-meat" },
        },
    },
},
```

### Field Reference

| Section | Field | Type | Required | Notes |
|---------|-------|------|----------|-------|
| `always` | — | array | No | Items that drop 100% of the time. Each element: `{ template, quantity }`. `quantity` defaults to 1. |
| `on_death` | `weight` | number | Yes (if on_death exists) | Relative probability. Weights normalize automatically; sum doesn't need to equal 100. |
| `on_death` | `item` | table/nil | Yes | Object to drop: `{ template = "..." }`. `nil` for "nothing" option. |
| `variable` | `template` | string | Yes | Object template ID. |
| `variable` | `min`, `max` | number | Yes | Quantity range. Roll `math.random(min, max)`. If 0, item may not appear. |
| `conditional` | `kill_method` | string | — | Key name (e.g., "fire_kill", "poison_kill"). Matched against `death_context.kill_method`. |

---

## 4. Weighted Roll Algorithm

### `weighted_select(options)` Implementation

```lua
function weighted_select(options)
    -- Normalize weights
    local total = 0
    for _, opt in ipairs(options) do
        total = total + opt.weight
    end

    if total == 0 then
        return nil  -- No valid options
    end

    -- Roll 0.0 to total
    local roll = math.random() * total
    
    -- Cumulative search
    local cumulative = 0
    for _, opt in ipairs(options) do
        cumulative = cumulative + opt.weight
        if roll <= cumulative then
            return opt  -- This option wins
        end
    end

    -- Fallback (shouldn't reach here)
    return options[#options]
end
```

### Algorithm Explanation

1. **Total all weights** — Sum the `weight` field across all options.
2. **Generate roll** — `math.random() * total` produces 0.0 to total.
3. **Cumulative search** — Iterate options, adding weight. When roll ≤ cumulative, that option wins.
4. **Example (3 options, weights 20, 30, 50, total 100)**
   - Roll 15: Falls in 0–20 range → option 1 (silver-coin)
   - Roll 35: Falls in 20–50 range → option 2 (torn-cloth)
   - Roll 75: Falls in 50–100 range → option 3 (nothing)

### Weight Normalization

Weights do **not** need to sum to 100. Any positive sum works:

```lua
on_death = {
    { item = { template = "coin" }, weight = 1 },
    { item = { template = "cloth" }, weight = 2 },
    { item = nil, weight = 7 },
}
-- Total = 10. Coin = 10%, cloth = 20%, nothing = 70%
```

---

## 5. Instantiation Flow

### `roll_loot_table(creature, death_context)` Function

Located in `src/engine/creatures/loot.lua`:

```lua
function roll_loot_table(creature, death_context)
    local loot = creature.loot_table
    if not loot then return {} end

    local drops = {}

    -- 1. Always drops (100% guaranteed)
    for _, always_item in ipairs(loot.always or {}) do
        table.insert(drops, {
            template = always_item.template,
            quantity = always_item.quantity or 1,
        })
    end

    -- 2. Weighted roll (pick ONE from on_death)
    if loot.on_death then
        local selected = weighted_select(loot.on_death)
        if selected and selected.item then
            table.insert(drops, {
                template = selected.item.template,
                quantity = 1,
            })
        end
    end

    -- 3. Variable quantity rolls
    for _, var_item in ipairs(loot.variable or {}) do
        local qty = math.random(var_item.min, var_item.max)
        if qty > 0 then
            table.insert(drops, {
                template = var_item.template,
                quantity = qty,
            })
        end
    end

    -- 4. Conditional drops (based on kill method)
    if death_context and death_context.kill_method then
        local cond_items = loot.conditional and loot.conditional[death_context.kill_method]
        if cond_items then
            for _, cond_item in ipairs(cond_items) do
                table.insert(drops, {
                    template = cond_item.template,
                    quantity = cond_item.quantity or 1,
                })
            end
        end
    end

    return drops  -- Array of { template, quantity }
end
```

### `instantiate_drops(drops, registry)` Function

```lua
function instantiate_drops(drops, registry)
    local instances = {}
    for _, drop in ipairs(drops) do
        for i = 1, drop.quantity do
            local instance = registry:instantiate(drop.template)
            if instance then
                table.insert(instances, instance)
            end
        end
    end
    return instances
end
```

### Integration with Death Handler

In `src/engine/creatures/death.lua`, `kill_handler()` calls:

```lua
-- After reshape
local death_context = {
    kill_method = context.last_combat_method,  -- "fire_kill", "poison_kill", etc.
}

local drops = loot.roll_loot_table(creature, death_context)
local instances = loot.instantiate_drops(drops, context.registry)

-- Place loot in room
for _, instance in ipairs(instances) do
    context.room:add_object(instance)
end
```

---

## 6. Deterministic Testing

### Reproducible Rolls with `math.randomseed()`

All loot tests use fixed seed to ensure reproducibility:

```lua
-- In test setup
math.randomseed(42)

-- Kill wolf 10 times with same seed
local drops = {}
for i = 1, 10 do
    math.randomseed(42)  -- Reset seed
    local wolf_loot = roll_loot_table(wolf_creature, {})
    table.insert(drops, wolf_loot)
end

-- Expected: identical loot sequence each run
t.assert_eq(drops[1], drops[11])  -- 10 kills later, same pattern
```

### Determinism Guarantees

- `math.random()` with fixed seed produces deterministic sequence
- Each test file calls `math.randomseed()` independently
- No shared RNG state between tests
- Weights always normalize the same way
- Cumulative search always picks the same option for same roll

### False Positives Prevention

If loot tests are **not** deterministic:
- Use `math.randomseed()` at test start
- Don't call `math.randomseed()` multiple times within a single test
- Document seed value in test comments
- Run tests 3 times in a row to verify consistency

---

## 7. Example: Wolf Loot Table

### Complete Wolf Definition (in `src/meta/creatures/wolf.lua`)

```lua
return {
    guid = "{WOLF-GUID}",
    template = "creature",
    id = "wolf",
    name = "a gray wolf",
    -- ... other creature fields ...

    -- REPLACES fixed inventory from Phase 3
    loot_table = {
        -- Always: every wolf drops a gnawed bone
        always = {
            { template = "gnawed-bone" },
        },

        -- Weighted roll: pick ONE
        on_death = {
            { item = { template = "silver-coin" }, weight = 20 },      -- 20%
            { item = { template = "torn-cloth" }, weight = 30 },      -- 30%
            { item = nil, weight = 50 },                              -- 50% nothing
        },

        -- Variable: 0-3 copper coins
        variable = {
            { template = "copper-coin", min = 0, max = 3 },
        },

        -- Conditional: if killed by fire, drop charred hide
        conditional = {
            fire_kill = {
                { template = "charred-hide" },
            },
            poison_kill = {
                { template = "tainted-meat" },
            },
        },
    },
}
```

### Example Rolls

Kill 1:
- Always: gnawed-bone (1)
- on_death roll: 45 → torn-cloth (1)
- variable: random(0, 3) = 2 → copper-coin (2)
- **Total drop:** gnawed-bone, torn-cloth, copper-coin ×2

Kill 2:
- Always: gnawed-bone (1)
- on_death roll: 85 → nothing
- variable: random(0, 3) = 0 → copper-coin (0)
- **Total drop:** gnawed-bone only

Kill 3 (fire method):
- Always: gnawed-bone (1)
- on_death roll: 15 → silver-coin (1)
- variable: random(0, 3) = 1 → copper-coin (1)
- conditional (fire_kill): charred-hide (1)
- **Total drop:** gnawed-bone, silver-coin, copper-coin, charred-hide

---

## 8. Testing Strategy

### Test Coverage (WAVE-2 deliverables)

**File:** `test/loot/test-loot-engine.lua`
- ✅ `weighted_select()` with 3 options, weights 20/30/50 → correct distribution over 100 rolls
- ✅ Weight normalization: weights 1/2/7 same as 10/20/70 → identical probabilities
- ✅ `weighted_select()` with single option → always returns that option
- ✅ `weighted_select()` with all zero weights → returns nil
- ✅ `roll_loot_table()` with only `always` block → returns guaranteed items
- ✅ `roll_loot_table()` with only `on_death` block → returns one item or nil
- ✅ `roll_loot_table()` with `variable` block → quantity within [min, max]
- ✅ Deterministic seed: `math.randomseed(42)` → same 10-roll sequence each run

**File:** `test/loot/test-loot-integration.lua`
- ✅ Kill wolf with deterministic seed → drops appear in room
- ✅ Gnawed-bone always present
- ✅ on_death weighted distribution: 100 kills, verify coin/cloth ratio ≈ 20:30:50
- ✅ Variable quantity: 100 kills, verify copper coins in [0, 3]
- ✅ Conditional (fire_kill): kill wolf with fire → charred-hide appears
- ✅ Conditional (poison_kill): kill wolf with poison → tainted-meat appears
- ✅ Loot not in corpse container (on room floor)
- ✅ No regression in Phase 3 creature tests

---

## 9. Meta-Lint Rules

### LOOT Validation Suite

**Location:** `scripts/meta-lint/rules/loot.lua`

#### LOOT-001: Loot table structure
- ✅ If `loot_table` exists, must be a table
- ✅ Sections (always, on_death, variable, conditional) are tables or nil
- ✅ Error if: malformed array in any section

#### LOOT-002: Weight validation
- ✅ All `on_death` items must have `weight > 0`
- ✅ At least one weight must exist in `on_death` if section present
- ✅ Warn if: single item with weight 100 (always same result)

#### LOOT-003: Template reference validation
- ✅ All `template` references resolve to existing object files
- ✅ Error if: `template = "nonexistent-object"`
- ✅ Warn if: template is creature (should be object)

#### LOOT-004: Quantity bounds
- ✅ `variable.min` ≤ `variable.max`
- ✅ Both are ≥ 0
- ✅ Error if: min > max

#### LOOT-005: Conditional key validation
- ✅ All `conditional` keys (fire_kill, poison_kill) match known kill methods
- ✅ Warn if: unknown method names

---

## 10. Integration Points

### 1. Death Handler Connection

**File:** `src/engine/creatures/death.lua`

```lua
-- In kill_handler()
if creature.loot_table then
    local loot_engine = require("src.engine.creatures.loot")
    local death_context = { kill_method = context.last_combat_method }
    local drops = loot_engine.roll_loot_table(creature, death_context)
    local instances = loot_engine.instantiate_drops(drops, context.registry)
    for _, instance in ipairs(instances) do
        context.room:add_object(instance)
    end
end
```

### 2. Creature File Updates

**WAVE-2 assignments:**
- **Flanders:** Replace `inventory` GUIDs with `loot_table` block in `src/meta/creatures/wolf.lua`
- **Flanders:** Replace inventory with `loot_table` block in `src/meta/creatures/spider.lua`
  - Always: silk-bundle
  - On_death: 10% spider-fang
- **Flanders:** Create `src/meta/objects/spider-fang.lua` (poison weapon component)

### 3. Registry Dependency

Loot instantiation uses `registry:instantiate(template_id)`. Registry must have templates loaded before loot rolls.

### 4. Room Placement

Loot objects use `room:add_object(instance)` for room-floor placement. Objects immediately appear as pickable items.

---

## 11. Implementation Checklist (WAVE-2)

- [ ] **Bart:** Create `src/engine/creatures/loot.lua` (~100 LOC)
  - `weighted_select(options)` function
  - `roll_loot_table(creature, death_context)` function
  - `instantiate_drops(drops, registry)` function

- [ ] **Bart:** Integrate loot engine into `src/engine/creatures/death.lua`
  - Call `roll_loot_table()` after death reshape
  - Instantiate drops and place in room

- [ ] **Flanders:** Replace wolf inventory with `loot_table` in `src/meta/creatures/wolf.lua`
  - Always: gnawed-bone
  - On_death: 20% silver-coin, 30% torn-cloth, 50% nothing
  - Variable: 0-3 copper-coins

- [ ] **Flanders:** Replace spider inventory with `loot_table` in `src/meta/creatures/spider.lua`
  - Always: silk-bundle
  - On_death: 10% spider-fang

- [ ] **Flanders:** Create `src/meta/objects/spider-fang.lua` (small-item, poison component)

- [ ] **Nelson:** Write `test/loot/test-loot-engine.lua` (~4 tests, deterministic seed)

- [ ] **Nelson:** Write `test/loot/test-loot-integration.lua` (~4 integration tests)

- [ ] **Nelson:** Create `scripts/meta-lint/rules/loot.lua` (LOOT-001 through LOOT-005)

---

## 12. Related Systems

### Death Reshape (`creature-death-reshape.md`)
Loot rolls **after** death reshape. Corpse must be in valid state before drops are generated.

### Butchery System (`butchery-system.md`)
Loot tables are **independent** of butchery. A corpse drops loot immediately; butchery happens later if player chooses.

### Creature Inventory (`creature-inventory.md`)
Loot tables **replace** fixed inventory (Phase 3). Phase 4: no more fixed GUID drops. Phase 5+: can add butchery drops to loot tables.

### Tool Capability System
Loot tables are **passive** — no tool requirements. Future: "blessed weapons drop more often" (conditional on player state).

### Combat System (`src/engine/combat/`)
Loot tables reference `death_context.kill_method` (fire_kill, poison_kill). Combat system must populate this field.

---

## 13. Decision Rationale

### Why Weighted Rolls (Not Fixed Distribution)?

**Not:** "Each wolf has 33% chance of drop A, B, or C"  
**Instead:** "Weights: A=20, B=30, C=50 (normalized to 20%, 30%, 50%)"

**Rationale:**
- Weights don't need to sum to 100 (easier authoring)
- Can add/remove items without recalculating percentages
- Supports rare drops (weight 1 among weight 99 items)
- Aligns with industry standard (Diablo, Dark Souls)

### Why Room-Floor (Not Corpse Container)?

**Not:** "Loot stays in corpse; player searches corpse to find items"  
**Instead:** "Loot appears on room floor; player picks up directly"

**Rationale:**
- Simpler interaction model (no "search" verb needed)
- Consistent with Phase 3 corpus drop behavior
- Corpse-as-container adds complexity (can player put items back? can loot disappear?)
- Room-floor is transient and immediate

### Why Deterministic Testing?

**Not:** "Tests accept any valid loot distribution"  
**Instead:** "Tests use `math.randomseed(42)` for reproducible sequences"

**Rationale:**
- Catches weight miscalculations (same seed → different results = bug)
- Enables automated testing without randomness
- Reproducibility aids debugging
- Meets requirement: no flaky test reruns (100% pass rate 3× in a row)

### Why Separate Loot Engine (Not Inline in Death)?

**Not:** "Death handler computes loot directly"  
**Instead:** "Separate `src/engine/creatures/loot.lua` module"

**Rationale:**
- Reusability: loot engine used by death, butchery, creature-created-objects (Phase 4)
- Testability: unit tests focus on loot logic, not death complexity
- Maintainability: loot updates don't touch death handler
- Modularity: aligns with Principle 8 (engine executes metadata)

---

## 14. Known Limitations & Future Extensions

| Limitation | Status | Notes |
|-----------|--------|-------|
| Only one weighted roll per death | Deferred | Could support "roll twice" (e.g., always coin AND always cloth). Phase 5+. |
| Weights cannot exceed 2^31 | By design | Lua number precision. No practical impact for game balancing. |
| No kill-method-specific quantity | Deferred | `variable.min/max` same regardless of kill method. Phase 5: conditional quantity ranges. |
| No player-level-based drops | Deferred | Loot independent of player stats. Phase 5: scaling difficulty → better drops. |
| No "epic" or "legendary" drop rates | Deferred | All weights are flat probabilities. Phase 5: rarity tiers. |

---

## 15. Glossary

| Term | Definition |
|------|-----------|
| **Loot table** | Metadata block declaring what a creature drops on death |
| **Weighted roll** | Probability selection: choose one item based on relative weights |
| **Cumulative search** | Algorithm: sum weights, roll random, find which weight range contains roll |
| **Always drop** | Item that appears 100% of the time on every creature death |
| **On_death roll** | Weighted selection: pick ONE item (or nothing) from on_death array |
| **Variable quantity** | Roll random integer in [min, max] to determine drop count |
| **Conditional drop** | Item that appears only if specific kill method used (fire, poison, etc.) |
| **Death context** | Metadata object passed to loot engine: kill_method, damage_type, etc. |
| **Instantiation** | Process of creating a new object instance from template ID |
| **Room floor** | Placement location for loot: visible and pickable by player |

