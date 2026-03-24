# Armor System — Architecture

**Version:** 1.0  
**Date:** 2026-03-24  
**Author:** Bart (Architect)  
**Status:** Design Document (Phase A1)  
**Decision:** D-ARMOR-SYSTEM (to be filed)  
**Requested by:** Wayne "Effe" Berry  

**Prerequisite reading:**
- `docs/architecture/engine/effects-pipeline.md` (v2.0) — before/after interceptor infrastructure
- `docs/architecture/engine/injuries.lua` — injury infliction, FSM states, healing
- `docs/design/material-properties-system.md` — material property definitions
- `src/engine/materials/init.lua` — material registry (22 materials, 11 properties each)

---

## 1. Design Principle

**Armor protection MUST be derived from material properties, not hardcoded per-object.** 

The engine operates on property bags, not object type names. A ceramic pot on your head protects based on ceramic's `hardness: 7` and `fragility: 0.7` — NOT because we wrote `provides_armor = 1` on the pot object.

This aligns with the Dwarf Fortress principle: the simulation engine generates emergent consequences from physical properties. The same ceramic pot can be a helmet, a container, a tool, a missile, or a decorative display. The engine never asks *what* it is; it asks *what it's made of* and derives behavior from that.

---

## 2. Architecture Overview

### 2.1 System Components

| Component | Role | Location |
|-----------|------|----------|
| **Material Registry** | Property bags (hardness, flexibility, density, etc.) for 22 materials | `src/engine/materials/init.lua` |
| **Wearable System** | 9 slots, 3 layers, worn item tracking | `src/engine/verbs/init.lua` (wear verb) |
| **Effects Pipeline** | Before/after interceptor infrastructure | `src/engine/effects.lua` |
| **Injury System** | Injury infliction, FSM states, health computation | `src/engine/injuries.lua` |
| **Armor Interceptor** | Before-effect interceptor that reduces injury damage based on worn armor | `src/engine/effects.lua` (registered handler) |

### 2.2 Integration Flow

```
ATTACK: knife stab → Effects Pipeline → before-effect interceptor
                                             ↓
                                     Query: what is player wearing on {injury.location}?
                                             ↓
                                     Found: chamber-pot on head (material: ceramic)
                                             ↓
                                     Lookup: materials.get("ceramic")
                                     Result: hardness: 7, flexibility: 0.0, density: 2300, fragility: 0.7
                                             ↓
                                     Calculate: protection = f(hardness, flexibility, density)
                                     Calculate: break_chance = f(fragility, impact_force)
                                             ↓
                                     Reduce damage: effect.damage = max(1, damage - protection)
                                             ↓
                                     Check degradation: roll against break_chance
                                     If failed → armor state transition (intact → cracked → shattered)
                                             ↓
                                     Continue to inflict_injury handler (reduced damage or cancelled)
```

---

## 3. Protection Formula

### 3.1 Base Protection Calculation

Protection is a dimensionless value (0–50 typical range) derived from material properties:

```
protection = hardness × hardness_weight + flexibility × flexibility_weight + density_factor × density_weight

where:
  hardness_weight ≈ 2.0      (primary contributor)
  flexibility_weight ≈ 1.0   (absorbs impact, prevents cracking)
  density_weight ≈ 0.5       (mass helps stop force; diminishing returns)
  density_factor = min(1.0, density / 3000)  (cap: beyond 3000 kg/m³, density doesn't scale)
```

**Reference material values:**

| Material | hardness | flexibility | density | protection |
|----------|----------|-------------|---------|------------|
| steel | 9 | 0.3 | 7850 | 9×2.0 + 0.3×1.0 + 1.0×0.5 ≈ **19.3** |
| ceramic | 7 | 0.0 | 2300 | 7×2.0 + 0.0×1.0 + 0.77×0.5 ≈ **14.4** |
| leather | 3 | 0.6 | 850 | 3×2.0 + 0.6×1.0 + 0.28×0.5 ≈ **6.4** |
| fabric | 1 | 1.0 | 300 | 1×2.0 + 1.0×1.0 + 0.10×0.5 ≈ **3.1** |
| glass | 6 | 0.0 | 2500 | 6×2.0 + 0.0×1.0 + 0.83×0.5 ≈ **12.4** |

### 3.2 Armor Template Modifiers

Objects may declare a `coverage` factor and `fit` property to adjust effective protection:

```lua
wear = {
    slot = "head",
    layer = "outer",
    coverage = 0.8,  -- How much of the slot does this cover? (0.0–1.0)
                     -- 1.0 = full coverage (steel helm), 0.8 = partial (chamber pot on head)
                     -- Engine default if omitted: 1.0
    fit = "makeshift", -- "makeshift" (0.5×), "fitted" (1.0×), "masterwork" (1.2×)
                       -- Multiplier on protection value
                       -- Engine default if omitted: "fitted"
}
```

**Final protection calculation:**

```
effective_protection = base_protection × coverage × fit_multiplier
```

**Example:**

```lua
-- Chamber pot as makeshift helmet
wear = { slot = "head", layer = "outer", coverage = 0.8, fit = "makeshift" }
material = "ceramic"

base_protection = 14.4 (ceramic)
coverage multiplier = 0.8
fit multiplier = 0.5 (makeshift)
effective_protection = 14.4 × 0.8 × 0.5 = 5.76 → round to 6
```

### 3.3 Damage Reduction

When an injury effect fires on a location with worn armor:

```lua
-- Query worn items for this injury location
local worn_items = query_worn_by_location(effect.location)

-- Sum protection from all layers (inner + outer both contribute)
local total_protection = 0
for _, item in ipairs(worn_items) do
    total_protection = total_protection + calculate_protection(item)
end

-- Reduce damage (minimum 1: armor never fully negates)
effect.damage = math.max(1, effect.damage - total_protection)
```

---

## 4. Slot-to-Location Mapping

Armor only protects injuries that match its slot. The injury system tracks `injury.location` (body area); the armor system tracks `wear.slot` (equipment slot).

### 4.1 Standard Mappings

| Slot | Valid Injury Locations |
|------|-------------------------|
| `head` | head, forehead, temple, eye, ear, jaw, cheek, face, scalp |
| `torso` | torso, chest, ribs, abdomen, back, spine, shoulder, side |
| `left_arm` | left arm, left shoulder, left elbow, left wrist, left hand |
| `right_arm` | right arm, right shoulder, right elbow, right wrist, right hand |
| `left_leg` | left leg, left hip, left knee, left ankle, left foot |
| `right_leg` | right leg, right hip, right knee, right ankle, right foot |
| `hands` | left hand, right hand, hands, fingers (covers both) |
| `feet` | left foot, right foot, feet (covers both) |
| `neck` | neck, throat |

### 4.2 Location Resolution

The injury system passes `injury.location` as a string when inflicting an injury:

```lua
-- Example from a weapon effect
injuries.inflict(
    player,
    "minor-cut",
    "knife",
    "left arm",  -- injury.location
    5            -- damage
)
```

The armor interceptor queries: "What is the player wearing in slots that cover 'left arm'?" It checks armor slots `head`, `left_arm`, `hands`, and `feet` (nothing covers all locations, but armor may be combined).

### 4.3 Exact Match Requirement

An injury location must **exactly match** at least one string in the mapping, or it receives no armor protection. Designers must use canonical location names from the table above. This prevents defense gaps (typos like "left-arm" instead of "left arm") from silently disabling armor.

---

## 5. Material Degradation

Armor doesn't last forever. When it absorbs significant impact, it may crack, dent, or shatter. This is modeled via FSM state transitions on the armor object.

### 5.1 Degradation Formula

After armor reduces damage, check if it degrades:

```lua
-- High fragility materials (ceramic, glass) more likely to break
-- Low fragility materials (steel, leather) more resistant
-- Larger impacts more likely to degrade

break_chance = fragility × (original_damage / 20) × impact_type_factor

where:
  impact_type_factor: piercing 0.5, slashing 1.0, blunt 1.5
  original_damage: the damage BEFORE armor reduction
```

**Example:**

```lua
-- Ceramic pot (fragility 0.7) absorbs a 12-damage blunt hit
-- break_chance = 0.7 × (12 / 20) × 1.5 = 0.63 (63% chance to crack)

-- Steel helmet (fragility 0.05) absorbs the same hit
-- break_chance = 0.05 × (12 / 20) × 1.5 = 0.0045 (0.45% chance to dent)
```

### 5.2 Degradation States

Armor objects transition through FSM states as they take damage:

```
intact ──(break_chance failed)──→ cracked ──(break_chance failed again)──→ shattered
   │                                  │                                        │
   └──────────────────────────────────┴────────────────────────────────────────┘
                              (each degradation reduces protection)
```

**State transitions and effects:**

| State | Protection Multiplier | Armor Integrity | Narration |
|-------|----------------------|------------------|-----------|
| `intact` | 1.0× | Fully functional | (no message) |
| `cracked` | 0.7× | Damaged but wearable | "Your ceramic pot develops a hairline crack." |
| `shattered` | 0.0× | Useless | "Your ceramic pot shatters into pieces." |

**Implementation:** When break_chance is met, the armor interceptor fires a `mutate` effect to transition the object's `_state` field:

```lua
-- Fire state transition on the armor object
effects.process({
    type = "mutate",
    target = armor_object.id,
    field = "_state",
    value = "cracked"
}, ctx)
```

### 5.3 Shattered Armor

Once armor reaches the `shattered` state, it provides zero protection. Designers may choose:
1. Make it unwearable (the object remains but cannot be worn)
2. Make it drop/disappear (transition to a "fragments" state, then remove from inventory)
3. Make it permanently damaged (the shattered state applies permanently; regenerating armor is future design)

**Default behavior:** A shattered armor item is still worn but provides 0 protection. Designers can override by adding an `on_shatter` transition in the armor object's FSM that removes it from play.

---

## 6. Armor Template Specification

### 6.1 Object Declaration Pattern

Wearable armor objects must declare:

**Required:**
- `material` (string) — references a key in `materials.registry`
- `wear` (table) — slot assignment and wear properties

**Optional:**
- `wear.coverage` (0.0–1.0, default 1.0) — what fraction of the slot this covers
- `wear.fit` (string, default "fitted") — "makeshift" | "fitted" | "masterwork"
- `wear_slot` (legacy, deprecated) — use `wear.slot` instead

### 6.2 Example Armor Objects

**Steel helmet (full protection):**

```lua
return {
    id = "steel-helm",
    name = "iron helm",  -- Display name only; material defines properties
    description = "A sturdy iron helmet with a burnished finish.",
    material = "iron",   -- Engine derives protection: hardness 8, density 7870
    wear = {
        slot = "head",
        layer = "outer",
        coverage = 1.0,   -- Full head coverage
        fit = "fitted",   -- Professionally made
    },
}
```

**Chamber pot as makeshift helmet:**

```lua
return {
    id = "chamber-pot",
    name = "chamber pot",
    description = "A ceramic pot, formerly used for... personal matters.",
    material = "ceramic",  -- Engine derives: hardness 7, fragility 0.7
    wear = {
        slot = "head",
        layer = "outer",
        coverage = 0.8,   -- Only covers most of head, gaps around face
        fit = "makeshift", -- Not designed for this; 50% protection penalty
    },
    _state = "intact",
    states = {
        intact = {
            description = "A ceramic pot, formerly used for... personal matters.",
            room_presence = "A ceramic pot sits here.",
        },
        cracked = {
            description = "A ceramic pot with hairline cracks running through it.",
            room_presence = "A cracked ceramic pot sits here.",
        },
        shattered = {
            description = "Shattered ceramic fragments.",
            room_presence = "Ceramic shards lie scattered here.",
        },
    },
}
```

**Leather armor (flexible, durable):**

```lua
return {
    id = "leather-armor",
    name = "leather armor",
    description = "Well-worn leather armor, scarred from combat.",
    material = "leather",  -- Engine derives: hardness 3, flexibility 0.6, fragility 0.0
    wear = {
        slot = "torso",
        layer = "outer",
        coverage = 1.0,
        fit = "fitted",
    },
    _state = "intact",
    -- Leather never breaks (fragility 0.0), so degradation states omitted
}
```

### 6.3 What the Engine Derives

The engine **automatically calculates** these properties at wear-time; objects should NOT declare them:

- `provides_armor` (legacy, removed)
- `reduces_damage` (legacy, removed)
- `reduces_unconsciousness` (legacy, removed)
- `impact_resistance` (any ad-hoc armor metric)

These should be **purged from all armor objects**. The engine reads `material` and `wear` only. Everything else is derived.

---

## 7. Before-Effect Interceptor

### 7.1 Interceptor Registration

The armor interceptor is registered in `src/engine/effects.lua` during initialization:

```lua
effects.add_interceptor("before", function(effect, ctx)
    -- Armor reduction logic
    if effect.type ~= "inflict_injury" then return end
    
    -- Query worn armor for this injury location
    local worn_items = query_worn_by_location(effect.location)
    if not worn_items or #worn_items == 0 then return end  -- No armor
    
    -- Calculate total protection and reduce damage
    -- ... (full implementation in Phase A4 by Smithers)
end)
```

### 7.2 Context Passed to Interceptor

The before-interceptor receives:

```lua
effect = {
    type = "inflict_injury",
    injury_type = "minor-cut",
    location = "left arm",  -- The body area being injured
    damage = 5,             -- Original damage (will be reduced if armor matches)
    source = "knife",
    message = "...",
}

ctx = {
    player = <player object>,     -- Player state (contains player.worn)
    source = <object>,            -- Attacker object (for messaging)
    registry = <registry>,        -- Object registry
}
```

### 7.3 Interceptor Lifecycle

1. **Before Phase:** Armor interceptor runs FIRST. It may reduce `effect.damage` or cancel the effect entirely.
2. **Handler Phase:** `inflict_injury` handler runs (processes reduced/cancelled effect).
3. **After Phase:** Narration and logging interceptors run.

The interceptor returns:
- `nil` or nothing — effect proceeds normally (possibly with reduced damage)
- `"cancel"` — effect is cancelled (armor or immunity prevents injury entirely)

---

## 8. Worn Item Querying

### 8.1 Player Worn Armor Storage

The player state stores worn items in a `worn` array, tracking slot and layer:

```lua
player.worn = {
    -- Slot entry
    {
        slot = "head",
        items = {
            -- Layer entry
            { layer = "inner", object = <object> },
            { layer = "outer", object = <object> },
        }
    },
    -- Another slot
    {
        slot = "torso",
        items = {
            { layer = "outer", object = <object> },
        }
    },
}
```

### 8.2 Query Function Signature

```lua
function query_worn_by_location(injury_location)
    -- Input: injury_location (string, e.g., "left arm")
    -- Output: array of worn armor objects that cover this location
    --         ordered by layer (inner → outer)
    -- Returns: {} if no armor covers this location
end
```

**Implementation:**
1. Map `injury_location` to slot(s) using the standard mapping table (Section 4.1)
2. Iterate `player.worn` and find all items in matching slots
3. Return them sorted by layer priority (inner first, then outer)

**Example:**

```lua
-- Input: injury_location = "left arm"
-- Mapped slots: { "left_arm", "hands" }
-- Found in player.worn:
--   - left_arm/inner: none
--   - left_arm/outer: leather-bracers
--   - hands/outer: leather-gloves
-- Output: { leather-bracers, leather-gloves }
```

### 8.3 Multi-Layer Stacking

When multiple armor pieces cover the same location (different layers), **both contribute** to protection:

```lua
total_protection = 0
for _, armor_object in ipairs(worn_items) do
    total_protection = total_protection + calculate_protection(armor_object)
end

effect.damage = math.max(1, effect.damage - total_protection)
```

This models the reality that wearing a cloth tunic (inner) and leather armor (outer) both help. The damage must pass through both layers.

---

## 9. Material Consistency Principle

### 9.1 The Principle

Every armor object MUST reference a material from `src/engine/materials/init.lua`. The engine trusts that:
- The material name exists in the registry
- The material's properties (hardness, flexibility, density, fragility) accurately represent the physical object
- The armor's `wear.coverage` and `wear.fit` are sensible for the material and historical period

### 9.2 Instance Overrides

Objects MAY override individual material properties via fields like `fragility_override`:

```lua
return {
    id = "enchanted-steel-helmet",
    material = "steel",
    fragility_override = 0.0,  -- This steel helm never breaks (enchanted)
    wear = { slot = "head", layer = "outer" },
}
```

**Rule:** Instance overrides should be documented as exceptions and justified (e.g., "enchanted", "reinforced", "masterwork"). They should not become the default; they should remain rare and intentional.

### 9.3 Why Material Consistency Matters

1. **Predictability** — Content authors know that "ceramic" always means hardness 7, fragility 0.7. No surprises.
2. **Reusability** — New armor objects use existing materials without engine changes.
3. **Physics Simulation** — Material properties cascade to other systems: density → weight, flammability → burning, conductivity → electricity.
4. **Emergent Gameplay** — A ceramic pot can be armor, a container, a tool, or a projectile. The engine doesn't hardcode its behavior; it derives from ceramic properties.

---

## 10. Integration Diagram

```
Material Registry               Armor Object
(src/engine/materials/init.lua) (src/meta/objects/)
        │                            │
        │ materials.get("ceramic")   │ { material: "ceramic", wear: {...} }
        │                            │
        └────────────────┬───────────┘
                         │
                    Properties
                  (hardness: 7,
                   fragility: 0.7,
                   density: 2300)
                         │
                    ┌────┴─────┐
                    │           │
            Protection Formula  Degradation Formula
         (base_protection)   (break_chance)
                    │           │
                    └────┬───────┘
                         │
        Effects Pipeline Before-Interceptor
         (src/engine/effects.lua)
                         │
          ┌──────────────┼──────────────┐
          │              │              │
    Query Worn Items  Reduce Damage  Check Degradation
    (left_arm, head)  (effect.damage) (fragility × impact)
          │              │              │
          │              │         Mutate Object State
          │              │        (intact→cracked→shattered)
          │              │              │
          └──────────────┼──────────────┘
                         │
           Injury Handler (src/engine/injuries.lua)
         Inflicts reduced damage (or cancelled)
                         │
                   Player Health
               (derived from injuries)
```

---

## 11. Example Scenarios

### 11.1 Scenario: Ceramic Pot Helmet vs Stab

**Setup:** Player is wearing chamber pot (ceramic, makeshift fit) on head. Receives stab from knife.

**Calculation:**

```
1. Knife effect: type="inflict_injury", location="head", damage=10

2. Armor interceptor queries: worn items covering "head"
   → chamber-pot (material="ceramic", coverage=0.8, fit="makeshift")

3. Protection calculation:
   - base_protection = 7×2.0 + 0.0×1.0 + (2300/3000)×0.5 = 14.4 + 0.38 = 14.78
   - effective = 14.78 × 0.8 × 0.5 = 5.9 → round to 6

4. Damage reduction:
   - reduced_damage = max(1, 10 - 6) = 4

5. Degradation check:
   - break_chance = 0.7 (fragility) × (10/20) × 0.5 (piercing) = 0.175 (17.5%)
   - Roll: assume failed (73% chance to survive intact)
   - State: remains "intact"

6. Injury inflicted:
   - inflict_injury handler receives damage=4
   - "You feel a sharp jab on your head. The chamber pot absorbs most of the blow." (narration)
   - Head injury recorded: type="minor-cut", location="head", damage=4
```

### 11.2 Scenario: Ceramic Pot Helmet Takes Two Blunt Hits

**Setup:** Chamber pot is now "cracked" from a previous hit. Receives another blunt attack (12 damage).

**Calculation:**

```
1. Blunt effect: type="inflict_injury", location="head", damage=12

2. Armor interceptor queries worn items
   → chamber-pot in state="cracked" (protection multiplier 0.7x)

3. Protection with degraded state:
   - effective_protection = 5.9 × 0.7 = 4.13 → round to 4

4. Damage reduction:
   - reduced_damage = max(1, 12 - 4) = 8

5. Degradation check:
   - break_chance = 0.7 × (12/20) × 1.5 (blunt) = 0.63 (63% chance to shatter)
   - Roll: assume failed (37% survive cracked state, 63% shatter)
   - State: transitions to "shattered"

6. Shattered state consequences:
   - Future attacks: protection = 0 (shattered provides nothing)
   - Narration: "Your ceramic pot shatters into pieces!"
   - Player still wearing fragments (object remains; design choice: may auto-drop or become unwearable)

7. Injury inflicted:
   - Health penalty increased from degraded armor: damage=8
   - "A heavy blow strikes your head. The ceramic shatters against the impact." (narration)
```

### 11.3 Scenario: Leather Armor vs Slash

**Setup:** Player wearing leather armor (material="leather") on torso. Receives slash from sword.

**Calculation:**

```
1. Slash effect: type="inflict_injury", location="torso", damage=8

2. Armor interceptor queries: worn items covering "torso"
   → leather-armor (material="leather", coverage=1.0, fit="fitted")

3. Protection calculation:
   - base = 3×2.0 + 0.6×1.0 + (850/3000)×0.5 = 6 + 0.6 + 0.14 = 6.74
   - effective = 6.74 × 1.0 × 1.0 = 6.74 → round to 7

4. Damage reduction:
   - reduced_damage = max(1, 8 - 7) = 1

5. Degradation check:
   - break_chance = 0.0 (leather never breaks) × anything = 0 (no degradation)
   - State: remains "intact" forever

6. Injury inflicted:
   - damage=1 (nearly absorbed; leather saved you)
   - "Your leather armor absorbs most of the blade."
```

---

## 12. Phase A1 Completion Checklist

This architecture document covers:

- [x] How protection is derived from material properties (formulas using hardness, flexibility, density)
- [x] How the before-effect interceptor queries worn items by injury location
- [x] Slot-to-location mapping (head slot → head injuries, etc.)
- [x] Degradation model (fragility → crack → shatter FSM states)
- [x] Armor template specification (what objects declare vs what engine derives)
- [x] Integration diagram: materials.lua ↔ effects.lua ↔ injuries.lua ↔ wear system
- [x] Cross-references to existing docs (effects-pipeline.md, material-properties-system.md)

**Next phases:**
- **Phase A2:** Design doc (CBG) — designer-facing examples, material × damage type matrix, degradation narratives
- **Phase A3:** Unit tests (Nelson) — armor reduces damage, location matching, material degradation
- **Phase A4:** Implementation (Smithers) — armor interceptor in effects.lua
- **Phase A6:** Equipment event hooks (Bart + Smithers) — on_wear, on_remove_worn callbacks

---

## References

1. **`docs/architecture/engine/effects-pipeline.md`** (v2.0) — Before/after interceptor infrastructure, effect normalization
2. **`docs/design/material-properties-system.md`** — Material property definitions and emergent behaviors
3. **`src/engine/materials/init.lua`** — Complete material registry (22 materials)
4. **`src/engine/effects.lua`** — Effect processor implementation
5. **`src/engine/injuries.lua`** — Injury infliction and FSM state management
6. **`src/engine/verbs/init.lua`** — Wear verb handler and wearable system
7. **Dwarf Fortress Design Philosophy** — Property-bag simulation systems, emergent gameplay from material properties (D-DF-ARCHITECTURE decision)
