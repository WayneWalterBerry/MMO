# Burn

**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-07-25  
**Status:** 🔴 Planned  
**Level:** 1  
**GUID:** `{TBD — assigned during implementation}`  
**Cross-Ref:** [injury-catalog.md §2.8](../player/injury-catalog.md), [healing-items.md](../player/healing-items.md), [health-system.md](../player/health-system.md)

---

## 1. Overview

A burn is a **one-time damage** injury caused by contact with flame or hot objects. In Level 1, the candle and torch are the primary burn sources — the player reaches for the flame directly instead of using the holder. Burns teach the lesson: **use the tool, not the heat source directly**.

Burns are treatable with **cold water** (immediate relief) or **cool damp cloth** (improvised treatment). Salve works if available in later levels. The key design insight: the *treatment item already exists in Level 1* — the player just needs to connect "burn" with "water" and locate a water source (rain barrel in courtyard, or wet cloth).

---

## 2. Cause(s)

| Trigger | Object | Context |
|---------|--------|---------|
| **Touch lit candle flame** | `candle` (lit state) | Player tries to `take candle` without holder, or reaches into flame |
| **Touch lit torch** | `torch` (lit state) | Grabbing a lit torch barehanded from bracket |
| **Handle hot object** | *(future)* | Heated metal, boiling pot, hot coals |
| **Fire trap** | *(future)* | Flame jet, fire pit |

**Level 1 Primary Source:** The candle is the most common burn source. Player tries `take candle` while it's lit → burn to hand. The candle-holder exists specifically to prevent this — carrying the holder is the safe method. This is Puzzle Design 101: the safe tool is right next to the dangerous one.

---

## 3. Damage Pattern

| Type | Value |
|------|-------|
| **Category** | One-Time |
| **Severity** | Low to Medium (depends on source — candle = minor, torch = moderate) |
| **Health Impact** | One-time reduction on infliction. No ongoing drain. |
| **Worsens?** | Only severe burns — untreated severe burns can blister (see §4) |
| **Fatal?** | No — burns alone are not fatal in Level 1. Severe burns (future) could cascade. |

---

## 4. FSM States

### 4.1 Minor Burn (candle touch, brief flame contact)

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
  (cold water    (10 turns pass)
   or cool cloth)    │
     │               ▼
     ▼          ┌──────────┐
┌──────────┐    │  HEALED   │ ◄── slow natural healing
│ TREATED   │    └──────────┘
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

### 4.2 Severe Burn (torch grab, prolonged flame contact)

```
         [inflicted]
             │
             ▼
       ┌──────────┐
       │  ACTIVE   │ ◄── injury starts here
       │  (severe) │     angry, raw wound
       └─────┬─────┘
             │
     ┌───────┴──────────────────┐
     │                          │
     ▼                          ▼
  (cold water              (8 turns
   or salve)                untreated)
     │                          │
     ▼                          ▼
┌──────────┐              ┌──────────┐
│ TREATED   │              │ BLISTERED │ ◄── worsened state
└─────┬─────┘              │           │     requires salve
      │                    └─────┬─────┘
   (5 turns)                     │
      │                    (salve only)
      ▼                          │
┌──────────┐                     ▼
│  HEALED   │              ┌──────────┐
└──────────┘               │ TREATED   │
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
| **Active (minor)** | Until treated or 10 turns | Tender hand; no significant impairment; stinging on object contact |
| **Active (severe)** | Until treated or blistered (8 turns) | Burned hand → reduced grip. Cannot hold objects firmly. Pain on any hand use. |
| **Treated** | 5 turns (minor) or 5-8 turns (severe) | Pain fading. Grip improving. Full function returning. |
| **Blistered** | Until salve applied (only salve works at this stage) | Fluid-filled welts. Cannot use burned hand at all. Extreme pain on contact. |
| **Healed** | Permanent (injury removed) | Shiny pink skin remains (flavor). Full function restored. |

---

## 5. Symptoms (`injuries` verb output)

| State | Player Sees |
|-------|-------------|
| **Active (minor)** | *"Your fingertips are red and tender where you touched the flame. The skin is hot to the touch. Cool water would soothe this."* |
| **Active (severe)** | *"The burn on your hand is angry and raw. Even the air stings. You need something cooling — water, a damp cloth, a medicinal salve."* |
| **Active (severe, turn 5+)** | *"The burn throbs constantly. The skin is tightening. If you don't cool this down soon, it's going to blister."* |
| **Blistered** | *"The burn has blistered. Fluid-filled welts cover your hand. Don't touch anything. This is beyond simple cooling — you need a medicinal salve."* |
| **Treated (water)** | *"The cool water brought relief. The burn still aches, but the angry red is fading."* |
| **Treated (salve)** | *"The cool salve soothes the burn. The throbbing eases to a dull warmth."* |
| **Healed** | *"The burn has faded to a patch of shiny pink skin. No pain remains."* |

---

## 6. Treatment

### 6.1 Correct Treatments

| Item | Effect | How Obtained (Level 1) |
|------|--------|----------------------|
| **Cold water** | Transitions `active → treated`. Works on minor and severe burns (before blistering). Consumable — water is used. | Rain barrel in courtyard. Well bucket with water. Future: any water source. |
| **Cool damp cloth** | Same as cold water. Cloth + water = improvised treatment. Consumable — the dampness is spent. | Wet a cloth strip in rain barrel or well. |
| **Salve** | Transitions `active → treated` OR `blistered → treated`. Required for blistered burns. Consumable — use spent from jar, destroyed when empty. | Not available in Level 1 (Level 2+ medicine). This means severe burns MUST be treated before blistering in Level 1. |

**Level 1 Treatment Path:** The rain barrel in the courtyard and the well bucket are the water sources. Player must:
1. Recognize they need water ("cool water would soothe this")
2. Find a water source (courtyard rain barrel, well)
3. Apply water to the burn, targeting the specific injury: `pour water on burned hand`, `splash water on hand burn`, `cool burn with water`

**Targeted Treatment — What the Player Types:**

Single burn:
```
> pour water on burn
"You splash cold water over your burned fingers. The relief is immediate."
```

Multiple burns or injuries (must specify):
```
> pour water on left hand burn
"You splash cold water over your burned left hand. The angry red fades."
```

**Salve Lifecycle (Consumable):** Salve follows the consumable pattern — each application uses one dose. When the jar is empty, the instance is destroyed. There is no recovering spent salve. See healing-items.md §12 for full lifecycle.

### 6.2 Wrong Treatments

| Item Tried | What Happens | Feedback Message |
|------------|-------------|------------------|
| **Bandage** | No effect. | *"You wrap the burn in cloth. The pressure makes it worse — the heat has nowhere to go. Burns need cooling, not covering."* |
| **Antidote** | No effect. Item consumed/wasted. | *"You drink the antidote. Your stomach settles (it was fine), but the burn on your hand still throbs. This is heat damage, not poison."* |
| **Wine** | No effect. | *"You pour wine on the burn. It stings terribly. Wine is not water — the alcohol makes it worse, not better."* |
| **Dry cloth** | No effect (and hints at the right answer). | *"You press dry cloth against the burn. The heat radiates through it. If the cloth were WET and COOL, this might help."* |

**Note on the dry cloth response:** This is a designed "near miss" that teaches. The player tried cloth (good instinct) but it needs to be wet. The feedback message says "wet and cool" — guiding them toward the solution.

---

## 7. Discovery Clues

How the player figures out the treatment:

1. **Injury description says it directly:** "Cool water would soothe this." The word "cool" and "water" are explicit.
2. **Severe burn escalation:** "If you don't cool this down soon, it's going to blister" — the word "cool" repeats, reinforcing the need for cold/water.
3. **Environmental awareness:** Rain barrel in courtyard is described with water sounds. Well has water. The player connects burn → need water → water sources exist.
4. **Real-world intuition:** Everyone knows you put cold water on a burn. This injury rewards common sense.
5. **Dry cloth near-miss:** If the player tries a dry bandage, the response says "if the cloth were WET and COOL" — teaching the two-part solution.
6. **Blistered state lock-in:** If the burn blisters, the description changes: "beyond simple cooling — you need a medicinal salve." This signals that the treatment window for water has passed and a more advanced treatment is needed.

---

## 8. Puzzle Uses

### 8.1 The "Use the Tool, Not the Source" Lesson (Primary)

**Setup:** Lit candle sits in candle-holder on nightstand.  
**Naive action:** `take candle` → Burn to hand. You grabbed the flame end.  
**Smart action:** `take candle-holder` → Safe. The holder is the tool.  
**Lesson:** Objects exist for reasons. The holder isn't decoration — it's a safety device. Every tool in the game has a purpose.

### 8.2 The Water Fetch Puzzle

**Setup:** Player gets burned in the bedroom or cellar.  
**Puzzle:** Water is in the courtyard (rain barrel) — one or two rooms away.  
**Constraint:** Severe burn means reduced grip → carrying objects while burned is unreliable.  
**Resolution:** Get to water source → apply water → burn treated.  
**Alternative:** Wet a cloth and bring it back (if you can reach water with unburned hand).

### 8.3 The Preparation Puzzle

**Setup:** Player knows there's a torch in the cellar (torch bracket).  
**Foreshadow:** *"The metal bracket is warm from the still-smoldering torch."*  
**Preparation:** Wet a cloth before attempting to handle the torch. Or use a glove. Or use the candle-holder to carry the torch.  
**Lesson:** Anticipate hazards. Prepare before acting. The description gave you a warning ("warm").

### 8.4 Treatment Resource Connection

**Setup:** The rain barrel exists in the courtyard primarily as a water source.  
**Connection:** Burn injury creates the first NEED for water in Level 1. Before burns, water is just scenery. After a burn, the player sees water as a resource.  
**Meta-lesson:** Everything in the environment might have a purpose. Re-evaluate objects when your needs change.

---

## 9. Interaction with Other Systems

| System | Interaction |
|--------|-------------|
| **Candle/torch FSM** | Lit state objects gain `on_take_effect: "burn"` property. Only fires when player attempts bare-handed interaction with flame. Holder-mediated interaction bypasses this. |
| **Grip/hand system** | Active severe burn reduces grip reliability. Overlaps with bleeding's slippery-hands effect. If both active, grip is extremely unreliable — strong incentive to treat at least one. |
| **Water objects** | Rain barrel, well bucket — existing courtyard objects. Burn treatment is their first gameplay purpose. Later: water is used for cleaning wounds, mixing potions, extinguishing fires. |
| **Injury stacking** | Burns stack with other injuries. Burned hand + bleeding arm = both hands impaired in different ways. Multiple burns on different body parts are independent instances — a burned left hand and a burned right hand each need separate treatment and each contribute their own one-time damage to derived health. |
| **GOAP** | GOAP should NOT auto-treat burns. But GOAP CAN help: if player says "cool burn with water" and rain barrel is in an adjacent room, GOAP could plan: go to courtyard → get water from barrel → apply to burn. The navigation is GOAP territory; the decision to treat is the player's. |
| **Fire chain** | The candle fire chain (match → candle → light) already exists. Burns are the consequence of disrespecting that chain — grabbing fire directly instead of using proper tools. |

---

## 10. Implementation Notes for Flanders

- **Template file:** `src/meta/injuries/burn.lua`
- **FSM states:** `active_minor`, `active_severe`, `blistered`, `treated`, `healed`
- **Timers:** `active_minor` has `natural_heal_turns: 10`; `active_severe` has `blister_turns: 8`; `treated` has `heal_turns: 5` (minor) or `heal_turns: 8` (severe/blistered)
- **Treatment trigger:** Verb `pour water on`, `splash`, `cool`, `apply salve to` with item matching `healing.cools_burn = true` (water, wet cloth) or `healing.treats_burn = true` (salve)
- **Severity determined by source:** Candle → minor. Torch → severe. Object metadata declares `burn_severity: "minor"` or `burn_severity: "severe"`.
- **Grip reduction:** `active_severe` and `blistered` states set `player.grip_impaired = true`. Handling objects has a failure/drop chance.
- **Body location:** Defaults to `hand` (touching hot objects). Future: `face`/`body` for fire traps.
- **Blistered lock-in:** Once blistered, only `salve` works. Water no longer sufficient. This prevents the player from procrastinating.

---

## 11. Design Rationale

The burn injury serves three design purposes:

1. **Teaches tool use** — the candle-holder exists for a reason; grab the tool, not the flame
2. **Creates first water-need** — turns courtyard water sources from scenery into resources
3. **Rewards common sense** — everyone knows cold water helps burns; the game rewards real-world knowledge

Burns are the most **intuitive** injury in the catalog. The cause is obvious (fire), the treatment is obvious (water), and the lesson is obvious (use the holder). This makes it an excellent early-game injury — it builds confidence in the health system before the player encounters less intuitive injuries like nightshade poisoning.
