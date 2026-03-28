# Decision: Split preprocess into modules

Date: $ts
Owner: Bart
Issue: Phase 3 refactor (preprocess split)

## Decision
Split `src/engine/parser/preprocess.lua` into focused submodules for data, word helpers, core parsing, phrase transforms, compound actions, movement transforms, and command splitting. Maintain the existing public API via a thin orchestrator and preserve pipeline ordering and behaviors. Remove cross-module cycles by referencing core helpers directly from phrase transforms.

## Rationale
The original preprocess file exceeded review size thresholds and was a bottleneck for parallel work. Breaking it into pure modules keeps behavior stable while improving navigability and future edits.

## Constraints
- Zero behavior changes
- Preserve preprocess public API and pipeline order
- Maintain existing test expectations
