# Carbonell & Goldstein (1998) — Maximal Marginal Relevance (MMR)

**Category:** SHOULD DOWNLOAD

## Citation

Carbonell, J. & Goldstein, J. (1998). "The Use of MMR, Diversity-Based Reranking for Reordering Documents and Producing Summaries." *Proceedings of the 21st Annual International ACM SIGIR Conference on Research and Development in Information Retrieval*, pp. 335–336.

## Abstract

This paper presents a method for combining query-relevance with information-novelty in the context of text retrieval and summarization. The Maximal Marginal Relevance (MMR) criterion strives to reduce redundancy while maintaining query relevance in re-ranking retrieved documents and in selecting appropriate passages for text summarization. Preliminary results indicate some benefits for MMR diversity ranking in document retrieval and in single document summarization. However, the clearest advantage is demonstrated in constructing non-redundant multi-document summaries, where MMR results are clearly superior to non-MMR passage selection.

## Key Findings Relevant to MMO Parser

- **MMR balances relevance and novelty** — when multiple phrase variants match, MMR-style ranking could ensure we consider diverse interpretations rather than redundant near-duplicates
- **Redundancy reduction** is key for compact index design — if we want to prune our 4,579 phrases to a minimal covering set, MMR provides a principled selection algorithm
- **Reranking** technique applicable after initial BM25 retrieval — could be used as a tiebreaker when multiple commands score similarly

## Why It Matters to MMO's Tier 2 Parser

MMR is relevant to two aspects: (1) **index optimization** — selecting a diverse, non-redundant subset of phrase variants that maximizes coverage of player phrasings, and (2) **disambiguation** — when multiple commands match similarly, preferring the most distinct/relevant match. Lower priority than BM25/soft-cosine but useful for polish.

## Access

- CMU PDF: <https://www.cs.cmu.edu/afs/.cs.cmu.edu/Web/People/jgc/publication/MMR_DiversityBased_Reranking_SIGIR_1998.pdf>
