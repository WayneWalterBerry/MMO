# Pass-014: Critical Path Test — Level 1

**Date:** 2026-03-21  
**Tester:** Nelson (QA)  
**Build:** Post BUG-048 / BUG-050 fixes by Flanders  
**Focus:** Verify BUG-048 (crate `.inside` surface) and BUG-050 (duplicate presences) fixes  
**Start:** `lua src/main.lua --start-room start-room`

---

## Summary

| Category | Tests | Passed | Failed | Notes |
|----------|-------|--------|--------|-------|
| Bedroom Setup | 5 | 5 | 0 | Feel, drawer, matchbox, GOAP light candle |
| Bedroom Puzzle | 4 | 4 | 0 | Push bed, pull rug, brass key, trap door |
| Cellar Navigation | 3 | 3 | 0 | Unlock + open door with brass key, go north |
| **Crate Interaction (BUG-048)** | **6** | **5** | **1** | **Iron key accessible — FIX VERIFIED** |
| Deep Cellar → Hallway | 3 | 3 | 0 | Unlock with iron key, go up to hallway |
| Duplicate Presences (BUG-050) | 2 | 2 | 0 | **Hallway clean — FIX VERIFIED** |
| Inventory Management | 3 | 3 | 0 | Two-hand limit, drop/get cycle works |
| **TOTAL** | **26** | **25** | **1** | |

**RESULT: ✅ CRITICAL PATH COMPLETE — Bedroom → Cellar → Storage Cellar → Deep Cellar → Hallway**

---

## BUG-048 Verification (CRITICAL — Crate `.inside` Surface)

### ✅ FIXED — Iron key is now accessible inside the crate

| Test | Command | Result | Status |
|------|---------|--------|--------|
| Open crate with crowbar in hand | `get crowbar` → `open crate` | "You jam the crowbar under the lid and heave. Nails shriek as they pull free..." | ✅ PASS |
| Open crate via GOAP (crowbar in room) | `open crate` (crowbar not in hand) | GOAP auto-resolves crowbar from room, opens crate | ✅ PASS |
| Look inside opened crate | `look inside crate` | "You find inside a pried-open crate: a heavy iron key" | ✅ PASS |
| Feel inside opened crate | `feel inside crate` | "Your fingers find inside: a heavy iron key" | ✅ PASS |
| Take iron key (after dropping crowbar) | `drop crowbar` → `get iron key` | "You take a heavy iron key." | ✅ PASS |
| Pry crate | `pry crate` | "I don't understand that." | ❌ FAIL (BUG-049 still open) |

**Transcript — Crate Interaction:**
```
> get crowbar
You take an iron crowbar.
> open crate
You jam the crowbar under the lid and heave. Nails shriek as they pull free,
and the lid comes away in a shower of splinters and rust. Inside: a heavy sack
nestled in straw packing.
> look inside crate
You find inside a pried-open crate:
  a heavy iron key
> feel inside crate
Your fingers find inside:
  a heavy iron key
Your fingers find top:
  a small wooden crate
> drop crowbar
You drop an iron crowbar.
> get iron key
You take a heavy iron key.
```

---

## BUG-050 Verification (Duplicate Presences)

### ✅ FIXED — No duplicate instance descriptions in hallway

**Hallway room description (two separate visits):**
```
Torches burn in iron brackets along the walls, casting dancing orange light.
Portraits of stern-faced figures line the walls, their eyes following you in
the torchlight. A polished oak side table stands between the portraits, a vase
of dry flowers upon it.
```

- Torches: mentioned ONCE (as group) ✅
- Portraits: mentioned ONCE (as group) ✅
- Side table: mentioned ONCE ✅
- No repeated identical descriptions ✅
- Consistent across re-entry from bedroom ✅

---

## Complete Critical Path Transcript

### Step 1: Bedroom — Light the Candle
```
> feel
You reach out in the darkness, feeling around you...
  a large four-poster bed / a small nightstand / an oak vanity
  a heavy wardrobe / a threadbare rug / a leaded glass window
  heavy velvet curtains / a ceramic chamber pot

> open drawer
You pull the small drawer open. It slides out with a soft wooden scrape.

> get matchbox
You take a small matchbox.

> light candle
You'll need to prepare first...
[GOAP auto-chains: open matchbox → get match → strike match → light candle]
The wick catches the flame and curls to life, throwing a warm amber glow
across the room. Shadows retreat to the corners like startled cats.
```

### Step 2: Bedroom — Discover the Cellar
```
> drop matchbox / get candle / drop match
> push bed
The four-poster bed scrapes across the flagstones with a grinding shriek
of wood on stone, sliding off the threadbare rug.

> pull rug
Something clatters to the floor -- a small brass key!
As you pull the rug aside, your foot catches on a wooden edge -- a seam
in the flagstones. No... a trap door!

> get brass key / open trap door / down
You descend the narrow stone stairway...
```

### Step 3: Cellar → Storage Cellar
```
> unlock door
You insert a small brass key into the lock. *click*

> open door / north
You step through the doorway into a long, narrow vault...
The Storage Cellar
[Lists crate, crowbar, wine rack, rat, lantern, rope, etc.]
```

### Step 4: Storage Cellar — Crate Puzzle (BUG-048 focus)
```
> drop brass key / get crowbar / open crate
[Crowbar pries open crate — iron key revealed]

> drop crowbar / get iron key
You take a heavy iron key.
```

### Step 5: Storage Cellar → Deep Cellar → Hallway
```
> unlock door
You insert a heavy iron key into the lock. *click*

> open door / north
You step through the doorway and the world changes...
The Deep Cellar [dark — candle expired]

> up
You emerge from the stairway into warmth and light...
The Manor Hallway ← LEVEL 1 COMPLETE
```

---

## Issues Found

### Existing Bugs (Still Open)

| Bug | Severity | Description | Status |
|-----|----------|-------------|--------|
| BUG-049 | 🟡 MAJOR | `pry crate` → "I don't understand that." Parser doesn't know verb "pry" | STILL OPEN |

### New Observations

#### OBS-001: North Exit from Bedroom to Hallway is UNLOCKED

**Severity:** 🟡 DESIGN QUESTION  
**Reproduction:**
```
> light candle
[GOAP chains all steps]
> north
You emerge from the stairway into warmth and light...
The Manor Hallway
```

**Impact:** A player can skip the ENTIRE cellar puzzle chain (push bed, pull rug, brass key, trap door, cellar, storage cellar, crate, iron key, deep cellar) by simply typing `north` after lighting the candle. The north exit from the bedroom leads directly to the hallway with no key required.

**Question for Team:** Is this intentional? If reaching the hallway = Level 1 complete, the cellar path is entirely optional. The start-room.lua has `locked: false` on the north exit.

#### OBS-002: Candle Burns Out During Crate Area

**Impact:** LOW — The candle expires around the time you're opening the crate and examining it in the storage cellar. This means you arrive at the deep cellar in darkness. However, the `up` exit to the hallway works fine in the dark, and the hallway has torches. This creates a tense but fair moment — the player must navigate the deep cellar blind.

#### OBS-003: `feel inside drawer` Doesn't Work

**Reproduction:**
```
> open drawer
You pull the small drawer open. It slides out with a soft wooden scrape.
> feel inside drawer
You can't feel inside a small drawer.
```

**Impact:** LOW — Player can still `get matchbox` without issue. The `.inside` surface for the drawer may not be configured the same way the crate's was fixed. Not blocking.

---

## Regression Check

| System | Status | Notes |
|--------|--------|-------|
| GOAP auto-chain (light candle) | ✅ | 5-step chain works flawlessly |
| GOAP auto-use (crowbar on crate) | ✅ | Resolves crowbar from room inventory |
| Two-hand inventory limit | ✅ | Correctly blocks get when full |
| Room transitions with light | ✅ | Candle provides light in all rooms |
| Locked door + key system | ✅ | Both brass and iron key work correctly |
| Container nesting (crate > inside > iron key) | ✅ | **BUG-048 FIX VERIFIED** |
| Room presence deduplication | ✅ | **BUG-050 FIX VERIFIED** |
| Candle burn timer | ✅ | Burns out naturally during play |
| Room descriptions (lit) | ✅ | All rooms describe correctly when lit |
| Room descriptions (dark) | ✅ | Dark rooms show "too dark" message |
| on_enter text | ✅ | All transitions have atmospheric text |
| Exit display | ✅ | Lock status shown correctly |

---

## Verdict

**✅ LEVEL 1 CRITICAL PATH: COMPLETE AND VERIFIED**

Both BUG-048 and BUG-050 are confirmed fixed. The full cellar path from bedroom to hallway works end-to-end. The crate's `.inside` surface correctly exposes the iron key after prying it open, and hallway room presences display without duplication.

The only open question is OBS-001 (north bedroom exit bypasses all puzzles) — needs team decision on whether this is intentional.
