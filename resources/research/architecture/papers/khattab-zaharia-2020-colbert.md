# ColBERT: Efficient and Effective Passage Search via Contextualized Late Interaction over BERT

**Authors:** Omar Khattab, Matei Zaharia
**Year:** 2020
**Venue:** Proceedings of the 43rd International ACM SIGIR Conference on Research and Development in Information Retrieval, pp. 39-48
**URL:** <https://arxiv.org/abs/2004.12832>
**PDF:** <https://people.eecs.berkeley.edu/~matei/papers/2020/sigir_colbert.pdf>
**Code:** <https://github.com/stanford-futuredata/ColBERT>

## Abstract

Recent progress in Natural Language Understanding (NLU) is driving fast-paced advances in Information Retrieval (IR), largely owed to fine-tuning deep language models (LMs) for document ranking. While remarkably effective, the ranking models based on these LMs increase computational cost by orders of magnitude over prior approaches, particularly as they must feed each query-document pair through a massive neural network to compute a single relevance score. To tackle this, we present ColBERT, a novel ranking model that adapts deep LMs (in particular, BERT) for efficient retrieval. ColBERT introduces a late interaction architecture that independently encodes the query and the document using BERT and then employs a cheap yet powerful interaction step that models their fine-grained similarity. By delaying and yet retaining this fine-granular interaction, ColBERT can leverage the expressiveness of deep LMs while simultaneously gaining the ability to pre-compute document representations offline, considerably speeding up query processing. Beyond reducing the cost of re-ranking the documents retrieved by a traditional model, ColBERT's pruning-friendly interaction mechanism enables leveraging vector-similarity indexes for end-to-end retrieval directly from a large document collection. Extensive evaluation shows ColBERT's effectiveness is competitive with existing BERT-based models (and outperforms every non-BERT baseline), while executing two orders-of-magnitude faster and requiring four orders-of-magnitude fewer FLOPs per query.

## Key Algorithm / Methodology

### The Three Paradigms of Neural IR

ColBERT positions itself between two existing approaches:

1. **Cross-encoders (interaction-focused):** Feed query + document together through BERT. Very accurate but very slow -- every query-document pair requires a full BERT forward pass. O(N) BERT calls per query.

2. **Bi-encoders / Dual-encoders (representation-focused):** Encode query and document independently into single vectors. Fast (documents pre-computed) but less accurate -- information bottleneck in single vector.

3. **ColBERT (late interaction):** Encode query and document independently into **per-token** embedding matrices. Interaction happens via cheap MaxSim operation. Best of both worlds.

### Architecture

#### Independent Encoding

Query and document are encoded separately through BERT:

```
E_q = BERT_q(q)    -- query token embeddings: [n_q x d]
E_d = BERT_d(d)    -- document token embeddings: [n_d x d]
```

Where:
- n_q = number of query tokens (padded to fixed length, typically 32)
- n_d = number of document tokens
- d = embedding dimension (typically 128 after linear projection from BERT's 768)

#### Late Interaction: MaxSim Operator

The relevance score is computed via the **MaxSim** operation:

```
S(q, d) = sum_{i=1}^{n_q} max_{j=1}^{n_d} (E_q[i] . E_d[j])
```

For each query token embedding, find the **maximum cosine similarity** with any document token embedding, then sum these maximum similarities.

**Intuition:** Each query token "finds" its best-matching document token. "grab" in the query finds "take" in the document (if their BERT embeddings are similar). This is **token-level soft matching** -- exactly the kind of matching we want.

#### Query Augmentation

ColBERT pads queries with [MASK] tokens to a fixed length (e.g., 32 tokens). These masked tokens act as **soft expansion terms** -- BERT learns to produce useful embeddings for these positions that capture additional matching signals.

#### Training

- Trained with pairwise softmax cross-entropy loss over triples (query, positive passage, negative passage)
- Uses in-batch negatives for efficiency
- Fine-tuned from pre-trained BERT-base

### Efficiency Analysis

| Approach | Encoding Cost | Interaction Cost | Pre-computable |
|----------|--------------|-----------------|----------------|
| Cross-encoder | O(|q| + |d|) per pair | N/A (joint) | No |
| Bi-encoder | O(|q|) + O(|d|) each | O(1) dot product | Yes (documents) |
| **ColBERT** | O(|q|) + O(|d|) each | O(|q| * |d|) MaxSim | **Yes (documents)** |

ColBERT's key efficiency advantage: document embeddings are **pre-computed offline** and stored. At query time, only the query needs encoding (one BERT forward pass), then MaxSim is a simple matrix operation.

- **100x faster** than cross-encoder BERT re-rankers
- **10,000x fewer FLOPs** per query
- Competitive accuracy with cross-encoders

### End-to-End Retrieval

ColBERT can also be used for first-stage retrieval (not just re-ranking):
1. Index all document token embeddings using FAISS (with IVF-PQ compression)
2. For each query token, find approximate nearest neighbor document tokens
3. Aggregate scores per document using MaxSim
4. Return top-K documents

## Results Relevant to Our Parser

### MS MARCO Passage Ranking

| Model | MRR@10 | Recall@50 | Recall@200 |
|-------|--------|-----------|------------|
| BM25 | 0.187 | - | - |
| doc2query | 0.215 | - | - |
| BERT-base (cross-encoder) | 0.349 | - | - |
| **ColBERT** | **0.349** | **0.824** | **0.923** |

ColBERT matches cross-encoder accuracy while being 100x faster.

### TREC CAR

| Model | MRR@10 | Recall@200 |
|-------|--------|------------|
| BM25 | 0.153 | 0.335 |
| **ColBERT** | **0.370** | **0.712** |

### Key Findings

- **Per-token interaction is powerful:** Token-level matching captures fine-grained semantic relationships that single-vector models miss
- **Pre-computation is key:** All document processing happens offline; query-time cost is minimal
- **MaxSim is the right aggregation:** Sum of per-token max similarities is both effective and efficient
- **Soft matching emerges naturally:** BERT embeddings place synonyms near each other, so MaxSim implicitly handles synonym matching

## Implementation Notes for Pure Lua

### What ColBERT Teaches Us

ColBERT's late interaction pattern is **directly applicable** to our parser architecture:

1. **Per-token matching:** Instead of comparing whole phrases as bags-of-words, compare each query token against each phrase token individually. Find the best match for each query word.

2. **Pre-computed phrase representations:** Our phrase index already stores token-level data. We can pre-compute similarity features (BM25 IDF weights, embedding-based similarities) at build time.

3. **MaxSim as a scoring function:** ColBERT's MaxSim is conceptually similar to our planned soft matching. For each input token, find the most similar phrase token:

```lua
-- ColBERT-inspired MaxSim scoring in Lua
-- Using pre-computed word similarity matrix instead of BERT embeddings
function maxsim_score(query_tokens, phrase_tokens, sim_matrix)
    local total = 0
    for _, qt in ipairs(query_tokens) do
        local max_sim = 0
        for _, pt in ipairs(phrase_tokens) do
            local s = get_similarity(qt, pt, sim_matrix)
            if s > max_sim then max_sim = s end
        end
        total = total + max_sim
    end
    return total
end
```

4. **Hybrid approach:** Use BM25 for initial candidate retrieval (like ColBERT uses ANN for first stage), then MaxSim-style soft matching for re-ranking top candidates.

### Key Takeaway

ColBERT validates that **token-level matching with pre-computed representations** is the optimal architecture for balancing accuracy and efficiency. Our soft cosine + BM25 approach follows this same pattern, substituting our pre-computed word similarity matrix for BERT token embeddings.

## References Worth Following

- **Khattab et al. (2020)** -- "ColBERTv2: Effective and Efficient Retrieval via Lightweight Late Interaction" -- improved version with better compression
- **Santhanam et al. (2022)** -- "ColBERTv2" -- further improvements with denoised supervision
- **Hofstatter et al. (2020)** -- "Interpretable & Time-Budget-Constrained Contextualization for Re-Ranking" -- related efficient re-ranking approach
