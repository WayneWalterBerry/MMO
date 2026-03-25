# Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks

**Authors:** Patrick Lewis, Ethan Perez, Aleksandra Piktus, Fabio Petroni, Vladimir Karpukhin, Naman Goyal, Heinrich Küttler, Mike Lewis, Wen-tau Yih, Tim Rocktäschel, Sebastian Riedel, Douwe Kiela
**Year:** 2020
**Venue:** Advances in Neural Information Processing Systems (NeurIPS), 33, 9459–9474
**URL:** <https://arxiv.org/abs/2005.11401>

## Abstract

Large pre-trained language models have been shown to store factual knowledge in their parameters, and achieve state-of-the-art results when fine-tuned on downstream NLP tasks. However, their ability to access and precisely manipulate knowledge is still limited, and hence on knowledge-intensive tasks, their performance lags behind task-specific architectures. Additionally, providing provenance for their decisions and updating their world knowledge remain open research problems. Pre-trained models with a differentiable access mechanism to explicit non-parametric memory can overcome this issue, but have so far been only investigated for extractive downstream tasks. We explore a general-purpose fine-tuning recipe for retrieval-augmented generation (RAG) — models which combine pre-trained parametric and non-parametric memory for language generation. We introduce RAG models where the parametric memory is a pre-trained seq2seq model and the non-parametric memory is a dense vector index of Wikipedia, accessed with a pre-trained neural retriever. We compare two RAG formulations, one which conditions on the same retrieved passages across the whole generated sequence, the other can use different passages per token. We fine-tune and evaluate our models on a wide range of knowledge-intensive NLP tasks and set the state-of-the-art on three open domain QA tasks, outperforming parametric seq2seq models and task-specific retrieve-and-extract architectures. For language generation tasks, we find that RAG models generate more specific, diverse and factual language than a state-of-the-art parametric-only seq2seq baseline.

## Key Algorithm / Methodology

### Architecture Overview

RAG combines two components:
1. **Retriever** p_η(z|x): Given input x, retrieves top-K relevant documents z from a non-parametric memory (document index)
2. **Generator** p_θ(y_i|x, z, y_{1:i-1}): Generates output tokens conditioned on input x, retrieved document z, and previous tokens

The retrieved document is treated as a **latent variable** that is marginalized over.

### RAG-Sequence Model

Uses the **same retrieved document** for the entire generated sequence:

```
p_RAG-Sequence(y|x) ≈ Σ_{z ∈ top-k} p_η(z|x) * Π_i p_θ(y_i|x, z, y_{1:i-1})
```

- Retrieves K documents, generates full sequence for each, then marginalizes
- Better for tasks requiring consistent reasoning from a single source

### RAG-Token Model

Can use a **different document for each generated token**:

```
p_RAG-Token(y|x) ≈ Π_i Σ_{z ∈ top-k} p_η(z|x) * p_θ(y_i|x, z, y_{1:i-1})
```

- At each token position, marginalizes over all K retrieved documents
- Better for combining information from multiple sources

### Retriever Component (DPR-based)

The retriever uses a bi-encoder architecture (Dense Passage Retrieval):

```
p_η(z|x) ∝ exp(d(z)^T · q(x))
```

Where:
- `d(z) = BERT_d(z)` — document embedding from a BERT document encoder
- `q(x) = BERT_q(x)` — query embedding from a BERT query encoder
- Top-K retrieval is a Maximum Inner Product Search (MIPS) problem, solved approximately using FAISS

### Generator Component (BART)

- BART-large (400M parameters) pre-trained seq2seq transformer
- Input x and retrieved document z are simply **concatenated** as input to BART
- BART's parameters constitute the "parametric memory"

### Training

- Jointly train retriever and generator end-to-end
- Minimize negative marginal log-likelihood: `Σ_j -log p(y_j|x_j)`
- **Document encoder (BERT_d) is fixed** — updating it would require re-indexing all documents
- Only the **query encoder (BERT_q) and BART generator** are fine-tuned
- Stochastic gradient descent with Adam optimizer

### Decoding

- **RAG-Token:** Standard autoregressive beam search (marginalize over documents at each step)
- **RAG-Sequence:** Run beam search per document, collect hypotheses, then marginalize. Two variants:
  - *Thorough Decoding:* Run extra forward passes for completeness
  - *Fast Decoding:* Approximate p_θ(y|x,z_i) ≈ 0 for hypotheses not generated from z_i

### Non-Parametric Memory (Document Index)

- Wikipedia dump (December 2018), split into 100-word chunks → **21 million documents**
- Each document embedded with BERT_d and indexed with FAISS (HNSW approximation)
- **Hot-swappable:** Can replace the index at test time to update world knowledge without retraining
  - Demonstrated: swapping 2016 ↔ 2018 Wikipedia indexes changed answers about world leaders (70% accuracy with matched index, 4-12% with mismatched)

## Results Relevant to Our Parser

### Open-Domain QA (State of the Art)

| Model | NQ (EM) | TQA (EM) | WQ (EM) | CT (EM) |
|-------|---------|----------|---------|---------|
| DPR (extractive) | 41.5 | 56.8 | 34.6 | 25.9 |
| REALM | 40.4 | - | 40.7 | 46.8 |
| T5-11B (closed-book) | 36.6 | 60.5 | 37.4 | - |
| **RAG-Token** | **44.5** | **56.8** | **45.2** | **50.0** |
| **RAG-Sequence** | 44.2 | 56.1 | 45.5 | 52.2 |

### Generation Quality

| Model | MS-MARCO Rouge-L | Jeopardy Q-BLEU-1 | FEVER 3-way Acc | FEVER 2-way Acc |
|-------|-------------------|---------------------|-----------------|-----------------|
| BART | 38.2 | 19.7 | 64.0 | 81.1 |
| RAG-Token | 40.1 | 22.2 | 72.5 | 89.5 |
| RAG-Sequence | **40.8** | 21.4 | - | - |

### Key Findings

- RAG can generate correct answers even when the answer is **not in any retrieved document** (11.8% of NQ cases)
- Human evaluators found RAG **more factual** than BART in 42.7% of cases (vs. 7.1% for BART)
- RAG generations are **more diverse** (higher distinct n-gram ratios)
- For FEVER fact verification, **BM25 retrieval outperformed dense retrieval** — entity-centric tasks suit lexical matching
- Learned retrieval improved results on all tasks vs. frozen retriever

### Retrieval Ablation

- Replacing DPR with **BM25 retrieval** worked best for FEVER (entity-matching task) but worse for QA
- This validates that **lexical matching (like our BM25 approach) is competitive** for certain task types

## Implementation Notes for Pure Lua

We can't run neural RAG at runtime, but the **architectural pattern** is directly applicable:

1. **Non-parametric memory = our phrase index.** Pre-computed at build time, contains all valid game commands/phrases with their metadata.
2. **Retriever = our Tier 2 matcher.** Instead of MIPS with dense vectors, we use BM25 + soft cosine to retrieve top-K candidate phrases.
3. **Generator = our verb dispatch.** The top-K retrieved phrases inform which verb handler to call and with what arguments.
4. **Marginalization = confidence scoring.** We can weight multiple candidate matches and choose the best, or detect ambiguity when top candidates are close in score.
5. **Hot-swappable index = level loading.** When the player moves to a new level, we load a new phrase index without changing engine code.

### Conceptual Mapping

| RAG Component | Our Parser Equivalent |
|---|---|
| BERT query encoder | Preprocessing pipeline (tokenize, normalize, expand) |
| FAISS document index | Phrase index (pre-built keyword → phrase mappings) |
| Top-K retrieval | BM25 scoring → top candidates |
| BART generator | Verb handler dispatch |
| Parametric memory | Engine's verb handler logic |
| Non-parametric memory | Phrase index + object metadata |

## References Worth Following

- **Karpukhin et al. (2020)** — DPR paper (the retriever used by RAG) — see our DPR summary
- **Lewis et al. (2019)** — BART pre-training paper — the generator architecture
- **Guu et al. (2020)** — REALM — pre-trained with retrieval-augmented masked language modeling
- **Izacard & Grave (2021)** — Fusion-in-Decoder — alternative approach of fusing multiple retrieved documents in the decoder
