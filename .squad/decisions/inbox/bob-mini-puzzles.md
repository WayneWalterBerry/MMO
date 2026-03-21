# Decision: Level 1 Mini-Puzzles (Tutorial Gap Coverage)

**Date:** 2026-07-22  
**Author:** Sideshow Bob (Puzzle Master)  
**Status:** Proposed (awaiting Wayne review)  
**Stakeholders:** Wayne Berry (owner), Flanders (builder), Moe (world builder), Bart (architect), CBG (game designer), Nelson (tester)

---

## Problem Statement

CBG's tutorial coverage analysis (`docs/design/levels/level-01-tutorial-coverage.md`) identified 5 verb gaps in Level 1. Two are Priority 1 and 2 — medium-impact gaps that should be fixed before Level 2 design finalizes:

1. **EXTINGUISH** (Priority 1) — The candle FSM supports `lit → extinguished → lit`, but no puzzle requires it. Players never learn candles can go out or be relit.
2. **DRINK** (Priority 2) — Poison teaches `TASTE = death`, but safe drinking is never demonstrated. Players may fear all liquids in Level 2+.

---

## Solution

Two mini-puzzles designed to fill these gaps with minimal effort:

### Puzzle 015: Draft Extinguish

- **Location:** Stairway between Deep Cellar and Hallway (during Puzzle 011 ascent)
- **Mechanism:** Environmental wind effect extinguishes unprotected candle during traversal
- **Teaching:** Candles can go out; RELIGHT restores them; lantern (Puzzle 010) is wind-resistant
- **Effort:** No new objects. Requires `on_traverse` exit-effect pattern (new engine concept for Bart), stairway metadata update (Moe)
- **Critical path impact:** None — occurs on critical path but doesn't block it

### Puzzle 016: Wine Drink

- **Location:** Storage Cellar, wine rack (existing wine bottles)
- **Mechanism:** Add DRINK verb transition to wine-bottle FSM; TASTE gives safe investigation
- **Teaching:** DRINK is distinct from TASTE; not all liquids are poison; context clues indicate safety
- **Effort:** One FSM transition added to wine-bottle.lua (Flanders). No room changes (Moe).
- **Critical path impact:** None — entirely optional

---

## Handoffs

| Task | Owner | Effort |
|------|-------|--------|
| `on_traverse` exit-effect engine pattern | Bart | Medium — new generic pattern, first use is wind/extinguish |
| Stairway exit metadata with wind effect | Moe | Small — property addition to existing exit |
| Wine bottle DRINK transition + TASTE sensory | Flanders | Small — one FSM transition + sensory properties |
| Oil bottle DRINK rejection message | Flanders | Tiny — one rejection message |
| Per-bottle flavor variation (optional) | Flanders | Small — instance overrides for 3 bottles |
| Testing both puzzles | Nelson | Small — enumerated test cases in each puzzle doc |

---

## Design Constraints Respected

1. **Mini-puzzles only** — 1-2 steps each, no new rooms, no critical path changes
2. **No forced tutorials** — both teach through natural discovery/consequence
3. **Grounded in real-world logic** — stairway chimney effect (physics), wine in a wine rack (cultural)
4. **No existing puzzle breakage** — Puzzle 010 (oil discovery by SMELL) unchanged; Puzzle 011 (ascent) enhanced
5. **GOAP-compatible** — relight chain auto-resolves; DRINK is terminal (no GOAP interaction needed)

---

## Files Created

- `docs/levels/01/puzzles/puzzle-015-draft-extinguish.md` — Full puzzle spec
- `docs/levels/01/puzzles/puzzle-016-wine-drink.md` — Full puzzle spec

---

## Impact

With these two puzzles, Level 1 coverage rises from ~85% to ~91% (31/35 → 33/35 verbs taught). Remaining gaps (EAT, BURN) are low priority per CBG's analysis — EAT is universally intuitive, BURN can be taught organically in Level 2.
