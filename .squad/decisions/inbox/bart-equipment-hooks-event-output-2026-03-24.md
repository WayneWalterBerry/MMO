### D-EQUIP-HOOKS: Equipment Event Hooks (on_wear / on_remove_worn)

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-24  
**Status:** Implemented  
**Phase:** A6

Equipment actions are now engine events, not just array manipulation in verb handlers.

**Hooks implemented:**
- `on_wear(obj, ctx)` — fires after item is equipped and flavor message prints
- `on_remove_worn(obj, ctx)` — fires after item is unequipped and message prints
- `on_equip_tick(obj, ctx)` — designed, not yet implemented (needs game loop integration)

**Pattern:** Per-object callbacks (CODE pattern). Objects declare functions; engine calls them at the right time. Follows existing `on_look`/`on_feel` callback convention.

**Files changed:** `src/engine/verbs/init.lua`, `docs/architecture/engine/event-hooks.md` (v3.0)

**Cross-Agent Notes:**
- **Flanders:** Chamber pot migration (A7) can now use `on_wear` for smell narration
- **Nelson:** Can write tests for on_wear/on_remove_worn callbacks
- **Smithers:** Armor registration should hook into `on_wear`/`on_remove_worn`

---

### D-EVENT-OUTPUT: Instance-Level One-Shot Flavor Text System

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-24  
**Status:** Implemented  
**Phase:** A6b

Objects can declare `event_output = { on_wear = "text", on_take = "text" }` for per-instance flavor text that fires once then self-removes.

**Design:**
- DATA pattern, not CODE — no callbacks, just strings on the object
- Engine checks `obj.event_output[event_name]` after each event
- If string exists → print → set to nil (one-shot)
- Flavor text lives on ROOM instance data, not object template
- Same template can have different flavor text in different rooms

**Dispatch points:** on_take (4 paths), on_drop, on_wear, on_remove_worn, on_eat, on_drink — 8 total insertion points.

**Files changed:** `src/engine/verbs/init.lua`, `docs/architecture/engine/event-hooks.md` (v3.0)

**Cross-Agent Notes:**
- **Flanders:** Can now add `event_output.on_wear` to wool-cloak, chamber-pot, terrible-jacket instances
- **Nelson:** Can write event_output tests (wear → text prints, wear again → no text, object without → no error)
