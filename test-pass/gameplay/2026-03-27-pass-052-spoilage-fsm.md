# Pass-052: Corpse Spoilage FSM — Dead Rat Decay Progression

**Date:** 2026-03-27
**Tester:** Nelson
**Build:** Lua src/main.lua --headless
**Scope:** Corpse spoilage finite state machine — verify dead rat transitions through fresh → bloated → rotten → bones over time

## Executive Summary

**Total tests:** 8
**Pass:** 3 | **Fail:** 3 | **Warn:** 2
**Bugs found:** 2

The corpse spoilage FSM is **not functional**. After killing a rat and issuing 70+ `wait` commands, the dead rat corpse remained permanently in the "fresh" state. No state transitions occurred — description, smell, feel, and room presence text never changed. Additionally, the game clock remained frozen at 2:00 AM throughout the entire session, suggesting the `wait` command does not advance game time. The spoilage states (bloated, rotten, bones) appear to be **defined in metadata but never triggered by the engine**.

## Bug List

| Bug ID | Severity | Summary |
|--------|----------|---------|
| BUG-173 | HIGH | Corpse spoilage FSM timer never fires — dead rat stays "fresh" forever |
| BUG-174 | HIGH | Game clock frozen at 2:00 AM — `wait` command does not advance time |

## Methodology

Two headless sessions were run:
1. **Session 1 (10 waits):** Kill rat → 5 waits → look/smell → 5 waits → look/smell
2. **Session 2 (70 waits):** Kill rat → examine/feel/smell → 35 waits → look/examine/smell/feel → 35 waits → look/examine/smell

The rat.lua `death_state` defines 4 spoilage states with durations of 30, 40, and 60 ticks respectively. At 70 waits (70 ticks), the corpse should have transitioned through "fresh" (30 ticks) into "bloated" (30–70 ticks). At no point during either session did any transition occur.

**Root cause hypothesis:** The rat's `death_state` uses `duration` fields in its state definitions, but the FSM engine's timer system expects `timed_events`. The duration→timer conversion is not wired up for corpse objects.

---

## Individual Tests

### T-001: Kill rat and verify fresh corpse appears
**Input:**
```
goto cellar
attack rat
```
**Response:**
```
You engage a brown rat with bare fists!
[... combat log ...]
a brown rat is dead!
```
**Verdict:** ✅ PASS
**Notes:** Combat resolved correctly. Rat died and corpse appeared in room.

---

### T-002: Examine dead rat immediately after kill (fresh state)
**Input:**
```
examine dead rat
```
**Response:**
```
A dead rat lies on its side, legs splayed stiffly. Its fur is matted with
blood and its beady eyes stare at nothing.
```
**Verdict:** ✅ PASS
**Notes:** Description matches expected "fresh" state. Vivid, well-written.

---

### T-003: Sensory checks on fresh corpse
**Input:**
```
feel dead rat
smell dead rat
```
**Response (feel):**
```
Cooling fur over a limp body. The tail hangs like wet string.
```
**Response (smell):**
```
Blood and musk. The sharp copper of death.
```
**Verdict:** ✅ PASS
**Notes:** Both sensory descriptions are correct for "fresh" state. Excellent flavor text.

---

### T-004: Room presence text after kill
**Input:**
```
look
```
**Response (relevant excerpt):**
```
A dead rat lies crumpled on the floor.
```
**Verdict:** ⚠️ WARN
**Notes:** Room presence text is present and correct for "fresh" state. However, see T-006 — this text never changes even after 70 waits, which would be a fail if spoilage were working.

---

### T-005: Wait 5 times, then check for state change (expect: still fresh, ~5/30 ticks)
**Input:**
```
wait (x5)
look
smell dead rat
```
**Response (look excerpt):**
```
A dead rat lies crumpled on the floor.
```
**Response (smell):**
```
Blood and musk. The sharp copper of death.
```
**Verdict:** ⚠️ WARN
**Notes:** At 5 ticks, "fresh" state (duration 30) is expected. Text is correct. However, it's suspicious that the game clock still reads "It is 2:00 AM" — 5 ticks × 360 seconds/tick = 30 game minutes should show ~2:30 AM.

---

### T-006: Wait 35 times total, then check for bloated state (expect: bloated at tick 30+)
**Input:**
```
wait (x35 total)
look
examine dead rat
smell dead rat
feel dead rat
```
**Response (look excerpt):**
```
A dead rat lies crumpled on the floor.
```
**Response (examine):**
```
A dead rat lies on its side, legs splayed stiffly. Its fur is matted with
blood and its beady eyes stare at nothing.
```
**Response (smell):**
```
Blood and musk. The sharp copper of death.
```
**Response (feel):**
```
Cooling fur over a limp body. The tail hangs like wet string.
```
**Verdict:** ❌ FAIL — BUG-173
**Expected:** After 35 ticks, corpse should be in "bloated" state:
- Room: "A bloated rat carcass lies on the floor, reeking."
- Examine: "The rat's body has swollen, its belly distended with gas."
- Smell: "The sweet, cloying stench of decay."
**Actual:** All text still matches "fresh" state. No transition occurred.

---

### T-007: Wait 70 times total, check for rotten state (expect: rotten at tick 70+)
**Input:**
```
wait (x70 total)
look
examine dead rat
smell dead rat
```
**Response (look excerpt):**
```
A dead rat lies crumpled on the floor.
```
**Response (examine):**
```
A dead rat lies on its side, legs splayed stiffly. Its fur is matted with
blood and its beady eyes stare at nothing.
```
**Response (smell):**
```
Blood and musk. The sharp copper of death.
```
**Verdict:** ❌ FAIL — BUG-173
**Expected:** After 70 ticks, corpse should be in "rotten" state:
- Room: "A rotting rat carcass festers on the floor."
- Examine: "The rat is a putrid mess of matted fur and exposed tissue."
- Smell: "Overwhelming rot. Your eyes water."
**Actual:** All text still matches "fresh" state. FSM timer never fires.

---

### T-008: Game clock advancement via wait
**Input:**
```
wait (x70)
look (check time display)
```
**Response (all looks):**
```
It is 2:00 AM.
```
**Verdict:** ❌ FAIL — BUG-174
**Expected:** After 70 wait commands, game clock should have advanced. At 360 game-seconds per tick: 70 × 360 = 25,200 seconds = 7 hours → should read ~9:00 AM.
**Actual:** Clock displays "It is 2:00 AM" in every single `look` output across the entire session. The wait verb does not advance game time.

---

## Bug Details

### BUG-173: Corpse spoilage FSM timer never fires
**Severity:** HIGH
**Repro steps:**
1. `goto cellar`
2. `attack rat` (kill the rat)
3. `wait` (repeat 35+ times)
4. `examine dead rat` / `smell dead rat` / `look`
**Expected:** Corpse transitions from "fresh" → "bloated" after ~30 ticks
**Actual:** Corpse remains in "fresh" state indefinitely — all description, smell, feel, and room_presence text unchanged after 70 waits.
**Analysis:** The rat's `death_state` defines spoilage states with `duration` fields (30, 40, 60 ticks), but the FSM engine's `tick_timers()` function appears to consume `timed_events`, not `duration`. The conversion from duration to timed_events is not wired up for corpse objects. The states and transitions are **defined correctly in metadata** but **never executed by the engine**.

### BUG-174: Game clock frozen at 2:00 AM
**Severity:** HIGH
**Repro steps:**
1. Start game
2. Issue any number of `wait` commands
3. `look` to check time
**Expected:** Game clock advances (each tick = 360 game seconds = 6 minutes)
**Actual:** Clock reads "It is 2:00 AM" throughout entire session regardless of commands issued.
**Analysis:** The `wait` verb prints "Time passes." but does not increment the game clock. This likely means `SECONDS_PER_TICK` advancement in the game loop's post-command phase is either not running or not updating the clock display. This bug may be a root cause or co-factor of BUG-173 — if ticks aren't advancing, timer-based transitions can't fire.

---

## Observations

1. **Fresh state content is excellent.** The description, feel, smell, and room presence text for the "fresh" corpse state are vivid and well-crafted. The spoilage metadata (bloated/rotten/bones descriptions read from code review) is equally good. The creative work is done — it just needs the engine to execute it.

2. **Combat works correctly.** Killing the rat reliably produces a corpse that appears in the room with correct room_presence text.

3. **Two bugs may share a root cause.** If the game clock isn't advancing (BUG-174), then timer-based FSM transitions (BUG-173) can't fire either. Fixing the clock may fix spoilage.

4. **Timer duration is significant for playtesting.** Even when working, 30 ticks for "fresh" → "bloated" means a player would need to issue 30 commands before seeing any spoilage. This is a design consideration — the decay window feels appropriate for normal play but makes testing slow.

---

*Signed: Nelson, Tester — 2026-03-27*
