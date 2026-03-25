# Dense Passage Retrieval for Open-Domain Question Answering

**Authors:** Vladimir Karpukhin, Barlas Oguz, Sewon Min, Patrick Lewis, Ledell Wu, Sergey Edunov, Danqi Chen, Wen-tau Yih
**Year:** 2020
**Venue:** Proceedings of EMNLP, pp. 6769-6781
**URL:** <https://arxiv.org/abs/2004.04906>
**Code:** <https://github.com/facebookresearch/DPR>

## Abstract

Open-domain question answering relies on efficient passage retrieval to select candidate contexts, where traditional sparse vector space models, such as TF-IDF or BM25, are the de facto method. In this work, we show that retrieval can be practically implemented using dense representations alone, where embeddings are learned from a small number of questions and passages by a simple dual-encoder framework. When evaluated on a wide range of open-domain QA datasets, our dense retriever outperforms a strong Lucene-BM25 system largely by 9%-19% absolute in terms of top-20 passage retrieval accuracy, and helps our end-to-end QA system establish new state-of-the-art on multiple open-domain QA benchmarks.

## Key Algorithm / Methodology

### The Dual-Encoder Architecture

DPR uses two independent BERT encoders -- one for questions, one for passages:

```
E_Q(q) = BERT_question(q)[CLS]    -- question embedding (768-dim)
E_P(p) = BERT_passage(p)[CLS]     -- passage embedding (768-dim)
```

The [CLS] token's output is used as the dense representation of the entire input.

### Similarity Function

Relevance is measured by **dot product** between question and passage embeddings:

```
sim(q, p) = E_Q(q)^T * E_P(p)
```

**Why dot product over cosine?** Dot product allows the model to learn magnitude-based relevance (a passage with a larger vector norm is generally more relevant), while cosine normalizes this away.

### Training Objective: Contrastive Learning

For a question q with positive passage p+ and negative passages p_1-, p_2-, ..., p_n-:

```
L(q, p+, p1-, ..., pn-) = -log( exp(sim(q, p+)) / (exp(sim(q, p+)) + sum_j exp(sim(q, pj-))) )
```

This is the **negative log-likelihood of the positive passage** among the positive and all negatives -- a softmax cross-entropy loss.

### Negative Sampling Strategies

The paper investigates three types of negatives:

1. **Random negatives:** Random passages from the corpus. Easy to generate but too easy for the model.
2. **BM25 negatives:** Passages that BM25 ranks highly but don't contain the answer. These are **hard negatives** -- lexically similar but semantically wrong.
3. **In-batch negatives:** During training, each question's positive passage serves as a negative for all other questions in the batch. Very efficient -- N questions produce N*(N-1) negative pairs.

**Best combination:** BM25 hard negatives + in-batch negatives together produced the strongest results.

### Retrieval Pipeline

1. **Offline indexing:** Encode all passages in the corpus using BERT_passage. Store as dense vectors.
2. **Online query:** Encode the question using BERT_question. Use FAISS (approximate nearest neighbor) to find top-K most similar passage vectors.
3. **Reading:** Feed retrieved passages to an extractive reader model to extract the answer span.

### FAISS Indexing

- All passage vectors stored in a FAISS index with **HNSW** (Hierarchical Navigable Small World) graph structure
- Supports approximate nearest neighbor search in sub-linear time
- Wikipedia corpus: 21M passages, each a 768-dim vector = ~60GB index

## Results Relevant to Our Parser

### DPR vs. BM25 on Passage Retrieval

| Dataset | BM25 Top-20 Acc | DPR Top-20 Acc | Improvement |
|---------|-----------------|----------------|-------------|
| Natural Questions | 59.1% | 78.4% | **+19.3%** |
| TriviaQA | 66.9% | 79.4% | **+12.5%** |
| WebQuestions | 55.0% | 73.2% | **+18.2%** |
| CuratedTrec | 70.9% | 79.8% | **+8.9%** |
| SQuAD | 68.8% | 63.2% | -5.6% |

**Key insight:** DPR significantly outperforms BM25 on most datasets, but BM25 wins on SQuAD where queries are very similar to passage text (lexical matching sufficient).

### End-to-End QA Results

| System | NQ (EM) | TQA (EM) | WQ (EM) | CT (EM) |
|--------|---------|----------|---------|---------|
| BM25 + BERT reader | 26.5 | 47.1 | 17.7 | 21.3 |
| **DPR + BERT reader** | **41.5** | **56.8** | **42.4** | **49.4** |
| ORQA | 33.3 | 45.0 | 36.4 | 30.1 |

DPR-based system established new state-of-the-art on 4 of 5 benchmarks.

### Ablation: Effect of Training Data Size

DPR trained with only **1,000 question-passage pairs** already significantly outperforms BM25 on Natural Questions. With the full training set (~60K pairs), the gap widens further.

### Ablation: Negative Sampling

| Negative Type | Top-20 Accuracy (NQ) |
|--------------|----------------------|
| Random only | 72.4% |
| BM25 negatives | 76.6% |
| In-batch negatives | 75.6% |
| **BM25 + In-batch** | **78.4%** |

Hard negatives from BM25 are the most impactful single improvement.

## Implementation Notes for Pure Lua

### Why We Can't Use DPR Directly

DPR requires:
1. A BERT model to encode queries at runtime (~110M parameters, ~440MB)
2. GPU inference for reasonable speed
3. A FAISS index of passage embeddings

None of these are feasible in our pure-Lua, zero-dependency runtime.

### What DPR Teaches Us

1. **Dense retrieval establishes the upper bound.** DPR shows what's possible with full neural matching. Our GTE-tiny experiments (Issue #176) confirmed embedding quality: synonyms cluster at 0.97-0.99 cosine similarity.

2. **BM25 remains a strong baseline.** DPR's own results show BM25 is competitive for lexical matching tasks. Enhancing BM25 with soft matching could capture 60-70% of DPR's advantage.

3. **The bi-encoder pattern maps to our architecture:**

| DPR Component | Our Equivalent |
|---|---|
| BERT passage encoder (offline) | GTE-tiny embeddings computed at build time |
| BERT question encoder (online) | Can't do this -- no neural inference at runtime |
| FAISS vector index | Pre-computed similarity matrix (our substitute) |
| Dot product similarity | BM25 + soft cosine (our approximation) |

4. **Hard negatives improve training.** When evaluating our matcher, we should test with adversarial inputs (BM25-hard cases like "take candle" vs. "take candy") rather than just random inputs.

### Pre-computed Similarity as a DPR Substitute

Since we can compute GTE-tiny embeddings at build time but not at runtime, we pre-compute **all pairwise word similarities** and store them as a lookup table:

```lua
-- DPR uses: dot_product(BERT_q("grab"), BERT_p("take"))
-- We substitute: sim_matrix["grab"]["take"] = 0.95  (pre-computed from GTE-tiny)

-- DPR retrieves top-K passages by vector similarity
-- We retrieve top-K phrases by BM25 + soft cosine (using pre-computed similarities)
```

This is the fundamental insight: **pre-compute what you can't compute at runtime**.

### Key Takeaway

DPR confirms that dense retrieval significantly outperforms sparse retrieval for semantic matching. Since we can't do dense retrieval at runtime, our best strategy is to **transfer as much semantic knowledge as possible into our sparse representations** via synonym expansion and soft similarity matrices -- approximating DPR's quality with BM25's efficiency.

## References Worth Following

- **Lewis et al. (2020)** -- RAG paper -- builds directly on DPR for retrieval-augmented generation (see our RAG summary)
- **Xiong et al. (2021)** -- "Approximate Nearest Neighbor Negative Contrastive Learning for Dense Text Retrieval" (ANCE) -- improved DPR training with dynamic hard negatives
- **Qu et al. (2021)** -- "RocketQA: An Optimized Training Approach to Dense Passage Retrieval" -- further DPR improvements
- **Thakur et al. (2021)** -- "BEIR: A Heterogeneous Benchmark for Zero-shot Evaluation of Information Retrieval Models" -- the benchmark showing DPR's weakness on out-of-domain data (where BM25 often wins)
