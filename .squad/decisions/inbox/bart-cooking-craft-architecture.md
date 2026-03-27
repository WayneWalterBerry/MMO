# D-COOKING-CRAFT: Cooking-as-Craft Architecture

**Author:** Bart (Architect)  
**Date:** 2026-03-27  
**Status:** 🟢 Proposed  
**Category:** Architecture  
**Requested by:** Wayne Berry  
**Relates to:** D-14 (True Code Mutation), D-FOOD-SYSTEMS-RESEARCH

---

## Context

Wayne's directive: *"Some food can't be eaten without cooking, like raw flesh. You need to apply a craft like cooking to make the state change from raw flesh to edible meat. Or baking for grain into bread."*

This connects the **crafting system** (`src/engine/verbs/crafting.lua`) with the **mutation system** (D-14). After reading both systems, the existing `sew` verb in crafting.lua provides the exact template for cooking — it uses `material.crafting.sew` recipes on objects with tool gating and material consumption. Cooking follows the same pattern.

---

## Decision 1: Cooking Uses Mutation, Not FSM

**Choice: Option B — Mutation (D-14)**

Cooking transforms `raw-rat-meat.lua` → `cooked-rat-meat.lua` via the existing mutation system. This is the correct choice because:

1. **Cooked meat is a fundamentally different object.** Different name, different description, different sensory properties (smell, taste, feel), different nutrition, different material behavior, different keywords. This isn't a state — it's a transformation.
2. **D-14 Prime Directive:** "Code Mutation IS State Change." When you cook meat, the object's code is rewritten. The cooked-meat.lua file has completely different sensory text, edibility, nutrition, and room_presence.
3. **FSM is wrong here.** FSM is for objects that cycle through states while remaining the same object (candle: unlit → lit → extinguished). A raw chunk of meat that becomes cooked is not the same object with a flag change — it's a material transformation. Different smell, different taste, different texture, different weight (water loss), different everything.
4. **Precedent:** The existing `sew` verb already does this — cloth + needle → sewn item via `recipe.becomes`, which triggers mutation through `spawn_objects`. The `write` verb also demonstrates dynamic mutation via `ctx.mutation.mutate()`.

**Exception — FSM for spoilage AFTER cooking:** Cooked meat can use FSM states for post-cooking degradation: `fresh → cooling → cold → spoiling → spoiled`. That's legitimate FSM territory — same object degrading over time with changing sensory properties.

---

## Decision 2: `cook` Is a New Verb, Not a Craft Sub-Verb

**Choice: Dedicated `cook` verb with `bake`/`roast` as aliases.**

Rationale:
- Players will type `cook meat`, `cook rat`, `bake bread`, `roast meat` — these are natural language verbs, not "craft meat"
- The `sew` pattern in crafting.lua proves the model: each craft type gets its own verb handler (`sew`, `stitch`, `mend` are aliases)
- `cook` reads recipes from `obj.crafting.cook` — exactly how `sew` reads from `obj.crafting.sew`
- `bake` is an alias for `cook` — same mechanism, different word. The recipe on the object controls what happens, not the verb name.

Verb aliases:
```
cook → cook handler
roast → cook handler
bake → cook handler
grill → cook handler
fry → cook handler (future)
```

---

## Decision 3: Cooking Uses the `crafting` Field Pattern

The existing `sew` verb reads recipes from `material.crafting.sew`. Cooking follows the same convention: `obj.crafting.cook`.

### Raw Rat Meat — Object Definition

```lua
-- raw-rat-meat.lua
return {
    guid = "{a1b2c3d4-...}",
    template = "small-item",
    id = "raw-rat-meat",
    name = "a chunk of raw rat meat",
    keywords = {"rat meat", "raw meat", "meat", "raw rat meat", "flesh"},
    description = "A ragged chunk of dark red meat, torn from the rat's carcass. Blood still seeps from the torn edges.",

    material = "flesh",
    size = 1,
    weight = 0.2,
    portable = true,
    categories = {"small", "food", "raw", "perishable"},

    -- Edibility gating: NOT edible raw
    edible = false,
    on_eat_reject = "You can't eat this raw. You'd need to cook it first.",
    cookable = true,

    -- Sensory (on_feel mandatory)
    on_feel = "Cold, wet, slippery. Stringy fibers and the grit of small bones.",
    on_smell = "Raw blood and musk. The sharp copper smell of fresh meat.",
    on_taste = "You'd need to be truly desperate to eat this raw.",
    on_listen = "Silent. A faint drip of blood.",

    room_presence = "A chunk of raw meat lies on the ground, dark and bloody.",

    -- Crafting recipe: cook verb triggers mutation
    crafting = {
        cook = {
            becomes = "cooked-rat-meat",
            requires_tool = "fire_source",
            message = "You hold the meat over the flames. It sizzles and darkens, the blood hissing away. The smell shifts from raw copper to something almost appetizing.",
            fail_message_no_tool = "You need a fire source to cook this.",
        },
    },

    -- Mutation fallback (same recipe exposed for engine flexibility)
    mutations = {
        cook = {
            becomes = "cooked-rat-meat",
            requires_tool = "fire_source",
            message = "You cook the raw meat over the flames.",
        },
    },
}
```

### Cooked Rat Meat — Mutation Target

```lua
-- cooked-rat-meat.lua
return {
    guid = "{e5f6a7b8-...}",
    template = "small-item",
    id = "cooked-rat-meat",
    name = "a piece of cooked rat meat",
    keywords = {"rat meat", "cooked meat", "meat", "cooked rat meat", "food"},
    description = "A charred chunk of rat meat, browned and crispy at the edges. Not exactly a feast, but it smells better than it did raw.",

    material = "flesh",
    size = 1,
    weight = 0.15,  -- Water loss from cooking
    portable = true,
    categories = {"small", "food", "cooked", "perishable"},

    -- NOW edible
    edible = true,
    nutrition = 15,
    on_eat_message = "You chew the tough, gamey meat. Not good, but it fills your stomach.",
    cookable = false,  -- Already cooked

    -- Sensory properties completely different
    on_feel = "Warm and firm. The surface is slightly crispy, the inside dense and fibrous.",
    on_smell = "Charred meat — smoky, savory, with an undertone of gaminess.",
    on_taste = "Tough and gamey, but edible. The char adds a bitter smokiness.",
    on_listen = "Faint crackling as it cools.",

    room_presence = "A piece of cooked meat sits here, still faintly steaming.",

    -- Optional: FSM for post-cooking spoilage
    initial_state = "fresh",
    _state = "fresh",
    states = {
        fresh = {
            description = "A piece of cooked rat meat, still warm.",
            on_smell = "Charred meat — smoky, savory.",
            edible = true,
            nutrition = 15,
        },
        cold = {
            description = "A piece of cold cooked rat meat. Congealed grease coats the surface.",
            on_smell = "Cold grease and old meat.",
            edible = true,
            nutrition = 10,
        },
        spoiled = {
            description = "Rotten meat. Grey-green mold covers the surface.",
            on_smell = "Foul. Rotting meat and mold.",
            edible = false,
        },
    },
    transitions = {
        { from = "fresh", to = "cold", verb = "_tick", condition = "time_elapsed", duration = 3600 },
        { from = "cold", to = "spoiled", verb = "_tick", condition = "time_elapsed", duration = 7200 },
    },
}
```

### Grain → Bread (Baking Example)

```lua
-- grain-sack.lua already exists. Grain is NOT directly edible or bakeable —
-- it's a CRAFTING INGREDIENT. The player extracts grain from the sack,
-- then bakes it. The grain-sack object stays as a puzzle container.

-- For a standalone grain object (extracted or found loose):
-- grain-handful.lua
return {
    guid = "{...}",
    template = "small-item",
    id = "grain-handful",
    name = "a handful of barley grain",
    keywords = {"grain", "barley", "kernels"},
    description = "A handful of dry barley kernels.",

    edible = false,
    on_eat_reject = "Raw grain is too hard to chew. You'd need to grind and bake it.",
    cookable = true,

    on_feel = "Dry, hard little kernels that shift between your fingers.",
    on_smell = "Dusty, faintly nutty.",

    crafting = {
        cook = {
            becomes = "flatbread",
            requires_tool = "fire_source",
            message = "You spread the grain on a flat stone near the fire. With patience, the kernels soften and fuse into a crude flatbread.",
            fail_message_no_tool = "You need a fire source to bake this.",
        },
    },

    mutations = {
        cook = {
            becomes = "flatbread",
            requires_tool = "fire_source",
            message = "You bake the grain into a rough flatbread.",
        },
    },
}
```

---

## Decision 4: Edibility Gating in the Eat Handler

The existing `eat` handler in `survival.lua` (line 84) checks `obj.edible`. This already works for cooked food. For raw food, we add a hint mechanism:

**Current behavior (line 84-103):**
```lua
if obj.edible then
    print("You eat " .. (obj.name or "it") .. ".")
    -- ... consume object
else
    print("You can't eat " .. (obj.name or "that") .. ".")
end
```

**Proposed enhancement to eat handler:**
```lua
if obj.edible then
    -- existing eat logic (unchanged)
elseif obj.cookable then
    -- Object exists but needs cooking first
    print(obj.on_eat_reject or "You can't eat that raw. Try cooking it first.")
else
    print("You can't eat " .. (obj.name or "that") .. ".")
end
```

This is a **2-line addition** to the existing eat handler. The `on_eat_reject` field lets each object provide a custom rejection message. If absent, a generic "try cooking it first" hint guides the player.

---

## Decision 5: Tool Resolution — Fire Source Scope

**Cooking requires `fire_source` capability. The tool can be anywhere visible — hands, room, or surfaces.**

The existing `find_visible_tool(ctx, capability)` helper already searches the room, surfaces, and inventory for tools by capability. The `cook` verb uses this — you don't need to hold fire; you just need fire to be accessible.

**Scenarios:**
- Player holds raw meat + lit candle in hands → cook works (candle `provides_tool = "fire_source"` when lit)
- Player holds raw meat, lit torch is on the wall → cook works (torch in room scope)
- Player holds raw meat, fireplace is in room → cook works (fireplace provides `fire_source`)
- Player holds raw meat, no fire anywhere → "You need a fire source to cook this."

**Why scope-visible, not hands-only:** Cooking over a fireplace or torch on the wall is realistic. You don't hold the fire — you hold the food near the fire. This matches how `sew` works: the tool (needle) must be in inventory, but the `find_tool_in_inventory` search also checks bags.

For cooking, we use `find_visible_tool` (broader scope) because fire sources are often environmental (fireplace, wall torch, campfire).

---

## Decision 6: Cook Verb Handler Architecture

The `cook` verb follows the exact `sew` pattern from `crafting.lua` (lines 233-381):

```lua
-- To be added to src/engine/verbs/crafting.lua
handlers["cook"] = function(ctx, noun)
    if noun == "" then
        print("Cook what? (Try: cook <food>)")
        return
    end

    -- Find the food (hands first, then visible)
    local food = find_in_inventory(ctx, noun)
    if not food then
        food = find_visible(ctx, noun)
    end
    if not food then
        err_not_found(ctx)
        return
    end

    -- Check if food has crafting.cook recipe
    if not food.crafting or not food.crafting.cook then
        if not food.cookable then
            print("You can't cook " .. (food.name or "that") .. ".")
        else
            print("You're not sure how to cook " .. (food.name or "that") .. ".")
        end
        return
    end

    local recipe = food.crafting.cook

    -- Find fire source (visible scope — room, surfaces, or inventory)
    local fire = find_visible_tool(ctx, recipe.requires_tool or "fire_source")
    if not fire then
        fire = find_tool_in_inventory(ctx, recipe.requires_tool or "fire_source")
    end
    if not fire then
        print(recipe.fail_message_no_tool or "You need a fire source to cook.")
        return
    end

    -- Perform mutation: raw-X → cooked-X
    local mut_data = recipe
    local ok = perform_mutation(ctx, food, mut_data)
    if not ok then
        print("Something goes wrong — the food burns to ash.")
        return
    end

    -- Consume fire tool charge if applicable (matches burn down)
    consume_tool_charge(ctx, fire)

    -- Success message
    print(recipe.message or ("You cook " .. (food.name or "it") .. " over the flames."))
end

handlers["roast"] = handlers["cook"]
handlers["bake"] = handlers["cook"]
handlers["grill"] = handlers["cook"]
```

---

## Decision 7: What Tools/Stations Exist or Need Creating

### Already Exists
| Object | Provides | Notes |
|--------|----------|-------|
| match (lit) | `fire_source` | Consumable, burns out. Short cooking window. |
| candle (lit) | `fire_source` | Sustained fire. Good for simple cooking. |
| oil-lantern (lit) | `fire_source` | Sustained fire. |
| torch (lit) | `fire_source` | Room-scope fire source, not held. |

### Needed for Level 1 (Kitchen Room)
| Object | Provides | Priority |
|--------|----------|----------|
| hearth / kitchen-fireplace | `fire_source` (when lit) | **High** — the kitchen already has cooking-fire smell references in hallway-east-door and courtyard-kitchen-door. The fireplace is implied. |

### Future (Level 2+)
| Object | Provides | Priority |
|--------|----------|----------|
| campfire | `fire_source` | Medium — outdoor cooking |
| iron-pot | `cooking_vessel` | Low — multi-ingredient recipes |
| oven | `fire_source` + `baking_surface` | Low — advanced baking |

---

## Summary: What This Architecture Gives Us

1. **Zero new engine infrastructure.** Cooking uses existing mutation, tool capability, and crafting recipe systems.
2. **Object-declared behavior (Principle 8).** The `crafting.cook` recipe lives on the object. The engine doesn't know about "cooking" — it just follows recipes.
3. **D-14 compliance.** `raw-rat-meat.lua` is rewritten to `cooked-rat-meat.lua`. Code IS state.
4. **Natural language verbs.** `cook meat`, `bake grain`, `roast rat` all work via aliases.
5. **Edibility gating.** Raw food has `edible = false` + `on_eat_reject` hint. Cooked food has `edible = true`. The eat handler needs 2 new lines.
6. **Tool flexibility.** Any `fire_source` works — matches, candles, torches, fireplaces. Capability matching, not item-ID matching.

### Impact
- **Flanders:** Create `raw-rat-meat.lua`, `cooked-rat-meat.lua`, `flatbread.lua`, and any other food objects
- **Moe:** Wire hearth/fireplace into kitchen room when kitchen is built
- **Smithers:** Add `cook`/`roast`/`bake`/`grill` verb handler to `crafting.lua`; add `cookable` check to eat handler in `survival.lua`
- **Nelson:** Tests: cook with fire → mutation, cook without fire → rejection, eat raw → rejection + hint, eat cooked → success
- **Sideshow Bob:** Design cooking puzzles (rat bait, food trade, hunger pressure)

---

## Affected Files

| File | Change |
|------|--------|
| `src/engine/verbs/crafting.lua` | Add `cook` handler + aliases |
| `src/engine/verbs/survival.lua` | Add `cookable` check to eat handler (2 lines) |
| `src/meta/objects/raw-rat-meat.lua` | New object (Flanders) |
| `src/meta/objects/cooked-rat-meat.lua` | New object (Flanders) |
| `src/meta/objects/grain-handful.lua` | New object (Flanders) |
| `src/meta/objects/flatbread.lua` | New object (Flanders) |
| `test/verbs/test-cook.lua` | New test file (Nelson) |
