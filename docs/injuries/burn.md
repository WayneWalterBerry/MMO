# Burn — Injury Reference

## Description

A one-time damage injury from contact with flame or hot objects (candle, torch, hot metal). Treatment options depend on severity: minor burns respond to cold water; severe burns can blister and require salve.

**GUID:** `{TBD — assigned during implementation}`

## Damage Pattern

| Property | Value |
|----------|-------|
| **Category** | One-Time |
| **Severity** | Low to Medium (candle = minor, torch = moderate) |
| **Health Impact** | One-time reduction on infliction. No ongoing drain. |
| **Worsens?** | Yes — severe untreated burns can blister |
| **Fatal?** | No — not fatal in Level 1 |

## FSM States

### Minor Burn (candle touch, brief contact)

```
     [inflicted]
         │
         ▼
   ┌──────────┐
   │  ACTIVE   │ ◄── injury starts here
   │  (minor)  │     red, tender skin
   └─────┬─────┘
         │
 ┌───────┴───────┐
 │               │
 ▼               ▼
(cold water  (10 turns pass)
 or cool cloth)    │
 │               ▼
 ▼          ┌──────────┐
┌──────────┐│  HEALED   │ ◄── slow natural healing
│ TREATED   │└──────────┘
│           │
└─────┬─────┘
      │
   (5 turns)
      │
      ▼
┌──────────┐
│  HEALED   │ ◄── accelerated healing
└──────────┘
```

### Severe Burn (torch grab, prolonged contact)

```
     [inflicted]
         │
         ▼
   ┌──────────┐
   │  ACTIVE   │ ◄── injury starts here
   │ (severe)  │     angry, raw wound
   └─────┬─────┘
         │
 ┌───────┴──────────────────┐
 │                          │
 ▼                          ▼
(cold water            (8 turns
 or salve)              untreated)
 │                          │
 ▼                          ▼
┌──────────┐          ┌──────────┐
│ TREATED   │          │ BLISTERED │ ◄── worsened state
└─────┬─────┘          │           │
      │                └─────┬─────┘
   (5 turns)                 │
      │                (salve only)
      ▼                      │
┌──────────┐                 ▼
│  HEALED   │          ┌──────────┐
└──────────┘           │ TREATED   │
                       └─────┬─────┘
                             │
                          (8 turns)
                             │
                             ▼
                       ┌──────────┐
                       │  HEALED   │
                       └──────────┘
```

| State | Duration | Mechanical Effect |
|-------|----------|-------------------|
| **Active (minor)** | Until treated or 10 turns | Tender hand; no significant impairment; stinging on contact |
| **Active (severe)** | Until treated or blistered (8 turns) | Burned hand → reduced grip. Cannot hold firmly. Pain on use. |
| **Treated** | 5 turns (minor) or 5-8 turns (severe) | Pain fading. Grip improving. Function returning. |
| **Blistered** | Until salve applied (salve only works) | Fluid-filled welts. Cannot use burned hand. Extreme pain. |
| **Healed** | Permanent (injury removed) | Pink skin scar (flavor). Full function restored. |

## Symptoms

| State | Description |
|-------|-------------|
| **Active (minor)** | *"Your fingertips are red and tender where you touched the flame. The skin is hot to the touch. Cool water would soothe this."* |
| **Active (severe)** | *"The burn on your hand is angry and raw. Even the air stings. You need something cooling — water, a damp cloth, a medicinal salve."* |
| **Active (severe, turn 5+)** | *"The burn throbs constantly. The skin is tightening. If you don't cool this down soon, it's going to blister."* |
| **Blistered** | *"The burn has blistered. Fluid-filled welts cover your hand. Don't touch anything. This is beyond simple cooling — you need a medicinal salve."* |
| **Treated (water)** | *"The cool water brought relief. The burn still aches, but the angry red is fading."* |
| **Treated (salve)** | *"The cool salve soothes the burn. The throbbing eases to a dull warmth."* |
| **Healed** | *"The burn has faded to a patch of shiny pink skin. No pain remains."* |

## Treatment

### Minor Burn

| Item | Effect | Duration |
|------|--------|----------|
| **Cold water** | Transitions `active → treated`. Consumable. | 5 turns → healed |
| **Cool damp cloth** | Same as cold water. Consumable (wetness spent). | 5 turns → healed |

### Severe Burn — Before Blistering

| Item | Effect | Duration |
|------|--------|----------|
| **Cold water** | Transitions `active → treated`. Consumable. | 5-8 turns → healed |
| **Cool damp cloth** | Same as cold water. Consumable. | 5-8 turns → healed |

### Severe Burn — After Blistering

| Item | Effect | Duration |
|------|--------|----------|
| **Salve** | Transitions `blistered → treated`. Required (water no longer works). Consumable. | 8 turns → healed |

**Level 1 Path:** Rain barrel in courtyard and well bucket are water sources. Player must find water and apply it before severe burns blister.

### Targeted Treatment Examples

Single burn:
```
> pour water on burn
"You splash cold water over your burned fingers. The relief is immediate."
```

Multiple burns or injuries:
```
> pour water on left hand burn
"You splash cold water over your burned left hand. The angry red fades."
```

### Wrong Treatments

| Item | Feedback |
|-----|----------|
| **Bandage** | *"You wrap the burn in cloth. The pressure makes it worse — the heat has nowhere to go. Burns need cooling, not covering."* |
| **Antidote** | *"You drink the antidote. Your stomach settles, but the burn on your hand still throbs. This is heat damage, not poison."* |
| **Wine** | *"You pour wine on the burn. It stings terribly. Wine is not water — the alcohol makes it worse."* |
| **Dry cloth** | *"You press dry cloth against the burn. The heat radiates through it. If the cloth were WET and COOL, this might help."* |

## Body Location

Default: `hand` (the part that touches heat source). Future: `face`, `body` for fire traps.

## Causes

| Source | Context |
|--------|---------|
| Lit candle | Touching flame directly instead of using holder |
| Lit torch | Grabbing torch barehanded |
| Hot object | Future: heated metal, boiling pot, hot coals |
| Fire trap | Future: flame jet, fire pit |

## Severity Determination

Severity is determined by the source object:
- **Minor burn:** Objects with `burn_severity: "minor"` (candle)
- **Severe burn:** Objects with `burn_severity: "severe"` (torch)

## Implementation Details

- **Template file:** `src/meta/injuries/burn.lua`
- **FSM states:** `active_minor`, `active_severe`, `blistered`, `treated`, `healed`
- **Timers:**
  - `active_minor`: `natural_heal_turns: 10`
  - `active_severe`: `blister_turns: 8`
  - `treated`: `heal_turns: 5` (minor) or `heal_turns: 8` (severe/blistered)
- **Treatment triggers:**
  - Verb `pour water on`, `splash`, `cool`, `apply salve to`
  - Items matching `healing.cools_burn = true` (water, wet cloth)
  - Items matching `healing.treats_burn = true` (salve)
- **Severity from source:** Object declares `burn_severity: "minor"` or `burn_severity: "severe"`
- **Grip reduction:** `active_severe` and `blistered` set `player.grip_impaired = true` (drop chance)

## Interactions with Other Systems

| System | Effect |
|--------|--------|
| **Candle/torch FSM** | Lit state objects gain `on_take_effect: "burn"`. Only fires on bare-handed interaction. Holder bypasses this. |
| **Grip system** | Active severe burn reduces grip reliability |
| **Water objects** | Rain barrel, well bucket become first resource need |
| **Stacking** | Burns stack with other injuries. Multiple burns on different body parts track independently. |
| **GOAP** | Should NOT auto-treat. But can help with navigation/fetching water. |
| **Fire chain** | Disrespecting the candle-to-holder chain results in burn |

## Technical Notes

- Blistering locks in water treatment — once blistered, only salve works
- One-time damage (no per-turn drain)
- Drop chance only during `active_severe` and `blistered` states
