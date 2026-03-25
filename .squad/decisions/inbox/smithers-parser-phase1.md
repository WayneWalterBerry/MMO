# D-PARSER-BM25-PHASE1

**Author:** Smithers (Parser/UI Engineer)
**Date:** 2026-07-20
**Status:** Implemented (uncommitted — pending Wayne review)

## Decision

Replaced Jaccard similarity with BM25 (Okapi) scoring as the default Tier 2 matching algorithm. Added synonym expansion table and expanded stop word list. All changes are A/B-proven against a 60-case benchmark.

## What Changed

1. **Scoring mode flag:** `embedding_matcher.scoring_mode` defaults to `"bm25"`. Set to `"jaccard"` to revert. Old Jaccard code preserved intact as fallback.
2. **BM25 scoring:** IDF-weighted term frequency (k1=1.2, b=0.5). IDF table is precomputed at build time by `scripts/build-idf-table.py`.
3. **Synonym expansion:** 60+ verb synonyms map player words to canonical verbs in the phrase index. Expansion runs BEFORE typo correction.
4. **Stop words expanded:** 21 → 60+ common English filler words removed before matching.
5. **Dual threshold:** `THRESHOLD_BM25 = 3.00` / `THRESHOLD_JACCARD = 0.40` in `init.lua`.
6. **Typo correction tightened:** 5-char words now require distance ≤1 (was ≤2).

## Impact on Other Agents

- **Nelson (QA):** New benchmark at `test/parser/test-tier2-benchmark.lua`. Run with `lua test/parser/test-tier2-benchmark.lua bm25` (or `jaccard` for baseline). All 137 existing tests pass.
- **Gil (Web):** `bm25_data.lua` and `synonym_table.lua` are pure Lua tables — Fengari compatible. Web build needs regeneration (`web/dist/engine.lua` still has old `parser.THRESHOLD`).
- **Bart (Architecture):** No engine architecture changes. BM25/synonyms are localized to `embedding_matcher.lua` and `init.lua`.
- **Frink (Research):** Phase 1 complete. Phase 2 (soft cosine, inverted index) can build on this foundation.

## A/B Results

| Algorithm | Correct | Accuracy | False Positives | False Negatives |
|-----------|---------|----------|-----------------|-----------------|
| Jaccard (baseline) | 47/60 | 78.3% | 0 | 13 |
| BM25 + Synonyms | 60/60 | 100.0% | 0 | 0 |
| **Delta** | **+13** | **+21.7pp** | **0** | **-13** |

## Files Created/Modified

- `src/engine/parser/bm25_data.lua` (new, auto-generated)
- `src/engine/parser/synonym_table.lua` (new)
- `src/engine/parser/embedding_matcher.lua` (modified)
- `src/engine/parser/init.lua` (modified)
- `scripts/build-idf-table.py` (new)
- `test/parser/test-tier2-benchmark.lua` (new)
