# The Probabilistic Relevance Framework: BM25 and Beyond

**Authors:** Stephen Robertson, Hugo Zaragoza
**Year:** 2009
**Venue:** Foundations and Trends® in Information Retrieval, 3(4), 333–389
**URL:** <https://doi.org/10.1561/1500000019>
**Author PDF:** <https://www.staff.city.ac.uk/~sbrp622/papers/foundations_bm25_review.pdf>

## Abstract

The Probabilistic Relevance Framework (PRF) is a formal framework for document retrieval, grounded in work done in the 1970–1980s, which led to the development of one of the most successful text-retrieval algorithms, BM25. In recent years, research in the PRF has yielded new retrieval models that can take into account document metadata (especially structure and link-graph information). This further led to another highly successful search algorithm, BM25F. This monograph presents the PRF conceptually, explaining the probabilistic modeling assumptions behind the framework and the different ranking algorithms that result: the binary independence model, relevance feedback models, BM25, and BM25F. It also discusses the relation of PRF to other statistical models in information retrieval, use of non-textual features, and parameter optimization for models with free parameters.

## Key Algorithm / Methodology

### The BM25 Scoring Formula

Given a query Q containing keywords q_1, q_2, ..., q_n, the BM25 score of a document D is:

```
score(D, Q) = Σ(i=1..n) IDF(q_i) * [ f(q_i, D) * (k1 + 1) ] / [ f(q_i, D) + k1 * (1 - b + b * |D| / avgdl) ]
```

Where:
- `f(q_i, D)` = frequency of term q_i in document D (term frequency, TF)
- `|D|` = length of document D in words
- `avgdl` = average document length in the collection
- `k1` = term frequency saturation parameter (typical: **1.2 to 2.0**)
- `b` = length normalization parameter (typical: **0.75**)

### IDF (Inverse Document Frequency) Calculation

The Robertson/Spärck Jones IDF formula:

```
IDF(q_i) = ln( (N - n(q_i) + 0.5) / (n(q_i) + 0.5) + 1 )
```

Where:
- `N` = total number of documents in the collection
- `n(q_i)` = number of documents containing term q_i

The `+1` ensures IDF is never negative, even for terms appearing in more than half the documents.

### Intuition Behind Each Component

| Component | Formula Part | Purpose |
|-----------|-------------|---------|
| **IDF** | `ln((N - n + 0.5) / (n + 0.5) + 1)` | Boosts rare terms, penalizes common terms |
| **TF saturation** | `f * (k1 + 1) / (f + k1 * ...)` | Diminishing returns — 10 occurrences isn't 10x better than 1 |
| **Length norm** | `1 - b + b * |D| / avgdl` | Counteracts bias toward longer documents |

### Parameter Effects

- **k1 controls TF saturation:** Large k1 (e.g., 2.0) = slower saturation, extra occurrences still matter. Small k1 (e.g., 0.5) = fast saturation, presence matters more than count.
- **b controls length normalization:** b=1.0 = full normalization (long docs penalized). b=0.0 = no normalization (like classic TF).
- **For short text matching** (like game commands): k1 ≈ 1.2, b ≈ 0.75 are good defaults. Since our "documents" (phrase variants) are very short (2-5 tokens), b can be lowered to ~0.5.

### Probabilistic Foundation: Binary Independence Model (BIM)

BM25 is derived from the Binary Independence Model, which assumes:
1. Terms are independent given relevance/non-relevance
2. Relevance is binary (a document is relevant or not)
3. The probability of a term occurring differs between relevant and non-relevant documents

The BIM leads to a log-odds ratio for each term, which BM25 approximates using collection statistics (IDF) instead of requiring explicit relevance judgments.

### BM25F: Field-Weighted Extension

BM25F extends BM25 to structured documents with multiple fields (e.g., title, body, anchor text). Each field has its own weight and length normalization:

```
tf_BM25F = Σ(fields f) w_f * tf_f / (1 + B_f * (dl_f / avgdl_f - 1))
```

Then the combined TF is plugged into the standard BM25 saturation formula. This is relevant if we want to weight verb tokens differently from noun tokens in our phrase matching.

### BM25+ Variant (Lower-Bounded TF Normalization)

BM25+ addresses a deficiency where long documents matching a query term can score lower than short documents that don't match at all:

```
score_BM25+(D, Q) = Σ IDF(q_i) * [ f(q_i,D)*(k1+1) / (f(q_i,D) + k1*(1-b+b*|D|/avgdl)) + δ ]
```

Where δ (default 1.0) ensures a minimum contribution for matching terms regardless of document length.

### Pseudocode for BM25 Scoring

```
function bm25_score(query_terms, document, corpus_stats):
    score = 0
    for each term in query_terms:
        tf = count(term in document)
        if tf == 0: continue
        df = corpus_stats.doc_freq[term]
        N = corpus_stats.total_docs
        avgdl = corpus_stats.avg_doc_length
        dl = length(document)

        idf = math.log((N - df + 0.5) / (df + 0.5) + 1)
        tf_norm = (tf * (k1 + 1)) / (tf + k1 * (1 - b + b * dl / avgdl))
        score = score + idf * tf_norm
    return score
```

## Results Relevant to Our Parser

- BM25 is the **default scoring function in Lucene, Elasticsearch, and Solr** — battle-tested at web scale across billions of documents
- BM25 consistently **outperforms TF-IDF and Jaccard** on standard IR benchmarks (TREC)
- Standard parameters (k1=1.2, b=0.75) work well across diverse text collections without tuning
- BM25's IDF weighting naturally handles the "filler word" problem: common words like "the", "a", "at" get near-zero IDF, while informative words like "candle", "nightstand" get high IDF
- **Improvements over Jaccard for our use case:**
  - Jaccard treats "take candle" and "please take the candle now" as low similarity (2/5 overlap)
  - BM25 weights "take" and "candle" heavily (high IDF) and ignores "please", "the", "now" (low IDF), producing a high score

## Implementation Notes for Pure Lua

BM25 is **trivially implementable** in Lua — pure arithmetic (log, division, multiplication):

1. **Build-time:** Compute IDF for each term in our vocabulary (~200 words). Compute average phrase length. Store as a simple lookup table.
2. **Runtime:** For each input token, look up IDF. Compute TF normalization against each candidate phrase. Sum the weighted scores. O(|query| × |candidates|) — fast for our ~4,579 phrases.
3. **Memory:** IDF table is ~200 entries. Each phrase needs only its token list and length. Minimal overhead.
4. **Tuning:** Start with k1=1.2, b=0.75. If phrases are very short (2-3 tokens), try b=0.3-0.5 to reduce length normalization impact.
5. **BM25F potential:** If we separate verb and noun fields, we can weight verb matching higher than noun matching for disambiguation.

```lua
-- Lua BM25 implementation sketch
local function bm25_score(query_tokens, phrase_tokens, idf_table, avgdl, k1, b)
    local score = 0
    local dl = #phrase_tokens
    for _, qt in ipairs(query_tokens) do
        local tf = 0
        for _, pt in ipairs(phrase_tokens) do
            if qt == pt then tf = tf + 1 end
        end
        if tf > 0 and idf_table[qt] then
            local idf = idf_table[qt]
            local tf_norm = (tf * (k1 + 1)) / (tf + k1 * (1 - b + b * dl / avgdl))
            score = score + idf * tf_norm
        end
    end
    return score
end
```

## References Worth Following

- **Spärck Jones, Walker & Robertson (2000)** — "A probabilistic model of information retrieval" — deeper theoretical treatment of the probability model behind BM25
- **Lv & Zhai (2011)** — "Lower-bounding term frequency normalization" — the BM25+ variant that fixes edge cases with long documents
- **Robertson, Zaragoza, Taylor (2004)** — "Simple BM25 extension to multiple weighted fields" — BM25F for structured documents
- **Manning, Raghavan & Schütze (2009)** — *An Introduction to Information Retrieval* — textbook treatment with implementation guidance
