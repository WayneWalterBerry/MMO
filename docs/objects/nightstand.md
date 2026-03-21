# Nightstand — Object Design

## Description
A squat knotted-pine nightstand crusted with candle wax. Composite object with a detachable drawer. Has top surface and inside (drawer) surface.

**Material:** `oak`

## Composite Structure

```
nightstand (parent)
  ├── drawer (detachable part, carries contents)
  └── legs (non-detachable part)
```

## FSM States

```
closed_with_drawer ↔ open_with_drawer
        ↓ (detach)         ↓ (detach)
closed_without_drawer   open_without_drawer
        ↕ (reattach)       ↕ (reattach)
```

- **closed_with_drawer** — Default. Drawer closed, inside not accessible.
- **open_with_drawer** — Drawer slid open, inside accessible.
- **closed_without_drawer** — Drawer removed. Empty slot.
- **open_without_drawer** — Drawer removed. Empty slot visible.

## Sensory Descriptions

| State | Look | Feel |
|-------|------|------|
| closed_with_drawer | Squat pine nightstand, wax-crusted top, drawer closed | Smooth wood, wax drippings, drawer handle |
| open_with_drawer | Pine nightstand, wax drippings, drawer open | Smooth wood, wax drippings, drawer slides open |
| closed_without_drawer | Pine nightstand, empty slot where drawer was | Smooth wood, empty slot at front |
| open_without_drawer | Pine nightstand, empty rectangular slot | Smooth wood, empty slot |

## Surfaces

- **top:** capacity 3, max_item_size 2
- **inside:** capacity 2, max_item_size 1. Accessible only when drawer open.

## Transitions

| From | To | Verb | Mutate |
|------|-----|------|--------|
| closed_with_drawer | open_with_drawer | open | `keywords = { add = "open" }` |
| open_with_drawer | closed_with_drawer | close | `keywords = { remove = "open" }` |
| open_with_drawer | open_without_drawer | detach_part (drawer) | `weight = function(w) return w - 2 end` |
| closed_without_drawer | closed_with_drawer | reattach_part (drawer) | `weight = function(w) return w + 2 end` |
| open_without_drawer | open_with_drawer | reattach_part (drawer) | `weight = function(w) return w + 2 end` |

## Properties

- **Size:** 4, **Weight:** 15, **Portable:** No
- **Categories:** furniture, wooden
- **Keywords:** nightstand, night stand, bedside table, side table, small table

## What Changed (2026-07-20)

- Added `material = "oak"` metadata field
- Added `mutate` fields: keywords ±open for drawer open/close, weight ±2 for drawer detach/reattach
