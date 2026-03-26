# Portal Walkthrough — Level 1 Full Verification Gate

**Date:** 2026-03-26
**Tester:** Nelson (QA Engineer)
**Build:** `lua src/main.lua --headless`
**Purpose:** Final verification of portal unification (Phases 1-4). All exits are now portal objects.

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Rooms planned | 7 |
| Rooms reached | 1 (Bedroom only) |
| Portal objects (total) | 16 across 7 rooms |
| Portals loaded OK | 2 (bedroom-hallway-door-north, bedroom-hallway-door-south) |
| Portals FAILED to load | 14 |
| Exits tested | 3 (north, window, down from bedroom) |
| Exits working | 0 (north portal loads but door is barred — game design) |
| Bugs found | 1 CRITICAL (systemic) |

**VERDICT: ❌ FAIL — Portal unification is BROKEN. 14 of 16 portal objects fail to load at startup. Player is trapped in the bedroom.**

---

## Root Cause Analysis

All portal object `.lua` files define a `guid` field with a proper GUID (e.g., `"{5a9a6d9f-f112-499e-8f1e-dae571675015}"`). However, room instance entries reference portals using `type_id` set to the **string ID** instead of the GUID.

The engine loader (`src/engine/loader/init.lua:134`) indexes base classes by GUID. When a room instance has `type_id = "bedroom-courtyard-window-out"`, the loader searches for a base class with that key — but no such entry exists. The actual base class is indexed under `"{5a9a6d9f-f112-499e-8f1e-dae571675015}"`.

**Result:** 14 portal objects silently fail to load, print "base class not found" warnings to stderr, and are never registered. Movement through those exits fails with "You can't go that way."

### Which portals work vs fail:

| Room | Portal ID | type_id format | Loads? |
|------|-----------|---------------|--------|
| start-room | bedroom-hallway-door-north | GUID `{25852832-...}` | ✅ YES |
| hallway | bedroom-hallway-door-south | GUID `{a47ce304-...}` | ✅ YES |
| start-room | bedroom-courtyard-window-out | String ID | ❌ NO |
| start-room | bedroom-cellar-trapdoor-down | String ID | ❌ NO |
| cellar | cellar-bedroom-trapdoor-up | String ID | ❌ NO |
| cellar | cellar-storage-door-north | String ID | ❌ NO |
| courtyard | courtyard-bedroom-window-in | String ID | ❌ NO |
| courtyard | courtyard-kitchen-door | String ID | ❌ NO |
| hallway | hallway-deep-cellar-stairs-down | String ID | ❌ NO |
| hallway | hallway-level2-stairs-up | String ID | ❌ NO |
| hallway | hallway-west-door | String ID | ❌ NO |
| hallway | hallway-east-door | String ID | ❌ NO |
| deep-cellar | deep-cellar-storage-door-south | String ID | ❌ NO |
| deep-cellar | deep-cellar-hallway-stairs-up | String ID | ❌ NO |
| deep-cellar | deep-cellar-crypt-archway-west | String ID | ❌ NO |
| storage-cellar | storage-cellar-door-south | String ID | ❌ NO |
| storage-cellar | storage-deep-cellar-door-north | String ID | ❌ NO |
| crypt | crypt-deep-cellar-archway-west | String ID | ❌ NO |

---

## Room-by-Room Walkthrough

### Room 1: Bedroom (start-room) ✅ REACHED

**Test 1: Game startup**
```
> (game starts)
You wake with a start. The darkness is absolute.
You can feel rough linen beneath your fingers.
```
**Verdict:** ✅ PASS — Room loads, darkness intro works.

**Test 2: Feel around in darkness**
```
> feel around
You reach out in the darkness, feeling around you...
  a large four-poster bed
  a small nightstand
  an oak vanity
  a heavy wardrobe
  a threadbare rug
  a leaded glass window
  heavy velvet curtains
  a ceramic chamber pot
  a heavy oak door
```
**Verdict:** ✅ PASS — All room objects discoverable by touch.

**Test 3: Feel door**
```
> feel door
Rough oak grain under your fingers, cold iron bands riveted flat against the
wood. The door is solid — no give when you push. You trace the edge where
wood meets stone: sealed tight, not even a draught slips through.
```
**Verdict:** ✅ PASS — Tactile description works.

**Test 4: Go north (door — portal loaded)**
```
> go north
a heavy oak door is barred.
```
**Verdict:** ✅ PASS — Portal loaded, correct blocked message. Door is barred from hallway side (game design).

**Test 5: Open door (barred)**
```
> open door
The door doesn't budge. The iron bar holds from the other side.
```
**Verdict:** ✅ PASS — Correct response for barred door.

**Test 6: Unbar door**
```
> unbar door
You aren't holding that.
```
**Verdict:** ⚠️ NOTE — Parser finds the bar but player can't reach it from this side.

**Test 7: Sleep to dawn + look around**
```
> sleep (×4, advancing to 6:00 AM)
> look around
**The Bedroom**
You stand in a dim bedchamber that smells of tallow, old wool, and the
faintest ghost of lavender. [...full description...]
A heavy oak door with iron bands stands in the north wall, barred from the
corridor beyond.
Exits:
  window: window
  north: north
  down: down
It is 6:00 AM.
```
**Verdict:** ✅ PASS — Dawn light works. Room description is rich. Exits listed.

**Test 8: Open window + go window (portal FAILED)**
```
> open window
You unlatch the iron catch and push the window open. Cool air rushes in,
carrying the smell of rain and chimney smoke.

> go window
You can't go that way.
```
**Verdict:** ❌ FAIL — Window opens successfully but movement fails. Portal `bedroom-courtyard-window-out` not in registry.

**Test 9: Go out / go outside**
```
> go out
You can't go that way.

> go outside
You can't go that way.
```
**Verdict:** ❌ FAIL — No movement variant works.

**Test 10: Climb window / climb out / climb out window**
```
> climb window
You can't go that way.

> climb out
You can't go that way.

> climb out window
You can't go that way.
```
**Verdict:** ❌ FAIL — All window movement variants fail.

**Test 11: Look rug + move rug (trapdoor access)**
```
> look rug
A once-fine rug lies on the stone floor [...] It looks like it might be
hiding something underneath, as rugs in old rooms inevitably do.
One corner is slightly raised, as if something is beneath it.

> move rug
a large four-poster bed is sitting on a threadbare rug. You need to move
it first.
```
**Verdict:** ⚠️ NOTE — Rug hints at trapdoor but bed blocks it (game puzzle).

**Test 12: Look trapdoor / open trapdoor (hidden)**
```
> look trapdoor
You don't notice anything called that nearby.

> open trapdoor
You don't notice anything called that nearby.
```
**Verdict:** ✅ PASS — Trapdoor correctly hidden under rug. But even if revealed, portal wouldn't work (string type_id).

**Test 13: Go down (trapdoor portal FAILED)**
```
> go down
You can't go that way.
```
**Verdict:** ❌ FAIL — Portal `bedroom-cellar-trapdoor-down` not in registry.

**Test 14: Look door at dawn**
```
> look door
A heavy oak door with iron bands. It appears to be barred from the other side.

> examine door
A heavy oak door with iron bands. It appears to be barred from the other side.
```
**Verdict:** ✅ PASS — Visual description at dawn works correctly.

---

### Room 2: Hallway ❌ NOT REACHED

**Reason:** North door from bedroom is barred. This is the only portal pair that loaded correctly (bedroom-hallway-door-north + bedroom-hallway-door-south both use GUID type_ids). However, the door is barred from the hallway side — this is intentional game design (the bar must be removed from the hallway).

**Cannot test:** south exit (back to bedroom), down (stairs to deep cellar), west/east doors, north/up (level 2 stairs).

---

### Room 3: Cellar ❌ NOT REACHED

**Reason:** Trapdoor portal `bedroom-cellar-trapdoor-down` failed to load (string type_id). Additionally, the trapdoor is hidden under the bedroom rug and starts in "hidden" state.

**Cannot test:** up exit (back to bedroom), north exit (to storage cellar).

---

### Room 4: Storage Cellar ❌ NOT REACHED

**Reason:** No path available. Cellar unreachable, so storage cellar is also unreachable.

**Cannot test:** south exit (back to cellar), north exit (to deep cellar).

---

### Room 5: Deep Cellar ❌ NOT REACHED

**Reason:** Both paths blocked:
- Via storage cellar → portal chain broken
- Via hallway stairs → hallway unreachable, plus `hallway-deep-cellar-stairs-down` portal uses string type_id

**Cannot test:** south exit (to storage), up exit (stairs to hallway), west exit (archway to crypt).

---

### Room 6: Courtyard ❌ NOT REACHED

**Reason:** Window portal `bedroom-courtyard-window-out` failed to load (string type_id). Window opens successfully but movement fails.

**Cannot test:** window back to bedroom, kitchen door (boundary portal).

---

### Room 7: Crypt ❌ NOT REACHED

**Reason:** Deep cellar unreachable. Portal `deep-cellar-crypt-archway-west` uses string type_id anyway.

**Cannot test:** west exit (back to deep cellar), atmosphere.

---

## Startup Warnings (stderr)

Every game launch emits 17 warnings — one per failed portal instance:

```
Warning: base class not found for guid 'cellar-bedroom-trapdoor-up' (instance 'cellar-bedroom-trapdoor-up')
Warning: base class not found for guid 'cellar-storage-door-north' (instance 'cellar-storage-door-north')
Warning: base class not found for guid 'courtyard-bedroom-window-in' (instance 'courtyard-bedroom-window-in')
Warning: base class not found for guid 'courtyard-kitchen-door' (instance 'courtyard-kitchen-door')
Warning: base class not found for guid 'deep-cellar-storage-door-south' (instance 'deep-cellar-storage-door-south')
Warning: base class not found for guid 'deep-cellar-hallway-stairs-up' (instance 'deep-cellar-hallway-stairs-up')
Warning: base class not found for guid 'deep-cellar-crypt-archway-west' (instance 'deep-cellar-crypt-archway-west')
Warning: base class not found for guid 'hallway-deep-cellar-stairs-down' (instance 'hallway-deep-cellar-stairs-down')
Warning: base class not found for guid 'hallway-level2-stairs-up' (instance 'hallway-level2-stairs-up')
Warning: base class not found for guid 'hallway-west-door' (instance 'hallway-west-door')
Warning: base class not found for guid 'hallway-east-door' (instance 'hallway-east-door')
Warning: base class not found for guid 'storage-cellar-door-south' (instance 'storage-cellar-door-south')
Warning: base class not found for guid 'storage-deep-cellar-door-north' (instance 'storage-deep-cellar-door-north')
Warning: base class not found for guid 'crypt-deep-cellar-archway-west' (instance 'crypt-deep-cellar-archway-west')
Warning: base class not found for guid 'e4a7f3b2-91d6-4c8e-b5a0-3f2d1e8c6a49' (instance 'bedroom-door')
Warning: base class not found for guid 'bedroom-courtyard-window-out' (instance 'bedroom-courtyard-window-out')
Warning: base class not found for guid 'bedroom-cellar-trapdoor-down' (instance 'bedroom-cellar-trapdoor-down')
```

---

## Bug Summary

| Bug ID | Severity | Summary |
|--------|----------|---------|
| BUG-PORTAL-001 | 🔴 CRITICAL | 14 of 16 portal objects fail to load — type_id uses string ID instead of GUID |

### BUG-PORTAL-001: Portal type_id/GUID mismatch prevents all room-to-room movement

**Severity:** CRITICAL — Blocks all game progression
**Location:** All 7 room files in `src/meta/world/`
**Root cause:** `src/engine/loader/init.lua:134` — `resolve_instance()` indexes base classes by GUID only

**The fix requires one of:**
1. Update all 14 broken room instance entries to use the portal object's actual GUID as `type_id`
2. Add a secondary index in the loader that maps object `id` → base class (so string IDs resolve)
3. Both (fix data + add fallback)

**Affected files (instances with string type_ids):**
- `src/meta/world/start-room.lua` — 2 portals (window, trapdoor)
- `src/meta/world/hallway.lua` — 4 portals (stairs, level2, west door, east door)
- `src/meta/world/cellar.lua` — 2 portals (trapdoor-up, storage-door)
- `src/meta/world/courtyard.lua` — 2 portals (window-in, kitchen-door)
- `src/meta/world/deep-cellar.lua` — 3 portals (storage-door, stairs, archway)
- `src/meta/world/storage-cellar.lua` — 2 portals (cellar-door, deep-cellar-door)
- `src/meta/world/crypt.lua` — 1 portal (archway)

**Note:** `bedroom-door` (guid `e4a7f3b2-91d6-4c8e-b5a0-3f2d1e8c6a49`) also fails — this appears to be a legacy furniture door object separate from the portal.

---

## Sign-Off

**Walkthrough blocked after Room 1.** Portal unification Phases 1-4 introduced a systemic type_id mismatch that prevents 14 of 16 portal objects from loading. The 2 portals that DO load (bedroom-hallway door pair) prove the engine's portal movement code works correctly — the issue is purely in the data (room instance `type_id` fields).

**Recommendation:** Fix the type_id values in all room files, then re-run this walkthrough.

— Nelson, QA Engineer
