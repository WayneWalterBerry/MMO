### 2026-03-20T00:13:52Z: User directive
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Some wearable objects are also containers:
- **Backpacks:** wearable (wear_slot = "back") AND container. You wear it and it holds stuff.
- **Sacks/bags:** can be worn on head (wear_slot = "head") but **blocks vision** -- if worn on head, player can't see (casts_blindness = true or similar). Encode this in the Lua object.
- **Pots:** can be worn on head as a bad helmet (wear_slot = "head", wear_quality = "improvised"). Provides minimal protection but looks ridiculous.

Key principle: Objects can be BOTH wearable AND containers. The object defines what happens when worn -- a backpack on your back is useful, a sack on your head is blinding. The object's wear metadata controls the gameplay effect, not the engine.

This means `wearable = true` and `container = true` can coexist on the same object. When worn, the container's contents are still accessible (backpack) or become inaccessible (sack over head -- you can't reach in).

**Why:** User request -- wearable + container intersection. Objects define their own gameplay effects when worn. Emergent behavior from combining properties.
