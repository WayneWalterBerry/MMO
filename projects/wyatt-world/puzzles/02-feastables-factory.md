# Puzzle 02: Feastables Factory

**Room:** The Feastables Factory (North of Hub)  
**Difficulty:** ★★ (Straightforward categorization with one twist, ~1 minute)  
**Educational Angle:** Reading labels; sorting by category; process of elimination

---

## Premise

You walk into a bright room full of chocolate! A conveyor belt rolls through the middle, carrying five Feastables chocolate bars in shiny wrappers of different colors. At the end of the belt sit four big bins, each with a label describing a flavor category. Your job: read the flavor name on each bar's wrapper, figure out which category it belongs to, and sort them into the correct bins. One bar doesn't fit any category — that's the mystery flavor prize you get to keep!

---

## Objects Required

### Chocolate Bars (on conveyor belt)

Five small-item objects, each with a flavor name on the wrapper:

1. **Peanut Butter Chocolate Bar** (keywords: "chocolate", "peanut bar", "pb bar")
   - on_look: "A chocolate bar with a tan wrapper. It says 'Peanut Butter' in big letters."
   - on_smell: "Smells like peanuts and chocolate. Yum!"
   - Category: **Nutty**

2. **Strawberry Cream Chocolate Bar** (keywords: "chocolate", "strawberry", "cream bar")
   - on_look: "A chocolate bar with a pink wrapper. It says 'Strawberry Cream' on it."
   - on_smell: "Smells fruity and sweet."
   - Category: **Fruity**

3. **Almond Crunch Chocolate Bar** (keywords: "chocolate", "almond", "crunch")
   - on_look: "A chocolate bar with a white wrapper. It says 'Almond Crunch' in bold text."
   - on_smell: "Smells nutty. You can hear a faint crunch sound inside."
   - Category: **Nutty**

4. **Caramel Crispy Chocolate Bar** (keywords: "chocolate", "caramel", "crispy")
   - on_look: "A chocolate bar with a gold wrapper. It says 'Caramel Crispy' on the wrapper."
   - on_smell: "Smells like caramel and toasted stuff."
   - Category: **Crunchy**

5. **Mystery Flavor Chocolate Bar** (keywords: "chocolate", "mystery")
   - on_look: "A chocolate bar with a silver wrapper. The wrapper just says 'MYSTERY' with a big question mark."
   - on_smell: "Smells... weird? You can't tell what it is!"
   - Category: **None** — this is the hidden prize

### Sorting Bins (furniture, containers)

Four bin objects at the end of the conveyor belt:

1. **Fruity Bin** (keywords: "fruity bin", "bin", "fruity")
   - on_look: "A big blue bin with a label: 'FRUITY — Full of fruit flavors!'"
   - Accepts: strawberry bar only

2. **Nutty Bin** (keywords: "nutty bin", "bin", "nutty")
   - on_look: "A big brown bin with a label: 'NUTTY — Packed with nuts!'"
   - Accepts: peanut butter bar, almond crunch bar

3. **Crunchy Bin** (keywords: "crunchy bin", "bin", "crunchy")
   - on_look: "A big red bin with a label: 'CRUNCHY — All crunch, no mush!'"
   - Accepts: caramel crispy bar only

4. **Mystery Prize Box** (keywords: "mystery box", "box", "mystery")
   - on_look: "A fancy golden box with a big question mark on it. It says: 'MYSTERY PRIZE — If you can't sort it, you get to keep it!'"
   - Accepts: mystery bar

### Conveyor Belt (furniture, decorative)

- on_look: "A long metal belt that slowly rolls chocolate bars toward the bins. The bars glide smoothly along."
- on_listen: "A soft humming and whirring sound as the belt moves."

---

## Solution Steps

1. **EXAMINE each chocolate bar** (or FEEL/SMELL to get flavor hints)
   - Example: "EXAMINE PEANUT BAR" → "A chocolate bar with a tan wrapper. It says 'Peanut Butter' in big letters."

2. **READ each bin label** (or EXAMINE bins)
   - Example: "EXAMINE FRUITY BIN" → "A big blue bin with a label: 'FRUITY — Full of fruit flavors!'"

3. **TAKE each bar** (one at a time) and carry to correct bin

4. **PUT bar INTO correct bin**
   - Example: "PUT PEANUT BAR IN NUTTY BIN"
   - Output: "You drop the Peanut Butter bar into the Nutty bin. Perfect! It lands with a soft thud."

5. **Correct sorting sequence:**
   - Peanut Bar → Nutty Bin
   - Strawberry Bar → Fruity Bin
   - Almond Bar → Nutty Bin
   - Caramel Bar → Crunchy Bin
   - Mystery Bar → Mystery Box (or keep it in inventory)

6. **When all four category bins are full + mystery bar is either kept or placed in mystery box:**
   - Output: "You did it! All the chocolates are sorted! MrBeast's voice booms: 'Perfect categorization, Wyatt! Here's your prize!' A golden trophy slides out of a slot in the wall. The Mystery Flavor bar is YOUR PRIZE to keep!"
   - FSM: room enters "puzzle_complete" state
   - Prize appears in room_presence
   - Doors unlock

---

## FSM States

| State | Description | Trigger | Next State |
|-------|-------------|---------|-----------|
| `in_progress` | Puzzle unsolved; bars on belt, bins empty | Entry (default) | On completion |
| `puzzle_complete` | All bars sorted correctly | All 4 category bins filled + mystery bar secured | —— (stays) |

### State Behaviors

- **in_progress state:**
  - Bins accept correct items. Accepting wrong item → silly message: "That's not right for this bin! Read the label again!" (item pops back into inventory)
  - Pressing wrong bar into bin plays wrong-answer buzzer sound.

- **puzzle_complete state:**
  - Trophy appears in room.
  - Output shows when prize appears.

---

## Hints (Options System — 3 Tiers)

### Tier 1 (Standard)
**Output:** "Each bin has a label that tells you what kind of chocolate goes in it. Read the labels, then match the bars to the bins!"

### Tier 2 (Context Clues)
**Output:** "Start by reading each bar's wrapper. What flavor is it? Then find the bin with that category. Use SMELL to get flavor hints if you're stuck."

### Tier 3 (Mercy Mode)
**Output:** "Try: EXAMINE PEANUT BAR. Then: EXAMINE NUTTY BIN. Then: PUT PEANUT BAR IN NUTTY BIN. Repeat for the other bars!"

---

## Failure States

**Putting a bar in the wrong bin:**
- **Output:** "That's not right! Read the label on the bar again, and read the bin label. Try again!"
- **Sound effect:** Cartoon "boing" sound (silly, not harsh)
- **Consequence:** Item pops out of bin back into player's inventory.
- **Visual:** Bin briefly shakes or flashes red.

**Trying to put mystery bar in a category bin:**
- **Output:** "Hmm! This bar is a mystery flavor. You can't figure out which category it is! The bar pops back out. Maybe keep it as a prize instead?"

---

## Difficulty Rating

★★ (2 stars)

**Why:** This requires matching written descriptions (labels on bars) to categories (bin labels). It's not hard, but you have to read carefully and not skim. One bar is a red herring (the mystery flavor), which teaches process of elimination. Should take 1–1.5 minutes.

---

## Educational Angle

**Skills:**
- Reading labels and extracting key information (flavor names).
- Sorting by category (Fruity, Nutty, Crunchy).
- Process of elimination (the mystery bar teaches "if it doesn't fit, it's special").

**Why it matters:** Reading product labels is a real-world skill. This puzzle makes it fun and rewarding.

**Lesson for Wyatt:** "The wrapper tells you what's inside. Labels help you sort things. And sometimes the thing you can't figure out is actually the BEST prize!"

---

## Notes for Flanders (Object Designer)

- All bars are small-item template, takeable, can be placed in containers.
- Bins are container template with capacity = 3 items (to accept multiple bars).
- Bins should validate item type: only specific bars accepted (use `on_put` hook to check).
- Wrong bars should be ejected with the silly message.
- Mystery box is a special container that's visible on the floor (not a bin on the conveyor — decorative).
- Conveyor belt is furniture (not a container) — just for looks.

---

## Notes for Nelson (Tester)

- **Happy path:** Read labels → take bar → examine bin → put bar in correct bin → repeat 4 times → room declares victory.
- **Sad path:** Put bar in wrong bin → bin rejects it, pops item out → player gets hint.
- **Mystery bar:** Can be left in inventory or put in mystery box — either way counts as "solved."
- **Regression test:** Verify put/take mechanics work on bars; verify bin capacity is enforced; verify categorization rules are strict.
- **Headless test:** 
  ```
  echo -e "examine peanut bar\nexamine nutty bin\nput peanut bar in nutty bin\nput strawberry in fruity\nput almond in nutty\nput caramel in crunchy" | lua src/main.lua --headless --world wyatt-world
  ```

