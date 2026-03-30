# Bug Fix Summary — Issues #512, #513, #514

**Fixed by:** Flanders (Object Engineer)  
**Date:** 2026-03-30  
**TDD Required:** Yes — all tests written before fixes, all tests pass

---

## Issue #512: Riddle boards not individually examinable

**Status:** ✅ NO FIX NEEDED — Already working correctly

**Investigation:**
- Examined all three riddle board objects in Riddle Arena
- Each board already has distinct keywords:
  - Board One: "first riddle", "board one", "riddle 1", "hands riddle"
  - Board Two: "second riddle", "board two", "riddle 2", "keys riddle"
  - Board Three: "third riddle", "board three", "riddle 3", "bigger riddle"
- No keyword overlap between boards
- Each board's description contains full riddle text

**Test created:** `test/issues/test-riddle-board-disambiguation.lua` (5 tests, all pass)

**Conclusion:** Nelson's report may have been based on outdated code or parser confusion. The objects are correctly designed for disambiguation.

---

## Issue #514: Bookshelf surface error on load

**Status:** ✅ FIXED

**Problem:**
- `backwards-book` placed `on_top` of bookshelf in `last-to-leave.lua` room
- Bookshelf object didn't define a `top` surface
- Engine warning: "Warning: surface 'bookshelf.top' not found for instance 'backwards-book'"

**Root cause:** Missing `surfaces` definition on bookshelf object

**Fix applied:**
```lua
-- Added to src/meta/worlds/wyatt-world/objects/bookshelf.lua
surfaces = {
    top = { capacity = 4, max_item_size = 2, contents = {} },
},
```

**Test created:** `test/issues/test-bookshelf-surface.lua` (3 tests, all pass)

**Files modified:**
- `src/meta/worlds/wyatt-world/objects/bookshelf.lua`

**Validation:**
- Bookshelf now defines top surface with capacity=4 (enough for small books)
- Backwards-book (size=1, weight=1) fits within constraints
- No warning on room load

---

## Issue #513: "strike match" in E-rated help menu

**Status:** ✅ FIXED

**Problem:**
- E-rated worlds (Wyatt's World) showed "strike match on <x>" in help text
- "Strike" has violent connotations inappropriate for 10-year-old audience
- Even though "strike match" is utility (lighting), not combat, the verb choice is problematic

**Root cause:** Help text didn't differentiate verb phrasing by rating level

**Fix applied:**
```lua
-- Changed in src/engine/verbs/meta.lua line 357
-- E-rated (before): "strike match on <x>      Strike a match"
-- E-rated (after):  "light match on <x>       Light a match on a rough surface"
-- T-rated (unchanged): "strike match on <x>   Strike a match"
```

**Design decision:**
- E-rated: Use "light match" (safe, descriptive language)
- T-rated: Keep "strike match" (original phrasing, combat is allowed)
- Both syntaxes work in-game — this is display-only

**Test created:** `test/issues/test-help-strike-filtering.lua` (4 tests, all pass)

**Files modified:**
- `src/engine/verbs/meta.lua`

**Validation:**
- E-rated help shows "light match", no "strike" verb
- E-rated help hides "cut self", "prick self", Combat section (already working)
- T-rated help shows full command set including "strike match" and combat verbs
- Players can still use both "strike match" and "light match" commands — only help text changed

---

## Test Results

### New tests created (3 files, 12 tests total):
```
test/issues/test-riddle-board-disambiguation.lua — 5 tests, 5 passed
test/issues/test-bookshelf-surface.lua — 3 tests, 3 passed
test/issues/test-help-strike-filtering.lua — 4 tests, 4 passed
```

### Full test suite:
```
PASSED: 285 file(s) (7,685 tests)
FAILED: 1 file(s) (2 tests) — pre-existing failures (BUG-149, BUG-152)
```

**Zero regressions introduced.**

---

## Lessons Learned

### For Flanders (Object Engineer):
1. **Surfaces are required for on_top placement** — Any furniture that holds objects on its top MUST define `surfaces = { top = { capacity, max_item_size } }`. This is a common oversight when building furniture objects.

2. **Keywords matter for disambiguation** — When designing multiple similar objects (riddle boards, tables, etc.), always include ordinal keywords ("first", "second", "one", "two", "1", "2") to allow unambiguous player input.

3. **Rating-aware content extends beyond mechanics** — E-rated content simplification includes verb vocabulary, not just feature gating. "Strike" → "light" is a subtle but important distinction for kid-friendly language.

### For Squad:
- **Nelson (QA):** Issue #512 was a false positive — riddle boards were already correctly designed. May need to re-test with latest codebase.
- **Smithers (Parser):** Parser disambiguation relies on object keyword quality. Riddle boards demonstrate good pattern.
- **Brockman (Docs):** Document the `surfaces = { top, underneath, inside }` pattern in object design guide.

---

## Cross-Domain Impact

**Modified Bart's domain (engine/verbs/meta.lua):**
- Changed E-rated help text line 357
- Zero behavioral changes to verb handlers
- Display-only change, no engine logic touched

**Decision filed:** (Optional — this is a minor fix, no decision document needed)

---

## Verification Checklist

✅ TDD: Tests written before fixes  
✅ Tests fail before fix (bookshelf, help text)  
✅ Tests pass after fix  
✅ Full test suite run (7,685 tests pass)  
✅ Zero regressions  
✅ Lua syntax valid  
✅ All files in correct directories  
✅ Sensory properties preserved (bookshelf has on_feel, on_smell, etc.)  
✅ Material consistency maintained  
✅ Principle 8 compliance (objects declare, engine executes)  

---

**End of Report**
