# Embedding Vector Research: Jaccard vs Cosine Similarity

**Author:** Frink (Researcher)  
**Issue:** #176  
**Date:** 2026-03-29  
**Status:** COMPLETE  

---

## Executive Summary

The current parser (Tier 2) loads a 15.3 MB embedding index with 4,337 phrases × 384-dim GTE-tiny vectors, then **ignores the vectors entirely** and matches via Jaccard token overlap. The question: should we use the vectors?

**Bottom line: Keep Jaccard.** The vectors are high-quality, but we cannot encode novel player input at runtime in pure Lua or Fengari. The bag-of-word-vectors workaround degrades accuracy from 68% → 45%. The 15.3 MB index should be trimmed to text-only (~200 KB) unless we move to a browser-side ONNX architecture — which is a separate, larger decision.

---

## 1. Quality Comparison — Test Results

### Methodology

- 60 test inputs across 6 categories (exact, synonym, partial, novel, ambiguous, close-wrong)
- Jaccard matcher: faithful Python reimplementation of `embedding_matcher.lua`
- Cosine-BOW: bag-of-word-vectors approach (average word embeddings from index, compare via cosine)
- Hybrid: Jaccard pre-filter (top 50) → cosine re-rank
- "CORRECT" = right verb + right noun; "VERB_OK" = right verb, wrong noun variant

### Results Summary

| Category | Count | Jaccard | Cosine-BOW | Hybrid |
|----------|-------|---------|------------|--------|
| Exact matches | 10 | **8** (10 verb-ok) | 5 (8 verb-ok) | 5 (8 verb-ok) |
| Synonym/paraphrase | 10 | **9** (9 verb-ok) | 5 (9 verb-ok) | 5 (9 verb-ok) |
| Partial/abbreviated | 10 | **8** (10 verb-ok) | 4 (6 verb-ok) | 4 (6 verb-ok) |
| Novel phrasing | 10 | 2 (2 verb-ok) | 1 (1 verb-ok) | 1 (1 verb-ok) |
| Ambiguous | 10 | **7** (7 verb-ok) | 5 (5 verb-ok) | 6 (6 verb-ok) |
| Close-wrong | 10 | 7 (9 verb-ok) | 7 (8 verb-ok) | **8** (9 verb-ok) |
| **TOTAL** | **60** | **41 (68%)** | **27 (45%)** | **29 (48%)** |

**Jaccard wins decisively: 68% vs 45% correct.** Even on verb-only accuracy, Jaccard leads 47/60 vs 37/60.

### Full Test Results Table

| # | Input | Expected | Jaccard Result | Cosine-BOW Result | Winner |
|---|-------|----------|---------------|-------------------|--------|
| 1 | get candle | get+candle | ✅ get+candle (0.67) | ✅ get+candle (0.97) | Tie |
| 2 | look at candle | look+candle | ✅ look+candle (0.67) | ❌ search+candle (0.97) | Jaccard |
| 3 | open nightstand | open+nightstand | ✅ open+nightstand (0.67) | ❌ strike+nightstand-open (0.98) | Jaccard |
| 4 | drop knife | drop+knife | ✅ drop+knife (0.67) | ✅ drop+knife (0.97) | Tie |
| 5 | smell candle | smell+candle | ✅ smell+candle (0.67) | ⚠️ smell+candle-lit (0.98) | Jaccard |
| 6 | feel blanket | feel+blanket | ✅ feel+blanket (0.50) | ✅ feel+blanket (0.98) | Tie |
| 7 | examine match | examine+match | ⚠️ examine+match-lit (0.67) | ✅ examine+match (0.97) | Cosine |
| 8 | close wardrobe | close+wardrobe | ✅ close+wardrobe (0.67) | ⚠️ close+wardrobe-open (0.98) | Jaccard |
| 9 | search bed | search+bed | ⚠️ search+ (0.50) | ⚠️ search+bed-sheets (0.96) | Tie |
| 10 | inventory | i+ | ✅ i+ (1.00) | ✅ i+ (0.99) | Tie |
| 11 | pick up the candle | pick+candle | ✅ pick+candle (0.67) | ✅ pick+candle (0.97) | Tie |
| 12 | grab the knife | grab+knife | ✅ grab+knife (0.67) | ✅ grab+knife (0.97) | Tie |
| 13 | take the tallow candle | take+candle | ✅ take+candle (1.00) | ⚠️ take+candle-lit (0.98) | Jaccard |
| 14 | fetch the brass key | get+brass-key | ✅ get+brass-key (0.75) | ✅ get+brass-key (0.98) | Tie |
| 15 | sniff the candle | sniff+candle | ⚠️ smell+candle (0.67) | ❌ smell+candle-lit (0.98) | Jaccard |
| 16 | shut the wardrobe | close+wardrobe | ✅ close+wardrobe (0.67) | ⚠️ close+wardrobe-open (0.98) | Jaccard |
| 17 | observe the rug | look+rug | ✅ look+rug (0.67) | ✅ look+rug (0.98) | Tie |
| 18 | hit the window | strike+window | ✅ strike+window (0.50) | ⚠️ strike+window-open (0.98) | Jaccard |
| 19 | whack the pillow | strike+pillow | ✅ strike+pillow (0.67) | ✅ strike+pillow (0.98) | Tie |
| 20 | eat the candle | consume+candle | ✅ consume+candle (0.67) | ⚠️ consume+candle-lit (0.97) | Jaccard |
| 21 | get cand | get+candle | ✅ get+candle (0.33) | ⚠️ get+cloth (0.94) | Jaccard |
| 22 | take blanke | take+blanket | ✅ take+blanket (0.29) | ❌ sniff+cloth (0.96) | Jaccard |
| 23 | look match | look+match | ⚠️ look+match-lit (0.67) | ⚠️ search+match (0.96) | Tie |
| 24 | open ward | open+wardrobe | ⚠️ open+wardrobe-open (0.31) | ❌ strike+vanity-open (0.96) | Jaccard |
| 25 | feel pill | feel+pillow | ✅ feel+pillow (0.33) | ⚠️ feel+cloth (0.95) | Jaccard |
| 26 | smell rag | smell+rag | ✅ smell+rag (0.67) | ✅ smell+rag (0.98) | Tie |
| 27 | get key | get+brass-key | ✅ get+brass-key (0.50) | ✅ get+brass-key (0.97) | Tie |
| 28 | take shard | take+glass-shard | ✅ take+glass-shard (0.67) | ⚠️ sniff+glass-shard (0.97) | Jaccard |
| 29 | look needle | look+needle | ✅ look+needle (0.67) | ✅ look+needle (0.98) | Tie |
| 30 | drop pen | drop+pen | ✅ drop+pen (0.67) | ✅ drop+pen (0.97) | Tie |
| 31 | I want to hold the candle | get+candle | ❌ x+candle-lit (0.25) | ⚠️ ignite+candle (0.99) | Tie (both fail) |
| 32 | gimme that candle | get+candle | ❌ x+candle-lit (0.33) | ⚠️ ignite+candle (0.99) | Tie (both fail) |
| 33 | let me see the knife | look+knife | ⚠️ drop+knife (0.33) | ⚠️ drop+knife (0.97) | Tie |
| 34 | what does the rug look like | look+rug | ✅ look+rug (0.33) | ⚠️ x+rug (0.96) | Jaccard |
| 35 | put down the blanket | drop+blanket | ⚠️ don+blanket (0.50) | ⚠️ extinguish+blanket (0.98) | Tie |
| 36 | throw away the rag | drop+rag | ⚠️ x+rag (0.25) | ⚠️ place+rag (0.98) | Tie |
| 37 | check out the window | look+window | ⚠️ extinguish+window (0.33) | ❌ strike+window-open (0.95) | Jaccard |
| 38 | touch the bed sheets | feel+bed-sheets | ✅ feel+bed-sheets (0.75) | ✅ feel+bed-sheets (0.98) | Tie |
| 39 | peer at the nightstand | look+nightstand | ❌ x+nightstand-open (0.33) | ❌ take+nightstand-open (0.99) | Tie (both fail) |
| 40 | lift the pillow | get+pillow | ⚠️ x+pillow (0.33) | ⚠️ place+pillow (0.99) | Tie |
| 41 | get it | get+ | ✅ get+bandage (0.33) | ✅ get+cloth (0.94) | Tie |
| 42 | take the thing | take+ | ✅ take+bandage (0.25) | ❌ sniff+cloth (0.96) | Jaccard |
| 43 | look around | look+ | ✅ look+ (1.00) | ❌ search+cloth (0.95) | Jaccard |
| 44 | what is this | look+ | ❌ time+ (0.50) | ❌ time+ (0.96) | Tie (both fail) |
| 45 | use candle | ignite+candle | ❌ x+candle-lit (0.33) | ✅ ignite+candle (0.99) | Cosine |
| 46 | check inventory | i+ | ❌ inventory+ (1.00) | ❌ inventory+ (0.99) | Tie (both fail) |
| 47 | go north | look+north | ✅ look+north (0.33) | ✅ look+north (0.96) | Tie |
| 48 | open it | open+ | ✅ open+bandage (0.33) | ❌ strike+vanity-open (0.96) | Jaccard |
| 49 | search around | search+ | ✅ search+ (1.00) | ✅ search+cloth (0.95) | Tie |
| 50 | smell something | smell+ | ✅ smell+bandage (0.25) | ✅ smell+wardrobe-open (0.95) | Tie |
| 51 | light the match | ignite+match | ⚠️ ignite+match-lit (0.67) | ✅ ignite+match (0.97) | Cosine |
| 52 | strike a match | strike+match | ⚠️ strike+match-lit (0.67) | ✅ strike+match (0.96) | Cosine |
| 53 | burn the candle | burn+candle | ✅ burn+candle (0.67) | ✅ burn+candle (0.98) | Tie |
| 54 | break the glass | break+glass-shard | ✅ break+glass-shard (0.67) | ⚠️ break+window-open (0.96) | Jaccard |
| 55 | cut the cloth | cut+cloth | ✅ cut+cloth (0.67) | ✅ cut+cloth (0.97) | Tie |
| 56 | rip the sheets | rip+bed-sheets | ✅ rip+bed-sheets (0.50) | ✅ rip+bed-sheets (0.98) | Tie |
| 57 | tear the curtains | tear+curtains | ⚠️ rip+curtains (0.50) | ❌ rip+curtains-open (0.98) | Jaccard |
| 58 | mend the bandage | mend+bandage | ✅ mend+bandage (0.67) | ✅ mend+bandage (0.97) | Tie |
| 59 | sew the cloth | sew+cloth | ✅ sew+cloth (0.67) | ✅ sew+cloth (0.98) | Tie |
| 60 | write on paper | write+paper | ✅ write+paper (0.50) | ⚠️ strike+paper (0.97) | Jaccard |

Legend: ✅ = correct verb+noun, ⚠️ = right verb wrong noun (or vice versa), ❌ = wrong

### Key Observations

1. **Jaccard excels at partial/abbreviated input** ("get cand" → candle, "feel pill" → pillow) because the prefix-bonus heuristic directly handles this. BOW vectors have no concept of prefixes.

2. **Cosine-BOW has a fatal "open" problem.** The word "open" appears in many _noun variants_ (wardrobe-open, nightstand-open, window-open, vanity-open). The averaged word vector for "open" pulls toward these stateful variants, causing inputs like "open nightstand" to match "whack a small nightstand (drawer open)" instead.

3. **Both approaches fail hard on truly novel phrasing** ("gimme that candle", "I want to hold the candle"). This is the fundamental limitation of any lookup-based system — without runtime encoding, novel vocabulary can't match.

4. **Cosine-BOW's only wins are when verb disambiguation helps** — "use candle" → ignite, "light the match" → ignite. These cases work because the BOW vector for "light" happens to cluster near "ignite" phrases. But this is coincidental — the same mechanism causes "open nightstand" to fail.

---

## 2. The Runtime Encoding Problem

This is the **critical blocker** for any cosine-based approach.

### The Problem

The index contains pre-computed 384-dim GTE-tiny embeddings for 4,337 known phrases. Cosine similarity requires **both** vectors. For known phrases, we have vectors. For **player input** — which is novel text typed in real-time — we don't.

To get a player input vector, we need to run GTE-tiny inference.

### Can GTE-tiny run in pure Lua?

**No.** GTE-tiny is a 17.6M-parameter transformer (BERT-based). It requires:
- Matrix multiplication on weight matrices up to 384×384
- Multi-head attention (6 heads)
- Layer normalization
- GELU activation
- Tokenizer (WordPiece, 30k vocabulary)

Pure Lua cannot run a transformer model. The computation would take minutes, not milliseconds, even if someone ported the model weights to Lua tables.

### Can GTE-tiny run in Fengari (Lua-in-browser)?

**No.** Fengari is 3-10x slower than native Lua. If native Lua can't do it, Fengari definitely can't.

### Can we use ONNX Runtime Web?

**Yes, technically.** ONNX Runtime Web can run GTE-tiny in a browser via WebAssembly or WebGL. This is the approach the code comments mention ("Real vector similarity comes later in the browser via ONNX Runtime Web").

**Latency estimates** (from published benchmarks and ONNX Runtime Web documentation):
- ONNX Runtime Web (WASM): ~20-50ms per sentence encode on modern desktop
- ONNX Runtime Web (WebGL): ~10-30ms per sentence encode
- Mobile browser: ~50-150ms per sentence encode

The model file is ~70 MB (FP32) or ~17 MB (quantized INT8). This is a significant download for a text adventure.

**Assessment:** Feasible for a browser-only architecture, but adds:
- 17-70 MB model download
- JavaScript dependency (ONNX Runtime Web library)
- 20-50ms latency per parse (in addition to index scan)
- Mobile performance concerns
- Incompatible with pure Lua architecture (Principle 8 says engine executes metadata, no external dependencies)

### Pre-computing ALL verb+noun combinations?

**Partially feasible.** We could pre-compute vectors for every legal `verb noun` pair:
- 48 verbs × 41 nouns = 1,968 combinations (subset of the 4,337 we already have)
- These are already in the index

But this doesn't help with:
- Novel phrasing ("gimme", "I want to", "let me")
- Abbreviations ("cand" for candle)
- Compound inputs ("pick up the candle" — 4 words, not 2)
- Context-dependent input ("get it")

The index already covers common paraphrases (3 variants per verb+noun). Expanding to more variants requires the same GTE-tiny encoding we're trying to avoid.

---

## 3. Pure Lua Vector Math Benchmark

Tested on Windows, Lua 5.4, single-threaded.

| Operation | Time | Within 10ms Budget? |
|-----------|------|---------------------|
| Single cosine sim (384-dim) | 0.010 ms | ✅ Yes |
| Full index scan (4,337 phrases) | **44.7 ms** | ❌ No (4.5x over budget) |
| Top-50 filtered scan | 0.47 ms | ✅ Yes |
| Full Jaccard scan (4,337 phrases) | 8.1 ms | ✅ Yes (borderline) |

### Analysis

- **Full cosine scan is 5.5x slower than Jaccard** and blows the 10ms budget by 4.5x.
- **Top-50 filtered scan is fast** (0.47ms), making the hybrid approach performance-feasible.
- **Jaccard is already borderline** at 8.1ms for 4,337 phrases. As the index grows, this will need optimization.
- **Fengari would multiply these times by 3-10x**, putting even Jaccard at risk (24-81ms).

### Fengari Projections

| Operation | Estimated Fengari Time | Budget? |
|-----------|----------------------|---------|
| Full cosine scan | 134-447 ms | ❌ Way over |
| Top-50 cosine scan | 1.4-4.7 ms | ✅ Yes |
| Full Jaccard scan | 24-81 ms | ❌ Over in worst case |

---

## 4. Hybrid Approach Analysis

### Concept
1. Jaccard pre-filter → top 50 candidates by token overlap
2. Cosine re-rank those 50 using BOW-vectors

### Test Results

The hybrid approach scored **29/60 (48%)** — marginally better than pure Cosine-BOW (27/60, 45%) but much worse than pure Jaccard (41/60, 68%).

### Why the hybrid doesn't help

The Jaccard pre-filter works well — it correctly narrows to relevant candidates. But the cosine re-ranking step **degrades** results because:

1. **BOW vectors lose verb identity.** The word "get" appears in 117 phrases across ALL nouns. Its averaged vector is a centroid of everything-you-can-get. When cosine compares this against specific phrase vectors, it picks whichever phrase is closest to this generic centroid — often the wrong one.

2. **State variants confuse cosine.** "candle" (unlit) and "candle-lit" are nearly identical vectors (cosine ~0.98). The BOW approach can't distinguish them. Jaccard can, because the tokens are different.

3. **The pre-filter already solves the hard problem.** If Jaccard finds the right candidates, re-ranking with a noisier signal makes things worse, not better.

### When would a hybrid help?

Only if we had **proper sentence embeddings** for the input (not BOW). With true GTE-tiny encoding:
- "use candle" would encode as a vector near "light a candle" / "ignite a candle"
- "gimme that candle" would encode near "get a candle" / "take a candle"

But this requires runtime encoding — see Section 2.

---

## 5. Alternative: Offline Pre-computation (BOW-Vectors)

### Concept
- Pre-compute vectors for every game keyword and verb
- At runtime, look up player's words in keyword→vector table
- Average word vectors → "sentence" vector
- Compare against phrase vectors via cosine

### Test Results

This IS the "Cosine-BOW" approach tested above. **It scored 45%, worse than Jaccard's 68%.**

### Why it fails

The core issue is **word vector averaging destroys information**:

| Problem | Example |
|---------|---------|
| **Verb-noun confusion** | "open nightstand" averages "open" (appears in 117 phrases) + "nightstand" → centroid is closest to "strike nightstand-open" |
| **State variant bias** | Cosine scores "candle-lit" higher than "candle" for nearly every query, because lit-candle phrases have richer descriptions |
| **No word order** | "take match" and "match take" produce identical vectors |
| **Partial words unrepresented** | "cand" has no vector; falls back to nothing or wrong word |

### The GTE-tiny vectors are high quality

To be clear: the **pre-computed phrase vectors are excellent**:

| Phrase Pair | Cosine Similarity |
|-------------|------------------|
| "get a tallow candle" ↔ "take a tallow candle" | 0.979 |
| "get a tallow candle" ↔ "pick up a tallow candle" | 0.979 |
| "look at a tallow candle" ↔ "examine a tallow candle" | 0.985 |
| "smell a tallow candle" ↔ "sniff a tallow candle" | 0.989 |
| "strike a wooden match" ↔ "hit a wooden match" | 0.983 |
| "get a tallow candle" ↔ "break a tallow candle" | 0.969 |
| "get a tallow candle" ↔ "get a wooden match" | 0.842 |

Same-verb same-noun synonyms cluster at 0.97-0.99. Different verbs on same noun are 0.96-0.97. Different nouns drop to 0.84. **This is exactly what you'd want for semantic matching.**

The problem isn't vector quality — it's that **we can't produce a query vector of comparable quality at runtime.**

---

## 6. Recommendation

### KEEP JACCARD — with targeted improvements

**Rationale:**
1. Jaccard outperforms every cosine variant we can actually implement (68% vs 45-48%)
2. The runtime encoding problem has no pure-Lua solution
3. The ONNX browser approach adds 17-70 MB, JavaScript deps, and 20-50ms latency — disproportionate for the marginal gains on novel phrasing
4. Both approaches fail equally on truly novel input — this is a coverage problem, not an algorithm problem

### Actionable improvements to the CURRENT system

These would improve Jaccard's 68% accuracy without changing architecture:

1. **Strip the vectors from the index.** Reduce from 15.3 MB → ~200 KB. The vectors are unused and waste memory/bandwidth. Keep the original index archived in case we ever add ONNX support.

2. **Add more phrase variants** for the cases both approaches fail on:
   - "gimme X" → get (add to index)
   - "hold X" → get
   - "lift X" → get
   - "peer at X" → look
   - "put down X" → drop
   - "throw away X" → drop
   - "use candle" → ignite
   - "check out X" → look

3. **Fix the `match-lit` / `candle-lit` / `*-open` bias.** Jaccard scores "examine match" equally against "examine a wooden match" and "examine a lit match" (both score 0.67), then takes whichever comes first in the index. Add a **prefer-base-state tiebreaker**: when scores are equal, prefer the non-suffixed noun variant.

4. **Consider reducing index size.** 4,337 phrases but only ~48 verbs × 41 nouns = ~1,968 meaningful combinations. Many phrases are synonyms ("break/smash/shatter") that Jaccard handles via token overlap anyway. A curated 1,500-phrase index would be faster and just as accurate.

### When to revisit this decision

Revisit cosine similarity IF:
- The game moves to a **browser-only architecture** where ONNX Runtime Web is acceptable
- The phrase index grows beyond 10,000 entries (Jaccard scan time becomes a problem)
- A **pure-Lua-compatible embedding model** emerges (unlikely but not impossible — e.g., a hash-based embedding trained specifically for this vocabulary)

### What to do with the 15.3 MB index

| Option | Size | Recommendation |
|--------|------|---------------|
| Keep as-is | 15.3 MB | ❌ Wastes bandwidth, vectors unused |
| Strip vectors, keep phrases | ~200 KB | ✅ **Do this now** |
| Archive original for future ONNX | 15.3 MB (archived) | ✅ Keep in `resources/` |
| Delete entirely | 0 KB | ❌ Lose the phrase corpus |

---

## Appendix: Data & Method

### Test Script
`temp/run_comparison.py` — Python reimplementation of the Jaccard matcher + BOW-vector cosine approach

### Lua Benchmark
`temp/bench_cosine.lua` — Pure Lua cosine similarity performance measurement

### Embedding Index
- **File:** `src/assets/parser/embedding-index.json`
- **Model:** TaylorAI/gte-tiny
- **Dimensions:** 384
- **Phrases:** 4,337
- **Vector norms:** ~1.0 (unit-normalized)
- **Key name:** `embedding` (not `vector`)

### Vocabulary Coverage
- **Unique verbs:** 48
- **Unique nouns:** 41
- **Phrases per verb:** ~90-120 (3 synonyms × 39 nouns)
- **Word vector vocabulary:** 172 unique tokens (after stop-word removal)
