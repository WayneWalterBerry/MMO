# Formal et al. (2021) — SPLADE v2

**Category:** MUST DOWNLOAD

## Citation

Formal, T., Lassance, C., Piwowarski, B. & Clinchant, S. (2021). "SPLADE v2: Sparse Lexical and Expansion Model for Information Retrieval." arXiv: [2109.10086](https://arxiv.org/abs/2109.10086)

## Abstract

In neural Information Retrieval (IR), ongoing research is directed towards improving the first retriever in ranking pipelines. Learning dense embeddings to conduct retrieval using efficient approximate nearest neighbors methods has proven to work well. Meanwhile, there has been a growing interest in learning sparse representations for documents and queries, that could inherit from the desirable properties of bag-of-words models such as the exact matching of terms and the efficiency of inverted indexes. Introduced recently, the SPLADE model provides highly sparse representations and competitive results with respect to state-of-the-art dense and sparse approaches. In this paper, we build on SPLADE and propose several significant improvements in terms of effectiveness and/or efficiency. More specifically, we modify the pooling mechanism, benchmark a model solely based on document expansion, and introduce models trained with distillation. Overall, SPLADE is considerably improved with more than 9% gains on NDCG@10 on TREC DL 2019, leading to state-of-the-art results on the BEIR benchmark.

## Key Findings Relevant to MMO Parser

- **Sparse learned representations** bridge the gap between BM25-style lexical matching and dense neural embeddings — the best of both worlds
- **Document expansion** (adding related terms to documents at index time) is a powerful technique — conceptually identical to our synonym expansion of phrase variants
- **Distillation into sparse models** shows you can capture semantic knowledge in sparse (lexical) form — validates our approach of using GTE-tiny offline to build word similarity data, then using sparse matching at runtime
- **Inverted indexes remain efficient** even with learned sparse representations — our phrase index lookup stays fast

## Why It Matters to MMO's Tier 2 Parser

SPLADE validates the core thesis of our research: **you can achieve near-neural-quality retrieval using sparse/lexical methods enhanced with semantic knowledge**. While we can't run SPLADE itself (it's a neural model), the insight that offline semantic expansion + sparse matching at runtime is competitive with dense retrieval directly supports our planned approach of BM25 + soft matching + synonym expansion. SPLADE's document expansion technique is exactly analogous to what we do with phrase variant generation.

## Access

- arXiv: <https://arxiv.org/abs/2109.10086>
- Naver Labs: <https://europe.naverlabs.com/research/publications/splade-v2/>
