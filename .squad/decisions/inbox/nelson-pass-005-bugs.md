# Nelson — Pass 005 Bug Reports

## BUG-026: Movement verbs completely unimplemented — CRITICAL BLOCKER
- **Severity:** Critical
- **Input:** `go down`, `down`, `descend`, `climb down`, `enter trap door`, `go north`, `north`, `walk down`, `go through trap door`, `use trap door`, `go west`, `jump into trap door`
- **Expected:** Player moves to the room connected by the exit (trap door → room below, north → beyond oak door)
- **Actual:** All return "I don't understand that." (or "You don't see that here." for bare `north`)
- **Impact:** The game shows exits but provides zero way to use them. Multi-room gameplay is completely blocked. This is the #1 feature needed for game progression.
- **Minimum viable fix:** Parser must recognize: `go <direction>`, `<direction>` (n/s/e/w/u/d/north/south/etc.), `climb up/down`, `enter <exit>`, `descend`, `ascend`
- **Action:** Bart needs to implement a movement verb handler + room transition system

## BUG-027: FSM state labels leak into player text (trap door)
- **Severity:** Minor
- **Input:** `close trap door` → "You can't close a trap door **(open)**."  
  `listen to trap door` → "a trap door **(open)** makes no sound."
- **Expected:** State label should not appear in player-facing text
- **Actual:** Raw FSM state `(open)` appended to object display name
- **Note:** Same class as BUG-019 (fixed for drawer but not for trap door). All FSM objects need state label stripped from display text.

## BUG-028: "key" doesn't resolve to "brass key" in parser
- **Severity:** Minor
- **Input:** `drop key in trap door`
- **Expected:** Parser resolves "key" to the only key object in inventory/room
- **Actual:** "You aren't holding that." — parser requires full adjective "brass key"
- **Note:** Same class as BUG-014. Noun resolution should match on head noun when unambiguous.

## Verified Fixes
- BUG-024: ✅ FIXED — Sack on head blocks vision
- BUG-025: ✅ FIXED — Cloak + sack coexist (multi-slot wearables)
