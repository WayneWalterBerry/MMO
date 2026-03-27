# Food System — Proof of Concept (WAVE-5)

## Overview

The food system is a **metadata-driven, object-oriented** design where food is not a template but a trait. Any object can become edible by declaring `edible = true` and a `food = {}` metadata table. This PoC implements basic consumption (eat/drink verbs), a spoilage FSM, and a creature-bait mechanic powered by hunger drives.

**Design Philosophy:** Eating is a buff, not a requirement. No hunger meter. No starvation clock. In a two-hand inventory system, forcing rations crowds out puzzle items.

**Reference:** Full vision in `plans/food-system-plan.md`. This document covers WAVE-5 PoC scope only.

---

## 1. Food Metadata

Food is declared via two object properties:

```lua
edible = true,                    -- Signals object can be consumed
food = {
    nutrition = 10,               -- Buff strength (0-100), not tracked per-player
    category = "snack",           -- Flavor: "snack", "meat", "liquid", etc.
    bait_value = 50,              -- Creature attractiveness (0-100)
    bait_target = "rodent",       -- Which creature type hunts this food ("rodent", "insect", etc.)
    risk = "disease",             -- Optional danger on consumption ("disease", "poison", etc.)
    risk_chance = 0.2,            -- Probability of risk trigger (0.0-1.0)
    spoil_time = 120,             -- Game ticks until fresh → stale (optional, PoC only)
}
```

**Key Rules:**
- `edible = false` + `food = {}` makes food inedible unless cooked (not in WAVE-5 PoC).
- No per-player nutrition tracking. Buff is temporary, flavor-only in PoC.
- **Every food object MUST declare `on_feel`, `on_smell`, `on_taste`** — sensory descriptions updated by FSM state.
- Objects inherit `small-item` template; no `food` template exists.

---

## 2. Eat/Drink Verbs

### `eat` Handler

Located in `src/engine/verbs/survival.lua`:

```lua
handlers["eat"] = function(ctx, noun)
    local obj = find_in_inventory(ctx, noun) or find_visible(ctx, noun)
    if not obj then return err_not_found(ctx) end
    
    if obj.edible then
        print("You eat " .. obj.name .. ".")
        if obj.on_eat_message then print(obj.on_eat_message) end
        if obj.on_eat and type(obj.on_eat) == "function" then
            obj.on_eat(obj, ctx)
        end
        remove_from_location(ctx, obj)
        ctx.registry:remove(obj.id)
    else
        print("You can't eat " .. obj.name .. ".")
    end
end
```

**Checks:**
- Object must be in inventory or visible.
- Object must declare `edible = true`.
- No effect system integration in WAVE-5 (buff is flavor-only).
- Object is removed from inventory and registry after consumption.

**Aliases:** `consume`, `devour`

### `drink` Handler

```lua
handlers["drink"] = function(ctx, noun)
    local target = noun:match("^from%s+(.+)") or noun
    local obj = find_in_inventory(ctx, target)
    if not obj then return err_not_found(ctx) end
    
    if obj.states then
        local trans = fsm_mod.get_transitions(obj)
        -- Find "drink" transition
        if trans then
            fsm_mod.transition(ctx.registry, obj.id, trans.to, {}, "drink")
            return
        end
    end
    print("You can't drink " .. obj.name .. ".")
end
```

**Checks:**
- Preposition strip: "drink from bottle" → "bottle".
- Requires FSM state + "drink" transition (e.g., potion → empty-potion).
- FSM triggers effect system (potions, poison, etc.).
- Can be restricted by creature injury (e.g., rabies blocks drinking).

**Aliases:** `quaff`, `sip`

---

## 3. Bait Mechanic

Food with `bait_value > 0` emits a stimulus that creatures detect. When a creature's hunger drive activates:

1. **Stimulus Emission:** Food object on ground broadcasts `food_stimulus` with its `bait_value`.
2. **Creature Detection:** Creature scans nearby room for food. If `bait_target` matches creature type and `bait_value` exceeds threshold:
   - Food becomes priority over wander.
   - Creature pathfinds to food.
3. **Consumption:** Creature reaches food, consumes it (object removed from room).
4. **No Instant Win:** Bait works cross-tick, not instantly. Player can intercept.

**Example:**
```lua
-- cheese.lua declares bait
cheese = {
    edible = true,
    food = { bait_value = 75, bait_target = "rodent" },
    name = "a wedge of cheese"
}

-- In creature instance (rat):
-- Hunger drive: "If food_stimulus > 60 and bait_target = 'rodent', move toward food"
```

**Limitations (PoC):**
- Bait does NOT work from closed containers (blocked by containment).
- No skill check (pure creature drive).
- No resource scarcity (unlimited food = unlimited lure).
- Bait priority does NOT override combat (if creature is attacking player, bait is ignored).

---

## 4. PoC Scope

### Included (WAVE-5)

| Feature | Status | File |
|---------|--------|------|
| **Food Metadata** | ✅ | Object `.lua` files |
| **Eat Verb** | ✅ | `src/engine/verbs/survival.lua` |
| **Drink Verb** | ✅ | `src/engine/verbs/survival.lua` |
| **Spoilage FSM** | ✅ | Food object state machine (fresh → stale → spoiled) |
| **Bait Stimulus** | ✅ | `src/engine/creatures/init.lua` (hunger drive) |
| **Test Coverage** | ✅ | `test/food/test-eat-drink.lua`, `test/food/test-bait.lua`, `test/food/test-food-objects.lua` |
| **Sample Objects** | ✅ | `src/meta/objects/cheese.lua`, `src/meta/objects/bread.lua` |

### NOT Included (Defer to Full Vision)

- **Cooking system** — No `cook` verb; food items only edible as-is.
- **Nutrition tracking** — No per-player buff state; flavor-only in PoC.
- **Hunger meter** — No player starvation; players don't starve.
- **Recipes** — No crafting recipes; single objects only.
- **Farming** — No food generation system.
- **Spoilage behavior** — FSM states exist but don't yet trigger AI behavior (e.g., creatures avoid spoiled food).

---

## 5. Food Objects (Examples)

### Cheese

```lua
return {
    guid = "{guid}",
    template = "small-item",
    id = "cheese",
    name = "a wedge of cheese",
    keywords = {"cheese", "wedge"},
    description = "A small wedge of hard cheese.",
    
    edible = true,
    food = {
        nutrition = 8,
        category = "snack",
        bait_value = 75,
        bait_target = "rodent",
        spoil_time = 120,
    },
    
    on_feel = "Hard, waxy edges. Room-temperature.",
    on_smell = "Sharp, tangy. Appetizing.",
    on_taste = "Salty, with a sharp bite.",
    on_eat_message = "You bite into the cheese. Delicious.",
    
    initial_state = "fresh",
    states = {
        fresh = { description = "A wedge of hard cheese." },
        stale = { description = "The cheese has hardened and lost its appeal." },
        spoiled = { description = "Green mold covers the cheese. Do not eat." },
    },
    transitions = {
        { from = "fresh", to = "stale", timer = 120, message = "The cheese begins to harden." },
        { from = "stale", to = "spoiled", timer = 60, message = "The cheese spoils." },
    }
}
```

### Bread

```lua
return {
    guid = "{guid}",
    template = "small-item",
    id = "bread",
    name = "a loaf of bread",
    keywords = {"bread", "loaf"},
    description = "A crusty loaf of dark bread.",
    
    edible = true,
    food = {
        nutrition = 12,
        category = "snack",
        bait_value = 50,
        bait_target = "rodent",
        spoil_time = 180,
    },
    
    on_feel = "Crusty exterior, soft inside. Warm.",
    on_smell = "Yeasty, fresh. Homemade.",
    on_taste = "Hearty grain flavor.",
    on_eat_message = "You tear off a hunk and chew. Satisfying.",
    
    initial_state = "fresh",
    states = {
        fresh = { description = "A crusty loaf of dark bread." },
        stale = { description = "The bread has gone hard and dry." },
        spoiled = { description = "Mold covers the bread. Inedible." },
    },
    transitions = {
        { from = "fresh", to = "stale", timer = 180 },
        { from = "stale", to = "spoiled", timer = 120 },
    }
}
```

---

## 6. Future Expansion

See `plans/food-system-plan.md` for the **full food system vision:**

1. **Cooking** — Raw meat → cooked meat (mutation, new object).
2. **Nutrition Tracking** — Player buff state machine (fed → hungry → starving).
3. **Creature Starvation** — AI abandons tasks if hunger exceeds threshold.
4. **Food Trade** — NPCs negotiate via food (not yet: no NPC shop system).
5. **Farming & Foraging** — World-generated food resources.
6. **Spoilage Behavior** — Creatures avoid spoiled food; mold spreads.

---

## Testing

### Test Files

| File | Coverage |
|------|----------|
| `test/food/test-eat-drink.lua` | Eat/drink verbs, restrictions, removal |
| `test/food/test-bait.lua` | Stimulus emission, creature detection, consumption |
| `test/food/test-food-objects.lua` | Food object load, FSM states, sensory |
| `test/food/test-food-spoilage.lua` | Spoilage timer, state transitions, sensory updates |

### Running Tests

```bash
lua test/food/test-eat-drink.lua
lua test/food/test-bait.lua
```

---

## Related Documentation

- `docs/design/npc-system.md` — Creature drives, stimuli, behavior.
- `docs/design/object-design-patterns.md` — FSM pattern, metadata traits.
- `docs/design/tools-system.md` — Tool/capability system (future: bait as tool).
- `plans/food-system-plan.md` — Full vision, design rationale.
- `plans/npc-combat-implementation-phase2.md` — WAVE-5 context, integration gates.
