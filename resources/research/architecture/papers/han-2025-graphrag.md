# Retrieval-Augmented Generation with Graphs (GraphRAG)

**Authors:** Haoyu Han, Yu Wang, Harry Shomer, Kai Guo, Jiayuan Ding, Yongjia Lei, Mahantesh Halappanavar, Ryan A. Rossi, Subhabrata Mukherjee, Xianfeng Tang, Qi He, Zhigang Hua, Bo Long, Tong Zhao, Neil Shah, Amin Javari, Yinglong Xia, Jiliang Tang
**Year:** 2025
**Venue:** arXiv preprint (survey paper)
**URL:** <https://arxiv.org/abs/2501.00309>
**GitHub:** <https://github.com/Graph-RAG/GraphRAG/>

## Abstract

Retrieval-augmented generation (RAG) is a powerful technique that enhances downstream task execution by retrieving additional information, such as knowledge, skills, and tools from external sources. Graph, by its intrinsic "nodes connected by edges" nature, encodes massive heterogeneous and relational information, making it a golden resource for RAG in tremendous real-world applications. As a result, we have recently witnessed increasing attention on equipping RAG with Graph, i.e., GraphRAG. However, unlike conventional RAG, where the retriever, generator, and external data sources can be uniformly designed in the neural-embedding space, the uniqueness of graph-structured data, such as diverse-formatted and domain-specific relational knowledge, poses unique and significant challenges when designing GraphRAG for different domains. Given the broad applicability, the associated design challenges, and the recent surge in GraphRAG, a systematic and up-to-date survey of its key concepts and techniques is urgently desired. Following this motivation, we present a comprehensive and up-to-date survey on GraphRAG. Our survey first proposes a holistic GraphRAG framework by defining its key components, including query processor, retriever, organizer, generator, and data source. Furthermore, recognizing that graphs in different domains exhibit distinct relational patterns and require dedicated designs, we review GraphRAG techniques uniquely tailored to each domain. Finally, we discuss research challenges and brainstorm directions to inspire cross-disciplinary opportunities.

## Key Algorithm / Methodology

### The Holistic GraphRAG Framework

GraphRAG consists of five key components:

#### 1. Query Processor

Preprocesses the user query before retrieval:

```
Q_hat = Omega_Processor(Q)
```

- **Query decomposition:** Break complex queries into sub-queries
- **Query rewriting:** Rephrase queries for better retrieval
- **Entity linking:** Map query entities to graph nodes

#### 2. Retriever

Retrieves relevant content from graph-structured data:

```
C = Omega_Retriever(Q_hat, G)
```

**Graph-specific retrieval methods:**

- **Entity linking + Graph traversal:** Identify relevant entities in the query, then traverse the graph (BFS, DFS, random walk) to find related nodes/edges/subgraphs
- **Embedding-based retrieval:** Encode graph nodes as vectors and use ANN search
- **Hybrid:** Combine structural traversal with semantic matching

**Key graph traversal algorithms used:**
- Breadth-First Search (BFS) for local neighborhoods
- Depth-First Search (DFS) for path finding
- Monte Carlo Tree Search for complex reasoning
- A* search for goal-directed retrieval
- Community detection for topic clustering

#### 3. Organizer

Refines and structures the retrieved content:

```
C_hat = Omega_Organizer(Q_hat, C)
```

- **Re-ranking:** Score and sort retrieved content by relevance
- **Graph pruning:** Remove irrelevant nodes/edges from retrieved subgraphs
- **Context summarization:** Compress large retrieved contexts (up to 97% reduction while maintaining quality)
- **Deduplication:** Remove redundant information

#### 4. Generator

Produces the final answer:

```
A = Omega_Generator(Q_hat, C_hat)
```

- Can be an LLM (prompted with retrieved context)
- Can be a specialized model (trained for the domain)
- Graph structure can be encoded via GNNs before feeding to generator

#### 5. Graph Data Source

The underlying knowledge/document graph:
- **Knowledge graphs:** Triplets (entity, relation, entity)
- **Document graphs:** Documents as nodes, citations/links as edges
- **Scene graphs:** Objects as nodes, spatial relations as edges
- **Social graphs:** Users as nodes, interactions as edges

### Advantages Over Standard RAG

1. **Relational information:** Graphs encode relationships between entities that flat text misses
2. **Multi-hop reasoning:** Can traverse paths to answer complex queries requiring multiple steps
3. **Structural queries:** Can leverage graph topology (e.g., find all entities within 2 hops of entity X)
4. **Context preservation:** Graph structure maintains logical connections between retrieved chunks

### The Two-Stage Retrieval Pattern

GraphRAG commonly uses a **two-stage retrieval** approach:

1. **Stage 1 -- Entity/Category Narrowing:** Use graph structure to narrow to a relevant subgraph (e.g., find all nodes related to "verb: take")
2. **Stage 2 -- Fine-grained Matching:** Within the narrowed subgraph, use semantic matching to find the best specific match

This reduces search space dramatically -- from millions of nodes to hundreds.

## Results Relevant to Our Parser

### Performance Improvements

- Hierarchical retrieval using knowledge graphs improved **answer recall by 10-20%** on complex multi-hop queries
- Context summarization reduced prompt size by **up to 97%** while maintaining answer quality
- Two-stage retrieval (entity narrowing then semantic matching) is both faster and more accurate than flat search

### Domain Applications

The survey covers 10 domains. Most relevant to us:

| Domain | Task | Key Technique |
|--------|------|---------------|
| **Knowledge Graph QA** | Answer factual questions | Entity linking + graph traversal |
| **Document Graph** | Summarization, QA | Chunk-level graphs with citation edges |
| **Reasoning & Planning** | Sequential plan retrieval | Dependency graphs with causal edges |
| **Tool Usage** | Select correct API/tool | Plan graphs with resource dependencies |

The **Reasoning & Planning** domain is directly analogous to our parser's GOAP tier.

### Key Finding for Our Architecture

The most actionable insight: **verb-first filtering** (two-stage retrieval) can reduce our 4,579-phrase scan to ~100 comparisons:

1. **Stage 1:** Classify the verb (which of our 48 verbs?) -- narrows to ~100 phrases per verb
2. **Stage 2:** Match the noun within that subset using BM25/soft cosine

This is essentially GraphRAG's entity linking + subgraph retrieval pattern applied to our command parsing.

## Implementation Notes for Pure Lua

### Two-Stage Parser Architecture (Inspired by GraphRAG)

```lua
-- Stage 1: Verb classification (graph-like narrowing)
local function classify_verb(input_tokens, verb_index)
    local best_verb = nil
    local best_score = 0
    for verb, phrases in pairs(verb_index) do
        local score = bm25_score(input_tokens, {verb}, idf_table, avgdl)
        if score > best_score then
            best_score = score
            best_verb = verb
        end
    end
    return best_verb
end

-- Stage 2: Noun matching within verb subset
local function match_phrase(input_tokens, verb, phrase_index)
    local candidates = phrase_index[verb]  -- only ~100 phrases, not 4,579
    local best_phrase = nil
    local best_score = 0
    for _, phrase in ipairs(candidates) do
        local score = soft_cosine_score(input_tokens, phrase.tokens, sim_matrix)
        if score > best_score then
            best_score = score
            best_phrase = phrase
        end
    end
    return best_phrase
end
```

### Graph Structure for Our Game World

Our game world already has graph-like structure:
- **Rooms** = nodes, **exits** = edges (spatial graph)
- **Objects** = nodes, **containment** = edges (containment graph)
- **Verbs** = nodes, **valid combinations** = edges (action graph)

We could build a lightweight knowledge graph at build time:
- Node: "candle" -- edges: [can_be_lit, is_in:bedroom, made_of:wax]
- Node: "door" -- edges: [can_be_opened, connects:bedroom-hallway, requires:key]

This would enable structured retrieval: "What can I light?" -> traverse "can_be_lit" edges from player's reachable objects.

### Key Takeaway

GraphRAG's hierarchical retrieval pattern maps directly to a **verb-first filtering strategy** that could dramatically improve both speed and accuracy of our parser. Not immediately implementable but informs the next architectural iteration.

## References Worth Following

- **Edge et al. (2024)** -- "From Local to Global: A Graph RAG Approach to Query-Focused Summarization" -- Microsoft's GraphRAG implementation (the original industry system)
- **He et al. (2024)** -- "G-Retriever: Retrieval-Augmented Generation for Textual Graph Understanding" -- combining GNNs with LLMs for graph QA
- **Jiang et al. (2023)** -- "StructGPT: A General Framework for Large Language Model to Reason over Structured Data" -- using LLMs to query structured data
