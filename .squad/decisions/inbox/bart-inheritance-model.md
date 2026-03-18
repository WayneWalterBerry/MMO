# Decision: Object Inheritance / Template System + Extended Object Model

**Author:** Bart (Architect)  
**Date:** 2026-03-19  
**Status:** Implemented  
**Impact:** Architecture-level; affects object definitions, loader, registry, containment, mutation

---

## Summary

Three interlocking systems added to the engine:

1. **Template Inheritance** — Objects can declare `template = "sheet"` to inherit base properties. The loader deep-merges the template under instance overrides. Instance always wins.

2. **Weight + Categories** — All objects now carry `weight` (number) and `categories` (table of strings). Containers carry `weight_capacity`. The containment validator checks weight alongside size.

3. **Multi-Surface Containment** — Objects can define `surfaces = { top = {...}, inside = {...} }` to support multiple containment zones. Each zone has its own capacity, max_item_size, weight_capacity, and accessibility flag.

---

## Template System

### Templates created (`src/meta/templates/`)
| Template | Purpose | Key defaults |
|----------|---------|-------------|
| `sheet.lua` | Fabric/cloth family | size 1, weight 0.2, portable, tearable |
| `furniture.lua` | Heavy immovable objects | size 5, weight 30, not portable |
| `container.lua` | Bags, boxes, chests | container true, capacity 4, weight_capacity 10 |
| `small-item.lua` | Tiny portable items | size 1, weight 0.1, portable |

### Resolution rules
- `loader.resolve_template(object, templates)` performs deep merge
- Nested tables (mutations, surfaces) are recursively merged
- The `template` field is removed after resolution — does not exist at runtime
- If a template references another template, that's not supported (single-level only, by design)

---

## Object Model Extensions

### All objects now include:
- `weight` — numeric weight value
- `categories` — table of string tags (e.g., `{"fragile", "reflective"}`)
- `material` — string identifying the material

### Containers additionally include:
- `weight_capacity` — maximum total weight of contents
- `max_item_size` — largest single item size allowed

### Multi-surface objects include:
- `surfaces` — table of named zones, each with:
  - `capacity` (number)
  - `max_item_size` (number)
  - `weight_capacity` (number)
  - `accessible` (boolean, default true)
  - `contents` (table)

---

## Engine Changes

| File | Changes |
|------|---------|
| `engine/loader/init.lua` | Added `resolve_template()`, `load_template()`, `deep_merge()` |
| `engine/registry/init.lua` | Added `find_by_category()`, `total_weight()`, `contents_weight()` |
| `engine/containment/init.lua` | Created — 4-layer validator with weight + multi-surface |
| `engine/mutation/init.lua` | Surface content preservation, optional template re-resolution |

---

## Rationale

- **Templates are single-level** — deep inheritance chains create debugging nightmares. One level of `template` covers 90% of cases. If we need more, we add it later.
- **Weight is continuous, not tiered** — unlike size (where tiers simplify "does it fit?" checks), weight benefits from exact values for realistic stacking and capacity calculations.
- **Surfaces use `accessible` flag, not absence** — a locked drawer still *has* contents; it's just not accessible. This lets mutation carry contents correctly when toggling accessibility.
- **Template resolution is a loader concern** — the registry doesn't need to know about templates. By the time an object enters the registry, it's fully resolved.
