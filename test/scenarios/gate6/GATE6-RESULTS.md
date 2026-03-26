# Gate 6 — Combat Scenario Results

**Tester:** Nelson
**Date:** 2026-03-26 13:34 UTC
**Engine:** `lua src/main.lua --headless`
**Branch:** current working tree

---

## Executive Summary

**OVERALL: FAIL — All 4 scripted scenarios blocked. Combat system UNTESTABLE.**

The player cannot reach the cellar (where the rat lives). The trapdoor exit is blocked by a **duplicate trapdoor object bug**: after pulling the rug, the old hidden trapdoor persists alongside the newly revealed one. Even when "pull iron ring" successfully opens the revealed trapdoor, the exit remains blocked by the stale hidden copy. No scenario reached combat.

---

## BLOCKER Bug: Duplicate Trapdoor (#NEW)

**Severity:** CRITICAL — blocks all cellar access and all combat testing

**Steps to reproduce:**
1. Light candle (take candle, light candle)
2. Move bed → pull rug (reveals trapdoor + brass key)
3. "pull iron ring" → ✅ "The trap door swings open with a groan of old hinges"
4. "down" → ❌ "a trap door blocks your path"

**Root cause:** `pull rug` spawns a new trapdoor object but the original hidden trapdoor remains in the room. The exit check resolves to the old (closed/hidden) trapdoor, not the newly opened one. Room description confirms both exist: "There is a trap door here. A trap door stands open in the floor."

**Impact:** Player is permanently trapped in the bedroom. ALL cellar scenarios are blocked.

---

## Scenario Results

### Scenario F: Armed Combat — FAIL

**Script:** `scenario-f-armed-combat.txt` (15 commands)
**Output:** `output-f-armed-combat.txt`

| Check | Result | Evidence |
|-------|--------|----------|
| Game boots | ✅ PASS | "You wake with a start. The darkness is absolute." |
| Player reaches cellar | ❌ FAIL | "a trap door blocks your path" (line 39) |
| Combat initiates | ❌ FAIL | Never reached cellar |
| Attack narration | ❌ FAIL | "You don't see that here to attack." (line 47) |
| Rat takes damage | ❌ FAIL | N/A |

**Additional issues:**
- "take candle holder" resolves to the holder, not the candle. Script should use "take candle"
- "light candle" → "You can't light a brass candle holder" — because holding the holder, not the candle
- Trapdoor won't open (script doesn't move bed or pull rug)
- Scenario script needs updating for the bed→rug→ring puzzle sequence

### Scenario G: Flee Combat — FAIL

**Script:** `scenario-g-flee-combat.txt` (15 commands)
**Output:** `output-g-flee-combat.txt`

| Check | Result | Evidence |
|-------|--------|----------|
| Game boots | ✅ PASS | "You wake with a start." |
| Player reaches cellar | ❌ FAIL | "a trap door blocks your path" (line 35) |
| Combat initiates | ❌ FAIL | Never reached cellar |
| Flee works | ❌ FAIL | "You can't go that way." (line 39) |
| Rat takes damage | ❌ FAIL | N/A |

**Additional issues:**
- Same candle holder/candle confusion as Scenario F
- Same missing bed→rug→ring sequence
- "flee" parsed as a direction, not a combat action

### Scenario H: Unarmed Combat — FAIL

**Script:** `scenario-h-unarmed-combat.txt` (17 commands)
**Output:** `output-h-unarmed-combat.txt`

| Check | Result | Evidence |
|-------|--------|----------|
| Game boots | ✅ PASS | "You wake with a start." |
| Player reaches cellar | ❌ FAIL | "a trap door blocks your path" (line 34) |
| Combat initiates | ❌ FAIL | Never reached cellar |
| Punch produces narration | ❌ PARTIAL | "You can only hit yourself right now. (Try: hit head)" (lines 41-49) |
| Rat takes damage | ❌ FAIL | No rat present |

**Additional issues:**
- Same candle holder/candle confusion
- Same missing bed→rug→ring sequence
- "punch rat" / "hit rat" → self-harm suggestion when rat not in scope. Possibly related to #275 unarmed THICKNESS.
- Repeated 5 times with same result

### Scenario I: Darkness Combat — FAIL

**Script:** `scenario-i-darkness-combat.txt` (5 commands)
**Output:** `output-i-darkness-combat.txt`

| Check | Result | Evidence |
|-------|--------|----------|
| Game boots | ✅ PASS | "You wake with a start." |
| Player reaches cellar | ❌ FAIL | "a trap door blocks your path" (line 7) |
| Darkness combat | ❌ FAIL | Never reached cellar |
| Attack in dark | ❌ FAIL | "You don't see that here to attack." (line 22) |
| Feel rat in dark | ❌ FAIL | "You can't feel anything like that nearby." (line 24-25) |

**Notes:**
- Intentionally no light — tests darkness combat
- Cannot test darkness combat because player can't reach cellar in any conditions

---

## Freeform Playthrough — FAIL (Partial Progress)

**Output:** `output-freeform-playthrough.txt`

Best attempt reached trapdoor-open state but could not descend:

| Step | Command | Result |
|------|---------|--------|
| 1 | feel | ✅ Room objects listed |
| 2 | open drawer, search, get matchbox | ✅ Matchbox obtained |
| 3 | get match, strike match | ✅ Match lit (burns out same turn) |
| 4 | take candle, light candle | ✅ Candle lit! Room illuminated |
| 5 | move bed | ✅ "You move a large four-poster bed aside." |
| 6 | pull rug | ✅ "A trap door!" + "A small brass key!" |
| 7 | pull iron ring | ✅ "The trap door swings open with a groan of old hinges" |
| 8 | down | ❌ "a trap door blocks your path" |
| 9 | attack rat with knife | ❌ "You don't see that here to attack." |

**Room description confirms the bug:** Two trapdoors coexist — "There is a trap door here. A trap door stands open in the floor."

---

## Additional Issues Found

### Issue: Scenario Scripts Outdated

The gate6 scenario scripts (F, G, H) use `take candle holder` instead of `take candle`, causing candle-lighting to fail. They also skip the required bed→rug→ring sequence to open the trapdoor. Scripts need updating after the trapdoor bug is fixed.

### Issue: "take candle holder" vs "take candle"

`take candle holder` picks up the brass holder. `take candle` correctly takes the tallow candle from the holder. The parser resolves "candle" in "candle holder" to the holder object first. Scripts should use `take candle` explicitly.

### Issue: Self-Harm Suggestion on Missing Target

When "punch rat" is used with no rat in scope, the response is "You can only hit yourself right now. (Try: hit head)" — this is confusing and potentially concerning messaging. Should say something like "You don't see a rat here."

---

## Known Issues Referenced

- **#275 Unarmed THICKNESS** — Cannot verify; unarmed combat untestable due to cellar blocker
- **Duplicate trapdoor bug** — NEW, CRITICAL, blocks all cellar/combat access

---

## Recommendations

1. **FIX FIRST:** Duplicate trapdoor bug — `pull rug` must update the existing trapdoor instead of spawning a new one, OR the exit check must reference the correct trapdoor
2. **UPDATE SCRIPTS:** All gate6 scenarios need the bed→rug→ring sequence added before the `down` command
3. **FIX SCRIPTS:** Change `take candle holder` → `take candle` in all scenarios
4. **RE-TEST:** Once trapdoor bug is fixed, re-run all 4 scenarios + freeform
5. **REVIEW:** "punch" self-harm messaging when target not in scope
