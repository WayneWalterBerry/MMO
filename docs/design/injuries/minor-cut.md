# Minor Cut

**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-07-25  
**Status:** 🔴 Planned  
**Level:** 1  
**GUID:** `{TBD — assigned during implementation}`  
**Cross-Ref:** [injury-catalog.md §2.1](../player/injury-catalog.md), [healing-items.md](../player/healing-items.md)

---

## 1. Overview

A minor cut is a small laceration — the kind you get from handling broken glass without care or brushing against a sharp edge. It stings, it bleeds a little, and it heals on its own. The puzzle value isn't the injury itself — it's teaching the player that **interacting with sharp objects has consequences** and that **preparation prevents injury**.

---

## 2. Cause(s)

| Trigger | Object | Context |
|---------|--------|---------|
| **Handle broken glass** | `glass-shard` | Picking up glass shard barehanded (spawned from breaking vanity mirror) |
| **Sharp edge contact** | `silver-dagger` | Careless handling (reaching into dark container with dagger inside) |
| **Pin prick** | `pin` | Feeling inside the pillow and finding the pin by getting pricked |
| **Minor trap** | *(future)* | Trip-wire, thorn bush |

**Key Design Note:** The glass shard is the primary Level 1 source. Its `on_feel_effect: "cut"` already exists in the object metadata. This injury formalizes that effect.

---

## 3. Damage Pattern

| Type | Value |
|------|-------|
| **Category** | One-Time |
| **Severity** | Low (minor) |
| **Health Impact** | Small one-time reduction on infliction |
| **Worsens?** | No — does NOT worsen if untreated |
| **Fatal?** | No — never fatal on its own |

---

## 4. FSM States

```
         [inflicted]
             │
             ▼
       ┌──────────┐
       │  ACTIVE   │ ◄── injury starts here
       │           │     stinging sensation
       │           │     minor narrative feedback
       └─────┬─────┘
             │
     ┌───────┴───────┐
     │               │
     ▼               ▼
  (bandage)     (5 turns pass)
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
| **Healed** | Permanent (injury removed) | No effect; injury cleared from player |

---

## 5. Symptoms (`injuries` verb output)

| State | Player Sees |
|-------|-------------|
| **Active** | *"A small cut on your hand where the glass caught you. It stings, but the bleeding has mostly stopped on its own."* |
| **Active (reminder, turn 3+)** | *"The cut on your hand is still tender. It's closing up slowly."* |
| **Treated** | *"The bandage on your hand is snug. The sting is fading."* |
| **Healed** | *"The cut on your hand has closed. Barely a mark remains."* |

---

## 6. Treatment

### 6.1 Correct Treatment

| Item | Effect | How Obtained (Level 1) |
|------|--------|----------------------|
| **Cloth bandage** | Transitions `active → treated`. Accelerates healing from 5 turns to 2 turns. | Tear blanket, curtains, or wool-cloak → cloth strip → bandage |

**Treatment is optional.** The minor cut heals on its own in 5 turns. Bandaging speeds it up but is not required. This teaches players that minor injuries are survivable without treatment — save your bandages for serious wounds.

### 6.2 Wrong Treatments

| Item Tried | What Happens | Feedback Message |
|------------|-------------|------------------|
| **Antidote** | No effect. Item consumed/wasted. | *"You drink the antidote. It settles warmly in your stomach, but the cut on your hand still stings. This is a wound, not a poisoning."* |
| **Water** | No effect (not a burn). Item used. | *"You splash water on the cut. It cleans it, but it doesn't close any faster. You'd need something to wrap it."* |
| **Salve** | No effect. Item wasted. | *"You apply the salve. It's soothing, but this is a simple cut — it needs covering, not ointment."* |

---

## 7. Discovery Clues

How the player figures out the treatment:

1. **Injury description itself:** The `injuries` output says "stings" and "mostly stopped on its own" — signaling this is minor and self-healing.
2. **Absence of urgency:** Unlike bleeding or poison, the description has no urgency cues ("now," "getting worse," "you need"). This teaches: not every injury demands immediate treatment.
3. **Object clue:** If the player examines the blanket: *"A heavy wool blanket. Warm, but threadbare in places — you could tear strips from it."* → Suggests cloth strips → bandage path.
4. **Contrast teaching:** After experiencing a minor cut (self-heals), encountering bleeding (does NOT self-heal) teaches severity discrimination.

---

## 8. Puzzle Uses

### 8.1 The "Prepare Your Tools" Lesson

**Setup:** Glass shard lies on the floor after breaking the vanity mirror.  
**Naive action:** `take glass shard` → Minor cut inflicted.  
**Smart action:** `wrap glass shard in cloth` → No injury, and now you have a safe cutting tool.  
**Lesson:** Dangerous objects can be handled safely with preparation. The cut is the cost of not thinking ahead.

### 8.2 Resource Tension Seed

The bandage that treats a minor cut is the SAME bandage that stops bleeding from a deep wound. Using it on a minor cut (unnecessary) means it's unavailable later when you're bleeding (critical). This teaches resource prioritization early.

### 8.3 Severity Calibration

The minor cut is the player's first injury. It establishes the baseline: this is what "not serious" looks like. When they later get a bleeding wound or poisoning, the contrast in symptoms (urgency, worsening, lethality) teaches them to read the `injuries` verb carefully.

---

## 9. Interaction with Other Systems

| System | Interaction |
|--------|-------------|
| **Blood writing** | A minor cut does NOT produce enough bleeding for blood writing. Only the `bleeding` injury enables that mechanic. |
| **Object handling** | Glass shard with `on_feel_effect: "cut"` triggers this injury. The injury formalization means the engine applies a real injury instance instead of just flavor text. |
| **Stacking** | Minor cut stacks with other injuries. Multiple minor cuts from different sources are tracked independently. |
| **GOAP** | GOAP should NOT auto-treat minor cuts. They heal naturally. This prevents the engine from wasting bandages on trivial injuries. |

---

## 10. Implementation Notes for Flanders

- **Template file:** `src/meta/injuries/minor-cut.lua`
- **FSM states:** `active`, `treated`, `healed`
- **Timers:** `active` state has `auto_heal_turns: 5`; `treated` state has `heal_turns: 2`
- **Treatment trigger:** Verb `bandage` or `apply bandage to hand` with item matching `healing.stops_minor_bleeding = true`
- **Infliction trigger:** Objects with `on_feel_effect: "cut"` or `on_take_effect: "cut"` produce this injury
- **Body location:** Defaults to `hand` (the part that touches)
- **Sensory overlay:** No sensory degradation (too minor). No capability restriction.

---

## 11. Design Rationale

The minor cut exists to **calibrate expectations**. It's the gentlest introduction to the injury system — it teaches:

1. Sharp objects hurt if handled carelessly
2. The `injuries` verb tells you what's wrong
3. Injuries have descriptions that hint at treatment
4. Some injuries heal on their own (don't panic)
5. Bandages exist and accelerate healing (but aren't always necessary)

Without the minor cut, the player's first injury experience might be bleeding or poison — both of which are urgent and potentially lethal. The minor cut provides a safe first encounter with the health system.
