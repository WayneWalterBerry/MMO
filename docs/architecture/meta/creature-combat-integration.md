# Creature Combat Integration — Engine Architecture

**Last updated:** 2026-08-16  
**Audience:** Engine developers modifying `src/engine/creatures/`, `src/engine/combat/`  
**Owner:** Bart (Architecture Lead)  
**Prerequisite reading:** `docs/architecture/meta/creature-behavior-engine.md`, `docs/architecture/engine/creature-death-reshape.md`

---

## Overview

This document describes how the engine reads combat-related metadata from creature `.lua` files: body zones, natural weapons, loot tables, death state handling, and butchery products. All combat data is declared in creature definitions and consumed generically by the engine. No creature-specific combat code exists in the engine (Principle 8).

---

## 1. Body Tree / Zone System

Each creature declares a `body_tree` table that maps anatomical zones to their properties. The engine reads this metadata for hit targeting and damage resolution.

### Body Tree Shape

```lua
body_tree = {
    head = {
        size = 1,                              -- relative zone size (hit probability weight)
        vital = true,                          -- hits here can be lethal
        tissue = { "hide", "flesh", "bone" },  -- tissue layers (damage penetration order)
        on_damage = nil,                       -- optional debuff tags on damage
        names = { "head", "skull", "muzzle" }, -- narration-specific zone names
    },
    body = {
        size = 5,
        vital = true,
        tissue = { "hide", "flesh", "bone", "organ" },
        names = { "body", "flank", "side", "ribs" },
    },
    forelegs = {
        size = 3,
        vital = false,
        tissue = { "hide", "flesh", "bone" },
        on_damage = { "reduced_movement" },     -- applied as status effect on hit
        names = { "foreleg", "front leg", "shoulder" },
    },
},
```

### How the Engine Uses Body Zones

| Field | Engine consumer | Purpose |
|-------|----------------|---------|
| `size` | Combat hit resolution | Weighted random zone selection — larger zones are hit more often |
| `vital` | Damage resolution | Hits to vital zones can trigger death when health ≤ 0 |
| `tissue` | Damage penetration | Layers checked in order for armor/damage reduction |
| `on_damage` | Status effects | Tags like `"reduced_movement"` applied when zone is damaged |
| `names` | Narration (`zone_text()`) | Engine selects a narration-appropriate name for hit descriptions (D-CREATURE-ZONE-NAMES) |

### Zone Selection Algorithm

```
1. Sum all zone sizes → total_size
2. Roll random(0, total_size)
3. Walk zones, accumulating size. First zone whose cumulative size ≥ roll is selected.
```

Example for a wolf (head=2, body=5, forelegs=3, hindlegs=3, tail=1, total=14):
- Head: 14% chance
- Body: 36% chance
- Forelegs: 21% chance
- Hindlegs: 21% chance
- Tail: 7% chance

### Creature-Specific Anatomy

Body trees vary per creature. The engine makes no assumptions about zone names:

| Creature | Zones | Notes |
|----------|-------|-------|
| Rat | `head`, `body`, `legs`, `tail` | Standard quadruped |
| Wolf | `head`, `body`, `forelegs`, `hindlegs`, `tail` | Split leg zones |
| Cat | `head`, `body`, `legs`, `tail` | Standard quadruped |
| Bat | `head`, `body`, `wings`, `legs` | Wings are non-vital; `on_damage = {"grounded"}` |
| Spider | `cephalothorax`, `abdomen`, `legs` | Arachnid anatomy; no standard zones |

---

## 2. Natural Weapons

Creatures declare their attacks in `combat.natural_weapons`. The engine reads this array to resolve creature attack actions.

### Natural Weapon Shape

```lua
combat = {
    natural_weapons = {
        {
            id = "bite",                       -- weapon identifier
            type = "pierce",                   -- damage type (pierce, slash, blunt)
            material = "tooth-enamel",         -- material for hardness/penetration lookup
            zone = "head",                     -- which body zone this weapon originates from
            force = 5,                         -- base damage force
            target_pref = "arms",              -- preferred target zone on defender (hint)
            message = "clamps its jaws onto",  -- narration fragment
        },
        {
            id = "claw",
            type = "slash",
            material = "keratin",
            zone = "forelegs",
            force = 3,
            message = "rakes its claws across",
        },
    },
}
```

### How the Engine Resolves Weapons

1. **Weapon selection:** During combat, the engine picks a weapon from `natural_weapons`. Selection may factor in `zone` (damaged zone = weapon disabled).
2. **Force resolution:** `force` is the base damage value. The engine applies modifiers from defender armor, material hardness, and zone tissue layers.
3. **Material lookup:** `material` is resolved against the material registry (`src/engine/materials/init.lua`) for hardness and penetration values.
4. **Narration:** `message` is interpolated into combat text: *"The wolf clamps its jaws onto your arm."*
5. **On-hit effects:** Optional `on_hit` table triggers additional effects (e.g., spider bite inflicts `spider-venom` with probability).

### Natural Armor

```lua
combat = {
    natural_armor = {
        { material = "hide", coverage = { "body", "head" }, thickness = 2 },
    },
}
```

The engine checks if the struck `body_tree` zone is covered by natural armor. If so, armor's `material` and `thickness` reduce incoming damage.

### Combat Behavior Metadata

```lua
combat = {
    behavior = {
        aggression = "territorial",     -- "passive", "on_provoke", "territorial", "hostile"
        flee_threshold = 0.2,           -- flee when health/max_health < this
        attack_pattern = "sustained",   -- "random", "sustained", "hit_and_run", "ambush", "opportunistic"
        defense = "counter",            -- "dodge", "counter", "flee", "block"
        target_priority = "threatening",-- "closest", "weakest", "threatening"
        pack_size = 1,                  -- expected pack size for encounter scaling
    },
}
```

The combat engine reads these declaratively. `flee_threshold` feeds into morale checks; `attack_pattern` influences weapon selection frequency; `target_priority` determines which prey to engage first.

---

## 3. Loot Table Processing — `loot.lua`

When a creature dies, the engine rolls its `loot_table` to determine item drops. The loot engine (`src/engine/creatures/loot.lua`) supports four drop patterns.

### Pattern 1: Always Drops (100% Guaranteed)

```lua
loot_table = {
    always = {
        { template = "gnawed-bone" },
        { template = "silk-bundle" },
    },
}
```

Every item in the `always` array is instantiated unconditionally. Used for biology-derived drops (bones, silk).

### Pattern 2: Weighted Random (Pick One)

```lua
loot_table = {
    on_death = {
        { item = { template = "silver-coin" }, weight = 20 },
        { item = { template = "torn-cloth" },  weight = 30 },
        { item = nil,                          weight = 50 },  -- 50% chance of nothing
    },
}
```

The engine sums all `weight` values, rolls a random number, and selects exactly one option via cumulative distribution. An `item = nil` entry represents "no drop."

### Pattern 3: Variable Quantity

```lua
loot_table = {
    variable = {
        { template = "copper-coin", min = 0, max = 3 },
    },
}
```

For each entry, the engine rolls `math.random(min, max)`. If quantity > 0, that many instances are created.

### Pattern 4: Conditional Drops (Kill Method)

```lua
loot_table = {
    conditional = {
        fire_kill  = { { template = "charred-hide" } },
        poison_kill = { { template = "tainted-meat" } },
    },
}
```

The engine checks `death_context.kill_method` against the keys in `conditional`. If matched, all items in that array are dropped. Allows drops that only appear for specific kill methods.

### Instantiation Pipeline

```
roll_loot_table(creature, death_context)
  → drops[] (array of {template, quantity})

instantiate_drops(drops, room, context)
  → resolve each template via registry/object_sources/base_classes
  → deep-copy template, assign unique instance id
  → register in registry, add to room.contents
  → set location = room.id
```

Template resolution follows the same 3-tier pattern as byproduct resolution: (1) registry lookup, (2) `object_sources` + loader, (3) `base_classes` scan.

---

## 4. Death State Handling

When a creature's health reaches zero, the engine orchestrates death via `death.handle_creature_death()` in `src/engine/creatures/death.lua`.

### Death Sequence

```
health ≤ 0 detected (combat system or creature tick)
  │
  ├─ 1. Check creature.death_state
  │     ├─ Present → reshape_instance() (D-14 metamorphosis)
  │     └─ Absent → legacy FSM: creature._state = "dead" (backward compat)
  │
  ├─ 2. Capture loot_table before reshape (defensive copy)
  │
  ├─ 3. reshape_instance(creature, death_state, registry, room)
  │     ├─ Switch template (creature → small-item or furniture)
  │     ├─ Overwrite identity (name, description, keywords, room_presence)
  │     ├─ Overwrite sensory (on_feel, on_smell, on_listen, on_taste)
  │     ├─ Set animate = false, alive = false, portable = death_state.portable
  │     ├─ Apply optional: food, crafting, container metadata
  │     ├─ Install spoilage FSM (states + transitions + start timer)
  │     ├─ Ensure creature in room.contents exactly once
  │     └─ Clear creature metadata: behavior, drives, reactions, movement,
  │        awareness, health, max_health, body_tree, combat = nil
  │
  ├─ 4. Instantiate byproducts to room floor (e.g., spider silk)
  │
  ├─ 5. Drop creature inventory to room floor (WAVE-2)
  │
  ├─ 6. Roll loot table + instantiate drops to room floor
  │
  ├─ 7. Clear loot_table from reshaped corpse
  │
  ├─ 8. Print reshape_narration (if declared)
  │
  └─ 9. Trauma hook: add_stress("witness_creature_death") if player in same room
```

### D-14 Alignment: Instance Metamorphosis

`reshape_instance()` modifies the creature table **in-place**. The GUID is preserved — the same object that was a living wolf is now a dead wolf corpse. This is not file-swap mutation (`mutation.mutate()` which loads a different `.lua` file). The creature's death form lives in the same `.lua` file as its living form.

```lua
-- Before reshape
instance.template = "creature"
instance.animate = true
instance.behavior = { aggression = 70, ... }

-- After reshape
instance.template = "furniture"  -- wolf is too large to carry
instance.animate = false
instance.behavior = nil           -- creature metadata cleared
instance.food = { category = "meat", cookable = false }
```

### Backward Compatibility

If a creature definition does not declare `death_state`, the engine falls back to the legacy FSM dead state. No errors, no crashes:

```lua
if creature.death_state then
    handle_creature_death(creature, context, room)  -- full reshape
else
    creature._state = "dead"  -- legacy: FSM transition only
end
```

---

## 5. Spoilage FSM

Reshaped corpses can declare a spoilage FSM via `death_state.states` and `death_state.transitions`. This uses the same FSM engine (`src/engine/fsm/init.lua`) as all other objects.

### Standard Spoilage Lifecycle

```
fresh ──(timer_expired)──> bloated ──(timer_expired)──> rotten ──(timer_expired)──> bones
```

Each state has `timed_events` that fire auto-transitions:

```lua
states = {
    fresh = {
        timed_events = { { delay = 3600, event = "timer_expired", to_state = "bloated" } },
    },
}
transitions = {
    { from = "fresh", to = "bloated", trigger = "auto", condition = "timer_expired" },
}
```

### Timer Integration

After `reshape_instance()` installs the spoilage FSM, it calls `fsm.start_timer(registry, instance_id)` to begin the first spoilage timer. Subsequent timers are started automatically by `fsm.tick_timers()` when one state expires into another (cyclic timer pattern).

### State-Specific Property Changes

Each spoilage state can override properties:

| State | Food changes | Sensory changes |
|-------|-------------|-----------------|
| `fresh` | `cookable = true` | Default death sensory |
| `bloated` | `cookable = false` | `on_smell` overridden (decay stench) |
| `rotten` | `cookable = false, edible = false` | `on_smell` overridden (overwhelming rot) |
| `bones` | `food = nil` | `on_smell = "Nothing"`, `on_feel` = dry bones |

---

## 6. Butchery Product Spawning

Large creatures (wolf, future large animals) declare `death_state.butchery_products`. The engine reads this metadata when the player uses a butchering verb on the corpse.

### Butchery Metadata Shape

```lua
death_state = {
    butchery_products = {
        requires_tool = "butchering",        -- tool capability required
        duration = "5 minutes",              -- game-time cost
        products = {
            { id = "wolf-meat", quantity = 3 },
            { id = "wolf-bone", quantity = 2 },
            { id = "wolf-hide", quantity = 1 },
        },
        narration = {
            start = "You begin carving the wolf carcass...",
            complete = "You finish butchering the wolf...",
        },
        removes_corpse = true,               -- corpse removed after butchery
    },
}
```

### Engine Processing

1. **Tool check:** Verb handler checks player holds a tool with `provides_tool = "butchering"`.
2. **Duration:** Game time advances by `duration` (or tick count equivalent).
3. **Product instantiation:** For each product, engine creates `quantity` instances using the standard template resolution pipeline. Products are placed on the room floor.
4. **Corpse removal:** If `removes_corpse = true`, the corpse object is removed from registry and room contents after successful butchery.
5. **Narration:** `narration.start` printed when butchery begins; `narration.complete` printed when finished.

### Contrast: Butchery vs. Loot vs. Byproducts

| Mechanism | When | What drops | Declared in |
|-----------|------|-----------|-------------|
| **Loot table** | Automatic on death | Probabilistic items (coins, fangs) | `creature.loot_table` |
| **Byproducts** | Automatic on death | Biology-derived items (silk) | `death_state.byproducts` |
| **Butchery** | Player action on corpse | Deterministic cuts (meat, bone, hide) | `death_state.butchery_products` |

Loot and byproducts are processed in `death.handle_creature_death()`. Butchery is processed by the butcher verb handler reading the reshaped corpse's metadata.

---

## 7. Byproduct Resolution

The `death_state.byproducts` array lists object IDs to instantiate on death:

```lua
death_state = {
    byproducts = { "silk-bundle" },
}
```

The engine resolves each byproduct ID through a 3-tier pipeline:

1. **Registry lookup:** `registry:get(bp_id)` — object already loaded.
2. **On-demand loading:** `object_sources[bp_id]` + `loader.load_source()` → register and return.
3. **Base class scan:** Search `base_classes` for matching `id` field → deep-copy and register.

Each resolved byproduct is placed in the room (`location = room.id`, added to `room.contents`).

---

## 8. Respawn System

After death, creatures with `respawn` metadata are registered for timed respawn:

```lua
respawn = {
    timer = 60,          -- ticks until respawn
    home_room = "cellar", -- room to spawn in
    max_population = 3,   -- cap on simultaneous instances
},
```

The `respawn.lua` module:
1. Records the creature's base data when `register(creature)` is called on death.
2. Each tick in `M.tick()`, `respawn.tick()` decrements timers.
3. When timer reaches zero and `max_population` isn't exceeded, a new instance is created in `home_room`.

---

## 9. Stress Trauma Hook

When a creature dies in the player's room, the death handler emits a stress event:

```lua
injuries.add_stress(player, "witness_creature_death")
```

This delegates to the centralized injury/stress API (D-STRESS-HOOKS). The engine doesn't define what "witness_creature_death" does — the injury system reads stress definitions from `src/meta/injuries/` metadata.

---

## See Also

- **Creature Loading:** `docs/architecture/meta/creature-loading.md` — sandbox, template resolution
- **Creature Behavior:** `docs/architecture/meta/creature-behavior-engine.md` — tick loop, drives, actions
- **Death Reshape (detailed):** `docs/architecture/engine/creature-death-reshape.md` — full reshape spec
- **Creature Template:** `docs/architecture/meta/creature-template.md` — field reference
- **Effects Pipeline:** `docs/architecture/engine/effects-pipeline.md` — effect processing
- **Core Principles:** `docs/architecture/objects/core-principles.md` — D-14, Principle 8
