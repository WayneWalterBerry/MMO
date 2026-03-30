# Puzzle 04: Beast Burger Kitchen

**Room:** The Beast Burger Kitchen (East of Hub)  
**Difficulty:** ★★★ (Six sequential steps, ~2–3 minutes)  
**Educational Angle:** Following step-by-step instructions; understanding that order matters; patience and rereading

---

## Premise

You walk into a bright kitchen. A big grill sizzles. Shelves are loaded with burger ingredients — buns, patties, cheese, lettuce, tomato, pickles, and sauces. A recipe card sits on the counter. It says: "Build the Beast Burger! Follow the recipe EXACTLY." You need to pick up each ingredient and place it on a plate in the correct order. Get it right and the burger is complete — a bell rings and you win a Beast Burger coupon. Get it wrong and the burger falls apart with a funny splat sound, and you have to start over.

---

## Objects Required

### Recipe Card (sheet, on counter)

1. **Recipe Card** (sheet)
   - on_look: 
     ```
     THE BEAST BURGER RECIPE
     (Follow these steps IN ORDER!)

     Step 1: Put the bottom bun on the plate.
     Step 2: Add one beef patty.
     Step 3: Add a slice of cheese.
     Step 4: Add lettuce leaves.
     Step 5: Add a slice of tomato.
     Step 6: Put the top bun on top.

     NOW YOU HAVE THE BEAST BURGER!
     ```
   - This is readable; player can reference it while building.

### Ingredients (small-items, on shelves or counter)

2. **Bottom Bun** (small-item)
   - on_look: "A soft, toasted hamburger bun. This is the bottom piece."
   - on_feel: "Warm and soft."
   - on_smell: "Smells like fresh bread."
   - Step in recipe: **Step 1** (goes on plate first)

3. **Beef Patty** (small-item)
   - on_look: "A juicy beef patty, hot off the grill. Smells amazing!"
   - on_feel: "Warm and squishy."
   - on_smell: "Smells like grilled beef."
   - Step in recipe: **Step 2** (goes on bun)

4. **Cheese Slice** (small-item)
   - on_look: "A perfectly melted slice of yellow cheese."
   - on_feel: "Warm and gooey."
   - on_smell: "Smells like melted cheese."
   - Step in recipe: **Step 3** (goes on patty)

5. **Lettuce Leaves** (small-item)
   - on_look: "Fresh, crispy lettuce leaves."
   - on_feel: "Cool and crunchy."
   - on_smell: "Smells fresh and green."
   - Step in recipe: **Step 4** (goes on cheese)

6. **Tomato Slice** (small-item)
   - on_look: "A thick, juicy slice of ripe tomato."
   - on_feel: "Cool and slightly squishy."
   - on_smell: "Smells like fresh tomato."
   - Step in recipe: **Step 5** (goes on lettuce)

7. **Top Bun** (small-item)
   - on_look: "A soft, toasted hamburger bun. This is the top piece."
   - on_feel: "Warm and soft."
   - on_smell: "Smells like fresh bread."
   - Step in recipe: **Step 6** (goes on top, final step)

### Building Surface

8. **Plate** (furniture/container, on counter)
   - on_look: "A wide, clean plate. Ready for burger building!"
   - Accepts ingredients in the correct order.
   - Has a special FSM state for tracking burger progress.

### The Grill (furniture, decoration)

9. **Grill** (furniture)
   - on_look: "A big metal grill with flames licking underneath."
   - on_listen: "You hear a loud sizzle as beef cooks."
   - Decoration only.

### Winning Condition

10. **Bell** (appears when burger is complete)
    - Appears after all 6 ingredients are placed in correct order.
    - Sound effect: RING RING RING!
    - Output: "You did it! The Beast Burger is COMPLETE! A bell RINGS and MrBeast's voice booms: 'PERFECT BURGER, WYATT! Here's your Beast Burger coupon!'"

---

## Solution Steps

1. **READ the Recipe Card** (optional, but recommended)
   - Output: Shows the 6 steps clearly.
   - This teaches the player what to do.

2. **TAKE the Bottom Bun**
   - Output: "You pick up the soft bottom bun."

3. **PUT Bottom Bun on the plate**
   - Output: "You place the bottom bun on the plate. Good start!"
   - Plate FSM: advances to "step_1_complete"

4. **TAKE the Beef Patty**
   - Output: "You pick up the hot beef patty. It smells amazing!"

5. **PUT Beef Patty on the plate** (on top of bun)
   - Output: "You place the beef patty on the bun. Getting closer!"
   - Plate FSM: advances to "step_2_complete"

6. **TAKE the Cheese Slice**
   - Output: "You pick up the melted cheese slice."

7. **PUT Cheese Slice on the plate** (on top of patty)
   - Output: "You place the cheese on the patty. It's melting perfectly!"
   - Plate FSM: advances to "step_3_complete"

8. **TAKE the Lettuce Leaves**
   - Output: "You pick up the crisp lettuce."

9. **PUT Lettuce Leaves on the plate** (on top of cheese)
   - Output: "You place the lettuce on top. Nice and fresh!"
   - Plate FSM: advances to "step_4_complete"

10. **TAKE the Tomato Slice**
    - Output: "You pick up the juicy tomato slice."

11. **PUT Tomato Slice on the plate** (on top of lettuce)
    - Output: "You place the tomato on top. Almost done!"
    - Plate FSM: advances to "step_5_complete"

12. **TAKE the Top Bun**
    - Output: "You pick up the top bun."

13. **PUT Top Bun on the plate** (on top of tomato, final step)
    - Output: "You place the top bun on top... DING! The burger is COMPLETE!"
    - Bell sound effect: RING RING RING!
    - MrBeast voice: "PERFECT BURGER, WYATT! Here's your Beast Burger coupon!"
    - Plate FSM: transitions to "burger_complete"
    - Coupon appears in room (takeable)
    - Room declares victory

---

## FSM States

| State | Description | Trigger | Next State |
|-------|-------------|---------|-----------|
| `empty` | Plate is empty; no ingredients placed | Entry (default) | After step 1 |
| `step_1_complete` | Bottom bun placed | Put bottom bun | After step 2 |
| `step_2_complete` | Beef patty placed | Put beef patty on bun | After step 3 |
| `step_3_complete` | Cheese placed | Put cheese on patty | After step 4 |
| `step_4_complete` | Lettuce placed | Put lettuce on cheese | After step 5 |
| `step_5_complete` | Tomato placed | Put tomato on lettuce | After step 6 |
| `burger_complete` | Burger finished! | Put top bun | —— (stays) |

### State Behaviors

- **empty state:**
  - Accepting ingredient NOT in step 1 → splat sound. Output: "Oops! The ingredient falls apart! Read the recipe. Step 1 is the bottom bun first!"
  - Accepting bottom bun → advance to step_1_complete.

- **step_N_complete states (N = 1–5):**
  - Each state only accepts the next ingredient in order.
  - Accepting wrong ingredient → splat sound. Output: "Oops! That's not the next step! The burger falls apart! Read the recipe and try again!"
  - Accepting correct ingredient → advance to next step.

- **burger_complete state:**
  - Burger is done and won't accept more ingredients (if player tries to add more).

---

## Hints (Options System — 3 Tiers)

### Tier 1 (Standard)
**Output:** "You have a recipe card right there on the counter. Have you read it? Follow the steps in order!"

### Tier 2 (Context Clues)
**Output:** "The recipe says to put the bottom bun first. Then the patty. Then cheese. Then lettuce. Then tomato. Then the top bun. Do it step-by-step!"

### Tier 3 (Mercy Mode)
**Output:** "Try: READ RECIPE. Then: TAKE BOTTOM BUN. Then: PUT BOTTOM BUN ON PLATE. Then keep going with each ingredient in order."

---

## Failure States

**Placing ingredients in the wrong order:**
- **Output:** "Oops! That's not right! The burger falls apart with a SPLAT! Read the recipe card again. You need to follow the steps IN ORDER!"
- **Sound effect:** Splat sound (silly, not harsh)
- **Consequence:** The plate returns to its previous step (or resets to empty, depending on design choice). All placed ingredients pop back into the player's inventory.
- **Visual:** Burger visually collapses on the plate.
- **Encouragement:** "Try again! Read each step carefully!"

---

## Difficulty Rating

★★★ (3 stars)

**Why:** Six steps in order. This requires the player to:
1. Read the recipe.
2. Remember the sequence.
3. Execute it correctly without skipping or reordering.
4. If a mistake is made, start over.

Should take 2–3 minutes for a first-time player. More experienced players can do it in 1 minute.

---

## Educational Angle

**Skills:**
- Reading and following multi-step instructions.
- Understanding that order matters in processes (cooking, building, assembly).
- Patience and careful execution.
- Rereading when you make a mistake.

**Why it matters:** Many real-world tasks (cooking, assembly, coding) require following steps in exact order. Missing a step or reordering them breaks the result. This puzzle teaches that lesson in a fun, forgiving way.

**Lesson for Wyatt:** "Recipes aren't just ideas — they're exact instructions. If you follow them perfectly, you get the right result. If you skip a step or do them out of order, it all falls apart. That's why cooks read recipes so carefully!"

---

## Notes for Flanders (Object Designer)

- All ingredients are small-item template, takeable, and stackable on the plate.
- Plate is a special container with advanced FSM tracking:
  - Track which step of the burger-building process is complete.
  - `on_put` hook validates the ingredient type and order.
  - If correct, advance state and show appropriate message.
  - If wrong, play splat sound, eject all items, reset state.
- Recipe card is sheet template, readable (on_look returns the full recipe).
- Grill is just decoration.
- When burger is complete, a "Beast Burger Coupon" object appears (small-item, takeable).

---

## Notes for Nelson (Tester)

- **Happy path:** Read recipe → take bottom bun → put on plate → take patty → put on plate → ... → take top bun → put on plate → victory.
- **Sad path (wrong order):** Take cheese → put on plate → splat → all ingredients eject → reset to empty state.
- **Sad path (skip step):** Take bottom bun → put on plate → take cheese (skip patty) → put on plate → splat.
- **Regression test:** Verify FSM state tracking; verify ingredient validation; verify splat sound plays; verify items eject correctly.
- **Headless test:**
  ```
  echo -e "read recipe\ntake bottom bun\nput bottom bun on plate\ntake patty\nput patty on plate\ntake cheese\nput cheese on plate\ntake lettuce\nput lettuce on plate\ntake tomato\nput tomato on plate\ntake top bun\nput top bun on plate" | lua src/main.lua --headless --world wyatt-world
  ```

