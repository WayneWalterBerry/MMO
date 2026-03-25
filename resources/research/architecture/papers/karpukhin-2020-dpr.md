# Karpukhin et al. (2020) — Dense Passage Retrieval (DPR)

**Category:** SHOULD DOWNLOAD

## Citation

Karpukhin, V., Oğuz, B., Min, S., Lewis, P., Wu, L., Edunov, S., Chen, D. & Yih, W. (2020). "Dense Passage Retrieval for Open-Domain Question Answering." *Proceedings of EMNLP*, pp. 6769–6781. arXiv: [2004.04906](https://arxiv.org/abs/2004.04906)

## Abstract

Open-domain question answering requires retrieving relevant text passages from a large corpus and then extracting the answer. Recent approaches combine powerful pretrained language models for answer extraction with sparse retrieval techniques such as TF-IDF or BM25 for passage retrieval. The authors present Dense Passage Retrieval (DPR) — a set of simple and effective neural models for open-domain QA that can be trained end-to-end from question-answer pairs. The system encodes questions and passages independently into dense vectors, such that relevant passages can be retrieved using maximum inner product search. DPR significantly outperforms state-of-the-art retrieval-based baselines on multiple open-domain QA benchmarks.

## Key Findings Relevant to MMO Parser

- **Dense retrieval outperforms BM25** on semantic matching tasks where paraphrasing is common — confirms our GTE-tiny results showing high-quality embeddings (but we can't produce query vectors at runtime)
- **Independent encoding** of queries and passages (bi-encoder architecture) — the same pattern we use with precomputed phrase embeddings
- **BM25 remains a strong baseline** — DPR beats it, but BM25 is competitive, especially when augmented with expansion techniques

## Why It Matters to MMO's Tier 2 Parser

DPR establishes the upper bound for what dense retrieval can achieve. Our embedding research (Issue #176) already showed GTE-tiny vectors cluster synonyms at 0.97-0.99 similarity — the quality is there, but we can't encode queries at runtime. DPR's results justify investing in BM25 + soft matching as the best non-neural approximation: if we can capture even 60-70% of the dense retrieval advantage through soft similarity matrices and synonym expansion, we'll significantly exceed our current 68%.

## Access

- arXiv: <https://arxiv.org/abs/2004.04906>
