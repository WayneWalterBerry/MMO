# Puzzle Design Patterns

**Version:** 1.0  
**Author:** Sideshow Bob (Puzzle Master)  
**Last Updated:** 2026-03-20

---

## Overview

This document catalogs recurring puzzle design patterns used in MMO. Each pattern represents a core puzzle archetype that can be used standalone or combined with others. Understanding these patterns helps designers conceptualize new puzzles and ensures consistent puzzle vocabulary across the team.

---

## Pattern Library

### 1. Lock-and-Key

**Core Mechanic:** Object A locks a goal; Object B unlocks it.

**Structure:**
- **Locked object:** Door, container, mechanism
- **Lock requirement:** Specific tool or key
- **Key object:** Must be found, created, or earned
- **Unlocking action:** USE key ON lock (or specialized verb)

**Variants:**

#### 1.1 Simple Lock (One-Step)
**Example:** Key in chest, key unlocks door.
- Player finds key → player uses key on door → door opens
- **Difficulty:** Level 1–2
- **Cruelty:** Merciful (key cannot be lost permanently)

#### 1.2 Nested Locks (Multi-Step)
**Example:** Three doors, each unlocks the next.
- Player finds key #1 → unlocks door #1 → finds key #2 → unlocks door #2 → etc.
- **Difficulty:** Level 2–3 (linear progression)
- **Cruelty:** Polite (if keys don't regenerate, wasting keys is permanent)

#### 1.3 Multiple Keys for One Lock
**Example:** Door requires TWO keys to open, or key system (e.g., 3 of 5 possible keys work).
- Player must find multiple keys and use them in sequence (or combination)
- **Difficulty:** Level 3–4
- **Cruelty:** Tough (player must choose which keys to use; using wrong key may waste it)

#### 1.4 Compound Lock (Lock + Key + Tool)
**Example:** Door is locked, key is inside a chest, chest is stuck—requires a tool to open.
- STRIKE wedge to open chest → TAKE key from chest → USE key on door
- **Difficulty:** Level 3–4
- **Cruelty:** Polite (prerequisite tools are discoverable and replenishable)

#### 1.5 Magical/Conditional Lock
**Example:** Door opens only if player is holding a specific object (e.g., enchanted amulet).
- Lock checks `player.inventory` for amulet; does not require physical "key" action
- **Difficulty:** Level 2–4 (depends on how player learns the requirement)
- **Cruelty:** Nasty (if requirement is not hinted, player may waste time trying normal keys)

**Design Use:** Lock-and-Key is the foundational puzzle pattern. Use it everywhere doors and containers are involved. Introduce early and often.

**Example in MMO:** Puzzle 001 teaches compound locks implicitly (match requires striker surface to ignite). Puzzle 005 (bedroom escape) will likely use locks.

**Zarfian Consideration:** If the key is unique and can be consumed/lost, mark as "Tough" or "Nasty" depending on feedback quality.

---

### 2. Environmental / Spatial Manipulation

**Core Mechanic:** Puzzle is solved by interacting with or changing the room/environment itself, not by carrying objects.

**Structure:**
- **Environment property:** Rug covers trapdoor, curtains block light, wall is climbable
- **Interaction:** Move, uncover, or alter the environment
- **Consequence:** Alters what's accessible or visible

**Variants:**

#### 2.1 Uncover / Reveal
**Example:** Rug covers trapdoor; player moves rug and trapdoor appears.
- MOVE rug → trapdoor visible/accessible
- **Difficulty:** Level 1–2
- **Cruelty:** Merciful (action is reversible)

#### 2.2 Spatial Relationships
**Example:** Climb wall using furniture as steps.
- Stack boxes → climb boxes → reach window
- **Difficulty:** Level 2–3
- **Cruelty:** Polite (fumbling doesn't break boxes; furniture is stable)

#### 2.3 Environmental State Change
**Example:** Sunlight through window moves as time progresses; player must use the light at the right moment.
- Wait for dusk → sunlight hits mirror → light reflects through hidden door
- **Difficulty:** Level 3–4
- **Cruelty:** Nasty (player may pass the time window without realizing)

#### 2.4 Pressure / Weight-Based
**Example:** Floor tile is pressure-sensitive; standing on it activates a mechanism.
- STAND on tile → mechanism triggers → door opens
- **Difficulty:** Level 2–3
- **Cruelty:** Polite (if mechanism is obvious or hinted)

#### 2.5 Multi-Point Environmental
**Example:** Three levers must be pulled simultaneously (or in correct sequence) to open vault.
- PULL lever #1 → does nothing until lever #2 is pulled → etc.
- **Difficulty:** Level 3–4
- **Cruelty:** Tough (player must discover the sequence or try combinations)

**Design Use:** Environmental puzzles reward exploration and spatial reasoning. Use to make rooms feel alive and interactive.

**Example in MMO:** Rug covering trap-door (planned for later room). Sunlight timing mechanic (teaches time system).

**Research Inspiration:** The Witness uses environmental awareness heavily (e.g., shadows, reflections reveal puzzle patterns). Baba Is You treats room layout as puzzle logic itself.

---

### 3. Combination / Synthesis

**Core Mechanic:** Two or more objects must be combined (or used together in a specific order) to create a new object or state.

**Structure:**
- **Input objects:** Object A + Object B
- **Action:** Combine, use together, or apply one to the other
- **Output:** New object, state change, or unlocked capability

**Variants:**

#### 3.1 Simple Binary Combination
**Example:** Match + matchbox striker → lit match.
- STRIKE match ON matchbox → match mutates to match-lit
- **Difficulty:** Level 2
- **Cruelty:** Polite (match can be relit if needed)

#### 3.2 Ternary Combination
**Example:** Flour + egg + sugar → dough (requires mixing bowl as tool).
- PUT flour IN bowl → PUT egg IN bowl → PUT sugar IN bowl → SHAKE bowl → dough emerges
- **Difficulty:** Level 3–4
- **Cruelty:** Polite if ingredients regenerate; Nasty if not

#### 3.3 Ordering-Dependent Combination
**Example:** Poison must be added to wine in correct sequence to avoid detection.
- ADD poison to wine (if ingredient order is wrong, poison is wasted)
- **Difficulty:** Level 4
- **Cruelty:** Nasty (wrong order consumes resources)

#### 3.4 Tool + Object Application
**Example:** Lockpick + door → opens door.
- USE lockpick ON door → door unlocks (without a key)
- **Difficulty:** Level 2–3
- **Cruelty:** Polite (if lockpick is reusable)

#### 3.5 Chemical / Reaction Chain
**Example:** Three reagents must be combined in a specific order to produce alchemical result.
- ADD reagent A → ADD reagent B → ADD reagent C → HEAT → transmuted object
- **Difficulty:** Level 4–5
- **Cruelty:** Nasty (wrong order may lock player into dead-end)

**Design Use:** Combination puzzles teach the `becomes` mutation system and FSM state transitions. Core to advanced puzzle design.

**Example in MMO:** Puzzle 002 (poison bottle) uses combination. Future alchemy system will rely heavily on this.

**Research Inspiration:** Point-and-click adventures (monkey island, Day of the Tentacle) define the genre via combinations. Return of the Obra Dinn's logic chains are implicit combination puzzles.

---

### 4. Sequence / Ordering

**Core Mechanic:** Actions must be performed in a specific order, or multiple puzzles must be solved in parallel and synchronized.

**Structure:**
- **Locked step:** Action B cannot occur until Action A completes
- **Visibility / Linearity:** Player may or may not know the sequence in advance
- **Consequence:** Wrong order wastes resources or triggers trap

**Variants:**

#### 4.1 Linear Sequence (One Door After Another)
**Example:** Unlock door #1 → find key #2 → unlock door #2 → etc.
- **Difficulty:** Level 2–3
- **Cruelty:** Polite (sequence is obvious; missteps revert)

#### 4.2 Parallel Puzzles with Synchronization
**Example:** Three locks in three rooms must be opened within 60 seconds of each other (or simultaneously).
- Player must plan route, execute quickly
- **Difficulty:** Level 3–4
- **Cruelty:** Tough (time limit creates pressure; resource cost if failed)

#### 4.3 Discovered Sequence
**Example:** Clues are scattered; player must piece together the correct order from hints.
- Find scroll mentioning "First light the candle, then read the scroll, then take the key"
- **Difficulty:** Level 4
- **Cruelty:** Nasty (if hints are cryptic or easy to miss)

#### 4.4 Ritual / Ceremony Sequence
**Example:** Ancient ritual requires objects to be used in a specific order at a specific location.
- RING bell → BOW before altar → PLACE offering → CHANT words
- **Difficulty:** Level 4–5
- **Cruelty:** Nasty (if one wrong step resets the ritual)

#### 4.5 Undo-able Sequence (with Consequences)
**Example:** Pull levers in order; can undo by re-pulling, but each undo consumes a resource.
- PULL lever A → PULL lever B → (oops, wrong order) → PULL lever A again to reset (costs 1 token)
- **Difficulty:** Level 3
- **Cruelty:** Polite (recoverable with cost)

**Design Use:** Sequence puzzles teach planning and consequences. Useful for mid-game pacing.

**Example in MMO:** Room 1→2 escape involves a sequence (darkness → light → find key → open door), though not explicitly locked.

**Research Inspiration:** Zork's sequence puzzles (e.g., the troll bridge requires specific command order). Infocom games relied heavily on hidden sequences as difficulty.

---

### 5. Discovery / Hidden Objects

**Core Mechanic:** Puzzle solution requires finding a hidden object through exploration, sensory interaction, or deduction.

**Structure:**
- **Hidden object:** Not immediately visible
- **Discovery mode:** Exploration, FEEL, SMELL, LISTEN, TASTE, or logic deduction
- **Reveal condition:** Player performs specific action or meets specific state

**Variants:**

#### 5.1 Sensory Discovery (Non-Visual)
**Example:** In darkness, FEEL nightstand → discover drawer.
- Player uses FEEL (or LISTEN, SMELL) to find object without line of sight
- **Difficulty:** Level 1–2
- **Cruelty:** Merciful (sensory action is always available)

#### 5.2 Conditional Visibility
**Example:** Object appears only after a specific condition (e.g., after lighting room, after solving another puzzle).
- Invisible ink becomes visible under flame
- **Difficulty:** Level 3
- **Cruelty:** Tough (player may not realize condition is necessary)

#### 5.3 Spatial Deduction
**Example:** Player deduces object location from clues (e.g., "The key is where water flows").
- Room has stream; object is by stream
- **Difficulty:** Level 3–4
- **Cruelty:** Nasty (if clues are ambiguous or scattered)

#### 5.4 Container Within Container
**Example:** Object is nested 3 levels deep (matchbox inside drawer inside nightstand).
- Must open multiple containers sequentially
- **Difficulty:** Level 2–3
- **Cruelty:** Polite (each container layer teaches containment)

#### 5.5 Hidden Passage / Secret
**Example:** Wall has hidden compartment; player must deduction or random interaction to find it.
- PUSH wall → hidden door opens
- **Difficulty:** Level 4
- **Cruelty:** Cruel (if no hints are given; player may waste hours randomly pushing walls)

**Design Use:** Discovery puzzles reward thorough exploration. Use FEEL and other sensory verbs to hint at objects.

**Example in MMO:** Puzzle 001 teaches sensory discovery (FEEL in darkness).

**Research Inspiration:** Zork's "FEEL" verb is iconic for discovery. Modern games (Outer Wilds, A Short Hike) use environmental discovery as core mechanic.

---

### 6. Transformation / State Mutation

**Core Mechanic:** Object changes state (appearance, capability, or properties) and this change is the puzzle solution or prerequisite.

**Structure:**
- **Initial state:** Object is in state A
- **Mutation trigger:** Specific action, condition, or time event
- **New state:** Object transitions to state B with new properties
- **Consequence:** New state enables further puzzle progress

**Variants:**

#### 6.1 Simple State Transition
**Example:** Unlit candle → lit candle (via fire source).
- State change reveals new property: `casts_light = true`
- **Difficulty:** Level 1–2
- **Cruelty:** Merciful (state change is obvious and beneficial)

#### 6.2 Irreversible Consumption
**Example:** Match burns → match is consumed → gone from world.
- `match-lit` → (after 30s) → `empty_slot` (match is consumed)
- **Difficulty:** Level 2
- **Cruelty:** Polite (consumable items teach resource scarcity)

#### 6.3 Time-Based Decay
**Example:** Food spoils over time → becomes inedible.
- `food-fresh` → (after 10 min) → `food-spoiled` → (after 20 min) → `food-rotten`
- Player must use food before it spoils
- **Difficulty:** Level 3
- **Cruelty:** Tough (if spoiling is not hinted)

#### 6.4 Conditional State Unlock
**Example:** Door is "locked" state; only unlocks if specific condition is met.
- Door is locked IF puzzle is unsolved; becomes unlocked after puzzle is solved
- **Difficulty:** Level 2–3
- **Cruelty:** Polite (unlock condition is usually explicit)

#### 6.5 Cascading Transformations
**Example:** Solve puzzle → object transforms → new object unlocks new area.
- Break mirror → find portal key → unlock door → new room
- **Difficulty:** Level 3–4
- **Cruelty:** Polite (each transformation is a milestone)

#### 6.6 Reverse Transformation (Restoration)
**Example:** Broken object can be repaired → returns to original state.
- `mirror-broken` → (with special tool) → `mirror-intact`
- **Difficulty:** Level 4
- **Cruelty:** Polite if repair tool is available; Nasty if not

**Design Use:** State mutation is the heart of the MMO engine. Every puzzle should teach or reinforce how objects change state.

**Example in MMO:** Puzzle 001 uses match mutation (match → match-lit → burnt). Poison bottle will use potion state transitions.

**Research Inspiration:** King's Quest series pioneered state-based puzzles (e.g., mirror transforms into portal). Myst series uses subtle state changes as exploration rewards.

---

### 7. Lateral Thinking / Non-Obvious Solution

**Core Mechanic:** Puzzle solution requires using an object in an unconventional way, or combining systems in unexpected ways.

**Structure:**
- **Problem:** Player has objective X
- **Obvious approach:** Try Y (which doesn't work)
- **Lateral solution:** Use Z in unconventional way (which works)
- **Aha moment:** Player realizes new possibility

**Variants:**

#### 7.1 Object Multi-Use
**Example:** Hammer can break things, but also can be used to ring a bell.
- Player tries BREAK object with hammer → doesn't work
- Player tries RING bell WITH hammer → works!
- **Difficulty:** Level 4
- **Cruelty:** Tough (if no hints; merciful if object description mentions "could ring something")

#### 7.2 Reverse Problem
**Example:** To get warm, don't build a fire—instead, find a blanket.
- Player tries to find wood to burn (fails)
- Player tries to find blanket (succeeds, is warmer)
- **Difficulty:** Level 3–4
- **Cruelty:** Nasty (if puzzle is framed as "get warm" without hinting that fire isn't the only way)

#### 7.3 Exploit Engine Mechanic
**Example:** Use FEEL to navigate a room you can't see; use it as "sonar" to map space.
- Player learns FEEL is meant for touching objects, then realizes it can map space
- **Difficulty:** Level 4
- **Cruelty:** Polite (if sensory feedback is immersive enough to hint at this)

#### 7.4 Impossibility as Solution
**Example:** Can't pick a lock, so instead go around by climbing wall (which is possible).
- Player tries USE lockpick ON door (doesn't work)
- Player tries CLIMB wall (works; discovers alternate route)
- **Difficulty:** Level 4
- **Cruelty:** Polite (if room description mentions climbable wall)

#### 7.5 Chaining Systems
**Example:** Combine object A from system X with tool B from system Y to solve puzzle Z.
- Use alchemy result (from crafting) with sensory trick (from exploration) to unlock door
- **Difficulty:** Level 5
- **Cruelty:** Nasty (if no hints connect the two systems)

**Design Use:** Lateral thinking puzzles are signature challenges. Reserve for Level 4–5 puzzles. Reward creativity.

**Example in MMO:** Puzzle 005 (bedroom escape) will likely feature lateral thinking (e.g., use shoe as hammer instead of finding hammer).

**Research Inspiration:** The Witness's "aha moments" rely on lateral thinking (e.g., realizing the puzzle is not just on the panel, but in the environment). Baba Is You's entire premise is lateral thinking (game rules become puzzle pieces).

---

### 8. Deduction / Logic Puzzle

**Core Mechanic:** Player must solve a logic puzzle (e.g., riddle, Sudoku, constraint satisfaction) as part of the adventure.

**Structure:**
- **Clues:** Player receives statements or information
- **Logic problem:** Determine which answer satisfies all clues
- **Solution:** Input answer; puzzle advances

**Variants:**

#### 8.1 Simple Riddle
**Example:** "I have cities but no houses. What am I?" → Answer: Map.
- NPC asks riddle; player must guess answer
- **Difficulty:** Level 2–3
- **Cruelty:** Merciful if multiple guesses allowed; Cruel if only one guess

#### 8.2 Constraint Satisfaction
**Example:** Three suspects, three motives; clues eliminate possibilities until one remains.
- "A was in the library. B wasn't in the garden. C has alibi for the study."
- Deduce who was where
- **Difficulty:** Level 3–4
- **Cruelty:** Tough (requires careful note-taking)

#### 8.3 Pattern Recognition
**Example:** Sequence of numbers; deduce the next number.
- `2, 4, 8, 16, ?` → Answer: 32
- **Difficulty:** Level 3
- **Cruelty:** Polite (many patterns can be guessed)

#### 8.4 Code-Breaking / Cipher
**Example:** Message is encrypted; player must deduce cipher and decrypt message.
- `ROT13`, `Caesar cipher`, `substitution cipher`
- **Difficulty:** Level 4–5
- **Cruelty:** Nasty (if hint is insufficient)

#### 8.5 Sudoku / Number Puzzle
**Example:** Number grid must be filled such that each row, column, and region contains digits 1–9.
- **Difficulty:** Level 4–5 (depends on difficulty of Sudoku)
- **Cruelty:** Polite (if player can use external tools or hints)

**Design Use:** Logic puzzles are optional enrichment. Don't overuse in core path; they can frustrate players who dislike logic games.

**Example in MMO:** Optional "scholar's challenge" room with cipher puzzle.

**Research Inspiration:** Infocom games (especially Zork III) used logic riddles. Return of the Obra Dinn is fundamentally a deduction puzzle game. Portal 2 tests spatial logic.

---

### 9. Moral / Choice Puzzle

**Core Mechanic:** Puzzle has no single "correct" solution; player must choose a solution, and the choice has narrative consequences.

**Structure:**
- **Dilemma:** Multiple valid solutions with different outcomes
- **Stakes:** Each solution leads to different story branch
- **Consequence:** Player's choice shapes future story

**Variants:**

#### 9.1 Sacrifice vs. Rescue
**Example:** Can save NPC or save object; can't do both.
- SAVE NPC → object is lost (but NPC lives)
- SAVE object → object survives (but NPC dies)
- **Difficulty:** Level 3 (mechanical) + Level 5 (narrative)
- **Cruelty:** Polite (both choices are valid; no "fail" state)

#### 9.2 Utilitarian vs. Deontological
**Example:** Can steal medicine to save many, or respect property rights.
- TAKE medicine → cures plague (but theft is crime)
- DON'T TAKE medicine → respect law (but people die)
- **Difficulty:** Level 4–5 (depends on how choice is discovered)
- **Cruelty:** Polite (both branches are complete)

#### 9.3 Path Splitting
**Example:** Multiple valid paths forward; choosing one locks out the other.
- Go north → desert route (harder, faster)
- Go south → forest route (easier, slower)
- **Difficulty:** Level 2–3
- **Cruelty:** Polite (both paths lead to same end goal)

#### 9.4 Truth vs. Lie
**Example:** Can tell NPC the truth or lie; consequences differ.
- TELL truth → NPC trusts you (but is in danger)
- LIE → NPC is safe (but distrusts you later)
- **Difficulty:** Level 4 (narrative)
- **Cruelty:** Polite (both choices progress story)

**Design Use:** Moral puzzles are high-investment. Use sparingly and ensure both branches are fully fleshed out.

**Example in MMO:** "Should you poison the rival lord?" puzzle (Puzzle 002 extended).

**Research Inspiration:** Planescape: Torment defined choice-based narrative. The Witcher 3's moral choices are infamous for having no "correct" answer. Life is Strange explores consequences across episodes.

---

## Pattern Combinations

Puzzles can combine multiple patterns for increased complexity:

| Pattern 1 | + | Pattern 2 | = | Result | Example |
|-----------|---|-----------|---|--------|---------|
| Lock-and-Key | + | Combination | | Compound lock requiring crafted key | Forge metal key from ore |
| Environmental | + | Sequence | | Timed environmental change | Solve before sunset |
| Discovery | + | Lateral Thinking | | Hidden shortcut using unconventional method | Use shadow to navigate unmarked corridor |
| Transformation | + | Sequence | | Cascading state changes | Break mirror → portal opens → enter new room → puzzle there |
| Deduction | + | Moral | | Logic puzzle with ethical branch | Deduce murderer's identity, then choose: report or conceal |

---

## Pattern Selection by Difficulty Level

| Level | Recommended Patterns | Avoid |
|-------|----------------------|-------|
| 1 | Simple Lock, Sensory Discovery | Deduction, Lateral Thinking, Moral |
| 2 | Lock-and-Key, Combination, Simple Sequence | Complex Deduction, Moral |
| 3 | Environmental, Discovered Sequence, Discovery, State Mutation | (All are viable with good design) |
| 4 | Lateral Thinking, Logic Puzzle, Choice Puzzle, Complex Combinations | Overly obscure sensory hints |
| 5 | Pattern Combinations, High-Consequence Choices, Cascading Transformations | Simple patterns (unless intentional irony) |

---

## Best Practices

1. **Teach the pattern before using it hard:** Introduce lock-and-key via simple door before using it in complex multi-room escape.

2. **Combine patterns vertically, not horizontally:** A Level 4 puzzle should combine 2–3 patterns deeply, not introduce 5 new patterns shallowly.

3. **Sensory hints first:** Before requiring lateral thinking, hint at unconventional solutions via sensory feedback.

4. **Failure is learning:** Design puzzles so failure teaches the pattern.

5. **Zarfian consciousness:** Always know whether your puzzle is Merciful, Polite, Tough, Nasty, or Cruel. Document it.

6. **GOAP interaction:** Consider whether GOAP will auto-resolve your puzzle. If yes, can the player still learn something? If no, is that intentional?

---

## References

- **Classic Text Adventures:** Zork I–III, Infocom games (Deadline, Sorcerer, Enchanter)
- **Modern Adventure Games:** Return of the Obra Dinn, The Witness, Baba Is You, Outer Wilds
- **Choice-Based Games:** Planescape: Torment, The Witcher 3, Life is Strange
- **Escape Room Design:** Reference rooms and design blogs on online escape room UX
