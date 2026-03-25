# Weinberger et al. (2009) — Feature Hashing

**Category:** SHOULD DOWNLOAD

## Citation

Weinberger, K., Dasgupta, A., Langford, J., Smola, A. & Attenberg, J. (2009). "Feature Hashing for Large Scale Multitask Learning." *Proceedings of the 26th International Conference on Machine Learning (ICML)*, pp. 1113–1120. arXiv: [0902.2206](https://arxiv.org/abs/0902.2206)

## Abstract

Empirical evidence suggests that hashing is an effective strategy for dimensionality reduction and practical nonparametric estimation. In this paper, we provide exponential tail bounds for feature hashing and show that the interaction between random subspaces is negligible with high probability. We demonstrate the feasibility of this approach with experimental results for a new use case — multitask learning with hundreds of thousands of tasks.

## Key Findings Relevant to MMO Parser

- **Hashing trick** projects high-dimensional one-hot vectors into smaller fixed-size space — could compress our token-based representations
- **Mathematical guarantees** on collision bounds — useful if we need to hash-encode phrase tokens for memory efficiency
- **Simple implementation** — a hash function maps features to buckets, incrementing counts

## Why It Matters to MMO's Tier 2 Parser

Lower priority. Our 4,579 phrases with ~14k total tokens are not memory-constrained enough to need feature hashing. However, if the game scales significantly (more verbs, objects, or NPC dialogue), hashing could keep the index compact. The paper is included for completeness as a potential future optimization technique — the research document notes it as an engineering solution rather than an accuracy booster.

## Access

- arXiv: <https://arxiv.org/abs/0902.2206>
- Author PDF: <https://alex.smola.org/papers/2009/Weinbergeretal09.pdf>
