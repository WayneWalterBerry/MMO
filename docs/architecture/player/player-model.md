# Player Model

**Version:** 1.0  
**Extracted from:** 00-architecture-overview.md  
**Purpose:** Complete specification of player entity structure, inventory system, and skill mechanics.

---

## Overview

The player is a first-class entity in the game state. The player model defines:
- What the player can hold (hand slots)
- What the player can wear (body slots)
- What skills the player has learned
- How player state persists and updates

---

## Player Entity Structure

```lua
player = {
    hands = { left = nil, right = nil },     -- What's held in hands?
    worn = {                                  -- What's worn?
        head = nil,
        torso = nil,
        feet = nil,
        -- ... other body slots
    },
    skills = {
        lockpicking = false,
        sewing = false,
        -- ... learned skills
    }
}
```

---

## Hand System

**Capacity:** 2 hands total (left + right)

**Object Declaration:**
- Objects declare `hands_required` (0, 1, or 2)
- Examples:
  - Single-handed: dagger, torch, key (1 hand)
  - Two-handed: sword, bow, heavy box (2 hands)
  - Hands-free: worn items, tools in containers

**Hand Resolution Logic:**
- When player attempts TAKE, engine checks available hands
- Heavy/large items tie up both hands
- Worn items don't consume hand slots
- If insufficient hands, action fails: "Your hands are full"

**Hand State Management:**
- Hands track object GUIDs
- Setting to `nil` represents "empty"
- TAKE populates hands; DROP clears them
- Player can manually switch grip (LEFT/RIGHT commands, future)

---

## Wearable System

**Body Slots:**
- Each worn item occupies one body slot
- Standard slots: head, torso, feet, hands (gloves), back (backpack)
- Expandable: custom slots per wearable

**Slot Conflict Rules:**
- Only one item per slot
- Attempting to wear item in occupied slot: fails with "Already wearing X"
- REMOVE unequips item to hands (must have hand space)

**Wearable Capabilities:**
1. **Containers:** Backpack on back becomes accessible storage
2. **Vision Blocking:** Sack on head / blindfold disables LOOK verb
3. **Light Casting:** Lantern on head casts light (worn light sources)
4. **Protection:** Armor reduces damage (Phase 2+)
5. **Tool Provision:** Gloves might provide grip bonus (Phase 2+)

**Wearable Object Declaration:**
```lua
backpack = {
    type = "wearable",
    wear_slot = "back",
    is_container = true,
    capacity = 10,
}

blindfold = {
    type = "wearable",
    wear_slot = "head",
    blocks_vision = true,
}
```

---

## Skills System

**Mechanics:**
- Binary state (learned or not learned)
- Once learned, persists for entire game session
- Gates access to certain verbs and tool combinations

**Skill Gating:**
1. **Verb Gating:** Some verbs require skills
   - SEW verb requires `skills.sewing`
   - PICK verb requires `skills.lockpicking`
   - Attempting without skill: "You lack the skill to do that"

2. **Tool Combinations:** Skills unlock advanced tool uses
   - PIN + lockpicking skill → creates lock pick (mutation)
   - Without skill, PIN remains a simple PIN

3. **New Mutations:** Learning skills opens new state transitions
   - Lockpicking skill enables lock picking state for doors

**Skill Discovery:**
- Found manual, read it → learn skill
- NPC teaching → learn skill
- Puzzle solve with proper sequence → learn skill
- Practice (future): repeated tool use might grant skill (Phase 2+)

**Skill Storage:**
```lua
player.skills = {
    lockpicking = false,    -- Not yet learned
    sewing = true,          -- Learned
    alchemy = false,
}
```

---

## Player Location & Context

**Location Tracking:**
- `ctx.current_room` stores player's current room ID
- Updated when movement verb executes successfully
- Used for:
  - Sensory queries (what can player see/feel?)
  - Object ticking (only objects in current room + player hands tick)
  - Exit validation (can player exit from current room?)

**Movement Details:** See [player-movement.md](player-movement.md)

---

## Player State in Game State

**Full State Context:**
```lua
ctx = {
    player = { ... },           -- Current player state (hands, worn, skills)
    current_room = "bedroom",   -- Player location
    -- ... rest of game state
}
```

**What's Persisted:**
- Player's hands and worn items
- Player's skills (learned state)
- Player's current room
- All mutated to cloud storage on each turn

**What's NOT Player-Specific:**
- Object definitions (shared across players in multi-player scenarios)
- Room layout (shared)
- Time (global clock)

---

## Related Systems

- **Skills:** See `player-skills.md` for detailed design
- **Movement:** See `player-movement.md` for movement mechanics
- **Sensory:** See Light & Dark System (Layer 8) for vision blocking and sensory gating
- **Tool Resolution:** Tool resolution uses player inventory; see `verb-system.md`
- **Consumables:** Consumed items remove from player inventory; see Layer 9

---

## Design Rationale

1. **Discrete Hand Slots:** Two hands mirrors physical reality; creates weight/burden puzzle
2. **Wearable Slots:** Clothing system adds flavor and solves weight management differently
3. **Binary Skills:** No levels/points; gates new verb access cleanly
4. **Location Tracking:** Enables efficient object ticking (only active area) and sensory gating
5. **Cloud Persistence:** Player state survives cross-device play; enables analytics on character evolution
