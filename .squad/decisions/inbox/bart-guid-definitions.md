# Decision: GUID Assignment for All Meta Definitions

**Author:** Bart (Architect)  
**Requested by:** Wayne "Effe" Berry  
**Status:** Implemented

## Context

Preparing for a streaming/download architecture where the phone client can request objects by GUID. Phase 1: assign stable unique identifiers to every definition file.

## Decision

Every `.lua` file in `src/meta/` (objects, rooms, templates) now carries a `guid` field — a UUID v4 string, hardcoded as the first field in each returned table.

The registry (`src/engine/registry/init.lua`) maintains a lightweight `_guid_index` (guid → id) that is updated on `register()` and `remove()`. A new `find_by_guid(guid)` method performs O(1) lookup.

## Rules

- **GUIDs are immutable** — once assigned, never changed, even if the file's other fields are edited.
- **Mutation variants have their own GUIDs** — `candle.lua` and `candle-lit.lua` are separate definitions with separate GUIDs.
- **GUID = definition identity, not instance identity** — a live object in the registry is tracked by its `id`; the `guid` tells you which definition file it came from.
- **No networking code yet** — this is purely the ID layer.

## Scope

- 39 object files in `src/meta/objects/`
- 1 room file in `src/meta/world/`
- 5 template files in `src/meta/templates/`
- Registry updated: `new()`, `register()`, `remove()`, `find_by_guid()`

## Impact

- All new `.lua` definition files added to `src/meta/` must include a `guid` field.
- Future streaming/download code can use `find_by_guid()` to resolve requested objects.
