# Puzzle 05: Last to Leave Room

**Room:** The Last to Leave Room (West of Hub)  
**Difficulty:** ★★★ (Close observation + careful reading, ~2–3 minutes)  
**Educational Angle:** Attention to detail; comparing description to reality; critical reading

---

## Premise

You walk into a room that looks like a regular living room. A couch. A TV. A bookshelf. A rug. A lamp. A clock on the wall. Everything looks... normal? A sign by the door says: "Three things in this room don't belong. Find them to win!" Your job: EXAMINE objects carefully and read their descriptions closely. Three objects have descriptions that DON'T MATCH what they claim to be. Find the fakes and drop them in a "Found It!" box by the door.

---

## Objects Required

### Incorrect/Fake Objects (the puzzle targets)

These three objects have descriptions that contradict their names:

1. **The Clock** (furniture, on wall)
   - on_look: "A clock hanging on the wall. But wait... it has 15 numbers around the face instead of 12. This isn't a real clock!"
   - on_listen: "No ticking sound. It's frozen."
   - Keywords: "clock", "fake clock", "weird clock"
   - **This is a fake** — belongs in Found It box

2. **The Book** (small-item, on bookshelf)
   - on_look: "A thick hardcover book on the shelf. The title on the spine reads: 'Gnihtsyreve tuoba koob a' ... wait, that's backwards! The real title is 'A book about Everything' written backwards!"
   - on_feel: "It's BACKWARDS. The spine is upside down."
   - Keywords: "book", "fake book", "backwards book"
   - **This is a fake** — belongs in Found It box

3. **The Lamp** (furniture, on side table)
   - on_look: "A lamp sitting on a table. But it's dark and cold, even though the switch is ON. It's not glowing. This is a fake lamp made of painted plastic!"
   - on_feel: "Cold to the touch. Not hot like a real bulb would be."
   - on_listen: "No electrical humming."
   - Keywords: "lamp", "fake lamp", "dark lamp"
   - **This is a fake** — belongs in Found It box

### Correct/Real Objects (decoys)

These four objects have descriptions that ARE correct:

4. **The Couch** (furniture)
   - on_look: "A comfortable-looking couch covered in soft fabric. It looks cozy and inviting."
   - on_feel: "Soft and cushioned."
   - Keywords: "couch", "sofa"
   - **This is real** — don't put in box

5. **The TV** (furniture)
   - on_look: "A flat-screen television. It's powered off right now, but the screen looks clean and shiny."
   - on_listen: "Silence. It's off."
   - Keywords: "tv", "television", "screen"
   - **This is real** — don't put in box

6. **The Bookshelf** (furniture)
   - on_look: "A tall wooden bookshelf filled with books. It's sturdy and well-organized."
   - on_feel: "Solid wood. Strong."
   - Keywords: "bookshelf", "shelf"
   - **This is real** — don't put in box

7. **The Rug** (furniture, on floor)
   - on_look: "A thick, comfortable rug on the floor. It has a cozy pattern."
   - on_feel: "Soft and fuzzy."
   - Keywords: "rug", "carpet"
   - **This is real** — don't put in box

### The Collection Box

8. **Found It! Box** (container, by the door)
   - on_look: "A big yellow box with a sign that says 'FOUND IT! Drop the fakes here!'"
   - Accepts: the three fake objects (clock, book, lamp)
   - Rejects: real objects (with a fun message)

### The Success Sign

9. **Challenge Sign** (sheet, by the door)
   - on_look: "Three things in this room don't belong. Find them to win!"

---

## Solution Steps

1. **EXAMINE each object carefully** (player must read descriptions closely)
   - Example: "EXAMINE CLOCK"
     - Output: "A clock hanging on the wall. But wait... it has 15 numbers around the face instead of 12. This isn't a real clock!"
     - Clue: "It has 15 numbers instead of 12" = FAKE

   - Example: "EXAMINE BOOK"
     - Output: "A thick hardcover book on the shelf. The title on the spine reads: 'Gnihtsyreve tuoba koob a' ... wait, that's backwards! The real title is 'A book about Everything' written backwards!"
     - Clue: "It's backwards" = FAKE

   - Example: "EXAMINE LAMP"
     - Output: "A lamp sitting on a table. But it's dark and cold, even though the switch is ON. It's not glowing. This is a fake lamp made of painted plastic!"
     - Clue: "It's on but not glowing. It's dark and cold." = FAKE

2. **TAKE the fake objects one by one**
   - "TAKE CLOCK"
   - "TAKE BOOK"
   - "TAKE LAMP"

3. **DROP each fake into the Found It! box**
   - "DROP CLOCK IN BOX"
   - "DROP BOOK IN BOX"
   - "DROP LAMP IN BOX"
   - Each time: "You drop the [object] into the Found It! box. Good catch!"

4. **When all three fakes are in the box:**
   - Output: "You found all three fakes! The box lights up and a trophy pops out! MrBeast's voice booms: 'YOU HAVE AN EYE FOR DETAIL, WYATT! Perfect observation! Here's your prize!'"
   - FSM: room enters "puzzle_complete" state
   - Trophy appears in room (takeable)
   - Doors unlock

---

## FSM States

| State | Description | Trigger | Next State |
|-------|-------------|---------|-----------|
| `in_progress` | Puzzle unsolved; all objects visible | Entry (default) | On completion |
| `puzzle_complete` | All three fakes found and boxed | Drop 3rd fake in box | —— (stays) |

### State Behaviors

- **in_progress state:**
  - Real objects in box → cute rejection. Output: "Wait, that one looks real to me! Better check it again!" (item pops out)
  - Fake objects in box → acceptance. Output: "Good catch! That one definitely doesn't belong!" (stays in box, count increments)
  - Tracking: Box counts how many correct fakes are inside (0/3).

- **puzzle_complete state:**
  - Trophy visible and takeable.
  - Victory message shown.

---

## Hints (Options System — 3 Tiers)

### Tier 1 (Standard)
**Output:** "Look at each object carefully. Read its description. Does the description match what the object says it is? Some descriptions have clues that something is wrong!"

### Tier 2 (Context Clues)
**Output:** "Try using EXAMINE on each object. Look for words that don't make sense. A clock with 15 numbers? A lamp that's cold? A book with a backwards title? Those are your fakes!"

### Tier 3 (Mercy Mode)
**Output:** "The fakes are: A clock with 15 numbers (should be 12). A lamp that's on but dark and cold (should be hot and bright). A book with a backwards title. Try: EXAMINE CLOCK. Then: TAKE CLOCK. Then: DROP CLOCK IN BOX."

---

## Failure States

**Putting a real object in the box:**
- **Output:** "Wait, that one looks real to me! Better check it again!"
- **Sound effect:** Gentle "boing" sound (silly, encouraging)
- **Consequence:** Item pops back out of the box into the player's inventory.
- **Visual:** Box briefly flashes or shakes.

**Putting a fake in the box:**
- **Output:** "Good catch! That one definitely doesn't belong here!"
- **Visual:** Item stays in box; counter increments (e.g., "1/3 fakes found").

---

## Difficulty Rating

★★★ (3 stars)

**Why:** This requires:
1. Examining multiple objects (7 total).
2. Reading descriptions carefully to spot contradictions.
3. Distinguishing between real and fake based on subtle textual clues.
4. Not assuming an object is real just because it looks normal.

Should take 2–3 minutes. The puzzle is NOT hard, but you can't rush or skim.

---

## Educational Angle

**Skills:**
- Close observation and attention to detail.
- Critical reading (comparing what something SAYS it is vs. what the description ACTUALLY says).
- Logic (if description contradicts name, it's fake).
- Skepticism (just because something is familiar doesn't mean it's real).

**Why it matters:** In real life, being able to spot inconsistencies and contradictions is a critical thinking skill. This puzzle teaches: "When something seems off, investigate. Don't assume. Read carefully."

**Lesson for Wyatt:** "Always read the fine print. If something seems wrong, it probably is. Pay attention to details. That's how you catch fakes!"

---

## Notes for Flanders (Object Designer)

- All objects are furniture or small-item templates with detailed `on_look` descriptions.
- Fake objects (clock, book, lamp) should have descriptions that explicitly contradict their names.
- Real objects (couch, TV, bookshelf, rug) should have normal, believable descriptions.
- Found It! box is a container template with a special `on_put` hook:
  - Check if item is in the list of known fakes (clock, book, lamp).
  - If yes, accept and increment counter.
  - If no (real object), reject with cute message, eject item.
- When counter reaches 3, transition room to "puzzle_complete" state, show victory message, eject trophy.

---

## Notes for Nelson (Tester)

- **Happy path:** Examine all 7 objects → identify the 3 with contradictory descriptions → take them → drop in box → victory.
- **Sad path:** Try to drop real object (e.g., couch) → rejection with pop-out.
- **Edge case:** Player tries to drop multiple times (e.g., drops couch 5 times). Each time: rejection. Eventually finds the 3 fakes.
- **Regression test:** Verify container rejection logic; verify counter tracking; verify victory trigger at 3/3.
- **Headless test:**
  ```
  echo -e "examine clock\nexamine book\nexamine lamp\ntake clock\ntake book\ntake lamp\ndrop clock in box\ndrop book in box\ndrop lamp in box" | lua src/main.lua --headless --world wyatt-world
  ```

