# Bed — Object Design

## Description
A massive four-poster bed with dark wooden frame carved with vines and faces. Straw-and-wool mattress. Heavy moth-eaten curtains hang from posts. Movable — can be pushed off the rug to reveal what's underneath.

**Material:** `wood`

## States

No FSM — static object. Movable via push mechanic.

## Sensory Descriptions

| Sense | Description |
|-------|-------------|
| Look | Massive four-poster, dark wood frame, carved vines and faces, straw mattress, moth-eaten curtains |
| Feel | Soft mattress, warm coverings, carved wooden frame with vines and faces |
| Smell | Musty linen, old straw, ghost of lavender |

## Surfaces

- **top:** capacity 8, max_item_size 5. Contents: pillow, bed-sheets, blanket
- **underneath:** capacity 4, max_item_size 3. Contents: knife (hidden)

## Movement

- `resting_on = "rug"` — bed sits on the rug initially
- Push message: scrapes across flagstones, slides off rug
- After move: "shoved to one side, curtains swaying"

## Properties

- **Size:** 10, **Weight:** 80, **Portable:** No, **Movable:** Yes
- **Categories:** furniture, wooden, large
- **Keywords:** bed, four-poster, poster bed, four poster, mattress, bedframe

## What Changed (2026-07-20)

- Added `material = "wood"` metadata field
