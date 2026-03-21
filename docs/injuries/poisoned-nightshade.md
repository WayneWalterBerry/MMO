# Poisoned by Nightshade — Injury Reference

## Description

A rapid over-time injury from consuming nightshade poison. The most lethal Level 1 injury. Requires specific nightshade antidote treatment. Generic antidotes do NOT work. Symptoms escalate through stages, with hallucinations and action interruption making survival harder as time passes.

**GUID:** `{TBD — assigned during implementation}`

## Damage Pattern

| Property | Value |
|----------|-------|
| **Category** | Over-Time (rapid — faster than bleeding) |
| **Severity** | High — lethal if untreated |
| **Health Impact** | Rapid drain each turn. Faster rate than bleeding. |
| **Drain Rate** | High per-turn. Fatal within 8-10 turns untreated. |
| **Worsens?** | Yes — symptoms escalate through stages |
| **Fatal?** | YES — death if untreated within window |

## FSM States

```
     [inflicted]
         │
         ▼
   ┌──────────┐
   │  ACTIVE   │ ◄── rapid health drain begins
   │ (stage 1) │     vision blurring, heart racing
   └─────┬─────┘
         │
 ┌───────┴──────────────────┐
 │                          │
 ▼                          ▼
(nightshade           (4 turns
 antidote)             untreated)
 │                          │
 ▼                          ▼
┌──────────┐          ┌──────────┐
│NEUTRALIZED          │ WORSENED  │ ◄── escalated symptoms
│           │          │ (stage 2) │     hallucinations, collapse
└─────┬─────┘          └─────┬─────┘
      │                       │
   (4 turns)          ┌────────┴────────┐
      │               │                 │
      ▼               ▼                 ▼
┌──────────┐    (nightshade         (4 more turns
│  HEALED   │     antidote)         untreated)
└──────────┘        │                 │
                    ▼                 ▼
              ┌──────────┐           DEATH
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
| **Active (stage 1)** | 4 turns until worsened | Rapid per-turn drain | Dilated pupils → vision blurred. Heart racing → dizziness (random action failure ~20%). |
| **Worsened (stage 2)** | 4 turns until death | Faster drain | Hallucinations (false room descriptions). Collapse risk (random movement failure ~40%). Cannot perform precise actions. |
| **Neutralized (from stage 1)** | 4 turns to healed | No drain | Weakness, nausea fading. Vision clearing. Function returning. |
| **Neutralized (from stage 2)** | 6 turns to healed | No drain | Severe weakness. Slow recovery. Limited actions longer. |
| **Healed** | Permanent (injury removed) | None | Full recovery. Injury cleared. |
| **DEATH** | — | — | Player dies. |

## Symptoms

| State | Description |
|-------|-------------|
| **Active (stage 1)** | *"Your pupils are huge — even dim light stabs at your eyes. Your heart hammers against your ribs. You recognize the symptoms: you've been poisoned. Something specific. The burning in your throat has a bitter, almost sweet edge — nightshade. You need the specific antidote for this. Not just any remedy."* |
| **Active (stage 1, turn 2+)** | *"The room pulses with your heartbeat. Colors swim. The nightshade is working through your blood. An antidote — the RIGHT antidote — or this ends badly."* |
| **Worsened (stage 2)** | *"Shadows move at the edges of your vision. Things that aren't there. Your legs won't hold you steady. The nightshade has reached your heart and brain. The antidote might still save you — if you can find it. If you can even walk."* |
| **Worsened (stage 2, final turns)** | *"You can barely see. Your heartbeat is irregular — fast, then slow, then fast again. The darkness is closing in. The nightshade is killing you."* |
| **Neutralized (from stage 1)** | *"The racing in your chest slows. Your pupils contract. The world stops pulsing. The antidote is working. You feel wrung out, but alive."* |
| **Neutralized (from stage 2)** | *"The hallucinations fade. Your heartbeat stumbles back toward normal. The antidote caught it just in time. You're alive, but barely. Don't move fast."* |
| **Healed** | *"The last traces of the nightshade have left your body. Your vision is clear. Your heart beats steady. You won't forget that bitter taste."* |

## Treatment

### Correct Treatment

| Item | Effect | Duration | Availability |
|------|--------|----------|---------------|
| **Nightshade antidote** | Transitions `active → neutralized` or `worsened → neutralized`. Stops all drain and symptoms. | 4 turns (from stage 1) or 6 turns (from stage 2) → healed | Must be placed in Level 1 if this injury is survivable. Requires object design. |

**The Antidote is a NEW OBJECT** that requires design and placement:
- Small glass vial with dark green liquid
- Label reads: "Contra Belladonna" (belladonna = nightshade; this is the key to identifying the cure)
- SMELL: *"Sharp and herbal. A strong medicinal scent — something brewed to counteract a specific poison."*
- EXAMINE: *"A small glass vial labeled in faded script: 'Contra Belladonna.' The dark green liquid inside smells of crushed herbs."*
- **Consumable lifecycle:** Drinking it destroys the instance (one vial, one use)

### Targeted Treatment

Nightshade typically auto-resolves (single poison):
```
> drink antidote
"You drink the dark liquid. The racing in your chest slows.
 The antidote is working."
```

### Partial Treatments

| Item | Effect | Notes |
|------|--------|-------|
| **Purge/vomit (salt water)** | Slows drain rate by ~50%. Does NOT stop it. | *"You retch violently. Some poison leaves your system. The burning eases — but doesn't stop. Purging slowed it, but the nightshade in your blood remains."* |
| **Generic antidote** | No effect on nightshade. | Nightshade is too specific for generic cures. |

### Wrong Treatments

| Item | Feedback |
|-----|----------|
| **Bandage** | *"You wrap your arm in cloth. The nightshade burning through your veins doesn't care about bandages. This is poison, not a wound."* |
| **Generic antidote** | *"You drink the antidote. For a moment, hope — then nothing. The racing heart, the blurred vision, the burning — all unchanged. This poison is too specific. You need something made for nightshade."* |
| **Water** | *"You drink deeply. The water is cool but the burning in your throat returns immediately. Water can't neutralize what's in your blood."* |
| **Salve** | *"You apply the salve to your skin. The nightshade is inside you, not on you. This needs something you swallow, not something you smear."* |
| **Wine** | *"The wine is warm going down, but your racing heart doesn't slow. Alcohol and nightshade — not a good combination. You need the antidote."* |

## Body Location

Systemic (affects entire body/bloodstream; not localized to one body part)

## Causes

| Source | Context |
|--------|---------|
| Poison bottle | Player opens and drinks the poison bottle (currently instant death) |
| Nightshade berries | Future: consuming dark berries found in courtyard/garden |
| Nightshade-laced drink | Future: tainted wine or water |

## Vision Degradation

- **Stage 1:** Examine descriptions become vaguer (blurred vision overlay)
- **Stage 2:** Hallucinations inject false details into room descriptions

## Action Interruption

- **Stage 1:** Dizziness causes random action failure (~20% chance per action)
- **Stage 2:** Collapse causes movement failure (~40% chance per move)

## Implementation Details

- **Template file:** `src/meta/injuries/poisoned-nightshade.lua`
- **FSM states:** `active`, `worsened`, `neutralized`, `healed`
- **Timers:**
  - `active`: `worsen_turns: 4`
  - `worsened`: `death_turns: 4`
  - `neutralized`: `heal_turns: 4` (from stage 1) or `heal_turns: 6` (from stage 2)
- **Treatment trigger:** Verb `drink` with item matching `healing.cures_nightshade = true`
- **Drain mechanic:** Per-turn health reduction. Rate increases in `worsened` state.
- **Vision overlay:** In `active`, examine descriptions get "blurred" modifier. In `worsened`, hallucination strings injected into room descriptions.
- **Action interruption:** `active` has ~20% dizziness chance per action; `worsened` has ~40% collapse chance per movement.
- **Sensory degradation:** TASTE and SMELL outputs corrupted while poisoned.

## Interactions with Other Systems

| System | Effect |
|--------|--------|
| **Poison bottle** | Currently instant death. This injury converts it to survivable IF antidote is placed. |
| **Vision system** | Stage 1: examine degraded. Stage 2: hallucinations overlay. |
| **Action system** | Dizziness/collapse interrupts actions. |
| **Stacking** | Nightshade stacks with other injuries. Being poisoned AND bleeding = doubly urgent (both drain health per turn). |
| **GOAP** | Should NOT auto-drink antidote. Player must identify and choose to drink it. |
| **Sensory overlay** | TASTE and SMELL degraded while poisoned (makes identifying other substances harder). |

## Death Sequence

If health reaches zero:
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

## Discovery Clues — How to Identify Treatment

1. **Injury names the poison:** `injuries` output explicitly says "nightshade" — identification
2. **Demands specificity:** "The specific antidote for this. Not just any remedy." → teaches generic cures won't work
3. **Antidote labels itself:** Vial says "Contra Belladonna." Player who reads label + knows belladonna = nightshade makes connection
4. **SMELL the antidote:** "Sharp and herbal. Medicinal." → this is medicine
5. **Wrong treatment feedback:** Generic antidote failure says "too specific... something made for nightshade" → directs player to right cure
6. **Herbal reference (optional):** Scroll or book describing nightshade symptoms + counter (if placed in level)
7. **EXAMINE poison bottle:** *"Residue at bottom is dark and oily, sickly sweet smell. Nightshade extract."* → confirms poison identity

## Technical Notes

- Most urgent Level 1 injury (fastest drain)
- Requires specific antidote (strongest "match the cure" teaching)
- Vision and action degradation make survival mechanically harder as time passes
- Death text provides clues for replay attempts
