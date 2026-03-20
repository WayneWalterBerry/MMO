# Object Design Patterns

**Last updated:** 2026-03-21  
**Audience:** Game Designers  
**Purpose:** Patterns for designing complex objects with multiple surfaces, states, and interactions.

---

## Multi-Surface Containment Model

**Pattern:** Objects with multiple interaction zones use `surfaces` instead of flat `contents`. Each surface has `capacity`, `max_item_size`, `weight_capacity`, and `accessible` flag.

**Examples:**
- **Bed:** `top` (where you sleep), `underneath` (storage)
- **Nightstand:** `top` (surface), `inside` (drawer)
- **Vanity:** `top` (surface), `inside` (drawer), `mirror_shelf`
- **Rug:** `top` (visible), `underneath` (hidden)

**Design Rule:** Never hide critical-path items without a hint. Example: rug description says "one corner is slightly raised" → hints at LOOK UNDER without spoiling.

---

## Composite Mutation Matrix (Multi-State Objects)

**Pattern:** When an object has N independent toggleable properties, it requires 2^N mutation files.

**Example - Vanity (2 axes: drawer open/closed × mirror intact/broken = 4 files):**
- `vanity.lua` — drawer closed, mirror intact
- `vanity-open.lua` — drawer open, mirror intact
- `vanity-mirror-broken.lua` — drawer closed, mirror broken
- `vanity-open-mirror-broken.lua` — drawer open, mirror broken

**Trade-off:** File count grows exponentially with independent states. For most objects (1 axis), this is fine. For 3+ axes, consider whether some states can be collapsed or chained.

---

## Template Inheritance

**Pattern:** Objects that share a base type use `template = "sheet"` to inherit default properties from `src/meta/templates/sheet.lua`. Instance overrides win.

**Template Examples:**
- `sheet.lua` — Fabric/cloth family (size 1, weight 0.2, portable, tearable)
- `furniture.lua` — Heavy immovable (size 5, weight 30, not portable)
- `container.lua` — Bags, boxes, chests (capacity 4, weight_capacity 10)
- `small-item.lua` — Tiny items (size 1, weight 0.1, portable)

**Design Rule:** Template resolution happens at load time. Instance fields override template fields. Nested tables (mutations, surfaces) are replaced wholesale, not deep-merged.

---

## Room Object Hierarchy

**Pattern:** Room `contents` lists only top-level furniture. Portable items live inside furniture surfaces, not directly in the room. This creates a natural discovery hierarchy: enter room → see furniture → examine furniture → find items.

**Example - Bedroom start state:**
```
Bedroom
├── bed (furniture)
│   ├── top (surface) → bed-sheets, pillow
│   └── underneath (surface) → wool-cloak
├── nightstand (furniture)
│   ├── top → candle
│   └── inside → (empty)
├── vanity (furniture)
│   ├── top → (empty)
│   └── inside → (empty)
├── wardrobe (furniture)
│   ├── inside → (empty)
├── curtains (furniture)
│   └── window behind
├── rug (furniture)
│   └── underneath → brass-key (hidden)
```

---

## See Also

- **Design Directives:** `design-directives.md` (core game rules)
- **Composite Objects:** `composite-objects.md` (player-facing mechanics)
- **Spatial System:** `spatial-system.md` (ON/UNDER/BEHIND relationships)
