# Khattab & Zaharia (2020) — ColBERT

**Category:** SHOULD DOWNLOAD

## Citation

Khattab, O. & Zaharia, M. (2020). "ColBERT: Efficient and Effective Passage Search via Contextualized Late Interaction over BERT." *Proceedings of the 43rd International ACM SIGIR Conference on Research and Development in Information Retrieval*, pp. 39–48. arXiv: [2004.12832](https://arxiv.org/abs/2004.12832)

## Abstract

Recent progress in Natural Language Understanding (NLU) is driving fast-paced advances in Information Retrieval (IR), largely owed to fine-tuning deep language models (LMs) for document ranking. While remarkably effective, ranking models based on these LMs increase computational cost by orders of magnitude over prior approaches. ColBERT introduces a late interaction architecture: it independently encodes the query and document using BERT, then applies a computationally cheap yet powerful step to model their fine-grained similarity. By delaying and localizing the interaction, ColBERT retains the expressiveness of BERT while allowing document representations to be pre-computed offline, substantially accelerating query processing. Extensive evaluation shows ColBERT is competitive with BERT-based models while running up to two orders-of-magnitude faster and requiring up to four orders-of-magnitude fewer FLOPs per query.

## Key Findings Relevant to MMO Parser

- **Late interaction pattern**: encode documents offline, do cheap comparison at query time — mirrors our approach of precomputing phrase data at build time
- **Per-token interaction** between query and document tokens — conceptually similar to our proposed soft matching where we compare each input token against each phrase token using a similarity matrix
- **Pre-computation** of document representations is key to making neural-quality matching fast — validates our offline computation strategy

## Why It Matters to MMO's Tier 2 Parser

ColBERT's architecture pattern (heavy offline processing, lightweight runtime matching) is the exact paradigm we're adopting. While we can't use BERT, the "late interaction" concept — comparing query tokens to pre-encoded document tokens with simple max-similarity operations — is implementable with our precomputed word similarity matrix.

## Access

- arXiv: <https://arxiv.org/abs/2004.12832>
- PDF: <https://people.eecs.berkeley.edu/~matei/papers/2020/sigir_colbert.pdf>
