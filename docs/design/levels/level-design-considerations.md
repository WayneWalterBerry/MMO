# Level Design Considerations

Design rules, considerations, and methodology for creating levels in the MMO.

## What is a Level?

A **level** is a set of rooms that work together as a cohesive gameplay experience. Levels have:
- A **theme** (setting, mood, narrative arc)
- A **progression** (skills taught, difficulty curve)
- **Completion criteria** (what triggers moving to the next level)
- A **map** (how rooms connect spatially)

Individual level designs live in `docs/levels/`. This document covers the *methodology* of designing levels.

---

## Considerations

### 1. Objects May Cross Level Boundaries

**Players carry objects between levels.** If a player picks up an object in Level 1, they may still have it when they enter Level 2. This has significant design implications:

#### The Problem
An object from a previous level could trivialize a puzzle in a later level. For example:
- A brass key from Level 1 might open a lock designed to be a Level 2 puzzle
- A lit torch from Level 1 might bypass a "find light" puzzle in Level 2
- A rope from Level 1 might skip a climbing challenge in Level 2

#### The Design Rule
**If the level designer does NOT want an object to transfer to the next level** (because it would break a future puzzle), then:

> **There MUST be a task or puzzle that destroys, consumes, or removes that object before the player can enter the next level.**

This should feel **natural and diegetic** — not arbitrary. Good examples:
- A **gate that requires surrendering the key** to pass (lock-and-consume)
- A **fire that consumes a rope** as the player uses it to descend (natural consumption)
- A **guard who confiscates weapons** at the entrance to a new area (narrative removal)
- A **puzzle that requires sacrificing an object** as its solution (trade-off puzzle)

Bad examples (avoid these):
- ❌ Objects simply vanishing from inventory at a level boundary
- ❌ "You can't bring that here" with no explanation
- ❌ Invisible walls that strip inventory

#### Design Checklist for Level Transitions
When designing a level boundary, the level designer MUST:

1. **Inventory audit:** List every object the player could be carrying when they reach the exit
2. **Impact analysis:** For each object, ask: "Does this break or trivialize any puzzle in the next level?"
3. **Removal design:** For objects that must not cross, design a natural removal mechanism
4. **Optional objects:** Some objects SHOULD cross levels — a worn cloak, a journal, a lucky coin. These create continuity.
5. **Test the boundary:** Nelson should specifically test level transitions with various inventory states

#### Principle 8 Compliance
Object removal at level boundaries must follow Principle 8: **"The Engine Executes Metadata; Objects Declare Behavior."** The removal mechanism should be declared in object metadata or room/puzzle metadata — not hard-coded in the engine.

---

### 2. Objects Are Shared Across Levels

**Objects are not level-specific; they are reusable assets.** All object specifications live in `docs/objects/` and can appear in any level. A brass key, a candle, a rope — these are game-wide objects, not tied to a single level.

#### Why This Matters

- **Reusability:** A brass key designed for Level 1 can appear in Level 3, Level 5, or anywhere else the designer needs a key-like object.
- **Consistency:** A candle is a candle, whether in a dungeon or a mansion. Its mechanics and properties don't change between levels.
- **Scalability:** As the game grows, reusing object specs prevents documentation and implementation bloat.

#### The Design Rule

**Only create new object specs when a level genuinely needs something that doesn't exist yet.** Before adding a new object:

1. **Search `docs/objects/`** — Is there an existing object that fits?
2. **Adapt existing specs** — Can an existing object be configured differently (e.g., a "rusty key" vs. a "golden key" — same mechanics, different properties)?
3. **Only then create new** — If truly unique, document it in `docs/objects/`.

Objects are not owned by levels; levels *consume* objects from a shared inventory.

---

### 3. Puzzles Should NOT Be Reused Across Levels

**Each puzzle should be unique to its level.** Reusing the same puzzle in a different level feels lazy and breaks the player's immersion. They should feel like "new challenges," not "that same thing again."

#### The General Rule

**Do not copy a puzzle from Level 1 and reuse it verbatim in Level 2.** This violates player expectations and wastes the opportunity to teach new mechanics or create fresh challenges.

#### The Exception: Refactored Puzzles

A puzzle **CAN** be reused IF it is refactored to "look and feel" completely different — even if the underlying mechanic is similar.

**Example: Lock-and-Key Pattern**

- **Level 1:** A "lock-and-key" puzzle uses a brass key + iron door. The player must find the key in the dark, identify it by touch, navigate to the locked door, and insert it.
  - *Sensory exploration, tool chains, navigation.*

- **Level 3:** A similar lock-and-key *mechanic* but completely reimagined:
  - Objects: combination lock + wooden chest (not a key-and-door)
  - Context: Requires solving a math puzzle to discover the combination
  - Sensory: Listening for clicking sounds as the dial turns
  - Consequence: Opening the chest triggers a trap
  - *Completely different experience, even though the core pattern is "unlock something with hidden information."*

#### The Checklist

Before reusing a puzzle mechanic in a new level, ask:

- ⬜ **Are the objects different?** (Different objects = different feel)
- ⬜ **Is the setting different?** (Different room, different narrative context)
- ⬜ **Is the sensory experience different?** (Sight, sound, touch — are they engaging different senses?)
- ⬜ **Are the consequences different?** (What happens if you fail? Success?)
- ⬜ **Is the progression step different?** (Early game vs. late game? Teaching vs. testing?)

If you can check ALL of these boxes, refactoring a mechanic into a new puzzle is valid. If not, design a truly new puzzle.

---

*More considerations will be added as the team develops level design expertise.*
