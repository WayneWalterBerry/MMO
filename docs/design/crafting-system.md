# Crafting System Design

**Version:** 1.0  
**Last Updated:** 2026-08-21  
**Author:** Brockman (Documentation)  
**Related:** `../../architecture/engine/butchery-system.md`, `../../architecture/engine/loot-tables.md`, `food-system.md`, `tools-system.md`

---

## Overview

The crafting system enables players to transform raw resources (butchered meat, silk bundles) into useful items through directed verb commands. It is implemented in Phase 4 across **WAVE-1** (butchery foundation), **WAVE-2** (loot tables for resource variety), and **WAVE-4** (silk crafting recipes).

The system follows a **Tier 1 recipe-ID dispatch** model: players type `craft silk-rope` or `make silk-bandage` (recipe ID as noun), and the engine resolves via lookup table. Advanced syntaxes like `craft rope from silk` are deferred to Phase 5 (Tier 3 GOAP planner).

---

## 1. Butchery Pipeline: Corpse → Resources

### The Problem

Phase 3 established creature death and corpse creation. But large creatures (wolf, spider) reshape to furniture template after death, which is non-portable and cannot be directly cooked. The resource extraction loop is blocked.

### The Solution: Butcher Verb

The `butcher` verb converts large corpses into portable resources using a knife or equivalent cutting tool.

| Step | Input | Action | Output |
|------|-------|--------|--------|
| 1 | Wolf corpse (furniture) | Player: `butcher wolf` | Validation: is corpse reshaped? Has butchery_products? |
| 2 | Knife (tool with "butchering" capability) | Tool check | Error if knife missing |
| 3 | Corpse metadata | Execute butchery | Instantiate all products in room |
| 4 | Time: 5 minutes | Game clock advances | FSM ticks, candle burn, spoilage, respawns trigger |
| 5 | Corpse cleanup | Optional removal | Corpse deregistered if `removes_corpse = true` |

### Creatures with Butchery Products

| Creature | Products | Tool Required | Notes |
|----------|----------|---------------|-------|
| **Wolf** | 3× wolf-meat, 2× wolf-bone, 1× wolf-hide | Knife (butchering capability) | Corpse removed after butchery |
| **Spider** | 1× spider-meat, 1× silk-bundle | Knife (butchering capability) | Corpse removed after butchery |

### Verb Aliases

`butcher`, `carve`, `skin`, `fillet` → all resolve to same handler in `src/engine/verbs/crafting.lua`.

### Integration with Food System

Butchered meat products follow the existing **raw → cooked → nutrition** pipeline:

1. `wolf-meat` (raw) — cold, slippery, gamey-tasting raw flesh
2. Cook via fire source: `cook wolf-meat`
3. Mutation: `wolf-meat` → `cooked-wolf-meat`
4. Eat: +nutrition, +healing

**Design rationale:** Butchery bridges corpse disposal and food creation, establishing the full resource cycle in a single system.

---

## 2. Loot Tables: Variable Resources on Death

### The Problem

Phase 3 used fixed creature inventories. This creates predictability: every wolf drops the same items. With 20+ creatures and randomized dungeons (future phases), fixed drops become monotonous and reduce replay value.

### The Solution: Weighted Loot Tables

Each creature declares a `loot_table` with multiple sections:

```lua
loot_table = {
    -- Always drop (100% chance)
    always = {
        { template = "gnawed-bone" },
    },
    
    -- Weighted roll (pick one)
    on_death = {
        { item = { template = "silver-coin" }, weight = 20 },
        { item = { template = "torn-cloth" }, weight = 30 },
        { item = nil, weight = 50 },  -- 50% nothing
    },
    
    -- Variable quantity (e.g., 1-3 coins)
    variable = {
        { template = "copper-coin", min = 0, max = 3 },
    },
    
    -- Conditional drops (kill method)
    conditional = {
        fire_kill = { { template = "charred-hide" } },
        poison_kill = { { template = "tainted-meat" } },
    },
}
```

### Loot Table Examples

| Creature | Always | Weighted On_Death | Variable | Conditional |
|----------|--------|-------------------|----------|-------------|
| **Wolf** | gnawed-bone | 20% silver-coin, 30% torn-cloth, 50% nothing | 0-3 copper | fire→charred-hide |
| **Spider** | silk-bundle | 10% spider-fang | — | poison→tainted-venom |
| **Rat** | none | 50% grain-seed, 50% nothing | 0-2 copper | fire→ash-pile |

### Probabilistic Behavior

Each wolf death invokes `roll_loot_table()`:

1. **Always** section: gnawed-bone guaranteed every time
2. **Weighted roll**: RNG chooses one option (cumulative probability)
3. **Variable ranges**: RNG generates quantity between min-max
4. **Conditional**: If kill method recorded, apply conditional drops

**Result:** 10 wolf kills produce varied loot, increasing player agency and exploration motivation.

### Integration with Butchery

Loot tables are **independent** of butchery. Both fire when a creature dies:

1. **Loot table triggers:** Generic drops appear (coins, bones, cloth)
2. **Corpse reshape:** Large creature becomes furniture with butchery_products
3. **Player action:** Choose to butcher (meat, bone, hide) OR leave corpse

This creates two resource pathways:

| Pathway | Resources | Effort |
|---------|-----------|--------|
| **Loot path** | Coins, cloth, bones (instant) | None — happens on death |
| **Butchery path** | Meat, bone, hide (requires knife) | 5 minutes time investment |

Players can optimize based on immediate needs.

---

## 3. Silk Crafting Recipes

### The Problem

Phase 4 WAVE-4 introduces spider silk bundles as loot from dead spiders. Silk is a rare, valuable resource. But silk bundles alone have no crafting use — they sit in inventory as cosmetic items.

### The Solution: Tier 1 Crafting Recipes

The `craft` verb (expanded in WAVE-4) supports recipe-ID dispatch. Players type recipe name directly:

```
> craft silk-rope
> make silk-rope
> create silk-rope
```

All three map to the same recipe lookup.

### Recipe: Silk-Rope

| Field | Value |
|-------|-------|
| **Recipe ID** | `silk-rope` |
| **Ingredients** | 2× silk-bundle |
| **Tool Required** | None |
| **Narration** | "You twist the silk bundles together into a strong, lightweight rope." |
| **Result** | 1× silk-rope |
| **Cooldown** | None |

#### Silk-Rope Immediate Use-Case

Silk-rope is **immediately valuable** in Level 1:

- **Courtyard puzzle:** `tie rope to hook` → player can descend well safely (avoids fall damage)
- **Design intent:** Spider ecology becomes non-optional; silk is essential for puzzle progression
- **Future extensions (Phase 5+):** Rope for climbing, binding, construction

### Recipe: Silk-Bandage

| Field | Value |
|-------|-------|
| **Recipe ID** | `silk-bandage` |
| **Ingredients** | 1× silk-bundle |
| **Tool Required** | None |
| **Narration** | "You tear the silk into strips suitable for bandaging wounds." |
| **Result** | 2× silk-bandage (1 silk → 2 bandages) |
| **Cooldown** | None |

#### Silk-Bandage Mechanics (Dual-Purpose Healing)

Single-use consumable item. When used:

1. **Instant HP restoration:** +5 health immediately
2. **Bleeding cure:** If player has active bleeding injury, stops tick damage

**Usage:** Can be used during or outside combat (no safe-room restriction).

**FSM states:**
- `unused` → `used` (consumed after one use)
- Removed from inventory when used

**Design rationale:** Silk is a limited resource (only spiders drop silk). Bandages compete with rope crafting decisions, creating resource scarcity pressure.

### Recipe Expansion (Future)

| Ingredient | Recipe | Result | Phase |
|-----------|--------|--------|-------|
| Silk-bundle | silk-rope (2 bundles) | 1× silk-rope | P4 |
| Silk-bundle | silk-bandage (1 bundle) | 2× silk-bandage | P4 |
| Silk-bundle | silk-vest (5 bundles) | 1× wearable armor | P5+ |
| Silk-bundle | silk-thread (3 bundles) | 10× thread | P5+ (sewing) |

---

## 4. Crafting Syntax: Tier 1 Recipe-ID Dispatch

### Model: Simple Recipe Lookup

**Tier 1 (Phase 4):** Recipe ID as noun.

```
> craft silk-rope
> make silk-rope
> create silk-rope
```

Engine flow:

1. Parse command: `craft [recipe_id]`
2. Look up recipe in `crafting_recipes` table
3. Validate: player has all ingredients in inventory
4. Consume ingredients from inventory
5. Instantiate result
6. Print narration

### Verb Aliases

All dispatch to same handler:

| Verb | Recipe ID |
|------|-----------|
| `craft` | `silk-rope`, `silk-bandage` |
| `make` | `silk-rope`, `silk-bandage` |
| `create` | `silk-rope`, `silk-bandage` |

### Recipe Lookup Implementation

In `src/engine/verbs/crafting.lua`:

```lua
local crafting_recipes = {
    ["silk-rope"] = {
        ingredients = { { id = "silk-bundle", quantity = 2 } },
        requires_tool = nil,
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

### Validation Checklist

Before crafting executes:

- ✓ Recipe exists in table
- ✓ Player inventory has all ingredients
- ✓ Tool check (if required)
- ✓ Inventory space for result

### Design Rationale: Phase 4 Limitation

**Why not `craft rope from silk` syntax?**

Answer: Requires **Tier 3 GOAP planner** to parse natural language ingredients. Phase 4 focuses on the crafting *mechanics*, not the parser. Recipe-ID dispatch is simple, fast, and extensible.

**Future Phase 5:** Tier 3 planner adds `craft [result] from [ingredients]` after semantic parsing foundation is stable.

---

## 5. Balance Notes

### Resource Scarcity

Silk bundles are the **bottleneck resource**:

| Source | Drop Rate | Quantity |
|--------|-----------|----------|
| Spider loot | Always | 1 silk-bundle per spider |
| Butchery | Spider death | 1 silk-bundle (via butchery_products) |

**Result per spider death:**

1. Loot table triggers: 1 silk-bundle guaranteed
2. Corpse becomes furniture (butcherable)
3. Player butchers: gets 1 spider-meat + 1 silk-bundle (redundant!)

**Design decision:** Silk is intentionally limited. With ~3-5 spiders per playthrough (Phase 4 scope), players get 6-10 silk bundles. Enough for:

- **Option A:** 3-5 silk-ropes (puzzle use + future binding)
- **Option B:** 3-5 silk-bandages (emergency healing reserves)
- **Option C:** Mix of both (e.g., 2 ropes + 4 bandages)

### Crafting Time

Tier 1 recipes are **instantaneous** (no time advancement). This differs from butchery (5 minutes) and cooking (implicit time).

**Rationale:** Silk crafting is fine manual work, but simple and quick. Players don't wait; action feels immediate and satisfying.

### Tool Requirements

Current recipes require **no tools**. Future Phase 5+ recipes might require:

- Needle + thread (for finer silk items)
- Loom (for fabric crafting)
- Tanning rack (for leather processing)

---

## 6. Integration Points

### 1. Parser Embedding Index

`src/engine/parser/embedding-index.json` updated with:

- `craft`, `make`, `create` → verb aliases
- `silk-rope`, `silk-bandage` → recipe ID semantics
- ~15 new embedding phrases for disambiguation

### 2. Verb Handler Pipeline

Location: `src/engine/verbs/crafting.lua`

```lua
verbs.craft = function(context, noun)
    local recipe = crafting_recipes[noun]
    if not recipe then
        context.print("You don't know how to craft that.")
        return
    end
    
    -- Validate ingredients
    for _, ingredient in ipairs(recipe.ingredients) do
        local count = context.player:count_inventory(ingredient.id)
        if count < ingredient.quantity then
            context.print(string.format("You need %d %s.", ingredient.quantity, ingredient.id))
            return
        end
    end
    
    -- Consume ingredients
    for _, ingredient in ipairs(recipe.ingredients) do
        for i = 1, ingredient.quantity do
            context.player:remove_from_inventory(ingredient.id)
        end
    end
    
    -- Create result
    local result_instance = context.registry:instantiate(recipe.result.id)
    context.player:add_to_inventory(result_instance)
    
    context.print(recipe.narration)
end
```

### 3. Loot System Interaction

When spider dies:

1. `loot_table.always` triggers: 1 silk-bundle → room floor
2. `death.reshape()` → corpse becomes furniture with `butchery_products`
3. Player can:
   - Pick up loot silk
   - Butcher corpse for more silk (via `butchery_products`)
   - Craft immediately or store for later

### 4. Food System Interaction

Butchered meat feeds food system:

```
Wolf corpse → butcher → wolf-meat (raw) → cook (fire) → cooked-wolf-meat → eat → nutrition
```

---

## 7. Testing Strategy

### Test Coverage (WAVE-4 deliverables)

**File:** `test/crafting/test-silk-crafting.lua`

- ✅ Recipe lookup: `craft silk-rope` resolves recipe
- ✅ Ingredient validation: Insufficient silk → error
- ✅ Silk-rope creation: 2 bundles → 1 rope
- ✅ Silk-bandage creation: 1 bundle → 2 bandages
- ✅ Recipe narration prints
- ✅ Ingredients consumed from inventory
- ✅ Result added to inventory
- ✅ Verb aliases work: `craft`, `make`, `create` all resolve

### Integration Tests

- ✅ Kill spider → get silk loot
- ✅ Craft rope from silk → rope appears in inventory
- ✅ Use rope in courtyard puzzle (tied to hook)
- ✅ Craft bandage → heal 5 HP when used
- ✅ Bandage stops bleeding if active

---

## 8. Known Limitations & Future Extensions

| Limitation | Status | Phase |
|-----------|--------|-------|
| Recipe-ID syntax only | By design | P4 (Tier 1) |
| No multi-step recipes | Deferred | P5+ (recipe composition) |
| No recipe discovery | Deferred | P5+ (hint system) |
| No craft failure chance | Deferred | P5+ (skill progression) |
| No tool degradation on craft | Deferred | P5+ (durability) |
| No inventory space checks (advanced) | Deferred | P5+ (weight system) |

---

## 9. Glossary

| Term | Definition |
|------|-----------|
| **Crafting** | Player-driven transformation of ingredients into results using verb dispatch |
| **Recipe** | Metadata table defining ingredients, tool requirement, narration, and result |
| **Recipe ID** | Canonical name for recipe (e.g., `silk-rope`); used as noun in Tier 1 dispatch |
| **Ingredient** | Resource consumed by recipe (e.g., silk-bundle) |
| **Silk-bundle** | Loot item from dead spiders; crafting material for rope and bandages |
| **Silk-rope** | Crafted item; immediate use in courtyard well puzzle; future binding/climbing |
| **Silk-bandage** | Crafted item; single-use healing consumable; stops active bleeding |

---

## 10. Related Systems

- **Butchery System** (`../../architecture/engine/butchery-system.md`) — Creates meat/bone/hide from corpses
- **Loot Tables** (`../../architecture/engine/loot-tables.md`) — Drops silk bundles and other loot on creature death
- **Food System** (`food-system.md`) — Cooks butchered meat into nutrition
- **Tools System** (`tools-system.md`) — Defines tool capabilities (butchering, fire_source, etc.)
- **Parser Pipeline** (`../../architecture/parser/parser-design.md`) — Tier 1 recipe-ID dispatch
