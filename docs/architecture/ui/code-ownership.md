# UI/Parser Code Ownership Map

**Author:** Smithers (UI Engineer)  
**Date:** 2026-03-22 (updated 2026-03-23 after separation refactor)  
**Based on:** Deep code review + UI/Parser/Engine separation refactor

---

## New Modules Created (Smithers Owns Exclusively)

| File | Purpose | Key Functions | Notes |
|------|---------|---------------|-------|
| `src/engine/parser/preprocess.lua` (~190 lines) | Input preprocessing pipeline: NLP normalization and basic parsing | `preprocess.natural_language(input)` → verb, noun; `preprocess.parse(input)` → verb, noun | Extracted from loop/init.lua. Pure functions, no side effects. 30+ NLP patterns. Smithers can add patterns without touching the game loop |
| `src/engine/ui/presentation.lua` (~160 lines) | Presentation helpers: time formatting, light level, vision checks | `presentation.get_game_time(ctx)`, `format_time(h,m)`, `time_of_day_desc(h)`, `get_light_level(ctx)`, `has_some_light(ctx)`, `vision_blocked_by_worn(ctx)`, `get_all_carried_ids(ctx)` | Extracted from verbs/init.lua. Reads game state to produce display-ready values. No mutations. Single source of truth for time constants |
| `src/engine/ui/status.lua` (~45 lines) | Status bar updater for split-screen UI | `status.create_updater()` → function(ctx) | Extracted from main.lua. Pure formatting |

---

## Smithers Owns (UI Engineer)

| File | Purpose | Notes |
|------|---------|-------|
| `src/engine/parser/init.lua` (69 lines) | Tier 2 parser wrapper | THRESHOLD=0.40. Diagnostic output to stderr |
| `src/engine/parser/preprocess.lua` (~190 lines) | **NEW** — NLP normalization + verb/noun parsing | Extracted from loop/init.lua. Add NLP patterns here |
| `src/engine/parser/embedding_matcher.lua` (241 lines) | Tier 2 Jaccard+bonus matching engine | D-BUG018 implemented |
| `src/engine/parser/json.lua` (119 lines) | JSON decoder for embedding-index.json | Minimal but correct |
| `src/engine/parser/goal_planner.lua` (442 lines) | Tier 3 GOAP backward-chaining planner | MAX_DEPTH=5 |
| `src/engine/display.lua` (85 lines) | Word-wrap + UI routing | WIDTH=78 default |
| `src/engine/ui/init.lua` (370 lines) | Split-screen ANSI terminal UI | 500-line scrollback |
| `src/engine/ui/presentation.lua` (~160 lines) | **NEW** — Time, light, vision helpers | Single source of truth for time constants |
| `src/engine/ui/status.lua` (~45 lines) | **NEW** — Status bar formatting | Extracted from main.lua |
| `src/assets/parser/embedding-index.json` | Phrase dictionary | ~50 phrases |

---

## Shared (Smithers + Bart)

| File | Smithers's Concern | Bart's Concern | Boundary |
|------|-------------------|----------------|----------|
| **`src/main.lua`** (~440 lines) | Welcome banner, `display.install()`, `ui.init()`, `parser_mod.init()`, CLI flags, `ui_status.create_updater()` call | Loader pipeline, registry, containment, player state, context, FSM init, `on_tick()` | Smithers: UI setup + status hookup. Bart: load/build + tick |
| **`src/engine/loop/init.lua`** (~240 lines) | REPL I/O, parse pipeline via `preprocess` module, Tier 1→2→3 dispatch, quit, error messages | FSM tick phase, timed events, `on_tick` callback, game-over check | Parse pipeline and tick phase are cleanly separated sections |
| **`src/engine/verbs/init.lua`** (~4500 lines) | Text presentation, help, sensory verb output, error messages, pronoun resolution, presentation helpers via `require("engine.ui.presentation")` | All mutations, FSM, containment, tools, crafting, movement, sleep, clock | Presentation helpers extracted. Verb handlers still mix presentation + logic inline (see Remaining Tangling) |

---

## Bart Owns (Architect)

| File | Purpose |
|------|---------|
| `src/engine/fsm/init.lua` (425 lines) | Table-driven FSM engine |
| `src/engine/containment/init.lua` (146 lines) | 4-layer containment validator |
| `src/engine/loader/init.lua` (160 lines) | Sandboxed Lua loader |
| `src/engine/materials/init.lua` (254 lines) | Material property registry |
| `src/engine/mutation/init.lua` (57 lines) | Hot-swap rewrite engine |
| `src/engine/registry/init.lua` (129 lines) | Object store |

---

## Dependency Graph (Post-Refactor)

```
main.lua
  ├─ engine/ui/status.lua (Smithers) ─→ engine/ui/presentation.lua (Smithers)
  ├─ engine/ui/init.lua (Smithers)
  ├─ engine/display.lua (Smithers)
  ├─ engine/parser/init.lua (Smithers)
  ├─ engine/loop/init.lua (Shared)
  │    └─ engine/parser/preprocess.lua (Smithers)
  │    └─ engine/parser/goal_planner.lua (Smithers)
  ├─ engine/verbs/init.lua (Shared)
  │    └─ engine/ui/presentation.lua (Smithers)
  │    └─ engine/fsm/init.lua (Bart)
  ├─ engine/registry/init.lua (Bart)
  ├─ engine/loader/init.lua (Bart)
  ├─ engine/mutation/init.lua (Bart)
  ├─ engine/containment/init.lua (Bart)
  └─ engine/fsm/init.lua (Bart)
```

---

## What Was Cleaned Up

### DRY Violations Fixed
1. **Time constants** — `GAME_SECONDS_PER_REAL_SECOND` and `GAME_START_HOUR` duplicated in verbs + main. Now single source in `ui/presentation.lua`
2. **`get_all_carried_ids()`** — Duplicated utility now shared from `ui/presentation.lua`
3. **`get_game_time()`** — Duplicated calculation (verbs had function, main had inline copy). Now in `presentation.lua`
4. **`format_time()`** — Identical formatting in verbs + status bar. Now shared

### Dead Code Removed
- **`cmd_look` in loop/init.lua** — Always overridden by `handlers["look"]` in verbs. Removed (58 lines)

### Bugs Fixed
- **Double `require("engine.parser")` in loop** — Re-required inside loop body. Now uses module-level import

---

## Remaining Tangling (Future Work)

### verbs/init.lua (~4500 lines) — The Elephant
Verb handlers still mix presentation and game logic inline. Separating would require:
1. A verb-result protocol (handlers return structured data)
2. A presentation layer that formats results
3. ~80 handler functions updated

**Risk:** Too high for single refactor. Needs incremental approach with test coverage.

### on_tick in main.lua
Contains both game logic (decrementing counters) and print statements. Could return messages instead of printing directly.

### Pronoun Resolution
`find_visible()` wrapper handles both object lookup (Bart) and pronoun tracking (Smithers). Could extract pronoun resolution.

---

## Parser Pipeline Flow (Post-Refactor)

```
Player Input
  ├─ loop/init.lua: Read input, trim, strip "?"
  ├─ loop/init.lua: Split compound commands on " and "
  │     └─ GOAP optimization for compound commands
  ├─ parser/preprocess.lua: natural_language() → verb, noun (30+ patterns)
  ├─ parser/preprocess.lua: parse() → verb, noun (word split)
  ├─ loop/init.lua: Prepositional strip ("light X with Y" → "light X")
  ├─ loop/init.lua: Tier 3 GOAP prerequisites
  ├─ loop/init.lua: Tier 1 exact dispatch
  ├─ parser/init.lua: Tier 2 fallback (Jaccard matching)
  └─ loop/init.lua: Error message
```
