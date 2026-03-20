### 2026-03-20T00:11:52Z: User directive
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Wearable objects define their own wear slots and layering rules -- the object knows where it goes, not the engine. Design principles:

1. **Wear slots are defined on the object**, not hardcoded in the engine. e.g., `wear_slot = "head"`, `wear_slot = "torso"`, `wear_slot = "feet"`. The engine just checks for conflicts.

2. **Slot conflict rules:** Only one item per slot UNLESS layering is allowed. A hat goes on "head" -- if you try a second hat, it fails ("You're already wearing a hat"). The object doesn't need to say "put it on my head" -- the engine infers from wear_slot.

3. **Layering:** Some slots support layers. A cloak (`wear_layer = "outer"`) can go over a shirt (`wear_layer = "inner"`). But two outer layers conflict. Two inner layers conflict. The object defines its layer.
   - Examples that work: shirt (inner) + cloak (outer), shirt (inner) + armor (outer)
   - Examples that fail: two hats, two pairs of pants, two pairs of shoes, two sets of armor

4. **Slot list lives on the object:**
   ```lua
   wearable = true,
   wear_slot = "head",      -- where it goes
   wear_layer = "outer",    -- layering (inner/outer/accessory)
   ```

5. **The engine's job is simple:** check if the slot+layer combo is already occupied. The object provides all the metadata.

6. **Flexibility:** New slots can be invented by new objects without changing the engine. A ring could use `wear_slot = "finger"`. Gloves use `wear_slot = "hands"`. The engine doesn't need to know about these in advance.

**Why:** User request -- wearable system design. Objects own their wear metadata, engine just enforces slot/layer conflicts. This keeps the system extensible without engine changes.
