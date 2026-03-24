# D-KEEP-JACCARD — Keep Jaccard Token Matching, Strip Vectors

**Author:** Frink (Researcher)
**Date:** 2026-03-29
**Issue:** #176
**Report:** `resources/research/embedding-vector-research.md`

## Decision

**Keep the Jaccard token-overlap matcher in Tier 2.** Do not upgrade to cosine similarity.

## Evidence

Tested 60 player inputs across 6 categories. Jaccard: 68% correct. Cosine-BOW: 45%. Hybrid: 48%.

The GTE-tiny vectors are high quality (synonyms cluster at 0.97-0.99), but we cannot produce comparable query vectors at runtime in pure Lua or Fengari. The bag-of-word-vectors workaround destroys verb/noun discrimination.

Full cosine scan in Lua takes 44.7ms (4.5x over 10ms budget). Jaccard takes 8.1ms.

## Action Items

1. **Strip vectors from embedding index** — 15.3 MB → ~200 KB. Archive original.
2. **Add missing phrase variants** — "gimme X", "hold X", "lift X", "peer at X", "put down X", "use X"
3. **Fix state-variant tiebreaker** — when Jaccard scores tie, prefer base-state noun over stateful variant (candle > candle-lit)
4. **Monitor Jaccard scan time** — at 8.1ms for 4,337 phrases, it's borderline. Optimize or reduce index if it grows.

## Who Should Know

- **Smithers** — Parser owner, action items 1-4
- **Gil** — Web build, index size reduction benefits bandwidth
- **Bart** — Architecture, no engine changes needed
- **Nelson** — Add parser accuracy regression tests based on the 60-input test suite
