# Decision: Player Model is Canonical State Source

**Date:** 2026-03-30  
**Author:** Bart (Architect)  
**Issue:** #104  
**Status:** Implemented  

## Decision

All player state MUST live on `ctx.player`. No player-related data on `ctx` root level.

## What Changed

- `visited_rooms` moved from `ctx.visited_rooms` → `ctx.player.visited_rooms`
- All engine code and tests updated to use `ctx.player.visited_rooms`

## Rule Going Forward

When adding new player state (e.g., quest flags, reputation, discovered secrets), put it on `ctx.player` or a sub-table like `ctx.player.state`. Never on `ctx` directly.

## Who Should Know

- **Moe** — room definitions don't change, but movement verb now reads `ctx.player.visited_rooms`
- **Smithers** — parser/verb code should access player state via `ctx.player`
- **Nelson** — test mock contexts must put `visited_rooms` on `ctx.player`, not `ctx`
- **Gil** — web adapter updated; `web/dist/` will need rebuild
