# Creature Loading — Engine Architecture

**Last updated:** 2026-08-16  
**Audience:** Engine developers modifying `src/engine/`  
**Owner:** Bart (Architecture Lead)  
**Prerequisite reading:** `docs/architecture/meta/creature-template.md`, `docs/architecture/objects/core-principles.md`

---

## Overview

Creature `.lua` files are loaded by the same sandboxed loader that handles every other object in the engine. There is no creature-specific loader code — the engine treats creatures as objects that happen to have the `animate = true` flag. This document describes the exact sequence: sandbox → template resolution → GUID registration → creature tick enrollment.

---

## 1. Sandbox Environment

Creature `.lua` files execute inside the same restricted sandbox as all object definitions. The sandbox is created by `loader.load_source()` in `src/engine/loader/init.lua`.

### Allowed Globals

```lua
{
    ipairs, pairs, next, select,
    tonumber, tostring, type,
    unpack (or table.unpack),
    error, pcall,
    math, string, table,
}
```

### Excluded

`os`, `io`, `require`, `dofile`, `loadfile`, `debug`, and all other standard library modules are **not** available inside creature definitions. This prevents creature files from performing I/O, loading arbitrary code, or escaping the sandbox.

### Execution Model

```
source string → loadstring/load() with sandbox env → pcall(chunk) → returned table
```

1. The loader compiles the source string into a chunk.
2. The chunk's environment is set to the sandbox (Lua 5.1: `setfenv`; 5.2+: `load()` fourth arg).
3. The chunk is executed via `pcall()`. Errors are caught and returned as strings.
4. The chunk must return a Lua table. Any other return type is an error.

**Implication for creatures:** Creature `.lua` files can use `math.random()`, string formatting, and table manipulation inside computed fields, but cannot `require()` external modules.

---

## 2. Template Resolution

Every creature definition declares `template = "creature"`. The engine resolves this against the creature base template (`src/meta/templates/creature.lua`) via `loader.resolve_template()`.

### Resolution Sequence

```
creature.lua (instance) ──deep_merge──> creature template (base)
                                         │
                                         ▼
                                    resolved object
```

1. **Load base template:** The creature template is loaded from `src/meta/templates/creature.lua` by the same `loader.load_source()` pipeline. The template defines defaults for all creature fields.

2. **Deep merge:** `deep_merge(template, instance)` copies all template fields into a new table, then overlays the instance's fields on top. The instance always wins for any key it defines.

3. **Consume template field:** After resolution, `resolved.template = nil`. The `template` field is a loader directive — it does not persist at runtime.

### Deep Merge Rules

| Scenario | Result |
|----------|--------|
| Template has key, instance doesn't | Template value inherited |
| Instance has key, template doesn't | Instance value used |
| Both have key (scalar) | Instance wins |
| Both have key (table) | Recursive deep merge |
| Both have key (array) | Instance replaces template array (not appended) |

### What the Template Provides

The creature template (`src/meta/templates/creature.lua`) supplies these defaults:

| Field | Default | Role |
|-------|---------|------|
| `animate` | `true` | Enrolls in creature tick |
| `size` | `"small"` | Containment constraint |
| `weight` | `1.0` | Containment weight |
| `portable` | `false` | Living creatures aren't pickupable |
| `material` | `"flesh"` | Physical material |
| `categories` | `{"creature"}` | Category-based registry queries |
| `on_feel` | `"Warm, alive."` | Sensory fallback |
| `on_smell` | `"An animal smell."` | Sensory fallback |
| `on_listen` | `"Quiet breathing."` | Sensory fallback |
| `initial_state` | `"alive-idle"` | FSM starting state |
| `_state` | `"alive-idle"` | Current FSM state |
| `states` | 4 base states | `alive-idle`, `alive-wander`, `alive-flee`, `dead` |
| `behavior` | `{default="idle", ...}` | Behavior defaults (all zeroed) |
| `drives` | `{}` | Empty drives (safe for tick) |
| `reactions` | `{}` | Empty reactions (no stimulus response) |
| `movement` | `{speed=1, ...}` | Basic locomotion |
| `awareness` | `{sight_range=1, ...}` | Perception ranges |
| `health` / `max_health` | `10` | Mortality baseline |

Creature instances override specific fields (e.g., rat overrides `size = "tiny"`, `weight = 0.3`, and provides creature-specific states, drives, and reactions).

---

## 3. Instance Placement

Creatures are placed into rooms the same way objects are. A room's `instances` array references the creature by `type_id` (the creature's GUID):

```lua
-- Inside a room .lua file
instances = {
    { id = "cellar-rat", type_id = "{071e73f6-535e-42cb-b981-ebf85c27356f}" },
}
```

The `loader.resolve_instance()` function:

1. Looks up the base class by normalized GUID in `base_classes`.
2. Deep-merges any `overrides` from the instance specification.
3. Resolves the template if not already resolved.
4. Sets `instance.id` to the instance-specific ID (e.g., `"cellar-rat"`).
5. Clears `instance.guid` — GUID belongs to the base class, not the instance.
6. Clears `instance.contents` — rebuilt from the instance tree.

**Key point:** Multiple instances of the same creature base can exist. Each gets a unique ID via the room's instance specification. The base creature file (e.g., `rat.lua`) serves as the prototype; room placement creates concrete instances.

---

## 4. GUID Registration

After template resolution and instance placement, each creature instance is registered in the global registry (`src/engine/registry/init.lua`).

```lua
registry:register(instance_id, resolved_object)
```

- The registry indexes by `id` (primary key) and by `guid` (secondary index).
- `find_by_keyword()` matches against `keywords` arrays and `name` fields — this is how the parser resolves player input like "rat" to a creature object.
- `find_by_category("creature")` returns all objects with `"creature"` in their `categories` array.

**No creature-specific registration code exists.** The registry treats creatures identically to furniture, containers, and small items. The `animate` flag is transparent to the registry — it's only meaningful to the creature tick engine.

---

## 5. The `animate = true` Gate

The `animate` flag is the single boolean that separates creatures from inanimate objects in the engine. Here's exactly where it matters:

### Creature Tick Enrollment

In `src/engine/creatures/init.lua`, the master `tick()` function filters:

```lua
for _, obj in ipairs(list_objects(context.registry)) do
    if obj.animate then
        creatures[#creatures + 1] = obj
    end
end
```

Only objects with `animate == true` enter the creature tick pipeline. Everything else is ignored.

### Creature-Specific Engine Paths

| Engine path | Gate condition | Module |
|-------------|---------------|--------|
| Drive updates | `obj.animate == true` | `creatures/init.lua` |
| Stimulus reactions | `obj.animate == true` | `creatures/stimulus.lua` |
| Action scoring | `obj.animate == true` | `creatures/actions.lua` |
| Movement | `obj.animate == true` | `creatures/navigation.lua` |
| Pack tactics | `obj.animate == true` and `_state ~= "dead"` | `creatures/pack-tactics.lua` |
| Territory marking | `obj.animate == true` and `behavior.territorial` | `creatures/territorial.lua` |
| Creature room queries | `obj.animate == true` | `creatures/init.lua:get_creatures_in_room` |

### Dead State Exit

When a creature transitions to `dead` (via `_state = "dead"` or `animate = false`), the tick loop skips it:

```lua
if not creature.animate or creature._state == "dead" then
    return messages  -- early exit, no behavior evaluation
end
```

After death reshape (`reshape_instance()`), the engine explicitly sets `animate = false`, permanently removing the instance from the creature tick.

---

## 6. Required vs. Optional Fields

### Required (engine will malfunction without these)

| Field | Type | Why |
|-------|------|-----|
| `animate` | `boolean` | Gate for creature tick enrollment |
| `_state` | `string` | FSM current state — tick checks this for dead state |
| `on_feel` | `string` | Primary sense in darkness (Principle 6) |

### Required for Full Behavior (engine handles nil safely, but creature will be inert)

| Field | Type | Fallback |
|-------|------|----------|
| `behavior` | `table` | Empty table → creature idles every tick |
| `drives` | `table` | Empty table → no drive updates, no fear/hunger scoring |
| `reactions` | `table` | Empty table → no stimulus response |
| `movement` | `table` | Nil → creature cannot move between rooms |
| `states` | `table` | Required for FSM transitions; nil = no state changes |
| `transitions` | `table` | Required for FSM; nil = creature stays in initial state |
| `health` / `max_health` | `number` | Required for combat/morale; nil = immortal (no death check) |

### Optional (engine ignores if absent)

| Field | Type | Purpose |
|-------|------|---------|
| `awareness` | `table` | Future-phase perception ranges |
| `body_tree` | `table` | Combat zone targeting |
| `combat` | `table` | Natural weapons, armor, combat behavior |
| `loot_table` | `table` | Probabilistic drops on death |
| `death_state` | `table` | In-place reshape on death (D-14) |
| `respawn` | `table` | Timer-based respawn after death |
| `on_smell`, `on_listen`, `on_taste` | `string` | Sensory descriptions (template provides fallbacks) |

---

## 7. Error Handling

The loader and registry fail gracefully:

| Error | Behavior |
|-------|----------|
| Creature `.lua` has syntax error | `loader.load_source()` returns `nil, "compile error: ..."` |
| Creature `.lua` throws runtime error | `loader.load_source()` returns `nil, "runtime error: ..."` |
| Creature `.lua` returns non-table | `loader.load_source()` returns `nil, "object source must return a table"` |
| Template `"creature"` not found | `loader.resolve_template()` returns `nil, "template 'creature' not found"` |
| `type_id` GUID not found in base_classes | `loader.resolve_instance()` returns `nil, "base class not found for guid '...'"` |
| Creature tick throws | `pcall()` wrapper in `M.tick()` catches error; game loop continues |

---

## See Also

- **Creature Template:** `docs/architecture/meta/creature-template.md` — full template field reference
- **Core Principles:** `docs/architecture/objects/core-principles.md` — Principles 1, 2, 8
- **Instance Model:** `docs/architecture/meta/instance-model.md` — base → instance inheritance
- **Creature Behavior Engine:** `docs/architecture/meta/creature-behavior-engine.md` — tick loop
- **Creature System (engine):** `docs/architecture/engine/creature-system.md` — engine module API
