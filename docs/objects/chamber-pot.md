# Chamber Pot — Object Design

## Description
A squat ceramic chamber pot with chipped blue-and-white glaze. Mercifully empty. Can be worn as makeshift head armor (pot-on-head trope). Also functions as a container.

**Material:** `ceramic`

## States

No FSM — static object.

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
| `wear.provides_armor` | `1` | Minimal protection — it's a pot, not a helm |
| `wear.wear_quality` | `makeshift` | Triggers comedic wear narration |
| `wear_slot` | `head` | Top-level — engine helmet detection (appearance + concussion) |
| `is_helmet` | `true` | Top-level — engine helmet detection (belt-and-suspenders) |
| `reduces_unconsciousness` | `1` | Reduces KO duration by 1 turn on head hits |

### Behavior

- **Wear:** `wear pot` / `put pot on head` → equips to head slot
  - Engine narration (makeshift armor): *"You place a ceramic chamber pot on your head. It makes a ridiculous helmet, but you feel... slightly tougher?"*
- **Remove:** `remove pot` / `take off pot` → frees head slot
- **Conflict:** Can't wear pot if another outer-layer headgear is already equipped. Player must remove existing headgear first. (Standard slot/layer conflict — engine handles this.)

### Appearance / Mirror

When worn and player looks in mirror or examines appearance:
- `appearance.worn_description`: *"A ceramic chamber pot sits absurdly atop your head."*
- Read by `engine/player/appearance.lua` → `render_head()` function

### Protection

- **Armor value:** 1 (minimal — ceramic is fragile)
- **KO reduction:** `reduces_unconsciousness = 1` — reduces concussion unconsciousness duration by 1 turn
- Read by `engine/verbs/init.lua` concussion system — any worn item with `wear_slot == "head"` or `is_helmet == true` qualifies

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

### 2026-07-27 — Wearable as improvised helmet (Issue #54)
- Added `wear_slot = "head"`, `is_helmet = true`, `reduces_unconsciousness = 1` (top-level engine detection)
- Added `appearance.worn_description` for mirror/appearance narration
- Added `on_smell_worn` for worn-state smell feedback
- Added helmet-related keywords: helmet, head pot, improvised helmet
- Added file header comment with doc and issue references
- Updated design doc with full wearable specification

### 2026-07-20
- Added `material = "ceramic"` metadata field
