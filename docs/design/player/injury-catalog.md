# Injury Catalog — Gameplay Design

**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-07-23  
**Revised:** 2026-07-24 (Wayne directive 2026-03-21T19:17Z — injury-specific cures, treatment-matching puzzle)  
**Status:** DESIGN  
**Depends On:** Health System (health-system.md), FSM Engine  
**Audience:** Designers, Bart (engine), Flanders (objects), Nelson (testing)

---

## 1. Injury Architecture

### 1.1 What Is an Injury?

An injury is a **stateful condition attached to the player** — like a status effect with its own lifecycle. Each injury:
- Has an **FSM** (finite state machine) with defined states and transitions
- Produces **narrative symptoms** (text the player sees via the `injuries` verb)
- May have **mechanical effects** (blocks actions, worsens over time)
- Requires a **SPECIFIC treatment** — not a generic cure, but a particular item or action
- Can **worsen** if untreated (degenerative injuries)
- Includes **discovery clues** — how the player figures out what treats it

### 1.2 The Cure Relationship — The Core Puzzle

**Every injury has a SPECIFIC cure.** This is the central puzzle design surface:

- A bandage stops *bleeding* but does nothing for *poison*
- A generic antidote cures *mild food poisoning* but not *viper venom*
- A nightshade antidote cures *nightshade poisoning* specifically — not all poisons
- Cold water soothes a *burn* but doesn't stop *bleeding*
- Rest heals *bruises* but won't cure *infection*

The player must **examine their injury** (via the `injuries` verb), **read the clues** embedded in the description, and **match the correct treatment**. Wrong treatment wastes the item. This matching is what makes healing a puzzle, not a menu.

### 1.3 Injury Categories

| Category | Duration | Worsens? | Example |
|----------|----------|----------|---------|
| **One-Time** | Heals naturally or with treatment | No | Cut, bruise, burn |
| **Over-Time** | Worsens each turn until treated or fatal | Some | Bleeding, mild poison |
| **Degenerative** | Escalates through stages | Yes | Infection, deep venom |

### 1.4 Injury FSM Pattern

Every injury follows a standard FSM structure:

```
            [inflicted]
                │
                ▼
          ┌──────────┐
          │  ACTIVE   │◄──── injury starts here
          │           │      symptoms visible via `injuries` verb
          │  (ticking)│      mechanical effects active
          └─────┬─────┘
                │ SPECIFIC treatment applied
                ▼
          ┌──────────┐
          │ TREATED   │      symptoms reduced
          │           │      worsening stops
          │           │      healing countdown begins
          └─────┬─────┘
                │ countdown expires
                ▼
          ┌──────────┐
          │  HEALED   │      injury removed from player
          │           │      no further effects
          └──────────┘
```

**Degenerative injuries** add a worsening path:

```
          ┌──────────┐
          │  ACTIVE   │──── untreated for N turns ────┐
          └─────┬─────┘                                │
                │ treatment                            ▼
                ▼                               ┌──────────┐
          ┌──────────┐                          │ WORSENED  │
          │ TREATED   │                          │ (stage 2) │
          └─────┬─────┘                          └─────┬─────┘
                │                                      │ untreated
                ▼                                      ▼
          ┌──────────┐                          ┌──────────┐
          │  HEALED   │                          │ CRITICAL  │
          └──────────┘                          │ (stage 3) │
                                                └─────┬─────┘
                                                      │ untreated
                                                      ▼
                                                   DEATH
```

---

## 2. Level 1 Injury Catalog

These injuries are relevant to Level 1 objects and puzzles. Each entry defines the injury, its SPECIFIC cure, and how the player discovers the treatment.

---

### 2.1 MINOR CUT

| Field | Value |
|-------|-------|
| **ID** | `minor-cut` |
| **Category** | One-Time |
| **Causes** | Glass shard (handle), pin prick, minor trap |
| **Body Location** | Hand (usually) |
| **Mechanical Effect** | None |
| **Cured By** | Heals naturally (5 turns), or `bandage` (cloth strip) to speed recovery |
| **Status** | 🔴 Planned (extends existing `bleed_ticks`) |

**FSM:**
```
active ──(5 turns)──► healed
active ──(bandage)──► treated ──(2 turns)──► healed
```

**Player Sees (`injuries` verb):**
| State | Symptom Text |
|-------|-------------|
| Active | *"A small cut on your [hand] where the glass caught you. It stings, but the bleeding has mostly stopped on its own."* |
| Active (reminder) | *"The cut on your [hand] is still tender."* |
| Treated | *"The bandage on your [hand] is snug. The sting is fading."* |
| Healed | *"The cut on your hand has closed. Barely a mark remains."* |

**Discovery Clues:** The injury description mentions "small" and "stings" — this signals it's minor. The player learns that minor cuts heal on their own. Bandaging speeds it up but isn't critical.

**Puzzle Use:** Glass shard hurts to pick up barehanded. Wrapping it in cloth first prevents the injury — teaches "prepare your tools."

---

### 2.2 DEEP CUT (Slash)

| Field | Value |
|-------|-------|
| **ID** | `deep-cut` |
| **Category** | Over-Time (bleeding) |
| **Causes** | Knife attack, blade trap, falling onto sharp object |
| **Body Location** | Arm, torso, leg |
| **Mechanical Effect** | Affected limb impaired. Bleeding creates time pressure. |
| **Cured By** | **Step 1:** `bandage` (cloth strip) → stops bleeding. **Step 2:** Rest or medicine → wound heals. |
| **Wrong Treatments** | Antidote does nothing. Salve does nothing. Only pressure/cloth stops this bleeding. |
| **Status** | 🔴 Planned |

**FSM:**
```
active ──(bleeding each turn)──► [death if injuries overwhelm]
active ──(bandage/cloth/pressure)──► bandaged ──(no drain)──► [still injured]
bandaged ──(rest, 10 turns)──► healed
active ──(untreated 15 turns)──► infected (see: INFECTION)
```

**Player Sees (`injuries` verb):**
| State | Symptom Text |
|-------|-------------|
| Active | *"A deep gash in your [arm] (bleeding). Blood flows freely. It won't stop on its own — you need something wrapped tight around it."* |
| Active (worsening) | *"Blood drips steadily from the gash. Your sleeve is soaked crimson. This is getting worse."* |
| Bandaged | *"The bandage around your [arm] is holding, but the wound beneath is serious. You need rest."* |
| Bandaged (reminder) | *"Your bandaged [arm] aches deeply. Movement is difficult."* |
| Healed | *"The wound on your [arm] has closed, leaving an angry red scar."* |

**Discovery Clues:** 
- `injuries` says: "It won't stop on its own — you need something wrapped tight around it." → Suggests cloth/bandage
- If player tries drinking a potion: "The warmth feels good but the gash in your arm still bleeds. This needs something physical, not something you drink."

**Puzzle Use:**
- **Time pressure:** Bleeding creates urgency. Must find cloth → tear → bandage before worsening.
- **Action gate:** Deep cut on arm → cannot climb or lift heavy objects until bandaged.
- **Resource tension:** Using the blanket for a bandage means it can't be used for a rope later.

---

### 2.3 BRUISE

| Field | Value |
|-------|-------|
| **ID** | `bruise` |
| **Category** | One-Time |
| **Causes** | Fall, blunt impact, heavy object dropped on player |
| **Body Location** | Legs (falls), torso (impacts), head (blows) |
| **Mechanical Effect** | Legs bruised → climbing/running impaired. Head bruised → examine descriptions degraded. |
| **Cured By** | **Rest** (sit down, sleep). Time heals bruises — no item required. |
| **Wrong Treatments** | Bandage does nothing (not bleeding). Antidote does nothing (not poison). |
| **Status** | 🔴 Planned |

**FSM:**
```
active ──(8 turns)──► healed
active ──(rest/sleep)──► recovering ──(4 turns)──► healed
```

**Player Sees (`injuries` verb):**
| State | Symptom Text |
|-------|-------------|
| Active | *"Badly bruised [legs] from the fall. Your ankles and knees throb. Moving is painful. This will heal with rest — time and staying off your feet."* |
| Active (action blocked) | *"You try to climb, but your bruised legs buckle. Not yet."* |
| Recovering | *"The bruising is fading. Your [legs] still protest sharp movements, but you can manage."* |
| Healed | *"The soreness in your [legs] has finally passed."* |

**Discovery Clues:** The `injuries` description says: "This will heal with rest — time and staying off your feet." The clue is in the description itself. No medicine needed.

**Puzzle Use:** 
- Puzzle 013 (Courtyard Entry): Window jump causes bruised legs → can't climb ivy until rested → must find ground-level route or wait
- Teaches: rest has value. Stopping to recover is a strategic choice, not wasted time.

---

### 2.4 BLEEDING

| Field | Value |
|-------|-------|
| **ID** | `bleeding` |
| **Category** | Over-Time |
| **Causes** | Accompanies deep cuts, glass shard wounds, weapon injuries |
| **Body Location** | Same as causing wound |
| **Mechanical Effect** | Leaves blood trail. Hands slippery (drop chance on handled objects). |
| **Cured By** | `bandage` (cloth strip, cobweb for minor). Pressure applied to wound. |
| **Wrong Treatments** | Antidote does nothing. Potion doesn't stop the bleeding (body still deteriorates). Salve doesn't stop bleeding. |
| **Status** | 🟡 Prototype exists (`bleed_ticks` in engine) |

**FSM:**
```
active ──(worsening each turn)──► [death if injuries overwhelm]
active ──(bandage/cloth/pressure)──► stopped
stopped ──(wound heals)──► [removed]
```

**Player Sees (`injuries` verb):**
| State | Symptom Text |
|-------|-------------|
| Active (minor) | *"Blood seeps from the wound, a slow but steady trickle. Something to stop the flow — cloth, pressure."* |
| Active (major) | *"Blood pours from the gash. Your sleeve is soaked crimson. You're getting lightheaded. This needs binding — now."* |
| Active (hands) | *"Blood makes your grip slippery. Objects feel uncertain in your hands."* |
| Stopped | *"The bleeding has stopped. The bandage holds."* |

**Discovery Clues:** Every bleeding description mentions pressure, cloth, binding, or wrapping — physical clues pointing to bandage.

**Puzzle Use:**
- **The classic time puzzle:** Player is bleeding → bandage exists 2 rooms away → every command matters
- **Resource discovery:** Blanket → tear → cloth → bandage. Player must figure this out under pressure.
- **Slippery hands:** Bleeding hands make object manipulation unreliable. Creates urgency to treat.

---

### 2.5 POISONING (Mild — Food/Generic)

| Field | Value |
|-------|-------|
| **ID** | `poisoning-mild` |
| **Category** | Over-Time |
| **Causes** | Spoiled food, weak generic venom, tainted drink |
| **Body Location** | Systemic (whole body) |
| **Mechanical Effect** | Nausea → intermittent action interruption. Smell/taste senses degraded. |
| **Cured By** | **Generic antidote** (cures food poisoning / mild toxins). Also: **vomit/purge** (drink salt water) — violent but effective. |
| **Wrong Treatments** | Bandage does nothing. Viper antivenom is too specific (overkill, still works but wasteful). Rest alone won't cure it. |
| **Status** | 🔴 Planned |

**FSM:**
```
active ──(worsening each turn)──► [death if injuries overwhelm]
active ──(generic antidote)──► neutralized ──(3 turns)──► healed
active ──(vomit/purge)──► weakened ──(5 turns)──► healed
```

**Player Sees (`injuries` verb):**
| State | Symptom Text |
|-------|-------------|
| Active | *"Your stomach churns violently. Something you consumed is poisoning you. The burning is from the inside — you need to neutralize it or get it out of your system."* |
| Active (worsening) | *"A wave of nausea hits. The poison burns through your veins. Everything tastes like copper."* |
| Neutralized | *"The antidote works quickly. The burning fades. You feel weak but alive."* |
| Weakened (post-purge) | *"You retch violently. The poison leaves your system the hard way. You feel hollowed out."* |
| Healed | *"The last of the poison has left your body. You won't forget that taste."* |

**Discovery Clues:**
- `injuries` says: "you need to neutralize it or get it out of your system" → antidote or purge
- SMELL on antidote bottle: "Sharp and herbal. Medicinal." → Suggests this is a cure
- TASTE (carefully!): Examining the cause of poisoning can hint at generic vs. specific

**Puzzle Use:**
- **Antidote fetch puzzle:** Poisoned by dart trap → must find antidote within time limit
- **Purge alternative:** No antidote? Induce vomiting (salt water, etc.) — saves life but weakens you more
- **Contrast with venom:** Mild poison responds to GENERIC antidote. Viper venom does NOT. Player learns specificity matters.

---

### 2.6 VIPER VENOM POISONING

| Field | Value |
|-------|-------|
| **ID** | `poisoning-viper` |
| **Category** | Over-Time (specific venom) |
| **Causes** | Viper bite (snake encounter in cellar, garden, outdoor areas) |
| **Body Location** | Bite site (ankle, hand) + spreading |
| **Mechanical Effect** | Spreading numbness from bite site. Affected limb becomes useless. |
| **Cured By** | **Viper antivenom** ONLY. Not the generic antidote. Not any other medicine. |
| **Wrong Treatments** | Generic antidote does nothing (consumed and wasted). Bandage doesn't help. Salve doesn't help. Purging doesn't help — the venom is in the blood, not the stomach. |
| **Status** | 🔴 Planned (Level 2+) |

**FSM:**
```
active ──(spreading each turn)──► [death if injuries overwhelm]
active ──(viper antivenom)──► neutralized ──(5 turns)──► healed
```

**Player Sees (`injuries` verb):**
| State | Symptom Text |
|-------|-------------|
| Active | *"Two puncture marks on your [ankle]. The skin around them is turning dark, and a burning numbness is spreading up your calf. This is venom — a specific kind. You need a cure made for THIS bite."* |
| Active (worsening) | *"The numbness has reached your knee. Your foot is dead weight. The venom is winning."* |
| Neutralized | *"The burning recedes. Feeling slowly returns to your leg. The antivenom is working."* |
| Healed | *"The bite marks have scabbed over. The numbness is gone. You were lucky."* |

**Discovery Clues:**
- `injuries` says: "a specific kind... a cure made for THIS bite" → not just any antidote
- EXAMINE the bite: "The fang marks are narrow and close together — a viper's signature."
- READ a herbal medicine book (if found): Describes viper antivenom recipe or location
- NPC healer might identify: "That's viper venom. You need the antivenom from the apothecary's kit."

**Puzzle Use:**
- **The core matching puzzle:** Generic antidote FAILS. Player must find the specific antivenom. The puzzle is identification + location.
- **Time pressure:** Venom spreads faster than mild poison. Urgency is higher.
- **Red herring:** Finding the generic antidote first and wasting it teaches the lesson: read the clues, match the cure.

---

### 2.7 NIGHTSHADE POISONING

| Field | Value |
|-------|-------|
| **ID** | `poisoning-nightshade` |
| **Category** | Over-Time (specific botanical poison) |
| **Causes** | Eating nightshade berries, drinking tainted wine, consuming nightshade-laced food |
| **Body Location** | Systemic — affects vision and heart |
| **Mechanical Effect** | Dilated pupils → vision blurred (examine descriptions degraded). Heart racing → intermittent dizziness. |
| **Cured By** | **Nightshade antidote** ONLY. A specific herbal preparation. |
| **Wrong Treatments** | Generic antidote does nothing. Viper antivenom does nothing. Purging helps only slightly (slows but doesn't stop). |
| **Status** | 🔴 Planned (Level 2+) |

**FSM:**
```
active ──(worsening each turn)──► [death if injuries overwhelm]
active ──(nightshade antidote)──► neutralized ──(4 turns)──► healed
active ──(purge/vomit)──► slowed ──(still worsening, but slower)──► [death if untreated]
```

**Player Sees (`injuries` verb):**
| State | Symptom Text |
|-------|-------------|
| Active | *"Your pupils are huge — the room seems painfully bright. Your heart races. You recognize these symptoms: nightshade. You need the specific antidote, not just any remedy."* |
| Active (worsening) | *"The room pulses with your heartbeat. Shadows crawl at the edges. The nightshade is tightening its grip."* |
| Neutralized | *"The racing in your chest slows. Your pupils contract. The world stops pulsing. The antidote worked."* |

**Discovery Clues:**
- `injuries` names the poison: "nightshade" — the player knows WHAT they need to cure
- EXAMINE berries (if that's the cause): "Small, dark, and deceptively sweet. Nightshade." — identification after the fact
- Herbal medicine book describes nightshade antidote ingredients
- The clue "not just any remedy" signals: generic antidote won't work

**Puzzle Use:**
- **Identification puzzle:** Player must recognize nightshade symptoms → know they need the NIGHTSHADE antidote
- **Crafting opportunity:** Nightshade antidote might be craftable from specific herbs (belladonna counter-herb + water + preparation)
- **Knowledge gate:** Player who read the herbalism book knows the cure. Player who didn't must experiment or find a prepared antidote.

---

### 2.8 BURN

| Field | Value |
|-------|-------|
| **ID** | `burn` |
| **Category** | One-Time |
| **Causes** | Touching lit candle, hot surface, fire trap |
| **Body Location** | Hand (touching hot object), face/body (fire trap) |
| **Mechanical Effect** | Burned hand → reduced grip. Burned face → vision impaired. |
| **Cured By** | **Cold water** (immediate relief) or **salve** (medicinal treatment). |
| **Wrong Treatments** | Bandage doesn't help burns. Antidote doesn't help. Rest alone is very slow. |
| **Status** | 🔴 Planned |

**FSM:**
```
active ──(cold water/salve)──► treated ──(5 turns)──► healed
active ──(10 turns)──► healed (slow natural healing)
active (severe) ──(untreated 8 turns)──► blistered ──(salve required)──► treated ──► healed
```

**Player Sees (`injuries` verb):**
| State | Symptom Text |
|-------|-------------|
| Active (minor) | *"Your fingertips are red and tender where you touched the flame. Cool water would soothe this."* |
| Active (severe) | *"The burn on your [hand] is angry and raw. Even the air hurts. You need something cooling — water or a medicinal salve."* |
| Treated | *"The cool salve soothes the burn. The throbbing eases."* |
| Blistered | *"The burn has blistered. Fluid-filled welts cover your [hand]. Don't touch anything. This needs real medicine — a salve."* |
| Healed | *"The burn has faded to a patch of shiny pink skin."* |

**Discovery Clues:**
- `injuries` says "cool water would soothe this" → water is the treatment
- For severe burns: "a medicinal salve" → salve is required
- Player near water source (rain barrel, well) should connect: water + burn = relief

**Puzzle Use:** 
- Lit candle teaches: use the holder, not the flame directly
- Fire trap: protective glove or wet cloth reduces burn severity — preparation puzzle

---

## 3. Future Injury Types (Level 2+)

### 3.1 INFECTION

| Field | Value |
|-------|-------|
| **ID** | `infection` |
| **Category** | Degenerative |
| **Causes** | Untreated cut/slash wound after 15+ turns |
| **Cured By** | **Stage 1:** Clean wound (water + cloth). **Stage 2:** Herb poultice (herbs + cloth + water). **Stage 3:** NPC healer only. |
| **Wrong Treatments** | Antidote does nothing (it's not poison). Bandage alone is insufficient (wound must be CLEANED). |
| **Mechanical Effect** | Fever → intermittent confusion. Stage 3 → bedridden. |
| **Status** | 🔴 Planned (Level 2) |

**FSM:**
```
stage_1 ──(clean wound: water + cloth)──► treated ──(8 turns)──► healed
stage_1 ──(untreated 10 turns)──► stage_2
stage_2 ──(herb poultice)──► treated ──(12 turns)──► healed
stage_2 ──(untreated 10 turns)──► stage_3
stage_3 ──(NPC healer)──► treated ──(20 turns)──► healed
stage_3 ──(untreated 15 turns)──► DEATH
```

**Discovery Clues:** 
- Stage 1: "The wound is warm to the touch and swollen. That's not a good sign. It needs cleaning — water and a fresh cloth." → water + cloth
- Stage 2: "Fever grips you. Red streaks crawl up your arm. You need real medicine — an herbal preparation." → herb poultice
- Stage 3: "You can barely stand. Without a healer, this will kill you." → find NPC

**Puzzle Use:** Multi-stage time puzzle where each stage requires a DIFFERENT treatment. Finding water is easy. Finding herbs is a fetch puzzle. Finding a healer is a navigation/relationship challenge.

### 3.2 BROKEN BONE

| Field | Value |
|-------|-------|
| **ID** | `broken-bone` |
| **Category** | One-Time (with long recovery) |
| **Causes** | Severe fall, heavy object, combat |
| **Cured By** | **Splint** (wood + cloth binding). NPC healer for faster recovery. |
| **Wrong Treatments** | Bandage alone insufficient (needs rigid support). Potion doesn't set bones. |
| **Mechanical Effect** | Broken arm → cannot carry objects, cannot climb. Broken leg → movement slowed. |
| **Status** | 🔴 Planned (Level 2+) |

**Discovery Clues:** "The bone is... wrong. It needs to be set — something rigid alongside it, bound tight." → wood + cloth = splint

### 3.3 HYPOTHERMIA

| Field | Value |
|-------|-------|
| **ID** | `hypothermia` |
| **Category** | Over-Time (environmental) |
| **Causes** | Extended cold exposure without cloak/fire |
| **Cured By** | **Warmth source** — fire, cloak, shelter, hot drink. |
| **Wrong Treatments** | Bandage, antidote, salve — all useless against cold. |
| **Mechanical Effect** | Shivering → reduced dexterity. Stage 2 → confusion. |
| **Status** | 🔴 Planned (Level 2+) |

**Discovery Clues:** "You're shivering uncontrollably. You need warmth — a fire, a cloak, shelter from the wind." → explicit warmth-seeking

**Puzzle Use:** The wool cloak — seemingly useless flavor item in Level 1 — retroactively proves its value in cold areas.

### 3.4 EXHAUSTION

| Field | Value |
|-------|-------|
| **ID** | `exhaustion` |
| **Category** | Degenerative (slow build) |
| **Causes** | Extended activity without rest, multiple injuries |
| **Cured By** | **Sleep** (full rest). **Food + drink** (partial relief). |
| **Wrong Treatments** | Medicine, bandage, antidote — none address exhaustion. Only rest and sustenance help. |
| **Mechanical Effect** | Stage 1: yawning. Stage 2: actions slower. Stage 3: collapse (forced rest). |
| **Status** | 🔴 Planned (Level 3+) |

---

## 4. Injury Interaction Rules

### 4.1 Stacking

Multiple injuries can be active simultaneously. Each has independent FSM, timers, and treatment requirements.

**Example compound state (via `injuries` verb):**
```
> injuries
"You examine yourself:
 — A deep cut on your arm (bandaged). The cloth is holding. Needs time.
 — Bruised ribs from the fall. Every breath aches. Rest will help.
 — Your stomach churns with poison. The burning hasn't stopped.
   You need to neutralize it — an antidote, something medicinal.
   
 The bandage is handling the cut, but the poison is the urgent problem.
 The bruised ribs will have to wait."
```

**Note:** The `injuries` verb helps the player prioritize. The narrative hints at urgency: "the poison is the urgent problem."

### 4.2 Injury Cascading

Some injuries trigger other injuries if untreated:

| If This... | And This... | Then... |
|------------|-------------|---------|
| Deep cut is untreated | 15+ turns pass | → INFECTION begins |
| Burn is untreated (severe) | 8+ turns pass | → BLISTERED (worse burn state) |
| Multiple bleeding wounds | Simultaneous | → Bleeding effects compound |

### 4.3 Treatment Priority

When the player has multiple injuries, the `injuries` verb narrative *guides* them toward the most urgent one:

> *"Your arm is bleeding and your ribs ache, but it's the poison in your blood that's the real danger. Treat that first."*

The game doesn't enforce treatment order — the player chooses — but the narrative provides guidance.

---

## 5. Injury × Puzzle Design Patterns

### Pattern 1: The Ticking Clock
**Setup:** Player receives an over-time injury (bleeding, poison).  
**Puzzle:** Find the SPECIFIC treatment before the injury overwhelms.  
**Tension:** Every command matters. Wrong treatment wastes time AND resources.  
**Example:** Viper bite → generic antidote fails → must find viper antivenom in locked medical kit.

### Pattern 2: The Capability Gate
**Setup:** Injury blocks a specific action.  
**Puzzle:** Find alternate solution or find the specific cure.  
**Example:** Bruised legs → can't climb → must rest (specific cure) or find stairs.

### Pattern 3: The Risky Shortcut
**Setup:** An action causes a specific injury but provides a benefit.  
**Puzzle:** Is the shortcut worth acquiring an injury that needs specific treatment?  
**Example:** Jump from window (bruised legs, needs rest) vs. find key (safe but slower).

### Pattern 4: The Prepared Adventurer
**Setup:** Environmental clues telegraph a coming hazard.  
**Puzzle:** Find the specific cure BEFORE encountering the hazard.  
**Example:** "A cold draft" + finding wool cloak → prepared for hypothermia.

### Pattern 5: The Diagnosis Puzzle
**Setup:** Injury symptoms don't immediately reveal the cause.  
**Puzzle:** Investigate symptoms → identify the specific injury → find the specific cure.  
**Example:** NPC is sick. Symptoms could be food poisoning OR nightshade. SMELL their breath → "A faint sweetness" → nightshade → need nightshade antidote, not generic.

### Pattern 6: The Nested Container Emergency
**Setup:** The correct healing item exists but is inside a locked container, inside a bag.  
**Puzzle:** Navigate the container hierarchy under injury time-pressure.  
**Example:** Antivenom is in the locked medical kit → kit is in the satchel → key is in the NPC's pocket → negotiate/search while the venom spreads.

---

## 6. Implementation Priority

| Priority | Injury | Why First | Specific Cure |
|----------|--------|-----------|---------------|
| **P1** | Minor Cut, Bleeding | Extends existing `bleed_ticks`. Minimal new engine work. | Bandage (cloth strip) |
| **P1** | Bruise | Window jump (Puzzle 013) needs this. | Rest |
| **P2** | Deep Cut | Weapon traps need a survivable wound type. | Bandage + rest |
| **P2** | Mild Poison | Dart traps, tainted food — Level 1 content. | Generic antidote or purge |
| **P3** | Burn | Candle interaction. Existing objects cause this. | Cold water or salve |
| **P3** | Viper Venom | Core matching puzzle demonstration. | Viper antivenom (specific) |
| **P3** | Nightshade Poisoning | Core matching puzzle demonstration. | Nightshade antidote (specific) |
| **P4** | Infection | Requires multi-stage FSM. Level 2 content. | Water+cloth → poultice → healer |
| **P4** | Broken Bone | Requires body-part action gating. Level 2 content. | Splint (wood + cloth) |
| **P5** | Hypothermia, Exhaustion | Environmental systems. Level 3+ content. | Warmth / rest+food |

---

## See Also

- [health-system.md](./health-system.md) — Derived health model and the `injuries` verb
- [healing-items.md](./healing-items.md) — Treatment objects and exactly which injuries they cure
- [README.md](./README.md) — System overview
- `docs/design/fsm-object-lifecycle.md` — FSM patterns (injuries follow same architecture)
- `docs/design/player-skills.md` §8 — Blood writing (existing prick → bleed chain)
