# Bleeding

**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-07-25  
**Status:** 🟡 Prototype exists (`bleed_ticks` in engine)  
**Level:** 1  
**GUID:** `{TBD — assigned during implementation}`  
**Cross-Ref:** [injury-catalog.md §2.4](../player/injury-catalog.md), [healing-items.md](../player/healing-items.md), [health-system.md](../player/health-system.md)

---

## 1. Overview

Bleeding is the first **over-time (damage-over-time)** injury the player encounters. Unlike the minor cut, bleeding does NOT stop on its own. Health drains each turn until the player applies a bandage. Even after bandaging, the underlying wound needs time to heal — the bandage only *stops the bleeding*, it doesn't *heal the wound*.

This two-phase recovery (stop bleeding → wait for healing) is the core mechanical lesson: **treatment and healing are separate steps**.

---

## 2. Cause(s)

| Trigger | Object | Context |
|---------|--------|---------|
| **Deep cut from dagger** | `silver-dagger` | Falling onto the dagger, or knife trap |
| **Severe glass wound** | `glass-shard` | Aggressive handling or falling onto broken glass |
| **Fall onto sharp surface** | *(environmental)* | Falling from height onto debris in cellar/crypt |
| **Weapon attack** | *(future: combat)* | NPC or trap inflicts slashing damage |

**Level 1 Primary Source:** The silver dagger in the crypt (Puzzle 014) or a fall in the deep cellar. The glass shard causes a minor cut by default — bleeding requires a deeper wound (forced contact, not casual handling).

---

## 3. Damage Pattern

| Type | Value |
|------|-------|
| **Category** | Over-Time (DoT) |
| **Severity** | Medium — serious if untreated |
| **Health Impact** | Drains health each turn while `active` |
| **Drain Rate** | Moderate per-turn health reduction |
| **Worsens?** | Yes — if untreated for 15+ turns, cascades to `infection` (Level 2 injury) |
| **Fatal?** | Yes — if the accumulated health drain reaches zero, the player dies |

---

## 4. FSM States

```
         [inflicted]
             │
             ▼
       ┌──────────┐
       │  ACTIVE   │ ◄── injury starts here
       │ (bleeding)│     health drains each turn
       │           │     blood trail, slippery hands
       └─────┬─────┘
             │
     ┌───────┴────────────────────┐
     │                            │
     ▼                            ▼
  (bandage                  (15 turns
   applied)                  untreated)
     │                            │
     ▼                            ▼
┌──────────┐              ┌──────────┐
│ BANDAGED  │              │ INFECTED  │ ◄── cascades to
│           │              │ (Level 2) │     infection injury
│ no drain  │              └──────────┘
│ wound     │
│ still     │
│ present   │
└─────┬─────┘
      │
   (10 turns
    of rest)
      │
      ▼
┌──────────┐
│  HEALED   │ ◄── injury removed
└──────────┘
```

| State | Duration | Health Drain | Mechanical Effect |
|-------|----------|-------------|-------------------|
| **Active** | Until bandaged or death | Yes — each turn | Blood trail left in rooms; slippery hands (drop chance on handled objects); affected limb impaired |
| **Bandaged** | 10 turns after bandage | No drain | Wound aches; affected limb still impaired but functional; no blood trail |
| **Healed** | Permanent (injury removed) | None | Scar remains (flavor); full function restored |
| **Infected** (cascade) | See `infection` injury | Worsening | Fever, confusion — requires different treatment entirely |

---

## 5. Symptoms (`injuries` verb output)

| State | Player Sees |
|-------|-------------|
| **Active (early)** | *"A deep gash in your arm. Blood flows freely — a slow but steady stream that won't stop on its own. You need something wrapped tight around it. Cloth. Pressure. Now."* |
| **Active (worsening, turn 5+)** | *"Blood drips steadily from the gash. Your sleeve is soaked crimson. You're getting lightheaded. This needs binding — urgently."* |
| **Active (critical, turn 10+)** | *"The world tilts. Blood pools at your feet. Your hands are numb and slippery. If you don't bind this wound, you're going to bleed out."* |
| **Active (hands bleeding)** | *"Blood makes your grip slippery. Objects feel uncertain in your hands."* |
| **Bandaged** | *"The bandage around your arm is holding. The bleeding has stopped, but the wound beneath is serious. It needs time to close."* |
| **Bandaged (reminder, turn 5+)** | *"Your bandaged arm aches deeply. Movement is painful, but the bandage holds. Give it time."* |
| **Healed** | *"The wound on your arm has closed, leaving an angry red scar. Full strength has returned."* |

---

## 6. Treatment

### 6.1 Correct Treatment

| Step | Item | Effect | How Obtained (Level 1) |
|------|------|--------|----------------------|
| **Step 1: Stop bleeding** | **Cloth bandage** | Transitions `active → bandaged`. Health drain STOPS. | Tear blanket, curtains, or wool-cloak → cloth strip → bandage |
| **Step 2: Heal wound** | **Time (rest)** | Transitions `bandaged → healed` after 10 turns. No item needed. | Wait. The wound heals naturally once the bleeding is stopped. |

**Critical Design Point:** The bandage does NOT heal the wound. It only stops the drain. The player still carries the injury (impaired limb, aching) until natural healing completes. This prevents the bandage from being a "full heal" button.

### 6.2 Alternative Treatments

| Item | Effect | Notes |
|------|--------|-------|
| **Cobweb** | Stops minor bleeding only. For a deep wound, cobweb slows the drain but doesn't fully stop it. | Cobweb = weak bandage. Buys time, not a cure. |
| **Direct pressure (hand)** | Pauses drain for 1 turn if player has a free hand. | Emergency measure — can't do anything else while pressing. |

### 6.3 Wrong Treatments

| Item Tried | What Happens | Feedback Message |
|------------|-------------|------------------|
| **Antidote** | No effect. Item consumed/wasted. | *"You drink the antidote. It does nothing for the gash in your arm. The blood keeps flowing. This wound needs something physical — pressure, cloth, binding."* |
| **Water** | Cleans wound but doesn't stop bleeding. | *"You pour water over the wound. The blood washes away briefly, then flows again. Cleaning it helps, but you still need to BIND it."* |
| **Salve** | No effect on bleeding. | *"You smear the salve over the gash. It stings, but the blood keeps coming. Ointment can't stop this — you need pressure."* |
| **Potion/wine** | No effect on the wound. | *"The warmth feels good going down, but the gash in your arm still bleeds. You can't drink your way out of this. Something physical. Tight."* |

---

## 7. Discovery Clues

How the player figures out the treatment:

1. **Injury description is explicit:** Every `active` state description mentions "wrapped tight," "cloth," "pressure," "binding," or "bind" — physical action words pointing to bandage.
2. **Escalating urgency:** Descriptions get more desperate each turn ("now" → "urgently" → "bleed out"). This teaches: over-time injuries are time-sensitive.
3. **Blood trail:** The player sees *"You notice blood on the floor behind you"* when moving between rooms. This is a sensory cue that something is actively wrong.
4. **Slippery hands:** Dropping an object with *"Your bloody hands lose their grip on the [object]"* — mechanical feedback reinforcing the injury.
5. **Object clue (blanket):** Examining the blanket: *"A heavy wool blanket. Threadbare in places — you could tear strips from it."* → cloth → bandage chain.
6. **Contrast with minor cut:** If the player already had a minor cut (self-healed), bleeding's escalation ("won't stop on its own") clearly signals different severity.

---

## 8. Puzzle Uses

### 8.1 The Ticking Clock (Primary Pattern)

**Setup:** Player gets a deep wound (dagger trap, fall).  
**Clock:** Health drains each turn.  
**Puzzle:** Find cloth material → tear into strips → apply bandage. Bandage-able cloth may be 2 rooms away.  
**Tension:** Every command counts. Moving costs a turn. Examining costs a turn. The drain is relentless.  
**Resolution:** Bandage applied → drain stops → player survives with injury.

### 8.2 Resource Discovery Under Pressure

**Setup:** Player is bleeding and has no bandage.  
**Puzzle:** What in the environment can become a bandage?  
**Options:** Tear blanket (bed), tear curtains (window), tear wool-cloak (wardrobe), tear sack material.  
**Lesson:** Everyday objects have emergency medical uses. The player learns to see cloth as a resource, not decoration.

### 8.3 The Capability Gate

**Setup:** Bleeding from arm wound → arm impaired.  
**Gate:** Cannot climb, cannot lift heavy objects, grip is unreliable.  
**Puzzle:** Must bandage arm before attempting physical challenges (climbing the well, lifting a crate lid, pulling a lever).  
**Alternative:** Find a path that doesn't require the impaired action.

### 8.4 The Resource Tension Dilemma

**Setup:** Player has one piece of cloth. They're bleeding AND they need cloth for another puzzle (rope, sewing, fire bundle).  
**Dilemma:** Use cloth for bandage (survive) or save cloth for puzzle (risk death)?  
**Design:** There should always be enough cloth sources in Level 1, but the player doesn't KNOW that. The tension is psychological.

### 8.5 Blood Trail as Clue

**Setup:** Player bleeds while exploring.  
**Mechanic:** Blood trail left in rooms.  
**Puzzle use (future):** NPCs or creatures can follow blood trails. Or: the player's own blood trail helps them retrace their path in a maze.

---

## 9. Interaction with Other Systems

| System | Interaction |
|--------|-------------|
| **Blood writing** | Active bleeding enables the `write with blood` mechanic. The player's injury becomes a tool — but using it costs health (continued bleeding while writing). Strategic choice. |
| **Infection cascade** | Untreated bleeding for 15+ turns triggers `infection` injury (Level 2). The wound isn't just draining — it's getting dirty. This cascading makes ignoring the injury increasingly dangerous. |
| **Injury stacking** | Bleeding stacks with other injuries. Multiple bleeding wounds compound the drain rate. Two active bleeds = twice the urgency. |
| **Room descriptions** | While bleeding, room enter text includes: *"Blood drips from your arm onto the cold stone floor."* This is a per-room sensory overlay. |
| **GOAP** | GOAP should NOT auto-bandage. The player must choose to treat. However, GOAP CAN auto-tear cloth if the player says "bandage arm" and has no bandage but has cloth. The mechanical preparation is GOAP territory; the decision to treat is the player's. |
| **`player.state.bloody`** | Existing engine state. Bleeding injury sets `player.state.bloody = true`. Cleared when bandaged. Other systems can check this flag. |

---

## 10. Death Sequence (if untreated)

If health reaches zero from bleeding:

```
"Your vision narrows to a dark tunnel. The cold stone beneath you
is the last thing you feel. The bleeding never stopped.

A bandage — even a torn strip of cloth — could have saved you.
The blanket on the bed. The curtains on the window. Anything
wrapped tight around the wound.

You bled out in the [room name]."
```

**Design Note:** The death text names the treatment (bandage/cloth) and hints at sources (blanket, curtains). On replay, the player knows WHAT to look for and WHERE to find it.

---

## 11. Implementation Notes for Flanders

- **Template file:** `src/meta/injuries/bleeding.lua`
- **FSM states:** `active`, `bandaged`, `healed` (plus cascade trigger to `infection` at turn 15)
- **Timers:** `active` has per-turn drain tick; `bandaged` has `heal_turns: 10`; cascade check at turn 15
- **Treatment trigger:** Verb `bandage` or `apply [cloth/bandage] to [body_part]` with item matching `healing.stops_bleeding = true`
- **Drain mechanic:** Each turn in `active` state reduces health by a fixed amount. Amount defined in injury metadata, not engine.
- **Blood trail:** Set `player.state.bloody = true` in `active`; clear in `bandaged`. Room enter handler checks this flag for blood-trail text.
- **Slippery hands:** In `active` state, handled objects have a drop chance per interaction. Probability defined in injury metadata.
- **Body location:** Inherited from cause (arm for dagger, hand for glass, leg for fall).
- **Extends existing `bleed_ticks`:** This injury formalizes the prototype. The `bleed_ticks` counter becomes the `active` state timer.

---

## 12. Design Rationale

Bleeding is the **gateway over-time injury**. It teaches three critical lessons:

1. **Some injuries don't heal on their own** — contrast with minor cut
2. **Treatment ≠ healing** — bandage stops the drain but doesn't remove the injury
3. **Time pressure is real** — the first injury where every turn matters

The two-phase recovery (bandage → rest → healed) is the foundational pattern for all serious injuries. Master this, and the player understands the health system.
