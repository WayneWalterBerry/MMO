# Decision: Parser Soft Matching Phase Needs Wayne Input

**Author:** Smithers (UI Engineer)
**Date:** 2026-03-29
**Category:** Architecture / Parser

## Context

Parser audit reveals Phases 1-3 shipped (91.2% accuracy, 134/147 benchmark). The next accuracy gains require implementing soft cosine or MaxSim re-ranking — Phase 2 of the original design doc. The data layer (`word_similarity.lua`) exists but the scoring functions and hybrid integration are not built.

## Decisions Needed from Wayne (D1-D4 from design doc)

1. **D1: Hybrid scoring weights** — BM25 + soft cosine ratio (70/30 recommended)
2. **D2: Synonym expansion scope** — 2-3 vs 5 synonyms per term
3. **D3: Soft cosine vs MaxSim** — which re-ranker, or A/B test both
4. **D4: Phase 3 target** — stop at 91% or push toward 95%

## Impact

- Affects Smithers (implementation), Nelson (new test cases for soft matching), Bart (engine integration if scoring_mode changes)
- No urgency — current 91.2% is strong for beta playtesting
