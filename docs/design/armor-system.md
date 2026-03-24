# Armor System — Design Document

**Version:** 1.0  
**Date:** 2026-03-24  
**Author:** Comic Book Guy (Game Designer)  
**Audience:** Game Designers, Content Creators  
**Status:** Design Complete — Ready for Architecture Review  

---

## Executive Summary

Armor protection is **derived from material properties**, not hardcoded on objects. You don't write `provides_armor = 1` on a ceramic pot. Instead, you declare `material = "ceramic"` on the wear metadata, and the engine calculates protection based on ceramic's `hardness`, `flexibility`, and `density`. This is the Dwarf Fortress principle: **the engine operates on property bags, not named object types.**

A ceramic pot on your head protects you because ceramic is hard and dense. When struck, it cracks because ceramic has high fragility. A brass spittoon protects similarly (same slot, different material) but never breaks because brass has low fragility. Both objects work *emergently* from the same material system, not from hardcoded rules.

**Core Design Philosophy:** The armor system connects three existing layers:
1. **Material Registry** — 22 materials with 11 numeric properties each
2. **Wearable System** — 9 slots, 3 layers, conflict resolution
3. **Effects Pipeline** — before/after interceptors for damage modification

This document guides designers in making wearable objects that act as armor. It's NOT about implementation details or engine architecture — see `docs/architecture/engine/armor-system.md` for that.

---

## Part 1: How Armor Works (Designer Perspective)

### The Big Picture

When a player takes damage to the head (injury), here's what happens:

```
ATTACK: enemy swings sword at player's head
  ↓
EFFECTS PIPELINE: before-effect interceptor fires
  ↓
ARMOR CHECK: "What is player wearing on the head?"
  ↓
MATERIAL LOOKUP: "That's a ceramic pot. What does ceramic provide?"
  ↓
PROTECTION CALCULATION: Ceramic's hardness=7 + flexibility=0.0 + density=2300 → protection=X
  ↓
DAMAGE REDUCTION: Incoming 5 damage → 5 - X = modified damage to player
  ↓
DEGRADATION ROLL: Ceramic's fragility=0.7 vs attack force → "Crack appears in pot"
  ↓
FSM TRANSITION: Pot state changes from "intact" → "cracked"
  ↓
CONTINUE: Reduced damage is inflicted on player
```

**The key insight:** You define the wear metadata, and the engine derives everything else from the material.

---

## Part 2: Making an Object Act as Armor

### Required Metadata

When you want an object to protect the player, add a `wear` table to its definition:

```lua
return {
    id = "chamber-pot",
    name = "a dented chamber pot",
    material = "ceramic",
    
    -- THIS IS ALL YOU NEED FOR ARMOR:
    wear = {
        slot = "head",           -- where this fits (required)
        layer = "outer",         -- stacking layer (required)
        coverage = 0.8,          -- how much of slot this covers (0.0–1.0)
        fit = "makeshift",       -- quality: makeshift | fitted | masterwork
    },
    
    -- ... rest of object definition
}
```

**That's it.** The engine will:
- Calculate protection from `material = "ceramic"` (hardness, flexibility, density)
- Check `fragility` to see if the pot cracks on impact
- Apply the `fit` multiplier (makeshift items are less reliable)
- Narrate the armor interaction when worn

You **never** write:
- ❌ `provides_armor = 1`
- ❌ `reduces_unconsciousness = 1`
- ❌ `armor_strength = 5`

These are derived from the material. The armor system is **emergent**, not scripted.

### Wear Metadata Fields

| Field | Type | Required? | Default | Meaning |
|-------|------|-----------|---------|---------|
| `slot` | string | ✅ YES | — | Head, torso, hands, feet, etc. Engine uses slot to match injuries. |
| `layer` | string | ✅ YES | — | inner, mid, outer. Determines stacking: multiple layers on same slot both contribute. |
| `coverage` | number | — | 1.0 | What fraction of the slot does this cover? Full helm = 1.0, pot = 0.8, hat = 0.5. |
| `fit` | string | — | fitted | How well does this fit? "makeshift" ÷ 2, "fitted" ÷ 1, "masterwork" × 2. |

### Slot Names (Engine Standard)

| Slot | Where | Examples | Notes |
|------|-------|----------|-------|
| `head` | Head, protects against head injuries | Helmet, pot, hat | Can wear multiple items at once (inner + outer). |
| `torso` | Chest, back, stomach | Breastplate, cloak, armor vest | Main body protection. |
| `hands` | Both hands | Gloves, gauntlets | Protects hands specifically. |
| `feet` | Both feet | Boots, shoes | Protects feet. |
| `legs` | Thighs, shins, calves | Greaves, pants | Lower body. |
| `neck` | Neck, throat | Gorget, scarf | Specialized protection. |
| `waist` | Hips, belt area | Belt, sash | Can hold items too (future). |
| `wrists` | Wrists specifically | Bracers, cuffs | Against wrist injuries. |
| `back` | Back exclusively | Backpack, quiver | Storage + protection. |

**Injury ↔ Slot Mapping:** Head injuries are blocked by items on `head` slot, torso injuries by `torso` slot, etc. The engine doesn't care about the object's semantic purpose — it only cares about the slot.

---

## Part 3: Material → Protection Table

The engine calculates protection using these material properties:

| Material | Hardness | Flexibility | Density | Fragility | Protection Ranking | Use Case |
|----------|----------|-------------|---------|-----------|-------------------|----------|
| **steel** | 9 | 0.3 | 7850 | 0.05 | ⭐⭐⭐⭐⭐ Elite | Best armor (rare, expensive) |
| **iron** | 8 | 0.3 | 7870 | 0.1 | ⭐⭐⭐⭐ Excellent | Military gear, crafted armor |
| **ceramic** | 7 | 0.0 | 2300 | 0.7 | ⭐⭐⭐ Good (fragile) | Makeshift (pots, tiles) |
| **brass** | 6 | 0.1 | 8500 | 0.1 | ⭐⭐⭐ Good (durable) | Decorative + functional (spittoons) |
| **stone** | 7 | 0.0 | 2600 | 0.3 | ⭐⭐⭐ Good | Makeshift (rocks, bricks) |
| **bone** | 5 | 0.05 | 1900 | 0.4 | ⭐⭐ Moderate | Primitive armor, tough enough |
| **leather** | 3 | 0.6 | 850 | 0.0 | ⭐⭐ Moderate | Flexible protection, no breaking |
| **wood** | 4 | 0.2 | 600 | 0.2 | ⭐⭐ Moderate | Shields, armor, durable |
| **wool** | 1 | 0.9 | 350 | 0.0 | ⭐ Weak | Padding, insulation, never breaks |
| **fabric** | 1 | 1.0 | 300 | 0.0 | ⭐ Weak | Clothing, bandages, no breaking |
| **glass** | 6 | 0.0 | 2500 | 0.9 | ⚠️ Risky | Visual only, shatters immediately |

### How Protection Is Calculated

**The Formula (Conceptual):**

```
protection = (hardness × 0.5) + (flexibility × 0.3) + (density_factor × 0.2)
           × coverage × fit_multiplier
```

More durable, denser materials provide more protection. Flexible materials (like leather) absorb some impact. Fragile materials (like ceramic) lose protection quickly after cracking.

**Key Principles:**
- **Hardness is primary** — it's the main defense against cutting and piercing
- **Flexibility matters** — reduces risk of shattering, spreads impact force
- **Density adds mass** — heavier = more momentum needed to penetrate
- **Coverage limits benefit** — pot covering 80% of head doesn't protect the back of your neck
- **Fit modifies effectiveness** — Makeshift is half as effective; masterwork is twice as effective

### Real Comparisons

**Steel Helm vs Ceramic Pot (both head slot, outer layer):**

| Property | Steel | Ceramic | Difference |
|----------|-------|---------|-----------|
| Hardness | 9 | 7 | Steel is harder |
| Flexibility | 0.3 | 0.0 | Steel flexes; ceramic shatters |
| Density | 7850 | 2300 | Steel is 3× heavier |
| Fragility | 0.05 | 0.7 | Steel durable; ceramic breaks easily |
| **Protection** | 6.0–7.0 | 3.5–4.0 | Steel ≈ 70% better |
| **Cost** | 10 value | 3 value | Steel is expensive |

Result: Steel helm is much better, but ceramic pot still provides real protection.

**Brass Spittoon vs Ceramic Pot (both head slot, makeshift):**

| Property | Brass | Ceramic |
|----------|-------|---------|
| Hardness | 6 | 7 |
| Flexibility | 0.1 | 0.0 |
| Fragility | 0.1 | 0.7 |
| **Protection** | 3.8–4.2 | 3.5–4.0 |
| **Key Difference** | Never breaks | Cracks after hits |

Result: Protection is nearly identical, but brass is **far more durable**. After your 5th hit, the ceramic pot is shattered; the brass spittoon is still intact.

---

## Part 4: Damage Type × Material Interaction Matrix

Different damage types interact with materials differently:

### Damage Type Definitions

| Damage Type | Weapon Examples | What It Does | Counter |
|-------------|-----------------|-------------|---------|
| **Slashing** | Sword, dagger, whip | Cuts through material | Hardness resists |
| **Piercing** | Spear, stab, needle, arrow | Concentrates force on small point | Hardness + thickness |
| **Blunt** | Club, punch, fall, impact | Spreads shock across area | Hardness + flexibility |

### Interaction Matrix

```
                   SLASHING          PIERCING          BLUNT
STEEL (hard)       ████████░░        ██████░░░░        ██████░░░░
BRASS (hard)       ███████░░░        █████░░░░░        ██████░░░░
CERAMIC (hard)     ███████░░░        █████░░░░░        ███░░░░░░░
LEATHER (flex)     █████░░░░░        ███░░░░░░░        ████░░░░░░
WOOD (rigid)       ██████░░░░        ████░░░░░░        █████░░░░░
WOOL (soft)        ██░░░░░░░░        █░░░░░░░░░        ███░░░░░░░

(Each ░ = ~10% damage reduction)
```

### Read This As:

**Against SLASHING (sword cuts):**
- Hard materials (steel, brass, ceramic) are effective — they resist cutting
- Soft materials (wool, fabric) are poor — cuts right through

**Against PIERCING (arrow, stab):**
- Hard + thick materials (steel, ceramic) are good — harder to penetrate
- Soft materials (wool, fabric) are terrible — offer almost no resistance
- **Key:** Piercing damage punches through, so hardness alone isn't enough — need mass too

**Against BLUNT (club, fall, punch):**
- Flexible materials (leather, wool) are surprisingly effective — absorb impact
- Rigid materials (ceramic) are weak — shatter under impact
- Hard materials (steel, brass) are good — good balance of hardness + some flex

### Designer Insight

- **Medieval helm made of ceramic?** Terrible against arrows (piercing), OK against swords (slashing), VERY bad against clubs (blunt + shattering)
- **Leather armor?** Poor against arrows, decent against swords, good against blunt (it's flexible)
- **Wool cloak over steel?** Two layers: outer wool absorbs first hit, inner steel handles penetration
- **Brass spittoon?** Decent against all types, but especially good against blunt (brass is slightly flexible + durable)

---

## Part 5: Degradation Narratives

When armor absorbs a hit, it doesn't just reduce damage — it might **break**. The `fragility` property determines this.

### Degradation States (FSM Transitions)

An armored object typically has these states:

| State | Description | Protection | Next State | Trigger |
|-------|-------------|-----------|-----------|---------|
| `intact` | Fresh, full protection | 100% | cracked | Hit with enough force × high fragility |
| `cracked` | Damaged, reduced protection | ~60% | shattered | Hit again, or attempted wear |
| `shattered` | Terminal, useless | 0% | — | Cannot repair without crafting |

### Fragility-Based Degradation Rules

| Fragility | Material Example | Degradation Pattern | Narrative Feel |
|-----------|-----------------|-------------------|-----------------|
| 0.0–0.1 | Leather, fabric, hemp, steel | Never breaks (only dents, cosmetic) | "The helm dents but holds" |
| 0.1–0.3 | Wood, bone, iron | Rare breakage (cracks after many hits) | "The wooden shield splinters" |
| 0.3–0.5 | Stone | Occasional breakage (cracks with moderate hits) | "A chunk of stone chips away" |
| 0.5–0.7 | Ceramic | Frequent breakage (cracks after 2–3 hits) | "Your pot cracks with a sickening crunch" |
| 0.7–0.9 | Glass | Immediate shattering (breaks on first significant hit) | "The glass helmet shatters into fragments" |
| 0.9–1.0 | Pure glass, mirrors | Shatters on ANY hit | "The mirror explodes into razor shards" |

### Ceramic Pot Degradation Narrative

**Initial state: `intact`**

```
> WEAR POT
You place the dented chamber pot on your head. It sits awkwardly 
but provides a surprising amount of protection.

> LOOK
You see yourself in the mirror:
  The pot rests crooked on your head. It smells. Badly.
```

**After absorbing a strong hit: `cracked`**

```
[Enemy swings sword at your head]
Your ceramic pot absorbs some of the blow, but cracks loudly. 
A hairline fracture runs down the side.

> FEEL POT
The pot has a long crack running down one side. If you take 
another hard hit like that, it might shatter completely.
```

**After absorbing another strong hit: `shattered`**

```
[Enemy swings again]
Your pot cracks further and fragments fall around you. 
It no longer provides protection.

> REMOVE POT
You pull off the broken pottery. Sharp ceramic edges have 
cut your forehead. Several pieces fall to the floor.
```

### Brass Spittoon Degradation Narrative

**Same hits, VERY different outcome (fragility 0.1):**

**After 5+ hits:**

```
[Enemy swings at your head]
Your spittoon rings like a bell and dents inward slightly, 
but holds firm. It's getting ugly, but still intact.

> FEEL SPITTOON
The brass is now covered in dents and scratches, but structurally 
sound. It has clearly seen combat.
```

**Even after 20+ hits:**

```
[Enemy swings at your head]
Your spittoon absorbs the impact with a dull THUD, but doesn't 
break. The dents and dings accumulate, but it endures.

> REMOVE SPITTOON
You take off the thoroughly battered brass vessel. It's dented 
all over, but still protects your head if needed.
```

**Key Difference:** Ceramic tells a story of fragility and impending failure. Brass tells a story of cumulative damage and durability. Both are emergent from a single property: `fragility`.

---

## Part 6: Full Examples

### Example 1: Ceramic Pot (Makeshift Head Armor)

**Design Decisions:**

```lua
return {
    id = "chamber-pot",
    name = "a dented chamber pot",
    material = "ceramic",    -- hardness: 7, fragility: 0.7
    
    wear = {
        slot = "head",
        layer = "outer",
        coverage = 0.8,      -- doesn't cover back of neck
        fit = "makeshift",   -- × 0.5 protection multiplier
    },
    
    -- ... other fields like description, on_feel, on_smell, etc.
    
    -- Optional: FSM states for degradation
    -- The engine manages: intact → cracked → shattered
}
```

**What This Means:**
- Protection: Ceramic (hardness 7, density 2300) = **base 3.5–4.0**
- Adjusted: × 0.8 coverage × 0.5 makeshift fit = **final 1.4–1.6 protection**
- Against slashing (sword): **good** — ceramic is hard
- Against piercing (arrow): **poor** — ceramic is brittle, breaks under point pressure
- Against blunt (club): **very poor** — ceramic shatters immediately
- Durability: **very fragile** — cracks after 2–3 moderate hits

**Narrative Arc:**
1. Player finds pot, thinks "this could protect my head"
2. Put it on, feels awkward but helpful (coverage 0.8 hints it's not perfect)
3. First sword swing glances off — "Your pot absorbs some of the blow"
4. Second sword swing cracks it — "The pot cracks with a loud crunch"
5. Third swing shatters it — pieces fall, protection is gone

### Example 2: Brass Spittoon (Durable Head Armor)

**Design Decisions:**

```lua
return {
    id = "brass-spittoon",
    name = "a heavy brass spittoon",
    material = "brass",      -- hardness: 6, fragility: 0.1
    
    wear = {
        slot = "head",
        layer = "outer",
        coverage = 0.9,      -- covers most of head
        fit = "makeshift",   -- × 0.5 protection multiplier (not well-fitted)
    },
    
    -- Optional: weight = 2.5 (brass is heavy!)
    -- Optional: can_drop_on_foot_effect = "pain" (heavy object hazard)
}
```

**What This Means:**
- Protection: Brass (hardness 6, density 8500, high mass) = **base 4.0–4.5**
- Adjusted: × 0.9 coverage × 0.5 makeshift fit = **final 1.8–2.0 protection**
- Against slashing (sword): **good** — brass is hard
- Against piercing (arrow): **moderate** — brass is dense, arrow struggles to punch through
- Against blunt (club): **good** — brass is slightly flexible, spreads impact
- Durability: **very durable** — takes 20+ hits to accumulate dents, essentially never breaks

**Narrative Arc:**
1. Player finds heavy brass vessel, realizes it could work as armor
2. Put it on, feels *very* heavy but protective (coverage 0.9 is nearly complete)
3. First sword swing clangs off — "Your spittoon rings with the impact"
4. After 10+ swings: "Your spittoon is dented all over but still protects your head"
5. Never shatters — just gets uglier and uglier

### Example 3: Steel Helm (Crafted Head Armor)

**Design Decisions:**

```lua
return {
    id = "steel-helm",
    name = "a well-crafted steel helm",
    material = "steel",      -- hardness: 9, fragility: 0.05
    
    wear = {
        slot = "head",
        layer = "outer",
        coverage = 1.0,      -- full head coverage
        fit = "fitted",      -- × 1.0 protection multiplier (professional fit)
    },
    
    -- Optional: keywords = { "helm", "helmet", "crown" }
    -- Optional: value = 50 (steel is expensive)
}
```

**What This Means:**
- Protection: Steel (hardness 9, density 7850) = **base 6.0–7.0**
- Adjusted: × 1.0 coverage × 1.0 fitted fit = **final 6.0–7.0 protection**
- Against slashing (sword): **excellent** — steel is the hardest and densest
- Against piercing (arrow): **excellent** — steel resists penetration
- Against blunt (club): **excellent** — steel + good fit absorbs impact
- Durability: **extremely durable** — essentially never breaks in normal combat

**Narrative Arc:**
1. Player finds or crafts expensive steel helm
2. Put it on, feels secure and professional (coverage 1.0, fit "fitted")
3. Arrows bounce off with loud **PING** sounds
4. Swords glance off the curved surface
5. After many battles: maybe a few scratches, but fully intact
6. Never shatters — can be kept forever if maintained

### Example 4: Leather Cap (Flexible Head Armor)

**Design Decisions:**

```lua
return {
    id = "leather-cap",
    name = "a soft leather cap",
    material = "leather",    -- hardness: 3, flexibility: 0.6, fragility: 0.0
    
    wear = {
        slot = "head",
        layer = "inner",     -- underneath other armor
        coverage = 0.6,      -- partial head coverage
        fit = "fitted",      -- comfortable fit
    },
}
```

**What This Means:**
- Protection: Leather (hardness 3, flexibility 0.6) = **base 2.0–2.5**
- Adjusted: × 0.6 coverage × 1.0 fitted fit = **final 1.2–1.5 protection**
- Against slashing (sword): **poor** — soft leather cuts easily
- Against piercing (arrow): **very poor** — arrow punches right through
- Against blunt (club): **moderate** — flexibility absorbs some impact
- Durability: **never breaks** — leather degrades slowly but never shatters
- Stacking: Can wear underneath a helmet for padding

**Narrative Arc:**
1. Player finds soft leather cap
2. Put it on, feels comfortable but protective
3. Sword hit: "The blade cuts through the leather cap slightly, but your head is cushioned beneath"
4. Never breaks, but gradually shows wear
5. Works well stacked with other armor (cap + helm = dual layer protection)

### Example 5: Sack on Head (Absurd Head Protection)

**Design Decisions:**

```lua
return {
    id = "sack",
    name = "a burlap sack",
    material = "burlap",     -- hardness: 2, flexibility: 0.7, fragility: 0.05
    
    wear = {
        slot = "head",
        layer = "outer",
        coverage = 0.7,      -- covers most but fabric sags
        fit = "makeshift",   -- × 0.5 protection multiplier (very poor fit)
    },
    
    -- Optional: on_wear effect (narrate wearing a sack)
}
```

**What This Means:**
- Protection: Burlap (hardness 2, flexibility 0.7) = **base 1.2–1.5**
- Adjusted: × 0.7 coverage × 0.5 makeshift fit = **final 0.4–0.5 protection**
- Against slashing (sword): **very poor** — just fabric
- Against piercing (arrow): **useless** — arrow goes through easily
- Against blunt (club): **poor** — fabric absorbs almost nothing
- Durability: **never breaks** — it's just fabric, can't shatter
- Visibility: **reduced** — you can't see well with a sack on your head

**Narrative Arc:**
1. Player desperate, puts sack on head
2. "You pull the burlap sack over your head. You can barely see."
3. First hit: "The sack tears slightly, but you're mostly OK."
4. Multiple hits: "Your sack is in tatters, hanging around your neck."
5. Never provides real protection, but provides comedy and consequence

---

## Part 7: Case Study — Brass Spittoon

### The Design Brief

Wayne's vision for the brass spittoon: **a durable, comedic counterpart to the ceramic pot**. Both are improvised helmets, but they represent opposite ends of the material spectrum.

### Material Profile

**Brass Properties:**
- `hardness: 6` — moderately hard
- `flexibility: 0.1` — very inflexible (brass is brittle)
- `density: 8500` — very heavy
- `fragility: 0.1` — extremely durable (only dents)
- `value: 8` — moderately expensive

### Why These Choices?

| Choice | Why | Effect |
|--------|-----|--------|
| **hardness: 6** | Brass is soft relative to steel (9) but harder than ceramic (7) on Mohs scale. Actually brass is 3 Mohs, but we inflate to reflect game balance — a spittoon shouldn't be as good as steel. | Protection is slightly lower than ceramic on hardness alone, but better overall due to durability. |
| **fragility: 0.1** | Brass doesn't shatter like ceramic. Under impact, it **dents** instead of cracks. This is the key design difference. | Instead of "pot cracks and breaks," narration is "spittoon dents but holds firm." |
| **density: 8500** | Brass is heavy (heavier than steel 7850). This is physically accurate and gives the spittoon heft. | Heavy object, harder to carry, but harder to penetrate. Nice trade-off for a comedic helmet. |
| **flexibility: 0.1** | Brass is not flexible — it's rigid. Unlike leather (0.6), brass doesn't absorb impact through flex; it resists through mass and hardness. | Better against slashing/piercing (hard surface), worse against blunt (rigid = shatters under club, except fragility keeps it together). |

### Gameplay Implications

**Comparison to Ceramic Pot:**

| Aspect | Ceramic Pot | Brass Spittoon | Winner |
|--------|------------|-----------------|--------|
| **Initial Protection** | Good (hardness 7) | Good (hardness 6 + density) | Tie |
| **Slashing Resistance** | ⭐⭐⭐ | ⭐⭐⭐ | Tie |
| **Piercing Resistance** | ⭐⭐ | ⭐⭐⭐ | Brass (mass matters) |
| **Blunt Resistance** | ⭐ (shatters) | ⭐⭐⭐ (absorbs) | Brass |
| **Durability** | Very fragile | Very durable | Brass |
| **Weight Penalty** | Light | Heavy | Ceramic (better for carrying) |
| **Aesthetic** | Embarrassing | Ridiculous | Brass (funnier) |

**Emergent Story:**
- A player finding the ceramic pot thinks: "Maybe this could work as emergency protection."
- A player finding the brass spittoon thinks: "This is absurd... but it's actually pretty durable."

After both take hits:
- Ceramic pot: "After your 3rd sword hit, it shatters into pieces. You need new armor."
- Brass spittoon: "After your 10th sword hit, it's dented all over, but still on your head."

### Why Material-Derived Design Works

The brass spittoon is **designed as a pure material choice**. There's no "makeshift helmet behavior" code. There's no special case for "denting vs breaking." The engine just follows the material properties:

```
Brass properties (fragility: 0.1)
  ↓
Engine rolls degradation check
  ↓
99% of hits: fail to break (0.1 fragility means 90% pass rate)
  ↓
Narration: "The spittoon dents but holds"
  ↓
State: remains "intact"

[vs. ceramic, fragility: 0.7]
  ↓
70% of hits: pass the break check
  ↓
Narration: "The pot cracks"
  ↓
State: transitions "intact" → "cracked"
```

The designer **never wrote** degradation logic. The designer **only declared** material properties. The engine derived the emergent behavior.

This is the core philosophy of the armor system: **declare materials, engine handles emergent consequences.**

---

## Part 8: Core Design Philosophy

### Principle 1: Protection Is Derived, Never Hardcoded

**DO:**
```lua
wear = {
    slot = "head",
    layer = "outer",
    material = "ceramic",  -- engine calculates protection
}
```

**DON'T:**
```lua
provides_armor = 1           -- ❌ hardcoded
reduces_unconsciousness = 1  -- ❌ hardcoded
armor_strength = 5           -- ❌ hardcoded
```

The material system is the single source of truth for armor values. If you find yourself writing numeric armor properties on objects, stop and check the material instead.

### Principle 2: Material × Damage Type × Location Matters

The same material provides different protection depending on:

- **Where you're wearing it:** Head armor doesn't protect torso
- **What hits you:** Slashing, piercing, or blunt damage
- **How you're wearing it:** Makeshift fit vs fitted vs masterwork

The engine handles all these interactions. You just declare the material and slot.

### Principle 3: Degradation Tells a Story

Fragility isn't just a number. It's a narrative arc:

- **Low fragility (brass 0.1):** "I'm going to look really beat up, but I'm not breaking"
- **High fragility (ceramic 0.7):** "I'm going to fail soon, and dramatically"

Use fragility to tell stories about object durability. Makeshift objects (ceramic pot) are fragile. Crafted objects (steel helm) are durable. This guides player expectations naturally.

### Principle 4: No Hardcoded Interactions

Don't write code like:

```lua
-- ❌ NO
if armor.material == "ceramic" and damage_type == "blunt" then
    armor.state = "cracked"
end
```

Instead, let the material properties and damage type system produce emergent interactions:

```lua
-- ✅ YES
-- Material: ceramic (fragility: 0.7, hardness: 7)
-- Damage: blunt (ignores hardness, stresses fragility)
-- Engine: "Blunt damage × high fragility → likely crack"
-- Result: emergent interaction, no code needed
```

### Principle 5: Coverage and Fit Are Multiplicative

Protection is never absolute. Three factors scale it:

1. **Material properties** — base protection (hardness, flexibility, density)
2. **Coverage** — does the armor cover this location? (0.0–1.0)
3. **Fit** — how well is it crafted? (makeshift ÷2, fitted ÷1, masterwork ×2)

```
final_protection = material_base × coverage × fit_multiplier
```

This allows designers to use the same material multiple times with different stories:

- **Leather cap** (coverage 0.6, makeshift fit) = weak but comfortable
- **Leather armor** (coverage 1.0, fitted fit) = much better protection

Same material, different declarations = different gameplay.

### Principle 6: The Engine Is a Tool, Not a Constraint

Material properties enable emergent behavior, but they don't force it. Designers can:

- Deliberately use "wrong" materials (glass helmet? Fragile but cool)
- Mix materials (ceramic inner layer + leather outer = unusual protection profile)
- Create narrative through material choice (aluminum foil as a joke armor = very low protection but memorable)

The system empowers designer creativity through consistent rules, not limits.

---

## Part 9: Design Tips for Object Creators

### Tip 1: Use Material Existing Before Inventing New Materials

We have 22 materials. Before adding a new one, check if an existing material works:

- **Want "bone armor"?** Use `material = "bone"` — hardness 5, fragility 0.4
- **Want "copper helmet"?** Use `material = "brass"` — similar properties, value 8
- **Want "leather jacket"?** Use `material = "leather"` — hardness 3, never breaks

New materials dilute the system. Reuse existing ones and vary coverage/fit instead.

### Tip 2: Choose Fit to Tell a Story

| Fit | Multiplier | Story | Example |
|-----|-----------|-------|---------|
| `makeshift` | ÷ 2 | Improvised, poorly fitted | Pot on head, bag as armor, cardboard shield |
| `fitted` | ÷ 1 | Standard crafting, comfortable wear | Leather armor, wool cloak, basic helm |
| `masterwork` | × 2 | Professional craftsmanship, perfect fit | Enchanted armor, dwarvish steel, royal regalia |

Makeshift fit explains why a ceramic pot isn't as good as it should be — it's not designed to be worn. Masterwork fit rewards players for finding the best-crafted items.

### Tip 3: Set Coverage to Match Reality

| Coverage | Narrative | Example |
|----------|-----------|---------|
| 0.5–0.6 | Partial coverage | Cap (back of head exposed), gauntlets (wrists only) |
| 0.7–0.8 | Good coverage | Helmet (face/top covered, back of neck exposed), spittoon |
| 0.9–1.0 | Full coverage | Full helm (complete head), breastplate (full torso) |

Coverage isn't just mechanics — it's narration. A 0.5 coverage item should feel like it leaves you exposed. An attack "glances off the exposed side."

### Tip 4: Layer Stacking for Complex Armor

Players can wear multiple items in the same slot, on different layers:

```
Inner layer: wool cap (soft, absorbs blunt)
Mid layer: leather armor (flexible, moderate protection)
Outer layer: steel plate (hard, maximum protection)

Result: three protection sources stack, each reducing damage
```

When designing an object, ask: "Would this wear well *underneath* something else?" If yes, use `layer = "inner"`. If it's a complete piece, use `layer = "outer"`.

### Tip 5: Remember that Armor Doesn't Mean Wearable

An object can have `material` and not have armor. The material system is for all objects:

- A wooden door's hardness determines how easily it breaks
- A ceramic cup's fragility determines if it shatters when dropped
- A wool rug's absorbency determines if it soaks up spilled liquid

Armor is just one application. Don't conflate material system with armor system.

### Tip 6: Avoid Over-Optimizing for Protection Values

New designers often ask: "What combination of hardness, flexibility, and density gives the maximum protection?"

**Stop.** Here's the answer: **it doesn't matter**. The engine interpolates material properties into protection values that balance the game. If your ceramic pot feels weak (it should be — it's fragile), that's correct. If your steel helm feels strong (it should be — it's crafted), that's correct.

Focus on narrative fit, not min-maxing values.

---

## Part 10: Anti-Patterns — What NOT to Do

### Anti-Pattern 1: Hardcoding Material Behavior

**❌ WRONG:**
```lua
-- object definitions shouldn't have armor properties
wear = {
    slot = "head",
    armor_reduction = 3,      -- NO
    reduces_slashing = true,  -- NO
    reduces_piercing = 0.5,   -- NO
}
```

**✅ RIGHT:**
```lua
material = "steel"  -- engine derives all behaviors
wear = {
    slot = "head",
    layer = "outer",
    coverage = 1.0,
    fit = "fitted",
}
```

### Anti-Pattern 2: Creating New Materials for One Object

**❌ WRONG:**
```lua
-- in materials.lua
mithril = {
    hardness = 11,   -- NO! We don't have mithril yet
    fragility = 0.01,
    -- ... etc
}

-- then use it on one sword
```

**✅ RIGHT:**
```lua
-- Use existing "steel" for now
material = "steel"

-- If we later add mithril with proper lore and gameplay,
-- then refactor existing objects to use it
```

### Anti-Pattern 3: Coverage As Excuse for Low Protection

**❌ WRONG:**
```lua
wear = {
    slot = "head",
    coverage = 0.2,   -- "it's ok to be weak, coverage explains it"
}
```

**✅ RIGHT:**
```lua
wear = {
    slot = "head",
    coverage = 0.2,   -- coverage is REAL game mechanic
    -- Enemy attacks the exposed 80% of head
}
```

Coverage isn't an excuse — it's a real mechanic. A helmet with 0.2 coverage only protects 1/5 of head injuries. Attackers learn to aim for the gaps.

### Anti-Pattern 4: Inventing New Slot Names

**❌ WRONG:**
```lua
wear = {
    slot = "face_only",   -- Not in engine standard
    layer = "outer",
}
```

**✅ RIGHT:**
```lua
wear = {
    slot = "head",        -- Standard slot
    layer = "outer",
    coverage = 0.3,       -- Only face area (30% of head)
}
```

Use standard slots and coverage to describe detailed protection, not custom slot names.

### Anti-Pattern 5: Assuming Material Means Identity

**❌ WRONG:**
```lua
-- Two different objects with same material expect same properties
id = "sword",
material = "steel",

id = "helm",
material = "steel",  -- "If both are steel, they should be interchangeable"
```

**✅ RIGHT:**
```lua
-- Material determines PROPERTIES, not purpose
id = "sword",
material = "steel",  -- A blade made of steel

id = "helm",
material = "steel",  -- A helmet also made of steel
-- But they function completely differently
-- The steel PROPERTIES (hardness, fragility) apply to both
-- But how those properties are USED depends on context (weapon vs armor)
```

---

## Part 11: Integration with Other Systems

### Integration with Injury System

When a player takes an injury (head damage, cut, wound):

1. Injury system tries to apply effect
2. Effects pipeline checks: "What armor is on this location?"
3. Armor system calculates protection from material
4. Damage is reduced
5. Reduced damage is applied to player
6. Armor degradation check fires (does it break?)

**Example:**
```
Enemy slashes at head with sword (5 damage)
  → Armor: ceramic pot (protection: 1.5)
  → Reduced damage: 5 - 1.5 = 3.5 → 3 (minimum 1)
  → Apply: player takes 3 damage to head
  → Degradation: ceramic (fragility 0.7) vs slash (stress level 2) → CRACK
  → Pot transitions: intact → cracked
```

### Integration with Wearable System

The wearable system already exists. Armor just adds:

1. **Wear metadata** — `wear.slot` and `wear.layer` existing
2. **Material lookup** — new behavior at damage time
3. **Degradation FSM** — new state transitions for cracking

No changes to how players wear/remove armor. The `WEAR` and `REMOVE` verbs work exactly as before.

### Integration with Appearance System

The appearance system (mirror) shows worn items. Armor works like any wearable:

```
> LOOK IN MIRROR
You see yourself:
  A ceramic pot sits awkwardly on your head. (worn armor)
  Your wool cloak drapes over your shoulders. (worn cloak)
  Your leather boots protect your feet. (worn boots)
```

Degradation is reflected in appearance:

```
> LOOK IN MIRROR (after pot cracks)
You see yourself:
  A cracked ceramic pot sits on your head, pieces threatening to fall.
```

---

## Part 12: Common Questions

### Q: What if I want an object that provides no protection but is wearable?

**A:** Don't include armor metadata:

```lua
wear = {
    slot = "head",
    layer = "inner",
    coverage = 1.0,
    -- NO material armor
}
```

Without armor metadata, it's a hat that can be worn but provides no protection. Perfectly valid.

### Q: Can I have layered armor that stacks?

**A:** Yes! Wear multiple items on the same slot, different layers:

```
Inner: wool cap (protection: 1.0)
Outer: steel helm (protection: 6.0)

Result: both protect against head injury in sequence
Incoming 5 damage → 5 - 1.0 (wool) = 4 → 4 - 6.0 (steel) = 0 → minimum 1
Final damage: 1 (armor is very good)
```

### Q: What if a material should be armor but a specific object shouldn't be?

**A:** Don't use the `wear` metadata for that object:

```lua
-- Ceramic can be armor normally
material = "ceramic"

-- But THIS specific vase can't be worn
wear = nil  -- explicitly no-wear
```

### Q: Can armor protect against non-injury damage?

**A:** Not in V1. The armor system only hooks into the injury/damage system. Other game systems (environmental, falling, etc.) are separate. Future expansions could integrate armor more broadly.

### Q: What happens if armor is destroyed? Can I repair it?

**A:** Destroyed armor (shattered state) is usually terminal in V1. A future crafting system might allow repair, but that's beyond the current scope.

### Q: Can I create a "masterwork" material?

**A:** No. Fit is the quality multiplier:

```lua
wear = {
    material = "ceramic",
    fit = "masterwork",  -- × 2 protection multiplier
}
```

Use `fit` to indicate quality, not new materials.

---

## Part 13: Future Extensions

These are ideas for expansion, but **NOT part of Phase A2**:

### Possible Future: Elemental Armor

Armor that resists specific damage types (fire, cold, poison). Requires:
- New damage type system
- Material property for elemental resistance
- New degradation narratives

### Possible Future: Armor Enchantments

Items with magical effects (blessing, curse, bonus). Requires:
- Magical system architecture
- Integration with armor before-interceptor

### Possible Future: Armor Condition Repair

Allowing players to repair degraded armor. Requires:
- Crafting system
- Repair skill
- Material consumption (fabric for patching, metal for hammering, etc.)

### Possible Future: Armor Weight and Carry Limits

Tracking total armor weight against carrying capacity. Requires:
- Weight system architecture
- Carrying capacity per player

### Possible Future: Environmental Wear

Armor degrading due to weather, time, or environment:
- Rust in wet areas (iron armor)
- Fading in sunlight (fabric)
- Warping in heat (leather)

---

## Summary

The armor system connects three pieces you already have:

1. **Material Registry** — 22 materials with numeric properties
2. **Wearable System** — wearing/removing items on slots
3. **Effects Pipeline** — intercepting damage before it applies

As a designer, you:

1. **Choose a material** — `material = "ceramic"` (22 options)
2. **Add wear metadata** — `wear = { slot, layer, coverage, fit }`
3. **Let the engine do the rest** — protection, degradation, narration all emerge

**The core philosophy:** Protection is **derived from material**, never hardcoded. A ceramic pot works because ceramic is hard and dense, not because we wrote `provides_armor = 1`. When it breaks, it's because ceramic is fragile, not because we scripted a break animation.

This is Dwarf Fortress design: **the engine operates on property bags, emergent behavior is free.**

---

## Document Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-03-24 | CBG | Initial design document — armor philosophy, material table, examples, integration guidance |

---

## See Also

- `docs/architecture/engine/armor-system.md` — Architecture document (implementation details)
- `docs/design/material-properties-system.md` — Material property mechanics
- `src/engine/materials/init.lua` — Material registry (22 materials)
- `src/engine/effects.lua` — Effects pipeline architecture
- `src/engine/injuries.lua` — Injury system
- `src/engine/verbs/init.lua` — Wearable system
- `docs/design/design-directives.md` — Core game design principles

---

*End of Armor System Design Document*
