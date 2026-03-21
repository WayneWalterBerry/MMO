# Nelson — Puzzle 015/016 Test Bugs

**Author:** Nelson (QA Tester)  
**Date:** 2026-03-21  
**Pass:** 016 — Puzzles & UX Polish  
**Status:** 3 bugs filed, 2 critical/high

---

## BUG-060 (🔴 CRITICAL): Draft extinguish puzzle never fires — schema mismatch

**Location:** `src/engine/traverse_effects.lua` line 45 vs `src/meta/world/deep-cellar.lua` line 96

**Repro:** Carry a lit candle, go UP from deep cellar to hallway. No wind message appears, candle stays lit.

**Root cause:** The `traverse_effects.process()` function expects:
```lua
on_traverse = { type = "wind_effect", extinguishes = {...} }
```
But room data provides:
```lua
on_traverse = { wind_effect = { strength = "gust", extinguishes = {...} } }
```
At line 45, `effect.type` is nil (the effect name is a TABLE KEY, not a `type` field), so the handler silently returns.

**Fix:** Either:
1. Flatten room data: `on_traverse = { type = "wind_effect", strength = "gust", ... }`
2. Update engine to iterate `on_traverse` keys as effect types

**Impact:** Puzzle 015 completely broken. Both directions (up from deep cellar, down from hallway) affected.

---

## BUG-061 (🔴 HIGH): Wine bottles not instantiated in wine rack

**Location:** `src/meta/world/storage-cellar.lua` vs `src/meta/objects/wine-rack.lua`

**Repro:** In storage cellar, try `take wine bottle`, `take bottle`, `look inside wine rack` — all fail.

**Root cause:** Wine rack type definition specifies `contents = {"wine-bottle-1", "wine-bottle-2", "wine-bottle-3"}` but storage-cellar.lua only instantiates one bottle with id `"wine-bottle"` (no suffix). The IDs don't match, so containment never places them. Result: wine rack `.inside` surface is empty.

**Impact:** Puzzle 016 (Wine Drink) completely untestable. DRINK verb teaching, TASTE investigation, and sealed→open→empty FSM chain all blocked.

---

## BUG-062 (🟢 LOW): Drink verb ignores `on_drink_reject` custom text

**Location:** Drink verb handler in `src/engine/verbs/init.lua`

**Repro:** `take oil flask`, `drink oil flask` → "You can't drink a small ceramic oil flask." (generic). Expected: "You gag on the thick, acrid oil. That's lamp fuel, not drink."

**Root cause:** Drink verb handler doesn't check for `on_drink_reject` field on the object before falling back to generic rejection.

**Impact:** Low — cosmetic/flavor only. All non-drinkable objects give the same generic message instead of per-object custom rejection text.

---

## Recommendation

BUG-060 and BUG-061 are both simple data/schema fixes — the engine code and object definitions are solid, they just don't connect. Suggest Bart fix BUG-060 (schema alignment) and Moe fix BUG-061 (wine bottle instantiation) as quick wins before next playtest.
