# Sheet Template

> Base pattern for fabric and textile objects: sheets, curtains, rags, cloth, paper, etc.

## Purpose

The Sheet template provides lightweight **textile-based objects** that can be manipulated, torn, and transformed. Objects inheriting from this template are soft, flexible materials that support state changes through mutations.

**Typical objects:** Sheet, curtain, rag, cloth, napkin, bandage, paper, parchment, sail, tapestry

## Default Properties

| Property | Default | Purpose |
|----------|---------|---------|
| `id` | `"sheet"` | Template identifier |
| `guid` | `"ada88382-de1e-4fbc-908c-05d121e02f84"` | Unique template ID |
| `name` | `"a sheet"` | Display name (overridden by instances) |
| `size` | `1` | Compact; takes minimal space |
| `weight` | `0.2` | Very light |
| `portable` | `true` | Can be picked up and carried |
| `material` | `"fabric"` | Textile composition |
| `container` | `false` | Not a container |
| `capacity` | `0` | No containment |
| `contents` | `{}` | Empty (not used for sheets) |
| `location` | `nil` | Where the sheet is located |
| `categories` | `{"fabric"}` | For grouping and queries |
| `mutations` | `{tear = {becomes = nil, spawns = {"cloth"}}}` | Tears into cloth scraps |

## Textile Mutations

### Tear Mutation

The Sheet template includes a **tear mutation**:

```lua
mutations = {
  tear = { becomes = nil, spawns = {"cloth"} }
}
```

**Behavior:**
- When `TEAR` verb is applied, the sheet is **destroyed** (`becomes = nil`)
- One or more **cloth scraps** are spawned in its place (`spawns = {"cloth"}`)

**Gameplay effect:** Players can tear sheets into usable cloth scraps for various purposes.

### Custom Mutations

Instance sheets may define additional mutations:

```lua
mutations = {
  tear = {becomes = nil, spawns = {"cloth", "cloth"}},  -- tears into 2 scraps
  burn = {becomes = nil, spawns = {"ash"}},  -- burns to ash
  cut = {becomes = nil, spawns = {"strip", "strip"}},  -- cuts into strips
}
```

## Surfaces & Interactions

The Sheet template does **not** define surfaces. Sheets are typically:
- Picked up and held
- Torn or damaged
- Used as wrapping or covering
- Placed on furniture surfaces

Complex uses (e.g., wrapping items in a sheet) are handled by verb overrides in instance objects.

## FSM States

Sheets may track state:
- **Torn/Intact** — Original vs. damaged condition
- **Wet/Dry** — Moisture state
- **Soiled/Clean** — Cleanliness
- **Folded/Spread** — Organization state

State is tracked per-instance, not in the template.

## Objects Using This Template

Common instances include:
- `sheet` — Plain linen sheet
- `cloth` — Generic cloth scrap (spawned by tearing)
- `rag` — Dirty cloth
- `curtain` — Decorative hanging
- `bandage` — Medical cloth
- `parchment` — Paper-like material
- `sail` — Ship canvas
- `tapestry` — Woven wall hanging

Check `src/meta/objects/` for the complete inventory.

## Design Notes

### Why Small & Light?

Sheets default to `size = 1`, `weight = 0.2` because:
- Real cloth is compact when folded
- Textiles are among the lightest materials
- Players naturally carry cloth for multiple purposes (wrapping, climbing, patching)

Heavier cloth objects (like tapestries) override `weight` accordingly.

### Tear as Transformation

The tear mutation is **intentional decomposition**:
- Players tear sheets into cloth scraps
- Cloth scraps are used for different tasks (bandaging, climbing, fire starting)
- This creates a "decomposition chain" — larger textiles break into smaller, more versatile pieces

### Crafting Integration

Cloth scraps serve as inputs to crafting systems:
- **Bandages** — Cloth + healing potion → Healing item
- **Rope** — Multiple cloth strips twisted together
- **Armor padding** — Cloth + leather → Padded protection

### No Container Role

Unlike Container or Furniture templates, sheets are **not interaction points**. Players don't store items inside a sheet (though wrapping logic could be added via custom verbs).

## Implementation Reference

- **File:** `src/meta/templates/sheet.lua`
- **Used by:** Object mutation system
- **Related Verbs:** `TEAR`, `BURN`, `CUT`, `EXAMINE`

---

**See Also:** [Small Item Template](./small-item.md), [Object Mutations](../architecture/objects/core-principles.md), [Verb System](../design/verb-system.md)
