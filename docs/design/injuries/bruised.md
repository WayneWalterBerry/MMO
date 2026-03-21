# Bruised

**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-07-25  
**Status:** 🔴 Planned  
**Level:** 1  
**GUID:** `{TBD — assigned during implementation}`  
**Cross-Ref:** [injury-catalog.md §2.3](../player/injury-catalog.md), [healing-items.md](../player/healing-items.md), [health-system.md](../player/health-system.md), [Puzzle 013 — Courtyard Entry](../../levels/01/puzzles/puzzle-013-courtyard-entry.md)

---

## 1. Overview

A bruise is a **one-time blunt-force injury** that heals naturally over time with no treatment required. It hurts, it slows you down, and it teaches the player that **rest has strategic value** — stopping to recover isn't wasted time, it's a calculated decision.

Bruises are the game's way of saying: "That was a bad idea, but you'll live." They're survivable consequences that create **narrative friction** and **capability gates** without threatening the player's life.

---

## 2. Cause(s)

| Trigger | Object/Event | Context |
|---------|-------------|---------|
| **Fall from height** | Window jump (Puzzle 013) | Jumping from the first-floor window to the courtyard below |
| **Fall in cellar** | Cellar stairs (miss step) | Descending stairs carelessly in darkness |
| **Blunt impact** | Falling crate, heavy object | Heavy object dropped on player or player falls into object |
| **Collision** | Running into wall in darkness | Moving through dark rooms without caution |

**Level 1 Primary Source:** The window jump in Puzzle 013 (Courtyard Entry). The player chooses to jump from the bedroom window as a shortcut to the courtyard — the consequence is bruised legs. This is the **Risky Shortcut** pattern: faster route, but with a cost.

---

## 3. Damage Pattern

| Type | Value |
|------|-------|
| **Category** | One-Time |
| **Severity** | Low (minor blunt damage) |
| **Health Impact** | Small one-time reduction on infliction |
| **Worsens?** | No — bruises do NOT worsen. They are stable from moment of infliction. |
| **Fatal?** | No — never fatal on their own |

---

## 4. FSM States

```
         [inflicted]
             │
             ▼
       ┌──────────┐
       │  ACTIVE   │ ◄── injury starts here
       │           │     throbbing pain, impaired movement
       └─────┬─────┘
             │
     ┌───────┴───────┐
     │               │
     ▼               ▼
  (rest/sleep)   (8 turns pass)
     │               │
     ▼               ▼
┌──────────┐    ┌──────────┐
│RECOVERING │    │  HEALED   │ ◄── slow natural healing
│           │    └──────────┘
└─────┬─────┘
      │
   (4 turns)
      │
      ▼
┌──────────┐
│  HEALED   │ ◄── accelerated by rest
└──────────┘
```

| State | Duration | Mechanical Effect |
|-------|----------|-------------------|
| **Active** | Until rest or 8 turns | **Body-location dependent:** Legs bruised → climbing/running impaired (cannot climb, movement descriptions mention limping). Head bruised → examine descriptions occasionally degraded (seeing stars). Torso bruised → carrying heavy objects impaired. |
| **Recovering** | 4 turns after rest | Pain fading. Impairment reduced but not eliminated. Can attempt restricted actions with narrative protest. |
| **Healed** | Permanent (injury removed) | Full function restored. No lasting effects. |

---

## 5. Symptoms (`injuries` verb output)

### 5.1 Legs Bruised (most common — falls)

| State | Player Sees |
|-------|-------------|
| **Active** | *"Badly bruised legs from the fall. Your ankles and knees throb with every step. Climbing is out of the question. Moving is painful. This will heal with rest — time and staying off your feet."* |
| **Active (action blocked)** | *"You try to climb, but your bruised legs buckle beneath you. Not yet."* |
| **Active (movement)** | *"You limp forward, each step sending a jolt of pain through your knees."* |
| **Recovering** | *"The bruising is fading. Your legs still protest sharp movements, but you can manage. Climbing might work if you're careful."* |
| **Healed** | *"The soreness in your legs has finally passed. Full strength has returned."* |

### 5.2 Head Bruised (blunt impact)

| State | Player Sees |
|-------|-------------|
| **Active** | *"A throbbing lump on the side of your head. Stars swim at the edges of your vision. Focusing on details is difficult. Rest would help clear the fog."* |
| **Active (examine degraded)** | *"You squint at the [object]. The details swim. Your head throbs when you try to focus."* |
| **Recovering** | *"The lump on your head is tender but the stars have cleared. You can focus again."* |
| **Healed** | *"The bump on your head has gone down. Your vision is clear."* |

### 5.3 Torso Bruised (impact, heavy object)

| State | Player Sees |
|-------|-------------|
| **Active** | *"Bruised ribs. Every breath is a shallow, careful thing. Lifting anything heavy sends a spike of pain through your chest. Rest is what this needs."* |
| **Active (carry blocked)** | *"You try to lift the [heavy object]. Your ribs scream in protest. Not with this injury."* |
| **Recovering** | *"The bruised ribs still ache with deep breaths, but the sharp pain has dulled. You can carry things again — carefully."* |
| **Healed** | *"Your ribs have stopped aching. You can breathe fully again."* |

---

## 6. Treatment

### 6.1 Correct Treatment

| Item | Effect | How Obtained (Level 1) |
|------|--------|----------------------|
| **Rest** | Transitions `active → recovering`. Accelerates healing from 8 turns to 4 turns. | Verb: `rest`, `sit down`, `sleep`. Must be in a safe location (bed, chair, ground). No item required. |
| **Sleep** | Same as rest but more effective — represents longer recovery period. | Verb: `sleep`. Must be on a bed or soft surface. |

**No treatment item is needed.** Bruises heal on their own. Rest accelerates recovery. This is the only Level 1 injury where the "cure" is inaction — teaching that sometimes the smartest move is to stop moving.

### 6.2 Wrong Treatments

| Item Tried | What Happens | Feedback Message |
|------------|-------------|------------------|
| **Bandage** | No effect. | *"You wrap a bandage around your bruised legs. It doesn't help — there's nothing to bind, no bleeding to stop. The bruising is deep in the muscle. Only time and rest will heal this."* |
| **Antidote** | No effect. Item consumed/wasted. | *"You drink the antidote. Your stomach is fine. Your bruised legs are not. This is blunt trauma, not poison."* |
| **Water** | No effect. | *"You pour water over your bruised knees. It's cool and pleasant, but the deep ache doesn't change. This needs rest, not water."* |
| **Salve** | Minimal effect (slight comfort, no mechanical benefit). | *"You rub salve into the bruised skin. It feels soothing on the surface, but the deep ache persists. The muscle needs time to heal."* |

---

## 7. Discovery Clues

How the player figures out the "treatment":

1. **Injury description says it directly:** "This will heal with rest — time and staying off your feet." The word "rest" is explicit.
2. **No urgency in the description:** Unlike bleeding or poison, there's no "now," "urgently," or "you need." The tone is resigned, not panicked — signaling this isn't an emergency.
3. **Action blocking teaches:** When the player tries to climb with bruised legs and gets "your bruised legs buckle," the blocked action itself suggests the solution: stop doing the thing that hurts.
4. **Contrast with bleeding:** Bleeding says "you need something wrapped tight." Bruising says "time and rest." The difference teaches injury discrimination — not every injury needs an item.
5. **Real-world intuition:** Everyone knows bruises heal with rest. The game rewards this common-sense knowledge.

---

## 8. Puzzle Uses

### 8.1 The Risky Shortcut (Primary — Puzzle 013)

**Setup:** Player wants to reach the courtyard. Two paths:
- **Safe route:** Find the hallway key → unlock door → go through hallway → reach courtyard (longer but no injury)
- **Risky route:** Open bedroom window → jump down → bruised legs (faster but costly)

**Consequence:** Bruised legs → cannot climb ivy on courtyard wall → must find ground-level route or rest first.  
**Lesson:** Shortcuts have costs. The "fast" path actually costs more time (recovery) than the "slow" path.

### 8.2 The Capability Gate

**Setup:** Player has bruised legs and encounters a climbing challenge.  
**Gate:** Cannot climb until bruising resolves (healed or recovering).  
**Options:**
1. Rest (sit down, sleep) → accelerate healing → climb later
2. Find alternate route that doesn't require climbing
3. Wait 8 turns (natural healing) and keep exploring non-climbing areas

**Lesson:** Injuries change what's possible. Adapt your approach.

### 8.3 Strategic Rest Timing

**Setup:** Player has bruised legs AND is being pursued by a time pressure (another injury, timed puzzle).  
**Dilemma:** Rest heals bruises faster, but resting costs turns. If there's a bleeding wound or poison ticking, every turn matters.  
**Decision:** Treat the urgent injury first (bandage bleeding, drink antidote), THEN rest for bruises.  
**Lesson:** Triage. Prioritize injuries by urgency, not by which hurts most.

### 8.4 Exploration Redirection

**Setup:** Bruised legs block climbing but don't block walking, examining, or other actions.  
**Design:** While "stuck" recovering, the player is encouraged to explore the current area more thoroughly — examining objects they might have skipped, reading inscriptions, smelling things.  
**Hidden benefit:** Recovery downtime often leads to discovering things the player would have missed by rushing through.

---

## 9. Interaction with Other Systems

| System | Interaction |
|--------|-------------|
| **Movement** | Bruised legs add limping flavor text to all movement: *"You limp northward, each step protesting."* This is narrative friction, not a movement block. The player can still move — it just hurts. |
| **Climbing/running** | Bruised legs BLOCK climbing and running. These require leg strength. `climb ivy` → *"Your bruised legs buckle. Not yet."* |
| **Carrying** | Bruised torso impairs carrying heavy objects (2-handed items, large crates). Light items unaffected. |
| **Examination** | Bruised head occasionally degrades examine output: details are fuzzier, descriptions shorter. Not a hard block — just reduced fidelity. |
| **Injury stacking** | Bruises stack with other injuries. Bruised legs + bleeding arm = very limited capability. Multiple bruises on different body parts are independent instances — bruised legs AND bruised ribs means both climbing AND carrying are impaired. The one-time damage from each bruise accumulates in derived health (see health-system.md §1.3). The `injuries` verb helps prioritize: bleeding is urgent, bruises are patient. |
| **GOAP** | GOAP should NOT auto-rest. The decision to rest (sacrificing turns) is strategic — the player must weigh recovery against other priorities. |
| **Sleep verb** | If the player `sleep`s in bed with bruised legs, the injury transitions to `recovering` during the sleep time skip. Sleep is the fastest recovery. |
| **Rest verb** | `rest` or `sit down` triggers the transition. Must be in a location where resting is plausible (not mid-combat, not in water). |

---

## 10. Body Location Variants

Bruises are **body-location-specific**. The location determines the capability gate:

| Location | Caused By | Gates | Narrative |
|----------|-----------|-------|-----------|
| **Legs** | Falls, window jump, tripping | Climbing, running, kicking | Limping, buckling knees |
| **Head** | Blunt impact to head, falling object | Examination clarity, focus tasks | Seeing stars, foggy vision |
| **Torso** | Falling onto hard surface, heavy object impact | Carrying heavy items, physical exertion | Painful breathing, shallow breaths |
| **Arms** | Impact, catching self during fall | Lifting, pushing/pulling heavy objects | Aching grip, weak arms |

**Level 1 default:** Legs (from window jump / cellar fall). Future levels can target other body parts.

---

## 11. Implementation Notes for Flanders

- **Template file:** `src/meta/injuries/bruised.lua`
- **FSM states:** `active`, `recovering`, `healed`
- **Timers:** `active` has `natural_heal_turns: 8`; `recovering` has `heal_turns: 4`
- **Treatment trigger:** Verb `rest`, `sit`, `sit down`, `sleep` → transitions `active → recovering`
- **Body location:** Set by infliction source. `window_jump` → `legs`. `falling_object` → varies.
- **Capability gates:** Define `blocked_actions` per body location:
  - Legs: `climb`, `run`, `jump`, `kick`
  - Head: (no hard blocks, but examine fidelity reduced)
  - Torso: `carry_heavy`, `push_heavy`, `pull_heavy`
  - Arms: `lift_heavy`, `push`, `pull`
- **Movement flavor:** While `active` with legs bruised, all movement descriptions get a limping overlay.
- **No drain:** No per-turn health loss. The one-time damage is the only health impact.

---

## 12. Design Rationale

The bruise is the **most forgiving injury** in the catalog. It teaches three things:

1. **Actions have consequences** — jumping from a window hurts, even if you survive
2. **Rest has value** — sometimes the best action is inaction
3. **Injuries create capability constraints** — you can't do everything while hurt

Bruises exist in the design space between "no consequence" (boring) and "lethal consequence" (frustrating). They're the Goldilocks injury: meaningful enough to change behavior, gentle enough not to kill. The player who gets bruised legs learns to assess risks before leaping — literally.
