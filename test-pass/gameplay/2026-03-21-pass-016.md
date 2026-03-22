# Pass 016: Puzzles & UX Polish Playtest

**Date:** 2026-03-21  
**Tester:** Nelson (QA Agent)  
**Build:** Latest (post multi-command, visited rooms, puzzle 015/016 deployment)  
**Method:** `lua src/main.lua --no-ui` (plain stdout mode) + TUI mode for initial tests  

---

## Summary

| Category | Tests | Passed | Failed | Notes |
|----------|-------|--------|--------|-------|
| Multi-Command Input | 6 | 6 | 0 | All separators work perfectly |
| Visited Room Tracking | 5 | 5 | 0 | Short desc on revisit, full on look |
| Report Bug Command | 3 | 3 | 0 | URL, intro mention, context-aware |
| Puzzle 015: Draft Extinguish | 4 | 0 | 4 | 🔴 Not firing — schema mismatch |
| Puzzle 016: Wine Drink | 6 | 0 | 6 | 🔴 Wine bottles not accessible |
| Oil Flask Drink Rejection | 2 | 1 | 1 | Generic msg, not custom rejection |
| **TOTAL** | **26** | **15** | **11** | **58% pass rate** |

---

## 1. Multi-Command Input (Issue #1 Fix) — ✅ PASS

### Test 1.1: Comma separator (3 commands)
```
> feel bed, feel rug, feel nightstand
```
**Result:** All 3 commands executed sequentially. Bed description → rug description → nightstand description. **PASS**

### Test 1.2: Semicolon separator
```
> look; feel nightstand
```
**Result:** Both commands executed. "Too dark to see" (look in dark) then nightstand feel description. **PASS**

### Test 1.3: "then" separator
```
> feel wardrobe then feel vanity
```
**Result:** Both commands executed. Wardrobe description → vanity description. **PASS**

### Test 1.4: Empty segments ignored
```
> look,,,feel bed
```
**Result:** Triple commas correctly ignored. Only `look` and `feel bed` executed. **PASS**

### Test 1.5: Single command still works
```
> feel
```
**Result:** Normal room feel output. No regression. **PASS**

### Test 1.6: Multi-command with navigation
```
> get candle, push bed, pull rug, get brass key, open trap door, go down
```
**Result:** All 6 commands executed sequentially in one input. This is genuinely transformative for gameplay speed. **PASS**

**Rating: PASS — All 6 tests pass. Multi-command is rock solid.**

---

## 2. UX Polish — Visited Room Tracking — ✅ PASS

### Test 2.1: First visit (bedroom, with light)
```
> look
**The Bedroom**

You stand in a dim bedchamber that smells of tallow, old wool, and the
faintest ghost of lavender...
[FULL description — 12 lines of atmospheric text + objects + exits]
```
**Result:** Full description displayed on first `look`. **PASS**

### Test 2.2: Leave and return
```
> go down  [to cellar]
> go up    [back to bedroom]

**The Bedroom**
A dim bedchamber of cold stone and stale air.
```
**Result:** SHORT description on return visit. Only title + one-line summary. **PASS**

### Test 2.3: `look` after returning
```
> look
**The Bedroom**

You stand in a dim bedchamber... [FULL description again]
```
**Result:** Full description restored on explicit `look`. **PASS**

### Test 2.4: Bold markers on room titles
**Result:** All room titles wrapped in `**` markers:
- `**The Bedroom**`
- `**The Cellar**`
- `**The Storage Cellar**`
- `**The Deep Cellar**`
- `**The Manor Hallway**`
**PASS**

### Test 2.5: Other rooms show short description on revisit
```
> go down  [cellar → bedroom → cellar again]
**The Cellar**
A cold, damp cellar of rough stone and dripping water.
```
**Result:** Short description on cellar revisit too. Works consistently across rooms. **PASS**

**Rating: PASS — All 5 tests pass. Visited room tracking works elegantly.**

---

## 3. Puzzle 015 — Draft Extinguish — 🔴 FAIL

### Test 3.1: Go UP from deep cellar with lit candle
```
> inventory
  Left hand: a lit tallow candle
  Right hand: a heavy iron key
> go up
[Normal hallway entry text — NO wind/draft message]
```
**Result:** No wind effect triggered. Candle remains lit. **FAIL**

### Test 3.2: Verify wind description prints
**Result:** No wind description printed during traversal. **FAIL**

### Test 3.3: Candle state after traversal
```
> inventory  [in hallway]
  Left hand: a lit tallow candle
```
**Result:** Candle still lit — should be extinguished. **FAIL**

### Test 3.4: Go DOWN from hallway to deep cellar
```
> go down
[Normal deep cellar entry text — NO wind/draft message]
```
**Result:** No wind effect in either direction. **FAIL**

### Root Cause Analysis

**BUG-060 (🔴 CRITICAL): Draft extinguish puzzle (P015) never fires — schema mismatch**

The traverse_effects engine (line 45 of `src/engine/traverse_effects.lua`) expects:
```lua
on_traverse = { type = "wind_effect", extinguishes = {...} }
```

But the room data in `deep-cellar.lua` and `hallway.lua` provides:
```lua
on_traverse = { wind_effect = { extinguishes = {...} } }
```

The code checks `effect.type` (line 45), but since `on_traverse.type` is nil (the effect name is a KEY, not a `type` field), the handler silently returns without processing. The engine framework, handler code, and room data all exist — they just don't speak the same schema.

**Fix options:**
1. Change room data to flat `{ type = "wind_effect", ... }` format (matches engine expectations)
2. Change engine to iterate keys of `on_traverse` as effect types (matches room data format)

### Oil lantern wind-resistant test: NOT TESTABLE
Cannot test oil lantern sparing since the wind effect doesn't fire at all.

**Rating: FAIL — 0/4 tests pass. Schema mismatch blocks entire puzzle.**

---

## 4. Puzzle 016 — Wine Drink — 🔴 FAIL

### Test 4.1: Find wine bottle in storage cellar
```
> look
[Room description mentions "A tall wine rack stands against the west wall, a few dusty bottles still resting in its slots."]
```
**Result:** Wine mentioned in room text. Wine rack is examinable. **PARTIAL**

### Test 4.2: Take wine bottle
```
> take wine bottle → "You don't see that here."
> take bottle → "You don't see that here."
> get wine → "You can't carry a wooden wine rack."
> take bottle from wine rack → "There is no bottle in a wooden wine rack."
> look inside wine rack → "There is nothing inside a wooden wine rack."
```
**Result:** Wine bottles do not exist as interactable objects. **FAIL**

### Test 4.3-4.6: Open, drink, taste, empty tests
**Result:** Cannot test — wine bottle not accessible. **FAIL (BLOCKED)**

### Root Cause Analysis

**BUG-061 (🔴 HIGH): Wine bottles not instantiated in wine rack**

The wine rack type definition (`wine-rack.lua`) specifies contents `{"wine-bottle-1", "wine-bottle-2", "wine-bottle-3"}` in its `.inside` surface. However, `storage-cellar.lua` only instantiates ONE wine bottle with id `"wine-bottle"` and location `"wine-rack"`. The instance IDs don't match the surface template IDs, so the containment system never places them.

Additionally, `look inside wine rack` returns "There is nothing inside" despite the room description mentioning bottles — indicating the `.inside` surface is either empty or not being exposed to the look verb.

**Rating: FAIL — 0/6 tests pass. Wine bottles exist in code but not in the game world.**

---

## 5. Report Bug Command — ✅ PASS

### Test 5.1: `report bug` command
```
> report bug
To report a bug, open this URL:
https://github.com/WayneWalterBerry/MMO-Issues/issues/new?title=[Bug+Report]+The+Bedroom+-+2026-03-21+11:18&body=...
```
**Result:** Generates GitHub issue URL with room name and timestamp. **PASS**

### Test 5.2: Mentioned in intro text
```
Type 'look' to look around. Type 'report bug' to report issues. Type 'quit' to exit.
```
**Result:** `report bug` explicitly mentioned in intro help text. **PASS**

### Test 5.3: Context-aware
**Result:** URL includes current room name ("The Bedroom") and timestamp. **PASS**

**Rating: PASS — All 3 tests pass.**

---

## 6. Oil Flask Drink Rejection — ⚠️ PARTIAL

### Test 6.1: Drink oil flask without holding
```
> drink oil flask
You'll need to pick that up first.
```
**Result:** Correctly requires holding the item. **PASS**

### Test 6.2: Drink oil flask while holding
```
> drop brass key, take oil flask, drink oil flask
You can't drink a small ceramic oil flask.
```
**Result:** Generic rejection message. The object definition has a custom `on_drink_reject` message ("You gag on the thick, acrid oil...") but it's not being used by the drink verb handler. **FAIL**

**BUG-062 (LOW): Drink verb uses generic rejection instead of object's `on_drink_reject` text**

**Rating: PARTIAL — 1/2 tests pass.**

---

## New Bugs Discovered

| Bug ID | Severity | Title | Impact |
|--------|----------|-------|--------|
| BUG-060 | 🔴 CRITICAL | Draft extinguish puzzle never fires — `on_traverse` schema mismatch | Puzzle 015 completely broken. Engine expects `{type: "wind_effect", ...}`, room data provides `{wind_effect: {...}}` |
| BUG-061 | 🔴 HIGH | Wine bottles not instantiated in wine rack | Puzzle 016 completely broken. Wine bottle object exists but isn't placed as a takeable object. Instance ID mismatch (`wine-bottle` vs `wine-bottle-1/2/3`) |
| BUG-062 | 🟢 LOW | Drink verb ignores `on_drink_reject` custom text | Generic "You can't drink" shown instead of per-object rejection flavor text |

---

## Wins

1. **Multi-command input is transformative** — 6 commands in one line, all separators work, empty segments handled. Speed-running the critical path in a single input is genuine quality-of-life.
2. **Visited room tracking is elegant** — Short descriptions on revisit reduce text fatigue, `look` always gives full detail when you want it.
3. **Bold room titles** (`**The Bedroom**`) provide clear visual anchoring in text output.
4. **Report bug command** is production-quality — context-aware GitHub issue URL with room name and timestamp.
5. **Multi-command + navigation** chains work seamlessly — `get candle, push bed, pull rug, get brass key, open trap door, go down` executes 6 steps in one input with zero errors.

---

## Observations

- The TUI mode (without `--no-ui`) occasionally blanks output on complex multi-command sequences — `--no-ui` mode is far more reliable for testing.
- Candle burn timer still feels tight — burned out during wine bottle investigation (about 12-15 commands after reaching storage cellar).
- The deep cellar `on_enter` text ("You step through the doorway and the world changes...") is extraordinary writing. When the wind effect works, this stairway transition will be a memorable game moment.
- `taste wine` (SMELL/TASTE sensory hints) cannot be tested until wine bottles are accessible, but the object definition has rich sensory text waiting to be experienced.
