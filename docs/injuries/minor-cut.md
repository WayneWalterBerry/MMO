# Minor Cut — Injury Reference

## Description

A minor laceration from handling sharp objects (glass, pins, edges) without care. Stings and bleeds slightly. Heals on its own without treatment.

**GUID:** `{TBD — assigned during implementation}`

## Damage Pattern

| Property | Value |
|----------|-------|
| **Category** | One-Time |
| **Severity** | Low |
| **Health Impact** | Small one-time reduction on infliction |
| **Worsens?** | No |
| **Fatal?** | No |

## FSM States

```
     [inflicted]
         │
         ▼
   ┌──────────┐
   │  ACTIVE   │ ◄── injury starts here
   │           │     stinging sensation
   └─────┬─────┘
         │
 ┌───────┴───────┐
 │               │
 ▼               ▼
(bandage)   (5 turns pass)
 │               │
 ▼               ▼
┌──────────┐   ┌──────────┐
│ TREATED   │   │  HEALED   │ ◄── natural healing
│           │   │           │
└─────┬─────┘   └──────────┘
      │
   (2 turns)
      │
      ▼
┌──────────┐
│  HEALED   │ ◄── bandage accelerates healing
└──────────┘
```

| State | Duration | Mechanical Effect |
|-------|----------|-------------------|
| **Active** | Until bandaged or 5 turns | Stinging; no mechanical impairment |
| **Treated** | 2 turns after bandage applied | Sting fading; no impairment |
| **Healed** | Permanent (injury removed) | No effect; injury cleared |

## Symptoms

| State | Description |
|-------|-------------|
| **Active** | *"A small cut on your hand where the glass caught you. It stings, but the bleeding has mostly stopped on its own."* |
| **Active (reminder, turn 3+)** | *"The cut on your hand is still tender. It's closing up slowly."* |
| **Treated** | *"The bandage on your hand is snug. The sting is fading."* |
| **Healed** | *"The cut on your hand has closed. Barely a mark remains."* |

## Treatment

### Correct Treatment

| Item | Effect | Duration |
|------|--------|----------|
| **Cloth bandage** | Transitions `active → treated`. Accelerates healing (5 → 2 turns). Bandage is reusable, attaches to cut. | 2 turns (treated) → healed |

**Natural Healing:** Minor cut heals on its own in 5 turns without treatment.

### Wrong Treatments

| Item | Feedback |
|-----|----------|
| **Antidote** | *"You drink the antidote. It settles warmly in your stomach, but the cut on your hand still stings. This is a wound, not a poisoning."* |
| **Water** | *"You splash water on the cut. It cleans it, but it doesn't close any faster. You'd need something to wrap it."* |
| **Salve** | *"You apply the salve. It's soothing, but this is a simple cut — it needs covering, not ointment."* |

## Body Location

Default: `hand` (the part that touches the sharp object)

## Causes

| Source | Context |
|--------|---------|
| Glass shard | From broken glass (vanity mirror) |
| Silver dagger | Careless handling of blade |
| Pin | Feeling inside pillow without caution |

## Implementation Details

- **Template file:** `src/meta/injuries/minor-cut.lua`
- **FSM states:** `active`, `treated`, `healed`
- **Timers:** 
  - `active` state: `auto_heal_turns: 5`
  - `treated` state: `heal_turns: 2`
- **Treatment trigger:** Verb `bandage` or `apply bandage to [body_part]` with item matching `healing.stops_minor_bleeding = true`
- **Infliction trigger:** Objects with `on_feel_effect: "cut"` or `on_take_effect: "cut"`

## Interactions with Other Systems

| System | Effect |
|--------|--------|
| **Stacking** | Multiple minor cuts are tracked independently. Two cuts on different hands are two separate injury instances. |
| **GOAP** | Should NOT auto-treat. Minor cuts heal naturally. |
| **Blood writing** | Minor cut does NOT produce enough bleeding for this mechanic. |

## Technical Notes

- No sensory degradation (too minor)
- No capability restriction
- Stacking allowed (multiple cuts possible)
