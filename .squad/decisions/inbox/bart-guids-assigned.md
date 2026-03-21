# Decision: GUID Audit — All Rooms, Levels, and Templates

**Author:** Bart (Architect)  
**Date:** 2026-07-21  
**Status:** ✅ AUDIT COMPLETE — No changes needed

## Context

Wayne requested Windows-style GUIDs be added to all room and level `.lua` files for JIT loading support. Audit was performed across all rooms (`src/meta/world/`), levels (`src/meta/levels/`), and templates (`src/meta/templates/`).

## Finding

**All 13 files already have properly formatted GUIDs.** No modifications were required.

Every GUID follows the standard format: lowercase, hyphen-separated, no braces (e.g., `"44ea2c40-e898-47a6-bb9d-77e5f49b3ba0"`).

## Complete GUID Registry

### Rooms (src/meta/world/)

| File | ID | GUID |
|------|----|------|
| start-room.lua | start-room | `44ea2c40-e898-47a6-bb9d-77e5f49b3ba0` |
| cellar.lua | cellar | `b7d2e3f4-a891-4c56-9e38-d7f1b2c4a605` |
| storage-cellar.lua | storage-cellar | `a1aa73d3-cd9d-4d13-9361-bd510cf0d46d` |
| deep-cellar.lua | deep-cellar | `64da418f-1fb2-4898-a016-50a5c0a6f4da` |
| hallway.lua | hallway | `bb964e65-2233-4624-8757-9ec31d278530` |
| courtyard.lua | courtyard | `8fa16d57-41ea-4695-a61b-2ccc3f68c1b6` |
| crypt.lua | crypt | `dea3ae62-c67e-4092-a361-fe3911c3fd4e` |

### Levels (src/meta/levels/)

| File | Name | GUID |
|------|------|------|
| level-01.lua | The Awakening | `c4a71e20-8f3d-4b61-a9c5-2d7e1f03b8a6` |

### Templates (src/meta/templates/)

| File | ID | GUID |
|------|----|------|
| container.lua | container | `f1596a51-4e1f-4f9a-a6d0-93b279066910` |
| furniture.lua | furniture | `45a12525-ae7c-4ff1-ba22-4719e9144621` |
| room.lua | room | `071e1b6a-17ae-498b-b7af-0cbb8948cd0d` |
| sheet.lua | sheet | `ada88382-de1e-4fbc-908c-05d121e02f84` |
| small-item.lua | small-item | `c2960f69-67a2-42e4-bcdc-dbc0254de113` |

## Note

The task referenced `bedroom.lua` — this file is actually `start-room.lua` (id: `start-room`, name: "The Bedroom"). No `bedroom.lua` exists in the codebase.
