# Decision: Mutation Graph Linter Plan

**ID:** D-MUTATION-GRAPH-LINTER  
**Author:** Bart  
**Date:** 2026-07-28  
**Status:** 🟡 Plan Written — Awaiting Implementation  
**Affects:** Nelson (tests), Flanders (missing object files), Brockman (docs), Bart (graph lib)

## Decision

A mutation graph linter will be added as a pure-Lua test at `test/meta/test-mutation-graph.lua`. It walks all `.lua` files in `src/meta/objects/`, `src/meta/creatures/`, and `src/meta/injuries/`, extracts all mutation edges (6 mechanisms), builds a directed graph, and validates every link.

## Key Points

1. **New test directory:** `test/meta/` must be added to `test_dirs` in `test/run-tests.lua`
2. **Dynamic mutations (`dynamic = true`) are flagged but never followed** — only paper.lua currently uses this
3. **`becomes = nil` is intentional destruction** — not a broken edge, not an error
4. **Cycles are reported but not failures** — toggle patterns (matchbox ↔ matchbox-open) are valid game mechanics
5. **Template inheritance deferred** — all current instances redeclare inherited mutations; merging is a Phase 2 enhancement
6. **4 known broken edges** will generate GitHub issues assigned to Flanders: poison-gas-vent-plugged, wood-splinters ×3

## Plan Location

`plans/mutation-graph-linter-plan.md`

## Impact

- Flanders: will receive issues to create missing object files (poison-gas-vent-plugged.lua, wood-splinters.lua)
- Nelson: implements the test file
- Brockman: writes `docs/testing/mutation-graph-linting.md`
- Bart: designs graph library functions, reviews implementation
