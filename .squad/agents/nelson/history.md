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

**Testing Summary (2026-03-19 to 2026-03-23):**
- 12 playtests completed, 346+ tests run, 284+ passed
- Critical path: bedroom → cellar → storage-cellar → deep-cellar → hallway ✅ COMPLETE
- 60 unique bugs discovered (8 CRITICAL/HIGH, 20 MEDIUM+MAJOR, 4 LOW, 28 MINOR/COSMETIC)
- Phase 3 features (hit/unconsciousness/appearance/mirror): engine solid, parser gaps identified

## Learnings

### Phase 4 Walkthrough TDD Tests (2026-07-10)
- Wrote `test/integration/test-phase4-bugfixes.lua` — 5 tests for 3 Phase 4 wiring bugs (D-TESTFIRST)
- **Bug 1: Silk-bundle disambiguation** — `take silk-bundle` with 2 identical silk-bundles triggers "Which do you mean: a bundle of spider silk or a bundle of spider silk?" — impossible choice. Unit test confirms.
- **Bug 2: Silk crafting 2-ingredient recipes broken** — `craft silk-rope` (needs 2 silk-bundles) fails with "don't have enough" even when player holds both. Root cause: craft handler can't resolve 2nd ingredient from hand strings. 1-ingredient recipes (silk-bandage) work fine.
- **Bug 3: Unlock verb is a stub** — `handlers["unlock"]` just says "You can't unlock" without checking FSM transitions. The door has a proper `locked→closed` transition with `requires_tool = "brass-key"`, and the brass-key has `provides_tool = "brass-key"`, but the verb never calls `fsm.transition()`.
- Pre-existing test failures (4 files: silk-crafting, predator-prey, spider-web, combat-verbs) predate this change.
- `loader` is a static module (no `.new()`), `loader.load_source()` takes a SOURCE STRING not a file path.
- `verbs.create()` returns handlers directly — no `register_all` method.
