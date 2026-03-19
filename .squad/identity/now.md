---
updated_at: 2026-03-19T14:54:50Z
focus_area: FSM engine shipped. Match 3-turn consumable live. Nightstand container with state swapping working. Next: candle, wardrobe, vanity FSM. Player skills implementation pending.
active_issues: []
---

# What We're Focused On

**Phase 2 Status:** FSM engine implementation complete and tested. Match and nightstand state machines live. Candle, wardrobe, vanity, window, curtains FSM conversions queued. Player skills system pending FSM completion.

## Completed (FSM Engine Batch)

- ✅ **Bart:** FSM Engine Implementation (shipped)
  - Built FSM engine (~130 lines) with lazy-loading definitions and in-place mutation
  - Match FSM: unlit → lit → burned-out (3-turn auto-burn)
  - Nightstand FSM: closed ↔ open with compartment property swapping
  - Game loop tick phase after each command
  - Verb handlers check FSM before old mutation system (backward compatible)
  - Fixed 3 search bugs (keyword substring, hand/bag priority, bag extraction)
  - All 9 test cases pass
  - **Commit:** FSM engine shipped
  - **Files:** src/engine/fsm/init.lua, src/meta/fsms/match.lua, src/meta/fsms/nightstand.lua
  
- ✅ **Comic Book Guy:** FSM Design Validated
  - Your FSM object lifecycle design implemented exactly by Bart
  - Table-driven approach with lazy loading proved clean and extensible
  - Match lifecycle (urgency teacher) and nightstand reversibility (information gate) validated in play

## In Progress

- ⏳ **Frink:** CYOA Book Series Research
  - Branching patterns documented (Time Cave, Branch-and-Bottleneck, etc.)
  - Lua table-driven FSM validates homoiconicity research
  - Awaiting Wayne scope/timeline directive for story module design
  - Expected completion: Next session

## Queued (Ready)

- **Candle FSM** — 3 states (unlit, lit, stub), 100-turn + 20-turn + terminal, drips mechanic
- **Wardrobe FSM** — hanging space, drawer storage, try-on mechanics
- **Vanity FSM** — mirror, locked drawer, cosmetics mechanics
- **Window FSM** — closed ↔ open, breakable state
- **Curtains FSM** — open ↔ closed, light-blocking mechanic

## Artifacts Generated (Batch 5)

- `.squad/orchestration-log/2026-03-19-145450-bart.md` — FSM engine shipping log
- `.squad/log/2026-03-19-145450-fsm-engine-shipped.md` — Session log with design rationale
- `.squad/decisions.md#20` — Decision 20: FSM Engine Architecture (merged from inbox)

## Cross-Agent Context

- **Bart → CBG:** FSM engine live. Your design validated. Match 3-turn and nightstand container working as specified.
- **CBG → Frink:** FSM engine validates table-driven Lua approach. Homoiconicity proved valuable for runtime introspection.
- **Frink → Bart:** CYOA research continues in parallel. State machine patterns align with branching narrative requirements.

## Immediate Next Steps

1. **Convert remaining 5 FSM objects** (candle, vanity, wardrobe, window, curtains)
   - Same pattern as match/nightstand (~20 lines each)
   - Expected: 1 session per 2-3 objects

2. **Player skills implementation** (pending FSM completion)
   - Lockpicking skill (pin + PICK LOCK verb)
   - Sewing skill (needle + thread + SEW verb)
   - Blood writing (PRICK SELF + WRITE WITH blood)

3. **Frink's scope clarification** (pending Wayne)
   - CYOA research → story module architecture
   - Timeline and integration points with game engine

4. **Advanced mechanics** (blocked until FSM foundation complete)
   - Paper dynamics (requires paper/ink FSM)
   - Knife/pin as injury tools (requires safe FSM)
   - Sewing mechanics (requires wardrobe FSM)

