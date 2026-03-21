# Bruised — Injury Reference

## Description

A blunt-force injury from falls, impacts, or collisions. Heals naturally over time with no treatment item required. Rest accelerates healing. Different body locations gate different capabilities (legs block climbing, head reduces examine fidelity, torso blocks lifting).

**GUID:** `{TBD — assigned during implementation}`

## Damage Pattern

| Property | Value |
|----------|-------|
| **Category** | One-Time |
| **Severity** | Low |
| **Health Impact** | Small one-time reduction on infliction |
| **Worsens?** | No — bruises are stable from infliction |
| **Fatal?** | No — never fatal |

## FSM States

```
     [inflicted]
         │
         ▼
   ┌──────────┐
   │  ACTIVE   │ ◄── injury starts here
   │           │     throbbing pain
   └─────┬─────┘
         │
 ┌───────┴───────┐
 │               │
 ▼               ▼
(rest/sleep) (8 turns pass)
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
| **Active** | Until rest or 8 turns | **Body-location dependent:** Legs → climbing/running blocked; Head → examine degraded; Torso → carrying heavy objects blocked |
| **Recovering** | 4 turns after rest | Pain fading. Impairment reduced but not eliminated. Can attempt restricted actions with difficulty. |
| **Healed** | Permanent (injury removed) | Full function restored. |

## Symptoms — Legs Bruised (Most Common)

| State | Description |
|-------|-------------|
| **Active** | *"Badly bruised legs from the fall. Your ankles and knees throb with every step. Climbing is out of the question. Moving is painful. This will heal with rest — time and staying off your feet."* |
| **Active (action blocked)** | *"You try to climb, but your bruised legs buckle beneath you. Not yet."* |
| **Active (movement)** | *"You limp forward, each step sending a jolt of pain through your knees."* |
| **Recovering** | *"The bruising is fading. Your legs still protest sharp movements, but you can manage. Climbing might work if you're careful."* |
| **Healed** | *"The soreness in your legs has finally passed. Full strength has returned."* |

## Symptoms — Head Bruised

| State | Description |
|-------|-------------|
| **Active** | *"A throbbing lump on the side of your head. Stars swim at the edges of your vision. Focusing on details is difficult. Rest would help clear the fog."* |
| **Active (examine degraded)** | *"You squint at the [object]. The details swim. Your head throbs when you try to focus."* |
| **Recovering** | *"The lump on your head is tender but the stars have cleared. You can focus again."* |
| **Healed** | *"The bump on your head has gone down. Your vision is clear."* |

## Symptoms — Torso Bruised

| State | Description |
|-------|-------------|
| **Active** | *"Bruised ribs. Every breath is a shallow, careful thing. Lifting anything heavy sends a spike of pain through your chest. Rest is what this needs."* |
| **Active (carry blocked)** | *"You try to lift the [heavy object]. Your ribs scream in protest. Not with this injury."* |
| **Recovering** | *"The bruised ribs still ache with deep breaths, but the sharp pain has dulled. You can carry things again — carefully."* |
| **Healed** | *"Your ribs have stopped aching. You can breathe fully again."* |

## Treatment

### Correct Treatment

| Method | Effect | How It Works |
|--------|--------|-------------|
| **Rest** | Transitions `active → recovering`. Accelerates healing (8 → 4 turns). | Verb: `rest`, `sit down` |
| **Sleep** | Same as rest but more effective. | Verb: `sleep`. Must be on bed or soft surface. |

**No treatment item is needed.** Bruises heal on their own. Rest accelerates recovery. Natural healing takes 8 turns; rest accelerates to 4 turns.

### Wrong Treatments

| Item | Feedback |
|-----|----------|
| **Bandage** | *"You wrap a bandage around your bruised legs. It doesn't help — there's nothing to bind, no bleeding to stop. The bruising is deep in the muscle. Only time and rest will heal this."* |
| **Antidote** | *"You drink the antidote. Your stomach is fine. Your bruised legs are not. This is blunt trauma, not poison."* |
| **Water** | *"You pour water over your bruised knees. It's cool and pleasant, but the deep ache doesn't change. This needs rest, not water."* |
| **Salve** | *"You rub salve into the bruised skin. It feels soothing on the surface, but the deep ache persists. The muscle needs time to heal."* |

## Body Location Variants

| Location | Caused By | Gates | Narrative |
|----------|-----------|-------|-----------|
| **Legs** | Falls, window jump, tripping | Climbing, running, kicking | Limping, buckling knees |
| **Head** | Blunt impact to head, falling object | Examination clarity, focus tasks | Seeing stars, foggy vision |
| **Torso** | Falling onto hard surface, heavy object impact | Carrying heavy items, physical exertion | Painful breathing, shallow breaths |
| **Arms** | Impact, catching self during fall | Lifting, pushing/pulling heavy objects | Aching grip, weak arms |

**Level 1 default:** Legs (from window jump or cellar fall)

## Causes

| Source | Context |
|--------|---------|
| Window jump | Jumping from first-floor window (Puzzle 013) |
| Fall in cellar | Missing steps descending in darkness |
| Falling crate | Heavy object dropped on player |
| Collision | Running into wall or obstacle in darkness |

## Implementation Details

- **Template file:** `src/meta/injuries/bruised.lua`
- **FSM states:** `active`, `recovering`, `healed`
- **Timers:**
  - `active`: `natural_heal_turns: 8`
  - `recovering`: `heal_turns: 4`
- **Treatment trigger:** Verb `rest`, `sit`, `sit down`, `sleep` → transitions `active → recovering`
- **Body location:** Set by infliction source (e.g., `window_jump` → `legs`)
- **Capability gates:** Define `blocked_actions` per location:
  - Legs: `climb`, `run`, `jump`, `kick`
  - Head: (no hard blocks, examine fidelity reduced)
  - Torso: `carry_heavy`, `push_heavy`, `pull_heavy`
  - Arms: `lift_heavy`, `push`, `pull`

## Movement Flavor

While `active` with legs bruised, movement descriptions include limping narrative:
```
"You limp northward, each step protesting."
```

## Interactions with Other Systems

| System | Effect |
|--------|--------|
| **Movement** | Bruised legs add limping flavor to all movement (narrative, not blocked) |
| **Climbing/running** | Bruised legs BLOCK these actions completely |
| **Carrying** | Bruised torso impairs carrying heavy objects (light items unaffected) |
| **Examination** | Bruised head occasionally degrades examine output (fuzzier details) |
| **Stacking** | Multiple bruises on different body parts track independently |
| **GOAP** | Should NOT auto-rest. Decision to rest is strategic (sacrifices turns). |
| **Sleep verb** | If player sleeps in bed with bruised legs, injury transitions to `recovering` during sleep time skip. Sleep is fastest recovery. |

## Technical Notes

- No per-turn health drain (one-time damage only)
- Movement is NOT blocked; only specific actions like climbing or heavy lifting
- Multiple bruises possible on different body parts
- One-time damage from each bruise accumulates
