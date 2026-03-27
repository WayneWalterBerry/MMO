# Deep Architecture Analysis — How Creatures Become Food

**Author:** Bart (Architect)  
**Date:** 2026-03-30  
**Status:** PROPOSED — Awaiting Wayne's review  
**Category:** Architecture  
**Requested by:** Wayne Berry  
**Related:** D-14, D-INANIMATE, D-CREATURES-DIRECTORY, D-FOOD-SYSTEMS-RESEARCH

---

## The Question

> "A dead creature can be food, and items like grain in a bag can be food. Both objects and creatures (two different meta types) can be food. How do we work that into our system?"

This is a foundational type-system question. It asks: when an entity crosses a categorical boundary (creature → object, or object → edible-object), what architectural mechanism governs that crossing?

---

## Current System State

Before analyzing options, here's what exists today:

### Templates (7 total)
| Template | Category | Key traits |
|----------|----------|------------|
| `room` | Environment | exits, contents |
| `furniture` | Inanimate, heavy | portable=false, surfaces |
| `container` | Inanimate, holdable | container=true, capacity |
| `small-item` | Inanimate, portable | portable=true, lightweight |
| `sheet` | Inanimate, fabric | material="fabric", tearable |
| `creature` | Animate | behavior, drives, FSM, health, reactions |
| `portal` | Passage | portal metadata, traversable states |

### Creature Template Structure
The creature template provides: `animate=true`, `behavior={}`, `drives={}`, `reactions={}`, `movement={}`, `awareness={}`, `health`, `body_tree`, `combat={}`. Its FSM includes alive states and a `dead` state where `animate=false, portable=true`.

### Mutation System (D-14)
`mutation.mutate(reg, ldr, object_id, new_source, templates)`:
- Loads new source via sandboxed `load_source`
- Resolves template if present
- **Preserves: `location`, `container`, surface contents, root contents**
- Replaces registry entry via `reg:register(object_id, new_obj)` — **same ID slot**

### Registry
- ID-indexed (`_objects[id]`)
- GUID-indexed (`_guid_index[normalized_guid]`)
- `register()` replaces any existing entry at that ID
- No type checking — the registry doesn't know or care about templates

### Loader
- `resolve_template()` deep-merges template under instance, then **deletes `template` field** (`resolved.template = nil`)
- At runtime, objects don't carry their template name — it's consumed during loading

### Key Observation
The registry is type-agnostic. It stores tables. There is no "creature registry" vs "object registry." Once loaded, a creature is just a table with extra fields. This is architecturally significant — it means type transitions don't require registry migration.

---

## Option A: Pure D-14 Mutation — Creature Dies → Mutates to Food Object

### Mechanism
When a rat takes lethal damage, instead of (or after) transitioning to its `dead` FSM state, the engine triggers a mutation: `rat.lua` → `dead-rat.lua`. The dead-rat file declares `template = "small-item"` with food metadata.

### Code Example

```lua
-- src/meta/creatures/rat.lua (add mutation declaration)
mutations = {
    kill = {
        becomes = "dead-rat",
        message = "The rat shudders and goes still.",
    },
},
```

```lua
-- src/meta/objects/dead-rat.lua (the mutation target)
return {
    guid = "{new-guid-dead-rat}",
    template = "small-item",
    id = "dead-rat",
    name = "a dead rat",
    keywords = {"dead rat", "rat", "rat corpse", "corpse", "carcass"},
    description = "A limp brown rat, its matted fur dark with blood. The beady eyes are glazed and empty.",

    size = 1,
    weight = 0.3,
    portable = true,
    material = "flesh",
    categories = {"food", "corpse"},

    -- Food metadata (trait pattern — see Option B analysis)
    edible = true,
    food = {
        nutrition = 3,
        risk = "disease",
        risk_chance = 0.4,
        raw = true,
        on_eat_message = "You tear into the raw rat flesh. It's gamey and foul.",
    },

    -- Sensory (retains creature identity for examination)
    on_feel = "Cooling fur over a limp body. The tail hangs like wet string.",
    on_smell = "Blood and musk. The sharp copper of death.",
    on_listen = "Nothing. Absolutely nothing.",
    on_taste = "Fur and blood. Gamey, iron-rich. You immediately regret this.",

    -- Can be cooked (second mutation)
    mutations = {
        cook = {
            becomes = "cooked-rat-meat",
            message = "The rat flesh sizzles and chars. The smell is... tolerable.",
            requires_tool = "fire_source",
        },
    },
}
```

```lua
-- src/meta/objects/cooked-rat-meat.lua (cooking mutation target)
return {
    guid = "{new-guid-cooked-rat}",
    template = "small-item",
    id = "cooked-rat-meat",
    name = "cooked rat meat",
    keywords = {"rat meat", "cooked rat", "cooked meat", "meat"},
    description = "A charred hunk of rat meat. Not appetizing, but protein is protein.",

    size = 1,
    weight = 0.2,
    portable = true,
    material = "meat",
    categories = {"food"},

    edible = true,
    food = {
        nutrition = 6,
        risk = nil,
        raw = false,
        on_eat_message = "Tough and gamey, but it fills your stomach. You've eaten worse. Probably.",
    },

    on_feel = "Warm, slightly greasy meat. Charred on the outside.",
    on_smell = "Roasted meat with an undertone of musk.",
    on_listen = "Silent.",
    on_taste = "Gamey. Fibrous. Edible.",

    mutations = {},
}
```

### What Happens Mechanically

1. Rat takes lethal damage → engine detects `health_zero` condition
2. Engine looks up `mutations.kill` on the rat object
3. `mutation.mutate(reg, ldr, "rat", dead_rat_source, templates)` is called
4. Mutation loads `dead-rat.lua`, resolves `template = "small-item"`
5. Preserves `location` and `container` — dead rat stays where the live rat was
6. Registry entry at key "rat" is **replaced** — now points to the dead-rat table
7. The old creature data (behavior, drives, reactions, movement) is **gone**
8. The object is now a portable small-item with `edible = true`

### GUID Analysis

The mutation system's handling of GUIDs is clean here:
- The old rat's GUID (`{071e73f6-...}`) is dropped (it was in `old` but not carried forward)
- The dead-rat has its own GUID (`{new-guid-dead-rat}`)
- The registry ID stays the same ("rat") — all containment references survive
- The GUID index gets updated by `register()`

### Creature Tick Impact

**Critical question:** Does the creature tick system check `animate` or template?

If the creature tick iterates registered objects looking for `animate == true`, then mutation solves this automatically — dead-rat has no `animate` field (inherits nothing from small-item template, which doesn't define it). The tick skips it.

If the creature tick iterates a separate "creatures" list, then mutation needs to also remove the object from that list. This is a one-line addition to the kill handler.

### Pros
- **Pure D-14.** Code IS state. The creature literally becomes a different thing at the code level.
- **Clean type crossing.** No dual-type ambiguity. The dead rat IS a small-item. Period.
- **Creature identity preserved via sensory text.** You can still "examine dead rat" and get rich description. Keywords include "rat" — the parser resolves it.
- **Mutation chain.** `rat.lua` → `dead-rat.lua` → `cooked-rat-meat.lua`. Each step is a clean D-14 code rewrite.
- **No engine changes needed.** The mutation system, loader, and registry already handle this. Template resolution at mutation time is already implemented (line 27-32 of mutation/init.lua).
- **Principle 8 compliant.** Objects declare `mutations.kill.becomes`; engine executes it generically.

### Cons
- **Object file proliferation.** Each creature needs a `dead-X.lua` file (and possibly `cooked-X-meat.lua`). For 10 creature types, that's 10-20 extra files.
- **Rat history lost at runtime.** Once mutated, the creature's behavior/drives/combat data is gone. You can't query "what kind of creature was this?" without adding a `source_creature` field to dead-rat.lua.
- **Requires mutation trigger in kill path.** The damage/kill handler must know to call `mutation.mutate` rather than just FSM-transitioning to `dead` state. This is a design choice, not a bug.

### Complexity Estimate: LOW
Zero engine changes. 1 new file per creature death form. Verb handler needs a kill→mutation path (small).

---

## Option B: Mixin/Trait — `food` as Metadata, Not a Template

### Mechanism
"Food" is not a type — it's a set of metadata fields that any object (or creature) can declare. The `eat` verb checks for `edible == true` and reads `food = {...}` metadata. No template inheritance required.

### Code Example — Grain in a Bag

```lua
-- src/meta/objects/grain-sack.lua
return {
    guid = "{grain-sack-guid}",
    template = "small-item",
    id = "grain-sack",
    name = "a sack of grain",
    keywords = {"grain", "sack of grain", "grain sack", "seeds"},
    description = "A rough burlap sack, heavy with grain. Individual kernels press against the fabric.",

    size = 2,
    weight = 1.5,
    portable = true,
    material = "grain",
    categories = {"food", "grain"},

    -- Food trait (not a template — just metadata)
    edible = true,
    food = {
        nutrition = 4,
        risk = nil,
        raw = true,
        on_eat_message = "You scoop handfuls of dry grain into your mouth. It's bland but filling.",
    },

    on_feel = "Rough burlap. Inside, thousands of small hard kernels shift under your fingers.",
    on_smell = "Dry, dusty, faintly sweet. Like a barn in autumn.",
    on_listen = "A faint shushing sound as grain shifts inside.",
    on_taste = "Dry. Nutty. Gritty between your teeth.",

    mutations = {
        cook = {
            becomes = "porridge",
            message = "The grain softens in the hot water, thickening into a lumpy porridge.",
            requires_tool = "fire_source",
        },
    },
}
```

### Code Example — Dead Rat (Combined with Option A)

```lua
-- src/meta/objects/dead-rat.lua (same as Option A — the trait is IN the file)
return {
    template = "small-item",
    -- ...
    edible = true,
    food = {
        nutrition = 3,
        risk = "disease",
        -- ...
    },
}
```

### Eat Verb Implementation

```lua
-- In verbs/survival.lua (already nearly this — just check food metadata)
handlers["eat"] = function(ctx, noun)
    if noun == "" then
        print("Eat what?")
        return
    end

    local obj = find_in_inventory(ctx, noun)
    if not obj then obj = find_visible(ctx, noun) end
    if not obj then err_not_found(ctx) return end

    -- Trait check — not template check
    if not obj.edible then
        print("You can't eat " .. (obj.name or "that") .. ".")
        return
    end

    -- Food metadata drives behavior
    local food = obj.food or {}
    print("You eat " .. (obj.name or "it") .. ".")
    if food.on_eat_message then
        print(food.on_eat_message)
    end

    -- Risk processing (disease, poison)
    if food.risk and math.random() < (food.risk_chance or 0.5) then
        -- delegate to effects/injuries system
        effects.apply(ctx, food.risk, ctx.player)
    end

    -- Nutrition
    if food.nutrition and ctx.player.hunger then
        ctx.player.hunger = math.min(100, ctx.player.hunger + food.nutrition)
    end

    -- Hooks
    if obj.on_eat and type(obj.on_eat) == "function" then
        obj.on_eat(obj, ctx)
    end

    -- Remove consumed object
    remove_from_location(ctx, obj)
    ctx.registry:remove(obj.id)
end
```

### Key Insight: Option B Is Not an Alternative to Option A — It's the Same Thing

Look carefully. The dead-rat in Option A already uses `edible = true` and `food = {...}` metadata. That IS Option B's trait pattern. The grain-sack does the same thing. The `eat` verb checks `obj.edible` — it doesn't check `obj.template`.

**Option B is not a standalone option. It's the metadata convention that ALL options use.** The question isn't "trait vs template" — it's "how does a creature BECOME an object that has the food trait?"

### Pros
- **Principle 8 pure.** Engine checks metadata. Objects declare edibility. No type-coupling.
- **Works for everything.** Grain, bread, raw meat, cooked meat, poisonous mushrooms, mysterious potions — all just objects with `edible = true`.
- **Already implemented.** The current `eat` verb stub already checks `obj.edible` (line 84 of survival.lua). We just need to enrich it.
- **Zero template changes.** No new templates needed.
- **Composable.** A container can also be edible (eat the wax seal on a bottle). Furniture could be edible (gingerbread house). No type conflicts.

### Cons
- **No enforced defaults.** Every food object must manually declare `nutrition`, `risk`, etc. No template provides sensible defaults. (Mitigated: code review + meta-lint.)
- **Doesn't answer the creature→object question.** This tells you how to eat things, not how a rat becomes a thing you can eat.

### Complexity Estimate: TRIVIAL
The eat verb already has this pattern. Just add `food = {}` to object .lua files.

---

## Option C: Multiple Templates (Array of Templates)

### Mechanism
An object declares `template = {"small-item", "food"}` — an array. The loader resolves both and deep-merges them in order.

### Code Example

```lua
-- src/meta/templates/food.lua (new template)
return {
    guid = "{food-template-guid}",
    id = "food",

    edible = true,
    food = {
        nutrition = 0,
        risk = nil,
        risk_chance = 0,
        raw = false,
        spoilage_rate = 0,
        freshness = 100,
    },

    categories = {"food"},
}
```

```lua
-- src/meta/objects/grain-sack.lua (multi-template)
return {
    template = {"small-item", "food"},  -- ARRAY
    id = "grain-sack",
    name = "a sack of grain",
    food = {
        nutrition = 4,
        raw = true,
    },
    -- ...
}
```

### Loader Change Required

```lua
-- engine/loader/init.lua — resolve_template must handle arrays
function loader.resolve_template(object, templates)
    if not object.template then
        return object, nil
    end

    local template_ids = object.template
    -- Normalize to array
    if type(template_ids) == "string" then
        template_ids = { template_ids }
    end

    -- Merge templates in order (later templates override earlier)
    local merged_base = {}
    for _, tid in ipairs(template_ids) do
        local tmpl = templates[tid]
        if not tmpl then
            return nil, "template '" .. tostring(tid) .. "' not found"
        end
        merged_base = deep_merge(merged_base, tmpl)
    end

    local resolved = deep_merge(merged_base, object)
    resolved.template = nil
    return resolved, nil
end
```

### Problems

1. **Merge order ambiguity.** If `small-item` defines `categories = {}` and `food` defines `categories = {"food"}`, deep_merge replaces the array (per current implementation — "arrays are replaced, not appended"). So `template = {"food", "small-item"}` would lose `{"food"}`. Order matters and it's not obvious.

2. **Field conflicts.** If two templates define the same field with different semantics, the merge is unpredictable. `small-item.container = false` vs a hypothetical `container.container = true` — which wins?

3. **Template identity lost.** After resolution, `resolved.template = nil`. There's no record of WHICH templates contributed. Debugging becomes harder.

4. **Mutation interaction.** When `dead-rat.lua` declares `template = {"small-item", "food"}`, mutation calls `resolve_template`. The mutation system must pass the templates table. It already does (line 27-32), but array resolution changes the contract.

5. **Meta-lint impact.** The linter validates template fields. Array templates require entirely new validation logic.

6. **Every consumer changes.** Anything that reads `obj.template` (even though it's nil at runtime) or reasons about template identity needs updating.

### Pros
- **Formal type composition.** An object IS-A small-item AND IS-A food. Clean conceptually.
- **Default propagation.** Food template provides sensible defaults (nutrition=0, spoilage_rate=0) so objects don't repeat boilerplate.

### Cons
- **Major loader refactor.** `resolve_template` changes from simple lookup to ordered multi-merge.
- **Ordering semantics.** Must be documented and enforced. Subtle bugs from wrong order.
- **Violates simplicity.** Our templates are single-inheritance by design. This makes them multiple-inheritance, which is a well-known source of complexity (the "diamond problem").
- **Overkill for food.** We're adding multi-template resolution to solve a problem that `edible = true` already solves.
- **Still doesn't address creature→object.** The dead rat still needs mutation to change from `template = "creature"` to `template = {"small-item", "food"}`. The crossing mechanism is the same as Option A.

### Complexity Estimate: HIGH
Loader rewrite. Meta-lint rewrite. Mutation interaction testing. Template ordering documentation. All for a problem that metadata traits solve without any engine changes.

---

## Option D: Food Template Extends Small-Item

### Mechanism
Create a `food` template that inherits from `small-item` via Lua table composition (not engine-level template chaining — we don't have that). The food template deep-merges small-item's defaults with food-specific additions.

### Code Example

```lua
-- src/meta/templates/food.lua
-- Food template: portable edible item. Composes small-item defaults.
local small_item = dofile("src/meta/templates/small-item.lua")
-- ^ This violates the sandboxed loader. Templates can't require other templates.

-- Alternative: manually duplicate small-item fields + add food fields
return {
    guid = "{food-template-guid}",
    id = "food",
    name = "a food item",
    keywords = {},
    description = "Something edible.",

    -- From small-item
    size = 1,
    weight = 0.2,
    portable = true,
    material = "organic",
    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    -- Food-specific
    edible = true,
    food = {
        nutrition = 0,
        risk = nil,
        risk_chance = 0,
        raw = false,
        spoilage_rate = 0,
        freshness = 100,
    },

    categories = {"food"},

    mutations = {},
}
```

```lua
-- src/meta/objects/grain-sack.lua
return {
    template = "food",           -- single template, gets all defaults
    id = "grain-sack",
    food = { nutrition = 4, raw = true },
    -- ...
}
```

### Problems

1. **Template chaining isn't supported.** The loader resolves ONE template. `food` can't declare `template = "small-item"` because templates aren't instances — they're flat definitions. We'd have to manually duplicate small-item's fields in the food template.

2. **Duplication drift.** If small-item adds a field, food template must be manually updated. No automatic inheritance.

3. **Furniture that's food?** A gingerbread house is furniture AND food. `template = "food"` loses furniture properties. Back to the multi-template problem.

4. **Creature crossing still needs mutation.** Dead rat mutates from `template = "creature"` to `template = "food"`. Same mechanism as Option A.

### Pros
- **Clean single inheritance.** `template = "food"` is simple and familiar.
- **Sensible defaults.** Food objects get nutrition=0, spoilage_rate=0, etc. without declaring them.
- **Eat verb works the same way.** Still checks `obj.edible` (Principle 8).

### Cons
- **Template duplication.** Food template must copy small-item fields manually.
- **Not composable.** Can't have food+furniture, food+container without more templates (edible-container, edible-furniture...). Combinatorial explosion.
- **Marginal benefit over Option B.** The only thing a food template gives you over raw `edible = true` metadata is default values. That's useful but not worth the architectural commitment.

### Complexity Estimate: LOW-MEDIUM
One new template file. No engine changes. But creates a maintenance burden from field duplication and limits composability.

---

## Principle Compliance Matrix

| Principle | Option A (Mutation) | Option B (Trait) | Option C (Multi-Template) | Option D (Food Template) |
|-----------|:------------------:|:----------------:|:------------------------:|:------------------------:|
| **P0: Inanimate** | ✅ Dead rat IS inanimate | ✅ Trait on inanimate objects | ✅ | ✅ |
| **P1: Code-derived** | ✅ Code defines new form | ✅ Code declares metadata | ✅ | ✅ |
| **P2: Base→Instance** | ✅ Dead-rat is its own base | ✅ No change | ✅ | ✅ |
| **P3: FSM+State** | ✅ Food can have FSM (fresh→spoiled) | ✅ FSM independent of edibility | ✅ | ✅ |
| **P4: Composite** | ✅ Dead rat can contain items | ✅ No change | ✅ | ✅ |
| **P5: Multiple instances** | ✅ Each dead rat is unique | ✅ No change | ✅ | ✅ |
| **P6: Sensory space** | ✅ Dead-rat has full sensory | ✅ Sensory per object | ✅ | ✅ |
| **P7: Spatial** | ✅ Mutation preserves location | ✅ No change | ✅ | ✅ |
| **P8: Engine executes metadata** | ✅ `mutations.kill` is metadata | ✅ `edible` is metadata | ✅ | ✅ |
| **P9: Material consistency** | ✅ material="flesh" | ✅ material-based | ✅ | ✅ |
| **D-14: Code IS state** | ✅ Code literally transforms | ⚠️ Doesn't address state change | ⚠️ Same as B for crossing | ⚠️ Same as B for crossing |

---

## Impact Analysis on Engine Modules

| Module | Option A | Option B | Option C | Option D |
|--------|----------|----------|----------|----------|
| **Loader** | No change | No change | **MAJOR rewrite** (array template resolution) | No change |
| **Registry** | No change (already type-agnostic) | No change | No change | No change |
| **Mutation** | No change (already resolves templates during mutation) | No change | Must handle array templates | No change |
| **FSM** | Kill transition triggers mutation | No change | No change | No change |
| **Creature Tick** | Must skip mutated objects (check `animate`) | No change | No change | No change |
| **Eat Verb** | Minor enrichment (already checks `edible`) | Same enrichment | Same | Same |
| **Meta-lint** | Validate dead-X files | Validate `food` metadata | **Rewrite** template validation | Validate food template |
| **Containment** | No change (mutation preserves location) | No change | No change | No change |
| **Effects** | Add food risk→injury processing | Same | Same | Same |

---

## The Hidden Insight: These Aren't Competing Options

Wayne framed this as "Option A vs B vs C vs D." But after deep analysis, I see something different:

**Option A (Mutation) answers: "How does a creature become an object?"**  
**Option B (Trait) answers: "How does the engine know something is edible?"**

These are different questions with complementary answers. They don't compete — they compose.

**Option C and D** are both attempts to formalize Option B into the template system. But Option B doesn't NEED formalization because Principle 8 already handles it: the engine executes metadata. `edible = true` IS the mechanism. Adding template machinery around it adds complexity without adding capability.

---

## RECOMMENDATION: Option A + B Hybrid (Mutation + Metadata Trait)

### The Architecture

1. **"Food" is a metadata trait, not a template.** Any object can be food by declaring `edible = true` and `food = {...}`. The `eat` verb checks this metadata. This is Principle 8 in its purest form.

2. **Creature death uses D-14 mutation to cross the type boundary.** When a creature dies, the kill handler triggers `mutation.mutate()` to replace the creature with an inanimate object. The new object's .lua file declares whatever traits it needs — including `edible = true` if appropriate.

3. **No new templates. No loader changes. No registry changes.**

### Why This Is Right

| Criterion | Justification |
|-----------|--------------|
| **D-14 compliance** | Creature→object is a code rewrite. The code IS the state. |
| **Principle 8** | `edible`, `food.nutrition`, `food.risk` — engine reads metadata, objects declare behavior. Zero food-specific engine logic. |
| **Principle 0** | Dead creature stops being animate. Clean categorical boundary. |
| **Composability** | Grain in a bag: `edible = true`. Dead rat: `edible = true`. Poisonous mushroom: `edible = true, food.risk = "poison"`. Wax candle stub: `edible = true, food.nutrition = 0, food.on_eat_message = "Why."`. ANY object can be food. |
| **Existing infrastructure** | Mutation already handles template resolution. Registry is type-agnostic. Eat verb already checks `edible`. |
| **Zero engine changes** | The entire food system is metadata-driven. Only verb enrichment needed. |

### The Kill→Mutation Flow

```
Player attacks rat → damage handler → health reaches 0
  → Check obj.mutations.kill
  → If defined: mutation.mutate(reg, ldr, rat_id, dead_rat_source, templates)
    → Dead-rat.lua loaded with template="small-item"
    → Location preserved, creature data gone
    → Registry entry replaced
    → Creature tick skips (no `animate` field)
  → If NOT defined: FSM transition to "dead" state (existing behavior)
    → Object stays a creature, just in dead state
    → Can STILL be mutated later (butcher verb?)
```

### Why NOT Option C (Multiple Templates)

Multiple templates solve the "IS-A food AND IS-A small-item" problem. But `food` isn't a type — it's a property. A candle isn't a "food-type" thing; it's a small-item that happens to be edible (if you're desperate enough). Multi-template inheritance adds engine complexity to solve a modeling error.

The analogy: in real life, "edible" isn't a category of object. It's a property. A shoe is leather (edible in extremis). A candle is wax (edible). Grain is grain (edible). A desk is wood (not edible). "Edible" crosscuts all categories. That's a trait, not a type.

### Why NOT Option D (Food Template)

A food template gives you default values for nutrition, spoilage, etc. That's useful but creates an artificial category. What template does a "candle stub you can eat in desperation" use? `small-item`? `food`? It can't be both without multi-template (Option C).

If we want food defaults, we can achieve them through:
1. **Meta-lint rule:** "If `edible = true`, object MUST have `food.nutrition`."
2. **Convention:** Copy-paste the `food = {...}` block from a reference.
3. **Future:** If we get 20+ food items, THEN consider a food template. Not before.

### What About Creature Identity?

Wayne asked: "Can you still examine dead rat and get rat info?"

Yes. The dead-rat.lua file contains:
- `keywords = {"dead rat", "rat", "rat corpse", "corpse"}` — parser resolves "rat"
- `description = "A limp brown rat..."` — full rat description, just dead
- Full sensory set (`on_feel`, `on_smell`, `on_listen`, `on_taste`) — all written for the dead state
- Optionally: `source_creature = "rat"` if we need programmatic tracing

The identity isn't lost. It's **encoded in the mutation target's code**. This is D-14: the code contains all the information.

### Implementation Roadmap

| Step | Work | Effort |
|------|------|--------|
| 1 | Add `mutations.kill` to `rat.lua` | 2 lines |
| 2 | Create `dead-rat.lua` with `edible = true, food = {...}` | 1 file (~50 lines) |
| 3 | Wire kill handler to call `mutation.mutate` when `mutations.kill` exists | ~15 lines in damage path |
| 4 | Enrich `eat` verb to process `food` metadata (nutrition, risk, effects) | ~30 lines (survival.lua) |
| 5 | Create `cooked-rat-meat.lua` for the cook mutation chain | 1 file (~40 lines) |
| 6 | Add `edible = true, food = {...}` to existing food objects (grain, bread, etc.) | ~5 lines per object |
| 7 | Meta-lint: if `edible = true`, require `food.nutrition` and `on_taste` | ~20 lines |

**Total estimated effort:** 4-6 hours. Zero engine module changes. All work is in metadata and verb handlers.

---

## Appendix: How Other Engines Handle This

| Engine | Mechanism | Notes |
|--------|-----------|-------|
| **Dwarf Fortress** | Butcher workshop transforms creature → meat/bones/hide items | Type transformation via workshop action. Creature is destroyed, items spawned. |
| **NetHack** | Kill drops a "corpse" item (new object type `FOOD_CLASS`) | Creature and corpse are separate entities. Corpse has `corpsenm` field linking back to monster type. |
| **Caves of Qud** | Butchery skill produces food items from corpses | Similar to DF. Creature death spawns a corpse object; butchery spawns food. |
| **Ultima Online** | Creature death spawns a "corpse container" with loot + meat | Corpse is a special container. Carving produces food items. |
| **MUDs (Diku/MERC)** | Creature death creates a "corpse" object with timer | Corpse is an item with `ITEM_CORPSE` flag. Dissipates after N ticks. |

**Common pattern:** Every engine treats death as a type transition. The creature stops existing; one or more items appear in its place. Our mutation system does exactly this, but more elegantly — the object ID persists, so containment references don't break.

---

## Summary

| Option | Verdict | Reason |
|--------|---------|--------|
| **A: Mutation** | ✅ USE — for creature→object crossing | Pure D-14. Already supported by mutation engine. |
| **B: Trait** | ✅ USE — for food metadata convention | Pure Principle 8. Already nearly implemented in eat verb. |
| **C: Multi-Template** | ❌ REJECT | Over-engineered. Solves a modeling error with engine complexity. |
| **D: Food Template** | ❌ DEFER | Not needed until we have 20+ food items. Revisit then. |

**Final answer:** Mutation handles the boundary crossing. Metadata traits handle edibility. Together they solve Wayne's question with zero engine changes, full principle compliance, and clean composability.

— Bart
