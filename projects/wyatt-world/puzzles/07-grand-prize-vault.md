# Puzzle 07: Grand Prize Vault

**Room:** The Grand Prize Vault (Downstairs from Hub)  
**Difficulty:** ★★★★ (Reading comprehension + number extraction, ~1–2 minutes)  
**Educational Angle:** Reading comprehension; extracting specific information from text; careful, focused reading

---

## Premise

You walk down stairs into a sparkly room. Gold and silver streamers hang everywhere. In the center sits a giant treasure chest with a combination lock. The lock has three dials — each one needs a number. A letter sits on a pedestal in front of the chest. It's from MrBeast! The letter contains a warm, friendly message — but three hidden numbers are woven into the text. Your job: read the letter carefully, extract the three numbers, and enter them on the dials to open the chest and win the grand prize.

---

## Objects Required

### The Treasure Chest (furniture, container)

1. **Treasure Chest** (furniture with locked container)
   - on_look: "A giant wooden treasure chest with shiny golden hinges. A three-dial combination lock sits on the front."
   - States:
     - **locked:** Cannot be opened until correct combination is entered.
     - **unlocked:** Opens to reveal the grand prize inside.

### The Combination Lock (interactive)

2. **Combination Lock** (interactive FSM object on chest)
   - Three dials, each with numbers 0–9.
   - on_look: "A lock with three dials. Each dial has numbers 0 through 9. You need to enter the correct three-digit combination."
   - Interaction: `SET DIAL 1 TO 13` or `TURN DIAL 1 TO 13` (depending on verb implementation)
   - Then: `SET DIAL 2 TO 50`
   - Then: `SET DIAL 3 TO 7`
   - Then: `OPEN CHEST` or `UNLOCK CHEST`

### The MrBeast Letter (sheet, readable)

3. **Letter from MrBeast** (sheet on pedestal)
   - on_look: 
     ```
     Hey Wyatt! You made it! Congrats on making it this far!

     I started making videos when I was THIRTEEN years old.
     Back then, I was just a kid filming challenges for fun.
     My first big challenge had FIFTY people in it.
     Everyone showed up on a hot summer day.

     This vault has been locked for exactly SEVEN days.
     Nobody has solved it yet!

     You're the first one to get here. I'm so proud of you!
     Keep going, Wyatt. You're a star!

     — MrBeast
     ```
   - Reading this letter, a careful reader will extract:
     - THIRTEEN (age MrBeast started making videos)
     - FIFTY (number of people in first challenge)
     - SEVEN (number of days vault has been locked)
   - Combination: **13-50-7**

---

## Solution Steps

1. **EXAMINE or READ the letter from MrBeast**
   - Output: Shows the full letter text as above.
   - Clues in text:
     - "I was THIRTEEN years old" → First digit is 13
     - "FIFTY people in it" → Second digit is 50
     - "SEVEN days" → Third digit is 7

2. **EXAMINE the combination lock**
   - Output: "A lock with three dials. Each dial has numbers 0 through 9. You need to enter the correct three-digit combination."

3. **SET DIAL 1 TO 13**
   - Command: `SET DIAL 1 TO 13` or `TURN DIAL 1 TO 13`
   - Output: "You turn the first dial. It clicks into place at 13."
   - FSM: lock tracks `dial_1 = 13`

4. **SET DIAL 2 TO 50**
   - Command: `SET DIAL 2 TO 50`
   - Output: "You turn the second dial. It clicks into place at 50."
   - FSM: lock tracks `dial_2 = 50`

5. **SET DIAL 3 TO 7**
   - Command: `SET DIAL 3 TO 7`
   - Output: "You turn the third dial. It clicks into place at 7."
   - FSM: lock tracks `dial_3 = 7`

6. **OPEN the chest / UNLOCK the chest**
   - Command: `OPEN CHEST` or `UNLOCK CHEST`
   - Engine checks: all three dials correct?
   - If YES:
     - Output: "The lock CLICKS! The chest lid swings open! Inside sits a GIANT GOLDEN TROPHY with your name engraved on it! MrBeast's voice booms: 'YOU DID IT, WYATT! YOU SOLVED THE GRAND PRIZE VAULT! YOU ARE THE CHAMPION!'"
     - Sound effect: Triumphant fanfare music!
     - FSM: chest transitions to "unlocked" state
     - Trophy appears inside (visible, takeable)
     - Room enters "puzzle_complete" state

7. **TAKE the trophy**
   - Output: "You lift out the massive golden trophy! You're the Grand Prize Vault Champion!"

---

## FSM States

| State | Description | Trigger | Next State |
|-------|-------------|---------|-----------|
| `locked` | Chest is closed; lock has 3 dials; letter on pedestal | Entry (default) | On correct combo |
| `unlocked` | Chest open; trophy visible inside | All 3 dials correct + OPEN | —— (stays) |

### Lock Sub-States (within locked state)

| Lock State | Description |
|-----------|-------------|
| `dial_1_unset` | Dial 1 not yet set (entry state) |
| `dial_1_set` | Dial 1 is set (13) |
| `dial_1_2_set` | Dials 1–2 are set (13, 50) |
| `dial_1_2_3_set` | All dials set (13, 50, 7) |

### State Behaviors

- **locked state:**
  - Setting a dial: update lock sub-state, show message confirming dial is set.
  - Trying to open before all dials are set: "The lock doesn't open. All three dials need to be set first!"
  - Setting wrong dial values: lock still accepts (we allow trial-and-error), but opening fails.

- **unlocked state:**
  - Chest is open.
  - Trophy is visible inside, takeable.
  - Trying to close chest: "The chest won't close. The treasure is yours to take!"

---

## Hints (Options System — 3 Tiers)

### Tier 1 (Standard)
**Output:** "You have a letter right there. What does it say? Sometimes important information is hidden in words."

### Tier 2 (Context Clues)
**Output:** "Read the letter from MrBeast carefully. Look for NUMBERS written in the text. How old was MrBeast? How many people? How many days? Those are your dial numbers!"

### Tier 3 (Mercy Mode)
**Output:** "The letter says: 'THIRTEEN years old', 'FIFTY people', and 'SEVEN days'. Those are your three numbers. Try: SET DIAL 1 TO 13. Then: SET DIAL 2 TO 50. Then: SET DIAL 3 TO 7. Then: OPEN CHEST."

---

## Failure States

**Setting wrong dial values:**
- When a player sets dials, we accept any value (0–99 or beyond).
- Example: "SET DIAL 1 TO 5" → "You turn the first dial. It clicks into place at 5."
- When player tries to OPEN with wrong combination:
  - Output: "The lock resists. The combination isn't correct! Read the letter again!"
  - Sound effect: Buzzer sound
  - The lock stays closed. The dials remain set to their current values (or reset, depending on design choice).
  - I recommend: dials STAY set, so player can try again without re-entering correct dials.

---

## Difficulty Rating

★★★★ (4 stars)

**Why:** This is pure reading comprehension at the hardest level:
1. Player must read a paragraph carefully.
2. Extract three specific numbers from the text (not math, just identification).
3. Translate the context into the dial-setting process.
4. Remember the three numbers long enough to enter them.

Should take 1–2 minutes. This is the final puzzle and the climax of the game. It's challenging but achievable for a 5th-grader.

---

## Educational Angle

**Skills:**
- Reading comprehension at its finest.
- Extracting specific information from a larger text (a real-world skill used in research, reading instruction manuals, understanding contracts).
- Attention to detail and careful word-reading.
- Connecting narrative context to numbers.

**Why it matters:** In real life, people need to read documents carefully and pull out key facts. Skimming misses important details. This puzzle teaches: "Every word matters. Read carefully. The information you need is there — you just have to find it."

**Lesson for Wyatt:** "A letter might seem like just a friendly message, but it can also hide important information. Careful readers catch the details. That's a superpower!"

---

## Notes for Flanders (Object Designer)

- **Treasure Chest:** Furniture template with special FSM. Two states: `locked` and `unlocked`. Visual appearance changes (closed vs. open).
- **Letter:** Sheet template, readable. Text is fixed as shown above. Must contain the three numbers in the specified words (THIRTEEN, FIFTY, SEVEN).
- **Combination Lock:** Interactive FSM with three dials (dial_1, dial_2, dial_3).
  - `SET DIAL N TO X` verb: accepts any dial number (1–3) and any value (0–99+).
  - Stores the value.
  - Shows confirmation message.
  - Tracks lock sub-state (which dials are set).
- **OPEN CHEST** verb: checks if all three dials match the correct combo (13, 50, 7).
  - If correct: transition chest to `unlocked`, show victory, eject trophy.
  - If wrong: show buzz message, stay locked.
- **Trophy:** Small-item template, appears inside chest after unlock, takeable.
- **Fanfare Sound:** Play triumphant music when chest opens (if audio is available).

---

## Notes for Nelson (Tester)

- **Happy path:** Read letter → extract numbers 13, 50, 7 → set all 3 dials → open chest → victory → take trophy.
- **Sad path (wrong numbers):** Set dials to 5, 20, 3 (wrong) → try to open → buzzer → dials stay set → re-read letter → correct dials.
- **Edge case:** Player enters numbers in wrong order (e.g., 50, 13, 7 instead of 13, 50, 7). Should still fail. Only 13-50-7 in that order opens it.
- **Regression test:** Verify dial-setting works; verify lock state tracking; verify correct combo opens chest; verify wrong combo fails; verify trophy appears and is takeable.
- **Headless test:**
  ```
  echo -e "read letter\nset dial 1 to 13\nset dial 2 to 50\nset dial 3 to 7\nopen chest\ntake trophy" | lua src/main.lua --headless --world wyatt-world
  ```

