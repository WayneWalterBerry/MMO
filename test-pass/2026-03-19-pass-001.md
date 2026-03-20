# Playtest Report 001 — Nelson the Tester
**Date:** Session 1  
**Build:** `lua src/main.lua` (V1 Playtest)  
**Duration:** ~28 commands  
**Tester:** Nelson (AI)

---

## 1. Transcript

```
================================================================
  THE BEDROOM -- A Text Adventure
  V1 Playtest
================================================================
You wake with a start. The darkness is absolute.
You can feel rough linen beneath your fingers.

Type 'help' for commands. Try 'feel' to explore the darkness.
Type 'look' to look around. Type 'quit' to exit.

> look
The Bedroom
It is too dark to see. You need a light source.
(Try 'feel' to grope around in the darkness.)
Deep night. The world sleeps. It is 2:04 AM.

> feel
You reach out in the darkness, feeling around you...
  a large four-poster bed
  a small nightstand
  an oak vanity
  a heavy wardrobe
  a threadbare rug
  a leaded glass window
  heavy velvet curtains
  a ceramic chamber pot

> feel nightstand
Smooth wooden surface, crusted with hardened wax drippings. A small drawer handle protrudes from the front.
Your fingers find top:
  a tallow candle
  a small glass bottle

> open drawer
You pull the small drawer open. It slides out with a soft wooden scrape.

> feel drawer
Smooth wooden surface, crusted with hardened wax drippings. The drawer slides open under your fingers.
Your fingers find inside:
  a small matchbox
Your fingers find top:
  a tallow candle
  a small glass bottle

> get matchbox
You take a small matchbox.

> open matchbox
You slide the matchbox tray open with your thumb. Inside, a clutch of wooden matches rests snugly in a row.

> get match
You take a wooden match from an open matchbox.

> light match
You drag the match head across the striker strip. It sputters once, twice -- then catches with a sharp hiss and a curl of sulphur smoke. A tiny flame dances at the tip.

> look
The Bedroom
You stand in a dim bedchamber that smells of tallow, old wool, and the faintest ghost of lavender...
[Full room description with all objects listed]
Exits:
  north: a heavy oak door
  window: the leaded glass window (locked)
Deep night. The world sleeps. It is 2:52 AM.
The match flame flickers dangerously low...

> light candle
The wick catches the flame and curls to life, throwing a warm amber glow across the room. Shadows retreat to the corners like startled cats.
The match flame dies. Your fingers are cold and dark.

> inventory
  Left hand: an open matchbox (contains: 6 wooden matches)
  Right hand: a spent match

> look at candle
A stubby tallow candle gutters in its brass dish, throwing wild shadows that dance across the walls like drunken puppets. The flame is small but fierce...

> yell for help
[Parser] Tier 2 match: "yell for help" → help  (score: 1.00, phrase: "help")
Available commands: [full help menu displayed]

> go back to sleep
[Parser] No match found. Input: "go back to sleep" | Best: "lick bed-sheets" via "lick sheets" (score: 0.25)

> examine bed
A massive four-poster bed... [description]
On the bed: pillow, bed-sheets, blanket
The bedskirt hangs unevenly, as if something is wedged beneath the mattress.

> look under bed
You find under a large four-poster bed:
  a small knife

> grab the knife
Your hands are full. Drop something first.

> drop spent match
You drop a spent match.

> take knife
You take a small knife.

> smell
You smell the air around you. Dust and stillness.

> listen
You hold your breath and listen. Silence -- save for your own heartbeat.

> open wardrobe
You open a heavy wardrobe (open).

> look in wardrobe
You find in a heavy wardrobe (open):
  a moth-eaten wool cloak
  a burlap sack

> break window
The window explodes inward in a shower of glass! Shards skitter across the stone floor.

> look at window
A tall window of diamond-paned leaded glass... The window is latched shut.
[BUG: describes window as intact after breaking it]

> look at vanity
A solid oak vanity... An ornate mirror... paper, pen on surface. Drawer closed.

> go north
[Parser] No match found. Input: "go north" | Best: "look north" via "look at north" (score: 0.33)

> north
[Parser] Tier 2 match: "north" → look north (score: 0.50, phrase: "look at north")
You don't see that here.

> open door
It is already open.

> take candle and light it
Your hands are full. Drop something first.
You can't light a lit tallow candle.

> smell bottle
Even through the cork, you detect something acrid and chemical. Dangerous.

> loko at bed
[Parser] Tier 2 match: "loko at bed" → look  (score: 0.50, phrase: "look at")
The Bedroom [full room description — typo "loko" recovered, but target "bed" was lost]

> time
Dawn breaks on the horizon. It is 5:17 AM.

> look at it
A small glass bottle with a skull and crossbones label... [bottle description displayed]

> extinguish candle
You extinguish a lit tallow candle.

> what's in here?
It is too dark to see anything.

> quit
Goodbye.
```

---

## 2. Bugs Found

### BUG-001: Text Wrapping Duplicates Characters (SEVERITY: HIGH)
- **What I typed:** `look at candle`, `look at vanity`, `look at window`, `look` (any long text output)
- **What happened:** Line wrapping splits words and duplicates the last character before the break. Examples:
  - `"corners\ns like startled cats"` (should be `"corners like startled cats"`)
  - `"puppets\ns."` (should be `"puppets."`)
  - `"worl\nld"` (should be `"world"`)
  - `"wav\nvering"` (should be `"wavering"`)
  - `"stuff\nfed"` (should be `"stuffed"`)
  - `"nigh\nhtstand"` (should be `"nightstand"`)
  - `"sp\npent"` (should be `"spent"`)
  - `"somethin\nng"` (should be `"something"`)
- **What should happen:** Words should wrap cleanly at word boundaries without character duplication.
- **Pattern:** The wrapping function appears to have an off-by-one error — it includes the character at the wrap position on BOTH the current line AND the next line.

### BUG-002: Window Description Not Updated After Breaking (SEVERITY: MEDIUM)
- **What I typed:** `break window` then `look at window`
- **What happened:** `break window` says "The window explodes inward in a shower of glass!" but `look at window` still describes intact diamond-paned glass with "The window is latched shut."
- **What should happen:** The examine description should reflect the broken state. The exit listing correctly shows "a shattered window frame" — so the FSM state changed, but the `look at` description didn't switch.

### BUG-003: "yell for help" Incorrectly Matches "help" Command (SEVERITY: MEDIUM)
- **What I typed:** `yell for help`
- **What happened:** Tier 2 parser matched it to the `help` command with score 1.00, showing the help menu.
- **What should happen:** Either recognize it as an unimplemented action ("You shout into the darkness. No one answers.") or reject it as unrecognized. The word "help" in the phrase shouldn't match the meta-command.

### BUG-004: "go north" / "north" Don't Work for Movement (SEVERITY: MEDIUM)
- **What I typed:** `go north`, `north`
- **What happened:** `go north` → no match. `north` → matched as `look north` → "You don't see that here." The door was already open.
- **What should happen:** Movement commands should be recognized. The room shows "Exits: north: a heavy oak door" but there's no way to actually move through it. (May be by design if only one room exists, but the parser should at least say "You can't go that way yet" rather than a cryptic mismatch.)

### BUG-005: "loko at bed" Recovers Verb but Loses Object (SEVERITY: LOW)
- **What I typed:** `loko at bed`
- **What happened:** Tier 2 matched "loko at" to "look at" (good typo recovery!) but dropped "bed" — executed `look` (room description) instead of `look at bed`.
- **What should happen:** After recovering the verb, the object "bed" should still be passed through.

### BUG-006: Dawn + Broken Window = Still Dark After Extinguishing Candle (SEVERITY: LOW)
- **What I typed:** `extinguish candle` (at 5:17 AM, with broken window)
- **What happened:** "It is too dark to see anything." The window is broken, dawn has broken, but the room goes pitch black.
- **What should happen:** With a shattered window and dawn light, the room shouldn't be in total darkness. Natural light should provide dim visibility.

### BUG-007: "feel drawer" Shows Nightstand Description (SEVERITY: LOW)
- **What I typed:** `feel drawer`
- **What happened:** Shows nightstand's touch description ("Smooth wooden surface, crusted with hardened wax drippings") before listing drawer contents. Also says "The drawer slides open under your fingers" even though drawer was already open.
- **What should happen:** The drawer should have its own feel description, not inherit the nightstand's. Should not report opening an already-open drawer.

---

## 3. Parser Observations

### Tier 2 Matches That WORKED:
| Input | Matched To | Score | Notes |
|-------|-----------|-------|-------|
| `grab the knife` | `take knife` | (implicit) | Natural language synonym ✓ |
| `examine bed` | `look at bed` | (implicit) | Synonym ✓ |
| `loko at bed` | `look at` | 0.50 | Typo recovery ✓ (but lost object) |
| `take candle and light it` | Two commands | — | Compound command splitting ✓ |
| `look at it` | `look at bottle` | — | Pronoun/context resolution ✓ |
| `what's in here?` | (darkness check) | — | Natural language handled gracefully |

### Tier 2 Matches That MISSED:
| Input | Best Match | Score | Problem |
|-------|-----------|-------|---------|
| `yell for help` | `help` | 1.00 | False positive — "help" in phrase shouldn't match meta-command |
| `go back to sleep` | `lick bed-sheets` | 0.25 | Absurd match (correctly rejected at threshold) |
| `go north` | `look at north` | 0.33 | No movement verbs in parser vocabulary |
| `north` | `look at north` | 0.50 | Barely above threshold, wrong interpretation |

### Diagnostic Output:
- Parser shows `[Parser] Tier 2 match:` lines with input, matched command, score, and matched phrase
- `[Parser] No match found.` lines show what was tried and the best (rejected) candidate
- 4337 phrases loaded from index — substantial vocabulary
- Unicode arrow (→) appears garbled in terminal as `ΓåÆ` (encoding issue in diagnostic output)

---

## 4. Player Experience Notes

### What Felt Good:
- **The opening is atmospheric and compelling.** Waking in pitch darkness with just "rough linen beneath your fingers" is immediately immersive.
- **The feel→discover→open→find loop is satisfying.** The critical path feels natural and rewarding.
- **Rich object descriptions.** The candle, vanity mirror, bottle with skull label — all evocative and well-written.
- **Sensory verbs work great.** `smell`, `listen`, `feel` all provide atmosphere even when not mechanically necessary.
- **Match-lighting moment is a highlight.** The description of striking the match is genuinely cinematic.
- **State tracking is mostly excellent.** Dropped items appear on floor, wardrobe shows "open" in room description, inventory tracks hands separately.
- **Compound commands work.** "take candle and light it" split into two actions correctly.

### What Was Confusing:
- **No movement commands.** Room shows exits but you can't use them. No feedback that movement isn't implemented — just parser confusion.
- **"Hands full" with no hint.** When I tried to grab the knife, I had to figure out I needed to drop something. A hint like "Both hands are full (try 'drop' something)" would help.
- **Time jumps dramatically.** From 2:04 AM to 5:09 AM in ~25 commands. Each action seems to take ~7-8 minutes of game time. This feels too fast — the match barely flickered but 3 hours passed?
- **"feel drawer" vs "feel nightstand" confusion.** The drawer gives the nightstand's description. As a player I wasn't sure if I was feeling the right thing.
- **No "unrecognized" message for failed parses.** When "go back to sleep" fails, there's just silence (no output). The player gets nothing. Should say "I don't understand that."

### Where I Got Stuck:
- Nowhere on the critical path — it was very discoverable.
- Stuck trying to move north (door open but no movement system).

---

## 5. Critical Path Status

| Step | Command | Result | Status |
|------|---------|--------|--------|
| 1. Feel around | `feel` | Discovered all objects ✓ | ✅ PASS |
| 2. Feel nightstand | `feel nightstand` | Found drawer handle, candle, bottle ✓ | ✅ PASS |
| 3. Open drawer | `open drawer` | Drawer opened ✓ | ✅ PASS |
| 4. Get matchbox | `get matchbox` | Taken ✓ | ✅ PASS |
| 5. Open matchbox | `open matchbox` | Matches visible ✓ | ✅ PASS |
| 6. Get match | `get match` | Taken from matchbox ✓ | ✅ PASS |
| 7. Light match | `light match` | Match lit with great description ✓ | ✅ PASS |
| 8. Look around | `look` | Full room revealed ✓ | ✅ PASS |
| 9. Light candle | `light candle` | Candle lit, match auto-expired ✓ | ✅ PASS |

**CRITICAL PATH: ✅ FULLY COMPLETABLE**

The entire darkness→light sequence works beautifully. The pacing of discovery is excellent — each step naturally leads to the next.

---

## Summary

The game's core experience is **strong**. The critical path is smooth and atmospheric. The writing is excellent. The biggest technical issue is the **text wrapping bug** (BUG-001) which makes every long description look broken — this is the highest-priority fix. The **window state not updating on examine** (BUG-002) is the most visible gameplay bug. The parser's false positive on "yell for help" → "help" (BUG-003) is a design concern for the Tier 2 system.
