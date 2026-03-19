# Decision: Compound Tools, Two-Hand Inventory, Consumables

**Author:** Bart (Architect)  
**Date:** 2026-03-21  
**Status:** IMPLEMENTED  
**Requested by:** Wayne "Effe" Berry

---

## D-XX: Two-Hand Inventory System

**Decision:** Player inventory is now two hand slots + worn items. Replaces the unlimited flat inventory.

**Player state:**
```lua
player = {
    hands = { nil, nil },  -- two hand slots (object IDs)
    worn = {},              -- backpack, cloak (don't use hand slots)
    skills = {},            -- future use
    state = { has_flame = 0, bloody = false, poisoned = false },
}
```

**Rules:**
- Two hands = two items maximum
- A bag (sack) held in one hand: contents accessible, bag uses a hand
- Wearable items (cloak, backpack) go to `worn` via WEAR verb, freeing hands
- TAKE checks for empty hand slot; "Your hands are full. Drop something first."
- DROP removes from hand, places on room floor
- GET X FROM Y extracts items from held/worn bags into an empty hand
- PUT X IN Y moves from hand to bag/surface

---

## D-XX: Compound Tool System (STRIKE verb)

**Decision:** STRIKE is the first compound tool verb. The primary tool (match) is consumed from the matchbox. The secondary tool (matchbox/striking surface) can be in your hand OR on any reachable surface.

**Key design decision — the "both hands" problem:**

> Effe asked: if match is in hand 1 and matchbox in hand 2, player CAN strike. But what if matchbox is on the nightstand?

**Resolution:** You do NOT need to hold the matchbox. The matchbox just needs to be within reach (in hand, on surface, anywhere accessible). Rationale: you hold the match and strike it against whatever surface is nearby. This avoids the deadlock where both hands are full.

In practice, since the matchbox holds the matches (charges), the player says "STRIKE match ON matchbox" and the system:
1. Finds the matchbox (searches carried items, then room/surfaces)
2. Checks charges > 0
3. Consumes one charge
4. Sets `player.state.has_flame = 3` (3 command ticks)
5. Player then uses LIGHT to transfer flame to candle

The match is ephemeral — it's a player state (`has_flame`), not a persistent object. This is cleaner than spawning/destroying match objects.

**Future compound tools** (SEW cloth WITH needle AND thread) will use a `requires_tools` array on mutations. The STRIKE verb establishes the pattern.

---

## D-XX: Consumables System

**Decision:** Objects can be consumed and permanently removed from the universe.

**Types implemented:**
1. **Match:** Ephemeral after striking. `has_flame` ticks down (3 commands). Using LIGHT transfers flame and consumes match. Otherwise it burns out: "The match sputters and dies."
2. **Candle:** `burn_remaining = 60` (60 command ticks). Each command while lit decrements it. Warning at 5 ticks. At 0: "The candle gutters and goes out, plunging the room into darkness." → `registry:remove()`.
3. **EAT:** Stub verb. Checks `obj.edible`, removes from world if true.
4. **BURN:** Stub verb. Checks for flame + flammable category, removes from world if true.

**Tick system:** `context.on_tick(ctx)` called after every command in the game loop. Handles flame countdown and candle burn.

**Burn timer is per-command, not real-time** (simpler for V1, as Effe specified).

---

## Files Modified

- `src/engine/verbs/init.lua` — All verb updates, new hand helpers, STRIKE/WEAR/REMOVE/EAT/BURN verbs
- `src/main.lua` — Player state structure, on_tick handler for consumables
- `src/engine/loop/init.lua` — Post-command tick hook
- `src/meta/objects/candle-lit.lua` — Added `burn_remaining = 60`
- `src/meta/objects/wool-cloak.lua` — Added `wearable = true`

---

## Architectural Notes

- The hand system affects EVERY verb that touches inventory. All helpers (`find_in_inventory`, `find_tool_in_inventory`, `find_visible`, `remove_from_location`, `get_light_level`, `inventory_weight`) were rewritten.
- `get_all_carried_ids(ctx)` is the canonical way to get all items a player has access to (hands + bag contents + worn + worn bag contents).
- `find_visible` now returns location types: "room", "surface", "container", "hand", "bag", "worn" — verbs use this to determine valid actions.
- The tick system is extensible — any time-based mechanic (poison damage, hunger, etc.) can hook into `on_tick`.
