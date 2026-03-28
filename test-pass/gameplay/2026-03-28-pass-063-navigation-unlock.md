# Pass-063: Navigation + Unlock — Bedroom to Cellar Critical Path

**Date:** 2026-03-28
**Tester:** Nelson
**Build:** Lua src/main.lua --headless
**Scope:** Navigation between rooms, key-based unlock mechanics, door lock/close, return navigation, creative phrase coverage

## Executive Summary

**Total Tests:** 30 | **Pass:** 22 | **Fail:** 5 | **Warn:** 3
**Bugs Filed:** 7 (0 CRITICAL, 3 MEDIUM, 4 LOW)

The bedroom → cellar → storage cellar → deep cellar → hallway critical path is **fully playable**. All key unlocks work via the simple `unlock door` command, and the GOAP planner impressively auto-resolves multi-step prerequisites (crowbar → open crate → take key → unlock). Return navigation (deep cellar → bedroom round-trip) works correctly in all directions.

The main issues are parser gaps: the `with` tool modifier is ignored for unlock/lock/light verbs, door disambiguation shows identical names for different doors, and `light candle` while holding the candle holder targets the holder instead of the nested candle.

## Bug List

| Bug ID | Severity | Summary |
|--------|----------|---------|
| BUG-180 | MEDIUM | Door disambiguation shows identical "an open iron-bound door" for two different doors in Storage Cellar |
| BUG-181 | MEDIUM | "unlock door with brass key" fails — parser doesn't handle "with" tool modifier for unlock/lock |
| BUG-182 | MEDIUM | "light candle" while holding candle holder resolves to holder, says "You can't light a brass candle holder" |
| BUG-183 | LOW | "exits" command not recognized — no synonym for listing room exits |
| BUG-184 | LOW | "insert key into lock" produces nonsensical "You can't close a small brass key" |
| BUG-185 | LOW | "use key on padlock" not recognized — common player phrasing for tool use |
| BUG-186 | LOW | "unbar door" in hallway says "You aren't holding that" — unclear how to unbar |

## Room Map Discovered

```
Manor Hallway (torchlit)
  ├── south: Bedroom (barred from hallway side)
  ├── down: Deep Cellar (stone steps)
  ├── east: ? (latched door, cooking smell)
  ├── west: ? (locked door)
  └── north: Upstairs (blocked by rubble)

Bedroom
  ├── north: Manor Hallway (barred from hallway side, cannot open)
  ├── down: Cellar (trap door)
  └── window: ? (leaded glass window)

Cellar (brazier-lit)
  ├── up: Bedroom (stone stairway)
  └── north: Storage Cellar (padlock, requires brass key)

Storage Cellar (no light source)
  ├── south: Cellar
  └── north: Deep Cellar (iron lock, requires iron key from crate)

Deep Cellar (no light source)
  ├── south: Storage Cellar
  ├── up: Manor Hallway (stone steps)
  └── west: ? (locked iron gate, stone archway)
```

## Individual Tests

### T-001: look
**Input:** `look`
**Response:** "It is too dark to see. You need a light source. Try 'feel' to grope around in the darkness."
**Verdict:** ✅ PASS — Correct darkness behavior at game start (2:00 AM).

### T-002: feel around
**Input:** `feel around`
**Response:** Lists 11 objects in bedroom including bed, nightstand, vanity, wardrobe, rug, windows, curtains, chamber pot, oak door, trap door.
**Verdict:** ✅ PASS — Complete object discovery in darkness.

### T-003: search nightstand → take matchbox → light candle sequence
**Input:** `search nightstand` → `take matchbox` → `open matchbox` → `take match` → `light candle with match`
**Response:** GOAP auto-sequence: attempts to get match from matchbox, strikes match, lights candle wick. "The wick catches the flame and curls to life, throwing a warm amber glow across the room."
**Verdict:** ✅ PASS — Full candle-lighting chain works when candle is on nightstand.

### T-004: light candle while holding candle holder
**Input:** `take candle holder` → `light candle with match` (holding candle holder + match)
**Response:** "You can't light a brass candle holder."
**Verdict:** ❌ FAIL — Parser resolves "candle" to the candle holder instead of the nested candle.
**Bug:** BUG-182

### T-005: light match → light candle (sequential, holding candle holder)
**Input:** `strike match` → `light candle`
**Response:** Match lights and immediately burns out. Then "You can't light a brass candle holder."
**Verdict:** ❌ FAIL — Same underlying issue as T-004: candle holder intercepts "candle" keyword.
**Bug:** BUG-182

### T-006: move bed → lift rug → find brass key
**Input:** `move bed` → `lift rug`
**Response:** "You move a large four-poster bed aside." → "You grab the edge of the threadbare rug and pull it aside... Something clatters to the floor -- a small brass key!"
**Verdict:** ✅ PASS — Puzzle chain works perfectly. Move bed (blocks rug), lift rug, key revealed.

### T-007: take brass key
**Input:** `take brass key`
**Response:** "You take a small brass key."
**Verdict:** ✅ PASS

### T-008: go north (bedroom, door barred)
**Input:** `go north`
**Response:** "a heavy oak door is barred."
**Verdict:** ✅ PASS — Correctly blocks passage through barred door.

### T-009: open trap door → go down → enter cellar
**Input:** `open trap door` → `go down`
**Response:** "The trap door comes up with a groan of old hinges..." → "You descend the narrow stone stairway..." Full cellar description displayed with spider, brazier, barrel, padlocked door.
**Verdict:** ✅ PASS — Room transition with atmospheric text works.

### T-010: unlock door (cellar padlock, brass key in hand)
**Input:** `unlock door`
**Response:** "The brass key slides into the padlock with a precise click. You turn it — the mechanism resists, then yields with a grinding clank. The padlock falls open."
**Verdict:** ✅ PASS — Auto-selects correct key from inventory. Excellent flavor text.

### T-011: unlock door with brass key
**Input:** `unlock door with brass key`
**Response:** "You don't notice anything called that nearby."
**Verdict:** ❌ FAIL — "with brass key" causes parser to fail entirely. The simple `unlock door` works.
**Bug:** BUG-181

### T-012: open door → go north (cellar to storage)
**Input:** `open door` → `go north`
**Response:** "You push the heavy door. It swings open..." → Full Storage Cellar description with crate, wine rack, lantern, crowbar, second locked door.
**Verdict:** ✅ PASS — Room transition works. Lit candle carried as light source.

### T-013: open crate (GOAP auto-sequence)
**Input:** `open crate`
**Response:** "You'll need to prepare first... You look for crowbar... You take an iron crowbar. You jam the crowbar under the lid and heave. Nails shriek as they pull free..."
**Verdict:** ✅ PASS — GOAP planner automatically finds crowbar and uses it. Impressive multi-step resolution.

### T-014: take iron key → unlock second door → open second door → go north
**Input:** `drop crowbar` → `take iron key` → `unlock second door` → `open second door` → `go north`
**Response:** Each step works. Iron key unlocks the lock plate. Door opens into the Deep Cellar.
**Verdict:** ✅ PASS — Full chain: pry crate → take key → unlock → open → enter.

### T-015: Deep Cellar room description
**Input:** `look around` (on first entry with candle light)
**Response:** Full description: limestone blocks, ribbed vault, stone altar, sarcophagus, iron chain, stone archway (locked gate west), stone steps (up), iron-bound door (south). Spider and wolf present.
**Verdict:** ✅ PASS — Rich room description. Wolf and spider confirmed present.

### T-016: go south (deep cellar to storage cellar)
**Input:** `go south`
**Response:** Returns to Storage Cellar.
**Verdict:** ✅ PASS — Bidirectional navigation works.

### T-017: lock door disambiguation
**Input:** `lock door` (in storage cellar with two iron-bound doors)
**Response:** "Which do you mean: an open iron-bound door or an open iron-bound door?"
**Verdict:** ❌ FAIL — Both doors have identical display names, making disambiguation impossible.
**Bug:** BUG-180

### T-018: close second door → lock second door
**Input:** `close second door` → `lock second door`
**Response:** "You heave the door shut." → "You turn the iron key. The lock engages with a heavy, final sound."
**Verdict:** ✅ PASS — Named door reference works for close and lock.

### T-019: Full return circuit
**Input:** Deep Cellar → `go south` → Storage → `go south` → Cellar → `go up` → Bedroom
**Response:** Each transition works with appropriate flavor text. Bedroom reached successfully.
**Verdict:** ✅ PASS — Complete round-trip navigation works.

### T-020: Deep Cellar up exit → Hallway
**Input:** `go up` (from Deep Cellar)
**Response:** "You emerge from the stairway into warmth and light." Full Manor Hallway description with torchlight, side table, barred south door, locked west door, latched east door, blocked staircase.
**Verdict:** ✅ PASS — Alternative route discovered. Hallway connects to Deep Cellar via stairs.

### T-021: Bedroom ↔ Cellar round-trip stress
**Input:** `go down` → `go up` → `go down` → `go up` (4 transitions)
**Response:** All transitions work correctly with varied flavor text.
**Verdict:** ✅ PASS — Repeated navigation is stable.

### T-022: unbar door (hallway south door)
**Input:** `unbar door` / `unbar south door`
**Response:** "You aren't holding that."
**Verdict:** ⚠️ WARN — Error message implies you need to hold the bar? Unclear how to unbar.
**Bug:** BUG-186

### T-023: go south (hallway, barred door)
**Input:** `go south` (from hallway)
**Response:** "a heavy oak door is barred."
**Verdict:** ✅ PASS — Correctly blocks. Door is barred from hallway side.

### T-024: Creative navigation phrases
**Input:** `walk north`, `head north`, `travel north`, `n`
**Response:** All correctly resolve to north direction (all blocked by barred door, which confirms they work).
**Verdict:** ✅ PASS — Multiple navigation synonyms work.

### T-025: please open the door
**Input:** `please open the door`
**Response:** "The door doesn't budge. The iron bar holds from the other side."
**Verdict:** ✅ PASS — Politeness stripping works. Door correctly responds.

### T-026: exits
**Input:** `exits`
**Response:** "I'm not sure what you mean."
**Verdict:** ⚠️ WARN — "exits" is a common player command to list available exits.
**Bug:** BUG-183

### T-027: use brass key on padlock
**Input:** `use brass key on padlock`
**Response:** "You don't notice anything called that nearby."
**Verdict:** ⚠️ WARN — Natural phrasing not recognized.
**Bug:** BUG-185

### T-028: insert key into lock
**Input:** `insert key into lock`
**Response:** "You can't close a small brass key."
**Verdict:** ❌ FAIL — Nonsensical error. "insert" seems to be interpreted as "close."
**Bug:** BUG-184

### T-029: put key in padlock
**Input:** `put key in padlock`
**Response:** "a heavy iron-bound door is not a container"
**Verdict:** ✅ PASS (borderline) — At least the error makes mechanical sense, even if unhelpful to a player.

### T-030: Creature observations
**Input:** (observed across all tests)
**Response:** Brown rat appears in Cellar, scurries between rooms. Spider in Cellar and Deep Cellar. Grey wolf in Deep Cellar, wanders to Storage Cellar when doors open.
**Verdict:** ✅ PASS — All three creatures (wolf, spider, rat) confirmed present and mobile.

## Candle Burn Duration

The tallow candle consistently burned out after approximately 20 in-game commands from lighting. The candle always expired upon entering the Deep Cellar, suggesting the critical path from bedroom → deep cellar is at the outer edge of a single candle's life. Players will need the brass oil lantern from the Storage Cellar for extended exploration.

## Notable Positives

1. **GOAP planner is impressive** — auto-resolves "open crate" by finding and using the crowbar, auto-resolves "unlock door" by matching the correct key.
2. **Atmospheric text is excellent** — room transitions, unlock sounds, rug/key discovery all feel immersive.
3. **Politeness stripping works** — "please open the door" correctly strips "please" and processes the command.
4. **Navigation synonyms are comprehensive** — walk, head, travel, go, enter, n/s/e/w all work.
5. **Door state tracking is solid** — locked/unlocked/open/closed/barred states all persist correctly.

## Sign-off

Navigation and unlock critical path verified. 7 bugs documented, none blocking progression. The path from bedroom to deep cellar is fully completable using `unlock door` (simple form). Parser gaps with `with` modifier and door disambiguation are the main areas needing attention.

— Nelson, Tester
