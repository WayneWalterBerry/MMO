# Room Design: The Inner Courtyard

**Room ID:** `courtyard`  
**File:** `src/meta/world/courtyard.lua` *(not yet created)*  
**Status:** 🔴 New — Design Only (OPTIONAL ROOM)  
**Author:** Moe (World Builder)  
**Date:** 2026-07-21  
**Level:** 1 — The Awakening  
**Act:** Alternate Path (Window Escape)  

---

## 1. Physical Reality

**Space type:** Enclosed interior courtyard of a medieval manor house — open to the sky  
**Era/style:** Late medieval. The courtyard is bounded on all four sides by the manor's walls, rising 2-3 stories. This is the architectural heart of the building — an outdoor room, private and enclosed. In a medieval manor, the courtyard was the working center: a well for water, space for deliveries, access to kitchen and servants' quarters.  
**Dimensions (implied):** Roughly 10m × 10m — open and exposed after the confined interiors. The sky is visible. The manor walls rise on all sides, making the courtyard feel like the bottom of a stone well.  
**Materials:**
- **Ground:** Cobblestones — uneven, worn, some loose. Moss grows in the joints. Puddles where the stones have sunk.
- **Walls:** The manor's exterior stone walls surround the courtyard. Dressed limestone, ivy-covered on the east wall. Windows visible above (including the bedroom window, high up).
- **Well:** Circular stone well at the center. Dressed limestone with an iron winch and a wooden bucket on a rope.
- **Sky:** Open to the elements. Moonlit at 2 AM. Stars visible. The first natural light the player has seen.
- **Other:** Wooden rain barrel against the north wall. Kitchen door (wooden, possibly locked) in the east wall.

**Architectural logic:** In a medieval manor house, the inner courtyard was essential — it provided light and air to interior rooms, collected rainwater, and served as a secure outdoor space. This courtyard is functional but neglected: the cobblestones are uneven, the ivy is overgrown, the well hasn't been maintained. The bedroom window is visible high above — the player can see where they jumped/climbed from, reinforcing the danger of the route they took. The kitchen door (east wall) and a potential servant's passage (west wall) connect to the ground floor — providing a way back inside.

---

## 2. Sensory Design

### description (moonlit — natural light from sky)
> "You stand in a cobblestone courtyard enclosed by the manor's stone walls on all four sides. Above, the sky is open — stars scattered like ice chips across a deep black field, and a half-moon casting silver light over everything. A stone well stands at the center, its iron winch creaking faintly in the breeze. Ivy smothers the east wall in a dark, dense curtain. The air is cold and damp and smells of rain, wet stone, and chimney smoke from somewhere above. High on the south wall, far above your reach, you can see the bedroom window — a dark rectangle in the moonlight."

**Design notes:** First EXTERIOR space. The open sky must be impactful — the player has been in enclosed stone rooms for their entire experience. Moonlight provides natural illumination (light_level ~1-2, enough to see but not well). The bedroom window visible above grounds the space — the player recognizes where they came from.

### feel (dark — if clouds obscure moon)
> "Uneven ground underfoot — cobblestones, cold and slick with moisture. The air is sharp and open — no walls pressing close, no ceiling above. For the first time, you feel SPACE — open sky, moving air, the chill of night. Your feet splash in puddles between the stones. You reach out: to your left, a stone wall, cold and rough, draped in something leafy and thick — ivy. Ahead, your hands find a circular stone rim at waist height — a well, its lip worn smooth by centuries of rope and bucket. The wind carries the smell of rain and chimney smoke."

### smell
> "Rain — recent rain on cobblestones, that clean, mineral scent of wet rock. Chimney smoke, drifting down from somewhere above — the flue of a fireplace in the manor, though no fire seems to burn now. Ivy — the green, faintly bitter smell of living plants. And beneath it all, the cold, open smell of night air — something you've been starved of since waking. It smells like freedom, but the high walls around you say otherwise."

### sound
> "Wind. Not strong, but present — a breeze that lifts the ivy and makes the well's winch creak. Water dripping from somewhere — a gutter, a leak, rain running off the roof hours ago. The distant hoot of an owl. Your own footsteps on wet cobblestones, loud and echoless in the open air. And from inside the manor — nothing. The windows above are dark, the doors are shut. The building watches in silence."

---

## 3. Spatial Layout

```
    North Wall (Manor exterior, rain barrel)
    ┌──────────────────────────────────────┐
    │                                      │
    │   [rain-barrel]                      │
    │   (against north wall)               │
    │                                      │
    │                                      │
    │              [stone-well]            │
    │              (center of courtyard,   │
    │               with winch + bucket)   │
    │                                      │
    │                                      │
    │   [ivy]                              │
    │   (east wall,      [wooden-door]     │
    │    thick curtain    (east wall,      │
    │    of vegetation)   kitchen?)        │
    │                                      │
    │   [loose                             │
    │    cobblestones]                     │
    │   (scattered,                        │
    │    some pryable)                     │
    │                                      │
    │                          [bedroom    │
    │                           window     │
    │                           visible    │
    │                           HIGH above]│
    └──────────────────────────────────────┘
    South Wall (Bedroom above; window high up)
```

**Placement logic:**
- **Stone well** — dead center of the courtyard. The dominant feature. Functional (contains water), potentially hides secrets at the bottom.
- **Rain barrel** — against the north wall. Collects rainwater from the gutters. Contains water. Wooden, old, but functional.
- **Ivy** — covers the east wall in a thick curtain. Climbable? Conceals the wall surface (maybe hides a window or servant's entrance behind it).
- **Loose cobblestones** — scattered around the courtyard edges. Some can be pried up. Takeable (tool/weapon). One might conceal something beneath.
- **Wooden door** — east wall, ground level. Leads to kitchen or servants' area. Locked? Openable?
- **Bedroom window** — visible high on the south wall, 2-3 stories up. If the player came via window escape, they fell/climbed from there. If they broke the window, broken glass is visible from below.

---

## 4. Exits

### Window (up) → Bedroom
- **Type:** `window`
- **Passage ID:** `bedroom-courtyard-window` (matches bedroom's window exit)
- **State:** Depends on bedroom window state. If player broke it to get here, it's a shattered frame. If they opened it, it's open. The direction is UP — the player can't easily return this way (the window is 2-3 stories up).
- **Constraints:** max_carry_size 2, requires_hands_free, player_max_size 4
- **Design note:** This exit is effectively ONE-WAY downward. The player dropped into the courtyard from the window. Climbing back up would require rope + some means of getting it up there (throw through window frame? Shoot with arrow?). For Level 1, this is likely not a viable return path. The player must find another way inside.

### East — Wooden Door → Kitchen / Servants' Hall
- **Type:** `door`
- **Passage ID:** `courtyard-kitchen-door`
- **State:** Locked (or stuck). The player needs to force it, pick it, or find a key.
- **Constraints:** max_carry_size 4, player_max_size 5
- **Description (locked):** "A stout wooden door, warped with age and damp. The latch is rusted shut. Through the crack beneath it, you smell old cooking fires and grease."
- **Design note:** This is the courtyard player's PRIMARY way back inside. It connects to the manor's ground floor (kitchen area), which connects to the hallway. Puzzle 013 involves getting through this door. Could be forced with the crowbar (if player has it), picked with the pin, or opened with brute force.

### Potential: Ivy / Climbing → Upper Floor Window
- **Type:** `climbing surface`
- **Not a formal exit** — could be an emergent path if the player climbs the ivy. Risky (ivy might not hold), leads to an upper-floor window. If the engine supports climbing mechanics, this becomes an alternate way back inside. Otherwise, it's a red herring (ivy tears away, player falls back to courtyard).

---

## 5. Environmental Properties

| Property | Value | Rationale |
|----------|-------|-----------|
| `temperature` | 8°C | COLD. Outdoor, nighttime, no shelter. Colder than any interior space. Wind chill. |
| `moisture` | 0.7 | HIGH. Open to weather. Recent rain. Puddles on cobblestones. Damp air. |
| `light_level` | 1 | DIM MOONLIGHT. Not total darkness — the open sky provides faint natural light. Enough to see shapes and large objects, not enough to read or examine details. Player's carried light source still useful for close examination. |

**Material interactions at moisture 0.7, temperature 8°C:**
- Iron (well winch, door hardware): High rust risk. The winch is described as creaking — partially rusted.
- Wood (door, rain barrel, well bucket): Damp, swollen. The door is warped shut by moisture exposure.
- Stone (well, cobblestones, walls): Slick with moisture. Moss growing in joints.
- Fabric (if player carries cloak): Gets damp from rain/mist. Provides some warmth against wind but moisture reduces insulation.
- Rope (well rope): Hemp, damp but functional. Could be cut and taken.
- Plants (ivy): Living vegetation — the only living organic material the player has encountered. Responds to moisture and light (moonlight).

**Environmental design insight:** This is the first EXTERIOR room. The environmental properties are fundamentally different from interiors: exposed to weather, natural light (moonlight), wind, living plants. The material system should reflect outdoor exposure — everything is damper, colder, more weathered. Objects left here would deteriorate faster than objects indoors.

---

## 6. Objects Inventory

All objects are **🔴 NEW** (need to be designed by Flanders).

### Room-Level Objects

| Object | Type | Spatial Position | Status | Notes |
|--------|------|------------------|--------|-------|
| stone-well | Stone Well | Center of courtyard | 🔴 NEW | Circular stone well with iron winch mechanism and wooden bucket on rope. Container (contains water). Deep (~10m). Bucket can be lowered/raised. Could conceal items at the bottom. Immovable. |
| well-bucket | Well Bucket | Hanging from well winch | 🔴 NEW | Wooden bucket on hemp rope. Can be lowered into well and raised. Container for water/small items. |
| ivy | Ivy | East wall | 🔴 NEW | Dense curtain of climbing ivy. Living plant. Possibly climbable (risky). Might conceal a window or passage behind it. Tearable (reveals wall surface). |
| cobblestone | Loose Cobblestone | Ground, near south wall | 🔴 NEW | Pryable from ground. Takeable. Tool/weapon (blunt). Heavy for its size. One might conceal something beneath. |
| rain-barrel | Rain Barrel | Against north wall | 🔴 NEW | Large wooden barrel, open-topped. Contains rainwater. Container. Could be used to wash, extinguish fire, or fill vessels. |
| wooden-door | Wooden Door | East wall (exit to kitchen) | 🔴 NEW | Exit object. Warped shut by moisture. Part of courtyard-kitchen-door exit. Breakable? Forcible? |

**Total: ~6 object instances**

**Flanders coordination notes:**
- Stone well: Complex interactive object. The winch mechanism allows lowering/raising the bucket. The well is deep — LOOK DOWN shows darkness, water glinting. LISTEN = water echoing far below. Potentially dangerous (fall in = death? injury?).
- Well bucket: Container that can be lowered (LOWER BUCKET, TURN WINCH) and raised (RAISE BUCKET, TURN WINCH). When lowered, fills with water. Could retrieve items from the bottom of the well.
- Ivy: Environmental object. CLIMB IVY = risky (might hold, might tear). PULL IVY or CUT IVY = tears away a section, revealing the wall behind. Behind the ivy: bare stone wall, OR a hidden window/passage (Bob/Wayne to decide).
- Cobblestone: Takeable when pried up (PRY COBBLESTONE, or PULL COBBLESTONE). Heavy, blunt. Could be used as weapon, tool (break things), or as weight/anchor.
- Rain barrel: Open-top container of water. Useful for: washing (blood, dirt), extinguishing fire, filling vessels. Atmospheric.

---

## 7. Puzzle Hooks

| Puzzle ID | Name | Difficulty | Status | Description |
|-----------|------|------------|--------|-------------|
| 013 | Courtyard Entry | ⭐⭐⭐⭐ | 🔴 New | OPTIONAL. Player reached courtyard via window escape and must find a way BACK INSIDE the manor. Multiple possible solutions: (a) force the kitchen door (crowbar, cobblestone, brute force), (b) pick the lock (pin from bedroom), (c) climb the ivy to an upper window (risky), (d) use rope (if acquired) to climb back up to bedroom window. Teaches: creative problem-solving, alternate solutions, consequences of choices. |

**Bob's design notes:**
- **Puzzle 013** should have 3-4 distinct solution paths, each with different difficulty/risk:
  - **Force door (⭐⭐⭐):** Use crowbar or cobblestone on kitchen door. Noisy. Works.
  - **Pick lock (⭐⭐⭐⭐):** Use pin or knife on door latch. Quiet. Requires finesse.
  - **Climb ivy (⭐⭐⭐⭐⭐):** Very risky. Ivy might tear. Player could fall. If it works, they reach an upper window. High skill, high reward.
  - **Rope ascent (⭐⭐⭐⭐):** Requires rope from storage cellar (unlikely if player came via window escape, unless they explored cellars first). Throw rope through bedroom window frame, climb up. Elegant but requires foresight.
- The INTENDED solution is probably (a) or (b). The player who came through the window probably has the pin and/or knife from the bedroom.
- **Well exploration** is not a puzzle per se, but lowering the bucket might retrieve an item from the bottom (a coin, a ring, a small key — lore item, not critical path).

---

## 8. Map Context

### Player Journey Through This Room
1. **Arrival:** Player breaks/opens the bedroom window and drops into the courtyard. This is a DANGEROUS path — potential injury from the fall (broken glass, impact).
2. **Disorientation:** First exterior space. Open sky. Moonlight. Cold wind. Everything is different — the player's senses recalibrate.
3. **Assessment:** They're in an enclosed courtyard. The manor walls surround them. The bedroom window is far above. They need to get back inside.
4. **Exploration:** Discover the well, the rain barrel, the ivy, the kitchen door. Assess their tools (what did they bring from the bedroom?).
5. **Puzzle 013:** Find a way through the kitchen door (or up the ivy, or back through the window with rope). Enter the manor at ground level.
6. **Reconnection:** Kitchen → Hallway → rejoin the main path (or explore from a different angle than cellar players).

### Connections
- **Up → Bedroom (window):** Where the player came from. Effectively one-way DOWN. Return requires rope/climbing.
- **East → Kitchen/Servants' Hall:** Through the wooden door. Primary re-entry path. Locked/stuck.
- **Potential → Upper floor:** Via ivy climbing. Risky alternate re-entry.

### Environment Role
The courtyard is an **alternate-path reward room**:
1. **Risk/reward payoff:** Only accessible to players who take the dangerous window escape. They're rewarded with unique content (exterior space, moonlight, the well) but punished with a new challenge (getting back inside).
2. **Environmental contrast:** First outdoor space. Open sky, wind, rain, living plants (ivy). Fundamentally different sensory experience from every previous room.
3. **Perspective shift:** From inside looking out (bedroom window) to outside looking up (courtyard floor). The player sees the manor from a new angle — literally and metaphorically.
4. **Resource discovery:** The well provides water (washing, filling vessels). The cobblestone provides a blunt tool. These are unique resources not available on the cellar path.
5. **Narrative texture:** The neglected courtyard (overgrown ivy, puddled cobblestones, creaking winch) continues the story of abandonment. But the chimney smoke hints at SOMEONE still present — the manor isn't completely empty.

### Adjacency Notes
- **Above (south wall):** Bedroom window. 2-3 stories up. One-way down unless player has rope/climbing ability.
- **East (ground level):** Kitchen or servants' hall. Door stuck/locked. Primary re-entry to manor.
- **The courtyard is ISOLATED from the cellar path.** Players who take the cellar route never see the courtyard (unless they backtrack to the bedroom and then break the window, which would be unusual). The courtyard is exclusive alternate-path content.
