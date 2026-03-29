# Parser Improvements — Board

**Owner:** ⚛️ Smithers (UI Engineer)
**Last Updated:** 2026-03-29
**Overall Status:** 🟢 Phases 1-3 SHIPPED — 91.2% accuracy (134/147 benchmark cases)

---

## Next Steps

Prioritized by impact. These are the remaining unimplemented items from the design doc and the 13 remaining benchmark failures.

| # | Task | Est. Impact | Effort | Status | Notes |
|---|------|-------------|--------|--------|-------|
| 1 | **MaxSim re-ranker** | +3-5% accuracy | 2-3 days | 🟢 Unblocked (D3) | Implement `maxsim_score()` consuming `word_similarity.lua`. Two-stage: BM25 retrieves top-50, MaxSim re-ranks. |
| 2 | **Noun synonym expansion** | +1-2% accuracy | 2 days | 🟢 Unblocked (D2) | Add 2-3 synonyms per noun to `synonym_table.lua`. Conservative scope per D2. |
| 3 | **Hybrid scoring integration** | +1-2% accuracy | 1 day | 🟢 Unblocked (D1) | Wire MaxSim as Stage 2 re-ranker with 70/30 BM25-heavy blend. |
| 4 | **Adaptive weighting (BM25F)** | +1-2% accuracy | 3-5 days | ⏳ Not Started | Separate verb/noun field weights in BM25 scoring. Design doc §4.8. |
| 5 | **"match match" edge case** (P6) | +1 case | 1 day | ⏳ Not Started | Duplicate-word input resolves incorrectly. Benchmark case C-97. |
| 6 | **Fengari performance profiling** | 0% accuracy | 2 days | ⏳ Not Started | Profile MaxSim in browser. Soft cosine fallback documented if needed. |

**Decisions Resolved (Frink research, 2026-03-29):**
- D1: Hybrid scoring weights → **70/30 BM25-heavy, two-stage pipeline** (BM25 retrieves top-50, MaxSim re-ranks). Short queries favor lexical precision.
- D2: Synonym expansion scope → **2-3 per noun (conservative)**. Lu et al. research; no synonym-caused failures in remaining 13; drift risk above 3.
- D3: Soft cosine vs MaxSim → **MaxSim first, soft cosine as fallback**. Simpler, debuggable, noise-robust, equivalent accuracy at 2-4 token scale.
- D4: Accuracy target → **93% (~137/147), then beta + reassess**. 3 more cases achievable; diminishing returns above 93%; real player data > benchmarks.

See `.squad/decisions/inbox/frink-parser-scoring.md` for full reasoning.

---

## Accuracy Trajectory

| Milestone | Target | Actual | Benchmark |
|-----------|--------|--------|-----------|
| Baseline (pre-improvement) | — | 68% | 41/60 |
| Phase 1 (BM25 + IDF + inverted index) | 75% | ~78% | 60-case suite |
| Phase 2 (synonyms + typo correction) | 80% | ~84% | 60-case suite |
| Phase 3 (context boost + state tiebreaker) | 85% | ~89% | 60-case suite |
| Issue #242-244 fixes | — | 89% | 147-case expanded |
| Typo tightening | — | **91.2%** | **134/147** |
| Soft cosine / MaxSim (Phase 2 design) | **93%** (D4) | ⏳ | ~137/147 target |

**Remaining failures:** 13/147 cases across 6 categories (see design doc §Remaining Failures).

---

## What Already Exists

### Parser Pipeline (6 Tiers)

| Tier | Component | File | Status | Evidence |
|------|-----------|------|--------|----------|
| **Tier 1** | Preprocessing pipeline | `src/engine/parser/preprocess.lua` | ✅ Complete | 11-stage pipeline: normalize, strip filler, idioms, questions, look patterns, search phrases, compound actions, movement, possessives |
| **Tier 1** | Question transforms | `src/engine/parser/questions.lua` | ✅ Complete | 81 patterns with priority sorting (10-95) |
| **Tier 1** | Idiom patterns | `src/engine/parser/idioms.lua` | ✅ Complete | 90 idiom patterns across 10 categories |
| **Tier 2** | Embedding matcher (BM25) | `src/engine/parser/embedding_matcher.lua` | ✅ Complete | 528 LOC, BM25 scoring with k1=1.2, b=0.5 |
| **Tier 2** | IDF table | `src/engine/parser/bm25_data.lua` | ✅ Complete | 244 unique tokens, 11,131 phrases, avg doc length 3.67 |
| **Tier 2** | Inverted index | `src/engine/parser/embedding_matcher.lua` | ✅ Complete | Token→phrase candidate retrieval (lines 387-420) |
| **Tier 2** | Synonym table | `src/engine/parser/synonym_table.lua` | ✅ Complete | Verb synonyms (60+ mappings), `expand_tokens()` |
| **Tier 2** | Typo correction | `src/engine/parser/embedding_matcher.lua` | ✅ Complete | Levenshtein with tightened thresholds (4→d1, 5→d1, 6+→d2) |
| **Tier 2** | Word similarity matrix | `src/engine/parser/word_similarity.lua` | ⚠️ Data Only | 257 LOC sparse matrix exists but NOT consumed by `match()` |
| **Tier 3** | GOAP planner | `src/engine/parser/goal_planner.lua` | ✅ Complete | 790 LOC, backward-chaining prerequisite resolver, MAX_DEPTH=7 |
| **Tier 4** | Context window | `src/engine/parser/context.lua` | ✅ Complete | 171 LOC, recency stack (5 items), pronoun resolution, discovery list |
| **Tier 5** | Fuzzy noun resolution | `src/engine/parser/fuzzy.lua` | ✅ Complete | 491 LOC, material/property/typo/disambiguation matching |
| **Tier 6** | Light/FSM requirements | `src/engine/parser/goal_planner.lua` | ✅ Complete | Light sourcing, tool requirements via GOAP |

### Validation Gates (P1-P6) in embedding_matcher.lua

| Gate | Purpose | Status | Evidence |
|------|---------|--------|----------|
| P1 | Noun validation — reject verb-only false positives | ✅ Implemented | Line 532: skip candidates where no input noun matches |
| P2 | Verbose input truncation — keep ≤5 tokens | ✅ Implemented | Line 464: prioritize game nouns, then IDF |
| P3 | Question transform — "what is X" → "examine X" | ✅ Implemented | Line 438: pre-tokenization transform |
| P4 | Noun exactness tiebreaker — prefer exact noun | ✅ Implemented | Lines 280-282: `noun_exactness()` function |
| P5 | Adjective-only guard — reject generic adj input | ✅ Implemented | Line 496: filters out "get small" type inputs |
| P6 | Unknown lead-word guard | ✅ Implemented | Line 509: reject if first token foreign to game |

### Phrase Index

| Asset | Status | Details |
|-------|--------|---------|
| `src/assets/parser/embedding-index.json` | ✅ Active | 11,131 phrases (31 verbs × ~74 objects × state variants + synonym expansions) |
| `src/engine/parser/bm25_data.lua` | ✅ Active | Auto-generated IDF table, 244 tokens |
| `src/engine/parser/synonym_table.lua` | ✅ Active | 60+ verb synonym mappings |
| `src/engine/parser/word_similarity.lua` | ⚠️ Unused | Sparse matrix exists, not wired into scoring |

---

## Improvement Status

Full audit of design doc planned improvements vs. actual implementation.

### Phase 1: Quick Wins (Design §4.1-4.3) — ✅ SHIPPED

| Item | Design Ref | Status | Evidence |
|------|-----------|--------|----------|
| BM25 scoring replacing Jaccard | §4.1 | ✅ Done | `bm25_score()` at line 204, IDF-weighted TF with saturation |
| IDF table (pre-computed) | §4.1 | ✅ Done | `bm25_data.lua`: 244 tokens, generated by `scripts/add_missing_objects.py` |
| Synonym expansion (verb) | §4.2 | ✅ Done | `synonym_table.lua`: 60+ verb synonyms, `expand_tokens()` |
| Threshold tuning | §4.3 | ✅ Done | THRESHOLD_BM25=3.00 (up from Jaccard 0.40) in `init.lua:13` |
| Inverted index | §4.7 (moved up) | ✅ Done | Built at load time, lines 387-420, `get_candidates()` at line 411 |

### Phase 2: Soft Matching (Design §4.4-4.5) — ⚠️ PARTIAL

| Item | Design Ref | Status | Evidence |
|------|-----------|--------|----------|
| Word similarity matrix (data) | §4.4 | ✅ Done | `word_similarity.lua`: 257 LOC, verb synonym pairs + semantic groupings |
| Soft cosine scoring function | §4.4 | 📋 Fallback (D3) | Documented as fallback if MaxSim insufficient. `word_similarity.lua` data ready. |
| MaxSim token matching | §4.5 | 🟢 Unblocked (D3) | Primary re-ranker per D3. Implement `maxsim_score()` consuming sparse matrix. |
| Hybrid BM25 + soft scoring | §4.4 | 🟢 Unblocked (D1) | 70/30 BM25-heavy, two-stage pipeline per D1. |

### Phase 3: Advanced Techniques (Design §4.6-4.8) — ⚠️ PARTIAL

| Item | Design Ref | Status | Evidence |
|------|-----------|--------|----------|
| Context-aware recency boost | §4.6 | ✅ Done | Phase 3 mode in embedding_matcher (line 558-562), `CONTEXT_BOOST_WEIGHT` |
| Inverted index for speed | §4.7 | ✅ Done | Moved to Phase 1, fully operational |
| Adaptive weighting (BM25F) | §4.8 | ⏳ Not Started | Separate verb/noun field weights not implemented |

### Post-Phase Fixes (Not in Original Design) — ✅ SHIPPED

| Item | Status | Evidence |
|------|--------|----------|
| P1: Noun validation gate | ✅ Done | Prevents verb-only false positives (+6 cases) |
| P2: Verbose input truncation | ✅ Done | Keeps ≤5 tokens, prioritizes game nouns |
| P3: Question transform in matcher | ✅ Done | "what is X" → "examine X" pre-tokenization |
| P4: Noun exactness tiebreaker | ✅ Done | Prefers "bed" over "bed-sheets" for input "hit bed" |
| P5: Adjective-only guard | ✅ Done | Rejects "get small" type inputs |
| P6: Unknown lead-word guard | ✅ Done | Rejects completely foreign first tokens |
| Tighter Levenshtein thresholds | ✅ Done | 4→d1, 5→d1, 6+→d2 (was 4→d1, 5→d2, 6+→d2) |
| Issue #242-244 synonyms | ✅ Done | peer/check→examine, context boost in BM25 path, noun_tokens |

---

## Ownership

| Domain | Owner | Collaborators |
|--------|-------|---------------|
| Parser pipeline (Tiers 1-5) | ⚛️ Smithers | — |
| Embedding matcher & scoring | ⚛️ Smithers | — |
| GOAP planner | ⚛️ Smithers | 🏗️ Bart (engine integration) |
| Phrase index & build scripts | ⚛️ Smithers | — |
| Parser tests | 🧪 Nelson (QA) | ⚛️ Smithers (test design) |
| Preprocessing pipeline | ⚛️ Smithers | — |
| Fuzzy noun resolution | ⚛️ Smithers | — |

---

## Test Coverage

### Parser Test Files (32 files + 11 pipeline sub-tests)

| Category | Files | Coverage |
|----------|-------|----------|
| **Benchmarks** | `bench-tier2-benchmark.lua`, `bench-inverted-index.lua` | 147-case accuracy benchmark, inverted index performance |
| **BM25 / Scoring** | `test-bm25-deep.lua`, `test-bm25f-disambiguation.lua` | BM25 stress tests, all verbs, typos, disambiguation |
| **Context** | `test-context.lua`, `test-context-window.lua`, `test-context-boost.lua` | Context stack, discoveries, pronouns, recency boost |
| **Fuzzy** | `test-fuzzy-nouns.lua`, `test-fuzzy-resolution.lua` | Material matching, property matching, typos |
| **GOAP** | `test-goap-tier6.lua` | Goal planning, light sourcing, prerequisites |
| **Preprocessing** | `test-preprocess.lua`, `test-preprocess-phrases.lua`, `test-prepositional-stripping.lua` | Pipeline stages, phrase routing, prepositions |
| **Patterns** | `test-idioms.lua`, `test-questions.lua`, `test-hit-synonyms.lua` | 90 idioms, 81 questions, hit synonym cluster |
| **Commands** | `test-compound-commands.lua`, `test-sleep-transforms.lua` | Multi-command parsing, sleep verbs |
| **Regression** | `test-regression-comprehensive.lua`, `test-pass027-bugs.lua`, `test-pass031-bugs.lua`, `test-pass033-bugs.lua`, `test-pass033-context-bugs.lua`, `test-pass038-phrase-routing.lua` | Comprehensive regressions, per-pass bug fixes |
| **Other** | `test-disambiguation.lua`, `test-loot-disambiguation.lua`, `test-error-messages.lua`, `test-on-traverse.lua`, `test-p1-parser-fixes.lua`, `test-issue-174-embedding-overhaul.lua`, `test-issue-14-15-16-17.lua` | Disambiguation, traversal, error handling, issue regressions |

### Pipeline Sub-Tests (11 files in `test/parser/pipeline/`)

| File | Coverage |
|------|----------|
| `test-normalize.lua` | Whitespace, casing, punctuation |
| `test-strip-filler.lua` | Preambles, politeness, adverbs |
| `test-expand-idioms.lua` | Idiom pattern matching |
| `test-transform-questions.lua` | Question→imperative transforms |
| `test-transform-look-patterns.lua` | Look at/for/around/check |
| `test-transform-search-phrases.lua` | Search/hunt/rummage |
| `test-transform-compound-actions.lua` | Pry, use X on Y, put/take, wear |
| `test-apply-patterns.lua` | Pattern application |
| `test-pour-patterns.lua` | Pour verb patterns |
| `test-wash-patterns.lua` | Wash verb patterns |
| `test-pipeline-integration.lua` | End-to-end pipeline |

### Coverage Gaps

| Area | Gap |
|------|-----|
| Soft cosine scoring | No tests (function not yet implemented) |
| MaxSim scoring | No tests (function not yet implemented) |
| Noun synonym expansion | Not tested (verb-only synonyms currently) |
| BM25F adaptive weighting | No tests (not yet implemented) |
| Fengari browser performance | No browser-side profiling tests |

---

## Plan Files

- **Design doc:** [`projects/parser-improvements/parser-improvement-design.md`](parser-improvement-design.md)
- **Research papers:** `resources/research/architecture/papers/` (BM25, Soft Cosine, ColBERT, WordNet, RAG)
- **Embedding index:** `src/assets/parser/embedding-index.json`
- **Build scripts:** `scripts/add_missing_objects.py` (generates IDF table + phrase index)
