# Puzzle 01: Beast Studio (Hub)

**Room:** MrBeast's Challenge Studio (The Hub)  
**Difficulty:** ★ (Warm-up, ~30 seconds)  
**Educational Angle:** Careful reading; following exact directions; "read ALL the words before acting"

---

## Premise

You just walked into MrBeast's Challenge Studio! A big sign greets you with a welcome message. MrBeast's voice says, "Welcome, Wyatt! Push the right button to start!" In the middle of the room sits a fancy golden podium with a big red button. But the sign tells you which COLOR of button to press. If you push the wrong one, a buzzer sounds and the sign gives you a hint.

---

## Objects Required

- **Welcome Sign** (sheet) — readable, contains button color instruction
- **Golden Podium** (furniture) — decorative base
- **Red Button** (small-item, on podium) — main button, wrong answer
- **Blue Button** (small-item, on podium) — correct answer (or similar — spec per level design)
- **Scoreboard** (furniture, high on wall) — shows player name and progress

---

## Solution Steps

1. **EXAMINE or READ the Welcome Sign**
   - Output: "Welcome to MrBeast's Challenge Studio, Wyatt! You are Contestant #1! To start the show, press the BLUE button on the podium. Let's GO!"
   - Player learns: blue button is the goal.

2. **PRESS the BLUE BUTTON on the podium**
   - Output: "The podium lights up! Confetti EXPLODES from the ceiling! MrBeast's voice booms: 'HERE WE GO! Six rooms. Six challenges. Let's see if you can solve them all!'"
   - FSM: studio enters "show_started" state
   - All six challenge doors become available (doors now display exit descriptions)
   - Repeat signal: "The doors around you are now open. Pick a challenge!"

---

## FSM States

| State | Description | Trigger | Next State |
|-------|-------------|---------|-----------|
| `welcome` | Player just arrived; sign visible, button unpressed | `--` | On button press |
| `show_started` | Button pressed correctly; all doors open | Press blue button | —— (stays) |

### State Behaviors

- **welcome state:**
  - Red Button → Wrong answer. Buzzer sound. Output: "BZZZZT! That's not the right button. Try reading the sign again!"
  - Any other button → Same as red.

- **show_started state:**
  - Pressing button again → Encouraging message: "The show is already running! Pick a door to start a challenge!"

---

## Hints (Options System — 3 Tiers)

### Tier 1 (Standard — First ask)
**Output:** "This is the studio hub. Signs usually tell you what to do. Have you read the sign yet?"

### Tier 2 (Context Clues — 3–4 asks)
**Output:** "The sign mentions a COLOR of button. Look at the podium — which color button matches what the sign says?"

### Tier 3 (Mercy Mode — 5+ asks)
**Output:** "Try: READ WELCOME SIGN. Then: PRESS BLUE BUTTON."

---

## Failure States

**Pressing the wrong button:**
- **Output:** "BZZZZT! That's not the right button. The sign says to press the BLUE one. Try again!"
- **Sound effect:** Cartoon buzzer (silly, not harsh)
- **Consequence:** None. The button un-presses. Player can try again immediately.

---

## Difficulty Rating

★ (1 star)

**Why:** This is a warm-up. It teaches the player to read signs and interact with objects before doing anything else. No thinking required — just read and follow. Should take 15–30 seconds.

---

## Educational Angle

**Skill:** Careful reading + following exact directions.

**Why it matters:** Many puzzles in this world require the player to read signs, labels, and instructions. This warm-up teaches: "Before you act, STOP and read what it says. Every word matters."

**Lesson for Wyatt:** "The game is asking for the BLUE button. The sign says BLUE. I need to read the whole message, not just guess."

---

## Notes for Flanders (Object Designer)

- Make the Welcome Sign a sheet object (readable like a sheet/card).
- The sign text is: `"Welcome to MrBeast's Challenge Studio, Wyatt! You are Contestant #1! To start the show, press the BLUE button on the podium. Let's GO!"`
- Red Button should have `on_press` verb that outputs the wrong-answer message and stays unpressed.
- Blue Button should have `on_press` verb that triggers `studio.show_started` state change, plays confetti sound, and outputs the victory message.
- Podium is just a pretty container/furniture — buttons sit on top.

---

## Notes for Nelson (Tester)

- **Happy path:** READ SIGN → PRESS BLUE BUTTON → game transitions to "show_started" → all six doors open.
- **Sad path:** PRESS RED BUTTON (or any wrong button) → buzzer message → game stays in "welcome" state.
- **Regression test:** Verify that pressing button does NOT work before reading the sign (optional: if we want to lock buttons until sign is read).
- **Headless test:** `echo -e "read sign\npress blue button" | lua src/main.lua --headless --world wyatt-world`

