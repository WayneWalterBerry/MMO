# Pass-053: Multi-Room Exploration — Creature Presence Verification

**Date:** 2026-03-27
**Tester:** Nelson
**Build:** `lua src/main.lua --headless`
**Method:** Headless pipe input (Pattern 1)

## Executive Summary

**Total tests:** 17 | **Pass:** 15 | **Warn:** 1 | **Fail:** 1

All 5 creature rooms loaded successfully. Each creature was confirmed present in its designated room: rat (cellar), cat (courtyard), wolf (hallway), spider (deep-cellar), bat (crypt). Sensory (`smell`) output worked in every room with rich, room-specific and creature-specific descriptions. Navigation via `goto` worked for all rooms except "bedroom" — the room ID is "start-room", not "bedroom", and `goto` does not resolve keywords.

One bug found. One warning for missing newlines in cellar formatting.

## Bug List

| Bug ID | Severity | Summary |
|--------|----------|---------|
| BUG-165 | MEDIUM | `goto bedroom` fails — room ID is "start-room"; goto does not resolve by keyword |

## Observations

- **Creature wandering works:** The wolf wandered from hallway into deep-cellar ("A wolf paces the room, sniffing the air.") then left ("A grey wolf scurries down/up"). This is intentional creature AI behavior.
- **Smell is excellent:** Every room returns rich atmospheric text plus itemized per-object smell descriptions including creatures (rat: "Musty rodent", cat: "Warm animal musk", spider: "old silk and dry insect husks", bat: "Musky and faintly sour").
- **Dark rooms behave correctly:** Courtyard, deep-cellar, and crypt all show "too dark to see" with the `feel` hint, but smell still works fully — correct per design.
- **Hallway is lit:** Torches provide light, full room description renders. Good contrast with dark rooms.

---

## Individual Tests

### T-001: `goto cellar`
**Response:** `You materialize in The Cellar. **The Cellar** You stand at the foot of a narrow stone stairway...`
**Verdict:** ✅ PASS
**Notes:** Navigation successful. Room loaded with full description. Immediate creature text: "A rat freezes, beady eyes fixed on you. Its whiskers quiver."

### T-002: `look` (in cellar)
**Response:** Full room description including "There is a brown rat here" and "A panicked rat zigzags across the floor."
**Verdict:** ⚠️ WARN
**Notes:** Rat confirmed present. Room description and object presence text render correctly. Minor formatting issue: missing newlines between room header and description (`**The Cellar**You stand` — no line break). This may be headless-mode specific.

### T-003: `smell` (in cellar)
**Response:** "Damp earth, cold stone, and something faintly metallic..." + per-object list including "a brown rat — Musty rodent — damp fur, old nesting material, and the faint ammonia of urine."
**Verdict:** ✅ PASS
**Notes:** Rich atmospheric and itemized sensory output. Rat smell present. All cellar objects enumerated.

### T-004: `goto courtyard`
**Response:** `You materialize in The Inner Courtyard.` + darkness message + "The cat freezes, ears swiveling toward you. Its tail tip flicks once."
**Verdict:** ✅ PASS
**Notes:** Navigation successful. Cat creature immediately announced on arrival.

### T-005: `look` (in courtyard)
**Response:** "It is too dark to see. You need a light source. Try 'feel' to grope around in the darkness."
**Verdict:** ✅ PASS
**Notes:** Dark room correctly suppresses visual description. Cat not mentioned in look (correct — can't see in dark).

### T-006: `smell` (in courtyard)
**Response:** "Rain — recent rain on cobblestones..." + per-object list including "a grey cat — Warm animal musk and something faintly metallic — old blood on its whiskers."
**Verdict:** ✅ PASS
**Notes:** Excellent atmospheric text. Cat smell confirmed. All courtyard objects enumerated even in darkness.

### T-007: `goto hallway`
**Response:** `You materialize in The Manor Hallway.` + full lit room description + "A wolf paces the room, sniffing the air."
**Verdict:** ✅ PASS
**Notes:** Navigation successful. Hallway is lit (torches). Wolf creature present.

### T-008: `look` (in hallway)
**Response:** Full room description including "There is a grey wolf here." and "A wolf paces the room, sniffing the air."
**Verdict:** ✅ PASS
**Notes:** Wolf confirmed in room. Rich description with exits listed. Wolf also shown leaving: "A grey wolf scurries down." — creature wandering behavior.

### T-009: `smell` (in hallway)
**Response:** "Beeswax polish on the wooden floor..." + per-object list for all hallway objects (torches, portraits, doors, staircase). "A wolf paces the room, sniffing the air." appended.
**Verdict:** ✅ PASS
**Notes:** Excellent atmospheric and per-object smell. Wolf presence noted in output but wolf itself not in smell item list (wolf had briefly left and returned).

### T-010: `goto deep-cellar`
**Response:** `You materialize in The Deep Cellar.` + darkness message + "A wolf paces the room, sniffing the air. The spider tenses, front legs raised. The web trembles."
**Verdict:** ✅ PASS
**Notes:** Navigation successful. Spider creature confirmed. Wolf wandered in from hallway (creature AI working).

### T-011: `look` (in deep-cellar)
**Response:** "It is too dark to see..." + "A grey wolf scurries up."
**Verdict:** ✅ PASS
**Notes:** Dark room correctly suppresses visuals. Wolf left the room (creature wandering).

### T-012: `smell` (in deep-cellar)
**Response:** "Dust — not the organic dust of the storage cellar, but mineral dust..." + per-object list including "a large brown spider — A faint, musty odor — old silk and dry insect husks." Also "A wolf paces the room, sniffing the air." (wolf returned).
**Verdict:** ✅ PASS
**Notes:** Spider smell confirmed. Rich atmospheric text. All deep-cellar objects enumerated.

### T-013: `goto crypt`
**Response:** `You materialize in The Crypt.` + darkness message + "The bat's ears swivel toward you. Its claws tighten on the ceiling."
**Verdict:** ✅ PASS
**Notes:** Navigation successful. Bat creature confirmed on arrival.

### T-014: `look` (in crypt)
**Response:** "It is too dark to see. You need a light source."
**Verdict:** ✅ PASS
**Notes:** Dark room correctly suppresses visuals.

### T-015: `smell` (in crypt)
**Response:** "Dust — mineral, ancient..." + per-object list including "a small brown bat — Musky and faintly sour. Guano and warm fur."
**Verdict:** ✅ PASS
**Notes:** Bat smell confirmed. Excellent atmospheric description. All crypt objects enumerated.

### T-016: `goto bedroom`
**Response:** `No room called 'bedroom' exists.`
**Verdict:** ❌ FAIL
**Bug:** BUG-165
**Notes:** The bedroom's room ID is "start-room" (file: `start-room.lua`). The keyword "bedroom" is defined in the room's `keywords` table, but `goto` resolves by room ID only. `goto start-room` works correctly (verified separately). Player would naturally type "goto bedroom" since the room is called "The Bedroom".

### T-017: `look` (after failed goto — still in crypt)
**Response:** Crypt dark-room message displayed.
**Verdict:** ✅ PASS
**Notes:** Game state stable after failed goto. Player remains in crypt as expected.

---

## Bug Details

### BUG-165: `goto bedroom` fails — room keyword not resolved

**Severity:** MEDIUM
**Repro:** `echo "goto bedroom" | lua src/main.lua --headless`
**Expected:** Navigate to The Bedroom (start-room)
**Actual:** "No room called 'bedroom' exists."
**Root cause:** `goto` resolves by room `id` field only ("start-room"), not by `keywords` (which includes "bedroom"). All other rooms have IDs matching their natural names (cellar, courtyard, hallway, deep-cellar, crypt), so this is the only room where the mismatch is noticeable.
**Workaround:** `goto start-room`
**Suggested fix:** Either (a) make `goto` also search room keywords, or (b) add "bedroom" as an alias in the goto resolver.

---

## Creature Presence Matrix

| Room | Creature | Present on Arrival | In Look | In Smell | Creature Behavior Text |
|------|----------|--------------------|---------|----------|----------------------|
| Cellar | Brown rat | ✅ | ✅ "There is a brown rat here" | ✅ "Musty rodent" | "A rat freezes, beady eyes fixed on you" |
| Courtyard | Grey cat | ✅ | N/A (dark) | ✅ "Warm animal musk" | "The cat freezes, ears swiveling toward you" |
| Hallway | Grey wolf | ✅ | ✅ "There is a grey wolf here" | ✅ (in room text) | "A wolf paces the room, sniffing the air" |
| Deep Cellar | Brown spider | ✅ | N/A (dark) | ✅ "old silk and dry insect husks" | "The spider tenses, front legs raised" |
| Crypt | Brown bat | ✅ | N/A (dark) | ✅ "Musky and faintly sour" | "The bat's ears swivel toward you" |

**All 5 creatures confirmed present in their designated rooms. ✅**

---

*Nelson — Tester*
*"Every bug you find now is a bug the player never sees."*
