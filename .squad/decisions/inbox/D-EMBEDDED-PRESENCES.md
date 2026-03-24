# D-EMBEDDED-PRESENCES: Room Embedded Presences Pattern

**Author:** Bart (Architect)  
**Date:** 2026-03-28  
**Status:** Implemented  

## Decision

Rooms can now declare `embedded_presences = { "obj-id-1", "obj-id-2", ... }` — a list of object IDs whose presence is already described in `room.description`. The look handler skips these objects during the presences iteration, preventing duplicate display.

## Rationale

BUG-050: Multiple rooms (hallway, crypt, courtyard) had objects described in both `room.description` AND in the room_presence presences section. Torches, portraits, sarcophagi, etc. appeared twice. The previous `seen_presences` text-dedup only prevented identical text from repeating — it didn't prevent objects described in the prose from also rendering room_presence.

## Pattern

```lua
-- In room .lua file:
return {
    description = "A corridor lit by torches in iron brackets.",
    embedded_presences = { "torch-lit-west", "torch-lit-east" },
    instances = {
        { id = "torch-lit-west", type = "Lit Torch", ... },
        { id = "torch-lit-east", type = "Lit Torch", ... },
    },
}
```

## Impact

- Room authors must add `embedded_presences` when their `description` already mentions specific instance objects
- Objects in `embedded_presences` are still interactable — they're just not double-rendered in `look`
- If an object is picked up and dropped in another room, it renders normally (the flag is per-room, not per-object)
