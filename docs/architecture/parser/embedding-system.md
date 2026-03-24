# Embedding System Architecture

**Author:** Brockman (Documentation)  
**Date:** 2026-03-24  
**Status:** Final  
**Related:** #174 (SLM lazy-load audit), #175 (documentation), #176 (Jaccard research)

---

## 1. System Overview

### Purpose

The **embedding index** is the **Tier 2 semantic matcher** in the five-tier parser pipeline. When a player types a command, it flows through:

| Tier | Purpose | Match Rate | Example |
|------|---------|-----------|---------|
| 1 | Exact verb/noun lookup | ~70% | `"get candle"` → exact match |
| **2** | **Semantic matching via embeddings** | **~20%** | **`"pick up the candle"` → semantic similarity** |
| 3 | Goal-oriented planning (GOAP) | ~5% | `"use a light source"` → verb inference |
| 4 | Context window (recent interactions) | ~3% | Last command context |
| 5 | Fuzzy noun resolution | ~2% | Typos, abbreviations |

The Tier 2 system is **not** what players typically think of as "AI." It's a **fast, deterministic dictionary lookup** that finds the best matching verb+noun pair from a pre-computed index of natural-language training phrases.

### How It Works

1. **At build time (Python):** 
   - Scan verbs, objects, and rooms from Lua source files
   - Generate 4,579 natural-language phrase variants using templates
   - Encode all phrases using **TaylorAI/gte-tiny** (384-dimensional embeddings)
   - Save to `src/assets/parser/embedding-index.json`

2. **At runtime (Lua):**
   - Load the slim index (text/verb/noun only, ~362 KB)
   - Tokenize player input
   - Compare against all phrases via **Jaccard token matching**
   - Return the best-matching verb+noun pair

### The Jaccard Decision (D-KEEP-JACCARD)

The index **contains 384-dimensional embedding vectors** but **Lua code ignores them**. Instead, it matches via **Jaccard token overlap** (intersection over union of word tokens). 

**Why not use the vectors?**

- **GTE-tiny can't run in pure Lua.** It's a 17.6M-parameter transformer. Lua can't encode novel player input at runtime.
- **ONNX Runtime Web is available but heavy.** The full ONNX model is ~70 MB; adding JavaScript dependencies breaks the "pure Lua" architecture.
- **Jaccard outperforms practical alternatives.** Frink's research (Issue #176) showed Jaccard achieves 68% accuracy vs 45% for bag-of-word cosine matching.

**Future path:** If the game moves to a browser-only architecture, real vector similarity via ONNX Runtime Web becomes feasible. For now, vectors are archived; only the text/verb/noun fields are used.

---

## 2. Index Structure

### File Locations

```
src/assets/parser/
├── embedding-index.json        # Primary index (slim, ~362 KB)
├── embedding-index.json.gz     # Compressed (~100 KB for web delivery)
└── .gitkeep

resources/archive/
└── embedding-index-full.json   # Full index with vectors (15.3 MB, reference only)
```

### Index Format (Slim)

```json
{
  "phrases": [
    {
      "id": 1,
      "text": "break a crude bandage",
      "verb": "break",
      "noun": "bandage"
    },
    {
      "id": 2,
      "text": "smash a crude bandage",
      "verb": "break",
      "noun": "bandage"
    },
    // ... 4,577 more entries
  ],
  "model": "TaylorAI/gte-tiny",
  "note": "Slim index - vectors stripped. Full index archived at resources/archive/embedding-index-full.json"
}
```

### Size Analysis

| Version | Format | Size | Use Case |
|---------|--------|------|----------|
| **Slim (current)** | JSON | ~362 KB | Lua runtime matching |
| Slim (gzipped) | .json.gz | ~100 KB | Web delivery |
| Full (archived) | JSON + 384-dim vectors | 15.3 MB | Future ONNX experiments |
| Full (gzipped) | .json.gz | 4.8 MB | Reference |

**Decision:** Strip vectors from the primary index because:
1. Lua code doesn't use them (Jaccard matching only)
2. Saves ~13.9 MB in the Lua build
3. Full vectors remain archived if ONNX support is added later

### Phrase Counts

- **Total phrases:** 4,579
- **Unique verbs:** 48 (get, look, examine, break, burn, etc.)
- **Unique nouns:** 41 (candle, match, bed, wardrobe, etc.)
- **Variants per verb+noun pair:** ~3 (synonyms + different articles)

Example for `get + candle`:
- "get a tallow candle"
- "take a tallow candle"
- "pick up a tallow candle"

### Phrase Generation Rules

Phrases are generated from:
1. **Verb set** from `src/engine/verbs/init.lua` (primary handlers only, not aliases)
2. **Object set** from `src/meta/objects/` (each object's `id`, `name`, `keywords`)
3. **Template variations** (3-4 paraphrases per verb+noun pair)

Generation respects:
- **Object properties:** Use the object's descriptive name (e.g., "crude bandage", "tallow candle")
- **Verb aliases:** Only primary verbs get phrases; aliases (e.g., `handlers.get = handlers.take`) are filtered
- **State variants:** Include open/lit/broken suffixed nouns (e.g., "wardrobe-open", "candle-lit")

---

## 3. Generation Pipeline

### Scripts

Two Python scripts manage the index:

#### Phase 1: Training Data (`scripts/generate_parser_data.py`)

**Purpose:** Extract verbs/objects/rooms from Lua source, generate training phrases.

**Usage:**
```bash
# Generate from local Lua source (fast, reproducible)
python scripts/generate_parser_data.py --mode=local

# Generate using LLM paraphrasing (slow, ~5-10 min, requires OPENAI_API_KEY)
python scripts/generate_parser_data.py --mode=llm
```

**Output:** `data/parser/training-pairs.csv`

**Columns:**
```
phrase_id,phrase_text,verb,noun
1,"break a crude bandage",break,bandage
2,"smash a crude bandage",break,bandage
3,"shatter a crude bandage",break,bandage
...
```

**Local mode strategy:** Hard-coded template paraphrases (verified accurate, 242+ phrase variants).

**LLM mode strategy:** Uses GPT to generate additional paraphrases (more creative but requires token budget).

#### Phase 2: Embedding Index (`scripts/build_embedding_index.py`)

**Purpose:** Load training CSV, encode phrases with GTE-tiny, save index.

**Usage:**
```bash
# Generate slim index (default: vectors stripped)
python scripts/build_embedding_index.py

# Generate full index (with vectors)
python scripts/build_embedding_index.py --no-slim

# Custom input/output
python scripts/build_embedding_index.py \
  --input data/parser/training-pairs.csv \
  --output-dir src/assets/parser \
  --model-cache models/
```

**Requirements:**
```bash
pip install sentence-transformers  # or transformers + torch
```

**Process:**
1. Load `training-pairs.csv` (4,579 rows)
2. Load **TaylorAI/gte-tiny** model (17.6M params, 384-dim output)
3. Encode all phrases (~60 phrases/sec on CPU, ~1 min total)
4. Round vectors to 6 decimal places
5. Save slim (text/verb/noun) to `embedding-index.json`
6. Archive full (with vectors) to `resources/archive/embedding-index-full.json`
7. Gzip both to `.json.gz`

### Regeneration Workflow

**When to regenerate the index:**
- New verbs added to `src/engine/verbs/init.lua`
- New objects added to `src/meta/objects/`
- Object keywords or descriptions changed
- New room exits or world layout changes

**Full regeneration:**
```bash
# Step 1: Generate training pairs from updated Lua source
python scripts/generate_parser_data.py --mode=local

# Step 2: Encode into embedding index
python scripts/build_embedding_index.py

# Result: embedding-index.json updated, archive maintained
```

**Time:** ~60 seconds (model load ~10s, encoding ~50s)

### Model Details

**TaylorAI/gte-tiny**

| Attribute | Value |
|-----------|-------|
| Base model | BERT-style transformer |
| Parameters | 17.6M |
| Output dimensions | 384 |
| Max sequence length | 128 tokens |
| Training data | General-purpose semantic similarity |
| License | Apache 2.0 |

Why this model?
- **Small:** 17.6M params (vs 110M+ for full embeddings)
- **Fast:** ~60 phrases/sec on CPU
- **General-purpose:** Trained on broad semantic tasks (paraphrase, similarity)
- **Pre-trained:** No fine-tuning needed for game commands

---

## 4. Runtime Usage

### Lua Matcher: `embedding_matcher.lua`

**File:** `src/engine/parser/embedding_matcher.lua`  
**Size:** ~254 lines

#### API

```lua
local matcher = require("src.engine.parser.embedding_matcher")

-- Create matcher (loads index from JSON)
local m = matcher.new("src/assets/parser/embedding-index.json", debug=true)

-- Match player input against index
local verb, noun, score, matched_phrase = m:match("pick up the candle")
-- Returns: ("get", "candle", 0.67, "pick up a tallow candle")

-- Check if loaded
if m.loaded then
  print("Index contains " .. #m.phrases .. " phrases")
end
```

#### Algorithm: Jaccard with Prefix Bonus

1. **Tokenize input:** Lowercase, strip punctuation, remove stop words
2. **Tokenize all phrases:** Same preprocessing
3. **For each phrase:**
   - **Exact token matches:** Intersection count
   - **Prefix bonus:** If a 3+ char input token shares a prefix with a phrase token, award partial credit (0.5x)
   - **Jaccard score:** (intersection + partial) / union
4. **Tiebreaker:** If two phrases tie, prefer non-suffixed nouns (base-state preferred)

**Example:**

```
Input: "pick up the candle"
Tokens (after stop-word removal): ["pick", "candle"]

Phrase 1: "pick up a tallow candle"
Tokens: ["pick", "tallow", "candle"]
Exact matches: ["pick", "candle"] = 2
Union: ["pick", "tallow", "candle"] = 3
Score: 2/3 = 0.67

Phrase 2: "take a tallow candle"
Tokens: ["take", "tallow", "candle"]
Exact matches: ["candle"] = 1
Prefix bonus: "pick" starts with "pic", "take" starts with "tak" → no 3-char match = 0
Union: ["pick", "take", "tallow", "candle"] = 4
Score: 1/4 = 0.25

Best match: Phrase 1 (verb="get", noun="candle", score=0.67)
```

#### Performance

**Benchmark (Windows, Lua 5.4, single-threaded):**
- **Full scan (4,579 phrases):** 8.1 ms
- **Per-lookup latency:** < 10 ms ✅

**Fengari (browser Lua):** ~24-81 ms (3-10x slower, acceptable for interactive UI)

#### Stop Words

Filtered during tokenization (the following are ignored):
```lua
"the", "a", "an", "some", "to", "at", "on", "in", "of", "my", "its", "this",
"that", "is", "it", "i", "and", "or", "with", "for", "up", "down", "around"
```

#### Special Features

1. **Typo correction (optional):**
   - Verbs only (nouns handled by Tier 5)
   - Levenshtein distance ≤ 2 for words > 4 chars
   - Short words (≤ 4 chars) require exact match only

2. **Tiebreaker for state variants:**
   - When scores tie, prefer base-state nouns (no -lit/-open/-broken suffix)
   - Prevents "examine a wooden match" from matching "examine a lit match" equally

3. **Prefix matching:**
   - Abbreviations like "cand" → "candle" get partial credit
   - Useful for partial input or typos

---

## 5. Web/Browser Architecture

### Web Build Integration

**Web builder:** `web/game-adapter.lua` (Fengari layer)

**Loading strategy:**
```lua
-- Load the slim index for Tier 2 matching
local matcher = require("src.engine.parser.embedding_matcher")
local index_path = "assets/parser/embedding-index.json"
local m = matcher.new(index_path, debug=false)
```

**File delivery:**
- **src/assets/parser/embedding-index.json** → served to browser as `assets/parser/embedding-index.json`
- **src/assets/parser/embedding-index.json.gz** → optionally gzipped for transfer (100 KB vs 362 KB)

**Caching strategy:**
- **Browser cache:** Include `Cache-Control: max-age=86400` (1 day) for the index
- **Service worker:** Can cache the gzipped index locally for offline play
- **Lazy loading:** Index loads on first parser query (not on page load)

### Future: ONNX Runtime Web (Not Yet Implemented)

When moving to real vector similarity:

1. **Load ONNX model:** GTE-tiny converted to ONNX format (~70 MB, quantized ~17 MB)
2. **Use ONNX Runtime Web:** WebAssembly or WebGL backend
3. **Encode player input:** At parse time (~20-50 ms per query on desktop)
4. **Compare via cosine:** Real vector similarity instead of Jaccard
5. **Expected improvement:** ~20% boost in accuracy (from 68% Jaccard to ~80% with vectors)

**Decision gate:** Only pursue if:
- Browser-only play becomes the primary platform
- ONNX model download is acceptable (~17 MB)
- JavaScript/WebAssembly dependency is acceptable

---

## 6. Decision: D-KEEP-JACCARD

### Context

**Issue #176:** Frink's research compared Jaccard token matching (current) vs cosine vector similarity (proposed).

### Research Summary

**Test scope:** 60 commands across 6 categories (exact, synonym, partial, novel, ambiguous, close-wrong)

**Results:**

| Approach | Correct | Verb-OK | Accuracy |
|----------|---------|---------|----------|
| **Jaccard (current)** | 41 | 47 | **68%** |
| Cosine BOW | 27 | 37 | 45% |
| Hybrid (Jaccard → cosine) | 29 | 40 | 48% |

**Jaccard decisively wins** because:

1. **Excels at partial input:** Prefix matching handles abbreviations ("cand" → candle)
2. **Avoids state-variant bias:** "candle-lit" and "candle" don't confuse Jaccard (different tokens)
3. **No runtime encoding blocker:** Works entirely offline

### The Runtime Encoding Problem

Cosine similarity requires encoding novel player input into 384-dim vectors. Problem:

- **Pure Lua:** Cannot run GTE-tiny (transformer inference in Lua would take minutes, not milliseconds)
- **Fengari (Lua browser):** 3-10x slower than native Lua, still infeasible
- **ONNX Runtime Web:** Feasible (~20-50ms per query) but adds 70 MB model + JavaScript dependency

**Bottom line:** No practical way to encode player input at runtime in current architecture.

### Decision

**KEEP JACCARD** as the Tier 2 matching strategy indefinitely.

**Rationale:**
- Outperforms cosine by 23 percentage points (68% vs 45%)
- No runtime encoding requirement
- Performance meets budget (< 10ms per lookup)
- Vectors remain archived for future ONNX experiments

### Alternative: Pre-compute All Combinations

Could pre-compute vectors for every valid verb+noun pair (~1,968 combinations already exist in index). But this doesn't help with:
- Novel phrasing ("gimme", "I want to")
- Typos/abbreviations
- Compound input ("pick up the candle")

The index already covers 3 common paraphrases per pair. Expanding requires the same GTE-tiny encoding we're avoiding.

---

## 7. Size Analysis

### Index Size Breakdown

| Component | Size | Notes |
|-----------|------|-------|
| **Slim (current)** | 362 KB | text, verb, noun only |
| **Slim gzipped** | 100 KB | web delivery |
| **Full (archived)** | 15.3 MB | with 384-dim vectors |
| **Full gzipped** | 4.8 MB | reference |

### Why Strip Vectors?

**15.3 MB → 362 KB is a 42x reduction** because:

- Each phrase vector: 384 floats × 4 bytes = 1,536 bytes
- 4,579 phrases × 1,536 bytes = 7.0 MB (before JSON overhead)
- JSON overhead (field names, delimiters, formatting): ~2x compression factor
- Total: ~15.3 MB

**Vectors unused at runtime** (Jaccard matching only) → strip them.

### Archive Strategy

Full index with vectors remains at:
```
resources/archive/embedding-index-full.json
```

This enables:
- **Experimental comparison** if cosine matching is reconsidered
- **ONNX model conversion** if browser architecture is adopted
- **Vector statistics** (average norm, dimensionality check)

---

## 8. Cross-References

### Parser Architecture

- **5-tier pipeline overview:** `docs/architecture/parser/` (to be created)
- **Tier 1 (exact matching):** `src/engine/parser/init.lua` (Tier 1 exact handlers)
- **Tier 3 (GOAP planning):** `src/engine/parser/goal_planner.lua`
- **Tier 4 (context window):** `src/engine/parser/context.lua`
- **Tier 5 (fuzzy resolution):** `src/engine/parser/fuzzy.lua`

### Related Documentation

- **Design directives (gameplay verbs):** `docs/design/verb-system.md`
- **Parser pipeline design:** `docs/design/prime-directive-tiers.md`
- **Core principles (engine architecture):** `docs/architecture/objects/core-principles.md`
- **Issues:** #174 (lazy-load audit), #175 (this documentation), #176 (Jaccard research)

### Implementation Files

- **Lua matcher:** `src/engine/parser/embedding_matcher.lua`
- **Index data:** `src/assets/parser/embedding-index.json`
- **Build script:** `scripts/build_embedding_index.py`
- **Training data generator:** `scripts/generate_parser_data.py`
- **Archive:** `resources/archive/embedding-index-full.json`

---

## 9. Testing

### Unit Tests

**File:** `test/parser/test-embedding-matcher.lua`

Tests cover:
- Index loading and phrase count
- Jaccard score calculation
- Prefix bonus scoring
- Tiebreaker (prefer base-state nouns)
- Stop-word filtering
- Typo correction for verbs

**Run tests:**
```bash
lua test/parser/test-embedding-matcher.lua
```

### Integration Tests

**File:** `test/integration/` (multi-tier parser tests)

Tests verify:
- Tier 2 fallback when Tier 1 doesn't match
- Score thresholds for acceptance
- Parser pipeline flow with real player input

---

## 10. Troubleshooting

### Index Not Loaded

**Symptom:** `[Parser] Warning: embedding index not found`

**Cause:** `embedding-index.json` missing or path incorrect

**Fix:**
```bash
# Regenerate index
python scripts/build_embedding_index.py

# Verify file exists
ls src/assets/parser/embedding-index.json
```

### Low Match Quality

**Symptom:** Commands not matching expected verb+noun

**Cause:** Phrase not in training data or score tie favors wrong variant

**Fix:**
1. Check if phrase is in index: `grep "your phrase" data/parser/training-pairs.csv`
2. Regenerate index if objects/verbs changed
3. Review tiebreaker logic (prefers base-state nouns)

### Encoding Time Regression

**Symptom:** Parser queries taking > 10ms

**Cause:** Index size grew beyond 4,579 phrases

**Fix:**
1. Profile with `lua scripts/bench_embedding_matcher.lua`
2. Consider phrase count: ~4,579 = 8.1ms (acceptable limit)
3. For > 10,000 phrases, optimize by:
   - Reducing verbosity (fewer variants per pair)
   - Indexing by verb first (faster narrowing)
   - Upgrading to native C module (if needed)

---

## 11. Summary

The **embedding index** is the Tier 2 semantic matcher: a fast, deterministic dictionary of 4,579 natural-language phrases paired with verb+noun metadata. At runtime, Lua loads the slim index (~362 KB) and matches player input via **Jaccard token matching** (~8ms per lookup). 

**Key decisions:**
- **Keep Jaccard:** 68% accuracy, no runtime encoding needed
- **Strip vectors:** 15.3 MB → 362 KB, vectors unused in Lua
- **Archive full:** 384-dim vectors saved for future ONNX experiments

The system is production-ready, well-tested, and meets all performance budgets.
