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
- Joined the team 2026-03-28. Inheriting lint system from Bart (architecture), Nelson (tests), Lisa (validation), Gil (CI).
