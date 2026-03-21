# Decision: Level 1 Tutorial Verb/Pattern Coverage Audit

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-07-22  
**Status:** Proposed  
**Affects:** Level 1 puzzle design, Level 2 onboarding  
**Document:** `docs/design/levels/level-01-tutorial-coverage.md`

---

## Context

Level 1 ("The Awakening") serves as the game's tutorial. A comprehensive audit was performed comparing the engine's full interaction vocabulary (35 primary verbs, 28 aliases, 24 interaction patterns) against what Level 1's 14 puzzles actually teach through gameplay.

## Findings

Level 1 teaches **31 of 35 verbs** and **21 of 24 interaction patterns** through puzzle necessity — no exposition, no tutorials, pure discovery. This is excellent.

**Four verbs are never required:** EXTINGUISH, EAT, DRINK, BURN.  
**Three patterns are untaught:** extinguish/relight cycle, eat/drink consumption, fire-as-destruction.

## Decisions Proposed

### D-TUTORIAL-1: Add EXTINGUISH/RELIGHT moment to Level 1
**Priority:** Must-do before Level 2 finalization.  
**Recommendation:** Add a draft in the Deep Cellar stairway (Puzzle 011) that blows out the player's candle, forcing RELIGHT. Or modify Puzzle 012 so the altar ritual requires an extinguished-then-relit candle.  
**Rationale:** The candle FSM supports this fully. If Level 2 has wind or stealth mechanics, the player needs to know SNUFF and RELIGHT exist.

### D-TUTORIAL-2: Add safe DRINK interaction to Level 1
**Priority:** Should-do.  
**Recommendation:** Make one wine bottle in the Storage Cellar (Puzzle 010) safely drinkable ("sour but harmless"), or add a drinkable rain barrel/well-bucket in the Courtyard (Puzzle 013).  
**Rationale:** TASTE teaches "danger" via the poison bottle. Without a safe DRINK example, players may fear all liquid interaction in Level 2.

### D-TUTORIAL-3: No action needed for EAT, BURN, or SET
**Priority:** Won't-do (for now).  
**Rationale:** EAT is universally intuitive. BURN redirects to LIGHT in the engine. SET is Level 2 content (wall-clock). These can be taught organically when first encountered.

## For Review By

- **Sideshow Bob** — puzzle design (implements the tweaks)
- **Flanders** — object design (may need new object states)
- **Wayne** — sign-off on tutorial philosophy
