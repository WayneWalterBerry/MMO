# Decision: Instance/Base-Class Architecture

**Author:** Bart (Architect)
**Requested by:** Effe

## Summary

Implemented clean separation between immutable base classes and mutable instances. Room is the uber-container holding all instances as a flat array with location-based containment.

## What Changed

- **Base classes** (object files) are now indexed by GUID into a `base_classes` table at load time
- **Instances** in room files reference base classes by `base_guid` and carry optional `overrides`
- **Containment** is derived from instance `location` field, not hardcoded in base class surface arrays
- **Loading pipeline**: load base classes → load room → resolve instances → build containment

## Impact on Other Agents

- **Comic Book Guy**: Base class files (`src/meta/objects/*.lua`) are unchanged — no impact on object definitions or descriptions
- **All agents**: Room files now use `instances` array instead of `contents` — any new room objects must be added as instances with `base_guid` and `location`
- **Mutation**: V1 mutation still uses source-code-based hot-swap via `object_sources` — no change to mutation flow

## Key Rules

1. Instance `id` must be unique within the room
2. Instance `location` uses: `"room"` for top-level, `"parent.surface"` for surfaces, `"parent"` for containers
3. Base class GUIDs are stable and never change
4. Resolved instances have `base_guid` (not `guid`) — registry guid index is reserved for base classes
5. New objects in a room must be added as instances in the room's `instances` array

## Architecture Doc

Full documentation at `docs/architecture/instance-model.md`
