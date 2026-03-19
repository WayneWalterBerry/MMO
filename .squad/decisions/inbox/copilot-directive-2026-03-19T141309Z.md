### 2026-03-19T141309Z: Architecture directive — Field naming: type and type_id
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Rename instance fields:
- `name` → `type` (human-readable type name, e.g., "Matchbox", "Poison Bottle")
- `base_guid` → `type_id` (the GUID that references the base class definition)

**Final instance field convention:**
```lua
{
  id = "matchbox-1",                              -- unique instance ID within this room
  type = "Matchbox",                              -- human-readable type (what kind of thing)
  type_id = "a1b2c3d4-e5f6-4a7b-8c9d-...",       -- GUID of the base class definition
  location = "nightstand-1.inside",
  overrides = {},
  contents = {}
}
```

**Rationale:** 
- `type` is more accurate than `name` — it describes WHAT KIND of thing this is, not what this specific instance is called. A room might have "Grandmother's Rocking Chair" (instance display name) but its TYPE is "Chair".
- `type_id` clearly communicates "this is the ID that resolves the type definition"
- `id` remains the instance's unique identifier within the room

**This applies everywhere:**
- All instance definitions in room files
- The loader/resolver uses `type_id` to find the base class
- Architecture docs should use this terminology

**IMPORTANT:** Capture all of this (instance model, overrides, type/type_id, room as container, GUID resolution) in docs/architecture/instance-model.md.

**Why:** User request — clearer naming convention. Type describes the class, type_id is the resolvable reference.
