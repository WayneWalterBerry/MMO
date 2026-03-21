# Poisoned by Nightshade

**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-07-25  
**Status:** 🔴 Planned  
**Level:** 1  
**GUID:** `{TBD — assigned during implementation}`  
**Cross-Ref:** [injury-catalog.md §2.7](../player/injury-catalog.md), [healing-items.md](../player/healing-items.md), [health-system.md](../player/health-system.md)

---

## 1. Overview

Nightshade poisoning is the most **lethal Level 1 injury** and the introduction to the **treatment-matching puzzle**. The player drinks from the poison bottle (or consumes nightshade-tainted substance) and begins a rapid decline. Generic antidotes don't work. Only the **nightshade-specific antidote** cures it.

This injury exists to teach one lesson above all others: **don't consume unknown substances** — and if you do, **read the symptoms carefully to match the cure**.

---

## 2. Cause(s)

| Trigger | Object | Context |
|---------|--------|---------|
| **Drink poison bottle** | `poison-bottle` | Player opens and drinks the poison bottle in the bedroom. Currently instant death — this injury design offers a survivable alternative if an antidote exists in the level. |
| **Eat nightshade berries** | *(future object)* | Consuming dark berries found in courtyard/garden |
| **Nightshade-laced drink** | *(future object)* | Tainted wine or water |

**Level 1 Primary Source:** The poison bottle in the bedroom (sealed with cork, stored on vanity or shelf). The existing behavior is instant death via `drink = game over`. This injury design proposes a **revision**: if a nightshade antidote exists somewhere in the level, drinking the poison inflicts `poisoned-nightshade` instead of instant death — giving the player a narrow window to find the cure. If no antidote exists in the level, the original instant-death behavior remains.

**Design Decision Required:** Wayne/CBG must decide whether to place a nightshade antidote in Level 1. If yes, the poison bottle becomes a survivable puzzle. If no, the poison bottle remains an instant-death lesson and this injury type is deferred to Level 2+.

---

## 3. Damage Pattern

| Type | Value |
|------|-------|
| **Category** | Over-Time (rapid — faster than bleeding) |
| **Severity** | High — lethal if untreated |
| **Health Impact** | Rapid health drain each turn. Faster rate than bleeding. |
| **Drain Rate** | High per-turn. Fatal within approximately 8-10 turns untreated. |
| **Worsens?** | Yes — symptoms escalate through stages |
| **Fatal?** | YES — death if untreated within the window |

---

## 4. FSM States

```
         [inflicted]
             │
             ▼
       ┌──────────┐
       │  ACTIVE   │ ◄── rapid health drain begins
       │ (stage 1) │     vision blurring, heart racing
       └─────┬─────┘
             │
     ┌───────┴──────────────────────┐
     │                              │
     ▼                              ▼
  (nightshade                 (4 turns
   antidote)                   untreated)
     │                              │
     ▼                              ▼
┌──────────┐              ┌──────────┐
│NEUTRALIZED│              │ WORSENED  │ ◄── escalated symptoms
│           │              │ (stage 2) │     hallucinations, collapse
└─────┬─────┘              └─────┬─────┘
      │                          │
   (4 turns)              ┌──────┴──────┐
      │                   │             │
      ▼                   ▼             ▼
┌──────────┐        (nightshade    (4 more turns
│  HEALED   │         antidote)     untreated)
└──────────┘              │             │
                          ▼             ▼
                    ┌──────────┐     DEATH
                    │NEUTRALIZED│
                    └─────┬─────┘
                          │
                       (6 turns)
                          │
                          ▼
                    ┌──────────┐
                    │  HEALED   │
                    └──────────┘
```

| State | Duration | Health Drain | Mechanical Effect |
|-------|----------|-------------|-------------------|
| **Active (stage 1)** | 4 turns until worsened | Rapid per-turn drain | Dilated pupils → vision blurred (examine descriptions degraded). Heart racing → intermittent dizziness (random action failure). |
| **Worsened (stage 2)** | 4 turns until death | Faster drain | Hallucinations (false room descriptions). Collapse risk (random movement failure). Cannot perform precise actions. |
| **Neutralized (from stage 1)** | 4 turns to healed | No drain | Weakness, nausea fading. Vision clearing. Full function returning. |
| **Neutralized (from stage 2)** | 6 turns to healed | No drain | Severe weakness. Slow recovery. Limited actions for longer. |
| **Healed** | Permanent (injury removed) | None | Full recovery. Injury cleared. |
| **DEATH** | — | — | Player dies. |

---

## 5. Symptoms (`injuries` verb output)

| State | Player Sees |
|-------|-------------|
| **Active (stage 1)** | *"Your pupils are huge — even dim light stabs at your eyes. Your heart hammers against your ribs. You recognize the symptoms: you've been poisoned. Something specific. The burning in your throat has a bitter, almost sweet edge — nightshade. You need the specific antidote for this. Not just any remedy."* |
| **Active (stage 1, turn 2+)** | *"The room pulses with your heartbeat. Colors swim. The nightshade is working through your blood. An antidote — the RIGHT antidote — or this ends badly."* |
| **Worsened (stage 2)** | *"Shadows move at the edges of your vision. Things that aren't there. Your legs won't hold you steady. The nightshade has reached your heart and brain. The antidote might still save you — if you can find it. If you can even walk."* |
| **Worsened (stage 2, final turns)** | *"You can barely see. Your heartbeat is irregular — fast, then slow, then fast again. The darkness is closing in. The nightshade is killing you."* |
| **Neutralized (from stage 1)** | *"The racing in your chest slows. Your pupils contract. The world stops pulsing. The antidote is working. You feel wrung out, but alive."* |
| **Neutralized (from stage 2)** | *"The hallucinations fade. Your heartbeat stumbles back toward normal. The antidote caught it just in time. You're alive, but barely. Don't move fast."* |
| **Healed** | *"The last traces of the nightshade have left your body. Your vision is clear. Your heart beats steady. You won't forget that bitter taste."* |

---

## 6. Treatment

### 6.1 Correct Treatment

| Item | Effect | How Obtained (Level 1) |
|------|--------|----------------------|
| **Nightshade antidote** | Transitions `active → neutralized` or `worsened → neutralized`. Stops all drain and symptoms. | **Object design needed.** Must be placed in Level 1 if this injury is survivable. Possible locations: locked medicine cabinet in hallway, hidden in cellar storage crate, carried by NPC. |

**The antidote is a NEW OBJECT** that needs to be designed and placed. Suggested properties:
- Small glass vial with dark green liquid
- SMELL: *"Sharp and herbal. A strong medicinal scent — something brewed to counteract a specific poison."*
- EXAMINE: *"A small glass vial labeled in faded script: 'Contra Belladonna.' The dark green liquid inside smells of crushed herbs."*
- The label "Contra Belladonna" is the key clue — belladonna = nightshade. The player who reads the label and knows nightshade = belladonna makes the connection.

**Consumable Lifecycle:** The antidote is consumable. Drinking it destroys the instance. One vial, one use, gone. The `sealed → open → empty (destroyed)` FSM follows the same terminal pattern as spent matches. See healing-items.md §12 for lifecycle details.

**Targeted Treatment — What the Player Types:**

Nightshade is typically the only poison the player has (single injury auto-resolves):
```
> drink antidote
"You drink the dark liquid. The racing in your chest slows.
 The antidote is working."
```

If somehow the player has multiple conditions, the antidote only works on nightshade — the parser matches automatically since generic antidotes don't treat nightshade and the nightshade antidote doesn't treat anything else.

### 6.2 Partial Treatments

| Item | Effect | Notes |
|------|--------|-------|
| **Purge/vomit (salt water)** | Slows the drain rate by roughly half. Does NOT stop it. | *"You retch violently. Some of the poison leaves your system. The burning eases — but doesn't stop. Purging slowed it, but the nightshade in your blood remains. You still need the real antidote."* |
| **Generic antidote** | No effect on nightshade. | Nightshade is too specific for a generic cure. |

### 6.3 Wrong Treatments

| Item Tried | What Happens | Feedback Message |
|------------|-------------|------------------|
| **Bandage** | No effect. | *"You wrap your arm in cloth. The nightshade burning through your veins doesn't care about bandages. This is poison, not a wound."* |
| **Generic antidote** | No effect. Item consumed/wasted. | *"You drink the antidote. For a moment, hope — then nothing. The racing heart, the blurred vision, the burning — all unchanged. This poison is too specific. You need something made for nightshade."* |
| **Water** | No effect. | *"You drink deeply. The water is cool but the burning in your throat returns immediately. Water can't neutralize what's in your blood."* |
| **Salve** | No effect. | *"You apply the salve to your skin. The nightshade is inside you, not on you. This needs something you swallow, not something you smear."* |
| **Wine** | No effect (and arguably makes it worse narratively). | *"The wine is warm going down, but your racing heart doesn't slow. Alcohol and nightshade — not a good combination. You need the antidote."* |

---

## 7. Discovery Clues

How the player figures out the treatment:

1. **The injury NAMES the poison:** The `injuries` output explicitly says "nightshade." This is the identification — the player knows WHAT poisoned them.
2. **The injury demands specificity:** "The specific antidote for this. Not just any remedy." This tells the player: generic cures won't work.
3. **The antidote labels itself:** The vial says "Contra Belladonna." Belladonna = nightshade. The literate player makes the connection.
4. **SMELL the antidote:** "Sharp and herbal. Medicinal." → This is medicine, not food or drink.
5. **Wrong-treatment feedback teaches:** If the player tries a generic antidote and it fails, the message says "too specific... something made for nightshade" — directing them to the right cure.
6. **Herbal medicine book (if found):** A tattered scroll or book in the crypt/cellar might describe nightshade symptoms and the herbal counter. This is the "prepared adventurer" path — finding the knowledge before needing it.
7. **EXAMINE the poison bottle (after drinking):** *"The residue at the bottom of the bottle is dark and oily, with a sickly sweet smell. Nightshade extract."* — Confirms the poison identity retroactively.

---

## 8. Puzzle Uses

### 8.1 The "Don't Drink Random Things" Lesson (Primary)

**Setup:** Player finds sealed poison bottle. Curiosity says "drink it."  
**Outcome:** Nightshade poisoning begins.  
**Puzzle:** Find the nightshade antidote before time runs out.  
**Lesson:** Investigate before consuming. The bottle had warning signs (SMELL: *"bitter and vaguely sweet — not appetizing"*; label if readable).  
**Meta-lesson:** The `injuries` verb tells you what's wrong. READ IT.

### 8.2 The Treatment-Matching Exemplar

**Setup:** Player is poisoned by nightshade. They find a generic antidote.  
**Failed attempt:** Generic antidote does nothing. Item wasted.  
**Realization:** "Not just any remedy" — need the SPECIFIC antidote.  
**Resolution:** Find the nightshade antidote ("Contra Belladonna").  
**Lesson:** Match the cure to the disease. This principle governs ALL future poison encounters.

### 8.3 The Knowledge Gate

**Setup:** A herbal medicine reference exists somewhere in Level 1 (tattered scroll in crypt, book in storage).  
**Pre-reading path:** Player who read the reference before getting poisoned knows immediately what they need and where to look.  
**Post-reading path:** Player who finds the reference WHILE poisoned must read it quickly under time pressure.  
**No-reading path:** Player must rely on injury descriptions and experimentation.  
**Lesson:** Knowledge gathered before a crisis saves your life during it.

### 8.4 Time Pressure Escalation

**Setup:** 8-10 turns to find the antidote.  
**Escalation:** Stage 1 (4 turns) → Stage 2 (4 turns) → death.  
**Stage 2 handicap:** Hallucinations corrupt room descriptions. Movement may fail. Precise actions impossible.  
**Design:** The poison actively makes finding the cure HARDER as time passes. The player is racing their own deterioration.

### 8.5 Verb Contrast with Puzzle 016 (Wine)

**Setup:** Poison bottle (DRINK = poisoned) exists alongside wine bottles (DRINK = safe/beneficial).  
**Teaching pair:** Not all liquids are dangerous. Not all are safe. Investigate first.  
**Contrast clues:** Poison bottle SMELLS bitter/sweet. Wine bottle SMELLS like wine. The nose knows.

---

## 9. Interaction with Other Systems

| System | Interaction |
|--------|-------------|
| **Poison bottle (existing)** | Currently instant death. This injury converts it to a survivable (but dangerous) condition IF an antidote is placed in the level. Requires design decision. |
| **Vision degradation** | Stage 1: examine descriptions become vaguer. Stage 2: hallucinations inject false details into room descriptions. This is a mechanical overlay on the existing light/vision system. |
| **Action interruption** | Dizziness causes random action failure in stage 1 (~20% chance). Collapse causes movement failure in stage 2 (~40% chance). |
| **Injury stacking** | Nightshade poisoning stacks with other injuries. Being poisoned AND bleeding is doubly urgent — both drain health per turn, and the drains accumulate (see health-system.md §1.3). Which do you treat first? The `injuries` verb provides triage guidance through its severity descriptions. |
| **GOAP** | GOAP should NOT auto-drink the antidote. The player must identify and choose to drink it. GOAP can help with container-opening chains (unlock cabinet → open → take vial) but not the decision to consume. |
| **Sensory overlay** | While poisoned, TASTE and SMELL senses are degraded. The burning in the throat corrupts taste perception. This makes identifying OTHER substances harder while poisoned. |

---

## 10. Death Sequence (if untreated)

If health reaches zero from nightshade poisoning:

```
"The darkness is complete now. Your heart flutters — fast, slow,
fast — then begins to stop. The nightshade has won.

Somewhere in this place, there was an antidote — a small vial,
'Contra Belladonna' on its label. Green liquid. Sharp herbal
smell. It could have saved you.

Perhaps next time, you'll think twice before drinking from
unlabeled bottles.

You died of nightshade poisoning in the [room name]."
```

**Design Note:** The death text names the cure ("Contra Belladonna"), describes it (green liquid, herbal smell), and gently chides the player ("think twice before drinking"). On replay, the player knows exactly what to look for.

---

## 11. The Nightshade Antidote — Object Spec for Flanders

This injury requires a new object: the nightshade antidote vial.

| Property | Value |
|----------|-------|
| **Name** | `nightshade-antidote` |
| **Type** | Consumable (single-use) |
| **Size** | Tiny (size tier 1) |
| **Portable** | Yes (one-handed) |
| **Description** | *"A small glass vial, stoppered with wax. The liquid inside is dark green, almost black. Faded script on a paper label reads: 'Contra Belladonna.'"* |
| **on_smell** | *"Sharp and herbal. A concentrated medicinal scent — something brewed with purpose."* |
| **on_feel** | *"Smooth cool glass. The liquid sloshes inside — there's not much."* |
| **on_taste** | *"(If healthy:) Intensely bitter. Your tongue goes numb for a moment. Powerful medicine — best saved for when you need it."* |
| **Verb: drink** | If player has `poisoned-nightshade` injury → applies cure. If healthy → *"The liquid is astringent and bitter. Your tongue goes numb. You feel... fine. You just wasted a dose of antidote you might have needed."* |
| **FSM** | `sealed → open → empty` (same as poison bottle pattern) |
| **Suggested Location** | Locked medicine cabinet in hallway, or inside a crate in storage cellar, or on a shelf in the deep cellar |
| **GUID** | `{TBD — assigned during implementation}` |

---

## 12. Implementation Notes for Flanders

- **Template file:** `src/meta/injuries/poisoned-nightshade.lua`
- **FSM states:** `active`, `worsened`, `neutralized`, `healed`
- **Timers:** `active` has `worsen_turns: 4`; `worsened` has `death_turns: 4`; `neutralized` has `heal_turns: 4` (from stage 1) or `heal_turns: 6` (from stage 2)
- **Treatment trigger:** Verb `drink` with item matching `healing.cures_nightshade = true`
- **Drain mechanic:** Per-turn health reduction, higher rate than bleeding. Rate increases in `worsened` state.
- **Vision overlay:** In `active` state, examine descriptions get a "blurred" modifier. In `worsened` state, hallucination strings are injected into room descriptions.
- **Action interruption:** `active` has ~20% chance per action of dizziness interruption. `worsened` has ~40% chance of collapse interruption.
- **Sensory degradation:** TASTE and SMELL outputs are corrupted while poisoned.

---

## 13. Design Rationale

Nightshade poisoning is the **pinnacle of Level 1 injury design**. It teaches:

1. **Don't consume unknown substances** — the fundamental survival lesson
2. **Read your symptoms** — the `injuries` verb names the poison and hints at treatment
3. **Specific cures for specific poisons** — generic antidotes don't work
4. **Time pressure with escalation** — the injury gets HARDER to survive as it progresses
5. **Knowledge is power** — finding the herbal reference before getting poisoned saves your life
6. **Investigation before action** — the bottle had warning signs if you smelled it first

This is the injury that makes players respect the health system. After surviving (or dying to) nightshade, they'll never blindly consume anything again.
