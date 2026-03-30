# Puzzle 03: Money Vault

**Room:** The Money Vault (South of Hub)  
**Difficulty:** ★★ (Simple math + reading + no rushing, ~1–2 minutes)  
**Educational Angle:** Multiplication, addition, and reading word problems (5th-grade math)

---

## Premise

You step into a giant vault full of CASH and GOLD. Stacks of play money are piled on three tables. Against the back wall is an enormous safe with a number pad. A sign above it says: "Count it up! The total opens the safe." Each table has a card that tells you HOW MANY bills are in the stack and HOW MUCH each bill is worth. You need to calculate the total value of all three stacks, then enter the total into the safe's keypad.

---

## Objects Required

### Money Stacks & Cards (on three tables)

**Table 1: Red Pile**

1. **Money Stack 1 (Red Table)** (small-item)
   - on_look: "A big stack of play money. It's held together with a rubber band."
   - on_feel: "Feels like paper. Thick and heavy."
   - Actual value: not directly shown on object

2. **Card 1** (sheet, on red table)
   - on_look: "A card that says: '5 bills. Each one is worth $10. How much is this stack?'"
   - Calculation: 5 × $10 = **$50**

**Table 2: Blue Pile**

3. **Money Stack 2 (Blue Table)** (small-item)
   - on_look: "Another stack of play money, rubber-banded and colorful."
   - on_feel: "Feels similar to the first stack."

4. **Card 2** (sheet, on blue table)
   - on_look: "A card that says: '3 bills. Each one is worth $20. How much is this stack?'"
   - Calculation: 3 × $20 = **$60**

**Table 3: Green Pile**

5. **Money Stack 3 (Green Table)** (small-item)
   - on_look: "A third stack of play money, smaller than the others."
   - on_feel: "Feels light. Maybe fewer bills?"

6. **Card 3** (sheet, on green table)
   - on_look: "A card that says: '4 bills. Each one is worth $15. How much is this stack?'"
   - Calculation: 4 × $15 = **$60**

### The Safe (furniture, container/FSM)

7. **Giant Safe** (furniture with dial/keypad)
   - on_look: "An enormous metal safe built into the wall. It has a glowing number pad on the front. Above it, a sign says: 'Count it up! The total opens the safe.'"
   - on_listen: "The safe is silent. Waiting."
   - Interaction: player uses keypad to enter numbers

### Sign Above Safe

8. **Safe Sign** (sheet, decoration)
   - on_look: "A big sign that says: 'Count it up! The total opens the safe.'"

### Misc Decoration

9. **Gold Coins** (decoration, scattered on floor)
   - on_look: "Piles of shiny gold coins scattered on the floor. They're plastic toys, but they're pretty!"
   - on_feel: "Cool and smooth."
   - These are just decoration; don't affect the puzzle.

---

## Solution Steps

1. **EXAMINE or READ Card 1**
   - Output: "A card that says: '5 bills. Each one is worth $10. How much is this stack?'"
   - Player learns: 5 × $10 = $50

2. **EXAMINE or READ Card 2**
   - Output: "A card that says: '3 bills. Each one is worth $20. How much is this stack?'"
   - Player learns: 3 × $20 = $60

3. **EXAMINE or READ Card 3**
   - Output: "A card that says: '4 bills. Each one is worth $15. How much is this stack?'"
   - Player learns: 4 × $15 = $60

4. **Calculate the grand total:**
   - $50 + $60 + $60 = **$170**

5. **EXAMINE the safe keypad**
   - Output: "You see a glowing number pad with buttons 0–9 and an ENTER button."

6. **ENTER the combination into the keypad**
   - Command: `ENTER 170` or `TYPE 170` or `INPUT 170 INTO KEYPAD`
   - Output: "You punch in 1...7...0 on the keypad. The safe beeps and hums. With a loud CLUNK, the safe door swings open! Inside, a shiny golden trophy sits on a velvet pillow."
   - FSM: safe enters "open" state
   - Trophy appears in room

7. **TAKE the trophy**
   - Output: "You pull out the golden trophy! MrBeast's voice booms: 'You did the math! Perfect! Here's your prize!'"
   - FSM: room enters "puzzle_complete" state

---

## FSM States

| State | Description | Trigger | Next State |
|-------|-------------|---------|-----------|
| `locked` | Safe is closed; cards visible; keypad ready | Entry (default) | On correct combo |
| `open` | Safe door open; trophy visible | Enter correct combo (170) | —— (stays) |

### State Behaviors

- **locked state:**
  - Entering wrong combination → buzzer sound. Output: "BZZZZT! That's not the right number. Try reading the cards again and adding them up!"
  - Player can try as many times as they want.

- **open state:**
  - Safe is visually open.
  - Trophy is takeable and gives victory message.

---

## Hints (Options System — 3 Tiers)

### Tier 1 (Standard)
**Output:** "There are three tables, each with a money stack and a card. The card tells you how much money is in the stack. You need to add them all together!"

### Tier 2 (Context Clues)
**Output:** "Start by reading each card carefully. Each one tells you: 'X bills, each worth $Y.' Multiply them together. Then add all three totals."

### Tier 3 (Mercy Mode)
**Output:** "Card 1: 5 × $10 = $50. Card 2: 3 × $20 = $60. Card 3: 4 × $15 = $60. Add them: $50 + $60 + $60 = $170. Try: ENTER 170."

---

## Failure States

**Entering the wrong combination:**
- **Output:** "BZZZZT! That's not the right number. Try reading the cards again and adding them up!"
- **Sound effect:** Cartoon buzzer (silly, not harsh)
- **Consequence:** The keypad clears. Player can try again immediately.
- **Visual:** The number pad briefly flashes red.

---

## Difficulty Rating

★★ (2 stars)

**Why:** Basic multiplication (single-digit × double-digit) and addition (three 2-digit numbers). It's not hard, but you have to read the cards carefully and not rush. The puzzle teaches: "Slow down, read every word, do the math step-by-step." Should take 1–2 minutes.

---

## Educational Angle

**Skills:**
- Reading word problems (each card is a mini word problem).
- Multiplication (5 × $10, 3 × $20, 4 × $15).
- Addition (three totals added together).
- Following a multi-step process.

**Why it matters:** This is real-world math. Reading a word problem and solving it is something adults do every day. The puzzle teaches: "Math is just organized thinking."

**Lesson for Wyatt:** "The card tells you the recipe for math. Read the recipe. Do the math. It works every time."

---

## Notes for Flanders (Object Designer)

- All money stacks are small-item template, can be examined but don't need to be taken (they're just for show).
- Cards are sheet template, readable (on_look returns full text).
- Safe is furniture with special FSM:
  - `locked` state: `on_keypad_input` verb checks the number entered.
  - If correct (170), transition to `open` state, eject trophy.
  - If wrong, play buzzer, stay in `locked` state, clear the input.
- Keypad interaction: accept numeric input (0–9) and an ENTER key. Store the number, then check on ENTER press.
- Trophy is small-item template, appears in safe after it opens, takeable.

---

## Notes for Nelson (Tester)

- **Happy path:** Read all 3 cards → calculate 5×$10=50, 3×$20=60, 4×$15=60 → add 50+60+60=170 → enter 170 → safe opens → trophy appears → room declares victory.
- **Sad path:** Enter wrong number (e.g., 100, 50, 170) → buzzer → player can try again.
- **Edge case:** Player doesn't read cards; just guesses → should take several tries to stumble on 170.
- **Regression test:** Verify keypad input works; verify safe state transition works; verify trophy appears/is takeable.
- **Headless test:**
  ```
  echo -e "read card on red table\nread card on blue table\nread card on green table\nenter 170 into keypad" | lua src/main.lua --headless --world wyatt-world
  ```

