# Gate 6 — Combat Scenario Results (Re-Run)

**Tester:** Nelson
**Date:** 2026-03-26
**Engine:** `lua src/main.lua --headless`
**Branch:** current working tree
**Context:** Re-run after #276 trapdoor fix and script updates (#277)

---

## Executive Summary

**OVERALL: PARTIAL PASS — Cellar access UNBLOCKED. Combat functional with caveats.**

The #276 trapdoor fix works. All four scenarios now reach the cellar via the correct puzzle sequence (`move bed → pull rug → pull iron ring → down`). Scripts updated: `take candle holder` → `take candle`, full puzzle sequence added. Combat engages in 2 of 4 scenarios. Remaining issues are pre-existing combat/parser bugs, not script problems.

| Scenario | Cellar Access | Combat Engages | Notes |
|----------|:---:|:---:|-------|
| F: Armed Combat | ✅ | ❌ | Rat scurries away before attack command |
| G: Flee Combat | ✅ | ✅ | Combat auto-resolves; flee untestable (rat dead) |
| H: Unarmed Combat | ✅ | ✅ | "punch rat" fails; "hit rat" succeeds |
| I: Darkness Combat | ✅ | ❌ | "attack rat" fails in dark (expected?); "feel rat" works |

---

## Script Changes (This Run)

All four scripts updated per #277:
1. **`take candle holder` → `take candle`** — Picks up tallow candle, not brass holder
2. **Added full puzzle sequence:** `move bed → pull rug → pull iron ring` before `down`
3. **Removed `open trap door`** — Old command that no longer applies; ring-pull opens it
4. **Scenario I:** Added `move bed → pull rug → pull iron ring` for darkness path (works without light)

---

## Scenario Results

### Scenario F: Armed Combat — PARTIAL PASS

**Script:** `scenario-f-armed-combat.txt` (17 commands)
**Output:** `output-f-armed-combat.txt`

| Check | Result | Evidence |
|-------|--------|----------|
| Game boots | ✅ PASS | "You wake with a start. The darkness is absolute." |
| Candle lights | ✅ PASS | "The wick catches the flame and curls to life" (auto-ignite) |
| Knife obtained | ✅ PASS | "You take a small knife." |
| Puzzle sequence | ✅ PASS | move bed ✅ → pull rug ✅ → pull iron ring ✅ |
| Player reaches cellar | ✅ PASS | "You descend the narrow stone stairway..." / "The Cellar" |
| Rat visible | ✅ PASS | "There is a brown rat here." (second look) |
| Attack initiates | ❌ FAIL | "You don't see that here to attack." |
| Look rat | ✅ PASS | "A plump brown rat with matted fur..." |

**Issue:** The rat scurries between locations ("A brown rat scurries up") and is intermittently out of scope when "attack rat" fires. The `look` shows the rat present, but by the time `attack rat` executes, the rat has scurried away. This is a **rat movement timing bug**, not a script issue.

### Scenario G: Flee Combat — PARTIAL PASS

**Script:** `scenario-g-flee-combat.txt` (17 commands)
**Output:** `output-g-flee-combat.txt`

| Check | Result | Evidence |
|-------|--------|----------|
| Game boots | ✅ PASS | "You wake with a start." |
| Candle lights | ✅ PASS | Auto-ignite sequence works |
| Knife obtained | ✅ PASS | "You take a small knife." |
| Puzzle sequence | ✅ PASS | move bed ✅ → pull rug ✅ → pull iron ring ✅ |
| Player reaches cellar | ✅ PASS | "The Cellar" description rendered |
| Combat initiates | ✅ PASS | "You engage a brown rat with a small knife!" |
| Rat takes damage | ✅ PASS | Multi-round combat narration, "a brown rat is dead!" |
| Flee works | ❌ FAIL | "You can't go that way." — combat resolved before flee |

**Issue:** Combat auto-resolves in a single turn (all rounds execute at once). The rat dies before `flee` is processed. Flee is parsed as a movement direction, not a combat action. **Two bugs:** (1) combat doesn't pause between rounds for player input, (2) `flee` not recognized as combat escape verb.

### Scenario H: Unarmed Combat — PARTIAL PASS

**Script:** `scenario-h-unarmed-combat.txt` (19 commands)
**Output:** `output-h-unarmed-combat.txt`

| Check | Result | Evidence |
|-------|--------|----------|
| Game boots | ✅ PASS | "You wake with a start." |
| Candle lights | ✅ PASS | Auto-ignite sequence works |
| Puzzle sequence | ✅ PASS | move bed ✅ → pull rug ✅ → pull iron ring ✅ |
| Player reaches cellar | ✅ PASS | "The Cellar" description rendered |
| Rat visible | ✅ PASS | "There is a brown rat here." (second look) |
| "punch rat" | ❌ FAIL | "You don't notice anything called that nearby." |
| "hit rat" | ✅ PASS | "You engage a brown rat with bare fists!" |
| Unarmed combat runs | ✅ PASS | Multi-round unarmed narration, "a brown rat is dead!" |
| Post-combat "punch rat" | ❌ EXPECTED | Rat is dead/gone, can't punch again |
| "look rat" | ✅ PASS | Shows dead rat description |

**Issue:** `punch rat` fails to resolve the rat as a target, but `hit rat` succeeds. The `punch` verb doesn't go through the same target resolution as `hit`/`attack`. Pre-existing parser routing bug — `punch` probably maps to self-harm handler instead of combat.

### Scenario I: Darkness Combat — PARTIAL PASS

**Script:** `scenario-i-darkness-combat.txt` (7 commands)
**Output:** `output-i-darkness-combat.txt`

| Check | Result | Evidence |
|-------|--------|----------|
| Game boots | ✅ PASS | "You wake with a start. The darkness is absolute." |
| Puzzle in dark | ✅ PASS | move bed ✅ → pull rug ✅ → pull iron ring ✅ (all work in darkness!) |
| Player reaches cellar | ✅ PASS | "The Cellar" / "It is too dark to see." |
| Feel reveals room | ✅ PASS | Lists barrel, bracket, trap door, iron-bound door, **brown rat** |
| Attack in dark | ❌ FAIL | "You don't see that here to attack." |
| Feel rat | ✅ PASS | "Coarse, greasy fur over a warm, squirming body..." + "It bites." |

**Notes:**
- Darkness puzzle path works perfectly — `move bed`, `pull rug`, `pull iron ring` all succeed without light
- `feel` correctly reveals the rat in darkness
- `attack rat` fails in dark — the attack verb requires sight. This may be intentional (can't attack what you can't see) or a bug (should allow blind combat)
- `feel rat` gives a great tactile response AND the rat bites — this is working as designed
- **Question for design team:** Should darkness combat be possible? If so, what verb initiates it?

---

## Pre-Existing Bugs Found (Not Caused by Script Changes)

### Bug: Rat Movement Timing (Scenario F)
The rat scurries in/out of scope between turns. `look` shows it, but `attack` on the next turn misses it. May need `attack` to check recent-presence or rat needs to be stationary when combat-eligible.

### Bug: Combat Auto-Resolves (Scenario G)
All combat rounds execute in a single turn. No opportunity for player to `flee` mid-combat. Combat system likely needs turn-based round separation.

### Bug: "flee" Not a Combat Verb (Scenario G)
`flee` is parsed as a movement direction ("You can't go that way."), not as a combat escape action.

### Bug: "punch" Doesn't Target Creatures (Scenario H)
`punch rat` → "You don't notice anything called that nearby." but `hit rat` → combat starts. The `punch` verb isn't routing through creature/combat target resolution.

### Bug: "attack" Requires Light (Scenario I)
`attack rat` fails in darkness. `feel rat` confirms the rat is present. If blind combat is intended, `attack` needs a darkness-aware path.

---

## Recommendations

1. ✅ **DONE:** Scripts updated with correct puzzle sequence and `take candle`
2. ✅ **DONE:** #276 trapdoor fix verified — cellar accessible in all conditions
3. **FILE:** Rat movement timing bug — rat scurries away before attack resolves
4. **FILE:** Combat auto-resolution — needs turn-based rounds for flee to work
5. **FILE:** `flee` verb not recognized as combat action
6. **FILE:** `punch` verb doesn't target creatures (only self-harm)
7. **DESIGN QUESTION:** Should `attack` work in darkness? Currently requires sight.
