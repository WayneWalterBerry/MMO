# Combat System Design Plan

**Author:** Comic Book Guy (Creative Director / Design Department Lead)  
**Date:** 2026-07-28  
**Status:** Design Proposal — Awaiting Wayne Approval  
**Requested By:** Wayne "Effe" Berry  
**Design Philosophy:** Dwarf Fortress physics + MTG structured phases + text IF narrative  

**Wayne's Combat Directives:**
- **D-COMBAT-1:** 4–6 body zones (head, torso, arms, legs), NOT Dwarf Fortress's 200 parts
- **D-COMBAT-2:** MTG combat phases embedded as engine-driven FSM/metadata, NOT player-operated turns
- **D-COMBAT-3:** Body zones = armor equipment slots (one unified system)
- **D-COMBAT-4:** Every creature has `body_tree` in its .lua metadata
- **D-COMBAT-5:** NPC plan needs body_tree requirement update

---

## Table of Contents

1. [Summary](#1-summary)
2. [Design Principles](#2-design-principles)
3. [Body Zone System](#3-body-zone-system)
4. [Combat Phases (MTG-Inspired)](#4-combat-phases-mtg-inspired)
5. [Damage & Materials](#5-damage--materials)
6. [Injury Integration](#6-injury-integration)
7. [Creature Combat Metadata](#7-creature-combat-metadata)
8. [Player Combat](#8-player-combat)
9. [NPC-vs-NPC Combat](#9-npc-vs-npc-combat)
10. [Disease & Status Effects](#10-disease--status-effects)
11. [Implementation Phases](#11-implementation-phases)
12. [Who Does What](#12-who-does-what)
13. [Open Questions](#13-open-questions)

---

## 1. Summary

This document defines the combat system for the MMO text adventure engine. Combat resolves through **material physics** (Dwarf Fortress), **structured engine-driven phases** (Magic: The Gathering), and **narrative-first text output** (interactive fiction tradition). Every creature — player, rat, wolf, guard — exposes an identical `body_tree` and combat metadata table. The engine resolves all combat through one unified function: weapon material × force vs. armor material + tissue properties → body zone hit → injury/mutation. There are no hit points, no damage numbers on screen, no abstract stats. A steel dagger cuts flesh because steel is harder than flesh. A ceramic pot on your head cracks when struck because ceramic has high fragility. The player always has a meaningful response choice — block, dodge, counterattack, use item, flee — and combat narration is generated from structured results, never scripted per-creature. Wayne's five combat directives (D-COMBAT-1 through D-COMBAT-5) are foundational constraints: 4–6 body zones, MTG phases as engine FSM, body zones unified with armor slots, `body_tree` on every creature, and NPC plan updated accordingly.

---

## 2. Design Principles

### Principle C1: Material Physics, Not Abstract Stats

> "Steel cuts flesh. Always. The question is HOW MUCH damage, not WHETHER damage occurs."

Damage emerges from the physical interaction of weapon material, armor material, and tissue material — exactly how Dwarf Fortress works, exactly how our existing 17+ material system already operates. No `attack_power = 5` on weapons. No `defense = 3` on armor. The engine compares material properties (hardness, density, shear resistance, edge quality) and the result is a severity level. A wooden club against iron armor bruises through impact transfer. An obsidian knife against bare flesh cuts deep because obsidian has extreme edge quality. The same material system that determines whether a pot shatters when dropped determines whether armor cracks when struck.

**This is Principle 9 (material consistency) applied to combat.** Steel behaves like steel everywhere — in crafting, in environmental interaction, in combat. No special-case combat stats.

### Principle C2: Unified Combatant Interface

> "The engine doesn't know if it's processing a dragon or a kitten."

Every creature — player, rat, cat, guard — uses the same combat resolution function. There is no `resolve_player_combat()` vs `resolve_npc_combat()`. One function: `resolve_exchange(attacker, defender, weapon, target_zone)`. The combatant's `body_tree` + `combat` metadata provides all the data the engine needs. The player's response phase presents choices to the human; an NPC's response phase runs through its `combat.behavior` metadata. Same engine, different input source.

**This is Principle 8 (engine executes metadata).** No rat-specific code, no wolf-specific code, no player-specific code in the combat engine.

### Principle C3: Every Attack Tells a Story

> "In text IF, 'You hit the rat for 3 damage' repeated 5 times is unbearable."

Combat narration is generated from structured resolution results, not scripted per-creature. Each exchange produces: `{attacker, action_verb, target, body_zone, severity, material_interaction}`. The text engine formats this into prose that varies by severity, material, and body zone. A steel sword cutting a rat's flank reads differently from a wooden club bruising a rat's head. Severity scales the description from "grazes" to "tears through" to "severs." The material vocabulary comes from the material registry — "denting iron," "tearing leather," "fracturing bone," "shattering glass."

**Repetition is death in text IF.** The narration template system ensures no two identical-looking combat outputs, even for the same weapon/target combination.

### Principle C4: Meaningful Choices Every Exchange

> "No successful combat system automates combat entirely."

Every combat exchange presents the player with a genuine decision where no option is always correct:

- **Attack** — deal damage, but you're exposed to the counterattack
- **Block** (requires shield/armor in hand) — reduce incoming damage by shield material properties
- **Dodge** — chance to avoid entirely, but costs your next attack action
- **Counterattack** (requires weapon) — trade taking the hit for a simultaneous strike
- **Use item** — throw a flask, deploy a tool, apply a consumable
- **Flee** — attempt to leave the room; may fail; costs your defensive stance

The player's choice creates divergent outcomes. There is no "spam attack to win" strategy.

### Principle C5: Deterministic Core, Bounded Variance

> "If the player doesn't understand why they missed, combat feels arbitrary."

The core resolution is deterministic: steel cuts flesh, always. Variance enters through two bounded channels:

1. **Hit zone selection** — weighted by zone size (torso most likely, head rare). The player can target a specific zone at reduced accuracy, or let the engine pick at full accuracy.
2. **Attack quality** — the player's choice (aggressive/cautious/desperate) modifies force applied. Aggressive = more force, less defense. Cautious = less force, better defense.

There are no misses against stationary targets. A sword swung at a rat connects — the question is WHERE and HOW HARD. This eliminates the "whiff problem" (five consecutive misses killing pacing) that plagues D&D-derived systems.

### Principle C6: Combat Has a Clock

> "Gloomhaven's card exhaustion. Our existing consumable light sources. Combat must end."

Fights don't last forever. Natural time pressure comes from:

- **Weapon durability** — weapons degrade through use (Principle 9: materials have fragility)
- **Light sources** — candles and matches burn down during combat; darkness impairs accuracy
- **Injury accumulation** — untreated wounds tick damage per turn (existing injury system)
- **Creature morale** — NPC flee thresholds cause withdrawal; player stress effects limit options

Every combat resource is depletable. The optimal player strategy is to end fights quickly, not to turtle.

### Principle C7: Code Mutation IS Combat State Change (D-14)

When a rat dies in combat, the engine doesn't set `rat.alive = false`. The engine **mutates the rat object** — `rat.lua` becomes `dead-rat.lua` at runtime. When a shield cracks from blocking a mace, the shield object mutates from `iron-shield.lua` to `iron-shield-cracked.lua`. The code IS the state. This is D-14 applied to combat outcomes — the same mutation system that turns `mirror.lua` into `mirror-broken.lua` turns `rat.lua` into `dead-rat.lua`.

---

## 3. Body Zone System

### 3.1 Overview (D-COMBAT-1, D-COMBAT-3, D-COMBAT-4)

Wayne's directives are crystal clear: **4–6 body zones, unified with armor slots, declared as `body_tree` in every creature's `.lua` metadata.** This section defines the canonical body zone system.

### 3.2 The Five Standard Zones

The human/humanoid body uses **5 zones**. This is the sweet spot — enough granularity for tactical targeting and armor slot variety, simple enough for text IF pacing.

| Zone | Size Weight | Vital? | Armor Slot | Injury Consequences |
|------|------------|--------|------------|---------------------|
| **head** | 1 (10%) | Yes | head (helmet, pot, spittoon) | Concussion, unconsciousness, death |
| **torso** | 4 (40%) | Yes | torso (breastplate, vest, cloak) | Organ damage, bleeding, death |
| **arms** | 2 (20%) | No | arms (bracers, gloves, sleeves) | Weapon drop, reduced attack, inability to use tools |
| **legs** | 2 (20%) | No | legs (greaves, boots, trousers) | Reduced movement, can't flee, prone |
| **tail** | 1 (10%) | No | — (creatures only) | Balance loss, cosmetic (rats) |

**Size weight** determines hit probability when no specific zone is targeted. A random attack hits the torso 40% of the time, head 10%, etc. This matches physical intuition — your torso is the biggest target.

**Vital zones** (head, torso) can cause death when injury severity reaches critical. Non-vital zones cause debilitation but not death.

**Armor slots are body zones.** This is D-COMBAT-3. There is no separate "equipment slot" system and "body zone" system. The `wear.slot` on an armor object directly corresponds to the `body_tree` zone it protects. A `wear = { slot = "head" }` ceramic pot protects the `head` zone. One system, not two.

### 3.3 Creature Zone Variations

Not every creature has the same zones. The `body_tree` declares what a creature actually has:

| Creature | Zones | Notes |
|----------|-------|-------|
| **Player** | head, torso, arms, legs | Standard humanoid |
| **Rat** | head, body, legs, tail | No separate arms; "body" = torso equivalent |
| **Cat** | head, body, legs, tail | Same as rat, different size/tissue |
| **Wolf** | head, body, legs | No tail zone (tail is not a meaningful combat target) |
| **Spider** | body, legs | No head zone (cephalothorax is "body"); many legs |
| **Snake** | head, body | Just two zones: head and everything else |
| **Humanoid NPC** | head, torso, arms, legs | Same as player |

The engine doesn't hardcode zone lists. It reads the `body_tree` from the creature's metadata. A spider with `body_tree = { body = {...}, legs = {...} }` is resolved the same way as a player with 5 zones — just fewer zones to target.

### 3.4 The `body_tree` Format (D-COMBAT-4)

Every creature's `.lua` file includes a `body_tree` table. This is the authoritative declaration of the creature's physical structure:

```lua
-- Player body_tree
body_tree = {
    head = {
        size = 1,
        vital = true,
        tissue = { "skin", "flesh", "bone" },
        natural_armor = nil,
    },
    torso = {
        size = 4,
        vital = true,
        tissue = { "skin", "flesh", "bone", "organ" },
        natural_armor = nil,
    },
    arms = {
        size = 2,
        vital = false,
        tissue = { "skin", "flesh", "bone" },
        natural_armor = nil,
        on_damage = { "weapon_drop", "reduced_attack" },
    },
    legs = {
        size = 2,
        vital = false,
        tissue = { "skin", "flesh", "bone" },
        natural_armor = nil,
        on_damage = { "reduced_movement", "prone" },
    },
},
```

```lua
-- Rat body_tree
body_tree = {
    head = {
        size = 1,
        vital = true,
        tissue = { "hide", "flesh", "bone" },
        natural_armor = nil,
    },
    body = {
        size = 3,
        vital = true,
        tissue = { "hide", "flesh", "bone", "organ" },
        natural_armor = nil,
    },
    legs = {
        size = 2,
        vital = false,
        tissue = { "hide", "flesh", "bone" },
        natural_armor = nil,
        on_damage = { "reduced_movement" },
    },
    tail = {
        size = 1,
        vital = false,
        tissue = { "hide", "flesh" },
        natural_armor = nil,
        on_damage = { "balance_loss" },
    },
},
```

### 3.5 `body_tree` Field Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `size` | number | Yes | Relative size weight for hit probability. Sum of all zone sizes determines probability distribution. |
| `vital` | boolean | Yes | If `true`, critical injuries to this zone can cause death. |
| `tissue` | array | Yes | Ordered from outermost to innermost. Each tissue type references a material in the material registry. Damage penetrates from outer to inner. |
| `natural_armor` | string/nil | No | Material name for natural protection (e.g., `"chitin"` for insects, `"scales"` for reptiles). Evaluated before worn armor. |
| `on_damage` | array/nil | No | List of debuff effect IDs triggered when this zone takes meaningful damage. Resolved by the effects pipeline. |

### 3.6 Tissue Layers

Each tissue type maps to a material with combat properties:

| Tissue | Material | Shear Resistance | Impact Resistance | Notes |
|--------|----------|-----------------|-------------------|-------|
| `skin` | skin | Low | Low | Human skin; easily cut, easily bruised |
| `hide` | hide | Medium-Low | Medium-Low | Animal hide; tougher than skin |
| `flesh` | flesh | Very Low | Very Low | Muscle/fat; offers little resistance |
| `bone` | bone | High | Medium | Stops most cuts; can fracture from impact |
| `organ` | organ | Very Low | Very Low | Protected by bone; damage here is critical |
| `chitin` | chitin | Medium | Medium-High | Insect exoskeleton; natural armor |
| `scales` | scales | Medium-High | Medium | Reptile scales; resists slashing |

The engine resolves damage by walking the tissue array from outermost inward. A sword strike to a rat's body: `hide` (shear check) → `flesh` (shear check) → `bone` (shear check) → `organ` (if bone penetrated). Each layer absorbs force proportional to its material's resistance. The attack continues inward until force is exhausted or all layers are penetrated.

### 3.7 Armor Integration (D-COMBAT-3)

When the player wears armor on a zone, the armor's material is evaluated **before** the tissue layers:

```
Attack → [worn armor material] → [natural armor, if any] → skin → flesh → bone → organ
```

Example: Player wearing a ceramic pot on `head`, hit by a mace:

1. **Ceramic pot** (hardness 7, fragility 0.7): absorbs impact, but — fragility check — the pot **cracks** (FSM transition: intact → cracked). Some force passes through.
2. **Skin**: remaining force bruises skin (impact resistance exceeded).
3. **Flesh**: remaining force bruises flesh.
4. **Bone (skull)**: remaining force compared to bone's impact resistance → if exceeded, **concussion** injury.

The armor system design doc (`docs/design/armor-system.md`) already defines the `wear = { slot, layer, coverage, fit }` metadata and the material → protection derivation pipeline. Combat uses this exact pipeline. `coverage` (0.0–1.0) determines the probability that armor catches the hit; `fit` (makeshift/fitted/masterwork) applies a protection multiplier. **No new armor system needed — combat plugs into the existing one.**

### 3.8 NPC Plan Update (D-COMBAT-5)

The NPC system plan (`plans/npc-system-plan.md`) currently uses a single `health` number and defers body parts to Phase 4. Wayne's D-COMBAT-5 directive requires updating it:

**Change required:** The creature template and rat specification must include `body_tree`. The NPC plan's Section 10 ("What We Deliberately Omit") listed "body part simulation" as skipped for Phases 1–3. This override replaces that row:

> ~~Body part simulation — Phase 4~~ → **`body_tree` is required on all creatures from Phase 1. See combat-system-plan.md Section 3.**

The `body_tree` does NOT replace `health` / `max_health` on creatures. Health remains derived (Principle: `max_health - sum(injury.damage)`). The `body_tree` determines WHERE injuries land and what DEBUFFS they cause, while the injury system's existing damage accumulation determines overall health. Both systems coexist.

---

## 4. Combat Phases (MTG-Inspired)

<!-- STUB — to be filled -->

---

## 5. Damage & Materials

<!-- STUB — to be filled -->

---

## 6. Injury Integration

<!-- STUB — to be filled -->

---

## 7. Creature Combat Metadata

<!-- STUB — to be filled -->

---

## 8. Player Combat

<!-- STUB — to be filled -->

---

## 9. NPC-vs-NPC Combat

<!-- STUB — to be filled -->

---

## 10. Disease & Status Effects

<!-- STUB — to be filled -->

---

## 11. Implementation Phases

<!-- STUB — to be filled -->

---

## 12. Who Does What

<!-- STUB — to be filled -->

---

## 13. Open Questions

<!-- STUB — to be filled -->
