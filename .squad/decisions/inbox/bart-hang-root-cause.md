# Bart: Hang Root Cause Analysis — Phase 4

**Date:** 2026-03-25  
**Author:** Bart (Architect)  
**Status:** Complete  
**Requested by:** Wayne "Effe" Berry

---

## Decision

**D-HANG-ROOT:** Replace depth limits with visited sets in container traversal; add recursion depth guard to preprocessor.

### What Changed

1. **`src/engine/search/traverse.lua`** — `expand_object()` and `matches_target()` now use visited sets (tracking object IDs already processed) instead of relying solely on depth limits. Depth limits retained as secondary safety belt.

2. **`src/engine/parser/preprocess.lua`** — `natural_language()` now accepts an optional `_depth` parameter. Recursive preamble stripping (line 119) passes `_depth + 1`. Returns `nil, nil` if depth > 10.

3. **`web/dist/engine.lua`** — Same changes mirrored in the web bundle.

### Root Cause Findings

Three distinct hang mechanisms identified across 9 bugs:

| Mechanism | Bugs | Root Cause | Fix |
|---|---|---|---|
| Container traversal cycles | BUG-076, 077, 080 | Recursive walk without cycle detection | **Visited sets** (implemented) |
| Preprocessing coverage gaps | BUG-086, 087, 093, 094 | Unknown verbs fell to Tier 2 → triggered search → hit Mechanism 1 | Synonym rules (already fixed, validated as correct) |
| Compound command interaction | BUG-084 | Search not drained between sub-commands | Search drain (already fixed, validated as correct) |
| GOAP prerequisite chains | BUG-090 | Backward chaining without bounds | Visited set + MAX_DEPTH (already had correct fix) |

### Key Architectural Findings

- **Embedding matcher is single-pass.** No recursion, no re-entry into parser. O(n*m) Jaccard scan. Correct as-is.
- **No verb handler re-enters the parser.** Smithers's concern about "verb handlers recursively calling the parser" was from historical code — current code has no such path.
- **Preprocessing rules are correct, not band-aids.** Synonym mapping is canonical text adventure parser design.
- **Depth limits were accidentally right.** The containment model is a 3-level tree, so depth > 3 works, but it was protecting against depth (which can't exceed 3 in correct data) rather than cycles (which would be a data bug). Visited sets are the principled fix.

### Verification

- All 15 test files pass (438 tests, 0 failures)
- All 7 previously-hanging inputs complete with meaningful output
- Full analysis document: `docs/architecture/engine/parser/hang-root-cause-analysis.md`
