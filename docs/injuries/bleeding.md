# Bleeding — Injury Reference

## Description

An over-time (DoT) injury from deep wounds. Health drains each turn until the player applies a bandage. Even after bandaging, the underlying wound needs time to heal — the bandage only stops the drain.

**GUID:** `{TBD — assigned during implementation}`

**Status:** Prototype exists (`bleed_ticks` in engine)

## Damage Pattern

| Property | Value |
|----------|-------|
| **Category** | Over-Time (DoT) |
| **Severity** | Medium — serious if untreated |
| **Health Impact** | Drains health each turn while `active` |
| **Drain Rate** | Moderate per-turn health reduction |
| **Worsens?** | Yes — untreated for 15+ turns cascades to `infection` (Level 2) |
| **Fatal?** | Yes — accumulated drain reaches zero = player dies |

## FSM States

```
     [inflicted]
         │
         ▼
   ┌──────────┐
   │  ACTIVE   │ ◄── injury starts here
   │ (bleeding)│     health drains each turn
   │           │
   └─────┬─────┘
         │
 ┌───────┴────────────────────┐
 │                            │
 ▼                            ▼
(bandage              (15 turns
 applied)              untreated)
 │                            │
 ▼                            ▼
┌──────────┐          ┌──────────┐
│ BANDAGED  │          │ INFECTED  │ ◄── cascades to infection
│           │          │ (Level 2) │
│ no drain  │          └──────────┘
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
| **Active** | Until bandaged or death | Yes — each turn | Blood trail in rooms; slippery hands (drop chance); affected limb impaired |
| **Bandaged** | 10 turns after bandage | No drain | Wound aches; affected limb still impaired but functional; no blood trail |
| **Healed** | Permanent (injury removed) | None | Scar remains (flavor); full function restored |
| **Infected** (cascade) | — | Worsening | See `infection` injury |

## Symptoms

| State | Description |
|-------|-------------|
| **Active (early)** | *"A deep gash in your arm. Blood flows freely — a slow but steady stream that won't stop on its own. You need something wrapped tight around it. Cloth. Pressure. Now."* |
| **Active (worsening, turn 5+)** | *"Blood drips steadily from the gash. Your sleeve is soaked crimson. You're getting lightheaded. This needs binding — urgently."* |
| **Active (critical, turn 10+)** | *"The world tilts. Blood pools at your feet. Your hands are numb and slippery. If you don't bind this wound, you're going to bleed out."* |
| **Active (hands bleeding)** | *"Blood makes your grip slippery. Objects feel uncertain in your hands."* |
| **Bandaged** | *"The bandage around your arm is holding. The bleeding has stopped, but the wound beneath is serious. It needs time to close."* |
| **Bandaged (reminder, turn 5+)** | *"Your bandaged arm aches deeply. Movement is painful, but the bandage holds. Give it time."* |
| **Healed** | *"The wound on your arm has closed, leaving an angry red scar. Full strength has returned."* |

## Treatment

### Correct Treatment — Two-Phase Recovery

**Step 1: Stop bleeding** — Apply bandage
| Item | Effect | Duration |
|------|--------|----------|
| **Cloth bandage** | Transitions `active → bandaged`. Health drain STOPS immediately. Bandage attaches (reusable). | — |

**Step 2: Heal wound** — Wait
| Item | Effect | Duration |
|-----|--------|----------|
| **Time (rest)** | Transitions `bandaged → healed`. No item needed. Wound heals naturally. | 10 turns |

**Bandage Lifecycle (Reusable):**
- Applying a bandage **attaches** it to the bleeding injury (moves from inventory to injury)
- While attached, bandage stops drain and accelerates healing (10 turns)
- Once healed, bandage enters `removable` state. Player types `remove bandage from [body part]` to recover it
- One bandage can be applied to multiple injuries sequentially (only one active use at a time)
- **A bandage can only treat ONE injury at a time**

### Targeted Treatment Examples

Single bleeding wound:
```
> apply bandage
"You wrap the cloth strip tightly around your wounded forearm.
 The bleeding slows... and stops. The bandage holds."
```

Multiple bleeding wounds (must specify):
```
> apply bandage to left arm
"You wrap the cloth strip tightly around the gash on your left arm.
 The bleeding slows... and stops."
```

Bandage already in use:
```
> apply bandage to right leg
"That bandage is already wrapped around your left arm wound.
 You'd need to remove it first."
```

### Partial/Alternative Treatments

| Item | Effect | Notes |
|------|--------|-------|
| **Cobweb** | Slows drain (weak bandage) | Buys time but doesn't stop bleeding fully |
| **Direct pressure (hand)** | Pauses drain for 1 turn | Emergency measure; can't do anything else while pressing |

### Wrong Treatments

| Item | Feedback |
|-----|----------|
| **Antidote** | *"You drink the antidote. It does nothing for the gash in your arm. The blood keeps flowing. This wound needs something physical — pressure, cloth, binding."* |
| **Water** | *"You pour water over the wound. The blood washes away briefly, then flows again. Cleaning it helps, but you still need to BIND it."* |
| **Salve** | *"You smear the salve over the gash. It stings, but the blood keeps coming. Ointment can't stop this — you need pressure."* |
| **Potion/wine** | *"The warmth feels good going down, but the gash in your arm still bleeds. You can't drink your way out of this."* |

## Body Location

Inherited from cause (arm for dagger, hand for glass, leg for fall)

## Causes

| Source | Context |
|--------|---------|
| Silver dagger | Falling onto or being stabbed by dagger |
| Glass shard | Aggressive handling or falling onto broken glass |
| Sharp surface fall | Falling from height onto debris |
| Weapon attack | Future: NPC or trap inflicts slashing damage |

## Stacking — Multiple Bleeding Wounds

Two independent bleeds stack their drains:
```
Stab wound on left arm:  drains 2 health/turn
Gash on right leg:       drains 2 health/turn
Combined drain: 4 health/turn (survival time HALVED)
```

Player sees:
```
> injuries
"You examine yourself:
 — A deep stab wound on your left arm (bleeding). Blood flows
   from the gash.
 — A deep gash on your right leg (bleeding). Blood runs down
   into your boot.
 
 Two wounds bleeding. You're losing blood from both — faster
 than either alone. You need bandages. More than one."
```

**Triage scenario (one bandage, two wounds):** Player must prioritize which wound to treat first. Once one is bandaged, use time to rest and heal before treating the second.

## Implementation Details

- **Template file:** `src/meta/injuries/bleeding.lua`
- **FSM states:** `active`, `bandaged`, `healed` (plus cascade trigger to `infection` at turn 15)
- **Timers:** 
  - `active` has per-turn drain tick
  - `bandaged` has `heal_turns: 10`
  - Cascade check at turn 15
- **Treatment trigger:** Verb `bandage` or `apply [cloth/bandage] to [body_part]` with item matching `healing.stops_bleeding = true`
- **Drain mechanic:** Each turn in `active` reduces health by fixed amount (defined in injury metadata)
- **Blood trail:** Set `player.state.bloody = true` in `active`; clear in `bandaged`
- **Slippery hands:** In `active` state, handled objects have drop chance (probability in metadata)
- **Extends existing `bleed_ticks`:** This formalizes the prototype

## Interactions with Other Systems

| System | Effect |
|--------|--------|
| **Blood writing** | Active bleeding enables the `write with blood` mechanic (costs health) |
| **Infection cascade** | Untreated 15+ turns triggers `infection` injury (Level 2) |
| **Stacking** | Multiple bleeds compound drain rate |
| **Room descriptions** | While bleeding, enter text includes blood narrative overlay |
| **GOAP** | Should NOT auto-bandage. Can auto-tear cloth if needed. |
| **`player.state.bloody`** | Set to true while active; cleared when bandaged |
| **Grip system** | Slippery hands increase drop chance |

## Death Sequence

If health reaches zero:
```
"Your vision narrows to a dark tunnel. The cold stone beneath you
is the last thing you feel. The bleeding never stopped.

A bandage — even a torn strip of cloth — could have saved you.
The blanket on the bed. The curtains on the window. Anything
wrapped tight around the wound.

You bled out in the [room name]."
```
