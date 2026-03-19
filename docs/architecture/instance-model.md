# Instance Model Architecture

## Overview

The MMO engine separates **base classes** (immutable templates downloaded by GUID) from **instances** (mutable state that lives inside room definitions). The **room** is the uber-container — it holds all instances as a nested tree and serves as the download/save unit.

## Base Classes

Base classes live in `src/meta/objects/*.lua` and `src/meta/templates/*.lua`. Each has a stable UUID v4 `guid` that never changes.

```lua
-- src/meta/objects/candle.lua (base class)
return {
    guid = "992df7f3-1b8e-4164-939a-3415f8f6ffe3",
    id = "candle",
    name = "a tallow candle",
    description = "A stubby tallow candle...",
    weight = 1,
    categories = {"light source"},
    mutations = { light = { becomes = "candle-lit", ... } },
}
```

**Rules:**
- Base classes are **never modified at runtime**
- They define defaults: name, description, sensory text, weight, categories, surfaces, mutations
- Mutation variants (candle vs candle-lit) are **different base classes** with different GUIDs
- Templates (furniture, small-item, container, sheet, room) provide shared defaults that base classes inherit via `template` field
- At load time, templates are resolved into base classes so base classes are fully materialized

## Instances

Instances are defined inside room files. Each references a `type_id` (the engine-resolvable GUID of the base class) and can carry sparse `overrides` for properties that differ from the base. The `type` field is a human-readable name for the base class — it exists purely for readability and is not used by the engine.

```lua
-- Inside a room definition
instances = {
    { id = "candle",        type = "Candle",        type_id = "992df7f3-...", location = "nightstand.top" },
    { id = "poison-bottle", type = "Poison Bottle", type_id = "a1043287-...", location = "nightstand.top",
      overrides = {
          description = "A cracked bottle with a faded label."
      }
    },
}
```

**Instance fields:**
- `id` — unique within the room, used as the registry key
- `type` — human-readable name of the base class (for code readability, not used by the engine)
- `type_id` — which base class this instance is built from (engine-resolvable GUID)
- `location` — where in the room this instance lives (see Containment below)
- `overrides` — optional sparse table of properties that differ from the base

**At runtime, instances are resolved:** the base class is deep-copied, overrides are applied on top, and the result is registered in the engine's object registry.

## Override Resolution

When resolving an instance, properties are merged in this order (last wins):

1. **Template** — shared defaults (e.g., furniture template provides portable=false)
2. **Base class** — canonical object definition (name, description, weight, etc.)
3. **Instance overrides** — sparse table of instance-specific values

```
Template defaults  →  Base class definition  →  Instance overrides
     (lowest priority)                              (highest priority)
```

The `resolve_instance()` function in `engine/loader/init.lua` handles this:
1. Look up base class by GUID
2. Deep-merge base with instance overrides (instance wins for any key it defines)
3. Strip `guid` (it belongs to the base, not the instance)
4. Set `type_id` on the resolved object for future reference
5. Clear `contents` and surface `contents` arrays (rebuilt from instance locations)

## Room as Uber-Container

The room definition is the download/save unit. It contains:
- Room properties (name, description, exits, mutations)
- An `instances` array — the complete inventory of every object in the room

```lua
return {
    guid = "44ea2c40-e898-47a6-bb9d-77e5f49b3ba0",
    template = "room",
    id = "start-room",
    name = "The Bedroom",
    description = "...",
    instances = { ... },   -- ALL objects in this room
    exits = { ... },
    on_enter = function(self) ... end,
}
```

The room's `contents` array (used by the engine at runtime) is **not** stored in the room definition — it's rebuilt at load time from instance locations.

## Containment Model

Instance `location` encodes the containment tree:

| Location format | Meaning | Example |
|---|---|---|
| `"room"` | Top-level room object | `{ id = "bed", location = "room" }` |
| `"parent.surface"` | On a surface of parent | `{ id = "candle", location = "nightstand.top" }` |
| `"parent"` (no dot, not "room") | Inside a container | `{ id = "match-1", location = "matchbox" }` |

At load time, the engine walks all instances and populates:
- `room.contents` — IDs of room-level objects
- `parent.surfaces[name].contents` — IDs on each surface
- `container.contents` — IDs inside containers

The runtime `obj.location` is set to the **parent ID** (e.g., "nightstand" for candle, "matchbox" for match-1).

## Mutation in the Instance Model

Mutations change the **instance**, never the base class:

| Action | What changes on the instance |
|---|---|
| Break mirror | `type_id` → broken-mirror GUID |
| Light candle | `type_id` → candle-lit GUID |
| Write on paper | `overrides.written_text = "hello"`, `overrides.description` updated |
| Consume match | Instance removed from matchbox contents and room instances |

The current V1 mutation system still uses source-code-based hot-swap (`engine/mutation/init.lua`). Future versions will use GUID-based mutation: change the instance's `type_id` and re-resolve against the new base class.

## Loading Pipeline

```
1. Load templates         → templates table (by id)
2. Load base classes      → resolve templates → base_classes table (by GUID)
                          → object_sources table (by id, for mutation)
3. Load room              → resolve room template
4. Resolve instances      → for each: deep_merge(base, overrides) → register
5. Build containment      → parse locations → populate contents arrays
6. Game ready             → all objects in registry, containment tree built
```

## Future: Streaming Model

The instance/base-class split enables a streaming download architecture:

1. Player enters a room → **download room GUID** → get room definition with instances
2. For each instance → check if `type_id` is in local cache
3. **Download missing base GUIDs** → only fetch base classes the client doesn't have
4. Resolve instances locally → game ready

Base classes are shared across rooms and universes. A "wooden chair" base class downloaded for Room A is reused for Room B. Only the room definitions (with their instance overrides) are unique per-universe.

## Key Design Rules

- **GUIDs are stable** — once assigned to a base class file, never changed
- **Base classes are immutable** — the canonical template for each object type
- **Instances hold all mutable state** — location, overrides, contents
- **Room is the save unit** — save the room definition and you save all instance state
- **Registry indexes by instance ID** — not by GUID (multiple instances can share a base GUID)
