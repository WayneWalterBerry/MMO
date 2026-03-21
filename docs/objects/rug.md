# Rug — Object Design

## Description
A threadbare rug on the stone floor with faded crimson-and-gold pattern. Covers the trap door. Movable — pulling it aside reveals the trap door beneath.

**Material:** `wool`

## States

No FSM — static object. Movable via pull mechanic. Covering relationship hides the trap door.

## Sensory Descriptions

| Sense | Description |
|-------|-------------|
| Look | Faded crimson and gold pattern, frayed edges, worn thin center, one corner raised |
| Feel | Rough woven textile, frayed edges, one corner slightly raised |

## Surfaces

- **underneath:** capacity 3, max_item_size 2. Contents: brass-key

## Covering

- `covering = {"trap-door"}` — hides the trap door until rug is moved
- Move message: grab edge, pull aside, bunch against wall

## Properties

- **Size:** 5, **Weight:** 8, **Portable:** No, **Movable:** Yes
- **Categories:** fabric, floor covering
- **Keywords:** rug, carpet, mat, floor covering

## What Changed (2026-07-20)

- Added `material = "wool"` metadata field
