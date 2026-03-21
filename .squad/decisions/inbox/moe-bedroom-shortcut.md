# Decision: Bedroom North Door — Barred, Not Keyed

**Author:** Moe (World Builder)  
**Date:** 2026-03-21  
**Source:** Nelson Pass-014 bug report (nelson-bedroom-north-bypass.md)  
**Status:** ✅ IMPLEMENTED

## Problem

The bedroom north exit led directly to the hallway (Level 1 completion room) with `open = true, locked = false`. Players could skip the entire cellar puzzle chain by typing "go north" from the start room.

## Decision

**Bar the door from the hallway side** rather than locking it with a key.

### Why a bar, not a key lock:
1. **Narrative fit:** Someone imprisoned the player in the bedroom. Barring the door from outside is how you trap someone in a medieval manor — it's sinister and intentional.
2. **No keyhole exploit:** A lock implies a key exists somewhere. If the key were findable in the bedroom (like the brass key under the rug), the shortcut would persist. A bar has no keyhole — there's nothing to pick, nothing to unlock from the wrong side.
3. **Clean hallway-side interaction:** When the player reaches the hallway via the deep cellar stairway, they see the bar and can lift it with a simple "unlock" (no key required). This reconnects the rooms for backtracking.
4. **Break remains as high-cost alternate:** The door is still breakable (difficulty 3). A determined/creative player can smash through, but that's an earned shortcut with consequences (spawns splinters, destroys the door).

## Changes Made

### start-room.lua (bedroom north exit)
- `open`: true → **false**
- `locked`: false → **true**
- `key_id`: nil (unchanged — no keyhole on this side)
- Description updated: mentions iron bar on the far side, no keyhole
- Removed `lock`/`unlock` mutations (meaningless from barred side)
- Added `condition` to `open` mutation (checks `not self.locked`)
- Kept `break` mutation unchanged

### hallway.lua (hallway south exit)
- `open`: true → **false**
- `locked`: false → **true**
- `key_id`: "brass-key" → **nil** (bar, not a lock)
- Description updated: describes the iron bar in brackets
- `unlock` mutation: lifts the bar (no key required)
- `lock` mutation: replaces the bar
- Added `condition` to `open` mutation (checks `not self.locked`)

### Documentation updated
- `docs/levels/01/rooms/start-room.md` — north exit section
- `docs/levels/01/rooms/hallway.md` — south exit section
- `docs/levels/01/level-01-intro.md` — alternate path description

## Impact

- The Level 1 critical path is now enforced: bedroom → cellar → storage cellar → deep cellar → hallway
- Backtracking from hallway to bedroom is preserved (lift bar from hallway side)
- The break alternate path adds player agency without trivializing the puzzle chain
