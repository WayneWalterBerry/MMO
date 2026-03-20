### 2026-03-20T00:08:51Z: User directive
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Some objects are wearable (e.g., the cloak). Objects need a `wearable = true` property and a WEAR verb that moves them from inventory to a "worn" slot. Worn items should affect gameplay -- a cloak might provide warmth, a bandage might stop bleeding. The WEAR/REMOVE verbs need to work with the FSM system if the wearable has states (e.g., cloak: folded → worn → torn).
**Why:** User request -- design directive for wearable object category. Expands the object property system.
