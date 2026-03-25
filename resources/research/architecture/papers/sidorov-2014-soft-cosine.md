# Soft Similarity and Soft Cosine Measure: Similarity of Features in Vector Space Model

**Authors:** Grigori Sidorov, Alexander Gelbukh, Helena Gómez-Adorno, David Pinto
**Year:** 2014
**Venue:** Computación y Sistemas, 18(3), 491–504
**URL:** <https://doi.org/10.13053/CyS-18-3-2043>
**Open Access PDF:** <https://www.scielo.org.mx/pdf/cys/v18n3/v18n3a7.pdf>

## Abstract

We show how to consider similarity between features for calculation of similarity of objects in the Vector Space Model (VSM) for machine learning algorithms and other classes of methods that involve similarity between objects. Unlike LSA, we assume that similarity between features is known (say, from a synonym dictionary) and does not need to be learned from the data. We call the proposed similarity measure **soft similarity**. Similarity between features is common, for example, in natural language processing: words, n-grams, or syntactic n-grams can be somewhat different (which makes them different features) but still have much in common: for example, words "play" and "game" are different but related. When there is no similarity between features then our soft similarity measure is equal to the standard similarity. For this, we generalize the well-known cosine similarity measure in VSM by introducing what we call **"soft cosine measure"**. We propose various formulas for exact or approximate calculation of the soft cosine measure. For example, in one of them we consider for VSM a new feature space consisting of pairs of the original features weighted by their similarity. Again, for features that bear no similarity to each other, our formulas reduce to the standard cosine measure. Our experiments show that our soft cosine measure provides better performance in our case study: entrance exams question answering task at CLEF. In these experiments, we use syntactic n-grams as features and Levenshtein distance as the similarity between n-grams, measured either in characters or in elements of n-grams.

**Keywords:** Soft similarity, soft cosine measure, vector space model, similarity between features, Levenshtein distance, n-grams, syntactic n-grams.

## Key Algorithm / Methodology

### The Standard Cosine Similarity (Baseline)

Standard cosine similarity between two document vectors a and b:

```
cosine(a, b) = (a · b) / (||a|| * ||b||) = Σ_i(a_i * b_i) / (sqrt(Σ_i a_i²) * sqrt(Σ_i b_i²))
```

This treats all features as completely independent — "grab" and "take" have zero similarity because they are different features.

### The Soft Cosine Measure (Core Innovation)

The soft cosine measure generalizes cosine similarity by incorporating a **word similarity matrix S**, where S_ij represents the similarity between feature i and feature j:

```
soft_cosine(a, b) = Σ_{i,j} (a_i * b_j * S_ij) / ( sqrt(Σ_{i,j} a_i * a_j * S_ij) * sqrt(Σ_{i,j} b_i * b_j * S_ij) )
```

Where:
- `a_i`, `b_j` are elements of document vectors a and b (e.g., term frequencies or TF-IDF weights)
- `S_ij` is the entry in the word similarity matrix (how similar word i is to word j)
- When `S_ij = δ_ij` (Kronecker delta: 1 if i=j, 0 otherwise), the formula **reduces exactly to standard cosine similarity** — zero regression risk

### Properties of the Similarity Matrix S

- **Symmetric:** S_ij = S_ji
- **Diagonal = 1:** S_ii = 1 (every word is perfectly similar to itself)
- **Positive semi-definite:** Required for the measure to be well-defined (the square root is always real)
- **Range:** 0 ≤ S_ij ≤ 1

### Sources for S_ij in Practice

The paper proposes that S can come from **any known similarity measure between features**:
1. **Synonym dictionaries** (e.g., WordNet) — "grab" and "take" are synonyms → S ≈ 0.9
2. **Word embeddings** — cosine similarity between word vectors (e.g., Word2Vec, GloVe, GTE-tiny)
3. **Levenshtein distance** — for morphological similarity (used in the paper's experiments)
4. **Manual annotation** — for domain-specific knowledge

### Matrix Formulation

The soft cosine can be written compactly using matrix notation:

```
soft_cosine(a, b) = (a^T · S · b) / (sqrt(a^T · S · a) * sqrt(b^T · S · b))
```

Where S is the n×n similarity matrix and a, b are n-dimensional feature vectors.

### Approximate Computation (Efficiency)

The paper proposes an efficient approximation using only the **top-k most similar feature pairs** rather than the full n×n matrix:

1. **Threshold approach:** Only include S_ij entries above a threshold (e.g., S_ij > 0.3). Set all others to 0.
2. **Sparse matrix:** With most entries zeroed out, the computation becomes O(k × |non-zero terms|) instead of O(n²).
3. **Pair-feature space:** Create a new feature space consisting of pairs (i,j) weighted by S_ij. This transforms the n-dimensional problem into a manageable set of pair features.

### Pseudocode

```
function soft_cosine(a, b, S):
    numerator = 0
    norm_a = 0
    norm_b = 0

    for i in vocabulary:
        for j in vocabulary:
            if S[i][j] > threshold:
                numerator += a[i] * b[j] * S[i][j]
                norm_a += a[i] * a[j] * S[i][j]
                norm_b += b[i] * b[j] * S[i][j]

    if norm_a == 0 or norm_b == 0: return 0
    return numerator / (sqrt(norm_a) * sqrt(norm_b))
```

## Results Relevant to Our Parser

### CLEF Question Answering Experiments

- **Task:** Entrance exams question answering at CLEF (Choose the best answer from a set of options)
- **Features:** Syntactic n-grams as features
- **Similarity measure:** Levenshtein distance between n-grams
- **Result:** Soft cosine measure **outperformed standard cosine** in all experimental configurations
- **Key insight:** Even with a simple similarity measure (Levenshtein), incorporating feature similarity improved QA accuracy

### Why This Matters for Short Text Matching

The paper's key contribution is showing that when features (words) have known similarities, exploiting this information **always helps and never hurts**:
- When words are truly unrelated, S_ij = 0, and soft cosine = standard cosine (no regression)
- When words are related (synonyms, morphological variants), soft cosine captures the relationship

**Example for our parser:**
- Input: "grab lamp" → vector a = [0, 0, 1, 1, 0, ...] (for "grab" and "lamp")
- Phrase: "get lamp" → vector b = [0, 1, 0, 1, 0, ...] (for "get" and "lamp")
- Standard cosine: only "lamp" matches → cosine ≈ 0.5
- Soft cosine: "grab"↔"get" have S ≈ 0.95, "lamp"↔"lamp" = 1.0 → soft_cosine ≈ 0.97

## Implementation Notes for Pure Lua

### Pre-computed Similarity Matrix (Build Time)

1. **Vocabulary size:** ~200 unique words in our game → 200×200 = 40,000 entries. But with threshold (S_ij > 0.3), only ~500-1000 meaningful pairs.
2. **Source of similarities:** Use GTE-tiny embeddings (already available from Issue #176) to compute pairwise cosine similarities between all vocabulary words at build time.
3. **Storage:** A sparse Lua table mapping word pairs to similarity values: `sim["grab"]["take"] = 0.95`
4. **Memory:** ~160KB for the full matrix, much less with sparse representation.

### Runtime Scoring (Query Time)

```lua
-- Lua soft cosine implementation sketch
local function soft_cosine_score(query_tokens, phrase_tokens, sim_matrix)
    local numerator = 0
    local norm_q = 0
    local norm_p = 0

    -- Build frequency vectors
    local q_freq, p_freq = {}, {}
    for _, t in ipairs(query_tokens) do q_freq[t] = (q_freq[t] or 0) + 1 end
    for _, t in ipairs(phrase_tokens) do p_freq[t] = (p_freq[t] or 0) + 1 end

    -- Compute soft dot products
    for qi, qf in pairs(q_freq) do
        for pi, pf in pairs(p_freq) do
            local s = get_similarity(qi, pi, sim_matrix) -- returns 1.0 if qi==pi
            if s > 0 then
                numerator = numerator + qf * pf * s
            end
        end
    end

    -- Compute soft norms
    for qi, qf in pairs(q_freq) do
        for qj, qf2 in pairs(q_freq) do
            local s = get_similarity(qi, qj, sim_matrix)
            if s > 0 then norm_q = norm_q + qf * qf2 * s end
        end
    end
    for pi, pf in pairs(p_freq) do
        for pj, pf2 in pairs(p_freq) do
            local s = get_similarity(pi, pj, sim_matrix)
            if s > 0 then norm_p = norm_p + pf * pf2 * s end
        end
    end

    if norm_q == 0 or norm_p == 0 then return 0 end
    return numerator / (math.sqrt(norm_q) * math.sqrt(norm_p))
end
```

### Optimization for Our Scale

- With ~200 vocabulary words, even the naive O(n²) computation per comparison is fast
- For 4,579 phrase candidates: ~4,579 × (|query|² + |query| × |phrase|) operations — well under 1ms
- **Combine with BM25:** Use BM25 for initial ranking (top 50 candidates), then soft cosine for re-ranking

## References Worth Following

- **Charlet & Damnati (2017)** — "SimBow at SemEval-2017" — used soft cosine with Word2Vec for semantic textual similarity, achieving strong results
- **Novotný et al. (2018)** — "Implementation Notes for the Soft Cosine Measure" (arXiv:1808.09407) — detailed implementation guide with complexity analysis and optimizations for Gensim
- **Li & Han (2013)** — "Distance weighted cosine similarity measure for text classification" — related approach of weighting features by distance
- **Jimenez et al. (2010)** — "Text comparison using soft cardinality" — alternative soft matching approach that inspired this work
