# Small Item Template

> Base pattern for tiny portable objects: keys, coins, shards, pebbles, etc.

## Purpose

The Small Item template provides **minimal portable objects** for inventory fillers and essential quest items. Objects inheriting from this template are lightweight, space-efficient, and highly versatile — perfect for keys, currency, tools, and collectibles.

**Typical objects:** Key, coin, shard, pebble, seed, button, gem, ring, needle, match

## Default Properties

| Property | Default | Purpose |
|----------|---------|---------|
| `id` | `"small-item"` | Template identifier |
| `guid` | `"c2960f69-67a2-42e4-bcdc-dbc0254de113"` | Unique template ID |
| `name` | `"a small item"` | Display name (overridden by instances) |
| `keywords` | `{}` | Search aliases (overridden per-item) |
| `description` | `"A small item."` | Generic description (nearly always overridden) |
| `size` | `1` | Minimal footprint |
| `weight` | `0.1` | Very light |
| `portable` | `true` | **Always** can be picked up |
| `material` | `"generic"` | Default material (overridden per-item) |
| `container` | `false` | Not a container |
| `capacity` | `0` | No containment |
| `contents` | `{}` | Empty (not used) |
| `location` | `nil` | Where the item is |
| `categories` | `{}` | Empty by default (specific per-item) |
| `mutations` | `{}` | No default mutations |

## Small Item Characteristics

### Portability

`portable = true` means:
- Players can **always** pick up the item
- Item occupies 1 slot in any container
- Item fits in any inventory space
- Item is immediately useful

This is by design — small items should never be immobile or stuck.

### Minimal Weight

`weight = 0.1` means:
- **10 small items = 1 unit of weight** (same as 1 sheet)
- **100 small items = 10 units** (max weight for a container)

Players can accumulate dozens of small items without cargo burden.

### Generic Material

`material = "generic"` is the default. Instances override:
- `"metal"` — Coins, nails, keys
- `"stone"` — Pebbles, gems, shards
- `"wood"` — Seeds, matches, splinters
- `"glass"` — Shards, beads
- `"fabric"` — Buttons, threads
- `"bone"` — Dice, needles

## Mutations

The Small Item template has **no default mutations**. Instances define transformations:

```lua
mutations = {
  break = {becomes = nil, spawns = {"shard", "shard"}},  -- Gem breaks into shards
  light = {becomes = nil, spawns = {"flame"}},  -- Match ignites
}
```

## Objects Using This Template

Common instances include:

**Quest Items:**
- `key` — Opens locked containers/doors
- `ring` — Worn item, quest device
- `token` — Pass or credential

**Currency:**
- `coin` — Generic currency

**Collectibles:**
- `shard` — Glass, crystal, or gem pieces
- `pebble` — Stone pieces
- `button` — Decorative items

**Tools & Materials:**
- `needle` — Sewing, piercing
- `match` — Fire starting
- `seed` — Planting, growing

Check `src/meta/objects/` for the complete inventory.

## Design Notes

### Portable by Default

Unlike Furniture (immobile) or Container (limited capacity), small items are **always portable**. This reflects real life:
- A key fits in any pocket
- A coin is instantly useful
- A button can be carried anywhere

If an item should be heavy/immobile, use the **Furniture** template instead.

### No Categories

Small Items default to `categories = {}` because they are **specific instances**, not category templates. Each item defines its own categories:

```lua
categories = {"metal", "currency"}  -- coin
categories = {"stone", "collectible"}  -- pebble
categories = {"tool", "fire"}  -- match
```

### Inventory Slot Efficiency

Small items occupy **1 slot each**, regardless of material. The engine doesn't distinguish between:
- 1 coin vs. 1 key vs. 1 shard
- All stack as single items

Volume is abstract — focus is on **count**, not realistic size.

### Quest Mechanics

Small items are ideal for quests:
- Keys unlock puzzles
- Tokens grant access
- Collectibles mark progress

Define quest-specific `on_examine` behaviors in the instance to integrate with quest hooks.

## Implementation Reference

- **File:** `src/meta/templates/small-item.lua`
- **Used by:** Inventory, containment, and quest systems
- **Related Verbs:** `GET`, `DROP`, `EXAMINE`, `USE`

---

**See Also:** [Sheet Template](./sheet.md), [Container Template](./container.md), [Verb System](../design/verb-system.md)
