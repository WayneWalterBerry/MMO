# Han et al. (2025) — GraphRAG

**Category:** SHOULD DOWNLOAD

## Citation

Han, H., Xu, H., Chen, H., et al. (2025). "Retrieval-Augmented Generation with Graphs (GraphRAG)." arXiv: [2501.00309](https://arxiv.org/abs/2501.00309)

## Abstract

Retrieval-augmented generation (RAG) is a powerful technique that enhances downstream task execution by retrieving additional information from external sources. Graphs, by their intrinsic "nodes connected by edges" nature, encode massive heterogeneous and relational information, making them a golden resource for RAG in numerous real-world applications. As a result, there has been increasing attention on equipping RAG with graphs, i.e., GraphRAG. However, unlike conventional RAG, where the retriever, generator, and external data sources can be uniformly designed in the neural-embedding space, the uniqueness of graph-structured data poses unique and significant challenges. The authors present a comprehensive survey on GraphRAG, proposing a holistic framework defining key components including query processor, retriever, organizer, generator, and data source.

## Key Findings Relevant to MMO Parser

- **Hierarchical retrieval** using knowledge graphs improved answer recall and comprehensiveness by ~10–20% on complex queries
- **Two-stage retrieval**: first narrow by entity/relation (e.g., verb category), then search within that subset — could inform a verb-first filtering strategy
- **Context summarization** reduced prompt size by up to 97% while maintaining quality — relevant to keeping our phrase index lean

## Why It Matters to MMO's Tier 2 Parser

GraphRAG's hierarchical search concept directly maps to a two-stage parser strategy: first classify the verb (narrowing to a subset of ~100 phrases per verb), then match the noun within that subset. This would reduce our 4,579-phrase scan to ~100 comparisons, improving both speed and precision. Not immediately implementable but informs future architecture.

## Access

- arXiv: <https://arxiv.org/abs/2501.00309>
- GitHub: <https://github.com/Graph-RAG/GraphRAG/>
