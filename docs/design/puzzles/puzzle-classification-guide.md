# Puzzle Classification Guide

**Version:** 1.0  
**Author:** Sideshow Bob (Puzzle Master)  
**Last Updated:** 2026-03-20

---

## Overview

This guide standardizes how puzzles are documented, classified, and tracked through their lifecycle. Every puzzle must have a `.md` file in `docs/puzzles/` following the template below. This ensures Wayne, Flanders, and Nelson can quickly understand a puzzle's status, requirements, and design intent.

---

## Puzzle Lifecycle

Puzzles move through three states before and after implementation:

### 🔴 Theorized
**Definition:** Conceptualized; not yet approved by Wayne.

**Characteristics:**
- Preliminary design notes exist
- No formal puzzle doc (or doc marked 🔴 Theorized)
- May lack detailed solution path or object specifications
- Unclear if it fits game flow or technical capability

**Who can create:** Any team member

**Approval trigger:** Wayne reviews, then assigns 🟡 Wanted or requests redesign

**Example:** "A puzzle where player must deduce a password from scattered letters"

---

### 🟡 Wanted
**Definition:** Designed and approved by Wayne; not yet built.

**Characteristics:**
- Complete puzzle doc with detailed solution(s), object specs, and failure modes
- Wayne has signed off on design
- Design specifies which objects exist (or need to be created by Flanders)
- Solution is solvable given current engine capabilities
- Ready for handoff to Flanders (Object Designer)

**Who can create:** Sideshow Bob (with Wayne's feedback), or any designer with Wayne's approval

**Handoff trigger:** Bob hands spec to Flanders; Flanders builds objects in `src/meta/objects/` and integrates into room

**Status during build:** Flanders works on implementation; Bob and Nelson may request changes or clarifications

**Example:** Puzzle 002 (Poison Bottle) — designed and approved, awaiting object implementation

---

### 🟢 In Game
**Definition:** Fully implemented, tested, and working in live game.

**Characteristics:**
- Puzzle is playable in `lua src/main.lua`
- All required objects exist and have correct FSM transitions
- Nelson has tested solvability and edge cases
- No critical bugs in puzzle flow
- Passes both manual and automated testing

**Who verifies:** Nelson (Tester) and Lisa (QA) sign off

**Commitment:** Puzzle is locked; breaking it requires a formal fix (bug fix PR with code review)

**Example:** Puzzle 001 (Light the Room) — implemented and tested, currently in game

---

## Puzzle State Transitions

```
THEORIZED ──(Wayne approves)──> WANTED ──(Flanders builds)──> IN GAME ──(Nelson tests)──> LOCKED
   🔴                              🟡                             🟢
```

**Rules:**
- Wayne must explicitly approve Theorized → Wanted transition
- Flanders must complete implementation before Wanted → In Game
- Nelson must test and sign off before In Game is locked
- If a puzzle has a bug after being locked, it stays 🟢 but a bug-fix PR is required

---

## Puzzle Documentation Template

All puzzles must be documented in `docs/puzzles/{NUMBER}-{SLUG}.md` following this structure:

### 1. Header

```markdown
# Puzzle {NUMBER}: {Title}

**Status:** 🟢 In Game / 🟡 Wanted / 🔴 Theorized  
**Difficulty:** ⭐⭐ Level 2  
**Cruelty Rating:** Polite (recoverable with consequences)  
**Author:** Sideshow Bob  
**Last Updated:** YYYY-MM-DD
```

### 2. Quick Reference Section

```markdown
## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Bedroom, Hallway |
| **Objects Required** | nightstand, matchbox, match, candle |
| **Objects Created** | match-lit (mutation of match) |
| **Prerequisite Puzzles** | None |
| **Unlocks** | Hallway accessible after lighting room |
| **GOAP Compatible?** | Yes (full auto-resolution available) |
| **Multiple Solutions?** | 2 (strike match OR wait for dawn) |
| **Estimated Time** | 2–5 min (first-time), < 1 min (repeat) |
```

### 3. Overview

**1–2 paragraph narrative summary of what the puzzle is about.**

Example: "Player wakes in complete darkness and must find a light source to illuminate the room and proceed. Teaches the tool system and sensory interaction in darkness."

### 4. Puzzle Design

#### 4.1 Solution Path(s)

**Primary Solution:**
1. Numbered step-by-step walkthrough
2. Include required verbs, objects, and state transitions
3. Note compound actions (e.g., "STRIKE match ON matchbox requires both objects")
4. Specify sensory hints at each step

**Alternative Solutions (if any):**
- Daytime path (wait for dawn instead of lighting candle)
- Alternate tool chain (find lighter instead of matches)
- Shortcut (if player discovers non-obvious path)

#### 4.2 Failure Modes & Consequences

Document what can go wrong:

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| Waste all 7 matches | Matchbox is empty; no fire source | Wait for dawn (3–4 min) |
| Light match but don't use it | Match burns out in ~30 sec | Strike another match |
| Try to light candle with no fire | Engine says "you have no fire source" | Find tool first |

**Cruelty assessment:** Are any of these failures unfair? Does the player get feedback?

#### 4.3 What the Player Learns

List 5–8 key learnings. Example:
- FEEL works in darkness (sensory verbs bypass light requirement)
- Containers hold objects; you extract objects from them
- Compound tool actions require TWO objects (match + matchbox striker)
- Resources are consumable and limited
- State mutations are visible (match-lit is a different object)

#### 4.4 Prerequisite Chain

Document what must exist before this puzzle is solvable:

- **Objects:** Which base objects must already be in the game?
- **Verbs:** Does the puzzle require new verbs, or just core verbs?
- **Mechanics:** Does it depend on a mechanic not yet in the game (e.g., time system, decay)?
- **Puzzles:** Does the player need to solve another puzzle first?

#### 4.5 Objects Required & Specs

| Object | Type | State(s) | Key Properties | Built? |
|--------|------|---------|-----------------|--------|
| nightstand | furniture | closed, open | `contains: [drawer]`, `has_drawer: true` | ✅ |
| matchbox | container | closed, open | `has_striker: true`, `contents: [match × 7]` | ✅ |
| match | consumable tool | normal, lit, burnt | `requires_tool: fire_source` (to light), `provides_tool: fire_source` (when lit), `burn_time: 30s` | ✅ |
| candle | light object | unlit, lit | `requires_tool: fire_source`, `casts_light: true` (when lit) | ✅ |

**Legend:** ✅ = built, ⏳ = in progress, ❌ = not started

### 5. Design Rationale

**Why these objects?** Justify design choices.

Example: "Matchbox as a container with 7 matches teaches that tools are physical objects in the world, not abstract resources. The matchbox's striker surface is a property, not a separate object, teaching capability matching."

**Why this difficulty?** Connect to learning objectives and game pacing.

Example: "Level 2 introductory puzzle. Teaches core systems (containment, compound tools, sensory verbs) without overwhelming complexity. GOAP can auto-resolve, so novice players can focus on discovery."

**Why this room / location?** Justify spatial context.

Example: "Bedroom is the starting location. Nightstand is narratively appropriate for matches. Matches near candle suggests where to find them."

### 6. GOAP Analysis

**Is this puzzle GOAP-compatible?**

**How does GOAP interact with the solution?**

Example: "GOAP can auto-resolve the entire puzzle. Player can type 'light candle' and GOAP plans: discover match location → extract match from matchbox → strike match on matchbox → light candle with match. Or player can manually execute all steps. Difficulty is preserved either way because the core insight (light requires fire source) is the puzzle, not the tool-finding."

### 7. Notes & Edge Cases

- **Timing issues:** Does the puzzle depend on timing? (e.g., matches burn out in 30s)
- **State conflicts:** Can two different puzzle solutions interfere with each other?
- **Player softlock:** Can the player reach an unwinnable state? (Should be "No" for merciful designs)
- **Sensory tricks:** Are there clues hidden in unseen sensory modes (SMELL, TASTE)?

### 8. Status & Ownership

```markdown
## Status

🟢 In Game — Tested and working.

**Owner:** Sideshow Bob  
**Builder:** Flanders (Object Designer)  
**Tester:** Nelson  
**Last Tested:** 2026-03-15
```

---

## Puzzle Numbering

**Format:** `{SEQUENCE}-{SLUG}`

- **SEQUENCE:** Three-digit zero-padded integer (001, 002, 003, ..., 999)
- **SLUG:** Kebab-case short title (light-the-room, poison-bottle, bedroom-escape)

**Sequence strategy:**
- 001–010: Introductory (tutorial zone)
- 011–050: Early game (first major location)
- 051–100: Mid game
- 101–200: Late game
- 200+: Optional / end-game / area-specific

**Example:** `005-retrieve-golden-key.md`

---

## Classification Status Fields

Every puzzle `.md` must have a status indicator at the top:

```markdown
**Status:** 🟢 In Game / 🟡 Wanted / 🔴 Theorized
```

**Update protocol:**
- Sideshow Bob moves to 🟡 after Wayne approves design
- Flanders moves to 🟢 after implementation and Nelson tests
- Do NOT move to 🟢 without Nelson's sign-off

---

## Design Review Checklist

Before moving a puzzle from 🔴 → 🟡, ask:

- [ ] Is the puzzle goal clear to the player?
- [ ] Are all required objects specified?
- [ ] Is at least one solution path fully documented?
- [ ] Are failure modes documented and recoverable?
- [ ] Does the puzzle teach something new, or reinforce existing systems?
- [ ] Is it solvable with current engine capabilities?
- [ ] Does it fit the game's narrative and pacing?
- [ ] Has Wayne signed off?

Before moving a puzzle from 🟡 → 🟢, Flanders should:

- [ ] All required objects built and integrated
- [ ] FSM transitions correct (state mutations work)
- [ ] GOAP compatible or manually solvable
- [ ] Nelson has tested and signed off
- [ ] No critical bugs

---

## Appendix: Quick Template

```markdown
# Puzzle {NUMBER}: {TITLE}

**Status:** 🟡 Wanted  
**Difficulty:** ⭐⭐⭐ Level 3  
**Cruelty:** Polite  
**Author:** Sideshow Bob  
**Last Updated:** YYYY-MM-DD

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | |
| **Objects Required** | |
| **Objects Created** | |
| **Prerequisite Puzzles** | |
| **GOAP Compatible?** | |
| **Multiple Solutions?** | |
| **Estimated Time** | |

---

## Overview

[1–2 paragraphs]

---

## Solution Path

### Primary Solution
1.
2.
3.

### Alternative Solutions
- 

---

## Failure Modes

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| | | |

---

## What the Player Learns

1.
2.
3.

---

## Prerequisite Chain

**Objects:**
**Verbs:**
**Mechanics:**
**Puzzles:**

---

## Objects Required

| Object | Type | State(s) | Key Properties | Built? |
|--------|------|---------|-----------------|--------|

---

## Design Rationale

**Why these objects?**

**Why this difficulty?**

**Why this location?**

---

## GOAP Analysis

---

## Notes & Edge Cases

---

## Status

🟡 Wanted — Design approved by Wayne; awaiting implementation.

**Owner:** Sideshow Bob  
**Next:** Flanders to build objects
```

---

## Cross-References

- **Puzzle Rating System:** `docs/design/puzzles/puzzle-rating-system.md`
- **Puzzle Design Patterns:** `docs/design/puzzles/puzzle-design-patterns.md`
- **GOAP Documentation:** `src/engine/parser/goal_planner.lua`
- **Object Lifecycle:** `docs/design/fsm-object-lifecycle.md`
- **Tool System:** `docs/design/tool-objects.md`
