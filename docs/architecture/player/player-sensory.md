# Player Sensory Experience

**Version:** 1.0  
**Extracted from:** 00-architecture-overview.md, Layer 8: Light & Dark System  
**Purpose:** Specify how players perceive the world, sensory gating, and darkness mechanics.

---

## Overview

The player's sensory experience is shaped by two factors:
1. **Light/Dark State:** Whether the room/player is in light or darkness
2. **Vision Blocking:** Whether the player is wearing something that blocks sight

Sensory design creates puzzle depth: darkness forces non-visual senses (FEEL/SMELL/LISTEN).

---

## Light & Dark System

**Light Sources:**
- Objects with `casts_light = true` emit light
- Examples: lit candle, torch, lantern, glow stone
- Room-level check: if ANY object in room casts light, room is bright

**Daylight:**
- Outside areas + 6 AM to 6 PM + `allows_daylight = true` = automatic light
- Inside (house, cave) = no daylight, only object-provided light

**Vision Blocking (Player Worn Items):**
- Wearables with `blocks_vision = true` disable LOOK verb
- Examples: sack on head, blindfold, opaque helmet
- Overrides room light state: even in bright room, blindness prevents LOOK

**Sensory Verb Gating:**
1. **LOOK** — Requires light AND no vision blocking
   - Fails: "You see nothing in the darkness" (no light)
   - Fails: "Your sight is blocked" (wearing blindfold)

2. **FEEL / SMELL / TASTE / LISTEN** — Work in darkness
   - No light requirement
   - Bypasses vision blocking
   - Allows puzzles: "You can't see it, but you can feel something cold..."

3. **EXAMINE** — Requires light (inspect detail)
   - Light requirement prevents examination in darkness
   - Once LOOK succeeds, EXAMINE gives more detail

---

## Sensory Descriptions

**Sensory Gating by Light State:**
- Objects return different descriptions based on light
- Bright: "The cat is sleeping on the mat"
- Dark: "You hear gentle breathing but can't see what it is"

**Vision Blocking Impact:**
- While wearing vision-blocking item: LOOK disabled
- Player can still FEEL/SMELL/LISTEN
- Creates sensory puzzle: "You can't see, but you can feel the wall texture..."

---

## Player Perception Model

**What Determines Player Perception:**
1. **Room Light State** (any object casting light?)
2. **Time of Day** (6 AM to 6 PM = daylight outside)
3. **Player Worn Items** (vision blocking?)
4. **Verb Used** (LOOK vs FEEL vs SMELL)

**Sensory Priority:**
- LOOK/EXAMINE → Light required
- FEEL/SMELL/LISTEN → No light required
- Forces sensory puzzle design: "Light is out — what can you learn from touch?"

---

## Design Rationale

1. **Sensory Over Visual:** Darkness forces FEEL/SMELL/LISTEN; creates puzzle depth beyond "find the light source"
2. **Vision Blocking as Wearable:** Puzzles can require removing items to see
3. **Binary Light State:** Either room is light or not; no gradual dimming (keeps logic simple)
4. **Verb-Based Gating:** Different verbs have different sensory requirements (extensible)
5. **Object-Specific Descriptions:** Objects can tailor output based on light state

---

## Related Systems

- **Wearables:** Blocks vision defined on wearable objects; see player-model.md
- **Light Sources:** Objects with casts_light property; see Layer 8 in architecture overview
- **Game Clock:** Time determines daylight; see Layer 7
- **Verbs:** LOOK, FEEL, SMELL, LISTEN have sensory requirements; see verb-system.md
