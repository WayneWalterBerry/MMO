# Chamber Pot — Object Design

## Description
A squat ceramic chamber pot with chipped blue-and-white glaze. Mercifully empty. Can be worn as makeshift head armor (pot-on-head trope). Also functions as a container.

**Material:** `ceramic`

## States (FSM Degradation)

| State | Description |
|-------|-------------|
| `intact` (default) | Whole pot, chipped glaze but structurally sound |
| `cracked` | Visible crack from rim to base, one more hit finishes it |
| `shattered` | Ceramic fragments — spawns ceramic-shard ×2, pot destroyed |

### Transitions
- `intact` → `cracked`: hit, kick, strike, smash
- `cracked` → `shattered`: hit, kick, strike, smash (spawns ceramic shards)

## Sensory Descriptions

| Sense | Description |
|-------|-------------|
| Look | Squat ceramic pot, chipped blue-and-white glaze, mercifully empty |
| Feel | Smooth-glazed ceramic, cold, chipped rim |
| Smell | Memory of purpose lingers, even empty |
| Smell (worn) | "You catch a faint whiff of... you'd rather not think about it." |

## Wearable — Improvised Helmet (Issue #54)

The chamber pot can be worn on the head as improvised armor. This is a real-world object creativity feature: people CAN put pots on their heads, and the game should allow it.

### Equip Metadata

| Property | Value | Notes |
|----------|-------|-------|
| `wear.slot` | `head` | Equips to head slot |
| `wear.layer` | `outer` | Outer layer (conflicts with other outer headgear) |
| `wear.coverage` | `0.8` | 80% head coverage — it's a bowl, not a full helm |
| `wear.fit` | `makeshift` | Makeshift fit — loose, improvised |
| `wear.wear_quality` | `makeshift` | Triggers comedic wear narration |
| `wear_slot` | `head` | Top-level — engine helmet detection (appearance + concussion) |
| `is_helmet` | `true` | Top-level — semantic tag for engine helmet queries |

### Armor — Material-Derived (Phase A7)

Armor protection is **no longer hardcoded**. The engine armor interceptor calculates protection from the object's material properties:

- `material = "ceramic"` → engine reads ceramic hardness, density, fragility from material registry
- Coverage (`0.8`) and fit (`makeshift`) further modify the calculation
- No `provides_armor` or `reduces_unconsciousness` on the object — engine derives these

This follows the Dwarf Fortress property-bag philosophy: objects declare what they ARE (ceramic, helmet-shaped, 80% coverage), and the engine figures out what that MEANS for protection.

### Behavior

- **Wear:** `wear pot` / `put pot on head` → equips to head slot
  - Engine narration (makeshift armor): *"You place a ceramic chamber pot on your head. It makes a ridiculous helmet, but you feel... slightly tougher?"*
  - One-shot flavor: *"This is going to smell worse than I thought."*
- **Remove:** `remove pot` / `take off pot` → frees head slot
- **Conflict:** Can't wear pot if another outer-layer headgear is already equipped. Player must remove existing headgear first. (Standard slot/layer conflict — engine handles this.)

### Appearance / Mirror

When worn and player looks in mirror or examines appearance:
- `appearance.worn_description`: *"A ceramic chamber pot sits absurdly atop your head."*
- Read by `engine/player/appearance.lua` → `render_head()` function

### Design Intent

Wayne's vision: mundane real-world objects should have creative emergent uses. A chamber pot IS a bowl that fits on a head. The game rewards lateral thinking with functional (if comedic) results. This is the Dwarf Fortress philosophy — objects have properties, and the simulation respects those properties.

## Container

- **Capacity:** 2
- Can hold small items

## Properties

- **Size:** 2, **Weight:** 3, **Portable:** Yes
- **Categories:** ceramic, container, fragile, wearable
- **Keywords:** chamber pot, pot, ceramic pot, toilet, chamberpot, privy, helmet, head pot, improvised helmet

## Changelog

### 2026-07-27 — Phase A7: Material-derived armor migration
- **REMOVED** hardcoded `provides_armor = 1` from wear table
- **REMOVED** top-level `reduces_unconsciousness = 1`
- **ADDED** `coverage = 0.8` and `fit = "makeshift"` to wear table
- **ADDED** FSM degradation: intact → cracked → shattered (3 states, 2 transitions)
- **ADDED** `event_output.on_wear` one-shot flavor text
- Armor protection now derived from `material = "ceramic"` via engine armor interceptor
- `is_helmet = true` retained as semantic tag (engine hint, not protection source)

### 2026-07-27 — Shatter on drop (Issue #56)
- Added `mutations.shatter` with `spawns = {"ceramic-shard", "ceramic-shard"}` and narration
- When dropped on a hard surface (stone hardness ≥ 5), the pot shatters via the on_drop fragility system
- Spawns 2 ceramic shards as debris; original pot is removed from room
- Controlled by material properties: ceramic fragility (0.7) ≥ threshold (0.5) + floor hardness ≥ 5
- Soft floors (e.g., wood hardness 4) prevent shattering

### 2026-07-27 — Wearable as improvised helmet (Issue #54)
- Added `wear_slot = "head"`, `is_helmet = true`, `reduces_unconsciousness = 1` (top-level engine detection)
- Added `appearance.worn_description` for mirror/appearance narration
- Added `on_smell_worn` for worn-state smell feedback
- Added helmet-related keywords: helmet, head pot, improvised helmet
- Added file header comment with doc and issue references
- Updated design doc with full wearable specification

### 2026-07-20
- Added `material = "ceramic"` metadata field
