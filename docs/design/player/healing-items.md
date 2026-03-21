# Healing Items — Gameplay Design

**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-07-23  
**Status:** DESIGN  
**Depends On:** Health System (health-system.md), Injury Catalog (injury-catalog.md)  
**Audience:** Designers, Flanders (objects), Bart (engine)

---

## 1. Healing Philosophy

Healing in this game is **specific, physical, and interactive**. There is no generic "heal" command. Every healing action uses a real object, applied through a verb the player already knows, targeting a specific injury or health need. The player must *understand* their condition and *choose* the right treatment.

### Core Rules

1. **No healing spells.** This is a material world. Healing comes from objects you find, craft, or buy.
2. **No universal cures.** A bandage stops bleeding but doesn't cure poison. An antidote cures poison but doesn't heal a cut. Matching treatment to injury is the puzzle.
3. **Healing items are consumed.** Bandages are used. Potions are drunk. Medicine is applied. Resources are finite.
4. **Treatment and healing are separate.** Stopping the bleeding (bandage) is not the same as restoring lost HP (potion/rest). The player may need both.
5. **Objects declare their healing properties.** No engine special-casing. A bandage's metadata says `stops_bleeding = true`. The engine reads it.

---

## 2. Healing Item Categories

| Category | What It Does | HP Effect | Injury Effect | Example |
|----------|-------------|-----------|---------------|---------|
| **Wound Dressing** | Stops bleeding, protects wound | None directly | Transitions bleeding → stopped | Bandage, cloth strip, cobweb |
| **Restorative** | Restores HP directly | +N HP (varies) | None | Healing potion, food, water, wine |
| **Medicine** | Cures a specific injury type | Indirect (stops drain) | Transitions injury → treated | Antidote, salve, herb poultice |
| **Rest** | Passive healing over time | +HP/turn while resting | Accelerates injury recovery | Sleep, sit by fire |

---

## 3. Wound Dressings

### 3.1 BANDAGE (Cloth Strip)

| Field | Value |
|-------|-------|
| **ID** | `bandage` |
| **Crafted From** | Tear cloth from blanket, curtains, cloak, or sack |
| **Verb** | `bandage [body part]`, `apply bandage`, `wrap wound` |
| **Effect** | Stops bleeding on target wound. Transitions bleeding → stopped. |
| **HP Restored** | 0 (stops drain, does not restore) |
| **Uses** | 1 (consumed on application) |
| **Status** | 🟡 Object exists in design (`docs/design` mentions bandage from cloth), not yet implemented as healing item |

**How It Plays:**

```
> tear cloth from blanket
"You rip a long strip of wool from the blanket. It's rough but serviceable."

> bandage hand
"You wrap the cloth strip tightly around your wounded hand.
 The bleeding slows... and stops. The bandage holds."
 
[Injury: BLEEDING → STOPPED]
[HP drain: 3/turn → 0/turn]
[Bandage consumed]
```

**Design Details:**
- A bandage does **not** restore HP. It only stops HP drain. The player must still recover the lost health through rest or a restorative.
- Bandages work on **any bleeding wound** regardless of cause. They're the universal wound dressing.
- The cloth strip is the same object used for sewing, cleaning, and other crafting. Using it as a bandage consumes it — resource tension.
- Multiple wounds need multiple bandages. One strip per wound.

**Puzzle Opportunities:**
- Player is bleeding → must figure out that the blanket can be torn → cloth works as bandage. Discovery + crafting under time pressure.
- Only one cloth strip available → two bleeding wounds → which one to bandage? (The more severe one, obviously — but the player must assess.)
- NPC is bleeding → player applies bandage to NPC → relationship/quest advancement.

### 3.2 COBWEB (Natural Dressing)

| Field | Value |
|-------|-------|
| **ID** | `cobweb` |
| **Found In** | Cellar corners, crypt passages, abandoned rooms |
| **Verb** | `apply cobweb to wound`, `press cobweb on cut` |
| **Effect** | Stops minor bleeding only (2 HP/turn or less). Ineffective on major wounds. |
| **HP Restored** | 0 |
| **Uses** | 1 |
| **Status** | 🔴 Planned (Level 2) |

**Design Details:**
- A "realistic" healing item — cobwebs have been used as wound dressing historically.
- Less effective than cloth bandage (minor wounds only), but freely available in cellar environments.
- Teaches the player: "The environment has resources if you think creatively."

---

## 4. Restoratives

### 4.1 HEALING POTION

| Field | Value |
|-------|-------|
| **ID** | `healing-potion` |
| **Found In** | Alchemy lab, merchant, hidden cache |
| **Verb** | `drink potion`, `quaff potion` |
| **Effect** | Restores HP instantly. Does NOT cure injuries. |
| **HP Restored** | 30 HP |
| **Uses** | 1 (bottle becomes empty) |
| **Status** | 🔴 Planned (Level 2+) |

**How It Plays:**

```
> drink healing potion
"You uncork the small blue bottle and drink. The liquid is warm
 and faintly sweet. Strength floods back into your limbs."
 
[HP: 42 → 72]
[Potion consumed. Empty bottle remains.]
[Injuries: unchanged — the potion heals flesh, not conditions.]
```

**Design Details:**
- Healing potions restore HP but do **not** cure injuries. A bleeding player who drinks a potion gains HP but continues bleeding. They need a bandage AND a potion for full recovery.
- The empty bottle remains as an object (consistent with composite object patterns). Empty bottles have puzzle uses: fill with water, use as container, throw as distraction.
- Healing potions are **rare**. They're a strategic resource, not a convenience item. Level 1 has zero potions — they appear in Level 2+.
- Potions are colored/labeled to distinguish them from poison. The player should be able to SMELL and EXAMINE a potion to determine safety. Blue/sweet = healing. Green/acrid = danger.

**Puzzle Opportunities:**
- The "fake potion" trap: A bottle that looks like a healing potion but is actually poison. SMELL reveals the difference — "This smells acrid and chemical, nothing like the sweet healing potions you've seen."
- Potion as bribe/trade item for NPCs.
- Using a potion before a known dangerous encounter (forewarning → preparation).

### 4.2 FOOD (Generic Restorative)

| Field | Value |
|-------|-------|
| **ID** | varies (`bread`, `dried-fruit`, `cheese`, `cooked-meat`) |
| **Found In** | Kitchen, storage cellar, merchant, NPC gift |
| **Verb** | `eat [food]` |
| **Effect** | Restores small amount of HP. Some food cures mild conditions. |
| **HP Restored** | 5–15 HP (varies by food type) |
| **Uses** | 1 (consumed) |
| **Status** | 🔴 Planned (Level 2+) |

**Food Table:**

| Food | HP Restored | Special Effect | Found In |
|------|-------------|---------------|----------|
| Stale bread | 5 HP | None | Storage cellar, prison cells |
| Dried fruit | 8 HP | None | Merchant, traveler's pack |
| Cheese wedge | 10 HP | None | Kitchen, cellar |
| Cooked meat | 15 HP | Clears exhaustion (Stage 1) | Kitchen, campfire |
| Spoiled food | 0 HP | Causes mild poisoning! | Abandoned kitchens |

**Design Details:**
- Food is the **slow, common** restorative. Small HP gains, widely available, but requires finding and eating.
- Spoiled food is a trap that teaches "examine before eating" — the same lesson as the poison bottle but survivable.
- Eating takes 1 turn (like any action). In a time-pressure scenario, spending a turn eating is a strategic choice.
- Food objects follow existing FSM patterns: fresh → stale → spoiled (time-based transitions, like candle burn-down).

### 4.3 WATER

| Field | Value |
|-------|-------|
| **ID** | `water` (in container: bucket, flask, cupped hands) |
| **Found In** | Well, rain barrel, stream, flask |
| **Verb** | `drink water`, `drink from [container]` |
| **Effect** | Minor HP restore. Can clean wounds. |
| **HP Restored** | 5 HP |
| **Special** | `cleans_wound = true` — transitions infection Stage 1 → treated |
| **Status** | 🔴 Planned |

**Design Details:**
- Water is both a restorative (drink for HP) and a medical supply (clean wounds to prevent infection).
- Available from rain barrel (Puzzle 013 courtyard) and well bucket. Both are Level 1 objects.
- Water in cupped hands has a short duration — must be used quickly or it drips away. Water in a flask/bucket persists.
- Dirty water (stagnant pool) is harmful — drinking it causes mild poisoning. Clean water (rain, well, stream) is safe.

### 4.4 WINE

| Field | Value |
|-------|-------|
| **ID** | `wine` (from wine-bottle) |
| **Found In** | Storage cellar wine rack (Level 1, Puzzle 016) |
| **Verb** | `drink wine`, `drink from bottle` |
| **Effect** | Minor HP restore. Mild "warmth" effect (cold resistance for 5 turns). |
| **HP Restored** | 5 HP |
| **Special** | `cold_resistance = 5` (turns of warmth) |
| **Status** | 🟡 Wine bottle exists; DRINK transition planned (Puzzle 016) |

**Design Details:**
- Wine is the safe counterpart to the poison bottle. Puzzle 016 establishes that DRINK ≠ death.
- The warmth effect is a hint toward future cold-resistance mechanics. Drinking wine before going outside in winter helps.
- Excessive drinking (3+ bottles?) could cause "intoxicated" status: vision blurs, movement erratic. Comedy and consequence.

---

## 5. Medicines

### 5.1 ANTIDOTE

| Field | Value |
|-------|-------|
| **ID** | `antidote` |
| **Found In** | Alchemy lab, healer's kit, herb garden |
| **Verb** | `drink antidote`, `take antidote` |
| **Effect** | Cures mild poisoning. Transitions poison → neutralized. |
| **HP Restored** | 0 (stops poison drain) |
| **Uses** | 1 |
| **Status** | 🔴 Planned (Level 2+) |

**How It Plays:**

```
> drink antidote
"The bitter liquid burns going down — but differently from the poison.
 Your stomach settles. The nausea recedes. The burning fades."
 
[Injury: POISONING → NEUTRALIZED]
[HP drain: 5/turn → 0]
[Antidote consumed]
```

**Design Details:**
- Antidotes are **specific** to poison type in later levels. Early game: one generic antidote. Late game: must match antidote to poison (identify via SMELL/TASTE clues).
- Antidote does not restore HP — it stops the drain. Player needs a restorative to recover lost HP.
- Drinking antidote when not poisoned: "The liquid is unpleasantly bitter but doesn't seem to do anything. Wasted."

### 5.2 SALVE (Burn Treatment)

| Field | Value |
|-------|-------|
| **ID** | `salve` |
| **Found In** | Healer's kit, alchemy crafting |
| **Verb** | `apply salve to burn`, `rub salve on [body part]` |
| **Effect** | Treats burns. Transitions burn → treated. Soothes pain. |
| **HP Restored** | 5 HP (minor soothing effect) |
| **Uses** | 3 (jar with multiple applications) |
| **Status** | 🔴 Planned (Level 2+) |

### 5.3 HERB POULTICE (Infection Treatment)

| Field | Value |
|-------|-------|
| **ID** | `herb-poultice` |
| **Crafted From** | Medicinal herbs + cloth + water (crafting recipe) |
| **Verb** | `apply poultice to wound` |
| **Effect** | Treats infection (Stage 1–2). Transitions infected → treated. |
| **HP Restored** | 0 |
| **Uses** | 1 |
| **Status** | 🔴 Planned (Level 2+) |

**Puzzle Opportunities:**
- The poultice is a **crafting puzzle**: player must find herbs (herb garden), cloth (tear from fabric), and water (well/rain barrel), combine them, then apply. A 4-step healing chain.
- Knowledge gate: How does the player know the recipe? Find an herbalism book, or an NPC teaches them (parallels sewing manual → sewing skill).

---

## 6. Rest as Healing

### 6.1 SLEEP

| Condition | Effect |
|-----------|--------|
| Healthy, no injuries | No HP change (already full) |
| Minor injuries (Tier 4) | +10 HP per sleep hour. Injuries heal 2× faster while sleeping. |
| Wounded (Tier 3) | +5 HP per sleep hour. Injuries heal at normal rate. |
| Critical (Tier 2) | Cannot sleep — "The pain won't let you rest." |
| Near-Death (Tier 1) | Cannot sleep — "You can't sleep. You're not sure you'd wake up." |
| Bleeding (untreated) | **Dangerous.** Bleeding continues during sleep. Player may die in their sleep. |
| Poisoned | **Dangerous.** Poison ticks during sleep. |

**Design Details:**
- Sleep is the free-but-slow healing path. No items consumed, but time passes (game clock advances).
- Sleeping while injured but treated is safe and efficient. Sleeping while untreated is risky.
- The bed (Level 1) is the first rest location. Future: campfire, inn, safe room.
- Sleep requires a "safe" location. Can't sleep in a room with active threats (future: hostile NPCs).

### 6.2 REST (Sitting/Leaning)

| Condition | Effect |
|-----------|--------|
| Any health tier | +2 HP per rest turn. No injury acceleration. |
| Duration | 1 turn per `rest` command. Player chooses when to stop. |

**Design Details:**
- Resting is a lighter version of sleep. Sit against a wall, lean on a barrel, pause and catch your breath.
- Costs turns (time-pressure tradeoff) but no special requirements.
- Doesn't require a bed or safe location.

---

## 7. Healing Object Metadata Pattern

All healing objects declare their properties in standard metadata. The engine reads these — no special-casing.

```lua
-- Bandage object metadata
{
  id = "bandage",
  name = "cloth bandage",
  keywords = {"bandage", "cloth strip", "dressing"},
  type_id = "medical-supply",
  
  healing = {
    type = "wound_dressing",
    stops_bleeding = true,
    applies_to = {"cut", "deep-cut", "slash"},  -- injury types
    verb = "bandage",              -- what verb triggers it
    target = "injury",             -- applies to player injury
    consumed = true,               -- used up on application
    message = "You wrap the bandage tightly. The bleeding stops.",
    fail_message = "You don't have a wound that needs bandaging."
  },
  
  -- Standard object properties
  portable = true,
  size = 1,
  weight = 0.1,
  hands_required = 1,
  description = "A strip of rough cloth, suitable for binding wounds.",
  on_feel = "Soft, slightly scratchy wool fabric.",
  on_smell = "Faintly of wool and lanolin."
}
```

```lua
-- Healing potion metadata
{
  id = "healing-potion",
  name = "blue potion",
  keywords = {"potion", "blue bottle", "healing potion", "elixir"},
  
  healing = {
    type = "restorative",
    hp_restore = 30,
    verb = "drink",
    consumed = true,
    becomes = "empty-potion-bottle",  -- FSM transition
    message = "Warmth floods through you. You feel stronger.",
    fail_message = "You're already at full health."
  },
  
  -- Sensory properties for identification
  on_smell = "Sweet, with a hint of lavender and something metallic.",
  on_taste = "Warm and faintly sweet. It tingles on your tongue.",
  on_look = "A small glass bottle filled with luminous blue liquid. A cork stopper seals it.",
  on_feel = "Cool glass. The liquid inside sloshes gently."
}
```

```lua
-- Antidote metadata
{
  id = "antidote",
  name = "antidote vial",
  keywords = {"antidote", "vial", "cure", "remedy"},
  
  healing = {
    type = "medicine",
    cures_injury = "poisoning-mild",  -- specific injury type
    verb = "drink",
    consumed = true,
    becomes = "empty-vial",
    message = "The bitter liquid fights the poison. Your stomach settles.",
    fail_message = "You don't appear to be poisoned."
  },
  
  on_smell = "Sharp and herbal. Medicinal.",
  on_taste = "Intensely bitter, but you feel it working."
}
```

---

## 8. Design Guidelines for Future Healing Items

### 8.1 The Healing Spectrum

When designing new healing items, place them on this spectrum:

```
Common ◄──────────────────────────────────► Rare
Weak                                        Powerful
  │                                            │
  water     food     bandage    salve    potion    miracle cure
  (5 HP)   (5-15)   (stops     (burns)  (30 HP)   (full heal
                      bleed)                        + all injuries)
```

**Rule of thumb:** Common items heal small amounts or treat common injuries. Rare items heal large amounts or cure serious conditions. No item should be both common AND powerful.

### 8.2 Treatment Specificity Scale

| Specificity | Example | Design Use |
|-------------|---------|------------|
| Universal | Rest/sleep (heals any HP) | Always available fallback |
| Broad | Bandage (stops any bleeding) | Common treatment for common injuries |
| Targeted | Antidote (cures poison only) | Requires correct diagnosis |
| Precise | Nightshade antidote (cures one specific poison) | Late-game challenge |

**Design rule:** Increase specificity as the game progresses. Level 1: bandages and rest. Level 3: specific antidotes for specific poisons.

### 8.3 Balancing Healing Items

| Question | Guideline |
|----------|-----------|
| How much HP should it restore? | Scale to the expected damage in that level. If enemies deal 20 HP, potions should restore 25–30 HP. |
| How many should exist per level? | Enough to survive if careful, not enough to ignore danger. ~2–3 restoratives per level. |
| Should GOAP auto-use them? | **No.** Healing is always player-initiated. GOAP can help *find* a healing item (open medical kit → take bandage) but never auto-applies treatment. |
| Can healing items be combined? | Yes — bandage + herb = poultice (crafting). Water + cloth = clean dressing. Combinations should feel logical. |
| Can healing items be misused? | Yes — drinking antidote when not poisoned wastes it. Applying bandage to un-bleeding wound does nothing. Using healing potion at full HP is wasteful. |

### 8.4 Narrative Rules for Healing

1. **Healing text should be sensory.** The player feels the potion's warmth, smells the herbs, feels the bandage tighten. Not just "You heal 30 HP."
2. **Pain reduction is noticeable.** When an injury is treated, the next few commands should reference the *absence* of pain: "For the first time in a while, your arm doesn't ache."
3. **Healing takes a beat.** Don't rush past it. The moment of treatment is a relief — let the player feel it.
4. **Failed healing gets a message.** If the player tries to bandage when not bleeding: "You wrap the cloth around your arm, but there's nothing to treat. The bandage is wasted." (Or: "You don't seem to need a bandage right now." — gentler, doesn't consume.)

### 8.5 Anti-Patterns (Don't Do This)

| Anti-Pattern | Why It's Bad | Do This Instead |
|-------------|-------------|-----------------|
| Healing fountain that fully restores | Removes all tension from nearby encounters | Fountain heals 20 HP, once per day |
| Infinite-use medical kit | Makes injuries meaningless | Kit has 3 bandages, 1 salve, 1 antidote |
| Auto-healing when entering safe room | Player never engages with the system | Player must explicitly rest/sleep/treat |
| Healing item that cures everything | No diagnosis puzzle | Each medicine cures one condition |
| HP regen over time (passive) | Player just waits | Only regen during rest (active choice) |

---

## 9. Level 1 Healing Inventory

What healing resources exist (or should exist) in Level 1?

| Resource | Location | How Obtained | Heals |
|----------|----------|-------------|-------|
| **Blanket** (tear for cloth) | Bedroom, on bed | `tear blanket` → cloth strip | Cloth → bandage (stops bleeding) |
| **Wool cloak** (tear for cloth) | Wardrobe | `tear cloak` → cloth strip | Cloth → bandage (but destroys cloak) |
| **Curtains** (tear for cloth) | Bedroom window | `tear curtains` → cloth strip | Cloth → bandage (but loses daylight control) |
| **Wine** | Storage cellar, wine rack | `drink wine` (Puzzle 016) | 5 HP, minor warmth |
| **Water** (rain barrel) | Courtyard | `drink from barrel`, `fill flask` | 5 HP, cleans wounds |
| **Rest** (bed) | Bedroom | `sleep`, `rest on bed` | HP regen over time |
| **Rest** (any surface) | Anywhere | `rest`, `sit down` | +2 HP/turn (slow) |

**Design Note:** Level 1 has **no potions, no medicine, no antidote**. Healing in Level 1 is primitive — cloth bandages, wine, water, rest. This teaches the fundamentals (injury + treatment = survival) before introducing powerful healing items in Level 2.

**Resource tension:** The blanket, cloak, and curtains are all usable for other purposes (warmth, rope-making, daylight control). Tearing them for bandages is a trade-off. This is good design — every resource decision matters.

---

## 10. Healing × Puzzle Integration

### Integration 1: The Bleeding Clock
**Puzzle:** Player is cut by a trap → bleeding 3 HP/turn → must find cloth + tear it + bandage within ~15 turns.  
**Healing items used:** Cloth strip (torn from blanket/cloak), applied as bandage.  
**Why it works:** Time pressure from bleeding drives the puzzle. Treatment is the goal, not a side activity.

### Integration 2: The Poison Antidote Fetch
**Puzzle:** Player is poisoned by dart trap → must find antidote in a locked cabinet → 20 turns of poison remaining.  
**Healing items used:** Antidote vial.  
**Why it works:** The antidote is the "key" that solves the puzzle. Finding it requires exploration under pressure.

### Integration 3: The Injury-Gated Path
**Puzzle:** Player needs full health to survive a challenge (squeeze through narrow gap, withstand a cold blast).  
**Healing items used:** Whatever brings them to full HP — potion, food, rest.  
**Why it works:** Healing items become keys. "Full health" is the requirement; the puzzle is gathering enough healing.

### Integration 4: The Prepared Explorer
**Puzzle:** A room ahead is known to be dangerous (environmental descriptions hint at it). Healing items found beforehand are preparation.  
**Healing items used:** Pre-collected bandages, potions carried in inventory.  
**Why it works:** Rewards planning and resource management. The player who explored thoroughly is ready.

### Integration 5: The NPC Healer
**Puzzle:** An injured NPC blocks a door. Healing the NPC opens the path.  
**Healing items used:** Bandage applied to NPC, potion given to NPC.  
**Why it works:** Extends healing from self-care to world interaction. Healing items become social tools.

---

## See Also

- [health-system.md](./health-system.md) — Health scale, damage model, death design
- [injury-catalog.md](./injury-catalog.md) — Injury types that these items treat
- [README.md](./README.md) — System overview
- `docs/design/composite-objects.md` — Object FSM patterns (healing potions follow same lifecycle)
- `docs/design/tool-objects.md` — Tool resolution system (healing items use same dispatch)
