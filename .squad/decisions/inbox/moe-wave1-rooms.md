# Decision: WAVE-1 Creature Room Placements

**Date:** 2026-03-26
**By:** Moe (World Builder)
**Scope:** Room files — creature instance placement

## What Changed

Added creature instances to 4 room files:

| Room | Creature ID | Type GUID |
|------|------------|-----------|
| `src/meta/rooms/courtyard.lua` | `courtyard-cat` | `{46c2583c-2cec-4842-bfd3-5d56c737996d}` |
| `src/meta/rooms/hallway.lua` | `hallway-wolf` | `{e69fc5e8-ce63-4b26-b5b2-faa2ff85d12c}` |
| `src/meta/rooms/deep-cellar.lua` | `deep-cellar-spider` | `{f67e3d8b-ecab-41a4-9f3e-79da4c5374ae}` |
| `src/meta/rooms/crypt.lua` | `crypt-bat` | `{52e32931-84dc-4a3d-a2cf-04cf79d61f4c}` |

## Convention Established

- **Creature instance naming:** `{room-id}-{creature}` (e.g., `courtyard-cat`)
- **Placement style:** Room-level (not nested on furniture) — creatures roam freely
- **Minimal entry:** `{ id = "...", type_id = "{guid}" }` — no `type` field, matching cellar-rat pattern

## Who Needs to Know

- **Flanders:** Creature object `.lua` files must exist in `src/meta/creatures/` with matching GUIDs for these to resolve at load time
- **Nelson:** 4 new creature instances in rooms — may need integration test updates
- **Bart:** No engine changes required — uses existing creature/instance system
