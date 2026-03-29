# Parser Scoring Decisions — Frink Research Recommendations

**Date:** 2026-03-29
**Author:** Frink (Research Scientist)
**Requested by:** Wayne "Effe" Berry
**Context:** Parser at 91.2% accuracy (134/147). Four blocking decisions needed for next round of parser improvements.

---

### D1: Hybrid scoring weights — BM25 + soft cosine ratio

**Decision:** 70/30 BM25-heavy, implemented as two-stage pipeline (BM25 retrieval → semantic re-rank on top 50).

**Reasoning:** For short queries (2-4 tokens), lexical matching dominates. Robertson & Zaragoza (2009) established that BM25 is remarkably robust for short queries — IDF weighting on 2-3 content tokens provides strong discriminative signal. Soft cosine adds value only at the margin: breaking ties between candidates that BM25 scored equally. The two-stage architecture (already outlined in the design doc §2.5) is cleaner than linear combination because it avoids score-range normalization issues between BM25 (unbounded) and soft cosine (0-1). Concretely: BM25 retrieves top-50 candidates via the existing inverted index, then the semantic re-ranker applies the similarity matrix to re-order those 50. The 70/30 ratio applies only if Smithers prefers a linear blend — but I recommend the two-stage pipeline as the primary approach.

**Affects:** Smithers (implementation in `embedding_matcher.lua`)

---

### D2: Synonym expansion scope — 2-3 synonyms per noun term (conservative)

**Decision:** Conservative: 2-3 close synonyms per noun. No aggressive expansion.

**Reasoning:** Lu et al. (2015) found that top 2-3 WordNet synonyms yielded +5% precision and +8% recall in code search. Beyond 3, precision degrades as semantic drift introduces false matches ("candle" → "taper" is valid; "candle" → "light" → "lamp" → "lantern" creates chains that drift from intent). Our verb synonym system (60+ mappings in `synonym_table.lua`) already validates this approach — it uses tight, curated mappings and achieves strong results.

For nouns specifically: the game vocabulary is ~200 words. Players encounter objects directly and learn their names. The primary failure mode isn't "player knows a synonym we don't" — it's disambiguation and verbose input. The 13 remaining benchmark failures include zero cases where a missing noun synonym was the root cause.

Adaptive expansion (start at 2, expand per-term if recall is low) is theoretically appealing but adds complexity without clear benefit at this vocabulary size. Start conservative, expand specific terms only if beta playtesting reveals gaps.

**Affects:** Smithers (noun entries in `synonym_table.lua`), Flanders (object keyword lists)

---

### D3: Soft cosine vs MaxSim — MaxSim first, soft cosine as documented fallback

**Decision:** Implement MaxSim. Skip A/B testing. Keep soft cosine as fallback if MaxSim proves insufficient.

**Reasoning:** At our query scale (2-4 tokens × 3-4 token phrases), the O(n²) vs O(n×m) complexity difference is irrelevant — both resolve in microseconds even in Fengari. The decision comes down to three factors:

1. **Implementation simplicity.** MaxSim is ~20 LOC: for each query token, find max similarity against all phrase tokens, sum the maxima. Soft cosine requires frequency vectors, normalization denominators, and the full double-summation. MaxSim ships faster.

2. **Debuggability.** MaxSim decomposes naturally: you can see that "grab" matched "get" at 0.95, "candle" matched "candle" at 1.0, "quickly" matched nothing at 0.0. Soft cosine produces a single opaque score. For a system at 91.2% where we're chasing marginal gains, debuggability matters.

3. **Noise token robustness.** MaxSim naturally handles extra noise tokens (they contribute ~0 to the sum). Soft cosine's normalization penalizes query-document length mismatch, which hurts on verbose player inputs — exactly the failure category (P2) we're already fighting.

4. **Accuracy equivalence at this scale.** For 2-4 token queries, MaxSim and soft cosine produce near-identical rankings. The theoretical advantage of soft cosine (capturing inter-token correlations) matters for longer documents, not for "grab candle" vs "get candle".

The `word_similarity.lua` sparse matrix (286 LOC, ~150 word pairs) is already in the right format for MaxSim lookups. A/B testing both doubles the implementation cost for negligible expected accuracy delta. If MaxSim doesn't hit the 93% target after integration, THEN build soft cosine.

**Affects:** Smithers (new `maxsim_score()` in `embedding_matcher.lua`, consume `word_similarity.lua`)

---

### D4: Accuracy target — 93% target, then reassess after beta

**Decision:** Push to 93% (~137/147), then ship to beta. Reassess based on real player data.

**Reasoning:** Three data points drive this:

1. **91% → 93% is achievable.** That's ~3 more cases. MaxSim re-ranking + noun synonym expansion should cover 3-5 of the 13 remaining failures based on their root causes (the false-positive and disambiguation categories are most likely to benefit from semantic re-ranking).

2. **93% → 95% hits diminishing returns.** The remaining ~10 failures after 93% will include hard edge cases ("match match" duplicate word, unknown-noun false positives for objects not in the game). Each requires custom logic, not general improvements. The cost-per-percent-point doubles.

3. **Beta playtesting data is worth 10x the benchmark.** The 147-case benchmark was designed by the dev team — it reflects developer intuitions about what players type. Real players will surprise us. Shipping at 93% with instrumentation to capture failure patterns gives us data to prioritize the push from 93% → 95% based on actual player frustration, not hypothetical failures.

The design doc's original target was 85%. We've already exceeded it by 6 points. 93% is a defensible, achievable milestone that clears the path to beta without over-investing in pre-beta optimization.

**Affects:** Smithers (scope of next sprint), Nelson (benchmark target update), Wayne (beta timeline)

---

## Summary

| Decision | Recommendation | Key Rationale |
|----------|---------------|---------------|
| D1: Hybrid weights | 70/30 BM25-heavy, two-stage pipeline | Short queries favor lexical precision; semantic re-ranking handles ties |
| D2: Synonym scope | 2-3 per noun (conservative) | Lu et al. research; no synonym-caused failures in remaining 13; drift risk |
| D3: Scoring approach | MaxSim first, soft cosine fallback | Simpler, debuggable, noise-robust, equivalent accuracy at this scale |
| D4: Accuracy target | 93%, then beta + reassess | 3 cases achievable; diminishing returns above 93%; real data > benchmarks |
