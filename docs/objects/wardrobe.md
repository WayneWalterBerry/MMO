# Wardrobe — Object Design

## Description
A towering oak wardrobe with carved acorn-and-oak-leaf doors. Container with inside surface. Holds wool-cloak and sack at game start.

**Material:** `oak`

## FSM States

```
closed ↔ open
```

- **closed** — Doors shut. Inside surface not accessible. Cedar smell through doors.
- **open** — Doors flung wide. Inside accessible. Cedar and moth-eaten wool smell.

## Sensory Descriptions

| State | Look | Feel | Smell |
|-------|------|------|-------|
| closed | Towering oak wardrobe, carved doors firmly shut | Massive wooden frame, carved acorn handles | Cedar, sharp and sweet |
| open | Wardrobe open, cedar-lined interior, wooden pegs | Frame with doors swung wide on iron hinges | Cedar released into room, trace of moth-eaten wool |

## Surfaces

- **inside:** capacity 8, max_item_size 4. Accessible only when open.
- Initial contents: wool-cloak, sack

## Transitions

| From | To | Verb | Message |
|------|-----|------|---------|
| closed | open | open | Pull heavy doors open, iron hinges groan, cedar billows out |
| open | closed | close | Push doors shut with solid thud |

## Mutate Fields (Added 2026-07-20)

| Transition | Mutate |
|---|---|
| closed → open | `keywords = { add = "open" }` |
| open → closed | `keywords = { remove = "open" }` |

**Design rationale:** "LOOK IN OPEN WARDROBE" resolves via keyword. Consistent with window/curtains open/close pattern.

## Properties

- **Size:** 9, **Weight:** 60, **Portable:** No
- **Categories:** furniture, wooden, large, container
- **Keywords:** wardrobe, armoire, closet, cabinet, clothes

## What Changed (2026-07-20)

- Added `material = "oak"` metadata field
- Added `mutate` fields to open/close transitions (keywords ±open)
