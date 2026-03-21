# Decision: Puzzle Rating System & Classification Standard

**Date:** 2026-03-20  
**Author:** Sideshow Bob (Puzzle Master)  
**Status:** Proposed (awaiting Wayne review)  
**Stakeholders:** Wayne Berry (owner), Flanders (builder), Nelson (tester), CBG (game designer)

---

## Problem Statement

MMO needed a standardized way to:
1. Rate puzzle difficulty for player progression planning
2. Track puzzle lifecycle (concept → design → built → tested)
3. Document puzzle design patterns for consistency
4. Help designers understand how GOAP interacts with puzzle complexity

Without this system, puzzle docs were inconsistent, and there was no shared vocabulary for "how hard is this puzzle?"

---

## Solution

Implemented three new design documents:

### 1. **Puzzle Rating System** (`docs/design/puzzles/puzzle-rating-system.md`)
- **5-star scale:** 1 = trivial tutorial, 5 = expert lateral thinking
- **Cruelty orthogonal to difficulty:** Includes Zarfian Cruelty analysis (Merciful, Polite, Tough, Nasty, Cruel)
- **GOAP analysis:** Documents how auto-resolution affects perceived difficulty
- **Worked example:** Puzzle 001 rated as ⭐⭐ Level 2 Polite

### 2. **Puzzle Classification Guide** (`docs/design/puzzles/puzzle-classification-guide.md`)
- **Status lifecycle:** 🔴 Theorized → 🟡 Wanted → 🟢 In Game
- **Approval chain:** Wayne (Theorized→Wanted), Flanders (build), Nelson (test)
- **Standardized template:** All puzzle docs must include required fields (name, classification, difficulty, objects, prerequisites, GOAP compatibility, failure modes, etc.)
- **Numbering:** `{SEQUENCE}-{SLUG}` format (e.g., 001-light-the-room)

### 3. **Puzzle Design Patterns** (`docs/design/puzzles/puzzle-design-patterns.md`)
- **9 core patterns:** Lock-and-Key, Environmental, Combination, Sequence, Discovery, Transformation, Lateral Thinking, Deduction, Moral Choice
- **Variants per pattern:** Each pattern has 4–6 sub-types (e.g., Simple Lock, Nested Locks, Compound Lock, Magical Lock)
- **Difficulty guidelines:** Which patterns fit which levels (Level 1 avoids Lateral Thinking; Level 5 combines patterns)
- **Research-backed:** Sourced from Zarfian Cruelty Scale, escape room design, The Witness, Baba Is You, Infocom classics

---

## Key Decisions

1. **Difficulty and Cruelty are orthogonal:**
   - A puzzle can be hard but fair (Level 4, Polite)
   - Or easy but punishing (Level 2, Cruel)
   - Both dimensions must be rated independently

2. **GOAP is a documented puzzle property:**
   - Not every puzzle is GOAP-compatible
   - GOAP can reduce perceived difficulty by auto-resolving prerequisites
   - But GOAP should never auto-solve the puzzle's core "aha!" moment

3. **Puzzle lifecycle has formal approval gates:**
   - Wayne approves creative design (Theorized→Wanted)
   - Flanders implements objects (Wanted→In Game, pending test)
   - Nelson verifies solvability (In Game locked in)
   - Status field in puzzle doc is source of truth

4. **Patterns are descriptive, not prescriptive:**
   - 9 patterns catalog how puzzles typically work
   - Not required to use a pattern, but helpful reference
   - Patterns can combine (Lock-and-Key + Transformation + Sequence)

5. **Template standardization:**
   - All puzzle docs follow the same structure
   - Required fields: name, status, difficulty, cruelty, objects required, prerequisite chain, GOAP analysis, failure modes, patterns used
   - Enables consistent documentation and easier cross-referencing

---

## Impact

### Enablers
- Designers now have a shared vocabulary for puzzle difficulty
- Wayne can plan progression (early game = Level 2, late game = Level 4–5)
- Nelson has explicit criteria for testing (must be solvable, failure modes documented)
- Flanders understands which objects are prerequisites (from puzzle template)

### Constraints
- All future puzzles must follow the template (one .md per puzzle in `docs/puzzles/`)
- Puzzles cannot move from 🟡→🟢 without Nelson's sign-off
- Puzzle naming must follow `{SEQUENCE}-{SLUG}` format

### Risk Mitigation
- Template is flexible enough to handle unexpected puzzle types
- Rating is based on playtesting feedback; can adjust after data
- Patterns are guidelines, not rules—designers have creative freedom
- GOAP analysis is documented but doesn't require changes to engine

---

## Implementation

**Rollout:**
1. Bob to present rating system and patterns to Wayne for buy-in
2. All new puzzles (002, 003, 004, ...) must use new template and rating system
3. Existing puzzles (001) will be retrofitted with new template
4. Update squad charter to reflect puzzle classification as standard

**Rollback:**
- If rating system proves too rigid or doesn't match playtesting data, revert template and simplify to binary "difficulty estimation" + "cruelty assessment"

---

## References

- **Research sources:** Zarfian Cruelty Scale, escape room industry standards, The Witness design philosophy, Baba Is You puzzle mechanics, Infocom games (Zork, Enchanter series)
- **Related docs:** `docs/design/tool-objects.md`, `docs/design/fsm-object-lifecycle.md`, `docs/design/game-design-foundations.md`
- **Implementation:** Puzzle 001 retrofitted as worked example

---

## Approval

- [ ] Wayne Berry — Approves rating system and lifecycle
- [ ] CBG — Confirms design philosophy alignment
- [ ] Flanders — Confirms object spec clarity
- [ ] Nelson — Confirms testing criteria are clear

