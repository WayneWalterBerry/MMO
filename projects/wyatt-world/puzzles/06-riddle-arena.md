# Puzzle 06: Riddle Arena

**Room:** The Riddle Arena (Upstairs from Hub)  
**Difficulty:** ★★★★ (Lateral thinking, wordplay, metaphor, ~2–3 minutes)  
**Educational Angle:** Riddle-solving, wordplay, metaphorical thinking, connecting abstract clues to concrete objects

---

## Premise

You walk into a game-show stage with spotlights and colorful riddle boards. Three big boards stand in a row, each with a riddle written in big letters. In front sits a podium with three buttons — one for each riddle. A screen above says: "Solve all three riddles to win!" For each riddle, you must figure out what the answer IS, then interact with that object in the room to confirm your answer.

---

## Objects Required

### The Riddle Boards (furniture, decoration)

1. **Riddle Board 1** (furniture)
   - on_look: 
     ```
     RIDDLE 1:
     I have hands but cannot clap.
     I have a face but cannot smile.
     What am I?
     ```
   - Answer: **The Clock** (in the room)

2. **Riddle Board 2** (furniture)
   - on_look: 
     ```
     RIDDLE 2:
     I am full of keys but cannot open any door.
     What am I?
     ```
   - Answer: **The Piano** (in the room)

3. **Riddle Board 3** (furniture)
   - on_look: 
     ```
     RIDDLE 3:
     The more you take from me, the bigger I get.
     What am I?
     ```
   - Answer: **The Hole** (in the stage floor)

### The Answer Objects (scattered in the room)

4. **The Clock** (furniture, on wall)
   - on_look: "A clock on the wall. It has hands (the hour and minute hands) and a face (the clock face). But it can't clap or smile!"
   - on_listen: "You hear a steady ticking sound. Tick, tick, tick."
   - on_touch / on_examine: "You touch the clock. The hands move. DING! Riddle 1 is correct!"
   - When touched after Riddle 1 is solved: FSM transitions, board 1 lights up green.
   - Keywords: "clock", "time", "watch"

5. **The Piano** (furniture, in corner)
   - on_look: "A beautiful grand piano. It has 88 keys spread across the keyboard. You can press keys to make music!"
   - on_listen: "If you listen closely, you hear a faint musical note."
   - on_touch / on_examine: "You touch the piano keys. A chord plays! DING! Riddle 2 is correct!"
   - When touched after Riddle 2 is solved: FSM transitions, board 2 lights up green.
   - Keywords: "piano", "keys", "instrument"

6. **The Hole** (furniture/landmark, in stage floor)
   - on_look: "A large, jagged hole in the wooden stage floor. The deeper it gets, the bigger it seems!"
   - on_feel: "You can feel the edges of the hole. It's rough."
   - on_touch / on_examine: "You reach into the hole... and the more you take (like dirt, splinters, debris), the bigger the hole gets! DING! Riddle 3 is correct!"
   - When touched after Riddle 3 is solved: FSM transitions, board 3 lights up green.
   - Keywords: "hole", "pit", "gap"

### The Podium (furniture, with answer buttons)

7. **Podium** (furniture)
   - on_look: "A podium with three big buttons. Each one corresponds to a riddle."
   - Decorative (optional: buttons could confirm answers if we want a two-stage solution).

### Success Bell & Prize

8. **Bell** (sound effect, appears after all 3 riddles solved)
   - Sound: RING RING RING!
   - Output: "You solved all three riddles! MrBeast's voice booms: 'BRILLIANT THINKING, WYATT! Here's your prize!'"

9. **Trophy** (small-item, appears in room after all riddles solved)
   - on_look: "A shiny gold trophy with 'RIDDLE MASTER' engraved on it."
   - Takeable.

---

## Solution Steps

### For Each Riddle:

1. **READ the Riddle Board**
   - Player reads the riddle and thinks about what the answer might be.

2. **Find the answer object in the room**
   - Riddle 1: Clock (on wall)
   - Riddle 2: Piano (in corner)
   - Riddle 3: Hole (in stage floor)

3. **TOUCH / EXAMINE the answer object**
   - Example: "TOUCH CLOCK"
   - Output: "You touch the clock. The hands move. DING! Riddle 1 is correct!"
   - FSM: Riddle Board 1 transitions to "solved" state, lights up green.

4. **Repeat for Riddle 2 and Riddle 3**
   - "TOUCH PIANO" → Board 2 lights up
   - "TOUCH HOLE" → Board 3 lights up

5. **When all three boards are lit green:**
   - Output: "All three riddle boards light up bright GREEN! A bell RINGS and MrBeast's voice booms: 'BRILLIANT THINKING, WYATT! You solved them all! Here's your prize!'"
   - Trophy appears in the room.
   - FSM: room enters "puzzle_complete" state.

6. **TAKE the trophy**
   - Output: "You lift the trophy! You're the Riddle Master!"

---

## FSM States

| State | Description | Trigger | Next State |
|-------|-------------|---------|-----------|
| `unsolved` | No riddles solved; all boards dark | Entry (default) | After 1st solve |
| `one_solved` | Riddle 1 solved; board 1 green | Touch clock | After 2nd solve |
| `two_solved` | Riddles 1–2 solved; boards 1–2 green | Touch piano | After 3rd solve |
| `puzzle_complete` | All 3 riddles solved; all boards green | Touch hole | —— (stays) |

### State Behaviors

- **unsolved state:**
  - Touching any object shows the object's normal description.
  - Board remains dark.

- **one_solved state:**
  - Board 1 remains green.
  - Boards 2 and 3 are still dark.
  - Player must solve Riddle 2 next.

- **two_solved state:**
  - Boards 1 and 2 remain green.
  - Board 3 is still dark.
  - Player must solve Riddle 3 next.

- **puzzle_complete state:**
  - All boards are green.
  - Trophy is visible and takeable.
  - Victory message has been shown.

---

## Hints (Options System — 3 Tiers)

### Tier 1 (Standard)
**Output:** "Each riddle is a clue about something in this room. Read the riddle carefully. Think about what it describes. Then look for that object in the room!"

### Tier 2 (Context Clues)
**Output:** "Riddle 1: Something with hands and a face. What keeps time and has those? Riddle 2: Something with lots of keys. What musical instrument has keys? Riddle 3: Something that gets bigger when you take from it. What hole gets bigger?"

### Tier 3 (Mercy Mode)
**Output:** "Riddle 1 answer: Clock. Try: TOUCH CLOCK. Riddle 2 answer: Piano. Try: TOUCH PIANO. Riddle 3 answer: Hole. Try: TOUCH HOLE."

---

## Failure States

**Trying to touch a wrong object for a riddle:**
- There is no explicit "wrong" interaction — the puzzle is about figuring out what the riddle means and finding the right object.
- If a player examines an object that's not the answer, it just shows the normal description.
- Example: "TOUCH PODIUM" → "You touch the podium. Nothing happens. That's not the answer to any riddle."

**Trying to solve riddles out of order (optional):**
- If we want strict sequencing: Solving Riddle 2 before Riddle 1 doesn't count.
- Output: "The board doesn't light up. You need to solve Riddle 1 first!"
- However, the simpler design: allow any order (no strict sequence).

---

## Difficulty Rating

★★★★ (4 stars)

**Why:** Riddle-solving requires:
1. Understanding metaphorical language ("hands" = clock hands, not human hands).
2. Lateral thinking (a piano is "full of keys" but they're not door keys).
3. Abstract reasoning (a hole gets bigger when you take from it — counterintuitive).
4. Connecting the riddle to the physical object in the room.

This is the hardest reading challenge in Wyatt's World. Should take 2–3 minutes for a clever 5th-grader. Younger kids might need hints.

---

## Educational Angle

**Skills:**
- Riddle-solving and wordplay.
- Metaphorical thinking (recognizing that words can mean different things).
- Lateral thinking (the answer isn't always literal).
- Making connections between abstract clues and concrete objects.

**Why it matters:** Riddles develop creative thinking and language flexibility. They teach that words can be playful and ambiguous. Understanding riddles helps with reading comprehension, poetry, and humor.

**Lesson for Wyatt:** "Words can trick you in fun ways. 'Keys' doesn't always mean door keys. 'Hands' doesn't always mean fingers. Read carefully, think creatively, and the riddle reveals its answer!"

---

## Notes for Flanders (Object Designer)

- **Clock:** Furniture template. `on_look` describes hands and face. `on_touch` shows the riddle-solved message and triggers FSM.
- **Piano:** Furniture template. `on_look` describes 88 keys. `on_touch` shows the riddle-solved message and triggers FSM.
- **Hole:** Furniture template (a landmark/landmark object). `on_look` describes the hole. `on_touch` shows the riddle-solved message and triggers FSM.
- **Riddle Boards:** Furniture template (just displays text). No interaction beyond looking.
- Each answer object needs a special `on_touch` verb that:
  - Checks the current room state (which riddles are solved).
  - If the riddle for that object is not yet solved, triggers FSM transition.
  - If the riddle is already solved, shows a message like "You already solved this riddle!"
- Trophy: Small-item template, appears after all riddles solved, takeable.

---

## Notes for Nelson (Tester)

- **Happy path:** Read riddle 1 → touch clock → board 1 green → read riddle 2 → touch piano → board 2 green → read riddle 3 → touch hole → board 3 green → all boards green → trophy appears → victory.
- **Order test:** Can player solve in any order, or must they be strict sequence? (Design choice — I recommend "any order" for simplicity.)
- **Regression test:** Verify FSM state tracking; verify boards light up; verify trophy appears; verify touch interactions work.
- **Headless test:**
  ```
  echo -e "read riddle 1\ntouch clock\nread riddle 2\ntouch piano\nread riddle 3\ntouch hole" | lua src/main.lua --headless --world wyatt-world
  ```

