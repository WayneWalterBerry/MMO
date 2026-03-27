# D-WAVE2-TDD-MOCK-CONTEXT — Combat Test Mock Requirements

**Author:** Nelson (QA)
**Date:** 2026-07-30
**Affects:** Bart, Nelson

## Decision

When writing tests that call `combat.run_combat()`, the mock context **must** include:
- `game_start_time = os.time()` — required by `presentation.get_light_level()`
- `headless = true` — suppress TUI
- `player.hands = { nil, nil }` — required by `presentation.get_all_carried_ids()`
- `registry:get(id)` method — required by light-level scanning of room contents

Without these, `run_combat` crashes in `presentation.lua` before reaching combat logic.

## Rationale

Discovered while writing WAVE-2 TDD tests. The `run_combat` entry point calls `presentation.get_light_level(context)` to determine narration mode (lit/dark). That function walks the player's hands and room contents via `registry:get()`. Test mocks that omit these fields crash before testing any combat logic.

---

# D-WAVE2-SCORE-ACTIONS-EXPORT — Bart Must Export score_actions for Testing

**Author:** Nelson (QA)
**Date:** 2026-07-30
**Affects:** Bart

## Decision

`creatures/init.lua` must export `score_actions`, `execute_action`, `has_prey_in_room`, and `select_prey_target` for WAVE-2 GATE-2 tests to pass. Currently these are all local functions or stubs.

**Suggested approach:** Either expose via `M.score_actions` etc. directly, or add a `M._test = { score_actions = score_actions, ... }` accessor for test-only access.

26 of 40 WAVE-2 TDD tests depend on these exports.
