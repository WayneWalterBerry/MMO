# Search/Find System Bugs — Pass-024
**Discovered:** 2026-03-22  
**Tester:** Nelson  
**Test:** Pass-024 (Creative Search Phrasing + Nightstand Regression)  

---

## Critical Bugs (🔥 P0)

### **BUG-076: Game hangs on "find something to light"**
**Priority:** CRITICAL (P0)  
**Status:** NEW  
**Discovered:** Pass-024, Test #14  

**Input:** `find something to light`  
**Output:** [No response — game enters infinite loop or deadlock]  

**Expected Behavior:**  
Should either:
- Find matchbox (if in scope)
- Respond "I don't understand 'something to light'."
- Provide helpful hint

**Actual Behavior:**  
Game hangs completely. No output. Must terminate process.

**Impact:**  
- Player must restart game (loss of progress)
- Game-breaking user experience
- Blocks creative phrasing testing

**Reproduction:**  
1. Start game: `lua src/main.lua`
2. Type: `find something to light`
3. Game hangs (no output after 30+ seconds)

**Root Cause (Hypothesis):**  
Parser likely enters infinite loop when processing multi-word abstract target phrase ("something to light"). Possible issues:
- Recursive target resolution without exit condition
- Infinite synonym expansion
- Deadlock in object matching logic

**Workaround:** None (game must be restarted)

**Related Bugs:** BUG-077 (likely same root cause)

---

### **BUG-077: Game hangs on "search for a match"**
**Priority:** CRITICAL (P0)  
**Status:** NEW  
**Discovered:** Pass-024, Test #15  

**Input:** `search for a match`  
**Output:** [No response — game enters infinite loop or deadlock]  

**Expected Behavior:**  
Should find matchbox or matches inside matchbox (if matchbox is open/held).

**Actual Behavior:**  
Game hangs completely. No output. Must terminate process.

**Impact:**  
- Player must restart game (loss of progress)
- Game-breaking user experience
- Blocks testing

**Reproduction:**  
1. Start game: `lua src/main.lua`
2. Type: `search for a match`
3. Game hangs (no output after 30+ seconds)

**Root Cause (Hypothesis):**  
Likely same as BUG-076 — parser deadlock on ambiguous/abstract target. "match" may also conflict with:
- Matchbox object
- Matches (plural) object
- Verb "match" (pattern matching)
- Abstract concept "a match"

**Workaround:** None (game must be restarted)

**Related Bugs:** BUG-076 (likely same root cause)

**Note:** May be duplicate of BUG-076. If root cause is shared, fixing one should fix both.

---

### **BUG-075: `search nightstand` finds nothing despite drawer with matchbox**
**Priority:** CRITICAL (P0)  
**Status:** NEW (REGRESSION)  
**Discovered:** Pass-024, Tests #13, #27  

**Input:** `search nightstand`  
**Output:**  
```
You begin searching...
You feel the a small nightstand — nothing there.
You finish searching the area. Nothing interesting.
```

**Expected Behavior:**  
Should discover drawer and/or reveal matchbox inside drawer. Should behave consistently with `search around` (which auto-opens drawers).

**Actual Behavior:**  
Reports "nothing there" even though:
- Nightstand has a drawer (sub-container)
- Drawer contains matchbox (critical item)
- `examine nightstand` correctly discovers the drawer
- `search around` correctly opens the drawer

**Impact:**  
- Breaks discovery mechanic for targeted search
- Natural player command ("search the nightstand") yields false negative
- Forces players to use less intuitive `examine` → `open` → `feel` chain
- REGRESSION: `search around` works correctly, but `search [object]` does not

**Reproduction:**  
1. Start game: `lua src/main.lua`
2. `feel around` (discover nightstand)
3. `search nightstand`
4. Observe: "nothing there" (incorrect — drawer exists)
5. Compare: `examine nightstand` → correctly discovers drawer

**Root Cause (Hypothesis):**  
`search [object]` command:
- Only checks object's surfaces/inventory
- Does NOT auto-discover sub-containers (unlike `search around`)
- Does NOT auto-open closed sub-containers (unlike `search around`)

**Workaround:**  
Use `examine nightstand` → `open drawer` → `feel drawer` chain.

**Fix Suggestion:**  
Make `search [object]` behavior consistent with `search around`:
1. Auto-discover sub-containers (drawers, compartments)
2. Auto-open accessible sub-containers
3. Report contents or prompt player to open

**Related Issues:**  
- Inconsistency between `search around` and `search [object]`
- `search around` has smart discovery, `search [object]` does not

---

## High Priority Bugs (⚠️ P1)

### **BUG-074: "look for X" triggers "look" instead of "find X"**
**Priority:** HIGH (P1)  
**Status:** NEW  
**Discovered:** Pass-024, Test #12  

**Input:** `look for the matchbox`  
**Output:** `It is too dark to see anything.`  

**Expected Behavior:**  
Should trigger `find matchbox` behavior (traverse/search for matchbox).

**Actual Behavior:**  
Parser interprets command as `look` (examine room), completely ignoring "for the matchbox".

**Impact:**  
- "look for X" is extremely common natural English phrasing
- Players expect "look for X" to search for X, not just look around
- Causes confusion and frustration
- Breaks natural language interaction

**Reproduction:**  
1. Start game: `lua src/main.lua`
2. Type: `look for the matchbox`
3. Observe: Triggers `look` command instead of `find matchbox`
4. Compare: `find matchbox` works correctly

**Root Cause (Hypothesis):**  
Parser prioritizes "look" verb match, does not recognize "look for" as distinct command pattern. Likely issues:
- Verb matching too greedy (matches "look" prefix)
- Missing "look for" → "find" alias
- Parser doesn't check for "for [object]" pattern after "look"

**Workaround:**  
Use `find matchbox` or `search for matchbox`.

**Fix Suggestion:**  
Add parser alias: `look for [object]` → `find [object]`

**Examples of affected phrasings:**  
- "look for the matchbox"
- "look for a match"
- "look for something"

---

## Medium Priority Bugs (📌 P2)

### **BUG-073: "search the room" interprets "the room" as object name**
**Priority:** MEDIUM (P2)  
**Status:** NEW  
**Discovered:** Pass-024, Test #11  

**Input:** `search the room`  
**Output:**  
```
You begin searching for the room...
You feel the a large four-poster bed — nothing there.
You feel the a small nightstand — nothing there.
[...searches for object named "the room"...]
You finish searching. No the room found.
```

**Expected Behavior:**  
Should work like `search around` (area search). "Search the room" is synonymous with "search everywhere" in natural English.

**Actual Behavior:**  
Parser interprets "the room" as a target object name, not as synonym for "area/everywhere".

**Impact:**  
- "Search the room" is very common player input
- Creates confusing output ("searching for the room", "No the room found")
- Wastes player time (searches entire area looking for non-existent object)
- Breaks natural language expectation

**Reproduction:**  
1. Start game: `lua src/main.lua`
2. Type: `search the room`
3. Observe: Searches for object named "the room" (incorrect)
4. Compare: `search around` works correctly

**Root Cause (Hypothesis):**  
Parser does not recognize "the room" as location/area reference. Treats it as literal object name.

**Workaround:**  
Use `search around` or `search` without target.

**Fix Suggestion:**  
Add parser aliases for area search:
- `search the room` → `search around`
- `search room` → `search around`
- `search here` → `search around`
- `search everywhere` → `search around`

**Related phrasings (likely affected):**  
- "search the area"
- "search this place"
- "search everywhere"

---

## Summary

**Total Bugs:** 5  
**Critical (P0):** 3 (BUG-075, BUG-076, BUG-077)  
**High (P1):** 1 (BUG-074)  
**Medium (P2):** 1 (BUG-073)  

### Critical Issues
- **2 game-hanging bugs** (BUG-076, BUG-077) — must be fixed to continue testing
- **1 critical discovery regression** (BUG-075) — breaks natural search command

### Must-Fix for Release
- BUG-075: `search nightstand` regression
- BUG-076: "find something to light" hang
- BUG-077: "search for a match" hang
- BUG-074: "look for X" misinterpretation

### Should-Fix for Better UX
- BUG-073: "search the room" misinterpretation

---

## Testing Status

**Tests Completed:** 27/52 (52%)  
**Tests Blocked:** 25/52 (48%) — blocked by BUG-076, BUG-077  

**Remaining Tests (Blocked):**
- ~15 creative search phrasings
- Compound commands ("search X for Y")
- Abstract targets ("something to...", "anything...")
- Question phrasings ("where is...", "what's in...")
- Creative verbs ("hunt", "rummage", "check")

**Action Required:**  
Fix BUG-076, BUG-077 (hangs) before completing Pass-024 testing.

---

**Reporter:** Nelson  
**Date:** 2026-03-22  
**Source:** Pass-024 playtest  
**Test File:** `test-pass/2026-03-22-pass-024.md`
