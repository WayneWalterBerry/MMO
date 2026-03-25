# Parser Improvement Plan: Tier 2 Accuracy Roadmap

**Author:** Frink (Researcher), updated by Smithers (UI/Parser)  
**Date:** 2026-03-29 (updated 2026-03-25)  
**Status:** PHASES 1-3 SHIPPED — Ongoing improvements  
**Requested by:** Wayne Berry (Effe)  

---

## Current State (2026-03-25)

### Benchmark Results

**Expanded benchmark:** 134/147 cases passing = **91.2% accuracy**  
**Baseline (pre-improvement):** 83.7% on 147 cases (Nelson's expanded benchmark)

### Shipped Phases

| Phase | Status | What Shipped | Accuracy |
|-------|--------|-------------|----------|
| **Phase 1** | ✅ DONE | BM25 scoring, IDF weighting, inverted index | 68% → ~78% |
| **Phase 2** | ✅ DONE | Synonym table (40+ mappings), typo correction with IDF guard | ~78% → ~84% |
| **Phase 3** | ✅ DONE | Context-aware recency boost, state-variant tiebreaker | ~84% → 89% |
| **#242-244 fixes** | ✅ DONE | peer/check→examine synonyms, context boost in BM25 path, noun_tokens | 84% → 89% |
| **Typo tightening** | ✅ DONE | Tighter Levenshtein thresholds (4→d1, 5→d1, 6+→d2), snag/show synonyms | 89% → 91.2% |

### Remaining Failures (13/147)

Categorized by root cause and prioritized by fix impact:

| Priority | Category | Count | Root Cause | Example |
|----------|----------|-------|-----------|---------|
| **P1** | False positives (unknown nouns) | 6 | BM25 matches verb-only when noun isn't in index. "eat the dragon" → "eat portrait" | E-131..E-147 |
| **P2** | BM25 dilution on verbose input | 2 | Stop words removed but many noise tokens remain. Long inputs dilute BM25 signal | C-98, C-99 |
| **P3** | Question pattern routing | 1 | "what is the candle" → "what can i do" (help). Needs question→examine transform | B-75 |
| **P4** | Noun resolution (bed vs bed-sheets) | 1 | "hit bed" matches "hit bed sheets" because "bed" is a substring | F-14 |
| **P5** | Adjective-only matching | 2 | "get small" / "get something small" false-matches "get a small knife" | A-47, C-100 |
| **P6** | Edge cases | 1 | "match match" (duplicate word) resolves to drop instead of ignite | C-97 |

### Recommended Next Improvements (by impact)

1. **Noun validation gate** (P1, est. +6 cases) — Require that at least one input noun token matches a phrase's noun_tokens before accepting the match. This prevents verb-only matches against unrelated nouns. Uses the noun_tokens field now populated on all phrases.

2. **Question transform expansion** (P3, est. +1 case) — Add "what is X" → "examine X" to the questions.lua transform pipeline. Currently only handles "what can I do" → help.

3. **Adjective-only false positive guard** (P5, est. +2 cases) — When input after stop-word removal contains only adjectives (words in IDF that aren't verbs or nouns), suppress the match. "get small" should be rejected.

4. **Verbose input truncation** (P2, est. +2 cases) — For inputs exceeding N tokens after stop-word removal, keep only the first verb + nearest noun tokens, discarding noise. Prevents BM25 dilution on long player input.

5. **Noun prefix matching** (P4, est. +1 case) — When noun candidates tie, prefer shorter nouns that are exact prefixes of the input ("bed" over "bed-sheets" for input "hit bed").

---

## Original Plan (Historical — Phases 1-3 below are now shipped)

---

## 1. Current Parser Architecture

### 1.1 Tier 2 (Jaccard Matcher) — The Bottleneck

**File:** `src/engine/parser/embedding_matcher.lua`  
**Lines:** 210-251 (`match()` function)

**Current Algorithm:**
```lua
-- Jaccard index with substring bonus
function jaccard_with_bonus(input_tokens, phrase_tokens)
    local intersection = 0
    local partial = 0
    
    -- Exact token matches
    for t in pairs(set_a) do
        if set_b[t] then intersection = intersection + 1 end
    end
    
    -- Substring/prefix bonus (3+ char overlap)
    for _, a in ipairs(input_tokens) do
        for _, b in ipairs(phrase_tokens) do
            if a:sub(1,3) == b:sub(1,3) and #a >= 3 and #b >= 3 then
                partial = partial + (overlap / max_len) * 0.5
            end
        end
    end
    
    return (intersection + partial) / union_size
end
```

**Problems:**
1. **All tokens treated equally** — "the" has same weight as "candle"
2. **No synonym awareness** — "grab" and "take" have zero similarity
3. **Bag-of-words only** — no phrase structure awareness
4. **Linear scan** — compares input against all 4,579 phrases (fast enough, but wasteful)
5. **Threshold too low** — 0.40 acceptance threshold causes false positives

**Hit Rate:** ~20% additional coverage beyond Tier 1 (11-12 out of 60 test cases)

### 1.2 Tier 1 (Preprocessing Pipeline)

**Files:**
- `src/engine/parser/questions.lua` — 74 question patterns → commands
- `src/engine/parser/idioms.lua` — 89 idiom patterns → canonical forms
- `src/engine/parser/preprocess.lua` — 7-stage normalization pipeline

**Performance:** ~48% hit rate on test inputs (exact verb match + pattern transforms)

**Integration:** Tier 2 only fires when Tier 1 misses — no interference risk.

### 1.3 Tiers 3-5 (Context, GOAP, Fuzzy)

**Files:**
- `src/engine/parser/context.lua` — Recent object stack for pronouns ("it", "that")
- `src/engine/parser/fuzzy.lua` — Material/property/typo resolution
- (GOAP not yet implemented)

**Coverage:** Handles ~5-10% of edge cases (pronouns, typos, "the wooden thing")

### 1.4 Phrase Index

**File:** `src/assets/parser/embedding-index.json` (15.3 MB)

**Structure:**
```json
{
  "phrases": [
    {
      "id": 1,
      "text": "break a crude bandage",
      "verb": "break",
      "noun": "bandage"
    },
    ...
  ]
}
```

**Size:** 4,579 phrases (31 verbs × ~74 objects × ~2 state variants)  
**Vocabulary:** ~200 unique tokens (48 verbs, ~150 nouns/adjectives)

---

## 2. Research Findings vs. Reality

### 2.1 BM25 (Okapi) Scoring

**Research ([Robertson & Zaragoza 2009](../resources/research/architecture/papers/robertson-zaragoza-2009-bm25.md)):**

BM25 is the gold standard for lexical retrieval, used in Lucene/Elasticsearch/Solr. Outperforms unweighted Jaccard by 10-20% on short text queries.

**Formula:**
```
score(D, Q) = Σ IDF(q_i) * [ f(q_i, D) * (k1 + 1) ] / [ f(q_i, D) + k1 * (1 - b + b * |D| / avgdl) ]

IDF(q_i) = ln( (N - n(q_i) + 0.5) / (n(q_i) + 0.5) + 1 )
```

Where:
- `f(q_i, D)` = term frequency of query term q_i in document D
- `k1` = TF saturation parameter (1.2-2.0; lower = faster saturation)
- `b` = length normalization (0.75 standard, 0.3-0.5 for short text)
- `N` = total documents (4,579 phrases)
- `n(q_i)` = documents containing term q_i
- `avgdl` = average document length (~3 tokens per phrase)

**Example:**

Input: "get the candle from shelf"  
Phrase: "get candle"

| Token | IDF | Input TF | Phrase TF | BM25 Contribution |
|-------|-----|----------|-----------|-------------------|
| get | 0.52 | 1 | 1 | 0.45 |
| the | 0.01 | 1 | 0 | 0.00 (stop word) |
| candle | 3.81 | 1 | 1 | **3.20** |
| from | 0.15 | 1 | 0 | 0.00 |
| shelf | 2.45 | 1 | 0 | 0.00 |

**BM25 Score:** 3.65 (high — matches the important tokens)

**Jaccard Score:** 2/5 = 0.40 (low — penalized by extra words)

**Our Reality:**

Current Jaccard matcher **ignores term importance**. Input "please take the candle now" scores poorly against "take candle" because 3/5 tokens don't match. BM25 would weight "take" and "candle" heavily (high IDF) and ignore "please", "the", "now" (near-zero IDF).

**Gap:** We need IDF-weighted scoring to handle verbose/polite input gracefully.

**Implementation Path:** Precompute IDF table at build time (200 tokens → 200 entries, ~1KB). Modify `jaccard_with_bonus()` to sum IDF-weighted TF instead of unweighted intersection count.

---

### 2.2 Soft Cosine Measure (Word Similarity Matrix)

**Research ([Sidorov et al. 2014](../resources/research/architecture/papers/sidorov-2014-soft-cosine.md)):**

Soft cosine generalizes standard cosine similarity by incorporating a word-to-word similarity matrix S:

```
soft_cosine(a, b) = Σ_{i,j} (a_i * b_j * S_ij) / (sqrt(Σ_{i,j} a_i * a_j * S_ij) * sqrt(Σ_{i,j} b_i * b_j * S_ij))
```

Where `S_ij` = similarity between word i and word j (from embeddings, WordNet, or manual annotation).

**Properties:**
- When `S_ij = δ_ij` (1 if i=j, 0 otherwise), reduces to standard cosine — **zero regression risk**
- When `S_ij > 0` for synonyms, captures semantic similarity without neural inference

**Example:**

Input: "grab lamp"  
Phrase: "get lamp"

Word similarity matrix:
```
S["grab"]["get"] = 0.95  (synonyms)
S["grab"]["grab"] = 1.0
S["get"]["get"] = 1.0
S["lamp"]["lamp"] = 1.0
```

Standard cosine: Only "lamp" matches → similarity ≈ 0.5  
Soft cosine: "grab"↔"get" have S=0.95, "lamp"↔"lamp" = 1.0 → similarity ≈ **0.97**

**Our Reality:**

Current Jaccard matcher treats "grab" and "take" as **completely unrelated** (similarity = 0). D-KEEP-JACCARD decision (#176) ruled out runtime neural encoding, but **offline word similarity matrices are viable**.

**Gap:** We have GTE-tiny embeddings for all vocabulary words (archived from Issue #176). We can compute pairwise cosine similarities offline and store as a sparse Lua table.

**Implementation Path:**
1. Extract unique vocabulary from phrase index (~200 words)
2. Compute word×word cosine similarity using GTE-tiny embeddings (Python)
3. Threshold S_ij > 0.3, store sparse matrix (~500-1000 pairs, ~80KB)
4. Modify scoring function to use soft matching

---

### 2.3 Synonym Expansion (WordNet Query Expansion)

**Research ([Lu et al. 2015](../resources/research/architecture/papers/lu-2015-wordnet-query-expansion.md)):**

Query expansion using POS-filtered WordNet synonyms improved code search by +5% precision, +8% recall.

**Algorithm:**
```
1. Extract query terms and their POS tags (verb/noun)
2. For each term, retrieve synonyms from WordNet (filtered by matching POS)
3. Add top 2-3 synonyms to query (or expand phrase index offline)
4. Match expanded query/phrases using standard retrieval
```

**Critical insight:** POS filtering prevents wrong-sense expansion:
- "light" (verb) → ignite, kindle (NOT "light" adjective "not heavy")
- "match" (noun) → lighter, fire-starter (NOT "match" verb "to correspond")

**Example:**

Original phrase: "take candle"  
Expanded to:
- "take candle" (original)
- "grab candle" (take → grab)
- "get candle" (take → get)
- "seize candle" (take → seize)
- "take taper" (candle → taper)
- "grab taper" (both expanded)

**Our Reality:**

Current phrase index contains **only** the exact object names and base states. "take candle" is in the index, but "grab candle" is not — instant miss.

**Gap:** No synonym variants in the phrase index. We generate variants via templates at build time, but only cover different phrasings of the **same verb**, not synonym verbs.

**Implementation Path:** Build a manual POS-filtered synonym table (48 verbs, ~150 nouns) and expand phrases at build time. Manageable scale: 4,579 base phrases × 5 synonyms average = ~23K expanded phrases (still < 50ms lookup).

---

### 2.4 ColBERT Late Interaction (Per-Token Matching)

**Research ([Khattab & Zaharia 2020](../resources/research/architecture/papers/khattab-zaharia-2020-colbert.md)):**

ColBERT achieves cross-encoder accuracy with bi-encoder speed via **MaxSim** late interaction:

```
S(q, d) = sum_{i=1}^{n_q} max_{j=1}^{n_d} (E_q[i] · E_d[j])
```

For each query token, find the maximum similarity with any document token, then sum.

**Intuition:** Each query word "finds" its best-matching phrase word. Soft synonym matching emerges naturally if embeddings place synonyms close together.

**Example:**

Input: "grab candle quickly"  
Phrase: "get candle"

MaxSim scoring (using word similarity matrix):
- "grab" → max(sim("grab", "get")=0.95, sim("grab", "candle")=0.0) = **0.95**
- "candle" → max(sim("candle", "get")=0.0, sim("candle", "candle")=1.0) = **1.0**
- "quickly" → max(sim("quickly", "get")=0.0, sim("quickly", "candle")=0.0) = **0.0**

**Total:** 0.95 + 1.0 + 0.0 = **1.95** (strong match despite "quickly" and "grab"≠"get")

**Our Reality:**

Current Jaccard matcher compares **sets** (unordered bags of unique tokens). ColBERT's MaxSim is more granular: per-token best-match aggregation.

**Gap:** We don't track which input token matched which phrase token — just global intersection/union.

**Implementation Path:** Adapt MaxSim for use with soft cosine word similarity matrix. For each input token, find max similarity with any phrase token, sum the maxima. Complements BM25 (BM25 for candidate retrieval, MaxSim for re-ranking top 50).

---

### 2.5 Hybrid Retrieval (Two-Stage Pipeline)

**Research ([Cursor codebase indexing](../resources/research/architecture/papers/n1n-2026-cursor-codebase-indexing.md), [GraphRAG](../resources/research/architecture/papers/han-2025-graphrag.md)):**

Production RAG systems use **hybrid sparse+dense retrieval**:
1. **Stage 1:** Fast lexical filter (BM25, inverted index) to retrieve top-K candidates
2. **Stage 2:** Expensive semantic re-rank (vector similarity, cross-encoder) on candidates only

This combines precision of keyword matching with recall of semantic matching.

**Example (from Cursor):**
1. User types "authentication logic"
2. Keyword index finds files containing "auth", "login", "token" (fast, high precision)
3. Embedding index finds conceptually related files without exact keywords (high recall)
4. Merge + deduplicate top 20 results, pass to LLM

**Our Reality:**

Current matcher does a flat scan: all 4,579 phrases evaluated via Jaccard on every input. No first-pass filtering, no re-ranking.

**Gap:** We could prune 90% of candidates before expensive soft matching by using an inverted index: "Which phrases contain at least one input token?"

**Implementation Path:**
1. Build inverted index at load time: `token → [phrase_id_1, phrase_id_2, ...]`
2. For input "get candle", union the candidate sets: phrases containing "get" OR "candle"
3. Score only those candidates with BM25/soft cosine
4. Reduces scoring from 4,579 phrases to ~200-500 candidates (10x speedup)

---

## 3. Gap Analysis Summary

| Technique | Research Says | Our Reality | Gap | Estimated Gain |
|-----------|--------------|-------------|-----|----------------|
| **BM25 Scoring** | Outperforms Jaccard by 10-20% on short text | We use unweighted Jaccard | No IDF weighting, no TF saturation, no length norm | **+5-7%** |
| **Soft Cosine** | Captures synonym similarity without runtime inference | "grab" and "take" have sim=0 | No word similarity matrix | **+3-5%** |
| **Synonym Expansion** | +5% precision, +8% recall in code search | Only exact object names in index | No synonym variants | **+3-5%** |
| **ColBERT MaxSim** | Per-token matching, 100x faster than cross-encoders | Set-based Jaccard only | No per-token best-match aggregation | **+2-3%** |
| **Hybrid Retrieval** | 10-20% efficiency gain, maintains accuracy | Flat scan of 4,579 phrases | No inverted index, no two-stage pipeline | **0%** (speed only) |
| **Context Ranking** | Cursor uses recent files/symbols for disambiguation | Context window exists but not used in Tier 2 | No recency scoring in phrase matching | **+1-2%** |

**Total Potential Gain:** 14-22% absolute improvement → **Target: 68% → 82-90%**

**Conservative Target (Phase 1+2):** 68% → 80% (+12%)

---

## 4. Prioritized Improvements

### Phase 1: Quick Wins (Target: 68% → 75%, Effort: 1 week)

#### 4.1 BM25 Scoring (Priority 1)

**Effort:** 2-3 days  
**Impact:** +5-7% accuracy  
**Risk:** Low (BM25 is battle-tested, pure math)

**Changes:**

**File:** `src/engine/parser/embedding_matcher.lua`

**Build-time (Python script):**
```python
# scripts/build-idf-table.py
import json, math
from collections import Counter

# Load phrase index
with open("src/assets/parser/embedding-index.json") as f:
    index = json.load(f)

# Tokenize all phrases, count document frequencies
vocab_df = Counter()  # term → doc count
total_docs = len(index["phrases"])
avg_doc_len = 0

for phrase in index["phrases"]:
    tokens = set(phrase["text"].lower().split())
    avg_doc_len += len(tokens)
    for token in tokens:
        vocab_df[token] += 1

avg_doc_len /= total_docs

# Compute IDF for each term
idf_table = {}
for term, df in vocab_df.items():
    idf_table[term] = math.log((total_docs - df + 0.5) / (df + 0.5) + 1)

# Write Lua module
with open("src/engine/parser/bm25_data.lua", "w") as f:
    f.write("return {\n")
    f.write(f"  avg_doc_length = {avg_doc_len},\n")
    f.write(f"  total_docs = {total_docs},\n")
    f.write("  idf = {\n")
    for term, idf in sorted(idf_table.items()):
        f.write(f'    ["{term}"] = {idf:.6f},\n')
    f.write("  }\n}\n")
```

**Runtime (Lua):**
```lua
-- src/engine/parser/embedding_matcher.lua (lines 109-154)
local bm25_data = require("engine.parser.bm25_data")

-- Replace jaccard_with_bonus with BM25 scoring
local function bm25_score(input_tokens, phrase_tokens, k1, b)
    k1 = k1 or 1.2
    b = b or 0.5  -- Lower b for short documents
    local score = 0
    local doc_len = #phrase_tokens
    local avgdl = bm25_data.avg_doc_length
    
    -- Build phrase token frequency map
    local phrase_tf = {}
    for _, t in ipairs(phrase_tokens) do
        phrase_tf[t] = (phrase_tf[t] or 0) + 1
    end
    
    -- Sum IDF-weighted TF for each query term
    for _, qt in ipairs(input_tokens) do
        local tf = phrase_tf[qt] or 0
        if tf > 0 then
            local idf = bm25_data.idf[qt] or 0.5  -- fallback for unknown terms
            local tf_norm = (tf * (k1 + 1)) / (tf + k1 * (1 - b + b * doc_len / avgdl))
            score = score + idf * tf_norm
        end
    end
    
    return score
end

-- In matcher:match(), replace:
--   local score = jaccard_with_bonus(input_tokens, phrase.tokens)
-- With:
--   local score = bm25_score(input_tokens, phrase.tokens)
```

**Testing:**
```lua
-- test/parser/test-bm25.lua
local t = require("test.parser.test-helpers")
local matcher = require("engine.parser.embedding_matcher")

local m = matcher.new("src/assets/parser/embedding-index.json")

t.test("BM25: filler words ignored", function()
    local v, n, score = m:match("please take the candle now")
    t.assert_eq(v, "take")
    t.assert_eq(n, "candle")
    t.assert_gt(score, 0.6, "BM25 should weight 'take' and 'candle' highly")
end)

t.test("BM25: rare terms boosted", function()
    local v1, n1, s1 = m:match("get thing")        -- "thing" is common
    local v2, n2, s2 = m:match("get nightstand")   -- "nightstand" is rare
    t.assert_gt(s2, s1, "Rare term should score higher")
end)

t.summary()
```

**Validation:** Run before/after accuracy on 60-test benchmark. Expected: 41/60 → 45/60 (+4 cases, +7%).

---

#### 4.2 Synonym Expansion (Priority 2)

**Effort:** 1-2 days  
**Impact:** +3-5% accuracy  
**Risk:** Low (manual curation ensures quality)

**Changes:**

**File:** `src/engine/parser/synonym_table.lua` (new)

```lua
-- POS-filtered synonym table (curated manually)
return {
    -- Verbs (only verb synonyms, no other POS)
    take   = {"get", "grab", "pick", "snatch", "seize"},
    get    = {"take", "grab", "fetch", "retrieve"},
    grab   = {"take", "get", "seize", "snatch"},
    open   = {"unlock", "unfasten", "unseal"},
    close  = {"shut", "seal", "fasten"},
    look   = {"examine", "inspect", "observe", "view", "check", "study"},
    examine = {"look", "inspect", "study", "observe"},
    light  = {"ignite", "kindle"},  -- verb sense only
    ignite = {"light", "kindle", "set fire"},
    break  = {"smash", "shatter", "crack", "destroy"},
    strike = {"hit", "whack", "smack", "bash"},
    drop   = {"discard", "ditch", "toss"},
    smell  = {"sniff", "scent"},
    feel   = {"touch", "handle"},
    consume = {"eat", "devour"},
    -- ... (48 verbs total)
    
    -- Nouns (only noun synonyms)
    candle = {"taper"},
    lamp   = {"lantern", "light"},  -- noun sense only
    door   = {"entrance", "portal", "gateway"},
    key    = {"lock pick"},
    match  = {"lighter"},  -- noun sense: fire tool
    -- ... (~150 nouns)
}
```

**Build script:**
```python
# scripts/expand-phrase-index.py
import json

synonyms = __import__("src.engine.parser.synonym_table")  # Load Lua → dict

with open("src/assets/parser/embedding-index.json") as f:
    index = json.load(f)

expanded_phrases = []
next_id = len(index["phrases"]) + 1

for phrase in index["phrases"]:
    expanded_phrases.append(phrase)  # Keep original
    
    verb, noun = phrase["verb"], phrase["noun"]
    verb_syns = synonyms.get(verb, [])
    noun_syns = synonyms.get(noun.split("-")[0], [])  # Handle "candle-lit" → "candle"
    
    # Generate synonym variants
    for v_syn in verb_syns:
        expanded_phrases.append({
            "id": next_id,
            "text": f"{v_syn} {noun}",
            "verb": verb,  # Keep canonical verb for dispatch
            "noun": noun
        })
        next_id += 1
    
    for n_syn in noun_syns:
        expanded_phrases.append({
            "id": next_id,
            "text": f"{verb} {n_syn}",
            "verb": verb,
            "noun": noun  # Keep canonical noun for lookup
        })
        next_id += 1

# Write expanded index
index["phrases"] = expanded_phrases
with open("src/assets/parser/embedding-index-expanded.json", "w") as f:
    json.dump(index, f, indent=2)

print(f"Expanded: {len(index['phrases'])} phrases")
```

**Estimated size:** 4,579 × 5 = ~23K phrases (~1.2 MB JSON, down from 15.3 MB by removing unused embedding vectors)

**Testing:**
```lua
t.test("Synonym: grab → take", function()
    local v, n = m:match("grab candle")
    t.assert_eq(v, "take")  -- Dispatches to canonical verb
    t.assert_eq(n, "candle")
end)

t.test("Synonym: lantern → lamp", function()
    local v, n = m:match("get lantern")
    t.assert_eq(v, "get")
    t.assert_eq(n, "lamp")  -- Resolves to canonical noun
end)
```

---

#### 4.3 Threshold Tuning (Priority 3)

**Effort:** 1 hour  
**Impact:** +1-2% accuracy  
**Risk:** None (just a constant)

**Current:** `parser.THRESHOLD = 0.40` (in `src/engine/parser/init.lua`)

**Problem:** BM25 scores are on a different scale than Jaccard (IDF-weighted sums vs. 0-1 ratios). Current threshold may be too permissive or too strict.

**Solution:** Empirically tune on 60-test benchmark:
1. Run matcher on all 60 inputs with BM25 scoring
2. Plot score distribution for correct vs. incorrect matches
3. Choose threshold that maximizes F1 score (balance precision/recall)

**Expected:** Threshold ≈ 2.0-3.0 for BM25 (not 0.40)

---

### Phase 2: Soft Matching (Target: 75% → 80%, Effort: 1 week)

#### 4.4 Word Similarity Matrix (Priority 4)

**Effort:** 3-5 days  
**Impact:** +3-5% accuracy  
**Risk:** Medium (requires careful integration with BM25)

**Changes:**

**Build script:**
```python
# scripts/build-word-similarity-matrix.py
import json, numpy as np
from sklearn.metrics.pairwise import cosine_similarity

# Load GTE-tiny embeddings (from Issue #176 archive)
with open("resources/research/gte-tiny-embeddings.json") as f:
    embeddings = json.load(f)

# Extract unique vocabulary from phrase index
vocab = set()
with open("src/assets/parser/embedding-index.json") as f:
    for phrase in json.load(f)["phrases"]:
        vocab.update(phrase["text"].lower().split())

# Build vocabulary → embedding mapping
word_vectors = {}
for word in vocab:
    if word in embeddings:
        word_vectors[word] = np.array(embeddings[word])

# Compute pairwise cosine similarity
words = list(word_vectors.keys())
vectors = np.array([word_vectors[w] for w in words])
sim_matrix = cosine_similarity(vectors)

# Threshold and sparsify (only store sim > 0.3)
sparse_sim = {}
for i, w1 in enumerate(words):
    for j, w2 in enumerate(words):
        if i != j and sim_matrix[i][j] > 0.3:
            if w1 not in sparse_sim:
                sparse_sim[w1] = {}
            sparse_sim[w1][w2] = float(sim_matrix[i][j])

# Write Lua module
with open("src/engine/parser/word_similarity.lua", "w") as f:
    f.write("return {\n")
    for w1, sims in sorted(sparse_sim.items()):
        f.write(f'  ["{w1}"] = {{\n')
        for w2, score in sorted(sims.items()):
            f.write(f'    ["{w2}"] = {score:.3f},\n')
        f.write("  },\n")
    f.write("}\n")
```

**Runtime (Lua):**
```lua
-- src/engine/parser/embedding_matcher.lua (add after BM25)
local word_sim = require("engine.parser.word_similarity")

local function get_similarity(w1, w2)
    if w1 == w2 then return 1.0 end
    if word_sim[w1] and word_sim[w1][w2] then
        return word_sim[w1][w2]
    end
    if word_sim[w2] and word_sim[w2][w1] then
        return word_sim[w2][w1]
    end
    return 0.0
end

-- Soft cosine scoring (Sidorov et al. 2014)
local function soft_cosine_score(input_tokens, phrase_tokens)
    -- Build frequency maps
    local q_freq, p_freq = {}, {}
    for _, t in ipairs(input_tokens) do q_freq[t] = (q_freq[t] or 0) + 1 end
    for _, t in ipairs(phrase_tokens) do p_freq[t] = (p_freq[t] or 0) + 1 end
    
    local numerator = 0
    for qi, qf in pairs(q_freq) do
        for pi, pf in pairs(p_freq) do
            local s = get_similarity(qi, pi)
            if s > 0 then
                numerator = numerator + qf * pf * s
            end
        end
    end
    
    -- Compute soft norms (for proper normalization)
    local norm_q, norm_p = 0, 0
    for qi, qf in pairs(q_freq) do
        for qj, qf2 in pairs(q_freq) do
            local s = get_similarity(qi, qj)
            if s > 0 then norm_q = norm_q + qf * qf2 * s end
        end
    end
    for pi, pf in pairs(p_freq) do
        for pj, pf2 in pairs(p_freq) do
            local s = get_similarity(pi, pj)
            if s > 0 then norm_p = norm_p + pf * pf2 * s end
        end
    end
    
    if norm_q == 0 or norm_p == 0 then return 0 end
    return numerator / (math.sqrt(norm_q) * math.sqrt(norm_p))
end
```

**Hybrid scoring (BM25 + soft cosine):**
```lua
-- Two-stage retrieval:
-- 1. BM25 for candidate selection (top 50)
-- 2. Soft cosine for re-ranking

function matcher:match(input_text)
    -- ... (existing tokenization)
    
    -- Stage 1: BM25 scoring on all phrases
    local candidates = {}
    for _, phrase in ipairs(self.phrases) do
        local bm25 = bm25_score(input_tokens, phrase.tokens)
        if bm25 > 1.0 then  -- Pre-filter threshold
            table.insert(candidates, {phrase = phrase, score = bm25})
        end
    end
    
    -- Stage 2: Soft cosine re-ranking on top candidates
    table.sort(candidates, function(a, b) return a.score > b.score end)
    local top_k = math.min(50, #candidates)
    for i = 1, top_k do
        local soft = soft_cosine_score(input_tokens, candidates[i].phrase.tokens)
        candidates[i].score = 0.7 * candidates[i].score + 0.3 * soft  -- Weighted combo
    end
    
    table.sort(candidates, function(a, b) return a.score > b.score end)
    
    if #candidates > 0 then
        local best = candidates[1]
        return best.phrase.verb, best.phrase.noun, best.score, best.phrase.text
    end
    
    return nil, nil, 0, nil
end
```

**Testing:**
```lua
t.test("Soft cosine: grab ≈ take", function()
    local v, n, score = m:match("grab candle")
    t.assert_eq(v, "take")
    t.assert_eq(n, "candle")
    t.assert_gt(score, 0.8, "Soft cosine should match synonyms")
end)

t.test("Soft cosine: no false positives", function()
    local v, n, score = m:match("eat window")  -- Unrelated verb+noun
    t.assert_eq(v, nil, "Should not match unrelated pairs")
end)
```

---

#### 4.5 MaxSim Token Matching (Priority 5)

**Effort:** 2-3 days  
**Impact:** +2-3% accuracy  
**Risk:** Low (complements soft cosine)

**Algorithm (ColBERT-inspired):**
```lua
-- For each input token, find the best-matching phrase token
local function maxsim_score(input_tokens, phrase_tokens)
    local total = 0
    for _, qt in ipairs(input_tokens) do
        local max_sim = 0
        for _, pt in ipairs(phrase_tokens) do
            local s = get_similarity(qt, pt)
            if s > max_sim then max_sim = s end
        end
        total = total + max_sim
    end
    return total
end
```

**Integration:** Use MaxSim as an alternative to soft cosine for re-ranking (A/B test to see which performs better).

---

### Phase 3: Advanced Techniques (Target: 80% → 85%, Effort: 2 weeks)

#### 4.6 Context-Aware Ranking (Priority 6)

**Effort:** 3-5 days  
**Impact:** +1-2% accuracy  
**Risk:** Low (context module already exists)

**Idea:** Boost scores for phrases referencing recently interacted objects.

**Changes:**
```lua
-- src/engine/parser/embedding_matcher.lua (in match())
local context = require("engine.parser.context")

-- After scoring, apply recency boost
for _, candidate in ipairs(candidates) do
    local recency = context.recency_score(candidate.phrase.noun)
    if recency > 0 then
        candidate.score = candidate.score * (1.0 + 0.1 * recency)  -- 10% boost per recency rank
    end
end
```

**Example:** Player just examined "candle". Next input "light it" → "light candle" gets recency boost over "light match".

---

#### 4.7 Inverted Index (Priority 7)

**Effort:** 2-3 days  
**Impact:** 0% accuracy (speed only)  
**Risk:** Low (standard IR technique)

**Build inverted index at load time:**
```lua
-- src/engine/parser/embedding_matcher.lua (in new())
self.inverted_index = {}
for _, phrase in ipairs(self.phrases) do
    for _, token in ipairs(phrase.tokens) do
        if not self.inverted_index[token] then
            self.inverted_index[token] = {}
        end
        table.insert(self.inverted_index[token], phrase)
    end
end
```

**Use for candidate retrieval:**
```lua
-- In match(), replace full scan with inverted lookup
local candidate_set = {}
for _, qt in ipairs(input_tokens) do
    if self.inverted_index[qt] then
        for _, phrase in ipairs(self.inverted_index[qt]) do
            candidate_set[phrase.id] = phrase
        end
    end
end

local candidates = {}
for _, phrase in pairs(candidate_set) do
    local score = bm25_score(input_tokens, phrase.tokens)
    table.insert(candidates, {phrase = phrase, score = score})
end
```

**Expected speedup:** 4,579 phrases → ~200-500 candidates (10x faster)

---

#### 4.8 Adaptive Weighting (Priority 8)

**Effort:** 3-5 days  
**Impact:** +1-2% accuracy  
**Risk:** Medium (requires tuning)

**Idea:** Weight verb tokens higher than noun tokens for disambiguation.

**Implementation (BM25F variant):**
```lua
-- Separate verb and noun fields, apply different weights
local function bm25f_score(input_tokens, phrase)
    local verb_score = bm25_score(input_tokens, {phrase.verb}) * 2.0  -- Verb weight
    local noun_score = bm25_score(input_tokens, phrase.noun:split()) * 1.0  -- Noun weight
    return verb_score + noun_score
end
```

---

## 5. Implementation Phases

### Phase 1: Quick Wins (Week 1)

**Goal:** 68% → 75% accuracy

**Tasks:**
1. **Day 1-2:** Implement BM25 scoring
   - Write `scripts/build-idf-table.py`
   - Modify `embedding_matcher.lua` to use BM25
   - Run before/after tests
2. **Day 3-4:** Build synonym expansion
   - Curate `synonym_table.lua` (48 verbs, ~150 nouns)
   - Write `scripts/expand-phrase-index.py`
   - Regenerate phrase index
3. **Day 5:** Tune threshold
   - Empirical calibration on 60-test benchmark
   - Update `parser.THRESHOLD` in `init.lua`

**Deliverables:**
- ✅ BM25 scorer operational
- ✅ Synonym-expanded phrase index (23K phrases)
- ✅ Threshold tuned for optimal F1
- ✅ Test suite passing with +7% accuracy

---

### Phase 2: Soft Matching (Week 2)

**Goal:** 75% → 80% accuracy

**Tasks:**
1. **Day 1-2:** Build word similarity matrix
   - Write `scripts/build-word-similarity-matrix.py`
   - Extract GTE-tiny embeddings from Issue #176 archive
   - Generate sparse Lua table (~80KB)
2. **Day 3-4:** Implement soft cosine
   - Add `soft_cosine_score()` to `embedding_matcher.lua`
   - Integrate as Stage 2 re-ranker
3. **Day 5:** A/B test vs. MaxSim
   - Implement MaxSim alternative
   - Compare accuracy on 60-test + expanded test set

**Deliverables:**
- ✅ Word similarity matrix operational
- ✅ Soft cosine re-ranker functional
- ✅ Hybrid BM25+soft cosine pipeline
- ✅ 80% accuracy milestone reached

---

### Phase 3: Advanced (Weeks 3-4)

**Goal:** 80% → 85% accuracy (stretch)

**Tasks:**
1. **Week 3:** Context-aware ranking + inverted index
   - Integrate recency boosting from `context.lua`
   - Build inverted index for speed
2. **Week 4:** Adaptive weighting (BM25F)
   - Separate verb/noun field weighting
   - Tune weights empirically

**Deliverables:**
- ✅ Context-boosted ranking
- ✅ 10x speedup via inverted index
- ✅ 85% accuracy (if feasible)

---

## 6. Risks and Constraints

### 6.1 Fengari Performance

**Constraint:** Parser must run in Fengari (Lua-in-browser), which is 3-10x slower than native Lua.

**Risk:** Soft cosine with nested loops (O(|query|² + |phrase|²)) may be too slow.

**Mitigation:**
- Threshold similarity lookups (skip S_ij < 0.3)
- Use inverted index to reduce candidate set
- Profile in browser before committing

**Fallback:** If soft cosine is too slow, use MaxSim (simpler, O(|query| × |phrase|)).

---

### 6.2 Index Size Explosion

**Current:** 4,579 phrases → 15.3 MB JSON (including unused embedding vectors)

**After synonym expansion:** ~23K phrases → **~1.2 MB** (vectors stripped)

**After inverted index:** +~200KB (in-memory data structure)

**Total:** <2 MB (acceptable for browser)

**Mitigation:** Strip embedding vectors from JSON (keep only text, verb, noun fields).

---

### 6.3 Principle 8: No Object-Specific Engine Code

**Constraint:** Parser must remain **object-agnostic** — no hardcoded object names in matching logic.

**Risk:** Synonym table could tempt us to add object-specific hacks.

**Mitigation:** Synonym table is **pure data** (Lua table), not code. All matching logic is generic (applies to any verb/noun pair).

---

### 6.4 False Positive Rate

**Risk:** Soft matching may incorrectly match unrelated commands (e.g., "eat window" → "open window" if "eat" somehow scores high).

**Mitigation:**
- Threshold tuning (require min score)
- Verb-noun coherence check (e.g., don't match food verbs to non-consumable nouns)
- Test suite with negative cases ("wrong verb + wrong noun should fail")

---

### 6.5 Synonym Maintenance

**Risk:** Manual synonym table requires curation effort as vocabulary grows.

**Mitigation:**
- Document curation process in `docs/architecture/parser/synonym-maintenance.md`
- Use WordNet or thesaurus for initial seeding, then manually vet
- Automate validation: "Does this synonym appear in player test data?"

---

## 7. Decision Points (Require Wayne's Input)

### D1: Hybrid Scoring Weights (BM25 + Soft Cosine)

**Question:** What weight ratio for BM25 vs. soft cosine in hybrid scoring?

**Options:**
- A) 70% BM25, 30% soft cosine (lexical precision > semantic recall)
- B) 50/50 (equal weight)
- C) 30% BM25, 70% soft cosine (semantic recall > lexical precision)

**Recommendation:** Start with A (70/30), tune empirically.

**Decision:** _______________

---

### D2: Synonym Expansion Scope

**Question:** How many synonyms per verb/noun?

**Options:**
- A) Top 2-3 synonyms (Lu et al. 2015 recommendation) → ~10K phrases
- B) Top 5 synonyms → ~23K phrases
- C) All synonyms from WordNet → ~50K+ phrases (risky)

**Recommendation:** Start with A (2-3), expand to B if accuracy gains warrant it.

**Decision:** _______________

---

### D3: Soft Cosine vs. MaxSim

**Question:** Which re-ranking algorithm for Stage 2?

**Options:**
- A) Soft cosine (Sidorov et al. — more theoretically sound)
- B) MaxSim (ColBERT — simpler, faster)
- C) Both (A/B test, keep winner)

**Recommendation:** C (both), then pick winner after empirical evaluation.

**Decision:** _______________

---

### D4: Phase 3 Priority

**Question:** Should we pursue 85% accuracy (Phase 3) or stop at 80%?

**Context:** 80% may be "good enough" for beta playtesting. Diminishing returns after that.

**Options:**
- A) Stop at 80%, focus on other systems (NPC dialogue, combat)
- B) Push to 85% (perfectionism)
- C) Conditional: if Phase 2 exceeds 82%, continue; else stop

**Recommendation:** C (conditional).

**Decision:** _______________

---

### D5: Inverted Index Timing

**Question:** When to implement inverted index?

**Options:**
- A) Phase 1 (proactive optimization)
- B) Phase 2 (when soft cosine proves expensive)
- C) Phase 3 (only if performance degrades)

**Recommendation:** B (wait for soft cosine profile data).

**Decision:** _______________

---

## 8. Success Metrics

### 8.1 Accuracy Targets

| Milestone | Accuracy | Test Suite Pass Rate |
|-----------|----------|---------------------|
| Baseline | 68% | 41/60 |
| Phase 1 Complete | 75% | 45/60 |
| Phase 2 Complete | 80% | 48/60 |
| Phase 3 Complete | 85% | 51/60 |

### 8.2 Performance Targets

| Metric | Current | Target (Phase 2) | Target (Phase 3) |
|--------|---------|------------------|------------------|
| Tier 2 latency | <10ms | <20ms | <10ms (with index) |
| Phrase index size | 15.3 MB | 1.2 MB | 1.2 MB |
| Memory footprint | ~20 MB | ~25 MB | ~25 MB |

### 8.3 Quality Targets

| Metric | Current | Target |
|--------|---------|--------|
| False positive rate | ~10% | <5% |
| False negative rate | ~32% | <20% |
| Ambiguous command handling | Manual disambiguation | Automatic (context) |

---

## 9. Testing Strategy

### 9.1 Regression Suite

**File:** `test/parser/test-tier2-benchmark.lua` (expand to 120 cases)

**Categories:**
- Exact matches (baseline)
- Synonym variants ("grab" → "take")
- Verbose input ("please take the candle now")
- Novel phrasing ("gimme that candle")
- Ambiguous ("get it" with context)
- Wrong commands (negative cases)

### 9.2 A/B Testing

**Methodology:**
1. Run baseline Jaccard on 60-test suite → record accuracy
2. Run BM25 on same suite → compare delta
3. Run BM25+synonyms → compare delta
4. Run BM25+synonyms+soft cosine → compare delta

**Tracking:** CSV file with columns: input, expected, jaccard_result, bm25_result, soft_result, winner

### 9.3 Performance Profiling

**Tools:**
- Lua profiler (`os.clock()` timestamps)
- Browser DevTools (for Fengari)

**Metrics:**
- Time per `matcher:match()` call
- Memory allocation per match
- Total load time for phrase index + IDF table

---

## 10. References

### Research Papers

1. **Robertson & Zaragoza (2009)** — "The Probabilistic Relevance Framework: BM25 and Beyond" — [../resources/research/architecture/papers/robertson-zaragoza-2009-bm25.md](../resources/research/architecture/papers/robertson-zaragoza-2009-bm25.md)
2. **Sidorov et al. (2014)** — "Soft Similarity and Soft Cosine Measure" — [../resources/research/architecture/papers/sidorov-2014-soft-cosine.md](../resources/research/architecture/papers/sidorov-2014-soft-cosine.md)
3. **Lu et al. (2015)** — "Query Expansion via WordNet for Effective Code Search" — [../resources/research/architecture/papers/lu-2015-wordnet-query-expansion.md](../resources/research/architecture/papers/lu-2015-wordnet-query-expansion.md)
4. **Khattab & Zaharia (2020)** — "ColBERT: Efficient and Effective Passage Search" — [../resources/research/architecture/papers/khattab-zaharia-2020-colbert.md](../resources/research/architecture/papers/khattab-zaharia-2020-colbert.md)
5. **Lewis et al. (2020)** — "Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks" — [../resources/research/architecture/papers/lewis-2020-rag.md](../resources/research/architecture/papers/lewis-2020-rag.md)

### Internal Reports

1. **Embedding Vector Research (Issue #176)** — [../resources/research/architecture/embedding-vector-research.md](../resources/research/architecture/embedding-vector-research.md)
2. **RAG Research** — [../resources/research/architecture/Applying RAG & Context-Packing Techniques to a Text Adventure Parser.md](../resources/research/architecture/Applying%20RAG%20&%20Context-Packing%20Techniques%20to%20a%20Text%20Adventure%20Parser.md)

### Code Files

1. `src/engine/parser/embedding_matcher.lua` — Tier 2 Jaccard matcher (lines 109-251)
2. `src/engine/parser/init.lua` — Parser orchestration (line 12: threshold)
3. `src/engine/parser/preprocess.lua` — Input normalization pipeline
4. `src/engine/parser/fuzzy.lua` — Tier 5 fuzzy resolution
5. `src/engine/parser/context.lua` — Context window for recency scoring

---

## Appendix A: BM25 Parameter Tuning

**Recommended starting values:**
- `k1 = 1.2` (standard TF saturation)
- `b = 0.5` (reduced length norm for short documents)

**Tuning strategy:**
1. Grid search: k1 ∈ {0.8, 1.0, 1.2, 1.5, 2.0}, b ∈ {0.3, 0.5, 0.75}
2. Evaluate accuracy on 60-test suite for each (k1, b) pair
3. Choose parameters that maximize F1 score

**Expected optimal:** k1 ≈ 1.2, b ≈ 0.3-0.5 (lower b than standard due to very short phrases)

---

## Appendix B: Word Similarity Threshold Tuning

**Question:** At what similarity S_ij should we treat two words as "matching"?

**Options:**
- A) S_ij > 0.8 (strict — only close synonyms)
- B) S_ij > 0.5 (moderate — related words)
- C) S_ij > 0.3 (permissive — distant semantic relations)

**Recommendation:** B (0.5) for matching, C (0.3) for storage (store more, use threshold at runtime).

**Testing:** Manually inspect similarity matrix for common verbs/nouns:
```
get ↔ take: 0.95 ✅
get ↔ grab: 0.93 ✅
get ↔ consume: 0.42 ⚠️ (borderline)
get ↔ light: 0.12 ❌ (unrelated)
candle ↔ lamp: 0.88 ✅
candle ↔ match: 0.67 ⚠️ (fire tools)
candle ↔ knife: 0.08 ❌ (unrelated)
```

**Tuning:** Run soft cosine with different thresholds, measure precision/recall trade-off.

---

## Appendix C: Estimated Code Changes

| File | Current LOC | Added LOC | Modified LOC | Total LOC |
|------|-------------|-----------|--------------|-----------|
| `src/engine/parser/embedding_matcher.lua` | 254 | +120 (BM25, soft cosine) | ~30 (match() refactor) | 374 |
| `src/engine/parser/bm25_data.lua` | 0 | +220 (IDF table) | 0 | 220 |
| `src/engine/parser/word_similarity.lua` | 0 | +600 (sparse matrix) | 0 | 600 |
| `src/engine/parser/synonym_table.lua` | 0 | +300 (manual curated) | 0 | 300 |
| `scripts/build-idf-table.py` | 0 | +50 | 0 | 50 |
| `scripts/build-word-similarity-matrix.py` | 0 | +80 | 0 | 80 |
| `scripts/expand-phrase-index.py` | 0 | +60 | 0 | 60 |
| **Total** | **254** | **+1,430** | **~30** | **1,684** |

**Estimated effort:** ~40-60 hours coding + 20-30 hours testing = **2-3 weeks calendar time**

---

## END OF PLAN

**Next Steps:**
1. Wayne reviews this plan and makes decisions on D1-D5
2. Frink archives this plan in `.squad/agents/frink/history.md`
3. Bart (or Smithers) implements Phase 1 (BM25 + synonyms)
4. Nelson validates accuracy gains via test suite
5. Team decides whether to proceed to Phase 2 based on Phase 1 results

**Questions?** Ask Frink (Researcher) or Smithers (Parser Owner).
