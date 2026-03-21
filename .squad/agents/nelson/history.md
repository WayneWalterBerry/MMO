# Nelson — Tester History

## Project Context
- **Owner:** Wayne "Effe" Berry
- **Project:** MMO — Lua text adventure engine
- **Stack:** Pure Lua, REPL-based, run via `lua src/main.lua`
- **Game starts in darkness** — player must feel around, find matchbox, light match to see
- **Key systems:** FSM engine for object state, Tier 2 embedding parser, container model, sensory verbs

## Critical Path
1. feel around → discover nightstand
2. open drawer → access matchbox
3. get matchbox → open matchbox → get match
4. light match (or strike match on matchbox) → room is lit
5. look around → see the room for the first time

## Core Context

**Agent Role:** Tester responsible for playtest validation, bug discovery, and regression verification.

**Testing Summary (2026-03-19 to 2026-03-21):**
- 8 playtests completed, 94+ tests run, 83+ passed
- Critical path proven end-to-end: feel → GOAP light → spatial puzzle → multi-room → unlock
- 35 unique bugs discovered (6 CRITICAL/HIGH, 9 MEDIUM, 2 LOW, 18 MINOR/COSMETIC)
- All CRITICAL/HIGH bugs fixed; 1 MEDIUM open (BUG-035)

**Current Status:**
- Engine core: ✅ SOLID
- Parser: ✅ WORKING (Tier 2 embedding)
- Objects: 🚀 READY (new batch: candle-holder, wall-clock, enhanced candle/match)
- Progression: ⏸️ BLOCKED at Room 3 (content needed, mechanics proven)

## Archives

- `history-archive-2026-03-20T22-40Z-nelson.md` — Full archive (2026-03-19 to 2026-03-20T22:40Z): all 7 playtests, 32 bugs, regression verification, pass-by-pass findings

## Recent Updates

### Pass-009 Execution: Material Properties & Mutate Fields (2026-03-21)

**Status:** ✅ COMPLETE

| Category | Tests | Passed | Failed | Notes |
|----------|-------|--------|--------|-------|
| Material System | 8 | 6 | 2 | 2 registry mismatches |
| Mutate Fields | 10 | 9 | 1 | GOAP relight bug |
| Core Gameplay | 12 | 12 | 0 | Zero regressions |
| Timed Events | 3 | 3 | 0 | All fire correctly |
| GOAP | 4 | 3 | 1 | First light ✅; relight ❌ |
| **TOTAL** | **37** | **33** | **4** | |

**New Bugs:**
- BUG-033 (LOW): Material "oak" missing from registry (3 objects affected)
- BUG-034 (LOW): Material "velvet" missing from registry (curtains)
- BUG-035 (MEDIUM): GOAP relight picks spent match instead of fresh one

**Major Wins:**
1. `apply_mutations()` works perfectly — weight functions, keyword add/remove, category ops all verified
2. Window open/close: keywords + feel changes + categories all mutate correctly
3. Wardrobe open/close: keywords mutate correctly
4. Nightstand open drawer: keyword mutation + room description update confirmed
5. Candle burn timer fires naturally during gameplay — excellent urgency
6. Zero regressions across entire critical path

**Full Report:** test-pass/2026-03-21-pass-009.md
**Puzzle Feedback:** .squad/decisions/inbox/nelson-puzzle-feedback-pass009.md

### Pass-007 Execution: GOAP Tier 3 + UNLOCK Verb Validation (2026-03-20T21:45Z)

**Status:** ✅ COMPLETE
**Build:** 634a96e

| Category | Tests | Passed | Failed | Notes |
|----------|-------|--------|--------|-------|
| GOAP Cold Start | 11 | 4 | 3 | 4 edge cases |
| UNLOCK Verb | 7 | 7 | 0 | All clean |
| Multi-Room Nav | 10 | 10 | 0 | Perfect |
| Regression | 20 | 20 | 0 | Zero regressions |
| Edge Cases | 5 | 5 | 0 | All graceful |
| Bug Verification | 4 | 4 | 0 | All fixed |
| **TOTAL** | **57** | **50** | **3** | **4 edge cases** |

**Major Wins:**
1. **GOAP Tier 3 is TRANSFORMATIVE** — "light candle" from cold start auto-chains 5 prerequisite steps
2. **UNLOCK verb fully polished** — 3 phrasings, clean error states, dynamic descriptions
3. **4 previous bugs FIXED** (BUG-015, BUG-028, BUG-029, BUG-030)
4. **Zero regressions** across all systems

**New Minor Issues:**
- BUG-031 (MINOR): Compound "and" + GOAP mixed output
- BUG-032 (MINOR): "burn candle" doesn't trigger GOAP

**Critical Path:** feel → `light candle` (GOAP!) → push bed → pull rug → get key → open trap door → down → unlock door → open door → [Room 3 needed]
**Full Report:** test-pass/2026-03-20-pass-007.md

### Cross-Agent Updates (2026-03-20)
- **From Bart (2026-03-20T22:00Z):** 4 new objects ready for testing (candle-holder, wall-clock, enhanced candle/match) + BUG-031/BUG-032 fixes
- **From Frink:** MUD verb research — 50-100 predefined socials recommended for MVP

### GOAP Tier 3 Implementation (2026-03-20T21:15Z)
**Status:** Ready for testing. Bart delivered UNLOCK verb + auto prerequisite planning.

## Bug Track Summary (35 unique)
- CRITICAL/HIGH (6): BUG-001, BUG-004, BUG-008, BUG-017, BUG-026, BUG-030 — ALL FIXED
- MEDIUM (9): ALL FIXED except BUG-035 (GOAP spent match relight)
- LOW (2): BUG-033 (oak missing from registry), BUG-034 (velvet missing from registry)
- MINOR/COSMETIC (18): Most fixed; BUG-031, BUG-032 fixed post-pass-007

## Learnings

- GOAP is game-changing (single command replaces 7-step manual sequence)
- Systematic regression testing catches reintroductions early
- Spatial puzzles (push bed → pull rug → discover) are excellent game design
- Multi-room navigation, inventory persistence, light sources: all robust
- Container nesting handled correctly at all levels
- Wearable system is polished and extensible
- Critical path now proven end-to-end (darkness → light → spatial → multi-room → unlock)
- Content (Room 3) is the next blocker, not engine mechanics
- Material registry works for gameplay display but has data gaps (oak/velvet missing from registry, 20 objects lack material field)
- `apply_mutations()` handles all three types (direct, function, list ops) correctly — tested across candle, match, window, wardrobe, nightstand
- GOAP spent match selection is a real usability problem — first light is magic, relight is broken
- Spent matches accumulate inside matchbox after GOAP chains — root cause of relight failures
- Candle burn timer fires correctly over gameplay time, creating real urgency
- Match burn timer fires same-turn (by design) — you can't hold a lit match between commands
