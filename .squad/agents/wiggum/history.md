# Wiggum — Project History

## Project Context
- **Project:** MMO — Lua text adventure game inspired by Zork
- **Owner:** Wayne "Effe" Berry
- **Tech:** Pure Lua engine, zero external dependencies, Fengari browser compat
- **My role:** Linter Engineer — I own the entire meta-lint system and mutation-edge validation pipeline

## Core Context
- The meta-lint system (`scripts/meta-lint/`) has 306 rules across 20 categories, ~1,900 LOC in lint.py
- The mutation-edge extractor (`scripts/mutation-edge-check.lua`) scans 206 meta files, finds 66 edges, 5 broken, 1 dynamic
- Pipeline: Lua edge extractor → Python meta-lint, composed via wrapper scripts (ps1/sh)
- Parallel execution per D-MUTATION-LINT-PARALLEL: per-file parallel lint, sequential output display
- CI: edge check in squad-ci.yml (continue-on-error), pre-deploy gate in run-before-deploy.ps1
- Test infrastructure: pytest at test/linter/, Lua tests at test/meta/
- Key decisions: D-MUTATION-LINT-PIVOT, D-PARALLEL-EXPAND-LINT, D-LINTER-IMPL-WAVES, D-MUTATION-LINT-PARALLEL
- Linter improvement plan: plans/linter/linter-improvement-design.md (6 waves, 5 gates — partially complete)
- Known broken edges: poison-gas-vent-plugged, wood-splinters (4 sources) — issues #403, #404, #405

## Learnings

### CREATURE-003/004/007/008 Fix (GATE-4 Blocker)
- **Root cause (all 4):** `_validate_creature` was looking for `drives` and `states` at top-level `fields` instead of navigating into `behavior_t.fields`. The creature data model nests `drives` and `states` inside `behavior = { drives = {...}, states = {...} }`, but the code treated them as top-level keys.
- **CREATURE-003:** Was checking `len(behavior_t.fields.keys()) == 0` (behavior empty) instead of checking `behavior.drives` for emptiness. A creature with `drives = {}` still had `states` in behavior, so the check never fired.
- **CREATURE-004:** Was reading `fields.get("states")` (top-level FSM states, which always have idle/fleeing/dead) instead of `behavior_t.fields.get("states")` (behavior states). Removing idle from behavior.states didn't affect the top-level states.
- **CREATURE-007/008:** Was reading `fields.get("drives")` (top-level, always None since drives is nested) instead of `behavior_t.fields.get("drives")`. Drive weight validation never executed.
- **Fix:** All three code blocks now correctly navigate into `behavior_t.fields` to find `drives` and `states`. CREATURE-007/008 also falls back to top-level `fields.get("drives")` when behavior_t is None, for defensive coverage.
- **Regression safety:** 74/74 pytest pass, Lua suite unaffected (pre-existing failure in injuries/test-weapon-pipeline.lua is unrelated).
