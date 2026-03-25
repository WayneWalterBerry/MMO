# SPLADE v2: Sparse Lexical and Expansion Model for Information Retrieval

**Authors:** Thibault Formal, Carlos Lassance, Benjamin Piwowarski, Stephane Clinchant
**Year:** 2021
**Venue:** arXiv preprint (presented at SIGIR workshops)
**URL:** <https://arxiv.org/abs/2109.10086>
**Code:** <https://github.com/naver/splade>

## Abstract

In neural Information Retrieval (IR), ongoing research is directed towards improving the first retriever in ranking pipelines. Learning dense embeddings to conduct retrieval using efficient approximate nearest neighbors methods has proven to work well. Meanwhile, there has been a growing interest in learning sparse representations for documents and queries, that could inherit from the desirable properties of bag-of-words models such as the exact matching of terms and the efficiency of inverted indexes. Introduced recently, the SPLADE model provides highly sparse representations and competitive results with respect to state-of-the-art dense and sparse approaches. In this paper, we build on SPLADE and propose several significant improvements in terms of effectiveness and/or efficiency. More specifically, we modify the pooling mechanism, benchmark a model solely based on document expansion, and introduce models trained with distillation. Overall, SPLADE is considerably improved with more than 9% gains on NDCG@10 on TREC DL 2019, leading to state-of-the-art results on the BEIR benchmark.

## Key Algorithm / Methodology

### Core Idea: Learned Sparse Representations

SPLADE bridges the gap between **traditional sparse retrieval** (BM25, TF-IDF) and **dense neural retrieval** (DPR, ColBERT) by learning **sparse high-dimensional vectors** that:
- Are aligned with vocabulary tokens (interpretable -- each dimension is a word)
- Are extremely sparse (most entries are zero)
- Can be stored in and retrieved from **inverted indexes** (like BM25)
- Capture semantic relationships (not just lexical matches)

### Architecture

#### Input Encoding (BERT-based)

Both queries and documents are passed through a BERT transformer encoder:

```
H = BERT(input_tokens)   -- H is [seq_len x hidden_dim]
```

#### MLM Head for Term Importance

SPLADE reuses BERT's **Masked Language Model (MLM) head** to produce a distribution over the entire vocabulary for each input token position:

```
w_ij = MLM_head(h_i)[j]   -- importance of vocab term j at position i
```

This means each token position produces a score for every word in the vocabulary -- enabling **document expansion** (generating importance weights for terms not present in the input).

#### Pooling: Max over Positions (v2 Improvement)

SPLADE v2 uses **max pooling** across all token positions to get a single importance weight per vocabulary term:

```
w_j = max_i(log(1 + ReLU(w_ij)))   -- for each vocab term j, take max across all positions i
```

- **SPLADE v1** used sum pooling (less effective)
- The `log(1 + ReLU(...))` transformation ensures non-negative weights with controlled magnitude
- Max pooling was inspired by SPARTA and EPIC models

#### Sparse Regularization (FLOPS Regularizer)

To enforce sparsity, SPLADE adds a **regularization loss** that penalizes non-zero entries:

```
L_sparse = sum_j (mean_i(w_ij))^2    -- "FLOPS" regularizer
```

This encourages the model to use **few non-zero entries** while keeping important term weights high. The strength of regularization controls the sparsity/effectiveness trade-off.

#### Total Training Loss

```
L_total = L_ranking + lambda * (L_sparse_query + L_sparse_document)
```

Where L_ranking is a standard contrastive/distillation ranking loss.

### Document Expansion: The Key Insight

The most powerful aspect of SPLADE is **learned document expansion**:

1. A document about "machine learning" might get non-zero weights for terms like "AI", "neural", "classifier" -- even if those exact words don't appear in the document
2. This is conceptually **identical** to our planned synonym expansion, but learned end-to-end instead of hand-crafted
3. The expansion happens at **index time** (offline) -- no computational cost at query time

### SPLADE-doc Variant (Document-Only Encoding)

A variant where **only the document** is encoded through the neural model:
- Documents are expanded and indexed offline
- Queries are processed with simple bag-of-words
- Even faster at query time -- the neural model only runs during indexing
- Still outperforms BM25 significantly

### Training Enhancements in v2

1. **Knowledge Distillation:** Train SPLADE using a powerful cross-encoder teacher model (e.g., MonoT5). The student (SPLADE) learns to mimic the teacher's relevance judgments.
2. **Hard Negative Mining:** Instead of random negatives, use BM25 or a first-stage retriever to find challenging negatives that are lexically similar but not relevant.
3. **Better Initialization:** Using pre-trained DistilBERT or CoCondenser improves convergence.

### Retrieval with Inverted Index

Since SPLADE outputs are sparse and vocabulary-aligned:
1. Build a standard inverted index: for each vocab term, store a posting list of documents with non-zero weights
2. At query time, look up query terms in the inverted index and accumulate document scores
3. This is the **exact same data structure** as BM25 -- can use the same infrastructure (Lucene, Anserini)

```
score(q, d) = sum_{t in vocab} w_q(t) * w_d(t)
```

Where w_q(t) and w_d(t) are the sparse SPLADE weights for term t in query and document respectively.

## Results Relevant to Our Parser

### TREC Deep Learning 2019

| Model | NDCG@10 | MRR@10 |
|-------|---------|--------|
| BM25 | 0.506 | 0.860 |
| DocT5Query (doc expansion) | 0.627 | - |
| DPR | 0.622 | - |
| ColBERT | 0.695 | - |
| SPLADE v1 | 0.684 | 0.916 |
| **SPLADE v2 (distill)** | **0.729** | **0.946** |

SPLADE v2 achieves **+44% improvement over BM25** on NDCG@10.

### BEIR Benchmark (Out-of-Domain Generalization)

SPLADE v2 achieves **state-of-the-art results on BEIR**, outperforming both dense and other sparse models on average across 13 diverse retrieval tasks. This demonstrates strong **zero-shot transfer** -- the model generalizes to unseen domains.

### Key Findings

- Sparse learned representations **match or exceed** dense retrieval quality while maintaining inverted-index efficiency
- **Document expansion alone** (without query expansion) captures most of the benefit
- Distillation from cross-encoders provides the largest single improvement
- Sparsity can be tuned: sparser models are faster but slightly less effective

## Implementation Notes for Pure Lua

We can't run SPLADE's neural model, but the **conceptual framework** validates our approach:

### What SPLADE Teaches Us

1. **Document expansion at index time is the winning strategy.** SPLADE's biggest gains come from adding semantically related terms to documents offline. This is exactly what our synonym expansion does.

2. **Sparse representations + inverted indexes are competitive with dense retrieval.** We don't need dense vectors at runtime. A well-expanded sparse index with BM25 scoring can approach neural-quality matching.

3. **The inverted index architecture works.** Our phrase index (keyword to phrase mappings) is essentially an inverted index. SPLADE validates that this architecture, enhanced with expansion, is state of the art.

### Practical Application to Our Parser

```lua
-- Our phrase expansion is conceptually identical to SPLADE's document expansion
-- SPLADE does it with a neural MLM head; we do it with a synonym table

-- SPLADE approach (what the neural model learns):
-- "take candle" -> {take: 0.9, grab: 0.7, get: 0.6, seize: 0.4, candle: 1.0, taper: 0.3}

-- Our equivalent (build-time synonym expansion):
-- "take candle" -> indexed under: ["take candle", "grab candle", "get candle", "seize candle"]

-- Both achieve the same goal: matching "grab candle" to "take candle"
-- SPLADE uses learned continuous weights; we use binary expansion
-- For our small vocabulary (~200 words), hand-crafted synonyms may actually be MORE precise
```

### Key Takeaway

SPLADE proves that **BM25 + offline expansion** is a viable alternative to dense neural retrieval. Our planned approach (BM25 scoring + synonym expansion + soft cosine re-ranking) follows the same philosophy and should capture the majority of the benefit.

## References Worth Following

- **Formal et al. (2021)** -- "SPLADE: Sparse Lexical and Expansion Model for First Stage Ranking" (SIGIR 2021) -- the original SPLADE v1 paper with more theoretical foundations
- **Nogueira et al. (2019)** -- "Document Expansion by Query Prediction" (DocT5Query) -- earlier work on neural document expansion using T5
- **MacAvaney et al. (2020)** -- "Expansion via Prediction of Importance with Contextualization" (EPIC) -- related approach that inspired SPLADE's pooling
- **Dai & Callan (2020)** -- "Context-Aware Term Weighting for First-Stage Passage Retrieval" (DeepCT) -- learning term weights from BERT for BM25-style retrieval
