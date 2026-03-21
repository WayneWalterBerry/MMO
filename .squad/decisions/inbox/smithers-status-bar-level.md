# Decision: Status Bar Now Shows Level Name

**Author:** Smithers (UI Engineer)  
**Date:** 2026-07-18  
**Status:** Implemented (partial — needs Moe's room data)  
**Affects:** `src/engine/ui/status.lua`, `docs/architecture/ui/README.md`

---

## What Changed

The status bar now shows:

```
 Lv 1: The Awakening — THE BEDROOM  2:00 AM      Matches: 7  Candle: o
```

Previously it showed only:

```
 THE BEDROOM  2:00 AM      Matches: 7  Candle: o
```

## Implementation

`status.lua` now includes:

1. **`LEVEL_MAP`** — A hardcoded lookup table mapping room IDs → `{ number, name }`.
   This is an interim solution. It covers all known rooms for Level 1.

2. **`status.get_level(room)`** — Checks `room.level` first (future-proof), then falls back to `LEVEL_MAP`.

3. **Updated `create_updater()`** — Left side of the status bar now shows `Lv N: Level Name — ROOM NAME`.

## What Moe Needs To Do

**Add a `level` field to every room `.lua` file** in `src/meta/world/`. Format:

```lua
return {
    -- ... existing fields ...
    level = { number = 1, name = "The Awakening" },
    -- ...
}
```

Once rooms carry their own `level` field, `status.get_level()` will prefer it over the hardcoded `LEVEL_MAP`, which can then be removed.

**Rooms needing the field:**
- `start-room.lua` → `{ number = 1, name = "The Awakening" }`
- `cellar.lua` → `{ number = 1, name = "The Awakening" }`
- Any future rooms Moe adds

## Rationale

- Wayne requested level visibility in the status bar.
- Rooms don't currently declare their level — this is a data-model gap.
- Hardcoded lookup is acceptable for V1 (2 rooms), but won't scale. The `room.level` field is the proper long-term solution.
- Status bar formatting is purely Smithers's domain; room data is Moe's.
