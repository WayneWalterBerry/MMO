# Paper Index — RAG & Context-Packing Parser Research

> Source document: `resources/research/architecture/Applying RAG & Context-Packing Techniques to a Text Adventure Parser.md` (78 KB)
>
> Compiled by Frink (Researcher) — 2026-07-24

---

## MUST DOWNLOAD — Directly Applicable Techniques

These papers describe techniques we can implement in pure Lua to improve Tier 2 beyond 68% Jaccard accuracy.

| # | Paper | File | One-Line Summary |
|---|-------|------|-----------------|
| 1 | Robertson & Zaragoza (2009) | `robertson-zaragoza-2009-bm25.md` | BM25 scoring formula — the #1 replacement for Jaccard, weights rare tokens higher |
| 2 | Sidorov et al. (2014) | `sidorov-2014-soft-cosine.md` | Soft cosine measure — partial credit for similar words using a precomputed matrix |
| 3 | Lu et al. (2015) | `lu-2015-wordnet-query-expansion.md` | WordNet synonym expansion for code search — 5% precision + 8% recall gains |
| 4 | Lewis et al. (2020) | `lewis-2020-rag.md` | RAG foundational paper — retrieval + generation outperforms either alone by 8–15 pts |
| 5 | Formal et al. (2021) | `formal-2021-splade-v2.md` | SPLADE v2 — sparse learned representations bridge BM25 and dense embeddings |

## SHOULD DOWNLOAD — Valuable Background

These papers inform design decisions, provide architectural patterns, or cover future optimization paths.

| # | Paper | File | One-Line Summary |
|---|-------|------|-----------------|
| 6 | Khattab & Zaharia (2020) | `khattab-zaharia-2020-colbert.md` | ColBERT — late interaction pattern: heavy offline encoding, cheap runtime matching |
| 7 | Han et al. (2025) | `han-2025-graphrag.md` | GraphRAG — hierarchical retrieval via knowledge graphs, 10–20% recall improvement |
| 8 | Karpukhin et al. (2020) | `karpukhin-2020-dpr.md` | Dense Passage Retrieval — establishes upper bound for dense vs. sparse retrieval |
| 9 | Hinton et al. (2015) | `hinton-2015-knowledge-distillation.md` | Knowledge distillation — compress large model knowledge into small representations |
| 10 | Carbonell & Goldstein (1998) | `carbonell-goldstein-1998-mmr.md` | MMR — diversity-based reranking for reducing redundancy in retrieval results |
| 11 | Weinberger et al. (2009) | `weinberger-2009-feature-hashing.md` | Feature hashing — dimensionality reduction for large feature spaces |
| 12 | Banerjee (2025) | `banerjee-2025-copilot-prompt-lifecycle.md` | Copilot Chat prompt pipeline — local indexing + heuristic ranking + context packing |
| 13 | n1n.ai (2026) | `n1n-2026-cursor-codebase-indexing.md` | Cursor's RAG pipeline — Tree-sitter chunking, hybrid retrieval, Merkle tree sync |

## SKIP — Tangential or Not Applicable

These papers are cited in the research document but are not directly useful given our constraints (pure Lua, no runtime neural inference, ~4.6K phrase index).

| Paper | Reason to Skip |
|-------|---------------|
| Indyk & Motwani (1998) — LSH | Performance optimization; our 4.6K index doesn't need sub-linear search |
| Broder (1997) — MinHash | Near-duplicate detection for web pages; not applicable at our scale |
| Sahlgren (2005) — Random Indexing | Inferior to learned embeddings; our bag-of-word-vectors test already scored 45% |
| Sanh et al. (2019) — DistilBERT | Requires neural runtime; violates no-runtime-ML constraint |
| Turc et al. (2019) — Knowledge Distillation for BERT | Same neural runtime constraint |
| Porter (1980) — Stemming Algorithm | Well-known; implementation trivial from documentation, no paper needed |
| Chaudhuri et al. (2006) — Weighted Jaccard | Superseded by BM25 and soft cosine in our context |
| Cohen et al. (2003) — Soft TF-IDF | Older technique; Sidorov (2014) provides more modern formulation |
| Rocchio (1971) — Relevance Feedback | Classic technique; concept is simple enough without the paper |
| Zhai & Lafferty (2001) — Term Reweighting | Covered adequately by Robertson & Zaragoza's BM25 monograph |
| Marchand & Shawe-Taylor (2002) — Set Covering Machine | Theoretical; set cover is NP-hard, we'll use greedy heuristics |
| Johnson-Lindenstrauss (1984) — Dimensionality Reduction Lemma | Theoretical foundation only; not directly implementable |
| Salakhutdinov & Hinton (2008) — Semantic Hashing | Requires autoencoder; violates no-runtime-ML constraint |
| Andoni et al. (2015) — LSH + Product Quantization | Performance optimization; not needed at our scale |
| Zhao et al. (2014) — Short Text Similarity Survey | Survey; specific techniques (BM25, soft cosine) already covered |
| Bronda-Ecraela & Doctora (2024) — BM25+Jaccard | Minor study confirming BM25 > Jaccard; Robertson covers this better |

## Technical Blog References (also cited)

| Source | URL | Relevance |
|--------|-----|-----------|
| Islam (2026) — "How BM25 and RAG Retrieve Information Differently" | <https://www.marktechpost.com/2026/03/22/how-bm25-and-rag-retrieve-information-differently/> | Accessible BM25 vs. dense retrieval comparison |
| Seiwan-Maikuma — "Deep Dive into Copilot Agent Mode Prompt Structure" | <https://dev.to/seiwan-maikuma/a-deep-dive-into-github-copilot-agent-modes-prompt-structure-2i4g> | System/context/user layer architecture |
| Towards Data Science — "GraphRAG in Practice" | <https://towardsdatascience.com/graphrag-in-practice-how-to-build-cost-efficient-high-recall-retrieval-systems/> | Practical GraphRAG implementation patterns |
| Towards Data Science — "How Cursor Actually Indexes Your Codebase" | <https://towardsdatascience.com/how-cursor-actually-indexes-your-codebase/> | Cursor's structural chunking + metadata filtering |

---

## Implementation Priority (from research document)

1. **Synonym/Paraphrase Expansion** (offline) — papers #3, #5
2. **Soft Similarity Matching** — paper #2, informed by #9
3. **BM25/Inverted Index** — paper #1
4. **Contextual Ranking Heuristics** — papers #12, #13, #10
5. **Advanced Techniques** (future) — papers #6, #7, #8, #11

## Estimated Combined Impact

Current accuracy: ~68% (Jaccard Tier 2)
Projected with all MUST techniques: ~75–82%
Projected with MUST + SHOULD context heuristics: ~80–85%
