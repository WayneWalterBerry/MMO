# Player Health System — Gameplay Design

**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-07-23  
**Revised:** 2026-07-25 (Wayne directive 2026-03-21T20:05Z — explicit injury accumulation, targeted treatment)  
**Status:** DESIGN  
**Depends On:** FSM Engine, Verb Handlers, Game Loop tick system  
**Audience:** Designers, Bart (engine), Flanders (objects)

---

## 1. The Core Principle: Health Is Derived from Injuries

**There is no HP bar. There is no health number displayed to the player.**

The player's health is the *aggregate of their active injuries*. A healthy player is one with no injuries. A dying player is a collection of untreated wounds, each worsening independently. The player never sees "HP: 42/100" — they see:

> *"You examine yourself: a deep gash on your forearm (bleeding), a dull ache in your ribs (bruised). Your vision swims when you stand too quickly."*

Health is **felt through injuries, not through a number**.

### 1.1 How Health "Works" Without a Visible Number

Internally, the engine may compute a derived health value from the aggregate of injuries for mechanical purposes (action gating, death threshold). But the player **never sees this number**. What they see is narrative text that describes their *injuries* and how those injuries make them *feel*.

The design surface is the injuries themselves and the narrative voice they produce — not health tiers or HP ranges.

### 1.2 Injury Severity Levels

Instead of HP-based tiers, the player's condition is described by the aggregate severity of their active injuries:

| Severity | What the Player Has | Narrative Feel |
|----------|-------------------|----------------|
| **Uninjured** | No active injuries | Silence. The body is invisible. Player focuses on the world. |
| **Scratched** | One or two minor injuries (small cut, scrape) | Occasional pain reminders. Body nags but doesn't dominate. |
| **Hurt** | Multiple minor injuries, or one serious injury | Persistent pain. Physical actions include pain notes. Room descriptions gain a somatic overlay. |
| **Badly Wounded** | Serious injuries compounding — bleeding, poison, deep cuts | Body dominates every interaction. Sensory descriptions filtered through pain and disorientation. |
| **Dying** | Untreated critical injuries, aggregate damage overwhelming | Fragmentary, desperate prose. Ellipses and incomplete sentences. Every command is agony. |

The transitions between these levels happen organically as injuries accumulate, worsen, or are treated. There are no hard HP thresholds — the narrative voice shifts based on *what injuries the player has* and *how severe each one is*.

### 1.3 Injury Accumulation — Multiple Injuries Stack

**Injuries are accumulative.** Each active injury contributes its own damage independently. Two stab wounds drain twice as fast as one. A bleeding arm and a bleeding leg together are twice as dangerous as either alone.

**The math (internal, never shown to player):**

```
derived_health = max_health - sum(all_active_injury_damage)

Example — Player with max_health 100:
  Stab wound on left arm:  drains 2 health/turn
  Stab wound on right leg: drains 2 health/turn
  Minor cut on hand:       one-time -3 (already applied)
  Bruised ribs:            one-time -5 (already applied)

  Turn 1: 100 - 3 - 5 = 92 (one-time hits applied)
  Turn 2: 92 - 2 - 2 = 88  (both stab wounds drain)
  Turn 3: 88 - 2 - 2 = 84
  Turn 4: 84 - 2 - 2 = 80
  ...
  Total drain per turn: 4 health/turn (2 from each bleeding wound)
```

**What the player experiences (not numbers — narrative):**

```
> injuries
"You examine yourself:
 — A deep stab wound on your left arm (bleeding). Blood flows
   steadily. Something tight around this — now.
 — A second wound on your right leg (bleeding). More blood.
   The floor beneath you is pooling red.
 — A small cut on your hand (healing on its own).
 — Bruised ribs from the fall. They ache, but it's the blood
   that's killing you.
 
 Two wounds are bleeding. You're losing blood fast — faster than
 one wound alone. You need bandages. Plural."
```

**Accumulation creates exponential urgency.** One bleeding wound is survivable for many turns. Two bleeding wounds halve that survival time. Three would be critical. The narrative voice communicates this through escalating desperation without ever showing numbers.

**Key design implications:**
- **Triage matters.** With two bleeding wounds and one bandage, which wound gets treated first? The player must assess via `injuries` and choose.
- **Healing order is strategic.** Treat the fastest-draining injury first to maximize survival time. Or treat the one blocking a critical action.
- **Same injury type stacks.** Two minor cuts are tracked independently. Two burns on different body parts each hurt separately. The player can't "batch heal" — each injury needs its own treatment instance.

---

## 2. The `injuries` Verb — How the Player Reads Their Body

The `injuries` verb is the health system's primary interface. It is to the body what `inventory` is to possessions: the player examining what they're carrying — in this case, wounds.

### 2.1 Design Philosophy

The `injuries` verb returns a **first-person physical assessment**. The player is examining their own body, noting each wound, describing its current state, and (critically) noticing clues about what might treat it.

This is NOT a clinical readout. It's a person looking at themselves and describing what they see and feel.

### 2.2 Example Output by Severity

**Uninjured:**
```
> injuries
"You examine yourself. No injuries. You feel strong and alert."
```

**Scratched (one minor injury):**
```
> injuries
"You examine yourself:
 — A small cut on your hand where the glass caught you. It stings,
   but the bleeding has mostly stopped on its own."
```

**Hurt (multiple injuries):**
```
> injuries
"You examine yourself:
 — A deep gash on your forearm (bleeding). Blood seeps steadily.
   It won't stop without pressure — something wrapped tight.
 — A dull ache in your ribs (bruised). Breathing hurts.
   Time will take care of this one.
 
 You feel lightheaded. You need to stop the bleeding soon."
```

**Badly Wounded (serious, compounding):**
```
> injuries
"You examine yourself:
 — A deep slash across your side (bleeding heavily). Your shirt
   is soaked through. You can feel your strength draining.
 — Your stomach churns with nausea (poisoned — something you ate).
   The burning hasn't stopped since the spoiled meat.
 — Bruised ribs from the fall. The least of your worries.
 
 You are in serious trouble. The bleeding and the poison are
 both killing you, and they need different treatments."
```

**Dying (critical, overwhelming):**
```
> injuries
"You... examine yourself. It's hard to focus.
 — The wound in your side... so much blood...
 — Everything tastes like copper. The poison...
 — Your ribs... doesn't matter anymore.
 
 You need help. Now. Or this is where it ends."
```

### 2.3 Embedded Discovery Clues

The `injuries` verb output includes *subtle clues* about treatment. This is the puzzle interface — the player reads their injuries and gets hints:

| Injury Description | Embedded Clue |
|-------------------|---------------|
| *"Blood seeps steadily. It won't stop without pressure — something wrapped tight."* | → Bandage / cloth strip needed |
| *"Your stomach churns. Something you consumed is still burning."* | → Antidote or purge needed |
| *"The burn is angry and raw. Even the air hurts."* | → Salve or cold water needed |
| *"The wound is warm to the touch and swollen. That's not a good sign."* | → Clean the wound (water + cloth) |
| *"Two puncture marks on your ankle. The skin around them is turning dark."* | → Viper antidote specifically (not generic) |

The clues never say "use item X." They describe the injury in terms that *suggest* a treatment. The player must make the connection. **That connection is the puzzle.**

### 2.4 `injuries` vs. Other Health Verbs

| Verb | What It Does |
|------|-------------|
| `injuries` | Full assessment — lists all active injuries with descriptions and severity. The primary health verb. |
| `examine [body part]` | Zooms in on a specific injury. More detail than the `injuries` summary. May reveal additional clues. |
| `examine self` | Equivalent to `injuries`. |

---

## 3. Narrative Voice by Injury Severity

The health system's primary output is **text tied to specific injuries**. Messages fire contextually — on room entry, on action, on idle tick. These are *guidelines for writers*; actual text lives in engine metadata.

### Uninjured
No health messages. The body is invisible. The player focuses entirely on the world.

### Scratched (Minor Injuries Only)
Intermittent reminders tied to the *specific injury*, not generic pain.

> *"Your cut hand throbs dully."*  
> *"You wince as you reach for the door handle — the scrape on your palm catches."*  
> *"A twinge of pain reminds you of the cut on your hand."*

**Frequency:** Every 3–5 commands. Always references the actual injury by name and location.

### Hurt (Serious Injuries Present)
Pain is persistent. Every physical action includes a pain note from the relevant injury. Room descriptions gain a somatic overlay.

> *"Your wounded arm protests as you lift the crate."*  
> *"Blood seeps through the makeshift bandage. You need to treat this properly."*  
> *"Each step sends a jolt through your injured leg."*  
> *"You lean against the wall, breathing hard. The gash in your side throbs."*

**Frequency:** Every 1–2 commands. Physical actions always mention the relevant injury.

**Room Description Modifier:**
> **Normal:** *"A cold cellar stretches before you. Barrels line the walls."*  
> **Hurt:** *"A cold cellar stretches before you. Barrels line the walls. You steady yourself against the door frame, your wounded side aching in the chill."*

### Badly Wounded (Multiple Serious Injuries)
The player's body dominates every interaction. Sensory descriptions are filtered through pain and disorientation.

> *"Your vision blurs. You stumble. You need to treat these wounds."*  
> *"The room swims before your eyes. Each breath is a conscious effort."*  
> *"Your hands shake. Picking up the key takes three attempts."*  
> *"A wave of nausea forces you to pause. The darkness at the edge of your sight is not just the unlit room."*

**Frequency:** Every command. Physical actions may fail or require extra description.

**Sensory Degradation:**
> **LOOK (normal):** *"An ornate brass key lies on the stone shelf."*  
> **LOOK (badly wounded):** *"Something metallic glints on the shelf. Your vision is too blurred to make out details."*  
>
> **FEEL (normal):** *"The stone wall is cool and smooth."*  
> **FEEL (badly wounded):** *"The wall is cold. Your fingers feel numb and clumsy."*

### Dying (Aggregate Injuries Fatal)
Fragmentary, desperate prose. The player is dying. Every message reinforces urgency.

> *"The edges of your vision darken. Each step is agony."*  
> *"You collapse against the wall. Getting up takes everything you have."*  
> *"Your heartbeat pounds in your ears, drowning out everything else."*  
> *"The cold stone floor presses against your cheek. When did you fall?"*  
> *"...you can barely... the room is... so cold..."*

**Frequency:** Every command. Descriptions are shorter, more fragmented. Ellipses and incomplete sentences.

### Dead
A dramatic, final passage. Then game over.

> *"Your legs give way. The cold stone rushes up to meet you."*  
> *"The last thing you hear is the drip of water somewhere in the darkness."*  
> *"Silence. Stillness. The adventure ends here."*

---

## 4. Damage Sources — What Causes Injuries

Injuries come from **objects and environmental effects**, never from abstract mechanics. Every injury has a *cause* the player can understand and (usually) avoid.

| Category | Source | Injury Created | Example |
|----------|--------|---------------|---------|
| **Self-Injury** | Prick self (pin/needle) | Minor cut (finger) | Blood writing mechanic (existing) |
| **Self-Injury** | Cut self (knife/glass shard) | Deep cut + bleeding | Blood writing mechanic (existing) |
| **Weapon** | Knife slash (combat or trap) | Deep slash + heavy bleeding | NPC attack, trapped chest |
| **Environmental** | Fall (short) | Bruised legs / bruised ribs | Jumping from window (Puzzle 013) |
| **Environmental** | Fall (long) | Instant death | Falling into pit without rope |
| **Poison** | Poison ingestion (lethal) | Instant death | Poison bottle (existing, Puzzle 002) |
| **Poison** | Mild poison / tainted food | Mild poisoning (nausea, over-time) | Spoiled food, weak venom |
| **Poison** | Viper bite | Viper venom poisoning (specific) | Snake encounter |
| **Poison** | Nightshade consumption | Nightshade poisoning (specific) | Tainted drink, deceptive berry |
| **Trap** | Dart trap | Puncture wound + specific poison | Trapped chest or passage |
| **Over-Time** | Untreated cut (15+ turns) | Infection (degenerative) | Cut that wasn't cleaned |
| **Thermal** | Touching flame / hot surface | Burn | Lit candle, fire trap |
| **Environmental** | Extreme cold | Hypothermia (over-time) | Outdoors in winter without cloak |

### Instant Death vs. Injury

Some hazards bypass the injury system entirely. This is a *design choice*:

| Hazard | Effect | Rationale |
|--------|--------|-----------|
| **Poison bottle** | Instant death | Teaches "investigate before consuming." |
| **Long fall** | Instant death | Realism serves the fiction. |
| **Trapped chest** (dart) | Injury (treatable) | Survivable but creates treatment puzzle. |
| **Bleeding out** | Death over time | Treatable if the player acts. Creates puzzle urgency. |

**Design Rule:** Instant death should always be *player-initiated* or *clearly telegraphed*. Surprise instant death is cruel and unfun.

---

## 5. Death & Game Over Design

### 5.1 When Death Occurs

Death happens when the aggregate of untreated injuries overwhelms the body. There is no single "HP = 0" moment the player sees. Instead, the narrative escalates through the severity levels until the injuries become fatal.

From the player's perspective: they see their injuries worsening, the prose growing more desperate, and then — death.

### 5.2 The Death Sequence

```
1. Injuries accumulate beyond survivable threshold
2. Death narrative plays (cause-specific text based on worst injury)
3. Brief pause (dramatic beat)
4. "YOU HAVE DIED."
5. Cause of death: "The bleeding wouldn't stop. The gash in your side 
   needed a bandage — tight cloth wrapped around the wound."
6. Game over. (Future: checkpoint restart)
```

Note: the cause-of-death text includes a **treatment hint** — what SPECIFIC treatment might have saved them. This teaches the matching puzzle for next time.

### 5.3 Cause-Specific Death Text

**Bleeding Out:**
> *"The blood won't stop. You press your hand against the wound, but your fingers are too cold, too weak. The cellar floor is warm where you lie — or maybe that's just the last of your warmth leaving."*  
> Hint: *"A strip of cloth, wrapped tight, might have stopped the bleeding."*

**Poison (mild — treatable but untreated):**
> *"The poison finishes its work. The burning in your veins becomes ice. Your last thought is that somewhere in this place, there was a cure — if only you'd found it in time."*  
> Hint: *"An antidote for [specific poison] existed somewhere nearby."*

**Poison (lethal — instant):**
> *"Your body crumples to the cold stone floor. The poison works swiftly — a fire in your veins, then ice, then nothing. Your last thought is of the skull etched on the bottle's label."*  
*(This text already exists in the engine.)*

**Fall:**
> *"The ground rushes up. There is a terrible, brief moment of understanding — and then silence."*

**Cold/Exposure:**
> *"The shivering stopped some time ago. That should worry you, but you can't quite remember why. The snow is so soft. Just rest for a moment..."*

**Infection:**
> *"The fever took you in the night. Your wound, untreated for too long, brought a sickness that no amount of willpower could fight."*  
> Hint: *"Clean water on the wound, earlier, might have prevented the infection."*

### 5.4 Recovery Mechanics (Future)

For V1, death is final (restart the game). **Recommendation:** Start with permadeath — it matches the current engine and creates maximum tension. Implement checkpoints in V2 when save/load exists.

---

## 6. Damage Scenarios from Level 1

These scenarios demonstrate how injury-derived health interacts with existing Level 1 content. Note: **no HP numbers are shown to the player** in any scenario.

### Scenario 1: The Blood Writing Chain

**Current behavior:** `prick self with pin` → `bleed_ticks = 8` → blood available for writing  
**With injury system:**

```
> prick self with pin
"You press the pin into your fingertip. A bead of dark blood wells up."
(Injury added: pinprick, finger — minor, heals naturally)

> injuries
"You examine yourself:
 — A tiny puncture on your fingertip. It stings but it's nothing serious."

> [8 turns later — injury heals naturally]
"The bleeding has stopped. The tiny wound is already closing."
```

**Puzzle implication:** Blood writing now creates a real (if minor) injury. Pricking yourself many times accumulates minor injuries that shift the narrative tone. The player must weigh "do I need to write this?"

### Scenario 2: The Knife as Hazard

```
> cut self with knife
"You draw the blade across your palm. Blood flows freely.
 The cut is deep. Blood drips steadily from your hand."
(Injuries added: deep cut, hand + bleeding)

> injuries
"You examine yourself:
 — A deep cut across your palm (bleeding). Blood seeps steadily.
   It won't stop without pressure — something wrapped tight."

> tear cloth from blanket
"You rip a strip of cloth from the wool blanket."

> bandage hand with cloth
"You wrap the cloth tightly around your palm. The bleeding slows
 and stops. The makeshift bandage holds." 
(Injury: bleeding → stopped. Deep cut → bandaged.)

> injuries
"You examine yourself:
 — A bandaged cut on your palm. The cloth is holding. The sting
   is fading, but the wound needs time."
```

**Puzzle implication:** The blanket — previously a flavor object — becomes a medical resource. The `injuries` verb told the player what was wrong ("bleeding... something wrapped tight") and the player figured out cloth → bandage.

### Scenario 3: Poison Bottle — Preserved Instant Death

```
> taste poison bottle
"BITTER! The liquid burns your tongue, your throat, your stomach.
 Your body crumples to the cold stone floor."
 
YOU HAVE DIED.
Cause: Lethal poison ingestion.
Perhaps the skull on the label was a warning.
```

### Scenario 4: Window Jump → Bruised Legs → Treatment Puzzle

```
> jump from window
"You haul yourself onto the ledge and leap. The ground is further
 than it looked. You hit the cobblestones hard, pain exploding
 through your ankles and knees."
(Injury added: bruised legs)

> injuries
"You examine yourself:
 — Badly bruised legs from the fall. Your ankles and knees throb.
   Moving is painful. This will heal with rest — time and staying 
   off your feet."

> [In courtyard, trying to climb ivy]
"You reach for the ivy, but your bruised legs buckle under you.
 You can't climb — not like this."

> rest
"You sit against the wall, letting the pain subside.
 After a while, the throbbing eases." 
(Bruised legs: active → recovering. Climbing re-enabled after rest.)
```

### Scenario 5: The Matching Puzzle — Viper Bite

This scenario demonstrates the CORE puzzle mechanic: injury-specific treatment.

```
> [Player bitten by viper in cellar passage]
"Sharp pain lances through your ankle! A snake — quick and dark —
 slithers away into the shadows. Two puncture marks well with blood."
(Injury added: viper venom poisoning)

> injuries
"You examine yourself:
 — Two puncture marks on your ankle. The skin around them is turning
   dark, and a burning numbness is spreading up your calf. This is
   venom — a specific kind. You need a cure made for this bite, not
   just any antidote."

> [Player finds a generic antidote]
> drink antidote
"You drink the antidote. It's bitter and medicinal — but the burning
 in your leg doesn't change. This antidote wasn't made for viper venom."
(Antidote consumed. Injury unchanged. Resource wasted.)

> [Player finds viper antivenom in locked medical kit]
> drink viper antivenom
"You drink the dark liquid. It tastes of iron and herbs.
 Within moments, the burning numbness in your leg begins to recede.
 The venom is neutralizing. You'll live."
(Injury: viper venom → neutralized → will heal over time)
```

**THIS is the puzzle.** The generic antidote failed. The player had to find the *specific* cure. The `injuries` verb hinted at it: "a specific kind... a cure made for this bite."

### Scenario 6: Nested Inventory Under Pressure

```
> [Player is poisoned and knows antivenom is in a medical kit]
> open satchel
"You open the leather satchel. Inside: a locked medical kit, a candle stub,
 some twine."

> open medical kit
"The medical kit is locked. A small brass keyhole stares back at you."

> injuries
"You examine yourself:
 — The venom is spreading. Your foot is numb now. The burning reaches
   your knee. You are running out of time."

> [Player must find the key to the medical kit, which is inside 
   the satchel's inner pocket...]
```

**Puzzle implication:** Nested containers create layers of access under time pressure. The healing item exists — but reaching it IS the puzzle.

---

## 7. Interaction with Game Time

### 7.1 Injury Ticking

Over-time injuries (bleeding, poison, infection) worsen per game tick. The engine already has `tick_timers()` in the game loop — injury ticks plug into the same mechanism.

**Current:** Each command = 1 tick = 360 game seconds  
**With injuries:** Each tick processes the player's injury list, advancing over-time injuries and checking for cascading effects.

### 7.2 Sleep and Injuries

- **Sleeping while bleeding:** Bleeding continues. The player might not wake up. "You drift off... and the blood doesn't stop."
- **Sleeping while treated:** Injuries heal faster during rest. The narrative acknowledges recovery: "You wake feeling better. The wound is closing."
- **Sleeping with serious untreated injuries:** Sleep may be blocked. "You lie down, but the pain in your side won't let you rest."

### 7.3 Time Pressure from Injuries

Over-time injuries create **implicit turn limits** the player feels through narrative, not numbers:

| Injury | Approximate Urgency | What the Player Sees |
|--------|---------------------|---------------------|
| Minor bleeding | Many turns (~50) | Slow mentions of blood. "The cut still bleeds, a slow trickle." |
| Major bleeding | Few turns (~20) | Urgent, desperate. "Blood pours from the gash. You're getting dizzy." |
| Mild poison | Moderate turns (~20) | Waves of nausea, burning. "The poison churns in your gut." |
| Viper venom | Moderate turns (~15) | Spreading numbness. "The darkness around the bite is spreading up your leg." |
| Infection (early) | Many turns (~100) | Subtle warmth, swelling. Easy to ignore — and that's the danger. |
| Infection (late) | Few turns (~15) | Fever, delirium. "Your thoughts scatter. The wound is killing you." |

**Design note:** The player doesn't see turn counts. They see the prose deteriorating and feel the urgency. The `injuries` verb shows worsening descriptions each time they check.

---

## See Also

- [injury-catalog.md](./injury-catalog.md) — Full catalog of injury types, their cures, and discovery clues
- [healing-items.md](./healing-items.md) — Each healing item and exactly which injuries it treats
- [README.md](./README.md) — System overview and design principles
- `docs/design/game-design-foundations.md` §4 — Original player model
- `docs/design/player-skills.md` §8 — Blood writing (existing injury → resource chain)
