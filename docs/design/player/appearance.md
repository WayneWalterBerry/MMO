# Player Appearance Subsystem — Gameplay Design

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-03-23  
**Status:** DESIGN  
**Depends On:** Player state model, Injury system, Wearable system, Inventory system  
**Audience:** Designers, Smithers (engine), Nelson (testing)

---

## 1. Core Concept

The player appearance subsystem is an **engine component** that reads the player's current state (worn items, injuries, held items, health level) and **composes a natural language description** of what they look like.

**Why separate subsystem?** Appearance is reusable across contexts:
- **Today:** Mirrors show the player their own appearance
- **Tomorrow (multiplayer):** `look at <player>` shows another player's appearance using identical logic
- **Future:** NPCs comment on player condition ("You look hurt, friend")

This subsystem takes input of raw state flags and produces output of *beautiful, natural prose* — not robotic lists.

---

## 2. Input: Player State Model

The subsystem reads from a player state table:

```lua
{
  -- Worn items (equipment slots)
  worn = {
    head = helmet_object,
    torso = armor_object,
    left_arm = glove_object,
    right_arm = glove_object,
    legs = pants_object,
    feet = boot_object,
    hands = nil,  -- Wearables that cover hands only
  },
  
  -- Held items (in each hand)
  held = {
    left_hand = sword_object,
    right_hand = nil,
  },
  
  -- Active injuries
  injuries = {
    {
      id = "stab-wound-left-arm",
      type = "bleeding",
      location = "left_arm",
      severity = "serious",
      treatment = "bandaged",  -- or "untreated" or "healed"
      duration = 5,
    },
    {
      id = "bruise-ribs",
      type = "bruised",
      location = "torso",
      severity = "moderate",
      treatment = "untreated",
    },
  },
  
  -- Overall health state
  max_health = 100,
  current_health = 35,  -- Derived from injuries, but stored for efficiency
  
  -- Consciousness state
  consciousness = "conscious",  -- or "unconscious" or "waking"
}
```

---

## 3. Output: Composed Natural Language

The subsystem produces a single narrative paragraph (or multi-paragraph prose) that describes the player:

```
> examine mirror
"Your reflection in the mirror shows a battered figure. You wear iron plate armor, 
dented on the left side where a deep gash runs beneath. Blood has stained the metal 
rust-colored and dried. A bandage peeks from under the armor at your ribs — you 
wrapped that wound this morning, and it still hasn't stopped weeping entirely.

Your left arm hangs at an awkward angle, swollen and deeply bruised from the 
fall. You're not holding anything in your right hand — it's steady. In your left 
hand, you're gripping a sword with white knuckles.

Your face in the mirror is pale, hollow-eyed. You're breathing quickly. Your skin 
has taken on a grayish tint — you've lost too much blood. How much longer can you 
keep going?"
```

This is *not* a list. It's prose that flows naturally and creates emotional presence.

---

## 4. Layer System: Head-to-Toe Ordering

The subsystem renders appearance in layers, proceeding from head to feet, then a summary:

### 4.1 Layer Execution Order

```lua
function appearance.describe(player)
  local layers = {
    render_head(player),
    render_torso(player),
    render_arms_hands(player),
    render_legs(player),
    render_feet(player),
    render_overall_health(player),
  }
  
  -- Filter out nil layers (nothing notable to say)
  -- Compose into prose with natural connectives
  return compose_prose(layers)
end
```

### 4.2 Layer Definitions

Each layer is responsible for describing one part of the body:

| Layer | Covers | Content |
|-------|--------|---------|
| **Head** | Hair, hat, helmet, face injuries, head bandages | *"A dented iron helmet covers your head..."* |
| **Torso** | Shirt, chest armor, chest injuries, chest bandages, blood stains | *"You wear a leather jerkin over a white shirt, now stained with blood..."* |
| **Arms/Hands** | Gloves, arm injuries, held items in each hand | *"Your left arm is heavily bandaged..."* or *"You're holding a torch in your right hand..."* |
| **Legs** | Pants, leg armor, leg injuries, leg bandages | *"Your legs are bare except for bruises..."* |
| **Feet** | Boots, shoes | *"You're barefoot..."* or *"Worn leather boots cover your feet."* |
| **Overall** | Health status (pale, flushed, gaunt), blood coverage, general condition | *"You look like you're dying. Your skin is gray-white..."* |

### 4.3 Nil Layers (Skipped)

If a layer has nothing notable, it returns `nil` and is skipped:

```lua
function render_feet(player)
  if player.worn.feet == nil and no_feet_injuries(player) then
    return nil  -- Nothing to say about bare feet in good condition
  end
  -- ... compose feet description
end

-- In final output, nil layers are filtered out:
local non_nil_layers = {}
for _, layer_text in ipairs(layers) do
  if layer_text ~= nil then
    table.insert(non_nil_layers, layer_text)
  end
end
```

---

## 5. Injury Rendering Pipeline

### 5.1 Injury Phrase Composition

Each injury is rendered as a phrase that combines severity, location, and treatment status:

```lua
function compose_injury_phrase(injury)
  -- injury = {
  --   type = "bleeding",
  --   location = "left_arm",
  --   severity = "serious",
  --   treatment = "bandaged",
  -- }
  
  local phrases = {
    ["bleeding"] = {
      untreated = "blood seeps from",
      bandaged = "a bandage, stained with blood, wraps around",
      healed = "an old scar marks",
    },
    ["bruised"] = {
      untreated = "dark purple bruises mark",
      bandaged = "bruises covered by",
      healed = "faint bruises remain on",
    },
    ["poison"] = {
      active = "you're flushed and feverish from",
      recovering = "you still feel the effects of",
    },
  }
  
  -- Build the phrase
  local severity_modifier = get_severity_descriptor(injury.severity)
  local treatment_phrase = phrases[injury.type][injury.treatment]
  local location_description = get_body_part_article(injury.location)
  
  return severity_modifier .. " " .. treatment_phrase .. " " .. location_description
end
```

### 5.2 Injury Phrasing by Type

**Bleeding (untreated):**
> *"Blood flows steadily from a deep gash on your left arm"*

**Bleeding (bandaged):**
> *"A bandage is wrapped around your left arm, stained with dried blood. You can see it's still weeping at the edges."*

**Bleeding (healed):**
> *"An old scar marks your left arm where the wound has finally closed."*

**Bruised (untreated):**
> *"Dark purple bruising marks your ribs"*

**Bruised (swollen):**
> *"Your left arm is swollen and deeply bruised from the fall"*

**Poisoned (active):**
> *"You're flushed and trembling — your body is fighting something"*

**Poisoned (recovering):**
> *"You're still pale from the poison, though the worst seems to have passed"*

### 5.3 Multiple Injuries on Same Body Part

If multiple injuries affect the same area, they're merged into a natural description:

```
Single injury:
  "A bandaged cut marks your left arm"

Multiple injuries on same area:
  "Your left arm is a mess — a deep stab wound (badly bleeding despite the 
  bandage) and heavy bruising from a fall above the elbow. You can barely move it."
```

---

## 6. Clothing & Armor Rendering

### 6.1 Armor Rendering

Each equipped armor piece is described in the appropriate layer:

**Head armor:**
> *"An iron helmet covers your head, dented on the left side"*

**Torso armor:**
> *"You wear full plate armor over a thick leather tunic"*

**Arm armor (gloves):**
> *"Steel-reinforced leather gloves cover your hands"*

**Leg armor:**
> *"Iron leg armor protects your shins"*

**Full armor combination:**
> *"You appear formidable in full plate armor — a helmet with a gorget, breastplate, 
> pauldrons, and leg greaves. The metal is dented and scraped from use, but still 
> protective."*

### 6.2 Clothing Rendering

Clothing beneath armor is visible if armor is partially damaged or if no armor covers it:

**With armor covering:**
> *"You wear a leather jerkin beneath your breastplate (not visible)"*

**Without armor:**
> *"You wear a simple white linen shirt, now stained with blood"*

**Mixed (some armor, some clothing):**
> *"You wear leather armor on your torso, but your legs are bare except for bruises"*

### 6.3 Blood Stains on Clothing/Armor

Blood state is incorporated into the appearance:

**Fresh blood (active bleeding):**
> *"Your armor is splattered with fresh blood, dripping from the seams"*

**Dried blood (old injury):**
> *"Dried blood stains the left pauldron, dark rust-colored against the iron"*

**Multiple stains (multiple injuries):**
> *"Your armor is a record of violence — fresh blood on the left side, dried stains 
> on the right, and more on the gauntlets"*

---

## 7. Held Items in Appearance

### 7.1 Item Rendering in Hands

Held items appear in the arms/hands layer:

**Single hand occupied:**
> *"You're holding a sword in your right hand, point down"*

**Both hands occupied:**
> *"You're carrying a torch in your left hand and a dagger in your right"*

**Prominent items:**
> *"A heavy bag is slung over your shoulder, hanging at your left side"*

### 7.2 Item Interaction with Injuries

If an item is held in an injured hand, this creates tension in the description:

**Holding sword with injured arm:**
> *"You're gripping a sword in your right hand despite the swollen bruising up your arm. Your knuckles are white from the strain."*

**Injured hand but still holding:**
> *"Your left arm is badly wounded and heavily bandaged, but you're still gripping your bow with white knuckles"*

---

## 8. Health-Based Overall Descriptors

### 8.1 Health Tiers → Narrative Descriptors

Health is not shown as a number. Instead, the overall layer includes health-based descriptors:

| Health Range | Descriptor | Phrasing |
|-------------|-----------|----------|
| 90-100% | Robust | *"You look healthy and strong, ready for anything."* |
| 70-89% | Healthy | *"You're in good condition, with no signs of serious injury."* |
| 50-69% | Worn | *"You look like you've been through something, but you're managing."* |
| 30-49% | Badly Hurt | *"You're clearly wounded and struggling. Every movement costs effort."* |
| 10-29% | Critical | *"You're pale and trembling. You look like you might collapse at any moment."* |
| 1-9% | Dying | *"You're barely conscious. Your vision swims. How much longer can you hold on?"* |

### 8.2 Appearance Changes Per Tier

**Healthy (90-100%):**
> *"Your skin is clear, your eyes bright. You're breathing normally."*

**Worn (70-89%):**
> *"You show signs of exertion — your breathing is a bit heavy, there's a sheen 
> of sweat on your brow — but you're managing."*

**Badly Hurt (30-49%):**
> *"Your skin has taken on a grayish tint. Dark circles mark your eyes. You're 
> breathing quickly and your hands tremble slightly."*

**Dying (1-9%):**
> *"You look like a ghost of yourself. Your skin is paper-white. Your eyes are 
> unfocused. Every breath is an effort. You're not going to last much longer."*

---

## 9. Smart Composition: Natural English

### 9.1 Connectives & Flow

The subsystem uses natural connectives to flow from layer to layer:

```
HEAD:   "An iron helmet covers your head..."
        ↓ [connective]
TORSO:  "...and below it, your torso is protected by plate armor..."
        ↓ [connective]
ARMS:   "...though your left arm, visible between the armor gaps, is heavily 
        bandaged and swollen..."
        ↓ [connective]
LEGS:   "...while your legs bear bruises from impacts the armor didn't cover..."
        ↓ [connective]
OVERALL: "...and taking it all together, you look like a soldier who's barely 
         survived a war."
```

### 9.2 Avoiding Redundancy

The subsystem tracks what's been said and avoids repeating information:

```
GOOD (not redundant):
  "You're wearing armor. Your left arm is exposed and heavily bruised."

BAD (redundant):
  "You're wearing armor. Your armor covers your chest. Your left arm is not 
   covered by armor. Your left arm has a bruise."
```

### 9.3 Varying Phrasing

The subsystem uses template variations to keep prose fresh:

**Same scenario, different phrasings:**

Version 1: *"Your reflection shows a battered figure in iron plate armor..."*
Version 2: *"Looking in the mirror, you see yourself in plate armor, battered..."*
Version 3: *"The mirror reflects someone in iron plate armor, looking battered..."*

---

## 10. Special Cases

### 10.1 Unconscious Player

If the player is unconscious, the appearance call returns an error:

```lua
function appearance.describe(player)
  if player.consciousness == "unconscious" or player.consciousness == "waking" then
    return "You can't examine yourself — you're unconscious."
  end
  -- ... continue with normal appearance composition
end
```

### 10.2 Darkness Adjustment

In darkness, the appearance is dimmed and more vague:

```lua
function appearance.describe_in_darkness(player)
  -- Same composition, but with hedged descriptions
  -- "In the dim light, you can barely make out..."
  -- "You feel more than see..."
end
```

### 10.3 Bare/Nothing

If the player has no items, no armor, and no injuries, the appearance is simple:

```
> examine mirror
"Your reflection shows a simple sight: a human figure in plain clothes, 
unharmed and unburdened. Nothing remarkable."
```

---

## 11. Multiplayer Hook (Design, Not Implementation)

For future multiplayer, the same subsystem handles `look at <player>`:

```lua
-- Current (single-player): Mirror uses own state
appearance.describe(player, nil)  -- nil = self-reflection

-- Future (multiplayer): Look at another player
local target_player = find_player_by_name("Alice")
appearance.describe(target_player, "third_person")  -- third_person = "Alice is..."
```

The logic is identical — only the input player state changes and the narrative voice shifts to third person ("You are..." → "She is...").

---

## 12. Testing Criteria (Nelson)

- [x] Appearance for fresh, uninjured, unarmored player
- [x] Appearance with single bleeding wound (unbandaged)
- [x] Appearance with bleeding wound + bandage
- [x] Appearance with multiple injuries (different body parts)
- [x] Appearance with armor (helmet, chest, full plate)
- [x] Appearance with held items (sword, torch, multiple items)
- [x] Appearance combines armor + injuries naturally
- [x] Appearance reflects low health with pale/gaunt descriptors
- [x] Health tiers produce appropriate descriptors (healthy vs. dying)
- [x] Appearance avoids redundancy
- [x] Appearance uses natural connectives and varied phrasing
- [x] Appearance rejects unconscious player ("You can't examine yourself...")
- [x] Appearance works in darkness (dimmed/vague variant)
- [x] No nil layers produce empty gaps
- [x] Phrasing is natural prose, not robotic lists

---

## 13. Narrative Examples for QA

**Fresh player (no items, no injuries, no armor):**
> Your reflection shows a simple sight: a healthy person in plain clothes, 
> unharmed and unburdened.

**After getting injured and treated:**
> Your reflection shows someone who's been through something. A bandage wraps 
> around your left arm, stained rust-colored with dried blood. Your face is still 
> pale, but your breathing has steadied. You look like you've survived.

**Armored and injured:**
> You appear formidable in iron plate armor, though the left side is dented and 
> scraped. Beneath the damaged armor, you can see the edge of a bloodied bandage — 
> a deep wound that nearly got through your protection. Your face is pale beneath 
> your helmet, but your jaw is set. You look determined.

**Multiple injuries, low health:**
> Your reflection is disturbing. Your skin has taken on a gray-white pallor. Dark 
> circles mark your eyes. A stab wound on your left arm (heavily bandaged but still 
> weeping), another on your ribs (also bandaged), and deep bruising on your right 
> leg from a fall. You're holding yourself upright with obvious effort. You look 
> like you're dying.

**Dying:**
> You look like a ghost. Your skin is paper-white, almost translucent. Your eyes 
> are unfocused and glazed. You're barely standing — every breath is an agony. The 
> wounds covering your body are a record of a battle you're losing. How much longer 
> can you possibly hold on?

---

## 14. Implementation Notes for Smithers

1. **Location:** `src/engine/player/appearance.lua`
2. **Main function:** `appearance.describe(player_state, narrative_mode)`
   - `narrative_mode = "first_person"` → "You are..."
   - `narrative_mode = "third_person"` → "They are..." (future)
3. **Layer functions:** Each has its own renderer
   - `render_head(player)`, `render_torso(player)`, etc.
   - Each returns string or `nil`
4. **Injury composition:** 
   - Iterate over `player.injuries`
   - Group by body location
   - Compose phrase for each group
5. **Health descriptors:** Map `current_health / max_health` to tier, then to descriptor
6. **Connectives:** Templates for joining layers naturally ("...and...", "...though...", etc.)
7. **Redundancy check:** Track what's been mentioned, don't repeat
8. **Integration point:** Called from mirror object `on_examine` hook
9. **Error handling:** Return appropriate message if player is unconscious

---

## 15. See Also

- `docs/design/objects/mirror.md` — Mirror object that displays appearance
- `docs/design/injuries/unconsciousness.md` — Unconsciousness mechanics
- `docs/design/player/health-system.md` — Overall health and injury model
- `docs/design/wearable-system.md` — Armor and clothing system
- `docs/verbs/examine.md` — Examine verb reference
