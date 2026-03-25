# Query Expansion via WordNet for Effective Code Search

**Authors:** Meili Lu, Xiaobing Sun, Shaowei Wang, David Lo, Yucong Duan
**Year:** 2015
**Venue:** 22nd IEEE International Conference on Software Analysis, Evolution, and Reengineering (SANER), pp. 545–549
**URL:** <https://doi.org/10.1109/SANER.2015.7081874>
**Author PDF:** <http://www.mysmu.edu/faculty/davidlo/papers/saner15-expansion.pdf>

## Abstract

The paper proposes a query expansion approach using synonyms from WordNet to improve the effectiveness of source code search. The method extracts natural language phrases from code identifiers, expands queries with WordNet synonyms (filtered by part-of-speech matching), and matches them to these phrases to enhance search accuracy. Empirical evaluation demonstrated improvements of ~5% in precision and ~8% in recall over state-of-the-art techniques.

## Key Algorithm / Methodology

### Problem Statement

Users searching for code often use different vocabulary than the developers who wrote it. For example, a user might search for "remove element" when the code uses "delete item". This **vocabulary mismatch** degrades search accuracy — the exact same problem our parser faces when players type "grab candle" but the phrase index has "take candle".

### The Query Expansion Algorithm

#### Step 1: Query Preprocessing

1. Tokenize the user's query into individual words
2. Determine the **part of speech (POS)** of each word using NLP tagging:
   - Verbs: "take", "get", "remove", "open"
   - Nouns: "candle", "door", "lamp"
   - Adjectives/adverbs: filtered out or handled separately
3. Stem/lemmatize each word to its base form

#### Step 2: WordNet Synonym Expansion

For each query term, retrieve synonyms from WordNet **filtered by matching POS**:

```
function expand_query(query_terms):
    expanded = []
    for each term in query_terms:
        pos = get_part_of_speech(term)
        synsets = wordnet.synsets(term, pos=pos)  -- POS-filtered!
        for each synset in synsets:
            for each lemma in synset.lemmas():
                if lemma != term:
                    expanded.append(lemma)
    return query_terms + deduplicate(expanded)
```

**Critical insight: POS filtering is essential.** Without it:
- "take" (verb) would expand to "take" (noun, as in "movie take") → nonsense matches
- "light" (noun) would expand to "light" (adjective, "not heavy") → wrong context
- "match" (noun, fire tool) would expand to "match" (verb, "to correspond") → confusion

#### Step 3: Code Identifier Phrase Extraction

From source code, extract natural language phrases by:
1. Splitting camelCase and snake_case identifiers: `getUserName` → "get user name"
2. Extracting comments and documentation strings
3. Building an index of these extracted phrases

#### Step 4: Expanded Query Matching

Match the expanded query (original terms + synonyms) against the phrase index using standard text retrieval (TF-IDF or similar):

```
function search(query, code_index):
    expanded_query = expand_query(query)
    results = []
    for each phrase in code_index:
        score = similarity(expanded_query, phrase)
        results.append((phrase, score))
    return sort_by_score(results)
```

### Synonym Selection Strategy

The paper identifies key challenges in synonym expansion:

1. **Over-expansion:** Adding too many synonyms introduces noise. Solution: limit to **first 2-3 synsets** (most common meanings) per word.
2. **Polysemy:** Words with multiple meanings expand to wrong senses. Solution: **POS filtering** eliminates most wrong-sense expansions.
3. **Domain specificity:** Generic synonyms may not apply in the target domain. Solution: validate expanded terms against the corpus vocabulary.

### Offline vs. Online Expansion

The paper demonstrates that expansion can be done **at index time** (expanding documents/phrases) rather than at query time:
- **Index-time expansion:** Add synonym variants to each phrase in the index. "take candle" also gets indexed under "grab candle", "get candle", "seize candle".
- **Query-time expansion:** Expand the user's query with synonyms before matching.
- **Both are valid** — index-time expansion is preferred when the phrase set is fixed (as in our game).

## Results Relevant to Our Parser

### Experimental Setup

- **Corpus:** Rhino JavaScript/ECMAScript interpreter source code
- **Queries:** 40 maintenance-related natural language queries
- **Baseline:** Conquer tool (state-of-the-art code search at the time)
- **Metrics:** Precision@k, Recall, MAP (Mean Average Precision)

### Results

| Method | Precision Improvement | Recall Improvement |
|--------|----------------------|-------------------|
| No expansion (baseline) | — | — |
| WordNet expansion (unfiltered) | +2% | +5% |
| **WordNet + POS filtering** | **+5%** | **+8%** |

### Key Findings

- **POS-filtered expansion consistently outperformed unfiltered expansion** — without POS filtering, wrong-sense synonyms degraded precision
- **Small, controlled vocabularies benefit most** — the code identifier vocabulary is limited (like our ~200 game words), making expansion highly effective
- **Offline expansion** (at index time) was as effective as online expansion and adds zero runtime cost
- **Diminishing returns** with more than 3 synsets per word — quality drops as obscure meanings are included

## Implementation Notes for Pure Lua

### Build-Time Synonym Expansion (Recommended)

Since our phrase index is fixed at build time, we should expand phrases offline:

```lua
-- Build-time synonym expansion for phrase index
local synonym_table = {
    -- Verbs (POS-filtered: only verb synonyms)
    take  = {"grab", "get", "seize", "snatch", "pick up"},
    open  = {"unlock", "unfasten"},
    look  = {"examine", "inspect", "observe", "view", "check"},
    light = {"ignite", "kindle"},  -- verb sense only
    break = {"smash", "shatter", "crack", "destroy"},
    put   = {"place", "set", "drop", "deposit"},

    -- Nouns (POS-filtered: only noun synonyms)
    candle = {"taper", "light"},   -- noun sense only
    door   = {"entrance", "portal", "gateway"},
    key    = {"lock pick"},
    lamp   = {"lantern", "light"}, -- noun sense only
}

function expand_phrase(phrase_tokens, synonym_table)
    local expanded_variants = {phrase_tokens}  -- original always included
    for i, token in ipairs(phrase_tokens) do
        if synonym_table[token] then
            for _, synonym in ipairs(synonym_table[token]) do
                local variant = shallow_copy(phrase_tokens)
                variant[i] = synonym
                table.insert(expanded_variants, variant)
            end
        end
    end
    return expanded_variants
end
```

### Practical Considerations

1. **Synonym source:** We don't need runtime WordNet access. Pre-build the synonym table manually for our ~48 verbs and ~74 object names. Small enough to curate by hand.
2. **POS tagging:** Not needed at runtime. Our phrase format is always `<verb> <noun>`, so position determines POS.
3. **Index size:** With ~5 synonyms per verb and ~3 per noun, each phrase generates ~15-20 variants. 4,579 base phrases × 15 = ~70K entries — still trivially fast to search.
4. **Combine with BM25:** Synonym-expanded phrases get matched via BM25, which naturally handles the expanded vocabulary with IDF weighting.

## References Worth Following

- **Miller (1995)** — "WordNet: A lexical database for English" — the definitive WordNet reference
- **Haiduc et al. (2013)** — "Automatic query reformulation for text retrieval in software engineering" — alternative query expansion techniques for code search
- **Nie et al. (2016)** — "Query expansion based on crowd knowledge for code search" — expansion using Stack Overflow data instead of WordNet
