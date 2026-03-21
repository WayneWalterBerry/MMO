# Puzzle Difficulty Rating System

**Version:** 1.0  
**Author:** Sideshow Bob (Puzzle Master)  
**Last Updated:** 2026-03-20

---

## Overview

This document defines how MMO puzzles are rated for difficulty. The system accounts for **cognitive complexity** (how many steps, how obscure the clues), **tool sophistication** (whether GOAP auto-resolves steps or requires player planning), **failure reversibility** (can the player recover from mistakes), and **discovery model** (exploration vs. lateral thinking required).

The rating system is **independent of** the Zarfian Cruelty Scale (which measures forgiveness/unwinnable states). A puzzle can be intellectually easy but cruel (instant unwinnable), or intellectually hard but merciful (always recoverable).

---

## Difficulty Scale: 1–5 Stars

### ⭐ Level 1: Trivial (Tutorial / Teaching)

**Definition:** Puzzle teaches a single game mechanic with no room for failure.

**Characteristics:**
- **Steps:** 1–2 discrete actions
- **Tool chain:** Single tool or no tools
- **Clues:** Explicit or obvious in room description
- **GOAP involvement:** None or full auto-resolution
- **Failure:** Impossible or automatically recoverable
- **Discovery mode:** Linear exploration (follow signs)
- **Typical time to solve:** < 1 minute

**Examples:**
- "Take the apple from the table" — teaches TAKE verb
- "Open the door and walk north" — teaches room navigation
- "Read the sign to learn your objective" — teaches READ verb

**Design use:** First 10 minutes of game. Player onboarding.

---

### ⭐⭐ Level 2: Introductory (Basic Tool Use)

**Definition:** Single tool acquisition chain or one simple compound action. All objects are discoverable by exploration alone.

**Characteristics:**
- **Steps:** 3–5 discrete actions
- **Tool chain:** 1–2 tools in sequence (e.g., find key → unlock chest → take item)
- **Clues:** Sensory hints present (LOOK, FEEL, LISTEN) or contextual (matches near candle)
- **GOAP involvement:** Partial—player may need 1 GOAP step, or can solve without it
- **Failure:** Soft failure only (resources deplete, but daytime alternative exists)
- **Discovery mode:** Exploration + light context clues (narratively integrated)
- **Typical time to solve:** 2–5 minutes for first-time player

**Examples:**
- **Puzzle 001: Light the Room** — FEEL for nightstand → open drawer → take matchbox → take match → strike match → light candle
- "Fill a cup from a tap, drink water to cure thirst"
- "Take key from shelf, use key to open door"

**Design use:** Teach core systems (containment, compound tools, sensory verbs, GOAP). First puzzle should be Level 2.

---

### ⭐⭐⭐ Level 3: Intermediate (Multi-Step Planning)

**Definition:** Puzzle requires planning a chain of actions across multiple rooms or objects. Player must synthesize multiple clues or discover a non-obvious object combination.

**Characteristics:**
- **Steps:** 6–10 discrete actions
- **Tool chain:** 2–4 tools in sequence; one or more compound steps
- **Clues:** Scattered across multiple locations or sensory modes; one clue may be ambiguous
- **GOAP involvement:** Moderate—GOAP auto-resolves 1–2 intermediate steps, but player must plan the main chain
- **Failure:** Soft or moderate—player can waste resources or lock themselves into a wrong branch, but can recover via alternate path
- **Discovery mode:** Exploration + puzzle logic (player must reason "I need X to get Y")
- **Typical time to solve:** 5–15 minutes for experienced player; 15–30 for first-time

**Examples:**
- "Acquire poison from kitchen, deliver to victim's drink, retrieve antidote from safe" — multi-room chain
- "Combine three ingredients to craft a tool, then use tool to solve new problem"
- "Unlock multiple containers in sequence to reach final item"

**Design use:** Post-tutorial progression. Tests systematic planning.

---

### ⭐⭐⭐⭐ Level 4: Advanced (Lateral Thinking / Hidden Mechanics)

**Definition:** Puzzle requires discovering a non-obvious mechanic, creative object combination, or unconventional use of game systems. Or: multi-step chain with irreversible consequences for wrong choices.

**Characteristics:**
- **Steps:** 8–15 discrete actions
- **Tool chain:** 3–5 tools; multiple compound actions; potential for creative reordering
- **Clues:** Subtle or deliberately misleading; may require re-examining objects under different conditions
- **GOAP involvement:** Limited—GOAP may fail if player hasn't discovered a prerequisite; player must often manually execute
- **Failure:** Moderate or harsh—wrong choice locks player into dead-end (though alternate solution usually exists)
- **Discovery mode:** Lateral thinking required; object uses are not obvious; may require "aha moment"
- **Typical time to solve:** 20–60 minutes for experienced player; may require walkthrough for first-timers

**Examples:**
- "Realize that object A is actually a tool for problem B (not its obvious use)"
- "Combine two unrelated objects in an unconventional way"
- "Use environmental feature (e.g., shadow, sound reflection) as a puzzle element"
- "Discover that a 'consumed' resource regenerates under specific conditions"

**Design use:** Mid-to-late game. Rewards system mastery and creativity.

---

### ⭐⭐⭐⭐⭐ Level 5: Expert (Multi-Solution / Consequence Management)

**Definition:** Puzzle with multiple valid solutions, deep consequence chains, or requires mastery of multiple game systems simultaneously. High skill ceiling.

**Characteristics:**
- **Steps:** 12–25+ discrete actions (depending on solution path)
- **Tool chain:** 4–7 tools; elaborate compound chains; solutions may branch
- **Clues:** Minimal; much of puzzle is non-obvious; player must make inferences
- **GOAP involvement:** Very limited—GOAP provides scaffolding, but puzzle core is manual
- **Failure:** Consequences carry forward; wrong choice may consume resources needed for alternate path, but puzzle remains solvable
- **Discovery mode:** Extensive lateral thinking; may involve puzzle-specific systems (e.g., alchemy, code-breaking, ritual sequences)
- **Typical time to solve:** 45–120+ minutes for experienced player; expertise-dependent
- **Multiple solutions:** 2–4 distinct valid paths to success

**Examples:**
- "Obtain objective via one of three methods (stealth, negotiation, or brute force); each uses different resources and unlocks different post-puzzle state"
- "Solve a deep puzzle chain where resource decisions made in step 2 affect availability of tools in step 8"
- "Master a micro-system (e.g., alchemy reaction chains) to solve a cascading problem"

**Design use:** End-game or optional challenge puzzles. Tests true mastery.

---

## How GOAP Auto-Resolution Affects Difficulty

GOAP (backward-chaining goal planner) can auto-resolve tool-acquisition steps. When considering difficulty:

### GOAP Reduces Perceived Difficulty By:
- **Automating prerequisites** — Player types "light candle"; GOAP finds match, strikes it, then lights candle
- **Reducing manual steps** — Player doesn't need to manually execute the chain
- **Hiding complexity** — Novice player sees a simple outcome; expert player knows the system that powered it

### GOAP Does NOT Reduce Difficulty By:
- **Solving the core puzzle** — If the puzzle's core insight is "use object A on problem B," GOAP doesn't provide that insight
- **Finding unique tools** — GOAP finds *common* tool candidates; if the puzzle requires *this specific tool*, GOAP must find it or the puzzle stalls
- **Solving non-linear problems** — If three separate sub-puzzles must be solved in parallel, GOAP can resolve prerequisites for each, but doesn't orchestrate the solve order

### Classification Rule:
- **Level 1–2:** GOAP often fully resolves; puzzle feels effortless
- **Level 3:** GOAP resolves intermediate steps; player focuses on main chain
- **Level 4–5:** GOAP scaffolds only; player executes core logic manually

---

## Rating Checklist

When rating a new puzzle, assess:

| Factor | Level 1 | Level 2 | Level 3 | Level 4 | Level 5 |
|--------|---------|---------|---------|---------|---------|
| **Step count** | 1–2 | 3–5 | 6–10 | 8–15 | 12–25+ |
| **Tool chain depth** | 0–1 | 1–2 | 2–4 | 3–5 | 4–7 |
| **Clue obviousness** | Explicit | Contextual | Scattered | Subtle | Minimal |
| **GOAP coverage** | Full | Partial | Moderate | Light | Minimal |
| **Failure reversibility** | Impossible | Soft | Soft/Moderate | Moderate/Harsh | Managed |
| **Requires lateral thinking?** | No | No | Slightly | Yes | Extensive |

---

## Worked Example: Puzzle 001 — Light the Room

### Puzzle Summary
Player wakes in darkness. Must find matchbox, strike match, light candle.

**Solution steps:**
1. FEEL (discover nightstand)
2. FEEL nightstand (discover drawer)
3. OPEN nightstand (drawer)
4. FEEL inside drawer (discover matchbox)
5. TAKE matchbox
6. OPEN matchbox
7. TAKE match
8. STRIKE match ON matchbox (compound action)
9. LIGHT candle WITH match

### Rating Analysis

| Factor | Analysis | Score |
|--------|----------|-------|
| **Step count** | 9 actions, but GOAP can collapse 5–7 into 1 | 3–5 range |
| **Tool chain depth** | Single chain: nightstand → matchbox → match → strike → light | 2 (simple sequence) |
| **Clue obviousness** | Nightstand contextually next to bed (narrative sense); matches contextually near candle; FEEL works in darkness (taught immediately) | Contextual |
| **GOAP coverage** | GOAP can auto-resolve matchbox acquisition + striking IF player first discovers match location manually. Player might type "light candle" and GOAP finds match, or player might manually execute all steps. | Partial |
| **Failure reversibility** | Soft only: player can waste 7 matches, then wait for dawn (3–4 min wall-clock time). Or restart. | Soft |
| **Lateral thinking required?** | No. Solution is linear and encouraged by narrative ("you wake in darkness, you need light"). | No |
| **Actual time to solve** | 2–5 min (first time); < 1 min (experienced) | |

### Final Rating: ⭐⭐ Level 2 (Introductory)

**Justification:** This is the opening puzzle. It teaches core systems (containment, compound tools, sensory verbs, GOAP scaffolding) with a linear solution path and no real failure penalty. The puzzle is designed to build confidence before introducing Level 3 complexity. Despite 9 actions, the conceptual challenge is minimal—GOAP can collapse it, and the narrative guides the player.

---

## Difficulty Progression Strategy

**Recommended sequence:**
- **Tutorial (first 10 min):** Level 1 only
- **Early game (first hour):** Level 2 + one Level 3 toward end
- **Mid game:** Level 2–3 mix, introducing Level 4 patterns
- **Late game:** Level 3–4 primary, Level 5 optional
- **End game / challenges:** Level 4–5

---

## Notes

- Difficulty ratings are **relative to the game**. A Level 3 MMO puzzle might be a Level 2 in a hardcore roguelike.
- Playtesting may reveal that a designed Level 3 plays like a Level 2 or 4; ratings can shift based on actual player data.
- Multiple solutions reduce perceived difficulty; players who find an easy alternate path rate a Level 4 as Level 3.
- Zarfian Cruelty is orthogonal; always document both: "Level 3 difficulty, Polite cruelty rating" (recoverable) vs. "Level 3 difficulty, Nasty cruelty rating" (one wrong choice and you're locked out).
