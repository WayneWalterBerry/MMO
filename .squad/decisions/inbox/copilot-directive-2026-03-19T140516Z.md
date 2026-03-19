### 2026-03-19T140516Z: Architecture directive — Instance/Base Class/Room Container Model
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Major architecture shift toward an instance-based object model:

**The Model:**
- Every object in a room is an INSTANCE
- Each instance has a BASE CLASS (referenced by GUID)
- Base classes can inherit from other base classes (matchbox → container)
- The ROOM is the uber-container — it holds everything, including the player
- Instances live INSIDE the room definition as a nested tree

**Instance vs Base:**
- Base class (e.g., `poison-bottle`) defines generic defaults: description, feel, smell, taste, etc.
- Instance (in the room) can OVERRIDE any base property to make it unique
- Example: base poison-bottle has generic "A glass bottle" description. The bedroom instance overrides with "A small glass bottle with a faded label, sitting on the nightstand beside a dried ring of spilled liquid."
- Overrides are sparse — only specify what's different from the base

**Room as Download Unit:**
- A room GUID is the download unit
- When you download a room, you get: room definition + nested tree of all object instances
- Each instance references its base class GUID
- If the engine doesn't have the base class cached, it downloads that too
- Instance data includes: position (location/surface), overrides, mutable state (contents, charges, etc.)

**Inheritance Chain:**
```
match-instance-1 (in matchbox, room-specific)
  → match (base class, GUID: xxx)
    → small-item (template/base, GUID: yyy)

matchbox-instance (in nightstand drawer, has 6 matches)
  → matchbox (base class, GUID: xxx)
    → container (template/base, GUID: yyy)
```

**Instance Data in Room:**
```lua
return {
  guid = "room-guid",
  name = "The Bedroom",
  instances = {
    {
      id = "matchbox-1",
      base_guid = "matchbox-base-guid",
      location = "nightstand-1.inside",
      overrides = {},
      contents = {"match-1", "match-2", "match-3", "match-4", "match-5", "match-6"}
    },
    {
      id = "poison-bottle-1",
      base_guid = "poison-bottle-base-guid",
      location = "nightstand-1.top",
      overrides = {
        description = "A small glass bottle with a faded label...",
        on_smell = "Something acrid seeps through the cracked cork..."
      }
    },
    ...
  }
}
```

**Mutation in this model:**
- Mutation changes the INSTANCE, not the base class
- Breaking the mirror: instance gets new base_guid (mirror → broken-mirror) + override data
- Writing on paper: instance gets `written_text` override
- Consuming a match: instance removed from matchbox contents, then removed from room entirely
- The base classes are IMMUTABLE templates. Instances are the mutable layer.

**Why:** User request — this separates content (base classes) from state (instances), enables streaming (download room = get all instances + base GUIDs), enables expansion packs (new base classes), and keeps the room as the atomic unit of game state. Aligns with multiverse model (each player's universe = their room instances with their mutations).
