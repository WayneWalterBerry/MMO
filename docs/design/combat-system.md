# Combat System

**File:** Design reference for game designers and players  
**Author:** Brockman (Documentation)  
**Date:** 2026-07-XX  
**Version:** 1.0 (GATE-6)

---

## Overview

The **Combat System** is a turn-based physical conflict engine that models weapon attacks, defensive responses, and material-based damage. It's designed for **tactical depth**: players must choose stances, manage weapons, and consider darkness when fighting creatures.

This document is for **game designers and advanced players**. For implementation details, see the architecture docs in `docs/architecture/combat/`.

---

## Core Mechanics

### The Combat Exchange

A **combat exchange** is a single round of attack and defense:

1. Both combatants determine **initiative** (who acts first)
2. Attacker **declares** weapon and target zone (or random)
3. Defender **chooses response** (block/dodge/counter/flee)
4. Engine **calculates damage** based on weapon material and body zone
5. **Narration** describes the outcome (varies by severity and light level)
6. **Health** is reduced and **injuries** are inflicted

After each exchange, the system checks for **interrupts** (weapon break, ineffective stance, critical health). Interrupts pause combat and re-prompt the player for new actions.

### Severity Levels

Combat results in 5 severity levels:

| Level | Health Loss | Example |
|-------|-------------|---------|
| **DEFLECT** | 0 | Glances off armor/skin |
| **GRAZE** | 1 | Light cut, minor bleeding |
| **HIT** | 3 | Moderate wound, significant bleeding |
| **SEVERE** | 6 | Deep wound, fracture, major trauma |
| **CRITICAL** | 10 | Vital organ damage, potentially fatal |

---

## The Stance System (Hybrid Auto-Resolve)

### Stance Types

Before combat begins, the player chooses a **stance** that governs both attack force and defense for the entire encounter:

| Stance | Attack | Defense | Use When |
|--------|--------|---------|----------|
| **Aggressive** | +30% | +30% | You want to end combat fast (but risk injury) |
| **Defensive** | -30% | -30% | You want to minimize damage (but prolong combat) |
| **Balanced** | —— | —— | You want normal combat (default) |

### Auto-Resolve Loop

Once you choose a stance, combat **auto-resolves** without per-round input:

1. **Prompt:** "Combat stance? > aggressive | defensive | balanced"
2. **Selection:** Type your stance
3. **Auto-loop:** Each round:
   - Both combatants attack based on stance + creature behavior
   - Narration describes the exchange
   - Health decreases for both sides
4. **Interrupt check:** If weapon breaks / stance ineffective 2+ rounds / critical health:
   - Combat **pauses**
   - **Re-prompt:** "Combat stance? > aggressive | defensive | balanced | flee | use [item]"
   - Player chooses new action or continues

**Headless mode:** Auto-selects "balanced" stance, never interrupts, runs to completion.

### Stance Modifiers

**Aggressive:**
- Attack force: 130% (more damage dealt)
- Defense: 130% (more damage resisted)
- Can counter on natural 20 (future skill)

**Defensive:**
- Attack force: 70% (less damage dealt)
- Defense: 70% (less damage resisted)
- Auto-dodge on natural 1 (future skill)

**Balanced:**
- No modifiers (default 100% / 100%)

---

## Weapon & Defense System

### Weapon Types

Weapons fall into three types, each penetrating differently:

| Type | Example | Property |
|------|---------|----------|
| **Edged** (slash) | Silver dagger, sword | Concentrates force with sharp edge → penetrates deep |
| **Pierce** (stab) | Spear, arrow | Focuses force on point → penetrates through layers |
| **Blunt** (impact) | Fist, club, hammer | Spreads force wide → more damage on contact, less penetration |

**Weapon stats:**
- `force` (1–10): Base attack power
- `type` (edged/pierce/blunt): Penetration model
- `material` (steel/bone/wood): Density affects force calculation
- `message` (verb): Narration text ("slashes", "punches", etc.)
- `two_handed` (boolean): Requires both hand slots

### Natural Weapons

Creatures have **natural weapons** (claws, teeth) instead of holding items:

**Rat natural weapons:**
- **Bite:** Pierce type, tooth-enamel material (force=2, sharp)
- **Claw:** Slash type, keratin material (force=1, raking)

**Player natural weapons:**
- **Punch:** Blunt type, bone material (force=2, fist impact)
- **Kick:** Blunt type, bone material (force=3, leg impact)

### Defensive Responses

When attacked, the defender chooses:

| Response | Effect | Risk |
|----------|--------|------|
| **Block** | Armor/shields absorb 70% | Tied to item/shields |
| **Dodge** | 40% chance to evade entirely | 60% fail still takes hit |
| **Counter** | Defend + hit back | Risky, takes return damage |
| **Flee** | Escape combat (50% success) | On fail: take extra damage, lose turn |
| **(Default)** | Stand and take it | Always hits, full damage |

---

## Body Zones & Anatomy

### Zone Structure

Each combatant has **body zones** with different sizes and damage consequences:

**Player anatomy:**
- **Head** (size 1, vital): Small target, vital organ protection
- **Torso** (size 4, vital): Large target, contains organs
- **Arms** (size 2): Medium target, weapon drop on severe damage
- **Legs** (size 2): Medium target, movement penalty on severe damage

**Rat anatomy:**
- **Head** (size 1, vital): Small target
- **Body** (size 3, vital): Large target
- **Legs** (size 2): Medium target
- **Tail** (size 1): Small target, balance loss on damage

### Zone Targeting

**Aimed attack (60% accuracy):**
- You can target a specific zone: `attack rat head`
- 60% chance: hits target zone
- 40% chance: misses, hits random adjacent zone instead

**Random attack:**
- No zone specified: `attack rat`
- Zone selected by **weighted probability** (larger zones more likely)
- All attacks default to random in **darkness**

### Tissue Layers

Each zone contains ordered **tissue layers** (outside-in):

| Layer | Armor | Hardness | Role |
|-------|-------|----------|------|
| **Skin/Hide** | Outer | Low | First defense |
| **Flesh** | Middle | Low | Muscle/fat |
| **Bone** | Structural | High | Skeleton, support |
| **Organ** | Vital | Very low | Heart, lungs, brain |

**Damage severity by deepest layer hit:**
- None penetrated → DEFLECT
- Skin/hide only → GRAZE
- Flesh → HIT
- Bone → SEVERE
- Organ → CRITICAL

---

## The Accuracy System

### Zone Accuracy (60%)

When you target a specific zone, you have **60% hit chance**:
- 60%: Hit target zone
- 40%: Miss, fall to random adjacent zone

**High-force weapons (force ≥ 7):** 100% accuracy (but this rarity is Phase 2)

### Darkness Modifier

In **darkness** (no light source), targeting is disabled:
- All attacks become **random zone selection**
- No accuracy bonus applies
- Narration uses sound/feel instead of visual

---

## Darkness Combat

Combat in darkness is **distinctly disadvantaged** for the player:

### Darkness Rules

| Aspect | Light | Dark |
|--------|-------|------|
| **Zone targeting** | Allowed (60%) | Disabled (random only) |
| **Narration** | Visual: "You see the steel blade bite into..." | Auditory/tactile: "A wet thud as the blade sinks..." |
| **Accuracy** | Normal (60%) | Random (0% control) |
| **Creature advantage** | Equal | Creature has advantage (better hearing/smell) |

### Dark Narration Examples

- DEFLECT: "You hear a sharp clack as the blade glances off in the dark."
- HIT: "A wet thud and sharp pain in your shoulder; the claws bite into flesh."
- CRITICAL: "A deep, wet squelch and a scream — the blow to your torso is fatal."

---

## Material System

### Weapon Materials

Each material has distinct damage properties:

| Material | Density | Hardness | Property | Weapon Example |
|----------|---------|----------|----------|-----------------|
| **Steel** | High | High | Sharp, dense, penetrating | Dagger (force=5) |
| **Bone** | Medium | High | Blunt/sharp, lightweight | Fist (force=2) |
| **Wood** | Low | Low | Blunt, flexible, weak | Club |
| **Tooth Enamel** | Very high | Very high | Sharp, brittle (rat bite) | Rat bite (force=2) |
| **Keratin** | Medium | Medium | Raking, sharp (claws) | Rat claw (force=1) |

### Tissue Materials

Each body tissue resists damage differently:

| Tissue | Armor | Flexibility | Fragility | Role |
|--------|-------|-------------|-----------|------|
| **Skin** | 1 | 0.7 | 0.6 | Outer layer (player) |
| **Hide** | 2 | 0.6 | 0.5 | Outer layer (creature) |
| **Flesh** | 1 | 0.8 | 0.7 | Muscle/fat (all) |
| **Bone** | 6 | 0.05 | 0.3 | Skeleton (all) |
| **Organ** | 0.5 | 0.9 | 0.8 | Vital systems (all) |

### Force Calculation

```
Base Force = weapon_material.density × attacker_size × weapon.force × stance_modifier × defense_modifier
```

**Example:** Player (medium) punches rat with aggressive stance:
```
base_force = 1900 (bone) × 2.0 (medium) × 2 (punch force) × 1.3 (aggressive) × 0.3 (if blocked)
           ≈ 29.6
```

---

## Injury System Integration

After combat damage is applied, injuries are **inflicted** based on severity and weapon type:

### Severity-to-Injury Mapping

**Edged weapons:**
- GRAZE → minor-cut
- HIT → bleeding (moderate)
- SEVERE → bleeding (heavy)
- CRITICAL → bleeding (critical)

**Pierce weapons:**
- GRAZE → minor-cut
- HIT → bleeding
- SEVERE → bleeding
- CRITICAL → bleeding

**Blunt weapons:**
- GRAZE → bruised
- HIT → bruised
- SEVERE → crushing-wound
- CRITICAL → crushing-wound

### Injury Effects

Injuries trigger consequences like:
- Movement speed reduction (leg damage)
- Weapon drop (arm damage)
- Bleeding damage over time (from cuts)
- Stunning/knockback (from blunt force)

---

## Combat Examples

### Example 1: Player vs Rat (Light, Silver Dagger)

Rat combat stats are sourced from `src/meta/creatures/rat.lua`.

```
1. INITIATE: Player (speed 4) vs Rat (speed 6) → Rat acts first
2. DECLARE: Rat chooses bite (pierce, force 2), targets arms
3. RESPOND: Player chooses block (0.3× defense)
4. RESOLVE: 
   - Rat bite penetrates: hide → flesh (HIT)
   - Damage: 1 (reduced by block)
   - Player takes 1 health, minor-cut injury
5. NARRATE: "The rat's teeth sink into your arm, but your guard absorbs most of the impact."
6. [Next round]
7. DECLARE: Player chooses dagger (edged, force 5), targets head
8. RESPOND: Rat chooses dodge (40% success: miss!)
9. RESOLVE: Dagger penetrates: hide → flesh → bone → organ (CRITICAL)
   - Damage: 10
   - Rat health: 0 → dead
10. NARRATE: "You plunge the silver dagger into the rat's head, hitting something vital."
11. Rat transitions to dead state, becomes portable
```

### Example 2: Combat in Darkness

```
1. INITIATE: Player (speed 4) vs Rat (speed 6) → Rat acts first
2. [No light source]
3. DECLARE: Player chooses bare fist, [attempts to target rat head]
4. RESOLVE: Zone targeting DISABLED in darkness → random zone selected (body)
   - Blunt force poor penetration: skin only (GRAZE)
   - Damage: 1
5. NARRATE: "In the dark, a dull thud at the rat's body; your punch doesn't bite."
```

### Example 3: Flee Mechanic

```
1. Combat starts, player stance: aggressive
2. [After 3 rounds] Rat critical health (< 30%) → triggers interrupt
3. Interrupt: "Stance ineffective — 2 consecutive misses!"
4. [Re-prompt] "Combat stance? > aggressive | defensive | balanced | flee"
5. Player types: "flee north"
6. Flee check: Player speed (4) vs Rat speed (6) + leg injury modifier
   - Fleeing: 55% success (speed check with injury penalty)
   - Success! Player moves north, combat ends with glancing blow
7. Damage: 3 (50% of normal, escape bonus)
```

---

## Interrupt Conditions

Combat **pauses and re-prompts** when:

1. **Weapon breaks** — Material fatigue during combat (Phase 2)
2. **Armor fails** — Damage penetrates armor for first time (Phase 2)
3. **Stance ineffective** — 2+ consecutive DEFLECT results (current)
4. **Critical health** — Your health drops below 30% (current)
5. **Creature flees** — Rat enters flee state from fear (current)
6. **New threats** — Another creature enters the room (Phase 2)
7. **Significant state change** — Light source extinguished (Phase 2)

On interrupt, player can:
- Change stance (aggressive/defensive/balanced)
- Flee (with speed check)
- Target specific zone (next round only)
- Use item (drink health potion, switch weapon)

---

## Light vs Dark Combat

### With Light

- **Zone targeting:** Enabled (60% accuracy)
- **Narration:** Visual detail ("steel blade", "flesh", exact zone)
- **Advantage:** Player can aim, see exact results
- **Disadvantage:** Creature visibility (Phase 2: they can see you too)

### Without Light

- **Zone targeting:** Disabled (all random)
- **Narration:** Auditory/tactile only ("wet thud", "sharp sting")
- **Advantage:** Harder for creatures to aim precisely
- **Disadvantage:** Player completely blind, all attacks random

**Strategic choice:** Light a candle before engaging dangerous creatures, or fight blind and hope for lucky hits.

---

## Death & Aftermath

When a combatant's health reaches 0:

1. **Death transition:** State changes to `dead`
2. **Death narration:** Custom description from creature's dead state
3. **Portability:** Dead body becomes pickup-able (can be taken like item)
4. **Stimulus:** Other creatures react (`creature_died` stimulus)
5. **Player experience:** Can examine, loot, or take dead creature

### Creature Death Example

```
You plunge the dagger deep; the rat convulses and goes still.
[The rat is dead.]
> examine rat
A small gray rat, now motionless on the cold stone floor.
```

---

## Phase 1 Scope

The current implementation (GATE-6, Phase 1) includes:

✅ **Implemented:**
- 5 severity levels (DEFLECT through CRITICAL)
- 3 weapon types (edged/pierce/blunt)
- Tissue penetration algorithm
- Zone targeting (60% accuracy, random fallback)
- Darkness disables targeting
- Material-based force calculation
- Stance system (aggressive/defensive/balanced)
- Auto-resolve loop with interrupts
- Creature death and state transitions
- Injury infliction (basic)
- Narration generation (5 severity levels × 2 light variants)

❌ **Phase 2 features:**
- Skill checks (luck/dexterity modifiers)
- Armor system (worn items reduce damage)
- Weapon durability & breakage
- Advanced creature AI (coordinated pack attacks)
- Status effects (bleeding, poison, stun)
- Special maneuvers (disarm, grapple, execute)
- Combat formations (multiple attackers)
- Environmental hazards in combat

---

## Design Principles

1. **Material realism:** Damage is based on physical properties (density, hardness)
2. **Tactical choice:** Stance selection and zone targeting require thought
3. **Consequences:** Darkness & injuries create strategic decisions
4. **Narrative variety:** No two combats produce identical text
5. **Creature agency:** Rats fight back with realistic behaviors

---

## See Also

- **Architecture:** `docs/architecture/combat/` — Implementation details
  - `body-zone-system.md` — Zone and tissue system
  - `combat-fsm.md` — 6-phase finite state machine
  - `damage-resolution.md` — Force & penetration math
  - `combat-narration.md` — Template generation
- **Design:** `docs/design/material-properties-system.md` — Material constants
- **NPC System:** `docs/design/npc-system.md` — Creature behavior
