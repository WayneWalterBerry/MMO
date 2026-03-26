# Body Zone System

**File:** `src/engine/combat/init.lua`  
**Author:** Bart (Architecture)  
**Date:** 2026-07-XX  
**Version:** 1.0 (GATE-6)

---

## Overview

The body zone system divides combatants into spatially distinct target regions. Each zone has:
- **Size weight** for random selection probability
- **Vital flag** indicating if damage causes system-level effects
- **Tissue layers** ordered from outer to inner (skin → flesh → bone → organ)
- **Damage consequences** (optional: movement penalties, weapon drop effects)

Zone targeting is probabilistic: aimed shots hit 60% of the time; misses fall to adjacent zones. Zone selection during defense is weighted by zone size.

---

## Zone Structure

### body_tree Table

Each combatant defines a `body_tree` property containing zones:

```lua
body_tree = {
    head = { size = 1, vital = true, tissue = { "skin", "flesh", "bone" } },
    torso = { size = 4, vital = true, tissue = { "skin", "flesh", "bone", "organ" } },
    arms = { size = 2, vital = false, tissue = { "skin", "flesh", "bone" } },
    legs = { size = 2, vital = false, tissue = { "skin", "flesh", "bone" } },
}
```

#### Fields

| Field | Type | Purpose |
|-------|------|---------|
| `size` | number | Weight for random zone selection (higher = more likely to be hit randomly) |
| `vital` | boolean | If `true`, critical hits to this zone can cause system-level effects (organ damage) |
| `tissue` | array | Ordered list of tissue layer names, outer to inner. See Material System for layer properties. |
| `on_damage` | array | Optional: consequence IDs applied when zone takes damage (e.g., `"reduced_movement"` on leg damage) |

### Zone Examples

#### Head (Rat)
- **Size:** 1 (small target)
- **Vital:** true (brain/eyes)
- **Tissue:** `{ "hide", "flesh", "bone" }` — no organs (rat-specific anatomy)

#### Torso (Player)
- **Size:** 4 (largest target)
- **Vital:** true (heart, lungs, organs exposed)
- **Tissue:** `{ "skin", "flesh", "bone", "organ" }` — full layer stack
- **Damage consequence:** none (torso damage applies directly)

#### Arms (Both)
- **Size:** 2 (medium target)
- **Vital:** false (limb loss is permanent, not system-fatal)
- **Tissue:** `{ "skin", "flesh", "bone" }` — no organs
- **Damage consequence:** `"weapon_drop"` (severe arm damage drops held weapon), `"reduced_attack"` (broken arm reduces force)

#### Legs (Both)
- **Size:** 2 (medium target)
- **Vital:** false (limb loss is permanent, not system-fatal)
- **Tissue:** `{ "skin", "flesh", "bone" }` — no organs
- **Damage consequence:** `"reduced_movement"` (broken leg slows movement), `"prone"` (critical leg damage causes falling)

---

## Zone Targeting

### Aimed Attack

**Accuracy Rate:** 60% (controlled by `accuracy` parameter in `select_zone()`)

When a player targets a specific zone:

1. Roll random value [0, 1]
2. If roll ≤ accuracy (default 0.6): hit target zone
3. If roll > 0.6: miss target, select random adjacent zone using weighted selection

**Code:**
```lua
local function select_zone(body_tree, target_zone, allow_target, accuracy)
    if not body_tree or next(body_tree) == nil then return target_zone or "body" end
    local target_accuracy = accuracy or 0.6
    if target_zone and allow_target and body_tree[target_zone] then
        if math.random() <= target_accuracy then
            return target_zone  -- Hit!
        end
        return weighted_zone(body_tree, target_zone) or target_zone  -- Miss → adjacent
    end
    return weighted_zone(body_tree, nil) or target_zone  -- Random selection
end
```

### Weighted Random Selection

Zones are selected probabilistically using cumulative weight distribution:

**Algorithm:**
1. Collect all zones (excluding optional exclude zone)
2. Sum zone sizes into total weight
3. Roll [0, total]
4. Accumulate sizes until accumulation ≥ roll value
5. Return hit zone

**Example (rat):**
- head: size=1
- body: size=3
- legs: size=2
- tail: size=1
- **Total weight:** 7

Roll = 4.2:
- Accumulate: head (0→1), body (1→4), legs (4→6)
- Hit zone: legs (4.2 falls between 4 and 6)

**Code:**
```lua
local function weighted_zone(body_tree, exclude)
    local zones, total = zone_weights(body_tree, exclude)
    if #zones == 0 then return nil end
    local roll = math.random() * total
    local acc = 0
    for _, entry in ipairs(zones) do
        acc = acc + entry.weight
        if roll <= acc then return entry.id end
    end
    return zones[#zones].id
end
```

### Accuracy Scaling

Accuracy is weapon-dependent:

- **Weapons with force ≥ 7:** 100% accuracy (high-force weapons are predictable)
- **Weapons with force < 7:** 60% accuracy (default, subject to player skill in Phase 2)

**Code:**
```lua
local accuracy = weapon_force >= 7 and 1.0 or 0.6
```

---

## Tissue Layers

Zones contain ordered tissue layers from outside to inside. Each layer has distinct material properties (density, hardness, flexibility) that affect penetration.

### Layer Order

Typical layer order (outer to inner):
1. **Skin/Hide** — protective outer layer (low density, high flexibility)
2. **Flesh** — muscle and fat (moderate density, moderate flexibility)
3. **Bone** — structural support (high density, low flexibility)
4. **Organ** — vital systems (very low density, high fragility)

### Layer Penetration

During damage resolution, layers are checked sequentially from outside in:

**For edged/pierce weapons:**
```
penetration_force = (base_force × weapon.max_edge) - (layer.hardness × THICKNESS)
if penetration_force > 0: layer is penetrated, reduce force for next layer
else: stop penetration, deepest layer hit is result
```

**For blunt weapons:**
```
transfer_force = base_force × (1.0 - layer.flexibility)
layer_damage = transfer_force - (layer.hardness × THICKNESS × 0.5)
remaining_force = transfer_force × 0.8 (decay for next layer)
if layer_damage > 0: layer is damaged
```

### Severity by Layer Hit

The deepest layer penetrated determines combat severity:

| Deepest Layer Hit | Severity | Example |
|-------------------|----------|---------|
| (none) | DEFLECT | Glances off skin |
| skin/hide | GRAZE | Shallow cut, minor bleeding |
| flesh | HIT | Cuts into muscle, moderate bleeding |
| bone | SEVERE | Fracture or blunt force trauma |
| organ | CRITICAL | Vital organ damage, potentially fatal |

---

## Material Integration

Each tissue layer is a **material** with properties defined in `src/engine/materials/`:

### Tissue Materials

| Material | Density | Hardness | Flexibility | Max Edge | Fragility | Purpose |
|----------|---------|----------|-------------|----------|-----------|---------|
| skin | 1050 | 1 | 0.7 | — | 0.6 | Player outer layer |
| hide | 1100 | 2 | 0.6 | — | 0.5 | Creature outer layer |
| flesh | 1050 | 1 | 0.8 | — | 0.7 | Muscle/fat (all) |
| bone | 1900 | 6 | 0.05 | — | 0.3 | Skeletal structure |
| organ | 1050 | 0.5 | 0.9 | — | 0.8 | Vital systems |
| tooth_enamel | 2900 | 5 | 0.0 | 4 | 0.4 | Rat natural weapon |
| keratin | 1300 | 3 | 0.2 | 3 | 0.3 | Creature claws |

### Weapon Materials

Weapon materials (steel, bone, wood) determine force calculation:

```
base_force = weapon_material.density × combatant_size_modifier × weapon.force × FORCE_SCALE
```

**FORCE_SCALE constant:** 0.1 (tuning factor for game balance)

---

## Zone Damage Consequences

When a zone takes significant damage, optional consequences are applied:

### Consequence Types

| Consequence | Effect | Trigger |
|-------------|--------|---------|
| `weapon_drop` | Player drops held weapon in favoring hand | Arm damage (severity ≥ SEVERE) |
| `reduced_attack` | Arm damage reduces attack force (pending Phase 2 injury system) | Arm damage (severity ≥ HIT) |
| `reduced_movement` | Leg damage slows movement speed (pending Phase 2 injury system) | Leg damage (severity ≥ SEVERE) |
| `prone` | Critical leg damage causes fall (pending Phase 2 injury system) | Leg damage (severity = CRITICAL) |
| `balance_loss` | Tail damage affects balance (creature-specific) | Tail damage (severity ≥ HIT) |

**Implementation (Phase 2):** Consequences are stored in the `result` table but enforcement happens via the injury system in `engine/injuries.lua`.

---

## Size Modifiers

Combatant size affects force calculation:

```lua
SIZE_MODIFIERS = {
    tiny = 0.5,
    small = 1.0,
    medium = 2.0,
    large = 4.0,
    huge = 8.0,
}
```

### Size Calculation

Base force for an attack is modified by both attacker and defender size:

**Force calculation:**
```
base_force = material.density × SIZE_MODIFIERS[attacker.size] × weapon.force × FORCE_SCALE
zone_accuracy = (weapon.force >= 7) and 1.0 or 0.6
```

**Interpretation:**
- **Tiny attacker:** Force is halved (rat punch)
- **Medium attacker:** Force is doubled (player punch)
- **Huge attacker:** Force is 8× (giant, if added in Phase 2)

---

## Body Tree Definition Guidelines

### For Players

```lua
body_tree = {
    head  = { size = 1, vital = true,  tissue = { "skin", "flesh", "bone" } },
    torso = { size = 4, vital = true,  tissue = { "skin", "flesh", "bone", "organ" } },
    arms  = { size = 2, vital = false, tissue = { "skin", "flesh", "bone" }, on_damage = { "weapon_drop", "reduced_attack" } },
    legs  = { size = 2, vital = false, tissue = { "skin", "flesh", "bone" }, on_damage = { "reduced_movement", "prone" } },
}
```

### For Creatures (Rat Example)

```lua
body_tree = {
    head = { size = 1, vital = true, tissue = { "hide", "flesh", "bone" } },
    body = { size = 3, vital = true, tissue = { "hide", "flesh", "bone", "organ" } },
    legs = { size = 2, vital = false, tissue = { "hide", "flesh", "bone" }, on_damage = { "reduced_movement" } },
    tail = { size = 1, vital = false, tissue = { "hide", "flesh" }, on_damage = { "balance_loss" } },
}
```

### Rules

- **Head/vitals:** Must include bone layer (protection)
- **Torso/core:** Include organ layer only
- **Limbs:** Exclude organ layer
- **Size total:** Should sum to 8–10 for balanced targeting
- **Tissue outer-to-inner:** Always order from protective (skin/hide) → structural (bone) → vital (organ)

---

## Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| `THICKNESS` | 1000 | Hardness factor for layer penetration calculation |
| `FORCE_SCALE` | 0.1 | Scaling factor for base force calculation |
| Default accuracy | 0.6 | 60% chance to hit aimed zone |
| Weapon force ≥ 7 threshold | 7 | High-force weapons achieve 100% accuracy |

---

## See Also

- **Combat FSM:** `docs/architecture/combat/combat-fsm.md` — Zone selection happens in the RESOLVE phase
- **Damage Resolution:** `docs/architecture/combat/damage-resolution.md` — Tissue penetration algorithm details
- **Material System:** `docs/design/material-properties-system.md` — Material properties used in layer calculation
