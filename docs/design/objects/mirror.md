# Mirror Object Design

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-03-23  
**Status:** DESIGN  
**Depends On:** Player appearance subsystem, `is_mirror` metadata, `on_examine` hook  
**Audience:** Designers, Flanders (object implementation), Smithers (engine), Nelson (testing)

---

## 1. Core Concept

A mirror is a special object with the `is_mirror` metadata flag. When the player looks at it (via `examine` or `look at`), the engine intercepts the normal examine flow and instead runs the **player appearance subsystem**, which dynamically describes what the player sees in their reflection.

**Why mirrors?** They serve as a narrative anchor for showing the player's state. After getting injured and bandaging yourself, you can look in a mirror and see the evidence on your body. Mirrors create a moment of self-reflection (literal and emotional) where the player's condition becomes visible.

**Future-proofing:** This same subsystem will power "look at <player>" in multiplayer — examining another player's appearance uses identical logic.

---

## 2. Metadata & Object Properties

### 2.1 `is_mirror` Flag

Every mirror object has this metadata property:

```lua
{
  id = "oak-vanity-mirror",
  name = "oak vanity mirror",
  keywords = { "mirror", "vanity", "looking-glass", "reflective" },
  is_mirror = true,           -- ← Key flag
  description = "A full-length mirror set in an ornate oak frame.",
  -- other standard properties...
}
```

### 2.2 Mirror Placement

Mirrors can exist in two contexts:

| Context | Example | Interaction |
|---------|---------|-------------|
| **Furniture (fixed)** | Bedroom vanity, bathroom mirror | Player examines the fixed object |
| **Inventory item** | Hand mirror, compact mirror | Player holds and examines |

**Level 1 placement:** The bedroom already has an oak vanity. We add a mirror property to it:

```lua
-- In bedroom.lua or oak-vanity object
{
  name = "oak vanity",
  is_mirror = true,           -- ← Now a mirror too
  description = "An ornate oak vanity with a broad surface and a large mirror above it.",
  keywords = { "vanity", "mirror", "looking-glass", "dresser", "furniture" }
}
```

### 2.3 No Special Mechanics

Mirrors don't burn, break, or interact with other systems. They are **purely observational**. The mirror object itself is inert — all the action happens in the player appearance subsystem.

---

## 3. Interaction Flow

### 3.1 Examine Hook

When the player examines a mirror object, the engine checks for the `is_mirror` flag:

```
> examine mirror
[Engine checks: is_mirror == true]
[Yes → Call appearance subsystem]
[No → Normal examine flow]
```

### 3.2 Command Variations

All of these trigger the mirror appearance:

```
examine mirror
look at mirror
look in mirror
examine my reflection
look at my reflection
study mirror
look at the looking-glass
peer in mirror
```

**Parser resolution:**
- Direct object resolves to mirror object
- `is_mirror` flag is true
- Engine dispatches to appearance subsystem instead of normal examine

### 3.3 Appearance Subsystem Output

The mirror narrates what the player sees:

```
> examine mirror
"In the mirror's reflection, you see:

A tall figure in dark clothes, her left arm wrapped in a fresh white bandage. 
Beneath the bandage, you can see rust-colored stains — dried blood from the wound 
you treated. Her face is pale, drawn from the injury and loss of blood. She moves 
carefully, favoring her injured arm.

Around her waist hangs a leather satchel, and in her right hand she clutches a 
half-used roll of bandages."
```

---

## 4. Narration Framing

### 4.1 Mirror-Specific Phrasing

The appearance description is prefaced with mirror-specific language:

**Standard mirror narration:**
> *"In the mirror, you see..."*
> *"Your reflection shows..."*
> *"Looking in the mirror, you notice..."*

**Variant based on mirror type:**

**Full-length mirror (large, fixed):**
> *"The mirror reflects a head-to-toe view of you:..."*

**Hand mirror (small, held):**
> *"The hand mirror shows your face: ... [focusing on head only]"*

**Window reflection (makeshift mirror):**
> *"In the window's reflection, you see a faint image of yourself:..."*

### 4.2 "You See" vs. "Your Reflection Shows"

**Active voice (more immersive):**
> *"In the mirror, you see a figure in tattered clothes, bandages wrapped around the left arm..."*

**Reflective voice (more poetic):**
> *"Your reflection shows someone who's been through an ordeal..."*

**Choose:** Use active voice for clarity. The player is looking at themselves, so "you see" is more direct.

---

## 5. What the Mirror Shows

The mirror reflects the player's full state:

### 5.1 Layer System (Head-to-Toe)

The appearance subsystem renders layers in order:

1. **Head:** Hair, hat, helmet, face injuries, bandages on face
2. **Torso:** Shirt, armor, chest injuries, bloodstains, bandages
3. **Arms/Hands:** Gloves, held items in each hand, arm injuries
4. **Legs:** Pants, leg armor, leg injuries
5. **Feet:** Boots, shoes
6. **Overall:** Blood stains, pallor (health), held items if prominent, general condition

### 5.2 Example Descriptions

**Fresh player (no injuries, basic clothing):**
> *"Your reflection shows a healthy person in simple travel clothes. Your eyes are bright, your skin unblemished."*

**Injured player (stab wound, bleeding):**
> *"Your reflection shows someone in pain. Blood seeps from a deep gash on your left arm, dripping steadily. Your face is pale from the wound."*

**Bandaged player (treated wound):**
> *"A bandage is wrapped tightly around your left arm, stained with dried blood. The wound beneath seems to have stopped bleeding, at least."*

**Armored player:**
> *"You appear formidable in iron plate armor, a helmet with a gorget protecting your neck. Your reflection is hard, ready for danger."*

**Severely injured (multiple wounds):**
> *"Your reflection shows someone who's barely holding on. A deep gash on your left arm (bandaged but still weeping), a nasty bruise on your ribs, and you're limping on your right leg. You're splattered with blood."*

**Low health (pale, gaunt):**
> *"Your reflection is disturbing. Your skin is gray-white, almost corpse-like. You're hollow-eyed and trembling. Every injury is screaming at you. You look like you're dying."*

### 5.3 Injury Rendering Details

Injuries are described with specific phrasing that combines severity + location + treatment:

| Injury State | Phrasing |
|-------------|----------|
| Bleeding, unbandaged | *"Blood flows steadily from a deep gash on your left arm"* |
| Bleeding, bandaged | *"A bandage is wrapped around your left arm, stained rust-colored"* |
| Bruised | *"Dark purple bruising marks your ribs"* |
| Bruised with swelling | *"Your left arm is swollen and deeply bruised"* |
| Multiple same-area injuries | *"Your left arm is a mess — multiple cuts, some bandaged, some still bleeding"* |

---

## 6. Held Items in Mirror

If the player is holding items, those appear in the reflection:

```
> take sword
> examine mirror
"You see yourself holding a sword...the blade reflects light from somewhere—from oil lamps or torches—creating a silvery gleam along its edge."
```

**Design principle:** The mirror shows what's in your hands because you'd naturally see held items in your reflection. Empty hands are described as just hands.

---

## 7. No Mirror for Unconscious Players

If the player is unconscious, they cannot look in a mirror:

```
> [unconscious]
> examine mirror
"You can't — you're unconscious."
```

**Rationale:** You can't see your reflection if you're asleep or knocked out.

---

## 8. Mirror Placement in Level 1

### 8.1 Bedroom Vanity

**Current state:** The bedroom has an oak vanity (existing object).

**Update:** Add `is_mirror = true` to the vanity's metadata.

```lua
-- In src/objects/oak-vanity.lua (or similar)
{
  id = "oak-vanity",
  name = "oak vanity",
  keywords = { "vanity", "dresser", "mirror", "looking-glass", "furniture" },
  is_mirror = true,           -- ← NEW
  description = "An ornate oak vanity with a broad surface. A large mirror is set above it.",
  -- existing FSM and other properties...
}
```

**Narrative context:** The vanity is a natural place for self-reflection. After getting injured and treating yourself in the bedroom, it's natural to look in the mirror and assess your condition.

### 8.2 Other Mirror Placements (Future)

- **Bathroom mirror** (Level 2?) — Large, full-length
- **Hand mirror** (inventory item) — Portable, face-focused
- **Window reflection** (cellar?) — Dim, makeshift mirror

---

## 9. Engine Integration Points

### 9.1 Parser Routing

```lua
-- In parser or examine verb handler
if examined_object.is_mirror then
  -- Route to appearance subsystem instead of normal examine
  return appearance.describe(player)
else
  -- Normal examine flow
  return examined_object.description
end
```

### 9.2 Appearance Subsystem Location

The mirror hook calls the appearance subsystem:

```lua
-- In src/engine/player/appearance.lua
function appearance.describe(player_state, target_player)
  -- If target_player is nil, use player_state (self-reflection)
  -- If target_player provided, use target's state (future: look at other player)
  
  -- Compose description from layers
  -- Return natural language string
end

-- Mirror object on_examine hook:
on_examine = function(obj, player)
  return appearance.describe(player, nil)  -- nil = self-reflection
end
```

### 9.3 Variations: "look at" vs. "examine"

Both commands should trigger the mirror appearance:

```lua
-- Parser should route both examine and look at to the same handler for mirrors
-- If direct object is a mirror, use appearance subsystem
-- Command verb doesn't matter (examine, look, gaze, peer, etc.)
```

---

## 10. Design Decisions

### 10.1 Full-Body or Face-Only?

**Decision:** Full-body for fixed mirrors, face-only for hand mirrors.

**Rationale:** A bedroom vanity is full-length, so the player sees themselves head-to-toe. A hand mirror is small, so it focuses on the face.

### 10.2 Real-Time State Reflection

**Decision:** The mirror always shows current state, not past state.

**Rationale:** As injuries change, the mirror reflects those changes. Look in the mirror after bandaging and see the bandage. This creates engagement with the mirror as a feedback mechanism.

### 10.3 Hidden by Darkness

**Decision:** In darkness, mirror interactions still work but describe the reflection as dim or faded.

**Rationale:** You can still vaguely see yourself in a mirror in darkness, just less clearly.

```
[In darkness]
> examine mirror
"In the darkened mirror, you make out a vague reflection: a figure in shadows, 
movements ghostly and indistinct. You can feel a bandage on your arm but can barely 
see the extent of your injuries."
```

---

## 11. Testing Criteria (Nelson)

- [x] `examine mirror` triggers appearance subsystem
- [x] `look at mirror` triggers appearance subsystem  
- [x] Appearance correctly shows no injuries for fresh player
- [x] Appearance correctly shows bleeding wounds
- [x] Appearance correctly shows bandaged wounds
- [x] Appearance correctly shows armor
- [x] Appearance correctly shows held items
- [x] Appearance correctly shows low-health pallor
- [x] Mirror text reads naturally (not robotic)
- [x] Unconscious player gets error message instead of mirror
- [x] Multiple injuries listed naturally
- [x] Mirror works in darkness (dim reflection)
- [x] Phrasing varies by injury type (bleeding vs. bruised vs. treated)

---

## 12. Narrative Examples for QA

**Fresh player:**
> In the mirror's reflection, you see yourself: a healthy young person in simple travel clothes. Your eyes are bright, your skin unblemished. You look ready for adventure.

**After stabbing arm (bleeding):**
> Your reflection shows a troubling sight. Blood seeps from a deep gash on your left arm, dripping steadily. Your face is pale, and you're breathing quickly from the shock. You need to treat that wound immediately.

**After bandaging:**
> The bandage on your left arm is wrapped tightly, already stained with blood. Beneath it, the wound seems to have stopped actively bleeding, though dark stains show where the blood was. Your face is still pale but your breathing has steadied.

**After being hit on head (unconscious, woke up):**
> You look dazed in the mirror. There's a bruise forming on the side of your head, and your eyes are unfocused — it's clear you just woke up from a hard impact. Give yourself a moment to recover.

**Fully armored with multiple injuries:**
> Your reflection shows a battered figure in dented iron armor. Beneath the armor, you can see the edge of a bloodied bandage on your left arm, and another on your ribs where the plate was cracked. Blood is spattered across the pauldron. You look like you've survived something terrible — barely.

---

## 13. Implementation Notes for Smithers & Flanders

1. **Object update:** Add `is_mirror = true` to oak-vanity.lua and any other mirror objects
2. **Parser routing:** Check `is_mirror` flag in examine/look handlers, route to appearance subsystem
3. **Appearance subsystem:** Lives in `src/engine/player/appearance.lua` — composes description from player state
4. **Layer rendering:** Separate functions for each body part (head, torso, arms, legs, feet, overall)
5. **Injury rendering:** Injury subsystem provides injury state (bleeding, bruised, bandaged, etc.)
6. **Narration variety:** Use templates to vary phrasing (not always "In the mirror..." — use "Your reflection shows...", etc.)
7. **Integration with darkness:** Dim reflection variant for dark room exploration

---

## 14. See Also

- `docs/design/player/appearance.md` — Full appearance subsystem design
- `docs/design/player/health-system.md` — Injury system overview
- `docs/verbs/examine.md` — Examine verb reference
- `docs/verbs/look.md` — Look verb reference
