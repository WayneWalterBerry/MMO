# Creature Death: In-Place Reshape Architecture

**Version:** 1.0  
**Date:** 2026-08-16  
**Author:** Brockman (Documentation) — Bart (Architecture Lead) review  
**Status:** ✅ SPECIFIED — Ready for WAVE-1 implementation  
**Decision:** D-CREATURE-DEATH-RESHAPE (Phase 3, v1.3)  
**Requested by:** Wayne "Effe" Berry  
**Prerequisite reading:** `docs/architecture/objects/core-principles.md` (D-14), `docs/architecture/engine/prime-directive-architecture.md`

---

## 1. Problem Statement

In Phase 2, creatures lived through combat and death but had no portable remains. Players killed a rat and it vanished or persisted as a furniture object with no loot, no cooking, no lifecycle. Phase 3 closes this gap: **when a creature dies, it becomes a portable, inspectable, cookable corpse in the same instance**.

### Design Goals

1. **D-14 Alignment:** The creature code literally transforms. No separate dead-creature files. The instance's shape changes in-place.
2. **GUID Preservation:** The creature instance keeps its identity (same GUID) but is no longer animate.
3. **Zero Engine Knowledge:** All death state — sensory text, cookability, container properties, spoilage FSM — is declared in the creature's `.lua` file. The engine is agnostic about what dies into what.
4. **Backward Compatibility:** Creatures without `death_state` declarations retain existing FSM dead state behavior.

---

## 2. Architecture: `reshape_instance()` Function

### 2.1 Conceptual Model

When a creature's health reaches zero:

1. **Engine detection:** Creature tick handler or combat system detects `health <= 0`
2. **Check for death_state:** Inspect creature instance for `death_state` metadata block
3. **If present:** Call `reshape_instance(instance, death_state, registry, room)` — transforms the living creature instance into a dead object instance in-place
4. **If absent:** Creature keeps existing FSM dead state (backward compat)
5. **Inventory drop:** Death drop process (WAVE-2) instantiates carried/worn items to room floor

**Key distinction:** This is NOT file-swap mutation (`mutation.mutate()` which loads a new `.lua` file). This is **instance-level metamorphosis** — the same Lua table object changes its template and properties without being replaced in the registry.

### 2.2 Engine Function Signature

**File:** `src/engine/creatures/init.lua`

```lua
-- reshape_instance(instance, death_state, registry, room)
--   -> void
--
-- Transforms a live creature instance into a dead object instance in-place.
-- Called when creature health reaches 0 and death_state is present.
-- Same GUID, different template and properties. Deregisters from creature system.
--
-- Args:
--   instance: The creature instance object to reshape
--   death_state: The death_state metadata block from the creature definition
--   registry: The global registry object
--   room: The room object where the creature is located
--
-- Side effects:
--   - Modifies instance table in-place (template, name, description, sensory, etc.)
--   - Deregisters instance from creature tick system
--   - Registers instance as a room object
--   - Clears all creature-only metadata (behavior, drives, reactions, etc.)

function M.reshape_instance(instance, death_state, registry, room)
    -- 1. Switch template
    instance.template = death_state.template  -- "small-item" or "furniture"

    -- 2. Overwrite identity properties
    instance.name = death_state.name
    instance.description = death_state.description
    instance.keywords = death_state.keywords
    instance.room_presence = death_state.room_presence

    -- 3. Overwrite sensory properties (mandatory: on_feel is primary dark sense)
    instance.on_feel = death_state.on_feel
    instance.on_smell = death_state.on_smell
    instance.on_listen = death_state.on_listen
    instance.on_taste = death_state.on_taste

    -- 4. Apply physical properties (animate flag + state flags)
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

    -- 7. Apply container properties (corpse can hold items)
    if death_state.container then
        instance.container = death_state.container
    end

    -- 8. Apply spoilage FSM (fresh → bloated → rotten → bones)
    if death_state.states then
        instance.states = death_state.states
        instance.initial_state = death_state.initial_state or "fresh"
        instance._state = instance.initial_state
        instance.transitions = death_state.transitions
    end

    -- 9. Emit optional reshape narration (if present)
    if death_state.reshape_narration then
        print(death_state.reshape_narration)
    end

    -- 10. Instantiate byproducts (if present, e.g., spider silk)
    if death_state.byproducts then
        for _, byproduct_id in ipairs(death_state.byproducts) do
            -- Create room-floor object for each byproduct
            local byproduct = registry:get(byproduct_id)
            if byproduct then
                registry:register_as_room_object(byproduct, room)
            end
        end
    end

    -- 11. Deregister from creature tick system
    M.deregister_creature(instance.guid)

    -- 12. Register as room object (so containment/search can find it)
    registry:register_as_room_object(instance, room)

    -- 13. Clear creature-only metadata (no longer alive)
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

### 2.3 D-14 Alignment: Code IS State

This function exemplifies **Principle D-14: Code Mutation IS State Change** from `docs/architecture/objects/core-principles.md`.

In the old pattern (v1.2), a creature's death would be modeled via FSM states:
```lua
states = {
    alive = { description = "A living rat..." },
    dead  = { description = "A dead rat...", portable = true, material = "flesh" }
}
```

This approach conflated two separate concepts: **the FSM state (alive/dead) vs. the object's domain (creature vs. inanimate object)**.

In the new pattern (v1.3), the creature instance **literally becomes a different type of object** by switching its template:

```lua
-- Before reshape_instance()
instance.template = "creature"
instance.animate = true
instance.alive = true
instance.behavior = { aggression = 5, ... }

-- After reshape_instance()
instance.template = "small-item"
instance.animate = false
instance.alive = false
instance.behavior = nil
instance.portable = true
instance.food = { category = "meat", cookable = true }
```

The Lua code describing the instance transforms. The instance remains in the registry with the same GUID, but its entire operational context changes. This is the strongest expression of D-14.

### 2.4 Distinction from `mutation.mutate()`

**`mutation.mutate()` (existing):**
- Loads a **different .lua file** (`dead-rat.lua` instead of `rat.lua`)
- Replaces the registry entry with a new object definition
- Used for permanent object transformations that require new code
- Example: breakable-mirror → mirror-broken

**`reshape_instance()` (new):**
- Applies a **metadata overlay** to the existing instance
- No new file is loaded; the creature file contains both living and dead forms
- Used for lifecycle transitions within a single object definition
- Example: rat (alive) → rat (dead, reshaped)

**Why not file-swap for death?** The death_state is intrinsically tied to the creature's biology. It lives in the same file because they're expressions of the same entity. A spider's death produces silk; a wolf's death leaves a large corpse. These are creature-specific data, not separate object definitions.

---

## 3. `death_state` Metadata Block Format

Each creature `.lua` file declares a `death_state` metadata block alongside its living creature data. This block contains **everything the reshaped dead instance needs**.

### 3.1 Full Schema

```lua
-- Inside creature.lua alongside living creature properties
death_state = {
    -- Template selection (controls shape after reshape)
    template = "small-item",           -- or "furniture" for large creatures

    -- Identity and description
    name = "a dead rat",               -- singular, article included
    description = "A dead rat...",     -- full examination text
    keywords = {"rat", "dead rat", "corpse", "rat corpse"},
    room_presence = "A dead rat lies crumpled on the floor.",

    -- Physical properties (D-9: Material Consistency)
    portable = true,                   -- can player take this?
    size = "tiny",                     -- inherited from living form if omitted
    weight = 0.3,                      -- inherited from living form if omitted
    material = "flesh",                -- matches living form

    -- Sensory properties (Principle 6: Sensory Space)
    -- MANDATORY: on_feel is primary dark sense
    on_feel = "Cooling fur over a limp body. The tail hangs like wet string.",
    on_smell = "Blood and musk. The sharp copper of death.",
    on_listen = "Nothing. Absolutely nothing.",
    on_taste = "Fur and blood. You immediately regret this decision.",

    -- Food system (edibility, cookability, effects)
    food = {
        category = "meat",             -- meat, plant, prepared, etc.
        raw = true,                    -- uncooked
        edible = false,                -- must cook first
        cookable = true,               -- can be cooked
    },

    -- Cooking recipe (read by cook verb in WAVE-3)
    crafting = {
        cook = {
            becomes = "cooked-rat-meat",  -- result object ID
            requires_tool = "fire_source", -- must have lit fire
            message = "You hold the rat over the flames...",
            fail_message_no_tool = "You need a fire source...",
        },
    },

    -- Container properties (corpse can hold items)
    container = {
        capacity = 1,                  -- how many items fit inside
        categories = { "tiny" },       -- size constraints
    },

    -- Spoilage FSM (fresh → bloated → rotten → bones)
    initial_state = "fresh",
    states = {
        fresh = {
            description = "A freshly killed rat...",
            room_presence = "A dead rat lies crumpled on the floor.",
            duration = 30,             -- ticks before transition
        },
        bloated = {
            description = "The rat's body has swollen...",
            room_presence = "A bloated rat carcass lies on the floor, reeking.",
            on_smell = "The sweet, cloying stench of decay.",
            food = { cookable = false },  -- spoiled, can't cook
            duration = 40,
        },
        rotten = {
            description = "The rat is a putrid mess...",
            room_presence = "A rotting rat carcass festers on the floor.",
            on_smell = "Overwhelming rot. Your eyes water.",
            food = { cookable = false, edible = false },  -- spoiled, poisonous
            duration = 60,
        },
        bones = {
            description = "A tiny scatter of cleaned rat bones.",
            room_presence = "A small pile of rat bones sits on the floor.",
            on_smell = "Nothing — just dry bone.",
            on_feel = "Tiny, fragile bones. They click together.",
            food = nil,                -- no longer food
        },
    },
    transitions = {
        { from = "fresh", to = "bloated", verb = "_tick", condition = "timer_expired" },
        { from = "bloated", to = "rotten", verb = "_tick", condition = "timer_expired" },
        { from = "rotten", to = "bones", verb = "_tick", condition = "timer_expired" },
    },

    -- Optional: narration when reshape happens
    reshape_narration = "The rat's body goes rigid, cooling in place.",

    -- Optional: byproducts instantiated on death (e.g., spider silk)
    byproducts = { "silk-bundle" },

    -- Transfer inventory to reshaped instance
    transfer_contents = true,
},
```

### 3.2 Mandatory Properties

Every `death_state` MUST include:

| Property | Reason |
|----------|--------|
| `template` | Determines object type (small-item vs. furniture) |
| `name` | Player identification |
| `description` | Examination text |
| `keywords` | Search/take matching |
| `room_presence` | Room description text |
| `on_feel` | **Primary dark sense** — player navigates dark rooms by touch |
| `on_smell`, `on_listen`, `on_taste` | Complete sensory coverage |

### 3.3 Template Selection

| Creature | Chosen Template | Rationale |
|----------|-----------------|-----------|
| rat | small-item | Tiny, portable, fits in hand |
| cat | small-item | Small-ish, portable, can be picked up |
| bat | small-item | Tiny, portable |
| spider | small-item | Tiny, portable (even though exoskeleton — still holdable) |
| wolf | furniture | Large (too heavy to carry), stays in room as fixture |

**Design decision:** Large creatures that reshape to furniture are not portable. They become permanent room features until they decompose or are destroyed.

### 3.4 Spoilage FSM (Optional but Recommended for Edible Creatures)

Dead animals decay over time. The spoilage FSM models this lifecycle:

- **fresh** (30 ticks): Recently dead, still cookable, strong blood smell
- **bloated** (40 ticks): Gas buildup, still recognizable, starts to stink, no longer cookable
- **rotten** (60 ticks): Advanced decay, barely identifiable, intensely foul, dangerous to eat
- **bones** (∞): Only skeleton remains, no longer food

Each state transition happens automatically via `_tick` verb (internal). The container capacity and sensory properties degrade over time, simulating real decay. This system is called by the effects pipeline during WAVE-3 food system.

---

## 4. Narration and Player Feedback

### 4.1 Death Narration Sequence

When a creature dies:

1. **Combat system** prints death text (existing): *"The rat collapses, dead."*
2. **Reshape narration** (optional): If `death_state.reshape_narration` is present, print it immediately after. Example: *"The rat's body goes rigid, cooling in place."*
3. **Discovery on look**: On next `look` or `examine`, player sees the `room_presence` text describing the dead creature's new form.

### 4.2 Narration Design

**Silent reshape (recommended default):** Most creatures don't need special reshape text. The combat death message ("The rat collapses, dead.") is sufficient. The player discovers the corpse is now lootable and cookable through interaction.

**Dramatic reshape (optional):** Some creatures warrant special description:
- Spider: *"The spider's abdomen splits, spilling a tangle of silk."*
- Wolf: *"The wolf crashes to the ground, dust rising in a cloud."*

The presence of `reshape_narration` is entirely at the creature designer's discretion (Flanders).

---

## 5. Backward Compatibility

### 5.1 Creatures Without `death_state`

If a creature definition does **not** declare `death_state`, the creature retains its original FSM dead state behavior. No errors, no crashes. The engine checks for the block's presence:

```lua
if creature.death_state then
    M.reshape_instance(creature, creature.death_state, registry, room)
else
    -- Existing behavior: creature transitions to FSM "dead" state
    creature._state = "dead"
end
```

This ensures Phase 2 creatures (if any existed without death_state) continue to work as-is.

### 5.2 Gradual Migration

Content authors can migrate creatures incrementally:
- **Phase 3 creatures** (rat, cat, wolf, spider, bat): Add full `death_state` blocks
- **Future creatures**: Include `death_state` in the template from day one
- **Legacy creatures**: Leave as-is; they work with old FSM dead state

---

## 6. Inventory and Byproducts (Overview)

### 6.1 Inventory Drop (WAVE-2)

Creatures can declare carried/worn items via an `inventory` metadata block (see `docs/architecture/engine/creature-inventory.md` for full details). When a creature reshapes:

1. Creature instance reshapes into corpse
2. Inventory drop process instantiates each carried/worn item to room floor
3. Reshaped corpse and dropped items coexist in the room as independent objects

### 6.2 Byproducts (Death Reshape)

Some creatures produce items **from their biology**, not from inventory. Example: spiders produce silk, not carry it. The `death_state.byproducts` array handles this:

```lua
death_state = {
    -- ...
    byproducts = { "silk-bundle" },  -- Instantiate silk to room floor during reshape
}
```

When `reshape_instance()` runs, it iterates `byproducts` and calls `registry:register_as_room_object()` for each. This is simpler and cleaner than modeling silk as carried inventory.

---

## 7. Testing Strategy (WAVE-1)

| Test Suite | Coverage |
|-----------|----------|
| `test/creatures/test-creature-death-reshape.lua` | Kill each creature type → instance reshapes correctly, template switches, sensory text updates, GUID preserved |
| `test/creatures/test-reshaped-corpse-properties.lua` | Reshaped corpses: portable/non-portable as expected, sensory text complete, creature metadata cleared |
| `test/food/test-corpse-spoilage.lua` | Spoilage FSM: fresh → bloated → rotten → bones, timer-driven transitions |

**Critical gates:**
- Kill rat → rat instance template changes from "creature" to "small-item"
- Same GUID throughout
- Creature deregistered from tick system (no longer ticks)
- Registered as room object (findable via search)
- All creature metadata cleared (behavior, drives, reactions = nil)
- Backward compat: creature without death_state stays in dead FSM state

---

## 8. Implementation Checklist (for WAVE-1)

- [ ] `reshape_instance(instance, death_state, registry, room)` function in `src/engine/creatures/init.lua`
- [ ] Death handler calls `reshape_instance()` when creature health ≤ 0 and `death_state` present
- [ ] Creature deregister call confirms instance no longer ticks
- [ ] Room registration confirms instance findable in room
- [ ] All 5 creature files (rat, cat, wolf, spider, bat) have `death_state` blocks
- [ ] `meat.lua` material defined
- [ ] Narration API wired: print `reshape_narration` if present
- [ ] Byproducts array processed: spider silk instantiated to room floor
- [ ] All WAVE-1 tests pass
- [ ] No regressions in Phase 2 tests

---

## 9. Related Documents

- **Core Principles:** `docs/architecture/objects/core-principles.md` (D-14, Principle 8)
- **Prime Directive:** `docs/architecture/engine/prime-directive-architecture.md`
- **Creature Inventory:** `docs/architecture/engine/creature-inventory.md` (WAVE-2)
- **Food System:** `plans/npc-combat/npc-combat-implementation-phase3.md` (WAVE-3)
- **Mutation System:** `src/engine/mutation/init.lua` (contrast: file-swap vs. reshape)

---

**Authored by:** Brockman (Documentation)  
**Reviewed by:** Bart (Architecture Lead) — WAVE-0 gate sign-off pending  
**Status:** Ready for WAVE-1 implementation
