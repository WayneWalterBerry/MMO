# Curtains — Object Design

## Description
Heavy faded burgundy velvet curtains hanging across the window. Can be opened to let in daylight or closed to block it. Tearable (destructive mutation spawns cloth + rag).

**Material:** `velvet`

## FSM States

```
closed ↔ open
```

- **closed** — Drawn shut, blocking light. Dusty folds pool on floor. Moth holes let through pinpricks of grey light.
- **open** — Pulled aside, bunched against wall. Pale grey light spills in. Dust motes swirl.

## Sensory Descriptions

| State | Look | Feel | Smell |
|-------|------|------|-------|
| closed | Faded burgundy velvet, drawn closed, moth-eaten | Heavy fabric, thick folds, dense weave | Dusty neglect of years |
| open | Burgundy curtains pulled aside, dust motes in light | Heavy velvet, bunched, slightly damp near window | Dust stirred from folds |

## Transitions

| From | To | Verb | Mutate |
|------|-----|------|--------|
| closed | open | open (aliases: draw, pull) | `keywords = { add = "open" }` |
| open | closed | close (aliases: draw, pull) | `keywords = { remove = "open" }` |

## Destructive Mutations

| Action | Result |
|--------|--------|
| tear | Curtains destroyed. Spawns: cloth ×2, rag ×1 |

## Properties

- **Size:** 4, **Weight:** 4, **Portable:** No
- **Categories:** fabric, soft, window covering
- **Keywords:** curtains, drapes, curtain, velvet, window covering
- **Special:** `filters_daylight = true` (closed), `allows_daylight = true` (open)

## What Changed (2026-07-20)

- Added `material = "velvet"` metadata field
- Added `mutate` fields to open/close transitions (keywords ±open)
