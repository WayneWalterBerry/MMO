# Chest Mechanics: Two-Handed Carry System

> Design specification for the two-handed carry system used by heavy container objects like chests, crates, and barrels.

## Overview

The **two-handed carry system** allows objects to declare how many hands they require when carried. The player has **two hand slots** total. Objects compete for those slots. When all hand slots are occupied, the player cannot interact with other objects or hold weapons.

This system creates meaningful inventory management and tactical trade-offs:
- Carrying a two-handed chest leaves no hands free for a candle, weapon, or tool
- Player must choose: explore in light (carry candle) OR gather supplies (carry chest)

## Hand Slot Mechanics

### Player Hand Capacity

The player has **exactly 2 hand slots** available at any time.

```lua
player.hand_slots = {
  [1] = { occupied_by = "lit_candle", hands_required = 1 },
  [2] = { occupied_by = "knife", hands_required = 1 }
}
```

| Object Type | Hands Required | Notes |
|-------------|---|---|
| Single-handed item (candle, dagger, torch) | 1 | Can hold one per hand |
| Two-handed item (chest, crate, barrel) | 2 | Occupies both hands; prevents dual-wielding |
| Wearable (shirt, boots, hat) | 0 | Worn items don't consume hand slots |
| Backpack | 0 | Worn containers don't consume hand slots |

### Worn Items vs Hand Items

**Critically important distinction:**

| Category | Hand Slots | Example | Interaction |
|----------|---|---|---|
| **Worn** | 0 | Backpack, gloves, ring, shirt | Equipped via WEAR verb; don't occupy hands |
| **Held** | 1 or 2 | Candle, dagger, chest, crate | Held via TAKE verb; occupy hand slots |

A player wearing a backpack (0 hands) can carry candle (1 hand) + dagger (1 hand) = 2 hands total.

## Objects Using Two-Handed System

### Implemented

- **Chest** — `hands_required = 2` — Storage container, heavy
- **Crate** — `hands_required = 2` — Stackable storage, fragile
- **Barrel** — `hands_required = 2` — Liquid storage, unwieldy

### Single-Handed (Reference)

- **Candle** — `hands_required = 1` — Light source
- **Match** — `hands_required = 1` — Fire source
- **Torch** — `hands_required = 1` — Light source (future)
- **Dagger/Sword** — `hands_required = 1` — Weapon
- **Backpack** — `hands_required = 0` — Worn (not held)

## Interaction Rules

### Rule 1: Taking (TAKE/PICK UP)

When player tries to pick up an object:

```lua
available_slots = 2 - count_occupied_slots
required_slots = object.hands_required

if available_slots >= required_slots then
    -- Success: add to inventory
else
    -- Fail: reject with Prime Directive message
end
```

**Examples:**

```
> inventory
Hands:
  - left hand: lit candle (1 hand)
  - right hand: [empty]

> take chest
You carefully lift the chest with both hands. But your right hand is already full holding the candle. You'd need to put the candle down first.

---

> put down candle
You set the candle down carefully.

> inventory
Hands:
  - left hand: [empty]
  - right hand: [empty]

> take chest
You carefully lift the chest with both hands, taking both hand slots. It's heavy.
```

### Rule 2: Dropping (PUT DOWN/DROP)

When player drops an object, hand slots are immediately freed.

```lua
if player.holding[object_id] then
    player.holding[object_id] = nil
    object.location = current_room
    -- Hand slots now available
end
```

**Example:**

```
> inventory
Hands:
  - both hands: wooden chest (2 hands)

> drop chest
You set the chest down carefully.

> inventory
Hands:
  - left hand: [empty]
  - right hand: [empty]

> take candle
You pick up the lit candle.
```

### Rule 3: Adding Items to Containers While Carrying

When carrying a two-handed object, the player **cannot** interact with other objects to store them.

```
> take chest                          -- Both hands occupied
> put key in chest
You're holding too many things. You'd need to put the chest down first to store the key.
```

**Why?** Because the player's hands are full holding the chest — there's no hand available to manipulate the key or place it.

### Rule 4: Interactions While Carrying

When carrying a two-handed object, the player **cannot:**

1. Pick up additional single-handed items
   - "You'd need to put the chest down first."

2. Light a candle or access light sources
   - "Both your hands are full. You'd need to put the chest down."

3. Use weapons, tools, or manipulation objects
   - "Your hands are occupied carrying the chest."

4. Perform crafting actions (sewing, writing, etc.)
   - "You need both hands free to do that."

When carrying one-handed objects, the player **can still:**

1. Wear items (wearables don't use hand slots)
2. Access worn containers (backpack, satchel)
3. Interact with furniture (examine, open, move)

## Error Messages (Prime Directive)

All two-handed constraint messages use natural, conversational language:

### When picking up

```
❌ "You'd need to put the chest down first."
   (trying to pick up chest while holding candle)

❌ "Your hands are full."
   (generic: both hand slots occupied)

❌ "Both your hands are already occupied."
   (specific: two items, each requiring 1 hand)
```

### When trying to use tools

```
❌ "You need a free hand to hold the candle."
   (trying to pick up candle while carrying chest)

❌ "Both your hands are full. You'd need to put the chest down first to use the match."
   (trying to interact with fire source while carrying chest)
```

### When trying to store

```
❌ "You're holding too many things. You'd need to put the chest down first."
   (trying to put key in chest while carrying chest)
```

### When trying to craft

```
❌ "You need both hands free to sew."
   (trying to sew while holding two-handed object)
```

### Success messages

```
✅ "You lift the heavy chest with both hands."
   (picking up two-handed object)

✅ "You put the chest down carefully."
   (dropping two-handed object)

✅ "You set the candle down and now have both hands free."
   (strategic drop for other action)
```

## Inventory Display

The inventory system shows hand slots separately from worn items and containers:

```
> inventory

Hands:
  - left hand: [empty]
  - right hand: lit candle (1 hand)

Worn:
  - on head: [nothing]
  - on torso: [nothing]
  - on feet: [nothing]
  - backpack: leather satchel (6 slots, 2 full)

Containers:
  - satchel contents: rope, iron key

Hand slots available: 1 / 2
```

**Display Logic:**

- Show each hand slot (left/right or numbered 1/2)
- Show occupied object and hands required
- Show remaining available slots (2 - occupied)
- Warn if near capacity ("Only 1 hand slot available!")

## Implementation Pattern

### Object Declaration

Two-handed objects declare their requirement in metadata:

```lua
{
  id = "chest",
  name = "a wooden chest",
  hands_required = 2,  -- Two hands required to carry
  portable = true,     -- Can be moved
  container = true,    -- Is a container
  -- ... other properties
}
```

### TAKE Verb Handler (Pseudocode)

```lua
function handle_take(ctx, object_id, target)
  local object = find_object(object_id)
  
  -- Check if player already holding it
  if ctx.player.holding[object_id] then
    return "Already holding it."
  end
  
  -- Check hand slot availability
  local used_hands = count_used_hand_slots(ctx.player)
  local available_hands = 2 - used_hands
  local required_hands = object.hands_required or 1
  
  if available_hands < required_hands then
    if required_hands == 2 then
      return "You'd need to put " .. (used_hands > 0 and "the " .. held_item.name .. " down first" or "things down") .. "."
    else
      return "Your hands are full."
    end
  end
  
  -- Success: add to inventory
  ctx.player.holding[object_id] = object
  ctx.player.hand_slots_used = used_hands + required_hands
  return "You lift the " .. object.name .. "."
end
```

### PUT DOWN Verb Handler (Pseudocode)

```lua
function handle_drop(ctx, object_id)
  local object = find_object(object_id)
  
  -- Check if player holding it
  if not ctx.player.holding[object_id] then
    return "You're not holding it."
  end
  
  -- Success: remove from inventory, place in room
  local freed_hands = object.hands_required or 1
  ctx.player.holding[object_id] = nil
  ctx.player.hand_slots_used = ctx.player.hand_slots_used - freed_hands
  
  object.location = ctx.current_room
  return "You set the " .. object.name .. " down carefully."
end
```

## Sensory Access During Carry

When carrying a two-handed object, sensory access to other objects is **blocked**:

```
> take chest
You carefully lift the chest with both hands.

> examine candle   [still in room]
You're holding too many things. You'd need to put the chest down first.

> listen
You can hear the ambient sounds, but both your hands are full with the chest.
```

**Exception:** Worn items and objects inside containers can still be accessed (sensory access to worn items ≠ hand interaction).

## Interaction Sequences

### Scenario 1: Exploring with Light, Find Treasure

```
Player: TAKE CANDLE
System: "You pick up the lit candle (1 hand). You can see."

Player: EXAMINE CHEST
System: [Can see chest in room]

Player: TAKE CHEST
System: "You'd need to put the candle down first."

Player: PUT DOWN CANDLE
System: "You set the candle down."

Player: TAKE CHEST
System: "You lift the chest with both hands (2 hands). It's heavy."

Player: GO NORTH
System: "You go north to the Bedroom, carrying the chest."

Player: PUT DOWN CHEST
System: "You set the chest down."

Player: TAKE CANDLE    [candle still in original room]
System: [Navigation required first]
```

### Scenario 2: Strategic Inventory Management

```
Player: TAKE DAGGER (1 hand), TAKE CANDLE (1 hand)
System: "Hands full: dagger and lit candle."

Player: TAKE ROPE
System: "Your hands are full."

Player: EXAMINE CHEST
System: "Heavy wooden chest, closed. Too heavy to move one-handed."

Player: DROP DAGGER
System: "You set the dagger down. Now one hand free."

Player: TAKE CHEST
System: "You'd need to put the candle down too. It requires both hands."

Player: DROP CANDLE
System: "You extinguish the candle. Darkness falls."

Player: TAKE CHEST
System: "You lift the chest with both hands."
```

### Scenario 3: Wearing a Container (Backpack)

```
Player: INVENTORY
System: "Backpack (worn, 4 slots, 1 full) - rope inside."

Player: TAKE CANDLE (1 hand)
System: "You pick up the candle (1 hand). Hands: 1/2 free."

Player: TAKE DAGGER (1 hand)
System: "You pick up the dagger (1 hand). Hands: 0/2 free."

Player: TAKE ROPE (wants to store in backpack, but hands full)
System: "Your hands are full. You'd need to put something down to pick it up."

Player: DROP DAGGER
System: "You set the dagger down."

Player: TAKE ROPE
System: "You pick up the rope and place it in your backpack."

Player: INVENTORY
System: "Hands: lit candle (1/2). Backpack (worn): rope. Dagger on ground."
```

## Future Extensions

### Multi-Size Two-Handed Objects

Future objects might have variable "bulkiness":

```lua
{
  id = "grand_piano",
  hands_required = 2,
  space_requires = 0.5  -- Takes up half the room (future spatial system)
}
```

### Strength-Based Hand Requirement

Future mechanics might scale hand requirement by player strength:

```lua
{
  id = "heavy_door",
  hands_required = 2,
  strength_threshold = 15  -- Needs 15 strength to carry with 1 hand; otherwise 2
}
```

### One-Handed Carry Mutation

Objects might transform to lighter states:

```lua
-- After removing items:
{ id = "chest-empty", hands_required = 1 }  -- Lighter when empty
```

## Design Philosophy

The two-handed system serves multiple purposes:

1. **Inventory Puzzle** — Forces meaningful choice between light sources and carrying capacity
2. **Pacing** — Slows strategic movement; prevents trivial "carry everything" loops
3. **Prime Directive** — All constraint messages feel conversational and helpful
4. **Realism** — Heavy objects naturally need both hands; lightweight objects don't
5. **Extensibility** — Future objects (musical instruments, furniture, weapons) can declare hand requirements

## See Also

- **[Chest Object Design](../objects/chest.md)** — Primary client for two-handed system
- **[Container Template](../templates/container.md)** — Container mechanics (independent of hand system)
- **[Inventory Management (REQ-017)](./00-design-requirements.md#req-017-player-two-handed-carry)** — Design requirement
- **[Player Model](../architecture/player/player-model.md)** — Player structure and inventory tracking
- **[Wearable System](./wearable-system.md)** — Hand slots vs worn slots distinction

---

**Last Updated:** 2026-03-25  
**Status:** Design complete, ready for implementation review  
**Complexity:** Medium (hand slot tracking, constraint validation, error messaging)
