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

### 4.1 Overview (D-COMBAT-2)

Wayne's directive: **MTG combat phases embedded as engine-driven FSM/metadata, NOT player-operated turns.** This means the phase progression is an FSM managed by the engine — the player doesn't manually advance through "declare attackers," "declare blockers," etc. The engine drives the phase sequence; the player makes choices at designated decision points within that sequence.

Think of it this way: MTG's 5-step combat phase happens every turn regardless of what the player does. The player's agency exists WITHIN the phase structure, not over it. Our combat FSM advances automatically; the player fills in the decision blanks.

### 4.2 The Combat Exchange FSM

Each combat exchange (one attack-response cycle) follows this 6-phase FSM:

```
┌─────────────┐
│ 1. INITIATE │ ── engine determines turn order (speed-based)
└──────┬──────┘
       ↓
┌─────────────┐
│ 2. DECLARE  │ ── attacker commits to an action (attack, grapple, ability)
└──────┬──────┘    For NPCs: engine reads combat.behavior metadata
       │           For player (on their turn): player chooses action + target zone
       ↓
┌─────────────┐
│ 3. RESPOND  │ ── defender reacts (block, dodge, counter, flee, use item)
└──────┬──────┘    For NPCs: engine reads combat.behavior.defense metadata
       │           For player (when attacked): player chooses response
       ↓
┌─────────────┐
│ 4. RESOLVE  │ ── engine calculates material interaction
└──────┬──────┘    weapon material × force vs. armor + tissue layers
       │           result = severity (miss/deflect/graze/hit/critical)
       │           zone = targeted or random-weighted from body_tree
       ↓
┌─────────────┐
│ 5. NARRATE  │ ── engine generates text from structured result
└──────┬──────┘    template: "{actor} {verb} {target}'s {zone}, {result_description}"
       │           severity scales vocabulary
       ↓
┌─────────────┐
│ 6. UPDATE   │ ── apply injuries, check morale, check death, trigger mutations
└─────────────┘    injury → body zone debuffs
                   death → creature mutation (alive → dead)
                   morale check → possible flee transition
```

### 4.3 Phase Details

#### Phase 1: INITIATE

**What happens:** The engine determines who acts first this exchange.

**Resolution:** Compare combatant `combat.speed` values. Faster creature acts first. On ties, smaller creature acts first (rats are quicker than humans). If still tied, the player acts first (home-field advantage in a text adventure).

**MTG parallel:** This is the "beginning of combat" step. Both combatants are committed to fighting — the question is who strikes first.

**Engine FSM state:** `combat_state = "initiate"`

**Player input:** None. The engine resolves initiative and narrates: *"The rat is faster — it lunges first!"* or *"You have the reach advantage — you strike first."*

#### Phase 2: DECLARE (Attacker's Action)

**What happens:** The attacker commits to an action and (optionally) a target zone.

**If attacker is NPC:** The engine reads `combat.behavior.attack_pattern` metadata to select an action. A rat with `attack_pattern = "bite"` always bites. A wolf with `attack_pattern = { "bite", "lunge", "claw" }` selects based on current state and target condition. No NPC-specific code — the engine evaluates the pattern metadata generically.

**If attacker is player:** The engine prompts:

```
The rat backs against the wall, hissing. What do you do?
> attack rat            (swing weapon at random zone)
> attack rat head       (target specific zone — harder to hit)
> throw flask at rat    (ranged attack with held item)
> flee north            (attempt to disengage and leave)
```

**MTG parallel:** This is "declare attackers." The attacker commits resources — in our case, the action and target. Once declared, it can't be changed (the swing is in motion).

**Engine FSM state:** `combat_state = "declare"`

#### Phase 3: RESPOND (Defender's Reaction)

**What happens:** After the attacker commits, the defender chooses a response. This is the critical player agency moment.

**If defender is NPC:** The engine reads `combat.behavior.defense` metadata. A rat's defense is `"dodge"` (small, fast). A wolf's defense might be `"counter"` (aggressive). A turtle's defense is `"shell"` (natural armor). Resolved entirely from metadata.

**If defender is player (being attacked):** The engine prompts:

```
The rat lunges at your hand, teeth bared!
> block          (requires shield/armor in hand — reduces damage)
> dodge          (agility check — avoid entirely, lose next attack)
> counter        (requires weapon — take the hit, strike simultaneously)
> use flask      (use held item — throw, apply, deploy)
> flee south     (attempt escape — may fail, takes full damage)
```

**MTG parallel:** This is "declare blockers" + the response window for combat tricks. The defender sees the attack and reacts. This is where combat tricks (items-as-instants) live.

**Engine FSM state:** `combat_state = "respond"`

**Key design:** The player ALWAYS gets a response choice, even when attacked. This ensures agency in every exchange, even when the creature has initiative.

#### Phase 4: RESOLVE (Material Calculation)

**What happens:** The engine compares attacker's weapon material + force against defender's armor material + tissue layers.

**Inputs:**
- `weapon`: material properties (hardness, density, edge quality) + weapon type (edged, blunt, pierce)
- `force`: base force from creature size × attack quality modifier from player choice
- `target_zone`: player-chosen or random-weighted from `body_tree` sizes
- `armor`: worn armor on target zone (if any) — material + coverage + fit
- `tissue`: tissue layers from `body_tree[zone].tissue` array
- `defense_modifier`: defender's response choice modifies incoming damage

**Resolution algorithm:**

```
1. Zone selection:
   - If player targeted specific zone: hit probability = 60% (general) or zone-specific
   - If random: weight by body_tree zone sizes, select randomly
   
2. Coverage check (armor):
   - Roll against armor.coverage (0.0–1.0)
   - If hit lands on covered area: armor material absorbs first
   - If hit lands on gap: skip armor, go straight to tissue

3. Layer penetration (Dwarf Fortress model):
   - For each layer (armor → natural_armor → tissue[1] → tissue[2] → ...):
     - Compare attack force × weapon shear/impact vs. layer material resistance
     - If attack exceeds resistance: penetrate, reduce force, continue inward
     - If attack doesn't exceed: stopped at this layer
   
4. Severity determination:
   - No penetration beyond armor: DEFLECT ("The blade glances off your steel helm.")
   - Skin only: GRAZE ("A shallow scratch across your forearm.")
   - Flesh: HIT ("The blade cuts deep into your shoulder muscle.")
   - Bone: SEVERE ("A sickening crack — the bone fractures.")
   - Organ: CRITICAL ("The blade pierces your gut. Blood everywhere.")

5. Defense modifier application:
   - Block: damage × 0.3 (shield absorbs 70%, but shield takes degradation)
   - Dodge (success): damage × 0.0 (avoided entirely)
   - Dodge (failure): damage × 1.0 (full hit — dodging is all-or-nothing)
   - Counter: damage × 1.0 (take full hit, but attacker also takes your hit)
   - Flee (success): damage × 0.5 (glancing blow as you turn to run)
   - Flee (failure): damage × 1.2 (caught off-balance, worse than standing)
```

**Engine FSM state:** `combat_state = "resolve"`

#### Phase 5: NARRATE (Text Generation)

**What happens:** The structured resolution result is formatted into prose.

**Narration template:**

```
{attacker_name} {action_verb} {target_name}'s {body_zone}, {result_description}!
```

**Severity-scaled vocabulary:**

| Severity | Edged Verbs | Blunt Verbs | Result Templates |
|----------|-------------|-------------|------------------|
| DEFLECT | glances off | bounces off | "{armor_material} holds. No damage." |
| GRAZE | nicks, scratches | grazes, brushes | "a thin red line across the {tissue}" |
| HIT | cuts, slashes, stabs | cracks, strikes, pounds | "cutting into the {tissue}, drawing blood" |
| SEVERE | tears through, hacks | shatters, crushes, smashes | "fracturing the {bone}, {limb_effect}" |
| CRITICAL | severs, eviscerates | pulverizes, destroys | "a fatal wound to the {organ}" |

**Examples:**

- DEFLECT: *"You swing the dagger at the rat's body — the blade catches a rib and deflects. The rat squeals but is unharmed."*
- GRAZE: *"Your dagger grazes the rat's flank, parting the fur and drawing a thin line of blood."*
- HIT: *"The dagger sinks into the rat's body, cutting through hide and into the flesh beneath. The rat shrieks."*
- CRITICAL: *"Your dagger plunges into the rat's body and finds something vital. The rat spasms, goes rigid, and collapses."*

**Engine FSM state:** `combat_state = "narrate"`

#### Phase 6: UPDATE (State Changes)

**What happens:** The engine applies all state changes from the resolution.

**Actions:**
1. **Inflict injury** on the target via `injuries.inflict()` — type determined by severity + zone + damage type (bleeding, bruised, crushing-wound, concussion, etc.)
2. **Apply zone debuffs** from `body_tree[zone].on_damage` — weapon drop (arms), reduced movement (legs), etc.
3. **Check morale** — compare cumulative damage to `combat.behavior.flee_threshold`. If exceeded, NPC transitions to fleeing state.
4. **Check death** — `injuries.compute_health(target)` ≤ 0 AND vital zone hit → death. Trigger creature mutation (alive → dead).
5. **Degrade equipment** — attacked armor gets fragility check. Shield used to block gets fragility check. Weapon used to attack gets fragility check (future Phase 3).
6. **Emit stimuli** — `creature_attacked`, `creature_injured`, `creature_died` stimuli for nearby creatures to react to.

**Engine FSM state:** `combat_state = "update"` → transitions back to `"initiate"` for next exchange, or to `"ended"` if combat is over.

### 4.4 Combat FSM Metadata Format

The combat state machine is declared as engine-level metadata, not per-creature. This is a single FSM definition that the engine uses for ALL combat:

```lua
-- engine/combat/phases.lua (metadata, not handler code)
return {
    id = "combat-exchange",
    initial_state = "initiate",
    states = {
        initiate = { next = "declare", auto = true },
        declare  = { next = "respond", requires_input = "attacker" },
        respond  = { next = "resolve", requires_input = "defender" },
        resolve  = { next = "narrate", auto = true },
        narrate  = { next = "update",  auto = true },
        update   = { next = "initiate", auto = true, 
                     exit_condition = "combat_over" },
    },
    exit_states = { "ended", "fled", "dead" },
}
```

The engine drives this FSM. At `declare` and `respond`, it checks whether the relevant combatant is the player (prompt for input) or an NPC (read metadata). All other phases are automatic. This is D-COMBAT-2: **MTG phases as engine-driven FSM.**

### 4.5 Multi-Exchange Combat Flow

A full combat encounter is a series of exchanges:

```
COMBAT START
  ↓
Exchange 1: rat attacks (initiative: rat is faster)
  INITIATE → DECLARE (rat bites hand) → RESPOND (player: dodge?) 
  → RESOLVE → NARRATE → UPDATE
  ↓
Exchange 2: player attacks (player's turn)
  INITIATE → DECLARE (player: attack rat body) → RESPOND (rat: dodge)
  → RESOLVE → NARRATE → UPDATE
  ↓
Exchange 3: rat attacks (rat still alive, still aggressive)
  ... (repeat until combat ends)
  ↓
COMBAT END (rat flees / rat dies / player flees / player dies)
```

Each exchange is one cycle of the 6-phase FSM. The engine loops until an exit condition triggers: combatant death, successful flee, morale break, or external interruption.

### 4.6 Speed and Pacing

**Exchanges per round:** Each round consists of one exchange per combatant, in initiative order. A player vs. rat round = 2 exchanges (rat attacks, then player attacks, or vice versa based on speed).

**Text pacing:** Each exchange produces 2–4 sentences of narration. A round takes ~10–15 seconds to read. This creates the "implicit pacing" advantage of text IF — dramatic tension through reading time, not artificial timers.

**Round limit:** Combat encounters should not exceed 5–8 rounds against a single creature. If combat drags past this, something is wrong with the balance. The material physics should ensure that wielded weapons resolve fights quickly against appropriately-sized targets.

---

## 5. Damage & Materials

### 5.1 Material Combat Properties

Our existing material registry has 11 properties per material. Combat requires extending 4 of these with combat-specific semantics and adding 2 new properties:

| Property | Existing? | Combat Use |
|----------|-----------|------------|
| `hardness` | ✅ Yes | Resistance to deformation. Higher hardness = harder to cut through (shear resistance). Steel 9, ceramic 7, wood 4, flesh 1. |
| `density` | ✅ Yes | Mass per volume. Affects weapon momentum (heavier = more blunt force). Lead 11340, steel 7800, wood 500, flesh 1050. |
| `fragility` | ✅ Yes | Likelihood of structural failure on impact. Ceramic 0.7 (cracks easily), brass 0.1 (dents, never breaks), steel 0.15. |
| `flexibility` | ✅ Yes | Ability to bend without breaking. Leather 0.9 (absorbs blunt force by flexing), steel 0.1, ceramic 0.0. |
| `shear_yield` | 🆕 New | Force required to begin cutting. Materials with high shear_yield resist edged weapons. Derived from hardness for Phase 1. |
| `max_edge` | 🆕 New | Maximum sharpness achievable. Obsidian 10 (sharper than steel), steel 8, copper 5, wood 1, bone 3. Determines edged weapon effectiveness. |

**Phase 1 simplification:** For Phase 1, `shear_yield` can be derived from `hardness` (shear_yield ≈ hardness × 1000). The explicit property exists for Phase 2+ when nuanced material interactions matter (e.g., obsidian has low hardness but extreme edge quality).

### 5.2 Weapon Types and Damage Modes

Weapons don't declare "slashing damage" as an abstract type. The weapon's physical shape determines how force is applied:

| Weapon Type | Force Application | Effective Against | Weak Against |
|-------------|-------------------|-------------------|--------------|
| **Edged** (sword, dagger, axe) | Concentrated force on thin edge; shears material | Unarmored flesh, leather, hide | Hard armor (metal, stone) |
| **Blunt** (mace, club, hammer) | Distributed force over broad area; transfers momentum | Hard armor (force passes through), bone | Flexible armor (leather absorbs) |
| **Pierce** (spear, arrow, fang) | Concentrated force on point; penetrates layers | Gaps in armor, chain mail links | Solid plate armor, thick bone |

**How this works in practice:**

- **Steel dagger (edged) vs. bare rat:** Dagger's max_edge (8) × force vs. hide's shear_yield (low) → cuts through easily. Flesh offers less resistance. High severity.
- **Wooden club (blunt) vs. armored player:** Wood's density (500) × velocity → moderate momentum. Ceramic pot's hardness (7) absorbs the edge force, but momentum transfers through → bruising beneath armor. The pot doesn't crack (blunt, not edged).
- **Rat bite (pierce) vs. leather glove:** Tooth enamel's max_edge (moderate) vs. leather's hardness (3) → teeth struggle to penetrate. Bite is partially blocked. Shallow wound.

### 5.3 The Damage Resolution Formula

```
FORCE = weapon_density × attack_size_modifier × quality_modifier
   where:
     attack_size_modifier = attacker creature size (tiny=0.5, small=1, medium=2, large=4, huge=8)
     quality_modifier = player choice (aggressive=1.3, standard=1.0, cautious=0.7)

For each layer from outer to inner (armor → natural_armor → tissue[0] → tissue[1] → ...):
  
  IF weapon is edged or pierce:
    penetration = (FORCE × weapon.max_edge) - (layer.hardness × layer_thickness)
    IF penetration > 0:
      FORCE = penetration  -- reduced force continues inward
    ELSE:
      STOP -- weapon cannot cut this layer
      
  IF weapon is blunt:
    transfer = FORCE × (1.0 - layer.flexibility)
    layer_damage = transfer - (layer.hardness × layer_thickness × 0.5)
    FORCE = transfer × 0.8  -- blunt force transfers through at 80%
    -- Blunt weapons don't "stop" — force propagates through all layers
    -- But each layer absorbs some energy

SEVERITY = map force_remaining to severity tiers:
  0         → DEFLECT (no penetration)
  1-20%     → GRAZE  (superficial)
  21-50%    → HIT    (meaningful wound)
  51-80%    → SEVERE (structural damage: fracture, deep cut)
  81-100%+  → CRITICAL (organ damage, potential death)
```

### 5.4 Material Interaction Examples

**Steel sword vs. unarmored rat (edged):**
```
FORCE = 7800 (steel density) × 0.5 (tiny attacker... no, PLAYER is attacking)
       Actually: FORCE = 7800 × 2.0 (medium player) × 1.0 (standard) = 15600
Layer 1: hide (hardness ~2, shear_yield ~2000): 15600 × 8 (max_edge) - 2000 = 122800. Penetrate.
Layer 2: flesh (hardness 1, shear_yield ~1000): trivially penetrated.
Layer 3: bone (hardness 6, shear_yield ~6000): 15600 × 8 - 6000 = substantial. Penetrate.
Layer 4: organ: penetrated. CRITICAL.
Result: The rat dies in one hit. Steel sword vs. tiny unarmored creature = instant kill.
```

**Rat bite vs. player's bare hand (pierce):**
```
FORCE = 1050 (tooth enamel density) × 0.5 (tiny rat) × 1.0 = 525
Layer 1: skin (hardness 1, shear_yield ~1000): 525 × 4 (tooth edge) - 1000 = 1100. Penetrate.
Layer 2: flesh: penetrated.
Layer 3: bone: 525 × 4 - 6000 = negative. STOPPED at bone.
Severity: HIT (penetrated skin and flesh, stopped at bone).
Result: "The rat sinks its teeth into your hand, piercing skin and drawing blood."
Injury: minor-cut or bleeding (location: hand/arms zone).
```

**Wooden club vs. ceramic pot on head (blunt):**
```
FORCE = 500 (wood density) × 2.0 (medium player) × 1.0 = 1000
Layer 1: ceramic pot (hardness 7, flexibility 0.0): 
  transfer = 1000 × (1.0 - 0.0) = 1000 (ceramic is rigid, full transfer)
  fragility check: ceramic fragility 0.7 vs. force → HIGH probability of cracking
  pot cracks (FSM: intact → cracked)
  FORCE continues at 800 (80% transfer)
Layer 2: skin: blunt impact → bruise
Layer 3: bone (skull): 800 × 0.8 - (6 × thick × 0.5) → possible concussion
Result: "The club crashes against the pot — CRACK — ceramic shards fly. Your head rings."
Injuries: concussion (head zone), pot mutation (intact → cracked).
```

### 5.5 Size Asymmetry

Creature size dramatically affects combat outcomes through the force calculation:

| Size | Force Modifier | Examples | Combat Implications |
|------|---------------|----------|---------------------|
| tiny | 0.5 | rat, spider, bat | Can barely damage armored targets; overwhelmed by larger creatures |
| small | 1.0 | cat, dog, child | Meaningful damage to unarmored; struggles against heavy armor |
| medium | 2.0 | human, wolf, deer | Standard combatant; equipment is the differentiator |
| large | 4.0 | bear, horse, ogre | Devastating force; can damage through heavy armor |
| huge | 8.0 | elephant, dragon | One-hit potential against anything smaller; nearly unstoppable |

**The equipment equalizer:** A naked human vs. a wolf is a losing fight (wolf has natural weapons + speed). A human with a steel spear and leather armor vs. a wolf is an even fight. A human with a steel sword and iron breastplate vs. a wolf wins decisively. **This reinforces the 2-hand inventory system's strategic importance** — what you carry into combat determines whether you live.

### 5.6 Natural Weapons

Creatures declare natural weapons in their `combat` metadata. Natural weapons are resolved using the same material system as crafted weapons:

| Natural Weapon | Material | Type | Typical Force | Found On |
|----------------|----------|------|---------------|----------|
| bite (rodent) | tooth_enamel | pierce | Very low | Rat, mouse |
| bite (canine) | tooth_enamel | pierce | Medium | Wolf, dog |
| claw (small) | keratin | slash | Low | Cat, rat |
| claw (large) | keratin | slash | High | Bear, wolf |
| hoof/kick | bone | blunt | High | Horse, deer |
| sting | chitin | pierce | Low | Spider, scorpion |
| constrict | flesh | blunt | Variable (size-dependent) | Snake |

The engine doesn't know about "bite" or "claw" as special categories. It knows: this attack uses `tooth_enamel` material with `pierce` type at force level X. The material system resolves the rest.

---

## 6. Injury Integration

### 6.1 How Combat Feeds the Existing Injury System

The injury system (`src/engine/injuries.lua`) already handles:
- Infliction with body location (`injuries.inflict(player, type, source, location)`)
- Per-turn ticking with damage accumulation
- FSM state progression (active → worsened → critical → fatal)
- Healing via treatment objects (bandages, poultices)
- Health as derived value (`max_health - sum(injury.damage)`)

**Combat plugs directly into this system.** The Phase 4 (RESOLVE) output maps to an `injuries.inflict()` call:

```lua
-- In the combat resolution engine:
local severity = resolve_exchange(attacker, defender, weapon, zone)

if severity >= SEVERITY.GRAZE then
    local injury_type = map_severity_to_injury(severity, weapon_type, zone)
    local damage = calculate_injury_damage(severity, force_remaining)
    injuries.inflict(target, injury_type, weapon.id, zone.id, damage)
end
```

### 6.2 Severity → Injury Type Mapping

| Severity | Edged Weapon | Blunt Weapon | Pierce Weapon |
|----------|-------------|-------------|---------------|
| GRAZE | minor-cut | bruised | minor-cut |
| HIT | bleeding | bruised | bleeding |
| SEVERE | bleeding (high damage) | crushing-wound | bleeding (high damage) |
| CRITICAL (non-vital) | bleeding (critical) | crushing-wound (critical) | bleeding (critical) |
| CRITICAL (vital: head) | concussion → death | concussion → death | concussion → death |
| CRITICAL (vital: torso) | bleeding (fatal) | crushing-wound (fatal) | bleeding (fatal) |

All 7 existing injury types are already defined in `src/meta/injuries/`:

| Injury Type | Combat Source | Notes |
|-------------|--------------|-------|
| `bleeding` | Edged/pierce wounds | Over-time damage; needs bandage treatment |
| `bruised` | Blunt impacts, falls | Instant damage; auto-heals over time |
| `burn` | Fire sources (torch, oil) | Not typical combat, but possible with fire weapons |
| `concussion` | Head zone blunt/severe hits | Impairs vision, causes confusion |
| `crushing-wound` | Blunt weapons at high force | Structural damage; slow healing |
| `minor-cut` | Grazing edged/pierce hits | Low damage; auto-heals quickly |
| `poisoned-nightshade` | Poison weapons (future) | See Section 10: Disease & Status Effects |

### 6.3 Zone-Specific Injury Effects

Body zone debuffs are applied alongside the injury when `body_tree[zone].on_damage` is defined:

| Zone | Debuff | Mechanical Effect |
|------|--------|-------------------|
| **head** (SEVERE+) | `concussion` | Impaired accuracy, disorientation narration, possible unconsciousness |
| **arms** (HIT+) | `weapon_drop` | Chance to drop held weapon; reduced attack force until healed |
| **arms** (SEVERE+) | `reduced_attack` | Attack force halved; cannot use two-handed weapons |
| **legs** (HIT+) | `reduced_movement` | Cannot run; flee attempts auto-fail |
| **legs** (SEVERE+) | `prone` | Knocked down; must spend an action to stand; all attacks against you hit more easily |
| **tail** (HIT+) | `balance_loss` | NPC only: reduced dodge chance |

These debuffs are implemented as **effects** processed by the existing effects pipeline (`src/engine/effects.lua`). No new subsystem needed — the combat engine emits effect events that the effects pipeline handles.

### 6.4 Death and Mutation

**Player death:** When `injuries.compute_health(player) ≤ 0` and at least one injury was from an external source (not self-inflicted), the player dies. The existing injury tick already checks this. Combat simply generates the injuries; the injury system handles the death check.

**Creature death:** When a creature's health reaches 0 from combat damage:

1. The creature's FSM transitions to `dead` state (existing FSM engine handles this via the `{ from = "*", to = "dead", condition = "health_zero" }` transition already defined in the rat spec).
2. The creature object **mutates** (D-14): `rat.lua` metadata is rewritten to `dead` state, setting `animate = false`, `portable = true`, updating all sensory descriptions to dead variants.
3. The creature emits a `creature_died` stimulus for nearby creatures to react to.

**No new death system is needed.** The existing FSM transition + mutation + injury health-check chain handles creature death. Combat is just the input that triggers the chain.

### 6.5 Injury Stacking from Combat

Multiple combat exchanges can stack injuries:

- Exchange 1: rat bites player's hand → `minor-cut` on arms zone
- Exchange 2: rat bites again → `bleeding` on arms zone (second, more serious wound)
- Exchange 3: player fails to block → `bruised` on torso zone

Each injury is a separate instance with its own damage, FSM state, and tick behavior. The player accumulates damage from multiple wounds simultaneously. This creates the natural "attrition clock" — even winning a fight has costs.

Treatment after combat becomes a puzzle: multiple wounds competing for limited healing resources (bandages, poultices). The injury system's existing `resolve_target()` function already handles player targeting of specific injuries. Combat doesn't change this — it just creates more injuries to manage.

---

## 7. Creature Combat Metadata

### 7.1 The `combat` Table

Every creature that can participate in combat declares a `combat` table in its `.lua` metadata. This is the single source of truth for all combat behavior — the engine reads it generically (Principle 8).

```lua
combat = {
    -- Core stats
    size = "tiny",              -- force multiplier (tiny/small/medium/large/huge)
    speed = 6,                  -- initiative value (1=slow, 10=fastest)
    
    -- Natural weapons
    natural_weapons = {
        {
            id = "bite",
            type = "pierce",            -- edged | blunt | pierce
            material = "tooth_enamel",  -- material registry lookup
            zone = "head",              -- which body zone the weapon is on
            force = 2,                  -- base force (before size modifier)
            target_pref = "arms",       -- preferred target zone (or nil for random)
            message = "bites",          -- narration verb
        },
        {
            id = "claw",
            type = "slash",
            material = "keratin",
            zone = "legs",
            force = 1,
            target_pref = nil,
            message = "claws at",
        },
    },
    
    -- Natural armor (chitin, scales, thick hide — or nil for none)
    natural_armor = nil,
    
    -- Behavior in combat (engine evaluates this, not creature-specific code)
    behavior = {
        aggression = "on_provoke",      -- when to initiate combat:
                                        --   "on_sight" = attacks immediately
                                        --   "on_provoke" = attacks when attacked
                                        --   "never" = flees, never fights back
                                        --   "territorial" = attacks if in home room
        
        flee_threshold = 0.3,           -- flee when health drops below 30% of max
        
        attack_pattern = "random",      -- how to select from natural_weapons:
                                        --   "random" = pick randomly each exchange
                                        --   "cycle" = use weapons in order
                                        --   "strongest" = always use highest force
                                        --   specific weapon id = always use that weapon
        
        defense = "dodge",              -- default defensive response:
                                        --   "dodge" = attempt to evade (small/fast)
                                        --   "block" = stand ground (large/armored)
                                        --   "counter" = hit back (aggressive)
                                        --   "flee" = always try to run
        
        target_priority = "random",     -- who to attack when multiple targets:
                                        --   "random" = pick randomly
                                        --   "closest" = nearest target
                                        --   "weakest" = most injured target
                                        --   "threatening" = whoever attacked last
        
        pack_size = 1,                  -- how many of this creature fight together
                                        --   (Phase 2+: pack tactics)
    },
},
```

### 7.2 Rat Combat Metadata (Complete)

Combining the rat's existing NPC spec with combat data:

```lua
-- Rat combat metadata (added to existing rat.lua definition)
combat = {
    size = "tiny",
    speed = 6,                  -- fast for their size (rats are quick)
    
    natural_weapons = {
        {
            id = "bite",
            type = "pierce",
            material = "tooth_enamel",
            zone = "head",
            force = 2,
            target_pref = "arms",       -- rats go for hands/fingers
            message = "sinks its teeth into",
        },
        {
            id = "claw",
            type = "slash",
            material = "keratin",
            zone = "legs",
            force = 1,
            target_pref = nil,
            message = "rakes its claws across",
        },
    },
    
    natural_armor = nil,                -- rats have no natural armor
    
    behavior = {
        aggression = "on_provoke",      -- rat only fights when attacked first
        flee_threshold = 0.3,           -- flees at 30% health (cowardly)
        attack_pattern = "random",
        defense = "dodge",              -- rats dodge, not block
        target_priority = "threatening",-- attacks whoever attacked it
        pack_size = 1,
    },
},
```

### 7.3 Additional Creature Examples

**Wolf (Phase 2 creature):**

```lua
combat = {
    size = "small",
    speed = 7,
    natural_weapons = {
        {
            id = "bite",
            type = "pierce",
            material = "tooth_enamel",
            zone = "head",
            force = 6,
            target_pref = "arms",       -- go for limbs to bring down prey
            message = "lunges and clamps its jaws on",
        },
        {
            id = "claw",
            type = "slash",
            material = "keratin",
            zone = "legs",
            force = 3,
            target_pref = "legs",
            message = "rakes",
        },
    },
    natural_armor = nil,
    behavior = {
        aggression = "on_sight",        -- wolves are aggressive predators
        flee_threshold = 0.2,           -- wolves are braver than rats
        attack_pattern = "cycle",       -- bite, then claw, then bite...
        defense = "counter",            -- wolves fight back, don't dodge
        target_priority = "weakest",    -- pack mentality: target the wounded
        pack_size = 3,                  -- wolves hunt in packs
    },
},
```

**Giant Spider (Phase 2 creature):**

```lua
combat = {
    size = "small",
    speed = 4,                          -- spiders are ambush predators, not fast
    natural_weapons = {
        {
            id = "bite",
            type = "pierce",
            material = "chitin",        -- chelicerae (spider fangs)
            zone = "head",
            force = 3,
            target_pref = nil,
            message = "strikes with fanged mandibles at",
            on_hit = { inflict = "spider-venom" },  -- poison delivery
        },
    },
    natural_armor = "chitin",           -- exoskeleton provides armor
    behavior = {
        aggression = "territorial",     -- attacks in its web/lair
        flee_threshold = 0.5,           -- flees when half-dead
        attack_pattern = "strongest",
        defense = "dodge",
        target_priority = "closest",
        pack_size = 1,
    },
},
```

### 7.4 Player Combat Metadata

The player also has combat metadata — declared in the player model, not in a creature file:

```lua
-- Player combat metadata (in player model)
combat = {
    size = "medium",
    speed = 4,                          -- human baseline
    natural_weapons = {
        {
            id = "punch",
            type = "blunt",
            material = "bone",          -- fist = knuckle bones
            zone = "arms",
            force = 2,
            target_pref = nil,
            message = "punches",
        },
        {
            id = "kick",
            type = "blunt",
            material = "bone",
            zone = "legs",
            force = 3,
            target_pref = nil,
            message = "kicks",
        },
    },
    natural_armor = nil,
    -- Player combat behavior is driven by player input, not metadata
    -- The engine presents choices rather than evaluating behavior tables
},
```

When the player holds a weapon, the weapon's combat properties override natural weapons. When unarmed, the player fights with `punch` and `kick`. **The 2-hand inventory system determines available weapons.**

### 7.5 Weapon Object Combat Metadata

Crafted/found weapons add combat properties to their object definition:

```lua
-- Example: a dagger
return {
    id = "iron-dagger",
    material = "iron",
    -- ... standard object fields ...
    
    combat = {
        type = "edged",                 -- edged | blunt | pierce
        force = 5,                      -- base force
        -- material comes from the object's existing material field
        -- max_edge comes from the material registry
        -- density comes from the material registry
        message = "slashes",            -- narration verb
        two_handed = false,             -- requires one hand or two?
    },
}
```

**No `attack_power` property.** The weapon's combat effectiveness is derived from its material (hardness, density, max_edge) + its type (edged/blunt/pierce) + its force value. The same iron dagger is equally effective whether it's in a drawer or in the player's hand — the material doesn't change. What changes is that holding it enables combat use.

---

## 8. Player Combat

### 8.1 Entering Combat

Combat begins through one of these triggers:

| Trigger | Example | Who Acts First |
|---------|---------|----------------|
| **Player attacks creature** | `attack rat`, `hit rat with dagger`, `throw rock at rat` | Player (they initiated) |
| **Creature aggression** | Wolf has `aggression = "on_sight"`, player enters room | Creature (they detected player) |
| **Provocation** | Player kicks rat, rat's `reactions.player_attacks` triggers fight | Player started it, but rat may be faster (speed check) |
| **Territorial defense** | Player enters spider's lair, spider has `aggression = "territorial"` | Creature (home advantage) |

**The transition into combat is seamless.** There's no "combat mode" that changes the game interface. The player types `attack rat` just like `look rat` or `take candle`. The parser resolves the verb, the verb handler initiates the combat exchange FSM, and the engine runs the phases. When combat ends, normal play resumes. This is text IF, not a JRPG with a battle screen transition.

### 8.2 Player Verb Interface

Combat uses existing and new verbs. The parser resolves these through the same 5-tier pipeline as all other commands:

| Verb | Syntax | Effect |
|------|--------|--------|
| `attack` / `hit` / `strike` / `swing` | `attack rat`, `hit rat with dagger` | Initiate melee attack; weapon inferred from held items |
| `attack [zone]` | `attack rat head`, `strike rat legs` | Targeted attack at specific body zone (reduced hit probability) |
| `throw` | `throw rock at rat`, `throw flask at spider` | Ranged attack; consumes the thrown object |
| `block` | `block` (during RESPOND phase) | Defensive response; requires shield/armor in hand |
| `dodge` | `dodge` (during RESPOND phase) | Defensive response; agility check, lose next attack |
| `counter` | `counter` (during RESPOND phase) | Defensive response; take hit, deliver simultaneous strike |
| `flee` | `flee`, `flee north`, `run` | Attempt to disengage and leave; may fail; costs defense |
| `use [item]` | `use flask`, `throw sand` | Combat trick; use held item during combat |

### 8.3 The Two-Hand Constraint in Combat

The player has exactly 2 hand slots. What you're carrying determines your combat options:

| Left Hand | Right Hand | Combat Options |
|-----------|------------|----------------|
| Sword | Shield | Attack (sword), Block (shield), Dodge, Flee |
| Sword | Dagger | Attack (sword OR dagger), Counter (dual wield), Dodge, Flee |
| Torch | Sword | Attack (sword), Use torch (light/fire), Dodge, Flee — no block |
| Nothing | Nothing | Punch, Kick, Dodge, Flee — no block, low damage |
| Flask of oil | Dagger | Attack (dagger), Throw flask (ranged, fire source), Dodge, Flee |
| Bandage | Sword | Attack (sword), Use bandage (heal mid-combat), Dodge, Flee |

**Strategic pre-combat preparation:** Before entering a dangerous room, the player should consider what to hold. Carrying a torch provides light (can see the enemy) but occupies a hand slot. Carrying a shield provides defense but can't hold a second weapon. This is the 2-hand inventory system earning its design weight — every combat encounter is partially decided by the player's pre-fight loadout.

**Mid-combat item switching:** Picking up or dropping items during combat costs an action. You can't attack AND swap weapons in the same exchange. If a rat bites your arm and you drop your weapon (`on_damage: weapon_drop`), retrieving it costs your next attack. This creates real consequences for zone-targeted injuries.

### 8.4 Targeted vs. Random Attacks

The player can attack with or without targeting a specific body zone:

**Random targeting:** `attack rat` — the engine selects a zone weighted by `body_tree` size values. Torso (largest) is most likely. No accuracy penalty.

**Targeted attack:** `attack rat head` — the player aims for a specific zone. This has a reduced hit probability (60% instead of 100% for random). On miss (40%), the attack hits a random adjacent zone instead. The tradeoff: targeting the head can cause a concussion/instant kill, but you might miss and hit the body instead.

**Why targeting matters:**
- Targeting a vital zone (head) is high-risk, high-reward — possible instant kill
- Targeting legs can cripple the creature's ability to flee
- Targeting arms (on humanoids) can cause weapon drop
- Random is reliable but less strategic

### 8.5 Combat in Darkness

The game starts at 2 AM — total darkness. Combat in darkness has special rules:

| Condition | Effect |
|-----------|--------|
| **No light source** | Player cannot target specific zones; all attacks are random. Cannot see creature state. Narration uses sound/feel: *"You hear scrabbling claws and swing blindly."* |
| **Player has light** | Normal combat; can see and target. Light source occupies a hand slot (torch = 1 hand). |
| **Creature has no eyes** | (Future: blind creatures) Not affected by darkness. |

**Darkness as tactical element:** A rat in a dark room is harder to fight — you can't target, you can't see its injuries, you don't know if it's flanking you. Lighting a candle before combat is a strategic choice: it reveals the battlefield but consumes a match and occupies a hand or surface.

**Sensory narration in darkness:** Combat narration shifts from visual to auditory/tactile:
- Light: *"You slash the rat across its flank — blood spatters the flagstones."*
- Dark: *"Your blade connects with something — a wet impact, a shrill squeal. You feel warm blood on your fingers."*

This directly leverages the existing multi-sensory system (Principle 6). The `on_feel` and `on_listen` descriptions on creature states inform dark-mode combat narration.

### 8.6 Flee Mechanics

Fleeing is a genuine risk/reward decision, never a free escape:

1. **Player declares flee** during RESPOND phase (when being attacked) or DECLARE phase (on their turn).
2. **Direction:** If the player specifies (`flee north`), they attempt that exit. If not (`flee`), the engine picks the most accessible exit.
3. **Success check:** Based on player speed vs. creature speed, modified by leg injuries. Healthy player vs. rat: ~80% success. Injured legs: 40%. Rat is faster: -20%.
4. **On success:** Player takes a glancing blow (50% damage) and moves to the adjacent room. Combat ends. Creature may pursue (if `hunt` behavior, Phase 2+).
5. **On failure:** Player takes full damage (caught off-balance, 120% modifier) and remains in the room. They do NOT get a defensive action this exchange.
6. **Narration:** Success: *"You turn and bolt through the doorway — the rat's teeth graze your ankle as you flee."* Failure: *"You stumble toward the exit — the rat lunges, catching your calf. You're not getting away that easily."*

**MUD lesson applied:** Every MUD makes fleeing unreliable and costly. This prevents flee-spam as a dominant strategy and makes the decision to stand and fight meaningful.

---

## 9. NPC-vs-NPC Combat

### 9.1 Unified Combatant Interface

The combat resolution function makes **no distinction** between player and NPC. The same `resolve_exchange(attacker, defender, weapon, target_zone)` handles:

- Player attacks rat
- Rat attacks player
- Cat attacks rat
- Wolf attacks deer
- Guard attacks thief

The only difference is the input source: player combatants present choices to the human; NPC combatants read from their `combat.behavior` metadata. The resolution math, narration templates, injury system, and mutation pipeline are identical.

### 9.2 When NPCs Fight

NPC-vs-NPC combat triggers automatically when predator-prey metadata matches:

```lua
-- Cat's combat metadata includes:
combat = {
    behavior = {
        aggression = "on_sight",
        prey = { "rat", "mouse", "bird" },
    },
}

-- Engine check (in creature tick):
-- For each creature pair in the same room:
--   If creature_A.combat.behavior.prey contains creature_B.id:
--     Initiate combat between A and B
```

**No scripted interactions.** The engine doesn't have a `cat_sees_rat()` function. It has a generic prey-check that evaluates combat metadata. A cat that encounters a rat starts fighting because its metadata says rats are prey. A wolf that encounters a cat starts fighting for the same reason. The engine doesn't know or care what species are involved.

### 9.3 NPC-vs-NPC Resolution

The combat exchange FSM runs identically for NPC-vs-NPC:

1. **INITIATE:** Compare speeds. Cat (speed 7) vs. rat (speed 6) → cat acts first.
2. **DECLARE:** Cat's `attack_pattern = "strongest"` → selects bite (force 5, pierce).
3. **RESPOND:** Rat's `defense = "dodge"` → dodge attempt. Rat speed 6 vs. cat speed 7 → dodge fails.
4. **RESOLVE:** Cat bite (tooth_enamel, pierce, force 5 × small size 1.0 = 5) vs. rat head (hide → flesh → bone). Tooth_enamel max_edge vs. rat hide = penetrate. Result: CRITICAL hit to rat head.
5. **NARRATE:** *"The cat pounces and catches the rat by the skull. A wet crunch."*
6. **UPDATE:** Rat health → 0. FSM transition: alive → dead. Mutation: rat becomes dead-rat.

**Total: 1–2 exchanges.** A cat killing a rat is fast — because physically, a cat always beats a rat. The material system guarantees this. No need for scripted "cat wins" logic; the physics produces the correct outcome.

### 9.4 Player as Witness

When NPC-vs-NPC combat occurs in the player's room, the player witnesses it through the narration system:

**With light:** Full visual narration. *"The cat springs from behind the barrel, landing on the rat. Claws flash — the rat squeals — then silence. The cat sits back, licking blood from its paw. A dead rat lies at its feet."*

**In darkness:** Audio-only narration. *"A sudden scrabbling of claws. A shrill squeak — then a wet crunch. Something just killed something in the dark."*

**Adjacent room:** Distant sound only. *"From the cellar below, you hear a brief commotion — claws on stone, a high-pitched shriek, then silence."*

This uses the existing sensory system (Principle 6) and the perception range system from the NPC plan. No combat-specific narration code — the narration templates produce room-appropriate output based on light level and distance.

### 9.5 Player Intervention

The player can intervene in NPC-vs-NPC combat:

- **Attack one combatant:** `attack cat` — player enters the fight as a third combatant. Turn order now includes all three participants.
- **Throw something:** `throw rock at wolf` — ranged attack that interrupts the current exchange.
- **Separate combatants:** `kick cat` — may cause the cat to flee, ending its attack on the rat.
- **Environmental interaction:** `slam door` — loud noise that triggers flee reactions in both combatants.

The engine handles multi-combatant fights by running the exchange FSM for each combatant pair. In a 3-way fight (player, cat, rat), each round produces 3 exchange cycles based on each combatant's `target_priority` metadata.

### 9.6 Ecosystem Implications (Phase 2+)

When multiple creature types coexist in the world, the combat system creates emergent ecology:

| Interaction | Outcome | Emergent Effect |
|-------------|---------|-----------------|
| Cat hunts rat | Cat kills rat (usually) | Rat population controlled |
| Wolf hunts deer | Wolf kills deer | Food chain established |
| Player kills wolf | Wolf dies | Deer population unchecked |
| Spider ambushes rat | Spider bites rat (venom) | Territorial denial zones |
| Two wolves vs. bear | Wolves may flee (bear is large) | Size hierarchy respected |

None of these outcomes are scripted. They emerge from material physics (cat claws > rat hide), size asymmetry (wolf < bear), and behavior metadata (flee thresholds, aggression types). **This is the Dwarf Fortress philosophy: author the rules, not the behaviors.**

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
