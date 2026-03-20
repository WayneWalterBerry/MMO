# Decision: Wearable Object System Architecture

**Author:** Bart (Architect)
**Date:** 2026-03-25
**Status:** Implemented
**Impact:** Engine architecture, object metadata, verb system

## Decision

Wearable items use **object-owned metadata** (`wear = { slot, layer }`). The engine enforces conflicts but never hardcodes slot names — any string is a valid slot. This means new body locations can be invented by content authors without engine changes.

## Key Rules

1. **One inner + one outer per slot** — accessories are unlimited (up to `max_per_slot`)
2. **Vision blocking** is a wear property (`blocks_vision = true`), checked separately from room darkness
3. **Legacy support** — objects with `wearable = true` but no `wear` table default to `torso/outer`
4. **Player.worn** is a flat list (same pattern as `player.hands`) — slot queries iterate it

## Rationale

- Matches D-14 (objects own their own state) — wear metadata lives in the object file
- No enum of valid slots means content can grow without engine PRs
- Flat worn list is simple and sufficient — slot-indexed maps would add complexity for marginal gain at current scale

## Files Changed

- `src/engine/verbs/init.lua` — wear/remove handlers, conflict algorithm, vision blocking
- `src/engine/loop/init.lua` — NLP preprocessing for put on/take off
- `src/meta/objects/` — wool-cloak, sack, chamber-pot, terrible-jacket wear metadata
