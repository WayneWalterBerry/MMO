# Frink Recommendations: Puzzle Design Research

**Date:** 2026-07-22  
**Author:** Frink (Researcher)  
**Research:** `resources/research/puzzles/puzzle-design-research.md`  
**Audience:** Bob (Puzzle Master), Bart (Architect), Comic Book Guy (Designer)

---

## R-PUZ-1: GOAP-Aware Puzzle Design Policy (HIGH)

**Recommendation:** Establish that simple inventory chains (find key → unlock door) are NOT valid puzzles in our engine. GOAP auto-resolves them. All puzzles must include at least one **knowledge gate** — something the player must *understand*, not just *possess*.

**Rationale:** Zarfian Cruelty Scale + GOAP analysis shows our engine naturally operates at Merciful/Polite level. Traditional IF inventory puzzles become trivial. Knowledge gates are our primary puzzle mechanism.

**Impact:** Bob's puzzle designs must all pass the "GOAP test": would Tier 3 auto-resolve this? If yes, it's not a puzzle.

---

## R-PUZ-2: Material-Physics Puzzles as Showcase (HIGH)

**Recommendation:** Prioritize material-physics puzzles (threshold-based, chain-reaction, substitution) as our differentiating puzzle type. The fire propagation chain puzzle (R-MAT-4) should be the first implementation to validate the entire material+puzzle pipeline.

**Rationale:** No other text IF engine has numeric material properties. This is our unique competitive advantage for puzzle design. Fire propagation exercises flammability, ignition_point, melting_point, and conductivity in one puzzle chain.

**Impact:** Flanders should prioritize material property objects. Bob should design the first fire-chain puzzle. Bart should ensure threshold tick supports puzzle-relevant state transitions.

---

## R-PUZ-3: Sensory Puzzle Framework (HIGH)

**Recommendation:** Design at least one "dark room" puzzle per chapter/area that is solved entirely through non-visual senses (FEEL, LISTEN, SMELL, TASTE). This is our zero-competition feature.

**Rationale:** Our sensory system (D-37 to D-41) enables puzzle types no other text game can offer. Academic research confirms multi-sensory engagement enhances both learning and memory. Dark-room puzzles force players to engage all senses.

**Impact:** Bob needs sensory puzzle templates. Moe needs rooms with rich non-visual sensory descriptions. Object authors need `on_feel`, `on_smell`, `on_listen`, `on_taste` callbacks on all puzzle-relevant objects.

---

## R-PUZ-4: 4-Tier Hint System Design (MEDIUM)

**Recommendation:** Implement a progressive hint system: Tier 0 (sensory feedback, always available) → Tier 1 (THINK/HINT command, contextual nudge) → Tier 2 (extended stuckness, more explicit) → Tier 3 (near-solution on repeated request).

**Rationale:** Academic consensus: tiered, player-requested hints are best practice. Our sensory system provides natural Tier 0 hints. GOAP already handles mechanical prerequisites. Remaining puzzles need knowledge-gate hints.

**Impact:** Requires `on_hint` callback on puzzle objects (Bart), hint escalation counter in game loop (Bart), hint content per puzzle (Bob).

---

## R-PUZ-5: Puzzle Complexity Limit — 3-5 Key Elements (MEDIUM)

**Recommendation:** Enforce a maximum of 5 key elements per puzzle. Cognitive science shows insight-based solving degrades above this threshold. Complex puzzles should be decomposed into chained sub-puzzles of 3-5 elements each.

**Rationale:** Tufts University research on insight cognition + working memory limitations. Escape room industry confirms: multi-step chains of simple puzzles outperform single complex puzzles.

**Impact:** Bob's puzzle designs should explicitly list key elements and stay within the 3-5 limit.

---

## R-PUZ-6: No False Affordances Enforcement (INFORMATIONAL)

**Recommendation:** Reaffirm D-BUG022 (No False Affordances) for all puzzle objects. Every interactive-looking object must either serve a puzzle purpose or clearly signal it is decorative. Red herrings only when thematically motivated and immediately recognizable.

**Rationale:** Escape room research + Emily Short's principles confirm: red herrings that waste player time destroy trust. Our GOAP system makes false affordances worse because the planner might try to use non-puzzle objects.

**Impact:** Object review checklist for Moe/Flanders.

---

*Filed by Frink, 2026-07-22*
